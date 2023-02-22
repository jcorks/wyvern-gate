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
@:Entity = import(module:'class.entity.mt');
@:dialogue = import(module:'singleton.dialogue.mt');
@:Inventory = import(module:'class.inventory.mt');

return class(
    name: 'Wyvern.Party',
    
    define:::(this) {
        @:inventory = Inventory.new();
        @members = [];
        this.interface = {    
            add::(member => Entity.type) {
                // no repeats, please
                when(members->any(condition::(value) <- value == member)) empty;                
                member.inventory.items->foreach(do:::(index, item) {
                    inventory.add(item);                    
                });
                member.inventory.clear();


                members->push(value:member);
                
            },
            
            inventory : {
                get :: <- inventory
            },
            
            isMember::(entity => Entity.type) {
                return members->any(condition:::(value) <- value == entity);
            },
            
            remove::(member => Entity.type) {
                [::]{
                    members->foreach(do:::(index, m) {
                        if (m == member)::<={
                            members->remove(key:index);
                            dialogue.message(text:m.name + ' has been removed from the party.');
                            send();
                        };                        
                    });
                };
            },
            
            isIncapacitated :: {
                return members->all(condition:::(value) <- value.isIncapacitated());
            },
            
            
        
            members : {
                get ::<- members
            },
            
            state : {
                set ::(value) {
                    inventory.state = value.inventory;
                    members = [];
                    value.members->foreach(do:::(index, memberData) {
                        @member = Entity.new(levelHint: 0, state:memberData);
                        members->push(value:member);
                    });
                },
            
                get :: {
                    return {
                        inventory : inventory.state,
                        members: [...members]->map(to:::(value) <- value.state)
                    };
                }   
            }
        };
    }
);
