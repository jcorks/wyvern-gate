


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
  canvas.setSettings(settings);
  canvas.getPalette().getEvents().addCallback('onSelect', function() {
    settings.setMode(Settings.MODE.PEN);
  });
  settings.setMode(Settings.MODE.WALL);
  settings.setMode(Settings.MODE.PEN);
  
  const save = function() {
    const obj = {};
    obj.canvas = canvas.save();
    obj.settings = settings.save();
    
    window.localStorage.setItem('save', JSON.stringify(obj));
  }
  
  
  const load = function() {
    const obj = window.localStorage.getItem('save');
    if (obj == undefined) return;
    
    // settings first so it can populate the pattern data for the canvas
    settings.load(obj.canvas);
    canvas.load(obj.canvas);
  }
  
})();
