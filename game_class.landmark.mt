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
@:DungeonMap = import(module:'game_singleton.dungeonmap.mt');
@:StructureMap = import(module:'game_class.structuremap.mt');
@:DungeonController = import(module:'game_class.dungeoncontroller.mt');
@:distance = import(module:'game_function.distance.mt');
@Location = empty; // circular dep.
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:Map = import(module:'game_class.map.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');






@:Landmark = LoadableClass.new(  
    name : 'Wyvern.Landmark',
    statics : {
        Base  :::<= {
            @db;
            return {
                get ::<- db,
                set ::(value) <- db = value
            }
        }
    },
    
    new::(parent, base, x, y, state, floorHint){ 
        @island = if (parent->type == Map.type)
            parent.parent // immediate parent is map
        else // only other case is its a location, due to targetLandmark
            parent.landmark.island
            // loc  map   landm   map   island
        ;
        @:Island = import(module:'game_class.island.mt');
        
        @:this = Landmark.defaultNew();
        this.initialize(island);
        if (state != empty) 
            this.load(serialized:state)
        else 
            this.defaultLoad(base, x, y, floorHint);                    
        return this;
    },
    
    define :::(this) {
        if (Location == empty) Location = import(module:'game_class.location.mt');

        @island_;
        @dungeonLogic;
        @structureMapBuilder; // only used in initialization

        @:world = import(module:'game_singleton.world.mt');
        @:state = State.new(
            items : {
                worldID : world.getNextID(),
                name : empty,
                base : empty,
                x : 0,
                y : 0,
                discovered : false,
                peaceful : false,
                floor : 0,
                map : empty,
                gate : empty,
                stepsSinceLast: 0,
                modData : {}
            
            }
        );


        
        
        

        
        
        

        @:Entity = import(module:'game_class.entity.mt');

  

        


        this.interface =  {
            initialize::(island){
                island_ = island;
            },
            defaultLoad::(base, x, y, floorHint){


                state.base = base;
                state.x = x;
                state.y = y;
                state.peaceful = base.peaceful;
                

                if (base.dungeonMap) ::<= {
                    state.map = DungeonMap.create(parent:this, mapHint: base.mapHint);
                    dungeonLogic = DungeonController.new(map:state.map, island:island_, landmark:this);
                } else ::<= {
                    structureMapBuilder = StructureMap.new();//Map.new(mapHint: base.mapHint);
                    structureMapBuilder.initialize(mapHint:base.mapHint, parent:this);
                }


                if (base.dungeonMap) ::<= {
                    if (base.dungeonForceEntrance) ::<= {
                        this.addLocation(name:'Entrance');
                    }
                } else ::<= {
                    this.addLocation(name:'Entrance');
                }
                
                if (base.isUnique)
                    state.name = base.name
                else
                    state.name = base.name + ' of ' + NameGen.place();
                /*
                [0, Random.integer(from:base.minLocations, to:base.maxLocations)]->for(do:::(i) {
                    locations->push(value:island.newInhabitant());            
                });
                */
                @mapIndex = 0;
       







                
                





                


                foreach(base.requiredLocations)::(i, loc) {
                    this.addLocation(
                        name:loc
                    );
                
                    mapIndex += 1;
                }
                @:possibleLocations = [...base.possibleLocations];
                for(0, random.integer(from:base.minLocations, to:base.maxLocations))::(i) {
                    when(possibleLocations->keycount == 0) empty;
                    @:which = random.pickArrayItemWeighted(list:possibleLocations);
                    this.addLocation(
                        name:which.name
                    );
                    if (which.onePerLandmark) ::<= {
                        state.possibleLocations->remove(key:state.possibleLocations->findIndex(value:which));
                    }
                    mapIndex += 1;
                }
                
                if (base.dungeonMap) ::<= {
                    @:gate = this.gate;
                    if (gate == empty) ::<= {
                        this.movePointerToRandomArea();
                    } else ::<= {
                        state.map.setPointer(
                            x:gate.x,
                            y:gate.y
                        );                    
                    }
                } else ::<= {
                    state.map = structureMapBuilder.finalize();
                    @:gate = this.gate;
                    state.map.setPointer(
                        x:gate.x,
                        y:gate.y
                    );

                    // cant add locations to structure maps through the landmark.
                    structureMapBuilder = empty;
                }
                state.map.title = state.base.name + (
                    if (state.name == '') '' else (' of ' + state.name)
                );  
                if (floorHint != empty) ::<= {
                    state.floor = floorHint;
                    state.floor => Number;
                    if (state.base.dungeonMap)
                        dungeonLogic.floorHint = state.floor;
                }

                
                this.base.onCreate(landmark:this, island:island_);
                
                return this;
            },

            save :: {
                when (state.base.canSave)
                    state.save();
                
                return State.new(
                    items: {
                        x : state.x,
                        y : state.y,
                        floorHint : state.floor,
                        base : state.base,
                        isSparse : true
                    }
                ).save()
            },
            load ::(serialized) { 
                
                if (serialized.isSparse) ::<= {
                    @:sparse = State.new(
                        items: {
                            x : state.x,
                            y : state.y,
                            floorHint : state.floor,
                            base : state.base,
                            isSparse : true
                        }
                    );
                    sparse.load(parent:this, serialized);
                    this.defaultLoad(
                        base: sparse.base,
                        x: sparse.x,
                        y: sparse.y,
                        floorHint: sparse.floorHint
                    )   
                } else ::<= {                
                    state.load(parent:this, serialized)
                    dungeonLogic = DungeonController.new(map:state.map, island:island_, landmark:this);
                }
            },

            worldID : {
                get ::<- state.worldID
            },
        
            description : {
                get :: {
                    @:locations = this.locations;
                    @out = state.name + ', a ' + state.base.name;
                    if (locations->keycount > 0) ::<={
                        out = out + ' with ' + locations->keycount + ' permanent inhabitants';//:\n';
                        //foreach(in:locations, do:::(index, inhabitant) {
                        //    out = out + '   ' + inhabitant.name + ', a ' + inhabitant.species.name + ' ' + inhabitant.profession.base.name +'\n';
                        //});
                    }
                    return out;
                }
            },

            base : {
                get ::<- state.base
            },
            
            name : {
                get :: {
                    return state.name;                
                },
                
                set ::(value) {
                    state.name = value;
                    state.map.title = value;
                }
            },
            
            x : {
                get ::<- state.x
            },
            
            y : {
                get ::<- state.y
            },
            
            width : {
                get ::<- if (structureMapBuilder) structureMapBuilder.getWidth() else state.map.width
            },
            height : {
                get ::<- if (structureMapBuilder) structureMapBuilder.getHeight() else state.map.height
            },
            
            peaceful : {
                get :: <- state.peaceful,
                set ::(value) <- state.peaceful = value
            },

            floor : {
                get :: <- state.floor
            },

            step :: {

                world.stepTime(isStep:true); 
                this.map.title = this.name + ' - ' + world.timeString + '          ';
                when(!state.base.dungeonMap) empty;
                dungeonLogic.step();
            },
            
            kind : {
                get :: {
                    return state.base.name;
                }
            },
            
            gate : {
                get :: {
                    @:locations = this.locations;
                    @:index = locations->findIndex(query::(value) {
                        return value.base.name == 'Entrance'
                    });
                    when (index != -1)
                        locations[index];
                }
            },
            discover :: {
                @:world = import(module:'game_singleton.world.mt');
                @:windowEvent = import(module:'game_singleton.windowevent.mt');
                if (!state.discovered)
                    if (world.party.inventory.items->filter(by:::(value) <- value.base.name == 'Runestone')->keycount != 0) ::<= {
                        world.storyFlags.data_locationsDiscovered += 1;
                        windowEvent.queueMessage(text:'Location found! ' + world.storyFlags.data_locationsDiscovered + ' / ' 
                                                                 + world.storyFlags.data_locationsNeeded + ' locations.');               
                    }
                state.discovered = true;
            },
            
            discovered : {
                get ::<- state.discovered
            },
            
            locations : {
                get :: <- state.map.getAllItems() 
            },
            
            island : {
                get ::<- island_
            },
            
            movePointerToRandomArea ::{
                @:area = state.map.getRandomEmptyArea();
                state.map.setPointer(
                    x:area.x + (area.width/2)->floor,
                    y:area.y + (area.height/2)->floor
                );            
            },
            
            getRandomEmptyPosition ::{
                // shouldnt do this!
                when (!state.base.dungeonMap) empty;

                @:area = state.map.getRandomEmptyArea();
                return { 
                    x:area.x + (area.width/2)->floor,
                    y:area.y + (area.height/2)->floor
                }
            },
            
            modData : {
                get ::<- state.modData
            },


            removeLocation ::(location) {
                state.map.removeItem(data:location);
            },

            addLocation ::(name, ownedByHint, x, y) {
                @loc = Location.new(
                    base:Location.Base.database.find(name:name),
                    landmark:this, ownedByHint,
                    xHint: x,
                    yHint: y
                );

                if (state.base.dungeonMap) ::<= {
                    if (x == empty || y == empty)
                        state.map.addToRandomEmptyArea(item:loc, symbol: loc.base.symbol, name:loc.name)
                    else
                        state.map.setItem(data:loc, x:loc.x, y:loc.y, symbol: loc.base.symbol, discovered:true, name:loc.name);
                    
                } else ::<= {
                    if (structureMapBuilder != empty)
                        structureMapBuilder.addLocation(location:loc)
                    else 
                        state.map.setItem(data:loc, x:loc.x, y:loc.y, symbol: loc.base.symbol, discovered:true, name:loc.name);                    
                }
                return loc;            
 
            },
            
            island : {
                get ::<- island_
            },
            
            map : {
                get ::<- state.map
            },
            
            
            // TODO: Sort of in between controller and internal action 
            // should probably move back to instance
            visit ::(where) {
                if (where != empty)
                    state.map.setPointer(
                        x:where.x,
                        y:where.y
                    );                    
                
                @:windowEvent = import(module:'game_singleton.windowevent.mt');
                @:partyOptions = import(module:'game_function.partyoptions.mt');
                @:world = import(module:'game_singleton.world.mt');
                @:Island = import(module:'game_class.island.mt');
                @:Event  = import(module:'game_class.event.mt');

                @:party = world.party;
                
                this.map.title = this.name + ' - ' + world.timeString + '          ';
                this.base.onVisit(landmark:this, island:this.island);


                
                @stepCount = 0;


                @:landmarkChoices = ::{
                    windowEvent.queueChoices(
                        leftWeight: 1,
                        topWeight: 1,
                        prompt: 'What next?',
                        keep:true,
                        canCancel:true,
                        onGetChoices ::{
                            @choices = [                
                                'Party'
                            ];
                            
                            
                            @locationAt = this.map.getNamedItemsUnderPointer();
                            if (locationAt != empty) ::<= {
                                foreach(locationAt)::(i, loc) {
                                    choices->push(value:'Check ' + loc.name);
                                }
                            }

                            return choices;                
                        },
                        renderable:this.map,
                        onChoice::(choice) {
                            @locationAt = this.map.getNamedItemsUnderPointer();
                                

                                
                            @:MAX_STATIC_CHOICES = 1;
                            match(choice-1) {
                              
                              (0): ::<={
                                partyOptions();
                                this.step();
                              },
                              
                              
                              default: ::<= {
                                when(choice == empty) empty;
                                choice -= MAX_STATIC_CHOICES + 1;
                                when(choice >= locationAt->keycount) empty;
                                locationAt = locationAt[choice].data;
                                
                                
                                locationAt.interact();

                              }
                            
                            }
                        }
                    );
                }
                
                @nearby;
                windowEvent.queueCursorMove(
                    jumpTag: 'VisitLandmark',
                    onMenu ::{
                        landmarkChoices()
                    },
                    renderable:{
                        render :: {
                            this.map.render();
                            
                            when(nearby == empty || nearby->size == 0) empty;
                            
                            @:lines = [];
                            foreach(nearby)::(index, arr) {

                                lines->push(value:arr.name);
                            }
                            canvas.renderTextFrameGeneral(
                                leftWeight: 1,
                                topWeight: 1,
                                lines,
                                title: 'Arrived at:'
                            );
                        }
                    },
                    onMove ::(choice) {
                    
                        // move by one unit in that direction
                        // or ON it if its within one unit.
                        this.map.movePointerAdjacent(
                            x: if (choice == windowEvent.CURSOR_ACTIONS.RIGHT) 1 else if (choice == windowEvent.CURSOR_ACTIONS.LEFT) -1 else 0,
                            y: if (choice == windowEvent.CURSOR_ACTIONS.DOWN)  1 else if (choice == windowEvent.CURSOR_ACTIONS.UP)   -1 else 0
                        );
                        this.step();
                        stepCount += 1;

                        
                        // every 5 steps, heal 1% HP if below 1/5th health
                        if (stepCount % 15 == 0) ::<= {
                            foreach(party.members)::(i, member) {
                                if (member.hp < member.stats.HP * 0.2)
                                    member.heal(amount:(member.stats.HP * 0.01)->ceil);
                            }
                        }
                        

                        state.stepsSinceLast += 1;
                        if (this.peaceful == false) ::<= {
                            if (state.stepsSinceLast >= 5 && Number.random() > 0.7) ::<= {
                                this.island.addEvent(
                                    event:Event.new(
                                        base:Event.Base.database.find(name:'Encounter:Non-peaceful'),
                                        parent:this //, currentTime
                                    )
                                );
                                state.stepsSinceLast = 0;
                            }
                        }


                        
                        // cancel if we've arrived somewhere
                        nearby = this.map.getNamedItemsUnderPointer();

                        if (nearby != empty && nearby->size > 0)
                            this.map.setPointer(
                                x: nearby[0].x,
                                y: nearby[0].y
                            );

                    }                
                )
            }
            
        }
    }
);

@:LANDMARK_NAME = 'Wyvern.Landmark.Base'
Landmark.Base = class(
    name : LANDMARK_NAME,
    inherits : [Database.Item],
    new::(data) {
        @:this = Landmark.Base.defaultNew();
        this.initialize(data);
        return this;
    },
    statics : {
        database  :::<= {
            @db = Database.new(
                name : LANDMARK_NAME,
                attributes : {
                    name : String,
                    legendName : String,
                    symbol : String,
                    rarity: Number,
                    isUnique : Boolean,
                    minLocations : Number,
                    maxLocations : Number,
                    possibleLocations : Object,
                    requiredLocations : Object,
                    canSave : Boolean,
                    peaceful: Boolean,
                    dungeonMap: Boolean,
                    dungeonForceEntrance : Boolean,
                    mapHint : Object,
                    onCreate : Function,
                    onVisit : Function,
                    guarded : Boolean,
                    pointOfNoReturn : Boolean
                }
            );
            return {
                get ::<- db,
            }
        }
    },
    define:::(this) {
        Landmark.Base.database.add(item:this);
    }
);


Landmark.Base.new(
    data: {
        name : 'Town',
        legendName : 'Town',
        symbol : '#',
        rarity : 100000,
        minLocations : 3,
        maxLocations : 5,
        isUnique : false,
        peaceful : true,
        dungeonMap : false,
        dungeonForceEntrance: false,
        guarded : true,
        canSave : true,
        pointOfNoReturn : false,
        possibleLocations : [
            {name:'Home', rarity: 1},
            {name:'Tavern', rarity: 3},
            {name:'Blacksmith', rarity: 3},
            //{name:'guild', rarity: 25}
        ],
        requiredLocations : [
            'Shop',
            'School',
            'Inn',
        ],
        mapHint : {
            roomSize: 30,
            roomAreaSize: 7,
            roomAreaSizeLarge: 9,
            emptyAreaCount: 6,
            wallCharacter: '!',
            scatterChar: 'Y',
            scatterRate: 0.3
        },
        onCreate ::(landmark, island){},
        onVisit ::(landmark, island) {}
    }
)

Landmark.Base.new(
    data: {
        name : 'City',
        legendName : 'City',
        symbol : '|',
        rarity : 5,
        minLocations : 3,
        isUnique : false,
        maxLocations : 12,
        peaceful : true,
        guarded : true,
        dungeonMap : false,
        canSave : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: false,
        possibleLocations : [
            {name:'Home', rarity: 1},
            //{name:'inn', rarity: 3},
            //{name:'guild', rarity: 25}
            //{name:'tavern', rarity: 100}
            //{name:'school', rarity: 7}
        ],
        requiredLocations : [
            'Shop',
            'Shop',
            'Shop',
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
            emptyAreaCount: 18,
            wallCharacter : '|'
        },
        onCreate ::(landmark, island){},
        onVisit ::(landmark, island) {}
        
    }
)


Landmark.Base.new(
    data: {
        name : 'Mine',
        legendName: 'Mine',
        symbol : 'O',
        rarity : 5,
        minLocations : 3,
        isUnique : false,
        maxLocations : 5,
        peaceful : true,
        guarded : false,
        dungeonMap : true,
        canSave : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: true,
        possibleLocations : [
            {name:'Ore vein', rarity: 1},
            //{name:'inn', rarity: 3},
            //{name:'guild', rarity: 25}
            //{name:'tavern', rarity: 100}
            //{name:'school', rarity: 7}
        ],
        requiredLocations : [
            'Ore vein',
            'Smelter',
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
)


Landmark.Base.new(
    data: {
        name : 'Wyvern Gate',
        legendName: 'Gate',
        symbol : '@',
        rarity : 10,
        isUnique : true,
        minLocations : 4,
        maxLocations : 10,
        peaceful : true,
        guarded : false,
        dungeonMap : true,
        canSave : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: true,
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
)

Landmark.Base.new(
    data: {
        name : 'Wyvern Temple',
        legendName: 'Temple',
        symbol : '{}',
        rarity : 10000000,
        isUnique : true,
        minLocations : 4,
        maxLocations : 10,
        peaceful : true,
        guarded : false,
        dungeonMap : true,
        canSave : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: true,
        possibleLocations : [                    
        ],
        requiredLocations : [
            'Stairs Up',
        ],
        mapHint: {},
        onCreate ::(landmark, island){},
        onVisit ::(landmark, island) {}
        
    }
)



Landmark.Base.new(
    data: {
        name : 'Shrine of Fire',
        legendName: 'Shrine',
        symbol : 'M',
        rarity : 100000,      
        isUnique : true,
        minLocations : 1,
        maxLocations : 3,
        peaceful: false,
        guarded : false,
        dungeonMap : true,
        canSave : false,
        pointOfNoReturn : true,
        dungeonForceEntrance: false,
        possibleLocations : [
//                    {name: 'Stairs Down', rarity:1},

            // the standard set
            {name: 'Fountain', rarity:18},
            {name: 'Potion Shop', rarity: 17},
            {name: 'Enchantment Stand', rarity: 11},
            {name: 'Wyvern Statue', rarity: 15},
            {name: 'Small Chest', rarity: 16},
            {name: 'Locked Chest', rarity: 11},


            {name: 'Healing Circle', rarity:20},


            {name: 'Clothing Shop', rarity: 300},
            {name: 'Fancy Shop', rarity: 500}

        ],
        requiredLocations : [
            'Stairs Down',
            'Stairs Down'
        ],
        mapHint:{
            layoutType: DungeonMap.LAYOUT_ALPHA
        },
        onCreate ::(landmark, island){
        },
        onVisit ::(landmark, island) {
            if (landmark.floor == 0)
                windowEvent.queueMessage(
                    text:"This place seems to shift before you..."
                );
        }
        
    }
)

Landmark.Base.new(
    data: {
        name : 'Shrine of Ice',
        legendName: 'Shrine',
        symbol : 'O',
        rarity : 100000,      
        isUnique : true,
        minLocations : 1,
        maxLocations : 4,
        peaceful: false,
        guarded : false,
        dungeonMap : true,
        canSave : false,
        pointOfNoReturn : true,
        dungeonForceEntrance: false,
        possibleLocations : [
//                    {name: 'Stairs Down', rarity:1},
            {name: 'Fountain', rarity:18},
            {name: 'Potion Shop', rarity: 17},
            {name: 'Enchantment Stand', rarity: 11},
            {name: 'Wyvern Statue', rarity: 15},
            {name: 'Small Chest', rarity: 16},
            {name: 'Locked Chest', rarity: 11},
            {name: 'Magic Chest', rarity: 15},


            {name: 'Healing Circle', rarity:20},
            {name: 'Clothing Shop', rarity: 300},
            {name: 'Fancy Shop', rarity: 500},
        ],
        requiredLocations : [
            'Stairs Down',
            'Locked Chest',
        ],
        mapHint:{
            layoutType: DungeonMap.LAYOUT_BETA
        },
        onCreate ::(landmark, island){
        },
        onVisit ::(landmark, island) {}
        
    }
)

Landmark.Base.new(
    data: {
        name : 'Shrine of Thunder',
        symbol : 'O',
        legendName: 'Shrine',
        rarity : 100000,      
        isUnique : true,
        minLocations : 2,
        maxLocations : 4,
        peaceful: false,
        guarded : false,
        dungeonMap : true,
        canSave : false,
        pointOfNoReturn : true,
        dungeonForceEntrance: false,
        possibleLocations : [
//                    {name: 'Stairs Down', rarity:1},
            {name: 'Fountain', rarity:18},
            {name: 'Potion Shop', rarity: 17},
            {name: 'Enchantment Stand', rarity: 11},
            {name: 'Wyvern Statue', rarity: 15},
            {name: 'Small Chest', rarity: 16},
            {name: 'Locked Chest', rarity: 11},
            {name: 'Magic Chest', rarity: 15},

            {name: 'Healing Circle', rarity:25},

            {name: 'Clothing Shop', rarity: 200},
            {name: 'Fancy Shop', rarity: 100}

        ],
        requiredLocations : [
            'Stairs Down',
            'Locked Chest',
            'Small Chest'
        ],
        mapHint:{
            layoutType: DungeonMap.LAYOUT_DELTA
        },
        onCreate ::(landmark, island){
        },
        onVisit ::(landmark, island) {}
        
    }
)


Landmark.Base.new(
    data: {
        name : 'Shrine of Light',
        symbol : 'O',
        legendName: 'Shrine',
        rarity : 100000,      
        isUnique : true,
        minLocations : 2,
        maxLocations : 4,
        peaceful: false,
        guarded : false,
        dungeonMap : true,
        canSave : false,
        pointOfNoReturn : true,
        dungeonForceEntrance: false,
        possibleLocations : [
//                    {name: 'Stairs Down', rarity:1},
            {name: 'Fountain', rarity:18},
            {name: 'Potion Shop', rarity: 17},
            {name: 'Enchantment Stand', rarity: 11},
            {name: 'Wyvern Statue', rarity: 15},
            {name: 'Small Chest', rarity: 16},
            {name: 'Locked Chest', rarity: 11},
            {name: 'Magic Chest', rarity: 15},

            {name: 'Healing Circle', rarity:35},

            {name: 'Clothing Shop', rarity: 100},
            {name: 'Fancy Shop', rarity: 50}

        ],
        requiredLocations : [
            'Stairs Down',
            'Locked Chest',
            'Small Chest'
        ],
        mapHint:{
            layoutType: DungeonMap.LAYOUT_GAMMA
        },
        onCreate ::(landmark, island){
        },
        onVisit ::(landmark, island) {}
        
    }
)


Landmark.Base.new(
    data: {
        name : 'Shrine: Lost Floor',
        symbol : 'O',
        legendName: 'Shrine',
        rarity : 100000,      
        isUnique : true,
        minLocations : 2,
        maxLocations : 2,
        peaceful: true,
        guarded : false,
        dungeonMap : true,
        canSave : false,
        pointOfNoReturn : false,
        dungeonForceEntrance: false,
        possibleLocations : [
            {name: 'Small Chest', rarity:3},
        ],
        requiredLocations : [
            '?????',
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
)


Landmark.Base.new(
    data: {
        name : 'Treasure Room',
        legendName: 'T. Room',
        symbol : 'O',
        rarity : 5,      
        isUnique : true,
        minLocations : 1,
        maxLocations : 5,
        guarded : false,
        peaceful: true,
        dungeonMap : true,
        canSave : false,
        pointOfNoReturn : false,
        dungeonForceEntrance: false,
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
)

Landmark.Base.new(
    data: {
        name : 'Fire Wyvern Dimension',
        legendName: '???',
        symbol : 'M',
        rarity : 1,      
        isUnique : true,
        minLocations : 2,
        maxLocations : 2,
        guarded : false,
        peaceful: true,
        dungeonMap : true,
        canSave : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: false,
        possibleLocations : [
        ],
        requiredLocations : [
            'Wyvern Throne of Fire',
        ],
        
        mapHint : {
            roomSize: 20,
            roomAreaSize: 15,
            roomAreaSizeLarge: 15,
            emptyAreaCount: 1,
            wallCharacter: ' '
            
        },
        onCreate ::(landmark, island){},
        onVisit ::(landmark, island) {}
        
    }
)        

Landmark.Base.new(
    data: {
        name : 'Ice Wyvern Dimension',
        legendName: '???',
        symbol : 'M',
        rarity : 1,      
        isUnique : true,
        minLocations : 2,
        maxLocations : 2,
        guarded : false,
        peaceful: true,
        dungeonMap : true,
        canSave : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: false,
        possibleLocations : [
        ],
        requiredLocations : [
            'Wyvern Throne of Ice',
        ],
        
        mapHint : {
            roomSize: 20,
            roomAreaSize: 15,
            roomAreaSizeLarge: 15,
            emptyAreaCount: 1,
            wallCharacter: ' '
            
        },
        onCreate ::(landmark, island){},
        onVisit ::(landmark, island) {}
        
    }
) 

Landmark.Base.new(
    data: {
        name : 'Thunder Wyvern Dimension',
        legendName: '???',
        symbol : 'M',
        rarity : 1,      
        isUnique : true,
        minLocations : 2,
        maxLocations : 2,
        guarded : false,
        peaceful: true,
        
        canSave : true,
        dungeonMap : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: false,
        possibleLocations : [
        ],
        requiredLocations : [
            'Wyvern Throne of Thunder',
        ],
        
        mapHint : {
            roomSize: 20,
            roomAreaSize: 15,
            roomAreaSizeLarge: 15,
            emptyAreaCount: 1,
            wallCharacter: ' '
            
        },
        onCreate ::(landmark, island){},
        onVisit ::(landmark, island) {}
        
    }
) 


Landmark.Base.new(
    data: {
        name : 'Light Wyvern Dimension',
        legendName: '???',
        symbol : 'M',
        rarity : 1,      
        isUnique : true,
        minLocations : 2,
        maxLocations : 2,
        guarded : false,
        peaceful: true,
        
        canSave : true,
        dungeonMap : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: false,
        possibleLocations : [
        ],
        requiredLocations : [
            'Wyvern Throne of Light',
        ],
        
        mapHint : {
            roomSize: 20,
            roomAreaSize: 15,
            roomAreaSizeLarge: 15,
            emptyAreaCount: 1,
            wallCharacter: ' '
            
        },
        onCreate ::(landmark, island){},
        onVisit ::(landmark, island) {}
        
    }
) 


Landmark.Base.new(
    data: {
        name : 'Port',
        legendName: 'Port',
        rarity : 30,                
        symbol : '~',
        minLocations : 3,
        maxLocations : 10,
        peaceful: true,
        isUnique : false,
        dungeonMap : false,
        guarded : true,
        canSave : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: true,
        possibleLocations : [
            {name:'Home', rarity:5},
            {name:'Shop', rarity:40}
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
)

Landmark.Base.new(
    data: {
        name : 'Village',
        legendName: 'Village',
        rarity : 5,                
        symbol : '*',
        peaceful: true,
        minLocations : 3,
        maxLocations : 7,
        isUnique : false,
        dungeonMap : false,
        canSave : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: false,
        guarded : false,
        possibleLocations : [
            {name:'Home', rarity:1},
            {name:'Tavern', rarity:7},
            {name:'Shop', rarity:7},
            {name:'Farm', rarity:4}
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
)

Landmark.Base.new(
    data: {
        name : 'Villa',
        legendName: 'Villa',
        symbol : '=',
        rarity : 20,
        peaceful: true,                
        isUnique : false,
        dungeonMap : false,
        canSave : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: false,
        minLocations : 5,
        maxLocations : 10,
        guarded : false,
        possibleLocations : [
            {name:'Home', rarity:1},
            {name:'Tavern', rarity:7},
            {name:'Farm', rarity:4}
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
)

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
)*/

Landmark.Base.new(
    data: {
        name : 'Forest',
        legendName: 'Forest',
        symbol : 'T',
        rarity : 40,                
        peaceful: true,
        isUnique : false,
        dungeonMap : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: true,
        minLocations : 3,
        maxLocations : 5,
        guarded : false,
        canSave : true,
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
)

Landmark.Base.new(
    data: {
        name : 'Cave',
        legendName: 'Cave',
        symbol : 'O',
        rarity : 200,                
        peaceful: true,
        isUnique : false,
        dungeonMap : true,
        pointOfNoReturn : false,
        dungeonForceEntrance: true,
        minLocations : 0,
        maxLocations : 0,
        guarded : false,
        canSave : true,
        possibleLocations : [],
        requiredLocations : [],
        mapHint: {},
        onCreate ::(landmark, island){},
        onVisit ::(landmark, island) {}
        
    }
)

Landmark.Base.new(
    data: {
        name : 'Abandoned Castle',
        legendName: 'Castle',
        symbol : 'X',
        rarity : 10000,
        peaceful: false,
        isUnique : false,
        dungeonMap : true,
        dungeonForceEntrance: true,
        
        minLocations : 0,
        maxLocations : 0,
        guarded : false,
        canSave : true,
        pointOfNoReturn : false,
        possibleLocations : [],
        requiredLocations : [],
        mapHint: {},
        onCreate ::(landmark, island){},
        onVisit ::(landmark, island) {}
        
    }
)
Landmark.Base.new(
    data: {
        name : 'Abandoned Town',
        legendName: 'Town',
        rarity : 400,                
        symbol : 'x',
        peaceful: false,
        isUnique : false,
        dungeonMap : true,
        canSave : true,
        dungeonForceEntrance: true,
        guarded : false,
        minLocations : 0,
        maxLocations : 0,
        pointOfNoReturn : false,
        possibleLocations : [],
        requiredLocations : [],
        mapHint: {},              
        onCreate ::(landmark, island){},
        onVisit ::(landmark, island) {}
    }
)



return Landmark;
