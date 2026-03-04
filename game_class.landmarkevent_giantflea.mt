@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');
@:Species = import(module:'game_database.species.mt');
@:Profession = import(module:'game_database.profession.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

@:ROOM_MAX_ENTITY = 5;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;


@:TheBeast = LoadableClass.create(
  name: 'Wyvern.LandmarkEvent.GiantFlea',
  items : {
    encountersOnFloor : 0,
    hasBeast : false
  },
  define:::(this, state) {
    @map_;
    @island_;
    @landmark_;

    @:Entity = import(module:'game_class.entity.mt');
    @:Location = import(module:'game_mutator.location.mt');

  
  
    @:addEntity ::{
      @:windowEvent = import(module:'game_singleton.windowevent.mt');

      @ar = map_.getRandomArea();;
      @:tileX = ar.x + (ar.width /2)->floor;
      @:tileY = ar.y + (ar.height/2)->floor;
      
      // only add an entity when not visible. Makes it 
      // feel more alive and unknown
      when (map_.isLocationVisible(x:tileX, y:tileY)) empty;
      


      @:beast = island_.newInhabitant(
        speciesHint : 'base:giant-flea',
        professionHint : 'base:giant-flea'
      );
      beast.name = 'the Giant Flea';
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
        symbol:'f',
        entities : ents,
        tag : 'giantflea'
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
        @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'skeleton');
      
        // add additional entities out of spawn points (stairs)
        if (state.hasBeast && entities->keycount < 2 && state.encountersOnFloor < ROOM_MAX_ENTITY) ::<= {
          addEntity();
        }
      }
    }
  }
);
return TheBeast;
