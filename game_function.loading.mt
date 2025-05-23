@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');

return ::(do, message) {
  if (message == empty)
    message = 'Loading...'

    
  @frames = 0;
  @:onRender = ::{
    canvas.blackout();
    canvas.movePen(
      x: (canvas.width / 2 - message->length / 2)->floor,
      y: (canvas.height/2)->floor
    );
    
    canvas.drawText(text:message);
  };
  
  
  windowEvent.queueCustom(
    onEnter ::{},
    renderable : {
      render : onRender
    },
    waitFrames : 10,
    onLeave ::<- do(),
    jumpTag: 'loading'
  );

}
