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
@:Entity = import(module:'class.entity.mt');
@:Random = import(module:'singleton.random.mt');
@:console = import(module:'Matte.System.ConsoleIO');

@:canvas = import(module:'singleton.canvas.mt');
@:instance = import(module:'singleton.instance.mt');





instance.mainMenu(
    onCommit :::(lines) {
        console.clear();
        lines->foreach(do:::(index, line) {
            line->foreach(do:::(i, iter) {
                console.println(message:iter.text);
            });
        });    
    },
    
    onSaveState :::(
        slot,
        data
    ) {
        @:Filesystem = import(module:'Matte.System.Filesystem');
        Filesystem.cwd = '/usr/share/Wyvern_SAVES';
        Filesystem.writeString(
            path: 'saveslot' + slot,
            string: data
        );
    },

    onLoadState :::(
        slot
    ) {
        @:Filesystem = import(module:'Matte.System.Filesystem');
        Filesystem.cwd = '/usr/share/Wyvern_SAVES';
        return [::] {
            return Filesystem.readString(
                path: 'saveslot' + slot
            );
            
        } : {
            onError:::(detail) {
                return empty;
            }
        };
    },

    useCursor : false,
    
    onInputNumber :::() {
        @out = 0;
        [::] {
            out = Number.parse(string:console.getln());
        } : {
            onError:::(message) {
                //nothing
            }
        };    
        return out;
    },
    
    onInputCursor :::() {
        @out = 0;
        [::] {
            out = Number.parse(string:console.getln());
        } : {
            onError:::(message) {
                //nothing
            }
        };    
        
        /*
            @:CURSOR_ACTIONS : {
                LEFT : 0,
                UP : 1,
                RIGHT : 2,
                DOWN : 3,
                CONFIRM : 4,
                CANCEL : 5,
            };        
        */
        return out;        
    }
);




