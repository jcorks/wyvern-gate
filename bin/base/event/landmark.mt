@:Database = import(module:'core/data/database.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:State = import(module:'core/data/state.mt');
@:class = import(module:'Matte.Core.Class');
@:databaseItemMutatorClass = import(module:'core/data/databaseitemmutatorclass.mt');
@:random = import(module:'core/random.mt');




@:ItemSpecter = import(module:'base/event/landmark/itemspecter.mt');
@:Beast   = import(module:'base/event/landmark/thebeast.mt');
@:DungeonEncounters = import(module:'base/event/landmark/dungeonencounters.mt');
@:FlamingSkull  = import(module:'base/event/landmark/flamingskull.mt');
@:Gnome = import(module:'base/event/landmark/gnome.mt');
@:Skeleton = import(module:'base/event/landmark/skeleton.mt');
@:TreasureGolem = import(module:'base/event/landmark/treasuregolem.mt');
@:TheMirror = import(module:'base/event/landmark/themirror.mt');
@:GoldSlime = import(module:'base/event/landmark/goldslime.mt');
@:CreatureEncounters = import(module:'base/event/landmark/creatureencounters.mt')
@:Mimic = import(module:'base/event/landmark/mimic.mt');
@:Slime = import(module:'base/event/landmark/slime.mt');
@:CaveBat = import(module:'base/event/landmark/cavebat.mt');
@:TheSnakeSiren = import(module:'base/event/landmark/thesnakesiren.mt');
@:Shadowling = import(module:'base/event/landmark/shadowling.mt');
@:MobileMushroom = import(module:'base/event/landmark/mobilemushroom.mt');
@:GiantFlea = import(module:'base/event/landmark/giantflea.mt');
@:Monolith = import(module:'base/event/landmark/monolith.mt');
@:Chair = import(module:'base/event/landmark/chair.mt');


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
      @:a = Beast.new(parent);
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
      @:a = FlamingSkull.new(parent);
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
      @:a = Gnome.new(parent);
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
      @:a = Skeleton.new(parent);
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
      @:a = TheMirror.new(parent);
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
      @:a = TreasureGolem.new(parent);
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
      @:a = GoldSlime.new(parent);
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
      @:a = CreatureEncounters.new(parent);
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
      @:a = Mimic.new(parent);
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
      @:a = Slime.new(parent);
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
      @:a = CaveBat.new(parent);
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
      @:a = TheSnakeSiren
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
      @:a = Shadowling.new(parent);
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
      @:a = MobileMushroom.new(parent);
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
      @:a = GiantFlea.new(parent);
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
      @:a = Monolith.new(parent);
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
      @:a = Chair.new(parent);
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
      
      @:distance = import(:'core/distance.mt');
      @:Location = import(module:'base/map/location.mt');
      
      
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
