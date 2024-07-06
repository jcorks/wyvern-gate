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
@:Topaz = import(module:'Topaz');
@Shell = import(module:'sys_shell.mt');
@:Paths = import(module:'sys_path.mt');
@:JSON = import(module:'Matte.Core.JSON');
@:Settings = import(module:'sys_settings.mt')

@:FRAME_ANIMATION_POST_MS = 32;

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
    }
)
@MOD_DIR = 'mods';





return ::(terminal, arg, onDone) {
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
                    @:outputPath =  'WYVERNSAVE_' + slot;
                    @:basePath = Topaz.Resources.getPath();
                    
                    @:Filesystem = import(:'Matte.System.Filesystem');
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
                    Topaz.Resources.setPath(:path);
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
                                error(detail: 'Could not preload / compile ' + json.name + '/' + file + ':' + message.detail);
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
                {:::} {
                    @:path = Topaz.Filesystem.getPathFromString(path:Topaz.Resources.getPath() + '/' + MOD_DIR);
                
                    foreach(path.getChildren()) ::(k, file) {
                        loadModJSON(file);
                    }
                } : {
                    onError ::(message) {
                        error(detail:message.detail);
                    }
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
