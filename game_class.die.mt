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
/*
     _______
    |       |    
    | o   o |    
    |   o   |    
    | o   o |    
    |_______|    


*/

@:lclass = import(module:'game_function.lclass.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:random = import(module:'game_singleton.random.mt');

@:DICE_WIDTH = 9;
@:DICE_HEIGHT = 5;





@:Die = lclass(
    statics : {
        WIDTH : DICE_WIDTH,
        HEIGHT : DICE_HEIGHT  
    },
    constructor ::{
    },
    interface : {
            
        value : {
            get ::<- _.val,
            set ::(value) {
                when (value == empty)
                    _.val = empty;
                _.val => Number;
                if (value < 1 || value > 6)
                    error(message:'Value of a die can only be empty or [1, 6]');
                _.val = value;
            }
        },
        
        roll :: {
            _.val = random.integer(from:1, to:6);
        },
        
        render ::(x, y) {
        
            // render base 
            canvas.movePen(x:x, y:y); canvas.drawChar(text:'┌');
            for(1, DICE_WIDTH-1)::(i) {
                canvas.movePen(x:x+i, y); canvas.drawChar(text:'─');
            }


            canvas.movePen(x:x+DICE_WIDTH-1, y:y); canvas.drawChar(text:'┐');
            for(1, DICE_WIDTH-1)::(i) {
                canvas.movePen(x:x+i, y:y+DICE_HEIGHT-1); canvas.drawChar(text:'─');
            }

            canvas.movePen(x:x, y:y+DICE_HEIGHT-1); canvas.drawChar(text:'└');
            for(1, DICE_HEIGHT-1)::(i) {
                canvas.movePen(x, y:y+i); canvas.drawChar(text:'│');
            }

            canvas.movePen(x:x+DICE_WIDTH-1, y:y+DICE_HEIGHT-1); canvas.drawChar(text:'┘');
            for(1, DICE_HEIGHT-1)::(i) {
                canvas.movePen(x:x+DICE_WIDTH-1, y:y+i); canvas.drawChar(text:'│');
            }


            match(_.val) {
              (1):::<= {
                canvas.movePen(x:x + 4, y:y + 2); canvas.drawChar(text:'o');
              },
              
              (2):::<= {
                canvas.movePen(x:x + 2, y:y + 1); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 6, y:y + 3); canvas.drawChar(text:'o');
              },


              (3):::<= {
                canvas.movePen(x:x + 2, y:y + 1); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 4, y:y + 2); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 6, y:y + 3); canvas.drawChar(text:'o');
              },
              
              (4):::<= {
                canvas.movePen(x:x + 2, y:y + 1); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 2, y:y + 3); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 6, y:y + 3); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 6, y:y + 1); canvas.drawChar(text:'o');
              },

              (5):::<= {
                canvas.movePen(x:x + 2, y:y + 1); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 2, y:y + 3); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 6, y:y + 3); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 6, y:y + 1); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 4, y:y + 2); canvas.drawChar(text:'o');
              },

              (6):::<= {
                canvas.movePen(x:x + 2, y:y + 1); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 2, y:y + 3); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 4, y:y + 3); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 4, y:y + 1); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 6, y:y + 3); canvas.drawChar(text:'o');
                canvas.movePen(x:x + 6, y:y + 1); canvas.drawChar(text:'o');
              }
              
            }            
        }
    }
)

return Die;
