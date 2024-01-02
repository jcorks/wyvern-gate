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
@:ItemDesign = import(module:'game_class.itemdesign.mt');
@:Material = import(module:'game_class.material.mt');
@:ApparelMaterial = import(module:'game_class.apparelmaterial.mt');
@:random = import(module:'game_singleton.random.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

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
    BLUNT     : 0x1,
    SHARP     : 0x10,
    FLAT      : 0x100,
    SHIELD    : 0x1000,
    METAL     : 0x10000,
    FRAGILE   : 0x100000,
    WEAPON    : 0x1000000,
    RAW_METAL : 0x10000000
}

@:USE_TARGET_HINT = {
    ONE     : 0,    
    GROUP   : 1,
    ALL     : 2
}

@:SIZE = {
    SMALL : 0,
    TINY : 1,
    AVERAGE : 2,
    LARGE : 3,
    BIG : 4
}




@:Item = LoadableClass.new(
    name : 'Wyvern.Item',
    statics : {
        Base  :::<= {
            @db;
            return {
                get ::<- db,
                set ::(value) <- db = value
            }
        },
        TYPE :{get::<- TYPE},
        ATTRIBUTE : {get::<-ATTRIBUTE},
        USE_TARGET_HINT : {get::<-USE_TARGET_HINT}
    },
    new ::(parent, base, from, creationHint, qualityHint, enchantHint, materialHint, apparelHint, rngEnchantHint, state, colorHint, abilityHint, forceEnchant) {
        @:this = Item.defaultNew();

        if (state != empty)
            this.load(serialized:state)
        else 
            this.defaultLoad(base, from, creationHint, qualityHint, enchantHint, materialHint, apparelHint, rngEnchantHint, colorHint, abilityHint, forceEnchant);
            
        return this;
    },
    define:::(this) {
    

        @container = empty;
        @equippedBy = empty;
        
        @:state = State.new(
            items : {
                base : empty,
                enchants : [], // ItemMod
                quality : empty,
                material : empty,
                apparel : empty,
                customPrefix : empty,
                customName : empty,
                description : empty,
                hasEmblem : empty,
                size : empty,
                price : empty,
                color : empty,
                island : empty,
                islandLevelHint : empty,
                islandNameHint : empty,
                islandTierHint : empty,
                improvementsLeft : empty,
                improvementsStart : empty,
                equipEffects : [],
                useEffects : [],
                intuition : 0,
                ability : empty,
                stats : StatSet.new(),
                design : empty,
                modData : {}
            }
        );
    

        
        @:getEnchantTag ::<- match(state.enchants->keycount) {
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
        
        
        @:recalculateName = ::{
            when (state.customPrefix)
                state.customName = state.customPrefix + getEnchantTag();


            @baseName =
            if (state.base.isApparel && state.apparel)
                state.apparel.name + ' ' + state.base.name
            else if (state.base.hasMaterial && state.material != empty)
                state.material.name + ' ' + state.base.name
            else 
                state.base.name
            ;
            
            state.customName = baseName;
            
                
            @enchantName = getEnchantTag();
            
            state.customName = if (state.base.hasQuality && state.quality != empty)
                state.quality.name + ' ' + baseName + enchantName 
            else
                baseName + enchantName;

            if (state.improvementsLeft != state.improvementsStart) ::<= {
                state.customName = state.customName +  '+'+(state.improvementsStart - state.improvementsLeft);
            }


        }
        
        @:sizeToString ::<- match(state.size) {
          (SIZE.SMALL)   : 'smaller than expected',
          (SIZE.TINY)    : 'quite small',
          (SIZE.AVERAGE) : 'normally sized',
          (SIZE.LARGE)   : 'larger than expected',
          (SIZE.BIG)     : 'quite large' 
        }
        
        @:assignSize = ::{
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
        
        @:recalculateDescription ::{
            @:base = this.base;
            state.description = String.combine(strings:[
                base.description,
                ' ',
                (if (state.ability == empty) '' else 'If equipped, grants the ability: "' + state.ability + '". '),
                if (state.size == empty) '' else 'It is ' + sizeToString() + '. ',
                if (state.hasEmblem) (
                    if (base.isApparel) 
                        'The maker\'s emblem is sewn on it. '
                    else
                        'The maker\'s emblem is engraved on it. '
                ) else 
                    '',
                if (base.hasQuality && state.quality != empty) state.quality.description + ' ' else '',
                if (base.hasMaterial) state.material.description + ' ' else '',
                if (base.isApparel) state.apparel.description + ' ' else ''
            ]);
            if (base.canBeColored) ::<= {
                state.description = state.description->replace(key:'$color$', with:state.color.name);
                state.description = state.description->replace(key:'$design$', with:state.design.name);
            }
        }
        
        @:Island = import(module:'game_class.island.mt');
        @:world = import(module:'game_singleton.world.mt');
        
        this.interface = {
            defaultLoad::(base, from, creationHint, qualityHint, enchantHint, materialHint, apparelHint, rngEnchantHint, colorHint, designHint, abilityHint, forceEnchant) {
                
                state.ability = if (abilityHint) abilityHint else random.pickArrayItem(list:base.possibleAbilities);
                state.base = base;
                state.stats.add(stats:base.equipMod);
                state.price = base.basePrice;
                state.price *= 1.05 * state.base.weight;
                state.improvementsLeft = random.integer(from:10, to:25);
                state.improvementsStart = state.improvementsLeft;
                
                if (base.hasSize)   
                    assignSize();
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
                            ItemQuality.database.getRandomWeighted()
                        else 
                            ItemQuality.database.find(name:qualityHint);
                        state.stats.add(stats:state.quality.equipMod);
                        state.price += (state.price * (state.quality.pricePercentMod/100));                        
                    }
                }
                
                @:story = import(module:'game_singleton.story.mt');

                if (base.hasMaterial) ::<= {
                    if (materialHint == empty) ::<= {
                        state.material = Material.database.getRandomWeightedFiltered(
                            filter::(value) <- value.tier <= story.tier
                        );
                    } else ::<= {
                        state.material = Material.database.find(name:materialHint);                
                    }
                    state.stats.add(stats:state.material.statMod);
                }

                if (base.isApparel) ::<= {
                    if (apparelHint == empty) ::<= {
                        state.apparel = ApparelMaterial.database.getRandomWeightedFiltered(
                            filter::(value) <- value.tier <= story.tier
                        );
                    } else ::<= {
                        state.apparel = ApparelMaterial.database.find(name:apparelHint);                
                    }
                    state.stats.add(stats:state.apparel.statMod);
                }                

                
                if (base.canHaveEnchants) ::<= {
                    if (enchantHint != empty) ::<= {
                        this.addEnchant(mod:ItemEnchant.new(
                            base:ItemEnchant.Base.database.find(name:enchantHint)
                        ));
                    }

                    
                    if (rngEnchantHint != empty && (random.try(percentSuccess:60) || forceEnchant)) ::<= {
                        @enchantCount = random.integer(from:1, to:match(story.tier) {
                            (6, 7, 8, 9, 10):    8,
                            (3,4,5):    4,
                            (1, 2):    2,
                            default: 1
                        });
                        
                        
                        
                        for(0, enchantCount)::(i) {
                            @mod = ItemEnchant.new(
                                base:ItemEnchant.Base.database.getRandomFiltered(
                                    filter::(value) <- value.tier <= story.tier && (if (base.canHaveTriggerEnchants == false) value.triggerConditionEffects->keycount == 0 else true)
                                )
                            )
                            this.addEnchant(mod);
                        }
                    }
                }


                if (base.canBeColored) ::<= {
                    state.color = if (colorHint) ItemColor.database.find(name:colorHint) else ItemColor.database.getRandom();
                    state.stats.add(stats:state.color.equipMod);
                    state.design = if (designHint) ItemDesign.database.find(name:designHint) else ItemDesign.database.getRandom();
                    state.stats.add(stats:state.design.equipMod);
                }
                            
                
                

                if (state.material != empty) 
                    state.price += state.price * (state.material.pricePercentMod / 100);
                    
                state.price = (state.price)->ceil;
                
                base.onCreate(item:this, user:from, creationHint);
                recalculateDescription();
                recalculateName();
                
                return this;
                
            },

            base : {
                get :: {
                    return state.base;
                }
            },
            
            
            name : {
                get :: {
                    when (state.customName != empty) state.customName;
                    return state.base.name;
                },
                
                set ::(value => String)  {
                    state.customPrefix = value;
                    recalculateName();
                }
            },
            
            quality : {
                get ::<- state.quality,
                set ::(value) {
                    if (state.quality != empty) ::<= {
                        state.stats.subtract(stats:state.quality.equipMod);
                        state.price -= (state.price * (state.quality.pricePercentMod/100));
                    }
                    state.quality = value;
                    state.stats.add(stats:state.quality.equipMod);
                    state.price += (state.price * (state.quality.pricePercentMod/100));

                    recalculateName();
                }
            },
            
            enchantsCount : {
                get ::<- state.enchants->keycount
            },
            
            equipMod : {
                get ::<- state.stats
            },
            
            container : {
                get :: {
                    return container;
                },
                
                set ::(value => Inventory.type) {
                    container = value;
                }
            },
            
            equippedBy : {
                set ::(value) {
                    equippedBy = value;
                },
                
                get ::<- equippedBy
            },

            ability : {
                get ::<- state.ability
            },
            
            equipEffects : {
                get ::<- state.equipEffects
            },
            
            islandEntry : {
                get ::<- state.island
            },
            
            setIslandGenAttributes ::(levelHint => Number, nameHint => String, tierHint => Number, islandHint) {
                state.islandLevelHint = levelHint;
                state.islandNameHint = nameHint;
                state.islandTierHint = tierHint;
                state.island = islandHint;
            },
            
            modData : {
                get ::<- state.modData
            },
            
            addIslandEntry ::(world) {
                when (state.island != empty) empty;

                state.island = world.discoverIsland(
                    levelHint: (state.islandLevelHint)=>Number,
                    nameHint: (state.islandNameHint)=>String,
                    tierHint: (state.islandTierHint)=>Number
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
                get ::<-state.price,
                set ::(value) <- state.price = value
            },
            
            material : {
                get ::<- state.material
            },
            
            addEnchant::(mod) {
                when (state.enchants->keycount >= state.base.enchantLimit) empty;
                state.enchants->push(value:mod);
                foreach(mod.base.equipEffects)::(i, effect) {
                    state.equipEffects->push(value:effect);
                }
                state.stats.add(stats:mod.base.equipMod);
                //if (description->contains(key:mod.description) == false)
                //    description = description + mod.description + ' ';
                recalculateName();
                state.price += mod.base.priceMod;
                state.price = state.price->ceil;
            },
            
            description : {
                get :: {
                    return state.description + '\nEquip effects: \n' + state.stats.getRates();
                }
            },
            
            onTurnEnd ::(wielder, battle){
                foreach(state.enchants)::(i, enchant) {
                    enchant.onTurnCheck(wielder, item:this, battle);
                }
            },
            
            improvementsLeft : {
                get::<- state.improvementsLeft,
                set::(value) {
                    state.improvementsLeft = value;
                    recalculateName();
                }
            },
            
            describe ::(by) {
                @:Effect = import(module:'game_class.effect.mt');
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
                            @:list = [
                                'I', 'II', 'III', 'IV', 'V', 'VI', "VII", 'VIII', 'IX', 'X', 'XI'
                            ]
                            @out = '';
                            when (state.enchants->keycount == 0) 'None.';
                            foreach(state.enchants)::(i, mod) {
                                out = out + list[i] + ' - ' + mod.description + '\n';
                            }
                            return out;
                        }
                    );                
                }                
                
                windowEvent.queueMessage(
                    speaker:this.name + ' - Equip Stats',
                    text:state.stats.description,
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
                                out = out + '. ' + Effect.database.find(name:effect).description + '\n';
                            }
                            return out;
                        }
                    );
                }
                

                                
                windowEvent.queueMessage(
                    speaker:this.name + ' - Use Effects',
                    pageAfter:canvas.height-4,
                    text:::<={
                        @out = '';
                        when (state.useEffects->keycount == 0) 'None.';
                        foreach(state.useEffects)::(i, effect) {
                            out = out + '. ' + Effect.database.find(name:effect).description + '\n';
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
                get ::<- state.stats
            },
            
            addIntuition :: {
                state.intuition += 1;
            },

            canGainIntuition ::(silent) {
                return state.intuition < 20;
            },
            
            maxOut ::{
                state.intuition = 20;
                state.improvementsLeft = 0;
            },
            
            save ::<- state.save(),
            load ::(serialized) <- state.load(parent:this, serialized)
        }
    }
);


Item.Base = Database.newBase(
    name: 'Wyvern.Item.Base',
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
        possibleAbilities : Object
    
    },
    
    getInterface::(this) {
        return {
            hasAttribute :: (attribute) {
                return (this.attributes & attribute) != 0;
            }   
        } 
    }          
)



Item.Base.new(
    data : {
        name : 'None',
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
        onCreate ::(item, user, creationHint) {},
        possibleAbilities : [],
    }
)
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
    tier: 0,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,
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
    attributes : ATTRIBUTE.FRAGILE
})

Item.Base.new(data : {
    name : "Mei\'s Bow",
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
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,
    isUnique : true,
    canBeColored : false,
    useTargetHint : USE_TARGET_HINT.ONE,
    hasSize : false,
    onCreate ::(item, user, creationHint) {},
    possibleAbilities : [],
    
    equipMod : StatSet.new(
        HP: 30,
        DEF: 50
    ),
    useEffects : [
        'Fling',
        'Break Item'
    ],
    equipEffects : [
    ],
    attributes : ATTRIBUTE.FRAGILE    
})

Item.Base.new(data : {
    name : "Life Crystal",
    description: 'A shimmering amulet. The metal enclosure has a $color$ tint. If death befalls the holder, has a 50% chance to revive them and break.',
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
    onCreate ::(item, user, creationHint) {},
    possibleAbilities : [],
    
    equipMod : StatSet.new(
        HP: 10,
        DEF: 10
    ),
    useEffects : [
        'Fling',
        'Break Item'
    ],
    equipEffects : [
        'Auto-Life',
    ],
    attributes : ATTRIBUTE.FRAGILE    
})


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
    tier: 0,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,
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
    attributes : 
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {}
})

Item.Base.new(data : {
    name : "Skie's Ring",
    description: 'A simple ring said to have been worn by a great dragon.',
    examine : 'Wearers appear to feel a bit tired from wearing it, but feel their potential profoundly grow.',
    equipType: TYPE.RING,
    rarity : 30000,
    basePrice : 30000,
    keyItem : false,
    tier: 0,
    hasMaterial : false,
    isApparel : false,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
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
    attributes : 
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {}
})

Item.Base.new(data : {
    name : "Pink Potion",
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
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, user, creationHint) {}


})


Item.Base.new(data : {
    name : "Purple Potion",
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
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, user, creationHint) {}


})    

Item.Base.new(data : {
    name : "Green Potion",
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
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, user, creationHint) {}


})    

Item.Base.new(data : {
    name : "Orange Potion",
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
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, user, creationHint) {}
})    


Item.Base.new(data : {
    name : "Black Potion",
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
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, user, creationHint) {}


})    


/*
Item.Base.new(data : {
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
        'Consume Item'       
    ],
    equipEffects : [
    ],
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, user, creationHint) {}


})
*/



Item.Base.new(data : {
    name : "Cyan Potion",
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
    attributes : 
        ATTRIBUTE.FRAGILE
    ,
    onCreate ::(item, user, creationHint) {}


})

Item.Base.new(data : {
    name : "Pitchfork",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {}

})

Item.Base.new(data : {
    name : "Shovel",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {}

})

Item.Base.new(data : {
    name : "Pickaxe",
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


    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {}

})


Item.Base.new(data : {
    name : "Butcher's Knife",
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

    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {}

})

Item.Base.new(data : {
    name : "Bludgeon",
    description: 'A basic blunt weapon. The hilt has a $color$ trim with a $design$ design.',
    examine : 'Clubs and bludgeons seem primitive, but are quite effective.',
    equipType: TYPE.HAND,
    rarity : 300,
    canBeColored : true,
    keyItem : false,
    weight : 4,
    basePrice: 40,
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
    equipMod : StatSet.new(
        ATK: 20,
        DEF: 15,
        SPD: -10
    ),
    useEffects : [
        'Fling',
    ],
    possibleAbilities : [
        "Doublestrike",
        "Triplestrike",
        "Stun"
    ],

    equipEffects : [],
    attributes : 
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})    

Item.Base.new(data : {
    name : "Shortsword",
    description: 'A basic sword. The hilt has a $color$ trim with a $design$ design.',
    examine : 'Swords like these are quite common and are of adequate quality even if simple.',
    equipType: TYPE.HAND,
    rarity : 300,
    canBeColored : true,
    keyItem : false,
    weight : 4,
    basePrice: 50,
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})


Item.Base.new(data : {
    name : "Longsword",
    description: 'A basic sword. The hilt has a $color$ trim with a $design$ design.',
    examine : 'Swords like these are quite common and are of adequate quality even if simple.',
    equipType: TYPE.TWOHANDED,
    rarity : 300,
    canBeColored : true,
    keyItem : false,
    weight : 4,
    basePrice: 50,
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
    equipMod : StatSet.new(
        ATK: 35,
        DEF: 15,
        SPD: -10
    ),
    useEffects : [
        'Fling',
    ],
    possibleAbilities : [
        "Stab",
        "Stun"
    ],

    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})


Item.Base.new(data : {
    name : "Blade & Shield",
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
    equipMod : StatSet.new(
        ATK: 25,
        DEF: 35,
        SPD: -15,
        DEX: 10
    ),
    useEffects : [
        'Fling',
    ],
    possibleAbilities : [
        "Counter",
        "Stun",
        "Leg Sweep"
    ],

    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP  |
        ATTRIBUTE.METAL  |
        ATTRIBUTE.SHIELD |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})


Item.Base.new(data : {
    name : "Wall Shield",
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
    equipMod : StatSet.new(
        ATK: 15,
        DEF: 55,
        SPD: -15,
        DEX: -10
    ),
    useEffects : [
        'Fling',
    ],
    possibleAbilities : [
        "Counter",
        "Stun",
        "Leg Sweep"
    ],

    equipEffects : [],
    attributes : 
        ATTRIBUTE.BLUNT  |
        ATTRIBUTE.METAL  |
        ATTRIBUTE.SHIELD |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})

Item.Base.new(data : {
    name : "Chakram",
    description: 'A pair of round blades. The handles have a $color$ trim with a $design$ design..',
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})    


Item.Base.new(data : {
    name : "Falchion",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})    


Item.Base.new(data : {
    name : "Morning Star",
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
        "Stab",
        "Stun",
        "Counter",
        "Big Swing"
    ],

    // fatigued
    equipMod : StatSet.new(
        ATK: 35,
        DEF: 20,
        SPD: -10
    ),
    useEffects : [
        'Fling',
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})     

Item.Base.new(data : {
    name : "Scimitar",
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
        DEX: 10
    ),
    useEffects : [
        'Fling',
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

}) 


Item.Base.new(data : {
    name : "Rapier",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})    


Item.Base.new(data : {
    name : "Bow & Quiver",
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
        "Doublestrike",
        "Triplestrike",
        "Precise Strike",
        "Tranquilizer"
    ],

    // fatigued
    equipMod : StatSet.new(
        ATK: 15,
        SPD: 10,
        DEX: 45
    ),
    useEffects : [
        'Fling',
        'Break Item'
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.WEAPON            
    ,
    onCreate ::(item, user, creationHint) {}

})


Item.Base.new(data : {
    name : "Crossbow",
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
        "Precise Strike",
        "Tranquilizer"
    ],

    // fatigued
    equipMod : StatSet.new(
        ATK: 35,
        SPD: -10,
        DEX: 45
    ),
    useEffects : [
        'Fling',
        'Break Item'
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.WEAPON            
    ,
    onCreate ::(item, user, creationHint) {}

})

Item.Base.new(data : {
    name : "Greatsword",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON    
    ,
    onCreate ::(item, user, creationHint) {}

})

Item.Base.new(data : {
    name : "Dagger",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON

    ,
    onCreate ::(item, user, creationHint) {}

})    

Item.Base.new(data : {
    name : "Smithing Hammer",
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL

    ,
    onCreate ::(item, user, creationHint) {}

})


Item.Base.new(data : {
    name : "Halberd",
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})

Item.Base.new(data : {
    name : "Lance",
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})    

Item.Base.new(data : {
    name : "Glaive",
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})    


Item.Base.new(data : {
    name : "Staff",
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})    


Item.Base.new(data : {
    name : "Mage-Staff",
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
        "Fire",
        "Ice",
        "Thunder",
        "Flare",
        "Frozen Flame",
        "Explosion",
        "Flash",
        "Cure",
        "Greater Cure",
        "Summon: Fire Sprite",
        "Summon: Ice Elemental",
        "Summon: Thunder Spawn"
    ],

    // fatigued
    equipMod : StatSet.new(
        ATK:  25,
        SPD:  -10,
        INT:  45
    ),
    useEffects : [
        'Fling'
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

}) 

Item.Base.new(data : {
    name : "Wand",
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
        "Fire",
        "Ice",
        "Thunder",
        "Flare",
        "Frozen Flame",
        "Explosion",
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})    



Item.Base.new(data : {
    name : "Warhammer",
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}

})


Item.Base.new(data : {
    name : "Tome",
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
        "Fire",
        "Ice",
        "Thunder",
        "Flash",
        "Cure",
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
    attributes : 
        ATTRIBUTE.BLUNT |
        ATTRIBUTE.METAL |
        ATTRIBUTE.WEAPON
    ,
    onCreate ::(item, user, creationHint) {}
    
})

Item.Base.new(data : {
    name : "Tunic",
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
    equipMod : StatSet.new(
        DEF: 5,
        SPD: 5
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
    onCreate ::(item, user, creationHint) {}
    
})


Item.Base.new(data : {
    name : "Robe",
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
    equipMod : StatSet.new(
        DEF: 5,
        INT: 5
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
    onCreate ::(item, user, creationHint) {}
    
})

Item.Base.new(data : {
    name : "Scarf",
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
    equipMod : StatSet.new(
        DEF: 3
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
    onCreate ::(item, user, creationHint) {}
    
})    


Item.Base.new(data : {
    name : "Headband",
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
    equipMod : StatSet.new(
        DEF: 3
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
    onCreate ::(item, user, creationHint) {}
    
})        
Item.Base.new(data : {
    name : "Ring",
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

    equipMod : StatSet.new(
        ATK: 15,
        SPD: 10,
        DEX: 20
    ),
    useEffects : [
        'Fling',
    ],
    possibleAbilities : [
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {}

})  

Item.Base.new(data : {
    name : "Cape",
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
    equipMod : StatSet.new(
        DEF: 3
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
    onCreate ::(item, user, creationHint) {}
    
})    


Item.Base.new(data : {
    name : "Cloak",
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
    equipMod : StatSet.new(
        SPD: 3,
        DEX: 5
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
    onCreate ::(item, user, creationHint) {}
    
})   

Item.Base.new(data : {
    name : "Hat",
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
    equipMod : StatSet.new(
        DEF: 3
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
    onCreate ::(item, user, creationHint) {}
    
})           

Item.Base.new(data : {
    name : "Fortified Cape",
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
    onCreate ::(item, user, creationHint) {}
    
})   


Item.Base.new(data : {
    name : "Light Robe",
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
    equipMod : StatSet.new(
        DEF: 23,
        INT: 15
    ),
    useEffects : [
    ],
    equipEffects : [],
    attributes : 0,
    onCreate ::(item, user, creationHint) {}
    
})    


Item.Base.new(data : {
    name : "Chainmail",
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
    onCreate ::(item, user, creationHint) {}
    
})

Item.Base.new(data : {
    name : "Filigree Armor",
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
    onCreate ::(item, user, creationHint) {}
    
})
    
Item.Base.new(data : {
    name : "Plate Armor",
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
    onCreate ::(item, user, creationHint) {}
    
})    

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
    equipMod : StatSet.new(
        ATK: 15,
        SPD: -5,
        DEX: -5
    ),
    useEffects : [
        'Fling'
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {}
    
})


////// RAW_METALS


Item.Base.new(data : {
    name : "Copper Ingot",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, user, creationHint) {}

})      



Item.Base.new(data : {
    name : "Iron Ingot",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, user, creationHint) {}

})   

Item.Base.new(data : {
    name : "Steel Ingot",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, user, creationHint) {}

})      



Item.Base.new(data : {
    name : "Mythril Ingot",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, user, creationHint) {}

})   

Item.Base.new(data : {
    name : "Quicksilver Ingot",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, user, creationHint) {}

})   

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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, user, creationHint) {}

}) 


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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, user, creationHint) {}

}) 

Item.Base.new(data : {
    name : "Moonstone Ingot",
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, user, creationHint) {}

}) 

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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.RAW_METAL
    ,
    onCreate ::(item, user, creationHint) {}

}) 
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
    attributes : 
        ATTRIBUTE.SHARP
    ,
    onCreate ::(item, user, creationHint) {}

}) 

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
    attributes : 
        ATTRIBUTE.SHARP
    ,
    onCreate ::(item, user, creationHint) {}

})

Item.Base.new(data : {
    name : "Skill Crystal",
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
    attributes : 
        ATTRIBUTE.SHARP
    ,
    onCreate ::(item, user, creationHint) {}

})
    




Item.Base.new(data : {
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
    onCreate ::(item, user, creationHint) {}

})  



Item.Base.new(data : {
    name : "Tablet",
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
    attributes : 
        ATTRIBUTE.SHARP
    ,
    onCreate ::(item, user, creationHint) {}

}) 


Item.Base.new(data : {
    name : "Ingredient",
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
    attributes : 0,
    onCreate ::(item, user, creationHint) {}

}) 


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
    tier: 0,
    keyItem : false,
    levelMinimum : 1000000000,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : true,
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {     
    
        @:world = import(module:'game_singleton.world.mt');        
        @:nameGen = import(module:'game_singleton.namegen.mt');
        @:story = import(module:'game_singleton.story.mt');
        @:island = {
            island : empty
        }
        breakpoint();
        item.setIslandGenAttributes(
            levelHint:  story.levelHint,//user.level => Number,
            nameHint:   nameGen.island(),
            tierHint : 1
        );
        
        item.price = 1;
    }
    
})

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
    tier: 0,
    keyItem : false,
    levelMinimum : 1000000000,
    canHaveEnchants : false,
    canHaveTriggerEnchants : false,
    enchantLimit : 0,
    hasQuality : false,
    hasMaterial : false,
    isApparel : false,    isUnique : true,
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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {     
    
        @:world = import(module:'game_singleton.world.mt');        
        @:nameGen = import(module:'game_singleton.namegen.mt');
        @:story = import(module:'game_singleton.story.mt');
        @:island = {
            island : empty
        }

        item.setIslandGenAttributes(
            levelHint:  story.levelHint+1,
            nameHint:   nameGen.island(),
            tierHint : 2
        );
        
        item.price = 1;
    }
    
})    

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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {     
    
        @:world = import(module:'game_singleton.world.mt');        
        @:nameGen = import(module:'game_singleton.namegen.mt');
        @:story = import(module:'game_singleton.story.mt');
        @:island = {
            island : empty
        }

        item.setIslandGenAttributes(
            levelHint:  story.levelHint+2,
            nameHint:   nameGen.island(),
            tierHint : 3
        );
        
        item.price = 1;
    }
    
})    

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
    attributes : 
        ATTRIBUTE.SHARP |
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {     
    
        @:world = import(module:'game_singleton.world.mt');        
        @:nameGen = import(module:'game_singleton.namegen.mt');
        @:story = import(module:'game_singleton.story.mt');
        @:island = {
            island : empty
        }

        item.setIslandGenAttributes(
            levelHint:  story.levelHint+3,
            nameHint:   nameGen.island(),
            tierHint : 4
        );
        
        item.price = 1;
    }
    
})       

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
    
        @:world = import(module:'game_singleton.world.mt');        
        @:nameGen = import(module:'game_singleton.namegen.mt');
        @:island = if (creationHint != empty) ::<={
            return {
                levelHint:  (creationHint.levelHint) => Number,
                nameHint:   (creationHint.nameHint)  => String,
                island : empty
            }
        } else ::<= {
            return {
                nameHint: nameGen.island(),
                levelHint: user.level+1,
                island : empty
            }
        }
        
        @:levelToStratum = ::(level) {
            return match((level / 5)->floor) {
              (0): 'IV',
              (1): 'III',
              (2): 'II',
              (3): 'I',
              default: 'Unknown'
            }
        }
        
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


Item.Base.new(data : {
    name : "Sentimental Box",
    description: 'A box of sentimental value. You feel like you should open it right away.',
    examine : '',
    equipType: TYPE.TWOHANDED,
    rarity : 100,
    weight : 10,
    canBeColored : false,
    basePrice: 100,
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
    equipMod : StatSet.new(
        ATK: 15,
        SPD: -5,
        DEX: -5
    ),
    useEffects : [
        'Sentimental Box',
    ],
    equipEffects : [],
    attributes : 
        ATTRIBUTE.SHARP  |
        ATTRIBUTE.METAL
    ,
    onCreate ::(item, user, creationHint) {     

    }
    
})    


    


return Item;
