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
  AILMENT : 1,
  BUFF : 2,
  DEBUFF : 4,
  SPECIAL : 8
};


  ////////////////////// SPECIAL EFFECTS
@:reset :: {

@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Scene = import(module:'game_database.scene.mt');
@:random = import(module:'game_singleton.random.mt');
@:g = import(module:'game_function.g.mt');
@:EffectStack = import(:'game_class.effectstack.mt');


  
  
  
  //////////////////////



Effect.newEntry(
  data : {
    name : 'Defend',
    id: 'base:defend',
    description: 'Adds an additional block point. Reduces damage by 40%. When first getting this effect and HP is below 50%, gain 10% HP back.',
    battleOnly : true,
    stackable: false,
    blockPoints : 1,
    flags : FLAGS.BUFF,
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
    description: '+50% DEF and grants an additional block point.',
    battleOnly : true,
    stackable: false,
    blockPoints : 1,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF: 50
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
    battleOnly : true,
    stackable : true,
    blockPoints: 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(
          text: holder.name + ' is primed for more damage!'
        );
      },

      onPreAttackOther ::(from, item, holder, to, damage) {
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
    battleOnly : true,
    stackable : false,
    blockPoints: 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage) {
        windowEvent.queueMessage(
          text: holder.name + '\'s attack bypassed ' + to.name +'\'s DEF!'
        );

        damage.forceDEFbypass = true;
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
    battleOnly : true,
    stackable : true,
    blockPoints: 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage) {
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
    name : 'Mirrored',
    id : 'base:mirrored',
    description: 'Attacks by the holder now damage a random enemy for the same damage amount.',
    battleOnly : true,
    stackable : true,
    blockPoints: 0,
    flags : FLAGS.BUFF,
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
    description: 'Next attack received is translated instead to Banish stacks. The count is equivalent to 1/3rd the damage, rounded up. When an attack is translated in this way, the holder loses a stack of Banishing Light.',
    battleOnly : true,
    stackable : true,
    blockPoints: 0,
    flags : FLAGS.DEBUFF,
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

        for(0, (damage.amount/3)->ceil) ::(i) {
          holder.addEffect(from, id:'base:banish', durationTurns:10000);      
        }
        damage.amount = 0;
        holder.removeEffectInstance(:
          (holder.effectStack.getAll()->filter(::(value) <- value.id == 'base:banishing-light'))[0]
        )
        breakpoint();
      }
    }
  }
);


Effect.newEntry(
  data : {
    name : 'Agile',
    id: 'base:agile',
    description: '+20% DEX. The holder may now dodge attacks. If the holder has more DEX than the attacker, the chance of dodging increases if the holder\'s DEX is greater than the attacker\'s.',
    battleOnly : true,
    stackable: true,
    blockPoints : 1,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEX: 20
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
    battleOnly : true,
    stackable: false,
    blockPoints : 1,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
    ),
    events : {
      onPreDamage ::(from, item, holder, attacker, damage) {
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
    description: 'ATK -50%, DEF +200%, gains an additional block point.',
    battleOnly : true,
    stackable: false,
    blockPoints : 1,
    flags : 0,
    stats: StatSet.new(ATK:-50, DEF:200),
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
    description: 'DEF -50%, ATK +200%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
    stats: StatSet.new(DEF:-50, ATK:200),
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
    description: 'ATK -50%, SPD +100%, DEX +100%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
    stats: StatSet.new(ATK:-50, SPD:100, DEX:100),
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
    description: 'SPD -50%, DEF +200%, additional block point.',
    battleOnly : true,
    stackable: false,
    blockPoints : 1,
    flags : 0,
    stats: StatSet.new(SPD:-50, DEF:200),
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
    description: 'ATK -50%, INT +200%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
    stats: StatSet.new(ATK:-50, INT:200),
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
    description: 'SPD -30%, DEF -30%, ATK +200%, DEX +100%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
    stats: StatSet.new(SPD:-30, DEF:-30, ATK:200, DEX:100),
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
    battleOnly : true,
    stackable: false,
    stats: StatSet.new(),
    blockPoints : 0,
    flags : 0,
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
    description: 'Negates incoming attacks and redirects a portion of the would-be damage back at the attacker. The holder is unable to act while this is active.',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' is busy concentrating on countering enemy attacks!');
        return false;
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:from.name + " snuck behind " + holder.name + '!');
      
      },
      onPreDamage ::(from, item, holder, attacker, damage) {
        breakpoint();
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
    description: 'INT +100%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      INT: 100
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
    description: 'DEF +100%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF: 100
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
    description: 'DEF +10%, 30% chance to block',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF: 10
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
    name : 'Trigger Item Art',
    id : 'base:trigger-itemart',
    description: 'Casts an Art from an item.',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    description: 'Heals 2 HP.',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
    stats: StatSet.new(
    ),
    events : {
      onAffliction ::(from, item, holder) {
        when(holder.hp == 0) empty;
        windowEvent.queueMessage(text:holder.name + '\'s ' + item.name + ' glows with power!');
        holder.heal(
          amount: 2
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    description: 'DEF +10%, light damage when attacked.',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF: 10
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    description: 'ATK +70%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      ATK:70
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
    description: 'ATK +70%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      ATK:25
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    description: 'DEF +70%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF:70
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
    description: 'DEF +25%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF:25
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    description: 'INT +70%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      INT:70
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
    description: 'INT +25%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      INT:70
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    description: 'DEX +70%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEX:70
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
    description: 'DEX +25%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
    stats: StatSet.new(DEX:25),
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    description: 'SPD +70%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      SPD:70
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
    description: 'SPD +70%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      SPD:25
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
    description: 'DEF +50%.',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF: 50
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
    description: 'DEF +50%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF: 50
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
    description: 'ATK +40%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      ATK: 40
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
    description: 'Skips turn and, instead, attacks a random enemy. ATK,DEF +70%.',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF: 70,
      ATK: 70
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
    description: 'ATK +100%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      ATK: 100
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
    description: 'DEF +100%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF: 100
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
    description: 'DEF +100%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF: 100
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : 0,
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
    name : 'Break Item',
    id : 'base:break-item',
    description: 'The item is destroyed in the process of misuse or strain',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : 0,
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
    name : 'HP Recovery: All',
    id : 'base:hp-recovery-all',
    description: 'Heals 100% of HP.',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    name : 'AP Recovery: All',
    id : 'base:ap-recovery-all',
    description: 'Heals 100% of AP.',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    name : 'Treasure I',
    id : 'base:treasure-1',
    description: 'Opening gives a fair number of G.',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
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
    description: 'ATK +30%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(ATK:30),
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
    description: 'ATK +30%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(ATK:30),
    events : {
    
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Cheered',
    id : 'base:cheered',
    description: 'ATK +70%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(ATK:70),
    events : {}
  }
)       

Effect.newEntry(
  data : {
    name : 'Poisonroot Growing',
    id : 'base:poisonroot-growing',
    description: 'Vines grow on holder. SPD -10%.',
    battleOnly : true,
    stackable: true,        
    stats: StatSet.new(SPD:-10),
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
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
    description: 'Every turn, holder takes 1 to 4 poison damage. SPD -10%',
    battleOnly : true,
    stackable: true,
    stats: StatSet.new(SPD:-10),
    blockPoints : 0,
    flags : FLAGS.DEBUFF,

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
    description: 'Vines grow on holder. SPD -10%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
    stats: StatSet.new(SPD:-10),
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
    description: 'Every turn 40% chance to trip the holder, cancelling their turn. SPD -10%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
    stats: StatSet.new(SPD:-10),
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
    description: 'Vines grow on holder. SPD -10%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : 0,
    stats: StatSet.new(SPD:-10),
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
    description: 'Every turn heals the holder by 2 HP. SPD -10%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(SPD:-10),
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
    battleOnly : false,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
            (value.traits & Arts.TRAITS.SUPPORT) != 0 &&
            ((value.traits & Arts.TRAITS.SPECIAL) == 0) &&
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
    battleOnly : false,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
            (value.traits & Arts.TRAITS.SUPPORT) != 0 &&
            ((value.traits & Arts.TRAITS.SPECIAL) == 0) &&
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    description: 'The holder is unable to act.',
    battleOnly : true,
    stackable: false,
    stats: StatSet.new(),
    blockPoints : 0,
    flags : 0,
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
    description: 'The holder is not properly balanced. ATK -90%.',
    battleOnly : true,
    stackable: false,
    stats: StatSet.new(
      ATK: -90
    ),
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: false,
    stats: StatSet.new(
    ),
    blockPoints : 0,
    flags : Effect.FLAGS.DEBUFF,
    events : {
      onPreAttackOther ::(from, item, holder, to, damage) {
        if (damage.isMultihit) ::<= {
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
    id : 'base:dampen-multi-hit',
    description: 'All multi-hit attack damage targetting the holder are nullified.',
    battleOnly : true,
    stackable: false,
    stats: StatSet.new(
    ),
    blockPoints : 0,
    flags : Effect.FLAGS.BUFF,
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
    description: 'The holder is is desparate. HP -50%, DEF -100%. Attacks to others are 2.5 times more damaging.',
    battleOnly : true,
    stackable: false,
    stats: StatSet.new(
      DEF: -100,
      HP: -50
    ),
    blockPoints : 0,
    flags : 0,
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' became desparate!');
      },
      
      onPreAttackOther ::(from, item, holder, to, damage) {
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
    description: 'The holder is is magically enlarged. HP +50%, DEF +50%',
    battleOnly : true,
    stackable: false,
    stats: StatSet.new(
      DEF: 50,
      HP: 50
    ),
    blockPoints : 0,
    flags : 0,
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
    description: 'Unable to act. Unable to block.',
    battleOnly : true,
    stackable: false,
    blockPoints : -3,
    stats: StatSet.new(),
    flags : FLAGS.DEBUFF,
    events : {
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + ' broke free from the grapple!')
      },
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' is being grappled and is unable to move!');
        return false;
      }
    }
  }
)   

Effect.newEntry(
  data : {
    name : 'Ensnared',
    id : 'base:ensnared',
    description: 'Unable to act. Unable to block.',
    battleOnly : true,
    stackable: false,
    blockPoints : -3,
    flags : FLAGS.DEBUFF,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' is ensnared and is unable to move!');
        return false;
      }
    }
  }
)  

Effect.newEntry(
  data : {
    name : 'Grappling',
    id : 'base:grappling',
    description: 'Unable to act. Unable to block.',
    battleOnly : true,
    stackable: false,
    blockPoints : -3,
    flags : 0,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' is in the middle of grappling and cannot move!');
        return false;
      }
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Ensnaring',
    id : 'base:ensnaring',
    description: 'Unable to act. Unable to block.',
    battleOnly : true,
    stackable: false,
    blockPoints : -3,
    flags : 0,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' is busy keeping someone ensared and cannot move!');
        return false;
      }
    }
  }
)            

    

Effect.newEntry(
  data : {
    name : 'Bribed',
    id : 'base:bribed',
    description: 'Unable to act.',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : 0,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' was bribed and can no longer act!');
        return false;
      }
    }
  }
)
Effect.newEntry(
  data : {
    name : 'Stunned',
    id : 'base:stunned',
    description: 'Unable to act. Unable to block.',
    battleOnly : true,
    stackable: false,
    blockPoints : -3,
    flags : FLAGS.DEBUFF,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' is still stunned!');
        return false;
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
    description: 'ATK +20%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      ATK: 20
    ),
    events : {
    }
  }
)

Effect.newEntry(
  data : {
    name : 'Weaken Armor',
    id : 'base:weaken-armor',
    description: 'DEF -20%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
    stats: StatSet.new(
      DEF: -20
    ),
    events : {}
  }
)    

Effect.newEntry(
  data : {
    name : 'Dull Weapon',
    id : 'base:dull-weapon',
    description: 'ATK -20%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
    stats: StatSet.new(
      ATK: -20
    ),
    events : {}
  }
)

Effect.newEntry(
  data : {
    name : 'Strengthen Armor',
    id : 'base:strengthen-armor',
    description: 'DEF +20%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF: 20
    ),
    events : {}
  }
)  


Effect.newEntry(
  data : {
    name : 'Lunar Affinity',
    id : 'base:lunar-affinity',
    description: 'INT,DEF,ATK +40% if night time.',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
          stats.modRate(stats:StatSet.new(INT:40, DEF:40, ATK:40));
        }          
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
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      ATK:35,
      DEF:35,
      SPD:35
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
    description: 'DEF + 50%',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
        stats.modRate(stats:StatSet.new(DEF:50));
      }
    }
  }
)


Effect.newEntry(
  data : {
    name : 'Solar Affinity',
    id : 'base:solar-affinity',
    description: 'INT,DEF,ATK +40% if day time.',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
          stats.modRate(stats:StatSet.new(INT:40, DEF:40, ATK:40));
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    description: 'SPD, ATK +25% for each slain.',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    description: 'SPD, ATK +25%',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      ATK:25,
      SPD:25
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : 0,
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
    description: '-5% total HP every on holder. ATK,DEF,SPD -20%.',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.AILMENT,
    stats: StatSet.new(
      ATK: -20,
      DEF: -20,
      SPD: -20
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : 0,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:'Glowing cyan runes were imprinted on ' + holder.name + "!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:'The regeneration rune fades from ' + holder.name + '.');
      },        
      
      onNextTurn ::(from, item, holder, duration) {
        when(holder.hp == 0) empty;
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
    description: '+100% DEF',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(
      DEF: 100
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.AILMENT,
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
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.AILMENT,
    stats: StatSet.new(),
    events : {
      onAffliction ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " was blinded!");
      
      },
      
      onRemoveEffect ::(from, item, holder) {
        windowEvent.queueMessage(text:holder.name + " is no longer blind.");
      },        

      onPreAttackOther ::(from, item, holder, to, damage) {
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.AILMENT,
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
    description: 'Unable to act. Unable to block.',
    battleOnly : true,
    stackable: false,
    blockPoints : -3,
    flags : FLAGS.AILMENT,
    stats: StatSet.new(),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' is still frozen and unable to act!');
        return false;
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
    description: 'SPD,ATK -100%. The holder is unable to act or block.',
    battleOnly : true,
    stackable: false,
    blockPoints : -3,
    flags : FLAGS.AILMENT,
    stats: StatSet.new(
      SPD: -100,
      ATK: -100
    ),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' is still paralyzed and unable to act!');
        return false;
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
    description: 'SPD,DEF -100%. Unable to act, unable to block.',
    battleOnly : true,
    stackable: false,
    blockPoints : -3,
    flags : FLAGS.DEBUFF,
    stats: StatSet.new(
      SPD: -100,
      DEF: -100
    ),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' is still mesmerized and unable to act!');
        return false;
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
    description: 'Can\'t act. Unable to block.',
    battleOnly : true,
    stackable: false,
    blockPoints : -3,
    flags : FLAGS.SPECIAL,
    stats: StatSet.new(
    ),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' is still wrapped and unable to act!');
        return false;
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
    description: 'Unable to act. DEF -50%',
    battleOnly : true,
    stackable: false,
    blockPoints : -3,
    flags : FLAGS.AILMENT,
    stats: StatSet.new(
      DEF: -50
    ),
    events : {
      onNextTurn ::(from, item, holder, duration) {        
        windowEvent.queueMessage(text:holder.name + ' is still petrified and unable to act!');
        return false;
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
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
    battleOnly : true,
    stats: StatSet.new(),
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    id : 'base:frozen',
    description: 'Attacks have 10% chance to inflict Frozen for 2 turns.',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    description: '-15% ATK, -15% SPD. At 10 stacks, the holder is removed from battle.',
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
    stats: StatSet.new(
      ATK: -15,
      SPD: -15
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
    name : 'Redirect Momentum',
    id : 'base:redirect-momentum',
    description: 'If the holder is to be afflicted with Grappled, instead the holder inflicts 1/3 of the source\'s DEF in damage to the source of the Grappled effect and Stuns them for a turn.',
    battleOnly : true,
    stackable: false,
    blockPoints : 0,
    flags : FLAGS.BUFF,
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(),
    events : {
      onPreAttackOther ::(from, item, holder, to, damage) {
        @:id = match(damage.type) {
          (Damage.TYPE.FIRE) : 'base:burning',
          (Damage.TYPE.ICE) : 'base:icy',
          (Damage.TYPE.THUNDER) : 'base:shock',
          (Damage.TYPE.LIGHT) : 'base:shimmering',
          (Damage.TYPE.DARK) : 'base:dark',
          (Damage.TYPE.POISON) : 'base:poison'
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.BUFF,
    stats: StatSet.new(),
    events : {
      onEffectRemoveForced ::(from, holder, item, effectData) {
        windowEvent.queueMessage(
          text: holder.name + '\'s Clean Blessing granted a positive effect!'
        );
        
        holder.addEffect(
          id: Effect.getRandomFiltered(::(value) <- 
            (value.traits & Effect.TRAITS.SPECIAL) == 0 &&
            (value.traits & Effect.TRAITS.BUFF) != 0
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
    battleOnly : true,
    stackable: true,
    blockPoints : 0,
    flags : FLAGS.DEBUFF,
    stats: StatSet.new(),
    events : {
      onEffectRemoveForced ::(from, holder, item, effectData) {
        windowEvent.queueMessage(
          text: holder.name + '\'s Clean Curse inflicted a negative effect!'
        );
        
        holder.addEffect(
          id: Effect.getRandomFiltered(::(value) <- 
            (value.traits & Effect.TRAITS.SPECIAL) == 0 &&
            (
              (value.traits & Effect.TRAITS.DEBUFF) != 0 ||
              (value.traits & Effect.TRAITS.AILMENT) != 0
            )
          ),
          durationTurns: 3,
          from:holder
        );
      }
    }
  }
)    


}

@:Effect = Database.new(
  name: "Wyvern.Effect",
  statics : {
    FLAGS : {
      get ::<- FLAGS
    },
    
    FLAGS_TO_DOMINANT_SYMBOL ::(flag) {
      when(flag & FLAGS.SPECIAL) '?';
      when(flag & FLAGS.AILMENT) '!';
      when(flag & FLAGS.BUFF)    '+';
      when(flag & FLAGS.DEBUFF)  '-';
      return '?'
    }
  },
  attributes : {
    name : String,
    id : String,
    description : String,
    battleOnly : Boolean,
    stats : StatSet.type,
    flags : Number,
    blockPoints : Number,
    events : Object,
    stackable : Boolean // whether multiple of the same effect can coexist
  },
  reset
);

return Effect;
