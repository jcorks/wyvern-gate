const Settings = {
  MODE : {
    PEN : 0,
    WALL : 1,
    SELECTOR : 2,
    AREA_EDITOR : 3,
    CONNECTIONS : 4,
    LOCATIONS : 5,
    ENTITIES : 6
  },

  new : function(canvas, xRange, yRange) {
    var self;
    const table = document.createElement('table');
    var patterns = {
      Default : Pattern.new(canvas)
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
    
    var rebuildLocationPulldown;
    
    

    var cursorOptions_isWall_set;
    var patternOptions_pattern_set;
    var cursorOptions_connections_set;
    var undoRedo_set;
    
    const initProject = function() {
      if (Object.keys(window.localStorage).length == 0) {
        const newP = Pattern.new(canvas);
        canvas.setPattern(newP);        

        const save = self.save();
        const data = JSON.stringify(save);
        
        window.localStorage.setItem('Default', data);
      }
      const keys = Object.keys(window.localStorage);
      self.loadProjectName(keys[0]);
      rebuildProjectPulldown();
      
    }
    
    const updateLayout = function() {
      hideSet(cursorOptions_isErase_set);
      hideSet(cursorOptions_connections_set);
      hideSet(cursorOptions_entities_set);
      hideSet(cursorOptions_locationsOptions_set);
      hideSet(cursorOptions_locationsPulldown_set);
      hideSet(cursorOptions_locationsInfo_set);
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
          canvas.enableAreas();
          break;
          
        case 'Connectors': 
          showSet(cursorOptions_connections_set);
          showSet(cursorOptions_isErase_set);
          break;

        case 'Locations': 
          showSet(cursorOptions_locationsOptions_set);
          showSet(cursorOptions_locationsPulldown_set);
          showSet(cursorOptions_locationsInfo_set);
          showSet(cursorOptions_isErase_set);
          break;

        case 'Entities': 
          showSet(cursorOptions_entities_set);
          showSet(cursorOptions_isErase_set);
          break;

        
          break;

      }
      canvas.refresh();
    }
    
    // row -1 
        const projectOptions_projectNew_element = makeButton(
          "New",
          function() {
            if (window.confirm("Save the current map?")) {
              const save = self.save();
              const data = JSON.stringify(save);
              
              const name = projectOptions_projectList_element.value
              window.localStorage.setItem(name, data);              
            }

            const ch = window.prompt("Enter a name for the new, blank map.");
            if ((typeof ch) != 'string') return;
            if (typeof window.localStorage.getItem(ch) == "string") {
              if (!window.confirm("The map " + ch + " exists. Overwrite?")) {
                return;
              }
            }
            
            patterns = {
              Default : Pattern.new(canvas)
            };                        
            const newP = patterns.Default;
            canvas.setPattern(newP);
            const save = self.save();
            const data = JSON.stringify(save);
            window.localStorage.setItem(ch, data);

            rebuildProjectPulldown();
            self.loadProjectName(ch);
            
          }
        )



        const projectOptions_projectSave_element  = makeButton(
          "Save",
          function() {
            const save = self.save();
            const data = JSON.stringify(save);
            
            const name = projectOptions_projectList_element.value
            window.localStorage.setItem(name, data);
          }
        )

        const projectOptions_projectExport_element  = makeButton(
          "Export",
          function() {
            const save = self.save();
            const data = JSON.stringify(save);
            
          
            const supportsSaving = (typeof window.showSaveFilePicker != 'undefined');
              
            if (supportsSaving) {
              const handle = window.showSaveFilePicker({
                startIn : 'downloads',
                suggestedName : 'map.txt'
              })
              
              handle.write(data);
              handle.close();
              
            } else {
              const ch = window.prompt("The browser doesn't allow direct file saving, which. Yeah, fair. But also yes just enter a name here to put it in your downloads folder:");
              if ((typeof ch) != 'string') return;

              const blob = new Blob([data], {type : 'text/plain'});
              const downloadelem = document.createElement("a");
              const url = URL.createObjectURL(blob);
              document.body.appendChild(downloadelem);
              downloadelem.href = url;
              downloadelem.download = ch;
              downloadelem.click();
              downloadelem.remove();
              window.URL.revokeObjectURL(url);
            }

            
          }
        )


        const projectOptions_projectImport_element  = makeButton(
          "Import",
          function() {
            const el = document.createElement('input');
            el.type = 'file';
            el.addEventListener("change", function(event) {
          
              const files = el.files;
              if (!files || files.length == 0) return;
              
              files[0].text().then(function(value) {

                
                const ch = window.prompt("Enter a name for this map.");
                if ((typeof ch) != 'string') return;
                if (typeof window.localStorage.getItem(ch) == "string") {
                  if (!window.confirm("The map " + ch + " exists. Overwrite?")) {
                    return;
                  }
                }

                
                window.localStorage.setItem(ch, value);
                rebuildProjectPulldown();
                self.loadProjectName(ch);
              });
            
            });
            el.click();
          }
        )

        const projectOptions_projectList_element = document.createElement('select');
        setDropDownOptions(projectOptions_projectList_element, ['Default']);
        projectOptions_project_set = makeRow([
          makeLabel('Map:'),
          projectOptions_projectList_element
        ]);

        projectOptions_projectList_element.addEventListener(
          "change",
          function() {
            const which = projectOptions_projectList_element.value
            self.loadProjectName(which);
          }
        );


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
            
            const newP = Pattern.new(canvas);
            newP.load(canvas.getPattern().save());
            patterns[ch] = newP;
            
            
            // clear undo 
            newP.undo();
            newP.commitChange();
            
            canvas.setPattern(newP);
            rebuildPatternPulldown();
            updateLayout();
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
            patterns[ch] = Pattern.new(canvas);
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
                pattern = Pattern.new(canvas);
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
        
        const rebuildProjectPulldown = function() {
          const keys = Object.keys(window.localStorage);
          if (keys.length == 0) {
            setDropDownOptions(projectOptions_projectList_element, ['Default']);
          } else {
            setDropDownOptions(projectOptions_projectList_element, keys);
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
            const p = canvas.getPattern();
            p.areaSet.hide();

            const newPattern = patterns[patternOptions_patternList_element.value];
            canvas.setPattern(newPattern);
            updateLayout();
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
          'Locations',
          'Entities',
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


        const connectionNeededID_element = document.createElement('select');
        setDropDownOptions(connectionNeededID_element, ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z']);


        // make ui elements
        cursorOptions_connections_set = makeRow([
          makeLabel(''),
          makeLabel('ID:'),
          connectionID_element,

          makeLabel('Requires:'),
          connectionNeededID_element

        ]);
        
    // Locations
        const locationID_element = document.createElement('div');
        const locationSymbol_element = document.createElement('div');
        const locationPulldown_element = document.createElement('select');

        
        const updateLocationTags = function() {
          const pattern = canvas.getPattern();
          const which = pattern.locations[locationPulldown_element.value];
          
          if (!which) return;
          locationSymbol_element.innerText = 'Symbol:['+which.symbol+']';
          locationID_element.innerText = 'ID:['+which.id+']';        
        }        
        
        rebuildLocationPulldown = function() {
          const pattern = canvas.getPattern();
          if (!pattern) return;
          const keys = Object.keys(pattern.locations);
          setDropDownOptions(locationPulldown_element, keys);
          updateLocationTags();
        }


        locationPulldown_element.addEventListener("change", function() {
          updateLocationTags();
        })


        
        const locationNew_element = makeButton('New', function() {
          const pattern = canvas.getPattern();
          const name = window.prompt("Enter the name that uniquely defines this location");          
          if (typeof name != 'string') return; 
          
          if (pattern.locations[name] != null) {
            if (!window.confirm(name + ' already exists. Replace?')) return;
          }
          
          const id = window.prompt("Enter the ID for this location");   
          if (typeof id != 'string') return; 
          const ch = window.prompt("Enter the character to represent this location");          
          if (typeof ch != 'string') return; 
          
          pattern.locations[name] = {
            id: id,
            symbol : ch
          }
          rebuildLocationPulldown();
        
        });
        const locationRemove_element = makeButton('Remove', function() {
          const name = locationPulldown_element.value;
          if (!window.confirm("Really remove location " + name + "? This is not undoable.")) return;

          canvas.pattern.removeLocation(name);
          rebuildLocationPulldown();        
        });
        const locationClone_element = makeButton('Clone', function() {
          const pattern = canvas.getPattern();
          const name = window.prompt("Enter the name that uniquely defines this cloned location");          
          const source = locationPulldown_element.value
          if (typeof name != 'string') return; 
          if (name == source) return;

          
          pattern.locations[name] = {
            id: pattern.locations[source].id,
            symbol : pattern.locations[source].symbol
          }
          rebuildLocationPulldown();
        
        });




    
        cursorOptions_locationsPulldown_set = makeRow([
          makeLabel(''),
          locationPulldown_element,
          makeLabel(''),
        ]);
        
        cursorOptions_locationsOptions_set = makeRow([
          makeLabel(''),
          locationNew_element,
          locationClone_element,
          locationRemove_element,
        ]);

        cursorOptions_locationsInfo_set = makeRow([
          makeLabel(''),
          locationID_element,
          locationSymbol_element
        ]);





    // Entities
        entitiesID_element = document.createElement('input');
    
        cursorOptions_entities_set = makeRow([
          makeLabel(''),
          makeLabel('ID:'),
          entitiesID_element,
        ]);
        rebuildLocationPulldown();



        
    // SelectorOptions source

    rebuildProjectPulldown();
    self = {
      getElement : function() {
        return table;
      },
      
      save : function() {
        const p = {};
        const keys = Object.keys(patterns);
        var whichSaved = null;

      
        for(var i = 0; i < keys.length; ++i) {
          p[keys[i]] = patterns[keys[i]].save();
          if (patterns[keys[i]] == canvas.getPattern()) {
            whichSaved = keys[i];
          }
        }
      
        return {
          activePattern : whichSaved,
          patterns : p
        }
      },
      
      loadProjectName : function(name) {
        const str = window.localStorage.getItem(name);
        if (typeof str != 'string') return;
        
        const obj = JSON.parse(str);
        self.load(obj);
        if (projectOptions_projectList_element.value != name)
          projectOptions_projectList_element.value = name;
      },
      
      load : function(obj) {
        patterns = {};
        const keys = Object.keys(obj.patterns);
        
        for(var i = 0; i < keys.length; ++i) {
          const p = Pattern.new(canvas);
          p.load(obj.patterns[keys[i]]);
          patterns[keys[i]] = p;
        }
        
        if (obj.activePattern == null) {
          obj.activePattern = keys[0];
        }
        
        canvas.setPattern(patterns[obj.activePattern]);
        
        rebuildPatternPulldown();
        rebuildLocationPulldown();
        updateLayout();
      },
      
      setMode : function(i) {
        cursorMode_element.value = modes[i];
        updateLayout();
      },
      
      getMode : function() {
        return modes.indexOf(cursorMode_element.value)
      },
      
      getEntityID : function() {
        return entitiesID_element.value
      },
      getLocationName : function() {
        return locationPulldown_element.value
      },

            
      getConnectionID : function() {
        return connectionID_element.value;
      },
      getConnectionNeededID : function() {
        return connectionNeededID_element.value;
      },


            
      isErase : function() {
        return isErase_element.checked
      }
    
    }
    initProject();
    return self;
  }
}
