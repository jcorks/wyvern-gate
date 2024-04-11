@:Database = import(module:'game_class.database.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');
@:class = import(module:'Matte.Core.Class');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');








@:reset ::{
LandmarkEvent.database.newEntry(
    data : {
        id: 'base:item-specter',
        startup ::(parent) {
            @:ItemSpecter = import(module:'game_class.landmarkevent_itemspecter.mt');
            @:a = ItemSpecter.new(parent);
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
        id: 'base:dungeon-encounters',
        startup ::(parent) {
            @:DungeonEncounters = import(module:'game_class.landmarkevent_dungeonencounters.mt');
            // TODO: make dungeon encounters loadable
            @:a = DungeonEncounters.new(parent);   
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
        id: 'base:the-beast',
        startup ::(parent) {
            @:b = import(module:'game_class.landmarkevent_thebeast.mt');
            @:a = b.new(parent);
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
        id: 'base:the-mirror',
        startup ::(parent) {
            @:b = import(module:'game_class.landmarkevent_themirror.mt');
            @:a = b.new(parent);
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
        id: 'base:treasure-golem',
        startup ::(parent) {
            @:b = import(module:'game_class.landmarkevent_treasuregolem.mt');
            @:a = b.new(parent);
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
        id: 'base:cave-bat',
        startup ::(parent) {
            @:b = import(module:'game_class.landmarkevent_cavebat.mt');
            @:a = b.new(parent);
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
        id: 'base:the-snakesiren',
        startup ::(parent) {
            @:b = import(module:'game_class.landmarkevent_thesnakesiren.mt');
            @:a = b.new(parent);
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
                state.data = base.startup(parent:this);
            },
            
            landmark : {
                get ::<- landmark_
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
