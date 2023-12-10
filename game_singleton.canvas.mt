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
@:struct = import(module:'game_struct.mt');
@:class = import(module:'Matte.Core.Class');


@CANVAS_WIDTH  = 80;
@CANVAS_HEIGHT = 24;

@:hints = {
    // for general messages describing whats going on.
    NEUTRAL : 0,
    
    // For something positive to a player
    GOOD : 1,


    // For something not so good to a player
    BAD : 2,


    // Like neutral, but less focused
    SUBDUED : 3,

    // To really let the user know of something.
    ALERT : 4,

    // Dialog spoken by a character
    QUOTE : 5,
    
    // for the speaker of a quote.
    SPEAKER : 6,
    
    // For indicate a choice for the user non-diagetically
    PROMPT: 7,

    // To indicate to the IO system that a 
    // break in output
    NEWLINE: 8,
    
    // To indicate to the IO system to clear the currently 
    // displayed output for clarity
    CLEAR: 9
}



// converts a string into an array of characters.
@:splay ::(string => String) {
    @:out = [];
    for(0, string->length)
        ::(i) <- out->push(
            value:string->charAt(
                index:i
            )
        )
    
    
    return out;
}


@:min ::(a => Number, b => Number) {
    when(a < b) a;
    return b;
}

@:TextIter = struct(
    name: 'Wyvern.Canvas.TextIter',
    items : {
        text : String,
        color : Number
    }
);

@:CHAR__CORNER_TOPLEFT  = '╒';
@:CHAR__CORNER_TOPRIGHT = '╕';
@:CHAR__CORNER_BOTTOMRIGHT = '┘';
@:CHAR__CORNER_BOTTOMLEFT = '└';
@:CHAR__SIDE = '│';
@:CHAR__TOP = '═';
@:CHAR__BOTTOM = '─';

return class(
    name: 'Wyvern.Canvas',
    define:::(this) {
        @canvas = [];
        @penx = 0;
        @peny = 0;
        @penColor = hints.NEUTRAL;
        @onCommit;
        @debugLines = [];
        @:lines_output = [];
        
        @savestates = [];
        

        
        this.interface = {
            resize ::(width, height) {
                CANVAS_HEIGHT = height;
                CANVAS_WIDTH = width;
                @iter = 0;
                for(0, CANVAS_HEIGHT)::(index) {
                    for(0, CANVAS_WIDTH)::(ch) {
                        canvas[iter] = ' ';
                        iter += 1;
                    }
                }
            },

            movePen ::(x => Number, y => Number) {
                penx = x->floor;
                peny = y->floor;
            },
            
            penX : {
                set ::(value) <- (
                    penx = value
                ),
                get ::<- penx
            },

            penY : {
                set ::(value) <- peny = value,
                get ::<- peny
            },
            
            onCommit : {
                get ::<- onCommit,
                set ::(value)<- onCommit = value
            },
            
            width : {
                get ::<- CANVAS_WIDTH
            },

            height : {
                get ::<- CANVAS_HEIGHT
            },

            
            penColor : {
                set ::(value => Number)<- penColor = value,
                get ::<- penColor
            },
            
            debugLine : {
                set ::(value) <- debugLines[0] = value => String,
                get ::<- debugLines[0]
            },

            renderFrame ::(top, left, width, height) {

                // TOP LINE
                this.movePen(
                    x: left,
                    y: top 
                );
                
                this.drawChar(text:CHAR__CORNER_TOPLEFT);
                this.penX += 1;
                for(2, width)::(x) {
                    this.drawChar(text:CHAR__TOP);    
                    this.penX += 1;
                            
                }
                this.drawChar(text:CHAR__CORNER_TOPRIGHT);

                
                // NLINES
                for(1, height - 1)::(y) {
                    this.movePen(x: left, y: top+y);
                    this.drawChar(text:CHAR__SIDE);
                    this.penX += 1;

                    for(2, width)::(x) {
                        this.erase();        
                        this.penX += 1;
                    }
                    this.drawChar(text:CHAR__SIDE);
                }


                // BOTTOM LINE
                this.movePen(
                    x: left,
                    y: top+(height-1)
                );
                
                this.drawChar(text:CHAR__CORNER_BOTTOMLEFT);
                this.penX += 1;
                for(2, width)::(x) {
                    this.drawChar(text:CHAR__BOTTOM);    
                    this.penX += 1;
                            
                }
                this.drawChar(text:CHAR__CORNER_BOTTOMRIGHT);




            },  
            
            pushState ::{
                @:canvasCopy = [...canvas];
                
                savestates->push(value:{
                    text : canvasCopy
                });
            },
            
            popState ::{
                when(savestates->keycount == 0)
                    error(detail:'Tried to call popState() when canvas savestate stack was empty. Fix ur gosh darn application');

                @top = savestates->pop;
                canvas = top.text;
            },
                        
            drawText ::(text => String) {
                when (penx < 0 || penx >= CANVAS_WIDTH || peny < 0 || peny >= CANVAS_HEIGHT) empty;              
                for(penx, penx+min(a:text->length, b:CANVAS_WIDTH-penx))::(i) {
                    @ch = text->charAt(index:i-penx);
                    if (ch == '\n') ch = ' ';
                    canvas[i+peny*CANVAS_WIDTH] = ch;
                }
            },
            
            drawChar ::(text => String) {  
                when (penx < 0 || penx >= CANVAS_WIDTH || peny < 0 || peny >= CANVAS_HEIGHT) empty;              
                if (text == '\n') text = ' ';
                canvas[penx+peny*CANVAS_WIDTH] = text->charAt(index:0);               
            },
            
            drawRectangle ::(text => String, width => Number, height => Number) {
                @ch = text->charAt(index:0);
                for(0, height)::(y) {
                    @offsety = peny + y;
                    for(0, width)::(x) {
                        canvas[penx+x + (offsety)*CANVAS_WIDTH] = ch
                    }
                }
            },
            
            erase :: {
                this.penColor = hints.NEUTRAL;
                this.drawChar(text:' ');
            },
            
            // like penText, but moves the pen position
            writeText ::(text => String) {
                foreach(splay(string:text))::(index, ch) {
                    this.drawChar(text:ch);
                    if (penx >= CANVAS_WIDTH)
                        this.movePen(x:0, y:peny+1)
                    else
                        this.movePen(x:penx+1, y:peny)
                    ;
                }
            },
            
            drawTextCentered ::(text => String, y => Number) {
                
            },
            
            clear :: {
                when (savestates->keycount) ::<= {
                    @prevCanvas = savestates[savestates->keycount-1].text;
                    canvas = [...prevCanvas];
                }
                this.blackout();
            },
            
            blackout ::{
                @iter = 0;
                for(0, CANVAS_HEIGHT)::(i) {
                    for(0, CANVAS_WIDTH)::(ch) {
                        canvas[iter] = ' ';
                        iter += 1;
                    }
                }          
            },
            
            commit ::(renderNow) {
                // debug lines happen as the LAST possible thing 
                // the canvas does to ensure that its always on top.
                if (debugLines[0] != empty) ::<= {
                    this.movePen(x:0, y:0);
                    this.drawText(text: debugLines[0]);
                }
                

                for(0, CANVAS_HEIGHT)::(row) {
                    lines_output[row] = String.combine(strings:canvas->subset(from:row*CANVAS_WIDTH, to:(row+1)*CANVAS_WIDTH-1));
                    /*
                    @:line = canvas[row];
                    @:lineColors = canvasColors[row];

                    @:iters = [];
                    @last = 0;
                    @iter = TextIter.new(
                        state : {
                            text : '',
                            color : lineColors[0]
                        }
                    );
                    
                    
                    [0, CANVAS_WIDTH]->for(do:::(x) {
                        if (iter.color != lineColors[x]) ::<= {
                            iter.text = String.combine(strings:line->subset(from:last, to:x));
                            iters->push(iter);
                            last = x;                            
                            iter = TextIter.new(
                                state : {
                                    text : '',
                                    color : lineColors[x]
                                }
                            );
                        }
                    });
                    iter.text = String.combine(strings:line->subset(from:last, to:CANVAS_WIDTH-1));
                    iters->push(value:iter);                    
                    lines->push(value:iters);
                    */
                }
                
                
                onCommit(
                    lines:lines_output,
                    renderNow              
                );                
            }
        }    
    }
).new();
