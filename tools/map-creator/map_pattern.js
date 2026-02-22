Pattern = {
  new : function() {
  
    var chars = [];
    var wall = [];
    var connections = [];
    var connectionsNeeded = [];
    var areas = [];
    var undoController = UndoContext.new();
    var areaSet = AreaSet.new(self);

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
        Array.from(areas),
      ]
    }
    
    const quickLoad = function(state) {
      chars = state[0];
      wall = state[1];
      connections = state[2];
      connectionsNeeded = state[3];
      areas = state[4];
      
      self.chars = chars;
      self.wall = wall;
      self.connections = connections;
      self.connectionsNeeded = connectionsNeeded;
      self.areas = areas;
    }
    
    
    var self = {
      chars : chars,
      wall : wall,
      connections : connections,
      connectionsNeeded : connectionsNeeded,
      areas : areas,

      save : function() {
        // first find the origin and bounds
        var left = MAX_LENGTH;
        var top = MAX_LENGTH;
        var right = 0;
        var bottom = 0;
        
        for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
          if (chars[i] > 0 || wall[i] != false || connections[i] != null) {
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
        for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
          if (chars[i] != 0) {
            const x = i % MAX_LENGTH
            const y = Math.floor(i / MAX_LENGTH);
            out.scenery.push([
              x - left,
              y - top,
              chars[i]
            ]);
          }
          
          
          if (walls[i] != false) {
            const x = i % MAX_LENGTH
            const y = Math.floor(i / MAX_LENGTH);
            out.walls.push([
              x - left,
              y - top
            ]);
          }          
        }
        
        // TODO
        out.mapEntities = [];
        
        out.areas = [];
        for(var i = 0; i < out.areas.length; ++i) {
          const area = areas[i];
          out.areas.push([
            area.x - left,
            area.y - top,
            area.width,
            area.height
          ]);
        }
        
        out.mapEntities = [],
        
        
        
        out.connectors = [];
        for(var i = 0; i < connections.length; ++i) {
          const x = i % MAX_LENGTH
          const y = Math.floor(i / MAX_LENGTH);

          const connection = connections[i];
          
          out.connectors.push([
            x,
            y,
            connections[i],
            connectionsNeeded[i]
          ]);
          
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

      }
    };
    
    undoController.commitState(quickSave());
    
    return self;
  }
};
