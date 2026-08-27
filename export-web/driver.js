(function() {


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

    // reads a binary file
    const readBinary = function(name, onLoad) {
        const req = new XMLHttpRequest();
        req.open("GET", name, true);
        req.responseType = "arraybuffer";

        req.onload = (event) => {
            const arrayBuffer = req.response; // Note: not req.responseText
            if (arrayBuffer) {
                onLoad(arrayBuffer);
            };
        }
        req.send(null);
    };

    

    var matteListIndex = 0;

    const mattePreloadedBytecode = {};

    const matte = Matte.newVM(
        function(name) {
            return mattePreloadedBytecode[name];
        },
        function(value) {
            console.log(value);
        },
    );

    matte.unhandledError = function(file, line, value) {
        Worker.throwMatteError(matte.store.valueObjectAccessString(value, 'summary'));
    };  
    



    matte.setExternalFunction('external_onStartCommit', [], function(fn, args) {
        return matte.store.createEmpty();        
    });

    matte.setExternalFunction('external_onEndCommit', [],function(fn, args) {
        Worker.send();
        return matte.store.createEmpty();            
    });


    matte.setExternalFunction('external_onCommitText', ['a'],function(fn, args) {
        Worker.newLine(args[0]);
        return matte.store.createEmpty();        
    });

    matte.setExternalFunction('external_onSaveState', ['a', 'b'], function(fn, args) {
        const slot = args[0];
        Worker.save(
            'wyvernslot'+slot,
            Matte.objectToJSON(args[1])
        );
        return matte.store.createEmpty();            
    });
    
    matte.setExternalFunction('external_onSaveSettings', ['a'], function(fn, args) {
        Worker.save(
            'wyvernsettings',
            args[0]
        );
    });
    
    matte.setExternalFunction('external_onLoadSettings', [], function(fn, args) {
        return matte.store.createString(Worker.loadSettings());
    });

    matte.setExternalFunction('external_onListSlots', ['a', 'b'], function(fn, args) {
        const names = Worker.listSaveSlots();
        const argsA = [];
        
        for(var i = 0; i < names.length; ++i) {
            argsA.push(
                matte.store.createString(
                    names[i]
                )
            )
        }
        return matte.store.createObjectArray(argsA);            
    });
    
    
    matte.setExternalFunction('external_onPlaySFX', ['a'], function(fn, args) {
        Worker.playSFX(args[0]);         
    });    

    matte.setExternalFunction('external_onPlayBGM', ['a', 'b'], function(fn, args) {
        Worker.playBGM(args[0], args[1]);         
    });    
    

      
    matte.setExternalFunction('external_onLoadState', ['a'], function(fn, args) {
        const s = Worker.getSlot(args[0]);
        if (s == '' || !s) return matte.store.createEmpty();
        return Matte.JSONtoObject(s);    
    });      


    matte.setExternalFunction('external_getInput', [], function(fn, args) {
        const val = Worker.nextInput();

        if (val == null) return matte.store.createEmpty();
        return matte.store.createNumber(val);
    });

    matte.setExternalFunction('external_onQuit', [], function(fn, args) {
        Worker.quit();
    });



    ////////// BFS_NATIVE ///////////
    
    const bfs_q = [];
    const bfs_visited = [];
    matte.setExternalFunction('wyvern_gate__native__bfs', [
        "width",    
        "height",
        "scenery",
        "start",
        "goal",
        "corners"     
    ], function(fn, args) {
        const store = matte.store;

        const width  = store.valueAsNumber(args[0]);
        const height = store.valueAsNumber(args[1]);
        const scenery = args[2];
        const start = store.valueAsNumber(args[3]);
        const goal = store.valueAsNumber(args[4]);
        const corners = store.valueAsBoolean(args[5]);
    
    
        const aStarNewNode = function(x, y) {
            const id = x + y*width;
            const sceneryValue = store.valueObjectArrayAtUnsafe(scenery, id);
            const sceneryValueNumber = store.valueAsNumber(sceneryValue);
            if (!(sceneryValueNumber & 0x010000) && x >= 0 && y >= 0 && x < width && y < height)
                return id;
        }

        var aStarGetNeighbors;
        if (corners) {
            aStarGetNeighbors = function(neighbors, current) {
                neighbors.length = 0;
                const x = current%width;
                const y = Math.floor(current/width);
                
                var i;
                i = aStarNewNode(x+1, y+1); if (i != undefined) neighbors.push(i);
                i = aStarNewNode(x+1, y-1); if (i != undefined) neighbors.push(i);
                i = aStarNewNode(x-1, y+1); if (i != undefined) neighbors.push(i);
                i = aStarNewNode(x-1, y-1); if (i != undefined) neighbors.push(i);

                i = aStarNewNode(x-1, y  ); if (i != undefined) neighbors.push(i);
                i = aStarNewNode(x+1, y  ); if (i != undefined) neighbors.push(i);
                i = aStarNewNode(x  , y+1); if (i != undefined) neighbors.push(i);
                i = aStarNewNode(x  , y-1); if (i != undefined) neighbors.push(i);
                return neighbors;
            }  
        } else {
            aStarGetNeighbors = function(neighbors, current) {
                neighbors.length = 0;
                const x = current%width;
                const y = Math.floor(current/width);
                
                var i;
                i = aStarNewNode(x-1, y  ); if (i != undefined) neighbors.push(i);
                i = aStarNewNode(x+1, y  ); if (i != undefined) neighbors.push(i);
                i = aStarNewNode(x  , y+1); if (i != undefined) neighbors.push(i);
                i = aStarNewNode(x  , y-1); if (i != undefined) neighbors.push(i);
                return neighbors;
            }         
        }
  
    
    
        const q = bfs_q;
        q.length = 0;
        
        const visited = bfs_visited;
        visited.length = 0;
        

            
        if (start == goal) return store.createEmpty();
        var qIter = 0;
        const neighbors = [];
        visited[start] = start;
        q.push(start);
        
        while(qIter < q.length) {
            const v = q[qIter];
            qIter +=1;


            if (v == goal) {
                // build path
                var a = v;
                var last;
                const returnOut = [];
                for(;;) {
                    const aValue = store.createNumber(a);
                    returnOut.push(aValue);
                    
                    if (visited[a] == start) {
                        return store.createObjectArray(returnOut);
                    }                    
                    
                    a = visited[a];
                }
            }
            aStarGetNeighbors(neighbors, v)
            for(var i = 0; i < neighbors.length; ++i) {
                const w = neighbors[i];
                if (visited[w]) continue;
                
                visited[w] = v; // parent
                q.push(w);
            }
        }
        
        return store.createEmpty();
    });

//////////////////////////////////////////




      
    
    var loadedCount = 0;
    var task = setInterval(function() {
        if (matteListIndex != matteList.length) {             
            const mod = matteList[matteListIndex++]; 
            readBinary(mod, function(data) {
                console.log('Loading ' + mod);
                mattePreloadedBytecode[mod] = data;

                
                loadedCount++;
            });
        } 
        
        if (loadedCount == matteList.length) {
            clearInterval(task);
            const update = matte.import('main.external.mt');
            
            
            setInterval(function() {
                matte.callFunction(update, [], []);
            }, 30);
        }
    });

})();

