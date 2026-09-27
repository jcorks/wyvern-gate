importScripts("matte.js", "driver.js", "filelist.js");

Worker = (function() {
    const lines = [];
    var lineIter = 0;
    
    var inputs = [];
    
    var saves;
    
    
    onmessage = function(message) {
        const data = JSON.parse(message.data);
        if (!data.command)
            inputs.push(data);

        switch(data.command) {
          case 'deliverSaves': 
            saves = data.saves;
            
        }
    }
    
    
    postMessageJSON = function(data) {
        postMessage(JSON.stringify(data));
    }
    
    return {
        nextInput : function() {
            if (inputs.length == 0) return null;
            const out = inputs[0];
            inputs.splice(0, 1);
            return out;
        },
        
        list : function() {
            return Object.keys(saves);
        },
        
        load : function(name) {
            return saves[name];
        },

    
        newLine : function(text) {
            lines[lineIter] = text;
            lineIter++;
        },
        
        save : function(name, data) {
            postMessageJSON({
                command: 'save',
                name: name,
                data: data
            });
        },
        
        send : function() {
            postMessageJSON({
                command: 'lines',
                data : lines
            });
            lineIter = 0;
        },
        
        quit : function() {
            postMessageJSON({
                command: 'quit'
            });            
        },
        
        playSFX : function(name) {
            postMessageJSON({
                command: 'sfx',
                name : name
            });
        },

        playBGM : function(name, loop) {
            postMessageJSON({
                command: 'bgm',
                name : name,
                loop : loop
            });
        },

        
        throwMatteError : function(message) {
            postMessageJSON({
                command: 'error',
                data: message
            });
        }
    }
})();
