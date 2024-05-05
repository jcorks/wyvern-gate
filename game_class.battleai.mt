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
@:BattleAI = LoadableClass.create(
    name: 'Wyvern.BattleAI',
    items : [],
    define:::(this, state) {
        @user_;
        
            
        this.interface = {
            initialize::(user) {
                this.setUser(user);
            },
            
            defaultLoad ::{},

            setUser ::(user) {
                user_ = user;
            },
            
            chooseReaction::(source, battle, enemies, allies) {

                @hand = user_.deck.hand->filter(
                    ::(value) <- Arts.find(id:value.id).usageHintAI != Arts.USAGE_HINT.DONTUSE &&
                                 Arts.find(id:value.id).kind == Arts.KIND.REACTION
                );
                
                when(hand->size == 0) empty;
                when (random.try(percentSuccess:40)) empty;
                
                @:sourceIsEnemy = enemies->findIndex(:source) != -1;
                hand = random.scrambled(:hand);

                when(sourceIsEnemy) hand[0];
                
                return {:::} {
                    foreach(hand) ::(k, v) {
                        @art = Arts.find(id:v.id);
                        if (art.usageHintAI != Arts.USAGE_HINT.DEBUFF &&
                            art.usageHintAI != Arts.USAGE_HINT.OFFENSIVE)
                            send(:v);
                    } 
                }
            },
            
            takeTurn ::(battle, enemies, allies){
                @:Entity = import(module:'game_class.entity.mt');
                
                
                @:commitTargettedAction::(card) {
                    @:art = Arts.find(id:card.id);
                    @atEnemy = (art.usageHintAI == Arts.USAGE_HINT.OFFENSIVE) ||
                               (art.usageHintAI == Arts.USAGE_HINT.DEBUFF);
                    
                    @targets = [];
                    @targetParts = [];
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
                        if (Number.random() < 0.5) 
                            targets->push(value:Random.pickArrayItem(list:enemies))
                        else 
                            targets->push(value:Random.pickArrayItem(list:allies))
                        ;                    
                      }

                    }
                    foreach(targets) ::(index, t) {
                        targetParts[index] = Entity.normalizedDamageTarget();
                    }
                    windowEvent.onResolveAll(
                        onDone:: {
                            battle.entityCommitAction(action:BattleAction.new(
                                card,
                                targets: targets,
                                targetParts : targetParts,
                                extraData: {}                        
                            ));   
                        }
                    );          
                }
                
                @:defaultAttack = ::{
                    user_.deck.discardFromHand(card:random.pickArrayItem(list:user_.deck.hand));

                    windowEvent.onResolveAll(
                        onDone:: {

                            battle.entityCommitAction(action:BattleAction.new(
                                card: ArtsDeck.synthesizeHandCard(id:'base:attack'),

                                targets: [
                                    Random.pickArrayItem(list:enemies)
                                ],
                                targetParts : [
                                    Entity.normalizedDamageTarget()
                                ],
                                extraData: {}                        
                            ));             
                        }
                    );
                }
            
                when(enemies->keycount == 0)
                    battle.entityCommitAction(action:BattleAction.new(
                        card: ArtsDeck.synthesizeHandCard(id:'base:wait'),
                        targets: [],
                        targetParts : [],
                        extraData: {}                        
                    ));
            
                
                
                @:hand = user_.deck.hand->filter(by::(value) <- Arts.find(id:value.id).usageHintAI != Arts.USAGE_HINT.DONTUSE);
                
                foreach(hand) ::(k, v) {
                    @art = Arts.find(id:v.id);
                    if (art.kind == Arts.KIND.EFFECT && random.flipCoin()) ::<= {
                        commitTargettedAction(
                            card:v
                        );
                        hand->remove(key:hand->findIndex(value:v));
                    }
                }                


                when(hand->keycount == 0)
                    defaultAttack();
            
                    
                @card = Random.pickArrayItem(list:hand->filter(by::(value) <- Arts.find(id:value.id).kind == Arts.KIND.ABILITY));
                when (card == empty)
                    defaultAttack();

                @:ability = Arts.find(id:card.id);

                when (ability.usageHintAI == Arts.USAGE_HINT.HEAL &&                
                    user_.hp == user_.stats.HP)
                    defaultAttack();
                
                commitTargettedAction(card:card);
            }
        }   
    }  

);
return BattleAI;
