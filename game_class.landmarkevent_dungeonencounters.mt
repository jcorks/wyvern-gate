@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');

@:ROOM_MAX_ENTITY = 6;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;


@:DungeonEncounters = class(
    name: 'Wyvern.LandmarkEvent.DungeonEncounters',

    define:::(this) {
        @map_;
        @island_;
        @landmark_;
        @encountersOnFloor = 0;
        @isBusy = false;

        @:Entity = import(module:'game_class.entity.mt');
        @:Location = import(module:'game_class.location.mt');
        
    
    
        @:addEntity ::{
            @:windowEvent = import(module:'game_singleton.windowevent.mt');

            @ar = map_.getRandomArea();;
            @:tileX = ar.x + (ar.width /2)->floor;
            @:tileY = ar.y + (ar.height/2)->floor;
            
            // only add an entity when not visible. Makes it 
            // feel more alive and unknown
            when (map_.isLocationVisible(x:tileX, y:tileY)) empty;
            
            
            // who knows whos down here. Can be anything and anyone, regardless of 
            // the inhabitants of the island.
            @ents = [landmark_.island.newInhabitant()]
   
            encountersOnFloor += 1;
            
            

            ::<={
                @:Item = import(module:'game_class.item.mt');

                if (island_.tier > 0)
                    ents->push(value:landmark_.island.newInhabitant());

                if (island_.tier > 2)
                    ents->push(value:landmark_.island.newInhabitant());



                foreach(ents) ::(index, ref) {

                    ref.inventory.clear();
                    @:itembase = Item.Base.database.getRandomWeightedFiltered(
                        filter:::(value) <- value.isUnique == false && value.tier <= island_.tier                    
                    );
                    if (itembase.name != 'None') ::<={
                        @:itemInstance = Item.new(base:itembase, from:ref, rngEnchantHint:true);
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
            ref.addUpkeepTask(name:'dungeonencounters-roam');
            ref.addUpkeepTask(name:'aggressive');
            
            if (encountersOnFloor == 1)
                windowEvent.queueMessage(
                    text:random.pickArrayItem(list:[
                        'Are those foosteps? Be careful.',
                        'Hmm. Footsteps nearby.',
                        'What? Footsteps?'
                    ])
                );
        }
        

    
        this.interface = {
            initialize::(landmark) {
                map_ = landmark.map;
                island_ = landmark.island;
                landmark_ = landmark;
                isBusy = if (landmark_.floor == 0) false else random.try(percentSuccess:10);
                return this;
            },
            
            step::{
                @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'dungeonencounter');
            
            
                // add additional entities out of spawn points (stairs)
                @recCount = if (isBusy) 
                    5
                else 
                    (if (landmark_.floor == 0) 
                        0 
                    else 
                        (2+(landmark_.floor/4)->ceil)
                    )
                ;                                    

                if (entities->keycount < recCount && 
                    landmark_.base.peaceful == false && 
                        (   
                            isBusy 
                                || 
                            (Number.random() < 0.1 / (encountersOnFloor*(10 / (island_.tier+1))+1))
                        )
                    ) ::<= {
                    addEntity();
                }
            }
        }
    }
);
return DungeonEncounters;
