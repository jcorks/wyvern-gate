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
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:random = import(module:'game_singleton.random.mt');
@:Arts = import(:'game_database.arts.mt');
@:ArtsDeck = import(:'game_class.artsdeck.mt');

@:CONDITION_CHANCES = [
  10,
  33,
  60,
  80,
  95
];

@:CONDITION_CHANCE_NAMES = [
  'rarely',
  'sometimes',
  'often',
  'very often',
  'almost always'
];






@:reset ::{

@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

// The art is special. All itemenchants have a flat 15% chance to arts.
ItemEnchant.database.newEntry(
  data : {
    name : 'Art',
    id : 'base:art',
    description : ', will $1 perform the Art "$2": $3',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 1000,
    tier : 0,
    
    triggerConditionEffects : [
      'placeholderart',
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)
/*
ItemEnchant.database.newEntry(
  data : {
    name : 'Evade',
    id : 'base:evade',
    description : ', will $1 allow the wielder to evade attacks the next turn.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 350,
    tier : 1,
    
    triggerConditionEffects : [
      'base:trigger-evade' // 100% next turn
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)



ItemEnchant.database.newEntry(
  data : {
    name : 'Regen',
    id : 'base:regen',
    description : ', will $1 slightly recover the users wounds.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 350,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-regen'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)*/

ItemEnchant.database.newEntry(
  data : {
    name : 'Chance to Break',
    id : 'base:chance-to-break',
    description : ', will $1 break.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: -1000,
    tier : 1,
    
    triggerConditionEffects : [
      'base:trigger-break-chance'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Chance to Hurt',
    id : 'base:chance-to-hurt',
    description : ', will $1 hurt the wielder.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: -200,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-hurt-chance'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Chance to Fatigue',
    id : 'base:chance-to-fatigue',
    description : ', will $1 fatigue the wielder.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: -200,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-fatigue-chance'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)

/*
ItemEnchant.database.newEntry(
  data : {
    name : 'Spikes',
    id : 'base:spikes',
    description : ', will $1 cast a spell that damages an enemy when attacked for a few turns.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 350,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-spikes'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Ensnare',
    description : ', will $1 cast a spell to cause the wielder and the attacker to get ensnared.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 350,
    tier : 1,
    
    triggerConditionEffects : [
      'Trigger Ensnare'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)
*/

/*
ItemEnchant.database.newEntry(
  data : {
    name : 'Ease',
    id : 'base:ease',
    description : ', will $1 recover from mental fatigue.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 350,
    tier : 1,
    
    triggerConditionEffects : [
      'base:trigger-ap-regen'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Shield',
    id : 'base:shield',
    description : ', will $1 cast Shield for a while, which may block attacks.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 250,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-shield' 
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Boost Strength',
    id : 'base:boost-strength',
    description : ', will $1 boost the wielder\'s power for a while.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 250,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-strength-boost'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Boost Defense',
    id : 'base:boost-defense',
    description : ', will $1 boost the wielder\'s defense for a while.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 250,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-defense-boost'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Boost Mind',
    id : 'base:boost-mind',
    description : ', will $1 boost the wielder\'s mental acquity for a while.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 250,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-mind-boost'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Boost Dex',
    id : 'base:boost-dex',
    description : ', will $1 boost the wielder\'s dexterity for a while.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 250,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-dex-boost'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Boost Speed',
    id : 'base:boost-speed',
    description : ', will $1 boost the wielder\'s speed for a while.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 250,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-speed-boost'
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)
*/


ItemEnchant.database.newEntry(
  data : {
    name : 'Burning',
    id : 'base:burning',
    description : 'The material its made of is warm to the touch. Grants a fire aspect to attacks and gives ice resistance when used as armor.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 1,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:burning"
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Icy',
    id : 'base:icy',
    description : 'The material its made of is cold to the touch. Grants an ice aspect to attacks and gives fire resistance when used as armor.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 1,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:icy"
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Shock',
    id : 'base:shock',
    description : 'The material its made of gently hums. Grants a thunder aspect to attacks and gives thunder resistance when used as armor.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 1,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:shock"
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Toxic',
    id : 'base:toxic',
    description : 'The material its made has been made poisonous. Grants a poison aspect to attacks and gives poison resistance when used as armor.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 1,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:toxic"
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Shimmering',
    id : 'base:shimmering',
    description : 'The material its made of glows softly. Grants a light aspect to attacks and gives dark resistance when used as armor.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 1,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:shimmering"
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Dark',
    id : 'base:dark',
    description : 'The material its made of is very dark. Grants a dark aspect to attacks and gives light resistance when used as armor.',
    equipMod : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 1,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:dark"
    ],
    
    useEffects : []
  }
)



ItemEnchant.database.newEntry(
  data : {
    name : 'Rune: Power',
    id : 'base:rune-power',
    description : 'Imbued with a potent rune of power.',
    equipMod : StatSet.new(
      ATK: 150,
      DEX: -10,
      SPD: -10,
      DEF: -10,
      INT: -10          
    ),
    levelMinimum : 1,
    priceMod: 20000,
    tier : 3,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Rune: Shield',
    id : 'base:rune-shield',
    description : 'Imbued with a potent rune of shielding.',
    equipMod : StatSet.new(
      DEF: 150,
      DEX: -10,
      ATK: -10,
      SPD: -10,
      INT: -10          
    ),
    levelMinimum : 1,
    priceMod: 20000,
    tier : 3,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)    

ItemEnchant.database.newEntry(
  data : {
    name : 'Rune: Reflex',
    id : 'base:rune-reflex',
    description : 'Imbued with a potent rune of reflex.',
    equipMod : StatSet.new(
      DEX: 150,
      DEF: -10,
      ATK: -10,
      SPD: -10,
      INT: -10          
    ),
    levelMinimum : 1,
    priceMod: 20000,
    tier : 3,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
) 

ItemEnchant.database.newEntry(
  data : {
    name : 'Rune: Speed',
    id : 'base:rune-speed',
    description : 'Imbued with a potent rune of speed.',
    equipMod : StatSet.new(
      SPD: 150,
      DEF: -10,
      ATK: -10,
      DEX: -10,
      INT: -10          
    ),
    levelMinimum : 1,
    priceMod: 20000,
    tier : 3,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Rune: Mind',
    id : 'base:rune-mind',
    description : 'Imbued with a potent rune of mind.',
    equipMod : StatSet.new(
      INT: 150,
      DEF: -10,
      ATK: -10,
      DEX: -10,
      SPD: -10          
    ),
    levelMinimum : 1,
    priceMod: 20000,
    tier : 3,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)




ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Teal Crystal',
    id : 'base:inlet-teal-crystal',
    description : 'Set with a simple, enchanted teal crystal of alchemical origin, which alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 15,
      DEX: 15,
      ATK: -5,
      DEF: -5,
      INT: -5
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Lavender Crystal',
    id : 'base:inlet-lavender-crystal',
    description : 'Set with a simple, enchanted lavender crystal of alchemical origin, which alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -5,
      DEX: 15,
      ATK: 15,
      DEF: -5,
      INT: -5
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Orange Crystal',
    id : 'base:inlet-orange-crystal',
    description : 'Set with a simple, enchanted orange crystal of alchemical origin, which alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -5,
      DEX: -5,
      ATK: 15,
      DEF: 15,
      INT: -5
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Indigo Crystal',
    id : 'base:inlet-indigo-crystal',
    description : 'Set with a simple, enchanted indigo crystal of alchemical origin, which alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -5,
      DEX: -5,
      ATK: -5,
      DEF: 15,
      INT: 15
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Rose Crystal',
    id : 'base:inlet-rose-crystal',
    description : 'Set with a simple, enchanted rose crystal of alchemical origin, which alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 15,
      DEX: -5,
      ATK: -5,
      DEF: -5,
      INT: 15
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Cyan Crystal',
    id : 'base:inlet-cyan-crystal',
    description : 'Set with a simple, enchanted cyan crystal of alchemical origin, which alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 15,
      DEX: -5,
      ATK: 15,
      DEF: -5,
      INT: -5
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: White Crystal',
    id : 'base:inlet-white-crystal',
    description : 'Set with a simple, enchanted white crystal of alchemical origin, which alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 15,
      DEX: -5,
      ATK: -5,
      DEF: 15,
      INT: -5
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Violet Crystal',
    id : 'base:inlet-violet-crystal',
    description : 'Set with a simple, enchanted violet crystal of alchemical origin, which alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -5,
      DEX: 15,
      ATK: -5,
      DEF: 15,
      INT: -5
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Scarlet Crystal',
    id : 'base:inlet-scarlet-crystal',
    description : 'Set with a simple, enchanted scarlet crystal of alchemical origin, which alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -5,
      DEX: 15,
      ATK: -5,
      DEF: -5,
      INT: 15
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Maroon Crystal',
    id : 'base:inlet-maroon-crystal',
    description : 'Set with a simple, enchanted maroon crystal of alchemical origin, which alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 15,
      DEX: -5,
      ATK: 15,
      DEF: -5,
      INT: -5
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Crimson Crystal',
    id : 'base:inlet-crimson-crystal',
    description : 'Set with a simple, enchanted crimson crystal of alchemical origin, which alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -5,
      DEX: -5,
      ATK: 15,
      DEF: -5,
      INT: 15
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)













ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Morion',
    id : 'base:inlet-morion',
    description : 'Set with an enchanted morion stone, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 50,
      DEX: 50,
      ATK: -25,
      DEF: -25,
      INT: -25
    ),
    priceMod: 1200,
    tier : 2,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Amethyst',
    id : 'base:inlet-amethyst',
    description : 'Set with an enchanted amethyst, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -25,
      DEX: 50,
      ATK: 50,
      DEF: -25,
      INT: -25
    ),
    priceMod: 1200,
    tier : 2,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Citrine',
    id : 'base:inlet-citrine',
    description : 'Set with an enchanted citrine stone, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -25,
      DEX: -25,
      ATK: 50,
      DEF: 50,
      INT: -25
    ),
    priceMod: 1200,
    tier : 2,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Garnet',
    id : 'base:inlet-garnet',
    description : 'Set with an enchanted garnet stone, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -25,
      DEX: -25,
      ATK: -25,
      DEF: 50,
      INT: 50
    ),
    priceMod: 1200,
    tier : 2,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Praesolite',
    id : 'base:inlet-praesolite',
    description : 'Set with an enchanted praesolite stone, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 50,
      DEX: -25,
      ATK: -25,
      DEF: -25,
      INT: 50
    ),
    priceMod: 1200,
    tier : 2,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Aquamarine',
    id : 'base:inlet-aquamarine',
    description : 'Set with an enchanted aquamarine stone, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 50,
      DEX: -25,
      ATK: 50,
      DEF: -25,
      INT: -25
    ),
    priceMod: 1200,
    tier : 2,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Diamond',
    id : 'base:inlet-diamond',
    description : 'Set with an enchanted diamond stone, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 50,
      DEX: -25,
      ATK: -25,
      DEF: 50,
      INT: -25
    ),
    priceMod: 1200,
    tier : 2,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Pearl',
    id : 'base:inlet-pearl',
    description : 'Set with an enchanted pearl, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -25,
      DEX: 50,
      ATK: -25,
      DEF: 50,
      INT: -25
    ),
    priceMod: 1200,
    tier : 2,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Ruby',
    id : 'base:inlet-ruby',
    description : 'Set with an enchanted ruby, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -25,
      DEX: 50,
      ATK: -25,
      DEF: -25,
      INT: 50
    ),
    priceMod: 1200,
    tier : 2,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Sapphire',
    id : 'base:inlet-sapphire',
    description : 'Set with an enchanted sapphire, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 50,
      DEX: -25,
      ATK: 50,
      DEF: -25,
      INT: -25
    ),
    priceMod: 1200,
    tier : 2,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Opal',
    id : 'base:inlet-opal',
    description : 'Set with an enchanted opal stone, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: -25,
      DEX: -25,
      ATK: 50,
      DEF: -25,
      INT: 50
    ),
    priceMod: 1200,
    tier : 2,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Cursed',
    id : 'base:cursed',
    description : 'Somehow, cursed magicks have seeped into this, which greatly alters the stats of the item.',
    equipMod : StatSet.new(
      DEF: -70,
      ATK: -70,
      INT: 150,
      DEX: 80
    ),
    levelMinimum : 5,
    priceMod: 300,
    tier : 1,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
    ],
    
    useEffects : []
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Bloodstone',
    id : 'base:inlet-bloodstone',
    description : 'Set with a large bloodstone, shining sinisterly. This greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 30,
      DEX: 30,
      ATK: 30,
      DEF: 30,
      INT: 30,
      HP: -5
    ),
    priceMod: 2000,
    tier : 3,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Soulstone',
    id : 'base:inlet-soulstone',
    description : 'Set with a large soulstone, shining sinisterly. This greatly alters the stats of the item.',
    equipMod : StatSet.new(
      SPD: 30,
      DEX: 30,
      ATK: 30,
      DEF: 30,
      INT: 30,
      AP: -10
    ),
    priceMod: 2000,
    tier : 3,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Green',
    id : 'base:aura-green',
    description : 'Imbued with a stamina aura; it softly glows green.',
    equipMod : StatSet.new(
      SPD: -15,
      HP:  20
    ),
    priceMod: 200,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Red',
    id : 'base:aura-red',
    description : 'Imbued with a stamina aura; it softly glows red.',
    equipMod : StatSet.new(
      ATK: -15,
      HP:  20
    ),
    priceMod: 200,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Blue',
    id : 'base:aura-blue',
    description : 'Imbued with a stamina aura; it softly glows blue with a glimmer.',
    equipMod : StatSet.new(
      DEF: -15,
      HP:  20
    ),
    priceMod: 400,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Yellow',
    id : 'base:aura-yellow',
    description : 'Imbued with a stamina aura; it softly glows yellow.',
    equipMod : StatSet.new(
      INT: -15,
      HP:  20
    ),
    priceMod: 200,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Orange',
    id : 'base:aura-orange',
    description : 'Imbued with a stamina aura; it softly glows orange.',
    equipMod : StatSet.new(
      DEX: -15,
      HP:  20
    ),
    priceMod: 200,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Silver',
    id : 'base:aura-silver',
    description : 'Imbued with a stamina aura; it softly glows silver.',
    equipMod : StatSet.new(
      AP: -15,
      HP:  20
    ),
    priceMod: 200,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Gold',
    id : 'base:aura-gold',
    description : 'Imbued with a stamina aura; it softly glows gold.',
    equipMod : StatSet.new(
      AP:  35,
      HP:  35
    ),
    priceMod: 1000,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : []
  }
)
}


@:ItemEnchant = databaseItemMutatorClass.create(
  name : 'Wyvern.ItemEnchant',
  items : {
    condition : empty,
    conditionChance : 0,
    conditionChanceName  : '',
    artID : ''
  },

  database: Database.new(
    name : 'Wyvern.ItemEnchant.Base',
    attributes : {
      name : String,
      id : String,
      description : String,
      levelMinimum : Number,
      equipMod : StatSet.type, // percentages
      useEffects : Object,
      equipEffects : Object,
      triggerConditionEffects : Object,
      priceMod : Number,
      tier : Number
    },
    reset
  ),

  define:::(this, state) {
    @:ItemEnchantCondition = import(module:'game_database.itemenchantcondition.mt');

    this.interface = {
      initialize::{},
      defaultLoad ::(base, conditionHint) {
        state.base = base;
        
        if (base.id == 'base:art') ::<= {
          state.artID = Arts.getRandomFiltered(::(value) <- 
            (value.traits & Arts.TRAITS.SUPPORT) != 0 &&
            (value.kind != Arts.KIND.REACTION) &&
            (value.traits & Arts.TRAITS.SPECIAL) == 0
          ).id;   
        }
        
        if (base.triggerConditionEffects->keycount > 0) ::<= {
          if (conditionHint != empty) ::<= {
            state.condition = ItemEnchantCondition.find(id:conditionHint);
          } else ::<= {
            state.condition = ItemEnchantCondition.getRandom();
          }
          @conditionIndex = random.pickArrayItem(list:CONDITION_CHANCES->keys);
          state.conditionChance = CONDITION_CHANCES[conditionIndex];
          state.conditionChanceName = CONDITION_CHANCE_NAMES[conditionIndex];
        }
        return this;
      },
      
      art : {
        get ::<- state.artID
      },
      

      description : {
        get ::{
          when(state.condition == empty) state.base.description;
          @out = state.condition.description + (state.base.description)->replace(key:'$1', with: state.conditionChanceName);
          when (state.artID == '') out;
          out = out->replace(key:'$2', with: Arts.find(id:state.artID).name);
          return out->replace(key:'$3', with: Arts.find(id:state.artID).description);          
        }
      },
      
      name : {
        get ::{
          when(state.condition == empty) state.base.name;
          breakpoint();
          return state.condition.name + ': ' + state.base.name;
        }
      },
      
      processEvent ::(*args) {
        @:world = import(module:'game_singleton.world.mt');
        when(state.condition == empty) empty;
        if (state.condition.effectEvent == args.name) ::<= {
          when(!random.try(percentSuccess:state.conditionChance)) empty;
          if (state.artID != '') ::<= {
            foreach(state.base.triggerConditionEffects)::(i, effectName) {
              args.holder.addEffect(
                from:args.holder, id: effectName, durationTurns: 1, item:args.item
              );            
            }
          } else ::<= {
            when(args.holder.battle == empty) empty;

            @:battle = args.holder.battle;

            if (world.party.isMember(:args.holder)) ::<= {
              args.holder.playerUseArt(
                commitAction ::(action) {
                  battle.entityCommitAction(action:action);                
                },
                card:ArtsDeck.synthesizeHandCard(id:state.artID),
                allies : args.holder.battle.getAllies(entity:args.holder.user),
                enemies : args.holder.battle.getEnemies(entity:args.holder.user),
                onCancel :: {
                  
                }
              );
            } else ::<= {
              args.holder.battleAI.commitTargettedAction(
                battle,
                card: ArtsDeck.synthesizeHandCard(id: state.artID),
                allies : args.holder.battle.getAllies(entity:args.holder.user),
                enemies : args.holder.battle.getEnemies(entity:args.holder.user)
              );
            }
          }
        }
      }
    }
  }

);

return ItemEnchant;
