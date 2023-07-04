@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');

@:ROOM_MAX_ENTITY = 6;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;


return class(
    name: 'Wyvern.DungeonController',
    define:::(this) {
        @:entities = [];
        @map_;
        @island_;
        @landmark_;
        @floorHint = 0;;

        @:Entity = import(module:'game_class.entity.mt');
        @:Location = import(module:'game_class.location.mt');

    
        this.constructor = ::(map => Object, island => Object, landmark => Object) {
            map_ = map;
            island_ = island;
            landmark_ = landmark;
            return this;
        };
    
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
            };

            ::<={
                @story = import(module:'game_singleton.story.mt');
                @:Item = import(module:'game_class.item.mt');
                [0, 1+(Number.random()*3)->floor]->for(do:::(i) {
                    @:item = Item.Base.database.getRandomWeightedFiltered(
                        filter:::(value) <- value.isUnique == false && value.tier <= story.tier
                        
                    );
                    if (item.name != 'None') ::<={
                        @:itemInstance = item.new(from:ent.ref);
                        ent.ref.inventory.add(item:itemInstance);
                    };
                });
            };
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
        };
    
        this.interface = {
            floorHint : {
                set ::(value) <- floorHint = value
            },
            step::{
                // update movement of entity
                Object.freezeGC();

                entities->foreach(do:::(i, ent) {
                    @:item = map_.getItem(data:ent);
                    if (map_.getDistanceFromItem(data:ent) < 2) ::<= {
                        @:world = import(module:'game_singleton.world.mt');
                        @:Battle = import(module:'game_class.battle.mt');
                        
                        when (world.battle.isActive) ::<= {
                            world.battle.join(enemy:ent.ref);
                        };
                        Object.thawGC();

                        world.battle.start(
                            party:island_.world.party,                            
                            allies: island_.world.party.members,
                            enemies: [ent.ref],
                            landmark: this,
                            noLoot: true,
                            onTurn ::{
                                this.step();
                            },
                            
                            onEnd::(result) {
                                breakpoint();
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
                                                @:canvas = import(module:'game_singleton.canvas');
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
                                };
                            }
                        ); 
                        Object.freezeGC();
                    };

                    when (map_.getDistanceFromItem(data:ent) < AGGRESSIVE_DISTANCE + floorHint/2) ::<= {
                        map_.moveTowardPointer(data:ent);                    
                    };

                    
                    map_.moveTowardPoint(data:ent, x:ent.targetX, y:ent.targetY);

                    
                    if (distance(x0:item.x, y0:item.y, x1:ent.targetX, y1:ent.targetY) < REACHED_DISTANCE) ::<= {
                        @:ar = map_.getRandomArea();
                        ent.targetX = (ar.x + ar.width/2)->floor;
                        ent.targetY = (ar.y + ar.height/2)->floor; 
                    };
                });
                Object.thawGC();
                
                
                // add additional entities out of spawn points (stairs)
                if (entities->keycount < (floorHint/3)->ceil && Number.random() < 0.1) ::<= {
                    addEntity();
                };
            
            }
        };
    }
);
