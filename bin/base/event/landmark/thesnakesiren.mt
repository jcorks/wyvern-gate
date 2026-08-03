@:class = import(module:'Matte.Core.Class');
@:random = import(module:'core/random.mt');
@:distance = import(module:'core/distance.mt');
@:Species = import(module:'base/entity/species.mt');
@:Profession = import(module:'base/entity/profession.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');





@:TheSnakeSiren = LoadableClass.create(
  name: 'Wyvern.LandmarkEvent.TheSnakeSiren',
  items : {
    encountersOnFloor : 0,
    hasBeast : false
  },
  statics : {
    createEntity ::{
      @:Entity = import(module:'base/entity.mt');
      @world = import(module:'base/world.mt');
      @:beast = world.island.newInhabitant(
        speciesHint : 'base:beast',
        professionHint : 'base:snake-siren'
      );
      beast.name = 'the Snake Siren';
      beast.supportArts = [];      
      for(0, 20) ::(i) {
        beast.autoLevelProfession(:beast.profession);
      }
      beast.equipAllProfessionArts();  

      beast.stats.load(serialized:StatSet.new(
        HP:   140,
        AP:   999,
        ATK:  14,
        INT:  30,
        DEF:  10,
        LUK:  6,
        SPD:  100,
        DEX:  7
      ).add(:beast.stats).save());
      
      beast.unequipAll(silent:true);
      beast.heal(amount:9999, silent:true); 
      beast.healAP(amount:9999, silent:true);
      beast.aiAbilityChance = 75;
      return beast;    
    }
  },

  define:::(this, state) {
    @map_;
    @island_;
    @landmark_;
    @encountersOnFloor = 0;
    @hasBeast = false;

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
      

      @beast = TheSnakeSiren.createEntity();
      state.hasBeast = false;

      
      // who knows whos down here. Can be anything and anyone, regardless of 
      // the inhabitants of the island.
      @ents = [beast]
   
      encountersOnFloor += 1;

      @:ref = landmark_.mapEntityController.add(
        x:tileX, 
        y:tileY, 
        symbol:'S',
        entities : ents,
        tag : 'thesnakesiren'
      );
      ref.addUpkeepTask(id:'base:thesnakesiren-roam');
      ref.addUpkeepTask(id:'base:thesnakesiren-song');
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
      
      defaultLoad ::{
        state.hasBeast = if (landmark_.floor > 0 && random.try(percentSuccess:10)) true else false;      
      },
      
      step::{
        @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'thesnakesiren');
        if (random.try(percentSuccess:30) == true && state.hasBeast) ::<= {
          addEntity();
        }
      }
    }
  }
);
return TheSnakeSiren;
