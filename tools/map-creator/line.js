
// Class containing a row of text
/*
  Events:
  
  onClick(line_
*/

const Line = {
  new : function(zIndex) {
    var self;

    const v = document.createElement('div');
    const events = EventSystem.new([
      'onClick',
      'onEnter',
      'onLeave',
      'onRelease',
      'onDown',
      'onContext'
    ]);
    

    

    v.style.fontFamily = 'gamefont';
    v.style.zIndex = 100-zIndex;
    v.style.position = "relative";
    v.style.height = "19px";
    //v.style.top = "-2px";
    //v.style.top = '-' + (zIndex*2) + 'px'

    const setChar = function(index, ch, color) {
      const c = chars[index];

      c.active = true;
      c.innerText = ch;
      c.style.color = color;
      c.colorStore = c.style.color;
    }
    
    const getChar = function(c) {
      if (c.active == false) {
        return c.innerText;
      } else {
        return null;
      }
    }

    

  
    const chars = [];
    var lastHovered;
    var displayLine;
    
    const packArgument = function(c) {
      return {
        index:c.index, 
        line:self, 
        x:c.offsetLeft+ v.offsetLeft, 
        y:c.offsetTop + v.offsetTop     
      }
    }
    
    for(var i = 0; i < VIEW_WIDTH; ++i) {
      const c = document.createElement('h');
      c.style.margin = '0px';
      c.style.whiteSpace = 'pre';
      c.style.fontFamily = 'gamefont';
      c.style.fontSize = '20px'
      c.style.position = 'relative';
      c.style.display = 'inline-block';
      c.style.width = '9px';

      c.index = i;
      v.appendChild(c);
      chars[i] = c;
      setChar(i, '`', TEXT_COLOR_INACTIVE);
      
      
      c.addEventListener("mouseenter", function(evt) {
        lastHovered = chars[i];
        
        c.style.backgroundColor = TEXT_COLOR_ACTIVE;
        c.style.color = BACKGROUND_COLOR;
        events.emit('onEnter', packArgument(c));
      })

      c.addEventListener("mouseleave", function(evt) {

        c.style.backgroundColor = BACKGROUND_COLOR;
        c.style.color = c.colorStore;;
        lastHovered = null;
        events.emit('onLeave', packArgument(c));
      })

      c.addEventListener("mousemove", function(evt) {
        if (evt.buttons & 0x1) {
          events.emit('onClick', packArgument(c));
        }
      })

      c.addEventListener("mouseup", function(evt) {
        if (evt.button != 0) return;
        events.emit('onRelease', packArgument(c));
      })

      c.addEventListener("mousedown", function(evt) {
        if (evt.button != 0) return;
        events.emit('onDown', packArgument(c));
      })
      


      c.addEventListener("click", function(evt) {
        events.emit('onClick', packArgument(c));
      })

      c.addEventListener("contextmenu", function(evt) {
        evt.preventDefault();
        events.emit('onContext', packArgument(c));
        return true;
      });
    }


      
    self  = {
      getElement : function() {
        return v;
      },
      getChar : function(x) {
        return chars[x];
      },
      
      setTooltip : function(x, text) {
        chars[x].tooltip = text;
      },
      
      clearTooltip : function(x) {
        delete chars[x].tooltip
      },

      events : events,
      
      aliasPoint : function(x, y) {

        for(var i = 0; i < chars.length; ++i) {
          let c = chars[i];
          let cRect = c.getBoundingClientRect();
          
          
          if (x >= cRect.x && x < cRect.x + cRect.width &&
              y >= cRect.y && y < cRect.y + cRect.height) {
            return {
              x : cRect.x,
              y : cRect.y,
              index : i
            };
          }
        }
      },

      editChar : function(index, ch, color) {
        if (ch == null)
          ch = chars[index]
        if (ch === 0) {
          ch = '`';
        }
        setChar(index, ch[0], color);
      },
      
      erase : function(index) {
        setChar(index, '`', TEXT_COLOR_INACTIVE);      
      }
    }
    
    return self;
  }
}
