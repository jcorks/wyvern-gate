@:class = import(module:'Matte.Core.Class');
@:random = import(module:'core/random.mt');
@:distance = import(module:'core/distance.mt');
@:windowEvent = import(module:'core/windowevent.mt');
@:Inventory = import(module:'base/item/inventory.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');


@:ROOM_MAX_ENTITY = 3;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;
@:MAX_ENCOUNTERS = 2;


@:DungeonEncounters = LoadableClass.create(
  name: 'Wyvern.LandmarkEvent.CreatureEncounters',
  items : {
    encountersOnFloor : 0,
    isBusy : false,
    maxEncounters : 0
  },

  define:::(this, state) {
    @map_;
    @island_;
    @landmark_;

    @:Entity = import(module:'base/entity.mt');
    @:Location = import(module:'base/map/location.mt');
    
  
  
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
      @ents = [landmark_.island.newHostileCreature()]
   
      state.encountersOnFloor += 1;
      ents[0].unequipAll(silent:true);
      ents[0].heal(amount:9999, silent:true); 
      ents[0].healAP(amount:9999, silent:true);
      @:ref = landmark_.mapEntityController.add(
        x:tileX, 
        y:tileY, 
        symbol:'{',
        entities : ents,
        tag : 'creature'
      );
      ref.addUpkeepTask(id:'base:dungeonencounters-roam');
      ref.addUpkeepTask(id:'base:aggressive');
      ref.addDeathTask(id:'base:to-body');

    }
    

  
    this.interface = {
      initialize::(parent) {
        @landmark = parent.landmark;

        map_ = landmark.map;
        island_ = landmark.island;
        landmark_ = landmark;
      },
      
      defaultLoad :: {
     
      },
      
      step::{
        @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'creature');
      
        // add additional entities out of spawn points (stairs)
        if (landmark_.floor > 0 && entities->keycount < 1 && state.encountersOnFloor < ROOM_MAX_ENTITY) ::<= {
          addEntity();
        }
      }
    }
  }
);
return DungeonEncounters;
