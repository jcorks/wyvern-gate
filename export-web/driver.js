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
        'class.ability.mt',
        'class.battleai.mt',
        'class.battle.mt',
        'class.damage.mt',
        'class.database.mt',
        'class.dungeoncontroller.mt',
        'class.dungeonmap.mt',
        'class.effect.mt',
        'class.entity.mt',
        'class.event.mt',
        'class.interaction.mt',
        'class.inventory.mt',
        'class.island.mt',
        'class.itemcolor.mt',
        'class.itemmodifier.mt',
        'class.item.mt',
        'class.landmark.mt',
        'class.largemap.mt',
        'class.location.mt',
        'class.logtimer.mt',
        'class.mapbase.mt',
        'class.map.mt',
        'class.material.mt',
        'class.party.mt',
        'class.personality.mt',
        'class.profession.mt',
        'class.scene.mt',
        'class.species.mt',
        'class.stateflags.mt',
        'class.statset.mt',
        'function.battlemenu.mt',
        'function.distance.mt',
        'function.itemmenu.mt',
        'function.partyoptions.mt',
        'function.pickitem.mt',
        'main_external.mt',
        'singleton.canvas.mt',
        'singleton.dialogue.mt',
        'singleton.instance.mt',
        'singleton.menustack.mt',
        'singleton.namegen.mt',
        'singleton.random.mt',
        'singleton.story.mt',
        'singleton.world.mt',
        'struct.battleaction.mt',
        'struct.mt',
        
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
        console.log(matte.heap.valueObjectAccessString(value, 'summary').data);
    };  
    



    matte.setExternalFunction('external_onStartCommit', [], function(fn, args) {
        CANVAS.reset();
        return matte.heap.createEmpty();        
    });

    matte.setExternalFunction('external_onEndCommit', [],function(fn, args) {
        return matte.heap.createEmpty();            
    });


    matte.setExternalFunction('external_onCommitText', ['a'],function(fn, args) {
        CANVAS.writeCommit(args[0].data);
        return matte.heap.createEmpty();        
    });

    matte.setExternalFunction('external_onSaveState', ['a'], function(fn, args) {
        //var storage = window['localStorage'];
        storage['wyvernslot'+slot] = args[0].data;
        return matte.heap.createEmpty();            
    });
      
    matte.setExternalFunction('external_onLoadState', ['a'], function(fn, args) {
        //var storage = window['localStorage'];
        return matte.heap.createString(storage['wyvernslot'+args[0].data]);    
    });      


    matte.setExternalFunction('external_getInput', [], function(fn, args) {
        if (LAST_INPUT == -1) return matte.heap.createEmpty();
        var out = LAST_INPUT;
        LAST_INPUT = -1;
        return matte.heap.createNumber(out);
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
            const update = matte.import('main_external.mt');
            
            
            setInterval(function() {
                matte.callFunction(update, [], []);
            }, 30);
        }
    });

})();

