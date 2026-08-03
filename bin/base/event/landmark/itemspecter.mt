@:class = import(module:'Matte.Core.Class');
@:random = import(module:'core/random.mt');
@:distance = import(module:'core/distance.mt');
@:windowEvent = import(module:'core/windowevent.mt');
@:Species = import(module:'base/entity/species.mt');
@:Profession = import(module:'base/entity/profession.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:Battle = import(module:'base/battle.mt');
@:Inventory = import(module:'base/item/inventory.mt');
@:Item = import(module:'base/item.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');

@:ROOM_SPECTER_COUNT = 3;
@:ItemSpecter = LoadableClass.create(
  name : 'Wyvern.LandmarkEvent.ItemSpecter',
  items : {
    addedSpecters : false
  },
  
  statics : {
    createEntity ::{
      @:Entity = import(module:'base/entity.mt');
      @world = import(module:'base/world.mt');


      @:specter = world.island.newInhabitant(
        speciesHint : 'base:wyvern-specter',
        professionHint : 'base:wyvern-specter'
      );
      specter.name = 'the Wyvern Specter';
      specter.supportArts = [];      
      for(0, 20) ::(i) {
        specter.autoLevelProfession(:specter.profession);
      }
      specter.equipAllProfessionArts();  

      @:inv = Inventory.new();
      inv.add(item:Item.new(base:Item.database.find(id:'base:life-crystal'
      )));      
      specter.forceDrop = inv;

      
      specter.unequipAll(silent:true);
      specter.heal(amount:9999, silent:true); 
      specter.healAP(amount:9999, silent:true);   
      return specter;
    }
  },
  define::(this, state) {
    @:Entity = import(module:'base/entity.mt');
    @:Location = import(module:'base/map/location.mt');

    @map_;
    @island_;
    @landmark_;
    
    
    @:addSpecter ::{
      @:windowEvent = import(module:'core/windowevent.mt');
      @ar = map_.getRandomArea();;
      @:tileX = ar.x + (ar.width /2)->floor;
      @:tileY = ar.y + (ar.height/2)->floor;
      
      // only add an entity when not visible. Makes it 
      // feel more alive and unknown
      when (map_.isLocationVisible(x:tileX, y:tileY)) empty;
      



      @:specter = ItemSpecter.createEntity();



      @ent = landmark_.mapEntityController.add(
        x:tileX,
        y:tileY,
        symbol: 'x',
        entities : [specter],
        tag : 'specter'
      );
      ent.addUpkeepTask(id:'base:specter');
      
      @ent = {
        targetX:tileX, 
        targetY:tileY
      }
      if (state.addedSpecters == false)
        windowEvent.queueMessage(
          text:random.pickArrayItem(list:[
            'Something\'s off... It\'s not safe here.',
            'Do you feel that? Something... different... is here.',
          ])
        );
      state.addedSpecters = true;
        
    }    


    this.interface = {
      initialize::(parent) {
        @landmark = parent.landmark;
        map_ = landmark.map;
        island_ = landmark.island;
        landmark_ = landmark;
      },
      
      defaultLoad ::{
        state.addedSpecters = false;
      },
      
      step::{ 
        @:specters = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'specter');
        
        // the specters have been appeased. They leave now
        when(state.addedSpecters == true && specters->size == 0) empty;
        when(landmark_.floor < 1 || (landmark_.floor%3 != 0)) empty;

      
        if (specters->size < ROOM_SPECTER_COUNT)
          addSpecter();
      
      }
    }    
  }   
);

return ItemSpecter;
