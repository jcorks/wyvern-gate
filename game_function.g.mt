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
return ::(g) {
  @neg = g < 0;
  if (g < 0) g *= -1;
   
  when(g < 1000) 
    if (neg) 
      '-' + g + 'G'
    else
      '' + g + 'G'
    ;
    
  @:pad1000::(val) <-  
    '' + 
    ((val / 100) % 10)->floor + 
    ((val / 10) % 10)->floor + 
    (val % 10)->floor
  

  
  // separators
  @out = '';
  {:::} {
    forever ::{
      when(g < 1000) ::<= {
        out = '' + g + out;
        send();
      }
      
      @:digits = (g % 1000);
      out =  ',' + pad1000(val:digits) + out;
      g = (g / 1000)->floor
    }
  }
  return (if (neg) '-' else '') + out + 'G';
}


