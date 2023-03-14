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
@:dialogue = import(module:'singleton.dialogue.mt');
@:random = import(module:'singleton.random.mt');
@:Battle = import(module:'class.battle.mt');
@:canvas = import(module:'singleton.canvas.mt');
@:Item = import(module:'class.item.mt');
@:Entity = import(module:'class.entity.mt');
@:Scene = import(module:'class.scene.mt');
@:Event = class(
    statics : {
        Base : empty
    },
    
    
    define:::(this) {
        @timeLeft;
        @duration;
        @base_;
        @party_;
        @island_;
        @startAt;
        @landmark_;

        this.constructor = ::(base, party, island, landmark, currentTime, state) {
            island_ = island;
            party_ = party;
            when (state != empty) ::<= {
                this.state = state;
                return this;
            }; 
            base_ = base; 
            startAt = currentTime;
            landmark_ = landmark;
            duration = base.onEventStart(event:this);
            timeLeft = duration;
            return this;
        };

        this.interface = {
            state : {
                set ::(value) {
                    base_ = Event.Base.database.find(name:value.baseName);
                    timeLeft = value.timeLeft;
                    duration = value.duration;
                    startAt = value.startAt;
                },
                get :: {
                    return {
                        baseName : base_.name,
                        timeLeft : timeLeft,
                        duration : duration,
                        startAt : startAt
                    };    
                }
            },
        
            expired : {
                get :: <- timeLeft == 0
            },
            
            stepTime :: {
                base_.onEventUpdate(event:this);
                if (timeLeft > 0) timeLeft -= 1;
            },
            
            duration : {
                get :: <- duration
            },
            
            island : {
                get :: <- island_
            },
            
            party : {
                get :: <- party_
            },
            
            landmark : {
                get :: <- landmark_
            },
            
            base : {
                get :: <- base_
            }
            
        };
    }

);


Event.Base = class(
    name : 'Wyvern.Event.Base',
    statics : {
        database : empty
    },
    define:::(this) {
        @kind;
        Database.setup(
            item: this,
            attributes : {
                name : String,
                rarity: Number,
                onEventStart : Function,
                onEventUpdate : Function,
                onEventEnd : Function
            }
        );
        
        
        
        this.interface = {
            new :: (island, party, currentTime, landmark, state) {
                return Event.new(base:this, island, party, currentTime, landmark, state);
            }
        };
    }

);



Event.Base.database = Database.new(
    items : [
        Event.Base.new(
            data: {
                name : 'Weather:1',
                rarity: 10,        
                onEventStart ::(event) {
                    // only one weather event at a time.
                    when (event.island.events->any(condition::(value) <- value.base.name->contains(key:'Weather'))) 0;
                    @:world = import(module:'singleton.world.mt');
                    match(world.season) {

                        (world.SEASON.WINTER): dialogue.message(
                            text: random.pickArrayItem(list:[
                                'It starts to snow softly.',
                                'A thick snow obscures your vision.',
                                'A quiet snowfall begins.',
                            ])
                        ),

                        default: dialogue.message(
                            text: random.pickArrayItem(list:[
                                'It starts to rain gently.',
                                'It starts to storm intensely.',
                                'It starts to rain.',
                                'It starts to rain as a gentle fog rolls in.'
                            ])
                        )

                        
                        
                    };
                    return 5+(Number.random()*10)->floor; // number of timesteps active
                },
                
                onEventUpdate ::(event) {
                    
                },
                
                onEventEnd ::(event) {
                    when(event.duration == 0) empty;
                    dialogue.message(
                        text: random.pickArrayItem(list:[
                            'The weather subsides.',
                        ])
                    );                
                    
                }
            }
        ),

        Event.Base.new(
            data: {
                name : 'Encounter:GateBoss',
                rarity: 10000000,        
                onEventStart ::(event) {
                    @:Species = import(module:'class.species.mt');
                    @:Profession = import(module:'class.profession.mt');

                    dialogue.message(speaker: '???', text:'The gates of wyverns are only for use by the chosen.');
                    dialogue.message(speaker: '???', text:'You shall be judged.');
                    
                    @chance = Number.random(); 
                    @:island = event.island;   
                    @:party = event.party;

                    @lackey0 = Entity.new(
                        speciesHint:    Species.database.find(name:'Wyvern'),
                        levelHint:      event.island.levelMin,
                        professionHint: 'Disciple'
                    );
                    @lackey1 = Entity.new(
                        speciesHint:    Species.database.find(name:'Wyvern'),
                        levelHint:      event.island.levelMin,
                        professionHint: 'Disciple'
                    );
                    @boss = Entity.new(
                        speciesHint:    Species.database.find(name:'Wyvern'),
                        levelHint:      event.island.levelMax,
                        professionHint: 'Keeper'
                    );



                    @enemies = [
                        lackey0,
                        boss,
                        lackey1               
                    ];
                    
                    
                    [::] {
                        forever(do:::{
                            boss.autoLevel();
                            if (boss.level >= island.levelMax)
                                send();                                    
                        });
                    };


                    enemies->foreach(do:::(index, e) {
                        e.anonymize();
                    });
                    @:world = import(module:'singleton.world.mt');
                    
                    [::] {
                        forever(do:::{
                            match(world.battle.start(
                                party,
                                
                                allies: party.members,
                                enemies,
                                
                                landmark: {},
                                onStart :: {

                                }
                            ).result) {
                              (Battle.RESULTS.ALLIES_WIN): ::<= {
                                canvas.clear();
                                dialogue.message(speaker: '???', text:'You are worthy of this key\'s use.');                              
                                dialogue.message(text:'The world around you warps until you are brought to your feet on a new land.');                              
                                dialogue.message(text:'Something falls to your feet.');                              
                                
                                /*
                                @message = 'The party was given a Tablet.';
                                @:item = Item.new(
                                    base: Item.Base.database.find(name:'Tablet')
                                );
                                */
                                @message = 'The party picks it up and puts it in their inventory.';
                                @:item = Item.new(
                                    base: Item.Base.database.getRandomFiltered(filter::(value) <- value.isUnique)
                                );
                                
                                dialogue.message(text: message);
                                when(world.party.inventory.isFull) ::<= {
                                    dialogue.message(text: '...but the party\'s inventory was full.');
                                    send();
                                };
                                
                                party.inventory.add(item);


                                send();
                              },
                              
                              (Battle.RESULTS.ENEMIES_WIN): ::<= {
                                send();
                              },
                              
                              
                              (Battle.RESULTS.NOONE_WIN): ::<= {
                                dialogue.message(speaker: '???', text:'Judgement shall be brought forth.');                              
                              }
                            };
                        });
                    };
                    
                    
                    
                    return 0;              
                    
                },
                
                onEventUpdate ::(event) {
                    
                },
                
                onEventEnd ::(event) {                    
                }
            }
        ),
        
        Event.Base.new(
            data: {
                name : 'Encounter:TreasureBoss',
                rarity: 10000000,        
                onEventStart ::(event) {
                    
                    @chance = Number.random(); 
                    @:island = event.island;   
                    @:party = event.party;
                    @enemies = [
                        island.newHostileCreature(),
                        island.newHostileCreature(),
                        island.newHostileCreature()                        
                    ];
                    
                    
                    @:boss = enemies[1];

                    
                    [::] {
                        forever(do:::{
                            boss.autoLevel();
                            if (boss.level >= (1+(0.05*(event.landmark.floor/3))) * (island.levelMax))
                                send();                                    
                        });
                    };


                    @:world = import(module:'singleton.world.mt');
                    
                    [::] {
                        forever(do:::{
                            match(world.battle.start(
                                party,
                                
                                allies: party.members,
                                enemies,
                                exp:true,
                                landmark: {},
                                onStart :: {
                                }
                            ).result) {
                              (Battle.RESULTS.ALLIES_WIN): ::<= {
                                @:loot = [];
                                enemies->foreach(do:::(index, enemy) {
                                    enemy.inventory.items->foreach(do:::(index, item) {
                                        if (Number.random() > 0.7 && loot->keycount == 0) ::<= {
                                            loot->push(value:enemy.inventory.remove(item));
                                        };
                                    });
                                });
                                
                                if (loot->keycount > 0) ::<= {
                                    dialogue.message(text: 'It looks like they dropped some items during the fight...');
                                    @message = 'The party found:\n\n';
                                    loot->foreach(do:::(index, item) {
                                        message = message + item.name + '\n';
                                        party.inventory.add(item);
                                    });
                                    
                                    
                                    
                                    dialogue.message(text: message);
                                };
                                send();
                              },
                              
                              (Battle.RESULTS.ENEMIES_WIN): ::<= {
                                send();
                              },
                              
                              
                              (Battle.RESULTS.NOONE_WIN): ::<= {
                                dialogue.message(text:'The ' + boss.name + ' corners you!');                              
                              }
                            };
                        });
                    };
                    
                    return 0;              
                    
                },
                
                onEventUpdate ::(event) {
                    
                },
                
                onEventEnd ::(event) {                    
                }
            }
        ),        
        
        Event.Base.new(
            data: {
                name : 'Chest:Normal',
                rarity: 1, //5        
                onEventStart ::(event) {
                    @:party = event.party;
                    dialogue.message(text:'What\'s this?');
                    dialogue.message(text:'The party trips over a hidden chest!');
                    when(dialogue.askBoolean(
                        prompt: 'Open the chest?'
                    ) == false) 0;
                    
                    
                    @:opener = party.members[dialogue.choicesNow(
                        prompt: 'Who opens up the chest?',
                        choices : [...party.members]->map(to:::(value) <- value.name)
                    )-1];
                    
                    
                    dialogue.message(text:'The party opens the chest...'); 
                    @:Damage = import(module:'class.damage.mt');
                    
                    when(Number.random() < 0.5) ::<= {
                        dialogue.message(text:'A trap is triggered, and a volley of arrows springs form the chest!'); 
                        if (Number.random() < 0.5) ::<= {
                            dialogue.message(text:opener.name + ' narrowly dodges the trap.');                         
                        } else ::<= {
                            opener.damage(
                                from: opener,
                                damage: Damage.new(
                                    amount:opener.stats.HP * (0.7),
                                    damageType : Damage.TYPE.PHYS,
                                    damageClass: Damage.CLASS.HP
                                )
                            );
                        };
                        return 0;
                    }; 
                    
                    
                    @:itemCount = (2+Number.random()*3)->floor;
                    
                    dialogue.message(text:'The chest contained ' + itemCount + ' items!'); 
                    [0, itemCount]->for(do:::(index) {
                        @:item = Item.Base.database.getRandom().new(from:opener);
                        @message = 'The party found a(n) ';
                        message = message + item.name;
                        dialogue.message(text: message);

                        when(party.inventory.isFull) ::<= {
                            dialogue.message(text: '...but the party\'s inventory was full.');
                        };

                        party.inventory.add(item);
                        
                    });    
                
                    return 0; // number of timesteps active
                },
                
                onEventUpdate ::(event) {
                    
                },
                
                onEventEnd ::(event) {

                }
            }
        ),


        Event.Base.new(
            data: {
                name : 'BBQ',
                rarity: 1, //5        
                onEventStart ::(event) {
                    @:party = event.party;
                    dialogue.message(speaker: '???', text:'"Hey!"');
                    dialogue.message(text:'Someone calls out to the party.');
                    dialogue.message(text:'They are by a fire enjoying a meal.');
                    dialogue.message(speaker: '???', text:'"Care to join me? There\'s plenty to share!"');

                    when(dialogue.askBoolean(
                        prompt:'Sit by the fire?'
                    ) == false) ::<= {
                        dialogue.message(speaker:'???', text:'"Ah, I understand. Stay safe out there!"');
                        return 0;
                    };

                    dialogue.message(text:'The party is given some food.');

                    @StatSet = import(module:'class.statset.mt');
                    if (Number.random() < 0.8) ::<= {
                        dialogue.message(text:'The food is delicious.');
                        event.party.members->foreach(do:::(index, member) {
                            @oldStats = StatSet.new();
                            oldStats.state = member.stats.state;
                            member.stats.add(stats:StatSet.new(HP:(oldStats.HP*0.1)->ceil, MP:(oldStats.MP*0.1)->ceil));
                            oldStats.printDiff(other:member.stats, prompt:member.name + ': Mmmm...');

                            member.heal(amount:member.stats.HP * 0.1);
                            member.healMP(amount:member.stats.MP * 0.1);
                        });
                        
                    } else ::<= {
                        dialogue.message(text:'The food tastes terrible. The party feels ill.');
                        @:Damage = import(module:'class.damage.mt');
                        event.party.members->foreach(do:::(index, member) {
                            @oldStats = StatSet.new();
                            oldStats.state = member.stats.state;
                            member.stats.add(stats:StatSet.new(HP:-(oldStats.HP*0.1)->ceil, MP:-(oldStats.MP*0.1)->ceil));
                            oldStats.printDiff(other:member.stats, prompt:member.name + ': Ugh...');


                            member.damage(
                                from: member,
                                damage: Damage.new(
                                    amount:member.stats.MP * (0.1),
                                    damageType : Damage.TYPE.PHYS,
                                    damageClass: Damage.CLASS.MP
                                )
                            );
                        });
                    
                    };

                    @:nicePerson = event.island.newInhabitant();
                    nicePerson.interactPerson(
                        party:event.party
                    );

                    if (!party.isMember(entity:nicePerson)) ::<= {
                        dialogue.message(text:'You thank the person and continue on your way.');  
                    };
                    
                    return 0; // number of timesteps active
                },
                
                onEventUpdate ::(event) {
                    
                },
                
                onEventEnd ::(event) {

                }
            }
        ),

        Event.Base.new(
            data: {
                name : 'Camp out',
                rarity: 1, //5        
                onEventStart ::(event) {
                    @:party = event.party;
                    
                    if (party.members->keycount == 1) ::<= {
                        dialogue.message(
                            speaker:party.members[0].name,
                            text:'This looks like a good place to rest...'
                        );
                    } else ::<= {
                        dialogue.message(
                            speaker:party.members[1].name,
                            text:'"Can we take a break for a bit?"'
                        );
                    };

                    when(dialogue.askBoolean(
                        prompt:'Rest?'
                    ) == false) ::<= {
                        dialogue.message(speaker:'???', text:'The party continues on their way.');
                        return 0;
                    };


                    canvas.pushState();
                    canvas.clear();

                    dialogue.message(text:
                        random.pickArrayItem(
                            list:
                            
                            if (party.members->keycount == 1)
                                [
                                    party.members[0].name + ' sits next to the campfire in a peaceful silence.'
                                ]                                
                            else
                                [
                                    'The party starts a fire and huddles up close to it, resting in silence.',
                                    'The party makes a fire and sits, excitedly talking about the most recent endaevors.',
                                    'The party sets up camp, and sleeps for a brief time.'   
                                ]
                                
                        )
                    );
                    canvas.popState();
                    @:world = import(module:'singleton.world.mt');
                    [0, 5*3]->for(do:::(i) {
                        world.stepTime();
                    });

                    event.party.members->foreach(do:::(index, member) {
                        member.heal(amount:member.stats.HP * 0.3);
                        member.healMP(amount:member.stats.MP * 0.3);
                    });

                    return 0; // number of timesteps active
                },
                
                onEventUpdate ::(event) {
                    
                },
                
                onEventEnd ::(event) {

                }
            }
        ),


        
        Event.Base.new(
            data: {
                name : 'Encounter:Normal',
                rarity: 2,        
                onEventStart ::(event) {
                    @chance = Number.random(); 
                    @:island = event.island;   
                    @:party = event.party;
                    
                    @:world = import(module:'singleton.world.mt');
                    dialogue.message(
                        text: 'A shadow emerges; the party is caught off-guard!'
                    );                    
                    @enemies = 
                        if (world.time < world.TIME.EVENING) 
                            match(true) {
                                (chance < 0.8): [
                                    island.newAggressor(),
                                    island.newAggressor()                        
                                ],
                                
                                (chance < 0.9):::<= {
                                    @:only = island.newAggressor();                                                
                                    [::] {
                                        forever(do:::{
                                            only.autoLevel();
                                            if (only.level >= island.levelMax)
                                                send();                                    
                                        });
                                    };
                                    only.autoLevel();
                                    return [only];
                                },
                                
                                default: [
                                    island.newAggressor(),
                                    island.newAggressor(),
                                    island.newAggressor()                        
                                ]
                            }
                        else 
                            match(true) {
                                (chance < 0.8): [
                                    island.newAggressor(),
                                    island.newAggressor(),                    
                                    island.newAggressor()                        
                                ],
                                
                                (chance < 0.95):::<= {
                                    @:only = island.newAggressor();                                                
                                    [::] {
                                        forever(do:::{
                                            only.autoLevel();
                                            if (only.level >= island.levelMax)
                                                send();                                    
                                        });
                                    };

                                    return [
                                        island.newAggressor(),
                                        only,
                                        island.newAggressor()                                                                
                                    ];
                                },
                                
                                default: [
                                    island.newAggressor(),
                                    island.newAggressor(),
                                    island.newAggressor(),           
                                    island.newAggressor()                       
                                ]
                            }
                    ;

                    enemies->foreach(do:::(index, e) {
                        e.anonymize();
                    });
                    
                    match(world.battle.start(
                        party,
                        
                        allies: party.members,
                        enemies,
                        landmark: {}
                    ).result) {
                      (Battle.RESULTS.ALLIES_WIN,
                       Battle.RESULTS.NOONE_WIN): ::<= {

                      },
                      
                      (Battle.RESULTS.ENEMIES_WIN): ::<= {
                      }
                    
                    };
                
                    
                    
                
                    return 0; // number of timesteps active
                },
                
                onEventUpdate ::(event) {
                    
                },
                
                onEventEnd ::(event) {

                }
            }
        ),
        
        
        Event.Base.new(
            data: {
                name : 'Encounter:Non-peaceful',
                rarity: 20000000,        
                onEventStart ::(event) {
                    @chance = Number.random(); 
                    @:island = event.island;   
                    @:party = event.party;
                    @:landmark = event.landmark;

                    @enemies = if (landmark == empty) ::<= {
                        @:out = [
                            island.newAggressor(),
                            island.newAggressor(),
                            island.newAggressor()                        
                        ];
                        out->foreach(do:::(i, e) <- e.anonymize());
                        return out;
                    } else 
                        match(event.landmark.base.name) {
                          ('town')::<={
                            
                            // not only do these places have guards, but the guards are 
                            // equipped with standard gear.
                            
                            
                            
                            @:e = [
                                island.newInhabitant(professionHint:'Guard'),
                                island.newInhabitant(professionHint:'Guard'),
                                island.newInhabitant(professionHint:'Guard')                        
                            ];
                            
                            e->foreach(do:::(index, guard) {
                                guard.equip(
                                    item:Item.Base.database.find(
                                        name:'Polearm'
                                    ).new(
                                        from:guard, 
                                        modHint:'Standard',
                                        materialHint: 'Mythril'
                                    ),
                                    slot: Entity.EQUIP_SLOTS.HAND_R,
                                    silent:true, 
                                    inventory:guard.inventory
                                );

                                guard.equip(
                                    item:Item.Base.database.find(
                                        name:'Plate Armor'
                                    ).new(
                                        from:guard, 
                                        modHint:'Standard',
                                        materialHint: 'Mythril'
                                    ),
                                    slot: Entity.EQUIP_SLOTS.ARMOR,
                                    silent:true, 
                                    inventory:guard.inventory
                                );
                                guard.anonymize();
                            });
                            
                            return e;
                          },
                            
                            
                          default: match(true) {
                            (Number.random() > 0.9):
                              [
                                    island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.01)->floor),
                                    island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.01)->floor),
                                    island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.01)->floor)                        
                              ],
                              
                            (Number.random() > 0.8):
                              [
                                    island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.10)->floor)
                              ],
                              
                            default:
                              [
                                    island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.05)->floor),
                                    island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.05)->floor)                                                      
                              ]
                          }
                        }
                    ;


                    @:world = import(module:'singleton.world.mt');
                    
                    match(world.battle.start(
                        party,
                        
                        allies: party.members,
                        enemies,
                        landmark: {}
                    ).result) {
                      (Battle.RESULTS.ALLIES_WIN,
                       Battle.RESULTS.NOONE_WIN): ::<= {
                      },
                      
                      (Battle.RESULTS.ENEMIES_WIN): ::<= {
                      }
                    
                    };
                
                    
                    
                
                    return 0; // number of timesteps active
                },
                
                onEventUpdate ::(event) {
                    
                },
                
                onEventEnd ::(event) {

                }
            }
        )

    ]

);


return Event;
