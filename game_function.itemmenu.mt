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
@:random = import(module:'game_singleton.random.mt');
@:BattleAction = import(module:'game_struct.battleaction.mt');
@:Ability = import(module:'game_class.ability.mt');
@:pickItem = import(module:'game_function.pickitem.mt');



return ::(
    user,
    party,
    enemies,
    onAct => Function,
    inBattle => Boolean
) {
    @:Item = import(module:'game_class.item.mt');
    
    @:commitAction ::(action) {
        onAct(action);    
    };
    

    pickItem(inventory:party.inventory, canCancel:true, onPick::(item) {
        when(item == empty) empty;
        windowEvent.queueChoices(
            leftWeight: 1,
            topWeight: 1,
            prompt: '[' + item.name + ']',
            canCancel : true,
            keep:true,
            jumpTag: 'Item',
            choices: [
                'Use',
                'Check',
                'Compare',
                'Improve',
                'Toss'
            ],
            onChoice::(choice) {
                when (choice == 0) empty;              
                
                match(choice-1) {
                  // item: use
                  (0): ::<={
                    match(item.base.useTargetHint) {
                      (Item.USE_TARGET_HINT.ONE): ::<={
                        @:all = [];
                        party.members->foreach(do:::(index, ally) {
                            all->push(value:ally);
                        });
                        enemies->foreach(do:::(index, enemy) {
                            all->push(value:enemy);
                        });
                        
                        
                        @:allNames = [];
                        all->foreach(do:::(index, person) {
                            allNames->push(value:person.name);
                        });
                      
                      
                        choice = windowEvent.queueChoices(
                          leftWeight: 1,
                          topWeight: 1,
                          prompt: 'On whom?',
                          choices: allNames,
                          canCancel: true,
                          keep: true,
                          onChoice ::(choice) {
                            when(choice == 0) empty;                      
                            commitAction(action:BattleAction.new(state:{
                                    ability: Ability.database.find(name:'Use Item'),
                                    targets: [all[choice-1]],
                                    extraData : [item]
                                }) 
                            );                            
                            if (windowEvent.canJumpToTag(name:'Item'))
                                windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);

                          }
                        );
                        
                
                      },
                      
                      (Item.USE_TARGET_HINT.GROUP): ::<={
                        choice = windowEvent.queueChoices(
                          leftWeight: 1,
                          topWeight: 1,
                          prompt: 'On whom?',
                          choices: [
                            'Allies',
                            'Enemies'
                          ],
                          canCancel: true,
                          keep : true,
                          onChoice ::(choice) {
                       
                            when(choice == 0) empty;                                                  
                            commitAction(action:BattleAction.new(state:{
                                    ability: Ability.database.find(name:'Use Item'),
                                    targets: if (choice == 1) party.members else enemies,
                                    extraData : [item]
                                }) 
                            );                  
                            if (windowEvent.canJumpToTag(name:'Item'))
                                windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
                          
                          }
                        );
                      },

                      (Item.USE_TARGET_HINT.ALL): ::<= {
                        commitAction(action:BattleAction.new(state:{
                                ability: Ability.database.find(name:'Use Item'),
                                targets: [...party.members, ...enemies],
                                extraData : [item]
                            }) 
                        );                  
                        if (windowEvent.canJumpToTag(name:'Item'))
                            windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
                      
                      }



                    };
                  
                  },

                  
                  (1): ::<={ // inventory
                    item.describe(
                        by:user
                    );
                    
                  },
                  
                  // compare
                  (2)::<= {
                    @slot = user.getSlotsForItem(item)[0];
                    @currentEquip = user.getEquipped(slot);
                    
                    currentEquip.equipMod.printDiffRate(
                        prompt: '(Equip) ' + currentEquip.name + ' -> ' + item.name,
                        other:item.equipMod
                    ); 
                  },
                  (3)::<= {
                    when(item.material == empty) ::<= {
                        windowEvent.queueMessage(
                            text: 'Only items with a specified material can be improved.'
                        );                                                                                            
                    };
                  
                  
                    @:StatSet = import(module:'game_class.statset.mt'); 
                    if (! party.isMember(entity:user)) ::<= {
                        windowEvent.queueMessage(
                            text: item.name + ' can only be improved if they\'re in the party.'
                        );                                                                        
                    };
                    if (inBattle == true) ::<= {
                        @:complainer = random.pickArrayItem(list:party.members->filter(by::(value) <- value != user));
                        @:Personality = import(module:'game_class.personality.mt');
                        @:personality = complainer.personality;
                        windowEvent.queueMessage(
                            speaker: complainer.name,
                            text: '"' + random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.INAPPROPRIATE_TIME]) + '"'
                        );                        
                    };
                    
                    when(item.improvementsLeft == 0) ::<= {
                        windowEvent.queueMessage(
                            text: item.name + ' cannot be improved any further.'
                        );                                                
                    };
                    
                    windowEvent.queueMessage(
                        text: item.name + ' can be improved by attempting to combine it with another item of the same material. Once the process is complete, the other item is lost, and this item is improved.'
                    );
                    
                    windowEvent.queueAskBoolean(
                        prompt:'Improve ' + item.name + '?',
                        onChoice::(which) {
                        
                            when(which == false) empty;                     
                            @:others = party.inventory.items->filter(by:::(value) <- value.material == item.material && value != item);
                            when(others->keycount == 0) ::<= {
                                windowEvent.queueMessage(
                                    text: 'The party has no other items that are of the material ' + item.material.name
                                );
                            };
                                         
                            @:statChoices = [
                                'HP',
                                'AP',
                                'ATK',
                                'INT',
                                'DEF',
                                'LUK',
                                'SPD',
                                'DEX'
                            ];               
                            windowEvent.queueChoices(
                                prompt: 'Choose a stat to improve.',
                                choices: statChoices,
                                canCancel: true,
                                onChoice::(choice) {
                                    when(choice == 0) empty;
                                    @stat = statChoices[choice-1];
                                    windowEvent.queueChoices(
                                        prompt: 'Choose an item to use.',
                                        choices:[...others]->map(to:::(value) <- value.name),
                                        canCancel:true,
                                        onChoice::(choice) {
                                            when (choice == 0) empty;
                                            
                                            @:other = others[choice-1];
                                            windowEvent.queueMessage(
                                                text: 'Once complete, this will destroy ' + other.name + '.'
                                            );
                                            
                                            windowEvent.queueAskBoolean(
                                                prompt: 'Use ' + other.name + ' to improve ' + item.name + '?',
                                                onChoice::(which) {
                                                    when(which == false) empty;                     
                                                    
                                                    @:tryImprove::{
                                                        when(random.try(percentSuccess:85)) ::<= {
                                                            windowEvent.queueMessage(
                                                                text:'Looks like it needs more work...'
                                                            );
                                                            windowEvent.queueAskBoolean(
                                                                prompt: 'Try again?',
                                                                onChoice::(which) {
                                                                    when(which == false) empty;
                                                                    tryImprove();
                                                                }
                                                            );
                                                        };
                                                        
                                                        party.inventory.remove(item:other);
                                                        
                                                        
                                                        if (random.try(percentSuccess:90)) ::<= {
                                                            // success
                                                            windowEvent.queueMessage(
                                                                text: 'The improvement was successful!'
                                                            );                                              
                                                            
                                                            @:oldStats = item.equipMod;
                                                            @:newStats = StatSet.new();
                                                            @:state = oldStats.state;
                                                            state[stat] += 8;
                                                            state[random.pickArrayItem(list:statChoices)] -= 4;
                                                            
                                                            newStats.state = state;
                                                            item.improvementsLeft-=1;
                                                            
                                                            oldStats.printDiffRate(
                                                                other:newStats,
                                                                prompt: 'New stats: ' + item.name
                                                            );
                                                            
                                                            item.equipMod.state = newStats.state;
                                                              
                                                        } else ::<= {
                                                            windowEvent.queueMessage(
                                                                text: 'The improvement was unsuccessful...'
                                                            );                                                
                                                        };
                                                        
                                                    };
                                                    
                                                    
                                                    tryImprove();
                                                }
                                            );
                                        }
                                    );                                
                                }
                            
                            );
                        }
                    );
                  },                  
                  // Toss
                  (4)::<= {
                    windowEvent.queueAskBoolean(
                        prompt:'Are you sure you wish to throw away the ' + item.name + '?',
                        onChoice::(which) {
                            when(which == false) empty;
                            party.inventory.remove(item);
                            windowEvent.queueMessage(text:'The ' + item.name + ' was thrown away.');
                            if (windowEvent.canJumpToTag(name:'Item'))
                                windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
                        }
                    );
                  }
                };              
            
            }
        );
    });    
};
