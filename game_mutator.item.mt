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
@:InletSet = import(:'game_class.inletset.mt');
@:InletSet = import(:'game_class.inletset.mt');

@:MAX_ENCHANT_GLOBAL = 10;

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


@:SORT_TYPE = {
  WEAPON        : 0,
  ARMOR_CLOTHES : 1,
  ACCESSORIES   : 2, // includes rings and amulets and trinkets
  USABLES       : 3,
  KEYS          : 4,
  INLET         : 5,
  MISC          : 6,
  LOOT          : 7
}



@:TYPE = {
  HAND      : 0,   
  ARMOR     : 1,  
  AMULET    : 2,  
  RING      : 3,  
  TRINKET   : 4,
  TWOHANDED : 5
}
  
@:TRAIT = {
  BLUNT         : 2 << 0,
  SHARP         : 2 << 1,
  FLAT          : 2 << 2,
  SHIELD        : 2 << 3,
  METAL         : 2 << 4,
  FRAGILE       : 2 << 5,
  WEAPON        : 2 << 6,
  STRANGE_TO_EQUIP     : 2 << 7,
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
  CAN_BE_APPRAISED : 2 << 18,
  HAS_INLET_SLOTS : 2 << 19,
  PRICELESS : 2 << 20,
  STRANGE_TO_EQUIP : 2 << 21
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
    sortType : SORT_TYPE.MISC,
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
    sortType : SORT_TYPE.MISC,
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
    onCreate ::(item, creationHint) {},
    possibleArts : [],
  }
)

Item.database.newEntry(data : {
  name : "Mei\'s Bow",
  id: 'base:meis-bow',
  description: 'A neck accessory featuring an ornate bell and bow.',
  examine : '',
  sortType : SORT_TYPE.ACCESSORIES,
  equipType: TYPE.TRINKET,
  rarity : 30000,
  basePrice : 1,
  weight : 0.1,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 0,
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
  sortType : SORT_TYPE.ACCESSORIES,
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
    sortType : SORT_TYPE.USABLES,
    equipType: TYPE.HAND,
    weight : 2,
    rarity : 100,
    basePrice: 40,
    tier: 0,
    levelMinimum : 1,
    enchantLimit : 0,
    useTargetHint : USE_TARGET_HINT.ONE,
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
      TRAIT.MEANT_TO_BE_USED |
      TRAIT.STRANGE_TO_EQUIP
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
  sortType : SORT_TYPE.USABLES,
  equipType: TYPE.HAND,
  weight : 2,
  rarity : 100,
  basePrice: 200,
  tier: 2,
  levelMinimum : 1,
  enchantLimit : 0,
  useTargetHint : USE_TARGET_HINT.ONE,
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
    TRAIT.MEANT_TO_BE_USED |
    TRAIT.STRANGE_TO_EQUIP
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
  sortType : SORT_TYPE.USABLES,
  examine : '',
  equipType: TYPE.HAND,
  weight : 1,
  rarity : 100,
  basePrice: 1050,
  tier: 0,
  levelMinimum : 1,
  enchantLimit : 0,
  useTargetHint : USE_TARGET_HINT.ONE,
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
    TRAIT.MEANT_TO_BE_USED |
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {
    @:Arts = import(module:'game_database.arts.mt');
    @:art = Arts.getRandomFiltered(::(value) <- value.hasTraits(:Arts.TRAIT.COMMON_ATTACK_SPELL));
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
  sortType : SORT_TYPE.MISC,
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
  sortType : SORT_TYPE.MISC,
  equipType: TYPE.HAND,
  basePrice: 13,
  rarity : 100,
  tier: 0,
  weight : 4,
  levelMinimum : 1,
  enchantLimit : 0,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
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
  sortType : SORT_TYPE.MISC,
  equipType: TYPE.TWOHANDED,
  rarity : 100,
  tier: 0,
  weight : 4,
  basePrice: 20,
  levelMinimum : 1,
  enchantLimit : 0,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
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
  sortType : SORT_TYPE.MISC,
  equipType: TYPE.HAND,
  rarity : 100,
  tier: 0,
  weight : 4,
  basePrice: 17,
  levelMinimum : 1,
  enchantLimit : 0,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
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
  name : "Mace",
  id : 'base:bludgeon',
  description: 'A basic blunt weapon. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Clubs and bludgeons seem primitive, but are quite effective.',
  sortType : SORT_TYPE.WEAPON,
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 4,
  basePrice: 70,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS

  ,
  onCreate ::(item, creationHint) {}

})  

Item.database.newEntry(data : {
  name : "Shortsword",
  id : 'base:shortsword',
  description: 'A basic sword. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Swords like these are quite common and are of adequate quality even if simple.',
  equipType: TYPE.HAND,
  sortType : SORT_TYPE.WEAPON,
  rarity : 300,
  weight : 4,
  basePrice: 90,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS


  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Longsword",
  id : 'base:longsword',
  description: 'A basic sword. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Swords like these are quite common and are of adequate quality even if simple.',
  sortType : SORT_TYPE.WEAPON,
  equipType: TYPE.TWOHANDED,
  rarity : 300,
  weight : 4,
  basePrice: 110,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS


  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Blade & Shield",
  id : 'base:blade-and-shield',
  description: 'A matching medium-length blade and shield. They feature a $color$, $design$ design.',
  examine : 'Weapons with shields seem to block more than they let on.',
  equipType: TYPE.TWOHANDED,
  sortType : SORT_TYPE.WEAPON,
  rarity : 400,
  weight : 12,
  basePrice: 250,
  levelMinimum : 1,
  tier: 1,
  enchantLimit : 15,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS

    
  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Wall Shield",
  id : 'base:wall-shield',
  description: 'A large shield that can be used for defending.',
  examine : 'Weapons with shields seem to block more than they let on.',
  sortType : SORT_TYPE.WEAPON,
  equipType: TYPE.TWOHANDED,
  rarity : 400,
  weight : 17,
  basePrice: 350,
  levelMinimum : 1,
  tier: 2,
  enchantLimit : 15,
  useTargetHint : USE_TARGET_HINT.ONE,

  // fatigued
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS

    
  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Chakram",
  id : 'base:chakram',
  description: 'A pair of round blades. The handles have a $color$ trim with a $design$ design.',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS


  ,
  onCreate ::(item, creationHint) {}

})  

Item.database.newEntry(data : {
  name : "Blade Pair",
  id : 'base:dual-blades',
  description: 'A pair of short blades. The hilts have a $color$ trim with a $design$ design.',
  examine : '.',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS


  ,
  onCreate ::(item, creationHint) {}

}) 

Item.database.newEntry(data : {
  name : "Falchion",
  id : 'base:falchion',
  description: 'A basic sword with a large blade. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Swords like these are quite common and are of adequate quality even if simple.',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS


  ,
  onCreate ::(item, creationHint) {}

})  


Item.database.newEntry(data : {
  name : "Morning Star",
  id : 'base:morning-star',
  description: 'A spiked weapon. The hilt has a $color$ trim with a $design$ design.',
  examine : '',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS


  ,
  onCreate ::(item, creationHint) {}

})   

Item.database.newEntry(data : {
  name : "Scimitar",
  id : 'base:scimitar',
  description: 'A basic sword with a curved blade. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Swords like these are quite common and are of adequate quality even if simple.',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS
  ,
  onCreate ::(item, creationHint) {}

}) 


Item.database.newEntry(data : {
  name : "Rapier",
  id : 'base:rapier',
  description: 'A slender sword excellent for thrusting. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Swords like these are quite common and are of adequate quality even if simple.',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS
  ,
  onCreate ::(item, creationHint) {}

})  


Item.database.newEntry(data : {
  name : "Bow & Quiver",
  id : 'base:bow-and-quiver',
  description: 'A basic bow and quiver full of arrows. The bow features a $design$ design and has a streak of $color$ across it.',
  sortType : SORT_TYPE.WEAPON,
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
    //'base:doublestrike',
    //'base:triplestrike',
    'base:precise-strike',
    'base:tranquilizer'
  ],

  // fatigued
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS

  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Crossbow",
  id : 'base:crossbow',
  description: 'A mechanical device that launches bolts. It features a $color$, $design$ design design.',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS

  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Greatsword",
  id : 'base:greatsword',
  description: 'A basic, large sword. The hilt has a $color$ trim with a $design$ design.',
  examine : 'Not as common as shortswords, but rather easy to find. Favored by larger warriors.',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS

  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Dagger",
  id : 'base:dagger',
  description: 'A basic knife. The handle has an $color$ trim with a $design$ design.',
  examine : 'Commonly favored by both swift warriors and common folk for their easy handling and easiness to produce.',
  sortType : SORT_TYPE.WEAPON,
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 1,
  tier: 0,
  basePrice: 35,
  enchantLimit : 10,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,

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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS

  ,
  onCreate ::(item, creationHint) {}

})  

Item.database.newEntry(data : {
  name : "Knuckle",
  id : 'base:knuckle',
  description: 'Designed to be worn on the fists for close combat. It has an $color$ trim with a $design$ design.',
  examine : '',
  sortType : SORT_TYPE.WEAPON,
  equipType: TYPE.HAND,
  rarity : 300,
  weight : 0.5,
  tier: 0,
  basePrice: 35,
  enchantLimit : 10,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,

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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS

  ,
  onCreate ::(item, creationHint) {}

})  


Item.database.newEntry(data : {
  name : "Smithing Hammer",
  id : 'base:smithing-hammer',
  description: 'A basic hammer meant for smithing.',
  examine : 'Easily available, this hammer is common as a general tool for metalworking.',
  sortType : SORT_TYPE.MISC,
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
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS
  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Lance",
  id : 'base:lance',
  description: 'A weapon with long reach and deadly power. The handle has a $color$ trim with a $design$ design.',
  examine : '',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS
  ,
  onCreate ::(item, creationHint) {}

})  

Item.database.newEntry(data : {
  name : "Glaive",
  id : 'base:glaive',
  description: 'A weapon with long reach and deadly power. The handle has a $color$ trim with a $design$ design.',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS
  ,
  onCreate ::(item, creationHint) {}

})  


Item.database.newEntry(data : {
  name : "Staff",
  id :  'base:staff',
  description: 'A combat staff. Promotes fluid movement when used well. The ends are tied with a $color$ fabric, featuring a $design$ design.',
  examine : '',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS
  ,
  onCreate ::(item, creationHint) {}

})  


Item.database.newEntry(data : {
  name : "Mage-Staff",
  id : 'base:mage-staff',
  description: 'Similar to a wand, promotes mental acuity. The handle has a $color$ trim with a $design$ design.',
  examine : '',
  equipType: TYPE.TWOHANDED,
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS
  ,
  onCreate ::(item, creationHint) {}

}) 

Item.database.newEntry(data : {
  name : "Wand",
  id : 'base:wand',
  description: 'The handle has a $color$ trim with a $design$ design.',
  examine : '',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS
  ,
  onCreate ::(item, creationHint) {}

})  



Item.database.newEntry(data : {
  name : "Warhammer",
  id : 'base:warhammer',
  description: 'A hammer meant for combat with a $design$ design. The end is tied with a $color$ fabric.',
  examine : 'A common choice for those who wish to cause harm and have the arm to back it up.',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS
  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Battelaxe",
  id : 'base:battleaxe',
  description: 'An axe meant for combat with a $design$ design. The end is tied with a $color$ fabric.',
  examine : 'A common choice for those who wish to cause harm and have the arm to back it up.',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS
  ,
  onCreate ::(item, creationHint) {}

})



Item.database.newEntry(data : {
  name : "Tome",
  id : 'base:tome',
  sortType : SORT_TYPE.WEAPON,
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS
  ,
  onCreate ::(item, creationHint) {}
  
})

Item.database.newEntry(data : {
  name : "Tunic",
  id : 'base:tunic',
  description: 'Simple cloth for the body with a $design$ design. It is predominantly $color$.',
  examine : 'Common type of light armor',
  equipType: TYPE.ARMOR,
  sortType : SORT_TYPE.ARMOR_CLOTHES,
  rarity : 100,
  weight : 1,
  levelMinimum : 1,
  tier: 0,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 100,
  possibleArts : [],

  // fatigued
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS  
  ,
  onCreate ::(item, creationHint) {}
  
})


Item.database.newEntry(data : {
  name : "Robe",
  id : 'base:robe',
  description: 'Simple cloth favored by scholars. It features a $color$, $design$ design.',
  examine : 'Common type of light armor',
  sortType : SORT_TYPE.ARMOR_CLOTHES,
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
    TRAIT.HAS_COLOR  |
    TRAIT.HAS_INLET_SLOTS  
  ,
  onCreate ::(item, creationHint) {}
  
})

Item.database.newEntry(data : {
  name : "Scarf",
  id : 'base:scarf',
  description: 'Simple cloth accessory. It is $color$ with a $design$ design.',
  examine : 'Common type of light armor',
  sortType : SORT_TYPE.ACCESSORIES,
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
  sortType : SORT_TYPE.ACCESSORIES,
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
  sortType : SORT_TYPE.ACCESSORIES,
  basePrice: 3000,
  enchantLimit : 10,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,

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
  sortType : SORT_TYPE.ACCESSORIES,
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
  sortType : SORT_TYPE.ACCESSORIES,
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
  sortType : SORT_TYPE.ACCESSORIES,
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
  sortType : SORT_TYPE.ACCESSORIES,
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
  sortType : SORT_TYPE.ARMOR_CLOTHES,
  rarity : 350,
  weight : 1,
  tier: 1,
  levelMinimum : 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 350,
  possibleArts : [],

  // fatigued
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS  
  ,
  onCreate ::(item, creationHint) {}
  
})  


Item.database.newEntry(data : {
  name : "Chainmail",
  id : 'base:chainmail',
  description: 'Mail made of linked chains. It bears an emblem colored $color$ with a $design$ design.',
  examine : 'Common type of light armor',
  sortType : SORT_TYPE.ARMOR_CLOTHES,
  equipType: TYPE.ARMOR,
  rarity : 350,
  weight : 3,
  levelMinimum : 1,
  tier: 1,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 200,
  possibleArts : [],

  // fatigued
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS  
  ,
  onCreate ::(item, creationHint) {}
  
})

Item.database.newEntry(data : {
  name : "Filigree Armor",
  id : 'base:filigree-armor',
  description: 'Hardened material with a fancy $color$ trim and a $design$ design.',
  examine : 'Common type of light armor',
  sortType : SORT_TYPE.ARMOR_CLOTHES,
  equipType: TYPE.ARMOR,
  rarity : 500,
  weight : 5,
  levelMinimum : 1,
  enchantLimit : 10,
  tier: 2,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 350,
  possibleArts : [],

  // fatigued
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
    TRAIT.HAS_COLOR|
    TRAIT.HAS_INLET_SLOTS  
  ,
  onCreate ::(item, creationHint) {}
  
})
  
Item.database.newEntry(data : {
  name : "Plate Armor",
  id : 'base:plate-armor',
  description: 'Extremely protective armor of a high-grade. It has a $color$ trim with a $design$ design.',
  examine : 'Highly skilled craftspeople are required to make this work.',
  sortType : SORT_TYPE.ARMOR_CLOTHES,
  equipType: TYPE.ARMOR,
  rarity : 500,
  weight : 9,
  levelMinimum : 1,
  tier: 3,
  enchantLimit : 10,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 400,
  possibleArts : [],

  // fatigued
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
    TRAIT.HAS_COLOR |
    TRAIT.HAS_INLET_SLOTS  
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




Item.database.newEntry(data : {
  name : "Ingot",
  id : 'base:ingot',
  description: 'An ingot of pure material.',
  examine : '',
  sortType : SORT_TYPE.MISC,
  equipType: TYPE.TWOHANDED,
  rarity : 150,
  weight : 10,
  tier: 0,
  basePrice: 20,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  possibleArts : [],

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
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {
    @:Material = import(:'game_database.material.mt');
    @:world = import(module:'game_singleton.world.mt');


    @:mat = Material.getRandomFiltered(::(value) <- value.tier <= world.island.tier);
    item.name = mat.name + ' Ingot';
    item.data.RAW_MATERIAL = mat.id;
    item.price += (((mat.tier)**1.4) * 240)->ceil;
  }

})    

Item.database.newEntry(data : {
  name : "Bank Stone",
  id : 'base:storage-stone',
  description: 'A small magic stone that, when used, allows sending and receiving items from a storage location.',
  examine : '',
  sortType : SORT_TYPE.USABLES,
  equipType: TYPE.HAND,
  rarity : 200,
  weight : 2,
  tier: 0,
  basePrice: 600,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.NONE,
  possibleArts : [],

  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:access-bank',
    'base:consume-item'
  ],
  equipEffects : [],
  traits : 
    TRAIT.STACKABLE |
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {
  }

})  



Item.database.newEntry(data : {
  name : "Escape Stone",
  id : 'base:escape-stone',
  description: 'A small magic stone that, when used, allows escaping from dungeons.',
  examine : '',
  sortType : SORT_TYPE.USABLES,
  equipType: TYPE.HAND,
  rarity : 200,
  weight : 2,
  tier: 0,
  basePrice: 100,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.NONE,
  possibleArts : [],

  equipMod : StatSet.new(
    ATK: 2, // well. its hard!
    DEF: 2, // well. its hard!
    SPD: -10,
    DEX: -20
  ),
  useEffects : [
    'base:escape',
    'base:consume-item'
  ],
  equipEffects : [],
  traits : 
    TRAIT.STACKABLE |
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {
  }

})   


Item.database.newEntry(data : {
  name : "Ore",
  id : 'base:ore',
  description: "Raw ore. It's hard to tell exactly what kind of metal it is.",
  examine : 'Could be smelted into...',
  sortType : SORT_TYPE.MISC,
  equipType: TYPE.TWOHANDED,
  rarity : 100,
  weight : 5,
  tier: 0,
  enchantLimit : 0,
  levelMinimum : 100000,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 5,
  possibleArts : [],

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
    TRAIT.UNIQUE |
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {}

}) 

Item.database.newEntry(data : {
  name : "Gold Pouch",
  id : 'base:gold-pouch',
  description: "A pouch of coins.",
  examine : '',
  sortType : SORT_TYPE.USABLES,
  equipType: TYPE.HAND,
  rarity : 100,
  weight : 5,
  tier: 0,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 1000,
  possibleArts : [],

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
    TRAIT.MEANT_TO_BE_USED |
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
  name : "Perfect Arts Crystal",
  id : 'base:perfect-arts-crystal',
  description: "Extremely rare irridescent crystal that imparts knowledge when used. The skills required to make this have been lost to time.",
  examine : 'Not much else is known about these.',
  equipType: TYPE.HAND,
  sortType : SORT_TYPE.USABLES,
  rarity : 100,
  weight : 3,
  tier: 10,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 3000,
  possibleArts : [],

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
    TRAIT.MEANT_TO_BE_USED |
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {}

})


Item.database.newEntry(data : {
  name : "Arts Crystal",
  id : 'base:arts-crystal',
  description: "Irridescent crystal that imparts knowledge when used.",
  examine : 'Quite sought after, highly skilled mages usually produce them for the public.',
  equipType: TYPE.HAND,
  sortType : SORT_TYPE.USABLES,
  rarity : 100,
  weight : 3,
  tier: 0,
  enchantLimit : 0,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 600,
  possibleArts : [],

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
    TRAIT.MEANT_TO_BE_USED |  
    TRAIT.STRANGE_TO_EQUIP
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
  sortType : SORT_TYPE.MISC,
  equipType: TYPE.TWOHANDED,
  rarity : 3000,
  weight : 10,
  tier: 0,
  enchantLimit : 0,
  levelMinimum : 10000000,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 175,
  possibleArts : [],

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
    TRAIT.STACKABLE |
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {}

}) 


Item.database.newEntry(data : {
  name : "Ingredient",
  id : 'base:ingredient',
  description: "A pack of ingredients used for potions and brews.",
  examine : 'Common ingredients used by alchemists.',
  sortType : SORT_TYPE.MISC,
  equipType: TYPE.TWOHANDED,
  rarity : 300000000,
  weight : 1,
  tier: 0,
  enchantLimit : 0,
  levelMinimum : 10000000,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 5,
  possibleArts : [],

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
    TRAIT.UNIQUE |
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {}

}) 


Item.database.newEntry(data : {
  name : "Book",
  id : 'base:book',
  description: "A book containing writing. It can be read it to see its contents.",
  examine : 'Common ingredients used by alchemists.',
  sortType : SORT_TYPE.USABLES,
  equipType: TYPE.TWOHANDED,
  rarity : 39,
  weight : 2,
  tier: 0,
  enchantLimit : 40,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 30,
  possibleArts : [],

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
    TRAIT.MEANT_TO_BE_USED |
    TRAIT.STRANGE_TO_EQUIP
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
  sortType : SORT_TYPE.USABLES,
  description: "Permanently increases a base stat.",
  examine : 'Its abilities are unknown.',
  equipType: TYPE.TWOHANDED,
  rarity : 500,
  weight : 1,
  tier: 4,
  enchantLimit : 40,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 10000,
  possibleArts : [],

  equipMod : StatSet.new(
  ),
  useEffects : [
    'base:seed',
    'base:consume-item'     
  ],
  equipEffects : [],
  traits :     
    TRAIT.MEANT_TO_BE_USED |
    TRAIT.UNIQUE |
    TRAIT.STRANGE_TO_EQUIP
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


Item.database.newEntry(data : {
  name : "Wyvern Flower",
  id : 'base:wyvern-flower',
  sortType : SORT_TYPE.USABLES,
  description: "A mysterious and extremely rare plant. It is said that, when used, unlocks the potential of the user. Otherwise, its abilities are unknown.",
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

  equipMod : StatSet.new(
  ),
  useEffects : [
    'base:wyvern-flower',
    'base:consume-item'     
  ],
  equipEffects : [],
  traits :     
    TRAIT.MEANT_TO_BE_USED |
    TRAIT.UNIQUE |
    TRAIT.PRICELESS |
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {
  }
}) 


Item.database.newEntry(data : {
  name : "Ethereal Shard",
  id : 'base:item-box',
  description: "Its abilities are unknown.",
  examine : 'Its abilities are unknown.',
  sortType : SORT_TYPE.LOOT,
  equipType: TYPE.TWOHANDED,
  rarity : 500,
  weight : 0,
  tier: 999,
  enchantLimit : 40,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 10,
  possibleArts : [],

  equipMod : StatSet.new(
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits :     
    TRAIT.UNIQUE |
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {
  }
}) 


::<= {
@:crystals = {
  'Teal'     : ['SPD', 'DEX'],
  'Lavender' : ['DEX', 'ATK'],
  'Orange'   : ['ATK', 'DEF'],
  'Indigo'   : ['INT', 'DEF'],
  'Rose'     : ['INT', 'SPD'],
  'Cyan'     : ['ATK', 'SPD'],
  'White'    : ['DEF', 'SPD'],
  'Violet'   : ['DEX', 'DEF'],
  'Scarlet'  : ['DEX', 'INT'],
  'Crimson'  : ['ATK', 'INT'],
}
Item.database.newEntry(data : {
  name : "Crystal",
  id : 'base:inlet-crystal',
  description: "An enchanted alchemical crystal. When set in slots on equipment, it can rebalance stats.",
  examine : 'Its abilities are unknown.',
  sortType : SORT_TYPE.INLET,
  equipType: TYPE.HAND,
  rarity : 500,
  weight : 0.1,
  tier: 0,
  enchantLimit : 40,
  levelMinimum : 1,
  useTargetHint : USE_TARGET_HINT.ONE,
  basePrice: 10000,
  possibleArts : [],

  equipMod : StatSet.new(
  ),
  useEffects : [
  ],
  equipEffects : [],
  traits : 
    TRAIT.STRANGE_TO_EQUIP
  ,
  onCreate ::(item, creationHint) {
    @:kind = random.pickArrayItem(:crystals->keys);
    
    @:statsA = {
      ATK: -1,
      DEX: -1,
      SPD: -1,
      DEF: -1,
      INT: -1      
    }
    foreach(crystals[kind]) ::(k, v) {
      statsA[v] = 2;
    }
    @desc = item.base.description + ": ";
    foreach(statsA) ::(k, v) {
      when (k == crystals[kind][0]) empty;
      when (k == crystals[kind][1]) empty;
      desc = desc + k + ',';
    }      
    desc = desc + ' base -1, ' + crystals[kind][0] + ',' + crystals[kind][1] + ' base +2';
    //item.setOverrideDescription(:desc);
    item.setUpInlet(
      stats : StatSet.new(*statsA)
    );
    @:InletSet = import(:'game_class.inletset.mt');  
    item.name = kind + ' Crystal '/*(' +
      (match(item.inletShape) {
        (InletSet.SLOTS.ROUND) : 'round',
        (InletSet.SLOTS.TRIANGLE) : 'triangular',
        (InletSet.SLOTS.SQUARE) : 'square'
      }) + ')'*/
    
  }
})   
}





::<= {

@:gems = {
  'Morion'     : ['SPD', 'DEX'],
  'Amethyst'   : ['DEX', 'ATK'],
  'Citrine'    : ['ATK', 'DEF'],
  'Garnet'     : ['INT', 'DEF'],
  'Praesolite' : ['INT', 'SPD'],
  'Aquamarine' : ['ATK', 'SPD'],
  'Diamond'    : ['DEF', 'SPD'],
  'Pearl'      : ['DEX', 'DEF'],
  'Ruby'       : ['DEX', 'INT'],
  'Sapphire'   : ['SPD', 'ATK'],
  'Opal'       : ['ATK', 'INT']
  
}

Item.database.newEntry(
  data : {
    name : 'Gemstone',
    id : 'base:inlet-gem',
    description: "An enchanted gemstone. When set in slots on equipment, it can rebalance stats.",
    examine : 'Its abilities are unknown.',
    sortType : SORT_TYPE.INLET,
    equipType: TYPE.HAND,
    rarity : 500,
    weight : 0.1,
    tier: 2,
    enchantLimit : 40,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 30000,
    possibleArts : [],

    equipMod : StatSet.new(
    ),
    useEffects : [
    ],
    equipEffects : [],
    traits : 
      TRAIT.STRANGE_TO_EQUIP
    ,
    onCreate ::(item, creationHint) {
      @:kind = random.pickArrayItem(:gems->keys);
      
      @:statsA = {
        ATK: -2,
        DEX: -2,
        SPD: -2,
        DEF: -2,
        INT: -2      
      }
      foreach(gems[kind]) ::(k, v) {
        statsA[v] = 5;
      }
      @desc = item.base.description + ": ";
      foreach(statsA) ::(k, v) {
        when (k == gems[kind][0]) empty;
        when (k == gems[kind][1]) empty;
        desc = desc + k + ',';
      }      
      desc = desc + ' base -2, ' + gems[kind][0] + ',' + gems[kind][1] + ' base +5';
      //item.setOverrideDescription(:desc);
      
      item.setUpInlet(
        stats : StatSet.new(*statsA)
      );

      @:InletSet = import(:'game_class.inletset.mt');
      item.name = kind /*+ ' (' +
        (match(item.inletShape) {
          (InletSet.SLOTS.ROUND) : 'round',
          (InletSet.SLOTS.TRIANGLE) : 'triangular',
          (InletSet.SLOTS.SQUARE) : 'square'
        }) + ')';*/
      item.setUpInlet(
        stats : StatSet.new(*statsA)
      );
    }
  }
)
}


Item.database.newEntry(
  data : {
    name : 'Soul Gem',
    id : 'base:inlet-soulgem',
    description: "",
    examine : 'Its abilities are unknown.',
    sortType : SORT_TYPE.INLET,
    equipType: TYPE.HAND,
    rarity : 500,
    weight : 0.1,
    tier: 4,
    enchantLimit : 40,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 70000,
    possibleArts : [],

    equipMod : StatSet.new(
    ),
    useEffects : [
    ],
    equipEffects : [],
    traits : 
      TRAIT.STRANGE_TO_EQUIP
    ,
    onCreate ::(item, creationHint) {
      @:Effect = import(module:'game_database.effect.mt');
      @:effect = Effect.getRandomFiltered(::(value) <- value.hasNoTrait(:Effect.TRAIT.INSTANTANEOUS | Effect.TRAIT.SPECIAL));
      item.setUpInlet(
        effect : effect.id
      );
      
      item.setOverrideDescription(
        : "A soul gem which grants the effect " + effect.name + ":" + effect.description
      )

      @:InletSet = import(:'game_class.inletset.mt');
      item.name = effect.name + ' Soul Gem ' /*(' +
        (match(item.inletShape) {
          (InletSet.SLOTS.ROUND) : 'round',
          (InletSet.SLOTS.TRIANGLE) : 'triangular',
          (InletSet.SLOTS.SQUARE) : 'square'
        }) + ')';*/
    }
  }
)


  
  
::<= {

  Item.database.newEntry(data : {
    name : "Wyvern Key",
    id : 'base:wyvern-key',
    description: 'A key to another island. The key is huge, dense, and requires 2 hands to wield. In fact, it is so large and sturdy that it could even be wielded as a weapon in dire circumstances.',
    examine : '',
    sortType : SORT_TYPE.KEYS,
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
      TRAIT.HAS_COLOR |
      TRAIT.STRANGE_TO_EQUIP
    ,
    onCreate ::(item, user, creationHint) {
      @:world = import(module:'game_singleton.world.mt');
      @:Island = import(:'game_mutator.island.mt');
      @tier = if (world != empty && world.island != empty) world.island.tier + random.integer(from:1, to:4) else 0;

      if (creationHint->type == Object) ::<= {
        if (creationHint.tier->type == Number) 
          tier = creationHint.tier
      }

      @:story = import(:'game_singleton.story.mt');
      @:capitalize = import(:'game_function.capitalize.mt');
      item.name = random.pickArrayItem(:keyQualifiers) + ' Key (Tier '+ tier + ')';
      item.price += 4420 * tier;
      item.setIslandGenTraits(
        levelHint : story.levelHint + (tier * 1.4),
        tierHint : tier,
        idHint : Island.database.getRandomFiltered(::(value) <- (value.traits & Island.TRAIT.SPECIAL) == 0).id
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
    if (state.coreDescription != '') state.coreDescription else base.description,
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
  ]);
  if (base.hasTraits(:TRAIT.HAS_COLOR)) ::<= {
    out = out->replace(key:'$color$', with:state.color.name);
    out = out->replace(key:'$design$', with:state.design.name);
  }
  return out;
}

@:getStars::(item) {
  when (item.data.stars != empty)
    item.data.stars;
  
  @:price = Item.BUY_PRICE_MULTIPLIER * item.price;
  when(item.base.id == 'base:none') 0;
  when(price < 40)     1;
  when(price < 90)     2;
  when(price < 150)    3;
  when(price < 300)    4;
  when(price < 700)    5;
  when(price < 1200)   6;
  when(price < 2400)   7;
  when(price < 5000)   8;
  when(price < 8000)   9;
  when(price < 10000)  10;
  when(price < 100000) 11;
  return 12;
}

@:starsToString::(item) {
  when (item.needsAppraisal) '???';
  @out = ''
  @stars = getStars(item);
  for(0, stars) ::(i) {
    if (i%5 == 0 && i > 0)
      out = out + ' '  
    out = out + '*';
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
    SORT_TYPE : {get ::<- SORT_TYPE},
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
    appraisalCount : 0,
    inletData : empty,
    inletSlotData : empty,
    coreDescription : '',
    forceEnchantCount : -1
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
      possibleArts : Object,
      sortType : Number,
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
      if (forceEnchantCount != empty)
        state.forceEnchantCount = forceEnchantCount;
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
        when (enchantHint != empty) ::<= {
          foreach(enchantHint) ::(k, v) {
            this.addEnchant(mod:ItemEnchant.new(
              base:ItemEnchant.database.find(id:v)
            ));
          }
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
              if (world.island.tier > 1 && random.try(percentSuccess:25)) 
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
      
      if (base.hasTraits(:TRAIT.PRICELESS))
        state.price = 999999 / Item.BUY_PRICE_MULTIPLIER;
      
      
      
      if (base.hasTraits(:TRAIT.HAS_INLET_SLOTS)) ::<= {
        @:slotCount = match(tier) {
          (0):
            random.pickArrayItem(:[
              0, 0, 0, 0, 1
            ]),
          (1): 
            random.pickArrayItem(:[
              0, 0, 1, 1, 1, 2, 3
            ]),
            
          (2): random.integer(from:0, to:4),
          (3): random.integer(from:1, to:5),
          default: random.integer(from:2, to:7)
        }
        
        if (slotCount > 0) ::<= {
          state.price += 400**(1+0.1*slotCount);
          state.inletSlotData = import(:'game_class.inletset.mt').new(size:slotCount);          
        }
      }
      
      base.onCreate(item:this, creationHint);
      recalculateName(*_);

      
      return this;
      
    },
    boxUp ::{
      when(_.this.base.id == 'base:item-box') 
        _.this;
      @:box = Item.new(
        base: Item.database.find(:'base:item-box')
      );
      box.data.boxed = _.this.save();
      box.data.stars = getStars(:_.this);
      box.name = 'Ethereal Shard';
      return box;
    },
    
    unbox :: {
      @:this = _.this;
      if (_.state.base.id != 'base:item-box')
        error(:'Tried to unbox something that isnt a box. Not good!!!');

      // shouldnt happen, but we can cope with it
      when (_.state.data.boxed == empty) 
        Item.new(
          id: Item.database.getRandomFiltered(::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE | Item.TRAIT.KEY_ITEM))
        );
      
        
        
      @:a = Item.new(base:Item.database.find(id:'base:none'));
      a.load(:_.state.data.boxed);
      return a;
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
          Arts.getRandomFiltered(::(value) <- value.kind == Arts.KIND.ABILITY && ((value.traits & Arts.TRAIT.SPECIAL) == 0)).id,
          Arts.getRandomFiltered(::(value) <- value.kind == Arts.KIND.ABILITY && ((value.traits & Arts.TRAIT.SPECIAL) == 0)).id,
          Arts.getRandomFiltered(::(value) <- value.kind == Arts.KIND.ABILITY && ((value.traits & Arts.TRAIT.SPECIAL) == 0)).id
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
      get ::{ 
        when(_.state.inletSlotData == empty)_.state.statsBase
        @:out = StatSet.new();
        out.add(:_.state.statsBase);
        out.add(:_.state.inletSlotData.stats);
        return out;
      }
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
    
    enchantLimit : {
      get ::{
        @:state = _.state;
        when (state.forceEnchantCount != -1) state.forceEnchantCount;
        @a = state.base.enchantLimit;
        @b = if (state.apparel == empty ) MAX_ENCHANT_GLOBAL else state.apparel.enchantLimit;
        @c = if (state.material == empty) MAX_ENCHANT_GLOBAL else state.material.enchantLimit;
        
        return if (a < b) 
          if (a < c)
            a 
          else
            c
        else 
          if (c < b)
            c 
          else 
            b
      }
    },
      
    addEnchant::(mod) {
      @:state = _.state;
      @:enchLimit = _.this.enchantLimit;
      
      when (state.enchants->keycount >= enchLimit) false;

      state.enchants->push(value:mod);
      foreach(mod.equipEffects)::(i, effect) {
        state.equipEffects->push(value:effect);
      }
      state.statsBase.add(stats:mod.equipModBase);
      //if (description->contains(key:mod.description) == false)
      //  description = description + mod.description + ' ';
      recalculateName(*_);
      state.price += mod.base.priceMod;
      state.price = state.price->ceil;
      return true;
    },
      
    description : {
      get :: {
        @:state = _.state;
        return calculateDescription(*_);
      }
    },
    
    setOverrideDescription ::(text) {
      _.state.coreDescription = text;
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
    
    stars : {
      get ::<- getStars(:_.this)
    },
    
    starsString : {
      get ::<- starsToString(:_.this)
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
          this.name + ': Description'
        ],
        set : [
          this.description + '\n\nValue: ' + starsToString(:this),
        ]
      );
      
      if (this.enchantLimit > 0 && ((this.base.traits & Item.TRAIT.CAN_HAVE_ENCHANTMENTS) != 0))    
        windowEvent.queueReader(
          prompt: this.name + ': Enchantments',
          lines :            
            
            ::<= {
            
              @column0 = [];
              @column1 = [];
              @column2 = [];
              @:LIMIT_DESCRIPT_LENGTH = 40;

              for(0, this.enchantLimit) ::(i) {
                column0->push(:'(' + romanNum(value:i+1) + ')');
                when(state.enchants[i] == empty) ::<= {
                  column1->push(:'----');
                  column2->push(:'----');
                }

                column1->push(:state.enchants[i].name);
                  
                @:desc = state.enchants[i].description;
                when(desc->length < LIMIT_DESCRIPT_LENGTH) ::<= {
                  column2->push(:desc);
                  return empty;
                }


                @:descLines = canvas.refitLines(input:[desc], maxWidth:LIMIT_DESCRIPT_LENGTH)
                column2->push(:descLines[0]);
                descLines->remove(:0);
                
   
                // tricky! add dummy lines to give the illusion
                foreach(descLines) ::(k, line) {
                  column0->push(:'');
                  column1->push(:'');
                  column2->push(:line);
                } 
              }
              

              return canvas.columnsToLines(
                columns : [
                  column0,
                  column1,
                  column2
                ],
                spacing:2
              )
            }

        );
        
        
      windowEvent.queueMessageSet(
        speakers : [
          this.name + if (this.inletStats != empty) ': Gem stats' else ': Equip Stats',
          this.name + ': Use Effects'
        ],
        set : [
          
          String.combine(:
            if (this.inletStats != empty)
              [
                'Gem shape: ' + InletSet.SLOT_NAMES[this.inletShape] + '\n', 
                ...this.inletStats.descriptionAugmentLines->map(::(value) <- value + '\n')
              ]
            else
              state.stats.descriptionRateLinesBase(:this.equipModBase)->map(::(value) <- value + '\n')
          ),
          
          if (state.useEffects->size > 0) ::<= {
            @out = '';
            when (state.useEffects->keycount == 0) 'None.';
            foreach(state.useEffects)::(i, effect) {
              @:eff = Effect.find(id:effect);
              out = out + ' - ' + eff.name + ': ' + eff.description + '\n';
            }
            return out;
          } else '',
            
        ]
      )
      
      if (state.inletSlotData)
        state.inletSlotData.queueShowBasic();
      
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
      get :: {
        when (_.state.inletData == empty) _.state.stats;
        @out = _.state.stats.clone();
        out.add(:_.state.inletData.stats);
        return out;
      }
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
    
    setUpInlet ::(stats, effect) {
      @:InletSet = import(:'game_class.inletset.mt');
      _.state.inletData = {
        stats : if (stats == empty) StatSet.new() else stats,
        slot  : random.pickArrayItem(:InletSet.SLOTS->values),
        effect : effect
      }
    },
    
    inletStats : {
      get ::{ 
        when (_.state.inletData == empty) empty;
        return _.state.inletData.stats;
      }
    },

    inletShape : {
      get ::{ 
        when (_.state.inletData == empty) -1;
        return _.state.inletData.slot;
      }
    },

    inletEffect : {
      get ::{ 
        when (_.state.inletData == empty) empty;
        return _.state.inletData.effect;
      }
    },

    
    inletGetDescriptionLines :: {
      @:Effect = import(module:'game_database.effect.mt');
      when(_.state.inletData == empty) [];
      when(_.state.inletData.effect != empty) [
        'Grants the effect "' + Effect.find(:_.state.inletData.effect).name + '": ',
        '',
        Effect.find(:_.state.inletData.effect).description
      ]
      
      
      
      return [
        'Grants base stats: ',
        ...(_.state.inletData.stats.descriptionAugmentLines)
      ]
    },
    
    
    inletSlotSet : {
      get ::<- _.state.inletSlotData
    },
      
    maxOut ::{
      _.state.intuition = 20;
      _.state.improvementsLeft = 0;
    }
  }
);


  


return Item;
