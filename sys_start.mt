@:Topaz = import(module:'Topaz');
@Shell = import(module:'sys_shell.mt');

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
        canvas.onCommit = ::(lines){
            currentCanvas = lines;
            canvasChanged = true;
        };

        Shell.onProgramKeyboard = ::(input, value) {
            when(value < 1) empty;
            match(input) {
                (Topaz.Input.KEY.Z,
                Topaz.Input.KEY.ENTER):::<= {
                    windowEvent.commitInput(input:4);
                },

                (Topaz.Input.KEY.X,
                Topaz.Input.KEY.BACKSPACE):::<= {
                    windowEvent.commitInput(input:5);
                },

                (Topaz.Input.KEY.LEFT):::<= {
                    windowEvent.commitInput(input:0);
                },
                (Topaz.Input.KEY.UP):::<= {
                    windowEvent.commitInput(input:1);
                },
                (Topaz.Input.KEY.RIGHT):::<= {
                    windowEvent.commitInput(input:2);
                },
                (Topaz.Input.KEY.DOWN):::<= {
                    windowEvent.commitInput(input:3);
                }

            };
            
        };


        @lastInput;
        Shell.onProgramCycle = ::{
            windowEvent.commitInput(input:lastInput);
            if (canvasChanged) ::<= {
                @:lines = currentCanvas;
                lines->foreach(do:::(index, line) {
                    terminal.updateLine(index, text:line);
                }); 
                canvasChanged = false;    
            };

        };

        instance.mainMenu(
            onSaveState :::(
                slot,
                data
            ) {
            },

            onLoadState :::(
                slot
            ) {

            }

        ); 


    };
};
