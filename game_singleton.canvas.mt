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
  a.pushState = getExternalFunction(:'wyvern_gate__native__canvas__pushState');
  a.removeState = getExternalFunction(:'wyvern_gate__native__canvas__removeState');
  a.drawText = getExternalFunction(:'wyvern_gate__native__canvas__drawText');
  a.drawChar = getExternalFunction(:'wyvern_gate__native__canvas__drawChar');
  a.drawRectangle = getExternalFunction(:'wyvern_gate__native__canvas__drawRectangle');
  a.erase = getExternalFunction(:'wyvern_gate__native__canvas__erase');
  a.writeText = getExternalFunction(:'wyvern_gate__native__canvas__writeText');
  a.clear = getExternalFunction(:'wyvern_gate__native__canvas__clear');
  a.blackout = getExternalFunction(:'wyvern_gate__native__canvas__blackout');
  a.columnsToLines = getExternalFunction(:'wyvern_gate__native__canvas__columnsToLines');
  a.addEffect = getExternalFunction(:'wyvern_gate__native__canvas__addEffect');
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
    @:lines_output = [];
    
    @savestates = [];
    @idStatePool = 0;
    @idStatePool_dead = [];
    @effects = [];
    @counter = 0;
    @showEffects = true;
    
    
    

    
    this.interface = {
      reset ::{
        savestates = [];
        idStatePool = 0;
        idStatePool_dead = [];
      },
    
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

      
      renderBarAsString ::(width, fillFraction, character) {
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
            this.erase();    
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

      removeState ::(id) {
        @w = savestates->filter(by::(value) <- value.id == id);
        if (w->size != 1)
          error(detail:'Tried to removeState() on something that isnt a state!');

        idStatePool_dead->push(value:w[0].id);
        savestates->remove(key:savestates->findIndex(value:w[0]));
        this.clear();
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
      clear :: {
        when (savestates->keycount) ::<= {
          @prevCanvas = savestates[savestates->keycount-1].text;
          canvas = [...prevCanvas];
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
        breakpoint();

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
      
      
      /*
      refitCanvas ::{
        @:console = import(:'Matte.System.ConsoleIO');
        console.put(:"\x1b[999;999H");
        console.put(:"\x1b[6n");
        @w;
        @h;


        ::? {
          forever ::{
            @ch = console.getch(unbuffered:true);
            if (ch != empty) send();
          }
        }

        ::? {
          @target = '';
          @ch = console.getch(unbuffered:true);

          forever ::{
            @ch = console.getch(unbuffered:true);
            //console.println(:"ch: " + ch);
            when(ch == empty) send();
            when (ch == 'R') ::<= {
              w = target;
              send();
            }
            when (ch == ';') ::<= {
              h = target;
              target = '';
            }
            target = target + ch;
          }
        }
        
        console.clear();
        when(w == empty || h == empty) empty;
        
        w = Number.parse(:w);
        h = ((Number.parse(:h) / 2)->floor)*2 -2;

        this.resize(width:w, height:h);
      },  
      */  

      
      // Adds an effect to be called after rendering the current 
      // window visual. Note that when effects are active, the 
      // window will be rerendered every frame. So performance is a factor
      //
      // When the effect is done, it should 
      addEffect ::(effect => Function) {  
        breakpoint();
        when(showEffects == false) empty;
        effects[effect] = true;
      },
      
      showEffects : {
        get ::<- showEffects,
        set ::(value => Boolean) <- showEffects = value
      },
      
      update ::{
        when(effects->keycount == 0) empty;        
        foreach(effects) ::(effect, k) {
          @:ret = effect();
          if (ret == EFFECT_FINISHED) 
            effects->remove(:effect);
        }     

        for(0, CANVAS_HEIGHT)::(row) {
          lines_output[row] = String.combine(strings:canvas->subset(from:row*CANVAS_WIDTH, to:(row+1)*CANVAS_WIDTH-1));
        }
        onCommit(
          lines:lines_output
        ); 
      },
        
      commit ::(renderNow) {
        when(effects->keycount > 0 && (renderNow != true)) empty;

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
