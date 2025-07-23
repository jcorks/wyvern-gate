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

@:TRAIT = {
    SPECIAL : 1
}




@:reset ::{

@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

// The art is special. All itemenchants have a flat 15% chance to arts.
ItemEnchant.database.newEntry(
  data : {
    name : 'Art',
    id : 'base:art',
    description : ', will $1 add the Art "$2" to the wielder\'s hand: $3',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 1000,
    tier : 10,
    
    triggerConditionEffects : [
      'base:trigger-itemart',
    ],
    
    equipEffects : [
    ],
    
    useEffects : [],
    traits : TRAIT.SPECIAL,
    onCreate ::(this){}
  }
)
/*
ItemEnchant.database.newEntry(
  data : {
    name : 'Evade',
    id : 'base:evade',
    description : ', will $1 allow the wielder to evade attacks the next turn.',
    equipModBase : StatSet.new(
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
*/



ItemEnchant.database.newEntry(
  data : {
    name : 'Regen',
    id : 'base:regen',
    description : ', will $1 slightly recover the users wounds.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 350,
    tier : 0,
    traits: 0,
    
    triggerConditionEffects : [
      'base:trigger-regen'
    ],
    
    equipEffects : [
    ],
    
    useEffects : [],
    onCreate ::(this){}
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Break',
    id : 'base:chance-to-break',
    description : ', will $1 break.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: -1000,
    tier : 4,
    
    triggerConditionEffects : [
      'base:trigger-break-chance'
    ],
    
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Ailment',
    id : 'base:chance-to-inflict-ailment',
    description : ', will $1 give the holder a random status ailment.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: -1000,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-random-ailment'
    ],
    
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)



ItemEnchant.database.newEntry(
  data : {
    name : 'Hurt',
    id : 'base:chance-to-hurt',
    description : ', will $1 hurt the wielder.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: -200,
    tier : 1,
    
    triggerConditionEffects : [
      'base:trigger-hurt-chance'
    ],
    
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Fatigue',
    id : 'base:chance-to-fatigue',
    description : ', will $1 fatigue the wielder.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: -200,
    tier : 1,
    
    triggerConditionEffects : [
      'base:trigger-fatigue-chance'
    ],
    
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 1,
    onCreate ::(this){}
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Spikes',
    id : 'base:spikes',
    description : ', will $1 cast a spell that damages an enemy when attacked for a few turns.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 350,
    tier : 0,
    
    triggerConditionEffects : [
      'base:trigger-spikes'
    ],
    
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)

/*
ItemEnchant.database.newEntry(
  data : {
    name : 'Ensnare',
    description : ', will $1 cast a spell to cause the wielder and the attacker to get ensnared.',
    equipModBase : StatSet.new(
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


ItemEnchant.database.newEntry(
  data : {
    name : 'Ease',
    id : 'base:ease',
    description : ', will $1 recover from mental fatigue.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 350,
    tier : 0,
    traits: 0,
    
    triggerConditionEffects : [
      'base:trigger-ap-regen'
    ],
    
    equipEffects : [
    ],
    
    useEffects : [],
    onCreate ::(this){}
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Shield',
    id : 'base:shield',
    description : ', will $1 cast Shield for a while, which may block attacks.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 250,
    tier : 0,
    traits : 0,
    
    triggerConditionEffects : [
      'base:trigger-shield' 
    ],
    
    equipEffects : [
    ],
    
    useEffects : [],
    onCreate ::(this){}
  }
)

/*
ItemEnchant.database.newEntry(
  data : {
    name : 'Boost Strength',
    id : 'base:boost-strength',
    description : ', will $1 boost the wielder\'s power for a while.',
    equipModBase : StatSet.new(
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
    equipModBase : StatSet.new(
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
    equipModBase : StatSet.new(
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
    equipModBase : StatSet.new(
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
    equipModBase : StatSet.new(
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
    name : 'Sharp',
    id : 'base:sharp',
    description : 'Has a chance of causing bleed on a target when attacking.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 0,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:sharp"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)



ItemEnchant.database.newEntry(
  data : {
    name : 'Burning',
    id : 'base:burning',
    description : 'The material its made of is warm to the touch. Grants a fire aspect to attacks and gives ice resistance when used as armor.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 0,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:burning"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Scorching',
    id : 'base:scorching',
    description : 'Has a chance of causing burns on a target when attacking.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 0,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:scorching"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Icy',
    id : 'base:icy',
    description : 'The material its made of is cold to the touch. Grants an ice aspect to attacks and gives fire resistance when used as armor.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 0,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:icy"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Freezing',
    id : 'base:freezing',
    description : 'Has a chance of freezing targets when attacking.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 0,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:freezing"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Shock',
    id : 'base:shock',
    description : 'The material its made of gently hums. Grants a thunder aspect to attacks and gives thunder resistance when used as armor.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 0,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:shock"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Paralyzing',
    id : 'base:paralyzing',
    description : 'Has a chance of causing paralysis to targets when attacking.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 3,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:paralyzing"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Toxic',
    id : 'base:toxic',
    description : 'The material its made has been made poisonous. Grants a poison aspect to attacks and gives poison resistance when used as armor.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 0,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:toxic"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Seeping',
    id : 'base:seeping',
    description : 'Has a chance of poisoning targets when attacking.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 1,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:seeping"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Shimmering',
    id : 'base:shimmering',
    description : 'The material its made of glows softly. Grants a light aspect to attacks and gives dark resistance when used as armor.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 2,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:shimmering"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Petrifying',
    id : 'base:petrifying',
    description : 'Has a chance of causing petrification to targets when attacking.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 4,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:petrifying"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Dark',
    id : 'base:dark',
    description : 'The material its made of is very dark. Grants a dark aspect to attacks and gives light resistance when used as armor.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 1,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:dark"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Blinding',
    id : 'base:blinding',
    description : 'Has a chance of causing blindness to targets when attacking.',
    equipModBase : StatSet.new(
    ),
    levelMinimum : 1,
    priceMod: 200,
    tier : 3,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
      "base:blinding"
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){}
  }
)


@:stats = {
  'Power' : 'ATK',
  'Shield' : 'DEF',
  'Reflex' : 'DEX',
  'Speed' : 'SPD',
  'Mind' : 'INT',
  
}


ItemEnchant.database.newEntry(
  data : {
    name : 'Rune',
    id : 'base:rune',
    description : '',
    equipModBase : StatSet.new(
    
    ),
    levelMinimum : 1,
    priceMod: 20000,
    tier : 3,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){
      @:kind = random.pickArrayItem(:stats->values);
      
      @:statsA = {
        ATK: -1,
        DEX: -1,
        SPD: -1,
        DEF: -1,
        INT: -1      
      }
      statsA[kind] = 7;
      @desc = 'Powerful rune. ';
      foreach(statsA) ::(k, v) {
        when (k == kind) empty;
        desc = desc + k + ',';
      }      
      desc = desc + ' base -1, ' + kind + ' base +7';
      this.description = desc;
      this.name = 'Rune of ' + kind;
      this.equipModBase.add(:StatSet.new(*statsA));
    }
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Minor Aura',
    id : 'base:minor-aura',
    description : 'Enchanted with a simple aura that boosts all traits slightly.',
    equipModBase : StatSet.new(
      HP : 1,
      AP : 1,
      SPD: 1,
      DEX: 1,
      ATK: 1,
      DEF: 1,
      INT: 1
    ),
    priceMod: 140,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){
    }
  }
)












ItemEnchant.database.newEntry(
  data : {
    name : 'Cursed',
    id : 'base:cursed',
    description : 'Cursed with dark magic. DEF, ATK base -3, INT, DEX base +6',
    equipModBase : StatSet.new(
      DEF: -3,
      ATK: -3,
      INT: 6,
      DEX: 6
    ),
    levelMinimum : 5,
    priceMod: 300,
    tier : 1,
    
    triggerConditionEffects : [
    ],
    
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){
    }
  }
)

/*
ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Bloodstone',
    id : 'base:inlet-bloodstone',
    description : 'Set with a large bloodstone, shining sinisterly. HP base -1, SPD, DEX, ATK, DEF, INT +2',
    equipModBase : StatSet.new(
      SPD: 2,
      DEX: 2,
      ATK: 2,
      DEF: 2,
      INT: 2,
      HP: -1
    ),
    priceMod: 2000,
    tier : 3,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Inlet: Soulstone',
    id : 'base:inlet-soulstone',
    description : 'Set with a large soulstone, shining sinisterly. AP base -1, SPD, DEX, ATK, DEF, INT +2',
    equipModBase : StatSet.new(
      SPD: 2,
      DEX: 2,
      ATK: 2,
      DEF: 2,
      INT: 2,
      AP: -1
    ),
    priceMod: 2000,
    tier : 3,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0
  }
)
*/


::<= {
ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Green',
    id : 'base:aura-green',
    description : 'Imbued with a stamina aura; it softly glows green.',
    equipModBase : StatSet.new(
      SPD: -1,
      HP:  2
    ),
    priceMod: 200,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){
    }
  }
)
}

ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Red',
    id : 'base:aura-red',
    description : 'Imbued with a stamina aura; it softly glows red.',
    equipModBase : StatSet.new(
      ATK: -1,
      HP:  2
    ),
    priceMod: 200,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){
    }
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Blue',
    id : 'base:aura-blue',
    description : 'Imbued with a stamina aura; it softly glows blue with a glimmer.',
    equipModBase : StatSet.new(
      DEF: -1,
      HP:  2
    ),
    priceMod: 400,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){
    }
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Yellow',
    id : 'base:aura-yellow',
    description : 'Imbued with a stamina aura; it softly glows yellow.',
    equipModBase : StatSet.new(
      INT: -1,
      HP:  2
    ),
    priceMod: 200,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){
    }
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Orange',
    id : 'base:aura-orange',
    description : 'Imbued with a stamina aura; it softly glows orange.',
    equipModBase : StatSet.new(
      DEX: -1,
      HP:  2
    ),
    priceMod: 200,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){
    }
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Silver',
    id : 'base:aura-silver',
    description : 'Imbued with a stamina aura; it softly glows silver.',
    equipModBase : StatSet.new(
      AP: -1,
      HP:  2
    ),
    priceMod: 200,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){
    }
  }
)


ItemEnchant.database.newEntry(
  data : {
    name : 'Aura: Gold',
    id : 'base:aura-gold',
    description : 'Imbued with a stamina aura; it softly glows gold.',
    equipModBase : StatSet.new(
      AP:  2,
      HP:  2
    ),
    priceMod: 1000,
    tier : 4,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){
    }
  }
)

ItemEnchant.database.newEntry(
  data : {
    name : 'Soul',
    id : 'base:soul',
    description : '',
    equipModBase : StatSet.new(
    ),
    priceMod: 500,
    tier : 0,
    levelMinimum : 1,
    
    triggerConditionEffects : [
    ],
    equipEffects : [
    ],
    
    useEffects : [],
    traits : 0,
    onCreate ::(this){
    }
  }
)

}


@:ItemEnchant = databaseItemMutatorClass.create(
  name : 'Wyvern.ItemEnchant',
  statics : {
    TRAIT : {get::<- TRAIT}
  },
  items : {
    name : '',
    description : '',
    condition : empty,
    conditionChance : 0,
    conditionChanceName  : '',
    artID : '',
    equipEffects : empty,
    useEffects : empty,
    equipModBase : empty,
  },

  database: Database.new(
    name : 'Wyvern.ItemEnchant.Base',
    attributes : {
      name : String,
      id : String,
      description : String,
      levelMinimum : Number,
      equipModBase : StatSet.type, // base stats
      useEffects : Object,
      equipEffects : Object,
      triggerConditionEffects : Object,
      priceMod : Number,
      tier : Number,
      traits : Number,
      onCreate : Function
    },
    reset
  ),

  define:::(this, state) {
    @:ItemEnchantCondition = import(module:'game_database.itemenchantcondition.mt');

    this.interface = {
      initialize::{},
      defaultLoad ::(base, conditionHint) {      
        state.base = base;
        state.equipEffects = [];
        state.useEffects = [];
        state.name = base.name;
        state.description = base.description;
        @:Effect = import(module:'game_database.effect.mt');
        
        if (base.id == 'base:soul') ::<= {
          @:effectID = Effect.getRandomFiltered(::(value) <- 
            value.hasNoTrait(:Effect.TRAIT.SPECIAL | Effect.TRAIT.INSTANTANEOUS | Effect.TRAIT.REVIVAL)
          ).id;
          state.equipEffects->push(:effectID);
        }
        
        if (base.id == 'base:art') ::<= {
          state.artID = Arts.getRandomFiltered(::(value) <- 
            (value.traits & Arts.TRAIT.SUPPORT) != 0 &&
            (value.kind != Arts.KIND.REACTION) &&
            (value.traits & Arts.TRAIT.SPECIAL) == 0
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
        
        foreach(base.equipEffects) ::(k, v) <- state.equipEffects->push(:v);
        foreach(base.useEffects) ::(k, v) <- state.useEffects->push(:v);
        state.equipModBase = base.equipModBase.clone();
        base.onCreate(this);
        return this;
      },
      
      equipModBase : {
        get ::<- state.equipModBase
      },
      
      
      art : {
        get ::<- state.artID
      },
      
      equipEffects : {get::<- state.equipEffects},

      useEffects : {get::<- state.useEffects},


      description : {
        get ::{
          @:Effect = import(module:'game_database.effect.mt');
          when(state.base.id == 'base:soul') 
            Effect.find(:state.equipEffects[0]).description;
            
          when(state.condition == empty) state.description;
          @out = state.condition.description + (state.base.description)->replace(key:'$1', with: state.conditionChanceName);
          when (state.artID == '') out;
          out = out->replace(key:'$2', with: Arts.find(id:state.artID).name);
          return out->replace(key:'$3', with: Arts.find(id:state.artID).description);          
        },
        
        set ::(value) {
          state.description = value;
        }
      },
      
      name : {
        get ::{
          @:Effect = import(module:'game_database.effect.mt');
          when (state.base.id == 'base:soul')
            'Soul of ' + Effect.find(:state.equipEffects[0]).name;
            
          when(state.condition == empty) state.name;
          
          return state.condition.name + ': ' + state.base.name;
        },
        
        set ::(value) {
          state.name = value;
        }
      },
      
      processEvent ::(*args) {
        @:world = import(module:'game_singleton.world.mt');
        when(state.condition == empty) empty;
        if (state.condition.effectEvent == args.name) ::<= {
          when(!random.try(percentSuccess:state.conditionChance)) empty;
          foreach(state.base.triggerConditionEffects)::(i, effectName) {
            args.holder.addEffect(
              from:args.holder, id: effectName, durationTurns: 1, item:args.item
            );
          }

          if (state.artID != '') ::<= {
            when(args.holder.battle == empty) empty;

            @:battle = args.holder.battle;

            @:card = args.holder.deck.addHandCardTemporary(
              :state.artID
            );
            args.holder.deck.revealArt(
              handCard:card, 
              prompt:'The Art ' + Arts.find(:state.artID).name + ' was added to ' + args.holder.name + '\'s hand.'
            );
            /*
            // insanity: instant casting
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
            */
          }
        }
      }
    }
  }

);

return ItemEnchant;
