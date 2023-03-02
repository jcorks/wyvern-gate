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
@:Database = import(module:'class.database.mt');
@:StatSet = import(module:'class.statset.mt');
@:Inventory = import(module:'class.inventory.mt');
@:ItemModifier = import(module:'class.itemmodifier.mt');
@:ItemColor = import(module:'class.itemcolor.mt');
@:Material = import(module:'class.material.mt');
@:random = import(module:'singleton.random.mt');
@:dialogue = import(module:'singleton.dialogue.mt');
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
};
    
@:ATTRIBUTE = {
    BLUNT   : 0,
    SHARP   : 1,
    FLAT    : 2,
    SHIELD  : 3,
    METAL   : 4,
    FRAGILE : 5,
    WEAPON  : 7,
    RAW_METAL     : 8
};

@:USE_TARGET_HINT = {
    ONE     : 0,    
    GROUP   : 1,
    ALL     : 2
};




@:Item = class(
    name : 'Wyvern.Item',
    statics : {
        Base : empty,
        TYPE : TYPE,
        ATTRIBUTE : ATTRIBUTE,
        USE_TARGET_HINT : USE_TARGET_HINT
    },
    define:::(this) {
        @base_;
        @mods = []; // ItemMod
        @material;
        @customName = empty;
        @description;
        @container;
        @price;
        @color;
        @island;
        @islandLevelHint;
        @islandNameHint;
        @victoryCount = 0; // like exp, stat mods increase with victories
                           // conceptually: the user becomes more familiar
                           // with how to effectively use it in their hands
                           // This is only for hand items since it only is 
                           // increased in the hand equip slot.
                           //
                           // Also the item can become enchanted through use 
        @:stats = StatSet.new();
        this.constructor = ::(base, from, creationHint, modHint, materialHint, state) {
            when(state != empty) ::<= {
                this.state = state;
                return this;
            };
            
            
            base_ = base;
            stats.add(stats:base.equipMod);
            description = base.description;
            
            if (base.canHaveModifier) ::<= {
                if (modHint != empty) ::<= {
                    @:mod = ItemModifier.database.find(name:modHint);
                    mods->push(value:mod);
                    customName = base.name + ' (' + mod.name + ')';
                    stats.add(stats:mod.equipMod);
                    description = description + mod.description;
                };

                if (Number.random() > 0.95) ::<= {
                    @:mod = ItemModifier.database.getRandomFiltered(
                        filter:::(value) <- from.level >= value.levelMinimum
                    );
                    mods->push(value:mod);
                    customName = base.name + ' (' + mod.name + ')';
                    stats.add(stats:mod.equipMod);
                    description = description + mod.description;
                };
            };
            

            if (base.canBeColored) ::<= {
                color = ItemColor.database.getRandom();
                stats.add(stats:color.equipMod);
                customName = if (customName) color.name + ' ' + customName else color.name + ' ' + base_.name;
            };
                        
            
            
            if (base.hasMaterial) ::<= {
                if (materialHint == empty) ::<= {
                    material = Material.database.getRandomWeightedFiltered(
                        filter:::(value) <- from.level >= value.levelMinimum
                    );
                } else ::<= {
                    material = Material.database.find(name:materialHint);                
                };

                stats.add(stats:material.statMod);
                if (mods->keycount)
                    customName = material.name + ' ' + customName
                else 
                    customName = material.name + ' ' + base.name;

            };
            
            price = base.basePrice;
            price *= 1.05 * base_.weight;
            mods->foreach(do:::(index, mod) {
                price += (price * (mod.pricePercentMod/100));
            });
            if (material != empty) 
                price += price * (material.pricePercentMod / 100);
                
            price = (price)->ceil;
            
            base.onCreate(item:this, user:from, creationHint);
            
            
            return this;
            
        };
        @:Island = import(module:'class.island.mt');
        @:world = import(module:'singleton.world.mt');
        
        this.interface = {
            base : {
                get :: {
                    return base_;
                }
            },
            
            
            name : {
                get :: {
                    when (customName != empty) customName;
                    return base_.name;
                },
                
                set ::(value => String)  {
                    customName = value;
                }
            },
            
            equipMod : {
                get ::<- stats
            },
            
            container : {
                get :: {
                    return container;
                },
                
                set ::(value => Inventory.type) {
                    container = value;
                }
            },
            
            islandEntry : {
                get ::<- island
            },
            
            setIslandGenAttributes ::(levelHint => Number, nameHint => String, islandHint) {
                islandLevelHint = levelHint;
                islandNameHint = nameHint;
                island = islandHint;
            },
            
            addIslandEntry ::(world) {
                when (island != empty) empty;

                island = world.discoverIsland(
                    levelHint: (islandLevelHint)=>Number,
                    nameHint: (islandNameHint)=>String
                );                
            },
            
            resetContainer :: {
                container = empty;
            },
                        
            throwOut :: {
                when(container == empty) empty;
                container.remove(item:this);
            },
            
            
            price : {
                get ::<-price,
                set ::(value) <- price = value
            },
            
            description : {
                get :: {
                    
                
                    return description + '\nEquip effects: \n' + stats.getRates();
                }
            },
            
            addVictory ::(silent) {
                victoryCount += 1;
                if (victoryCount % 5 == 0) ::<= {
                    @choice = random.integer(from:0, to:7);
                    @:oldStats = StatSet.new();
                    oldStats.add(stats);
                    stats.add(stats:StatSet.new(
                        HP: if (choice == 0) 1 else 0,
                        MP: if (choice == 1) 1 else 0,
                        ATK: if (choice == 2) 1 else 0,
                        DEF: if (choice == 3) 1 else 0,
                        INT: if (choice == 4) 1 else 0,
                        LUK: if (choice == 5) 1 else 0,
                        DEX: if (choice == 6) 1 else 0,
                        SPD: if (choice == 7) 1 else 0
                    ));
                    
                    if (silent == empty) ::<= {
                        dialogue.message(text:'The ' + this.name + ' gets stronger from use.');
                        oldStats.printDiffRate(other:stats, prompt:this.name);
                    };
                
                };
            },
            
            state : {
                set ::(value) {
                    base_ = Item.Base.database.find(name:value.baseName);
                    material = if (value.materialName == empty) empty else Material.database.find(name:value.materialName);
                    victoryCount = value.victoryCount;
                    customName = value.customName;
                    price = value.price;
                    islandLevelHint = value.islandLevelHint;
                    islandNameHint = value.islandNameHint;
                    if (value.island != empty) ::<= {
                        if (world.island.id == value.island.id) 
                            island = world.island  // already handled by current world loading.
                        else
                            island = Island.new(levelHint: 0, world: this, party : world.party, state:value.island);                        
                            
                    } else 
                        island = empty;
                        
                    description = value.description;
                    stats.state = value.stats;
                    value.modNames->foreach(do:::(index, modName) {
                        @:mod = ItemModifier.database.find(name:modName);
                        mods->push(value:mod);
                    });
                },
                get :: {
                    return {
                        baseName : base_.name,
                        materialName : if (material == empty) empty else material.name,
                        victoryCount : victoryCount,
                        customName : customName,
                        price : price,
                        islandLevelHint : islandLevelHint,
                        islandNameHint : islandNameHint,
                        island : if (island != empty && island.id != world.island.id) island.state else empty,
                        description : description,
                        stats : stats.state,
                        modNames : [...mods]->map(to:::(value) <- value.name)
                    };
                }
            }
            
            
            
        };
    
    }
);


Item.Base = class(
    name : 'Wyvern.Item.Base',
    statics : {
        database : empty

    },
    define:::(this) {
        Database.setup(
            item: this,
            attributes : {
                name : String,
                description : String,
                examine : String,
                equipType : Number,
                rarity : Number,
                weight : Number,
                levelMinimum : Number,
                equipMod : StatSet.type,
                canHaveModifier : Boolean,
                hasMaterial : Boolean,
                isUnique : Boolean,
                keyItem : Boolean,
                useEffects : Object,
                equipEffects : Object,
                attributes : Object,
                useTargetHint : Number,
                onCreate : Function,
                basePrice : Number,
                canBeColored: Boolean   
            
            }
        );
        this.interface = {
            new ::(from, creationHint, modHint, materialHint, state) {
                return Item.new(base:this, from, creationHint, modHint, materialHint, state);
            },
            

            
            hasAttribute :: (attribute) {
                return this.attributes->any(condition::(value) <- value == attribute);
            }
        };

    }
);



Item.Base.database = Database.new(items: [
    Item.Base.new(
        data : {
            name : 'None',
            description : '',
            examine : '',
            equipType : TYPE.HAND,
            equipMod : StatSet.new(),
            isUnique : false,
            weight: 0,
            rarity: 100,
            levelMinimum : 1,
            keyItem : false,
            basePrice: 0,
            canHaveModifier : false,
            hasMaterial : false,
            useTargetHint : USE_TARGET_HINT.ONE,
            useEffects : [],
            equipEffects : [],
            attributes : [],
            canBeColored : false,
            onCreate ::(item, user, creationHint) {},
        }
    ),
    Item.Base.new(data : {
        name : "Cat of Bea",
        description: 'A small, white figurine depicting a cat. It smells faintly of strawberry pastries.',
        examine : 'It appears to be entirely white and oddly angular. The bottom side is engraved with the number \'IX\'.',
        equipType: TYPE.TRINKET,
        rarity : 30000,
        basePrice : 30000,
        keyItem : false,
        weight : 0.1,
        levelMinimum : 1,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : true,
        canBeColored : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        onCreate ::(item, user, creationHint) {},
        
        equipMod : StatSet.new(
            DEF: 4,   // 
            INT: 10,  // strawberries are magical probably
            SPD: 8    // because zoomy
        ),
        useEffects : [
            'Fling',
            'Break Item'
        ],
        equipEffects : [
            // Affects whole party:
            // 99% chance -> strawberry shortcake smell (stat boost for turn)
            // 1%  chance -> premonition / subliminal state (incapacitated for turn)
            "Bea's Aura"     
        ],
        attributes : [
            ATTRIBUTE.FRAGILE
        ]
    }),


    Item.Base.new(data : {
        name : "Bracelet of Luna",
        description: 'A bracelet inset with an opal in the shape of a crescent moon.',
        examine : "Once the greatest treasure in a dragons' hoard, it softly gleams in the moonlight with incredible power.",
        equipType: TYPE.TRINKET,
        rarity : 30000,
        basePrice : 30000,
        keyItem : false,
        weight : 0.3,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : true,
        canBeColored : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        equipMod : StatSet.new(
            DEF: 4, 
            ATK: 10
        ),
        useEffects : [
            'Fling',
        ],
        equipEffects : [
            // At night: attacks gain water affinity with increased strength
            "Luna's Aura"     
        ],
        attributes : [
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}
    }),

    Item.Base.new(data : {
        name : "Skie's Ring",
        description: 'A simple ring said to have been worn by a great dragon.',
        examine : 'Wearers appear to feel a bit tired from wearing it, but feel their potential profoundly grow.',
        equipType: TYPE.RING,
        rarity : 30000,
        basePrice : 30000,
        keyItem : false,
        hasMaterial : false,
        canHaveModifier : false,
        canBeColored : false,
        isUnique : true,
        weight : 0.1,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            MP: -20, // 
            DEF: -20, // 
            SPD: -20, // 
            ATK: -40 // 
        ),
        useEffects : [
            'Fling',
        ],
        equipEffects : [
            // Growth potential + 3 for all stats
            "Skie's Aura"     
        ],
        attributes : [
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}
    }),

    Item.Base.new(data : {
        name : "Pink Potion",
        description: 'Pink-colored potions are known to be for recovery of injuries',
        examine : 'Potions like these are so common that theyre often unmarked and trusted as-is. The hue of this potion is distinct.',
        equipType: TYPE.HAND,
        weight : 0.5,
        rarity : 100,
        canBeColored : false,
        keyItem : false,
        basePrice: 20,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : false,
        isUnique : false,        
        useTargetHint : USE_TARGET_HINT.ONE,
        equipMod : StatSet.new(
            SPD: -2, // itll slow you down
            DEX: -10   // its oddly shaped.
        ),
        useEffects : [
            'HP Recovery: Minor',
            'Consume Item'       
        ],
        equipEffects : [
        ],
        attributes : [
            ATTRIBUTE.FRAGILE
        ],
        onCreate ::(item, user, creationHint) {}


    }),


    Item.Base.new(data : {
        name : "Pinkish Potion",
        description: 'Pink-colored potions are known to be for recovery of injuries',
        examine : 'This potion does not have the same hue as the common recovery potion and is a bit heavier. Did you get it from a reliable source?',
        equipType: TYPE.HAND,
        rarity : 600,
        weight : 0.5,
        basePrice: 20,
        canBeColored : false,
        hasMaterial : false,
        levelMinimum : 1,
        keyItem : false,
        isUnique : false,
        canHaveModifier : true,
        useTargetHint : USE_TARGET_HINT.ONE,
        equipMod : StatSet.new(
            SPD: -2, // itll slow you down
            DEX: -10   // its oddly shaped.
        ),
        useEffects : [
            'HP Recovery: Iffy',
            'Consume Item'       
        ],
        equipEffects : [
        ],
        attributes : [
            ATTRIBUTE.FRAGILE
        ],
        onCreate ::(item, user, creationHint) {}


    }),


    
    Item.Base.new(data : {
        name : "Cyan Potion",
        description: 'Cyan-colored potions are known to be for recovery of mental fatigue.',
        examine : 'Potions like these are so common that theyre often unmarked and trusted as-is. The hue of this potion is distinct.',
        equipType: TYPE.HAND,
        rarity : 100,
        weight : 0.5,        
        basePrice: 20,
        canBeColored : false,
        keyItem : false,
        levelMinimum : 1,
        hasMaterial : false,
        isUnique : false,
        canHaveModifier : true,
        useTargetHint : USE_TARGET_HINT.ONE,
        equipMod : StatSet.new(
            SPD: -2, // itll slow you down
            DEX: -10   // its oddly shaped.
        ),
        useEffects : [
            'MP Recovery: Minor',
            'Consume Item'       
        ],
        equipEffects : [
        ],
        attributes : [
            ATTRIBUTE.FRAGILE
        ],
        onCreate ::(item, user, creationHint) {}


    }),
    
    Item.Base.new(data : {
        name : "Pitchfork",
        description: 'A common farming implement.',
        examine : 'Quite sturdy and pointy, some people use these as weapons.',
        equipType: TYPE.HAND,
        rarity : 100,
        basePrice: 10,        
        canBeColored : false,
        keyItem : false,
        weight : 4,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK: 15,
            DEF: 20
        ),
        useEffects : [
            'Fling',
            'Break Item'
        ],
        equipEffects : [
            'Non-combat Weapon' // high chance to deflect, but when it deflects, the weapon breaks
            
        ],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }),

    Item.Base.new(data : {
        name : "Shovel",
        description: 'A common farming implement.',
        examine : 'Quite sturdy and pointy, some people use these as weapons.',
        equipType: TYPE.HAND,
        basePrice: 13,
        rarity : 100,
        keyItem : false,
        canBeColored : false,
        weight : 4,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK: 20,
            DEF: 10,
            SPD: -10,
            DEX: -10
        ),
        useEffects : [
            'Fling',
            'Break Item'
        ],
        equipEffects : [
            'Non-combat Weapon' // high chance to deflect, but when it deflects, the weapon breaks
            
        ],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }),

    Item.Base.new(data : {
        name : "Pickaxe",
        description: 'A common mining implement.',
        examine : 'Quite sturdy and pointy, some people use these as weapons.',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        keyItem : false,
        weight : 4,
        canBeColored : false,
        basePrice: 20,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK: 25,
            DEF: 5,
            SPD: -15,
            DEX: -15
        ),
        useEffects : [
            'Fling',
            'Break Item'
        ],
        equipEffects : [
            'Non-combat Weapon' // high chance to deflect, but when it deflects, the weapon breaks
            
        ],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }),


    Item.Base.new(data : {
        name : "Butcher's Knife",
        description: 'Common knife meant for cleaving meat.',
        examine : 'Quite sharp.',
        equipType: TYPE.HAND,
        rarity : 100,
        canBeColored : false,
        keyItem : false,
        weight : 4,
        basePrice: 17,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK: 25,
            DEX: 5
        ),
        useEffects : [
            'Fling',
            'Break Item'
        ],
        equipEffects : [
            'Non-combat Weapon' // high chance to deflect, but when it deflects, the weapon breaks
            
        ],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }),

    
    
    Item.Base.new(data : {
        name : "Shortsword",
        description: 'A basic sword.',
        examine : 'Swords like these are quite common and are of adequate quality even if simple.',
        equipType: TYPE.HAND,
        rarity : 300,
        canBeColored : false,
        keyItem : false,
        weight : 4,
        basePrice: 50,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK: 30,
            DEF: 10,
            SPD: -5
        ),
        useEffects : [
            'Fling',
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL,
            ATTRIBUTE.WEAPON
        ],
        onCreate ::(item, user, creationHint) {}

    }),

    
    Item.Base.new(data : {
        name : "Bow & Quiver",
        description: 'A basic bow and quiver full of arrows.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 300,
        keyItem : false,
        weight : 2,
        canBeColored : false,
        basePrice: 76,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK: 25,
            SPD: 10,
            DEX: 60
        ),
        useEffects : [
            'Fling',
            'Break Item'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.WEAPON            
        ],
        onCreate ::(item, user, creationHint) {}

    }),

    
    Item.Base.new(data : {
        name : "Greatsword",
        description: 'A basic, large sword.',
        examine : 'Not as common as shortswords, but rather easy to find. Favored by larger warriors.',
        equipType: TYPE.TWOHANDED,
        rarity : 300,
        weight : 12,
        keyItem : false,
        canBeColored : false,
        basePrice: 87,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK: 25,
            DEF: 25,
            SPD: -15
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL,
            ATTRIBUTE.WEAPON    
        ],
        onCreate ::(item, user, creationHint) {}

    }),
    
    Item.Base.new(data : {
        name : "Dagger",
        description: 'A basic knife.',
        examine : 'Commonly favored by both swift warriors and common folk for their easy handling and easiness to produce.',
        equipType: TYPE.HAND,
        rarity : 300,
        weight : 1,
        canBeColored : false,
        keyItem : false,
        basePrice: 35,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        equipMod : StatSet.new(
            ATK: 15,
            SPD: 10,
            DEX: 20
        ),
        useEffects : [
            'Fling',
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL,
            ATTRIBUTE.WEAPON

        ],
        onCreate ::(item, user, creationHint) {}

    }),    
    
    Item.Base.new(data : {
        name : "Hammer",
        description: 'A basic hammer.',
        examine : 'Easily available, the hammer is common as a general tool for metalworking.',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 8,
        canBeColored : false,
        keyItem : false,
        basePrice: 30,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK:  30,
            SPD: -30,
            DEX: -30
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.BLUNT,
            ATTRIBUTE.METAL

        ],
        onCreate ::(item, user, creationHint) {}

    }),
    
    
    Item.Base.new(data : {
        name : "Polearm",
        description: 'A weapon with long reach and deadly power.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 8,
        canBeColored : false,
        keyItem : false,
        basePrice: 105,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK:  40,
            SPD:  15,
            DEX:  20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.BLUNT,
            ATTRIBUTE.METAL,
            ATTRIBUTE.WEAPON

        ],
        onCreate ::(item, user, creationHint) {}

    }),
    
    Item.Base.new(data : {
        name : "Glaive",
        description: 'A weapon with long reach and deadly power.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 8,
        canBeColored : false,
        keyItem : false,
        basePrice: 105,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK:  35,
            SPD:  15,
            DEX:  25
        ),
        useEffects : [
            'Fling',
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.BLUNT,
            ATTRIBUTE.METAL,
            ATTRIBUTE.WEAPON

        ],
        onCreate ::(item, user, creationHint) {}

    }),    
    
    
    Item.Base.new(data : {
        name : "Staff",
        description: 'A combat staff. Promotes fluid movement when used well.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 8,
        canBeColored : false,
        keyItem : false,
        basePrice: 40,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK:  25,
            SPD:  15,
            DEX:  30
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.BLUNT,
            ATTRIBUTE.METAL

        ],
        onCreate ::(item, user, creationHint) {}

    }),    


    Item.Base.new(data : {
        name : "Mage-rod",
        description: 'Similar to a wand, promotes mental accuity.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 9,
        canBeColored : false,
        keyItem : false,
        basePrice: 100,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK:  15,
            SPD:  -10,
            INT:  40
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.BLUNT,
            ATTRIBUTE.METAL

        ],
        onCreate ::(item, user, creationHint) {}

    }), 
    
    Item.Base.new(data : {
        name : "Wand",
        description: '',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        canBeColored : false,
        weight : 8,
        keyItem : false,
        basePrice: 100,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            INT:  25,
            SPD:  45,
            DEX:  20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.BLUNT,
            ATTRIBUTE.METAL

        ],
        onCreate ::(item, user, creationHint) {}

    }),    



    Item.Base.new(data : {
        name : "Warhammer",
        description: 'A hammer meant for combat.',
        examine : 'A common choice for those who wish to cause harm and have the arm to back it up.',
        equipType: TYPE.TWOHANDED,
        rarity : 350,
        weight : 10,
        keyItem : false,
        canBeColored : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        basePrice: 200,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK: 45,
            DEF: 30,
            SPD: -25,
            DEX: -25
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.BLUNT,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }),
    
    
    Item.Base.new(data : {
        name : "Tome",
        description: 'A plated book for magick-users in the heat of battle.',
        examine : 'A lightly enchanted book meant to both be used as reference on-the-fly and meant to increase the mental acquity of the holder.',
        equipType: TYPE.HAND,
        rarity : 350,
        weight : 1,
        canBeColored : false,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 220,

        // fatigued
        equipMod : StatSet.new(
            DEF: 15,
            INT: 60,
            SPD: -10
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.BLUNT,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),

    Item.Base.new(data : {
        name : "Tunic",
        description: 'Simple cloth for the body.',
        examine : 'Common type of light armor',
        equipType: TYPE.ARMOR,
        rarity : 100,
        weight : 1,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 15,

        // fatigued
        equipMod : StatSet.new(
            DEF: 5,
            SPD: 5
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),


    Item.Base.new(data : {
        name : "Robe",
        description: 'Simple cloth favored by scholars.',
        examine : 'Common type of light armor',
        equipType: TYPE.ARMOR,
        rarity : 100,
        weight : 1,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 15,

        // fatigued
        equipMod : StatSet.new(
            DEF: 5,
            INT: 5
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),
    
    Item.Base.new(data : {
        name : "Scarf",
        description: 'Simple cloth accessory.',
        examine : 'Common type of light armor',
        equipType: TYPE.TRINKET,
        rarity : 100,
        weight : 1,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 10,

        // fatigued
        equipMod : StatSet.new(
            DEF: 3
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),    


    Item.Base.new(data : {
        name : "Bandana",
        description: 'Simple cloth accessory.',
        examine : 'Common type of light armor',
        equipType: TYPE.TRINKET,
        rarity : 100,
        weight : 1,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 10,

        // fatigued
        equipMod : StatSet.new(
            DEF: 3
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),        


    Item.Base.new(data : {
        name : "Cape",
        description: 'Simple cloth accessory.',
        examine : 'Common type of light armor',
        equipType: TYPE.TRINKET,
        rarity : 100,
        weight : 1,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 14,

        // fatigued
        equipMod : StatSet.new(
            DEF: 3
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),    
    
    Item.Base.new(data : {
        name : "Hat",
        description: 'Simple cloth accessory.',
        examine : 'Common type of light armor',
        equipType: TYPE.TRINKET,
        rarity : 100,
        weight : 1,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 10,

        // fatigued
        equipMod : StatSet.new(
            DEF: 3
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),           

    Item.Base.new(data : {
        name : "Fortified Cape",
        description: 'A cape fortified with metal. It is a bit heavy.',
        examine : 'Common type of light armor',
        equipType: TYPE.TRINKET,
        rarity : 350,
        weight : 10,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 200,

        // fatigued
        equipMod : StatSet.new(
            DEF: 15,
            SPD: -10
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),   

    
    Item.Base.new(data : {
        name : "Light Robe",
        description: 'Enchanted light wear favored by mages.',
        examine : 'Common type of light armor',
        equipType: TYPE.ARMOR,
        rarity : 350,
        weight : 1,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 350,

        // fatigued
        equipMod : StatSet.new(
            DEF: 23,
            INT: 15
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),    
    
    
    Item.Base.new(data : {
        name : "Chainmail",
        description: 'Mail made of linked chains.',
        examine : 'Common type of light armor',
        equipType: TYPE.ARMOR,
        rarity : 350,
        weight : 1,
        canBeColored : false,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 200,

        // fatigued
        equipMod : StatSet.new(
            DEF: 40,
            SPD: -10
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.BLUNT,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),

    Item.Base.new(data : {
        name : "Filigree Armor",
        description: 'Hardened material with a fancy trim.',
        examine : 'Common type of light armor',
        equipType: TYPE.ARMOR,
        rarity : 500,
        weight : 1,
        canBeColored : false,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 350,

        // fatigued
        equipMod : StatSet.new(
            DEF: 55,
            ATK: 10,
            SPD: -10
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.BLUNT,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),
        
    Item.Base.new(data : {
        name : "Plate Armor",
        description: 'Extremely protective armor of a high-grade.',
        examine : 'Highly skilled craftspeople are required to make this work.',
        equipType: TYPE.ARMOR,
        rarity : 500,
        weight : 1,
        canBeColored : false,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 400,

        // fatigued
        equipMod : StatSet.new(
            DEF: 65,
            ATK: 30,
            SPD: -20
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.BLUNT,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),    
    
    Item.Base.new(data : {
        name : "Edrosae's Key",
        description: 'The gateway to the domain of the Elders.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 10000000,
        basePrice: 1,
        keyItem : true,
        canBeColored : false,
        weight : 10,
        levelMinimum : 1,
        canHaveModifier : true,
        hasMaterial : false,
        isUnique : true,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK: 15,
            SPD: -5,
            DEX: -5
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),
    

    ////// RAW_METALS


    Item.Base.new(data : {
        name : "Copper Ingot",
        description: 'Copper Ingot',
        examine : 'Pure copper ingot.',
        equipType: TYPE.TWOHANDED,
        rarity : 150,
        weight : 5,
        canBeColored : false,
        keyItem : false,
        basePrice: 10,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.RAW_METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }),      



    Item.Base.new(data : {
        name : "Iron Ingot",
        description: 'Iron Ingot',
        examine : 'Pure iron ingot',
        equipType: TYPE.TWOHANDED,
        rarity : 200,
        weight : 5,
        keyItem : false,
        canBeColored : false,
        basePrice: 20,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.RAW_METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }),   

    Item.Base.new(data : {
        name : "Steel Ingot",
        description: 'Steel Ingot',
        examine : 'Pure Steel ingot.',
        equipType: TYPE.TWOHANDED,
        rarity : 300,
        canBeColored : false,
        weight : 5,
        keyItem : false,
        basePrice: 30,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.RAW_METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }),      



    Item.Base.new(data : {
        name : "Mythril Ingot",
        description: 'Mythril Ingot',
        examine : 'Pure iron ingot',
        equipType: TYPE.TWOHANDED,
        rarity : 1000,
        canBeColored : false,
        weight : 5,
        keyItem : false,
        basePrice: 150,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.RAW_METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }),   

    Item.Base.new(data : {
        name : "Quicksilver Ingot",
        description: 'Quicksilver Ingot',
        examine : 'Pure quicksilver alloy ingot',
        equipType: TYPE.TWOHANDED,
        rarity : 1550,
        canBeColored : false,
        weight : 5,
        keyItem : false,
        basePrice: 175,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.RAW_METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }),   

    Item.Base.new(data : {
        name : "Adamantine Ingot",
        description: 'Adamantine Ingot',
        examine : 'Pure adamantine ingot',
        equipType: TYPE.TWOHANDED,
        rarity : 2000,
        weight : 5,
        canBeColored : false,
        keyItem : false,
        basePrice: 300,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.RAW_METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }), 


    Item.Base.new(data : {
        name : "Sunstone Ingot",
        description: 'Sunstone alloy ingot',
        examine : 'An alloy with mostly sunstone, it dully shines with a soft yellow gleam',
        equipType: TYPE.TWOHANDED,
        rarity : 300,
        canBeColored : false,
        basePrice: 115,
        keyItem : false,
        weight : 5,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.RAW_METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }), 

    Item.Base.new(data : {
        name : "Moonstone Ingot",
        description: 'Sunstone alloy ingot',
        examine : 'An alloy with mostly moonstone, it dully shines with a soft teal',
        equipType: TYPE.TWOHANDED,
        rarity : 300,
        weight : 5,
        canBeColored : false,
        keyItem : false,
        basePrice: 115,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.RAW_METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }), 

    Item.Base.new(data : {
        name : "Dragonglass Ingot",
        description: 'Dragonglass alloy ingot',
        examine : 'An alloy with mostly dragonglass, it sharply shines black.',
        equipType: TYPE.TWOHANDED,
        rarity : 500,
        weight : 5,
        canBeColored : false,
        keyItem : false,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        basePrice: 250,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.RAW_METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }), 
    Item.Base.new(data : {
        name : "Ore",
        description: "Raw ore. It's hard to tell exactly what kind of metal it is.",
        examine : 'Could be smelted into',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 5,
        canBeColored : false,
        keyItem : false,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 100000,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 5,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP
        ],
        onCreate ::(item, user, creationHint) {}

    }), 
    
    Item.Base.new(data : {
        name : "Gold Pouch",
        description: "A pouch of coins.",
        examine : '',
        equipType: TYPE.HAND,
        rarity : 100,
        weight : 5,
        canBeColored : false,
        keyItem : false,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 100000,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 5,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Treasure I'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP
        ],
        onCreate ::(item, user, creationHint) {}

    }),
    
    Item.Base.new(data : {
        name : "Skill Crystal",
        description: "Irridescent cyrstal that imparts knowledge when used.",
        examine : 'Quite sought after, highly skilled mages usually produce them for the public',
        equipType: TYPE.HAND,
        rarity : 100,
        weight : 3,
        canBeColored : false,
        keyItem : false,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 100000,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 600,

        equipMod : StatSet.new(
            ATK: 10, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Learn Skill',
            'Consume Item'       
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP
        ],
        onCreate ::(item, user, creationHint) {}

    }),
        
    
    
    
    
    Item.Base.new(data : {
        name : "Runestone",
        description: "Resonates with certain locations and can reveal runes.",
        examine : '',
        equipType: TYPE.HAND,
        rarity : 300,
        weight : 10,
        canBeColored : false,
        keyItem : true,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : true,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 0,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP
        ],
        onCreate ::(item, user, creationHint) {}

    }),  



    Item.Base.new(data : {
        name : "Tablet",
        description: "A tablet with carved with runes in Draconic. Arcanists might find this valuable.",
        examine : 'Might have been used for some highly specialized purpose. These seem very rare.',
        equipType: TYPE.TWOHANDED,
        rarity : 3000,
        weight : 10,
        keyItem : false,
        canBeColored : false,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : true,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 1,

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Fling',
            'Break Item'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP
        ],
        onCreate ::(item, user, creationHint) {}

    }), 

    Item.Base.new(data : {
        name : "Wyvern Key",
        description: 'A key to another island.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 10,
        canBeColored : false,
        basePrice: 100,
        keyItem : false,
        levelMinimum : 1,
        canHaveModifier : false,
        hasMaterial : false,
        isUnique : true,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            ATK: 15,
            SPD: -5,
            DEX: -5
        ),
        useEffects : [
            'Fling'
        ],
        equipEffects : [],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {     
        
            @:world = import(module:'singleton.world.mt');        
            @:nameGen = import(module:'singleton.namegen.mt');
            @:island = if (creationHint != empty) ::<={
                return {
                    levelHint:  (creationHint.levelHint) => Number,
                    nameHint:   (creationHint.nameHint)  => String,
                    island : empty
                };
            } else ::<= {
                return {
                    nameHint: nameGen.island(),
                    levelHint: user.level+1,
                    island : empty
                };
            };
            
            @:levelToStratum = ::(level) {
                return match((level / 5)->floor) {
                  (0): 'IV',
                  (1): 'III',
                  (2): 'II',
                  (3): 'I',
                  default: 'Unknown'
                };
            };
            
            item.setIslandGenAttributes(
                levelHint: island.levelHint,
                nameHint : island.nameHint
            );
            
            item.price *= 1 + ((island.levelHint) / (5 + 5*Number.random()));
            item.price = item.price->ceil;
            item.name = 'Key to ' + island.nameHint + ' - Stratum ' + levelToStratum(level:island.levelHint);
            return island;
        }
        
    })

    
]);


return Item;
