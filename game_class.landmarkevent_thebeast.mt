@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');

@:ROOM_MAX_ENTITY = 6;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;


@:DungeonEncounters = class(
    name: 'Wyvern.LandmarkEvent.TheBeast',

    define:::(this) {
        @:entities = [];
        @map_;
        @island_;
        @landmark_;
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
                ref:[landmark_.island.newInhabitant()]
            }
            
            

            ::<={
                @:Item = import(module:'game_class.item.mt');

                if (island_.tier > 0)
                    ent.ref->push(value:landmark_.island.newInhabitant());

                if (island_.tier > 2)
                    ent.ref->push(value:landmark_.island.newInhabitant());



                foreach(ent.ref) ::(index, ref) {

                    ref.inventory.clear();
                    @:itembase = Item.Base.database.getRandomWeightedFiltered(
                        filter:::(value) <- value.isUnique == false && value.tier <= island_.tier                    
                    );
                    if (itembase.name != 'None') ::<={
                        @:itemInstance = Item.new(base:itembase, from:ref, rngEnchantHint:true);
                        ref.inventory.add(item:itemInstance);
                    }
                    ref.anonymize();
                }
            }
            entities->push(value:ent);
            map_.setItem(data:ent, x:tileX, y:tileY, discovered:true, symbol:'*');
            if (entities->keycount == 1)
                windowEvent.queueMessage(
                    text:random.pickArrayItem(list:[
                        'Are those foosteps? Be careful.',
                        'Hmm. Footsteps nearby.',
                        'What? Footsteps?'
                    ])
                );
        }
        

    
        this.interface = {
            initialize::(landmark) {
                map_ = landmark.map;
                island_ = landmark.island;
                landmark_ = landmark;
                return this;
            },
            
            step::{
                // update movement of entity

                foreach(entities)::(i, ent) {
                    @:item = map_.getItem(data:ent);
                    when (map_.getDistanceFromItem(data:ent) < 2) ::<= {
                        @:world = import(module:'game_singleton.world.mt');
                        @:Battle = import(module:'game_class.battle.mt');
                        
                        when (world.battle.isActive) ::<= {
                            foreach(ent.ref) ::(i, ref) <-
                                world.battle.join(enemy:ref);
                        }

                        map_.removeItem(data:ent);
                        entities->remove(key:entities->findIndex(value:ent));


                        world.battle.start(
                            party:island_.world.party,                            
                            allies: island_.world.party.members,
                            enemies: [...ent.ref],
                            landmark: landmark_,
                            loot: true,
                            onAct ::{
                                this.step();
                            },
                            
                            onEnd::(result) {
                                match(result) {
                                  (Battle.RESULTS.ALLIES_WIN):::<= {
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
                    }

                    when (map_.getDistanceFromItem(data:ent) < AGGRESSIVE_DISTANCE + landmark_.floor/2) ::<= {
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
                
                
                // add additional entities out of spawn points (stairs)
                if ((entities->keycount < (if (landmark_.floor == 0) 0 else (1+(landmark_.floor/4)->ceil))) && landmark_.base.peaceful == false && Number.random() < 0.1 / (encountersOnFloor*(10 / (island_.tier+1))+1)) ::<= {
                    addEntity();
                    encountersOnFloor += 1;
                }
            
            }
        }
    }
);
return DungeonEncounters;
