
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
      'onClick'
    ]);
    

    

    v.style.fontFamily = 'gamefont';
    v.style.zIndex = 100-zIndex;
    v.style.position = "relative";
    //v.style.top = "-2px";
    v.style.top = '-' + (zIndex*2) + 'px'

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
    for(var i = 0; i < VIEW_WIDTH; ++i) {
      const c = document.createElement('h');
      c.style.margin = '0px';
      c.style.whiteSpace = 'pre';
      c.style.fontFamily = 'gamefont';
      c.style.fontSize = '19px'

      c.index = i;
      v.appendChild(c);
      chars[i] = c;
      setChar(i, '`', TEXT_COLOR_INACTIVE);
      
      
      c.addEventListener("mouseenter", function(evt) {
        lastHovered = chars[i];
        
        c.style.backgroundColor = TEXT_COLOR_ACTIVE;
        c.style.color = BACKGROUND_COLOR;
      })

      c.addEventListener("mouseleave", function(evt) {

        c.style.backgroundColor = BACKGROUND_COLOR;
        c.style.color = c.colorStore;;
        lastHovered = null;
      })

      c.addEventListener("mousemove", function(evt) {
        if (evt.buttons != 0) {
          events.emit('onClick', {index:c.index, line:self});
        }
      })

      c.addEventListener("click", function(evt) {
        events.emit('onClick', {index:c.index, line:self});
      })


    }


      
    self  = {
      getElement : function() {
        return v;
      },
      getChar : function(x) {
        return chars[x];
      },

      events : events,

      editChar : function(index, ch, color) {
        if (ch == null)
          ch = chars[index]
        if (ch == 0) {
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
