@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');

return ::(do, message) {
  if (message == empty)
    message = 'Loading...'

    
  @frames = 0;
  @:onRender = ::{
    canvas.blackout();
    when(frames == 0) ::<= {
      

      canvas.movePen(
        x: (canvas.width / 2 - message->length / 2)->floor,
        y: (canvas.height/2)->floor
      );
      
      canvas.drawText(text:message);
      frames += 1;
    }
    if (frames == 1) ::<= {
      frames += 1;
      do();
    }
    return windowEvent.ANIMATION_FINISHED;
  };
  
  
  windowEvent.queueCustom(
    onEnter ::{},
    animationFrame : onRender,
    jumpTag: 'loading',
    isAnimation : true
  );

}
