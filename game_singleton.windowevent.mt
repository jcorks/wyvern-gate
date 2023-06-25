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


@:MAX_LINES_TEXTBOX = 5;
@:MAX_COLUMNS = canvas.width - 4;



@:renderText ::(limitLines, leftWeight, topWeight, lines, speaker, hasNotch) {
    if (leftWeight == empty) leftWeight = 0.5;
    if (topWeight  == empty) topWeight  = 0.5;

    @width = if (speaker == empty) 0 else speaker->length;
    lines->foreach(do:::(index, line) {
        if (line->length > width) width = line->length;
    });
    
    @left   = (canvas.width - (width+4))*leftWeight;
    width   = width + 4;
    @top    = (canvas.height - (lines->keycount + 4)) * topWeight;
    @height = lines->keycount + 4;
    
    if (top < 0) top = 0;
    if (left < 0) left = 0;
    
    
    canvas.renderFrame(top, left, width, height);

    // render text:
    
    lines->foreach(do:::(index, line) {
        canvas.movePen(x: left+2, y: top+2+index);
        canvas.drawText(text:line);
    });

    if (speaker != empty) ::<= {
        canvas.movePen(x: left+2, y:top);
        canvas.drawText(text:speaker);
    };

    if (hasNotch != empty && hasNotch == true) ::<= {
        canvas.movePen(x: left+width-8, y:top+height-1);
        canvas.drawText(text:'(next)');
    };

    
    

};

@:min = ::(a, b) {
    when(a < b) a;
    return b;
};

@:CURSOR_ACTIONS = {
    LEFT : 0,
    UP : 1,
    RIGHT : 2,
    DOWN : 3,
    CONFIRM : 4,
    CANCEL : 5
};

@:WindowEvent = class(
    name: 'Wyvern.WindowEvent',
    define:::(this) {
        @onInput;
        @isCursor = true;
        @choiceStack = [];
        @nextResolve = [];
    
    
        @:renderThis ::(data => Object, selfRender) {
            if (data.pushedCanvasState == empty) ::<= {
                canvas.pushState();      
                data.pushedCanvasState = true;
            };
            canvas.clear();

            @renderAgain = false;
            if (data.renderable) ::<= {
                renderAgain = (data.renderable.render()) == this.RENDER_AGAIN;        
            };
            if (selfRender)
                selfRender();
            canvas.commit();
            
            
            if (renderAgain == false)
                data.rendered = true;
        };
        
        @next ::(dontResolveNext) {
            if (choiceStack->keycount > 0) ::<= {
                @:data = choiceStack->pop;
                if (data.keep) ::<= {
                    choiceStack->push(value:data);
                } else ::<= {
                    canvas.popState();
                    if (data.onLeave)
                        data.onLeave();
                    if (choiceStack->keycount > 0)
                        choiceStack[choiceStack->keycount-1].rendered = empty;
                };
            };
            if (dontResolveNext == empty) ::<= {
                resolveNext();
                this.commitInput();        
            };
        };
        
        @:commitInput ::(input) {
            @continue; 
            if (choiceStack->keycount > 0) ::<= {
                @val = choiceStack[choiceStack->keycount-1];
                    
                //if (val.jail == true) ::<= {
                //    choiceStack->push(value:val);
                //};
                continue = match(val.mode) {
                  (CHOICE_MODE.CURSOR):         commitInput_cursor(data:val, input),
                  (CHOICE_MODE.COLUMN_CURSOR):  commitInput_columnCursor(data:val, input),
                  (CHOICE_MODE.DISPLAY):        commitInput_display(data:val, input),
                  (CHOICE_MODE.CURSOR_MOVE):    commitInput_cursorMove(data:val, input),
                  (CHOICE_MODE.NODISPLAY):      commitInput_noDisplay(data:val, input)
                };        
                
                // event callbacks mightve bonked out 
                // this current val. Double check 
                if (choiceStack->findIndex(value:val) == -1)
                    continue = false;
            };
            // true means done
            if (continue == true || choiceStack->keycount == 0) ::<= {
                next();
            };
        };


        // resolves the next action 
        // this is normally done for you, but
        // when jumping, sometimes it is required.
        @:resolveNext::{
            if (nextResolve->keycount) ::<= {
                @:cbs = nextResolve[0];
                nextResolve->remove(key:0);
                cbs->foreach(do:::(i, cb) <- cb());
            };
        };


        @:commitInput_cursor ::(data => Object, input) {
            @choice = input;
            @:canCancel = data.canCancel;
            @:prompt = data.prompt; 
            @:leftWeight = data.leftWeight; 
            @:topWeight = data.topWeight; 
            @:defaultChoice = data.defaultChoice;
            @:onChoice = data.onChoice;
            @cursorPos = if (defaultChoice == empty) 0 else defaultChoice-1;

            //if (canCancel) ::<= {
            //    choicesModified->push(value:'(Cancel)');
            //};
            if (data.rendered == empty || choice != empty) ::<= {
                @:choices = if (data.onGetChoices) data.onGetChoices() else data.choices;
                // no choices
                when(choices == empty || choices->keycount == 0) true;
                


                @:PAGE_SIZE = 7;     
                @:WIDTH = ::<= {
                    @max = 0;
                    choices->foreach(do:::(i, text) {
                        if (text->length > max)
                            max = text->length;
                    });
                    
                    return max;
                };

                @lineTop = '^';
                @lineBot = 'v';
                [0, WIDTH+2]->for(do:::(i) {
                    lineTop = lineTop + ' ';            
                    lineBot = lineBot + ' ';            
                });            
                
                @cursorPageTop = 0;

                if (choice == CURSOR_ACTIONS.UP) ::<= {
                    cursorPos -= 1;
                };
                if(choice == CURSOR_ACTIONS.DOWN) ::<= {
                    cursorPos += 1;
                };

                if (cursorPos < 0) cursorPos = 0;
                if (cursorPos >= choices->keycount) cursorPos = choices->keycount-1;

                //if (cursorPos >= cursorPageTop+PAGE_SIZE) cursorPageTop+=1;
                //if (cursorPos  < cursorPageTop) cursorPageTop -=1;
                cursorPageTop = cursorPos - (PAGE_SIZE/2)->floor;

                if (cursorPageTop > choices->keycount - PAGE_SIZE) cursorPageTop = choices->keycount-PAGE_SIZE;
                if (cursorPageTop < 0) cursorPageTop = 0;
                
                @:choicesModified = [];
                
                
                if (choices->keycount > PAGE_SIZE) ::<= {
                    @initialLine = if (cursorPageTop > 0) lineTop else ' ';
                    [initialLine->length, WIDTH]->for(do:::(i) {
                        initialLine = initialLine + ' ';
                    });                   
                    choicesModified->push(value:initialLine);


                    [cursorPageTop, cursorPageTop+PAGE_SIZE]->for(do:::(index) {
                        
                        choicesModified->push(value: (if (cursorPos == index) '>  ' else '   ') + choices[index]);
                    });


                    if (cursorPageTop + PAGE_SIZE < (choices->keycount))                    
                        choicesModified->push(value:lineBot)
                    else
                        choicesModified->push(value:'       ');

                } else ::<= {
                    [0, choices->keycount]->for(do:::(index) {
                        choicesModified->push(value: (if (cursorPos == index) '>  ' else '   ') + choices[index]);
                    });
                };
                
                
                
                
                
                if (choice == CURSOR_ACTIONS.UP||
                    choice == CURSOR_ACTIONS.DOWN) ::<= {
                    data.defaultChoice = (cursorPos+1);
                };
                renderThis(
                    data,
                    selfRender::{
                        renderText(
                            lines: choicesModified,
                            speaker: prompt,
                            leftWeight,
                            topWeight,
                            limitLines:14
                        ); 
                    }
                );
            };
                
            when(choice == CURSOR_ACTIONS.CANCEL && canCancel) ::<= {
                data.keep = empty;
                return true;
            };
            
            when(choice == CURSOR_ACTIONS.CONFIRM) ::<= {
                onChoice(choice:cursorPos + 1);
                return true;
            };
                
            return false;
        };


        @:commitInput_cursorMove ::(data => Object, input) {
            @:prompt = data.prompt; 
            @:leftWeight = data.leftWeight; 
            @:topWeight = data.topWeight; 
            @:defaultChoice = data.defaultChoice;
            @:onChoice = data.onChoice;
            @:choice = input;         
            

            when(choice == CURSOR_ACTIONS.CANCEL) ::<= {
                return true;
            };           

            if (  choice == CURSOR_ACTIONS.UP||
                  choice == CURSOR_ACTIONS.DOWN ||
                  choice == CURSOR_ACTIONS.LEFT ||
                  choice == CURSOR_ACTIONS.RIGHT ||
                  data.rendered == empty) ::<= {
                if (choice != empty) ::<= {
                    onChoice(choice);
                    resolveNext();
                };
                    
                renderThis(data, selfRender::{
                    renderText(
                        lines: ['[Cancel to return]'],
                        speaker: prompt,
                        leftWeight,
                        topWeight,
                        limitLines:13
                    );             
                });
            };
            return false;    
        };        
    
        @:commitInput_noDisplay ::(data => Object, input) {
            
            //if (canCancel) ::<= {
            //    choicesModified->push(value:'(Cancel)');
            //};
            
            if (data.rendered == empty || input != empty)
                renderThis(data);

            data.onEnter();
          
            return true;    
        };       
    
        @:commitInput_columnCursor ::(data => Object, input) {
        
            @:choices = if (data.onGetChoices) data.onGetChoices() else data.choices;
            // no choices
            when(choices == empty || choices->keycount == 0) true;
            
            
            when(input == empty && data.rendered != empty) false;
            @choice = input;                   
            
            
            @:prompt = data.prompt;
            @:itemsPerColumn = data.itemsPerColumn;
            @:leftWeight = data.leftWeight;
            @:topWeight = data.topWeight;
            @:canCancel = data.canCancel;
            @:onChoice = data.onChoice;
            
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
            choices->foreach(do:::(index, choice) {
                @entry = ('  ') + choice;
                if (columns[column]->keycount == y && column == x) which = index;
                
                columns[column]->push(value:entry);

                if (entry->length > columnWidth[column])
                    columnWidth[column] = entry->length;
                
                if (columns[column]->keycount >= itemsPerColumn) ::<= {
                    column+=1;
                    columns[column] = [];
                    columnWidth->push(value:0);
                };
            });
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
            };                  
            
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
            };

            // its just a regular choice at that point. Most of the time
            // we can be a little sloppy here.
            when(columns->keycount == 1)
                choices(choices, prompt, leftWeight, topWeight, canCancel);
            
            
            // reformat with spacing
            @:choicesModified = [];
            [0, itemsPerColumn]->for(do:::(i) {
                @choice = '';
                columns->foreach(do:::(index, text) {
                    if (text[i] != empty) ::<= {
                        choice = choice + text[i];
                        
                        [choice->length, columnWidth[index]]->for(do:::(n) {
                            choice = choice + ' ';
                        });
                        choice = choice + '   ';
                    };
                    
                });
                choicesModified->push(value:choice);
            });

            renderThis(data, selfRender::{
                renderText(
                    lines: choicesModified,
                    speaker: prompt,
                    leftWeight,
                    topWeight,
                    limitLines:9
                ); 
            });            
                
                
            when (choice == CURSOR_ACTIONS.CONFIRM) ::<= {
                onChoice(choice:which + 1);
                return true;
            };
                
            if (canCancel && choice == CURSOR_ACTIONS.CANCEL) ::<= {
                data.keep = empty;
                return true;
            };
            

            return false;
        };
        
        @:commitInput_display ::(data, input) {
            if (data.rendered == empty) ::<= {
                renderThis(data, selfRender::{
                    renderText(
                        leftWeight: data.leftWeight, 
                        topWeight: data.topWeight, 
                        lines: data.lines,
                        speaker:data.prompt,
                        limitLines : data.pageAfter,
                        hasNotch: true
                    );
                });
            };
        
            return match(input) {
              (CURSOR_ACTIONS.CONFIRM, 
               CURSOR_ACTIONS.CANCEL): ::<= {
                return true;
               },
              default: false
            };
        };
        
        
        @:CHOICE_MODE = {
            CURSOR : 0,
            NUMBER : 1,
            COLUMN_CURSOR : 2,
            COLUMN_NUMBER : 3,
            CURSOR_MOVE: 4,
            DISPLAY: 5,
            NODISPLAY: 6
        };
        
        
        this.interface = {
            commitInput : commitInput,
            
            RENDER_AGAIN : {
                get ::<- 1
            },
            
            // Similar to message, but accepts a set of 
            // messages to display
            queueMessageSet::(speaker, set => Object, leftWeight, topWeight, pageAfter, onLeave) {
                set->foreach(do::(i, text) <- 
                    this.queueMessage(
                        speaker,
                        text,
                        leftWeight,
                        topWeight,
                        pageAfter,
                        onLeave
                    )
                );
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

                [0, text->length]->for(do:::(i) {
                    @:word = text->charAt(index:i); 
                    when(word == '\n') ::<= {
                        lines->push(value:line);
                        line = '';                    
                    };
                    line = line + word;
                    if (line->length >= canvas.width-4) ::<= {
                        @nextLine = '';
                        [::] {
                            forever(do:::{
                                @ch = line->charAt(index:line->length-1);
                                when(line->length < canvas.width-4 && ch == ' ') send();

                                nextLine = ch + nextLine;
                                line = line->substr(from:0, to:line->length-2);
                                                          

                            });
                        };                                                
                        lines->push(value:line);
                        line = nextLine;
                    };
                });
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
            queueDisplayColumns::(prompt, columns, leftWeight, topWeight, pageAfter, onLeave) {
                @:lines = [];
                @:widths = [];
                @rowcount = 0;
                columns->foreach(do:::(index, lines) {
                    @width = 0;
                    lines->foreach(do:::(row, line) {
                        if (line->length > width)
                            width = line->length;

                        if (row+1 > rowcount)
                            rowcount = row+1;
                    });
                    
                    widths->push(value:width);                    
                });

                [0, rowcount]->for(do:::(row) {
                    @line = '';
                
                    columns->foreach(do:::(column, lines) {
                        line = line + lines[row];
                        [lines[row]->length, widths[column]]->for(do:::(i) {
                            line = line + ' ';
                        });                    
                        line = line + ' ';
                    });                
                    
                    lines->push(value:line);
                });                
           
                this.queueDisplay(
                    prompt, lines, pageAfter, leftWeight, topWeight, onLeave
                );
            },
            
            // like message, but tried to fit the text on one page.
            // If it doesnt fit, display will try and make it scrollable.
            //
            // lines should be an array of strings.
            queueDisplay::(prompt, lines, pageAfter, leftWeight, topWeight, renderable, onLeave) {
                nextResolve->push(value:[::{
                    if (pageAfter == empty) pageAfter = MAX_LINES_TEXTBOX;
                    [0, lines->keycount, pageAfter]->for(do:::(i) {
                        choiceStack->push(value:{
                            topWeight: topWeight,
                            leftWeight : leftWeight,
                            lines:lines->subset(from:i, to:min(a:i+pageAfter, b:lines->keycount)-1),
                            pageAfter: pageAfter,
                            prompt: prompt,
                            onLeave: onLeave,
                            mode: CHOICE_MODE.DISPLAY,
                            renderable: renderable
                        });
                    });                       
                }]);
            },
            
            // A place holder action. This can be used to run a function 
            // in order, or for rendering graphics.
            // onEnter runs whenever the display is entered.
            queueNoDisplay::(renderable, keep, onEnter => Function, jumpTag, onLeave) {
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
            queueChoices::(choices, prompt, leftWeight, topWeight, canCancel, defaultChoice, onChoice => Function, renderable, keep, onGetChoices, jumpTag, onLeave) {
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
                        onLeave : onLeave,
                        keep: keep,
                        onGetChoices : onGetChoices,
                        renderable:renderable,
                        jumpTag : jumpTag
                    });
                }]);
            },

            canJumpToTag::(name => String) {
                @:cs = [...choiceStack];
                return [::] {
                    forever(do::{
                        if (cs->keycount == 0)
                            send(message:false);
                        @:data = cs[cs->keycount-1];
                        if (data.jumpTag != name) ::<= {
                            cs->pop;
                        } else 
                            send(message:true);
                    });
                };            
            },

            // pops all choices in the stack until the tag is hit.
            jumpToTag::(name => String, goBeforeTag, doResolveNext, clearResolve) {
                [::] {
                    forever(do::{
                        if (choiceStack->keycount == 0)
                            error(detail:'jumpToTag() could not find a dialogue tag with name ' + name);
                            
                        @:data = choiceStack[choiceStack->keycount-1];
                        if (data.jumpTag != name) ::<= {
                            data.keep = false;
                            next(dontResolveNext:true);
                        } else 
                            send();
                    });
                };
                if (goBeforeTag != empty) ::<= {
                    canvas.popState();
                    @:data = choiceStack->pop; 
                    if (data.onLeave)
                        data.onLeave();                  
                };
                canvas.commit();                
                choiceStack[choiceStack->keycount-1].rendered = empty;
                if (clearResolve) ::<= {
                    nextResolve = [];
                };


                if (doResolveNext) ::<={
                    resolveNext();
                };
                
                    
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
            queueCursorMove ::(prompt, leftWeight, topWeight, onMove, renderable, onLeave) {
                nextResolve->push(value:[::{
                    choiceStack->push(value:{
                        mode: CHOICE_MODE.CURSOR_MOVE,
                        prompt: prompt,
                        leftWeight: leftWeight,
                        topWeight: topWeight,
                        onChoice:onMove,
                        onLeave:onLeave,
                        renderable:renderable,
                    });
                    canvas.clear();
                }]);
            },  
            
                         

            
            CURSOR_ACTIONS : {
                get::<- CURSOR_ACTIONS
            },
            
            forceExit ::(soft){
                choiceStack[choiceStack->keycount-1].keep = empty;
                next();
            },

            // ask yes or no immediately.
            queueAskBoolean::(prompt, onChoice => Function, onLeave) {
                this.queueChoices(prompt, choices:['Yes', 'No'], canCancel:false, onLeave:onLeave,
                    onChoice::(choice){
                        onChoice(which: choice == 1);
                    }
                );
            },
            

        };    
    }
).new();

return WindowEvent;

