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
  COSTLESS : 4096
}






@Arts;
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
      windowEvent.queueMessage(
        text: user.name + ' attacks ' + targets[0].name + '!'
      );
      
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            amount:Arts.find(:'base:attack').baseDamage(level, user),
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
      windowEvent.queueMessage(
        text: user.name + ' takes aim at ' + targets[0].name + '!'
      );
      
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            amount:Arts.find(:'base:precise-strike').baseDamage(level, user),
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
      windowEvent.queueMessage(
        text: user.name + ' attempts to tranquilize ' + targets[0].name + '!'
      );
      
      windowEvent.queueCustom(
        onEnter :: {
          if (user.attack(
            target:targets[0],
            amount:Arts.find(:'base:tranquilizer').baseDamage(level, user),
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
      windowEvent.queueMessage(
        text: user.name + ' attacks ' + targets[0].name + ' as a follow-up!'
      );

      windowEvent.queueCustom(
        onEnter :: {

          
          if (targets[0].flags.has(flag:StateFlags.HURT)) 
            user.attack(
              target:targets[0],
              amount:Arts.find(:'base:follow-up').baseDamage(level, user)*2,
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP,
              targetPart:targetParts[0],
              targetDefendPart:targetDefendParts[0]
            )
          else
            user.attack(
              target:targets[0],
              amount:Arts.find(:'base:follow-up').baseDamage(level, user),
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
    description: "Damages a target based on the user's ATK. Additional levels increase the damage per hit.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage::(level, user) <- user.stats.ATK * (0.4 + (level-1)*0.1),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' attacks twice!'
      );

      windowEvent.queueCustom(
        onEnter :: {
          @target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
          user.attack(
            target,
            amount: Arts.find(:'base:doublestrike').baseDamage(level, user),
            damageType : Damage.TYPE.PHYS,
            damageClass: Damage.CLASS.HP,
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
            amount:Arts.find(:'base:doublestrike').baseDamage(level, user),
            damageType : Damage.TYPE.PHYS,
            damageClass: Damage.CLASS.HP,
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
    description: "Damages three targets based on the user's ATK. Each level increases the amount of damage done.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage::(level, user) <- user.stats.ATK * (0.4 + (level-1)*0.07),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' attacks three times!'
      );
      
      
      windowEvent.queueCustom(
        onEnter :: {
          
          @target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
          user.attack(
            target,
            amount:Arts.find(:'base:triplestrike').baseDamage(level, user),
            damageType : Damage.TYPE.PHYS,
            damageClass: Damage.CLASS.HP,
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
            amount:Arts.find(:'base:triplestrike').baseDamage(level, user),
            damageType : Damage.TYPE.PHYS,
            damageClass: Damage.CLASS.HP,
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
            amount:Arts.find(:'base:triplestrike').baseDamage(level, user),
            damageType : Damage.TYPE.PHYS,
            damageClass: Damage.CLASS.HP,
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
      windowEvent.queueMessage(text:user.name + ' cheers for the party!');
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
            amount: Arts.find(:'base:moonbeam').baseDamage(user, level),
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
            amount:Arts.find(:'base:sunbeam').baseDamage(level, user),
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
      windowEvent.queueMessage(
        text: user.name + ' lets loose a burst of sunlight!'
      );    
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
              amount: Arts.find(:'base:sunburst').baseDamage(level, user),
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
    keywords : [],
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
    keywords : [],
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
    keywords : [],
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
      windowEvent.queueMessage(
        text: user.name + ' makes an eerie call!'
      );
      
      if (random.try(percentSuccess:50+(level-1)*10)) ::<= {
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
      windowEvent.queueMessage(
        text: user.name + ' tries to sweep everyone\'s legs!'
      );
      foreach((user.battle.getEnemies(:user)))::(i, enemy) {
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
      windowEvent.queueMessage(
        text: user.name + ' does a big swing!'
      );    
      foreach(targets)::(index, target) {
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target,
              amount:Arts.find(:'base:big-swing').baseDamage(level, user),
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
      windowEvent.queueMessage(
        text: user.name + ' bashes ' + targets[0].name + '!'
      );

      windowEvent.queueCustom(
        onEnter :: {

          user.attack(
            target:targets[0],
            amount:Arts.find(:'base:tackle').baseDamage(level, user),
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
            amount:Arts.find(:'base:throw-item').baseDamage(level, user) * (item.base.weight * 4),
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
      windowEvent.queueMessage(
        text: user.name + ' tries to stun ' + targets[0].name + '!'
      );

      windowEvent.queueCustom(
        onEnter :: {
          
          if (user.attack(
            target:targets[0],
            amount:Arts.find(:'base:stun').baseDamage(level, user),
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
    description: "Damages a target with an ice attack. 90% chance to Freeze. Additional levels increase its power.",
    keywords : ['base:frozen'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.ICE,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage ::(level, user) <- user.stats.ATK * (0.4) * (1 + (level-1)*0.07),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: 'A cold air emminates from ' + user.name + '!'
      );

      windowEvent.queueCustom(
        onEnter :: {

          if (user.attack(
            target:targets[0],
            amount:Arts.find(:'base:sheer-cold').baseDamage(level, user),
            damageType : Damage.TYPE.PHYS,
            damageClass: Damage.CLASS.HP,
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
      windowEvent.queueMessage(
        text: user.name + ' casts Flight on ' + targets[0].name + '!'
      );
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
      windowEvent.queueMessage(
        text: user.name + ' tries to grapple ' + targets[0].name + '!'
      );
      
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
    targetMode : TARGET_MODE.ONEPART,
    description: "Damages the same target twice at the same target and location. Additional levels increases the power.",
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : true,
    baseDamage ::(level, user) <- user.stats.ATK * (0.35) * (1 + (level-1)*0.05),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' does a combo strike on ' + targets[0].name + '!'
      );
      
      windowEvent.queueCustom(
        onEnter :: {
          
          user.attack(
            target: targets[0],
            amount: Arts.find(:'base:combo-strike').baseDamage(level, user),
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
            amount:Arts.find(:'base:combo-strike').baseDamage(level, user),
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
      windowEvent.queueMessage(
        text: user.name + ' casts Destruction Rune on ' + targets[0].name + '!'
      );
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
      windowEvent.queueMessage(
        text: user.name + ' casts Cure Rune on ' + targets[0].name + '!'
      );
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
      windowEvent.queueMessage(
        text: user.name + ' prepares a poison attack against ' + targets[0].name + '!'
      );
      windowEvent.queueCustom(
        onEnter :: {

          if (user.attack(
            target: targets[0],
            amount: Arts.find(:'base:poison-attack').baseDamage(level, user),
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
      windowEvent.queueMessage(
        text: user.name + ' prepares a petrifying attack against ' + targets[0].name + '!'
      );
      windowEvent.queueCustom(
        onEnter :: {

          if (user.attack(
            target: targets[0],
            amount: Arts.find(:'base:petrify').baseDamage(level, user),
            damageType : Damage.TYPE.PHYS,
            damageClass: Damage.CLASS.HP,
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
    targetMode : TARGET_MODE.ONE,
    description: "Activates a tripwire set up prior to battle, causing the target to be stunned for 3 turns. Only works once per battle.",
    keywords : ['base:stunned'],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.UNCOMMON,
    canBlock : false,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : true,
    baseDamage::(level, user){},
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
      windowEvent.queueMessage(
        text: user.name + ' activates the tripwire explosive right under ' + targets[0].name + '!'
      );
      when(random.try(percentSuccess:30)) ::<= {
        windowEvent.queueMessage(
          text: targets[0].name + ' avoided the trap!'
        );     
        return false;
             
      }
      windowEvent.queueCustom(
        onEnter :: {

          targets[0].damage(attacker:user, damage:Damage.new(
            amount:15,
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
    baseDamage::(level, user) <- 15,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' activates a floor trap, revealing a spike pit under the enemies!'
      );
      
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
      windowEvent.queueMessage(
        text: user.name + ' stabs ' + targets[0].name + '!'
      );

      windowEvent.queueCustom(
        onEnter :: {
          if (user.attack(
            target: targets[0],
            amount: Arts.find(:'base:stab').baseDamage(level, user),
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
      windowEvent.queueMessage(
        text: user.name + ' does first aid on ' + targets[0].name + '!'
      );
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
      windowEvent.queueMessage(
        text: user.name + ' mends ' + targets[0].name + '!'
      );
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
      windowEvent.queueMessage(
        text: user.name + ' gives a snack to ' + targets[0].name + '!'
      );
        
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

      windowEvent.queueMessage(
        text: user.name + ' summons a Fire Sprite!'
      );

      // limit 2 summons at a time.
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAITS.SUMMON) != 0)->size >= 2
      )
        windowEvent.queueMessage(
          text: '...but the summoning fizzled!'
        );


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
      windowEvent.queueMessage(
        text: user.name + ' summons an Ice Elemental!'
      );
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAITS.SUMMON) != 0)->size >= 2
      )
        windowEvent.queueMessage(
          text: '...but the summoning fizzled!'
        );


      
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
      windowEvent.queueMessage(
        text: user.name + ' summons a Thunder Spawn!'
      );
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAITS.SUMMON) != 0)->size >= 2
      )
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
      windowEvent.queueMessage(
        text: user.name + ' summons a Guiding Light!'
      );
      when ([...user.battle.getAllies(:user)]->filter(
        ::(value) <- (value.species.traits & Species.TRAITS.SUMMON) != 0)->size >= 2
      )
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
    targetMode : TARGET_MODE.ALLENEMY,
    description: 'Magick that removes a summoned entity.',
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
      windowEvent.queueMessage(
        text: user.name + ' casts Fire on ' + targets[0].name + '!'
      );
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            amount:Arts.find(:'base:fire').baseDamage(level, user),
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
      windowEvent.queueMessage(
        text: user.name + ' generates a great amount of heat!'
      );
      
      foreach(targets)::(i, target) {
        windowEvent.queueCustom(
          onEnter :: {
            if (user.attack(
              target:target,
              amount: Arts.find(:'base:backdraft').baseDamage(level, user),
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
      windowEvent.queueMessage(
        text: user.name + ' casts Flare on ' + targets[0].name + '!'
      );
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            amount: Arts.find(:'base:flare').baseDamage(level, user),
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
      windowEvent.queueMessage(
        text: user.name + ' casts Dematerialize on ' + targets[0].name + '!'
      );
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
    description: 'Magick that damages all enemies with ice based on INT.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.ICE,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- user.stats.INT * (0.6 + (0.2)*(level-1)),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' casts Ice!'
      );
      foreach((user.battle.getEnemies(:user)))::(index, enemy) {
        windowEvent.queueCustom(
          onEnter :: {

            user.attack(
              target:enemy,
              amount: Arts.find(:'base:ice').baseDamage(level, user),
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
    description: 'Magick that causes enemies to spontaneously combust in a cold, blue flame. Damage is based on INT with an additional chance to Freeze the hit targets. Additional levels increase damage.',
    keywords : ['base:frozen'],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.ICE,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- user.stats.INT * (0.75) * (1 + (level-1)* 0.15),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' casts Frozen Flame!'
      );
      foreach((user.battle.getEnemies(:user)))::(index, enemy) {
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target:enemy,
              amount: Arts.find(:'base:frozen-flame').baseDamage(level, user),
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
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.FIRE,
    rarity : RARITY.UNCOMMON,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- user.stats.INT * (0.85) * (1 + (level-1)*0.1),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' casts Explosion!'
      );
      foreach((user.battle.getEnemies(:user)))::(index, enemy) {
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target:enemy,
              amount:Arts.find(:'base:explosion').baseDamage(level, user),
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
    targetMode : TARGET_MODE.ALLENEMY,
    description: 'Magick that deals 4 random strikes based on INT. Each additional level deals an additional 2 strikes.',
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.MAGIC | TRAITS.THUNDER,
    rarity : RARITY.RARE,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage ::(level, user) <- user.stats.INT * (0.45),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' casts Thunder!'
      );
      for(0, 4 + (level-1)*2)::(index) {
        @:target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target,
              amount:Arts.find(:'base:thunder').baseDamage(level, user),
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
    keywords : [],
    durationTurns: 0,
    kind : KIND.ABILITY,
    traits : TRAITS.PHYSICAL,
    rarity : RARITY.EPIC,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {},
    oncePerBattle : false,
    canBlock : false,
    baseDamage::(level, user) <- user.stats.ATK * (0.9),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' wildly swings!'
      );
      for(0, 4 + (level-1)*2)::(index) {
        @:target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target,
              amount:Arts.find(:'base:wild-swing').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP,
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
      windowEvent.queueMessage(
        text: user.name + ' casts Cure on ' + targets[0].name + '!'
      );
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
    targetMode : TARGET_MODE.ONE,
    description: "Removes all status ailments and some negative effects. Additional levels have no benefit.",
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
      windowEvent.queueMessage(
        text: user.name + ' casts Cure All!'
      );

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
    description: 'Grants the Counter effect to the holder for 3 turns.',
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
        windowEvent.queueMessage(text:user.name + ' failed to disarm ' + targets[0].name + '!');
      
      }

    }
  }
) 


Arts.newEntry(
  data: {
    name: 'Sneak',
    id : 'base:sneak',
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
      windowEvent.queueCustom(
        onEnter :: {
          user.addEffect(from:user, id: 'base:cautious', durationTurns:10);
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
      windowEvent.queueMessage(text:'' + user.name + ' waits.');
      user.healAP(amount:3);
    }
  }
)


Arts.newEntry(
  data: {
    name: 'Plant Poisonroot',
    id : 'base:plant-poisonroot',
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
      windowEvent.queueMessage(text:targets[0].name + ' was covered in healroot seeds!');
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
      windowEvent.queueMessage(text:user.name + ' becomes shrouded in flame!');
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
      windowEvent.queueMessage(text:user.name + ' becomes shrouded in an icy wind!');
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
      windowEvent.queueMessage(text:user.name + ' becomes shrouded in electric arcs!');
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
      windowEvent.queueMessage(text:user.name + ' becomes shrouded in light');
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
      windowEvent.queueMessage(text:user.name + ' tries to convince ' + targets[0].name + ' to wait!');
      
      when(random.try(percentSuccess:50 - (level-1)*10))
        windowEvent.queueMessage(text: targets[0].name + ' ignored ' + user.name + '!');


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
    keywords: ['base:bribed'],
    durationTurns: 0,
    kind : KIND.EFFECT,
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
      windowEvent.queueMessage(
        text: user.name + ' sings a haunting, sweet song!'
      );
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

  Support arts

*/


Arts.newEntry(
  data: {
    name: 'Diversify',
    id : 'base:diversify',
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
    targetMode : TARGET_MODE.NONE,
    description: 'Discards entire hand, gain 2 HP.',
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
      when(random.flipCoin()) 
        windowEvent.queueMessage(
          text: '... but nothing happened!'
        );

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
    targetMode : TARGET_MODE.ONE,
    description: 'The user attacks as a reflex to an Art, damaging a target based on ATK. This damage is not blockable.',
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
    baseDamage ::(level, user) <- user.stats.ATK * (0.5),
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      windowEvent.queueMessage(
        text: user.name + ' reflexively attacks ' + targets[0].name + '!'
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
    name: 'Quick Shield',
    id : 'base:quick-shield',
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
      windowEvent.queueMessage(
        text: user.name + ' casts a shield spell in response!'
      );
      targets[0].heal(amount:2, isShield:true);           
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
    keywords: [],
    durationTurns: 0,
    kind : KIND.REACTION,
    traits : TRAITS.SUPPORT,
    rarity : RARITY.UNCOMMON,
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
    name: 'Shared Pain',
    id : 'base:shared-pain',
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
            amount:user.stats.HP - user.hp,
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
    name: 'Banishing Light',
    id : 'base:banishing-light',
    targetMode : TARGET_MODE.ONE,
    description: "The target receives the Banishing Light effect for the duration of the battle..",
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
            amount:user.stats.ATK * (0.3),
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
    name: 'Blood\'s Shield',
    id : 'base:bloods-shield',
    targetMode : TARGET_MODE.ONE,
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
    targetMode : TARGET_MODE.NONE,
    description: "Sacrifice 2 HP. Search user\'s discard pile for an Art. Add the Art to the user\'s hand.",
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
          
          windowEvent.queueMessage(
            text : 'Pick a card from ' + user.name + ' discard to add to your hand.'
          );  

          user.chooseDiscard(
            act: 'Add to hand.',
            onChoice::(id, backout) {
              backout();
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
      windowEvent.queueMessage(
        text: user.name + ' summons a Cursed Light!'
      );

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
      windowEvent.queueMessage(
        text: user.name + ' bodyslams ' + targets[0].name + '!'
      );
      
      windowEvent.queueCustom(
        onEnter :: {
          user.attack(
            target:targets[0],
            amount:Arts.find(:'base:bodyslam').baseDamage(level, user),
            damageType : Damage.TYPE.PHYS,
            damageClass: Damage.CLASS.HP,
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
    name: '@',
    id : 'base:b169',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all status ailments from the target.",
    keywords: ['base:ailments'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:allies)->filter(
        ::(value) <- value.effectStack.getAllByFilter(
          ::(value) <- (Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0
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
      windowEvent.queueMessage(
        text: targets[0].name + ' is covered in a soothing aura!'
      );

      @:filter = ::(value) <- (Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0

      @:hasAny = targets[0].effectStack.getAllByFilter(:filter)->size > 0;
      targets[0].effectStack.removeByFilter(:filter);
      if (hasAny == false)  
        windowEvent.queueMessage(
          text : '... but nothing happened!'
        )
    }
  }
)

Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b170',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all ailments and negative effects from the target. Only usable once per battle. Additional levels have no effect.",
    keywords: ['base:ailments'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:allies)->filter(
        ::(value) <- value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0) ||
                       ((Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF) != 0)
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

      windowEvent.queueMessage(
        text: targets[0].name + ' is covered in a soothing aura!'
      );
      @:filter = ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0) ||
                              ((Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF) != 0)

      @:hasAny = targets[0].effectStack.getAllByFilter(:filter)->size > 0;
      targets[0].effectStack.removeByFilter(:filter);
      if (hasAny == false)  
        windowEvent.queueMessage(
          text : '... but nothing happened!'
        )
    }
  }
)


Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b171',
    targetMode : TARGET_MODE.ALLALLY,
    description: "Removes all ailments and negative effects from allies and gives them all to the user.",
    keywords: ['base:ailments'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:allies)->filter(
        ::(value) <- value != user && value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0) ||
                       ((Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF) != 0)
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

      windowEvent.queueMessage(
        text: user.name + '\'s allies are covered in a mysterious light!'
      );


      @:condition = ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0) ||
                                 ((Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF) != 0)
      @toput = [];
      foreach(targets) ::(k, v) {
        when(v == user) empty;
        toput = [...toput, v.effectStack.getAllByFilter(:condition)];
        v.effectStack.removeByFilter(:condition);
      }
      
      when (toput->size == 0) 
        windowEvent.queueMessage(
          text: '...but the light fizzled and nothing happened!'
        );
      
      windowEvent.queueMessage(
        text: 'The light converges on ' + user.name + '!'
      );
      
      foreach(toput) ::(k, effectFull) {
        user.effectStack.add(
          id:effectFull.id,
          holder:user,
          duration: effectFull.duration,
          overrideTurnCount : effectFull.turnCount,
          from: effectFull.from,
          item: effectFull.item
        );
      }


    }
  }
)


Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b172',
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Randomly steals one positive effect from a random enemy and gives it to the user.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:enemies)->filter(
        ::(value) <- value != user && value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.BUFF) != 0)
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
      @:condition = ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.BUFF) != 0)

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
      victim.effectStack.removeByFilter(::(value) <- value == effectFull);
      

      
      user.effectStack.add(
        id:effectFull.id,
        holder:user,
        duration: effectFull.duration,
        overrideTurnCount : effectFull.turnCount,
        from: effectFull.from,
        item: effectFull.item
      );
    }
  }
)


Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b173',
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

      when(effects->size == 0)
        windowEvent.queueMessage(text:'...but nothing happened!');


      windowEvent.queueMessage(
        text: user.name + ' is covered in a mysterious light!'
      );

  
      if (effects->size > 2)
          effects->setSize(:2);
  
      user.effectStack.removeByFilter(::(value) {
        return {:::} {
          foreach(effects) ::(k, v) {
            if (v == value) send(:true);
          }
          return false;
        }
      });
                  

      foreach(effects) ::(k, v) {
        @:newEffect = Effect.getRandomFiltered(::(value) <- (value.flags & Effect.FLAGS.SPECIAL) == 0);
        user.effectStack.add(
          id:newEffect.id,
          holder:v.holder,
          duration: v.duration,
          overrideTurnCount : v.turnCount,
          from: v.from,
          item: v.item
        );        
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b174',
    targetMode : TARGET_MODE.ALL,
    description: "Removes all ailments and negative effects from all combatants, then discard a card and draw a card. Additional levels have no effect.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:allies)->filter(
        ::(value) <- value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0) ||
                       ((Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF) != 0)
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
      windowEvent.queueMessage(
        text: 'Everyone is covered in a soothing aura!'
      );
      
      @:filter = ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0) ||
                              ((Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF) != 0)
      
      foreach(targets) ::(k, target) {
        target.effectStack.removeByFilter(:filter);
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b175',
    targetMode : TARGET_MODE.ALL,
    description: "Removes all positive effects from all combatants.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:enemies)->filter(
        ::(value) <- value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.BUFF) != 0)
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
      windowEvent.queueMessage(
        text: 'Everyone is covered in an ominous aura!'
      );
      
      @:filter = ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.BUFF) != 0)      
      foreach(targets) ::(k, target) {
        target.effectStack.removeByFilter(:filter);
      }
    }
  }
)



Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b176',
    targetMode : TARGET_MODE.ONE,
    description: "Removes all effects from the user and randomly gives one of them to a target.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = user.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF) != 0) ||
                       ((Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0)
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
      @:filter = ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF) != 0) ||
                              ((Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0)
     
     
     
      @:v = user.effectStack.getAllByFilter(:filter)[0];
      when (v == empty)
        windowEvent.queueMessage(
          text: '... but nothing happened!'
        );
      
      windowEvent.queueMessage(
        text: user.name + ' and ' + targets[0].name + ' are covered in an ominous aura!'
      );
      
      user.effectStack.removeByFilter(filter);
      targets[0].effectStack.add(
        id:v.id,
        holder:v.holder,
        duration: v.duration,
        overrideTurnCount : v.turnCount,
        from: v.from,
        item: v.item
      );  
    }
  }
)

Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b177',
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
            ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.BUFF) != 0)
          )->size > 0
        )
        ||
        allies->filter(
          ::(value) <- value.effectStack.getAllByFilter(
            ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF) != 0) ||
                         ((Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0)
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
      windowEvent.queueMessage(
        text: 'Everyone is covered in a weird aura!'
      );
      
      @toput = [];
      foreach(targets) ::(k, v) {
        toput = [...toput, ...v.effectStack.getAll()];
        v.effectStack.removeByFilter(::(value) <- true);
      }
      
      foreach(random.scrambled(:toput)) ::(k, v) {
        @:target = random.pickArrayItem(:targets);
        
        target.effectStack.add(
          id:v.id,
          holder:v.holder,
          duration: v.duration,
          overrideTurnCount : v.turnCount,
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
      user.effectStack.removeByFilter(::(value) <- true);

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
    name: '@',
    id : 'base:b179',
    targetMode : TARGET_MODE.ONE,
    description: "Randomly steals up to two random effects from a target and gives it to the user.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:which = random.scrambled(:enemies)->filter(
        ::(value) <- value != user && value.effectStack.getAllByFilter(
          ::(value) <- ((Effect.find(:value.id).flags & Effect.FLAGS.BUFF) != 0)
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
      when(effectStackSize == 0)
        windowEvent.queueMessage(text:'...but nothing happened!');
                                 
      windowEvent.queueMessage(
        text: targets[0].name + ' is covered in a mysterious light!'
      );
      
      for(0, if (effectStackSize == 1) 1 else 2) ::(i) {
        @:effectFull = random.scrambled(:targets[0].effectStack.getAll())[0];
        targets[0].effectStack.removeByFilter(::(value) <- value == effectFull);
        
        user.effectStack.add(
          id:effectFull.id,
          holder:user,
          duration: effectFull.duration,
          overrideTurnCount : effectFull.turnCount,
          from: effectFull.from,
          item: effectFull.item
        );
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b180',
    targetMode : TARGET_MODE.ALLALLY,
    description: "Heals 1 HP for each effect that all the user\'s allies have.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.BUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      when(user.hp >= user.stats.HP) false;

      // if has any effects, is good to use
      return {:::} {
        foreach(allies) ::(k, v) {
          if (k.effectStack.getAll()->size > 0)
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
        tally += k.effectStack.getAll()->size;
      } 
      
      user.heal(amount:tally);
    }
  }
)

Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b181',
    targetMode : TARGET_MODE.ONE,
    description: "Replaces all negative effects on target with Banish stacks.",
    keywords: ['base:banish'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:able = enemies->filter(::(value) <- 
        value.effectStack.getAll()->filter(::(value) <- 
          (Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF)  != 0 ||
          (Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0
        )->size > 0);
          
      return [able]
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
        (Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF)  != 0 ||
        (Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0
      )]
      
      targets[0].removeEffects(:all);
      
      for(0, all->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:10000);              
      } 
    }
  }
)


Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b182',
    targetMode : TARGET_MODE.ONE,
    description: "Replaces all positive effects on target with Banish stacks.",
    keywords: ['base:banish'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:able = enemies->filter(::(value) <- 
        value.effectStack.getAll()->filter(::(value) <- 
          (Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF)  != 0 ||
          (Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0
        )->size > 0)
      when(able->size == 0) empty;
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
        (Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF)  != 0 ||
        (Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0
      )]
      
      targets[0].removeEffects(:all);
      
      for(0, all->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:10000);              
      } 
    }
  }
)

Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b183',
    targetMode : TARGET_MODE.ONE,
    description: "Replaces all positive effects on target with random ones. The durations of each effect are preserved.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.DEBUFF,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      @:able = enemies->filter(::(value) <- 
        value.effectStack.getAll()->filter(::(value) <- 
          (Effect.find(:value.id).flags & Effect.FLAGS.BUFF)  != 0
        )->size > 0)
      when(able->size == 0) empty;
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
        (Effect.find(:value.id).flags & Effect.FLAGS.BUFF)  != 0
      )]
      
      targets[0].removeEffects(:all);
      
      foreach(all) ::(k, v) {
        @:id = Effect.getRandomFiltered(::(value) <- (value.flags & Effect.FLAGS.SPECIAL) == 0);
        targets[0].addEffect(from:user, id, durationTurns:
          v.duration - v.turnCount
        );              
      } 
    }
  }
)


Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b184',
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
    name: '@',
    id : 'base:b185',
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
        v.effectStack.removeByFilter(::(value) <- true);
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
    name: '@',
    id : 'base:b186',
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
      when(oldBanish->size == 0) empty;  
      user.effectStack.removeByFilter(::(value) <- value.id == 'base:banish');
            
      for(0, oldBanish->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:banish', durationTurns:10000);              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b187',
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
      when(oldPoison->size == 0) empty;
      targets[0].effectStack.removeByFilter(::(value) <- value.id == 'base:poisoned');
            
      targets[0].heal(amount:oldPoison->size * 2);
            
      for(0, oldPoison->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:minor-dex-boost', durationTurns:2);              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b188',
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
      when(oldBurn->size == 0) empty;
      targets[0].effectStack.removeByFilter(::(value) <- value.id == 'base:burned');
            
      targets[0].heal(amount:oldBurn->size * 2);
            
      for(0, oldBurn->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:minor-defense-boost', durationTurns:2);              
      }
    }
  }
)

Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b189',
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
      when(oldParalyze->size == 0) empty;
      targets[0].effectStack.removeByFilter(::(value) <- value.id == 'base:paralyzed');
            
      targets[0].healAP(amount:oldParalyze->size * 2);
            
      for(0, oldParalyze->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:minor-mind-boost', durationTurns:2);              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b190',
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
      when(oldPetr->size == 0) empty;
      targets[0].effectStack.removeByFilter(::(value) <- value.id == 'base:petrified');
            
      targets[0].heal(amount:oldPetr->size * 2);
            
      for(0, oldPetr->size) ::(i) {
        targets[0].addEffect(from:user, id:'base:minor-strength-boost', durationTurns:3);              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b191',
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
            (Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0 ||
            (Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF)  != 0
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
        (Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0 ||
        (Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF)  != 0
      );
      when(oldBad->size == 0) empty;
      targets[0].effectStack.removeByFilter(::(value) <- 
        (Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0 ||
        (Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF)  != 0      
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
    name: '@',
    id : 'base:b192',
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
            (Effect.find(:value.id).flags & Effect.FLAGS.BUFF) != 0
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
      when(oldGood->size == 0) empty;
            
            
      foreach(oldGood) ::(k, v) {
        user.addEffect(
          from:targets[0], 
          id:v.id, 
          durationTurns: v.duration - v.turnCount,
          item: v.id
        );              
      }
    }
  }
)


Arts.newEntry(
  data: {
    name: '@',
    id : 'base:b193',
    targetMode : TARGET_MODE.ONE,
    description: "Grapples a target and binds their spirits together, transferring the user\'s effects to the target. The grapple lasts for 1 turn.",
    keywords: ['base:grappled', 'base:grappling'],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      // only use it offensively when you dont have buffs
      when (user.effectStack.getAllByFilter(::(value) <- 
        ((Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF) != 0) ||
        ((Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0)
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
            durationTurns: v.duration - v.turnCount,
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
    name: '@',
    id : 'base:b194',
    targetMode : TARGET_MODE.ONE,
    description: "Attacks an enemy. If the hit is successful, effects of the user and target are swapped.",
    keywords: [],
    durationTurns: 0,
    usageHintAI : USAGE_HINT.OFFENSIVE,
    shouldAIuse ::(user, reactTo, enemies, allies) {
      @:Effect = import(module:'game_database.effect.mt');
      // only use it offensively when you dont have buffs
      when (user.effectStack.getAllByFilter(::(value) <- 
        ((Effect.find(:value.id).flags & Effect.FLAGS.DEBUFF) != 0) ||
        ((Effect.find(:value.id).flags & Effect.FLAGS.AILMENT) != 0)
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
            amount:Arts.find(:'base:b194').baseDamage(level, user),
            damageType : Damage.TYPE.PHYS,
            damageClass: Damage.CLASS.HP,
            targetPart:Entity.DAMAGE_TARGET.BODY,
            targetDefendPart:targetDefendParts[0]
          )) ::<= {
            @effUser   = [...user.effectStack.getAll()]
            @effTarget = [...targets[0].effectStack.getAll()]

            targets[0].effectStack.removeByFilter(::(value) <- true);
            user.effectStack.removeByFilter(::(value) <- true);


            foreach(effUser) ::(k, v) {
              targets[0].addEffect(
                from:user, 
                id:v.id, 
                durationTurns: v.duration - v.turnCount,
                item: v.id
              );              
            }
            foreach(effTarget) ::(k, v) {
              user.addEffect(
                from:targets[0], 
                id:v.id, 
                durationTurns: v.duration - v.turnCount,
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
    name: '@',
    id : 'base:b195',
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
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user) <- user.stats.ATK * (0.35) * level,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @oldPois = user.effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:poisoned'
      );
      
      when(oldPois->size == 0) empty;
      
      user.effectStack.removeByFilter(::(value) <-
        value.id == 'base:poisoned'
      );
      
      foreach(oldPois->size) ::(k, v) {
        windowEvent.queueCustom(
          onEnter :: {
            @target = random.pickArrayItem(list:(user.battle.getEnemies(:user)));
            user.attack(
              target,
              amount: Arts.find(:'base:b195').baseDamage(level, user),
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP,
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
    name: '@',
    id : 'base:b196',
    targetMode : TARGET_MODE.ALLENEMY,
    description: "Removes all of the user\'s stacks of the Burned effect. This causes an explosion that burns all enemies, dealing more damage per stack of burn removed. If the user does not have the Burned status, nothing happens.",
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
    traits : TRAITS.SUPPORT | TRAITS.MAGIC,
    rarity : RARITY.RARE,
    baseDamage::(level, user) <- 4 * user.effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:burned'
      )->size * level,
    onAction: ::(level, user, targets, turnIndex, targetDefendParts, targetParts, extraData) {      
      @oldPois = user.effectStack.getAllByFilter(::(value) <- 
        value.id == 'base:burned'
      );
      
      when(oldPois->size == 0) empty;
      
      user.effectStack.removeByFilter(::(value) <-
        value.id == 'base:burned'
      );


      
      foreach(targets) ::(k, target) {
        windowEvent.queueCustom(
          onEnter :: {
            user.attack(
              target,
              amount: Arts.find(:'base:b196').baseDamage(level, user),
              damageType : Damage.TYPE.FIRE,
              damageClass: Damage.CLASS.HP,
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
    name: '@',
    id : 'base:b197',
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
      user.effectStack.removeByFilter(::(value) <-
        value.id == 'base:blind'
      );
      user.addEffect(from:user, id:'base:agile',durationTurns:2);
      user.addEffect(from:user, id:'base:agile',durationTurns:2);
    }
  }
)


};

Arts = class(
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
