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
@:Database = import(module:'game_class.database.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Battle = import(module:'game_class.battle.mt');
@:random = import(module:'game_singleton.random.mt');
@:Material = import(module:'game_class.material.mt');
@:Profession = import(module:'game_class.profession.mt');
@:Item = import(module:'game_class.item.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:Interaction = class(
    name : 'Wyvern.Interaction',
    statics : {
        database : empty
    },
    define:::(this) {
        Database.setup(
            item: this,
            attributes : {
                name : String,
                displayName : String,
                onInteract : Function
            }
        );
    }
);


Interaction.database = Database.new(
    items : [
        Interaction.new(
            data : {
                name : 'exit',
                displayName : 'Exit',
                onInteract ::(location, party) {
                    when (location.landmark.peaceful == false && (location.landmark.name == 'town' || location.landmark.name == 'city')) ::<= {
                        windowEvent.queueMessage(
                            speaker: '???',
                            text: "There they are!!"
                        );
                        @:world = import(module:'game_singleton.world.mt');

                        match(world.battle.start(
                            party,                            
                            allies: party.members,
                            enemies: [
                                location.landmark.island.newInhabitant(professionHint:'Guard'),
                                location.landmark.island.newInhabitant(professionHint:'Guard'),
                                location.landmark.island.newInhabitant(professionHint:'Guard'),                        
                            ]->map(to:::(value){ value.anonymize(); return value;}),
                            landmark: {}
                        ).result) {
                          (Battle.RESULTS.ALLIES_WIN,
                           Battle.RESULTS.NOONE_WIN): ::<= {
                          },
                          
                          (Battle.RESULTS.ENEMIES_WIN): ::<= {
                            windowEvent.jumpToTag(name:'MainMenu');
                          }
                        
                        }; 
                    };

                    // jumps to the prev menu lock
                    windowEvent.jumpToTag(name:'VisitLandmark', goBeforeTag:true, clearResolve:true);
                }
            }
        ),
        Interaction.new(
            data : {
                displayName : 'Examine',
                name : 'examine',
                onInteract ::(location, party) {
                    // jumps to the prev menu lock
                    windowEvent.queueMessage(speaker:location.name, text:location.description);             
                }
            }
        ),

        Interaction.new(
            data : {
                displayName : 'Vandalize',
                name : 'vandalize',
                onInteract ::(location, party) {
                    // jumps to the prev menu lock
                    windowEvent.queueMessage(text:'You try to vandalize the location, but you do a poor job.');             
                }
            }
        ),


        Interaction.new(
            data : {
                name : 'Stairs',
                displayName : 'Stairs',
                onInteract ::(location, party) {
                    

                }
            }
        ),

        Interaction.new(
            data : {
                name : 'talk',
                displayName : 'Talk',
                onInteract ::(location, party) {
                    // jumps to the prev menu lock
                    @choices = [];
                    if (location.ownedBy != empty)
                        choices->push(value:location.ownedBy);
                    location.occupants->foreach(do:::(index, person) {
                        choices->push(value:person);
                    });
                    
                    when (choices->keycount == 0)
                        windowEvent.queueMessage(text:'No one is within the ' + location.base.name);             

                    @talkee;
                    
                    windowEvent.queueChoices(
                        prompt: 'Talk to whom?',
                        choices : [...choices]->map(to:::(value) <- value.name),
                        canCancel : true,
                        onChoice::(choice) {
                            when(choice == 0) empty;
                            talkee = choices[choice-1];                            

                            // if cancelled
                            when(talkee == empty) empty;


                            if (location.landmark.peaceful == false) ::<= {
                                @:Event = import(module:'game_class.event.mt');

                                if (location.landmark.base.guarded == true) ::<= {
                                    windowEvent.queueMessage(speaker:talkee.name, text:'Guards! Guards! Help!');
                                    location.landmark.island.addEvent(
                                        event:Event.Base.database.find(name:'Encounter:Non-peaceful').new(
                                            island:location.landmark.island, party, landmark:location.landmark //, currentTime
                                        )
                                    );
                                } else ::<= {
                                    @:world = import(module:'game_singleton.world.mt');
                                    windowEvent.queueMessage(speaker:talkee.name, text:'You never should have come here!');
                                    world.battle.start(
                                        party,                            
                                        allies: party.members,
                                        enemies: [talkee],
                                        landmark: {},
                                        onEnd::(result) {
                                            breakpoint();
                                            when(result == Battle.RESULTS.ENEMIES_WIN)
                                                windowEvent.jumpToTag(name:'MainMenu', clearResolve:true);
                                        
                                            location.ownedBy = empty;                                                                        
                                        }
                                    );                                
                                };
                            } else ::<= {
                                talkee.interactPerson(
                                    party,
                                    location
                                );
                            };

                        }
                    );
                    
                }
            }
        ),



        
        Interaction.new(
            data : {
                displayName: 'Buy Drink',
                name : 'drink:tavern',
                onInteract ::(location, party) {
                    when (location.landmark.peaceful == false) ::<= {
                        windowEvent.queueMessage(
                            speaker: 'Bartender',
                            text: "Nope. Not servin' ya. Get out."
                        );
                    };
                    
                    windowEvent.queueAskBoolean(
                        prompt: 'Buy a drink? (1G)',
                        onChoice::(which) {
                            when(which  == false) empty; 
                    when (party.inventory.gold < 5)
                        windowEvent.queueMessage(text:'Not enough gold...');
                    
                        party.inventory.subtractGold(amount:5);
                        
                        windowEvent.queueMessage(
                            text: random.pickArrayItem(list:
                                [
                                    'The frothy drink calms your soul.',
                                    'Tastes a bit fruitier than you would have thought.',
                                    'The drink puts you at ease.',
                                ]           
                            )
                        );   


                        
                        party.members->foreach(do:::(index, member) {
                            if (member.ap < member.stats.AP)
                                member.healAP(amount:member.stats.AP * 0.1);
                        });



                        
                        @:chance = Number.random();
                        match(true) {
                          // normal
                          (chance < 0.6)::<= {
                            windowEvent.queueMessage(
                                text:'Someone sits next to you.'
                            );   
                            
                            @:talkee = location.landmark.island.newInhabitant();
                            talkee.interactPerson(
                                party,
                                location,
                                onDone::{
                                    windowEvent.queueMessage(text:'You finish your drink.');                                
                                }
                            );
                          },
                          

                          // gamblist
                          (chance < 0.8)::<= {
                            windowEvent.queueMessage(
                                text:'Someone sits next to you...'
                            );   
                            
                            @:story = import(module:'game_singleton.story.mt');
                            if (story.gamblistEncountered) ::<= {
                                windowEvent.queueMessage(
                                    text:'... wait it\'s.. huh.'
                                );                               

                                windowEvent.queueMessage(
                                    speaker: 'Wandering Gamblist',
                                    text:'Hello again, stranger.'
                                );                               

                                windowEvent.queueMessage(
                                    speaker: 'Wandering Gamblist',
                                    text:'Care to try your luck again? All it costs is an item of yours. Any will do.'
                                );                               
                            } else ::<= {
                                windowEvent.queueMessage(
                                    speaker: '???',
                                    text:'Hello, stranger.'
                                );                               

                                windowEvent.queueMessage(
                                    speaker: 'Wandering Gamblist',
                                    text:'May I interest you in some... Entertainment? All it costs is an item of yours. Any will do.'
                                );                               
                            };
                            
                            
                            windowEvent.queueAskBoolean(
                                prompt:'Play a game?',
                                onChoice::(which) {
                                    when(false) ::<= {
                                        windowEvent.queueMessage(
                                            speaker: 'Wandering Gamblist',
                                            text:'Suit yourself. Perhaps another time.'
                                        );                               
                                    
                                    };       
                                }
                            );
                          },


                          

                          // drunkard
                          (chance < 1)::<= {                            
                            @:talkee = location.landmark.island.newInhabitant();
                            talkee.anonymize();
                            windowEvent.queueMessage(
                                text:'Someone stumbles toward you...'
                            );

                            windowEvent.queueMessage(
                                speaker: '???',
                                text: random.pickArrayItem(
                                    list: [
                                        '"Hhheeeyy whaddya ddoin heer"',
                                        '"wwwhaaat? did youu sayy to mee.??"',
                                        '"uugghht gett outtaa my waaayy"'
                                    ]
                                )
                            );

                            @:world = import(module:'game_singleton.world.mt');
                            world.battle.start(
                                party,                            
                                allies: party.members,
                                enemies: [talkee],
                                landmark: {},
                                onEnd::(result) {
                                    breakpoint();
                                    when(result == Battle.RESULTS.ENEMIES_WIN)
                                        windowEvent.jumpToTag(name:'MainMenu');
                                
                                    if (talkee.isDead) ::<= {
                                        windowEvent.queueMessage(
                                            speaker: 'Bartender',
                                            text:"You killed 'em...?"
                                        );                            
                                        windowEvent.queueMessage(
                                            speaker: 'Bartender',
                                            text:"*sigh*"
                                        );                            
                                        windowEvent.queueMessage(
                                            text:'The guards are alerted of the death.'
                                        );                            
                                        location.landmark.peaceful = false;
                                    } else ::<= {
                                        windowEvent.queueMessage(
                                            speaker: 'Bartender',
                                            text:'Gah, what a drunk. Sorry \'bout that.'
                                        );                            
                                    };
                                                                
                                }
                            );                            
                            

                          },
                          
                          default: 
                            windowEvent.queueMessage(
                                text:'The drink is enjoyed in solitude.'
                            )
                          
                        };
                                                                              
                                                    
                        }
                    );
                }
            }
        ),

        Interaction.new(
            data : {
                displayName : 'Mine',
                name : 'mine',
                onInteract ::(location, party) {
                    @:Entity = import(module:'game_class.entity.mt');

                    if (location.data.charges == empty)
                        location.data.charges = 5+Number.random()*10;



                    @:miners = party.members->filter(by:::(value) <- value.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L).base.name == 'Pickaxe');
                    when(miners->keycount == 0)
                        windowEvent.queueMessage(text:'No party member has a pickaxe equipped. Ore cannot be mined.');

                    when (location.data.charges <= 0)
                        windowEvent.queueMessage(text:'The ore vein is depleted...');
                        

                    
                    @:minerNames = [...miners]->map(to:::(value) <- value.name);
                    

                    @:mining ::(miner) {
                        windowEvent.queueMessage(text:'*clank clank*');

                        if (Number.random() > 0.9) ::<= {
                            windowEvent.queueMessage(speaker:miner.name, text:'Oh...?');

                            @:item = Item.Base.database.find(name:'Ore').new(from:miner);
                            
                            windowEvent.queueMessage(text:'The party obtained some Ore!');     

                            when (party.inventory.isFull) ::<= {
                                windowEvent.queueMessage(text:'The party\'s inventory is full...');     
                                send();
                            };
                            party.inventory.add(item);


                            location.data.charges -= 1;      
                            
                            when (location.data.charges <= 0) ::<= {
                                windowEvent.queueMessage(text:'The ore vein is depleted...');
                                send();
                            };
                            
                        } else ::<= {
                            windowEvent.queueMessage(text:'Nothing yet...');

                        };
                        windowEvent.queueAskBoolean(
                            prompt:'Continue?',
                            onChoice::(which) {
                                when(which == true)
                                    mining(miner);
                            }
                        );                    
                    };
                    
                    
                    windowEvent.queueChoices(
                        prompt: 'Who will mine?',
                        choices: minerNames,
                        canCancel : true,
                        onChoice ::(choice) {
                            @:miner = miners[choice-1];                    
                            when(choice == 0) empty;
                            mining(miner);
                        }
                    );
                    

                    
                }
            }
        ),
        
        Interaction.new(
            data : {
                displayName : 'Smelt Ore',
                name : 'smelt ore',
                onInteract ::(location, party) {
                    @:ores = party.inventory.items->filter(by:::(value) <- value.base.name == 'Ore');
                    
                    when(ores->keycount < 2)
                        windowEvent.queueMessage(text: 'The party doesn\'t have enough ore to smelt into ingots. 2 units of ore are required per ingot.');

                    party.inventory.remove(item:ores[0]);
                    party.inventory.remove(item:ores[1]);
                    
                    @:metal = Item.Base.database.getRandomWeightedFiltered(filter:::(value) <- value.hasAttribute(attribute:Item.ATTRIBUTE.RAW_METAL)).new();                        
                    windowEvent.queueMessage(text: 'Smelted 2 ore chunks into ' + correctA(word:metal.name) + '!');
                    party.inventory.add(item:metal);                    
                        
                }

            }
        ),        
        

        Interaction.new(
            data : {
                displayName : 'Sell',
                name : 'sell:shop',
                onInteract ::(location, party) {
                    when (location.landmark.peaceful == false && location.ownedBy != empty) ::<= {
                        windowEvent.queueMessage(
                            speaker: location.ownedBy.name,
                            text: "You're not welcome here!!"
                        );
                        world.battle.start(
                            party,                            
                            allies: party.members,
                            enemies: [location.ownedBy],
                            landmark: {},
                            onEnd::(result) {
                                match(result) {
                                  (Battle.RESULTS.ALLIES_WIN,
                                   Battle.RESULTS.NOONE_WIN): ::<= {
                                    location.ownedBy = empty;                          
                                  },
                                  
                                  (Battle.RESULTS.ENEMIES_WIN): ::<= {
                                    windowEvent.jumpToTag(name:'MainMenu');
                                  }
                                };
                            }
                        );
                    };

                    @:world = import(module:'game_singleton.world.mt');
                    when (world.time < world.TIME.MORNING || world.time > world.TIME.EVENING)
                        windowEvent.queueMessage(text: 'The shop appears to be closed at this hour..');                            


                    @:pickItem = import(module:'game_function.pickitem.mt');
                    pickItem(
                        inventory:party.inventory,
                        canCancel: true,
                        leftWeight: 0.5,
                        topWeight: 0.5,
                        onGetPrompt:: <-  'Sell which? (current: ' + party.inventory.gold + 'G)',
                        showGold: true,
                        goldMultiplier: (0.5 / 5)*0.5,
                        onPick::(item) {
                            when(item == empty) empty;

                            @price = (item.price * ((0.5 / 5)*0.5))->ceil;
                            
                            windowEvent.queueMessage(text: 'Sold the ' + item.name + ' for ' + price + 'G');

                            party.inventory.addGold(amount:price);
                            party.inventory.remove(item);
                            
                            location.inventory.add(item);
                        }
                    );
                },
                

                
            }
        ),


        Interaction.new(
            data : {
                displayName : 'Buy',
                name : 'buy:shop',
                onInteract ::(location, party) {
                    when (location.landmark.peaceful == false && location.ownedBy != empty) ::<= {
                        windowEvent.queueMessage(
                            speaker: location.ownedBy.name,
                            text: "You're not welcome here!!"
                        );
                        world.battle.start(
                            party,                            
                            allies: party.members,
                            enemies: [location.ownedBy],
                            landmark: {},
                            onEnd::(result) {
                                match(result) {
                                  (Battle.RESULTS.ALLIES_WIN,
                                   Battle.RESULTS.NOONE_WIN): ::<= {
                                    location.ownedBy = empty;                          
                                  },
                                  
                                  (Battle.RESULTS.ENEMIES_WIN): ::<= {
                                    windowEvent.jumpToTag(name:'MainMenu');
                                  }
                                };
                            }
                        );
                    };
                    @:world = import(module:'game_singleton.world.mt');
                    @:pickItem = import(module:'game_function.pickitem.mt');
                    
                    when (world.time < world.TIME.MORNING || world.time > world.TIME.EVENING)
                        windowEvent.queueMessage(text: 'The shop appears to be closed at this hour..');                            
 
                    
                    
                    
                    pickItem(
                        inventory:location.inventory,
                        canCancel: true,
                        leftWeight: 0.5,
                        topWeight: 0.5,
                        onGetPrompt:: <-  'Buy which? (current: ' + party.inventory.gold + 'G)',
                        showGold: true,
                        goldMultiplier: (0.5 / 5),
                        onPick::(item) {
                            when(item == empty) empty;
                            @price = (item.price * (0.5 / 5))->ceil;
                            
                            windowEvent.queueChoices(
                                prompt: item.name,
                                choices: ['Buy', 'Check', 'Compare Equipment'],
                                canCancel: true,
                                onChoice::(choice) {
                                    when(choice == 0) empty;
                                    
                                    match(choice-1) {
                                      // buy
                                      (0)::<= {
                                        when(world.party.inventory.isFull) ::<= {
                                            windowEvent.queueMessage(text: 'The party\'s inventory is full.');
                                        };
                                            
                                        
                                        when(!party.inventory.subtractGold(amount:price)) windowEvent.queueMessage(text:'The party cannot afford this.');
                                        location.inventory.remove(item);
                                        
                                        if (item.base.name == 'Wyvern Key' && world.storyFlags.foundFirstKey == false) ::<= {
                                            location.landmark.island.world.storyFlags.foundFirstKey = true;
                                            windowEvent.queueMessage(
                                                speaker:location.ownedBy.name,
                                                text: 'Going up the strata, eh? Best of luck to ye. Those wyverns are pretty ruthless.'
                                            );
                                            windowEvent.queueMessage(
                                                speaker:location.ownedBy.name,
                                                text: 'Though, can\'t say I\'m not curious what lies at the top...'
                                            );

                                        };
                                        
                                        
                                        windowEvent.queueMessage(text: 'Bought ' + correctA(word:item.name));
                                        party.inventory.add(item);                              
                                      },
                                      // check
                                      (1)::<= {
                                        item.describe();
                                      },
                                      // compare 
                                      (2)::<= {
                                        @:memberNames = [...party.members]->map(to:::(value) <- value.name);
                                        @:choice = windowEvent.queueChoices(
                                            prompt: 'Compare equipment for whom?',
                                            choices: memberNames,
                                            onChoice::(choice) {
                                                @:user = party.members[choice-1];
                                                @slot = user.getSlotsForItem(item)[0];
                                                @currentEquip = user.getEquipped(slot);
                                                
                                                currentEquip.equipMod.printDiffRate(
                                                    prompt: '(Equip) ' + currentEquip.name + ' -> ' + item.name,
                                                    other:item.equipMod
                                                );                                                                               
                                            }
                                        );
                                      }  
                                    };   
                                }
                            );
                        
                        
                        }
                    );
                },
                

                
            }
        ),
        
        Interaction.new(
            data : {
                displayName : 'Forge',
                name : 'forge',
                onInteract ::(location, party) {
                
                    @:Entity = import(module:'game_class.entity.mt');

                    @:items = party.inventory.items->filter(by:::(value) <- value.base.hasAttribute(attribute:Item.ATTRIBUTE.RAW_METAL));
                    when(items->keycount == 0)
                        windowEvent.queueMessage(text:'No suitable ingots or materials were found in the party inventory.');


                    @charge = false;
                    @smith = empty;

                    @:smithingInAction = :: {
                       
                        @:itemNames = [...items]->map(to:::(value) <- value.name);
        
                        windowEvent.queueChoices(
                            prompt: 'Which material?',
                            choices: itemNames,
                            canCancel: true,
                            onChoice::(choice) {
                                @:ore = items[choice-1];
                                @:toMake = Item.Base.database.getAll()->filter(
                                    by:::(value) <- (
                                        value.isUnique == false &&
                                        smith.level >= value.levelMinimum &&
                                        value.hasAttribute(attribute:Item.ATTRIBUTE.METAL)
                                    )
                                );

                                @:outputBase = random.pickArrayItem(list:toMake);
                                when(windowEvent.queueAskBoolean(
                                    prompt:'Smith with ' + ore.base.name + '?',
                                    onChoice::(which) {
                                    
                                    }
                                )) empty;
                                
                                if (charge)
                                    party.inventory.subtractGold(amount:300);                            
                                
                
                                @:output = outputBase.new(
                                    materialHint: ore.base.name->split(token:' ')[0],
                                    from: smith
                                );
                                
                                windowEvent.queueMessage(
                                    speaker: smith.name,
                                    text: 'No problem!'
                                );
                                
                                windowEvent.queueMessage(
                                    text:smith.name + ' forged a ' + output.name
                                );
                                
                                windowEvent.queueNoDisplay(
                                    onEnter ::{
                                        party.inventory.remove(item:ore);
                                        party.inventory.add(item:output);                                                                                                        
                                    }
                                );
                            }
                        );         
                    };

                
                    @:smiths = party.members->filter(by:::(value) <- value.profession.base.name == 'Blacksmith');
                    if (smiths->keycount == 0) ::<= {
                        windowEvent.queueMessage(text:'No one in your party can work the forge (no one is a Blacksmith)');

                        @:world = import(module:'game_singleton.world.mt');
                        when (world.time < world.TIME.MORNING || world.time > world.TIME.EVENING)                            
                            windowEvent.queueMessage(text:'The blacksmith here would normally be able to forge for you, but the blacksmith is gone for the night.');

                        windowEvent.queueMessage(text:'The blacksmith offers to work the forge for you.');


                        windowEvent.queueAskBoolean(
                            prompt: 'Hire to forge for 300G?',
                            onChoice::(which) {
                                when(which == false) empty;
                                when(party.inventory.gold < 300)
                                    windowEvent.queueMessage(text:'The party cannot afford to pay the blacksmith.');
                                
                                smith = location.ownedBy;
                                charge = true;
                                smithingInAction();
                            }
                        );
                    } else ::<= {                            
                        @:names = [...smiths]->map(to:::(value) <- value.name);
                        
                        windowEvent.queueChoices(
                            prompt: 'Who should work the forge?',
                            choices: names,
                            canCancel: true,
                            onChoice::(choice) {
                                when(choice == 0) empty;
                                @:hammer = smiths[choice-1].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L);
                                when (hammer == empty || hammer.base.name != 'Smithing Hammer')
                                    windowEvent.queueMessage(text:'Smithing requires a Smithing Hammer to be equipped.');


                                smith = smiths[choice-1];
                                smithingInAction();
                            
                            }
                        );         
                    };

                    
                },
                

                
            }
        ),
        
        Interaction.new(
            data : {
                displayName : 'Enter Gate',
                name : 'enter gate',
                onInteract ::(location, party) {

                    @:keys = [];
                    @:keynames = [];
                    party.inventory.items->foreach(do:::(index, item) {
                        if (item.base.name->contains(key:'Wyvern Key')) ::<= {
                            keys->push(value: item);
                            keynames->push(value: item.name);
                        };
                            
                    });
                    when(keys->keycount == 0)
                        windowEvent.queueMessage(text:'Entering a gate requires a key. The party has none.');
                        
                    
                        
                    windowEvent.queueChoices(
                        prompt: 'Enter with which?',
                        choices: keynames,
                        canCancel: true,
                        onChoice:::(choice) {
                            when(choice == 0) empty;
                            canvas.clear();
                            windowEvent.queueMessage(text:'As the key is pushed in, the gate gently whirrs and glows with a blinding light...');
                            windowEvent.queueMessage(text:'As you enter, you feel the world around you fade.', renderable:{render::{canvas.blackout();}});
                            windowEvent.queueMessage(text:'...', renderable:{render::{canvas.blackout();}});
                            
                            windowEvent.queueNoDisplay( 
                                onEnter::{
                                @:Event = import(module:'game_class.event.mt');
                                @:Landmark = import(module:'game_class.landmark.mt');
                                @:world = import(module:'game_singleton.world.mt');
                                @:instance = import(module:'game_singleton.instance.mt');

                                @:d = Landmark.Base.database.find(name:match(keys[choice-1].name) {
                                    ('Wyvern Key of Fire'):    'Fire Wyvern Dimension',
                                    ('Wyvern Key of Ice'):     'Ice Wyvern Dimension',
                                    ('Wyvern Key of Thunder'): 'Thunder Wyvern Dimension',
                                    ('Wyvern Key of Light'):   'Light Wyvern Dimension',
                                    default: 'Unknown Wyvern Dimension'
                                }).new(
                                    island:location.landmark.island,
                                    x: 0,
                                    y: 0
                                );
                                instance.visitLandmark(landmark:d);                        
                            
                            });
                        }
                    );



                },
                

                
            }
        ),
            
        // specifically for exploring different areas of dungeons.
        Interaction.new(
            data : {
                displayName : 'Next Floor',
                name : 'next floor',
                onInteract ::(location, party) {

                    if (location.targetLandmark == empty) ::<={
                    
                        if (location.landmark.floor > 5 && Number.random() > 0.5 - (0.2*(location.landmark.floor - 5))) ::<= {
                            @:Landmark = import(module:'game_class.landmark.mt');
                            
                            location.targetLandmark = 
                                Landmark.Base.database.find(name:'Shrine: Lost Floor').new(
                                    island:location.landmark.island,
                                    x:-1,
                                    y:-1
                                )
                            ;
                                                    
                        } else ::<= {
                            @:Landmark = import(module:'game_class.landmark.mt');
                            
                            location.targetLandmark = 
                                Landmark.Base.database.find(name:'Shrine').new(
                                    island:location.landmark.island,
                                    x:-1,
                                    y:-1,
                                    floorHint:location.landmark.floor+1
                                )
                            ;
                            
                            location.targetLandmark.name = 'Shrine ('+location.targetLandmark.floor+'F)';
                        };
                    };

                    canvas.clear();
                    windowEvent.queueMessage(text:'The party travels to the next floor.', renderable:{render::{canvas.blackout();}});
                    
                    
                    @:instance = import(module:'game_singleton.instance.mt');
                    instance.visitLandmark(landmark:location.targetLandmark);


                },
            }
        ),  


        Interaction.new(
            data : {
                displayName : 'Climb Up',
                name : 'climb up',
                onInteract ::(location, party) {

                    windowEvent.queueMessage(text:'The party uses the ladder to climb up to the surface.', renderable:{render::{canvas.blackout();}});
                    windowEvent.queueNoDisplay(onEnter::{windowEvent.jumpToTag(name:'VisitIsland');});                    
                },
            }
        ),  


        
        Interaction.new(
            data : {
                displayName : 'Explore Pit',
                name : 'explore pit',
                onInteract ::(location, party) {
                    @:world = import(module:'game_singleton.world.mt');
                    @:Event = import(module:'game_class.event.mt');

                    if (location.contested == true) ::<= {
                        @:event = Event.Base.database.find(name:'Encounter:TreasureBoss').new(
                            island:location.landmark.island,
                            party:world.party,
                            currentTime:0, // TODO,
                            landmark:location.landmark
                        );  
                        location.contested = false;
                    } else ::<= {
                        if (location.targetLandmark == empty) ::<={
                            @:Landmark = import(module:'game_class.landmark.mt');
                            

                            location.targetLandmark = 
                                Landmark.Base.database.find(name:'Treasure Room').new(
                                    island:location.landmark.island,
                                    x:-1,
                                    y:-1
                                )
                            ;
                            
                        };
                        @:instance = import(module:'game_singleton.instance.mt');
                        instance.visitLandmark(landmark:location.targetLandmark);


                        canvas.clear();
                    };
                },
            }
        ),          
                  
            
        Interaction.new(
            data : {
                displayName : 'Steal',
                name : 'steal',
                onInteract ::(location, party) {
                
                    // the steal attempt happens first before items 
                    //
                    when (location.inventory.items->keycount == 0) ::<= {
                        windowEvent.queueMessage(text: "There was nothing to steal.");                            
                    };
                    
                    @:item = random.pickArrayItem(list:location.inventory.items);
                    windowEvent.queueMessage(text:'Stole ' + item.name);

                    when(party.inventory.isFull) ::<= {
                        windowEvent.queueMessage(text: '...but the party\'s inventory was full.');
                    };


                    if (location.ownedBy != empty) ::<= {
                        windowEvent.queueMessage(
                            speaker: location.ownedBy.name,
                            text: "What do you think you're doing?!"
                        );
                        @:world = import(module:'game_singleton.world.mt');
                        world.battle.start(
                            party,                            
                            allies: party.members,
                            enemies: [location.ownedBy],
                            landmark: {},
                            onEnd::(result) {
                              match(result) {
                                  (Battle.RESULTS.ALLIES_WIN,
                                   Battle.RESULTS.NOONE_WIN): ::<= {
                                    location.ownedBy = empty;                          
                                  },
                                  
                                  (Battle.RESULTS.ENEMIES_WIN): ::<= {
                                    windowEvent.jumpToTag(name:'MainMenu');
                                  }
                              };
                            }
                        );
                        
                    };
                    



                    location.inventory.remove(item);
                    party.inventory.add(item);                    
                },
            }
        ),
        
        
        
        Interaction.new(
            data : {
                displayName : 'Rest',
                name : 'rest',
                onInteract ::(location, party) {
                    @level = party.members[0].level;
                
                    @:cost = (level * (party.members->keycount)) * 2;
                
                    windowEvent.queueAskBoolean(
                        prompt: 'Rest for ' + cost + 'G?',
                        onChoice::(which) {
                            when(which == false) empty;

                            when(party.inventory.gold < cost)
                                windowEvent.queueMessage(text:'Not enough gold...');

                            party.inventory.subtractGold(amount:cost);


                            windowEvent.queueMessage(
                                text: 'A restful slumber is welcomed...',
                                renderable : {
                                    render::<- canvas.blackout()
                                }
                            );                    



                            // get those refreshing 7 hours!
                            @:world = import(module:'game_singleton.world.mt');
                            [::] {
                                forever(do:::{
                                    world.stepTime();
                                    if (world.time == world.TIME.MORNING)
                                        send();                        
                                });
                            };

                            windowEvent.queueMessage(
                                text: 'The party is refreshed.'
                            );

                            party.members->foreach(do:::(i, member) {
                                member.rest();
                            });      


                        }
                    );
                },
            }
        ),
        
        Interaction.new(
            data : {
                displayName : 'Change Profession',
                name : 'change profession',
                onInteract ::(location, party) {
                    @:names = [];
                    party.members->foreach(do:::(i, member) {
                        names->push(value:member.name);
                    });
                    
                    windowEvent.queueChoices(
                        leftWeight: 1,
                        topWeight: 1,
                        choices: names,
                        prompt: 'Whom?',
                        canCancel: false,
                        onChoice:::(choice) {

                            when(choice == 0) empty;
                            
                            @:whom = party.members[choice-1];
                            @cost = ((whom.level + whom.stats.sum/30)*10)->ceil;

                            when(whom.profession.base.name == location.ownedBy.profession.base.name)
                                windowEvent.queueMessage(
                                    text: whom.name + ' is already ' + correctA(word:location.ownedBy.profession.base.name) + '.'
                                );
                            
                            windowEvent.queueMessage(
                                text:
                                    'Profession: ' + location.ownedBy.profession.base.name + '\n\n' +
                                    location.ownedBy.profession.base.description + '\n' +
                                    'Weapon affinity: ' + location.ownedBy.profession.base.weaponAffinity
                            );


                            windowEvent.queueMessage(
                                text: 'Changing ' + whom.name + "'s profession from " + whom.profession.base.name + ' to ' + location.ownedBy.profession.base.name + ' will cost ' + cost + 'G.'

                            );

                            when(party.inventory.gold < cost)
                                windowEvent.queueMessage(
                                    text: 'The party cannot afford this.'
                                );


                            windowEvent.queueAskBoolean(
                                prompt: 'Continue?',
                                onChoice:::(which) {
                                    when(which == false) empty;
                                    party.inventory.subtractGold(amount:cost);       
                                    whom.profession = Profession.Base.database.find(name: location.ownedBy.profession.base.name).new();

                                    windowEvent.queueMessage(
                                        text: '' + whom.name + " is now " + correctA(word:whom.profession.base.name) + '.'

                                    );
                                }
                            );
                        }
                    );
                },
            }
        ),        
        
        Interaction.new(
            data : {
                displayName : 'Bet',
                name : 'bet',
                onInteract ::(location, party) {
                    @:getAWeapon = ::<-
                        Item.Base.database.getRandomFiltered(
                            filter:::(value) <- (
                                value.isUnique == false &&
                                value.attributes->findIndex(value:Item.ATTRIBUTE.WEAPON) != -1
                            )
                        )                    
                    ;
                
                    @:Entity = import(module:'game_class.entity.mt');
                    @:count = 3;
                    @:teamAname = 'The ' + Material.database.getRandom().name + ' ' + getAWeapon().name + 's';
                    @:teamA = [];
                    @:teamBname = 'The ' + Material.database.getRandom().name + ' ' + getAWeapon().name + 's';
                    @:teamB = [];

                    [0, count]->for(do:::(i) {
                        @:combatant = location.landmark.island.newInhabitant();
                        @:weapon = getAWeapon().new(from:combatant);
                        combatant.equip(item:weapon, slot:Entity.EQUIP_SLOTS.HAND_L, silent:true, inventory: combatant.inventory);

                        teamA->push(value:combatant);
                    });

                    [0, count]->for(do:::(i) {
                        @:combatant = location.landmark.island.newInhabitant();
                        @:weapon = getAWeapon().new(from:combatant);                        
                        combatant.equip(item:weapon, slot:Entity.EQUIP_SLOTS.HAND_L, silent:true, inventory: combatant.inventory);

                        teamB->push(value:combatant);
                    });


                    windowEvent.queueMessage(
                        text:'The croud cheers furiously as the teams get ready.'
                    );
                    
                    windowEvent.queueMessage(
                        speaker:'Announcer',
                        text:'The next match is about to begin! Here we have "' + teamAname + '" up against "' + teamBname + '"! Place your bets!'
                    );
                    
                    

                    windowEvent.queueChoices(
                        choices: [
                            teamAname + ' stats',
                            teamBname + ' stats',
                            'place bet'
                        ],
                        canCancel: true,
                        keep: true,
                        jumpTag: 'Bet',
                        onChoice::(choice) {                    
                            when(choice == 0) empty;
                            
                            match(choice-1) {
                              // team A examine
                              (0): ::<= {
                                [0, 3]->for(do:::(i) {
                                    windowEvent.queueMessage(text:teamAname + ' - Member ' + (i+1));
                                    teamA[i].describe();
                                });
                              },

                              // team B examine
                              (1): ::<= {
                                [0, 3]->for(do:::(i) {
                                    windowEvent.queueMessage(text:teamBname + ' - Member ' + (i+1));
                                    teamB[i].describe();
                                });
                              },
                              
                              // bet
                              (2): ::<= {
                              
                                @bet = 0;
                                
                                @:bets = [
                                    50,
                                    100,
                                    200,
                                    500,
                                    2000,
                                    5000,
                                    15000,
                                    50000,
                                    100000,
                                    1000000
                                ];
                                @choice = windowEvent.queueChoices(
                                    prompt: 'Bet how much? (payout - 2:1)',
                                    choices: [...bets]->map(to:::(value) <- String(from:value)),
                                    canCancel: true,
                                    onChoice::(choice) {
                                        when(choice == 0) empty;
                                        bet = bets[choice-1];
                                        
                                        when(party.inventory.gold < bet)
                                            windowEvent.queueMessage(text:'The party cannot afford this bet.');
                                            
                                        choice = windowEvent.queueChoices(
                                            prompt: 'Bet on which team?',
                                            choices: [
                                                teamAname,
                                                teamBname
                                            ],
                                            canCancel: true,
                                            onChoice::(choice) {
                                                when(choice == 0) empty;                                                        
                                                @betOnA = choice == 1;
                                              
                                                @:world = import(module:'game_singleton.world.mt');
                                              
                                                world.battle.start(
                                                    party,                            
                                                    allies: teamA,
                                                    enemies: teamB,
                                                    landmark: {},
                                                    renderable : {
                                                        render:: {
                                                            canvas.blackout();                                                    
                                                        }
                                                    },
                                                    onTurn ::{
                                                        if (Number.random() < 0.7) ::<= {
                                                            windowEvent.queueMessage(text:random.pickArrayItem(list:[
                                                                '"YEAH, tear them limb from limb!"',
                                                                'The croud jeers at team ' + (if (Number.random() < 0.5) teamAname else teamBname) + '.',  
                                                                'The croud goes silent.',
                                                                'The croud goes wild in an uproar.',
                                                                'The crowd murmurs restlessly.',
                                                                'The crowd gasps.'
                                                            ]));
                                                        };
                                                    },
                                                    npcBattle: true,
                                                    onEnd::(result) {
                                                        @aWon = result == Battle.RESULTS.ALLIES_WIN;
                                                        if (aWon) ::<= {
                                                            windowEvent.queueMessage(
                                                                text: teamAname + ' wins!'
                                                            );                                    
                                                        
                                                        } else ::<= {
                                                            windowEvent.queueMessage(
                                                                text: teamBname + ' wins!'
                                                            );                                    
                                                        };
                                                        
                                                        
                                                        // payout
                                                        if ((betOnA && aWon) || (!betOnA && !aWon)) ::<= {
                                                            windowEvent.queueMessage(
                                                                text:'The party won ' + (bet)->floor + 'G.'
                                                            );                                    
                                                            party.inventory.addGold(amount:(bet)->floor);
                                                        } else ::<= {
                                                            windowEvent.queueMessage(
                                                                text:'The party lost ' + bet + 'G.'
                                                            );                                    
                                                            party.inventory.subtractGold(amount:bet);
                                                        };  
                                                        windowEvent.jumpToTag(name:'Bet', goBeforeTag:true, doResolveNext:true);
                                                        
                                                    }  
                                                );                                           
                                            }
                                        );
                                    }
                                );
                              }
                            };                        
                        }
                    );

                    
                    
                    
                    
                
                         
                },
                

                
            }
            
            
                        
        ), 
        Interaction.new(
            data : {
                displayName : 'Open Chest',
                name : 'open-chest',
                onInteract ::(location, party) {
                    @:world = import(module:'game_singleton.world.mt');
                    when(location.inventory.items->keycount == 0)
                        windowEvent.queueMessage(text:'The chest was empty.');
                    
                    windowEvent.queueMessage(text:'The party opened the chest...');
                    
                    when(world.party.inventory.isFull) ::<= {
                        windowEvent.queueMessage(text: '...but the party\'s inventory was full.');
                    };
                    
                    location.inventory.items->foreach(do:::(i, item) {
                        windowEvent.queueMessage(text:'The party found ' + correctA(word:item.name) + '.');
                    });
                    
                    location.inventory.items->foreach(do:::(i, item) {
                        world.party.inventory.add(item);
                    });                   
                    location.inventory.clear();

                
                    @:amount = (20 + Number.random()*75)->floor;
                    windowEvent.queueMessage(text:'The party found ' + amount + 'G');
                    world.party.inventory.addGold(amount);    

                }
            }
        ),              

        Interaction.new(
            data : {
                displayName : 'Loot',
                name : 'loot',
                onInteract ::(location, party) {
                    @:world = import(module:'game_singleton.world.mt');
                    when(location.inventory.items->keycount == 0)
                        windowEvent.queueMessage(text:location.ownedBy.name + '\'s body contained no items');
                    
                    windowEvent.queueMessage(text:'The party looted the body...');
                    
                    when(world.party.inventory.isFull) ::<= {
                        windowEvent.queueMessage(text: '...but the party\'s inventory was full.');
                    };
                    
                    location.inventory.items->foreach(do:::(i, item) {
                        windowEvent.queueMessage(text:'The party found ' + correctA(word:item.name) + '.');
                    });
                    
                    location.inventory.items->foreach(do:::(i, item) {
                        world.party.inventory.add(item);
                    });                   
                    location.inventory.clear();


                }
            }
        ), 


        Interaction.new(
            data : {
                displayName : 'Compete',
                name : 'compete',
                onInteract ::(location, party) {
                }
            }
        ),
        Interaction.new(
            data : {
                displayName : 'Rune Research',
                name : 'sylvia-research',
                onInteract ::(location, party) {
                    @:world = import(module:'game_singleton.world.mt');

                    when(world.storyFlags.data_locationsDiscovered <
                         world.storyFlags.data_locationsNeeded) ::<= {
                        when (world.storyFlags.data_locationsDiscovered == 0)
                            windowEvent.queueMessage(speaker:'Sylvia', text: '"Don\'t forget to visit new locations with the runestone!"');

                        windowEvent.queueMessage(speaker:'Sylvia', text: '"Hmmm according to the stone, I still need ' + (world.storyFlags.data_locationsNeeded - world.storyFlags.data_locationsDiscovered) + ' rune samples."');
                    };
                }
            }
        ),        
        Interaction.new(
            data : {
                displayName : 'Tablet Trading',
                name : 'sylvia-tablet',
                onInteract ::(location, party) {
                    @:world = import(module:'game_singleton.world.mt');
                    @:tablets = world.party.inventory.items->filter(by:::(value) <- value.base.name->contains(key:'Tablet ('));
                    
                    when (tablets->keycount == 0) ::<= {
                        windowEvent.queueMessage(speaker: 'Sylvia', text: '"No tablets, eh? They are pretty hard to come across. I\'ll be here for you when you have any though!"');
                    };
                    
                    @:tabletNames = [...tablets]->map(to:::(value) <- value.name);
                    @choice = windowEvent.queueChoicesNow(
                        choices : tabletNames,
                        prompt: 'Give which?',
                        canCancel : true
                    );
                    when(choice == 0) empty;
                    @:tablet = tablets[choice-1];
                    
                    when(windowEvent.queueAskBoolean(
                        prompt: 'Give the ' + tablet.name + '?'
                    ) == false) empty;
                    
                    world.party.inventory.remove(item:tablet);
                    windowEvent.queueMessage(speaker: 'Sylvia', text: 'Let\'s see what this one says...');
                    @item;
                    
                    
                    match(tablet.name) {
                      ('Tablet (Green)')::<= { 
                        windowEvent.queueMessage(speaker: 'Sylvia', text: 
                            random.pickArrayItem(list: [
                                '"Seems to be a personal journal. It\'s stuff like this that reminds me how little we know about the day-to-day"',
                                '"It\'s a .... shopping list? Wait no that can\'t be right.."',
                                '"Some sort of ledger it seems like."',
                                '"An inventory listing of some sort."',
                            ])
                        );
                        
                        windowEvent.queueMessage(speaker: 'Sylvia', text: '"Here! Thanks again."');
                        item = Item.Base.database.getRandomFiltered(filter:::(value) <- 
                            value.name->contains(key:' Potion') ||
                            value.name->contains(key:'Ingot')
                        );
                      },


                      ('Tablet (Orange)')::<= {
                        windowEvent.queueMessage(speaker: 'Sylvia', text: 
                            random.pickArrayItem(list: [
                                '"Seems to be a historical recounting, or some sort of official record..."',
                            ])
                        );
                        
                        windowEvent.queueMessage(speaker: 'Sylvia', text: '"Here! Thanks again."');
                        item = Item.Base.database.getRandomFiltered(filter:::(value) <- 
                            value.hasAttribute(attribute:Item.ATTRIBUTE.WEAPON) &&
                            !value.isUnique
                        );
                      },


                      ('Tablet (Red)')::<= {
                        windowEvent.queueMessage(speaker: 'Sylvia', text: 
                            random.pickArrayItem(list: [
                                '"Oh wow. It seems to be some sort of religious text.."',
                            ])
                        );
                        
                        windowEvent.queueMessage(speaker: 'Sylvia', text: '"Here! Thanks again."');
                        item = Item.Base.database.getRandomFiltered(filter:::(value) <- 
                            (value.hasAttribute(attribute:Item.ATTRIBUTE.WEAPON) ||
                             value.equipType == Item.TYPE.RING ||
                             value.equipType == Item.TYPE.TRINKET) &&
                            value.isUnique
                        );
                      }                        
                    
                    };

                    item = item.new(from:location.ownedBy);                    
                    world.party.inventory.add(item);
                    windowEvent.queueMessage(speaker:'', text:'The party received ' + correctA(word:item.name) + '!');
                    
                    
                    
                    
                    
                    
                    
                }
            }
        )               
        
    
    ]
);

return Interaction;
