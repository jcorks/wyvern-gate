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
@:random = import(module:'game_singleton.random.mt');
@:NameGen = import(module:'game_singleton.namegen.mt');
@:Database = import(module:'game_class.database.mt');
@:Map = import(module:'game_class.map.mt');
@:DungeonMap = import(module:'game_class.dungeonmap.mt');
@:DungeonController = import(module:'game_class.dungeoncontroller.mt');
@:distance = import(module:'game_function.distance.mt');
@Location = empty; // circular dep.







@:Landmark = class(  
    name : 'Wyvern.Landmark',
    statics : {
        Base : empty
    },
    define :::(this) {
        if (Location == empty) Location = import(module:'game_class.location.mt');
        @name;
        @landmark;
        @x_;
        @y_;
        @discovered = false;
        @locations = [];
        @island_;
        @sizeW;
        @sizeH;
        @peaceful;
        @floor = 0;
        @map;
        @gate;
        @dungeonLogic;

        
        
        
        
        @:getLocationXY ::<= {
            @:tryMap = [
                [0, 0],
                [-1, 0],
                [-1, -1],
                [0, -1],
                [1, -1],
                [1, 0],
                [1, 1],
                [0, 1],
                [-1, 1],
                [-2, 1],
                [-2, 0],
                [-2, -1],
                [-2, -2],
                [-1, -2],
                [0, -2],
                [1, -2],
                [2, -2],
                [2, -1],
                [2, 0],
                [2, 1],
                [2, 2]
            ];
            
            
            @:tryArea = ::(ar, offset) {
                @area = {
                    x: (ar.x + ar.width/2 + offset[0]*2)->floor,
                    y: (ar.y + ar.height/2 + offset[1]*2)->floor
                };                
                
                @:already = map.itemsAt(x:area.x, y:area.y);
                when(already != empty && already->keycount) empty;
                return area;
            };
        
        
            return ::{
                @ar = map.getRandomArea();
                
                return [::] {
                    @iter = 0;
                    forever(do::{
                        @:try = tryArea(ar, offset:tryMap[iter]);
                        when(try != empty) send(message:try);
                        iter += 1;
                    });
                };
            }; 
        };
        
        
        

        @:Entity = import(module:'game_class.entity.mt');


        this.constructor = ::(base, island, x, y, state, floorHint){
            island_ = island;
            when(state != empty) ::<= {
                this.state = state;
                return this;
            };

            if (base.dungeonMap) ::<= {
                map = DungeonMap.new(mapHint: base.mapHint);
                dungeonLogic = DungeonController.new(map, island, landmark:this);
            } else ::<= {
                map = Map.new(mapHint: base.mapHint);
            };

            sizeW = map.width;
            sizeH = map.height;


            @area = map.getRandomArea();                

            gate = Location.Base.database.find(name:'Entrance').new(
                landmark:this, 
                xHint:area.x + (area.width/2)->floor,
                yHint:area.y + (area.height/2)->floor
            );                


            if (base.isUnique)
                name = base.name
            else
                name = base.name + ' of ' + NameGen.place();
            landmark = base;
            x_ = x;
            y_ = y;
            peaceful = base.peaceful;
            /*
            [0, Random.integer(from:base.minLocations, to:base.maxLocations)]->for(do:::(i) {
                locations->push(value:island.newInhabitant());            
            });
            */
            @mapIndex = 0;







            
            
            locations->push(value:gate);
            map.setItem(data:gate, x:gate.x, y:gate.y, symbol: gate.base.symbol, discovered:true, name:gate.name);
            map.title = landmark.name + (
                if (name == '') '' else (' of ' + name)
            );







            base.requiredLocations->foreach(do:::(i, loc) {
                this.addLocation(
                    name:loc
                );
            
                mapIndex += 1;
            });
            
            [0, random.integer(from:base.minLocations, to:base.maxLocations)]->for(do:::(i) {
                when(base.possibleLocations->keycount == 0) empty;
                @:which = random.pickArrayItemWeighted(list:base.possibleLocations);
                this.addLocation(
                    name:which.name
                );
                mapIndex += 1;
            });
            
            
            map.setPointer(
                x:gate.x,
                y:gate.y
            );

            if (floorHint != empty) ::<= {
                floor = floorHint;
                floor => Number;
                if (landmark.dungeonMap)
                    dungeonLogic.floorHint = floor;
            };

            
            this.base.onCreate(landmark:this, island);
            
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
                    sizeW = value.sizeW;
                    sizeH = value.sizeH;
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
                            data:loc,
                            x: loc.x,
                            y: loc.y,
                            symbol: loc.base.symbol,
                            discovered: true
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
                        sizeW : sizeW,
                        sizeH : sizeH,
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
            
            width : {
                get ::<- sizeW
            },
            height : {
                get ::<- sizeH
            },
            
            peaceful : {
                get :: <- peaceful,
                set ::(value) <- peaceful = value
            },

            floor : {
                get :: <- floor
            },

            step :: {
                when(!landmark.dungeonMap) empty;
                dungeonLogic.step();
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
                @:world = import(module:'game_singleton.world.mt');
                @:windowEvent = import(module:'game_singleton.windowevent.mt');
                if (!discovered)
                    if (world.party.inventory.items->filter(by:::(value) <- value.base.name == 'Runestone')->keycount != 0) ::<= {
                        world.storyFlags.data_locationsDiscovered += 1;
                        windowEvent.queueMessage(text:'Location found! ' + world.storyFlags.data_locationsDiscovered + ' / ' 
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

            addLocation ::(name, ownedByHint, x, y) {
                if (x == empty || y == empty) ::<= {
                    @xy = getLocationXY();
                    x = xy.x;
                    y = xy.y;
                };
                @loc = Location.Base.database.find(name:name).new(landmark:this, ownedByHint, xHint:x, yHint:y);
                map.setItem(data:loc, x:loc.x, y:loc.y, symbol: loc.base.symbol, discovered:true, name:loc.name);
                locations->push(value:loc);                
            },

            removeLocation ::(location) {
                @:index = locations->findIndex(value:location);
                when(index < 0) empty;
                locations->remove(key:index);
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
                dungeonMap: Boolean,
                mapHint : Object,
                onCreate : Function,
                onVisit : Function,
                guarded : Boolean
            }
        );
        
        
        
        this.interface = {
            new :: (island => Object, x => Number, y => Number, floorHint, state) {
                return Landmark.new(base:this, island, x, y, floorHint, state);
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
                dungeonMap : false,
                guarded : true,
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
                ],
                mapHint : {
                    roomSize: 30,
                    roomAreaSize: 7,
                    roomAreaSizeLarge: 9,
                    emptyAreaCount: 6,
                    scatterChar: 'Y',
                    scatterRate: 0.3
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'city',
                symbol : '|',
                rarity : 5,
                minLocations : 3,
                isUnique : false,
                maxLocations : 12,
                peaceful : true,
                guarded : true,
                dungeonMap : false,
                possibleLocations : [
                    {name:'home', rarity: 1},
                    //{name:'inn', rarity: 3},
                    //{name:'guild', rarity: 25}
                    //{name:'tavern', rarity: 100}
                    //{name:'school', rarity: 7}
                ],
                requiredLocations : [
                    'shop',
                    'shop',
                    'shop',
                    'Tavern',
                    'Arena',
                    'Inn',
                    'School',
                    'Blacksmith'            
                ],
                mapHint : {
                    roomSize: 30,
                    roomAreaSize: 5,
                    roomAreaSizeLarge: 7,
                    emptyAreaCount: 18
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
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
                guarded : false,
                dungeonMap : false,
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
                ],
                mapHint : {
                    roomSize: 15,
                    roomAreaSize: 5,
                    roomAreaSizeLarge: 10,
                    emptyAreaCount: 5
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
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
                guarded : false,
                dungeonMap : false,
                possibleLocations : [

                ],
                requiredLocations : [
                    'Gate'
                ],
                
                mapHint : {
                    roomSize: 25,
                    wallCharacter: 'Y',
                    roomAreaSize: 5,
                    roomAreaSizeLarge: 7,
                    emptyAreaCount: 30
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'Wyvern Temple',
                symbol : '{}',
                rarity : 10000000,
                isUnique : true,
                minLocations : 4,
                maxLocations : 10,
                peaceful : true,
                guarded : false,
                dungeonMap : true,
                possibleLocations : [                    
                ],
                requiredLocations : [
                    'Stairs Up',
                ],
                mapHint: {},
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        ),



        Landmark.Base.new(
            data: {
                name : 'Shrine',
                symbol : 'O',
                rarity : 100000,      
                isUnique : true,
                minLocations : 2,
                maxLocations : 2,
                peaceful: false,
                guarded : false,
                dungeonMap : true,
                possibleLocations : [
                    {name: 'Stairs Down', rarity:1},
                    {name: 'Small Chest', rarity:3},
                ],
                requiredLocations : [


                    'Stairs Down',
                    'Small Chest'
                ],
                mapHint:{},
                onCreate ::(landmark, island){
                },
                onVisit ::(landmark, island) {}
                
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'Shrine: Lost Floor',
                symbol : 'O',
                rarity : 100000,      
                isUnique : true,
                minLocations : 2,
                maxLocations : 2,
                peaceful: true,
                guarded : false,
                dungeonMap : true,
                possibleLocations : [
                    {name: 'Small Chest', rarity:3},
                ],
                requiredLocations : [
                    '?????',
                    'Small Chest'
                ],
                mapHint:{},
                onCreate ::(landmark, island){
                },
                
                onVisit ::(landmark, island) {
                    @:canvas = import(module:'game_singleton.canvas.mt');
                    @:windowEvent = import(module:'game_singleton.windowevent.mt');
                    windowEvent.queueMessage(text:'It seems this area has been long forgotten...', renderable:{render::<-canvas.blackout()});
                }
                
            }
        ),


        Landmark.Base.new(
            data: {
                name : 'Treasure Room',
                symbol : 'O',
                rarity : 5,      
                isUnique : true,
                minLocations : 1,
                maxLocations : 5,
                guarded : false,
                peaceful: true,
                dungeonMap : false,
                possibleLocations : [
                    {name: 'Small Chest', rarity:5},
                ],
                requiredLocations : [
                    'Large Chest',
                    'Ladder'
                ],
                
                mapHint : {
                    roomSize: 15,
                    roomAreaSize: 7,
                    roomAreaSizeLarge: 9,
                    emptyAreaCount: 2
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {
                    @:windowEvent = import(module:'game_singleton.windowevent.mt');
                    windowEvent.queueMessage(text:'The party enters the pit full of treasure.');
               
                }
                
                
            }
        ),
        
        Landmark.Base.new(
            data: {
                name : 'Fire Wyvern Dimension',
                symbol : 'M',
                rarity : 1,      
                isUnique : true,
                minLocations : 2,
                maxLocations : 2,
                guarded : false,
                peaceful: true,
                dungeonMap : false,
                possibleLocations : [
                ],
                requiredLocations : [
                    'Wyvern Throne of Fire',
                ],
                
                mapHint : {
                    roomSize: 20,
                    roomAreaSize: 15,
                    roomAreaSizeLarge: 15,
                    emptyAreaCount: 1
                    
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        ),        

        Landmark.Base.new(
            data: {
                name : 'Ice Wyvern Dimension',
                symbol : 'M',
                rarity : 1,      
                isUnique : true,
                minLocations : 2,
                maxLocations : 2,
                guarded : false,
                peaceful: true,
                dungeonMap : false,
                possibleLocations : [
                ],
                requiredLocations : [
                    'Wyvern Throne of Ice',
                ],
                
                mapHint : {
                    roomSize: 20,
                    roomAreaSize: 15,
                    roomAreaSizeLarge: 15,
                    emptyAreaCount: 1
                    
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        ), 


        

        Landmark.Base.new(
            data: {
                name : 'port',
                rarity : 30,                
                symbol : '~',
                minLocations : 3,
                maxLocations : 10,
                peaceful: true,
                isUnique : false,
                dungeonMap : false,
                guarded : true,
                possibleLocations : [
                    {name:'home', rarity:5},
                    {name:'shop', rarity:40}
                    //'guild',
                    //'guardpost',
                ],
                requiredLocations : [
                    'Tavern'
                    //'shipyard'
                ],
                mapHint : {
                    roomSize: 25,
                    roomAreaSize: 5,
                    roomAreaSizeLarge: 14,
                    emptyAreaCount: 7
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'village',
                rarity : 5,                
                symbol : '*',
                peaceful: true,
                minLocations : 3,
                maxLocations : 7,
                isUnique : false,
                dungeonMap : false,
                guarded : false,
                possibleLocations : [
                    {name:'home', rarity:1},
                    {name:'Tavern', rarity:7},
                    {name:'shop', rarity:7},
                    {name:'farm', rarity:4}
                ],
                requiredLocations : [],
                mapHint : {
                    roomSize: 25,
                    roomAreaSize: 7,
                    roomAreaSizeLarge: 14,
                    emptyAreaCount: 4
                },        
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'villa',
                symbol : '=',
                rarity : 20,
                peaceful: true,                
                isUnique : false,
                dungeonMap : false,
                minLocations : 5,
                maxLocations : 10,
                guarded : false,
                possibleLocations : [
                    {name:'home', rarity:1},
                    {name:'Tavern', rarity:7},
                    {name:'farm', rarity:4}
                ],
                requiredLocations : [],
                mapHint : {
                    roomSize: 25,
                    wallCharacter: ',',
                    roomAreaSize: 7,
                    roomAreaSizeLarge: 14,
                    emptyAreaCount: 4
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
            }
        ),

        /*Landmark.Base.new(
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
        ),*/

        Landmark.Base.new(
            data: {
                name : 'forest',
                symbol : 'T',
                rarity : 40,                
                peaceful: false,
                isUnique : false,
                dungeonMap : true,
                minLocations : 3,
                maxLocations : 5,
                guarded : false,
                possibleLocations : [
                    {name: 'Small Chest', rarity:1},
                ],
                requiredLocations : [
                    'Small Chest'
                ],
                mapHint: {
                    roomSize: 60,
                    wallCharacter: 'Y',
                    roomAreaSize: 7,
                    roomAreaSizeLarge: 14,
                    emptyAreaCount: 25,
                    outOfBoundsCharacter: '~'
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'cave',
                symbol : 'O',
                rarity : 200,                
                peaceful: true,
                isUnique : false,
                dungeonMap : true,
                minLocations : 0,
                maxLocations : 0,
                guarded : false,
                possibleLocations : [],
                requiredLocations : [],
                mapHint: {},
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        ),

        Landmark.Base.new(
            data: {
                name : 'abandoned castle',
                symbol : 'X',
                rarity : 10000,
                peaceful: false,
                isUnique : false,
                dungeonMap : true,
                
                minLocations : 0,
                maxLocations : 0,
                guarded : false,
                possibleLocations : [],
                requiredLocations : [],
                mapHint: {},
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        ),
        Landmark.Base.new(
            data: {
                name : 'abandoned town',
                rarity : 400,                
                symbol : 'x',
                peaceful: false,
                isUnique : false,
                dungeonMap : true,
                guarded : false,
                minLocations : 0,
                maxLocations : 0,
                possibleLocations : [],
                requiredLocations : [],
                mapHint: {},              
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
            }
        ),


      
        
        


    
    ]

);


return Landmark;
