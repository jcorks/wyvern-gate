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
@:EFFECT_FINISHED = -1;

/////////////////////////////////
// See if we have a native (quick) implementation
// If not, fallback on Matte implementation. 
// Matte version works okay, just might be a bit slower
// when scenes get heavy, like in battle.
@native = ::? {
  @:a = getExternalFunction(:'wyvern_gate__native__canvas')();
  
  a.EFFECT_FINISHED = EFFECT_FINISHED;
  a.width = CANVAS_WIDTH;
  a.height = CANVAS_HEIGHT;
  
  a.reset = getExternalFunction(:'wyvern_gate__native__canvas__reset');
  a.resize = getExternalFunction(:'wyvern_gate__native__canvas__resize');
  a.movePen = getExternalFunction(:'wyvern_gate__native__canvas__movePen');
  a.movePenRelative = getExternalFunction(:'wyvern_gate__native__canvas__movePenRelative');
  a.renderBarAsString = getExternalFunction(:'wyvern_gate__native__canvas__renderBarAsString');
  a.renderFrame = getExternalFunction(:'wyvern_gate__native__canvas__renderFrame');
  a.refitLines = getExternalFunction(:'wyvern_gate__native__canvas__refitLines');
  a.renderTextFrameGeneral = getExternalFunction(:'wyvern_gate__native__canvas__renderTextFrameGeneral');
  a.newFramebuffer = getExternalFunction(:'wyvern_gate__native__canvas__newFramebuffer');
  a.removeFramebuffer = getExternalFunction(:'wyvern_gate__native__canvas__removeFramebuffer');
  a.printFramebuffer = getExternalFunction(:'wyvern_gate__native__canvas__printFramebuffer');
  a.renderToFramebuffer = getExternalFunction(:'wyvern_gate__native__canvas__renderToFramebuffer');
  a.setFramebufferList = getExternalFunction(:'wyvern_gate__native__canvas__setFramebufferList');
  a.drawText = getExternalFunction(:'wyvern_gate__native__canvas__drawText');
  a.drawChar = getExternalFunction(:'wyvern_gate__native__canvas__drawChar');
  a.drawRectangle = getExternalFunction(:'wyvern_gate__native__canvas__drawRectangle');
  a.erase = getExternalFunction(:'wyvern_gate__native__canvas__erase');
  a.writeText = getExternalFunction(:'wyvern_gate__native__canvas__writeText');
  a.clear = getExternalFunction(:'wyvern_gate__native__canvas__clear');
  a.fill = getExternalFunction(:'wyvern_gate__native__canvas__fill');
  a.columnsToLines = getExternalFunction(:'wyvern_gate__native__canvas__columnsToLines');
  a.addEffect = getExternalFunction(:'wyvern_gate__native__canvas__addEffect');
  a.hasEffects = getExternalFunction(:'wyvern_gate__native__canvas__hasEffects');
  a.update = getExternalFunction(:'wyvern_gate__native__canvas__update');
  a.commit = getExternalFunction(:'wyvern_gate__native__canvas__commit');
  return a;  
} => {
  onError::(message) {
    //fallback on Matte implementation  
  }
}

when (native != empty) native;
//////////////////////////////////




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

/// @singleon Wyvern.Canvas
///
/// Canvas is the main class that handles rendering operations 
/// to the text buffer. While [#Wyvern.WindowEvent] handles 
/// higher-level output and management, Wyvern.WindowEvent can be used 
/// to create custom effects and animations.
///
/// The typical use-case is to provide Wyvern.WindowEvent with 
/// custom rendering operations, which typically require working with
/// Wyvern.Canvas
///
return class(
  name: 'Wyvern.Canvas',
  define:::(this) {
    @canvas = [];
    @penx = 0;
    @peny = 0;
    @onCommit;
    @debugLines = [];
    
    
    @idStatePool = 0;
    @idStatePool_dead = [];
    @effects = [];
    @counter = 0;
    @showEffects = true;
    
    @frames = [];
    @:noFrame = [];
    @currentFrame = noFrame;
    @currentSet;
    
    @:composite :: {
      // painter's!
      for(0, CANVAS_HEIGHT * CANVAS_WIDTH) ::(i) {
        canvas[i] = ::? {
          for(currentSet->size-1, -1) ::(n) {
            @:element = currentSet[n].textArray[i];
            if (element->type != Number) ::<= {
              send(:element);
            }
          }
          return ' ';
        }
      }
    }
    
    @:pushToScreen ::(renderNow) {
      @lines_output = [];
      for(0, CANVAS_HEIGHT)::(row) {
        lines_output[row] = String.combine(strings:canvas->subset(from:row*CANVAS_WIDTH, to:(row+1)*CANVAS_WIDTH-1));
      }
      
      onCommit(
        lines:lines_output,
        renderNow        
      );     
    }
    
    this.interface = {
      reset ::{
        idStatePool = 0;
        idStatePool_dead = [];
        frames = [];
      },
    
      resize ::(width, height) {
        CANVAS_HEIGHT = height;
        CANVAS_WIDTH = width;
      },



      movePen ::(x => Number, y => Number) {
        penx = x->floor;
        peny = y->floor;
      },

      movePenRelative ::(x => Number, y => Number) {
        penx += x->floor;
        peny += y->floor;
      },
      
      EFFECT_FINISHED : {
        get ::<- EFFECT_FINISHED
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

      
      renderBarAsString ::(width, fillFraction, character, emptyCharacter) {
        if (width == empty) width = 12;
        
        @ratio = fillFraction;;
        if (ratio > 1) ratio = 1;
        if (ratio < 0) ratio = 0;
        @numFilled = ((width - 2) * (ratio))->floor;
        if (fillFraction > 0 && numFilled < 1) numFilled = 1;
        if (character == empty)
          character = '▓'
        
        @out = ' ';
        for(0, numFilled)::(i) {
          out = out+character;
        }
        for(0, width - numFilled - 2)::(i) {
          out = out+if(emptyCharacter) emptyCharacter else '▁';
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
        penx += 1;
        for(2, width)::(x) {
          this.drawChar(text:CHAR__TOP);  
          penx += 1;
              
        }
        this.drawChar(text:CHAR__CORNER_TOPRIGHT);

        
        // NLINES
        for(1, height - 1)::(y) {
          this.movePen(x: left, y: top+y);
          this.drawChar(text:CHAR__SIDE);
          penx += 1;

          for(2, width)::(x) {
            this.drawChar(text:' ');
            penx += 1;
          }
          this.drawChar(text:CHAR__SIDE);
        }


        // BOTTOM LINE
        this.movePen(
          x: left,
          y: top+(height-1)
        );
        
        this.drawChar(text:CHAR__CORNER_BOTTOMLEFT);
        penx += 1;
        for(2, width)::(x) {
          this.drawChar(text:CHAR__BOTTOM);  
          penx += 1;
              
        }
        this.drawChar(text:CHAR__CORNER_BOTTOMRIGHT);




      },  
      
      // Takes an array of strings and returns a new array of strings 
      // that will fit once displayed. the standard is CANVAS_WIDTH - 4 
      // to leave room for the window frame if any.
      refitLines::(input => Object, maxWidth) {
        @:lines = [];
        foreach(input) ::(k, v) {
          lines->push(:v);
          if (k != input->size-1)
            lines->push(:'\n');
        }
        @:MAX_WIDTH = if (maxWidth == empty) CANVAS_WIDTH - 4 else maxWidth;
        
        @:text = String.combine(:lines);
        lines->setSize(:0);
        
        @chars = [];

        for(0, text->length)::(i) {
          @:word = text->charAt(:i); 
          when(word == '\n') ::<= {
            lines->push(:String.combine(:chars));
            chars->setSize(:0);          
          }
          chars->push(:word);
          if (chars->size >= MAX_WIDTH) ::<= {
            @nextLine = [];
            ::? {
              forever ::{
                @ch = chars[chars->size-1];
                when(chars->size < MAX_WIDTH && ch == ' ') send();

                nextLine->insert(at:0, value:ch);
                chars = chars->subset(from:0, to:chars->size-2);
                              

              }
            }                        
            lines->push(:String.combine(:chars));
            chars->setSize(:0);
            chars = nextLine;
          }
        }      
        lines->push(:String.combine(:chars));
        chars->setSize(:0);
        return lines;
      },
      
      
      renderTextFrameGeneral::(
        lines,
        title,
        topWeight,
        leftWeight,
        maxWidth,
        maxHeight,
        minWidth,
        notchText
      ) {
        @:WINDOW_BUFFER = 4;
      
        if (leftWeight == empty) leftWeight = 0.5;
        if (topWeight  == empty) topWeight  = 0.5;

        
        if (maxWidth != empty)
          lines = this.refitLines(
            input:lines, 
            maxWidth: (CANVAS_WIDTH - WINDOW_BUFFER) * maxWidth
          );
      

        
        @width = if (title!=empty) (title->length + 2) else 0;

        if (minWidth != empty) ::<= {
          
          if (width < minWidth)
            width = minWidth;
        }
        
            
        foreach(lines) ::(k, v) {
          if (v->length > width)
            width = v->length;
        }
        
        @left   = ((this.width - (width+WINDOW_BUFFER))*leftWeight)->floor;
        width   = width + WINDOW_BUFFER;
        @top  = ((this.height - (lines->keycount + WINDOW_BUFFER)) * topWeight)->floor;
        @height = lines->keycount + WINDOW_BUFFER;
        
        if (top < 0) top = 0;
        if (left < 0) left = 0;
        
        
        this.renderFrame(top, left, width, height);

        // render text:
        
        foreach(lines)::(index, line) {
          this.movePen(x: left+2, y: top+2+index);
          this.drawText(text:line);
        }

        if (title != empty && title != '') ::<= {
          this.movePen(x: left+2, y:top);
          this.drawText(text:'['+title+']');
        }

        if (notchText != empty) ::<= {
          this.movePen(x: left+width-2-(notchText->length), y:top+height-1);
          this.drawText(text:notchText);
        }        
        
        
        return {
          left : left,
          top : top,
          width : width,
          height: height
        }
      },
            
      drawText ::(text => String) {
        when (penx < 0 || penx >= CANVAS_WIDTH || peny < 0 || peny >= CANVAS_HEIGHT) empty;        
        for(penx, penx+min(a:text->length, b:CANVAS_WIDTH-penx))::(i) {
          @ch = text->charAt(index:i-penx);
          if (ch == '\n') ch = ' ';
          currentFrame[i+peny*CANVAS_WIDTH] = ch;
        }
      },
      
      drawChar ::(text => String) {  
        when (penx < 0 || penx >= CANVAS_WIDTH || peny < 0 || peny >= CANVAS_HEIGHT) empty;        
        if (text == '\n') text = ' ';
        currentFrame[penx+peny*CANVAS_WIDTH] = text->charAt(index:0);         
      },
      
      drawRectangle ::(text => String, width => Number, height => Number) {
        @ch = text->charAt(index:0);
        for(0, height)::(y) {
          @offsety = peny + y;
          for(0, width)::(x) {
            currentFrame[penx+x + (offsety)*CANVAS_WIDTH] = ch
          }
        }
      },
      
      /*
      // not needed yet, but for when it is:
      drawAroundRectangle ::(text => String, width => Number, height => Number) {
        @ch = text->charAt(index:0);
        for(0, CANVAS_HEIGHT)::(y) {
          for(0, CANVAS_WIDTH)::(x) {
            when(y >= peny && y <= (peny + height) &&
                 x >= penx && x <= (penx + width)) empty;
            currentFrame[x + (y)*CANVAS_WIDTH] = ch
          }
        }      
      },
      */
      
      erase :: {
        currentFrame[penx+peny*CANVAS_WIDTH] = 0;
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
      clear :: {
        for(0, CANVAS_HEIGHT * CANVAS_WIDTH) ::(i) {
          currentFrame[i] = 0;
        }
      },
      
      fill ::(with){
        if (with == empty) with = ' ';
        for(0, CANVAS_HEIGHT * CANVAS_WIDTH) ::(i) {
          currentFrame[i] = with;
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
      



      // creates a new frame and returns its ID
      newFramebuffer ::{
        @id = if (idStatePool_dead->size) 
            idStatePool_dead->pop 
          else ::<= {
            idStatePool += 1;
            return idStatePool;
          }
        @:frame = {
          textArray : ::<= {
            @:arr = [];
            for(0, CANVAS_HEIGHT * CANVAS_WIDTH) ::(i) {
              arr[i] = 0;            
            }
            return arr;
          },
          id : id
        }        
        frames[id] = frame;
        return id;
      },
      
      renderToFramebuffer ::(id => Number, render => Function) {
        if (frames[id] == empty) 
          error(:'No such frame ' + id);
        @:lastFrame = currentFrame;
        currentFrame = frames[id].textArray;
        render();
        currentFrame = lastFrame;
      },
      
      printFramebuffer ::(id => Number) {
        for(0, CANVAS_HEIGHT)::(row) {
          print(:String.combine(strings:frames[id].textArray->subset(from:row*CANVAS_WIDTH, to:(row+1)*CANVAS_WIDTH-1)));
        }        
      },

      removeFramebuffer ::(id) {
        @w = frames[id]
        if (w == empty)
          error(detail:'Tried to removeFramebuffer() on something that isnt a framebuffer!');

        idStatePool_dead->push(value:id);
        frames[id] = empty;
      },

      
      // Adds an effect to be called after rendering the current 
      // window visual. Note that when effects are active, the 
      // window will be rerendered every frame. So performance is a factor
      //
      // When the effect is done, it should 
      addEffect ::(effect => Function) {  
        when(showEffects == false) empty;
        effects[effect] = true;
      },
      
      showEffects : {
        get ::<- showEffects,
        set ::(value => Boolean) <- showEffects = value
      },
      
      hasEffects ::<- effects->keycount > 0,
      
      // defines the set that will be rendered
      setFramebufferList ::(ids) {
        currentSet = ids->map(::(value) <- 
          if (frames[value] == empty) 
            error(:'Unknown framebuffer ' + value) 
          else 
            frames[value]
        );
      },

      
      update ::{
        when(effects->keycount == 0) empty;  
        composite();
        // draw effects on real canvas after compositing
        ::<= {
          @:oldFrame = currentFrame;
          currentFrame = canvas;
          foreach(effects) ::(effect, k) {
            @:ret = effect();
            if (ret == EFFECT_FINISHED) 
              effects->remove(:effect);
          }    
          currentFrame = oldFrame
        } 
        pushToScreen();
      },
        
      commit ::(renderNow) {
        when(effects->keycount > 0 && (renderNow != true)) empty;
        composite();
        pushToScreen(renderNow);       
      }
    }  
  }
).new();
