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
        'game_class.ability.mt',
        'game_class.apparelmaterial.mt',
        'game_class.battleai.mt',
        'game_class.battle.mt',
        'game_class.damage.mt',
        'game_class.database.mt',
        'game_class.deck.mt',
        'game_class.die.mt',
        'game_class.effect.mt',
        'game_class.entity.mt',
        'game_class.entityquality.mt',
        'game_class.event.mt',
        'game_class.interaction.mt',
        'game_class.inventory.mt',
        'game_class.island.mt',
        'game_class.itemcolor.mt',
        'game_class.itemdesign.mt',
        'game_class.itemenchantcondition.mt',
        'game_class.itemenchant.mt',
        'game_class.item.mt',
        'game_class.itemquality.mt',
        'game_class.landmarkevent_dungeonencounters.mt',
        'game_class.landmarkevent_itemspecter.mt',
        'game_class.landmarkevent.mt',
        'game_class.landmarkevent_thebeast.mt',
        'game_class.landmark.mt',
        'game_class.location.mt',
        'game_class.logtimer.mt',
        'game_class.mapentity.mt',
        'game_class.map.mt',
        'game_class.material.mt',
        'game_class.party.mt',
        'game_class.personality.mt',
        'game_class.profession.mt',
        'game_class.scene.mt',
        'game_class.species.mt',
        'game_class.stateflags.mt',
        'game_class.state.mt',
        'game_class.statset.mt',
        'game_class.structuremap.mt',
        'game_function.battlemenu.mt',
        'game_function.correcta.mt',
        'game_function.dice.mt',
        'game_function.distance.mt',
        'game_function.interactperson.mt',
        'game_function.itemimprove.mt',
        'game_function.itemmenu.mt',
        'game_function.name.mt',
        'game_function.newrecord.mt',
        'game_function.partyoptions.mt',
        'game_function.pickitem.mt',
        'game_function.pickpartyitem.mt',
        'game_function.trap.mt',
        'game_singleton.canvas.mt',
        'game_singleton.dungeonmap.mt',
        'game_singleton.gamblist.mt',
        'game_singleton.instance.mt',
        'game_singleton.largemap.mt',
        'game_singleton.loadableclass.mt',
        'game_singleton.namegen.mt',
        'game_singleton.random.mt',
        'game_singleton.story.mt',
        'game_singleton.windowevent.mt',
        'game_singleton.world.mt',
        'game_struct.battleaction.mt',
        'game_struct.mt',

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
        CANVAS.reset();
        return matte.store.createEmpty();        
    });

    matte.setExternalFunction('external_onEndCommit', [],function(fn, args) {
        return matte.store.createEmpty();            
    });


    matte.setExternalFunction('external_onCommitText', ['a'],function(fn, args) {
        CANVAS.writeCommit(args[0].data);
        return matte.store.createEmpty();        
    });

    matte.setExternalFunction('external_onSaveState', ['a', 'b'], function(fn, args) {
        var storage = window['localStorage'];
        const slot = args[0].data;
        storage['wyvernslot'+slot] = args[1].data;
        return matte.store.createEmpty();            
    });

    matte.setExternalFunction('external_onListSlots', ['a', 'b'], function(fn, args) {
        var storage = window['localStorage'];
        const names = Object.keys(storage);
        const argsA = [];
        
        for(var i = 0; i < names.length; ++i) {
            if (names[i].indexOf('wyvernslot' !=-1)) {
                argsA.push(
                    matte.store.createString(
                        names[i].substring(
                            10,
                            names[i].length-1
                        )
                    )
                )
            }
        }
        return matte.store.createObjectArray(argsA);            
    });

      
    matte.setExternalFunction('external_onLoadState', ['a'], function(fn, args) {
        var storage = window['localStorage'];
        return matte.store.createString(storage['wyvernslot'+args[0].data]);    
    });      


    matte.setExternalFunction('external_getInput', [], function(fn, args) {
        if (LAST_INPUT == -1) return matte.store.createEmpty();
        var out = LAST_INPUT;
        LAST_INPUT = -1;
        return matte.store.createNumber(out);
    });


      
    
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

