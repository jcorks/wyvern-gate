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


return class(
    name : 'Wyvern.StateFlag',
    statics : {
        HURT_THIS_TURN : 0,
        WENT_THIS_TURN : 1,
        HEALED_THIS_TURN : 2,
        IS_FALLEN : 3, // HP = 0
        IS_DEAD : 4, // was hit with HP == 0
        WAS_SKIPPED : 5
    },
    define :::(this) {
        @set = [];
        
        this.interface = {
            add::(flag, flags) {
                when(flags == empty) ::<= {
                    set[flag] = true;
                };
                
                flags->foreach(do:::(index, flag) {
                    set[flag] = true;
                });
            },
            
            unset::(flag, flags) {
                when(flag) ::<= {
                    set[flag] = false;
                };
                
                flags->foreach(do:::(index, flag) {
                    set[flag] = false;
                });
            },
            
            has::(flag) {
                return set[flag];
            },
            
            reset:: {
                set = [];
            }            
        };
    
    }
);
