

@:Topaz = import(module:'Topaz');
@:Terminal = import(module:'sys_terminal.mt');
// if topaz is detected, setup its canvas and main loop

@:term = Terminal.new();

@:display = Topaz.ViewManager.getDefault();
@:displayWidth = ::{
    return display.getParameter(param:Topaz.Display.Parameter.Width);
}

@:displayHeight = ::{
    return display.getParameter(param:Topaz.Display.Parameter.Height);
}


term.setPosition(value:{
    x: -displayWidth()/2,
    y:  displayHeight()/2 - term.LINE_SPACING*2
});
display.setRoot(newRoot:term);
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
