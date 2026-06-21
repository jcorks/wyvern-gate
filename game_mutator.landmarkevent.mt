@:Database = import(module:'game_class.database.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');
@:class = import(module:'Matte.Core.Class');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:random = import(module:'game_singleton.random.mt');



@:KIND = {
  HOSTILE : 1,
  PEACEFUL : 2,
  NEUTRAL : 3
}


@:reset ::{
LandmarkEvent.database.newEntry(
  data : {
    id: 'base:item-specter',
    kind : KIND.HOSTILE,
    tier : 0,
    startup ::(parent, x, y) {
      @:ItemSpecter = import(module:'game_class.landmarkevent_itemspecter.mt');
      @:a = ItemSpecter.new(parent);
      return a;
    },
    
    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);

LandmarkEvent.database.newEntry(
  data : {
    id: 'base:dungeon-encounters',
    kind : KIND.HOSTILE,
    tier : 0,
    startup ::(parent, x, y) {
      @:DungeonEncounters = import(module:'game_class.landmarkevent_dungeonencounters.mt');
      // TODO: make dungeon encounters loadable
      @:a = DungeonEncounters.new(parent);   
      return a;
    },
    
    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);

LandmarkEvent.database.newEntry(
  data : {
    id: 'base:the-beast',
    kind : KIND.HOSTILE,
    tier : 1,
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_thebeast.mt');
      @:a = b.new(parent);
      return a;
    },
    
    events : {      
      onStep ::(data, landmark) {
        data.step();
      },
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:flaming-skull',
    kind : KIND.HOSTILE,
    tier : 1,
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_flamingskull.mt');
      @:a = b.new(parent);
      return a;
    },

    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    isActive ::(data) {
      return data.isActive()
    }
  }
);



LandmarkEvent.database.newEntry(
  data : {
    id: 'base:gnome',
    kind : KIND.HOSTILE,
    tier : 1,
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_gnome.mt');
      @:a = b.new(parent);
      return a;
    },

    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:skeleton',
    kind : KIND.HOSTILE,
    tier : 0,
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_skeleton.mt');
      @:a = b.new(parent);
      return a;
    },
    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);

LandmarkEvent.database.newEntry(
  data : {
    id: 'base:the-mirror',
    kind : KIND.HOSTILE,
    tier : 3,
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_themirror.mt');
      @:a = b.new(parent);
      return a;
    },
    
    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:treasure-golem',
    tier : 1,
    kind : KIND.HOSTILE,
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_treasuregolem.mt');
      @:a = b.new(parent);
      return a;
    },

    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);

LandmarkEvent.database.newEntry(
  data : {
    id: 'base:gold-slime',
    tier : 0,
    kind : KIND.HOSTILE,
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_goldslime.mt');
      @:a = b.new(parent);
      return a;
    },

    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:creature-encounters',
    tier : 0,
    kind : KIND.HOSTILE,
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_creatureencounters.mt');
      @:a = b.new(parent);
      return a;
    },

    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);

LandmarkEvent.database.newEntry(
  data : {
    id: 'base:mimic',
    kind : KIND.HOSTILE,
    tier : 1,
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_mimic.mt');
      @:a = b.new(parent);
      return a;
    },

    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);



LandmarkEvent.database.newEntry(
  data : {
    id: 'base:slimequeen',
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_slime.mt');
      @:a = b.new(parent);
      return a;
    },
    kind : KIND.HOSTILE,
    tier : 1,

    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);




LandmarkEvent.database.newEntry(
  data : {
    id: 'base:cave-bat',
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_cavebat.mt');
      @:a = b.new(parent);
      return a;
    },
    kind : KIND.HOSTILE,
    tier : 0,


    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:the-snakesiren',
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_thesnakesiren.mt');
      @:a = b.new(parent);
      return a;
    },
    kind : KIND.HOSTILE,
    tier : 2,

    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:shadowling',
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_shadowling.mt');
      @:a = b.new(parent);
      return a;
    },
    kind : KIND.HOSTILE,
    tier : 0,


    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:mobile-mushroom',
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_mobilemushroom.mt');
      @:a = b.new(parent);
      return a;
    },
    kind : KIND.HOSTILE,
    tier : 0,


    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);

LandmarkEvent.database.newEntry(
  data : {
    id: 'base:giant-flea',
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_giantflea.mt');
      @:a = b.new(parent);
      return a;
    },
    kind : KIND.HOSTILE,
    tier : 0,
    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);

LandmarkEvent.database.newEntry(
  data : {
    id: 'base:monolith',
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_monolith.mt');
      @:a = b.new(parent);
      return a;
    },
    kind : KIND.HOSTILE,
    tier : 1,
    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:chair',
    startup ::(parent, x, y) {
      @:b = import(module:'game_class.landmarkevent_chair.mt');
      @:a = b.new(parent);
      return a;
    },
    kind : KIND.HOSTILE,
    tier : 0,


    events : {
      onStep ::(data, landmark) {
        data.step();
      }
    },
    
    isActive ::(data) {
      return data.isActive()
    }
  }
);


LandmarkEvent.database.newEntry(
  data : {
    id: 'base:funny-tiles',
    kind : KIND.HOSTILE ,
    tier : 0,
    startup ::(parent, x, y) {
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


    events : {},
    
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
  
  statics : {
    KIND : {get ::<- KIND}
  },
  items : {
    data : empty // maintained  
  },
  
  database : Database.new(
    name:'Wyvern.LandmarkEvent.Base',
    attributes : {
      id : String,
      startup : Function,
      tier : Number,
      kind : Number,
      events : Object,
      isActive : Function
    },
    reset,
    knownEvents : [
      'onStep'
    ]
  ),
  
  define::(this, state) {
    
    @landmark_;
        
    this.interface = {
      initialize ::(parent) {
        landmark_ = parent;
      },
            
      defaultLoad ::(base, x, y) {
        state.base = base;
        state.data = base.startup(parent:this, x, y);
      },
      
      landmark : {
        get ::<- landmark_
      },
      
      step::{
        state.base.emit(event:'onStep',
          landmark:landmark_,
          data:state.data
        )
      },

      incrementTime::{
        state.base.emit(event:'onIncrementTime',
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
