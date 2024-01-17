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
@:ItemEnchantCondition = import(module:'game_database.itemenchantcondition.mt');
@:random = import(module:'game_singleton.random.mt');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:databaseItemMutatorClass = import(module:'game_function.databaseitemmutatorclass.mt');

@:CONDITION_CHANCES = [
    10,
    33,
    60,
    80,
    100
];

@:CONDITION_CHANCE_NAMES = [
    'rarely',
    'sometimes',
    'often',
    'very often',
    'always'
];




@:ItemEnchant = databaseItemMutatorClass(
    name : 'Wyvern.ItemEnchant',
    items : {
        condition : empty,
        conditionChance : empty,
        conditionChanceName  : empty   
    },

    database: Database.new(
        name : 'Wyvern.ItemEnchant.Base',
        attributes : {
            name : String,
            description : String,
            levelMinimum : Number,
            equipMod : StatSet.type, // percentages
            useEffects : Object,
            equipEffects : Object,
            triggerConditionEffects : Object,
            priceMod : Number,
            tier : Number
        }
    ),

    define:::(this, state) {
        
        this.interface = {
            initialize::{},
            defaultLoad ::(base, conditionHint) {
                state.base = base;
                
                if (base.triggerConditionEffects->keycount > 0) ::<= {
                    if (conditionHint != empty) ::<= {
                        state.condition = ItemEnchantCondition.find(name:conditionHint);
                    } else ::<= {
                        state.condition = ItemEnchantCondition.getRandom();
                    }
                    @conditionIndex = random.pickArrayItem(list:CONDITION_CHANCES->keys);
                    state.conditionChance = CONDITION_CHANCES[conditionIndex];
                    state.conditionChanceName = CONDITION_CHANCE_NAMES[conditionIndex];
                }
                return this;
            },
            

            description : {
                get ::{
                    when(state.condition == empty) state.base.description;
                    return state.condition.description + (state.base.description)->replace(key:'$1', with: state.conditionChanceName);
                    
                }
            },
            
            name : {
                get ::{
                    when(state.condition == empty) state.base.name;
                    breakpoint();
                    return state.condition.name + ': ' + state.base.name;
                }
            },
            
            onTurnCheck ::(wielder, item, battle) {
                when(state.condition == empty) empty;
                if (state.condition.onTurnCheck(wielder, item, battle) == true) ::<= {
                    when(!random.try(percentSuccess:state.conditionChance)) empty;
                
                    foreach(state.base.triggerConditionEffects)::(i, effectName) {
                        wielder.addEffect(
                            from:wielder, name: effectName, durationTurns: 1, item
                        );                        
                    }
                }
            }
        }
    }

);


ItemEnchant.database.newEntry(
    data : {
        name : 'Protect',
        description : ', will $1 cast Protect on the wielder for a while, which greatly increases defense.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 350,
        tier : 0,
        
        triggerConditionEffects : [
            'Trigger Protect' // 1 HP
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Evade',
        description : ', will $1 allow the wielder to evade attacks the next turn.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 350,
        tier : 1,
        
        triggerConditionEffects : [
            'Trigger Evade' // 100% next turn
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)



ItemEnchant.database.newEntry(
    data : {
        name : 'Regen',
        description : ', will $1 slightly recover the users wounds.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 350,
        tier : 0,
        
        triggerConditionEffects : [
            'Trigger Regen'
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Chance to Break',
        description : ', will $1 break.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: -1000,
        tier : 1,
        
        triggerConditionEffects : [
            'Trigger Break Chance'
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)


ItemEnchant.database.newEntry(
    data : {
        name : 'Chance to Hurt',
        description : ', will $1 hurt the wielder.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: -200,
        tier : 0,
        
        triggerConditionEffects : [
            'Trigger Hurt Chance'
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Chance to Fatigue',
        description : ', will $1 fatigue the wielder.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: -200,
        tier : 0,
        
        triggerConditionEffects : [
            'Trigger Fatigue Chance'
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)


ItemEnchant.database.newEntry(
    data : {
        name : 'Spikes',
        description : ', will $1 cast a spell that damages an enemy when attacked for a few turns.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 350,
        tier : 0,
        
        triggerConditionEffects : [
            'Trigger Spikes'
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)

/*
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


ItemEnchant.database.newEntry(
    data : {
        name : 'Ease',
        description : ', will $1 recover from mental fatigue.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 350,
        tier : 1,
        
        triggerConditionEffects : [
            'Trigger AP Regen'
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Shield',
        description : ', will $1 cast Shield for a while, which may block attacks.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 250,
        tier : 0,
        
        triggerConditionEffects : [
            'Trigger Shield' 
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Boost Strength',
        description : ', will $1 boost the wielder\'s power for a while.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 250,
        tier : 0,
        
        triggerConditionEffects : [
            'Trigger Strength Boost'
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Boost Defense',
        description : ', will $1 boost the wielder\'s defense for a while.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 250,
        tier : 0,
        
        triggerConditionEffects : [
            'Trigger Defense Boost'
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Boost Mind',
        description : ', will $1 boost the wielder\'s mental acquity for a while.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 250,
        tier : 0,
        
        triggerConditionEffects : [
            'Trigger Mind Boost'
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Boost Dex',
        description : ', will $1 boost the wielder\'s dexterity for a while.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 250,
        tier : 0,
        
        triggerConditionEffects : [
            'Trigger Dex Boost'
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Boost Speed',
        description : ', will $1 boost the wielder\'s speed for a while.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 250,
        tier : 0,
        
        triggerConditionEffects : [
            'Trigger Speed Boost'
        ],
        
        equipEffects : [
        ],
        
        useEffects : []
    }
)



ItemEnchant.database.newEntry(
    data : {
        name : 'Burning',
        description : 'The material its made of is warm to the touch. Grants a fire aspect to attacks and gives ice resistance when used as armor.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 200,
        tier : 1,
        
        triggerConditionEffects : [
        ],
        
        equipEffects : [
            "Burning"
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Icy',
        description : 'The material its made of is cold to the touch. Grants an ice aspect to attacks and gives fire resistance when used as armor.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 200,
        tier : 1,
        
        triggerConditionEffects : [
        ],
        
        equipEffects : [
            "Icy"
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Shock',
        description : 'The material its made of gently hums. Grants a thunder aspect to attacks and gives thunder resistance when used as armor.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 200,
        tier : 1,
        
        triggerConditionEffects : [
        ],
        
        equipEffects : [
            "Shock"
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Toxic',
        description : 'The material its made has been made poisonous. Grants a poison aspect to attacks and gives poison resistance when used as armor.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 200,
        tier : 1,
        
        triggerConditionEffects : [
        ],
        
        equipEffects : [
            "Toxic"
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Shimmering',
        description : 'The material its made of glows softly. Grants a light aspect to attacks and gives dark resistance when used as armor.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 200,
        tier : 1,
        
        triggerConditionEffects : [
        ],
        
        equipEffects : [
            "Shimmering"
        ],
        
        useEffects : []
    }
)

ItemEnchant.database.newEntry(
    data : {
        name : 'Dark',
        description : 'The material its made of is very dark. Grants a dark aspect to attacks and gives light resistance when used as armor.',
        equipMod : StatSet.new(
        ),
        levelMinimum : 1,
        priceMod: 200,
        tier : 1,
        
        triggerConditionEffects : [
        ],
        
        equipEffects : [
            "Dark"
        ],
        
        useEffects : []
    }
)



ItemEnchant.database.newEntry(
    data : {
        name : 'Rune: Power',
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
        description : 'Somehow, cursed magicks have seeped into this, which greatly alters the stats of the item.',
        equipMod : StatSet.new(
            DEF: -70,
            ATK: -70,
            INT: 100,
            SPD: 20
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
        description : 'Set with a large bloodstone, shining sinisterly. This greatly alters the stats of the item.',
        equipMod : StatSet.new(
            SPD: 30,
            DEX: 30,
            ATK: 30,
            DEF: 30,
            INT: 30,
            HP: -40
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
        description : 'Set with a large soulstone, shining sinisterly. This greatly alters the stats of the item.',
        equipMod : StatSet.new(
            SPD: 30,
            DEX: 30,
            ATK: 30,
            DEF: 30,
            INT: 30,
            AP: -40
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
        description : 'Imbued with a stamina aura; it softly glows green.',
        equipMod : StatSet.new(
            SPD: -15,
            HP:  25
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
        description : 'Imbued with a stamina aura; it softly glows red.',
        equipMod : StatSet.new(
            ATK: -15,
            HP:  25
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
        description : 'Imbued with a stamina aura; it softly glows blue with a glimmer.',
        equipMod : StatSet.new(
            DEF: 15,
            HP:  25
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
        description : 'Imbued with a stamina aura; it softly glows yellow.',
        equipMod : StatSet.new(
            INT: -15,
            HP:  25
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
        description : 'Imbued with a stamina aura; it softly glows orange.',
        equipMod : StatSet.new(
            DEX: -15,
            HP:  25
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
        description : 'Imbued with a stamina aura; it softly glows silver.',
        equipMod : StatSet.new(
            AP: -15,
            HP:  25
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

return ItemEnchant;
