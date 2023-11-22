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

@:serialize = ::(value) {
    return match(value->type) {
      (Number, String, Boolean, Empty): value,
      
      default: ::<= {
        // database items are always saved as strings.
        when (value->isa(type:Database.Item.type))
            {
                ___isDatabase : true,
                database : '' + value->type,
                name : value.name
            };
        // tagged classes get instantiated and loaded with their state
        when (LoadableClass.isLoadable(name:String(from:value->type))) ::<= {
            @:output = value.save();
            output.___c = '' + value->type;
            return output;
        }
        
        if (value->type != Object)
            error(detail:
                'The only Object kinds allowed when serializing are plain objects/arrays, Database.Items, and LoadableClasses. This seems to be a class instance of some sort. Try making your class (' + value->type + ') a LoadableClass instead.'
            );

        if (value->size > 0) ::<= {
            @:arr = {};
            for(0, value->size) ::(i) {
                arr[i] = serialize(value:value[i]);
            }
            return arr;
        } else ::<= {
            return value.save();
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
        when(value.___c != empty) ::<= {
            @:cl = LoadableClass.load(name:value.___c);
            if (cl == empty)
                error(detail:'Looks like a save file contained a LoadableClass that hasnt been loaded yet or is missing entirely. Check your mods and check your save file version!');
            output[key] = (cl).new(parent, state:value);
        }
        when(value.___isDatabase != empty) ::<= {
            @:database = Database.Lookup[value.database];
            output[key] = database.find(name:value.name);
        }
        
      
        if (value->size > 0) ::<= {
            for(0, value->size) ::(i) {
                deserialize(
                    output:output[key],
                    key:i,
                    value:value[i]
                )
            }   
        } else ::<= {
            output[key].load(parent, serialized:value);
        }
      }
    }
}


return {
    new ::(items)  {
        @:keys = [];
        foreach(items) ::(k => String, value) {
            keys[k] = true;
        }
        
        @:output = {
            save :: {
                @:serialized = {};
                foreach(output) ::(key, value) {
                    serialized[key] = serialize(value);
                }
                return serialized;
            },
            
            load ::(parent, serialized) {
                if (parent == empty)
                    error(detail:'state loading parent MUST be present. (parent parameter must be set to something)');
                foreach(serialized) ::(key, value) {
                    deserialize(
                        parent, 
                        output,
                        key,
                        value
                    );
                }
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
