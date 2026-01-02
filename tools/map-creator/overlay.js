const Overlay = {
  // color is [r, g, b];
  new : function(color) {
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

  
    commitSize();
    return {
      disablePointer : function() {
        el.style.pointerEvents = "none";
      },

      enablePointer : function() {
        el.style.pointerEvents = "initial";
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
      
      setP0 : function(x, y) {
        x_ = x;
        y_ = y;
        commitSize();
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
  }
}
