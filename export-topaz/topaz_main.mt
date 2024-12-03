

@:Topaz = import(module:'Topaz');
@:Terminal = import(module:'topaz_terminal.mt');
@Settings = import(:'topaz_settings.mt');
@:settings = Settings.getObject();




@:Shell = import(module:'topaz_shell.mt');
@:Topaz = import(module:'Topaz');
@:JSON = import(module:'Matte.Core.JSON');
@:Settings = import(module:'topaz_settings.mt')

@:FRAME_ANIMATION_POST_MS = 32;


@:Paths = import(:'topaz_paths.mt');




Paths.setMainPath(::<= {
    return {:::} {
        foreach(Topaz.getArguments()) ::(k, arg) {
            if (arg->contains(key:'savelocation:'))
                send(
                    message:arg->substr(
                        from:'savelocation:'->length, 
                        to:arg->length-1
                    )
                ) 
                    
        }
        
        return Topaz.Resources.getPath();
    }
})
@MOD_DIR = 'mods';





@:start = ::(terminal, arg, onDone) {
    terminal.clear();
    terminal.print(line:'Starting program...');
    @counter = 10;
    @pendingAction;
    @pendingActionTime;

    Shell.onProgramCycle = ::{
        when(counter > 0) counter-=1;
        

        @:canvas = import(module:'game_singleton.canvas.mt');
        @:instance = import(module:'game_singleton.instance.mt');
        @:windowEvent = import(module:'game_singleton.windowevent.mt');

        @currentCanvas;
        @canvasChanged = false;

        @:rerender = ::{
            if (canvasChanged) ::<= {
                @:lines = currentCanvas;
                foreach(lines)::(index, line) {
                    terminal.updateLine(index, text:line);
                }
                canvasChanged = false;    
                pendingAction = canvas.onFrameComplete;
                pendingActionTime = FRAME_ANIMATION_POST_MS;
            }
        }

        canvas.onCommit = ::(lines, renderNow) {
            currentCanvas = lines;
            canvasChanged = true;
            if (renderNow != empty)
                rerender();
        }

        Shell.onProgramKeyboard = ::(input, value) {
            when(value < 1) empty;
            match(input) {
                (Topaz.Key.z,
                Topaz.Key.enter,
                Topaz.Key.space):::<= {
                    windowEvent.commitInput(input:4);
                },

                (Topaz.Key.x,
                Topaz.Key.backspace,
                Topaz.Key.esc):::<= {
                    windowEvent.commitInput(input:5);
                },

                (Topaz.Key.left):::<= {
                    windowEvent.commitInput(input:0);
                },
                (Topaz.Key.up):::<= {
                    windowEvent.commitInput(input:1);
                },
                (Topaz.Key.right):::<= {
                    windowEvent.commitInput(input:2);
                },
                (Topaz.Key.down):::<= {
                    windowEvent.commitInput(input:3);
                }

            }
            
        }


        @lastInput;
        Shell.onProgramCycle = ::{
            if (pendingActionTime) ::<= {
                pendingActionTime -= Topaz.getDeltaTime()*1000;
                when(pendingActionTime <= 0) ::<= {
                    pendingAction()
                    pendingAction = empty;
                    pendingActionTime = empty;
                }
            }
            
            windowEvent.commitInput(input:lastInput);
            rerender();
        }

        @:saveAsset = Topaz.Resources.createAsset(name:'WYVERN_SAVE', type:Topaz.Asset.Type.Data);
        @settingsAsset;
        instance.mainMenu(
            canvasHeight: 22,
            canvasWidth: 80,
            onSaveState :::(
                slot,
                data
            ) {

                //Paths.enter(::{                
                    @:Filesystem = import(:'Matte.System.Filesystem');
                    @:outputPath =  'WYVERNSAVE_' + slot;
                    @:basePath = Topaz.Resources.getPath();


                    when (data->type == String && data == '') 
                        Filesystem.remove(path:basePath + '/' + outputPath);
                
                
                    
                    Filesystem.writeJSON(
                      path: basePath + '/' + outputPath,
                      object:data 
                    );
                //})
            },

            preloadMods :: {
                @:mods = [];

                @enterNewLocation ::(action, path) {
                    @CWD = Topaz.Resources.getPath();
                    if (Topaz.Resources.setPath(:path) == empty)
                        error(:path + ' was not available or doesn\'t exist.')
                    @output;
                    {:::} {
                      output = action();
                    } : {
                        onError::(message) {
                            Topaz.Resources.setPath(:CWD);
                            error(detail:message.detail);        
                        }
                    }
                    Topaz.Resources.setPath(:CWD);
                    return output;
                }


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
                                error(detail: 'Could not preload / compile ' + json.name + '/' + file + ':' + message.summary);
                            }
                        }
                    }
                }


                @:loadModJSON ::(file) {
                    enterNewLocation(
                        path: file.asString(),
                        action :: {
                            // first, get the JSON 
                            @:json = {:::} {
                                @:asset = Topaz.Resources.createDataAssetFromPath(path: 'mod.json', name: 'mod.json');
                                @:data = asset.getAsString();

                                if (data == empty || data == '')
                                error();

                                @:obj = JSON.decode(string:data);
                                Topaz.Resources.removeAsset(:asset);
                                return obj;
                            } : {
                                onError ::(message) {
                                    error(detail: 'Could not read or parse mod.json file within ' + file.asString() + '!');
                                }
                            }

                            checkTypes(path:file.path, json);
                            preload(json);
                            mods->push(value:json);
                        }
                    )
                }
                @:path = Topaz.Filesystem.getPathFromString(path:Topaz.Resources.getPath() + '/' + MOD_DIR);
                if (path == empty)
                    error(:'The /mods path does not exist. No mods can be loaded.');
                foreach(path.getChildren()) ::(k, file) {
                    loadModJSON(file);
                }
                return mods;              
            },

            onLoadSettings :: {
                @:obj = Settings.getObject();
                return JSON.encode(:obj);
            },
            onSaveSettings ::(data) {
                Settings.set(:JSON.decode(:data));
            },

            onListSlots ::{
                @:output = [];
                @:path = Topaz.Filesystem.getPathFromString(path:'.');
                foreach(path.getChildren()) ::(k, child) {
                    if (child.getName()->contains(key:'WYVERNSAVE_'))
                        output->push(value:child.getName()->split(token:'_')[1]);
                }
                return output;
            },

            onLoadState :::(
                slot
            ) {
                @:oldPath = Topaz.Resources.getPath();
                Topaz.Resources.setPath(path:'.');

                @:Filesystem = import(:'Matte.System.Filesystem');
                return Filesystem.readJSON(
                  path: Topaz.Resources.getPath() + '/WYVERNSAVE_' + slot
                );
            },
            
            onQuit ::{
                Topaz.quit();            
            }

        ); 


    }
}


    


// if topaz is detected, setup its canvas and main loop

@:term = Terminal.new();

@:PADDING = 6;
@:display = Topaz.ViewManager.getDefault();
@:displayWidth = ::{
    return display.getParameter(param:Topaz.Display.Parameter.Width);
}

@:displayHeight = ::{
    return display.getParameter(param:Topaz.Display.Parameter.Height);
}

display.setName(name:"tOS");

term.setPosition(value:{
    x: -term.widthPixels/2 + PADDING/2 - 2,
    y:  term.heightPixels/2+ PADDING/2
});

display.getViewport().resize(
    width :term.widthPixels + PADDING*2,
    height:term.heightPixels + PADDING*2
);


display.getViewport().attach(child:term);
//display.getViewport().setFiltered(enabled:false);

if (settings.fullscreen == true || settings.fullscreen == empty)
    display.setParameter(
        param:Topaz.Display.Parameter.Fullscreen,
        value:true
    );
    
if (settings.showConsole == true) ::<= {
    Topaz.Console.enable(:true);
    Topaz.Console.print(:'Hello! This is the debug console for Wyvern Gate. Errors will be listed here in full.')
}



term.clear();
Shell.start(terminal:term);
start(terminal:term, onDone::{
    term.clear();
    term.print(line:'Shutting down...');

    @counter = 100;
    Shell.onProgramCycle = ::{
        counter -= 1;
        if (counter <= 0 && Number.random() > 0.9)
            Topaz.quit();
    }
});
