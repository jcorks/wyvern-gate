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
  ONE   : 0,  
  ONEPART : 1,
  ALLALLY : 2,  
  RANDOM  : 3,  
  NONE  : 4,
  ALLENEMY: 5,
  ALL   : 6
}

@USAGE_HINT = {
  OFFENSIVE : 0,
  HEAL  : 1,
  BUFF  : 2,
  DEBUFF  : 3,
  DONTUSE : 4,
} 

@KIND = {
  ABILITY : 0,
  REACTION : 1,
  EFFECT : 2,
  FIELD : 3
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
  POISON : 1024,
  SPECIAL : 2048,
  COSTLESS : 4096,
  MULTIHIT : 8192
}








@Arts;
@:reset = ::{

@:ATTACK_SHIFTS = [
  "base:burning",
  "base:icy",
  "base:shock",
  "base:shimmering",
  "base:dark",
  "base:toxic"
]

@:CURSED_SHIFTS = [
  "base:fire-curse",
  "base:ice-curse",
  "base:thunder-curse",
  "base:light-curse",
  "base:dark-curse",
  "base:poison-curse"
]

@:AILMENTS = [
  "base:burned",
  "base:frozen",
  "base:paralyzed",
  "base:petrified",
  "base:blind",
  "base:poisoned"
]



@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Item = import(module:'game_mutator.item.mt');
@:Damage = import(module:'game_class.damage.mt');
@:random = import(module:'game_singleton.random.mt');
@:StateFlags = import(module:'game_class.stateflags.mt');
@:g = import(module:'game_function.g.mt');
@:Entity = import(module:'game_class.entity.mt');
@:StatSet = import(module:'game_class.statset.mt');
Arts.newEntry(
  data: {
    name: 'Attack',
    id : 'base:attack',
    notifCommit : '$1 attacks $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    keywords : [],
    description: "Damages a target based on the user's ATK.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL | TRAITS.SPECIAL | TRAITS.COSTLESS,
    rarity : RARITY.COMMON,
    baseDamage ::(level, user) <- user.stats.ATK * (0.5) * level,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:Arts.find(:'base:attack').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    notifCommit : '$1 attempts to defeat $2 in one attack!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Deals 1 HP. 5% chance to 1hit K.O. Each level increases the chance by 5%.",
    keywords : [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) <- 1,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      
      
      windowEvent.queueCustom(
        onEnter :: {

          if (user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:1,
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
            targetPart: Entity.DAMAGE_TARGET.HEAD,
            targetDefendPart:targetDefendParts[0]
          ) == true)
            if (random.try(percentSuccess:level*5)) ::<= {
              windowEvent.queueMessage(
                text: user.name + ' does a connecting blow, finishing off ' + targets[0].name +'!'
              );              
              targets[0].damage(attacker:user, damage:Damage.new(
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
    notifCommit : '$1 takes aim at $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Damages a target based on the user's ATK and DEX. Additional levels increase the damage by 10%.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    traits : TRAITS.PHYSICAL,
    baseDamage ::(level, user) <- (user.stats.ATK * (0.2) + user.stats.DEX * (0.5)) * (1 + 0.1*(level-1)),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:Arts.find(:'base:precise-strike').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    notifCommit : '$1 attempts to tranquilize $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Damages a target based on the user's DEX with a 45% chance to inflict Paralyzed. Additional levels increase the paralysis chance by 10%.",
    durationTurns: 0,
    keywords : ['base:paralyzed'],
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage ::(level, user) <- user.stats.DEX * (0.5),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          if (user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:Arts.find(:'base:tranquilizer').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    notifCommit : '$1 coordinates with others!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLALLY,
    description: "ATK,DEF,SPD +35% for each party member. Every 2 levels stacks the boost.",
    durationTurns: 0,
    keywords : [],
    kind : KIND.ABILITY,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {

          foreach(targets)::(i, ent) {
            when(ent == user) empty;
            // skip if already has Coordinated effect.
            //when(ent.effects->any(condition::(value) <- value.name == user.profession.name)) empty;
            for(0, (level/2)->floor + 1) ::(i) {
              targets[0].addEffect(from:user, id: 'base:coordinated', durationTurns: 1000000);
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
    notifCommit : '$1 attacks $2 as a follow-up!',
    notifFail : Arts.NO_NOTIF,

    targetMode : TARGET_MODE.ONEPART,
    description: "Damages a target based on the user's ATK, doing 100% more damage if the target was hit since their last turn. Additional levels increase the boost by 20%.",
    durationTurns: 0,
    keywords : [],
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage ::(level, user)<- user.stats.ATK * (0.5 + 0.15 * level),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {

          
          if (targets[0].flags.has(flag:StateFlags.HURT)) 
            user.attack(
              target:targets[0],
              damage: Damage.new(
                amount:Arts.find(:'base:follow-up').baseDamage(level, user)*2,
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
              ),
              targetPart:targetParts[0],
              targetDefendPart:targetDefendParts[0]
            )
          else
            user.attack(
              target:targets[0],
              damage: Damage.new(
                amount:Arts.find(:'base:follow-up').baseDamage(level, user),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
              ),
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
    notifCommit : '$1 attacks twice!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Multi-hit attack that damages a target based on the user's ATK. Additional levels increase the damage per hit.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL | TRAITS.MULTIHIT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage::(level, user) <- user.stats.ATK * (0.4 + (level-1)*0.1),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          @target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
          user.attack(
            target,
            damage: Damage.new(
              amount: Arts.find(:'base:doublestrike').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP,
              isMultihit : true
            ),
            targetPart: targetParts[(user.battle.getEnemies(:user))->findIndex(value:target)],
            targetDefendPart:targetDefendParts[(user.battle.getEnemies(:user))->findIndex(value:target)]
          );
        }
      );

      windowEvent.queueCustom(
        onEnter :: {

          @target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
          user.attack(
            target,
            damage: Damage.new(
              amount:Arts.find(:'base:doublestrike').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP,
              isMultihit : true
            ),
            targetPart : targetParts[(user.battle.getEnemies(:user))->findIndex(value:target)],
            targetDefendPart:targetDefendParts[(user.battle.getEnemies(:user))->findIndex(value:target)]
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
    description: "Multi-hit attack that damages three targets based on the user's ATK. Each level increases the amount of damage done.",
    notifCommit : '$1 attacks three times!',
    notifFail : Arts.NO_NOTIF,
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL | TRAITS.MULTIHIT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage::(level, user) <- user.stats.ATK * (0.4 + (level-1)*0.07),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      
      windowEvent.queueCustom(
        onEnter :: {
          
          @target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
          user.attack(
            target,
            damage: Damage.new(
              amount:Arts.find(:'base:triplestrike').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP,
              isMultihit : true
            ),
            targetPart: targetParts[(user.battle.getEnemies(:user))->findIndex(value:target)],
            targetDefendPart:targetDefendParts[(user.battle.getEnemies(:user))->findIndex(value:target)]
          );
        }
      ); 


      windowEvent.queueCustom(
        onEnter :: {
          @:target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
          user.attack(
            target,
            damage: Damage.new(
              amount:Arts.find(:'base:triplestrike').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP,
              isMultihit : true
            ),
            targetPart: targetParts[(user.battle.getEnemies(:user))->findIndex(value:target)],
            targetDefendPart:targetDefendParts[(user.battle.getEnemies(:user))->findIndex(value:target)]
          );
        }
      );

      windowEvent.queueCustom(
        onEnter :: {
          @:target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
          user.attack(
            target,
            damage: Damage.new(
              amount:Arts.find(:'base:triplestrike').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP,
              isMultihit : true
            ),
            targetPart: targetParts[(user.battle.getEnemies(:user))->findIndex(value:target)],
            targetDefendPart:targetDefendParts[(user.battle.getEnemies(:user))->findIndex(value:target)]
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
    notifCommit : '$1 focuses their perception!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Grants the Focus Perception effect to the user for 5 turns.",
    keywords : ['base:focus-perception'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 cheers on their allies!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLALLY,
    description: "Grants the Cheered effect to allies for 5 turns.",
    keywords : ['base:cheered'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.COMMON,
    traits : 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          foreach(user.battle.getAllies(:user))::(index, ally) {
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
    notifCommit : '$1\'s Lunar Blessing made it night time!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Puts all of the combatants into stasis until it is night time. Additional levels have no effect.",
    durationTurns: 0,
    keywords : [],
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {

      @:world = import(module:'game_singleton.world.mt');
      windowEvent.queueCustom(
        onEnter :: {

          {:::} {
            forever ::{
              world.incrementTime();
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
    notifCommit : '$1\'s Solar Blessing made it day time!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Puts all of the combatants into stasis until it is morning. Additional levels have no effect.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    traits : TRAITS.MAGIC,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      windowEvent.queueCustom(
        onEnter :: {

          {:::} {
            forever ::{
              world.incrementTime();
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
    notifCommit : '$1 fires a glowing beam of moonlight!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Damages a target with Fire based on the user's INT. If night time, the damage is boosted. Additional levels boost the damage further.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.FIRE,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {
      @:world = import(module:'game_singleton.world.mt');
      return user.stats.INT * (if (world.time >= world.TIME.EVENING) 1.4 else 0.8) * (1 + (level-1)*0.05);
    },
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
            damage: Damage.new(
              amount: Arts.find(:'base:moonbeam').baseDamage(user, level),
              damageType : Damage.TYPE.FIRE,
              damageClass: Damage.CLASS.HP
            ),
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
    notifCommit : '$1 fires a glowing beam of sunlight!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Damages a target with Fire based on the user's INT. If day time, the damage is boosted.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.FIRE,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {
      @:world = import(module:'game_singleton.world.mt');
      return user.stats.INT * (if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) 1.4 else 0.8) * (1 + (level-1)*0.05);    
    },
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
            damage: Damage.new(
              amount:Arts.find(:'base:sunbeam').baseDamage(level, user),
              damageType : Damage.TYPE.FIRE,
              damageClass: Damage.CLASS.HP
            ),
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
    notifCommit : '$1 lets loose a burst of sunlight!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Damages all enemies with Fire based on the user's INT. If day time, the damage is boosted.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    traits : TRAITS.MAGIC | TRAITS.FIRE,
    baseDamage ::(level, user) {
      @:world = import(module:'game_singleton.world.mt');
      return user.stats.INT * (if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) 1.7 else 0.4) * (1 + (level-1)*.08);
    },
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
        windowEvent.queueMessage(
          text: 'The blast shines brightly!'
        );                  
      }
      

      
      foreach((user.battle.getEnemies(:user)))::(index, enemy) {
        windowEvent.queueCustom(
          onEnter :: {

            user.attack(
              target: enemy,
              damage: Damage.new(
                amount: Arts.find(:'base:sunburst').baseDamage(level, user),
                damageType : Damage.TYPE.FIRE,
                damageClass: Damage.CLASS.HP
              )
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
    notifCommit : '$1 casts Night Veil on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Night Veil effect to a target for 5 turns. If casted during night time, it's much more powerful.",
    keywords : ['base:night-veil', 'base:greater-night-veil'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.UNCOMMON,
    traits : TRAITS.MAGIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
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
    notifCommit : '$1 casts Dayshroud on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Dayshroud effect to a target for 5 turns. If casted during day time, it's much more powerful.",
    keywords : ['base:dayshroud', 'base:greater-dayshroud'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.UNCOMMON,
    traits : TRAITS.MAGIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      
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
    notifCommit : '$1 casts Call of the Night on $2!',
    notifFail : Arts.NO_NOTIF,
    id : 'base:call-of-the-night',
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Call of the Night effect to a target for 5 turns. If casted during night time, it's much more powerful.",
    keywords : ['base:call-of-the-night', 'base:greater-call-of-the-night'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.UNCOMMON,
    traits : TRAITS.MAGIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 casts Lunacy on $2!',
    notifFail : '... But nothing happens!',
    targetMode : TARGET_MODE.ONE,
    description: "Inflicts the Lunacy effect on target. Only can be casted at night.",
    keywords : ['base:lunacy'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.RARE,
    traits : TRAITS.MAGIC,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      when (world.time < world.TIME.EVENING) Arts.FAIL;
      windowEvent.queueMessage(
        text: targets[0].name + ' shimmers brightly!'
      );                  
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:lunacy', durationTurns: 7);
        }
      )
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Moonsong',
    id : 'base:moonsong',
    notifCommit : '$1 casts Moonsong on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Moonsong effect on a target. If casted during night time, it's much more powerful.",
    keywords : ['base:moonsong', 'base:greater-moonsong'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.UNCOMMON,
    traits : TRAITS.MAGIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      
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
    notifCommit : '$1 casts Sol Attunement on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Sol Attunement effect to a target. If casted during day time, it's much more powerful.",
    keywords : ['base:sol-attunement', 'base:greater-sol-attunement'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.UNCOMMON,
    traits : TRAITS.MAGIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
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
    notifCommit : '$1 tries to ensnare $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Damages a target and Ensnares both the user and the target for 3 turns with an 80% success rate. Damage done increases with additional levels.",
    keywords : ['base:ensnaring', 'base:ensnared'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    rarity : RARITY.UNCOMMON,
    traits : TRAITS.PHYSICAL,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      
      windowEvent.queueCustom(
        onEnter :: {
          if (user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:user.stats.ATK * (0.3 + (level-1)*0.05),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    notifCommit : '$1 makes an eerie call!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.NONE,
    description: "Calls a creature to come and join the fight. Additional levels increase chances of success.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      when (!random.try(percentSuccess:50+(level-1)*10)) Arts.FAIL;
      
      @:world = import(module:'game_singleton.world.mt');
    
      @help = world.island.newHostileCreature();
      @battle = user.battle;
      
      windowEvent.queueCustom(
        onEnter :: {

          battle.join(
            group: [help],
            sameGroupAs:user
          );
        }
      )
                    
    }
  }
) 



Arts.newEntry(
  data: {
    name: 'Tame',
    id : 'base:tame',
    notifCommit : '$1 attempts to tame $2',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Attempts to tame a creature, making it a party member if successful. Additional levels increase chances of success.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {

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
    notifCommit : '$1 tries to sweep everyone\'s legs!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Swings, aiming for all enemies legs in hopes of stunning them for a turn.",
    keywords : ['base:stunned'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      foreach((user.battle.getEnemies(:user)))::(i, enemy) {
        windowEvent.queueCustom(
          onEnter :: {

            if (user.attack(
              target:enemy,
              damage: Damage.new(
                amount:user.stats.ATK * (0.3),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
              ),
              targetPart:Entity.DAMAGE_TARGET.LIMBS,
              targetDefendPart:targetDefendParts[i]
            ) == true)
              if (random.number() > 0.5)
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
    notifCommit : '$1 does a big swing!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Damages targets based on the user's strength. Additional levels increase the power.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage ::(level, user) <- user.stats.ATK * (0.35) * (1 + (level-1)*.05),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      foreach(targets)::(index, target) {
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target,
              damage: Damage.new(
                amount:Arts.find(:'base:big-swing').baseDamage(level, user),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
              ),
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
    notifCommit : '$1 bashes $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Damages a target based on the user's strength. Has a chance to Grapple the user and the target for a turn. Additional levels increase the power.",
    keywords : ['base:grappling', 'base:grappled'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage ::(level, user) <- user.stats.ATK * (0.7) * (1 + (level-1)*0.1),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {

      windowEvent.queueCustom(
        onEnter :: {

          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:Arts.find(:'base:tackle').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Damages a target by throwing an item. The base damage is boosted by the weight of the item chosen. Additional levels increase the damage done.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    rarity : RARITY.UNCOMMON,
    canBlock : true,
    traits : TRAITS.PHYSICAL,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    baseDamage ::(level, user) <- user.stats.ATK * (0.7) * (1 + (level-1)*0.2),
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
            damage: Damage.new(
              amount:Arts.find(:'base:throw-item').baseDamage(level, user) * (item.base.weight * 4),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    notifCommit : '$1 tries to stun $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Damages a target based on the user's strength with a chance to Stun for a turn. Further levels increase the stun chance.",
    keywords : ['base:stunned'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage::(level, user) <- user.stats.ATK * (0.3),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          
          if (user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:Arts.find(:'base:stun').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    notifCommit : 'A cold air emanates from $1!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Multi-hit attack that damages a target with an ice attack. 90% chance to Freeze. Additional levels increase its power.",
    keywords : ['base:frozen'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.ICE | TRAITS.MULTIHIT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage ::(level, user) <- user.stats.ATK * (0.4) * (1 + (level-1)*0.07),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {

      windowEvent.queueCustom(
        onEnter :: {

          if (user.attack(
            target:targets[0],
            damage: Damage.new(          
              amount:Arts.find(:'base:sheer-cold').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP,
              isMultihit : true
            ),
            targetPart: targetParts[0],
            targetDefendPart:targetDefendParts[0]
          ) == true)          
            if (random.number() < 0.9)
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
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    notifCommit : '$1 casts Flight on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Flight effect on a target for a turn. The effect lasts an additional turn for each level.",
    keywords : ['base:flight'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:flight', durationTurns: level);
        }
      )
    }
  }
)     
Arts.newEntry(
  data: {
    name: 'Grapple',
    id : 'base:grapple',
    notifCommit : '$1 tries to grapple $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Immobilizes both the user and the target for 3 turns. 65% success rate. Each level increases the success rate by 10%",
    keywords : ['base:grappled', 'base:grappling'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      
      windowEvent.queueCustom(
        onEnter :: {

          if (random.try(percentSuccess:55 + level*10)) ::<= {
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
    notifCommit : '$1 does a combo strike $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Multi-hit attack that damages the same target twice at the same target and location. Additional levels increases the power.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL | TRAITS.MULTIHIT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage ::(level, user) <- user.stats.ATK * (0.35) * (1 + (level-1)*0.05),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      
      windowEvent.queueCustom(
        onEnter :: {
          
          user.attack(
            target: targets[0],
            damage: Damage.new(
              amount: Arts.find(:'base:combo-strike').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP,
              isMultihit : true
            ),
            targetPart: targetParts[0],
            targetDefendPart:targetDefendParts[0]
          );
        }
      );

      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target: targets[0],
            damage: Damage.new(
              amount:Arts.find(:'base:combo-strike').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP,
              isMultihit : true
            ),
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
    notifCommit : '$1 casts Poison Rune on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Places a Poison Rune on a target. The rune lasts 10 turns.",
    keywords : ['base:poison-rune'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 releases all the runes on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Removes all Rune effects from a target.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {

      windowEvent.queueCustom(
        onEnter :: {
          targets[0].removeEffects(
            :[
              'base:poison-rune',
              'base:destruction-rune',
              'base:regeneration-rune',
              'base:cure-rune',
              'base:shield-rune'               
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
    notifCommit : '$1 casts Destruction Rune on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Places a Destruction Rune on a target. The rune lasts for 5 turns.",
    keywords : ['base:destruction-rune'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage::(level, user) <- user.stats.INT * (1.2),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:destruction-rune', durationTurns: 5);            
        }
      );
    }
  }
)     


Arts.newEntry(
  data: {
    name: 'Regeneration Rune',
    id : 'base:regeneration-rune',
    notifCommit : '$1 casts Regeneration Rune on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Places a Regeneration Rune on a target. The rune lasts for 10 turns.",
    keywords : ['base:regeneration-rune'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.UNCOMMON,
    traits : TRAITS.MAGIC,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 casts Shield Rune on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Places a Shield Rune on a target. The rune lasts for 10 turns.",
    keywords : ['base:shield-rune'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 casts Cure Rune on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Places a Cure Rune on a target. The rune lasts for 5 turns.",
    keywords : ['base:cure-rune'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:cure-rune', durationTurns: 5);            
        }
      )
    }
  }
)       

Arts.newEntry(
  data: {
    name: 'Multiply Runes',
    id : 'base:multiply-runes',
    notifCommit : '$1 casts Multiply Runes on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Doubles all current runes on a target.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
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
    notifCommit : '$1 prepares a poison attack against $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Damages a target based on the user's ATK with a poisoned weapon. Additional levels increase the damage done.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL | TRAITS.POISON,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage ::(level, user)<- user.stats.ATK * (0.3) * (1 + (level-1)*0.05),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {

          if (user.attack(
            target: targets[0],
            damage: Damage.new(
              amount: Arts.find(:'base:poison-attack').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    notifCommit : '$1 prepares a petrifying attack against $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Damages a target based on the user's ATK with special Light energy, causing the Petrified effect for 2 turns. Additional levels increase the power of the Art.",
    keywords : ['base:petrified'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL | TRAITS.LIGHT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage::(level, user) <- user.stats.ATK * (0.3) * (1 + (level-1)*0.05),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {

          if (user.attack(
            target: targets[0],
            damage: Damage.new(
              amount: Arts.find(:'base:petrify').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
            targetPart: targetParts[0],
            targetDefendPart:targetDefendParts[0]
          ))
            if (random.flipCoin())
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
    notifCommit : '$1 activates the tripwire right under $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Activates a tripwire set up prior to battle, causing the target to be stunned for 3 turns. Only works once per battle.",
    keywords : ['base:stunned'],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.UNCOMMON,
    canBlock : false,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      breakpoint();
    },
    oncePerBattle : true,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:stunned', durationTurns: 2);            
        }
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Trip Explosive',
    id : 'base:trip-explosive',
    notifCommit : '$1 activates the tripwire explosive right under $2!',
    notifFail : '$2 avoided the trap!',
    targetMode : TARGET_MODE.ONE,
    description: "Activates a tripwire-activated explosive set up prior to battle, causing the target to be damaged. Only works once per battle.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.REACTION,
    rarity : RARITY.RARE,
    traits : TRAITS.PHYSICAL,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : true,
    canBlock : false,
    baseDamage::(level, user) <- 15,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      when(random.try(percentSuccess:30)) Arts.FAIL;
      windowEvent.queueCustom(
        onEnter :: {

          targets[0].damage(attacker:user, damage:Damage.new(
            amount:15,
            damageType:Damage.TYPE.FIRE,
            damageClass:Damage.CLASS.HP
          ),dodgeable: false);  
        }
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Spike Pit',
    id : 'base:spike-pit',
    notifCommit : '$1 activates a floor trap, revealing a spike pit under their enemies!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Activates a floor trap leading to a spike pit which damages and stuns for 2 turns. Only works once per battle.",
    keywords : ['base:stunned'],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : true,
    canBlock : false,
    baseDamage::(level, user) <- 10,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      
      foreach(targets)::(i, target) {
        windowEvent.queueCustom(
          onEnter :: {

            when(random.try(percentSuccess:30)) ::<= {
              windowEvent.queueMessage(
                text: target.name + ' avoided the trap!'
              );                
            }
            target.damage(attacker:user, damage:Damage.new(
              amount:15,
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
    notifCommit : '$1 stabs $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Damages a target based on the user's ATK and causes Bleeding. Additional levels increases the power of the move.",
    keywords : ['base:bleeding'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage::(level, user) <- user.stats.ATK * (0.3) * (1 + (level-1)*0.07),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          if (user.attack(
            target: targets[0],
            damage: Damage.new(
              amount: Arts.find(:'base:stab').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    notifCommit : '$1 does first aid $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Heals a target by 3 HP. Additional levels increase the potency by 2 points.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.HEAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].heal(amount:1 + level*2);
        }
      )
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Mend',
    id : 'base:mend',
    notifCommit : '$1 mends $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Heals a target by 2 HP.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.HEAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].heal(amount:2);
        }
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Give Snack',
    id : 'base:give-snack',
    notifCommit : '$1 gives a snack to $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Either heals or recovers AP by a small amount.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.HEAL,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {        
      @:chance = random.number();
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
                amount:3 
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
    notifCommit : '$1 summons a Fire Sprite!',
    notifFail : '...but the summoning fizzled!',
    targetMode : TARGET_MODE.NONE,
    description: 'Summons a fire sprite to fight on your side. Additional levels makes the summoning stronger. If 2 or more summons exist on the user\'s side of battle, the summoning fails.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      @:Species = import(module:'game_database.species.mt');

      // limit 2 summons at a time.
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAITS.SUMMON) != 0)->size >= 2
      ) Arts.FAIL


      @:Entity = import(module:'game_class.entity.mt');
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
    notifCommit : '$1 summons an Ice Elemental!',
    notifFail : '...but the summoning fizzled!',
    targetMode : TARGET_MODE.NONE,
    description: 'Summons an ice elemental to fight on your side. Additional levels makes the summoning stronger. If 2 or more summons exist on the user\'s side of battle, the summoning fails.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Species = import(module:'game_database.species.mt');
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAITS.SUMMON) != 0)->size >= 2
      ) Arts.FAIL;


      
      @:Entity = import(module:'game_class.entity.mt');
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
    notifCommit : '$1 summons a Thunder Spawn!',
    notifFail : '...but the summoning fizzled!',
    targetMode : TARGET_MODE.NONE,
    description: 'Summons a thunder spawn to fight on your side. Additional levels makes the summoning stronger. If 2 or more summons exist on the user\'s side of battle, the summoning fails.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Species = import(module:'game_database.species.mt');
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAITS.SUMMON) != 0)->size >= 2
      ) Arts.FAIL;
      
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
    notifCommit : '$1 summons a Guiding Light!',
    notifFail : '...but the summoning fizzled!',
    targetMode : TARGET_MODE.NONE,
    description: 'Summons a guiding light to fight on the user\'s side. Additional levels makes the summoning stronger. If 2 or more summons exist on the user\'s side of battle, the summoning fails.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Species = import(module:'game_database.species.mt');
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAITS.SUMMON) != 0)->size >= 2
      ) Arts.FAIL;
      
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
    notifCommit : '$1 casts Unsummon!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: 'Magick that removes all summoned enemies from battle.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        @:Species = import(module:'game_database.species.mt');
        return [...enemies]->filter(::(value) <- (value.species.traits & Species.TRAITS.SUMMON) != 0)->size > 0;
    },
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Species = import(module:'game_database.species.mt');

      windowEvent.queueMessage(
        text: user.name + ' casts Unsummon!'
      );

      windowEvent.queueCustom(
        onEnter :: {
          foreach(targets) ::(k, target) {
            if ((target.species.traits & Species.TRAITS.SUMMON) != 0) ::<= {
              windowEvent.queueMessage(
                text: target.name + ' faded into nothingness!'
              );              
              target.kill(silent:true);  
            } else ::<= {
              windowEvent.queueMessage(
                text: target.name + ' was unaffected!'
              );                            
            }
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
    notifCommit : '$1 casts Fire on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Magick that damages a target with fire based on INT. Additional levels increase its potency.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.FIRE,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- user.stats.INT * (1.2) * (1 + (level-1)*0.15),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:Arts.find(:'base:fire').baseDamage(level, user),
              damageType : Damage.TYPE.FIRE,
              damageClass: Damage.CLASS.HP
            )
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
    notifCommit : '$1 generates a great amount of heat!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: 'Using great amount of heat, gives targets the Burned effect. Damage is based on INT. Additional levels increases the potency.',
    keywords : ['base:burned'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.FIRE,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- user.stats.INT * (0.6) * (1 + (level-1)*0.08),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      
      foreach(targets)::(i, target) {
        windowEvent.queueCustom(
          onEnter :: {
            if (user.attack(
              target:target,
              damage: Damage.new(
                amount: Arts.find(:'base:backdraft').baseDamage(level, user),
                damageType : Damage.TYPE.FIRE,
                damageClass: Damage.CLASS.HP
              )
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
    notifCommit : '$1 casts Flare on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Magick that greatly damages a target with fire based on INT. Additional levels increase the destructive power.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.FIRE,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- user.stats.INT * (2.0) * (1 + (level-1) * 0.15),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount: Arts.find(:'base:flare').baseDamage(level, user),
              damageType : Damage.TYPE.FIRE,
              damageClass: Damage.CLASS.HP
            )
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
    notifCommit : '$1 casts Dematerialize on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Magick that unequips a target\'s equipment',
    keywords : [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.RARE,
    traits : TRAITS.MAGIC,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        return [...enemies]->filter(::(value) <- {:::} {
          foreach(Entity.EQUIP_SLOTS)::(i, slot) {
            @out = value.getEquipped(slot);
            if (out != empty && out.base.name != 'base:none') send(:true);
          }        
          return false
        })
    },
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Entity = import(module:'game_class.entity.mt');
      @:Random = import(module:'game_singleton.random.mt');
      @:item = ::<= {
        @:list = [];
        foreach(Entity.EQUIP_SLOTS)::(i, slot) {
          @out = targets[0].getEquipped(slot);
          if (out != empty && out.base.name != 'base:none')
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
          @:world = import(module:'game_singleton.world.mt');      
          targets[0].unequipItem(item);
          if (world.party.isMember(entity:targets[0]))
            world.party.inventory.add(item);
          
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
    notifCommit : '$1 casts Ice!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: 'Multi-hit magick that damages all enemies with ice based on INT.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.ICE | TRAITS.MULTIHIT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- user.stats.INT * (0.6 + (0.2)*(level-1)),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      foreach((user.battle.getEnemies(:user)))::(index, enemy) {
        windowEvent.queueCustom(
          onEnter :: {

            user.attack(
              target:enemy,
              damage: Damage.new(
                amount: Arts.find(:'base:ice').baseDamage(level, user),
                damageType : Damage.TYPE.ICE,
                damageClass: Damage.CLASS.HP,
                isMultihit : true
              )
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
    notifCommit : '$1 casts Frozen Flame!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: 'Multi-hit magick that causes enemies to spontaneously combust in a cold, blue flame. Damage is based on INT with an additional chance to Freeze the hit targets. Additional levels increase damage.',
    keywords : ['base:frozen'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.ICE | TRAITS.MULTIHIT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- user.stats.INT * (0.75) * (1 + (level-1)* 0.15),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      foreach((user.battle.getEnemies(:user)))::(index, enemy) {
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target:enemy,
              damage: Damage.new(
                amount: Arts.find(:'base:frozen-flame').baseDamage(level, user),
                damageType : Damage.TYPE.ICE,
                damageClass: Damage.CLASS.HP,
                isMultihit : true
              )
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
    notifCommit : '$1 casts Telekinesis on $2!',
    notifFail : '...But it missed!',
    targetMode : TARGET_MODE.ONE,
    description: 'Magick that moves a target around, stunning them 50% of the time for a turn. Stunning chance increases with levels.',
    keywords : ['base:stunned'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      when (!random.try(percentSuccess:40 + level*10)) Arts.FAIL;

      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:stunned', durationTurns: 1)             
        }
      )

    }
  }
)      


Arts.newEntry(
  data: {
    name: 'Explosion',
    id : 'base:explosion',
    notifCommit : '$1 casts Explosion!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: 'Multi-hit magick that damages all enemies with fire based on the user\'s INT. Additional levels increase the damage.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.FIRE | TRAITS.MULTIHIT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- user.stats.INT * (0.85) * (1 + (level-1)*0.1),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      foreach((user.battle.getEnemies(:user)))::(index, enemy) {
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target:enemy,
              damage: Damage.new(
                amount:Arts.find(:'base:explosion').baseDamage(level, user),
                damageType : Damage.TYPE.FIRE,
                damageClass: Damage.CLASS.HP,
                isMultihit : true
              )
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
    notifCommit : '$1 casts Flash!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: 'Magick that blinds all enemies with a bright light. 50% chance to cause blindness, additional levels increase the chance.',
    keywords : ['base:blind'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' casts Flash!'
      );
      foreach((user.battle.getEnemies(:user)))::(index, enemy) {
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
    notifCommit : '$1 casts Thunder!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: 'Multi-hit magick that deals 4 random strikes based on INT. Each additional level deals an additional 2 strikes.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.THUNDER | TRAITS.MULTIHIT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- user.stats.INT * (0.45),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      for(0, 4 + (level-1)*2)::(index) {
        @:target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target,
              damage: Damage.new(
                amount:Arts.find(:'base:thunder').baseDamage(level, user),
                damageType : Damage.TYPE.THUNDER,
                damageClass: Damage.CLASS.HP,
                isMultihit : true
              )
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
    notifCommit : '$1 swings wildly!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: 'Multi-hit attack that deals 4 random strikes based on ATK. Additional levels increase the number of strikes.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL | TRAITS.MULTIHIT,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage::(level, user) <- user.stats.ATK * (0.9),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      for(0, 4 + (level-1)*2)::(index) {
        @:target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target,
              damage: Damage.new(
                amount:Arts.find(:'base:wild-swing').baseDamage(level, user),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP,
                isMultihit : true
              ),
              targetPart: Entity.normalizedDamageTarget(),
              targetDefendPart:targetDefendParts[(user.battle.getEnemies(:user))->findIndex(value:target)]
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
    notifCommit : '$1 casts Cure on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Heals a target by 5 HP. Additional levels increase potency by 2 HP.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.HEAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].heal(amount:3 + level*2);
        }
      )
    }
  }
)



Arts.newEntry(
  data: {
    name: 'Cleanse',
    id : 'base:cleanse',
    notifCommit : '$1 casts Cleanse on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Removes all status ailments and most negative effects. Additional levels have no benefit.",
    keywords : ['base:ailment'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.HEAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Effect = import(module:'game_database.effect.mt');
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].removeEffectsByFilter(
            ::(value) <- 
              ((Arts.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0) ||
              ((Arts.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0)
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
    notifCommit : '$1 casts Magic Mist!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Removes all effects from all enemies.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      foreach(targets)::(i, target) {
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
    notifCommit : '$1 casts Cure All!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLALLY,
    description: "Heals all party members by a 3HP. Additional levels increase the effect by 2 HP.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.HEAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      foreach(targets)::(i, target) {
        windowEvent.queueCustom(
          onEnter :: {
            target.heal(amount:1 + level*2);
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
    notifCommit : '$1 casts Protect on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Protect effect to a target for 10 turns.",
    keywords : ['base:protect'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 challenges $2 to a duel!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Dueled effect to a target for the rest of battle.",
    keywords : ['base:dueled'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 casts Grace on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Grace effect to a target for the rest of battle. Additional levels have no effect.",
    keywords : ['base:grace'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.HEAL | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 casts Phoenix Soul on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "If used during day time, grants the Grace effect to a target. Additional levels have no effect.",
    keywords : ['base:grace'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.HEAL,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      when (world.time < world.TIME.MORNING && world.time < world.TIME.EVENING) Arts.FAIL;

      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:grace', durationTurns: 1000)
        }
      )
    }
  }
)      

Arts.newEntry(
  data: {
    name: 'Protect All',
    id : 'base:protect-all',
    notifCommit : '$1 casts Protect All!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLALLY,
    description: "Grants the Protect effect to all allies for 5 turns.",
    keywords : ['base:protect'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' casts Protect All!'
      );
      foreach(user.battle.getAllies(:user))::(index, ally) {
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
    notifCommit : '$1 meditates!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Recovers users AP by a small amount.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.HEAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 casts Soothe on !',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Relaxes a target, healing 4 AP. Additional levels increase this by 2.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.HEAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' casts Soothe on ' + targets[0].name + '!'
      );
      
      windowEvent.queueCustom(
        onEnter :: {
          user.healAP(amount:2 + 2*level);
        }
      );
    }
  }
)



Arts.newEntry(
  data: {
    name: 'Steal',
    id : 'base:steal',
    notifCommit : '$1 attempts to steal from $2',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Steals an item from a target. Additional levels increase the stealing success rate.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
     
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
    notifCommit : '$1 gets ready to counter!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Grants the Counter effect to the user for 3 turns.',
    keywords : ['base:counter'],
    durationTurns: 0,
    kind : KIND.REACTION,
    rarity : RARITY.RARE,
    traits : TRAITS.PHYSICAL,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 attempts to disarm $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Attempts to disarm a target. Base chance is 30%. Additional levels increases the success rate.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      @:Entity = import(module:'game_class.entity.mt');
      
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
        windowEvent.queueMessage(text:user.name + ' failed to disarm ' + targets[0].name + '!');
      
      }

    }
  }
) 


Arts.newEntry(
  data: {
    name: 'Sneak',
    id : 'base:sneak',
    notifCommit : '$1 becomes one with the shadows!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Inflicts the Sneaked status on a target for 2 turns.',
    keywords : ['base:sneaked'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 begins to focus!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Grants the Mind Focused status to the user for 5 turns.',
    keywords : ['base:mind-focused'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 gets ready to defend!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Grants the Defend effect for one turn.',
    keywords : ['base:defend'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 gets ready to guard themself!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Grants the Guard effect for one turn.',
    keywords : ['base:guard'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 tells everyone to be wary!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLALLY,
    description: 'Grants the Cautious effect to all allies for 10 turns.',
    keywords : ['base:cautious'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      foreach(targets) ::(k, v) {
        windowEvent.queueCustom(
          onEnter :: {
            v.addEffect(from:user, id: 'base:cautious', durationTurns:10);
          }
        )
      }
    }
  }
)



Arts.newEntry(
  data: {
    name: 'Defensive Stance',
    id : 'base:defensive-stance',
    targetMode : TARGET_MODE.NONE,
    notifCommit : '$1 changes stances!',
    notifFail : Arts.NO_NOTIF,
    description: 'Removes all Stance effects. Grants the Defensive Stance effect for the rest of battle.',
    keywords : ['base:defensive-stance'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          @:Effect = import(module:'game_database.effect.mt');
          @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
          user.removeEffects(effectBases:stances);
          user.addEffect(from:user, id: 'base:defensive-stance', durationTurns:1000000);
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
    notifCommit : '$1 changes stances!',
    notifFail : Arts.NO_NOTIF,
    description: 'Removes all Stance effects. Grants the Offensive Stance effect for the rest of battle.',
    keywords : ['base:offensive-stance'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Effect = import(module:'game_database.effect.mt');
      @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));

      windowEvent.queueCustom(
        onEnter :: {
          user.removeEffects(effectBases:stances);
          user.addEffect(from:user, id: 'base:offensive-stance', durationTurns:1000000);
        }
      )
    }
  }
)      

Arts.newEntry(
  data: {
    name: 'Light Stance',
    id : 'base:light-stance',
    notifCommit : '$1 changes stances!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Removes all Stance effects. Grants the Light Stance effect for the rest of battle.',
    keywords : ['base:light-stance'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Effect = import(module:'game_database.effect.mt');
      @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
      windowEvent.queueCustom(
        onEnter :: {
          user.removeEffects(effectBases:stances);
          user.addEffect(from:user, id: 'base:light-stance', durationTurns:1000000);
        }
      )
    }
  }
)      

Arts.newEntry(
  data: {
    name: 'Heavy Stance',
    id : 'base:heavy-stance',
    notifCommit : '$1 changes stances!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Removes all Stance effects. Grants the Heavy Stance effect for the rest of battle.',
    keywords : ['base:heavy-stance'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.UNCOMMON,
    traits : 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Effect = import(module:'game_database.effect.mt');
      @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
      windowEvent.queueCustom(
        onEnter :: {
          user.removeEffects(effectBases:stances);
          user.addEffect(from:user, id: 'base:heavy-stance', durationTurns:1000000);
        }
      )
    }
  }
) 

Arts.newEntry(
  data: {
    name: 'Meditative Stance',
    id : 'base:meditative-stance',
    notifCommit : '$1 changes stances!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Removes all Stance effects. Grants the Meditative Stance effect for the rest of battle.',
    keywords : ['base:meditative-stance'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.UNCOMMON,
    traits : 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Effect = import(module:'game_database.effect.mt');
      @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
      windowEvent.queueCustom(
        onEnter :: {
          user.removeEffects(effectBases:stances);
          user.addEffect(from:user, id: 'base:meditative-stance', durationTurns:1000000);
        }
      );
    }
  }
)         

Arts.newEntry(
  data: {
    name: 'Striking Stance',
    id : 'base:striking-stance',
    notifCommit : '$1 changes stances!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Removes all Stance effects. Grants the Striking Stance effect for the rest of battle.',
    keywords : ['base:striking-stance'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Effect = import(module:'game_database.effect.mt');
      @:stances = Effect.getAll()->filter(by:::(value) <- value.name->contains(key:'Stance'));
      windowEvent.queueCustom(
        onEnter :: {
          user.removeEffects(effectBases:stances);
          user.addEffect(from:user, id: 'base:striking-stance', durationTurns:1000000);
        }
      )
    }
  }
)  


Arts.newEntry(
  data: {
    name: 'Reflective Stance',
    id : 'base:reflective-stance',
    notifCommit : '$1 changes stances!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Removes all Stance effects. Grants the Reflective Stance effect for the rest of battle.',
    keywords : ['base:reflective-stance'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 changes stances!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Removes all Stance effects. Grants the Evasive Stance effect for the rest of battle.',
    keywords : ['base:evasive-stance'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 waits.',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Does nothing.',
    keywords : [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    traits : TRAITS.SPECIAL | TRAITS.COSTLESS,
    kind : KIND.ABILITY,
    rarity : RARITY.COMMON,
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      user.healAP(amount:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Plant Poisonroot',
    id : 'base:plant-poisonroot',
    notifCommit : '$2 was covered in poisonroot seeds!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Plants a poisonroot seed on the target. The poisonroot grows in 4 turns.",
    keywords : ['base:poisonroot-growing', 'base:poisonroot'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$2 was covered in triproot seeds!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Plants a triproot seed on the target. The triproot grows in 4 turns.",
    keywords : ['base:triproot-growing', 'base:triproot'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$2 was covered in healroot seeds!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Plants a healroot seed on the target. The healroot grows in 4 turns.",
    keywords : ['base:healroot-growing', 'base:healroot'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 attempts to magically grow seeds on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Any growing roots grow instantly on the target.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.EPIC,
    usageHintAI: USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 becomes shrouded in flame!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Adds the Burning effect to the user for 4 turns.",
    keywords : ['base:burning'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC | TRAITS.FIRE,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.addEffect(from:user, id:'base:burning', durationTurns:4);              
        }
      )
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Elemental Tag',
    id : 'base:elemental-tag',
    notifCommit : '$1 casts Elemental Tag on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Inflicts the Elemental Tag status on target for 20 turns.",
    keywords : ['base:elemental-tag'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 casts Elemental Shield!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Grants the Elemental Shield status on target for 5 turns.",
    keywords : ['base:elemental-tag'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 becomes shrouded in an icy wind!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Adds the Icy effect to the user for 4 turns.",
    keywords : ['base:icy'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC | TRAITS.ICE,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.addEffect(from:user, id:'base:icy', durationTurns:4);              
        }
      )
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Thunder Shift',
    id : 'base:thunder-shift',
    notifCommit : '$1 becomes shrouded in electric arcs!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Adds the Shock effect to the user for 4 turns.",
    keywords : ['base:shock'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC | TRAITS.THUNDER,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.addEffect(from:user, id:'base:shock', durationTurns:4);              
        }
      )
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Tri Shift',
    id : 'base:tri-shift',
    notifCommit : '$1 becomes shrouded in light!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Adds the Shock, Burning, and Icy effects to the user.",
    keywords : ['base:burning', 'base:icy', 'base:shock'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {

          user.addEffect(from:user, id:'base:burning', durationTurns:4);              
          user.addEffect(from:user, id:'base:icy',   durationTurns:4);              
          user.addEffect(from:user, id:'base:shock',   durationTurns:4);              
        }
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Use Item',
    id : 'base:use-item',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Uses an item from the user's inventory.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : 0,
    rarity : RARITY.RARE,
    isSupport: false,
    usageHintAI: USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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



Arts.newEntry(
  data: {
    name: 'Equip Item',
    id : 'base:equip-item',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Equips an item from the user's inventory.",
    keywords : [],
    durationTurns: 0,
    hpCost : 0,
    apCost : 0,
    kind : KIND.ABILITY,
    traits : TRAITS.SPECIAL | TRAITS.COSTLESS,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(user, level, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:item = extraData[0];
      user.equip(
        item, 
        slot:user.getSlotsForItem(item)[0], 
        inventory:extraData[1]
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Defend Other',
    id : 'base:defend-other',
    notifCommit : '$1 is prepared to defend $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Defend Other effect to a target for 4 turns.",
    keywords : ['base:defend-other'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 casts Perfect Guard on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Perfect Guard effect to a target for 3 turns. Additional levels have no effect.",
    keywords : ['base:perfect-guard'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 attempts to sharpen $2\'s weapon!',
    notifFail : '$2 has no weapon to sharpen!',
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Sharpen effect to a target if they have a weapon equipped.",
    keywords : ['base:sharpen'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        allies = [...allies]->filter(::(value) <- value.getEquipped(
            :Entity.EQUIP_SLOTS.ARMOR
        ).base.id != 'base:none');
        when(allies->size == 0) false;        
        return [random.pickArrayItem(:allies)];    
    },
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Entity = import(module:'game_class.entity.mt');
      when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR).base.name == 'None')
        Arts.FAIL;

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
    notifCommit : '$1 attempts to weaken $2\'s armor!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Inflicts the Weaken Armor effect on a target if the target is wearing armor.",
    keywords : ['base:weaken-armor'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        enemies = [...enemies]->filter(::(value) <- value.getEquipped(
            :Entity.EQUIP_SLOTS.HAND_LR
        ).base.id != 'base:none');
        when(enemies->size == 0) false;
        return [random.pickArrayItem(:enemies)];    
    },
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Entity = import(module:'game_class.entity.mt');
      when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.ARMOR).base.name == 'None')
        windowEvent.queueMessage(text:targets[0].name + ' has no armor to weaken!');          

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
    notifCommit : '$1 attempts to dull $2\'s weapon!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Inflicts the Dull Weapon effect on a target if the target is using a weapon.",
    keywords : ['base:dull-weapon'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        enemies = [...enemies]->filter(::(value) <- value.getEquipped(
            :Entity.EQUIP_SLOTS.HAND_LR
        ).base.id != 'base:none');
        when(enemies->size == 0) false;
        return [random.pickArrayItem(:enemies)];
    },
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Entity = import(module:'game_class.entity.mt');
      when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR).base.name == 'None')
        windowEvent.queueMessage(text:targets[0].name + ' has no weapon to dull!');          

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
    notifCommit : '$1 attempts to strengthen $2\'s armor!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grants the Strengthen Armor effect to a target if they have armor equipped.",
    keywords : ['base:strengthen-armor'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        allies = [...allies]->filter(::(value) <- value.getEquipped(
            :Entity.EQUIP_SLOTS.ARMOR
        ).base.id != 'base:none');
        when(allies->size == 0) false;
        return [random.pickArrayItem(:allies)];
    },
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Entity = import(module:'game_class.entity.mt');
      when (targets[0].getEquipped(slot:Entity.EQUIP_SLOTS.ARMOR).base.name == 'None')
        windowEvent.queueMessage(text:targets[0].name + ' has no armor to strengthen!');          


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
    notifCommit : '$1 tries to convince $2 to wait!',
    notifFail : '$2 ignored $1!',
    targetMode : TARGET_MODE.ONE,
    description: "50% chance to inflict the Convinced status on the target for 1 to 3 turns. Additional levels increase the success chance by 10%.",
    keywords : ['base:convinced'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      
      when(random.try(percentSuccess:50 - (level-1)*10)) Arts.FAIL;


      windowEvent.queueMessage(text:targets[0].name + ' listens intently!');
      targets[0].addEffect(
        from:user, id: 'base:convinced', durationTurns: 1+(random.number()*3)->floor 
      )
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Pink Brew',
    id : 'base:pink-brew',
    notifCommit : '$1 attempts to make a potion!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Uses 2 Ingredients to make a pink potion.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 attempts to make a potion!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Uses 2 Ingredients to make a cyan potion.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 attempts to make a potion!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Uses 2 Ingredients to make a green potion.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 attempts to make a potion!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Uses 2 Ingredients to make an orange potion.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 attempts to make a potion!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Uses 2 Ingredients to make a purple potion.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 looked around and found an Ingredient!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Searches the area for an Ingredient to make potions.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
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
    notifCommit : '$1 attempts to make a potion!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Uses 2 Ingredients to make a black potion.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 tries to bribe $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Pays a combatant to not fight any more. Additional levels decrease the required cost.",
    keywords: ['base:bribed'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    rarity : RARITY.RARE,
    traits : 0,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      when (user.battle.getAllies(:user)->any(condition:::(value) <- value == targets[0]))
        windowEvent.queueMessage(text: "Are you... trying to bribe me? we're... we're on the same team..");
        
      @:cost = ((targets[0].level*100 + targets[0].stats.sum * 4) * (1 - (level-1)*0.08))->ceil;

      @:world = import(module:'game_singleton.world.mt');

      
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
          when (random.try(percentSuccess:20))
            windowEvent.queueCustom(
              onEnter :: {
                targets[0].addEffect(
                  from:user, id: 'base:bribed', durationTurns: -1
                );                     
              }
            )

          windowEvent.queueMessage(text: targets[0].name + ' ignored the ' + g(g:cost) + " bribe!");
        }
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Sweet Song',
    id : 'base:sweet-song',
    notifCommit : '$1 sings a haunting, sweet song!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: 'Alluring song that captivates the listener.',
    keywords: ['base:mesmerized'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      foreach((user.battle.getEnemies(:user)))::(index, enemy) {
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
    notifCommit : '$1 tries to coil around $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Wraps around one enemy, followed by ????',
    keywords: ['base:wrapped'],
    durationTurns: 2,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL | TRAITS.SPECIAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      when(turnIndex == 0) ::<= {

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
      notifCommit : '$1 attacks $2!',
      notifFail : Arts.NO_NOTIF,
      targetMode : TARGET_MODE.ONEPART,
      description: "Damages a target based on the user's ATK.",
      keywords: [],
      durationTurns: 0,
      kind : KIND.ABILITY,
      traits : TRAITS.PHYSICAL,
      rarity : RARITY.RARE,
      usageHintAI : USAGE_HINT.OFFENSIVE,
      shouldAIuse ::(user, reactTo, enemies, allies) {},
      oncePerBattle : false,
      canBlock : true,
      baseDamage ::(level, user) {},
      onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {        

        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target:targets[0],
              damage: Damage.new(
                amount:user.stats.ATK * (0.5),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP
              ),
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

  Support arts

*/


Arts.newEntry(
  data: {
    name: 'Diversify',
    id : 'base:diversify',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Draw 2 Arts cards.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      user.drawArt(count:2);
    }
  }
)   

Arts.newEntry(
  data: {
    name: 'Cycle',
    id : 'base:cycle',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Discard an Arts card. Draw an Arts card.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      user.discardArt();
      user.drawArt(count:1);
    }
  }
)  


Arts.newEntry(
  data: {
    name: 'Mind Games',
    id : 'base:mind-games',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Target discards an Art card.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      targets[0].discardArt();
    }
  }
)   

Arts.newEntry(
  data: {
    name: 'Crossed Wires',
    id : 'base:crossed-wires',
    notifCommit : '$1 swapped Arts with $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Swap hands with a target.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:oldHand = [...user.deck.hand]
      user.deck.hand = [...targets[0].deck.hand];
      targets[0].deck.hand = oldHand;
    }
  }
)   



Arts.newEntry(
  data: {
    name: 'Recycle',
    id : 'base:recycle',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Discard an Arts card and draw an Arts card from the user\'s discard pile.',
    durationTurns: 0,
    keywords: [],
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Discards entire hand and draws 5 cards.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    name: 'Catch Breath',
    id : 'base:catch-breath',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Discards entire hand, gain 2 HP.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(user.hp == user.stats.HP) false;
    },
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      user.deck.hand = [];
      foreach(user.deck.hand) ::(k, c) {
        user.deck.discardFromHand(:c);
      }
      user.heal(amount:2);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Makeshift Breather',
    id : 'base:makeshift-breather',
    targetMode : TARGET_MODE.NONE,
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    description: 'Sacrifice item, gain 2 HP.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:pickitem = import(:'game_function.pickitem.mt');
      @:world = import(module:'game_singleton.world.mt');
      if (world.party.isMember(:user)) ::<= {
        pickitem(
          canCancel: false,
          inventory : world.party.inventory,
          onPick ::(item){
            world.party.inventory.remove(:item);
            user.heal(amount:2);        
          }
        );
      } else ::<= {
        user.heal(amount:2);              
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Makeshift Transmutation',
    id : 'base:makeshift-transmutation',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Sacrifice item. Summons a small spirit to fight on your side.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      @:summon ::{

        @:Entity = import(module:'game_class.entity.mt');
        @:Species = import(module:'game_database.species.mt');
        @:sprite = Entity.new(
          island : world.island,
          speciesHint: 'base:spirit',
          professionHint: 'base:spirit',
          levelHint:4
        );
        sprite.name = 'the Spirit';
              
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


      @:pickitem = import(:'game_function.pickitem.mt');
      if (world.party.isMember(:user)) ::<= {
        pickitem(
          canCancel: false,
          inventory : world.party.inventory,
          onPick ::(item){
            world.party.inventory.remove(:item);
            summon();        
          }
        );
      } else ::<= {
        summon();        
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Makeshift Shield',
    id : 'base:quick-shield',
    notifCommit : '$1 begins to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Sacrifice an item. The user heals 4 Shield HP. This counts as healing.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:pickitem = import(:'game_function.pickitem.mt');
      @:world = import(module:'game_singleton.world.mt');
      if (world.party.isMember(:user)) ::<= {
        pickitem(
          canCancel: false,
          inventory : world.party.inventory,
          onPick ::(item){
            world.party.inventory.remove(:item);
            targets[0].heal(amount:4, isShield:true);           
          }
        );
      } else ::<= {
        targets[0].heal(amount:4, isShield:true);           
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Mutual Destruction',
    id : 'base:mutual-destruction',
    notifCommit : '$1 costs a mysterious spell!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: '50% chance success rate. Target gains 10 Banish stacks. Random teammate gains 10 banish stacks.',
    keywords: ['base:banish'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      when(random.flipCoin()) Arts.FAIL;

      @:sacr = random.pickArrayItem(:user.battle.getAllies(:user));

      for(0, 10) ::(i) {
        sacr.addEffect(from:user, id:'base:banish', durationTurns:10000);      
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:10000);      
      }
    }
  }
)



Arts.newEntry(
  data: {
    name: 'Brace',
    id : 'base:brace',
    notifCommit : '$1 started to brace for damage!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Discard an Arts card. User gains the Brace effect for 2 turns.',
    keywords: ['base:brace'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : '$1 increases their agility!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Discard an Arts card. User gains the Agile effect for 5 turns.',
    keywords: ['base:agile'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    rarity : RARITY.UNCOMMON,
    traits : TRAITS.SUPPORT,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Discard an Arts card. View a target\'s Arts hand.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
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
    name: 'Attack Reflex',
    id : 'base:retaliate',
    notifCommit : '$1 reflexively attacks $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'The user attacks as a reflex to an Art, damaging a target. This damage is not blockable.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : TRAITS.SUPPORT | TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- 2,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:2,
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    name: 'Quick Shield',
    id : 'base:quick-shield',
    notifCommit : '$1 casts a shield spell in response on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'The user heals 2 Shield HP. This counts as healing.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : TRAITS.SUPPORT | TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      targets[0].heal(amount:2, isShield:true);           
      return false;
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Cancel',
    id : 'base:cancel',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'The user cancels an ability Art.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(allies->findIndex(:reactTo) != -1) false;
    },
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      return true;
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Pebble',
    id : 'base:pebble',
    notifCommit : '$1 suddenly throws a pebble at $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Throws a pebble at a target, causing a small amount of damage.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.PHYSICAL,
    rarity : RARITY.COMMON,
    baseDamage ::(level, user) <- 1,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:1,
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    name: 'Shared Pain',
    id : 'base:shared-pain',
    notifCommit : '$1 and $2 start to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Deal a physical attack to target which has a base damage value equal to how much HP is missing from this character\'s current max HP.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(user.hp == user.stats.HP) false;
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:user.stats.HP - user.hp,
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    name: 'Banishing Light',
    id : 'base:banishing-light',
    notifCommit : '$1 casts Banishing Light on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "The target receives the Banishing Light effect for the duration of the battle.",
    keywords: ['base:banishing-light', 'base:banish'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id:'base:banishing-light', durationTurns:9999); 
        }
      )
    }
  }
)




Arts.newEntry(
  data: {
    name: 'Blood\'s Pain',
    id : 'base:bloods-pain',
    notifCommit : '$1 casts Blood\'s Pain on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    description: "Sacrifice 2 HP. Deal damage to target based on ATK.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) <- user.hp > 2,
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.PHYSICAL,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) <- user.stats.ATK * (0.3),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          user.damage(
            attacker: user,
            damage : Damage.new(
              amount : 2,
              damageType : Damage.TYPE.NEUTRAL,
              damageClass: Damage.CLASS.HP
            ),
            dodgeable : false,
            critical : false,
            exact : true
          );            


          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:user.stats.ATK * (0.3),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    name: 'Blood\'s Shield',
    id : 'base:bloods-shield',
    targetMode : TARGET_MODE.ONE,
    notifCommit : '$1 casts Blood\'s Shield on $2!',
    notifFail : Arts.NO_NOTIF,
    description: "Sacrifice 1 HP. Target receives 2 Shield HP. This counts as healing.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) <- user.hp > 1,
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          user.damage(
            attacker: user,
            damage : Damage.new(
              amount : 1,
              damageType : Damage.TYPE.NEUTRAL,
              damageClass: Damage.CLASS.HP
            ),
            dodgeable : false,
            critical : false,
            exact : true
          );            

          targets[0].heal(amount:2, isShield:true);           
        }
      )
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Blood\'s Exaltation',
    id : 'base:bloods-exaltation',
    notifCommit : '$1 casts Blood\'s Exaltation on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Sacrifice 2 HP. Target does x2 damage on next attack.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) <- user.hp > 2,
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          user.damage(
            attacker: user,
            damage : Damage.new(
              amount : 2,
              damageType : Damage.TYPE.NEUTRAL,
              damageClass: Damage.CLASS.HP
            ),
            dodgeable : false,
            critical : false,
            exact : true
          );            

          targets[0].addEffect(from:user, id:'base:next-attack-x2', durationTurns:9999);
        }
      )
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Blood\'s Ward',
    id : 'base:bloods-ward',
    notifCommit : '$1 casts Blood\'s Ward!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Sacrifice 1 HP. Cancel target Art.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(user.hp > 1) false
      when(allies->findIndex(:reactTo) != -1) false
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.REACTION,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.COMMON,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          user.damage(
            attacker: user,
            damage : Damage.new(
              amount : 1,
              damageType : Damage.TYPE.NEUTRAL,
              damageClass: Damage.CLASS.HP
            ),
            dodgeable : false,
            critical : false,
            exact : true
          );            
          windowEvent.queueMessage(
            text: user.name + ' cancels the Art!'
          );
        }
      )
      return true;
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Blood\'s Seeking',
    id : 'base:bloods-seeking',
    notifCommit : '$1 casts Blood\'s Seeking!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Sacrifice 2 HP. Search user\'s discard pile for an Art. Add the Art to the user\'s hand.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) <- user.hp > 2,
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          user.damage(
            attacker: user,
            damage : Damage.new(
              amount : 2,
              damageType : Damage.TYPE.NEUTRAL,
              damageClass: Damage.CLASS.HP
            ),
            dodgeable : false,
            critical : false,
            exact : true
          );          
          
          windowEvent.queueMessage(
            text : 'Pick a card from ' + user.name + '\s discard to add to your hand.'
          );  

          user.chooseDiscard(
            act: 'Add to hand.',
            onChoice::(id) {
              when(id == empty) empty;
              user.deck.addHandCard(id); 
            }
          );           
        }
      )
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Blood\'s Sacrifice',
    id : 'base:bloods-sacrifice',
    notifCommit : '$1 casts Blood\'s Sacrifice on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Sacrifice 2 HP. View target\'s hand and forces discarding of a card of the user\'s choosing.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) <- user.hp > 2,
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          user.damage(
            attacker: user,
            damage : Damage.new(
              amount : 2,
              damageType : Damage.TYPE.NEUTRAL,
              damageClass: Damage.CLASS.HP
            ),
            dodgeable : false,
            critical : false,
            exact : true
          );            

          targets[0].discardArt(chosenBy:user);           
        }
      )
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Blood\'s Wind',
    id : 'base:bloods-sacrifice',
    notifCommit : '$1 casts Blood\'s Wind on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Sacrifice 2 HP. The target receives the Evade effect for 2 turns.",
    keywords: ['base:evade'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) <- user.hp > 2,
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          user.damage(
            attacker: user,
            damage : Damage.new(
              amount : 2,
              damageType : Damage.TYPE.NEUTRAL,
              damageClass: Damage.CLASS.HP
            ),
            dodgeable : false,
            critical : false,
            exact : true
          );            

          targets[0].addEffect(from:user, id:'base:evade', durationTurns:2);                  
        }
      )
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Cursed Summoning',
    id : 'base:cursed-summoning',
    notifCommit : '$1 summons a Cursed Light!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Summons a very powerful Cursed Light to fight alongside the user. The Cursed Light is inflicted with Cursed Binding for the remainder of battle.",
    keywords: ['base:cursed-binding'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Species = import(module:'game_database.species.mt');

      @:Entity = import(module:'game_class.entity.mt');
      @:Species = import(module:'game_database.species.mt');
      @:world = import(module:'game_singleton.world.mt');
      @:sprite = Entity.new(
        island: world.island,
        speciesHint: 'base:guiding-light',
        professionHint: 'base:guiding-light',
        levelHint:14
      );
      sprite.name = 'the Cursed Light';
      
      
      
      @:battle = user.battle;
      windowEvent.queueCustom(
        onEnter :: {
          battle.join(
            group: [sprite],
            sameGroupAs:user
          );
          sprite.addEffect(from:user, id:'base:cursed-binding', durationTurns:10000);
        }
      )

    }
  }
)



Arts.newEntry(
  data: {
    name: 'Cursed Binding',
    id : 'base:cursed-binding',
    notifCommit : '$1 casts Cursed Binding on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Adds the effect Cursed Binding on a target for 10 turns.",
    keywords: ['base:cursed-binding'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:targets[0], id:'base:cursed-binding', durationTurns:10);
    }
  }
)



Arts.newEntry(
  data: {
    name: 'Blood\'s Summoning',
    id : 'base:bloods-summoning',
    notifCommit : '$1 casts Blood\'s Summoning!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Sacrifice 2 HP. Summons a small spirit to fight on your side.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) <- user.hp > 2,
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          user.damage(
            attacker: user,
            damage : Damage.new(
              amount : 2,
              damageType : Damage.TYPE.NEUTRAL,
              damageClass: Damage.CLASS.HP
            ),
            dodgeable : false,
            critical : false,
            exact : true
          );                            
        }
      )
      
      
      windowEvent.queueMessage(
        text: user.name + ' summons a Spirit!'
      );



      @:world = import(module:'game_singleton.world.mt');
      @:Entity = import(module:'game_class.entity.mt');
      @:Species = import(module:'game_database.species.mt');
      @:sprite = Entity.new(
        island : world.island,
        speciesHint: 'base:spirit',
        professionHint: 'base:spirit',
        levelHint:4
      );
      sprite.name = 'the Spirit';
            
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
    name: 'Unexpected Swipe',
    id : 'base:unexpected-swipe',
    notifCommit : '$1 unexpectedly swipes at $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Add the Unbalanced effect on target for 2 turns. Draw an Arts card.",
    keywords: ['base:unbalanced'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.RARE,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:unbalanced', durationTurns:2);      
      user.drawArt(count:1); 
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Desperation',
    id : 'base:desparation',
    notifCommit : '$1 starts to become desparate!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Add the Desparate effect on user for 2 turns. Draw an Arts card.",
    keywords: ['base:desparate'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:desparate', durationTurns:2);      
      user.drawArt(count:1); 
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Bodyslam',
    id : 'base:bodyslam',
    notifCommit : '$1 body slams $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Deal damage to a target where the base damage is equal to the current HP and 1/3 the DEF of the user. The user is stunned after use for 1 turn.",
    keywords: ['base:stunned'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT | TRAITS.PHYSICAL,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) <- user.stats.HP + user.stats.DEF/3,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:Arts.find(:'base:bodyslam').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
            targetPart:targetParts[0],
            targetDefendPart:targetDefendParts[0]
          );        
        }
      );    

      windowEvent.queueCustom(
        onEnter :: {
          user.addEffect(from:user, id: 'base:stunned', durationTurns: 1);  
        }
      );      
    }
  }
);


Arts.newEntry(
  data: {
    name: 'Enlarge',
    id : 'base:enlarge',
    notifCommit : '$1 casts Enlarge on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Adds the Enlarged effect to a target for 2 turns.",
    keywords: ['base:enlarged'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:enlarged', durationTurns:2);      
      
    }
  }
);


Arts.newEntry(
  data: {
    name: 'Shield Amplifier',
    id : 'base:shield-amplifier',
    notifCommit : '$1 casts Shield Amplifier on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Target\'s Shield HP is doubled. If the target has no Shield HP, the target receives 1 Shield HP.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      if (targets[0].shield == 0)
        targets[0].heal(amount:1, isShield:true)          
      else      
        targets[0].heal(amount:targets[0].shield, isShield:true);           
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Banish',
    id : 'base:banish',
    notifCommit : '$1 casts Banish on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Add 2 Banish stacks to target.",
    keywords: ['base:banish'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      for(0, 2) ::(i) {
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:10000);      
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Bound Banish',
    id : 'base:banish',
    notifCommit : '$1 casts Bound Banish on $2!',
    notifFail : Arts.NO_NOTIF,    
    targetMode : TARGET_MODE.ONE,
    description: "Paralyze user for 2 turns, preventing their action. Add 3 Banish stacks to target.",
    keywords: ['base:banish', 'base:paralyzed'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:paralyzed',durationTurns:2);
      for(0, 3) ::(i) {
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:10000);      
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Proliferate',
    id : 'base:proliferate',
    notifCommit : '$1 casts Proliferate on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "All effects on target are doubled. These new effects last for 2 turns.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      foreach(targets[0].effectStack.getAll()) ::(k, inst) {
        targets[0].addEffect(
          from:user, id:inst.id, durationTurns:2
        );
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Proliferate All',
    id : 'base:proliferate',
    notifCommit : '$1 casts Proliferate All!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALL,
    description: "All effects on all targets are doubled. These new effects last for 2 turns.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      foreach(targets) ::(k, target) {
        foreach(target.effectStack.getAll()) ::(k, inst) {
          target.addEffect(
            from:user, id:inst.id, durationTurns:2
          );
        }
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Banishing Aura',
    id : 'base:banishing-aura',
    notifCommit : '$1 casts Banishing Aura!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALL,
    description: "Accumulate 3 Banish stacks on all combatants.",
    keywords: ['base:banish'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      foreach(targets) ::(k, inst) {
        for(0, 3) ::(i) {
          inst.addEffect(
            from:user, id:'base:banish', durationTurns:10000
          );
        }
      }
    }
  }
)



Arts.newEntry(
  data: {
    name: 'Wyvern Prayer',
    id : 'base:wyvern-prayer',
    notifCommit : '$1 closes their eyes, lifts their arms, and prays to the Wyverns for a miracle!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALL,
    description: "Prays for a miracle, causing a variety of potent effects. Reduces current AP by half if successful. Additional levels reduce the AP cost.",
    keywords: [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      
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
                target.damage(attacker:user, damage:Damage.new(
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
                target.damage(attacker:user, damage:Damage.new(
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


// ver 0.2.0 starting supports
Arts.newEntry(
  data: {
    name: '@b169',
    id : 'base:b169',
    notifCommit : '$2 is covered in a soothing aura!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Removes all status ailments from the target.",
    keywords: ['base:ailments'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:allies)->filter(
        ::(value) <- value.effectStack.getAllByFilter(
          ::(value) <- (Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0
        )->size > 0
      );
      when(which->size == 0) false;
      
      return [which[0]];
    },
    oncePerBattle : true,
    canBlock : false,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');

      @:filter = ::(value) <- (Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0

      @:hasAny = targets[0].effectStack.getAllByFilter(:filter)->size > 0;
      targets[0].removeEffectsByFilter(:filter);
      if (hasAny == false)  
        windowEvent.queueMessage(
          text : '... but nothing happened!'
        )
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b170',
    id : 'base:b170',
    notifCommit : '$2 is covered in a soothing aura!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Removes all ailments and negative effects from the target. Only usable once per battle. Additional levels have no effect.",
    keywords: ['base:ailments'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:allies)->filter(
        ::(value) <- value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0) ||
                       ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      
      return [which[0]];
    },
    oncePerBattle : true,
    canBlock : false,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');

      @:filter = ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0) ||
                              ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0)

      @:hasAny = targets[0].effectStack.getAllByFilter(:filter)->size > 0;
      targets[0].removeEffectsByFilter(:filter);
      if (hasAny == false)  
        windowEvent.queueMessage(
          text : '... but nothing happened!'
        )
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b171',
    id : 'base:b171',
    notifCommit : '$1\'s allies are covered in a mysterious light!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLALLY,
    description: "Removes all ailments and negative effects from allies and gives them all to the user.",
    keywords: ['base:ailments'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:allies)->filter(
        ::(value) <- value != user && value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0) ||
                       ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      return which;
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');


      @:condition = ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0) ||
                                 ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0)
      @toput = [];
      foreach(targets) ::(k, v) {
        when(v == user) empty;
        toput = [...toput, v.effectStack.getAllByFilter(:condition)];
        v.removeEffectsByFilter(:condition);
      }
      
      when (toput->size == 0) 
        windowEvent.queueMessage(
          text: '...but the light fizzled and nothing happened!'
        );
      
      windowEvent.queueMessage(
        text: 'The light converges on ' + user.name + '!'
      );
      
      foreach(toput) ::(k, effectFull) {
        user.addEffect(
          id:effectFull.id,
          durationTurns: effectFull.duration,
          from: effectFull.from,
          item: effectFull.item
        );
      }


    }
  }
)


Arts.newEntry(
  data: {
    name: '@b172',
    id : 'base:b172',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Randomly steals one positive effect from a random enemy and gives it to the user.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:enemies)->filter(
        ::(value) <- value != user && value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.BUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      return which;
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:condition = ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.BUFF) != 0)

      @:which = random.scrambled(:targets)->filter(
        ::(value) <- value != user && value.effectStack.getAllByFilter(
          :condition
        )->size > 0
      );
                  
      when(which->size == 0)
        windowEvent.queueMessage(text:'...but nothing happened!');
                                 
      @:victim = random.pickArrayItem(:which);
      windowEvent.queueMessage(
        text: victim.name + ' is covered in a mysterious light!'
      );
      
      @:effectFull = random.scrambled(:victim.effectStack.getAllByFilter(:condition))[0];
      victim.removeEffectsByFilter(::(value) <- value == effectFull);
      

      
      user.addEffect(
        id:effectFull.id,
        durationTurns: effectFull.duration,
        from: effectFull.from,
        item: effectFull.item
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b173',
    id : 'base:b173',
    notifCommit : '$1 is covered in a myserious light!',
    notifFail : '... But nothing happened!',
    targetMode : TARGET_MODE.NONE,
    description: "Replaces up to two of the user\'s effects with random ones.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(user.effectStack.getAllByFilter(
          ::(value) <- true
        )->size == 0) false;
      return [user];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:effects = random.scrambled(:user.effectStack.getAllByFilter(::(value)<-true));
      @:Effect = import(module:'game_database.effect.mt');

      when(effects->size == 0) Arts.FAIL;


  
      if (effects->size > 2)
          effects->setSize(:2);
  
      user.removeEffectsByFilter(::(value) {
        return {:::} {
          foreach(effects) ::(k, v) {
            if (v == value) send(:true);
          }
          return false;
        }
      });
                  

      foreach(effects) ::(k, v) {
        @:newEffect = Effect.getRandomFiltered(::(value) <- (value.flags & Effect.TRAIT.SPECIAL) == 0);
        user.addEffect(
          durationTurns: v.duration,
          id:newEffect.id,
          from: v.from,
          item: v.item
        );        
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b174',
    id : 'base:b174',
    notifCommit : 'Everyone is covered in soothing aura!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALL,
    description: "Removes all ailments and negative effects from all combatants, then discard a card and draw a card. Additional levels have no effect.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:allies)->filter(
        ::(value) <- value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0) ||
                       ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      
      return [...allies, ...enemies];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      
      @:filter = ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0) ||
                              ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0)
      
      foreach(targets) ::(k, target) {
        target.removeEffectsByFilter(:filter);
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b175',
    id : 'base:b175',
    notifCommit : '$1 is covered in an ominous aura!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALL,
    description: "Removes all positive effects from all combatants.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:enemies)->filter(
        ::(value) <- value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.BUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      
      return [...allies, ...enemies];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      
      @:filter = ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.BUFF) != 0)      
      foreach(targets) ::(k, target) {
        target.removeEffectsByFilter(:filter);
      }
    }
  }
)



Arts.newEntry(
  data: {
    name: '@b176',
    id : 'base:b176',
    notifCommit : '$1 and $2 are covered in a myserious light!',
    notifFail : '... But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all effects from the user and randomly gives one of them to a target.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = user.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0) ||
                       ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0)
        )
      when(which->size == 0) false;
      
      return [random.pickArrayItem(:which)];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:filter = ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0) ||
                              ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0)
     
     
     
      @:v = user.effectStack.getAllByFilter(:filter)[0];
      when (v == empty) Arts.FAIL;
      
      
      user.removeEffectsByFilter(filter);
      targets[0].addEffect(
        id:v.id,
        durationTurns: v.duration,
        from: v.from,
        item: v.item
      );  
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b177',
    id : 'base:b177',
    notifCommit : 'Everyone is covered in a weird aura!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALL,
    description: "Randomly redistributes all effects to all combatants.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');

      when(
        enemies->filter(
          ::(value) <- value.effectStack.getAllByFilter(
            ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.BUFF) != 0)
          )->size > 0
        )
        ||
        allies->filter(
          ::(value) <- value.effectStack.getAllByFilter(
            ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0) ||
                         ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0)
          )->size > 0
        )
      ) [...allies, ...enemies];

      
      return false;
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      
      @toput = [];
      foreach(targets) ::(k, v) {
        toput = [...toput, ...v.effectStack.getAll()];
        v.removeEffectsByFilter(::(value) <- true);
      }
      
      foreach(random.scrambled(:toput)) ::(k, v) {
        @:target = random.pickArrayItem(:targets);
        
        target.addEffect(
          id:v.id,
          durationTurns: v.duration,
          from: v.from,
          item: v.item
        );  
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Tendril of Time',
    id : 'base:b178',
    notifCommit : '$1 is enveloped in eerie tendrils of light!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Removes all effects from user and resets HP and AP to full. This Art is permanently removed from the user\'s deck upon use. Additional levels have no effect.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(user.hp < user.stats.HP/2) [user];
      return false;
    },
    oncePerBattle : true,
    canBlock : false,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.removeEffectsByFilter(::(value) <- true);

      user.heal(
        amount:user.stats.HP - user.hp
      );
      
      user.healAP(
        amount: user.stats.AP - user.ap 
      );
      
      
      @toput = [];
      foreach(targets) ::(k, v) {
        toput = [...toput, ...v.effectStack.getAll()];
      }
      
      // technically removes ALL instances, but the others 
      // wouldnt be usable anyway
      user.artsDeck.purge(:'base:b178');
      
      // just remove ONE
      @index = user.supportArts->findIndex(:'base:b178');

      // if it came from someone else's deck, theyre in luck.
      when(index == -1) empty;
      
      user.supportArts->remove(:index);
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b179',
    id : 'base:b179',
    notifCommit : '$1 and $2 are covered in a mysterious light!',
    notifFail : '... But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Randomly steals up to two random effects from a target and gives it to the user.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:enemies)->filter(
        ::(value) <- value != user && value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.TRAIT.BUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      return [which[0]];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:effectStackSize = targets[0].effectStack.getAll()->size;
      when(effectStackSize == 0) Arts.FAIL;
                                 
      
      for(0, if (effectStackSize == 1) 1 else 2) ::(i) {
        @:effectFull = random.scrambled(:targets[0].effectStack.getAll())[0];
        targets[0].removeEffectsByFilter(::(value) <- value == effectFull);
        
        user.addEffect(
          id:effectFull.id,
          durationTurns: effectFull.duration,
          from: effectFull.from,
          item: effectFull.item
        );
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b180',
    id : 'base:b180',
    notifCommit : 'Everyone is covered in a weird aura!',
    notifFail : '... But nothing happened!',
    targetMode : TARGET_MODE.ALLALLY,
    description: "Heals the user by 1 HP for each effect that all the user\'s allies have.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      when(user.hp >= user.stats.HP) false;

      // if has any effects, is good to use
      return {:::} {
        foreach(allies) ::(k, v) {
          if (v.effectStack.getAll()->size > 0)
            send(:true);
        } 
        return false;
      }
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @tally = 0;
      foreach(targets) ::(k, v) {
        tally += v.effectStack.getAll()->size;
      } 
      
      when(tally == 0) Arts.FAIL;
      
      user.heal(amount:tally);
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b181',
    id : 'base:b181',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Replaces all negative effects on target with Banish stacks.",
    keywords: ['base:banish'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:able = random.scrambled(:enemies->filter(::(value) <- 
        value.effectStack.getAll()->filter(::(value) <- 
          ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF)  != 0) ||
          ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0)
        )->size > 0));
      when(able->size == 0) false;
          
      return [able[0]]
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:all = [...targets[0].effectStack.getAll()->filter(::(value) <- 
        ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF)  != 0) ||
        ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0)
      )]
      
      when(all->size == 0) Arts.FAIL;
      
      targets[0].removeEffects(:all);
      
      for(0, all->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:10000);              
      } 
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b182',
    id : 'base:b182',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Replaces all positive effects on target with Banish stacks.",
    keywords: ['base:banish'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:able = enemies->filter(::(value) <- 
        value.effectStack.getAll()->filter(::(value) <- 
          ((Effect.find(:value.id).flags & Effect.TRAIT.BUFF)  != 0)
        )->size > 0)
      when(able->size == 0) false;
      return [able[0]];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:all = [...targets[0].effectStack.getAll()->filter(::(value) <- 
          ((Effect.find(:value.id).flags & Effect.TRAIT.BUFF)  != 0)
      )]
      when(all->size == 0) Arts.FAIL;
      
      targets[0].removeEffects(:all);
      
      for(0, all->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:10000);              
      } 
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b183',
    id : 'base:b183',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Replaces all positive effects on target with random ones. The durations of each effect are preserved.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:able = enemies->filter(::(value) <- 
        value.effectStack.getAll()->filter(::(value) <- 
          (Effect.find(:value.id).flags & Effect.TRAIT.BUFF)  != 0
        )->size > 0)
      when(able->size == 0) false;
      return [able[0]];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:all = [...targets[0].effectStack.getAll()->filter(::(value) <- 
        (Effect.find(:value.id).flags & Effect.TRAIT.BUFF)  != 0
      )]
      
      when(all->size == 0) Arts.FAIL;
            
      foreach(all) ::(k, v) {
        @:id = Effect.getRandomFiltered(::(value) <- (value.flags & Effect.TRAIT.SPECIAL) == 0).id;
        targets[0].addEffect(from:user, id, durationTurns:
          v.duration
        );              
      } 
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b184',
    id : 'base:b184',
    notifCommit : 'A mystical light befalls everyone!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALL,
    description: "Deals damage to each combatant based on their respective number of effects.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:groupToCount::(group) <- 
        (group->map(::(value) <- 
          value.effectStack.getAll()->size)
        )->reduce(::(previous, value) <-
          if (previous == empty)
            value
          else 
            value + previous
        )
        
      // does it hurt them more than it hurts me? sure!
      when (groupToCount(:enemies) >
            groupToCount(:allies))
        [...allies, ...enemies];
      
      return false;
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      foreach(targets) ::(k, v) {
        @:amount = v.effectStack.getAll()->size;
        when(amount == 0) empty;
        
        windowEvent.queueCustom(
          onEnter ::{
            v.damage(attacker:user, damage:Damage.new(
              amount,
              damageType:Damage.TYPE.PHYS,
              damageClass:Damage.CLASS.HP
            ),dodgeable: false, exact: true);     
          }
        );
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b185',
    id : 'base:b185',
    notifCommit : 'A mystical light befalls everyone!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALL,
    description: "Removes all effects from each combatant. Each combatant gains a number of Banish stacks equal to the total number of those removed effects divided by the number of combatants, rounding up.",
    keywords: ['base:banish'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:groupToCount::(group) <- 
        (group->map(::(value) <- 
          value.effectStack.getAll()->size)
        )->reduce(::(previous, value) <-
          if (previous == empty)
            value 
          else 
            value + previous
        )
        
      // does it hurt them more than it hurts me? sure!
      when (groupToCount(:enemies) >
            groupToCount(:allies))
        [...allies, ...enemies];
      
      return false;
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @total = 0;
      foreach(targets) ::(k, v) {
        @:amount = v.effectStack.getAll()->size;
        when(amount == 0) empty;
    
        total += amount;
        v.removeEffectsByFilter(::(value) <- true);
      }
      
      
      total = (total / targets->size)->ceil;
      foreach(targets) ::(k, v) {
        for(0, total) ::(i) {
          v.addEffect(from:user, id:'base:banish', durationTurns:10000);              
        }
      }
      
    }
  }
)



Arts.newEntry(
  data: {
    name: '@b186',
    id : 'base:b186',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all the user's Banish stacks and places them on a target.",
    keywords: ['base:banish'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when (user.effectStack.getAllByFilter(::(value) <- 
          value.id == 'base:banish'
      )->size == 0) 
        false;
          
      return [random.pickArrayItem(:enemies)];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @total = 0;
      @oldBanish = user.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish');
      when(oldBanish->size == 0) Arts.FAIL;  
      user.removeEffectsByFilter(::(value) <- value.id == 'base:banish');
            
      for(0, oldBanish->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:10000);              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b187',
    id : 'base:b187',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all stacks of the Poisoned effect from target. For each Poisoned stack removed this way, the target gains 2 HP and +25% DEX for 2 turns.",
    keywords: ['base:poisoned'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return {:::} {
        foreach(allies) ::(k, v) {
          when (v.effectStack.getAllByFilter(::(value) <- value.id == 'base:poisoned')->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @total = 0;
      @oldPoison = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:poisoned');
      when(oldPoison->size == 0) Arts.FAIL;
      targets[0].removeEffectsByFilter(::(value) <- value.id == 'base:poisoned');
            
      targets[0].heal(amount:oldPoison->size * 2);
            
      for(0, oldPoison->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:minor-dex-boost', durationTurns:2);              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b188',
    id : 'base:b188',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all stacks of the Burned effect from target. For each Burned stack removed this way, the target gains 2 HP and +25% DEF for 2 turns.",
    keywords: ['base:burned'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return {:::} {
        foreach(allies) ::(k, v) {
          when (v.effectStack.getAllByFilter(::(value) <- value.id == 'base:burned')->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @total = 0;
      @oldBurn = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:burned');
      when(oldBurn->size == 0) Arts.FAIL;
      targets[0].removeEffectsByFilter(::(value) <- value.id == 'base:burned');
            
      targets[0].heal(amount:oldBurn->size * 2);
            
      for(0, oldBurn->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:minor-defense-boost', durationTurns:2);              
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b189',
    id : 'base:b189',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all stacks of the Paralyzed effect from target. For each Paralyzed stack removed this way, the target gains 2 AP and +25% INT for 2 turns.",
    keywords: ['base:paralyzed'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return {:::} {
        foreach(allies) ::(k, v) {
          when (v.effectStack.getAllByFilter(::(value) <- value.id == 'base:paralyzed')->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @total = 0;
      @oldParalyze = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:paralyzed');
      when(oldParalyze->size == 0) Arts.FAIL;
      targets[0].removeEffectsByFilter(::(value) <- value.id == 'base:paralyzed');
            
      targets[0].healAP(amount:oldParalyze->size * 2);
            
      for(0, oldParalyze->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:minor-mind-boost', durationTurns:2);              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b190',
    id : 'base:b190',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Removes the Petrified effect from target. The target gains 2 HP and +25% ATK for 3 turns.",
    keywords: ['base:petrified'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return {:::} {
        foreach(allies) ::(k, v) {
          when (v.effectStack.getAllByFilter(::(value) <- value.id == 'base:petrified')->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @total = 0;
      @oldPetr = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:petrified');
      when(oldPetr->size == 0) Arts.FAIL;
      targets[0].removeEffectsByFilter(::(value) <- value.id == 'base:petrified');
            
      targets[0].heal(amount:oldPetr->size * 2);
            
      for(0, oldPetr->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:minor-strength-boost', durationTurns:3);              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b191',
    id : 'base:b191',
    notifCommit : 'A soothing light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all negative effects from the target. For each effect removed this way, the target gains 2 AP and +25% SPD for 2 turns.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      return {:::} {
        foreach(allies) ::(k, v) {
          when (v.effectStack.getAllByFilter(::(value) <- 
            (Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0 ||
            (Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF)  != 0
          )->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @total = 0;
      @oldBad = targets[0].effectStack.getAllByFilter(::(value) <- 
        (Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0 ||
        (Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF)  != 0
      );
      when(oldBad->size == 0) Arts.FAIL;
      targets[0].removeEffectsByFilter(::(value) <- 
        (Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0 ||
        (Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF)  != 0      
      );
            
      targets[0].healAP(amount:oldBad->size * 2);
            
      for(0, oldBad->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:minor-speed-boost', durationTurns:2);              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b192',
    id : 'base:b192',
    notifCommit : '$2 and $1 glow ominously!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Matches the resonance of the user's spirit with another, granting the target's effects to the user.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      return {:::} {
        foreach([...enemies, ...allies]) ::(k, v) {
          when (v.effectStack.getAllByFilter(::(value) <- 
            (Effect.find(:value.id).flags & Effect.TRAIT.BUFF) != 0
          )->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @total = 0;
      @oldGood = targets[0].effectStack.getAllByFilter(::(value) <- 
        true
      );
      when(oldGood->size == 0) Arts.FAIL;
            
            
      foreach(oldGood) ::(k, v) {
        user.addEffect(
          from:targets[0], 
          id:v.id, 
          durationTurns: v.duration,
          item: v.id
        );              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b193',
    id : 'base:b193',
    notifCommit : '$1 lunges at $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Grapples a target and binds their spirits together, transferring the user\'s effects to the target. The grapple lasts for 1 turn.",
    keywords: ['base:grappled', 'base:grappling'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      // only use it offensively when you dont have buffs
      when (user.effectStack.getAllByFilter(::(value) <- 
        ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0) ||
        ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0)
      )->size == 0) false;

    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC | TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @total = 0;
      @oldGood = user.effectStack.getAllByFilter(::(value) <- 
        true
      );
      if (oldGood->size != 0) ::<= {
        foreach(oldGood) ::(k, v) {
          targets[0].addEffect(
            from:user, 
            id:v.id, 
            durationTurns: v.duration,
            item: v.id
          );              
        }
      }
      
      targets[0].addEffect(from:user, id: 'base:grappled', durationTurns: 1);            
      user.addEffect(from:user, id: 'base:grappling', durationTurns: 1);            
      
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b194',
    id : 'base:b194',
    notifCommit : '$1 begins to glow as they attack $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Attacks an enemy. If the hit is successful, effects of the user and target are swapped.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      // only use it offensively when you dont have buffs
      when (user.effectStack.getAllByFilter(::(value) <- 
        ((Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0) ||
        ((Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0)
      )->size == 0) false;

    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC | TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    baseDamage::(level, user) <- user.stats.ATK * (0.2) * level,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      


      windowEvent.queueCustom(
        onEnter :: {

          if (user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:Arts.find(:'base:b194').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
            targetPart:Entity.DAMAGE_TARGET.BODY,
            targetDefendPart:targetDefendParts[0]
          )) ::<= {
            @effUser   = [...user.effectStack.getAll()]
            @effTarget = [...targets[0].effectStack.getAll()]

            targets[0].removeEffectsByFilter(::(value) <- true);
            user.removeEffectsByFilter(::(value) <- true);


            foreach(effUser) ::(k, v) {
              targets[0].addEffect(
                from:user, 
                id:v.id, 
                durationTurns: v.duration,
                item: v.id
              );              
            }
            foreach(effTarget) ::(k, v) {
              user.addEffect(
                from:targets[0], 
                id:v.id, 
                durationTurns: v.duration,
                item: v.id
              );              
            }


          }
        }
      );
    }
  }
)




Arts.newEntry(
  data: {
    name: '@b195',
    id : 'base:b195',
    notifCommit : '$1 focuses their energy!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Fiercesome attack that siphons poison from a user's blood to strike at foes. Removes a stack of Poisoned. Hits two random targets base on ATK and inflicts Poisoned for each stack removed.",
    keywords: ['base:poisoned'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      // only use it offensively when you dont have buffs
      when (user.effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:poisoned'
      )->size == 0) false;

    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC | TRAITS.MULTIHIT,
    rarity : RARITY.RARE,
    baseDamage::(level, user) <- user.stats.ATK * (0.35) * level,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @oldPois = user.effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:poisoned'
      );
      
      when(oldPois->size == 0) Arts.FAIL;
      
      user.removeEffectsByFilter(::(value) <-
        value.id == 'base:poisoned'
      );
      
      foreach(oldPois->size) ::(k, v) {
        windowEvent.queueCustom(
          onEnter :: {
            @target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
            user.attack(
              target,
              damage: Damage.new(
                amount: Arts.find(:'base:b195').baseDamage(level, user),
                damageType : Damage.TYPE.PHYS,
                damageClass: Damage.CLASS.HP,
                isMultihit : true
              ),
              targetPart: targetParts[(user.battle.getEnemies(:user))->findIndex(value:target)],
              targetDefendPart:targetDefendParts[(user.battle.getEnemies(:user))->findIndex(value:target)]
            );
            
            target.addEffect(from:user, id:'base:poisoned',durationTurns:5);
          }
        );            
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b196',
    id : 'base:b196',
    notifCommit : 'A warmth emanates from $1!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Removes all of the user\'s stacks of the Burned effect. This causes an explosion that burns all enemies, dealing more damage per stack of Burned removed. If the user does not have the Burned status, nothing happens.",
    keywords: ['base:burned'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      // only use it offensively when you dont have buffs
      when (user.effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:burned'
      )->size == 0) false;

    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC | TRAITS.MULTIHIT,
    rarity : RARITY.RARE,
    baseDamage::(level, user) <- 4 * user.effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:burned'
      )->size * level,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @oldPois = user.effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:burned'
      );
      
      when(oldPois->size == 0) Arts.FAIL;
      
      user.removeEffectsByFilter(::(value) <-
        value.id == 'base:burned'
      );


      
      foreach(targets) ::(k, target) {
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target,
              damage: Damage.new(
                amount: Arts.find(:'base:b196').baseDamage(level, user),
                damageType : Damage.TYPE.FIRE,
                damageClass: Damage.CLASS.HP,
                isMultihit : true
              ),
              targetPart: targetParts[(user.battle.getEnemies(:user))->findIndex(value:target)],
              targetDefendPart:targetDefendParts[(user.battle.getEnemies(:user))->findIndex(value:target)]
            );
          }
        );            
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b197',
    id : 'base:b197',
    notifCommit : '$1 focuses inward!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.NONE,
    description: "Tune into inner senses to give 2 stacks of the Agile effect and remove the Blind effect.",
    keywords: ['base:agile', 'base:blind'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      // only use it offensively when you dont have buffs
      when (user.effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:blind'
      )->size == 0) false;

    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.removeEffectsByFilter(::(value) <-
        value.id == 'base:blind'
      );
      user.addEffect(from:user, id:'base:agile',durationTurns:2);
      user.addEffect(from:user, id:'base:agile',durationTurns:2);
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b198',
    id : 'base:b198',
    notifCommit : '$1 begins to glow!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.NONE,
    description: "Manifests a magickal equipment of choice to replace the user\'s weapon whose stats increase with the user\'s INT. The current armament, if any, is unequipped.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.ABILITY,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:world = import(module:'game_singleton.world.mt');
      @:equipped = user.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR); 
      if (equipped.name != 'None') ::<= {
        windowEvent.queueMessage(
          text: user.name + ' unequipped their ' + equipped.name + '.'
        );
        @:inventory = if (world.party.isMember(:user)) world.party.inventory else user.inventory
        user.unequipItem(
          item:equipped
        );        
        inventory.add(:equipped);
      }
      
      @:makeItem = ::(base) {
        @:item = Item.new(
          base,
          materialHint : 'base:ethereal'
        );
        
        item.stats.add(:
          StatSet.new(
            ATK : (user.stats.INT*7)->floor,
            DEF : (user.stats.INT*6)->floor,
            DEX : (user.stats.INT*5)->floor,
            SPD : (user.stats.INT*7)->floor
            // INT would be really funny because infinite growth would be so easy...
            // while cool, i would prefer players to find OTHER ways 
            // to home-grow infinite stat weapons
          )
        );
        
        windowEvent.queueMessage(
          text: user.name + ' equipped the ' + item.name + '!'
        );
        
        user.equip(item, slot:Entity.EQUIP_SLOTS.HAND_LR);
      }
      
      
      if (world.party.leader == user) ::<= {
        @:choices = Item.database.getAll()->filter(::(value) <- 
          ((value.traits & Item.TRAIT.WEAPON) != 0) &&
          ((value.traits & Item.TRAIT.KEY_ITEM) == 0)
        );
        windowEvent.queueChoices(
          prompt: 'Materialize which?',
          choices: choices->map(::(value) <- value.name),
          canCancel: false,
          onChoice::(choice) {
            makeItem(:choices[choice-1]);
          }
        );
      
      } else ::<= {
        makeItem(:
          random.pickArrayItem(:Item.database.getAll()->filter(::(value) <- 
            ((value.traits & Item.TRAIT.WEAPON) != 0) &&
            ((value.traits & Item.TRAIT.KEY_ITEM) == 0)
          ))
        );
      }

    }
  }
)


Arts.newEntry(
  data: {
    name: '@b199',
    id : 'base:b199',
    notifCommit : '$1 takes a defensive stance!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.NONE,
    description: "Grants the effect Redirect Momentum to the user for a turn. Draw an Arts card.",
    keywords: ['base:redirect-momentum', 'base:stunned', 'base:grappled'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:redirect-momentum', durationTurns:1);
      user.drawArt(count:1);
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b200',
    id : 'base:b200',
    notifCommit : '$1 glows!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Remove all stacks of Burned from a target. For each Burned removed this way, add a stack of Burning to the target for 3 turns.",
    keywords: ['base:burned', 'base:burning'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:a = allies->filter(::(value) <- 
        value.effectStack.getAllByFilter(::(value) <- 
          value.id == 'base:burned'
        )->size > 0
      );

      when(a->size == 0) false;
      return [random.scrambled(:a)[0]];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:size = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:burned')->size;
      targets[0].removeEffectsByFilter(::(value) <- value.id == 'base:burned');
      for(0, size) ::(i) {
        targets[0].addEffect(from:user, id:'base:burning', durationTurns:3);
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b201',
    id : 'base:b201',
    notifCommit : '$1 glows!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Remove the Frozen effect from a target. If Frozen was removed, add 2 stack of Icy to the target for 3 turns.",
    keywords: ['base:frozen', 'base:icy'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:a = allies->filter(::(value) <- 
        value.effectStack.getAllByFilter(::(value) <- 
          value.id == 'base:frozen'
        )->size > 0
      );

      when(a->size == 0) false;
      return [random.scrambled(:a)[0]];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:size = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:frozen')->size;
      targets[0].removeEffectsByFilter(::(value) <- value.id == 'base:frozen');
      for(0, size) ::(i) {
        targets[0].addEffect(from:user, id:'base:icy', durationTurns:3);
        targets[0].addEffect(from:user, id:'base:icy', durationTurns:3);
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b202',
    id : 'base:b202',
    notifCommit : '$1 glows!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Remove the Paralyzed effect from a target. If Paralyzed was removed, add 2 stack of Shock to the target for 3 turns.",
    keywords: ['base:paralyzed', 'base:shock'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:a = allies->filter(::(value) <- 
        value.effectStack.getAllByFilter(::(value) <- 
          value.id == 'base:paralyzed'
        )->size > 0
      );

      when(a->size == 0) false;
      return [random.scrambled(:a)[0]];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:size = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:paralyzed')->size;
      targets[0].removeEffectsByFilter(::(value) <- value.id == 'base:paralyzed');
      for(0, size) ::(i) {
        targets[0].addEffect(from:user, id:'base:shock', durationTurns:3);
        targets[0].addEffect(from:user, id:'base:shock', durationTurns:3);
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b202-2',
    notifCommit : '$1 glows!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Remove the Blind effect from a target. If Blind was removed, add 2 stack of Dark to the target for 3 turns.",
    keywords: ['base:blind', 'base:dark'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:a = allies->filter(::(value) <- 
        value.effectStack.getAllByFilter(::(value) <- 
          value.id == 'base:blind'
        )->size > 0
      );

      when(a->size == 0) false;
      return [random.scrambled(:a)[0]];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:size = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:blind')->size;
      targets[0].removeEffectsByFilter(::(value) <- value.id == 'base:blind');
      for(0, size) ::(i) {
        targets[0].addEffect(from:user, id:'base:dark', durationTurns:3);
        targets[0].addEffect(from:user, id:'base:dark', durationTurns:3);
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b202-3',
    notifCommit : '$1 glows!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Remove the Petrified effect from a target. If Petrified was removed, add 2 stack of Shimmering to the target for 3 turns.",
    keywords: ['base:petrified', 'base:shimmering'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:a = allies->filter(::(value) <- 
        value.effectStack.getAllByFilter(::(value) <- 
          value.id == 'base:petrified'
        )->size > 0
      );

      when(a->size == 0) false;
      return [random.scrambled(:a)[0]];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:size = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:petrified')->size;
      targets[0].removeEffectsByFilter(::(value) <- value.id == 'base:petrified');
      for(0, size) ::(i) {
        targets[0].addEffect(from:user, id:'base:shimmering', durationTurns:3);
        targets[0].addEffect(from:user, id:'base:shimmering', durationTurns:3);
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b203',
    id : 'base:b203',
    notifCommit : '$1 glows!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Each status ailment on a target is replaced with an attack shift corresponding to it for 3 turns. If there is no corresponding attack shift, the effect remains.",
    keywords: ['base:ailments', 'base:attack-shifts'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:a = allies->filter(::(value) <- 
        value.effectStack.getAllByFilter(::(value) <- 
          value.id == 'base:petrified' ||
          value.id == 'base:burned' ||
          value.id == 'base:blind' ||
          value.id == 'base:poisoned' ||
          value.id == 'base:frozen' ||
          value.id == 'base:paralyzed'
        )->size > 0
      );

      when(a->size == 0) false;
      return [random.scrambled(:a)[0]];
    },
    oncePerBattle : false,
    canBlock : false,
    kind : KIND.EFFECT,
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:convert = {
        ("base:petrified"): "base:shimmering",
        ("base:burned"): "base:burning",
        ("base:blind"): "base:dark",
        ("base:frozen"): "base:icy",
        ("base:paralyzed"): "base:shock",
        ("base:poisoned"): "base:toxic"
      }
      @:effects = targets[0].getAllByFilter(::(value) <- 
        convert->keys->findIndex(:value.id) != -1
      )->size;
      foreach(effects) ::(k, value) {
        targets[0].addEffect(from:user, id:convert[value.id], durationTurns:3);
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b205',
    id : 'base:b205',
    notifCommit : '$1 attacks $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    keywords : [],
    description: "Damages a target based on ATK. For each effect the target has, the damage is boosted by 25%.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) <- user.stats.ATK * (0.3) * level,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      

      @:baseDamage = Arts.find(:'base:b205').baseDamage(level, user);
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:baseDamage * (1 + 0.25 * targets[0].effectStack.getAll()->size),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            ),
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
    name: '@b206',
    id : 'base:b206',
    notifCommit : '$1 attacks $2! with a magical beam of light!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    keywords : [],
    description: "Damages a target based on INT. For each effect the target has, the damage is boosted by 25%.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) <- user.stats.INT * (0.3) * level,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      

      @:baseDamage = Arts.find(:'base:b205').baseDamage(level, user);
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:baseDamage * (1 + 0.25 * targets[0].effectStack.getAll()->size),
              damageType : Damage.TYPE.LIGHT,
              damageClass: Damage.CLASS.HP
            ),
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
    name: '@b207',
    id : 'base:b207',
    notifCommit : '$1 attacks $2! with fiery might!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:burned', 'base:burning'],
    description: "Deals 2 base damage to target. For each stack of Burned or Burning already on the target, this attack deals 2 additional damage. Adds Burned and Burning to target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:whom = enemies->filter(::(value) <-
        value.id == 'base:burned' ||
        value.id == 'base:burning'
      );
      when(whom->size == 0) false;
      
      return [random.scrambled(:whom)[0]];
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) <- 2,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      

      @:size = targets[0].effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:burned' ||
        value.id == 'base:burning'
      )->size;

      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:2 + size*2,
              damageType : Damage.TYPE.FIRE,
              damageClass: Damage.CLASS.HP
            ),
            targetPart:targetParts[0],
            targetDefendPart:targetDefendParts[0]
          );        
          
          targets[0].addEffect(durationTurns:3, from:user, id: 'base:burned');
          targets[0].addEffect(durationTurns:3, from:user, id: 'base:burning');
        }
      );      
                  
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b208',
    id : 'base:b208',
    notifCommit : '$1 attacks $2! with cold might!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:frozen', 'base:icy'],
    description: "Deals 2 base damage to target. For each stack of Icy or Frozen already on the target, this attack deals 2 additional damage. Adds Frozen and Icy to target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:whom = enemies->filter(::(value) <-
        value.id == 'base:frozen' ||
        value.id == 'base:icy'
      );
      when(whom->size == 0) false;
      
      return [random.scrambled(:whom)[0]];
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) <- 2,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      

      @:size = targets[0].effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:icy' ||
        value.id == 'base:frozen'
      )->size;

      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:2 + size*2,
              damageType : Damage.TYPE.ICE,
              damageClass: Damage.CLASS.HP
            ),
            targetPart:targetParts[0],
            targetDefendPart:targetDefendParts[0]
          );        
          
          targets[0].addEffect(durationTurns:3, from:user, id: 'base:icy');
          targets[0].addEffect(durationTurns:3, from:user, id: 'base:frozen');
        }
      );      
                  
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b209',
    id : 'base:b209',
    notifCommit : '$1 attacks $2! with electrifying might!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:paralyzed', 'base:shock'],
    description: "Deals 2 base damage to target. For each stack of Shock or Paralyzed already on the target, this attack deals 2 additional damage. Adds Paralyzed and Shock to target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:whom = enemies->filter(::(value) <-
        value.id == 'base:paralyzed' ||
        value.id == 'base:shock'
      );
      when(whom->size == 0) false;
      
      return [random.scrambled(:whom)[0]];
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) <- 2,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      

      @:size = targets[0].effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:shock' ||
        value.id == 'base:paralyzed'
      )->size;

      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:2 + size*2,
              damageType : Damage.TYPE.THUNDER,
              damageClass: Damage.CLASS.HP
            ),
            targetPart:targetParts[0],
            targetDefendPart:targetDefendParts[0]
          );        
          
          targets[0].addEffect(durationTurns:3, from:user, id: 'base:shock');
          targets[0].addEffect(durationTurns:3, from:user, id: 'base:paralyzed');
        }
      );      
                  
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b210',
    id : 'base:b210',
    notifCommit : '$1 summons an explosion!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:attack-shifts'],
    description: "Summons a fire explosion on a target, dealing damage based on the user's INT. This total damage is boosted by 20% for each attack shift on the user. Additional levels increase damage.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when (user.effectStack.getAllByFilter(::(value) <-
         ATTACK_SHIFTS->findIndex(:value.id) != -1
      )->size == 0) false;
      
      return [random.pickArrayItem(:enemies)]
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {
      @:baseDamage = user.stats.INT * (0.1 + 0.2*level)
      @:count = user.effectStack.getAllByFilter(::(value) <-
         ATTACK_SHIFTS->findIndex(:value.id) != -1
      )->size;
      
      return baseDamage * (1 + 0.2 * count);
    },
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      

      @:baseDamage = Arts.find(:'base:b210').baseDamage(level, user);

      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:baseDamage,
              damageType : Damage.TYPE.FIRE,
              damageClass: Damage.CLASS.HP
            ),
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
    name: '@b211',
    id : 'base:b211',
    notifCommit : 'A light engulfs everyone',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALL,
    keywords : ['base:attack-shifts'],
    description: "Grants all fighters a random attack shift for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      foreach(targets) ::(k, v) {
        v.addEffect(durationTurns:3, from:user, id: random.pickArrayItem(:ATTACK_SHIFTS));
      }
    }
  }
)




Arts.newEntry(
  data: {
    name: '@b214',
    id : 'base:b214',
    notifCommit : '$1 begins to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:shift-boost', 'base:attack-shifts'],
    description: "Grants Shift Boost to a target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL | TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(durationTurns:3, from:user, id: 'base:shift-boost');
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b215',
    id : 'base:b215',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:attack-shifts'],
    description: "A 2-turn attack. First turn, the user charges their elemental power and are unable to act. On the second turn, a random set of attack shifts are converted into an attack, causing damage based on INT and +20% more damage for each stack. If this set of attack shifts is 3 or more, the target is knocked out entirely. The set of shifts are removed after the attack. If no shifts are present, nothing happens.",
    durationTurns: 1,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(user.effectStack.getAllByFilter(::(value) <-
        ATTACK_SHIFTS->findIndex(:value.id) != -1
      )->size == 0) false;
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL | TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) <- user.stats.INT * (0.3 * level),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      


      when(turnIndex == 0) ::<= {
        windowEvent.queueMessage(
          text: user.name + ' focuses on channeling their power!'
        );

        when(user.effectStack.getAllByFilter(::(value) <-
          ATTACK_SHIFTS->findIndex(:value.id) != -1
        )->size == 0) ::<= {
          windowEvent.queueMessage(
            text: '...but ' + user.name + ' had no attack shifts to channel!'
          );
        
          return Arts.CANCEL_MULTITURN;
        }       
        
      }
      
      
      // now to attack 
      @:which = user.effectStack.getAllByFilter(::(value) <-
        ATTACK_SHIFTS->findIndex(:value.id) != -1
      );
      
      // could have lost it on previous turn
      when(which->size == 0)
        windowEvent.queueMessage(
          text: user.name + ' had no attack shifts to channel into an attack!'
        );
        
      @:theOne = random.pickArrayItem(:which).id;
      @:theSet = user.effectStack.getAllByFilter(::(value) <- value.id == theOne);
      
      @:damageType = match(theOne) {
        ('base:burning'): Damage.TYPE.FIRE,
        ('base:icy'): Damage.TYPE.ICE,
        ('base:shock'): Damage.TYPE.THUNDER,
        ('base:shimmering'): Damage.TYPE.LIGHT,
        ('base:dark'): Damage.TYPE.DARK,
        ('base:poison'): Damage.TYPE.POISON
      }
      
      
      if (theSet->size >= 3) ::<= {
        windowEvent.queueMessage(
          text: user.name + ' unleashes all their power!'
        );
        
        targets[0].damage(attacker:user, damage:Damage.new(
          amount:999999,
          damageType,
          damageClass:Damage.CLASS.HP
        ),dodgeable: false);         
      } else ::<= {
        user.attack(
          target:targets[0],
          damage: Damage.new(
            amount:Arts.find(:'base:b215').baseDamage(level, user) * (1.0 + 0.2 * theSet->size),
            damageType,
            damageClass: Damage.CLASS.HP
          ),
          targetPart:targetParts[0],
          targetDefendPart:targetDefendParts[0]
        ); 
      }
      
      user.removeEffectsByFilter(::(value) <- 
        theSet->findIndex(:value) != -1
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b216',
    id : 'base:b216',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALL,
    keywords : ['base:attack-shifts', 'base:resistance-shifts', 'base:cursed-shifts'],
    description: "Randomly selects a set of attack shifts to be removed from the user. For each shift removed this way, adds a respective resistance shift on all allies and adds a respective cursed shift on all enemies for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(user.effectStack.getAllByFilter(::(value) <-
        ATTACK_SHIFTS->findIndex(:value.id) != -1
      )->size == 0) false;
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:which = user.effectStack.getAllByFilter(::(value) <-
        ATTACK_SHIFTS->findIndex(:value.id) != -1
      );
      
      // could have lost it on previous turn
      when(which->size == 0)
        windowEvent.queueMessage(
          text: user.name + ' had no attack shifts to channel!'
        );
        
      @:theOne = random.pickArrayItem(:which).id;
      @:theSet = user.effectStack.getAllByFilter(::(value) <- value.id == theOne);
      
      @:m = match(theOne) {
        ('base:burning'):   ['base:fire-guard', 'base:fire-curse'],
        ('base:icy'):       ['base:ice-guard', 'base:ice-curse'],
        ('base:shock'):     ['base:thunder-guard', 'base:thunder-curse'],
        ('base:shimmering'):['base:light-guard', 'base:light-curse'],
        ('base:dark'):      ['base:dark-guard', 'base:dark-curse'],
        ('base:poison'):    ['base:poison-guard', 'base:poison-curse']
      }
      
      foreach(user.battle.getAllies(:user)) ::(k, ally) {
        ally.addEffect(from:user, id:[0], durationTurns:3);
      }

      foreach(user.battle.getEnemies(:user)) ::(k, enm) {
        enm.addEffect(from:user, id:[1], durationTurns:3);
      }
      
      user.removeEffectsByFilter(::(value) <- 
        theSet->findIndex(:value) != -1
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b217',
    id : 'base:b217',
    notifCommit : "$1 begins to glow!",
    notifFail : "...but nothing happened!",
    targetMode : TARGET_MODE.ALLALLY,
    keywords : [],
    description: "Grants each of the user's positive effects to each other ally. The durations of each effect are preserved.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      when(user.effectStack.getAllByFilter(::(value) <-
        (Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF)  == 0 &&
        (Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) == 0
      )->size == 0) false;
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:which = user.effectStack.getAllByFilter(::(value) <-
        (Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF)  == 0 &&
        (Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) == 0
      );
      
      when(which->size == 0) Arts.FAIL;

      foreach(targets) ::(k, ally) {
        when(ally == user) empty;
        foreach(which) ::(k, v) {
          ally.addEffect(
            from:user, 
            id:v.id, 
            durationTurns: v.duration,
            item: v.id
          );              
        }
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b218',
    id : 'base:b218',
    notifCommit : "$1 begins to glow!",
    notifFail : "...but nothing happened!",
    targetMode : TARGET_MODE.ALLENEMY,
    keywords : [],
    description: "Grants each of the user's negative effects to each enemy. The durations of each effect are preserved.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      when(user.effectStack.getAllByFilter(::(value) <-
        (Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF)  != 0 ||
        (Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0
      )->size == 0) false;
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:which = user.effectStack.getAllByFilter(::(value) <-
        (Effect.find(:value.id).flags & Effect.TRAIT.DEBUFF)  != 0 ||
        (Effect.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0
      );

      when(which->size == 0) Arts.FAIL;

      foreach(targets) ::(k, e) {
        foreach(which) ::(k, v) {
          e.addEffect(
            from:user, 
            id:v.id, 
            durationTurns: v.duration,
            item: v.id
          );              
        }
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b219',
    id : 'base:b219',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:poisoned', 'base:burned'],
    description: "Remove all stacks of Poisoned and Burned from target. Draw a card.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:which = allies.effectStack.getAllByFilter(::(value) <-
        value.id == 'base:burned' ||
        value.id == 'base:poisoned' 
      )
      
      when(which->size == 0) false;
      
      return [random.pickArrayItem(:which)];
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].removeEffectsByFilter(::(value) <-
        value.id == 'base:burned' ||
        value.id == 'base:poisoned' 
      );
      
      user.drawArt(count: 1);
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b220',
    id : 'base:b220',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:cursed-shifts', 'base:elemental-tag'],
    description: "Remove Elemental Tag and cursed shifts from target. Draw a card.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:which = allies.effectStack.getAllByFilter(::(value) <-
        value.id == 'base:elemental-tag' ||
        CURSED_SHIFTS->findIndex(:value.id) != -1
      )
      
      when(which->size == 0) false;
      
      return [random.pickArrayItem(:which)];
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].removeEffectsByFilter(::(value) <-
        value.id == 'base:elemental-tag' ||
        CURSED_SHIFTS->findIndex(:value.id) != -1
      );
      
      user.drawArt(count: 1);
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b221',
    id : 'base:b221',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:seed-effects'],
    description: "Remove all seed effects from target. Draw a card.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:which = allies.effectStack.getAllByFilter(::(value) <-
        value.id == 'base:poisonroot-growing' ||
        value.id == 'base:triproot-growing' ||
        value.id == 'base:healroot-growing'
      )
      
      when(which->size == 0) false;
      
      return [random.pickArrayItem(:which)];
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].removeEffectsByFilter(::(value) <-
        value.id == 'base:poisonroot-growing' ||
        value.id == 'base:triproot-growing' ||
        value.id == 'base:healroot-growing'
      );
      
      user.drawArt(count: 1);
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b222',
    id : 'base:b222',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:banish'],
    description: "Remove all stacks of Banish from target. Draw a card.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:which = allies.effectStack.getAllByFilter(::(value) <-
        value.id == 'base:banish'
      )
      
      when(which->size == 0) false;
      
      return [random.pickArrayItem(:which)];
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].removeEffectsByFilter(::(value) <-
        value.id == 'base:banish'
      );
      
      user.drawArt(count: 1);
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b223',
    id : 'base:b223',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:stunned'],
    description: "Remove then Stunned effect from target. Draw a card.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:which = allies.effectStack.getAllByFilter(::(value) <-
        value.id == 'base:stunned'
      )
      
      when(which->size == 0) false;
      
      return [random.pickArrayItem(:which)];
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].removeEffectsByFilter(::(value) <-
        value.id == 'base:stunned'
      );
      
      user.drawArt(count: 1);
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b224',
    id : 'base:b224',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:ailments'],
    description: "Remove all ailments from target. Draw a card.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:which = allies.effectStack.getAllByFilter(::(value) <-
        AILMENTS->findIndex(:value.id) != -1
      )
      
      when(which->size == 0) false;
      
      return [random.pickArrayItem(:which)];
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].removeEffectsByFilter(::(value) <-
        AILMENTS->findIndex(:value.id) != -1
      );
      
      user.drawArt(count: 1);
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b225',
    id : 'base:b225',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : [],
    description: "Re-adds all given by target's equipment to the target.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:which = allies->filter(::(value) <-
        {:::} {
          foreach(Entity.EQUIP_SLOTS) ::(k, slot) {
            @:eq = value.getEquipped(slot);
            when(eq.equipEffects->size > 0) send(:true);
          }
        }
      );
      
      
      when(which->size == 0) false;
      
      return [random.pickArrayItem(:which)];
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      
      foreach(Entity.EQUIP_SLOTS) ::(k, slot) {
        @:eq = targets[0].getEquipped(slot);
        foreach(eq.equipEffects) ::(k, eff) {
          targets[0].addEffect(
            from:user,
            id: eff,
            durationTurns : 9999999999,
            item: eq
          );  
        }
      }
      user.drawArt(count: 1);
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b226',
    id : 'base:b226',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:clean-blessing'],
    description: "Grants the Clean Blessing effect on target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(
        from:user,
        id: 'base:clean-blessing',
        durationTurns : 3
      );  
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b227',
    id : 'base:b227',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:clean-curse'],
    description: "Inflicts the Clean Curse effect on target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(
        from:user,
        id: 'base:clean-curse',
        durationTurns : 3
      );  
    }
  }
)



Arts.newEntry(
  data: {
    name: '@b228',
    id : 'base:b228',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:innate'],
    description: "For each effect on target where the count of stacks of said effect is 3 or greater, the target gains an additional stack of it as an innate effect.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:whom = (allies)->filter(::(value) <-
        {:::} {
          foreach(value.effectStack.getAll()) ::(k, eff) {
            if ((Effect.find(:eff.id).flags & Effect.TRAIT.BUFF) != 0)
              send(:true);
          }
          
          return false;
        }
      );
      
      when(whom->size == 0) false;
      
      return [random.pickArrayItem(:whom)];
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:table = {};
      foreach(targets[0].effectStack.getAll()) ::(k, eff) {
        if (table[eff.id] == empty)
          table[eff.id] = 1 
        else 
          table[eff.id] += 1
      }
      
      
      foreach(table) ::(k, v) {
        if (v >= 3)
          targets[0].addEffect(
            id: k,
            from : user,
            innate : true
          )
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b229',
    id : 'base:b229',
    notifCommit : "$1 takes aim!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:take-aim'],
    description: "Grants the effect Take Aim on the user.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(id: 'base:take-aim', durationTurns: 9999999999, from:user);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Splinter',
    id : 'base:b230',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:splinter'],
    description: "Grants the Splinter effect for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(
        from:user,
        id: 'base:splinter',
        durationTurns: 3
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Split View',
    id : 'base:b231',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:mirrored'],
    description: "Grants the Mirrored effect to the user for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(
        from:user,
        id: 'base:mirrored',
        durationTurns: 3
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Scorching',
    id : 'base:b232-1',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:scorching', 'base:burned'],
    description: "Grants the Scorching effect to the user for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(
        from:user,
        id: 'base:scorching',
        durationTurns: 3
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Freezing',
    id : 'base:b232-2',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:freezing', 'base:frozen'],
    description: "Grants the Freezing effect to the user for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(
        from:user,
        id: 'base:freezing',
        durationTurns: 3
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Paralyzing',
    id : 'base:b232-3',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:paralyzing', 'base:paralyzed'],
    description: "Grants the Freezing effect to the user for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(
        from:user,
        id: 'base:paralyzing',
        durationTurns: 3
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Petrifying',
    id : 'base:b232-4',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:petrifying', 'base:petrified'],
    description: "Grants the Petrifying effect to the user for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(
        from:user,
        id: 'base:petrifying',
        durationTurns: 3
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Blinding',
    id : 'base:b232-5',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:blinding', 'base:blind'],
    description: "Grants the Blinding effect to the user for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(
        from:user,
        id: 'base:blinding',
        durationTurns: 3
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Seeping',
    id : 'base:b232-6',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:seeping', 'base:poisoned'],
    description: "Grants the Seeping effect to the user for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(
        from:user,
        id: 'base:seeping',
        durationTurns: 3
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: '@base:b233',
    id : 'base:b233',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:dampen-multi-hit'],
    description: "Inflicts the Dampen Multi-hit effect on a target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(
        from:user,
        id: 'base:dampen-multi-hit',
        durationTurns: 3
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: '@base:b234',
    id : 'base:b234',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:multi-hit-guard'],
    description: "Grants the Multi-hit Guard effect on a target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(
        from:user,
        id: 'base:multi-hit-guard',
        durationTurns: 3
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Telemarket Leyline',
    id : 'base:b235',
    notifCommit : "A whirlwind of power appears before $1!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : [],
    description: "Summons an ethereal shopkeeper to purchase wares from.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:world = import(module:'game_singleton.world.mt');
      @:Inventory = import(:'game_class.inventory.mt');

      windowEvent.queueNestedResolve(
        onEnter ::{
          @:shopkeep = world.island.newInhabitant();
          shopkeep.name = 'Ethereal Shopkeep';
          
          @:shopInventory = Inventory.new();
          for(0, 35) ::(i) {
            shopInventory.add(item:
              Item.new(
                base:Item.database.getRandomFiltered(
                  filter:::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE)
                ),
                rngEnchantHint:true
              )   
            );       
          }
          
          
          @:buy = import(:'game_function.buyinventory.mt');
          windowEvent.queueMessage(
            speaker: shopkeep.name,
            text: '"A fine day for buying, doncha think?"'
          );
          buy(
            shopkeep,
            inventory:shopInventory,
            onDone ::{
              windowEvent.queueMessage(
                speaker: shopkeep.name,
                text: '"Pleasure doin\' business with ya!"'
              );
            }
          );
        
        }
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Critical Reaction',
    id : 'base:b236',
    notifCommit : "A whirlwind of power appears before $1!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:critical-reaction'],
    description: "Grants the Critical Reaction effect to the user for 6 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:critical-reaction', durationTurns:6);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'First Strike',
    id : 'base:b237',
    notifCommit : "$1 is envolped in a swift wind!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:first-strike'],
    description: "Grants the First Strike effect to the user for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:first-strike', durationTurns:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b238',
    id : 'base:b238',
    notifCommit : "$1 glows!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    keywords : [],
    description: "Immediately plays the next Art at the top of the user's deck for no AP cost.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.REACTION,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:world = import(module:'game_singleton.world.mt');
      @:card = user.deck.draw();
      user.deck.discardFromHand(:card);


      user.deck.revealArt(
        prompt: user.name + ' activated the next Art from their deck!',
        user:user,
        handCard: card
      );
      
      // hacky! but fun. maybe functional
      if (world.party.leader == user) ::<= {
        user.playerUseArt(
          card:card,
          canCancel: false,
          commitAction::(action) {            
            user.battle.entityCommitAction(action, from:user);
          }
        );
      } else ::<= {
        user.battleAI.commitTargettedAction(
          battle:user.battle,
          card: card,
          onCommit ::(action) {
            user.battle.entityCommitAction(action, from:user);
          }
        );
        
      }


    }
  }
)


Arts.newEntry(
  data: {
    name: '@b239',
    id : 'base:b239',
    notifCommit : "$1 glows!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : [],
    description: "Immediately plays the Art at the bottom of the user's discard pile for no AP cost.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.REACTION,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      when(user.deck.discardPile->size == 0) Arts.FAIL;
      @:card = user.deck.discardPile[user.deck.discardPile->size-1];
      @:world = import(module:'game_singleton.world.mt');
      


      user.deck.revealArt(
        prompt: user.name + ' activated the Art from the bottom of their discard pile!',
        user:user,
        handCard: card
      );
      
      // hacky! but fun. maybe functional
      if (world.party.leader == user) ::<= {
        user.playerUseArt(
          card:card,
          canCancel: false,
          commitAction::(action) {            
            user.battle.entityCommitAction(action, from:user);
          }
        );
      } else ::<= {
        user.battleAI.commitTargettedAction(
          battle:user.battle,
          card: card,
          onCommit ::(action) {
            user.battle.entityCommitAction(action, from:user);
          }
        );
        
      }


    }
  }
)



Arts.newEntry(
  data: {
    name: 'Cascading Flash',
    id : 'base:b240',
    notifCommit : "$1 glows!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:cascading-flash'],
    description: "Grants the Cascading Flash effect to the user for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.REACTION,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:cascading-flash', durationTurns:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b241',
    id : 'base:b241',
    notifCommit : Arts.NO_NOTIF,
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : [],
    description: "View the next 3 Arts of the user's deck. Draw one and discard the rest.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.REACTION,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:world = import(module:'game_singleton.world.mt');

      @:cards = [
        user.deck.draw(),
        user.deck.draw(),
        user.deck.draw()
      ]

      when(user != world.party.leader) ::<= {
        windowEvent.queueMessage(
          text: user.name + ' picks one of 3 Arts.'
        );

        @:keep = random.pickArrayItem(:cards);
        foreach(cards) ::(k, v) {
          when(v == keep) empty;
          user.deck.discardFromHand(:v);
        }

      }
      
      windowEvent.queueNestedResolve(
        onEnter :: {
          windowEvent.queueMessage(
            text: 'Of these 3 Arts, choose one to keep in your hand.'
          );
          user.deck.viewCards(
            user, 
            cards, 
            canCancel:false, 
            onChoice ::(choice) {
              @:keep = cards[choice-1];
              foreach(cards) ::(k, v) {
                when(v == keep) empty;
                user.deck.discardFromHand(:v);
              }
            }
          );

        }
      );


    }
  }
)




Arts.newEntry(
  data: {
    name: 'Clairvoyance',
    id : 'base:b242',
    notifCommit : "$1 focuses!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:clairvoyance'],
    description: "Grants the Clairvoyance effect to the user for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.REACTION,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:claivoyance', durationTurns:3);
    }
  }
)



Arts.newEntry(
  data: {
    name: 'Scatterbrained',
    id : 'base:b243',
    notifCommit : "$1 focuses!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:scatterbrained'],
    description: "Grants the Scatterbrained effect to the user for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.REACTION,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:scatterbrained', durationTurns:3);
    }
  }
)



Arts.newEntry(
  data: {
    name: '@b244',
    id : 'base:b244',
    notifCommit : '$1 attacks in a focused blast $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    keywords : [],
    description: "Deals fire damage to a target based on the user's INT. It deals one additonal damage for each effect the user\'s allies have.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) <- user.stats.INT * (0.5) * level,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @effCount = 0;
      foreach( user.battle.getAllies(:user)) ::(k, v) {
        effCount += v.effectStack.getAll()->size;
      }
  
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            damage: Damage.new(
              amount:Arts.find(:'base:b244').baseDamage(level, user) + effCount,
              damageType : Damage.TYPE.FIRE,
              damageClass: Damage.CLASS.HP
            ),
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
    name: 'Antimagic Trap',
    id : 'base:antimagic-trap',
    notifCommit : '$1 casts Antimagic Trap on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Removes all status ailments and most negative effects.",
    keywords : ['base:ailment'],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : TRAITS.MAGIC | TRAITS.HEAL,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Effect = import(module:'game_database.effect.mt');
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].removeEffectsByFilter(
            ::(value) <- 
              ((Arts.find(:value.id).flags & Effect.TRAIT.AILMENT) != 0) ||
              ((Arts.find(:value.id).flags & Effect.TRAIT.DEBUFF) != 0)
          );
        }
      );
    }
  }
)   


Arts.newEntry(
  data: {
    name: 'Light Guard',
    id : 'base:b247',
    notifCommit : "$1 casts Light Guard!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:light-guard'],
    description: "Grants the Light Guard effect to the target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.COMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:light-guard', durationTurns:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Multi Guard',
    id : 'base:b248',
    notifCommit : "$1 casts Multi Guard!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:multi-guard'],
    description: "Grants the Multi Guard effect to the target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    oncePerBattle : false,
    canBlock : true,
    kind : KIND.EFFECT,
    traits : TRAITS.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:multi-guard', durationTurns:3);
    }
  }
)

};

Arts = class(
  inherits: [Database],
  define::(this) {
    this.interface = {   
      NO_NOTIF : {get ::<- '[[]]'}, 
      FAIL : {get ::<- '[[]]'},
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
          (128): 'Support',
          (256): 'Light',
          (512): 'Dark',
          (1024): 'Poison',
          (2048): 'Special',
          (4096): 'Costless'
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
    
    // String to display when committing the action 
    // and when the action fails to occur.
    //
    // $1 is for the user's name 
    // $2 is for the first target's name
    notifCommit : String,
    notifFail : String,
    
    // an array of keywords that will "hyperlink" when 
    // the art is chosen graphically. Can either be 
    // IDs of effects or IDs of ArtsTerms.
    keywords : Object,
    description : String,
    targetMode : Number,
    usageHintAI : Number,
    // returns false if conditions arent good to use the art. 
    // If returns empty, behavior continues as normal. 
    // If returns an object, should contain the targets for 
    // that Art that should be used
    shouldAIuse : Function, 
    oncePerBattle : Boolean,
    kind : Number,
    traits : Number,
    rarity : Number,
    baseDamage : Function,
    durationTurns : Number, // multiduration turns supercede the choice of action
    canBlock : Boolean, // whether the targets get a chance to block

    onAction : Function
  },
  reset
);



return Arts;
