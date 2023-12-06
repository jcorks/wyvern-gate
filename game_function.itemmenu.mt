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
    }
    

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
                'Equip',
                'Compare',
                'Rename',
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
                        foreach(party.members)::(index, ally) {
                            all->push(value:ally);
                        }
                        foreach(enemies)::(index, enemy) {
                            all->push(value:enemy);
                        }
                        
                        
                        @:allNames = [];
                        foreach(all)::(index, person) {
                            allNames->push(value:person.name);
                        }
                      
                      
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



                    }
                  
                  },

                  
                  (1): ::<={ // inventory
                    item.describe(
                        by:user
                    );
                    
                  },
                  
                  (2): ::<= {
                    commitAction(action:BattleAction.new(state:{
                        ability: Ability.database.find(name:'Equip Item'),
                        targets: [user],
                        extraData : [item, party.inventory]
                    }));           
                    if (windowEvent.canJumpToTag(name:'Item'))
                        windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
                  },
                  
                  // compare
                  (3)::<= {
                    @slot = user.getSlotsForItem(item)[0];
                    @currentEquip = user.getEquipped(slot);
                    
                    currentEquip.equipMod.printDiffRate(
                        prompt: '(Equip) ' + currentEquip.name + ' -> ' + item.name,
                        other:item.equipMod
                    ); 
                  },
                  // rename
                  (4)::<= {
                    when (!item.base.canHaveEnchants)
                        windowEvent.queueMessage(text:item.name + ' cannot be renamed.');
                  
                    @:name = import(module:"game_function.name.mt");
                    name(
                        prompt: 'New item name:',
                        onDone::(name) {
                            item.name = name;
                            if (windowEvent.canJumpToTag(name:'Item'))
                                windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
                        }
                    );
                  },
                  // improve
                  (5)::<= {
                    (import(module:'game_function.itemimprove.mt'))(user, item, inBattle); 
                  },               
                  // Toss
                  (6)::<= {
                    windowEvent.queueAskBoolean(
                        prompt:'Are you sure you wish to throw away the ' + item.name + '?',
                        onChoice::(which) {
                            when(which == false) empty;
                            party.inventory.remove(item);
                            
                            if (item.name->contains(key:'Wyvern Key of')) ::<= {
                                @:world = import(module:'game_singleton.world.mt')
                                world.accoladeEnable(name:'gotRidOfWyvernKey');      
                            }
                                                      
                            windowEvent.queueMessage(text:'The ' + item.name + ' was thrown away.');
                            if (windowEvent.canJumpToTag(name:'Item'))
                                windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
                        }
                    );
                  }
                }              
            
            }
        );
    });    
}
