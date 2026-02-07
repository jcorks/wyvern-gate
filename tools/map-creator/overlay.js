const distance = function(x0, y0, x1, y1) {
  const x = (x1 - x0)
  const y = (y1 - y0);
  return Math.sqrt(x*x + y*y);
}

const Overlay = (function() {
    const overlays = [];
    


    var selected;
    window.addEventListener("mouseup", function(evt) {
      if (selected == undefined) return;
      selected.letGo();
      selected = undefined;
    })

    window.addEventListener("mousemove", function(evt) {
      if (selected) {
        if (selected.isResizing()) {
          selected.stretch(evt.x, evt.y);
          return;
        }
      
        selected.drag(evt.x, evt.y);
      }
    })


  return {
    // color is [r, g, b];
    new : function(color) {
      var instance;
      var el = document.createElement('div');
      el.style.position = 'absolute';
      
      var x_ = 0;
      var y_ = 0;
      var x1_ = 0;
      var y1_ = 0;
      
      
      
      const commitSize = function() {
        var x = x_;
        var y = y_;
        var x1 = x1_;
        var y1 = y1_;


        if (x1 < x) {
          const temp = x1;
          x1 = x;
          x = temp;
        }
        
        if (y1 < y) {
          const temp = y1;
          y1 = y;
          y = temp;        
        }
        
        const w = x1 - x;
        const h = y1 - y;
        
        
      
        el.style.left = ""+x+"px";
        el.style.width = ""+w+"px";
        el.style.top = ""+y+"px";
        el.style.paddingTop = ""+h+"px";
        el.style.zIndex = 1000;
      }
      el.style.borderColor = 'rgba(' + color[0] + ',' + color[1] + ',' + color[2] + ', 1.0)';
      el.style.borderStyle = 'solid';
      el.style.borderSize = '1px';
      el.style.backgroundColor = 'rgba(' + color[0] + ',' + color[1] + ',' + color[2] + ', 0.2)';
      
      document.body.appendChild(el);

      
      var data = {};
      var events = EventSystem.new(['onRelease']);

      var entered = false;
      var pressed = false;
      var pressedX = 0;
      var pressedY = 0;
      var resizing = false;


      el.addEventListener("mouseleave", function(evt) {
        entered = false;
      })


      el.addEventListener("mouseenter", function(evt) {
        entered = true;
      })


      el.addEventListener("mousedown", function(evt) {
        if (entered || selected == instance) {
          selected = instance;
          pressed = true;
          pressedX = evt.x;
          pressedY = evt.y;
        }
        
        // resize grab
        if (distance(evt.x, evt.y, x1_, y1_) < 35) {
          resizing = true;
        } 
      })
      
      




      el.addEventListener("contextmenu", function(evt) {
        evt.preventDefault();
        events.emit('onContext', packArgument(c));
        return true;
      });
      

    
      commitSize();
      instance = {
        disablePointer : function() {
          el.style.pointerEvents = "none";
        },

        enablePointer : function() {
          el.style.pointerEvents = "initial";
        },
        
        drag : function(x, y) {
          if (selected != instance) return;
          if (resizing) return;
          
          
          let diffX = x - pressedX;
          let diffY = y - pressedY;

          x_ += diffX;
          x1_ += diffX;
          y_ += diffY;
          y1_ += diffY;
          
          commitSize();
        
          pressedX = x;
          pressedY = y;
        
        },
        
        stretch : function(x, y) {
          if (!resizing) return;
          
          
          let diffX = x - pressedX;
          let diffY = y - pressedY;

          x1_ += diffX;
          y1_ += diffY;
          
          commitSize();
        
          pressedX = x;
          pressedY = y;
        
        },
        
        events : events,

        letGo : function() {
          if (selected == instance) {
            events.emit('onRelease');
            pressed = false;
            resizing = false;
          }
        },
      
        hide : function() {
          el.style.display = 'none';
        },
        
        show : function() {
          el.style.display = "initial";
        },
        
        isShown : function() {
          return el.style.display != 'none';
        },
        
        reset : function() {
          x_ = 0;
          y_ = 0;
          x1_ = 0;
          y1_ = 0;
          commitSize();
        },
        
        getX : () => x_,
        getY : () => y_,
        getWidth : () => x1_ - x_,
        getHeight : () => y1_ - y_,
        
        setP0 : function(x, y) {
          x_ = x;
          y_ = y;
          commitSize();
        },
        
        isResizing : function() {
          return resizing
        },

        setP1 : function(x, y) {
          x1_ = x;
          y1_ = y;
          commitSize();
        },
        
        getData : function() {
          return data;
        },
      
      
        remove : function() {
          document.body.removeChild(el);
          el = null;
        }
      }
      
      overlays.push(instance);
      return instance;
    }
  }
})();
