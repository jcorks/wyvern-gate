@:Topaz   = import(module:'Topaz');

return ::(terminal, arg, onDone) {
    @:Shell = import(module:'sys_shell.mt');

    terminal.print(line:'Currently connected pads:');    
    foreach(Topaz.Input.queryPads()) ::(k, v) {
        terminal.print(line:
            (if (k == Shell.currentEnabledPad) '*' else ' ') + (k+1) + ' - ' + Topaz.Input.getPadName(padIndex:k)
        );
    }
    
    
    terminal.print(line:'Use which pad number?');
    Shell.onProgramUnicode = ::(unicode) {
        match(unicode) {
            (49, 50, 51, 52, 53, 54, 55, 56, 57):::<= { 
                @:padIndex = unicode - 49; // ascii '1';
                Shell.enablePad(padIndex);
                terminal.print(line: 'OK! Using ' +  Topaz.Input.getPadName(padIndex) + ' in slot ' + (padIndex + 1));
                onDone();
            }
        }
    }
    
    
}
