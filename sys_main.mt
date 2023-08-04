

@:Topaz = import(module:'Topaz');
@:Terminal = import(module:'sys_terminal.mt');
// if topaz is detected, setup its canvas and main loop

@:term = Terminal.new();
term.position = {
    x: -Topaz.defaultDisplay.width/2,
    y:  Topaz.defaultDisplay.height/2 - term.LINE_SPACING*2
}
Topaz.defaultDisplay.root = term;
/*
Topaz.defaultDisplay.setParameter(
    parameter:Topaz.Display.PARAMETER.FULLSCREEN,
    value:true
);
*/

@:shell = import(module:'sys_shell.mt');
import(module:'sys_bootseq.mt')(
    terminal:term,
    onBoot ::(arg){
        term.clear();
        shell.start(terminal:term);
        shell.commands.start = ::(arg) {

        }
    }
);
