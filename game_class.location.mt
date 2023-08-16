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

@:Location = class(
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
    
    new::(base, landmark, xHint, yHint, state, targetLandmarkHint, ownedByHint) {
        @:this = Location.defaultNew();
        this.initialize(base, landmark, xHint, yHint, state, targetLandmarkHint, ownedByHint);
        return this;
    },
    
    define:::(this) {
        @base_;
        @targetLandmark; // where this location could take the party. Could be a different island in theory
        @occupants = []; // entities. non-owners can shift
        @ownedBy;// entity
        @description;
        @inventory = Inventory.new(size:30);
        @landmark_;
        @x;
        @y;
        @contested = false;
        @name;
        @data = {}; // simple table
        @visited = false;
        ;
        
        
        this.interface = {
            initialize ::(base, landmark, xHint, yHint, state, targetLandmarkHint, ownedByHint) {
                landmark_ = landmark;     

                when(state != empty) ::<={
                    this.state = state;
                    return this;
                }
                base_ = base;
                x = if (xHint == empty) (Number.random() * landmark.width ) else xHint;  
                y = if (yHint == empty) (Number.random() * landmark.height) else yHint;
                if (ownedByHint != empty)
                    ownedBy = ownedByHint;
                       
                description = random.pickArrayItem(list:base.descriptions);            
                base.onCreate(location:this);
                return this;
            },

            state : {
                set ::(value) {
                    @:Entity = import(module:'game_class.entity.mt');
                
                    base_ = Location.Base.database.find(name:value.baseName);
                    name = value.name;
                    contested = value.contested;
                    description = description;
                    ownedBy = if (value.ownedBy == empty) empty else Entity.new(levelHint: 0, state: value.ownedBy);
                    occupants = [];
                    foreach(value.occupants)::(index, occupantData) {
                        occupants->push(value:Entity.new(levelHint: 0, state: occupantData));
                    }
                    inventory.state = value.inventory;
                    x = value.x;
                    y = value.y;
                    data = value.data;
                    targetLandmark = empty;
                    if (value.targetLandmark != empty)
                        targetLandmark = Landmark.new(state:value.targetLandmark);
                        
                        
                    if (data == empty) data = {}
                },
                get :: {
                    return {
                        baseName : base_.name,
                        inventory : inventory.state,
                        occupants : [...occupants]->map(to:::(value) <- value.state),
                        ownedBy : if (ownedBy == empty) empty else ownedBy.state,
                        description : description,
                        targetLandmark : if(targetLandmark == empty) empty else targetLandmark.state,
                        x : x,
                        y : y,
                        contested : contested,
                        name : name,
                        data : data
                    
                    }
                }
            },
            
        
            base : {
                get :: {
                    return base_;
                }
            },
            
            targetLandmark : {
                get ::<- targetLandmark,
                set ::(value) <- targetLandmark = value
            },
            
            inventory : {
                get ::<- inventory
            },
            ownedBy : {
                get ::<- ownedBy,
                set ::(value) <- ownedBy = value
            },
            
            data : {
                get ::<- data
            },
            
            description : {
                get ::<- description + (if (ownedBy != empty) ' This ' + base_.name + ' is ' + base_.ownVerb + ' by ' + ownedBy.name + '.' else '')
            },
            
            contested : {
                get ::<- contested,
                set ::(value) <- contested = value
            },
            x : {
                get:: <- x,
                set::(value) <- x = value
            },
            
            y : {
                get:: <- y,
                set::(value) <- y = value
            },
            
            inventory : {
                get :: <- inventory
            },
            
            name : {
                get::<- if (name == empty) (if (ownedBy == empty) base_.name else (ownedBy.name + "'s " + base_.name)) else name,
                set::(value) <- name = value
            },
            occupants : {
                get :: {
                    return occupants;
                }
            },
            
            discovered : {
                get :: <- true
            },  
            
            
            landmark : {
                get ::<- landmark_
            },
            
            interact ::{
                @world = import(module:'game_singleton.world.mt');
                @party = world.party;            
                @:Interaction = import(module:'game_class.interaction.mt');
            
            
                @:aggress::(location, party) {
                    windowEvent.queueChoices(
                        prompt: 'Aggress how?',
                        choices: location.base.aggressiveInteractions,
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
                
                if (visited == false) ::<= {
                    for(0, random.integer(from:base_.minOccupants, to:base_.maxOccupants))::(i) {
                        occupants->push(value:landmark_.island.newInhabitant());
                    }
                
                
                    visited = true;
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
                    choices->push(value: 'Aggress...');
                    
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

Location.Base = class(
    inherits : [Database.Item],
    new::(data) {
        @:this = Location.Base.defaultNew();
        this.initialize(data);
        return this;    
    },
    statics : {
        database  :::<= {
            @db = Database.new(
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
    name: 'farm',
    rarity: 100,
    ownVerb: 'owned',
    category : Location.CATEGORY.RESIDENTIAL,
    symbol: 'F',
    minStructureSize : 2,

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
                                    && value.tier <= story.tier
            
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
    name: 'home',
    rarity: 100,
    ownVerb: 'owned',
    category : Location.CATEGORY.RESIDENTIAL,
    symbol: '^',
    minStructureSize : 1,

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
                                    && value.tier <= story.tier
            
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
    name: 'ore vein',
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
    name: 'smelter',
    rarity: 100,
    ownVerb: '???',
    category : Location.CATEGORY.UTILITY,
    symbol: 'm',
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
    minStructureSize : 1,

    descriptions: [
        "What seems to be a stone throne",
    ],
    interactions : [
        'talk',
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
        location.ownedBy.stats.state = StatSet.new(
            HP:   150,
            AP:   999,
            ATK:  12,
            INT:  5,
            DEF:  11,
            LUK:  8,
            SPD:  25,
            DEX:  10
        ).state;
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
    minStructureSize : 1,

    descriptions: [
        "What seems to be a stone throne",
    ],
    interactions : [
        'talk',
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
        location.ownedBy.stats.state = StatSet.new(
            HP:   270,
            AP:   999,
            ATK:  12,
            INT:  8,
            DEF:  7,
            LUK:  6,
            SPD:  20,
            DEX:  12
        ).state;
        location.ownedBy.heal(amount:9999, silent:true); 
        location.ownedBy.healAP(amount:9999, silent:true); 

        



    },
    
    onTimeChange::(location, time) {
    
    }
})


Location.Base.new(data:{
    name: 'shop',
    rarity: 100,
    ownVerb : 'run',
    category : Location.CATEGORY.BUSINESS,
    symbol: '$',
    minStructureSize : 1,

    descriptions: [
        "A modest trading shop. Relatively small.",
        "Extravagant shop with many wild trinkets."
    ],
    interactions : [
        'buy:shop',
        'sell:shop',
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
                                            && value.tier <= story.tier
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
            name: 'Skill Crystal'
        ), from:location.ownedBy));                
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
                            && value.tier <= story.tier
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
    minStructureSize : 2,

    descriptions: [
        "A fighting arena",
    ],
    interactions : [
        'compete',
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
    minStructureSize : 2,

    descriptions: [
        "A school",
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
    },
    
    onCreate ::(location) {
    },
    
    onTimeChange::(location, time) {
    
    }
})

Location.Base.new(data:{
    name: 'Ladder',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '=',
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

        return true;
    },
    
    onCreate ::(location) {
        location.contested = true;
    },
    
    onTimeChange::(location, time) {
    
    }
})         




Location.Base.new(data:{
    name: 'Stairs Up',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '^',
    category : Location.CATEGORY.EXIT,
    minStructureSize : 1,

    descriptions: [
        "Decrepit stairs",
    ],
    interactions : [
        'back-floor',
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
    name: 'Small Chest',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '$',
    category : Location.CATEGORY.UTILITY,
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
                                            && value.tier <= story.tier
                ),
                rngEnchantHint:true, 
                from:location.landmark.island.newInhabitant()
            )
        );
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
    minStructureSize : 1,

    descriptions: [
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
    name: 'Large Chest',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '$',
    category : Location.CATEGORY.UTILITY,
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
    
    onFirstInteract ::(location) {
        @:nameGen = import(module:'game_singleton.namegen.mt');
        @:Story = import(module:'game_singleton.story.mt');
        
        match(location.landmark.island.tier) {
            (0):::<= { 
                if (Story.foundFireKey == false)
                    location.inventory.add(item:Item.new(base:Item.Base.database.find(name:'Wyvern Key of Fire'),from:location.ownedBy));
                Story.foundFireKey = true;
            },
            (1):::<= {
                if (Story.foundIceKey == false) 
                    location.inventory.add(item:Item.new(base:Item.Base.database.find(name:'Wyvern Key of Ice'), from:location.ownedBy));                                            
                Story.foundIceKey = true;
            },
            (2):::<= {
                if (Story.foundThunderKey == false)                     
                    location.inventory.add(item:Item.new(base:Item.Base.database.find(name:'Wyvern Key of Thunder'), from:location.ownedBy));
                Story.foundThunderKey = true;
            },
            (3):::<= {
                if (Story.foundLightKey == false) 
                    location.inventory.add(item:Item.new(base:Item.Base.database.find(name:'Wyvern Key of Light'),from:location.ownedBy));
                Story.foundLightKey = true;
            }
        }
        @:story = import(module:'game_singleton.story.mt');
        for(0, 3+(Number.random()*2)->ceil)::(i) {
            location.inventory.add(item:
                Item.new(
                    base:Item.Base.database.getRandomFiltered(
                        filter:::(value) <- value.isUnique == false
                                            && value.tier <= story.tier
                    ),
                    from:location.landmark.island.newInhabitant(),rngEnchantHint:true
                )
            );
        }
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
