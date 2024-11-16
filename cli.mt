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
@:JSON = import(module:'Matte.Core.JSON');
@:time = import(module:'Matte.System.Time');

@MOD_DIR = './mods';

{:::} {
  MOD_DIR = import(module:'wyvern_gate__native__get_mod_dir')(); 
} : {
  onError::(message) {}
};

@currentCanvas;
@canvasChanged = false;

@:rerender = ::{
  console.clear();
  @:lines = currentCanvas;
  foreach(lines) ::(index, line) {
    console.println(message:line);
  }
  canvasChanged = false;   
  //time.sleep(milliseconds:1000 * (1 / 40.0));
  canvas.onFrameComplete();
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

@enterNewLocation ::(action, path) {
  @:Filesystem = import(module:'Matte.System.Filesystem');
  @CWD = Filesystem.cwd;
  Filesystem.cwd = path;
  @output;
  {:::} {
    output = action(filesystem:Filesystem);
  } : {
    onError::(message) {
      Filesystem.cwd = CWD;    
      error(detail:message.detail);        
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
    enterNewLocation(
      path: './',
      action::(filesystem) {
        when (data->type == String && data == '') 
          filesystem.remove(path: 'save_' + slot);
        
        breakpoint();
        filesystem.writeJSON(
          path: 'save_' + slot,
          object: data
        );
      }
    );
  },
  
  onListSlots ::{
    return enterNewLocation(
      path: './',
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
      return enterNewLocation(
        path: './',
        action::(filesystem) {
          return filesystem.readJSON(
            path: 'save_' + slot
          );
        }
      );
    } : {
      onError::(message) {
        return empty;
      }
    }
  },
  
  onLoadSettings ::{
    return {:::} {
      return enterNewLocation(
        path: './',
        action::(filesystem) {
          return filesystem.readString(
            path: 'settings'
          );
        }
      );
    } : {
      onError::(message) {
        return empty;
      }
    }
  },
  
  onSaveSettings ::(data){
    enterNewLocation(
      path: './',
      action::(filesystem) {
        filesystem.writeString(
          path: 'settings',
          string: data
        );
      }
    );  
  },
  
  preloadMods :: {
    @:mods = [];

    @:jsonTypes = {
      name : String,
      name : String,
      description : String,
      author : String,
      website : String,
      files : Object,
      loadFirst : Object
    }
    
    @:checkTypes ::(path, json) {
      foreach(jsonTypes) ::(name, type) {
        when(json[name]->type != type)
          error(detail:path + ': mod.json: "' + name + '" must be a ' + String(from:type) + '!');
      }
    }
    
    
    @:preload ::(json) {
      foreach(json.files) ::(i, file) {
        {:::} {
          importModule(
            module:file,
            alias:json.id + '/' + file,
            preloadOnly: true 
          )
        } : {
          onError::(message) {
            error(detail: 'Could not preload / compile ' + json.name + '/' + file + ':' + message.detail);
          }
        }
      }
    }
    

    @:loadModJSON ::(filesystem, file) {
      enterNewLocation(
        path: file.path,
        action ::(filesystem) {
          // first, get the JSON 
          @:json = {:::} {
            @:data = filesystem.readString(path:'mod.json');
            
            if (data == empty || data == '')
              error();
              
            return JSON.decode(string:data);
          } : {
            onError ::(message) {
              error(detail: 'Could not read or parse mod.json file within ' + file.path + '!');
            }
          }
          
          checkTypes(path:file.path, json);
          preload(json);
          mods->push(value:json);
        }
      )
    }
    {:::} {
      enterNewLocation(
        path: MOD_DIR,
        action::(filesystem) {
          foreach(filesystem.directoryContents) ::(k, file) {
            when (file.isFile) empty;
            
            loadModJSON(filesystem, file);
          }
        }
      );
    } : {
      onError ::(message) {
        error(detail:message.detail);
      }
    }
    return mods;  
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
