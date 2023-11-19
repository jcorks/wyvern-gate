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
@:Entity = import(module:'game_class.entity.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Inventory = import(module:'game_class.inventory.mt');

return class(
    name: 'Wyvern.Party',
    
    define:::(this) {
        @inventory;
        @members = [];
        this.interface = {    
            reset ::{
                members = [];
                inventory = Inventory.new(size:20);
            },
        
            add::(member => Entity.type) {
                // no repeats, please
                when(members->any(condition::(value) <- value == member)) empty;                
                /*
                member.inventory.items->foreach(do:::(index, item) {
                    inventory.add(item);                    
                });
                member.inventory.clear();
                */

                members->push(value:member);
                
            },
            
            inventory : {
                get :: <- inventory
            },
            
            isMember::(entity => Entity.type) {
                return members->any(condition:::(value) <- value == entity);
            },
            
            remove::(member => Entity.type) {
                {:::}{
                    foreach(members)::(index, m) {
                        if (m == member)::<={
                            members->remove(key:index);
                            windowEvent.queueMessage(text:m.name + ' has been removed from the party.');
                            send();
                        }                        
                    }
                }
            },
            
            isIncapacitated :: {
                return members->all(condition:::(value) <- value.isIncapacitated());
            },
            
            
        
            members : {
                get ::<- members
            },
            
            clear :: {
                inventory.clear();
                members = [];            
            },
            
            state : {
                set ::(value) {
                    inventory.state = value.inventory;
                    members = [];
                    foreach(value.members)::(index, memberData) {
                        @member = Entity.new(levelHint: 0, state:memberData);
                        members->push(value:member);
                    }
                },
            
                get :: {
                    return {
                        inventory : inventory.state,
                        members: [...members]->map(to:::(value) <- value.state)
                    }
                }   
            }
        }
    }
);
