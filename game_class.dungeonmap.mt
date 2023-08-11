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
}

@:BIG = 100000000;



@Area = class(
    name: 'Wyvern.DungeonMap.Area',
    define::(this) {
        @_x;
        @_y;
        @_w;
        @_h;
        
        this.interface = {
            setup::(x, y, width, height) {
                _x = x => Number;
                _y = y => Number;
                _w = width => Number;
                _h = height => Number;
                return this;
            },
            
            x : {get::<-_x},        
            y : {get::<-_y},        
            width : {get::<-_w},        
            height : {get::<-_h}        
        }
    }
);



@:DungeonMap = class(
    name: 'Wyvern.DungeonMap',
    new ::(mapHint => Object) {
        @:this = DungeonMap.defaultNew();
        this.initialize(mapHint);
        return this;
    },
    inherits:[import(module:'game_class.mapbase.mt')],

  
    define:::(this) {

        @:areas = [];
        @cavities = [];
        
        @ROOM_AREA_SIZE = 5;
        @ROOM_AREA_SIZE_LARGE = 9;
        @ROOM_AREA_VARIANCE = 0.2;
        @ROOM_SIZE = 50;
        @ROOM_EMPTY_AREA_COUNT = 13;
        @GEN_OFFSET = 20;
        ;
        

        @:generateArea ::(item) {
            @width  = if (Number.random() > 0.5) ROOM_AREA_SIZE else ROOM_AREA_SIZE_LARGE;
            @height = width;
            width  *= 1 + Number.random() * 0.2;
            height *= 1 + Number.random() * 0.2;
        
            width = width->floor;
            height = height->floor;
        
            @left = (item.x - width/2  + width  * (Number.random() * 0.4 - 0.2))->floor;
            @top  = (item.y - height/2 + height * (Number.random() * 0.4 - 0.2))->floor;
            


            if (left < 0) left = GEN_OFFSET;
            if (left + width +2 >= (ROOM_SIZE+GEN_OFFSET)-1) left = (ROOM_SIZE+GEN_OFFSET) - width - 3;
            if (top < 0) top = GEN_OFFSET;
            if (top + height +2 >= (ROOM_SIZE+GEN_OFFSET)-1) top = (ROOM_SIZE+GEN_OFFSET) - height - 3;
            

            areas->push(value: Area.new().setup(
                x: left,
                y: top,
                width: width,
                height: height
            ));
                    
            for(0, width+1)::(i) {
                this.enableWall(
                    x:left + i,
                    y:top
                );

                this.enableWall(
                    x:left + i,
                    y:top + height
                );
            }

            for(0, height+1)::(i) {
                this.enableWall(
                    x:left,
                    y:top + i
                );

                this.enableWall(
                    x:left + width,
                    y:top + i
                );
            }

        }
        
        @:applyCavities::{
            foreach(cavities)::(i, cav) {
                this.enableWall(
                    x:cav.x+1,
                    y:cav.y
                );
                this.enableWall(
                    x:cav.x-1,
                    y:cav.y
                );
                this.enableWall(
                    x:cav.x,
                    y:cav.y+1
                );
                this.enableWall(
                    x:cav.x,
                    y:cav.y-1
                );
                
                this.enableWall(
                    x:cav.x-1,
                    y:cav.y-1
                );
                this.enableWall(
                    x:cav.x+1,
                    y:cav.y+1
                );
                this.enableWall(
                    x:cav.x+1,
                    y:cav.y-1
                );
                this.enableWall(
                    x:cav.x-1,
                    y:cav.y+1
                );

            }
        }

        @:cleanupAreas::{
            foreach(areas)::(i, area) {
                for(area.x+1, area.x + area.width)::(x) {
                    for(area.y+1, area.y + area.height)::(y) {
                        this.disableWall(x, y);
                    }
                }
            }
            
            foreach(cavities)::(i, cav) {
                this.disableWall(x:cav.x, y:cav.y);
            }
            cavities = [];
        }

        
        @:addCavity ::(x, y) {
            cavities->push(value:{x:x, y:y});
        }
        
        @:networkAreas ::{
            @remaining = [...areas];
            @next = remaining->pop;
            for(0, areas->keycount-1)::(i) {
                @:a = next;
                @:b = remaining->pop;              

                // find x / y path from a -> b
                @ax = (a.x + (Number.random() - 0.5)*0.5 * a.width + a.width/2)->floor;
                @ay = (a.y + (Number.random() - 0.5)*0.5 * a.height + a.height/2)->floor;

                @bx = (b.x + (Number.random() - 0.5)*0.5 * b.width + b.width/2)->floor;
                @by = (b.y + (Number.random() - 0.5)*0.5 * b.height + b.height/2)->floor;


                if (ax < 0) ax = 0;
                if (ay < 0) ay = 0;
                if (bx < 0) bx = 0;
                if (by < 0) by = 0;


                @fromx = if (ax < bx) ax else bx;
                @tox   = if (ax > bx) ax else bx;
                @fromy = if (ay < by) ay else by;
                @toy   = if (ay > by) ay else by;
            
                @fromx_y = if (ax < bx) ay else by;

                next = b;
                
                /*
                if(fromx <= 0) fromx = 1;
                if(fromx >= (ROOM_SIZE+GEN_OFFSET)-1) fromx = (ROOM_SIZE+GEN_OFFSET)-2;
                if(fromy <= 0) fromy = 1;
                if(fromy >= ROOM_SIZE-1) fromy = ROOM_SIZE-2;
                if(tox <= 0) tox = 1;
                if(tox >= ROOM_SIZE-1) tox = ROOM_SIZE-2;
                if(toy <= 0) toy = 1;
                if(toy >= ROOM_SIZE-1) toy = ROOM_SIZE-2;
                */


                for(fromx-1, tox+1)::(i) {
                    addCavity(
                        x:i,
                        y:fromx_y
                    );                    
                }


                for(fromy-1, toy+1)::(i) {
                    addCavity(
                        x:tox,
                        y:i
                    );                    
                }

                
            }
        }
    
        @:generateLayout :: {
            /*[0, 200]->for(do:::(i) {
                enableWall(
                    x: (ROOM_SIZE * Number.random())->floor,
                    y: (ROOM_SIZE * Number.random())->floor
                );
            });*/
                    
        
            
            for(0, ROOM_EMPTY_AREA_COUNT)::(i) {
                generateArea(
                    item:{
                        x:(Number.random()*ROOM_SIZE)->floor + GEN_OFFSET, 
                        y:(Number.random()*ROOM_SIZE)->floor + GEN_OFFSET
                    }
                );                
            }
            
            networkAreas();
            applyCavities();
            cleanupAreas();
        }
        




        
        this.interface = {
            initialize ::(mapHint) {

                if (mapHint.roomAreaSize != empty) ROOM_AREA_SIZE = mapHint.roomAreaSize;
                if (mapHint.roomAreaSizeLarge != empty) ROOM_AREA_SIZE_LARGE = mapHint.roomAreaSize;
                if (mapHint.emptyAreaCount != empty) ROOM_EMPTY_AREA_COUNT = mapHint.emptyAreaCount;
                if (mapHint.roomSize != empty) ROOM_SIZE = mapHint.roomSize;


                this.paged = false;
                this.width = ROOM_SIZE + GEN_OFFSET*2;
                this.height = ROOM_SIZE + GEN_OFFSET*2;
                this.renderOutOfBounds = true;
                this.outOfBoundsCharacter = '`';

                if (mapHint.wallCharacter != empty) this.wallCharacter = mapHint.wallCharacter;
                if (mapHint.outOfBoundsCharacter != empty) this.outOfBoundsCharacter = mapHint.outOfBoundsCharacter;


                this.obscure();
                generateLayout();
                return this;
            },
        
            areas : {
                get ::<- areas
            },
            
            getRandomArea :: {
                return random.pickArrayItem(list:areas);
            }
        
        } 
    }
);
return DungeonMap;
