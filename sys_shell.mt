@:Topaz = import(module:'Topaz');
@:class = import(module:'Matte.Core.Class');

return class(
    define::(this) {
        @location = [''];


        @term;
        @currentCommand = '';
        @currentDirectory = '';
        @onProgramCycle = ::{}
        @onProgramUnicode = ::(unicode){}
        @onProgramKeyboard = ::(input, value){}
        @programActive = false;


        @:printPrompt ::{
            @:path = location->reduce(to:::(value, previous) <- if (previous == empty) '/'+value else previous+value);
            @:line = '/'+currentDirectory+':: > ' + currentCommand + '▓';
            term.reprint(line);
        }


        @:endProgramError::(message) {
            term.clear();
            term.print(line:'An error occurred:');
            foreach(message.summary->split(token:'\n'))::(i, line) {
                term.print(line);
                printPrompt();
                programActive = false;
                onProgramCycle = ::{}
                onProgramUnicode = ::(unicode){}
                onProgramKeyboard = ::(input, value){}

            }

        }

        @:runCommand = ::(command, arg) {
            @:mod = import(module:'sys_'+command+'.mt');
            programActive = true;
            {:::} {
                mod(terminal:term, arg, onDone::(message){
                    printPrompt();
                    programActive = false;
                    onProgramCycle = ::{}
                    onProgramUnicode = ::(unicode){}
                    onProgramKeyboard = ::(input, value){}
                });
            } : {
                onError:::(message) {
                    endProgramError(message);
                }
            }
        }


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
                terminal.print(line:'Pads connected: ' + Topaz.Input.queryPads()->keycount);
                terminal.print(line:'');
                terminal.print(line:'');
                printPrompt();

                Topaz.Input.addUnicodeListener(
                    listener : {
                        onNewUnicode::(unicode) {
                            when(programActive) ::<= {
                                {:::} {
                                    onProgramUnicode(unicode);
                                } : {
                                    onError::(message) {
                                        endProgramError(message);
                                    }
                                }
                            }
                            @:ch = ' '->setCharCodeAt(index:0, value:unicode);
                            currentCommand = currentCommand + ch;
                            printPrompt();
                        }
                    }
                );


                @lastLeftStickX = 0;
                @lastLeftStickY = 0;
                @:stickDeadzone = 0.35;
                Topaz.Input.addPadListener(
                    padIndex: 0,
                    listener : {
                        onUpdate::(input, value) {
                            when(programActive == false) empty;


                            match(input) {


                              (Topaz.Pad.axis_x): ::<= {
                                if (value->abs > stickDeadzone && lastLeftStickX->abs < stickDeadzone) ::<= {
                                    if (value < 0)
                                        onProgramKeyboard(input:Topaz.Key.left, value:1)
                                    else
                                        onProgramKeyboard(input:Topaz.Key.right, value:1);
                                }
                                lastLeftStickX = value;
                              },


                              (Topaz.Pad.axis_y): ::<= {
                                if (value->abs > stickDeadzone && lastLeftStickY->abs < stickDeadzone) ::<= {
                                    if (value < 0)
                                        onProgramKeyboard(input:Topaz.Key.up, value:1)
                                    else
                                        onProgramKeyboard(input:Topaz.Key.down, value:1);
                                }
                                lastLeftStickY = value;
                              }



                            }
                        },

                        onPress::(input) {
                            when(programActive)
                                match(input) {
                                  (Topaz.PAD.a): ::<={
                                    onProgramKeyboard(input:Topaz.Key.z, value:1);
                                  },

                                  (Topaz.PAD.b): ::<={
                                    onProgramKeyboard(input:Topaz.Key.x, value:1);
                                  },



                                  (Topaz.PAD.d_up):::<= {
                                    onProgramKeyboard(input:Topaz.Key.up, value:1);
                                  },
                                  (Topaz.PAD.d_down):::<= {
                                    onProgramKeyboard(input:Topaz.Key.down, value:1);
                                  },
                                  (Topaz.PAD.d_left):::<= {
                                    onProgramKeyboard(input:Topaz.Key.left, value:1);
                                  },
                                  (Topaz.PAD.d_right):::<= {
                                    onProgramKeyboard(input:Topaz.Key.right, value:1);
                                  }
                                }
                            ;                                

                            match(input) {
                                (Topaz.PAD.A,
                                 Topaz.PAD.START): ::<={
                                    currentCommand = 'start';
                                    printPrompt();                                
                                    runCommand(command:'start', arg:'');
                                }
                            }
                        }
                    }
                );

                @:shell = Topaz.Entity.create(
                    attributes : {
                        onStep : ::{
                            {:::} {
                                onProgramCycle();
                            } : {
                                onError::(message) {
                                    endProgramError(message);
                                }
                            }           
                        }         
                    }
                );
                
                terminal.attach(child:shell);

                Topaz.Input.addKeyboardListener(
                    listener : {
                        onUpdate::(input, value) {
                            when(programActive) ::<= {
                                {:::} {
                                    onProgramKeyboard(input, value);
                                } : {
                                    onError::(message) {
                                        endProgramError(message);
                                    }
                                }
                            }

                            when(value < 1) empty;
                            match(input) {
                                (Topaz.Key.enter):::<= {
                                    @:args = currentCommand->split(token:' ');
                                    @:command = this.commands->findIndex(value:args[0]);
                                    terminal.backspace(); // remove cursor
                                    terminal.nextLine();
                                    if (command == -1) ::<= {
                                        if (currentCommand != '')
                                            terminal.print(line:'Unknown command: ' + args[0]);
                                    } else ::<= {
                                        runCommand(command:args[0], arg:args[1]);
                                    }
                                    currentCommand = '';
                                    if (!programActive)
                                        printPrompt();
                                },

                                (Topaz.Key.backspace):::<= {
                                    when (currentCommand->length <= 1) ::<= {
                                        currentCommand = '';
                                        printPrompt();
                                    }
                                    currentCommand = currentCommand->substr(from:0, to:currentCommand->length-2);
                                    printPrompt();
                                }
                            }
                        }
                    }
                );
            }            
        }
    }
).new();
