const VIEW_WIDTH  = 80;
const VIEW_HEIGHT = 22;
const CHAR_FONT_WIDTH_PX = 16;

const BACKGROUND_COLOR = "#303030";
const TEXT_COLOR_ACTIVE = "#afafaf";
const TEXT_COLOR_INACTIVE = "#505050";


const BUTTON_COLOR_ACTIVE   = "#b0b0b0"
const BUTTON_COLOR_INACTIVE = "#606060"


document.body.style.backgroundColor = BACKGROUND_COLOR;
document.body.style.color = TEXT_COLOR_ACTIVE;
document.body.style.fontFamily = 'Monospace';


canvas = (function() {
  // Class containing a row of text
  const Line = {
    create : function() {
      const v = document.createElement('div');

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
      const enterCBs = [];
      const leaveCBs = [];
      const clickCBs = [];
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
          
          for(var n = 0; n < enterCBs.length; ++n) {
            enterCBs[n](c.index);
          }
        })

        c.addEventListener("mouseleave", function(evt) {

          c.style.backgroundColor = BACKGROUND_COLOR;
          c.style.color = (c.active) ? TEXT_COLOR_ACTIVE : TEXT_COLOR_INACTIVE;

          lastHovered = null;
          for(var n = 0; n < leaveCBs.length; ++n) {
            leaveCBs[n](c.index);
          }
        })

        c.addEventListener("mousemove", function(evt) {
          if (evt.buttons != 0) {
            for(var n = 0; n < clickCBs.length; ++n) {
              clickCBs[n](c.index);
            }
          }
        })

        c.addEventListener("click", function(evt) {
          for(var n = 0; n < clickCBs.length; ++n) {
            clickCBs[n](c.index);
          }
        })


      }


        
      return {
        getElement : function() {
          return v;
        },
        // returns the raw character array
        setState : function(
          lineArray
        ) {
          for(var i = 0; i < lineArray.length; ++i) {
            if (chars[i] == null) continue;
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
        
        // add a callback for when a specific character is entered.
        addEnterCallback : function(s) {
          enterCBs.push(s)
        },

        // when leaving a ch
        addLeaveCallback : function(s) {
          enterCBs.push(s)
        },

        addClickCallback : function(s) {
          clickCBs.push(s)
        },
        
        // 
        editChar : function(index, ch) {
          setChar(chars[index], ch[0]);
        }
      }
    }
  };

  const createStatus = function() {
    const div = document.createElement('div');
    div    
  }
  
  const createPalette = function() {
    var lastPicked;
    const div = document.createElement('div');
    div.style.fontSize = ''+CHAR_FONT_WIDTH_PX+'px';  
    div.style.overflow = 'scroll';
    
    const createButton = function(div, c) {
      const button = document.createElement('div');
      const buttonTextHolder = document.createElement('div');
      

      button.realText = c;
      if (c == '' || c == ' ')
        c = '\' \'';

      button.style.margin = '2px';
      button.style.padding = '20px';
      button.style.float = 'left';
      button.style.border = '2px';
      button.style.borderColor = 'white';
      //button.style.whiteSpace = 'pre';
      buttonTextHolder.innerText = c;
      button.style.backgroundColor = BUTTON_COLOR_INACTIVE
      button.appendChild(buttonTextHolder);

      button.addEventListener('click', function() {
        if (lastPicked) {
          lastPicked.style.backgroundColor = BUTTON_COLOR_INACTIVE
          lastPicked.style.color = TEXT_COLOR_ACTIVE;
        }
        button.style.backgroundColor = BUTTON_COLOR_ACTIVE;
        button.style.color = TEXT_COLOR_INACTIVE;
        lastPicked = button;
      });
      div.appendChild(button);

      document.body.addEventListener('load', function() {
        buttonTextHolder.style.marginRight= '-' + buttonTextHolder.clientWidth + 'px';      
      });
      buttonTextHolder.style.position = 'absolute';
            
      return button;
    }
    
    
    const buttons = [];
    for(var i = 32; i <= 126; ++i) {
      var c = String.fromCharCode(i);
      const b = createButton(div, c);

    }

    for(var i = 0x2580; i <= 0x259f; ++i) {
      var c = String.fromCharCode(i);
      const b = createButton(div, c);
    }

    

    return {
      getElement : function() {
        return div;
      },
    
      getSelected : function() {
        return lastPicked.realText;
      }
    }
  }


  var canvasChars = [];
  const lines = [];
  const main = document.createElement('div');

  main.style.userSelect = "none";
  main.style.fontSize = ''+CHAR_FONT_WIDTH_PX+'px';  


  for(var i = 0; i < VIEW_HEIGHT; ++i) {
    const line = Line.create();
    const v = line.getElement();

    line.addClickCallback(function(x) {
      line.editChar(x, palette.getSelected());
    });

    var row = i;
    main.appendChild(v);
    lines[i] = line;
  }

  const palette = createPalette();
  main.appendChild(palette.getElement());
  
  
  return {
    getMain : function() {
      return main;
    }
  }
})()
