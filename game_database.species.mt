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
@:Database = import(module:'game_class.database.mt');
@:class = import(module:'Matte.Core.Class');
@:StatSet = import(module:'game_class.statset.mt');



@:TRAITS = {
  SPECIAL : 1,
  SUMMON : 2,
  ETHEREAL : 4
};



// 36 points
@:reset ::{

Species.newEntry(data:{
  name : 'Wolf',
  id : 'base:wolf',
  rarity : 10,
  description: 'A common canid race.',
  growth : StatSet.new(
    HP : 8,
    AP : 2,
    ATK: 4,
    DEF: 4,
    INT: 2,
    LUK: 1,
    SPD: 7,
    DEX: 8
  ),    
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:body',
    'base:tail'
  ],
  traits : 0,
  canBlock : true,
  passives : [
  ],
  swarms : false
})

Species.newEntry(data:{
  name : 'Lynx',
  id : 'base:lynx',
  rarity : 10,
  description: 'A felid race.',
  growth : StatSet.new(
    HP : 2,
    AP : 6,
    ATK: 2,
    DEF: 2,
    INT: 8,
    LUK: 6,
    SPD: 6,
    DEX: 4
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:body',
    'base:tail'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Rabbit',
  id : 'base:rabbit',
  rarity : 10,
  description: 'A mammal race of medium stature.',
  growth : StatSet.new(
    HP : 2,
    AP : 6,
    ATK: 4,
    DEF: 1,
    INT: 4,
    LUK: 4,
    SPD: 7,
    DEX: 8
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Fox',
  id : 'base:fox',
  rarity : 10,
  description: 'A canid race.',
  growth : StatSet.new(
    HP : 2,
    AP : 6,
    ATK: 4,
    DEF: 1,
    INT: 5,
    LUK: 8,
    SPD: 6,
    DEX: 4
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Kitsune',
  id : 'base:kitsune',
  rarity : 10,
  description: 'A canid race.',
  growth : StatSet.new(
    HP : 2,
    AP : 5,
    ATK: 2,
    DEF: 1,
    INT: 8,
    LUK: 3,
    SPD: 7,
    DEX: 8
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  
  canBlock : true,
  traits : 0,
  passives : [
  ]
})  

Species.newEntry(data:{
  name : 'Tiger',
  id : 'base:tiger',
  description: 'A common felid race.',
  rarity : 45,
  growth : StatSet.new(
    HP : 5,
    AP : 3,
    ATK: 7,
    DEF: 2,
    INT: 4,
    LUK: 2,
    SPD: 6,
    DEX: 7
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Deer',
  id : 'base:deer',
  description: 'A common ungulate race.',
  rarity : 10,
  growth : StatSet.new(
    HP : 3,
    AP : 4,
    ATK: 3,
    DEF: 4,
    INT: 4,
    LUK: 6,
    SPD: 6,
    DEX: 6
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Goat',
  id : 'base:goat',
  description: 'A common ungulate race.',
  rarity : 10,
  growth : StatSet.new(
    HP : 3,
    AP : 4,
    ATK: 4,
    DEF: 2,
    INT: 3,
    LUK: 6,
    SPD: 6,
    DEX: 8
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body',
    'base:horns'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Sheep',
  id : 'base:sheep',
  description: 'A common ungulate race.',
  rarity : 10,
  growth : StatSet.new(
    HP : 3,
    AP : 6,
    ATK: 3,
    DEF: 4,
    INT: 6,
    LUK: 4,
    SPD: 6,
    DEX: 4
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body',
    'base:horns'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})
Species.newEntry(data:{
  name : 'Gazelle',
  id : 'base:gazelle',
  description: 'A tall ungulate race.',
  rarity : 40,
  growth : StatSet.new(
    HP : 3,
    AP : 6,
    ATK: 3,
    DEF: 3,
    INT: 7,
    LUK: 3,
    SPD: 8,
    DEX: 3
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})  


Species.newEntry(data:{
  name : 'Kobold',
  id : 'base:kobold',
  description: 'A common dragon-like race of small stature.',
  rarity : 30,
  growth : StatSet.new(
    HP : 1,
    AP : 8,
    ATK: 1,
    DEF: 1,
    INT: 8,
    LUK: 1,
    SPD: 8,
    DEX: 8
  ),
  qualities : [
    'base:snout',
    'base:scales',
    'base:eyes',
    'base:face',
    'base:tail',
    'base:horns',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Drake-kin',
  id : 'base:drake-kin',
  description: 'A common dragon-like race of medium stature with fur.',
  rarity : 30,
  growth : StatSet.new(
    HP : 5,
    AP : 4,
    ATK: 4,
    DEF: 9,
    INT: 5,
    LUK: 2,
    SPD: 1,
    DEX: 6
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:face',
    'base:tail',
    'base:horns',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Serval',
  id : 'base:serval',
  description: 'A felid race of medium stature.',
  rarity : 30,
  growth : StatSet.new(
    HP : 3,
    AP : 2,
    ATK: 4,
    DEF: 2,
    INT: 4,
    LUK: 6,
    SPD: 8,
    DEX: 7
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Jackal',
  id : 'base:jackal',
  rarity : 30,
  description: 'A slender canid race.',
  growth : StatSet.new(
    HP : 6,
    AP : 5,
    ATK: 2,
    DEF: 2,
    INT: 4,
    LUK: 6,
    SPD: 5,
    DEX: 6
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Opossum',
  id : 'base:possum',
  rarity : 40,
  description: 'A marsupial race of medium stature.',
  growth : StatSet.new(
    HP : 7,
    AP : 3,
    ATK: 3,
    DEF: 3,
    INT: 4,
    LUK: 10,
    SPD: 3,
    DEX: 3
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Bear',
  id : 'base:bear',
  rarity : 100,
  description: 'A large mammal race.',
  growth : StatSet.new(
    HP : 12,
    AP : 1,
    ATK: 8,
    DEF: 9,
    INT: 2,
    LUK: 1,
    SPD: 1,
    DEX: 2
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Kangaroo',
  id : 'base:kangaroo',
  rarity : 100,
  description: 'A large mammal race.',
  growth : StatSet.new(
    HP : 5,
    AP : 4,
    ATK: 10,
    DEF: 2,
    INT: 5,
    LUK: 1,
    SPD: 6,
    DEX: 3
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Raven',
  id : 'base:raven',
  rarity : 100,
  description: 'A bird race of medium stature',
  growth : StatSet.new(
    HP : 3,
    AP : 9,
    ATK: 3,
    DEF: 2,
    INT: 8,
    LUK: 2,
    SPD: 5,
    DEX: 4
  ),
  qualities : [
    'base:feathers',
    'base:eyes',
    'base:face',
    'base:body'
  ],    
  swarms : false,
  canBlock : true,
  traits : 0,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Pigeon',
  id : 'base:pigeon',
  rarity : 100,
  description: 'A bird race of medium stature',
  growth : StatSet.new(
    HP : 4,
    AP : 1,
    ATK: 5,
    DEF: 5,
    INT: 1,
    LUK: 9,
    SPD: 10,
    DEX: 1
  ),
  qualities : [
    'base:feathers',
    'base:eyes',
    'base:face',
    'base:body'
  ],    
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})



Species.newEntry(data:{
  name : 'Rat',
  id : 'base:rat',
  rarity : 100,
  description: 'A rodent race of medium stature',
  growth : StatSet.new(
    HP : 5,
    AP : 5,
    ATK: 4,
    DEF: 4,
    INT: 5,
    LUK: 3,
    SPD: 5,
    DEX: 5
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  // OKAY HEAR ME OUT... THIS COULD BE FUNNY....
  swarms : true,
    
  canBlock : true,
  traits : 0,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Caracal',
  id : 'base:caracal',
  rarity : 40,
  description: 'A felid race of medium stature',
  growth : StatSet.new(
    HP : 4,
    AP : 6,
    ATK: 3,
    DEF: 4,
    INT: 7,
    LUK: 2,
    SPD: 7,
    DEX: 3
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Tanuki',
  id : 'base:tanuki',
  rarity : 40,
  description: 'A canid race of medium stature',
  growth : StatSet.new(
    HP : 6,
    AP : 4,
    ATK: 2,
    DEF: 8,
    INT: 5,
    LUK: 2,
    SPD: 3,
    DEX: 6
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Werewolf',
  id : 'base:werewolf',
  rarity : 200,
  description: 'Canid race thought to be blessed by the moon.',
  growth : StatSet.new(
    HP : 8,
    AP : 2,
    ATK: 10,
    DEF: 1,
    INT: 2,
    LUK: 1,
    SPD: 10,
    DEX: 2
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Hyena',
  id : 'base:hyena',
  rarity: 100,
  description: 'A mammal race of medium stature.',
  growth : StatSet.new(
    HP : 4,
    AP : 2,
    ATK: 5,
    DEF: 3,
    INT: 7,
    LUK: 2,
    SPD: 6,
    DEX: 7
  ),
  traits : 0,
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Gnoll',
  id : 'base:gnoll',
  rarity : 200,
  description: 'A mammal race of medium stature.',
  growth : StatSet.new(
    HP : 6,
    AP : 1,
    ATK: 8,
    DEF: 5,
    INT: 2,
    LUK: 1,
    SPD: 7,
    DEX: 6
  ),
  qualities : [
    'base:snout',
    'base:fur',
    'base:eyes',
    'base:ears',
    'base:face',
    'base:tail',
    'base:body'
  ],
  swarms : false,
  canBlock : true,
  
  traits : 0,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Creature',
  id : 'base:creature',
  rarity : 200000000000,
  description: '',
  growth : StatSet.new(
    HP : 7,
    AP : 1,
    ATK: 4,
    DEF: 4,
    INT: 2,
    LUK: 1,
    SPD: 7,
    DEX: 4
  ),
  qualities : [
  ],
  swarms : true,
  canBlock : false,
  
  traits : TRAITS.SPECIAL,
  passives : [
  ]
})



Species.newEntry(data:{
  name : 'Fire Sprite',
  id : 'base:fire-sprite',
  rarity : 2000000000000,
  description: 'Hot n\' spicy!',
  growth : StatSet.new(
    HP : 3,
    AP : 1,
    ATK: 7,
    DEF: 4,
    INT: 7,
    LUK: 1,
    SPD: 2,
    DEX: 4
  ),
  qualities : [

  ],
  swarms : false,
  canBlock : false,
  
  traits : TRAITS.SPECIAL  | TRAITS.SUMMON,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Defensive Pylon',
  id : 'base:defensive-pylon',
  rarity : 2000000000000,
  description: 'A good buddy.',
  growth : StatSet.new(
    HP : 4,
    AP : 1,
    ATK: 7,
    DEF: 10,
    INT: 7,
    LUK: 1,
    SPD: 2,
    DEX: 4
  ),
  qualities : [

  ],
  swarms : false,
  canBlock : false,
  
  traits : TRAITS.SPECIAL  | TRAITS.SUMMON,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Ice Elemental',
  id : 'base:ice-elemental',
  rarity : 2000000000000,
  description: 'Brrr that\'s cold!',
  growth : StatSet.new(
    HP : 7,
    AP : 4,
    ATK: 7,
    DEF: 4,
    INT: 7,
    LUK: 1,
    SPD: 6,
    DEX: 4
  ),
  qualities : [

  ],
  swarms : false,
  canBlock : false,
  
  traits : TRAITS.SPECIAL | TRAITS.SUMMON,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Thunder Spawn',
  id : 'base:thunder-spawn',
  rarity : 2000000000000,
  description: 'Shocking!',
  growth : StatSet.new(
    HP : 7,
    AP : 6,
    ATK: 10,
    DEF: 4,
    INT: 7,
    LUK: 1,
    SPD: 6,
    DEX: 4
  ),
  qualities : [

  ],
  swarms : false,
  canBlock : false,
  
  traits : TRAITS.SPECIAL | TRAITS.SUMMON,
  passives : [
  ]
})  


Species.newEntry(data:{
  name : 'Guiding Light',
  id : 'base:guiding-light',
  rarity : 2000000000000,
  description: 'Oh!',
  growth : StatSet.new(
    HP : 7,
    AP : 12,
    ATK: 2,
    DEF: 4,
    INT: 7,
    LUK: 1,
    SPD: 6,
    DEX: 8
  ),
  qualities : [

  ],
  swarms : false,
  canBlock : false,
  
  traits : TRAITS.SPECIAL | TRAITS.SUMMON,
  passives : [
  ]
})  



Species.newEntry(data:{
  name : 'Wyvern',
  id : 'base:wyvern',
  rarity : 2000000000000,
  description: 'Keepers of the gates',
  growth : StatSet.new(
    HP : 60,
    AP : 10,
    ATK: 10,
    DEF: 10,
    INT: 10,
    LUK: 10,
    SPD: 10,
    DEX: 10
  ),
  qualities : [
  ],
  swarms : false,
  canBlock : true,
  
  traits : TRAITS.SPECIAL,
  passives : [
    'base:the-wyvern'
  ]
})



Species.newEntry(data:{
  name : 'Wyvern Specter',
  id : 'base:wyvern-specter',
  rarity : 2000000000000,
  description: 'Ancient spirit',
  growth : StatSet.new(
    HP : 60,
    AP : 10,
    ATK: 10,
    DEF: 10,
    INT: 10,
    LUK: 10,
    SPD: 10,
    DEX: 10
  ),
  qualities : [
  ],
  swarms: true,
  traits : TRAITS.SPECIAL | TRAITS.ETHEREAL,
  canBlock : false,
  passives : [
    'base:apparition'
  ]
})


Species.newEntry(data:{
  name : 'Beast',
  id : 'base:beast',
  rarity : 2000000000000,
  description: 'Force of nature',
  growth : StatSet.new(
    HP : 60,
    AP : 10,
    ATK: 10,
    DEF: 10,
    INT: 10,
    LUK: 10,
    SPD: 10,
    DEX: 10
  ),
  qualities : [
  ],
  swarms : true,
  canBlock : false,
  
  traits : TRAITS.SPECIAL,
  passives : [
    'base:the-beast'
  ]
})


Species.newEntry(data:{
  name : 'Mimic',
  id : 'base:mimic',
  rarity : 2000000000000,
  description: 'Force of nature',
  growth : StatSet.new(
    HP : 60,
    AP : 10,
    ATK: 10,
    DEF: 10,
    INT: 10,
    LUK: 10,
    SPD: 10,
    DEX: 10
  ),
  qualities : [
  ],
  swarms : true,
  canBlock : false,
  
  traits : TRAITS.SPECIAL,
  passives : [
    'base:the-beast'
  ]
})


Species.newEntry(data:{
  name : 'Treasure Golem',
  id : 'base:treasure-golem',
  rarity : 2000000000000,
  description: 'Looks like a chest! Not as friendly though.',
  growth : StatSet.new(
    HP : 60,
    AP : 10,
    ATK: 10,
    DEF: 10,
    INT: 10,
    LUK: 10,
    SPD: 10,
    DEX: 10
  ),
  qualities : [
  ],
  swarms : true,
  canBlock : false,
  
  traits : TRAITS.SPECIAL,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Cave Bat',
  id : 'base:cave-bat',
  rarity : 2000000000000,
  description: 'Large, wild bat.',
  growth : StatSet.new(
    HP : 60,
    AP : 10,
    ATK: 10,
    DEF: 10,
    INT: 10,
    LUK: 10,
    SPD: 10,
    DEX: 10
  ),
  qualities : [
  ],
  swarms : true,
  
  traits : TRAITS.SPECIAL,
  canBlock : false,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Spirit',
  id : 'base:spirit',
  rarity : 2000000000000,
  description: 'A small apparition.',
  growth : StatSet.new(
    HP : 1,
    AP : 5,
    ATK: 5,
    DEF: 5,
    INT: 1,
    LUK: 5,
    SPD: 5,
    DEX: 5
  ),
  qualities : [
  ],
  swarms : true,
  
  traits : TRAITS.SPECIAL | TRAITS.SUMMON,
  canBlock : false,
  passives : [
  ]
})
}


@:Species = class(
  inherits: [Database],
  define::(this) {
    this.interface = {    
      TRAITS : {get::<- TRAITS},
    }
  }
).new(
  name : 'Wyvern.Species',
  statics : {
    
  },
  attributes : {
    name : String,
    id : String,
    rarity: Number,
    qualities : Object,
    description : String,
    growth : StatSet.type,
    passives : Object,
    traits : Number,
    swarms : Boolean,
    canBlock : Boolean
  },
  reset 
);

return Species;
