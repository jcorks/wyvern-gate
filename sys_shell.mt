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
        
        @:padDirStates = [
            {input:Topaz.Key.left  , time:0},
            {input:Topaz.Key.right , time:0},
            {input:Topaz.Key.up    , time:0},
            {input:Topaz.Key.down  , time:0} 
        ];
        
        @:stickDeadzone = 0.35;
        @:HOLD_TIME_MIN = 0.4;
        @:HOLD_TIME_REPEAT = 0.08;
        @:checkRepeatPadInputs ::{
            @left = 
                Topaz.Input.getPadState(padIndex:0, input:Topaz.Pad.d_left) > 0 ||
                Topaz.Input.getPadState(padIndex:0, input:Topaz.Pad.axis_x) < -stickDeadzone ||
                Topaz.Input.getState(input:Topaz.Key.left) > 0

            @right = 
                Topaz.Input.getPadState(padIndex:0, input:Topaz.Pad.d_right) > 0 ||
                Topaz.Input.getPadState(padIndex:0, input:Topaz.Pad.axis_x) > stickDeadzone ||
                Topaz.Input.getState(input:Topaz.Key.right) > 0


            @down = 
                Topaz.Input.getPadState(padIndex:0, input:Topaz.Pad.d_down) > 0 ||
                Topaz.Input.getPadState(padIndex:0, input:Topaz.Pad.axis_y) > stickDeadzone ||
                Topaz.Input.getState(input:Topaz.Key.down) > 0
                

            @up = 
                Topaz.Input.getPadState(padIndex:0, input:Topaz.Pad.d_up) > 0 ||
                Topaz.Input.getPadState(padIndex:0, input:Topaz.Pad.axis_y) < -stickDeadzone ||
                Topaz.Input.getState(input:Topaz.Key.up) > 0



            padDirStates[0].state = left;
            padDirStates[1].state = right;
            padDirStates[2].state = up;
            padDirStates[3].state = down;

            
            @:delta = Topaz.getDeltaTime();
            foreach(padDirStates) ::(index, e) {
                @input = e.input;
                
                
                when (e.state == false)
                    e.time = 0;

                Topaz.Console.print(message:e.time);
               
                if (e.time == 0) 
                    onProgramKeyboard(input, value:1)
                    
                e.time += delta;
                if (e.time > HOLD_TIME_MIN) ::<= {
                    if (e.time > HOLD_TIME_MIN + HOLD_TIME_REPEAT) ::<= {
                        e.time = HOLD_TIME_MIN;
                        onProgramKeyboard(input, value:1)
                    }
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
                        
                            match(input) {
                              (Topaz.Pad.a): ::<={
                                onProgramKeyboard(input:Topaz.Key.Z, value:1);
                              },

                              (Topaz.Pad.b): ::<={
                                onProgramKeyboard(input:Topaz.Key.X, value:1);
                              }


                            }

                            match(input) {
                                (Topaz.Pad.A,
                                 Topaz.Pad.START): ::<={
                                    currentCommand = 'start';
                                    printPrompt();                                
                                    runCommand(command:'start', arg:'');
                                }
                            }
                        }
                    }
                );


                @:termManager = Topaz.Entity.create(
                    attributes : {
                        onStep ::{
                            {:::} {
                                checkRepeatPadInputs();
                                onProgramCycle();
                            } : {
                                onError::(message) {
                                    endProgramError(message);
                                }
                            }
                        }
                    }
                )
                
                term.attach(child:termManager);

                Topaz.Input.addKeyboardListener(
                    listener : {
                        onUpdate::(input, value) {
                            when(programActive) ::<= {
                                {:::} {
                                    match(input) {
                                      (Topaz.Key.up,
                                      Topaz.Key.down,
                                      Topaz.Key.left,
                                      Topaz.Key.right): empty,
                                      default:
                                        onProgramKeyboard(input, value)
                                    }
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
