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
  name: 'Wyvern.LandmarkEvent.Slime',
  items : {
    encountersOnFloor : 0,
    hasBeast : false,
    steps : 0
  },
  
  define:::(this, state) {
    @map_;
    @island_;
    @landmark_;

    @:Entity = import(module:'base/entity.mt');
    @:Location = import(module:'base/map/location.mt');

  
    @:addSlimeling ::(mapEntity) {
      when (mapEntity == empty) empty;
      @:pos = mapEntity.position;

      @:windowEvent = import(module:'core/windowevent.mt');


      @:beast = island_.newInhabitant(
        professionHint : 'base:slimeling',
        speciesHint : 'base:slimeling'
      );
      beast.name = 'the Slimeling';
      beast.supportArts = [];      

      
      beast.unequipAll(silent:true);
      beast.heal(amount:9999, silent:true); 
      beast.healAP(amount:9999, silent:true);   

      @ents = [beast]
   

      @:ref = landmark_.mapEntityController.add(
        x:pos.x, 
        y:pos.y, 
        symbol:'o',
        entities : ents,
        tag : 'slimeling'
      );
      ref.addUpkeepTask(id:'base:thebeast-roam');
      ref.addUpkeepTask(id:'base:aggressive');
      ref.addDeathTask(id:'base:to-poison');
      
      ref.addFriendSpecies(:'base:slimeling')
      ref.addFriendSpecies(:'base:slimequeen')
      
    }
  
  
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
        professionHint : 'base:slimequeen',
        speciesHint : 'base:slimequeen'
      );
      beast.name = 'the Slime Queen';
      beast.supportArts = [];      
      for(0, 20) ::(i) {
        beast.autoLevelProfession(:beast.profession);
      }
      beast.equipAllProfessionArts();  



      
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
        symbol:'O',
        entities : ents,
        tag : 'slimequeen'
      );
      ref.addUpkeepTask(id:'base:thebeast-roam');
      ref.addUpkeepTask(id:'base:aggressive');
      ref.addFriendSpecies(:'base:slimeling')
      ref.addFriendSpecies(:'base:slimequeen')
      ref.addDeathTask(id:'base:to-poison');
      return ref;
    }
    

  
    this.interface = {
      initialize::(parent) {
        @landmark = parent.landmark;
        map_ = landmark.map;
        island_ = landmark.island;
        landmark_ = landmark;
      },
      
      defaultLoad::{
        state.hasBeast = if (landmark_.floor > 0)
          true
        else 
          false
        ;
      },
      
      step::{
        @entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'slimequeen');
      
        // add additional entities out of spawn points (stairs)
        //if ((entities->keycount < (if (landmark_.floor == 0) 0 else (2+(landmark_.floor/4)->ceil))) && landmark_.base.peaceful == false && random.number() < 0.1 / (encountersOnFloor*(10 / (island_.tier+1))+1)) ::<= {
        if (entities->keycount < 1 && state.hasBeast && state.encountersOnFloor == 0) ::<= {
          addSlimeling(:addEntity());
        } else if (entities->keycount > 0) ::<= {
          state.steps += 1;
          if ((state.steps % 300) == 0) 
            addSlimeling(:entities[0]);
          
        }
      }
    }
  }
);
return TheBeast;
