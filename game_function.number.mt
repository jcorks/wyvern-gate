@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');


return ::(
  onDone => Function,
  prompt => String,
  renderable,
  canCancel
) {
  @name = '';
  
  @:select = [
    'Space',
    'Delete',
    'Done',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];
  
  windowEvent.queueChoices(
    renderable :{
      render :: {
        if (renderable)
          renderable.render();
        @pinch = name->length;
        if (prompt->length > pinch)
          pinch = prompt->length;
          
        @:centerX = canvas.width / 2;
        @:centerY = canvas.height / 4;
        @:height = 5;
        @:width = 4 + 1 + pinch;
        
        @:top = (centerY - height / 2)->floor;
        @:left = (centerX - width / 2)->floor;
        canvas.renderFrame(
          top, left, width, height
        );
        
        canvas.movePen(x:left+2, y:top);
        canvas.drawText(text:prompt);
        
        canvas.movePen(x:left+2, y:(top + height/2)->floor);
        canvas.drawText(text:name + '_');
      }
    },  
    choices: select,
    prompt: "",
    leftWeight: 0.5,
    topWeight: 1,
    canCancel: if (canCancel == empty) false else canCancel,
    keep: true,
    jumpTag: 'num',
    onCancel ::{
      if (canCancel == true)
        if (windowEvent.canJumpToTag(name:'num'))
          windowEvent.jumpToTag(name:'num', doResolveNext:true, goBeforeTag:true);                    
    },
    onChoice ::(choice) {
      when(choice == 1) ::<= {
        name = name + ' ';
      }

      when(choice == 2) ::<= {
        when(name->length <= 1)
          name = '';
        name = name->substr(from:0, to:name->length-2);
      }
      
      when(choice == 3) ::<= {
        if (name->length > 0) ::<= {
          onDone(:Number.parse(:name));
          if (windowEvent.canJumpToTag(name:'num'))
            windowEvent.jumpToTag(name:'num', doResolveNext:true, goBeforeTag:true);            
          
        }
      }
      
      name = name + select[choice-1];
    }
  );
}
