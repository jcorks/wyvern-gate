Pattern = {
  new : function() {
  
    var chars = [];
    var wall = [];
    var connections = [];
    var areas = [];
    var undo = UndoContext.new();

    for(var i = 0; i < MAX_LENGTH*MAX_LENGTH; ++i) {
      chars[i] = 0;
      wall[i] = false;
      connections[i] = null;
    }

    
    
    var self = {
      chars : chars,
      wall : wall,
      connections : connections,
      areas : areas,
      
      save : function() {
        return [
          Array.from(chars),
          Array.from(wall),
          Array.from(connections),
          Array.from(areas),
        ]
      },
      
      undoController : undo,
      
      load : function(state) {
        chars = state[0];
        wall = state[1];
        connections = state[2];
        areas = state[3];
        
        self.chars = chars;
        self.wall = wall;
        self.connections = connections;
        self.areas = areas;
      }
    };
    
    self.undoController.commitState(self.save());
    
    return self;
  }
};
