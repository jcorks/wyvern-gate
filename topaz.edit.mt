@:Topaz = import(module:'Topaz');
return ::(terminal, name, onQuit) {
    @listener;
    @typing;
    [::] {
        terminal.clear();
        @cursorCharacter = '▓';
        @:VIEWSPACE_HEIGHT = terminal.HEIGHT - 5;
        @:VIEWSPACE_WIDTH  = terminal.WIDTH - 8; // 8 is for the header
        @lines = [''];

        @:nameFiltered = name->replace(keys:['/', '\\', '..'], with: '');
        @item = Topaz.Resources.createAsset(
            path:nameFiltered,
            name:name
        );

        if (item == empty)
            item = Topaz.Resources.fetchAsset(name:name);

        if (item == empty) ::<= {
            item = Topaz.Resources.createAsset(name);
        } else ::<= {
            @:data = item.string;
            lines = data->split(token:'\n');        
        };



        @cursorLine = 0;
        @cursorPos = 0;

        @viewLine = 0;
        @viewPos = 0;

        @lastStatus = empty;
        @lastStatusCounter = 0;
        @:renderTerminal = ::{
            terminal.clear();
            if (lastStatus == empty)
                terminal.print(line:'Editing "' + name + '"')
            else ::<= {
                terminal.print(line:'[Update] ' + lastStatus);
                lastStatusCounter -= 1;
                if (lastStatusCounter == 0) ::<= {
                    lastStatus = empty;
                };
            };
            terminal.print(line:'____________________________________________________________________');
            
            [0, VIEWSPACE_HEIGHT]->for(do:::(i) {
                @lineNumber = ''+(if (i+viewLine == cursorLine) '   ->' else (viewLine+i+1));
                lineNumber = lineNumber + (
                    match(lineNumber->length) {
                        (1): '    ',
                        (2):  '   ',
                        (3):   '  ',
                        (4):    ' ',
                        default: ''
                    }
                );
                
                @header = lineNumber + ' | ';
                @line = header + 
                    (if (i+viewLine >= lines->keycount) '' else ::<={
                            @line = lines[i+viewLine];
                            when(viewPos >= line->length) '';
                            return line->substr(from:viewPos, to:line->length-1);
                    }) + ' '; // add an extra character for cursor replacement if applicable

                // assume cursor will always be in view
                if (i+viewLine == cursorLine) ::<= {
                    when(header->length + cursorPos - viewPos < 0 ||
                         header->length + cursorPos - viewPos > line->length) empty;
                    line = line->setCharAt(index:header->length + cursorPos - viewPos, value:cursorCharacter);
                };


                
                terminal.print(line);
            });

            terminal.print(line:'____________________________________________________________________');
            terminal.print(line:'Ctrl+x to quit, Ctrl+s to save');

        };

        @:checkCursorInBounds = ::{
            viewLine = (cursorLine - VIEWSPACE_HEIGHT / 2)->floor;
            if (viewLine > lines->keycount - VIEWSPACE_HEIGHT) viewLine = lines->keycount - VIEWSPACE_HEIGHT;
            if (viewLine < 0) viewLine = 0;

            if (cursorPos > viewPos + VIEWSPACE_WIDTH)
                viewPos = (cursorPos - VIEWSPACE_WIDTH / 2)->floor;

            if (cursorPos - viewPos < 0)
                viewPos = (cursorPos - VIEWSPACE_WIDTH / 2)->floor;

            if (viewPos < 0) viewPos = 0;


        };


        @:getCurrentLine ::{
            return lines[cursorLine];
        };

        @:moveCursorUp = ::{
            cursorLine -= 1;
            if (cursorLine < 0) ::<= {
                cursorLine = 0;
                cursorPos = 0;
            };
            if (cursorPos > getCurrentLine()->length)
                cursorPos = getCurrentLine()->length;
            checkCursorInBounds();
        };


        @:moveCursorDown = ::{
            cursorLine += 1;
            if (cursorLine > lines->keycount) ::<= {
                cursorLine = lines->keycount-1;
                cursorPos = getCurrentLine()->length;
            };
            if (cursorPos > getCurrentLine()->length)
                cursorPos = getCurrentLine()->length;
            checkCursorInBounds();
        };


        @:moveCursorRight = ::{
            cursorPos += 1;
            if (cursorPos > getCurrentLine()->length) ::<= {
                cursorPos = 0;
                moveCursorDown();
            };

            checkCursorInBounds();
        };

        @:moveCursorLeft = ::{
            cursorPos -= 1;
            if (cursorPos < 0) ::<= {
                @isStart = cursorLine == 0;
                moveCursorUp();
                if (!isStart)
                    cursorPos = getCurrentLine()->length;
            };

            checkCursorInBounds();
        };


        @controlHeld = 0;
        typing = Topaz.Input.addUnicodeListener(
            onNewUnicode::(unicode) {
                @:ch = ' '->setCharCodeAt(index:0, value:unicode);
                when(cursorPos == 0) ::<= {
                    lines[cursorLine] = getCurrentLine() + ch;
                    moveCursorRight();
                    renderTerminal();
                };

                when(cursorPos == getCurrentLine()->length) ::<= {
                    lines[cursorLine] = getCurrentLine() + ch;
                    moveCursorRight();
                    renderTerminal();
                };



                lines[cursorLine] = 
                    getCurrentLine()->substr(from:0, to:cursorPos-1) +
                    ch + 
                    getCurrentLine()->substr(from:cursorPos, to:getCurrentLine()->length-1); 
                ;
                moveCursorRight();
                renderTerminal();                
            }
        );
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
                            Topaz.Input.removeUnicodeListener(id:typing);

                            onQuit();            
                        };
                    },

                    (Topaz.Input.KEY.S):::<= {
                        if (controlHeld > 0) ::<= {
                            lastStatus = "Saved " + name;
                            lastStatusCounter = 10;
                            item.string = lines->reduce(to:::(previous, value) <- if (previous == empty) value else (previous + '\n' + value)); 
                            Topaz.Resources.writeAsset(asset:item, extension:'', path:name);
                            renderTerminal();
                        };
                    },



                    (Topaz.Input.KEY.ENTER):::<= {
                        when (value < 1) empty;
                        // line merges into previous
                        when(cursorPos == 0) ::<= {
                            lines->insert(at:cursorLine, value:'');
                            cursorLine += 1;
                            cursorPos = 0;
                            checkCursorInBounds();
                            renderTerminal();
                        };

                        when(cursorPos == getCurrentLine()->length) ::<= {
                            lines->insert(at:cursorLine+1, value:'');
                            cursorLine += 1;
                            cursorPos = 0;
                            checkCursorInBounds();
                            renderTerminal();
                        };

                        // normal case
                        @:str = getCurrentLine();
                        lines[cursorLine] = str->substr(from:cursorPos, to:str->length-1);
                        lines->insert(at:cursorLine, value:str->substr(from:0, to:cursorPos-1));
                        cursorLine += 1;
                        cursorPos = 0;
                        checkCursorInBounds();
                        renderTerminal();                          
                    },


                    (Topaz.Input.KEY.BACKSPACE):::<= {
                        when (value < 1) empty;
                        // line merges into previous
                        when(cursorPos == 0) ::<= {
                            when(cursorLine == 0) empty;
                            @:oldPos = lines[cursorLine-1]->length;
                            lines[cursorLine-1] = lines[cursorLine-1] + getCurrentLine();
                            lines->remove(key:cursorLine);
                            moveCursorLeft(); // prev line;
                            cursorPos = oldPos;
                            renderTerminal();
                        };

                        // trim end
                        when(cursorPos == getCurrentLine()->length) ::<= {
                            when(getCurrentLine()->length == 1) ::<= {
                                lines[cursorLine] = '';
                                moveCursorLeft();
                                renderTerminal();
                            };
                            lines[cursorLine] = getCurrentLine()->substr(from:0, to:getCurrentLine()->length-2);
                            moveCursorLeft();
                            renderTerminal();
                        };


                        when(cursorPos == 1) ::<= {
                            lines[cursorLine] = getCurrentLine()->substr(from:1, to:getCurrentLine()->length-1);
                            moveCursorLeft();
                            renderTerminal();  
                        };

                        // normal case
                        lines[cursorLine] = 
                            getCurrentLine()->substr(from:0, to:cursorPos-2) +
                            getCurrentLine()->substr(from:cursorPos, to:getCurrentLine()->length-1); 
                        ;
                        moveCursorLeft();
                        renderTerminal();  
                    },


                    (Topaz.Input.KEY.DOWN):::<= {
                        when (value < 1) empty;
                        moveCursorDown();
                        renderTerminal();
                    },

                    (Topaz.Input.KEY.UP):::<= {
                        when (value < 1) empty;
                        moveCursorUp();
                        renderTerminal();
                    },

                    (Topaz.Input.KEY.RIGHT):::<= {
                        when (value < 1) empty;
                        moveCursorRight();
                        renderTerminal();
                    },

                    (Topaz.Input.KEY.LEFT):::<= {
                        when (value < 1) empty;
                        moveCursorLeft();
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
            if (typing != empty)
                Topaz.Input.removeUnicodeListener(id:typing);
            onQuit(message:'An error occurred: ' + message.summary);
        }
    };





};
