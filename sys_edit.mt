@:Topaz = import(module:'Topaz');
return ::(terminal, arg, onDone) {
    @name = arg;
    @:Shell = import(module:'sys_shell.mt');
    when (Shell.currentDirectory->length == 0 && name->contains(key:'/') == false) ::<={
        terminal.print(line:'Cannot edit view in toplevel directory. "cd" into a directory first.');
        onDone();
    }

    name = Shell.currentDirectory + '_' + name;


    @listener;
    @typing;
    terminal.clear();
    @cursorCharacter = '▓';
    @:VIEWSPACE_HEIGHT = terminal.HEIGHT - 5;
    @:VIEWSPACE_WIDTH  = terminal.WIDTH - 8; // 8 is for the header
    @lines = [''];

    @nameFiltered = name->replace(keys:['\\', '..'], with: '');
    nameFiltered = name->replace(key:'/', with:'_');
    @item = Topaz.Resources.createAsset(
        path:nameFiltered,
        name:name
    );

    if (item == empty)
        item = Topaz.Resources.fetchAsset(name:nameFiltered);

    if (item == empty) ::<= {
        item = Topaz.Resources.createAsset(name:nameFiltered);
    } else ::<= {
        @:data = item.string;
        lines = data->split(token:'\n');  
        if (lines[0] == empty)
            lines[0] = '';      
    }



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
            }
        }
        terminal.print(line:'____________________________________________________________________');
        
        for(0, VIEWSPACE_HEIGHT)::(i) {
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
            }


            
            terminal.print(line);
        }

        terminal.print(line:'____________________________________________________________________');
        terminal.print(line:'Ctrl+x to quit, Ctrl+s to save');

    }

    @:checkCursorInBounds = ::{
        viewLine = (cursorLine - VIEWSPACE_HEIGHT / 2)->floor;
        if (viewLine > lines->keycount - VIEWSPACE_HEIGHT) viewLine = lines->keycount - VIEWSPACE_HEIGHT;
        if (viewLine < 0) viewLine = 0;

        if (cursorPos > viewPos + VIEWSPACE_WIDTH)
            viewPos = (cursorPos - VIEWSPACE_WIDTH / 2)->floor;

        if (cursorPos - viewPos < 0)
            viewPos = (cursorPos - VIEWSPACE_WIDTH / 2)->floor;

        if (viewPos < 0) viewPos = 0;


    }


    @:getCurrentLine ::{
        return lines[cursorLine];
    }

    @:moveCursorUp = ::{
        cursorLine -= 1;
        if (cursorLine < 0) ::<= {
            cursorLine = 0;
            cursorPos = 0;
        }
        if (cursorPos > getCurrentLine()->length)
            cursorPos = getCurrentLine()->length;
        checkCursorInBounds();
    }


    @:moveCursorDown = ::{
        cursorLine += 1;
        if (cursorLine >= lines->keycount) ::<= {
            cursorLine = lines->keycount-1;
            cursorPos = getCurrentLine()->length;
            checkCursorInBounds();
        }
        if (cursorPos > getCurrentLine()->length)
            cursorPos = getCurrentLine()->length;
        checkCursorInBounds();
    }


    @:moveCursorRight = ::{
        cursorPos += 1;
        if (cursorPos > getCurrentLine()->length) ::<= {
            cursorPos = 0;
            moveCursorDown();
        }

        checkCursorInBounds();
    }

    @:moveCursorLeft = ::{
        cursorPos -= 1;
        if (cursorPos < 0) ::<= {
            @isStart = cursorLine == 0;
            moveCursorUp();
            if (!isStart)
                cursorPos = getCurrentLine()->length;
        }

        checkCursorInBounds();
    }


    @controlHeld = 0;
    Shell.onProgramUnicode = ::(unicode) {
        @:ch = ' '->setCharCodeAt(index:0, value:unicode);
        when(cursorPos == 0) ::<= {
            lines[cursorLine] = getCurrentLine() + ch;
            moveCursorRight();
            renderTerminal();
        }

        when(cursorPos == getCurrentLine()->length) ::<= {
            lines[cursorLine] = getCurrentLine() + ch;
            moveCursorRight();
            renderTerminal();
        }



        lines[cursorLine] = 
            getCurrentLine()->substr(from:0, to:cursorPos-1) +
            ch + 
            getCurrentLine()->substr(from:cursorPos, to:getCurrentLine()->length-1); 
        ;
        moveCursorRight();
        renderTerminal();                    
    }

    Shell.onProgramKeyboard = ::(input, value) {
        match(input) {
            (Topaz.Key.lctrl,
                Topaz.Key.rctrl):::<= {
                controlHeld = value;
            },

            (Topaz.Key.x):::<= {
                if (controlHeld > 0) ::<= {
                    terminal.clear();
                    onDone();            
                }
            },

            (Topaz.Key.s):::<= {
                if (controlHeld > 0) ::<= {
                    lastStatus = "Saved " + name;
                    lastStatusCounter = 10;
                    item.setFromString(string:lines->reduce(to:::(previous, value) <- if (previous == empty) value else (previous + '\n' + value))); 
                    Topaz.Resources.writeAsset(asset:item, extension:'', path:nameFiltered);
                    renderTerminal();
                }
            },



            (Topaz.Key.enter):::<= {
                when (value < 1) empty;
                // line merges into previous
                when(cursorPos == 0) ::<= {
                    lines->insert(at:cursorLine, value:'');
                    cursorLine += 1;
                    cursorPos = 0;
                    checkCursorInBounds();
                    renderTerminal();
                }

                when(cursorPos == getCurrentLine()->length) ::<= {
                    lines->insert(at:cursorLine+1, value:'');
                    cursorLine += 1;
                    cursorPos = 0;
                    checkCursorInBounds();
                    renderTerminal();
                }

                // normal case
                @:str = getCurrentLine();
                lines[cursorLine] = str->substr(from:cursorPos, to:str->length-1);
                lines->insert(at:cursorLine, value:str->substr(from:0, to:cursorPos-1));
                cursorLine += 1;
                cursorPos = 0;
                checkCursorInBounds();
                renderTerminal();                          
            },


            (Topaz.Key.backspace):::<= {
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
                }

                // trim end
                when(cursorPos == getCurrentLine()->length) ::<= {
                    when(getCurrentLine()->length == 1) ::<= {
                        lines[cursorLine] = '';
                        moveCursorLeft();
                        renderTerminal();
                    }
                    lines[cursorLine] = getCurrentLine()->substr(from:0, to:getCurrentLine()->length-2);
                    moveCursorLeft();
                    renderTerminal();
                }


                when(cursorPos == 1) ::<= {
                    lines[cursorLine] = getCurrentLine()->substr(from:1, to:getCurrentLine()->length-1);
                    moveCursorLeft();
                    renderTerminal();  
                }

                // normal case
                lines[cursorLine] = 
                    getCurrentLine()->substr(from:0, to:cursorPos-2) +
                    getCurrentLine()->substr(from:cursorPos, to:getCurrentLine()->length-1); 
                ;
                moveCursorLeft();
                renderTerminal();  
            },


            (Topaz.Key.down):::<= {
                when (value < 1) empty;
                moveCursorDown();
                renderTerminal();
            },

            (Topaz.Key.up):::<= {
                when (value < 1) empty;
                moveCursorUp();
                renderTerminal();
            },

            (Topaz.Key.right):::<= {
                when (value < 1) empty;
                moveCursorRight();
                renderTerminal();
            },

            (Topaz.Key.left):::<= {
                when (value < 1) empty;
                moveCursorLeft();
                renderTerminal();
            }
        }
    }
    renderTerminal();
}
