@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');

@:godot_sendLine = getExternalFunction(:"wyvern_gate__native__godot_send_line");
@:console = import(module:'Matte.System.ConsoleIO');

@currentCanvas;
@canvasChanged = false;


@:rerender = ::{
  @:lines = currentCanvas;
  foreach(lines) ::(index, line) {
    godot_sendLine(index, line);
  }
  canvasChanged = false;   
}
canvas.onCommit = ::(lines, renderNow){
  currentCanvas = lines;
  canvasChanged = true;
  if (renderNow != empty)
    rerender();
}


// return the input function that godot will call 
return ::(input) {
  if (input != empty && input >= 0) ::<= {
    console.println(:"input: " + input);
  }
  windowEvent.commitInput(input:if (input == -1) empty else input);
  canvas.update();
  if (canvasChanged) 
    rerender();
  return 1;
}

