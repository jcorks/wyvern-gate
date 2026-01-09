const Palette = {
  new : function() {
    var lastPicked;
    const div = document.createElement('div');
    div.style.fontSize = ''+CHAR_FONT_WIDTH_PX+'px';  
    div.style.overflow = 'scroll';
    
    const events = EventSystem.new(['onSelect']);
    
    
    const createButton = function(div, c) {
      const button = document.createElement('div');
      const buttonTextHolder = document.createElement('div');
      

      button.realText = c;
      if (c == ' ')
        c = '\' \'';

      button.style.margin = '2px';
      button.style.padding = '20px';
      button.style.float = 'left';
      button.style.border = '2px';
      button.style.borderColor = 'white';
      button.style.fontFamily = 'gamefont';
      //button.style.whiteSpace = 'pre';
      buttonTextHolder.style.border = '1px';
      buttonTextHolder.style.borderColor = 'black';
      buttonTextHolder.style.borderStyle = 'solid';
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
        events.emit('onSelect');
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

    for(var i = 0x2500; i <= 0x257f; ++i) {
      var c = String.fromCharCode(i);
      const b = createButton(div, c);
    }
    

    return {
      getElement : function() {
        return div;
      },
      
      getEvents : function() {
        return events;
      },
    
      getSelected : function() {
        return lastPicked.realText;
      }
    }
  }
}
