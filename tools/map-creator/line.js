
// Class containing a row of text
/*
  Events:
  
  onClick(line_
*/

const Line = {
  new : function() {
    var self;
    const v = document.createElement('div');
    const events = EventSystem.new([
      'onClick'
    ]);

    v.style.fontFamily = 'Monospace';

    const setChar = function(c, ch) {
      if (typeof(ch) != "string") {
        c.active = false;
        c.innerText = '`';
        c.style.color = TEXT_COLOR_INACTIVE
      } else {
        c.active = true;
        c.innerText = ch;
        c.style.color = TEXT_COLOR_ACTIVE   
      }
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
      const c = document.createElement('code');
      c.style.margin = '0px';
      c.style.whiteSpace = 'pre';

      c.index = i;
      setChar(c, 0);
      v.appendChild(c);
      chars[i] = c;
      c.addEventListener("mouseenter", function(evt) {
        lastHovered = chars[i];
        
        c.style.backgroundColor = TEXT_COLOR_ACTIVE;
        c.style.color = BACKGROUND_COLOR;
      })

      c.addEventListener("mouseleave", function(evt) {

        c.style.backgroundColor = BACKGROUND_COLOR;
        c.style.color = (c.active) ? TEXT_COLOR_ACTIVE : TEXT_COLOR_INACTIVE;

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
      // returns the raw character array
      setState : function(
        lineArray
      ) {
        for(var i = 0; i < lineArray.length; ++i) {
          setChar(chars[i], lineArray[i]);
        }
      },
      
      // returns an array of the elements of the line.
      // for characters unset
      fetchState : function() {
        const out = [];
        for(var i = 0; i < chars.length; ++i) {
          out[i] = chars[i].innerText
        }
      },
      
      events : events,

      
      // 
      editChar : function(index, ch) {
        setChar(chars[index], ch[0]);
      }
    }
    
    return self;
  }
}
