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
    HAND       : 0,   
    ARMOR      : 1,    
    AMULET     : 2,    
    RING       : 3,    
    TRINKET    : 4,
    TWOHANDED  : 5
}
    
@:ATTRIBUTE = {
    BLUNT     : 1,
    SHARP     : 2,
    FLAT      : 4,
    SHIELD    : 8,
    METAL     : 16,
    FRAGILE   : 32,
    WEAPON    : 64,
    RAW_METAL : 128
}

@:USE_TARGET_HINT = {
    ONE     : 0,    
    GROUP   : 1,
    ALL     : 2,
    NONE    : 3
}

@:SIZE = {
    SMALL : 0,
    TINY : 1,
    AVERAGE : 2,
    LARGE : 3,
    BIG : 4
}







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
        isUnique : true,
        weight: 0,
        rarity: 100,
        levelMinimum : 1,
        tier: 0,
        keyItem : false,
        basePrice: 0,
        canHaveEnchants : false,
        canHaveTriggerEnchants : false,
        enchantLimit : 0,
        hasQuality : false,
        hasMaterial : false,
        isApparel : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        useEffects : [],
        equipEffects : [],
        attributes : 0,
        canBeColored : false,
        hasSize : false,
        blockPoints : 0,
        onCreate ::(item, creationHint) {},
        possibleAbilities : [],
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
    keyItem : false,
    weight : 0.1,
    levelMinimum : 1,
    tier: 0,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 0,
    blockPoints : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,
    isUnique : true,
    canBeColored : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    hasSize : false,
    onCreate ::(item, creationHint) {},
    possibleAbilities : [],
    
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
    attributes : ATTRIBUTE.FRAGILE    
})

Item.database.newEntry(data : {
    name : "Life Crystal",
    id : 'base:life-crystal',
    description: 'A shimmering amulet. The metal enclosure has a $color$ tint. If death befalls the holder, has a 50% chance to revive them. It breaks in the process of revival.',
    examine : '',
    equipType: TYPE.AMULET,
    rarity : 30000,
    basePrice : 5000,
    keyItem : false,
    weight : 2,
    levelMinimum : 1,
    tier: 0,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : true,
    canBeColored : true,
    useTargetHint : USE_TARGET_HINT.ONE,
    hasSize : false,
    onCreate ::(item, creationHint) {},
    possibleAbilities : [],
    
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
    attributes : ATTRIBUTE.FRAGILE    
})


Item.database.newEntry(data : {
    name : "Pink Potion",
    id : 'base:pink-potion',
    description: 'Pink-colored potions are known to be for recovery of injuries',
    examine : 'Potions like these are so common that theyre often unmarked and trusted as-is. The hue of this potion is distinct.',
    equipType: TYPE.HAND,
    weight : 2,
    rarity : 100,
    canBeColored : false,
    keyItem : false,
    basePrice: 20,
    tier: 0,
    levelMinimum : 1,
    hasSize : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    canHaveEnchants : false,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,
    isUnique : false,        
    useTargetHint : USE_TARGET_HINT.ONE,
    blockPoints : 0,
    equipMod : StatSet.new(
        SPD: -2, // itll slow you down
        DEX: -10   // its oddly shaped.
    ),
    useEffects : [
        'base:hp-recovery-all',
        'base:consume-item'       
    ],
    possibleAbilities : [],
    equipEffects : [
    ],
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, creationHint) {}


})


Item.database.newEntry(data : {
    name : "Purple Potion",
    id : 'base:purple-potion',
    description: 'Purple-colored potions are known to combine the effects of pink and cyan potions',
    examine : 'These potions are handy, as the effects of ',
    equipType: TYPE.HAND,
    weight : 2,
    rarity : 100,
    canBeColored : false,
    hasSize : false,
    keyItem : false,
    tier: 0,
    basePrice: 100,
    levelMinimum : 1,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,
    isUnique : false,        
    possibleAbilities : [],
    useTargetHint : USE_TARGET_HINT.ONE,
    blockPoints : 0,
    equipMod : StatSet.new(
        SPD: -2, // itll slow you down
        DEX: -10   // its oddly shaped.
    ),
    useEffects : [
        'base:hp-recovery-all',
        'base:ap-recovery-all',
        'base:consume-item'       
    ],
    equipEffects : [
    ],
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, creationHint) {}


})    

Item.database.newEntry(data : {
    name : "Green Potion",
    id : 'base:green-potion',
    description: 'Green-colored potions are known to be toxic.',
    examine : 'Often used offensively, these potions are known to be used as poison once used and doused on a target.',
    equipType: TYPE.HAND,
    weight : 2,
    rarity : 100,
    canBeColored : false,
    keyItem : false,
    basePrice: 20,
    tier: 0,
    levelMinimum : 1,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,
    isUnique : false,        
    hasSize : false,
    possibleAbilities : [],
    useTargetHint : USE_TARGET_HINT.ONE,
    blockPoints : 0,
    equipMod : StatSet.new(
        SPD: -2, // itll slow you down
        DEX: -10   // its oddly shaped.
    ),
    useEffects : [
        'base:poisoned',
        'base:consume-item'       
    ],
    equipEffects : [
    ],
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, creationHint) {}


})    

Item.database.newEntry(data : {
    name : "Orange Potion",
    id : 'base:orange-potion',
    description: 'Orange-colored potions are known to be volatile.',
    examine : 'Often used offensively, these potions are known to explode on contact.',
    equipType: TYPE.HAND,
    weight : 2,
    rarity : 100,
    canBeColored : false,
    keyItem : false,
    basePrice: 20,
    levelMinimum : 1,
    tier: 0,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasSize : false,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,
    isUnique : false,        
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [],
    blockPoints : 0,
    equipMod : StatSet.new(
        SPD: -2, // itll slow you down
        DEX: -10   // its oddly shaped.
    ),
    useEffects : [
        'base:explode',
        'base:consume-item'       
    ],
    equipEffects : [
    ],
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, creationHint) {}
})    


Item.database.newEntry(data : {
    name : "Black Potion",
    id : 'base:black-potion',
    description: 'Black-colored potions are known to be toxic to all organic life.',
    examine : 'Often used offensively, these potions are known to cause instant petrification.',
    equipType: TYPE.HAND,
    weight : 2,
    rarity : 100,
    canBeColored : false,
    keyItem : false,
    basePrice: 20,
    tier: 0,
    levelMinimum : 1,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,
    hasSize : false,
    isUnique : false,        
    possibleAbilities : [],
    useTargetHint : USE_TARGET_HINT.ONE,
    blockPoints : 0,
    equipMod : StatSet.new(
        SPD: -2, // itll slow you down
        DEX: -10   // its oddly shaped.
    ),
    useEffects : [
        'base:petrified',
        'base:consume-item'       
    ],
    equipEffects : [
    ],
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, creationHint) {}


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
    possibleAbilities : [],
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
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, creationHint) {}


})
*/



Item.database.newEntry(data : {
    name : "Cyan Potion",
    id : 'base:cyan-potion',
    description: 'Cyan-colored potions are known to be for recovery of mental fatigue.',
    examine : 'Potions like these are so common that theyre often unmarked and trusted as-is. The hue of this potion is distinct.',
    equipType: TYPE.HAND,
    rarity : 100,
    weight : 2,        
    basePrice: 20,
    canBeColored : false,
    tier: 0,
    keyItem : false,
    levelMinimum : 1,
    hasSize : false,
    hasMaterial : false,
    isApparel : false,
    isUnique : false,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    possibleAbilities : [],
    useTargetHint : USE_TARGET_HINT.ONE,
    blockPoints : 0,
    equipMod : StatSet.new(
        SPD: -2, // itll slow you down
        DEX: -10   // its oddly shaped.
    ),
    useEffects : [
        'base:ap-recovery-all',
        'base:consume-item'       
    ],
    equipEffects : [
    ],
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, creationHint) {}


})

Item.database.newEntry(data : {
    name : "Pitchfork",
    id : 'base:pitchfork',
    description: 'A common farming implement.',
    examine : 'Quite sturdy and pointy, some people use these as weapons.',
    equipType: TYPE.HAND,
    rarity : 100,
    basePrice: 10,        
    canBeColored : false,
    tier: 0,
    keyItem : false,
    weight : 4,
    levelMinimum : 1,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    hasSize : true,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
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
    keyItem : false,
    canBeColored : false,
    tier: 0,
    weight : 4,
    hasSize : true,
    levelMinimum : 1,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
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
    possibleAbilities : [
        'base:stun'
    ],
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
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
    keyItem : false,
    tier: 0,
    weight : 4,
    canBeColored : false,
    basePrice: 20,
    levelMinimum : 1,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : true,
    hasSize : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
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
    possibleAbilities : [
        'base:stab'
    ],


    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
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
    canBeColored : false,
    keyItem : false,
    tier: 0,
    weight : 4,
    basePrice: 17,
    levelMinimum : 1,
    hasSize : true,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
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
    possibleAbilities : [
        'base:stab'
    ],

    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
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
    canBeColored : true,
    keyItem : false,
    weight : 4,
    basePrice: 70,
    levelMinimum : 1,
    tier: 0,
    hasSize : true,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
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
    possibleAbilities : [
        'base:doublestrike',
        'base:triplestrike',
        'base:stun'
    ],

    equipEffects : [],
    attributes : 
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    weight : 4,
    basePrice: 90,
    levelMinimum : 1,
    tier: 0,
    hasSize : true,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
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
    possibleAbilities : [
        'base:stab',
        'base:doublestrike',
        'base:triplestrike',
        'base:stun'
    ],

    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    weight : 4,
    basePrice: 110,
    levelMinimum : 1,
    tier: 0,
    hasSize : true,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
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
    possibleAbilities : [
        'base:stab',
        'base:stun'
    ],

    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    weight : 12,
    basePrice: 250,
    levelMinimum : 1,
    tier: 1,
    hasSize : true,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 15,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
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
    possibleAbilities : [
        'base:counter',
        'base:stun',
        'base:leg-sweep'
    ],

    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP  |
        ATTRIBUTE.METAL  |
        ATTRIBUTE.SHIELD |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    weight : 17,
    basePrice: 350,
    levelMinimum : 1,
    tier: 2,
    hasSize : true,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 15,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
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
    possibleAbilities : [
        'base:counter',
        'base:stun',
        'base:leg-sweep'
    ],

    equipEffects : [],
    attributes : 
        ATTRIBUTE.BLUNT  |
        ATTRIBUTE.METAL  |
        ATTRIBUTE.SHIELD |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    weight : 4,
    tier: 3,
    basePrice: 200,
    levelMinimum : 1,
    hasSize : true,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    weight : 8,
    tier: 3,
    basePrice: 350,
    levelMinimum : 1,
    hasSize : true,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    weight : 4,
    basePrice: 150,
    levelMinimum : 1,
    tier: 1,
    hasSize : true,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    weight : 4,
    basePrice: 150,
    levelMinimum : 1,
    tier: 1,
    hasSize : true,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    weight : 4,
    basePrice: 150,
    levelMinimum : 1,
    hasSize : true,
    tier: 2,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    weight : 4,
    basePrice: 120,
    hasSize : true,
    tier: 2,
    levelMinimum : 1,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    keyItem : false,
    weight : 2,
    hasSize : true,
    canBeColored : true,
    basePrice: 76,
    levelMinimum : 1,
    tier: 0,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.WEAPON            
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
    keyItem : false,
    weight : 10,
    hasSize : true,
    canBeColored : true,
    basePrice: 76,
    levelMinimum : 1,
    tier: 3,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.WEAPON            
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
    hasSize : true,
    keyItem : false,
    canBeColored : true,
    basePrice: 87,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON    
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
    hasSize : true,
    tier: 0,
    canBeColored : true,
    keyItem : false,
    basePrice: 35,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
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
    possibleAbilities : [
        'base:stab',
        'base:doublestrike',
        'base:triplestrike'
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON

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
    canBeColored : false,
    keyItem : false,
    basePrice: 30,
    tier: 0,
    levelMinimum : 1,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasSize : true,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL

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
    canBeColored : true,
    keyItem : false,
    basePrice: 105,
    hasSize : true,
    tier: 2,
    levelMinimum : 1,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    weight : 8,
    canBeColored : true,
    keyItem : false,
    basePrice: 105,
    hasSize : true,
    tier: 0,
    levelMinimum : 1,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    basePrice: 105,
    hasSize : true,
    tier: 1,
    levelMinimum : 1,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    basePrice: 40,
    levelMinimum : 1,
    hasSize : true,
    tier: 1,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    hasSize : true,
    canBeColored : true,
    keyItem : false,
    basePrice: 100,
    levelMinimum : 1,
    tier: 1,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
        'base:fire',
        'base:ice',
        'base:thunder',
        'base:flare',
        'base:frozen-flame',
        'base:explosion',
        'base:flash',
        'base:cure',
        'base:greater-cure',
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    weight : 8,
    keyItem : false,
    basePrice: 100,
    levelMinimum : 1,
    hasSize : true,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    tier: 2,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
        'base:fire',
        'base:ice',
        'base:thunder',
        'base:flare',
        'base:frozen-flame',
        'base:explosion',
        'base:flash',
        'base:cure',
        'base:greater-cure'
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    keyItem : false,
    canBeColored : true,
    levelMinimum : 1,
    hasSize : true,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    basePrice: 200,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    tier: 2,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    keyItem : false,
    levelMinimum : 1,
    tier: 0,
    hasSize : false,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 220,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
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
    canBeColored : true,
    hasSize : false,
    keyItem : false,
    levelMinimum : 1,
    tier: 0,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : false,
    isApparel : true,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 100,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        DEF: 5,
        SPD: 5
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
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
    hasSize : false,
    canBeColored : true,
    tier: 0,
    keyItem : false,
    levelMinimum : 1,
    canHaveEnchants : true,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : false,
    isApparel : true,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 100,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        DEF: 5,
        INT: 5
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
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
    canBeColored : true,
    hasSize : false,
    keyItem : false,
    tier: 2,
    levelMinimum : 1,
    canHaveEnchants : true,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : false,
    isApparel : true,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 40,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        DEF: 3
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
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
    canBeColored : true,
    hasSize : false,
    keyItem : false,
    levelMinimum : 1,
    tier: 2,
    canHaveEnchants : true,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : false,
    isApparel : true,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 40,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        DEF: 3
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
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
    hasSize : true,
    tier: 2,
    canBeColored : true,
    keyItem : false,
    basePrice: 100,
    canHaveEnchants : true,
    canHaveTriggerEnchants : true,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
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
    possibleAbilities : [
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.METAL
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
    hasSize : false,
    canBeColored : true,
    keyItem : false,
    levelMinimum : 1,
    tier: 2,
    canHaveEnchants : true,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : false,
    isApparel : true,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 105,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        DEF: 3
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
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
    hasSize : false,
    canBeColored : true,
    keyItem : false,
    levelMinimum : 1,
    tier: 2,
    canHaveEnchants : true,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : false,
    isApparel : true,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 55,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        SPD: 3,
        DEX: 5
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
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
    canBeColored : true,
    hasSize : false,
    keyItem : false,
    levelMinimum : 1,
    tier: 2,
    canHaveEnchants : true,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : false,
    isApparel : true,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 10,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        DEF: 3
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
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
    hasSize : false,
    canBeColored : true,
    keyItem : false,
    tier: 3,
    levelMinimum : 1,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 200,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        DEF: 15,
        SPD: -10
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.METAL
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
    canBeColored : true,
    tier: 1,
    hasSize : false,
    keyItem : false,
    levelMinimum : 1,
    canHaveEnchants : true,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : false,
    isApparel : true,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 350,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        DEF: 23,
        INT: 15
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
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
    canBeColored : true,
    keyItem : false,
    hasSize : false,
    levelMinimum : 1,
    tier: 1,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 200,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        DEF: 40,
        SPD: -10
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL
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
    canBeColored : true,
    hasSize : false,
    keyItem : false,
    levelMinimum : 1,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    tier: 2,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 350,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        DEF: 55,
        ATK: 10,
        SPD: -10
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL
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
    canBeColored : true,
    keyItem : false,
    levelMinimum : 1,
    hasSize : false,
    tier: 3,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 10,
    hasQuality : true,
    hasMaterial : true,
    isApparel : false,
    isUnique : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 400,
    possibleAbilities : [],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
        DEF: 65,
        ATK: 30,
        SPD: -20
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL
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
    possibleAbilities : [],
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
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
    hasSize : false,
    weight : 5,
    tier: 0,
    canBeColored : false,
    keyItem : false,
    basePrice: 10,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [],

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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, creationHint) {
        item.modData.RAW_MATERIAL = 'base:copper';
    }

})      



Item.database.newEntry(data : {
    name : "Iron Ingot",
    id : 'base:iron-ingot',
    description: 'Iron Ingot',
    examine : 'Pure iron ingot',
    equipType: TYPE.TWOHANDED,
    rarity : 200,
    hasSize : false,
    weight : 5,
    keyItem : false,
    tier: 0,
    canBeColored : false,
    basePrice: 20,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [],
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, creationHint) {
        item.modData.RAW_MATERIAL = 'base:iron';
    }

})   

Item.database.newEntry(data : {
    name : "Steel Ingot",
    id : 'base:steel-ingot',
    description: 'Steel Ingot',
    examine : 'Pure Steel ingot.',
    equipType: TYPE.TWOHANDED,
    hasSize : false,
    rarity : 300,
    tier: 0,
    canBeColored : false,
    weight : 5,
    keyItem : false,
    basePrice: 30,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [],
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, creationHint) {
        item.modData.RAW_MATERIAL = 'base:steel';
    }

})      



Item.database.newEntry(data : {
    name : "Mythril Ingot",
    id : 'base:mythril-ingot',
    description: 'Mythril Ingot',
    examine : 'Pure iron ingot',
    equipType: TYPE.TWOHANDED,
    hasSize : false,
    rarity : 1000,
    tier: 1,
    canBeColored : false,
    weight : 5,
    keyItem : false,
    basePrice: 150,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [],

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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, creationHint) {
        item.modData.RAW_MATERIAL = 'base:mythril';
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
    canBeColored : false,
    hasSize : false,
    weight : 5,
    keyItem : false,
    basePrice: 175,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [],

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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, creationHint) {
        item.modData.RAW_MATERIAL = 'base:quicksilver';
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
    canBeColored : false,
    keyItem : false,
    hasSize : false,
    basePrice: 300,
    tier: 2,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [],

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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, creationHint) {
        item.modData.RAW_MATERIAL = 'base:adamantine';
    }

}) 


Item.database.newEntry(data : {
    name : "Sunstone Ingot",
    id : 'base:substone-ingot',
    description: 'Sunstone alloy ingot',
    examine : 'An alloy with mostly sunstone, it dully shines with a soft yellow gleam',
    equipType: TYPE.TWOHANDED,
    rarity : 300,
    canBeColored : false,
    basePrice: 115,
    keyItem : false,
    hasSize : false,
    weight : 5,
    tier: 2,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [],

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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, creationHint) {
        item.modData.RAW_MATERIAL = 'base:sunstone';
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
    canBeColored : false,
    keyItem : false,
    hasSize : false,
    basePrice: 115,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [],

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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, creationHint) {
        item.modData.RAW_MATERIAL = 'base:moonstone';
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
    canBeColored : false,
    keyItem : false,
    hasSize : false,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    basePrice: 250,
    tier: 2,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [],

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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, creationHint) {
        item.modData.RAW_MATERIAL = 'base:dragonglass';
    }

}) 
Item.database.newEntry(data : {
    name : "Ore",
    id : 'base:ore',
    description: "Raw ore. It's hard to tell exactly what kind of metal it is.",
    examine : 'Could be smelted into...',
    equipType: TYPE.TWOHANDED,
    hasSize : false,
    rarity : 100,
    weight : 5,
    canBeColored : false,
    keyItem : false,
    tier: 0,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 100000,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 5,
    possibleAbilities : [],

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
    attributes : 
        ATTRIBUTE.SHARP
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
    hasSize : false,
    canBeColored : false,
    keyItem : false,
    tier: 0,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 1000,
    possibleAbilities : [],
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
    attributes : 
        ATTRIBUTE.SHARP
    ,
    onCreate ::(item, creationHint) {}

})

Item.database.newEntry(data : {
    name : "Skill Crystal",
    id : 'base:skill-crystal',
    description: "Irridescent crystal that imparts knowledge when used.",
    examine : 'Quite sought after, highly skilled mages usually produce them for the public',
    equipType: TYPE.HAND,
    rarity : 100,
    weight : 3,
    tier: 0,
    canBeColored : false,
    keyItem : false,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasSize : false,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 1,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 600,
    possibleAbilities : [],

    blockPoints : 1,
    equipMod : StatSet.new(
        ATK: 10, // well. its hard!
        DEF: 2, // well. its hard!
        SPD: -10,
        DEX: -20
    ),
    useEffects : [
        'base:learn-skill',
        'base:consume-item'       
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP
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
    isApparel : false,    isUnique : false,
    levelMinimum : 1000000,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 0,
    possibleAbilities : [],

    equipMod : StatSet.new(
        ATK: 2, // well. its hard!
        DEF: 2, // well. its hard!
        SPD: -10,
        DEX: -20
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP
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
    hasSize : false,
    keyItem : false,
    canBeColored : false,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 10000000,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 175,
    possibleAbilities : [],

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
    attributes : 
        ATTRIBUTE.SHARP
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
    hasSize : false,
    keyItem : false,
    tier: 0,
    canBeColored : false,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : false,
    levelMinimum : 10000000,
    useTargetHint : USE_TARGET_HINT.ONE,
    basePrice: 5,
    possibleAbilities : [],

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
    attributes : 0,
    onCreate ::(item, creationHint) {}

}) 


  

Item.database.newEntry(data : {
    name : "Wyvern Key",
    id : 'base:wyvern-key',
    description: 'A key to another island.',
    examine : '',
    equipType: TYPE.TWOHANDED,
    rarity : 100,
    weight : 10,
    canBeColored : false,
    basePrice: 1000,
    keyItem : false,
    hasSize : false,
    tier: 0,
    levelMinimum : 1000000000,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : true,
    useTargetHint : USE_TARGET_HINT.ONE,
    possibleAbilities : [
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
    attributes : 
        ATTRIBUTE.SHARP  |
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {     
    }
    
})    



}

/*
@:Inventory = import(module:'game_class.inventory.mt');
@:ItemEnchant = import(module:'game_mutator.itemenchant.mt');
@:ItemQuality = import(module:'game_database.itemquality.mt');
@:ItemColor = import(module:'game_database.itemcolor.mt');
@:ItemDesign = import(module:'game_database.itemdesign.mt');
@:Material = import(module:'game_database.material.mt');
@:ApparelMaterial = import(module:'game_database.apparelmaterial.mt');
@:Ability = import(module:'game_database.ability.mt');
@:Island = import(module:'game_class.island.mt');
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


@:recalculateName = ::(state) {
    when (state.customPrefix != '')
        state.customName = state.customPrefix + getEnchantTag(state);


    @baseName =
    if (state.base.isApparel && state.apparel)
        state.apparel.name + ' ' + state.base.name
    else if (state.base.hasMaterial && state.material != empty)
        state.material.name + ' ' + state.base.name
    else 
        state.base.name
    ;
    
    state.customName = baseName;
    
        
    @enchantName = getEnchantTag(state);
    
    state.customName = if (state.base.hasQuality && state.quality != empty)
        state.quality.name + ' ' + baseName + enchantName 
    else
        baseName + enchantName;

    if (state.improvementsLeft != state.improvementsStart) ::<= {
        state.customName = state.customName +  '+'+(state.improvementsStart - state.improvementsLeft);
    }


}

@:sizeToString ::(state) <- match(state.size) {
  (SIZE.SMALL)   : 'smaller than expected',
  (SIZE.TINY)    : 'quite small',
  (SIZE.AVERAGE) : 'normally sized',
  (SIZE.LARGE)   : 'larger than expected',
  (SIZE.BIG)     : 'quite large' 
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


@:recalculateDescription ::(this, state){
    @:Ability = import(module:'game_database.ability.mt');
    @:base = this.base;
    state.description = String.combine(strings:[
        base.description,
        ' ',
        (if (state.ability == '') '' else 'If equipped, grants the ability: "' + Ability.find(id:state.ability).name + '". '),
        if (state.size == empty) '' else 'It is ' + sizeToString(state) + '. ',
        if (state.hasEmblem) (
            if (base.isApparel) 
                'The maker\'s emblem is sewn on it. '
            else
                'The maker\'s emblem is engraved on it. '
        ) else 
            '',
        if (base.hasQuality && state.quality != empty) state.quality.description + ' ' else '',
        if (base.hasMaterial) state.material.description + ' ' else '',
        if (base.isApparel) state.apparel.description + ' ' else '',
        if (base.blockPoints == 1) 'This equipment helps block an additional part of the body while equipped in combat.' else '',
        if (base.blockPoints > 1) 'This equipment helps block multiple additional parts of the body while equipped in combat.' else '',
    ]);
    if (base.canBeColored) ::<= {
        state.description = state.description->replace(key:'$color$', with:state.color.name);
        state.description = state.description->replace(key:'$design$', with:state.design.name);
    }
}






@:Item = databaseItemMutatorClass.createLight(
    name : 'Wyvern.Item',    
    items : {
        base : empty,
        enchants : empty, // ItemMod
        quality : empty,
        material : empty,
        apparel : empty,
        customPrefix : '',
        customName : '',
        description : '',
        hasEmblem : false,
        size : 0,
        price : 0,
        color : empty,
        island : empty,
        islandLevelHint : 0,
        islandNameHint : '',
        islandTierHint : 0,
        islandExtraLandmarks : empty,
        improvementsLeft : 0,
        improvementsStart : 0,
        equipEffects : empty,
        useEffects : empty,
        intuition : 0,
        ability : '',
        stats : empty,
        design : empty,
        modData : empty
    },
    
    database : Database.new(
        name: 'Wyvern.Item.Base',
        statics : {
            TYPE : TYPE,
            ATTRIBUTE : ATTRIBUTE,
            USE_TARGET_HINT : USE_TARGET_HINT
        },
        
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
            canHaveEnchants: Boolean,
            canHaveTriggerEnchants : Boolean,
            enchantLimit : Number,
            hasQuality : Boolean,
            hasMaterial : Boolean,
            isApparel : Boolean,
            isUnique : Boolean,
            keyItem : Boolean,
            useEffects : Object,
            equipEffects : Object,
            attributes : Number,
            useTargetHint : Number,
            onCreate : Function,
            basePrice : Number,
            canBeColored: Boolean,
            hasSize : Boolean,
            tier : Number,
            blockPoints : Number,
            possibleAbilities : Object
        
        },
        reset       
    ),
    
    private : {
        container : Nullable,
        equippedBy : Nullable
    },
    
    interface : {
        defaultLoad::(base, creationHint, qualityHint, enchantHint, materialHint, apparelHint, rngEnchantHint, colorHint, designHint, abilityHint, forceEnchant) {
            @:ItemEnchant = import(module:'game_mutator.itemenchant.mt');
            @:ItemQuality = import(module:'game_database.itemquality.mt');
            @:ItemColor = import(module:'game_database.itemcolor.mt');
            @:ItemDesign = import(module:'game_database.itemdesign.mt');
            @:Material = import(module:'game_database.material.mt');
            @:ApparelMaterial = import(module:'game_database.apparelmaterial.mt');
            @:this = _.this;
            @:state = _.state;
            @:world = import(module:'game_singleton.world.mt');

            state.enchants = []; // ItemMod
            state.equipEffects = [];
            state.useEffects = [];
            state.stats = StatSet.new();
            state.ability = ::<= {
                when (abilityHint) abilityHint;
                @:out = random.pickArrayItem(list:base.possibleAbilities);
                when(out == empty) '';
                return out;
            }
            state.base = base;
            state.stats.add(stats:base.equipMod);
            state.price = base.basePrice;
            state.price *= 1.05 * state.base.weight;
            state.improvementsLeft = random.integer(from:10, to:25);
            state.improvementsStart = state.improvementsLeft;
            state.modData = {};
            
            if (base.hasSize)   
                assignSize(*_);
            foreach(base.equipEffects)::(i, effect) {
                state.equipEffects->push(value:effect);
            }

            foreach(base.useEffects)::(i, effect) {
                state.useEffects->push(value:effect);
            }
            
            
            
            if (base.hasQuality) ::<= {
                // random chance to have a maker's emblem on it, indicating 
                // made with love and care
                if (random.try(percentSuccess:15)) ::<= {
                    state.hasEmblem = true;
                    state.stats.add(stats:StatSet.new(
                        ATK:10,
                        DEF:10,
                        SPD:10,
                        INT:10,
                        DEX:10                    
                    ));
                    state.price *= 1.05;
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
            

            if (base.hasMaterial) ::<= {
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

            if (base.isApparel) ::<= {
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

            
            if (base.canHaveEnchants) ::<= {
                if (enchantHint != empty) ::<= {
                    this.addEnchant(mod:ItemEnchant.new(
                        base:ItemEnchant.database.find(id:enchantHint)
                    ));
                }

                
                if (rngEnchantHint != empty && (random.try(percentSuccess:60) || forceEnchant)) ::<= {
                    @enchantCount = random.integer(from:1, to:match(world.island.tier) {
                        (6, 7, 8, 9, 10):    8,
                        (3,4,5):    4,
                        (1, 2):    2,
                        (0): 1,
                        default: ((world.island.tier**0.5) * 3.3)->floor
                    });
                    
                    
                    
                    for(0, enchantCount)::(i) {
                        @mod = ItemEnchant.new(
                            base:ItemEnchant.database.getRandomFiltered(
                                filter::(value) <- value.tier <= world.island.tier && (if (base.canHaveTriggerEnchants == false) value.triggerConditionEffects->keycount == 0 else true)
                            )
                        )
                        this.addEnchant(mod);
                    }
                }
            }


            if (base.canBeColored) ::<= {
                state.color = if (colorHint) ItemColor.find(id:colorHint) else ItemColor.getRandom();
                state.stats.add(stats:state.color.equipMod);
                state.design = if (designHint) ItemDesign.find(id:designHint) else ItemDesign.getRandom();
                state.stats.add(stats:state.design.equipMod);
            }
                        
            
            

            if (state.material != empty) 
                state.price += state.price * (state.material.pricePercentMod / 100);
                
            state.price = (state.price)->ceil;
            
            base.onCreate(item:this, creationHint);
            recalculateDescription(*_);
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
        
        container : {
            get :: {
                return _.container;
            },
            
            set ::(value) {
                @:Inventory = import(module:'game_class.inventory.mt');
                _.container = value => Inventory.type;
            }
        },
            
        equippedBy : {
            set ::(value) {
                _.equippedBy = value;
            },
            
            get ::<- _.equippedBy
        },

        ability : {
            get ::<- if (_.state.ability == '') empty else _.state.ability
        },
            
        equipEffects : {
            get ::<- _.state.equipEffects
        },
            
        islandEntry : {
            set ::(value) {
                @:state = _.state;
                state.island = value;
                state.price *= 1 + ((state.island.levelMin) / (5 + 5*Number.random()));
                state.price = state.price->ceil;
            
            },
            get ::<- _.state.island
        },
            
        setIslandGenAttributes ::(levelHint => Number, nameHint => String, tierHint => Number, extraLandmarks) {
            @:state = _.state;
            state.islandLevelHint = levelHint;
            state.islandNameHint = nameHint;
            state.islandTierHint = tierHint;
            state.islandExtraLandmarks = extraLandmarks;
        },
            
        modData : {
            get ::<- _.state.modData
        },
            
        addIslandEntry ::(world, island) {
            @:state = _.state;
            @:this = _.this;
            when (state.island != empty) empty;

            @:Island = import(module:'game_class.island.mt');


            if (island == empty) ::<= {
                this.islandEntry = Island.new(
                    levelHint: (state.islandLevelHint)=>Number,
                    nameHint: (state.islandNameHint)=>String,
                    tierHint: (state.islandTierHint)=>Number,
                    extraLandmarks: state.islandExtraLandmarks
                );                
            } else 
                this.islandEntry = island;


            
                            
            
            /*
            @:levelToStratum = ::(level) {
                return match((level / 5)->floor) {
                  (0): 'IV',
                  (1): 'III',
                  (2): 'II',
                  (3): 'I',
                  default: 'Unknown'
                }
            }
            state.customName = 'Key to ' + state.island.name + ' - Stratum ' + levelToStratum(level:state.island.levelMin);
            */
        },
            
        resetContainer :: {
            _.container = empty;
        },
                        
        throwOut :: {
            when(_.container == empty) empty;
            _.container.remove(item:_.this);
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
            foreach(mod.base.equipEffects)::(i, effect) {
                state.equipEffects->push(value:effect);
            }
            state.stats.add(stats:mod.base.equipMod);
            //if (description->contains(key:mod.description) == false)
            //    description = description + mod.description + ' ';
            recalculateName(*_);
            state.price += mod.base.priceMod;
            state.price = state.price->ceil;
        },
            
        description : {
            get :: {
                @:state = _.state;
                return state.description + '\nEquip effects: \n' + state.stats.descriptionRate;
            }
        },
            
        onTurnEnd ::(wielder, battle){
            @:state = _.state;
            @:this = _.this;
            foreach(state.enchants)::(i, enchant) {
                enchant.onTurnCheck(wielder, item:this, battle);
            }
        },
        
        improvementsLeft : {
            get::<- _.state.improvementsLeft,
            set::(value) {
                _.state.improvementsLeft = value;
                recalculateName(*_);
            }
        },
            
        describe ::(by) {
            @:state = _.state;
            @:this = _.this;
            @:Effect = import(module:'game_database.effect.mt');
            windowEvent.queueMessage(
                speaker:this.name,
                text:state.description,
                pageAfter:canvas.height-4
            );
            
            if (state.enchants->keycount != 0) ::<= {
                windowEvent.queueMessage(
                    speaker:this.name + ' - Enchantments',
                    pageAfter:canvas.height-4,
                    text:::<={
                        @out = '';
                        when (state.enchants->keycount == 0) 'None.';
                        foreach(state.enchants)::(i, mod) {
                            out = out + romanNum(value:i+1) + ' - ' + mod.description + '\n';
                        }
                        return out;
                    }
                );                
            }                
            
            windowEvent.queueMessage(
                speaker:this.name + ' - Equip Stats',
                text:state.stats.descriptionRate,
                pageAfter:canvas.height-4
            );

            if (state.equipEffects->keycount != 0) ::<= {
                windowEvent.queueMessage(
                    speaker:this.name + ' - Equip Effects',
                    pageAfter:canvas.height-4,
                    text:::<={
                        @out = '';
                        when (state.equipEffects->keycount == 0) 'None.';
                        foreach(state.equipEffects)::(i, effect) {
                            out = out + '. ' + Effect.find(id:effect).description + '\n';
                        }
                        return out;
                    }
                );
            }
            

                            
            windowEvent.queueMessage(
                speaker:_.this.name + ' - Use Effects',
                pageAfter:canvas.height-4,
                text:::<={
                    @out = '';
                    when (state.useEffects->keycount == 0) 'None.';
                    foreach(state.useEffects)::(i, effect) {
                        out = out + '- ' + Effect.find(id:effect).description + '\n';
                    }
                    return out;
                }
            );  


            if (by != empty) ::<= {
                when(by.profession.base.weaponAffinity != state.base.name) empty;
                windowEvent.queueMessage(
                    speaker:by.name,
                    pageAfter:canvas.height-4,
                    text:'Oh! This weapon type really works for me as ' + correctA(word:by.profession.base.name) + '.'
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
            
        maxOut ::{
            _.state.intuition = 20;
            _.state.improvementsLeft = 0;
        }
    }
);


    


return Item;
