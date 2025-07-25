/*
  Wyvern Gate, a procedural, console-based RPG
  Copyright (C) 2023, Johnathan Corkery (jcorkery@umich.edu)

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
@:class = import(module:'Matte.Core.Class');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:Database = import(module:'game_class.database.mt');
@:State = import(module:'game_class.state.mt');
@:sound = import(module:'game_singleton.sound.mt');


@:StateType = State.create(
  items : {
    x : 0,
    y : 0,
    floorHint : 0,
    base : empty,
    isSparse : true  
  }
);


@:TYPE = {
  DUNGEON : 0,
  STRUCTURE : 1,
  CUSTOM : 2
};

@:TRAIT = {
  UNIQUE : 1,
  PEACEFUL : 2,
  DUNGEON_FORCE_ENTRANCE: 4,
  EPHEMERAL: 8,
  CAN_SAVE : 16,
  POINT_OF_NO_RETURN : 32,
  GUARDED : 64
}


@:reset ::{

@:DungeonMap = import(module:'game_singleton.dungeonmap.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:LandmarkEvent = import(module:'game_mutator.landmarkevent.mt');

Landmark.database.newEntry(
  data: {
    name: 'Town',
    id: 'base:town',
    legendName : 'Town',
    symbol : '#',
    rarity : 100000,
    minLocations : 7,
    maxLocations : 15,
    minEvents : 0,
    maxEvents : 3,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,
    landmarkType : TYPE.STRUCTURE,
    traits : 
      TRAIT.GUARDED |
      TRAIT.CAN_SAVE |
      TRAIT.PEACEFUL,

    requiredEvents : [],
    possibleLocations : [
      {id:'base:home', rarity: 1},
      //{id:'guild', rarity: 25}
    ],
    requiredLocations : [
      'base:shop',
      'base:arts-tecker',
      'base:school',
      'base:tavern',
      'base:blacksmith',
      'base:inn'      
    ],
    mapHint : {
      roomSize: 30,
      roomAreaSize: 7,
      roomAreaSizeLarge: 9,
      emptyAreaCount: 6,
      wallCharacter: '!',
      scatterChar: 'Y',
      scatterRate: 0.3
    },
    onCreate ::(landmark, island){},
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onVisit ::(landmark, island) {
      sound.playBGM(name:'town-2', loop:true);

    }
  }
)

Landmark.database.newEntry(
  data: {
    name: 'City',
    id: 'base:city',
    legendName : 'City',
    symbol : '|',
    rarity : 5,
    minLocations : 12,
    maxLocations : 17,
    traits : 
      TRAIT.PEACEFUL |
      TRAIT.GUARDED |
      TRAIT.CAN_SAVE,
    minEvents : 2,
    maxEvents : 6,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    landmarkType : TYPE.STRUCTURE,
    requiredEvents : [],
    possibleLocations : [
      {id:'base:home', rarity: 1},
      //{id:'inn', rarity: 3},
      //{id:'guild', rarity: 25}
      //{id:'tavern', rarity: 100}
      //{id:'school', rarity: 7}
    ],
    requiredLocations : [
      'base:shop',
      'base:shop',
      'base:shop',
      'base:auction-house',
      'base:arts-tecker',
      'base:tavern',
      'base:arena',
      'base:inn',
      'base:school',
      'base:school',
      'base:blacksmith'      
    ],
    mapHint : {
      roomSize: 30,
      roomAreaSize: 5,
      roomAreaSizeLarge: 7,
      emptyAreaCount: 18,
      wallCharacter : '|'
    },
    onCreate ::(landmark, island){},
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onVisit ::(landmark, island) {
      sound.playBGM(name:'town-2', loop:true);
    }
    
  }
)


Landmark.database.newEntry(
  data: {
    name: 'Mine',
    id: 'base:mine',
    legendName: 'Mine',
    symbol : 'O',
    rarity : 5,
    minLocations : 10,
    maxLocations : 15,
    minEvents : 0,
    maxEvents : 0,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    traits : 
      TRAIT.PEACEFUL |
      TRAIT.CAN_SAVE |
      TRAIT.DUNGEON_FORCE_ENTRANCE,

    landmarkType : TYPE.DUNGEON,
    requiredEvents : [],
    possibleLocations : [
      {id:'base:ore-vein', rarity: 1},
      //{id:'inn', rarity: 3},
      //{id:'guild', rarity: 25}
      //{id:'tavern', rarity: 100}
      //{id:'school', rarity: 7}
    ],
    requiredLocations : [
      'base:ore-vein',
      'base:smelter',
    ],
    mapHint : {
      roomSize: 15,
      roomAreaSize: 5,
      roomAreaSizeLarge: 10,
      emptyAreaCount: 15
    },
    onCreate ::(landmark, island){},
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onVisit ::(landmark, island) {}
    
  }
)


Landmark.database.newEntry(
  data: {
    name: 'Wyvern Gate',
    id: 'base:wyvern-gate',
    legendName: 'Gate',
    symbol : '@',
    rarity : 10,
    minLocations : 4,
    maxLocations : 10,
    minEvents : 0,
    maxEvents : 0,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    traits : 
      TRAIT.UNIQUE |
      TRAIT.PEACEFUL |
      TRAIT.CAN_SAVE |
      TRAIT.DUNGEON_FORCE_ENTRANCE,

    landmarkType : TYPE.DUNGEON,
    requiredEvents : [],
    possibleLocations : [

    ],
    requiredLocations : [
      'base:gate'
    ],
    
    mapHint : {
      roomSize: 25,
      wallCharacter: 'Y',
      roomAreaSize: 5,
      roomAreaSizeLarge: 7,
      emptyAreaCount: 30
    },
    onCreate ::(landmark, island){},
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onVisit ::(landmark, island) {}
    
  }
)



Landmark.database.newEntry(
  data: {
    name: 'Mysterious Shrine',
    id: 'base:mysterious-shrine',
    symbol : 'M',
    legendName: 'Shrine',
    rarity : 100000,    
    minLocations : 0,
    maxLocations : 4,
    traits : 
      TRAIT.UNIQUE |
      TRAIT.POINT_OF_NO_RETURN |
      TRAIT.EPHEMERAL,
    minEvents : 1,
    maxEvents : 7,
    eventPreference : LandmarkEvent.KIND.HOSTILE,

    landmarkType : TYPE.DUNGEON,
    requiredEvents : [
      'base:dungeon-encounters',
    ],
    possibleLocations : [
//          {id: 'Stairs Down', rarity:1},
      {id: 'base:fountain', rarity:18},
      {id: 'base:potion-shop', rarity: 25},
      {id: 'base:wyvern-statue', rarity: 20},
      {id: 'base:small-chest', rarity: 16},
      {id: 'base:locked-chest', rarity: 11},
      {id: 'base:magic-chest', rarity: 15},

      {id: 'base:healing-circle', rarity:35},

      {id: 'base:clothing-shop', rarity: 100},
      {id: 'base:fancy-shop', rarity: 50}

    ],
    requiredLocations : [
      'base:stairs-down',
      'base:stairs-down',
      'base:enchantment-stand',
      'base:small-chest',
      'base:small-chest',
      'base:warp-point',
      'base:warp-point'
    ],
    mapHint:{
      layoutType: DungeonMap.LAYOUT_EPSILON
    },
    onCreate ::(landmark, island){
    },
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onVisit ::(landmark, island) {
      if (landmark.floor == 0)
        windowEvent.queueMessage(
          text:"This place seems to shift before you..."
        );
    }
  }
)









Landmark.database.newEntry(
  data: {
    name: 'Lost Shrine',
    id: 'base:lost-shrine',
    symbol : 'M',
    legendName: 'Shrine',
    rarity : 100000,    
    minLocations : 2,
    maxLocations : 4,
    traits :
      TRAIT.UNIQUE |
      TRAIT.POINT_OF_NO_RETURN |
      TRAIT.EPHEMERAL,
    minEvents : 1,
    maxEvents : 7,
    eventPreference : LandmarkEvent.KIND.HOSTILE,

    landmarkType : TYPE.DUNGEON,
    requiredEvents : [
      'base:dungeon-encounters'
    ],
    possibleLocations : [
//          {id: 'Stairs Down', rarity:1},
      {id: 'base:fountain', rarity:18},
      {id: 'base:potion-shop', rarity: 25},
      {id: 'base:wyvern-statue', rarity: 20},
      {id: 'base:small-chest', rarity: 16},
      {id: 'base:locked-chest', rarity: 11},
      {id: 'base:magic-chest', rarity: 15},
      {id: 'base:enchantment-stand', rarity: 15},

      {id: 'base:healing-circle', rarity:35},

      {id: 'base:clothing-shop', rarity: 100},
      {id: 'base:fancy-shop', rarity: 50}

    ],
    requiredLocations : [
      'base:stairs-down',
      'base:locked-chest',
      'base:small-chest',
      'base:small-chest',
      'base:warp-point',
      'base:warp-point'
    ],
    mapHint:{
      layoutType: DungeonMap.LAYOUT_DELTA
    },
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onCreate ::(landmark, island){
    },
    onVisit ::(landmark, island) {
      when (landmark.data.isCompleted == true) ::<= {
        windowEvent.queueMessage(text:'The entrance looks to be covered in rubble. There\'s no way to enter it again.');
        return false;
      }
    }
    
  }
)

Landmark.database.newEntry(
  data: {
    name: 'Shrine: Lost Floor',
    id: 'base:shrine-lost-floor',
    symbol : 'M',
    legendName: 'Shrine',
    rarity : 100000,    
    minLocations : 2,
    maxLocations : 2,
    minEvents : 0,
    maxEvents : 0,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    traits : 
      TRAIT.UNIQUE |
      TRAIT.PEACEFUL |
      TRAIT.POINT_OF_NO_RETURN |
      TRAIT.EPHEMERAL,

    landmarkType : TYPE.DUNGEON,
    requiredEvents : [
    ],
    possibleLocations : [
      {id: 'base:small-chest', rarity:3},
    ],
    requiredLocations : [
      'base:treasure-pit',
      'base:small-chest',
      'base:small-chest',
      'base:enchantment-stand'
    ],
    mapHint:{},
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onCreate ::(landmark, island){
    },
    
    onVisit ::(landmark, island) {
      @:canvas = import(module:'game_singleton.canvas.mt');
      @:windowEvent = import(module:'game_singleton.windowevent.mt');
      windowEvent.queueMessage(text:'It seems this area has been long forgotten...', renderable:{render::<-canvas.blackout()});
    }
    
  }
)


Landmark.database.newEntry(
  data: {
    name: 'Treasure Room',
    id: 'base:treasure-room',
    legendName: 'T. Room',
    symbol : 'O',
    rarity : 5,    
    minLocations : 1,
    maxLocations : 5,
    traits : 
      TRAIT.UNIQUE |
      TRAIT.PEACEFUL,
    minEvents : 0,
    maxEvents : 0,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    landmarkType : TYPE.DUNGEON,
    requiredEvents : [
    ],
    possibleLocations : [
      {id: 'base:small-chest', rarity:5},
    ],
    requiredLocations : [
      'base:large-chest',
      'base:ladder'
    ],
    
    mapHint : {
      roomSize: 15,
      roomAreaSize: 7,
      roomAreaSizeLarge: 9,
      emptyAreaCount: 2
    },
    onCreate ::(landmark, island){},
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onVisit ::(landmark, island) {
      @:world = import(module:'game_singleton.world.mt');
      windowEvent.queueMessage(text:'The party enters the pit full of treasure.');
      foreach(world.island.landmarks) ::(k, v) {
        v.data.isCompleted = true;
      }
    }
    
    
  }
)




Landmark.database.newEntry(
  data: {
    name: 'Port',
    id: 'base:port',
    legendName: 'Port',
    rarity : 30,        
    symbol : '~',
    minLocations : 3,
    maxLocations : 10,
    landmarkType : TYPE.STRUCTURE,
    traits : 
      TRAIT.PEACEFUL |
      TRAIT.GUARDED |
      TRAIT.CAN_SAVE |
      TRAIT.DUNGEON_FORCE_ENTRANCE,
    minEvents : 0,
    maxEvents : 3,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    requiredEvents : [
    ],
    possibleLocations : [
      {id:'base:home', rarity:5},
      {id:'base:shop', rarity:40}
      //'guild',
      //'guardpost',
    ],
    requiredLocations : [
      'base:tavern'
      //'shipyard'
    ],
    mapHint : {
      roomSize: 25,
      roomAreaSize: 5,
      roomAreaSizeLarge: 14,
      emptyAreaCount: 7
    },
    onCreate ::(landmark, island){},
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onVisit ::(landmark, island) {}
    
  }
)

Landmark.database.newEntry(
  data: {
    name: 'Village',
    id: 'base:village',
    legendName: 'Village',
    rarity : 5,        
    symbol : '*',
    minLocations : 3,
    maxLocations : 7,
    landmarkType : TYPE.STRUCTURE,
    traits :
      TRAIT.PEACEFUL |
      TRAIT.CAN_SAVE,
    minEvents : 0,
    maxEvents : 3,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,
      
    possibleLocations : [
      {id:'base:home', rarity:1},
      {id:'base:tavern', rarity:7},
      {id:'base:shop', rarity:7},
      {id:'base:arts-tecker', rarity:7},
      {id:'base:farm', rarity:4}
    ],
    requiredLocations : [
      'base:farm',
      'base:home',
      'base:school'    
    ],
    requiredEvents : [
    ],
    mapHint : {
      roomSize: 25,
      roomAreaSize: 7,
      roomAreaSizeLarge: 14,
      emptyAreaCount: 4
    },    
    onCreate ::(landmark, island){},
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onVisit ::(landmark, island) {}
  }
)

Landmark.database.newEntry(
  data: {
    name: 'Villa',
    id: 'base:villa',
    legendName: 'Villa',
    symbol : '=',
    rarity : 20,
    landmarkType : TYPE.STRUCTURE,
    traits :
      TRAIT.PEACEFUL |
      TRAIT.CAN_SAVE,
    minEvents : 0,
    maxEvents : 3,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,
      
    minLocations : 5,
    maxLocations : 10,
    possibleLocations : [
      {id:'base:home', rarity:1},
      {id:'base:tavern', rarity:7},
      {id:'base:farm', rarity:4}
    ],
    requiredEvents : [
    ],
    requiredLocations : [
      'base:farm',
      'base:home',
      'base:school'        
    ],
    mapHint : {
      roomSize: 25,
      wallCharacter: ',',
      roomAreaSize: 7,
      roomAreaSizeLarge: 14,
      emptyAreaCount: 4
    },
    onCreate ::(landmark, island){},
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onVisit ::(landmark, island) {}
  }
)

/*Landmark.database.newEntry(
  data: {
    id: 'Outpost',
    symbol : '[]',
    rarity : 500,        
    minLocations : 0,
    maxLocations : 0,
    possibleLocations : [
      //'barracks'        
    ],
    requiredLocations : []
  }
)*/

Landmark.database.newEntry(
  data: {
    name: 'Forest',
    id: 'base:forest',
    legendName: 'Forest',
    symbol : 'T',
    rarity : 40,        
    peaceful: true,
    landmarkType : TYPE.DUNGEON,

    traits :
      TRAIT.EPHEMERAL |
      TRAIT.DUNGEON_FORCE_ENTRANCE,
    minEvents : 0,
    maxEvents : 1,
    eventPreference : LandmarkEvent.KIND.HOSTILE,

    minLocations : 3,
    maxLocations : 5,
    possibleLocations : [
      {id: 'base:small-chest', rarity:1},
    ],
    requiredLocations : [
      'base:small-chest'
    ],
    requiredEvents : [
      'base:the-snakesiren'
    ],
    mapHint: {
      roomSize: 60,
      wallCharacter: 'Y',
      roomAreaSize: 7,
      roomAreaSizeLarge: 14,
      emptyAreaCount: 25,
      outOfBoundsCharacter: '~'
    },
    onCreate ::(landmark, island){},
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onVisit ::(landmark, island) {
      windowEvent.queueMessage(
        text:"This place seems to shift before you..."
      );    
    }
    
  }
)


Landmark.database.newEntry(
  data: {
    name: 'Forest',
    id: 'base:forest-generic',
    legendName: 'Forest',
    symbol : 'T',
    rarity : 40,        
    landmarkType : TYPE.DUNGEON,

    traits :
      TRAIT.PEACEFUL |
      TRAIT.UNIQUE |
      TRAIT.DUNGEON_FORCE_ENTRANCE |
      TRAIT.CAN_SAVE,
    minEvents : 0,
    maxEvents : 0,
    eventPreference : LandmarkEvent.KIND.HOSTILE,

    minLocations : 3,
    maxLocations : 5,
    possibleLocations : [
    ],
    requiredLocations : [
    ],
    requiredEvents : [
    ],
    mapHint: {
      roomSize: 30,
      wallCharacter: 'Y',
      roomAreaSize: 7,
      roomAreaSizeLarge: 14,
      emptyAreaCount: 13,
      outOfBoundsCharacter: '~'
    },
    onCreate ::(landmark, island){},
    onIncrementTime ::(landmark, island){},
    onStep ::(landmark, island) {},
    onVisit ::(landmark, island) {
    }
    
  }
)
/*
Landmark.database.newEntry(
  data: {
    name: 'Cave',
    legendName: 'Cave',
    symbol : 'O',
    rarity : 200,        
    peaceful: true,
    isUnique : false,
    landmarkType : TYPE.DUNGEON,
    pointOfNoReturn : false,
    ephemeral : false,
    dungeonForceEntrance: true,
    minLocations : 0,
    maxLocations : 0,
    guarded : false,
    canSave : true,
    requiredEvents : [
    ],
    possibleLocations : [],
    requiredLocations : [],
    mapHint: {},
    onCreate ::(landmark, island){},
    onVisit ::(landmark, island) {}
    
  }
)

Landmark.database.newEntry(
  data: {
    id: 'Abandoned Castle',
    legendName: 'Castle',
    symbol : 'X',
    rarity : 10000,
    peaceful: false,
    isUnique : false,
    landmarkType : TYPE.DUNGEON,
    dungeonForceEntrance: true,
    
    minLocations : 0,
    maxLocations : 0,
    guarded : false,
    canSave : true,
    pointOfNoReturn : false,
    ephemeral : false,
    requiredEvents : [
    ],
    possibleLocations : [],
    requiredLocations : [],
    mapHint: {},
    onCreate ::(landmark, island){},
    onVisit ::(landmark, island) {}
    
  }
)
Landmark.database.newEntry(
  data: {
    id: 'Abandoned Town',
    legendName: 'Town',
    rarity : 400,        
    symbol : 'x',
    peaceful: false,
    isUnique : false,
    landmarkType : TYPE.DUNGEON,
    canSave : true,
    dungeonForceEntrance: true,
    guarded : false,
    minLocations : 0,
    maxLocations : 0,
    pointOfNoReturn : false,
    ephemeral : false,
    requiredEvents : [
    ],
    possibleLocations : [],
    requiredLocations : [],
    mapHint: {},        
    onCreate ::(landmark, island){},
    onVisit ::(landmark, island) {}
  }
)
*/
}

@:Landmark = databaseItemMutatorClass.create(  
  name : 'Wyvern.Landmark',
  statics : {
    TYPE : {get ::<- TYPE},
    TRAIT : {get ::<- TRAIT}
  },
  items : {
    worldID : 0,
    name : '',
    x : 0,
    y : 0,
    discovered : false,
    peaceful : false,
    floor : 0,
    map : empty,
    stepsSinceLast: 0,
    data : empty,
    events : empty,
    mapEntityController : empty,
    overrideTitle : '',
    symbol : '',
    legendName : ''
  },
  
  database : Database.new(
    name : 'Wyvern.Landmark.Base',
    attributes : {
      id : String,
      name: String,
      legendName : String,
      symbol : String,
      rarity: Number,
      minEvents : Number,
      maxEvents : Number,
      eventPreference : Number,
      minLocations : Number,
      maxLocations : Number,
      possibleLocations : Object,
      requiredLocations : Object,
      requiredEvents : Object,
      landmarkType: Number,
      mapHint : Object,
      onCreate : Function,
      onVisit : Function,
      onIncrementTime : Function,
      onStep : Function,
      traits : Number
    },
    reset
  ),

  
  define :::(this, state) {
    @:MapEntity = import(module:'game_mutator.mapentity.mt');
    @:random = import(module:'game_singleton.random.mt');
    @:NameGen = import(module:'game_singleton.namegen.mt');
    @:DungeonMap = import(module:'game_singleton.dungeonmap.mt');
    @:StructureMap = import(module:'game_class.structuremap.mt');
    @:distance = import(module:'game_function.distance.mt');
    @:LoadableClass = import(module:'game_singleton.loadableclass.mt');
    @:Map = import(module:'game_class.map.mt');
    @:windowEvent = import(module:'game_singleton.windowevent.mt');
    @:canvas = import(module:'game_singleton.canvas.mt');
    @:Location = import(module:'game_mutator.location.mt');
    @:LandmarkEvent = import(module:'game_mutator.landmarkevent.mt');

    @island_;
    @structureMapBuilder; // only used in initialization

    @:world = import(module:'game_singleton.world.mt');


    
    
    

    
    
    

    @:Entity = import(module:'game_class.entity.mt');

    @:loadContent::(base) {

      if (base.landmarkType == TYPE.DUNGEON) ::<= {
        state.map = DungeonMap.create(parent:this, mapHint: base.mapHint);
        if (base.hasTraits(:Landmark.TRAIT.DUNGEON_FORCE_ENTRANCE)) ::<= {
          this.addLocation(location:Location.new(landmark: this, base:Location.database.find(:'base:entrance')));
        }
      } else if (base.landmarkType == TYPE.STRUCTURE) ::<= {
        structureMapBuilder = StructureMap.new();//Map.new(mapHint: base.mapHint);
        structureMapBuilder.initialize(mapHint:base.mapHint, parent:this);
        this.addLocation(location:Location.new(landmark: this, base:Location.database.find(:'base:entrance')));
      } else ::<= {
        state.map = Map.new(parent:this);
      }


      
      /*
      [0, Random.integer(from:base.minLocations, to:base.maxLocations)]->for(do:::(i) {
        locations->push(value:island.newInhabitant());      
      });
      */
      @mapIndex = 0;
   







      
      





      

      foreach(base.requiredLocations)::(i, loc) {
        this.addLocation(
          location:Location.new(landmark:this, base:Location.database.find(:loc))
        );
      
        mapIndex += 1;
      }
      @:possibleLocations = [...base.possibleLocations];
      for(0, random.integer(from:base.minLocations, to:base.maxLocations))::(i) {
        when(possibleLocations->keycount == 0) empty;
        @:which = random.pickArrayItemWeighted(list:possibleLocations);
        this.addLocation(
          location:Location.new(landmark:this, base:Location.database.find(:which.id))
        );
        if (Location.database.find(id:which.id).onePerLandmark) ::<= {
          possibleLocations->remove(key:possibleLocations->findIndex(value:which));
        }
        mapIndex += 1;
      }
      
      if (base.landmarkType == TYPE.DUNGEON) ::<= {
        @:gate = this.gate;
        if (gate == empty) ::<= {
          this.movePointerToRandomArea();
        } else ::<= {
          state.map.setPointer(
            x:gate.x,
            y:gate.y
          );          
        }
      } else if (base.landmarkType == TYPE.STRUCTURE) ::<= {
        state.map = structureMapBuilder.finalize();
        @:gate = this.gate;
        state.map.setPointer(
          x:gate.x,
          y:gate.y
        );

        // cant add locations to structure maps through the landmark.
        structureMapBuilder = empty;
      }




      state.map.title = state.name;

      
      @:alreadyEvents = [];
      foreach(base.requiredEvents) ::(k, evt) {
        alreadyEvents->push(:evt);
        state.events->push(value:
          LandmarkEvent.new(
            parent: this,
            base: LandmarkEvent.database.find(id:evt)
          )
        );
      }
      
      // TODO: repeats? make this unique?
      for(0, random.integer(from:base.minEvents, to:base.maxEvents)) ::(i) {
        @which = LandmarkEvent.database.getRandomFiltered(
          ::(value) <- value.kind == base.eventPreference &&
                       alreadyEvents->findIndex(:value.id) == -1
        )
        when(which == empty) empty;
        alreadyEvents->push(:which.id);
        state.events->push(value:
          LandmarkEvent.new(
            parent: this,
            base: which
          )
        );
      }
      
      state.mapEntityController = MapEntity.Controller.new(parent:this);
    }

    this.interface =  {
      initialize ::(parent, island) {
        @:Island = import(module:'game_mutator.island.mt');
        if (parent)
          island = parent.parent; // parents of locations are always maps

        // backup: just take the current world's island
        if (island == empty)  
          island = import(:'game_singleton.world.mt').island;
          
        if (island == empty)
          error(:'A landmark MUST be initialized with an island or parent.');
        island_ = island;
      },

      defaultLoad::(base, x, y, floorHint){
        state.worldID = world.getNextID();
        state.x = 0;
        state.y = 0;
        state.floor = 0;
        state.stepsSinceLast = 0;
        state.data = {};
        state.events = [];
        state.symbol = base.symbol;
        state.legendName = base.legendName;

        state.base = base;
        state.x = if (x != empty) x else 0;
        state.y = if (y != empty) y else 0;
        state.peaceful = base.hasTraits(:TRAIT.PEACEFUL)

        if (floorHint != empty) ::<= {
          state.floor = floorHint;
          state.floor => Number;
        }

        if (base.hasTraits(:TRAIT.UNIQUE))
          state.name = base.name
        else
          state.name = base.name + ' of ' + NameGen.place();


        if (!base.hasTraits(:TRAIT.EPHEMERAL))
          loadContent(base);
        this.base.onCreate(landmark:this, island:island_);    
        
      },

      save :: {
        return state.save();
      },
      load ::(serialized) { 
        if (serialized.isSparse) ::<= {
          @:sparse = StateType.new();
          sparse.load(parent:this, serialized);
          this.defaultLoad(
            base: sparse.base,
            x: sparse.x,
            y: sparse.y,
            floorHint: sparse.floorHint
          )   
        } else ::<= {
          state.load(parent:this, serialized, loadFirst: ['map'])
        }
        if (state.mapEntityController != empty)
          state.mapEntityController.initialize(parent:this);
      },

      worldID : {
        get ::<- state.worldID
      },
      
      // can modify
      events : {
        get ::<- state.events
      },
    
      description : {
        get :: {
          @:locations = this.locations;
          @out = state.name + ', a ' + state.base.name;
          if (locations->keycount > 0) ::<={
            out = out + ' with ' + locations->keycount + ' locations';//:\n';
            //foreach(in:locations, do:::(index, inhabitant) {
            //  out = out + '   ' + inhabitant.name + ', a ' + inhabitant.species.name + ' ' + inhabitant.profession.name +'\n';
            //});
          }
          return out;
        }
      },
      
      loadContent ::{
        @:base = state.base;        
        if (state.map == empty)
          loadContent(base);              
      },
      
      unloadContent ::{
        state.map = empty;
      },
      
      name : {
        get :: {
          return state.name;        
        },
        
        set ::(value) {
          state.name = value;
          if (state.map)
            state.map.title = value;
        }
      },
      
      x : {
        get ::<- state.x
      },
      
      y : {
        get ::<- state.y
      },
      
      width : {
        get ::<- if (structureMapBuilder) structureMapBuilder.getWidth() else state.map.width
      },
      height : {
        get ::<- if (structureMapBuilder) structureMapBuilder.getHeight() else state.map.height
      },
      
      peaceful : {
        get :: <- state.peaceful,
        set ::(value) <- state.peaceful = value
      },

      floor : {
        get :: <- state.floor
      },
      
      updateTitle ::(override)  {
        if (override) 
          state.overrideTitle = override;

        when (this.map == empty) empty;          
        when (state.overrideTitle != '')
          this.map.title = state.overrideTitle;
        
        this.map.title = this.name + 
          if (state.base.landmarkType == TYPE.DUNGEON) ' - Unknown Time' else 
          (' - ' + world.timeString)
        ;      
      },
      
      symbol : {
        get ::<- state.symbol,
        set ::(value) <- state.symbol = value
      },
      
      legendName : {
        get ::<- state.legendName,
        set ::(value) <- state.legendName = value
      },

      incrementTime ::{
        this.updateTitle();
        
        state.base.onIncrementTime();
        
        foreach(this.locations) ::(k, v) {
          v.incrementTime();
        }

        foreach(state.events) ::(k, event) {
          event.incrementTime();
        }
      },


      // represents a step made within the landmark.
      step :: {
        state.base.onStep(landmark:this, island:this.island);
        state.mapEntityController.step();

        foreach(world.party.quests) ::(k, v) {
          v.step(landmark:this, island:this.island);
        }

        foreach(state.events) ::(k, event) {
          event.step();
        }



        when(state.base.landmarkType == TYPE.STRUCTURE) ::<= {
          if (this.peaceful == false) ::<= {
            if (state.stepsSinceLast >= 30 && random.number() > 0.7) ::<= {
              @:Scene = import(module:'game_database.scene.mt');            
              Scene.start(id:'base:scene_guards0', onDone::{}, location:empty, landmark:this);
              state.stepsSinceLast = 0;
            }
          }
          state.stepsSinceLast += 1;        
        }
        
        foreach(state.events) ::(k, event) {
          event.step();
        }

        @:locations = state.map.getItemsUnderPointer();
        if (locations->type == Object) ::<= {
          foreach(locations) ::(k, v) {
            if (v.data->type == Location.type) ::<= {
              v.data.base.onStep(entities: world.party.members, location:v.data);
            }
          }
        }

        state.stepsSinceLast += 1;                
        
      },
      
      mapEntityController : {
        get ::<- state.mapEntityController
      },
      
      kind : {
        get :: {
          return state.base.name;
        }
      },
      
      gate : {
        get :: {
          @:locations = this.locations;
          @:index = locations->findIndexCondition(::(value) {
            return value.base.id == 'base:entrance'
          });
          when (index != -1)
            locations[index];
        }
      },
      discover :: {
        @:world = import(module:'game_singleton.world.mt');
        @:windowEvent = import(module:'game_singleton.windowevent.mt');
        if (!state.discovered)
          if (world.party.inventory.items->filter(by:::(value) <- value.base.name == 'Runestone')->keycount != 0) ::<= {
            world.storyFlags.data_locationsDiscovered += 1;
            windowEvent.queueMessage(text:'Location found! ' + world.storyFlags.data_locationsDiscovered + ' / ' 
                                 + world.storyFlags.data_locationsNeeded + ' locations.');         
          }
        state.discovered = true;
      },
      
      discovered : {
        get ::<- state.discovered
      },
      
      locations : {
        get :: {
          when(state.map == empty) [];
          return state.map.getAllItemData()->filter(by:::(value) <- value->type == Location.type)
        }
      },
      island : {
        get ::<- island_,
        set ::(value) <- island_ = value
      },
      
      movePointerToRandomArea ::{
        @:area = state.map.getRandomEmptyArea();
        state.map.setPointer(
          x:area.x + (area.width/2)->floor,
          y:area.y + (area.height/2)->floor
        );      
      },
      
      getRandomEmptyPosition ::{
        // shouldnt do this!
        when (state.base.landmarkType != TYPE.DUNGEON) empty;

        @:area = state.map.getRandomEmptyArea();
        return { 
          x:area.x + (area.width/2)->floor,
          y:area.y + (area.height/2)->floor
        }
      },
      
      data : {
        get ::<- state.data
      },


      removeLocation ::(location) {
        state.map.removeItem(data:location);
      },

      addLocation ::(location, width, height, noHalo, discovered) {
        location.landmark = this;
        @:loc = location;
        if (discovered == empty) 
          discovered = false         
        @:defaultAdd ::(discovered){
          when (width == empty && height == empty)
            state.map.setItem(data:loc, x:loc.x, y:loc.y, symbol: loc.base.symbol, discovered, name:loc.name);
          for(loc.x, width + loc.x) ::(ix) {
            for(loc.y, height + loc.y) ::(iy) {
              state.map.setItem(data:loc, x:ix, y:iy, symbol: loc.base.symbol, discovered, name:loc.name);            
            }
          }
                
        }

        if (state.base.landmarkType == TYPE.DUNGEON) ::<= {
          if (loc.x == 0 && loc.y == 0)
            state.map.addToRandomEmptyArea(item:loc, symbol: loc.base.symbol, name:loc.name, discovered:false)
          else
            defaultAdd(discovered:false);
          
        } else if (state.base.landmarkType == TYPE.STRUCTURE) ::<= {
          if (structureMapBuilder != empty)
            structureMapBuilder.addLocation(location:loc)
          else  
            defaultAdd(discovered:false);

        } else 
          defaultAdd(discovered:false);

        return loc;      
 
      },
      
      moveLocation ::(location) {
        
      },
      
      island : {
        get ::<- island_
      },
      
      map : {
        get ::<- state.map
      }
    }
  }
);


return Landmark;
