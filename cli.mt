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

@LOOP_DONE = false;
@:mainLoop = ::{
    // standard event loop
    {:::} {
        forever ::{
            when(LOOP_DONE) send();
            
            @val = pollInput();
            windowEvent.commitInput(input:val);
            
            if (canvasChanged) ::<= {
                rerender();  
            }
        }      
    } 
}

@enterSaveLocation ::(action) {
    @:Filesystem = import(module:'Matte.System.Filesystem');
    @CWD = Filesystem.cwd;
    Filesystem.cwd = '/usr/share/Wyvern_SAVES';
    @output;
    {:::} {
        output = action(filesystem:Filesystem);
    } : {
        onError::(detail) {
            Filesystem.cwd = CWD;        
            error(detail);                
        }
    }
    Filesystem.cwd = CWD;        
    return output;
}
instance.mainMenu(
    canvasWidth: 80,
    canvasHeight: 22,
    onSaveState :::(
        slot,
        data
    ) {
        enterSaveLocation(
            action::(filesystem) {
                filesystem.writeString(
                    path: 'save_' + slot,
                    string: data
                );
            }
        );
    },
    
    onListSlots ::{
        return enterSaveLocation(
            action::(filesystem) {
                @:out = {};
                foreach(filesystem.directoryContents) ::(k, file) {
                    when(!file.name->contains(key:'save_')) empty; // main or junk
                    out->push(value:file.name->split(token:'_')[1]);
                }

                return out;
            }
        );
    },

    onLoadState :::(
        slot
    ) {
        return {:::} {
            return enterSaveLocation(
                action::(filesystem) {
                    return filesystem.readString(
                        path: 'save_' + slot
                    );
                }
            );
        } : {
            onError::(detail) {
                return empty;
            }
        }
    },
    
    onQuit :: {
        LOOP_DONE = true;
    }
    /*
    onLoadMain ::{
        return {:::} {
            return enterSaveLocation(
                action::(filesystem) {
                    return filesystem.readString(
                        path: 'main'
                    );
                }
            );
        } : {
            onError::(detail) {
                return empty;
            }
        }
    },
    
    onSaveMain ::(data) {
        enterSaveLocation(
            action::(filesystem) {
                filesystem.writeString(
                    path: 'main',
                    string: data
                );                
            }
        )
    }
    */

);


if (mainLoop != empty) mainLoop();
