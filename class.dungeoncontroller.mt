@:class = import(module:'Matte.Core.Class');
@:random = import(module:'singleton.random.mt');
@:distance = import(module:'function.distance.mt');

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

        @:Entity = import(module:'class.entity.mt');
        @:Location = import(module:'class.location.mt');

    
        this.constructor = ::(map => Object, island => Object, landmark => Object) {
            map_ = map;
            island_ = island;
            landmark_ = landmark;
            return this;
        };
    
        @:addEntity ::{
            @area = map_.getRandomArea();;
            @:tileX = area.x + (area.width /2)->floor;
            @:tileY = area.y + (area.height/2)->floor;
            
            // only add an entity when not visible. Makes it 
            // feel more alive and unknown
            //when (map.isTileVisible(x:tileX, y:tileY)) empty;
            
            
            // who knows whos down here. Can be anything and anyone, regardless of 
            // the inhabitants of the island.
            @:ar = map_.getRandomArea();
            @ent = {
                targetX:(ar.x + ar.width/2)->floor, 
                targetY:(ar.y + ar.height/2)->floor, 
                ref:Entity.new(
                    levelHint: random.integer(from:island_.levelMin, to:island_.levelMax)
                )
            };
            ent.ref.anonymize();
            entities->push(value:ent);
            map_.setItem(data:ent, x:tileX, y:tileY, discovered:false, symbol:'*');
        };
    
        this.interface = {
            step::{
                // update movement of entity
                @toRemove = [];
                Object.freezeGC();

                entities->foreach(do:::(i, ent) {
                    @:item = map_.getItem(data:ent);
                    if (map_.getDistanceFromItem(data:ent) < 2) ::<= {
                        @:world = import(module:'singleton.world.mt');
                        @:Battle = import(module:'class.battle.mt');
                        
                        when (world.battle.isActive) ::<= {
                            world.battle.join(enemy:ent.ref);
                        };
                        Object.thawGC();

                        match(world.battle.start(
                            party:island_.world.party,                            
                            allies: island_.world.party.members,
                            enemies: [ent.ref],
                            landmark: this,
                            noLoot: true,
                            onTurn ::{
                                this.step();
                            }
                        ).result) {
                          (Battle.RESULTS.ALLIES_WIN):::<= {
                            toRemove->push(value:ent);
                            @loc = Location.Base.database.find(name:'Body').new(landmark:landmark_, ownedByHint: ent.ref, xHint:item.x, yHint:item.y);
                            map_.setItem(data:loc, x:item.x, y:item.y, symbol: loc.base.symbol, discovered: false, name:loc.name);
                            landmark_.addLocation(location:loc);
                          },
                          
                          (Battle.RESULTS.ENEMIES_WIN): ::<= {
                          }
                        };                     
                        Object.freezeGC();
                    };

                    when (map_.getDistanceFromItem(data:ent) < AGGRESSIVE_DISTANCE) ::<= {
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
                
                toRemove->foreach(do:::(i, ent) {
                    map_.removeItem(data:ent);
                    entities->remove(key:entities->findIndex(value:ent));
                });
                
                // add additional entities out of spawn points (stairs)
                if (entities->keycount < ROOM_MAX_ENTITY) ::<= {
                    addEntity();
                };
            
            }
        };
    }
);
