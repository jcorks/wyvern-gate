var matteWorker = null;

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

var startGame = function() {
    const isTouchScreen =
      (  (('ontouchstart' in window) ||
         (navigator.maxTouchPoints > 0) ||
         (navigator.msMaxTouchPoints > 0)));
    
    const rows = [];

    const body = document.getElementById("gameArea");
    body.requestFullscreen(
        {
            navigationUI : 'hide'
        }
    )
    body.style.display = 'block';
    
    
    
    const initMessage = document.getElementById("initMessage");
    initMessage.style.display = 'none';
    
    
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
            storage[data.name] = data.data;                

            postMessageWorker({
                command: 'deliverSaves',
                saves: window['localStorage']
            });
          } 
          
          case 'quit' : {          
            matteWorker = null;
            document.exitFullsreen();
            const endMessage = document.getElementById("endMessage");
            endMessage.style.display = 'block';
            
            
          }            
        }
         
    }

    if (!isTouchScreen) {
        document.getElementById('arrow-left').addEventListener('mousedown', function(e) {
            postMessageWorker(0);
        });

        document.getElementById('arrow-up').addEventListener('mousedown', function(e) {
            postMessageWorker(1);
        });

        document.getElementById('arrow-right').addEventListener('mousedown', function(e) {
            postMessageWorker(2);
        });

        document.getElementById('arrow-down').addEventListener('mousedown', function(e) {
            postMessageWorker(3);
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

