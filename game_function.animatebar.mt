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
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');


return ::(
  from, // current value;
  to,   // destination value. While max will never be exceeded, this controls the growth rate of the value changing.
  max,  // full bar. value will never exceed this

  // whether the bar should pause once done or complete.
  onGetPauseFinish,
  
  // to be called RIGHT when the last frame is reached.
  // if onGetPauseFinish() returns true, the paused frame is queued 
  // AFTER this is called.
  onFinish,

  // Gets the string to display above the bar
  onGetCaption,
  
  // Gets the caption to show below the bar
  onGetSubcaption,
  
  // Gets the caption to show below the subcaption.
  onGetSubsubcaption,

  // Called every frame to get the left weight of the window
  onGetLeftWeight,

  // Called every frame to get the top weight of the window
  onGetTopWeight,
  
  // Called when a new approaching value is calculated.
  onNewValue
) {
  @diff = from - to;
  @frame = 0;
  @current = from;
  @destination = if (to < max) to else max;


  windowEvent.queueCustom(
    onEnter ::{},
    isAnimation: true,
    onInput ::(input) {
      match(input) {
        (windowEvent.CURSOR_ACTIONS.CONFIRM,
         windowEvent.CURSOR_ACTIONS.CANCEL):
        current = destination
      }
    },
    animationFrame ::{  
      current = (0.9) * current + (0.1) * destination
      if (current > destination)
        current = max;
      if (onNewValue)
        onNewValue(:current);
      

      canvas.renderTextFrameGeneral(
        leftWeight: onGetLeftWeight(),
        topWeight : onGetTopWeight(),
        lines : [
          if (onGetCaption) onGetCaption() else '',
          '',
          canvas.renderBarAsString(width:40, fillFraction: (current) / max),
          if (onGetSubcaption) onGetSubcaption() else '',
          if (onGetSubsubcaption) onGetSubsubcaption() else ''
        ]
      );
      frame += 1;

      
      when((current - destination)->abs < 0.1) ::<= {
        if (onGetPauseFinish != empty && onGetPauseFinish())
          windowEvent.queueDisplay(
            leftWeight: onGetLeftWeight(),
            topWeight : onGetTopWeight(),
            skipAnimation: true,
            lines : [
              if (onGetCaption) onGetCaption() else '',
              '',
              canvas.renderBarAsString(width:40, fillFraction: (current) / max),
              if (onGetSubcaption) onGetSubcaption() else '',
              if (onGetSubsubcaption) onGetSubsubcaption() else ''
            ]        
          );           

        if (onFinish) 
          windowEvent.queueCustom(
            onLeave::{
              onFinish()
            }
          );

      
        return windowEvent.ANIMATION_FINISHED;
      }
    }
  );
    
 

}
