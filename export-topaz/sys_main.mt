

@:Topaz = import(module:'Topaz');
@:Terminal = import(module:'sys_terminal.mt');
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


display.setParameter(
    param:Topaz.Display.Parameter.Fullscreen,
    value:true
);



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
