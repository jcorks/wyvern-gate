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


@:deserialize = ::(output, key, value) {
    match(value->type) {
      (Number, String, Boolean, Empty):::<= {
        output[key] = value
      },
      
      default: ::<= {
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
            output[key].load(serialized:value);
        }
      }
    }
}


return {
    new :: {
        @:output = {
            save :: {
                @:serialized = {};
                foreach(output) ::(key, value) {
                    serialized[key] = serialize(value);
                }
                return serialized;
            },
            
            load ::(serialized) {
                foreach(serialized) ::(key, value) {
                    deserialize(
                        output,
                        key,
                        value
                    );
                }
            }
        }
        
        return output;
    }
}
