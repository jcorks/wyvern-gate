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
@:lclass = import(module:'Matte.Core.Class');
@:Random = import(module:'game_singleton.random.mt');

@:Item2Database = {};
@:LOOKUP = {};
@:ItemType = Object.newType(name:'Wyvern.Database.Item');

@:databaseNameGetter = {
    get ::<- name_
};


@:Database = lclass(
    name : 'Wyvern.Database',
    statics : {
        Lookup : LOOKUP
        ItemType : ItemType        
        reset :: {
            foreach(LOOKUP) ::(name, database) {
                database.reset();
            }
        }
    },

    constructor::(attributes, name => String, reset => Function, statics) {
        LOOKUP[name] = this;
        _.name = name;
        _.attributes = attributes;
        _.reset = reset;
        _.statics = statics;
        _.items = {};
    };

    interface = {

        attributes : {
            get::<- _.attributes
        },
        name : {
            get ::<- _.name
        },
        reset :: {
            _.items = {};
            _.reset();
        },            
        newEntry ::(data) {
            // preflight                            
            @:item = Object.instantiate(type:ItemType);

            foreach(_.attributes) ::(key, typ) {
                @val = data[key];
                when(val == empty)
                    error(detail:'Internal error: database item is missing property ' + key);

                when(key->type != String)
                    error(detail:'Internal error: database attribute property key isnt a string!');
                    
                when(typ->type != Type)
                    error(detail:'Internal error: database attribute property isnt a type!');

                when(typ != val->type)
                    error(detail:'Internal error: database item property should be of type ' + attributes_[key] + ', but received item of type ' + val->type);

                
                if (typ == Function)
                    item[key] = val
                else 
                    item[key] = {get::<-val}
            }                         
            item.databaseName = databaseNameGetter;
            item->setIsInterface(enabled:true);
            
            items_[item.id] = item;
        },

        remove ::(id) {
            _.items->remove(key:id);
        },
    
        find ::(id) {
            @:item = _.items[id];
            when(item == empty) error(detail: 'Unknown database item ID ' + id);
            return item;
        },
        
        getRandom :: {
            return Random.pickTableItem(table:_.items);
        },

        getRandomWeighted ::(knockout)  {
            // knockout removes the weighted property and randomly returns something
            when (knockout != empty && Random.try(percentSuccess:knockout))
                Random.pickArrayItem(list:_.items->values);
                
            return Random.pickArrayItemWeighted(list:_.items->values);
        },

        getRandomFiltered ::(filter => Function) {
            return Random.pickArrayItem(
                list: (
                    _.items->values->filter(by:filter)                   
                )
            );
        },
        
        getRandomSet ::(count, filter => Function) {
            @:l = [];
            for(0, count)::(i) {
                l->push(value:{:::} {
                    forever ::{
                        @:choice = _.this.getRandomFiltered(filter);
                        if (l->all(condition:::(value) <- value != choice))                            
                            send(message:choice);
                    }
                });
            }
            return l;            
        },

        getRandomWeightedFiltered ::(filter => Function, knockout) {
            // knockout removes the weighted property and randomly returns something
            when (knockout != empty && Random.try(percentSuccess:knockout))
                Random.pickArrayItem(
                    list: (
                        _.items->values->filter(by:filter)                   
                    )                    
                )
            ; 
            
            return Random.pickArrayItemWeighted(
                list: (
                    _.items->values->filter(by:filter)                   
                )
            );
        },

        
        getAll :: {
            return _.items->values;
        },
        
        statics : {
            get ::<- _.statics
        }
    }
);
return Database;
