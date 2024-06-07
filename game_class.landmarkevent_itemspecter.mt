@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Species = import(module:'game_database.species.mt');
@:Profession = import(module:'game_database.profession.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:Battle = import(module:'game_class.battle.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:Item = import(module:'game_mutator.item.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

@:ROOM_SPECTER_COUNT = 3;
@:ItemSpecter = LoadableClass.create(
  name : 'Wyvern.LandmarkEvent.ItemSpecter',
  items : {
    addedSpecters : false
  },
  
  statics : {
    createEntity ::{
      @:Entity = import(module:'game_class.entity.mt');
      @world = import(module:'game_singleton.world.mt');


      @:specter = world.island.newInhabitant();
      specter.name = 'the Wyvern Specter';
      specter.species = Species.find(id:'base:wyvern-specter');
      specter.profession = Profession.find(id:'base:wyvern-specter');         
      specter.supportArts = [];      

      @:inv = Inventory.new();
      inv.add(item:Item.new(base:Item.database.find(id:'base:life-crystal'
      )));      
      specter.forceDrop = inv;

      specter.stats.load(serialized:StatSet.new(
        HP:   120,
        AP:   999,
        ATK:  25,
        INT:  30,
        DEF:  3,
        LUK:  6,
        SPD:  100,
        DEX:  10
      ).save());
      
      specter.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
      specter.heal(amount:9999, silent:true); 
      specter.healAP(amount:9999, silent:true);   
      return specter;
    }
  },
  define::(this, state) {
    @:Entity = import(module:'game_class.entity.mt');
    @:Location = import(module:'game_mutator.location.mt');

    @map_;
    @island_;
    @landmark_;
    
    
    @:addSpecter ::{
      @:windowEvent = import(module:'game_singleton.windowevent.mt');
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
