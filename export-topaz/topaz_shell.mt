@:Topaz = import(module:'Topaz');
@:class = import(module:'Matte.Core.Class');



return class(
    define::(this) {
        @location = [''];

        this.constructor = ::{
            this.enablePad(padIndex:0);
        }

        @term;
        @currentCommand = '';
        @currentDirectory = '';
        @onProgramCycle = ::{}
        @onProgramUnicode = ::(unicode){}
        @onProgramKeyboard = ::(input, value){}
        @programActive = true;
        @padHint = 0;
        @padListener;


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
                Topaz.Console.print(message:line);
            }
            printPrompt();
            programActive = false;
            onProgramCycle = ::{}
            onProgramUnicode = ::(unicode){}
            onProgramKeyboard = ::(input, value){}
        }

        @:runCommand = ::(command, arg) {
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
            @padIndex = padHint;
            @left = 
                Topaz.Input.getState(input:Topaz.Key.left) > 0 ||
                (if (!term.requestStringMappings)
                    Topaz.Input.getPadState(padIndex, input:Topaz.Pad.d_left) > 0 ||
                    Topaz.Input.getPadState(padIndex, input:Topaz.Pad.axisX) < -stickDeadzone
                else
                    Topaz.Input.getMappedState(name:'left') < -stickDeadzone
                )

            @right = 
                Topaz.Input.getState(input:Topaz.Key.right) > 0 ||
                (if (!term.requestStringMappings)
                    Topaz.Input.getPadState(padIndex, input:Topaz.Pad.d_right) > 0 ||
                    Topaz.Input.getPadState(padIndex, input:Topaz.Pad.axisX) > stickDeadzone
                else
                    Topaz.Input.getMappedState(name:'right') > stickDeadzone
                )


            @down = 
                Topaz.Input.getState(input:Topaz.Key.down) > 0 ||
                (if (!term.requestStringMappings)
                    Topaz.Input.getPadState(padIndex, input:Topaz.Pad.d_down) > 0 ||
                    Topaz.Input.getPadState(padIndex, input:Topaz.Pad.axisY) > stickDeadzone
                else
                    Topaz.Input.getMappedState(name:'down') > stickDeadzone
                )
                

            @up = 
                Topaz.Input.getState(input:Topaz.Key.up) > 0 ||
                (if (!term.requestStringMappings)
                    Topaz.Input.getPadState(padIndex, input:Topaz.Pad.d_up) > 0 ||
                    Topaz.Input.getPadState(padIndex, input:Topaz.Pad.axisY) < -stickDeadzone 
                else
                    Topaz.Input.getMappedState(name:'up') < -stickDeadzone 
                )



            padDirStates[0].state = left;
            padDirStates[1].state = right;
            padDirStates[2].state = up;
            padDirStates[3].state = down;

            
            @:delta = Topaz.getDeltaTime();
            foreach(padDirStates) ::(index, e) {
                @input = e.input;
                
                
                when (e.state == false)
                    e.time = 0;

               
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
                    'fullscreen',
                    'console',
                    'pad-config',
                    'pad-select'
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
            
            currentEnabledPad : {
                get ::<- padHint
            },

            enablePad ::(padIndex) {
                if (padListener != empty)
                    Topaz.Input.removeListener(id:padListener);
                    
                padHint = padIndex;
                padListener = Topaz.Input.addPadListener(
                    padIndex: padHint,
                    listener : {
                        onPress::(input, value) {
                            when(term == empty) empty;
                            when(term.requestStringMappings) empty;
                            match(input) {
                              (Topaz.Pad.a): ::<={
                                when (programActive)
                                    onProgramKeyboard(input:Topaz.Key.z, value:1);

                                currentCommand = 'start';
                                printPrompt();                                
                                runCommand(command:'start', arg:'');
                              },
    
                              (Topaz.Pad.b): ::<={
                                onProgramKeyboard(input:Topaz.Key.x, value:1);
                              },

                              (Topaz.Pad.start): ::<={
                              }
                            }
                        }
                    }
                );            
            },
            
            terminal : {
                get ::<- term
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
                @registeredPadIndex = -1;

                
                Topaz.Input.addMappedListener(
                    mappedName: 'confirm',
                    listener : {
                        onPress::(input, value) {
                            when(!term.requestStringMappings) empty;
                            when (programActive)
                                onProgramKeyboard(input:Topaz.Key.z, value:1);

                            currentCommand = 'start';
                            printPrompt();                                
                            runCommand(command:'start', arg:'');
                        }
                    }
                );                

                Topaz.Input.addMappedListener(
                    mappedName: 'deny',
                    listener : {
                        onPress::(input, value) {
                            when(!term.requestStringMappings) empty;
                            when (programActive)
                                onProgramKeyboard(input:Topaz.Key.x, value:1);
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
                @altHeld = false;
                @enterHeld = false;
                Topaz.Input.addKeyboardListener(
                    listener : {
                        onPress::(input, value) {
                            if (((input == Topaz.Key.lalt ||
                                  input == Topaz.Key.ralt) && enterHeld) 
                                  ||
                                ((input == Topaz.Key.enter) && altHeld)
                            ) ::<= {
                                @:Settings = import(:'topaz_settings.mt');
                                @:props = {
                                    fullscreen : if(Topaz.ViewManager.getDefault().getParameter(param:Topaz.Display.Parameter.Fullscreen)==1) false else true
                                }
                                Topaz.ViewManager.getDefault().setParameter(
                                    param:Topaz.Display.Parameter.Fullscreen,
                                    value: props.fullscreen == true
                                );  
                                Settings.set(:props);
                            }                          
                                

                            when (!programActive) empty;
                            match(input) {
                              (Topaz.Key.z,
                               Topaz.Key.x,
                               Topaz.Key.enter,
                               Topaz.Key.backspace,
                               Topaz.Key.esc,
                               Topaz.Key.space):
                                    onProgramKeyboard(input, value:1)

                            }
                        },
                        onUpdate::(input, value) {
                            if (input == Topaz.Key.enter)
                                enterHeld = value != 0;
                            if (input == Topaz.Key.lalt ||
                                input == Topaz.Key.ralt)
                                altHeld = value != 0;

                                
                            when(programActive) ::<= {
                                match(input) {
                                    (Topaz.Key.up,
                                    Topaz.Key.down,
                                    Topaz.Key.left,
                                    Topaz.Key.right): empty
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
