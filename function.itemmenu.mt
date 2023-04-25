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
@:pickItem = import(module:'function.pickitem.mt');

return ::(
    user,
    party,
    enemies,
    onAct => Function
) {
    @:Item = import(module:'class.item.mt');

    pickItem(inventory:party.inventory, canCancel:true, onPick::(item) {
        when(item == empty) empty;
        dialogue.choices(
            leftWeight: 1,
            topWeight: 1,
            prompt: '[' + item.name + ']',
            canCancel : true,
            choices: [
                'Use',
                'Equip',
                'Check',
                'Compare'
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
                      
                      
                        choice = dialogue.choices(
                          leftWeight: 1,
                          topWeight: 1,
                          prompt: 'On whom?',
                          choices: allNames,
                          canCancel: true,
                          onChoice ::(choice) {
                            when(choice == 0) empty;                      

                            onAct(
                                action:BattleAction.new(state:{
                                    ability: Ability.database.find(name:'Use Item'),
                                    targets: [all[choice-1]],
                                    extraData : [item]
                                }) 
                            );                            
                          }
                        );
                        
                
                      },
                      
                      (Item.USE_TARGET_HINT.GROUP): ::<={
                        choice = dialogue.choicesNow(
                          leftWeight: 1,
                          topWeight: 1,
                          prompt: 'On whom?',
                          choices: [
                            'Allies',
                            'Enemies'
                          ],
                          canCancel: true
                        );
                        
                        when(choice == 0) empty;                      
                        onAct(
                            action:BattleAction.new(state:{
                                ability: Ability.database.find(name:'Use Item'),
                                targets: if (choice == 1) party.members else enemies,
                                extraData : [item]
                            }) 
                        );                  
                      },

                      (Item.USE_TARGET_HINT.ALL): ::<= {
                        onAct(action:
                            BattleAction.new(state:{
                                ability: Ability.database.find(name:'Use Item'),
                                targets: [...party.members, ...enemies],
                                extraData : [item]
                            }) 
                        );                  
                      
                      }



                    };
                  
                  },
                  // item equip
                  (1): onAct(action:
                    BattleAction.new(state:{
                        ability: Ability.database.find(name:'Equip Item'),
                        targets: [user],
                        extraData : [item, party.inventory]
                    })                   
                  ),

                  
                  (2): ::<={ // inventory
                    dialogue.message(speaker:item.name, text:item.description, pageAfter:canvas.height-4);
                    
                  },
                  
                  // compare
                  (3)::<= {
                    @slot = user.getSlotsForItem(item)[0];
                    @currentEquip = user.getEquipped(slot);
                    
                    currentEquip.equipMod.printDiffRate(
                        prompt: '(Equip) ' + currentEquip.name + ' -> ' + item.name,
                        other:item.equipMod,
                        onNext::{}
                    ); 
                    
                    
                    
                  }
                };              
            
            }
        );
    });    
};
