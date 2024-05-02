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



@:FLAGS = {
    AILMENT : 1
};


    ////////////////////// SPECIAL EFFECTS
@:reset :: {

@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Scene = import(module:'game_database.scene.mt');
@:random = import(module:'game_singleton.random.mt');
@:g = import(module:'game_function.g.mt');


    
    
    
    //////////////////////



Effect.newEntry(
    data : {
        name : 'Defend',
        id: 'base:defend',
        description: 'Reduces damage by 40%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 1,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
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

        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            windowEvent.queueMessage(text:holder.name + "'s defending stance reduces damage!");
            damage.amount *= 0.6;
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Brace',
        id: 'base:brace',
        description: 'Increased defense and grants an additional block point.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 1,
        flags : 0,
        stats: StatSet.new(
            DEF: 50
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' braces for damage!'
            );
        },

        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {

        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Agile',
        id: 'base:agile',
        description: 'The holder may now dodge attacks. If the holder has more DEX than the attacker, the chance of dodging increases if the holder\'s DEX is greater than the attacker\'s.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 1,
        flags : 0,
        stats: StatSet.new(
            DEX: 20
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' is now able to dodge attacks!'
            );
        },

        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {

        },

        onAttacked ::(user, item, holder, by, damage) {
            @:StateFlags = import(module:'game_class.stateflags.mt');
            @whiff = false;
            @:hitrate::(this, attacker) {
                //if (dexPenalty != empty)
                //    attacker *= dexPenalty;
                    
                when (attacker <= 1) 0.45;
                @:diff = attacker/this; 
                when(diff > 1) 1.0; 
                return 1 - 0.45 * ((1-diff)**0.9);
            }
            if (Number.random() > hitrate(
                this:     holder.stats.DEX,
                attacker: by.stats.DEX
            ))
                whiff = true;
            
            
            when(whiff) ::<= {
                windowEvent.queueMessage(text:random.pickArrayItem(list:[
                    holder.name + ' lithely dodges ' + by.name + '\'s attack!',                 
                    holder.name + ' narrowly dodges ' + by.name + '\'s attack!',                 
                    holder.name + ' dances around ' + by.name + '\'s attack!',                 
                    by.name + '\'s attack completely misses ' + holder.name + '!'
                ]));
                holder.flags.add(flag:StateFlags.DODGED_ATTACK);
                damage.amount = 0;
            }        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {

        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Guard',
        id : 'base:guard',
        description: 'Reduces damage by 90%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 1,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' takes a guarding stance!'
            );
        
        },

        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            windowEvent.queueMessage(text:holder.name + "'s defending stance reduces damage significantly!");
            damage.amount *= 0.1;
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Apparition',
        id : 'base:apparition',
        description: 'Ghostly apparition makes it particularly hard to hit.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {

        },

        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
            if (!holder.isIncapacitated() && random.try(percentSuccess:40)) ::<= {
                windowEvent.queueMessage(text:holder.name + "'s ghostly body bends around the attack!");
                damage.amount = 0;
            }        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {

        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)



Effect.newEntry(
    data : {
        name : 'The Beast',
        id : 'base:the-beast',
        description: 'The ferocity of this creature makes it particularly hard to hit.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {

        },

        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (!holder.isIncapacitated() && random.try(percentSuccess:35)) ::<= {
                windowEvent.queueMessage(text:holder.name + " ferociously repels the attack!");
                damage.amount = 0;
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Seasoned Adventurer',
        id : 'base:seasoned-adventurer',
        description: 'Is considerably harder to hit, as they are an experienced fighter.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {

        },

        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (!holder.isIncapacitated() && random.try(percentSuccess:60)) ::<= {
                windowEvent.queueMessage(text:
                    random.pickArrayItem(list: [
                        holder.name + " predicts and avoids the attack!",
                        holder.name + " easily avoids the attack!",
                        holder.name + " seems to have no trouble avoiding the attack!",
                    ])
                );
                damage.amount = 0;
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Defensive Stance',
        id : 'base:defensive-stance',
        description: 'ATK -50%, DEF +200%, additional block point.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 1,
        flags : 0,
        stats: StatSet.new(ATK:-50, DEF:200),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' changes their stance to be defensive!'
            );
        },

        onRemoveEffect ::(user, item, holder) {
        
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },


        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)        


Effect.newEntry(
    data : {
        name : 'Offsensive Stance',
        id : 'base:offensive-stance',
        description: 'DEF -50%, ATK +200%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(DEF:-50, ATK:200),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' changes their stance to be offensive!'
            );
        },

        onRemoveEffect ::(user, item, holder) {
        
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },


        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
) 

Effect.newEntry(
    data : {
        name : 'Light Stance',
        id : 'base:light-stance',        
        description: 'ATK -50%, SPD +100%, DEX +100%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(ATK:-50, SPD:100, DEX:100),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' changes their stance to be light on their feet!'
            );
        },

        onRemoveEffect ::(user, item, holder) {
        
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },


        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
) 

Effect.newEntry(
    data : {
        name : 'Heavy Stance',
        id : 'base:heavy-stance',
        description: 'SPD -50%, DEF +200%, additional block point.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 1,
        flags : 0,
        stats: StatSet.new(SPD:-50, DEF:200),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' changes their stance to be heavy and sturdy!'
            );
        },

        onRemoveEffect ::(user, item, holder) {
        
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },


        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)         


Effect.newEntry(
    data : {
        name : 'Meditative Stance',
        id : 'base:meditative-stance',
        description: 'SPD -50%, INT +200%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(SPD:-50, INT:200),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' changes their stance for mental focus!'
            );
        },

        onRemoveEffect ::(user, item, holder) {
        
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },


        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)         


Effect.newEntry(
    data : {
        name : 'Striking Stance',
        id : 'base:striking-stance',
        description: 'SPD -30%, DEF -30%, ATK +200%, DEX +100%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(SPD:-30, DEF:-30, ATK:200, DEX:100),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' changes their stance for maximum attack!'
            );
        },

        onRemoveEffect ::(user, item, holder) {
        
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },


        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
) 

Effect.newEntry(
    data : {
        name : 'Reflective Stance',
        id : 'base:reflective-stance',
        description: 'Attack retaliation',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        stats: StatSet.new(),
        blockPoints : 0,
        flags : 0,
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' changes their stance to reflect attacks!'
            );
        },

        onRemoveEffect ::(user, item, holder) {
        
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },


        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
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
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)                 

Effect.newEntry(
    data : {
        name : 'Counter',
        id : 'base:counter',
        description: 'Dodges attacks and retaliates.',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' is prepared for an attack!'
            );
        },

        onRemoveEffect ::(user, item, holder) {
        
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },


        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
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
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Evasive Stance',
        id : 'base:evasive-stance',
        description: '%50 chance damage nullify when from others.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: holder.name + ' changes their stance to evade attacks!'
            );
        },

        onRemoveEffect ::(user, item, holder) {
        
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },


        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            when (holder == from) empty;
            when(Number.random() > 5) empty;

            windowEvent.queueMessage(
                text: holder.name + ' evades!'
            );

            damage.amount = 0;
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
            
        }
    }
)               

Effect.newEntry(
    data : {
        name : 'Sneaked',
        id : 'base:sneaked',
        description: 'Guarantees next damage from user is x3',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:user.name + " snuck behind " + holder.name + '!');
        
        },

        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            breakpoint();
            if (from == user) ::<= {
                windowEvent.queueMessage(text:user.name + "'s sneaking takes " + holder.name + ' by surprise!');
                damage.amount *= 3;
            }
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Mind Focused',
        id : 'base:mind-focused',
        description: 'INT +100%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            INT: 100
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + ' focuses their mind');
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s focus returns to normal.');
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)        


Effect.newEntry(
    data : {
        name : 'Protect',
        id : 'base:protect',
        description: 'DEF +100%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: 100
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + ' is covered in a shell of light!');
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s shell of light fades away.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Shield',
        id : 'base:shield',
        description: 'DEF +10%, 30% chance to block',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: 10
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:'A shield of light appears before ' + holder.name + '!');
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s shield of light fades away.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
            if (Number.random() < 0.3) ::<= {
                windowEvent.queueMessage(text:holder.name + '\'s shield of light blocks the attack!');
                damage.amount = 0;
            }                
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Trigger Protect',
        id : 'base:trigger-protect',
        description: 'Casts Protect',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
            windowEvent.queueMessage(text:'It casts Protect on ' + holder.name + '!');
            holder.addEffect(
                from:user, id: 'base:protect', durationTurns: 3
            );                        
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 

Effect.newEntry(
    data : {
        name : 'Trigger Evade',
        id : 'base:trigger-evade',
        description: 'Allows the user to evade all attacks for the next turn.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
            holder.addEffect(
                from:user, id: 'base:evade', durationTurns: 1
            );                        
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 

Effect.newEntry(
    data : {
        name : 'Evade',
        id : 'base:evade',
        description: 'Allows the user to evade all attacks.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + ' is covered in a mysterious wind!');
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
            windowEvent.queueMessage(text:holder.name + '\'s mysterious wind caused the attack to miss!');
            damage.amount = 0;
        },
        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 


Effect.newEntry(
    data : {
        name : 'Trigger Regen',
        id : 'base:trigger-regen',
        description: 'Slightly heals wounds.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            when(holder.hp == 0) empty;
            windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
            holder.heal(
                amount: holder.stats.HP * 0.05
            );                        
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 

Effect.newEntry(
    data : {
        name : 'Trigger Hurt Chance',
        id : 'base:trigger-hurt-chance',
        description: '10% chance to hurt for 1HP.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            if (random.try(percentSuccess:10)) ::<= {
                windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                holder.damage(
                    from:holder,
                    damage: Damage.new(
                        amount: 1,
                        damageType: Damage.TYPE.NEUTRAL,
                        damageClass: Damage.CLASS.HP
                    ),
                    dodgeable: false
                );                        
            }
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 

Effect.newEntry(
    data : {
        name : 'Trigger Fatigue Chance',
        id : 'base:trigger-fatigue-chance',
        description: '10% chance to hurt for 1AP.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            if (random.try(percentSuccess:10)) ::<= {
                windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                holder.damage(
                    from:holder,
                    damage: Damage.new(
                        amount: 1,
                        damageType: Damage.TYPE.NEUTRAL,
                        damageClass: Damage.CLASS.AP
                    ),
                    dodgeable: false
                );                        
            }
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 

Effect.newEntry(
    data : {
        name : 'Trigger Break Chance',
        id : 'base:trigger-break-chance',
        description: '5% chance to break item.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            if (random.try(percentSuccess:5)) ::<= {
                windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
                holder.unequipItem(item, silent: true);
                windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' disintegrates.');                
            }
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 

Effect.newEntry(
    data : {
        name : 'Trigger Spikes',
        id : 'base:trigger-spikes',
        description: 'Casts Spikes',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
            windowEvent.queueMessage(text:'It covers ' + holder.name + ' in spikes of light!');
            holder.addEffect(
                from:user, id: 'base:spikes', durationTurns: 3
            );                        
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 

Effect.newEntry(
    data : {
        name : 'Spikes',
        id : 'base:spikes',
        description: 'DEF +10%, light damage when attacked.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: 10
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + ' is covered in spikes of light.');
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
            windowEvent.queueMessage(text:by.name + ' gets hurt by ' + holder.name + '\'s spikes of light!');
            by.damage(from:holder, damage:Damage.new(
                amount:random.integer(from:1, to:4),
                damageType:Damage.TYPE.LIGHT,
                damageClass:Damage.CLASS.HP
            ),dodgeable: false);
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s spikes of light fade.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 



Effect.newEntry(
    data : {
        name : 'Trigger AP Regen',
        id : 'base:trigger-ap-regen',
        description: 'Slightly recovers AP.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
            holder.healAP(
                amount: holder.stats.AP * 0.05
            );                        
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 

Effect.newEntry(
    data : {
        name : 'Trigger Shield',
        id : 'base:trigger-shield',
        description: 'Casts Shield',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
            windowEvent.queueMessage(text:'It casts Shield on ' + holder.name + '!');
            holder.addEffect(
                from:user, id: 'base:shield', durationTurns: 3
            );                        
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)         


Effect.newEntry(
    data : {
        name : 'Trigger Strength Boost',
        id : 'base:trigger-strength-boost',
        description: 'Triggers a boost in strength.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
            holder.addEffect(
                from:user, id: 'base:strength-boost', durationTurns: 3
            );                        
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)   

Effect.newEntry(
    data : {
        name : 'Strength Boost',
        id : 'base:strength-boost',
        description: 'ATK +70%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            ATK:70
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s power is increased!');
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s power boost fades!');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Trigger Defense Boost',
        id : 'base:trigger-defense-boost',
        description: 'Triggers a boost in defense.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
            holder.addEffect(
                from:user, id: 'base:defense-boost', durationTurns: 3
            );                        
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)   

Effect.newEntry(
    data : {
        name : 'Defense Boost',
        id : 'base:defense-boost',
        description: 'DEF +70%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF:70
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s defense is increased!');
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s defense boost fades!');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Trigger Mind Boost',
        id : 'base:trigger-mind-boost',
        description: 'Triggers a boost in mental acuity.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
            holder.addEffect(
                from:user, id: 'base:mind-boost', durationTurns: 3
            );                        
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)   

Effect.newEntry(
    data : {
        name : 'Mind Boost',
        id : 'base:mind-boost',
        description: 'INT +70%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            INT:70
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s mental acuity is increased!');
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s intelligence boost fades!');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Trigger Dex Boost',
        id : 'base:trigger-dex-boost',
        description: 'Triggers a boost in dexterity.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
            holder.addEffect(
                from:user, id: 'base:dex-boost', durationTurns: 3
            );                        
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)   

Effect.newEntry(
    data : {
        name : 'Dex Boost',
        id : 'base:dex-boost',
        description: 'DEX +70%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEX:70
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s dexterity is increased!');
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s dexterity boost fades!');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Trigger Speed Boost',
        id : 'base:trigger-speed-boost',
        description: 'Triggers a boost in speed.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
            holder.addEffect(
                from:user, id: 'base:speed-boost', durationTurns: 3
            );                        
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)   

Effect.newEntry(
    data : {
        name : 'Speed Boost',
        id : 'base:speed-boost',
        description: 'SPD +70%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            SPD:70
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s speed is increased!');
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s speed boost fades!');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  




Effect.newEntry(
    data : {
        name : 'Night Veil',
        id : 'base:night-veil',
        description: 'DEF +40%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: 50
        ),
        onAffliction ::(user, item, holder) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s Night Veil fades away.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Dayshroud',
        id : 'base:dayshroud',
        description: 'DEF +40%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: 50
        ),
        onAffliction ::(user, item, holder) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s Dayshroud fades away.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Call of the Night',
        id : 'base:call-of-the-night',
        description: 'ATK +40%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            ATK: 40
        ),
        onAffliction ::(user, item, holder) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s Call of the Night fades away.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  


Effect.newEntry(
    data : {
        name : 'Lunacy',
        id : 'base:lunacy',
        description: 'Skips turn and, instead, attacks a random enemy. ATK,DEF +70%.',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: 70,
            ATK: 70
        ),
        onAffliction ::(user, item, holder) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s Lunacy fades away.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            windowEvent.queueMessage(text:holder.name + ' attacks in a blind rage!');
            holder.attack(
                target:random.pickArrayItem(list:holder.enemies),
                amount:holder.stats.ATK * (0.5),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
            );                   
        

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Greater Call of the Night',
        id : 'base:greater-call-of-the-night',
        description: 'ATK +100%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            ATK: 100
        ),
        onAffliction ::(user, item, holder) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s Call of the Night fades away.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Greater Night Veil',
        id : 'base:greater-night-veil',
        description: 'DEF +100%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: 100
        ),
        onAffliction ::(user, item, holder) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s Night Veil fades away.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  


Effect.newEntry(
    data : {
        name : 'Greater Dayshroud',
        id : 'base:greater-dayshroud',
        description: 'DEF +100%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: 100
        ),
        onAffliction ::(user, item, holder) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s Dayshroud fades away.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Moonsong',
        id : 'base:moonsong',
        description: 'Heals 5% HP every turn',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s Moonsong fades.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            when(holder.hp == 0) empty;
            holder.heal(amount:holder.stats.HP * 0.05);
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Sol Attunement',
        id : 'base:sol-attunement',
        description: 'Heals 5% HP every turn',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s Sol Attunement fades.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            when(holder.hp == 0) empty;
            holder.heal(amount:holder.stats.HP * 0.05);
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)          

Effect.newEntry(
    data : {
        name : 'Greater Moonsong',
        id : 'base:greater-moonsong',
        description: 'Heals 15% HP every turn',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s Moonsong fades.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            when(holder.hp == 0) empty;
            holder.heal(amount:holder.stats.HP * 0.15);
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)       

Effect.newEntry(
    data : {
        name : 'Greater Sol Attunement',
        id : 'base:greater-sol-attunement',
        description: 'Heals 15% HP every turn',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s Sol Attunement fades.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            when(holder.hp == 0) empty;
            holder.heal(amount:holder.stats.HP * 0.15);
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)          
   
Effect.newEntry(
    data : {
        name : 'Grace',
        id : 'base:grace',
        description: 'If hurt while HP is 0, the damage is nullified and this effect disappears.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:'A halo appears above ' + holder.name + '!');
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + '\'s halo disappears.');
        },                

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (holder.hp == 0) ::<= {
                damage.amount = 0;
                windowEvent.queueMessage(text:holder.name + ' is protected from death!');
                holder.removeEffects(
                    effectBases : [
                        Effect.find(id:'base:grace')
                    ]
                );
            }
               
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)     
   

Effect.newEntry(
    data : {
        name : 'Consume Item',
        id : 'base:consume-item',
        description: 'The item is destroyed in the process of its effects',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: "The " + item.name + ' is consumed.'
            );
            item.throwOut();                
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Break Item',
        id : 'base:break-item',
        description: 'The item is destroyed in the process of misuse or strain',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            if (Number.random() > 0.5) ::<= {
                windowEvent.queueMessage(
                    text: "The " + item.name + ' broke.'
                );
                item.throwOut();                
            }
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)        

Effect.newEntry(
    data : {
        name : 'Fling',
        id : 'base:fling',
        description: 'The item is violently lunged at a target, likely causing damage. The target may catch the item.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: user.name + ' flung the ' + item.name + ' at ' + holder.name + '!'
            );
            
            windowEvent.queueCustom(
                onEnter::{
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
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)    

  

Effect.newEntry(
    data : {
        name : 'HP Recovery: All',
        id : 'base:hp-recovery-all',
        description: 'Heals 100% of HP.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            holder.heal(amount:holder.stats.HP);
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'AP Recovery: All',
        id : 'base:ap-recovery-all',
        description: 'Heals 100% of AP.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            holder.healAP(amount:holder.stats.AP);
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Treasure I',
        id : 'base:treasure-1',
        description: 'Opening gives a fair number of G.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            @:world = import(module:'game_singleton.world.mt');
            @:amount = (50 + Number.random()*400)->floor;                    
            windowEvent.queueMessage(text:'The party found ' + g(g:amount) + '.');
            world.party.addGoldAnimated(
                amount:amount,
                onDone::{}
            );
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)        

Effect.newEntry(
    data : {
        name : 'Field Cook',
        id : 'base:field-cook',
        description: 'Chance to cook a meal after battle.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
            @:world = import(module:'game_singleton.world.mt');
            
            
            when(Number.random() > 0.7) empty;
            when(user.isIncapacitated()) empty;
            when(!world.party.isMember(entity:holder)) empty;


            windowEvent.queueMessage(
                text: '' + holder.name + ' found some food and cooked a meal for the party.'
            );
            foreach(world.party.members)::(index, member) {
                member.heal(amount:member.stats.HP * 0.1);
                member.healAP(amount:member.stats.AP * 0.1);
            }
            
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Penny Picker',
        id : 'base:penny-picker',
        description: 'Looks on the ground for G after battle.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
            @:world = import(module:'game_singleton.world.mt');
            
            
            when(Number.random() > 0.7) empty;
            when(user.isIncapacitated()) empty;
            when(!world.party.isMember(entity:holder)) empty;


            @:amt = (Number.random() * 20)->ceil;
            windowEvent.queueMessage(
                text: '' + holder.name + ' happened to notice an additional ' + g(g:amt) + ' dropped on the ground.'
            );
            world.party.inventory.addGold(amount:amt);
            
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Alchemist\'s Scavenging',
        id : 'base:alchemists-scavenging',
        description: 'Scavenges for alchemist ingredients.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
            @:world = import(module:'game_singleton.world.mt');
            @:Item  = import(module:'game_mutator.item.mt');
            
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
                world.party.inventory.add(item:Item.new(base:Item.database.find(id:'base:ingredient')));
            }
            
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Trained Hand',
        id : 'base:trained-hand',
        description: 'ATK +30%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(ATK:30),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(
                text: user.name + ' readies their trained hands!'
            );
        },
        
        onRemoveEffect ::(user, item, holder) {                    
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)



Effect.newEntry(
    data : {
        name : 'Focus Perception',
        id : 'base:focus-perception',
        description: 'ATK +30%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(ATK:30),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {                    
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)   

Effect.newEntry(
    data : {
        name : 'Cheered',
        id : 'base:cheered',
        description: 'ATK +70%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(ATK:70),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {                    
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)           

Effect.newEntry(
    data : {
        name : 'Poisonroot Growing',
        id : 'base:poisonroot-growing',
        description: 'Vines grow on target. SPD -10%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,                
        stats: StatSet.new(SPD:-10),
        blockPoints : 0,
        flags : FLAGS.AILMENT,
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {                    
            holder.addEffect(from:holder, id:'base:poisonroot', durationTurns:30);                            
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            windowEvent.queueMessage(text: 'The poisonroot continues to grow on ' + holder.name);        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Poisonroot',
        id : 'base:poisonroot',
        description: 'Every turn takes poison damage. SPD -10%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        stats: StatSet.new(SPD:-10),
        blockPoints : 0,
        flags : FLAGS.AILMENT,
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {     
            windowEvent.queueMessage(text:'The poisonroot vines dissipate from ' + holder.name + '.'); 
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            windowEvent.queueMessage(text:user.name + ' is strangled by the poisonroot!');                    
            holder.damage(from:user, damage: Damage.new(
                amount: random.integer(from:1, to:4),
                damageType: Damage.TYPE.POISON,
                damageClass: Damage.CLASS.HP
            ),dodgeable: false);                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Triproot Growing',
        id : 'base:triproot-growing',
        description: 'Vines grow on target. SPD -10%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(SPD:-10),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {                    
            holder.addEffect(from:holder, id:'base:triproot', durationTurns:30);                            
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            windowEvent.queueMessage(text: 'The triproot continues to grow on ' + holder.name);        
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Triproot',
        id : 'base:triproot',
        description: 'Every turn 40% chance to trip. SPD -10%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(SPD:-10),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {                    
            windowEvent.queueMessage(text:'The triproot vines dissipate from ' + holder.name + '.'); 
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            if (Number.random() < 0.4) ::<= {
                windowEvent.queueMessage(text:'The triproot trips ' + holder.name + '!');
                holder.addEffect(from:holder, id:'base:stunned', durationTurns:1);                                                
            }
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Healroot Growing',
        id : 'base:healroot-growing',
        description: 'Vines grow on target. SPD -10%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(SPD:-10),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {                    
            holder.addEffect(from:holder, id:'base:healroot', durationTurns:30);                            
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            windowEvent.queueMessage(text: 'The healroot continues to grow on ' + holder.name);        
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Healroot',
        id : 'base:healroot',
        description: 'Every turn heal 5% HP. SPD -10%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(SPD:-10),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {                    
            windowEvent.queueMessage(text:'The healroot vines dissipate from ' + holder.name + '.'); 
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            when(holder.hp == 0) empty;
            windowEvent.queueMessage(text:'The healroot soothe\'s ' + holder.name + '.');
            holder.heal(amount:holder.stats.HP * 0.05);
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

     

Effect.newEntry(
    data : {
        name : 'Defend Other',
        id : 'base:defend-other',
        description: 'Takes hits for another.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: 100
        ),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:user.name + ' resumes a normal stance!');
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            @:amount = damage.amount;

            when(user == holder) ::<= {
                windowEvent.queueMessage(text:user.name + ' braces for damage!');            
            }

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
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Perfect Guard',
        id : 'base:perfect-guard',
        description: 'All damage is nullified.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + ' is strongly guarding themself');
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (from != holder) ::<= {
                windowEvent.queueMessage(text:holder.name + ' is protected from the damage!');
                damage.amount = 0;                        
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Convinced',
        id : 'base:convinced',
        description: 'Unable to act.',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        stats: StatSet.new(),
        blockPoints : 0,
        flags : 0,
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
            if (turnIndex >= turnCount)
                windowEvent.queueMessage(text:holder.name + ' realizes ' + user.name + "'s argument was complete junk!")
            else                    
                windowEvent.queueMessage(text:holder.name + ' thinks about ' + user.name + "'s argument!");
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Grappled',
        id : 'base:grappled',
        description: 'Unable to act.',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : -3,
        stats: StatSet.new(),
        flags : 0,
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
            if (turnIndex >= turnCount)
                windowEvent.queueMessage(text:holder.name + ' broke free from the grapple!')
            else                    
                windowEvent.queueMessage(text:holder.name + ' is being grappled and is unable to move!');
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)   

Effect.newEntry(
    data : {
        name : 'Ensnared',
        id : 'base:ensnared',
        description: 'Unable to act.',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : -3,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
            if (turnIndex >= turnCount)
                windowEvent.queueMessage(text:holder.name + ' broke free from the snare!')
            else                    
                windowEvent.queueMessage(text:holder.name + ' is ensnared and is unable to move!');
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Grappling',
        id : 'base:grappling',
        description: 'Unable to act.',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : -3,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
            windowEvent.queueMessage(text:holder.name + ' is in the middle of grappling and cannot move!');
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Ensnaring',
        id : 'base:ensnaring',
        description: 'Unable to act.',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : -3,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
            windowEvent.queueMessage(text:holder.name + ' is busy keeping someone ensared and cannot move!');
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)                        

      

Effect.newEntry(
    data : {
        name : 'Bribed',
        id : 'base:bribed',
        description: 'Unable to act.',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },

        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)
Effect.newEntry(
    data : {
        name : 'Stunned',
        id : 'base:stunned',
        description: 'Unable to act.',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : -3,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + ' was stunned!');
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + ' came to their senses!');
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Sharpen',
        id : 'base:sharpen',
        description: 'ATK +20%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            ATK: 20
        ),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Weaken Armor',
        id : 'base:weaken-armor',
        description: 'DEF -20%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: -20
        ),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)        

Effect.newEntry(
    data : {
        name : 'Dull Weapon',
        id : 'base:dull-weapon',
        description: 'ATK -20%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            ATK: -20
        ),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Strengthen Armor',
        id : 'base:strengthen-armor',
        description: 'DEF +20%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: 20
        ),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  


Effect.newEntry(
    data : {
        name : 'Lunar Affinity',
        id : 'base:lunar-affinity',
        description: 'INT,DEF,ATK +40% if night time.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            
        ),
        onAffliction ::(user, item, holder) {
            @:world = import(module:'game_singleton.world.mt');

            if (world.time > world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(text:'The moon shimmers... ' + holder.name +' softly glows');                    
            }
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
            @:world = import(module:'game_singleton.world.mt');

            if (world.time > world.TIME.EVENING) ::<= {
                stats.modRate(stats:StatSet.new(INT:40, DEF:40, ATK:40));
            }                    
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Coordinated',
        id : 'base:coordinated',
        description: 'SPD,DEF,ATK +35%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            ATK:35,
            DEF:35,
            SPD:35
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name +' is ready to coordinate!');                    
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },

        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        }
    }
)
Effect.newEntry(
    data : {
        name : 'Proceed with Caution',
        id : 'base:proceed-with-caution',
        description: 'DEF + 50%',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name +' braces for incoming damage!');                    
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + ' no longer braces for damage.');
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
            stats.modRate(stats:StatSet.new(DEF:50));
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Solar Affinity',
        id : 'base:solar-affinity',
        description: 'INT,DEF,ATK +40% if day time.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            
        ),
        onAffliction ::(user, item, holder) {
            @:world = import(module:'game_singleton.world.mt');

            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(text:'The sun intensifies... ' + holder.name +' softly glows');                    
            }
        },
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
            @:world = import(module:'game_singleton.world.mt');

            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                stats.modRate(stats:StatSet.new(INT:40, DEF:40, ATK:40));
            }                    
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Non-combat Weapon',
        id : 'base:non-combat-weapon',
        description: '20% chance to deflect attack then break weapon.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (Number.random() > 0.8 && damage.damageType == Damage.TYPE.PHYS) ::<= {
                @:Entity = import(module:'game_class.entity.mt');
            
                windowEvent.queueMessage(text:holder.name + " parries the blow, but their non-combat weapon breaks in the process!");
                damage.amount = 0;
                @:item = holder.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR);
                holder.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
                item.throwOut();                      
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)   


Effect.newEntry(
    data : {
        name : 'Auto-Life',
        id : 'base:auto-life',
        description: '50% chance to fully revive if damaged while at 0 HP. This breaks the item.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
            breakpoint();
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (holder.hp == 0) ::<= {
                windowEvent.queueMessage(text:holder.name + " glows!");
                holder.unequipItem(item, silent:true);
                item.throwOut();                      


                if (random.try(percentSuccess:50)) ::<= {

                    @:Entity = import(module:'game_class.entity.mt');
                
                    damage.amount = 0;
                    holder.heal(amount:holder.stats.HP);

                    windowEvent.queueMessage(text:'The ' + item.name + " shatters after reviving " + holder.name + "!");
                } else ::<= {
                    windowEvent.queueMessage(text:'The ' + item.name + " failed to revive " + holder.name + "!");
                    
                }
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)   


Effect.newEntry(
    data : {
        name : 'Flight',
        id : 'base:flight',
        description: 'Dodges attacks.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (from != holder) ::<= {
                @:Entity = import(module:'game_class.entity.mt');                    
                windowEvent.queueMessage(text:holder.name + " dodges the damage from Flight!");
                damage.amount = 0;
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)        
   
Effect.newEntry(
    data : {
        name : 'Assassin\'s Pride',
        id : 'base:assassins-pride',
        description: 'SPD, ATK +25% for each slain.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        
        onPostAttackOther ::(user, item, holder, to) {
            if (to.isIncapacitated()) ::<= {
                windowEvent.queueMessage(text:holder.name + "'s ending blow to " + to.name + " increases "+ holder.name + "'s abilities due to their Assassin's Pride.");                        
                user.addEffect(from:holder, id: 'base:pride', durationTurns: 10);                        
            }
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },


        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)        
Effect.newEntry(
    data : {
        name : 'Pride',
        id : 'base:pride',
        description: 'SPD, ATK +25%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            ATK:25,
            SPD:25
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " is feeling prideful.");
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },


        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)        
  
Effect.newEntry(
    data : {
        name : 'Dueled',
        id : 'base:dueled',
        description: 'If attacked by user, 1.5x damage.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (user == from) ::<= {
                windowEvent.queueMessage(text: user.name + '\'s duel challenge focuses damage!');
                damage.amount *= 2.25;
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {                
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  
Effect.newEntry(
    data : {
        name : 'Consume Item Partially',
        id : 'base:consume-item-partially',
        description: 'The item has a chance of being used up',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
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
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)  

Effect.newEntry(
    data : {
        name : 'Bleeding',
        id : 'base:bleeding',
        description: 'Damage every turn to holder. ATK,DEF,SPD -20%.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(
            ATK: -20,
            DEF: -20,
            SPD: -20
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " started to bleed out!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " is no longer bleeding out.");
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
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
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)     

Effect.newEntry(
    data : {
        name : 'Explode',
        id : 'base:explode',
        description: 'Damage to holder.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
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
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)        
Effect.newEntry(
    data : {
        name : 'Poison Rune',
        id : 'base:poison-rune',
        description: 'Damage every turn to holder.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:'Glowing purple runes were imprinted on ' + holder.name + "!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:'The poison rune fades from ' + holder.name + '.');
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
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
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Destruction Rune',
        id : 'base:destruction-rune',
        description: 'Causes INT-based damage when rune is released.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:'Glowing orange runes were imprinted on ' + holder.name + "!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:'The destruction rune fades from ' + holder.name + '.');
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)
Effect.newEntry(
    data : {
        name : 'Regeneration Rune',
        id : 'base:regeneration-rune',
        description: 'Heals holder every turn.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:'Glowing cyan runes were imprinted on ' + holder.name + "!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:'The regeneration rune fades from ' + holder.name + '.');
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            when(holder.hp == 0) empty;
            windowEvent.queueMessage(text:holder.name + " was healed by the regeneration rune.");
            holder.heal(amount:holder.stats.HP * 0.03);
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)        
Effect.newEntry(
    data : {
        name : 'Shield Rune',
        id : 'base:shield-rune',
        description: '+100% DEF while active.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
            DEF: 100
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:'Glowing deep-blue runes were imprinted on ' + holder.name + "!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:'The shield rune fades from ' + holder.name + '.');
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)        


Effect.newEntry(
    data : {
        name : 'Cure Rune',
        id : 'base:cure-rune',
        description: 'Cures the holder when the rune is released.',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:'Glowing green runes were imprinted on ' + holder.name + "!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:'The cure rune fades from ' + holder.name + '.');
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 

//////////////////////////////
/// STATUS AILMENTS

Effect.newEntry(
    data : {
        name : 'Poisoned',
        id : 'base:poisoned',
        description: 'Damage every turn to holder.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " was poisoned!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " is no longer poisoned.");
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
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
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)     

Effect.newEntry(
    data : {
        name : 'Blind',
        id : 'base:blind',
        description: '50% chance to miss attacks.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " was blinded!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " is no longer blind.");
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
            when (Number.random() > 0.5) empty;
            windowEvent.queueMessage(text:holder.name + " missed in their blindness!");
            damage.amount = 0;
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)             
  

Effect.newEntry(
    data : {
        name : 'Burned',
        id : 'base:burned',
        description: '50% chance to get damage each turn.',
        battleOnly : true,
        skipTurn : false,
        stackable: false,
        blockPoints : 0,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " was burned!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " is no longer burned.");
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
            when(Number.random() > 0.5) empty;
            windowEvent.queueMessage(text:holder.name + " was hurt by burns!");
            holder.damage(
                from:holder,
                damage : Damage.new(
                    amount: holder.stats.HP / 16,
                    damageClass: Damage.CLASS.HP,
                    damageType: Damage.TYPE.NEUTRAL                                                   
                ),dodgeable: false 
            );
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 
Effect.newEntry(
    data : {
        name : 'Frozen',
        id : 'base:frozen',
        description: 'Unable to act.',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : -3,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " was frozen");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " is no longer frozen.");
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)         

Effect.newEntry(
    data : {
        name : 'Paralyzed',
        id : 'base:paralyzed',
        description: 'SPD,ATK -100%',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : -3,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(
            SPD: -100,
            ATK: -100
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " was paralyzed");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " is no longer paralyzed.");
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 


Effect.newEntry(
    data : {
        name : 'Mesmerized',
        id : 'base:mesmerized',
        description: 'SPD,DEF -100%',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : -3,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(
            SPD: -100,
            DEF: -100
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " was mesmerized!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " is no longer mesmerized.");
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 


Effect.newEntry(
    data : {
        name : 'Wrapped',
        id : 'base:wrapped',
        description: 'Can\'t move.',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : -3,
        flags : 0,
        stats: StatSet.new(
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " was wrapped and encoiled!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " is no longer wrapped.");
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 


Effect.newEntry(
    data : {
        name : 'Petrified',
        id : 'base:petrified',
        description: 'Unable to act. DEF -50%',
        battleOnly : true,
        skipTurn : true,
        stackable: false,
        blockPoints : -3,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(
            DEF: -50
        ),
        onAffliction ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " was petrified!");
        
        },
        
        onRemoveEffect ::(user, item, holder) {
            windowEvent.queueMessage(text:holder.name + " is no longer petrified!");
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {
        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Elemental Tag',
        id : 'base:elemental-tag',
        description: 'Weakness to Fire, Ice, and Thunder damage by 100%',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : FLAGS.AILMENT,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
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
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Elemental Shield',
        id : 'base:elemental-shield',
        description: 'Nullify ',
        battleOnly : true,
        skipTurn : false,
        stats: StatSet.new(),
        stackable: false,
        blockPoints : 0,
        flags : 0,
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
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
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)


Effect.newEntry(
    data : {
        name : 'Burning',
        id : 'base:burning',
        description: 'Gives fire damage and gives 50% ice resist',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
            to.damage(from:to, damage: Damage.new(
                amount: random.integer(from:1, to:4),
                damageType: Damage.TYPE.FIRE,
                damageClass: Damage.CLASS.HP
            ),dodgeable: false);
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (damage.damageType == Damage.TYPE.ICE) ::<= {
                damage.amount *= 0.5;
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)         

Effect.newEntry(
    data : {
        name : 'Icy',
        id : 'base:icy',
        description: 'Gives ice damage and gives 50% fire resist',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
            to.damage(from:to, damage: Damage.new(
                amount: random.integer(from:1, to:4),
                damageType: Damage.TYPE.ICE,
                damageClass: Damage.CLASS.HP
            ),dodgeable: false);
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (damage.damageType == Damage.TYPE.FIRE) ::<= {
                damage.amount *= 0.5;
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Shock',
        id : 'base:shock',
        description: 'Gives thunder damage and gives 50% thunder resist',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
            to.damage(from:to, damage: Damage.new(
                amount: random.integer(from:1, to:4),
                damageType: Damage.TYPE.THUNDER,
                damageClass: Damage.CLASS.HP
            ),dodgeable: false);
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (damage.damageType == Damage.TYPE.THUNDER) ::<= {
                damage.amount *= 0.5;
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Toxic',
        id : 'base:toxic',
        description: 'Gives poison damage and gives 50% poison resist',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
            to.damage(from:to, damage: Damage.new(
                amount: random.integer(from:1, to:4),
                damageType: Damage.TYPE.POISON,
                damageClass: Damage.CLASS.HP
            ),
            dodgeable: false
            );
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (damage.damageType == Damage.TYPE.POISON) ::<= {
                damage.amount *= 0.5;
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)

Effect.newEntry(
    data : {
        name : 'Shimmering',
        id : 'base:shimmering',
        description: 'Gives light damage and gives 50% dark resist',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
            to.damage(from:to, damage: Damage.new(
                amount: random.integer(from:1, to:4),
                damageType: Damage.TYPE.LIGHT,
                damageClass: Damage.CLASS.HP
            ),dodgeable: false);
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },

        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (damage.damageType == Damage.TYPE.DARK) ::<= {
                damage.amount *= 0.5;
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
)        
Effect.newEntry(
    data : {
        name : 'Dark',
        id : 'base:dark',
        description: 'Gives dark damage and gives 50% light resist',
        battleOnly : true,
        skipTurn : false,
        stackable: true,
        blockPoints : 0,
        flags : 0,
        stats: StatSet.new(),
        onAffliction ::(user, item, holder) {
        },
        
        onRemoveEffect ::(user, item, holder) {
        },                
        onPostAttackOther ::(user, item, holder, to) {
            to.damage(from:to, damage: Damage.new(
                amount: random.integer(from:1, to:4),
                damageType: Damage.TYPE.DARK,
                damageClass: Damage.CLASS.HP
            ),dodgeable: false);
        },

        onPreAttackOther ::(user, item, holder, to, damage) {
        },
        onAttacked ::(user, item, holder, by, damage) {
        
        },
        onSuccessfulBlock::(user, item, holder, from, damage) {
        
        },
        onDamage ::(user, item, holder, from, damage) {
            if (damage.damageType == Damage.TYPE.LIGHT) ::<= {
                damage.amount *= 0.5;
            }
        },
        
        onNextTurn ::(user, item, holder, turnIndex, turnCount) {

        },
        onStatRecalculate ::(user, item, holder, stats) {
        
        }
    }
) 
}

@:Effect = Database.new(
    name: "Wyvern.Effect",
    statics : {
        FLAGS : FLAGS
    },
    attributes : {
        name : String,
        id : String,
        description : String,
        battleOnly : Boolean,
        skipTurn : Boolean, // whether this effect makes the user not act for a turn
        stats : StatSet.type,
        flags : Number,
        blockPoints : Number,
        onAffliction : Function, //Called once when first activated
        onPostAttackOther : Function, // Called AFTER the user has explicitly damaged a target
        onPreAttackOther : Function, // called when user is giving damage
        onAttacked : Function, // called when user is attacked, before being damaged.
        onRemoveEffect : Function, //Called once when removed. All effects will be removed at some point.
        onDamage : Function, // when the holder of the effect is hurt
        onNextTurn : Function, //< on end phase of turn once added as an effect. Not called if duration is 0
        onStatRecalculate : Function, // on start of a turn. Not called if duration is 0
        onSuccessfulBlock : Function, // when a targetted body part is blocked by the receiver.
        stackable : Boolean // whether multiple of the same effect can coexist
    },
    reset
);

return Effect;
