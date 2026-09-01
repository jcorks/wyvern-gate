@:Database = import(module:'core/data/database.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:State = import(module:'core/data/state.mt');
@:class = import(module:'Matte.Core.Class');
@:databaseItemMutatorClass = import(module:'core/data/databaseitemmutatorclass.mt');
@:random = import(module:'core/random.mt');
@:Encounter = import(module:'base/event/landmark/encounter.mt');
@:Inventory = import(module:'base/item/inventory.mt');
@:Item = import(module:'base/item.mt');
@:Entity = import(module:'base/entity.mt');

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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        symbol : 'x',
        speciesID : 'base:wyvern-specter',
        professionID : 'base:wyvern-specter',
        maxEncounters : if (parent.landmark.floor == 0 || parent.landmark.floor%3 != 0) 0 else 3,
        maxSimultaneousEncounters : 3,
        membersPerTeam : if (parent.landmark.island.tier > 2 && random.try(percentSuccess:35)) 2 else 1,
        townsfolk: false,
        name : 'the Wyvern Specter',
        
        upkeepTasks : [
          'base:specter'
        ],
        
        forceDrop : Inventory.new(
          items : [
            Item.new(base:Item.database.find(:'base:life-crystal'))
          ]
        ),
        
        enterPhrases : [
          'Something\'s off... It\'s not safe here.',
          'Do you feel that? Something... different... is here.',
        ]
      )
    ,
    
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
      @:landmark = parent.landmark;
      @:a = if (random.try(percentSuccess:10)) 
        Encounter.new(
        parent,
          symbol : '*',
          
          maxEncounters : if (parent.landmark.floor == 0) 0 else 10,
          maxSimultaneousEncounters : 5,
          membersPerTeam : if (landmark.island.tier > 2 && random.try(percentSuccess:35)) 2 else 1,
          townsfolk: true,
          
          
          upkeepTasks : [
            'base:dungeonencounters-roam',
            'base:aggressive',
            'base:exit'
          ],
          
          deathTasks : [
            'base:to-body'
          ],
          
          enterPhrases : [
            'There seems to be a lot of commotion around on this floor...',
            'What? It sounds like a large battle nearby...'
          ]
        )
      else 
        Encounter.new(
        parent,
          symbol : '*',
          
          maxEncounters : if (parent.landmark.floor == 0) 0 else 2,
          maxSimultaneousEncounters : random.integer(from:1, to:2),
          membersPerTeam : if (landmark.island.tier > 2 && random.try(percentSuccess:35)) 2 else 1,
          townsfolk: true,
          
          
          upkeepTasks : [
            'base:dungeonencounters-roam',
            'base:aggressive',
            'base:exit'
          ],
          
          deathTasks : [
            'base:to-body'
          ],
          
          enterPhrases : [
            'Are those foosteps? Be careful.',
            'Hmm. Footsteps nearby.',
            'What? Footsteps?'
          ]
        );  
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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Dungeon Beast',
        symbol : 'B',
        speciesID : 'base:beast',
        professionID : 'base:beast',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 1,
        maxSimultaneousEncounters : 1,
        membersPerTeam : 1,
        townsfolk: false,
        
        
        upkeepTasks : [
          'base:thebeast-roam',
          'base:aggressive',
        ],
        
        deathTasks : [
          'base:to-body'
        ],

        
        enterPhrases : [
          'That was definitely a roar or snarl just now. Something\'s near.',
          'Something heavy is stomping nearby.',
        ]
      )
    ,
    
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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Flaming Skull',
        symbol : '@',
        speciesID : 'base:flaming-skull',
        professionID : 'base:flaming-skull',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 2,
        maxSimultaneousEncounters : if (random.try(percentSuccess:20)) 2 else 1,
        membersPerTeam : 1,
        townsfolk: false,
        
        
        upkeepTasks : [
          'base:thebeast-roam',
          'base:aggressive',
          'base:flamingskull-particle'
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,

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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Gnome',
        symbol : 'g',
        speciesID : 'base:gnome',
        professionID : 'base:gnome',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 2,
        maxSimultaneousEncounters : if (random.try(percentSuccess:20)) 2 else 1,
        membersPerTeam : 1,
        townsfolk: false,
        
        
        upkeepTasks : [
          'base:dungeonencounters-roam',
          'base:aggressive',
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,

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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Skeleton',
        symbol : '#',
        speciesID : 'base:skeleton',
        professionID : 'base:skeleton',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 2,
        maxSimultaneousEncounters : if (random.try(percentSuccess:40)) 2 else 1,
        membersPerTeam : 1,
        townsfolk: false,
        
        
        upkeepTasks : [
          'base:dungeonencounters-roam',
          'base:aggressive',
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,
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
      @:world = import(module:'base/world.mt');

      return Encounter.new(
        parent,
        name : 'the Mirror',
        symbol : 'Ø',
        teamArchetype : world.party.members->map(::(value) {
          @:state = value.save();
          state.name = state.name + ' (clone)';
          return Entity.new(parent, state)
        }),
        maxEncounters : if (parent.landmark.floor == 0) 0 else 1,
        maxSimultaneousEncounters : 1,
        townsfolk: false,
        forceDrop : Inventory.new(
          items : [
            Item.new(base:Item.database.find(:'base:life-crystal'))
          ]
        ),

        upkeepTasks : [
          'base:dungeonencounters-roam',
          'base:aggressive',
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Treasure Golem',
        symbol : '$',
        speciesID : 'base:treasure-golem',
        professionID : 'base:treasure-golem',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 1,
        maxSimultaneousEncounters : 1,
        membersPerTeam : 1,
        townsfolk: false,
        
        forceDrop : Inventory.new(
          gold: 900 + (random.number()*200)->floor
        ),
        
        upkeepTasks : [
          'base:aggressive-slow',
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,

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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Gold Slime',
        symbol : 's',
        speciesID : 'base:gold-slime',
        professionID : 'base:gold-slime',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 1,
        maxSimultaneousEncounters : 1,
        membersPerTeam : 1,
        townsfolk: false,
        
        forceDrop : Inventory.new(
          items : [
            Item.new(
              base : Item.database.getRandomFiltered(::(value) <- 
                value.hasTraits(:Item.TRAIT.CAN_BE_APPRAISED)
              ),
              forceNeedsAppraisal : true 
            )
          ]
        ),
        
        upkeepTasks : [
          'base:exit',
          'base:defensive',
          'base:dungeonencounters-roam',
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,

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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        symbol : '{',
        teamArchetype : [parent.landmark.island.newHostileCreature()],
        maxEncounters : if (parent.landmark.floor == 0) 0 else 1,
        maxSimultaneousEncounters : 1,
        townsfolk: false,
        
        upkeepTasks : [
          'base:dungeonencounters-roam',
          'base:aggressive',
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,

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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Mimic',
        symbol : '\\',
        speciesID : 'base:mimic',
        professionID : 'base:mimic',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 1,
        maxSimultaneousEncounters : 1,
        townsfolk: false,
        
        upkeepTasks : [
          'base:mimic-place-stairs'
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,

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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Slime Queen',
        symbol : 'O',
        speciesID : 'base:slimequeen',
        professionID : 'base:slimequeen',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 1,
        maxSimultaneousEncounters : 1,
        townsfolk: false,
        
        upkeepTasks : [
          'base:thebeast-roam',
          'base:aggressive',
          'base:slime-queen-make-slimelings',
        ],
        
        friendSpecies : [
          'base:slimeling',
          'base:slimequeen'
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,
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
    id: 'base:cave-bat',
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Cave Bat',
        symbol : 'b',
        speciesID : 'base:cave-bat',
        professionID : 'base:cave-bat',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 2,
        maxSimultaneousEncounters : 2,
        townsfolk: false,
        
        upkeepTasks : [
          'base:thebeast-roam',
          'base:aggressive',
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,
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
      // dud
      when(random.try(percentSuccess:70)) empty
      return Encounter.new(
        name : 'the Snake Siren',
        symbol : 'S',
        speciesID : 'base:snake-siren',
        professionID : 'base:snake-siren',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 1,
        maxSimultaneousEncounters : 1,
        townsfolk: false,
        
        upkeepTasks : [
          'base:thebeast-roam',
          'base:aggressive',
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    },
    kind : KIND.HOSTILE,
    tier : 2,

    events : {
      onStep ::(data, landmark) {
        when(data == empty) empty;
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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Shadowling',
        symbol : '.',
        speciesID : 'base:shadowling',
        professionID : 'base:shadowling',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 2,
        maxSimultaneousEncounters : 2,
        townsfolk: false,
        
        upkeepTasks : [
          'base:thebeast-roam',
          'base:aggressive',
          'base:shadow'
        ],
        
        enterPhrases : [
          'Your mind feels fuzzy.'
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,
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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Mobile Mushroom',
        symbol : 't',
        speciesID : 'base:mobile-mushroom',
        professionID : 'base:mobile-mushroom',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 2,
        maxSimultaneousEncounters : 2,
        townsfolk: false,
        
        upkeepTasks : [
          'base:thebeast-roam',
          'base:aggressive'
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,
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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Giant Flea',
        symbol : 'f',
        speciesID : 'base:giant-flea',
        professionID : 'base:giant-flea',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 2,
        maxSimultaneousEncounters : 2,
        townsfolk: false,
        
        upkeepTasks : [
          'base:dungeonencounters-roam',
          'base:aggressive'
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,
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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Monolith',
        symbol : ']',
        speciesID : 'base:monolith',
        professionID : 'base:monolith',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 1,
        maxSimultaneousEncounters : 1,
        townsfolk: false,
        
        upkeepTasks : [
          'base:thebeast-roam',
          'base:aggressive'
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,
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
    startup ::(parent, x, y) <-
      Encounter.new(
        parent,
        name : 'the Chair',
        symbol : 'n',
        speciesID : 'base:wyvern-specter',
        professionID : 'base:wyvern-specter',
        maxEncounters : if (parent.landmark.floor == 0) 0 else 1,
        maxSimultaneousEncounters : random.integer(from:1, to:1),
        townsfolk: false,
        
        upkeepTasks : [
          'base:aggressive-no-party'
        ],
        
        deathTasks : [
          'base:to-body'
        ]
      )
    ,
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
