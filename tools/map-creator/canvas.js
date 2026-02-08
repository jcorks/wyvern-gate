
const Canvas = {
  new : function() {
    var self;
    var settings;
    var iterX = 0;
    var iterY = 0;
    var selectorContext = false;
    const palette = Palette.new();
    
    const lines = [];
    const main = document.createElement('div');
    const events = EventSystem.new(['onMove']);    
    var activeOverlay = Overlay.new([255, 255, 255]);



    /*
    var testOverlay = Overlay.new([255, 205, 205]);
    testOverlay.setP0(0, 0);
    testOverlay.setP1(200, 200);
    testOverlay.events.addCallback('onRelease', function() {
      // reverse order! the lines slightly overlap, so less-accurate
      // lines get prioritized if the order is increasing
      for(var i = lines.length-1; i >= 0 ; --i) {
        let r = lines[i].aliasPoint(testOverlay.getX(), testOverlay.getY());
        
        if (r != undefined) {
          let w = testOverlay.getWidth();
          let h = testOverlay.getHeight();
          testOverlay.setP0(r.x, r.y);
          break;
        }
      }
      
      for(var i = lines.length-1; i >= 0 ; --i) {
        let r = lines[i].aliasPoint(
          testOverlay.getX()+testOverlay.getWidth(), 
          testOverlay.getY()+testOverlay.getHeight()
        );
        
        if (r != undefined) {
          testOverlay.setP1(r.x, r.y);
          break;
        }
      }
      
      
    });
    testOverlay.enablePointer();
    */


    
    var pattern;
    
    // a layer over the real chars. Used for moving structures and pasting patterns.
    var overlayChars = [];
    
    var commitChangeCounter = 0;
    var selectionX0 = 0;
    var selectionY0 = 0;
    var selectionX1 = 0;
    var selectionY1 = 0;

    // if the user has clicked on a selected set in Move mode, this will be populated
    var moveSet;
    
    // The difference between the top-left corner of the selection and 
    // where the user first clicked
    var moveOffsetX;
    var moveOffsetY;

    // where the selection last was
    var moveSetX;
    var moveSetY;
    
    var areaSet;
    
    
    
    // fake clipboard
    var clipboard;
    
    // whether a pen stroke is active
    var inStroke = false;

    
    
    
    const resetSelectionSet = function() {
      selectionX0 = 0;
      selectionY0 = 0;
      selectionX1 = 0;
      selectionY1 = 0;
      
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
      
      selectionX0 = x+iterX;
      selectionY0 = y+iterY;

      selectionX1 = x1+iterX;
      selectionY1 = y1+iterY;
    }
    
    
    const hasSelection = function() {
      return selectionY1 - selectionY0 != 0 &&
             selectionX1 - selectionX0 != 0
    }
    
    const isSelected = function(x, y) {
      return x >= selectionX0 && x < selectionX1 &&
             y >= selectionY0 && y < selectionY1;
    }
    



    const commitChange = function() {
      pattern.undoController.commitState(pattern.save());
      commitChangeCounter++;
    }
    



    const refreshCanvas = function() {
      for(var y = 0; y < VIEW_HEIGHT; ++y) {
        const line = lines[y];
        
        for(var x = 0; x < VIEW_WIDTH; ++x) {
          const atlasIndex = iterX + x + (y + iterY)*MAX_LENGTH;
          var ch = pattern.chars[atlasIndex];
                    
          var color = ch === 0 ? TEXT_COLOR_INACTIVE : TEXT_COLOR_ACTIVE;
          
          var mode = settings == undefined ? Settings.MODE.WALL : settings.getMode()
          switch(mode) {
            case Settings.MODE.WALL:
              if (pattern.wall[atlasIndex])
                color = TEXT_COLOR_WALL;
              else
                color = TEXT_COLOR_INACTIVE;
              break;
              
            case Settings.MODE.SELECTOR:
              if (isSelected(iterX + x, iterY + y) == true) {
                if (ch === 0) {
                  color = TEXT_COLOR_SELECT_INACTIVE;
                } else {
                  color = TEXT_COLOR_SELECT;
                }
              }
              break;
              
            case Settings.MODE.CONNECTIONS:
              if (pattern.connections[atlasIndex] != null) {
                color = TEXT_COLOR_CONNECTION;
                ch = pattern.connections[atlasIndex][0];
              }
              break;

          }
          
          if (overlayChars[atlasIndex] != 0) {
            ch = overlayChars[atlasIndex];
            color = TEXT_COLOR_SELECT;
          }
          
          line.editChar(
            x, ch, color
          );
        }
      }
    }




    
    // whatever is selected, transfers it to the "move" set
    const selectionSetToMoveSet = function(selSet, offsetX, offsetY, x, y, yank) {
      moveSet = selSet;
      

      moveOffsetX = offsetX;
      moveOffsetY = offsetY;
      moveSetX = iterX + x + moveOffsetX;
      moveSetY = iterY + y + moveOffsetY; 


      for(var yi = 0; yi < moveSet.height; ++yi) {
        for(var xi = 0; xi < moveSet.width; ++xi) {
          const atlasIndex = (moveSetX + xi) + (moveSetY+yi)*MAX_LENGTH;
          if (yank) {
            pattern.chars[atlasIndex] = 0;
            pattern.wall[atlasIndex]  = false;
            pattern.Connections[atlasIndex] = null;
          }

          overlayChars[atlasIndex] = moveSet.chars[xi + (yi)*moveSet.width];
        }
      }
      
      
      
      refreshCanvas();
      resetSelectionSet();
    }


    for(var i = 0; i < VIEW_HEIGHT; ++i) {
      const line = Line.new(i);
      const v = line.getElement();
      const y = i;
      
      
      line.events.addCallback('onContext', function(data) {    
        if (selectorContext == false) return;    
        const x = data.index;
        ContextMenu(data.x, data.y,
          [
            "Copy", function() {
              if (!hasSelection())
                window.alert('No selection present. Drag the pointer to make a selection');
              
              clipboard = JSON.stringify(self.getSelectionSet(iterX + x, iterY + y));
              resetSelectionSet();
              refreshCanvas();            
            },
            
            
            "Cut", function() {
              if (!hasSelection())
                window.alert('No selection present. Drag the pointer to make a selection');
              clipboard = JSON.stringify(self.getSelectionSet(iterX + x, iterY + y, true));
              resetSelectionSet();
              refreshCanvas();
            },
            
            
            "Paste", function() {
              if (clipboard == null) {
                window.alert('No selection to paste.');
                return;
              }

              const set = JSON.parse(clipboard);
              selectionSetToMoveSet(
                set, 
                set.offsetX, 
                set.offsetY, 
                x, 
                y, 
                false
              );
              refreshCanvas();            
            }
          ]
        );
      });
      
      
      line.events.addCallback('onRelease', function(data) {
        if (inStroke == true) {
          commitChange();
          inStroke = false;
        }


        if (activeOverlay.isShown()) {
          const endIterX = data.index;
          const endIterY = y;
          
          const startIterX = activeOverlay.getData().iterX;
          const startIterY = activeOverlay.getData().iterY;
          
          activeOverlay.setP1(data.x, data.y);
          activeOverlay.hide();

          switch(settings.getMode()) {
            case Settings.MODE.AREA_EDITOR:
              const area = areaSet.addArea(0, 0);
              area.overlay.setP0(activeOverlay.getX(), activeOverlay.getY());
              area.overlay.setP1(activeOverlay.getX()+activeOverlay.getWidth(), activeOverlay.getY()+activeOverlay.getHeight());
              area.updateFromOverlay();
              break;
          
            case Settings.MODE.SELECTOR:
              if (moveSet == null) {
                setSelectionSet(
                  startIterX,
                  startIterY,
                  endIterX,
                  endIterY
                );
                refreshCanvas();              
              }
          }


        } else {
          activeOverlay.hide();          
        }
        
        
        // do overlay action here.          
        switch(settings.getMode()) {
          case Settings.MODE.SELECTOR:
            if (moveSet != null) {

              // reset overlay
              for(var yi = moveSetY; yi < moveSetY + moveSet.height; ++yi) {
                for(var xi = moveSetX; xi < moveSetX + moveSet.width; ++xi) {
                  overlayChars[xi + yi*MAX_LENGTH] = 0;
                }
              }
              
              // apply
              for(var yi = moveSetY; yi < moveSetY + moveSet.height; ++yi) {
                for(var xi = moveSetX; xi < moveSetX + moveSet.width; ++xi) {
                  const selIter = xi - moveSetX + (yi - moveSetY)*moveSet.width
                  if (moveSet.chars[selIter] != 0)
                    pattern.chars[xi + yi*MAX_LENGTH] = moveSet.chars[selIter];
                    pattern.wall [xi + yi*MAX_LENGTH] = moveSet.wall [selIter];
                    pattern.connections [xi + yi*MAX_LENGTH] = moveSet.connections[selIter];
                }
              }
              moveSet = null;
              commitChange();
              refreshCanvas();
  
            }
            break;
            
              
          
        } 
      });
      

      
      line.events.addCallback('onDown', function(data) {

        const x = data.index 
        const atlasIndex = iterX + x + (y + iterY)*MAX_LENGTH;        
        
        // special selection mode for moving stuff
        if (settings.getMode() == Settings.MODE.SELECTOR && isSelected(iterX + x, iterY + y) == true) {
          // yank the current selection set 
          if (moveSet == null) {
            selectionSetToMoveSet(
              self.getSelectionSet(), 
              selectionX0 - (iterX + x), 
              selectionY0 - (iterY + y), 
              x, 
              y, 
              true
            );
          } 
          
          return;
        }
        
        switch(settings.getMode()) {
          case Settings.MODE.WALL:
          case Settings.MODE.PEN:
            if (inStroke == false) {
              //commitChange();
            }
          case Settings.MODE.CONNECTIONS:
            if (inStroke == false) {
              inStroke = true;
            }
            break;

        
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

        if (moveSet != null) {
          // remove old set 
          for(var yi = moveSetY; yi < moveSetY + moveSet.height; ++yi) {
            for(var xi = moveSetX; xi < moveSetX + moveSet.width; ++xi) {
              overlayChars[xi + yi*MAX_LENGTH] = 0;
            }
          }

          // place new set
          moveSetX = iterX + x + moveOffsetX;
          moveSetY = iterY + y + moveOffsetY; 

          for(var yi = moveSetY; yi < moveSetY + moveSet.height; ++yi) {
            for(var xi = moveSetX; xi < moveSetX + moveSet.width; ++xi) {
              overlayChars[xi + yi*MAX_LENGTH] = moveSet.chars[xi - moveSetX + (yi - moveSetY)*moveSet.width];
            }
          }

          refreshCanvas();
          
          return;
        }

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
            old = pattern.chars[atlasIndex];
            if (settings.isErase())
              newVal = 0;
            else
              newVal = s;

            if (old !== newVal) {
              pattern.chars[atlasIndex] = newVal;
              refreshCanvas();
            }
            break;

          case Settings.MODE.WALL:
            old = pattern.wall[atlasIndex]
            if (settings.isErase()) {
              newVal = false;            
            } else {
              newVal = true;
            }
            if (old != newVal) {
              pattern.wall[atlasIndex] = newVal;
              refreshCanvas();
            }
            
            break;

          case Settings.MODE.CONNECTIONS:
            old = pattern.connections[atlasIndex]
            if (settings.isErase()) { 
              newVal = null;            
            } else {
              newVal = settings.getConnectionID();
            }
            if (old != newVal) {
              pattern.connections[atlasIndex] = newVal;
              refreshCanvas();
            }
            
            break;

            
        }
        
        
      });

      var row = i;
      main.appendChild(v);
      lines[i] = line;
    }

    
    

    
    main.style.userSelect = "none";
    main.style.fontSize = ''+CHAR_FONT_WIDTH_PX+'px';  
    
    // only used for initial creation
    activeOverlay.disablePointer();
    activeOverlay.hide();

    
    
    for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
      overlayChars[i] = 0;
    }
    
        
    self = {
      getElement : function() {
        return main;
      },
      
      getPalette : function() {
        return palette;
      },
      
      getSelectionSet : function(pointerX, pointerY, yank) {
        const set = [];
        const setW = [];
        const setC = [];
        const w = selectionX1 - selectionX0;
        for(var y = selectionY0; y < selectionY1; ++y) {
          var ySet = y - selectionY0;
          for(var x = selectionX0; x < selectionX1; ++x) {
            var xSet = x - selectionX0;
            
            set[xSet + ySet*w] = pattern.chars[x + y * MAX_LENGTH];
            setW[xSet + ySet*w] = pattern.wall[x + y * MAX_LENGTH];
            setC[xSet + ySet*w] = pattern.connections[x + y * MAX_LENGTH];
            
            if (yank) {
              pattern.chars[x + y * MAX_LENGTH] = 0;
              pattern.wall[x + y * MAX_LENGTH] = false;
              pattern.connections[x + y * MAX_LENGTH] = null;
            }
          }
        }
        
        if (pointerX != null) 
          pointerX = selectionX0 - pointerX;

        if (pointerY != null) 
          pointerY = selectionY0 - pointerY;
        
        if (yank);
          refreshCanvas();
        
        return {
          offsetX : pointerX,
          offsetY : pointerY,
          chars : set,
          wall : setW,
          connections : setW,
          width : w,
          height : selectionY1 - selectionY0
        }
      },
      
      // sets the current selection set from the output 
      // of a selectionSet object returned from getSelectionSet()
      //
      // This can also paste the original selection characters and wall 
      // state at a given x y
      restoreSelectionSet : function(set, pasteToo, x, y) {

        if (pasteToo) {
          for(var yi = y; yi < y + set.height; ++yi) {
            for(var xi = x; xi < x + set.width; ++xi) {
              const selIter = xi - x + (yi - y)*set.width
              pattern.chars[xi + yi*MAX_LENGTH] = set.chars[selIter];
              pattern.wall [xi + yi*MAX_LENGTH] = set.wall [selIter];
              pattern.connections[xi + yi*MAX_LENGTH] = set.connections[selIter];
            }
          }
        }

        setSelectionSet(
          x,
          y,
          x + set.width,
          y + set.height
        );
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
      
      clientPositionToMap : function(x, y) {
        // reverse order! the lines slightly overlap, so less-accurate
        // lines get prioritized if the order is increasing
        for(var i = lines.length-1; i >= 0 ; --i) {
          let r = lines[i].aliasPoint(x, y);
          
          if (r != undefined) {
            return {
              x : r.index + iterX,
              y : i + iterY
            }
          }
        }        
      },
      
      mapPositionToClient : function(x, y) {
        x -= iterX;
        y -= iterY;
        
        let c = lines[y].getChar(x).getBoundingClientRect();
        return {
          x : c.left,
          y : c.top
        }
      },
      
      
      undo : function() {
        const state = pattern.undoController.undo();
        if (state == false) return;
        pattern.load(state);
        refreshCanvas();
      },


      redo : function() {
        const state = pattern.undoController.redo();
        if (state == false) return;
        pattern.load(state);
        refreshCanvas();
      },

      enablePatternContextMenu : function() {
        selectorContext = true;
      },
      
      disablePatternContextMenu : function() {
        selectorContext = false;
      },
      
      enableAreas : function() {
        areaSet.show()
      },

      disableAreas : function() {
        areaSet.hide()
      },
      
      setPattern : function(p) {
        pattern = p;
        refreshCanvas();
      },
      
      getPattern : function(p) {
        return pattern;
      },
      
      moveRelative : function(x, y) {
        self.move(x + iterX, y + iterY);
      }
    }
    
    areaSet = AreaSet.new(self);
    
    return self;
  }
}
