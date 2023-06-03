@Topaz = import(module:'Topaz');
return ::(terminal, arg, onDone) {
    @which = arg;
    @:Shell = import(module:'sys_shell.mt');

    when(which == '..' && Shell.currentDirectory->length > 0) ::<= {
        Shell.currentDirectory = '';
        onDone();
    };


    @:path = Topaz.Filesystem.Path.new(fromNode:Topaz.Filesystem.DEFAULT_NODE.TOPAZ);


    @:dirs = {};
    @:files = path.children;


    @:output = [];        

    path.children->foreach(do:::(i, next) {
        @:next = files->pop;
        when (next == empty) empty; // shouldnt happen
        when (next.children != empty && next.children->keycount) empty;

        // check to see if the real file is prefixed with a directory
        if (Shell.currentDirectory == '') ::<= {
            @split = next.name->split(token:'_');
            if (split->keycount >= 2) ::<= {
                dirs[(split[0])] = true;
            };
        };
    });

    @ok = [::] {
        dirs->foreach(do:::(name, val) {
            if (name == which) ::<= {
                Shell.currentDirectory = which;
                send(message:true);
            };
        });

        return false;
    };

    if (!ok)
        terminal.print(line:'Could not find directory "'+which +'"');
    onDone();
};