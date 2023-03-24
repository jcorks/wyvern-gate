var LAST_INPUT = -1;

/*
@:CURSOR_ACTIONS = {
    LEFT : 0,
    UP : 1,
    RIGHT : 2,
    DOWN : 3,
    CONFIRM : 4,
    CANCEL : 5
};

*/

const CANVAS = {
    _el: null,
    _commitRow: 0,

    init: function (element) {
        if (!element) {
            console.warn('Could not find canvas to init!');
        } else {
            this._el = element;
        }
    },
    reset: function (clear = false) {
        this._commitRow = 0;
    },
    clear: function () {
        this._el.innerHTML = '';
    },
    writeRow: function (y, text) {
        // The old way, but here
        //this._el.innerHTML += '\n' + [...text]
        //    .map(character => `<span>${character}</span>`)
        //    .join('');

        // The better way
        // Make sure row exists first
        let row = this._el.children[y];

        if (!(row instanceof Element)) {
            row = document.createElement('div')
            row.id = `row-${y}`
            row.className = 'canvas__row'
        }

        // Iterate over text
        let textArray = [...text]
        
        textArray.forEach((character, x) => {
            let cell = row.children[x]

            if (!(cell instanceof Element)) {
                cell = document.createElement('span')
                cell.id = `cell-${x},${y}`
                cell.className = 'canvas__row__cell'
            }

            cell.innerHTML = character;

            if (cell.parentElement === null) {
                row.appendChild(cell)
            }
        })

        // Append at the end so we only render the DOM once
        if (row.parentElement === null) {
            this._el.appendChild(row)
        }
    },
    writeCommit: function (text) {
        this.writeRow(this._commitRow, text);
        this._commitRow++;
    }
}

document.addEventListener('DOMContentLoaded', function () {
    CANVAS.init(document.getElementById('canvas'));

    document.getElementById('arrow-left').addEventListener('click', function(e) {
        LAST_INPUT = 0;
    });

    document.getElementById('arrow-up').addEventListener('click', function(e) {
        LAST_INPUT = 1;
    });

    document.getElementById('arrow-right').addEventListener('click', function(e) {
        LAST_INPUT = 2;
    });

    document.getElementById('arrow-down').addEventListener('click', function(e) {
        LAST_INPUT = 3;
    });


    document.getElementById('a-button').addEventListener('click', function(e) {
        LAST_INPUT = 4;
    });

    document.getElementById('b-button').addEventListener('click', function(e) {
        LAST_INPUT = 5;
    });

});


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
    
    if (LAST_INPUT != -1)
        console.log(LAST_INPUT);
}



var onPageInput = function (event) {
    switch(event.key) {
      case 'ArrowLeft': 
        LAST_INPUT = 0;
        break;

      case 'ArrowRight': 
        LAST_INPUT = 2;
        break;

      case 'ArrowUp': 
        LAST_INPUT = 1;
        break;

      case 'ArrowDown': 
        LAST_INPUT = 3;
        break;

      case 'Z': 
      case 'Space': 
      case 'Enter': 
        LAST_INPUT = 4;
        break;

      case 'Escape': 
      case 'Backspace': 
        LAST_INPUT = 5;
        break;


    }
    console.log(event.key);
}





WYVERN_startCommit = function() {
    CANVAS.reset();
};
  
WYVERN_onCommitText = function (text) {
    CANVAS.writeCommit(text);
};
  
WYVERN_onEndCommit = function() {
        
};
  
WYVERN_onSaveState = function(slot, str) {
    var storage = window['localStorage'];
    storage['wyvernslot'+slot] = str;
};
  
WYVERN_onLoadState = function(slot) {
    var storage = window['localStorage'];
    return storage['wyvernslot'+slot];    
};

WYVERN_getInput = function() {
    var out = LAST_INPUT;
    LAST_INPUT = -1;
    return out;
};
  
WYVERN_error = function(version, error) {
    var a = document.getElementById("canvas");
    a.innerText = 
        'Whoops. JC made a mistake and the game pooped. Again.\n' +
        'There\'s a BIG chance it\'s just because of a missing\n' + 
        'feature, but just in case, you can send \'em this thingy:\n\n' +    
        '(commit: ' + version + ')\n' +
        error;
};


