@:Topaz   = import(module:'Topaz');

@currentList;

@newMapping::(name, positive, input) {
    if (mapping[name] != empty) ::<= {
        Topaz.Input.unmap(name);
    }
    mapping[name] = {
        positive: positive,
        input: input
    }
    @:Shell = import(module:'sys_shell.mt');
    Topaz.Input.mapPad(name, pad:Shell.currentEnabledPad, input);
}

@:DEADZONE = 0.35;


@mapping = empty;


@:initialize ::{
    mapping = {};
    newMapping(name:'confirm', positive:true,  input:Topaz.Pad.a);
    newMapping(name:'deny',    positive:true,  input:Topaz.Pad.b);
    newMapping(name:'up',      positive:true,  input:Topaz.Pad.axisY);
    newMapping(name:'down',    positive:false, input:Topaz.Pad.axisY);
    newMapping(name:'left',    positive:false, input:Topaz.Pad.axisX);
    newMapping(name:'right',   positive:true,  input:Topaz.Pad.axisX);    
}



// Runs the given function once an input from pad 0 is registered
@:pollInput ::(terminal, axis, name, onDone) {
    @:idState = [];
    @:Shell = import(module:'sys_shell.mt');
 
 
    @done = false;
    @lastInput;
    @lastValue;
    @:pollID = Topaz.Input.addPadListener(
        padIndex: Shell.currentEnabledPad,
        listener : {
            onUpdate ::(input, value) {
                when(done) empty;
                // button callbacks first 
                if (axis == true) ::<= {
                    if (input >= Topaz.Pad.axisX && input <= Topaz.Pad.axisL4) ::<= {

                        when (value->abs < DEADZONE && idState[input] == 2) ::<= {
                            finish(input);
                        }

                        if (value->abs < DEADZONE && idState[input] == empty) ::<= {
                            idState[input] = 1;
                            Topaz.Console.print(message:'firstID ' + input);
                        }

                        if (value->abs > DEADZONE && idState[input] == 1) ::<= {
                            idState[input] = 2;
                            Topaz.Console.print(message:'secondID ' + input);
                        }

               
                    }
                    
                } else ::<= {
                    if (lastInput == input) ::<= {
                        if (value == 0 && input >= Topaz.Pad.a && input <= Topaz.Pad.b32) 
                            finish(input);
                    }
                }
                lastInput = input;
                lastValue = value;
            }
        }
    );


    @:finish::(input) {
        Topaz.Input.removeListener(id:pollID);
        
        newMapping(name, input);
        if (input >= Topaz.Pad.a && input <= Topaz.Pad.b32)
            terminal.print(line: 'Button ' + (input - Topaz.Pad.a))
        else
            terminal.print(line: 'Axis ' + (input - Topaz.Pad.axisX));
        onDone();
        done = true;
    }

}

return ::(terminal, arg, onDone) {
    if (mapping == empty)
        initialize();

    terminal.print(line: 'This utility sets overrides for the ');
    terminal.print(line: 'current mappings on the connected gamepad.');

    currentList = [
        {name:'up',      axis: true},
        {name:'down',    axis: true},
        {name:'left',    axis: true},
        {name:'right',   axis: true},
        {name:'deny',    axis: false},
        {name:'confirm', axis: false}
    ];
    
    @:doNext = ::{
        when (currentList->size == 0) ::<= {
            terminal.requestStringMappings = true;
            onDone();
        }
            
        terminal.print(line: 'Use the gamepad to enter the input for:');
        @:entry = currentList->pop;
        terminal.print(line: entry.name + (if (entry.axis) '(must be an axis!)' else ''));

        pollInput(
            terminal,
            name:entry.name,
            axis: entry.axis,
            onDone :: {
                doNext();
            }
        );
    }
    
    doNext();

}
