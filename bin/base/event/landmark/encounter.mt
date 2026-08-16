@:class = import(module:'Matte.Core.Class');
@:random = import(module:'core/random.mt');
@:distance = import(module:'core/distance.mt');
@:Species = import(module:'base/entity/species.mt');
@:Profession = import(module:'base/entity/profession.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:Entity = import(module:'base/entity.mt');
@:Location = import(module:'base/map/location.mt');
@:Inventory = import(module:'base/item/inventory.mt');


@:ROOM_MAX_ENTITY = 5;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;

@:generateID = ::<= {
  @:hex = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g'];
  return ::{
    @:ids = []
    for(0, 25) ::(i) {
      ids->push(:random.pickArrayItem(:hex))
    }
    return String.combine(:ids);
  }
}

@:TheBeast = LoadableClass.create(
  name: 'Wyvern.LandmarkEvent.Encounter',
  items : {
    encountersOnFloor : 0,
    maxEncounters : 0,
    maxSimultaneousEncounters : 0,
    upkeepTasks : empty,
    deathTasks : empty,
    membersPerTeam : 0,
    professionID : '',
    speciesID : '',
    name : '',
    symbol : '',
    enterPhrases : empty,
    id : '',
    forceDrop : empty,
    forceTeam : empty,
    friendSpecies : empty,
    teamArchetype : empty,
    townsfolk : false
  },
  define:::(this, state) {
    @map_;
    @island_;
    @landmark_;


  
    @:addEntity ::{
      @:windowEvent = import(module:'core/windowevent.mt');

      @ar = map_.getRandomArea();;
      @:tileX = ar.x + (ar.width /2)->floor;
      @:tileY = ar.y + (ar.height/2)->floor;
      
      // only add an entity when not visible. Makes it 
      // feel more alive and unknown
      when (map_.isLocationVisible(x:tileX, y:tileY)) empty;
      when (map_.itemsAt(x:tileX, y:tileY) == empty) empty;
      

      @ents;
      if (state.teamArchetype != empty) {
        ents = state.teamArchetype->map(::(value) <- Entity.new(parent:this, state:value.save()));
      } else {
        ents = [];
        for(0, state.membersPerTeam) ::(i) {
          @:beast = island_.newInhabitant(
            speciesHint : if (state.speciesID == '') empty else state.speciesID,
            professionHint : if (state.professionID == '') empty else state.professionID
          );
          
          if (state.name != '')
            beast.name = state.name;

          if (state.townsfolk) {
            beast.anonymize();
          } else {
            beast.supportArts = [];      
            for(0, 20) ::(i) {
              beast.autoLevelProfession(:beast.profession);
            }
            beast.equipAllProfessionArts();  

            
            beast.unequipAll(silent:true);
          }
          beast.heal(amount:9999, silent:true); 
          beast.healAP(amount:9999, silent:true);   
          
          if (state.forceDrop != empty) {
            @:inv = Inventory.new(state:state.forceDrop.save());
            beast.forceDrop = inv;
          }
            
          ents->push(:beast)
        }
      }
      
   
      state.encountersOnFloor += 1;

      @:ref = landmark_.mapEntityController.add(
        x:tileX, 
        y:tileY, 
        symbol:state.symbol,
        entities : ents,
        tag : state.id
      );
      foreach(state.upkeepTasks) ::(k, v) {
        ref.addUpkeepTask(id:v);
      }
      if (state.deathTasks != empty) {
        foreach(state.deathTasks) ::(k, v) {
          ref.addDeathTask(id:v);
        }
      }
      if (state.friendSpecies != empty) {
        foreach(state.friendSpecies) ::(k, v) {
          ref.addFriendSpecies(id:v)
        }
      }
      
      if (state.encountersOnFloor == 1) {
        if (state.enterPhrases != empty) {
          windowEvent.queueMessage(
            text: random.pickArrayItem( 
              list : state.enterPhrases
            )
          );
        }
      }      
    }
    

  
    this.interface = {
      defaultLoad ::(
        maxEncounters => Number,
        
        // Optional max simultaneous. Defaults to 1
        maxSimultaneousEncounters,
        
        
        // An array of upkeep tasks. Must be present, though the array 
        // can be empty. This is required because it defined the entity's 
        // behavior.
        upkeepTasks => Object,
        
        // Optional array of tasks upon death.
        deathTasks,
        
        // How many members shoudl be generated per unit when in battle.
        membersPerTeam, // defaults to 1, but can specify multiple for larger parties. More than 2 is typically too much
        
        // if not specified, uses the default "basic" entity using newInhabitant
        professionID,
        speciesID,

        // override display name
        name,
        
        // The symbol to represent it on the map
        symbol => String,
        
        // optional: on first spawn of an entity, queueMessages this
        enterPhrases,
        
        
        // If present, should be an array of item IDs
        forceDrop,
        
        // whether this roaming entity is "just some person".
        // If true, the entities created will use the defaults of 
        // newInhabitant (including tier-specific equipment and arts)
        // If false, all equips are removed and the entity(s) are 
        // given all of their profession abilities
        townsfolk,
        
        // Optional array that is used as the "team" to generate 
        // when an encounter happens. The actual entities are cloned 
        // from the archetype. The presence of this ignores:
        // speciesID, professionID, townsfolk, forceDrop, membersPerTeam
        //
        // NOTE: because of save mechanics, ownership of the members is transferred 
        // meaning that this should be the ONLY instance of 
        // array and its members.
        teamArchetype,
        
        // Optional array of friend species. Friend species never fight.
        // See MapEntity.addFriendSpecies()
        friendSpecies

      ) {
        state.maxEncounters = maxEncounters;
        state.maxSimultaneousEncounters = if (maxSimultaneousEncounters == empty) 1 else maxSimultaneousEncounters
        state.upkeepTasks = upkeepTasks;
        state.deathTasks = deathTasks;
        state.membersPerTeam = if (membersPerTeam == empty) 1 else membersPerTeam
        if (professionID != empty) {
          state.professionID = professionID;
          state.speciesID = speciesID;
        }
        if (forceDrop != empty) {
          state.forceDrop = Inventory.new(state:forceDrop.save());
        }
        state.townsfolk = townsfolk;
        
        if (name != empty)
          state.name = name 
        state.symbol = symbol
        state.enterPhrases = enterPhrases
        state.id = generateID();
        state.teamArchetype = teamArchetype
        state.friendSpecies = friendSpecies
      },    
    
      initialize::(
        parent
      ) {
        @landmark = parent.landmark;

        map_ = landmark.map;
        island_ = landmark.island;
        landmark_ = landmark;
      },

      
      step::{
        @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == state.id);
      
        // add additional entities out of spawn points (stairs)
        if (entities->keycount < state.maxSimultaneousEncounters && 
            state.encountersOnFloor < state.maxEncounters
        ) ::<= {
          addEntity();
        }
      }
    }
  }
);
return TheBeast;
