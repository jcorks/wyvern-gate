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
@:Landmark = import(module:'game_class.landmark.mt');
@:Island = import(module:'game_class.island.mt');
@:Event  = import(module:'game_class.event.mt');
@:Interaction = import(module:'game_class.interaction.mt');
@:Item = import(module:'game_class.item.mt');
@:namegen = import(module:'game_singleton.namegen.mt');
@:partyOptions = import(module:'game_function.partyoptions.mt');
@:LargeMap = import(module:'game_singleton.largemap.mt');

import(module:'game_function.pickpartyitem.mt');



/* make sure base loadable classes are available */

import(module:'game_class.statset.mt');
import(module:'game_class.battleai.mt');
import(module:'game_class.entityquality.mt');
import(module:'game_class.inventory.mt');
import(module:'game_class.itemenchant.mt');
import(module:'game_class.map.mt');
import(module:'game_class.party.mt');
import(module:'game_class.profession.mt');
import(module:'game_class.stateflags.mt');


import(module:'game_class.item.mt');
import(module:'game_class.entity.mt');
import(module:'game_class.event.mt');
import(module:'game_class.island.mt');
import(module:'game_class.landmark.mt');
import(module:'game_class.location.mt');





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
        @island;
        @landmark;
        @party;
        @onSaveState;
        @onLoadState;

        
        

        
        @:systemMenu :: {
            windowEvent.queueChoices(
                choices: [
                    'Save',
                    'Quit'
                ],
                canCancel : true,
                onChoice::(choice) {
                    when(choice == 0) empty;
                    
                    match(choice-1) {
                      // save 
                      (0)::<= {
                        this.savestate();
                        windowEvent.queueMessage(text:'Successfully saved world ' + world.saveName);                        
                      },
                      // quit
                      (1)::<= {
                        windowEvent.queueChoices(
                            prompt:'Quit?',
                            choices: [
                                'Yes',
                                'No'
                            ],
                            onChoice::(choice) {
                                when(choice == 2) empty;
                                windowEvent.jumpToTag(name:'MainMenu');
                            }
                        );
                                        
                      }
                    }                
                }
            );

            


            
        }
        
        
        
        
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
                          },
                          
                          (2)::<= {
                            onQuit();
                          }
                        }                            
                    }
                );
            },
            
            startResume ::{
                island = world.island;
                party = world.party;
                
                when (world.finished)
                    (import(module:'game_function.newrecord.mt'))(wish:world.wish);
                    
                    
                this.visitIsland(restorePos:true);            
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
                        onEnter ::{                        
                            do();
                        }                    
                    )                
                }

            
            
                @:story = import(module:'game_singleton.story.mt');
                
                
                @:initialLoad :: {
                        //story.tier = 2;
                    @:keyhome = Item.new(
                        base: Item.Base.database.find(name:'Wyvern Key'),
                        creationHint: {
                            nameHint:namegen.island(), levelHint:story.levelHint
                        }
                    );
                    keyhome.name = 'Wyvern Key: Home';
                    
                    
                        
                    keyhome.addIslandEntry(world);
                    island = keyhome.islandEntry;
                    world.island = island;
                    party = world.party;
                    party.reset();



                    
                    // debug
                        //party.inventory.addGold(amount:100000);

                    
                    // since both the party members are from this island, 
                    // they will already know all its locations
                    foreach(island.landmarks)::(index, landmark) {
                        landmark.discover(); 
                    }
                    
                    
                    
                    @:Species = import(module:'game_class.species.mt');
                    @:p0 = island.newInhabitant(speciesHint: island.species[0], levelHint:story.levelHint);
                    @:p1 = island.newInhabitant(speciesHint: island.species[1], levelHint:story.levelHint-2);
                    // theyre just normal people so theyll have some trouble against 
                    // professionals.
                    p0.normalizeStats();
                    p1.normalizeStats();

                    party.inventory.add(item:Item.new(
                        base:Item.Base.database.find(name:'Sentimental Box'),
                        from:p0
                    ));



                    // debug
                        /*
                        //party.inventory.add(item:Item.Base.database.find(name:'Pickaxe'
                        //).new(from:island.newInhabitant(),rngEnchantHint:true));
                        
                        @:story = import(module:'game_singleton.story.mt');
                        story.foundFireKey = true;
                        story.foundIceKey = true;
                        story.foundThunderKey = true;
                        story.foundLightKey = true;
                        story.tier = 3;
                        
                        party.inventory.addGold(amount:20000);
                        


                        
                        party.inventory.add(item:Item.new(base:Item.Base.database.find(name:'Wyvern Key of Ice'
                        ), from:island.newInhabitant()));
                        party.inventory.add(item:Item.new(base:Item.Base.database.find(name:'Wyvern Key of Thunder'
                        ), from:island.newInhabitant()));
                        party.inventory.add(item:Item.new(base:Item.Base.database.find(name:'Wyvern Key of Light'
                        ), from:island.newInhabitant()));

                        @:story = import(module:'game_singleton.story.mt');
                        

                        

                        party.inventory.maxItems = 50
                        for(0, 20) ::(i) {
                            party.inventory.add(
                                item:Item.new(
                                    base:Item.Base.database.getRandomFiltered(
                                            filter:::(value) <- value.isUnique == false && value.hasQuality
                                    ),
                                    from:island.newInhabitant(),
                                    rngEnchantHint:true
                                )
                            )
                        };
                        */
                        
                        


                        
                        /*
                        @:sword = Item.new(
                            base: Item.Base.database.find(name:'Glaive'),
                            from:p0,
                            materialHint: 'Ray',
                            qualityHint: 'Null',
                            rngEnchantHint: false
                        );

                        @:tome = Item.new(
                            base:Item.Base.database.find(name:'Tome'),
                            from:p0,
                            materialHint: 'Ray',
                            qualityHint: 'Null',
                            rngEnchantHint: false,
                            abilityHint: 'Cure'
                        );
                        party.inventory.add(item:sword);
                        party.inventory.add(item:tome);
                        
                        */


                    party.add(member:p0);
                    party.add(member:p1);
                    
                    
                    /*
                    windowEvent.queueMessage(
                        text: '... As it were, today is the beginning of a new adventure.'
                    );


                    windowEvent.queueMessage(
                        text: '' + party.members[0].name + ' and their faithful companion ' + party.members[1].name + ' have decided to leave their long-time home of ' + island.name + '. Emboldened by countless tales of long lost eras, these 2 set out to discover the vast, mysterious, and treacherous world before them.'
                    );

                    windowEvent.queueMessage(
                        text: 'Their first task is to find a way off their island.\nDue to their distances and dangerous winds, travel between sky islands is only done via the Wyvern Gates, ancient portals of seemingly-eternal magick that connect these islands.'
                    );
                    
                    windowEvent.queueMessage(
                        text: party.members[0].name + ' has done the hard part and acquired a key to the Gate.\nAll thats left is to go to it and find where it leads.'
                    );
                    */
                }
                
                loadingScreen(
                    message: 'Loading...',
                    do ::{
                        initialLoad();
                        @somewhere = LargeMap.getAPosition(map:island.map);
                        island.map.setPointer(
                            x: somewhere.x,
                            y: somewhere.y
                        );               
                        this.savestate();
                        @:Scene = import(module:'game_class.scene.mt');
                        Scene.database.find(name:'scene_intro').act(onDone::{                    
                            this.visitIsland();

                            
                            /*island.addEvent(
                                event:Event.Base.database.find(name:'Encounter:Non-peaceful').new(
                                    island, party, landmark //, currentTime
                                )
                            );*/  
                        });
                    }
                )
                

                
          
                
            },
            visitIsland ::(where, restorePos) {
                if (where != empty) ::<= {
                    island = where;
                    world.island = island;
                }
                
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
                            world.stepTime(); 
                            island.map.title = world.timeString + '                   ';
                            island.incrementTime();
                            
                            // cancel if we've arrived somewhere
                            underFoot = island.map.getNamedItemsUnderPointerRadius(radius:5);
                            
                        }
                    );
                }

                
                
                
                @:islandChoices = ::{   
                    enteredChoices = true;
                    windowEvent.queueChoices(
                        leftWeight: 1,
                        topWeight: 1,
                        prompt: 'What next?',
                        renderable: island.map,
                        canCancel : true,
                        keep: true,
                        onGetChoices ::{
                            @:choices = [
                                'Check',
                                'Party',
                                'Look around',
                                'System',
                            ];
                            @visitable = island.map.getNamedItemsUnderPointerRadius(radius:5);

                            if (visitable != empty) ::<= {
                                foreach(visitable)::(i, vis) {
                                    choices->push(value:'Visit ' + vis.name);                
                                }
                            }
                            return choices;
                        },
                        onChoice::(choice) {
                            @visitable = island.map.getNamedItemsUnderPointerRadius(radius:5);

                           
                            match(choice-1) {
                            
                              // check
                              (0): ::<= {
                                choice = windowEvent.queueChoices(
                                    leftWeight: 1,
                                    topWeight: 1,
                                    prompt: 'Check which?',
                                    choices: [
                                        'Island',
                                    ],
                                    canCancel: true,
                                    onChoice::(choice){
                                        match(choice-1) {
                                          (0): windowEvent.queueMessage(speaker: 'About ' + island.name, text: island.description)
                                        }                                                        
                                    }
                                );
                              
                              },
                              

                              (2): ::<= {
                                island.incrementTime();
                                windowEvent.queueMessage(text:'Nothing to see but the peaceful scenery of ' + island.name + '.');                          
                              },
                              // party options
                              (1): partyOptions(),

                              (3): ::<= {
                                systemMenu();                          
                              },                          
                              
                              // visit landmark
                              default: ::<= {
                                //breakpoint();
                                @:landmark = visitable[choice-5].data;
                                when (landmark.base.pointOfNoReturn == true) ::<= {
                                    windowEvent.queueMessage(
                                        text: "It may be difficult to return... "
                                    );
                                    windowEvent.queueAskBoolean(
                                        prompt:'Enter?',
                                        onChoice::(which) {
                                            if (which == true)
                                                landmark.visit();
                                        }
                                    )
                                }
                                landmark.visit();
                              }
                            }


                        
                        
                        }
                    );
                }
                islandTravel();


            },      
            
            onSaveState : {
                set ::(value) <- onSaveState = value
            },
            onLoadState : {
                set ::(value) <- onLoadState = value
            },
            
            currentIsland : {
                get::<-island
            },
            
            savestate ::{
                onSaveState(slot:world.saveName, data:JSON.encode(object:this.save()));                    
            },

            save ::{    
                @:State = import(module:'game_class.state.mt');
                @:w = world.save();
                return w;
            },
            
            load ::(serialized) {
                world.load(serialized);
            }
        }
    }
).new();
