@Topaz = import(module:'Topaz');
return ::(terminal, arg, onDone) {
    @filter = arg;
    @:Shell = import(module:'sys_shell.mt');


    @:path = Topaz.Filesystem.getPath(node:Topaz.Filesystem.DefaultNode.Topaz);


    @:dirs = {}
    @:files = path.getChildren();


    @:output = [];        

    foreach(path.getChildren())::(i, next) {
        @:next = files->pop;
        when (next == empty) empty; // shouldnt happen
        when (next.getChildren()->keycount) empty;

        // only current directory
        when(Shell.currentDirectory->length > 0 && !next.getName()->contains(key:Shell.currentDirectory+'_')) empty;

        // check to see if the real file is prefixed with a directory
        if (Shell.currentDirectory == '') ::<= {
            @split = next.getName()->split(token:'_');
            if (split->keycount >= 2) ::<= {
                dirs[(split[0])] = true;
            }
        }

        @name;
        if (filter != empty) ::<= {
            if (next.getName()->contains(key:filter))
                name = next.getName();
        } else ::<= {
            name = next.getName();
        }
        when(name == empty) empty;
        // nothing in the toplevel directory.
        if (Shell.currentDirectory->length) ::<= {
            name = name->replace(key:Shell.currentDirectory+'_', with:'');
            output->push(value:name);
        }
    }

    foreach(dirs)::(name, val) {
        output->push(value:name + '/');
    }




    Shell.onProgramCycle = ::{
        when (output->keycount == 0) ::<= {
            onDone();
        }
        terminal.print(line:' ' + output->pop);
    }


}
