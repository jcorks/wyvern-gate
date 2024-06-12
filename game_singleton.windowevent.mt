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
@:FRAME_COUNT_RENDER_TEXT = 3;

@:renderTextSingle::(leftWeight, topWeight, maxWidth, maxHeight, lines, speaker, hasNotch) {
    canvas.renderTextFrameGeneral(
      leftWeight, 
      topWeight, 
      maxHeight,
      maxWidth,
      lines:lines, 
      title:speaker, 
      notchText:if(hasNotch != empty) "(next)" else empty)
}

// Renders a text box using an animation
@:renderText ::(leftWeight, topWeight, maxWidth, maxHeight, lines, speaker, hasNotch) {
  @width = 0;
  @height = lines->size;
  @frames = 0;  
  foreach(lines) ::(index, line) {
    if (width < line->length)
      width = line->length
  }

  @:fillLines ::(amount) {
    @:strings = [];
    for(0, amount) ::(i) {
      strings->push(value:' ');
    }
    return String.combine(strings);
  }

  @:animateLines ::{
    when(frames >= FRAME_COUNT_RENDER_TEXT) lines;
    @:frac = frames / FRAME_COUNT_RENDER_TEXT;
  
    return lines->subset(from:0, to:(lines->size-1)*frac)->map(to:::(value) {
      return fillLines(amount:frac * width);
    });
    
  }
  
  
  @:renderFrame ::{
    
    canvas.renderTextFrameGeneral(
      leftWeight, 
      topWeight, 
      maxWidth,
      maxHeight,
      lines:animateLines(), 
      title:speaker, 
      notchText:if(hasNotch != empty) "(next)" else empty)
    when(frames == FRAME_COUNT_RENDER_TEXT)
      canvas.ANIMATION_FINISHED;
    frames += 1;
  }
  
  canvas.queueAnimation(onRenderFrame:renderFrame);
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


// When dealing with kept commitInput handlers that immediately 
// return, some can get stuck and never give back control.
// This is most common when commitInput handlers are kept but 
// dont actually add any new queued window events.
// Sometimes this is intentional for a few frames, but sometimes 
// it is done erroneously. This limit safely gives control 
// back to the program if too many recursive updates happen in 
// this case
//
// In the future, exceeding this may throw an error just to let 
// the programmer know whats up.
//
@:KEEP_STACK_INPUT_SAFETY_LIMIT = 20;

@:WindowEvent = class(
  name: 'Wyvern.WindowEvent',
  define:::(this) {
    @onInput;
    @isCursor = true;
    @choiceStack = [];
    @resolveQueues = {};
    @:getResolveQueue ::{
      return resolveQueues[resolveQueues->size-1].queue;
    }
    
    @:pushResolveQueueTop ::(fns, setID) {
      return getResolveQueue()->push(:{
        fns : fns,
        setID : setID
      });
    }
    
    
    
    @:removeSetID ::(setID) {
      @:q = getResolveQueue()->filter(::(value) <- value.setID != setID)
      resolveQueues[resolveQueues->size-1].queue = q;
    }

    resolveQueues->push(:{
      onResolveAll : {},
      queue : {}
    });


    @requestAutoSkip = false;
    @autoSkipIndex = empty;

  
    @:choiceStackPush::(value) {
      if (choiceStack->size) ::<= {
        @:val = choiceStack[choiceStack->size-1];
        if (val.stateID == empty) ::<= {
          val.stateID = canvas.pushState();    
        }
      }
      choiceStack->push(value);
    }
  
    @:renderThis ::(data => Object, thisRender) {
      when (requestAutoSkip) empty; 
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
    
    @:renderThisAnimation ::(data => Object, frame) {
      when (requestAutoSkip) empty; 

      canvas.queueAnimation(onRenderFrame::{
        canvas.clear();
        if (data.renderable)
          data.renderable.render()

        return frame();
      });
      
      data.rendered = true;      
    }    
    
    
    @next ::(toRemove, dontResolveNext, level) {
      @kept;
      if (choiceStack->keycount > 0) ::<= {
        @:data = if (toRemove == empty) choiceStack[choiceStack->size-1] else toRemove;
        if (data.keep) ::<= {
          kept = true;
        } else ::<= {
          if (toRemove == empty) 
            choiceStack->pop 
          else 
            choiceStack->remove(key:choiceStack->findIndex(value:toRemove));

          if (!requestAutoSkip) ::<= {
            if (data.stateID != empty)
              canvas.removeState(id:data.stateID);
          }
          
          if (data.onLeave)
            data.onLeave();
          if (choiceStack->keycount > 0)
            choiceStack[choiceStack->keycount-1].rendered = empty;
        }
      }
      if (dontResolveNext == empty && ((level == empty) || (level < KEEP_STACK_INPUT_SAFETY_LIMIT))) ::<= {
        resolveNext(level);
      }
    }
    
    @:commitInput ::(input, level) {
    
      @continue; 
      @val;
      if (choiceStack->keycount > 0) ::<= {
        val = choiceStack[choiceStack->keycount-1];
          
        if (val.stateID != empty) ::<= {
          canvas.removeState(id:val.stateID);
          val.stateID = empty;
        }
          
        //if (val.jail == true) ::<= {
        //  choiceStack->push(value:val);
        //}
        continue = match(val.mode) {
          (CHOICE_MODE.CURSOR):         commitInput_cursor(data:val, input),
          (CHOICE_MODE.COLUMN_CURSOR):  commitInput_columnCursor(data:val, input),
          (CHOICE_MODE.DISPLAY):        commitInput_display(data:val, input),
          (CHOICE_MODE.CURSOR_MOVE):    commitInput_cursorMove(data:val, input),
          (CHOICE_MODE.CUSTOM):         commitInput_custom(data:val, input),
          (CHOICE_MODE.SLIDER):         commitInput_slider(data:val, input)
        }    
        
        // event callbacks mightve bonked out 
        // this current val. Double check 
        if (choiceStack->findIndex(value:val) == -1) ::<= {
          continue = false;
          resolveNext(noCommit:true);
        }
      }
      // true means done
      if (continue == true || choiceStack->keycount == 0) ::<= {
        next(toRemove:val, level:if (level == empty) 0 else level);
      }
    }


    // resolves the next action 
    // this is normally done for you, but
    // when jumping, sometimes it is required.
    @:resolveNext::(noCommit, level) {
      @inst = resolveQueues[resolveQueues->size-1];
      @:queue = inst.queue;
      @:onResolveAll = inst.onResolveAll;

      if (queue->keycount) ::<= {
        @:cbs = queue[0].fns;
        queue->remove(key:0);
        foreach(cbs)::(i, cb) <- cb();
      } else ::<= {
        if (onResolveAll->size > 0) ::<= {
          @:p = onResolveAll[0];
          onResolveAll->remove(:0);
          p();
          resolveNext();
        }
      }
      if (noCommit == empty)
        commitInput(level);
    }


    @:commitInput_cursor ::(data => Object, input) {
      @choice = input;
      @:canCancel = data.canCancel;
      @:prompt = data.prompt; 
      @:leftWeight = data.leftWeight; 
      @:topWeight = data.topWeight; 
      @:maxWidth = data.maxWidth;
      @:maxHeight = data.maxHeight;
      @:defaultChoice = data.defaultChoice;
      @:onChoice = data.onChoice;
      @:onHover = data.onHover;
      @:pageAfter = data.pageAfter;
      @:header = if (data.onGetHeader) data.onGetHeader() else data.header;
      @cursorPos = if (defaultChoice == empty) 0 else defaultChoice-1;

      when (requestAutoSkip) false;

      //if (canCancel) ::<= {
      //  choicesModified->push(value:'(Cancel)');
      //}
      @exitEmpty = false;

      
      
      if (data.rendered == empty || choice != empty) ::<= {
        @:choices = if (data.onGetChoices) data.onGetChoices() else data.choices;
        // no choices
        when(choices == empty || choices->keycount == 0) exitEmpty = true;
        


        @:PAGE_SIZE = if (pageAfter == empty) 7 else pageAfter;   
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

        if (cursorPos < 0) cursorPos = choices->keycount-1;
        if (cursorPos >= choices->keycount) cursorPos = 0;

        //if (cursorPos >= cursorPageTop+PAGE_SIZE) cursorPageTop+=1;
        //if (cursorPos  < cursorPageTop) cursorPageTop -=1;
        cursorPageTop = cursorPos - (PAGE_SIZE/2)->floor;

        if (cursorPageTop > choices->keycount - PAGE_SIZE) cursorPageTop = choices->keycount-PAGE_SIZE;
        if (cursorPageTop < 0) cursorPageTop = 0;
        
        @:choicesModified = if (data.choicesModified == empty) ::<= {
          data.choicesModified = [];
          return data.choicesModified; 
        } else data.choicesModified;
        
        choicesModified->setSize(size:0);
        
        
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
            when(data.hideWindow) empty;
            if (data.renderedAlready == empty) ::<= {
              renderText(
                lines: choicesModified,
                speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
                leftWeight,
                topWeight,
                maxWidth,
                maxHeight
              )
              data.renderedAlready = true;
            } else ::<= {
              renderTextSingle(
                lines: choicesModified,
                speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
                leftWeight,
                topWeight,
                maxWidth,
                maxHeight
              )
            }

          }
        );
      }
      when(exitEmpty) ::<= {
        data.keep = empty;
        return true;      
      }
        
      when(choice == CURSOR_ACTIONS.CANCEL && canCancel) ::<= {
        if (data.onCancel) data.onCancel();
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
      @:maxWidth = data.maxWidth;
      @:maxHeight = data.maxHeight;
      @:onChoice = data.onChoice;
      @:onHover = data.onHover;
      @:increments = data.increments;
      @cursorPos = data.defaultValue;

      when (requestAutoSkip) false;

      //if (canCancel) ::<= {
      //  choicesModified->push(value:'(Cancel)');
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
                line = line + '|'
              else
                line = line + ' '
              ;
            }
            line = line + ']'
            if (data.renderedAlready == empty) ::<= {
              data.renderedAlready = true;
              renderText(
                lines: [
                  '',
                  line,
                  ''
                ],
                speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
                leftWeight,
                topWeight,
                maxWidth,
                maxHeight
              );             
            } else ::<= {
              renderTextSingle(
                lines: [
                  '',
                  line,
                  ''
                ],
                speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
                leftWeight,
                topWeight,
                maxWidth,
                maxHeight
              ); 

            }
          }
        );
      }
      when(exitEmpty) ::<= {
        data.keep = empty;
        return true;      
      }
        
      when(choice == CURSOR_ACTIONS.CANCEL && canCancel) ::<= {
        if (data.onCancel) data.onCancel();
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
      @:maxWidth = data.maxWidth;
      @:maxHeight = data.maxHeight;
      @:defaultChoice = data.defaultChoice;
      @:onChoice = data.onChoice;
      @:choice = input;     
      @:onMenu = data.onMenu;      
      @:canCancel = data.canCancel;
      when (requestAutoSkip) false;

      when(choice == CURSOR_ACTIONS.CANCEL && canCancel) ::<= {
        if (data.onCancel) data.onCancel();
        data.keep = empty;
        return true;
      }

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

        if (choice != empty)
          resolveNext();

      }
      
      
      return false;  
    }    
  
    @:commitInput_custom ::(data => Object, input) {
      
      //if (canCancel) ::<= {
      //  choicesModified->push(value:'(Cancel)');
      //}
      
      if (data.rendered == empty) ::<= {
        if (data.isAnimation == true) ::<= {
          data.busy = true;
          renderThisAnimation(data, frame ::{
            @:output = data.animationFrame();
            when(output != canvas.ANIMATION_FINISHED) empty;
            data.busy = false;
            return canvas.ANIMATION_FINISHED;
          });
        } else ::<= {
          renderThis(data);
        }
      }
      if (data.entered == empty) ::<= {
        if (data.onEnter)
          data.onEnter();
        data.entered = true;
      }
      
      if (data.onUpdate)
        data.onUpdate();
      
      if (data.onInput != empty && input != empty)
        data.onInput(input);
      
      when(data.busy) false;
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
      @:maxWidth = data.maxWidth;
      @:maxHeight = data.maxHeight;
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

        if (x < 0) x = width-1;
        if (x >= width) x = 0;
        if (y < 0) y = height-1;
        if (y >= height) y = 0;
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
        if (data.renderedAlready == empty) ::<= {
          data.renderedAlready = true;
          renderText(
            lines: choicesModified,
            speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
            leftWeight,
            topWeight,
            maxWidth,
            maxHeight
          ); 
        } else ::<= {
          renderTextSingle(
            lines: choicesModified,
            speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
            leftWeight,
            topWeight,
            maxWidth,
            maxHeight
          );         
        }
      });      
        
        
      when (choice == CURSOR_ACTIONS.CONFIRM) ::<= {
        onChoice(choice:which + 1);
        return true;
      }
        
      if (canCancel && choice == CURSOR_ACTIONS.CANCEL) ::<= {
        if (data.onCancel) data.onCancel();
        data.keep = empty;
        return true;
      }
      

      return false;
    }
    
    @:commitInput_display ::(data, input) {
      when (requestAutoSkip) true;

    
    
      if (data.rendered == empty) ::<= {
        when(data.skipAnimation) ::<= {
          data.busy = false;
          renderThis(data, thisRender::{
            renderTextSingle(
              leftWeight: data.leftWeight, 
              topWeight: data.topWeight, 
              maxWidth : data.maxWidth,
              maxHeight : data.maxHeight,
              lines: data.lines,
              speaker:if (data.onGetPrompt == empty) data.prompt else data.onGetPrompt(),
              //limitLines : data.pageAfter,
              hasNotch: true
            );     
          })       
        }
      
        data.busy = true;
        ::<= {
        
          @progressCh = 0;
          @progressL = 0;
          @maxlen = 0;
          foreach(data.lines) ::(i, line) {
            if (line->length > maxlen)
              maxlen = line->length;
          }
    
          @:fillLine ::(line, from, to) {
            @:bases = [
              if (to >= line->length-1)
                line 
              else line->substr(from, to)
            ];
            for(bases[0]->length, maxlen) ::(i) {
              bases->push(value:' ');
            }
            return String.combine(strings:bases);
          }

          @:progressLines ::{
            when(progressL >= data.lines->size || data.busy == false) ::<= {
              data.busy = false;
              return data.lines;
            }
            @:out = [];
            for(0, progressL) ::(i) {
              out->push(value:data.lines[i]);
            }
            @:line = data.lines[progressL];
            out->push(value:fillLine(line, from:0, to:progressCh))
            for(progressL+1, data.lines->size) ::(i) {
              out->push(value:'');
            }

            
            if (progressCh > line->length) ::<= {
              progressCh = 0;
              progressL += 1;
            }
            progressCh+=4;

            return out;
          }


          @:nextFrame = ::{
            //canvas.clear();
            renderTextSingle(
              leftWeight: data.leftWeight, 
              topWeight: data.topWeight, 
              maxWidth : data.maxWidth,
              maxHeight : data.maxHeight,
              lines: progressLines(),
              speaker:if (data.onGetPrompt == empty) data.prompt else data.onGetPrompt(),
              //limitLines : data.pageAfter,
              hasNotch: true
            );
            when(data.busy == false) ::<= {
              return canvas.ANIMATION_FINISHED;
            }
          }
                  
          renderThisAnimation(data, 
            frame:nextFrame
          );
        }
      }
      return match(input) {
        (CURSOR_ACTIONS.CONFIRM, 
         CURSOR_ACTIONS.CANCEL): ::<= {
          when (data.busy) ::<= {
            data.busy = false;
            return false;
          } 
          // if queued in a set, remove remaining waiting
          if (input == CURSOR_ACTIONS.CANCEL && data.setID != empty) ::<= {
            removeSetID(:data.setID)
          }
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
      CUSTOM: 6,
      SLIDER : 7
    }
    
    
    
    this.interface = {
      commitInput : commitInput,
      
      RENDER_AGAIN : {
        get ::<- 1
      },
      
      // Similar to message, but accepts a set of 
      // messages to display
      queueMessageSet::(
          speakers, 
          set => Object, 
          leftWeight, 
          topWeight, 
          maxWidth,
          maxHeight,
          pageAfter, 
          onLeave
        ) {
        @:setID = {};
        foreach(set)::(i, text) {
          when(text == '' || text == empty) empty;
          this.queueMessage(
            speaker: speakers[i],
            text,
            leftWeight,
            topWeight,
            maxWidth,
            maxHeight,
            pageAfter,
            onLeave,
            setID
          )
        }
        
      },
      
      // Posts a message to the screen. In the case that a 
      // message overflows, it will be split into multiple dialogs.
      //
      // The function returns when the message is displayed in full
      // to the user.
      queueMessage::(
          speaker, 
          text, 
          leftWeight, 
          topWeight, 
          maxWidth,
          maxHeight,
          pageAfter, 
          renderable, 
          onLeave,
          setID
      ) {
        if (pageAfter == empty) pageAfter = MAX_LINES_TEXTBOX;
        // first: split the text.
        //text = text->replace(keys:['\r'], with: '');
        //text = text->replace(keys:['\t'], with: ' ');
        //text = text->replace(keys:['\n'], with: '\n');
        //@:words = text->split(token:' ');
        

        return this.queueDisplay(
          leftWeight, topWeight,
          maxWidth,
          maxHeight,
          prompt:speaker,
          renderable,
          lines : canvas.refitLines(input:[text]),
          pageAfter,
          onLeave,
          setID
        );        
      },
      
      
      // like message, but tried to fit the text on one page.
      // If it doesnt fit, display will try and make it scrollable.
      //
      // lines should be an array of strings.
      queueDisplay::(
        prompt, lines, 
        pageAfter, 
        leftWeight, 
        topWeight, 
        maxWidth,
        maxHeight,
        renderable, 
        onLeave, 
        skipAnimation,
        setID
      ) {
        when(requestAutoSkip) ::<= {
          if (onLeave) onLeave();
        }

        @:queuePage ::(iter, width, more){
          pushResolveQueueTop(fns:[::{
            @:limit = min(a:iter+pageAfter, b:lines->keycount)-1;
            @:linesOut = lines->subset(
              from:iter, 
              to:limit
            )
            
            // MORE text is never animated.
            if (!(iter == 0 && limit == lines->keycount-1))
              skipAnimation = true;
            
            if (width != empty)
              linesOut->push(value:createBlankLine(width, header:if (more) '-More-' else ''));
            
            choiceStackPush(value:{
              topWeight: topWeight,
              leftWeight : leftWeight,
              maxWidth : maxWidth,
              maxHeight : maxHeight,
              lines : linesOut,
              pageAfter: pageAfter,
              prompt: prompt,
              onLeave: onLeave,
              mode: CHOICE_MODE.DISPLAY,
              renderable: renderable,
              skipAnimation : skipAnimation,
              setID : setID
            });
          }], setID);
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
            
          }
        }
        return getResolveQueue()->size-1;
      },
      
      // An empty action. Can be used to make custom inputs.
      // If consistency is required, keep can be true and use forceExit() 
      // when done with the widget.
      queueCustom::(
        renderable, 
        keep, 
        onEnter, 
        onUpdate, 
        onInput, 
        jumpTag, 
        onLeave, 
        isAnimation, 
        animationFrame
      ) {
        when(requestAutoSkip) ::<= {
          if (onEnter) onEnter();
          if (onLeave) onLeave();
        }

        pushResolveQueueTop(fns:[::{
          choiceStackPush(value:{
            mode: CHOICE_MODE.CUSTOM,
            keep: keep,
            renderable:renderable,
            onEnter:onEnter,
            onUpdate:onUpdate,
            jumpTag: jumpTag,
            onLeave: onLeave,
            isAnimation : isAnimation,
            animationFrame : animationFrame,
            onInput : onInput
          });
        }]);        
        return getResolveQueue()->size-1;
      },
      
      
      


      
      
      // Allows for choosing from a list of options.
      // Like all UI choices, the weight can be chosen.
      // Prompt will be displayed, like speaker in the message callback
      //
      queueChoices::(
        choices, 
        prompt, 
        leftWeight, 
        topWeight, 
        maxWidth,
        maxHeight,        
        canCancel, 
        defaultChoice, 
        onChoice => Function, 
        onHover, 
        renderable, 
        keep, 
        onGetChoices, 
        onGetPrompt, 
        jumpTag, 
        onLeave, 
        header, 
        onGetHeader, 
        onCancel, 
        pageAfter, 
        hideWindow
      ) {
        pushResolveQueueTop(fns:[::{
          choiceStackPush(value:{
            onCancel : onCancel,
            mode: CHOICE_MODE.CURSOR,
            choices: choices,
            prompt: prompt,
            pageAfter: pageAfter,
            leftWeight: leftWeight,
            topWeight: topWeight,
            maxWidth : maxWidth,
            maxHeight : maxHeight,
            canCancel: canCancel,
            defaultChoice: defaultChoice,
            hideWindow : hideWindow,
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
        return getResolveQueue()->size-1;
      },
      
      
      
      
      queueSlider::(
        defaultValue => Number, 
        increments => Number, 
        prompt, 
        leftWeight, 
        topWeight, 
        maxWidth,
        maxHeight,
        canCancel, 
        defaultChoice, 
        onChoice => Function, 
        onHover, 
        renderable, 
        keep, 
        onGetPrompt, 
        jumpTag, 
        onLeave, 
        onCancel
      ) {


        pushResolveQueueTop(fns:[::{
          choiceStackPush(value:{
            onCancel: onCancel,
            mode: CHOICE_MODE.SLIDER,
            increments : increments,
            prompt: prompt,
            leftWeight: leftWeight,
            topWeight: topWeight,
            maxWidth : maxWidth,
            maxHeight : maxHeight,
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
        return getResolveQueue()->size-1;
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
          @:data = choiceStack->pop; 
          if (data.stateID != empty)
            canvas.removeState(id:data.stateID);

          if (data.onLeave)
            data.onLeave();          
        }
        canvas.commit();        
        choiceStack[choiceStack->keycount-1].rendered = empty;
        if (clearResolve) ::<= {
          getResolveQueue()->setSize(:0);
        }
      },
     
      
      queueChoiceColumns::(
        choices, 
        prompt, 
        itemsPerColumn, 
        leftWeight, 
        topWeight, 
        maxWidth,
        maxHeight,
        canCancel, 
        onChoice => Function, 
        keep, 
        renderable, 
        jumpTag, 
        onLeave, 
        onCancel
      ) {
        pushResolveQueueTop(fns:[::{
          choiceStackPush(value:{
            onCancel: onCancel,
            mode:if (isCursor) CHOICE_MODE.COLUMN_CURSOR else CHOICE_MODE.COLUMN_NUMBER,
            choices: choices,
            prompt: prompt,
            jumpTag : jumpTag,
            itemsPerColumn: itemsPerColumn,
            leftWeight : leftWeight,
            topWeight : topWeight,
            maxWidth : maxWidth,
            maxHeight : maxHeight,
            canCancel : canCancel,
            onChoice : onChoice,
            onLeave : onLeave,
            keep : keep,
            renderable:renderable,
          });
        }]);
        return getResolveQueue()->size-1;
      },      
      queueCursorMove ::(
        prompt, 
        leftWeight, 
        topWeight, 
        maxWidth,
        maxHeight,
        onMove, 
        onMenu => Function, 
        renderable, 
        onLeave, 
        jumpTag, 
        canCancel, 
        trap
      ) {
        pushResolveQueueTop(fns:[::{
          choiceStackPush(value:{
            canCancel: canCancel,
            mode: CHOICE_MODE.CURSOR_MOVE,
            prompt: prompt,
            leftWeight: leftWeight,
            topWeight: topWeight,
            maxWidth : maxWidth,
            maxHeight : maxHeight,
            onChoice:onMove,
            onLeave:onLeave,
            renderable:renderable,
            jumpTag: jumpTag,
            trap : trap,
            onMenu : onMenu
          });
          canvas.clear();
        }]);
        return getResolveQueue()->size-1;
      },  
      
      // Adds a resolve queue.
      // when queueing window events, you may optionally 
      // pass a "queueID" pointing to a resolve queue 
      pushResolveQueue:: {
        @:id = {}; // its unique!
        @:out = {
          queue : [],
          onResolveAll : []
        };
        resolveQueues->push(:out);
      },
      
      // Deletes a resolve queue.
      // All queued resolves are lost, so i wouldnt do this 
      // unless youre sure you dont want the queued items here!
      popResolveQueue :: {
        resolveQueues->pop;
        if (resolveQueues->size == 0)
          resolveQueues->push(:{
            onResolveAll : {},
            queue : {}
          });        
      },
            
      
      
      // Pushes through all queued actions to the top 
      // of the window stack in order. This is normally not needed, but 
      // may be needed in particular contexts and effects.
      onResolveAll ::(onDone, doResolveNext) {
        resolveQueues[resolveQueues->size-1].onResolveAll->push(:onDone);
        if (doResolveNext)
          resolveNext();        
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
        return this.queueChoices(prompt, choices:['Yes', 'No'], canCancel:false, onLeave:onLeave, topWeight, leftWeight,
          onChoice::(choice){
            onChoice(which: choice == 1);
          },
          renderable
        );
      },
      
      // returns any resolvable items are left queued.
      hasAnyQueued:: {
        return getResolveQueue()->size != 0;
      }
    }  
  }
).new();

return WindowEvent;

