return ::(terminal, arg, onDone) {
    terminal.print(line:'tOS shell commands:');
    terminal.print(line:' start       runs the preset default program');
    terminal.print(line:' clear       clears all terminal lines');
    terminal.print(line:' help        brings you here');
    terminal.print(line:' cd  [path]  changes directories');
    terminal.print(line:' ls [filter] lists files in the current directory');
    terminal.print(line:' edit [file] opens a file for editing');
    terminal.print(line:' shutdown    powers off the machine');

    onDone();
};