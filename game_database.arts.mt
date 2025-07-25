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

@:A_LOT = 999999999;

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
  SPECIAL : 3,
  FIELD : 4
}

@RARITY = {
  COMMON : 0,
  UNCOMMON : 1,
  RARE : 2,
  EPIC : 3
}

@:TRAIT = {
  PHYSICAL : 1,
  MAGIC : 2,
  HEAL : 2**2,
  FIRE : 2**3,
  ICE : 2**4,
  THUNDER : 2**5,
  
  SUPPORT : 2**6,
  LIGHT : 2**7,
  DARK : 2**8,
  POISON : 2**9,
  SPECIAL : 2**10,
  COSTLESS : 2**11,
  MULTIHIT : 2**12,
  
  CAN_BLOCK : 2**13,
  ONCE_PER_BATTLE : 2**14,
  
  COMMON_ATTACK_SPELL : 2**15
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
@:Effect = import(module:'game_database.effect.mt');
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
    kind : KIND.ABILITY,
    traits : TRAIT.PHYSICAL | TRAIT.SPECIAL | TRAIT.COSTLESS | TRAIT.CAN_BLOCK,
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
    description: "Deals 1 damage. 5% chance to 1hit K.O. Each level increases the chance by 5%.",
    keywords : [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    kind : KIND.ABILITY,
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
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
                amount:A_LOT,
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
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
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.MULTIHIT | TRAIT.CAN_BLOCK,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
              traits: Damage.TRAIT.MULTIHIT
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
              traits: Damage.TRAIT.MULTIHIT
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
    traits : TRAIT.PHYSICAL | TRAIT.MULTIHIT | TRAIT.CAN_BLOCK,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
              traits: Damage.TRAIT.MULTIHIT
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
              traits: Damage.TRAIT.MULTIHIT
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
              traits: Damage.TRAIT.MULTIHIT
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {

      @:world = import(module:'game_singleton.world.mt');
      windowEvent.queueCustom(
        onEnter :: {

          ::? {
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
    traits : TRAIT.MAGIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      windowEvent.queueCustom(
        onEnter :: {

          ::? {
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
    description: "Damages a target with Fire based on the user's INT. Cannot be blocked. If night time, the damage is boosted. Additional levels boost the damage further.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC | TRAIT.FIRE,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
              damageClass: Damage.CLASS.HP,
              traits : Damage.TRAIT.UNBLOCKABLE
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
    description: "Damages a target with Fire based on the user's INT. Cannot be blocked. If day time, the damage is boosted.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC | TRAIT.FIRE,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
              damageClass: Damage.CLASS.HP,
              traits : Damage.TRAIT.UNBLOCKABLE
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
    description: "Damages all enemies with Fire based on the user's INT. Cannot be blocked. If day time, the damage is boosted.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    traits : TRAIT.MAGIC | TRAIT.FIRE,
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
                damageClass: Damage.CLASS.HP,
                traits : Damage.TRAIT.UNBLOCKABLE
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
    traits : TRAIT.MAGIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC | TRAIT.ICE | TRAIT.MULTIHIT | TRAIT.CAN_BLOCK,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
              traits: Damage.TRAIT.MULTIHIT
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.MULTIHIT | TRAIT.CAN_BLOCK,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
              traits: Damage.TRAIT.MULTIHIT
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
              traits: Damage.TRAIT.MULTIHIT
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.POISON | TRAIT.CAN_BLOCK,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user)<- user.stats.ATK * (0.3) * (1 + (level-1)*0.05) + (level-1),
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
    traits : TRAIT.PHYSICAL | TRAIT.LIGHT | TRAIT.CAN_BLOCK,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.ONCE_PER_BATTLE,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      
    },
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
    traits : TRAIT.PHYSICAL | TRAIT.ONCE_PER_BATTLE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.ONCE_PER_BATTLE,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage::(level, user) <- user.stats.ATK * (0.3) * (1 + (level-1)*0.07) + (level-1),
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
    traits : TRAIT.HEAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    description: "Heals a target by 20%.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.HEAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].heal(amount:(0.2 * targets[0].stats.HP)->ceil);
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
    traits : TRAIT.HEAL,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
                amount:3
              );    
            }
          )          
        },

        default: ::<= {
          windowEvent.queueMessage(text: 'The snack tastes great!');
          windowEvent.queueCustom(
            onEnter :: {
              targets[0].heal(
                amount:((targets[0].stats.HP*0.25)->ceil)
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
    name: 'Summon: Slimeling',
    id : 'base:summon-slimeling',
    notifCommit : '$1 summons a Slimeling!',
    notifFail : '...but the summoning fizzled!',
    targetMode : TARGET_MODE.NONE,
    description: 'Summons a slimeling to fight by your side.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      @:Species = import(module:'game_database.species.mt');

      // limit 2 summons at a time.
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAIT.SUMMON) != 0)->size >= 2
      ) Arts.FAIL


      @:Entity = import(module:'game_class.entity.mt');
      @:sprite = Entity.new(
        island : world.island,
        speciesHint: 'base:slimeling',
        professionHint: 'base:slimeling',
        levelHint:1
      );
      sprite.stats.load(serialized:StatSet.new(
        HP:   1,
        AP:   1,
        ATK:  1,
        INT:  1,
        DEF:  1,
        LUK:  1,
        SPD:  1,
        DEX:  1
      ).save());
      sprite.supportArts = [];      

      sprite.name = 'the Slimeling';
            
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
    name: 'Summon: Fire Sprite',
    id : 'base:summon-fire-sprite',
    notifCommit : '$1 summons a Fire Sprite!',
    notifFail : '...but the summoning fizzled!',
    targetMode : TARGET_MODE.NONE,
    description: 'Summons a fire sprite to fight on your side. Additional levels makes the summoning stronger. If 2 or more summons exist on the user\'s side of battle, the summoning fails.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      @:Species = import(module:'game_database.species.mt');

      // limit 2 summons at a time.
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAIT.SUMMON) != 0)->size >= 2
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Species = import(module:'game_database.species.mt');
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAIT.SUMMON) != 0)->size >= 2
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Species = import(module:'game_database.species.mt');
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAIT.SUMMON) != 0)->size >= 2
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Species = import(module:'game_database.species.mt');
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAIT.SUMMON) != 0)->size >= 2
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        @:Species = import(module:'game_database.species.mt');
        return [...enemies]->filter(::(value) <- (value.species.traits & Species.TRAIT.SUMMON) != 0)->size > 0;
    },
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Species = import(module:'game_database.species.mt');

      windowEvent.queueMessage(
        text: user.name + ' casts Unsummon!'
      );

      windowEvent.queueCustom(
        onEnter :: {
          foreach(targets) ::(k, target) {
            if ((target.species.traits & Species.TRAIT.SUMMON) != 0) ::<= {
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
    description: 'Magick that damages a target with fire based on INT. Cannot be blocked. Additional levels increase its potency.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC | TRAIT.FIRE | TRAIT.COMMON_ATTACK_SPELL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) <- user.stats.INT * (1.2) * (1 + (level-1)*0.15),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            targetDefendPart:-1,
            targetPart: Entity.DAMAGE_TARGET.BODY,
            damage: Damage.new(
              amount:Arts.find(:'base:fire').baseDamage(level, user),
              damageType : Damage.TYPE.FIRE,
              damageClass: Damage.CLASS.HP,
              traits: Damage.TRAIT.UNBLOCKABLE
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
    traits : TRAIT.MAGIC | TRAIT.FIRE,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC | TRAIT.FIRE| TRAIT.COMMON_ATTACK_SPELL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) <- user.stats.INT * (2.0) * (1 + (level-1) * 0.15),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            targetDefendPart:-1,
            targetPart: Entity.DAMAGE_TARGET.BODY,
            damage: Damage.new(
              amount: Arts.find(:'base:flare').baseDamage(level, user),
              damageType : Damage.TYPE.FIRE,
              damageClass: Damage.CLASS.HP,
              traits: Damage.TRAIT.UNBLOCKABLE
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
    traits : TRAIT.MAGIC,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        return [...enemies]->filter(::(value) <- ::? {
          foreach(Entity.EQUIP_SLOTS)::(i, slot) {
            @out = value.getEquipped(slot);
            if (out != empty && out.base.name != 'base:none') send(:true);
          }        
          return false
        })
    },
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
    description: 'Multi-hit magick that damages all enemies with ice based on INT. Cannot be blocked.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC | TRAIT.ICE | TRAIT.MULTIHIT | TRAIT.COMMON_ATTACK_SPELL,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
                traits: Damage.TRAIT.MULTIHIT | Damage.TRAIT.UNBLOCKABLE
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
    description: 'Multi-hit magick that causes enemies to spontaneously combust in a cold, blue flame. Cannot be blocked. Damage is based on INT with an additional chance to Freeze the hit targets. Additional levels increase damage.',
    keywords : ['base:frozen'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC | TRAIT.ICE | TRAIT.MULTIHIT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
                traits: Damage.TRAIT.MULTIHIT | Damage.TRAIT.UNBLOCKABLE
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC | TRAIT.FIRE | TRAIT.MULTIHIT | TRAIT.COMMON_ATTACK_SPELL,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) <- user.stats.INT * (0.85) * (1 + (level-1)*0.1),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      foreach((user.battle.getEnemies(:user)))::(index, enemy) {
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target:enemy,
              targetPart: Entity.DAMAGE_TARGET.BODY,
              targetDefendPart: -1,
              damage: Damage.new(
                amount:Arts.find(:'base:explosion').baseDamage(level, user),
                damageType : Damage.TYPE.FIRE,
                damageClass: Damage.CLASS.HP,
                traits: Damage.TRAIT.MULTIHIT | Damage.TRAIT.UNBLOCKABLE
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
    traits : TRAIT.MAGIC | TRAIT.COMMON_ATTACK_SPELL,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    description: 'Multi-hit magick that deals 4 random strikes based on INT. Cannot be blocked. Each additional level deals an additional 2 strikes.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC | TRAIT.THUNDER | TRAIT.MULTIHIT | TRAIT.COMMON_ATTACK_SPELL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
                traits: Damage.TRAIT.MULTIHIT | Damage.TRAIT.UNBLOCKABLE
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
    traits : TRAIT.PHYSICAL | TRAIT.MULTIHIT | TRAIT.CAN_BLOCK,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
                traits: Damage.TRAIT.MULTIHIT
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
    description: "Heals a target by 20% HP. Additional levels increase potency by 10%.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC | TRAIT.HEAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].heal(amount:(targets[0].stats.HP*(0.2 + 0.1*(level-1)))->ceil);
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
    keywords : ['base:ailments'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC | TRAIT.HEAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Effect = import(module:'game_database.effect.mt');
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].removeEffectsByFilter(
            ::(value) <- 
              ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0) ||
              ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0)
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    description: "Heals all party members by 20%. Additional levels increase the effect by 5%.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC | TRAIT.HEAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      foreach(targets)::(i, target) {
        windowEvent.queueCustom(
          onEnter :: {
            target.heal(amount:(target.stats.HP*(0.2 + 0.05*(level-1)))->ceil);
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.HEAL | TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC | TRAIT.HEAL,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.HEAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.HEAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    name: 'Confusion',
    id : 'base:confusion',
    notifCommit : '$1 tries to confuse $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Inflicts the Confused status on a target for 5 turns.',
    keywords : ['base:confused'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:confused', durationTurns: 5);
        }
      )
    }
  }
)   

Arts.newEntry(
  data: {
    name: 'Taunt',
    id : 'base:taunt',
    notifCommit : '$1 tries to taunt $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Inflicts the Taunted status on a target for 3 turns.',
    keywords : ['base:taunted'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:taunted', durationTurns: 3);
        }
      )
    }
  }
) 

Arts.newEntry(
  data: {
    name: 'Terrify',
    id : 'base:terrify',
    notifCommit : '$1 tries to terrify $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Inflicts the Terrified status on a target for 3 turns.',
    keywords : ['base:terrified'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:terrified', durationTurns: 3);
        }
      )
    }
  }
) 


Arts.newEntry(
  data: {
    name: 'Field Barrier',
    id : 'base:field-barrier',
    notifCommit : '$1 casts Field Barrier!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Grants the Field Barrier status on a target for 3 turns.',
    keywords : ['base:field-barrier'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:field-barrier', durationTurns: 3);
        }
      )
     }
  }
) 



Arts.newEntry(
  data: {
    name: 'Potentiality Shard',
    id : 'base:potentiatily-shard',
    notifCommit : '$1 uses a Potentiality Shard!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Grants the Potentiality Shard status on a target.',
    keywords : ['base:potentiality-shard'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:potentiality-shared', durationTurns: A_LOT);
        }
      )
     }
  }
) 

Arts.newEntry(
  data: {
    name: 'Copy Shard',
    id : 'base:potentiatily-shard',
    notifCommit : '$1 uses a Copy Shard!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Grants the Copy Shard status on a target.',
    keywords : ['base:copy-shard'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:copy-shared', durationTurns: A_LOT);
        }
      )
     }
  }
) 


Arts.newEntry(
  data: {
    name: 'Suppressor',
    id : 'base:field-barrier',
    notifCommit : '$1 casts Suppressor!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: 'Grants the Suppressor status on a target for 2 turns.',
    keywords : ['base:suppressor'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:suppressor', durationTurns: 2);
        }
      )
     }
  }
) 


Arts.newEntry(
  data: {
    name: 'Block',
    id : 'base:block',
    notifCommit : '$1 begins to focus!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Grants the Block status to the user.',
    keywords : ['base:block'],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.addEffect(from:user, id: 'base:block', durationTurns: A_LOT);
        }
      )
    }
  }
) 

Arts.newEntry(
  data: {
    name: 'Slingshot Block',
    id : 'base:slingshot-block',
    notifCommit : '$1 begins to focus!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Grants the Slingshot Block status to the user.',
    keywords : ['base:slingshot-block'],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.addEffect(from:user, id: 'base:slingshot-block', durationTurns: A_LOT);
        }
      )
    }
  }
) 


Arts.newEntry(
  data: {
    name: 'Ricochet Block',
    id : 'base:ricochet-block',
    notifCommit : '$1 begins to focus!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Grants the Ricochet Block status to the user.',
    keywords : ['base:ricochet-block'],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.addEffect(from:user, id: 'base:ricochet-block', durationTurns: A_LOT);
        }
      )
    }
  }
) 



Arts.newEntry(
  data: {
    name: 'Reflective Block',
    id : 'base:reflective-block',
    notifCommit : '$1 begins to focus!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Grants the Reflective Block status to the user.',
    keywords : ['base:reflective-block'],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.addEffect(from:user, id: 'base:reflective-block', durationTurns: A_LOT);
        }
      )
    }
  }
) 

Arts.newEntry(
  data: {
    name: 'Conductive Block',
    id : 'base:conductive-block',
    notifCommit : '$1 begins to focus!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Grants the Conductive Block status to the user.',
    keywords : ['base:conductive-block', 'base:next-attack-x2'],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : 0,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          user.addEffect(from:user, id: 'base:conductive-block', durationTurns: A_LOT);
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SPECIAL | TRAIT.COSTLESS,
    kind : KIND.SPECIAL,
    rarity : RARITY.COMMON,
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC | TRAIT.FIRE,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC | TRAIT.ICE,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC | TRAIT.THUNDER,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    kind : KIND.EFFECT,
    traits : TRAIT.SPECIAL,
    rarity : RARITY.RARE,
    isSupport: false,
    usageHintAI: USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:item = extraData[0];
      when (targets->size == 0) ::<= {
        foreach(item.useEffects)::(index, effect) {  
          user.addEffect(from:user, id:effect, item:item, durationTurns:10);              
        }
      }

      
      foreach(item.useEffects)::(index, effect) {  
        foreach(targets)::(t, target) {
          target.addEffect(from:user, id:effect, item:item, durationTurns:10);              
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
    kind : KIND.EFFECT,
    traits : TRAIT.SPECIAL | TRAIT.COSTLESS,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        allies = [...allies]->filter(::(value) <- value.getEquipped(
            :Entity.EQUIP_SLOTS.ARMOR
        ).base.id != 'base:none');
        when(allies->size == 0) false;        
        return [random.pickArrayItem(:allies)];    
    },
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        enemies = [...enemies]->filter(::(value) <- value.getEquipped(
            :Entity.EQUIP_SLOTS.HAND_LR
        ).base.id != 'base:none');
        when(enemies->size == 0) false;
        return [random.pickArrayItem(:enemies)];    
    },
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        enemies = [...enemies]->filter(::(value) <- value.getEquipped(
            :Entity.EQUIP_SLOTS.HAND_LR
        ).base.id != 'base:none');
        when(enemies->size == 0) false;
        return [random.pickArrayItem(:enemies)];
    },
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
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.COMMON,
    usageHintAI: USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
        allies = [...allies]->filter(::(value) <- value.getEquipped(
            :Entity.EQUIP_SLOTS.ARMOR
        ).base.id != 'base:none');
        when(allies->size == 0) false;
        return [random.pickArrayItem(:allies)];
    },
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
    name: 'Make: Heal Potion',
    id : 'base:make-heal-potion',
    notifCommit : '$1 attempts to make a potion!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Uses 2 Ingredients to make a healing potion.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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

      @:item = Item.new(
        base:Item.database.find(id:'base:potion'),
        creationHint:0
      );

      windowEvent.queueMessage(text: '... and made a ' + item.name + '!');
      windowEvent.queueCustom(
        onEnter :: {

          inventory.removeByID(id:'base:ingredient');
          inventory.removeByID(id:'base:ingredient');
          inventory.add(item);              
        }
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Make: Buff Potion',
    id : 'base:make-buff-potion',
    notifCommit : '$1 attempts to make a potion!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Uses 2 Ingredients to make a buffing potion.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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

      @:item = Item.new(
        base:Item.database.find(id:'base:potion'),
        creationHint:1
      );

      windowEvent.queueMessage(text: '... and made a ' + item.name + '!');
      windowEvent.queueCustom(
        onEnter :: {

          inventory.removeByID(id:'base:ingredient');
          inventory.removeByID(id:'base:ingredient');
          inventory.add(item);              
        }
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Make: Debuff Potion',
    id : 'base:make-debuff-potion',
    notifCommit : '$1 attempts to make a potion!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Uses 2 Ingredients to make a debuffing potion.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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

      @:item = Item.new(
        base:Item.database.find(id:'base:potion'),
        creationHint:2
      );

      windowEvent.queueMessage(text: '... and made a ' + item.name + '!');
      windowEvent.queueCustom(
        onEnter :: {

          inventory.removeByID(id:'base:ingredient');
          inventory.removeByID(id:'base:ingredient');
          inventory.add(item);              
        }
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Make: Essence',
    id : 'base:make-essence',
    notifCommit : '$1 attempts to make essence!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Uses 2 Ingredients to make an essence of an effect.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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

      @:item = Item.new(
        base:Item.database.find(id:'base:essence')
      );

      windowEvent.queueMessage(text: '... and made a ' + item.name + '!');
      windowEvent.queueCustom(
        onEnter :: {

          inventory.removeByID(id:'base:ingredient');
          inventory.removeByID(id:'base:ingredient');
          inventory.add(item);              
        }
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Mix Potion',
    id : 'base:mix-potion',
    notifCommit : '$1 attempts to combine 2 Potions!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'Uses 2 Potions to make a new Potion of combined effects.',
    keywords: ['base:ingredient'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      @inventory;
      if (world.party.isMember(entity:user)) ::<= {
        inventory = world.party.inventory;
      } else ::<= {
        inventory = user.inventory;
      }
      
      
      @:pickPartyItem = import(:'game_function.pickpartyitem.mt');
      @alreadyPicked = empty;
      @:pick :: {
        pickPartyItem(
          canCancel:true,
          filter::(value) <- value.base.id == 'base:potion' && alreadyPicked != value,
          onCancel ::{
            alreadyPicked = empty;
            pick();
          },
          keep : false,
          onPick ::(item, equippedBy) {
            when (alreadyPicked == empty) ::<= {
              alreadyPicked = item;
              pick();
            }
            
            windowEvent.queueMessage(
              text: 'Mixing ' + alreadyPicked.name + ' with ' + item.name + '.'
            );
            
            windowEvent.queueAskBoolean(
              prompt: 'Mix these 2?',
              onChoice::(which) {
                when(which == false) ::<= {
                  alreadyPicked = empty;
                  pick();
                }
                
                @:mixed = Item.new(
                  base: Item.database.find(id:'base:potion')
                );
                
                mixed.name = user.name + '\'s Potion';
                mixed.useEffects = [
                  'base:consume-item',
                  ...[alreadyPicked.useEffects->filter(::(value) <- value != 'consume-item')],
                  ...[item.useEffects->filter(::(value) <- value != 'consume-item')]
                ]
                
                alreadyPicked.throwOut();
                item.throwOut();
                inventory.remove(:alreadyPicked);
                inventory.remove(:item);
                windowEvent.queueMessage(
                  text: 'A new potion has been brewed!'
                );
                
                mixed.describe();
                inventory.add(item:mixed);
              }
            );  
          }
        )
      }
      pick();
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
    traits : TRAIT.PHYSICAL | TRAIT.SPECIAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
      traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
      rarity : RARITY.RARE,
      usageHintAI : USAGE_HINT.OFFENSIVE,
      shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SUPPORT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    description: 'Discards entire hand, gain 10% HP.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(user.hp == user.stats.HP) false;
    },
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      user.deck.hand = [];
      foreach(user.deck.hand) ::(k, c) {
        user.deck.discardFromHand(:c);
      }
      user.heal(amount:(user.stats.HP * 0.1)->ceil);
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
    description: 'Sacrifice item, heal 15% HP.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:pickitem = import(:'game_function.pickitem.mt');
      @:world = import(module:'game_singleton.world.mt');
      if (world.party.leader == user) ::<= {
        pickitem(
          canCancel: false,
          inventory : world.party.inventory,
          onPick ::(item){
            world.party.inventory.remove(:item);
            user.heal(amount:(user.stats.HP * 0.15)->ceil);
          }
        );
      } else ::<= {
        user.heal(amount:(user.stats.HP * 0.15)->ceil);
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
    traits : TRAIT.SUPPORT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
      if (world.party.leader == user) ::<= {
        pickitem(
          canCancel: false,
          keep: false,
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
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:pickitem = import(:'game_function.pickitem.mt');
      @:world = import(module:'game_singleton.world.mt');
      if (world.party.leader == user) ::<= {
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
    traits : TRAIT.SUPPORT,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SUPPORT,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SUPPORT,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SUPPORT,
    rarity : RARITY.COMMON,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SUPPORT | TRAIT.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
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
    traits : TRAIT.SUPPORT | TRAIT.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
    traits : TRAIT.SUPPORT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(allies->findIndex(:reactTo) != -1) false;
    },
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
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
    description: "Deal a physical attack to target which has a base damage value equal to how much HP is missing from this character\'s current max HP. This damage is unblockable.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(user.hp == user.stats.HP) false;
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.PHYSICAL,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.PHYSICAL,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id:'base:banishing-light', durationTurns:A_LOT); 
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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

          targets[0].addEffect(from:user, id:'base:next-attack-x2', durationTurns:A_LOT);
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
    kind : KIND.REACTION,
    traits : TRAIT.SUPPORT,
    rarity : RARITY.RARE,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    id : 'base:bloods-wind',
    notifCommit : '$1 casts Blood\'s Wind on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Sacrifice 2 HP. The target receives the Evade effect for 2 turns.",
    keywords: ['base:evade'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) <- user.hp > 2,
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    kind : KIND.ABILITY,
    traits : TRAIT.SUPPORT | TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
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
            targetPart: Entity.DAMAGE_TARGET.BODY,
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
    kind : KIND.ABILITY,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    name: 'Lesser Banish',
    id : 'base:banish',
    notifCommit : '$1 casts Lesser Banish on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Add 1 Banish stack to target.",
    keywords: ['base:banish'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      for(0, 1) ::(i) {
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:A_LOT);      
      }
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      for(0, 2) ::(i) {
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:A_LOT);      
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Greater Banish',
    id : 'base:greater-banish',
    notifCommit : '$1 casts Greater Banish on $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Add 3 Banish stacks to target.",
    keywords: ['base:banish'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      for(0, 3) ::(i) {
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:A_LOT);      
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Bound Banish',
    id : 'base:bound-banish',
    notifCommit : '$1 casts Bound Banish on $2!',
    notifFail : Arts.NO_NOTIF,    
    targetMode : TARGET_MODE.ONE,
    description: "Paralyze user for 2 turns, preventing their action. Add 3 Banish stacks to target.",
    keywords: ['base:banish', 'base:paralyzed'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
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
                target.addEffect(from:user, id:'base:greater-sol-attunement', durationTurns:A_LOT);
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
    name: 'Refresh',
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
          ::(value) <- (Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0
        )->size > 0
      );
      when(which->size == 0) false;
      
      return [which[0]];
    },
    kind : KIND.ABILITY,
    traits : TRAIT.SUPPORT | TRAIT.ONCE_PER_BATTLE,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');

      @:filter = ::(value) <- (Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0

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
    name: 'Purification',
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
          ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0) ||
                       ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      
      return [which[0]];
    },
    kind : KIND.ABILITY,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC | TRAIT.ONCE_PER_BATTLE,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');

      @:filter = ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0) ||
                              ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0)

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
    name: 'Osmotic Sponge',
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
          ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0) ||
                       ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      return which;
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');


      @:condition = ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0) ||
                                 ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0)
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
    name: 'Chaotic Slurp',
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
          ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.BUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      return which;
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:condition = ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.BUFF) != 0)

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
    name: 'Sip of Chaos',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:effects = random.scrambled(:user.effectStack.getAllByFilter(::(value)<-true));
      @:Effect = import(module:'game_database.effect.mt');

      when(effects->size == 0) Arts.FAIL;


  
      if (effects->size > 2)
          effects->setSize(:2);
  
      user.removeEffectsByFilter(::(value) {
        return ::? {
          foreach(effects) ::(k, v) {
            if (v == value) send(:true);
          }
          return false;
        }
      });
                  

      foreach(effects) ::(k, v) {
        @:newEffect = Effect.getRandomFiltered(::(value) <- (value.traits & Effect.TRAIT.SPECIAL) == 0);
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
    name: 'Miasma Expungement',
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
          ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0) ||
                       ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      
      return [...allies, ...enemies];
    },
    kind : KIND.ABILITY,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      
      @:filter = ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0) ||
                              ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0)
      
      foreach(targets) ::(k, target) {
        target.removeEffectsByFilter(:filter);
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Joy Expungement',
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
          ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.BUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      
      return [...allies, ...enemies];
    },
    kind : KIND.ABILITY,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      
      @:filter = ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.BUFF) != 0)      
      foreach(targets) ::(k, target) {
        target.removeEffectsByFilter(:filter);
      }
    }
  }
)



Arts.newEntry(
  data: {
    name: 'Radiation State',
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
          ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0) ||
                       ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0)
        )
      when(which->size == 0) false;
      
      return [random.pickArrayItem(:enemies)];
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:filter = ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0) ||
                              ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0)
     
     
     
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
    name: 'Chaotic Redistribution',
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
            ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.BUFF) != 0)
          )->size > 0
        )
        ||
        allies->filter(
          ::(value) <- value.effectStack.getAllByFilter(
            ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0) ||
                         ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0)
          )->size > 0
        )
      ) [...allies, ...enemies];

      
      return false;
    },
    kind : KIND.ABILITY,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    kind : KIND.ABILITY,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC | TRAIT.ONCE_PER_BATTLE,
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
      user.deck.purge(:'base:b178');
      
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
    name: 'Chaotic Funnel',
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
          ::(value) <- ((Effect.find(:value.id).traits & Effect.TRAIT.BUFF) != 0)
        )->size > 0
      );
      when(which->size == 0) false;
      return [which[0]];
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Restorative Resonance',
    id : 'base:b180',
    notifCommit : 'Everyone is covered in a weird aura!',
    notifFail : '... But nothing happened!',
    targetMode : TARGET_MODE.ALLALLY,
    description: "Heals the user by 5% HP for each effect that all the user\'s allies have.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      when(user.hp >= user.stats.HP) false;

      // if has any effects, is good to use
      return ::? {
        foreach(allies) ::(k, v) {
          if (v.effectStack.getAll()->size > 0)
            send(:true);
        } 
        return false;
      }
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @tally = 0;
      foreach(targets) ::(k, v) {
        tally += v.effectStack.getAll()->size;
      } 
      
      when(tally == 0) Arts.FAIL;
      
      user.heal(amount:(tally * user.stats.HP * 0.05)->ceil);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Banish Conversion: Negative',
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
          ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF)  != 0) ||
          ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0)
        )->size > 0));
      when(able->size == 0) false;
          
      return [able[0]]
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:all = [...targets[0].effectStack.getAll()->filter(::(value) <- 
        ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF)  != 0) ||
        ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0)
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
    name: 'Banish Conversion: Positive',
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
          ((Effect.find(:value.id).traits & Effect.TRAIT.BUFF)  != 0)
        )->size > 0)
      when(able->size == 0) false;
      return [able[0]];
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:all = [...targets[0].effectStack.getAll()->filter(::(value) <- 
          ((Effect.find(:value.id).traits & Effect.TRAIT.BUFF)  != 0)
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
    name: 'Quantum Rearrangement',
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
          (Effect.find(:value.id).traits & Effect.TRAIT.BUFF)  != 0
        )->size > 0)
      when(able->size == 0) false;
      return [able[0]];
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:all = [...targets[0].effectStack.getAll()->filter(::(value) <- 
        (Effect.find(:value.id).traits & Effect.TRAIT.BUFF)  != 0
      )]
      
      when(all->size == 0) Arts.FAIL;
            
      foreach(all) ::(k, v) {
        @:id = Effect.getRandomFiltered(::(value) <- (value.traits & Effect.TRAIT.SPECIAL) == 0).id;
        targets[0].addEffect(from:user, id, durationTurns:
          v.duration
        );              
      } 
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Destructive Resonance',
    id : 'base:b184',
    notifCommit : 'A mystical light befalls everyone!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALL,
    description: "Deals damage to each combatant equal to their respective number of effects.",
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Banish Conversion: Ultima',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Banishing Regurgitation',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Poison Empowerment',
    id : 'base:b187',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all stacks of the Poisoned effect from target. For each Poisoned stack removed this way, the target heals 20% HP and +25% DEX for 2 turns.",
    keywords: ['base:poisoned'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return ::? {
        foreach(allies) ::(k, v) {
          when (v.effectStack.getAllByFilter(::(value) <- value.id == 'base:poisoned')->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @total = 0;
      @oldPoison = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:poisoned');
      when(oldPoison->size == 0) Arts.FAIL;
      targets[0].removeEffectsByFilter(::(value) <- value.id == 'base:poisoned');
            
      targets[0].heal(amount:(oldPoison->size * 2 * targets[0].stats.HP * 0.2)->ceil);
            
      for(0, oldPoison->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:minor-dex-boost', durationTurns:2);              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Burning Empowerment',
    id : 'base:b188',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all stacks of the Burned effect from target. For each Burned stack removed this way, the target gains 2 HP and +25% DEF for 2 turns.",
    keywords: ['base:burned'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return ::? {
        foreach(allies) ::(k, v) {
          when (v.effectStack.getAllByFilter(::(value) <- value.id == 'base:burned')->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Paralysis Empowerment',
    id : 'base:b189',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all stacks of the Paralyzed effect from target. For each Paralyzed stack removed this way, the target gains 2 AP and +25% INT for 2 turns.",
    keywords: ['base:paralyzed'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return ::? {
        foreach(allies) ::(k, v) {
          when (v.effectStack.getAllByFilter(::(value) <- value.id == 'base:paralyzed')->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Petrification Empowerment',
    id : 'base:b190',
    notifCommit : 'A mystical light is cast on $2!',
    notifFail : '...But nothing happened!',
    targetMode : TARGET_MODE.ONE,
    description: "Removes the Petrified effect from target. The target heals 20% HP and +25% ATK for 3 turns.",
    keywords: ['base:petrified'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return ::? {
        foreach(allies) ::(k, v) {
          when (v.hp < v.stats.HP || v.effectStack.getAllByFilter(::(value) <- value.id == 'base:petrified')->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @total = 0;
      @oldPetr = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:petrified');
      when(oldPetr->size == 0) Arts.FAIL;
      targets[0].removeEffectsByFilter(::(value) <- value.id == 'base:petrified');
            
      targets[0].heal(amount:(oldPetr->size * 2 * targets[0].stats.HP * 0.2)->ceil);
            
      for(0, oldPetr->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:minor-strength-boost', durationTurns:3);              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Negativity Empowerment',
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
      return ::? {
        foreach(allies) ::(k, v) {
          when (v.effectStack.getAllByFilter(::(value) <- 
            (Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0 ||
            (Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF)  != 0
          )->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @total = 0;
      @oldBad = targets[0].effectStack.getAllByFilter(::(value) <- 
        (Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0 ||
        (Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF)  != 0
      );
      when(oldBad->size == 0) Arts.FAIL;
      targets[0].removeEffectsByFilter(::(value) <- 
        (Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0 ||
        (Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF)  != 0      
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
    name: 'Bestow State',
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
      return ::? {
        foreach([...enemies, ...allies]) ::(k, v) {
          when (v.effectStack.getAllByFilter(::(value) <- 
            (Effect.find(:value.id).traits & Effect.TRAIT.BUFF) != 0
          )->size > 0) 
            send(:[v]);
        }      
        
        return false;
      }
    },
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Gifting Tether',
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
        ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0) ||
        ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0)
      )->size == 0) false;

    },
    kind : KIND.ABILITY,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC | TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
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
    name: 'Exchange of Blows',
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
        ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0) ||
        ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0)
      )->size == 0) false;

    },
    kind : KIND.ABILITY,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC | TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
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
    name: 'Venomous Redirection',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC | TRAIT.MULTIHIT | TRAIT.CAN_BLOCK,
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
                traits: Damage.TRAIT.MULTIHIT
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
    name: 'Explosive Redirection',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC | TRAIT.MULTIHIT,
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
                traits: Damage.TRAIT.MULTIHIT
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
    name: 'Unlock Senses',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Bound Weapon',
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
    kind : KIND.ABILITY,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Momentum Preparation',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT,
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
    name: 'Burning Conversion',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Icy Conversion',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Shock Conversion',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Blind Conversion',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Petrified Conversion',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
    name: 'Full Shift Conversion',
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
    kind : KIND.EFFECT,
    traits : TRAIT.SUPPORT | TRAIT.MAGIC,
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
      @:effects = targets[0].effectStack.getAllByFilter(::(value) <- 
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
    name: 'Resonant Rush',
    id : 'base:b205',
    notifCommit : '$1 attacks $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    keywords : [],
    description: "Damages a target based on ATK. For each effect the target has, the damage is boosted by 25%.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    kind : KIND.ABILITY,
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
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
    name: 'Resonant Blast',
    id : 'base:b206',
    notifCommit : '$1 attacks $2! with a magical beam of light!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    keywords : [],
    description: "Damages a target based on INT. For each effect the target has, the damage is boosted by 25%.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    kind : KIND.ABILITY,
    traits : TRAIT.PHYSICAL | TRAIT.CAN_BLOCK,
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
    name: 'Pyre Unleashed',
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
    kind : KIND.EFFECT,
    traits : TRAIT.PHYSICAL | TRAIT.MAGIC | TRAIT.CAN_BLOCK,
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
    name: 'Glacier Unleashed',
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
    kind : KIND.EFFECT,
    traits : TRAIT.PHYSICAL | TRAIT.MAGIC | TRAIT.CAN_BLOCK,
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
    name: 'Pylon Unleashed',
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
    kind : KIND.EFFECT,
    traits : TRAIT.PHYSICAL | TRAIT.MAGIC | TRAIT.CAN_BLOCK,
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
    name: 'Feedback Cascade',
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
    kind : KIND.ABILITY,
    traits : TRAIT.PHYSICAL | TRAIT.MAGIC,
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
    name: 'Chaotic Shift',
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
    kind : KIND.EFFECT,
    traits : TRAIT.PHYSICAL | TRAIT.MAGIC,
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
    name: 'Shift Boost',
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
    kind : KIND.EFFECT,
    traits : TRAIT.PHYSICAL | TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(durationTurns:3, from:user, id: 'base:shift-boost');
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Elemental Radiation',
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
    kind : KIND.ABILITY,
    traits : TRAIT.PHYSICAL | TRAIT.MAGIC | TRAIT.CAN_BLOCK,
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
          amount:A_LOT,
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
    name: 'Elemental Transmutation',
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
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC,
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
    name: 'Resonant Empowerment',
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
        (Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF)  == 0 &&
        (Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) == 0
      )->size == 0) false;
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:which = user.effectStack.getAllByFilter(::(value) <-
        (Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF)  == 0 &&
        (Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) == 0
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
    name: 'Resonant Debilitation',
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
        (Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF)  != 0 ||
        (Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0
      )->size == 0) false;
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:which = user.effectStack.getAllByFilter(::(value) <-
        (Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF)  != 0 ||
        (Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0
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
    name: 'Expel: Brimstone',
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    name: 'Expel: Misalignment',
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    name: 'Expel: Growth',
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    name: 'Expel: Banishment',
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    name: 'Expel Control',
    id : 'base:b223',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:stunned'],
    description: "Remove the Stunned effect from target. Draw a card.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.HEAL,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:which = allies.effectStack.getAllByFilter(::(value) <-
        value.id == 'base:stunned'
      )
      
      when(which->size == 0) false;
      
      return [random.pickArrayItem(:which)];
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    name: 'Expel: Ultima',
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    name: 'Refortification Ultima',
    id : 'base:b225',
    notifCommit : "$1 begins to glow!",
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    keywords : [],
    description: "Copies all Effects given by target's equipment and gives them to the target again.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:which = allies->filter(::(value) <-
        ::? {
          foreach(Entity.EQUIP_SLOTS) ::(k, slot) {
            @:eq = value.getEquipped(slot);
            when(eq.equipEffects->size > 0) send(:true);
          }
        }
      );
      
      
      when(which->size == 0) false;
      
      return [random.pickArrayItem(:which)];
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      
      foreach(Entity.EQUIP_SLOTS) ::(k, slot) {
        @:eq = targets[0].getEquipped(slot);
        foreach(eq.equipEffects) ::(k, eff) {
          targets[0].addEffect(
            from:user,
            id: eff,
            durationTurns : A_LOT,
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
    name: 'Clean Blessing',
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    name: 'Clean Curse',
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    name: 'Resonant Tessellation',
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
        ::? {
          foreach(value.effectStack.getAll()) ::(k, eff) {
            if ((Effect.find(:eff.id).traits & Effect.TRAIT.BUFF) != 0)
              send(:true);
          }
          
          return false;
        }
      );
      
      when(whom->size == 0) false;
      
      return [random.pickArrayItem(:whom)];
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    name: 'Take Aim',
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
    kind : KIND.EFFECT,
    traits : TRAIT.PHYSICAL,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(id: 'base:take-aim', durationTurns: A_LOT, from:user);
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    name: 'Dampen Multi-hit',
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    name: 'Multi-hit Guard',
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:first-strike', durationTurns:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Future Moment',
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
    kind : KIND.REACTION,
    traits : TRAIT.MAGIC,
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
    name: 'Boomerang',
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
    kind : KIND.REACTION,
    traits : TRAIT.MAGIC,
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
    kind : KIND.REACTION,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:cascading-flash', durationTurns:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Divination',
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
    kind : KIND.REACTION,
    traits : TRAIT.MAGIC,
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
    kind : KIND.REACTION,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:scatterbrained', durationTurns:3);
    }
  }
)



Arts.newEntry(
  data: {
    name: 'Resonant Soulfire',
    id : 'base:b244',
    notifCommit : '$1 attacks in a focused blast $2!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONEPART,
    keywords : [],
    description: "Deals fire damage to a target based on the user's INT. It deals one additonal damage for each effect the user\'s allies have.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC,
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
    keywords : ['base:ailments'],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : TRAIT.MAGIC | TRAIT.HEAL,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:Effect = import(module:'game_database.effect.mt');
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].removeEffectsByFilter(
            ::(value) <- 
              ((Effect.find(:value.id).traits & Effect.TRAIT.AILMENT) != 0) ||
              ((Effect.find(:value.id).traits & Effect.TRAIT.DEBUFF) != 0)
          );
        }
      );
    }
  }
)   


Arts.newEntry(
  data: {
    name: 'Half Guard',
    id : 'base:b247',
    notifCommit : "$1 casts Half Guard!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:light-guard'],
    description: "Grants the Light Guard effect to the target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
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
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:multi-guard', durationTurns:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Premonition',
    id : 'base:b251',
    notifCommit : "$1 casts Premonition!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:premonition'],
    description: "Grants the Premonition effect to the target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:premonition', durationTurns:3);
    }
  }
)


/*


// I FUCKED UP I DONT REMEMBER WHAT THIS EFFECT WAS SUPPOSED TO BE
// UUUGHHHHH CRYING AND FARTING

Arts.newEntry(
  data: {
    name: 'Calcification',
    id : 'base:b253',
    notifCommit : "$1 casts Calcification!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:calcification'],
    description: "Grants the Calcification effect to the target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:calcification', durationTurns:3);
    }
  }
)
*/

Arts.newEntry(
  data: {
    name: 'Crustacean Maneuver',
    id : 'base:b254',
    notifCommit : "$1 prepares for incoming damage!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:crustacean-maneuver'],
    description: "Grants the Crustacean Maneuver effect to the target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:crustacean-maneuver', durationTurns:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Lucky Charm',
    id : 'base:b255',
    notifCommit : "$1 casts Lucky Charm",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:lucky-charm'],
    description: "Grants the Lucky Charm effect to the target for 2 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC | TRAIT.ONCE_PER_BATTLE,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:lucky-charm', durationTurns:2);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Spirit Loan',
    id : 'base:b256',
    notifCommit : "$1 casts Spirit Loan",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:spirit-loan'],
    description: "Grants the Spirit Loan effect to the target for 2 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC | TRAIT.ONCE_PER_BATTLE,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:spirit-loan', durationTurns:2);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Procrastinate Death',
    id : 'base:b257',
    notifCommit : "$1 casts Procrastinate Death",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:procrastinate-death'],
    description: "Grants the Procrastinate Death effect to the target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC | TRAIT.ONCE_PER_BATTLE,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:procrastinate-death', durationTurns:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Cheat Death',
    id : 'base:b258',
    notifCommit : "$1 casts Cheat Death",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:cheat-death', 'base:stunned'],
    description: "Grants the Cheat Death effect to the target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC | TRAIT.ONCE_PER_BATTLE,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:cheat-death', durationTurns:3);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Death Reflection',
    id : 'base:b259',
    notifCommit : "$1 casts Death Reflection",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:death-reflection'],
    description: "Grants the Death Reflection effect.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:death-reflection', durationTurns:A_LOT);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Prismatic Wisp',
    id : 'base:prismatic-wisp',
    notifCommit : "$1 casts Prismatic Wisp",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:ailments'],
    description: "Gives the target a random status ailment for 2 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:random.pickArrayItem(:AILMENTS), durationTurns:2);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Limit Break',
    id : 'base:b260',
    notifCommit : "$1 casts Limit Break",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:limit-break', 'base:limit-reached'],
    description: "Grants the Limit Break effect to the caster.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:limit-break', durationTurns:A_LOT);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Resonant Doomsday',
    id : 'base:b261',
    notifCommit : "$1 casts Resonant Doomsday",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:revival-effect'],
    description: "For each Revival effect on a target, deal damage 5 damage. Remove all Revival effects from target.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = enemies->filter(::(value) <- value.effectStack.getAllByFilter(::(value) <- value.traits & Effect.TRAIT.REVIVAL)); 
      when (which->size == 0) false;
      return [random.pickArrayItem(:which)];
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:all = targets[0].effectStack.getAllByFilter(::(value) <- value.traits & Effect.TRAIT.REVIVAL); 
      when(all->size == 0) Arts.FAIL;


      targets[0].effectStack.removeByFilter(::(value) <- value.traits & Effect.TRAIT.REVIVAL)
      
      foreach(all) ::(k, v) {
        targets[0].damage(attacker:user, damage:Damage.new(
          amount:5,
          damageType:Damage.TYPE.DARK,
          damageClass:Damage.CLASS.HP
        ),dodgeable: false, exact:true);
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Shared Salvation',
    id : 'base:b263',
    notifCommit : "$1 casts Shared Salvation",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:revival-effect'],
    description: "Copy all of the user's Revival effects to a target.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(user.effectStack.getAllByFilter(::(value) <- value.traits & Effect.TRAIT.REVIVAL)->size == 0) false;
      
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:Effect = import(module:'game_database.effect.mt');
      @:all = targets[0].effectStack.getAllByFilter(::(value) <- value.traits & Effect.TRAIT.REVIVAL); 
      when(all->size == 0) Arts.FAIL;

      
      foreach(all) ::(k, v) {
        targets[0].addEffect(
          from: user,
          id: v.id,
          durationTurns: v.duration
        );
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Deathly Empowerment',
    id : 'base:b264',
    notifCommit : "$1 casts Deathly Empowerment",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ALL,
    keywords : ['base:revival-effect', 'base:aura'],
    description: "Each combatant gains a stack of the Aura effect for each of the Revival effects on them.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = allies->filter(::(value) <- value.effectStack.getAllByFilter(::(value) <- value.traits & Effect.TRAIT.REVIVAL)); 
      when (which->size == 0) false;
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @count = 0;
      foreach(targets)::(k, target) {
        @:all = target.effectStack.getAllByFilter(::(value) <- value.traits & Effect.TRAIT.REVIVAL); 

        
        foreach(all) ::(k, v) {
          target.addEffect(
            from: user,
            id: 'base:aura',
            durationTurns: A_LOT
          );
        }
        count += 1;
      }
      if (count == 0) Arts.FAIL;
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Purgatory',
    id : 'base:b265',
    notifCommit : "$1 casts Purgatory!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ALL,
    keywords : ['base:revival-effect', 'base:shield-aura', 'base:banish'],
    description: "Each combatant gains a stack of the Shield Aura effect and 4 stacks of Banish for each of the Revival effects on them.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = allies->filter(::(value) <- value.effectStack.getAllByFilter(::(value) <- value.traits & Effect.TRAIT.REVIVAL)); 
      when (which->size == 0) false;
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @count = 0;
      foreach(targets)::(k, target) {
        @:all = target.effectStack.getAllByFilter(::(value) <- value.traits & Effect.TRAIT.REVIVAL); 

        
        foreach(all) ::(k, v) {
          target.addEffect(
            from: user,
            id: 'base:shield-aura',
            durationTurns: A_LOT
          );
          
          for(0, 4) ::(k, v) {
            target.addEffect(
              from: user,
              id: 'base:banish',
              durationTurns: A_LOT
            );          
          }
        }
        count += 1;
      }
      if (count == 0) Arts.FAIL;
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Deathly Gamble',
    id : 'base:b266',
    notifCommit : "$1 casts Deathly Gamble!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ALL,
    keywords : ['base:revival-effect'],
    description: "Randomly selects a combatant with no Revival effects. If the combatant is knocked out, they heal 50% of their HP. If the combatant is not knocked out, they receive damage equal to their remaining HP, knocking them out.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:pool = targets->filter(::(value) <- value.effectStack.getAllByFilter(::(value) <- (value.traits & Effect.TRAIT.REVIVAL) == 0));
      when(pool->size == 0) Arts.FAIL;

      @:victim = random.pickArrayItem(:pool);
      if (victim.hp == 0) ::<= {
        victim.heal(amount:(victim.stats.HP/2)->ceil);
      } else ::<= {
        victim.damage(attacker:user, damage:Damage.new(
          amount:(victim.hp/2)->ceil,
          damageType:Damage.TYPE.PHYS,
          damageClass:Damage.CLASS.HP
        ),dodgeable: false, exact: true);        
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Deathless Overflow',
    id : 'base:b267',
    notifCommit : "$1 casts Deathless Overflow!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:deathless-overflow', 'base:banish'],
    description: "Grants the Deathless Overflow effect.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:deathless-overflow', durationTurns:A_LOT);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Soul Buffer',
    id : 'base:b271',
    notifCommit : "$1 casts Soul Buffer!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:soul-buffer'],
    description: "Grants the Soul Buffer effect for one turn.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:soul-buffer', durationTurns:1);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Body Buffer',
    id : 'base:b272',
    notifCommit : "$1 casts Body Buffer!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:body-buffer'],
    description: "Grants the Body Buffer effect for one turn.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:body-buffer', durationTurns:1);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Perfect Barrier',
    id : 'base:b273',
    notifCommit : "$1 casts Perfect Barrier!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ALL,
    keywords : ['base:perfect-barrier'],
    description: "Grants the Perfect Barrier effect to a random combatant for 2 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      random.pickArrayItem(:targets).addEffect(from:user, id:'base:perfect-barrier', durationTurns:1);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Summon: Defensive Pylon',
    id : 'base:summon-defensive-pylon',
    notifCommit : '$1 summons a Defensive Pylon!',
    notifFail : '...but the summoning fizzled!',
    targetMode : TARGET_MODE.ONE,
    description: 'Summons a defensive pylon that casts Soul Guard upon creation on the target indefinitely.',
    keywords : ['base:soul-guard', 'base:paralyzed'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:world = import(module:'game_singleton.world.mt');
      @:Species = import(module:'game_database.species.mt');

      // limit 2 summons at a time.
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAIT.SUMMON) != 0)->size >= 2
      ) Arts.FAIL


      @:Entity = import(module:'game_class.entity.mt');
      @:sprite = Entity.new(
        island : world.island,
        speciesHint: 'base:defensive-pylon',
        professionHint: 'base:defensive-pylon',
        levelHint:4 + level
      );
      sprite.name = targets[0].name + '\'s Pylon';
            
      @:battle = user.battle;
      
      
      targets[0].addEffect(
        from: sprite,
        id: 'base:soul-guard',
        durationTurns: A_LOT
      );
      

      windowEvent.queueCustom(
        onEnter :: {

          battle.join(
            group: [sprite],
            sameGroupAs:targets[0]
          );
        }
      )
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Soul Split',
    id : 'base:b283',
    notifCommit : "$1 casts Soul Split!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:soul-split'],
    description: "Grants the Soul Split effect to a target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(allies->size == 1) false;
      return [random.pickArrayItem(:allies->filter(::(value) <- value != user))[0]];
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:soul-split', durationTurns:3);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Soul Projection',
    id : 'base:b284',
    notifCommit : "$1 casts Soul Projection!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:soul-projection', 'base:concentrating'],
    description: "Grants the Soul Projection effect to a target for 2 turns. Inflicts the Concentrating effect on the user for 1 turn.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      when(allies->size == 1) false;
      return [random.pickArrayItem(:allies->filter(::(value) <- value != user))[0]];
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:concentrating', durationTurns:1);
      targets[0].addEffect(from:user, id:'base:soul-projection', durationTurns:2);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Charm',
    id : 'base:b286',
    notifCommit : "$1 casts Charm!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:charmed'],
    description: "Inflicts the Charmed effect for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:charmed', durationTurns:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Static Shield',
    id : 'base:b277',
    notifCommit : "$1 casts Static Shield!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:static-shield'],
    description: "Grants the Static Shield effect to a target for 3 turns",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:static-shield', durationTurns:3);
    }
  }
)



Arts.newEntry(
  data: {
    name: 'Scorching Shield',
    id : 'base:b278',
    notifCommit : "$1 casts Scorching Shield!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:scorching-shield'],
    description: "Grants the Scorching Shield effect to a target for 3 turns",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:scorching-shield', durationTurns:3);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Freezing Shield',
    id : 'base:b279',
    notifCommit : "$1 casts Freezing Shield!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:freezing-shield'],
    description: "Grants the Freezing Shield effect to a target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:freezing-shield', durationTurns:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Acid Dust',
    id : 'base:b280',
    notifCommit : "$1 throws acidic dust on $2!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:acid-dust'],
    description: "Inflicts the Acid Dust effect on a target",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:acid-dust', durationTurns:A_LOT);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Conduction Dust',
    id : 'base:b281',
    notifCommit : "$1 throws conductive dust on $2!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:conduction-dust'],
    description: "Inflicts the Conduction Dust effect on a target",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:conduction-dust', durationTurns:A_LOT);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Crystalized Dust',
    id : 'base:b282',
    notifCommit : "$1 throws crystalized dust on $2!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:crystalized-dust'],
    description: "Inflicts the Crystalized Dust effect on a target.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:crystalized-dust', durationTurns:A_LOT);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Humiliate',
    id : 'base:b290',
    notifCommit : "$1 attempts to humiliate $2!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:embarrassed'],
    description: "Inflicts the Embarrassed effect on a target for 4 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:embarrassed', durationTurns:4);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Enraged',
    id : 'base:b291',
    notifCommit : "$1 attempts to enrage $2!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:enraged'],
    description: "Inflicts the Enraged effect on a target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:enraged', durationTurns:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Imposter',
    id : 'base:b292',
    notifCommit : "$1 casts Imposter on $2!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ONE,
    keywords : ['base:self-illusion'],
    description: "Inflicts the Self-Illusion effect on a target for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      targets[0].addEffect(from:user, id:'base:self-illusion', durationTurns:3);
    }
  }
)




Arts.newEntry(
  data: {
    name: 'Static Infusion',
    id : 'base:b294',
    notifCommit : "$1 casts Static Infusion!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:paralyzed', 'base:shock'],
    description: "Grants the Shock effect to the user for a long time, but also inflicts Paralyzed for 1 turn.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:paralyzed', durationTurns:1);
      user.addEffect(from:user, id:'base:shock', durationTurns:A_LOT);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Burning Infusion',
    id : 'base:b295',
    notifCommit : "$1 casts Burning Infusion!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:burned', 'base:burning'],
    description: "Grants the Burning effect to the user for a long time, but also inflicts Burned for 3 turn.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:burned', durationTurns:3);
      user.addEffect(from:user, id:'base:burning', durationTurns:A_LOT);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Icy Infusion',
    id : 'base:b296',
    notifCommit : "$1 casts Icy Infusion!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:frozen', 'base:icy'],
    description: "Grants the Icy effect to the user for a long time, but also inflicts Frozen for 1 turn.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:frozen', durationTurns:1);
      user.addEffect(from:user, id:'base:icy', durationTurns:A_LOT);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Elemental Contract',
    id : 'base:b296',
    notifCommit : "$1 casts Elemental Contract!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:attack-shifts'],
    description: "Grants an Attack Shift of the user's choice, but also inflicts a random negative effect for 3 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:world = import(module:'game_singleton.world.mt');


      @:which = [
        'base:burning',
        'base:icy',
        'base:shock',
        'base:shimmering',
        'base:dark',
        'base:toxic'
      ];

      @:done::(id) {
        user.addEffect(from:user, id:Effect.getRandomFiltered(::(value) <- 
          value.hasAnyTrait(:Effect.TRAIT.DEBUFF | Effect.TRAIT.AILMENT) &&
          value.hasNoTrait(:Effect.TRAIT.SPECIAL | Effect.TRAIT.INSTANTANEOUS)
        ), durationTurns:3);
        user.addEffect(from:user, id:which, durationTurns:A_LOT);
      }

      when(world.party.isMember(:user)) ::<= {
        windowEvent.queueMessage(
          text: 'An elemental imp was summoned!'
        );
        
        
        windowEvent.queueMessage(
          speaker: 'Elemental Imp',
          text: '"Okay, whaddya want. Make it quick."'
        );

        
        windowEvent.queueChoices(
          canCancel: false,
          keep: false,
          prompt: 'Grant which?',
          choices : which->map(::(value) <- Effect.find(:value).name),
          onChoice::(choice) {
            done(:which[choice-1]);
            windowEvent.queueMessage(
              speaker: 'Elemental Imp',
              text: '"Pleasure doin\' business with ya!"'
            );
          }
        );
      }
      
      
      done(:random.pickArrayItem(:which));
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Chaotic Elemental',
    id : 'base:b298',
    notifCommit : "$1 casts Chaotic Elemental!",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.ALL,
    keywords : ['base:attack-shifts'],
    description: "Manifests a chaotic entity that randomly grants two combatants with an Attack Shift, and 2 combatants with a negative effect for 5 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @:world = import(module:'game_singleton.world.mt');


      @:which = [
        'base:burning',
        'base:icy',
        'base:shock',
        'base:shimmering',
        'base:dark',
        'base:toxic'
      ];
      
      for(0, 2)::(i) {
        random.pickArrayItem(:targets).addEffect(from:user, id:random.pickArrayItem(:which), durationTurns:5)
      }

      for(0, 2)::(i) {
        random.pickArrayItem(:targets).addEffect(from:user, id:Effect.getRandomFiltered(::(value) <- 
          value.hasAnyTrait(:Effect.TRAIT.DEBUFF | Effect.TRAIT.AILMENT) &&
          value.hasNoTrait(:Effect.TRAIT.SPECIAL | Effect.TRAIT.INSTANTANEOUS)
        ), durationTurns:5);
      }
    }
  }
)



Arts.newEntry(
  data: {
    name: '@b305',
    id : 'base:b305',
    notifCommit : "",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:b305'],
    description: "Grants the b305 effect for 5 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:b305', durationTurns:5);
    }
  }
)

Arts.newEntry(
  data: {
    name: '@b307',
    id : 'base:b307',
    notifCommit : "",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:b307', 'base:empowered'],
    description: "Grants the b307 effect for 5 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:b307', durationTurns:5);
    }
  }
)



Arts.newEntry(
  data: {
    name: '@b308',
    id : 'base:b308',
    notifCommit : "",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:b308', 'base:stunned'],
    description: "Grants the b308 effect for 5 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:b308', durationTurns:5);
    }
  }
)


Arts.newEntry(
  data: {
    name: '@b309',
    id : 'base:b309',
    notifCommit : "",
    notifFail : "...But nothing happened!",
    targetMode : TARGET_MODE.NONE,
    keywords : ['base:b309', 'base:bleeding'],
    description: "Grants the b309 effect for 5 turns.",
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    kind : KIND.EFFECT,
    traits : 0,
    rarity : RARITY.RARE,
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      user.addEffect(from:user, id:'base:b308', durationTurns:5);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Sudden Provocation',
    id : 'base:b311',
    notifCommit : Arts.NO_NOTIF,
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: 'The incoming Art being reacted to is changed to the Attack Art targetting the user.',
    keywords: [],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : TRAIT.SUPPORT,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DONTUSE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return false;
    },
    baseDamage ::(level, user) {},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:BattleAction = import(:'game_struct.battleaction.mt');
      @:ArtsDeck = import(:'game_class.artsdeck.mt');
      
      return BattleAction.new(
        card : ArtsDeck.synthesizeHandCard(
          id: 'base:attack',
          level: 1,
          energy: ArtsDeck.ENERGY.A
        ),
        targets : [
          user
        ],
        targetParts : targetParts,
        turnIndex: 0,
        extraData : extraData
      )
    }
  }
)


         
Arts.newEntry(
  data: {
    name: 'Corrupted Punishment',
    id : 'base:corrupted-punishment',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Adds the effect Corrupted Punishment for 3 turns.",
    keywords : ['base:corrupted-punishment', 'base:banish'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:corrupted-punishment', durationTurns: 3);             
        }
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Corrupted Empowerment',
    id : 'base:corrupted-empowerment',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Adds the effect Corrupted Empowerment for 3 turns.",
    keywords : ['base:corrupted-empowerment', 'base:banish'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:banishCount = user.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size;
      when(banishCount > 0) true;
    },
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:corrupted-empowerment', durationTurns: 3);             
        }
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Corrupted Radioactivity',
    id : 'base:corrupted-radioactivity',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Adds the effect Corrupted Radioactivity for 3 turns.",
    keywords : ['base:corrupted-radioactivity', 'base:banish'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:banishCount = user.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size;
      when(banishCount > 0) true;
    },
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:corrupted-radioactivity', durationTurns: 3);             
        }
      );
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Corrupted Inspiration',
    id : 'base:corrupted-inspiration',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Adds the effect Corrupted Inspiration for 3 turns.",
    keywords : ['base:corrupted-inspiration', 'base:banish', 'base:minor-aura'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:banishCount = user.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size;
      when(banishCount > 0) true;
    },
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:corrupted-inspiration', durationTurns: 3);             
        }
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Corrupted Corruption',
    id : 'base:corrupted-corruption',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Adds the effect Corrupted Corruption for 3 turns.",
    keywords : ['base:corrupted-corruption', 'base:banish', 'base:minor-curse'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:banishCount = user.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size;
      when(banishCount > 0) true;
    },
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          targets[0].addEffect(from:user, id: 'base:corrupted-corruption', durationTurns: 3);             
        }
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Banishing Accumulation',
    id : 'base:banishing-accumulation',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Add one stack of Banish to target. For each copy of Banishing Accumulation in allies hands, add an additional Banish stack.",
    keywords : ['base:banish'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          @:allies = user.battle.getAllies(:user);
          @banishCount = 0;
          foreach(allies) ::(k, v) {
            foreach(v.artsDeck.hand) ::(k2, card) {
              if (card.id == 'base:banishing-accumulation')
                banishCount += 1;
            }
          }
          for(0, banishCount) ::(i) {
            targets[0].addEffect(from:user, id: 'base:banish', durationTurns: A_LOT);             
          }
        }
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Banishing Resonance',
    id : 'base:banishing-resonance',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Add one stack of Banish to each enemy if they already have a stack of Banish.",
    keywords : ['base:banish'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
    },
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueCustom(
        onEnter :: {
          foreach(
            user.battle.getEnemies(:user)->filter(
              ::(value) <- value.deck.hand->filter(
                ::(value) <- value.id == 'base:banish'
              )->size > 0
            )
          ) ::(k, v) {
            v.addEffect(from:user, id: 'base:banish', durationTurns: A_LOT);                       
          }
        }
      );
    }
  }
)



Arts.newEntry(
  data: {
    name: 'Corrupted Drain',
    id : 'base:corrupted-drain',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "For each stack of Banish on target, deal damage to target equal to 5% of the target's max HP. The user heals that much HP.",
    keywords : ['base:banish'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return ::? {
        foreach(random.scrambled(:enemies)) ::(k, v) {
          if (v.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size)
            send(:[v]);
        }
        return false;
      } 
         
    },
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:s = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size
      @:amount = s*targets[0].stats.HP*0.05;
      
      targets[0].damage(
        attacker: user,
        damage : Damage.new(
          amount,
          damageType: Damage.TYPE.NEUTRAL,
          damageClass : Damage.CLASS.HP
        ),
        exact: true,
        dodgeable: false
      );
      
      user.heal(:amount);
    }
  }
)

Arts.newEntry(
  data: {
    name: 'Phasing Banishment',
    id : 'base:phasing-banishment',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "The target is removed from battle for one turn. Each stack of Banish increases the duration by one turn. All stacks of Banish are removed.",
    keywords : ['base:banish'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return ::? {
        foreach(random.scrambled(:enemies)) ::(k, v) {
          if (v.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size)
            send(:[v]);
        }
        return false;
      } 
         
    },
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:s = targets[0].effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size
      user.battle.evict(:targets[0]);
      
      user.battle.queueTurnCallback(
        callback :: {
          user.battle.join(:targets[0])
        },
        nTurns: 1+s
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Banish Shield',
    id : 'base:banish-shield',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "Adds the effect Banish Shield to target for 4 turns.",
    keywords : ['base:banish', 'base:banish-shield'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      
    },
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      targets[0].addEffect(from:user, id: 'base:banish-shield', durationTurns: 4);
    }
  }
)


::<={
@:getStacks ::(ent) <-
  ent.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size

Arts.newEntry(
  data: {
    name: 'Corrupted Soulbind',
    id : 'base:corrupted-soulbind',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.ONE,
    description: "User and targets Banish stacks are compared. The one with the lower Banish stack count gains Banish stacks until equal to the other's count.",
    keywords : ['base:banish'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      return ::? {
        @:userStacks = getStacks(:user);
        
        foreach(random.scrambled(:enemies)) ::(k, v) {
          if (getStacks(:v) > userStacks)
            send(:[v]);
        }
        return false;
      }
    },
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:userStacks = getStacks(:user);
      @:othrStacks = getStacks(:targets[0]);

      if (userStacks < othrStacks) ::<= {
        for(userStacks, othrStacks) ::(i) {
          user.addEffect(from:user, id:'base:banis', durationTurns:A_LOT);
        }
      } else ::<= {
        for(othrStacks, userStacks) ::(i) {
          targets[0].addEffect(from:user, id:'base:banis', durationTurns:A_LOT);
        }      
      }
    }
  }
)
}


Arts.newEntry(
  data: {
    name: 'Scavenge the Exiled',
    id : 'base:scavenge-the-exiled',
    notifCommit : '$1 starts to glow!',
    notifFail : Arts.NO_NOTIF,
    targetMode : TARGET_MODE.NONE,
    description: "Steals one random equipment from a banished fighter. ",
    keywords : ['base:banish'],
    durationTurns: 0,
    kind : KIND.EFFECT,
    traits : TRAIT.MAGIC,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) <-
      if (user.battle.banished->size > 0) ::<= {
        foreach(user.battle.banished) ::(k, v) {
          if (v.getEquips()->size > 0) ::<= {
            send(:true);
          }
        }
      } else false
    ,
    baseDamage ::(level, user){},
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @whom;
      @item;
      @:world = import(module:'game_singleton.world.mt');
      
      ::? {
        foreach(random.scrambled(:user.battle.banished)) ::(k, v) {
          if (v.getEquips()->size > 0) ::<= {
            item = random.pickArrayItem(:v.getEquips());
            whom = v;
            send();
          }
        }
      }
      
      if (whom != empty && item != empty) ::<= {
        whom.unequipItem(item);
        if (world.party.isMember(:user)) ::<= {
          world.party.inventory.add(:item);
        }
      }


      user.addEffect(from:user, id: 'base:banish', durationTurns: A_LOT);
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
      TRAIT : {get::<- TRAIT},
      CANCEL_MULTITURN : {get::<- -1},
      A_LOT : {get ::<- A_LOT},
      generateKeywordDefinitionLines ::(art) {
        @:ArtsTerm = import(:'game_database.artsterm.mt');
        @:Effect = import(:'game_database.effect.mt');
        @:lines = [];
        foreach(art.keywords) ::(k, v)  {
          // first check if its an effect 
          @thing = Effect.findSoft(:v);
          
          when(thing) ::<= {
            lines->push(:'[Effect: ' + thing.name + ']: ' + thing.description + (if (thing.stackable == false) ' This is unstackable.' else ''));
          }

          thing = ArtsTerm.find(id:v);
          when(thing) ::<= {
            lines->push(:'[' + thing.name + ']: ' + thing.description);
          }
        }  
        return lines;    
      },
      
      traitToString::(trait) {
        return match(trait) {
          (1): 'Physical',
          (2): 'Magick',
          (4): 'Healing',
          (8): 'Fire',
          (16): 'Ice',
          (32): 'Thunder',
          (64): 'Support',
          (128): 'Light',
          (256): 'Dark',
          (512): 'Poison',
          (1024): 'Special',
          (2048): 'Costless',
          (4096): 'Multi-hit',
          (4096*2): 'Blockable',
          (4096*4): 'Once Per Battle',
          default: ''
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
    kind : Number,
    traits : Number,
    rarity : Number,
    baseDamage : Function,
    durationTurns : Number, // multiduration turns supercede the choice of action

    onAction : Function
  },
  reset
);



return Arts;
