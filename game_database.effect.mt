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


@:TRAIT = {
  AILMENT : 1,
  BUFF : 2,
  DEBUFF : 4,
  SPECIAL : 8,
  
  // Means the holder will always go first. Ties are randomly decided
  ALWAYS_FIRST : 16,
  REVIVAL : 32,
  
  // Overrides duration to always be 0. effect stack will not report these if alone 
  // in a change.
  INSTANTANEOUS : 64,
  
  CANT_USE_ABILITIES : 128,
  CANT_USE_EFFECTS   : 256,
  CANT_USE_REACTIONS : 512,
};


  ////////////////////// SPECIAL EFFECTS
@:reset :: {

@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Scene = import(module:'game_database.scene.mt');
@:random = import(module:'game_singleton.random.mt');
@:g = import(module:'game_function.g.mt');
@:EffectStack = import(:'game_class.effectstack.mt');
@:canvas = import(module:'game_singleton.canvas.mt');


  
  
  
  //////////////////////


Effect.newEntry(
  data : {
    name : 'Reading',
    id : 'base:read',
    description: 'The user is in the middle of reading a book.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.INSTANTANEOUS | TRAIT.SPECIAL,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        when(item == empty || from.battle != empty)
          windowEvent.queueMessage(speaker: holder.name, text: "\"Why am I reading right now??\"");


        windowEvent.queueMessage(
          text: item.data.book.name + ', by ' + item.data.book.author
        );

        if (item.data.book) ::<= {
          @:w = item.data.book.onGetContents();
          if (w->type == String)
            windowEvent.queueReader(lines:w->split(token: '\n'))
          else 
            windowEvent.queueReader(lines:canvas.refitLines(input:w));
        }

      }
    }
  }
)    



Effect.newEntry(
  data : {
    name : 'Dying',
    id: 'base:dying',
    description: 'The holder is dying. When this effect\'s duration is reached and HP of the holder is 0, the combatant will die.',
    stackable: false,
    blockPoints : 1,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onDurationEnd::(from, item, holder) {
        when(holder.hp != 0) empty;
        holder.killFinalize(from);
      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'Defend',
    id: 'base:defend',
    description: 'Adds an additional block point. Reduces damage by 40%. When first getting this effect and HP is below 50%, gain 10% HP back.',
    stackable: false,
    blockPoints : 1,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
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

      onPreDamage ::(from, item, holder, attacker, damage) {
        windowEvent.queueMessage(text:holder.name + "'s defending stance reduces damage!");
        damage.amount *= 0.6;
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Brace',
    id: 'base:brace',
    description: '+3 base DEF and grants an additional block point.',
    stackable: false,
    blockPoints : 1,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF: 3
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' braces for damage!'
        );
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'x2 Damage',
    id : 'base:next-attack-x2',
    description: 'Next attack\'s damage will be 2 times as strong.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' is primed for more damage!'
        );
      },

      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        windowEvent.queueMessage(
          text: holder.name + '\'s attack was boosted x2!'
        );

        damage.amount *= 2;
        holder.removeEffectInstance(:
          holder.effectStack.getAll()->filter(::(value) <- value.id == 'base:next-attack-x2')[0]
        )
      }
    }
  }
);

Effect.newEntry(
  data : {
    name : 'Take Aim',
    id : 'base:take-aim',
    description: 'Next holder\'s attack bypasses target\'s DEF. After the next attack, this effect is removed.',
    stackable : false,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        windowEvent.queueMessage(
          text: holder.name + '\'s attack bypassed ' + to.name +'\'s DEF!'
        );

        damage.traits |= Damage.TRAIT.FORCE_DEF_BYPASS;
        
        holder.removeEffectInstance(:
          holder.effectStack.getAll()->filter(::(value) <- value.id == 'base:take-aim')[0]
        )
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Splinter',
    id : 'base:splinter',
    description: 'Attacks by the holder now damage all other enemies for 20% of the original attack\'s damage.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        when(holder.battle == empty) empty;
        
        @:targets = holder.battle.getEnemies(:holder)->filter(::(value) <- value != to);
        when (targets->size == 0) empty;

        windowEvent.queueMessage(
          text: holder.name + '\'s Splinter caused splash damage!'
        );

        foreach(targets) ::(k, v) {
          v.damage(attacker:holder, damage:Damage.new(
            amount : damage.amount * 0.2,
            damageType:damage.damageType,
            damageClass:damage.damageClass
          ),dodgeable: true);          
        }
      }
    }
  }
);

Effect.newEntry(
  data : {
    name : 'Confused',
    id : 'base:confused',
    description: '20% chance that attacks to others target their self or their allies.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        when(holder.battle == empty) empty;

        when(random.try(percentSuccess:80)) empty;

        
        @:target = random.pickArrayItem(:holder.battle.getAllies(:holder));
        windowEvent.queueMessage(
          text: holder.name + '\'s confusion caused them to attack ' + target.name + ' instead!'
        );
        
        overrideTarget->push(:target);
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Taunted',
    id : 'base:taunted',
    description: 'All of the holder\'s attacks can only target the person who inflicted this effect.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        when(from == empty) empty;
        windowEvent.queueMessage(
          text: holder.name + ' fell for ' + from.name + '\'s taunt!'
        );
        
        overrideTarget->push(:from);
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Terrified',
    id : 'base:terrified',
    description: 'The holder\'s attacks that target the person who inflicted this effect cause 0 damage.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        when(from == empty) empty;
        
        windowEvent.queueMessage(
          text: holder.name + ' is terrified of ' + from.name + '!'
        );

        damage.amount = 0;
      }
    }
  }
);

Effect.newEntry(
  data : {
    name : 'Field Barrier',
    id : 'base:field-barrier',
    description: 'Reduces incoming multi-hit damage by 80%.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        when((damage.traits & Damage.TRAIT.MULTIHIT) == 0) empty;
        windowEvent.queueMessage(text:holder.name + "'s Field Barrier reduces multi-hit damage!");
        damage.amount *= 0.2;
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Suppressor',
    id : 'base:suppressor',
    description: 'Reduces incoming attack damage by 50%.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        windowEvent.queueMessage(text:holder.name + "'s Suppressor reduces multi-hit damage!");
        damage.amount *= 0.5;
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Potentiality Shard',
    id : 'base:potentiality-shard',
    description: 'Next played Art has a 25% chance of activating twice. This effect gets removed afterward.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAction ::(from, holder, action) {
        holder.removeEffectsByFilter(::(value) <- value.id == 'base:potentiality-shard');

        when(random.try(percentSuccess:25)) ::<= {
          windowEvent.queueMessage(text:holder.name + "'s Potentiality Shard activates!");
          holder.battle.commitFreeAction(
            action,
            from:holder,
            onDone::{}
          )
        }
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Copy Shard',
    id : 'base:copy-shard',
    description: 'Next played Art is duplicated and added to hand. This effect gets removed afterward.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAction ::(from, holder, action) {
        holder.removeEffectsByFilter(::(value) <- value.id == 'base:copy-shard');

        when(random.try(percentSuccess:50)) ::<= {
          windowEvent.queueMessage(text:holder.name + "'s Copy Shard activates!");
          holder.deck.addHandCard(id:action.id);
        }
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Conductive Block',
    id : 'base:conductive-block',
    description: 'Next incoming attack\'s damage is negated and gives the holder the effect 2x Damage. This counts as blocking. This effect is removed afterward.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttacked ::(from, item, holder, attacker, damage) {
        @:Entity = import(module:'game_class.entity.mt');
        holder.removeFirstEffectByFilter(::(value) <- value.id == 'base:block');

        windowEvent.queueMessage(text:holder.name + " is blocking!");
        damage.amount = 0;
        
        holder.effectStack.emitEvent(
          name : 'onSuccessfulBlock',
          attacker,
          // synthetic but eh
          blockData : {
            targetDefendPart : Entity.DAMAGE_TARGET.BODY,
            targetPart : Entity.DAMAGE_TARGET.BODY
          }
        );

        attacker.effectStack.emitEvent(
          name : 'onGotBlocked',
          from: holder
        );
        
        @:Arts = import(:'game_database.arts.mt');
        holder.addEffect(from:holder, id: 'base:next-attack-x2', durationTurns: Arts.A_LOT);

      }
    }
  }
);

Effect.newEntry(
  data : {
    name : 'Block',
    id : 'base:block',
    description: 'Next incoming attack\'s damage is negated. This counts as blocking. This effect is removed afterward.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttacked ::(from, item, holder, attacker, damage) {
        holder.removeFirstEffectByFilter(::(value) <- value.id == 'base:block');
        @:Entity = import(module:'game_class.entity.mt');

        windowEvent.queueMessage(text:holder.name + " is blocking!");
        damage.amount = 0;
        
        holder.effectStack.emitEvent(
          name : 'onSuccessfulBlock',
          attacker,
          // synthetic but eh
          blockData : {
            targetDefendPart : Entity.DAMAGE_TARGET.BODY,
            targetPart : Entity.DAMAGE_TARGET.BODY
          }
        );

        attacker.effectStack.emitEvent(
          name : 'onGotBlocked',
          from: holder
        );

      }
    }
  }
);

Effect.newEntry(
  data : {
    name : 'Slingshot Block',
    id : 'base:slingshot-block',
    description: 'Next incoming attack\'s damage is reduced to 2 damage. The original damage is redirected to a target of the holder\'s choice. This counts as blocking. This effect is removed afterward.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttacked ::(from, item, holder, attacker, damage) {
        holder.removeFirstEffectByFilter(::(value) <- value.id == 'base:slingshot-block');

        windowEvent.queueMessage(text:holder.name + " is blocking!");
        @:copy = Damage.new();
        copy.load(:damage.save());
        damage.amount = 2;
        @:Entity = import(module:'game_class.entity.mt');
        
        holder.effectStack.emitEvent(
          name : 'onSuccessfulBlock',
          attacker,
          // synthetic but eh
          blockData : {
            targetDefendPart : Entity.DAMAGE_TARGET.BODY,
            targetPart : Entity.DAMAGE_TARGET.BODY
          }
        );

        attacker.effectStack.emitEvent(
          name : 'onGotBlocked',
          from: holder
        );

        windowEvent.queueNestedResolve(
          onEnter :: {
            holder.pickTarget(
              onPick ::(target) {
                attacker.damage(
                  attacker: holder,
                  damage: copy,
                  dodgeable: true,
                  exact: true
                );
              },
              canCancel: false,
              showHitChance : false
            )
          }
        );
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Ricochet Block',
    id : 'base:ricochet-block',
    description: 'Next incoming attack\'s is redirected to a random target. This counts as blocking. This effect is removed afterward.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttacked ::(from, item, holder, attacker, damage) {
        holder.removeFirstEffectByFilter(::(value) <- value.id == 'base:ricochet-block');
        @:Entity = import(module:'game_class.entity.mt');

        windowEvent.queueMessage(text:holder.name + " is blocking!");
        @:copy = Damage.new();
        copy.load(:damage.save());
        damage.amount = 0;
        
        holder.effectStack.emitEvent(
          name : 'onSuccessfulBlock',
          attacker,
          // synthetic but eh
          blockData : {
            targetDefendPart : Entity.DAMAGE_TARGET.BODY,
            targetPart : Entity.DAMAGE_TARGET.BODY
          }
        );

        attacker.effectStack.emitEvent(
          name : 'onGotBlocked',
          from: holder
        );

        @target = random.pickArrayItem(:[...holder.battle.getAllies(:holder)->filter(::(value) <- value != holder), ...holder.battle.getEnemies()]);

        target.damage(
          attacker: holder,
          damage: copy,
          dodgeable: true,
          exact: true
        );
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Reflective Block',
    id : 'base:reflective-block',
    description: 'Next incoming attack\'s is redirected to the origin attacker. This counts as blocking. This effect is removed afterward.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttacked ::(from, item, holder, attacker, damage) {
        holder.removeFirstEffectByFilter(::(value) <- value.id == 'base:reflective-block');
        @:Entity = import(module:'game_class.entity.mt');

        windowEvent.queueMessage(text:holder.name + " is blocking!");
        @:copy = Damage.new();
        copy.load(:damage.save());
        damage.amount = 0;
        
        holder.effectStack.emitEvent(
          name : 'onSuccessfulBlock',
          attacker,
          // synthetic but eh
          blockData : {
            targetDefendPart : Entity.DAMAGE_TARGET.BODY,
            targetPart : Entity.DAMAGE_TARGET.BODY
          }
        );

        attacker.effectStack.emitEvent(
          name : 'onGotBlocked',
          from: holder
        );


        attacker.damage(
          attacker: holder,
          damage: copy,
          dodgeable: true,
          exact: true
        );
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Mirrored',
    id : 'base:mirrored',
    description: 'Attacks by the holder now damage a random enemy for the same damage amount.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to, damage) {
        when(holder.battle == empty) empty;
        
        @:target = random.pickArrayItem(:holder.battle.getEnemies(:holder));

        windowEvent.queueMessage(
          text: holder.name + '\'s Mirrored caused an additional attack!'
        );

        target.damage(attacker:holder, damage:Damage.new(
          amount : damage.amount,
          damageType:damage.damageType,
          damageClass:damage.damageClass
        ),dodgeable: true);          
      }
    }
  }
);



Effect.newEntry(
  data : {
    name : 'Banishing Light',
    id : 'base:banishing-light',
    description: 'Next attack received is translated instead to 4 Banish stacks. When an attack is translated in this way, the holder loses a stack of Banishing Light.',
    stackable : true,
    blockPoints: 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' is inflicted with Banishing Light!'
        );
      },

      onPreAttacked ::(from, item, holder, attacker, damage) {
        windowEvent.queueMessage(
          text: holder.name + '\'s Banishing Light translated the damage into Banishing!'
        );

        for(0, 4) ::(i) {
          holder.addEffect(from, id:'base:banish', durationTurns:10000);      
        }
        damage.amount = 0;
        holder.removeEffectInstance(:
          (holder.effectStack.getAll()->filter(::(value) <- value.id == 'base:banishing-light'))[0]
        )
        
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Agile',
    id: 'base:agile',
    description: '+2 base DEX. The holder may now dodge attacks. If the holder has more DEX than the attacker, the chance of dodging increases if the holder\'s DEX is greater than the attacker\'s.',
    stackable: true,
    blockPoints : 1,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEX: 2
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' is now able to dodge attacks!'
        );
      },

      onPreAttacked ::(from, item, holder, attacker, damage) {
        @:StateFlags = import(module:'game_class.stateflags.mt');
        @whiff = false;
        @:hitrate::(this, attacker) {
          //if (dexPenalty != empty)
          //  attacker *= dexPenalty;
            
          when (attacker <= 1) 0.45;
          @:diff = attacker/this; 
          when(diff > 1) 0.85; 
          return 0.45 + (0.85 - 0.45) * ((1-diff)**0.9);
        }
        if (random.number() > hitrate(
          this:   holder.stats.DEX,
          attacker: attacker.stats.DEX
        ))
          whiff = true;
        
        
        when(whiff) ::<= {
          windowEvent.queueMessage(text:random.pickArrayItem(list:[
            holder.name + ' lithely dodges ' + attacker.name + '\'s attack!',         
            holder.name + ' narrowly dodges ' + attacker.name + '\'s attack!',         
            holder.name + ' dances around ' + attacker.name + '\'s attack!',         
            attacker.name + '\'s attack completely misses ' + holder.name + '!'
          ]));
          holder.flags.add(flag:StateFlags.DODGED_ATTACK);
          damage.amount = 0;
          
          return EffectStack.CANCEL_PROPOGATION;
        }    
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Guard',
    id : 'base:guard',
    description: 'Reduces incoming damage from attacks by 90%.',
    stackable: false,
    blockPoints : 1,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' takes a guarding stance!'
        );
      
      },
      onPreDamage ::(from, item, holder, attacker, damage) {
        windowEvent.queueMessage(text:holder.name + "'s defending stance reduces damage significantly!");
        damage.amount *= 0.1;
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Apparition',
    id : 'base:apparition',
    description: 'Ghostly apparition makes it particularly hard to hit.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onPreAttacked ::(from, item, holder, attacker, damage) {
        if (!holder.isIncapacitated() && random.try(percentSuccess:40)) ::<= {
          windowEvent.queueMessage(text:holder.name + "'s ghostly body bends around the attack!");
          damage.amount = 0;
        }    
        return EffectStack.CANCEL_PROPOGATION;
      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'The Beast',
    id : 'base:the-beast',
    description: 'The ferocity of this creature makes it particularly hard to hit.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onPreAttacked ::(from, item, holder, attacker, damage) {
        when (!holder.isIncapacitated() && random.try(percentSuccess:35)) ::<= {
          windowEvent.queueMessage(text:holder.name + " ferociously repels the attack!");
          damage.amount = 0;
          return EffectStack.CANCEL_PROPOGATION;
        }
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Wyvern\'s Aura',
    id : 'base:the-wyvern',
    description: 'The swiftness and power of the wyvern makes it particularly hard to hit.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onPreAttacked ::(from, item, holder, attacker, damage) {
        when (!holder.isIncapacitated() && random.try(percentSuccess:15)) ::<= {
          windowEvent.queueMessage(text:random.pickArrayItem(list:[
            'You will have to try harder than that, Chosen!',
            'Come at me; do not hold back, Chosen!',
            'You disrespect me with such a weak attack, Chosen!',
            'Nice try, but it is not enough!'
          ]));
          windowEvent.queueMessage(text:holder.name + ' deflected the attack!');
          damage.amount = 0;
          return EffectStack.CANCEL_PROPOGATION;
        }
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Seasoned Adventurer',
    id : 'base:seasoned-adventurer',
    description: 'Is considerably harder to hit, as they are an experienced fighter.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onPreAttacked ::(from, item, holder, attacker, damage) {
        when (!holder.isIncapacitated() && random.try(percentSuccess:60)) ::<= {
          windowEvent.queueMessage(text:
            random.pickArrayItem(list: [
              holder.name + " predicts and avoids the attack!",
              holder.name + " easily avoids the attack!",
              holder.name + " seems to have no trouble avoiding the attack!",
            ])
          );
          damage.amount = 0;
          return EffectStack.CANCEL_PROPOGATION;
        }
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Defensive Stance',
    id : 'base:defensive-stance',
    description: 'ATK base -5, DEF base +10, gains an additional block point.',
    stackable: false,
    blockPoints : 1,
    traits : 0,
    stats: StatSet.new(ATK:-5, DEF:10),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' changes their stance to be defensive!'
        );
      }
    }
  }
)    


Effect.newEntry(
  data : {
    name : 'Offsensive Stance',
    id : 'base:offensive-stance',
    description: 'DEF base -5, ATK base +10',
    stackable: false,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(DEF:-5, ATK:10),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' changes their stance to be offensive!'
        );
      }
    }
  }
) 



Effect.newEntry(
  data : {
    name : 'Light Stance',
    id : 'base:light-stance',    
    description: 'ATK base -5; SPD, DEX base +5',
    stackable: false,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(ATK:-5, SPD:5, DEX:5),
    events : { 
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' changes their stance to be light on their feet!'
        );
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Heavy Stance',
    id : 'base:heavy-stance',
    description: 'SPD base -5, DEF base +10, additional block point.',
    stackable: false,
    blockPoints : 1,
    traits : 0,
    stats: StatSet.new(SPD:-5, DEF:10),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' changes their stance to be heavy and sturdy!'
        );
      }
    }
  }
)     


Effect.newEntry(
  data : {
    name : 'Meditative Stance',
    id : 'base:meditative-stance',
    description: 'ATK base -5, INT base +10',
    stackable: false,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(ATK:-5, INT:10),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' changes their stance for mental focus!'
        );
      }
    }
  }
)     


Effect.newEntry(
  data : {
    name : 'Striking Stance',
    id : 'base:striking-stance',
    description: 'Base stats: SPD -2, DEF -2, ATK +10, DEX + 5',
    stackable: false,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(SPD:-2, DEF:-2, ATK:10, DEX:5),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' changes their stance for maximum attack!'
        );
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Reflective Stance',
    id : 'base:reflective-stance',
    description: 'For incoming physical attacks, negate the damage and send half of the would-be damage back to the attacker.',
    stackable: false,
    stats: StatSet.new(),
    blockPoints : 0,
    traits : 0,
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' changes their stance to reflect attacks!'
        );
      },

      onPreDamage ::(from, item, holder, attacker, damage) {
        when (holder == attacker) empty;
        when (damage.damageType != Damage.TYPE.PHYS) empty;
        
        // handles the DBZ-style case pretty well!
        @:amount = (damage.amount / 2)->floor;

        when(amount <= 0) empty;
        windowEvent.queueMessage(
          text: holder.name + ' retaliates!'
        );


        attacker.damage(attacker:holder, damage:Damage.new(
          amount,
          damageType:Damage.TYPE.PHYS,
          damageClass:Damage.CLASS.HP
        ),dodgeable: true);
      }
    }
  }
)         

Effect.newEntry(
  data : {
    name : 'Counter',
    id : 'base:counter',
    description: 'Negates incoming attacks and redirects a portion of the would-be damage back at the attacker. Unable to use Ability or Reaction Arts.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.CANT_USE_ABILITIES | TRAIT.CANT_USE_REACTIONS,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
      },

      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' is prepared for an attack!'
        );
      },
      onPreDamage ::(from, item, holder, attacker, damage) {
        @dmg = damage.amount * 0.75;
        when (dmg < 1) empty;
        damage.amount = 0;
        windowEvent.queueMessage(
          text: holder.name + ' counters!'
        );


        holder.attack(
          target:attacker,
          damage: Damage.new(
            amount: dmg,
            damageType : Damage.TYPE.PHYS,
            damageClass: Damage.CLASS.HP
          )
        );        
        return EffectStack.CANCEL_PROPOGATION;  
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Evasive Stance',
    id : 'base:evasive-stance',
    description: '%50 chance damage nullify when from others. -1 AP for each successful dodge. If the user has no AP, this effect is ignored.',
    stackable: false,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' changes their stance to evade attacks!'
        );
      },

      onPreDamage ::(from, item, holder, attacker, damage) {
        when (holder == attacker) empty;
        when (holder.ap == 0) empty;
        when(random.number() > .5) empty;

        holder.ap -= 1;
        windowEvent.queueMessage(
          text: holder.name + ' evades at the cost of 1 AP!'
        );

        damage.amount = 0;
        return EffectStack.CANCEL_PROPOGATION;  

      }
    }
  }
)         

Effect.newEntry(
  data : {
    name : 'Sneaked',
    id : 'base:sneaked',
    description: 'Guarantees next damage from the one inflicting is 3 times more damage.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:from.name + " snuck behind " + holder.name + '!');
      
      },
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (attacker == from) ::<= {
          windowEvent.queueMessage(text:from.name + "'s sneaking takes " + holder.name + ' by surprise!');
          damage.amount *= 3;
        }
        
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Mind Focused',
    id : 'base:mind-focused',
    description: 'INT base +5',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      INT: 5
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' focuses their mind');
      },

      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s focus returns to normal.');
      }
    }
  }
)    


Effect.newEntry(
  data : {
    name : 'Protect',
    id : 'base:protect',
    description: 'DEF base +10',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF: 10
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' is covered in a shell of light!');
      },

      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s shell of light fades away.');
      }    
    }     
  }
)  

Effect.newEntry(
  data : {
    name : 'Shield',
    id : 'base:shield',
    description: 'DEF base +2, 30% chance to block',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF: 2
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:'A shield of light appears before ' + holder.name + '!');
      },

      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s shield of light fades away.');
      },        
      onPreAttacked ::(from, item, holder, attacker, damage) {
        when (random.number() < 0.3) ::<= {
          windowEvent.queueMessage(text:holder.name + '\'s shield of light blocks the attack!');
          damage.amount = 0;
          return EffectStack.CANCEL_PROPOGATION;  
        }        
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Seed Stat Increase',
    id : 'base:seed',
    description: 'Increases a base stat permanently.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text: 'The ' + item.name + ' glows with power!');

        @:oldStats = StatSet.new();
        oldStats.load(serialized:holder.stats.save());
        @:newState = holder.stats.save();
        newState[item.data.statIncreaseType] += item.data.statIncrease;
        holder.stats.load(serialized:newState);
        
        oldStats.printDiff(
          other:holder.stats,
          prompt: 'New stats: ' + holder.name
        );


      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Wyvern Flower',
    id : 'base:wyvern-flower',
    description: 'Increases base stats permanently.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text: 'The ' + item.name + ' glows with power!');
        @:oldStats = holder.stats.clone();
        for(0, (holder.level/2)+1) ::(i) {
          holder.autoLevel();
        }
        holder.checkStatChanged(:oldStats);
      }
    }
  }
) 


Effect.newEntry(
  data : {
    name : 'Trigger Item Art',
    id : 'base:trigger-itemart',
    description: 'Casts an Art from an item.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL | TRAIT.INSTANTANEOUS,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Trigger Protect',
    id : 'base:trigger-protect',
    description: 'Casts Protect',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL | TRAIT.INSTANTANEOUS ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        windowEvent.queueMessage(text:'It casts Protect on ' + holder.name + '!');
        holder.addEffect(
          from, id: 'base:protect', durationTurns: 3
        );            
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Trigger Evade',
    id : 'base:trigger-evade',
    description: 'Allows the user to evade all attacks for the next turn.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL  | TRAIT.INSTANTANEOUS,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        holder.addEffect(
          from, id: 'base:evade', durationTurns: 1
        );            
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Evade',
    id : 'base:evade',
    description: 'All incoming attacks are nullified.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' is covered in a mysterious wind!');
      },
      onPreAttacked ::(from, item, holder, attacker, damage) {
        windowEvent.queueMessage(text:holder.name + '\'s mysterious wind caused the attack to miss!');
        damage.amount = 0;
        return EffectStack.CANCEL_PROPOGATION;  
      }
    }
  }
) 



Effect.newEntry(
  data : {
    name : 'Cursed Binding',
    id : 'base:cursed-binding',
    description: 'The holder attacking causes 1 damage to the original caster.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:from.name + ' was afflicted with a curse!');
      },
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:from.name + '\'s curse was lifted.');      
      },
      onPostAttackOther ::(from, item, holder, damage, to) {
        windowEvent.queueMessage(text:from.name + ' was hurt from a curse!');
        from.damage(attacker:from, damage: Damage.new(
          amount: 1,
          damageType: Damage.TYPE.PHYS,
          damageClass: Damage.CLASS.HP
        ),dodgeable: false);
      }
    }
  }
) 


Effect.newEntry(
  data : {
    name : 'Trigger Regen',
    id : 'base:trigger-regen',
    description: 'Heals 1 HP.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL  | TRAIT.INSTANTANEOUS,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        when(holder.hp == 0) empty;
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        holder.heal(
          amount: 1
        );            
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Trigger Hurt Chance',
    id : 'base:trigger-hurt-chance',
    description: '10% chance to hurt for 1HP.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL  | TRAIT.INSTANTANEOUS ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        if (random.try(percentSuccess:10)) ::<= {
          windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
          holder.damage(
            attacker:holder,
            damage: Damage.new(
              amount: 1,
              damageType: Damage.TYPE.NEUTRAL,
              damageClass: Damage.CLASS.HP
            ),
            dodgeable: false
          );            
        }
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Trigger Status Ailment',
    id : 'base:trigger-random-ailment',
    description: '50% chance to give a random status ailment to the holder for 2 turns.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL | TRAIT.INSTANTANEOUS ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        if (random.try(percentSuccess:50)) ::<= {
          windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
          holder.addEffect(
            durationTurns: 2,
            from:holder,
            id : random.pickArrayItem(:[
              'base:burned',
              'base:frozen',
              'base:paralyzed',
              'base:bleeding',
              'base:poisoned',
              'base:blind',
              'base:petrified',
            ])
          );
        }
      }
    }
  }
) 



Effect.newEntry(
  data : {
    name : 'Trigger Fatigue Chance',
    id : 'base:trigger-fatigue-chance',
    description: '10% chance to hurt for 1AP.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL  | TRAIT.INSTANTANEOUS,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        if (random.try(percentSuccess:10)) ::<= {
          windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
          holder.damage(
            attacker:holder,
            damage: Damage.new(
              amount: 1,
              damageType: Damage.TYPE.NEUTRAL,
              damageClass: Damage.CLASS.AP
            ),
            dodgeable: false
          );            
        }
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Trigger Break Chance',
    id : 'base:trigger-break-chance',
    description: '5% chance to break item.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL  | TRAIT.INSTANTANEOUS,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        if (random.try(percentSuccess:5)) ::<= {
          windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
          holder.unequipItem(item, silent: true);
          windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' disintegrates.');        
        }
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Trigger Spikes',
    id : 'base:trigger-spikes',
    description: 'Casts Spikes',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL | TRAIT.INSTANTANEOUS ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        windowEvent.queueMessage(text:'It covers ' + holder.name + ' in spikes of light!');
        holder.addEffect(
          from:from, id: 'base:spikes', durationTurns: 3
        );            
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Spikes',
    id : 'base:spikes',
    description: 'DEF base +2, causes 1-4 light damage when attacked.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF: 2
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' is covered in spikes of light.');
      },
      onPreAttacked ::(from, item, holder, attacker, damage) {
        windowEvent.queueMessage(text:attacker.name + ' gets hurt by ' + holder.name + '\'s spikes of light!');
        attacker.damage(attacker:holder, damage:Damage.new(
          amount:random.integer(from:1, to:4),
          damageType:Damage.TYPE.LIGHT,
          damageClass:Damage.CLASS.HP
        ),dodgeable: false);
      },

      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s spikes of light fade.');
      }
    }
  }
) 



Effect.newEntry(
  data : {
    name : 'Trigger AP Regen',
    id : 'base:trigger-ap-regen',
    description: 'Slightly recovers AP.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL  | TRAIT.INSTANTANEOUS,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        holder.healAP(
          amount: holder.stats.AP * 0.05
        );            
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Trigger Shield',
    id : 'base:trigger-shield',
    description: 'Casts Shield',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL | TRAIT.INSTANTANEOUS ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        windowEvent.queueMessage(text:'It casts Shield on ' + holder.name + '!');
        holder.addEffect(
          from:from, id: 'base:shield', durationTurns: 3
        );            
      }
    }
  }
)     


Effect.newEntry(
  data : {
    name : 'Trigger Strength Boost',
    id : 'base:trigger-strength-boost',
    description: 'Triggers a boost in strength.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL | TRAIT.INSTANTANEOUS ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        holder.addEffect(
          from:from, id: 'base:strength-boost', durationTurns: 3
        );            
      }
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Strength Boost',
    id : 'base:strength-boost',
    description: 'ATK base +4',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      ATK:4
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s power is increased!');
      },
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s power boost fades!');
      }
    }
  }
)  


Effect.newEntry(
  data : {
    name : 'Minor Strength Boost',
    id : 'base:minor-strength-boost',
    description: 'ATK base +2',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      ATK:2
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s power is increased!');
      },
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s power boost fades!');
      }
    }
  }
)  

Effect.newEntry(
  data : {
    name : 'Trigger Defense Boost',
    id : 'base:trigger-defense-boost',
    description: 'Triggers a boost in defense.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL | TRAIT.INSTANTANEOUS ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        holder.addEffect(
          from:from, id: 'base:defense-boost', durationTurns: 3
        );            
      }
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Defense Boost',
    id : 'base:defense-boost',
    description: 'DEF base +4',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF:4
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s defense is increased!');
      },
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s defense boost fades!');
      }
    }
  }
)  

Effect.newEntry(
  data : {
    name : 'Minor Defense Boost',
    id : 'base:minor-defense-boost',
    description: 'DEF base +2',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF:2
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s defense is increased!');
      },
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s defense boost fades!');
      }
    }
  }
)  


Effect.newEntry(
  data : {
    name : 'Trigger Mind Boost',
    id : 'base:trigger-mind-boost',
    description: 'Triggers a boost in mental acuity.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL | TRAIT.INSTANTANEOUS ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        holder.addEffect(
          from:from, id: 'base:mind-boost', durationTurns: 3
        );            
      }
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Mind Boost',
    id : 'base:mind-boost',
    description: 'INT base +4',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      INT:4
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s mental acuity is increased!');
      },
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s intelligence boost fades!');
      }
    }
  }
)  

Effect.newEntry(
  data : {
    name : 'Mind Boost',
    id : 'base:minor-mind-boost',
    description: 'INT base +2',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      INT:2
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s mental acuity is increased!');
      },
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s intelligence boost fades!');
      }
    }
  }
)  

Effect.newEntry(
  data : {
    name : 'Trigger Dex Boost',
    id : 'base:trigger-dex-boost',
    description: 'Triggers a boost in dexterity.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL | TRAIT.INSTANTANEOUS ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        holder.addEffect(
          from:from, id: 'base:dex-boost', durationTurns: 3
        );            
      }
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Dex Boost',
    id : 'base:dex-boost',
    description: 'DEX base +4',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEX:4
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s dexterity is increased!');
      },
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s dexterity boost fades!');
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Minor Dex Boost',
    id : 'base:minor-dex-boost',    
    description: 'DEX base +2',
    stackable: false,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(DEX:2),
    events : { 
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s dexterity is increased!');
      },
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s dexterity boost fades!');
      }
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Trigger Speed Boost',
    id : 'base:trigger-speed-boost',
    description: 'Triggers a boost in speed.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL | TRAIT.INSTANTANEOUS ,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        holder.addEffect(
          from:from, id: 'base:speed-boost', durationTurns: 3
        );            
      }
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Speed Boost',
    id : 'base:speed-boost',
    description: 'SPD base +4',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      SPD:4
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s speed is increased!');
      },
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s speed boost fades!');
      }
    }
  }
)  

Effect.newEntry(
  data : {
    name : 'Minor Speed Boost',
    id : 'base:minor-speed-boost',
    description: 'SPD base +2',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      SPD:2
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s speed is increased!');
      },
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s speed boost fades!');
      }
    }
  }
)  




Effect.newEntry(
  data : {
    name : 'Night Veil',
    id : 'base:night-veil',
    description: 'DEF base +3',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF: 3
    ),
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s Night Veil fades away.');
      }    
    }    
  }
)  

Effect.newEntry(
  data : {
    name : 'Dayshroud',
    id : 'base:dayshroud',
    description: 'DEF base +3',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF: 3
    ),
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s Dayshroud fades away.');
      }
    }    
  }
)  

Effect.newEntry(
  data : {
    name : 'Call of the Night',
    id : 'base:call-of-the-night',
    description: 'ATK base +3',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      ATK: 3
    ),
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s Call of the Night fades away.');
      }    
    }    
  }
)  


Effect.newEntry(
  data : {
    name : 'Lunacy',
    id : 'base:lunacy',
    description: 'Skips turn and, instead, attacks a random enemy. ATK,DEF base +3.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF: 3,
      ATK: 3
    ),
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s Lunacy fades away.');
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        windowEvent.queueMessage(text:holder.name + ' attacks in a blind rage!');
        holder.attack(
          target:random.pickArrayItem(:holder.battle.getEnemies(:holder)),
          damage: Damage.new(
            amount:holder.stats.ATK * (0.5),
            damageType : Damage.TYPE.PHYS,
            damageClass: Damage.CLASS.HP
          )
        );           
        return false;
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Greater Call of the Night',
    id : 'base:greater-call-of-the-night',
    description: 'ATK base +5',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      ATK: 5
    ),
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s Call of the Night fades away.');
      }
    }    
  }
)  

Effect.newEntry(
  data : {
    name : 'Greater Night Veil',
    id : 'base:greater-night-veil',
    description: 'DEF base +5',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF: 5
    ),
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s Night Veil fades away.');
      }        
    }
  }
)  


Effect.newEntry(
  data : {
    name : 'Greater Dayshroud',
    id : 'base:greater-dayshroud',
    description: 'DEF base +5',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF: 5
    ),

    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s Dayshroud fades away.');
      }
    }    
  }
)  

Effect.newEntry(
  data : {
    name : 'Moonsong',
    id : 'base:moonsong',
    description: 'Heals 1 HP every turn.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s Moonsong fades.');
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        when(holder.hp == 0) empty;
        holder.heal(amount:1);
      }
    }
  }
)  

Effect.newEntry(
  data : {
    name : 'Sol Attunement',
    id : 'base:sol-attunement',
    description: 'Heals 1 HP every turn.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),

    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s Sol Attunement fades.');
      },        
      onNextTurn ::(from, item, holder, duration) {
        when(holder.hp == 0) empty;
        holder.heal(amount:1);
      }
    }
  }
)      

Effect.newEntry(
  data : {
    name : 'Greater Moonsong',
    id : 'base:greater-moonsong',
    description: 'Heals 2 HP every turn.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s Moonsong fades.');
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        when(holder.hp == 0) empty;
        holder.heal(amount:2);
      }
    }
  }
)     

Effect.newEntry(
  data : {
    name : 'Greater Sol Attunement',
    id : 'base:greater-sol-attunement',
    description: 'Heals 2 HP every turn.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),

    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s Sol Attunement fades.');
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        when(holder.hp == 0) empty;
        holder.heal(amount:2);
      }
    }
  }
)      

   
Effect.newEntry(
  data : {
    name : 'Grace',
    id : 'base:grace',
    description: 'If hurt while HP is 0, the damage is nullified and this effect disappears.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:'A halo appears above ' + holder.name + '!');
      },

      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + '\'s halo disappears.');
      },        
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (holder.hp == 0) ::<= {
          damage.amount = 0;
          windowEvent.queueMessage(text:holder.name + ' is protected from death!');
          holder.removeEffects(
            effectBases : [
              Effect.find(id:'base:grace')
            ]
          );
        }
           
      }
    }
  }
)   
   

Effect.newEntry(
  data : {
    name : 'Consume Item',
    id : 'base:consume-item',
    description: 'The item is destroyed in the process of its effects',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.INSTANTANEOUS | TRAIT.SPECIAL,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: "The " + item.name + ' is consumed.'
        );
        item.throwOut();        
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Cast Spell',
    id : 'base:cast-spell',
    description: 'The item casts a spell when used.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.INSTANTANEOUS | TRAIT.SPECIAL,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        @:Arts = import(:'game_database.arts.mt');
        @:ArtsDeck = import(:'game_class.artsdeck.mt');
        @:world = import(module:'game_singleton.world.mt');

        when(item == empty || holder.battle == empty) 
          windowEvent.queueMessage(text:'The casting fizzled!');

        if (item.data.spell == empty) ::<= {
          @:art = Arts.getRandomFiltered(::(value) <- value.hasTraits(:Arts.TRAIT.COMMON_ATTACK_SPELL));
          item.data.spell = art.id;        
        }
        
        @:art = Arts.find(:item.data.spell);
        @:card = ArtsDeck.synthesizeHandCard(id:item.data.spell);
        
        
        @:enemies = random.scrambled(:world.battle.getEnemies(:from))
        @:commitRandom ::{
          from.useArt(
            level: 1,
            art,
            targets : 
              enemies,
            turnIndex: 0,
            targetDefendParts :
              enemies->map(::(value) <- random.integer(from:0, to:2)),
              
            targetParts :
              enemies->map(::(value) <- random.integer(from:0, to:2))
          );
        }
        

        
        windowEvent.queueNestedResolve(
          onEnter :: {
            from.deck.revealArt(
              user:from,
              handCard:card,
              prompt: 'From the power of the ' + item.name + ', ' + from.name + ' casted the spell: ' + art.name + '!'
            );

            when(world.party.leader == from) ::<= {
              from.playerUseArt(
                commitAction::(action) {
                  from.useArt(
                    art,
                    level: 1,
                    targets: action.targets,
                    turnIndex: 0,
                    targetDefendParts :
                      enemies->map(::(value) <- random.integer(from:0, to:2)),
                      
                    targetParts :
                      action.targets
                  );
                },
                card,
                canCancel : false
              );
            }
            commitRandom();
          }
        );

      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'Break Item',
    id : 'base:break-item',
    description: 'The item is destroyed in the process of misuse or strain',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.INSTANTANEOUS,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        if (random.number() > 0.5) ::<= {
          windowEvent.queueMessage(
            text: "The " + item.name + ' broke.'
          );
          item.throwOut();        
        }
      }
    }
  }
)    

Effect.newEntry(
  data : {
    name : 'Fling',
    id : 'base:fling',
    description: 'The item is violently lunged at a target, likely causing damage. The target may catch the item.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.INSTANTANEOUS,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: from.name + ' flung the ' + item.name + ' at ' + holder.name + '!'
        );
        
        windowEvent.queueCustom(
          onEnter::{
            if (random.number() > 0.8) ::<= {
              holder.inventory.add(item);
              windowEvent.queueMessage(
                text: holder.name + ' caught the flung ' + item.name + '!!'
              );
            } else ::<= {
              holder.damage(
                attacker: from,
                damage: Damage.new(
                  amount:from.stats.ATK*(item.base.weight * 0.1),
                  damageType : Damage.TYPE.NEUTRAL,
                  damageClass: Damage.CLASS.HP
                ),
                dodgeable: true                  
              );
            }            
          }
        );

        item.throwOut();
      }
    }
  }
)  

  

Effect.newEntry(
  data : {
    name : 'Major Recovery',
    id : 'base:hp-recovery-all',
    description: 'Heals 100% of HP.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.INSTANTANEOUS,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        holder.heal(amount:holder.stats.HP);
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Major Soothing',
    id : 'base:ap-recovery-all',
    description: 'Heals 100% of AP.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.INSTANTANEOUS,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        holder.healAP(amount:holder.stats.AP);
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Minor Healing',
    id : 'base:hp-recovery-half',
    description: 'Heals 50% of HP.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.INSTANTANEOUS,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        holder.heal(amount:holder.stats.HP*0.5);
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Minor Soothing',
    id : 'base:ap-recovery-half',
    description: 'Heals 50% of AP.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.INSTANTANEOUS,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        holder.healAP(amount:holder.stats.AP*0.5);
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Treasure I',
    id : 'base:treasure-1',
    description: 'Opening gives a fair number of G.',
    stackable: true,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        @:world = import(module:'game_singleton.world.mt');
        @:amount = (50 + random.number()*400)->floor;          
        windowEvent.queueMessage(text:'The party found ' + g(g:amount) + '.');
        world.party.addGoldAnimated(
          amount:amount,
          onDone::{}
        );
      }
    }
  }
)    

Effect.newEntry(
  data : {
    name : 'Field Cook',
    id : 'base:field-cook',
    description: 'Chance to cook a meal after battle.',
    stackable: false,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
      },
      
      onRemoveEffect ::(from, item, holder) {
        @:world = import(module:'game_singleton.world.mt');
        
        
        when(random.number() > 0.7) empty;
        when(from.isIncapacitated()) empty;
        when(!world.party.isMember(entity:holder)) empty;


        windowEvent.queueMessage(
          text: '' + holder.name + ' found some food and cooked a meal for the party.'
        );
        foreach(world.party.members)::(index, member) {
          member.heal(amount:member.stats.HP * 0.1);
          member.healAP(amount:member.stats.AP * 0.1);
        }
        
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Penny Picker',
    id : 'base:penny-picker',
    description: 'Looks on the ground for G after battle.',
    stackable: false,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(),
    events : {      
      onRemoveEffect ::(from, item, holder) {
        @:world = import(module:'game_singleton.world.mt');
        
        
        when(random.number() > 0.7) empty;
        when(holder.isIncapacitated()) empty;
        when(!world.party.isMember(entity:holder)) empty;


        @:amt = (random.number() * 20)->ceil;
        windowEvent.queueMessage(
          text: '' + holder.name + ' happened to notice an additional ' + g(g:amt) + ' dropped on the ground.'
        );
        world.party.inventory.addGold(amount:amt);
        
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Alchemist\'s Scavenging',
    id : 'base:alchemists-scavenging',
    description: 'Scavenges for alchemist ingredients.',
    stackable: false,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(),
    events : {
      onRemoveEffect ::(from, item, holder) {
        @:world = import(module:'game_singleton.world.mt');
        @:Item  = import(module:'game_mutator.item.mt');
        
        when(holder.isIncapacitated()) empty;
        when(!world.party.isMember(entity:holder)) empty;
                  
        when(random.number() < 0.5) empty;          

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
        
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Trained Hand',
    id : 'base:trained-hand',
    description: 'ATK base +3',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(ATK:3),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' readies their trained hands!'
        );
      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'Focus Perception',
    id : 'base:focus-perception',
    description: 'ATK base +3',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(ATK:3),
    events : {
    
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Cheered',
    id : 'base:cheered',
    description: 'ATK base +4',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(ATK:4),
    events : {}
  }
)       

Effect.newEntry(
  data : {
    name : 'Poisonroot Growing',
    id : 'base:poisonroot-growing',
    description: 'Vines grow on holder. SPD base -2.',
    stackable: true,        
    stats: StatSet.new(SPD:-2),
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    events : {
      
      onRemoveEffect ::(from, item, holder) {          
        holder.addEffect(from:holder, id:'base:poisonroot', durationTurns:30);              
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        windowEvent.queueMessage(text: 'The poisonroot continues to grow on ' + holder.name);    
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Poisonroot',
    id : 'base:poisonroot',
    description: 'Every turn, holder takes 1 to 4 poison damage. SPD base -2',
    stackable: true,
    stats: StatSet.new(SPD:-2),
    blockPoints : 0,
    traits : TRAIT.DEBUFF,

    events : {    
      onRemoveEffect ::(from, item, holder) {   
        windowEvent.queueMessage(text:'The poisonroot vines dissipate from ' + holder.name + '.'); 
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        windowEvent.queueMessage(text:from.name + ' is strangled by the poisonroot!');          
        holder.damage(attacker:from, damage: Damage.new(
          amount: random.integer(from:1, to:4),
          damageType: Damage.TYPE.POISON,
          damageClass: Damage.CLASS.HP
        ),dodgeable: false);        
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Triproot Growing',
    id : 'base:triproot-growing',
    description: 'Vines grow on holder. SPD base -2',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(SPD:-2),
    events : {
      onRemoveEffect ::(from, item, holder) {          
        holder.addEffect(from:holder, id:'base:triproot', durationTurns:30);              
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        windowEvent.queueMessage(text: 'The triproot continues to grow on ' + holder.name);    
      
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Triproot',
    id : 'base:triproot',
    description: 'Every turn 40% chance to trip the holder, cancelling their turn. SPD base -2',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(SPD:-2),
    events : {    
      onRemoveEffect ::(from, item, holder) {          
        windowEvent.queueMessage(text:'The triproot vines dissipate from ' + holder.name + '.'); 
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        if (random.number() < 0.4) ::<= {
          windowEvent.queueMessage(text:'The triproot trips ' + holder.name + '!');
          holder.addEffect(from:holder, id:'base:stunned', durationTurns:1);                        
        }
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Healroot Growing',
    id : 'base:healroot-growing',
    description: 'Vines grow on holder. SPD base -2',
    stackable: true,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(SPD:-2),
    events : {    
      onRemoveEffect ::(from, item, holder) {          
        holder.addEffect(from:holder, id:'base:healroot', durationTurns:30);              
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        windowEvent.queueMessage(text: 'The healroot continues to grow on ' + holder.name);    
      
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Healroot',
    id : 'base:healroot',
    description: 'Every turn heals the holder by 2 HP. SPD base -2',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(SPD:-2),
    events : {    
      onRemoveEffect ::(from, item, holder) {          
        windowEvent.queueMessage(text:'The healroot vines dissipate from ' + holder.name + '.'); 
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        when(holder.hp == 0) empty;
        windowEvent.queueMessage(text:'The healroot soothe\'s ' + holder.name + '.');
        holder.heal(amount:2);
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Learn Arts',
    id : 'base:learn-arts-perfect',
    description: 'Grants the learning of support Arts for use later.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.INSTANTANEOUS | TRAIT.SPECIAL,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        @:Arts = import(:'game_database.arts.mt');
        @:ArtsDeck = import(:'game_class.artsdeck.mt');
        @:world = import(module:'game_singleton.world.mt');

        @ARTS_COUNT = 4;
        @:arts = [];
        for(0, ARTS_COUNT) ::(i) {
          @:art = Arts.getRandomFiltered(::(value) <- 
            (value.traits & Arts.TRAIT.SUPPORT) != 0 &&
            ((value.traits & Arts.TRAIT.SPECIAL) == 0) &&
            (value.rarity >= Arts.RARITY.RARE)
          );
          arts->push(:art.id);
          world.party.addSupportArt(:art.id);
        }
        
        windowEvent.queueMessage(
          text: 'New Arts have been revealed!'
        );
        
        ArtsDeck.viewCards(
          cards: arts->map(::(value) <- ArtsDeck.synthesizeHandCard(id:value))
        );

        windowEvent.queueMessage(
          text: 'The Arts were added to the Trunk. They are now available when editing any party member\'s Arts in the Party menu.'
        );      
      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'Learn Arts',
    id : 'base:learn-arts',
    description: 'Grants the learning of support Arts for use later.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.INSTANTANEOUS | TRAIT.SPECIAL,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        @:Arts = import(:'game_database.arts.mt');
        @:ArtsDeck = import(:'game_class.artsdeck.mt');
        @:world = import(module:'game_singleton.world.mt');

        @ARTS_COUNT = 6;
        @:arts = [];
        for(0, ARTS_COUNT) ::(i) {
          @:art = Arts.getRandomFiltered(::(value) <- 
            (value.traits & Arts.TRAIT.SUPPORT) != 0 &&
            ((value.traits & Arts.TRAIT.SPECIAL) == 0) &&
            (value.rarity < Arts.RARITY.EPIC)
          );
          arts->push(:art.id);
          world.party.addSupportArt(:art.id);
        }
        
        windowEvent.queueMessage(
          text: 'New Arts have been revealed!'
        );
        
        ArtsDeck.viewCards(
          cards: arts->map(::(value) <- ArtsDeck.synthesizeHandCard(id:value))
        );

        windowEvent.queueMessage(
          text: 'The Arts were added to the Trunk. They are now available when editing any party member\'s Arts in the Party menu.'
        );      
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Defend Other',
    id : 'base:defend-other',
    description: 'The original caster receives damage instead of the holder.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.SPECIAL,
    stats: StatSet.new(),
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:from.name + ' resumes a normal stance!');
      },        
      onPreDamage ::(from, item, holder, attacker, damage) {
        @:amount = damage.amount;

        when(from == holder) ::<= {
          windowEvent.queueMessage(text:from.name + ' braces for damage!');      
        }

        damage.amount = 0;
        windowEvent.queueMessage(text:from.name + ' leaps in front of ' + holder.name + ', taking damage in their stead!');

        from.damage(
          attacker,
          damage: Damage.new(
            amount,
            damageType : damage.damageType,
            damageClass: damage.damageClass
          ),dodgeable: false
        );          
        

      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Perfect Guard',
    id : 'base:perfect-guard',
    description: 'All damage from others to the holder is nullified.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' is strongly guarding themself');
      },
      
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (attacker != holder) ::<= {
          windowEvent.queueMessage(text:holder.name + ' is protected from the damage!');
          damage.amount = 0;            
        }
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Convinced',
    id : 'base:convinced',
    description: 'Convinced by someone or something: the holder is unable to use Abilities.',
    stackable: false,
    stats: StatSet.new(),
    blockPoints : 0,
    traits : TRAIT.CANT_USE_ABILITIES,
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' realizes ' + from.name + "'s argument was complete junk!")
      },
    
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' thinks about ' + from.name + "'s argument!");
        return false;
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Unbalanced',
    id : 'base:unbalanced',
    description: 'The holder is not properly balanced. ATK base -6',
    stackable: false,
    stats: StatSet.new(
      ATK: -6
    ),
    blockPoints : 0,
    traits : 0,
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' lost balance!');
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' regained balance!');
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Dampen Multi-hit',
    id : 'base:dampen-multi-hit',
    description: 'All multi-hit attack damage from the holder are nullified.',
    stackable: false,
    stats: StatSet.new(
    ),
    blockPoints : 0,
    traits : Effect.TRAIT.DEBUFF,
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        if ((damage.traits & Damage.TRAIT.MULTIHIT) != 0) ::<= {
          windowEvent.queueMessage(text: holder.name + '\'s Dampen Multi-hit nullified the attack!');
          damage.amount = 0;
        }
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Multi-hit Guard',
    id : 'base:multi-hit-guard',
    description: 'All multi-hit attack damage targetting the holder are nullified.',
    stackable: false,
    stats: StatSet.new(
    ),
    blockPoints : 0,
    traits : Effect.TRAIT.BUFF,
    events : {
      onPreAttacked ::(from, item, holder, attacker, damage) {
        if (damage.isMultihit) ::<= {
          windowEvent.queueMessage(text: holder.name + '\'s Multi-hit Guard nullified the attack!');
          damage.amount = 0;
        }
      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'Desparate',
    id : 'base:desparate',
    description: 'The holder is is desparate. HP base -4, DEF base -5. Attacks to others are 2.5 times more damaging.',
    stackable: false,
    stats: StatSet.new(
      DEF: -5,
      HP: -5
    ),
    blockPoints : 0,
    traits : 0,
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' became desparate!');
      },
      
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        windowEvent.queueMessage(text: holder.name + '\'s desparation increased damage by 2.5 times!');
        damage.amount *= 2.5;
      },      
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' is no longer desparate!');
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Enlarged',
    id : 'base:enlarged',
    description: 'The holder is is magically enlarged. HP base +3, DEF base +3',
    stackable: false,
    stats: StatSet.new(
      DEF: 3,
      HP: 3
    ),
    blockPoints : 0,
    traits : 0,
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' became enlarged!');
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' is no longer enlarged!');
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Grappled',
    id : 'base:grappled',
    description: 'Unable to use Ability or Reaction Arts. Unable to block.',
    stackable: false,
    blockPoints : -3,
    stats: StatSet.new(),
    traits : TRAIT.DEBUFF | TRAIT.CANT_USE_ABILITIES | TRAIT.CANT_USE_REACTIONS,
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' broke free from the grapple!')
      },
      onNextTurn ::(from, item, holder, duration) {        
      }
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Ensnared',
    id : 'base:ensnared',
    description: 'Unable to use Ability or Reaction Arts. Unable to block.',
    stackable: false,
    blockPoints : -3,
    traits : TRAIT.DEBUFF | TRAIT.CANT_USE_ABILITIES | TRAIT.CANT_USE_REACTIONS,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
      }
    }
  }
)  

Effect.newEntry(
  data : {
    name : 'Grappling',
    id : 'base:grappling',
    description: 'Unable to use Ability or Reaction Arts. Unable to block.',
    stackable: false,
    blockPoints : -3,
    traits : TRAIT.CANT_USE_ABILITIES | TRAIT.CANT_USE_REACTIONS,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Ensnaring',
    id : 'base:ensnaring',
    description: 'Unable to use Ability or Reaction Arts. Unable to block.',
    stackable: false,
    blockPoints : -3,
    traits : TRAIT.CANT_USE_ABILITIES | TRAIT.CANT_USE_REACTIONS,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
      }
    }
  }
)            

    

Effect.newEntry(
  data : {
    name : 'Bribed',
    id : 'base:bribed',
    description: 'Unable to use abilities.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.SPECIAL | TRAIT.CANT_USE_ABILITIES,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' was bribed and can no longer use abilities!');
        return false;
      }
    }
  }
)
Effect.newEntry(
  data : {
    name : 'Stunned',
    id : 'base:stunned',
    description: 'Unable to use Ability or Reaction Arts. Unable to block.',
    stackable: false,
    blockPoints : -3,
    traits : TRAIT.DEBUFF | TRAIT.CANT_USE_ABILITIES | TRAIT.CANT_USE_REACTIONS,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
      },

      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' was stunned!');
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' came to their senses!');
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Sharpen',
    id : 'base:sharpen',
    description: 'ATK base +1',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      ATK: 1
    ),
    events : {
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Weaken Armor',
    id : 'base:weaken-armor',
    description: 'DEF base -1',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(
      DEF: -1
    ),
    events : {}
  }
)    

Effect.newEntry(
  data : {
    name : 'Dull Weapon',
    id : 'base:dull-weapon',
    description: 'ATK base -1',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(
      ATK: -1
    ),
    events : {}
  }
)

Effect.newEntry(
  data : {
    name : 'Strengthen Armor',
    id : 'base:strengthen-armor',
    description: 'DEF base +1',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF: 1
    ),
    events : {}
  }
)  


Effect.newEntry(
  data : {
    name : 'Lunar Affinity',
    id : 'base:lunar-affinity',
    description: 'INT,DEF,ATK base + 3 if night time.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      
    ),
    events : {
      onAffliction ::(from, item, holder) {
        @:world = import(module:'game_singleton.world.mt');

        if (world.time > world.TIME.EVENING) ::<= {
          windowEvent.queueMessage(text:'The moon shimmers... ' + holder.name +' softly glows');          
        }
      },
      onStatRecalculate ::(from, item, holder, stats) {
        @:world = import(module:'game_singleton.world.mt');

        if (world.time > world.TIME.EVENING) ::<= {
          stats.mod(stats:StatSet.new(INT:3, DEF:3, ATK:3));
        }          
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Coordinated',
    id : 'base:coordinated',
    description: 'SPD,DEF,ATK base +2',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      ATK:2,
      DEF:2,
      SPD:2
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name +' is ready to coordinate!');          
      }
    }
  }
)
Effect.newEntry(
  data : {
    name : 'Cautious',
    id : 'base:cautious',
    description: 'DEF base +2',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name +' braces for incoming damage!');          
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' no longer braces for damage.');
      },        

      onStatRecalculate ::(from, item, holder, stats) {
        stats.mod(stats:StatSet.new(DEF:2));
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Solar Affinity',
    id : 'base:solar-affinity',
    description: 'INT,DEF,ATK base +3 if day time.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      
    ),
    events : {
      onAffliction ::(from, item, holder) {
        @:world = import(module:'game_singleton.world.mt');

        if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
          windowEvent.queueMessage(text:'The sun intensifies... ' + holder.name +' softly glows');          
        }
      },

      onStatRecalculate ::(from, item, holder, stats) {
        @:world = import(module:'game_singleton.world.mt');

        if (world.time >= world.TIME.MORNING && world.time < world.TIME.EVENING) ::<= {
          stats.mod(stats:StatSet.new(INT:3, DEF:3, ATK:3));
        }          
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Non-combat Weapon',
    id : 'base:non-combat-weapon',
    description: '20% chance to deflect attack then break weapon.',
    stackable: true,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(),
    events : {

      onPreDamage ::(from, item, holder, attacker, damage) {
        if (random.number() > 0.8 && damage.damageType == Damage.TYPE.PHYS) ::<= {
          @:Entity = import(module:'game_class.entity.mt');
        
          windowEvent.queueMessage(text:holder.name + " parries the blow, but their non-combat weapon breaks in the process!");
          damage.amount = 0;
          @:item = holder.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR);
          holder.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
          item.throwOut();            
        }
      }
    }
  }
)   




Effect.newEntry(
  data : {
    name : 'Auto-Life',
    id : 'base:auto-life',
    description: '50% chance to fully revive if damaged while at 0 HP. This breaks the item.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.REVIVAL,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
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
      }
    }
  }
)  



Effect.newEntry(
  data : {
    name : 'Flight',
    id : 'base:flight',
    description: 'Causes all damaging attacks from others to miss.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (attacker != holder) ::<= {
          @:Entity = import(module:'game_class.entity.mt');          
          windowEvent.queueMessage(text:holder.name + " dodges the damage from Flight!");
          damage.amount = 0;
          return EffectStack.CANCEL_PROPOGATION
        }
      }
    }
  }
)    
   
Effect.newEntry(
  data : {
    name : 'Assassin\'s Pride',
    id : 'base:assassins-pride',
    description: 'Add a stack of Pride for each person defeated.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        if (to.isIncapacitated()) ::<= {
          windowEvent.queueMessage(text:holder.name + "'s ending blow to " + to.name + " increases "+ holder.name + "'s abilities due to their Assassin's Pride.");            
          holder.addEffect(from:holder, id: 'base:pride', durationTurns: 10);            
        }
      }
    }
  }
)    
Effect.newEntry(
  data : {
    name : 'Pride',
    id : 'base:pride',
    description: 'SPD, ATK base +1',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      ATK:1,
      SPD:1
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " is feeling prideful.");
      }
    }
  }
)    
  
Effect.newEntry(
  data : {
    name : 'Dueled',
    id : 'base:dueled',
    description: 'If attacked by the original caster, the holder receives 1.5x damage.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (from == attacker) ::<= {
          windowEvent.queueMessage(text: from.name + '\'s duel challenge focuses damage!');
          damage.amount *= 2.25;
        }
      }
    }
  }
)  
Effect.newEntry(
  data : {
    name : 'Consume Item Partially',
    id : 'base:consume-item-partially',
    description: 'The item has a chance of being used up',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.SPECIAL,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        if (random.number() > 0.7) ::<={
          windowEvent.queueMessage(
            text: "The " + item.name + ' is used in its entirety.'
          );
          item.throwOut();                  
        } else ::<={
          windowEvent.queueMessage(
            text: "A bit of the " + item.name + ' is used.'
          );          
        }
      }
    }
  }
)  

Effect.newEntry(
  data : {
    name : 'Bleeding',
    id : 'base:bleeding',
    description: '-5% total HP every turn on holder. ATK,DEF,SPD -1 base.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.AILMENT,
    stats: StatSet.new(
      ATK: -1,
      DEF: -1,
      SPD: -1
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " started to bleed out!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " is no longer bleeding out.");
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        windowEvent.queueMessage(text:holder.name + " suffered from bleeding!");
        
        holder.damage(
          attacker: holder,
          damage: Damage.new(
            amount:holder.stats.HP*0.05,
            damageType : Damage.TYPE.NEUTRAL,
            damageClass: Damage.CLASS.HP
          ),dodgeable: false
        );
      }
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Explode',
    id : 'base:explode',
    description: 'Damage to holder.',
    stackable: true,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:"The " + item.name + " explodes on " + from.name + "!");
        
        holder.damage(
          attacker: holder,
          damage: Damage.new(
            amount:random.integer(from:10, to:20),
            damageType : Damage.TYPE.FIRE,
            damageClass: Damage.CLASS.HP                             
          ),dodgeable: false 
        );
      
      }
    }
  }
)    
Effect.newEntry(
  data : {
    name : 'Poison Rune',
    id : 'base:poison-rune',
    description: 'Deals 1 to 3 Poison damage every turn to holder.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:'Glowing purple runes were imprinted on ' + holder.name + "!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:'The poison rune fades from ' + holder.name + '.');
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        windowEvent.queueMessage(text:holder.name + " was hurt by the poison rune!");
        
        holder.damage(
          attacker: holder,
          damage: Damage.new(
            amount:random.integer(from:1, to:3),
            damageType : Damage.TYPE.POISON,
            damageClass: Damage.CLASS.HP
          ),dodgeable: false 
        );
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Destruction Rune',
    id : 'base:destruction-rune',
    description: 'Causes INT-based damage when rune is released.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:'Glowing orange runes were imprinted on ' + holder.name + "!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:'The destruction rune fades from ' + holder.name + '.');
        from.attack(
          target:holder,
          damage: Damage.new(
            amount:from.stats.INT * (1.2),
            damageType : Damage.TYPE.FIRE,
            damageClass: Damage.CLASS.HP
          )
        );
      }
    }
  }
)
Effect.newEntry(
  data : {
    name : 'Regeneration Rune',
    id : 'base:regeneration-rune',
    description: 'Heals holder every turn by 1 HP.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:'Glowing cyan runes were imprinted on ' + holder.name + "!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:'The regeneration rune fades from ' + holder.name + '.');
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        windowEvent.queueMessage(text:holder.name + " was healed by the regeneration rune.");
        holder.heal(amount:1);
      }
    }
  }
)    
Effect.newEntry(
  data : {
    name : 'Shield Rune',
    id : 'base:shield-rune',
    description: 'DEF base +5',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
      DEF: 5
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:'Glowing deep-blue runes were imprinted on ' + holder.name + "!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:'The shield rune fades from ' + holder.name + '.');
      }
    }
  }
)    


Effect.newEntry(
  data : {
    name : 'Cure Rune',
    id : 'base:cure-rune',
    description: 'Cures the holder by 3 HP when the rune is released.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:'Glowing green runes were imprinted on ' + holder.name + "!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:'The cure rune fades from ' + holder.name + '.');
        holder.heal(amount:3);
      }
    }
  }
) 

//////////////////////////////
/// STATUS AILMENTS

Effect.newEntry(
  data : {
    name : 'Poisoned',
    id : 'base:poisoned',
    description: 'Holder takes damage equal to 5% total HP every turn.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.AILMENT,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " was poisoned!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " is no longer poisoned.");
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        windowEvent.queueMessage(text:holder.name + " was hurt by the poison!");
        
        holder.damage(
          attacker: holder,
          damage: Damage.new(
            amount:holder.stats.HP*0.05,
            damageType : Damage.TYPE.NEUTRAL,
            damageClass: Damage.CLASS.HP
          ),dodgeable: false 
        );
      }
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Blind',
    id : 'base:blind',
    description: '50% chance to miss attacks made by the user.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.AILMENT,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " was blinded!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " is no longer blind.");
      },        

      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        when (random.number() > 0.5) empty;
        windowEvent.queueMessage(text:holder.name + " missed in their blindness!");
        damage.amount = 0;
      }
    }
  }
)       
  

Effect.newEntry(
  data : {
    name : 'Burned',
    id : 'base:burned',
    description: '50% chance to get damage each turn.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.AILMENT,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " was burned!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " is no longer burned.");
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        when(random.number() > 0.5) empty;
        windowEvent.queueMessage(text:holder.name + " was hurt by burns!");
        holder.damage(
          attacker:holder,
          damage : Damage.new(
            amount: holder.stats.HP / 16,
            damageClass: Damage.CLASS.HP,
            damageType: Damage.TYPE.NEUTRAL                           
          ),dodgeable: false 
        );
      }
    }
  }
) 
Effect.newEntry(
  data : {
    name : 'Frozen',
    id : 'base:frozen',
    description: 'Unable to use Ability or Reaction Arts. Unable to block.',
    stackable: false,
    blockPoints : -3,
    traits : TRAIT.AILMENT | TRAIT.CANT_USE_ABILITIES | TRAIT.CANT_USE_REACTIONS,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
      },
      
    
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " was frozen");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " is no longer frozen.");
      }
    }
  }
)     

Effect.newEntry(
  data : {
    name : 'Paralyzed',
    id : 'base:paralyzed',
    description: 'SPD base -10. Unable to use Ability or Reaction Arts.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.AILMENT | TRAIT.CANT_USE_ABILITIES | TRAIT.CANT_USE_REACTIONS,
    stats: StatSet.new(
      SPD: -10
    ),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
      },

      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " was paralyzed");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " is no longer paralyzed.");
      }
    }
  }
) 


Effect.newEntry(
  data : {
    name : 'Mesmerized',
    id : 'base:mesmerized',
    description: 'SPD,DEF base -4. Unable to use Ability or Reaction Arts, unable to block.',
    stackable: false,
    blockPoints : -3,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(
      SPD: -4,
      DEF: -4
    ),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
      },

      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " was mesmerized!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " is no longer mesmerized.");
      }
    }
  }
) 


Effect.newEntry(
  data : {
    name : 'Wrapped',
    id : 'base:wrapped',
    description: 'Unable to use Abilities. Unable to block.',
    stackable: false,
    blockPoints : -3,
    traits : TRAIT.SPECIAL | TRAIT.CANT_USE_ABILITIES,
    stats: StatSet.new(
    ),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
      },

      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " was wrapped and encoiled!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " is no longer wrapped.");
      }
    }
  }
) 


Effect.newEntry(
  data : {
    name : 'Petrified',
    id : 'base:petrified',
    description: 'Unable to use Ability or Reaction Arts. DEF base -4',
    stackable: false,
    blockPoints : -3,
    traits : TRAIT.AILMENT | TRAIT.CANT_USE_ABILITIES | TRAIT.CANT_USE_REACTIONS,
    stats: StatSet.new(
      DEF: -4
    ),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
      },

      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " was petrified!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " is no longer petrified!");
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Elemental Tag',
    id : 'base:elemental-tag',
    description: 'Weakness to Fire, Ice, and Thunder damage by 100%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {

      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.FIRE) ::<= {
          damage.amount *= 2;
        }
        if (damage.damageType == Damage.TYPE.ICE) ::<= {
          damage.amount *= 2;
        }
        if (damage.damageType == Damage.TYPE.THUNDER) ::<= {
          damage.amount *= 2;
        }
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Elemental Shield',
    id : 'base:elemental-shield',
    description: 'Completely nullifies fire, ice, and thunder damage types.',
    stats: StatSet.new(),
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    events : {

      onPreDamage ::(from, item, holder, attacker, damage) {
        
        if (damage.damageType == Damage.TYPE.FIRE) ::<= {
          damage.amount *= 0;
        }
        if (damage.damageType == Damage.TYPE.ICE) ::<= {
          damage.amount *= 0;
        }
        if (damage.damageType == Damage.TYPE.THUNDER) ::<= {
          damage.amount *= 0;
        }
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Fire Guard',
    id : 'base:fire-guard',
    description: 'Reduces incoming fire damage by 25%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.FIRE) ::<= {
          damage.amount *= 0.25;
        }
      }
    }
  }
)     


Effect.newEntry(
  data : {
    name : 'Ice Guard',
    id : 'base:ice-guard',
    description: 'Reduces incoming ice damage by 25%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.ICE) ::<= {
          damage.amount *= 0.25;
        }
      }
    }
  }
)     


Effect.newEntry(
  data : {
    name : 'Thunder Guard',
    id : 'base:thunder-guard',
    description: 'Reduces incoming thunder damage by 25%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.ICE) ::<= {
          damage.amount *= 0.25;
        }
      }
    }
  }
)     


Effect.newEntry(
  data : {
    name : 'Dark Guard',
    id : 'base:dark-guard',
    description: 'Reduces incoming dark damage by 25%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.DARK) ::<= {
          damage.amount *= 0.25;
        }
      }
    }
  }
)     

Effect.newEntry(
  data : {
    name : 'Light Guard',
    id : 'base:light-guard',
    description: 'Reduces incoming light damage by 25%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.LIGHT) ::<= {
          damage.amount *= 0.25;
        }
      }
    }
  }
)     

Effect.newEntry(
  data : {
    name : 'Poison Guard',
    id : 'base:poison-guard',
    description: 'Reduces incoming poison damage by 25%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.POISON) ::<= {
          damage.amount *= 0.25;
        }
      }
    }
  }
)     



Effect.newEntry(
  data : {
    name : 'Fire Curse',
    id : 'base:fire-curse',
    description: 'Deals 1 to 2 fire damage to holder every turn. If the holder gains Burning, all instances of this are removed.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAddEffect ::(from, holder, item, effectData) {
        if (effectData.id == 'base:burning') ::<= {
          windowEvent.queueMessage(
            text: 'Burning lifted the Fire Curse!'
          );
          
          holder.removeEffectsByFilter(::(value) <- value.id == 'base:fire-curse');
        }
      },
      onNextTurn ::(from, item, holder, duration) {     
        windowEvent.queueMessage(
          text: holder.name + ' is hurt by the Fire Curse!'
        );  
         
        holder.damage(
          attacker: holder,
          damage: Damage.new(
            amount:random.integer(from:1, to:2),
            damageType : Damage.TYPE.FIRE,
            damageClass: Damage.CLASS.HP
          ),dodgeable: false 
        );
      }
    }
  }
)     

Effect.newEntry(
  data : {
    name : 'Ice Curse',
    id : 'base:ice-curse',
    description: 'Deals 1 to 2 fire damage to holder every turn. If the holder gains Icy, all instances of this are removed.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAddEffect ::(from, holder, item, effectData) {
        if (effectData.id == 'base:icy') ::<= {
          windowEvent.queueMessage(
            text: 'Icy lifted the Ice Curse!'
          );
          
          holder.removeEffectsByFilter(::(value) <- value.id == 'base:ice-curse');
        }
      },
      onNextTurn ::(from, item, holder, duration) {     
        windowEvent.queueMessage(
          text: holder.name + ' is hurt by the Ice Curse!'
        );  
         
        holder.damage(
          attacker: holder,
          damage: Damage.new(
            amount:random.integer(from:1, to:2),
            damageType : Damage.TYPE.ICE,
            damageClass: Damage.CLASS.HP
          ),dodgeable: false 
        );
      }
    }
  }
)     




Effect.newEntry(
  data : {
    name : 'Thunder Curse',
    id : 'base:thunder-curse',
    description: 'Deals 1 to 2 thunder damage to holder every turn. If the holder gains Shock, all instances of this are removed.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAddEffect ::(from, holder, item, effectData) {
        if (effectData.id == 'base:shock') ::<= {
          windowEvent.queueMessage(
            text: 'Shock lifted the Thunder Curse!'
          );
          
          holder.removeEffectsByFilter(::(value) <- value.id == 'base:thunder-curse');
        }
      },
      onNextTurn ::(from, item, holder, duration) {     
        windowEvent.queueMessage(
          text: holder.name + ' is hurt by the Thunder Curse!'
        );  
         
        holder.damage(
          attacker: holder,
          damage: Damage.new(
            amount:random.integer(from:1, to:2),
            damageType : Damage.TYPE.THUNDER,
            damageClass: Damage.CLASS.HP
          ),dodgeable: false 
        );
      }
    }
  }
)     



Effect.newEntry(
  data : {
    name : 'Dark Curse',
    id : 'base:dark-curse',
    description: 'Deals 1 to 2 dark damage to holder every turn. If the holder gains Dark, all instances of this are removed.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAddEffect ::(from, holder, item, effectData) {
        if (effectData.id == 'base:dark') ::<= {
          windowEvent.queueMessage(
            text: 'Dark lifted the Dark Curse!'
          );
          
          holder.removeEffectsByFilter(::(value) <- value.id == 'base:dark-curse');
        }
      },
      onNextTurn ::(from, item, holder, duration) {     
        windowEvent.queueMessage(
          text: holder.name + ' is hurt by the Dark Curse!'
        );  
         
        holder.damage(
          attacker: holder,
          damage: Damage.new(
            amount:random.integer(from:1, to:2),
            damageType : Damage.TYPE.DARK,
            damageClass: Damage.CLASS.HP
          ),dodgeable: false 
        );
      }
    }
  }
)     

Effect.newEntry(
  data : {
    name : 'Light Curse',
    id : 'base:light-curse',
    description: 'Deals 1 to 2 light damage to holder every turn. If the holder gains Shimmering, all instances of this are removed.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAddEffect ::(from, holder, item, effectData) {
        if (effectData.id == 'base:shimmering') ::<= {
          windowEvent.queueMessage(
            text: 'Shimmering lifted the Light Curse!'
          );
          
          holder.removeEffectsByFilter(::(value) <- value.id == 'base:light-curse');
        }
      },
      onNextTurn ::(from, item, holder, duration) {     
        windowEvent.queueMessage(
          text: holder.name + ' is hurt by the Light Curse!'
        );  
         
        holder.damage(
          attacker: holder,
          damage: Damage.new(
            amount:random.integer(from:1, to:2),
            damageType : Damage.TYPE.LIGHT,
            damageClass: Damage.CLASS.HP
          ),dodgeable: false 
        );
      }
    }
  }
)     


Effect.newEntry(
  data : {
    name : 'Poison Curse',
    id : 'base:poison-curse',
    description: 'Deals 1 to 2 poison damage to holder every turn. If the holder gains Toxic, all instances of this are removed.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAddEffect ::(from, holder, item, effectData) {
        if (effectData.id == 'base:toxic') ::<= {
          windowEvent.queueMessage(
            text: 'Toxic lifted the Poison Curse!'
          );
          
          holder.removeEffectsByFilter(::(value) <- value.id == 'base:poison-curse');
        }
      },
      onNextTurn ::(from, item, holder, duration) {     
        windowEvent.queueMessage(
          text: holder.name + ' is hurt by the Poison Curse!'
        );  
         
        holder.damage(
          attacker: holder,
          damage: Damage.new(
            amount:random.integer(from:1, to:2),
            damageType : Damage.TYPE.POISON,
            damageClass: Damage.CLASS.HP
          ),dodgeable: false 
        );
      }
    }
  }
)    


Effect.newEntry(
  data : {
    name : 'Burning',
    id : 'base:burning',
    description: 'Gives 1 to 4 additional fire damage per attack and reduces incoming ice damage by 50%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        to.damage(attacker:to, damage: Damage.new(
          amount: random.integer(from:1, to:4),
          damageType: Damage.TYPE.FIRE,
          damageClass: Damage.CLASS.HP
        ),dodgeable: false);
      },

      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.ICE) ::<= {
          damage.amount *= 0.5;
        }
      }
    }
  }
)     

Effect.newEntry(
  data : {
    name : 'Scorching',
    id : 'base:scorching',
    description: 'Attacks have 20% chance to inflict a stack of Burn for 5 turns.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        if (random.try(percentSuccess:20))
          to.addEffect(from, id:'base:burned',durationTurns:5);
      }
    }
  }
)    


Effect.newEntry(
  data : {
    name : 'Sharp',
    id : 'base:sharp',
    description: 'Attacks have 20% chance to inflict a stack of Bleeding for 5 turns.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        if (random.try(percentSuccess:20))
          to.addEffect(from, id:'base:bleeding',durationTurns:5);
      }
    }
  }
) 



Effect.newEntry(
  data : {
    name : 'Icy',
    id : 'base:icy',
    description: 'Gives 1 to 4 additional ice damage per attack and reduces incoming fire damage by 50%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        to.damage(attacker:to, damage: Damage.new(
          amount: random.integer(from:1, to:4),
          damageType: Damage.TYPE.ICE,
          damageClass: Damage.CLASS.HP
        ),dodgeable: false);
      },

      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.FIRE) ::<= {
          damage.amount *= 0.5;
        }
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Freezing',
    id : 'base:freezing',
    description: 'Attacks have 10% chance to inflict Frozen for 2 turns.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        if (random.try(percentSuccess:10))
          to.addEffect(from, id:'base:frozen',durationTurns:2);
      }
    }
  }
)    






Effect.newEntry(
  data : {
    name : 'Shock',
    id : 'base:shock',
    description: 'Gives 1 to 4 additional thunder damage per attack and reduces incoming thunder damage by 50%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        to.damage(attacker:to, damage: Damage.new(
          amount: random.integer(from:1, to:4),
          damageType: Damage.TYPE.THUNDER,
          damageClass: Damage.CLASS.HP
        ),dodgeable: false);
      },
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.THUNDER) ::<= {
          damage.amount *= 0.5;
        }
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Paralyzing',
    id : 'base:paralyzing',
    description: 'Attacks have 10% chance to inflict Paralyzed for 2 turns.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        if (random.try(percentSuccess:10))
          to.addEffect(from, id:'base:paralyzed',durationTurns:2);
      }
    }
  }
)    





Effect.newEntry(
  data : {
    name : 'Toxic',
    id : 'base:toxic',
    description: 'Gives 1 to 4 additional poison damage per attack and reduces incoming poison damage by 50%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        to.damage(attacker:to, damage: Damage.new(
          amount: random.integer(from:1, to:4),
          damageType: Damage.TYPE.POISON,
          damageClass: Damage.CLASS.HP
        ),
        dodgeable: false
        );
      },
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.POISON) ::<= {
          damage.amount *= 0.5;
        }
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Seeping',
    id : 'base:seeping',
    description: 'Attacks have 20% chance to inflict a stack of Poisoned for 5 turns.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        if (random.try(percentSuccess:20))
          to.addEffect(from, id:'base:poisoned',durationTurns:5);
      }
    }
  }
)    



Effect.newEntry(
  data : {
    name : 'Shimmering',
    id : 'base:shimmering',
    description: 'Gives 1 to 4 additional light damage per attack and reduces incoming dark damage by 50%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        to.damage(attacker:to, damage: Damage.new(
          amount: random.integer(from:1, to:4),
          damageType: Damage.TYPE.LIGHT,
          damageClass: Damage.CLASS.HP
        ),dodgeable: false);
      },
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.DARK) ::<= {
          damage.amount *= 0.5;
        }
      }
    }
  }
)    

Effect.newEntry(
  data : {
    name : 'Petrifying',
    id : 'base:petrifying',
    description: 'Attacks have 10% chance to inflict Petrified for 2 turns.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        if (random.try(percentSuccess:10))
          to.addEffect(from, id:'base:petrified',durationTurns:2);
      }
    }
  }
)   


Effect.newEntry(
  data : {
    name : 'Dark',
    id : 'base:dark',
    description: 'Gives 1 to 4 additional dark damage per attack and reduces incoming light damage by 50%',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        to.damage(attacker:to, damage: Damage.new(
          amount: random.integer(from:1, to:4),
          damageType: Damage.TYPE.DARK,
          damageClass: Damage.CLASS.HP
        ),dodgeable: false);
      },

      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.LIGHT) ::<= {
          damage.amount *= 0.5;
        }
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Blinding',
    id : 'base:blinding',
    description: 'Attacks have 10% chance to inflict Blind for 3 turns.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPostAttackOther ::(from, item, holder, to) {
        if (random.try(percentSuccess:10))
          to.addEffect(from, id:'base:blind',durationTurns:3);
      }
    }
  }
)   




Effect.newEntry(
  data : {
    name : 'Banish',
    id : 'base:banish',
    description: 'ATK, SPD base -1. At 10 stacks, the holder is removed from battle.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(
      ATK: -1,
      SPD: -1
    ),
    events : {
      onAffliction ::(from, item, holder, to) {
        @:stackCount = [...holder.effectStack.getAll()]->filter(::(value) <- value.id == 'base:banish')->size;

        if (stackCount >= 10) ::<= {
          windowEvent.queueMessage(
            text: holder.name + ' has been banished!'
          );
          
          holder.battle.evict(:holder);
        }
      }
    }
  }
) 

Effect.newEntry(
  data : {
    name : 'Banish Shield',
    id : 'base:banish-shield',
    description: 'Prevents all additional Banish stacks.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onPreAddEffect ::(from, holder, item, effectData) {
        when(effectData.id == 'base:banish' && from != holder) ::<= {
          windowEvent.queueMessage(
            text: holder.name + '\'s Banish Shield prevents the incoming stack of Banish!'
          );
          return false;
        }
      }
    }
  }
) 



Effect.newEntry(
  data : {
    name : 'Redirect Momentum',
    id : 'base:redirect-momentum',
    description: 'If the holder is to be afflicted with Grappled, instead the holder inflicts 1/3 of the source\'s DEF in damage to the source of the Grappled effect and Stuns them for a turn.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {

      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' is prepared for an attack!'
        );
      },
      onPreAddEffect ::(from, holder, item, effectData) {
        when(effectData.id == 'base:grappled' && from != holder) ::<= {
          @dmg = from.DEF * 0.33;
          when (dmg < 1) empty;

          windowEvent.queueMessage(
            text: holder.name + ' counters ' + from.name + '\'s grapple!'
          );

          holder.attack(
            target:from,
            damage: Damage.new(
              amount: dmg,
              damageType : Damage.TYPE.PHYS,
              damageClass: Damage.CLASS.HP
            )
          );        
          
          holder.addEffect(from:holder, id:'base:stunned', durationTurns:1);
        
          return false;
        }
      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'Shift Boost',
    id : 'base:shift-boost',
    description: 'Attack shifts now increase the power of their respective damage type. The damage is boosted by 20% for each stack.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        @:id = match(damage.type) {
          (Damage.TYPE.FIRE) : 'base:burning',
          (Damage.TYPE.ICE) : 'base:icy',
          (Damage.TYPE.THUNDER) : 'base:shock',
          (Damage.TYPE.LIGHT) : 'base:shimmering',
          (Damage.TYPE.DARK) : 'base:dark',
          (Damage.TYPE.POISON) : 'base:toxic'
        }
        
        when(id == empty) empty;
        
        @:size = from.effectStack.getAllByFilter(::(value) <- value.id == id)->size;
        when(size == 0) empty;
        
        @damageTypeName ::{
          return match(damage.damageType) {
            (Damage.TYPE.FIRE): 'fire ',
            (Damage.TYPE.ICE): 'ice ',
            (Damage.TYPE.THUNDER): 'thunder ',
            (Damage.TYPE.LIGHT): 'light ',
            (Damage.TYPE.DARK): 'dark ',
            (Damage.TYPE.PHYS): 'physical ',
            (Damage.TYPE.POISON): 'poison ',
            (Damage.TYPE.NEUTRAL): ''
          }
        }        
        
        windowEvent.queueMessage(
          text: 'Shift Boost boosted the ' + damageTypeName(:damage.type) + 'damage by ' + size * 20 + '%!'
        );
        damage.amount *= 1 + 0.20 * size;      
      }
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Clean Blessing',
    id : 'base:clean-blessing',
    description: 'Any time an effect is forcibly removed from the holder, a random positive effect is added for 3 turns.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onEffectRemoveForced ::(from, holder, item, effectData) {
        windowEvent.queueMessage(
          text: holder.name + '\'s Clean Blessing granted a positive effect!'
        );
        
        holder.addEffect(
          id: Effect.getRandomFiltered(::(value) <- 
            (value.traits & Effect.TRAIT.SPECIAL) == 0 &&
            (value.traits & Effect.TRAIT.BUFF) != 0
          ),
          durationTurns: 3,
          from:holder
        );
      }
    }
  }
)    

Effect.newEntry(
  data : {
    name : 'Clean Curse',
    id : 'base:clean-curse',
    description: 'Any time an effect is forcibly removed from the holder, a random negative effect is added for 3 turns.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onEffectRemoveForced ::(from, holder, item, effectData) {
        windowEvent.queueMessage(
          text: holder.name + '\'s Clean Curse inflicted a negative effect!'
        );
        
        holder.addEffect(
          id: Effect.getRandomFiltered(::(value) <- 
            (value.traits & Effect.TRAIT.SPECIAL) == 0 &&
            (
              (value.traits & Effect.TRAIT.DEBUFF) != 0 ||
              (value.traits & Effect.TRAIT.AILMENT) != 0
            )
          ),
          durationTurns: 3,
          from:holder
        );
      }
    }
  }
)    


Effect.newEntry(
  data : {
    name : 'Critical Reaction',
    id: 'base:critical-reaction',
    description: 'When the holder lands a critical hit, a random, non-reaction Art is used from their hand at no AP cost.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onCrit ::(to, item, holder) {
        @:Arts = import(:'game_database.arts.mt');
        @:world = import(module:'game_singleton.world.mt');
        // outside of battle?
        when (holder.battle == empty) empty;


        @:arts = holder.deck.hand->filter(
          ::(value) <- Arts.find(:value.id).kind != Arts.KIND.REACTION
        );
        
        when(arts->size == 0) empty;
        @:card = random.pickArrayItem(:arts);
        holder.deck.discardFromHand(:card);


        holder.deck.revealArt(
          prompt: holder.name + '\'s Critical Reaction activated a random Art from their hand!',
          user:holder,
          handCard: card
        );
        
        // hacky! but fun. maybe functional
        if (world.party.leader == holder) ::<= {
          holder.playerUseArt(
            card:card,
            canCancel: false,
            commitAction::(action) {            
              holder.battle.entityCommitAction(action, from:holder);
            }
          );
        } else ::<= {
          holder.battleAI.commitTargettedAction(
            battle:holder.battle,
            card: card,
            onCommit ::(action) {
              holder.battle.entityCommitAction(action, from:holder);
            }
          );
          
        }
        
      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'Cascading Flash',
    id: 'base:cascading-flash',
    description: 'At the start of the holder\'s turn, 30% chance to play the Art at the top of the holder\'s deck as long as the Art is not a reaction.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onNextTurn ::(item, holder) {
        @:Arts = import(:'game_database.arts.mt');
        @:world = import(module:'game_singleton.world.mt');
        // outside of battle?
        when (holder.battle == empty) empty;
        when (random.try(percentSuccess:70)) empty;

        when (
          Arts.find(:holder.deck.deckPile[holder.deck.deckPile->size-1]).kind == Arts.KIND.REACTION
        ) empty;

        @:card = holder.deck.draw();
        holder.deck.discardFromHand(:card);

        holder.deck.revealArt(
          prompt: holder.name + '\'s Cascading Flash activated the next Art from their deck!',
          user:holder,
          handCard: card
        );
        
        // hacky! but fun. maybe functional
        if (world.party.leader == holder) ::<= {
          holder.playerUseArt(
            card:card,
            canCancel: false,
            commitAction::(action) {            
              holder.battle.entityCommitAction(action, from:holder);
            }
          );
        } else ::<= {
          holder.battleAI.commitTargettedAction(
            battle:holder.battle,
            card: card,
            onCommit ::(action) {
              holder.battle.entityCommitAction(action, from:holder);
            }
          );
          
        }
        
      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'First Strike',
    id : 'base:first-strike',
    description: 'The holder always goes first. If another combatant also always goes first, the order is decided randomly.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.DEBUFF | TRAIT.ALWAYS_FIRST,
    stats: StatSet.new(),
    events : {
    }
  }
)  


Effect.newEntry(
  data : {
    name : 'Clairvoyance',
    id: 'base:clairvoyance',
    description: 'At the start of the holder\'s turn after drawing, they can view the top 2 cards of their deck.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onNextTurn ::(item, holder) {
        @:Arts = import(:'game_database.arts.mt');
        @:world = import(module:'game_singleton.world.mt');
        // outside of battle?
        when (world.party.leader != holder) empty;

        @:cards = holder.deck.peekTopCards(count:2);
        windowEvent.queueNestedResolve(
          onEnter ::{
            @:ArtsDeck = import(:'game_class.artsdeck.mt');

            windowEvent.queueMessage(
              text: 'These 2 cards will be drawn next.'
            );
          
            ArtsDeck.viewCards(
              uter:holder,
              cards
            );
          }
        );
      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'Scatterbrained',
    id: 'base:scatterbrained',
    description: 'At the start of the holder\'s turn, 50% chance to play a random non-reaction Art from the holder\'s hand.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onNextTurn ::(item, holder) {
        @:Arts = import(:'game_database.arts.mt');
        @:world = import(module:'game_singleton.world.mt');
        // outside of battle?
        when (holder.battle == empty) empty;

        @:cards = holder.deck.hand->filter(::(value) <- Arts.find(:value.id).kind != Arts.KIND.REACTION);
        when(cards->size == 0) empty;

        when (random.flipCoin()) empty;

        @:card = random.pickArrayItem(:cards);
        holder.deck.discardFromHand(:card);

        holder.deck.revealArt(
          prompt: holder.name + '\'s Scatterbrained activated a random Art from their hand!',
          user:holder,
          handCard: card
        );
        
        // hacky! but fun. maybe functional
        if (world.party.leader == holder) ::<= {
          holder.playerUseArt(
            card:card,
            canCancel: false,
            commitAction::(action) {            
              holder.battle.entityCommitAction(action, from:holder);
            }
          );
        } else ::<= {
          holder.battleAI.commitTargettedAction(
            battle:holder.battle,
            card: card,
            onCommit ::(action) {
              holder.battle.entityCommitAction(action, from:holder);
            }
          );
          
        }
        
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Half Guard',
    id : 'base:half-guard',
    description: '50% of the time, damage from others to the holder is reduced by half.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        when(random.flipCoin()) empty;
        if (attacker != holder) ::<= {
          windowEvent.queueMessage(text:holder.name + ' is protected from the damage thanks to Light Guard!');
          damage.amount *= 0.5;            
        }
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Multi Guard',
    id : 'base:multi-guard',
    description: 'Multi-hit damage from others to the holder is reduced to 1.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (attacker != holder && ((damage.traits & Damage.TRAIT.MULTIHIT) != 0)) ::<= {
          windowEvent.queueMessage(text:holder.name + ' is protected from the damage thanks to Light Guard!');
          damage.amount = 1;            
        }
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Premonition',
    id : 'base:premonition',
    description: 'All incoming critical hits are reduced to 1 damage.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (attacker != holder && ((damage.traits & Damage.TRAIT.IS_CRIT) != 0)) ::<= {
          windowEvent.queueMessage(text:holder.name + ' is protected from critical hit damage thanks to Premonition!');
          damage.amount = 1;            
        }
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Crustacean Maneuver',
    id : 'base:crustacean-maneuver',
    description: 'All incoming attacks are nullified. Unable to use Ability or Reaction Arts.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.CANT_USE_ABILITIES | TRAIT.CANT_USE_REACTIONS,
    stats: StatSet.new(),
    events : {      
      onPreAttack ::(from, item, holder, attacker, damage) {
        if (attacker != holder) ::<= {
          windowEvent.queueMessage(text:holder.name + ' is protected from damage thanks to the Crustacean Maneuver!');
          damage.amount = 1;            
        }
      },

      onNextTurn ::(from, item, holder, duration) {        
      },
    }
  }
)




Effect.newEntry(
  data : {
    name : 'Lucky Charm',
    id : 'base:lucky-charm',
    description: '20% chance to avoid death once, granting 1 HP. On revival, all stacks of Lucky Charm are removed.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.REVIVAL,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (holder.hp == 0) ::<= {
     
          if (random.try(percentSuccess:20)) ::<= {
            windowEvent.queueMessage(text:holder.name + " glows!");

            @:Entity = import(module:'game_class.entity.mt');
            damage.amount = 0;
            holder.heal(amount:1);

            holder.effectStack.removeAllByID(:'base:lucky-charm');
          }        
        }
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Spirit Loan',
    id : 'base:spirit-loan',
    description: 'Avoids death, but sends a Dark blast to another ally upon revival that deals damage equivalent to the ally\'s total health. If there are no other allies, revival happens regardless.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.REVIVAL,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        when(holder.battle == empty) empty;
        if (holder.hp == 0) ::<= {
          windowEvent.queueMessage(text:holder.name + " glows!");
          holder.effectStack.removeAllByID(:'base:spirit-loan');

          @:Entity = import(module:'game_class.entity.mt');
          damage.amount = 0;
          holder.heal(amount:1);


          @forWhomItTolls = holder.battle.getAllies(:holder)->filter(::(value) <- value != holder);
          when(forWhomItTolls->size) ::<= {
            @:victim = random.pickArrayItem(:forWhomItTolls);
            victim.damage(
              attacker: holder,
              damage : Damage.new(
                amount : victim.stats.HP,
                damageType: Damage.TYPE.DARK,
                damageClass : Damage.CLASS.HP
              ),
              dodgeable : false,
              exact: true
            );
          }
        }
      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'Procrastinate Death',
    id : 'base:procrastinate-death',
    description: 'The next time the holder would die, their HP is set to 1 and this effect is removed. If this effect is never triggered prior to removal, the holder receives Dark damage equal to their total health.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.REVIVAL,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        when(holder.battle == empty) empty;
        if (holder.hp == 0) ::<= {
          windowEvent.queueMessage(text:holder.name + " glows!");
          holder.effectStack.removeAllByID(:'base:procrastinate-death');

          @:Entity = import(module:'game_class.entity.mt');
          damage.amount = 0;
          holder.heal(amount:1);
        }
      },

      onDurationEnd ::(from, item, holder, duration) {
        @:victim = holder;
        victim.damage(
          attacker: holder,
          damage : Damage.new(
            amount : victim.stats.HP,
            damageType: Damage.TYPE.DARK,
            damageClass : Damage.CLASS.HP
          ),
          dodgeable : false,
          exact: true
        );
      }
    }
  }
)






Effect.newEntry(
  data : {
    name : 'Cheat Death',
    id : 'base:cheat-death',
    description: 'Avoids death, but when avoided stuns the holder for 2 turns.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.REVIVAL,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        when(holder.battle == empty) empty;
        if (holder.hp == 0) ::<= {
          windowEvent.queueMessage(text:holder.name + " glows!");
          holder.effectStack.removeAllByID(:'base:cheat-death');

          @:Entity = import(module:'game_class.entity.mt');
          damage.amount = 0;
          holder.heal(amount:1);

          holder.addEffect(from:holder, id:'base:stunned', durationTurns:2);                        
        }
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Death Reflection',
    id : 'base:death-reflection',
    description: 'Grants a 25% chance to reflect death onto a random combatant instead of the holder.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.REVIVAL,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        when(holder.battle == empty) empty;
        if (holder.hp == 0) ::<= {
          windowEvent.queueMessage(text:holder.name + " glows!");
          holder.effectStack.removeAllByID(:'base:death-reflection');

          @:Entity = import(module:'game_class.entity.mt');
          damage.amount = 0;
          holder.heal(amount:1);
          
          @:victim = random.pickArrayItem(:holder.battle.getAll()->filter(::(value) <- value != holder));
          windowEvent.queueMessage(text:holder.name + " avoids death at the cost of " + victim.name + '\'s life!');
          victim.kill();
        }
      }
    }
  }
)



Effect.newEntry(
  data : {
    name : 'Limit Break',
    id : 'base:limit-break',
    description: 'If damage would cause the holder to get knocked out, the holder gains 50% of their HP and inflicts the Limit Reached effect.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.REVIVAL,
    stats: StatSet.new(),
    events : {      
      onKnockedOut ::(from, item, holder) {
        when(holder.battle == empty) empty;
        windowEvent.queueMessage(text:holder.name + " glows!");
        holder.effectStack.removeAllByID(:'base:limit-break');

        @:Entity = import(module:'game_class.entity.mt');
        @:Arts = import(:'game_database.arts.mt');
        holder.heal(amount:(holder.stats.HP / 2)->ceil);
        holder.addEffect(from:holder, id:'base:limit-reached', durationTurns:Arts.A_LOT);
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Limit Reached',
    id : 'base:limit-reached',
    description: 'The holder getting knocked out will also kill the holder.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {      
      onKnockedOut ::(from, item, holder) {
        when(holder.battle == empty) empty;
        windowEvent.queueMessage(text:holder.name + " has reached their limit...");
        holder.effectStack.removeAllByID(:'base:limit-reached');

        @:Entity = import(module:'game_class.entity.mt');
        holder.kill();
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Aura',
    id : 'base:aura',
    description: 'ATK,DEF,INT,SPD,DEX base +4, gains an additional block point.',
    stackable: true,
    blockPoints : 1,
    traits : 0,
    stats: StatSet.new(
      ATK:4, 
      DEF:4,
      INT:4,
      SPD:4,
      DEX:4
    ),
    events : {
    }
  }
)  



Effect.newEntry(
  data : {
    name : 'Minor Aura',
    id : 'base:minor-aura',
    description: 'ATK,DEF,INT,SPD,DEX base +1',
    stackable: true,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(
      ATK:1, 
      DEF:1,
      INT:1,
      SPD:1,
      DEX:1
    ),
    events : {
    }
  }
)  

Effect.newEntry(
  data : {
    name : 'Minor Curse',
    id : 'base:minor-curse',
    description: 'ATK,DEF,INT,SPD,DEX base -1',
    stackable: true,
    blockPoints : 0,
    traits : 0,
    stats: StatSet.new(
      ATK:-1, 
      DEF:-1,
      INT:-1,
      SPD:-1,
      DEX:-1
    ),
    events : {
    }
  }
)    
  

Effect.newEntry(
  data : {
    name : 'Shield Aura',
    id : 'base:shield-aura',
    description: 'DEF base +4, gains an additional block point, and reduces both incoming and outgoing damage by 1.',
    stackable: true,
    blockPoints : 1,
    traits : 0,
    stats: StatSet.new(
      DEF:4
    ),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        damage.amount -= 1;
        if (damage.amount < 0)
          damage.amount = 0;
        windowEvent.queueMessage(text:holder.name + "'s Shield Aura reduced damage!");
      },

      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        windowEvent.queueMessage(
          text: holder.name + '\'s Shield Aura reduced the moved effectiveness!'
        );

        damage.amount -= 1;
        if (damage.amount < 0)
          damage.amount = 0;
      }      
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Deathless Overflow',
    id : 'base:deathless-overflow',
    description: 'If damage would cause the holder to get knocked out, the holder gains 50% of their HP. Holder gain 5 Banish stacks.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF | TRAIT.REVIVAL,
    stats: StatSet.new(),
    events : {      
      onKnockedOut ::(from, item, holder) {
        when(holder.battle == empty) empty;
        windowEvent.queueMessage(text:holder.name + " glows!");
        holder.effectStack.removeAllByID(:'base:deathless-overflow');

        @:Entity = import(module:'game_class.entity.mt');
        @:Arts = import(:'game_database.arts.mt');
        holder.heal(amount:(holder.stats.HP / 2)->ceil);
        for(0, 5) ::(i) {
          holder.addEffect(from:holder, id:'base:banish', durationTurns:Arts.A_LOT);
        }
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Soul Buffer',
    id : 'base:soul-buffer',
    description: 'Prevents all non-physical damage.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType != Damage.TYPE.PHYS) ::<= { 
          windowEvent.queueMessage(text:holder.name + "'s Soul Buffer negates the damage!");
          damage.amount = 0;
        }
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Body Buffer',
    id : 'base:body-buffer',
    description: 'Prevents all physical damage.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        if (damage.damageType == Damage.TYPE.PHYS) ::<= { 
          windowEvent.queueMessage(text:holder.name + "'s Body Buffer negates the damage!");
          damage.amount = 0;
        }
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Perfect Barrier',
    id : 'base:perfect-barrier',
    description: 'Prevents all damage.',
    stackable: false,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        windowEvent.queueMessage(text:holder.name + "'s Perfect Barrier negates the damage!");
        damage.amount = 0;
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Escape',
    id : 'base:escape',
    description : 'Escape from any area or battle. Loses half of any collected Ethereal Shards.',
    stackable : false,
    blockPoints :0,
    traits : TRAIT.SPECIAL,
    stats : StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        @:world = import(module:'game_singleton.world.mt');
        if (world.battle.isActive)
          world.battle.cancel();

        when(world.party.isMember(:holder) == false)
          empty;

        @loot = random.scrambled(:world.party.inventory.loot);
        @erased = false;
        if (loot->size > 3) ::<= {
          loot = loot->subset(from:0, to:(loot->size/3)->floor);
          foreach(loot) ::(k, v) {
            world.party.inventory.remove(:v);
          }
          erased = true;
        }
        
          
        @:instance = import(:'game_singleton.instance.mt');
        instance.visitCurrentIsland(restorePos:true);
        windowEvent.queueMessage(text:'The party teleported out of the area.');
        if (erased)
          windowEvent.queueMessage(text:'The party loses some of their loot during the teleportation process');
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Access Bank',
    id : 'base:access-bank',
    description : 'Access a pocket dimension to transfer inventory to and from.',
    stackable : false,
    blockPoints :0,
    traits : TRAIT.SPECIAL,
    stats : StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        @:world = import(module:'game_singleton.world.mt');

        when(world.party.isMember(:holder) == false)
          empty;
          

        @:pickItem = import(:'game_function.pickitem.mt');
      
        @:xferItems = ::(from, to, moveToName) {
          pickItem(
            tabbed: true,
            inventory:from,
            leftWeight: 0.5,
            topWeight: 0.5,
            canCancel:true, 
            pageAfter:12,
            showRarity:true,
            header : ['Item', 'Value', ''],
            onPick::(item) {
              @:choiceItem = item;
              when(choiceItem == empty) empty;
              windowEvent.queueChoices(
                leftWeight: 0.5,
                topWeight: 0.5,
                prompt: choiceItem.name,
                canCancel : true,
                keep:true,
                jumpTag : 'BANKING-ITEM',
                choices: [
                  'Check',
                  'Move to ' + moveToName
                ],
                onChoice::(choice) {
                  when (choice == 0) empty;        
                  when (choice == 1) choiceItem.describe();
                  when (choice == 2) ::<= {
                    from.remove(:choiceItem);
                    to.add(:choiceItem);
                    windowEvent.jumpToTag(name: 'BANKING-ITEM', goBeforeTag: true);
                  }
                }
              );
            }
          );         
        }
      
        @:bankedItems = ::{
          @:inv = world.party.bank;
          when(inv.isEmpty) ::<= {
            windowEvent.queueMessage(
              speaker: 'The banker?',
              text: '"What\'s the big idea? You don\'t got anything in storage right now!"'
            );
          }

          windowEvent.queueMessage(
            speaker: 'The banker?',
            text: '"Here\'s what you got in storage. Ahem..."'
          );
          
          xferItems(
            from:world.party.bank,
            to:  world.party.inventory,
            moveToName : 'Inventory'
          );
  
        }

        @:inventoryItems = ::{
          @:inv = world.party.inventory;
          when(inv.isEmpty) ::<= {
            windowEvent.queueMessage(
              speaker: 'The banker?',
              text: '"This a joke? You don\'t got anything on you right now!"'
            );
          }
          
          xferItems(
            from:world.party.inventory,
            to:  world.party.bank,
            moveToName : 'Bank Storage'
          )
        }

          
        @:bankedGold ::{
          @:inv = world.party.bank;
          when(inv.gold == 0) 
            windowEvent.queueMessage(
              speaker: 'The banker?',
              text: '"This a joke? You don\'t got any money in the Bank!"'
            );

          @:num = import(:'game_function.number.mt');
          num(
            canCancel : true,
            onDone::(value) {
              when (value > inv.gold)
                windowEvent.queueMessage(
                  speaker: 'The banker?',
                  text: '"Huh? Real funny... But we know you don\'t have that much in the Bank."'
                );

              @amount = value;
              inv.subtractGold(:amount);
              world.party.inventory.addGold(:amount);
            },
            prompt: 'Take how much? Current: ' + g(:inv.gold)
          );
        }

        @:inventoryGold ::{
          @:inv = world.party.inventory;
          when(inv.gold == 0) 
            windowEvent.queueMessage(
              speaker: 'The banker?',
              text: '"This a joke? You don\'t got any gold on you!"'
            );

          @:num = import(:'game_function.number.mt');
          num(
            canCancel : true,
            onDone::(value) {
              when (value > inv.gold)
                windowEvent.queueMessage(
                  speaker: 'The banker?',
                  text: '"Huh? Real funny... But we both know you don\'t have that on you."'
                );

              @amount = value;
              inv.subtractGold(:amount);
              world.party.bank.addGold(:amount);
            },
            prompt: 'Put in how much? Current: ' + g(:inv.gold)
          );
        }


      
        windowEvent.queueNestedResolve(
          onEnter ::{
            windowEvent.queueMessage(
              text: 'The stone raises up in the air before flashing in a bright light.'
            );

            windowEvent.queueMessage(
              text: 'What seems to be a particularly short Kobold appears from the flash.'
            );

            // their name is Vasho. Not sure if there's gonna be a chance to learn their name 
            // yet. maybe in a future side-story quest?
            windowEvent.queueMessage(
              speaker: 'The banker?',
              text: '"Yeah, hey, how you doin\'. Whaddya want?"'
            );

            windowEvent.queueChoices(
              prompt: 'Banking...',
              jumpTag : 'BANKING',
              keep : true,
              choices : [
                'Take from Bank...',
                'Put in Bank...',
                'Done'
              ],
              canCancel : false,
              
              onChoice::(choice) {
                when(choice == 3)
                  windowEvent.queueAskBoolean(
                    prompt: 'Done banking?',
                    onChoice::(which) {
                      when(which == true) ::<= {
                        windowEvent.queueMessage(
                          speaker: 'Banker?',
                          text: '"Yeah, yeah. Pleasure doin\' business with ya. Later."'
                        );

                        windowEvent.queueMessage(
                          text: 'The Kobold disappears in a flash.'
                        );

                        windowEvent.jumpToTag(name: 'BANKING', goBeforeTag:true);
                      }
                    }
                  );              
              
                @takeFromBank = choice == 1;
                windowEvent.queueChoices(
                  prompt : if (takeFromBank)
                    'Take from Bank...'
                   else 
                    'Put in Bank...',
                  choices : [
                    'Items',
                    'Gold'
                  ],
                  canCancel: true,
                  keep : true,
                  onChoice::(choice) {
                    when(choice == 1)
                      if (takeFromBank)
                        bankedItems()
                      else 
                        inventoryItems()
                        
                      if (takeFromBank)
                        bankedGold()
                      else 
                        inventoryGold()
                    
                    
                  }
                );
              }
            );
          }
        );
      }
    }
  }
);







Effect.newEntry(
  data : {
    name : 'Soul Guard',
    id : 'base:soul-guard',
    description: '1/4th chance that the caster nullifies damage done to the holder if the caster is conscious. Upon successful blocking, has a 1/4th chance to cause Paralysis indefinitely.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        when (from.isIncapacitated()) empty;
        when (attacker == empty) empty;
    
        when(random.try(percentSuccess:75)) empty;
        damage.amount = 0;
        windowEvent.queueMessage(text:holder.name + "'s Soul Guard negates the damage!");
        @:Arts = import(:'game_database.arts.mt');

        when(random.try(percentSuccess:75)) empty;
        attacker.addEffect(from, id:'base:paralyzed',durationTurns:Arts.A_LOT);
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Soul Split',
    id : 'base:soul-split',
    description: 'Redistributes incoming damage between the holder and caster evenly.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        windowEvent.queueMessage(text:holder.name + "'s Soul Split splits damage!");


        damage.amount *= 0.5;

        from.damage(attacker:attacker, damage:Damage.new(
          amount : damage.amount,
          damageType:damage.damageType,
          damageClass:damage.damageClass
        ),dodgeable: false);          
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Soul Projection',
    id : 'base:soul-projection',
    description: 'Original caster receives damage instead of the holder. If the holder is the caster, nothing happens.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {      
      onPreDamage ::(from, item, holder, attacker, damage) {
        when(holder == from) empty;

        windowEvent.queueMessage(text:holder.name + "'s Soul Projection redirects damage!");
        from.damage(attacker:attacker, damage:Damage.new(
          amount : damage.amount,
          damageType:damage.damageType,
          damageClass:damage.damageClass
        ),dodgeable: false);          
        damage.amount = 0;

      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Concentrating',
    id : 'base:concentrating',
    description: 'Unable to use Ability or Reaction Arts. Unable to block.',
    stackable: false,
    blockPoints : -3,
    traits : TRAIT.DEBUFF | TRAIT.CANT_USE_ABILITIES | TRAIT.CANT_USE_REACTIONS,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
      }
    }
  }
)    

Effect.newEntry(
  data : {
    name : 'Charmed',
    id : 'base:charmed',
    description: 'Attacks from the holder that target the original caster is reduced by 50%',
    stackable: true,
    blockPoints : -3,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        when (to != from) empty;
      
        windowEvent.queueMessage(
          text: holder.name + '\'s attack was halved due to being Charmed!'
        );
        damage.amount *= 0.5;
      }
    }
  }
)    


Effect.newEntry(
  data : {
    name : 'Static Shield',
    id : 'base:static-shield',
    description: 'Incoming lightning damage is reduced by 75%. Incoming attacks deal 1 - 4 lighting damage to the attacker.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttacked ::(from, item, holder, to, damage) {
        if (damage.damageType == Damage.TYPE.THUNDER) ::<= {
          windowEvent.queueMessage(
            text: 'Incoming thunder damage was reduced!'
          );
          damage.amount *= 0.25;
        }
      },
      
      onPostAttacked ::(attacker, holder, item, damage) {
        windowEvent.queueMessage(
          text: holder.name + '\'s Static Shield causes damage to ' + attacker.name + '!'
        );
        
        attacker.damage(attacker:holder, damage:Damage.new(
          amount : random.integer(from:1, to:4),
          damageType:Damage.TYPE.THUNDER,
          damageClass:Damage.CLASS.HP
        ),dodgeable: false, exact:true);
      }
    }
  }
)    

Effect.newEntry(
  data : {
    name : 'Scorching Shield',
    id : 'base:scorching-shield',
    description: 'Incoming fire damage is reduced by 75%. Incoming attacks deal 1 - 4 fire damage to the attacker.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttacked ::(from, item, holder, to, damage) {
        if (damage.damageType == Damage.TYPE.FIRE) ::<= {
          windowEvent.queueMessage(
            text: 'Incoming fire damage was reduced!'
          );
          damage.amount *= 0.25;
        }
      },
      
      onPostAttacked ::(attacker, holder, item, damage) {
        windowEvent.queueMessage(
          text: holder.name + '\'s Scorching Shield causes damage to ' + attacker.name + '!'
        );
        
        attacker.damage(attacker:holder, damage:Damage.new(
          amount : random.integer(from:1, to:4),
          damageType:Damage.TYPE.FIRE,
          damageClass:Damage.CLASS.HP
        ),dodgeable: false, exact:true);
      }
    }
  }
)    

Effect.newEntry(
  data : {
    name : 'Freezing Shield',
    id : 'base:freezing-shield',
    description: 'Incoming ice damage is reduced by 75%. Incoming attacks deal 1 - 4 ice damage to the attacker.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttacked ::(from, item, holder, to, damage) {
        if (damage.damageType == Damage.TYPE.ICE) ::<= {
          windowEvent.queueMessage(
            text: 'Incoming ice damage was reduced!'
          );
          damage.amount *= 0.25;
        }
      },
      
      onPostAttacked ::(attacker, holder, item, damage) {
        windowEvent.queueMessage(
          text: holder.name + '\'s Freezing Shield causes damage to ' + attacker.name + '!'
        );
        
        attacker.damage(attacker:holder, damage:Damage.new(
          amount : random.integer(from:1, to:4),
          damageType:Damage.TYPE.ICE,
          damageClass:Damage.CLASS.HP
        ),dodgeable: false, exact:true);
      }
    }
  }
)    



::<= {

@:explode::(holder) {
  windowEvent.queueMessage(
    text: holder.name + '\'s Acid Dust explodes!'
  );
  holder.removeEffectInstance(:
    (holder.effectStack.getAll()->filter(::(value) <- value.id == 'base:acid-dust'))[0]
  )

  
  @targets = [holder];
  if (holder.battle)
    targets = holder.battle.getAllies(:holder);
  
  foreach(targets) ::(k, v) {      
    v.damage(attacker:holder, damage:Damage.new(
      amount : random.integer(from:4, to:6),
      damageType:Damage.TYPE.FIRE,
      damageClass:Damage.CLASS.HP
    ),dodgeable: false, exact:true);
  }
}

Effect.newEntry(
  data : {
    name : 'Acid Dust',
    id : 'base:acid-dust',
    description: 'Upon recieving fire-based damage or receiving the Burning effect, the holder and any allies take 4 - 6 fire damage.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
    
      onPostAddEffect::(holder, from, item, effectData) {
        when(effectData.id != 'base:burning') empty;
        explode(holder);
      },
         
      onPostDamage ::(attacker, holder, item, damage) {
        when(damage.damageType != Damage.TYPE.FIRE) empty;
        explode(holder);
      }
    }
  }
)    
}





::<= {

@:explode::(holder) {
  windowEvent.queueMessage(
    text: holder.name + '\'s Conduction Dust explodes!'
  );
  holder.removeEffectInstance(:
    (holder.effectStack.getAll()->filter(::(value) <- value.id == 'base:conduction-dust'))[0]
  )

  
  @targets = [holder];
  if (holder.battle)
    targets = holder.battle.getAllies(:holder);
  
  foreach(targets) ::(k, v) {      
    v.damage(attacker:holder, damage:Damage.new(
      amount : random.integer(from:4, to:6),
      damageType:Damage.TYPE.THUNDER,
      damageClass:Damage.CLASS.HP
    ),dodgeable: false, exact:true);
  }
}

Effect.newEntry(
  data : {
    name : 'Conduction Dust',
    id : 'base:conduction-dust',
    description: 'Upon recieving thunder-based damage or receiving the Shock effect, the holder and any allies take 4 - 6 thunder damage.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
    
      onPostAddEffect::(holder, from, item, effectData) {
        when(effectData.id != 'base:shock') empty;
        explode(holder);
      },
         
      onPostDamage ::(attacker, holder, item, damage) {
        when(damage.damageType != Damage.TYPE.THUNDER) empty;
        explode(holder);
      }
    }
  }
)    
}


::<= {

@:explode::(holder) {
  windowEvent.queueMessage(
    text: holder.name + '\'s Conduction Dust explodes!'
  );
  holder.removeEffectInstance(:
    (holder.effectStack.getAll()->filter(::(value) <- value.id == 'base:conduction-dust'))[0]
  )

  
  @targets = [holder];
  if (holder.battle)
    targets = holder.battle.getAllies(:holder);
  
  foreach(targets) ::(k, v) {      
    v.damage(attacker:holder, damage:Damage.new(
      amount : random.integer(from:4, to:6),
      damageType:Damage.TYPE.THUNDER,
      damageClass:Damage.CLASS.HP
    ),dodgeable: false, exact:true);
  }
}

Effect.newEntry(
  data : {
    name : 'Conduction Dust',
    id : 'base:conduction-dust',
    description: 'Upon recieving thunder-based damage or receiving the Shock effect, the holder and any allies take 4 - 6 thunder damage.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
    
      onPostAddEffect::(holder, from, item, effectData) {
        when(effectData.id != 'base:shock') empty;
        explode(holder);
      },
         
      onPostDamage ::(attacker, holder, item, damage) {
        when(damage.damageType != Damage.TYPE.THUNDER) empty;
        explode(holder);
      }
    }
  }
)    
}

::<= {

@:explode::(holder) {
  windowEvent.queueMessage(
    text: holder.name + '\'s Conduction Dust explodes!'
  );
  holder.removeEffectInstance(:
    (holder.effectStack.getAll()->filter(::(value) <- value.id == 'base:conduction-dust'))[0]
  )

  
  @targets = [holder];
  if (holder.battle)
    targets = holder.battle.getAllies(:holder);
  
  foreach(targets) ::(k, v) {      
    v.damage(attacker:holder, damage:Damage.new(
      amount : random.integer(from:4, to:6),
      damageType:Damage.TYPE.THUNDER,
      damageClass:Damage.CLASS.HP
    ),dodgeable: false, exact:true);
  }
}

Effect.newEntry(
  data : {
    name : 'Crystalized Dust',
    id : 'base:crystalized-dust',
    description: 'Upon recieving ice-based damage or receiving the Icy effect, the holder and any allies take 4 - 6 ice damage.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
    
      onPostAddEffect::(holder, from, item, effectData) {
        when(effectData.id != 'base:icy') empty;
        explode(holder);
      },
         
      onPostDamage ::(attacker, holder, item, damage) {
        when(damage.damageType != Damage.TYPE.ICE) empty;
        explode(holder);
      }
    }
  }
)    



}


Effect.newEntry(
  data : {
    name : 'Embarrassed',
    id : 'base:embarrassed',
    description: 'When the holder attacks the original caster, 50% chance to miss.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        when(from != to) empty;
        when(random.coinFlip()) empty;
        windowEvent.queueMessage(
          text: holder.name + '\'s embarrassment caused the attack to miss!'
        );

        damage.amount *= 0;
      }
    }
  }
)  



Effect.newEntry(
  data : {
    name : 'Enraged',
    id : 'base:enraged',
    description: 'When the holder attacks the original caster, 33% of damage is inflicted to the holder as well.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        when(from != to) empty;
        windowEvent.queueMessage(
          text: holder.name + '\'s Enraged caused recoil damage!'
        );

        holder.damage(attacker:holder, damage:Damage.new(
          amount : (damage.amount * 0.33)->ceil,
          damageType:damage.damageType,
          damageClass:damage.damageClass
        ),dodgeable: false, exact:true);          


      }
    }
  }
)    


Effect.newEntry(
  data : {
    name : 'Berserk',
    id : 'base:berserk',
    description: 'Unable to use Effect and Reaction Arts.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF | TRAIT.CANT_USE_EFFECTS | TRAIT.CANT_USE_REACTIONS,
    stats: StatSet.new(),
    events : {
    }
  }
) 



Effect.newEntry(
  data : {
    name : 'Self-Illusion',
    id : 'base:self-illusion',
    description: 'When the holder attacks the original caster, it is inflicted on their self instead.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.DEBUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        when(from != to) empty;
        when(holder.isIncapacitated()) empty;
        windowEvent.queueMessage(
          text: holder.name + '\'s Self-Illusion made the attack directed back!'
        );
        
        holder.attack(
          target:holder,
          damage: Damage.new(
            amount: damage.amount,
            damageType : damage.damageType,
            damageClass: damage.damageClass
          )
        );
        
        damage.amount = 0;              
      }
    }
  }
)    


Effect.newEntry(
  data : {
    name : '@b305',
    id : 'base:b305',
    description: 'Adds one additional block point. Any damage taken is increased by 1.',
    stackable: true,
    blockPoints : 1,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
        when(damage.amount == 0) empty;
        damage.amount += 1;
        windowEvent.queueMessage(
          text: holder.name + '\'s b305 increased the damage received!'
        );
        
      }
    }
  }
)  

Effect.newEntry(
  data : {
    name : '@b307',
    id : 'base:b307',
    description: 'Successful blocks add a stack of Empowered to the holder for 3 turns.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onSuccessfulBlock ::(from, item, holder, attacker, damage) {
        holder.addEffect(from:holder, id:'base:empowered', durationTurns:3);
      }
    }
  }
)    
  
Effect.newEntry(
  data : {
    name : 'Empowered',
    id : 'base:empowered',
    description: 'Next attack from the holder is 1.5x more damaging. This effect is removed after.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        windowEvent.queueMessage(text: holder.name + '\'s Empowered increased damage by 1.5 times!');
        damage.amount = (damage.amount*1.5)->ceil;
        holder.removeEffectInstance(:
          holder.effectStack.getAll()->filter(::(value) <- value.id == 'base:empowered')[0]
        )
      }
    }
  }
)    

Effect.newEntry(
  data : {
    name : '@b308',
    id : 'base:b308',
    description: 'Successful blocks inflicts the Stunned effect on the attacker for 1 turn.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onSuccessfulBlock ::(from, item, holder, attacker, damage) {
        windowEvent.queueMessage(text: holder.name + '\'s successful block stunned the attacker!');
        holder.addEffect(from:holder, id:'base:stunned', durationTurns:1);
      }
    }
  }
)    

Effect.newEntry(
  data : {
    name : '@b309',
    id : 'base:b309',
    description: 'Successful blocks have a 10% chance of unequipping a the weapon of the attacker. Else, add a stack of Bleeding to the attacker for 3 turns.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onSuccessfulBlock ::(from, item, holder, attacker, damage) {
        windowEvent.queueMessage(text: holder.name + '\'s successful block activated b309!');
        @:world = import(module:'game_singleton.world.mt');
        @:Entity = import(module:'game_class.entity.mt');           

        @:equipped = attacker.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR); 
        
        if (random.try(percentSuccess:10) && equipped.name != 'None') ::<= {
          windowEvent.queueCustom(
            onEnter :: {
              attacker.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
              if (world.party.isMember(entity:attacker))
                world.party.inventory.add(item:equipped);
            }
          )
          windowEvent.queueMessage(text:attacker.name + ' lost grip of their ' + equipped.name + '!');
        } else ::<= {
          attacker.addEffect(from:holder, id:'base:bleeding', durationTurns:3);        
        }

      }
    }
  }
)    


Effect.newEntry(
  data : {
    name : 'Corrupted Punishment',
    id : 'base:corrupted-punishment',
    description: 'Attacks against a target are 1.3x more effective for each stack of Banish they have.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        @:banishCount = to.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size;
        when(banishCount == 0) empty;
        windowEvent.queueMessage(
          text: holder.name + '\'s attack interracts with ' + to.name +'\'s Banish stacks!'
        );

        damage.amount *= 1.3 * banishCount;
      }
    }
  }
)   


Effect.newEntry(
  data : {
    name : 'Corrupted Empowerment',
    id : 'base:corrupted-empowerment',
    description: 'Attacks against a target are 1.3x more effective for each stack of Banish the holder has.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage, overrideTarget) {
        @:banishCount = holder.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size;
        when(banishCount == 0) empty;
        windowEvent.queueMessage(
          text: holder.name + '\'s attack interracts with their Banish stacks!'
        );

        damage.amount *= 1.3 * banishCount;
      }
    }
  }
)   


Effect.newEntry(
  data : {
    name : 'Corrupted Radioactivity',
    id : 'base:corrupted-radioactivity',
    description: 'At the start of the holder\'s turn, an enemy is struck with an INT-based Fire attack to a random enemy based on the number of Banish stacks.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        @:banishCount = holder.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size;
        when(banishCount == 0) empty;
        @:target = holder.battle.getEnemies(:holder);
        when(target == empty) empty;
        @:Entity = import(module:'game_class.entity.mt');


        windowEvent.queueMessage(
          text: holder.name + '\'s Banish stacks create an attack!'
        );


        holder.attack(
          target,
          targetDefendPart:-1,
          targetPart: Entity.DAMAGE_TARGET.BODY,
          damage: Damage.new(
            amount:holder.stats.INT * (1.2) * (1 + (banishCount-1)*0.15),
            damageType : Damage.TYPE.FIRE,
            damageClass: Damage.CLASS.HP
          )
        );
      }
    }
  }
)  

Effect.newEntry(
  data : {
    name : 'Corrupted Inspiration',
    id : 'base:corrupted-inspiration',
    description: 'At the start of the holder\'s turn, if the holder has a Banish stack, remove the Banish stack and grant Minor Aura to all allies for the duration of the battle.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        @:banishCount = holder.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size;
        when(banishCount == 0) empty;
        @:allies = holder.battle.getAllies(:holder);

        windowEvent.queueMessage(
          text: holder.name + ' channels a Banish stack into an aura!'
        );

        holder.effectStack.removeFirstEffectByFilter(::(value) <- value.id == 'base:banish');
        @:Arts = import(:'game_database.arts.mt');
        foreach(allies) ::(k, v) {
          v.addEffect(from:holder, id: 'base:minor-aura', durationTurns: Arts.A_LOT);
        }

      }
    }
  }
)  


Effect.newEntry(
  data : {
    name : 'Corrupted Corruption',
    id : 'base:corrupted-corruption',
    description: 'At the start of the holder\'s turn, if the holder has a Banish stack, remove the Banish stack and grant Minor Curse to all allies for the duration of the battle.',
    stackable: true,
    blockPoints : 0,
    traits : TRAIT.BUFF,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        @:banishCount = holder.effectStack.getAllByFilter(::(value) <- value.id == 'base:banish')->size;
        when(banishCount == 0) empty;
        @:enemies = holder.battle.getEnemies(:holder);
        when(enemies->size == 0) empty;
        
        windowEvent.queueMessage(
          text: holder.name + ' channels a Banish stack into a curse!'
        );

        holder.effectStack.removeFirstEffectByFilter(::(value) <- value.id == 'base:banish');
        @:Arts = import(:'game_database.arts.mt');
        foreach(enemies) ::(k, v) {
          v.addEffect(from:holder, id: 'base:minor-curse', durationTurns: Arts.A_LOT);
        }

      }
    }
  }
)  



}

@:Effect = Database.new(
  name: "Wyvern.Effect",
  statics : {
    TRAIT : {
      get ::<- TRAIT
    },
    
    TRAITS_TO_DOMINANT_SYMBOL ::(flag) {
      when(flag & TRAIT.SPECIAL) '?';
      when(flag & TRAIT.AILMENT) '!';
      when(flag & TRAIT.BUFF)    '+';
      when(flag & TRAIT.DEBUFF)  '-';
      return '?'
    }
  },
  attributes : {
    name : String,
    id : String,
    description : String,
    stats : StatSet.type,
    traits : Number,
    blockPoints : Number,
    events : Object,
    stackable : Boolean // whether multiple of the same effect can coexist
  },
  reset
);

return Effect;
