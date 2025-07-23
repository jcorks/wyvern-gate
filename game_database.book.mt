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
    author : 'Guildmaster Tsahlothi',
    onGetContents :: {
      import(:'game_function.battletutorial.mt')();
      return "That's about all it says.";
    }
  }
) 

Book.newEntry(
  data : {
    name : '(Ruined)',
    id : 'base:???',
    author : '???',
    onGetContents :: {
      return "It looks like this book was ruined. It's impossible to read now.";
    }
  }
) 


Book.newEntry(
  data : {
    name : 'The Fisherman\'s Legend',
    id : 'base:the-fishermans-tale',
    author : 'Ota Veithi-Ta',
    onGetContents ::<-
      [
        'The Fisherman\'s Legend, or as it is referred to by some \"The Fisherman\'s Myth\", used to be known far and wide. However, due to it\'s relatively niche subject, has lost much of its popularity over the last few decades among island folk.',
        'The legend and its loss in popularity are signs of the shifting of beliefs and culture surrounding such topics.',
        'While the legend itself fluctuates from telling to telling, here is a brief overview of the myth.',
        'The Fisherman\'s Legend alleges that an island exists that is entirely as a large inland sea absolutely teeming with various species of fish. While fish are relatively rare on most islands, the base of the legend is pretty simple.', 
        'However, the legend typically goes further warning of a particularly possessive Wyvern living on the island who, supposedly, turns anyone wandering in the island into various sea creatures to join the inland sea for eternity. Some even say that a key to the island exists in a Shrine flooded with water, waiting for someone to claim it.',
        'Upon research with various scholars, it turns out that the addition of the possessive Wyvern, who stands unnamed in most tellings, and the Shrine key, which is often omitted from the telling, are relatively recent additions. It could even be said that these addition brought the myth into the mainstream.',
        'If these are indeed recent additions, it could be more likely that such an island with an inland sea does in fact exist, but the story has been "enhanced" with "additional details" which attributed greatly to its spread.',
        'Regardless, the tale seems to be reaching the tail-end of its popularity, but it\'s impact on legends in the public mind continue.'
      ]
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
