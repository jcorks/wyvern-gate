

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

@:JSON = import(module:'Matte.Core.JSON');
@:Entity = import(module:'base/entity.mt');
@:Random = import(module:'core/random.mt');

@:canvas = import(module:'core/graphics/canvas.mt');
@:instance = import(module:'base/instance.mt');



// Called when telling the external device that 
// a new frame will be prepared
// no args, no return
@:external_onStartCommit = getExternalFunction(name:'external_onStartCommit');

// Called when telling the external device that 
// a new frame data has been delivered.
// no args, no return
@:external_onEndCommit = getExternalFunction(name:'external_onEndCommit');


// Called when telling the external device that 
// JSON from the environment is needed
@:external_preloadJSONText = getExternalFunction(name:'external_preloadJSONText');



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

// Sets the loop iterator
@external_setLoopIter    = getExternalFunction(name:'external_setLoopIter');


// Gets the list of mod dir roots for mod loading and alias settings
@external_getModDirs = getExternalFunction(name:'external_getModDirs');



@:windowEvent = import(module:'core/windowevent.mt');
windowEvent.errorHandler = ::<= {
  @count = 0;
  return ::(message) {
    count += 1;
    if (count == 20)
      error(detail:'Too many errors encountered on the web version of the game. Displaying last error:' + message.summary);
    
  }
}


@currentCanvas;
@canvasChanged = false;

@rerender = :: {
  @:lines = currentCanvas;
  external_onStartCommit();
  foreach(lines)::(index, line) {
    external_onCommitText(a:line);
  }
  external_onEndCommit();
  print(:'New line request 3');
  canvasChanged = false;  
}

canvas.onCommit = ::(lines, renderNow){
  currentCanvas = lines;
  canvasChanged = true;
  if (renderNow != empty)
    rerender();
}

@:jsonPreloaded = external_preloadJSONText();

foreach(jsonPreloaded) ::(k, v) {
  print(:'Preloaded JSON: ' + k);
  jsonPreloaded[k] = JSON.decode(:v)
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
  
  preloadJSON :: {
    return {...jsonPreloaded};
  },

  preloadMods :: {
    @:mods = [];

    @:jsonTypes = {
      name : String,
      description : String,
      author : String,
      website : String,
      files : Object,
      JSONdata : Object,
      loadFirst : Object
    }
    
    @:checkTypes ::(root, json) {
      foreach(jsonTypes) ::(name, type) {
        when(json[name]->type != type)
          error(detail:root + ': mod.json: "' + name + '" must be a ' + String(from:type) + '!');
      }
    }
    
    
    @:preload ::(root, json) {
      foreach(json.files) ::(i, file) {
        ::? {
          importModule(
            module:root+'/'+file,
            alias:json.id + '/' + file,
            preloadOnly: true 
          )
        } => {
          onError::(message) {
            error(detail: 'Could not preload / compile ' + json.name + '/' + file + ':\n' + message.detail);
          }
        }
      }
      
      foreach(json.JSONdata) ::(i, file) {
        ::? {
          setModule(
            name:json.id + '/' + file,
            value : jsonPreloaded(:root+'/'+file)
          )
        } => {
          onError::(message) {
            error(detail: 'Could not preload / compile ' + json.name + '/' + file + ':\n' + message.detail);
          }
        }
      }      
    }
    

    @:loadModJSON ::(root) {
      @:json = ::? {
        @:data = jsonPreloaded[root+'/mod.json'];
        
        if (data == empty)
          error();
        return data;
      } => {
        onError ::(message) {
          error(detail: 'Could not read or parse mod.json file within ' + root + '!');
        }
      }
      
      checkTypes(root, json);
      preload(root, json);
      mods->push(value:json);
    }
    ::? {
      foreach(external_getModDirs()) ::(k, root) {
        loadModJSON(root);
      }
    } => {
      onError ::(message) {
        error(detail:message.summary);
      }
    }
    return mods; 
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



@:printMacro ::{
  @:macro = windowEvent.getMacro();
  when(macro == empty) empty;
  
  print(:'\n\n[');
  foreach(macro) ::(k, v) {
    print(:'  {input: windowEvent.CURSOR_ACTIONS.' + 
      (
        match(v.input) {
          (windowEvent.CURSOR_ACTIONS.LEFT): 'LEFT',
          (windowEvent.CURSOR_ACTIONS.UP): 'UP',
          (windowEvent.CURSOR_ACTIONS.RIGHT): 'RIGHT',
          (windowEvent.CURSOR_ACTIONS.DOWN): 'DOWN',
          (windowEvent.CURSOR_ACTIONS.CONFIRM): 'CONFIRM',
          (windowEvent.CURSOR_ACTIONS.CANCEL): 'CANCEL',
          default: '???'
        }
      ) + ', waitFrames: ' +
      (
        v.waitFrames
      ) + '},'
    );
  }
  print(:']');
}




// user code calls the returned function every frame
@LOOP_DONE = false;
external_setLoopIter(::{
  when(LOOP_DONE) ::<= {
    printMacro();
    send();
  }
  
  @val = external_getInput();
  windowEvent.commitInput(input:val);    
  
  if (canvasChanged) ::<= {
    rerender();  
  }

})
