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
        @animations = [];
        
        @savestates = [];
        @idStatePool = 0;
        @idStatePool_dead = [];
        @backgrounds = {};
        
        
        @:animateNext::{
            foreach(animations) ::(index, queuedFrame) {
                if (queuedFrame() == this.ANIMATION_FINISHED) ::<= {
                    animations->remove(key:index);
                }
            }

            this.commit();
        }
        
        @onFrameComplete::{
            when(animations->size == 0) empty;
            animateNext();
        }

        
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
            
            ANIMATION_FINISHED : {
                get ::<- -1
            },

            penY : {
                set ::(value) <- peny = value,
                get ::<- peny
            },
            
            onCommit : {
                get ::<- onCommit,
                set ::(value)<- onCommit = value
            },
            
            onFrameComplete : {
                get ::<- onFrameComplete
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
            
            renderBarAsString ::(width, fillFraction) {
                if (width == empty) width = 12;
                
                @ratio = fillFraction;;
                if (ratio > 1) ratio = 1;
                if (ratio < 0) ratio = 0;
                @numFilled = ((width - 2) * (ratio))->floor;
                if (fillFraction > 0 && numFilled < 1) numFilled = 1;
                
                @out = ' ';
                for(0, numFilled)::(i) {
                    out = out+'▓';
                }
                for(0, width - numFilled - 2)::(i) {
                    out = out+'▁';
                }
                return out + ' ';            
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
            
            renderTextFrameGeneral::(
                lines,
                title,
                topWeight,
                leftWeight,
                notchText
            ) {
                if (leftWeight == empty) leftWeight = 0.5;
                if (topWeight  == empty) topWeight  = 0.5;

                @width = if (title == empty) 0 else title->length;
                foreach(lines)::(index, line) {
                    if (line->length > width) width = line->length;
                }
                
                @left   = (this.width - (width+4))*leftWeight;
                width   = width + 4;
                @top    = (this.height - (lines->keycount + 4)) * topWeight;
                @height = lines->keycount + 4;
                
                if (top < 0) top = 0;
                if (left < 0) left = 0;
                
                
                this.renderFrame(top, left, width, height);

                // render text:
                
                foreach(lines)::(index, line) {
                    this.movePen(x: left+2, y: top+2+index);
                    this.drawText(text:line);
                }

                if (title != empty) ::<= {
                    this.movePen(x: left+2, y:top);
                    this.drawText(text:title);
                }

                if (notchText != empty) ::<= {
                    this.movePen(x: left+width-8, y:top+height-1);
                    this.drawText(text:notchText);
                }                
            },
            
            addBackground::(render) {
                @:key = {};
                backgrounds[key] = render;
                breakpoint();
                return key;
            },
            
            removeBackground::(id) {
                backgrounds->remove(key:id);
            },
            
            pushState ::{
                @:canvasCopy = [...canvas];
                
                @id = if (idStatePool_dead->size) 
                        idStatePool_dead->pop 
                      else ::<= {
                        idStatePool += 1;
                        return idStatePool;
                      }
                savestates->push(value:{
                    id : id,
                    text : canvasCopy
                });
                
                return id;
            },
            
            replaceState ::(id){
                @w = savestates->filter(by::(value) <- value.id == id);
                if (w->size != 1)
                    error(detail:'Tried to replaceState() on something that isnt a state!');

                w[0].text = [...canvas];
                return id;
            },            
            
            states : {
                get ::<- [...savestates]
            },
            
            removeState ::(id) {
                @w = savestates->filter(by::(value) <- value.id == id);
                if (w->size != 1)
                    error(detail:'Tried to removeState() on something that isnt a state!');

                idStatePool_dead->push(value:w[0].id);
                savestates->remove(key:savestates->findIndex(value:w[0]));
                this.clear();
            },
            
            stateCount : {
                get ::<- savestates->keycount
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
                    foreach(backgrounds) ::(k, v) {
                        v();
                    }
                }
                this.blackout();
            },
            
            blackout ::(with){
                if (with == empty) with = ' ';
                @iter = 0;
                for(0, CANVAS_HEIGHT)::(i) {
                    for(0, CANVAS_WIDTH)::(ch) {
                        canvas[iter] = with;
                        iter += 1;
                    }
                }  
                when(backgrounds->size == 0) empty;
                foreach(backgrounds) ::(k, v) {
                    v();
                }

            },
            
            // formats columns of text into lines where columns are lined up
            columnsToLines::(columns, leftJustifieds, spacing) {
                if (leftJustifieds == empty)
                    leftJustifieds = [...columns]->map(to::(value) <- true);
                
                if (spacing == empty)
                    spacing = 1;
                    
                    
                    
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


                @:parts = [];

                @:formatColumn::(column, text) {
                    if (!leftJustifieds[column]) ::<= {
                        for(text->length, widths[column])::(i) {
                            parts->push(value:' ');
                        }
                    }
                    parts->push(value:text);                    
                    if (leftJustifieds[column]) ::<= {
                        for(text->length, widths[column])::(i) {
                            parts->push(value:' ');
                        }
                    }

                }


                for(0, rowcount)::(row) {
                    @line = '';
                    parts->setSize(size:0);                
                    foreach(columns)::(column, lines) {
                        formatColumn(
                            column,
                            text: lines[row]
                        );
                        
                        for(0, spacing) ::(i) {
                            parts->push(value:' ');
                        }
                    }   
                    
                    lines->push(value:String.combine(strings:parts));
                }   
                return lines;            
            },
            
            // Queues a set of frames to render and then play.
            // These happen as the external environment confirms that a frame has been posted
            // If multiple animations are queued, their frames will be interleaved.
            // The function passed is expected to control the canvas. Committing is handled
            // by the canvas and should not be called unless advanced effects are being used.
            //
            // The onRenderFrame function will run until it returns canvas.ANIMATION_FINISHED
            queueAnimation::(onRenderFrame => Function) {
                animations->push(value:onRenderFrame);
                animateNext();
            },
            
            
            commit ::(renderNow) {
                // debug lines happen as the LAST possible thing 
                // the canvas does to ensure that its always on top.
                if (debugLines[0] != empty) ::<= {
                
                    this.movePen(x:0, y:0);
                    this.drawText(text: debugLines[0]);
                }
                
                
                // This helps debug which savestates are active.
                /*
                    @:trackWindows ::{
                        @out = '{';
                        foreach(this.states) ::(i, state) {
                            out = out + state.id + ' ';
                        }
                        return out + '}';
                    }                

                    this.movePen(x:0, y:1);
                    this.drawText(text: trackWindows());
                */

                for(0, CANVAS_HEIGHT)::(row) {
                    lines_output[row] = String.combine(strings:canvas->subset(from:row*CANVAS_WIDTH, to:(row+1)*CANVAS_WIDTH-1));
                }
                
                
                onCommit(
                    lines:lines_output,
                    renderNow              
                );                
            }
        }    
    }
).new();
