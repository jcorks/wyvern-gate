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
@:dialogue = import(module:'singleton.dialogue.mt');
@:Item = import(module:'class.item.mt');
@:Damage = import(module:'class.damage.mt');
@:random = import(module:'singleton.random.mt');
@:StateFlags = import(module:'class.stateflags.mt');

@:Ability = class(
    name : 'Wyvern.Ability',    
    statics : {
        database : empty,
        TARGET_MODE : {
            ONE     : 0,    
            ALLALLY : 1,    
            RANDOM  : 2,    
            NONE    : 3,
            ALLENEMY: 4
        },
        
        USAGE_HINT : {
            OFFENSIVE : 0,
            HEAL    : 1,
            BUFF    : 2,
            DEBUFF  : 3,
            DONTUSE : 4,
        }        
    },
    define:::(this) {
        Database.setup(
            item: this,
            attributes : {
                name : String,
                description : String,
                targetMode : Number,
                usageHintAI : Number,
                durationTurns : Number, // multiduration turns supercede the choice of action
                mpCost : Number,
                hpCost : Number,

                onAction : Function
            
            }  
        );
    }
);


@:TARGET_MODE  = Ability.TARGET_MODE;
@:USAGE_HINT   = Ability.USAGE_HINT;



Ability.database = Database.new(
    items: 
        [
            Ability.new(
                data: {
                    name: 'Attack',
                    targetMode : TARGET_MODE.ONE,
                    description: "Damages a target based on the user's ATK.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' attacks ' + targets[0].name + '!'
                        );
                        
                        user.attack(
                            target:targets[0],
                            amount:user.stats.ATK * (0.5),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );                        
                                                
                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'Follow Up',
                    targetMode : TARGET_MODE.ONE,
                    description: "Damages a target based on the user's ATK, doing 150% more damage if the target was hit since their last turn.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 10,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' attacks ' + targets[0].name + ' as a follow-up!'
                        );
                        
                        if (targets[0].flags.has(flag:StateFlags.HURT_THIS_TURN)) 
                            user.attack(
                                target:targets[0],
                                amount:user.stats.ATK * (1.25),
                                damageType : Damage.TYPE.PHYS,
                                damageClass: Damage.CLASS.HP
                            )
                        else
                            user.attack(
                                target:targets[0],
                                amount:user.stats.ATK * (0.5),
                                damageType : Damage.TYPE.PHYS,
                                damageClass: Damage.CLASS.HP
                            );
                    }
                }
            ),            
            


            Ability.new(
                data: {
                    name: 'Doublestrike',
                    targetMode : TARGET_MODE.ALLENEMY,
                    description: "Damages a target based on the user's strength.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' attacks twice!'
                        );
                        user.attack(
                            target:random.pickArrayItem(list:user.enemies),
                            amount:user.stats.ATK * (0.4),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );
                        user.attack(
                            target:random.pickArrayItem(list:user.enemies),
                            amount:user.stats.ATK * (0.4),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );

                    }
                }
            ),



            Ability.new(
                data: {
                    name: 'Triplestrike',
                    targetMode : TARGET_MODE.ALLENEMY,
                    description: "Damages three targets based on the user's strength.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 24,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' attacks three times!'
                        );
                        user.attack(
                            target:random.pickArrayItem(list:user.enemies),
                            amount:user.stats.ATK * (0.4),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );
                        user.attack(
                            target:random.pickArrayItem(list:user.enemies),
                            amount:user.stats.ATK * (0.4),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );
                        user.attack(
                            target:random.pickArrayItem(list:user.enemies),
                            amount:user.stats.ATK * (0.4),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );

                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Run',
                    targetMode : TARGET_MODE.ONE,
                    description: "Takes 2 turns to run.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.DONTUSE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        user.addEffect(from:user, name: 'Running', durationTurns: 1);                        
                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Focus Perception',
                    targetMode : TARGET_MODE.NONE,
                    description: "Causes the user to focus on their enemies, making attacks 25% more effective for 5 turns.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 8,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(text:user.name + ' focuses their perception, increasing their ATK temporarily!');
                        user.addEffect(from:user, name: 'Focus Perception', durationTurns: 5);                        
                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Cheer',
                    targetMode : TARGET_MODE.ALLALLY,
                    description: "Cheers, granting a 30% damage bonus to allies for 5 turns.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 16,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(text:user.name + ' cheers for the party!');
                        user.allies->foreach(do:::(index, ally) {
                            ally.addEffect(from:user, name: 'Cheered', durationTurns: 5);                        
                        
                        });
                    }
                }
            ),


            Ability.new(
                data: {
                    name: 'Lunar Blessing',
                    targetMode : TARGET_MODE.NONE,
                    description: "Puts all of the combatants into stasis until it is night time.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 4, 
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:world = import(module:'singleton.world.mt');
                        [::] {
                            forever(do:::{
                                world.stepTime();
                                if (world.time == world.TIME.EVENING)
                                    send();                        
                            });
                        };
                        dialogue.message(text:user.name + '\'s Lunar Blessing made it night time!');
                        
                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'Solar Blessing',
                    targetMode : TARGET_MODE.NONE,
                    description: "Puts all of the combatants into stasis until it is morning.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 4, 
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:world = import(module:'singleton.world.mt');
                        [::] {
                            forever(do:::{
                                world.stepTime();
                                if (world.time == world.TIME.MORNING)
                                    send();                        
                            });
                        };
                        dialogue.message(text:user.name + '\'s Solar Blessing made it night time!');
                        
                    }
                }
            ),            
            

            Ability.new(
                data: {
                    name: 'Moonbeam',
                    targetMode : TARGET_MODE.ONE,
                    description: "Damages a target with Fire based on the user's INT. If night time, the damage is boosted.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' fires a glowing beam of moonlight!'
                        );      
                        @:world = import(module:'singleton.world.mt');
                        if (world.time >= world.TIME.EVENING) ::<= {
                            dialogue.message(
                                text: 'The beam shines brightly!'
                            );                                  
                        };
                        
                        @:world = import(module:'singleton.world.mt');
                        
                        user.attack(
                            target: targets[0],
                            amount:user.stats.INT * (if (world.time >= world.TIME.EVENING) 1.4 else 0.8),
                            damageType : Damage.TYPE.FIRE,
                            damageClass: Damage.CLASS.HP
                        );

                    }
                }
            ),


            Ability.new(
                data: {
                    name: 'Sunbeam',
                    targetMode : TARGET_MODE.ONE,
                    description: "Damages a target with Fire based on the user's INT. If day time, the damage is boosted.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' fires a glowing beam of sunlight!'
                        );      
                        @:world = import(module:'singleton.world.mt');
                        if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                            dialogue.message(
                                text: 'The beam shines brightly!'
                            );                                  
                        };
                        
                        @:world = import(module:'singleton.world.mt');
                        
                        user.attack(
                            target: targets[0],
                            amount:user.stats.INT * (if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) 1.4 else 0.8),
                            damageType : Damage.TYPE.FIRE,
                            damageClass: Damage.CLASS.HP
                        );

                    }
                }
            ),
            
            
            Ability.new(
                data: {
                    name: 'Sunburst',
                    targetMode : TARGET_MODE.ALLENEMY,
                    description: "Damages all enemies with Fire based on the user's INT. If day time, the damage is boosted.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 25,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' lets loose a burst of sunlight!'
                        );      
                        @:world = import(module:'singleton.world.mt');
                        if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                            dialogue.message(
                                text: 'The blast shines brightly!'
                            );                                  
                        };
                        
                        @:world = import(module:'singleton.world.mt');
                        
                        user.enemies->foreach(do:::(index, enemy) {
                            user.attack(
                                target: enemy,
                                amount:user.stats.INT * (if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) 1.7 else 0.9),
                                damageType : Damage.TYPE.FIRE,
                                damageClass: Damage.CLASS.HP
                            );
                        
                        });

                    }
                }
            ),            

            Ability.new(
                data: {
                    name: 'Night Veil',
                    targetMode : TARGET_MODE.ONE,
                    description: "Increases DEF of target for 5 turns. If casted during night time, it's much more powerful.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 8,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Night Veil on ' + targets[0].name + '!'
                        );
                        
                        @:world = import(module:'singleton.world.mt');
                        if (world.time >= world.TIME.EVENING) ::<= {
                            dialogue.message(
                                text: targets[0].name + ' shimmers brightly!'
                            );                                  
                            targets[0].addEffect(from:user, name: 'Greater Night Veil', durationTurns: 5);

                        } else 
                            targets[0].addEffect(from:user, name: 'Night Veil', durationTurns: 5);
                        ;
                        
                        

                    }
                }
            ),


            Ability.new(
                data: {
                    name: 'Dayshroud',
                    targetMode : TARGET_MODE.ONE,
                    description: "Increases DEF of target for 5 turns. If casted during day time, it's much more powerful.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 8,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Dayshroud on ' + targets[0].name + '!'
                        );
                        
                        @:world = import(module:'singleton.world.mt');
                        if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                            dialogue.message(
                                text: targets[0].name + ' shines brightly!'
                            );                                  
                            targets[0].addEffect(from:user, name: 'Greater Dayshroud', durationTurns: 5);

                        } else 
                            targets[0].addEffect(from:user, name: 'Dayshroud', durationTurns: 5);
                        ;
                        
                        

                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Call of the Night',
                    targetMode : TARGET_MODE.ONE,
                    description: "Increases ATK of target for 5 turns. If casted during night time, it's much more powerful.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 32,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Call of the Night on ' + targets[0].name + '!'
                        );
                        
                        @:world = import(module:'singleton.world.mt');
                        if (world.time >= world.TIME.EVENING) ::<= {
                            dialogue.message(
                                text: targets[0].name + ' shimmers brightly!'
                            );                                  
                            targets[0].addEffect(from:user, name: 'Greater Call of the Night', durationTurns: 5);

                        } else 
                            targets[0].addEffect(from:user, name: 'Call of the Night', durationTurns: 5);
                        ;
                        
                        

                    }
                }
            ),



            Ability.new(
                data: {
                    name: 'Lunacy',
                    targetMode : TARGET_MODE.ONE,
                    description: "Causes the target to go berserk and attack random enemies for their turns. DEF,ATK +70%. Only can be casted at night.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 54,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Lunacy on ' + targets[0].name + '!'
                        );
                        
                        @:world = import(module:'singleton.world.mt');
                        if (world.time >= world.TIME.EVENING) ::<= {
                            dialogue.message(
                                text: targets[0].name + ' shimmers brightly!'
                            );                                  
                            targets[0].addEffect(from:user, name: 'Lunacy', durationTurns: 7);

                        } else 
                            dialogue.message(text:'....But nothing happens!');
                        ;
                        
                        

                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Moonsong',
                    targetMode : TARGET_MODE.ONE,
                    description: "Heals over time. If casted during night time, it's much more powerful.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 26,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Moonsong on ' + targets[0].name + '!'
                        );
                        
                        @:world = import(module:'singleton.world.mt');
                        if (world.time >= world.TIME.EVENING) ::<= {
                            dialogue.message(
                                text: targets[0].name + ' shimmers brightly!'
                            );                                  
                            targets[0].addEffect(from:user, name: 'Greater Moonsong', durationTurns: 8);

                        } else 
                            targets[0].addEffect(from:user, name: 'Moonsong', durationTurns: 3);
                        ;
                        
                        

                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Sol Attunement',
                    targetMode : TARGET_MODE.ONE,
                    description: "Heals over time. If casted during day time, it's much more powerful.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 26,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Sol Attunement on ' + targets[0].name + '!'
                        );
                        
                        @:world = import(module:'singleton.world.mt');
                        if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                            dialogue.message(
                                text: targets[0].name + ' shines brightly!'
                            );                                  
                            targets[0].addEffect(from:user, name: 'Greater Sol Attunement', durationTurns: 8);

                        } else 
                            targets[0].addEffect(from:user, name: 'Sol Attunement', durationTurns: 3);
                        ;
                        
                        

                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Leg Sweep',
                    targetMode : TARGET_MODE.ALLENEMY,
                    description: "Swings, aiming for all enemies legs in hopes of stunning them.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 15,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' tries to sweep everyone\'s legs!'
                        );
                        user.enemies->foreach(do:::(i, enemy) {
                            user.attack(
                                target:enemy,
                                amount:user.stats.ATK * (0.3),
                                damageType : Damage.TYPE.PHYS,
                                damageClass: Damage.CLASS.HP
                            );
                            
                            if (Number.random() > 0.5)
                                enemy.addEffect(from:user, name: 'Stunned', durationTurns: 1);    
                        });
                    }
                }
            ),


            Ability.new(
                data: {
                    name: 'Big Swing',
                    targetMode : TARGET_MODE.ALLENEMY,
                    description: "Damages targets based on the user's strength.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' does a big swing!'
                        );      
                        targets->foreach(do:::(index, target) {
                            user.attack(
                                target,
                                amount:user.stats.ATK * (0.35),
                                damageType : Damage.TYPE.PHYS,
                                damageClass: Damage.CLASS.HP
                            );
                        });
                    }
                }
            ),


            
            Ability.new(
                data: {
                    name: 'Tackle',
                    targetMode : TARGET_MODE.ONE,
                    description: "Damages a target based on the user's strength.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 2,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' bashes ' + targets[0].name + '!'
                        );
                        user.attack(
                            target:targets[0],
                            amount:user.stats.ATK * (0.7),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );
                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Throw Item',
                    targetMode : TARGET_MODE.ONE,
                    description: "Damages a target by throwing an item.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 2,
                    usageHintAI : USAGE_HINT.DONTUSE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:pickItem = import(module:'function.pickitem.mt');
                        @:world = import(module:'singleton.world.mt');
                        
                        @:item = pickItem(inventory:world.party.inventory, canCancel:false);
                    
                        dialogue.message(
                            text: user.name + ' throws a ' + item.name + ' at ' + targets[0].name + '!'
                        );
                        
                        user.attack(
                            target:targets[0],                            
                            from: user,
                            amount:user.stats.ATK * (0.7) * (item.base.weight * 4),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );
                    }
                }
            ),



            Ability.new(
                data: {
                    name: 'Stun',
                    targetMode : TARGET_MODE.ONE,
                    description: "Damages a target based on the user's strength with a chance to stun.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' tries to stun ' + targets[0].name + '!'
                        );
                        user.attack(
                            target:targets[0],
                            amount:user.stats.ATK * (0.3),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );
                        
                        if (Number.random() > 0.5)
                            targets[0].addEffect(from:user, name: 'Stunned', durationTurns: 1);                        
                            
                    }
                }
            ),
            
            
            Ability.new(
                data: {
                    name: 'Grapple',
                    targetMode : TARGET_MODE.ONE,
                    description: "Immobilizes both the user and the target for 3 turns. 70% success rate.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 20,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' tries to grapple ' + targets[0].name + '!'
                        );
                        
                        if (Number.random() > 0.3) ::<= {
                            targets[0].addEffect(from:user, name: 'Grappled', durationTurns: 3);                        
                            user.addEffect(from:user, name: 'Grappling', durationTurns: 3);                        
                        };
                            
                    }
                }
            ),            


            Ability.new(
                data: {
                    name: 'Swipe Kick',
                    targetMode : TARGET_MODE.ONE,
                    description: "Damages a target based on the user's strength with a possibility to stun",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' does a swipe kick on ' + targets[0].name + '!'
                        );
                        user.attack(
                            target: targets[0],
                            amount:user.stats.ATK * (0.5),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );
                        
                        if (Number.random() > 0.2)
                            targets[0].addEffect(from:user, name: 'Stunned', durationTurns: 1);                        
                            
                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'Poison Attack',
                    targetMode : TARGET_MODE.ONE,
                    description: "Damages a target based on the user's strength.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' attacks ' + targets[0].name + ' with a poisoned weapon!'
                        );
                        user.attack(
                            target: targets[0],
                            amount:user.stats.ATK * (0.3),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );
                        targets[0].addEffect(from:user, name: 'Poisoned', durationTurns: 4);                        
                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'Stab',
                    targetMode : TARGET_MODE.ONE,
                    description: "Damages a target based on the user's strength and causes bleeding.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 20,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' attacks ' + targets[0].name + '!'
                        );
                        user.attack(
                            target: targets[0],
                            amount:user.stats.ATK * (0.3),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );
                        targets[0].addEffect(from:user, name: 'Bleeding', durationTurns: 4);                        
                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'First Aid',
                    targetMode : TARGET_MODE.ONE,
                    description: "Heals a target by a small amount.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 3,
                    usageHintAI : USAGE_HINT.HEAL,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' does first aid on ' + targets[0].name + '!'
                        );
                        targets[0].heal(amount:((targets[0].stats.HP*0.15)->ceil));
                    }
                }
            ),


            Ability.new(
                data: {
                    name: 'Give Snack',
                    targetMode : TARGET_MODE.ONE,
                    description: "Heals a target by a small amount.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI : USAGE_HINT.HEAL,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' gives a snack to ' + targets[0].name + '!'
                        );
                            
                        @:chance = Number.random();
                        match(true) {
                          (chance > 0.9) ::<= {        
                            dialogue.message(text: 'The snack tastes fruity!');
                            targets[0].healMP(amount:((targets[0].stats.MP*0.15)->ceil));                          
                          },

                          (chance > 0.8) ::<= {        
                            dialogue.message(text: 'The snack tastes questionable...');
                            targets[0].heal(
                                amount:(1)
                            );                          
                          },

                          default: ::<= {
                            dialogue.message(text: 'The snack tastes great!');
                            targets[0].heal(
                                amount:((targets[0].stats.HP*0.15)->ceil) 
                            );                          
                          
                          }
                          

                        };
                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'Fire',
                    targetMode : TARGET_MODE.ONE,
                    description: 'Magick that damages a target with fire.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 4,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Fire on ' + targets[0].name + '!'
                        );
                        user.attack(
                            target:targets[0],
                            amount:user.stats.INT * (1.2),
                            damageType : Damage.TYPE.FIRE,
                            damageClass: Damage.CLASS.HP
                        );
                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Flare',
                    targetMode : TARGET_MODE.ONE,
                    description: 'Magick that damages a target with fire.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 20,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Flare on ' + targets[0].name + '!'
                        );
                        user.attack(
                            target:targets[0],
                            amount:user.stats.INT * (2.0),
                            damageType : Damage.TYPE.FIRE,
                            damageClass: Damage.CLASS.HP
                        );
                    }
                }
            ),


            
            Ability.new(
                data: {
                    name: 'Ice',
                    targetMode : TARGET_MODE.ALLENEMY,
                    description: 'Magick that damages all enemies with Ice.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 8,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Ice!'
                        );
                        user.enemies->foreach(do:::(index, enemy) {
                            user.attack(
                                target:enemy,
                                amount:user.stats.INT * (0.8),
                                damageType : Damage.TYPE.ICE,
                                damageClass: Damage.CLASS.HP
                            );
                        });
                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'Explosion',
                    targetMode : TARGET_MODE.ALLENEMY,
                    description: 'Magick that damages all enemies with Fire.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 38,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Explosion!'
                        );
                        user.enemies->foreach(do:::(index, enemy) {
                            user.attack(
                                target:enemy,
                                amount:user.stats.INT * (1.85),
                                damageType : Damage.TYPE.FIRE,
                                damageClass: Damage.CLASS.HP
                            );
                        });
                    }
                }
            ),            
            
            Ability.new(
                data: {
                    name: 'Flash',
                    targetMode : TARGET_MODE.ALLENEMY,
                    description: 'Magick that blinds all enemies with a bright light.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 18,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Flash!'
                        );
                        user.enemies->foreach(do:::(index, enemy) {
                            enemy.addEffect(from:user, name: 'Blind', durationTurns: 5);
                        });
                    }
                }
            ),            

            Ability.new(
                data: {
                    name: 'Thunder',
                    targetMode : TARGET_MODE.ALLENEMY,
                    description: 'Magick that deals 4 random strikes.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 16,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Thunder!'
                        );
                        [0, 4]->for(do:::(index) {
                            @:target = random.pickArrayItem(list:user.enemies);
                            user.attack(
                                target,
                                amount:user.stats.INT * (1.2),
                                damageType : Damage.TYPE.FIRE,
                                damageClass: Damage.CLASS.HP
                            );
                        
                        });
                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Wild Swing',
                    targetMode : TARGET_MODE.ALLENEMY,
                    description: 'Attack that deals 4 random strikes.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 25,
                    usageHintAI : USAGE_HINT.OFFENSIVE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' wildly swings!'
                        );
                        [0, 4]->for(do:::(index) {
                            @:target = random.pickArrayItem(list:user.enemies);
                            user.attack(
                                target,
                                amount:user.stats.ATK * (0.9),
                                damageType : Damage.TYPE.PHYS,
                                damageClass: Damage.CLASS.HP
                            );
                        
                        });
                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Cure',
                    targetMode : TARGET_MODE.ONE,
                    description: "Heals a target by a small amount.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI : USAGE_HINT.HEAL,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Cure on ' + targets[0].name + '!'
                        );
                        targets[0].heal(amount:((targets[0].stats.HP*0.15)->ceil));
                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'Cleanse',
                    targetMode : TARGET_MODE.ONE,
                    description: "Removes the status effects: Paralyzed, Poisoned, Petrified, Burned, Frozen, and Blind.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 20,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Cleanse on ' + targets[0].name + '!'
                        );
                        @:Effect = import(module:'class.effect.mt');
                        targets[0].removeEffects(
                            effectBases: [
                                Effect.databse.find(name:'Poisoned'),
                                Effect.databse.find(name:'Paralyzed'),
                                Effect.databse.find(name:'Petrified'),
                                Effect.databse.find(name:'Burned'),
                                Effect.databse.find(name:'Blind'),
                                Effect.databse.find(name:'Frozen')                                  
                            ]
                        );

                    }
                }
            ),            

            Ability.new(
                data: {
                    name: 'Antidote',
                    targetMode : TARGET_MODE.ONE,
                    description: "Cures the poison status effect.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Effect = import(module:'class.effect.mt');
                        dialogue.message(
                            text: user.name + ' casts Antidote on ' + targets[0].name + '!'
                        );
                        targets[0].removeEffects(
                            effectBases: [
                                Effect.databse.find(name:'Poisoned')                            
                            ]
                        );
                    }
                }
            ),
            

            Ability.new(
                data: {
                    name: 'Greater Cure',
                    targetMode : TARGET_MODE.ONE,
                    description: "Heals a target by a moderate amount.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 15,
                    usageHintAI : USAGE_HINT.HEAL,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Greater Cure on ' + targets[0].name + '!'
                        );
                        targets[0].heal(amount:((targets[0].stats.HP*0.25)->ceil));
                    }
                }
            ),


            Ability.new(
                data: {
                    name: 'Protect',
                    targetMode : TARGET_MODE.ONE,
                    description: "Increases DEF of target for 10 turns.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 10,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Protect on ' + targets[0].name + '!'
                        );
                        targets[0].addEffect(from:user, name: 'Protect', durationTurns: 10);

                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'Duel',
                    targetMode : TARGET_MODE.ONE,
                    description: "Chooses a target to have a duel, causing them to take bonus damage by the user.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 10,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' challenges ' + targets[0].name + ' to a duel!'
                        );
                        targets[0].addEffect(from:user, name: 'Dueled', durationTurns: 1000000);

                    }
                }
            ),            

            Ability.new(
                data: {
                    name: 'Grace',
                    targetMode : TARGET_MODE.ONE,
                    description: "Grants the target the ability to avoid death once.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 55,
                    usageHintAI : USAGE_HINT.HEAL,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Grace on ' + targets[0].name + '!'
                        );
                        targets[0].addEffect(from:user, name: 'Grace', durationTurns: 1000);

                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'Phoenix Soul',
                    targetMode : TARGET_MODE.ONE,
                    description: "Grants the target the ability to avoid death once if casted during daytime.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 42,
                    usageHintAI : USAGE_HINT.HEAL,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Pheonix Soul on ' + targets[0].name + '!'
                        );
                        @:world = import(module:'singleton.world.mt');

                        
                        if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING)
                            targets[0].addEffect(from:user, name: 'Grace', durationTurns: 1000)
                        else 
                            dialogue.message(text:'... but nothing happened!');

                    }
                }
            ),            

            Ability.new(
                data: {
                    name: 'Protect All',
                    targetMode : TARGET_MODE.ALLALLY,
                    description: "Increases DEF of allies for 5 turns.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 25,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Protect All!'
                        );
                        user.allies->foreach(do:::(index, ally) {
                            ally.addEffect(from:user, name: 'Protect', durationTurns: 5);
                        });
                    }
                }
            ),
            Ability.new(
                data: {
                    name: 'Soothe',
                    targetMode : TARGET_MODE.ONE,
                    description: "Recovers target\'s MP by a small amount.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' uses Soothe on ' + targets[0].name +'!'
                        );
                        targets[0].healMP(amount:((targets[0].stats.MP*0.1)->ceil));
                    }
                }
            ),

            Ability.new(
                data: {
                    name: 'Meditate',
                    targetMode : TARGET_MODE.NONE,
                    description: "Recovers users MP by a small amount.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.HEAL,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' meditates!'
                        );
                        user.healMP(amount:((user.stats.MP*0.1)->ceil));
                    }
                }
            ),


            Ability.new(
                data: {
                    name: 'Soothe',
                    targetMode : TARGET_MODE.ONE,
                    description: "Relaxes a target, healing MP by a small amount.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI : USAGE_HINT.HEAL,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' casts Soothe on ' + targets[0].name + '!'
                        );
                        user.healMP(amount:((user.stats.MP*0.12)->ceil));
                    }
                }
            ),


            
            Ability.new(
                data: {
                    name: 'Steal',
                    targetMode : TARGET_MODE.ONE,
                    description: 'Steals an item from a target',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 3,
                    usageHintAI : USAGE_HINT.DEBUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:world = import(module:'singleton.world.mt');

                        dialogue.message(
                            text: user.name + ' attempted to steal from ' + targets[0].name + '!'
                        );
                        
                        when(targets[0].inventory.items->keycount == 0) 
                            dialogue.message(text:targets[0].name + ' has no items!');
                            
                        // NICE
                        if (Number.random() > 0.31) ::<= {
                            @:item = targets[0].inventory.items[0];
                            targets[0].inventory.remove(item);
                            
                            if (world.party.isMember(entity:user)) ::<= {
                                world.party.inventory.add(item);
                            } else ::<= {
                                targets[0].inventory.add(item);
                            };
                            
                            dialogue.message(text:user.name + ' stole a ' + item.name + '!');
                        } else ::<= {
                            dialogue.message(text:user.name + " couldn't steal!");                        
                        };

                    }
                }
            ),            

            Ability.new(
                data: {
                    name: 'Unarm',
                    targetMode : TARGET_MODE.ONE,
                    description: 'Disarms a target',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 3,
                    usageHintAI : USAGE_HINT.DEBUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:world = import(module:'singleton.world.mt');
                        @:Entity = import(module:'class.entity.mt');
                        dialogue.message(
                            text: user.name + ' attempted to disarm ' + targets[0].name + '!'
                        );
                        
                        @:equipped = targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L); 
                        when(equipped.name == 'None') 
                            dialogue.message(text:targets[0].name + ' has nothing in-hand!');
                            
                        // NICE
                        if (Number.random() > 0.31) ::<= {
                            targets[0].unequip(slot:Entity.EQUIP_SLOTS.HAND_L, silent:true);
                            
                            dialogue.message(text:targets[0].name + ' lost grip of their ' + equipped.name + '!');
                        } else ::<= {
                            dialogue.message(text:targets[0].name + " swiftly dodged and retaliated!");                        
                            targets[0].attack(
                                target:user,
                                amount:targets[0].stats.ATK * (0.2),
                                damageType : Damage.TYPE.PHYS,
                                damageClass: Damage.CLASS.HP
                            );


                        };

                    }
                }
            ), 
            
            Ability.new(
                data: {
                    name: 'Mug',
                    targetMode : TARGET_MODE.ONE,
                    description: 'Damages an enemy and attempts to steal gold',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 4,
                    usageHintAI : USAGE_HINT.DEBUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(
                            text: user.name + ' mugs ' + targets[0].name + '!'
                        );
                        user.attack(
                            target:targets[0],
                            amount:user.stats.ATK * (0.5),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );
                            
                        // NICE
                        if (Number.random() > 0.31) ::<= {
                            when(targets[0].inventory.gold <= 0) empty;

                            @amount = (targets[0].inventory.gold * 0.25)->ceil;
                            targets[0].inventory.subtractGold(amount);
                            
                            @:world = import(module:'singleton.world.mt');                            
                            if (world.party.isMember(entity:user)) ::<= {
                                world.party.inventory.addGold(amount);
                            } else ::<= {
                                targets[0].inventory.addGold(amount);
                            };
                            
                            dialogue.message(text:user.name + ' stole ' + amount + 'G!');
                        };

                    }
                }
            ),   
            
            Ability.new(
                data: {
                    name: 'Sneak',
                    targetMode : TARGET_MODE.ONE,
                    description: 'Guarantees times 3 damage next time an offensive ability is used next turn',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 8,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        targets[0].addEffect(from:user, name: 'Sneaked', durationTurns: 2);

                    }
                }
            ),     

            Ability.new(
                data: {
                    name: 'Mind Focus',
                    targetMode : TARGET_MODE.NONE,
                    description: 'Increases user\'s INT by 100% for 5 turns.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 8,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        targets[0].addEffect(from:user, name: 'Mind Focused', durationTurns: 5);
                    }
                }
            ), 

            Ability.new(
                data: {
                    name: 'Defend',
                    targetMode : TARGET_MODE.NONE,
                    description: 'Reduced damage for one turn.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        user.addEffect(from:user, name: 'Defend', durationTurns:1);
                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'Defensive Stance',
                    targetMode : TARGET_MODE.NONE,
                    description: 'Stance that sacrifices offensive capabilities to boost defense.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Effect = import(module:'class.effect.mt');
                        @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
                        user.removeEffects(effectBases:stances);
                        user.addEffect(from:user, name: 'Defensive Stance', durationTurns:1000);
                    }
                }
            ),            

            Ability.new(
                data: {
                    name: 'Offensive Stance',
                    targetMode : TARGET_MODE.NONE,
                    description: 'Stance that sacrifices defensive capabilities to boost offense.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Effect = import(module:'class.effect.mt');
                        @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
                        user.removeEffects(effectBases:stances);
                        user.addEffect(from:user, name: 'Offsensive Stance', durationTurns:1000);
                    }
                }
            ),            

            Ability.new(
                data: {
                    name: 'Light Stance',
                    targetMode : TARGET_MODE.NONE,
                    description: 'Stance that makes the user lighter on their feet at the cost of offense.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Effect = import(module:'class.effect.mt');
                        @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
                        user.removeEffects(effectBases:stances);
                        user.addEffect(from:user, name: 'Light Stance', durationTurns:1000);
                    }
                }
            ),             

            Ability.new(
                data: {
                    name: 'Heavy Stance',
                    targetMode : TARGET_MODE.NONE,
                    description: 'Stance that makes the user sturdier at the cost of speed.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Effect = import(module:'class.effect.mt');
                        @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
                        user.removeEffects(effectBases:stances);
                        user.addEffect(from:user, name: 'Heavy Stance', durationTurns:1000);
                    }
                }
            ),  
            
            Ability.new(
                data: {
                    name: 'Meditative Stance',
                    targetMode : TARGET_MODE.NONE,
                    description: 'Stance that makes the user more mentally focused.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Effect = import(module:'class.effect.mt');
                        @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
                        user.removeEffects(effectBases:stances);
                        user.addEffect(from:user, name: 'Meditative Stance', durationTurns:1000);
                    }
                }
            ),                 

            Ability.new(
                data: {
                    name: 'Striking Stance',
                    targetMode : TARGET_MODE.NONE,
                    description: 'Stance that focuses offense above all.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Effect = import(module:'class.effect.mt');
                        @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
                        user.removeEffects(effectBases:stances);
                        user.addEffect(from:user, name: 'Striking Stance', durationTurns:1000);
                    }
                }
            ),  
            

            Ability.new(
                data: {
                    name: 'Reflective Stance',
                    targetMode : TARGET_MODE.NONE,
                    description: 'Stance that allows the user to reflect damage.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Effect = import(module:'class.effect.mt');
                        @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
                        user.removeEffects(effectBases:stances);
                        user.addEffect(from:user, name: 'Reflective Stance', durationTurns:1000);
                    }
                }
            ), 
            
            Ability.new(
                data: {
                    name: 'Evasive Stance',
                    targetMode : TARGET_MODE.NONE,
                    description: 'Stance that allows the user to dodge incoming attacks.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Effect = import(module:'class.effect.mt');
                        @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
                        user.removeEffects(effectBases:stances);
                        user.addEffect(from:user, name: 'Evasive Stance', durationTurns:1000);
                    }
                }
            ),                            

            Ability.new(
                data: {
                    name: 'Wait',
                    targetMode : TARGET_MODE.NONE,
                    description: 'Does nothing.',
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI : USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(text:'' + user.name + ' waits.');
                    }
                }
            ),

            
            Ability.new(
                data: {
                    name: 'Use Item',
                    targetMode : TARGET_MODE.ONE,
                    description: "Uses an item from the user's inventory.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI: USAGE_HINT.DONTUSE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:item = extraData[0];
                        item.base.useEffects->foreach(do:::(index, effect) {    
                            targets->foreach(do:::(t, target) {
                                target.addEffect(from:user, name:effect, item:item, durationTurns:0);                            
                            });
                        });
                    }
                }
            ),        

            Ability.new(
                data: {
                    name: 'Quickhand Item',
                    targetMode : TARGET_MODE.ONE,
                    description: "Uses 2 items from the user's inventory.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI: USAGE_HINT.DONTUSE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @item = extraData[0];
                        item.base.useEffects->foreach(do:::(index, effect) {    
                            targets->foreach(do:::(t, target) {
                                target.addEffect(from:user, name:effect, item:item, durationTurns:0);                            
                            });
                        });

                        item = extraData[1];
                        item.base.useEffects->foreach(do:::(index, effect) {    
                            targets->foreach(do:::(t, target) {
                                target.addEffect(from:user, name:effect, item:item, durationTurns:0);                            
                            });
                        });
                    }
                }
            ),


            Ability.new(
                data: {
                    name: 'Equip Item',
                    targetMode : TARGET_MODE.ONE,
                    description: "Equips an item from the user's inventory.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI: USAGE_HINT.DONTUSE,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:item = extraData[0];
                        user.equip(
                            item, 
                            slot:user.getSlotsForItem(item)[0], 
                            inventory:extraData[1]
                        );
                    }
                }
            ),
            
            Ability.new(
                data: {
                    name: 'Defend Other',
                    targetMode : TARGET_MODE.ONE,
                    description: "Defends another from getting attacked",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI: USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        targets[0].addEffect(
                            from:user, name: 'Defend Other', durationTurns: 4 
                        );
                    }
                }
           ),

            Ability.new(
                data: {
                    name: 'Sharpen',
                    targetMode : TARGET_MODE.ONE,
                    description: "Sharpens a weapon, increasing its damage for the battle.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI: USAGE_HINT.BUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Entity = import(module:'class.entity.mt');
                        when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L).base.name == 'None')
                            dialogue.message(text:targets[0] + ' has no weapon to sharpen!');                    


                        dialogue.message(text:user.name + ' sharpens ' + targets[0].name + '\'s weapon!');

                        targets[0].addEffect(
                            from:user, name: 'Sharpen', durationTurns: 1000000 
                        );
                        
                    }
                }
           ),

            Ability.new(
                data: {
                    name: 'Weaken Armor',
                    targetMode : TARGET_MODE.ONE,
                    description: "Weakens armor, decreasing its effectiveness for the battle.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI: USAGE_HINT.DEBUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Entity = import(module:'class.entity.mt');
                        when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.ARMOR).base.name == 'None')
                            dialogue.message(text:targets[0] + ' has no armor to weaken!');                    


                        dialogue.message(text:user.name + ' weakens ' + targets[0].name + '\'s armor!');

                        targets[0].addEffect(
                            from:user, name: 'Weaken Armor', durationTurns: 1000000 
                        );
                        
                    }
                }
           ),

            Ability.new(
                data: {
                    name: 'Dull Weapon',
                    targetMode : TARGET_MODE.ONE,
                    description: "Dull a weapon, increasing its damage for next turn.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI: USAGE_HINT.DEBUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Entity = import(module:'class.entity.mt');
                        when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L).base.name == 'None')
                            dialogue.message(text:targets[0] + ' has no weapon to dull!');                    


                        dialogue.message(text:user.name + ' dulls ' + targets[0].name + '\'s weapon!');

                        targets[0].addEffect(
                            from:user, name: 'Dull Weapon', durationTurns: 1000000 
                        );
                        
                    }
                }
           ),

            Ability.new(
                data: {
                    name: 'Strengthen Armor',
                    targetMode : TARGET_MODE.ONE,
                    description: "Strengthens armor, increasing its effectiveness for the battle",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 0,
                    usageHintAI: USAGE_HINT.DEBUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        @:Entity = import(module:'class.entity.mt');
                        when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.ARMOR).base.name == 'None')
                            dialogue.message(text:targets[0] + ' has no armor to strengthen!');                    


                        dialogue.message(text:user.name + ' strengthens ' + targets[0].name + '\'s armor!');

                        targets[0].addEffect(
                            from:user, name: 'Strengthen Armor', durationTurns: 1000000 
                        );
                        
                    }
                }
           ),

           Ability.new(
                data: {
                    name: 'Convince',
                    targetMode : TARGET_MODE.ONE,
                    description: "Prevents a combatant from acting for a few turns if successful.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI: USAGE_HINT.DEBUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        dialogue.message(text:user.name + ' tries to convince ' + targets[0].name + ' to wait!');
                        
                        when(Number.random() < 0.5)
                            dialogue.message(text: targets[0].name + ' ignored ' + user.name + '!');


                        dialogue.message(text:targets[0].name + ' listens intently!');
                        targets[0].addEffect(
                            from:user, name: 'Convinced', durationTurns: 1+(Number.random()*3)->floor 
                        );
                    }
                }
            ),
            
            
           Ability.new(
                data: {
                    name: 'Bribe',
                    targetMode : TARGET_MODE.ONE,
                    description: "Pays a combatant to not fight any more.",
                    durationTurns: 0,
                    hpCost : 0,
                    mpCost : 5,
                    usageHintAI: USAGE_HINT.DEBUFF,
                    onAction: ::(user, targets, turnIndex, extraData) {
                        when (user.allies->any(condition:::(value) <- value == targets[0]))
                            dialogue.message(text: "Are you... trying to bribe me? we're... we're on the same team..");
                            
                        @:cost = targets[0].level*100 + targets[0].stats.sum * 4;
    
                        @:world = import(module:'singleton.world.mt');
    
                        dialogue.message(text: user.name + ' tries to bribe ' + targets[0].name + '!');
                        
                        match(true) {
                            // party -> NPC
                            (world.party.isMember(entity:user)) ::<= {

                                when (world.party.inventory.gold < cost)
                                    dialogue.message(text: "The party couldn't afford the " + cost + "G bribe!");
        
                                world.party.inventory.subtractGold(amount:cost);
                                targets[0].addEffect(
                                    from:user, name: 'Bribed', durationTurns: -1
                                );             
                                dialogue.message(text: user.name + ' bribes ' + targets[0].name + '!');
                            
                            },
                            
                            // NPC -> party
                            (world.party.isMember(entity:targets[0])) ::<= {
                                dialogue.message(text: user.name + ' has offered ' + cost + 'G for ' + targets[0].name + ' to stop acting for the rest of the battle.');
                                when(
                                    dialogue.choices(
                                        prompt: 'Accept offer for ' + cost + 'G?',
                                        choices : ['Yes', 'No']                    
                                    ) == 2
                                ) empty;              
                                              
                                dialogue.message(text: user.name + ' bribes ' + targets[0].name + '!');
                                targets[0].addEffect(
                                    from:user, name: 'Bribed', durationTurns: -1
                                );    
                
        
                                world.party.inventory.addGold(amount:cost);
                            },
                            
                            // NPC -> NPC
                            default: ::<={
                                targets[0].addEffect(
                                    from:user, name: 'Bribed', durationTurns: -1
                                );                                         
                            }
                        };
                    }
                }
            )
            
        ]
);


return Ability;
