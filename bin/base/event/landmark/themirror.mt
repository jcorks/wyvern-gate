@:class = import(module:'Matte.Core.Class');
@:random = import(module:'core/random.mt');
@:distance = import(module:'core/distance.mt');
@:Species = import(module:'base/entity/species.mt');
@:Profession = import(module:'base/entity/profession.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:Inventory = import(module:'base/item/inventory.mt');
@:Item = import(module:'base/item.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');

@:ROOM_MAX_ENTITY = 6;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;


@:TheBeast = LoadableClass.create(
  name: 'Wyvern.LandmarkEvent.TheMirror',
  items : {
    hasBeast : false,
    encountersOnFloor : 0
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
      

      @:world = import(module:'base/world.mt');
      @:partyCopy = [];
      
      
      foreach(world.party.members) ::(i, member) {
        @:a = member.save();
        a.stats.SPD -= 1;
        a.name = a.name + ' (clone)';

        @:ent = Entity.new(
          parent:this,
          state: a
        );
        
        ent.heal(amount:ent.stats.HP, silent:true);


        partyCopy->push(value:ent)        
      }  
      
      @:inv = Inventory.new();
      inv.add(item:Item.new(base:Item.database.find(id:'base:life-crystal'
      )));            
      partyCopy[0].forceDrop = inv;

      
   
      state.encountersOnFloor += 1;

      @:ref = landmark_.mapEntityController.add(
        x:tileX, 
        y:tileY, 
        symbol:'Ø',
        entities : partyCopy,
        tag : 'themirror'
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
      
      defaultLoad :: {
        state.hasBeast = if (landmark_.floor > 1 && random.try(percentSuccess:50))
          true
        else 
          false
        ;
      },
      
      step::{
        @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'themirror');
      
        // add additional entities out of spawn points (stairs)
        //if ((entities->keycount < (if (landmark_.floor == 0) 0 else (2+(landmark_.floor/4)->ceil))) && landmark_.base.peaceful == false && random.number() < 0.1 / (encountersOnFloor*(10 / (island_.tier+1))+1)) ::<= {
        if (entities->keycount < 1 && state.hasBeast) ::<= {
          addEntity();
          state.hasBeast = false;
        }
      }
    }
  }
);
return TheBeast;
