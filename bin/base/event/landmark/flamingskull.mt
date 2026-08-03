@:class = import(module:'Matte.Core.Class');
@:random = import(module:'core/random.mt');
@:distance = import(module:'core/distance.mt');
@:Species = import(module:'base/entity/species.mt');
@:Profession = import(module:'base/entity/profession.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');

@:ROOM_MAX_ENTITY = 6;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;




@:TheBeast = LoadableClass.create(
  name: 'Wyvern.LandmarkEvent.FlamingSkull',
  
  statics : {
    createEntity ::{
      @:Entity = import(module:'base/entity.mt');
      @world = import(module:'base/world.mt');
      @:beast = world.island.newInhabitant(
        speciesHint : 'base:flaming-skull',
        professionHint : 'base:flaming-skull'
      );
      beast.name = 'the Flaming Skull';
      beast.supportArts = [];      
      for(0, 20) ::(i) {
        beast.autoLevelProfession(:beast.profession);
      }
      beast.equipAllProfessionArts();  

      beast.stats.load(serialized:StatSet.new(
        HP:   30,
        AP:   999,
        ATK:  14,
        INT:  30,
        DEF:  3,
        LUK:  6,
        SPD:  100,
        DEX:  20
      ).add(:beast.stats).save());
      
      beast.unequipAll(silent:true);
      beast.heal(amount:9999, silent:true); 
      beast.healAP(amount:9999, silent:true);   
      return beast;    
    }
  },
  
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
      

      @beast = TheBeast.createEntity();

      
      // who knows whos down here. Can be anything and anyone, regardless of 
      // the inhabitants of the island.
      @ents = [beast]
   
      state.encountersOnFloor += 1;

      @:ref = landmark_.mapEntityController.add(
        x:tileX, 
        y:tileY, 
        symbol:'@',
        entities : ents,
        tag : 'theflamingskull'
      );
      ref.data.emitter = import(:'core/graphics/particle.mt').new(
        directionMin : -110,
        directionMax : -80,

        directionDeltaMin : -1,
        directionDeltaMax : 2,
    
        speedMin : 0.3,
        speedMax : 1,
        
        speedDeltaMin : 0.03,
        speedDeltaMax : 0.05,

        characters : ['▓', '▓', '▒', '░', '▒', '░', '░'],
        charactersRepeat : false,
        
        lifeMax : 4,
        lifeMin : 1    
      );
      ref.addUpkeepTask(id:'base:thebeast-roam');
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
        state.hasBeast = if (landmark_.floor > 1)
          true
        else 
          false
        ;
      
      },
      
      
      
      step::{
        @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'theflamingskull');
        
        foreach(entities) ::(k, v) {
          @mapPos = v.position;
          @:pos = landmark_.map.mapCoordinatesToScreen(*mapPos);
          v.data.emitter.move(x:pos.x, y:pos.y);
          v.data.emitter.start(emitCount:1);
          v.data.emitter.stop();
        }
      
        // add additional entities out of spawn points (stairs)
        //if ((entities->keycount < (if (landmark_.floor == 0) 0 else (2+(landmark_.floor/4)->ceil))) && landmark_.base.peaceful == false && random.number() < 0.1 / (encountersOnFloor*(10 / (island_.tier+1))+1)) ::<= {
        if (entities->keycount < 3 && state.hasBeast) ::<= {
          addEntity();
          state.hasBeast = false;
        }
      }
    }
  }
);
return TheBeast;
