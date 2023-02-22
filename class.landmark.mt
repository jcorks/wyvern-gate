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
@:class = import(module:'Matte.Core.Class');
@:random = import(module:'singleton.random.mt');
@:NameGen = import(module:'singleton.namegen.mt');
@:Database = import(module:'class.database.mt');
@:Map = import(module:'class.map.mt');
@Location = empty; // circular dep.

@:Landmark = class(  
    name : 'Wyvern.Landmark',
    statics : {
        Base : empty
    },
    define :::(this) {
        if (Location == empty) Location = import(module:'class.location.mt');
        @name;
        @landmark;
        @x_;
        @y_;
        @discovered = false;
        @locations = [];
        @island_;
        @size = random.integer(from:5, to:10)->ceil;
        @peaceful;
        @floor = 0;
        @map = Map.new();
        map.size = size;
        @gate;



        this.constructor = ::(base, island, x, y, state){
            island_ = island;
            when(state != empty) ::<= {
                this.state = state;
                return this;
            };

            if (base.isUnique)
                name = ''
            else
                name = NameGen.place();
            landmark = base;
            x_ = x;
            y_ = y;
            peaceful = base.peaceful;
            /*
            [0, Random.integer(from:base.minLocations, to:base.maxLocations)]->for(do:::(i) {
                locations->push(value:island.newInhabitant());            
            });
            */
            map.size = size;
            @mapIndex = 0;




            match ((Number.random()*4)->floor) {
              (0)::<= {
                gate = Location.Base.database.find(name:'Entrance').new(
                    landmark:this, 
                    xHint:0,
                    yHint:Number.random()*size
                );                
              },
              (1)::<= {
                gate = Location.Base.database.find(name:'Entrance').new(
                    landmark:this, 
                    xHint:size - 0.1,
                    yHint:Number.random()*size
                );                
              },
              (2)::<= {
                gate = Location.Base.database.find(name:'Entrance').new(
                    landmark:this, 
                    xHint:Number.random()*size,
                    yHint:0
                );                
              },
              (3)::<= {
                gate = Location.Base.database.find(name:'Entrance').new(
                    landmark:this, 
                    xHint:Number.random()*size,
                    yHint:size-0.1
                );                
              }


            };           

            
            
            locations->push(value:gate);
            map.setItem(object:gate, x:gate.x, y:gate.y, symbol: gate.base.symbol);
            map.title = landmark.name + (
                if (name == '') '' else (' of ' + name)
            );








            base.requiredLocations->foreach(do:::(i, loc) {
                @loc = Location.Base.database.find(name:loc).new(landmark:this);
                map.setItem(object:loc, x:loc.x, y:loc.y, symbol: loc.base.symbol);
                mapIndex += 1;
                locations->push(value:loc);
            });
            
            [0, random.integer(from:base.minLocations, to:base.maxLocations)]->for(do:::(i) {
                when(base.possibleLocations->keycount == 0) empty;
                @:which = random.pickArrayItemWeighted(list:base.possibleLocations);
                @:loc = Location.Base.database.find(name:which.name).new(landmark:this);
                map.setItem(object:loc, x:loc.x, y:loc.y, symbol: loc.base.symbol);
                mapIndex += 1;

                locations->push(value:loc);
            });
            
            
            return this;
        };    

        this.interface =  {
            state : {
                set ::(value) {
                    landmark = Landmark.Base.database.find(name:value.baseName);
                    x_ = value.x;
                    y_ = value.y;
                    discovered = value.discovered;
                    name = value.name;
                    size = value.size;
                    peaceful = value.peaceful;
                    floor = value.floor;
                    locations = [];
                    map = Map.new();
                    gate = empty;
                    value.locations->foreach(do:::(index, location) {
                        @loc = Location.Base.database.find(name:location.baseName).new(landmark:this, state:location);
                        if (loc.base.name == 'Entrance')
                            gate = loc;

                        map.setItem(
                            object:loc,
                            x: loc.x,
                            y: loc.y,
                            symbol: loc.base.symbol
                        );
                        locations->push(value:loc);
                    });
                    if (gate == empty)
                        error(detail: 'landmark state is missing an Entrance.');

                    map.state = value.map;
                },
            
                get :: {
                    return {
                        baseName : landmark.name,
                        name : name,
                        x: x_,
                        y: y_,
                        size : size,
                        peaceful : peaceful,
                        map : map.state,
                        floor : floor,
                        locations : [...locations]->map(to:::(value) <- value.state),
                        discovered : discovered
                        
                    };
                }
            },
        
            description : {
                get :: {
                    @out = name + ', a ' + landmark.name;
                    if (locations->keycount > 0) ::<={
                        out = out + ' with ' + locations->keycount + ' permanent inhabitants';//:\n';
                        //foreach(in:locations, do:::(index, inhabitant) {
                        //    out = out + '   ' + inhabitant.name + ', a ' + inhabitant.species.name + ' ' + inhabitant.profession.base.name +'\n';
                        //});
                    };
                    return out;
                }
            },

            base : {
                get ::<- landmark
            },
            
            name : {
                get :: {
                    return name;                
                },
                
                set ::(value) {
                    name = value;
                    map.title = value;
                }
            },
            
            x : {
                get ::<- x_
            },
            
            y : {
                get ::<- y_
            },
            
            size : {
                get ::<- size
            },
            
            peaceful : {
                get :: <- peaceful,
                set ::(value) <- peaceful = value
            },

            floor : {
                get :: <- floor,
                set ::(value) <- floor = value
            },

            
            kind : {
                get :: {
                    return landmark.name;
                }
            },
            
            gate : {
                get :: <- gate
            },
            discover :: {
                @:world = import(module:'singleton.world.mt');
                @:dialogue = import(module:'singleton.dialogue.mt');
                if (!discovered)
                    if (world.party.inventory.items->filter(by:::(value) <- value.base.name == 'Runestone')->keycount != 0) ::<= {
                        world.storyFlags.data_locationsDiscovered += 1;
                        dialogue.message(text:'Location found! ' + world.storyFlags.data_locationsDiscovered + ' / ' 
                                                                 + world.storyFlags.data_locationsNeeded + ' locations.');               
                    };
                discovered = true;
            },
            
            discovered : {
                get ::<- discovered
            },
            
            locations : {
                get :: <- locations 
            },

            
            island : {
                get ::<- island_
            },
            
            map : {
                get ::<- map
            },
            
            inhabitants : {
                get :: {
                    return locations;
                }
            }
        };
    }
);


Landmark.Base = class(
    name : 'Wyvern.Landmark.Base',
    statics : {
        database : empty
    },
    define:::(this) {
        @kind;
        Database.setup(
            item: this,
            attributes : {
                name : String,
                symbol : String,
                rarity: Number,
                isUnique : Boolean,
                minLocations : Number,
                maxLocations : Number,
                possibleLocations : Object,
                requiredLocations : Object,
                peaceful: Boolean,

            }
        );
        
        
        
        this.interface = {
            new :: (island => Object, x => Number, y => Number, state) {
                return Landmark.new(base:this, island, x, y, state);
            }
        };
    }
);



Landmark.Base.database = Database.new(
    items: [

        Landmark.Base.new(
            data: {
                name : 'town',
                symbol : '#',
                rarity : 100000,
                minLocations : 3,
                maxLocations : 5,
                isUnique : false,
                peaceful : true,
                possibleLocations : [
                    {name:'home', rarity: 1},
                    {name:'Tavern', rarity: 3},
                    {name:'Blacksmith', rarity: 3},
                    //{name:'guild', rarity: 25}
                ],
                requiredLocations : [
                    'shop',
                    'School',
                    'Inn',
                ]
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'city',
                symbol : '|',
                rarity : 5,
                minLocations : 3,
                isUnique : false,
                maxLocations : 5,
                peaceful : true,
                possibleLocations : [
                    {name:'home', rarity: 1},
                    //{name:'inn', rarity: 3},
                    //{name:'guild', rarity: 25}
                    //{name:'tavern', rarity: 100}
                    //{name:'school', rarity: 7}
                ],
                requiredLocations : [
                    'shop',
                    'Tavern',
                    'Arena',
                    'Inn',
                    'School',
                    'Blacksmith'            
                ]
            }
        ),


        Landmark.Base.new(
            data: {
                name : 'Mine',
                symbol : 'O',
                rarity : 5,
                minLocations : 3,
                isUnique : false,
                maxLocations : 5,
                peaceful : true,
                possibleLocations : [
                    {name:'ore vein', rarity: 1},
                    //{name:'inn', rarity: 3},
                    //{name:'guild', rarity: 25}
                    //{name:'tavern', rarity: 100}
                    //{name:'school', rarity: 7}
                ],
                requiredLocations : [
                    'ore vein',
                    'smelter',
                ]
            }
        ),

        
        Landmark.Base.new(
            data: {
                name : 'Wyvern Gate',
                symbol : '@',
                rarity : 10,
                isUnique : true,
                minLocations : 4,
                maxLocations : 10,
                peaceful : true,
                possibleLocations : [

                ],
                requiredLocations : [
                    'Gate'
                ]
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'Dungeon',
                symbol : 'O',
                rarity : 100000,      
                isUnique : true,
                minLocations : 1,
                maxLocations : 3,
                peaceful: false,
                possibleLocations : [
                    {name: 'Stairs Down', rarity:1},
                    {name: 'Small Chest', rarity:5},
                    {name: '?????',       rarity:10},                    
                ],
                requiredLocations : [
                ]
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'Treasure Room',
                symbol : 'O',
                rarity : 5,      
                isUnique : true,
                minLocations : 1,
                maxLocations : 4,
                peaceful: true,
                possibleLocations : [
                    {name: 'Small Chest', rarity:5},
                ],
                requiredLocations : [
                    'Large Chest',
                ]
            }
        ),
        
        Landmark.Base.new(
            data: {
                name : 'The Outlook',
                symbol : '^',
                rarity : 0,      
                isUnique : true,
                minLocations : 0,
                maxLocations : 0,
                peaceful: true,
                possibleLocations : [
                ],
                requiredLocations : []
            }
        ),        
        
        
/*
        Landmark.Base.new(
            data: {
                name : 'city',
                symbol : '@',
                rarity : 20,                
                minLocations : 5,
                maxLocations : 10,
                possibleLocations : [
                    'guild',
                    'jail', // basically same as guild, functionally, can bail people out
                    'guardpost',
                    'school',
                    'home',
                    'shop',
                    'tavern'
                    
                ],
                requiredLocations : []
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'port',
                rarity : 30,                
                symbol : '~',
                minLocations : 0,
                maxLocations : 0,
                possibleLocations : [
                    'home',
                    'shop',
                    'guild',
                    'guardpost',
                    'tavern'
                ],
                requiredLocations : [
                    //'shipyard'
                ]
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'village',
                rarity : 5,                
                symbol : '*',

                minLocations : 0,
                maxLocations : 0,
                possibleLocations : [
                    'home',
                    'tavern',
                    'shop',
                    'farm'
                ],
                requiredLocations : []
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'villa',
                symbol : '=',
                rarity : 100,                
                minLocations : 0,
                maxLocations : 0,
                possibleLocations : [
                    'home',
                    'tavern',
                    'farm'
                ],
                requiredLocations : []
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'Outpost',
                symbol : '[]',
                rarity : 500,                
                minLocations : 0,
                maxLocations : 0,
                possibleLocations : [
                    //'barracks'                
                ],
                requiredLocations : []
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'forest',
                symbol : '^',
                rarity : 40,                
                minLocations : 0,
                maxLocations : 0,
                possibleLocations : [],
                requiredLocations : []
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'cave',
                symbol : 'O',
                rarity : 200,                

                minLocations : 0,
                maxLocations : 0,
                possibleLocations : [],
                requiredLocations : []
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'abandoned castle',
                symbol : 'X',
                rarity : 10000,                
                minLocations : 0,
                maxLocations : 0,
                possibleLocations : [],
                requiredLocations : []
            }
        ),
        Landmark.Base.new(
            data: {
                name : 'abandoned town',
                rarity : 400,                
                symbol : 'x',
                minLocations : 0,
                maxLocations : 0,
                possibleLocations : [],
                requiredLocations : []
            }
        ),


        Landmark.Base.new(
            data: {
                name : 'grotto',
                symbol : '_',
                rarity : 50,                

                minLocations : 0,
                maxLocations : 0,
                possibleLocations : [],
                requiredLocations : []
            }
        )*/
    
    ]

);


return Landmark;
