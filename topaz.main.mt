


@:Topaz = import(module:'Topaz');
@:Terminal = import(module:'topaz.terminal.mt');
// if topaz is detected, setup its canvas and main loop

@:term = Terminal.new();
term.position = {
    x: -Topaz.defaultDisplay.width/2,
    y:  Topaz.defaultDisplay.height/2 - term.LINE_SPACING*2
};
Topaz.defaultDisplay.root = term;
@:shell = import(module:'topaz.shell.mt');
import(module:'topaz.bootseq.mt')(
    terminal:term,
    onBoot ::{
        term.clear();
        shell.start(terminal:term);
        shell.commands = {
            'start' : start
        };

    }
);


@:start = ::{
    shell.disabled = true;
    @:canvas = import(module:'singleton.canvas.mt');
    @:instance = import(module:'singleton.instance.mt');
    @:dialogue = import(module:'singleton.dialogue.mt');

    @currentCanvas;
    @canvasChanged = false;
    canvas.onCommit = ::(lines){
        currentCanvas = lines;
        canvasChanged = true;
    };

    Topaz.Input.addKeyboardListener(
        onPress :::(input, value) {
            match(input) {
              (Topaz.Input.KEY.Z,
               Topaz.Input.KEY.ENTER):::<= {
                dialogue.commitInput(input:4);
              },

              (Topaz.Input.KEY.X,
               Topaz.Input.KEY.BACKSPACE):::<= {
                dialogue.commitInput(input:5);
              },

              (Topaz.Input.KEY.LEFT):::<= {
                dialogue.commitInput(input:0);
              },
              (Topaz.Input.KEY.UP):::<= {
                dialogue.commitInput(input:1);
              },
              (Topaz.Input.KEY.RIGHT):::<= {
                dialogue.commitInput(input:2);
              },
              (Topaz.Input.KEY.DOWN):::<= {
                dialogue.commitInput(input:3);
              }

            };
        }
    );


    @lastInput;
    canvas.onStep = ::{
        dialogue.commitInput(input:lastInput);
        if (canvasChanged) ::<= {
            @:lines = currentCanvas;
            lines->foreach(do:::(index, line) {
                canvas.updateLine(index, text:line);
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