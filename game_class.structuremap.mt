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
@:canvas = import(module:'game_singleton.canvas.mt');
@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');



@:EPSILON = 0.000001;

@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
};

@:BIG = 100000000;

@:NORTH = 0;
@:EAST  = 1;
@:WEST  = 2;
@:SOUTH = 3;


@:ZONE_BUILDING_MINIMUM_WIDTH  = 6;
@:ZONE_BUILDING_MINIMUM_HEIGHT = 5;
@:ZONE_MINIMUM_SPAN = 2;
@:ZONE_MAXIMUM_SPAN  = 3;
@:STRUCTURE_MAP_STARTING_X = 100;
@:STRUCTURE_MAP_STARTING_Y = 100;
@:STRUCTURE_MAP_SIZE = 200;
@:ZONE_CONTENT_PADDING = 2;
@:STRUCTURE_MAP_FILLER_MINIMUM_RATE = 0.8;


@Zone = class(
    name: 'Wyvern.StructureMap.Zone',
    define::(this) {
        @_x;
        @_y;
        @_w;
        @_h;
        @_map;
        @_category;
        @unitsWide;
        @unitsHigh;
        @gateSide = random.integer(from:NORTH, to:SOUTH);
        
        @slots = [];
        @freeSpaces = [];
        @blockSceneryIndex;
        
        @:addBuildingBlock::(x, y) {
            _map.enableWall(x, y);
            _map.setSceneryIndex(x, y, symbol:blockSceneryIndex);
        };
        
        this.constructor = ::(map, category => Number) {
            unitsWide = random.integer(from:ZONE_MINIMUM_SPAN, to:ZONE_MAXIMUM_SPAN); 
            unitsHigh = random.integer(from:ZONE_MINIMUM_SPAN, to:ZONE_MAXIMUM_SPAN); 

            if (unitsWide > ZONE_MAXIMUM_SPAN ||
                unitsHigh > ZONE_MAXIMUM_SPAN)
                error(detail:' uhhh RNG brokey.');

            blockSceneryIndex = map.addScenerySymbol(character:'▓');

            // if category is Entrance, the area is 2x2 
            if (category == Location.CATEGORY.ENTRANCE) ::<= {
                unitsWide = 1;
                unitsHigh = 1;
            };

            _map = map;
            _category = category;
            _w = unitsWide * ZONE_BUILDING_MINIMUM_WIDTH +ZONE_CONTENT_PADDING*2;
            _h = unitsHigh * ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING*2;
            
            [0, unitsWide]->for(do::(x) {
                slots[x] = [];
                [0, unitsHigh]->for(do::(y) {
                    slots[x][y] = false;
                    freeSpaces->push(value:{x:x, y:y});
                });               
            });
            
            
            
            return this;
        };
        
        @locations = [];  
        
        @:getSpaceBySlot::(x, y) {
            return freeSpaces[freeSpaces->findIndex(query::(value) <- value.x == x && value.y == y)];
        };   
        
        // adds a minimally-sized building
        @:addMinimalBuilding ::(left, top, symbol, location) {
            /*   
                xxxx
                x$$x
                x  x
            
            */
            addBuildingBlock(x:left + 1, y: top + 1);
            addBuildingBlock(x:left + 2, y: top + 1);
            addBuildingBlock(x:left + 3, y: top + 1);
            addBuildingBlock(x:left + 4, y: top + 1);

            addBuildingBlock(x:left + 1, y: top + 2);
            addBuildingBlock(x:left + 2, y: top + 2);
            addBuildingBlock(x:left + 3, y: top + 2);
            addBuildingBlock(x:left + 4, y: top + 2);

            addBuildingBlock(x:left + 1, y: top + 3);
            addBuildingBlock(x:left + 4, y: top + 3);

            if (symbol != empty) ::<= {
                @:index = _map.addScenerySymbol(character:symbol);
                _map.setSceneryIndex(x:left + 2, y: top + 2, symbol:index);
                _map.setSceneryIndex(x:left + 3, y: top + 2, symbol:index);
            };
            
            @windowEvent = import(module:'game_singleton.windowevent.mt');
            
            @:interact = ::{
                location.interact();
            };
            
            _map.setStepAction(x:left + 2, y: top + 3, action:interact);
            _map.setStepAction(x:left + 3, y: top + 3, action:interact);
                

        };  



        // adds a minimally-sized building
        @:addGate ::(left, top, which, location) {
            location.x = left;
            location.y = top;


            @:interact = ::{
                location.interact();
            };
            
            @:index = _map.addScenerySymbol(character:'#');

            match(which) {
              // North             
              (NORTH):::<={
                [-ZONE_CONTENT_PADDING, ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING+1]->for(do:::(i) {
                    _map.setStepAction(x:left+i,   y:top-ZONE_CONTENT_PADDING+1, action:interact);
                    _map.setSceneryIndex(x:left+i,   y:top-ZONE_CONTENT_PADDING+1, symbol:index);
                });
                

              },

              // East             
              (EAST):::<={
                [-ZONE_CONTENT_PADDING, ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING+1]->for(do:::(i) {
                    _map.setStepAction(x:left+ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING-1, y:top+i, action:interact);
                    _map.setSceneryIndex(x:left+ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING-1, y:top+i, symbol:index);
                });


                
              },

              // West             
              (WEST):::<={
                [-ZONE_CONTENT_PADDING, ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING+1]->for(do:::(i) {
                    _map.setStepAction(x:left-ZONE_CONTENT_PADDING+1, y:top+i, action:interact);
                    _map.setSceneryIndex(x:left-ZONE_CONTENT_PADDING+1, y:top+i, symbol:index);
                });
              },



              // South
              (SOUTH):::<={
                [-ZONE_CONTENT_PADDING, ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING+1]->for(do:::(i) {
                    _map.setStepAction(x:left+i,   y:top+ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING-1, action:interact);
                    _map.setSceneryIndex(x:left+i,   y:top+ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING-1, symbol:index);
                });

              }
              
              
            };

            
            return which;

        };  



        // adds a minimally-sized wide building
        @:addWideBuilding ::(left, top, symbol, location) {
            /*
                xxxxxxxxxx
                xxxxxxx$$x
                x  xxxxxxx
            
            */

            /*
                xxxxxxxxxx
                x$$xxxxxxx
                xxxxxxx  x
            
            */

            @:interact = ::{
                location.interact();
            };


            [0, 3]->for(do:::(y) {
                [0, 10]->for(do:::(x) {
                    addBuildingBlock(x:left+x + 1, y:top+y+1);
                });
            });


            if (random.flipCoin() == true) ::<= {
                _map.disableWall(x:left + 2, y: top + 3);
                _map.disableWall(x:left + 3, y: top + 3);
                _map.clearScenery(x:left + 2, y: top + 3);
                _map.clearScenery(x:left + 3, y: top + 3);
                _map.setStepAction(x:left + 2, y: top + 3, action:interact);
                _map.setStepAction(x:left + 3, y: top + 3, action:interact);
                

                if (symbol != empty) ::<= {
                    @:index = _map.addScenerySymbol(character:symbol);
                    _map.setSceneryIndex(x:left + 8, y: top + 2, symbol:index);
                    _map.setSceneryIndex(x:left + 9, y: top + 2, symbol:index);
                };


            } else ::<= {            
                _map.disableWall(x:left + 8, y: top + 3);
                _map.disableWall(x:left + 9, y: top + 3);
                _map.clearScenery(x:left + 8, y: top + 3);
                _map.clearScenery(x:left + 9, y: top + 3);
                _map.setStepAction(x:left + 8, y: top + 3, action:interact);
                _map.setStepAction(x:left + 9, y: top + 3, action:interact);

                if (symbol != empty) ::<= {
                    @:index = _map.addScenerySymbol(character:symbol);
                    _map.setSceneryIndex(x:left + 2, y: top + 2, symbol:index);
                    _map.setSceneryIndex(x:left + 3, y: top + 2, symbol:index);
                };

            };


        }; 


        // adds a minimally-sized wide building
        @:addTallBuilding ::(left, top, symbol, location) {
            /*
                xxxx
                xxxx
                xxxx
                xxxx
                xxxx
                xxxx
                x  x
            
            */
            [0, 7]->for(do:::(y) {
                [0, 4]->for(do:::(x) {
                    addBuildingBlock(x:left+x + 1, y:top+y+1);
                });
            });

            @:interact = ::{
                location.interact();
            };


            _map.disableWall(x:left + 2, y: top + 7);
            _map.disableWall(x:left + 3, y: top + 7);
            _map.clearScenery(x:left + 2, y: top + 7);
            _map.clearScenery(x:left + 3, y: top + 7);
            _map.setStepAction(x:left + 2, y: top + 7, action:interact);
            _map.setStepAction(x:left + 3, y: top + 7, action:interact);

            
            if (symbol != empty) ::<= {
                @:index = _map.addScenerySymbol(character:symbol);
                _map.setSceneryIndex(x:left + 2, y: top + 4, symbol:index);
                _map.setSceneryIndex(x:left + 3, y: top + 4, symbol:index);
            };
            

        };
        

        @:Location = import(module:'game_class.location.mt');


        
        this.interface = {
            left : {get::<-_x},        
            top : {get::<-_y},  
            
            setPosition ::(left, top) {
                _x = left;
                _y = top;
                
                
                [0, _w]->for(do::(i) {
                    _map.enableWall(x:i+_x, y:_y);
                    _map.enableWall(x:i+_x, y:_y+_h);
                });            

                [0, _h]->for(do::(i) {
                    _map.enableWall(x:_x, y:_y+i);
                    _map.enableWall(x:_x+_w, y:_y+i);
                });
                   
            },
                  
            width : {get::<-_w},        
            height : {get::<-_h},
            category : {get::<- _category},
            
            // only for zones that have gates, gets the 
            // side that the gate is hugging. This is primarily used for 
            // placement of the first zone in the map so that it logically 
            // looks like an entrance to the outside.
            // is empty if there is no gate.
            gateSide : {get::<- gateSide},
            
            // returns false if cant fit the location
            addLocation::(location) {
                // entrances take up 2 slots.
                when(location.base.category == Location.CATEGORY.ENTRANCE) ::<= {                    
                    [::] {
                        [0, 20]->for(do:::(i) {
                            @x0;
                            @y0;
                            @x1;
                            @y1;
                            
                            match(gateSide) {
                              (EAST, WEST):::<= {
                                x0 = if (gateSide == WEST) 0 else unitsWide - 1;
                                y0 = random.integer(from:0, to:unitsHigh-1);
                                
                                x1 = x0;
                                y1 = y0;
                                if (gateSide == WEST)
                                    x1 += 1
                                else  
                                    x1 -= 1;
                                                              
                              },
                              
                              
                              (NORTH, SOUTH):::<= {
                                x0 = random.integer(from:0, to:unitsWide-1);                                
                                y0 = if (gateSide == NORTH) 0 else unitsHigh - 1;

                                x1 = x0;
                                y1 = y0;
                                if (gateSide == SOUTH)
                                    y1 += 1
                                else  
                                    y1 -= 1;                              
                              }
                            };                            
                            when(slots[x0][y0] != false) empty;
                            //when(slots[x1][y1] != false) empty;

                            @:space0 = getSpaceBySlot(x:x0, y:y0);
                            //@:space1 = getSpaceBySlot(x:x1, y:y1);


                            
                            slots[x0][y0] = true;
                            //slots[x1][y1] = true;
                            
                            freeSpaces->remove(key:space0);
                            //freeSpaces->remove(key:space1);
                            addGate(
                                location,
                                left:space0.x * ZONE_BUILDING_MINIMUM_WIDTH + _x+ZONE_CONTENT_PADDING,
                                top:space0.y * ZONE_BUILDING_MINIMUM_HEIGHT + _y+ZONE_CONTENT_PADDING,
                                which:gateSide
                            );
                            send();
                        });
                    };
                };
            
            
                @:size = location.base.minStructureSize;
                when(random.flipCoin() && size == 1) ::<= {
                    when(freeSpaces->keycount == 0) false;
                    
                    @:space = random.pickArrayItem(list:freeSpaces);
                    slots[space.x][space.y] = true;
                    freeSpaces->remove(key:freeSpaces->findIndex(value:space));
                    addMinimalBuilding(
                        location,
                        symbol:if (location.base.category == Location.CATEGORY.RESIDENTIAL) empty else location.base.symbol,
                        left:space.x * ZONE_BUILDING_MINIMUM_WIDTH + _x+ZONE_CONTENT_PADDING,
                        top:space.y * ZONE_BUILDING_MINIMUM_HEIGHT + _y+ZONE_CONTENT_PADDING
                    );
                    return true;
                };
                
                
                when(true) ::<= {
                    @:wide = random.flipCoin();
                    
                    return [::] {
                        [0, 10]->for(do:::(i) {
                            @:space0 = random.pickArrayItem(list:freeSpaces);
                            @space1;
                            
                            if (wide) ::<= {
                                space1 = (freeSpaces->filter(by::(value) <- value.x == space0.x+1 && value.y == space0.y))[0];
                                if (space1 == empty)
                                    space1 = (freeSpaces->filter(by::(value) <- value.x == space0.x-1 && value.y == space0.y))[0];
                            } else ::<= {
                                space1 = (freeSpaces->filter(by::(value) <- value.x == space0.x && value.y == space0.y+1))[0];
                                if (space1 == empty)
                                    space1 = (freeSpaces->filter(by::(value) <- value.x == space0.x && value.y == space0.y-1))[0];                            
                            };
                            // this attempt failed
                            when(space1 == empty) empty;

                            slots[space0.x][space0.y] = true;
                            freeSpaces->remove(key:freeSpaces->findIndex(value:space0));
                            slots[space1.x][space1.y] = true;
                            freeSpaces->remove(key:freeSpaces->findIndex(value:space1));

                            
                            
                            if (wide) ::<= {
                                @:left = if (space0.x < space1.x) space0.x else space1.x;
                                addWideBuilding(
                                    location,
                                    symbol:if (location.base.category == Location.CATEGORY.RESIDENTIAL) empty else location.base.symbol,
                                    left:_x + left * ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING,
                                    top: _y + space0.y * ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING
                                );
                            } else ::<= {
                                @:top = if (space0.y < space1.y) space0.y else space1.y;
                                addTallBuilding(
                                    location,
                                    symbol:if (location.base.category == Location.CATEGORY.RESIDENTIAL) empty else location.base.symbol,
                                    left:_x + space0.x * ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING,
                                    top: _y + top * ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING
                                );                            
                            };
                            
                            send(message:true);
                        });
                        return false;
                    };
                };
                
                
                error(detail:'Dunno what to do here.');
            },
    

        };
    }
);



return class(
    name: 'Wyvern.StructureMap',
    inherits:[import(module:'game_class.mapbase.mt')],

  
    define:::(this) {

        
        @hasZoningWalls = true;
        @hasFillerBuildings = true;
        @zones = [];
        @paired = [];
        
        @isPaired = ::(i, n) {
            @temp;
            if (i < n) ::<= {
                temp = i;
                i = n;
                n = temp;
            };
            
            return paired['' + i + '-' + n]!=empty;
        };
        
        
        @setPaired = ::(i, n, alongIcoord, alongIside, alongIcenter) {
            @temp;
            if (i < n) ::<= {
                temp = i;
                i = n;
                n = temp;
            };
            
            paired['' + i + '-' + n] = {
                first: i,
                second: n,
                coord: alongIcoord,
                side: alongIside,
                center:alongIcenter
            };
        };        



        this.constructor = ::(mapHint => Object) {


            this.paged = false;
            this.renderOutOfBounds = true;
            this.outOfBoundsCharacter = ' ';
            

            if (mapHint.wallCharacter != empty) this.wallCharacter = mapHint.wallCharacter;
            if (mapHint.outOfBoundsCharacter != empty) this.outOfBoundsCharacter = mapHint.outOfBoundsCharacter;
            if (mapHint.hasZoningWalls != empty) hasZoningWalls = mapHint.hasZoningWalls;
            if (mapHint.hasFillerBuildings != empty) hasFillerBuildings = mapHint.hasFillerBuildings;

            this.width = STRUCTURE_MAP_SIZE;
            this.height = STRUCTURE_MAP_SIZE;

            return this;
        };   
        
        // returns whether 2 line segments overlap
        // l0 is less than m0,
        // l1 is less than m1
        @:is1DlineOverlap::(l0, m0, l1, m1) <-
            if (l0 < l1) 
                l1 < m0
            else 
                m1 > l0
        ;
        
        
        @:isZoneAllowed::(top, left, zone) {
            when (
                top < 0 ||
                left < 0 ||
                left + zone.width  > this.width ||
                top + zone.height > this.height
                
            ) false;

        
            return [::] {
                zones->foreach(do::(i, z) {
                    // intersects with existing zones
                    @xOverlap = is1DlineOverlap(
                        l0:   z.left, m0:   z.left +    z.width,
                        l1:     left, m1:     left + zone.width
                    );
                    
                    @yOverlap = is1DlineOverlap(
                        l0:   z.top, m0:   z.top +    z.height,
                        l1:     top, m1:     top + zone.height
                    );
                    
                    
                    if (xOverlap
                         &&
                        yOverlap
                    ) send(message:false);



                });  
                
                return true;
            };
        };
        
        // adds a new zone.
        // if no zones exist, then the zone is placed somewhere 
        // out in the open. Else, it must be touching an existing zone 
        // on its side
        @:addZone ::(category) {
            @zone = Zone.new(map:this, category);
            @top;
            @left;
            @alongIcoord;
            @alongIside;
            @alongIcenter;
            @preZone;
            if (zones->keycount == 0) ::<= {
                // fallback
                match(zone.gateSide) {
                  (NORTH):::<= {
                    top = 0;
                    left = (this.width / 2)->floor;
                  },

                  (EAST):::<= {
                    top = (this.height / 2)->floor;
                    left = this.width - zone.width;
                  },
                  
                  (WEST):::<= {
                    top = (this.height / 2)->floor;
                    left = 0;
                  },
                  
                  (SOUTH):::<= {
                    top = this.height - zone.height;
                    left = (this.width / 2)->floor;
                  },

                  default: ::<= {
                    top  = STRUCTURE_MAP_STARTING_Y;
                    left = STRUCTURE_MAP_STARTING_X;                                  
                  }
                };
            } else ::<= {
                [::] {
                    forever(do:::{
                        // pick a random zone and extend it 
                        preZone = random.pickArrayItem(list:zones);
                        match(random.integer(from:0, to:3)) {
                          // North
                          (NORTH):::<= {
                            top = preZone.top - zone.height;
                            left = (preZone.left + preZone.width / 2 + (-0.5 + random.float()) * zone.width)->floor - zone.width/2;
                            top = top->floor;
                            left = left->floor;
                            alongIcoord = preZone.top;
                            alongIside = NORTH;
                            
                            @:innerMiddle = if (left > preZone.left) left else preZone.left;
                            @:outerMiddle = if (zone.width + left < preZone.width + preZone.left) zone.width + left else preZone.width + preZone.left;
                            alongIcenter = ((innerMiddle + outerMiddle)/2)->floor;
                          },
                          
                          // East 
                          (WEST):::<= {
                            top = (preZone.top + preZone.height / 2 + (-0.5 + random.float()) * zone.height)->floor - zone.height/2;                  
                            left = preZone.left - zone.width;
                            top = top->floor;
                            left = left->floor;
                            alongIcoord = preZone.left;
                            alongIside = WEST;
                            @:innerMiddle = if (top > preZone.top) top else preZone.top;
                            @:outerMiddle = if (zone.height + top < preZone.height + preZone.top) zone.height + top else preZone.height + preZone.top;
                            alongIcenter = ((innerMiddle + outerMiddle)/2)->floor;

                          },
                          
                          // South
                          (SOUTH):::<= {
                            top = preZone.top + preZone.height;
                            left = (preZone.left + preZone.width / 2 + (-0.5 + random.float()) * zone.width)->floor - zone.width/2;
                            top = top->floor;
                            left = left->floor;
                            alongIcoord = top;
                            alongIside = SOUTH;
                            @:innerMiddle = if (left > preZone.left) left else preZone.left;
                            @:outerMiddle = if (zone.width + left < preZone.width + preZone.left) zone.width + left else preZone.width + preZone.left;
                            alongIcenter = ((innerMiddle + outerMiddle)/2)->floor;
                          },
                          
                          // West
                          (EAST):::<= {
                            top = (preZone.top + preZone.height / 2 + (-0.5 + random.float()) * zone.height)->floor - zone.height/2;                  
                            left = preZone.left + preZone.width;
                            top = top->floor;
                            left = left->floor;
                            alongIcoord = left;
                            alongIside = EAST;
                            @:innerMiddle = if (top > preZone.top) top else preZone.top;
                            @:outerMiddle = if (zone.height + top < preZone.height + preZone.top) zone.height + top else preZone.height + preZone.top;
                            alongIcenter = ((innerMiddle + outerMiddle)/2)->floor;
                          }

                          
                        };
                        
                        when (!isZoneAllowed(top, left, zone)) empty;                      
                        send();
                    });
                };
            };
            
            zone.setPosition(top, left);            
            zones->push(value:zone);

                        
            setPaired(
                i:zones->findIndex(value:preZone),
                n:zones->keycount-1,
                alongIcoord,
                alongIside,
                alongIcenter
            );  
            
            
            return zone;
        };
        
        @Location = import(module:'game_class.location.mt');
        this.interface = {
            // special function that adds a location value 
            // to the map in a designated zoning area.
            addLocation::(location => Location.type) {
                @:zonesCat = zones->filter(by:::(value) <- value.category == location.base.category);
                @zone = if (zonesCat == empty || zonesCat->keycount == 0)
                    addZone(category:location.base.category)
                else
                    random.pickArrayItem(list:zonesCat)
                ;
                
                if (zone.addLocation(location) == false) ::<= {
                    zone = addZone(category:location.base.category);
                    zone.addLocation(location);
                };
            },
            
            // indicates that no other locations will be added 
            // so any final step can be taken, such as adding 
            // zoning walls and expanding / connecting 
            // buildings.
            finalize::{

                
                paired->foreach(do:::(i, data) {
                    @:base = zones[data.first];
                    @:other = zones[data.second];
                    match(data.side) {
                      (NORTH, SOUTH):::<= {
                        [data.center-1, data.center+2]->for(do::(x) {
                            this.disableWall(x, y: data.coord);
                            this.clearScenery(x, y: data.coord);                        
                        });
                      },

                      (EAST, WEST):::<= {
                        [data.center-1, data.center+2]->for(do::(y) {
                            this.disableWall(x:data.coord, y);
                            this.clearScenery(x:data.coord, y);                        
                        });
                      }

                    };
                });


            }
        }; 
    }
);
