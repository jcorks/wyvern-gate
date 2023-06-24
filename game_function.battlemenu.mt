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
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Random = import(module:'game_singleton.random.mt');
@:BattleAction = import(module:'game_struct.battleaction.mt');
@:Ability = import(module:'game_class.ability.mt');
@:itemmenu = import(module:'game_function.itemmenu.mt');


return ::(
    party,
    battle,
    user,
    landmark,
    allies,
    enemies             
) {
    @:commitAction ::(action) {
        battle.entityCommitAction(action:action);    
        windowEvent.jumpToTag(name:'BattleMenu', goBeforeTag:true, doResolveNext:true);
    };


    windowEvent.choiceColumns(
        leftWeight: 1,
        topWeight: 1,
        choices : [
            'Act',
            'Check',
            'Run',
            'Wait',
            'Item'
        ],
        jumpTag: 'BattleMenu',
        keep: true,
        itemsPerColumn: 3,
        renderable: battle,
        prompt: 'What will ' + user.name + ' do?',
        canCancel: false,
        onChoice::(choice) {
            
            match(choice-1) {
              (0): ::<={ // fight

                @:abilities = [];
                user.abilitiesAvailable->foreach(do:::(index, ability) {
                    abilities->push(value:
                        if (ability.apCost > 0 || ability.hpCost > 0)
                            if (ability.apCost > 0) 
                                ability.name + '(' + ability.apCost + ' AP)'
                            else 
                                ability.name + '(' + ability.apCost + ' HP)'
                        else
                            ability.name
                    );
                });
                
                windowEvent.choices(
                    leftWeight: 1,
                    topWeight: 1,
                    prompt:'What ability should ' + user.name + ' use?',
                    choices: abilities,
                    canCancel: true,
                    keep: true,
                    onChoice::(choice) {
                        when(choice == 0) empty;
                        
                        
                        @:ability = user.abilitiesAvailable[choice-1];
                        
                        
                        match(ability.targetMode) {
                          (Ability.TARGET_MODE.ONE): ::<={
                            @:all = [];
                            allies->foreach(do:::(index, ally) {
                                all->push(value:ally);
                            });
                            enemies->foreach(do:::(index, enemy) {
                                all->push(value:enemy);
                            });
                            
                            
                            @:allNames = [];
                            all->foreach(do:::(index, person) {
                                allNames->push(value:person.name);
                            });
                          
                          
                            windowEvent.choices(
                              leftWeight: 1,
                              topWeight: 1,
                              prompt: 'Against whom?',
                              choices: allNames,
                              canCancel: true,
                              keep: true,
                              onChoice::(choice) {
                                when(choice == 0) empty;
                                
                                commitAction(action:
                                    BattleAction.new(
                                        state : {
                                            ability: ability,
                                            targets: [all[choice-1]],
                                            extraData: {}
                                        }
                                    )
                                );
                              
                              }
                            );
                            
                          },
                          (Ability.TARGET_MODE.ALLALLY): ::<={
                            commitAction(action:
                                BattleAction.new(
                                    state : {
                                        ability: ability,
                                        targets: allies,
                                        extraData: {}
                                    }
                                )
                            );                          
                          },
                          (Ability.TARGET_MODE.ALLENEMY): ::<={
                            commitAction(action:
                                BattleAction.new(
                                    state : {
                                        ability: ability,
                                        targets: enemies,
                                        extraData: {}                                
                                    }
                                )
                            );
                          },

                          (Ability.TARGET_MODE.NONE): ::<={
                            commitAction(action:
                                BattleAction.new(
                                    state : {
                                        ability: ability,
                                        targets: [],
                                        extraData: {}                                
                                    }
                                )
                            );
                          },

                          (Ability.TARGET_MODE.RANDOM): ::<={
                            @all = [];
                            allies->foreach(do:::(index, ally) {
                                all->push(value:ally);
                            });
                            enemies->foreach(do:::(index, enemy) {
                                all->push(value:enemy);
                            });
                
                            commitAction(action:
                                BattleAction.new(
                                    state : {
                                        ability: ability,
                                        targets: Random.pickArrayItem(list:all),
                                        extraData: {}                                
                                    }
                                )
                            );
                          }
                          
                          

                        };                    
                    }
                );
              },
              
              (1): ::<={ // Info
                windowEvent.choices(
                  topWeight: 1,
                  prompt: 'Check which?', 
                  leftWeight: 1,
                  keep: true,
                  canCancel: true,
                  choices : [
                    'Abilities',
                    'Allies',
                    'Enemies'
                  ],
                  onChoice::(choice) {
                    when(choice == 0) empty;

                    match(choice-1) {
                      (0): ::<={ // abilities
                        @:names = [...user.abilitiesAvailable]->map(to:::(value){return value.name;});
                        
                        windowEvent.choices(
                          leftWeight: 1,
                          topWeight: 1,
                          prompt: 'Check which ability?',
                          choices: names,
                          keep: true,
                          canCancel: true,
                          onChoice::(choice) {
                            when(choice == 0) empty;
                                
                            @:ability = user.abilitiesAvailable[choice-1];

                            windowEvent.message(
                                speaker: 'Ability: ' + ability.name,
                                text:ability.description
                            );                          
                          }
                        );
                      },
                      
                      (1): ::<={ // allies
                        @:names = [...allies]->map(to:::(value){return value.name;});
                        
                        choice = windowEvent.choices(
                            topWeight: 1,
                            leftWeight: 1,
                            prompt:'Check which ally?',
                            choices: names,
                            keep: true,
                            canCancel: true,
                            onChoice::(choice) {
                                when (choice == 0) empty;

                                @:ally = allies[choice-1];
                                ally.describe();                            
                            }
                        );
                      }
                    
                    };                  
                  }
                );
                

              },
              
              // run 
              (2): ::<= {
                commitAction(action:
                    BattleAction.new(
                        state : {
                            ability: Ability.database.find(name:'Run'),
                            targets: [],
                            extraData: {}
                        }
                    )                
                );
                
              },
              
              // wait
              (3): ::<={
                commitAction(action:
                    BattleAction.new(
                        state : {
                            ability: Ability.database.find(name:'Wait'),
                            targets: [],
                            extraData: {}
                        }
                    )                
                );
              },
              
              // Item
              (4): ::<= {
                itemmenu(user, party, enemies, onAct::(action){
                    commitAction(action);
                });
              }
            };          
        }
    );    
};
