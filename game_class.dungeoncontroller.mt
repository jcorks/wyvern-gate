@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');

@:ROOM_MAX_ENTITY = 6;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;


@:DungeonController = class(
    name: 'Wyvern.DungeonController',
    new::(map => Object, island => Object, landmark => Object) {
        @:this = DungeonController.defaultNew();
        this.initialize(map, island, landmark);
        return this;
    },
    define:::(this) {
        @:entities = [];
        @map_;
        @island_;
        @landmark_;
        @floorHint = 0;;
        @encountersOnFloor = 0;

        @:Entity = import(module:'game_class.entity.mt');
        @:Location = import(module:'game_class.location.mt');

    
    
        @:addEntity ::{
            @:windowEvent = import(module:'game_singleton.windowevent.mt');

            @ar = map_.getRandomArea();;
            @:tileX = ar.x + (ar.width /2)->floor;
            @:tileY = ar.y + (ar.height/2)->floor;
            
            // only add an entity when not visible. Makes it 
            // feel more alive and unknown
            when (map_.isLocationVisible(x:tileX, y:tileY)) empty;
            
            
            // who knows whos down here. Can be anything and anyone, regardless of 
            // the inhabitants of the island.
            @ent = {
                targetX:tileX, 
                targetY:tileY, 
                ref:landmark_.island.newInhabitant()
            }

            ::<={
                @story = import(module:'game_singleton.story.mt');
                @:Item = import(module:'game_class.item.mt');
                ent.ref.inventory.clear();
                @:itembase = Item.Base.database.getRandomWeightedFiltered(
                    filter:::(value) <- value.isUnique == false && value.tier <= story.tier
                    
                );
                if (itembase.name != 'None') ::<={
                    @:itemInstance = Item.new(base:itembase, from:ent.ref, rngEnchantHint:true);
                    ent.ref.inventory.add(item:itemInstance);
                }
            }
            ent.ref.anonymize();
            entities->push(value:ent);
            map_.setItem(data:ent, x:tileX, y:tileY, discovered:true, symbol:'*');
            if (entities->keycount == 1)
                windowEvent.queueMessage(
                    text:random.pickArrayItem(list:[
                        'Are those foosteps? Be careful.',
                        'Hmm. Footsteps nearby.',
                        'It\'s not safe here.',
                        'What? Footsteps?'
                    ])
                );
        }
        

    
        this.interface = {
            floorHint : {
                set ::(value) {
                    floorHint = value;
                    encountersOnFloor = 0;
                }
            },
            
            initialize::(map, island, landmark) {
                map_ = map;
                island_ = island;
                landmark_ = landmark;
                return this;
            },
            
            step::{
                // update movement of entity
                Object.freezeGC();

                foreach(entities)::(i, ent) {
                    @:item = map_.getItem(data:ent);
                    if (map_.getDistanceFromItem(data:ent) < 2) ::<= {
                        @:world = import(module:'game_singleton.world.mt');
                        @:Battle = import(module:'game_class.battle.mt');
                        
                        when (world.battle.isActive) ::<= {
                            world.battle.join(enemy:ent.ref);
                        }
                        Object.thawGC();

                        world.battle.start(
                            party:island_.world.party,                            
                            allies: island_.world.party.members,
                            enemies: [ent.ref],
                            landmark: this,
                            noLoot: true,
                            onAct ::{
                                this.step();
                            },
                            
                            onEnd::(result) {
                                match(result) {
                                  (Battle.RESULTS.ALLIES_WIN):::<= {
                                    map_.removeItem(data:ent);
                                    entities->remove(key:entities->findIndex(value:ent));

                                    landmark_.addLocation(name:'Body', x:item.x, y:item.y, ownedByHint: ent.ref);
                                  },
                                  
                                  (Battle.RESULTS.ENEMIES_WIN): ::<= {
                                    @:windowEvent = import(module:'game_singleton.windowevent.mt');
                                    windowEvent.queueMessage(text:'Perhaps these Chosen were not ready...',
                                        renderable : {
                                            render :: {
                                                @:canvas = import(module:'game_singleton.canvas.mt');
                                                canvas.blackout();
                                                canvas.commit();
                                            }
                                        }
                                    );
                                    
                                    windowEvent.queueNoDisplay(
                                        onEnter :: {                                        
                                            windowEvent.jumpToTag(name:'MainMenu');                                        
                                        }
                                    );
                                  }
                                }
                            }
                        ); 
                        Object.freezeGC();
                    }

                    when (map_.getDistanceFromItem(data:ent) < AGGRESSIVE_DISTANCE + floorHint/2) ::<= {
                        ent.pathTo = empty;                    
                        map_.moveTowardPointer(data:ent);                    
                    }

                    if (ent.pathTo == empty || ent.pathTo->keycount == 0) ::<= {
                        @:ar = map_.getRandomArea();
                        ent.pathTo = map_.getPathTo(
                            data: ent,
                            x:(ar.x + ar.width/2)->floor,
                            y:(ar.y + ar.height/2)->floor                         
                        )
                    }
                    if (ent.pathTo != empty && ent.pathTo->keycount > 0) ::<= {
                        @:next = ent.pathTo->pop;
                        map_.moveItem(data:ent, x:next.x, y:next.y);
                    }
                }
                Object.thawGC();
                
                
                // add additional entities out of spawn points (stairs)
                if ((entities->keycount < (if (floorHint == 0) 0 else (1+(floorHint/4)->ceil))) && landmark_.base.peaceful == false && Number.random() < 0.1 / (encountersOnFloor*10+1)) ::<= {
                    addEntity();
                    encountersOnFloor += 1;
                }
            
            }
        }
    }
);
return DungeonController;
