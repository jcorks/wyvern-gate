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
@:ItemEnchantCondition = import(module:'game_class.itemenchantcondition.mt');


@:ItemEnchant = class(
    name : 'Wyvern.ItemEnchant',
    statics : {
        Base : empty
    },
    define:::(this) {
        @base_;
        @condition;
        
        this.constructor = ::(base, conditionHint, state) {
            base_ = base;
            when(state != empty) ::<= {
                this.state = state;
                return this;
            };
            
            if (base.triggerConditionEffects->keycount > 0) ::<= {
                if (conditionHint != empty) ::<= {
                    condition = ItemEnchantCondition.database.find(name:conditionHint);
                } else ::<= {
                    condition = ItemEnchantCondition.database.getRandom();
                };
            };
            return this;
        };
        
        this.interface = {
            description : {
                get ::{
                    when(condition == empty) base_.description;
                    return condition.description + base_.description;
                    
                }
            },
            
            name : {
                get ::{
                    when(condition == empty) base_.name;
                    breakpoint();
                    return condition.name + ': ' + base_.name;
                }
            },
            
            base : {
                get ::<- base_
            },
            
            onTurnCheck ::(wielder, item, battle) {
                when(condition == empty) empty;
                if (condition.onTurnCheck(wielder, item, battle) == true) ::<= {
                    base_.triggerConditionEffects->foreach(do:::(i, effectName) {
                        wielder.addEffect(
                            from:wielder, name: effectName, durationTurns: 1, item
                        );                        
                    });
                };
            },
            
            state : {
                get ::{
                
                },
                
                set ::(value) {
                
                }
            }
        };
    }

);


ItemEnchant.Base = class(
    name : 'Wyvern.ItemEnchant.Base',
    statics : {
        database : empty
    },
    define:::(this) {
        Database.setup(
            item: this,
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
        );
        
        this.interface = {
            new::(conditionHint) {
                return ItemEnchant.new(base:this, conditionHint);
            }
        };
    }
);


ItemEnchant.Base.database = Database.new(
    items : [


        ItemEnchant.Base.new(
            data : {
                name : 'Protect',
                description : ', will cast Protect on the wielder for a while, which greatly increases defense.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Evade',
                description : ', will allow the wielder to evade attacks the next turn.',
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
        ),



        ItemEnchant.Base.new(
            data : {
                name : 'Regen',
                description : ', will slightly recover the users wounds.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Spikes',
                description : ', will damage an enemy when attacked for a few turns.',
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
        ),



        ItemEnchant.Base.new(
            data : {
                name : 'Ease',
                description : ', will recover from mental fatigue.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Shield',
                description : ', casts Shield for a while, which may block attacks.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Boost Strength',
                description : ', will boost the wielder\'s power for a while.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Boost Defense',
                description : ', will boost the wielder\'s defense for a while.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Boost Mind',
                description : ', will boost the wielder\'s mental acquity for a while.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Boost Dex',
                description : ', will boost the wielder\'s dexterity for a while.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Boost Speed',
                description : ', will boost the wielder\'s speed for a while.',
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
        ),



        ItemEnchant.Base.new(
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
        ),

        ItemEnchant.Base.new(
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
        ),

        ItemEnchant.Base.new(
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
        ),

        ItemEnchant.Base.new(
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
        ),

        ItemEnchant.Base.new(
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
        ),

        ItemEnchant.Base.new(
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
        ),



        ItemEnchant.Base.new(
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
        ),
        
        ItemEnchant.Base.new(
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
        ),        

        ItemEnchant.Base.new(
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
        ), 

        ItemEnchant.Base.new(
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
        ),

        ItemEnchant.Base.new(
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
        ),


        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Morion',
                description : 'Set with an enchanted morion stone.',
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
        ),
        
        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Amethyst',
                description : 'Set with an enchanted amethyst.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Citrine',
                description : 'Set with an enchanted citrine stone.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Garnet',
                description : 'Set with an enchanted garnet stone.',
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
        ),


        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Praesolite',
                description : 'Set with an enchanted praesolite stone.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Aquamarine',
                description : 'Set with an enchanted aquamarine stone.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Diamond',
                description : 'Set with an enchanted diamond stone.',
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
        ),
        
        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Pearl',
                description : 'Set with an enchanted pearl.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Ruby',
                description : 'Set with an enchanted ruby.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Sapphire',
                description : 'Set with an enchanted sapphire.',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Opal',
                description : 'Set with an enchanted opal stone.',
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
        ),


        ItemEnchant.Base.new(
            data : {
                name : 'Cursed',
                description : 'Somehow, cursed magicks have seeped into this.',
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
        ),


        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Bloodstone',
                description : 'Set with a large bloodstone, shining sinisterly',
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
        ),

        ItemEnchant.Base.new(
            data : {
                name : 'Inlet: Soulstone',
                description : 'Set with a large soulstone, shining sinisterly',
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
        ),

    
    ]
);

return ItemEnchant;
