

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

@:Entity = import(module:'game_class.entity.mt');
@:Random = import(module:'game_singleton.random.mt');

@:canvas = import(module:'game_singleton.canvas.mt');
@:instance = import(module:'game_singleton.instance.mt');



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
@:external_onLoadState   = getExternalFunction(name:'external_onLoadState');

// Called when querying available save files.
// return: array of strings
@:external_onListSlots   = getExternalFunction(name:'external_onListSlots');

// Called when saving settings.
// arg: JSON string 
@:external_onSaveSettings = getExternalFunction(name:'external_onSaveSettings');

// Called when loading settings.
// return: JSON string
@:external_onLoadSettings = getExternalFunction(name:'external_onLoadSettings');

// Called when quitting.
// arg: none 
// return: none
@:external_onQuit   = getExternalFunction(name:'external_onQuit');


// Called when getting input.
// Will hold thread until an input is ready from the device.
// 
// returns the appropriate cursor action number 
//

//  LEFT : 0,
//  UP : 1,
//  RIGHT : 2,
//  DOWN : 3,
//  CONFIRM : 4,
//  CANCEL : 5,

@:external_getInput    = getExternalFunction(name:'external_getInput');

// Called when game requests to play a sound.
// Takes the name of a sound
@external_onPlaySFX    = getExternalFunction(name:'external_onPlaySFX');


// Called when game requests to play a song.
// Takes the name of a sound and whether to loop
@external_onPlayBGM    = getExternalFunction(name:'external_onPlayBGM');



@:windowEvent = import(module:'game_singleton.windowevent.mt');



@currentCanvas;
@canvasChanged = false;

@rerender = :: {
  @:lines = currentCanvas;
  external_onStartCommit();
  foreach(lines)::(index, line) {
    external_onCommitText(a:line);
  }
  external_onEndCommit();
  canvasChanged = false;  
}

canvas.onCommit = ::(lines, renderNow){
  currentCanvas = lines;
  canvasChanged = true;
  if (renderNow != empty)
    rerender();
}


instance.mainMenu(
  canvasHeight: 24,
  canvasWidth: 80,
  features : 0,
    
  onSaveState :::(
    slot,
    data
  ) {
    external_onSaveState(a:slot, b:data);
  },

  onListSlots ::{
    return external_onListSlots();
  },
  
  onQuit ::{
    external_onQuit();
  },

  onLoadSettings ::{
    return external_onLoadSettings();
  },
  
  onSaveSettings ::(data) {
    external_onSaveSettings(a:data);
  },
  
  onPlaySFX ::(name) {
    external_onPlaySFX(a:name);
  },

  onPlayBGM ::(name, loop) {
    external_onPlayBGM(a:name, b:loop);
  },

  preloadMods :: {
    return [];
  },

  onLoadState :::(
    slot
  ) {
    return ::? {
      return external_onLoadState(a:slot);
    } => {
      onError:::(detail) {
        return empty;
      }
    }
  }
);






// user code calls the returned function every frame
return ::{
  @val = external_getInput();
  windowEvent.commitInput(input:val);
  
  if (canvasChanged) ::<= {
    rerender();
  }

}



