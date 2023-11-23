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

/*
    Solution for standard serialization.
    Primarily used for saving and loading
*/


@:Database = import(module:'game_class.database.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

@:SPARSE_THRESHOLD = 30;

@:TAG__IS_DATABASE = '$id';
@:TAG__LOADABLE_CLASS = '$c';
@:TAG__SPARSE_ARRAY = '$sa';

@:serialize = ::(value) {
    return match(value->type) {
      (Number, String, Boolean, Empty): value,
      
      (Function): error(detail:'Functions are not allowed to be serialized'),
      
      default: ::<= {
        // database items are always saved as strings.
        when (value->isa(type:Database.Item.type))
            {
                (TAG__IS_DATABASE) : true,
                database : '' + value->type,
                name : value.name
            };
        // tagged classes get instantiated and loaded with their state
        when (LoadableClass.isLoadable(name:String(from:value->type))) ::<= {
            @:output = value.save();
            output[TAG__LOADABLE_CLASS] = '' + value->type;
            return output;
        }
        
        if (value->type != Object)
            error(detail:
                'The only Object kinds allowed when serializing are plain objects/arrays, Database.Items, and LoadableClasses. This seems to be a class instance of some sort. Try making your class (' + value->type + ') a LoadableClass instead.'
            );

        return if (value->size > 0) ::<= {
            @arr = {};
            @emptyCount = 0;
            {:::} {
                for(0, value->size) ::(i) {
                    when(emptyCount > SPARSE_THRESHOLD) ::<= {
                        arr = empty;
                        send();
                    }
                        
                    if (value[i] == empty)
                        emptyCount += 1;
                    arr[i] = serialize(value:value[i]);
                }
            }
            
            // sparse array
            if (arr == empty) ::<= {
                arr = {(TAG__SPARSE_ARRAY):true};
                for(0, value->size) ::(i) {
                    when (value[i] == empty) empty
                    arr[''+i] = serialize(value:value[i]);
                }
            }
            
            return arr;
        } else ::<= {
            @:arr = {};
            foreach(value) ::(k => String, v) {
                arr[k] = serialize(value:v);
            }
            return arr;
        }
      }
    }

}


@:deserialize = ::(parent, output, key, value) {
    match(value->type) {
      (Number, String, Boolean, Empty):::<= {
        output[key] = value
      },
      
      default: ::<= {
        when(value[TAG__LOADABLE_CLASS] != empty) ::<= {
            @:cl = LoadableClass.load(name:value[TAG__LOADABLE_CLASS]);
            if (cl == empty)
                error(detail:'Looks like a save file contained a LoadableClass that hasnt been loaded yet or is missing entirely. Check your mods and check your save file version!');
            output[key] = (cl).new(parent, state:value);
        }
        when(value[TAG__IS_DATABASE] != empty) ::<= {
            @:database = Database.Lookup[value.database];
            output[key] = database.find(name:value.name);
        }
        
        when(value[TAG__SPARSE_ARRAY] != empty) ::<= {
            @:out = [];
            for(0, value->size) ::(i) {
                deserialize(
                    parent,
                    output:out,
                    key:Number.parse(string:i),
                    value:value[i]
                )
            }   
            output[key] = out;
        }
      
        if (value->size > 0) ::<= {
            @:out = [];
            for(0, value->size) ::(i) {
                deserialize(
                    parent,
                    output:out,
                    key:i,
                    value:value[i]
                )
            }   
            output[key] = out;            
        } else ::<= {
            @:out = [];
            foreach(value) ::(k, v) {
                deserialize(
                    parent,
                    output:out,
                    key:k,
                    value:v
                )
            }   
            output[key] = out;            
        }
      }
    }
}


return {
    new ::(items)  {
        @:keys = {'save':true, 'load':true};
        foreach(items) ::(k => String, value) {
            keys[k] = true;
        }
        
        @:output = {};
        items.save = :: {
            @:serialized = {};
            foreach(items) ::(key, value) {
                when(key == 'save' || key == 'load') empty; // skip
                serialized[key] = serialize(value);
            }
            return serialized;
        };
            
        items.load = ::(parent, serialized) {
            if (parent == empty)
                error(detail:'state loading parent MUST be present. (parent parameter must be set to something)');
            foreach(serialized) ::(key, value) {
                deserialize(
                    parent, 
                    output:items,
                    key,
                    value
                );
            }
        }
        
        output->setAttributes(
            attributes : {
                '.' : {
                    set ::(key, value) {
                        if (keys[key] == empty)
                            error(detail:'State has no member named ' + key);
                        items[key] = value;
                    },
                    
                    get ::(key) {
                        if (keys[key] == empty)
                            error(detail:'State has no member named ' + key);
                        return items[key];                    
                    }
                }   
            }
        )
        
        return output;
    }
}
