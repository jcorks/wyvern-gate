@:WyvernGate = import(:'wyvern-gate.mt');

@:Scene = WyvernGate.Scene
@:ParticleEmitter = WyvernGate.Core.Graphics.Particle
@:random = WyvernGate.Core.Random
@:windowEvent = WyvernGate.Core.WindowEvent
@:StatSet = WyvernGate.Util.StatSet
@:Species = WyvernGate.Entity.Species

return ::{
  Species.newEntry(data:{
    name : 'Wyvern of Fire',
    id : 'thechosen:wyvern-of-fire',
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

    levelPenalty : 10,
    
    baseStats : StatSet.new(
      HP:   120,
      AP:   999,
      ATK:  6,
      INT:  5,
      DEF:  11,
      LUK:  8,
      SPD:  25,
      DEX:  11      
    ),
    
    qualities : [
    ],
    swarms : false,
    canBlock : true,
    
    traits : Species.TRAIT.SPECIAL | Species.TRAIT.NO_DEFAULT_EQUIPS,
    passives : [
      'base:the-wyvern'
    ]
  })
  Species.newEntry(data:{
    name : 'Wyvern of Ice',
    id : 'thechosen:wyvern-of-ice',
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
    levelPenalty : 10,
    
    baseStats: StatSet.new(
      HP:   230,
      AP:   999,
      ATK:  13,
      INT:  8,
      DEF:  7,
      LUK:  6,
      SPD:  60,
      DEX:  14      
    ),
    
    qualities : [
    ],
    swarms : false,
    canBlock : true,
    
    traits : Species.TRAIT.SPECIAL | Species.TRAIT.NO_DEFAULT_EQUIPS,
    passives : [
      'base:icy',
      'base:the-wyvern'
    ]
  })


  Species.newEntry(data:{
    name : 'Wyvern of Thunder',
    id : 'thechosen:wyvern-of-thunder',
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
    
    baseStats : StatSet.new(
      HP:   400,
      AP:   999,
      ATK:  20,
      INT:  10,
      DEF:  10,
      LUK:  9,
      SPD:  100,
      DEX:  16      
    ),
    
    levelPenalty : 10,
    qualities : [
    ],
    swarms : false,
    canBlock : true,
    
    traits : Species.TRAIT.SPECIAL,
    passives : [
      'base:shock',
      'base:the-wyvern'
    ]
  })


  Species.newEntry(data:{
    name : 'Wyvern of Light',
    id : 'thechosen:wyvern-of-light',
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
    
    baseStats : StatSet.new(
      HP:   650,
      AP:   999,
      ATK:  30,
      INT:  17,
      DEF:  3,
      LUK:  6,
      SPD:  100,
      DEX:  20      
    ),
    levelPenalty : 10,
    
    
    qualities : [
    ],
    swarms : false,
    canBlock : true,
    
    traits : Species.TRAIT.SPECIAL | Species.TRAIT.NO_DEFAULT_EQUIPS,
    passives : [
      'base:shimmering',
      'base:the-wyvern'
    ]
  })
}
