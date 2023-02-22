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
@:Database = import(module:'class.database.mt');
@:StatSet = import(module:'class.statset.mt');
@:dialogue = import(module:'singleton.dialogue.mt');
@:canvas = import(module:'singleton.canvas.mt');
@:Battle = import(module:'class.battle.mt');
@:random = import(module:'singleton.random.mt');
@:Material = import(module:'class.material.mt');
@:Profession = import(module:'class.profession.mt');
@:Item = import(module:'class.item.mt');
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
                        dialogue.message(
                            speaker: '???',
                            text: "There they are!!"
                        );
                        @:world = import(module:'singleton.world.mt');

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
                            forever(do:::{
                                canvas.clear();
                                dialogue.message(text: 'Perhaps adventuring could wait another day...');                            
                            });
                          }
                        
                        }; 
                    };

                    // jumps to the prev menu lock
                    send();                
                }
            }
        ),
        Interaction.new(
            data : {
                displayName : 'Examine',
                name : 'examine',
                onInteract ::(location, party) {
                    // jumps to the prev menu lock
                    dialogue.message(speaker:location.name, text:location.description);             
                }
            }
        ),

        Interaction.new(
            data : {
                displayName : 'Vandalize',
                name : 'vandalize',
                onInteract ::(location, party) {
                    // jumps to the prev menu lock
                    dialogue.message(text:'You try to vandalize the location, but you do a poor job.');             
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
                        dialogue.message(text:'No one is within the ' + location.base.name);             

                    @talkee;
                    if (choices->keycount == 1) ::<= {
                        talkee = choices[0];                    
                    } else ::<= {
                        @choice = dialogue.choices(
                            prompt: 'Talk to whom?',
                            choices : [...choices]->map(to:::(value) <- value.name),
                            canCancel : true
                        );
                        
                        when(choice == 0) empty;
                        talkee = choices[choice-1];
                    };
                    
                    // if cancelled
                    when(talkee == empty) empty;

                    talkee.interactPerson(
                        party,
                        location
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
                        dialogue.message(
                            speaker: 'Bartender',
                            text: "Nope. Not servin' ya. Get out."
                        );
                    };
                    
                    when(dialogue.choices(
                        prompt: 'Buy a drink? (1G)',
                        choices : [
                            'Yes',
                            'No'
                        ]
                    ) == 2) empty;   
                    
                    when (party.inventory.gold < 5)
                        dialogue.message(text:'Not enough gold...');
                    
                    party.inventory.subtractGold(amount:5);
                    
                    dialogue.message(
                        text: random.pickArrayItem(list:
                            [
                                'The frothy drink calms your soul.',
                                'Tastes a bit fruitier than you would have thought.',
                                'The drink puts you at ease.',
                            ]           
                        )
                    );   


                    
                    party.members->foreach(do:::(index, member) {
                        if (member.mp < member.stats.MP)
                            member.healMP(amount:member.stats.MP * 0.1);
                    });



                    
                    @:chance = Number.random();
                    match(true) {
                      // normal
                      (chance < 0.8)::<= {
                        dialogue.message(
                            text:'Someone sits next to you.'
                        );   
                        
                        @:talkee = location.landmark.island.newInhabitant();
                        talkee.interactPerson(
                            party,
                            location
                        );
                      },

                      // drunkard
                      (chance < 0.9)::<= {                            
                        @:talkee = location.landmark.island.newInhabitant();

                        dialogue.message(
                            text:'Someone stumbles toward you...'
                        );

                        dialogue.message(
                            speaker: '???',
                            text: random.pickArrayItem(
                                list: [
                                    '"Hhheeeyy whaddya ddoin heer"',
                                    '"wwwhaaat? did youu sayy to mee.??"',
                                    '"uugghht gett outtaa my waaayy"'
                                ]
                            )
                        );

                        @:world = import(module:'singleton.world.mt');
                        match(world.battle.start(
                            party,                            
                            allies: party.members,
                            enemies: [talkee],
                            landmark: {}
                        ).result) {
                          (Battle.RESULTS.ALLIES_WIN,
                           Battle.RESULTS.NOONE_WIN): ::<= {
                          },
                          
                          (Battle.RESULTS.ENEMIES_WIN): ::<= {
                            forever(do:::{
                                canvas.clear();
                                dialogue.message(text: 'Perhaps adventuring could wait another day...');                            
                            });
                          }
                        
                        }; 
                        
                        if (talkee.isDead) ::<= {
                            dialogue.message(
                                speaker: 'Bartender',
                                text:"You killed 'em...?"
                            );                            
                            dialogue.message(
                                speaker: 'Bartender',
                                text:"*sigh*"
                            );                            
                            dialogue.message(
                                text:'The guards are alerted of the death.'
                            );                            
                            location.landmark.peaceful = false;
                        } else ::<= {
                            dialogue.message(
                                speaker: 'Bartender',
                                text:'Gah, what a drunk. Sorry \'bout that.'
                            );                            
                        };
                        

                      },
                      
                      default: 
                        dialogue.message(
                            text:'The drink is enjoyed in solitude.'
                        )
                      
                    };
                                                                          


                        
                    

                }
            }
        ),

        Interaction.new(
            data : {
                displayName : 'Mine',
                name : 'mine',
                onInteract ::(location, party) {
                    @:Entity = import(module:'class.entity.mt');

                    if (location.data.charges == empty)
                        location.data.charges = 5+Number.random()*10;



                    @:miners = party.members->filter(by:::(value) <- value.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L).base.name == 'Pickaxe');
                    when(miners->keycount == 0)
                        dialogue.message(text:'No party member has a pickaxe equipped. Ore cannot be mined.');

                    when (location.data.charges <= 0)
                        dialogue.message(text:'The ore vein is depleted...');
                        

                    
                    @:minerNames = [...miners]->map(to:::(value) <- value.name);
                    @choice = dialogue.choices(
                        prompt: 'Who will mine?',
                        choices: minerNames,
                        canCancel : true
                    );
                    @:miner = miners[choice-1];
                    
                    when(choice == 0) empty;
                    
                    [::]{
                        forever(do:::{
                            dialogue.message(text:'*clank clank*');

                            if (Number.random() > 0.9) ::<= {
                                dialogue.message(text:'Oh...?');

                                @:item = Item.Base.database.find(name:'Ore').new(from:miner);
                                party.inventory.add(item);
                                dialogue.message(text:'The party obtained some Ore!');     
                                location.data.charges -= 1;      
                                
                                when (location.data.charges <= 0) ::<= {
                                    dialogue.message(text:'The ore vein is depleted...');
                                    send();
                                };
                                
                            } else ::<= {
                                dialogue.message(text:'Nothing yet...');

                            };
                            when(dialogue.choices(
                                prompt:'Continue?',
                                choices: ['Yes', 'No']
                            ) == 2) send();
                        });
                    };

                    
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
                        dialogue.message(text: 'The party doesn\'t have enough ore to smelt into ingots. 2 units of ore are required per ingot.');

                    party.inventory.remove(item:ores[0]);
                    party.inventory.remove(item:ores[1]);
                    
                    @:metal = Item.Base.database.getRandomWeightedFiltered(filter:::(value) <- value.hasAttribute(attribute:Item.ATTRIBUTE.RAW_METAL)).new();                        
                    dialogue.message(text: 'Smelted 2 ore chunks into a(n) ' + metal.name + '!');
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
                        dialogue.message(
                            speaker: location.ownedBy.name,
                            text: "You're not welcome here!!"
                        );
                        match(world.battle.start(
                            party,                            
                            allies: party.members,
                            enemies: [location.ownedBy],
                            landmark: {}
                        ).result) {
                          (Battle.RESULTS.ALLIES_WIN,
                           Battle.RESULTS.NOONE_WIN): ::<= {
                            location.ownedBy = empty;                          
                          },
                          
                          (Battle.RESULTS.ENEMIES_WIN): ::<= {
                            forever(do:::{
                                canvas.clear();
                                dialogue.message(text: 'Perhaps adventuring could wait another day...');                            
                            });
                          }
                        
                        }; 
                    };

                    @:world = import(module:'singleton.world.mt');
                    when (world.time < world.TIME.MORNING || world.time > world.TIME.EVENING)
                        dialogue.message(text: 'The shop appears to be closed at this hour..');                            


                    [::]{
                        forever(do:::{                    
                            @items = party.inventory.items;
                            //@basePrices = [...items]->map(to:::(value) <- (((value.price * 0.4)/5)->ceil)*5); // compiler bug here if uncomment
                            @basePrices = [];
                            items->foreach(do:::(index, item) {
                                @sellPrice = (((item.price * 0.5)/5)*0.5)->ceil;
                                if (sellPrice < 0) sellPrice = 0;
                                basePrices[index] = sellPrice;
                            });
                            @choices = [];
                            items->foreach(do:::(index, item) {
                                choices->push(value: item.name + '(' + basePrices[index] + 'G)');
                            });
                            
                            @choice = dialogue.choices(
                                choices,
                                prompt: 'Sell which? (current: ' + party.inventory.gold + 'G)',
                                canCancel : true
                            );
                            
                            when(choice == 0) send();
                            
                            @item = items[choice-1];
                            @price = basePrices[choice-1];
                            
                            dialogue.message(text: 'Sold the ' + item.name + ' for ' + price + 'G');

                            party.inventory.addGold(amount:price);
                            party.inventory.remove(item);
                            
                            location.inventory.add(item);
                        });
                    };
                },
                

                
            }
        ),


        Interaction.new(
            data : {
                displayName : 'Buy',
                name : 'buy:shop',
                onInteract ::(location, party) {
                    when (location.landmark.peaceful == false && location.ownedBy != empty) ::<= {
                        dialogue.message(
                            speaker: location.ownedBy.name,
                            text: "You're not welcome here!!"
                        );
                        match(world.battle.start(
                            party,                            
                            allies: party.members,
                            enemies: [location.ownedBy],
                            landmark: {}
                        ).result) {
                          (true): ::<= {
                            location.ownedBy = empty;                          
                          },
                          
                          (false): ::<= {
                            forever(do:::{
                                canvas.clear();
                                dialogue.message(text: 'Perhaps adventuring could wait another day...');                            
                            });
                          }
                        
                        }; 
                    };
                    @:world = import(module:'singleton.world.mt');
                    
                    when (world.time < world.TIME.MORNING || world.time > world.TIME.EVENING)
                        dialogue.message(text: 'The shop appears to be closed at this hour..');                            
 
                    
                    
                    
                    [::]{
                        forever(do:::{                    
                            @items = location.inventory.items;
                            //@basePrices = [...items]->map(to:::(value) <- (((value.price * 0.4)/5)->ceil)*5); // compiler bug here if uncomment
                            @basePrices = [];
                            items->foreach(do:::(index, item) {
                                basePrices[index] = ((item.price * 0.5)/5)->ceil;
                            });
                            @choices = [];
                            items->foreach(do:::(index, item) {
                                choices->push(value: item.name + '(' + basePrices[index] + 'G)');
                            });
                            
                            @choice = dialogue.choices(
                                choices,
                                prompt: 'Buy which? (current: ' + party.inventory.gold + 'G)',
                                canCancel : true
                            );
                            
                            when(choice == 0) send();
                            @item = items[choice-1];
                            @price = basePrices[choice-1];
                            
                            choice = dialogue.choices(
                                prompt: item.name,
                                choices: ['Buy', 'Compare Equipment'],
                                canCancel: true
                            );
                            when(choice == 0) send();
                            
                            match(choice-1) {
                              // buy
                              (0)::<= {
                                
                                when(!party.inventory.subtractGold(amount:price)) dialogue.message(text:'The party cannot afford this.');
                                location.inventory.remove(item);
                                
                                if (item.base.name == 'Wyvern Key' && world.storyFlags.foundFirstKey == false) ::<= {
                                    location.landmark.island.world.storyFlags.foundFirstKey = true;
                                    dialogue.message(
                                        speaker:location.ownedBy.name,
                                        text: 'Going up the strata, eh? Best of luck to ye. Those wyverns are pretty ruthless.'
                                    );
                                    dialogue.message(
                                        speaker:location.ownedBy.name,
                                        text: 'Though, can\'t say I\'m not curious what lies at the top...'
                                    );

                                };
                                
                                
                                dialogue.message(text: 'Bought a(n) ' + item.name);
                                party.inventory.add(item);                              
                              },
                              
                              // compare 
                              (1)::<= {
                                @:memberNames = [...party.members]->map(to:::(value) <- value.name);
                                @:choice = dialogue.choices(
                                    prompt: 'Compare equipment for whom?',
                                    choices: memberNames
                                );
                                @:user = party.members[choice-1];
                                @slot = user.getSlotsForItem(item)[0];
                                @currentEquip = user.getEquipped(slot);
                                
                                currentEquip.equipMod.printDiffRate(
                                    prompt: '(Equip) ' + currentEquip.name + ' -> ' + item.name,
                                    other:item.equipMod
                                );                               
                              }
                            };
                            
                        });
                    };
                },
                

                
            }
        ),
        
        Interaction.new(
            data : {
                displayName : 'Forge',
                name : 'forge',
                onInteract ::(location, party) {
                
                    @:Entity = import(module:'class.entity.mt');
                
                    @:smiths = party.members->filter(by:::(value) <- value.profession.base.name == 'Blacksmith');
                    @:smith = if (smiths->keycount == 0) ::<= {
                        dialogue.message(text:'No one in your party can work the forge (no one is a Blacksmith)');

                        @:world = import(module:'singleton.world.mt');
                        when (world.time < world.TIME.MORNING || world.time > world.TIME.EVENING)                            
                            dialogue.message(text:'The blacksmith here would normally be able to forge for you, but the blacksmith is gone for the night.');

                        dialogue.message(text:'The blacksmith offers to work the forge for you.');
                        when(dialogue.choices(
                            prompt: 'Hire to forge for 100G?',
                            choices: ['Yes', 'No']
                        ) == 2) empty;
                        
                        when(party.inventory.gold < 100)
                            dialogue.message(text:'The party cannot afford to pay the blacksmith.');

                        party.inventory.subtractGold(amount:100);                            
                        return location.ownedBy;
                    } else ::<= {                            
                        @:names = [...smiths]->map(to:::(value) <- value.name);
                        
                        @choice = dialogue.choices(
                            prompt: 'Who should work the forge?',
                            choices: names,
                            canCancel: true
                        );         
                        when(choice == 0) empty;
                        @:hammer = smiths[choice-1].getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L);
                        when (hammer == empty || hammer.base.name != 'Hammer')
                            dialogue.message(text:'Smithing requires a Hammer to be equipped.');


                        return smiths[choice-1];
                    };
                    when(smith == empty) empty;
                        
                    @:items = party.inventory.items->filter(by:::(value) <- value.base.hasAttribute(attribute:Item.ATTRIBUTE.RAW_METAL));
                    when(items->keycount == 0)
                        dialogue.message(text:'No suitable ingots or materials were found in the party inventory.');

                    @:itemNames = [...items]->map(to:::(value) <- value.name);
    
                    @choice = dialogue.choices(
                        prompt: 'Which material?',
                        choices: itemNames,
                        canCancel: true
                    );         
                    when(choice == 0) empty;
                    @:ore = items[choice-1];
                    @:toMake = Item.Base.database.getAll()->filter(
                        by:::(value) <- (
                            value.isUnique == false &&
                            smith.level >= value.levelMinimum &&
                            value.hasAttribute(attribute:Item.ATTRIBUTE.METAL)
                        )
                    );

                    @:outputBase = random.pickArrayItem(list:toMake);
                    choice = dialogue.choices(
                        prompt:'Smith with ' + ore.base.name + '?',
                        choices: ['Yes', 'No']
                    );
                    
                    when(choice == 2) empty;
    
                    @:output = outputBase.new(
                        materialHint: ore.base.name->split(token:' ')[0],
                        from: smith
                    );
                    
                    dialogue.message(
                        speaker: smith.name,
                        text: 'No problem!'
                    );
                    
                    dialogue.message(
                        text:smith.name + ' forged a ' + output.name
                    );
                    party.inventory.remove(item:ore);
                    party.inventory.add(item:output);
                    
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
                        if (item.base.name == 'Wyvern Key') ::<= {
                            keys->push(value: item);
                            keynames->push(value: item.name);
                        };
                            
                    });
                    when(keys->keycount == 0)
                        dialogue.message(text:'Entering a gate requires a key. The party has none.');
                        
                    
                        
                    @choice = dialogue.choices(
                        prompt: 'Enter with which?',
                        choices: keynames,
                        canCancel: true                        
                    );
                    when(choice == 0) empty;

                    canvas.clear();
                    dialogue.message(text:'As the key is pushed in, the gate gently whirrs and glows with a blinding light...');
                    dialogue.message(text:'As you enter, you feel the world around you fade.');
                    dialogue.message(text:'...');

                    @:Event = import(module:'class.event.mt');
                    @:world = import(module:'singleton.world.mt');


                    @:event = Event.Base.database.find(name:'Encounter:GateBoss').new(
                        island:location.landmark.island,
                        party:world.party,
                        currentTime:0, // TODO,
                        landmark:location.landmark
                    );  



                    @:world = import(module:'singleton.world.mt');

                    @:key = keys[choice-1];
                    key.addIslandEntry(world);    
                    send(message:key.islandEntry);


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
                        @:Landmark = import(module:'class.landmark.mt');
                        

                        location.targetLandmark = 
                            Landmark.Base.database.find(name:'Dungeon').new(
                                island:location.landmark.island,
                                x:-1,
                                y:-1
                            )
                        ;
                        
                        
                        location.targetLandmark.floor = location.landmark.floor+1;
                        location.targetLandmark.name = 'Dungeon ('+location.targetLandmark.floor+'F)';
                    };

                    canvas.clear();
                    dialogue.message(text:'The party travels to the next floor.');
                    send(message:location.targetLandmark);


                },
            }
        ),  
        
        Interaction.new(
            data : {
                displayName : 'Explore Pit',
                name : 'explore pit',
                onInteract ::(location, party) {

                    if (location.targetLandmark == empty) ::<={
                        @:Landmark = import(module:'class.landmark.mt');
                        

                        location.targetLandmark = 
                            Landmark.Base.database.find(name:'Treasure Room').new(
                                island:location.landmark.island,
                                x:-1,
                                y:-1
                            )
                        ;
                        
                        
                        location.targetLandmark.floor = location.landmark.floor+1;
                    };

                    canvas.clear();
                    dialogue.message(text:'The party enters the pit full of treasure.');
                    send(message:location.targetLandmark);


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
                    if (location.ownedBy != empty) ::<= {
                        dialogue.message(
                            speaker: location.ownedBy.name,
                            text: "What do you think you're doing?!"
                        );
                        @:world = import(module:'singleton.world.mt');
                        match(world.battle.start(
                            party,                            
                            allies: party.members,
                            enemies: [location.ownedBy],
                            landmark: {}
                        ).result) {
                          (Battle.RESULTS.ALLIES_WIN,
                           Battle.RESULTS.NOONE_WIN): ::<= {
                            location.ownedBy = empty;                          
                          },
                          
                          (Battle.RESULTS.ENEMIES_WIN): ::<= {
                            forever(do:::{
                                canvas.clear();
                                dialogue.message(text: 'Perhaps adventuring could wait another day...');                            
                            });
                          }
                        
                        };                        
                        
                    };
                    
                    when (location.inventory.items->keycount == 0) ::<= {
                        dialogue.message(text: "There was nothing to steal.");                            
                    };
                    
                    @:item = random.pickArrayItem(list:location.inventory.items);
                    dialogue.message(text:'Stole ' + item.name);
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
                
                    @:choice = dialogue.choices(
                        prompt: 'Rest for ' + cost + 'G?',
                        choices: ['Yes', 'No']
                    );

                    when(choice == 2) empty;
                    when(party.inventory.gold < cost)
                        dialogue.message(text:'Not enough gold...');

                    party.inventory.subtractGold(amount:cost);

                    canvas.pushState();
                    canvas.clear();
                    dialogue.message(
                        text: 'A restful slumber is welcomed...'
                    );                    
                    canvas.popState();
                    // get those refreshing 7 hours!
                    @:world = import(module:'singleton.world.mt');
                    [::] {
                        forever(do:::{
                            world.stepTime();
                            if (world.time == world.TIME.MORNING)
                                send();                        
                        });
                    };

                    dialogue.message(
                        text: 'The party is refreshed.'
                    );

                    party.members->foreach(do:::(i, member) {
                        member.rest();
                    });                                    

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
                    
                    @choice = dialogue.choices(
                        leftWeight: 1,
                        topWeight: 1,
                        choices: names,
                        prompt: 'Whom?',
                        canCancel: false
                    );
                    
                    when(choice == 0) empty;
                    
                    @:whom = party.members[choice-1];
                    @cost = ((whom.level + whom.stats.sum/30)*10)->ceil;

                    when(whom.profession.base.name == location.ownedBy.profession.base.name)
                        dialogue.message(
                            text: whom.name + ' is already a(n) ' + location.ownedBy.profession.base.name + '.'
                        );
                    
                    dialogue.message(
                        text:
                            'Profession: ' + location.ownedBy.profession.base.name + '\n\n' +
                            location.ownedBy.profession.base.description + '\n' +
                            'Weapon affinity: ' + location.ownedBy.profession.base.weaponAffinity
                    );


                    dialogue.message(
                        text: 'Changing ' + whom.name + "'s profession from " + whom.profession.base.name + ' to ' + location.ownedBy.profession.base.name + ' will cost ' + cost + 'G.'

                    );

                    when(party.inventory.gold < cost)
                        dialogue.message(
                            text: 'The party cannot afford this.'
                        );


                    when (dialogue.choices(
                        prompt: 'Continue?',
                        choices: ['Yes', 'No']
                    ) == 2) empty;

                    party.inventory.subtractGold(amount:cost);       
                    whom.profession = Profession.Base.database.find(name: location.ownedBy.profession.base.name).new();

                    dialogue.message(
                        text: '' + whom.name + " is now a(n) " + whom.profession.base.name + '.'

                    );
                                                  

                },
            }
        ),        
        
        Interaction.new(
            data : {
                displayName : 'Bet',
                name : 'bet',
                onInteract ::(location, party) {
                    @:Entity = import(module:'class.entity.mt');
                    @:count = 3;
                    @:teamAname = 'The ' + Material.database.getRandom().name + ' ' + Item.Base.database.getRandomFiltered(filter:::(value) <- !value.isUnique).name + 's';
                    @:teamA = [];
                    @:teamBname = 'The ' + Material.database.getRandom().name + ' ' + Item.Base.database.getRandomFiltered(filter:::(value) <- !value.isUnique).name + 's';
                    @:teamB = [];

                    [0, count]->for(do:::(i) {
                        @:combatant = location.landmark.island.newInhabitant();
                        @:weapon = Item.Base.database.getRandomFiltered(
                            filter:::(value) <- (
                                value.isUnique == false &&
                                value.equipType == Item.TYPE.HAND                 
                            )
                        ).new(from:combatant);
                        combatant.equip(item:weapon, slot:Entity.EQUIP_SLOTS.HAND_L, silent:true, inventory: combatant.inventory);

                        teamA->push(value:combatant);
                    });

                    [0, count]->for(do:::(i) {
                        @:combatant = location.landmark.island.newInhabitant();
                        @:weapon = Item.Base.database.getRandomFiltered(
                            filter:::(value) <- (
                                value.isUnique == false &&
                                value.equipType == Item.TYPE.HAND                 
                            )
                        ).new(from:combatant);                        
                        combatant.equip(item:weapon, slot:Entity.EQUIP_SLOTS.HAND_L, silent:true, inventory: combatant.inventory);

                        teamB->push(value:combatant);
                    });


                    
                    dialogue.message(
                        speaker:'Announcer',
                        text:'The next match is about to begin! Here we have "' + teamAname + '" up against "' + teamBname + '"! Place your bets!'
                    );
                    
                    

                    [::]{
                        forever(do:::{
                            @:choice = dialogue.choices(
                                choices: [
                                    teamAname + ' stats',
                                    teamBname + ' stats',
                                    'place bet'
                                ],
                                canCancel: true
                            );
                            
                            when(choice == 0) send();
                            
                            match(choice-1) {
                              // team A examine
                              (0): ::<= {
                                [0, 3]->for(do:::(i) {
                                    dialogue.message(text:teamAname + ' - Member ' + (i+1));
                                    teamA[i].describe();
                                });
                              },

                              // team B examine
                              (1): ::<= {
                                [0, 3]->for(do:::(i) {
                                    dialogue.message(text:teamBname + ' - Member ' + (i+1));
                                    teamB[i].describe();
                                });
                              },
                              
                              // bet
                              (2): ::<= {
                              
                                @bet = 0;
                                
                                @:bets = [
                                    200,
                                    500,
                                    2000,
                                    5000,
                                    15000,
                                    50000,
                                    100000,
                                    1000000
                                ];
                                @choice = dialogue.choices(
                                    prompt: 'Bet how much? (payout - 2:1)',
                                    choices: [...bets]->map(to:::(value) <- String(from:value)),
                                    canCancel: true
                                );
                                when(choice == 0) empty;
                                bet = bets[choice-1];
                                
                                when(party.inventory.gold < bet)
                                    dialogue.message(text:'The party cannot afford this bet.');
                                    
                                choice = dialogue.choices(
                                    prompt: 'Bet on which team?',
                                    choices: [
                                        teamAname,
                                        teamBname
                                    ],
                                    canCancel: true
                                );
                                breakpoint();
                                when(choice == 0) empty;                                                        
                                @betOnA = choice == 1;
                              
                                @:world = import(module:'singleton.world.mt');
                              
                                @aWon = world.battle.start(
                                    party,                            
                                    allies: teamA,
                                    enemies: teamB,
                                    landmark: {},
                                    npcBattle: true
                                ).result;
                                
                                // annouce winner
                                if (aWon) ::<= {
                                    dialogue.message(
                                        text: teamAname + ' wins!'
                                    );                                    
                                
                                } else ::<= {
                                    dialogue.message(
                                        text: teamBname + ' wins!'
                                    );                                    
                                };
                                
                                
                                // payout
                                if ((betOnA && aWon) || (!betOnA && !aWon)) ::<= {
                                    dialogue.message(
                                        text:'The party won ' + (bet)->floor + 'G.'
                                    );                                    
                                    party.inventory.addGold(amount:(bet)->floor);
                                } else ::<= {
                                    dialogue.message(
                                        text:'The party lost ' + bet + 'G.'
                                    );                                    
                                    party.inventory.subtractGold(amount:bet);
                                };  
                                send();                               
                              }

                                
                            };
                            
                        });
                    };
                    
                    
                    
                    
                
                         
                },
                

                
            }
            
            
                        
        ), 
        Interaction.new(
            data : {
                displayName : 'Open Chest',
                name : 'open-chest',
                onInteract ::(location, party) {
                    @:world = import(module:'singleton.world.mt');
                    when(location.inventory.items->keycount == 0)
                        dialogue.message(text:'The chest was empty.');
                    
                    dialogue.message(text:'The party opened the chest...');
                    
                    location.inventory.items->foreach(do:::(i, item) {
                        dialogue.message(text:'The party found a(n) ' + item.name + '.');
                    });
                    
                    location.inventory.items->foreach(do:::(i, item) {
                        world.party.inventory.add(item);
                    });                   
                    location.inventory.clear();

                
                    @:amount = (20 + Number.random()*75)->floor;
                    dialogue.message(text:'The party found ' + amount + 'G');
                    world.party.inventory.addGold(amount);    

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
                    @:world = import(module:'singleton.world.mt');

                    when(world.storyFlags.data_locationsDiscovered <
                         world.storyFlags.data_locationsNeeded) ::<= {
                        when (world.storyFlags.data_locationsDiscovered == 0)
                            dialogue.message(speaker:'Sylvia', text: '"Don\'t forget to visit new locations with the runestone!"');

                        dialogue.message(speaker:'Sylvia', text: '"Hmmm according to the stone, I still need ' + (world.storyFlags.data_locationsNeeded - world.storyFlags.data_locationsDiscovered) + ' rune samples."');
                    };
                }
            }
        ),        
        Interaction.new(
            data : {
                displayName : 'Tablet Trading',
                name : 'sylvia-tablet',
                onInteract ::(location, party) {
                    @:world = import(module:'singleton.world.mt');
                    @:tablets = world.party.inventory.items->filter(by:::(value) <- value.base.name->contains(key:'Tablet ('));
                    
                    when (tablets->keycount == 0) ::<= {
                        dialogue.message(speaker: 'Sylvia', text: '"No tablets, eh? They are pretty hard to come across. I\'ll be here for you when you have any though!"');
                    };
                    
                    @:tabletNames = [...tablets]->map(to:::(value) <- value.name);
                    @choice = dialogue.choices(
                        choices : tabletNames,
                        prompt: 'Give which?',
                        canCancel : true
                    );
                    when(choice == 0) empty;
                    @:tablet = tablets[choice-1];
                    
                    when(dialogue.choices(
                        prompt: 'Give the ' + tablet.name + '?',
                        choices : [
                            'Yes',
                            'No'
                        ]                 
                    ) == 2) empty;
                    
                    world.party.inventory.remove(item:tablet);
                    dialogue.message(speaker: 'Sylvia', text: 'Let\'s see what this one says...');
                    @item;
                    
                    
                    match(tablet.name) {
                      ('Tablet (Green)')::<= { 
                        dialogue.message(speaker: 'Sylvia', text: 
                            random.pickArrayItem(list: [
                                '"Seems to be a personal journal. It\'s stuff like this that reminds me how little we know about the day-to-day"',
                                '"It\'s a .... shopping list? Wait no that can\'t be right.."',
                                '"Some sort of ledger it seems like."',
                                '"An inventory listing of some sort."',
                            ])
                        );
                        
                        dialogue.message(speaker: 'Sylvia', text: '"Here! Thanks again."');
                        item = Item.Base.database.getRandomFiltered(filter:::(value) <- 
                            value.name->contains(key:' Potion') ||
                            value.name->contains(key:'Ingot')
                        );
                      },


                      ('Tablet (Orange)')::<= {
                        dialogue.message(speaker: 'Sylvia', text: 
                            random.pickArrayItem(list: [
                                '"Seems to be a historical recounting, or some sort of official record..."',
                            ])
                        );
                        
                        dialogue.message(speaker: 'Sylvia', text: '"Here! Thanks again."');
                        item = Item.Base.database.getRandomFiltered(filter:::(value) <- 
                            value.hasAttribute(attribute:Item.ATTRIBUTE.WEAPON) &&
                            !value.isUnique
                        );
                      },


                      ('Tablet (Red)')::<= {
                        dialogue.message(speaker: 'Sylvia', text: 
                            random.pickArrayItem(list: [
                                '"Oh wow. It seems to be some sort of religious text.."',
                            ])
                        );
                        
                        dialogue.message(speaker: 'Sylvia', text: '"Here! Thanks again."');
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
                    dialogue.message(speaker:'', text:'The party received a(n) ' + item.name + '!');
                    
                    
                    
                    
                    
                    
                    
                }
            }
        )               
        
    
    ]
);

return Interaction;
