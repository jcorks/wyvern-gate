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
    inherits:[import(module:'game_class.mapbase.mt')],

    new::(state, sizeW, sizeH) {
        @:this = LargeMap.defaultNew();
        this.initialize(state, sizeW, sizeH);
        return this;
    },
  
    define:::(this) {
        
        this.interface = {

            initialize::(state, sizeW, sizeH) {
                when (state) ::<= {
                    this.state = state;
                    return this;
                }
                
                this.width = sizeW + BUFFER_SPACE*2;
                this.height = sizeH + BUFFER_SPACE*2;

                @index = this.addScenerySymbol(character:'▓');

                for(0, this.height)::(y) {
                    for(0, this.width)::(x) {
                        when(y > BUFFER_SPACE && x > BUFFER_SPACE &&
                             x < sizeW + BUFFER_SPACE && y < sizeH + BUFFER_SPACE) empty;
                        this.enableWall(x, y);
                        this.setSceneryIndex(x, y, symbol:index);
                    }
                }
                
                this.offsetX = 100;
                this.offsetY = 100;
                this.paged = true;
                this.drawLegend = true;
                
                foreach(generateTerrain(map:this, width:this.width - BUFFER_SPACE*2, height:this.height - BUFFER_SPACE*2))::(index, value) {
                    //when(value.x < 0 || value.x >= this.width || value.y < 0 || value.y >= this.height)
                        //empty;
                    this.setSceneryIndex(
                        x:value.x,
                        y:value.y,
                        symbol:value.symbol
                    );
                }
                return this;
                        
            },


             addLandmark::(island, base) { 
                @landmark = Landmark.new(
                    base,
                    island,             
                    x:random.integer(from:BUFFER_SPACE + (0.2*(this.width  - BUFFER_SPACE*2))->floor, to:(this.width  - BUFFER_SPACE)-(0.2*(this.width  - BUFFER_SPACE*2))->floor),
                    y:random.integer(from:BUFFER_SPACE + (0.2*(this.height - BUFFER_SPACE*2))->floor, to:(this.height - BUFFER_SPACE)-(0.2*(this.height - BUFFER_SPACE*2))->floor)
                );
                this.setItem(data:landmark, x:landmark.x, y:landmark.y, symbol:landmark.base.symbol, name:landmark.base.name);
                return landmark;
            },
            
            getAPosition ::{
                return {
                    x:random.integer(from:BUFFER_SPACE + (0.2*(this.width  - BUFFER_SPACE*2))->floor, to:(this.width  - BUFFER_SPACE)-(0.2*(this.width  - BUFFER_SPACE*2))->floor),
                    y:random.integer(from:BUFFER_SPACE + (0.2*(this.height - BUFFER_SPACE*2))->floor, to:(this.height - BUFFER_SPACE)-(0.2*(this.height - BUFFER_SPACE*2))->floor)
                }
            }
            
            
        }
    }
);
return LargeMap;
