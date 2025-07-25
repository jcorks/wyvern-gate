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

@:LOOKUP = {};
@:ItemType = Object.newType(name:'Wyvern.Database.Item');

@:hasTraits::(items)   <- (_.traits & items) == items
@:hasAnyTrait::(items) <- (_.traits & items) != 0
@:hasNoTrait::(items)  <- (_.traits & items) == 0


@:Database = class(
  name : 'Wyvern.Database',
  statics : {
    Lookup : {
      get::<-LOOKUP
    },
    ItemType : {
      get ::<- ItemType
    },
    
    reset :: {
      foreach(LOOKUP) ::(name, database) {
        database.reset();
      }
    }
  },
  define:::(this) {
    @items_ = {}
    @itemsOrdered = [];
    @name_;
    @attributes_;
    @reset_;
    @:databaseNameGetter = {
      get ::<- name_
    };
    this.constructor = ::(attributes, name => String, reset => Function, statics) {
      LOOKUP[name] = this;
      name_ = name;
      attributes_ = attributes;
      reset_ = reset;
      
      if (statics != empty)
        this.interface = statics;
    };

    @:interface = {
      
      attributes : {
        get::<- attributes_
      },
      name : {
        get ::<- name_
      },
      reset :: {
        items_ = {};
        reset_();
      },      
      newEntry ::(data) {
        // preflight              
        @:item = Object.instantiate(type:ItemType);

        foreach(attributes_) ::(key, typ) {
          @val = data[key];
          when(key->type != String)
            error(detail:'Internal error: database attribute property key isnt a string!');
            
          when(typ->type != Type)
            error(detail:'Internal error: database attribute property isnt a type!');

          when(!val->isa(:typ))
            error(detail:'Internal error: database item property \"' + key + '\" should be of type ' + attributes_[key] + ', but received item of type ' + val->type);

          
          if (typ == Function)
            item[key] = val
          else 
            item[key] = {get::<-val}
        }             
        item.databaseName = databaseNameGetter;
        item.hasTraits = hasTraits;
        item.hasAnyTrait = hasAnyTrait;
        item.hasNoTrait = hasNoTrait;
        item->setIsInterface(enabled:true, private:item);
                
        items_[item.id] = item;
        itemsOrdered->push(:item.id);
      },

      remove ::(id) {
        items_->remove(key:id);
      },
    
      find ::(id) {
        @:item = items_[id];
        when(item == empty) error(detail: 'Unknown database item ID ' + id);
        return item;
      },

      findSoft ::(id) <- items_[id],

      
      getRandom :: {
        return Random.pickTableItem(table:items_);
      },

      getRandomWeighted ::(knockout)  {
        // knockout removes the weighted property and randomly returns something
        when (knockout != empty && Random.try(percentSuccess:knockout))
          Random.pickArrayItem(list:items_->values);
          
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
          l->push(value:::? {
            forever ::{
              @:choice = this.getRandomFiltered(filter);
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
              items_->values->filter(by:filter)           
            )          
          )
        ; 
        
        return Random.pickArrayItemWeighted(
          list: (
            items_->values->filter(by:filter)           
          )
        );
      },
      
      dumpCSV ::(titles, fieldFormatters, filename, sort, filter) {
        @:csv = [titles];
        
        @items = itemsOrdered->values->map(::(value) <- items_[value]);
        
        if (filter)
          items = items->filter(:filter);
        
        if (sort != empty)
          items->sort(:sort);
        
        foreach(items) ::(k, item) {
          @:row = [];
          foreach(titles) ::(i, title) {
            row->push(:fieldFormatters[title](item));
          }
          csv->push(:row);
        }
        
        @:strings = [];
        foreach(csv) ::(k, row) {
          foreach(row) ::(i, cell) {
            strings->push(:'"'+cell+'"');
            strings->push(:',');
          }
          strings->push(:'\n');
        };
        
        @:Filesystem = import(:'Matte.System.Filesystem');
        Filesystem.writeString(path:filename, string:String.combine(:strings));
      },

      
      getAll :: {
        return items_->values;
      }
    }
    
    
    
    this.interface = interface;
  }
);
return Database;
