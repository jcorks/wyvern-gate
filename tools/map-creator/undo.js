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
      },
      undo : function() {
        if (pointer == 0) return false;
        pointer --;
        return JSON.parse(stack[pointer]);
      },
      redo : function() {
        if (pointer == stack.length) return false;
        const output = stack[pointer];
        pointer++;
        return JSON.parse(output);
      }
    }
  }
}
