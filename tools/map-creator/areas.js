const AreaSet = {
  new : function(canvas) {
    const areas = [];
    var self;
    
    
    // always in character indexes (map space)
    const makeArea = function(x, y, w, h) {
      return {
        x : x,
        y : y
      }
    }
    
        
    canvas.events.addCallback('onMove', function() {
      for(var i = 0; i < areas.length; ++i) {
        areas[i].updateOverlay();
      }
    });


    
    self = {
      hide : function() {
          for(var i = 0; i < areas.length; ++i) {
              areas[i].overlay.hide();
          }
      },
      
      show : function() {
          for(var i = 0; i < areas.length; ++i) {
              areas[i].overlay.show();
          }
          
      },
    
      addArea : function(x, y, w, h) {
        const area = {
          x: x,
          y: y,
          w: 10,
          h: 10,
          
          overlay : Overlay.new([255, 205, 205]),
          
          updateOverlay : function() {
            const p0 = canvas.mapPositionToClient(area.x, area.y);
            const p1 = canvas.mapPositionToClient(area.x + area.w, area.y + area.h);
            
            if (p0 == undefined && p1 == undefined) {
              area.overlay.hide();
            } else {
              area.overlay.show();
              area.overlay.setP0(p0.x, p0.y);
              area.overlay.setP1(p1.x, p1.y);
            }
          },
          
          updateFromOverlay : function() {
            const overlay = area.overlay;
            const p0 = canvas.clientPositionToMap(overlay.getX(), overlay.getY());
            const p1 = canvas.clientPositionToMap(overlay.getX()+overlay.getWidth(), overlay.getY()+overlay.getHeight());

            if (p0 == undefined || p1 == undefined) {
              return;
            }


            area.x = p0.x;
            area.y = p0.y;
            area.w = p1.x - p0.x;
            area.h = p1.y - p0.y;
            
            area.updateOverlay(); // rematch just in case.          
          }
        }
        
        
        // response to move + resize by user
        area.overlay.events.addCallback('onRelease', function() {
          area.updateFromOverlay();
        });  
        
        area.updateOverlay();     
        areas.push(area);
        return area;
      }
      
    }
    return self;
  }
}
