@:WyvernGate = import(:'wyvern-gate.mt');

@:Item = WyvernGate.Item
@:StatSet = WyvernGate.Util.StatSet
@:windowEvent = WyvernGate.Core.WindowEvent

@:Landmark = WyvernGate.Map.Landmark
@:DungeonMap = WyvernGate.Map.Dungeon
@:LandmarkEvent = WyvernGate.Event.Landmark
@:Location = WyvernGate.Map.Location

breakpoint();
return ::{
  Landmark.database.newEntry(
    data: {
      name: 'Shrine: Lost Floor',
      id: 'thechosen:shrine-lost-floor',
      symbol : 'M',
      legendName: 'Shrine',
      rarity : 100000,  
      traits : 
        Landmark.TRAIT.UNIQUE |
        Landmark.TRAIT.PEACEFUL |
        Landmark.TRAIT.EPHEMERAL |
        Landmark.TRAIT.POINT_OF_NO_RETURN,
      minEvents : 0,
      maxEvents : 0,
      eventPreference : LandmarkEvent.KIND.PEACEFUL,

      minObjects : 2,
      maxObjects : 2,
      landmarkType : Landmark.TYPE.DUNGEON,
      requiredEvents : [
      ],
      possibleObjects : [
        {id: 'base:small-chest', rarity:3},
      ],
      requiredObjects : [
        {id: 'thechosen:final-stairs'},
        {id: 'base:small-chest'},
        {id: 'base:enchantment-stand'}
      ],
      mapHint:{},
      events : {
      
        onVisit ::(landmark, island) {
          @:canvas = import(module:'core/graphics/canvas.mt');
          @:windowEvent = import(module:'core/windowevent.mt');
          windowEvent.queueMessage(text:'It seems this area has been long forgotten...');
        }
      }        
    }
  ) 



  Landmark.database.newEntry(
    data: {
      name : 'Shrine of Fire',
      id : 'thechosen:shrine-of-fire',
      legendName: 'Shrine',
      symbol : 'M',
      rarity : 100000,    
      minObjects : 1,
      maxObjects : 2,
      landmarkType : Landmark.TYPE.DUNGEON,
      traits : 
        Landmark.TRAIT.UNIQUE |
        Landmark.TRAIT.POINT_OF_NO_RETURN |
        Landmark.TRAIT.EPHEMERAL,

      minEvents : 0,
      maxEvents : 2,
      eventPreference : LandmarkEvent.KIND.HOSTILE,

      requiredEvents : [
        'base:creature-encounters'
      ],
      possibleObjects : [
  //          {id: 'Stairs Down', rarity:1},

        // the standard set
        {id: 'base:fountain', rarity:18},
        {id: 'base:potion-shop', rarity: 100},
        {id: 'base:wyvern-statue', rarity: 15},
        {id: 'base:enchantment-stand', rarity: 35},


        {id: 'base:healing-circle', rarity:30},


        {id: 'base:clothing-shop', rarity: 100},
        {id: 'base:fancy-shop', rarity: 500}

      ],
      requiredObjects : [
        {id: 'thechosen:stairs-down'},
        {id: 'thechosen:stairs-down'},
        {id: 'base:item'},
        {id: 'base:item'}
      ],
      mapHint:{
        layoutType: DungeonMap.LAYOUT_ALPHA
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
      name : 'Shrine of Ice',
      id : 'thechosen:shrine-of-ice',
      legendName: 'Shrine',
      symbol : 'M',
      rarity : 100000,    
      minObjects : 1,
      maxObjects : 4,
      landmarkType : Landmark.TYPE.DUNGEON,
      traits : 
        Landmark.TRAIT.UNIQUE |
        Landmark.TRAIT.POINT_OF_NO_RETURN |
        Landmark.TRAIT.EPHEMERAL,

      minEvents : 1,
      maxEvents : 3,
      eventPreference : LandmarkEvent.KIND.HOSTILE,


      requiredEvents : [
        'base:dungeon-encounters',
        'base:item-specter',
      ],
      possibleObjects : [
  //          {id: 'Stairs Down', rarity:1},
        {id: 'base:fountain', rarity:18},
        {id: 'base:wyvern-statue', rarity: 15},
        {id: 'base:small-chest', rarity: 36},
        {id: 'base:locked-chest', rarity: 22},
        {id: 'base:magic-chest', rarity: 40},
        {id: 'base:healing-circle', rarity:20},

        {id: 'base:potion-shop', rarity: 100},
        {id: 'base:clothing-shop', rarity: 300},
        {id: 'base:fancy-shop', rarity: 500},
      ],
      requiredObjects : [
        {id: 'thechosen:stairs-down'},
        {id: 'base:item'},
        {id: 'base:item'},
        {id: 'base:enchantment-stand'}
        
      ],
      mapHint:{
        layoutType: DungeonMap.LAYOUT_BETA
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
      name : 'Shrine of Thunder',
      id : 'thechosen:shrine-of-thunder',
      symbol : 'M',
      legendName: 'Shrine',
      rarity : 100000,    
      minObjects : 2,
      maxObjects : 4,
      landmarkType : Landmark.TYPE.DUNGEON,
      traits : 
        Landmark.TRAIT.UNIQUE |
        Landmark.TRAIT.POINT_OF_NO_RETURN |
        Landmark.TRAIT.EPHEMERAL,

      minEvents : 1,
      maxEvents : 3,
      eventPreference : LandmarkEvent.KIND.HOSTILE,

      requiredEvents : [
        'base:dungeon-encounters',
        'base:item-specter',
      ],
      possibleObjects : [
  //          {id: 'Stairs Down', rarity:1},
        {id: 'base:fountain', rarity:18},
        {id: 'base:potion-shop', rarity: 17},
        {id: 'base:wyvern-statue', rarity: 15},
        {id: 'base:locked-chest', rarity: 40},
        {id: 'base:magic-chest', rarity: 60},

        {id: 'base:healing-circle', rarity:25},

        {id: 'base:clothing-shop', rarity: 80},
        {id: 'base:fancy-shop', rarity: 100}

      ],
      requiredObjects : [
        {id: 'thechosen:stairs-down'},
        {id: 'base:item'},
        {id: 'base:item'},

        {id: 'base:warp-point'},
        {id: 'base:enchantment-stand'}
      ],
      mapHint:{
        layoutType: DungeonMap.LAYOUT_GAMMA
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
      name : 'Shrine of Light',
      id : 'thechosen:shrine-of-light',
      symbol : 'M',
      legendName: 'Shrine',
      rarity : 100000,    
      minObjects : 2,
      maxObjects : 4,
      landmarkType : Landmark.TYPE.DUNGEON,

      traits : 
        Landmark.TRAIT.UNIQUE |
        Landmark.TRAIT.POINT_OF_NO_RETURN |
        Landmark.TRAIT.EPHEMERAL,

      minEvents : 1,
      maxEvents : 5,
      eventPreference : LandmarkEvent.KIND.HOSTILE,


      requiredEvents : [
        'base:dungeon-encounters',
        'base:item-specter'
      ],
      possibleObjects : [
  //          {id: 'Stairs Down', rarity:1},
        {id: 'base:fountain', rarity:18},
        {id: 'base:potion-shop', rarity: 17},
        {id: 'base:wyvern-statue', rarity: 15},
        {id: 'base:small-chest', rarity: 16},
        {id: 'base:locked-chest', rarity: 40},
        {id: 'base:magic-chest', rarity: 15},

        {id: 'base:healing-circle', rarity:35},

        {id: 'base:clothing-shop', rarity: 100},
        {id: 'base:fancy-shop', rarity: 50}

      ],
      requiredObjects : [
        {id: 'thechosen:stairs-down'},
        {id: 'base:small-chest'},
        {id: 'base:enchantment-stand'},
        
        {id: 'base:warp-point'},
        {id: 'base:warp-point'}          
      ],
      mapHint:{
        layoutType: DungeonMap.LAYOUT_DELTA
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
      name : 'Fire Wyvern Dimension',
      id : 'thechosen:fire-wyvern-dimension',
      legendName: '???',
      symbol : 'M',
      rarity : 1,    
      minObjects : 2,
      maxObjects : 2,
      traits : 
        Landmark.TRAIT.UNIQUE   |
        Landmark.TRAIT.PEACEFUL |
        Landmark.TRAIT.EPHEMERAL,

      minEvents : 0,
      maxEvents : 0,
      eventPreference : LandmarkEvent.KIND.PEACEFUL,
      landmarkType : Landmark.TYPE.DUNGEON,

      
      requiredEvents : [
      ],
      possibleObjects : [
      ],
      requiredObjects : [
        {id: 'thechosen:throne-fire'},
      ],
      
      mapHint : {
        roomSize: 20,
        roomAreaSize: 15,
        roomAreaSizeLarge: 15,
        emptyAreaCount: 1,
        wallCharacter: ' '
        
      },
      events : {}        
    }
  )    



  Landmark.database.newEntry(
    data: {
      name : 'Ice Wyvern Dimension',
      id : 'thechosen:ice-wyvern-dimension',
      legendName: '???',
      symbol : 'M',
      rarity : 1,    
      minObjects : 2,
      maxObjects : 2,
      landmarkType : Landmark.TYPE.DUNGEON,
      traits : 
        Landmark.TRAIT.UNIQUE   |
        Landmark.TRAIT.PEACEFUL |
        Landmark.TRAIT.EPHEMERAL,

      minEvents : 0,
      maxEvents : 0,
      eventPreference : LandmarkEvent.KIND.PEACEFUL,


      requiredEvents : [
      ],
      possibleObjects : [
      ],
      requiredObjects : [
        {id: 'thechosen:throne-ice'},
      ],
      
      mapHint : {
        roomSize: 20,
        roomAreaSize: 15,
        roomAreaSizeLarge: 15,
        emptyAreaCount: 1,
        wallCharacter: ' '
        
      },
      events : {}
      
    }
  ) 

  Landmark.database.newEntry(
    data: {
      name : 'Thunder Wyvern Dimension',
      id : 'thechosen:thunder-wyvern-dimension',
      legendName: '???',
      symbol : 'M',
      rarity : 1,    
      minObjects : 2,
      maxObjects : 2,
      landmarkType : Landmark.TYPE.DUNGEON,
      traits : 
        Landmark.TRAIT.UNIQUE   |
        Landmark.TRAIT.PEACEFUL |
        Landmark.TRAIT.EPHEMERAL,

      minEvents : 0,
      maxEvents : 0,
      eventPreference : LandmarkEvent.KIND.PEACEFUL,

      requiredEvents : [
      ],
      possibleObjects : [
      ],
      requiredObjects : [
        {id: 'thechosen:throne-thunder'},
      ],
      
      mapHint : {
        roomSize: 20,
        roomAreaSize: 15,
        roomAreaSizeLarge: 15,
        emptyAreaCount: 1,
        wallCharacter: ' '
        
      },
      events : {}
    }
  ) 


  Landmark.database.newEntry(
    data: {
      name : 'Light Wyvern Dimension',
      id : 'thechosen:light-wyvern-dimension',
      legendName: '???',
      symbol : 'M',
      rarity : 1,    
      minObjects : 2,
      maxObjects : 2,
      landmarkType : Landmark.TYPE.DUNGEON,
      traits : 
        Landmark.TRAIT.UNIQUE   |
        Landmark.TRAIT.PEACEFUL |
        Landmark.TRAIT.EPHEMERAL,

      minEvents : 0,
      maxEvents : 0,
      eventPreference : LandmarkEvent.KIND.PEACEFUL,

      requiredEvents : [
      ],
      possibleObjects : [
      ],
      requiredObjects : [
        {id: 'thechosen:throne-light'},
      ],
      
      mapHint : {
        roomSize: 20,
        roomAreaSize: 15,
        roomAreaSizeLarge: 15,
        emptyAreaCount: 1,
        wallCharacter: ' '
        
      },
      events : {}
      
    }
  ) 
  



  Landmark.database.newEntry(
    data: {
      name : 'Dark Lair',
      id : 'thechosen:dark-lair',
      symbol : 'M',
      legendName: 'Shrine',
      rarity : 100000,    
      minObjects : 0,
      maxObjects : 4,

      traits : 
        Landmark.TRAIT.UNIQUE |
        Landmark.TRAIT.POINT_OF_NO_RETURN |
        Landmark.TRAIT.EPHEMERAL,

      minEvents : 1,
      maxEvents : 6,
      eventPreference : LandmarkEvent.KIND.HOSTILE,


      landmarkType : Landmark.TYPE.DUNGEON,
      requiredEvents : [
        'base:damned-souls',
      ],
      possibleObjects : [
  //          {id: 'Stairs Down', rarity:1},
        {id: 'base:fountain', rarity:18},
        {id: 'base:potion-shop', rarity: 17},
        {id: 'base:wyvern-statue', rarity: 15},
        {id: 'base:small-chest', rarity: 16},
        {id: 'base:locked-chest', rarity: 11},
        {id: 'base:magic-chest', rarity: 15},

        {id: 'base:Healing Circle', rarity:35}

      ],
      requiredObjects : [
        {id: 'base:enchantment-stand'},
        {id: 'base:stairs-up'},
        {id: 'base:locked-chest'},
        {id: 'base:Small-chest'}
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
    data : {
      name : 'Dark Lair - Entrance',
      id : 'thechosen:dark-lair-entrance',
      legendName : 'Dark Lair',
      symbol : '#',
      rarity : 100000,
      minObjects : 0,
      maxObjects : 0,
      traits : 
        Landmark.TRAIT.UNIQUE |
        Landmark.TRAIT.POINT_OF_NO_RETURN |
        Landmark.TRAIT.PEACEFUL,

      minEvents : 0,
      maxEvents : 0,
      eventPreference : LandmarkEvent.KIND.PEACEFUL,



      landmarkType : Landmark.TYPE.CUSTOM,
      requiredEvents : [],
      possibleObjects : [
      ],
      requiredObjects : [
      ],
      mapHint : {
      },
      
      events : {
        onLoadContent ::(landmark, island){
          @:map = landmark.map;
          map.width = 100;
          map.height = 60;
          map.undefinedCharacter = '.'
          
          
          @:CASTLE_MAIN_X = 30;
          @:CASTLE_MAIN_HEIGHT = 13;
          @:CASTLE_MAIN_WIDTH = 32;
          @:CASTLE_WINDOW_HEIGHT = 3;
          
          @:CASTLE_EXT_HEIGHT = 18;

          @:PATH_HEIGHT = 22;



          // main castle
          map.paintScenerySolidRectangle(
            x: CASTLE_MAIN_X,
            y: 0,
            width: CASTLE_MAIN_WIDTH,
            height: CASTLE_MAIN_HEIGHT,
            symbol : map.addScenerySymbol(
              character: '▓'
            ),
            isWall:true
          );
          
          map.paintScenerySolidRectangle(
            x: 0,
            y: 0,
            width: CASTLE_MAIN_X,
            height: CASTLE_EXT_HEIGHT,
            symbol : map.addScenerySymbol(
              character: '▓'
            ),
            isWall:true
          );
          
          map.paintScenerySolidRectangle(
            x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH,
            y: 0,
            width: map.width - (CASTLE_MAIN_X + CASTLE_MAIN_WIDTH)-1,
            height: CASTLE_EXT_HEIGHT,
            symbol : map.addScenerySymbol(
              character: '▓'
            ),
            isWall:true
          );
          

          map.paintScenerySolidRectangle(
            x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH/2 - 2,
            y: CASTLE_MAIN_HEIGHT - 1,
            width: 4,
            height: 1,
            symbol : map.addScenerySymbol(
              character: ' '
            ),
            isWall:false
          );
          
          @:l = landmark.addLocation(
            location: Location.new(
              landmark: landmark,
              base:Location.database.find(id: 'thechosen:foreboding-entrance'),
              x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH/2 - 2,
              y: CASTLE_MAIN_HEIGHT - 1
            ),
            width: 4,
            height: 1
          );


          // castle details 
          // grows down
          @:makeWindow ::<= {
            @:emp = map.addScenerySymbol(character: ' ');
            return ::(x, y) {
              map.paintScenerySolidRectangle(
                x,
                y,
                width: 1,
                height: CASTLE_WINDOW_HEIGHT,
                symbol: emp,
                isWall : false
              );
            }
          }

          @:makeWindowPair::(x, y) {
            makeWindow(x, y);
            makeWindow(x:x+2, y);
          }





          for(0, 2) ::(y) {

            for(0, 2) ::(i) {          
              makeWindowPair(
                x: CASTLE_MAIN_X + 1 + i * 5, 
                y: CASTLE_MAIN_HEIGHT - CASTLE_WINDOW_HEIGHT - 2 - y*(CASTLE_WINDOW_HEIGHT + 2));
            }

            for(0, 2) ::(i) {          
              makeWindowPair(
                x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH - 4 - i * 5, 
                y: CASTLE_MAIN_HEIGHT - CASTLE_WINDOW_HEIGHT - 2 - y*(CASTLE_WINDOW_HEIGHT + 2));
            }
          }


          for(0, 3) ::(y) {
            for(0, 5) ::(i) {          
              makeWindowPair(
                x: CASTLE_MAIN_X - (1 + 4 + i * 5), 
                y: CASTLE_EXT_HEIGHT - CASTLE_WINDOW_HEIGHT - 2 - y*(CASTLE_WINDOW_HEIGHT + 2) + 1);
            }

            for(0, 5) ::(i) {          
              makeWindowPair(
                x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH + (2 + i * 5), 
                y: CASTLE_EXT_HEIGHT - CASTLE_WINDOW_HEIGHT - 2 - y*(CASTLE_WINDOW_HEIGHT + 2) + 1);
            }
          }







          // pathway 

          map.paintScenerySolidRectangle(
            x: 0,
            y: CASTLE_EXT_HEIGHT,
            width: CASTLE_MAIN_X+CASTLE_MAIN_WIDTH/2-2,
            height: PATH_HEIGHT,
            symbol : map.addScenerySymbol(
              character: '.'
            ),
            isWall:true
          );

          map.paintScenerySolidRectangle(
            x: CASTLE_MAIN_X+CASTLE_MAIN_WIDTH/2+2,
            y: CASTLE_EXT_HEIGHT,
            width: map.width - CASTLE_MAIN_X+CASTLE_MAIN_WIDTH/2-1,
            height: PATH_HEIGHT,
            symbol : map.addScenerySymbol(
              character: '.'
            ),
            isWall:true
          );


          map.paintScenerySolidRectangle(
            x: 0,
            y: CASTLE_EXT_HEIGHT + PATH_HEIGHT,
            width: map.width-1,
            height: map.height - (CASTLE_EXT_HEIGHT + PATH_HEIGHT) - 1,
            symbol : map.addScenerySymbol(
              character: '.'
            ),
            isWall:true
          );
          

          map.paintScenerySolidRectangle(
            x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH/2 - 5,
            y: CASTLE_EXT_HEIGHT + PATH_HEIGHT - 3,
            width: 10,
            height: 6,
            symbol : map.addScenerySymbol(
              character: ' '
            ),
            isWall:false
          );





            



          map.setPointer(
            x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH / 2,
            y: CASTLE_EXT_HEIGHT + PATH_HEIGHT
          );
          
          map.paged = false;

        
        },
      }
    }
  );  
  
}
