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
@:Landmark = import(module:'game_class.landmark.mt');
@:Map = import(module:'game_class.map.mt');

@:mapSizeW  = 38;
@:mapSizeH  = 16;

@:BUFFER_SPACE = 60;

@:EPSILON = 0.000001;

@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
}



@:generateTerrain::(map, width, height) {
    @:symbolList = [
        map.addScenerySymbol(character:' '),
        map.addScenerySymbol(character:'╿'),
        map.addScenerySymbol(character:'.'),
        map.addScenerySymbol(character:'`'),
        map.addScenerySymbol(character:'^'),
        map.addScenerySymbol(character:'░')
    ];
    @:out = [];
    @:seedCount = ((width*height)**0.5) / 2.5

    for(0, seedCount)::(i) {
        out[
                                      (Number.random() * width)->floor + BUFFER_SPACE + 
            (width + BUFFER_SPACE*2) * ((Number.random() * height)->floor + BUFFER_SPACE)
        ] = symbolList[random.integer(from:1, to:symbolList->keycount-1)]
    }


    for(0, seedCount)::(i) {
        out[
                    0 + BUFFER_SPACE+
            (width + BUFFER_SPACE*2) * ((Number.random() * height)->floor + BUFFER_SPACE)
        ] = symbolList[0];
    }

    for(0, seedCount)::(i) {
        out[
                    width + BUFFER_SPACE+
            (width + BUFFER_SPACE*2) * ((Number.random() * height)->floor + BUFFER_SPACE)
        ] = symbolList[0];
    }

    for(0, seedCount)::(i) {
        out[
                    (Number.random()*width)->floor + BUFFER_SPACE+
            (width + BUFFER_SPACE*2) * (0 + BUFFER_SPACE)
        ] = symbolList[0];
    }

    for(0, seedCount)::(i) {
        out[
                    (Number.random()*width)->floor + BUFFER_SPACE + 
            (width + BUFFER_SPACE*2) * (height + BUFFER_SPACE)
        ] = symbolList[0];
    }



    
    @xIncr = 1;
    @yIncr = 1;
    
    for(0, 4)::(i) {
        for(0, height + BUFFER_SPACE*2) ::(y) {
            for(0, width + BUFFER_SPACE*2) ::(x) {
                //when(Number.random() < 0.4) empty;
                @:val = out[x + (width + BUFFER_SPACE*2) * y];
                when(val == empty) empty;
                
                @:choice = (Number.random() * 4)->floor;
                @newx = if (choice == 1) x+xIncr else if (choice == 2) x-xIncr else x;
                @newy = if (choice == 3) y+yIncr else if (choice == 0) y-yIncr else y;
                out[newx + (width + BUFFER_SPACE*2) * newy] = val;
                
            }
        }
    }

    // fill gaps
    for(0, 2)::(i) {
        for(0, height + BUFFER_SPACE*2) ::(y) {
            for(0, width + BUFFER_SPACE*2) ::(x) {
                //when(Number.random() < 0.4) empty;
                @:val = out[x + (width + BUFFER_SPACE*2) * y];
                when(val != empty) empty;
                

                @v;                
                @:v0 = out[x + 1 + (width + BUFFER_SPACE*2) * y];
                @:v1 = out[x - 1 + (width + BUFFER_SPACE*2) * y];
                @:v2 = out[x     + (width + BUFFER_SPACE*2) * (y+1)];
                @:v3 = out[x     + (width + BUFFER_SPACE*2) * (y-1)];
                
                @sides = 
                    (if (v0 != empty) 1 else 0)+
                    (if (v1 != empty) 1 else 0)+
                    (if (v2 != empty) 1 else 0)+
                    (if (v3 != empty) 1 else 0)
                ;
                if (sides >= 3)
                    out[x + (width + BUFFER_SPACE*2) * y] = random.pickArrayItem(list:[v0, v1, v2, v3]->filter(by::(value) <- value != empty));
                

            }
        }
    }

    return out;
}

@:LargeMap = class(
    name: 'Wyvern.LargeMap',
    define:::(this) {
        
        this.interface = {

            create::(parent, sizeW, sizeH) {                
                @:map = Map.new(parent);
                map.width = sizeW + BUFFER_SPACE*2;
                map.height = sizeH + BUFFER_SPACE*2;

                @index = map.addScenerySymbol(character:'▓');

                for(0, map.height)::(y) {
                    for(0, map.width)::(x) {
                        when(y > BUFFER_SPACE && x > BUFFER_SPACE &&
                             x < sizeW + BUFFER_SPACE && y < sizeH + BUFFER_SPACE) empty;
                        map.enableWall(x, y);
                        map.setSceneryIndex(x, y, symbol:index);
                    }
                }
                
                map.offsetX = 100;
                map.offsetY = 100;
                map.paged = true;
                map.drawLegend = true;
                
                @:table = generateTerrain(map, width:map.width - BUFFER_SPACE*2, height:map.height - BUFFER_SPACE*2);

                for(0, map.height) ::(y) {
                    for(0, map.width) ::(x) {
                        @:val = table[x + (sizeW + BUFFER_SPACE*2) * y];
                        when(val == empty) empty;
                        map.setSceneryIndex(
                            x:x,
                            y:y,
                            symbol:val
                        );
                    }
                }
                return map;
                        
            },


            addLandmark::(map, island, base) { 
                return island.newLandmark(
                    base,
                    x:random.integer(from:BUFFER_SPACE + (0.2*(map.width  - BUFFER_SPACE*2))->floor, to:(map.width  - BUFFER_SPACE)-(0.2*(map.width  - BUFFER_SPACE*2))->floor),
                    y:random.integer(from:BUFFER_SPACE + (0.2*(map.height - BUFFER_SPACE*2))->floor, to:(map.height - BUFFER_SPACE)-(0.2*(map.height - BUFFER_SPACE*2))->floor)
                );
            },
            
            getAPosition ::(map) {
                return {
                    x:random.integer(from:BUFFER_SPACE + (0.2*(map.width  - BUFFER_SPACE*2))->floor, to:(map.width  - BUFFER_SPACE)-(0.2*(map.width  - BUFFER_SPACE*2))->floor),
                    y:random.integer(from:BUFFER_SPACE + (0.2*(map.height - BUFFER_SPACE*2))->floor, to:(map.height - BUFFER_SPACE)-(0.2*(map.height - BUFFER_SPACE*2))->floor)
                }
            }
            
            
        }
    }
);
return LargeMap.new();
