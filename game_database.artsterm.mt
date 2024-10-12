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




@:reset :: {
ArtsTerm.newEntry(
  data : {
    name : 'Status Ailments',
    id : 'base:ailments',
    description : 'Status ailments include the effects Burned, Frozen, Paralyzed, Blind, Bleeding, Poisoned, and Petrified.'
  }
);

ArtsTerm.newEntry(
  data : {
    name : 'Ingredient',
    id : 'base:ingredient',
    description : 'An item gathered by Alchemists through Scavenging. Can be used to brew potions.'
  }
);



}

@:ArtsTerm = Database.new(
  name : 'Wyvern.ArtsTerm',
  attributes : {
    name : String,
    id : String,
    description : String
  },
  reset
);






return ArtsTerm;
