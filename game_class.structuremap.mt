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
@:ZONE_MAXIMUM_SPAN  = 4;
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

            blockSceneryIndex = map.addScenerySymbol(character:'▓');

            // if category is Entrance, the area is 2x2 
            if (category == Location.CATEGORY.ENTRANCE) ::<= {
                unitsWide = 2;
                unitsHigh = 2;
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
        @:addMinimalBuilding ::(left, top) {
            /*
                xxxx
                xxxx
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


        };  



        // adds a minimally-sized building
        @:addGate ::(left, top, which) {
            /*
              xx
              x
              x
              x
              xx
            */

            /*
                xx
                 x
                 x
                 x
                xx
            */

            /*
               xxxxxx
               x    x
            */

            /*
               x    x
               xxxxxx
            */


            match(which) {
              // North             
              (0):::<={
                addBuildingBlock(x:left, y:top);
                addBuildingBlock(x:left+1, y:top);
                addBuildingBlock(x:left+2, y:top);
                addBuildingBlock(x:left+3, y:top);
                addBuildingBlock(x:left+4, y:top);

                addBuildingBlock(x:left,   y:top+1);
                addBuildingBlock(x:left+4, y:top+1);

              },

              // East             
              (1):::<={
                addBuildingBlock(x:left+5, y:top);
                addBuildingBlock(x:left+4, y:top);
                addBuildingBlock(x:left+5, y:top+1);
                addBuildingBlock(x:left+5, y:top+2);
                addBuildingBlock(x:left+5, y:top+3);
                addBuildingBlock(x:left+5, y:top+4);
                addBuildingBlock(x:left+4, y:top+4);
                
              },

              // West             
              (2):::<={
                addBuildingBlock(x:left, y:top);
                addBuildingBlock(x:left+1, y:top);
                addBuildingBlock(x:left, y:top+1);
                addBuildingBlock(x:left, y:top+2);
                addBuildingBlock(x:left, y:top+3);
                addBuildingBlock(x:left, y:top+4);
                addBuildingBlock(x:left+1, y:top+4);
              },



              // South
              (3):::<={
                addBuildingBlock(x:left, y:top+4);
                addBuildingBlock(x:left+1, y:top+4);
                addBuildingBlock(x:left+2, y:top+4);
                addBuildingBlock(x:left+3, y:top+4);
                addBuildingBlock(x:left+4, y:top+4);

                addBuildingBlock(x:left,   y:top+3);
                addBuildingBlock(x:left+4, y:top+3);


              }
              
              
            };



        };  



        // adds a minimally-sized wide building
        @:addWideBuilding ::(left, top) {
            /*
                xxxxxxxxxx
                xxxxxxxxxx
                x  xxxxxxx
            
            */

            /*
                xxxxxxxxxx
                xxxxxxxxxx
                xxxxxxx  x
            
            */
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
            } else ::<= {            
                _map.disableWall(x:left + 8, y: top + 3);
                _map.disableWall(x:left + 9, y: top + 3);
                _map.clearScenery(x:left + 8, y: top + 3);
                _map.clearScenery(x:left + 9, y: top + 3);
            };
        }; 


        // adds a minimally-sized wide building
        @:addTallBuilding ::(left, top) {
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


            _map.disableWall(x:left + 2, y: top + 7);
            _map.disableWall(x:left + 3, y: top + 7);
            _map.clearScenery(x:left + 2, y: top + 7);
            _map.clearScenery(x:left + 3, y: top + 7);

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
                            @which;
                            if (random.flipCoin()) ::<= {
                                x0 = if (random.flipCoin()) 0 else unitsWide - 1;
                                y0 = random.integer(from:0, to:unitsHigh-1);
                                
                                x1 = x0;
                                y1 = y0;
                                which = if (x0 == 0) WEST else EAST;
                                if (which == WEST)
                                    x1 += 1
                                else  
                                    x1 -= 1;
                                
                            } else ::<= {
                                x0 = random.integer(from:0, to:unitsWide-1);                                
                                y0 = if (random.flipCoin()) 0 else unitsHigh - 1;

                                x1 = x0;
                                y1 = y0;
                                which = if (y0 == 0) NORTH else SOUTH;
                                if (which == SOUTH)
                                    y1 += 1
                                else  
                                    y1 -= 1;
                            };
                            
                            when(slots[x0][y0] != false) empty;
                            when(slots[x1][y1] != false) empty;

                            @:space0 = getSpaceBySlot(x:x0, y:y0);
                            @:space1 = getSpaceBySlot(x:x1, y:y1);
                            
                            slots[x0][y0] = true;
                            slots[x1][y1] = true;
                            
                            freeSpaces->remove(key:space0);
                            freeSpaces->remove(key:space1);
                            
                            addGate(
                                left:space0.x * ZONE_BUILDING_MINIMUM_WIDTH + _x+ZONE_CONTENT_PADDING,
                                top:space0.y * ZONE_BUILDING_MINIMUM_HEIGHT + _y+ZONE_CONTENT_PADDING,
                                which
                            );
                            send();
                        });
                    };
                };
            
            
                @:size = location.base.minStructureSize;
                when(size == 1) ::<= {
                    when(freeSpaces->keycount == 0) false;
                    
                    @:space = random.pickArrayItem(list:freeSpaces);
                    slots[space.x][space.y] = true;
                    freeSpaces->remove(key:freeSpaces->findIndex(value:space));
                    addMinimalBuilding(
                        left:space.x * ZONE_BUILDING_MINIMUM_WIDTH + _x+ZONE_CONTENT_PADDING,
                        top:space.y * ZONE_BUILDING_MINIMUM_HEIGHT + _y+ZONE_CONTENT_PADDING
                    );
                    return true;
                };
                
                
                when(size == 2) ::<= {
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
                                    left:_x + left * ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING,
                                    top: _y + space0.y * ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING
                                );
                            } else ::<= {
                                @:top = if (space0.y < space1.y) space0.y else space1.y;
                                addTallBuilding(
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
        



        this.constructor = ::(mapHint => Object) {


            this.paged = false;
            this.renderOutOfBounds = true;
            this.outOfBoundsCharacter = '`';
            

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
                top + zone.width  > STRUCTURE_MAP_SIZE ||
                top + zone.height > STRUCTURE_MAP_SIZE
                
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
            @openingX;
            @openingY;
            if (zones->keycount == 0) ::<= {
                top  = STRUCTURE_MAP_STARTING_Y;
                left = STRUCTURE_MAP_STARTING_X;
            } else ::<= {
                [::] {
                    forever(do:::{
                        // pick a random zone and extend it 
                        @:preZone = random.pickArrayItem(list:zones);
                        match(random.integer(from:0, to:3)) {
                          // North
                          (0):::<= {
                            top = preZone.top - zone.height;
                            left = (preZone.left + preZone.width / 2 + (-0.5 + random.float()) * zone.width)->floor - zone.width/2;
                            openingX = preZone.left + preZone.width / 2;
                            openingY = top + zone.height;
                          },
                          
                          // East 
                          (1):::<= {
                            top = (preZone.top + preZone.height / 2 + (-0.5 + random.float()) * zone.height)->floor - zone.height/2;                  
                            left = preZone.left - zone.width;
                            openingX = left + zone.width;
                            openingY = preZone.top + preZone.height / 2;
                          },
                          
                          // South
                          (2):::<= {
                            top = preZone.top + preZone.height;
                            left = (preZone.left + preZone.width / 2 + (-0.5 + random.float()) * zone.width)->floor - zone.width/2;
                            openingX = preZone.left + preZone.width / 2;
                            openingY = top;
                          },
                          
                          // West
                          (3):::<= {
                            top = (preZone.top + preZone.height / 2 + (-0.5 + random.float()) * zone.height)->floor - zone.height/2;                  
                            left = preZone.left + preZone.width;
                            openingX = left;
                            openingY = preZone.top + preZone.height / 2;                            
                          }

                          
                        };
                        top = top->floor;
                        left = left->floor;
                        
                        if (isZoneAllowed(top, left, zone)) send();
                    });
                };
            };
            
            zone.setPosition(top, left);

            // add an opening 
            if (openingX != empty)
                this.disableWall(x:openingX, y:openingY);
            
            zones->push(value:zone);
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
                
            }
        }; 
    }
);
