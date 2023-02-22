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
@:Random = import(module:'singleton.random.mt');


return class(
    name : 'Wyvern.Database',
    statics : {
        setup ::(item => Object, attributes => Object) {
            @:core = {};
            
            // default constructor that requires all 
            // entries to be specified and with the correct 
            // type.
            item.constructor = ::(data) {
                data->foreach(do:::(name, entry) {
                    when(attributes[name] == empty) 
                        error(detail: 'Unknown attribute ' + name + ' given to new instance.');


                    // yell at user for not adhering to the constructor types
                    ::(value => attributes[name]){}(value:entry);
                    core[name] = entry;
                });

                
                attributes->foreach(do:::(name, entry) {
                    when(core[name] == empty)
                        error(detail: 'Attribute ' + name + ' missing. Please check your constructor.');

                });
                
                return item;
            };
            
            // add getters
            @getters = {};
            attributes->foreach(do:::(name => String, entry) {
                getters[name] = {
                    get :: {
                        return core[name];
                    }
                };
            });
            item.interface = getters;
        }    
    },

    define:::(this) {
        @:items_ = {};
        this.constructor = ::(items) {
            items->foreach(do:::(index, item) {
                items_[item.name] = item;            
            });
            return this;
        };
        this.interface = {
            find ::(name) {
                @:item = items_[name];
                when(item == empty) error(detail: 'Unknown database item ' + name);
                return item;
            },
            
            getRandom :: {
                return Random.pickTableItem(table:items_);
            },

            getRandomWeighted :: {
                return Random.pickArrayItemWeighted(list:items_->values);
            },

            getRandomFiltered ::(filter => Function) {
                return Random.pickArrayItem(
                    list: (
                        items_->values->filter(by:filter)                   
                    )
                );
            },
            
            getRandomSet ::(count, filter => Function) {
                @:l = [];
                [0, count]->for(do:::(i) {
                    l->push(value:[::] {
                        forever(do:::{
                            @:choice = this.getRandomFiltered(filter);
                            if (l->all(condition:::(value) <- value != choice))                            
                                send(message:choice);
                        });
                    });
                });
                return l;            
            },

            getRandomWeightedFiltered ::(filter => Function) {
                return Random.pickArrayItemWeighted(
                    list: (
                        items_->values->filter(by:filter)                   
                    )
                );
            },

            
            getAll :: {
                return items_->values;
            }
            
            
        };
    }
);
