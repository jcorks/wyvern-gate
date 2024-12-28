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
    description : 'Status ailments include at least the effects Burned, Frozen, Paralyzed, Blind, Bleeding, Poisoned, and Petrified.'
  }
);
ArtsTerm.newEntry(
  data : {
    name : 'Attack Shifts',
    id : 'base:attack-shifts',
    description : 'Attack shifts include the effects Burning, Icy, Shock, Dark, Toxic, and Shimmering, which deal additional damage of a corresponding type.'
  }
);

ArtsTerm.newEntry(
  data : {
    name : 'Resistance Shifts',
    id : 'base:resistance-shifts',
    description : 'Resistance shifts, named "[element] Guard" (i.e. Fire Guard) provide 25% resistance to that type of damage.'
  }
);

ArtsTerm.newEntry(
  data : {
    name : 'Cursed Shifts',
    id : 'base:cursed-shifts',
    description : 'Cursed shifts, named "[element] Curse" (i.e. Fire Curse) damage the holder every turn. This is removed if the holder gains a respective attack shift.'
  }
);

ArtsTerm.newEntry(
  data : {
    name : 'Seeds',
    id : 'base:seeds-effects',
    description : 'Seeds are effects of something growing on the holder. This includes Poisonroot Growing, Triproot Growing, and Healroot Growing.'
  }
);

ArtsTerm.newEntry(
  data : {
    name : 'Innate Effects',
    id : 'base:innate',
    description : 'Innate effects are not removable. They only dissapate once a battle has ended.'
  }
);

ArtsTerm.newEntry(
  data : {
    name : 'Ingredient',
    id : 'base:ingredient',
    description : 'An item gathered by Alchemists through Scavenging. Can be used to brew potions.'
  }
);


ArtsTerm.newEntry(
  data : {
    name : 'Revival Effect',
    id : 'base:revival-effect',
    description : 'Revival Effects are those that heal someone from a knockout or prevents death.'
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
