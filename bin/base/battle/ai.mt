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
@:Random = import(module:'core/random.mt');
@:BattleAction = import(module:'base/battle/action.mt');
@:class  = import(module:'Matte.Core.Class');
@:Arts = import(module:'base/arts.mt');
@:random = import(module:'core/random.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:ArtsDeck = import(module:'base/arts/deck.mt');
@:windowEvent = import(:'core/windowevent.mt');
@:canvas = import(module:'core/graphics/canvas.mt');
@:BattleAI = LoadableClass.create(
  name: 'Wyvern.BattleAI',
  items : [],
  define:::(this, state) {
    @user_;
    @:Entity = import(module:'base/entity.mt');        

    @:defaultAttack = ::(onCommit, battle){
      @enemies = battle.getEnemies(:user_)->filter(::(value) <- value.isIncapacitated() == false);
      if (enemies->size == 0)
        enemies = battle.getEnemies(:user_);

      onCommit(:BattleAction.new(
        card: Arts.new(base:Arts.database.find(id:'base:attack')),
        turnIndex : 0,

        targets: [
          Random.pickArrayItem(list:enemies)
        ],
        targetParts : [
          Entity.normalizedDamageTarget()
        ],
        extraData: {}            
      ));
    }

    
      
    this.interface = {
      initialize::(user) {
        this.setUser(user);
      },
      
      defaultLoad ::{},

      setUser ::(user) {
        user_ = user;
      },
      
      chooseReaction::(source, battle, onCommit) {
        @:cardI = ::<= {
          @:enemies = battle.getEnemies(:user_);
          @:allies = battle.getAllies(:user_);

          when(user_.canUseReactions() == false) empty;
        
          @hand = user_.arts->map(to::(value) <- {
              card:value, 
              overrideTargets:(Arts.database.find(id:value.id).shouldAIuse(
                  user:user_,
                  enemies,
                  reactTo:source,
                  allies
              ))
          });

          
          @hand = hand->filter(
            ::(value) <- Arts.database.find(id:value.card.id).usageHintAI != Arts.USAGE_HINT.DONTUSE &&
                         value.card.canUse && 
                        (!(value.overrideTargets->type == Boolean && value.overrideTargets == false))
          );
          
          when(hand->size == 0) empty;
          when (random.try(percentSuccess:40)) empty;
          
          return random.pickArrayItem(:hand);
        }

        when(cardI == empty)
          onCommit();                   
          
  
        this.commitTargettedAction(
          card:cardI.card,
          battle,
          condition : if (Arts.database.find(id:cardI.card.id).usageHintAI == Arts.USAGE_HINT.HEAL) ::<= {
            ::(value) <- value.hp < value.stats.HP
          },
          overrideTargets: cardI.overrideTargets,
          onCommit
        );
      },

      commitTargettedAction::(battle, onCommit, card, condition, overrideTargets) {
        @enemies = battle.getEnemies(:user_);
        @allies = battle.getAllies(:user_);
        
        
        @:art = Arts.database.find(id:card.id);
        @atEnemy = (art.usageHintAI == Arts.USAGE_HINT.OFFENSIVE) ||
               (art.usageHintAI == Arts.USAGE_HINT.DEBUFF);
        
        @targets = [];
        @targetParts = [];
        if (overrideTargets == empty) ::<= {
          match(art.targetMode) {
            (Arts.TARGET_MODE.ONE,
             Arts.TARGET_MODE.ONEPART) :::<= {
              if (atEnemy) ::<= {
                if (condition)
                  enemies = [...enemies]->filter(:condition);
                if (art.usageHintAI == Arts.USAGE_HINT.OFFENSIVE)
                  enemies = enemies->filter(::(value) <- value.hp != 0);
                  
                if (enemies->size > 0) ::<= {
                  targets->push(value:Random.pickArrayItem(list:enemies))
                  if (art.targetMode == Arts.TARGET_MODE.ONEPART)
                    targetParts = [Entity.normalizedDamageTarget()];
                }
              } else ::<= {
                if (condition)
                  allies = [...allies]->filter(:condition);
                if (allies->size > 0)
                  targets->push(value:Random.pickArrayItem(list:allies))
              }
            },
            
            (Arts.TARGET_MODE.ALLALLY) :::<= {
              targets = [...allies];
            },          

            (Arts.TARGET_MODE.ALLENEMY) :::<= {
              targets = [...enemies];
            },          

            (Arts.TARGET_MODE.NONE) :::<= {
            },


            (Arts.TARGET_MODE.RANDOM) :::<= {
              if (condition) ::<= {
                allies = [...allies]->filter(:condition);
                enemies = [...enemies]->filter(:condition);
              }
              @v = Random.pickArrayItem(: if(Random.flipCoin()) enemies else allies);
              if (v != empty)
                targets->push(:v);
            }

          }
        } else ::<= {
          @targetIndex = overrideTargets->findIndexCondition(::(value) <- value->type != Entity.type);
          if (targetIndex != -1) 
          ::<= {
            error(:'Hi. This error is happening because the AI decision for an Art returned an invalid value. It is likely that the Art ' + 
              if (card == empty)
                '... Actually hold on, there is apparently another error (card == empty?)'
              else 
                card.id + ' is the culprit. (overrideTargets member in question is of type ' + String(:overrideTargets[targetIndex]->type) + ')'
            )
          }        
          targets = overrideTargets;
        }
        
        
        when (targets->size == 0 && art.targetMode != Arts.TARGET_MODE.NONE)
          defaultAttack(battle, onCommit);
        
        if (targetParts == empty) ::<= {
          foreach(targets) ::(index, t) {
            targetParts[index] = Entity.DAMAGE_TARGET.BODY;
          }
        }
        onCommit(:BattleAction.new(
          card,
          turnIndex : 0,
          targets: targets,
          targetParts : targetParts,
          extraData: {}            
        ));  
      },



      
      takeTurn ::(battle){
        @:acts = {};
        @:processActs ::(acts){
          windowEvent.queueCallback(
            callback ::{

              when(acts->size == 0) windowEvent.CALLBACK_DONE
              @:act = acts[0]
              acts->remove(:0)
              

              
              battle.entityCommitAction(action:act);
              
            }
          );        
        }
      
        ::<= {
          @:enemies = battle.getEnemies(:user_);
          @:allies = battle.getAllies(:user_);

          @:Entity = import(module:'base/entity.mt');        
          @:Profession = import(module:'base/entity/profession.mt');        
          // discourage abilities until players get their bearings, please!
          @:world = import(module:'base/world.mt');
          @:party = world.party;
          
          when (user_.species.overrideBattleAI->type == Function) ::<= {
            user_.species.overrideBattleAI(
              entity : user_,
              battle : battle,
              commitBattleActions ::(acts => Object) {
                foreach(acts) ::(k, v) {
                  if (v->type != BattleAction.type) ::<= {
                    error(:'overrideBattleAI (for ' + user_.name + ') contains elements within acts that arent BattleActions.');
                  }
                }
                
                processActs(acts);
              }
            );
          }
          

          @tier = world.island.tier;
          
          if (world.party.isMember(:user_)) 
            tier = 99;
          
                  
          when(((user_.profession.traits & Profession.TRAIT.PACIFIST) != 0) || enemies->keycount == 0 || enemies->findIndexCondition(::(value) <- !value.isIncapacitated()) == -1)
            
            acts->push(:BattleAction.new(
              card: Arts.new(base:Arts.database.find(id:'base:wait')),
              targets: [],
              turnIndex : 0,
              targetParts : [],
              extraData: {}
            ))
        
          
          
          @hand = user_.arts->map(to::(value) <- {
              card:value, 
              overrideTargets:(Arts.database.find(id:value.id).shouldAIuse(
                  user:user_,
                  enemies,
                  allies
              ))
          });
          
          hand = random.scrambled(:hand);


          hand = hand->filter(::(value) <- 
              (Arts.database.find(id:value.card.id).usageHintAI != Arts.USAGE_HINT.DONTUSE) &&
              (!(value.overrideTargets->type == Boolean && value.overrideTargets == false)) &&
              
              // only party members are beholden to this limit
              (world.party.isMember(:user_) == false || value.card.canUse)
          );
                  
          // limit max action count by tier
          ::<= {
            @handOld = [...hand];
            hand = [];
            ::? {
              for(0, tier+1) ::(i) {
                if (i >= handOld->size) send();
                hand->push(:handOld[i]);
              }
            }
          }
          
          @projectedAP = user_.ap; 
          foreach(hand) ::(k, full) {
            when(random.flipCoin()) empty;
            @v = full.card;
            @art = Arts.database.find(id:v.id);
            
            // objects with no size are equivalent to no override targets.
            if (full.overrideTargets->type == Object &&
              full.overrideTargets->size == 0) ::<= {
              full.overrideTargets = empty;   
            }
            
            // "true" is shorthand for "just choose a target please"
            if (full.overrideTargets->type == Boolean) ::<= {
              full.overrideTargets = empty;
            }
            
            if (user_.canUseEffects() && art.kind == Arts.KIND.EFFECT && random.flipCoin()) ::<= {
              when (projectedAP < 2) empty;
              this.commitTargettedAction(
                battle,
                card:v,
                overrideTargets: full.overrideTargets,
                onCommit ::(action) {
                  acts->push(:action)
                }
              );
              projectedAP -= 2;
              hand->remove(key:hand->findIndex(value:full));
            }
          }        


          when(hand->keycount == 0 && user_.canUseAbilities())
            defaultAttack(
              battle,
              onCommit ::(action) {
                acts->push(:action)
              }
            ); 
           
        
          when (user_.canUseAbilities() == false) empty;
          @c = Random.pickArrayItem(list:hand->filter(by::(value) <- Arts.database.find(id:value.card.id).kind == Arts.KIND.ABILITY));

          when (c == empty)
            defaultAttack(
              battle,
              onCommit ::(action) {
                acts->push(:action)
              }
            ); 
           

          @:ability = Arts.database.find(id:c.card.id);
          
          
          

          
          when (party != empty && [...enemies]->filter(::(value) <- party.isMember(:value))->size > 0 &&
              random.try(percentSuccess:80 - (tier * 30)))
              defaultAttack(
                battle,
                onCommit ::(action) {
                  acts->push(:action)
                }
              ); 
             

          // need enough to use an art
          when (projectedAP < 2)
              defaultAttack(
                battle,
                onCommit ::(action) {
                  acts->push(:action)
                }
              ); 
             
          @condition;
          
          if (ability.usageHintAI == Arts.USAGE_HINT.HEAL) ::<= {
            condition = ::(value) <- value.hp < value.stats.HP
          }
          
          this.commitTargettedAction(
            card:c.card, 
            battle, 
            condition, 
            overrideTargets:c.overrideTargets,
            onCommit ::(action) {
              acts->push(:action)
            }
          );
        }
        
        if (acts->size == 0) 
          acts->push(:BattleAction.new(
            card: Arts.new(base:Arts.database.find(id:'base:wait')),
            targets: [],
            turnIndex : 0,
            targetParts : [],
            extraData: {}
          ))
              
        processActs(acts);
      }
    }

       
  }  

);
return BattleAI;
