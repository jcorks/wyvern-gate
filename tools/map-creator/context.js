const ContextMenu = (function() {
  var div;
  
  
  return function(
    xpos, 
    ypos,
    
    options
  ) {
    if (div) document.body.removeChild(div);

  
    div = document.createElement("div");
    div.style.position = 'absolute';
    div.style.fontSize = '14px';
    div.style.backgroundColor = 'rgba(0, 0, 0, 0.8)';
    div.style.color = 'rgb(200, 200, 200)';
    div.style.zIndex = 2000;
    
    const createButton = function(name, callback) {
      const d = document.createElement("div");
      d.style.margin = '4px';
      d.innerText = name;
      div.appendChild(d);
      d.addEventListener("click", function() {
        callback();
        document.body.removeChild(div);
        div = null;
      });
      
      d.addEventListener("mouseenter", function() {
        d.style.backgroundColor = 'rgba(255, 255, 255, 0.3)'
      });

      d.addEventListener("mouseleave", function() {
        d.style.backgroundColor = 'rgba(0, 0, 0, 0.8)'
      });

    }
    
    for(var i = 0; i < options.length; i+=2) {
      createButton(options[i], options[i+1]);
    }

    
    document.body.appendChild(div);
    contextMenu = div;
    contextMenu.style.display = 'initial';
    contextMenu.style.left = ''+xpos+'px';
    contextMenu.style.top = ''+ypos+'px';
    
  }
})();
