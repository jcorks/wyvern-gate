const Settings = {
  MODE : {
    PEN : 0,
    WALL : 1,
    PATTERN : 2,
    AREA_EDITOR : 4
  },

  new : function(canvas, xRange, yRange) {
    const table = document.createElement('table');
    const patterns = {};

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
    
    const addDropDownOptions = function(dropDown, options) {
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
    var undoRedo_set;
    
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

        
        
    // Cursor Mode
        const modes = [
          'Pen',
          'Wall',
          'Pattern', 
          'Area Editor'
        ];
        const cursorMode_element = document.createElement('select');
        addDropDownOptions(cursorMode_element, modes);

        // make ui elements
        makeRow([
          makeLabel('Mode:'),
          cursorMode_element,
        ]);

        // make connections
        cursorMode_element.addEventListener('change', function() {
          hideSet(cursorOptions_isErase_set);
          hideSet(patternOptions_pattern_set);
          canvas.disablePatternContextMenu();
          switch(cursorMode_element.value) {
            case 'Pen':
              showSet(cursorOptions_isErase_set);
              break;

            case 'Wall':
              showSet(cursorOptions_isErase_set);
              break;
              
            case 'Pattern':
              canvas.enablePatternContextMenu();
              showSet(patternOptions_pattern_set);
              break;

          }
          canvas.refresh();
        });



    // Cursor options: erase
        const isErase_element = document.createElement('input');
        isErase_element.type = 'checkbox';

        // make ui elements
        cursorOptions_isErase_set = makeRow([
          makeLabel(''),
          makeLabel('Erase?:'),
          isErase_element
        ]);
        
        
        
        
    // SelectorOptions source
        const patternOptions_patternStore_element = document.createElement('button');
        const patternOptions_patternLoad_element  = document.createElement('button');
        const patternOptions_patternNew_element   = document.createElement('button');

        const patternOptions_patternList_element = document.createElement('select');
        addDropDownOptions(patternOptions_patternList_element, ['Default']);
        


        
        patternOptions_patternStore_element.innerText = 'Store';
        patternOptions_patternLoad_element.innerText = 'Load';
        patternOptions_patternNew_element.innerText = 'New';
        
        patternOptions_pattern_set = makeRow([
          makeLabel(''),
          patternOptions_patternStore_element,
          patternOptions_patternLoad_element,
          patternOptions_patternList_element,
          patternOptions_patternNew_element
        ]);

        patternOptions_patternStore_element.addEventListener(
          "click",
          function(event) {
            const selection = canvas.getSelectionSet();
            if (selection.width == 0 || selection.height == 0)
              window.alert('Theres no pattern to save! Highlight the canvas by dragging first.');
              
            patterns[patternOptions_patternList_element.value] = selection;
          }
        );



        patternOptions_patternNew_element.addEventListener(
          "click",
          function(event) {
            const ch = window.prompt("Enter a name for the new pattern:");
            
            if (Object.hasOwnProperty(patterns, ch)) {
              window.alert('The name of this pattern already exists!');
            }
            
            patterns[ch] = canvas.getSelectionSet();
            
          }
        );


    return {
      getElement : function() {
        return table;
      },
      
      getPatterns : function() {
        return patterns;
      },
      
      setMode : function(i) {
        cursorMode_element.value = modes[i];
      },
      
      getMode : function() {
        return modes.indexOf(cursorMode_element.value)
      },
            
      isErase : function() {
        return isErase_element.checked
      }
    
    }
  }
}
