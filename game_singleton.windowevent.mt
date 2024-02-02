/*
    Wyvern Gate, a procedural, console-based RPG
    Copyright (C) 2023, Johnathan Corkery (jcorkery@umich.edu)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
// uses the canvas to push and queue windowEvent.

@:canvas = import(module:'game_singleton.canvas.mt');
@:class = import(module:'Matte.Core.Class');


@:MAX_LINES_TEXTBOX = 10;
@:MAX_COLUMNS = canvas.width - 4;



@:renderText ::(leftWeight, topWeight, lines, speaker, hasNotch) {
    canvas.renderTextFrameGeneral(leftWeight, topWeight, lines, title:speaker, notchText:if(hasNotch != empty) "(next)" else empty)
}

@:createBlankLine::(width, header) {
    if (header == empty)
        header = '';
    @:out = [header];
    for(header->length, width) ::(i) {
        out->push(value: ' ');
    }
    return String.combine(strings:out);
}

@:min = ::(a, b) {
    when(a < b) a;
    return b;
}

@:CURSOR_ACTIONS = {
    LEFT : 0,
    UP : 1,
    RIGHT : 2,
    DOWN : 3,
    CONFIRM : 4,
    CANCEL : 5
}

@:WindowEvent = class(
    name: 'Wyvern.WindowEvent',
    define:::(this) {
        @onInput;
        @isCursor = true;
        @choiceStack = [];
        @nextResolve = [];
        @requestAutoSkip = false;
        @autoSkipIndex = empty;

    
        @:renderThis ::(data => Object, thisRender) {
            when (requestAutoSkip) empty; 
            if (data.pushedCanvasState == empty) ::<= {
                canvas.pushState();      
                data.pushedCanvasState = true;
            }
            canvas.clear();

            @renderAgain = false;
            if (data.renderable) ::<= {
                renderAgain = (data.renderable.render()) == this.RENDER_AGAIN;        
            }
            if (thisRender)
                thisRender();
            canvas.commit();
            
            
            if (renderAgain == false)
                data.rendered = true;
        }
        
        @next ::(dontResolveNext) {
            if (choiceStack->keycount > 0) ::<= {
                @:data = choiceStack->pop;
                if (data.keep) ::<= {
                    choiceStack->push(value:data);
                } else ::<= {
                    if (!requestAutoSkip) ::<= {
                        if (data.pushedCanvasState)
                            canvas.popState();
                    }
                    
                    if (data.onLeave)
                        data.onLeave();
                    if (choiceStack->keycount > 0)
                        choiceStack[choiceStack->keycount-1].rendered = empty;
                }
            }
            if (dontResolveNext == empty) ::<= {
                resolveNext();
                this.commitInput();        
            }
        }
        
        @:commitInput ::(input) {
            @continue; 
            if (choiceStack->keycount > 0) ::<= {
                @val = choiceStack[choiceStack->keycount-1];
                    
                //if (val.jail == true) ::<= {
                //    choiceStack->push(value:val);
                //}
                continue = match(val.mode) {
                  (CHOICE_MODE.CURSOR):         commitInput_cursor(data:val, input),
                  (CHOICE_MODE.COLUMN_CURSOR):  commitInput_columnCursor(data:val, input),
                  (CHOICE_MODE.DISPLAY):        commitInput_display(data:val, input),
                  (CHOICE_MODE.CURSOR_MOVE):    commitInput_cursorMove(data:val, input),
                  (CHOICE_MODE.NODISPLAY):      commitInput_noDisplay(data:val, input),
                  (CHOICE_MODE.SLIDER):         commitInput_slider(data:val, input)
                }        
                
                // event callbacks mightve bonked out 
                // this current val. Double check 
                if (choiceStack->findIndex(value:val) == -1)
                    continue = false;
            }
            // true means done
            if (continue == true || choiceStack->keycount == 0) ::<= {
                next();
            }
        }


        // resolves the next action 
        // this is normally done for you, but
        // when jumping, sometimes it is required.
        @:resolveNext::{
            if (nextResolve->keycount) ::<= {
                @:cbs = nextResolve[0];
                nextResolve->remove(key:0);
                foreach(cbs)::(i, cb) <- cb();
            }
        }


        @:commitInput_cursor ::(data => Object, input) {
            @choice = input;
            @:canCancel = data.canCancel;
            @:prompt = data.prompt; 
            @:leftWeight = data.leftWeight; 
            @:topWeight = data.topWeight; 
            @:defaultChoice = data.defaultChoice;
            @:onChoice = data.onChoice;
            @:onHover = data.onHover;
            @:header = if (data.onGetHeader) data.onGetHeader() else data.header;
            @cursorPos = if (defaultChoice == empty) 0 else defaultChoice-1;

            when (requestAutoSkip) false;

            //if (canCancel) ::<= {
            //    choicesModified->push(value:'(Cancel)');
            //}
            @exitEmpty = false;

            
            
            if (data.rendered == empty || choice != empty) ::<= {
                @:choices = if (data.onGetChoices) data.onGetChoices() else data.choices;
                // no choices
                when(choices == empty || choices->keycount == 0) exitEmpty = true;
                


                @:PAGE_SIZE = 7;     
                @:WIDTH = ::<= {
                    @max = 0;
                    foreach(choices)::(i, text) {
                        if (text->length > max)
                            max = text->length;
                    }
                    if (header != empty)
                        if (header->length > max)
                            max = header->length;
                            
                    return max;
                }

                @padCombine = [];
                @:pad::(text) {
                    padCombine->setSize(size:0);
                    padCombine->push(value:text);
                    for(text->length, WIDTH) ::(i) {
                        padCombine->push(value:' ');
                    }
                    return String.combine(strings:padCombine);
                }


                @lineTop = '^  ';
                @lineBot = 'v  ';
                for(0, WIDTH)::(i) {
                    if (header == empty)
                        lineTop = lineTop + ' ';            
                    lineBot = lineBot + ' ';            
                }
                
                if (header != empty)
                    lineTop = lineTop + header;
    
                @cursorPageTop = 0;

                if (choice == CURSOR_ACTIONS.UP) ::<= {
                    cursorPos -= 1;
                }
                if(choice == CURSOR_ACTIONS.DOWN) ::<= {
                    cursorPos += 1;
                }

                if (cursorPos < 0) cursorPos = 0;
                if (cursorPos >= choices->keycount) cursorPos = choices->keycount-1;

                //if (cursorPos >= cursorPageTop+PAGE_SIZE) cursorPageTop+=1;
                //if (cursorPos  < cursorPageTop) cursorPageTop -=1;
                cursorPageTop = cursorPos - (PAGE_SIZE/2)->floor;

                if (cursorPageTop > choices->keycount - PAGE_SIZE) cursorPageTop = choices->keycount-PAGE_SIZE;
                if (cursorPageTop < 0) cursorPageTop = 0;
                
                @:choicesModified = [];
                
                
                if (choices->keycount > PAGE_SIZE) ::<= {
                    @initialLine = if (cursorPageTop > 0) lineTop else 
                        if (header == empty)
                            ''
                        else 
                            '   '+header
                    ;
                    choicesModified->push(value:initialLine);
                    if (header != empty)
                        choicesModified->push(value:'');


                    for(cursorPageTop, cursorPageTop+PAGE_SIZE)::(index) {
                        
                        choicesModified->push(value: 
                            (if (cursorPos == index) '-{ ' else '   ') + 
                            pad(text:choices[index]) + 
                            (if (cursorPos == index) ' }-' else '   ')                            
                        );
                    }


                    if (cursorPageTop + PAGE_SIZE < (choices->keycount))                    
                        choicesModified->push(value:lineBot)
                    else
                        choicesModified->push(value:'');

                } else ::<= {
                    if (header != empty) ::<= {     
                        choicesModified->push(value:'   '+header);
                        choicesModified->push(value:'');
                    }
                    for(0, choices->keycount)::(index) {
                        choicesModified->push(value: 
                            (if (cursorPos == index) '-{ ' else '   ') + 
                            pad(text:choices[index]) + 
                            (if (cursorPos == index) ' }-' else '   ')
                        );
                    }
                }
                
                
                
                
                
                if (choice == CURSOR_ACTIONS.UP||
                    choice == CURSOR_ACTIONS.DOWN) ::<= {
                    data.defaultChoice = (cursorPos+1);
                }
                
                if (onHover != empty)
                    onHover(choice:cursorPos+1);
                
                renderThis(
                    data,
                    thisRender::{
                        renderText(
                            lines: choicesModified,
                            speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
                            leftWeight,
                            topWeight
                        ); 
                    }
                );
            }
            when(exitEmpty) ::<= {
                data.keep = empty;
                return true;            
            }
                
            when(choice == CURSOR_ACTIONS.CANCEL && canCancel) ::<= {
                data.keep = empty;
                return true;
            }
            
            when(choice == CURSOR_ACTIONS.CONFIRM) ::<= {
                onChoice(choice:cursorPos + 1);
                data.rendered = empty;
                return true;
            }
                
            return false;
        }


        @:commitInput_slider ::(data => Object, input) {
            @choice = input;
            @:canCancel = data.canCancel;
            @:prompt = data.prompt; 
            @:leftWeight = data.leftWeight; 
            @:topWeight = data.topWeight; 
            @:onChoice = data.onChoice;
            @:onHover = data.onHover;
            @:increments = data.increments;
            @cursorPos = data.defaultValue;

            when (requestAutoSkip) false;

            //if (canCancel) ::<= {
            //    choicesModified->push(value:'(Cancel)');
            //}
            @exitEmpty = false;

            
            
            if (data.rendered == empty || choice != empty) ::<= {
                
                if (choice == CURSOR_ACTIONS.LEFT) ::<= {
                    cursorPos -= 1 / increments;
                }
                if(choice == CURSOR_ACTIONS.RIGHT) ::<= {
                    cursorPos += 1 / increments;
                }             
                
                if (cursorPos < 0) cursorPos = 0;
                if (cursorPos > 1) cursorPos = 1;
                
                if (choice == CURSOR_ACTIONS.LEFT||
                    choice == CURSOR_ACTIONS.RIGHT) ::<= {
                    data.defaultValue = cursorPos;
                }
                
                if (onHover != empty)
                    onHover(fraction:cursorPos);
                
                renderThis(
                    data,
                    thisRender::{
                        @line = '[';
                        for(0, 50) ::(i) {
                            if ((cursorPos * 50)->floor == i)
                                line = line + 'I'
                            else
                                line = line + '-'
                            ;
                        }
                        line = line + ']'
                        renderText(
                            lines: [
                                '',
                                line,
                                ''
                            ],
                            speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
                            leftWeight,
                            topWeight
                        ); 
                    }
                );
            }
            when(exitEmpty) ::<= {
                data.keep = empty;
                return true;            
            }
                
            when(choice == CURSOR_ACTIONS.CANCEL && canCancel) ::<= {
                data.keep = empty;
                return true;
            }
            
            when(choice == CURSOR_ACTIONS.CONFIRM) ::<= {
                onChoice(fraction:cursorPos);
                data.rendered = empty;
                return true;
            }
                
            return false;
        }



        @:commitInput_cursorMove ::(data => Object, input) {
            @:prompt = data.prompt; 
            @:leftWeight = data.leftWeight; 
            @:topWeight = data.topWeight; 
            @:defaultChoice = data.defaultChoice;
            @:onChoice = data.onChoice;
            @:choice = input;         
            @:onMenu = data.onMenu;            

            when (requestAutoSkip) false;

            when(choice == CURSOR_ACTIONS.CANCEL ||
                 choice == CURSOR_ACTIONS.CONFIRM) ::<= {
                onMenu();
                resolveNext();
                return false;
            }           

            if (  choice == CURSOR_ACTIONS.UP||
                  choice == CURSOR_ACTIONS.DOWN ||
                  choice == CURSOR_ACTIONS.LEFT ||
                  choice == CURSOR_ACTIONS.RIGHT ||
                  data.rendered == empty) ::<= {
                if (choice != empty) ::<= {
                    onChoice(choice);
                    resolveNext();
                }
                
                renderThis(data, thisRender::{
                    /*renderText(
                        lines: ['[Cancel to return]'],
                        speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
                        leftWeight,
                        topWeight,
                        limitLines:13
                    );*/             
                });
            }
            return false;    
        }        
    
        @:commitInput_noDisplay ::(data => Object, input) {
            
            //if (canCancel) ::<= {
            //    choicesModified->push(value:'(Cancel)');
            //}
            
            if (data.rendered == empty || input != empty)
                renderThis(data);

            data.onEnter();
          
            return true;    
        }       
    
        @:commitInput_columnCursor ::(data => Object, input) {
        
            @:choices = if (data.onGetChoices) data.onGetChoices() else data.choices;
            // no choices
            when(choices == empty || choices->keycount == 0) true;
            
            
            when(input == empty && data.rendered != empty) false;
            @choice = input;                   

            when (requestAutoSkip) false;
            
            
            @:prompt = data.prompt;
            @:itemsPerColumn = data.itemsPerColumn;
            @:leftWeight = data.leftWeight;
            @:topWeight = data.topWeight;
            @:canCancel = data.canCancel;
            @:onChoice = data.onChoice;
            @:onHover = data.onHover;
            
            @x = data.defaultX;
            @y = data.defaultY;

            
            if (x == empty) x = 0;
            if (y == empty) y = 0;

            
      
            


            @:choicesModified = [];
            @column = 0;
            
            @:columns = [[]];
            @:columnWidth = [0];

            @height;
            @width;
            @which;
            foreach(choices)::(index, choice) {
                @entry = ('  ') + choice;
                if (columns[column]->keycount == y && column == x) which = index;
                
                columns[column]->push(value:entry);

                if (entry->length > columnWidth[column])
                    columnWidth[column] = entry->length;
                
                if (columns[column]->keycount >= itemsPerColumn) ::<= {
                    column+=1;
                    columns[column] = [];
                    columnWidth->push(value:0);
                }
            }
            width = columnWidth->keycount;
            height = itemsPerColumn;
            
            
            @oldX = x;
            @oldY = y;
            if(choice == CURSOR_ACTIONS.LEFT||
                 choice == CURSOR_ACTIONS.RIGHT||
                 choice == CURSOR_ACTIONS.UP||
                 choice == CURSOR_ACTIONS.DOWN) ::<= {
                if (choice == CURSOR_ACTIONS.LEFT)
                    x -= 1;
                    
                if (choice == CURSOR_ACTIONS.RIGHT)
                    x += 1;
                    
                if (choice == CURSOR_ACTIONS.UP)
                    y -= 1;

                if (choice == CURSOR_ACTIONS.DOWN)
                    y += 1;

                if (x < 0) x = 0;
                if (x >= width) x = width-1;
                if (y < 0) y = 0;
                if (y >= height) y = height-1;
            }                  
            
            ::<= {                
                if (columns[x][y] == empty) 
                    ::<= {
                        x = oldX;
                        y = oldY;
                    }
                ;
                columns[x][y] = '> ' + columns[x][y]->substr(from:2, to:columns[x][y]->length-1);

                data.defaultX = x;
                data.defaultY = y;
            }

            // its just a regular choice at that point. Most of the time
            // we can be a little sloppy here.
            when(columns->keycount == 1)
                choices(choices, prompt:if (data.onGetPrompt == empty) prompt else data.onGetPrompt(), leftWeight, topWeight, canCancel);
            
            
            // reformat with spacing
            @:choicesModified = [];
            for(0, itemsPerColumn)::(i) {
                @choice = '';
                foreach(columns)::(index, text) {
                    if (text[i] != empty) ::<= {
                        choice = choice + text[i];
                        
                        for(choice->length, columnWidth[index])::(n) {
                            choice = choice + ' ';
                        }
                        choice = choice + '   ';
                    }
                    
                }
                choicesModified->push(value:choice);
            }
            
            if (onHover != empty)
                onHover(choice:which+1);

            renderThis(data, thisRender::{
                renderText(
                    lines: choicesModified,
                    speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
                    leftWeight,
                    topWeight
                ); 
            });            
                
                
            when (choice == CURSOR_ACTIONS.CONFIRM) ::<= {
                onChoice(choice:which + 1);
                return true;
            }
                
            if (canCancel && choice == CURSOR_ACTIONS.CANCEL) ::<= {
                data.keep = empty;
                return true;
            }
            

            return false;
        }
        
        @:commitInput_display ::(data, input) {
            when (requestAutoSkip) true;
        
        
            if (data.rendered == empty) ::<= {
                renderThis(data, thisRender::{
                    renderText(
                        leftWeight: data.leftWeight, 
                        topWeight: data.topWeight, 
                        lines: data.lines,
                        speaker:if (data.onGetPrompt == empty) data.prompt else data.onGetPrompt(),
                        //limitLines : data.pageAfter,
                        hasNotch: true
                    );
                });
            }
        
            return match(input) {
              (CURSOR_ACTIONS.CONFIRM, 
               CURSOR_ACTIONS.CANCEL): ::<= {
                return true;
               },
              default: false
            }
        }
        
        
        @:CHOICE_MODE = {
            CURSOR : 0,
            NUMBER : 1,
            COLUMN_CURSOR : 2,
            COLUMN_NUMBER : 3,
            CURSOR_MOVE: 4,
            DISPLAY: 5,
            NODISPLAY: 6,
            SLIDER : 7
        }
        
        
        this.interface = {
            commitInput : commitInput,
            
            RENDER_AGAIN : {
                get ::<- 1
            },
            
            // Similar to message, but accepts a set of 
            // messages to display
            queueMessageSet::(speaker, set => Object, leftWeight, topWeight, pageAfter, onLeave) {
                foreach(set)::(i, text) <- 
                    this.queueMessage(
                        speaker,
                        text,
                        leftWeight,
                        topWeight,
                        pageAfter,
                        onLeave
                    )
                
            },
            
            // Posts a message to the screen. In the case that a 
            // message overflows, it will be split into multiple dialogs.
            //
            // The function returns when the message is displayed in full
            // to the user.
            queueMessage::(speaker, text, leftWeight, topWeight, pageAfter, renderable, onLeave) {
                if (pageAfter == empty) pageAfter = MAX_LINES_TEXTBOX;
                // first: split the text.
                //text = text->replace(keys:['\r'], with: '');
                //text = text->replace(keys:['\t'], with: ' ');
                //text = text->replace(keys:['\n'], with: '\n');
                //@:words = text->split(token:' ');

                @:lines = [];
                @line = '';

                for(0, text->length)::(i) {
                    @:word = text->charAt(index:i); 
                    when(word == '\n') ::<= {
                        lines->push(value:line);
                        line = '';                    
                    }
                    line = line + word;
                    if (line->length >= canvas.width-4) ::<= {
                        @nextLine = '';
                        {:::} {
                            forever ::{
                                @ch = line->charAt(index:line->length-1);
                                when(line->length < canvas.width-4 && ch == ' ') send();

                                nextLine = ch + nextLine;
                                line = line->substr(from:0, to:line->length-2);
                                                          

                            }
                        }                                                
                        lines->push(value:line);
                        line = nextLine;
                    }
                }
                lines->push(value:line);
                

                this.queueDisplay(
                    leftWeight, topWeight,
                    prompt:speaker,
                    renderable,
                    lines,
                    pageAfter,
                    onLeave
                );              
            },
            
            // Similar to display(), but takes in an array of string arrays and 
            // treats them as columns, appended left-to-right separated with a 
            // space.
            queueDisplayColumns::(prompt, columns, leftWeight, topWeight, pageAfter, onLeave, renderable) {
                @:lines = [];
                @:widths = [];
                @rowcount = 0;
                foreach(columns)::(index, lines) {
                    @width = 0;
                    foreach(lines)::(row, line) {
                        if (line->length > width)
                            width = line->length;

                        if (row+1 > rowcount)
                            rowcount = row+1;
                    }
                    
                    widths->push(value:width);                    
                }

                for(0, rowcount)::(row) {
                    @line = '';
                
                    foreach(columns)::(column, lines) {
                        line = line + lines[row];
                        for(lines[row]->length, widths[column])::(i) {
                            line = line + ' ';
                        }
                        line = line + ' ';
                    }   
                    
                    lines->push(value:line);
                }   
           
                this.queueDisplay(
                    prompt, lines, pageAfter, leftWeight, topWeight, onLeave, renderable
                );
            },
            
            // like message, but tried to fit the text on one page.
            // If it doesnt fit, display will try and make it scrollable.
            //
            // lines should be an array of strings.
            queueDisplay::(prompt, lines, pageAfter, leftWeight, topWeight, renderable, onLeave) {
                when(requestAutoSkip) ::<= {
                    if (onLeave) onLeave();
                }

                @:queuePage ::(iter, width, more){
                    nextResolve->push(value:[::{
                        @:linesOut = lines->subset(
                            from:iter, 
                            to:min(a:iter+pageAfter, b:lines->keycount)-1
                        )
                        
                        if (width != empty)
                            linesOut->push(value:createBlankLine(width, header:if (more) '-More-' else ''));
                        
                        choiceStack->push(value:{
                            topWeight: topWeight,
                            leftWeight : leftWeight,
                            lines : linesOut,
                            pageAfter: pageAfter,
                            prompt: prompt,
                            onLeave: onLeave,
                            mode: CHOICE_MODE.DISPLAY,
                            renderable: renderable
                        });
                    }]);
                }
                if (pageAfter == empty) pageAfter = MAX_LINES_TEXTBOX;

                @:MAX_WIDTH = ::<= {
                    when(lines->size <= pageAfter) empty;
                    @width = 0;
                    foreach(lines) ::(k, line) {
                        if (line->length > width)
                            width = line->length
                    }
                    return width;
                }

                @iter = 0;
                {:::} {
                    forever ::{

                        @last = iter + pageAfter >= lines->size;

                        queuePage(iter, width:MAX_WIDTH, more:!last);

                        when (last) send();
                        iter += 1;
                        
                        breakpoint();
                    }
                }
            },
            
            // A place holder action. This can be used to run a function 
            // in order, or for rendering graphics.
            // onEnter runs whenever the display is entered.
            queueNoDisplay::(renderable, keep, onEnter => Function, jumpTag, onLeave) {
                when(requestAutoSkip) ::<= {
                    if (onEnter) onEnter();
                    if (onLeave) onLeave();
                }

                nextResolve->push(value:[::{
                    choiceStack->push(value:{
                        mode: CHOICE_MODE.NODISPLAY,
                        keep: keep,
                        renderable:renderable,
                        onEnter:onEnter,
                        jumpTag: jumpTag,
                        onLeave: onLeave
                    });
                }]);                
            },
            
            
            


            
            
            // Allows for choosing from a list of options.
            // Like all UI choices, the weight can be chosen.
            // Prompt will be displayed, like speaker in the message callback
            //
            queueChoices::(choices, prompt, leftWeight, topWeight, canCancel, defaultChoice, onChoice => Function, onHover, renderable, keep, onGetChoices, onGetPrompt, jumpTag, onLeave, header, onGetHeader) {

                nextResolve->push(value:[::{
                    choiceStack->push(value:{
                        mode: CHOICE_MODE.CURSOR,
                        choices: choices,
                        prompt: prompt,
                        leftWeight: leftWeight,
                        topWeight: topWeight,
                        canCancel: canCancel,
                        defaultChoice: defaultChoice,
                        onChoice: onChoice,
                        onHover: onHover,
                        onLeave : onLeave,
                        keep: keep,
                        onGetChoices : onGetChoices,
                        onGetPrompt : onGetPrompt,
                        renderable:renderable,
                        jumpTag : jumpTag,
                        header : header,
                        onGetHeader : onGetHeader
                    });
                }]);
            },
            
            
            queueSlider::(defaultValue => Number, increments => Number, prompt, leftWeight, topWeight, canCancel, defaultChoice, onChoice => Function, onHover, renderable, keep, onGetPrompt, jumpTag, onLeave) {

                nextResolve->push(value:[::{
                    choiceStack->push(value:{
                        mode: CHOICE_MODE.SLIDER,
                        increments : increments,
                        prompt: prompt,
                        leftWeight: leftWeight,
                        topWeight: topWeight,
                        canCancel: canCancel,
                        defaultValue: defaultValue,
                        onChoice: onChoice,
                        onHover: onHover,
                        onLeave : onLeave,
                        keep: keep,
                        onGetPrompt : onGetPrompt,
                        renderable:renderable,
                        jumpTag : jumpTag
                    });
                }]);
            },            

            canJumpToTag::(name => String) {
                @:cs = [...choiceStack];
                return {:::} {
                    forever ::{
                        if (cs->keycount == 0)
                            send(message:false);
                        @:data = cs[cs->keycount-1];
                        if (data.jumpTag != name) ::<= {
                            cs->pop;
                        } else 
                            send(message:true);
                    }
                }            
            },

            // pops all choices in the stack until the tag is hit.
            jumpToTag::(name => String, goBeforeTag, doResolveNext, clearResolve) {
                {:::} {
                    forever ::{
                        if (choiceStack->keycount == 0)
                            error(detail:'jumpToTag() could not find a dialogue tag with name ' + name);
                            
                        @:data = choiceStack[choiceStack->keycount-1];
                        if (data.jumpTag != name) ::<= {
                            data.keep = false;
                            next(dontResolveNext:true);
                        } else 
                            send();
                    }
                }
                if (goBeforeTag != empty) ::<= {
                    canvas.popState();
                    @:data = choiceStack->pop; 
                    if (data.onLeave)
                        data.onLeave();                  
                }
                canvas.commit();                
                choiceStack[choiceStack->keycount-1].rendered = empty;
                if (clearResolve) ::<= {
                    nextResolve = [];
                }


                if (doResolveNext) ::<={
                    resolveNext();
                }
                
                    
                this.commitInput();
            },
       
            
            queueChoiceColumns::(choices, prompt, itemsPerColumn, leftWeight, topWeight, canCancel, onChoice => Function, keep, renderable, jumpTag, onLeave) {
                nextResolve->push(value:[::{
                    choiceStack->push(value:{
                        mode:if (isCursor) CHOICE_MODE.COLUMN_CURSOR else CHOICE_MODE.COLUMN_NUMBER,
                        choices: choices,
                        prompt: prompt,
                        jumpTag : jumpTag,
                        itemsPerColumn: itemsPerColumn,
                        leftWeight : leftWeight,
                        topWeight : topWeight,
                        canCancel : canCancel,
                        onChoice : onChoice,
                        onLeave : onLeave,
                        keep : keep,
                        renderable:renderable,
                    });
                }]);
            },            
            queueCursorMove ::(prompt, leftWeight, topWeight, onMove, onMenu => Function, renderable, onLeave, jumpTag) {
                nextResolve->push(value:[::{
                    choiceStack->push(value:{
                        mode: CHOICE_MODE.CURSOR_MOVE,
                        prompt: prompt,
                        leftWeight: leftWeight,
                        topWeight: topWeight,
                        onChoice:onMove,
                        onLeave:onLeave,
                        renderable:renderable,
                        jumpTag: jumpTag,
                        onMenu : onMenu
                    });
                    canvas.clear();
                }]);
            },  
            
              
            // request to not render or wait for nodisplay and display 
            // events. If auto skip is enabled and any of the other events 
            // are queued, an error is thrown.           
            autoSkip  : {
                get ::<- requestAutoSkip,
                set ::(value) <- requestAutoSkip = value
            },
            
            CURSOR_ACTIONS : {
                get::<- CURSOR_ACTIONS
            },
            
            forceExit ::(soft){
                choiceStack[choiceStack->keycount-1].keep = empty;
                next();
            },

            // ask yes or no immediately.
            queueAskBoolean::(prompt, leftWeight, topWeight, onChoice => Function, renderable, onLeave) {
                this.queueChoices(prompt, choices:['Yes', 'No'], canCancel:false, onLeave:onLeave, topWeight, leftWeight,
                    onChoice::(choice){
                        onChoice(which: choice == 1);
                    },
                    renderable
                );
            },
            
            // returns any resolvable items are left queued.
            hasAnyQueued:: {
                return nextResolve->size != 0;
            }
        }    
    }
).new();

return WindowEvent;

