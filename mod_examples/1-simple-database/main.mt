@:Item = import(module:'game_mutator.item.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:StatSet = import(module:'game_class.statset.mt');
/*
    Example 1
    
    This is a complete mod that introduces a new Item to the Item database.
    If this mod is active, it will add it to all scenarios.
    
    

*/

return {
    // This is called right when the mod is first loaded, after 
    // the "loadFirst" mods have loaded, if any.
    onGameStartup ::{
        // itll be annoying for a user if you prompt this every time a mod loads.
        // Its more common to do checking and initial work needed, as this is run once per 
        // game invocation.
        windowEvent.queueMessage(
            text: 'Frying pan has been loaded.'
        );
    },

    // This is called right when a player starts to choose or loads 
    // a scenario. This happens after the base database items 
    // are loaded, so this is most commonly used for modifying 
    // databases.
    onDatabaseStartup ::{
        Item.database.newEntry(data : {
            // Base name of the item.
            name : "Frying Pan",

            // A unique ID. Usually this is prefixed with the mod ID to guarantee uniqueness.            
            id: 'mod.example.rasa.simplescenario:frying-pan',

            // Regular description of the item. Note the $color$ and $design$ tokens.
            description: 'A frying pan usually used for cooking. The handle has a $color$ trim with a $design$ design.',

            // Extended description, which may be used from time to time.
            examine : 'Frying pans are usually not used for combat, but there are exceptions...',

            // Where its equipped.
            equipType: Item.TYPE.HAND,
            
            // The relative rarity of the item. Look at game item rarities to get a feel. 
            // Higher number means more rare.
            rarity : 50,

            // Whether the $color$ tag should be assigned. Item colors slightly modify the stats 
            // as well.
            canBeColored : true,
            
            // Whether the item is a key item, meaning its special or has plot significance.
            // This can be used to prevent throwing out an item.
            keyItem : false,
            
            // How heavy the item is. This affects the price and some other aspects.
            weight : 6,
            
            // The base price of the item.
            basePrice: 65,
            
            // The minimum level.
            levelMinimum : 1,
            
            // The first tier where this should be introduced and appear.
            tier: 0,
            
            // Whether the item can vary in size. This slightly affects stats and 
            // adds an additional description note.
            hasSize : true,
            
            // Whether the item can be enchanted.
            canHaveEnchants : true,
            
            // Whether the item can have trigger enchantments.
            canHaveTriggerEnchants : true,
            
            // The max number of enchantments than the item can have.
            enchantLimit : 10,
            
            // Whether the item has an item quality associated with it/
            hasQuality : true,
            
            // Whether the item can come in different materials.
            hasMaterial : true,
            
            // Whether the item is wearable. Has certain effects.
            isApparel : false,
            
            // Hint to whether the item is unique.
            isUnique : false,
            
            // Hint to how the item can be used.
            useTargetHint : Item.USE_TARGET_HINT.ONE,

            // The percent additional to the Entity stats when equipped.
            equipMod : StatSet.new(
                ATK: 35,
                DEF: 25,
                SPD: -15
            ),
            
            // The effects that occur, in order, when used as an item.
            useEffects : [
                'base:fling',
            ],
            
            // The abilities that are possible when making an item. Only one of them is 
            // chosen for an item instance.
            possibleAbilities : [
                "base:doublestrike",
                "base:stun"
            ],

            // Additional effects, by name, that are passively active when equipping the item.
            equipEffects : [],
            
            // Hints to the item 
            attributes : 
                Item.ATTRIBUTE.BLUNT |
                Item.ATTRIBUTE.METAL |
                Item.ATTRIBUTE.WEAPON
            ,
            
            // Special function to call for additional maintenance when creating the item for the first time.
            onCreate ::(item, creationHint) {}
        })  
    }      
}
