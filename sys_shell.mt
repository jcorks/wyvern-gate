@:Topaz = import(module:'Topaz');
@:class = import(module:'Matte.Core.Class');

return class(
    define::(this) {
        @location = [''];


        @term;
        @currentCommand = '';
        @currentDirectory = '';
        @onProgramCycle = ::{};
        @onProgramUnicode = ::(unicode){};
        @onProgramKeyboard = ::(input, value){};
        @programActive = false;


        @:printPrompt ::{
            @:path = location->reduce(to:::(value, previous) <- if (previous == empty) '/'+value else previous+value);
            @:line = '/'+currentDirectory+':: > ' + currentCommand + '▓';
            term.reprint(line);
        };


        @:endProgramError::(message) {
            term.clear();
            term.print(line:'An error occurred:');
            message.summary->split(token:'\n')->foreach(do:::(i, line) {
                term.print(line);
                printPrompt();
                programActive = false;
                onProgramCycle = ::{};
                onProgramUnicode = ::(unicode){};
                onProgramKeyboard = ::(input, value){};

            });

        };

        @:runCommand = ::(command, arg) {
            @:mod = import(module:'sys_'+command+'.mt');
            programActive = true;
            [::] {
                mod(terminal:term, arg, onDone::(message){
                    printPrompt();
                    programActive = false;
                    onProgramCycle = ::{};
                    onProgramUnicode = ::(unicode){};
                    onProgramKeyboard = ::(input, value){};
                });
            } : {
                onError:::(message) {
                    endProgramError(message);
                }
            };
        };


        this.interface = {
            currentDirectory : {
                get::<- currentDirectory,
                set::(value) <- currentDirectory = value
            },
            commands : {
                get::<- [
                    'start',
                    'clear',
                    'help',
                    'cd',
                    'ls',
                    'edit',
                    'shutdown',
                    'fullscreen'
                ]
            },

            onProgramUnicode: {
                set ::(value) <- onProgramUnicode = value
            },

            onProgramKeyboard: {
                set ::(value) <- onProgramKeyboard = value
            },

            onProgramCycle: {
                set ::(value) <- onProgramCycle = value
            },

            programActive : {
                get ::<- programActive
            },

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
                        when(this.programActive) ::<= {
                            [::] {
                                onProgramUnicode(unicode);
                            } : {
                                onError::(message) {
                                    endProgramError(message);
                                }
                            };
                        };
                        @:ch = ' '->setCharCodeAt(index:0, value:unicode);
                        currentCommand = currentCommand + ch;
                        printPrompt();
                    }
                );


                terminal.onStep = ::{
                    [::] {
                        onProgramCycle();
                    } : {
                        onError::(message) {
                            endProgramError(message);
                        }
                    };
                };

                Topaz.Input.addKeyboardListener(
                    onUpdate::(input, value) {
                        when(programActive) ::<= {
                            [::] {
                                onProgramKeyboard(input, value);
                            } : {
                                onError::(message) {
                                    endProgramError(message);
                                }
                            };
                        };

                        when(value < 1) empty;

                        match(input) {
                            (Topaz.Input.KEY.ENTER):::<= {
                                @:args = currentCommand->split(token:' ');
                                @:command = this.commands->findIndex(value:args[0]);
                                terminal.backspace(); // remove cursor
                                terminal.nextLine();
                                if (command == -1) ::<= {
                                    if (currentCommand != '')
                                        terminal.print(line:'Unknown command: ' + args[0]);
                                } else ::<= {
                                    runCommand(command:args[0], arg:args[1]);
                                };
                                currentCommand = '';
                                if (!programActive)
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
    }
).new();