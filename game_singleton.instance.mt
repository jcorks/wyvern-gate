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
@:dialogue = import(module:'game_singleton.dialogue.mt');
@:Battle = import(module:'game_class.battle.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Landmark = import(module:'game_class.landmark.mt');
@:Island = import(module:'game_class.island.mt');
@:Event  = import(module:'game_class.event.mt');
@:Interaction = import(module:'game_class.interaction.mt');
@:Item = import(module:'game_class.item.mt');
@:namegen = import(module:'game_singleton.namegen.mt');
@:partyOptions = import(module:'game_function.partyoptions.mt');
@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
};
@:JSON = import(module:'Matte.Core.JSON');
@:VERSION = '0.1.3a';
@world = import(module:'game_singleton.world.mt');

return class(
    name: 'Wyvern.Instance',
    define:::(this) {
        @island;
        @landmark;
        @party;
        @onSaveState;
        @onLoadState;
        @stepsSinceLast = 0;

        
        
        
        
        @:aggress::(location, party) {
            @choice = dialogue.choicesNow(
                prompt: 'Aggress how?',
                choices: location.base.aggressiveInteractions,
                canCancel : true
            );
            
            when(choice == 0) empty;
            
            when (location.landmark.peaceful && (dialogue.choicesNow(
                prompt: 'Are you sure?',
                choices: ['Yes', 'No']
            ) == 2)) empty;
            
            
                        
            @:interaction = Interaction.database.find(name:
                location.base.aggressiveInteractions[choice-1]
            );
            
            interaction.onInteract(location, party);

            if (location.landmark.peaceful) ::<= {
                location.landmark.peaceful = false;
                dialogue.message(text:'The people here are now aware of your aggression.');
            };

            
        };
        
        @:systemMenu :: {
            dialogue.choices(
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
                        dialogue.choicesNow(
                            prompt:'Save which slot?',
                            choices: [
                                'Slot 1',
                                'Slot 2',
                                'Slot 3',
                            ],
                            canCancel : true,
                            onChoice::(choice) {
                                when(choice == 0) empty;
                                
                                
                                onSaveState(slot:choice, data:JSON.encode(object:this.state));        
                                dialogue.message(text:'Saved successfully to slot ' + choice);
                            }
                        );
                        
                      },
                      // quit
                      (1)::<= {
                        dialogue.choices(
                            prompt:'Quit?',
                            choices: [
                                'Yes',
                                'No'
                            ],
                            onChoice::(choice) {
                                when(choice == 2) empty;
                            
                            }
                        );
                                        
                      }
                    };                
                }
            );

            


            
        };
        
        
        @:visitIsland :: {

            // check if we're AT a location.
            island.map.title = "(Map of " + island.name + ')';




            dialogue.choices(
                leftWeight: 1,
                topWeight: 1,
                prompt: 'What next?',
                renderable: island.map,
                keep: true,
                onGetChoices ::{
                    @:choices = [
                        'Travel',
                        'Check',
                        'Party',
                        'Look around',
                        'System',
                    ];
                    @visitable = island.map.getNamedItemsUnderPointerRadius(radius:5);

                    if (visitable != empty) ::<= {
                        visitable->foreach(do:::(i, vis) {
                            choices->push(value:'Visit ' + vis.name);                
                        });
                    };
                    return choices;
                },
                onChoice::(choice) {
                    @visitable = island.map.getNamedItemsUnderPointerRadius(radius:5);

                   
                    match(choice-1) {
                      // travel
                      (0): ::<= {

                        dialogue.cursorMove(
                            leftWeight: 1,
                            topWeight: 1,
                            prompt: 'Traveling...',
                            renderable:island.map,
                            onMove ::(choice) {
                                
                                @:target = island.landmarks[choice-1];
                                
                                
                                // move by one unit in that direction
                                // or ON it if its within one unit.
                                island.map.movePointerFree(
                                    x: if (choice == dialogue.CURSOR_ACTIONS.RIGHT) 4 else if (choice == dialogue.CURSOR_ACTIONS.LEFT) -4 else 0,
                                    y: if (choice == dialogue.CURSOR_ACTIONS.DOWN)  4 else if (choice == dialogue.CURSOR_ACTIONS.UP)   -4 else 0
                                );
                                world.stepTime(); 
                                island.map.title = world.timeString + '                   ';
                                island.incrementTime();
                                
                                // cancel if we've arrived somewhere
                                @:arrival = island.map.getNamedItemsUnderPointerRadius(radius:5);
                                if (arrival != empty) ::<= {
                                    arrival->foreach(do:::(i, arr) {
                                        dialogue.message(
                                            text:"The party has arrived at the " + arr.data.name,
                                            onNext::{
                                                arr.data.discover();
                                                island.map.discover(data:arr.data);                                            
                                            }
                                        );
                                        //island.map.setPointer(
                                        //    x: arr.x,
                                        //    y: arr.y
                                        //);
                                    
                                    });
                                    
                                };                            

                            }
                        
                        );
                            
                      },
                    
                      // check
                      (1): ::<= {
                        choice = dialogue.choices(
                            leftWeight: 1,
                            topWeight: 1,
                            prompt: 'Check which?',
                            choices: [
                                'Island',
                            ],
                            canCancel: true,
                            onChoice::(choice){
                                match(choice-1) {
                                  (0): dialogue.message(speaker: 'About ' + island.name, text: island.description)
                                };                                                        
                            }
                        );
                      
                      },
                      

                      (3): ::<= {
                        island.incrementTime();
                        dialogue.message(text:'Nothing to see but the peaceful scenery of ' + island.name + '.');                          
                      },
                      // party options
                      (2): partyOptions(),

                      (4): ::<= {
                        systemMenu();                          
                      },                          
                      
                      // visit landmark
                      default: ::<= {
                        //breakpoint();
                        this.visitLandmark(landmark:visitable[choice-6].data);
                      }
                    };


                
                
                }
            );



        };
        
        this.interface = {
            visitLandmark ::(landmark){
                landmark.map.title = landmark.name + ' - ' + world.timeString + '          ';
                // render pattern
                /*canvas.clear();
                [0, 100]->for(do:::(y) {
                    canvas.movePen(
                        x:((canvas.width)*Number.random())->floor, 
                        y:((canvas.height)*Number.random())->floor
                    );
                    canvas.drawChar(text:',');
                });

                canvas.pushState();
                */
                
                @stepCount = 0;
                dialogue.choices(
                    leftWeight: 1,
                    topWeight: 1,
                    prompt: 'What next?',
                    keep:true,
                    onGetChoices ::{
                        @choices = [                
                            'Walk...',
                            'Party'
                        ];
                        
                        
                        @locationAt = landmark.map.getNamedItemsUnderPointer();
                        if (locationAt != empty) ::<= {
                            locationAt->foreach(do:::(i, loc) {
                                choices->push(value:'Check ' + loc.name);
                            });
                        };

                        return choices;                
                    },
                    renderable:landmark.map,
                    onChoice::(choice) {
                        @locationAt = landmark.map.getNamedItemsUnderPointer();
                            

                            
                        @:MAX_STATIC_CHOICES = 2;
                        match(choice-1) {
                          (0)::<= {
                            
                            @lastChoice = 0;

                            if (false) ::<= {

                                @choices = [];
                                landmark.locations->foreach(do:::(index, location) {
                                    choices->push(value:location.name);
                                });
                                
                                dialogue.choices(
                                    leftWeight: 1,
                                    topWeight: 1,
                                    prompt: 'Walk where?',
                                    choices,
                                    defaultChoice: lastChoice,
                                    canCancel : true,
                                    onChoice::(choice) {
                                        when(choice == 0) send();
                                        lastChoice = choice;
                                        landmark.map.movePointerToward(x:landmark.locations[choice-1].x, y:landmark.locations[choice-1].y);
                                        stepsSinceLast += 1;
                                        if (landmark.peaceful == false) ::<= {
                                            if (stepsSinceLast >= 5 && Number.random() > 0.7) ::<= {
                                                island.addEvent(
                                                    event:Event.Base.database.find(name:'Encounter:Non-peaceful').new(
                                                        island, party, landmark //, currentTime
                                                    )
                                                );
                                                stepsSinceLast = 0;
                                            };
                                        };
                                        when(party.isIncapacitated()) send();



                                        @:arrival = landmark.map.getNamedItemsUnderPointer();
                                        if (arrival != empty) ::<= {
                                            arrival->foreach(do:::(index, arr) {
                                                dialogue.message(
                                                    text:"The party has arrived at " + arr.name
                                                );
                                            });
                                        };                                
                                    }
                                );                 
                                
                                
                            } else ::<= {
                                dialogue.cursorMove(
                                    leftWeight: 1,
                                    topWeight: 1,
                                    prompt: 'Walk which way?',
                                    renderable:landmark.map,
                                    onMove ::(choice) {
                                        lastChoice = choice;
                                        // move by one unit in that direction
                                        // or ON it if its within one unit.
                                        landmark.map.movePointerAdjacent(
                                            x: if (choice == dialogue.CURSOR_ACTIONS.RIGHT) 1 else if (choice == dialogue.CURSOR_ACTIONS.LEFT) -1 else 0,
                                            y: if (choice == dialogue.CURSOR_ACTIONS.DOWN)  1 else if (choice == dialogue.CURSOR_ACTIONS.UP)   -1 else 0
                                        );
                                        landmark.step();
                                        stepCount += 1;
                                        when(party.isIncapacitated()) dialogue.popChoice();


                                        // every 5 steps, heal 1% HP
                                        if (stepCount % 15 == 0) 
                                            party.members->foreach(do:::(i, member) <- member.heal(amount:(member.stats.HP * 0.01)->ceil));
                                        
                                        // cancel if we've arrived somewhere
                                        @:arrival = landmark.map.getNamedItemsUnderPointer();
                                        if (arrival != empty && arrival->keycount > 0) ::<= {
                                            arrival->foreach(do:::(index, arr) {
                                                dialogue.message(
                                                    text:"The party has arrived at the " + arr.name
                                                );
                                            });
                                            landmark.map.setPointer(
                                                x: arrival[0].x,
                                                y: arrival[0].y
                                            );
                                            
                                        };                            

                                    }
                                
                                );
                        
                            };
                          },
                          
                          (1): ::<={
                            partyOptions();
                            landmark.step();
                          },
                          
                          
                          default: ::<= {
                            when(choice == empty) empty;
                            choice -= MAX_STATIC_CHOICES + 1;
                            when(choice >= locationAt->keycount) empty;
                            locationAt = locationAt[choice].data;
                            
                            
                            // initial interaction 
                            // Initial interaction triggers an event.
                            
                            @canInteract = [::] {
                                return locationAt.base.onInteract(location:locationAt);
                            };
                                
                            when(canInteract == false) empty;
                          
                            @:interactionNames = [...locationAt.base.interactions]->map(to:::(value) {
                                return Interaction.database.find(name:value).displayName;
                            });
                                
                            @:choices = [...interactionNames];

                            if (locationAt.base.aggressiveInteractions->keycount)
                                choices->push(value: 'Aggress...');
                                
                            dialogue.choices(
                                prompt: 'Interaction',
                                choices:choices,
                                canCancel : true,
                                keep: true,
                                onChoice::(choice) {
                           
                                    when(choice == 0) empty;

                                    // aggress
                                    when(locationAt.base.aggressiveInteractions->keycount > 0 && choice-1 == locationAt.base.interactions->keycount) ::<= {
                                        aggress(location:locationAt, party);
                                    };
                                    
                                    Interaction.database.find(name:locationAt.base.interactions[choice-1]).onInteract(
                                        location: locationAt,
                                        party
                                    );
                                    landmark.step();                            
                                }
                            );

                          }
                        
                        };
                    }
                );
            },


            mainMenu ::(
                onSaveState => Function, // for saving,
                onLoadState => Function,
            ) {
                this.onSaveState = onSaveState;
                this.onLoadState = onLoadState;
                                
                dialogue.message(
                    text: ' Wyvern Gate ' + VERSION + ' '
                );
                dialogue.message(
                    text: 'Note: this game is under heavy development. Depending on your platform, use either Number keys + Enter, gamepad up/down/left/right / confirm / cancel, or arrow keys / enter / backspace to navigate.\nGoodluck!'
                );                
                dialogue.choices(
                    choices : ['Load', 'New', 'Quit'],
                    topWeight: 0.75,
                    onChoice ::(choice) {
                        match(choice-1) {
                          // Load 
                          (0)::<= {
                            @:choice = dialogue.choices(
                                choices: [
                                    'Slot 1',
                                    'Slot 2',
                                    'Slot 3',
                                ],
                                canCancel: true
                            );
                            when(choice == 0) empty;
                            @:data = onLoadState(slot:choice);

                            when(data == empty)
                                dialogue.message(text:'There is no data in this slot');
                                
                            this.state = JSON.decode(string:data);
                            this.startInstance();
                          },
                          
                          (1)::<= {
                            canvas.clear();
                            @:message = 'Loading...';
                            canvas.movePen(
                                x: canvas.width/2 - message->length/2,
                                y: canvas.height/2
                            );
                            canvas.drawText(text:message);
                            canvas.commit();
                            this.startNew();
                            //this.startInstance();
                          },
                          
                          (2)::<= {
                            dialogue.popChoice();
                          }
                        };                            
                    }
                );
            },
            
        
            startInstance ::{
                /*
                @destination = empty;
                @landmarkChain = [];


                if (destination != empty) ::<= {
                    // user initiated island travel
                    match(destination->type) {
                      (Island.type)::<={
                        island = destination;
                        landmark = empty;
                        world.island = island;
                        
                        // place the player on a random location in the island
                        island.map.setPointer(
                            x: Number.random()*island.map.size,
                            y: Number.random()*island.map.size
                        );                                                

                      },
                      
                      (Landmark.type):::<= {
                        if (landmark != empty)
                            landmarkChain->push(value:landmark);
                        island = destination.island;
                        landmark = destination;
                        world.island = island;
                        landmark.map.setPointer(
                            x: landmark.gate.x,
                            y: landmark.gate.y
                        );                                                

                      }
                      
                      
                    };

                    destination = empty;
                } else ::<= {
                    landmark = empty;
                    // need to go back where we came before back to island                        
                    if (landmarkChain->keycount > 0) ::<={
                        landmark = landmarkChain->pop;
                    };
                };
            
                when(landmark != empty) ::<= {
                    destination = visitLandmark();
                    breakpoint();
                };


                // fallback op                        
                destination = visitIsland();
                breakpoint();
                when(party.isIncapacitated()) ::<= {
                    canvas.clear();
                    dialogue.message(text: 'Perhaps fate has entrusted someone else with the future...');                            
                    party.clear();
                    send();
                };
                */
            },
        
            startNew ::{
            
                @:keyhome = Item.Base.database.find(name:'Wyvern Key').new(
                    creationHint: {
                        nameHint:namegen.island(), levelHint:5
                    }
                );
                
                
                    
                keyhome.addIslandEntry(world);
                island = keyhome.islandEntry;
                world.island = island;
                party = world.party;
                party.inventory.addGold(amount:100);
                // debug
                //party.inventory.addGold(amount:100000);
                
                
                // since both the party members are from this island, 
                // they will already know all its locations
                island.landmarks->foreach(do:::(index, landmark) {
                    landmark.discover(); 
                });
                
                island.map.setPointer(
                    x: island.sizeW * Number.random(),
                    y: island.sizeH * Number.random()
                );               
                
                
                
                @:p0 = island.newInhabitant(speciesHint: island.species[0], levelHint:500);
                @:p1 = island.newInhabitant(speciesHint: island.species[1], levelHint:5);
                // debug
                    party.inventory.add(item:Item.Base.database.find(name:'Wyvern Key of Fire'
                    ).new(from:island.newInhabitant(),rngModHint:true));


                    /*
                    [0, 10]->for(do:::(i) {
                        party.inventory.add(item:Item.Base.database.getRandomFiltered(
                            filter:::(value) <- value.isUnique == false
                        ).new(from:island.newInhabitant(),rngModHint:true));
                    });
                    */

                [0, 3]->for(do:::(i) {
                    @:crystal = Item.Base.database.find(name:'Skill Crystal').new(from:p0);
                    party.inventory.add(item:crystal);
                });




                party.add(member:p0);
                party.add(member:p1);
                
                
                /*
                dialogue.message(
                    text: '... As it were, today is the beginning of a new adventure.'
                );


                dialogue.message(
                    text: '' + party.members[0].name + ' and their faithful companion ' + party.members[1].name + ' have decided to leave their long-time home of ' + island.name + '. Emboldened by countless tales of long lost eras, these 2 set out to discover the vast, mysterious, and treacherous world before them.'
                );

                dialogue.message(
                    text: 'Their first task is to find a way off their island.\nDue to their distances and dangerous winds, travel between sky islands is only done via the Wyvern Gates, ancient portals of seemingly-eternal magick that connect these islands.'
                );
                
                dialogue.message(
                    text: party.members[0].name + ' has done the hard part and acquired a key to the Gate.\nAll thats left is to go to it and find where it leads.'
                );
                */
                
                @:Scene = import(module:'game_class.scene.mt');
                Scene.database.find(name:'scene_intro').act(onDone::{
                    visitIsland();
                    //island.addEvent(
                    //    event:Event.Base.database.find(name:'Encounter:Non-peaceful').new(
                    //        island, party, landmark //, currentTime
                    //    )
                    //);  
                });
                
          
                
            },
            onSaveState : {
                set ::(value) <- onSaveState = value
            },
            onLoadState : {
                set ::(value) <- onLoadState = value
            },
            state : {
                set::(value) {

                    world.state = value.world;
                    party = world.party;
                    island = world.island;
                    landmark = if (value.landmarkIndex == empty) empty else 
                               island.landmarks[value.landmarkIndex];
                },
                get:: {
                    return {
                        landmarkIndex : if (landmark == empty) -1 else island.getLandmarkIndex(landmark),
                        world : world.state
                    };
                }   
            }
        };
    }
).new();