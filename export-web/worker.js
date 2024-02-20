importScripts("matte.js", "driver.js");

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
        
        listSaveSlots : function() {
            const allNames = Object.keys(saves);
            const allNamesOut = [];
            for(var i = 0; i < allNames.length; ++i) {
                if (allNames[i].indexOf('wyvernslot') == 0) {
                    allNamesOut.push(allNames[i].substring(
                        10
                    ))
                }
            }
            
            return allNamesOut;
        },
        
        getSlot : function(name) {
            return saves['wyvernslot'+name];
        },
        loadSettings : function(name) {
            return saves['wyvernsettings'];
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
        
        throwMatteError : function(message) {
            postMessageJSON({
                command: 'error',
                data: message
            });
        }
    }
})();
