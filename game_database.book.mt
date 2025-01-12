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
@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'game_class.database.mt');
@:StatSet = import(module:'game_class.statset.mt');



@:reset ::{




Book.newEntry(
  data : {
    name : 'How to Fight',
    id : 'base:how-to-fight',
    author : 'Guildmaster Kyurth',
    onGetContents :: {
      import(:'game_function.battletutorial.mt')();
      return "That's about all it says.";
    }
  }
) 

Book.newEntry(
  data : {
    name : '???',
    id : 'base:???',
    author : '???',
    onGetContents :: {
      return "It looks like this book was ruined. It's impossible to read now.";
    }
  }
) 

}

@:Book = Database.new(
  name : 'Wyvern.Book',
  attributes : {
    name : String,
    id : String,
    author : String,
    onGetContents : Function 
  },
  reset 
);




return Book;
