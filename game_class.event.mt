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
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:random = import(module:'game_singleton.random.mt');
@:Battle = import(module:'game_class.battle.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Item = import(module:'game_class.item.mt');
@:Entity = import(module:'game_class.entity.mt');
@:Scene = import(module:'game_class.scene.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');


@:Event = LoadableClass.new(
    name: 'Wyvern.Event',
    statics : {
        Base  :::<= {
            @db;
            return {
                get ::<- db,
                set ::(value) <- db = value
            }
        }
    },
    
    new ::(parent, base, currentTime, state) {
        @:this = Event.defaultNew();

        @:world = import(module:'game_singleton.world.mt');
        
        @:Island = import(module:'game_class.island.mt');
        @:Landmark = import(module:'game_class.landmark.mt');
        
        @landmark;
        @island;
        
        if (parent->type == Island.type) ::<= {
            landmark = empty;
            island = parent;
        } else if (parent->type == Landmark.type) ::<= {
            landmark = parent;
            island = landmark.island;
        } else 
            error(detail:'Parents of Events can only be either Landmarks or Islands');
        
        @:party = world.party;
        
        this.initialize(party, island, landmark);

        if (state != empty)
            this.load(serialized:state)
        else
            this.defaultLoad(base, currentTime);
        return this;
    },
    
    define:::(this) {
        @:state = State.new(
            items : {
                timeLeft : 0,
                base : empty,
                duration : 0,
                startAt : 0                  
            }
        );
        
    
        @party_;
        @island_;
        @landmark_;


        this.interface = {
            initialize ::(party, island, landmark) {
                island_ = island;
                party_ = party;
                landmark_ = landmark;
            },

            defaultLoad ::(base, currentTime) {
                state.base = base; 
                state.startAt = currentTime;
                state.duration = base.onEventStart(event:this);
                state.timeLeft = state.duration;
                return this;
            },

            save ::{
                return state.save();
            },
            
            load ::(serialized) {
                state.load(parent:this, serialized);
            },
        
            expired : {
                get :: <- state.timeLeft == 0
            },
            
            stepTime :: {
                state.base.onEventUpdate(event:this);
                if (state.timeLeft > 0) state.timeLeft -= 1;
            },
            
            duration : {
                get :: <- state.duration
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
                get :: <- state.base
            }
            
        }
    }

);


@:EVENT_BASE_NAME = 'Wyvern.Event.Base';

Event.Base = class(
    name : EVENT_BASE_NAME,
    inherits : [Database.Item],
    new::(data) {
        @:this = Event.Base.defaultNew();
        this.initialize(data);
        return this;
    },
    statics : {
        database  :::<= {
            @db = Database.new(
                name : EVENT_BASE_NAME,
                attributes : {
                    name : String,
                    rarity: Number,
                    onEventStart : Function,
                    onEventUpdate : Function,
                    onEventEnd : Function
                }            
            );
            return {
                get ::<- db
            }
        }
    },
    define:::(this) {
        Event.Base.database.add(item:this);
    }

);



Event.Base.new(
    data: {
        name : 'Weather:1',
        rarity: 10,        
        onEventStart ::(event) {
            // only one weather event at a time.
            when (event.island.events->any(condition::(value) <- value.base.name->contains(key:'Weather'))) 0;
            @:world = import(module:'game_singleton.world.mt');
            match(world.season) {

                (world.SEASON.WINTER): windowEvent.queueMessage(
                    text: random.pickArrayItem(list:[
                        'It starts to snow softly.',
                        'A thick snow obscures your vision.',
                        'A quiet snowfall begins.',
                    ])
                ),

                default: windowEvent.queueMessage(
                    text: random.pickArrayItem(list:[
                        'It starts to rain gently.',
                        'It starts to storm intensely.',
                        'It starts to rain.',
                        'It starts to rain as a gentle fog rolls in.'
                    ])
                )

                
                
            }
            return 14+(Number.random()*20)->floor; // number of timesteps active
        },
        
        onEventUpdate ::(event) {
            
        },
        
        onEventEnd ::(event) {
            when(event.duration == 0) empty;
            windowEvent.queueMessage(
                text: random.pickArrayItem(list:[
                    'The weather subsides.',
                ])
            );                
            
        }
    }
)

Event.Base.new(
    data: {
        name : 'Encounter:GateBoss',
        rarity: 10000000,        
        onEventStart ::(event) {
            @:Species = import(module:'game_class.species.mt');
            @:Profession = import(module:'game_class.profession.mt');

            windowEvent.queueMessage(speaker: '???', text:'The gates of wyverns are only for use by the chosen.');
            windowEvent.queueMessage(speaker: '???', text:'You shall be judged.');
            
            @chance = Number.random(); 
            @:island = event.island;   
            @:party = event.party;

            @lackey0 = Entity.new(
                island:         event.landmark.island,
                speciesHint:    'Wyvern',
                levelHint:      event.island.levelMin,
                professionHint: 'Disciple'
            );
            @lackey1 = Entity.new(
                island:         event.landmark.island,
                speciesHint:    'Wyvern',
                levelHint:      event.island.levelMin,
                professionHint: 'Disciple'
            );
            @boss = Entity.new(
                island:         event.landmark.island,
                speciesHint:    'Wyvern',
                levelHint:      event.island.levelMax,
                professionHint: 'Keeper'
            );



            @enemies = [
                lackey0,
                boss,
                lackey1               
            ];
            
            
            {:::} {
                forever ::{
                    boss.autoLevel();
                    if (boss.level >= island.levelMax)
                        send();                                    
                }
            }


            foreach(enemies)::(index, e) {
                e.anonymize();
            }
            @:world = import(module:'game_singleton.world.mt');
            
            
            @:battleStart = ::{
                world.battle.start(
                    party,
                    
                    allies: party.members,
                    enemies,
                    
                    landmark: {},
                    onStart :: {

                    },
                    
                    onEnd ::(result){
                        match(result) {
                          (Battle.RESULTS.ALLIES_WIN): ::<= {
                            canvas.clear();
                            windowEvent.queueMessage(speaker: '???', text:'You are worthy of this key\'s use.');                              
                            windowEvent.queueMessage(text:'The world around you warps until you are brought to your feet on a new land.');                              
                            windowEvent.queueMessage(text:'Something falls to your feet.');                              
                            
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
                            
                            windowEvent.queueMessage(text: message);
                            when(world.party.inventory.isFull) ::<= {
                                windowEvent.queueMessage(text: '...but the party\'s inventory was full.');
                                send();
                            }
                            
                            party.inventory.add(item);


                          },
                          
                          (Battle.RESULTS.ENEMIES_WIN): ::<= {
                            windowEvent.jumpToTag(name:'MainMenu');
                          },
                          
                          
                          (Battle.RESULTS.NOONE_WIN): ::<= {
                            windowEvent.queueMessage(speaker: '???', text:'Judgement shall be brought forth.');                              
                            battleStart();
                          }         
                        }                      
                    }
                );
            }
            
            battleStart();
            
            return 0;              
            
        },
        
        onEventUpdate ::(event) {
            
        },
        
        onEventEnd ::(event) {                    
        }
    }
)

Event.Base.new(
    data: {
        name : 'Encounter:TreasureBoss',
        rarity: 10000000,        
        onEventStart ::(event) {
            
            @chance = Number.random(); 
            @:island = event.island;   
            @:party = event.party;
            @enemies = [];
            
            
            for(0, 3)::(i) {
                @:enemy = island.newAggressor();
                enemy.inventory.clear();
                enemy.anonymize();
                enemies->push(value:enemy);
            }
            
            @:boss = enemies[1];

            windowEvent.queueMessage(
                speaker: '???',
                text: random.pickArrayItem(list:[
                    'Well, well, well. Look who else is after the key. It\' ours!',
                    'Get out of here, the key is ours!',
                    'Wait, no! The key is ours! Get out of here!',
                    'We will fight for that key to the death!',
                    'The key is ours! We are the real Chosen!'
                ])
            );

            @:world = import(module:'game_singleton.world.mt');
            

            @:battleStart = ::{
                world.battle.start(
                    party,

                    allies: party.members,
                    enemies,
                    exp:true,
                    landmark: {},
                    onStart :: {
                    },
                    onEnd ::(result) {
                        match(result) {
                          (Battle.RESULTS.ALLIES_WIN): ::<= {
                            windowEvent.queueMessage(text: 'It looks like they dropped some items during the fight...');
                            @:item = Item.new(base:Item.Base.database.find(name:'Skill Crystal'), from:boss);
                            @message = 'The party found a Skill Crystal!';
                            party.inventory.add(item);
                            windowEvent.queueMessage(text: message);
                          },
                          
                          (Battle.RESULTS.ENEMIES_WIN): ::<= {
                            windowEvent.jumpToTag(name:'MainMenu');
                          },
                          
                          
                          (Battle.RESULTS.NOONE_WIN): ::<= {
                            windowEvent.queueMessage(text:boss.name + ' corners you!');                              
                            battleStart();
                          }
                        }
                       }
                  );
            }
            battleStart();
            return 0;  
        },
        
        onEventUpdate ::(event) {
            
        },
        
        onEventEnd ::(event) {                    
        }
    }
)        

Event.Base.new(
    data: {
        name : 'Chest:Normal',
        rarity: 1, //5        
        onEventStart ::(event) {
            @:openChest = ::(opener){

                windowEvent.queueMessage(text:'The party opens the chest...'); 
                @:Damage = import(module:'game_class.damage.mt');
                
                when(Number.random() < 0.5) ::<= {
                    windowEvent.queueMessage(text:'A trap is triggered, and a volley of arrows springs form the chest!'); 
                    if (Number.random() < 0.5) ::<= {
                        windowEvent.queueMessage(text:opener.name + ' narrowly dodges the trap.');                         
                    } else ::<= {
                        opener.damage(
                            from: opener,
                            damage: Damage.new(
                                amount:opener.stats.HP * (0.7),
                                damageType : Damage.TYPE.PHYS,
                                damageClass: Damage.CLASS.HP
                            ),
                            dodgeable: false
                        );
                    }
                } 
                
                
                @:itemCount = (2+Number.random()*3)->floor;
                
                windowEvent.queueMessage(text:'The chest contained ' + itemCount + ' items!'); 
                
            
                when(itemCount > party.inventory.slotsLeft) ::<= {
                    windowEvent.queueMessage(text: '...but the party\'s inventory was too full.');
                }                
                for(0, itemCount)::(index) {
                    @:item = Item.new(
                        base:Item.Base.database.getRandomFiltered(
                            filter:::(value) <- value.isUnique == false && value.canHaveEnchants && value.tier <= event.landmark.island.tier
                        ),
                        rngEnchantHint:true, from:opener
                    );
                    @message = 'The party found ' + correctA(word:item.name);
                    windowEvent.queueMessage(text: message);


                    party.inventory.add(item);
                    
                }

            }


            
            @:party = event.party;
            windowEvent.queueMessage(text:'What\'s this?');
            windowEvent.queueMessage(text:'The party trips over a hidden chest!');
            windowEvent.queueAskBoolean(
                prompt: 'Open the chest?',
                onChoice ::(which) {
                    when(which == false) empty;
                                        
                    windowEvent.queueChoices(
                        prompt: 'Who opens up the chest?',
                        choices : [...party.members]->map(to:::(value) <- value.name),
                        canCancel: false,
                        onChoice::(choice) {
                            openChest(opener:party.members[choice-1]);
                        }
                    );
                }
            );
            return 0;

        },
        
        onEventUpdate ::(event) {
            
        },
        
        onEventEnd ::(event) {

        }
    }
)


Event.Base.new(
    data: {
        name : 'BBQ',
        rarity: 1, //5        
        onEventStart ::(event) {
            @:party = event.party;
            windowEvent.queueMessage(speaker: '???', text:'"Hey!"');
            windowEvent.queueMessage(text:'Someone calls out to the party.');
            windowEvent.queueMessage(text:'They are by a fire enjoying a meal.');
            windowEvent.queueMessage(speaker: '???', text:'"Care to join me? There\'s plenty to share!"');

            windowEvent.queueAskBoolean(
                prompt:'Sit by the fire?',
                onChoice::(which) {
                    when(which == false)
                        windowEvent.queueMessage(speaker:'???', text:'"Ah, I understand. Stay safe out there!"');

                    windowEvent.queueMessage(text:'The party is given some food.');

                    @StatSet = import(module:'game_class.statset.mt');
                    if (Number.random() < 0.8) ::<= {
                        windowEvent.queueMessage(text:'The food is delicious.');
                        foreach(event.party.members)::(index, member) {
                            @oldStats = StatSet.new();
                            oldStats.load(serialized:member.stats.save());
                            member.stats.add(stats:StatSet.new(HP:(oldStats.HP*0.1)->ceil, AP:(oldStats.AP*0.1)->ceil));
                            oldStats.printDiff(other:member.stats, prompt:member.name + ': Mmmm...');

                            member.heal(amount:member.stats.HP * 0.1);
                            member.healAP(amount:member.stats.AP * 0.1);
                        }
                        
                    } else ::<= {
                        windowEvent.queueMessage(text:'The food tastes terrible. The party feels ill.');
                        @:Damage = import(module:'game_class.damage.mt');
                        foreach(event.party.members)::(index, member) {
                            @oldStats = StatSet.new();
                            oldStats.load(serialized:member.stats.save());
                            member.stats.add(stats:StatSet.new(HP:-(oldStats.HP*0.1)->ceil, AP:-(oldStats.AP*0.1)->ceil));
                            oldStats.printDiff(other:member.stats, prompt:member.name + ': Ugh...');


                            member.damage(
                                from: member,
                                damage: Damage.new(
                                    amount:member.stats.AP * (0.1),
                                    damageType : Damage.TYPE.PHYS,
                                    damageClass: Damage.CLASS.AP
                                ),
                                dodgeable:false
                            );
                        }
                    
                    }

                    @:nicePerson = event.island.newInhabitant();
                    nicePerson.interactPerson(
                        party:event.party,
                        onDone ::{
                            if (!party.isMember(entity:nicePerson)) ::<= {
                                windowEvent.queueMessage(text:'You thank the person and continue on your way.');  
                            }
                        }
                    );

                }
            );
            return 0; // number of timesteps active
        },
        
        onEventUpdate ::(event) {
            
        },
        
        onEventEnd ::(event) {

        }
    }
)

Event.Base.new(
    data: {
        name : 'Camp out',
        rarity: 1, //5        
        onEventStart ::(event) {
            @:party = event.party;
            
            if (party.members->keycount == 1) ::<= {
                windowEvent.queueMessage(
                    speaker:party.members[0].name,
                    text:'This looks like a good place to rest...'
                );
            } else ::<= {
                windowEvent.queueMessage(
                    speaker:party.members[1].name,
                    text:'"Can we take a break for a bit?"'
                );
            }

            windowEvent.queueAskBoolean(
                prompt:'Rest?',
                onChoice::(which) {
                    when(which == false)
                        windowEvent.queueMessage(speaker:'???', text:'The party continues on their way.');


                    windowEvent.queueMessage(text:
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
                    @StatSet = import(module:'game_class.statset.mt');
                    
                    windowEvent.queueNoDisplay(
                        onLeave::{
                            @:world = import(module:'game_singleton.world.mt');
                            for(0, 5*3)::(i) {
                                world.stepTime();
                            }
            
                            foreach(event.party.members)::(index, member) {
                                @oldStats = StatSet.new();
                                oldStats.load(serialized:member.stats.save());
                                member.stats.add(stats:StatSet.new(HP:(oldStats.HP*0.1)->ceil, AP:(oldStats.AP*0.1)->ceil));
                                oldStats.printDiff(other:member.stats, prompt:member.name + ': I feel refreshed!');


                                member.heal(amount:member.stats.HP * 0.3);
                                member.healAP(amount:member.stats.AP * 0.3);
                            }
                        },
                        
                        onEnter::{}
                    );


                }
            );


            return 0;
        },
        
        onEventUpdate ::(event) {
            
        },
        
        onEventEnd ::(event) {

        }
    }
)



Event.Base.new(
    data: {
        name : 'Encounter:Normal',
        rarity: 2,        
        onEventStart ::(event) {
            @chance = Number.random(); 
            @:island = event.island;   
            @:party = event.party;
            
            @:world = import(module:'game_singleton.world.mt');
            windowEvent.queueMessage(
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
                            {:::} {
                                forever ::{
                                    only.autoLevel();
                                    if (only.level >= island.levelMax)
                                        send();                                    
                                }
                            }
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
                            {:::} {
                                forever ::{
                                    only.autoLevel();
                                    if (only.level >= island.levelMax)
                                        send();                                    
                                }
                            }

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

            foreach(enemies)::(index, e) {
                e.anonymize();
            }
            
            world.battle.start(
                party,
                
                allies: party.members,
                enemies,
                landmark: {},
                loot : true,
                onEnd::(result){
                
                }
            );
        
            
            
        
            return 0; // number of timesteps active
        },
        
        onEventUpdate ::(event) {
            
        },
        
        onEventEnd ::(event) {

        }
    }
)


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
                foreach(out) ::(i, e) <- e.anonymize();
                return out;
            } else (if (event.landmark.base.guarded) ::<= {
                    
                    // not only do these places have guards, but the guards are 
                    // equipped with standard gear.
                    
                    
                    
                    @:e = [
                        island.newInhabitant(professionHint:'Guard'),
                        island.newInhabitant(professionHint:'Guard'),
                        island.newInhabitant(professionHint:'Guard')                        
                    ];
                    
                    foreach(e)::(index, guard) {
                        guard.equip(
                            item:Item.new(
                                base:Item.Base.database.find(
                                    name:'Halberd'
                                ),
                                from:guard, 
                                qualityHint:'Standard',
                                materialHint: 'Mythril',
                                rngEnchantHint: true
                            ),
                            slot: Entity.EQUIP_SLOTS.HAND_R,
                            silent:true, 
                            inventory:guard.inventory
                        );

                        guard.equip(
                            item:Item.new(
                                base: Item.Base.database.find(
                                    name:'Plate Armor'
                                ),
                                from:guard, 
                                qualityHint:'Standard',
                                materialHint: 'Mythril',
                                rngEnchantHint: true
                            ),
                            slot: Entity.EQUIP_SLOTS.ARMOR,
                            silent:true, 
                            inventory:guard.inventory
                        );
                        guard.anonymize();
                    }
                    
                    windowEvent.queueMessage(speaker:e.name, text:'There they are!');
                    
                    
                    return e;
                  } else empty);/*,
                    
                    
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
                  }*/
                
            when(enemies == empty) 0;


            @:world = import(module:'game_singleton.world.mt');
            
            world.battle.start(
                party,
                
                allies: party.members,
                enemies,
                landmark: {},
                loot : true,
                onEnd::(result){
                
                    if (result == Battle.RESULTS.ENEMIES_WIN)::<= {
                        breakpoint();
                        windowEvent.jumpToTag(name:'MainMenu', clearResolve:true);
                    }

                }
            );
        
            
            
        
            return 0; // number of timesteps active
        },
        
        onEventUpdate ::(event) {
            
        },
        
        onEventEnd ::(event) {

        }
    }
)



return Event;
