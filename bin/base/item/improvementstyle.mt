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
@:Database = import(module:'core/data/database.mt');
@:StatSet = import(module:'base/util/statset.mt');


@:reset::{
ImprovementStyle.newEntry(
  data : {
    name : 'Balanced',
    id : 'base:balanced',
    description : 'Doesn\'t focus on any specific aspect, but it\'s well-rounded',
    expMultiplier : 1,
    stats : StatSet.new(
      ATK: 25,
      DEF: 25,
      SPD: 25,
      INT: 25,
      DEX: 25
    ),
    onLevel ::(item, stat) {}
  }
)

ImprovementStyle.newEntry(
  data : {
    name : 'Forceful',
    id : 'base:forceful',
    description : 'Good for ATK and DEF.',
    expMultiplier : 1,
    stats : StatSet.new(
      DEF: 35,
      ATK: 35,
      SPD: 10,
      DEX: 20
    ),
    onLevel ::(item, stat) {}
  }
)


ImprovementStyle.newEntry(
  data : {
    name : 'Careful',
    id : 'base:careful',
    description : 'Good for INT and DEX.',
    expMultiplier : 1,
    stats : StatSet.new(
      INT: 35,
      DEX: 35,
      SPD: 10,
      DEF: 20
    ),
    onLevel ::(item, stat) {}
  }
)


}

@:ImprovementStyle = Database.new(
  name: 'Wyvern.ImprovementStyle',
  attributes : {
    name : String,
    id : String,
    description : String,
    expMultiplier : Number,
    // percent application to the 
    stats : StatSet.type,
    
    
    onLevel : Function
  },
  reset
);



return ImprovementStyle;

