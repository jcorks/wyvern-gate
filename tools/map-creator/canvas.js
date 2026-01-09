
const Canvas = {
  new : function() {
    var self;
    var selectionMode = SELECTION_MODE__PEN;
    var settings;
    const undoController = UndoContext.new();
    var iterX = 0;
    var iterY = 0;
    const palette = Palette.new();
    
    const lines = [];
    const main = document.createElement('div');
    const events = EventSystem.new(['onMove']);    
    var activeOverlay = Overlay.new([255, 255, 255]);
    
    /// STATE SAVE
    var canvasChars = [];
    var canvasWall = [];
    var canvasAreas = [];
    /// STATE SAVE 
    
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
    
    // for right click menus
    var contextHandler;
    var contextMenu;
    
    
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
    


    
    const commitChangeSoft = function() {
      if (commitChangeCounter % 3 == 0) {
        undoController.commitState([canvasChars, canvasWall, canvasAreas]);
      }
      commitChangeCounter++;
    }

    const commitChange = function() {
      undoController.commitState([canvasChars, canvasWall, canvasAreas]);
      commitChangeCounter++;
    }
    



    const refreshCanvas = function() {
      for(var y = 0; y < VIEW_HEIGHT; ++y) {
        const line = lines[y];
        
        for(var x = 0; x < VIEW_WIDTH; ++x) {
          const atlasIndex = iterX + x + (y + iterY)*MAX_LENGTH;
          var ch = canvasChars[atlasIndex];
          
          if (typeof ch == 'String') {
            console.log('hi');
          }
          
          var color = ch === 0 ? TEXT_COLOR_INACTIVE : TEXT_COLOR_ACTIVE;
          
          
          switch(settings.getMode()) {
            case Settings.MODE.WALL:
              if (canvasWall[atlasIndex])
                color = TEXT_COLOR_WALL;
              else
                color = TEXT_COLOR_INACTIVE;
              break;
              
            case Settings.MODE.PATTERN:
              if (isSelected(iterX + x, iterY + y) == true) {
                if (ch === 0) {
                  color = TEXT_COLOR_SELECT_INACTIVE;
                } else {
                  color = TEXT_COLOR_SELECT;
                }
              }

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
            canvasChars[atlasIndex] = 0;
            canvasWall[atlasIndex]  = false;
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
        if (contextHandler == null) return;
        
        contextHandler(data.index, y, data.x, data.y);
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
            case Settings.MODE.PATTERN:
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
          case Settings.MODE.PATTERN:
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
                    canvasChars[xi + yi*MAX_LENGTH] = moveSet.chars[selIter];
                  canvasWall [xi + yi*MAX_LENGTH] = moveSet.wall [selIter];
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
        if (contextMenu)
          contextMenu.style.display = 'none';

        const x = data.index 
        const atlasIndex = iterX + x + (y + iterY)*MAX_LENGTH;        
        
        // special selection mode for moving stuff
        if (settings.getMode() == Settings.MODE.PATTERN && isSelected(iterX + x, iterY + y) == true) {
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
              inStroke = true;
            }
            break;

        
          case Settings.MODE.AREA_EDITOR:
          case Settings.MODE.PATTERN:
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
          case Settings.MODE.PATTERN:
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

            if (old !== newVal) {
              canvasChars[atlasIndex] = newVal;
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
      overlayChars[i] = 0;
    }
    commitChange();
    main.style.userSelect = "none";
    main.style.fontSize = ''+CHAR_FONT_WIDTH_PX+'px';  
    
    // only used for initial creation
    activeOverlay.disablePointer();
    activeOverlay.hide();

    
    
    
    
    
        
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
        const w = selectionX1 - selectionX0;
        for(var y = selectionY0; y < selectionY1; ++y) {
          var ySet = y - selectionY0;
          for(var x = selectionX0; x < selectionX1; ++x) {
            var xSet = x - selectionX0;
            
            set[xSet + ySet*w] = canvasChars[x + y * MAX_LENGTH];
            setW[xSet + ySet*w] = canvasWall[x + y * MAX_LENGTH];
            
            if (yank) {
              canvasChars[x + y * MAX_LENGTH] = 0;
              canvasWall[x + y * MAX_LENGTH] = false;
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
              canvasChars[xi + yi*MAX_LENGTH] = set.chars[selIter];
              canvasWall [xi + yi*MAX_LENGTH] = set.wall [selIter];
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

      enablePatternContextMenu : function() {
        contextHandler = function(x, y, xpos, ypos) {
        
          if (contextMenu == null) {
          
            const div = document.createElement("div");
            div.style.position = 'absolute';
            div.style.fontSize = '14px';
            div.style.backgroundColor = 'rgba(0, 0, 0, 0.8)';
            div.style.color = 'rgb(200, 200, 200)';
            div.style.zIndex = 2000;
            
            const createButton = function(name, callback) {
              const d = document.createElement("div");
              d.style.margin = '4px';
              d.innerText = name;
              div.appendChild(d);
              d.addEventListener("click", callback);
              
              d.addEventListener("mouseenter", function() {
                d.style.backgroundColor = 'rgba(255, 255, 255, 0.3)'
              });

              d.addEventListener("mouseleave", function() {
                d.style.backgroundColor = 'rgba(0, 0, 0, 0.8)'
              });

            }
            
            createButton("Copy", function() {
              if (!hasSelection())
                window.alert('No selection present. Drag the pointer to make a selection');
              clipboard = JSON.stringify(self.getSelectionSet(iterX + contextMenu.x, iterY + contextMenu.y));
              div.style.display = 'none';
              resetSelectionSet();
              refreshCanvas();
            });



            createButton("Cut", function() {
              if (!hasSelection())
                window.alert('No selection present. Drag the pointer to make a selection');
              clipboard = JSON.stringify(self.getSelectionSet(iterX + contextMenu.x, iterY + contextMenu.y, true));
              div.style.display = 'none';
              resetSelectionSet();
              refreshCanvas();
            });

            createButton("Paste", function() {
              div.style.display = 'none';              
              if (clipboard == null) {
                window.alert('No selection to paste.');
                return;
              }

              const set = JSON.parse(clipboard);
              selectionSetToMoveSet(
                set, 
                set.offsetX, 
                set.offsetY, 
                contextMenu.x, 
                contextMenu.y, 
                false
              );
              refreshCanvas();
              
            });

            
            document.body.appendChild(div);
            contextMenu = div;
          }
          contextMenu.x = x;
          contextMenu.y = y;
          contextMenu.style.display = 'initial';
          contextMenu.style.left = ''+xpos+'px';
          contextMenu.style.top = ''+ypos+'px';
          
        }
      },
      
      disablePatternContextMenu : function() {
      
      },

      
      moveRelative : function(x, y) {
        self.move(x + iterX, y + iterY);
      }
    }
    
    return self;
  }
}
