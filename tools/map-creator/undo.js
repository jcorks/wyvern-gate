const UndoContext = {
  new : function() {
    // state as JSON strings
    const stack = [];
    // points to the NEXT index of a state
    var pointer = 0;
    
    
    
    return {
      commitState : function(state) {
        // shaves off the previous undo state
        stack.length = pointer;
        stack.push(JSON.stringify(state));
        pointer ++;
        
        console.log('UNDO COMMIT: ' + stack.length + '-' + pointer);
      },
      
      reset : function() {
        stack.length = 0;
        pointer = 0;
      },
      
      undo : function() {
        if (pointer == 1) return false;
        pointer --;
        console.log('UNDO UNDO: ' + stack.length + '-' + pointer);
        return JSON.parse(stack[pointer-1]);
      },
      redo : function() {
        if (pointer == stack.length) return false;
        const output = stack[pointer];
        pointer++;
        console.log('UNDO REDO: ' + stack.length + '-' + pointer);
        return JSON.parse(output);
      }
    }
  }
}
