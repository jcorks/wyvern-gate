@:Topaz = import(module:'Topaz');
@Shell = import(module:'sys_shell.mt');

@:FRAME_ANIMATION_POST_MS = 32;

@:SAVEPATH = ::<= {
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
@MODS_PATH = 'mods';

@:enterLocation = ::(location, action) {
    @:oldPath = Topaz.Resources.getPath();
    Topaz.Resources.setPath(path:location);
    
    {:::} {
        action();
    } : {
        onError ::(message) {
            Topaz.Resources.setPath(path:oldPath);            
            error(detail:message.detail);
        }
    }
    Topaz.Resources.setPath(path:oldPath);
}



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
        @:settingsAsset = Topaz.Resources.createAsset(name:'settings', type:Topaz.Asset.Type.Data);
        instance.mainMenu(
            canvasHeight: 22,
            canvasWidth: 80,
            onSaveState :::(
                slot,
                data
            ) {

                enterLocation(location:SAVEPATH, action::{                
                    saveAsset.setFromString(string:data);
                    @:outputPath =  'WYVERNSAVE_' + slot;
                    if (Topaz.Resources.writeAsset(
                        asset:saveAsset,
                        fileType: 'text',
                        outputPath
                    ) == 0) error(detail:outputPath + ' could not be written!');
                })
            },

            preloadMods :: {
                @:mods = [];
                return mods;
            },

            onLoadSettings :: {
                @data;
                enterLocation(location:SAVEPATH, action::{
                    Topaz.Resources.readDataAssetFromPath(asset:settingsAsset, path:'settings');
                    @:asset = settingsAsset;

                    when (asset == empty) empty;
                    data = asset.getAsString();
                    Topaz.Resources.removeAsset(asset);
                    when (data == '') empty;
                });
                return if (data == empty || data == '') empty else data;
            },
            onSaveSettings ::(data) {
                enterLocation(location:SAVEPATH, action::{                
                    settingsAsset.setFromString(string:data);
                    if (Topaz.Resources.writeAsset(
                        asset:settingsAsset,
                        fileType: 'text',
                        outputPath:'settings'
                    ) == 0) error(detail:'settings could not be written!');
                });
            },

            onListSlots ::{
                @:output = [];
                @:path = Topaz.Filesystem.getPathFromString(path:SAVEPATH);
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
                Topaz.Resources.setPath(path:SAVEPATH);


                @:asset = Topaz.Resources.createDataAssetFromPath(path:'WYVERNSAVE_' + slot, name:slot);
                @:data = asset.getAsString();
                Topaz.Resources.removeAsset(asset);

                Topaz.Resources.setPath(path:oldPath);
                return data;

            },
            
            onQuit ::{
                Topaz.quit();            
            }

        ); 


    }
}
