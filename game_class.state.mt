@:serialize = ::(value) {
    return match(value->type) {
      (Number, String, Boolean): value,
      
      (Object) : if (value->size > 0) ::<= {
            @:arr = {};
            for(0, value->size) ::(i) {
                arr[i] = serialize(value[i]);
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
      (Number, String, Boolean):::<= {
        output[key] = value
      },
      
      (Object):::<= {
        if (value->size > 0) ::<= {
            for(0, value->size) ::(i) {
                deserialize(
                    output[key],
                    i,
                    value[i]
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
