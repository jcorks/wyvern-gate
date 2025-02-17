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
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:Database = import(module:'game_class.database.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:random = import(module:'game_singleton.random.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:romanNum = import(module:'game_function.romannumerals.mt');

/*
  Items. 
  
  - All items are equippable
  - All items have an equip slot type
  - All items can have modifiers
  - All items can be used
  - All items are instances, meaning their modifiers 
    can be globally unique. Their base is a standard item 
    class

*/




@:TYPE = {
  HAND     : 0,   
  ARMOR    : 1,  
  AMULET   : 2,  
  RING     : 3,  
  TRINKET  : 4,
  TWOHANDED  : 5
}
  
@:TRAIT = {
  BLUNT         : 2 << 0,
  SHARP         : 2 << 1,
  FLAT          : 2 << 2,
  SHIELD        : 2 << 3,
  METAL         : 2 << 4,
  FRAGILE       : 2 << 5,
  WEAPON        : 2 << 6,
  RAW_METAL     : 2 << 7,
  KEY_ITEM      : 2 << 8,
  STACKABLE     : 2 << 9,
  HAS_QUALITY   : 2 << 10,
  APPAREL       : 2 << 11,
  CAN_HAVE_ENCHANTMENTS : 2 << 12, 
  CAN_HAVE_TRIGGER_ENCHANTMENTS : 2 << 13, 
  HAS_COLOR     : 2 << 14,
  HAS_SIZE      : 2 << 15,
  UNIQUE        : 2 << 16,
  MEANT_TO_BE_USED : 2 << 17,
  CAN_BE_APPRAISED : 2 << 18
}


@:USE_TARGET_HINT = {
  ONE   : 0,  
  GROUP   : 1,
  ALL   : 2,
  NONE  : 3
}

@:SIZE = {
  SMALL : 0,
  TINY : 1,
  AVERAGE : 2,
  LARGE : 3,
  BIG : 4
}

@none;


// The keys have qualifiers not normal for 
// average objects to highlight their power.
@:keyQualifiers = [
  'Mysterious',
  'Sentimental',
  'Lucid',
  'Impressive',
  'Foolish',
  'Placid',
  'Superb',
  'Remarkable',
  'Sordid',
  'Rustic',
  'Remarkable',
  'Rough',
  'Wise',
  'Faint',
  'Feeble',
  'Ethereal',
  'Romantic',
  'Belligerent',
  'Ancient',
  'Wakeful',
  'Tawdry',
  'Gruesome',
  'Shivering',
  'Obeisant',
  'Cheerful',
  'Curious',
  'Sincere',
  'Truthful',
  'Wealthy',
  'Righteous',
  'Recondite',
  'Faded',
  'Mellow',
  'Evanescent',
  'Nascent',
  'Vague',
  'Honorable',
  'Placid',
  'Elated',
  'Shivering',
  'Miscreant',
  'Abstract',
  'Wily',
  'Witty',
  'Inquisitive',
  'Ill-fated',
  'Acrid',
  'Simple',
  'Overwrought',
  'Abrupt',
  'Hypnotic',
  'Languid',
  'Bashful',
  'Knowledgeable',
  'Illustrious',
  'Perpetual',
  'Puzzling',
  'Vacuous',
  'Boorish',
  'Direful',
  'Steady',
  'Cynical',
  'Chivalrous',
  'Imminent',
  'Ceaseless',
  'Careless',
  'Ubiquitous',
  'Unending',
  'Relentless'
];




@:reset ::{

@:Inventory = import(module:'game_class.inventory.mt');
@:ItemEnchant = import(module:'game_mutator.itemenchant.mt');
@:ItemQuality = import(module:'game_database.itemquality.mt');
@:ItemColor = import(module:'game_database.itemcolor.mt');
@:ItemDesign = import(module:'game_database.itemdesign.mt');
@:Material = import(module:'game_database.material.mt');
@:ApparelMaterial = import(module:'game_database.apparelmaterial.mt');


Item.database.newEntry(
  data : {
    name : 'None',
    id : 'base:none',
    description : '',
    examine : '',
    equipType : TYPE.HAND,
    equipMod : StatSet.new(),
    weight: 0,
    rarity: 100,
    levelMinimum : 1,
    tier: 0,
    enchantLimit : 0,
    basePrice: 0,
    enchantLimit : 0,
    useTargetHint : USE_TARGET_HINT.ONE,
    useEffects : [],
    equipEffects : [],
    traits : 
      TRAIT.UNIQUE |
      TRAIT.KEY_ITEM |
      TRAIT.STACKABLE,
    blockPoints : 0,
    onCreate ::(item, creationHint) {},
    possibleArts : [],
  }
)


Item.database.newEntry(
  data : {
    name : 'Unused 7',
    id : 'base:placeholder',
    description : '',
    examine : '',
    equipType : TYPE.HAND,
    equipMod : StatSet.new(),
    weight: 0,
    rarity: 100,
    levelMinimum : 1,
    tier: 0,
    enchantLimit : 0,
    basePrice: 0,
    enchantLimit : 0,
    useTargetHint : USE_TARGET_HINT.ONE,
    useEffects : [],
    equipEffects : [],
    traits : 
      TRAIT.UNIQUE |
      TRAIT.KEY_ITEM |
      TRAIT.STACKABLE,
    blockPoints : 0,
    onCreate ::(item, creationHint) {},
    possibleArts : [],
  }
)

Item.database.newEntry(data : {
  name : "Mei\'s Bow",
  id: 'base:meis-bow',
  description: 'A neck accessory featuring an ornate bell and bow.',
  examine : '',
  equipType: TYPE.TRINKET,
  rarity : 30000,
  basePrice : 1,
  weight : 0.1,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 0,
  blockPoints : 0,
  useTargetHint : USE_TARGET_HINT.ONE,
  onCreate ::(item, creationHint) {},
  possibleArts : [],
  
  equipMod : StatSet.new(
    HP: 30,
    DEF: 50
  ),
  useEffects : [
    'base:fling',
    'base:break-item'
  ],
  equipEffects : [
  ],
  traits : 
    TRAIT.FRAGILE |
    TRAIT.APPAREL |
    TRAIT.UNIQUE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS
})

Item.database.newEntry(data : {
  name : "Life Crystal",
  id : 'base:life-crystal',
  description: 'A shimmering amulet. The metal enclosure has a $color$ tint. If death befalls the holder, has a 50% chance to revive them. It breaks in the process of revival.',
  examine : '',
  equipType: TYPE.AMULET,
  rarity : 30000,
  basePrice : 5000,
  weight : 2,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  onCreate ::(item, creationHint) {},
  possibleArts : [],
  
  blockPoints : 0,
  equipMod : StatSet.new(
    HP: 10,
    DEF: 10
  ),
  useEffects : [
    'base:fling',
    'base:break-item'
  ],
  equipEffects : [
    'base:auto-life',
  ],
  traits : 
    TRAIT.FRAGILE |
    TRAIT.METAL |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_COLOR |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.UNIQUE

})

::<= {
  @:healEffects = [
    'base:hp-recovery-all',
    'base:ap-recovery-all',
    'base:hp-recovery-half',
    'base:ap-recovery-half',
    'base:regeneration-rune',
    'base:cure-rune'
  ]
  
  @:buffEffects = [
    'base:scorching',
    'base:sharp',
    'base:burning',
    'base:icy',
    'base:freezing',
    'base:shock',
    'base:paralyzing',
    'base:toxic',
    'base:seeping',
    'base:shimmering',
    'base:petrifying',
    'base:dark',
    'base:blinding',
  ]
  
  
  @:debuffEffects = [
    'base:poisoned',
    'base:burned',
    'base:frozen',
    'base:paralyzed',
    'base:blind',
    'base:bleeding',
    'base:petrified'
  ]
  
  
  @:overridePotionNames = {
    'base:regeneration' : 'Regeneration',
    'base:cure-rune'    : 'Delayed Healing',
    'base:icy'          : 'Cold',
    'base:sharp'        : 'Bleeding',
    'base:dark'         : 'Darkness',
    
    'base:poisoned'     : 'Poison',
    'base:burned'       : 'Acid',
    'base:frozen'       : 'Frost',
    'base:paralyzed'    : 'Paralysis',
    'base:blind'        : 'Blindness',
    'base:bleeding'     : 'Hemorrhaging',
    'base:petrified'    : 'Petrification'
  
  }
  
  


  Item.database.newEntry(data : {
    name : "Potion",
    id : 'base:potion',
    description: 'Provides effects upon use. Most effects last 5 turns if they\'re not instant.',
    examine : 'Potions like these are so common that theyre often unmarked and trusted as-is. The hue of this potion is distinct.',
    equipType: TYPE.HAND,
    weight : 2,
    rarity : 100,
    basePrice: 40,
    tier: 0,
    levelMinimum : 1,
    enchantLimit : 0,
    useTargetHint : USE_TARGET_HINT.ONE,
    blockPoints : 0,
    equipMod : StatSet.new(
      SPD: -2, // itll slow you down
      DEX: -10   // its oddly shaped.
    ),
    useEffects : [
      'base:consume-item'     
    ],
    possibleArts : [],
    equipEffects : [
    ],
    traits : 
      TRAIT.FRAGILE |
      TRAIT.MEANT_TO_BE_USED
    ,
    onCreate ::(item, creationHint) {
      @:Effect = import(module:'game_database.effect.mt');
      @kind = if (creationHint->type == Number)
        creationHint 
      else
        random.pickArrayItem(:[0, 1, 2]);
        
        
      @:supply = ::(which)<-
        match(which) {
          (0): random.pickArrayItem(:healEffects),
          (1):random.pickArrayItem(:buffEffects),
          (2):random.pickArrayItem(:debuffEffects)
        }
      ;
      
      ::<= { 
        // rare potion   
        when (random.try(percentSuccess:10) && creationHint->type != Number) ::<= {
          item.name = random.pickArrayItem(:keyQualifiers) + ' Potion';
        
          // FULL random
          when(random.flipCoin()) ::<= {
            @:rollRandom = ::<- supply(:random.integer(from:0, to:2));
            
            for(0, random.integer(from:2, to:6)) ::(i) {
              item.useEffects->push(:rollRandom());
            }
          }
          
          
          // fortified random
          for(0, random.integer(from:2, to:3)) ::(i) {
            item.useEffects->push(:supply(:kind));
          }
        }
        
        // normal potion
        @:eff = supply(:kind);
        item.name = 'Potion of ' + (if (overridePotionNames[eff] != empty) 
            overridePotionNames[eff] 
          else 
            Effect.find(:eff).name
        );
        item.useEffects->push(:eff);
      }
      item.price += item.base.basePrice * item.useEffects->size;
    }

  })
}


Item.database.newEntry(data : {
  name : "Essence",
  id : 'base:essence',
  description: 'Provides an effect upon use. Most effects last 3 turns if they\'re not instant.',
  examine : 'Potions like these are so common that theyre often unmarked and trusted as-is. The hue of this potion is distinct.',
  equipType: TYPE.HAND,
  weight : 2,
  rarity : 100,
  basePrice: 200,
  tier: 2,
  levelMinimum : 1,
  enchantLimit : 0,
  useTargetHint : USE_TARGET_HINT.ONE,
  blockPoints : 0,
  equipMod : StatSet.new(
    SPD: -2, // itll slow you down
    DEX: -10   // its oddly shaped.
  ),
  useEffects : [
    'base:consume-item'     
  ],
  possibleArts : [],
  equipEffects : [
  ],
  traits : 
    TRAIT.FRAGILE |
    TRAIT.MEANT_TO_BE_USED
  ,
  onCreate ::(item, creationHint) {
    @:Effect = import(module:'game_database.effect.mt');
    @:effect = Effect.getRandomFiltered(::(value) <- value.hasNoTrait(:Effect.TRAIT.INSTANTANEOUS | Effect.TRAIT.SPECIAL));
    item.name = 'Essence of ' + effect.name;
    item.useEffects->push(:effect.id);
  }

})



Item.database.newEntry(data : {
  name : "Scroll",
  id : 'base:scroll',
  description: 'An enchanted parchment that casts an offensive, basic spell upon use. Only usable in battle.',
  examine : '',
  equipType: TYPE.HAND,
  weight : 1,
  rarity : 100,
  basePrice: 1050,
  tier: 0,
  levelMinimum : 1,
  enchantLimit : 0,
  useTargetHint : USE_TARGET_HINT.ONE,
  blockPoints : 0,
  equipMod : StatSet.new(
  ),
  useEffects : [
    'base:cast-spell',
    'base:consume-item'     
  ],
  possibleArts : [],
  equipEffects : [
  ],
  traits : 
    TRAIT.FRAGILE |
    TRAIT.MEANT_TO_BE_USED
  ,
  onCreate ::(item, creationHint) {
    @:Arts = import(module:'game_database.arts.mt');
    @:art = Arts.getRandomFiltered(::(value) <- value.hasTraits(:Arts.TRAITS.COMMON_ATTACK_SPELL));
    item.data.spell = art.id;
    item.name = 'Scroll of ' + art.name;
  }

})










/*
Item.database.newEntry(data : {
  name : "Pinkish Potion",
  description: 'Pink-colored potions are known to be for recovery of injuries',
  examine : 'This potion does not have the same hue as the common recovery potion and is a bit heavier. Did you get it from a reliable source?',
  equipType: TYPE.HAND,
  rarity : 600,
  weight : 2,
  basePrice: 20,
  canBeColored : false,
  hasMaterial : false,
  isApparel : false,
  levelMinimum : 1,
  keyItem : false,
  hasSize : false,
  tier: 0,
  isUnique : false,
  canHaveEnchants : false,
  canHaveTriggerEnchants : false,
  enchantLimit : 0,
  hasQuality : false,
  possibleArts : [],
  useTargetHint : USE_TARGET_HINT.ONE,
  equipMod : StatSet.new(
    SPD: -2, // itll slow you down
    DEX: -10   // its oddly shaped.
  ),
  useEffects : [
    'HP Recovery: Iffy',
    'base:consume-item'     
  ],
  equipEffects : [
  ],
  traits : 
    TRAIT.FRAGILE
  ,
  onCreate ::(item, creationHint) {}


})
*/



Item.database.newEntry(data : {
  name : "Pitchfork",
  id : 'base:pitchfork',
  description: 'A common farming implement.',
  examine : 'Quite sturdy and pointy, some people use these as weapons.',
  equipType: TYPE.HAND,
  rarity : 100,
  basePrice: 10,    
  tier: 0,
  weight : 4,
  levelMinimum : 1,
  enchantLimit : 0,
  possibleArts : [
    'base:stab'
  ],
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
  blockPoints : 2,
  equipMod : StatSet.new(
    ATK: 15,
    DEF: 20
  ),
  useEffects : [
    'base:fling',
    'base:break-item'
  ],
  equipEffects : [
    'base:non-combat-weapon' // high chance to deflect, but when it deflects, the weapon breaks
    
  ],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE
  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Shovel",
  id : 'base:shovel',
  description: 'A common farming implement.',
  examine : 'Quite sturdy and pointy, some people use these as weapons.',
  equipType: TYPE.HAND,
  basePrice: 13,
  rarity : 100,
  tier: 0,
  weight : 4,
  levelMinimum : 1,
  enchantLimit : 0,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 20,
    DEF: 10,
    SPD: -10,
    DEX: -10
  ),
  useEffects : [
    'base:fling',
    'base:break-item'
  ],
  equipEffects : [
    'base:non-combat-weapon' // high chance to deflect, but when it deflects, the weapon breaks
    
  ],
  possibleArts : [
    'base:stun'
  ],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE
  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Pickaxe",
  id : 'base:pickaxe',
  description: 'A common mining implement.',
  examine : 'Quite sturdy and pointy, some people use these as weapons.',
  equipType: TYPE.TWOHANDED,
  rarity : 100,
  tier: 0,
  weight : 4,
  basePrice: 20,
  levelMinimum : 1,
  enchantLimit : 0,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 25,
    DEF: 5,
    SPD: -15,
    DEX: -15
  ),
  useEffects : [
    'base:fling',
    'base:break-item'
  ],
  equipEffects : [
    'base:non-combat-weapon' // high chance to deflect, but when it deflects, the weapon breaks
    
  ],
  possibleArts : [
    'base:stab'
  ],


  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE
  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Butcher's Knife",
  id : 'base:butchers-knife',
  description: 'Common knife meant for cleaving meat.',
  examine : 'Quite sharp.',
  equipType: TYPE.HAND,
  rarity : 100,
  tier: 0,
  weight : 4,
  basePrice: 17,
  levelMinimum : 1,
  enchantLimit : 0,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    ATK: 25,
    DEX: 5
  ),
  useEffects : [
    'base:fling',
    'base:break-item'
  ],
  equipEffects : [
    'base:non-combat-weapon' // high chance to deflect, but when it deflects, the weapon breaks
    
  ],
  possibleArts : [
    'base:stab'
  ],

  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE
  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Bludgeon",
  id : 'base:bludgeon',
  description: 'A basic blunt weapon. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Clubs and bludgeons seem primitive, but are quite effective.',
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 4,
  basePrice: 70,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 20,
    DEF: 15,
    SPD: -10
  ),
  useEffects : [
    'base:fling',
  ],
  possibleArts : [
    'base:doublestrike',
    'base:triplestrike',
    'base:stun'
  ],

  equipEffects : [],
  traits : 
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR

  ,
  onCreate ::(item, creationHint) {}

})  

Item.database.newEntry(data : {
  name : "Shortsword",
  id : 'base:shortsword',
  description: 'A basic sword. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Swords like these are quite common and are of adequate quality even if simple.',
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 4,
  basePrice: 90,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 30,
    DEF: 10,
    SPD: -5
  ),
  useEffects : [
    'base:fling',
  ],
  possibleArts : [
    'base:stab',
    'base:doublestrike',
    'base:triplestrike',
    'base:stun'
  ],

  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR


  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Longsword",
  id : 'base:longsword',
  description: 'A basic sword. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Swords like these are quite common and are of adequate quality even if simple.',
  equipType: TYPE.TWOHANDED,
  rarity : 300,
  weight : 4,
  basePrice: 110,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 35,
    DEF: 15,
    SPD: -10
  ),
  useEffects : [
    'base:fling',
  ],
  possibleArts : [
    'base:stab',
    'base:stun'
  ],

  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR


  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Blade & Shield",
  id : 'base:blade-and-shield',
  description: 'A matching medium-length blade and shield. They feature a $color$, $design$ design.',
  examine : 'Weapons with shields seem to block more than they let on.',
  equipType: TYPE.TWOHANDED,
  rarity : 400,
  weight : 12,
  basePrice: 250,
  levelMinimum : 1,
  tier: 1,
  enchantLimit : 15,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
  blockPoints : 2,
  equipMod : StatSet.new(
    ATK: 25,
    DEF: 35,
    SPD: -15,
    DEX: 10
  ),
  useEffects : [
    'base:fling',
  ],
  possibleArts : [
    'base:counter',
    'base:stun',
    'base:leg-sweep'
  ],

  equipEffects : [],
  traits : 
    TRAIT.SHARP  |
    TRAIT.METAL  |
    TRAIT.SHIELD |
    TRAIT.WEAPON |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR

    
  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Wall Shield",
  id : 'base:wall-shield',
  description: 'A large shield that can be used for defending.',
  examine : 'Weapons with shields seem to block more than they let on.',
  equipType: TYPE.TWOHANDED,
  rarity : 400,
  weight : 17,
  basePrice: 350,
  levelMinimum : 1,
  tier: 2,
  enchantLimit : 15,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
  blockPoints : 2,
  equipMod : StatSet.new(
    ATK: 15,
    DEF: 55,
    SPD: -15,
    DEX: -10
  ),
  useEffects : [
    'base:fling',
  ],
  possibleArts : [
    'base:counter',
    'base:stun',
    'base:leg-sweep'
  ],

  equipEffects : [],
  traits : 
    TRAIT.BLUNT  |
    TRAIT.METAL  |
    TRAIT.SHIELD |
    TRAIT.WEAPON |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR

    
  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Chakram",
  id : 'base:chakram',
  description: 'A pair of round blades. The handles have a $color$ trim with a $design$ design.',
  examine : '.',
  equipType: TYPE.TWOHANDED,
  rarity : 300,
  weight : 4,
  tier: 3,
  basePrice: 200,
  levelMinimum : 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stab',
    'base:stun',
    'base:combo-strike'
  ],

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 25,
    DEF: 5,
    SPD: 15,
    DEX: 25
  ),
  useEffects : [
    'base:fling',
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR


  ,
  onCreate ::(item, creationHint) {}

})  

Item.database.newEntry(data : {
  name : "Blade Pair",
  id : 'base:dual-blades',
  description: 'A pair of short blades. The hilts have a $color$ trim with a $design$ design.',
  examine : '.',
  equipType: TYPE.TWOHANDED,
  rarity : 300,
  weight : 8,
  tier: 3,
  basePrice: 350,
  levelMinimum : 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stab',
    'base:stun',
    'base:combo-strike'
  ],

  // fatigued
  blockPoints : 2,
  equipMod : StatSet.new(
    ATK: 35,
    DEF: -20,
    SPD: -15,
    DEX: 30
  ),
  useEffects : [
    'base:fling',
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR


  ,
  onCreate ::(item, creationHint) {}

}) 

Item.database.newEntry(data : {
  name : "Falchion",
  id : 'base:falchion',
  description: 'A basic sword with a large blade. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Swords like these are quite common and are of adequate quality even if simple.',
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 4,
  basePrice: 150,
  levelMinimum : 1,
  tier: 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stab',
    'base:doublestrike',
    'base:triplestrike',
    'base:stun',
    'base:counter'
  ],

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 35,
    DEF: 10,
    SPD: -10
  ),
  useEffects : [
    'base:fling',
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR


  ,
  onCreate ::(item, creationHint) {}

})  


Item.database.newEntry(data : {
  name : "Morning Star",
  id : 'base:morning-star',
  description: 'A spiked weapon. The hilt has a $color$ trim with a $design$ design.',
  examine : '',
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 4,
  basePrice: 150,
  levelMinimum : 1,
  tier: 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stab',
    'base:stun',
    'base:counter',
    'base:big-swing'
  ],

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 35,
    DEF: 20,
    SPD: -10
  ),
  useEffects : [
    'base:fling',
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR


  ,
  onCreate ::(item, creationHint) {}

})   

Item.database.newEntry(data : {
  name : "Scimitar",
  id : 'base:scimitar',
  description: 'A basic sword with a curved blade. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Swords like these are quite common and are of adequate quality even if simple.',
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 4,
  basePrice: 150,
  levelMinimum : 1,
  tier: 2,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stab',
    'base:doublestrike',
    'base:triplestrike',
    'base:stun',
  ],

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 30,
    DEF: 10,
    SPD: -10,
    DEX: 10
  ),
  useEffects : [
    'base:fling',
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}

}) 


Item.database.newEntry(data : {
  name : "Rapier",
  id : 'base:rapier',
  description: 'A slender sword excellent for thrusting. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Swords like these are quite common and are of adequate quality even if simple.',
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 4,
  basePrice: 120,
  tier: 2,
  levelMinimum : 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stab',
    'base:doublestrike',
    'base:triplestrike',
    'base:counter'
  ],

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 35,
    SPD: 10,
    DEF:-10,
    DEX: 10
  ),
  useEffects : [
    'base:fling',
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}

})  


Item.database.newEntry(data : {
  name : "Bow & Quiver",
  id : 'base:bow-and-quiver',
  description: 'A basic bow and quiver full of arrows. The bow features a $design$ design and has a streak of $color$ across it.',
  examine : '',
  equipType: TYPE.TWOHANDED,
  rarity : 300,
  weight : 2,
  basePrice: 76,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:doublestrike',
    'base:triplestrike',
    'base:precise-strike',
    'base:tranquilizer'
  ],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    ATK: 55,
    SPD: -10,
    DEX: 95
  ),
  useEffects : [
    'base:fling',
    'base:break-item'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR

  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Crossbow",
  id : 'base:crossbow',
  description: 'A mechanical device that launches bolts. It features a $color$, $design$ design design.',
  examine : '',
  equipType: TYPE.TWOHANDED,
  rarity : 300,
  weight : 10,
  basePrice: 76,
  levelMinimum : 1,
  tier: 3,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:precise-strike',
    'base:tranquilizer'
  ],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    ATK: 35,
    SPD: -10,
    DEX: 45
  ),
  useEffects : [
    'base:fling',
    'base:break-item'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.WEAPON |
    TRAIT.METAL |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR

  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Greatsword",
  id : 'base:greatsword',
  description: 'A basic, large sword. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Not as common as shortswords, but rather easy to find. Favored by larger warriors.',
  equipType: TYPE.TWOHANDED,
  rarity : 300,
  weight : 12,
  tier: 1,
  basePrice: 87,
  enchantLimit : 10,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stun',
    'base:stab',
    'base:big-swing',
    'base:leg-sweep'
  ],

  // fatigued
  blockPoints : 2,
  equipMod : StatSet.new(
    ATK: 30,
    DEF: 25,
    SPD: -15
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR

  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Dagger",
  id : 'base:dagger',
  description: 'A basic knife. The handle has an $color$ trim with a $design$ design.',
  examine : 'Commonly favored by both swift warriors and common folk for their easy handling and easiness to produce.',
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 1,
  tier: 0,
  basePrice: 35,
  enchantLimit : 10,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 15,
    SPD: 10,
    DEX: 20
  ),
  useEffects : [
    'base:fling',
  ],
  possibleArts : [
    'base:stab',
    'base:doublestrike',
    'base:triplestrike'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR

  ,
  onCreate ::(item, creationHint) {}

})  

Item.database.newEntry(data : {
  name : "Knuckle",
  id : 'base:knuckle',
  description: 'Designed to be worn on the fists for close combat. It has an $color$ trim with a $design$ design.',
  examine : '',
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 0.5,
  tier: 0,
  basePrice: 35,
  enchantLimit : 10,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,

  blockPoints : 0,
  equipMod : StatSet.new(
    ATK: 15,
    DEF: -20,
    SPD: 40,
    DEX: 50
  ),
  useEffects : [
    'base:fling',
  ],
  possibleArts : [
    'base:counter',
    'base:doublestrike',
    'base:triplestrike'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR

  ,
  onCreate ::(item, creationHint) {}

})  


Item.database.newEntry(data : {
  name : "Smithing Hammer",
  id : 'base:smithing-hammer',
  description: 'A basic hammer meant for smithing.',
  examine : 'Easily available, this hammer is common as a general tool for metalworking.',
  equipType: TYPE.TWOHANDED,
  rarity : 100,
  weight : 8,
  basePrice: 30,
  tier: 0,
  levelMinimum : 1,
  enchantLimit : 0,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stun'
  ],

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK:  30,
    SPD: -30,
    DEX: -30
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.HAS_SIZE |
    TRAIT.HAS_COLOR


  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Halberd",
  id : 'base:halberd',
  description: 'A weapon with long reach and deadly power. The handle has a $color$ trim with a $design$ design.',
  examine : '',
  equipType: TYPE.TWOHANDED,
  rarity : 100,
  weight : 8,
  basePrice: 105,
  tier: 2,
  levelMinimum : 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stun',
    'base:stab',
    'base:big-swing',
    'base:leg-sweep'
  ],

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK:  40,
    SPD:  15,
    DEX:  20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Lance",
  id : 'base:lance',
  description: 'A weapon with long reach and deadly power. The handle has a $color$ trim with a $design$ design.',
  examine : '',
  equipType: TYPE.TWOHANDED,
  rarity : 100,
  weight : 5,
  basePrice: 105,
  tier: 0,
  levelMinimum : 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stun',
    'base:stab',
    'base:big-swing',
    'base:leg-sweep'
  ],

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK:  35,
    SPD:  20,
    DEX:  15
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}

})  

Item.database.newEntry(data : {
  name : "Glaive",
  id : 'base:glaive',
  description: 'A weapon with long reach and deadly power. The handle has a $color$ trim with a $design$ design.',
  examine : '',
  equipType: TYPE.TWOHANDED,
  rarity : 100,
  weight : 8,
  basePrice: 105,
  tier: 1,
  levelMinimum : 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stun',
    'base:stab',
    'base:big-swing',
    'base:leg-sweep'
  ],

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK:  35,
    SPD:  15,
    DEX:  25
  ),
  useEffects : [
    'base:fling',
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}

})  


Item.database.newEntry(data : {
  name : "Staff",
  id :  'base:staff',
  description: 'A combat staff. Promotes fluid movement when used well. The ends are tied with a $color$ fabric, featuring a $design$ design.',
  examine : '',
  equipType: TYPE.TWOHANDED,
  rarity : 100,
  weight : 8,
  basePrice: 40,
  levelMinimum : 1,
  tier: 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:stun',
    'base:big-swing',
    'base:leg-sweep'
  ],

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK:  25,
    SPD:  15,
    DEX:  30
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}

})  


Item.database.newEntry(data : {
  name : "Mage-Staff",
  id : 'base:mage-staff',
  description: 'Similar to a wand, promotes mental acuity. The handle has a $color$ trim with a $design$ design.',
  examine : '',
  equipType: TYPE.TWOHANDED,
  rarity : 100,
  weight : 9,
  basePrice: 100,
  levelMinimum : 1,
  tier: 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:fire',
    'base:ice',
    'base:thunder',
    'base:flare',
    'base:frozen-flame',
    'base:explosion',
    'base:flash',
    'base:cure',
    'base:cure-all',
    'base:summon-fire-sprite',
    'base:summon-ice-elemental',
    'base:summon-thunder-spawn'
  ],

  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    ATK:  25,
    SPD:  -10,
    INT:  45
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR    
  ,
  onCreate ::(item, creationHint) {}

}) 

Item.database.newEntry(data : {
  name : "Wand",
  id : 'base:wand',
  description: 'The handle has a $color$ trim with a $design$ design.',
  examine : '',
  equipType: TYPE.TWOHANDED,
  rarity : 100,
  weight : 8,
  basePrice: 100,
  levelMinimum : 1,
  enchantLimit : 10,
  tier: 2,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [
    'base:fire',
    'base:ice',
    'base:thunder',
    'base:flare',
    'base:frozen-flame',
    'base:explosion',
    'base:flash',
    'base:cure',
    'base:cure-all'
  ],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    ATK:  5,
    INT:  85,
    SPD:  45,
    DEX:  20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}

})  



Item.database.newEntry(data : {
  name : "Warhammer",
  id : 'base:warhammer',
  description: 'A hammer meant for combat with a $design$ design. The end is tied with a $color$ fabric.',
  examine : 'A common choice for those who wish to cause harm and have the arm to back it up.',
  equipType: TYPE.TWOHANDED,
  rarity : 350,
  weight : 10,
  levelMinimum : 1,
  enchantLimit : 10,
  basePrice: 200,
  useTargetHint : USE_TARGET_HINT.ONE,
  tier: 2,
  possibleArts : [
    'base:stun',
    'base:big-swing',
    'base:leg-sweep'
  ],

  // fatigued
  blockPoints : 2,
  equipMod : StatSet.new(
    ATK: 45,
    DEF: 30,
    SPD: -25,
    DEX: -25
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Battelaxe",
  id : 'base:battleaxe',
  description: 'An axe meant for combat with a $design$ design. The end is tied with a $color$ fabric.',
  examine : 'A common choice for those who wish to cause harm and have the arm to back it up.',
  equipType: TYPE.TWOHANDED,
  rarity : 350,
  weight : 10,
  levelMinimum : 1,
  enchantLimit : 10,
  basePrice: 250,
  useTargetHint : USE_TARGET_HINT.ONE,
  tier: 2,
  possibleArts : [
    'base:stun',
    'base:big-swing',
    'base:leg-sweep'
  ],

  // fatigued
  blockPoints : 2,
  equipMod : StatSet.new(
    ATK: 75,
    DEF: 10,
    SPD: -25,
    DEX: -25
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}

})



Item.database.newEntry(data : {
  name : "Tome",
  id : 'base:tome',
  description: 'A plated book for magick-users in the heat of battle. It is covered with a $color$ fabric featuring a $design$ design.',
  examine : 'A lightly enchanted book meant to both be used as reference on-the-fly and meant to increase the mental acquity of the holder.',
  equipType: TYPE.HAND,
  rarity : 350,
  weight : 1,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 220,
  possibleArts : [
    'base:fire',
    'base:ice',
    'base:thunder',
    'base:flash',
    'base:cure',
  ],
  // fatigued
  blockPoints : 1,
  equipMod : StatSet.new(
    DEF: 15,
    INT: 60,
    SPD: -10
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.WEAPON |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}
  
})

Item.database.newEntry(data : {
  name : "Tunic",
  id : 'base:tunic',
  description: 'Simple cloth for the body with a $design$ design. It is predominantly $color$.',
  examine : 'Common type of light armor',
  equipType: TYPE.ARMOR,
  rarity : 100,
  weight : 1,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 100,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    DEF: 5,
    SPD: 5
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.APPAREL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR  
  
  ,
  onCreate ::(item, creationHint) {}
  
})


Item.database.newEntry(data : {
  name : "Robe",
  id : 'base:robe',
  description: 'Simple cloth favored by scholars. It features a $color$, $design$ design.',
  examine : 'Common type of light armor',
  equipType: TYPE.ARMOR,
  rarity : 100,
  weight : 1,
  tier: 0,
  levelMinimum : 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 100,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    DEF: 5,
    INT: 5
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.APPAREL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR  
  ,
  onCreate ::(item, creationHint) {}
  
})

Item.database.newEntry(data : {
  name : "Scarf",
  id : 'base:scarf',
  description: 'Simple cloth accessory. It is $color$ with a $design$ design.',
  examine : 'Common type of light armor',
  equipType: TYPE.TRINKET,
  rarity : 100,
  weight : 1,
  tier: 2,
  levelMinimum : 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 40,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    DEF: 3
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.APPAREL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR  
  
  ,
  onCreate ::(item, creationHint) {}
  
})  


Item.database.newEntry(data : {
  name : "Headband",
  id : 'base:headband',
  description: 'Simple cloth accessory. It is $color$ with a $design$ design.',
  examine : 'Common type of light armor',
  equipType: TYPE.TRINKET,
  rarity : 100,
  weight : 1,
  levelMinimum : 1,
  tier: 2,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 40,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    DEF: 3
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.APPAREL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR    
  ,
  onCreate ::(item, creationHint) {}
  
})    
Item.database.newEntry(data : {
  name : "Ring",
  id : 'base:ring',
  description: 'A metallic ring. The inset gem is $color$ and features a $design$ design.',
  examine : '',
  equipType: TYPE.RING,
  rarity : 300,
  weight : 1,
  tier: 2,
  basePrice: 100,
  enchantLimit : 10,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,

  blockPoints : 0,
  equipMod : StatSet.new(
    ATK: 15,
    SPD: 10,
    DEX: 20
  ),
  useEffects : [
    'base:fling',
  ],
  possibleArts : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.METAL |
    TRAIT.HAS_QUALITY |
    TRAIT.HAS_SIZE |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR  
  ,
  onCreate ::(item, creationHint) {}

})  

Item.database.newEntry(data : {
  name : "Cape",
  id : 'base:cape',
  description: 'Simple cloth accessory. It features a $color$-based design with a $design$ pattern.',
  examine : 'Common type of light armor',
  equipType: TYPE.TRINKET,
  rarity : 100,
  weight : 5,
  levelMinimum : 1,
  tier: 2,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 105,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    DEF: 3
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.APPAREL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR    
  ,
  onCreate ::(item, creationHint) {}
  
})  


Item.database.newEntry(data : {
  name : "Cloak",
  id : 'base:cloak',
  description: 'Simple cloth accessory that covers the entire body and includes a hood. It features a $color$-based design with a $design$ pattern.',
  examine : 'Stylish!',
  equipType: TYPE.TRINKET,
  rarity : 100,
  weight : 1,
  levelMinimum : 1,
  tier: 2,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 55,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    SPD: 3,
    DEX: 5
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.APPAREL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR    
  
  ,
  onCreate ::(item, creationHint) {}
  
})   

Item.database.newEntry(data : {
  name : "Hat",
  id : 'base:hat',
  description: 'Simple cloth accessory. It is predominantly $color$ with a $design$ design.',
  examine : 'Common type of light armor',
  equipType: TYPE.TRINKET,
  rarity : 100,
  weight : 1,
  levelMinimum : 1,
  tier: 2,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 10,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    DEF: 3
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.APPAREL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.HAS_COLOR    
  
  ,
  onCreate ::(item, creationHint) {}
  
})       

Item.database.newEntry(data : {
  name : "Fortified Cape",
  id : 'base:fortified-cape',
  description: 'A cape fortified with metal. It is a bit heavy. It features a $color$ trim and a $design$ design.',
  examine : 'Common type of light armor',
  equipType: TYPE.TRINKET,
  rarity : 350,
  weight : 10,
  tier: 3,
  levelMinimum : 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 200,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    DEF: 15,
    SPD: -10
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.METAL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR      
  ,
  onCreate ::(item, creationHint) {}
  
})   


Item.database.newEntry(data : {
  name : "Light Robe",
  id : 'base:light-robe',
  description: 'Enchanted light wear favored by mages. It features a $color$, $design$ design.',
  examine : 'Common type of light armor',
  equipType: TYPE.ARMOR,
  rarity : 350,
  weight : 1,
  tier: 1,
  levelMinimum : 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 350,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    DEF: 23,
    INT: 15
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.APPAREL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR    
  ,
  onCreate ::(item, creationHint) {}
  
})  


Item.database.newEntry(data : {
  name : "Chainmail",
  id : 'base:chainmail',
  description: 'Mail made of linked chains. It bears an emblem colored $color$ with a $design$ design.',
  examine : 'Common type of light armor',
  equipType: TYPE.ARMOR,
  rarity : 350,
  weight : 1,
  levelMinimum : 1,
  tier: 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 200,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    DEF: 40,
    SPD: -10
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}
  
})

Item.database.newEntry(data : {
  name : "Filigree Armor",
  id : 'base:filigree-armor',
  description: 'Hardened material with a fancy $color$ trim and a $design$ design.',
  examine : 'Common type of light armor',
  equipType: TYPE.ARMOR,
  rarity : 500,
  weight : 1,
  levelMinimum : 1,
  enchantLimit : 10,
  tier: 2,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 350,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    DEF: 55,
    ATK: 20,
    SPD: -40
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}
  
})
  
Item.database.newEntry(data : {
  name : "Plate Armor",
  id : 'base:plate-armor',
  description: 'Extremely protective armor of a high-grade. It has a $color$ trim with a $design$ design.',
  examine : 'Highly skilled craftspeople are required to make this work.',
  equipType: TYPE.ARMOR,
  rarity : 500,
  weight : 1,
  levelMinimum : 1,
  tier: 3,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 400,
  possibleArts : [],

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    DEF: 75,
    ATK: 40,
    SPD: -65
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.BLUNT |
    TRAIT.METAL |
    TRAIT.HAS_QUALITY |
    TRAIT.CAN_HAVE_ENCHANTMENTS |
    TRAIT.CAN_BE_APPRAISED |
    TRAIT.CAN_HAVE_TRIGGER_ENCHANTMENTS |
    TRAIT.HAS_COLOR
  ,
  onCreate ::(item, creationHint) {}
  
})  
/*
Item.database.newEntry(data : {
  name : "Edrosae's Key",
  id : 'base:
  description: 'The gateway to the domain of the Elders.',
  examine : '',
  equipType: TYPE.TWOHANDED,
  rarity : 10000000,
  hasSize : false,
  basePrice: 1,
  keyItem : true,
  canBeColored : false,
  weight : 10,
  tier: 0,
  levelMinimum : 1,
  canHaveEnchants : false,
  canHaveTriggerEnchants : false,
  enchantLimit : 0,
  hasQuality : false,
  hasMaterial : false,
  isApparel : false,
  isUnique : true,
  possibleArts : [],
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
  blockPoints : 0,
  equipMod : StatSet.new(
    ATK: 15,
    SPD: -5,
    DEX: -5
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.METAL
  ,
  onCreate ::(item, creationHint) {}
  
})*/


////// RAW_METALS


Item.database.newEntry(data : {
  name : "Copper Ingot",
  id : 'base:copper-ingot',
  description: 'Copper Ingot',
  examine : 'Pure copper ingot.',
  equipType: TYPE.TWOHANDED,
  rarity : 150,
  weight : 5,
  tier: 0,
  basePrice: 10,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [],

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.RAW_METAL |
    TRAIT.STACKABLE
  ,
  onCreate ::(item, creationHint) {
    item.data.RAW_MATERIAL = 'base:copper';
  }

})    



Item.database.newEntry(data : {
  name : "Iron Ingot",
  id : 'base:iron-ingot',
  description: 'Iron Ingot',
  examine : 'Pure iron ingot',
  equipType: TYPE.TWOHANDED,
  rarity : 200,
  weight : 5,
  tier: 0,
  basePrice: 20,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [],
  blockPoints : 1,

  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.RAW_METAL |
    TRAIT.STACKABLE
  ,
  onCreate ::(item, creationHint) {
    item.data.RAW_MATERIAL = 'base:iron';
  }

})   

Item.database.newEntry(data : {
  name : "Steel Ingot",
  id : 'base:steel-ingot',
  description: 'Steel Ingot',
  examine : 'Pure Steel ingot.',
  equipType: TYPE.TWOHANDED,
  rarity : 300,
  tier: 0,
  weight : 5,
  basePrice: 30,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [],
  blockPoints : 1,

  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.RAW_METAL |
    TRAIT.STACKABLE
  ,
  onCreate ::(item, creationHint) {
    item.data.RAW_MATERIAL = 'base:steel';
  }

})    



Item.database.newEntry(data : {
  name : "Mythril Ingot",
  id : 'base:mythril-ingot',
  description: 'Mythril Ingot',
  examine : 'Pure iron ingot',
  equipType: TYPE.TWOHANDED,
  rarity : 1000,
  tier: 1,
  weight : 5,
  basePrice: 150,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [],

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.RAW_METAL |
    TRAIT.STACKABLE
  ,
  onCreate ::(item, creationHint) {
    item.data.RAW_MATERIAL = 'base:mythril';
  }

})   

Item.database.newEntry(data : {
  name : "Quicksilver Ingot",
  id : 'base:quicksilver-ingot',
  description: 'Quicksilver Ingot',
  examine : 'Pure quicksilver alloy ingot',
  equipType: TYPE.TWOHANDED,
  rarity : 1550,
  tier: 1,
  weight : 5,
  basePrice: 175,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [],

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.RAW_METAL |
    TRAIT.STACKABLE
  ,
  onCreate ::(item, creationHint) {
    item.data.RAW_MATERIAL = 'base:quicksilver';
  }

})   

Item.database.newEntry(data : {
  name : "Adamantine Ingot",
  id : 'base:adamantine-ingot',
  description: 'Adamantine Ingot',
  examine : 'Pure adamantine ingot',
  equipType: TYPE.TWOHANDED,
  rarity : 2000,
  weight : 5,
  basePrice: 300,
  tier: 2,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [],

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.RAW_METAL |
    TRAIT.STACKABLE
  ,
  onCreate ::(item, creationHint) {
    item.data.RAW_MATERIAL = 'base:adamantine';
  }

}) 


Item.database.newEntry(data : {
  name : "Sunstone Ingot",
  id : 'base:substone-ingot',
  description: 'Sunstone alloy ingot',
  examine : 'An alloy with mostly sunstone, it dully shines with a soft yellow gleam',
  equipType: TYPE.TWOHANDED,
  rarity : 300,
  basePrice: 115,
  weight : 5,
  tier: 2,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [],

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.RAW_METAL |
    TRAIT.STACKABLE
  ,
  onCreate ::(item, creationHint) {
    item.data.RAW_MATERIAL = 'base:sunstone';
  }

}) 

Item.database.newEntry(data : {
  name : "Moonstone Ingot",
  id : 'base:moonstone-ingot',
  description: 'Sunstone alloy ingot',
  examine : 'An alloy with mostly moonstone, it dully shines with a soft teal',
  equipType: TYPE.TWOHANDED,
  rarity : 300,
  weight : 5,
  tier: 2,
  basePrice: 115,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [],

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.RAW_METAL |
    TRAIT.STACKABLE
  ,
  onCreate ::(item, creationHint) {
    item.data.RAW_MATERIAL = 'base:moonstone';
  }

}) 

Item.database.newEntry(data : {
  name : "Dragonglass Ingot",
  id : 'base:dragonglass-ingot',
  description: 'Dragonglass alloy ingot',
  examine : 'An alloy with mostly dragonglass, it sharply shines black.',
  equipType: TYPE.TWOHANDED,
  rarity : 500,
  weight : 5,
  enchantLimit : 0,
  basePrice: 250,
  tier: 2,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [],

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.RAW_METAL |
    TRAIT.STACKABLE
  ,
  onCreate ::(item, creationHint) {
    item.data.RAW_MATERIAL = 'base:dragonglass';
  }

}) 
Item.database.newEntry(data : {
  name : "Ore",
  id : 'base:ore',
  description: "Raw ore. It's hard to tell exactly what kind of metal it is.",
  examine : 'Could be smelted into...',
  equipType: TYPE.TWOHANDED,
  rarity : 100,
  weight : 5,
  tier: 0,
  enchantLimit : 0,
  levelMinimum : 100000,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 5,
  possibleArts : [],

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:fling'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.STACKABLE |
    TRAIT.UNIQUE
  ,
  onCreate ::(item, creationHint) {}

}) 

Item.database.newEntry(data : {
  name : "Gold Pouch",
  id : 'base:gold-pouch',
  description: "A pouch of coins.",
  examine : '',
  equipType: TYPE.HAND,
  rarity : 100,
  weight : 5,
  tier: 0,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 1000,
  possibleArts : [],
  blockPoints : 0,

  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:treasure-1',
    'base:consume-item'     
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP|
    TRAIT.STACKABLE |
    TRAIT.MEANT_TO_BE_USED    
  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Perfect Arts Crystal",
  id : 'base:perfect-arts-crystal',
  description: "Extremely rare irridescent crystal that imparts knowledge when used. The skills required to make this have been lost to time.",
  examine : 'Not much else is known about these.',
  equipType: TYPE.HAND,
  rarity : 100,
  weight : 3,
  tier: 10,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 3000,
  possibleArts : [],

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 10, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:learn-arts-perfect',
    'base:consume-item'     
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.STACKABLE |
    TRAIT.UNIQUE |
    TRAIT.MEANT_TO_BE_USED    
  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Arts Crystal",
  id : 'base:arts-crystal',
  description: "Irridescent crystal that imparts knowledge when used.",
  examine : 'Quite sought after, highly skilled mages usually produce them for the public.',
  equipType: TYPE.HAND,
  rarity : 100,
  weight : 3,
  tier: 0,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 600,
  possibleArts : [],

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 10, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:learn-arts',
    'base:consume-item'     
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.STACKABLE |
    TRAIT.UNIQUE |
    TRAIT.MEANT_TO_BE_USED    
  ,
  onCreate ::(item, creationHint) {}

})
  



/*
Item.database.newEntry(data : {
  name : "Runestone",
  description: "Resonates with certain locations and can reveal runes.",
  examine : '',
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 10,
  tier: 0,
  canBeColored : false,
  hasSize : false,
  keyItem : true,
  canHaveEnchants : false,
  canHaveTriggerEnchants : false,
  enchantLimit : 0,
  hasQuality : false,
  hasMaterial : false,
  isApparel : false,  isUnique : false,
  levelMinimum : 1000000,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 0,
  possibleArts : [],

  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP
  ,
  onCreate ::(item, creationHint) {}

})  
*/


Item.database.newEntry(data : {
  name : "Tablet",
  id : 'base:tablet',
  description: "A tablet with carved with runes in Draconic. Arcanists might find this valuable.",
  examine : 'Might have been used for some highly specialized purpose. These seem very rare.',
  equipType: TYPE.TWOHANDED,
  rarity : 3000,
  weight : 10,
  tier: 0,
  enchantLimit : 0,
  levelMinimum : 10000000,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 175,
  possibleArts : [],

  blockPoints : 1,
  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:fling',
    'base:break-item'
  ],
  equipEffects : [],
  traits : 
    TRAIT.SHARP |
    TRAIT.STACKABLE
  ,
  onCreate ::(item, creationHint) {}

}) 


Item.database.newEntry(data : {
  name : "Ingredient",
  id : 'base:ingredient',
  description: "A pack of ingredients used for potions and brews.",
  examine : 'Common ingredients used by alchemists.',
  equipType: TYPE.TWOHANDED,
  rarity : 300000000,
  weight : 1,
  tier: 0,
  enchantLimit : 0,
  levelMinimum : 10000000,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 5,
  possibleArts : [],

  blockPoints : 0,
  equipMod : StatSet.new(
    ATK: 0,
    DEF: 2, 
    SPD: -1,
    DEX: -2
  ),
  useEffects : [
    'base:fling',
    'base:break-item'
  ],
  equipEffects : [],
  traits :     
    TRAIT.STACKABLE |
    TRAIT.UNIQUE
  ,
  onCreate ::(item, creationHint) {}

}) 


Item.database.newEntry(data : {
  name : "Book",
  id : 'base:book',
  description: "A book containing writing. It can be read it to see its contents.",
  examine : 'Common ingredients used by alchemists.',
  equipType: TYPE.TWOHANDED,
  rarity : 39,
  weight : 2,
  tier: 0,
  enchantLimit : 40,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 30,
  possibleArts : [],

  blockPoints : 0,
  equipMod : StatSet.new(
    ATK: 0,
    DEF: 2, 
    SPD: -1,
    DEX: -2
  ),
  useEffects : [
    'base:read'
  ],
  equipEffects : [],
  traits :     
    TRAIT.MEANT_TO_BE_USED
  ,
  onCreate ::(item, creationHint) {
    @:Book = import(:'game_database.book.mt');
    item.data.book = if (creationHint == empty) Book.getRandom() else Book.find(:creationHint);
    item.name = 'Book: ' + item.data.book.name;
  }

}) 


Item.database.newEntry(data : {
  name : "Seed",
  id : 'base:seed',
  description: "Permanently increases a base stat.",
  examine : 'Its abilities are unknown.',
  equipType: TYPE.TWOHANDED,
  rarity : 500,
  weight : 1,
  tier: 4,
  enchantLimit : 40,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 10,
  possibleArts : [],

  blockPoints : 0,
  equipMod : StatSet.new(
  ),
  useEffects : [
    'base:seed',
    'base:consume-item'     
  ],
  equipEffects : [],
  traits :     
    TRAIT.MEANT_TO_BE_USED |
    TRAIT.UNIQUE
  ,
  onCreate ::(item, creationHint) {
    @:stats = {
      "HP" : 2,
      "AP" : 2,
      "ATK" : 3,
      "DEF" : 3,
      "SPD" : 3,
      "INT" : 3,
      "LUK" : 3,
      "DEX" : 3
    }
    
    item.data.statIncreaseType = random.pickArrayItem(:stats->keys);
    item.data.statIncrease = stats[item.data.statIncreaseType];
    item.name = item.data.statIncreaseType + ' Seed';
  }
}) 



  
::<= {

  Item.database.newEntry(data : {
    name : "Wyvern Key",
    id : 'base:wyvern-key',
    description: 'A key to another island. The key is huge, dense, and requires 2 hands to wield. In fact, it is so large and sturdy that it could even be wielded as a weapon in dire circumstances.',
    examine : '',
    equipType: TYPE.TWOHANDED,
    rarity : 100,
    weight : 10,
    basePrice: 1000,
    tier: 0,
    levelMinimum : 1000000000,
    enchantLimit : 20,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleArts : [
    ],

    // fatigued
    blockPoints : 2,
    equipMod : StatSet.new(
      ATK: 15,
      SPD: -5,
      DEX: -5
    ),
    useEffects : [
    ],
    equipEffects : [],
    traits : 
      TRAIT.SHARP  |
      TRAIT.UNIQUE |
      TRAIT.HAS_COLOR
    ,
    onCreate ::(item, user, creationHint) {
      @:world = import(module:'game_singleton.world.mt');
      @:Island = import(:'game_mutator.island.mt');
      @tier = if (world != empty && world.island != empty) world.island.tier + random.integer(from:1, to:4) else 0;

      if (creationHint->type == Object) ::<= {
        if (creationHint.tier->type == Number) 
          tier = creationHint.tier
      }
      breakpoint();

      @:story = import(:'game_singleton.story.mt');
      @:capitalize = import(:'game_function.capitalize.mt');
      item.name = random.pickArrayItem(:keyQualifiers) + ' Key (Tier '+ tier + ')';
      item.price += 4420 * tier;
      item.setIslandGenTraits(
        levelHint : story.levelHint + (tier * 1.4),
        tierHint : tier,
        idHint : Island.database.getRandomFiltered(::(value) <- (value.traits & Island.TRAITS.SPECIAL) == 0).id
      );
    }
  })  
}

none = Item.new(base:Item.database.find(id:'base:none'), artsHint : [])
none.name = 'None';
}

/*
@:Inventory = import(module:'game_class.inventory.mt');
@:ItemEnchant = import(module:'game_mutator.itemenchant.mt');
@:ItemQuality = import(module:'game_database.itemquality.mt');
@:ItemColor = import(module:'game_database.itemcolor.mt');
@:ItemDesign = import(module:'game_database.itemdesign.mt');
@:Material = import(module:'game_database.material.mt');
@:ApparelMaterial = import(module:'game_database.apparelmaterial.mt');
@:Arts = import(module:'game_database.arts.mt');
@:Island = import(module:'game_mutator.island.mt');
@:world = import(module:'game_singleton.world.mt');
*/





@:getEnchantTag ::(state) <- match(state.enchants->keycount) {
  (0) :'',
  (1) :' (I)',
  (2) :' (II)',
  (3) :' (III)',
  (4) :' (IV)',
  (5) :' (V)',
  (6) :' (VI)',
  (7) :' (VII)',
  (8) :' (VIII)',
  (9) :' (IX)',
  (10) :' (X)',
  default: ' (*)'     
};

@:expToNextLevel::(level) {
  return 100 ** (1 + 0.104*level);
}

@:recalculateName = ::(state) {
  when(state.needsAppraisal) 
    state.customName = '???? ' + state.base.name;

  when (state.customPrefix != '') ::<= {
    state.customName = state.customPrefix + getEnchantTag(state);
    if (state.improvements > 0) ::<= {
      state.customName = state.customName +  '+'+(state.improvements);
    }
  }

  @baseName =
  if (state.base.hasTraits(:TRAIT.APPAREL) && state.apparel)
    state.apparel.name + ' ' + state.base.name
  else if (state.base.hasTraits(:TRAIT.METAL) && state.material != empty)
    state.material.name + ' ' + state.base.name
  else 
    state.base.name
  ;
  
  state.customName = baseName;
  
    
  @enchantName = getEnchantTag(state);
  
  state.customName = if (state.base.hasTraits(:TRAIT.HAS_QUALITY) && state.quality != empty)
    state.quality.name + ' ' + baseName + enchantName 
  else
    baseName + enchantName;

  if (state.improvements > 0) ::<= {
    state.customName = state.customName +  '+'+(state.improvements);
  }


}

@:sizeToString ::(state) <- match(state.size) {
  (SIZE.SMALL)   : 'smaller than expected',
  (SIZE.TINY)  : 'quite small',
  (SIZE.AVERAGE) : 'normally sized',
  (SIZE.LARGE)   : 'larger than expected',
  (SIZE.BIG)   : 'quite large' 
}

@:assignSize = ::(state){
  state.size = random.integer(from:0, to:4);
  
  (match(state.size) {
    (SIZE.SMALL): ::{
      state.stats.add(stats:StatSet.new(
        ATK:-10,
        DEF:-10,
        SPD:10,
        DEX:10          
      ));
      state.price *= 0.85;          
    },

    (SIZE.TINY): ::{
      state.stats.add(stats:StatSet.new(
        ATK:-20,
        DEF:-20,
        SPD:20,
        DEX:20          
      ));
      state.price *= 0.75;          
    },

    (SIZE.AVERAGE):::{
    },

    (SIZE.LARGE): ::{
      state.stats.add(stats:StatSet.new(
        ATK:10,
        DEF:10,
        SPD:-10,
        DEX:-10          
      ));
      state.price *= 1.15;          
    },

    (SIZE.BIG): ::{
      state.stats.add(stats:StatSet.new(
        ATK:20,
        DEF:20,
        SPD:-20,
        DEX:-20          
      ));
      state.price *= 1.25;          
    }
  })()
}


@:calculateDescription ::(this, state){
  @:Arts = import(module:'game_database.arts.mt');
  @:base = this.base;
  
  when(state.needsAppraisal)
    'It is clearly ' + correctA(:base.name) + '... Though, it\'s hard to discern anything else from this mysterious item. It should be appraised by someone.'
  
  @out = String.combine(strings:[
    base.description,
    ' ',
    (if (state.arts == empty) '' else 'If equipped, ' + 
      (if (state.arts[0] == state.arts[1])
          'the Art "' + Arts.find(id:state.arts[0]).name + '" becomes available often in battle. '
        else
          'the Arts "' + Arts.find(id:state.arts[0]).name + '" and "' + Arts.find(id:state.arts[1]).name + '" become available in battle. '
      )
    ),
    if (state.size == -1) '' else 'It is ' + sizeToString(state) + '. ',
    if (state.hasEmblem) (
      if (base.hasTraits(:TRAIT.APPAREL)) 
        'The maker\'s emblem is sewn on it. '
      else
        'The maker\'s emblem is engraved on it. '
    ) else 
      '',
    if (base.hasTraits(:TRAIT.HAS_QUALITY) && state.quality != empty) state.quality.description + ' ' else '',
    if (base.hasTraits(:TRAIT.METAL)) state.material.description + ' ' else '',
    if (base.hasTraits(:TRAIT.APPAREL)) state.apparel.description + ' ' else '',
    if (base.blockPoints == 1) 'This equipment helps block an additional part of the body while equipped in combat.' else '',
    if (base.blockPoints > 1) 'This equipment helps block multiple additional parts of the body while equipped in combat.' else '',
  ]);
  if (base.hasTraits(:TRAIT.HAS_COLOR)) ::<= {
    out = out->replace(key:'$color$', with:state.color.name);
    out = out->replace(key:'$design$', with:state.design.name);
  }
  return out;
}






@:Item = databaseItemMutatorClass.createLight(
  name : 'Wyvern.Item',  
  statics : {
    TYPE : {get::<-TYPE},
    TRAIT : {get::<-TRAIT},
    USE_TARGET_HINT : {get::<-USE_TARGET_HINT},
    NONE : {get ::<- none},
    BUY_PRICE_MULTIPLIER : {get ::<- 0.1},
    SELL_PRICE_MULTIPLIER : {get ::<- 0.05},
  },


  items : {
    base : empty,
    enchants : empty, // ItemMod
    quality : empty,
    material : empty,
    apparel : empty,
    customPrefix : '',
    customName : '',
    hasEmblem : false,
    size : -1,
    price : 0,
    color : empty,
    islandID : 0,
    islandLevelHint : 0,
    islandNameHint : '',
    islandTierHint : 0,
    islandIDhint : 'base:normal-island',
    islandExtraLandmarks : empty,
    improvementsLeft : 0,
    improvements : 0,
    improvementEXP : 0,
    improvementEXPtoNext : 100,
    equipEffects : empty,
    useEffects : empty,
    intuition : 0,
    arts : empty,
    stats : empty,
    statsBase : empty,
    design : empty,
    data : empty,
    worldID : -1,
    faveMark : '',
    needsAppraisal : false,
    appraisalCount : 0

  },
  
  database : Database.new(
    name: 'Wyvern.Item.Base',
    
    attributes : {
      name : String,
      id : String,
      description : String,
      examine : String,
      equipType : Number,
      rarity : Number,
      weight : Number,
      levelMinimum : Number,
      equipMod : StatSet.type,
      enchantLimit : Number,
      equipEffects : Object,
      useEffects : Object,
      traits : Number,
      useTargetHint : Number,
      onCreate : Function,
      basePrice : Number,
      tier : Number,
      blockPoints : Number,
      possibleArts : Object
    },
    reset     
  ),
  
  private : {
  },
  
  interface : {
    defaultLoad::(base, creationHint, qualityHint, enchantHint, materialHint, apparelHint, rngEnchantHint, colorHint, designHint, artsHint, forceEnchant, forceEnchantCount, forceNeedsAppraisal) {
      @:ItemEnchant = import(module:'game_mutator.itemenchant.mt');
      @:ItemQuality = import(module:'game_database.itemquality.mt');
      @:ItemColor = import(module:'game_database.itemcolor.mt');
      @:ItemDesign = import(module:'game_database.itemdesign.mt');
      @:Material = import(module:'game_database.material.mt');
      @:ApparelMaterial = import(module:'game_database.apparelmaterial.mt');
      @:this = _.this;
      @:state = _.state;
      @:world = import(module:'game_singleton.world.mt');
      @:tier = if (world.island) world.island.tier else 1;
      state.base = base;      
      state.worldID = world.getNextID();
      state.enchants = []; // ItemMod
      state.equipEffects = [];
      state.useEffects = [];
      state.stats = StatSet.new();
      state.statsBase = StatSet.new();
      state.arts = ::<= {
        when (artsHint) artsHint;
        @:out = [
          random.pickArrayItem(list:base.possibleArts),
          random.pickArrayItem(list:base.possibleArts)
        ]
        when(out[0] == empty) empty;
        return out;
      }
      state.base = base;
      state.stats.add(stats:base.equipMod);
      state.price = base.basePrice;
      state.price *= 1.05 * state.base.weight;
      state.improvementsLeft = if (base.id == 'base:none') 0 else random.integer(from:10, to:25);
      state.improvements = 0;
      state.improvementEXP = 0;
      state.data = {};
      state.needsAppraisal = if (forceNeedsAppraisal != empty) forceNeedsAppraisal
        else if (base.hasTraits(:TRAIT.CAN_BE_APPRAISED) && random.try(percentSuccess::<= {
          @chance = 0.2 + tier*1.5;
          when (chance > 5) 5;
          return chance;
        })) true else false;
      
      if (state.needsAppraisal)
        state.price = 999;
      
      if (base.hasTraits(:TRAIT.HAS_SIZE))   
        assignSize(*_);
      foreach(base.equipEffects)::(i, effect) {
        state.equipEffects->push(value:effect);
      }

      foreach(base.useEffects)::(i, effect) {
        state.useEffects->push(value:effect);
      }
      
      
      
      if (base.hasTraits(:TRAIT.HAS_QUALITY)) ::<= {
        // random chance to have a maker's emblem on it, indicating 
        // made with love and care
        if (random.try(percentSuccess:15)) ::<= {
          state.hasEmblem = true;
          state.stats.add(stats:StatSet.new(
            ATK:25,
            DEF:25,
            SPD:25,
            INT:25,
            DEX:25          
          ));
          state.price *= 1.25;
        } else 
          state.hasEmblem = false;
        
        
        if (random.try(percentSuccess:30) || (qualityHint != empty)) ::<= {
          state.quality = if (qualityHint == empty)
            ItemQuality.getRandomWeighted(
              knockout : if (world.island.tier > world.MAX_NORMAL_TIER) (world.island.tier  - world.MAX_NORMAL_TIER)*1.4              
            )
          else 
            ItemQuality.find(id:qualityHint);
          state.stats.add(stats:state.quality.equipMod);
          state.price += (state.price * (state.quality.pricePercentMod/100));            
        }
      }
      

      if (base.hasTraits(:TRAIT.METAL)) ::<= {
        if (materialHint == empty) ::<= {
          state.material = Material.getRandomWeightedFiltered(
            filter::(value) <- value.tier <= world.island.tier,
            knockout : if (world.island.tier > world.MAX_NORMAL_TIER) (world.island.tier  - world.MAX_NORMAL_TIER)*1.4
          );
        } else ::<= {
          state.material = Material.find(id:materialHint);        
        }
        state.stats.add(stats:state.material.statMod);
      }

      if (base.hasTraits(:TRAIT.APPAREL)) ::<= {
        if (apparelHint == empty) ::<= {
          state.apparel = ApparelMaterial.getRandomWeightedFiltered(
            filter::(value) <- value.tier <= world.island.tier,
            knockout : if (world.island.tier > world.MAX_NORMAL_TIER) (world.island.tier  - world.MAX_NORMAL_TIER)*1.4
          );
        } else ::<= {
          state.apparel = ApparelMaterial.find(id:apparelHint);        
        }
        state.stats.add(stats:state.apparel.statMod);
      }        

      
      if (base.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS)) ::<= {
        if (enchantHint != empty) ::<= {
          this.addEnchant(mod:ItemEnchant.new(
            base:ItemEnchant.database.find(id:enchantHint)
          ));
        }

        
        if (state.needsAppraisal == false && rngEnchantHint != empty && (random.try(percentSuccess:25) || forceEnchant)) ::<= {
          @enchantCount = if (forceEnchantCount) forceEnchantCount else random.integer(from:1, to:match(world.island.tier) {
            (6, 7, 8, 9, 10):  8,
            (3,4,5):  4,
            (1, 2):  2,
            (0): 1,
            default: ((world.island.tier**0.5) * 3.3)->floor
          });
          
          
          
          for(0, enchantCount)::(i) {
            @mod = ItemEnchant.new(
              base:
              if (random.try(percentSuccess:25)) 
                ItemEnchant.database.find(id:'base:soul')
              else
                ItemEnchant.database.getRandomFiltered(
                  filter::(value) <- 
                  value.tier <= world.island.tier 
                )
            )
            this.addEnchant(mod);
          }
        }
      }


      if (base.hasTraits(:TRAIT.HAS_COLOR)) ::<= {
        state.color = if (colorHint) ItemColor.find(id:colorHint) else ItemColor.getRandom();
        state.stats.add(stats:state.color.equipMod);
        state.design = if (designHint) ItemDesign.find(id:designHint) else ItemDesign.getRandom();
        state.stats.add(stats:state.design.equipMod);
      }
            
      
      

      if (state.material != empty) 
        state.price += state.price * (state.material.pricePercentMod / 100);
        
      state.price = (state.price)->ceil;
      
      if (state.needsAppraisal) ::<= {
        state.price = 1;
      }      
      
      
      base.onCreate(item:this, creationHint);
      recalculateName(*_);
      
      return this;
      
    },
     

    base : {
      get :: {
        return _.state.base;
      }
    },
    
      
    name : {
      get :: {
        when (_.state.customName != '') _.state.customName;
        return _.state.base.name;
      },
      
      set ::(value => String)  {
        _.state.customPrefix = value;
        recalculateName(*_);
      }
    },
    
    needsAppraisal : {
      get :: <-  _.state.needsAppraisal
    },

    appraisalCount : {
      get :: <- _.state.appraisalCount,
      set ::(value => Number) {
        _.state.appraisalCount = value
      }
    },
    
    // returns a new item representing the appraisal.
    // appraisals always have:
    appraise ::{
      @:Material = import(module:'game_database.material.mt');
      @:ApparelMaterial = import(module:'game_database.apparelmaterial.mt');
      @:ItemQuality = import(module:'game_database.itemquality.mt');
      @:Arts = import(module:'game_database.arts.mt');
      @:base = _.state.base;
      @:item = Item.new(
        base,
        forceEnchantCount: random.integer(from:3, to:7),
        forceEnchant : true,
        rngEnchantHint : true,
        forceNeedsAppraisal : false,
        artsHint : [
          Arts.getRandomFiltered(::(value) <- value.kind == Arts.KIND.ABILITY && ((value.traits & Arts.TRAITS.SPECIAL) == 0)).id,
          Arts.getRandomFiltered(::(value) <- value.kind == Arts.KIND.ABILITY && ((value.traits & Arts.TRAITS.SPECIAL) == 0)).id,
          Arts.getRandomFiltered(::(value) <- value.kind == Arts.KIND.ABILITY && ((value.traits & Arts.TRAITS.SPECIAL) == 0)).id
        ],
        qualityHint : if ((base.traits & TRAIT.HAS_QUALITY) != 0) ItemQuality.getRandom().id,
        materialHint : if ((base.traits & TRAIT.METAL) != 0) Material.getRandom().id,
        apparelHint : if ((base.traits & TRAIT.APPAREL) != 0) ApparelMaterial.getRandom().id
      );
      item.name = random.pickArrayItem(:keyQualifiers) + ' ' + base.name;
      _.state.appraisalCount += 1;
      return item;
    },
    
    quality : {
      get ::<- _.state.quality,
      set ::(value) {
        @:state = _.state;
        if (state.quality != empty) ::<= {
          state.stats.subtract(stats:state.quality.equipMod);
          state.price -= (state.price * (state.quality.pricePercentMod/100));
        }
        state.quality = value;
        state.stats.add(stats:state.quality.equipMod);
        state.price += (state.price * (state.quality.pricePercentMod/100));

        recalculateName(*_);
      }
    },
      
    enchantsCount : {
      get ::<- _.state.enchants->keycount
    },
      
    equipMod : {
      get ::<- _.state.stats
    },
    
    equipModBase : {
      get ::<- _.state.statsBase
    },

    arts : {
      get ::<- if (_.state.arts == empty) empty else _.state.arts
    },
      
    equipEffects : {
      get ::<- _.state.equipEffects
    },
      
      
    setIslandGenTraits ::(levelHint, nameHint, tierHint, extraLandmarks, idHint) {
      @:state = _.state;
      if (levelHint)  
        state.islandLevelHint = levelHint;
      if (nameHint)
        state.islandNameHint = nameHint;
        
      if (tierHint != empty)
        state.islandTierHint = tierHint;
        
      if (extraLandmarks != empty)
        state.islandExtraLandmarks = extraLandmarks;
        
      if (idHint != empty)
        state.islandIDhint = idHint;
    },
    
    islandGenTraits : {
      get ::{ 
        @:Island = import(:'game_mutator.island.mt');
        return {
          levelHint: _.state.islandLevelHint,
          nameHint: _.state.islandNameHint,
          tierHint: _.state.islandTierHint,
          extraLandmarks: _.state.islandExtraLandmarks,
          base : Island.database.find(:_.state.islandIDhint)
        }
      }
    },
    
    islandID : {
      get ::<- _.state.islandID,
      set ::(value)<- _.state.islandID = value
    },
      
    data : {
      get ::<- _.state.data
    },
      
      
            
    throwOut :: {
      _.state.base = Item.database.find(:'base:none');
    },
      
    color : {
      get ::<- _.state.color
    },
      
    price : {
      get ::<-_.state.price,
      set ::(value) <- _.state.price = value
    },
    
      
    material : {
      get ::<- _.state.material
    },
      
    addEnchant::(mod) {
      @:state = _.state;
      when (state.enchants->keycount >= state.base.enchantLimit) empty;
      state.enchants->push(value:mod);
      foreach(mod.equipEffects)::(i, effect) {
        state.equipEffects->push(value:effect);
      }
      state.stats.add(stats:mod.base.equipMod);
      //if (description->contains(key:mod.description) == false)
      //  description = description + mod.description + ' ';
      recalculateName(*_);
      state.price += mod.base.priceMod;
      state.price = state.price->ceil;
    },
      
    description : {
      get :: {
        @:state = _.state;
        return calculateDescription(*_);
      }
    },
      
    commitEffectEvent ::(*args) {
      @:state = _.state;
      @:this = _.this;
      args.item = this;
      foreach(state.enchants)::(i, enchant) {
        enchant.processEvent(*args);
      }
    },
    
    improvementsLeft : {
      get::<- _.state.improvementsLeft
    },

    improvements : {
      get::<- _.state.improvements,
    },
    
    improvementEXP : {
      get ::<- _.state.improvementEXP
    },
    
    improvementEXPtoNext : {
      get ::<- _.state.improvementEXPtoNext
    },

    improve ::(exp) {
      @:state = _.state;
      @:chunk = if (_.state.improvementEXP + exp > _.state.improvementEXPtoNext) 
        state.improvementEXPtoNext - _.state.improvementEXP
      else 
        exp;

      state.improvementEXP += chunk;
      exp -= chunk;
      @leveled = false;
      if (state.improvementEXPtoNext == state.improvementEXP) ::<= {
        state.improvements += 1;
        state.improvementsLeft -= 1;
        if (state.improvementsLeft < 0)
            state.improvementsLeft = 0;
        state.improvementEXPtoNext = expToNextLevel(:state.improvements)->floor;
        state.improvementEXP = 0;
        leveled = true;
      }
      
      if (leveled)
        recalculateName(*_);
      return exp;
    },
    
    useEffects : {
      get ::<- _.state.useEffects,
      set ::(value) <- _.state.useEffects = value
    },
      
    describe ::(by) {
      @:state = _.state;
      @:this = _.this;
      @:Effect = import(module:'game_database.effect.mt');
      windowEvent.queueMessageSet(
        speakers : [
          this.name + ': Description',
          this.name + ': Enchantments',
          this.name + ': Equip Stats',
          this.name + ': Equip Effects',
          this.name + ': Use Effects'
        ],
        set : [
          this.description,
          
          if (state.enchants->keycount != 0) ::<= {
            @out = '';
            when (state.enchants->keycount == 0) 'None.';
            foreach(state.enchants)::(i, mod) {
              out = out + romanNum(value:i+1) + ' - ' + mod.description + '\n';
            }
            return out;
          } else '',
          
          String.combine(:state.stats.descriptionRateLinesBase(:state.statsBase)->map(::(value) <- value + '\n')),          

          if (state.equipEffects->keycount != 0) ::<= {
            @out = '';
            when (state.equipEffects->keycount == 0) 'None.';
            foreach(state.equipEffects)::(i, effect) {
              out = out + '. ' + Effect.find(id:effect).description + '\n';
            }
            return out;
          } else '',     
          
          if (state.useEffects->size > 0) ::<= {
            @out = '';
            when (state.useEffects->keycount == 0) 'None.';
            foreach(state.useEffects)::(i, effect) {
              @:eff = Effect.find(id:effect);
              out = out + ' - ' + eff.name + ': ' + eff.description + '\n';
            }
            return out;
          } else '',
            
        ],
        pageAfter:canvas.height-4
      )
      if (by != empty) ::<= {
        when(by.profession.weaponAffinity != state.base.name) empty;
        windowEvent.queueMessage(
          speaker:by.name,
          pageAfter:canvas.height-4,
          text:'Oh! This weapon type really works for me as ' + correctA(word:by.profession.name) + '.'
        );  
      }
    },
    
    stats : {
      get ::<- _.state.stats
    },
    
    addIntuition :: {
      _.state.intuition += 1;
    },

    canGainIntuition ::(silent) {
      return _.state.intuition < 20;
    },
    
    worldID : {
      get ::<- _.state.worldID
    },
    
    faveMark : {
      get ::<- _.state.faveMark,
      set ::(value) <- _.state.faveMark = value
    },
      
    maxOut ::{
      _.state.intuition = 20;
      _.state.improvementsLeft = 0;
    }
  }
);


  


return Item;
