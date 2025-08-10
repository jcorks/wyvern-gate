@:Database = import(module:'game_class.database.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');
@:class = import(module:'Matte.Core.Class');
@:distance = import(module:'game_function.distance.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:random = import(module:'game_singleton.random.mt');
@:Map = import(module:'game_class.map.mt');
/*
  Some tasks to implement:
    "fight" -> when with party, fights normal, when with npc v npc, does damage to both every step.
    "huntParty" -> step toward party 
    "findExit" -> goes to exit 
    "disappear" -> remove map entity 

*/





@:reset :: {

@:Item = import(module:'game_mutator.item.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Landmark = import(module:'game_mutator.landmark.mt');
@:world = import(module:'game_singleton.world.mt');
@:Battle = import(module:'game_class.battle.mt');
@:Entity = import(module:'game_class.entity.mt');




// roams to random areas with the following triggers:
// if within interest distance, stairs down locations will 
MapEntity.Task.database.newEntry(
  data : {
    id: 'base:dungeonencounters-roam',
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


MapEntity.Task.database.newEntry(
  data : {
    id: 'base:to-body',
    startup :: {
    
    },
    
    do ::(data, mapEntity) {
      @:Location = import(module:'game_mutator.location.mt');
      foreach(mapEntity.entities) ::(k, ent) {
        mapEntity.controller.landmark.addLocation(
          location : Location.new(
            landmark: mapEntity.controller.landmark,
            x:mapEntity.position.x,
            y:mapEntity.position.y,
            ownedByHint: ent,
            base: Location.database.find(:'base:body')
          )
        );    
      }
    }
  }
);

MapEntity.Task.database.newEntry(
  data : {
    id: 'base:to-poison',
    startup :: {
    
    },
    
    do ::(data, mapEntity) {
      @:Location = import(module:'game_mutator.location.mt');
      foreach(mapEntity.entities) ::(k, ent) {
        mapEntity.controller.landmark.addLocation(
          location : Location.new(
            landmark: mapEntity.controller.landmark,
            x:mapEntity.position.x,
            y:mapEntity.position.y,
            ownedByHint: ent,
            base: Location.database.find(:'base:poison-tile'),
            noHalo : true,
            discovered : true
          )
        );    
      }
    }
  }
);



MapEntity.Task.database.newEntry(
  data : {
    id: 'base:thebeast-roam',
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



MapEntity.Task.database.newEntry(

  data : {
    id: 'base:exit',
    startup ::{},
    do ::(data, mapEntity) {
      @:Location = import(module:'game_mutator.location.mt');
      @item = mapEntity.controller.map.getItem(data:mapEntity);
      when(item == empty) empty;
      if (::? {
        foreach(mapEntity.controller.map.getItemsWithinRadius(
          x:item.x,
          y:item.y,
          radius: 2
        )) ::(i, item) {
          if (item.data->type == Location.type && (
            item.data.base.category == Location.CATEGORY.ENTRANCE ||
            item.data.base.category == Location.CATEGORY.EXIT
          ))
            send(message:true);
        
        }
        
        return false;
      }) 
        mapEntity.remove();
      
    
    }
  }
)


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
    
    if (distance(
      x0:POINTER.x, y0:POINTER.y, x1:item.x, y1:item.y) < INTEREST_DISTANCE &&
      mapEntity.data.caresAboutParty == true
    )
      nearby->push(value:POINTER);
    return nearby;
  }

  @:aggressive = ::(speed, data, mapEntity, noAttackParty, onDeath) {
    if (mapEntity.data.caresAboutParty == empty) ::<= {
      mapEntity.data.caresAboutParty = random.try(percentSuccess:80); 
    }
    @:map = mapEntity.controller.map;
    when (map.getDistanceFromItem(data:mapEntity) < CONTACT_DISTANCE && (noAttackParty == empty)) ::<= {
      @:pos = mapEntity.position;
      @:landmark = mapEntity.controller.landmark;

      when (world.battle.isActive) ::<= {
        when (world.battle.isMember(:mapEntity.entities[0])) empty;
        when (mapEntity.entities[0].isIncapacitated()) empty;

        // swarming will group them in the same 
        // team as the currently swarmed enemy
        @:all = world.battle.getMembers();
        ::? {
          foreach(all) ::(k, member) {
            if (
              (mapEntity.entities[0].species.swarms &&member.species.id == mapEntity.entities[0].species.id)
              ||
              (mapEntity.isFriend(:member.species.id))        
            ) ::<= {
              world.battle.join(group: mapEntity.entities, sameGroupAs:member);            
              world.battle.addOnFinishCallback(::(result) {
                mapEntity.kill();
                mapEntity.remove();          
              });            
              send();
            }
          }   
          world.battle.join(group: mapEntity.entities);
          world.battle.addOnFinishCallback(::(result) {
            mapEntity.kill();
            mapEntity.remove();          
          });            
        }
      }

      mapEntity.clearPath();
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
          @:Location = import(module:'game_mutator.location.mt');
          @:Species = import(module:'game_database.species.mt');
          when(!world.battle.partyWon()) ::<= {
            @:windowEvent = import(module:'game_singleton.windowevent.mt');

            @:instance = import(module:'game_singleton.instance.mt');
            instance.gameOver(reason: 'The party has been wiped out.');
          }
          
          mapEntity.kill();
          mapEntity.remove();
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
      when (itemOther.data->type != mapEntity->type  &&
            itemOther != POINTER) empty;

      // swarming enemies dont attack each other
      when (itemOther.data != empty && // filter out pointer
          (((mapEntity.entities[0].species.swarms && 
           mapEntity.entities[0].species.id == itemOther.data.entities[0].species.id))
         ||
           mapEntity.isFriend(:mapEntity.entities[0].species.id)))
        empty;
      
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
                
      if (dist < CONTACT_DISTANCE && itemOther.data != empty) ::<= {
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
        y:closest.y,
        speed
      );
    }    
  }


  MapEntity.Task.database.newEntry(
    data : {
      id: 'base:aggressive',
      startup ::{
      },
      
      do ::(data, mapEntity) {
        aggressive(speed:1, data, mapEntity);    
      }
    }
  );
  
  MapEntity.Task.database.newEntry(
    data : {
      id: 'base:aggressive-slow',
      startup ::{
      },
      
      do ::(data, mapEntity) {
        aggressive(speed:0.5, data, mapEntity);    
      }
    }
  );  
  
  MapEntity.Task.database.newEntry(
    data : {
      id: 'base:aggressive-no-party',
      startup ::{
      },
      
      do ::(data, mapEntity) {
        aggressive(speed:0.5, data, noAttackParty:true, mapEntity);    
      }
    }
  );    
}


// specter
::<= {
  @:itemToEquipper = [];
  @:fetchAllPartyItems ::{
    @:party = world.party;
    @:items = [...party.inventory.items];
    
    foreach(party.members) ::(i, member) {
      foreach(Entity.EQUIP_SLOTS) ::(k, slot) {
        @:item = member.getEquipped(slot);
        when(item == empty) empty;
        when(item.base.id == 'base:none') empty;
        
        items->push(value:item);
        itemToEquipper[item] = member;
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

    @:items = fetchAllPartyItems()->filter(by::(value) <- 
      value.base.hasAnyTrait(:
        Item.TRAIT.METAL |
        Item.TRAIT.APPAREL |
        Item.TRAIT.HAS_QUALITY
      )
    );
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
      text: '... The ' + theDesired.name + (if (itemToEquipper[theDesired] != empty) " that " + itemToEquipper[theDesired].name + " holds" else '') + "... It now belongs to the Shrines..."
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
              @:windowEvent = import(module:'game_singleton.windowevent.mt');
              when(world.battle.partyWon()) ::<= {
                windowEvent.queueMessage(
                  text: 'The apparitions vanished...'
                );
              }
                
              @:instance = import(module:'game_singleton.instance.mt');
              instance.gameOver(reason:'The Wyvern Specter claims the items as the Shrine\'s possessions.');
            }
          );
          
          
        }
        
        
        // else you agree to fork it over and live another day 
        if (itemToEquipper[theDesired] != empty) ::<= {
          windowEvent.queueMessage(
            text: 'The ' + theDesired.name + ' vanished from ' + itemToEquipper[theDesired].name + '!'
          );
          itemToEquipper[theDesired].unequipItem(item:theDesired);
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


  MapEntity.Task.database.newEntry(
    data : {
      id: 'base:specter',
      startup ::{
      },
      
      do ::(data, mapEntity) {
        @:map = mapEntity.controller.map;
        @:selfItem = map.getItem(data:mapEntity);

        @index = 0;
        @specters = [];
        @tooClose = false;
        ::? {
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
        
        ::? {
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


@:THESNAKESIREN_SONG_DISTANCE = 18;
MapEntity.Task.database.newEntry(
  data : {
    id: 'base:thesnakesiren-song',
    startup ::{
      
    },
    
    do ::(data, mapEntity) {
      @:map = mapEntity.controller.map;
      @:item = map.getItem(data:mapEntity);

      @:siren = mapEntity.entities[0];

      when (siren.data.thesnakesiren_heardsong == true) ::<= {
        map.movePointerToward(
          x: item.x,
          y: item.y
        );
      }
    

      when(distance(
        x0:map.pointerX, y0:map.pointerX,
        x1:item.x, y1:item.y
      ) > THESNAKESIREN_SONG_DISTANCE) empty;


      when (siren.data.thesnakesiren_heardsong == false) empty;    
    
    
      windowEvent.queueMessage(
        text: 'The party hears a sweet, pleasant song in the distance...'
      );
      
      windowEvent.queueAskBoolean(
        prompt: 'Listen to the song?',
        onChoice::(which) {
          when(which == false) ::<= {
            windowEvent.queueMessage(
              text: 'The party ignores the pleasant-yet-harrowing song.'
            );
            siren.data.thesnakesiren_heardsong = false;
          }
          
          siren.data.thesnakesiren_heardsong = true;
          windowEvent.queueMessage(
            text: 'The party takes a second to listen to the song.'
          );

          windowEvent.queueMessage(
            text: 'The party suddenly feels compelled to go to the source of the song.'
          );
        }
      );
      // to prevent multi-steps
      siren.data.thesnakesiren_heardsong = false;

    }
  }
);



MapEntity.Task.database.newEntry(
  data : {
    id: 'base:thesnakesiren-roam',
    startup ::{
      
    },
    
    do ::(data, mapEntity) {
      @:map = mapEntity.controller.map;    
      mapEntity.newPathTo(
        x:map.pointerX,
        y:map.pointerY,
        speed: 2/3
      );
    }
  }
);


MapEntity.Task.database.newEntry(
  data : {
    id: 'base:shadow',
    startup ::{
      
    },
    
    do ::(data, mapEntity) {
      @:map = mapEntity.controller.map;    
      map.obscureRadius(
        x: mapEntity.position.x,
        y: mapEntity.position.y,
        radius:6
      );
    }
  }
);



MapEntity.Task.database.newEntry(
  data : {
    id: 'base:teleport-offscreen',
    startup ::{
      
    },
    
    do ::(data, mapEntity) {
      @:map = mapEntity.controller.map;    
      when(map.isLocationVisible(
        x:mapEntity.position.x,
        y:mapEntity.position.y
      )) empty;
      
      if (random.try(percentSuccess:15)) ::<= { 
        @:newLoc = map.getRandomArea();
        when(map.isLocationVisible(
          x:newLoc.x,
          y:newLoc.y
        )) empty;

        mapEntity.move(
          x:newLoc.x,
          y:newLoc.y
        );

      }
    }
  }
);



}


@:stepEmitter = import(:'game_class.particle.mt').new(
  directionMin: 0,
  directionMax: 0,
  directionDeltaMin: 0,
  directionDeltaMax: 10,
  
  speedMin: 0,
  speedMax: 0,
  speedDeltaMin: 0,
  speedDeltaMax: 0,
  
  characters : ['=', '-', '-', ',', ',', ',', '.', '.', '.'],
  lifeMin: 5,
  lifeMax: 9
); 


@:damageEmitter = import(:'game_class.particle.mt').new(
  directionMin: 0,
  directionMax: 360,
  directionDeltaMin: 3,
  directionDeltaMax: 10,
  
  speedMin: 1,
  speedMax: 3,
  speedDeltaMin: -0.06,
  speedDeltaMax: -0.02,
  
  characters : ['X', 'X', 'x', ',', ',', ',', '.', '.', '.'],
  lifeMin: 2,
  lifeMax: 6
); 



@:MapEntity = LoadableClass.create(
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
  items : {
    tag : '',
    entities : empty,
    targetX : -1,
    targetY : -1,
    path : empty,
    onArrive  : empty, // MapEntity.Task to do when arriving 
    onCancel  : empty, // MapEntity.Task to do when cancelling.
    onStepSet : empty, // MapEntity.Task array to do each step
    onDeathSet: empty, // MapEntity.Task array to do on death
    steps : 0,
    speedSteps : 0,
    speed : 1,
    locationID : -1,
    data : empty,
    friends : empty // array of species ids to
  },
  define:::(this, state) {
    @:Item = import(module:'game_mutator.item.mt');
    @:Damage = import(module:'game_class.damage.mt');
    @:Landmark = import(module:'game_mutator.landmark.mt');
    @:world = import(module:'game_singleton.world.mt');
    @:Battle = import(module:'game_class.battle.mt');
    @:Entity = import(module:'game_class.entity.mt');
  

    @map_;
    @isRemoved = false;
    @location_;
    @lastPosition;
    
    @:animateClash::(other) {
      damageEmitter.tether(:map_);
      damageEmitter.move(
        x:this.position.x,
        y:this.position.y
      );
      damageEmitter.start(:5);
      damageEmitter.stop();
    }
    
    
    this.interface = {
      initialize ::(parent) {
        parent => Map.type
        map_ = parent;

        if (state.locationID != -1) ::<= {        
          ::? {
            foreach(map_.parent.locations) ::(k, v) {
              if (v.worldID == state.locationID) ::<= {
                location_ = v;
                send();
              }
            }
          }
        }
      },
      
      data : {
        get ::<- state.data
      },
      
      defaultLoad::(x, y, symbol, entities => Object, tag, location) {
        state.entities = entities;
        state.tag = tag;
        state.onStepSet = [];
        state.onDeathSet = [];
        state.friends = [];
        state.data = {};
        map_.setItem(data:this, x, y, discovered:true, symbol); 
        if (location != empty) ::<= {
          state.locationID = location.worldID;
          location_ = location;
          location_.x = x;
          location_.y = y;
          map_.parent.addLocation(location);
        }
      },
      
      isFriend::(id) <- state.friends->findIndex(:id) != -1,
      
      addFriendSpecies ::(id)  {
        if (state.friends == empty)
          state.friends = [];
          
        state.friends->push(:id)
      },
      
      
      steps : {
        get ::<- state.steps
      },
      
      tag : {
        get ::<- state.tag
      },
      
      position : {
        get ::<- if (lastPosition != empty) lastPosition else map_.getItem(data:this)
      },
      
      move ::(x, y) {
        @:item = map_.getItem(data:this);
        when(item == empty) empty;

        @:oldX = this.position.x;
        @:oldY = this.position.y;

        when(oldX == x &&
             oldY == y) empty;


        map_.moveItem(data:this, x, y);
        if (location_ != empty) ::<= {
          map_.moveItem(data:location_, x, y);        
        }
        stepEmitter.tether(:map_);
        stepEmitter.move(
          x:oldX,
          y:oldY
        );


        stepEmitter.start();
        stepEmitter.stop();
        
      },
    
      step :: {
        when(isRemoved) empty;
        state.steps += 1;
        state.speedSteps += state.speed;
        foreach(state.onStepSet) ::(k, task) {
          task.do(mapEntity:this);
        }
      
      
        @path = state.path;
        when(path == empty) empty;
        when(state.speedSteps < 1) empty;
        state.speedSteps -= 1;
        when(isRemoved) empty;
        when (
          distance(x0:state.targetX,
               y0:state.targetY,
               
               x1:map_.getItem(data:this).x,
               y1:map_.getItem(data:this).y
        ) < 2) ::<={
          state.onCancel = empty;
          if (state.onArrive) ::<= {
            @:task = MapEntity.Task.new(
              base:MapEntity.Task.database.find(id:state.onArrive)
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
        if (map_.isWalled(x:next.x, y:next.y))
          state.path = map_.getPathTo(
            data:this,
            x:state.targetX,
            y:state.targetY,
            useBFS:true
          );
        
        this.move(x:next.x, y:next.y);
        @:Location = import(module:'game_mutator.location.mt');

        @:items = map_.itemsAt(x:next.x, y:next.y);
        if (items != empty) ::<= {
          foreach(items) ::(k, v) {
            if (v.data->type == Location.type) ::<= {
              when (v.data == location_) empty;
              v.data.base.onStep(entities:state.entities, location:v.data);
            }
          }
        }
      },
      
      addUpkeepTask ::(id) {
        state.onStepSet->push(
          value: MapEntity.Task.new(
            base:MapEntity.Task.database.find(id)
          )
        );
      },
      
      addDeathTask ::(id) {
        state.onDeathSet->push(
          value: MapEntity.Task.new(
            base:MapEntity.Task.database.find(id)
          )
        );
      },   
      
      kill :: {
        foreach(state.onDeathSet) ::(k, task) {
          task.do(mapEntity:this);
        }
      },   
      
      removeUpkeepTask ::(id) {
        @:index = state.onStepSet->findIndex(query::(value) <- value.base.id == id);
        when(index == -1) empty;
        state.onStepSet->remove(key:index);
      },
      
      controller : {
        get ::<- map_.parent.mapEntityController
      },
      
      // for non-battle fighting between NPCs.
      // each member does a blow to a random other member who is 
      // not incapacitated. Simplified attacks.
      squabble ::(other => MapEntity.type, onDeath) {
        this.clearPath();
        windowEvent.autoSkip = true;
        
          @:allies = state.entities->filter(by::(value) <- !value.isIncapacitated());
          @:enemies = other.entities->filter(by::(value) <- !value.isIncapacitated());
          if (enemies->size > 0)  ::<= {
            foreach(allies) ::(i, ally) {
              @target = random.pickArrayItem(list:enemies);
              ally.attack(
                target,
                damage: Damage.new(
                  amount:ally.stats.ATK * (0.5),
                  damageType : Damage.TYPE.PHYS,
                  damageClass: Damage.CLASS.HP
                )
              );     
              animateClash(:other);
            }
          }
          
          @defeated = true;
          foreach(enemies) ::(i, enemy) {
            if (!enemy.isIncapacitated())
              defeated = false;
          }

        windowEvent.autoSkip = false;
        @:Location = import(module:'game_mutator.location.mt');
        
        
        if (defeated) ::<= {
          @:otherItem = map_.getItem(data:other);
          other.remove();
          
          // Not really needed it seems since we have Bodies appearing 
          // for fallen teams.
          /*
          if (distance(   
            x0: map_.pointerX,
            y0: map_.pointerY,
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
          */
            
          @coversEntranceExit = ::? {
            foreach(map_.getItemsWithinRadius(
              x:otherItem.x,
              y:otherItem.y,
              radius: 2
            )) ::(i, item) {
              if (item.data->type == Location.type && (
                item.data.base.category == Location.CATEGORY.ENTRANCE ||
                item.data.base.category == Location.CATEGORY.EXIT
              ))
                send(message:true);
            
            }
            
            return false;
          }
          
          if (!coversEntranceExit) ::<= {
            other.kill();
          }
        }
      },
      
      remove :: {
        when(isRemoved) empty;
        lastPosition = this.position;
        isRemoved = true;
        this.controller.remove(entity:this);
      },
      
      entities : {
        get ::<- state.entities
      },

      // sets a new place to go to
      newPathTo ::(x => Number, y => Number, onArrive, onCancel, speed) {
        when(isRemoved) empty;
        this.clearPath();
        state.speed = if (speed == empty) 1 else speed;
        state.targetX = x;
        state.targetY = y;
        state.onArrive = onArrive;
        state.onCancel = onCancel;
        state.path = map_.getPathTo(
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
            base:MapEntity.Task.database.find(id:state.onArrive)
          );
          task.do(mapEntity:this);
        }
        state.path = empty;
        state.onCancel = empty;
        state.onArrive = empty;      
      },
      
      hasPath : {
        get ::<- state.path != empty
      }     
    }
  }
)



MapEntity.Controller = LoadableClass.create(
  name : 'Wyvern.MapEntity.Controller',
  items : {
    // it used to be mapEntities, but the map will own all instances, 
    // and we cant have reference copies anywhere.
  },
  define:::(this, state) {
  
    @map_;
    @landmark_;
    
    @:Landmark = import(module:'game_mutator.landmark.mt');

    
    this.interface = {
      initialize ::(parent) {
        landmark_ = parent => Landmark.type;
        map_ = parent.map;
      },
      
      defaultLoad ::{},
      
      map : {
        get ::<- map_
      },
      
      landmark : {
        get ::<- landmark_
      },
      
      add::(x, y, symbol, entities => Object, tag, interactions, location) {
        return MapEntity.new(parent:map_, x, y, symbol, entities, tag, interactions, location); // automatically gets added to mapEntities
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
      }
    }
  }
);

MapEntity.Task = databaseItemMutatorClass.create(
  name : "Wyvern.MapEntity.Task",
  items : {
    data : empty
  },  
  database : Database.new(
    name : 'Wyvern.MapEntity.Task.Base',
    attributes : {
      id : String,
      startup : Function,
      do : Function
    },
    reset
  ),
  define::(this, state) {  
    this.interface = {
      defaultLoad ::(base) {
        state.data = base.startup();
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

import(module:'game_class.landmarkevent_thebeast.mt');
import(module:'game_class.landmarkevent_cavebat.mt');
import(module:'game_class.landmarkevent_dungeonencounters.mt');
import(module:'game_class.landmarkevent_itemspecter.mt');
import(module:'game_class.landmarkevent_themirror.mt');
import(module:'game_class.landmarkevent_treasuregolem.mt');
import(module:'game_class.landmarkevent_thesnakesiren.mt');
import(module:'game_class.landmarkevent_mimic.mt');
import(module:'game_class.landmarkevent_slime.mt');
import(module:'game_class.landmarkevent_chair.mt');
import(module:'game_class.landmarkevent_shadowling.mt');



return MapEntity;
