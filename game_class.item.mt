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
@:StatSet = import(module:'game_class.statset.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:ItemEnchant = import(module:'game_class.itemenchant.mt');
@:ItemQuality = import(module:'game_class.itemquality.mt');
@:ItemColor = import(module:'game_class.itemcolor.mt');
@:Material = import(module:'game_class.material.mt');
@:random = import(module:'game_singleton.random.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:correctA = import(module:'game_function.correcta.mt');
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
        @enchants = []; // ItemMod
        @quality;
        @material;
        @customName = empty;
        @description;
        @container;
        @price;
        @color;
        @island;
        @islandLevelHint;
        @islandNameHint;
        @islandTierHint;
        @equipEffects = [];
        @useEffects = [];
        @ability;
        @victoryCount = 0; // like exp, stat mods increase with victories
                           // conceptually: the user becomes more familiar
                           // with how to effectively use it in their hands
                           // This is only for hand items since it only is 
                           // increased in the hand equip slot.
                           //
                           // Also the item can become enchanted through use 
        @:stats = StatSet.new();
        
        @:recalculateName = ::{

            @baseName =
            if (base_.hasMaterial)
                customName = material.name + ' ' + base_.name
            else 
                customName = base_.name
            ;
                
            @enchantName = match(enchants->keycount) {
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
              (10) :' (X)'            
            };
            
            customName = if (base_.hasQuality && quality != empty)
                quality.name + ' ' + baseName + enchantName 
            else
                baseName + enchantName;


        };
        
        @:assignSize = ::{
            random.pickArrayItem(list:[
                ::{
                    description = description + 'It is smaller than expected. ';
                    stats.add(stats:StatSet.new(
                        ATK:-10,
                        DEF:-10,
                        SPD:10,
                        DEX:10                    
                    ));
                    price *= 0.85;                    
                },

                ::{
                    description = description + 'It is quite small. ';
                    stats.add(stats:StatSet.new(
                        ATK:-20,
                        DEF:-20,
                        SPD:20,
                        DEX:20                    
                    ));
                    price *= 0.75;                    
                },

                ::{
                    description = description + 'It is average-sized. ';
                },

                ::{
                    description = description + 'It is larger than expected. ';
                    stats.add(stats:StatSet.new(
                        ATK:10,
                        DEF:10,
                        SPD:-10,
                        DEX:-10                    
                    ));
                    price *= 1.15;                    
                },

                ::{
                    description = description + 'It is quite large. ';
                    stats.add(stats:StatSet.new(
                        ATK:20,
                        DEF:20,
                        SPD:-20,
                        DEX:-20                    
                    ));
                    price *= 1.25;                    
                }

            
            ])();
        };
        
        this.constructor = ::(base, from, creationHint, qualityHint, enchantHint, materialHint, rngEnchantHint, state, colorHint) {
            when(state != empty) ::<= {
                this.state = state;
                return this;
            };
            
            ability = random.pickArrayItem(list:base.possibleAbilities);
            base_ = base;
            stats.add(stats:base.equipMod);
            price = base.basePrice;
            price *= 1.05 * base_.weight;
            description = base.description + (if (ability == empty) ' ' else ' If equipped, grants the ability: "' + ability + '". ');
            base.equipEffects->foreach(do:::(i, effect) {
                equipEffects->push(value:effect);
            });

            base.useEffects->foreach(do:::(i, effect) {
                useEffects->push(value:effect);
            });
            
            
            
            if (base.hasQuality) ::<= {
                // random chance to have a maker's emblem on it, indicating 
                // made with love and care
                if (Number.random() < 0.3) ::<= {
                    description = description + 'The maker\'s emblem is engraved on it. ';
                    stats.add(stats:StatSet.new(
                        ATK:10,
                        DEF:10,
                        SPD:10,
                        INT:10,
                        DEX:10                    
                    ));
                    price *= 1.05;
                };
                
                
                if (Number.random() < 0.3) ::<= {
                    quality = if (qualityHint == empty)
                        ItemQuality.database.getRandom()
                    else 
                        ItemQuality.database.find(name:qualityHint);
                    stats.add(stats:quality.equipMod);
                    price += (price * (quality.pricePercentMod/100));
                    description = description + quality.description + ' ';
                    
                };
            };
            
            @:story = import(module:'game_singleton.story.mt');

            if (base.hasMaterial) ::<= {
                if (materialHint == empty) ::<= {
                    material = Material.database.getRandomWeightedFiltered(
                        filter:::(value) <- if (story.defeatedWyvernFire) true else from.level >= value.levelMinimum
                    );
                } else ::<= {
                    material = Material.database.find(name:materialHint);                
                };
                description = description + material.description + ' ';
                stats.add(stats:material.statMod);
                recalculateName();
            };
            

            
            if (base.canHaveEnchants) ::<= {
                if (enchantHint != empty) ::<= {
                    this.addEnchant(name:enchantHint);
                };

                
                if (rngEnchantHint != empty && Number.random() < 0.5) ::<= {
                    @enchantCount = random.integer(from:1, to:1+match(true) {
                        (story.defeatedWyvernLight):   4,
                        (story.defeatedWyvernThunder): 3,
                        (story.defeatedWyvernFire):    2,
                        default: 0
                    });
                    
                    [0, enchantCount]->for(do:::(i) {
                        @mod = if (story.defeatedWyvernIce)
                            ItemEnchant.Base.getRandom().new()
                        else
                            ItemEnchant.Base.database.getRandomFiltered(
                                filter::(value) <- value.isRare == false
                            ).new();
                            
                        this.addEnchant(mod);
                    });
                };
            };
            
            if (base.hasSize)   
                assignSize();


            if (base.canBeColored) ::<= {
                color = if (colorHint) ItemColor.database.find(name:colorHint) else ItemColor.database.getRandom();
                stats.add(stats:color.equipMod);
                description = description->replace(key:'$color$', with:color.name);
            };
                        
            
            

            if (material != empty) 
                price += price * (material.pricePercentMod / 100);
                
            price = (price)->ceil;
            
            base.onCreate(item:this, user:from, creationHint);
            
            
            return this;
            
        };
        @:Island = import(module:'game_class.island.mt');
        @:world = import(module:'game_singleton.world.mt');
        
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
            
            enchantsCount : {
                get ::<- enchants->keycount
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

            ability : {
                get ::<- ability
            },
            
            equipEffects : {
                get ::<- equipEffects
            },
            
            islandEntry : {
                get ::<- island
            },
            
            setIslandGenAttributes ::(levelHint => Number, nameHint => String, tierHint => Number, islandHint) {
                islandLevelHint = levelHint;
                islandNameHint = nameHint;
                islandTierHint = tierHint;
                island = islandHint;
            },
            
            addIslandEntry ::(world) {
                when (island != empty) empty;

                island = world.discoverIsland(
                    levelHint: (islandLevelHint)=>Number,
                    nameHint: (islandNameHint)=>String,
                    tierHint: (islandTierHint)=>Number
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
            
            addEnchant::(mod) {
    
                enchants->push(value:mod);
                mod.base.equipEffects->foreach(do:::(i, effect) {
                    equipEffects->push(value:effect);
                });
                breakpoint();
                stats.add(stats:mod.base.equipMod);
                if (description->contains(key:mod.description) == false)
                    description = description + mod.description + ' ';
                recalculateName();
                price += mod.base.priceMod;
                price = price->ceil;
            },
            
            description : {
                get :: {
                    
                
                    return description + '\nEquip effects: \n' + stats.getRates();
                }
            },
            
            onTurnEnd ::(wielder, battle){
                enchants->foreach(do:::(i, enchant) {
                    enchant.onTurnCheck(wielder, item:this, battle);
                });
            },
            
            describe ::(by) {
                @:Effect = import(module:'game_class.effect.mt');
                windowEvent.queueMessage(
                    speaker:this.name,
                    text:description,
                    pageAfter:canvas.height-4
                );
                windowEvent.queueMessage(
                    speaker:this.name + ' - Equip Stats',
                    text:stats.description,
                    pageAfter:canvas.height-4
                );

                windowEvent.queueMessage(
                    speaker:this.name + ' - Equip Effects',
                    pageAfter:canvas.height-4,
                    text:::<={
                        @out = '';
                        when (equipEffects->keycount == 0) 'None.';
                        equipEffects->foreach(do:::(i, effect) {
                            out = out + '. ' + Effect.database.find(name:effect).description + '\n';
                        });
                        return out;
                    }
                );                
                windowEvent.queueMessage(
                    speaker:this.name + ' - Use Effects',
                    pageAfter:canvas.height-4,
                    text:::<={
                        @out = '';
                        when (useEffects->keycount == 0) 'None.';
                        useEffects->foreach(do:::(i, effect) {
                            out = out + '. ' + Effect.database.find(name:effect).description + '\n';
                        });
                        return out;
                    }
                );  


                if (by != empty) ::<= {
                    when(by.profession.base.weaponAffinity != base_.name) empty;
                    windowEvent.queueMessage(
                        speaker:by.name,
                        pageAfter:canvas.height-4,
                        text:'Oh! This weapon type really works for me as ' + correctA(word:by.profession.base.name) + '.'
                    );  
                };

            },
            
            addVictory ::(silent) {
                victoryCount += 1;
                if (victoryCount % 3 == 0) ::<= {
                    @choice = random.integer(from:0, to:7);
                    @:oldStats = StatSet.new();
                    oldStats.add(stats);
                    stats.add(stats:StatSet.new(
                        HP: if (choice == 0) 1 else 0,
                        AP: if (choice == 1) 1 else 0,
                        ATK: if (choice == 2) 1 else 0,
                        DEF: if (choice == 3) 1 else 0,
                        INT: if (choice == 4) 1 else 0,
                        LUK: if (choice == 5) 1 else 0,
                        DEX: if (choice == 6) 1 else 0,
                        SPD: if (choice == 7) 1 else 0
                    ));
                    
                    if (silent == empty && base_.name != 'None') ::<= {
                        windowEvent.queueMessage(text:'The party get\'s more used to using the ' + this.name + '.');
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
                    equipEffects = [];
                    value.equipEffects->foreach(do:::(index, effectName) {
                        equipEffects->push(value:effectName);
                    });

                    enchants = [];
                    value.enchantNames->foreach(do:::(index, modName) {
                        @:mod = ItemEnchant.database.find(name:modName);
                        enchants->push(value:mod);
                    });
                    
                    quality = ItemQuality.database.find(name:value.quality);
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
                        enchantNames : [...enchants]->map(to:::(value) <- value.name),
                        equipEffects : [...equipEffects],
                        quality : quality.name
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
                canHaveEnchants: Boolean,
                hasQuality : Boolean,
                hasMaterial : Boolean,
                isUnique : Boolean,
                keyItem : Boolean,
                useEffects : Object,
                equipEffects : Object,
                attributes : Object,
                useTargetHint : Number,
                onCreate : Function,
                basePrice : Number,
                canBeColored: Boolean,
                hasSize : Boolean,
                possibleAbilities : Object
            
            }
        );
        this.interface = {
            new ::(from, creationHint, enchantHint, materialHint, rngEnchantHint, qualityHint, state, colorHint) {
                return Item.new(base:this, from, creationHint, enchantHint, materialHint, rngEnchantHint, qualityHint, state, colorHint);
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
            canHaveEnchants : false,
            hasQuality : false,
            hasMaterial : false,
            useTargetHint : USE_TARGET_HINT.ONE,
            useEffects : [],
            equipEffects : [],
            attributes : [],
            canBeColored : false,
            hasSize : false,
            onCreate ::(item, user, creationHint) {},
            possibleAbilities : [],
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
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : true,
        canBeColored : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        hasSize : false,
        onCreate ::(item, user, creationHint) {},
        possibleAbilities : [],
        
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
        hasSize : false,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : true,
        canBeColored : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        equipMod : StatSet.new(
            DEF: 4, 
            ATK: 10
        ),
        possibleAbilities : [],
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
        canHaveEnchants : false,
        hasQuality : false,
        canBeColored : false,
        isUnique : true,
        weight : 0.1,
        hasSize : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,

        // fatigued
        equipMod : StatSet.new(
            AP: -20, // 
            DEF: -20, // 
            SPD: -20, // 
            ATK: -40 // 
        ),
        useEffects : [
            'Fling',
        ],
        possibleAbilities : [],
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
        hasSize : false,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,        
        useTargetHint : USE_TARGET_HINT.ONE,
        equipMod : StatSet.new(
            SPD: -2, // itll slow you down
            DEX: -10   // its oddly shaped.
        ),
        useEffects : [
            'HP Recovery: All',
            'Consume Item'       
        ],
        possibleAbilities : [],
        equipEffects : [
        ],
        attributes : [
            ATTRIBUTE.FRAGILE
        ],
        onCreate ::(item, user, creationHint) {}


    }),
    
    
    Item.Base.new(data : {
        name : "Purple Potion",
        description: 'Purple-colored potions are known to combine the effects of pink and cyan potions',
        examine : 'These potions are handy, as the effects of ',
        equipType: TYPE.HAND,
        weight : 0.5,
        rarity : 100,
        canBeColored : false,
        hasSize : false,
        keyItem : false,
        basePrice: 100,
        levelMinimum : 1,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,        
        possibleAbilities : [],
        useTargetHint : USE_TARGET_HINT.ONE,
        equipMod : StatSet.new(
            SPD: -2, // itll slow you down
            DEX: -10   // its oddly shaped.
        ),
        useEffects : [
            'HP Recovery: All',
            'AP Recovery: All',
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
        name : "Green Potion",
        description: 'Green-colored potions are known to be toxic.',
        examine : 'Often used offensively, these potions are known to be used as poison once used and doused on a target.',
        equipType: TYPE.HAND,
        weight : 0.5,
        rarity : 100,
        canBeColored : false,
        keyItem : false,
        basePrice: 20,
        levelMinimum : 1,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,        
        hasSize : false,
        possibleAbilities : [],
        useTargetHint : USE_TARGET_HINT.ONE,
        equipMod : StatSet.new(
            SPD: -2, // itll slow you down
            DEX: -10   // its oddly shaped.
        ),
        useEffects : [
            'Poisoned',
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
        name : "Orange Potion",
        description: 'Orange-colored potions are known to be volatile.',
        examine : 'Often used offensively, these potions are known to explode on contact.',
        equipType: TYPE.HAND,
        weight : 0.5,
        rarity : 100,
        canBeColored : false,
        keyItem : false,
        basePrice: 20,
        levelMinimum : 1,
        canHaveEnchants : false,
        hasSize : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,        
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [],
        equipMod : StatSet.new(
            SPD: -2, // itll slow you down
            DEX: -10   // its oddly shaped.
        ),
        useEffects : [
            'Explode',
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
        name : "Black Potion",
        description: 'Black-colored potions are known to be toxic to all organic life.',
        examine : 'Often used offensively, these potions are known to cause instant petrification.',
        equipType: TYPE.HAND,
        weight : 0.5,
        rarity : 100,
        canBeColored : false,
        keyItem : false,
        basePrice: 20,
        levelMinimum : 1,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        hasSize : false,
        isUnique : false,        
        possibleAbilities : [],
        useTargetHint : USE_TARGET_HINT.ONE,
        equipMod : StatSet.new(
            SPD: -2, // itll slow you down
            DEX: -10   // its oddly shaped.
        ),
        useEffects : [
            'Petrified',
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
        hasSize : false,
        isUnique : false,
        canHaveEnchants : false,
        hasQuality : false,
        possibleAbilities : [],
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
        hasSize : false,
        hasMaterial : false,
        isUnique : false,
        canHaveEnchants : false,
        hasQuality : false,
        possibleAbilities : [],
        useTargetHint : USE_TARGET_HINT.ONE,
        equipMod : StatSet.new(
            SPD: -2, // itll slow you down
            DEX: -10   // its oddly shaped.
        ),
        useEffects : [
            'AP Recovery: All',
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
        canHaveEnchants : false,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        hasSize : true,
        possibleAbilities : [
            "Stab"
        ],
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
        hasSize : true,
        levelMinimum : 1,
        canHaveEnchants : false,
        hasQuality : true,
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
        possibleAbilities : [
            "Stun"
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
        canHaveEnchants : false,
        hasQuality : true,
        hasSize : true,
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
        possibleAbilities : [
            "Stab"
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
        hasSize : true,
        canHaveEnchants : false,
        hasQuality : true,
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
        possibleAbilities : [
            "Stab"
        ],

        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {}

    }),

    
    
    Item.Base.new(data : {
        name : "Shortsword",
        description: 'A basic sword. The hilt has a $color$ trim.',
        examine : 'Swords like these are quite common and are of adequate quality even if simple.',
        equipType: TYPE.HAND,
        rarity : 300,
        canBeColored : true,
        keyItem : false,
        weight : 4,
        basePrice: 50,
        levelMinimum : 1,
        hasSize : true,
        canHaveEnchants : true,
        hasQuality : true,
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
        possibleAbilities : [
            "Stab",
            "Doublestrike",
            "Triplestrike",
            "Stun"
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
        name : "Chakram",
        description: 'A pair of round blades. The handles have a $color$ trim.',
        examine : '.',
        equipType: TYPE.TWOHANDED,
        rarity : 300,
        canBeColored : true,
        keyItem : false,
        weight : 4,
        basePrice: 200,
        levelMinimum : 1,
        hasSize : true,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Stab",
            "Stun",
            "Swipe Kick"
        ],

        // fatigued
        equipMod : StatSet.new(
            ATK: 25,
            DEF: 5,
            SPD: 15,
            DEX: 25
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
        name : "Falchion",
        description: 'A basic sword with a large blade. The hilt has a $color$ trim.',
        examine : 'Swords like these are quite common and are of adequate quality even if simple.',
        equipType: TYPE.HAND,
        rarity : 300,
        canBeColored : true,
        keyItem : false,
        weight : 4,
        basePrice: 150,
        levelMinimum : 1,
        hasSize : true,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Stab",
            "Doublestrike",
            "Triplestrike",
            "Stun",
            "Counter"
        ],

        // fatigued
        equipMod : StatSet.new(
            ATK: 35,
            DEF: 10,
            SPD: -10
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
        name : "Scimitar",
        description: 'A basic sword with a curved blade. The hilt has a $color$ trim.',
        examine : 'Swords like these are quite common and are of adequate quality even if simple.',
        equipType: TYPE.HAND,
        rarity : 300,
        canBeColored : true,
        keyItem : false,
        weight : 4,
        basePrice: 150,
        levelMinimum : 1,
        hasSize : true,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Stab",
            "Doublestrike",
            "Triplestrike",
            "Stun",
        ],

        // fatigued
        equipMod : StatSet.new(
            ATK: 30,
            DEF: 10,
            SPD: -10,
            DEX: 5
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
        name : "Rapier",
        description: 'A slender sword excellent for thrusting. The hilt has a $color$ trim.',
        examine : 'Swords like these are quite common and are of adequate quality even if simple.',
        equipType: TYPE.HAND,
        rarity : 300,
        canBeColored : true,
        keyItem : false,
        weight : 4,
        basePrice: 120,
        hasSize : true,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Stab",
            "Doublestrike",
            "Triplestrike",
            "Counter"
        ],

        // fatigued
        equipMod : StatSet.new(
            ATK: 35,
            SPD: 10,
            DEF:-10,
            DEX: 10
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
        description: 'A basic bow and quiver full of arrows. The bow has a streak of $color$ across it.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 300,
        keyItem : false,
        weight : 2,
        hasSize : true,
        canBeColored : true,
        basePrice: 76,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Doublestrike",
            "Triplestrike",
            "Sharpshoot",
            "Tranquilizer"
        ],

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
        description: 'A basic, large sword. The hilt has a $color$ trim.',
        examine : 'Not as common as shortswords, but rather easy to find. Favored by larger warriors.',
        equipType: TYPE.TWOHANDED,
        rarity : 300,
        weight : 12,
        hasSize : true,
        keyItem : false,
        canBeColored : true,
        basePrice: 87,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Stun",
            "Stab",
            "Big Swing",
            "Leg Sweep"
        ],

        // fatigued
        equipMod : StatSet.new(
            ATK: 30,
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
        description: 'A basic knife. The handle has an intricate $color$ trim.',
        examine : 'Commonly favored by both swift warriors and common folk for their easy handling and easiness to produce.',
        equipType: TYPE.HAND,
        rarity : 300,
        weight : 1,
        hasSize : true,
        canBeColored : true,
        keyItem : false,
        basePrice: 35,
        canHaveEnchants : true,
        hasQuality : true,
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
        possibleAbilities : [
            "Stab",
            "Doublestrike",
            "Triplestrike"
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
        canHaveEnchants : true,
        hasSize : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Stun"
        ],

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
        name : "Halberd",
        description: 'A weapon with long reach and deadly power. The handle has a $color$ trim.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 8,
        canBeColored : true,
        keyItem : false,
        basePrice: 105,
        hasSize : true,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Stun",
            "Stab",
            "Big Swing",
            "Leg Sweep"
        ],

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
        name : "Lance",
        description: 'A weapon with long reach and deadly power. The handle has a $color$ trim.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 8,
        canBeColored : true,
        keyItem : false,
        basePrice: 105,
        hasSize : true,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Stun",
            "Stab",
            "Big Swing",
            "Leg Sweep"
        ],

        // fatigued
        equipMod : StatSet.new(
            ATK:  35,
            SPD:  20,
            DEX:  15
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
        description: 'A weapon with long reach and deadly power. The handle has a $color$ trim.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 8,
        canBeColored : true,
        keyItem : false,
        basePrice: 105,
        hasSize : true,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Stun",
            "Stab",
            "Big Swing",
            "Leg Sweep"
        ],

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
        description: 'A combat staff. Promotes fluid movement when used well.The ends are tied with a $color$ fabric.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 8,
        canBeColored : true,
        keyItem : false,
        basePrice: 40,
        levelMinimum : 1,
        hasSize : true,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Stun",
            "Big Swing",
            "Leg Sweep"
        ],

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
            ATTRIBUTE.METAL,
            ATTRIBUTE.WEAPON

        ],
        onCreate ::(item, user, creationHint) {}

    }),    


    Item.Base.new(data : {
        name : "Mage-rod",
        description: 'Similar to a wand, promotes mental acuity. The handle has a $color$ trim.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 9,
        hasSize : true,
        canBeColored : true,
        keyItem : false,
        basePrice: 100,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Fire",
            "Ice",
            "Thunder",
            "Flare",
            "Frozen Flame",
            "Explostion",
            "Flash",
            "Cure",
            "Greater Cure"
        ],

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
            ATTRIBUTE.METAL,
            ATTRIBUTE.WEAPON

        ],
        onCreate ::(item, user, creationHint) {}

    }), 
    
    Item.Base.new(data : {
        name : "Wand",
        description: 'The handle has a $color$ trim.',
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
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Fire",
            "Ice",
            "Thunder",
            "Flare",
            "Frozen Flame",
            "Explostion",
            "Flash",
            "Cure",
            "Greater Cure"
        ],

        // fatigued
        equipMod : StatSet.new(
            ATK:  5,
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
            ATTRIBUTE.METAL,
            ATTRIBUTE.WEAPON

        ],
        onCreate ::(item, user, creationHint) {}

    }),    



    Item.Base.new(data : {
        name : "Warhammer",
        description: 'A hammer meant for combat. The end is tied with a $color$ fabric.',
        examine : 'A common choice for those who wish to cause harm and have the arm to back it up.',
        equipType: TYPE.TWOHANDED,
        rarity : 350,
        weight : 10,
        keyItem : false,
        canBeColored : true,
        levelMinimum : 1,
        hasSize : true,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        basePrice: 200,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Stun",
            "Big Swing",
            "Leg Sweep"
        ],

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
            ATTRIBUTE.METAL,
            ATTRIBUTE.WEAPON
        ],
        onCreate ::(item, user, creationHint) {}

    }),
    
    
    Item.Base.new(data : {
        name : "Tome",
        description: 'A plated book for magick-users in the heat of battle. The cover is imprinted with a $color$ fabric.',
        examine : 'A lightly enchanted book meant to both be used as reference on-the-fly and meant to increase the mental acquity of the holder.',
        equipType: TYPE.HAND,
        rarity : 350,
        weight : 1,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        hasSize : false,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 220,
        possibleAbilities : [
            "Fire",
            "Ice",
            "Thunder",
            "Flare",
            "Frozen Flame",
            "Explostion",
            "Flash",
            "Cure",
            "Greater Cure"
        ],
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
            ATTRIBUTE.METAL,
            ATTRIBUTE.WEAPON
        ],
        onCreate ::(item, user, creationHint) {}
        
    }),

    Item.Base.new(data : {
        name : "Tunic",
        description: 'Simple cloth for the body. It is predominantly $color$.',
        examine : 'Common type of light armor',
        equipType: TYPE.ARMOR,
        rarity : 100,
        weight : 1,
        canBeColored : true,
        hasSize : false,
        keyItem : false,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 15,
        possibleAbilities : [],

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
        description: 'Simple cloth favored by scholars. It features a $color$ design.',
        examine : 'Common type of light armor',
        equipType: TYPE.ARMOR,
        rarity : 100,
        weight : 1,
        hasSize : false,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 15,
        possibleAbilities : [],

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
        description: 'Simple cloth accessory. It is $color$.',
        examine : 'Common type of light armor',
        equipType: TYPE.TRINKET,
        rarity : 100,
        weight : 1,
        canBeColored : true,
        hasSize : false,
        keyItem : false,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 10,
        possibleAbilities : [],

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
        description: 'Simple cloth accessory. It is $color$.',
        examine : 'Common type of light armor',
        equipType: TYPE.TRINKET,
        rarity : 100,
        weight : 1,
        canBeColored : true,
        hasSize : false,
        keyItem : false,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 10,
        possibleAbilities : [],

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
        description: 'Simple cloth accessory. It features a $color$-based design.',
        examine : 'Common type of light armor',
        equipType: TYPE.TRINKET,
        rarity : 100,
        weight : 1,
        hasSize : false,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 14,
        possibleAbilities : [],

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
        description: 'Simple cloth accessory. It is predominantly $color$.',
        examine : 'Common type of light armor',
        equipType: TYPE.TRINKET,
        rarity : 100,
        weight : 1,
        canBeColored : true,
        hasSize : false,
        keyItem : false,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 10,
        possibleAbilities : [],

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
        description: 'A cape fortified with metal. It is a bit heavy. It features a $color$ trim.',
        examine : 'Common type of light armor',
        equipType: TYPE.TRINKET,
        rarity : 350,
        weight : 10,
        hasSize : false,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 200,
        possibleAbilities : [],

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
        description: 'Enchanted light wear favored by mages. It features a $color$ design.',
        examine : 'Common type of light armor',
        equipType: TYPE.ARMOR,
        rarity : 350,
        weight : 1,
        canBeColored : true,
        hasSize : false,
        keyItem : false,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : false,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 350,
        possibleAbilities : [],

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
        description: 'Mail made of linked chains. It bears an emblem colored $color$.',
        examine : 'Common type of light armor',
        equipType: TYPE.ARMOR,
        rarity : 350,
        weight : 1,
        canBeColored : true,
        keyItem : false,
        hasSize : false,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 200,
        possibleAbilities : [],

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
        description: 'Hardened material with a fancy $color$ trim.',
        examine : 'Common type of light armor',
        equipType: TYPE.ARMOR,
        rarity : 500,
        weight : 1,
        canBeColored : true,
        hasSize : false,
        keyItem : false,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 350,
        possibleAbilities : [],

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
        description: 'Extremely protective armor of a high-grade. It has a $color$ trim.',
        examine : 'Highly skilled craftspeople are required to make this work.',
        equipType: TYPE.ARMOR,
        rarity : 500,
        weight : 1,
        canBeColored : true,
        keyItem : false,
        levelMinimum : 1,
        hasSize : false,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : true,
        isUnique : false,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 400,
        possibleAbilities : [],

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
        hasSize : false,
        basePrice: 1,
        keyItem : true,
        canBeColored : false,
        weight : 10,
        levelMinimum : 1,
        canHaveEnchants : true,
        hasQuality : true,
        hasMaterial : false,
        isUnique : true,
        possibleAbilities : [],
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
        hasSize : false,
        weight : 5,
        canBeColored : false,
        keyItem : false,
        basePrice: 10,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [],

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
        hasSize : false,
        weight : 5,
        keyItem : false,
        canBeColored : false,
        basePrice: 20,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [],

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
        hasSize : false,
        rarity : 300,
        canBeColored : false,
        weight : 5,
        keyItem : false,
        basePrice: 30,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [],

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
        hasSize : false,
        rarity : 1000,
        canBeColored : false,
        weight : 5,
        keyItem : false,
        basePrice: 150,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [],

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
        hasSize : false,
        weight : 5,
        keyItem : false,
        basePrice: 175,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [],

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
        hasSize : false,
        basePrice: 300,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [],

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
        hasSize : false,
        weight : 5,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [],

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
        hasSize : false,
        basePrice: 115,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [],

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
        hasSize : false,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        basePrice: 250,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [],

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
        hasSize : false,
        rarity : 100,
        weight : 5,
        canBeColored : false,
        keyItem : false,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 100000,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 5,
        possibleAbilities : [],

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
        hasSize : false,
        canBeColored : false,
        keyItem : false,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 5,
        possibleAbilities : [],

        equipMod : StatSet.new(
            ATK: 2, // well. its hard!
            DEF: 2, // well. its hard!
            SPD: -10,
            DEX: -20
        ),
        useEffects : [
            'Treasure I',
            'Consume Item'       
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
        canHaveEnchants : false,
        hasSize : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 1,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 600,
        possibleAbilities : [],

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
        hasSize : false,
        keyItem : true,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
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
        hasSize : false,
        keyItem : false,
        canBeColored : false,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 10000000,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 1,
        possibleAbilities : [],

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
        name : "Ingredient",
        description: "A pack of ingredients used for potions and brews.",
        examine : 'Common ingredients used by alchemists.',
        equipType: TYPE.TWOHANDED,
        rarity : 300000000,
        weight : 1,
        hasSize : false,
        keyItem : false,
        canBeColored : false,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : false,
        levelMinimum : 10000000,
        useTargetHint : USE_TARGET_HINT.ONE,
        basePrice: 5,
        possibleAbilities : [],

        equipMod : StatSet.new(
            ATK: 0,
            DEF: 2, 
            SPD: -1,
            DEX: -2
        ),
        useEffects : [
            'Fling',
            'Break Item'
        ],
        equipEffects : [],
        attributes : [
        ],
        onCreate ::(item, user, creationHint) {}

    }), 


    Item.Base.new(data : {
        name : "Wyvern Key of Fire",
        description: 'A key to another island. Its quite big and warm to the touch.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 10,
        hasSize : false,
        canBeColored : false,
        basePrice: 1,
        keyItem : false,
        levelMinimum : 1000000000,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : true,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Fire" // for fun!
        ],

        // fatigued
        equipMod : StatSet.new(
            ATK: 25,
            SPD: -5,
            DEX: -5
        ),
        useEffects : [
        ],
        equipEffects : [
            "Burning"
        ],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {     
        
            @:world = import(module:'game_singleton.world.mt');        
            @:nameGen = import(module:'game_singleton.namegen.mt');
            @:island = {
                island : empty
            };

            item.setIslandGenAttributes(
                levelHint:  6,//user.level => Number,
                nameHint:   nameGen.island(),
                tierHint : 1
            );
            item.addIslandEntry(world);
            
            item.price = 1;
        }
        
    }),
    
    Item.Base.new(data : {
        name : "Wyvern Key of Ice",
        description: 'A key to another island. Its quite big and cold to the touch.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        hasSize : false,
        weight : 10,
        canBeColored : false,
        basePrice: 1,
        keyItem : false,
        levelMinimum : 1000000000,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : true,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Ice" // for fun!
        ],

        // fatigued
        equipMod : StatSet.new(
            ATK: 25,
            SPD: -5,
            DEX: -5
        ),
        useEffects : [
        ],
        equipEffects : [
            "Icy"
        ],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {     
        
            @:world = import(module:'game_singleton.world.mt');        
            @:nameGen = import(module:'game_singleton.namegen.mt');
            @:island = {
                island : empty
            };

            item.setIslandGenAttributes(
                levelHint:  7,
                nameHint:   nameGen.island(),
                tierHint : 2
            );
            
            item.price = 1;
        }
        
    }),    
    
    Item.Base.new(data : {
        name : "Wyvern Key of Thunder",
        description: 'A key to another island. Its quite big and softly hums.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 10,
        canBeColored : false,
        hasSize : false,
        basePrice: 1,
        keyItem : false,
        levelMinimum : 1000000000,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : true,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Thunder" // for fun!
        ],

        // fatigued
        equipMod : StatSet.new(
            ATK: 25,
            SPD: -5,
            DEX: -5
        ),
        useEffects : [
        ],
        equipEffects : [
            "Shock"
        ],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {     
        
            @:world = import(module:'game_singleton.world.mt');        
            @:nameGen = import(module:'game_singleton.namegen.mt');
            @:island = {
                island : empty
            };

            item.setIslandGenAttributes(
                levelHint:  8,
                nameHint:   nameGen.island(),
                tierHint : 3
            );
            
            item.price = 1;
        }
        
    }),    

    Item.Base.new(data : {
        name : "Wyvern Key of Light",
        description: 'A key to another island. Its quite big and faintly glows.',
        examine : '',
        equipType: TYPE.TWOHANDED,
        rarity : 100,
        weight : 10,
        hasSize : false,
        canBeColored : false,
        basePrice: 1,
        keyItem : false,
        levelMinimum : 1000000000,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : true,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
            "Explosion" // for fun!
        ],

        // fatigued
        equipMod : StatSet.new(
            ATK: 25,
            SPD: -5,
            DEX: -5
        ),
        useEffects : [
        ],
        equipEffects : [
            "Shimmering"
        ],
        attributes : [
            ATTRIBUTE.SHARP,
            ATTRIBUTE.METAL
        ],
        onCreate ::(item, user, creationHint) {     
        
            @:world = import(module:'game_singleton.world.mt');        
            @:nameGen = import(module:'game_singleton.namegen.mt');
            @:island = {
                island : empty
            };

            item.setIslandGenAttributes(
                levelHint:  9,
                nameHint:   nameGen.island(),
                tierHint : 3
            );
            
            item.price = 1;
        }
        
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
        hasSize : false,
        levelMinimum : 1000000000,
        canHaveEnchants : false,
        hasQuality : false,
        hasMaterial : false,
        isUnique : true,
        useTargetHint : USE_TARGET_HINT.ONE,
        possibleAbilities : [
        ],

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
        
            @:world = import(module:'game_singleton.world.mt');        
            @:nameGen = import(module:'game_singleton.namegen.mt');
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
                nameHint : island.nameHint,
                tierHint : 0
            );
            
            item.price *= 1 + ((island.levelHint) / (5 + 5*Number.random()));
            item.price = item.price->ceil;
            item.name = 'Key to ' + island.nameHint + ' - Stratum ' + levelToStratum(level:island.levelHint);
        }
        
    })    

    
]);


return Item;
