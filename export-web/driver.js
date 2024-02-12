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

    const matteList = [
        "game_class.battleai.mt",
        "game_class.battle.mt",
        "game_class.damage.mt",
        "game_class.database.mt",
        "game_class.deck.mt",
        "game_class.die.mt",
        "game_class.entity.mt",
        "game_class.inventory.mt",
        "game_class.island.mt",
        "game_class.landmarkevent_cavebat.mt",
        "game_class.landmarkevent_dungeonencounters.mt",
        "game_class.landmarkevent_itemspecter.mt",
        "game_class.landmarkevent_thebeast.mt",
        "game_class.landmarkevent_themirror.mt",
        "game_class.landmarkevent_treasuregolem.mt",
        "game_class.logtimer.mt",
        "game_class.map.mt",
        "game_class.party.mt",
        "game_class.stateflags.mt",
        "game_class.state.mt",
        "game_class.statset.mt",
        "game_class.structuremap.mt",
        "game_database.ability.mt",
        "game_database.apparelmaterial.mt",
        "game_database.effect.mt",
        "game_database.interaction.mt",
        "game_database.itemcolor.mt",
        "game_database.itemdesign.mt",
        "game_database.itemenchantcondition.mt",
        "game_database.itemquality.mt",
        "game_database.material.mt",
        "game_database.personality.mt",
        "game_database.scene.mt",
        "game_database.species.mt",
        "game_function.battlemenu.mt",
        "game_function.choicescolumns.mt",
        "game_function.correcta.mt",
        "game_function.databaseitemmutatorclass.mt",
        "game_function.dice.mt",
        "game_function.distance.mt",
        "game_function.g.mt",
        "game_function.interactperson.mt",
        "game_function.itemimprove.mt",
        "game_function.itemmenu.mt",
        "game_function.name.mt",
        "game_function.newrecord.mt",
        "game_function.partyoptions.mt",
        "game_function.pickitem.mt",
        "game_function.pickitemprices.mt",
        "game_function.pickpartyitem.mt",
        "game_function.trap.mt",
        "game_mutator.entityquality.mt",
        "game_mutator.event.mt",
        "game_mutator.itemenchant.mt",
        "game_mutator.item.mt",
        "game_mutator.landmarkevent.mt",
        "game_mutator.landmark.mt",
        "game_mutator.location.mt",
        "game_mutator.mapentity.mt",
        "game_mutator.profession.mt",
        "game_mutator.scenario.mt",
        "game_scenario.thechosen.mt",
        "game_scenario.thetrader.mt",
        "game_singleton.canvas.mt",
        "game_singleton.commoninteractions.mt",
        "game_singleton.dungeonmap.mt",
        "game_singleton.gamblist.mt",
        "game_singleton.instance.mt",
        "game_singleton.largemap.mt",
        "game_singleton.loadableclass.mt",
        "game_singleton.namegen.mt",
        "game_singleton.random.mt",
        "game_singleton.story.mt",
        "game_singleton.windowevent.mt",
        "game_singleton.world.mt",
        "game_struct.accolade.mt",
        "game_struct.battleaction.mt",
        "game_struct.interactionmenuentry.mt",
        "game_struct.mt",

        'main.external.mt',
        'Matte.Core.Class',
        'Matte.Core',
        'Matte.Core.JSON',
        'Matte.Core.Introspect',
        'Matte.Core.EventSystem'

    ];

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
        console.log(matte.store.valueObjectAccessString(value, 'summary').data);
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
        Worker.save({
            name: 'wyvernslot'+slot,
            data: args[1]
        });
        return matte.store.createEmpty();            
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

      
    matte.setExternalFunction('external_onLoadState', ['a'], function(fn, args) {
        return matte.store.createString(Worker.getSlot(args[0]));    
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
        "goal"        
    ], function(fn, args) {
        const store = matte.store;

        const width  = store.valueAsNumber(args[0]);
        const height = store.valueAsNumber(args[1]);
        const scenery = args[2];
        const start = store.valueAsNumber(args[3]);
        const goal = store.valueAsNumber(args[4]);
    
    
        const aStarNewNode = function(x, y) {
            const id = x + y*width;
            const sceneryValue = store.valueObjectArrayAtUnsafe(scenery, id);
            const sceneryValueNumber = store.valueAsNumber(sceneryValue);
            if (!(sceneryValueNumber & 0x010000) && x >= 0 && y >= 0 && x < width && y < height)
                return id;
        }

        const aStarGetNeighbors = function(neighbors, current) {
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

