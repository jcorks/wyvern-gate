Pattern = {
  new : function(canvas) {
    var chars = [];
    var wall = [];
    var connections = [];
    var connectionsNeeded = [];
    var undoController = UndoContext.new();
    var areaSet = AreaSet.new(canvas);
    var mapEntities = [];
    var mapLocations = [];
    var locations = {};
    var self;

    for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
      chars[i] = 0;
      wall[i] = false;
      connections[i] = null;
      connectionsNeeded[i] = null;
    }
    // messy quick save that wastes data but is perfect for undo / redo 
    const quickSave = function() {
      return [
        Array.from(chars),
        Array.from(wall),
        Array.from(connections),
        Array.from(connectionsNeeded),
        areaSet.getAreaState(),
        Array.from(mapEntities),
        Array.from(mapLocations),
        Array.from(locations)
      ]
    }
    
    const quickLoad = function(state) {
      chars = state[0];
      wall = state[1];
      connections = state[2];
      connectionsNeeded = state[3];
      self.areaSet.setAreaState(state[4]);
      mapEntities = state[5];
      mapLocations = state[6];
      locations = state[7];
      
      self.chars = chars;
      self.wall = wall;
      self.connections = connections;
      self.connectionsNeeded = connectionsNeeded;
      self.mapEntities = mapEntities;
      self.mapLocations = mapLocations;
      self.locations = locations;
    }
    
    
    self = {
      chars : chars,
      wall : wall,
      connections : connections,
      connectionsNeeded : connectionsNeeded,
      areaSet : areaSet,
      mapEntities : mapEntities,
      mapLocations : mapLocations,
      locations : locations,
      
      removeLocation : function(name) {
        delete locations[name];
        for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
          if (mapLocations[i]) {
            const ref = mapLocations[i];
            const newRef = [];
            for(var n = 0; n < ref.length; ++n) {
              if (ref[n] != name) {
                newRef.push(ref[n]);
              }
            }
            
            if (newRef.length == 0) {
              mapLocations[i] = null;
            } else {
              mapLocations[i] = newRef;
            }
          }
        }
      },

      save : function() {
        // first find the origin and bounds
        var left = MAX_LENGTH;
        var top = MAX_LENGTH;
        var right = 0;
        var bottom = 0;
        
        for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
          if (chars[i] || wall[i] || connections[i] || mapEntities[i] || mapLocations[i]) {
            const x = i % MAX_LENGTH
            const y = Math.floor(i / MAX_LENGTH);
            
            if (x < left) left = x
            if (y < top)  top = y;

            if (x > right)  right = x
            if (y > bottom) bottom = y;
          }
        }
        
        
        const out = {};
        out.top = top;
        out.left = left;
        out.width = right - left;
        out.height = bottom - top;
        
        // TODO
        out.rarity = 1;
        
        out.scenery = [];
        out.walls = [];
        out.mapEntities = [];
        out.mapLocations = [];
        for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
          const x = i % MAX_LENGTH
          const y = Math.floor(i / MAX_LENGTH);


          if (chars[i]) {
            out.scenery.push([
              x - left,
              y - top,
              chars[i]
            ]);
          }
          
          if (wall[i]) {
            out.walls.push([
              x - left,
              y - top
            ]);
          }          
          
          if (typeof mapEntities[i] == 'string') {
            out.mapEntities.push([
              x - left,
              y - top,
              mapEntities[i]
            ]);
          }

          if (mapLocations[i] && (typeof mapLocations[i] == 'object')) {
            for(var n = 0; n < mapLocations[i].length; ++n) {
              out.mapLocations.push([
                x - left,
                y - top,
                mapLocations[i]
              ]);
            }
          }
        }
        
        // that simple?
        out.locations = locations;


        
        out.areas = [];
        const areas = areaSet.areas;
        for(var i = 0; i < areas.length; ++i) {
          const area = areas[i];
          out.areas.push([
            area.x - left,
            area.y - top,
            area.w,
            area.h
          ]);
        }
        
         
        
        
        out.connectors = [];
        for(var i = 0; i < connections.length; ++i) {
          const x = i % MAX_LENGTH
          const y = Math.floor(i / MAX_LENGTH);

          const connection = connections[i];
          if (connection) {
          
            out.connectors.push([
              x - left,
              y - top,
              connections[i],
              connectionsNeeded[i]
            ]);
          }
          
        }
        
        
        return out;
        
      },
      
      commitChange : function() {
        undoController.commitState(quickSave());
      },
      
      undo : function() {
        const state = undoController.undo();
        if (state == false) return;
        quickLoad(state);
      },
      
      redo : function() {
        const state = undoController.redo();
        if (state == false) return;
        quickLoad(state);
      },
      
      load : function(state) {
        const top = state.top;
        const left = state.left;
        const width = state.width;
        const height = state.height;
        

        chars = [];
        wall = [];
        connections = [];
        connectionsNeeded = [];     
        mapEntities = [];
        mapLocations = [];
        locations = {};
        
        self.chars = chars;
        self.wall = wall;
        self.connections = connections;
        self.connectionsNeeded = connectionsNeeded;
        self.mapEntities = mapEntities;
        self.mapLocations = mapLocations;
        self.locations = locations;
            
        for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
          chars[i] = 0;
          wall[i] = false;
          connections[i] = null;
          connectionsNeeded[i] = null;
        }        
        
        const areas = state.areas;   
        
        areaSet.removeAll();
        for(var i = 0; i < areas.length; ++i) {
          const area = areas[i];
          areaSet.addArea(
            area[0] + left,
            area[1] + top,
            area[2],
            area[3]
          )
        }
        
        for(var i = 0; i < state.scenery.length; ++i) {
          const next = state.scenery[i];
          
          const x = next[0] + left;
          const y = next[1] + top;
          const ch = next[2];
          
          chars[x + y*MAX_LENGTH] = ch;
        }
        
        
        for(var i = 0; i < state.walls.length; ++i) {
          const next = state.walls[i];
          const x = next[0] + left;
          const y = next[1] + top;
          wall[x + y * MAX_LENGTH] = true;
        }
        
        for(var i = 0; i < state.mapEntities.length; ++i) {
          const next = state.mapEntities[i];
          const x = next[0] + left;
          const y = next[1] + top;
          mapEntities[x + y * MAX_LENGTH] = next[2];
        }

        for(var i = 0; i < state.mapLocations.length; ++i) {
          const next = state.mapLocations[i];
          const x = next[0] + left;
          const y = next[1] + top;
          mapLocations[x + y * MAX_LENGTH] = next[2];
        }
        
        // temporary old version
        if (!state.locations) {
          const token = 'IMPORTED';
          for(var i = 0; i < state.mapLocations.length; ++i) {
            const next = state.mapLocations[i];
            const x = next[0] + left;
            const y = next[1] + top;
            const name = token+next[2];
            mapLocations[x + y * MAX_LENGTH] = [name];
            
            locations[name] = {
              id : next[2],
              symbol: '.'
            }
          }
          
          
        } else {
          const keys = Object.keys(state.locations);
          for(var i = 0; i < keys.length; ++i) {
            locations[keys[i]] = state.locations[keys[i]];
          }
        }

        
        for(var i = 0; i < state.connectors.length; ++i) {
          const c = state.connectors[i];
          
          const x = c[0] + left;
          const y = c[1] + top;
          connections[x + y*MAX_LENGTH] = c[2];
          connectionsNeeded[x + y*MAX_LENGTH] = c[3];
        }
      }
    };
    
    undoController.commitState(quickSave());
    
    return self;
  }
};
