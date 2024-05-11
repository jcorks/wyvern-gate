/*
    Wyvern Gate, a procedural, console-based RPG
    Copyright (C) 2023, Johnathan Corkery (jcorkery@umich.edu)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

// database loading 



import(module:'game_database.arts.mt');
import(module:'game_database.apparelmaterial.mt');
import(module:'game_database.effect.mt');
import(module:'game_database.interaction.mt');
import(module:'game_database.itemcolor.mt');
import(module:'game_database.itemdesign.mt');
import(module:'game_database.itemenchantcondition.mt');
import(module:'game_database.itemquality.mt');
import(module:'game_database.material.mt');
import(module:'game_database.personality.mt');
import(module:'game_database.scene.mt');
import(module:'game_database.species.mt');

import(module:'game_mutator.entityquality.mt');
import(module:'game_mutator.event.mt');
import(module:'game_mutator.item.mt');
import(module:'game_mutator.itemenchant.mt');
import(module:'game_mutator.landmark.mt');
import(module:'game_mutator.landmarkevent.mt');
import(module:'game_mutator.location.mt');
import(module:'game_mutator.mapentity.mt');
import(module:'game_database.profession.mt');
import(module:'game_mutator.scenario.mt');
import(module:'game_function.trap.mt');
import(module:'game_singleton.commoninteractions.mt');

@:Database = import(module:'game_class.database.mt');


@:class = import(module:'Matte.Core.Class');
@:Entity = import(module:'game_class.entity.mt');
@:Party = import(module:'game_class.party.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Battle = import(module:'game_class.battle.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Landmark = import(module:'game_mutator.landmark.mt');
@:Island = import(module:'game_class.island.mt');
@:Event  = import(module:'game_mutator.event.mt');
@:Interaction = import(module:'game_database.interaction.mt');
@:Item = import(module:'game_mutator.item.mt');
@:namegen = import(module:'game_singleton.namegen.mt');
@:LargeMap = import(module:'game_singleton.largemap.mt');
@:Scenario = import(module:'game_mutator.scenario.mt');

import(module:'game_function.pickpartyitem.mt');


/* make sure base loadable classes are available */

import(module:'game_class.statset.mt');
import(module:'game_class.battleai.mt');
import(module:'game_class.inventory.mt');
import(module:'game_class.map.mt');
import(module:'game_class.party.mt');
import(module:'game_class.stateflags.mt');


import(module:'game_class.entity.mt');
import(module:'game_class.island.mt');

@:loading = import(module:'game_function.loading.mt');




@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
}
@:JSON = import(module:'Matte.Core.JSON');
@:GIT_COMMIT = import(module:'GIT_COMMIT');
@:VERSION = '0.1.8b - ' + GIT_COMMIT;
@world = import(module:'game_singleton.world.mt');
import(module:'game_function.newrecord.mt');


// every game starts or loads PAST this point.
// If a game bounces back to this, the user will be 
// unable to progress.
@:pointOfNoReturn::(do) {
    windowEvent.queueCustom(
        keep : true,
        jumpTag : 'PointOfNoReturn',
        renderable : {
            render :: {
                canvas.blackout();
            }
        },
        onEnter : do
    );
}

return class(
    name: 'Wyvern.Instance',
    define:::(this) {
        @onSaveState;
        @onLoadState;
        @island_;
        @landmark_;
        @settings;
        @onSaveSettings_;
        
        // the main.mt results of all mods, ordered based on dependency
        @:modMainOrdered = [];




        

        @:loadMods ::(mods) {
            // first we need the proper dep tree;
            @:depends = {};
            @:modsIndexed = {};
            
        
            foreach(mods) ::(i, mod) {
                depends[mod.id] = [...mod.loadFirst];
                modsIndexed[mod.id] = mod;
            }

            
            @:loaded = {}; // by name
            @:loading = {}; // by name, for circ dep
            
            
            // loads a single mod in order, detected circular dependencies.
            @:loadMod ::(mod) {
                when(loaded[mod.id] == true) empty;
                if (loading[mod.id] == true)
                    error(detail: 'Circular dependency of mods detected! First circular dependency: ' + mod.id);
                    
                loading[mod.id] = true;
                
                // load prereqs
                foreach(mod.loadFirst) ::(i, first) {
                    loadMod(mod:modsIndexed[first]);
                }
                
                
                // get entry point.
                @:result = {:::} {
                    return import(module: mod.id + '/main.mt');
                } : {
                    onError::(message) {
                        error(detail: 'An error occurred while loading the mod ' + mod.id + ':' + message.summary + '\n\n');
                    }
                }

                modMainOrdered->push(value:result);

                loaded[mod.id] = true;
            }
            foreach(mods) ::(i, mod) {
                loadMod(mod);
            }
            
            
            foreach(modMainOrdered) ::(i, modMain) {
                modMain.onGameStartup();
            }
        }
        
        
        
        this.interface = {

            mainMenu ::(
                canvasWidth => Number,
                canvasHeight=> Number,
                onSaveState => Function, // for saving,
                onLoadState => Function,
                onListSlots => Function,
                preloadMods => Function,
                onSaveSettings => Function,
                onLoadSettings => Function,
                onQuit => Function
            ) {
                canvas.resize(width:canvasWidth, height:canvasHeight);
                this.onSaveState = onSaveState;
                this.onLoadState = onLoadState;                

                onSaveSettings_ = onSaveSettings;
                settings = onLoadSettings();
                if (settings == empty)
                    settings = {
                        unlockedScenarios : false,
                        //  other default settings here
                    }
                else 
                    settings = JSON.decode(string:settings);
                



/*
@:otherChoices ::{
    windowEvent.queueChoices(
        choices : [
            'A',
            'B'
        ],
        leftWeight : Number.random(),
        canCancel : true,
        onChoice::(choice) {
            when (choice == 1)
                otherChoices()
                
                
                
            windowEvent.queueAskBoolean(
                prompt: 'Do it?',
                onChoice ::(which) {
                
                }
            );
            
            
        }
    );  
}

@:doMain :: {
    windowEvent.queueChoices(
        choices: [
            "1",
            '2',
            '3'
        ],
        keep:true,
        onChoice::(choice) {
            when(choice == 1)
                windowEvent.queueMessage(
                    text: 'HIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII'
                );
                
            otherChoices();
        }
    );
}

windowEvent.queueCustom(
    keep : true,
    renderable : {
        render :: {
            canvas.blackout(with:'.');
        }
    },
    onEnter ::{
        doMain();
    }
    
);


return empty;
*/







                
                @:mods = preloadMods();
                loadMods(mods);
                


                @:choiceActions = [];
                
                @:genChoices ::{
                    choiceActions->setSize(size:0);
                    @:choiceNames = [];
                    if (onListSlots()->size != 0) ::<= {
                        choiceNames->push(value:'Load');
                        choiceActions->push(value: ::{
                            @:choices = onListSlots();
                            
                            choices->sort(comparator:::(a, b) {
                                when(a < b) -1;
                                when(a > b)  1;
                                return 0;
                            });
                            
                            when (choices->size == 0) ::<= {
                                windowEvent.queueMessage(text: 'No save files were found.');
                            }
                            windowEvent.queueChoices(
                                choices,
                                prompt: 'Load which save?',
                                canCancel: true,
                                onChoice::(choice) {
                                    when(choice == 0) empty;
                                    @:data = onLoadState(slot:choices[choice-1]);
                                    
                                    loading(
                                        message: 'Loading scenario...',
                                        do:: {
                                            this.resetDatabase();
                                            loading(
                                                message: 'Loading save...',
                                                do :: {
                                                    this.load(serialized:JSON.decode(string:data));
                                                    pointOfNoReturn(
                                                        do::<- this.startResume()
                                                    );
                                                }
                                            )
                                        }
                                    );
                                
                                }
                            );                    
                        });
                    }
                
                
                
                    choiceNames->push(value:'New');
                    choiceActions->push(value:::{
                        
                        loading(
                            message: 'Loading scenarios...',
                            do ::{
                                
                                

                                this.resetDatabase();


                                @:enterName = import(module:'game_function.name.mt');


                                @choices = Scenario.database.getAll();
                                choices->sort(comparator:::(a, b) {
                                    when(a.name < b.name) -1;
                                    when(a.name > b.name)  1;
                                    return 0;
                                });
                                @choiceNames = [...choices]->map(to::(value) <- value.name);
                                
                                if (settings.unlockedScenarios == false || settings.unlockedScenarios == empty) ::<= {
                                    choices = [Scenario.database.find(id:'rasa:thechosen')];
                                    choiceNames = ['The Chosen'];
                                }
                                
                                
                                windowEvent.queueChoices(
                                    prompt: 'Select a scenario:',
                                    choices: choiceNames,
                                    canCancel: true,
                                    renderable : {
                                        render :: {
                                            canvas.blackout();
                                        }
                                    },
                                    onChoice::(choice) {
                                        when(choice <= 0) empty;
                                        world.scenario = Scenario.new(base:choices[choice-1]);

                                        @:startNewWorld = ::(name){
                                            world.saveName = name;                        
                                            this.startNew();
                                            //this.startInstance();                            
                                        }

                                        enterName(
                                            prompt: 'Enter a file name.',
                                            canCancel: true,
                                            renderable : {
                                                render :: {
                                                    canvas.blackout();
                                                }  
                                            },
                                            onDone ::(name){
                                                @:currentFiles = onListSlots();

                                                when (currentFiles->findIndex(value:name) != -1) ::<= {
                                                    windowEvent.queueMessage(
                                                        text:'There\'s already a file named ' + name,
                                                        renderable : {
                                                            render ::{
                                                                canvas.blackout();
                                                            }
                                                        }
                                                    );
                                                    windowEvent.queueAskBoolean(
                                                        prompt: 'Overwrite ' + name + '?',
                                                        renderable : {
                                                            render ::{
                                                                canvas.blackout();
                                                            }
                                                        },
                                                        onChoice ::(which) {
                                                            when(!which) empty;
                                                            pointOfNoReturn(
                                                                do::{ 
                                                                    startNewWorld(name)
                                                                }
                                                            )
                                                        }
                                                    );
                                                }
                                            
                                                pointOfNoReturn(
                                                    do::{ 
                                                        startNewWorld(name);
                                                    }
                                                );
                                            }
                                        )
                                    }
                                );  
                            }    
                        )          
                    });
                    
                    
                    if (mods->size != 0) ::<= {
                        choiceNames->push(value:'Mods...');

                        @:modNames = [];
                        @:modList = [];
                        
                        foreach(mods) ::(k, mod) {
                            modNames->push(value:mod.name);
                            modList->push(value:mod);
                        }

                        choiceActions->push(value:::{
                            windowEvent.queueChoices(
                                prompt: 'Loaded mods:',
                                keep:true,
                                canCancel:true,
                                choices: modNames,
                                onChoice ::(choice) {
                                    @:mod = modList[choice-1];
                                    windowEvent.queueMessage(
                                        speaker: 'Mod info...',
                                        text: 
                                            'Name    : ' + mod.name + '\n'+
                                            '         (' + mod.id + ')\n' +
                                            'Author  : ' + mod.author + '\n' +
                                            'Website : ' + mod.website + '\n\n' +
                                            mod.description + 
                                            '\n\nDepends on ' + mod.loadFirst->size + ' mods:\n' + ::<= {
                                                @out = '';
                                                foreach(mod.loadFirst) ::(i, depends) {
                                                    out = out + ' - ' + depends + '\n'
                                                }
                                                return out;
                                            }
                                    )
                                }
                            );
                        });
                    }
                    
                    choiceNames->push(value: 'Credits');
                    choiceActions->push(value ::{
                        this.queueCredits();
                    });
                    
                    
                    choiceNames->push(value: 'Exit');
                    choiceActions->push(value ::<- onQuit());    
                    return choiceNames;            
                }

                
                windowEvent.queueChoices(
                    onGetChoices ::{
                        return genChoices();
                    },
                    topWeight: 0.75,
                    keep : true,
                    jumpTag : 'MainMenu',
                    renderable : {
                        render ::{
                            @: title = 'Wyvern Gate';
                            @:subtitle = '~ A Tale of Wishes ~';
                            canvas.blackout();
                            canvas.movePen(x:
                                canvas.width / 2 - title->length / 2,
                                y: 2
                            );
                                
                            canvas.drawText(
                                text:title
                            );

                            canvas.movePen(x:
                                canvas.width / 2 - subtitle->length / 2,
                                y: 3
                            );
                                
                            canvas.drawText(
                                text:subtitle
                            );
                            
                            
                            
                            @:loc = 'https://github.com/jcorks/wyvern-gate/ (' + VERSION + ')'                            
                            canvas.movePen(
                                x: canvas.width / 2 - loc->length / 2,
                                y: canvas.height - 2
                            );
                            
                            canvas.drawText(
                                text:loc
                            );

                        }
                    },
                    onChoice ::(choice) {
                        choiceActions[choice-1]();                            
                    }
                );
            },

            queueCredits :: {
                windowEvent.queueMessage(
                    text: 'A game by Johnathan "Rasa" Corkery\n'+
                          'https://github.com/jcorks/\n\n' + 
                          'Additional support : Adrian "Radscale" Hernik\n' +
                          'Playtesting        : Caleb Dron\n' +
                          '                     Cane\n'
                );
                
                windowEvent.queueMessage(
                    text: 'Special thanks to:\n' +
                          'Meiyuu\n' +
                          'Drassy\n' +
                          'Nido\n' +
                          'Maztitos\n' +
                          'Dr. San'
                );

                windowEvent.queueMessage(
                    text: 'Also a special thanks to Rocco Botte, who personally advised me to stop watching a video of his. As difficult as it is, I continue to heed his advice to this day.'
                );            
            },
            
            startResume ::{                
                when (world.finished)
                    (import(module:'game_function.newrecord.mt'))(wish:world.wish);
                    
                world.scenario.onResume();
            },
        
            startNew ::{
            


            
            
                
                
                loading(
                    message: 'Creating world...',
                    do ::{
                        world.scenario.base.onBegin(data:world.scenario.data);
                    }
                )
                

                
          
                
            },
            
            gameOver ::(reason) {


                windowEvent.queueCustom(
                    keep : true,
                    jumpTag: "GameOver",
                    renderable : {
                        render :: {
                            @:canvas = import(module:'game_singleton.canvas.mt');
                            canvas.blackout();
                            canvas.commit();
                        }
                    },
                    onEnter :: {
                            
                        windowEvent.queueMessage(
                            text: reason
                        );

                        windowEvent.queueMessage(
                            text: 'Game Over'
                        );

                        this.unlockScenarios();

                        
                        windowEvent.queueCustom(
                            onEnter :: {
                                windowEvent.jumpToTag(name:"GameOver", goBeforeTag: true);
                            }
                        );                    
                    }
                );

                windowEvent.jumpToTag(name:'MainMenu', doResolveNext:true);
            },
            
            unlockScenarios :: {
                if (settings.unlockedScenarios == false || settings.unlockedScenarios == empty) ::<= {
                    settings.unlockedScenarios = true;
                    onSaveSettings_(data:JSON.encode(object:settings));
                    
                    windowEvent.queueMessage(
                        text: "Alternate scenarios of gameplay now unlocked. You can start a new game at anytime to try them."
                    );
                }            
            },
            
            visitIsland ::(key, restorePos, noMenu, atGate, onReady) {            
                @:doVisit :: {
                    if (key != empty) ::<= {
                        key => Item.type;
                        world.island = key.islandEntry;
                    }
                    @:island = world.island;
                    island_ = island;
                    
                    // check if we're AT a location.
                    island.map.title = "(Map of " + island.name + ')';

                    if (restorePos == empty) ::<= {
                        if (atGate == empty) ::<= {
                            @somewhere = LargeMap.getAPosition(map:island.map);
                        }
                    }

                    @hasVisitIsland;
                    if (noMenu == empty || noMenu == false) ::<= {
                        this.islandTravel();
                        if (windowEvent.canJumpToTag(name:'VisitIsland'))
                            windowEvent.jumpToTag(name:'VisitIsland', goBeforeTag:true, doResolveNext:true);
                        hasVisitIsland = true;
                    }
                    when (restorePos == empty && atGate != empty) ::<= {
                        @gate = island.landmarks->filter(by:::(value) <- value.base.id == 'base:wyvern-gate');
                        when(gate->size == 0) empty;
                        
                        gate = gate[0];
                        island.map.setPointer(
                            x: gate.x,
                            y: gate.y
                        );               
                        
                        
                        @gategate = gate.locations->filter(by:::(value) <- value.base.id == 'base:gate');
                        when(gategate->size == 0) empty;
                        
                        this.visitLandmark(
                            landmark:gate,
                            where: ::(landmark)<- gategate[0]
                        );                
                        if (hasVisitIsland)
                            windowEvent.resolveAllQueued(:onReady)
                        else
                            if (onReady)
                                onReady();
                    }
                    if (onReady)
                        onReady();
                }

                if (key != empty && key.islandEntry == empty)
                    loading(
                        message: '...',
                        do ::{
                            key.addIslandEntry(world);
                            doVisit();
                        }
                    )
                else 
                    doVisit();                
                

            },  

            islandTravel ::{
                @:island = world.island;
                
                when(island == empty)
                    error(detail:'No island to make a menu for! Use visitIsland() to set the current island.');
                
                @enteredChoices = false;
                @underFoot;
                @islandTravel = ::{
                    windowEvent.queueCursorMove(
                        leftWeight: 1,
                        topWeight: 1,
                        prompt: 'Traveling...',
                        jumpTag: 'VisitIsland',
                        onMenu :: {
                            islandChoices();
                        },
                        
                        renderable : {
                            render ::{
                                island.map.render();
                                when(underFoot == empty || underFoot->size == 0) empty;


                                
                                @:lines = [];
                                foreach(underFoot)::(i, arr) {


                                    lines->push(value:arr.data.name);

                                    arr.data.discover();
                                    island.map.discover(data:arr.data);                                            
                                    //island.map.setPointer(
                                    //    x: arr.x,
                                    //    y: arr.y
                                    //);
                                
                                }
                                canvas.renderTextFrameGeneral(
                                    title: 'Nearby:',
                                    topWeight : 1,
                                    leftWeight : 1,
                                    lines
                                );
                            }
                        },
                        onMove ::(choice) {
                            
                            @:target = island.landmarks[choice-1];
                            
                            
                            // move by one unit in that direction
                            // or ON it if its within one unit.
                            island.map.movePointerFree(
                                x: if (choice == windowEvent.CURSOR_ACTIONS.RIGHT) 4 else if (choice == windowEvent.CURSOR_ACTIONS.LEFT) -4 else 0,
                                y: if (choice == windowEvent.CURSOR_ACTIONS.DOWN)  4 else if (choice == windowEvent.CURSOR_ACTIONS.UP)   -4 else 0
                            );
                            island.map.title = world.timeString + '                   ';
                            island.incrementTime();
                            island.takeStep();
                            
                            // cancel if we've arrived somewhere
                            underFoot = island.map.getNamedItemsUnderPointerRadius(radius:5);
                            
                        }
                    );
                }

                
                
                
                @:islandChoices = ::{   
                
                    @islandOptions;
                
                    enteredChoices = true;
                    windowEvent.queueChoices(
                        leftWeight: 1,
                        topWeight: 1,
                        prompt: 'What next?',
                        renderable: island.map,
                        canCancel : true,
                        keep: true,
                        jumpTag: 'LandmarkInteraction',
                        onGetChoices ::{
                            islandOptions = [...world.scenario.base.interactionsWalk]->filter(by::(value) <- value.filter(island));
                            
                            @:choices = [...islandOptions]->map(to::(value) <- value.name);
                            @visitable = island.map.getNamedItemsUnderPointerRadius(radius:5);

                            choices->push(value: 'Options');

                            if (visitable != empty) ::<= {
                                foreach(visitable)::(i, vis) {
                                    choices->push(value:'Visit ' + vis.name);                
                                }
                            }
                            
                            return choices;
                        },
                        onChoice::(choice) {
                            @visitable = island.map.getNamedItemsUnderPointerRadius(radius:5);

                            if (choice-1 < islandOptions->size) ::<= {
                                islandOptions[choice-1].onSelect(island);
                                if (!islandOptions[choice-1].keepInteractionMenu && windowEvent.canJumpToTag(name:'LandmarkInteraction')) ::<= {
                                    windowEvent.jumpToTag(name:'LandmarkInteraction', goBeforeTag:true, doResolveNext:true);
                                }
                            } else if (choice-1 == islandOptions->size) ::<= {
                                @:options = [...world.scenario.base.interactionsOptions]->filter(by::(value) <- value.filter(island));
                                @:choices = [...options]->map(to::(value) <- value.name);

                                windowEvent.queueChoices(
                                    leftWeight: 1,
                                    topWeight: 1,
                                    prompt: 'Options',
                                    canCancel : true,
                                    keep: true,
                                    jumpTag: 'LandmarkInteractionOptions',
                                    choices,
                                    onChoice::(choice) {
                                        when(choice == 0) empty;
                                        options[choice-1].onSelect(island);
                                        if (!options[choice-1].keepInteractionMenu && windowEvent.canJumpToTag(name:'LandmarkInteractionOptions'))
                                            windowEvent.jumpToTag(name:'LandmarkInteractionOptions', goBeforeTag:true, doResolveNext:true);
                                    }
                                );
                            } else ::<= {
                                @:landmark = visitable[choice-(islandOptions->size + 1 + 1)].data;

                                @where = ::(landmark) <- landmark.gate;

                                when (landmark.base.pointOfNoReturn == true) ::<= {
                                    windowEvent.queueMessage(
                                        text: "It may be difficult to return... "
                                    );
                                    windowEvent.queueAskBoolean(
                                        prompt:'Enter?',
                                        onChoice::(which) {
                                            if (which == true)
                                                this.visitLandmark(landmark, where);
                                        }
                                    )
                                }
                                this.visitLandmark(landmark, where);                            
                                if (windowEvent.canJumpToTag(name:'LandmarkInteraction')) ::<= {
                                    windowEvent.jumpToTag(name:'LandmarkInteraction', goBeforeTag:true, doResolveNext:true);
                                }

                            }
                        }
                    );
                } 
                islandTravel();           
            },

            
            visitLandmark ::(landmark => Landmark.type, where) {
                if (landmark_ != empty && landmark_.base.ephemeral)
                    landmark_.unloadContent();
                landmark_ = landmark;                
                landmark.loadContent();
                if (where != empty) ::<= {
                    where = where(landmark);
                    if (where != empty)
                        landmark.map.setPointer(
                            x:where.x,
                            y:where.y
                        ); 
                }
                @:windowEvent = import(module:'game_singleton.windowevent.mt');
                @:partyOptions = import(module:'game_function.partyoptions.mt');
                @:world = import(module:'game_singleton.world.mt');
                @:Island = import(module:'game_class.island.mt');
                @:Event  = import(module:'game_mutator.event.mt');

                @:party = world.party;
                
                landmark.updateTitle();
                landmark.base.onVisit(landmark, island:landmark.island);


                
                @stepCount = 0;


                @:landmarkChoices = ::{
                    @landmarkOptions;
                    windowEvent.queueChoices(
                        leftWeight: 1,
                        topWeight: 1,
                        prompt: 'What next?',
                        keep:true,
                        canCancel:true,
                        onGetChoices ::{
                            landmarkOptions = [...world.scenario.base.interactionsWalk]->filter(by::(value) <- value.filter(island:island_, landmark));
                            
                            @:choices = [...landmarkOptions]->map(to::(value) <- value.name);

                            choices->push(value: 'Options');
                            
                            
                            @locationAt = landmark.map.getNamedItemsUnderPointer();
                            if (locationAt != empty) ::<= {
                                foreach(locationAt)::(i, loc) {
                                    choices->push(value:'Check ' + loc.name);
                                }
                            }

                            return choices;                
                        },
                        renderable:landmark.map,
                        onChoice::(choice) {
                            when(choice == empty) empty;
                            @locationAt = landmark.map.getNamedItemsUnderPointer();
                                

                            if (choice-1 < landmarkOptions->size) ::<= {
                                landmarkOptions[choice-1].onSelect(island:island_, landmark);
                            } else if (choice-1 == landmarkOptions->size) ::<= {
                                @:options = [...world.scenario.base.interactionsOptions]->filter(by::(value) <- value.filter(island:island_, landmark));
                                @:choices = [...options]->map(to::(value) <- value.name);

                                windowEvent.queueChoices(
                                    leftWeight: 1,
                                    topWeight: 1,
                                    prompt: 'Options',
                                    canCancel : true,
                                    keep: true,
                                    choices,
                                    onChoice::(choice) {
                                        when(choice == 0) empty;
                                        options[choice-1].onSelect(island:island_, landmark);
                                    }
                                );
                            } else ::<= {
                                choice -= landmarkOptions->size + 2;
                                when(choice >= locationAt->keycount) empty;
                                locationAt = locationAt[choice].data;
                                locationAt.interact();
                            }
                        }
                    );
                }
                
                @nearby;
                windowEvent.queueCursorMove(
                    jumpTag: 'VisitLandmark',
                    onMenu ::{
                        landmarkChoices()
                    },
                    renderable:{
                        render :: {
                            landmark.map.render();
                            
                            when(nearby == empty || nearby->size == 0) empty;
                            
                            @:lines = [];
                            foreach(nearby)::(index, arr) {

                                lines->push(value:arr.name);
                            }
                            canvas.renderTextFrameGeneral(
                                leftWeight: 1,
                                topWeight: 1,
                                lines,
                                title: 'Arrived at:'
                            );
                        }
                    },
                    onMove ::(choice) {
                    
                        // move by one unit in that direction
                        // or ON it if its within one unit.
                        when(!landmark.map.movePointerAdjacent(
                            x: if (choice == windowEvent.CURSOR_ACTIONS.RIGHT) 1 else if (choice == windowEvent.CURSOR_ACTIONS.LEFT) -1 else 0,
                            y: if (choice == windowEvent.CURSOR_ACTIONS.DOWN)  1 else if (choice == windowEvent.CURSOR_ACTIONS.UP)   -1 else 0
                        )) empty;
                        landmark.step();
                        stepCount += 1;

                        
                        // every 5 steps, heal 1% HP if below 1/5th health
                        if (stepCount % 15 == 0) ::<= {
                            foreach(party.members)::(i, member) {
                                if (member.hp < member.stats.HP * 0.2)
                                    member.heal(amount:(member.stats.HP * 0.01)->ceil);
                            }
                        }
                        
                        // cancel if we've arrived somewhere
                        nearby = landmark.map.getNamedItemsUnderPointer();

                        if (nearby != empty && nearby->size > 0)
                            landmark.map.setPointer(
                                x: nearby[0].x,
                                y: nearby[0].y
                            );

                    }                
                )
            },
                
            
            onSaveState : {
                set ::(value) <- onSaveState = value
            },
            onLoadState : {
                set ::(value) <- onLoadState = value
            },
            
            savestate ::{
                onSaveState(slot:world.saveName, data:JSON.encode(object:this.save()));                    
            },

            save ::{    
                @:State = import(module:'game_class.state.mt');
                @:w = world.save();
                return w;
            },
            
            landmark : {
                get ::{
                    when(windowEvent.canJumpToTag(name:'VisitLandmark')) landmark_;
                    landmark_ = empty;
                    return empty;
                }
                
            },
            
            resetDatabase :: {
                Database.reset();
                world.initializeNPCs();
                foreach(modMainOrdered) ::(i, modMain) {
                    modMain.onDatabaseStartup();
                }
            },

            island : {
                get ::<- island_,
                set ::(value) <- island_ = value
            },
            
            load ::(serialized) {
                world.load(serialized);
                @:island = world.island;
                island_ = island;                
            }
        }
    }
).new();
