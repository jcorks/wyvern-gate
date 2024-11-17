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
  Standard way of representing a database item that has extra 
  data attached to it. Always has a "base" member to the state and the interface 
  and provides a static "Base" referring to the given database.
*/
@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'game_class.database.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');


return {
  createLight::(
    /// The name of the class to create
    name => String,
    
    /// The items of the state to be created on your behalf
    /// No state items are initialized, but this can be done 
    /// manually in the defineMutator startup function.
    /// By default, the state will always provide the "base"
    /// trait, which refers to the DatabaseItem that this 
    /// Mutator is based on.
    items => Object,
    
    /// Any optional statics youd like the class to have.
    statics,
    
    private => Object,

    interface => Object,
    
    /// The database class upon which this Mutator is based on.
    database  
  ) {
    @:staticsOut = if (statics) {
      ...statics
    } else {}
    
    staticsOut.database = {
      get ::<- database
    };
    items.base = empty;
    
    interface.base = {
      get ::<- _.state.base
    }

    interface.__defaultLoad = interface.defaultLoad;
    interface.defaultLoad = ::(*args) {
      _.state.base = args.base;
      if (interface.__defaultLoad != empty)
        _.this.__defaultLoad(*args)
    }

    
    
    @:c = LoadableClass.createLight(
      name,
      items,
      statics:staticsOut,
      private,
      interface
    )
    return c;  
  },

  create::(
    /// The name of the class to create
    name => String,
    
    /// The items of the state to be created on your behalf
    /// No state items are initialized, but this can be done 
    /// manually in the defineMutator startup function.
    /// By default, the state will always provide the "base"
    /// trait, which refers to the DatabaseItem that this 
    /// Mutator is based on.
    items => Object,
    
    /// Any optional statics youd like the class to have.
    statics,
    
    /// The define() function but specialized for mutators.
    /// Same as LoadableClass, except a "base" getter is added which 
    /// simply provides state.base publicly.
    define => Function,
    
    /// The database class upon which this Mutator is based on.
    database
    
  ) {
    @:staticsOut = if (statics) {
      ...statics
    } else {}
    
    staticsOut.database = {
      get ::<- database
    };
    items.base = empty;
    
    @:c = LoadableClass.create(
      name,
      items,
      statics:staticsOut,
      define ::(this, state) {
        define(this, state);

        @:defaultLoad = this.defaultLoad;
        this.interface = {
          defaultLoad ::(*args) {
            state.base = args.base;
            if (defaultLoad != empty)
              defaultLoad(*args)
          },

          base : {
            get ::<- state.base
          }        
        }
      }
    )
    return c;
  }
}
