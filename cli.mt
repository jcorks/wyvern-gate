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
//@:Entity = import(module:'game_class.entity.mt');
//@:Random = import(module:'game_singleton.random.mt');

@:canvas = import(module:'game_singleton.canvas.mt');
@:instance = import(module:'game_singleton.instance.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');




@currentCanvas;
@canvasChanged = false;

@:rerender = ::{
    console.clear();
    @:lines = currentCanvas;
    foreach(lines) ::(index, line) {
        console.println(message:line);
    }
    canvasChanged = false;   
}
canvas.onCommit = ::(lines, renderNow){
    currentCanvas = lines;
    canvasChanged = true;
    if (renderNow != empty)
        rerender();
}




@:console = import(module:'Matte.System.ConsoleIO');
@:Time = import(module:'Matte.System.Time');

@:pollInput = ::{
        
    @command = '';
    @:getPiece = ::{
        @:ch = console.getch(unbuffered:true);
        when (ch == empty || ch == '') '';
        return ch->charCodeAt(index:0);
    }
    
    command = '' + getPiece() + getPiece() + getPiece();
    
    // ansi terminal actions
    @:CURSOR_ACTIONS = {
        '279165': 1, // up,
        '279166': 3, // down
        '279168': 0, // left,
        '279167': 2, // right

        '75': 0, // left 
        '72': 1, // up
        '77': 2, // right 
        '80': 3, // down
        
        '122': 4, // confirm,
        '120': 5, // cancel
        
    }
    @val = CURSOR_ACTIONS[command];
    if (val == empty)
        Time.sleep(milliseconds:30);
    return val;   
}

@:mainLoop = ::{
    // standard event loop
    forever ::{
        @val = pollInput();
        windowEvent.commitInput(input:val);
        
        if (canvasChanged) ::<= {
            rerender();  
        }
    }       
}



instance.mainMenu(
    onSaveState :::(
        slot,
        data
    ) {
        @:Filesystem = import(module:'Matte.System.Filesystem');
        @:oldcwd = Filesystem.cwd;
        Filesystem.cwd = '/usr/share/Wyvern_SAVES';
        Filesystem.writeString(
            path: 'saveslot' + slot,
            string: data
        );
        Filesystem.cwd = oldcwd;

    },

    onLoadState :::(
        slot
    ) {
        @:Filesystem = import(module:'Matte.System.Filesystem');
        @:oldcwd = Filesystem.cwd;
        Filesystem.cwd = '/usr/share/Wyvern_SAVES';
        return {:::} {
            @:out = Filesystem.readString(
                path: 'saveslot' + slot
            );
            Filesystem.cwd = oldcwd;
            return out;            
        } : {
            onError:::(detail) {
                Filesystem.cwd = oldcwd;
                return empty;
            }
        }
    }

);


if (mainLoop != empty) mainLoop();
