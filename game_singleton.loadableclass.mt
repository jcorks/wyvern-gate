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


return {
    create ::(
        define,
        items => Object,
        name => String,
        inherits,
        statics
    ) {
        @:output = class(
            define ::(this) {
                @:state = State.new(items);
                
                define(this, state);
                if (this.interface == empty)
                    this.interface = {};
                @:interface = this.interface;
                
                
                @:afterLoad = interface.afterLoad;
                @:overrideSave = interface.save;
                @:overrideLoad = interface.load;
                @:initialize = interface.initialize;
                
                this.constructor = ::(*args) {
                        
                    if (initialize != empty)
                        initialize(*args);
                    
                    if (args.state != empty) 
                        this.load(serialized:args.state)
                    else 
                        this.defaultLoad(*args);
                }

                interface.afterLoad = empty;

                interface.load = if (overrideLoad) overrideLoad else ::(serialized) {
                    state.load(parent:this, serialized);
                    if (afterLoad != empty)
                        afterLoad();
                }

                interface.save = if (overrideSave) overrideSave else ::(serialized) {
                    return state.save();
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



