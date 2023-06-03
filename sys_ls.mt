@Topaz = import(module:'Topaz');
return ::(terminal, arg, onDone) {
    @filter = arg;
    @:Shell = import(module:'sys_shell.mt');


    @:path = Topaz.Filesystem.Path.new(fromNode:Topaz.Filesystem.DEFAULT_NODE.TOPAZ);


    @:dirs = {};
    @:files = path.children;


    @:output = [];        

    path.children->foreach(do:::(i, next) {
        @:next = files->pop;
        when (next == empty) empty; // shouldnt happen
        when (next.children != empty && next.children->keycount) empty;

        // only current directory
        when(Shell.currentDirectory->length > 0 && !next.name->contains(key:Shell.currentDirectory+'_')) empty;

        // check to see if the real file is prefixed with a directory
        if (Shell.currentDirectory == '') ::<= {
            @split = next.name->split(token:'_');
            if (split->keycount >= 2) ::<= {
                dirs[(split[0])] = true;
            };
        };

        @name;
        if (filter != empty) ::<= {
            if (next.name->contains(key:filter))
                name = next.name;
        } else ::<= {
            name = next.name;
        };
        when(name == empty) empty;
        // nothing in the toplevel directory.
        if (Shell.currentDirectory->length) ::<= {
            name = name->replace(key:Shell.currentDirectory+'_', with:'');
            output->push(value:name);
        };
    });

    dirs->foreach(do:::(name, val) {
        output->push(value:name + '/');
    });




    Shell.onProgramCycle = ::{
        when (output->keycount == 0) ::<= {
            onDone();
        };
        terminal.print(line:' ' + output->pop);
    };


};