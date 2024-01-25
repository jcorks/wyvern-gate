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
@:Ability = import(module:'game_database.ability.mt');
@:random = import(module:'game_singleton.random.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
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
            
            takeTurn ::(battle, enemies, allies){
                @:defaultAttack = ::{
                    battle.entityCommitAction(action:BattleAction.new(
                        ability: 
                            Ability.find(name:'Attack'),

                        targets: [
                            Random.pickArrayItem(list:enemies)
                        ],
                        extraData: {}                        
                    ));                  
                }
            
                when(enemies->keycount == 0)
                    battle.entityCommitAction(action:BattleAction.new(
                        ability: Ability.find(name:'Wait'),
                        targets: [],
                        extraData: {}                        
                    ));
            
            
                // default: just attack if all you have is defend and attack
                when(user_.abilitiesAvailable->keycount <= 2 || random.try(percentSuccess:40))
                    defaultAttack();          

                // else pick a non-defend ability
                @:list = user_.abilitiesAvailable->filter(by:::(value) <- value.name != 'Attack' && value.name != 'Defend' && value.usageHintAI != Ability.USAGE_HINT.DONTUSE);

                // fallback if only ability known is "dont use"
                when (list->keycount == 0)
                    defaultAttack();
                    
                @:ability = Random.pickArrayItem(list);



                when (ability.usageHintAI == Ability.USAGE_HINT.HEAL &&                
                    user_.hp == user_.stats.HP)
                    defaultAttack();
                
                @atEnemy = (ability.usageHintAI == Ability.USAGE_HINT.OFFENSIVE) ||
                           (ability.usageHintAI == Ability.USAGE_HINT.DEBUFF);
                
                @targets = [];
                match(ability.targetMode) {
                  (Ability.TARGET_MODE.ONE) :::<= {
                    if (atEnemy) 
                        targets->push(value:Random.pickArrayItem(list:enemies))
                    else 
                        targets->push(value:Random.pickArrayItem(list:allies))
                    ;
                  },
                  
                  (Ability.TARGET_MODE.ALLALLY) :::<= {
                    targets = [...allies];
                  },                  

                  (Ability.TARGET_MODE.ALLENEMY) :::<= {
                    targets = [...enemies];
                  },                  

                  (Ability.TARGET_MODE.NONE) :::<= {
                  },


                  (Ability.TARGET_MODE.RANDOM) :::<= {
                    if (Number.random() < 0.5) 
                        targets->push(value:Random.pickArrayItem(list:enemies))
                    else 
                        targets->push(value:Random.pickArrayItem(list:allies))
                    ;                    
                  }

                }
                
                
                battle.entityCommitAction(action:BattleAction.new(
                    ability: ability,
                    targets: targets,
                    extraData: {}                        
                ));
            }
        }   
    }  

);
return BattleAI;
