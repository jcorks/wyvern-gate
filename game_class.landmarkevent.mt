@:Database = import(module:'game_class.database.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');
@:class = import(module:'Matte.Core.Class');


// essentially an opaque wrapper for custom per-step 
// controllers of landmarks.
@:LandmarkEvent = LoadableClass.new(
    name : 'Wyvern.LandmarkEvent',
    statics : {
        Base  :::<= {
            @db;
            return {
                get ::<- db,
                set ::(value) <- db = value
            }
        },    
    },
    new ::(parent, base, state) {
        @:this = LandmarkEvent.defaultNew();
        
        this.initialize(landmark:parent);
        
        if (state != empty)
            this.load(serialized:state)
        else 
            this.defaultLoad(base)
        return this;
    },
    
    define::(this) {
        
        @landmark_;
        @state = State.new(
            items : {
                base : empty,
                data : empty // maintained
            }
        );
        this.interface = {
            initialize ::(landmark) {
                landmark_ = landmark;
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




LandmarkEvent.Base = Database.newBase(
    name:'Wyvern.LandmarkEvent.Base',
    attributes : {
        name : String,
        startup : Function,
        step : Function,
        isActive : Function
    }
);



LandmarkEvent.Base.new(
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

LandmarkEvent.Base.new(
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

LandmarkEvent.Base.new(
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

LandmarkEvent.Base.new(
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


LandmarkEvent.Base.new(
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


LandmarkEvent.Base.new(
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

return LandmarkEvent;
