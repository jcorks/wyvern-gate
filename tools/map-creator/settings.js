const Settings = {
  MODE : {
    PEN : 0,
    WALL : 1,
    SELECTOR : 2,
    AREA_EDITOR : 3,
    CONNECTIONS : 4
  },

  new : function(canvas, xRange, yRange) {
    const table = document.createElement('table');
    const patterns = {
      Default : Pattern.new()
    };

    const makeLabel = function(str) {
      const out = document.createElement('div');
      out.innerText = str;
      return out;
    }
    
    const hideSet = function(set) { 
      for(var i = 0; i < set.length; ++i) {
        set[i].style.display = 'none'
      }
    }

    const showSet = function(set) { 
      for(var i = 0; i < set.length; ++i) {
        set[i].style.display = 'block'
      }
    }


    const makeRow = function(items) {
      var row = document.createElement('tr');
      var data;
      table.appendChild(row);
      
      
      for(var i = 0; i < items.length; ++i) {
        const next = document.createElement('td');      
        row.appendChild(next);
        
        next.appendChild(items[i]);
      }
      
      return items;
    }
    
    const makeButton = function(text, onClick) {
      const b = document.createElement('button')
      b.innerText = text;
      b.style.width = "100%";
      b.addEventListener(
        "click",
        onClick 
      )
      return b;
    }
    
    const setDropDownOptions = function(dropDown, options) {
      const children = [...dropDown.children];
      for(var i = 0; i < children.length; ++i) {
        dropDown.removeChild(children[i]);
      }
      
      for(var i = 0; i < options.length; ++i) {
        const opt = document.createElement("option");
        opt.text = options[i];
        dropDown.add(opt);
      }
    }
    

    var cursorOptions_isWall_set;
    var patternOptions_pattern_set;
    var cursorOptions_connections_set;
    var undoRedo_set;
    
    const updateLayout = function() {
      hideSet(cursorOptions_isErase_set);
      hideSet(cursorOptions_connections_set);
      canvas.disablePatternContextMenu();
      canvas.disableAreas();
      switch(cursorMode_element.value) {
        case 'Pen':
          showSet(cursorOptions_isErase_set);
          break;

        case 'Wall':
          showSet(cursorOptions_isErase_set);
          break;
          
        case 'Selector':
          canvas.enablePatternContextMenu();
          break;
          
        case 'Area Editor':
          showSet(cursorOptions_isErase_set);
          canvas.enableAreas();
          break;
          
        case 'Connectors': 
          showSet(cursorOptions_connections_set);
          showSet(cursorOptions_isErase_set);
        
          break;

      }
      canvas.refresh();
    }
    
    // row -1 
        const projectOptions_projectNew_element = makeButton(
          "New",
          function() {
          
          }
        )



        const projectOptions_projectSave_element  = makeButton(
          "Save",
          function() {
          
          }
        )

        const projectOptions_projectExport_element  = makeButton(
          "Export",
          function() {
          
          }
        )


        const projectOptions_projectImport_element  = makeButton(
          "Import",
          function() {
          
          }
        )

        const projectOptions_projectList_element = document.createElement('select');
        setDropDownOptions(projectOptions_projectList_element, ['Default']);
        projectOptions_project_set = makeRow([
          makeLabel('Project:'),
          projectOptions_projectList_element
        ]);



        projectOptions_project_set = makeRow([
          makeLabel('|'),
          projectOptions_projectNew_element,
          projectOptions_projectSave_element,
        ]);
        
        makeRow([
          makeLabel('|'),
          projectOptions_projectExport_element,
          projectOptions_projectImport_element
        
        ])

        makeRow([
          makeLabel('|')
        ]);

        
    
    // row 0
        const patternOptions_patternClone_element = makeButton(
          "Clone",
          function(event) {
            const ch = window.prompt("Enter a name for the cloned pattern:");
            
            if (Object.hasOwnProperty(patterns, ch)) {
              window.alert('The name of this pattern already exists!');
              return;
            }
            
            const newP = Pattern.new();
            newP.load(canvas.getPattern().save());
            patterns[ch] = newP;
            
            
            // clear undo 
            newP.undo();
            newP.commitChange();
            
            canvas.setPattern(newP);
            rebuildPatternPulldown();
          }
        )
        const patternOptions_patternNew_element = makeButton(
          "New",
          function(event) {
            const ch = window.prompt("Enter a name for the new pattern:");
            
            if (Object.hasOwnProperty(patterns, ch)) {
              window.alert('The name of this pattern already exists!');
              return;
            }
            patterns[ch] = Pattern.new();
            canvas.setPattern(patterns[ch]);
            rebuildPatternPulldown();
          }
        )
        const patternOptions_patternRemove_element = makeButton(
          "Remove",
          function(event) {
          
            const patternT = canvas.getPattern();
            const keys = Object.keys(patterns);
            var whoami = '[Error]'
            
            for(var i = 0; i < keys.length; ++i) {
              if (patterns[keys[i]] == patternT) {
                whoami = keys[i];
                break;
              }
            }
            
            
            if (window.confirm("Really remove the pattern " + whoami + '?')) { 
              delete patterns[whoami];
              
              const keys = Object.keys(patterns);
              
              var pattern;
              if (keys.length == 0) {
                pattern = Pattern.new();
                patterns['Default'] = pattern;
              } else {
                pattern = patterns[Object.keys(patterns)[0]];
              }
              
              canvas.setPattern(pattern);
            }
            rebuildPatternPulldown();
          }
        )

        const patternOptions_patternList_element = document.createElement('select');
        setDropDownOptions(patternOptions_patternList_element, ['Default']);
        
        const rebuildPatternPulldown = function() {
          const pattern = canvas.getPattern();
          const keys = Object.keys(patterns);
          setDropDownOptions(patternOptions_patternList_element, keys);
          for(var i = 0; i < keys.length; ++i) {
            if (patterns[keys[i]] == pattern) {
              patternOptions_patternList_element.value = keys[i];
              break;
            }
          }
        }

        
        
        patternOptions_pattern_set = makeRow([
          makeLabel('Patterns:'),
          patternOptions_patternList_element,
        ]);


        patternOptions_pattern_set = makeRow([
          makeLabel('|'),
          patternOptions_patternNew_element,
          patternOptions_patternClone_element,
          patternOptions_patternRemove_element
        ]);
        
        makeRow([
          makeLabel('|')
        ])




        patternOptions_patternList_element.addEventListener(
          "change",
          function() {
            const newPattern = patterns[patternOptions_patternList_element.value];
            canvas.setPattern(newPattern);
          }
        );






        
    // UNDO/REDO
        const undo_element = document.createElement('button');
        const redo_element = document.createElement('button');
        
        
        undo_element.innerText = 'Undo';
        redo_element.innerText = 'Redo';


        // make ui elements
        makeRow([
          makeLabel('Undo/Redo'),
          undo_element,
          redo_element
        ]);
        
        undo_element.addEventListener('click', function() {
          canvas.undo(); 
        })

        redo_element.addEventListener('click', function() {
          canvas.redo(); 
        })

        makeRow([
          makeLabel('|'),
        ]);
       
    
    
    // ROW 1: View
        const locationX_element = document.createElement('input');
        const locationY_element = document.createElement('input');
        locationX_element.type = 'number';
        locationY_element.type = 'number';
        locationX_element.value = 0;
        locationY_element.value = 0;
        locationX_element.style.width = "70px";
        locationY_element.style.width = "70px";


        // make ui elements
        makeRow([
          makeLabel('View location:'),
          locationX_element,
          locationY_element
        ]);

        // make connections
        canvas.events.addCallback('onMove', function() {
          locationX_element.value = canvas.getViewX()
          locationY_element.value = canvas.getViewY()
        });
        
        locationX_element.addEventListener('change', function() {
          xRange.value = locationX_element.value;
          xRange.dispatchEvent(new Event("change"));
        });
        locationY_element.addEventListener('change', function() {
          yRange.value = locationY_element.value;
          yRange.dispatchEvent(new Event("change"));
        });
 
        
    // Cursor Mode
        const modes = [
          'Pen',
          'Wall',
          'Selector', 
          'Area Editor',
          'Connectors',
        ];
        const cursorMode_element = document.createElement('select');
        setDropDownOptions(cursorMode_element, modes);

        // make ui elements
        makeRow([
          makeLabel('Mode:'),
          cursorMode_element,
        ]);

        // make connections
        cursorMode_element.addEventListener('change', updateLayout);



    // Cursor options: erase
        const isErase_element = document.createElement('input');
        isErase_element.type = 'checkbox';

        // make ui elements
        cursorOptions_isErase_set = makeRow([
          makeLabel(''),
          makeLabel('Erase?:'),
          isErase_element
        ]);
        
    // connection id (connections)
        const connectionID_element = document.createElement('select');
        setDropDownOptions(connectionID_element, ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z']);

        // make ui elements
        cursorOptions_connections_set = makeRow([
          makeLabel(''),
          makeLabel('ID:'),
          connectionID_element
        ]);
        

        
    // SelectorOptions source


    canvas.setPattern(patterns.Default);
    return {
      getElement : function() {
        return table;
      },
      
      save : function() {
        const p = {};
        const keys = Object.keys(patterns);
      
        for(var i = 0; i < keys.length; ++i) {
          p[keys[i]] = patterns.save();
        }
      
        return {
          patterns : p
        }
      },
      
      load : function(obj) {
        patterns = [];
        const keys = Object.keys(patterns);
        
        for(var i = 0; i < keys.length; ++i) {
          const p = Pattern.new();
          p.load(obj[keys]);
          patterns.push(p);
        }
        rebuildPatternPulldown();
      },
      
      setMode : function(i) {
        cursorMode_element.value = modes[i];
        updateLayout();
      },
      
      getMode : function() {
        return modes.indexOf(cursorMode_element.value)
      },
            
      getConnectionID : function() {
        return connectionID_element.value;
      },
            
      isErase : function() {
        return isErase_element.checked
      }
    
    }
  }
}
