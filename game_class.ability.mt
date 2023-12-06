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
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Item = import(module:'game_class.item.mt');
@:Damage = import(module:'game_class.damage.mt');
@:random = import(module:'game_singleton.random.mt');
@:StateFlags = import(module:'game_class.stateflags.mt');


@:ABILITY_NAME = 'Wyvern.Ability';

@:Ability = class(
    name : ABILITY_NAME,    
    inherits: [Database.Item],
    new ::(data) {
        @this = Ability.defaultNew();
        this.initialize(data);
        return this;
    },
    statics : ::<= {
        @database = Database.new(
            name: ABILITY_NAME,
            attributes : {
                name : String,
                description : String,
                targetMode : Number,
                usageHintAI : Number,
                oncePerBattle : Boolean,
                durationTurns : Number, // multiduration turns supercede the choice of action
                apCost : Number,
                hpCost : Number,

                onAction : Function
            } 
        );




        @TARGET_MODE = {
            ONE     : 0,    
            ALLALLY : 1,    
            RANDOM  : 2,    
            NONE    : 3,
            ALLENEMY: 4,
            ALL     : 5
        }
        
        @USAGE_HINT = {
            OFFENSIVE : 0,
            HEAL    : 1,
            BUFF    : 2,
            DEBUFF  : 3,
            DONTUSE : 4,
        } 
        
        return {
            database : {
                get ::<- database,
            },
            TARGET_MODE : {get::<- TARGET_MODE},
            USAGE_HINT : {get::<- USAGE_HINT}  
        }       
    },
    define:::(this) {
        // adds item to database and applies attributes
        Ability.database.add(item:this);
    }
);


@:TARGET_MODE  = Ability.TARGET_MODE;
@:USAGE_HINT   = Ability.USAGE_HINT;




Ability.new(
    data: {
        name: 'Attack',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's ATK.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
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
)
Ability.new(
    data: {
        name: 'Headhunter',
        targetMode : TARGET_MODE.ONE,
        description: "Deals 1 HP. 5% chance to 1hit KO.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' attempts to defeat ' + targets[0].name + ' in one attack!'
            );
            
            if (user.attack(
                target:targets[0],
                amount:1,
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
            ) == true)
                if (random.try(percentSuccess:5)) ::<= {
                    windowEvent.queueMessage(
                        text: user.name + ' does a connecting blow, finishing ' + targets[0].name +'!'
                    );                            
                    targets[0].damage(from:user, damage:Damage.new(
                        amount:999999,
                        damageType:Damage.TYPE.PHYS,
                        damageClass:Damage.CLASS.HP
                    ),dodgeable: false);                                
                }   
                                    
        }
    }
)


Ability.new(
    data: {
        name: 'Wyvern Prayer',
        targetMode : TARGET_MODE.ALL,
        description: "Prays for a miracle. If successful, uses all remaining AP.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' closes their eyes, lifts their arms, and prays to the Wyverns for guidance!'
            );
            
            
            // only valid for non-wyvern battles. No cheating!
            when (targets->any(condition::(value) <-
                value.species.name->contains(key:'Wyvern')
            ))
                windowEvent.queueMessage(
                    text: '...But the presence of a Wyvern is interrupting the prayer!'
                );
            
            
            
            // Sometimes the gods are busy or arent listening... or you have no AP to offer
            when (random.try(percentSuccess:66) || user.ap == 0) 
                windowEvent.queueMessage(
                    text: '...But nothing happened!'
                );

            

            
            (random.pickArrayItem(list:[
                // sudden death, 1 HP for everyone
                :: {
                    windowEvent.queueMessage(
                        text: 'A malevolent and dark energy befalls the battle.'
                    );
                    
                    foreach(targets) ::(k, target) {
                        target.damage(from:user, damage:Damage.new(
                            amount:target.hp-1,
                            damageType:Damage.TYPE.LIGHT,
                            damageClass:Damage.CLASS.HP
                        ),dodgeable: false, exact: true);         
                    }
                },
                
                // hurt everyone
                :: {
                    windowEvent.queueMessage(
                        text: 'Beams of line shine from above!'
                    );
                    
                    foreach(targets) ::(k, target) {
                        target.damage(from:user, damage:Damage.new(
                            amount:(target.hp/2)->floor,
                            damageType:Damage.TYPE.LIGHT,
                            damageClass:Damage.CLASS.HP
                        ),dodgeable: false, exact: true);         
                    }
                },                

                // Unequip everyone's weapon.
                :: {
                    windowEvent.queueMessage(
                        text: 'Arcs of electricity blast everyone\'s weapons out of their hands!'
                    );
                    @:Entity = import(module:'game_class.entity.mt');
                    @:party = import(module:'game_singleton.world.mt').party;                    
                    foreach(targets) ::(k, target) {
                        @:item = target.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR);
                        target.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR);
                        if (party.isMember(entity:target)) ::<= {
                            party.inventory.add(item);
                        }
                    }
                },   

                // Max HP!
                :: {
                    windowEvent.queueMessage(
                        text: 'A soothing energy envelopes the battlefield.'
                    );
                    
                    foreach(targets) ::(k, target) {
                        target.heal(amount:target.stats.HP);       
                    }
                },

                // Heal over time. Sol Attunement for now
                :: {
                    windowEvent.queueMessage(
                        text: 'A soothing energy envelopes the battlefield.'
                    );
                    
                    foreach(targets) ::(k, target) {
                        target.addEffect(from:user, name:'Greater Sol Attunement', durationTurns:9999);
                    }
                }
            ]))();
            

                                                
        }
    }
)


Ability.new(
    data: {
        name: 'Precise Strike',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's ATK and DEX.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' takes aim at ' + targets[0].name + '!'
            );
            
            user.attack(
                target:targets[0],
                amount:user.stats.ATK * (0.2) + user.stats.DEX * (0.5),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
            );                        
                                    
        }
    }
)


Ability.new(
    data: {
        name: 'Tranquilizer',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's DEX with a 45% chance to paralyze.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' attempts to tranquilize ' + targets[0].name + '!'
            );
            
            if (user.attack(
                target:targets[0],
                amount:user.stats.DEX * (0.5),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
            ) == true)                      
                if (Number.random() < 0.45)
                    targets[0].addEffect(from:user, name:'Paralyzed', durationTurns:2);


        }
    }
)



Ability.new(
    data: {
        name: 'Coordination',
        targetMode : TARGET_MODE.ALLALLY,
        description: "ATK,DEF,SPD +35% for each party member who is also the same profession.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' coordinates with others!'
            );
            
            foreach(targets)::(i, ent) {
                when(ent == user) empty;
                if (ent.profession.name == user.profession.name) ::<= {
                    // skip if already has Coordinated effect.
                    when(ent.effects->any(condition::(value) <- value.name == user.profession.name)) empty;

                    targets[0].addEffect(from:user, name: 'Coordinated', durationTurns: 1000000);
                }
            }
        }
    }
)            

Ability.new(
    data: {
        name: 'Follow Up',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's ATK, doing 150% more damage if the target was hit since their last turn.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
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
)            



Ability.new(
    data: {
        name: 'Doublestrike',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Damages a target based on the user's strength.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
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
)



Ability.new(
    data: {
        name: 'Triplestrike',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Damages three targets based on the user's strength.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
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
)


Ability.new(
    data: {
        name: 'Focus Perception',
        targetMode : TARGET_MODE.NONE,
        description: "Causes the user to focus on their enemies, making attacks 25% more effective for 5 turns.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:user.name + ' focuses their perception, increasing their ATK temporarily!');
            user.addEffect(from:user, name: 'Focus Perception', durationTurns: 5);                        
        }
    }
)

Ability.new(
    data: {
        name: 'Cheer',
        targetMode : TARGET_MODE.ALLALLY,
        description: "Cheers, granting a 30% damage bonus to allies for 5 turns.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:user.name + ' cheers for the party!');
            foreach(user.allies)::(index, ally) {
                ally.addEffect(from:user, name: 'Cheered', durationTurns: 5);                        
            
            }
        }
    }
)


Ability.new(
    data: {
        name: 'Lunar Blessing',
        targetMode : TARGET_MODE.NONE,
        description: "Puts all of the combatants into stasis until it is night time.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1, 
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            {:::} {
                forever ::{
                    world.stepTime();
                    if (world.time == world.TIME.EVENING)
                        send();                        
                }
            }
            windowEvent.queueMessage(text:user.name + '\'s Lunar Blessing made it night time!');
            
        }
    }
)

Ability.new(
    data: {
        name: 'Solar Blessing',
        targetMode : TARGET_MODE.NONE,
        description: "Puts all of the combatants into stasis until it is morning.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1, 
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            {:::} {
                forever ::{
                    world.stepTime();
                    if (world.time == world.TIME.MORNING)
                        send();                        
                }
            }
            windowEvent.queueMessage(text:user.name + '\'s Solar Blessing made it day time!');
            
        }
    }
)            


Ability.new(
    data: {
        name: 'Moonbeam',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target with Fire based on the user's INT. If night time, the damage is boosted.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' fires a glowing beam of moonlight!'
            );      
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: 'The beam shines brightly!'
                );                                  
            }
            
            @:world = import(module:'game_singleton.world.mt');
            
            user.attack(
                target: targets[0],
                amount:user.stats.INT * (if (world.time >= world.TIME.EVENING) 1.4 else 0.8),
                damageType : Damage.TYPE.FIRE,
                damageClass: Damage.CLASS.HP
            );

        }
    }
)


Ability.new(
    data: {
        name: 'Sunbeam',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target with Fire based on the user's INT. If day time, the damage is boosted.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' fires a glowing beam of sunlight!'
            );      
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: 'The beam shines brightly!'
                );                                  
            }
            
            @:world = import(module:'game_singleton.world.mt');
            
            user.attack(
                target: targets[0],
                amount:user.stats.INT * (if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) 1.4 else 0.8),
                damageType : Damage.TYPE.FIRE,
                damageClass: Damage.CLASS.HP
            );

        }
    }
)


Ability.new(
    data: {
        name: 'Sunburst',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Damages all enemies with Fire based on the user's INT. If day time, the damage is boosted.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' lets loose a burst of sunlight!'
            );      
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: 'The blast shines brightly!'
                );                                  
            }
            
            @:world = import(module:'game_singleton.world.mt');
            
            foreach(user.enemies)::(index, enemy) {
                user.attack(
                    target: enemy,
                    amount:user.stats.INT * (if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) 1.7 else 0.4),
                    damageType : Damage.TYPE.FIRE,
                    damageClass: Damage.CLASS.HP
                );
            
            }

        }
    }
)            

Ability.new(
    data: {
        name: 'Night Veil',
        targetMode : TARGET_MODE.ONE,
        description: "Increases DEF of target for 5 turns. If casted during night time, it's much more powerful.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Night Veil on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shimmers brightly!'
                );                                  
                targets[0].addEffect(from:user, name: 'Greater Night Veil', durationTurns: 5);

            } else 
                targets[0].addEffect(from:user, name: 'Night Veil', durationTurns: 5);
            ;
            
            

        }
    }
)


Ability.new(
    data: {
        name: 'Dayshroud',
        targetMode : TARGET_MODE.ONE,
        description: "Increases DEF of target for 5 turns. If casted during day time, it's much more powerful.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Dayshroud on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shines brightly!'
                );                                  
                targets[0].addEffect(from:user, name: 'Greater Dayshroud', durationTurns: 5);

            } else 
                targets[0].addEffect(from:user, name: 'Dayshroud', durationTurns: 5);
            ;
            
            

        }
    }
)

Ability.new(
    data: {
        name: 'Call of the Night',
        targetMode : TARGET_MODE.ONE,
        description: "Increases ATK of target for 5 turns. If casted during night time, it's much more powerful.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Call of the Night on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shimmers brightly!'
                );                                  
                targets[0].addEffect(from:user, name: 'Greater Call of the Night', durationTurns: 5);

            } else 
                targets[0].addEffect(from:user, name: 'Call of the Night', durationTurns: 5);
            ;
            
            

        }
    }
)



Ability.new(
    data: {
        name: 'Lunacy',
        targetMode : TARGET_MODE.ONE,
        description: "Causes the target to go berserk and attack random enemies for their turns. DEF,ATK +70%. Only can be casted at night.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Lunacy on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shimmers brightly!'
                );                                  
                targets[0].addEffect(from:user, name: 'Lunacy', durationTurns: 7);

            } else 
                windowEvent.queueMessage(text:'....But nothing happens!');
            ;
            
            

        }
    }
)

Ability.new(
    data: {
        name: 'Moonsong',
        targetMode : TARGET_MODE.ONE,
        description: "Heals over time. If casted during night time, it's much more powerful.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Moonsong on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shimmers brightly!'
                );                                  
                targets[0].addEffect(from:user, name: 'Greater Moonsong', durationTurns: 8);

            } else 
                targets[0].addEffect(from:user, name: 'Moonsong', durationTurns: 3);
            ;
            
            

        }
    }
)

Ability.new(
    data: {
        name: 'Sol Attunement',
        targetMode : TARGET_MODE.ONE,
        description: "Heals over time. If casted during day time, it's much more powerful.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Sol Attunement on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shines brightly!'
                );                                  
                targets[0].addEffect(from:user, name: 'Greater Sol Attunement', durationTurns: 3);

            } else 
                targets[0].addEffect(from:user, name: 'Sol Attunement', durationTurns: 3);
            ;
            
            

        }
    }
)

Ability.new(
    data: {
        name: 'Ensnare',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target and immobilizes both the user and the target for 3 turns. 80% success rate.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' tries to ensnare ' + targets[0].name + '!'
            );
            
            
            if (user.attack(
                target:targets[0],
                amount:user.stats.ATK * (0.3),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
            ) == true)                        
                if (random.try(percentSuccess:80)) ::<= {
                    targets[0].addEffect(from:user, name: 'Ensnared', durationTurns: 3);                        
                    user.addEffect(from:user, name: 'Ensnaring', durationTurns: 3);                        
                }
                
        }
    }
) 


Ability.new(
    data: {
        name: 'Call',
        targetMode : TARGET_MODE.NONE,
        description: "Calls a creature to come and join the fight.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' makes an eerie call!'
            );
            
            if (random.flipCoin()) ::<= {
                @:instance = import(module:'game_singleton.instance.mt');
            
                @help = instance.island.newHostileCreature();
                @battle = user.battle;
                if (battle.allies->findIndex(value:user) == -1) ::<= {
                    battle.join(enemy:help);
                } else ::<= {
                    battle.join(ally:help);
                }
                
            } else ::<= {
                windowEvent.queueMessage(
                    text: '...but nothing happened!'
                );                        
            }
                                        
        }
    }
) 



Ability.new(
    data: {
        name: 'Tame',
        targetMode : TARGET_MODE.ONE,
        description: "Attempts to tame a creature, making it a party member if successful.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' attempts to tame ' + targets[0].name + '!'
            );

            when(targets[0].species.name != 'Creature') ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' was not receptive to being tamed!'
                );                            
            }
            @:party = import(module:'game_singleton.world.mt').party;                    

            when(party.isMember(entity:targets[0])) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' is already tamed!'
                );
                
            }

            
            if (random.flipCoin()) ::<= {
                windowEvent.queueMessage(
                    text: '' + targets[0].name + ' was tamed!'
                );                        
                party.add(member:targets[0]);
            } else ::<= {
                windowEvent.queueMessage(
                    text: '...but ' + targets[0].name + ' continued to be untamed!'
                );                        
            }
                                        
        }
    }
) 

Ability.new(
    data: {
        name: 'Leg Sweep',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Swings, aiming for all enemies legs in hopes of stunning them.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' tries to sweep everyone\'s legs!'
            );
            foreach(user.enemies)::(i, enemy) {
                if (user.attack(
                    target:enemy,
                    amount:user.stats.ATK * (0.3),
                    damageType : Damage.TYPE.PHYS,
                    damageClass: Damage.CLASS.HP
                ) == true)
                    if (Number.random() > 0.5)
                        enemy.addEffect(from:user, name: 'Stunned', durationTurns: 1);    
            }
        }
    }
)


Ability.new(
    data: {
        name: 'Big Swing',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Damages targets based on the user's strength.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' does a big swing!'
            );      
            foreach(targets)::(index, target) {
                user.attack(
                    target,
                    amount:user.stats.ATK * (0.35),
                    damageType : Damage.TYPE.PHYS,
                    damageClass: Damage.CLASS.HP
                );
            }
        }
    }
)



Ability.new(
    data: {
        name: 'Tackle',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's strength.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
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
)

Ability.new(
    data: {
        name: 'Throw Item',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target by throwing an item.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:pickItem = import(module:'game_function.pickitem.mt');
            @:world = import(module:'game_singleton.world.mt');
            
            @:item = pickItem(inventory:world.party.inventory, canCancel:false);
        
            windowEvent.queueMessage(
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
)



Ability.new(
    data: {
        name: 'Stun',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's strength with a chance to stun.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' tries to stun ' + targets[0].name + '!'
            );
            if (user.attack(
                target:targets[0],
                amount:user.stats.ATK * (0.3),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
            ) == true)                    
                if (Number.random() > 0.5)
                    targets[0].addEffect(from:user, name: 'Stunned', durationTurns: 1);                        
                
        }
    }
)

Ability.new(
    data: {
        name: 'Sheer Cold',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's strength with a chance to stun.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: 'A cold air emminates from ' + user.name + '!'
            );
            if (user.attack(
                target:targets[0],
                amount:user.stats.ATK * (0.4),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
            ) == true)                    
                if (Number.random() < 0.9)
                    targets[0].addEffect(from:user, name: 'Frozen', durationTurns: 1);                        
                
        }
    }
)


Ability.new(
    data: {
        name: 'Mind Read',
        targetMode : TARGET_MODE.ONE,
        description: 'Uses a random offsensive ability of the target\'s',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' reads ' + targets[0].name + '\'s mind!'
            );
            
            @:choices = targets[0].abilitiesAvailable;
            
            // offensive moves only
            @:firstChoices = choices->filter(by:::(value) <- value.usageHintAI == USAGE_HINT.OFFENSIVE && value.name != 'Attack');
            when(firstChoices->keycount) ::<= {
                @:Random = import(module:'game_singleton.random.mt');
                @:which = Random.pickArrayItem(list:firstChoices);
                user.useAbility(
                    ability:which,
                    targets,
                    turnIndex,
                    extraData
                );
            }
            
            windowEvent.queueMessage(
                text: user.name + ' couldn\'t find any offensive abilities to use!'
            );                        
            
        }
    }
)             
Ability.new(
    data: {
        name: 'Flight',
        targetMode : TARGET_MODE.ONE,
        description: "Causes the target to fly, making all damage miss the target for 3 turns",
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Flight on ' + targets[0].name + '!'
            );
            targets[0].addEffect(from:user, name: 'Flight', durationTurns: 3);
                
        }
    }
)         
Ability.new(
    data: {
        name: 'Grapple',
        targetMode : TARGET_MODE.ONE,
        description: "Immobilizes both the user and the target for 3 turns. 70% success rate.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' tries to grapple ' + targets[0].name + '!'
            );
            
            if (Number.random() > 0.3) ::<= {
                targets[0].addEffect(from:user, name: 'Grappled', durationTurns: 3);                        
                user.addEffect(from:user, name: 'Grappling', durationTurns: 3);                        
            }
                
        }
    }
)            


Ability.new(
    data: {
        name: 'Swipe Kick',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's strength with a possibility to stun",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
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
)

Ability.new(
    data: {
        name: 'Poison Rune',
        targetMode : TARGET_MODE.ONE,
        description: "Places a poison rune on a target, which causes damage to the target each turn.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Poison Rune on ' + targets[0].name + '!'
            );
            targets[0].addEffect(from:user, name: 'Poison Rune', durationTurns: 10);                        
        }
    }
)            
Ability.new(
    data: {
        name: 'Rune Release',
        targetMode : TARGET_MODE.ONE,
        description: "Release all runes.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' releases all the runes on ' + targets[0].name + '!'
            );
            
            @:effects = [...targets[0].effects->filter(by:::(value) <- 
                match(value.effect.name) {
                  (
                    'Poison Rune',
                    'Destruction Rune',
                    'Regeneration Rune',
                    'Cure Rune',
                    'Shield Rune'                             
                  ): true,
                  default: false
                }
            )]->map(to:::(value) <- value.effect);
            
            @toRemove = [];
            breakpoint();
            foreach(effects)::(i, effect) {
                toRemove->push(value:effect);
                match(effect.name) {                              
                  ('Destruction Rune'): ::<= {
                    windowEvent.queueMessage(text:'The release of the Destruction Rune causes it to explode on ' + targets[0].name + '!');
                    targets[0].damage(from:user, damage:Damage.new(
                        amount:user.stats.INT * (1.2),
                        damageType:Damage.TYPE.PHYS,
                        damageClass:Damage.CLASS.HP
                    ),dodgeable: false);                
                  },

                  ('Cure Rune'): ::<= {
                    windowEvent.queueMessage(text:'The release of the Cure Rune causes it to heal ' + targets[0].name + '!');
                    targets[0].heal(
                        amount: targets[0].stats.HP * 0.3
                    );                
                  }
                }                      
            }
            
            targets[0].removeEffects(effectBases:toRemove);                        
        }
    }
)            
Ability.new(
    data: {
        name: 'Destruction Rune',
        targetMode : TARGET_MODE.ONE,
        description: "Places a destruction rune on a target, which causes INT-based damaged upon release.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Destruction Rune on ' + targets[0].name + '!'
            );
            targets[0].addEffect(from:user, name: 'Destruction Rune', durationTurns: 10);                        
        }
    }
)       


Ability.new(
    data: {
        name: 'Regeneration Rune',
        targetMode : TARGET_MODE.ONE,
        description: "Places a regeneration rune on a target, which slightly heals a target every turn.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Regeneration Rune on ' + targets[0].name + '!'
            );
            targets[0].addEffect(from:user, name: 'Regeneration Rune', durationTurns: 10);                        
        }
    }
)
Ability.new(
    data: {
        name: 'Shield Rune',
        targetMode : TARGET_MODE.ONE,
        description: "Places a shield rune on a target, which gives +100% DEF while active.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Shield Rune on ' + targets[0].name + '!'
            );
            targets[0].addEffect(from:user, name: 'Shield Rune', durationTurns: 10);                        
        }
    }
)  
Ability.new(
    data: {
        name: 'Cure Rune',
        targetMode : TARGET_MODE.ONE,
        description: "Places a cure rune on a target, which heals the target when the rune is released.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Cure Rune on ' + targets[0].name + '!'
            );
            targets[0].addEffect(from:user, name: 'Cure Rune', durationTurns: 10);                        
        }
    }
)             

Ability.new(
    data: {
        name: 'Multiply Runes',
        targetMode : TARGET_MODE.ONE,
        description: "Doubles all current runes on a target.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Multiply Runes on ' + targets[0].name + '!'
            );
            
            @:effects = targets[0].effects->filter(by:::(value) <- 
                match(value.effect.name) {
                  (
                    'Poison Rune',
                    'Destruction Rune',
                    'Regeneration Rune',
                    'Cure Rune',
                    'Shield Rune'                             
                  ): true,
                  default: false
                }
            );
            
            foreach(effects)::(i, effect) {
                targets[0].addEffect(from:user, name:effect.effect.name, durationTurns:10);
            }
        }
    }
)  

                 
Ability.new(
    data: {
        name: 'Poison Attack',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's strength with a poisoned weapon.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
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
)

Ability.new(
    data: {
        name: 'Petrify',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's strength with a special petrification poison.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' attacks ' + targets[0].name + ' with a poisoned weapon!'
            );
            user.attack(
                target: targets[0],
                amount:user.stats.ATK * (0.3),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
            );
            targets[0].addEffect(from:user, name: 'Petrified', durationTurns: 2);                        
        }
    }
)            
Ability.new(
    data: {
        name: 'Tripwire',
        targetMode : TARGET_MODE.ONE,
        description: "Activates a tripwire set up prior to battle, causing the target to be stunned for 3 turns. Only works once per battle.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : true,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' activates the tripwire right under ' + targets[0].name + '!'
            );
            targets[0].addEffect(from:user, name: 'Stunned', durationTurns: 2);                        
        }
    }
)


Ability.new(
    data: {
        name: 'Trip Explosive',
        targetMode : TARGET_MODE.ONE,
        description: "Activates a tripwire-activated explosive set up prior to battle, causing the target to be damaged. Only works once per battle.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : true,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' activates the tripwire explosive right under ' + targets[0].name + '!'
            );
            when(random.try(percentSuccess:70)) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' avoided the trap!'
                );                                
            }
            targets[0].damage(from:user, damage:Damage.new(
                amount:50,
                damageType:Damage.TYPE.FIRE,
                damageClass:Damage.CLASS.HP
            ),dodgeable: false);  
        }
    }
)


Ability.new(
    data: {
        name: 'Spike Pit',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Activates a floor trap leading to a spike pit. Only works once per battle.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : true,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' activates a floor trap, revealing a spike pit under the enemies!'
            );
            
            foreach(targets)::(i, target) {
                when(random.try(percentSuccess:70)) ::<= {
                    windowEvent.queueMessage(
                        text: target.name + ' avoided the trap!'
                    );                                
                }
                target.damage(from:user, damage:Damage.new(
                    amount:50,
                    damageType:Damage.TYPE.PHYS,
                    damageClass:Damage.CLASS.HP
                ),dodgeable: false);   
                target.addEffect(from:user, name: 'Stunned', durationTurns: 2);                        
            }
        }
    }
)            

Ability.new(
    data: {
        name: 'Stab',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's strength and causes bleeding.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' attacks ' + targets[0].name + '!'
            );
            if (user.attack(
                target: targets[0],
                amount:user.stats.ATK * (0.3),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
            ) == true)
                targets[0].addEffect(from:user, name: 'Bleeding', durationTurns: 4);                        
        }
    }
)

Ability.new(
    data: {
        name: 'First Aid',
        targetMode : TARGET_MODE.ONE,
        description: "Heals a target by a small amount.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' does first aid on ' + targets[0].name + '!'
            );
            targets[0].heal(amount:((targets[0].stats.HP*0.25)->ceil));
        }
    }
)


Ability.new(
    data: {
        name: 'Mend',
        targetMode : TARGET_MODE.ONE,
        description: "Heals a target by a small amount.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' mends ' + targets[0].name + '!'
            );
            targets[0].heal(amount:((targets[0].stats.HP*0.25)->ceil));
        }
    }
)

Ability.new(
    data: {
        name: 'Give Snack',
        targetMode : TARGET_MODE.ONE,
        description: "Heals a target by a small amount.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' gives a snack to ' + targets[0].name + '!'
            );
                
            @:chance = Number.random();
            match(true) {
              (chance > 0.9) ::<= {        
                windowEvent.queueMessage(text: 'The snack tastes fruity!');
                targets[0].healAP(amount:((targets[0].stats.AP*0.15)->ceil));                          
              },

              (chance > 0.8) ::<= {        
                windowEvent.queueMessage(text: 'The snack tastes questionable...');
                targets[0].heal(
                    amount:(1)
                );                          
              },

              default: ::<= {
                windowEvent.queueMessage(text: 'The snack tastes great!');
                targets[0].heal(
                    amount:((targets[0].stats.HP*0.15)->ceil) 
                );                          
              
              }
              

            }
        }
    }
)


Ability.new(
    data: {
        name: 'Summon: Fire Sprite',
        targetMode : TARGET_MODE.NONE,
        description: 'Summons a fire sprite to fight on your side.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:world = import(module:'game_singleton.world.mt');

            windowEvent.queueMessage(
                text: user.name + ' summons a Fire Sprite!'
            );

            // limit 2 summons at a time.
            @count = 0;
            foreach(user.allies)::(i, ally) {
                match(ally.name) {
                    ('the Fire Sprite',
                    'the Ice Elemental',
                    'the Thunder Spawn',
                    'the Guiding Light'): ::<= {
                        count += 1;
                    }
                }
            }
            when (count >= 2) 
                windowEvent.queueMessage(
                    text: '...but the summoning fizzled!'
                );


            @:Entity = import(module:'game_class.entity.mt');
            @:Species = import(module:'game_class.species.mt');
            @:sprite = Entity.new(
                island : world.island,
                speciesHint: 'Fire Sprite',
                professionHint: 'Fire Sprite',
                levelHint:5
            );
            sprite.name = 'the Fire Sprite';
            
            for(0, 10)::(i) {
                sprite.learnNextAbility();
            }
            
            @:battle = user.battle;
            if (battle.allies->findIndex(value:user) != -1)
                battle.join(
                    ally: sprite                               
                )
            else
                battle.join(
                    enemy: sprite                                                                                       
                )
            ;
        }
    }
)

Ability.new(
    data: {
        name: 'Summon: Ice Elemental',
        targetMode : TARGET_MODE.NONE,
        description: 'Summons an ice elemental to fight on your side.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' summons an Ice Elemental!'
            );
            @count = 0;
            foreach(user.allies)::(i, ally) {
                match(ally.name) {
                    ('the Fire Sprite',
                    'the Ice Elemental',
                    'the Thunder Spawn',
                    'the Guiding Light'): ::<= {
                        count += 1;
                    }
                }
            }
            when (count >= 2) 
                windowEvent.queueMessage(
                    text: '...but the summoning fizzled!'
                );


            
            @:Entity = import(module:'game_class.entity.mt');
            @:Species = import(module:'game_class.species.mt');
            @:world = import(module:'game_singleton.world.mt');
            @:sprite = Entity.new(
                island: world.island,
                speciesHint: 'Ice Elemental',
                professionHint: 'Ice Elemental',
                levelHint:5
            );
            sprite.name = 'the Ice Elemental';
            
            for(0, 10)::(i) {
                sprite.learnNextAbility();
            }
            
            @:battle = user.battle;
            if (battle.allies->findIndex(value:user) != -1)
                battle.join(
                    ally: sprite                               
                )
            else
                battle.join(
                    enemy: sprite                                                                                       
                )
            ;
        }
    }
)            

Ability.new(
    data: {
        name: 'Summon: Thunder Spawn',
        targetMode : TARGET_MODE.NONE,
        description: 'Summons a thunder spawn to fight on your side.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' summons a Thunder Spawn!'
            );
            @count = 0;
            foreach(user.allies)::(i, ally) {
                match(ally.name) {
                    ('the Fire Sprite',
                    'the Ice Elemental',
                    'the Thunder Spawn',
                    'the Guiding Light'): ::<= {
                        count += 1;
                    }
                }
            }
            when (count >= 2) 
                windowEvent.queueMessage(
                    text: '...but the summoning fizzled!'
                );
            
            @:Entity = import(module:'game_class.entity.mt');
            @:Species = import(module:'game_class.species.mt');
            @:world = import(module:'game_singleton.world.mt');
            @:sprite = Entity.new(
                island: world.island,
                speciesHint: 'Thunder Spawn',
                professionHint: 'Thunder Spawn',
                levelHint:5
            );
            sprite.name = 'the Thunder Spawn';
            
            for(0, 10)::(i) {
                sprite.learnNextAbility();
            }
            
            @:battle = user.battle;
            if (battle.allies->findIndex(value:user) != -1)
                battle.join(
                    ally: sprite                               
                )
            else
                battle.join(
                    enemy: sprite                                                                                       
                )
            ;
        }
    }
)       

Ability.new(
    data: {
        name: 'Summon: Guiding Light',
        targetMode : TARGET_MODE.NONE,
        description: 'Summons a guiding light to fight on your side.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' summons a Guiding Light!'
            );
            @count = 0;
            foreach(user.allies)::(i, ally) {
                match(ally.name) {
                    ('the Fire Sprite',
                    'the Ice Elemental',
                    'the Thunder Spawn',
                    'the Guiding Light'): ::<= {
                        count += 1;
                    }
                }
            }
            when (count >= 2) 
                windowEvent.queueMessage(
                    text: '...but the summoning fizzled!'
                );
            
            @:Entity = import(module:'game_class.entity.mt');
            @:Species = import(module:'game_class.species.mt');
            @:world = import(module:'game_singleton.world.mt');
            @:sprite = Entity.new(
                island: world.island,
                speciesHint: 'Guiding Light',
                professionHint: 'Guiding Light',
                levelHint:5
            );
            sprite.name = 'the Guiding Light';
            
            for(0, 10)::(i) {
                sprite.learnNextAbility();
            }
            
            @:battle = user.battle;
            if (battle.allies->findIndex(value:user) != -1)
                battle.join(
                    ally: sprite                               
                )
            else
                battle.join(
                    enemy: sprite                                                                                       
                )
            ;
        }
    }
)                   

Ability.new(
    data: {
        name: 'Unsummon',
        targetMode : TARGET_MODE.ONE,
        description: 'Magick that removes a summoned entity.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Unsummon on ' + targets[0].name + '!'
            );

            if (match(targets[0].name) {
                ('the Fire Sprite',
                 'the Ice Elemental',
                 'the Thunder Spawn',
                 'the Guiding Light'): true,
                default: false
            }) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' faded into nothingness!'
                );                            
                targets[0].kill(silent:true);  
            } else ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' was unaffected!'
                );                                                        
            }
            
                

        }
    }
)                        

Ability.new(
    data: {
        name: 'Fire',
        targetMode : TARGET_MODE.ONE,
        description: 'Magick that damages a target with fire.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
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
)


Ability.new(
    data: {
        name: 'Backdraft',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Using great amount of heat, gives targets burns.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' generates a great amount of heat!'
            );
            
            foreach(targets)::(i, target) {
                if (user.attack(
                    target:target,
                    amount:user.stats.INT * (0.6),
                    damageType : Damage.TYPE.FIRE,
                    damageClass: Damage.CLASS.HP
                ))
                    targets[0].addEffect(from:user, name:'Burned', durationTurns:5);
                                          
            }
        }
    }
)




Ability.new(
    data: {
        name: 'Flare',
        targetMode : TARGET_MODE.ONE,
        description: 'Magick that damages a target with fire.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
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
)


Ability.new(
    data: {
        name: 'Dematerialize',
        targetMode : TARGET_MODE.ONE,
        description: 'Magick that unequips a target\'s equipment',
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI : USAGE_HINT.OFFENSIVE,	
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Dematerialize on ' + targets[0].name + '!'
            );
            @:Entity = import(module:'game_class.entity.mt');
            @:Random = import(module:'game_singleton.random.mt');
            @:item = ::<= {
                @:list = [];
                foreach(Entity.EQUIP_SLOTS)::(i, slot) {
                    @out = targets[0].getEquipped(slot);
                    if (out)
                        list->push(value:out);
                }
                return Random.pickArrayItem(list);
            }
            targets[0].unequipItem(item);
            windowEvent.queueMessage(
                text: targets[0].name + '\'s ' + item.name + ' gets unequipped!'
            );
        }
    }
)



Ability.new(
    data: {
        name: 'Ice',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Magick that damages all enemies with Ice.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Ice!'
            );
            foreach(user.enemies)::(index, enemy) {
                user.attack(
                    target:enemy,
                    amount:user.stats.INT * (0.8),
                    damageType : Damage.TYPE.ICE,
                    damageClass: Damage.CLASS.HP
                );
            }
        }
    }
)

Ability.new(
    data: {
        name: 'Frozen Flame',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Magick that causes enemies to spontaneously combust in a cold, blue flame. Might freeze the targets.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Frozen Flame!'
            );
            foreach(user.enemies)::(index, enemy) {
                user.attack(
                    target:enemy,
                    amount:user.stats.INT * (0.75),
                    damageType : Damage.TYPE.ICE,
                    damageClass: Damage.CLASS.HP
                );
            }


        }
    }
)            


Ability.new(
    data: {
        name: 'Telekinesis',
        targetMode : TARGET_MODE.ONE,
        description: 'Magick that moves a target around, stunning them',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Telekinesis!'
            );
            if (random.flipCoin())
                targets[0].addEffect(from:user, name: 'Stunned', durationTurns: 1)                       
            else 
                windowEvent.queueMessage(
                    text: '...but it missed!'
                );

        }
    }
)          


Ability.new(
    data: {
        name: 'Explosion',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Magick that damages all enemies with Fire.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Explosion!'
            );
            foreach(user.enemies)::(index, enemy) {
                user.attack(
                    target:enemy,
                    amount:user.stats.INT * (1.2),
                    damageType : Damage.TYPE.FIRE,
                    damageClass: Damage.CLASS.HP
                );
            }
        }
    }
)            

Ability.new(
    data: {
        name: 'Flash',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Magick that blinds all enemies with a bright light.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Flash!'
            );
            foreach(user.enemies)::(index, enemy) {
                if (random.flipCoin())
                    enemy.addEffect(from:user, name: 'Blind', durationTurns: 5)
                else 
                    windowEvent.queueMessage(
                        text: enemy.name + ' covered their eyes!'
                    );                                
            }
        }
    }
)            

Ability.new(
    data: {
        name: 'Thunder',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Magick that deals 4 random strikes.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Thunder!'
            );
            for(0, 4)::(index) {
                @:target = random.pickArrayItem(list:user.enemies);
                user.attack(
                    target,
                    amount:user.stats.INT * (0.45),
                    damageType : Damage.TYPE.THUNDER,
                    damageClass: Damage.CLASS.HP
                );
            
            }
        }
    }
)

Ability.new(
    data: {
        name: 'Wild Swing',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Attack that deals 4 random strikes.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' wildly swings!'
            );
            for(0, 4)::(index) {
                @:target = random.pickArrayItem(list:user.enemies);
                user.attack(
                    target,
                    amount:user.stats.ATK * (0.9),
                    damageType : Damage.TYPE.PHYS,
                    damageClass: Damage.CLASS.HP
                );
            
            }
        }
    }
)

Ability.new(
    data: {
        name: 'Cure',
        targetMode : TARGET_MODE.ONE,
        description: "Heals a target by a small amount.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Cure on ' + targets[0].name + '!'
            );
            targets[0].heal(amount:((targets[0].stats.HP*0.5)->ceil));
        }
    }
)



Ability.new(
    data: {
        name: 'Cleanse',
        targetMode : TARGET_MODE.ONE,
        description: "Removes the status effects: Paralyzed, Poisoned, Petrified, Burned, Frozen, and Blind.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Cleanse on ' + targets[0].name + '!'
            );
            @:Effect = import(module:'game_class.effect.mt');
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
)          

Ability.new(
    data: {
        name: 'Magic Mist',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Removes ALL effects.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            foreach(targets)::(i, target) {
                windowEvent.queueMessage(
                    text: user.name + ' casts Magic Mist on ' + target.name + '!'
                );
                user.resetEffects();
            }
        }
    }
)


Ability.new(
    data: {
        name: 'Antidote',
        targetMode : TARGET_MODE.ONE,
        description: "Cures the poison status effect.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Effect = import(module:'game_class.effect.mt');
            windowEvent.queueMessage(
                text: user.name + ' casts Antidote on ' + targets[0].name + '!'
            );
            targets[0].removeEffects(
                effectBases: [
                    Effect.databse.find(name:'Poisoned')                            
                ]
            );
        }
    }
)


Ability.new(
    data: {
        name: 'Greater Cure',
        targetMode : TARGET_MODE.ONE,
        description: "Heals a target by a moderate amount.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Greater Cure on ' + targets[0].name + '!'
            );
            targets[0].heal(amount:((targets[0].stats.HP*0.7)->ceil));
        }
    }
)


Ability.new(
    data: {
        name: 'Protect',
        targetMode : TARGET_MODE.ONE,
        description: "Increases DEF of target for 10 turns.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Protect on ' + targets[0].name + '!'
            );
            targets[0].addEffect(from:user, name: 'Protect', durationTurns: 10);

        }
    }
)

Ability.new(
    data: {
        name: 'Duel',
        targetMode : TARGET_MODE.ONE,
        description: "Chooses a target to have a duel, causing them to take bonus damage by the user.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' challenges ' + targets[0].name + ' to a duel!'
            );
            targets[0].addEffect(from:user, name: 'Dueled', durationTurns: 1000000);

        }
    }
)

Ability.new(
    data: {
        name: 'Grace',
        targetMode : TARGET_MODE.ONE,
        description: "Grants the target the ability to avoid death once.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Grace on ' + targets[0].name + '!'
            );
            targets[0].addEffect(from:user, name: 'Grace', durationTurns: 1000);

        }
    }
)

Ability.new(
    data: {
        name: 'Phoenix Soul',
        targetMode : TARGET_MODE.ONE,
        description: "Grants the target the ability to avoid death once if casted during daytime.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Pheonix Soul on ' + targets[0].name + '!'
            );
            @:world = import(module:'game_singleton.world.mt');

            
            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING)
                targets[0].addEffect(from:user, name: 'Grace', durationTurns: 1000)
            else 
                windowEvent.queueMessage(text:'... but nothing happened!');

        }
    }
)            

Ability.new(
    data: {
        name: 'Protect All',
        targetMode : TARGET_MODE.ALLALLY,
        description: "Increases DEF of allies for 5 turns.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Protect All!'
            );
            foreach(user.allies)::(index, ally) {
                ally.addEffect(from:user, name: 'Protect', durationTurns: 5);
            }
        }
    }
)

Ability.new(
    data: {
        name: 'Meditate',
        targetMode : TARGET_MODE.NONE,
        description: "Recovers users AP by a small amount.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' meditates!'
            );
            user.healAP(amount:((user.stats.AP*0.2)->ceil));
        }
    }
)


Ability.new(
    data: {
        name: 'Soothe',
        targetMode : TARGET_MODE.ONE,
        description: "Relaxes a target, healing AP by a small amount.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 5,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Soothe on ' + targets[0].name + '!'
            );
            user.healAP(amount:((user.stats.AP*0.22)->ceil));
        }
    }
)



Ability.new(
    data: {
        name: 'Steal',
        targetMode : TARGET_MODE.ONE,
        description: 'Steals an item from a target',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:world = import(module:'game_singleton.world.mt');

            windowEvent.queueMessage(
                text: user.name + ' attempted to steal from ' + targets[0].name + '!'
            );
            
            when(targets[0].inventory.items->keycount == 0) 
                windowEvent.queueMessage(text:targets[0].name + ' has no items!');
                
            // NICE
            if (Number.random() > 0.31) ::<= {
                @:item = targets[0].inventory.items[0];
                targets[0].inventory.remove(item);
                
                if (world.party.isMember(entity:user)) ::<= {
                    world.party.inventory.add(item);
                } else ::<= {
                    targets[0].inventory.add(item);
                }
                
                windowEvent.queueMessage(text:user.name + ' stole a ' + item.name + '!');
            } else ::<= {
                windowEvent.queueMessage(text:user.name + " couldn't steal!");                        
            }

        }
    }
)            


Ability.new(
    data: {
        name: 'Counter',
        targetMode : TARGET_MODE.NONE,
        description: 'If attacked, dodges and retaliates for 3 turns.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            user.addEffect(from:user, name: 'Counter', durationTurns: 3);
        }
    }
)



Ability.new(
    data: {
        name: 'Unarm',
        targetMode : TARGET_MODE.ONE,
        description: 'Disarms a target',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @:Entity = import(module:'game_class.entity.mt');
            windowEvent.queueMessage(
                text: user.name + ' attempted to disarm ' + targets[0].name + '!'
            );
            
            @:equipped = targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR); 
            when(equipped.name == 'None') 
                windowEvent.queueMessage(text:targets[0].name + ' has nothing in-hand!');
                
            // NICE
            if (Number.random() > 0.31) ::<= {
                targets[0].unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
                
                windowEvent.queueMessage(text:targets[0].name + ' lost grip of their ' + equipped.name + '!');
            } else ::<= {
                windowEvent.queueMessage(text:targets[0].name + " swiftly dodged and retaliated!");                        
                targets[0].attack(
                    target:user,
                    amount:targets[0].stats.ATK * (0.2),
                    damageType : Damage.TYPE.PHYS,
                    damageClass: Damage.CLASS.HP
                );


            }

        }
    }
) 

Ability.new(
    data: {
        name: 'Mug',
        targetMode : TARGET_MODE.ONE,
        description: 'Damages an enemy and attempts to steal gold',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(
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
                
                @:world = import(module:'game_singleton.world.mt');                            
                if (world.party.isMember(entity:user)) ::<= {
                    world.party.inventory.addGold(amount);
                } else ::<= {
                    targets[0].inventory.addGold(amount);
                }
                
                windowEvent.queueMessage(text:user.name + ' stole ' + amount + 'G!');
            }

        }
    }
)   

Ability.new(
    data: {
        name: 'Sneak',
        targetMode : TARGET_MODE.ONE,
        description: 'Guarantees times 3 damage next time an offensive ability is used next turn',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            targets[0].addEffect(from:user, name: 'Sneaked', durationTurns: 2);

        }
    }
)     

Ability.new(
    data: {
        name: 'Mind Focus',
        targetMode : TARGET_MODE.NONE,
        description: 'Increases user\'s INT by 100% for 5 turns.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            targets[0].addEffect(from:user, name: 'Mind Focused', durationTurns: 5);
        }
    }
) 




Ability.new(
    data: {
        name: 'Defend',
        targetMode : TARGET_MODE.NONE,
        description: 'Reduced damage for one turn.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            user.addEffect(from:user, name: 'Defend', durationTurns:1);
            user.flags.add(flag:StateFlags.DEFENDED);
        }
    }
)

Ability.new(
    data: {
        name: 'Guard',
        targetMode : TARGET_MODE.NONE,
        description: 'Reduced damage for one turn.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            user.addEffect(from:user, name: 'Guard', durationTurns:1);
        }
    }
)


Ability.new(
    data: {
        name: 'Proceed with Caution',
        targetMode : TARGET_MODE.ALLALLY,
        description: 'Defense is heightened for the team for 10 turns.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            user.addEffect(from:user, name: 'Proceed with Caution', durationTurns:10);
        }
    }
)

Ability.new(
    data: {
        name: 'Retaliate',
        targetMode : TARGET_MODE.ALLALLY,
        description: 'The user retaliates to attacks.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            user.addEffect(from:user, name: 'Retaliate', durationTurns:10);
        }
    }
)

Ability.new(
    data: {
        name: 'Defensive Stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that sacrifices offensive capabilities to boost defense.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Effect = import(module:'game_class.effect.mt');
            @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            user.removeEffects(effectBases:stances);
            user.addEffect(from:user, name: 'Defensive Stance', durationTurns:1000);
        }
    }
)           

Ability.new(
    data: {
        name: 'Offensive Stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that sacrifices defensive capabilities to boost offense.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Effect = import(module:'game_class.effect.mt');
            @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            user.removeEffects(effectBases:stances);
            user.addEffect(from:user, name: 'Offsensive Stance', durationTurns:1000);
        }
    }
)            

Ability.new(
    data: {
        name: 'Light Stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that makes the user lighter on their feet at the cost of offense.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Effect = import(module:'game_class.effect.mt');
            @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            user.removeEffects(effectBases:stances);
            user.addEffect(from:user, name: 'Light Stance', durationTurns:1000);
        }
    }
)            

Ability.new(
    data: {
        name: 'Heavy Stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that makes the user sturdier at the cost of speed.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Effect = import(module:'game_class.effect.mt');
            @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            user.removeEffects(effectBases:stances);
            user.addEffect(from:user, name: 'Heavy Stance', durationTurns:1000);
        }
    }
) 

Ability.new(
    data: {
        name: 'Meditative Stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that makes the user more mentally focused.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Effect = import(module:'game_class.effect.mt');
            @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            user.removeEffects(effectBases:stances);
            user.addEffect(from:user, name: 'Meditative Stance', durationTurns:1000);
        }
    }
)                 

Ability.new(
    data: {
        name: 'Striking Stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that focuses offense above all.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Effect = import(module:'game_class.effect.mt');
            @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            user.removeEffects(effectBases:stances);
            user.addEffect(from:user, name: 'Striking Stance', durationTurns:1000);
        }
    }
)  


Ability.new(
    data: {
        name: 'Reflective Stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that allows the user to reflect damage.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Effect = import(module:'game_class.effect.mt');
            @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            user.removeEffects(effectBases:stances);
            user.addEffect(from:user, name: 'Reflective Stance', durationTurns:1000);
        }
    }
) 

Ability.new(
    data: {
        name: 'Evasive Stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that allows the user to dodge incoming attacks.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Effect = import(module:'game_class.effect.mt');
            @:stances = Effect.database.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            user.removeEffects(effectBases:stances);
            user.addEffect(from:user, name: 'Evasive Stance', durationTurns:1000);
        }
    }
)                            

Ability.new(
    data: {
        name: 'Wait',
        targetMode : TARGET_MODE.NONE,
        description: 'Does nothing.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:'' + user.name + ' waits.');
        }
    }
)


Ability.new(
    data: {
        name: 'Plant Poisonroot',
        targetMode : TARGET_MODE.ONE,
        description: "Plants a poisonroot seed on the target. Grows in 4 turns and causes poison damage every turn when grown.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:targets[0].name + ' was covered in poisonroot seeds!');
            targets[0].addEffect(from:user, name:'Poisonroot Growing', durationTurns:4);                            
        }
    }
)

Ability.new(
    data: {
        name: 'Plant Triproot',
        targetMode : TARGET_MODE.ONE,
        description: "Plants a triproot seed on the target. Grows in 4 turns and causes 40% chance to trip every turn when grown.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:targets[0].name + ' was covered in triproot seeds!');
            targets[0].addEffect(from:user, name:'Triproot Growing', durationTurns:4);                            
        }
    }
)

Ability.new(
    data: {
        name: 'Plant Healroot',
        targetMode : TARGET_MODE.ONE,
        description: "Plants a healroot seed on the target. Grows in 4 turns and heals 5% HP turn.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI: USAGE_HINT.HEAL,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:targets[0].name + ' was covered in triproot seeds!');
            targets[0].addEffect(from:user, name:'Healroot Growing', durationTurns:4);                            
        }
    }
)


Ability.new(
    data: {
        name: 'Green Thumb',
        targetMode : TARGET_MODE.NONE,
        description: "Any growing roots grow instantly on the target.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:effects = targets[0].effects;
            @:toRemove = [];
            foreach(effects)::(i, effect) {
                if (effect.name == 'Healroot Growing' ||
                    effect.name == 'Triproot Growing' ||
                    effect.name == 'Poisonroot Growing')
                    toRemove->push(value:effect.base);
            }
            
            when(toRemove->keycount == 0)
                windowEvent.queueMessage(text:'Nothing happened!');
            targets[0].removeEffects(effectBases:toRemove);
            windowEvent.queueMessage(text:user.name + ' accelerated the growth of the seeds on ' + targets[0].name + '!');
        }
    }
)


Ability.new(
    data: {
        name: 'Fire Shift',
        targetMode : TARGET_MODE.NONE,
        description: "Adds the Burning effect.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:user.name + ' becomes shrouded in flame!');
            user.addEffect(from:user, name:'Burning', durationTurns:20);                            
        }
    }
)


Ability.new(
    data: {
        name: 'Elemental Tag',
        targetMode : TARGET_MODE.ONE,
        description: "Adds weakness to elemental damage +100%.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:targets[0].name + ' becomes weak to elemental damage!');
            user.addEffect(from:user, name:'Elemental Tag', durationTurns:20);                            
        }
    }
)


Ability.new(
    data: {
        name: 'Elemental Shield',
        targetMode : TARGET_MODE.NONE,
        description: "Nullifies most Thunder, Fire, and Ice damage.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:user.name + ' becomes shielded to elemental damage!');
            user.addEffect(from:user, name:'Elemental Shield', durationTurns:20);                            
        }
    }
)



Ability.new(
    data: {
        name: 'Ice Shift',
        targetMode : TARGET_MODE.NONE,
        description: "Adds the Icy effect.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:user.name + ' becomes shrouded in an icy wind!');
            user.addEffect(from:user, name:'Icy', durationTurns:20);                            
        }
    }
)

Ability.new(
    data: {
        name: 'Thunder Shift',
        targetMode : TARGET_MODE.NONE,
        description: "Adds the Shock effect.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:user.name + ' becomes shrouded in electric arcs!');
            user.addEffect(from:user, name:'Shock', durationTurns:20);                            
        }
    }
)

Ability.new(
    data: {
        name: 'Tri Shift',
        targetMode : TARGET_MODE.NONE,
        description: "Adds the Shock, Burning, and Icy effects.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 3,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:user.name + ' becomes shrouded in light');
            user.addEffect(from:user, name:'Burning', durationTurns:20);                            
            user.addEffect(from:user, name:'Icy',     durationTurns:20);                            
            user.addEffect(from:user, name:'Shock',   durationTurns:20);                            
        }
    }
)


Ability.new(
    data: {
        name: 'Use Item',
        targetMode : TARGET_MODE.ONE,
        description: "Uses an item from the user's inventory.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI: USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:item = extraData[0];
            foreach(item.base.useEffects)::(index, effect) {    
                foreach(targets)::(t, target) {
                    target.addEffect(from:user, name:effect, item:item, durationTurns:0);                            
                }
            }
        }
    }
)        

Ability.new(
    data: {
        name: 'Quickhand Item',
        targetMode : TARGET_MODE.ONE,
        description: "Uses 2 items from the user's inventory.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI: USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @item = extraData[0];
            foreach(item.base.useEffects)::(index, effect) {    
                foreach(targets)::(t, target) {
                    target.addEffect(from:user, name:effect, item:item, durationTurns:0);                            
                }
            }

            item = extraData[1];
            foreach(item.base.useEffects)::(index, effect) {    
                foreach(targets)::(t, target) {
                    target.addEffect(from:user, name:effect, item:item, durationTurns:0);                            
                }
            }
        }
    }
)


Ability.new(
    data: {
        name: 'Equip Item',
        targetMode : TARGET_MODE.ONE,
        description: "Equips an item from the user's inventory.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI: USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:item = extraData[0];
            user.equip(
                item, 
                slot:user.getSlotsForItem(item)[0], 
                inventory:extraData[1]
            );
        }
    }
)

Ability.new(
    data: {
        name: 'Defend Other',
        targetMode : TARGET_MODE.ONE,
        description: "Defends another from getting attacked",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            targets[0].addEffect(
                from:user, name: 'Defend Other', durationTurns: 4 
            );
        }
    }
)

Ability.new(
    data: {
        name: 'Perfect Guard',
        targetMode : TARGET_MODE.ONE,
        description: "Nullifies damage for 3 turns",
        durationTurns: 0,
        hpCost : 0,
        apCost : 2,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            targets[0].addEffect(
                from:user, name: 'Perfect Guard', durationTurns: 3 
            );
        }
    }
)

Ability.new(
    data: {
        name: 'Sharpen',
        targetMode : TARGET_MODE.ONE,
        description: "Sharpens a weapon, increasing its damage for the battle.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Entity = import(module:'game_class.entity.mt');
            when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR).base.name == 'None')
                windowEvent.queueMessage(text:targets[0].name + ' has no weapon to sharpen!');                    


            windowEvent.queueMessage(text:user.name + ' sharpens ' + targets[0].name + '\'s weapon!');

            targets[0].addEffect(
                from:user, name: 'Sharpen', durationTurns: 1000000 
            );
            
        }
    }
)

Ability.new(
    data: {
        name: 'Weaken Armor',
        targetMode : TARGET_MODE.ONE,
        description: "Weakens armor, decreasing its effectiveness for the battle.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Entity = import(module:'game_class.entity.mt');
            when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.ARMOR).base.name == 'None')
                windowEvent.queueMessage(text:targets[0] + ' has no armor to weaken!');                    


            windowEvent.queueMessage(text:user.name + ' weakens ' + targets[0].name + '\'s armor!');

            targets[0].addEffect(
                from:user, name: 'Weaken Armor', durationTurns: 1000000 
            );
            
        }
    }
)

Ability.new(
    data: {
        name: 'Dull Weapon',
        targetMode : TARGET_MODE.ONE,
        description: "Dull a weapon, decreasing its damage for next turn.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Entity = import(module:'game_class.entity.mt');
            when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR).base.name == 'None')
                windowEvent.queueMessage(text:targets[0] + ' has no weapon to dull!');                    


            windowEvent.queueMessage(text:user.name + ' dulls ' + targets[0].name + '\'s weapon!');

            targets[0].addEffect(
                from:user, name: 'Dull Weapon', durationTurns: 1000000 
            );
            
        }
    }
)

Ability.new(
    data: {
        name: 'Strengthen Armor',
        targetMode : TARGET_MODE.ONE,
        description: "Strengthens armor, increasing its effectiveness for the battle",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:Entity = import(module:'game_class.entity.mt');
            when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.ARMOR).base.name == 'None')
                windowEvent.queueMessage(text:targets[0] + ' has no armor to strengthen!');                    


            windowEvent.queueMessage(text:user.name + ' strengthens ' + targets[0].name + '\'s armor!');

            targets[0].addEffect(
                from:user, name: 'Strengthen Armor', durationTurns: 1000000 
            );
            
        }
    }
)

Ability.new(
    data: {
        name: 'Convince',
        targetMode : TARGET_MODE.ONE,
        description: "Prevents a combatant from acting for a few turns if successful.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            windowEvent.queueMessage(text:user.name + ' tries to convince ' + targets[0].name + ' to wait!');
            
            when(Number.random() < 0.5)
                windowEvent.queueMessage(text: targets[0].name + ' ignored ' + user.name + '!');


            windowEvent.queueMessage(text:targets[0].name + ' listens intently!');
            targets[0].addEffect(
                from:user, name: 'Convinced', durationTurns: 1+(Number.random()*3)->floor 
            );
        }
    }
)

Ability.new(
    data: {
        name: 'Pink Brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 1 Ingredient to make a pink potion.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.name == 'Ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make a Pink Brew...');
            when(count < 1)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Pink Potion!');
            inventory.removeByName(name:'Ingredient');
            inventory.add(item:Item.new(base:Item.Base.database.find(name:'Pink Potion'), from:user));                            
        }
    }
)

Ability.new(
    data: {
        name: 'Cyan Brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 1 Ingredient to make a cyan potion.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.name == 'Ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make a Cyan Brew...');
            when(count < 1)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Cyan Potion!');
            inventory.removeByName(name:'Ingredient');
            inventory.add(item:
                Item.new(
                    base:Item.Base.database.find(name:'Cyan Potion'),
                    from:user
                )
            );                            
        }
    }
)


Ability.new(
    data: {
        name: 'Green Brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 1 Ingredient to make a cyan potion.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.name == 'Ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make a Green Brew...');
            when(count < 1)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Green Potion!');
            inventory.removeByName(name:'Ingredient');
            inventory.add(
                item:Item.new(
                    base:Item.Base.database.find(name:'Green Potion'),
                    from:user
            ));                            
        }
    }
)



Ability.new(
    data: {
        name: 'Orange Brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 1 Ingredient to make an orange potion.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.name == 'Ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make an Orange Brew...');
            when(count < 1)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Orange Potion!');
            inventory.removeByName(name:'Ingredient');
            inventory.add(item:
                Item.new(
                    base:Item.Base.database.find(name:'Orange Potion'),
                    from:user
                )
            );                            
        }
    }
)

Ability.new(
    data: {
        name: 'Purple Brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 1 Ingredient to make a purple potion.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.name == 'Ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make a Purple Brew...');
            when(count < 1)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Purple Potion!');
            inventory.removeByName(name:'Ingredient');
            inventory.add(
                item:Item.new(
                    new:Item.Base.database.find(name:'Purple Potion'),
                    from:user
                )
            );                            
        }
    }
)


Ability.new(
    data: {
        name: 'Black Brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 1 Ingredient to make a black potion.',
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.name == 'Ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make a Black Brew...');
            when(count < 1)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Black Potion!');
            inventory.removeByName(name:'Ingredient');
            inventory.add(
                item:Item.new(
                    base:Item.Base.database.find(name:'Black Potion'),
                    from:user
                )
            );                            
        }
    }
)


Ability.new(
    data: {
        name: 'Bribe',
        targetMode : TARGET_MODE.ONE,
        description: "Pays a combatant to not fight any more.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 1,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        onAction: ::(user, targets, turnIndex, extraData) {
            when (user.allies->any(condition:::(value) <- value == targets[0]))
                windowEvent.queueMessage(text: "Are you... trying to bribe me? we're... we're on the same team..");
                
            @:cost = targets[0].level*100 + targets[0].stats.sum * 4;

            @:world = import(module:'game_singleton.world.mt');

            windowEvent.queueMessage(text: user.name + ' tries to bribe ' + targets[0].name + '!');
            
            match(true) {
                // party -> NPC
                (world.party.isMember(entity:user)) ::<= {

                    when (world.party.inventory.gold < cost)
                        windowEvent.queueMessage(text: "The party couldn't afford the " + cost + "G bribe!");

                    world.party.inventory.subtractGold(amount:cost);
                    targets[0].addEffect(
                        from:user, name: 'Bribed', durationTurns: -1
                    );             
                    windowEvent.queueMessage(text: user.name + ' bribes ' + targets[0].name + '!');
                
                },
                
                // NPC -> party
                (world.party.isMember(entity:targets[0])) ::<= {
                    windowEvent.queueMessage(text: user.name + ' has offered ' + cost + 'G for ' + targets[0].name + ' to stop acting for the rest of the battle.');
                    windowEvent.queueAskBoolean(
                        prompt: 'Accept offer for ' + cost + 'G?',
                        onChoice::(which) {
                            when(which == false) empty;

                            windowEvent.queueMessage(text: user.name + ' bribes ' + targets[0].name + '!');
                            targets[0].addEffect(
                                from:user, name: 'Bribed', durationTurns: -1
                            );    
            
                            world.party.inventory.addGold(amount:cost);
                        }
                    );                                              
                },
                
                // NPC -> NPC
                default: ::<={
                    targets[0].addEffect(
                        from:user, name: 'Bribed', durationTurns: -1
                    );                                         
                }
            }
        }
    }
)


return Ability;
