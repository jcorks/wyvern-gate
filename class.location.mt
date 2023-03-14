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
@:Database = import(module:'class.database.mt');
@:class = import(module:'Matte.Core.Class');
@:random = import(module:'singleton.random.mt');
@Landmark = import(module:'class.landmark.mt');
@:Item = import(module:'class.item.mt');
@:Inventory = import(module:'class.inventory.mt');
@:Scene = import(module:'class.scene.mt');
@:dialogue = import(module:'singleton.dialogue.mt');

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
        this.constructor = ::(base, landmark, xHint, yHint, state, targetLandmarkHint, ownedByHint) {
            landmark_ = landmark;     

            when(state != empty) ::<={
                this.state = state;
                return this;
            };
            base_ = base;
            x = if (xHint == empty) (Number.random() * landmark.width ) else xHint;  
            y = if (yHint == empty) (Number.random() * landmark.height) else yHint;
            if (base.owned) ::<= {
                if (ownedByHint == empty)
                    ownedBy = landmark.island.newInhabitant()
                else
                    ownedBy = ownedByHint;
                    
                description = random.pickArrayItem(list:base.descriptions) + ' This ' + base.name + ' is ' + base.ownVerb + ' by ' + ownedBy.name + '.';
            } else ::<= {
                description = random.pickArrayItem(list:base.descriptions);            
            };
            [0, random.integer(from:base.minOccupants, to:base.maxOccupants)]->for(do:::(i) {
                occupants->push(value:landmark.island.newInhabitant());
            });
            name = if (ownedBy == empty) base_.name else (ownedBy.name + "'s " + base_.name);
            base.onCreate(location:this);
            return this;
        };
        
        
        this.interface = {
            state : {
                set ::(value) {
                    @:Entity = import(module:'class.entity.mt');
                
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
                get ::<- description
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
                get::<- name,
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
                owned : Boolean,
                
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
            owned : false,
            descriptions: [
                "A sturdy gate surrounded by a well-maintained fence around the area.",
                "A decrepit gate surrounded by a feeble attempt at fencing.",
                "A protective gate surrounded by a proepr stone wall. Likely for safety."
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
            owned : true,
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
            
            onInteract ::(location) {
                return true;

            },            
            
            onCreate ::(location) {
                @:Profession = import(module:'class.profession.mt');
            
                location.ownedBy.profession = Profession.Base.database.find(name:'Farmer').new();
            
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
            owned : true,
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
            owned : false,
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
            owned : false,
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
            name: 'shop',
            rarity: 100,
            ownVerb : 'run',
            symbol: '$',
            owned : true,

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
            
            onInteract ::(location) {
                return true;

            },            
            
            onCreate ::(location) {
                @:Profession = import(module:'class.profession.mt');
            
                location.ownedBy.profession = Profession.Base.database.find(name:'Trader').new();

                @:nameGen = import(module:'singleton.namegen.mt');

                [0, 4 + (location.ownedBy.level / 4)->ceil]->for(do:::(i) {
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
                    name: 'Pickaxe'
                ).new(from:location.ownedBy));                
                location.inventory.add(item:Item.Base.database.find(
                    name: 'Hammer'
                ).new(from:location.ownedBy));                


            },
            
            onTimeChange::(location, time) {
            
            }
        }),
        
        Location.Base.new(data:{
            name: 'Blacksmith',
            rarity: 100,
            ownVerb : 'run',
            symbol: '/',
            owned : true,

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
            
            onInteract ::(location) {
                
                return true;

            },            
            
            onCreate ::(location) {
                @:Profession = import(module:'class.profession.mt');
            
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
            
            onTimeChange::(location, time) {
            
            }
        }),        


        Location.Base.new(data:{
            name: 'Tavern',
            rarity: 100,
            ownVerb : 'run',
            symbol: '&',
            owned : false,

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
            owned : false,

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
            owned : false,

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
            owned : true,

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
            
            onInteract ::(location) {
                
            },            
            onCreate ::(location) {
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
            owned : false,

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
            owned : false,

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
            owned : false,

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
            owned : false,

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
            
            onInteract ::(location) {
                @:world = import(module:'singleton.world.mt');
                @:Event = import(module:'class.event.mt');

                if (location.contested == true) ::<= {
                    @:event = Event.Base.database.find(name:'Encounter:TreasureBoss').new(
                        island:location.landmark.island,
                        party:world.party,
                        currentTime:0, // TODO,
                        landmark:location.landmark
                    );  
                    location.contested = false;
                };
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
            owned : false,

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
            owned : false,

            descriptions: [
            ],
            interactions : [
                'open-chest'
            ],
            
            aggressiveInteractions : [
            ],


            
            minOccupants : 0,
            maxOccupants : 0,
            
            onInteract ::(location) {
            },
            
            onCreate ::(location) {
                location.inventory.add(item:Item.Base.database.getRandomFiltered(
                    filter:::(value) <- value.isUnique == false
                ).new(from:location.landmark.island.newInhabitant()));
            },
            
            onTimeChange::(location, time) {
            
            }
        }), 


        Location.Base.new(data:{
            name: 'Large Chest',
            rarity: 1000000000000,
            ownVerb : '',
            symbol: '$',
            owned : false,

            descriptions: [
            ],
            interactions : [
                'open-chest'
            ],
            
            aggressiveInteractions : [
            ],


            
            minOccupants : 0,
            maxOccupants : 0,
            
            onInteract ::(location) {
            },
            
            onCreate ::(location) {
                @:nameGen = import(module:'singleton.namegen.mt');
                location.inventory.add(item:Item.Base.database.find(name:'Wyvern Key').new(from:location.ownedBy, creationHint:{
                    levelHint: ((location.landmark.island.levelMax * 1.1) + 5)->floor,
                    nameHint: nameGen.island()
                }));
                [0, 3+(Number.random()*2)->ceil]->for(do:::(i) <-
                    location.inventory.add(item:Item.Base.database.getRandomFiltered(
                        filter:::(value) <- value.isUnique == false
                    ).new(from:location.landmark.island.newInhabitant()))
                );
            },
            
            onTimeChange::(location, time) {
            
            }
        }),
        
        Location.Base.new(data:{
            name: 'Body',
            rarity: 1000000000000,
            ownVerb : 'owned',
            symbol: 'x',
            owned : true,

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
            owned : false,

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
            
            onInteract ::(location) {
                @:world = import(module:'singleton.world.mt');                
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
