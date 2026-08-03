@:windowEvent = import(module:'core/windowevent.mt');
@:canvas = import(module:'core/graphics/canvas.mt');

return ::(do, message) {
  if (message == empty)
    message = 'Loading...'

    
  @frames = 0;
  @:onRender = ::{
    canvas.fill();
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
