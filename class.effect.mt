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
@:dialogue = import(module:'singleton.dialogue.mt');
@:Damage = import(module:'class.damage.mt');
@:Scene = import(module:'class.scene.mt');
@:random = import(module:'singleton.random.mt');

@:Effect = class(
    statics : {
        database : empty
    },
    define:::(this) {
        Database.setup(
            item: this,
            attributes : {
                name : String,
                description : String,
                battleOnly : Boolean,
                skipTurn : Boolean, // whether this effect makes the user not act for a turn
                stats : StatSet.type,
                onAffliction : Function, //Called once when first activated
                onGivenDamage : Function, // Called AFTER the user has explicitly damaged a target
                onGiveDamage : Function, // called when user is giving damage
                onRemoveEffect : Function, //Called once when removed. All effects will be removed at some point.
                onDamage : Function, // when the holder of the effect is hurt
                onNextTurn : Function, //< on end phase of turn once added as an effect. Not called if duration is 0
                onStatRecalculate : Function // on start of a turn. Not called if duration is 0
            }   
        );
    }
);




Effect.database = Database.new(
    items : [
    
    
        ////////////////////// SPECIAL EFFECTS
        
        Effect.new(
            data : {
                name : 'EVENTEFFECT::scene0_0_sylviaenter',
                description: '',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    Scene.database.find(name:'scene0_0_sylviaenter').act();
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                }
            }
        ),
        
        
        
        
        
        //////////////////////
    
    
    
        Effect.new(
            data : {
                name : 'Defend',
                description: 'Reduces damage by 40%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: holder.name + ' takes a defensive stance!'
                    );
                
                },

                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                onDamage : ::(user, item, holder, from, damage) {
                    dialogue.message(text:holder.name + "'s defending stance reduces damage!");
                    damage.amount *= 0.6;
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                }
            }
        ),
        
        Effect.new(
            data : {
                name : 'Defensive Stance',
                description: 'ATK -50%, DEF +75%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(ATK:-50, DEF:75),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: holder.name + ' changes their stance to be defensive!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                }
            }
        ),        

       
        Effect.new(
            data : {
                name : 'Offsensive Stance',
                description: 'DEF -50%, ATK +75%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(DEF:-50, ATK:75),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: holder.name + ' changes their stance to be offensive!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                }
            }
        ), 

        Effect.new(
            data : {
                name : 'Light Stance',
                description: 'ATK -50%, SPD +75%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(ATK:-50, SPD:75),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: holder.name + ' changes their stance to be light on their feet!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                }
            }
        ), 
        
        Effect.new(
            data : {
                name : 'Heavy Stance',
                description: 'SPD -50%, DEF +75%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(SPD:-50, DEF:75),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: holder.name + ' changes their stance to be heavy and sturdy!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                }
            }
        ),         
        

        Effect.new(
            data : {
                name : 'Meditative Stance',
                description: 'SPD -50%, INT +75%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(SPD:-50, INT:75),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: holder.name + ' changes their stance for mental focus!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                }
            }
        ),         
        

        Effect.new(
            data : {
                name : 'Striking Stance',
                description: 'SPD -30%, DEF -30%, ATK +100%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(SPD:-30, DEF:-30, ATK:100),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: holder.name + ' changes their stance for maximum attack!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                }
            }
        ), 
        
        Effect.new(
            data : {
                name : 'Reflective Stance',
                description: 'Attack retaliation',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: holder.name + ' changes their stance to reflect attacks!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                onDamage : ::(user, item, holder, from, damage) {
                    when (holder == from) empty;
                    // handles the DBZ-style case pretty well!
                    @:amount = (damage.amount / 2)->floor;

                    when(amount <= 0) empty;
                    dialogue.message(
                        text: holder.name + ' retaliates!'
                    );


                    from.damage(from:holder, damage:Damage.new(
                        amount,
                        damageType:Damage.TYPE.PHYS,
                        damageClass:Damage.CLASS.HP
                    ));
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                }
            }
        ),                 


        Effect.new(
            data : {
                name : 'Evasive Stance',
                description: '%50 chance damage nullify when from others.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: holder.name + ' changes their stance to evade attacks!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                onDamage : ::(user, item, holder, from, damage) {
                    when (holder == from) empty;
                    when(Number.random() > 5) empty;

                    dialogue.message(
                        text: holder.name + ' evades!'
                    );

                    damage.amount = 0;
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                }
            }
        ),               

        Effect.new(
            data : {
                name : 'Sneaked',
                description: 'Guarantees next damage from user is x3',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:user.name + " snuck behind " + holder.name + '!');
                
                },

                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onDamage : ::(user, item, holder, from, damage) {
                    breakpoint();
                    if (from == user) ::<= {
                        dialogue.message(text:user.name + "'s sneaking takes " + holder.name + ' by surprise!');
                        damage.amount *= 3;
                    };
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),
        

        Effect.new(
            data : {
                name : 'Mind Focused',
                description: 'INT +100%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    INT: 100
                ),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:holder.name + ' focuses their mind');
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s focus returns to normal.');
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),        


        Effect.new(
            data : {
                name : 'Protect',
                description: 'DEF +100%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    DEF: 100
                ),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:holder.name + ' is covered in a shell of light');
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s shell of light fades away.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  
        
        Effect.new(
            data : {
                name : 'Weapon Affinity',
                description: 'User has their profession\'s ideal weapon. ATK,DEF,SPD,INT +20%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    ATK: 20,
                    DEF: 20,
                    SPD: 20,
                    INT: 20
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),         

        Effect.new(
            data : {
                name : 'Night Veil',
                description: 'DEF +40%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    DEF: 50
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s Night Veil fades away.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  

        Effect.new(
            data : {
                name : 'Dayshroud',
                description: 'DEF +40%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    DEF: 50
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s Dayshroud fades away.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  

        Effect.new(
            data : {
                name : 'Call of the Night',
                description: 'ATK +40%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    DEF: 50
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s Call of the Night fades away.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  


        Effect.new(
            data : {
                name : 'Lunacy',
                description: 'Skips turn and, instead, attacks a random enemy. ATK,DEF +70%.',
                battleOnly : true,
                skipTurn : true,
                stats: StatSet.new(
                    DEF: 70,
                    ATK: 70
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s Lunacy fades away.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    dialogue.message(text:holder.name + ' attacks in a blind rage!');
                    holder.attack(
                        target:random.pickArrayItem(list:holder.enemies),
                        amount:holder.stats.ATK * (0.5),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP
                    );                   
                

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),


        Effect.new(
            data : {
                name : 'Greater Call of the Night',
                description: 'ATK +100%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    DEF: 100
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s Call of the Night fades away.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  

        Effect.new(
            data : {
                name : 'Greater Night Veil',
                description: 'DEF +100%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    DEF: 100
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s Night Veil fades away.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  


        Effect.new(
            data : {
                name : 'Greater Dayshroud',
                description: 'DEF +100%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    DEF: 100
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s Dayshroud fades away.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  

        Effect.new(
            data : {
                name : 'Moonsong',
                description: 'Heals 5% HP every turn',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s Moonsong fades.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    holder.heal(amount:holder.stats.HP * 0.05);
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  
        
        Effect.new(
            data : {
                name : 'Sol Attunement',
                description: 'Heals 5% HP every turn',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s Sol Attunement fades.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    holder.heal(amount:holder.stats.HP * 0.05);
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),          
        
        Effect.new(
            data : {
                name : 'Greater Moonsong',
                description: 'Heals 15% HP every turn',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s Moonsong fades.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    holder.heal(amount:holder.stats.HP * 0.15);
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),       
        
        Effect.new(
            data : {
                name : 'Greater Sol Attunement',
                description: 'Heals 15% HP every turn',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s Sol Attunement fades.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    holder.heal(amount:holder.stats.HP * 0.15);
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),          
           
        Effect.new(
            data : {
                name : 'Grace',
                description: 'If hurt while HP is 0, the damage is nullified and this effect disappears.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:'A halo appears above ' + holder.name + '!');
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + '\'s halo disappears.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                    if (holder.hp == 0) ::<= {
                        damage.amount = 0;
                        dialogue.message(text:holder.name + ' is protected from death!');
                        holder.removeEffects(
                            effectBases : [
                                Effect.database.find(name:'Grace')
                            ]
                        );
                    };
                       
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),     
           
        
        Effect.new(
            data : {
                name : 'Consume Item',
                description: 'The item is destroyed in the process of its effects',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: "The " + item.name + ' is consumed.'
                    );
                    item.throwOut();                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),
        
        Effect.new(
            data : {
                name : 'Break Item',
                description: 'The item is destroyed in the process of misuse or strain',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    if (Number.random() > 0.5) ::<= {
                        dialogue.message(
                            text: "The " + item.name + ' broke.'
                        );
                        item.throwOut();                
                    };
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),        

        Effect.new(
            data : {
                name : 'Fling',
                description: 'The item is violently lunged at a target, likely causing damage. The target may catch the item.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: user.name + ' flung the ' + item.name + ' at ' + holder.name + '!'
                    );

                    item.throwOut();
                    if (Number.random() > 0.8) ::<= {
                        holder.inventory.add(item);
                        dialogue.message(
                            text: holder.name + ' caught the flung ' + item.name + '!!'
                        );
                    } else ::<= {
                        holder.damage(
                            from: user,
                            damage: Damage.new(
                                amount:user.stats.ATK*(item.base.weight * 0.1),
                                damageType : Damage.TYPE.NEUTRAL,
                                damageClass: Damage.CLASS.HP
                            )
                        );
                    };
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),      

        Effect.new(
            data : {
                name : 'HP Recovery: Minor',
                description: 'Heals 20% of HP.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    holder.heal(amount:holder.stats.HP*0.2);
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),
        
        Effect.new(
            data : {
                name : 'Treasure I',
                description: 'Heals 20% of HP.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    @:world = import(module:'singleton.world.mt');
                    @:amount = (50 + Number.random()*400)->floor;                    
                    dialogue.message(text:'The party found ' + amount + 'G.');
                    world.party.inventory.addGold(amount);                    
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),        

        Effect.new(
            data : {
                name : 'Field Cook',
                description: 'Chance to cook a meal after battle.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    @:world = import(module:'singleton.world.mt');
                    
                    
                    when(Number.random() > 0.7) empty;
                    when(user.isIncapacitated()) empty;
                    when(!world.party.isMember(entity:holder)) empty;


                    dialogue.message(
                        text: 'After the battle, ' + holder.name + ' found some food and cooked a meal for the party.'
                    );
                    world.party.members->foreach(do:::(index, member) {
                        member.heal(amount:member.stats.HP * 0.1);
                        member.healMP(amount:member.stats.MP * 0.1);
                    });
                    
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),

        Effect.new(
            data : {
                name : 'Penny Picker',
                description: 'Looks on the ground for G after battle.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    @:world = import(module:'singleton.world.mt');
                    
                    
                    when(Number.random() > 0.7) empty;
                    when(user.isIncapacitated()) empty;
                    when(!world.party.isMember(entity:holder)) empty;


                    @:amt = (Number.random() * 20)->ceil;
                    dialogue.message(
                        text: 'After the battle, ' + holder.name + ' found ' + amt + 'G on the ground dropped from the battling party.'
                    );
                    world.party.addGold(amount:amt);
                    
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),


        Effect.new(
            data : {
                name : 'Trained Hand',
                description: 'ATK +30%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(ATK:30),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {                    
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),
        
        Effect.new(
            data : {
                name : 'Focus Perception',
                description: 'ATK +30%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(ATK:30),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {                    
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),   

        Effect.new(
            data : {
                name : 'Cheered',
                description: 'ATK +25%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(ATK:25),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {                    
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),           
             

        Effect.new(
            data : {
                name : 'Defend Other',
                description: 'Takes hits for another.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:user.name + ' resumes a normal stance!');
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                    @:amount = damage.amount;
                    damage.amount = 0;
                    dialogue.message(text:user.name + ' leaps in front of ' + holder.name + ', taking damage in their stead!');

                    user.damage(
                        from,
                        damage: Damage.new(
                            amount,
                            damageType : Damage.TYPE.NEUTRAL,
                            damageClass: Damage.CLASS.HP
                        )
                    );                    
                    

                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),



        Effect.new(
            data : {
                name : 'Convinced',
                description: 'Unable to act.',
                battleOnly : true,
                skipTurn : true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                    if (turnIndex >= turnCount)
                        dialogue.message(text:holder.name + ' realizes ' + user.name + "'s argument was complete junk!")
                    else                    
                        dialogue.message(text:holder.name + ' thinks about ' + user.name + "'s argument!");
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),
        
        Effect.new(
            data : {
                name : 'Grappled',
                description: 'Unable to act.',
                battleOnly : true,
                skipTurn : true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                    if (turnIndex >= turnCount)
                        dialogue.message(text:holder.name + ' broke free from the grapple!')
                    else                    
                        dialogue.message(text:holder.name + ' is being grappled and is unable to move!');
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),   
        
        Effect.new(
            data : {
                name : 'Grappling',
                description: 'Unable to act.',
                battleOnly : true,
                skipTurn : true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                    dialogue.message(text:holder.name + ' is in the middle of grappling and cannot move!');
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),                
        
        Effect.new(
            data : {
                name : 'Running',
                description: 'Unable to act.',
                battleOnly : true,
                skipTurn : true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(
                        text: holder.name + ' starts to run from the fight!'
                    );
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                    dialogue.message(text: user.name + ' runs from the battle!');
                    user.requestsRemove = true;
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),        

        Effect.new(
            data : {
                name : 'Bribed',
                description: 'Unable to act.',
                battleOnly : true,
                skipTurn : true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),
        Effect.new(
            data : {
                name : 'Stunned',
                description: 'Unable to act.',
                battleOnly : true,
                skipTurn : true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:holder.name + ' was stunned!');
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + ' came to their senses!');
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),

        Effect.new(
            data : {
                name : 'Sharpen',
                description: 'ATK +5%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    ATK: 5
                ),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),
        
        Effect.new(
            data : {
                name : 'Weaken Armor',
                description: 'DEF -5%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    DEF: -5
                ),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),        

        Effect.new(
            data : {
                name : 'Dull Weapon',
                description: 'ATK -5%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    ATK: -5
                ),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),
        
        Effect.new(
            data : {
                name : 'Strengthen Armor',
                description: 'DEF +5%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    DEF: 5
                ),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  


        Effect.new(
            data : {
                name : 'Lunar Affinity',
                description: 'INT,DEF,ATK +40% if night time.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    
                ),
                onAffliction : ::(user, item, holder) {
                    @:world = import(module:'singleton.world.mt');

                    if (world.time > world.TIME.EVENING) ::<= {
                        dialogue.message(text:'The moon shimmers... ' + holder.name +' softly glows');                    
                    };
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    @:world = import(module:'singleton.world.mt');

                    if (world.time > world.TIME.EVENING) ::<= {
                        stats.modRate(stats:StatSet.new(INT:40, DEF:40, ATK:40));
                    };                    
                }
            }
        ),

        Effect.new(
            data : {
                name : 'Solar Affinity',
                description: 'INT,DEF,ATK +40% if day time.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    
                ),
                onAffliction : ::(user, item, holder) {
                    @:world = import(module:'singleton.world.mt');

                    if (world.time > world.TIME.EVENING) ::<= {
                        dialogue.message(text:'The sun intensifies... ' + holder.name +' softly glows');                    
                    };
                },
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    @:world = import(module:'singleton.world.mt');

                    if (world.time < world.TIME.EVENING) ::<= {
                        stats.modRate(stats:StatSet.new(INT:40, DEF:40, ATK:40));
                    };                    
                }
            }
        ),

        
        Effect.new(
            data : {
                name : 'Non-combat Weapon',
                description: '20% chance to deflect attack then break weapon.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                    if (Number.random() > 0.8 && damage.damageType == Damage.TYPE.PHYS) ::<= {
                        @:Entity = import(module:'class.entity.mt');
                    
                        dialogue.message(text:holder.name + " parries the blow, but their weapon breaks in the process!");
                        damage.amount = 0;
                        @:item = holder.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L);
                        holder.unequip(slot:Entity.EQUIP_SLOTS.HAND_L, silent:true);
                        item.throwOut();                      
                    };
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),      
        Effect.new(
            data : {
                name : 'Assassin\'s Pride',
                description: 'SPD, ATK +25% for each slain.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                
                onGivenDamage : ::(user, item, holder, to) {
                    if (to.isIncapacitated()) ::<= {
                        dialogue.message(text:holder.name + "'s ending blow to " + to.name + " increases "+ holder.name + "'s abilities due to their Assassin's Pride.");                        
                        user.addEffect(from:holder, name: 'Pride', durationTurns: 10);                        
                    };
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),        
        Effect.new(
            data : {
                name : 'Pride',
                description: 'SPD, ATK +25%',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    ATK:25,
                    SPD:25
                ),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " is feeling prideful.");
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },


                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),        
          
        Effect.new(
            data : {
                name : 'Dueled',
                description: 'If attacked by user, 1.5x damage.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                    if (user == from) ::<= {
                        dialogue.message(text: user.name + '\'s duel challenge focuses damage!');
                        damage.amount *= 1.5;
                    };
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  
        Effect.new(
            data : {
                name : 'Consume Item Partially',
                description: 'The item has a chance of being used up',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    if (Number.random() > 0.7) ::<={
                        dialogue.message(
                            text: "The " + item.name + ' is used in its entirety.'
                        );
                        item.throwOut();                                    
                    } else ::<={
                        dialogue.message(
                            text: "A bit of the " + item.name + ' is used.'
                        );                    
                    };
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  
        
        Effect.new(
            data : {
                name : 'Bleeding',
                description: 'Damage every turn to holder. ATK,DEF,SPD -20%.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    ATK: -20,
                    DEF: -20,
                    SPD: -20
                ),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " started to bleed out!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " is no longer bleeding out.");
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    dialogue.message(text:holder.name + " suffered from bleeding!");
                    
                    holder.damage(
                        from: holder,
                        damage: Damage.new(
                            amount:holder.HP*0.05,
                            damageType : Damage.TYPE.NEUTRAL,
                            damageClass: Damage.CLASS.HP
                        )
                    );
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),     

        Effect.new(
            data : {
                name : 'Learn Skill',
                description: 'Acquire a new skill',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(
                    
                ),
                onAffliction : ::(user, item, holder) {

                    @:learned = holder.profession.gainSP(amount:1);
                    learned->foreach(do:::(index, ability) {
                        holder.learnAbility(name:ability);
                        dialogue.message(text: holder.name + ' learned the ability: ' + ability);                        
                    });
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ), 
        


        
        
        
        //////////////////////////////
        /// STATUS AILMENTS
        
        Effect.new(
            data : {
                name : 'Poisoned',
                description: 'Damage every turn to holder.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " was poisoned!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " is no longer poisoned.");
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    dialogue.message(text:holder.name + " was hurt by the poison!");
                    
                    holder.damage(
                        from: holder,
                        damage: Damage.new(
                            amount:holder.HP*0.05,
                            damageType : Damage.TYPE.NEUTRAL,
                            damageClass: Damage.CLASS.HP
                        )
                    );
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),     

        Effect.new(
            data : {
                name : 'Blind',
                description: '50% chance to miss attacks.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " was blinded!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " is no longer blind.");
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                    when (Number.random() > 0.5) empty;
                    dialogue.message(text:holder.name + " missed in their blindness!");
                    damage.amount = 0;
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),             
          

        Effect.new(
            data : {
                name : 'Burned',
                description: '50% chance to get damage each turn.',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " was burned!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " is no longer burned.");
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    when(Number.random() > 0.5) empty;
                    dialogue.message(text:holder.name + " was hurt by burns!");
                    holder.damage(
                        from:holder,
                        damage : Damage.new(
                            amount: user.stats.HP / 16,
                            damageClass: Damage.CLASS.HP,
                            damageType: Damage.TYPE.FIRE
                        )
                    );
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ), 
        Effect.new(
            data : {
                name : 'Frozen',
                description: 'Unable to act.',
                battleOnly : true,
                skipTurn : true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " was frozen");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " is no longer frozen.");
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),         

        Effect.new(
            data : {
                name : 'Paralyzed',
                description: 'SPD,ATK -100%',
                battleOnly : true,
                skipTurn : true,
                stats: StatSet.new(
                    SPD: -100,
                    ATK: -100
                ),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " was paralyzed");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " is no longer paralyzed.");
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ), 

        Effect.new(
            data : {
                name : 'Petrified',
                description: 'Unable to act. DEF -50%',
                battleOnly : true,
                skipTurn : true,
                stats: StatSet.new(
                    DEF: -50
                ),
                onAffliction : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " was petrified!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    dialogue.message(text:holder.name + " is no longer petrified!");
                },                
                onGivenDamage : ::(user, item, holder, to) {
                },

                onGiveDamage : ::(user, item, holder, to, damage) {
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),
        
    ]
);

return Effect;
