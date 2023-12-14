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
            }
        }
    }
);




@:LANDMARKEVENT_BASE_NAME = 'Wyvern.LandmarkEvent.Base';
LandmarkEvent.Base = class(
    name : LANDMARKEVENT_BASE_NAME,
    inherits : [Database.Item],
    new ::(data) {
        @:this = LandmarkEvent.Base.defaultNew();
        this.initialize(data);
        return this;
    },
    statics : {
        database  :::<= {
            @:db = Database.new(
                name: LANDMARKEVENT_BASE_NAME,
                attributes : {
                    name : String,
                    startup : Function,
                    step : Function
                }
            );
            
            return {
                get ::<- db 
            }
        }
    },
    define:::(this) {
        LandmarkEvent.Base.database.add(item:this);
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
        }
    }
);

return LandmarkEvent;
