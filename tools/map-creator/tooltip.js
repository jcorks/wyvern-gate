const Tooltip = (function() {
  const el = document.createElement('div');
  el.style.position = 'absolute';
  el.style.zIndex = 1000;
  el.style.pointerEvents = "none";
  el.style.backgroundColor = "rgb(0, 0, 0)"

  document.body.appendChild(el);


  addEventListener("mousemove", function(event) {
    el.style.left = ""+(event.x + 20)+"px";
    el.style.top = ""+(event.y - 20) +"px";
  });
  
  //el.innerText = "This is a test";

  return {
    set : function(message) {
    
      el.innerText = message;
      el.style.display = "initial";
    },
    unset : function() {
      el.innterText = '';
      el.style.display = 'none';
    }
  }

})();
