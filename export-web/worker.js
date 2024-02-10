importScripts("matte.js", "driver.js");

Worker = (function() {
    const lines = [];
    var lineIter = 0;
    
    var inputs = [];
    
    var saves;
    
    
    onmessage = function(message) {
        if (!message.data.command)
            inputs.push(message.data);

        switch(message.data.command) {
          case 'deliverSaves': 
            saves = message.data.saves;
            
        }
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
                if (allNames[i].indexOf('wyvernslot' !=-1)) {
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
    
        newLine : function(text) {
            lines[lineIter] = text;
            lineIter++;
        },
        
        save : function(name, data) {
            postMessage({
                command: 'save',
                data : {
                    name: name,
                    data: data
                }
            });
        },
        
        send : function() {
            postMessage({
                command: 'lines',
                data : lines
            });
            lineIter = 0;
        }
    }
})();
