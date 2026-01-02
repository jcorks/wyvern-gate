
const Canvas = {
  new : function() {
    var self;
    var selectionMode = SELECTION_MODE__PEN;
    var settings;
    const undoController = UndoContext.new();
    
    
    /// STATE SAVE
    var canvasChars = [];
    var canvasWall = [];
    var canvasAreas = [];
    /// STATE SAVE 
    
    
    
    
    var selectedSet = [];
    const resetSelectionSet = function() {
      for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
        selectedSet[i] = false;
      }
    }
    
    
    const setSelectionSet = function(x, y, x1, y1) {
      if (x1 < x) {
        const temp = x1;
        x1 = x;
        x = temp;
      }

      if (y1 < y) {
        const temp = y1;
        y1 = y;
        y = temp;
      }
      


      selectedSet.length = MAX_LENGTH*MAX_LENGTH;;

      resetSelectionSet();
      
      for(var yi = y; yi < y1; ++yi) {
        for(var xi = x; xi < x1; ++xi) {
          selectedSet[xi + yi*(MAX_LENGTH)] = true;
        }
      }
    }
    
    
    

    const palette = Palette.new();
    
    var commitChangeCounter = 0;
    const commitChange = function() {
      if (commitChangeCounter % 3 == 0) {
        undoController.commitState([canvasChars, canvasWall, canvasAreas]);
      }
      commitChangeCounter++;

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
              else
                color = TEXT_COLOR_INACTIVE;
              break;
              
            case Settings.MODE.SELECTOR:
              if (selectedSet[atlasIndex] == true) {
                if (ch == 0) {
                  color = TEXT_COLOR_SELECT_INACTIVE;
                } else {
                  color = TEXT_COLOR_SELECT;
                }
              } else
                color = TEXT_COLOR_INACTIVE;

          }
          line.editChar(
            x, ch, color
          );
        }
      }
    }



    const lines = [];
    const main = document.createElement('div');
    const events = EventSystem.new(['onMove']);

    main.style.userSelect = "none";
    main.style.fontSize = ''+CHAR_FONT_WIDTH_PX+'px';  
    var iterX = 0;
    var iterY = 0;
    
    // only used for initial creation
    var activeOverlay = Overlay.new([255, 255, 255]);
    activeOverlay.disablePointer();
    activeOverlay.hide();

    for(var i = 0; i < VIEW_HEIGHT; ++i) {
      const line = Line.new(i);
      const v = line.getElement();
      const y = i;
      
      line.events.addCallback('onRelease', function(data) {
        if (activeOverlay.isShown()) {
          const endIterX = data.index;
          const endIterY = y;
          
          const startIterX = activeOverlay.getData().iterX;
          const startIterY = activeOverlay.getData().iterY;
          
          activeOverlay.setP1(data.x, data.y);
          activeOverlay.hide();
          
          
          
          // do overlay action here.          
          switch(settings.getMode()) {
            case Settings.MODE.SELECTOR:
              setSelectionSet(
                startIterX,
                startIterY,
                endIterX,
                endIterY
              );
              refreshCanvas();
              break;
              
              
          }
        } else {
          activeOverlay.hide();          
        }
      });
      

      line.events.addCallback('onDown', function(data) {
        const x = data.index 
        const atlasIndex = iterX + x + (y + iterY)*MAX_LENGTH;        
        switch(settings.getMode()) {
          case Settings.MODE.AREA_EDITOR:
          case Settings.MODE.SELECTOR:
            if (activeOverlay.isShown()) {
              activeOverlay.setP1(data.x, data.y);
            } else {
              resetSelectionSet();
              refreshCanvas();
              activeOverlay.reset();
              activeOverlay.show();
              activeOverlay.setP0(data.x, data.y);
              activeOverlay.setP1(data.x, data.y);
              
              activeOverlay.getData().iterX = x;
              activeOverlay.getData().iterY = y;
            }
            break;
        }
      });


      line.events.addCallback('onEnter', function(data) {
        const x = data.index 
        const atlasIndex = iterX + x + (y + iterY)*MAX_LENGTH;        

        switch(settings.getMode()) {
          case Settings.MODE.AREA_EDITOR:
          case Settings.MODE.SELECTOR:
            if (activeOverlay.isShown()) {
              activeOverlay.setP1(data.x, data.y);
            }
        }
      });


      line.events.addCallback('onClick', function(data) {
        const x = data.index 
        const atlasIndex = iterX + x + (y + iterY)*MAX_LENGTH;        
        
        var old;
        var newVal;
        switch(settings.getMode()) {
          case Settings.MODE.PEN:
            const s = palette.getSelected();
            old = canvasChars[atlasIndex];
            if (settings.isErase())
              newVal = 0;
            else
              newVal = s;

            if (old != newVal) {
              canvasChars[atlasIndex] = newVal;
              commitChange();
              refreshCanvas();
            }
            break;

          case Settings.MODE.WALL:
            old = canvasWall[atlasIndex]
            if (settings.isErase()) {
              newVal = false;            
            } else {
              newVal = true;
            }
            if (old != newVal) {
              canvasWall[atlasIndex] = newVal;
              commitChange();
              refreshCanvas();
            }
            
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
    commitChange();
    
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
      
      undo : function() {
        const state = undoController.undo();
        if (state == false) return;
        canvasChars = state[0];
        canvasWall  = state[1];
        canvasAreas = state[2];
        refreshCanvas();
      },


      redo : function() {
        const state = undoController.redo();
        if (state == false) return;
        canvasChars = state[0];
        canvasWall  = state[1];
        canvasAreas = state[2];
        refreshCanvas();
      },


      
      moveRelative : function(x, y) {
        self.move(x + iterX, y + iterY);
      }
    }
    
    return self;
  }
}
