@:Topaz = import(module:'Topaz');

@location = [''];


@term;
@currentCommand = '';

@:printPrompt ::{
    @:path = location->reduce(to:::(value, previous) <- if (previous == empty) '/'+value else previous+value);
    @:line = '['+path+'] > ' + currentCommand + '▓';
    term.reprint(line);
};

@:Shell = {
    commands : {
        help ::(arg){
            term.print(line:'tOS shell commands:');
            term.print(line:' start       runs the preset default program');
            term.print(line:' help        brings you here');
            term.print(line:' ls          lists files in the current directory');
            term.print(line:' view [file] opens a file for viewing');
            term.print(line:' edit [file] opens a file for editing');
            term.print(line:' shutdown    powers off the machine');
        },

        view ::(arg) {
            @:view = import(module:'topaz.view.mt');
            Shell.disabled = true;
            view(terminal:term, name:arg, onQuit::{
                term.clear();
                printPrompt();
                Shell.disabled = false;
            });
        },

        shutdown ::(arg){
            term.clear();
            term.print(line:'Shutting down...');
            Shell.disabled = true;

            @:shutter = Topaz.Entity.new();
            @counter = 100;
            shutter.onStep = ::{
                counter -= 1;
                if (counter <= 0 && Number.random() > 0.9)
                    Topaz.quit();
            };
            term.attach(entity:shutter);
        }

    },

    disabled : false,

    start:::(terminal) {
        term = terminal;



        terminal.clear();
        terminal.print(line:'tOS shell');
        terminal.print(line:'type "start" and enter to run the default program');
        terminal.print(line:'Enter "help" for commands.');
        terminal.print(line:'');
        terminal.print(line:'');
        printPrompt();

        @:shell = Topaz.Entity.new();
        Topaz.Input.addUnicodeListener(
            onNewUnicode::(unicode) {
                when(Shell.disabled) empty;

                @:ch = ' '->setCharCodeAt(index:0, value:unicode);
                currentCommand = currentCommand + ch;
                printPrompt();
            }
        );

        Topaz.Input.addKeyboardListener(
            onPress::(input, value) {
                when(Shell.disabled) empty;


                match(input) {
                    (Topaz.Input.KEY.ENTER):::<= {
                        @:args = currentCommand->split(token:' ');
                        @:command = Shell.commands[args[0]];
                        if (command == empty) ::<= {
                            terminal.print(line:'Unknown command: ' + args[0]);
                        } else ::<= {
                            command(arg:args[1]);
                        };
                        currentCommand = '';
                        if (!Shell.disabled)
                            printPrompt();
                    },

                    (Topaz.Input.KEY.BACKSPACE):::<= {
                        when (currentCommand->length <= 1) ::<= {
                            currentCommand = '';
                            printPrompt();
                        };
                        currentCommand = currentCommand->substr(from:0, to:currentCommand->length-2);
                        printPrompt();
                    }
                };
            }
        );

        terminal.attach(entity:shell);

    }
};
return Shell;