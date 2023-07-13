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


@:mapSizeW  = 38;
@:mapSizeH  = 16;

@:EPSILON = 0.000001;

@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
};



@:generateTerrain::(map, width, height) {
    @:symbolList = [
        map.addScenerySymbol(character:' '),
        map.addScenerySymbol(character:'╿'),
        map.addScenerySymbol(character:'.'),
        map.addScenerySymbol(character:'`'),
        map.addScenerySymbol(character:'^'),
        map.addScenerySymbol(character:'░')
    ];
    @:out = {};
    [0, 20]->for(do:::(i) {
        out->push(value:{
            x: (Number.random() * width)->floor,
            y: (Number.random() * height)->floor,
            symbol: symbolList[random.integer(from:1, to:symbolList->keycount-1)]
        });
    });


    [0, 20]->for(do:::(i) {
        out->push(value:{
            x: 0,
            y: (Number.random() * height)->floor,
            symbol: symbolList[0]
        });
    });

    [0, 20]->for(do:::(i) {
        out->push(value:{
            x: width,
            y: (Number.random() * height)->floor,
            symbol: symbolList[0]
        });
    });

    [0, 20]->for(do:::(i) {
        out->push(value:{
            x: (Number.random()*width)->floor,
            y: 0,
            symbol: symbolList[0]
        });
    });

    [0, 20]->for(do:::(i) {
        out->push(value:{
            x: (Number.random()*width)->floor,
            y: height,
            symbol: symbolList[0]
        });
    });



    
    @xIncr = 1;
    @yIncr = 1;
    
    [0, 10]->for(do:::(i) {
        @nextset = {};
        out->foreach(do:::(n, val) {
            when(Number.random() < 0.5) empty;
            @:choice = (Number.random() * 4)->floor;
            
            nextset->push(value:{
                x: if (choice == 1) val.x+xIncr else if (choice == 2) val.x-xIncr else val.x,
                y: if (choice == 3) val.y+yIncr else if (choice == 0) val.y-yIncr else val.y,
                symbol: val.symbol
            });
        });
        
        nextset->foreach(do:::(n, val) <- out->push(value:val));
    });
    return out;
};

return class(
    name: 'Wyvern.LargeMap',
    inherits:[import(module:'game_class.mapbase.mt')],


  
    define:::(this) {

        this.constructor = ::(state, sizeW, sizeH) {
            when (state) ::<= {
                this.state = state;
                return this;
            };
            
            this.width = sizeW;
            this.height = sizeH;
            this.offsetX = 100;
            this.offsetY = 100;
            this.paged = true;
            this.drawLegend = true;
            
            generateTerrain(map:this, width:this.width, height:this.height)->foreach(do::(index, value) {
                //when(value.x < 0 || value.x >= this.width || value.y < 0 || value.y >= this.height)
                    //empty;
                this.setSceneryIndex(
                    x:value.x,
                    y:value.y,
                    symbol:value.symbol
                );
            });
            return this;
                    
        };
    }
);
