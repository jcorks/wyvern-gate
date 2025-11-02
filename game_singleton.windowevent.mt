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
@:sound = import(module:'game_singleton.sound.mt');


@:MAX_LINES_TEXTBOX = 10;
@:MAX_COLUMNS = canvas.width - 4;
@:FRAME_COUNT_RENDER_TEXT = 3;
@:CALLBACK_DONE = {};
@:ANIMATION_FINISHED = -1;


@:RENDER_STATE = {
  ANIMATING : 2,
  DONE : 3
};

@:renderTextSingle::(leftWeight, topWeight, maxWidth, maxHeight, lines, speaker, hasNotch, notchText, minWidth) <- 
    canvas.renderTextFrameGeneral(
      leftWeight, 
      topWeight, 
      maxHeight,
      maxWidth,
      lines:lines, 
      title:speaker, 
      minWidth,
      notchText:if(hasNotch != empty) (if (notchText == empty) "(next)" else notchText) else empty)


// Renders a text box using an animation
@:renderTextAnimation ::(leftWeight, topWeight, maxWidth, maxHeight, lines, speaker, hasNotch, notchText) {
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
  
  
  return ::{    
    canvas.renderTextFrameGeneral(
      leftWeight, 
      topWeight, 
      maxWidth,
      maxHeight,
      lines:animateLines(), 
      title:speaker, 
      notchText:if(hasNotch != empty) (if (notchText == empty) "(next)" else notchText) else empty)
      
    when(frames == FRAME_COUNT_RENDER_TEXT)
      ANIMATION_FINISHED;
    frames += 1;
  }  
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
@:KEEP_STACK_INPUT_SAFETY_LIMIT = 100;
@KEEP_STACK_INPUT_SAFETY_LIMIT_REACHED = false;

@:WindowEvent = class(
  name: 'Wyvern.WindowEvent',
  define:::(this) {
    @onInput;
    @isCursor = true;
    @choiceStack = [];
    @resolveQueues = {};
    @requestAutoSkip = false;
    @autoSkipIndex = empty;
    @autoSkipAnimations = false;
    @queuedInputs = [];
    @record;
    @lastRecordFrames;
    @markedError = false;
    @errorHandler;
    @log_;
    @hadInputLast = false;
    
    resolveQueues->push(:{
      onResolveAll : {},
      queue : {}
    });
    
    
    @:commitVisual :: {
      canvas.commit();
    }
      
    // Adds a resolve queue.
    // when queueing window events, you may optionally 
    // pass a "queueID" pointing to a resolve queue 
    @:pushResolveQueue:: {
      @:out = {
        queue : [],
        onResolveAll : []
      };
      resolveQueues->push(:out);
    }
    
    // Deletes a resolve queue.
    // All queued resolves are lost, so i wouldnt do this 
    // unless youre sure you dont want the queued items here!
    @:popResolveQueue :: {
      resolveQueues->pop;
      if (resolveQueues->size == 0)
        resolveQueues->push(:{
          onResolveAll : {},
          queue : {}
        });        
    }    
    
    @:getResolveQueue ::{
      return resolveQueues[resolveQueues->size-1].queue;
    }
    
    @:pushResolveQueueTop ::(fns, setID) {
      hadInputLast = true;
      return getResolveQueue()->push(:{
        fns : fns,
        setID : setID
      });
    }
    
    
    
    @:removeSetID ::(setID) {
      @:q = getResolveQueue()->filter(::(value) <- value.setID != setID)
      resolveQueues[resolveQueues->size-1].queue = q;
    }



  
    @:choiceStackPush::(value) {
      if (choiceStack->size) ::<= {
        @:val = choiceStack[choiceStack->size-1];
        if (val.stateID == empty) ::<= {
          if (::? {
            foreach(choiceStack) ::(k, v) {
              if (v.disableCache)
                send(:false);
            }
            return true;
          })
            val.stateID = canvas.pushState();    
        }
      }
      choiceStack->push(value);
    }
  
  
    /*
      Main rendering path.
      Handles:
        - animations 
        - requestAutoSkip
        - cache disabling
    
      For animations: isAnim
    
    */
    @:renderThis ::(data => Object, renderOnly, rerender) {
      when (requestAutoSkip) empty; 
      when (data.rendered != empty && rerender == empty) empty;

      if (renderOnly == empty && rerender != true)
        canvas.clear();
        
      if (rerender == empty) ::<= {
        @dorender = false;
        
        foreach(choiceStack) ::(k, v) {
          when(v == data) empty;
          if (v.disableCache) ::<= {
            dorender = true;
          }
          if (dorender)
            renderThis(data:v, rerender:true);
        }
      }

      if (autoSkipAnimations)
        data.renderState = RENDER_STATE.DONE;


      // animations prevent continuing by using the renderState flag
      // Once an animation is complete, it defaults to 
      // thisRender once skipped or complete
      if (data.renderState == RENDER_STATE.ANIMATING) ::<= {        

        if (data.renderable)
          data.renderable.render()

        @:output = data.animationFrame();
        if (output == ANIMATION_FINISHED) ::<= {
          data.renderState = RENDER_STATE.DONE;
        }

        commitVisual();
        
      } else ::<= {        

        @renderAgain = false;
        if (data.renderable) ::<= {
          renderAgain = (data.renderable.render()) == this.RENDER_AGAIN;    
        }
        
        if (data.thisRender) ::<= {
          renderAgain = (data.thisRender()) == this.RENDER_AGAIN;    
        }
          
        if (renderOnly == empty && rerender != true)
          commitVisual();

        
        if (renderAgain == false)
          data.rendered = true;

      }
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
            if (data.stateID != empty) ::<= {
              //canvas.removeState(id:data.stateID);
            }
          }
          
          if (data.onLeave)
            data.onLeave();
          if (choiceStack->keycount > 0)
            choiceStack[choiceStack->keycount-1].rendered = empty;
        }
      }

      when ((level != empty) && (level > KEEP_STACK_INPUT_SAFETY_LIMIT)) ::<= {
        if (KEEP_STACK_INPUT_SAFETY_LIMIT_REACHED == false) ::<= {
          KEEP_STACK_INPUT_SAFETY_LIMIT_REACHED = true;
          error(:'An internal threshold was reached (next/resolve queue is possibly empty! recusion level above KEEP_STACK_INPUT_SAFETY_LIMIT). It is safe to continue, but note that this indicates an issue in the program.')
        }
      }

      if (dontResolveNext == empty) ::<= {
        resolveNext(level);
      }
    }
    
    @:queuedInputFetch::(input) {
      when(queuedInputs->size == 0) input;
      @:next = queuedInputs[0];
      when(next.waitFrames > 0) ::<= {
        next.waitFrames-=1;
        return empty;
      }
      queuedInputs->remove(key:0);
      @:out = next.input;
      if (next.callback)
        next.callback();
        
      return out;
    }
    
    @:commitInput ::(input, level, forceRedraw) {
      canvas.update();
      ::? {
        if (input == empty)
          hadInputLast = false
        else
          hadInputLast = true;
        if (record != empty) ::<= {
          if (input != empty) ::<= {
            record->push(:{
              input : input,
              waitFrames : lastRecordFrames
            });
            lastRecordFrames = 0;
          } else ::<= {
            lastRecordFrames += 1;
          }
        }
      
        input = queuedInputFetch(input);
        @continue; 
        @val;
        if (choiceStack->keycount > 0) ::<= {
          val = choiceStack[choiceStack->keycount-1];
            
          if (val.stateID != empty) ::<= {
            canvas.removeState(id:val.stateID);
            val.stateID = empty;
          }
            
          if (forceRedraw == true)
            val.rendered = empty;

          //if (val.jail == true) ::<= {
          //  choiceStack->push(value:val);
          //}
          continue = match(val.mode) {
            (CHOICE_MODE.CURSOR):         commitInput_cursor(data:val, input),
            (CHOICE_MODE.COLUMN_CURSOR):  commitInput_columnCursor(data:val, input),
            (CHOICE_MODE.DISPLAY):        commitInput_display(data:val, input),
            (CHOICE_MODE.CURSOR_MOVE):    commitInput_cursorMove(data:val, input),
            (CHOICE_MODE.CUSTOM):         commitInput_custom(data:val, input),
            (CHOICE_MODE.SLIDER):         commitInput_slider(data:val, input),
            (CHOICE_MODE.CALLBACK):       commitInput_callback(data:val, input),
            (CHOICE_MODE.READER):         commitInput_reader(data:val, input)
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
      } => {
        onError ::(message) {
          if (errorHandler) errorHandler(:message);
        
          if (markedError == false) ::<= {
            markedError = true;
            this.queueReader(
              lines : [
                'Unfortunately due to the Unexpected, an Error has Occurred.',
                '',
                ...message.summary->split(token:'\n'),
                '',
                'This and additional errors will be within the error log of your system.'
              ]
            );
            if (canResolveNext())
              resolveNext();
          }
        }
      }
    }


    // resolves the next action 
    // this is normally done for you, but
    // when jumping, sometimes it is required.
    @:resolveNext::(noCommit, level) {
      @inst = resolveQueues[resolveQueues->size-1];
      @:queue = inst.queue;
      @:onResolveAll = inst.onResolveAll;

      if (level->type == Number) level += 1;

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
    
    @:canResolveNext:: <- resolveQueues[resolveQueues->size-1].queue->size;


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
      @:onGetFooter = data.onGetFooter;
      @header = data.header;
      @cursorPos = if (defaultChoice == empty) 0 else defaultChoice-1;

      when (requestAutoSkip) false;
      

      //if (canCancel) ::<= {
      //  choicesModified->push(value:'(Cancel)');
      //}
      @exitEmpty = false;

      if (data.onInput != empty && input != empty) 
        data.onInput(:input);
      
      
      if (choice != empty || data.rendered == empty) ::<= {
        @:choices = if (data.onGetChoices) data.onGetChoices() else data.choices;
        if (data.onGetHeader) 
          header = data.onGetHeader();
          
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

          if (data.onGetMinWidth != empty) ::<= {
            @min = data.onGetMinWidth();
            if (max < min) max = min;
          }
          return max;
        }

        @padCombine = [];
        @:pad::(text) {
          if (text == empty) text = "";
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

        if (data.horizontalFlow) ::<= {
          if (choice == CURSOR_ACTIONS.LEFT) ::<= {
            cursorPos -= 1;
          }
          if(choice == CURSOR_ACTIONS.RIGHT) ::<= {
            cursorPos += 1;
          }
        
        } else ::<= {
          if (choice == CURSOR_ACTIONS.UP) ::<= {
            cursorPos -= 1;
          }
          if(choice == CURSOR_ACTIONS.DOWN) ::<= {
            cursorPos += 1;
          }
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

          @count = choices->size;
          if (data.onGetMinHeight != empty) ::<= {
            @:out = data.onGetMinHeight();
            if (count < out)
              count = out;
          }


          for(0, count)::(index) {
            choicesModified->push(value: 
              (if (cursorPos == index) '-{ ' else '   ') + 
              pad(text:choices[index]) + 
              (if (cursorPos == index) ' }-' else '   ')
            );
          }
        }
        
        
        
        
        @:affectsChoice = if (data.horizontalFlow)
          choice == CURSOR_ACTIONS.LEFT ||
          choice == CURSOR_ACTIONS.RIGHT        
        else 
          choice == CURSOR_ACTIONS.UP ||
          choice == CURSOR_ACTIONS.DOWN        
        ;

        if (affectsChoice) ::<= {
          sound.playSFX(:"cursor");
          data.defaultChoice = (cursorPos+1);
        }
        
        if (onHover != empty)
          onHover(choice:cursorPos+1);
        
        
        if (data.hideWindow != true) ::<= {
          if (data.animationFrame == empty) ::<= {
            data.renderState = RENDER_STATE.ANIMATING;
            data.animationFrame = renderTextAnimation(
              lines: choicesModified,
              speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
              leftWeight,
              topWeight,
              maxWidth,
              maxHeight,
              hasNotch : if (onGetFooter == empty) empty else true,
              notchText : if (onGetFooter == empty) empty else onGetFooter() 
            )
          }      

          // TODO better efficiency
          data.thisRender = ::{
            renderTextSingle(
              lines: choicesModified,
              speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
              leftWeight,
              topWeight,
              maxWidth,
              maxHeight,
              hasNotch : if (onGetFooter == empty) empty else true,
              notchText : if (onGetFooter == empty) empty else onGetFooter() 
            )
          }
        }
        data.rendered = empty;
        renderThis(data);
      }


      when(exitEmpty) ::<= {
        data.keep = empty;
        return true;      
      }
        
      when(choice == CURSOR_ACTIONS.CANCEL && canCancel) ::<= { 
        sound.playSFX(:"cancel");
        @res;
        if (data.onCancel) 
          res = data.onCancel();
        when (res == this.STOP_CANCEL) false;
        
        data.keep = empty;
        return true;
      }
      
      when(choice == CURSOR_ACTIONS.CONFIRM) ::<= {
        onChoice(choice:cursorPos + 1);
        sound.playSFX(:"confirm");
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

        @line = '[';
        for(0, 50) ::(i) {
          if ((cursorPos * 50)->floor == i)
            line = line + '|'
          else
            line = line + ' '
          ;
        }
        line = line + ']'

        
        if (data.animationFrame == empty) ::<= {
          data.renderState = RENDER_STATE.ANIMATING
          data.animationFrame = ::<={
            return renderTextAnimation(
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

          
        data.thisRender = ::{
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
        data.rendered = empty;

        renderThis(
          data
          
        );
      }
      when(exitEmpty) ::<= {
        data.keep = empty;
        return true;      
      }
        
      when(choice == CURSOR_ACTIONS.CANCEL && canCancel) ::<= {
        sound.playSFX(:"cancel");
        @res;
        if (data.onCancel) 
          res = data.onCancel();
        when (res == this.STOP_CANCEL) false;
        data.keep = empty;
        return true;
      }
      
      when(choice == CURSOR_ACTIONS.CONFIRM) ::<= {
        onChoice(fraction:cursorPos);
        sound.playSFX(:"confirm");
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
      
      when(canResolveNext()) ::<= {
        resolveNext();
        return false;
      }

      when(choice == CURSOR_ACTIONS.CANCEL && canCancel) ::<= {
        @res;
        if (data.onCancel) 
          res = data.onCancel();
        when (res == this.STOP_CANCEL) false;
        data.keep = empty;
        return true;
      }

      when(choice == CURSOR_ACTIONS.CANCEL ||
         choice == CURSOR_ACTIONS.CONFIRM) ::<= {
        sound.playSFX(:"confirm");
        onMenu();
        //resolveNext();
        return false;
      }       

      if (  choice == CURSOR_ACTIONS.UP||
          choice == CURSOR_ACTIONS.DOWN ||
          choice == CURSOR_ACTIONS.LEFT ||
          choice == CURSOR_ACTIONS.RIGHT ||
          data.rendered == empty) ::<= {
        
        data.rendered = empty;
        if (choice != empty) ::<= {
          onChoice(choice);
        }
        

        //if (choice != empty)
          //resolveNext();
      }
      
      if (data.rendered == empty) ::<= {
          renderThis(data);
      }      
      
      return false;  
    }    
  
    @:commitInput_custom ::(data => Object, input) {

      //if (canCancel) ::<= {
      //  choicesModified->push(value:'(Cancel)');
      //}
      if (data.isAnimation && data.renderState == empty)
        data.renderState = RENDER_STATE.ANIMATING;
      
      if (data.rendered == empty) ::<= {
        renderThis(data);
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

      when(data.waitFrames != empty && data.waitFrames > 0) ::<= {
        data.waitFrames -= 1;
        return false;
      }

   
      when(data.resolveStack == true) ::<= {
        when(canResolveNext()) ::<= {
          resolveNext();
          return false;
        }        
        return true;
      }
      
      when(data.renderState == RENDER_STATE.ANIMATING) false;
      
      return true;  
    }
    
    
    @:commitInput_callback ::(data => Object, input) {
      
      //if (canCancel) ::<= {
      //  choicesModified->push(value:'(Cancel)');
      //}
      
      if (data.rendered == empty) ::<= {
        renderThis(data);
      }
      if (data.entered == empty) ::<= {
        data.entered = true;
      }
      
      @:ret = data.callback() == WindowEvent.CALLBACK_DONE
      return ret;
    }     
    
  
  
    @:commitInput_columnCursor ::(data => Object, input) {
    
      @:choices = if (data.onGetChoices) data.onGetChoices() else data.choices;
      // no choices
      when(choices == empty || choices->keycount == 0) true;
      
      
      when(input == empty && data.rendered != empty) false;
      @choice = input;           

      when (requestAutoSkip) false;
      data.rendered = empty;
      
      @:prompt = data.prompt;
      @:itemsPerRow = data.itemsPerRow;
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
      
      @:columns = [[]];
      @:columnWidth = [0];

      @height;
      @width;
      @which;
      foreach(choices)::(index, choice) {
        @:column = index % itemsPerRow;
        if (columns[column] == empty) ::<= {
          columns[column] = [];
          columnWidth->push(value:0);
        }
          
        @entry = ('  ') + choice;

        if (columns[column]->keycount == y && column == x) which = index;
        
        columns[column]->push(value:entry);

        if (entry->length > columnWidth[column])
          columnWidth[column] = entry->length;
        
      }
      width = columnWidth->keycount;
      height = columns[0]->size;
      
      
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

        sound.playSFX(:"cursor");


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
      for(0, height)::(i) {
        @choice = '';
        foreach(columns)::(index, text) {
          if (text[i] != empty) ::<= {
            choice = choice + text[i];
            
            for(text[i]->length, columnWidth[index])::(n) {
              choice = choice + ' ';
            }
            choice = choice + '   ';
          }
          
        }
        choicesModified->push(value:choice);
      }
      
      if (onHover != empty)
        onHover(choice:which+1);


      if (data.animationFrame == empty) ::<= {
        data.renderState = RENDER_STATE.ANIMATING;
        data.animationFrame = renderTextAnimation(
          lines: choicesModified,
          speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
          leftWeight,
          topWeight,
          maxWidth,
          maxHeight
        ); 


      }

      data.thisRender = ::{
        renderTextSingle(
          lines: choicesModified,
          speaker: if (data.onGetPrompt == empty) prompt else data.onGetPrompt(),
          leftWeight,
          topWeight,
          maxWidth,
          maxHeight
        );         
      }
        
        
      when (choice == CURSOR_ACTIONS.CONFIRM) ::<= {
        sound.playSFX(:"confirm");
        onChoice(choice:which + 1);
        renderThis(data);      
        return true;
      }
        
      when (canCancel && choice == CURSOR_ACTIONS.CANCEL) ::<= {
        sound.playSFX(:"cancel");
        @res;
        if (data.onCancel) 
          res = data.onCancel();
        when (res == this.STOP_CANCEL) false;
        data.keep = empty;
        renderThis(data);      
        return true;
      }
      
      renderThis(data);      

      return false;
    }
    
    @:commitInput_display_emitter = import(:'game_class.particle.mt').new(
      directionMin : -135,
      directionMax : -45,

      directionDeltaMin : -1,
      directionDeltaMax : 2,
  
      speedMin : 0.3,
      speedMax : 1,
      
      speedDeltaMin : 0.03,
      speedDeltaMax : 0.05,

      characters : ['▓', '▓', '▒', '░', '▒', '░', '░'],
      charactersRepeat : false,
      
      lifeMax : 7,
      lifeMin : 1    
    );    
    @:commitInput_display ::(data, input) {
      when (requestAutoSkip) true;

    

      if (data.animationFrame == empty) ::<= {
      
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
          when(progressL >= data.lines->size) ::<= {
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
      
        data.animationFrame = ::{

          @:location = renderTextSingle(
            leftWeight: data.leftWeight, 
            topWeight: data.topWeight, 
            maxWidth : data.maxWidth,
            maxHeight : data.maxHeight,
            lines: progressLines(),
            speaker:if (data.onGetPrompt == empty) data.prompt else data.onGetPrompt(),
            //limitLines : data.pageAfter,
            hasNotch: true
          );
          for(0, 4) ::(i) {
            commitInput_display_emitter.move(
              x: location.left + 2 + progressCh + i,
              y: location.top  + 2 + progressL + 1
            );
            commitInput_display_emitter.emit();
          }
            
            


          when(progressL >= data.lines->size) ::<= {
            commitInput_display_emitter.stop();
            return ANIMATION_FINISHED;
          }

        }
        
        
        data.thisRender = ::{

        
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
        }
        if (data.skipAnimation != true)
          data.renderState = RENDER_STATE.ANIMATING;
      }

      renderThis(data);
      
      if (data.autoSkipAfterFrames->type == Number) ::<= {
        data.autoSkipAfterFrames -= 1;
      }
      
      when(data.autoSkipAfterFrames->type == Number && data.autoSkipAfterFrames <= 0) ::<= {
        return true;
      }      
      
      return match(input) {
        (CURSOR_ACTIONS.CONFIRM, 
         CURSOR_ACTIONS.CANCEL): ::<= {
          when (data.renderState == RENDER_STATE.ANIMATING) ::<= {
            commitInput_display_emitter.stop();
            data.renderState = RENDER_STATE.DONE;
            return false;
          } 

          sound.playSFX(:if (input == CURSOR_ACTIONS.CONFIRM) "confirm" else "cancel");

          // if queued in a set, remove remaining waiting
          if (input == CURSOR_ACTIONS.CANCEL && data.setID != empty) ::<= {
            removeSetID(:data.setID)
          }
          return true;
        },
        default: false
      }
    }


    @:commitInput_reader ::(data, input) {
      when (requestAutoSkip) true;

      if (data.iter == empty)
        data.iter = 0;
        
      ::<= {
        @w = 0;
        foreach(data.lines) ::(k, line) <- if (w < line->length) w = line->length;
        if (data.maxWidth == empty)
          data.maxWidth = w;
        data.minWidth = w;
      }
      
      if (data.startAtBottom != empty) ::<= {
        data.iter = data.lines->size - data.maxHeight - 1;
        data.rendered = empty;
        data.startAtBottom = empty;
        if (data.iter < 0) data.iter = 0;
      }

      if(input == CURSOR_ACTIONS.UP||
         input == CURSOR_ACTIONS.DOWN) ::<= {
          
        if (input == CURSOR_ACTIONS.UP)
          data.iter -= 1;

        if (input == CURSOR_ACTIONS.DOWN)
          data.iter += 1;
          
          
        if (data.iter > data.lines->size - data.maxHeight - 1) data.iter = data.lines->size - data.maxHeight - 1;
        if (data.iter < 0) data.iter = 0;
        data.rendered = empty;
      }   
      
      data.thisRender = ::{
        @:fraction = (data.iter / (data.lines->size - data.maxHeight - 1));
        
        @:end = if (data.iter+data.maxHeight >= data.lines->size) 
          data.lines->size-1 
        else
          data.iter+data.maxHeight
          
          
        @:info = renderTextSingle(
          leftWeight: data.leftWeight, 
          topWeight: data.topWeight, 
          maxWidth : data.maxWidth,
          maxHeight : data.maxHeight,
          minWidth : data.minWidth,
          lines: data.lines->subset(from:data.iter, to:end),
          speaker:if (data.onGetPrompt == empty) data.prompt else data.onGetPrompt(),
          hasNotch: true,
          notchText : 'Scroll ' + ((fraction*100)->round) + '%' + 
            (if (fraction != 1) '[v]' else '') + 
            (if (fraction != 0) '[^]' else '')
          
          //limitLines : data.pageAfter,
        );
        
        // showing the full thing.
        when (data.iter == 0 && end == data.lines->size-1) empty;

        // render scrollbar
        @space = info.height - 4;
        @scrollHeight = ((data.maxHeight / data.lines->size) * space)->floor;
        @scrollStart = 
          (space - scrollHeight) *                     // total space available
          fraction
        ;

        @endX = info.left+info.width-1;

        
        for(0, space->round) ::(i) {
          canvas.movePen(x:endX, y:i+2);
          canvas.drawChar(text: '░');
        }

        for(scrollStart->round, (scrollStart + scrollHeight)->round) ::(i) {
          canvas.movePen(x:endX, y:i+2);
          canvas.drawChar(text: '▓');
        }

      }
      

      renderThis(data);
      
      return match(input) {
        (CURSOR_ACTIONS.CONFIRM, 
         CURSOR_ACTIONS.CANCEL): ::<= {
          when (data.renderState == RENDER_STATE.ANIMATING) ::<= {
            data.renderState = RENDER_STATE.DONE;
            return false;
          } 

          sound.playSFX(:if (input == CURSOR_ACTIONS.CONFIRM) "confirm" else "cancel");

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
      SLIDER : 7,
      CALLBACK : 8
    }
    
    
    
    this.interface = {
      commitInput : commitInput,
      
      ANIMATION_FINISHED : {
        get ::<- ANIMATION_FINISHED
      },
      
      RENDER_AGAIN : {
        get ::<- 1
      },
      
      STOP_CANCEL : {
        get ::<- -1
      },
      
      clearAll ::(onReady){
        breakpoint();
        onInput = empty;
        isCursor = true;
        choiceStack = [];
        resolveQueues = {};
        requestAutoSkip = false;
        autoSkipIndex = empty;      
        resolveQueues->push(:{
          onResolveAll : {},
          queue : {}
        });

        onReady();

        /*
        @:pushMainArena = ::{
          breakpoint();
          this.queueNestedResolve(
            onEnter ::{
              onReady();
            }, 
            onUpdate ::{
              breakpoint();
            }, 
            onLeave ::{
              breakpoint();
              this.queueMessage(
                text: 'If you are seeing this message, hi! You have encountered a bug! This message appears when no windowevent action is active. This should never happen under normal circumstances, as the player would not be able to progress. Tell the developer of the mod or the base game!'
              );
              
              pushMainArena();
            }
          )
        }
        
        pushMainArena();
        */
      },
      
      startRecordLog :: {
        log_ = [];
      },

      stopRecordLog :: {
        log_ = empty;
      },
      
      log : {
        get ::<- log_
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
          onLeave,
          autoSkipAfterFrames
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
            setID,
            autoSkipAfterFrames
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
          setID,
          autoSkipAfterFrames
      ) {
        if (pageAfter == empty) pageAfter = MAX_LINES_TEXTBOX;
        // first: split the text.
        //text = text->replace(keys:['\r'], with: '');
        //text = text->replace(keys:['\t'], with: ' ');
        //text = text->replace(keys:['\n'], with: '\n');
        //@:words = text->split(token:' ');

          if (log_) ::<= {
            log_->push(:'[]  '+text);
            /*
            @:st = [];
            foreach(data.lines) ::(k, l) {
              st->push(:l);
              st->push(:'\n');
            }
            
            record->push(:'--'+String.combine(:st));
            */
          }
        

        this.queueDisplay(
          leftWeight, topWeight,
          maxWidth,
          maxHeight,
          prompt:speaker,
          renderable,
          lines : canvas.refitLines(input:[text]),
          pageAfter,
          onLeave,
          setID,
          autoSkipAfterFrames
        );        
      },

      // Lets the user read a long set of text
      // split into pages
      queueReader::(
        prompt, 
        lines, 
        // if true, will split text into pages and 
        // disable normal scrolling.
        hasPages, 
        startAtBottom,

        maxWidth,
        maxHeight,
        onLeave
      ) {
        if (maxHeight == empty) ::<= {
          maxHeight = canvas.height-5;
        }
        if (maxHeight >= lines->size) maxHeight = lines->size;

        if (maxWidth == empty) ::<= {
          maxWidth = canvas.width - 4;
        }

      
        pushResolveQueueTop(fns:[::{
          choiceStackPush(value:{
            startAtBottom : startAtBottom,
            mode: CHOICE_MODE.READER,
            prompt: prompt,
            lines : canvas.refitLines(input: lines, maxWidth),
            hasPages : hasPages,
            maxHeight : maxHeight,
            maxWidth : maxWidth,
            onLeave : onLeave
          });
        }]); 
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
        setID,
        autoSkipAfterFrames
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
              setID : setID,
              autoSkipAfterFrames : autoSkipAfterFrames
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
        ::? {
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
        waitFrames,
        animationFrame,
        // Watch out! disableCache is a very special attribute. If active, every draw 
        // of the topmost widget will trigger a redraw of this leading up to every 
        // item in the menu stack up to the current one.
        //
        // This is useful for menu items that update outside of them being
        // the top widget. Use this sparingly! Usually, visuals of menu items are 
        // cached so that drawing is cheap. This mechanism is shut off if 
        // disableCache is true
        //
        // This should only be used if youre doing something special
        disableCache
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
            waitFrames : waitFrames,
            onInput : onInput,
            disableCache : disableCache
          });
        }]);        
        return getResolveQueue()->size-1;
      },

      // forcibly resolves the next queued item.
      // This is used for cases where normal 
      // user input is not sufficient for the desired 
      // effect.       
      forceResolveNext::{
        when(canResolveNext())
          resolveNext();
      },
      
      
      // communicates whether commitInput is required to be called to pump 
      // additional updates.
      needsCommit : {
        get::{
          when (canvas.hasEffects()) true;
          when (choiceStack->size == 0) true;
          @:val = choiceStack[choiceStack->keycount-1];
          when (val.mode == CHOICE_MODE.CUSTOM) true;
          when (val.rendered != true) true;
          when (val.renderState != empty && val.renderState != RENDER_STATE.DONE) true;
          when (hadInputLast == true) true;
          return false
        }
      },



      // Queues a nested resolve queue. When entered, will push a new resolve queue, 
      // which preserves existing queue items until this new resolve queue 
      // fully resolves. This is analogous to "calling a function of queues", which 
      // will all be processed until this queued item "returns".
      queueNestedResolve::(
        renderable, 
        onEnter, 
        onUpdate, 
        onInput, 
        jumpTag, 
        onLeave, 
        isAnimation, 
        animationFrame
        
      ) {
        @:onEnterReal::{
          breakpoint();
          pushResolveQueue();
          if (onEnter) onEnter();
        }

        @:onLeaveReal::{
          popResolveQueue(); //< this is probably needed because the queue wont resolve until AFTER onLeave is called
          if (onLeave) onLeave();
        }

      
        when(requestAutoSkip) ::<= {
          onEnterReal();
          onLeaveReal();
        }

        pushResolveQueueTop(fns:[::{
          choiceStackPush(value:{
            mode: CHOICE_MODE.CUSTOM,
            keep: false,
            isNestedResolve: true,
            renderable:renderable,
            onEnter:onEnterReal,
            onUpdate:onUpdate,
            jumpTag: jumpTag,
            onLeave: onLeaveReal,
            isAnimation : isAnimation,
            animationFrame : animationFrame,
            onInput : onInput,
            resolveStack : true
          });
        }]);        
        return getResolveQueue()->size-1;
      },
      
      // Convenience function. Creates a nested resolve (queueNestedResolve) 
      // and adds a queueCustom for each "phase" (a function call).
      // If a phase returns false, the remaining phases are cancelled.
      // Note that each queueCustom happens AFTER each phase function ends.
      queueNestedPhases ::(
        phases => Object,
        onFinish,
        renderable
      ) {
        @finished = false;
        phases = [...phases]
        @:doNextPhase :: {
          @:next = phases[0];
          when(next == empty)
            if (onFinish) ::<= {
              finished = true;
              onFinish(:true);
            }
          
          phases->remove(key:0);
          
          if (next() != false) 
            this.queueCustom(
              onEnter ::<- doNextPhase()
            );       
        }      
        this.queueNestedResolve(
          renderable,
          onEnter :: {
            doNextPhase();
          },
          
          onLeave ::{
            if (onFinish != empty && finished == false)
              onFinish(:false);
          }
        );
      },
      
      // An empty action that, when visited, will fire off 
      // the given callback. If the callback returns windowEvent.CALLBACK_DONE, it will 
      // cancel the action.
      queueCallback::(
        renderable, 
        callback => Function,
        jumpTag,
        isAnimation, 
        animationFrame
      ) {
        when(requestAutoSkip) ::<= {
          ::? {
            forever ::{
              if (callback() == false)
                send();
            }
          };
        }

        pushResolveQueueTop(fns:[::{
          choiceStackPush(value:{
            mode: CHOICE_MODE.CALLBACK,
            callback: callback,
            renderable:renderable,
            jumpTag: jumpTag,
            isAnimation : isAnimation,
            animationFrame : animationFrame
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
        onGetMinWidth,
        onGetMinHeight,       
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
        hideWindow,
        horizontalFlow,
        onInput,
        onGetFooter
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
            onGetHeader : onGetHeader,
            horizontalFlow : horizontalFlow,
            onInput : onInput,
            onGetMinHeight : onGetMinHeight,
            onGetMinWidth : onGetMinWidth,
            onGetFooter : onGetFooter
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
        return ::? {
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
        ::? {
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
        itemsPerRow,
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
            itemsPerRow: itemsPerRow,
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

            
      
      
      // Pushes through all queued actions to the top 
      // of the window stack in order. This is normally not needed, but 
      // may be needed in particular contexts and effects.
      onResolveAll ::(onDone, doResolveNext) {
        resolveQueues[resolveQueues->size-1].onResolveAll->push(:onDone);
        if (doResolveNext)
          resolveNext();        
      },
      
      removeOnResolveAll ::(onDone) {
        @:rq = resolveQueues[resolveQueues->size-1].onResolveAll;
        rq->remove(:rq->findIndex(:onDone));
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
      
      CALLBACK_DONE : {
        get ::<- CALLBACK_DONE
      },
      
      forceExit ::(soft){
        choiceStack[choiceStack->keycount-1].keep = empty;
        next();
      },

      // ask yes or no immediately.
      queueAskBoolean::(prompt, leftWeight, topWeight, onChoice => Function, renderable, onLeave, onGetPrompt) {
        return this.queueChoices(prompt, choices:['Yes', 'No'], canCancel:false, onLeave:onLeave, topWeight, leftWeight,
          onChoice::(choice){
            onChoice(which: choice == 1);
          },
          onGetPrompt,
          renderable
        );
      },
      
      // returns any resolvable items are left queued.
      hasAnyQueued:: {
        return getResolveQueue()->size != 0;
      },
      
      // records inputs.
      // Use getMacro() to fetch the recorded inputs.
      // The inputs are in the style of queueInputEvents() arguments.
      recordMacro ::{
        record = [];
        lastRecordFrames = 0;
      },
      
      getMacro ::<- record,
      
      // universally skips animations that come through 
      // normal paths.
      autoSkipAnimations : {
        get ::<- autoSkipAnimations,
        set ::(value) <- autoSkipAnimations = value
      },
      
      // the error handler will be called any time window event catches an error 
      errorHandler : {
        set ::(value) <- errorHandler = value
      },
      
      // queues a set of input events to be played
      // list should be an array of objects, each object 
      //
      // should contain:
      //  input : windowEvent.INPUT.*
      //  waitFrames : Number
      //  callback : Function
      // 
      // while inputs are queued, external inputs are ignored
      // until all queuedInputs are processed
      queueInputEvents ::(list) {
        foreach(list) ::(k, v) {
          queuedInputs->push(:{...v});        
        }
      }
    }  
    this.clearAll(::{});


  }
).new();

return WindowEvent;

