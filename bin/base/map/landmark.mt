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
@:databaseItemMutatorClass = import(module:'core/data/databaseitemmutatorclass.mt');
@:Database = import(module:'core/data/database.mt');
@:State = import(module:'core/data/state.mt');
@:sound = import(module:'core/sound.mt');
@:random = import(module:'core/random.mt');


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
  // Dungeon mode features a generation algorithm to determine areas and 
  // points of interest in a continuous, connected space.
  // Objects are placed within these map areas calculated.
  // In dungeon mode, every object (required / possible) is a location specification
  /*
      {
        // the ID of the location to spawn
        id: 'location-id',
        
        // optional symbol to override its mark with 
        overrideSymbol : '*',
        
        // Optional override name
        overrideName : 'My Display Name',
      
        // Optional any-data to pass to the location.
        data : {
          someData : thing
        },
        
        // Optional relative rarity (higher means more rare)
        // Only used for "possible" entries
        rarity : 10
      }
  */
  DUNGEON : {},
  
  // In structure mode, every object (required / possible) is a portal.
  // "buildings" are created with portals leading to the objects.
  // This is purely cosmetic and used for placement.
  // Portals are special jump points to other landmarks.
  // Technically, portals are special locations within the landmarks.
  /*
      {
        // the ID of a landmark to warp to.
        // Landmarks created this way are generated on-the-fly 
        // upon first visiting the portal. The landmark is 
        // also added to a 
        id: 'landmark-id',
        
        // optional symbol to identify the structure associated with the portal
        // More often than not override symbols are blank
        symbol : '*',
        
        // Public name of the portal to show.
        name : 'Shop',
      
        // Optional any-data to pass to the landmark 
        data : {
          someData : thing
        },
        
        // Optional relative rarity (higher means more rare)
        // Only used for "possible" entries
        rarity : 10
      }
  */
  STRUCTURE : {},
  
  // objects are ignored and it is up to the landmark or manager 
  // to populate the landmark.
  CUSTOM : {},
  
  // imports a json layout in "single" mode, where 
  // a random pattern is loaded as a valid map.
  // NOTE: all json files are preloaded by the 
  // game at startup or on modload
  //
  // Each blueprint interprets objects as 
  // locations.
  BLUEPRINT_SINGLE ::(path) <-
    {
      blueprint : true,
      single : true,
      data : import(:path)
    },
    
  // Each blueprint interprets objects as 
  // locations.
  BLUEPRINT_COLLAGE ::(path) <-
    {
      blueprint : true,
      single : false,
      data : import(:path)
    }
}

@:TRAIT = {
  NONE : 0,
  UNIQUE : 1,
  PEACEFUL : 2,
  DUNGEON_FORCE_ENTRANCE: 4,
  EPHEMERAL: 8,
  CAN_SAVE : 16,
  POINT_OF_NO_RETURN : 32,
  GUARDED : 64,
  NOTHING_HIDDEN : 128,
  
  // by default, locations are of structure size small 
  // this bumps it up. really only for structure maps
  STRUCTURE_LARGE : 256,
  
  STRUCTURE_RESIDENTIAL : 512,
  STRUCTURE_BUSINESS : 1024,
  STRUCTURE_UTILITY : 2048,

}


@:reset ::{

@:DungeonMap = import(module:'base/map/dungeon.mt');
@:windowEvent = import(module:'core/windowevent.mt');
@:LandmarkEvent = import(module:'base/event/landmark.mt');

Landmark.database.newEntry(
  data: {
    name: 'Town',
    id: 'base:town',
    legendName : 'Town',
    symbol : '#',
    rarity : 100000,
    minObjects : 7,
    maxObjects : 15,
    minEvents : 0,
    maxEvents : 3,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,
    landmarkType : TYPE.STRUCTURE,
    traits : 
      TRAIT.GUARDED |
      TRAIT.CAN_SAVE |
      TRAIT.PEACEFUL,

    requiredEvents : [],
    possibleObjects : [
      {
        name : 'Home',
        symbol: ' ',
        id:'base:home-inside', rarity:20
      },
      //{id:'guild', rarity: 25}
    ],
    requiredObjects : [
      {
        name : 'Shop',
        symbol: '$',
        id: 'base:shop-inside'
      },
      /*    
      {id:'base:arts-tecker'},
      {id:'base:school'},
      {id:'base:tavern'},
      {id:'base:blacksmith'},
      {id:'base:inn'}      
      */
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
    events :{
      onVisit ::(landmark, island) {
        sound.playBGM(name:'town-2', loop:true);
      }
    }
  }
)



Landmark.database.newEntry(
  data: {
    name: 'Home Town',
    id: 'base:town-start',
    legendName : 'Home Town',
    symbol : '#',
    rarity : 100000,
    minObjects : 4,
    maxObjects : 6,
    minEvents : 0,
    maxEvents : 3,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,
    landmarkType : TYPE.STRUCTURE,
    traits : 
      TRAIT.GUARDED |
      TRAIT.CAN_SAVE |
      TRAIT.PEACEFUL,

    requiredEvents : [],
    possibleObjects : [
      {
        name : 'Home',
        symbol: ' ',
        id:'base:home-inside', rarity:20
      },
      //{id:'guild', rarity: 25}
    ],
    requiredObjects : [
      {
        name : 'Your Home',
        symbol: ' ',
        id:'base:home-inside-start', rarity:20
      },

      {
        name : 'Shop',
        symbol: '$',
        id: 'base:shop-inside'
      },
      /*    
      {id:'base:arts-tecker'},
      {id:'base:school'},
      {id:'base:tavern'},
      {id:'base:blacksmith'},
      {id:'base:inn'}      
      */
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
    events :{
      onVisit ::(landmark, island) {
        sound.playBGM(name:'town-2', loop:true);
      }
    }
  }
)



Landmark.database.newEntry(
  data: {
    name: '',
    id: 'base:none',
    legendName : '',
    symbol : ' ',
    rarity : 100000,
    minObjects : 7,
    maxObjects : 15,
    minEvents : 0,
    maxEvents : 3,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,
    landmarkType : TYPE.STRUCTURE,
    traits : 
      TRAIT.GUARDED |
      TRAIT.CAN_SAVE |
      TRAIT.PEACEFUL | 
      TRAIT.UNIQUE,

    requiredEvents : [],
    possibleObjects : [
    ],
    requiredObjects : [
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
    events : {}
  }
)



Landmark.database.newEntry(
  data: {
    name: 'City',
    id: 'base:city',
    legendName : 'City',
    symbol : '|',
    rarity : 5,
    minObjects : 12,
    maxObjects : 17,
    traits : 
      TRAIT.PEACEFUL |
      TRAIT.GUARDED |
      TRAIT.CAN_SAVE,
    minEvents : 2,
    maxEvents : 6,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    landmarkType : TYPE.STRUCTURE,
    requiredEvents : [],
    possibleObjects : [
      {id:'base:home', rarity: 1},
      //{id:'inn', rarity: 3},
      //{id:'guild', rarity: 25}
      //{id:'tavern', rarity: 100}
      //{id:'school', rarity: 7}
    ],
    requiredObjects : [
      {
        name : 'Shop',
        symbol: '$',
        id: 'base:shop-inside'
      },
      {
        name : 'Shop',
        symbol: '$',
        id: 'base:shop-inside'
      },
      {
        name : 'Shop',
        symbol: '$',
        id: 'base:shop-inside'
      },            
      /*
      'base:auction-house',
      'base:arts-tecker',
      'base:tavern',
      'base:arena',
      'base:inn',
      'base:school',
      'base:school',
      'base:blacksmith'      
      */
    ],
    mapHint : {
      roomSize: 30,
      roomAreaSize: 5,
      roomAreaSizeLarge: 7,
      emptyAreaCount: 18,
      wallCharacter : '|'
    },
    events : {
      onVisit ::(landmark, island) {
        sound.playBGM(name:'town-2', loop:true);
      }
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
    minObjects : 10,
    maxObjects : 15,
    minEvents : 0,
    maxEvents : 0,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    traits : 
      TRAIT.PEACEFUL |
      TRAIT.CAN_SAVE |
      TRAIT.DUNGEON_FORCE_ENTRANCE,

    landmarkType : TYPE.DUNGEON,
    requiredEvents : [],
    possibleObjects : [
      {id:'base:ore-vein', rarity: 1},
    ],
    requiredObjects : [
      {id:'base:ore-vein'},
      {id:'base:smelter'},
    ],
    mapHint : {
      roomSize: 15,
      roomAreaSize: 5,
      roomAreaSizeLarge: 10,
      emptyAreaCount: 15
    },
    events : {}
    
  }
)


Landmark.database.newEntry(
  data: {
    name: 'Wyvern Gate',
    id: 'base:wyvern-gate',
    legendName: 'Gate',
    symbol : '@',
    rarity : 10,
    minObjects : 4,
    maxObjects : 10,
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
    possibleObjects : [

    ],
    requiredObjects : [
      {id:'base:gate'}
    ],
    
    mapHint : {
      roomSize: 25,
      wallCharacter: 'Y',
      roomAreaSize: 5,
      roomAreaSizeLarge: 7,
      emptyAreaCount: 30
    },
    events : {}
  }
)



Landmark.database.newEntry(
  data: {
    name: 'Mysterious Shrine',
    id: 'base:mysterious-shrine',
    symbol : 'M',
    legendName: 'Shrine',
    rarity : 100000,    
    minObjects : 0,
    maxObjects : 4,
    traits : 
      TRAIT.UNIQUE |
      TRAIT.POINT_OF_NO_RETURN |
      TRAIT.EPHEMERAL,
    minEvents : 2,
    maxEvents : 7,
    eventPreference : LandmarkEvent.KIND.HOSTILE,

    landmarkType : TYPE.DUNGEON,
    requiredEvents : [
    ],
    possibleObjects : [
//          {id: 'Stairs Down', rarity:1},
      {id: 'base:fountain', rarity:18},
      {id: 'base:potion-shop', rarity: 25},
      {id: 'base:wyvern-statue', rarity: 20},
      {id: 'base:small-chest', rarity: 30},
      {id: 'base:locked-chest', rarity: 40},
      {id: 'base:magic-chest', rarity: 15},

      {id: 'base:healing-circle', rarity:35},

      {id: 'base:clothing-shop', rarity: 100},
      {id: 'base:fancy-shop', rarity: 50}

    ],
    requiredObjects : [
      {id:'base:stairs-down'},
      {id:'base:stairs-down'},
      {id:'base:enchantment-stand'},
      {id:'base:item'},
      {id:'base:item'},
      {id:'base:warp-point'},
    ],
    mapHint:{
      layoutType: DungeonMap.LAYOUT_EPSILON
    },
    events : {
      onVisit ::(landmark, island) {
        if (landmark.floor == 0)
          windowEvent.queueMessage(
            text:"This place seems to shift before you..."
          );
      }
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
    minObjects : 2,
    maxObjects : 4,
    traits :
      TRAIT.UNIQUE |
      TRAIT.POINT_OF_NO_RETURN |
      TRAIT.EPHEMERAL,
    minEvents : 2,
    maxEvents : 7,
    eventPreference : LandmarkEvent.KIND.HOSTILE,

    landmarkType : TYPE.DUNGEON,
    requiredEvents : [
    ],
    possibleObjects : [
//          {id: 'Stairs Down', rarity:1},
      {id: 'base:fountain', rarity:18},
      {id: 'base:potion-shop', rarity: 25},
      {id: 'base:wyvern-statue', rarity: 20},
      {id: 'base:locked-chest', rarity: 40},
      {id: 'base:locked-chest', rarity: 40},
      {id: 'base:magic-chest', rarity: 50},
      {id: 'base:enchantment-stand', rarity: 15},

      {id: 'base:healing-circle', rarity:35},

      {id: 'base:clothing-shop', rarity: 100},
      {id: 'base:fancy-shop', rarity: 50}

    ],
    requiredObjects : [
      {id: 'base:stairs-down'},
      {id: 'base:item'},
      {id: 'base:item'},
      {id: 'base:warp-point'}
    ],
    mapHint:{
      layoutType: DungeonMap.LAYOUT_DELTA
    },
    events : {
      onVisit ::(landmark, island) {
        when (landmark.data.isCompleted == true) ::<= {
          windowEvent.queueMessage(text:'The entrance looks to be covered in rubble. There\'s no way to enter it again.');
          return false;
        }
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
    minObjects : 2,
    maxObjects : 2,
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
    possibleObjects : [
      {id: 'base:small-chest', rarity:3},
    ],
    requiredObjects : [
      {id: 'base:treasure-pit'},
      {id: 'base:small-chest'},
      {id: 'base:small-chest'},
      {id: 'base:enchantment-stand'}
    ],
    mapHint:{},
    events : {
      onVisit ::(landmark, island) {
        @:canvas = import(module:'core/graphics/canvas.mt');
        @:windowEvent = import(module:'core/windowevent.mt');
        windowEvent.queueMessage(text:'It seems this area has been long forgotten...', renderable:{render::<-canvas.fill()});
      }
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
    minObjects : 1,
    maxObjects : 5,
    traits : 
      TRAIT.UNIQUE |
      TRAIT.PEACEFUL,
    minEvents : 0,
    maxEvents : 0,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    landmarkType : TYPE.DUNGEON,
    requiredEvents : [
    ],
    possibleObjects : [
      {id: 'base:small-chest', rarity:5},
    ],
    requiredObjects : [
      {id: 'base:large-chest'},
      {id: 'base:ladder'}
    ],
    
    mapHint : {
      roomSize: 15,
      roomAreaSize: 7,
      roomAreaSizeLarge: 9,
      emptyAreaCount: 2
    },
    events : {
      onVisit ::(landmark, island) {
        @:world = import(module:'base/world.mt');
        windowEvent.queueMessage(text:'The party enters the pit full of treasure.');
        foreach(world.island.landmarks) ::(k, v) {
          v.data.isCompleted = true;
        }
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
    minObjects : 3,
    maxObjects : 10,
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
    possibleObjects : [
      {id:'base:home', rarity:5},
      {id:'base:shop', rarity:40}
      //'guild',
      //'guardpost',
    ],
    requiredObjects : [
      {id:'base:tavern'}
      //'shipyard'
    ],
    mapHint : {
      roomSize: 25,
      roomAreaSize: 5,
      roomAreaSizeLarge: 14,
      emptyAreaCount: 7
    },
    events : {}    
  }
)

Landmark.database.newEntry(
  data: {
    name: 'Village',
    id: 'base:village',
    legendName: 'Village',
    rarity : 5,        
    symbol : '*',
    minObjects : 3,
    maxObjects : 7,
    landmarkType : TYPE.STRUCTURE,
    traits :
      TRAIT.PEACEFUL |
      TRAIT.CAN_SAVE,
    minEvents : 0,
    maxEvents : 3,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,
      
    possibleObjects : [
      /*{id:'base:home', rarity:1},
      {id:'base:tavern', rarity:7},
      {id:'base:shop', rarity:7},
      {id:'base:arts-tecker', rarity:7},
      {id:'base:farm', rarity:4}*/
    ],
    requiredObjects : [
      /*
      {id:'base:farm'},
      {id:'base:home'},
      {id:'base:school'}    
      */
    ],
    requiredEvents : [
    ],
    mapHint : {
      roomSize: 25,
      roomAreaSize: 7,
      roomAreaSizeLarge: 14,
      emptyAreaCount: 4
    },    
    events : {}
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
      
    minObjects : 5,
    maxObjects : 10,
    possibleObjects : [
      //{id:'base:home', rarity:1},
      //{id:'base:tavern', rarity:7},
      //{id:'base:farm', rarity:4}
    ],
    requiredEvents : [
    ],
    requiredObjects : [
      //'base:farm',
      //'base:home',
      //'base:school'        
    ],
    mapHint : {
      roomSize: 25,
      wallCharacter: ',',
      roomAreaSize: 7,
      roomAreaSizeLarge: 14,
      emptyAreaCount: 4
    },
    events : {}
  }
)

/*Landmark.database.newEntry(
  data: {
    id: 'Outpost',
    symbol : '[]',
    rarity : 500,        
    minObjects : 0,
    maxObjects : 0,
    possibleObjects : [
      //'barracks'        
    ],
    requiredObjects : []
  }
)*/

Landmark.database.newEntry(
  data: {
    name: 'Forest Cave',
    id: 'base:forest',
    legendName: 'Forest Cave',
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

    minObjects : 3,
    maxObjects : 5,
    possibleObjects : [
      {id: 'base:small-chest', rarity:1},
    ],
    requiredObjects : [
      {id: 'base:item'},
      {id: 'base:item'},
      {id: 'base:item'},
      {id: 'base:item'},
      {id: 'base:item'},
      {id: 'base:item'}
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
      undefinedCharacter: '~'
    },
    events : {
      onVisit ::(landmark, island) {
        windowEvent.queueMessage(
          text:"This place seems to shift before you..."
        );    
      }
    }    
  }
)

Landmark.database.newEntry(
  data: {
    name: 'Hidden Forest Cave',
    id: 'base:forest-generic',
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

    minObjects : 0,
    maxObjects : 1,
    possibleObjects : [
      {id: 'base:small-chest', rarity:1},
    ],
    requiredObjects : [

    ],
    requiredEvents : [
    ],
    mapHint: {
      roomSize: 60,
      wallCharacter: 'Y',
      roomAreaSize: 7,
      roomAreaSizeLarge: 14,
      emptyAreaCount: 25,
      undefinedCharacter: '~'
    },
    events : {
      onVisit ::(landmark, island) {
        windowEvent.queueMessage(
          text:"This place seems to shift before you..."
        );    
      }
    }    
  }
)


Landmark.database.newEntry(
  data: {
    name: 'Shop: Inside',
    id: 'base:shop-inside',
    legendName: '',
    symbol : '$',
    rarity : 40,        
    landmarkType : TYPE.BLUEPRINT_SINGLE(:'assets/maps/roomtest.json'),

    traits :
      TRAIT.PEACEFUL |
      TRAIT.UNIQUE |
      TRAIT.CAN_SAVE |
      TRAIT.NOTHING_HIDDEN |
      TRAIT.STRUCTURE_BUSINESS,
    minEvents : 0,
    maxEvents : 0,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    minObjects : 0,
    maxObjects : 0,
    possibleObjects : [
    ],
    requiredObjects : [
    ],
    requiredEvents : [
    ],
    mapHint: {
    },
    events : {
    }
    
  }
)




Landmark.database.newEntry(
  data: {
    name: 'Home: Inside',
    id: 'base:home-inside',
    legendName: '',
    symbol : '',
    rarity : 40,        
    landmarkType : TYPE.BLUEPRINT_SINGLE(:'assets/maps/home.json'),

    traits :
      TRAIT.PEACEFUL |
      TRAIT.UNIQUE |
      TRAIT.CAN_SAVE |
      TRAIT.NOTHING_HIDDEN |
      TRAIT.STRUCTURE_RESIDENTIAL,
    minEvents : 0,
    maxEvents : 0,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    minObjects : 0,
    maxObjects : 0,
    possibleObjects : [
    ],
    requiredObjects : [
    ],
    requiredEvents : [
    ],
    mapHint: {
    },
    events : {
      onLeave::(landmark) {
        @:name = ::? {
          foreach(landmark.locations) ::(k, loc) {
            if (loc.base.id == 'base:person-static')
              send(:loc.name);
          }
        }
        when(name == empty) empty;
      
        foreach(landmark.locations) ::(k, loc) {
          when (loc.base.id == 'base:portal' && loc.hasPortal) ::<= {
            @:targetLocation = landmark.island.findLocation(:loc.portal.destinationWorldID);
            breakpoint();
            
            @:items = targetLocation.landmark.map.itemsAt(x:targetLocation.x, y:targetLocation.y);
            when(items == empty) empty;
            
            foreach(items) ::(k, item) {
              @:location = item.data;
              when(location.base.id != 'base:sign') empty;
              location.name = name + '\'s Home';
              targetLocation.name = name;
            }
          }
        }
      }
    }
    
  }
)


Landmark.database.newEntry(
  data: {
    name: 'Home: Inside',
    id: 'base:home-inside-start',
    legendName: '',
    symbol : '',
    rarity : 40,        
    landmarkType : TYPE.BLUEPRINT_SINGLE(:'assets/maps/home-chosen.json'),

    traits :
      TRAIT.PEACEFUL |
      TRAIT.UNIQUE |
      TRAIT.CAN_SAVE |
      TRAIT.NOTHING_HIDDEN |
      TRAIT.STRUCTURE_RESIDENTIAL,
    minEvents : 0,
    maxEvents : 0,
    eventPreference : LandmarkEvent.KIND.PEACEFUL,

    minObjects : 0,
    maxObjects : 0,
    possibleObjects : [
    ],
    requiredObjects : [
    ],
    requiredEvents : [
    ],
    mapHint: {
    },
    events : {
      onLoadContent::(landmark) {

      }
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
    minObjects : 0,
    maxObjects : 0,
    guarded : false,
    canSave : true,
    requiredEvents : [
    ],
    possibleObjects : [],
    requiredObjects : [],
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
    
    minObjects : 0,
    maxObjects : 0,
    guarded : false,
    canSave : true,
    pointOfNoReturn : false,
    ephemeral : false,
    requiredEvents : [
    ],
    possibleObjects : [],
    requiredObjects : [],
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
    minObjects : 0,
    maxObjects : 0,
    pointOfNoReturn : false,
    ephemeral : false,
    requiredEvents : [
    ],
    possibleObjects : [],
    requiredObjects : [],
    mapHint: {},        
    onCreate ::(landmark, island){},
    onVisit ::(landmark, island) {}
  }
)
*/
}


@:makeBlueprintSingle::(this, state, data) {
  @:Map = import(module:'core/map.mt');
  @:Location = import(module:'base/map/location.mt');

  @:buffer = 50;


  // first pick a random pattern 
  @:pattern = random.pickArrayItem(:data.patterns->values)

  @:top = pattern.top + buffer;
  @:left = pattern.left + buffer;
  
  @:map = state.map;
  map.width = pattern.width + top  + buffer;
  map.height = pattern.height + left  + buffer;
  

  foreach(pattern.scenery) ::(k, v) {
    @:next = v;
    
    map.setSceneryIndex(
      x : left + next[0],
      y : top + next[1],
      symbol : map.addScenerySymbol(:next[2])
    )
  }


  foreach(pattern.walls) ::(k, v) {
    @:next = v;
    
    map.enableWall(
      x : left + next[0],
      y : top + next[1]
    )
  }

  foreach(pattern.mapEvents) ::(k, next) {
    this.addEvent(
      id : next[2],
      x : left + next[0],
      y : top + next[1]
    );
  }

  foreach(pattern.mapObjects) ::(k, v) {
    @:next = v;
    
    foreach(next[2]) ::(index, id) {
      @:data = pattern.objects[id];
      @:location = Location.new(
        x : left + next[0],
        y : top + next[1],
        base : Location.database.find(:data.id),
        landmark : this,
        data: data.data
      );
      
      if (data.symbol != '')
        location.symbol = data.symbol
        
      match(data.haloMode) {
        (0): empty,
        (1): location.halo = true,
        (2): location.halo = false
      }
      this.addLocation(
        location,
        width: 1,
        height : 1
      );
    }
  }


  foreach(pattern.areas) ::(k, v) {
    @:next = v;
    map.addArea(:Map.Area.new(
      x : left + next[0],
      y : top + next[1],
      width: next[2],
      height: next[3]
    ));
  }


  



 
}

@:makeBlueprintCollage ::(this, state) {
  error(detail:'Not working yet!');
}

// uses the json blueprint to create a map
@:makeBlueprint::(this, state) {
  @:self = state.base.landmarkType;
  
  if(self.single)
    makeBlueprintSingle(this, state, data:self.data)
  else
    makeBlueprintCollage(this, state, data:self.data)
  
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
    steps: 0,
    data : empty,
    events : empty,
    mapEntityController : empty,
    overrideTitle : '',
    symbol : '',
    legendName : '',
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
      minObjects : Number,
      maxObjects : Number,
      possibleObjects : Object,
      requiredObjects : Object,
      requiredEvents : Object,
      landmarkType: Any,
      mapHint : Object,
      /*
        onCreate : Function,
        onVisit : Function,
        onIncrementTime : Function,
        onStep : Function,
      */
      events : Object,
      traits : Number
    },
    reset,
    knownEvents : [
      'onLoadContent',
      'onCreate',
      'onVisit',
      'onLeave',
      'onIncrementTime',
      'onStep',
      'onAddLocation',
      'onRemoveLocation'
    ]
  ),

  
  define :::(this, state) {
    @:MapEntity = import(module:'base/map/mapentity.mt');
    @:random = import(module:'core/random.mt');
    @:NameGen = import(module:'base/namegen.mt');
    @:DungeonMap = import(module:'base/map/dungeon.mt');
    @:StructureMap = import(module:'base/map/structure.mt');
    @:distance = import(module:'core/distance.mt');
    @:LoadableClass = import(module:'core/data/loadableclass.mt');
    @:Map = import(module:'core/map.mt');
    @:windowEvent = import(module:'core/windowevent.mt');
    @:canvas = import(module:'core/graphics/canvas.mt');
    @:Location = import(module:'base/map/location.mt');
    @:LandmarkEvent = import(module:'base/event/landmark.mt');

    @island_;

    @:world = import(module:'base/world.mt');


    @:nearby = {};
    @:setNearby::(newNearby) {
      @:removed = [];
      @:new = [];

      @:checked = {};
      foreach(newNearby) ::(k, v) {
        checked[v] = true;
        when (nearby[v] == true) empty;
        new->push(:v);
      }

      // get who was removed
      foreach(nearby) ::(k, v) {
        if (checked[k] != true)
          removed->push(:k);   
      }

      foreach(new) ::(k, v) {
        nearby[v] = true;
        v.partyEntered();
        this.map.discover(:v);
      }    
      
      foreach(removed) ::(k, v) {
        nearby->remove(key:v);
        v.partyLeft();
      }    
    }

    
    
    

    
    
    

    @:Entity = import(module:'base/entity.mt');

    @:loadContent::(base) {
    
      @:selected = [];
      @:possibleObjects = [...base.possibleObjects];
      for(0, random.integer(from:base.minObjects, to:base.maxObjects))::(i) {
        when(possibleObjects->keycount == 0) empty;
        @:which = random.pickArrayItemWeighted(list:possibleObjects);
        selected->push(:which);
        if (base.landmarkType == TYPE.DUNGEON && Location.database.find(id:which.id).hasTraits(:Location.TRAIT.ONE_PER_LANDMARK)) ::<= {
          possibleObjects->remove(key:possibleObjects->findIndex(value:which));
        }
      }        
      
      @:setupLocations = ::(objects) {
        foreach(objects) ::(k, v) {
          @:loc = this.createLocationFromSpecification(:v);
          this.addLocation(location:loc);
        }
      }
      
      
      if (base.landmarkType.blueprint) {
        state.map = Map.new(parent:this);
        makeBlueprint(this, state); 
      } else
      if (base.landmarkType == TYPE.DUNGEON) ::<= {
        state.map = DungeonMap.create(parent:this, mapHint: base.mapHint);
        @entrance;
        if (base.hasTraits(:Landmark.TRAIT.DUNGEON_FORCE_ENTRANCE)) ::<= {
          entrance = Location.new(landmark: this, base:Location.database.find(:'base:ladder'));
          this.addLocation(location:entrance);
        }
        setupLocations(:[...base.requiredObjects, ...selected]);

        if (base.hasTraits(:Landmark.TRAIT.DUNGEON_FORCE_ENTRANCE)) ::<= {
          breakpoint();
          state.map.setPointer(x:entrance.x, y:entrance.y);
        } else {
          this.movePointerToRandomArea();        
        }

      } else if (base.landmarkType == TYPE.STRUCTURE) ::<= {        
        // handles portal adding and such
        state.map = Map.new(parent:this);
        StructureMap(
          mapHint:base.mapHint, 
          landmark:this,
          objects : [...base.requiredObjects, ...selected]
        );
      } else ::<= {
        state.map = Map.new(parent:this);
      }


      
      /*
      [0, Random.integer(from:base.minObjects, to:base.maxObjects)]->for(do:::(i) {
        locations->push(value:island.newInhabitant());      
      });
      */
   







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
                       alreadyEvents->findIndex(:value.id) == -1 &&
                       value.tier <= island_.tier
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
      this.base.emit(event:'onLoadContent', landmark:this);    
      

    }
    

    


    this.interface =  {
      initialize ::(parent, island) {
        @:Island = import(module:'base/map/island.mt');
        if (parent->type == Island.type)
          island = parent
        else if (parent)
          island = parent.parent; // parents of locations are always maps

        // backup: just take the current world's island
        if (island == empty)  
          island = import(:'base/world.mt').island;
          
        if (island == empty)
          error(:'A landmark MUST be initialized with an island or parent.');
        island_ = island;
      },

      defaultLoad::(base, x, y, floorHint, data){
        state.worldID = world.getNextID();
        state.x = 0;
        state.y = 0;
        state.floor = 0;
        state.steps = 0;
        state.events = [];
        state.symbol = base.symbol;
        state.legendName = base.legendName;
        if (data != empty)
          state.data = data
        else
          state.data = {};

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


        this.base.emit(event:'onCreate', landmark:this, island:island_);    
        
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
        get ::<- state.map.width
      },
      height : {
        get ::<- state.map.height
      },
      
      peaceful : {
        get :: <- state.peaceful,
        set ::(value) <- state.peaceful = value
      },

      floor : {
        get :: <- state.floor
      },

      // adds a special location that teleports to a different landmark 
      // within the same island.     
      //
      // Portal data can contain:
      /*
      {
        // the ID of a landmark to warp to.
        // Landmarks created this way are generated on-the-fly 
        // upon first visiting the portal. 
        id: 'landmark-id',
        
        // optional symbol to identify the structure associated with the portal
        // More often than not override symbols are blank
        symbol : '*',
        
        // public name to use for the portal
        name : '',
      
        // Optional any-data to pass to the landmark 
        data : {
          someData : thing
        }
      }
      */
      addPortal ::(x, y, portalData) {
        if (portalData.symbol == empty)
          portalData.symbol = '';

        @:location = Location.new(
          landmark: this,
          base:Location.database.find(:'base:portal'), 
          x, 
          y,
          data: portalData
        );
        
        location.halo = false;
        location.symbol = '';


        this.addLocation(
          location
        );
        return location;
      },


      // enters the travel ui state, bringing the user to the 
      // interactive travel menu for this landmark.
      //
      // onLoad is called within the "loading spot" of the transition 
      //
      // onReady is called in a queued event RIGHT before 
      // the cursorMove event for the travel.
      //
      // startAnimationRenderable is a renderable that will be used 
      // for the starting visual for the transition animation.
      //
      // skipAnimation is whether to skip the transition from the travel
      travel ::(onLoad, onReady, startAnimationRenderable, skipAnimation) {      
        @:world = import(module:'base/world.mt');
        if (world.landmark != this) ::<= {
          error(:'The current landmark isnt the one being traveled to!')
        }
        @:jumpTag = 'LANDMARK_VISIT' + this.worldID;

        @:hud = import(:'core/graphics/hud.mt');
        @:windowEvent = import(module:'core/windowevent.mt');
        @:partyOptions = import(module:'base/widgets/partyoptions.mt');
        @:Island = import(module:'base/map/island.mt');


        @:party = world.party;
        @:landmark = this;
        landmark.updateTitle();
        @:island = this.island;                    
        
        windowEvent.removeTag(:jumpTag)


        
        @stepCount = 0;
        @choiceActions = [];

        @:landmarkChoices = ::{
          @landmarkOptions;
          windowEvent.queueChoices(
            leftWeight: 1,
            topWeight: 1,
            prompt: 'What next?',
            keep:true,
            canCancel:true,
            jumpTag:'LANDMARK_TRAVEL',
            onGetChoices ::{
              landmarkOptions = [...world.scenario.base.interactionsWalk]->filter(by::(value) <- value.filter(island, landmark));
              
              choiceActions = [];
              @:choices = [];
              @locationAt = landmark.map.getNamedItemsUnderPointerRadius(:3);
              if (locationAt != empty) ::<= {
                foreach(locationAt)::(i, loc) {
                  if (loc.data.canInteract()) ::<= {
                    choices->push(value:'Check ' + loc.name);
                    choiceActions->push(::{
                      locationAt = loc.data;
                      locationAt.interact();                  
                    });
                  }
                }
              }              
              
              foreach(landmarkOptions) ::(k, value) {
                choices->push(:value.name);
                choiceActions->push(::{
                  value.select(island, landmark);                
                });       
              }
              
              choices->push(value: 'Options');
              choiceActions->push(::{
                @:options = [...world.scenario.base.interactionsOptions]->filter(by::(value) <- value.filter(island, landmark));
                @:choices = [...options]->map(to::(value) <- value.name);

                windowEvent.queueChoices(
                  leftWeight: 1,
                  topWeight: 1,
                  prompt: 'Options',
                  canCancel : true,
                  keep: true,
                  choices,
                  onChoice::(choice) {
                    when(choice == 0) empty;
                    options[choice-1].select(island, landmark);
                  }
                );              
              });
              


              return choices;        
            },
            onChoice::(choice) {
              choiceActions[choice-1]();
            }
          );
        }

        @cursorMoveRenderable = {
          render::{
            if (onReady != empty) {
              onReady();
              onReady = empty;
            } 

            this.visit();
            when(landmark.map == empty) canvas.fill();
            landmark.map.render();

            hud.render(island, landmark);
            
            when(nearby == empty || nearby->keycount == 0) empty;
            
            @:nearbySet = nearby->keys;
            nearbySet->sort(::(a, b) <- a.name < b.name)
            
            @:lines = [];
            foreach(nearbySet)::(index, arr) {
              lines->push(value:arr.name);
            }
            canvas.renderTextFrameGeneral(
              leftWeight: 1,
              topWeight: 1,
              lines,
              title: 'Arrived at:'
            );
          }
        };
        
        @:startup ::{
          this.loadContent();
          @where = onLoad
          if (where != empty) ::<= {
            where(landmark);
          }
        }
        
        if (skipAnimation != true)
          windowEvent.queueTransition(
            kind:windowEvent.TRANSITION.FADE_TO_BLACK, 
            renderableStart: if (startAnimationRenderable == empty) empty else ({
              render :: {
                startAnimationRenderable.render();
              }
            }),
            renderableMiddle: {
              render :: {
                startup();
                landmark.map.render();
              }
            }
          )


        windowEvent.queueCursorMove(
          jumpTag,
          onMenu ::{
            landmarkChoices()
          },
          renderable: cursorMoveRenderable,
          onMove ::(choice) {
          
            // move by one unit in that direction
            // or ON it if its within one unit.
            when(!landmark.map.movePointerAdjacent(
              x: if (choice == windowEvent.CURSOR_ACTIONS.RIGHT) 1 else if (choice == windowEvent.CURSOR_ACTIONS.LEFT) -1 else 0,
              y: if (choice == windowEvent.CURSOR_ACTIONS.DOWN)  1 else if (choice == windowEvent.CURSOR_ACTIONS.UP)   -1 else 0
            )) empty;
            world.incrementTime(isStep:true);
            landmark.step();
            stepCount += 1;

            
            // every 5 steps, heal 1% HP if below 1/5th health
            if (stepCount % 15 == 0) ::<= {
              foreach(party.members)::(i, member) {
                if (member.hp < member.stats.HP * 0.2)
                  member.heal(amount:(member.stats.HP * 0.01)->ceil);
              }
            }
            
            // cancel if we've arrived somewhere
            @:locations = landmark.map.getNamedItemsUnderPointerRadius(:3)->map(::(value) <- value.data)
            setNearby(:locations->filter(::(value) <- value.base.hasNoTrait(:Location.TRAIT.INVISIBLE)));
          }        
        )      
        if (skipAnimation == true)
          startup();



      },

      // Makes this landmark the "current" landmark that 
      // the party is within.
      //
      visit ::  {
        @:landmark = this;
        @:world = import(module:'base/world.mt');
        when(world.landmark == this) empty;
        when (state.base.emit(event:'onVisit', landmark:this, island:landmark.island) == false) empty;

        if (world.landmark)
          world.landmark.leave();
          
          
        @:old = world.landmark;
        world.landmark = this;  

        foreach(world.party.members) ::(k, v) {
          v.addOpinion(
            fullName : 'the ' + landmark.name
          );
        }
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
        
        state.base.emit(event:'onIncrementTime');
        
        foreach(this.locations) ::(k, v) {
          v.incrementTime();
        }

        foreach(state.events) ::(k, event) {
          event.incrementTime();
        }
      },

      steps : {
        get ::<- state.steps
      },

      // represents a step made within the landmark.
      step :: {
        state.base.emit(event:'onStep', landmark:this, island:this.island);
        state.mapEntityController.step();

        foreach(world.party.quests) ::(k, v) {
          v.step(landmark:this, island:this.island);
        }

        foreach(state.events) ::(k, event) {
          event.step();
        }
        



        
        foreach(state.events) ::(k, event) {
          event.step();
        }

        @:locations = state.map.getItemsUnderPointer();
        if (locations->type == Object) ::<= {
          foreach(locations) ::(k, v) {
            if (v.data->type == Location.type) ::<= {
              v.data.base.emit(event:'onStep', entities: world.party.members, location:v.data);
            }
          }
        }
        world.party.step();
        state.steps += 1;                


        when(state.base.landmarkType == TYPE.STRUCTURE) ::<= {
          if (this.peaceful == false) ::<= {
            if (((state.steps != 0) && state.steps % 30 == 0) && random.number() > 0.7) ::<= {
              @:Scene = import(module:'base/scene.mt');            
              Scene.start(id:'base:scene_guards0', onDone::{}, location:empty, landmark:this);
            }
          }
        }
        
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
        @:world = import(module:'base/world.mt');
        @:windowEvent = import(module:'core/windowevent.mt');
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
        when (state.map.areas->size == 0) empty;
        @:area = state.map.getRandomEmptyArea();
        return { 
          x:area.x + (area.width/2)->floor,
          y:area.y + (area.height/2)->floor
        }
      },
      
      data : {
        get ::<- state.data
      },

      addEvent ::(id, x, y) {
        state.events->push(value:
          LandmarkEvent.new(
            parent: this,
            base: id
          )
        );      
      },
      
      removeEvent ::(event => LandmarkEvent.type) {
        state.events = state.events->filter(::(value) <- value != event);
      },


      removeLocation ::(location => Location.type) {
        when (state.map.getItem(:location) == empty) empty;
        state.map.removeItem(data:location);
        windowEvent.invalidateCache(:'VisitLandmark');
        state.base.emit(event:'onRemoveLocation', landmark:this, location);

      },
      




      addLocation ::(location, width, height, traits) {
        location.landmark = this;
        @:loc = location;
        
        
        if (traits == empty)
          traits = 0
          
        if (loc.halo)
          traits |= Map.TRAIT.HAS_HALO;
        

        
        if (state.base.hasTraits(:TRAIT.NOTHING_HIDDEN) || location.base.hasTraits(:Location.TRAIT.INVISIBLE))
          traits |= Map.TRAIT.DISCOVERED
             
        @:defaultAdd ::{
          when (width == empty && height == empty)
            state.map.setItem(data:loc, x:loc.x, y:loc.y, symbol: loc.symbol, traits, name:loc.name);
          for(loc.x, width + loc.x) ::(ix) {
            for(loc.y, height + loc.y) ::(iy) {
              state.map.setItem(data:loc, x:ix, y:iy, symbol: loc.symbol, traits, name:loc.name);            
            }
          }
                
        }

        if (state.base.landmarkType == TYPE.DUNGEON) ::<= {
          if (loc.x == 0 && loc.y == 0) {
            @:pos = state.map.setItem(data:loc, area:state.map.getRandomEmptyArea(), symbol: loc.symbol, traits, name:loc.name)
            loc.x = pos.x
            loc.y = pos.y;
          } else
            defaultAdd();
          
        } else
          defaultAdd();

        windowEvent.invalidateCache(:'VisitLandmark');
        state.base.emit(event:'onAddLocation', landmark:this, location);
        return loc;      

      },
      
      moveLocation ::(location) {
        
      },
      
      leave ::{
        state.base.emit(event:'onLeave', landmark:this, island:this.island)
        setNearby(:[]);
      },
      
      island : {
        get ::<- island_
      },

      // creates a location from a Landmark object specification
      createLocationFromSpecification::(spec) {
        @:Location = import(module:'base/map/location.mt');
        @:loc = Location.new(
          landmark: this,
          base: Location.database.find(:spec.id),
          data : spec.data
        );
        
        if (spec.overrideSymbol != empty) ::<= {
          spec.overrideSymbol => String
          loc.symbol = spec.overrideSymbol
        }
          
        if (spec.overrideName != empty) ::<= {
          spec.overrideName => String
          loc.name = spec.overrideName
        }
      
        return loc
      },
      
      map : {
        get ::<- state.map
      }
    }
  }
);


return Landmark;
