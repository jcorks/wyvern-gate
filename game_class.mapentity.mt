
@:Database = import(module:'game_class.database.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');
@:class = import(module:'Matte.Core.Class');
@:Item = import(module:'game_class.item.mt');
@:distance = import(module:'game_function.distance.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:random = import(module:'game_singleton.random.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Landmark = import(module:'game_class.landmark.mt');
@:world = import(module:'game_singleton.world.mt');
@:Battle = import(module:'game_class.battle.mt');
@:Entity = import(module:'game_class.entity.mt');

/*
    Some tasks to implement:
        "fight" -> when with party, fights normal, when with npc v npc, does damage to both every step.
        "huntParty" -> step toward party 
        "findExit" -> goes to exit 
        "disappear" -> remove map entity 

*/


@:MapEntity = LoadableClass.new(
    name : 'Wyvern.MapEntity',
    statics : {
        Controller :::<= {
            @a;
            return {
                get ::<- a,
                set::(value) <- a = value
            }
        },
        
        Task :::<= {
            @a;
            return {
                get ::<- a,
                set::(value) <- a = value
            }
        }        
    },
    new ::(parent, state, x, y, symbol, entities, tag) {
        parent => MapEntity.Controller.type
        @:this = MapEntity.defaultNew();

        this.initialize(controller:parent);

        if (state != empty)
            this.load(serialized:state)
        else 
            this.defaultLoad(x, y, symbol, entities, tag);
            
        return this;
    },
    define:::(this) {
    

        @controller_;
        @isRemoved = false;
        @:state = State.new(
            items : {
                tag : empty,
                entities : empty,
                targetX : empty,
                targetY : empty,
                path : empty,
                onArrive : empty, // MapEntity.Task to do when arriving 
                onCancel : empty, // MapEntity.Task to do when cancelling.
                onStepSet: empty, // MapEntity.Task array to do each step
                steps : 0,
                speed : 1
            }
        )
        
        
        this.interface = {
            initialize ::(controller) {
                controller_ = controller;
            },
            
            defaultLoad::(x, y, symbol, entities => Object, tag) {
                state.entities = entities;
                state.tag = tag;
                state.onStepSet = [];
                controller_.map.setItem(data:this, x, y, discovered:true, symbol);            
            },
            
            steps : {
                get ::<- state.steps
            },
            
            tag : {
                get ::<- state.tag
            },
        
            step :: {
                when(isRemoved) empty;
                state.steps += 1;
                foreach(state.onStepSet) ::(k, task) {
                    task.do(mapEntity:this);
                }
            
            
                @path = state.path;
                when(path == empty) empty;
                when(state.steps % state.speed != 0) empty;
                when(isRemoved) empty;
                when (
                    distance(x0:state.targetX,
                             y0:state.targetY,
                             
                             x1:controller_.map.getItem(data:this).x,
                             y1:controller_.map.getItem(data:this).y
                ) < 2) ::<={
                    state.onCancel = empty;
                    if (state.onArrive) ::<= {
                        @:task = MapEntity.Task.new(
                            base:MapEntity.Task.Base.database.find(name:state.onArrive)
                        );
                        task.do(mapEntity:this);
                        
                    }
                    state.path = empty;
                }

                when(isRemoved) empty;


                @:next = path[path->size-1];
                path->setSize(size:path->size-1);
                when (path->size == 0)
                    state.path = empty;
                
                // looks like the map was updated and we bumped 
                // into a wall! get a new route.
                if (controller_.map.isWalled(x:next.x, y:next.y))
                    state.path = controller_.map.getPathTo(
                        data:this,
                        x:state.targetX,
                        y:state.targetY,
                        useBFS:true
                    );
                
                controller_.map.moveItem(data:this, x:next.x, y:next.y);
                
            },
            
            addUpkeepTask ::(name) {
                state.onStepSet->push(
                    value: MapEntity.Task.new(
                        base:MapEntity.Task.Base.database.find(name)
                    )
                );
            },
            
            removeUpkeepTask ::(name) {
                @:index = state.onStepSet->findIndex(query::(value) <- value.base.name == name);
                when(index == -1) empty;
                state.onStepSet->remove(key:index);
            },
            
            controller : {
                get ::<- controller_
            },
            
            // for non-battle fighting between NPCs.
            // each member does a blow to a random other member who is 
            // not incapacitated. Simplified attacks.
            squabble ::(other => MapEntity.type) {

                windowEvent.autoSkip = true;
                
                    @:allies = state.entities->filter(by::(value) <- !value.isIncapacitated());
                    @:enemies = other.entities->filter(by::(value) <- !value.isIncapacitated());
                    if (enemies->size > 0)  ::<= {
                        foreach(allies) ::(i, ally) {
                            @target = random.pickArrayItem(list:enemies);
                            ally.attack(
                                target,
                                amount:ally.stats.ATK * (0.5),
                                damageType : Damage.TYPE.PHYS,
                                damageClass: Damage.CLASS.HP
                            );       
                        }
                    }
                    
                    @defeated = true;
                    foreach(enemies) ::(i, enemy) {
                        if (!enemy.isIncapacitated())
                            defeated = false;
                    }

                windowEvent.autoSkip = false;
                
                
                if (defeated) ::<= {
                    @:otherItem = controller_.map.getItem(data:other);
                    other.remove();
                    if (distance(   
                        x0: controller_.map.pointerX,
                        y0: controller_.map.pointerY,
                        x1: otherItem.x,
                        y1: otherItem.y
                    ) < 15)
                        windowEvent.queueMessage(
                            text: random.pickArrayItem(list : [
                                'Was that a scream...?',
                                'Something definitely happened to someone nearby...',
                                '...That did not sound good.',
                                'A battle of some kind just ended.'
                            ])
                        );
                }
            },
            
            remove :: {
                when(isRemoved) empty;
                isRemoved = true;
                controller_.remove(entity:this);
            },
            
            entities : {
                get ::<- state.entities
            },

            // sets a new place to go to
            newPathTo ::(x => Number, y => Number, onArrive, onCancel, speed) {
                when(isRemoved) empty;
                this.clearPath();
                state.speed = if (speed != empty) (1/speed)->round else 1;
                state.targetX = x;
                state.targetY = y;
                state.onArrive = onArrive;
                state.onCancel = onCancel;
                state.path = controller_.map.getPathTo(
                    data:this,
                    x,
                    y,
                    useBFS:true
                );
            },
            
            clearPath ::{
                when(isRemoved) empty;
                if (state.onCancel != empty) ::<= {
                    @:task = MapEntity.Task.new(
                        base:MapEntity.Task.Base.database.find(name:state.onArrive)
                    );
                    task.do(mapEntity:this);
                }
                state.path = empty;
                state.onCancel = empty;
                state.onArrive = empty;            
            },
            
            hasPath : {
                get ::<- state.path != empty
            },
            
            save :: {
                return state.save();
            },
            
            load::(serialized) {
                state.load(parent:this, serialized);
            }            
        }
    }
)



MapEntity.Controller = LoadableClass.new(
    name : 'Wyvern.MapEntity.Controller',
    new ::(parent => Landmark.type, state) {
        @:this = MapEntity.Controller.defaultNew();

        this.initialize(landmark: parent);

        if (state != empty)
            this.load(serialized:state)
        else 
            this.defaultLoad();
            
        return this;
    },
    define:::(this) {
    
        @map_;
        @landmark_;
        
        @:state = State.new(
            items : {
                // it used to be mapEntities, but the map will own all instances, 
                // and we cant have reference copies anywhere.
            }
        );
        
        
        this.interface = {
            initialize ::(landmark) {
                landmark_ = landmark;
                map_ = landmark.map;
            },
            
            defaultLoad ::{},
            
            map : {
                get ::<- map_
            },
            
            landmark : {
                get ::<- landmark_
            },
            
            add::(x, y, symbol, entities => Object, tag) {
                return MapEntity.new(parent:this, x, y, symbol, entities, tag); // automatically gets added to mapEntities
            },
            
            mapEntities : {
                get ::{
                    @:out = map_.getAllItemData()->filter(by::(value) <- value->type == MapEntity.type);
                    return out;
                }
            },
            
            remove::(entity => MapEntity.type) {
                map_.removeItem(data:entity);
            },
            
            step ::{
                foreach(this.mapEntities) ::(k, ent) {
                    ent.step();
                }
            },
            
            save :: {
                return state.save();
            },
            
            load::(serialized) {
                state.load(parent:this, serialized);
            }
        }
    }
);


MapEntity.Task = LoadableClass.new(
    name : "Wyvern.MapEntity.Task",
    statics : {
        Base :::<= {
            @a;
            return {
                get ::<- a,
                set ::(value) <- a = value
            }
        }
    },
    
    new ::(parent, state, base) {
        @:this = MapEntity.Task.defaultNew();
    
        if (state != empty) 
            this.load(serialized:state)
        else 
            this.defaultLoad(base);
        return this;
    },
    
    define::(this) {
        @:state = State.new(
            items : {
                data : empty,
                base : empty,
            }
        );
    
    
        this.interface = {
            defaultLoad ::(base) {
                state.base = base;
                state.data = base.startup();
            },
            
            load ::(serialized) {
                state.load(parent:this, serialized);
            },
            
            save ::{
                return state.save();
            },
            
            do ::(mapEntity => MapEntity.type) {
                state.base.do(
                    mapEntity,
                    data:state.data
                )
            }
        }
    }
);

MapEntity.Task.Base = Database.newBase(
    name : 'Wyvern.MapEntity.Task.Base',
    attributes : {
        name : String,
        startup : Function,
        do : Function
    }
);




// roams to random areas with the following triggers:
// if within interest distance, stairs down locations will 
MapEntity.Task.Base.new(
    data : {
        name: 'dungeonencounters-roam',
        startup ::{
            
        },
        
        do ::(data, mapEntity) {
            @:map = mapEntity.controller.map;

        
            // go to a random area.
            if (!mapEntity.hasPath) ::<= {
                @:ar = map.getRandomArea();
                mapEntity.newPathTo(
                    x:(ar.x + ar.width/2)->floor,
                    y:(ar.y + ar.height/2)->floor                         
                );
            }
        }
    }
);


MapEntity.Task.Base.new(
    data : {
        name: 'thebeast-roam',
        startup ::{
            
        },
        
        do ::(data, mapEntity) {
            @:map = mapEntity.controller.map;

        
            // go to a random area.
            if (!mapEntity.hasPath) ::<= {
                @:ar = map.getRandomArea();
                mapEntity.newPathTo(
                    x:(ar.x + ar.width/2)->floor,
                    y:(ar.y + ar.height/2)->floor,
                    speed: 1/2
                );
            }
        }
    }
);



::<= {
    @:INTEREST_DISTANCE = 4;
    @:CONTACT_DISTANCE = 2;
    @:POINTER = {};

    @:getAllNearby::(mapEntity, map) {
        @:item = map.getItem(data:mapEntity);
        @:nearby = map.getItemsWithinRadius(
            x: item.x,
            y: item.y,
            radius: INTEREST_DISTANCE
        )->filter(by::(value) <- value.data != mapEntity && value.data->type == MapEntity.type);
        POINTER.x = map.pointerX;
        POINTER.y = map.pointerY;
        
        if (distance(x0:POINTER.x, y0:POINTER.y, x1:item.x, y1:item.y) < INTEREST_DISTANCE)
            nearby->push(value:POINTER);
        return nearby;
    }


    MapEntity.Task.Base.new(
        data : {
            name: 'aggressive',
            startup ::{
            },
            
            do ::(data, mapEntity) {
                    


                @:map = mapEntity.controller.map;
                when (map.getDistanceFromItem(data:mapEntity) < CONTACT_DISTANCE) ::<= {
                    mapEntity.remove();

                    @:landmark = mapEntity.controller.landmark;

                    when (world.battle.isActive) ::<= {
                        world.battle.join(group: mapEntity.entities);
                    }
                    
                    
                    world.battle.start(
                        party:  landmark.island.world.party,                            
                        allies: landmark.island.world.party.members,
                        enemies: [...mapEntity.entities],
                        landmark: landmark,
                        loot: true,
                        onAct ::{
                            landmark.step(); // convenient!
                        },
                        
                        onEnd::(result) {
                            when(!world.battle.partyWon()) ::<= {
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
                    ); 

                    
                }


                // get new routes and also squabble
                @:item = map.getItem(data:mapEntity);
                @:nearby = getAllNearby(mapEntity, map);
                @closestDist = 1000000;
                @closest = empty;
                @squabbled = false;
                foreach(nearby) ::(i, itemOther) {
                    
                    @dist = distance(
                        x0: item.x,
                        y0: item.y,
                        x1: itemOther.x,
                        y1: itemOther.y 
                    );
                    if (dist < closestDist) ::<= {
                        closestDist = dist;
                        closest = itemOther;
                    }
                                        
                    if (dist < CONTACT_DISTANCE) ::<= {
                        mapEntity.squabble(other:itemOther.data);
                        squabbled = true;
                    }
                }
                
                // busy!
                when(squabbled)
                    mapEntity.clearPath();
                

                when (closestDist < INTEREST_DISTANCE) ::<= {
                    mapEntity.newPathTo(
                        x:closest.x,
                        y:closest.y
                    );
                }        
            }
        }
    );
}


// specter
::<= {

    @:fetchAllPartyItems ::{
        @:party = world.party;
        @:items = [...party.inventory.items];
        
        foreach(party.members) ::(i, member) {
            foreach(Entity.EQUIP_SLOTS) ::(k, slot) {
                when(slot == Entity.EQUIP_SLOTS.HAND_R) empty;
                @:item = member.getEquipped(slot);
                when(item == empty) empty;
                when(item.name == 'None') empty;
                
                items->push(value:item);
            }                
        }
        return items;
    }
    
    
    @:encounterSpecter ::(mapEntity) {
    
        windowEvent.queueMessage(
            text: 'An apparition comes before the party. Its voice bellows around you.'
        );
    
        windowEvent.queueMessage(
            speaker: '???',
            text: '....Mortal...'
        );

        @:items = fetchAllPartyItems()->filter(by::(value) <- value.base.hasMaterial || value.base.isApparel || value.base.hasQuality);
        when (items->size == 0) ::<= {
            windowEvent.queueMessage(
                speaker: '???',
                text: '...These Shrines are sacred ground...'
            );

            windowEvent.queueMessage(
                speaker: '???',
                text: '...You will pay tribute, or you shall face the consequences...'
            );

            windowEvent.queueMessage(
                speaker: '???',
                text: '...You have been warned...'
            );

        }
        items->sort(comparator::(a, b) {
            when(a.price < b.price) -1;
            when(a.price > b.price)  1;
            return 0;
        });


        windowEvent.queueMessage(
            speaker: '???',
            text: '...You have something I desire...'
        );

        
        @:theDesired = items[items->size-1];
        windowEvent.queueMessage(
            text: '... The ' + theDesired.name + (if (theDesired.equippedBy != empty) " that " + theDesired.equippedBy.name + " holds" else '') + "... It now belongs to the Shrines..."
        );

        windowEvent.queueMessage(
            speaker: '???',
            text: '...You will give it to us, or you will face the consequences...'
        );


        windowEvent.queueAskBoolean(
            prompt: 'Hand over the ' + theDesired.name + '?',
            onChoice::(which) {
                when(which == false) ::<= {
                    windowEvent.queueMessage(
                        speaker: '???',
                        text: '...Then you shall perish...!'
                    );

    
                    when (world.battle.isActive) ::<= {
                        world.battle.join(group: mapEntity.entities);
                    }
                    

                    world.battle.start(
                        party:world.party,                            
                        allies: world.party.members,
                        enemies: [...mapEntity.entities],
                        landmark: mapEntity.controller.landmark,
                        loot: false,
                        onAct ::{
                            mapEntity.controller.landmark.step();
                        },
                        
                        onEnd::(result) {
                            when(world.battle.partyWon()) ::<= {
                                windowEvent.queueMessage(
                                    text: 'The apparitions vanished...'
                                );
                            }
                              
                            @:windowEvent = import(module:'game_singleton.windowevent.mt');
                            windowEvent.queueMessage(text:'The Wyvern Specter claims the items as the Shrine\'s possessions.',
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
                    );
                    
                    
                }
                
                
                // else you agree to fork it over and live another day 
                if (theDesired.equippedBy != empty) ::<= {
                    windowEvent.queueMessage(
                        text: 'The ' + theDesired.name + ' vanished from ' + theDesired.equippedBy.name + '!'
                    );
                    theDesired.equippedBy.unequipItem(item:theDesired);
                } else 
                    windowEvent.queueMessage(
                        text: 'The ' + theDesired.name + ' vanished from the party\'s inventory!'
                    );


                theDesired.throwOut();


                windowEvent.queueMessage(
                    speaker: '???',
                    text: '...A reasonable choice...'
                );

                windowEvent.queueMessage(
                    speaker: '???',
                    text: '...These treasures are not for you...'
                );

                windowEvent.queueMessage(
                    text: 'The apparitions vanished...'
                );

            }
        )
    }

    @:INTEREST_DISTANCE = 3;
    @:CONTACT_DISTANCE = 2;
    @:POINTER = {};

    @:getAllNearby::(mapEntity, map) {
        @:item = map.getItem(data:mapEntity);
        @:nearby = map.getItemsWithinRadius(
            x: item.x,
            y: item.y,
            radius: INTEREST_DISTANCE
        )->filter(by::(value) <- value.data != mapEntity && value.data->type == MapEntity.type);
        POINTER.x = map.pointerX;
        POINTER.y = map.pointerY;
        
        if (distance(x0:POINTER.x, y0:POINTER.y, x1:item.x, y1:item.y) < INTEREST_DISTANCE)
            nearby->push(value:POINTER);
            
            
        return nearby;
    }


    MapEntity.Task.Base.new(
        data : {
            name: 'specter',
            startup ::{
            },
            
            do ::(data, mapEntity) {
                @:map = mapEntity.controller.map;
                @:selfItem = map.getItem(data:mapEntity);

                @index = 0;
                @specters = [];
                @tooClose = false;
                {:::} {
                    foreach(mapEntity.controller.mapEntities) ::(k, ent) {
                        when(ent.tag != 'specter') empty;
                        
                        specters->push(value:ent);
                        when(ent == mapEntity) empty;
                        @:item = map.getItem(data:ent);
                        if (distance(
                            x0: selfItem.x,
                            y0: selfItem.y,
                            x1: item.x,
                            y1: item.y
                        ) < 3) ::<= {
                            tooClose = true;
                            send();
                        }
                    }
                }
                
                // "merge" into existing specters
                when(tooClose) ::<= {
                    mapEntity.remove();
                }
                
                {:::} {
                    foreach(specters) ::(k, specter) {
                        if (specter == mapEntity) send();
                        index += 1;       
                    }
                }
                
                
                when (map.getDistanceFromItem(data:mapEntity) < CONTACT_DISTANCE) ::<= {
                    foreach(specters) ::(k, specter) {
                        specter.remove();
                    }

                    encounterSpecter(mapEntity);
                }


                // get new routes and also squabble
                @:item = map.getItem(data:mapEntity);
                @:nearby = getAllNearby(mapEntity, map)->filter(by::(value) <- value.tag != 'specter');
                @closestDist = 1000000;
                @closest;
                @squabbled = false;
                foreach(nearby) ::(i, itemOther) {
                    when(itemOther.data->type != MapEntity.type) empty;
                    
                    @dist = distance(
                        x0: item.x,
                        y0: item.y,
                        x1: itemOther.x,
                        y1: itemOther.y 
                    );
                    if (dist < closestDist)
                        closestDist = dist;
                    closest = itemOther;
                    
                    if (dist < CONTACT_DISTANCE) ::<= {
                        mapEntity.squabble(other:itemOther.data);
                        squabbled = true;
                    }
                }
                
                // busy!
                when(squabbled)
                    mapEntity.clearPath();

                when (closestDist < INTEREST_DISTANCE) ::<= {
                    mapEntity.newPathTo(
                        x:closest.x,
                        y:closest.y
                    );
                }        

                mapEntity.clearPath();
                if (mapEntity.steps % 3 == index)
                    mapEntity.newPathTo(
                        x:POINTER.x,
                        y:POINTER.y
                    );
            }
        }
    );
}

return MapEntity;
