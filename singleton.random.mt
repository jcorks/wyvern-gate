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
    name : 'Wyvern.random',
    
    define:::(this) {
        this.interface = {
            integer::(from, to) {
                return from + (Number.random() * ((to+1)-from))->floor;
            },
            
            range::(from, to) {
                return from + (Number.random() * ((to+1)-from));
            },
        
            pickArrayItem::(list) {
                return list[this.integer(from:0, to:list->keycount-1)];
            },

            pickTableItem::(table) {
                return table[this.pickArrayItem(list:table->keys)];
            },
            
            pickArrayItemWeighted::(list) {
                @:weightTable = [];
                @totalWeight = 0;
                list->foreach(do:::(index, item) {
                    weightTable[index] = totalWeight;
                    totalWeight += 1 / item.rarity;
                });
                weightTable[list->keycount] = totalWeight;
                
                @:which = Number.random()*totalWeight;

                return list[ 
                    [::]{
                        [0, weightTable->keycount-1]->for(do:::(index) {
                            when(which > weightTable[index] &&
                                 which < weightTable[index+1])
                                send(message:index);
                            
                        });
                        return weightTable->length-1;
                    } 
                ];
            }
            

        };
    }
).new();
