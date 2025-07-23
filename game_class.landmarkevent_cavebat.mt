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
  name: 'Wyvern.LandmarkEvent.CaveBat',
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
        speciesHint : 'base:cave-bat',
        professionHint : 'base:cave-bat'
      );
      beast.name = 'Cave Bat';
      beast.supportArts = [];      
      for(0, 20) ::(i) {
        beast.autoLevelProfession(:beast.profession);
      }
      beast.equipAllProfessionArts();  

      beast.stats.load(serialized:StatSet.new(
        HP:   7,
        AP:   15,
        ATK:  6,
        INT:  5,
        DEF:  3,
        LUK:  6,
        SPD:  10,
        DEX:  5
      ).save());
      
      beast.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
      beast.heal(amount:9999, silent:true); 
      beast.healAP(amount:9999, silent:true);   

      
      // who knows whos down here. Can be anything and anyone, regardless of 
      // the inhabitants of the island.
      @ents = [beast]
   
      state.encountersOnFloor += 1;

      @:ref = landmark_.mapEntityController.add(
        x:tileX, 
        y:tileY, 
        symbol:'b',
        entities : ents,
        tag : 'cavebat'
      );
      ref.addUpkeepTask(id:'base:thebeast-roam');
      ref.addUpkeepTask(id:'base:aggressive');
      
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
        @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'cavebat');
      
        // add additional entities out of spawn points (stairs)
        if (state.hasBeast && entities->keycount < 3 && state.encountersOnFloor < ROOM_MAX_ENTITY) ::<= {
          addEntity();
        }
      }
    }
  }
);
return TheBeast;
