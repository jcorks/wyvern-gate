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
@:windowEvent = import(:'game_singleton.windowevent.mt');
@:BattleAction = import(module:'game_struct.battleaction.mt');
@:Arts = import(module:'game_mutator.arts.mt');
@:random = import(module:'game_singleton.random.mt');


@:TRAIT = {
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
  swarms : false,
  overrideBattleAI : empty
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,

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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
    
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
  overrideBattleAI : empty,
  
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
    HP : 0,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Shadowling',
  id : 'base:shadowling',
  rarity : 2000000000000,
  description: 'A moving shadow.',
  growth : StatSet.new(
    HP : 5,
    AP : 1,
    ATK: 2,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Mobile Mushroom',
  id : 'base:mobile-mushroom',
  rarity : 2000000000000,
  description: 'A moving mushroom.',
  growth : StatSet.new(
    HP : 10,
    AP : 1,
    ATK: 1,
    DEF: 4,
    INT: 1,
    LUK: 1,
    SPD: 1,
    DEX: 1
  ),
  qualities : [

  ],
  swarms : false,
  canBlock : false,
  overrideBattleAI ::(entity, battle, commitBattleActions) {
    entity.ap += 2;
    windowEvent.queueMessage(speaker: entity.name, text: '...');
    when(battle.getEnemies(:entity)->size == 0) 
      commitBattleActions(:[BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:wait')),
        targets: [],
        turnIndex : 0,
        targetParts : [],
        extraData: {}
      )])
    
    commitBattleActions(:[
      BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:acidic-gas')),
        targets: battle.getEnemies(:entity),
        turnIndex : 0,
        targetParts : [],
        extraData: {}
      )
    ]);
  },
  
  traits : TRAIT.SPECIAL,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL  | TRAIT.SUMMON,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL  | TRAIT.SUMMON,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL | TRAIT.SUMMON,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL | TRAIT.SUMMON,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL | TRAIT.SUMMON,
  passives : [
  ]
})  



Species.newEntry(data:{
  name : 'Wyvern',
  id : 'base:wyvern',
  rarity : 2000000000000,
  description: 'Keepers of the gates',
  growth : StatSet.new(
    HP : 6,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL,
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
    HP : 6,
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
  traits : TRAIT.SPECIAL | TRAIT.ETHEREAL,
  canBlock : false,
  overrideBattleAI : empty,
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
    HP : 6,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL,
  passives : [
    'base:the-beast'
  ]
})


Species.newEntry(data:{
  name : 'Flaming Skull',
  id : 'base:flaming-skull',
  rarity : 2000000000000,
  description: 'Force of nature',
  growth : StatSet.new(
    HP : 6,
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
  overrideBattleAI ::(entity, battle, commitBattleActions) {
    entity.ap += 2;
    @:Entity = import(module:'game_class.entity.mt');        
    
    @:whosLeft = battle.getEnemies(:entity)->filter(::(value) <- value.isIncapacitated() == false);
    when (whosLeft->size == empty) ::<= {
      windowEvent.queueMessage(text: entity.name + ' seems satisfied.');
      commitBattleActions(:[BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:wait')),
        targets: [],
        turnIndex : 0,
        targetParts : [],
        extraData: {}
      )])
    }

    when(random.flipCoin()) 
      commitBattleActions(:[
        BattleAction.new(
          card: Arts.new(base:Arts.database.find(id:'base:fire')),
          turnIndex : 0,

          targets: [
            random.pickArrayItem(list:whosLeft)
          ],
          targetParts : [
            Entity.normalizedDamageTarget()
          ],
          extraData: {}            
        )      
      ]);
      
    // "hey i do that" - Roxy
    windowEvent.queueMessage(text: entity.name + ' laughs maniacally!');
    commitBattleActions(:[
      BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:doom-strike')),
        targets: [...battle.getEnemies(:entity)],
        turnIndex : 0,
        targetParts : [],
        extraData: {}
      )
    ]);
  },  
  traits : TRAIT.SPECIAL,
  passives : [
    'base:scorching',
    'base:aspect-fire'
  ]
})


Species.newEntry(data:{
  name : 'Mimic',
  id : 'base:mimic',
  rarity : 2000000000000,
  description: 'Force of nature',
  growth : StatSet.new(
    HP : 6,
    AP : 10,
    ATK: 4,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL,
  passives : [
    'base:the-beast'
  ]
})

Species.newEntry(data:{
  name : 'Slime Queen',
  id : 'base:slimequeen',
  rarity : 2000000000000,
  description: 'Force of nature',
  growth : StatSet.new(
    HP : 10,
    AP : 1,
    ATK: 4,
    DEF: 5,
    INT: 0,
    LUK: 0,
    SPD: 1,
    DEX: 1
  ),
  qualities : [
  ],
  swarms : true,
  canBlock : false,
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Slimeling',
  id : 'base:slimeling',
  rarity : 2000000000000,
  description: 'Force of nature',
  growth : StatSet.new(
    HP : 6,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL,
  passives : [
  ]
})

Species.newEntry(data:{
  name : 'Skeleton',
  id : 'base:skeleton',
  rarity : 2000000000000,
  description: 'Force of nature',
  growth : StatSet.new(
    HP : 6,
    AP : 5,
    ATK: 3,
    DEF: 4,
    INT: 7,
    LUK: 1,
    SPD: 7,
    DEX: 10
  ),
  qualities : [
  ],
  swarms : true,
  canBlock : false,
  overrideBattleAI ::(entity, battle, commitBattleActions) {
    @:Entity = import(module:'game_class.entity.mt');        

    when (entity.getEquipped(:Entity.EQUIP_SLOTS.HAND_LR).base.id == 'base:none') ::<= {
      commitBattleActions(:[BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:b198')),
        targets: [],
        turnIndex : 0,
        targetParts : [],
        extraData: {}
      )])
    }
    
    @:targets = battle.getEnemies(:entity);
  
    when(targets->size == 0) 
      commitBattleActions(:[BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:wait')),
        targets: [],
        turnIndex : 0,
        targetParts : [],
        extraData: {}
      )])
    
    commitBattleActions(:[
      BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:attack')),
        targets: [random.pickArrayItem(:targets)],
        turnIndex : 0,
        targetParts : [],
        extraData: {}
      )
    ]);
  },  
  traits : TRAIT.SPECIAL,
  passives : [
  ]
})




Species.newEntry(data:{
  name : 'Gold Slime',
  id : 'base:gold-slime',
  rarity : 2000000000000,
  description: 'Force of nature',
  growth : StatSet.new(
    HP : 6,
    AP : 5,
    ATK: 3,
    DEF: 4,
    INT: 7,
    LUK: 1,
    SPD: 7,
    DEX: 20
  ),
  qualities : [
  ],
  swarms : true,
  canBlock : false,
  overrideBattleAI ::(entity, battle, commitBattleActions) {
    @:Entity = import(module:'game_class.entity.mt');  
    
    when(random.try(percentSuccess:10)) ::<= {
      windowEvent.queueMessage(text:'The gold slime melted into a puddle and ran away!');
      commitBattleActions(:[BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:see-ya')),
        targets: [],
        turnIndex : 0,
        targetParts : [],
        extraData: {}
      )])
    }      
    
    
    @:targets = battle.getEnemies(:entity);
  
    when(targets->size == 0) 
      commitBattleActions(:[BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:wait')),
        targets: [],
        turnIndex : 0,
        targetParts : [],
        extraData: {}
      )])


    when((entity.ap >= 2) && random.try(percentSuccess:30))
      commitBattleActions(:[BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:flash')),
        targets: [...targets],
        turnIndex : 0,
        targetParts : [],
        extraData: {}
      )])

    
    commitBattleActions(:[
      BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:attack')),
        targets: [random.pickArrayItem(:targets)],
        turnIndex : 0,
        targetParts : [],
        extraData: {}
      )
    ]);
  },  
  traits : TRAIT.SPECIAL,
  passives : [
    'base:metal-body'
  ]
})



Species.newEntry(data:{
  name : 'Treasure Golem',
  id : 'base:treasure-golem',
  rarity : 2000000000000,
  description: 'Looks like a chest! Not as friendly though.',
  growth : StatSet.new(
    HP : 6,
    AP : 10,
    ATK: 4,
    DEF: 10,
    INT: 10,
    LUK: 0,
    SPD: 10,
    DEX: 10
  ),
  qualities : [
  ],
  swarms : true,
  canBlock : false,
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Cave Bat',
  id : 'base:cave-bat',
  rarity : 2000000000000,
  description: 'Large, wild bat.',
  growth : StatSet.new(
    HP : 6,
    AP : 1,
    ATK: 1,
    DEF: 1,
    INT: 1,
    LUK: 1,
    SPD: 1,
    DEX: 1
  ),
  qualities : [
  ],
  swarms : true,
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL,
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL | TRAIT.SUMMON,
  canBlock : false,
  passives : [
  ]
})


Species.newEntry(data:{
  name : 'Banished Beast',
  id : 'base:banished-beast',
  rarity : 2000000000000,
  description: 'A creature from the banished realm.',
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
  overrideBattleAI : empty,
  
  traits : TRAIT.SPECIAL | TRAIT.SUMMON,
  canBlock : false,
  passives : [
    'base:banishing-touch'
  ]
})
}


@:Species = class(
  inherits: [Database],
  define::(this) {
    this.interface = {    
      TRAIT : {get::<- TRAIT},
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
    canBlock : Boolean,
    overrideBattleAI : Nullable
  },
  reset 
);

return Species;
