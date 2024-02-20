@Topaz = import(module:'Topaz');
return ::(terminal, arg, onDone) {
    @which = arg;
    @:Shell = import(module:'sys_shell.mt');

    when(which == '..' && Shell.currentDirectory->length > 0) ::<= {
        Shell.currentDirectory = '';
        onDone();
    }


    @:path = Topaz.Filesystem.getPath(node:Topaz.Filesystem.DefaultNode.Topaz);


    @:dirs = {}
    @:files = path.getChildren();


    @:output = [];        

    foreach(path.getChildren())::(i, next) {
        @:next = files->pop;
        when (next == empty) empty; // shouldnt happen
        when (next.getChildren()->keycount) empty;

        // check to see if the real file is prefixed with a directory
        if (Shell.currentDirectory == '') ::<= {
            @split = next.getName()->split(token:'_');
            if (split->keycount >= 2) ::<= {
                dirs[(split[0])] = true;
            }
        }
    }

    @ok = {:::} {
        foreach(dirs)::(name, val) {
            if (name == which) ::<= {
                Shell.currentDirectory = which;
                send(message:true);
            }
        }

        return false;
    }

    if (!ok)
        terminal.print(line:'Could not find directory "'+which +'"');
    onDone();
}
