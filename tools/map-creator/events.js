
const EventSystem = {
  new : function(events) {
    var self;
    var listeners = {};
    
    for(var i = 0; i < events.length; ++i) {
      listeners[events[i]] = []
    }
    
    
    self = {
      addCallback : function(name, fn) {
        var list = listeners[name];
        if (list == null) {
          throw new Error('No such event ' + name);
        }
        list.push(fn);
      },
      
      emit : function(name, data) {
        var list = listeners[name];
        if (list == null) {
          throw new Error('No such event ' + name);
        }  
        
        for(var i = 0; i < list.length; ++i) {
          list[i](data);
        }
      }
    }
    
    return self;
  }
}
