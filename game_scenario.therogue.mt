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





@:initializeItems ::{




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
    'base:next-floor',
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
    /*
    if (location.landmark.island.tier > 1) 
      if (random.flipCoin()) ::<= {
        location.lockWithPressurePlate();
      }
    */
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
  onCreate ::(location) <-
    location.inventory.addGold(:random.integer(from: 20, to: 250))
  ,
  
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
        'base:stairs-down',
        'base:stairs-down',
        'base:item',
        'base:item',
        'therogue:gold',
        'base:warp-point'
      ],
      mapHint:{
        layoutType: DungeonMap.LAYOUT_EPSILON
      },
      onCreate ::(landmark, island){  
        island.levelMin+=1
        island.levelMax+=1
      },
      onIncrementTime ::(landmark, island){},
      onStep ::(landmark, island) {},
      onVisit ::(landmark, island) {
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
        'therogue:mysterious-shrine'
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





@:characterCreator ::(onDone) {
  windowEvent.queueMessage(
    text: 'Who are you?'
  );
  
  @species = Species.getRandomFiltered(::(value) <- (value.traits & Species.TRAIT.SPECIAL) == 0)
  @profession = Profession.getRandomFiltered(::(value) <- value.learnable)
  @name = namegen.person();
  @arts = [
    Arts.getRandomFiltered(::(value) <- (value.traits & Arts.TRAIT.SPECIAL) == 0),
    Arts.getRandomFiltered(::(value) <- (value.traits & Arts.TRAIT.SPECIAL) == 0),
    Arts.getRandomFiltered(::(value) <- (value.traits & Arts.TRAIT.SPECIAL) == 0)  
  ];

  @:choiceActions = [
    // name 
    :: {
      windowEvent.queueMessage(
        text:'Please choose a name.'
      );
      
      windowEvent.queueChoices(
        onGetPrompt::<- 'Name: ' + name,
        choices : [
          'Choose one for me',
          'Enter name...'
        ],
        canCancel : true,
        
        onChoice ::(choice) {
          when(choice == 1) ::<= {
            name = namegen.person();
          }
          
          when(choice == 2) ::<= {
            name = (import(:'game_function.name.mt'))();
          }
        }
      );
    
    },
    
    // species
    :: {
      windowEvent.queueMessage(
        text:'Please choose a species.'
      );
      
      @:choices = Species.getAllFiltered(::(value) <- (value.traits & Species.TRAIT.SPECIAL) == 0)
      @:choicesMarked = choices->map(::(value) <-
        if (value == species) 
          '[*]'
        else  
          '   '
      );

      @:choicesColumns = import(:'game_function.choicescolumns.mt');
      choicesColumns(
        leftJustified : [true, true],
        onGetPrompt::<- 'Species:' + species.name,
        onGetChoices::<- [
          choices->map(::(value) <- value.name),
          choicesMarked
        ],
        separator : '',
        canCancel: true,
        onChoice::(choice) {
          species = choices[choice-1];
        }
      );      
    },

    // Profession
    :: {
      windowEvent.queueMessage(
        text:'Please choose a profession.'
      );
      
      @:choices = Profession.getAllFiltered(::(value) <- value.learnable)
      @:choicesMarked = choices->map(::(value) <-
        if (value == species) 
          '[*]'
        else  
          '   '
      );


      @:choicesColumns = import(:'game_function.choicescolumns.mt');
      choicesColumns(
        leftJustified : [true, true],
        onGetPrompt::<- 'Profession:' + profession.name,
        onGetChoices::<- [
          choices->map(::(value) <- value.name),
          choicesMarked
        ],
        separator : '',
        canCancel: true,
        onChoice::(choice) {
          profession = choices[choice-1];
        }
      );      
    },


    /*
    :: {
      windowEvent.queueMessage(
        text:'Select 3 Arts to start with.'
      );
      
      @:choices = Profession.getAllFiltered(::(value) <- (value.traits & Profession.TRAIT.SPECIAL) == 0)
      @:choicesMarked = choices->map(::(value) <-
        if (value == species) 
          '[*]'
        else  
          '   '
      );

     
    }
    */
    
    ::{
      windowEvent.queueAskBoolean(
        prompt: 'Are you ready, ' + name + ', the ' + species.name + ' ' + profession.name + '?',
        onChoice::(which) {
          when(which == true) ::<= {
            windowEvent.jumpToTag(
              name: 'THEROGUESETUP',
              goBeforeTag: true
            );
            onDone(::<={
              @world = import(module:'game_singleton.world.mt');
              @:entity = Entity.new(
                professionHint : profession.id,
                speciesHint: species.id,
                levelHint: 6,
                name : name
              );

              entity.autoLevelProfession(:entity.profession);
              entity.autoLevelProfession(:entity.profession);


              entity.equipAllProfessionArts();  
              ::? {
                forever ::{
                  if (entity.calculateDeckSize() >= 35) send();

                  entity.supportArts->push(:
                    Arts.getRandomFiltered(::(value) <- 
                      ((value.traits & Arts.TRAIT.SPECIAL) == 0)
                      &&
                      ((value.traits & Arts.TRAIT.SUPPORT) != 0)
                    ).id
                  );
                }
              }
              
              
              return entity;
            });
          }
        }
      );
    }

    
  ]
  
  windowEvent.queueChoices(
    onGetPrompt ::<-  name + ', the ' + species.name + ' ' + profession.name,
    choices : [
      'Choose Name',
      'Choose Species',
      'Choose Profession',
      //'Choose 3 Starter Arts',
      'Proceed'
    ],
    canCancel : false,
    keep:true,
    jumpTag: 'THEROGUESETUP',
    
    onChoice::(choice) {
      choiceActions[choice-1]();
    }
  );
}


return {
  name : 'The Rogue',
  id : 'rasa:therogue',


  // Called when a new day starts
  onNewDay ::(data){},

  // Called when a file is loaded with this scenario 
  onResume ::(data){},
  
  // Called when a party member dies.
  onDeath ::(data, entity){},

  skipName : false,

  // List of interactions available when talking to an Entity.  
  // This is specifically when at a location owned by an Entity.
  interactionsPerson: [],

  // List of interactions when at a location.
  interactionsLocation: [],
  
  // List of interactions when at a landmark.
  interactionsLandmark: [],
  
  // List of interactions available when simply walking around at 
  // either the landmark or island level.
  interactionsWalk : [
    commonInteractions.walk.check,
    commonInteractions.walk.party,
    commonInteractions.walk.inventory,
  ],
  
  // List of interactions available when controlling the party 
  // in a battle.
  interactionsBattle : [
    commonInteractions.battle.attack,
    commonInteractions.battle.arts,
    commonInteractions.battle.check,
    commonInteractions.battle.item,
    commonInteractions.battle.wait,
    commonInteractions.battle.log,
  ],
  
  // List of general options available, such as quitting the game.
  interactionsOptions : [
    commonInteractions.options.quickSave,
    commonInteractions.options.system,
    commonInteractions.options.quit,      
  ],


  // Function reserved for overriding database options. Good for database 
  // items that are specific to this scenario.
  databaseOverrides ::(){},
  
  // List of accolades (achievements) available when beating this scenario.
  accolades : [],
  
  // Text to display when completing the scenario that summarizes highlights 
  // of data that the player did. For example in "The Chosen" scenario, the 
  // number of knockouts is displayed.
  reportCard :: {
    return '';
  },


  
  onBegin ::(data) {
    @:instance = import(module:'game_singleton.instance.mt');
    @:story = import(module:'game_singleton.story.mt');
    @world = import(module:'game_singleton.world.mt');
    @:LargeMap = import(module:'game_singleton.largemap.mt');
    @party = world.party;      


  
    initializeItems();    


    party.reset();
    @:island = world.island;


    @:keyother = Item.new(
      base: Item.database.find(id:'base:wyvern-key')
    );
    
    keyother.setIslandGenTraits(
      nameHint: 'The Dungeon',
      levelHint: story.levelHint,
      idHint: 'therogue:home',
      tierHint: 0
    );

    world.loadIsland(key:keyother, onDone::(island) {
      characterCreator(::(entity){
        party.add(:entity);
        breakpoint();
        instance.visitLandmark(landmark:island.landmarks[0]);
      });
    });



  }  
}
