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
@:dialogue = import(module:'game_singleton.dialogue.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Random = import(module:'game_singleton.random.mt');
@:BattleAction = import(module:'game_struct.battleaction.mt');
@:Ability = import(module:'game_class.ability.mt');
@:pickItem = import(module:'game_function.pickitem.mt');


@nextAction;

return ::(
    user,
    party,
    enemies,
    onAct => Function
) {
    @:Item = import(module:'game_class.item.mt');

    pickItem(inventory:party.inventory, canCancel:true, onPick::(item) {
        when(item == empty) empty;
        dialogue.choices(
            leftWeight: 1,
            topWeight: 1,
            prompt: '[' + item.name + ']',
            canCancel : true,
            keep:true,
            choices: [
                'Use',
                'Equip',
                'Check',
                'Compare'
            ],
            onNext::{
                onAct(action:nextAction);         
            },
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
                      
                      
                        choice = dialogue.choices(
                          leftWeight: 1,
                          topWeight: 1,
                          prompt: 'On whom?',
                          choices: allNames,
                          canCancel: true,
                          keep: true,
                          onNext ::{
                            dialogue.forceExit();
                          },
                          onChoice ::(choice) {
                            when(choice == 0) empty;                      

                            nextAction = BattleAction.new(state:{
                                    ability: Ability.database.find(name:'Use Item'),
                                    targets: [all[choice-1]],
                                    extraData : [item]
                                }) 
                            ;                            
                            dialogue.forceExit();
                          }
                        );
                        
                
                      },
                      
                      (Item.USE_TARGET_HINT.GROUP): ::<={
                        choice = dialogue.choices(
                          leftWeight: 1,
                          topWeight: 1,
                          prompt: 'On whom?',
                          choices: [
                            'Allies',
                            'Enemies'
                          ],
                          canCancel: true,
                          keep : true,
                          onNext ::{
                            dialogue.forceExit();                          
                          },
                          onChoice ::(choice) {
                       
                            when(choice == 0) empty;                      
                            
                            nextAction =BattleAction.new(state:{
                                    ability: Ability.database.find(name:'Use Item'),
                                    targets: if (choice == 1) party.members else enemies,
                                    extraData : [item]
                                }) 
                            ;                  
                            dialogue.forceExit();
                          
                          }
                        );
                      },

                      (Item.USE_TARGET_HINT.ALL): ::<= {
                        nextAction = BattleAction.new(state:{
                                ability: Ability.database.find(name:'Use Item'),
                                targets: [...party.members, ...enemies],
                                extraData : [item]
                            }) 
                        ;                  
                        dialogue.forceExit();
                      
                      }



                    };
                  
                  },
                  // item equip
                  (1)::<={
                    nextAction = BattleAction.new(state:{
                        ability: Ability.database.find(name:'Equip Item'),
                        targets: [user],
                        extraData : [item, party.inventory]
                    });           
                    dialogue.forceExit();


                  },

                  
                  (2): ::<={ // inventory
                    item.describe(
                        by:user,
                        onNext::{}
                    );
                    
                  },
                  
                  // compare
                  (3)::<= {
                    @slot = user.getSlotsForItem(item)[0];
                    @currentEquip = user.getEquipped(slot);
                    
                    currentEquip.equipMod.printDiffRate(
                        prompt: '(Equip) ' + currentEquip.name + ' -> ' + item.name,
                        other:item.equipMod
                    ); 
                    
                    
                    
                  }
                };              
            
            }
        );
    });    
};
