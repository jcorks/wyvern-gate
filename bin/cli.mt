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
//@:Entity = import(module:'base/entity.mt');
//@:Random = import(module:'core/random.mt');


breakpoint()

@:canvas = import(:'core/graphics/canvas.mt');
@:instance = import(module:'base/instance.mt');
@:windowEvent = import(module:'core/windowevent.mt');
@:JSON = import(module:'Matte.Core.JSON');
@:time = import(module:'Matte.System.Time');
@:Filesystem = import(module:'Matte.System.Filesystem');
@:renderLines = getExternalFunction(:'wyvern_gate__native__canvas__renderLines');


@:write = getExternalFunction(:'wyvern_gate__native__writeDataText');
@:read = getExternalFunction(:'wyvern_gate__native__readDataText');
@:list = getExternalFunction(:'wyvern_gate__native__listDataText');




@:getchWait = ::? {
  return getExternalFunction(:'wyvern_gate__native__getchWait');
} => {
  onError::(message) {
    // fallback simple CPU reduction
    return ::(wait) {
      ::? {
        forever :: {
          lastVal = console.getch(unbuffered:true);
          if (lastVal != empty && lastVal != '')
            send();

          if (wait != empty)
            Time.sleep(milliseconds:wait);
        }
      }    
    }  
  }
}



@MOD_DIR = './mods';

::? {
  MOD_DIR = import(module:'wyvern_gate__native__get_mod_dir')(); 
} => {
  onError::(message) {}
};

@currentCanvas;
@canvasChanged = false;

@:rerender = ::{
  console.clear();
  @:lines = currentCanvas;
  
  renderLines(:lines)
  /*
  foreach(lines) ::(index, line) {
    console.println(message:line);
  }
  */
  canvasChanged = false;   
  //time.sleep(milliseconds:1000 * (1 / 40.0));
}
canvas.onCommit = ::(lines, renderNow){
  currentCanvas = lines;
  canvasChanged = true;
  if (renderNow != empty)
    rerender();
}
/*
@:refitCanvasCLI::{
      
  console.clear();
  console.put(:"\x1b[999;999H");
  console.put(:"\x1b[6n");
  @w;
  @h;


  ::? {
    forever ::{
      @ch = getchWait()
      if (ch != empty) {
        send();
      }
    }
  }

  ::? {
    @target = '';
    @ch = getchWait()

    forever ::{
      @ch = getchWait()
      //console.println(:"ch: " + ch);
      when(ch == empty) send();
      when (ch == 'R') ::<= {
        w = target;
        send();
      }
      when (ch == ';') ::<= {
        h = target;
        target = '';
      }
      target = target + ch;
    }
  }
  
  console.clear();
  when(w == empty || h == empty) empty;
  
  w = Number.parse(:w);
  h = ((Number.parse(:h) / 2)->floor)*2 -2;

  when (canvas.width == w && canvas.height == h) empty;


  canvas.resize(width:w, height:h);
}
*/



@:console = import(module:'Matte.System.ConsoleIO');
@:Time = import(module:'Matte.System.Time');
@msResize = 0 ;
@history = [];
@lastVal = empty;
@:pollInput = ::{
  @val;
  @command = '';
  @:getPieces = ::<- ::? {
    forever ::{
      @:ch = getchWait();
      when (ch == empty || ch == '') send();
      history->push(:ch->charCodeAt(:0));
    }
  }
  getPieces();
  

  
  if (history->size > 2) {
    breakpoint();
    command = String.combine(:history->map(::(value) <- ''+value));
    
    // ansi terminal actions
    if (command->search(:'279165') != -1) val = 1; // up,
    if (command->search(:'279166') != -1) val = 3; // down,
    if (command->search(:'279168') != -1) val = 0; // left,
    if (command->search(:'279167') != -1) val = 2; // right,

    if (val != empty) {
      breakpoint();
      history = [];
    }
  }

  if (history->size > 0) {
    val = match(' '->setCharCodeAt(index:0, value:history[history->size-1])) {
      ('z', ' ', '.', 'a', '['): 4,
      ('x', '/', 'b', ']'): 5
    }
    if (val != empty)
      history = [];
  }


  // clears current line
  console.put(:"\x1b[2K");
  if (val == empty) ::<= {
    Time.sleep(milliseconds:30);
    // now wait till we get some input to save some CPU huh!
    if (windowEvent.needsCommit == false) ::<= {
      @ch = getchWait(:30);
      if (ch == empty || ch == '') {
        
      } else {
        history->push(:ch->charCodeAt(:0));
      }
    }

    
  }
  return val;   
}

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

@LOOP_DONE = false;
@:mainLoop = ::{
  // standard event loop
  ::? {
    forever ::{
      when(LOOP_DONE) ::<= {
        printMacro();
        send();
      }
      
      @val = pollInput();
      windowEvent.commitInput(input:val);
      
      
      if (canvasChanged) ::<= {
        rerender();  
      }
    }    
  } 
}

@enterNewLocation ::(action, path) {
  @CWD = Filesystem.cwd;
  Filesystem.cwd = path;
  @output;
  ::? {
    output = action(filesystem:Filesystem);
  } => {
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
  features: 0,
  
  writeDataText : write,
  readDataText : read,
  listDataText : list,
  
  
  preloadJSON ::{
    @:loaded = {};

    enterNewLocation(
      path: './',
      action::(filesystem) {
        @:items = [];
        @:getRelPath = :: {
          @out = ''
          foreach(items) ::(k, v) {
            out = out + v + '/'
          }        
          return out;
        }
        
        @:enterDir ::(dir) {                
          @:oldCwd = filesystem.cwd;
          filesystem.cwd = dir;
          items->push(:dir);

      
          foreach(filesystem.directoryContents) ::(k, v) {
            when (v.isFile == false)
              enterDir(:v.name);
              
            if (v.name->contains(:'.json')) {
              ::? {
                loaded[getRelPath()+v.name] = filesystem.readJSON(:v.path);
              } => {
                onError ::(message) {
                  error(detail:v.path + ' could not be opened.')
                }
              }
            }
          }
          filesystem.cwd = oldCwd;
          items->pop
        }
        

        
        enterDir(:'assets');
      }
    );  
    
    return loaded
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
    
    @:checkTypes ::(path, json) {
      foreach(jsonTypes) ::(name, type) {
        when(json[name]->type != type)
          error(detail:path + ': mod.json: "' + name + '" must be a ' + String(from:type) + '!');
      }
    }
    
    
    @:preload ::(json) {
      foreach(json.files) ::(i, file) {
        ::? {
          importModule(
            module:file,
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
            value : JSON.decode(:Filesystem.readString(:file))
          )
        } => {
          onError::(message) {
            error(detail: 'Could not preload / compile ' + json.name + '/' + file + ':\n' + message.detail);
          }
        }
      }      
    }
    

    @:loadModJSON ::(filesystem, file) {
      enterNewLocation(
        path: file.path,
        action ::(filesystem) {
          // first, get the JSON 
          @:json = ::? {
            @:data = filesystem.readString(path:'mod.json');
            
            if (data == empty || data == '')
              error();
              
            return JSON.decode(string:data);
          } => {
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
    ::? {
      enterNewLocation(
        path: MOD_DIR,
        action::(filesystem) {
          foreach(filesystem.directoryContents) ::(k, file) {
            when (file.isFile) empty;
            
            loadModJSON(filesystem, file);
          }
        }
      );
    } => {
      onError ::(message) {
        error(detail:message.detail);
      }
    }
    return mods;  
  },
  
  onPlaySFX ::(name) {
  },
  
  onPlayBGM ::(name, loop) {
  
  },
  
  onQuit :: {
    LOOP_DONE = true;
  }
  /*
  onLoadMain ::{
    return ::? {
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
