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
@:class = import(module:'Matte.Core.Class');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');


@:partyDiscardItem ::(this) {
  @:world = import(module:'game_singleton.world.mt');
  @:windowEvent = import(module:'game_singleton.windowevent.mt');
  @:g = import(module:'game_function.g.mt');

  windowEvent.queueNestedResolve(
    jumpTag : 'DISCARD_ITEM',
    onEnter ::{
      when(this.items->keycount <= this.maxItems) empty;
      @:tooMany = (this.items->keycount - this.maxItems);
          
      windowEvent.queueMessage(
        text: 'The party\'s inventory is full.' 
      );
      windowEvent.queueMessage(
        text: 'Please discard ' + (if (tooMany == 1) 'an item ' else ''+tooMany+ ' items ') + 'to continue.'
      );

      @:pickItem = import(module:'game_function.pickitem.mt');

      pickItem(
        tabbed: true,
        includeLoot : true,
        inventory:this,
        leftWeight: 0.5,
        topWeight: 0.5,
        canCancel:false, 
        keep: true,
        pageAfter:12,
        showRarity:true,
        header : ['Item', 'Value', ''],
        prompt: 'Discard which?',
        onGetFooter ::<- '(Need to discard :' + (this.items->keycount - this.maxItems) + ' items.)',
        onPick::(item) {
          @choiceItem = item;
          when(choiceItem == empty) empty;
          
          windowEvent.queueChoices(
            leftWeight: 0.5,
            topWeight: 0.5,
            prompt: choiceItem.name,
            canCancel : true,
            jumpTag : 'DISCARD_ITEM_SUB',
            keep : true,
            choices: ['Check', 'Discard'],
            onChoice::(choice) {
              when (choice == 0) empty;        
              when(choice == 1) 
                item.describe()
                
              when(choice == 2)
                windowEvent.queueAskBoolean(
                  prompt: 'Are you sure you want to discard the ' + choiceItem.name + '?',
                  onChoice ::(which) {
                    when (which == false) empty;
                    this.remove(:choiceItem);

                    when(this.items->keycount <= this.maxItems)
                      windowEvent.jumpToTag(name:'DISCARD_ITEM');
                    windowEvent.jumpToTag(name:'DISCARD_ITEM_SUB', goBeforeTag:true);
                  }
                );
            }
          );
        }
      ); 


    }
  );
}

@:Inventory = LoadableClass.create(
  name: 'Wyvern.Inventory',
  items : {
    items : empty,
    loot : empty,
    gold : 0,
    maxItems : 0
  },
  define:::(this, state) {
   
    this.interface = {
      initialize ::{
      },
      
      defaultLoad::(size) {
        state.maxItems = 10;
        if (size != empty)
          this.maxItems = size;            
        state.items = [];
        state.gold = 0;
      },
      
      add::(item) {
        when (item.base.id == 'base:none') false; // never accept None as a real item
        when (item.base.id == 'base:item-box') ::<= {
          if (state.loot == empty)
            state.loot = [];
          state.loot->push(:item);
          return true;
        }
        
        state.items->push(value:item);
        
        // special case for party's inventory
        when (state.items->keycount > state.maxItems) ::<= {
          @:world = import(module:'game_singleton.world.mt');
          when(this != world.party.inventory) ::<= {
            this.remove(:item);
            return false;
          }
          
          partyDiscardItem(this);
        }
        
        return true;
      },
      
      clone:: {
        @:out = Inventory.new();
        out.maxItems = state.maxItems;
        foreach([...state.items, ...(if(state.loot)state.loot  else [])]) ::(k, item) {
          out.add(item);
        }

        out.addGold(amount:state.gold);
        return out;
      },
      
      remove::(item) {
        @:index = state.items->findIndex(value:item);
        when(index == -1) ::<= {
          when(state.loot == empty) empty;
          
          @:index = state.loot->findIndex(value:item);
          when(index == -1) empty;

          state.loot->remove(key:index);
          return item;
        }
        
        state.items->remove(key:index);
        return item;
      },
      
      removeByID::(id) {
        {:::} {
          foreach(state.items)::(i, item) {
            if (item.base.id == id) ::<= {
              state.items->remove(key:i);
              send();
            }
          }
        }
      },
      
      maxItems : {
        set ::(value) {
          state.maxItems = value;
        },
        
        get ::<- state.maxItems
      },
      
      gold : {
        get ::<- state.gold,
      },
      
      addGold::(amount) {
        state.gold += amount;
      },
      
      subtractGold::(amount) {
        when(state.gold < amount) false;
        state.gold -= amount;
        return true;
      },
      clear :: {
        state.items = [];
        state.loot = empty;
        state.gold = 0;
      },
      
      items : {
        get :: {
          state.items = state.items->filter(::(value) <- value.base.id != 'base:none');
          return [...state.items];
        }
      },
      
      loot : {
        get :: {
          when(state.loot == empty) [];
          return [...state.loot]
        }
      },
      
      clearLoot :: {
        state.loot = empty;
      },
      
      
      isEmpty : {
        get ::<- this.items->keycount == 0
      },
      
      isFull : {
        get :: <- this.items->keycount >= state.maxItems
      },
      
      slotsLeft : {
        get ::<- state.maxItems - this.items->keycount
      }
    }
  }
);
return Inventory;
