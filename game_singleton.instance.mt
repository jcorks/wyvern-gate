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
import(module:'game_mutator.entityquality.mt');
import(module:'game_class.inventory.mt');
import(module:'game_mutator.itemenchant.mt');
import(module:'game_class.map.mt');
import(module:'game_class.party.mt');
import(module:'game_mutator.profession.mt');
import(module:'game_class.stateflags.mt');


import(module:'game_mutator.item.mt');
import(module:'game_class.entity.mt');
import(module:'game_mutator.event.mt');
import(module:'game_class.island.mt');
import(module:'game_mutator.landmark.mt');
import(module:'game_mutator.location.mt');





@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
}
@:JSON = import(module:'Matte.Core.JSON');
@:VERSION = '0.1.5a';
@world = import(module:'game_singleton.world.mt');
import(module:'game_function.newrecord.mt');
world.initializeNPCs();

return class(
    name: 'Wyvern.Instance',
    define:::(this) {
        @onSaveState;
        @onLoadState;
        @island_;
        @landmark_;
        
        

        

        
        
        
        
        this.interface = {
            


            mainMenu ::(
                canvasWidth => Number,
                canvasHeight=> Number,
                onSaveState => Function, // for saving,
                onLoadState => Function,
                onListSlots => Function,
                onQuit => Function
            ) {
                canvas.resize(width:canvasWidth, height:canvasHeight);
                this.onSaveState = onSaveState;
                this.onLoadState = onLoadState;                
                
                windowEvent.queueMessage(
                    text: ' Wyvern Gate ' + VERSION + ' '
                );
                windowEvent.queueChoices(
                    choices : ['Load', 'New', 'Quit'],
                    topWeight: 0.75,
                    keep : true,
                    jumpTag : 'MainMenu',
                    renderable : {
                        render ::{
                            canvas.blackout();
                        }
                    },
                    onChoice ::(choice) {
                        match(choice-1) {
                          // Load 
                          (0)::<= {
                            @:choices = onListSlots();
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
                                                                            
                                    this.load(serialized:JSON.decode(string:data));
                                    this.startResume();
                                
                                }
                            );
                          },
                          
                          (1)::<= {
                            canvas.clear();
                            canvas.blackout();

                            @:enterName = import(module:'game_function.name.mt');


                            @:choices = Scenario.database.getAll();
                            @:choiceNames = [...choices]->map(to::(value) <- value.name);
                            
                            
                            windowEvent.queueChoices(
                                prompt: 'Select a scenario:',
                                choices: choiceNames,
                                canCancel: true,
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
                                        onDone ::(name){
                                            @:currentFiles = onListSlots();

                                            when (currentFiles->findIndex(value:name) != -1) ::<= {
                                                windowEvent.queueMessage(text:'There\'s already a file named ' + name);
                                                windowEvent.queueAskBoolean(
                                                    prompt: 'Overwrite ' + name + '?',
                                                    onChoice ::(which) {
                                                        when(!which) empty;
                                                        startNewWorld(name);
                                                    }
                                                );
                                            }
                                        
                                            startNewWorld(name);
                                        }
                                    )
                                }
                            );
                          },
                          
                          (2)::<= {
                            onQuit();
                          }
                        }                            
                    }
                );
            },
            
            startResume ::{                
                when (world.finished)
                    (import(module:'game_function.newrecord.mt'))(wish:world.wish);
                    
                world.scenario.resume();
            },
        
            startNew ::{
            
                @:loadingScreen = ::(message, do) {
                    windowEvent.queueNoDisplay(
                        renderable : {
                            render :: {
                                canvas.blackout();
                                canvas.clear();
                                canvas.blackout();
                                canvas.movePen(
                                    x: canvas.width/2 - message->length/2,
                                    y: canvas.height/2
                                );
                                canvas.drawText(text:message);
                                canvas.commit(renderNow:true);                         
                            }
                        },
                        onEnter ::{},
                        onLeave ::{                        
                            do();
                        }                    
                    )                
                }

            
            
                
                
                loadingScreen(
                    message: 'Loading...',
                    do ::{
                        world.scenario.base.begin(data:world.scenario.data);
                    }
                )
                

                
          
                
            },
            visitIsland ::(where, restorePos) {
                if (where != empty) ::<= {
                    world.island = island;
                }
                @:island = world.island;
                island_ = island;
                
                // check if we're AT a location.
                island.map.title = "(Map of " + island.name + ')';

                if (restorePos == empty) ::<= {
                    @somewhere = LargeMap.getAPosition(map:island.map);
                    island.map.setPointer(
                        x: somewhere.x,
                        y: somewhere.y
                    );               
                }

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
                        onGetChoices ::{
                            islandOptions = [...world.scenario.base.interactionsWalk]->filter(by::(value) <- value.filter(island));
                            
                            @:choices = [...islandOptions]->map(to::(value) <- value.displayName);
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
                            } else if (choice-1 == islandOptions->size) ::<= {
                                @:options = [...world.scenario.base.interactionsOptions]->filter(by::(value) <- value.filter(island));
                                @:choices = [...options]->map(to::(value) <- value.displayName);

                                windowEvent.queueChoices(
                                    leftWeight: 1,
                                    topWeight: 1,
                                    prompt: 'Options',
                                    canCancel : true,
                                    keep: true,
                                    choices,
                                    onChoice::(choice) {
                                        when(choice == 0) empty;
                                        options[choice-1].onSelect(island);
                                    }
                                );
                            } else ::<= {
                                //breakpoint();
                                @:landmark = visitable[choice-(islandOptions->size + 1 + 1)].data;
                                when (landmark.base.pointOfNoReturn == true) ::<= {
                                    windowEvent.queueMessage(
                                        text: "It may be difficult to return... "
                                    );
                                    windowEvent.queueAskBoolean(
                                        prompt:'Enter?',
                                        onChoice::(which) {
                                            if (which == true)
                                                this.visitLandmark(landmark);
                                        }
                                    )
                                }
                                this.visitLandmark(landmark);                            
                            }
                        }
                    );
                }
                islandTravel();


            },  
            
            visitLandmark ::(landmark, where) {
                if (landmark_ != empty && landmark_.base.ephemeral)
                    landmark_.unloadContent();
                landmark_ = landmark;
                if (where != empty)
                    landmark.map.setPointer(
                        x:where.x,
                        y:where.y
                    );                 
                landmark.loadContent();
                @:windowEvent = import(module:'game_singleton.windowevent.mt');
                @:partyOptions = import(module:'game_function.partyoptions.mt');
                @:world = import(module:'game_singleton.world.mt');
                @:Island = import(module:'game_class.island.mt');
                @:Event  = import(module:'game_mutator.event.mt');

                @:party = world.party;
                
                landmark.map.title = landmark.name + ' - ' + world.timeString + '          ';
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
                            
                            @:choices = [...landmarkOptions]->map(to::(value) <- value.displayName);

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
                                @:choices = [...options]->map(to::(value) <- value.displayName);

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
                        landmark.map.movePointerAdjacent(
                            x: if (choice == windowEvent.CURSOR_ACTIONS.RIGHT) 1 else if (choice == windowEvent.CURSOR_ACTIONS.LEFT) -1 else 0,
                            y: if (choice == windowEvent.CURSOR_ACTIONS.DOWN)  1 else if (choice == windowEvent.CURSOR_ACTIONS.UP)   -1 else 0
                        );
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

            island : {
                get ::<- island_
            },
            
            load ::(serialized) {
                world.load(serialized);
            }
        }
    }
).new();
