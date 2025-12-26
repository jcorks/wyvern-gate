
const Canvas = {
  new : function() {
    var self;
    var selectionMode = SELECTION_MODE__PEN;

    const palette = Palette.new();


 
    


    var canvasChars = [];
    const lines = [];
    const main = document.createElement('div');
    const events = EventSystem.new(['onMove']);

    main.style.userSelect = "none";
    main.style.fontSize = ''+CHAR_FONT_WIDTH_PX+'px';  
    var iterX = 0;
    var iterY = 0;

    for(var i = 0; i < VIEW_HEIGHT; ++i) {
      const line = Line.new();
      const v = line.getElement();
      const y = i;

      line.events.addCallback('onClick', function(data) {
        const x = data.index 
        const s = palette.getSelected();
        line.editChar(x, s);
        canvasChars[iterX + x + MAX_WIDTH*(iterY + y)] = s;
        
      });

      var row = i;
      main.appendChild(v);
      lines[i] = line;
    }

    
    
    const refreshCanvas = function() {
      for(var y = 0; y < VIEW_HEIGHT; ++y) {
        const line = lines[y];

        line.setState(function() {
          const list = [];
          for(var x = iterX; x < iterX + VIEW_WIDTH; ++x) {
            list.push(canvasChars[x + (iterY+y) * MAX_WIDTH]);
          }
          return list;
        }());
      }

    }
    
    self = {
      getElement : function() {
        return main;
      },
      
      move : function(x, y) {
        const oldX = iterX;
        const oldY = iterY;
        if (x < 0) x = 0;
        if (y < 0) y = 0; 
        iterX = x;
        iterY = y;
        
        if (oldX == iterX && oldY == iterY) return;
        refreshCanvas();
        events.emit('onMove');
      },
      
      events : events,
      
      getPalette : function() {
        return palette;
      },
      
      getViewX : function() {
        return iterX
      },
      
      getViewY : function() {
        return iterY
      },
      
      moveRelative : function(x, y) {
        self.move(x + iterX, y + iterY);
      }
    }
    
    return self;
  }
}
