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
@:dialogue = import(module:'singleton.dialogue.mt');
@:canvas = import(module:'singleton.canvas.mt');
@:Random = import(module:'singleton.random.mt');
@:BattleAction = import(module:'struct.battleaction.mt');
@:Ability = import(module:'class.ability.mt');
@:itemmenu = import(module:'function.itemmenu.mt');
return ::(
    party,
    battle,
    user,
    landmark,
    allies,
    enemies             
) {

    dialogue.choiceColumns(
        leftWeight: 1,
        topWeight: 1,
        choices : [
            'Act',
            'Check',
            'Run',
            'Wait',
            'Item'
        ],
        
        itemsPerColumn: 3,
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
                
                dialogue.choices(
                    leftWeight: 1,
                    topWeight: 1,
                    prompt:'What ability should ' + user.name + ' use?',
                    choices: abilities,
                    canCancel: true,
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
                          
                          
                            dialogue.choices(
                              leftWeight: 1,
                              topWeight: 1,
                              prompt: 'Against whom?',
                              choices: allNames,
                              canCancel: true,
                              onChoice::(choice) {
                                when(choice == 0) empty;
                                
                                battle.entityCommitAction(action:
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
                            battle.entityCommitAction(action:
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
                            battle.entityCommitAction(action:
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
                            battle.entityCommitAction(action:
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
                
                            battle.entityCommitAction(action:
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
                dialogue.choices(
                  topWeight: 1,
                  prompt: 'Check which?', 
                  leftWeight: 1,

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
                        
                        dialogue.choices(
                          leftWeight: 1,
                          topWeight: 1,
                          prompt: 'Check which ability?',
                          choices: names,
                          canCancel: true,
                          onChoice::(choice) {
                            when(choice == 0) empty;
                                
                            @:ability = user.abilitiesAvailable[choice-1];

                            dialogue.message(
                                speaker: 'Ability: ' + ability.name,
                                text:ability.description
                            );                          
                          }
                        );
                      },
                      
                      (1): ::<={ // allies
                        @:names = [...allies]->map(to:::(value){return value.name;});
                        
                        choice = dialogue.choices(
                            topWeight: 1,
                            leftWeight: 1,
                            prompt:'Check which ally?',
                            choices: names,
                            canCancel: true,
                            onChoice::(choice) {
                                when (choice == 0) empty;

                                @:ally = allies[choice-1];
                                ally.describe();                            
                            }
                        );
                      }
                    
                    };                  
                  },
                  canCancel : true
                );
                

              },
              
              // run 
              (2): ::<= {
                battle.entityCommitAction(action:
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
                battle.entityCommitAction(action:
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
                itemmenu(user, party, enemies, onAct::(action){battle.entityCommitAction(action);});
              }
            };          
        }
    );    
};
