@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');


@:ROOM_MAX_ENTITY = 6;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;
@:MAX_ENCOUNTERS = 30;


@:DungeonEncounters = LoadableClass.create(
    name: 'Wyvern.LandmarkEvent.DungeonEncounters',
    items : {
        encountersOnFloor : 0,
        isBusy : false,
        maxEncounters : 0,
    },

    define:::(this, state) {
        @map_;
        @island_;
        @landmark_;

        @:Entity = import(module:'game_class.entity.mt');
        @:Location = import(module:'game_mutator.location.mt');
        
    
    
        @:addEntity ::{
            when (state.encountersOnFloor > MAX_ENCOUNTERS) empty;

            @ar = map_.getRandomArea();;
            @:tileX = ar.x + (ar.width /2)->floor;
            @:tileY = ar.y + (ar.height/2)->floor;
            
            // only add an entity when not visible. Makes it 
            // feel more alive and unknown
            when (map_.isLocationVisible(x:tileX, y:tileY)) empty;
            
            
            // who knows whos down here. Can be anything and anyone, regardless of 
            // the inhabitants of the island.
            @ents = [landmark_.island.newInhabitant()]
   
            state.encountersOnFloor += 1;
            
            

            ::<={
                @:Item = import(module:'game_mutator.item.mt');

                @:i = random.integer(from:0, to:2);

                if (island_.tier > 0 && i > 0)
                    ents->push(value:landmark_.island.newInhabitant());

                if (island_.tier > 2 && i > 1)
                    ents->push(value:landmark_.island.newInhabitant());



                foreach(ents) ::(index, ref) {

                    ref.inventory.clear();
                    @:itembase = Item.database.getRandomWeightedFiltered(
                        filter:::(value) <- value.isUnique == false && value.tier <= island_.tier                    
                    );
                    if (itembase.id != 'base:none') ::<={
                        @:itemInstance = Item.new(base:itembase, rngEnchantHint:true);
                        ref.inventory.add(item:itemInstance);
                    }
                    ref.anonymize();
                }
            }
            @:ref = landmark_.mapEntityController.add(
                x:tileX, 
                y:tileY, 
                symbol:'*',
                entities : ents,
                tag : 'dungeonencounter'
            );
            ref.addUpkeepTask(id:'base:dungeonencounters-roam');
            ref.addUpkeepTask(id:'base:aggressive');
            ref.addUpkeepTask(id:'base:exit');

            if (state.encountersOnFloor == 1) ::<= {
                windowEvent.queueMessage(
                    text:random.pickArrayItem(list:[
                        'Are those foosteps? Be careful.',
                        'Hmm. Footsteps nearby.',
                        'What? Footsteps?'
                    ])
                );

                if (state.isBusy)
                    windowEvent.queueMessage(
                        text:random.pickArrayItem(list:[
                            'There seems to be a lot of commotion around on this floor...',
                            'What? It sounds like a large battle nearby...'
                        ])
                    );


            }
        }
        

    
        this.interface = {
            initialize::(parent) {
                @landmark = parent.landmark;
                map_ = landmark.map;
                island_ = landmark.island;
                landmark_ = landmark;
            },

            defaultLoad ::{
                state.isBusy = if (landmark_.floor == 0) false else random.try(percentSuccess:10);
                state.maxEncounters = if (state.isBusy) 
                    5
                else 
                    (if (landmark_.floor == 0) 
                        0 
                    else 
                        (2+(landmark_.floor/3)->round)
                    )
                ;
            },
            
            step::{
                @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'dungeonencounter');
            
            
                // add additional entities out of spawn points (stairs)
                @recCount = if (state.isBusy) 
                    5
                else 
                    (1+(landmark_.floor/4)->round)
                ;                                 

                @:world = import(module:'game_singleton.world.mt');
    
                if (!world.battle.isActive &&
                    state.encountersOnFloor < state.maxEncounters && 
                    entities->keycount < recCount && 
                    landmark_.base.peaceful == false && 
                        (   
                            state.isBusy 
                                || 
                            (Number.random() < 0.1 / (state.encountersOnFloor*(10 / (island_.tier+1))+1))
                        )
                    ) ::<= {
                    
                    addEntity();
                }
            }
        }
    }
);
return DungeonEncounters;
