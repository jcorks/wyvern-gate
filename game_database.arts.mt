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

@TARGET_MODE = {
    ONE     : 0,    
    ONEPART : 1,
    ALLALLY : 2,    
    RANDOM  : 3,    
    NONE    : 4,
    ALLENEMY: 5,
    ALL     : 6
}

@USAGE_HINT = {
    OFFENSIVE : 0,
    HEAL    : 1,
    BUFF    : 2,
    DEBUFF  : 3,
    DONTUSE : 4,
} 

@KIND = {
    ABILITY : 0,
    REACTION : 1,
    EFFECT : 2,
}

@RARITY = {
    COMMON : 0,
    UNCOMMON : 1,
    RARE : 2,
    EPIC : 3
}

@:TRAITS = {
    PHYSICAL : 1,
    MAGIC : 2,
    HEAL : 4,
    FIRE : 8,
    ICE : 16,
    THUNDER : 32,
    SUPPORT : 128,
    LIGHT : 256,
    DARK : 512,
    POISON : 1024    
}







@:reset = ::{
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Item = import(module:'game_mutator.item.mt');
@:Damage = import(module:'game_class.damage.mt');
@:random = import(module:'game_singleton.random.mt');
@:StateFlags = import(module:'game_class.stateflags.mt');
@:g = import(module:'game_function.g.mt');
@:Entity = import(module:'game_class.entity.mt');
Arts.newEntry(
    data: {
        name: 'Attack',
        id : 'base:attack',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages a target based on the user's ATK.",
        durationTurns: 0,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' attacks ' + targets[0].name + '!'
            );
            
            windowEvent.queueCustom(
                onEnter :: {
                    user.attack(
                        target:targets[0],
                        amount:user.stats.ATK * (0.5) * level,
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart:targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    );              
                }
            );          
                                    
        }
    }
)




Arts.newEntry(
    data: {
        name: 'Headhunter',
        id : 'base:headhunter',
        targetMode : TARGET_MODE.ONE,
        description: "Deals 1 HP. 5% chance to 1hit K.O. Each level increases the chance by 5%.",
        durationTurns: 0,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.UNCOMMON,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' attempts to defeat ' + targets[0].name + ' in one attack!'
            );
            
            
            windowEvent.queueCustom(
                onEnter :: {

                    if (user.attack(
                        target:targets[0],
                        amount:1,
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: Entity.DAMAGE_TARGET.HEAD,
                        targetDefendPart:targetDefendParts[0]
                    ) == true)
                        if (random.try(percentSuccess:level*5)) ::<= {
                            windowEvent.queueMessage(
                                text: user.name + ' does a connecting blow, finishing off ' + targets[0].name +'!'
                            );                            
                            targets[0].damage(from:user, damage:Damage.new(
                                amount:999999,
                                damageType:Damage.TYPE.PHYS,
                                damageClass:Damage.CLASS.HP
                            ),dodgeable: false);                                
                        }   
                }
            );
                                            
        }       
    }
)





Arts.newEntry(
    data: {
        name: 'Precise Strike',
        id : 'base:precise-strike',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages a target based on the user's ATK and DEX. Additional levels increase the damage by 10%.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        traits : TRAITS.PHYSICAL,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' takes aim at ' + targets[0].name + '!'
            );
            
            windowEvent.queueCustom(
                onEnter :: {
                    user.attack(
                        target:targets[0],
                        amount:(user.stats.ATK * (0.2) + user.stats.DEX * (0.5)) * (1 + 0.1*(level-1)),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart:targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    );                        
                }
            );
                                    
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Tranquilizer',
        id : 'base:tranquilizer',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages a target based on the user's DEX with a 45% chance to paralyze. Additional levels increase the paralysis chance by 10%.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' attempts to tranquilize ' + targets[0].name + '!'
            );
            
            windowEvent.queueCustom(
                onEnter :: {
                    if (user.attack(
                        target:targets[0],
                        amount:user.stats.DEX * (0.5),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart:targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    ) == true)                     
                        if (random.try(percentSuccess:40 + level*10))
                            targets[0].addEffect(from:user, id:'base:paralyzed', durationTurns:2);
                }
            );

        }
    }
)



Arts.newEntry(
    data: {
        name: 'Coordination',
        id : 'base:coordination',
        targetMode : TARGET_MODE.ALLALLY,
        description: "ATK,DEF,SPD +35% for each party member. Every 2 levels stacks the boost.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : 0,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' coordinates with others!'
            );
            
            windowEvent.queueCustom(
                onEnter :: {

                    foreach(targets)::(i, ent) {
                        when(ent == user) empty;
                        // skip if already has Coordinated effect.
                        //when(ent.effects->any(condition::(value) <- value.name == user.profession.name)) empty;
                        for(0, (level/2)->floor + 1) ::(i) {
                            targets[0].addEffect(holder:targets[0], from:user, id: 'base:coordinated', durationTurns: 1000000);
                        }
                    }
                }
            );
        }
    }
)            

Arts.newEntry(
    data: {
        name: 'Follow Up',
        id : 'base:follow-up',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages a target based on the user's ATK, doing 150% more damage if the target was hit since their last turn. Additional levels increase the boost by 20%.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' attacks ' + targets[0].name + ' as a follow-up!'
            );

            windowEvent.queueCustom(
                onEnter :: {

                    
                    if (targets[0].flags.has(flag:StateFlags.HURT)) 
                        user.attack(
                            target:targets[0],
                            amount:user.stats.ATK * (1.25 + level*0.2),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP,
                            targetPart:targetParts[0],
                            targetDefendPart:targetDefendParts[0]
                        )
                    else
                        user.attack(
                            target:targets[0],
                            amount:user.stats.ATK * (0.5),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP,
                            targetPart : targetParts[0],
                            targetDefendPart:targetDefendParts[0]
                        );
                }
            );
        }
    }
)            



Arts.newEntry(
    data: {
        name: 'Doublestrike',
        id : 'base:doublestrike',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Damages a target based on the user's strength. Additional levels increase the damage per hit.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' attacks twice!'
            );

            windowEvent.queueCustom(
                onEnter :: {
                    @target = random.pickArrayItem(list:user.enemies);
                    user.attack(
                        target,
                        amount:user.stats.ATK * (0.4 + (level-1)*0.1),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[user.enemies->findIndex(value:target)],
                        targetDefendPart:targetDefendParts[user.enemies->findIndex(value:target)]
                    );
                }
            );

            windowEvent.queueCustom(
                onEnter :: {

                    @target = random.pickArrayItem(list:user.enemies);
                    user.attack(
                        target,
                        amount:user.stats.ATK * (0.4 + (level-1)*0.1),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart : targetParts[user.enemies->findIndex(value:target)],
                        targetDefendPart:targetDefendParts[user.enemies->findIndex(value:target)]
                    );
                }
            );

        }
    }
)



Arts.newEntry(
    data: {
        name: 'Triplestrike',
        id : 'base:triplestrike',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Damages three targets based on the user's strength. Each level increases the amount of damage done.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' attacks three times!'
            );
            
            
            windowEvent.queueCustom(
                onEnter :: {
                    
                    @target = random.pickArrayItem(list:user.enemies);
                    user.attack(
                        target,
                        amount:user.stats.ATK * (0.4 + (level-1)*0.07),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[user.enemies->findIndex(value:target)],
                        targetDefendPart:targetDefendParts[user.enemies->findIndex(value:target)]
                    );
                }
            ); 


            windowEvent.queueCustom(
                onEnter :: {
                    @:target = random.pickArrayItem(list:user.enemies);
                    user.attack(
                        target,
                        amount:user.stats.ATK * (0.4 + (level-1)*0.07),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[user.enemies->findIndex(value:target)],
                        targetDefendPart:targetDefendParts[user.enemies->findIndex(value:target)]
                    );
                }
            );

            windowEvent.queueCustom(
                onEnter :: {
                    @:target = random.pickArrayItem(list:user.enemies);
                    user.attack(
                        target,
                        amount:user.stats.ATK * (0.4 + (level-1)*0.07),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[user.enemies->findIndex(value:target)],
                        targetDefendPart:targetDefendParts[user.enemies->findIndex(value:target)]
                    );
                }
            );
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Focus Perception',
        id : 'base:focus-perception',        
        targetMode : TARGET_MODE.NONE,
        description: "Causes the user to focus on their enemies, making attacks 25% more effective for 5 turns.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:user.name + ' focuses their perception, increasing their ATK temporarily!');
            windowEvent.queueCustom(
                onEnter :: {
                    user.addEffect(from:user, id: 'base:focus-perception', durationTurns: 5);                        
                }
            );
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Cheer',
        id : 'base:cheer',
        targetMode : TARGET_MODE.ALLALLY,
        description: "Cheers, granting a 30% damage bonus to allies for 5 turns.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.COMMON,
        traits : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:user.name + ' cheers for the party!');
            windowEvent.queueCustom(
                onEnter :: {
                    foreach(user.allies)::(index, ally) {
                        ally.addEffect(from:user, id: 'base:cheered', durationTurns: 5);                        
                    }
                }
            )
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Lunar Blessing',
        id : 'base:lunar-blessing',
        targetMode : TARGET_MODE.NONE,
        description: "Puts all of the combatants into stasis until it is night time. Additional levels have no effect.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:user.name + '\'s Lunar Blessing made it night time!');

            @:world = import(module:'game_singleton.world.mt');
            windowEvent.queueCustom(
                onEnter :: {

                    {:::} {
                        forever ::{
                            world.stepTime();
                            if (world.time == world.TIME.EVENING)
                                send();                        
                        }
                    }
                }
            );
            
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Solar Blessing',
        id : 'base:solar-blessing',
        targetMode : TARGET_MODE.NONE,
        description: "Puts all of the combatants into stasis until it is morning. Additional levels have no effect.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        traits : TRAITS.MAGIC,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:user.name + '\'s Solar Blessing made it day time!');
            @:world = import(module:'game_singleton.world.mt');
            windowEvent.queueCustom(
                onEnter :: {

                    {:::} {
                        forever ::{
                            world.stepTime();
                            if (world.time == world.TIME.MORNING)
                                send();                        
                        }
                    }
                }
            );
            
        }
    }
)            


Arts.newEntry(
    data: {
        name: 'Moonbeam',
        id : 'base:moonbeam',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages a target with Fire based on the user's INT. If night time, the damage is boosted. Additional levels boost the damage further.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.FIRE,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' fires a glowing beam of moonlight!'
            );      
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: 'The beam shines brightly!'
                );                                  
            }
            
            
            windowEvent.queueCustom(
                onEnter :: {
                    user.attack(
                        target: targets[0],
                        amount:user.stats.INT * (if (world.time >= world.TIME.EVENING) 1.4 else 0.8) * (1 + (level-1)*0.05),
                        damageType : Damage.TYPE.FIRE,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    );
                }
            );
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Sunbeam',
        id : 'base:sunbeam',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages a target with Fire based on the user's INT. If day time, the damage is boosted.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.FIRE,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' fires a glowing beam of sunlight!'
            );      
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: 'The beam shines brightly!'
                );                                  
            }
            
            
            windowEvent.queueCustom(
                onEnter :: {
                    user.attack(
                        target: targets[0],
                        amount:user.stats.INT * (if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) 1.4 else 0.8) * (1 + (level-1)*0.05),
                        damageType : Damage.TYPE.FIRE,
                        damageClass: Damage.CLASS.HP,
                        targetPart : targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    );
                }
            );

        }
    }
)


Arts.newEntry(
    data: {
        name: 'Sunburst',
        id : 'base:sunburst',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Damages all enemies with Fire based on the user's INT. If day time, the damage is boosted.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        traits : TRAITS.MAGIC | TRAITS.FIRE,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' lets loose a burst of sunlight!'
            );      
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: 'The blast shines brightly!'
                );                                  
            }
            

            
            foreach(user.enemies)::(index, enemy) {
                windowEvent.queueCustom(
                    onEnter :: {

                        user.attack(
                            target: enemy,
                            amount:user.stats.INT * (if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) 1.7 else 0.4) * (1 + (level-1)*.08),
                            damageType : Damage.TYPE.FIRE,
                            damageClass: Damage.CLASS.HP
                        );
                    }
                )
            }

        }
    }
)            

Arts.newEntry(
    data: {
        name: 'Night Veil',
        id : 'base:night-veil',
        targetMode : TARGET_MODE.ONE,
        description: "Increases DEF of target for 5 turns. If casted during night time, it's much more powerful.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.UNCOMMON,
        traits : TRAITS.MAGIC,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Night Veil on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shimmers brightly!'
                );                                  
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:greater-night-veil', durationTurns: 5);
                    }
                );
            } else 
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:night-veil', durationTurns: 5);
                    }
                )
            ;
            
            

        }
    }
)


Arts.newEntry(
    data: {
        name: 'Dayshroud',
        id : 'base:dayshroud',
        targetMode : TARGET_MODE.ONE,
        description: "Increases DEF of target for 5 turns. If casted during day time, it's much more powerful.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.UNCOMMON,
        traits : TRAITS.MAGIC,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Dayshroud on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shines brightly!'
                );                                  
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:greater-dayshroud', durationTurns: 5);
                    }
                )
            } else 
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:dayshroud', durationTurns: 5);
                    }
                )
            ;
            
            

        }
    }
)

Arts.newEntry(
    data: {
        name: 'Call of the Night',
        id : 'base:call-of-the-night',
        targetMode : TARGET_MODE.ONE,
        description: "Increases ATK of target for 5 turns. If casted during night time, it's much more powerful.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.UNCOMMON,
        traits : TRAITS.MAGIC,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Call of the Night on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shimmers brightly!'
                );                                  
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:greater-call-of-the-night', durationTurns: 5);
                    }
                )
            } else 
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:call-of-the-night', durationTurns: 5);
                    }
                )
            ;
            
            

        }
    }
)



Arts.newEntry(
    data: {
        name: 'Lunacy',
        id : 'base:lunacy',
        targetMode : TARGET_MODE.ONE,
        description: "Causes the target to go berserk and attack random enemies for their turns. DEF, ATK +70%. Only can be casted at night.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.RARE,
        traits : TRAITS.MAGIC,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Lunacy on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shimmers brightly!'
                );                                  
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:lunacy', durationTurns: 7);
                    }
                )

            } else 
                windowEvent.queueMessage(text:'....But nothing happens!');
            ;
            
            

        }
    }
)

Arts.newEntry(
    data: {
        name: 'Moonsong',
        id : 'base:moonsong',
        targetMode : TARGET_MODE.ONE,
        description: "Heals over time. If casted during night time, it's much more powerful.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.UNCOMMON,
        traits : TRAITS.MAGIC,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Moonsong on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shimmers brightly!'
                );                                  
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:greater-moonsong', durationTurns: 8);
                    }
                )

            } else 
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:moonsong', durationTurns: 3);
                    }
                )
            ;
            
            

        }
    }
)

Arts.newEntry(
    data: {
        name: 'Sol Attunement',
        id : 'base:sol-attunement',
        targetMode : TARGET_MODE.ONE,
        description: "Heals over time. If casted during day time, it's much more powerful.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.UNCOMMON,
        traits : TRAITS.MAGIC,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Sol Attunement on ' + targets[0].name + '!'
            );
            
            @:world = import(module:'game_singleton.world.mt');
            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' shines brightly!'
                );                                  
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:greater-sol-attunement', durationTurns: 3);
                    }
                );

            } else 
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:sol-attunement', durationTurns: 3);
                    }
                );
            ;
            
            

        }
    }
)

Arts.newEntry(
    data: {
        name: 'Ensnare',
        id : 'base:ensnare',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target and immobilizes both the user and the target for 3 turns. 80% success rate. Damage done increases with additional levels.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        rarity : RARITY.UNCOMMON,
        traits : TRAITS.PHYSICAL,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' tries to ensnare ' + targets[0].name + '!'
            );
            
            
            
            windowEvent.queueCustom(
                onEnter :: {
                    if (user.attack(
                        target:targets[0],
                        amount:user.stats.ATK * (0.3 + (level-1)*0.05),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: Entity.DAMAGE_TARGET.BODY,
                        targetDefendPart:targetDefendParts[0]
                    ) == true)                        
                        if (random.try(percentSuccess:80)) ::<= {
                            targets[0].addEffect(from:user, id: 'base:ensnared', durationTurns: 3);                        
                            user.addEffect(from:user, id: 'base:ensnaring', durationTurns: 3);                        
                        }
                }
            );
                
        }
    }
) 


Arts.newEntry(
    data: {
        name: 'Call',
        id : 'base:call',
        targetMode : TARGET_MODE.NONE,
        description: "Calls a creature to come and join the fight. Additional levels increase chances of success.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : 0,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' makes an eerie call!'
            );
            
            if (random.try(percentSuccess:50+(level-1)*10)) ::<= {
                @:instance = import(module:'game_singleton.instance.mt');
            
                @help = instance.island.newHostileCreature();
                @battle = user.battle;
                
                windowEvent.queueCustom(
                    onEnter :: {

                        battle.join(
                            group: [help],
                            sameGroupAs:user
                        );
                    }
                )
                
            } else ::<= {
                windowEvent.queueMessage(
                    text: '...but nothing happened!'
                );                        
            }
                                        
        }
    }
) 



Arts.newEntry(
    data: {
        name: 'Tame',
        id : 'base:tame',
        targetMode : TARGET_MODE.ONE,
        description: "Attempts to tame a creature, making it a party member if successful. Additional levels increase chances of success.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : 0,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
                windowEvent.queueCustom(
                    onEnter :: {
                        party.add(member:targets[0]);
                    }
                );
            } else ::<= {
                windowEvent.queueMessage(
                    text: '...but ' + targets[0].name + ' continued to be untamed!'
                );                        
            }
                                        
        }
    }
) 

Arts.newEntry(
    data: {
        name: 'Leg Sweep',
        id : 'base:leg-sweep',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Swings, aiming for all enemies legs in hopes of stunning them.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' tries to sweep everyone\'s legs!'
            );
            foreach(user.enemies)::(i, enemy) {
                windowEvent.queueCustom(
                    onEnter :: {

                        if (user.attack(
                            target:enemy,
                            amount:user.stats.ATK * (0.3),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP,
                            targetPart:Entity.DAMAGE_TARGET.LIMBS,
                            targetDefendPart:targetDefendParts[i]
                        ) == true)
                            if (Number.random() > 0.5)
                                enemy.addEffect(from:user, id: 'base:stunned', durationTurns: 1);    
                    }
                );
            }
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Big Swing',
        id : 'base:big-swing',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Damages targets based on the user's strength. Additional levels increase the power.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' does a big swing!'
            );      
            foreach(targets)::(index, target) {
                windowEvent.queueCustom(
                    onEnter :: {
                        user.attack(
                            target,
                            amount:user.stats.ATK * (0.35) * (1 + (level-1)*.05),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP,
                            targetPart: Entity.DAMAGE_TARGET.BODY,
                            targetDefendPart:targetDefendParts[index]
                        );
                    }
                )
            }
        }
    }
)



Arts.newEntry(
    data: {
        name: 'Tackle',
        id : 'base:tackle',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's strength. Has a chance to immobolize the user and the target. Additional levels increase the power.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' bashes ' + targets[0].name + '!'
            );

            windowEvent.queueCustom(
                onEnter :: {

                    user.attack(
                        target:targets[0],
                        amount:user.stats.ATK * (0.7) * (1 + (level-1)*0.1),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: Entity.DAMAGE_TARGET.BODY,
                        targetDefendPart:targetDefendParts[0]
                    );
                    if (random.try(percentSuccess:60)) ::<= {
                        targets[0].addEffect(from:user, id: 'base:grappled', durationTurns: 1);                        
                        user.addEffect(from:user, id: 'base:grappling', durationTurns: 1);                        
                    }
                }
            );
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Throw Item',
        id : 'base:throw-item',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages a target by throwing an item. Additional levels increase the damage done.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        rarity : RARITY.UNCOMMON,
        canBlock : true,
        traits : TRAITS.PHYSICAL,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:pickItem = import(module:'game_function.pickitem.mt');
            @:world = import(module:'game_singleton.world.mt');
            
            @:item = pickItem(inventory:world.party.inventory, canCancel:false, keep:false);
        
            windowEvent.queueMessage(
                text: user.name + ' throws a ' + item.name + ' at ' + targets[0].name + '!'
            );
            

            windowEvent.queueCustom(
                onEnter :: {
                    user.attack(
                        target:targets[0],                            
                        from: user,
                        amount:user.stats.ATK * (0.7) * (item.base.weight * 4) * (1 + (level-1)*0.2),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    );
                }
            );
        }
    }
)



Arts.newEntry(
    data: {
        name: 'Stun',
        id : 'base:stun',
        targetMode : TARGET_MODE.ONE,
        description: "Damages a target based on the user's strength with a chance to stun. Further levels increase the stun chance.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' tries to stun ' + targets[0].name + '!'
            );

            windowEvent.queueCustom(
                onEnter :: {
                    
                    if (user.attack(
                        target:targets[0],
                        amount:user.stats.ATK * (0.3),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: Entity.DAMAGE_TARGET.BODY,
                        targetDefendPart:targetDefendParts[0]
                    ) == true)       
                        if (random.try(percentSuccess:50 + (level-1)*10))
                            targets[0].addEffect(from:user, id: 'base:stunned', durationTurns: 1);                        

                }
            );                
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Sheer Cold',
        id : 'base:sheer-cold',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages a target with an ice attack. 90% chance to freeze. Additional levels increase its power.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.ICE,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: 'A cold air emminates from ' + user.name + '!'
            );

            windowEvent.queueCustom(
                onEnter :: {

                    if (user.attack(
                        target:targets[0],
                        amount:user.stats.ATK * (0.4) * (1 + (level-1)*0.07),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    ) == true)                    
                        if (Number.random() < 0.9)
                            targets[0].addEffect(from:user, id: 'base:frozen', durationTurns: 1);                        
                }
            );                
        }
    }
)

/*
Arts.newEntry(
    data: {
        name: 'Mind Read',
        id : 'base:mind-read',
        targetMode : TARGET_MODE.ONE,
        description: 'Uses a random offensive ability of the target\'s',
        durationTurns: 0,
        kind : KIND.ABILITY,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
*/ 
Arts.newEntry(
    data: {
        name: 'Flight',
        id : 'base:flight',
        targetMode : TARGET_MODE.ONE,
        description: "Causes the target to fly, making all damage miss the target for 3 turns. The effect lasts an additional turn for each level.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Flight on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id: 'base:flight', durationTurns: 2+level);
                }
            )
        }
    }
)         
Arts.newEntry(
    data: {
        name: 'Grapple',
        id : 'base:grapple',
        targetMode : TARGET_MODE.ONE,
        description: "Immobilizes both the user and the target for 3 turns. 70% success rate. Each level increases the success rate by 5%",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' tries to grapple ' + targets[0].name + '!'
            );
            
            windowEvent.queueCustom(
                onEnter :: {

                    if (random.try(percentSuccess:65 + level*5)) ::<= {
                        targets[0].addEffect(from:user, id: 'base:grappled', durationTurns: 3);                        
                        user.addEffect(from:user, id: 'base:grappling', durationTurns: 3);                        
                    }
                }
            );
                
        }
    }
)            


Arts.newEntry(
    data: {
        name: 'Combo Strike',
        id : 'base:combo-strike',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages the same target twice at the same target and location. Additional levels increases the power.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' does a combo strike on ' + targets[0].name + '!'
            );
            
            windowEvent.queueCustom(
                onEnter :: {
                    
                    user.attack(
                        target: targets[0],
                        amount:user.stats.ATK * (0.35) * (1 + (level-1)*0.05),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    );
                }
            );

            windowEvent.queueCustom(
                onEnter :: {
                    user.attack(
                        target: targets[0],
                        amount:user.stats.ATK * (0.35) * (1 + (level-1)*0.05),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    );
                }
            );
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Poison Rune',
        id : 'base:poison-rune',
        targetMode : TARGET_MODE.ONE,
        description: "Places a poison rune on a target, which causes damage to the target each turn.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Poison Rune on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id: 'base:poison-rune', durationTurns: 10);                        
                }
            );
        }
    }
)            
Arts.newEntry(
    data: {
        name: 'Rune Release',
        id : 'base:rune-release',
        targetMode : TARGET_MODE.ONE,
        description: "Release all runes.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' releases all the runes on ' + targets[0].name + '!'
            );

            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].removeEffects(
                        :[
                            'base:poison-rune',
                            'base:destruction-rune',
                            'base:regeneration-rune',
                            'base:cure-rune',
                            'base:Shield Rune'                             
                        ]
                    );
                }
            );                     
        }
    }
)            
Arts.newEntry(
    data: {
        name: 'Destruction Rune',
        id : 'base:destruction-rune',
        targetMode : TARGET_MODE.ONE,
        description: "Places a destruction rune on a target, which causes INT-based damaged upon release.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Destruction Rune on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id: 'base:destruction-rune', durationTurns: 10);                        
                }
            );
        }
    }
)       


Arts.newEntry(
    data: {
        name: 'Regeneration Rune',
        id : 'base:regeneration-rune',
        targetMode : TARGET_MODE.ONE,
        description: "Places a regeneration rune on a target, which slightly heals a target every turn.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.UNCOMMON,
        traits : TRAITS.MAGIC,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Regeneration Rune on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id: 'base:regeneration-rune', durationTurns: 10);                        
                }
            );
        }
    }
)
Arts.newEntry(
    data: {
        name: 'Shield Rune',
        id : 'base:shield-rune',
        targetMode : TARGET_MODE.ONE,
        description: "Places a shield rune on a target, which gives +100% DEF while active.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Shield Rune on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id: 'base:shield-rune', durationTurns: 10);                        
                }
            )
        }
    }
)  
Arts.newEntry(
    data: {
        name: 'Cure Rune',
        id : 'base:cure-rune',
        targetMode : TARGET_MODE.ONE,
        description: "Places a cure rune on a target, which heals the target when the rune is released.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Cure Rune on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id: 'base:cure-rune', durationTurns: 10);                        
                }
            )
        }
    }
)             

Arts.newEntry(
    data: {
        name: 'Multiply Runes',
        id : 'base:multiply-runes',
        targetMode : TARGET_MODE.ONE,
        description: "Doubles all current runes on a target.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Multiply Runes on ' + targets[0].name + '!'
            );
            
            @:effects = targets[0].effectStack.getAll()->filter(by:::(value) <- 
                match(value.id) {
                  (
                    'base:poison-rune',
                    'base:destruction-rune',
                    'base:regeneration-rune',
                    'base:cure-rune',
                    'base:shield-rune'                             
                  ): true,
                  default: false
                }
            );

            windowEvent.queueCustom(
                onEnter :: {
                    foreach(effects)::(i, effect) {
                        targets[0].addEffect(from:user, id:effect.id, durationTurns:10);
                    }
                }
            )
        }
    }
)  

                 
Arts.newEntry(
    data: {
        name: 'Poison Attack',
        id : 'base:poison-attack',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages a target based on the user's ATK with a poisoned weapon. Additional levels increase the damage done.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL | TRAITS.POISON,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' prepares a poison attack against ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {

                    if (user.attack(
                        target: targets[0],
                        amount:user.stats.ATK * (0.3) * (1 + (level-1)*0.05),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    ))
                        targets[0].addEffect(from:user, id: 'base:poisoned', durationTurns: 4);                       
                }
            );
                 
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Petrify',
        id : 'base:petrify',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages a target based on the user's ATK with special Light energy, causing petrification. Additional levels increase the power of the move.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL | TRAITS.LIGHT,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' prepares a petrifying attack against ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {

                    if (user.attack(
                        target: targets[0],
                        amount:user.stats.ATK * (0.3) * (1 + (level-1)*0.05),
                        damageType : Damage.TYPE.LIGHT,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    ))
                        targets[0].addEffect(from:user, id: 'base:petrified', durationTurns: 2);  
                }
            )                      
        }
    }
)            
Arts.newEntry(
    data: {
        name: 'Tripwire',
        id : 'base:tripwire',
        targetMode : TARGET_MODE.ONE,
        description: "Activates a tripwire set up prior to battle, causing the target to be stunned for 3 turns. Only works once per battle.",
        durationTurns: 0,
        kind : KIND.REACTION,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.UNCOMMON,
        canBlock : false,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' activates the tripwire right under ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id: 'base:stunned', durationTurns: 2);                        
                }
            );
            return true;
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Trip Explosive',
        id : 'base:trip-explosive',
        targetMode : TARGET_MODE.ONE,
        description: "Activates a tripwire-activated explosive set up prior to battle, causing the target to be damaged. Only works once per battle.",
        durationTurns: 0,
        kind : KIND.REACTION,
        rarity : RARITY.RARE,
        traits : TRAITS.PHYSICAL,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : true,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' activates the tripwire explosive right under ' + targets[0].name + '!'
            );
            when(random.try(percentSuccess:70)) ::<= {
                windowEvent.queueMessage(
                    text: targets[0].name + ' avoided the trap!'
                );       
                return false;
                         
            }
            windowEvent.queueCustom(
                onEnter :: {

                    targets[0].damage(from:user, damage:Damage.new(
                        amount:50,
                        damageType:Damage.TYPE.FIRE,
                        damageClass:Damage.CLASS.HP
                    ),dodgeable: false);  
                }
            );
            return true;
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Spike Pit',
        id : 'base:spike-pit',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Activates a floor trap leading to a spike pit. Only works once per battle.",
        durationTurns: 0,
        kind : KIND.REACTION,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : true,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' activates a floor trap, revealing a spike pit under the enemies!'
            );
            
            foreach(targets)::(i, target) {
                windowEvent.queueCustom(
                    onEnter :: {

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
                        target.addEffect(from:user, id: 'base:stunned', durationTurns: 2);                        
                    }
                );
            }
        }
    }
)            

Arts.newEntry(
    data: {
        name: 'Stab',
        id : 'base:stab',
        targetMode : TARGET_MODE.ONEPART,
        description: "Damages a target based on the user's ATK and causes bleeding. Additional levels increases the power of the move.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' stabs ' + targets[0].name + '!'
            );

            windowEvent.queueCustom(
                onEnter :: {
                    if (user.attack(
                        target: targets[0],
                        amount:user.stats.ATK * (0.3) * (1 + (level-1)*0.07),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart: targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    ) == true)
                        targets[0].addEffect(from:user, id: 'base:bleeding', durationTurns: 4);                        
                }
            );
        }
    }
)

Arts.newEntry(
    data: {
        name: 'First Aid',
        id : 'base:first-aid',
        targetMode : TARGET_MODE.ONE,
        description: "Heals a target by a small amount. Additional levels increase the potency.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.HEAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' does first aid on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].heal(amount:((targets[0].stats.HP*(0.15 + (level-1)*0.07))->ceil));
                }
            )
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Mend',
        id : 'base:mend',
        targetMode : TARGET_MODE.ONE,
        description: "Heals a target by a small amount.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.HEAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' mends ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].heal(amount:((targets[0].stats.HP*0.25)->ceil));
                }
            );
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Give Snack',
        id : 'base:give-snack',
        targetMode : TARGET_MODE.ONE,
        description: "Heals a target by a small amount.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.HEAL,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' gives a snack to ' + targets[0].name + '!'
            );
                
            @:chance = Number.random();
            match(true) {
              (chance > 0.9) ::<= {        
                windowEvent.queueMessage(text: 'The snack tastes fruity!');
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].healAP(amount:((targets[0].stats.AP*0.15)->ceil));                         
                    }
                ) 
              },

              (chance > 0.8) ::<= {        
                windowEvent.queueMessage(text: 'The snack tastes questionable...');
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].heal(
                            amount:(1)
                        );      
                    }
                )                    
              },

              default: ::<= {
                windowEvent.queueMessage(text: 'The snack tastes great!');
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].heal(
                            amount:((targets[0].stats.HP*0.15)->ceil) 
                        );                          
                    }
                )
              }
              

            }
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Summon: Fire Sprite',
        id : 'base:summon-fire-sprite',
        targetMode : TARGET_MODE.NONE,
        description: 'Summons a fire sprite to fight on your side. Additional levels makes the summoning stronger.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
            @:Species = import(module:'game_database.species.mt');
            @:sprite = Entity.new(
                island : world.island,
                speciesHint: 'base:fire-sprite',
                professionHint: 'base:fire-sprite',
                levelHint:4 + level
            );
            sprite.name = 'the Fire Sprite';
                        
            @:battle = user.battle;

            windowEvent.queueCustom(
                onEnter :: {

                    battle.join(
                        group: [sprite],
                        sameGroupAs:user
                    );
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Summon: Ice Elemental',
        id : 'base:summon-ice-elemental',
        targetMode : TARGET_MODE.NONE,
        description: 'Summons an ice elemental to fight on your side.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
            @:Species = import(module:'game_database.species.mt');
            @:world = import(module:'game_singleton.world.mt');
            @:sprite = Entity.new(
                island: world.island,
                speciesHint: 'base:ice-elemental',
                professionHint: 'base:ice-elemental',
                levelHint:4 + level
            );
            sprite.name = 'the Ice Elemental';
            
            
            @:battle = user.battle;
            windowEvent.queueCustom(
                onEnter :: {
                    battle.join(
                        group: [sprite],
                        sameGroupAs:user
                    );
                }
            )
        }
    }
)            

Arts.newEntry(
    data: {
        name: 'Summon: Thunder Spawn',
        id : 'base:summon-thunder-spawn',
        targetMode : TARGET_MODE.NONE,
        description: 'Summons a thunder spawn to fight on your side.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
            @:Species = import(module:'game_database.species.mt');
            @:world = import(module:'game_singleton.world.mt');
            @:sprite = Entity.new(
                island: world.island,
                speciesHint: 'base:thunder-spawn',
                professionHint: 'base:thunder-spawn',
                levelHint:4 + level
            );
            sprite.name = 'the Thunder Spawn';
            
            
            @:battle = user.battle;
            windowEvent.queueCustom(
                onEnter :: {
                    battle.join(
                        group: [sprite],
                        sameGroupAs:user
                    );
                }
            )

        }
    }
)       

Arts.newEntry(
    data: {
        name: 'Summon: Guiding Light',
        id : 'base:summon-guiding-light',
        targetMode : TARGET_MODE.NONE,
        description: 'Summons a guiding light to fight on your side.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC,
        rarity : RARITY.EPIC,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
            @:Species = import(module:'game_database.species.mt');
            @:world = import(module:'game_singleton.world.mt');
            @:sprite = Entity.new(
                island: world.island,
                speciesHint: 'base:guiding-light',
                professionHint: 'base:guiding-light',
                levelHint:6 + level
            );
            sprite.name = 'the Guiding Light';
            
            
            @:battle = user.battle;
            windowEvent.queueCustom(
                onEnter :: {
                    battle.join(
                        group: [sprite],
                        sameGroupAs:user
                    );
                }
            )
        }
    }
)                   

Arts.newEntry(
    data: {
        name: 'Unsummon',
        id : 'base:unsummon',
        targetMode : TARGET_MODE.ONE,
        description: 'Magick that removes a summoned entity.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Unsummon on ' + targets[0].name + '!'
            );

            windowEvent.queueCustom(
                onEnter :: {

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
            )
        }
    }
)                        

Arts.newEntry(
    data: {
        name: 'Fire',
        id : 'base:fire',
        targetMode : TARGET_MODE.ONE,
        description: 'Magick that damages a target with fire based on INT. Additional levels increase its potency.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.FIRE,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Fire on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    user.attack(
                        target:targets[0],
                        amount:user.stats.INT * (1.2) * (1 + (level-1)*0.15),
                        damageType : Damage.TYPE.FIRE,
                        damageClass: Damage.CLASS.HP
                    );
                }
            );
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Backdraft',
        id : 'base:backdraft',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Using great amount of heat, gives targets burns. Damage is based on INT. Additional levels increases the potency.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.FIRE,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' generates a great amount of heat!'
            );
            
            foreach(targets)::(i, target) {
                windowEvent.queueCustom(
                    onEnter :: {
                        if (user.attack(
                            target:target,
                            amount:user.stats.INT * (0.6) * (1 + (level-1)*0.08),
                            damageType : Damage.TYPE.FIRE,
                            damageClass: Damage.CLASS.HP
                        ))
                            targets[0].addEffect(from:user, id:'base:burned', durationTurns:5);
                    }
                );
            }
        }
    }
)




Arts.newEntry(
    data: {
        name: 'Flare',
        id : 'base:flare',
        targetMode : TARGET_MODE.ONE,
        description: 'Magick that greatly damages a target with fire based on INT. Additional levels increase the destructive power.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.FIRE,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Flare on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    user.attack(
                        target:targets[0],
                        amount:user.stats.INT * (2.0) * (1 + (level-1) * 0.15),
                        damageType : Damage.TYPE.FIRE,
                        damageClass: Damage.CLASS.HP
                    );
                }
            )
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Dematerialize',
        id : 'base:dematerialize',
        targetMode : TARGET_MODE.ONE,
        description: 'Magick that unequips a target\'s equipment',
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.RARE,
        traits : TRAITS.MAGIC,
        usageHintAI : USAGE_HINT.OFFENSIVE,	
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
            when (item == empty)
                windowEvent.queueMessage(
                    text: targets[0].name + ' had nothing to unequip!'
                );

            windowEvent.queueCustom(
                onEnter :: {
            
                    targets[0].unequipItem(item);
                }
            );
            windowEvent.queueMessage(
                text: targets[0].name + '\'s ' + item.name + ' gets unequipped!'
            );
        }
    }
)



Arts.newEntry(
    data: {
        name: 'Ice',
        id : 'base:ice',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Magick that damages all enemies with Ice based on INT.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.ICE,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Ice!'
            );
            foreach(user.enemies)::(index, enemy) {
                windowEvent.queueCustom(
                    onEnter :: {

                        user.attack(
                            target:enemy,
                            amount:user.stats.INT * (0.8 + (0.2)*(level-1)),
                            damageType : Damage.TYPE.ICE,
                            damageClass: Damage.CLASS.HP
                        );
                    }
                )
            }
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Frozen Flame',
        id : 'base:frozen-flame',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Magick that causes enemies to spontaneously combust in a cold, blue flame. Damage is based on INT, and it might freeze the targets. Additional levels increase damage.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.ICE,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Frozen Flame!'
            );
            foreach(user.enemies)::(index, enemy) {
                windowEvent.queueCustom(
                    onEnter :: {
                        user.attack(
                            target:enemy,
                            amount:user.stats.INT * (0.75) * (1 + (level-1)* 0.15),
                            damageType : Damage.TYPE.ICE,
                            damageClass: Damage.CLASS.HP
                        );
                    }
                )
            }


        }
    }
)            


Arts.newEntry(
    data: {
        name: 'Telekinesis',
        id : 'base:telekinesis',
        targetMode : TARGET_MODE.ONE,
        description: 'Magick that moves a target around, stunning them 50% of the time. Stunning chance increases with levels.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Telekinesis!'
            );
            if (random.try(percentSuccess:40 + level*10))
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:stunned', durationTurns: 1)                       
                    }
                )
            else 
                windowEvent.queueMessage(
                    text: '...but it missed!'
                );

        }
    }
)          


Arts.newEntry(
    data: {
        name: 'Explosion',
        id : 'base:explosion',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Magick that damages all enemies with fire based on the user\'s INT. Additional levels increase the damage.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.FIRE,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Explosion!'
            );
            foreach(user.enemies)::(index, enemy) {
                windowEvent.queueCustom(
                    onEnter :: {
                        user.attack(
                            target:enemy,
                            amount:user.stats.INT * (1.2) * (1 + (level-1)*0.1),
                            damageType : Damage.TYPE.FIRE,
                            damageClass: Damage.CLASS.HP
                        );
                    }
                )
            }
        }
    }
)            

Arts.newEntry(
    data: {
        name: 'Flash',
        id : 'base:flash',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Magick that blinds all enemies with a bright light. 50% chance to cause blindness, additional levels increase the chance.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Flash!'
            );
            foreach(user.enemies)::(index, enemy) {
                when(enemy.isIncapacitated()) empty;
                if (random.try(percentSuccess:40 * (level*10)))
                    windowEvent.queueCustom(
                        onEnter :: {
                            enemy.addEffect(from:user, id: 'base:blind', durationTurns: 5)
                        }
                    )
                else 
                    windowEvent.queueMessage(
                        text: enemy.name + ' covered their eyes!'
                    );                                
            }
        }
    }
)            

Arts.newEntry(
    data: {
        name: 'Thunder',
        id : 'base:thunder',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Magick that deals 4 random strikes based on INT. Each additional level deals an additional 2 strikes.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.THUNDER,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Thunder!'
            );
            for(0, 4 + (level-1)*2)::(index) {
                @:target = random.pickArrayItem(list:user.enemies);
                windowEvent.queueCustom(
                    onEnter :: {
                        user.attack(
                            target,
                            amount:user.stats.INT * (0.45),
                            damageType : Damage.TYPE.THUNDER,
                            damageClass: Damage.CLASS.HP
                        );
                    }
                )
            
            }
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Wild Swing',
        id : 'base:wild-swing',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Attack that deals 4 random strikes based on ATK. Additional levels increase the number of strikes.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' wildly swings!'
            );
            for(0, 4 + (level-1)*2)::(index) {
                @:target = random.pickArrayItem(list:user.enemies);
                windowEvent.queueCustom(
                    onEnter :: {
                        user.attack(
                            target,
                            amount:user.stats.ATK * (0.9),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP,
                            targetPart: Entity.normalizedDamageTarget(),
                            targetDefendPart:targetDefendParts[user.enemies->findIndex(value:target)]
                        );
                    }
                )
            }
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Cure',
        id : 'base:cure',
        targetMode : TARGET_MODE.ONE,
        description: "Heals a target by a small amount. Additional levels increase potency.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.HEAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Cure on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].heal(amount:((targets[0].stats.HP*(0.5 + (level-1)*0.1))->ceil));
                }
            )
        }
    }
)



Arts.newEntry(
    data: {
        name: 'Cleanse',
        id : 'base:cleanse',
        targetMode : TARGET_MODE.ONE,
        description: "Removes all status ailments and some negative effects. Additional levels have no benefit.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.HEAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Cleanse on ' + targets[0].name + '!'
            );
            @:Effect = import(module:'game_database.effect.mt');
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].removeEffects(
                        effectBases: [...Effect.getAll()]->filter(by:::(value) <- value.flags & Effect.statics.FLAGS.AILMENT)
                    );
                }
            );
        }
    }
)          

Arts.newEntry(
    data: {
        name: 'Magic Mist',
        id : 'base:magic-mist',
        targetMode : TARGET_MODE.ALLENEMY,
        description: "Removes ALL effects.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            foreach(targets)::(i, target) {
                windowEvent.queueMessage(
                    text: user.name + ' casts Magic Mist on ' + target.name + '!'
                );
                windowEvent.queueCustom(
                    onEnter :: {
                        user.resetEffects();
                    }
                )
            }
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Cure All',
        id : 'base:cure-all',
        targetMode : TARGET_MODE.ALLALLY,
        description: "Heals all party members by a small amount. Additional levels increase the effect.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.HEAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Cure All!'
            );

            foreach(targets)::(i, target) {
                windowEvent.queueCustom(
                    onEnter :: {
                        target.heal(amount:((target.stats.HP*(0.25 + (level-1) * 0.15)->ceil)));
                    }
                )
            }
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Protect',
        id : 'base:protect',
        targetMode : TARGET_MODE.ONE,
        description: "Increases DEF of target for 10 turns. It is stackable.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Protect on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id: 'base:protect', durationTurns: 10);
                }
            );
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Duel',
        id : 'base:duel',
        targetMode : TARGET_MODE.ONE,
        description: "Chooses a target to have a duel, causing them to take bonus damage by the user.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' challenges ' + targets[0].name + ' to a duel!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id: 'base:dueled', durationTurns: 1000000);
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Grace',
        id : 'base:grace',
        targetMode : TARGET_MODE.ONE,
        description: "Grants the target the ability to avoid death once. Additional levels have no effect.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.HEAL | TRAITS.MAGIC,
        rarity : RARITY.EPIC,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Grace on ' + targets[0].name + '!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id: 'base:grace', durationTurns: 1000);
                }
            )    
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Phoenix Soul',
        id : 'base:phoenix-soul',
        targetMode : TARGET_MODE.ONE,
        description: "Grants the target the ability to avoid death once if casted during daytime. Additional levels have no effect.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.MAGIC | TRAITS.HEAL,
        rarity : RARITY.EPIC,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Pheonix Soul on ' + targets[0].name + '!'
            );
            @:world = import(module:'game_singleton.world.mt');

            
            if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING)
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:grace', durationTurns: 1000)
                    }
                )
            else 
                windowEvent.queueMessage(text:'... but nothing happened!');

        }
    }
)            

Arts.newEntry(
    data: {
        name: 'Protect All',
        id : 'base:protect-all',
        targetMode : TARGET_MODE.ALLALLY,
        description: "Increases DEF of allies for 5 turns. This effect is stackable.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Protect All!'
            );
            foreach(user.allies)::(index, ally) {
                windowEvent.queueCustom(
                    onEnter :: {
                        ally.addEffect(from:user, id: 'base:protect', durationTurns: 5);
                    }
                )
            }
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Meditate',
        id : 'base:meditate',
        targetMode : TARGET_MODE.NONE,
        description: "Recovers users AP by a small amount.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.HEAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' meditates!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    user.healAP(amount:((user.stats.AP*0.2)->ceil));
                }
            );
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Soothe',
        id : 'base:soothe',
        targetMode : TARGET_MODE.ONE,
        description: "Relaxes a target, healing AP by a small amount.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.HEAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' casts Soothe on ' + targets[0].name + '!'
            );
            
            windowEvent.queueCustom(
                onEnter :: {
                    user.healAP(amount:((user.stats.AP*0.22)->ceil));
                }
            );
        }
    }
)



Arts.newEntry(
    data: {
        name: 'Steal',
        id : 'base:steal',
        targetMode : TARGET_MODE.ONE,
        description: 'Steals an item from a target. Additional levels increase the stealing success rate.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:world = import(module:'game_singleton.world.mt');

            windowEvent.queueMessage(
                text: user.name + ' attempted to steal from ' + targets[0].name + '!'
            );
            
            when(targets[0].inventory.items->keycount == 0) 
                windowEvent.queueMessage(text:targets[0].name + ' has no items!');
                
            // NICE
            if (random.try(percentSuccess:31 + (level-1)*8)) ::<= {
                windowEvent.queueCustom(
                    onEnter :: {

                        @:item = targets[0].inventory.items[0];
                        targets[0].inventory.remove(item);
                        
                        if (world.party.isMember(entity:user)) ::<= {
                            world.party.inventory.add(item);
                        } else ::<= {
                            targets[0].inventory.add(item);
                        }
                        windowEvent.queueMessage(text:user.name + ' stole a ' + item.name + '!');
                    }
                )                
            } else ::<= {
                windowEvent.queueMessage(text:user.name + " couldn't steal!");                        
            }

        }
    }
)            


Arts.newEntry(
    data: {
        name: 'Counter',
        id : 'base:counter',
        targetMode : TARGET_MODE.NONE,
        description: 'If attacked, dodges and retaliates for 3 turns.',
        durationTurns: 0,
        kind : KIND.REACTION,
        rarity : RARITY.RARE,
        traits : TRAITS.PHYSICAL,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueCustom(
                onEnter :: {
                    user.addEffect(from:user, id: 'base:counter', durationTurns: 3);
                }
            )
        }
    }
)



Arts.newEntry(
    data: {
        name: 'Unarm',
        id : 'base:unarm',
        targetMode : TARGET_MODE.ONE,
        description: 'Disarms a target. Additional levels increases the success rate.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @:Entity = import(module:'game_class.entity.mt');
            windowEvent.queueMessage(
                text: user.name + ' attempted to disarm ' + targets[0].name + '!'
            );
            
            @:equipped = targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR); 
            when(equipped.name == 'None') 
                windowEvent.queueMessage(text:targets[0].name + ' has nothing in-hand!');
                
            // NICE
            if (random.try(percentSuccess:31 + (level-1)*20)) ::<= {
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
                        if (world.party.isMember(entity:targets[0]))
                            world.party.inventory.add(item:equipped);
                    }
                )
                windowEvent.queueMessage(text:targets[0].name + ' lost grip of their ' + equipped.name + '!');
            } else ::<= {
                windowEvent.queueMessage(text:targets[0].name + " swiftly dodged and retaliated!");                        
                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].attack(
                            target:user,
                            amount:targets[0].stats.ATK * (0.2),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                        );
                    }
                )
            }

        }
    }
) 


Arts.newEntry(
    data: {
        name: 'Sneak',
        id : 'base:sneak',
        targetMode : TARGET_MODE.ONE,
        description: 'Guarantees times 3 damage next time an offensive ability is used next turn',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id: 'base:sneaked', durationTurns: 2);
                }
            )
        }
    }
)     

Arts.newEntry(
    data: {
        name: 'Mind Focus',
        id : 'base:mind-focus',
        targetMode : TARGET_MODE.NONE,
        description: 'Increases user\'s INT by 100% for 5 turns. Stackable.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueCustom(
                onEnter :: {
                    user.addEffect(from:user, id: 'base:mind-focused', durationTurns: 5);
                }
            )
        }
    }
) 




Arts.newEntry(
    data: {
        name: 'Defend',
        id : 'base:defend',
        targetMode : TARGET_MODE.NONE,
        description: 'Reduced damage for one turn and increases the number of block points by one. Additional stacks have no effect.',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueCustom(
                onEnter :: {
                    user.addEffect(from:user, id: 'base:defend', durationTurns:1);
                    user.flags.add(flag:StateFlags.DEFENDED);
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Guard',
        id : 'base:guard',
        targetMode : TARGET_MODE.NONE,
        description: 'Reduced damage for one turn.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueCustom(
                onEnter :: {
                    user.addEffect(from:user, id: 'base:guard', durationTurns:1);
                }
            )
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Proceed with Caution',
        id : 'base:proceed-with-caution',
        targetMode : TARGET_MODE.ALLALLY,
        description: 'Defense is heightened for the team for 10 turns.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueCustom(
                onEnter :: {
                    user.addEffect(from:user, id: 'base:proceed-with-caution', durationTurns:10);
                }
            )
        }
    }
)



Arts.newEntry(
    data: {
        name: 'Defensive Stance',
        id : 'base:defensive-stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that sacrifices offensive capabilities to boost defense.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueCustom(
                onEnter :: {
                    @:Effect = import(module:'game_database.effect.mt');
                    @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
                    user.removeEffects(effectBases:stances);
                    user.addEffect(from:user, id: 'base:defensive-stance', durationTurns:1000);
                }
            );
        }
    }
)           

Arts.newEntry(
    data: {
        name: 'Offensive Stance',
        id : 'base:offensive-stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that sacrifices defensive capabilities to boost offense.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:Effect = import(module:'game_database.effect.mt');
            @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));

            windowEvent.queueCustom(
                onEnter :: {
                    user.removeEffects(effectBases:stances);
                    user.addEffect(from:user, id: 'base:offensive-stance', durationTurns:1000);
                }
            )
        }
    }
)            

Arts.newEntry(
    data: {
        name: 'Light Stance',
        id : 'base:light-stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that makes the user lighter on their feet at the cost of offense.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:Effect = import(module:'game_database.effect.mt');
            @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            windowEvent.queueCustom(
                onEnter :: {
                    user.removeEffects(effectBases:stances);
                    user.addEffect(from:user, id: 'base:light-stance', durationTurns:1000);
                }
            )
        }
    }
)            

Arts.newEntry(
    data: {
        name: 'Heavy Stance',
        id : 'base:heavy-stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that makes the user sturdier at the cost of speed.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.UNCOMMON,
        traits : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:Effect = import(module:'game_database.effect.mt');
            @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            windowEvent.queueCustom(
                onEnter :: {
                    user.removeEffects(effectBases:stances);
                    user.addEffect(from:user, id: 'base:heavy-stance', durationTurns:1000);
                }
            )
        }
    }
) 

Arts.newEntry(
    data: {
        name: 'Meditative Stance',
        id : 'base:meditative-stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that makes the user more mentally focused.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.UNCOMMON,
        traits : 0,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:Effect = import(module:'game_database.effect.mt');
            @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            windowEvent.queueCustom(
                onEnter :: {
                    user.removeEffects(effectBases:stances);
                    user.addEffect(from:user, id: 'base:meditative-stance', durationTurns:1000);
                }
            );
        }
    }
)                 

Arts.newEntry(
    data: {
        name: 'Striking Stance',
        id : 'base:striking-stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that focuses offense above all.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:Effect = import(module:'game_database.effect.mt');
            @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            windowEvent.queueCustom(
                onEnter :: {
                    user.removeEffects(effectBases:stances);
                    user.addEffect(from:user, id: 'base:striking-stance', durationTurns:1000);
                }
            )
        }
    }
)  


Arts.newEntry(
    data: {
        name: 'Reflective Stance',
        id : 'base:reflective-stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that allows the user to reflect damage.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:Effect = import(module:'game_database.effect.mt');
            @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            windowEvent.queueCustom(
                onEnter :: {
                    user.removeEffects(effectBases:stances);
                    user.addEffect(from:user, id: 'base:reflective-stance', durationTurns:1000);
                }
            );
        }
    }
) 

Arts.newEntry(
    data: {
        name: 'Evasive Stance',
        id : 'base:evasive-stance',
        targetMode : TARGET_MODE.NONE,
        description: 'Stance that allows the user to dodge incoming attacks.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:Effect = import(module:'game_database.effect.mt');
            @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
            windowEvent.queueCustom(
                onEnter :: {
                    user.removeEffects(effectBases:stances);
                    user.addEffect(from:user, id: 'base:evasive-stance', durationTurns:1000);
                }
            )
        }
    }
)                            

Arts.newEntry(
    data: {
        name: 'Wait',
        id : 'base:wait',
        targetMode : TARGET_MODE.NONE,
        description: 'Does nothing.',
        durationTurns: 0,
        usageHintAI : USAGE_HINT.BUFF,
        traits : 0,
        kind : KIND.ABILITY,
        rarity : RARITY.COMMON,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:'' + user.name + ' waits.');
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Plant Poisonroot',
        id : 'base:plant-poisonroot',
        targetMode : TARGET_MODE.ONE,
        description: "Plants a poisonroot seed on the target. Grows in 4 turns and causes poison damage every turn when grown.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:targets[0].name + ' was covered in poisonroot seeds!');
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id:'base:poisonroot-growing', durationTurns:2);                            
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Plant Triproot',
        id : 'base:plant-triproot',
        targetMode : TARGET_MODE.ONE,
        description: "Plants a triproot seed on the target. Grows in 4 turns and causes 40% chance to trip every turn when grown.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:targets[0].name + ' was covered in triproot seeds!');
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id:'base:triproot-growing', durationTurns:2);                            
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Plant Healroot',
        id : 'base:plant-healroot',
        targetMode : TARGET_MODE.ONE,
        description: "Plants a healroot seed on the target. Grows in 4 turns and heals 5% HP turn.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI: USAGE_HINT.HEAL,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:targets[0].name + ' was covered in triproot seeds!');
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(from:user, id:'base:healroot-growing', durationTurns:2);                            
                }
            );
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Green Thumb',
        id : 'base:green-thumb',
        targetMode : TARGET_MODE.ONE,
        description: "Any growing roots grow instantly on the target.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.EPIC,
        usageHintAI: USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:which = [
                'base:healroot-growing',
                'base:triproot-growing',
                'base:poisonroot-growing'                    
            ]

            @:effects = targets[0].effectStack.getAll()->filter(::(value) <- which->findIndex(:value.id) != -1);            
            when(effects->keycount == 0)
                windowEvent.queueMessage(text:'Nothing happened!');

            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].removeEffects(:which);
                }
            )
            windowEvent.queueMessage(text:user.name + ' accelerated the growth of the seeds on ' + targets[0].name + '!');
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Fire Shift',
        id : 'base:fire-shift',
        targetMode : TARGET_MODE.NONE,
        description: "Adds the Burning effect. Stackable.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC | TRAITS.FIRE,
        rarity : RARITY.COMMON,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:user.name + ' becomes shrouded in flame!');
            windowEvent.queueCustom(
                onEnter :: {
                    user.addEffect(from:user, id:'base:burning', durationTurns:20);                            
                }
            )
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Elemental Tag',
        id : 'base:elemental-tag',
        targetMode : TARGET_MODE.ONE,
        description: "Adds weakness to elemental damage +100%. Stackable.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.UNCOMMON,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:targets[0].name + ' becomes weak to elemental damage!');
            windowEvent.queueCustom(
                onEnter :: {
                    user.addEffect(from:user, id:'base:elemental-tag', durationTurns:20);                            
                }
            )
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Elemental Shield',
        id : 'base:elemental-shield',
        targetMode : TARGET_MODE.NONE,
        description: "Nullifies most Thunder, Fire, and Ice damage for 5 turns.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.RARE,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:user.name + ' becomes shielded to elemental damage!');
            windowEvent.queueCustom(
                onEnter :: {
                    user.addEffect(from:user, id:'base:elemental-shield', durationTurns:5);                            
                }
            )
        }
    }
)



Arts.newEntry(
    data: {
        name: 'Ice Shift',
        id : 'base:ice-shift',
        targetMode : TARGET_MODE.NONE,
        description: "Adds the Icy effect. Stackable.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC | TRAITS.ICE,
        rarity : RARITY.COMMON,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:user.name + ' becomes shrouded in an icy wind!');
            windowEvent.queueCustom(
                onEnter :: {
                    user.addEffect(from:user, id:'base:icy', durationTurns:20);                            
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Thunder Shift',
        id : 'base:thunder-shift',
        targetMode : TARGET_MODE.NONE,
        description: "Adds the Shock effect. Stackable.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC | TRAITS.THUNDER,
        rarity : RARITY.COMMON,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:user.name + ' becomes shrouded in electric arcs!');
            windowEvent.queueCustom(
                onEnter :: {
                    user.addEffect(from:user, id:'base:shock', durationTurns:20);                            
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Tri Shift',
        id : 'base:tri-shift',
        targetMode : TARGET_MODE.NONE,
        description: "Adds the Shock, Burning, and Icy effects. Stackable.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.MAGIC,
        rarity : RARITY.RARE,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:user.name + ' becomes shrouded in light');
            windowEvent.queueCustom(
                onEnter :: {

                    user.addEffect(from:user, id:'base:burning', durationTurns:20);                            
                    user.addEffect(from:user, id:'base:icy',     durationTurns:20);                            
                    user.addEffect(from:user, id:'base:shock',   durationTurns:20);                            
                }
            );
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Use Item',
        id : 'base:use-item',
        targetMode : TARGET_MODE.ONE,
        description: "Uses an item from the user's inventory.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : 0,
        rarity : RARITY.RARE,
        isSupport: false,
        usageHintAI: USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:item = extraData[0];
            when (targets->size == 0) ::<= {
                foreach(item.base.useEffects)::(index, effect) {    
                    user.addEffect(from:user, id:effect, item:item, durationTurns:0);                            
                }
            }

            
            foreach(item.base.useEffects)::(index, effect) {    
                foreach(targets)::(t, target) {
                    target.addEffect(from:user, id:effect, item:item, durationTurns:0);                            
                }
            }
        }
    }
) 
       


/*
Arts.newEntry(
    data: {
        name: 'Quickhand Item',
        id : 'base:quickhand-item',
        targetMode : TARGET_MODE.ONE,
        description: "Uses 2 items from the user's inventory.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI: USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @item = extraData[0];
            foreach(item.base.useEffects)::(index, effect) {    
                foreach(targets)::(t, target) {
                    target.addEffect(from:user, id:effect, item:item, durationTurns:0);                            
                }
            }

            item = extraData[1];
            foreach(item.base.useEffects)::(index, effect) {    
                foreach(targets)::(t, target) {
                    target.addEffect(from:user, id:effect, item:item, durationTurns:0);                            
                }
            }
        }
    }
)
*/


/*
Arts.newEntry(
    data: {
        name: 'Equip Item',
        id : 'base:equip-item',
        targetMode : TARGET_MODE.ONE,
        description: "Equips an item from the user's inventory.",
        durationTurns: 0,
        hpCost : 0,
        apCost : 0,
        usageHintAI: USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:item = extraData[0];
            user.equip(
                item, 
                slot:user.getSlotsForItem(item)[0], 
                inventory:extraData[1]
            );
        }
    }
)
*/

Arts.newEntry(
    data: {
        name: 'Defend Other',
        id : 'base:defend-other',
        targetMode : TARGET_MODE.ONE,
        description: "Defends another from getting attacked",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.RARE,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(
                        from:user, id: 'base:defend-other', durationTurns: 4 
                    );
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Perfect Guard',
        id : 'base:perfect-guard',
        targetMode : TARGET_MODE.ONE,
        description: "Nullifies damage for 3 turns. Additional levels have no effect.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.RARE,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(
                        from:user, id: 'base:perfect-guard', durationTurns: 3 
                    );
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Sharpen',
        id : 'base:sharpen',
        targetMode : TARGET_MODE.ONE,
        description: "Sharpens a weapon, increasing its damage for the battle.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI: USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:Entity = import(module:'game_class.entity.mt');
            when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR).base.name == 'None')
                windowEvent.queueMessage(text:targets[0].name + ' has no weapon to sharpen!');                    


            windowEvent.queueMessage(text:user.name + ' sharpens ' + targets[0].name + '\'s weapon!');

            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(
                        from:user, id: 'base:sharpen', durationTurns: 1000000 
                    );
                }
            );
            
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Weaken Armor',
        id : 'base:weaken-armor',
        targetMode : TARGET_MODE.ONE,
        description: "Weakens armor, decreasing its effectiveness for the battle.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:Entity = import(module:'game_class.entity.mt');
            when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.ARMOR).base.name == 'None')
                windowEvent.queueMessage(text:targets[0].name + ' has no armor to weaken!');                    


            windowEvent.queueMessage(text:user.name + ' weakens ' + targets[0].name + '\'s armor!');
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(
                        from:user, id: 'base:weaken-armor', durationTurns: 1000000 
                    );
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Dull Weapon',
        id : 'base:dull-weapon',
        targetMode : TARGET_MODE.ONE,
        description: "Dull a weapon, decreasing its damage for next turn.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:Entity = import(module:'game_class.entity.mt');
            when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR).base.name == 'None')
                windowEvent.queueMessage(text:targets[0].name + ' has no weapon to dull!');                    


            windowEvent.queueMessage(text:user.name + ' dulls ' + targets[0].name + '\'s weapon!');

            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(
                        from:user, id: 'base:dull-weapon', durationTurns: 1000000 
                    );
                }
            )
            
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Strengthen Armor',
        id : 'base:strengthen-armor',
        targetMode : TARGET_MODE.ONE,
        description: "Strengthens armor, increasing its effectiveness for the battle",
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.COMMON,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:Entity = import(module:'game_class.entity.mt');
            when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.ARMOR).base.name == 'None')
                windowEvent.queueMessage(text:targets[0].name + ' has no armor to strengthen!');                    


            windowEvent.queueMessage(text:user.name + ' strengthens ' + targets[0].name + '\'s armor!');

            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(
                        from:user, id: 'base:strengthen-armor', durationTurns: 1000000 
                    );
                }
            )
            
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Convince',
        id : 'base:convince',
        targetMode : TARGET_MODE.ONE,
        description: "Prevents a combatant from acting for a few turns if successful. Additional levels increase the success chance.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : 0,
        rarity : RARITY.UNCOMMON,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text:user.name + ' tries to convince ' + targets[0].name + ' to wait!');
            
            when(random.try(percentSuccess:50 - (level-1)*10))
                windowEvent.queueMessage(text: targets[0].name + ' ignored ' + user.name + '!');


            windowEvent.queueMessage(text:targets[0].name + ' listens intently!');
            windowEvent.queueCustom(
                onEnter :: {
                    targets[0].addEffect(
                        from:user, id: 'base:convinced', durationTurns: 1+(Number.random()*3)->floor 
                    );
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Pink Brew',
        id : 'base:pink-brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 2 Ingredients to make a pink potion.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.base.id == 'base:ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make a Pink Brew...');
            when(count < 2)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Pink Potion!');
            windowEvent.queueCustom(
                onEnter :: {

                    inventory.removeByID(id:'base:ingredient');
                    inventory.removeByID(id:'base:ingredient');
                    inventory.add(item:Item.new(base:Item.database.find(id:'base:pink-potion')));                            
                }
            );
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Cyan Brew',
        id : 'base:cyan-brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 2 Ingredients to make a cyan potion.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.base.id == 'base:ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make a Cyan Brew...');
            when(count < 2)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Cyan Potion!');

            windowEvent.queueCustom(
                onEnter :: {
                    inventory.removeByID(id:'base:ingredient');
                    inventory.removeByID(id:'base:ingredient');
                    inventory.add(item:
                        Item.new(
                            base:Item.database.find(id:'base:cyan-potion')
                        )
                    );              
                }
            );              
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Green Brew',
        id : 'base:green-brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 2 Ingredients to make a green potion.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.base.id == 'base:ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make a Green Brew...');
            when(count < 2)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Green Potion!');
            windowEvent.queueCustom(
                onEnter :: {
                    inventory.removeByID(id:'base:ingredient');
                    inventory.removeByID(id:'base:ingredient');
                    inventory.add(
                        item:Item.new(
                            base:Item.database.find(id:'base:green-potion')
                    ));             
                }
            );               
        }
    }
)



Arts.newEntry(
    data: {
        name: 'Orange Brew',
        id : 'base:orange-brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 2 Ingredients to make an orange potion.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.base.id == 'base:ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make an Orange Brew...');
            when(count < 2)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Orange Potion!');

            windowEvent.queueCustom(
                onEnter :: {
                    inventory.removeByID(id:'base:ingredient');
                    inventory.removeByID(id:'base:ingredient');
                    inventory.add(item:
                        Item.new(
                            base:Item.database.find(id:'base:orange-potion')
                        )
                    );                            
                }
            );
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Purple Brew',
        id : 'base:purple-brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 2 Ingredients to make a purple potion.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.base.id == 'base:ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make a Purple Brew...');
            when(count < 2)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Purple Potion!');
            windowEvent.queueCustom(
                onEnter :: {
                    inventory.removeByID(id:'base:ingredient');
                    inventory.removeByID(id:'base:ingredient');
                    inventory.add(
                        item:Item.new(
                            base:Item.database.find(id:'base:purple-potion')
                        )
                    );                            
                }
            )
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Scavenge',
        id : 'base:scavenge',
        targetMode : TARGET_MODE.NONE,
        description: 'Searches the area for an Ingredient to make potions.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(text: user.name + ' looked around and found an Ingredient!');
            windowEvent.queueCustom(
                onEnter :: {
                    @:world = import(module:'game_singleton.world.mt');

                    world.party.inventory.add(
                        item:Item.new(
                            base:Item.database.find(id:'base:ingredient')
                        )
                    );      
                }
            )                      
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Black Brew',
        id : 'base:black-brew',
        targetMode : TARGET_MODE.NONE,
        description: 'Uses 2 Ingredients to make a black potion.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : 0,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:world = import(module:'game_singleton.world.mt');
            @inventory;
            if (world.party.isMember(entity:user)) ::<= {
                inventory = world.party.inventory;
            } else ::<= {
                inventory = user.inventory;
            }
            
            @count = 0;
            foreach(inventory.items)::(i, item) {
                if (item.base.id == 'base:ingredient') ::<= {
                    count += 1;
                }
            }
            
            windowEvent.queueMessage(text: user.name + ' tried to make a Black Brew...');
            when(count < 2)
                windowEvent.queueMessage(text: '... but didn\'t have enough ingredients!');

            windowEvent.queueMessage(text: '... and made a Black Potion!');
            windowEvent.queueCustom(
                onEnter :: {
                    inventory.removeByID(id:'base:ingredient');
                    inventory.removeByID(id:'base:ingredient');
                    inventory.add(
                        item:Item.new(
                            base:Item.database.find(id:'base:black-potion')
                        )
                    );   
                }
            )                         
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Bribe',
        id : 'base:bribe',
        targetMode : TARGET_MODE.ONE,
        description: "Pays a combatant to not fight any more. Additional levels decrease the required cost.",
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.RARE,
        traits : 0,
        usageHintAI: USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            when (user.allies->any(condition:::(value) <- value == targets[0]))
                windowEvent.queueMessage(text: "Are you... trying to bribe me? we're... we're on the same team..");
                
            @:cost = ((targets[0].level*100 + targets[0].stats.sum * 4) * (1 - (level-1)*0.08))->ceil;

            @:world = import(module:'game_singleton.world.mt');

            windowEvent.queueMessage(text: user.name + ' tries to bribe ' + targets[0].name + '!');
            
            match(true) {
                // party -> NPC
                (world.party.isMember(entity:user)) ::<= {

                    when (world.party.inventory.gold < cost)
                        windowEvent.queueMessage(text: "The party couldn't afford the " + g(g:cost) + " bribe!");

                    windowEvent.queueCustom(
                        onEnter :: {
                            world.party.inventory.subtractGold(amount:cost);
                            targets[0].addEffect(
                                from:user, id: 'base:bribed', durationTurns: -1
                            );             
                        }
                    );
                    windowEvent.queueMessage(text: user.name + ' bribes ' + targets[0].name + ' for ' + g(g:cost) + '!');
                
                },
                
                // NPC -> party
                (world.party.isMember(entity:targets[0])) ::<= {
                    windowEvent.queueMessage(text: user.name + ' has offered ' + g(g:cost) + ' for ' + targets[0].name + ' to stop acting for the rest of the battle.');
                    windowEvent.queueAskBoolean(
                        prompt: 'Accept offer for ' + g(g:cost) + '?',
                        onChoice::(which) {
                            when(which == false) empty;

                            windowEvent.queueMessage(text: user.name + ' bribes ' + targets[0].name + '!');
                            targets[0].addEffect(
                                from:user, id: 'base:bribed', durationTurns: -1
                            );    
            
                            world.party.inventory.addGold(amount:cost);
                        }
                    );                                              
                },
                
                // NPC -> NPC
                default: ::<={
                    windowEvent.queueCustom(
                        onEnter :: {
                            targets[0].addEffect(
                                from:user, id: 'base:bribed', durationTurns: -1
                            );                                         
                        }
                    )
                }
            }
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Sweet Song',
        id : 'base:sweet-song',
        targetMode : TARGET_MODE.ALLENEMY,
        description: 'Alluring song that captivates the listener',
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : 0,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' sings a haunting, sweet song!'
            );
            foreach(user.enemies)::(index, enemy) {
                when(enemy.isIncapacitated()) empty;
                if (random.flipCoin())
                    windowEvent.queueCustom(
                        onEnter :: {
                            enemy.addEffect(from:user, id: 'base:mesmerized', durationTurns: 3)
                        }
                    )
                else 
                    windowEvent.queueMessage(
                        text: enemy.name + ' covered their ears!'
                    );                                
            }
        }
    }
)     


Arts.newEntry(
    data: {
        name: 'Wrap',
        id : 'base:wrap',
        targetMode : TARGET_MODE.ONE,
        description: 'Wraps around one enemy, followed by a feast.',
        durationTurns: 2,
        kind : KIND.ABILITY,
        traits : TRAITS.PHYSICAL,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            when(turnIndex == 0) ::<= {
                windowEvent.queueMessage(
                    text: user.name + ' tries to coil around ' + targets[0].name + '!'
                );

                when(targets[0].isIncapacitated() == false && random.try(percentSuccess:25)) ::<= {
                    windowEvent.queueMessage(
                        text: targets[0].name + ' narrowly escapes!'
                    );
                    return Arts.CANCEL_MULTITURN;
                }


                windowEvent.queueCustom(
                    onEnter :: {
                        targets[0].addEffect(from:user, id: 'base:wrapped', durationTurns: 4)
                    }
                );
            }
            
            when(turnIndex == 2) ::<= {
                breakpoint();
                when (targets[0].effectStack.getAll()->filter(by:::(value) <- value.id == 'base:wrapped')->size == 0) empty;
                
                windowEvent.queueMessage(
                    text: 'While wrapping ' + targets[0].name + ' in their coils, ' + user.name + ' tries to devour ' + targets[0].name + '!'
                );            

                when(targets[0].isIncapacitated() || random.try(percentSuccess:75)) ::<= {
                    windowEvent.queueMessage(
                        text: targets[0].name + ' was swallowed whole!'
                    );                                
                    windowEvent.queueCustom(
                        onEnter :: {
                            targets[0].kill(silent:true);
                        }
                    )
                }
                
                windowEvent.queueMessage(
                    text: targets[0].name + ' managed to struggle enough to prevent getting eaten!'
                );                                
                
                
                windowEvent.queueCustom(
                    onEnter :: {
                        @:which = targets[0].effectStack.getAll()->filter(
                            ::(value) <- value.from == user && value.id == 'base:wrapped'
                        );
                        when (which->size == 0) empty;
                        targets[0].removeEffectInstance(:which);
                    }
                )
                
            }
        }
    }
)     


/* NOT USED ANYMORE */
/////////
    Arts.newEntry(
        data: {
            name: 'Swipe Kick',
            id : 'base:swipe-kick',
            targetMode : TARGET_MODE.ONEPART,
            description: "Damages a target based on the user's ATK.",
            durationTurns: 0,
            kind : KIND.ABILITY,
            traits : TRAITS.PHYSICAL,
            rarity : RARITY.RARE,
            usageHintAI : USAGE_HINT.OFFENSIVE,
            oncePerBattle : false,
            canBlock : true,
            isSupport : false,
            onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
                windowEvent.queueMessage(
                    text: user.name + ' attacks ' + targets[0].name + '!'
                );
                

                windowEvent.queueCustom(
                    onEnter :: {
                        user.attack(
                            target:targets[0],
                            amount:user.stats.ATK * (0.5),
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP,
                            targetPart:targetParts[0],
                            targetDefendPart:targetDefendParts[0]
                        );                        
                    }
                )
                                        
            }
        }
    )
///////////



/*

    Meta arts

*/


Arts.newEntry(
    data: {
        name: 'Diversify',
        id : 'base:diversify',
        targetMode : TARGET_MODE.NONE,
        description: 'Draw 2 Arts cards.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.SUPPORT,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            user.drawArt(count:2);
        }
    }
)     

Arts.newEntry(
    data: {
        name: 'Mind Games',
        id : 'base:mind-games',
        targetMode : TARGET_MODE.ONE,
        description: 'Target discards an Art card.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.SUPPORT,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            targets[0].discardArt();
        }
    }
)     

Arts.newEntry(
    data: {
        name: 'Crossed Wires',
        id : 'base:crossed-wires',
        targetMode : TARGET_MODE.ONE,
        description: 'Swap hands with a target.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.SUPPORT,
        rarity : RARITY.RARE,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:oldHand = [...user.deck.hand]
            user.deck.hand = [...targets[0].deck.hand];
            targets[0].deck.hand = oldHand;
            
            windowEvent.queueMessage(
                text: user.name + ' swapped Arts with ' + targets[0].name + '!'
            );
        }
    }
)     



Arts.newEntry(
    data: {
        name: 'Recycle',
        id : 'base:recycle',
        targetMode : TARGET_MODE.NONE,
        description: 'Discard an Arts card and draw an Arts card from the user\'s discard pile.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.SUPPORT,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            user.discardArt();
            user.drawArt();            
        }
    }
)     

Arts.newEntry(
    data: {
        name: 'Reevaluate',
        id : 'base:reevaluate',
        targetMode : TARGET_MODE.NONE,
        description: 'Discards entire hand and draws 5 cards.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.SUPPORT,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            user.deck.hand = [];
            foreach(user.deck.hand) ::(k, c) {
                user.deck.discardFromHand(:c);
            }
            user.drawArt(count:5);            
        }
    }
)


Arts.newEntry(
    data: {
        name: 'Brace',
        id : 'base:brace',
        targetMode : TARGET_MODE.NONE,
        description: 'Discard an Arts card. User has an additional block point for 2 turns and gains 50% DEF.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.SUPPORT,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            user.discardArt();
            user.addEffect(from:user, id:'base:brace', durationTurns:2);
        }
    }
)    

Arts.newEntry(
    data: {
        name: 'Agility',
        id : 'base:agility',
        targetMode : TARGET_MODE.NONE,
        description: 'Discard an Arts card. User is given the \'Agile\' status for 3 turns. While Agile, the user has a chance to dodge attacks. This chance is increased if the user\'s DEX is greater than the attacker\'s. This can be stacked.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        rarity : RARITY.UNCOMMON,
        traits : TRAITS.SUPPORT,
        usageHintAI : USAGE_HINT.BUFF,
        oncePerBattle : false,
        canBlock : false,
        isSupport : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            user.discardArt();
            user.addEffect(from:user, id:'base:agile', durationTurns:5);
        }
    }
)    

Arts.newEntry(
    data: {
        name: 'Foresight',
        id : 'base:foresight',
        targetMode : TARGET_MODE.ONE,
        description: 'Discard an Arts card. View a target\'s Arts hand.',
        durationTurns: 0,
        kind : KIND.EFFECT,
        traits : TRAITS.SUPPORT,
        rarity : RARITY.COMMON,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        isSupport : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            user.discardArt();
            windowEvent.queueMessage(text:user.name + ' views ' + targets[0].name + ' Arts hand.');
            @:party = import(module:'game_singleton.world.mt').party;                    

            when(party.leader == user) ::<= {
                targets[0].deck.viewHand();
            }
        }
    }
)    

Arts.newEntry(
    data: {
        name: 'Retaliate',
        id : 'base:retaliate',
        targetMode : TARGET_MODE.NONE,
        description: 'The user retaliates to an ability, damaging the enemy based on ATK. This damage is not blockable.',
        durationTurns: 0,
        kind : KIND.REACTION,
        traits : TRAITS.SUPPORT | TRAITS.PHYSICAL,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : false,
        isSupport : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' retaliates to ' + targets[0].name + '\'s Art!'
            );
            windowEvent.queueCustom(
                onEnter :: {
                    user.attack(
                        target:targets[0],
                        amount:user.stats.ATK * (0.5),
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart:targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    );        
                }
            )
            return false;
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Cancel',
        id : 'base:cancel',
        targetMode : TARGET_MODE.NONE,
        description: 'The user cancels an ability Art.',
        durationTurns: 0,
        kind : KIND.REACTION,
        traits : TRAITS.SUPPORT,
        rarity : RARITY.UNCOMMON,
        usageHintAI : USAGE_HINT.DEBUFF,
        oncePerBattle : false,
        canBlock : false,
        isSupport : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' retaliates to ' + targets[0].name + '\'s Art!'
            );
            return true;
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Pebble',
        id : 'base:pebble',
        targetMode : TARGET_MODE.ONEPART,
        description: "Throws a pebble at a target, causing a small amount of damage.",
        durationTurns: 0,
        usageHintAI : USAGE_HINT.OFFENSIVE,
        oncePerBattle : false,
        canBlock : true,
        isSupport : true,
        kind : KIND.EFFECT,
        traits : TRAITS.SUPPORT | TRAITS.PHYSICAL,
        rarity : RARITY.RARE,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            windowEvent.queueMessage(
                text: user.name + ' suddenly throws a pebble at ' + targets[0].name + '!'
            );
            
            windowEvent.queueCustom(
                onEnter :: {
                    user.attack(
                        target:targets[0],
                        amount:1,
                        damageType : Damage.TYPE.PHYS,
                        damageClass: Damage.CLASS.HP,
                        targetPart:targetParts[0],
                        targetDefendPart:targetDefendParts[0]
                    );                        
                }
            )
        }
    }
)

Arts.newEntry(
    data: {
        name: 'Wyvern Prayer',
        id : 'base:wyvern-prayer',
        targetMode : TARGET_MODE.ALL,
        description: "Prays for a miracle, causing a variety of potent effects. Reduces current AP by half if successful. Additional levels reduce the AP reduction.",
        durationTurns: 0,
        kind : KIND.ABILITY,
        traits : TRAITS.SUPPORT | TRAITS.MAGIC,
        rarity : RARITY.EPIC,
        usageHintAI : USAGE_HINT.DONTUSE,
        oncePerBattle : false,
        canBlock : false,
        isSupport : true,
        onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
            when (user.ap == 0) 
                windowEvent.queueMessage(
                    text: '...But nothing happened!'
                );
            
            @red = (0.5 + ((level-1) * 0.1));
            if (red > 0.95) red = 0.95;
            
            user.ap = (user.ap * red)->floor;
            
            (random.pickArrayItem(list:[
                // sudden death, 1 HP for everyone
                :: {
                    windowEvent.queueMessage(
                        text: 'A malevolent and dark energy befalls the battle.'
                    );
                    windowEvent.queueCustom(
                        onEnter :: {
                            foreach(targets) ::(k, target) {
                                target.damage(from:user, damage:Damage.new(
                                    amount:target.hp-1,
                                    damageType:Damage.TYPE.LIGHT,
                                    damageClass:Damage.CLASS.HP
                                ),dodgeable: false, exact: true);         
                            }
                        }
                    )
                },
                
                // hurt everyone
                :: {
                    windowEvent.queueMessage(
                        text: 'Beams of light shine from above!'
                    );
                    
                    windowEvent.queueCustom(
                        onEnter :: {
                            foreach(targets) ::(k, target) {
                                target.damage(from:user, damage:Damage.new(
                                    amount:(target.hp/2)->floor,
                                    damageType:Damage.TYPE.LIGHT,
                                    damageClass:Damage.CLASS.HP
                                ),dodgeable: false, exact: true);         
                            }
                        }
                    );
                },                

                // Unequip everyone's weapon.
                :: {
                    windowEvent.queueMessage(
                        text: 'Arcs of electricity blast everyone\'s weapons out of their hands!'
                    );
                    windowEvent.queueCustom(
                        onEnter :: {
                    
                            @:Entity = import(module:'game_class.entity.mt');
                            @:party = import(module:'game_singleton.world.mt').party;                    
                            foreach(targets) ::(k, target) {
                                @:item = target.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR);
                                target.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR);
                                if (party.isMember(entity:target)) ::<= {
                                    party.inventory.add(item);
                                }
                            }
                        }
                    );
                },   

                // Max HP!
                :: {
                    windowEvent.queueMessage(
                        text: 'A soothing energy envelopes the battlefield.'
                    );
                    
                    windowEvent.queueCustom(
                        onEnter :: {
                            foreach(targets) ::(k, target) {
                                target.heal(amount:target.stats.HP);       
                            }
                        }
                    );
                },

                // Heal over time. Sol Attunement for now
                :: {
                    windowEvent.queueMessage(
                        text: 'A soothing energy envelopes the battlefield.'
                    );
                    
                    windowEvent.queueCustom(
                        onEnter :: {
                            foreach(targets) ::(k, target) {
                                target.addEffect(from:user, id:'base:greater-sol-attunement', durationTurns:9999);
                            }
                        }
                    )
                }
            ]))();
            

                                                
        }
    }
)


};

@:Arts = class(
    inherits: [Database],
    define::(this) {
        this.interface = {        
            TARGET_MODE : {get::<- TARGET_MODE},
            USAGE_HINT : {get::<- USAGE_HINT},
            KIND : {get::<- KIND},
            RARITY : {get::<- RARITY},
            TRAITS : {get::<- TRAITS},
            CANCEL_MULTITURN : {get::<- -1},
            
            traitToString::(trait) {
                return match(trait) {
                  (1): 'Physical',
                  (2): 'Magick',
                  (4): 'Healing',
                  (8): 'Fire',
                  (16): 'Ice',
                  (32): 'Thunder',
                  (64): 'Status',
                  (128): 'Support'
                }
                return '';
            }
        }
    }    
).new(
    name : 'Wyvern.Arts',
    attributes : {
        name : String,
        id : String,
        description : String,
        targetMode : Number,
        usageHintAI : Number,
        oncePerBattle : Boolean,
        kind : Number,
        traits : Number,
        rarity : Number,
        durationTurns : Number, // multiduration turns supercede the choice of action
        canBlock : Boolean, // whether the targets get a chance to block

        onAction : Function
    },
    reset
);



return Arts;