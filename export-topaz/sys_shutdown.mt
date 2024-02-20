@:Topaz = import(module:'Topaz');
@:Shell = import(module:'sys_shell.mt');
return ::(terminal, arg, onDone) {
    terminal.clear();
    terminal.print(line:'Shutting down...');

    @counter = 100;
    Shell.onProgramCycle = ::{
        counter -= 1;
        if (counter <= 0 && Number.random() > 0.9)
            Topaz.quit();
    }
}
