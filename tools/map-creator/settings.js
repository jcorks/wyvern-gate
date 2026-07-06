const Settings = {
  MODE : {
    PEN : 0,
    WALL : 1,
    SELECTOR : 2,
    AREA_EDITOR : 3,
    CONNECTIONS : 4,
    OBJECTS : 5,
    EVENTS : 6,
    MARKERS : 7
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
    
    var rebuildObjectPulldown;
    
    

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
      hideSet(cursorOptions_events_set);
      hideSet(cursorOptions_markers_set);
      hideSet(cursorOptions_markersData_set);
      hideSet(cursorOptions_objectsOptions_set);
      hideSet(cursorOptions_objectsPulldown_set);
      hideSet(cursorOptions_objectsInfo_set);
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

        case 'Objects': 
          showSet(cursorOptions_objectsOptions_set);
          showSet(cursorOptions_objectsPulldown_set);
          showSet(cursorOptions_objectsInfo_set);
          showSet(cursorOptions_isErase_set);
          break;

        case 'Events': 
          showSet(cursorOptions_events_set);
          showSet(cursorOptions_isErase_set);
          break;

        case 'Markers': 
          showSet(cursorOptions_markers_set);
          showSet(cursorOptions_markersData_set);
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

                try {
                  window.localStorage.setItem(ch, value);
                } catch(e) {
                  window.localStorage.removeItem(ch);
                  rebuildProjectPulldown();
                  self.loadProjectName(ch);
                  
                  window.alert('The map could not be loaded.');
                }
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
            rebuildObjectPulldown();
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
        const objectX_element = document.createElement('input');
        const objectY_element = document.createElement('input');
        objectX_element.type = 'number';
        objectY_element.type = 'number';
        objectX_element.value = 0;
        objectY_element.value = 0;
        objectX_element.style.width = "70px";
        objectY_element.style.width = "70px";


        // make ui elements
        makeRow([
          makeLabel('View object:'),
          objectX_element,
          objectY_element
        ]);

        // make connections
        canvas.events.addCallback('onMove', function() {
          objectX_element.value = canvas.getViewX()
          objectY_element.value = canvas.getViewY()
        });
        
        objectX_element.addEventListener('change', function() {
          xRange.value = objectX_element.value;
          xRange.dispatchEvent(new Event("change"));
        });
        objectY_element.addEventListener('change', function() {
          yRange.value = objectY_element.value;
          yRange.dispatchEvent(new Event("change"));
        });
 
        
    // Cursor Mode
        const modes = [
          'Pen',
          'Wall',
          'Selector', 
          'Area Editor',
          'Connectors',
          'Objects',
          'Events',
          'Markers'
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
        
    // Objects
        var objectPulldown_element = document.createElement('select');;
        const objectID_element = document.createElement('input');
        objectID_element.size = 8;
        const objectSymbol_element = document.createElement('input');
        objectSymbol_element.size = 2;
        const objectData_element = document.createElement('button');
        objectData_element.innerText = 'Set Data...'
        objectData_element.addEventListener('click', function(ev) {
          const pattern = canvas.getPattern();
          const which = pattern.objects[objectPulldown_element.value];
          const data = window.prompt("Enter the JSON data string for this object to be available during runtime.");          
          try {
            which.data = JSON.parse(data);
            pattern.commitChange();
            canvas.refresh();
          } catch(e) {
            window.alert('The data entered could not be parsed into valid JSON. It might be easiest if you type the JSON in a text editor, verify it, then paste it here.');
          }
        });
        const objectHalo_element = document.createElement('select');
        objectHalo_element.type = 'checkbox';
        const objectHalo_element_keys = ['Default Halo', 'Show Halo', 'Hide Halo']
        setDropDownOptions(objectHalo_element, objectHalo_element_keys);

        objectHalo_element.addEventListener("change", function() {
          const pattern = canvas.getPattern();
          const which = pattern.objects[objectPulldown_element.value];

          which.haloMode = objectHalo_element_keys.indexOf(objectHalo_element.value);          
          pattern.commitChange();
          canvas.refresh();
        
        });



        objectID_element.addEventListener("change", function() {
          const pattern = canvas.getPattern();
          const which = pattern.objects[objectPulldown_element.value];

          which.id = objectID_element.value;          
          pattern.commitChange();
          canvas.refresh();
        });


        objectSymbol_element.addEventListener("change", function() {
          const pattern = canvas.getPattern();
          const which = pattern.objects[objectPulldown_element.value];

          which.symbol = objectSymbol_element.value;          
          pattern.commitChange();
          canvas.refresh();
        });




        
        const updateObjectTags = function() {
          const pattern = canvas.getPattern();
          const which = pattern.objects[objectPulldown_element.value];
          
          if (!which) return;
          objectSymbol_element.value = which.symbol;
          objectID_element.value = which.id;        
          objectData_element.value = which.data;
          objectHalo_element.value = objectHalo_element_keys[which.haloMode];
        }        
        
        rebuildObjectPulldown = function() {
          const pattern = canvas.getPattern();
          if (!pattern) return;
          const keys = Object.keys(pattern.objects);
          setDropDownOptions(objectPulldown_element, keys);
          updateObjectTags();
        }


        objectPulldown_element.addEventListener("change", function() {
          updateObjectTags();
        })


        
        const objectNew_element = makeButton('New', function() {
          const pattern = canvas.getPattern();
          const name = window.prompt("Enter the name that uniquely defines this object");          
          if (typeof name != 'string') return; 
          
          if (pattern.objects[name] != null) {
            if (!window.confirm(name + ' already exists. Replace?')) return;
          }
          
          pattern.objects[name] = {
            id: 'base:none',
            symbol : '*',
            haloMode : 0,
            data : '{}'
          }
          rebuildObjectPulldown();
        
        });
        const objectRemove_element = makeButton('Remove', function() {
          const pattern = canvas.getPattern();
          if (!pattern) return;

          const name = objectPulldown_element.value;
          if (!window.confirm("Really remove object " + name + "? This is not undoable.")) return;

          pattern.removeObject(name);
          rebuildObjectPulldown();        
        });
        const objectClone_element = makeButton('Clone', function() {
          const pattern = canvas.getPattern();
          const name = window.prompt("Enter the name that uniquely defines this cloned object");          
          const source = objectPulldown_element.value
          if (typeof name != 'string') return; 
          if (name == source) return;

          
          pattern.objects[name] = {
            id: pattern.objects[source].id,
            symbol : pattern.objects[source].symbol,
            haloMode : pattern.objects[source].haloMode,
            data : pattern.objects[source].data
          }
          rebuildObjectPulldown();
        
        });




    
        cursorOptions_objectsPulldown_set = makeRow([
          makeLabel(''),
          objectPulldown_element,
          makeLabel(''),
        ]);
        
        cursorOptions_objectsOptions_set = makeRow([
          makeLabel(''),
          objectNew_element,
          objectClone_element,
          objectRemove_element,
        ]);

        cursorOptions_objectsInfo_set = makeRow([
          makeLabel(''),
          makeLabel('ID'),
          objectID_element,
          makeLabel('Symbol'),
          objectSymbol_element,
          objectHalo_element,
          makeLabel('Data'),
          objectData_element
        ]);





    // Events
        eventsID_element = document.createElement('input');
    
        cursorOptions_events_set = makeRow([
          makeLabel(''),
          makeLabel('ID:'),
          eventsID_element,
        ]);

    // Markers
        markersID_element = document.createElement('input');
        cursorOptions_markers_set = makeRow([
          makeLabel(''),
          makeLabel('ID:'),
          markersID_element,
        ]);

        markersData_element = document.createElement('input');
        cursorOptions_markersData_set = makeRow([
          makeLabel(''),
          makeLabel('Data:'),
          markersData_element,
        ]);



        
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
        rebuildObjectPulldown();
        updateLayout();
      },
      
      setMode : function(i) {
        cursorMode_element.value = modes[i];
        updateLayout();
      },
      
      getMode : function() {
        return modes.indexOf(cursorMode_element.value)
      },
      
      getEventID : function() {
        return eventsID_element.value
      },

      getMarkerID : function() {
        return markersID_element.value
      },

      getMarkerData : function() {
        return markersData_element.value
      },


      getObjectName : function() {
        return objectPulldown_element.value
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
