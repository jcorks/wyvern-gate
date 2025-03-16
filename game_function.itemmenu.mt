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
  @:world = import(:'game_singleton.world.mt');
  
  choiceNames->push(value:'Use');
  choices->push(value::{
    match(choiceItem.base.useTargetHint) {
      (Item.USE_TARGET_HINT.ONE): ::<={
        @:commit ::(who) {
          commitAction(action:BattleAction.new(
              card : ArtsDeck.synthesizeHandCard(id:'base:use-item'),
              targets: [who],
              extraData : [choiceItem],
              turnIndex : 0,
              targetParts : []
            ) 
          );              
          if (windowEvent.canJumpToTag(name:'Item'))
            windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
        
        }
      
      
        when (inBattle == false) ::<= {
      
          @:all = [];
          foreach(party.members)::(index, ally) {
            all->push(value:ally);
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
              commit(:all[choice-1]);
            }
          );        
        }
        
        // in battle variant
        @:all = [
          [...world.battle.getEnemies(:user)],
          [...world.battle.getAllies(:user)]
        ]
        
        @:allNames = [
          [...(world.battle.getEnemies(:user)->map(::(value) <- value.name))],
          [...(world.battle.getAllies (:user)->map(::(value) <- value.name))]        
        ]



        @:tabbedChoices = import(:'game_function.tabbedchoices.mt');
        @choice = tabbedChoices(
          leftWeight: if (leftWeight == empty) 1 else leftWeight,
          topWeight: if (topWeight == empty) 1 else topWeight,
          onGetTabs::<- [
            'Enemies',
            'Allies'
          ],
          onGetChoices::<- allNames,
          canCancel: true,
          keep: true,
          onChoice ::(choice, tab) {
            when(choice == 0) empty;            
            commit(:all[tab][choice-1]);
          }
        );
            
  
      },
      
      (Item.USE_TARGET_HINT.GROUP): ::<={
      
        @enemies
        @choices    
        @allies;    
        if (inBattle) ::<= {
          choices = [
            'Allies',
            'Enemies'
          ]
          enemies = world.battle.getEnemies(:user);
          allies  = world.battle.getAllies(:user)
        } else ::<= {
          choices = ['Allies'];
          allies = party.members;
        }
      
        @choice = windowEvent.queueChoices(
          leftWeight: if (leftWeight == empty) 1 else leftWeight,
          topWeight: if (topWeight == empty) 1 else topWeight,
          prompt: 'On whom?',
          choices,
          canCancel: true,
          keep : true,
          onChoice ::(choice) {
         
          when(choice == 0) empty;                          
            commitAction(action:BattleAction.new(
              card : ArtsDeck.synthesizeHandCard(id:'base:use-item'),
              targets: if (choice == 1) allies else enemies,
              extraData : [choiceItem],
              turnIndex : 0,
              targetParts : []
            ) 
          );          
          if (windowEvent.canJumpToTag(name:'Item'))
            windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
          
          }
        );
      },

      (Item.USE_TARGET_HINT.ALL): ::<= {
        @enemies = [];
        if (inBattle) ::<= {
          enemies = world.battle.getEnemies(:user)
        }
        commitAction(action:BattleAction.new(
            card : ArtsDeck.synthesizeHandCard(id:'base:use-item'),
            targets: [...party.members, ...enemies],
            extraData : [choiceItem],
            turnIndex : 0,
            targetParts : []
          ) 
        );          
        if (windowEvent.canJumpToTag(name:'Item'))
          windowEvent.jumpToTag(name:'Item', goBeforeTag:true, doResolveNext:true);
      
      },
      
      (Item.USE_TARGET_HINT.NONE): ::<= {
        commitAction(action:BattleAction.new(
            card : ArtsDeck.synthesizeHandCard(id:'base:use-item'),
            targets: [],
            extraData : [choiceItem],
            turnIndex : 0,
            targetParts : []
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
        extraData : [choiceItem, party.inventory],
        turnIndex : 0,
        targetParts : []
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


  choiceNames->push(value:'Mark Favorite');
  choices->push(value::{
    @:symbols = [
      'None',
      '&',
      '@',
      '!',
      '#',
      '$',
      '%',
      '^',
      '*',
      '+',
      '-'
    ]
    windowEvent.queueChoices(
      prompt: 'Mark with which symbol?',
      choices : symbols,
      canCancel : true,
      onChoice ::(choice) {
        when(choice == 1)
          choiceItem.faveMark = '';
          
        choiceItem.faveMark = symbols[choice-1];
      }
    );
  });
  
  
  choiceNames->push(value:'Rename');
  choices->push(value::{
    when (!choiceItem.base.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS))
      windowEvent.queueMessage(text:choiceItem.name + ' cannot be renamed.');
    
    @:name = import(module:"game_function.name.mt");
    name(
      prompt: 'Item name:',
      canCancel : true,
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
        when ((choiceItem.base.traits & Item.TRAIT.KEY_ITEM) != 0)
          windowEvent.queueMessage(
            text:'You feel unable to throw this away.'
          )
      
      
      
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
    tabbed: true,
    includeLoot : true,
    inventory:party.inventory,
    renderable, 
    leftWeight: if (leftWeight == empty) 1 else leftWeight,
    topWeight: if (topWeight == empty) 1 else topWeight,
    canCancel:true, 
    pageAfter:12,
    showRarity:true,
    header : ['Item', 'Value', ''],
    prompt: if (limitedMenu) 'Inventory...' else (user.name + ' - Choosing...'),
    onPick::(item) {
      choiceItem = item;
      when(choiceItem == empty) empty;
      windowEvent.queueChoices(
        leftWeight: if (leftWeight == empty) 1 else leftWeight,
        topWeight: if (topWeight == empty) 1 else topWeight,
        prompt: choiceItem.name,
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
