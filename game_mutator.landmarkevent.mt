@:Database = import(module:'game_class.database.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');
@:class = import(module:'Matte.Core.Class');
@:databaseItemMutatorClass = import(module:'game_function.databaseitemmutatorclass.mt');








@:reset ::{
LandmarkEvent.database.newEntry(
    data : {
        name: 'item-specter',
        startup ::(landmark) {
            @:ItemSpecter = import(module:'game_class.landmarkevent_itemspecter.mt');
            @:a = ItemSpecter.new();
            a.initialize(landmark);
            return a;
        },

        
        step ::(data, landmark) {
            data.step();
        },
        
        isActive ::(data) {
            return data.isActive()
        }
    }
);

LandmarkEvent.database.newEntry(
    data : {
        name: 'dungeon-encounters',
        startup ::(landmark) {
            @:DungeonEncounters = import(module:'game_class.landmarkevent_dungeonencounters.mt');
            // TODO: make dungeon encounters loadable
            @:a = DungeonEncounters.new();   
            a.initialize(landmark);
            return a;
        },
        
        step ::(data, landmark) {
            data.step();
        },
        
        isActive ::(data) {
            return data.isActive()
        }
    }
);

LandmarkEvent.database.newEntry(
    data : {
        name: 'the-beast',
        startup ::(landmark) {
            @:b = import(module:'game_class.landmarkevent_thebeast.mt');
            @:a = b.new();
            a.initialize(landmark);
            return a;
        },

        
        step ::(data, landmark) {
            data.step();
        },
        
        isActive ::(data) {
            return data.isActive()
        }
    }
);

LandmarkEvent.database.newEntry(
    data : {
        name: 'the-mirror',
        startup ::(landmark) {
            @:b = import(module:'game_class.landmarkevent_themirror.mt');
            @:a = b.new();
            a.initialize(landmark);
            return a;
        },

        
        step ::(data, landmark) {
            data.step();
        },
        
        isActive ::(data) {
            return data.isActive()
        }
    }
);


LandmarkEvent.database.newEntry(
    data : {
        name: 'treasure-golem',
        startup ::(landmark) {
            @:b = import(module:'game_class.landmarkevent_treasuregolem.mt');
            @:a = b.new();
            a.initialize(landmark);
            return a;
        },

        
        step ::(data, landmark) {
            data.step();
        },
        
        isActive ::(data) {
            return data.isActive()
        }
    }
);


LandmarkEvent.database.newEntry(
    data : {
        name: 'cave-bat',
        startup ::(landmark) {
            @:b = import(module:'game_class.landmarkevent_cavebat.mt');
            @:a = b.new();
            a.initialize(landmark);
            return a;
        },

        
        step ::(data, landmark) {
            data.step();
        },
        
        isActive ::(data) {
            return data.isActive()
        }
    }
);
}

// essentially an opaque wrapper for custom per-step 
// controllers of landmarks.
@:LandmarkEvent = databaseItemMutatorClass(
    name : 'Wyvern.LandmarkEvent',
    items : {
        data : empty // maintained    
    },
    
    database : Database.new(
        name:'Wyvern.LandmarkEvent.Base',
        attributes : {
            name : String,
            startup : Function,
            step : Function,
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
                state.data = base.startup(landmark:landmark_);
            },
            
            step::{
                state.base.step(
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
