@:WyvernGate = import(:'wyvern-gate.mt');

@:Item = WyvernGate.Item
@:StatSet = WyvernGate.Util.StatSet
@:windowEvent = WyvernGate.Core.WindowEvent

return ::{
  Item.database.newEntry(data : {
    name : "Sentimental Box",
    id : 'thechosen:sentimental-box',
    description: 'A box of sentimental value. You feel like you should open it right away.',
    examine : '',
    sortType : Item.SORT_TYPE.USABLES,
    equipType: Item.TYPE.TWOHANDED,
    rarity : 100,
    weight : 10,
    basePrice: 400,
    tier: 0,
    levelMinimum : 1000000000,
    enchantLimit : 0,
    useTargetHint : Item.USE_TARGET_HINT.NONE,
    possibleArts : [
    ],

    // fatigued
    blockPoints : 0,
    equipMod : StatSet.new(
      ATK: 5,
      SPD: -5,
      DEX: -5
    ),
    useEffects : [
      'thechosen:sentimental-box',
    ],
    equipEffects : [],
    traits : 
      Item.TRAIT.SHARP  |
      Item.TRAIT.UNIQUE |
      Item.TRAIT.STRANGE_TO_EQUIP
    ,
    events : {}
    
  })  




  Item.database.newEntry(data : {
    name : "Wyvern Key of Fire",
    id : 'thechosen:wyvern-key-of-fire',
    description: 'A key to another island. Its quite big and warm to the touch.',
    examine : '',
    sortType : Item.SORT_TYPE.KEYS,
    equipType: Item.TYPE.TWOHANDED,
    rarity : 100,
    weight : 10,
    basePrice: 1,
    tier: 0,
    levelMinimum : 1000000000,
    enchantLimit : 0,
    useTargetHint : Item.USE_TARGET_HINT.ONE,
    possibleArts : [
      "base:fire" // for fun!
    ],

    // fatigued
    blockPoints : 2,
    equipMod : StatSet.new(
      ATK: 25,
      SPD: -5,
      DEX: -5
    ),
    useEffects : [
    ],
    equipEffects : [
      "base:burning",
      'base:aspect-fire'
    ],
    traits : 
      Item.TRAIT.SHARP |
      Item.TRAIT.KEY_ITEM |
      Item.TRAIT.UNIQUE
    ,
    events : {
      onCreate ::(item, user, creationHint) {   
      
        @:world = import(module:'base/world.mt');    
        @:nameGen = import(module:'base/namegen.mt');
        @:story = import(module:'base/story.mt');
        @:island = {
          island : empty
        }
        
        item.setIslandGenTraits(
          levelHint:  story.levelHint,
          nameHint:   'Island of Fire',
          tierHint : 0,
          idHint : 'thechosen:island-of-fire'
        );
        
        item.price = 1;
      }
    }
  })

  Item.database.newEntry(data : {
    name : "Wyvern Key of Ice",
    id : 'thechosen:wyvern-key-of-ice',
    description: 'A key to another island. Its quite big and cold to the touch.',
    examine : '',
    sortType : Item.SORT_TYPE.KEYS,
    equipType: Item.TYPE.TWOHANDED,
    rarity : 100,
    weight : 10,
    basePrice: 1,
    tier: 0,
    keyItem : false,
    levelMinimum : 1000000000,
    enchantLimit : 0,
    useTargetHint : Item.USE_TARGET_HINT.ONE,
    possibleArts : [
      "base:ice" // for fun!
    ],

    // fatigued
    blockPoints : 2,
    equipMod : StatSet.new(
      ATK: 25,
      SPD: -5,
      DEX: -5
    ),
    useEffects : [
    ],
    equipEffects : [
      "base:icy",
      'base:aspect-ice'
    ],
    traits : 
      Item.TRAIT.SHARP |
      Item.TRAIT.KEY_ITEM |
      Item.TRAIT.UNIQUE
    ,
    events : {
      onCreate ::(item, user, creationHint) {   
      
        @:world = import(module:'base/world.mt');    
        @:nameGen = import(module:'base/namegen.mt');
        @:story = import(module:'base/story.mt');
        @:island = {
          island : empty
        }

        item.setIslandGenTraits(
          levelHint:  story.levelHint+2,
          nameHint:   'Island of Ice',
          tierHint : 1,
          idHint : 'thechosen:island-of-ice'
        );
        
        item.price = 1;
      }
    }
    
  })  

  Item.database.newEntry(data : {
    name : "Wyvern Key of Thunder",
    id : 'thechosen:wyvern-key-of-thunder',
    description: 'A key to another island. Its quite big and softly hums.',
    examine : '',
    sortType : Item.SORT_TYPE.KEYS,
    equipType: Item.TYPE.TWOHANDED,
    rarity : 100,
    weight : 10,
    basePrice: 1,
    tier: 0,
    levelMinimum : 1000000000,
    enchantLimit : 0,
    useTargetHint : Item.USE_TARGET_HINT.ONE,
    possibleArts : [
      "base:thunder" // for fun!
    ],

    // fatigued
    blockPoints : 2,
    equipMod : StatSet.new(
      ATK: 25,
      SPD: -5,
      DEX: -5
    ),
    useEffects : [
    ],
    equipEffects : [
      "base:shock",
      'base:aspect-thunder'
    ],
    traits : 
      Item.TRAIT.SHARP |
      Item.TRAIT.KEY_ITEM |
      Item.TRAIT.UNIQUE


    ,
    events : {
      onCreate ::(item, user, creationHint) {   
      
        @:world = import(module:'base/world.mt');    
        @:nameGen = import(module:'base/namegen.mt');
        @:story = import(module:'base/story.mt');
        @:island = {
          island : empty
        }

        item.setIslandGenTraits(
          levelHint:  story.levelHint+4,
          nameHint:   'Island of Thunder',
          tierHint : 2,
          idHint : 'thechosen:island-of-thunder'
        );
        
        item.price = 1;
      }
    }
    
  })  

  Item.database.newEntry(data : {
    name : "Wyvern Key of Light",
    id : 'thechosen:wyvern-key-of-light',
    description: 'A key to another island. Its quite big and faintly glows.',
    examine : '',
    sortType : Item.SORT_TYPE.KEYS,
    equipType: Item.TYPE.TWOHANDED,
    rarity : 100,
    weight : 10,
    basePrice: 1,
    tier: 0,
    levelMinimum : 1000000000,
    enchantLimit : 0,
    useTargetHint : Item.USE_TARGET_HINT.ONE,
    possibleArts : [
      "base:explosion", // for fun!
      'base:aspect-light'
    ],

    // fatigued
    blockPoints : 2,
    equipMod : StatSet.new(
      ATK: 25,
      SPD: -5,
      DEX: -5
    ),
    useEffects : [
    ],
    equipEffects : [
      "base:shimmering"
    ],
    traits : 
      Item.TRAIT.SHARP |
      Item.TRAIT.KEY_ITEM|
      Item.TRAIT.UNIQUE

    ,
    events : {
      onCreate ::(item, user, creationHint) {   
      
        @:world = import(module:'base/world.mt');    
        @:nameGen = import(module:'base/namegen.mt');
        @:story = import(module:'base/story.mt');
        @:island = {
          island : empty
        }

        item.setIslandGenTraits(
          levelHint:  story.levelHint+7,
          nameHint:   'Island of Light',
          tierHint : 3,
          idHint : 'thechosen:island-of-light'
        );
        
        item.price = 1;
      }
    }
    
  })   
}
