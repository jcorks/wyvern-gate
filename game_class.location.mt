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
        Base : empty
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
        this.constructor = ::(base, landmark, xHint, yHint, state, targetLandmarkHint, ownedByHint) {
            landmark_ = landmark;     

            when(state != empty) ::<={
                this.state = state;
                return this;
            };
            base_ = base;
            x = if (xHint == empty) (Number.random() * landmark.width ) else xHint;  
            y = if (yHint == empty) (Number.random() * landmark.height) else yHint;
            if (ownedByHint != empty)
                ownedBy = ownedByHint;
                   
            description = random.pickArrayItem(list:base.descriptions);            
            base.onCreate(location:this);
            return this;
        };
        
        
        this.interface = {
            state : {
                set ::(value) {
                    @:Entity = import(module:'game_class.entity.mt');
                
                    base_ = Location.Base.database.find(name:value.baseName);
                    name = value.name;
                    contested = value.contested;
                    description = description;
                    ownedBy = if (value.ownedBy == empty) empty else Entity.new(levelHint: 0, state: value.ownedBy);
                    occupants = [];
                    value.occupants->foreach(do:::(index, occupantData) {
                        occupants->push(value:Entity.new(levelHint: 0, state: occupantData));
                    });
                    inventory.state = value.inventory;
                    x = value.x;
                    y = value.y;
                    data = value.data;
                    targetLandmark = empty;
                    if (value.targetLandmark != empty)
                        targetLandmark = Landmark.new(state:value.targetLandmark);
                        
                        
                    if (data == empty) data = {};
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
                    
                    };
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
                get:: <- x
            },
            
            y : {
                get:: <- y
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
                            };
                                
                            
                            windowEvent.queueAskBoolean(
                                prompt: 'Are you sure?',
                                onChoice::(which) {
                                    when(which == false) empty;
                                    interaction.onInteract(location, party);                    
                                    
                                    if (location.landmark.peaceful) ::<= {
                                        location.landmark.peaceful = false;
                                        windowEvent.queueMessage(text:'The people here are now aware of your aggression.');
                                    };                
                                                            
                                }
                            );
                        }
                    );
                };            
            
            
                // initial interaction 
                // Initial interaction triggers an event.
                
                if (visited == false) ::<= {
                    [0, random.integer(from:base_.minOccupants, to:base_.maxOccupants)]->for(do:::(i) {
                        occupants->push(value:landmark_.island.newInhabitant());
                    });
                
                
                    visited = true;
                    this.base.onFirstInteract(location:this);
                };
                    
                
                @canInteract = [::] {
                    return this.base.onInteract(location:this);
                };
                    
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
                        };
                        
                        Interaction.database.find(name:this.base.interactions[choice-1]).onInteract(
                            location: this,
                            party
                        );
                        this.landmark.step();                            
                    }
                );            
            }
        };
    }
);

Location.Base = class(
    statics : {
        database : empty
    },
    define:::(this) {
        Database.setup(
            item : this,
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
                onTimeChange : Function
            }
        );
        
        this.interface = {
            new ::(landmark => Landmark.type, xHint, yHint, state, ownedByHint) <- Location.new(base:this, landmark, xHint, yHint, state, ownedByHint) 
        };
    }

);

Location.Base.database = Database.new(
    items : [
        Location.Base.new(data:{
            name: 'Entrance',
            rarity: 100000000,
            ownVerb: '',
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
                
                //};
            }
        }),

        Location.Base.new(data:{
            name: 'farm',
            rarity: 100,
            ownVerb: 'owned',
            symbol: 'F',

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
                location.ownedBy.profession = Profession.Base.database.find(name:'Farmer').new();                
                
                [0, 2+(Number.random()*4)->ceil]->for(do:::(i) {
                    // no weight, as the value scales
                    location.inventory.add(item:Item.Base.database.getRandomFiltered(filter::(value) <- value.isUnique == false)
                    .new(from:location.ownedBy, rngEnchantHint:true));
                });
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
                
                //};
            }
            
        
        }),


        Location.Base.new(data:{
            name: 'home',
            rarity: 100,
            ownVerb: 'owned',
            symbol: '^',

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
            
                [0, 2+(Number.random()*4)->ceil]->for(do:::(i) {
                    // no weight, as the value scales
                    location.inventory.add(item:Item.Base.database.getRandomFiltered(filter::(value) <- value.isUnique == false)
                    .new(from:location.ownedBy, rngEnchantHint:true));
                });            
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
                
                //};
            }
            
        
        }),

        Location.Base.new(data:{
            name: 'ore vein',
            rarity: 100,
            ownVerb: '???',
            symbol: '%',

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
            
        
        }),


        Location.Base.new(data:{
            name: 'smelter',
            rarity: 100,
            ownVerb: '???',
            symbol: 'm',

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
                
                //};
            }
            
        
        }),


        Location.Base.new(data:{
            name: 'Wyvern Throne',
            rarity: 1,
            ownVerb : 'owned',
            symbol: 'W',

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
                match(location.landmark.island.tier) {
                  (0): ::<= {
                    @:Profession = import(module:'game_class.profession.mt');
                    @:Species = import(module:'game_class.species.mt');
                    @:Story = import(module:'game_singleton.story.mt');
                    @:Scene = import(module:'game_class.scene.mt');
                    @:StatSet = import(module:'game_class.statset.mt');
                    location.ownedBy = location.landmark.island.newInhabitant();
                    location.ownedBy.name = 'Kaedjaal, Wyvern of Fire';
                    location.ownedBy.species = Species.database.find(name:'Wyvern of Fire');
                    location.ownedBy.profession = Profession.Base.database.find(name:'Wyvern of Fire').new();               
                    location.ownedBy.clearAbilities();
                    location.ownedBy.profession.gainSP(amount:10)->foreach(do:::(i, ability) {
                        location.ownedBy.learnAbility(name:ability);
                    });

                    
                    location.ownedBy.onInteract = ::(party, location, onDone) {
                        if (!Story.defeatedWyvernFire) ::<= {
                            Scene.database.find(name:'scene_wyvernfire0').act(onDone::{}, location, landmark:location.landmark);
                        } else ::<= {
                            // just visiting!
                            Scene.database.find(name:'scene_wyvernfire1').act(onDone::{}, location, landmark:location.landmark);                        
                        };
                    };
                    location.ownedBy.stats.state = StatSet.new(
                        HP:   110,
                        AP:   999,
                        ATK:  7,
                        INT:  16,
                        DEF:  9,
                        LUK:  8,
                        SPD:  16,
                        DEX:  8
                    ).state;
                    location.ownedBy.heal(amount:9999, silent:true); 
                    location.ownedBy.healAP(amount:9999, silent:true); 
                  },
                  default: ::<= {
                    error(detail:'This wyvern is currently out!');
                  }

                };
                



            },
            
            onTimeChange::(location, time) {
            
            }
        }),

        Location.Base.new(data:{
            name: 'shop',
            rarity: 100,
            ownVerb : 'run',
            symbol: '$',

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
                location.ownedBy.profession = Profession.Base.database.find(name:'Trader').new();
                location.inventory.maxItems = 50;

                @:nameGen = import(module:'game_singleton.namegen.mt');

                [0, 30 + (location.ownedBy.level / 4)->ceil]->for(do:::(i) {
                    // no weight, as the value scales
                    location.inventory.add(item:Item.Base.database.getRandomFiltered(
                        filter:::(value) <- value.isUnique == false &&
                                            location.ownedBy.level >= value.levelMinimum
                    ).new(from:location.ownedBy));
                });



                location.inventory.add(item:Item.Base.database.find(
                    name: 'Skill Crystal'
                ).new(from:location.ownedBy));                
                location.inventory.add(item:Item.Base.database.find(
                    name: 'Skill Crystal'
                ).new(from:location.ownedBy));                
                location.inventory.add(item:Item.Base.database.find(
                    name: 'Skill Crystal'
                ).new(from:location.ownedBy));                
                location.inventory.add(item:Item.Base.database.find(
                    name: 'Skill Crystal'
                ).new(from:location.ownedBy));                
                location.inventory.add(item:Item.Base.database.find(
                    name: 'Skill Crystal'
                ).new(from:location.ownedBy));                
                location.inventory.add(item:Item.Base.database.find(
                    name: 'Pickaxe'
                ).new(from:location.ownedBy));                
                location.inventory.add(item:Item.Base.database.find(
                    name: 'Hammer'
                ).new(from:location.ownedBy));                
            },
            onInteract ::(location) {
                return true;

            },            
            
            onCreate ::(location) {

            },
            
            onTimeChange::(location, time) {
            
            }
        }),
        

        Location.Base.new(data:{
            name: 'Enchant Stand',
            rarity: 100,
            ownVerb : 'run',
            symbol: '$',

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

                [0, location.data.enchants->keycount]->for(do:::(i) {
                    when (i > location.data.enchants->keycount) empty;
                    [0, location.data.enchants->keycount]->for(do:::(n) {
                        when (i == n) empty;
                        when (n > location.data.enchants->keycount) empty;
                    
                        if (location.data.enchants[i] ==
                            location.data.enchants[n])
                            location.data.enchants->remove(key:n);
                    });
                });
            },            
            onInteract ::(location) {
                return true;

            },            
            
            onCreate ::(location) {


            },
            
            onTimeChange::(location, time) {
            
            }
        }),

        Location.Base.new(data:{
            name: 'Blacksmith',
            rarity: 100,
            ownVerb : 'run',
            symbol: '/',

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
                location.ownedBy.profession = Profession.Base.database.find(name:'Blacksmith').new();
                location.name = 'Blacksmith';
                [0, 1 + (location.ownedBy.level / 4)->ceil]->for(do:::(i) {

                    location.inventory.add(
                        item:Item.Base.database.getRandomFiltered(
                            filter::(value) <- (
                                value.isUnique == false && 
                                location.ownedBy.level >= value.levelMinimum &&
                                value.hasAttribute(attribute:Item.ATTRIBUTE.METAL)
                            )
                        ).new(from:location.ownedBy)
                    );

                });
            },            
            onInteract ::(location) {
                
                return true;

            },            
            
            onCreate ::(location) {

            },
            
            onTimeChange::(location, time) {
            
            }
        }),        


        Location.Base.new(data:{
            name: 'Tavern',
            rarity: 100,
            ownVerb : 'run',
            symbol: '&',

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
        }),

        Location.Base.new(data:{
            name: 'Arena',
            rarity: 100,
            ownVerb : 'run',
            symbol: '!',

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
        }),

        Location.Base.new(data:{
            name: 'Inn',
            rarity: 100,
            ownVerb : 'run',
            symbol: '=',

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
        }),

        Location.Base.new(data:{
            name: 'School',
            rarity: 100,
            ownVerb : 'run',
            symbol: '+',

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
        }),

        Location.Base.new(data:{
            name: 'Library',
            rarity: 100,
            ownVerb : '',
            symbol: '[]',

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
        }),


        Location.Base.new(data:{
            name: 'Gate',
            rarity: 100,
            ownVerb : '',
            symbol: '@',

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
        }),
        
        Location.Base.new(data:{
            name: 'Stairs Down',
            rarity: 1000000000000,
            ownVerb : '',
            symbol: '\\',

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
        }),
        
        Location.Base.new(data:{
            name: 'Ladder',
            rarity: 1000000000000,
            ownVerb : '',
            symbol: '=',

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
        }),        
        
        Location.Base.new(data:{
            name: '?????',
            rarity: 1000000000000,
            ownVerb : '',
            symbol: '?',

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
        }),         



        
        Location.Base.new(data:{
            name: 'Stairs Up',
            rarity: 1000000000000,
            ownVerb : '',
            symbol: '^',

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
        }), 
                
        Location.Base.new(data:{
            name: 'Small Chest',
            rarity: 1000000000000,
            ownVerb : '',
            symbol: '$',

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
                location.inventory.add(item:Item.Base.database.getRandomFiltered(
                    filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                ).new(rngEnchantHint:true, from:location.landmark.island.newInhabitant()));
            },
            
            onTimeChange::(location, time) {
            
            }
        }), 


        Location.Base.new(data:{
            name: 'Large Chest',
            rarity: 1000000000000,
            ownVerb : '',
            symbol: '$',

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
                            location.inventory.add(item:Item.Base.database.find(name:'Wyvern Key of Fire').new(from:location.ownedBy));
                        Story.foundFireKey = true;
                    },
                    (1):::<= {
                        if (Story.foundIceKey == false) 
                            location.inventory.add(item:Item.Base.database.find(name:'Wyvern Key of Ice').new(from:location.ownedBy));                                            
                        Story.foundIceKey = true;
                    },
                    (2):::<= {
                        if (Story.foundThunderKey == false)                     
                            location.inventory.add(item:Item.Base.database.find(name:'Wyvern Key of Thunder').new(from:location.ownedBy));
                        Story.foundThunderKey = true;
                    },
                    (3):::<= {
                        if (Story.foundLightKey == false) 
                            location.inventory.add(item:Item.Base.database.find(name:'Wyvern Key of Light').new(from:location.ownedBy));
                        Story.foundLightKey = true;
                    }
                };
                [0, 3+(Number.random()*2)->ceil]->for(do:::(i) {
                    location.inventory.add(item:Item.Base.database.getRandomFiltered(
                        filter:::(value) <- value.isUnique == false
                    ).new(from:location.landmark.island.newInhabitant(),rngEnchantHint:true));
                });            
            },
            onInteract ::(location) {
            },
            
            onCreate ::(location) {

            },
            
            onTimeChange::(location, time) {
            
            }
        }),
        
        Location.Base.new(data:{
            name: 'Body',
            rarity: 1000000000000,
            ownVerb : 'owned',
            symbol: 'x',

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
                location.ownedBy.inventory.items->foreach(do:::(i, item) {
                    location.inventory.add(item);
                });
                location.ownedBy.inventory.clear();
            },
            
            onTimeChange::(location, time) {
            
            }
        }),        
        
        Location.Base.new(data:{
            name: 'Sylvia\'s Library',
            rarity: 1000000000000,
            ownVerb : '',
            symbol: '*',

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
                };
                
                if (world.party.inventory.items->all(condition:::(value) <- !value.name->contains(key:'Key to'))) ::<= {
                    Scene.database.find(name:'scene2_0_sylviakeyout').act(location);
                };
            },
            
            onCreate ::(location) {
            },
            
            onTimeChange::(location, time) {
            
            }
        }),                
        
    
    ]
);


return Location;
