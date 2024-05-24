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


@:Inventory = LoadableClass.create(
  name: 'Wyvern.Inventory',
  items : {
    items : empty,
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

      afterLoad :: {
        foreach(state.items) ::(k, item) {
          item.container = this;
        }
      },
      
      add::(item) {
        when (item.base.id == 'base:none') false; // never accept None as a real item
        when (state.items->keycount == state.maxItems) false;
        state.items->push(value:item);
        item.container = this;
        return true;
      },
      
      clone:: {
        @:out = Inventory.new();
        out.maxItems = state.maxItems;
        foreach(state.items) ::(k, item) {
          out.add(item);
        }
        out.addGold(amount:state.gold);
        return out;
      },
      
      remove::(item) {
        @:index = state.items->findIndex(value:item);
        when(index == -1) empty;
        
        state.items->remove(key:index);
        item.resetContainer();
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
      },
      
      items : {
        get :: {
          return state.items;
        }
      },
      
      isEmpty : {
        get ::<- state.items->keycount == 0
      },
      
      isFull : {
        get :: <- state.items->keycount >= state.maxItems
      },
      
      slotsLeft : {
        get ::<- state.maxItems - state.items->keycount
      },
      
      afterLoad ::{ 
        foreach(state.items) ::(k, item) {
          item.container = this;        
        }
      }
    }
  }
);
return Inventory;
