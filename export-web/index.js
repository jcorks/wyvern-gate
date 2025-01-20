var matteWorker = null;


window.onerror = function(errorMessage, url, line) {
    reportError(
        "Browser threw an exception:\n" +
        errorMessage + "\n" +
        "(" + url + ":" + line + ")"
    )
}

window.addEventListener("error", function (e) {
    reportError(
        "Browser threw an error:\n" +
        e.error.message + "\n\n" +
        (e.error.stack ? e.error.stack : "(no stack)")
    )
})
/*
window.addEventListener("unhandledrejection", function (e) {
    reportError(
        "Browser threw an unhandledrejection:\n" +
        e.reason.message + "\n\n" +
        e.reason.stack
    )
})
*/

var postMessageWorker = function(data) {
    if (matteWorker != null)
        matteWorker.postMessage(JSON.stringify(data));
};

(function() {


    

    


    var currentGamepad = null;
    var gamepadInterval = null;
    window.addEventListener("gamepaddisconnected", function(e) {
        if (currentGamepad === e.gamepad)
            currentGamepad = null;

        console.log("Gamepad disconnected from index %d: %s",
            e.gamepad.index, e.gamepad.id);
    });

    window.addEventListener("gamepadconnected", function(e) {
        currentGamepad = e.gamepad;
        console.log(currentGamepad);
        
        if (gamepadInterval == null) {
            gamepadInterval = setInterval(getGamepadInput, 30);
        }
        
        console.log("Gamepad connected at index %d: %s. %d buttons, %d axes.",
            e.gamepad.index, e.gamepad.id,
            e.gamepad.buttons.length, e.gamepad.axes.length);
    });


    var gamepadLastState = [
        false, false, false,
        false, false, false    
    ];

    var gamepadThisState = [
        false, false, false,
        false, false, false    
    ];

    // this isnt fit for a "realtime" game as it would 
    // eat inputs and is not flexible with axes
    var getGamepadInput = function() {
        if (currentGamepad == null) return;
        
        var temp = gamepadLastState;
        gamepadLastState = gamepadThisState;
        gamepadThisState = temp;
        for(var i = 0; i < 6; ++i) {
            gamepadThisState[i] = false;
        }

        if (currentGamepad.buttons[0].pressed > 0)
            gamepadThisState[4] = true;
        else if (currentGamepad.buttons[1].pressed > 0)
            gamepadThisState[5] = true;
            
        if (currentGamepad.axes[0].toFixed(4) > 0.6)
            gamepadThisState[2] = true;
        else if (currentGamepad.axes[0].toFixed(4) < -0.6)
            gamepadThisState[0] = true;
        else if (currentGamepad.axes[1].toFixed(4) > 0.6) {
            gamepadThisState[3] = true;
        } else if (currentGamepad.axes[1].toFixed(4) < -0.6) {
            gamepadThisState[1] = true;
        }

        for(var i = 0; i < 6; ++i) {
            if (gamepadThisState[i] == true && gamepadLastState[i] == false) LAST_INPUT = i;    
        }
        
        if (LAST_INPUT != -1) {
            console.log(LAST_INPUT);
            LAST_INPUT = -1;
        }        
    }



    

    /*
    const canvasInput = data.data;
    if (typeof canvasInput == 'string') {
        var a = document.getElementById("canvas");
        a.innerText = 
            'Whoops. JC made a mistake and the game pooped. Again.\n' +
            'There\'s a BIG chance it\'s just because of a missing\n' + 
            'feature, but just in case, you can send \'em this thingy:\n\n' +
            canvasInput;           
    } else {
        for(var i = 0; i < canvasInput.length; ++i) {
            CANVAS.writeRow(i, canvasInput[i]);
        }    
    }
    */

})();


const fullscreenEnter = function(element) {
    element.style.width = "100vw";
    element.style.height = "100vh";
    if (element.requestFullscreen) {
        element.requestFullscreen(
            {
                navigationUI : 'hide'
            }        
        );
    } else if (element.mozRequestFullScreen) {
        element.mozRequestFullScreen();
    } else if (element.webkitRequestFullScreen) {
        element.webkitRequestFullScreen();
    } else if (element.msRequestFullscreen) {
        element.msRequestFullscreen();
    }
    
    
    try {
        window.o9n.orientation.lock("landscape-primary");
    } catch(e) {
    
    }
}

const fullscreenExit = function(element) {
    try {
        window.o9n.orientation.unlock("landscape-primary");
    } catch(e) {
    
    }
    if (document.exitFullscreen) {
        if (document.fullscreenElement) {
            document.exitFullscreen();
        }
    } else if (document.webkitExitFullscreen) {
        document.webkitExitFullscreen();
    } else if (document.mozCancelFullScreen) {
        document.mozCancelFullScreen();
    } else if (document.msExitFullscreen) {
        document.msExitFullscreen();
    }

}


const exitGame = function() {
    matteWorker = null;
    fullscreenExit();

    const body = document.getElementById("gameArea");
    body.style.display = 'none';

}

var reportError__reported = false;
var reportError = function(message) {
    if (reportError__reported) return;
    reportError__reported = true;
    exitGame();
    const err = document.getElementById("errorMessage");
    err.innerText = 
        "Unfortunately, an error has occured.\n\n"+
        "Send this to JC or post it as a bug report in the git repo.\n"+
        message
    ;
    err.style.display = "block";  
}


var startGame = function(touch) {
    if (touch != 'use-touch') {
        document.getElementById('inputArea').style.display = 'none';
    }
    

    const isTouchScreen =
      (  (('ontouchstart' in window) ||
         (navigator.maxTouchPoints > 0) ||
         (navigator.msMaxTouchPoints > 0)));
    
    const rows = [];
    
    const imgs = document.getElementsByTagName("img");
    for(var i = 0; i < imgs.length; ++i) {
        imgs[i].addEventListener("contextmenu", function(e) {e.preventDefault();});
    }
    

    const body = document.getElementById("gameArea");

    fullscreenEnter(body);
    

    // resize canvas


    
    window.setTimeout(function() {
    
      const canvas = document.getElementById("canvas");
      const gameArea = document.getElementById("gameArea");
      var vw = gameArea.clientWidth;
      var vh = gameArea.clientHeight;




      const aspectRatioWH = (80 * 13) / (24 * 25.0);
      const requiredHeight = vw * (1 / aspectRatioWH);
      
      // we dont have enough room. Fit it based on height
      if (requiredHeight > vh) {
          vw = vh * aspectRatioWH;
      } else {
          vh = requiredHeight;
      }
      



      canvas.style.margin = "0 auto";
      canvas.style.width = ""+vw+"px";
      canvas.style.height = ""+vh+"px";


      initializeTextRenderer();
      
      matteWorker = new Worker("worker.js");
      
      postMessageWorker({
          command: 'deliverSaves',
          saves: JSON.parse(JSON.stringify(window['localStorage']))
      });




      matteWorker.onmessage = function(e) {
          const data = JSON.parse(e.data);
      
          switch(data.command) {
            case 'lines':
              const lines = data.data;
              for(var i = 0; i < data.data.length; ++i) {
                  TextRenderer.setLine(i, data.data[i]);
              }
              TextRenderer.requestDraw();
              break;
              
            case 'save': {
              var storage = window['localStorage'];
              if (data.data == undefined || data.data == '' || data.data == '""')
                    delete storage[data.name];
              else 
                    storage[data.name] = data.data;                

              postMessageWorker({
                  command: 'deliverSaves',
                  saves: window['localStorage']
              });
              break;
            } 
            
            case 'quit' : {          
              exitGame();
              const endMessage = document.getElementById("endMessage");
              endMessage.style.display = 'block';
              break;
            }
            
            case 'sfx' : {
              // play a sound
              data.name
              break;
            }

            case 'bgm' : {
              // play a sound
              data.name
              data.loop
              break;
            }

            
            case 'error' : {
              reportError(
                  "git info: " + GIT_VERSION + "\n\n" +
                  data.data
              );
              break;

            }
          }
           
      }      
      
    }, 2000);  
    
    body.style.display = 'block';
    
    
    
    const initMessage = document.getElementById("initMessage");
    initMessage.style.display = 'none';
    
    


    const repeaterInput = function(element, input) {
        postMessageWorker(input);

        var intervalID;
        var timeoutID = setTimeout(function() {
            intervalID = setInterval(function() {
                postMessageWorker(input);
            }, 80);
        }, 300);
        const refID = element.addEventListener('mouseup', function(e) {
            element.removeEventListener('mouseup', refID);
            clearInterval(intervalID);
            clearTimeout(timeoutID);
        });    
    }

    if (!isTouchScreen) {
        document.getElementById('arrow-left').addEventListener('mousedown', function(e) {
            repeaterInput(document.getElementById('arrow-left'), 0);
        });

        document.getElementById('arrow-up').addEventListener('mousedown', function(e) {
            repeaterInput(document.getElementById('arrow-up'), 1);
        });

        document.getElementById('arrow-right').addEventListener('mousedown', function(e) {
            repeaterInput(document.getElementById('arrow-right'), 2);
        });

        document.getElementById('arrow-down').addEventListener('mousedown', function(e) {
            repeaterInput(document.getElementById('arrow-down'), 3);
        });





        document.getElementById('a-button').addEventListener('mousedown', function(e) {
            postMessageWorker(4);
        });

        document.getElementById('b-button').addEventListener('mousedown', function(e) {
            postMessageWorker(5);
        });
    }
    
    
    
   document.getElementById('arrow-left').addEventListener('touchstart', function(e) {
        postMessageWorker(0);
    });

    document.getElementById('arrow-up').addEventListener('touchstart', function(e) {
        postMessageWorker(1);
    });

    document.getElementById('arrow-right').addEventListener('touchstart', function(e) {
        postMessageWorker(2);
    });

    document.getElementById('arrow-down').addEventListener('touchstart', function(e) {
        postMessageWorker(3);
    });


    document.getElementById('a-button').addEventListener('touchstart', function(e) {
        postMessageWorker(4);
    });

    document.getElementById('b-button').addEventListener('touchstart', function(e) {
        postMessageWorker(5);
    });        

}



var onPageInput = function (event) {
    switch(event.key) {
      case 'ArrowLeft': 
        postMessageWorker(0);
        break;

      case 'ArrowRight': 
        postMessageWorker(2);
        break;

      case 'ArrowUp': 
        postMessageWorker(1);
        break;

      case 'ArrowDown': 
        postMessageWorker(3);
        break;

      case 'z': 
      case 'Space': 
      case ' ':
      case 'Enter': 
        postMessageWorker(4);
        break;

      case 'x': 
      case 'Escape': 
      case 'Backspace': 
        postMessageWorker(5);
        break;
    }
};

