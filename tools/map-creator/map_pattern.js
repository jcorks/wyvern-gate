Pattern = {
  new : function(canvas) {
    var chars = [];
    var wall = [];
    var connections = [];
    var connectionsNeeded = [];
    var undoController = UndoContext.new();
    var areaSet = AreaSet.new(canvas);
    var mapEvents = [];
    var mapObjects = [];
    var objects = {};
    var markers = [];
    var self;

    for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
      chars[i] = 0;
      wall[i] = false;
      connections[i] = null;
      connectionsNeeded[i] = null;
      markers[i] = null;
    }
    // messy quick save that wastes data but is perfect for undo / redo 
    const quickSave = function() {
      return [
        Array.from(chars),
        Array.from(wall),
        Array.from(connections),
        Array.from(connectionsNeeded),
        areaSet.getAreaState(),
        Array.from(mapEvents),
        Array.from(mapObjects),
        {...objects},
        Array.from(markers)
      ]
    }
    
    const quickLoad = function(state) {
      chars = state[0];
      wall = state[1];
      connections = state[2];
      connectionsNeeded = state[3];
      self.areaSet.setAreaState(state[4]);
      mapEvents = state[5];
      mapObjects = state[6];
      objects = state[7];
      markers = state[8];
      
      self.chars = chars;
      self.wall = wall;
      self.connections = connections;
      self.connectionsNeeded = connectionsNeeded;
      self.mapEvents = mapEvents;
      self.mapObjects = mapObjects;
      self.objects = objects;
      self.markers = markers;
    }
    
    
    self = {
      chars : chars,
      wall : wall,
      connections : connections,
      connectionsNeeded : connectionsNeeded,
      areaSet : areaSet,
      mapEvents : mapEvents,
      mapObjects : mapObjects,
      objects : objects,
      
      removeObject : function(name) {
        delete objects[name];
        for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
          if (mapObjects[i]) {
            const ref = mapObjects[i];
            const newRef = [];
            for(var n = 0; n < ref.length; ++n) {
              if (ref[n] != name) {
                newRef.push(ref[n]);
              }
            }
            
            if (newRef.length == 0) {
              mapObjects[i] = null;
            } else {
              mapObjects[i] = newRef;
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
          if (chars[i] || wall[i] || connections[i] || mapEvents[i] || mapObjects[i]) {
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
        out.mapEvents = [];
        out.mapObjects = [];
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
          
          if (typeof mapEvents[i] == 'string') {
            out.mapEvents.push([
              x - left,
              y - top,
              mapEvents[i]
            ]);
          }

          if (mapObjects[i] && (typeof mapObjects[i] == 'object')) {
            for(var n = 0; n < mapObjects[i].length; ++n) {
              out.mapObjects.push([
                x - left,
                y - top,
                mapObjects[i]
              ]);
            }
          }
        }
        
        // that simple?
        out.objects = objects;


        
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



        
        out.markers = [];
        for(var i = 0; i < markers.length; ++i) {
          const x = i % MAX_LENGTH
          const y = Math.floor(i / MAX_LENGTH);

          if (markers[i]) {
          
            out.markers.push([
              x - left,
              y - top,
              markers[i][0], // name
              markers[i][1] // string
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
        mapEvents = [];
        mapObjects = [];
        objects = {};
        markers = [];
        
        self.chars = chars;
        self.wall = wall;
        self.connections = connections;
        self.connectionsNeeded = connectionsNeeded;
        self.mapEvents = mapEvents;
        self.mapObjects = mapObjects;
        self.objects = objects;
        self.markers = markers;
            
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
        
        for(var i = 0; i < state.mapEvents.length; ++i) {
          const next = state.mapEvents[i];
          const x = next[0] + left;
          const y = next[1] + top;
          mapEvents[x + y * MAX_LENGTH] = next[2];
        }

        for(var i = 0; i < state.mapObjects.length; ++i) {
          const next = state.mapObjects[i];
          const x = next[0] + left;
          const y = next[1] + top;
          mapObjects[x + y * MAX_LENGTH] = next[2];
        }
        
        // temporary old version
        
        const keys = Object.keys(state.objects);
        for(var i = 0; i < keys.length; ++i) {
          const object = state.objects[keys[i]];
          if (object.haloMode == undefined) object.haloMode = 0;
          if (object.data == undefined) object.data = {};
          if (typeof (object.data) == 'string') object.data = {}
          if (object.symbol == undefined) object.symbol = '*'
          objects[keys[i]] = state.objects[keys[i]];
        }

        
        for(var i = 0; i < state.connectors.length; ++i) {
          const c = state.connectors[i];
          
          const x = c[0] + left;
          const y = c[1] + top;
          connections[x + y*MAX_LENGTH] = c[2];
          connectionsNeeded[x + y*MAX_LENGTH] = c[3];
        }

        for(var i = 0; i < state.markers.length; ++i) {
          const c = state.markers[i];
          
          const x = c[0] + left;
          const y = c[1] + top;
          markers[x + y*MAX_LENGTH] = [c[2], c[3]];
        }

      }
    };
    
    undoController.commitState(quickSave());
    
    return self;
  }
};
