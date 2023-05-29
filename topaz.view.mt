@:Topaz = import(module:'Topaz');
return ::(terminal, name, onQuit) {
    @listener;
    [::] {
        terminal.clear();

        @lines = [
        ];

        @:nameFiltered = name->replace(keys:['/', '\\', '..'], with: '');
        @item = Topaz.Resources.createAsset(
            path:nameFiltered,
            name:name
        );

        if (item == empty)
            item = Topaz.Resources.fetchAsset(name:name);

        when(item == empty)
            error(detail:'No such item to view.');


        @:data = item.string;
        lines = data->split(token:'\n');

        @cursorLine = 0;
        @cursorPos = 0;

        @viewLine = 0;
        @viewPos = 0;

        @:renderTerminal = ::{
            terminal.clear();
            terminal.print(line:'Viewing "' + name + '"');
            terminal.print(line:'____________________________________________________________________');

            [0, 21]->for(do:::(i) {
                terminal.print(line:
                    ''+(viewLine+i+1) + 
                        (if (viewLine+i < 9) '  | ' else ' | ') + 
                    (if (i+viewLine >= lines->keycount) '' else ::<={
                            @line = lines[i+viewLine];
                            when(viewPos >= line->length) '';
                            return line->substr(from:viewPos, to:line->length-1);
                    })
                );
            });

            terminal.print(line:'____________________________________________________________________');
            terminal.print(line:'Ctrl+x to quit');

        };
        @controlHeld = 0;
        listener = Topaz.Input.addKeyboardListener(

            onUpdate::(input, value) {

                match(input) {
                    (Topaz.Input.KEY.L_CTRL,
                     Topaz.Input.KEY.R_CTRL):::<= {
                        controlHeld = value;
                    },

                    (Topaz.Input.KEY.X):::<= {
                        if (controlHeld > 0) ::<= {
                            Topaz.Input.removeListener(id:listener);
                            onQuit();            
                        };
                    },
                    (Topaz.Input.KEY.DOWN):::<= {
                        viewLine += 1;
                        if (viewLine >= lines->keycount - 18)
                            viewLine = lines->keycount - 18;
                        renderTerminal();
                    },

                    (Topaz.Input.KEY.UP):::<= {
                        viewLine -= 1;
                        if (viewLine < 0)
                            viewLine = 0;
                        renderTerminal();
                    },

                    (Topaz.Input.KEY.RIGHT):::<= {
                        viewPos += 1;
                        renderTerminal();
                    },

                    (Topaz.Input.KEY.LEFT):::<= {
                        viewPos -= 1;
                        if (viewPos < 0)
                            viewPos = 0;
                        renderTerminal();
                    }
                };
            }
        );


        renderTerminal();
    } : {
        onError::(message) {
            if (listener != empty)
                Topaz.Input.removeListener(id:listener);
            terminal.print(line:'An error occurred: ' + message.summary);
            onQuit();
        }
    };





};