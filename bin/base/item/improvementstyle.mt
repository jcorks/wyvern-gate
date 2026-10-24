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



ImprovementStyle.newEntry(
  data : {
    name : 'Sharp I',
    id : 'base:sharpi',
    description : 'Good for ATK.',
    expMultiplier : 1,
    stats : StatSet.new(
      ATK: 55,
      DEX: 35,
      SPD: 15
    ),
    onLevel ::(item, stat) {}
  }
)

ImprovementStyle.newEntry(
  data : {
    name : 'Sharp II',
    id : 'base:sharpii',
    description : 'Good for ATK.',
    expMultiplier : 1,
    stats : StatSet.new(
      ATK: 75,
      DEX: 35
    ),
    onLevel ::(item, stat) {}
  }
)

ImprovementStyle.newEntry(
  data : {
    name : 'Sharp III',
    id : 'base:sharpiii',
    description : 'Good for ATK.',
    expMultiplier : 1,
    stats : StatSet.new(
      ATK: 55
    ),
    onLevel ::(item, stat) {}
  }
)






ImprovementStyle.newEntry(
  data : {
    name : 'Hard I',
    id : 'base:hardi',
    description : 'Good for DEF.',
    expMultiplier : 1,
    stats : StatSet.new(
      DEF: 55,
      DEX: 35,
      SPD: 15
    ),
    onLevel ::(item, stat) {}
  }
)

ImprovementStyle.newEntry(
  data : {
    name : 'Hard II',
    id : 'base:hardii',
    description : 'Good for DEF.',
    expMultiplier : 1,
    stats : StatSet.new(
      DEF: 75,
      DEX: 35
    ),
    onLevel ::(item, stat) {}
  }
)

ImprovementStyle.newEntry(
  data : {
    name : 'Hard III',
    id : 'base:hardiii',
    description : 'Good for DEF.',
    expMultiplier : 1,
    stats : StatSet.new(
      DEF: 55
    ),
    onLevel ::(item, stat) {}
  }
)



ImprovementStyle.newEntry(
  data : {
    name : 'Swift I',
    id : 'base:swifti',
    description : 'Good for SPD.',
    expMultiplier : 1,
    stats : StatSet.new(
      INT: 15,
      DEX: 35,
      SPD: 55
    ),
    onLevel ::(item, stat) {}
  }
)

ImprovementStyle.newEntry(
  data : {
    name : 'Swift II',
    id : 'base:swiftii',
    description : 'Good for SPD.',
    expMultiplier : 1,
    stats : StatSet.new(
      SPD: 75,
      DEX: 35
    ),
    onLevel ::(item, stat) {}
  }
)

ImprovementStyle.newEntry(
  data : {
    name : 'Swift III',
    id : 'base:swiftiii',
    description : 'Good for SPD.',
    expMultiplier : 1,
    stats : StatSet.new(
      SPD: 55
    ),
    onLevel ::(item, stat) {}
  }
)




ImprovementStyle.newEntry(
  data : {
    name : 'Wary I',
    id : 'base:waryi',
    description : 'Good for INT.',
    expMultiplier : 1,
    stats : StatSet.new(
      SPD: 15,
      DEX: 35,
      INT: 55
    ),
    onLevel ::(item, stat) {}
  }
)

ImprovementStyle.newEntry(
  data : {
    name : 'Wary II',
    id : 'base:waryii',
    description : 'Good for INT.',
    expMultiplier : 1,
    stats : StatSet.new(
      INT: 75,
      DEX: 35
    ),
    onLevel ::(item, stat) {}
  }
)

ImprovementStyle.newEntry(
  data : {
    name : 'Wary III',
    id : 'base:waryiii',
    description : 'Good for INT.',
    expMultiplier : 1,
    stats : StatSet.new(
      INT: 55
    ),
    onLevel ::(item, stat) {}
  }
)





ImprovementStyle.newEntry(
  data : {
    name : 'Precise I',
    id : 'base:precisei',
    description : 'Good for DEX.',
    expMultiplier : 1,
    stats : StatSet.new(
      SPD: 15,
      DEX: 35,
      INT: 55
    ),
    onLevel ::(item, stat) {}
  }
)

ImprovementStyle.newEntry(
  data : {
    name : 'Precise II',
    id : 'base:preciseii',
    description : 'Good for DEX.',
    expMultiplier : 1,
    stats : StatSet.new(
      INT: 75,
      DEX: 35
    ),
    onLevel ::(item, stat) {}
  }
)

ImprovementStyle.newEntry(
  data : {
    name : 'Precise III',
    id : 'base:preciseiii',
    description : 'Good for DEX.',
    expMultiplier : 1,
    stats : StatSet.new(
      INT: 55
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

