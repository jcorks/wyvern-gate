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
//@:Entity = import(module:'class.entity.mt');
//@:Random = import(module:'singleton.random.mt');

[::] {
    @:Topaz = import(module:'Topaz');
    import(module:'topaz.main.mt');

} : {
    //onError ::(message){
         //continue on to terminal implementation
    //}
};
return empty;

@:canvas = import(module:'singleton.canvas.mt');
@:instance = import(module:'singleton.instance.mt');
@:dialogue = import(module:'singleton.dialogue.mt');




@currentCanvas;
@canvasChanged = false;
canvas.onCommit = ::(lines){
    currentCanvas = lines;
    canvasChanged = true;
};




@:console = import(module:'Matte.System.ConsoleIO');
@:Time = import(module:'Matte.System.Time');

@:pollInput = ::{
        
    @command = '';
    @:getPiece = ::{
        @:ch = console.getch(unbuffered:true);
        when (ch == empty || ch == '') '';
        return ch->charCodeAt(index:0);
    };
    
    command = '' + getPiece() + getPiece() + getPiece();

    
    // ansi terminal actions
    @:CURSOR_ACTIONS = {
        '279165': 1, // up,
        '279166': 3, // down
        '279168': 0, // left,
        '279167': 2, // right
        
        '122': 4, // confirm,
        '120': 5, // cancel
        
    };
    @val = CURSOR_ACTIONS[command];
    if (val == empty)
        Time.sleep(milliseconds:30);
    return val;   
};

@:mainLoop = ::{
    // standard event loop
    forever(do::{
        @val = pollInput();
        dialogue.commitInput(input:val);
        
        if (canvasChanged) ::<= {
            console.clear();
            @:lines = currentCanvas;
            lines->foreach(do:::(index, line) {
                console.println(message:line);
            }); 
            canvasChanged = false;    
        };
    });            
};



instance.mainMenu(
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
    }

);


if (mainLoop != empty) mainLoop();
