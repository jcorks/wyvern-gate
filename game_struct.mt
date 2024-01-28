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

return ::(
    name => String,
    items => Object,
    readOnly
) {
    @:type = Object.newType(name);
    @:itemNames = items->keys;
    @:itemTypes = {...items}

    @:int = {
        new ::(*state) {
            @:initialized = {}
            foreach(itemNames)::(index, value) {
                initialized[value] = false;
            }
            
            @:data = {}
            foreach(state)::(name, value) {
                when (initialized[name] == empty)
                    error(detail:'"' + name + '" is not a member of the structure ' + String(from:type));

                when (itemTypes[name] != value->type)
                    error(
                        detail:'"' + name + '" should be of type ' 
                        + String(from:itemTypes[name]) +  
                        ', but given value was of type ' +
                        String(from:value->type)
                    );
                data[name] = value;
                initialized[name] = true;
            }
               
            /*
            foreach(in:initialized, do:::(name, initialized) {
                if (initialized != true)
                    error(detail:'"' + name + '" was never initialized in constructor.');
            });  
            */
            
            @:out = Object.instantiate(type);
            
            
            @:reactor = {
                get ::(key) {
                    if (initialized[key] == empty)
                        error(detail:'"' + key + '" is not a member of the structure ' + String(from:type));
                    return data[key];
                },

                set: if (readOnly) 
                            ::(key, value) {
                                error(detail:'Structure ' + String(from:type) + ' is read-only.'); 
                            }
                        else
                            ::(key, value) {
                                when (initialized[key] == empty)
                                    error(detail:'"' + name + '" is not a member of the structure ' + String(from:type));
                            
                                data[key] = value;
                            }
            }
            
            out->setAttributes(
                attributes : {
                    '[]' : reactor,
                    '.'  : reactor,
                    foreach ::<- data,
                    values  ::<- data->values,
                    keys    ::<- data->keys                                                    
                }
            );  
            
            
            return out;
        }
    }
    int->setIsInterface(enabled:true);
    return int;
    
    
}
