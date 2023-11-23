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

@:BUFFER_SPACE = 30;

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
    @:out = {}
    for(0, 20)::(i) {
        out->push(value:{
            x: (Number.random() * width)->floor + BUFFER_SPACE,
            y: (Number.random() * height)->floor + BUFFER_SPACE,
            symbol: symbolList[random.integer(from:1, to:symbolList->keycount-1)]
        });
    }


    for(0, 20)::(i) {
        out->push(value:{
            x: 0 + BUFFER_SPACE,
            y: (Number.random() * height)->floor + BUFFER_SPACE,
            symbol: symbolList[0]
        });
    }

    for(0, 20)::(i) {
        out->push(value:{
            x: width + BUFFER_SPACE,
            y: (Number.random() * height)->floor + BUFFER_SPACE,
            symbol: symbolList[0]
        });
    }

    for(0, 20)::(i) {
        out->push(value:{
            x: (Number.random()*width)->floor + BUFFER_SPACE,
            y: 0 + BUFFER_SPACE,
            symbol: symbolList[0]
        });
    }

    for(0, 20)::(i) {
        out->push(value:{
            x: (Number.random()*width)->floor + BUFFER_SPACE,
            y: height + BUFFER_SPACE,
            symbol: symbolList[0]
        });
    }



    
    @xIncr = 1;
    @yIncr = 1;
    
    for(0, 10)::(i) {
        @nextset = {}
        foreach(out)::(n, val) {
            when(Number.random() < 0.5) empty;
            @:choice = (Number.random() * 4)->floor;
            
            nextset->push(value:{
                x: if (choice == 1) val.x+xIncr else if (choice == 2) val.x-xIncr else val.x,
                y: if (choice == 3) val.y+yIncr else if (choice == 0) val.y-yIncr else val.y,
                symbol: val.symbol
            });
        }
        
        foreach(nextset)::(n, val) <- out->push(value:val);
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
                
                foreach(generateTerrain(map, width:map.width - BUFFER_SPACE*2, height:map.height - BUFFER_SPACE*2))::(index, value) {
                    //when(value.x < 0 || value.x >= map.width || value.y < 0 || value.y >= map.height)
                        //empty;
                    map.setSceneryIndex(
                        x:value.x,
                        y:value.y,
                        symbol:value.symbol
                    );
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
