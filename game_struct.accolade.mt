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
@:struct = import(module:'game_struct.mt');
@:Arts = import(module:'game_database.arts.mt');
@:Database = import(module:'game_class.database.mt');


return struct(
  name: 'Wyvern.Accolade',
  
  items : {
    // The message / name of the accolade to display.
    //Usually a silly / cheeky quote from the dev
    message: String,
    
    // A description of the accolade.
    info: String,
    
    // Condition of when the accolate has been achieved. has the world instance 
    // passed in.
    condition: Function
  }
);  
