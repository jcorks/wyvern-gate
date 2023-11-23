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
@:Random = import(module:'game_singleton.random.mt');

@:Item2Database = {};
@:LOOKUP = {};

@:Database = class(
    name : 'Wyvern.Database',
    statics : {
        Lookup : {
            get::<-LOOKUP
        },
        Item : ::<= {
            @:Item = class(
                define::(this) {
                    @data_;
                    @database_;
                    @attribs;
                    this.interface = {
                    
                        initialize ::(data) {
                            if (database_ == empty)
                                error(detail:'Internal error: database not bound to item. Maybe didnt call database.bind in item define()?');

                            // preflight                            
                            foreach(attribs) ::(key, typ) {

                                @val = data[key];
                                when(val == empty)
                                    error(detail:'Internal error: database item is missing property ' + key);

                                when(key->type != String)
                                    error(detail:'Internal error: database attribute property key isnt a string!');
                                    
                                when(typ->type != Type)
                                    error(detail:'Internal error: database attribute property isnt a type!');

                                when(typ != val->type)
                                    error(detail:'Internal error: database item property should be of type ' + attribs[key] + ', but received item of type ' + val->type);
                            }                         
                            data_ = data;
                            database_.bind(item:this);
                        },
                        
                        // gathers the expected interface of attributes in the database item,
                        // setting up the interface with getters for those properties.
                        bindData ::(database => Database.type) {
                            database_ = database;
                            attribs = database.attributes;
                            
                            if (this.interface == empty)
                                this.interface = {};

                            foreach(attribs) ::(key, val) {
                                this.interface[key] = {
                                    get ::<- data_[key]
                                }
                            }
                        }
                    }
                }
            );
            return {get::<-Item};
        },
    
   
    },
    new ::(attributes, name) {
        @this = Database.defaultNew();
        LOOKUP[name] = this;
        this.initialize(attributes);
        return this;
    },
    define:::(this) {
        @:items_ = {}
        @attributes_;
        this.interface = {
            initialize::(attributes => Object) {
                attributes_ = attributes;
                return this;
            },
            
            attributes : {
                get::<- attributes_
            },
            
            bind::(item) {
                items_[item.name] = item;
            },            
            add::(item) {
                item.bindData(database:this);
            },
        
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
                for(0, count)::(i) {
                    l->push(value:{:::} {
                        forever ::{
                            @:choice = this.getRandomFiltered(filter);
                            if (l->all(condition:::(value) <- value != choice))                            
                                send(message:choice);
                        }
                    });
                }
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
            
            
        }
    }
);
return Database;
