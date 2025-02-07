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
@:Random = import(module:'game_singleton.random.mt');
@:BattleAction = import(module:'game_struct.battleaction.mt');
@:class  = import(module:'Matte.Core.Class');
@:Arts = import(module:'game_database.arts.mt');
@:random = import(module:'game_singleton.random.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:ArtsDeck = import(module:'game_class.artsdeck.mt');
@:windowEvent = import(:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:BattleAI = LoadableClass.create(
  name: 'Wyvern.BattleAI',
  items : [],
  define:::(this, state) {
    @user_;
    @:Entity = import(module:'game_class.entity.mt');        

    @:defaultAttack = ::(onCommit, battle){
      @:enemies = battle.getEnemies(:user_);

      onCommit(:BattleAction.new(
        card: ArtsDeck.synthesizeHandCard(id:'base:attack'),
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
        
          @hand = [...user_.deck.hand]->map(to::(value) <- {
              card:value, 
              overrideTargets:(Arts.find(id:value.id).shouldAIuse(
                  user:user_,
                  enemies,
                  reactTo:source,
                  allies
              ))
          });

          
          @hand = hand->filter(
            ::(value) <- Arts.find(id:value.card.id).usageHintAI != Arts.USAGE_HINT.DONTUSE &&
                         Arts.find(id:value.card.id).kind == Arts.KIND.REACTION &&
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
          condition : if (Arts.find(id:cardI.card.id).usageHintAI == Arts.USAGE_HINT.HEAL) ::<= {
            ::(value) <- value.hp < value.stats.HP
          },
          overrideTargets: cardI.overrideTargets,
          onCommit
        );
      },

      commitTargettedAction::(battle, onCommit, card, condition, overrideTargets) {
        @:enemies = battle.getEnemies(:user_);
        @:allies = battle.getAllies(:user_);
        @:art = Arts.find(id:card.id);
        @atEnemy = (art.usageHintAI == Arts.USAGE_HINT.OFFENSIVE) ||
               (art.usageHintAI == Arts.USAGE_HINT.DEBUFF);
        
        @targets = [];
        @targetParts = [];
        if (overrideTargets == empty) ::<= {
          match(art.targetMode) {
            (Arts.TARGET_MODE.ONE,
             Arts.TARGET_MODE.ONEPART) :::<= {
              if (atEnemy) 
                targets->push(value:Random.pickArrayItem(list:enemies))
              else 
                targets->push(value:Random.pickArrayItem(list:allies))
              ;
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
              if (random.number() < 0.5) 
                targets->push(value:Random.pickArrayItem(list:enemies))
              else 
                targets->push(value:Random.pickArrayItem(list:allies))
              ;          
            }

          }
        } else ::<= {
          if (overrideTargets->findIndexCondition(::(value) <- value->type != Entity.type) != -1) 
          ::<= {
            error(:'Hi. This error is happening because the AI decision for an Art returned an invalid value. It is likely that the Art ' + 
              if (card == empty)
                '... Actually hold on, there is apparently another error (card == empty?)'
              else 
                card.id + ' is the culprit. (overrideTargets is of type ' + String(:targets->type) + ')'
            )
          }        
          targets = overrideTargets;
        }
        
        if (condition)
          targets = [...targets]->filter(:condition);
        
        when (targets->size == 0 && art.targetMode != Arts.TARGET_MODE.NONE)
          defaultAttack(battle, onCommit);
        
        foreach(targets) ::(index, t) {
          targetParts[index] = Entity.normalizedDamageTarget();
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
      
        ::<= {
          @:enemies = battle.getEnemies(:user_);
          @:allies = battle.getAllies(:user_);

          @:Entity = import(module:'game_class.entity.mt');        
          @:Profession = import(module:'game_database.profession.mt');        
        
          when(((user_.profession.traits & Profession.TRAITS.PACIFIST) != 0) || enemies->keycount == 0 || enemies->findIndexCondition(::(value) <- !value.isIncapacitated()) == -1)
            
            acts->push(:BattleAction.new(
              card: ArtsDeck.synthesizeHandCard(id:'base:wait'),
              targets: [],
              turnIndex : 0,
              targetParts : [],
              extraData: {}
            ))
        
          
          
          @hand = [...user_.deck.hand]->map(to::(value) <- {
              card:value, 
              overrideTargets:(Arts.find(id:value.id).shouldAIuse(
                  user:user_,
                  enemies,
                  allies
              ))
          });


          hand = hand->filter(::(value) <- 
              (Arts.find(id:value.card.id).usageHintAI != Arts.USAGE_HINT.DONTUSE) &&
              (!(value.overrideTargets->type == Boolean && value.overrideTargets == false))
          );
                  
          
          @projectedAP = user_.ap; 
          foreach(hand) ::(k, full) {
            @v = full.card;
            @art = Arts.find(id:v.id);
            
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
          @c = Random.pickArrayItem(list:hand->filter(by::(value) <- Arts.find(id:value.card.id).kind == Arts.KIND.ABILITY));

          when (c == empty)
            defaultAttack(
              battle,
              onCommit ::(action) {
                acts->push(:action)
              }
            ); 
           

          @:ability = Arts.find(id:c.card.id);
          
          
          @:world = import(module:'game_singleton.world.mt');
          @:party = world.party;
          
          // discourage abilities until players get their bearings, please!
          @:tier = world.island.tier;
          
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
            card: ArtsDeck.synthesizeHandCard(id:'base:wait'),
            targets: [],
            turnIndex : 0,
            targetParts : [],
            extraData: {}
          ))
              
        windowEvent.queueCallback(
          callback ::{

            when(acts->size == 0) windowEvent.CALLBACK_DONE
            @:act = acts[0]
            acts->remove(:0)
            

            
            battle.entityCommitAction(action:act);
            
          }
        );
      }
    }

       
  }  

);
return BattleAI;
