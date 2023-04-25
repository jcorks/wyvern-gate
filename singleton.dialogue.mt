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
// uses the canvas to push and queue dialogue.

@:canvas = import(module:'singleton.canvas.mt');
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

return class(
    name: 'Wyvern.UI',
    define:::(this) {
        @onInput;
        @isCursor = true;
        @choiceStack = [];
    
    
    
    


        @:choicesCursor ::(data => Object, input) {
            @:choices = data.choices;
            @:prompt = data.prompt; 
            @:leftWeight = data.leftWeight; 
            @:topWeight = data.topWeight; 
            @:canCancel = data.canCancel;
            @:defaultChoice = data.defaultChoice;
            @:onChoice = data.onChoice;
            @choice = input;
            
            @continue = match(choice) {
              (CURSOR_ACTIONS.UP,
               CURSOR_ACTIONS.DOWN,
               CURSOR_ACTIONS.LEFT,
               CURSOR_ACTIONS.RIGHT,
               CURSOR_ACTIONS.CONFIRM,
               CURSOR_ACTIONS.CANCEL): true,
               
              default:false
            };
            // first render
            if (data.rendered == empty) ::<= {
                continue = true;
                data.rendered = true; 
            };  

            when(!continue) false;            
            @:PAGE_SIZE = 7;        
            @:WIDTH = ::<= {
                @max = 0;
                choices->foreach(do:::(i, text) {
                    if (text->length > max)
                        max = text->length;
                });
                
                return max;
            };
            @cursorPos = if (defaultChoice == empty) 0 else defaultChoice-1;
            @cursorPageTop = 0;

            if (choice == CURSOR_ACTIONS.UP) ::<= {
                cursorPos -= 1;
            };
            if(choice == CURSOR_ACTIONS.DOWN) ::<= {
                cursorPos += 1;
            };

            if (cursorPos < 0) cursorPos = 0;
            if (cursorPos >= choices->keycount) cursorPos = choices->keycount-1;

            if (cursorPos >= cursorPageTop+PAGE_SIZE) cursorPageTop+=1;
            if (cursorPos  < cursorPageTop) cursorPageTop -=1;

            if (cursorPageTop > choices->keycount - PAGE_SIZE) cursorPageTop = choices->keycount-PAGE_SIZE;
            if (cursorPageTop < 0) cursorPageTop = 0;
            
            @:choicesModified = [];
            
            
            if (choices->keycount > PAGE_SIZE) ::<= {
                @initialLine = if (cursorPageTop > 0) '▴' else ' ';
                [initialLine->length, WIDTH]->for(do:::(i) {
                    initialLine = initialLine + ' ';
                });                   
                choicesModified->push(value:initialLine);


                [cursorPageTop, cursorPageTop+PAGE_SIZE]->for(do:::(index) {
                    
                    choicesModified->push(value: (if (cursorPos == index) '▹  ' else '   ') + choices[index]);
                });


                if (cursorPageTop + PAGE_SIZE < (choices->keycount))                    
                    choicesModified->push(value:'▾  ')
                else
                    choicesModified->push(value:'       ');
            } else ::<= {
                [0, choices->keycount]->for(do:::(index) {
                    choicesModified->push(value: (if (cursorPos == index) '▹  ' else '   ') + choices[index]);
                });
            
            };
            
            if (choice == CURSOR_ACTIONS.UP||
                choice == CURSOR_ACTIONS.DOWN) ::<= {
                data.defaultChoice = (cursorPos+1);
            };

            //if (canCancel) ::<= {
            //    choicesModified->push(value:'(Cancel)');
            //};
            if (data.renderable) 
                data.renderable.render();
            renderText(
                lines: choicesModified,
                speaker: prompt,
                leftWeight,
                topWeight,
                limitLines:13
            ); 
            canvas.commit();    

                
            when(choice == CURSOR_ACTIONS.CANCEL && canCancel) ::<= {
                canvas.popState();
                choiceStack->pop;
                return true;
            };
            
            when(choice == CURSOR_ACTIONS.CONFIRM) ::<= {
                if (data.keep == false || data.keep == empty) ::<= {
                    canvas.popState();
                    choiceStack->pop;
                }; 
                data.rendered = empty;
                onChoice(choice:cursorPos + 1);
                return true;
            };
                
            return false;
        };


        @:choiceCursorMove ::(data => Object, input) {
            @:prompt = data.prompt; 
            @:leftWeight = data.leftWeight; 
            @:topWeight = data.topWeight; 
            @:defaultChoice = data.defaultChoice;
            @:onChoice = data.onChoice;
            @:choice = input;         
            @:renderable = data.renderable;   
            
            //if (canCancel) ::<= {
            //    choicesModified->push(value:'(Cancel)');
            //};
            if (data.rendered == empty) ::<= {
                if (data.renderable) 
                    data.renderable.render();
                renderText(
                    lines: ['[Cancel to return]'],
                    speaker: prompt,
                    leftWeight,
                    topWeight,
                    limitLines:13
                ); 
                canvas.commit();    
                data.rendered = true;
            };


            when(choice == CURSOR_ACTIONS.CANCEL) ::<= {
                canvas.popState();
                choiceStack->pop;
                return true;
            };           

            if (choice == CURSOR_ACTIONS.UP||
                  choice == CURSOR_ACTIONS.DOWN ||
                  choice == CURSOR_ACTIONS.LEFT ||
                  choice == CURSOR_ACTIONS.RIGHT) ::<= {
                onChoice(choice);
                data.rendered = empty;
                this.commitInput();
            };
            return false;    
        };        
    
    
    
        @:choiceColumnsCursor ::(data => Object) {
        
            @:choices = data.choices;
            @:prompt = data.prompt;
            @:itemsPerColumn = data.itemsPerColumn;
            @:leftWeight = data.leftWeight;
            @:topWeight = data.topWeight;
            @:canCancel = data.canCancel;
            @:onChoice = data.onChoice;
            
            @x = 0;
            @y = 0;
            onChoice(choice:[::] {
                forever(do:::{

                    @:choicesModified = [];
                    @column = 0;
                    
                    @:columns = [[]];
                    @:columnWidth = [0];

                    @height;
                    @width;
                    @which;
                    choices->foreach(do:::(index, choice) {
                        @entry = (if (columns[column]->keycount == y && column == x)'▹ ' else '  ') + choice;
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
                    // first render
                    if (data.rendered == empty) ::<= {
                        renderText(
                            lines: choicesModified,
                            speaker: prompt,
                            leftWeight,
                            topWeight,
                            limitLines:9
                        ); 
                        canvas.commit();
                        data.rendered = true; 
                    };                                           
                    @choice;
                    [::] {  
                        forever(do:::{
                            choice = onInput();
                            match(choice) {
                              (CURSOR_ACTIONS.UP,
                               CURSOR_ACTIONS.DOWN,
                               CURSOR_ACTIONS.LEFT,
                               CURSOR_ACTIONS.RIGHT,
                               CURSOR_ACTIONS.CONFIRM,
                               CURSOR_ACTIONS.CANCEL): send()
                            };
                        });
                    };                                              
                    renderText(
                        lines: choicesModified,
                        speaker: prompt,
                        leftWeight,
                        topWeight,
                        limitLines:9
                    ); 
                    canvas.commit();                    
                    
                    if (choice == CURSOR_ACTIONS.CONFIRM)
                        send(message:which+1);        
                        
                    if (canCancel && choice == CURSOR_ACTIONS.CANCEL)  
                        send(message:0);  
                    
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
                        
                });
            });
        
        };
        
        @:displayCursor ::(data, input) {
            if (data.rendered == empty) ::<={
                renderText(
                    leftWeight: data.leftWeight, 
                    topWeight: data.topWeight, 
                    lines: data.lines,
                    speaker:data.prompt,
                    limitLines : data.pageAfter,
                    hasNotch: true
                );
                canvas.commit();
                data.rendered = false;
            };
        
            return match(input) {
              (CURSOR_ACTIONS.CONFIRM, 
               CURSOR_ACTIONS.CANCEL): ::<= {
                canvas.popState();
                choiceStack->pop;
                data.onNext();
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
            DISPLAY: 5
        };
        
       
        this.interface = {
            commitInput ::(input){    
                @:val = choiceStack[choiceStack->keycount-1];
                //if (val.jail == true) ::<= {
                //    choiceStack->push(value:val);
                //};
                @result = match(val.mode) {
                  (CHOICE_MODE.CURSOR):         choicesCursor(data:val, input),
                  (CHOICE_MODE.COLUMN_CURSOR):  choiceColumnsCursor(data:val, input),
                  (CHOICE_MODE.DISPLAY):        displayCursor(data:val, input),
                  (CHOICE_MODE.CURSOR_MOVE):    choiceCursorMove(data:val, input)
                };        
                // true means done
                if (result == true) ::<= {
                    if (choiceStack->keycount)
                        this.commitInput();                    
                };
            },
            
            
            // Similar to message, but accepts a set of 
            // messages to display
            messageSet::(speaker, set => Object, leftWeight, topWeight, pageAfter, onNext => Function) {
                set = [...set];
                @:post = ::{
                    when(set->keycount == 0) onNext();
                    @:text = set[0];
                    set->remove(key:0);
                    this.message(
                        speaker,
                        text,
                        leftWeight,
                        topWeight,
                        pageAfter,
                        onNext:post
                    );   
                };
                post();
            },
            
            // Posts a message to the screen. In the case that a 
            // message overflows, it will be split into multiple dialogs.
            //
            // The function returns when the message is displayed in full
            // to the user.
            message::(speaker, text, leftWeight, topWeight, pageAfter, onNext => Function) {
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
                

                this.display(
                    leftWeight, topWeight,
                    prompt:speaker,
                    lines,
                    pageAfter,
                    onNext
                );              
            },
            
            // Similar to display(), but takes in an array of string arrays and 
            // treats them as columns, appended left-to-right separated with a 
            // space.
            displayColumns::(prompt, columns, leftWeight, topWeight, pageAfter, onNext => Function) {
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
           
                this.display(
                    prompt, lines, pageAfter, leftWeight, topWeight, onNext
                );
            },
            
            // like message, but tried to fit the text on one page.
            // If it doesnt fit, display will try and make it scrollable.
            //
            // lines should be an array of strings.
            display::(prompt, lines, pageAfter, leftWeight, topWeight, onNext => Function) {
                if (pageAfter == empty) pageAfter = MAX_LINES_TEXTBOX;
                [0, lines->keycount, pageAfter]->for(do:::(i) {
                    choiceStack->push(value:{
                        topWeight: topWeight,
                        leftWeight : leftWeight,
                        lines:lines->subset(from:i, to:min(a:i+pageAfter, b:lines->keycount)-1),
                        pageAfter: pageAfter,
                        prompt: prompt,
                        mode: CHOICE_MODE.DISPLAY,
                        onNext: onNext
                    });
                    canvas.pushState();      
                });                       
            },




            
            
            // Allows for choosing from a list of options.
            // Like all UI choices, the weight can be chosen.
            // Prompt will be displayed, like speaker in the message callback
            //
            choices ::(choices, prompt, leftWeight, topWeight, canCancel, defaultChoice, onChoice => Function, renderable, keep) {
                choiceStack->push(value:{
                    mode: CHOICE_MODE.CURSOR,
                    choices: choices,
                    prompt: prompt,
                    leftWeight: leftWeight,
                    topWeight: topWeight,
                    canCancel: canCancel,
                    defaultChoice: defaultChoice,
                    onChoice: onChoice,
                    keep: keep,
                    renderable:renderable
                });
                canvas.pushState();      
   
            },
            cursorMove ::(prompt, leftWeight, topWeight, onMove, renderable) {
                choiceStack->push(value:{
                    mode: CHOICE_MODE.CURSOR_MOVE,
                    prompt: prompt,
                    leftWeight: leftWeight,
                    topWeight: topWeight,
                    onChoice:onMove,
                    renderable:renderable
                });
                canvas.clear();
                canvas.pushState();      
            },               

            
            CURSOR_ACTIONS : {
                get::<- CURSOR_ACTIONS
            }
            /*
            choicesNow ::(choices, prompt, leftWeight, topWeight, canCancel, defaultChoice) {
                @out;
                choiceStack->push(value:{
                    mode: if (isCursor) CHOICE_MODE.CURSOR else CHOICE_MODE.NUMBER,
                    choices: choices,
                    prompt: prompt,
                    leftWeight: leftWeight,
                    topWeight: topWeight,
                    canCancel: canCancel,
                    defaultChoice: defaultChoice,
                    onChoice::(choice) {
                        out = choice;
                    }
                });
                commitChoice();
                return out;
            },  
            */      
            /*
 
            
            
            // like choices(), but instead displays it column-wise.
            // It's pretty limited, though.
            pushChoiceColumns ::(choices, prompt, itemsPerColumn, leftWeight, topWeight, canCancel, onChoice => Function) {
                choiceStack->push(value:{
                    mode:if (isCursor) CHOICE_MODE.COLUMN_CURSOR else CHOICE_MODE.COLUMN_NUMBER,
                    choices: choices,
                    prompt: prompt,
                    itemsPerColumn: itemsPerColumn,
                    leftWeight : leftWeight,
                    topWeight : topWeight,
                    canCancel : canCancel,
                    onChoice : onChoice
                });
            
            },

            choiceColumnsNow ::(choices, prompt, itemsPerColumn, leftWeight, topWeight, canCancel) {
                @out;
                choiceStack->push(value:{
                    mode:if (isCursor) CHOICE_MODE.COLUMN_CURSOR else CHOICE_MODE.COLUMN_NUMBER,
                    choices: choices,
                    prompt: prompt,
                    itemsPerColumn: itemsPerColumn,
                    leftWeight : leftWeight,
                    topWeight : topWeight,
                    canCancel : canCancel,
                    onChoice ::(choice) {
                        out = choice;
                    }
                });
                commitChoice();
                return out;
            },
            
            // ask yes or no immediately.
            askBoolean::(prompt) {
                @out;
                this.pushChoices(prompt, choices:['Yes', 'No'],
                    onChoice::(choice) {
                        out = choice;
                    }
                );
                this.showChoices();
                return if(out == 1) true else false;
            },
            
            
            showChoices :: {
                commitChoice();
            },
            
            
            popChoice :: {
                choiceStack->pop;
            },
            
            choiceCount : {
                get ::{
                    return choiceStack->keycount;
                }
            },

            
            startChoiceStack ::{
                startChoices();
            },

            */
        };    
    }
).new();

