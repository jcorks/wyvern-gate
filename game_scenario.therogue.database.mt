@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'game_class.database.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Item = import(module:'game_mutator.item.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:random = import(module:'game_singleton.random.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:namegen = import(module:'game_singleton.namegen.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:InteractionMenuEntry = import(module:'game_struct.interactionmenuentry.mt');
@:commonInteractions = import(module:'game_singleton.commoninteractions.mt');
@:Personality = import(module:'game_database.personality.mt');
@:g = import(module:'game_function.g.mt');
@:Accolade = import(module:'game_struct.accolade.mt');
@:loading = import(module:'game_function.loading.mt');
@:romanNum = import(module:'game_function.romannumerals.mt');
@:ParticleEmitter = import(module:'game_class.particle.mt');
@:Landmark = import(module:'game_mutator.landmark.mt');
@:Island = import(module:'game_mutator.island.mt');
@:Species = import(module:'game_database.species.mt');
@:LandmarkEvent = import(module:'game_mutator.landmarkevent.mt');
@:DungeonMap = import(:'game_singleton.dungeonmap.mt');
@:Profession = import(module:'game_database.profession.mt');
@:Arts = import(module:'game_database.arts.mt');
@:Entity = import(module:'game_class.entity.mt');
@:Location = import(module:'game_mutator.location.mt');
@:State = import(module:'game_class.state.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:world = import(module:'game_singleton.world.mt');
@:pickItem = import(:'game_function.pickitem.mt');
@:Interaction = import(module:'game_database.interaction.mt');




return ::{
Location.database.newEntry(data:{
  name: 'Stairs Down',
  id: 'therogue:stairs-down',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '\\',
  category : Location.CATEGORY.EXIT,
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
    "Decrepit stairs",
  ],
  interactions : [
    'therogue:next-floor',
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  
  onFirstInteract ::(location) {},
  onInteract ::(location) {
    @open = location.isUnlockedWithPlate();
    if (!open)  
      windowEvent.queueMessage(text: 'The entry to the stairway is locked. Perhaps some lever or plate nearby can unlock it.');
    return open;      
  },
  
  onCreate ::(location) {
    if (location.landmark.island.tier > 1) 
      if (random.flipCoin()) ::<= {
        location.lockWithPressurePlate();
      }
    
  },
  onStep ::(location, entities) {
  
  },
  
  onIncrementTime::(location, time) {
  
  }
})



Location.database.newEntry(data:{
  name: 'Gold',
  id: 'therogue:gold',
  rarity: 1000000000000,
  ownVerb : 'owned',
  symbol: 'G',
  category : Location.CATEGORY.UTILITY,
  minStructureSize : 1,
  onePerLandmark : false,

  descriptions: [
    'An spare pile of G.'
  ],
  interactions : [
    'base:take'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract::(location){},      
  onInteract ::(location) {
  },
  onStep ::(location, entities) {
  
  },  
  onCreate ::(location) {
    @mark = random.integer(
      from:1, 
      to:((location.landmark.island).level - 6)*2
    )
    location.inventory.addGold(:mark*10);
  },
  
  onIncrementTime::(location, time) {
  
  }
}) 

Interaction.newEntry(
  data : {
    name : 'Check Vault',
    id :  'therogue:check-vault',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:theRogue = import(:'game_scenario.therogue.mt').context;
      when (theRogue.unlocks & theRogue.UNLOCKS.VAULT == 0) 
        windowEvent.queueMessage(text: 'It seems locked.'); 
    
      @:xferItems = ::(from, to, moveToName) {
        pickItem(
          tabbed: true,
          inventory:from,
          leftWeight: 0.5,
          topWeight: 0.5,
          canCancel:true, 
          pageAfter:12,
          showRarity:true,
          header : ['Item', 'Value', ''],
          onPick::(item) {
            @:choiceItem = item;
            when(choiceItem == empty) empty;
            windowEvent.queueChoices(
              leftWeight: 0.5,
              topWeight: 0.5,
              prompt: choiceItem.name,
              canCancel : true,
              keep:true,
              jumpTag : 'BANKING-ITEM',
              choices: [
                'Check',
                'Move to ' + moveToName
              ],
              onChoice::(choice) {
                when (choice == 0) empty;        
                when (choice == 1) choiceItem.describe();
                when (choice == 2) ::<= {
                  if (to.isFull) ::<= {
                    windowEvent.queueMessage(
                      text: 'Inventory is full.'
                    );
                  } else ::<= {
                    from.remove(:choiceItem);
                    to.add(:choiceItem);
                  }
                  windowEvent.jumpToTag(name: 'BANKING-ITEM', goBeforeTag: true);
                }
              }
            );
          }
        );         
      }
    
      @:bankedItems = ::{
        @:inv = world.party.bank;
        when(inv.isEmpty) ::<= {
          windowEvent.queueMessage(
            text: 'The vault is empty.'
          );
        }
        
        xferItems(
          from:world.party.bank,
          to:  world.party.inventory,
          moveToName : 'Inventory'
        );

      }

      @:inventoryItems = ::{
        @:inv = world.party.inventory;
        when(inv.isEmpty) ::<= {
          windowEvent.queueMessage(
            text: 'Inventory is empty.'
          );
        }
        
        xferItems(
          from:world.party.inventory,
          to:  world.party.bank,
          moveToName : 'Bank Storage'
        )
      }

        
      @:bankedGold ::{
        @:inv = world.party.bank;
        when(inv.gold == 0) 
          windowEvent.queueMessage(
            text:'The party has no money in the vault to take.'
          );

        @:num = import(:'game_function.number.mt');
        num(
          canCancel : true,
          onDone::(value) {
            when (value > inv.gold)
              windowEvent.queueMessage(
                text:'There isn\'t that much to take...'
              );

            @amount = value;
            inv.subtractGold(:amount);
            world.party.inventory.addGold(:amount);
          },
          prompt: 'Take how much? Current: ' + g(:inv.gold)
        );
      }

      @:inventoryGold ::{
        @:inv = world.party.inventory;
        when(inv.gold == 0) 
          windowEvent.queueMessage(
            speaker: 'The banker?',
            text: '"This a joke? You don\'t got any gold on you!"'
          );

        @:num = import(:'game_function.number.mt');
        num(
          canCancel : true,
          onDone::(value) {
            when (value > inv.gold)
              windowEvent.queueMessage(
                text: 'That\'s too much.'
              );

            @amount = value;
            inv.subtractGold(:amount);
            world.party.bank.addGold(:amount);
          },
          prompt: 'Put in how much? Current: ' + g(:inv.gold)
        );
      }


    
      windowEvent.queueNestedResolve(
        onEnter ::{

          windowEvent.queueChoices(
            prompt: 'The Vault...',
            jumpTag : 'BANKING',
            keep : true,
            choices : [
              'Take from Vault...',
              'Put in Vault...',
              'Done'
            ],
            canCancel : false,
            
            onChoice::(choice) {
              when(choice == 3)
                windowEvent.queueAskBoolean(
                  prompt: 'Done banking?',
                  onChoice::(which) {
                    when(which == true) ::<= {

                      windowEvent.jumpToTag(name: 'BANKING', goBeforeTag:true);
                    }
                  }
                );              
            
              @takeFromBank = choice == 1;
              windowEvent.queueChoices(
                prompt : if (takeFromBank)
                  'Take from Bank...'
                 else 
                  'Put in Bank...',
                choices : [
                  'Items',
                  'Gold'
                ],
                canCancel: true,
                keep : true,
                onChoice::(choice) {
                  when(choice == 1)
                    if (takeFromBank)
                      bankedItems()
                    else 
                      inventoryItems()
                      
                    if (takeFromBank)
                      bankedGold()
                    else 
                      inventoryGold()
                  
                  
                }
              );
            }
          );
        }
      )
    }
  }
)




Location.database.newEntry(data:{
  name: 'The Vault',
  id: 'therogue:the-vault',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '$',
  category : Location.CATEGORY.UTILITY,
  minStructureSize : 1,
  onePerLandmark : false,

  descriptions: [
    'A mysterious chest in the shape of a small vault.'
  ],
  interactions : [
    'therogue:check-vault'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract::(location){},      
  onInteract ::(location) {
  },
  onStep ::(location, entities) {
  
  },  
  onCreate ::(location) {
  },
  
  onIncrementTime::(location, time) {
  
  }
}) 





  Landmark.database.newEntry(
    data: {
      name: 'Dungeon',
      id: 'therogue:mysterious-shrine',
      symbol : 'M',
      legendName: 'Shrine',
      rarity : 100000,    
      minLocations : 0,
      maxLocations : 4,
      traits : 
        Landmark.TRAIT.UNIQUE |
        Landmark.TRAIT.POINT_OF_NO_RETURN |
        Landmark.TRAIT.EPHEMERAL,
      minEvents : 1,
      maxEvents : 7,
      eventPreference : LandmarkEvent.KIND.HOSTILE,

      landmarkType : Landmark.TYPE.DUNGEON,
      requiredEvents : [
        'base:dungeon-encounters',
      ],
      possibleLocations : [
  //          {id: 'Stairs Down', rarity:1},
        {id: 'base:fountain', rarity:18},
        {id: 'base:potion-shop', rarity: 25},
        {id: 'base:wyvern-statue', rarity: 20},
        {id: 'base:magic-chest', rarity: 15},

        {id: 'base:healing-circle', rarity:35},

        {id: 'base:clothing-shop', rarity: 100},
        {id: 'base:fancy-shop', rarity: 50}

      ],
      requiredLocations : [
        'base:stairs-up',
        'base:item',
        'base:item',
        'therogue:gold',
        'base:warp-point'
      ],
      mapHint:{
        layoutType: DungeonMap.LAYOUT_EPSILON
      },
      onCreate ::(landmark, island){  
        island.level+=1
      },
      onIncrementTime ::(landmark, island){},
      onStep ::(landmark, island) {},
      onVisit ::(landmark, island) {
        if (landmark.floor == 0)
          windowEvent.queueMessage(
            speaker: world.party.members[0].name, 
            text:"\"Further in is the only way to go...\""
          );
      }
    }
  )





  @:createHome::(landmark) {
  

    
    
  
  
    @:map = landmark.map;
    map.width = 100;
    map.height = 100;
    
    @:wall = map.addScenerySymbol(:'Y');

    @:OFFSET = 50;
    
    @:REAL_WIDTH = 12;
    @:REAL_HEIGHT = 10;

    // need to place chest 
    @:CHEST_LOCATION = {
      x: 3,
      y: (REAL_HEIGHT/2)->floor
    }

    @:STAIRS_LOCATION = {
      x: 8,
      y: (REAL_HEIGHT/2)->floor
    }

    landmark.addLocation(
      location: 
        Location.new(
          landmark,
          base: Location.database.find(id:'therogue:the-vault'),
          x: (map.width/2)->floor  - (OFFSET/2)->floor + CHEST_LOCATION.x,
          y: (map.height/2)->floor - (OFFSET/2)->floor + CHEST_LOCATION.y
        ),
        
      width: 1, height: 1,
      discovered: false
    );


    landmark.addLocation(
      location: 
        Location.new(
          landmark,
          base: Location.database.find(id:'therogue:stairs-down'),
          x: (map.width/2)->floor  - (OFFSET/2)->floor + STAIRS_LOCATION.x,
          y: (map.height/2)->floor - (OFFSET/2)->floor + STAIRS_LOCATION.y
        ),
        
      width: 1, height: 1,
      discovered: false
    );


    


    

    map.paintScenerySolidRectangle(
      symbol : wall,
      isWall : true,
      x : 0,
      y : 0,
      width: map.width,
      height: map.height
    );
    
    map.paintScenerySolidRectangle(
      isWall : false,
      x : (map.width/2)->floor  - (OFFSET/2)->floor,
      y : (map.height/2)->floor - (OFFSET/2)->floor,
      width: OFFSET,
      height: OFFSET
    );
    
    
    
    
    map.setPointer(
      x: OFFSET,
      y: OFFSET
    );
  }


  Landmark.database.newEntry(
    data: {
      name: 'Ethereal Home',
      id: 'therogue:ethereal-home',
      symbol : 'M',
      legendName: 'Shrine',
      rarity : 100000,    
      minLocations : 0,
      maxLocations : 2,
      traits : 
        Landmark.TRAIT.UNIQUE |
        Landmark.TRAIT.POINT_OF_NO_RETURN,
      minEvents : 1,
      maxEvents : 7,
      eventPreference : LandmarkEvent.KIND.PEACEFUL,

      landmarkType : Landmark.TYPE.CUSTOM,
      requiredEvents : [
      ],
      possibleLocations : [
      ],
      requiredLocations : [
      ],
      mapHint:{},
      onCreate ::(landmark, island) {
        createHome(:landmark);
      },
      onIncrementTime ::(landmark, island){},
      onStep ::(landmark, island) {},
      onVisit ::(landmark, island) {
        island.level+=1
      
        @world = import(module:'game_singleton.world.mt');
        if (landmark.floor == 0)
          windowEvent.queueMessage(
            speaker: world.party.members[0].name, 
            text:"\"Further in is the only way to go...\""
          );
      }
    }
  )







Island.database.newEntry(
  data : {
    id : 'therogue:home',
    requiredLandmarks : [
      'therogue:ethereal-home'
    ],
    possibleLandmarks : [
    ],
    minAdditionalLandmarkCount : 0,
    maxAdditionalLandmarkCount : 0,
    minSize : 1,//80,
    maxSize : 1, //130,
    events : [
      
    ],
    possibleSceneryCharacters : [
      '╿', '.', '`', '^', ','
    ],
    traits : Island.TRAIT.SPECIAL | Island.TRAIT.EMPTY,
    
    overrideSpecies : empty,
    overrideNativeCreatures : empty,
    overridePossibleEvents : empty,
    overrideClimate : empty,  
  }
)

}
