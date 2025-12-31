
const Canvas = {
  new : function() {
    var self;
    var selectionMode = SELECTION_MODE__PEN;
    var settings;

    const palette = Palette.new();

    

    const attributeToColor = function(attribute) {
      if (attribute == 0)
        return TEXT_COLOR_ACTIVE;

      if (attribute & (Line.ATTRIBUTES.INACTIVE))
        return TEXT_COLOR_INACTIVE;

        
      var color = {r:64, g:64, b:64};
      if (attribute & (Line.ATTRIBUTES.WALL)) 
        color.g+=180

      if (attribute & (Line.ATTRIBUTES.SELECTION)) { 
        color.g+=120
        color.b+=120
      }
        
        
      return "rgb(" + color.r + ", " + color.g + ", " + color.b + ")";
    }

    const refreshCanvas = function() {
      for(var y = 0; y < VIEW_HEIGHT; ++y) {
        const line = lines[y];
        
        for(var x = 0; x < VIEW_WIDTH; ++x) {
          const atlasIndex = iterX + x + (y + iterY)*MAX_LENGTH;
          var ch = canvasChars[atlasIndex];
          var color = ch == 0 ? TEXT_COLOR_INACTIVE : TEXT_COLOR_ACTIVE;
          
          
          switch(settings.getMode()) {
            case Settings.MODE.WALL:
              if (canvasWall[atlasIndex])
                color = TEXT_COLOR_WALL;
          }
          line.editChar(
            x, ch, color
          );
        }
      }
    }
 
    


    var canvasChars = [];
    var canvasWall = [];
    const lines = [];
    const main = document.createElement('div');
    const events = EventSystem.new(['onMove']);

    main.style.userSelect = "none";
    main.style.fontSize = ''+CHAR_FONT_WIDTH_PX+'px';  
    var iterX = 0;
    var iterY = 0;

    for(var i = 0; i < VIEW_HEIGHT; ++i) {
      const line = Line.new(i);
      const v = line.getElement();
      const y = i;

      line.events.addCallback('onClick', function(data) {
        const x = data.index 
        const s = palette.getSelected();
        const atlasIndex = iterX + x + (y + iterY)*MAX_LENGTH;        
        
        switch(settings.getMode()) {
          case Settings.MODE.PEN:
            if (settings.isErase())
              canvasChars[atlasIndex] = 0;
            else
              canvasChars[atlasIndex] = s;

            refreshCanvas();
            break;

          case Settings.MODE.WALL:
            if (settings.isErase()) {
              canvasWall[atlasIndex] = false;            
            } else {
              canvasWall[atlasIndex] = true;
            }
            refreshCanvas();
            break;
            
        }
        
        
      });

      var row = i;
      main.appendChild(v);
      lines[i] = line;
    }

    
    

    
    for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
      canvasChars[i] = 0;
      canvasWall[i] = false;
    }
    
    self = {
      getElement : function() {
        return main;
      },
      
      refresh : refreshCanvas,
      
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
      
      setSettings : function(e) {
        settings = e;
      },
      
      moveRelative : function(x, y) {
        self.move(x + iterX, y + iterY);
      }
    }
    
    return self;
  }
}
