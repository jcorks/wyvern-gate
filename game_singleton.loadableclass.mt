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
  Loadable classes can be revived automatically from serialization loading

  Includes a state instance (initialized with the create() items argument)
  and provides default for saving / loading (through save() and load()) if desired.
  These can be overridden.
  
  Also provides 2 initialization mechanisms. Construction is wrapped to 
  facilitate loadable behavior. When loading from a state, only this.initialize() 
  is called. When loading with no state, initialize() is called followed by 
  defaultLoad() with arguments pulled from the main constructor as needed.

*/

@:class = import(module:'Matte.Core.Class');
@:State = import(module:'game_class.state.mt');




@:TYPE_TO_CLASS = {};
@:NAME_TO_CLASS = {};
@:status = {};

return {
  status : status,
  createLight ::(
    name => String,
    items => Object,
    private => Object,
    interface,
    statics
  ) {
    status[name] = 0;
    @:StateType = State.create(items);
    @:type = Object.newType(name:name);
    @:output = {};
    foreach(statics) ::(k, v) {
      output[k] = v;
    }

    private.state = Object;
    private.this = Object;
    @:PrivateType = Object.newType(
      name : name + '.private',
      layout: private
    );
    

    if (interface.load == empty)
      interface.load = ::(serialized) {
        _.state.load(parent:_.this, serialized);
        if (interface.afterLoad != empty)
          _.this.afterLoad();
      }
    
    if (interface.save == empty)
      interface.save = ::(serialized) {
        return _.state.save();
      }

    output.type = {
      get ::<- type
    }


    
    
    output.new = ::(*args) {
      status[name] += 1;
      @:priv = Object.instantiate(type:PrivateType);
      @:out = Object.instantiate(type:type);
      out .= interface;
      
      priv.this = out;
      priv.state = StateType.new();
      
      out->setIsInterface(
        enabled: true,
        private : priv
      );
      
      if (interface.initialize != empty)
        out.initialize(*args);
      
      if (args.state != empty)
        out.load(serialized:args.state)
      else 
        out.defaultLoad(*args);
      
      return out;
    }
    output->setIsInterface(
      enabled:true
    );

    
    NAME_TO_CLASS[name] = output;
    return output;
  },

  create ::(
    define,
    items => Object,
    name => String,
    inherits,
    statics
  ) {
    status[name] = 0;
    @:StateType = State.create(items);
    @:output = class(
      define ::(this) {
        status[name] += 1;
      
        @:state = StateType.new();
        
        define(this, state);
        
        
        @:keys = this->keys;
        @isKey = {};
        foreach(keys) ::(k, v) {
          isKey[v] = true;
        }
        
        
        @:afterLoad = if (isKey.afterLoad) this.afterLoad else empty;
        @:overrideSave = if (isKey.save) this.save else empty;
        @:overrideLoad = if (isKey.load) this.load else empty;
        @:initialize = if (isKey.initialize) this.initialize else empty;
        
        this.constructor = ::(*args) {
            
          if (initialize != empty)
            initialize(*args);
          
          if (args.state != empty) 
            this.load(serialized:args.state)
          else 
            this.defaultLoad(*args);
        }

        this.interface = {
          afterLoad : empty,

          load : if (overrideLoad) overrideLoad else ::(serialized) {
            state.load(parent:this, serialized);
            if (afterLoad != empty)
              afterLoad();
          },

          save : if (overrideSave) overrideSave else ::(serialized) {
            return state.save();
          }
        }

      },
      name,
      inherits,
      statics
    )
    NAME_TO_CLASS[name] = output;
    return output;
  },
  
  load::(name) {
    @:out = NAME_TO_CLASS[name];
    return out;
  },
  
  isLoadable::(name) <- NAME_TO_CLASS[name] != empty
  
}



