const Settings = {
  MODE : {
    PEN : 0,
    WALL : 1,
    SELECTOR : 2,
    AREA_EDITOR : 3
  },

  new : function(canvas, xRange, yRange) {
    const table = document.createElement('table');

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
      for(var i = 0; i < options.length; ++i) {
        const opt = document.createElement("option");
        opt.text = options[i];
        dropDown.add(opt);
      }
    }
    

    var cursorOptions_isWall_set;
    
    // ROW 1: View
        const locationX_element = document.createElement('input');
        const locationY_element = document.createElement('input');
        locationX_element.type = 'number';
        locationY_element.type = 'number';
        locationX_element.value = 0;
        locationY_element.value = 0;


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
          switch(cursorMode_element.value) {
            case 'Pen':
              showSet(cursorOptions_isErase_set);

            case 'Wall':
              showSet(cursorOptions_isErase_set);
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
        


    return {
      getElement : function() {
        return table;
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
