@:Topaz = import(module:'Topaz');
@Shell = import(module:'sys_shell.mt');


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




return ::(terminal, arg, onDone) {
    terminal.clear();
    terminal.print(line:'Starting program...');
    @counter = 10;

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
                Topaz.Key.enter):::<= {
                    windowEvent.commitInput(input:4);
                },

                (Topaz.Key.x,
                Topaz.Key.backspace):::<= {
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
            windowEvent.commitInput(input:lastInput);
            rerender();
        }

        @:saveAsset = Topaz.Resources.createAsset(name:'WYVERN_SAVE', type:Topaz.Asset.Type.Data);
        instance.mainMenu(
            canvasHeight: 32,
            canvasWidth: 80,
            onSaveState :::(
                slot,
                data
            ) {
                @:oldPath = Topaz.Resources.getPath();
                Topaz.Resources.setPath(path:SAVEPATH);
                
                saveAsset.setFromString(string:data);
                @:outputPath =  'WYVERNSAVE_' + slot;
                if (Topaz.Resources.writeAsset(
                    asset:saveAsset,
                    fileType: 'text',
                    outputPath
                ) == 0) error(detail:outputPath + ' could not be written!');


                Topaz.Resources.setPath(path:oldPath);
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
                return data;

                Topaz.Resources.setPath(path:oldPath);

            }

        ); 


    }
}
