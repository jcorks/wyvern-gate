@:Topaz = import(module:'Topaz');
@:Shell = {
    commands : {


    },

    disabled : false,

    start:::(terminal) {
        terminal.clear();
        terminal.print(line:'tOS shell');
        terminal.print(line:'type "start" and enter to run the default program');
        terminal.print(line:'Enter "help" for commands.');
        terminal.print(line:'');
        terminal.print(line:'> ');

        @:shell = Topaz.Entity.new();


        @currentCommand = '';
        Topaz.Input.addUnicodeListener(
            onNewUnicode::(unicode) {
                when(Shell.disabled) empty;
                @:ch = ' '->setCharCodeAt(index:0, value:unicode);
                currentCommand = currentCommand + ch;
                terminal.printch(value:ch);
            }
        );

        Topaz.Input.addKeyboardListener(
            onPress::(input, value) {
                when(Shell.disabled) empty;
                if (input == Topaz.Input.KEY.ENTER) ::<= {
                    terminal.print(line:'>>>   '+ currentCommand);

                    @:command = Shell.commands[currentCommand];
                    if (command == empty) ::<= {
                        terminal.print(line:'Unknown command: ' + currentCommand);
                    } else ::<= {
                        command();
                    };

                    currentCommand = '';
                };
            }
        );

        terminal.attach(entity:shell);

    }
};
return Shell;