@Topaz = import(module:'Topaz');
return ::(terminal, filter, onDone) {
    @:path = Topaz.Filesystem.Path.new(fromNode:Topaz.Filesystem.DEFAULT_NODE.TOPAZ);

    @:unroller = Topaz.Entity.new();

    @:files = path.children;
    unroller.onStep = ::{
        if (files->keycount == 0) ::<= {
            unroller.remove();
            onDone();
        };
        @:next = files->pop;
        when (next == empty) empty; // shouldnt happen
        when (next.children != empty && next.children->keycount) empty;

        @name;
        if (filter != empty) ::<= {
            if (next.name->contains(key:filter))
                name = next.name;
        } else ::<= {
            name = next.name;
        };
        when(name == empty) empty;
        terminal.print(line:' ' + name);
    };


    terminal.attach(entity:unroller);
};