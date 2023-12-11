/*
    Wyvern Gate, a procedural, console-based RPG
    Copyright (C) 2023, Johnathan Corkery (jcorkery@umich.edu)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
@:Database = import(module:'game_class.database.mt');
@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@Landmark = import(module:'game_class.landmark.mt');
@:Item = import(module:'game_class.item.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:Scene = import(module:'game_class.scene.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

@:Location = LoadableClass.new(
    name: 'Wyvern.Location',
    statics : {
        Base  :::<= {
            @db;
            return {
                get ::<- db,
                set ::(value) <- db = value
            }
        },
        CATEGORY ::<= {  
            @:ct = {
                ENTRANCE : 0,
                RESIDENTIAL : 1,
                BUSINESS : 2,
                UTILITY : 3,
                EXIT : 4,
                DUNGEON_SPECIAL : 5
            }
            return {
                get ::<- ct
            }
        }
    },
    
    new::(base, parent, landmark, xHint, yHint, state, ownedByHint) {
        @:landmark = if (landmark) landmark else parent.parent; // parents of locations are always maps
        @:this = Location.defaultNew();
        this.initialize(landmark);

        if (state != empty)
            this.load(serialized:state)
        else 
            this.defaultLoad(base, xHint, yHint, ownedByHint);
        return this;
    },
    
    define:::(this) {


        @landmark_;
        @world = import(module:'game_singleton.world.mt');    
        @:state = State.new(
            items : {
                worldID : world.getNextID(),
                targetLandmark : empty, // where this location could take the party. Could be a different island in theory
                targetLandmarkEntry : empty, // where in the landmark to take to. Should be an X-Y if populated, else its the locations responsibility to populate as needed.
                base : empty,
                occupants : [], // entities. non-owners can shift
                ownedBy : empty,// entity
                description : empty,
                inventory : Inventory.new(size:30),
                x : 0,
                y : 0,
                contested : false,
                name : empty,
                data : {}, // simple table
                visited : false,
                modData : {}
            }
        );
        
        
        this.interface = {
            initialize ::(landmark) {
                landmark_ = landmark;     
            },

            defaultLoad ::(base, xHint, yHint, ownedByHint) {

                state.base = base;
                state.x = if (xHint == empty) (Number.random() * landmark_.width ) else xHint;  
                state.y = if (yHint == empty) (Number.random() * landmark_.height) else yHint;
                if (ownedByHint != empty)
                    this.ownedBy = ownedByHint;
                       
                state.description = random.pickArrayItem(list:base.descriptions);            
                base.onCreate(location:this);
                return this;
            },

            save ::{
                return state.save()
            },
            
            load ::(serialized) {
                state.load(parent:this, serialized)
                if (this.ownedBy)
                    this.ownedBy.owns = this;
            },

            worldID : {
                get ::<- state.worldID
            },

                
            base : {
                get :: {
                    return state.base;
                }
            },
            
            targetLandmark : {
                get ::<- state.targetLandmark,
                set ::(value) <- state.targetLandmark = value
            },

            targetLandmarkEntry : {
                get ::<- state.targetLandmarkEntry,
                set ::(value) <- state.targetLandmarkEntry = value
            },

            
            inventory : {
                get ::<- state.inventory
            },
            ownedBy : {
                get ::<- state.ownedBy,
                set ::(value) {
                    if (state.ownedBy != empty)
                        state.ownedBy.owns = empty;
                    state.ownedBy = value          
                    if (value != empty)          
                        value.owns = this;
                }
            },
            
            data : {
                get ::<- state.data
            },
            
            description : {
                get ::<- state.description + (if (state.ownedBy != empty) ' This ' + state.base.name + ' is ' + state.base.ownVerb + ' by ' + state.ownedBy.name + '.' else '')
            },
            
            contested : {
                get ::<- state.contested,
                set ::(value) <- state.contested = value
            },
            x : {
                get:: <- state.x,
                set::(value) <- state.x = value
            },
            
            y : {
                get:: <- state.y,
                set::(value) <- state.y = value
            },
            
            inventory : {
                get :: <- state.inventory
            },
            
            name : {
                get::<- if (state.name == empty) (if (state.ownedBy == empty) state.base.name else (state.ownedBy.name + "'s " + state.base.name)) else state.name,
                set::(value) <- state.name = value
            },
            occupants : {
                get :: {
                    return state.occupants;
                }
            },
            
            discovered : {
                get :: <- true
            },  
            
            
            landmark : {
                get ::<- landmark_
            },
            
            peaceful : {
                get ::{
                    when (state.data.peaceful) true;
                    return landmark_.peaceful;
                }
            },
            
            // per location mod data.
            modData : {
                get ::<- state.modData
            },
            
            
            lockWithPressurePlate :: {
                @:pressurePlate = landmark_.addLocation(
                    name:'Pressure Plate'
                );
                
                state.data.plateID = pressurePlate.worldID;
                pressurePlate.data.pressed = false;


                if (random.flipCoin()) ::<= {
                    // for every pressure plate, there is a trapped 
                    // pressure plate.
                    @:pressurePlateFake = landmark_.addLocation(
                        name:'Pressure Plate'
                    );
                    pressurePlateFake.data.trapped = true;
                }
            },
            
            
            isUnlockedWithPlate :: {
                when(state.data.plateID == empty) true;
                
                @locations = landmark_.locations;
                
                return locations[locations->findIndex(query::(value) <- 
                    value.name == 'Pressure Plate' &&
                    value.worldID == state.data.plateID
                )].data.pressed;
            },
            
            interact ::{
                @world = import(module:'game_singleton.world.mt');
                @party = world.party;            
                @:Interaction = import(module:'game_class.interaction.mt');
                

            
                @:aggress::(location, party) {
                
                    @:choiceNames = [];
                    foreach(location.base.aggressiveInteractions) ::(k, name) {
                        choiceNames->push(value:
                            Interaction.database.find(name).displayName
                        );
                    }                
                    windowEvent.queueChoices(
                        prompt: 'Aggress how?',
                        choices: choiceNames,
                        canCancel : true,
                        onChoice ::(choice) {
                            when(choice == 0) empty;


                            @:interaction = Interaction.database.find(name:
                                location.base.aggressiveInteractions[choice-1]
                            );
                            
                            when (!location.landmark.peaceful) ::<= {
                                interaction.onInteract(location, party);                    
                            }
                                
                            
                            windowEvent.queueAskBoolean(
                                prompt: 'Are you sure?',
                                onChoice::(which) {
                                    when(which == false) empty;
                                    interaction.onInteract(location, party);                    
                                    
                                    if (location.landmark.peaceful) ::<= {
                                        location.landmark.peaceful = false;
                                        windowEvent.queueMessage(text:'The people here are now aware of your aggression.');
                                    }                
                                                            
                                }
                            );
                        }
                    );
                }            
            
            
                // initial interaction 
                // Initial interaction triggers an event.
                
                if (state.visited == false) ::<= {
                    for(0, random.integer(from:state.base.minOccupants, to:state.base.maxOccupants))::(i) {
                        state.occupants->push(value:landmark_.island.newInhabitant());
                    }
                
                
                    state.visited = true;
                    this.base.onFirstInteract(location:this);
                }
                    
                
                @canInteract = {:::} {
                    return this.base.onInteract(location:this);
                }
                    
                when(canInteract == false) empty;
              
                @:interactionNames = [...this.base.interactions]->map(to:::(value) {
                    return Interaction.database.find(name:value).displayName;
                });
                    
                @:choices = [...interactionNames];

                if (this.base.aggressiveInteractions->keycount)
                    choices->push(value: 'Aggress location...');
                    
                windowEvent.queueChoices(
                    prompt: 'Interaction',
                    choices:choices,
                    canCancel : true,
                    keep: true,
                    onChoice::(choice) {
               
                        when(choice == 0) empty;

                        // aggress
                        when(this.base.aggressiveInteractions->keycount > 0 && choice-1 == this.base.interactions->keycount) ::<= {
                            aggress(location:this, party);
                        }
                        
                        Interaction.database.find(name:this.base.interactions[choice-1]).onInteract(
                            location: this,
                            party
                        );
                        this.landmark.step();                            
                    }
                );            
            }
        }
    }
);


@:LOCATION_NAME = 'Wyvern.Location.Base';

Location.Base = class(
    name: LOCATION_NAME,
    inherits : [Database.Item],
    new::(data) {
        @:this = Location.Base.defaultNew();
        this.initialize(data);
        return this;    
    },
    statics : {
        database  :::<= {
            @db = Database.new(
                name: LOCATION_NAME,
                attributes : {
                    name: String,
                    rarity: Number,
                    descriptions : Object,
                    symbol : String,
                    
                    // List of interaction names
                    interactions : Object,
                    
                    // List of interaction names that will mark you as 
                    // hostile by the owner / occupants. Might initiate 
                    // combat
                    aggressiveInteractions : Object,
                    
                    ownVerb : String,
                    // number of people aside from the owner
                    minOccupants : Number,
                    // number of people aside from the owner
                    maxOccupants : Number,
                    
                    // Whether there can only be one per landmark.
                    // This is strictly followed in dungeons.
                    onePerLandmark: Boolean,

                    // when the location is interacted with, before displaying options
                    // The return value is whether to continue with interaction options 
                    // or not.
                    onInteract : Function,
                    
                    // Called on first time interaction is attempted. 
                    onFirstInteract : Function,
                    
                    // when the location is created
                    onCreate : Function,
                    // called by the world when the time of day changes
                    onTimeChange : Function,
                    // the type of location it is
                    category : Number,
                    
                    // in structural maps, this determines the structure 
                    // size in min units.
                    minStructureSize : Number
                }
            );


            return {
                get ::<- db
            }
        }
    },
    define:::(this) {
        Location.Base.database.add(item:this);
    }

);

Location.Base.new(data:{
    name: 'Entrance',
    rarity: 100000000,
    ownVerb: '',
    category : Location.CATEGORY.ENTRANCE,
    minStructureSize : 1,
    onePerLandmark : false,
    descriptions: [
        "A sturdy gate surrounded by a well-maintained fence around the area.",
        "A decrepit gate surrounded by a feeble attempt at fencing.",
        "A protective gate surrounded by a proper stone wall. Likely for safety."
    ],
    symbol: '#',
    
    interactions : [
        'exit',
    ],
    
    aggressiveInteractions : [            
        'vandalize',
    ],
    
    
    minOccupants : 0,
    maxOccupants : 0,
    
    onFirstInteract ::(location){
    
    },

    onInteract ::(location) {
        return true;
    },            

    
    onCreate ::(location) {
    
    },
    
                
    onTimeChange ::(location, time) {
        // make everyone come home
        //if (time == WORLD.TIME.EVENING) ::<={
            
        //} else ::<={
        
        //}
    }
})

Location.Base.new(data:{
    name: 'Farm',
    rarity: 100,
    ownVerb: 'owned',
    category : Location.CATEGORY.RESIDENTIAL,
    symbol: 'F',
    minStructureSize : 2,
    onePerLandmark : false,

    descriptions: [
        "A well-maintained farm. Looks like an experienced farmer works it.",
        "An old farm. It looks like it has a rich history.",
        "A modest farm. A little sparse, but well-maintained",
    ],
    
    interactions : [
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [            
        'steal',
    ],
    
    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location){
        location.ownedBy = location.landmark.island.newInhabitant();
        @:Profession = import(module:'game_class.profession.mt');
        location.ownedBy.profession = Profession.new(base:Profession.Base.database.find(name:'Farmer'));                
        @:story = import(module:'game_singleton.story.mt');
        
        for(0, 2+(Number.random()*4)->ceil)::(i) {
            // no weight, as the value scales
            location.inventory.add(item:
                Item.new(
                    base:Item.Base.database.getRandomFiltered(filter::(value) <- value.isUnique == false
                                    && value.tier <= location.landmark.island.tier
            
                    ),
                    from:location.ownedBy, rngEnchantHint:true
                )
            );
        }
    },
    
    onInteract ::(location) {
        return true;
    },            
    
    onCreate ::(location) {
    },
                
    onTimeChange ::(location, time) {
        // make everyone come home
        //if (time == WORLD.TIME.EVENING) ::<={
            
        //} else ::<={
        
        //}
    }
    

})


Location.Base.new(data:{
    name: 'Home',
    rarity: 100,
    ownVerb: 'owned',
    category : Location.CATEGORY.RESIDENTIAL,
    symbol: '^',
    minStructureSize : 1,
    onePerLandmark : false,

    descriptions: [
        "A well-kept residence. Looks like it's big enough to hold a few people",
        "An old residence. It looks like it has a rich history.",
        "A modest residence. Not too much in the way of amenities, but probably lived in by someone trustworthy",
        "An ornate residence. Unexpectedly, this seems lived in by people of wealth.",
        "An average residence. Nothing short of ordinary."
    ],
    
    interactions : [
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [            
        'steal',
        'vandalize',
    ],
    
    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {
        location.ownedBy = location.landmark.island.newInhabitant();
        @:story = import(module:'game_singleton.story.mt');
    
        for(0, 2+(Number.random()*4)->ceil)::(i) {
            // no weight, as the value scales
            location.inventory.add(
                item:Item.new(
                    base:Item.Base.database.getRandomFiltered(filter::(value) <- value.isUnique == false
                                    && value.tier <= location.landmark.island.tier
            
                    ),
                    from:location.ownedBy, rngEnchantHint:true
                )
            );
        }
    },            
    onInteract ::(location) {            
        return true;

    },            
    
    onCreate ::(location) {
    
    },
                
    onTimeChange ::(location, time) {
        // make everyone come home
        //if (time == WORLD.TIME.EVENING) ::<={
            
        //} else ::<={
        
        //}
    }
    

})

Location.Base.new(data:{
    name: 'Ore vein',
    rarity: 100,
    ownVerb: '???',
    category : Location.CATEGORY.UTILITY,
    symbol: '%',
    minStructureSize : 1,

    descriptions: [
        "A rocky area with a clearly different color than the its surroundings."
    ],
    
    interactions : [
        'mine',
        'examine'
    ],
    
    aggressiveInteractions : [            
    ],
    
    
    minOccupants : 0,
    maxOccupants : 0,
    onePerLandmark : false,
    onFirstInteract ::(location) {
    },            
    onInteract ::(location) {
        return true;

    },            
    
    onCreate ::(location) {
    
    },
                
    onTimeChange ::(location, time) {

    }
    

})


Location.Base.new(data:{
    name: 'Smelter',
    rarity: 100,
    ownVerb: '???',
    category : Location.CATEGORY.UTILITY,
    symbol: 'm',
    onePerLandmark : false,
    minStructureSize : 1,

    descriptions: [
        "Heated enough to melt metal."
    ],
    
    interactions : [
        'smelt ore',
        'examine'
    ],
    
    aggressiveInteractions : [
        'vandalize',                        
    ],
    
    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {

    },            
    onInteract ::(location) {
        return true;

    },            
    
    onCreate ::(location) {
    
    },
                
    onTimeChange ::(location, time) {
        // make everyone come home
        //if (time == WORLD.TIME.EVENING) ::<={
            
        //} else ::<={
        
        //}
    }
    

})


Location.Base.new(data:{
    name: 'Wyvern Throne of Fire',
    rarity: 1,
    ownVerb : 'owned',
    category : Location.CATEGORY.RESIDENTIAL,
    symbol: 'W',
    onePerLandmark : true,
    minStructureSize : 1,

    descriptions: [
        "What seems to be a stone throne",
    ],
    interactions : [
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    
    onFirstInteract ::(location) {
    },
    onInteract ::(location) {
        return true;

    },            
    
    onCreate ::(location) {
        location.name = 'Wyvern Throne';
        @:Profession = import(module:'game_class.profession.mt');
        @:Species = import(module:'game_class.species.mt');
        @:Story = import(module:'game_singleton.story.mt');
        @:Scene = import(module:'game_class.scene.mt');
        @:StatSet = import(module:'game_class.statset.mt');
        location.ownedBy = location.landmark.island.newInhabitant();
        location.ownedBy.name = 'Wyvern of Fire';
        location.ownedBy.species = Species.database.find(name:'Wyvern of Fire');
        location.ownedBy.profession = Profession.new(base:Profession.Base.database.find(name:'Wyvern of Fire'));               
        location.ownedBy.clearAbilities();
        foreach(location.ownedBy.profession.gainSP(amount:10))::(i, ability) {
            location.ownedBy.learnAbility(name:ability);
        }

        
        location.ownedBy.onInteract = ::(party, location, onDone) {
            if (Story.tier < 1) ::<= {
                Scene.database.find(name:'scene_wyvernfire0').act(onDone::{}, location, landmark:location.landmark);
            } else ::<= {
                // just visiting!
                Scene.database.find(name:'scene_wyvernfire1').act(onDone::{}, location, landmark:location.landmark);                        
            }
        }
        location.ownedBy.stats.load(serialized:StatSet.new(
            HP:   150,
            AP:   999,
            ATK:  12,
            INT:  5,
            DEF:  11,
            LUK:  8,
            SPD:  25,
            DEX:  10
        ).save());
        location.ownedBy.heal(amount:9999, silent:true); 
        location.ownedBy.healAP(amount:9999, silent:true); 

        



    },
    
    onTimeChange::(location, time) {
    
    }
})


Location.Base.new(data:{
    name: 'Wyvern Throne of Ice',
    rarity: 1,
    ownVerb : 'owned',
    category : Location.CATEGORY.RESIDENTIAL,
    symbol: 'W',
    onePerLandmark : true,
    minStructureSize : 1,

    descriptions: [
        "What seems to be a stone throne",
    ],
    interactions : [
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    
    onFirstInteract ::(location) {
    },
    onInteract ::(location) {
        return true;

    },            
    
    onCreate ::(location) {
        location.name = 'Wyvern Throne';
        @:Profession = import(module:'game_class.profession.mt');
        @:Species = import(module:'game_class.species.mt');
        @:Story = import(module:'game_singleton.story.mt');
        @:Scene = import(module:'game_class.scene.mt');
        @:StatSet = import(module:'game_class.statset.mt');
        location.ownedBy = location.landmark.island.newInhabitant();
        location.ownedBy.name = 'Wyvern of Ice';
        location.ownedBy.species = Species.database.find(name:'Wyvern of Ice');
        location.ownedBy.profession = Profession.new(base:Profession.Base.database.find(name:'Wyvern of Ice'));               
        location.ownedBy.clearAbilities();
        foreach(location.ownedBy.profession.gainSP(amount:10))::(i, ability) {
            location.ownedBy.learnAbility(name:ability);
        }

        
        location.ownedBy.onInteract = ::(party, location, onDone) {
            if (Story.tier < 2) ::<= {
                Scene.database.find(name:'scene_wyvernice0').act(onDone::{}, location, landmark:location.landmark);
            } else ::<= {
                // just visiting!
                Scene.database.find(name:'scene_wyvernice1').act(onDone::{}, location, landmark:location.landmark);                        
            }
        }
        location.ownedBy.stats.load(serialized:StatSet.new(
            HP:   200,
            AP:   999,
            ATK:  12,
            INT:  8,
            DEF:  7,
            LUK:  6,
            SPD:  20,
            DEX:  12
        ).save());
        location.ownedBy.heal(amount:9999, silent:true); 
        location.ownedBy.healAP(amount:9999, silent:true); 

        



    },
    
    onTimeChange::(location, time) {
    
    }
})


Location.Base.new(data:{
    name: 'Wyvern Throne of Thunder',
    rarity: 1,
    ownVerb : 'owned',
    category : Location.CATEGORY.RESIDENTIAL,
    symbol: 'W',
    onePerLandmark : true,
    minStructureSize : 1,

    descriptions: [
        "What seems to be a stone throne",
    ],
    interactions : [
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    
    onFirstInteract ::(location) {
    },
    onInteract ::(location) {
        return true;

    },            
    
    onCreate ::(location) {
        location.name = 'Wyvern Throne';
        @:Profession = import(module:'game_class.profession.mt');
        @:Species = import(module:'game_class.species.mt');
        @:Story = import(module:'game_singleton.story.mt');
        @:Scene = import(module:'game_class.scene.mt');
        @:StatSet = import(module:'game_class.statset.mt');
        location.ownedBy = location.landmark.island.newInhabitant();
        location.ownedBy.name = 'Wyvern of Thunder';
        location.ownedBy.species = Species.database.find(name:'Wyvern of Thunder');
        location.ownedBy.profession = Profession.new(base:Profession.Base.database.find(name:'Wyvern of Thunder'));               
        location.ownedBy.clearAbilities();
        foreach(location.ownedBy.profession.gainSP(amount:10))::(i, ability) {
            location.ownedBy.learnAbility(name:ability);
        }

        
        location.ownedBy.onInteract = ::(party, location, onDone) {
            if (Story.tier < 3) ::<= {
                Scene.database.find(name:'scene_wyvernthunder0').act(onDone::{}, location, landmark:location.landmark);
            } else ::<= {
                // just visiting!
                Scene.database.find(name:'scene_wyvernthunder1').act(onDone::{}, location, landmark:location.landmark);                        
            }
        }
        location.ownedBy.stats.load(serialized:StatSet.new(
            HP:   350,
            AP:   999,
            ATK:  15,
            INT:  10,
            DEF:  10,
            LUK:  9,
            SPD:  30,
            DEX:  16
        ).save());
        location.ownedBy.heal(amount:9999, silent:true); 
        location.ownedBy.healAP(amount:9999, silent:true); 

        



    },
    
    onTimeChange::(location, time) {
    
    }
})


Location.Base.new(data:{
    name: 'Wyvern Throne of Light',
    rarity: 1,
    ownVerb : 'owned',
    category : Location.CATEGORY.RESIDENTIAL,
    symbol: 'W',
    onePerLandmark : true,
    minStructureSize : 1,

    descriptions: [
        "What seems to be a stone throne",
    ],
    interactions : [
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    
    onFirstInteract ::(location) {
    },
    onInteract ::(location) {
        return true;

    },            
    
    onCreate ::(location) {
        location.name = 'Wyvern Throne';
        @:Profession = import(module:'game_class.profession.mt');
        @:Entity = import(module:'game_class.entity.mt');
        @:Species = import(module:'game_class.species.mt');
        @:Story = import(module:'game_singleton.story.mt');
        @:Scene = import(module:'game_class.scene.mt');
        @:StatSet = import(module:'game_class.statset.mt');
        location.ownedBy = location.landmark.island.newInhabitant();
        location.ownedBy.name = 'Wyvern of Light';
        location.ownedBy.species = Species.database.find(name:'Wyvern of Light');
        location.ownedBy.profession = Profession.new(base:Profession.Base.database.find(name:'Wyvern of Light'));               
        location.ownedBy.clearAbilities();
        foreach(location.ownedBy.profession.gainSP(amount:10))::(i, ability) {
            location.ownedBy.learnAbility(name:ability);
        }

        
        location.ownedBy.onInteract = ::(party, location, onDone) {
            if (Story.tier < 4) ::<= {
                Scene.database.find(name:'scene_wyvernlight0').act(onDone::{}, location, landmark:location.landmark);
            } else ::<= {
                // just visiting!
                Scene.database.find(name:'scene_wyvernlight1').act(onDone::{}, location, landmark:location.landmark);                        
            }
        }
        location.ownedBy.stats.load(serialized:StatSet.new(
            HP:   650,
            AP:   999,
            ATK:  25,
            INT:  10,
            DEF:  3,
            LUK:  6,
            SPD:  100,
            DEX:  20
        ).save());
        
        location.ownedBy.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
        location.ownedBy.heal(amount:9999, silent:true); 
        location.ownedBy.healAP(amount:9999, silent:true); 

        



    },
    
    onTimeChange::(location, time) {
    
    }
})

Location.Base.new(data:{
    name: 'Shop',
    rarity: 100,
    ownVerb : 'run',
    category : Location.CATEGORY.BUSINESS,
    symbol: '$',
    onePerLandmark : false,
    minStructureSize : 1,

    descriptions: [
        "A modest trading shop. Relatively small.",
        "Extravagant shop with many wild trinkets."
    ],
    interactions : [
        'buy:shop',
        'sell:shop',
        'bag:shop',
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [
        'steal',
        'vandalize',            
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {
        @:Profession = import(module:'game_class.profession.mt');
        location.ownedBy = location.landmark.island.newInhabitant();            
        location.ownedBy.profession = Profession.new(base:Profession.Base.database.find(name:'Trader'));
        location.name = 'Shop';
        location.inventory.maxItems = 50;

        @:nameGen = import(module:'game_singleton.namegen.mt');
        @:story = import(module:'game_singleton.story.mt');

        for(0, 30 + (location.ownedBy.level / 4)->ceil)::(i) {
            // no weight, as the value scales
            location.inventory.add(item:
                Item.new(
                    base:Item.Base.database.getRandomFiltered(
                        filter:::(value) <- value.isUnique == false &&
                                            location.ownedBy.level >= value.levelMinimum
                                            && value.tier <= location.landmark.island.tier
                    ),
                    from:location.ownedBy, 
                    rngEnchantHint:true
                )
            );
        }



        location.inventory.add(item:Item.new(base:Item.Base.database.find(
            name: 'Skill Crystal'
        ), from:location.ownedBy));                
        location.inventory.add(item:Item.new(base:Item.Base.database.find(
            name: 'Skill Crystal'
        ), from:location.ownedBy));                
        location.inventory.add(item:Item.new(base:Item.Base.database.find(
            name: 'Pickaxe'
        ), from:location.ownedBy));                
        location.inventory.add(item:Item.new(base:Item.Base.database.find(
            name: 'Smithing Hammer'
        ), from:location.ownedBy));                
    },
    onInteract ::(location) {
        return true;

    },            
    
    onCreate ::(location) {

    },
    
    onTimeChange::(location, time) {
    
    }
})


Location.Base.new(data:{
    name: 'Enchant Stand',
    rarity: 100,
    ownVerb : 'run',
    category : Location.CATEGORY.BUSINESS,
    symbol: '$',
    onePerLandmark : false,
    minStructureSize : 1,

    descriptions: [
        'An enchanter\'s stand.'
    ],
    interactions : [
        'enchant',
        'disenchant',
        'transfer-enchant',
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [
        'vandalize',            
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {
        location.ownedBy = location.landmark.island.newInhabitant();
    
    
        @:ItemEnchant = import(module:'game_class.itemenchant.mt');
    
        location.data.enchants = [
            ItemEnchant.database.getRandom().name,
            ItemEnchant.database.getRandom().name,
            ItemEnchant.database.getRandom().name,
            ItemEnchant.database.getRandom().name
        ];

        for(0, location.data.enchants->keycount)::(i) {
            when (i > location.data.enchants->keycount) empty;
            for(0, location.data.enchants->keycount)::(n) {
                when (i == n) empty;
                when (n > location.data.enchants->keycount) empty;
            
                if (location.data.enchants[i] ==
                    location.data.enchants[n])
                    location.data.enchants->remove(key:n);
            }
        }
    },            
    onInteract ::(location) {
        return true;

    },            
    
    onCreate ::(location) {


    },
    
    onTimeChange::(location, time) {
    
    }
})

Location.Base.new(data:{
    name: 'Blacksmith',
    rarity: 100,
    ownVerb : 'run',
    category : Location.CATEGORY.BUSINESS,
    symbol: '/',
    minStructureSize : 1,

    descriptions: [
        "A modest trading shop. Relatively small.",
        "Extravagant shop with many wild trinkets."
    ],
    onePerLandmark : false,
    interactions : [
        'buy:shop',
        'forge',
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [
        'steal',
        'vandalize',            
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {
        @:Profession = import(module:'game_class.profession.mt');
        location.ownedBy = location.landmark.island.newInhabitant();            
        location.ownedBy.profession = Profession.new(base:Profession.Base.database.find(name:'Blacksmith'));
        location.name = 'Blacksmith';
        @:story = import(module:'game_singleton.story.mt');
        for(0, 1 + (location.ownedBy.level / 4)->ceil)::(i) {

            location.inventory.add(
                item:Item.new(
                    base: Item.Base.database.getRandomFiltered(
                        filter::(value) <- (
                            value.isUnique == false && 
                            location.ownedBy.level >= value.levelMinimum &&
                            value.hasAttribute(attribute:Item.ATTRIBUTE.METAL)
                        )
                    ),
                    from:location.ownedBy
                )
            );

        }
    },            
    onInteract ::(location) {
        
        return true;

    },            
    
    onCreate ::(location) {

    },
    
    onTimeChange::(location, time) {
    
    }
})        


Location.Base.new(data:{
    name: 'Tavern',
    rarity: 100,
    ownVerb : 'run',
    category : Location.CATEGORY.UTILITY,
    symbol: '&',
    onePerLandmark : false,
    minStructureSize : 2,

    descriptions: [
        "A modest tavern with a likely rich history.",
    ],
    interactions : [
        'drink:tavern',
        'examine'
    ],
    
    aggressiveInteractions : [
        'steal',
        'vandalize',            
    ],


    
    minOccupants : 1,
    maxOccupants : 6,
    onFirstInteract ::(location) {
        location.ownedBy = location.landmark.island.newInhabitant();            
    },
    
    onInteract ::(location) {

    },            
    onCreate ::(location) {

    },
    
    onTimeChange::(location, time) {
    
    }
})

Location.Base.new(data:{
    name: 'Arena',
    rarity: 100,
    ownVerb : 'run',
    category : Location.CATEGORY.UTILITY,
    symbol: '!',
    onePerLandmark : false,
    minStructureSize : 2,

    descriptions: [
        "A fighting arena",
    ],
    interactions : [
        //'compete',
        'bet',
        'examine'
    ],
    
    aggressiveInteractions : [
        'steal',
        'vandalize',            
    ],


    
    minOccupants : 1,
    maxOccupants : 6,
    onFirstInteract ::(location) {},
    
    onInteract ::(location) {

    },            
    onCreate ::(location) {

    },
    
    onTimeChange::(location, time) {
    
    }
})

Location.Base.new(data:{
    name: 'Inn',
    rarity: 100,
    ownVerb : 'run',
    category : Location.CATEGORY.UTILITY,
    symbol: '=',
    onePerLandmark : false,
    minStructureSize : 2,


    descriptions: [
        "An inn",
    ],
    interactions : [
        'rest',
        'examine'
    ],
    
    aggressiveInteractions : [
        'steal',
        'vandalize',            
    ],


    
    minOccupants : 1,
    maxOccupants : 4,
    onFirstInteract ::(location) {},
    
    onInteract ::(location) {

    },            
    onCreate ::(location) {

    },
    
    onTimeChange::(location, time) {
    
    }
})

Location.Base.new(data:{
    name: 'School',
    rarity: 100,
    ownVerb : 'run',
    category : Location.CATEGORY.UTILITY,
    symbol: '+',
    onePerLandmark : false,
    minStructureSize : 2,

    descriptions: [
        "A school.",
    ],
    interactions : [
        'change profession',
        'examine'
    ],
    
    aggressiveInteractions : [
        'steal',
        'vandalize',            
    ],


    
    minOccupants : 1,
    maxOccupants : 4,
    onFirstInteract ::(location) {},
    
    onInteract ::(location) {
        
    },            
    onCreate ::(location) {
        location.ownedBy = location.landmark.island.newInhabitant();
        location.name = location.ownedBy.profession.base.name + ' school';
    },
    
    onTimeChange::(location, time) {
    
    }
})

Location.Base.new(data:{
    name: 'Library',
    rarity: 100,
    ownVerb : '',
    category : Location.CATEGORY.UTILITY,
    symbol: '[]',
    onePerLandmark : true,
    minStructureSize : 2,

    descriptions: [
        "A library",
    ],
    interactions : [
        'browse',
        'examine'
    ],
    
    aggressiveInteractions : [
        'steal',
        'vandalize',            
    ],


    
    minOccupants : 1,
    maxOccupants : 10,
    onFirstInteract ::(location) {},
    
    onInteract ::(location) {
        
    },            
    onCreate ::(location) {
    },
    
    onTimeChange::(location, time) {
    
    }
})


Location.Base.new(data:{
    name: 'Gate',
    rarity: 100,
    ownVerb : '',
    category : Location.CATEGORY.UTILITY,
    symbol: '@',
    onePerLandmark : true,
    minStructureSize : 1,

    descriptions: [
        "A large stone ring, tall enough to fit a few people and a wagon.",
    ],
    interactions : [
        'enter gate',
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    
    onFirstInteract ::(location) {},
    onInteract ::(location) {
        return true;                
    },
    
    onCreate ::(location) {
        location.contested = true;
    },
    
    onTimeChange::(location, time) {
    
    }
})

Location.Base.new(data:{
    name: 'Stairs Down',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '\\',
    category : Location.CATEGORY.EXIT,
    onePerLandmark : false,
    minStructureSize : 1,

    descriptions: [
        "Decrepit stairs",
    ],
    interactions : [
        'next floor',
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    
    onFirstInteract ::(location) {},
    onInteract ::(location) {
        @open = location.isUnlockedWithPlate();
        if (!open)  
            windowEvent.queueMessage(text: 'The entry to the stairway is locked. Perhaps some lever or plate nearby can unlock it.');
        return open;            
    },
    
    onCreate ::(location) {
        if (location.landmark.island.tier > 1) 
            if (random.flipCoin()) ::<= {
                location.lockWithPressurePlate();
            }
    },
    
    onTimeChange::(location, time) {
    
    }
})




Location.Base.new(data:{
    name: 'Ladder',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '=',
    onePerLandmark : false,
    category : Location.CATEGORY.EXIT,
    minStructureSize : 1,

    descriptions: [
        "Ladder leading to the surface.",
    ],
    interactions : [
        'climb up',
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    
    onFirstInteract ::(location) {},
    onInteract ::(location) {
    },
    
    onCreate ::(location) {
    },
    
    onTimeChange::(location, time) {
    
    }
})        

Location.Base.new(data:{
    name: '?????',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '?',
    category : Location.CATEGORY.EXIT,
    onePerLandmark : false,
    minStructureSize : 1,

    descriptions: [
        "A suspicious pit.",
    ],
    interactions : [
        'explore pit',
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    
    onFirstInteract ::(location) {},
    onInteract ::(location) {
        @:world = import(module:'game_singleton.world.mt');
        when (world.party.inventory.slotsLeft < 1) ::<= {
            windowEvent.queueMessage(
                text:'You get the feeling that you should have at least one inventory slot open before continuing. Your inventory is currently full.'
            );
            return false;
        }
        return true;
    },
    
    onCreate ::(location) {
        location.contested = true;
    },
    
    onTimeChange::(location, time) {
    
    }
})         



        
Location.Base.new(data:{
    name: 'Small Chest',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '$',
    category : Location.CATEGORY.UTILITY,
    onePerLandmark : false,
    minStructureSize : 1,

    descriptions: [
    ],
    interactions : [
        'open-chest'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {},
    
    onInteract ::(location) {
    },
    
    onCreate ::(location) {
        @:story = import(module:'game_singleton.story.mt');
        location.inventory.add(item:
            Item.new(
                base:Item.Base.database.getRandomFiltered(
                    filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                                            && value.tier <= location.landmark.island.tier
                ),
                rngEnchantHint:true, 
                forceEnchant:true,
                from:location.landmark.island.newInhabitant()
            )
        );
    },
    
    onTimeChange::(location, time) {
    
    }
}) 


Location.Base.new(data:{
    name: 'Magic Chest',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '$',
    category : Location.CATEGORY.UTILITY,
    onePerLandmark : true,
    minStructureSize : 1,

    descriptions: [
    ],
    interactions : [
        'open-magic-chest'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {},
    
    onInteract ::(location) {
    },
    
    onCreate ::(location) {
    },
    
    onTimeChange::(location, time) {
    
    }
}) 


Location.Base.new(data:{
    name: 'Locked Chest',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '$',
    category : Location.CATEGORY.UTILITY,
    onePerLandmark : false,
    minStructureSize : 1,

    descriptions: [
    ],
    interactions : [
        'open-chest'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {},
    
    onInteract ::(location) {
        @open = location.isUnlockedWithPlate();
        if (!open)  
            windowEvent.queueMessage(text: 'The chest is locked. Perhaps some lever or plate nearby can unlock it.');
        return open;            
    },
    
    onCreate ::(location) {
        location.lockWithPressurePlate();    
    
        @:story = import(module:'game_singleton.story.mt');
        for(0, 3) ::{
            location.inventory.add(item:
                Item.new(
                    base:Item.Base.database.getRandomFiltered(
                        filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                                                && value.tier <= location.landmark.island.tier + 1
                    ),
                    rngEnchantHint:true, 
                    forceEnchant:true,
                    from:location.landmark.island.newInhabitant()
                )
            );
        }
    },
    
    onTimeChange::(location, time) {
    
    }
}) 


Location.Base.new(data:{
    name: 'Pressure Plate',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '=',
    category : Location.CATEGORY.UTILITY,
    onePerLandmark : false,
    minStructureSize : 1,

    descriptions: [
    ],
    interactions : [
        'examine-plate',
        'press-pressure-plate'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {},
    
    onInteract ::(location) {
    },
    
    onCreate ::(location) {
        location.data.pressed = false;
    },
    
    onTimeChange::(location, time) {
    
    }
}) 





Location.Base.new(data:{
    name: 'Fountain',
    rarity: 4,
    ownVerb : '',
    symbol: 'S',
    category : Location.CATEGORY.DUNGEON_SPECIAL,
    onePerLandmark : true,
    minStructureSize : 1,

    descriptions: [
        'A simple fountain flowing with fresh water.'
    ],
    interactions : [
        'drink-fountain'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {},
    
    onInteract ::(location) {
    },
    
    onCreate ::(location) {

    },
    
    onTimeChange::(location, time) {
    
    }

});


Location.Base.new(data:{
    name: 'Healing Circle',
    rarity: 4,
    ownVerb : '',
    symbol: 'X',
    category : Location.CATEGORY.DUNGEON_SPECIAL,
    onePerLandmark : true,
    minStructureSize : 1,

    descriptions: [
        'An inscribed circle containing a one-time use healing spell.'
    ],
    interactions : [
        'healing-circle'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {},
    
    onInteract ::(location) {
    },
    
    onCreate ::(location) {
        location.data.used = false;
    },
    
    onTimeChange::(location, time) {
    
    }

});


Location.Base.new(data:{
    name: 'Wyvern Statue',
    rarity: 4,
    ownVerb : '',
    symbol: 'M',
    category : Location.CATEGORY.DUNGEON_SPECIAL,
    onePerLandmark : false,
    minStructureSize : 1,

    descriptions: [
        'A statue depecting a forlorn wyvern holding their hands in the air in sorrow. It\'s very old.',
        'A statue depecting a kneeling wyvern, looking to the sky. It\'s very old.',
        'A statue depecting a wyvern with one wing in the air, and the other wrapping around themself. It\'s very old.',
    ],
    interactions : [
        'pray-statue'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {},
    
    onInteract ::(location) {
    },
    
    onCreate ::(location) {
        location.data.hasPrayer = true;

    },
    
    onTimeChange::(location, time) {
    
    }

});


Location.Base.new(data:{
    name: 'Enchantment Stand',
    rarity: 4,
    ownVerb : '',
    symbol: '%',
    category : Location.CATEGORY.DUNGEON_SPECIAL,
    onePerLandmark : false,
    minStructureSize : 1,

    descriptions: [
        'A stone stand with magic runes.'
    ],
    interactions : [
        'enchant-once'
    ],
    
    aggressiveInteractions : [
    ],

    
    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {
    },  
    
    onInteract ::(location) {
    },
    
    onCreate ::(location) { 
        @:ItemEnchant = import(module:'game_class.itemenchant.mt');
        location.data.enchant = ItemEnchant.new(
            base:ItemEnchant.Base.database.getRandom()
        )
    },
    
    onTimeChange::(location, time) {
    
    }

});


Location.Base.new(data:{
    name: 'Clothing Shop',
    rarity: 4,
    ownVerb : '',
    symbol: '%',
    category : Location.CATEGORY.DUNGEON_SPECIAL,
    onePerLandmark : true,
    minStructureSize : 1,

    descriptions: [
        'A makeshift wooden stand with a crude sign depecting a sheep selling clothing.'
    ],
    interactions : [
        'buy:shop',
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [
        'steal',
        'vandalize'         
    ],

    
    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {
        @:Profession = import(module:'game_class.profession.mt');
        @:Entity = import(module:'game_class.entity.mt');
        @:EntityQuality = import(module:'game_class.entityquality.mt');
        @:world = import(module:'game_singleton.world.mt');                
        when(world.npcs.mei == empty || world.npcs.mei.isIncapacitated())
            location.ownedBy = empty;

        location.ownedBy = world.npcs.mei;
        location.inventory.maxItems = 50;

        @:nameGen = import(module:'game_singleton.namegen.mt');
        @:story = import(module:'game_singleton.story.mt');

        for(0, 10)::(i) {
            // no weight, as the value scales
            location.inventory.add(item:
                Item.new(
                    base:Item.Base.database.getRandomFiltered(
                        filter:::(value) <- value.isApparel == true
                    ),
                    apparelHint: 'Wool+',
                    from:location.ownedBy, 
                    rngEnchantHint:true
                )
            );
        }
    },  
    
    onInteract ::(location) {
        @:story = import(module:'game_singleton.story.mt');
        @:world = import(module:'game_singleton.world.mt');    
                    
        when(location.ownedBy == empty) ::<= {
            windowEvent.queueMessage(
                text: 'The shop seems empty...'
            );
            return false;
        }
        location.ownedBy.onHire = ::{
            @:story = import(module:'game_singleton.story.mt');
            world.npcs.mei = empty;
            world.accoladeEnable(name:'recruitedOPNPC');
        };            
    },
    
    onCreate ::(location) { 
        location.data.peaceful = true;
    },
    
    onTimeChange::(location, time) {
    
    }

});

Location.Base.new(data:{
    name: 'Potion Shop',
    rarity: 4,
    ownVerb : '',
    symbol: 'P',
    category : Location.CATEGORY.DUNGEON_SPECIAL,
    onePerLandmark : true,
    minStructureSize : 1,

    descriptions: [
        'A makeshift wooden stand with a crude sign depecting a drake-kin selling potions.'
    ],
    interactions : [
        'buy:shop',
        'sell:shop',
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [
        'steal',
        'vandalize'         
    ],

    
    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {
        @:Profession = import(module:'game_class.profession.mt');
        @:Entity = import(module:'game_class.entity.mt');
        @:EntityQuality = import(module:'game_class.entityquality.mt');
        @:story = import(module:'game_singleton.story.mt');
        @:world = import(module:'game_singleton.world.mt');                
        when (world.npcs.sylvia == empty || world.npcs.sylvia.isIncapacitated())
            location.ownedBy = empty;

        location.ownedBy = world.npcs.sylvia;
        location.inventory.maxItems = 50;

        @:nameGen = import(module:'game_singleton.namegen.mt');
        @:story = import(module:'game_singleton.story.mt');

        for(0, 14)::(i) {
            @:item = Item.new(
                base:Item.Base.database.getRandomFiltered(
                    filter:::(value) <- value.name->contains(key:'Potion')
                ),
                from:location.ownedBy
            );
            
            // scalping is bad!
            item.price *= 10;

            location.inventory.add(item);
        }
    },  
    
    onInteract ::(location) {
        @:story = import(module:'game_singleton.story.mt');
        when(location.ownedBy == empty) ::<= {
            windowEvent.queueMessage(
                text: 'The shop seems empty...'
            );
            return false;
        }
        location.ownedBy.onHire = ::{
            @:world = import(module:'game_singleton.world.mt');                
            world.npcs.sylvia = empty;
            // Nerfed 'em because too common of an appearance. People can recruit if they want without penalty.
            //world.accoladeEnable(name:'recruitedOPNPC');
        };            
    },
    
    onCreate ::(location) { 
        location.data.peaceful = true;
    },
    
    onTimeChange::(location, time) {
    
    }

});

Location.Base.new(data:{
    name: 'Fancy Shop',
    rarity: 4,
    ownVerb : '',
    symbol: '$',
    category : Location.CATEGORY.DUNGEON_SPECIAL,
    onePerLandmark : true,
    minStructureSize : 1,

    descriptions: [
        'A surprisingly ornate and refined shopping stand.'
    ],
    interactions : [
        'buy:shop',
        'talk',
        'examine'
    ],
    
    aggressiveInteractions : [
        'steal',
        'vandalize'    
    ],

    
    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {
        @:Profession = import(module:'game_class.profession.mt');
        @:Entity = import(module:'game_class.entity.mt');
        @:EntityQuality = import(module:'game_class.entityquality.mt');
        @:world = import(module:'game_singleton.world.mt');                
        when(world.npcs.faus == empty || world.npcs.faus.isIncapacitated()) empty;
            location.ownedBy = empty
            
        location.ownedBy = world.npcs.faus;
        location.inventory.maxItems = 50;

        @:nameGen = import(module:'game_singleton.namegen.mt');
        @:story = import(module:'game_singleton.story.mt');



        @:qualities = [
            'Legendary',
            'Divine',
            'Masterwork',
            'Queen\'s',
            'King\'s'
        ]


        for(0, 10)::(i) {
            // no weight, as the value scales
            location.inventory.add(item:
                Item.new(
                    base:Item.Base.database.getRandomFiltered(
                        filter:::(value) <- value.hasQuality == true
                    ),
                    qualityHint: random.pickArrayItem(list:qualities),
                    from:location.ownedBy, 
                    rngEnchantHint:true
                )
            );
        }
    },  
    
    onInteract ::(location) {
        @:story = import(module:'game_singleton.story.mt');
        when(location.ownedBy == empty) ::<= {
            windowEvent.queueMessage(
                text: 'The shop seems empty...'
            );
            return false;
        }
        
        location.ownedBy.onHire = ::{
            @:world = import(module:'game_singleton.world.mt');                
            world.npcs.faus = empty;            
            world.accoladeEnable(name:'recruitedOPNPC');
        };        
    },
    
    onCreate ::(location) { 
        location.data.peaceful = true;
    },
    
    onTimeChange::(location, time) {
    
    }

});


Location.Base.new(data:{
    name: 'Large Chest',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '$',
    category : Location.CATEGORY.UTILITY,
    minStructureSize : 1,
    onePerLandmark : true,

    descriptions: [
    ],
    interactions : [
        'open-chest'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    
    onFirstInteract ::(location) {
        @:nameGen = import(module:'game_singleton.namegen.mt');
        @:Story = import(module:'game_singleton.story.mt');
        

        @:story = import(module:'game_singleton.story.mt');
        for(0, 3)::(i) {
            location.inventory.add(item:
                Item.new(
                    base:Item.Base.database.getRandomFiltered(
                        filter:::(value) <- value.isUnique == false
                                            && value.tier <= location.landmark.island.tier
                    ),
                    from:location.landmark.island.newInhabitant(),rngEnchantHint:true
                )
            );
        }
        
        location.inventory.add(item:
            Item.new(
                base:Item.Base.database.getRandomFiltered(
                    filter:::(value) <- value.isUnique == false
                                        && value.hasQuality
                ),
                qualityHint : 'Masterwork',
                from:location.landmark.island.newInhabitant(),rngEnchantHint:true
            )
        );        

        location.inventory.add(item:
            Item.new(
                base:Item.Base.database.getRandomFiltered(
                    filter:::(value) <- value.isUnique == false
                                        && value.hasQuality
                ),
                qualityHint : 'Masterwork',
                from:location.landmark.island.newInhabitant(),rngEnchantHint:true
            )
        ); 

    },
    onInteract ::(location) {
    },
    
    onCreate ::(location) {

    },
    
    onTimeChange::(location, time) {
    
    }
})

Location.Base.new(data:{
    name: 'Body',
    rarity: 1000000000000,
    ownVerb : 'owned',
    symbol: 'x',
    category : Location.CATEGORY.UTILITY,
    minStructureSize : 1,
    onePerLandmark : false,

    descriptions: [
        'An incapacitated individual.'
    ],
    interactions : [
        'loot'
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract::(location){},            
    onInteract ::(location) {
    },
    
    onCreate ::(location) {
        foreach(location.ownedBy.inventory.items)::(i, item) {
            location.inventory.add(item);
        }
        location.ownedBy.inventory.clear();
    },
    
    onTimeChange::(location, time) {
    
    }
})        

Location.Base.new(data:{
    name: 'Sylvia\'s Library',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '*',
    category : Location.CATEGORY.UTILITY,
    minStructureSize : 2,
    onePerLandmark : true,

    descriptions: [
        "A library stocked with books many times a person\'s height. Various colors and sizes of book bindings cover each columned shelf",
    ],
    interactions : [
        'sylvia-research',
        'sylvia-tablet',
    ],
    
    aggressiveInteractions : [
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    
    onFirstInteract::(location){},            
    onInteract ::(location) {
        @:world = import(module:'game_singleton.world.mt');                
        if (world.storyFlags.action_interactedSylviaLibrary == false) ::<= {
            Scene.database.find(name:'scene1_0_sylvialibraryfirst').act(location);
            world.storyFlags.action_interactedSylviaLibrary = true;
        }
        
        if (world.party.inventory.items->all(condition:::(value) <- !value.name->contains(key:'Key to'))) ::<= {
            Scene.database.find(name:'scene2_0_sylviakeyout').act(location);
        }
    },
    
    onCreate ::(location) {
    },
    
    onTimeChange::(location, time) {
    
    }
})                


return Location;
