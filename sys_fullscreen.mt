@:Topaz = import(module:'Topaz');

return ::(terminal, arg, onDone) {
    when(arg != 'on' && arg != 'off') ::<= {
        terminal.print(line:'Argument needs to be either "on" or "off"');
        terminal.print(line:'Unrecognized argument "' + arg + '"');
    };
    @:enable = (arg == 'on');


    Topaz.defaultDisplay.setParameter(
        parameter:Topaz.Display.PARAMETER.FULLSCREEN,
        value:enable
    );
    onDone();
};