

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

@:canvas = import(module:'singleton.canvas.mt');
@:instance = import(module:'singleton.instance.mt');



// Called when telling the external device that 
// a new frame will be prepared
// no args, no return
@:external_onStartCommit = getExternalFunction(name:'external_onStartCommit');

// Called when telling the external device that 
// a new frame data has been delivered.
// no args, no return
@:external_onEndCommit = getExternalFunction(name:'external_onEndCommit');


// Called when the next character to be displayed is known.
// The characters are given from left to right, top to bottom.
// The current size is standard VT 24 x 80
//
// arg: string holding one character.
// return: none
@:external_onCommitText  = getExternalFunction(name:'external_onCommitText');

// Called when saving the state.
// arg: slot (number, 0-2), data (string)
// return none
@:external_onSaveState   = getExternalFunction(name:'external_onSaveState');

// Called when loading the state.
// arg: slot (number, 0-2)
// return: state (string)
@:external_onLoadState     = getExternalFunction(name:'external_onLoadState');

// Called when getting input.
// Will hold thread until an input is ready from the device.
// 
// returns the appropriate cursor action number 
//

//    LEFT : 0,
//    UP : 1,
//    RIGHT : 2,
//    DOWN : 3,
//    CONFIRM : 4,
//    CANCEL : 5,

@:external_getInput      = getExternalFunction(name:'external_getInput');


@:windowEvent = import(module:'singleton.windowevent.mt');



@currentCanvas;
@canvasChanged = false;
canvas.onCommit = ::(lines){
    currentCanvas = lines;
    canvasChanged = true;
};


instance.mainMenu(
    
    onSaveState :::(
        slot,
        data
    ) {
        external_onSaveState(a:slot, b:data);
    },

    onLoadState :::(
        slot
    ) {
        return [::] {
            return external_onLoadState(a:slot);
        } : {
            onError:::(detail) {
                return empty;
            }
        };
    }
);






// user code calls the returned function every frame
return ::{
    @val = external_getInput();
    windowEvent.commitInput(input:val);
    
    if (canvasChanged) ::<= {
        @:lines = currentCanvas;
        external_onStartCommit();
        lines->foreach(do:::(index, line) {
            line->foreach(do:::(i, iter) {
                external_onCommitText(a:iter.text);
            });
        });    
        external_onEndCommit();
        canvasChanged = false;    
    };

};



