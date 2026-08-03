@:class = import(module:'Matte.Core.Class');
@:random = import(module:'core/random.mt');
@:distance = import(module:'core/distance.mt');
@:Species = import(module:'base/entity/species.mt');
@:Profession = import(module:'base/entity/profession.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');

@:ROOM_MAX_ENTITY = 1;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;


@:TheBeast = LoadableClass.create(
  name: 'Wyvern.LandmarkEvent.Monolith',
  items : {
    encountersOnFloor : 0,
    hasBeast : false
  },
  define:::(this, state) {
    @map_;
    @island_;
    @landmark_;

    @:Entity = import(module:'base/entity.mt');
    @:Location = import(module:'base/map/location.mt');

  
  
    @:addEntity ::{
      @:windowEvent = import(module:'core/windowevent.mt');

      @ar = map_.getRandomArea();;
      @:tileX = ar.x + (ar.width /2)->floor;
      @:tileY = ar.y + (ar.height/2)->floor;
      
      // only add an entity when not visible. Makes it 
      // feel more alive and unknown
      when (map_.isLocationVisible(x:tileX, y:tileY)) empty;
      


      @:beast = island_.newInhabitant(
        speciesHint : 'base:monolith',
        professionHint : 'base:monolith'
      );
      beast.name = 'the Monolith';
      beast.supportArts = [];      
      for(0, 20) ::(i) {
        beast.autoLevelProfession(:beast.profession);
      }
      beast.equipAllProfessionArts();  
      
      beast.unequipAll(silent:true);
      beast.heal(amount:9999, silent:true); 
      beast.healAP(amount:9999, silent:true);   

      
      // who knows whos down here. Can be anything and anyone, regardless of 
      // the inhabitants of the island.
      @ents = [beast]
   
      state.encountersOnFloor += 1;

      @:ref = landmark_.mapEntityController.add(
        x:tileX, 
        y:tileY, 
        symbol:']',
        entities : ents,
        tag : 'monolith'
      );
      ref.addUpkeepTask(id:'base:aggressive');
      ref.addUpkeepTask(id:'base:dungeonencounters-roam');
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
        state.hasBeast = if (landmark_.floor > 1)
          true
        else 
          false
        ;      
      },
      
      step::{
        @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'monolith');
      
        // add additional entities out of spawn points (stairs)
        if (state.hasBeast && entities->keycount < 2 && state.encountersOnFloor < ROOM_MAX_ENTITY) ::<= {
          addEntity();
        }
      }
    }
  }
);
return TheBeast;
