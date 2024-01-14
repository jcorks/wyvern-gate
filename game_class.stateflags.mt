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
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');

@:StateFlags = LoadableClass.create(
    name : 'Wyvern.StateFlag',
    statics : {
        HURT : {get::<-0},
        WENT : {get::<-1},
        HEALED : {get::<-2},
        FALLEN : {get::<-3}, // HP = 0
        DIED : {get::<-4}, // was hit with HP == 0
        SKIPPED : {get::<-5},
        DEFENDED : {get::<-6}, // defended,
        DEFEATED_ENEMY : {get::<-7},
        DODGED_ATTACK : {get::<-8},
        ATTACKED : {get::<-9},
        ABILITY : {get::<-10}
    },
    items: {
        set : empty
    },

    
    define :::(this, state) {
        
        
        this.interface = {
            defaultLoad ::{
                state.set = [];
            },
        
            add::(flag, flags) {
                when(flags == empty) ::<= {
                    state.set[flag] = true;
                }
                
                foreach(flags)::(index, flag) {
                    state.set[flag] = true;
                }
            },
            
            unset::(flag, flags) {
                when(flag) ::<= {
                    state.set[flag] = empty;
                }
                
                foreach(flags)::(index, flag) {
                    state.set[flag] = empty;
                }
            },
            
            has::(flag) {
                return state.set[flag] == true;
            },
            
            reset:: {
                state.set = [];
            }            
        }
    
    }
);

return StateFlags;
