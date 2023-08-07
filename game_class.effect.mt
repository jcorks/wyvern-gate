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
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Scene = import(module:'game_class.scene.mt');
@:random = import(module:'game_singleton.random.mt');

@:Effect = class(
    statics : {
        database  :::<= {
            @db;
            return {
                get ::<- db,
                set ::(value) <- db = value
            }
        }
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
                onPostAttackOther : Function, // Called AFTER the user has explicitly damaged a target
                onPreAttackOther : Function, // called when user is giving damage
                onAttacked : Function, // called when user is attacked, before being damaged.
                onRemoveEffect : Function, //Called once when removed. All effects will be removed at some point.
                onDamage : Function, // when the holder of the effect is hurt
                onNextTurn : Function, //< on end phase of turn once added as an effect. Not called if duration is 0
                onStatRecalculate : Function, // on start of a turn. Not called if duration is 0
                stackable : Boolean // whether multiple of the same effect can coexist
            }   
        );
    }
);




Effect.database = Database.new().initialize(
    items : [
    
    
        ////////////////////// SPECIAL EFFECTS
        
        Effect.new(
            data : {
                name : 'EVENTEFFECT::scene0_0_sylviaenter',
                description: '',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    Scene.database.find(name:'scene0_0_sylviaenter').act();
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                
                onAttacked : ::(user, item, holder, by, damage) {
                
                },


                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                },
            }
        ),
        
        
        
        
        
        //////////////////////
    
    
    
        Effect.new(
            data : {
                name : 'Defend',
                description: 'Reduces damage by 40%',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' takes a defensive stance!'
                    );
                    if (holder.hp < holder.stats.HP * 0.5) ::<= {
                        windowEvent.queueMessage(
                            text: holder.name + ' catches their breath while defending!'
                        );
                        holder.heal(amount:holder.stats.HP * 0.1);
                    }
                },

                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    windowEvent.queueMessage(text:holder.name + "'s defending stance reduces damage!");
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
                name : 'Guard',
                description: 'Reduces damage by 90%',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' takes a guarding stance!'
                    );
                
                },

                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    windowEvent.queueMessage(text:holder.name + "'s defending stance reduces damage significantly!");
                    damage.amount *= 0.9;
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
                stackable: false,
                stats: StatSet.new(ATK:-50, DEF:75),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' changes their stance to be defensive!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(DEF:-50, ATK:75),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' changes their stance to be offensive!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(ATK:-50, SPD:75),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' changes their stance to be light on their feet!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(SPD:-50, DEF:75),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' changes their stance to be heavy and sturdy!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(SPD:-50, INT:75),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' changes their stance for mental focus!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(SPD:-30, DEF:-30, ATK:100),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' changes their stance for maximum attack!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' changes their stance to reflect attacks!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },


                onDamage : ::(user, item, holder, from, damage) {
                    when (holder == from) empty;
                    // handles the DBZ-style case pretty well!
                    @:amount = (damage.amount / 2)->floor;

                    when(amount <= 0) empty;
                    windowEvent.queueMessage(
                        text: holder.name + ' retaliates!'
                    );


                    from.damage(from:holder, damage:Damage.new(
                        amount,
                        damageType:Damage.TYPE.PHYS,
                        damageClass:Damage.CLASS.HP
                    ),dodgeable: true);
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    
                }
            }
        ),                 

        Effect.new(
            data : {
                name : 'Counter',
                description: 'Dodges attacks and retaliates.',
                battleOnly : true,
                skipTurn : true,
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' is prepared for an attack!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },


                onDamage : ::(user, item, holder, from, damage) {
                    @dmg = damage.amount * 0.75;
                    when (dmg < 1) empty;
                    damage.amount = 0;
                    windowEvent.queueMessage(
                        text: holder.name + ' counters!'
                    );


                    holder.attack(
                        target:from,
                        amount: dmg,
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP
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
                name : 'Evasive Stance',
                description: '%50 chance damage nullify when from others.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' changes their stance to evade attacks!'
                    );
                },

                onRemoveEffect : ::(user, item, holder) {
                
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },


                onDamage : ::(user, item, holder, from, damage) {
                    when (holder == from) empty;
                    when(Number.random() > 5) empty;

                    windowEvent.queueMessage(
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:user.name + " snuck behind " + holder.name + '!');
                
                },

                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    breakpoint();
                    if (from == user) ::<= {
                        windowEvent.queueMessage(text:user.name + "'s sneaking takes " + holder.name + ' by surprise!');
                        damage.amount *= 3;
                    }
                    
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
                stackable: false,
                stats: StatSet.new(
                    INT: 100
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + ' focuses their mind');
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s focus returns to normal.');
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(
                    DEF: 100
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + ' is covered in a shell of light!');
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s shell of light fades away.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),  

        Effect.new(
            data : {
                name : 'Shield',
                description: 'DEF +10%, 30% chance to block',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                    DEF: 10
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'A shield of light appears before ' + holder.name + '!');
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s shield of light fades away.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                    if (Number.random() < 0.3) ::<= {
                        windowEvent.queueMessage(text:holder.name + '\'s shield of light blocks the attack!');
                        damage.amount = 0;
                    }                
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),
        

        Effect.new(
            data : {
                name : 'Trigger Protect',
                description: 'Casts Protect',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                    windowEvent.queueMessage(text:'It casts Protect on ' + holder.name + '!');
                    holder.addEffect(
                        from:user, name: 'Protect', durationTurns: 3
                    );                        
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Trigger Evade',
                description: 'Allows the user to evade all attacks for the next turn.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                    holder.addEffect(
                        from:user, name: 'Evade', durationTurns: 1
                    );                        
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Evade',
                description: 'Allows the user to evade all attacks.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + ' is covered in a mysterious wind!');
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                    windowEvent.queueMessage(text:holder.name + '\'s mysterious wind caused the attack to miss!');
                    damage.amount = 0;
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
                name : 'Trigger Regen',
                description: 'Slightly heals wounds.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                    holder.heal(
                        amount: holder.stats.HP * 0.05
                    );                        
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Trigger Spikes',
                description: 'Casts Spikes',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                    windowEvent.queueMessage(text:'It covers ' + holder.name + ' in spikes of light!');
                    holder.addEffect(
                        from:user, name: 'Spikes', durationTurns: 3
                    );                        
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Spikes',
                description: 'DEF +10%, light damage when attacked.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                    DEF: 10
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + ' is covered in spikes of light.');
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                    windowEvent.queueMessage(text:by.name + ' gets hurt by ' + holder.name + '\'s spikes of light!');
                    by.damage(from:holder, damage:Damage.new(
                        amount:random.integer(from:1, to:4),
                        damageType:Damage.TYPE.LIGHT,
                        damageClass:Damage.CLASS.HP
                    ),dodgeable: false);
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s spikes of light fade.');
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
                name : 'Trigger AP Regen',
                description: 'Slightly recovers AP.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                    holder.healAP(
                        amount: holder.stats.AP * 0.05
                    );                        
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Trigger Shield',
                description: 'Casts Shield',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                    windowEvent.queueMessage(text:'It casts Shield on ' + holder.name + '!');
                    holder.addEffect(
                        from:user, name: 'Shield', durationTurns: 3
                    );                        
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Trigger Strength Boost',
                description: 'Triggers a boost in strength.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                    holder.addEffect(
                        from:user, name: 'Strength Boost', durationTurns: 3
                    );                        
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Strength Boost',
                description: 'ATK +70%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(
                    ATK:70
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s power is increased!');
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s power boost fades!');
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
                name : 'Trigger Defense Boost',
                description: 'Triggers a boost in defense.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                    holder.addEffect(
                        from:user, name: 'Defense Boost', durationTurns: 3
                    );                        
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Defense Boost',
                description: 'DEF +70%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(
                    DEF:70
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s defense is increased!');
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s defense boost fades!');
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
                name : 'Trigger Mind Boost',
                description: 'Triggers a boost in mental acuity.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                    holder.addEffect(
                        from:user, name: 'Mind Boost', durationTurns: 3
                    );                        
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Mind Boost',
                description: 'INT +70%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(
                    INT:70
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s mental acuity is increased!');
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s intelligence boost fades!');
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
                name : 'Trigger Dex Boost',
                description: 'Triggers a boost in dexterity.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                    holder.addEffect(
                        from:user, name: 'Dex Boost', durationTurns: 3
                    );                        
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Dex Boost',
                description: 'DEX +70%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(
                    DEX:70
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s dexterity is increased!');
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s dexterity boost fades!');
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
                name : 'Trigger Speed Boost',
                description: 'Triggers a boost in speed.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                    holder.addEffect(
                        from:user, name: 'Speed Boost', durationTurns: 3
                    );                        
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Speed Boost',
                description: 'SPD +70%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(
                    SPD:70
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s speed is increased!');
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s speed boost fades!');
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
                description: 'User has their profession\'s ideal weapon. ATK,DEF,SPD,INT,DEX +60%',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                    ATK: 60,
                    DEF: 60,
                    SPD: 60,
                    INT: 60,
                    DEX: 60
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(
                    DEF: 50
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s Night Veil fades away.');
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
                stackable: false,
                stats: StatSet.new(
                    DEF: 50
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s Dayshroud fades away.');
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
                stackable: false,
                stats: StatSet.new(
                    ATK: 40
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s Call of the Night fades away.');
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
                stackable: false,
                stats: StatSet.new(
                    DEF: 70,
                    ATK: 70
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s Lunacy fades away.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    windowEvent.queueMessage(text:holder.name + ' attacks in a blind rage!');
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
                stackable: false,
                stats: StatSet.new(
                    ATK: 100
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s Call of the Night fades away.');
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
                stackable: false,
                stats: StatSet.new(
                    DEF: 100
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s Night Veil fades away.');
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
                stackable: false,
                stats: StatSet.new(
                    DEF: 100
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s Dayshroud fades away.');
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
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s Moonsong fades.');
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
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s Sol Attunement fades.');
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
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s Moonsong fades.');
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
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s Sol Attunement fades.');
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
                stackable: false,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'A halo appears above ' + holder.name + '!');
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + '\'s halo disappears.');
                },                

                onDamage : ::(user, item, holder, from, damage) {
                    if (holder.hp == 0) ::<= {
                        damage.amount = 0;
                        windowEvent.queueMessage(text:holder.name + ' is protected from death!');
                        holder.removeEffects(
                            effectBases : [
                                Effect.database.find(name:'Grace')
                            ]
                        );
                    }
                       
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
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: "The " + item.name + ' is consumed.'
                    );
                    item.throwOut();                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    if (Number.random() > 0.5) ::<= {
                        windowEvent.queueMessage(
                            text: "The " + item.name + ' broke.'
                        );
                        item.throwOut();                
                    }
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: user.name + ' flung the ' + item.name + ' at ' + holder.name + '!'
                    );
                    
                    windowEvent.queueNoDisplay(
                        onStart::{
                            if (Number.random() > 0.8) ::<= {
                                holder.inventory.add(item);
                                windowEvent.queueMessage(
                                    text: holder.name + ' caught the flung ' + item.name + '!!'
                                );
                            } else ::<= {
                                holder.damage(
                                    from: user,
                                    damage: Damage.new(
                                        amount:user.stats.ATK*(item.base.weight * 0.1),
                                        damageType : Damage.TYPE.NEUTRAL,
                                        damageClass: Damage.CLASS.HP
                                    ),
                                    dodgeable: true                                    
                                );
                            }                        
                        }
                    );

                    item.throwOut();
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'HP Recovery: All',
                description: 'Heals 100% of HP.',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    holder.heal(amount:holder.stats.HP);
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'AP Recovery: All',
                description: 'Heals 100% of AP.',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    holder.healAP(amount:holder.stats.AP);
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                description: 'Opening gives a fair number of G.',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    @:world = import(module:'game_singleton.world.mt');
                    @:amount = (50 + Number.random()*400)->floor;                    
                    windowEvent.queueMessage(text:'The party found ' + amount + 'G.');
                    world.party.inventory.addGold(amount);                    
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    @:world = import(module:'game_singleton.world.mt');
                    
                    
                    when(Number.random() > 0.7) empty;
                    when(user.isIncapacitated()) empty;
                    when(!world.party.isMember(entity:holder)) empty;


                    windowEvent.queueMessage(
                        text: 'After the battle, ' + holder.name + ' found some food and cooked a meal for the party.'
                    );
                    foreach(world.party.members)::(index, member) {
                        member.heal(amount:member.stats.HP * 0.1);
                        member.healAP(amount:member.stats.AP * 0.1);
                    }
                    
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    @:world = import(module:'game_singleton.world.mt');
                    
                    
                    when(Number.random() > 0.7) empty;
                    when(user.isIncapacitated()) empty;
                    when(!world.party.isMember(entity:holder)) empty;


                    @:amt = (Number.random() * 20)->ceil;
                    windowEvent.queueMessage(
                        text: 'After the battle, ' + holder.name + ' found ' + amt + 'G on the ground dropped from the battling party.'
                    );
                    world.party.inventory.addGold(amount:amt);
                    
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Alchemist\'s Scavenging',
                description: 'Scavenges for alchemist ingredients.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    @:world = import(module:'game_singleton.world.mt');
                    @:Item  = import(module:'game_class.item.mt');
                    
                    when(user.isIncapacitated()) empty;
                    when(!world.party.isMember(entity:holder)) empty;
                                        
                    when(Number.random() < 0.5) empty;                    

                    @:amt = 1;
                    windowEvent.queueMessage(
                        text: holder.name + ' scavenged for ingredients...'
                    );
                    windowEvent.queueMessage(
                        text: holder.name + ' found ' + amt + ' ingredient(s).'
                    );

                    for(0, amt)::(i) {                    
                        world.party.inventory.add(item:Item.Base.database.find(name:'Ingredient').new(from:holder));
                    }
                    
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(ATK:30),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {                    
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: true,
                stats: StatSet.new(ATK:30),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {                    
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: true,
                stats: StatSet.new(ATK:25),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {                    
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),           

        Effect.new(
            data : {
                name : 'Poisonroot Growing',
                description: 'Vines grow on target. SPD -10%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,                
                stats: StatSet.new(SPD:-10),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {                    
                    holder.addEffect(from:holder, name:'Poisonroot', durationTurns:30);                            
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),


        Effect.new(
            data : {
                name : 'Poisonroot',
                description: 'Every turn takes poison damage. SPD -10%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(SPD:-10),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {     
                    windowEvent.queueMessage(text:'The poisonroot vines dissipate from ' + holder.name + '.'); 
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    windowEvent.queueMessage(text:user.name + ' is strangled by the poisonroot!');                    
                    holder.damage(from:user, damage: Damage.new(
                        amount: random.integer(from:1, to:4),
                        damageType: Damage.TYPE.POISON,
                        damageClass: Damage.CLASS.HP
                    ),dodgeable: false);                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),

        Effect.new(
            data : {
                name : 'Triproot Growing',
                description: 'Vines grow on target. SPD -10%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(SPD:-10),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {                    
                    holder.addEffect(from:holder, name:'Triproot', durationTurns:30);                            
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),


        Effect.new(
            data : {
                name : 'Triproot',
                description: 'Every turn 40% chance to trip. SPD -10%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(SPD:-10),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {                    
                    windowEvent.queueMessage(text:'The triproot vines dissipate from ' + holder.name + '.'); 
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    if (Number.random() < 0.4) ::<= {
                        windowEvent.queueMessage(text:'The triproot trips ' + holder.name + '!');
                        holder.addEffect(from:holder, name:'Stunned', durationTurns:1);                                                
                    }
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),


        Effect.new(
            data : {
                name : 'Healroot Growing',
                description: 'Vines grow on target. SPD -10%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(SPD:-10),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {                    
                    holder.addEffect(from:holder, name:'Healroot', durationTurns:30);                            
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),


        Effect.new(
            data : {
                name : 'Healroot',
                description: 'Every turn heal 5% HP. SPD -10%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(SPD:-10),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {                    
                    windowEvent.queueMessage(text:'The healroot vines dissipate from ' + holder.name + '.'); 
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    windowEvent.queueMessage(text:'The healroot soothe\'s ' + holder.name + '.');
                    holder.heal(amount:holder.stats.HP * 0.05);
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:user.name + ' resumes a normal stance!');
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                    @:amount = damage.amount;
                    damage.amount = 0;
                    windowEvent.queueMessage(text:user.name + ' leaps in front of ' + holder.name + ', taking damage in their stead!');

                    user.damage(
                        from,
                        damage: Damage.new(
                            amount,
                            damageType : Damage.TYPE.NEUTRAL,
                            damageClass: Damage.CLASS.HP
                        ),dodgeable: false
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
                name : 'Perfect Guard',
                description: 'All damage is nullified.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + ' is strongly guarding themself');
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                    if (from != holder) ::<= {
                        windowEvent.queueMessage(text:holder.name + ' is protected from the damage!');
                        damage.amount = 0;                        
                    }
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                    if (turnIndex >= turnCount)
                        windowEvent.queueMessage(text:holder.name + ' realizes ' + user.name + "'s argument was complete junk!")
                    else                    
                        windowEvent.queueMessage(text:holder.name + ' thinks about ' + user.name + "'s argument!");
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                    if (turnIndex >= turnCount)
                        windowEvent.queueMessage(text:holder.name + ' broke free from the grapple!')
                    else                    
                        windowEvent.queueMessage(text:holder.name + ' is being grappled and is unable to move!');
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),   

        Effect.new(
            data : {
                name : 'Ensnared',
                description: 'Unable to act.',
                battleOnly : true,
                skipTurn : true,
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                    if (turnIndex >= turnCount)
                        windowEvent.queueMessage(text:holder.name + ' broke free from the snare!')
                    else                    
                        windowEvent.queueMessage(text:holder.name + ' is ensnared and is unable to move!');
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                    windowEvent.queueMessage(text:holder.name + ' is in the middle of grappling and cannot move!');
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),
        
        Effect.new(
            data : {
                name : 'Ensnaring',
                description: 'Unable to act.',
                battleOnly : true,
                skipTurn : true,
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                    windowEvent.queueMessage(text:holder.name + ' is busy keeping someone ensared and cannot move!');
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(
                        text: holder.name + ' starts to run from the fight!'
                    );
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                    windowEvent.queueMessage(text: user.name + ' runs from the battle!');
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + ' was stunned!');
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + ' came to their senses!');
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                description: 'ATK +20%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(
                    ATK: 20
                ),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                description: 'DEF -20%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(
                    DEF: -20
                ),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                description: 'ATK -20%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(
                    ATK: -20
                ),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                description: 'DEF +20%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(
                    DEF: 20
                ),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(
                    
                ),
                onAffliction : ::(user, item, holder) {
                    @:world = import(module:'game_singleton.world.mt');

                    if (world.time > world.TIME.EVENING) ::<= {
                        windowEvent.queueMessage(text:'The moon shimmers... ' + holder.name +' softly glows');                    
                    }
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    @:world = import(module:'game_singleton.world.mt');

                    if (world.time > world.TIME.EVENING) ::<= {
                        stats.modRate(stats:StatSet.new(INT:40, DEF:40, ATK:40));
                    }                    
                }
            }
        ),

        Effect.new(
            data : {
                name : 'Coordinated',
                description: 'SPD,DEF,ATK +35%',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                    ATK:35,
                    DEF:35,
                    SPD:35
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name +' is ready to coordinate!');                    
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },

                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Proceed with Caution',
                description: 'DEF + 50%',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                    
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name +' braces for incoming damage!');                    
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + ' no longer braces for damage.');
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    stats.modRate(stats:StatSet.new(DEF:50));
                }
            }
        ),


        Effect.new(
            data : {
                name : 'Solar Affinity',
                description: 'INT,DEF,ATK +40% if day time.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(
                    
                ),
                onAffliction : ::(user, item, holder) {
                    @:world = import(module:'game_singleton.world.mt');

                    if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                        windowEvent.queueMessage(text:'The sun intensifies... ' + holder.name +' softly glows');                    
                    }
                },
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                
                onDamage : ::(user, item, holder, from, damage) {
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                    @:world = import(module:'game_singleton.world.mt');

                    if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                        stats.modRate(stats:StatSet.new(INT:40, DEF:40, ATK:40));
                    }                    
                }
            }
        ),

        
        Effect.new(
            data : {
                name : 'Non-combat Weapon',
                description: '20% chance to deflect attack then break weapon.',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                    if (Number.random() > 0.8 && damage.damageType == Damage.TYPE.PHYS) ::<= {
                        @:Entity = import(module:'game_class.entity.mt');
                    
                        windowEvent.queueMessage(text:holder.name + " parries the blow, but their non-combat weapon breaks in the process!");
                        damage.amount = 0;
                        @:item = holder.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L);
                        holder.unequip(slot:Entity.EQUIP_SLOTS.HAND_L, silent:true);
                        item.throwOut();                      
                    }
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {                
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),   
        
        Effect.new(
            data : {
                name : 'Flight',
                description: 'Dodges attacks.',
                battleOnly : true,
                skipTurn : false,
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                    if (from != holder) ::<= {
                        @:Entity = import(module:'game_class.entity.mt');                    
                        windowEvent.queueMessage(text:holder.name + " dodges the damage from Flight!");
                        damage.amount = 0;
                    }
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
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                
                onPostAttackOther : ::(user, item, holder, to) {
                    if (to.isIncapacitated()) ::<= {
                        windowEvent.queueMessage(text:holder.name + "'s ending blow to " + to.name + " increases "+ holder.name + "'s abilities due to their Assassin's Pride.");                        
                        user.addEffect(from:holder, name: 'Pride', durationTurns: 10);                        
                    }
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: true,
                stats: StatSet.new(
                    ATK:25,
                    SPD:25
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " is feeling prideful.");
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },
                
                onDamage : ::(user, item, holder, from, damage) {
                    if (user == from) ::<= {
                        windowEvent.queueMessage(text: user.name + '\'s duel challenge focuses damage!');
                        damage.amount *= 2.25;
                    }
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
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    if (Number.random() > 0.7) ::<={
                        windowEvent.queueMessage(
                            text: "The " + item.name + ' is used in its entirety.'
                        );
                        item.throwOut();                                    
                    } else ::<={
                        windowEvent.queueMessage(
                            text: "A bit of the " + item.name + ' is used.'
                        );                    
                    }
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: true,
                stats: StatSet.new(
                    ATK: -20,
                    DEF: -20,
                    SPD: -20
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " started to bleed out!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " is no longer bleeding out.");
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    windowEvent.queueMessage(text:holder.name + " suffered from bleeding!");
                    
                    holder.damage(
                        from: holder,
                        damage: Damage.new(
                            amount:holder.stats.HP*0.05,
                            damageType : Damage.TYPE.NEUTRAL,
                            damageClass: Damage.CLASS.HP
                        ),dodgeable: false
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
                stackable: true,
                stats: StatSet.new(
                    
                ),
                onAffliction : ::(user, item, holder) {

                    @:learned = holder.profession.gainSP(amount:1);
                    foreach(learned)::(index, ability) {
                        holder.learnAbility(name:ability);
                        windowEvent.queueMessage(text: holder.name + ' learned the ability: ' + ability);                        
                    }
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Explode',
                description: 'Damage to holder.',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:"The " + item.name + " explodes on " + user.name + "!");
                    
                    holder.damage(
                        from: holder,
                        damage: Damage.new(
                            amount:random.integer(from:10, to:20),
                            damageType : Damage.TYPE.FIRE,
                            damageClass: Damage.CLASS.HP                                                       
                        ),dodgeable: false 
                    );
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Poison Rune',
                description: 'Damage every turn to holder.',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'Glowing purple runes were imprinted on ' + holder.name + "!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'The poison rune fades from ' + holder.name + '.');
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    windowEvent.queueMessage(text:holder.name + " was hurt by the poison rune!");
                    
                    holder.damage(
                        from: holder,
                        damage: Damage.new(
                            amount:random.integer(from:1, to:3),
                            damageType : Damage.TYPE.POISON,
                            damageClass: Damage.CLASS.HP
                        ),dodgeable: false 
                    );
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),

        Effect.new(
            data : {
                name : 'Destruction Rune',
                description: 'Causes INT-based damage when rune is released.',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'Glowing orange runes were imprinted on ' + holder.name + "!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'The destruction rune fades from ' + holder.name + '.');
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Regeneration Rune',
                description: 'Heals holder every turn.',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'Glowing cyan runes were imprinted on ' + holder.name + "!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'The regeneration rune fades from ' + holder.name + '.');
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    windowEvent.queueMessage(text:holder.name + " was healed by the regeneration rune.");
                    holder.heal(amount:holder.stats.HP * 0.03);
                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),        
        Effect.new(
            data : {
                name : 'Shield Rune',
                description: '+100% DEF while active.',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(
                    DEF: 100
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'Glowing deep-blue runes were imprinted on ' + holder.name + "!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'The shield rune fades from ' + holder.name + '.');
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Cure Rune',
                description: 'Cures the holder when the rune is released.',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'Glowing green runes were imprinted on ' + holder.name + "!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:'The cure rune fades from ' + holder.name + '.');
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " was poisoned!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " is no longer poisoned.");
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    windowEvent.queueMessage(text:holder.name + " was hurt by the poison!");
                    
                    holder.damage(
                        from: holder,
                        damage: Damage.new(
                            amount:holder.stats.HP*0.05,
                            damageType : Damage.TYPE.NEUTRAL,
                            damageClass: Damage.CLASS.HP
                        ),dodgeable: false 
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " was blinded!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " is no longer blind.");
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                    when (Number.random() > 0.5) empty;
                    windowEvent.queueMessage(text:holder.name + " missed in their blindness!");
                    damage.amount = 0;
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " was burned!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " is no longer burned.");
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {
                    when(Number.random() > 0.5) empty;
                    windowEvent.queueMessage(text:holder.name + " was hurt by burns!");
                    holder.damage(
                        from:holder,
                        damage : Damage.new(
                            amount: user.stats.HP / 16,
                            damageClass: Damage.CLASS.HP,
                            damageType: Damage.TYPE.NEUTRAL                                                   
                        ),dodgeable: false 
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
                stackable: false,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " was frozen");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " is no longer frozen.");
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(
                    SPD: -100,
                    ATK: -100
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " was paralyzed");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " is no longer paralyzed.");
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                stackable: false,
                stats: StatSet.new(
                    DEF: -50
                ),
                onAffliction : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " was petrified!");
                
                },
                
                onRemoveEffect : ::(user, item, holder) {
                    windowEvent.queueMessage(text:holder.name + " is no longer petrified!");
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
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
                name : 'Elemental Tag',
                description: 'Weakness to Fire, Ice, and Thunder damage by 100%',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    if (damage.damageType == Damage.TYPE.FIRE) ::<= {
                        damage.amount *= 2;
                    }
                    if (damage.damageType == Damage.TYPE.ICE) ::<= {
                        damage.amount *= 2;
                    }
                    if (damage.damageType == Damage.TYPE.THUNDER) ::<= {
                        damage.amount *= 2;
                    }
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),


        Effect.new(
            data : {
                name : 'Elemental Shield',
                description: 'Nullify ',
                battleOnly : true,
                skipTurn : false,
                stats: StatSet.new(),
                stackable: false,
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    @:effects = holder.effects;
                    
                    @fire    = effects->filter(by:::(value) <- value.name == 'Burning')->keycount != 0;
                    @ice     = effects->filter(by:::(value) <- value.name == 'Icy')->keycount != 0;
                    @thunder = effects->filter(by:::(value) <- value.name == 'Shock')->keycount != 0;
                    
                    if (fire && holder.damage.damageType == Damage.TYPE.FIRE) ::<= {
                        damage.amount *= 0;
                    }
                    if (ice && damage.damageType == Damage.TYPE.ICE) ::<= {
                        damage.amount *= 0;
                    }
                    if (thunder && damage.damageType == Damage.TYPE.THUNDER) ::<= {
                        damage.amount *= 0;
                    }
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),

        
        Effect.new(
            data : {
                name : 'Burning',
                description: 'Gives fire damage and gives 50% ice resist',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                    to.damage(from:to, damage: Damage.new(
                        amount: random.integer(from:1, to:4),
                        damageType: Damage.TYPE.FIRE,
                        damageClass: Damage.CLASS.HP
                    ),dodgeable: false);
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    if (damage.damageType == Damage.TYPE.ICE) ::<= {
                        damage.amount *= 0.5;
                    }
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),         

        Effect.new(
            data : {
                name : 'Icy',
                description: 'Gives ice damage and gives 50% fire resist',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                    to.damage(from:to, damage: Damage.new(
                        amount: random.integer(from:1, to:4),
                        damageType: Damage.TYPE.ICE,
                        damageClass: Damage.CLASS.HP
                    ),dodgeable: false);
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    if (damage.damageType == Damage.TYPE.FIRE) ::<= {
                        damage.amount *= 0.5;
                    }
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),

        Effect.new(
            data : {
                name : 'Shock',
                description: 'Gives thunder damage and gives 50% thunder resist',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                    to.damage(from:to, damage: Damage.new(
                        amount: random.integer(from:1, to:4),
                        damageType: Damage.TYPE.THUNDER,
                        damageClass: Damage.CLASS.HP
                    ),dodgeable: false);
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    if (damage.damageType == Damage.TYPE.THUNDER) ::<= {
                        damage.amount *= 0.5;
                    }
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),

        Effect.new(
            data : {
                name : 'Toxic',
                description: 'Gives poison damage and gives 50% poison resist',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                    to.damage(from:to, damage: Damage.new(
                        amount: random.integer(from:1, to:4),
                        damageType: Damage.TYPE.POISON,
                        damageClass: Damage.CLASS.HP
                    ),
                    dodgeable: false
                    );
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    if (damage.damageType == Damage.TYPE.POISON) ::<= {
                        damage.amount *= 0.5;
                    }
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),

        Effect.new(
            data : {
                name : 'Shimmering',
                description: 'Gives light damage and gives 50% dark resist',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                    to.damage(from:to, damage: Damage.new(
                        amount: random.integer(from:1, to:4),
                        damageType: Damage.TYPE.LIGHT,
                        damageClass: Damage.CLASS.HP
                    ),dodgeable: false);
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    if (damage.damageType == Damage.TYPE.DARK) ::<= {
                        damage.amount *= 0.5;
                    }
                },
                
                onNextTurn : ::(user, item, holder, turnIndex, turnCount) {

                },
                onStatRecalculate : ::(user, item, holder, stats) {
                
                }
            }
        ),        
        Effect.new(
            data : {
                name : 'Dark',
                description: 'Gives dark damage and gives 50% light resist',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                stats: StatSet.new(),
                onAffliction : ::(user, item, holder) {
                },
                
                onRemoveEffect : ::(user, item, holder) {
                },                
                onPostAttackOther : ::(user, item, holder, to) {
                    to.damage(from:to, damage: Damage.new(
                        amount: random.integer(from:1, to:4),
                        damageType: Damage.TYPE.DARK,
                        damageClass: Damage.CLASS.HP
                    ),dodgeable: false);
                },

                onPreAttackOther : ::(user, item, holder, to, damage) {
                },
                onAttacked : ::(user, item, holder, by, damage) {
                
                },

                onDamage : ::(user, item, holder, from, damage) {
                    if (damage.damageType == Damage.TYPE.LIGHT) ::<= {
                        damage.amount *= 0.5;
                    }
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
