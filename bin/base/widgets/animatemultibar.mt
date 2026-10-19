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
@:windowEvent = import(module:'core/windowevent.mt');
@:canvas = import(module:'core/graphics/canvas.mt');


@generateContent = ::(clients) {
  @:bars = [];
  @:titles = [];
  foreach(clients) ::(k, v) {
    titles->push(:v.title);
    bars->push(:canvas.renderBarAsString(
      width:30, 
      fillFraction: (v.current) / v.max,
      auxFillFraction : (v.destination) / v.max
    ))
  }
  return canvas.columnsToLines(
    columns : [
      bars,
      titles
    ],
    leftJustifieds : [true, true],
    spacing: 1
  );
}

return {
  generateLines ::(clients) <- generateContent(:
    clients->map(::(value) <- 
      {
        current:value.from,
        destination: value.to,
        max : value.max,
        title : value.title
      }
    )
  ),

  widget ::(
    // An array containing objects to define a bar within the multibar widget 
    // Each object should contain:
    /*  
      title, // The displayed title of the bar shown to the user
      from, // current value;
      to,   // destination value. While max will never be exceeded, this controls the growth rate of the value changing.
      max,  // full bar. value will never exceed this

    */
    clients, 

    // whether the bar should pause once done or complete.
    onGetPauseFinish,

    // whether to pause at the start before showing the animation
    pauseStart,

    // Function to call when a specific client's value reaches the max.
    // Optionally, the function may return an object containing a new value and max.
    // If they are provided, the animation will continue as if first specifying 
    // the value and max
    onCompleteValue,

    // to be called RIGHT when the last frame is reached.
    // if onGetPauseFinish() returns true, the paused frame is queued 
    // AFTER this is called.
    onFinish,

    // Gets the string to display above the bar
    onGetCaption,

    // 
    onGetCoCaption,

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
    foreach(clients) ::(k, v) {
      v.diff = v.from - v.to;
      v.current = v.from
      v.destination = v.to;

    }

    @frame = 0;
    if (pauseStart == empty)
      pauseStart = true;

    if (pauseStart) 
      windowEvent.queueDisplay(
        leftWeight: onGetLeftWeight(),
        topWeight : onGetTopWeight(),
        skipAnimation: true,
        lines : [
          if (onGetCaption) onGetCaption() else '',
          '',
          if (onGetCoCaption) onGetCoCaption() else '',
          
          // the meat of it. it doesnt need to be meat. maybe some tofu or something idk
          ...generateContent(clients),
          if (onGetSubcaption) onGetSubcaption() else '',
          if (onGetSubsubcaption) onGetSubsubcaption() else ''
        ]
      );


    windowEvent.queueCustom(
      onEnter ::{},
      isAnimation: true,
      onInput ::(input) {
        match(input) {
          (windowEvent.CURSOR_ACTIONS.CONFIRM,
           windowEvent.CURSOR_ACTIONS.CANCEL): ::<= {
            foreach(clients) ::(k, v) {
              v.current = v.destination
            }
          }
        }
      },

      onLeave ::{
        if (onNewValue) {
          foreach(clients) ::(k, v) {
            onNewValue(client: k, value:v.destination);
          }
        }
        if (onGetPauseFinish != empty && onGetPauseFinish())
          windowEvent.queueDisplay(
            leftWeight: onGetLeftWeight(),
            topWeight : onGetTopWeight(),
            skipAnimation: true,
            lines : [
              if (onGetCaption) onGetCaption() else '',
              '',
              if (onGetCoCaption) onGetCoCaption() else '',
              ...generateContent(clients),
              if (onGetSubcaption) onGetSubcaption() else '',
              if (onGetSubsubcaption) onGetSubsubcaption() else ''
            ]        
          );           

        if (onFinish) 
          windowEvent.queueCustom(
            onLeave::{
              foreach(clients) ::(client, val) {
                onFinish(client, value:val.current)
              }
            }
          );    


      },
      
      animationFrame ::{  
        foreach(clients) ::(k, v) {
          v.current = (0.9) * v.current + (0.1) * v.destination
          if (v.current > v.destination)
            v.current = v.max;
            
          if ((v.current - v.max)->abs < 0.1 || v.current > v.max) {
            breakpoint()
            @:ret = onCompleteValue(client: k);
            if (ret->type == Object) {
              v.current = ret.from
              v.destination = ret.to
              v.max = ret.max
            }
          }

          if (onNewValue)
            onNewValue(client: k, value:v.current);
        }

        canvas.renderTextFrameGeneral(
          leftWeight: onGetLeftWeight(),
          topWeight : onGetTopWeight(),
          lines : [
            if (onGetCaption) onGetCaption() else '',
            '',
            if (onGetCoCaption) onGetCoCaption() else '',
            ...generateContent(clients),
            if (onGetSubcaption) onGetSubcaption() else '',
            if (onGetSubsubcaption) onGetSubsubcaption() else ''
          ]
        );
        frame += 1;

        return ::? {
          foreach(clients) ::(k, v) {
            if ((v.current - v.destination)->abs >= 0.1) send();
          }

          return windowEvent.ANIMATION_FINISHED;
        }
      }
    );
  }
}
