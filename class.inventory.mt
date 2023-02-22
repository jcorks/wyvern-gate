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

return class(
    name: 'Wyvern.Inventory',
    define:::(this) {


        @items = [];    
        @gold = 0;
    
        this.interface = {
            add::(item) {
                when (item.base.name == 'None') empty; // never accept None as a real item
                items->push(value:item);
                item.container = this;
            },
            
            remove::(item) {
                @:index = items->findIndex(value:item);
                when(index == -1) empty;
                
                items->remove(key:index);
                item.resetContainer();
                return item;
            },
            
            gold : {
                get ::<- gold,
            },
            
            addGold::(amount) {
                gold += amount;
            },
            
            subtractGold::(amount) {
                when(gold < amount) false;
                gold -= amount;
                return true;
            },
            clear :: {
                items = [];
            },
            
            items : {
                get :: {
                    return items;
                }
            },
            state: {
                set ::(value) {
                    @:Item = import(module:'class.item.mt');
                
                    gold = value.gold;
                    items = [];
                    value.items->foreach(do:::(i, itemData) {
                        @:item = Item.Base.database.find(name:itemData.baseName).new(state:itemData);
                        this.add(item);
                    });
                },
            
                get :: {
                    
                    return {
                        items: [...items]->map(to:::(value) <- value.state),
                        gold : gold
                    };
                }
            }
            
        };
    }
);
