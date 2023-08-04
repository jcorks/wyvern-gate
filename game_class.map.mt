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
        this.constructor = ::(x, y, width, height) {
            _x = x => Number;
            _y = y => Number;
            _w = width => Number;
            _h = height => Number;
            return this.instance;
        }
        
        this.interface = {
            x : {get::<-_x},        
            y : {get::<-_y},        
            width : {get::<-_w},        
            height : {get::<-_h}        
        }
    }
);



return class(
    name: 'Wyvern.Map',
    inherits:[import(module:'game_class.mapbase.mt')],

  
    define:::(this) {

        @:areas = [];
        @cavities = [];
        
        // defaults. They can be overridden by the constructor
        @ROOM_AREA_SIZE = 5;
        @ROOM_AREA_SIZE_LARGE = 6;
        @ROOM_AREA_VARIANCE = 0.2;
        @ROOM_SIZE = 30;
        @ROOM_EMPTY_AREA_COUNT = 35;
        @ROOM_SCATTER_CHAR = ',';
        @ROOM_SCATTER_RATE = 0.3;
        @self;
        

        @:generateArea ::(item) {
            @width  = if (Number.random() > 0.5) ROOM_AREA_SIZE else ROOM_AREA_SIZE_LARGE;
            @height = width;
            width  *= 1 + Number.random() * 0.2;
            height *= 1 + Number.random() * 0.2;
        
            width = width->floor;
            height = height->floor;
        
            @left = (item.x - width/2  + width  * (Number.random() * 0.4 - 0.2))->floor;
            @top  = (item.y - height/2 + height * (Number.random() * 0.4 - 0.2))->floor;
            


            if (left < 0) left = 0;
            if (left + width >= ROOM_SIZE-1) left = ROOM_SIZE - width - 2;
            if (top < 0) top = 0;
            if (top + height >= ROOM_SIZE-1) top = ROOM_SIZE - height - 2;

            areas->push(value: Area.new(
                x: left,
                y: top,
                width: width,
                height: height
            ));
                    
            for(0, width+1)::(i) {
                self.addWall(
                    x:left + i,
                    y:top
                );

                self.addWall(
                    x:left + i,
                    y:top + height
                );
            }

            for(0, height+1)::(i) {
                self.addWall(
                    x:left,
                    y:top + i
                );

                self.addWall(
                    x:left + width,
                    y:top + i
                );
            }

        }
        
        @:applyCavities::{
            foreach(cavities)::(i, cav) {
                self.addWall(
                    x:cav.x+1,
                    y:cav.y
                );
                self.addWall(
                    x:cav.x-1,
                    y:cav.y
                );
                self.addWall(
                    x:cav.x,
                    y:cav.y+1
                );
                self.addWall(
                    x:cav.x,
                    y:cav.y-1
                );
                
                self.addWall(
                    x:cav.x-1,
                    y:cav.y-1
                );
                self.addWall(
                    x:cav.x+1,
                    y:cav.y+1
                );
                self.addWall(
                    x:cav.x+1,
                    y:cav.y-1
                );
                self.addWall(
                    x:cav.x-1,
                    y:cav.y+1
                );

            }
        }

        @:cleanupAreas::{
            foreach(areas)::(i, area) {
                for(area.x+1, area.x + area.width)::(x) {
                    for(area.y+1, area.y + area.height)::(y) {
                        self.removeWall(x, y);
                        self.clearItems(x, y);
                        self.clearScenery(x, y);
                    }
                }
            }
            
            foreach(cavities)::(i, cav) {
                self.removeWall(x:cav.x, y:cav.y);
                self.clearItems(x:cav.x, y:cav.y);
                self.clearScenery(x:cav.x, y:cav.y);
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
            
                
                when(fromx <= 2 || fromx >= ROOM_SIZE-2) empty;
                when(fromy <= 2 || fromy >= ROOM_SIZE-2) empty;
                when(tox <= 2 || fromx >= ROOM_SIZE-2) empty;
                when(toy <= 2 || fromy >= ROOM_SIZE-2) empty;
                

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
            self.sceneryValues = [ROOM_SCATTER_CHAR];
            for(-30, ROOM_SIZE+30)::(y) {
                for(-30, ROOM_SIZE+30)::(x) {
                    if (Number.random() < ROOM_SCATTER_RATE / 4)
                        self.setSceneryIndex(
                            x, y, symbol: 0
                        );
                }
            }
                    
        
            
            for(0, ROOM_EMPTY_AREA_COUNT)::(i) {
                generateArea(
                    item:{
                        x:(Number.random()*ROOM_SIZE)->floor, 
                        y:(Number.random()*ROOM_SIZE)->floor
                    }
                );                
            }
            
            networkAreas();
            applyCavities();
            cleanupAreas();
        }



        this.constructor = ::(mapHint => Object) {
            self = this.instance;
            self.paged = false;
            self.width = if (mapHint.roomSize == empty) ROOM_SIZE else mapHint.roomSize;
            self.height = if (mapHint.roomSize == empty) ROOM_SIZE else mapHint.roomSize;
            self.renderOutOfBounds = if (mapHint.renderOutOfBounds == empty) true else mapHint.renderOutOfBounds;
            self.outOfBoundsCharacter = if (mapHint.outOfBoundsCharacter == empty) ' ' else mapHint.outOfBoundsCharacter;
            self.wallCharacter = if (mapHint.wallCharacter == empty) '▓' else mapHint.wallCharacter;
            
            if (mapHint.roomAreaSize != empty) ROOM_AREA_SIZE = mapHint.roomAreaSize;
            if (mapHint.roomAreaSizeLarge != empty) ROOM_AREA_SIZE_LARGE = mapHint.roomAreaSizeLarge;
            if (mapHint.roomAreaVariance != empty) ROOM_AREA_VARIANCE = mapHint.roomAreaVariance;
            if (mapHint.roomSize != empty) ROOM_SIZE = mapHint.roomSize;
            if (mapHint.emptyAreaCount != empty) ROOM_EMPTY_AREA_COUNT = mapHint.emptyAreaCount;
            if (mapHint.scatterChar != empty) ROOM_SCATTER_CHAR = mapHint.scatterChar;
            if (mapHint.scatterRate != empty) ROOM_SCATTER_RATE = mapHint.scatterRate;
            
            generateLayout();
            return self;
        }   
        
        this.interface = {
            areas : {
                get ::<- areas
            },
            
            getRandomArea :: {
                return random.pickArrayItem(list:areas);
            }
        
        } 
    }
);
