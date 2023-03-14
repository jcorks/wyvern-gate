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
@:canvas = import(module:'singleton.canvas.mt');
@:class = import(module:'Matte.Core.Class');

@:MAP_SIZE = 70;

@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
};


return class(
    inherits:[import(module:'class.mapbase.mt')],
    name: 'Wyvern.Map',
    define:::(this) {
        this.constructor = ::{
            this.width = MAP_SIZE;
            this.height = MAP_SIZE;
            this.paged = false;
            return this;
        };
        
        this.interface = {       
            isTileVisible::(x, y) {
                @itemX = ((x - this.pointerX + this.MAP_CHARS_WIDTH /2))->floor;
                @itemY = ((y - this.pointerY + this.MAP_CHARS_HEIGHT/2))->floor;
            
                return !(itemX < 1 || itemY < 1 || itemX >= this.MAP_CHARS_WIDTH || itemY > this.MAP_CHARS_HEIGHT);
            }
        };
    }
);
