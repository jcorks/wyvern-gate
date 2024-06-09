@:Topaz = import(module:'Topaz');

return ::(terminal, arg, onDone) {
    when(arg != 'on' && arg != 'off') ::<= {
        terminal.print(line:'Argument needs to be either "on" or "off"');
        if (arg != empty)
            terminal.print(line:'Unrecognized argument "' + arg + '"');
        onDone();
    }
    @:enable = (arg == 'on');

    @:Settings = import(:'sys_settings.mt');
    @:props = {
        fullscreen : enable
    }
    Settings.set(:props);
    Topaz.ViewManager.getDefault().setParameter(
        param:Topaz.Display.Parameter.Fullscreen,
        value:enable
    );
    onDone();
}
