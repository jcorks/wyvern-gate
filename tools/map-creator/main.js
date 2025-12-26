


document.body.style.backgroundColor = BACKGROUND_COLOR;
document.body.style.color = TEXT_COLOR_ACTIVE;
document.body.style.fontFamily = 'Monospace';





// init
(function() {
  const canvas = Canvas.new();



  document.getElementById('canvas-anchor').appendChild(canvas.getElement());
  document.getElementById('palette-anchor').appendChild(canvas.getPalette().getElement());

  const yRange = document.getElementById('y-range');
  const xRange = document.getElementById('x-range');
  yRange.style.height = '' + canvas.getElement().clientHeight + 'px';
  xRange.style.width  = '' + canvas.getElement().clientWidth  + 'px';
  


  const updateScroll = function() {
    canvas.move(
      parseFloat(xRange.value),
      parseFloat(yRange.value)
    )
  }  
  xRange.addEventListener("change", function(event) {updateScroll()});
  yRange.addEventListener("change", function(event) {updateScroll()});
  
  
  const settings = Settings.new(
    canvas,
    xRange,
    yRange
  );
  document.getElementById('settings-anchor').appendChild(settings.getElement());
  
  
  
})();
