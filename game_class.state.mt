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

@:SPARSE_THRESHOLD = 30;

@:TAG__IS_DATABASE = '$id';
@:TAG__LOADABLE_CLASS = '$c';
@:TAG__SPARSE_ARRAY = '$sa';
@:TAG__WEIGHT = "$w";
@:TAG__ID = "$key";

@:isTag = {};
isTag[TAG__IS_DATABASE] = true;
isTag[TAG__LOADABLE_CLASS] = true;
isTag[TAG__SPARSE_ARRAY] = true;

@ALREADY_SERIALIZED = empty;

@:weight ::(s) {
  @key = 1;
  foreach(s) ::(k, v) {
    when(k->type != String) empty;
    key += k->length + match(v->type) {
      (Number): v->floor,
      (String): v->length,
      (Object): 
        if (v[TAG__WEIGHT] != empty) 
          v[TAG__WEIGHT]
        else
          0
      ,
      default: 1
    }
  }
  return key;
}

@:serialize = ::(value) {
  @:LoadableClass = import(module:'game_singleton.loadableclass.mt');
  return match(value->type) {
    (Number, String, Boolean, Empty): value,
    
    (Function): error(detail:'Functions are not allowed to be serialized'),
    
    default: ::<= {
      when (ALREADY_SERIALIZED != empty && ALREADY_SERIALIZED[value]) ::<= {
        {:::} {
          @:h = value.worldID;
          if (value.worldID->type != Number)
            error();
            
        } : {
          onError::(message) {
            error(detail:'Only classes with a worldID can be serialized multiple times. Please ensure that only one copy of non-worldID objects get saved.');
          }
        }

        return {
          (TAG__ID) : value.worldID
        }
        //error(detail:'Already serialized object! likely infinite recursion (or at the very least erroneous instance copies)');
      }

      @:obj = {:::} {
        // database items are always saved as strings.
        when (value->isa(type:Database.ItemType))
          {
            (TAG__IS_DATABASE) : true,
            database : value.databaseName,
            id : value.id
          };

        if (ALREADY_SERIALIZED != empty) ::<= {
          ALREADY_SERIALIZED[value] = true;
        }

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
      
      return obj;
    }
  }

}


@:deserialize = ::(parent, output, key, value) {
  @:LoadableClass = import(module:'game_singleton.loadableclass.mt');
  match(value->type) {
    (Number, String, Boolean, Empty):::<= {
      when(isTag[key]) empty;
      output[key] = value
    },

    
    default: ::<= {
      
      ::<= {
        when(value[TAG__ID] != empty) ::<= {
          output[key] = ALREADY_SERIALIZED[value[TAG__ID]];
          if (output[key] == empty)
            error(:"Somehow, a worldID object has its copy requested before the source appeared. Not sure how this happened!");
        }
        when(value[TAG__LOADABLE_CLASS] != empty) ::<= {
          @:cl = LoadableClass.load(name:value[TAG__LOADABLE_CLASS]);
          if (cl == empty)
            error(detail:'Looks like a save file contained a LoadableClass that hasnt been loaded yet or is missing entirely. Check your mods and check your save file version!');
          output[key] = (cl).new(parent, state:value);
        }
        when(value[TAG__IS_DATABASE] != empty) ::<= {
          @:database = Database.Lookup[value.database];
          output[key] = database.find(id:value.id);
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
      {:::} {
        if ((output[key]->keys->filter(::(value) <- value->type == String)->findIndex(:'worldID')) != -1)
          if (ALREADY_SERIALIZED != empty)
            ALREADY_SERIALIZED[output[key].worldID] = output[key]
      } : {
        onError::(message) {
          // nuthin
        }
      }
    }
  }
}


@:State = {
  startRootSerializeGuard ::{
    ALREADY_SERIALIZED = [];
  },
  
  weightEmplace ::(data) {
    @:next ::(serialized) {
      if (serialized->keys->size != 0) ::<= {
        serialized->remove(:TAG__WEIGHT);      
        {:::} {
          foreach(serialized) ::(k, v) {
            when(v->type != Object) empty;
            next(:v)
          }
        }
        if (serialized->size == 0)
          serialized[TAG__WEIGHT] = weight(:serialized);
      }
    }
    next(:data);
  },
  
  
  // The universe tends to prefer its order. You have been warned.
  weightCheck ::(data) {
    @:next ::(serialized) {
      when(serialized->keys->size == 0) true;
    
      @:realWeight = serialized[TAG__WEIGHT];
      serialized->remove(:TAG__WEIGHT);
      @:weight0 = weight(:serialized);

      @h = true;      
      foreach(serialized) ::(k, v) {
        when(v->type != Object) empty;
        if (next(:v) == false)
          h = false;
      }
      if (serialized->size == 0) ::<= {
        if (realWeight != weight0) ::<= {
          h = false;
          //breakpoint();
        }
      }
      return h;
    }  
    return next(:data);
  },
  
  endRootSerializeGuard ::{
    ALREADY_SERIALIZED = empty;
  },
  
  create ::(items) {

    items.save = ::($) {
      @:serialized = {};
      foreach($) ::(key, value) {
        when(key == 'save' || key == 'load') empty; // skip
        serialized[key] = serialize(value);
      }      
      return serialized;
    };
      
    items.load = ::($, parent, loadFirst, serialized) {

      @:output = $;// free clone
      if (parent == empty)
        error(detail:'state loading parent MUST be present. (parent parameter must be set to something)');
      
      when(loadFirst == empty) ::<= {
        foreach(serialized) ::(key, value) {
          deserialize(
            parent, 
            output,
            key,
            value
          );
        }
      }
      
      @:loaded = {};
      foreach(loadFirst) ::(i, key) {
        deserialize(
          parent, 
          output,
          key,
          value:serialized[key]
        );
        loaded[key] = true;
      }
      foreach(serialized) ::(key, value) {
        when(loaded[key] != empty) empty;
        deserialize(
          parent, 
          output,
          key,
          value
        );
      }
    }    
    @:types = {};
    
    
    foreach(items) ::(k, v) {
      types[k] = if (v == empty) Nullable else v->type;
    }
    @:type = Object.newType(
      layout : types,
      name : 'State'
    );
        
    
    return {
      type : type,
      new ::{
        @:obj = Object.instantiate(type);
        foreach(items) ::(k, v){
          obj[k] = v;
        }
        return obj;
      }
    }
  }
}
return State;
