@:WyvernGate = import(:'wyvern-gate.mt');

@:Profession = WyvernGate.Entity.Profession
@:windowEvent = WyvernGate.Core.WindowEvent
@:StatSet = WyvernGate.Util.StatSet

return ::{
  Profession.newEntry(data:{
    name: 'Wyvern of Fire',
    traits: Profession.TRAIT.NON_COMBAT,
    id:'thechosen:wyvern-of-fire',
    weaponAffinity: 'base:none',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
      HP:  20,
      AP:  20,
      ATK: 20,
      INT: 20,
      DEF: 20,
      SPD: 20,
      LUK: 20,
      DEX: 20
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
      'base:triplestrike',
      'base:backdraft',
      'base:big-swing',
      'base:stun',
      'base:fire',
      'base:wild-swing',
      'base:summon-fire-sprite',
      'base:vulnerability-fire'
    ],
    passives : [
    ]
  })

  Profession.newEntry(data:{
    name: 'Wyvern of Ice',
    id : 'thechosen:wyvern-of-ice',
    traits: Profession.TRAIT.NON_COMBAT,
    weaponAffinity: 'base:none',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
      HP:  20,
      AP:  20,
      ATK: 20,
      INT: 20,
      DEF: 20,
      SPD: 20,
      LUK: 20,
      DEX: 20
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
      'base:frozen-flame',
      'base:summon-ice-elemental',
      'base:ice',
      //'Magic Mist', // remove all effects
      'base:wild-swing',
      'base:sheer-cold',
      'base:vulnerability-ice'
    ],
    passives : [
    ]
  })      


  Profession.newEntry(data:{
    name: 'Wyvern of Thunder',
    id : 'thechosen:wyvern-of-thunder',
    traits: Profession.TRAIT.NON_COMBAT,
    weaponAffinity: 'base:none',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
      HP:  20,
      AP:  20,
      ATK: 20,
      INT: 20,
      DEF: 20,
      SPD: 20,
      LUK: 20,
      DEX: 20
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
      'base:thunder',
      'base:summon-thunder-spawn',
      //'Magic Mist', // remove all effects
      'base:wild-swing',
      'base:triplestrike',
      'base:leg-sweep',
      'base:summon-defensive-pylon',
      'base:flash',
      'base:unarm',
      'base:vulnerability-thunder'
    ],
    passives : [
    ]
  })     

  Profession.newEntry(data:{
    name: 'Wyvern of Light',
    id : 'thechosen:wyvern-of-light',
    weaponAffinity: 'base:none',
    traits: Profession.TRAIT.NON_COMBAT,
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
      HP:  20,
      AP:  20,
      ATK: 20,
      INT: 20,
      DEF: 20,
      SPD: 20,
      LUK: 20,
      DEX: 20
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
      'base:explosion',
      'base:flare',
      'base:headhunter',
      'base:sunburst',
      'base:sol-attunement',
      'base:cure',
      'base:summon-guiding-light',
      //'Magic Mist', // remove all effects
      'base:wild-swing',
      'base:triplestrike',
      'base:leg-sweep',
      'base:flash',
      'base:unarm',
      'base:vulnerability-light'
    ],
    passives : [
    ]
  }) 
}    
