@:Database = import(module:'game_class.database.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');
@:class = import(module:'Matte.Core.Class');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:random = import(module:'game_singleton.random.mt');








@:reset ::{
LandmarkEvent.database.newEntry(
  data : {
    id: 'base:item-specter',
    startup ::(parent) {
      @:ItemSpecter = import(module:'game_class.landmarkevent_itemspecter.mt');
      @:a = ItemSpecter.new(parent);
      return a;
    },

    onIncrementTime ::(data, landmark) {
    
    },
    
    onStep ::(data, landmark) {
      data.step();
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);

LandmarkEvent.database.newEntry(
  data : {
    id: 'base:dungeon-encounters',
    startup ::(parent) {
      @:DungeonEncounters = import(module:'game_class.landmarkevent_dungeonencounters.mt');
      // TODO: make dungeon encounters loadable
      @:a = DungeonEncounters.new(parent);   
      return a;
    },
    
    onIncrementTime ::(data, landmark) {
    
    },
    
    
    onStep ::(data, landmark) {
      data.step();
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);

LandmarkEvent.database.newEntry(
  data : {
    id: 'base:the-beast',
    startup ::(parent) {
      @:b = import(module:'game_class.landmarkevent_thebeast.mt');
      @:a = b.new(parent);
      return a;
    },

    onIncrementTime ::(data, landmark) {
    
    },

    
    onStep ::(data, landmark) {
      data.step();
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);

LandmarkEvent.database.newEntry(
  data : {
    id: 'base:the-mirror',
    startup ::(parent) {
      @:b = import(module:'game_class.landmarkevent_themirror.mt');
      @:a = b.new(parent);
      return a;
    },
    onIncrementTime ::(data, landmark) {
    
    },

    
    onStep ::(data, landmark) {
      data.step();
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:treasure-golem',
    startup ::(parent) {
      @:b = import(module:'game_class.landmarkevent_treasuregolem.mt');
      @:a = b.new(parent);
      return a;
    },

    onIncrementTime ::(data, landmark) {
    
    },

    
    onStep ::(data, landmark) {
      data.step();
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);

LandmarkEvent.database.newEntry(
  data : {
    id: 'base:mimic',
    startup ::(parent) {
      @:b = import(module:'game_class.landmarkevent_mimic.mt');
      @:a = b.new(parent);
      return a;
    },

    onIncrementTime ::(data, landmark) {
    
    },

    
    onStep ::(data, landmark) {
      data.step();
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);




LandmarkEvent.database.newEntry(
  data : {
    id: 'base:cave-bat',
    startup ::(parent) {
      @:b = import(module:'game_class.landmarkevent_cavebat.mt');
      @:a = b.new(parent);
      return a;
    },


    onIncrementTime ::(data, landmark) {
    
    },
    
    onStep ::(data, landmark) {
      data.step();
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:the-snakesiren',
    startup ::(parent) {
      @:b = import(module:'game_class.landmarkevent_thesnakesiren.mt');
      @:a = b.new(parent);
      return a;
    },

    onIncrementTime ::(data, landmark) {
    
    },

    
    onStep ::(data, landmark) {
      data.step();
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:funny-tiles',
    startup ::(parent) {
      when(random.try(percentSuccess:85)) empty;
    
      @:landmark = parent.landmark;
      @:map = parent.landmark.map;
      @:area = map.getRandomArea();
      @:blastRadius = random.integer(from:3, to:6);
      @:isBenign = random.flipCoin();
      
      @:distance = import(:'game_function.distance.mt');
      @:Location = import(module:'game_mutator.location.mt');
      
      
      for(area.x + area.width/2 - blastRadius/2, area.x + area.width/2 + blastRadius/2) ::(x) {
        for(area.y + area.height/2 - blastRadius/2, area.y + area.height/2 + blastRadius/2) ::(y) {
          if (distance(x0:x, y0:y, x1:area.x + area.width/2, y1:area.y + area.height/2) < blastRadius) ::<= {
            @:items = map.itemsAt(x:x, y:y) 
            if (items == empty) 
              landmark.addLocation(
                location : Location.new(
                  landmark: landmark,
                  base: Location.database.find(id:
                    if (isBenign)
                      'base:water-tile'
                    else 
                      'base:poison-tile'
                  ),
                  x,
                  y
                )
              )
          }
        }
      }
      
    },


    onIncrementTime ::(data, landmark) {
    
    },
    
    onStep ::(data, landmark) {
    },
    
    isActive ::(data) {
      return false;
    }
  }
);



}

// essentially an opaque wrapper for custom per-step 
// controllers of landmarks.
@:LandmarkEvent = databaseItemMutatorClass.create(
  name : 'Wyvern.LandmarkEvent',
  items : {
    data : empty // maintained  
  },
  
  database : Database.new(
    name:'Wyvern.LandmarkEvent.Base',
    attributes : {
      id : String,
      startup : Function,
      onStep : Function,
      onIncrementTime : Function,
      isActive : Function
    },
    reset
  ),
  
  define::(this, state) {
    
    @landmark_;
        
    this.interface = {
      initialize ::(parent) {
        landmark_ = parent;
      },
            
      defaultLoad ::(base) {
        state.base = base;
        state.data = base.startup(parent:this);
      },
      
      landmark : {
        get ::<- landmark_
      },
      
      step::{
        state.base.onStep(
          landmark:landmark_,
          data:state.data
        );
      },

      incrementTime::{
        state.base.onIncrementTime(
          landmark:landmark_,
          data:state.data
        );
      },

      
      isActive ::{
        return state.base.isActive(data:state.data);
      }
    }
  }
);


return LandmarkEvent;
