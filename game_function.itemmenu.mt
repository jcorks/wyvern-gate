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
@:Arts = import(module:'game_database.arts.mt');
@:pickItem = import(module:'game_function.pickitem.mt');
@:ArtsDeck = import(:'game_class.artsdeck.mt');


return ::(
  user,
  party,
  enemies,
  renderable,
  onAct => Function,
  inBattle => Boolean,
  topWeight,
  leftWeight,
  limitedMenu
) {
  @:Item = import(module:'game_mutator.item.mt');
  
  @:commitAction ::(action) {
    onAct(action);  
  }
  
  @:choiceNames = [];
  @:choices = [];
  @choiceItem;
  
  choiceNames->push(value:'Use');
  choices->push(value::{
    match(choiceItem.base.useTargetHint) {
      (Item.database.statics.USE_TARGET_HINT.ONE): ::<={
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
        
        
        @choice = windowEvent.queueChoices(
          leftWeight: if (leftWeight == empty) 1 else leftWeight,
          topWeight: if (topWeight == empty) 1 else topWeight,
          prompt: 'On whom?',
          choices: allNames,
          canCancel: true,
          keep: true,
          onChoice ::(choice) {
          when(choice == 0) empty;            
          commitAction(action:BattleAction.new(
              card : ArtsDeck.synthesizeHandCard(id:'base:use-item'),
              targets: [all[choice-1]],
              extraData : [choiceItem]
            ) 
          );              
          if (windowEvent.canJumpToTag(name:'Item'))
            windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);

          }
        );
        
  
      },
      
      (Item.database.statics.USE_TARGET_HINT.GROUP): ::<={
        @choice = windowEvent.queueChoices(
          leftWeight: if (leftWeight == empty) 1 else leftWeight,
          topWeight: if (topWeight == empty) 1 else topWeight,
          prompt: 'On whom?',
          choices: [
          'Allies',
          'Enemies'
          ],
          canCancel: true,
          keep : true,
          onChoice ::(choice) {
         
          when(choice == 0) empty;                          
          commitAction(action:BattleAction.new(
              card : ArtsDeck.synthesizeHandCard(id:'base:use-item'),
              targets: if (choice == 1) party.members else enemies,
              extraData : [choiceItem]
            ) 
          );          
          if (windowEvent.canJumpToTag(name:'Item'))
            windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
          
          }
        );
      },

      (Item.database.statics.USE_TARGET_HINT.ALL): ::<= {
        commitAction(action:BattleAction.new(
            card : ArtsDeck.synthesizeHandCard(id:'base:use-item'),
            targets: [...party.members, ...enemies],
            extraData : [choiceItem]
          ) 
        );          
        if (windowEvent.canJumpToTag(name:'Item'))
          windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
      
      },
      
      (Item.database.statics.USE_TARGET_HINT.NONE): ::<= {
        commitAction(action:BattleAction.new(
            card : ArtsDeck.synthesizeHandCard(id:'base:use-item'),
            targets: [],
            extraData : [choiceItem]
          ) 
        );          
        if (windowEvent.canJumpToTag(name:'Item'))
          windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
      
      }      



    }  
  });
  
  
  
  choiceNames->push(value:'Check');
  choices->push(value::{
    choiceItem.describe(
      by:user
    );  
  });
  
  
  if (limitedMenu != true) ::<= {
    choiceNames->push(value:'Equip');
    choices->push(value::{
      commitAction(action:BattleAction.new(
        card : ArtsDeck.synthesizeHandCard(id:'base:equip-item'),
        targets: [user],
        extraData : [choiceItem, party.inventory]
      ));       
      if (windowEvent.canJumpToTag(name:'Item'))
        windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);      
    });  
    
    
    choiceNames->push(value:'Compare');
    choices->push(value::{
      @slot = user.getSlotsForItem(item:choiceItem)[0];
      @currentEquip = user.getEquipped(slot);
      
      currentEquip.equipMod.printDiffRate(
        prompt: '(Equip) ' + currentEquip.name + ' -> ' + choiceItem.name,
        other:choiceItem.equipMod
      );     
    });
  }
  
  
  choiceNames->push(value:'Rename');
  choices->push(value::{
    when (!choiceItem.base.canHaveEnchants)
      windowEvent.queueMessage(text:choiceItem.name + ' cannot be renamed.');
    
    @:name = import(module:"game_function.name.mt");
    name(
      prompt: 'Item name:',
      onDone::(name) {
        choiceItem.name = name;
        if (windowEvent.canJumpToTag(name:'Item'))
          windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
      }
    );  
  });
  
  
  
  choiceNames->push(value:'Improve');
  choices->push(value::{
    (import(module:'game_function.itemimprove.mt'))(user, item:choiceItem, inBattle);   
  });
  
  choiceNames->push(value:'Toss');
  choices->push(value::{
    windowEvent.queueAskBoolean(
      prompt:'Are you sure you wish to throw away the ' + choiceItem.name + '?',
      onChoice::(which) {
        when(which == false) empty;
        party.inventory.remove(item:choiceItem);
        
        if (choiceItem.name->contains(key:'Wyvern Key of')) ::<= {
          @:world = import(module:'game_singleton.world.mt')
          world.accoladeEnable(name:'gotRidOfWyvernKey');    
        }
                      
        windowEvent.queueMessage(text:'The ' + choiceItem.name + ' was thrown away.');
        if (windowEvent.canJumpToTag(name:'Item'))
          windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
      }
    );  
  });
  
  

  pickItem(
    inventory:party.inventory,
    renderable, 
    leftWeight: if (leftWeight == empty) 1 else leftWeight,
    topWeight: if (topWeight == empty) 1 else topWeight,
    canCancel:true, 
    pageAfter:12,
    prompt: if (limitedMenu) 'Inventory...' else (user.name + ' - Choosing...'),
    onPick::(item) {
      choiceItem = item;
      when(choiceItem == empty) empty;
      windowEvent.queueChoices(
        leftWeight: if (leftWeight == empty) 1 else leftWeight,
        topWeight: if (topWeight == empty) 1 else topWeight,
        prompt: '[' + choiceItem.name + ']',
        canCancel : true,
        keep:true,
        jumpTag: 'Item',
        renderable,
        choices: choiceNames,
        onChoice::(choice) {
          when (choice == 0) empty;        
          choices[choice-1]();       
        }
      );
    }
  );  
}
