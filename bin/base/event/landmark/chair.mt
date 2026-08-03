@:class = import(module:'Matte.Core.Class');
@:random = import(module:'core/random.mt');
@:distance = import(module:'core/distance.mt');
@:Species = import(module:'base/entity/species.mt');
@:Profession = import(module:'base/entity/profession.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:Inventory = import(module:'base/item/inventory.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');

@:ROOM_MAX_ENTITY = 6;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;


@:TheBeast = LoadableClass.create(
  name: 'Wyvern.LandmarkEvent.Chair',
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
      
      state.hasBeast = false;


      @:beast = island_.newInhabitant(
        professionHint : 'base:wyvern-specter',
        speciesHint : 'base:wyvern-specter'
      );
      beast.name = 'the Chair';
      beast.supportArts = [];      
      for(0, 20) ::(i) {
        beast.autoLevelProfession(:beast.profession);
      }
      beast.equipAllProfessionArts();  



      @:inv = Inventory.new();
      inv.addGold(amount:900 + (random.number()*200)->floor);
      beast.forceDrop = inv;

      beast.stats.load(serialized:StatSet.new(
        HP:   60,
        AP:   20,
        ATK:  24,
        INT:  5,
        DEF:  20,
        LUK:  6,
        SPD:  1,
        DEX:  1
      ).add(:beast.stats).save());
      
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
        symbol:'n',
        entities : ents,
        tag : 'chair',
        location : Location.new(
          base : Location.database.find(:'base:chair'),
          landmark: landmark_
        )
      );
      ref.addUpkeepTask(id:'base:aggressive-no-party');
      ref.addDeathTask(id:'base:to-body');
      //ref.addUpkeepTask(id:'base:teleport-offscreen');
      
    }
    

  
    this.interface = {
      initialize::(parent) {
        @landmark = parent.landmark;
        map_ = landmark.map;
        island_ = landmark.island;
        landmark_ = landmark;
      },
      
      defaultLoad::{
        state.hasBeast =
          true
      },
      
      step::{
        @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'treasuregolem');
      
        // add additional entities out of spawn points (stairs)
        //if ((entities->keycount < (if (landmark_.floor == 0) 0 else (2+(landmark_.floor/4)->ceil))) && landmark_.base.peaceful == false && random.number() < 0.1 / (encountersOnFloor*(10 / (island_.tier+1))+1)) ::<= {
        if (entities->keycount < 1 && state.hasBeast) ::<= {
          addEntity();
        }
      }
    }
  }
);
return TheBeast;
