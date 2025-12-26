const Settings = {
  new : function(canvas, xRange, yRange) {
    const table = document.createElement('table');

    const makeLabel = function(str) {
      const out = document.createElement('div');
      out.innerText = str;
      return out;
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
    }

    
    
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


    return {
      getElement : function() {
        return table;
      }
    
    }
  }
}
