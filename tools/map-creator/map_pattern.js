Pattern = {
  new : function() {
  
    var chars = [];
    var wall = [];
    var connections = [];
    var areas = [];
    var undoController = UndoContext.new();

    for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
      chars[i] = 0;
      wall[i] = false;
      connections[i] = null;
    }
    // messy quick save that wastes data but is perfect for undo / redo 
    const quickSave = function() {
      return [
        Array.from(chars),
        Array.from(wall),
        Array.from(connections),
        Array.from(areas),
      ]
    }
    
    const quickLoad = function(state) {
      chars = state[0];
      wall = state[1];
      connections = state[2];
      areas = state[3];
      
      self.chars = chars;
      self.wall = wall;
      self.connections = connections;
      self.areas = areas;
    }
    
    
    var self = {
      chars : chars,
      wall : wall,
      connections : connections,
      areas : areas,
      /*
        {
          "left" : Number,
          "top"  : Number,
          "width" : Number,
          "height" : Number,
          
          // (from topleft)
          chars : Array,
          
          // 0 or 1 for more compact JSON
          wall : Array, 
          
          // [x, y, id]
          connections : Array,
          
          // [top, left, width, height], topleft relative to topleft of entire pattern
          areas : Array
        }
      */
      save : function() {
        // first find the origin and bounds
        
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
