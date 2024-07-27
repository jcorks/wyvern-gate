@:Database = import(module:'game_class.database.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');
@:class = import(module:'Matte.Core.Class');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:Item = import(module:'game_mutator.item.mt');
@:random = import(module:'game_singleton.random.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:g = import(:'game_function.g.mt');
@:Location = import(module:'game_mutator.location.mt');
@:world = import(module:'game_singleton.world.mt');


// Determines the difficulty of the mission
@:RANK = {
  NONE : -1,
  E  : 0,
  D  : 1,
  C  : 2,
  B  : 3,
  A  : 4,
  S  : 5,
  SS : 6,
  X  : 7
}

@:TRAITS = {
  // if present, the quest has its reward replaced with ???
  HIDDEN_REWARD : 1,
  SPECIAL : 2,
}

@:reset ::{
Quest.database.newEntry(
  data : {
    id : 'base:fetch-quest-personal',
    traits : TRAITS.HIDDEN_REWARD |
             TRAITS.SPECIAL,
    descriptions : [
      'I was in the forest and I lost my %1! Please help!',
      'I was scared by some creatures in the forest and dropped my %1! Please retrieve it.',
      'A while back, I dropped my %1 in the forest. I\'d like you to get it back for me.',
      'I need my %1! Please go to the forest to get it!'
    ],
    
    onCreate ::(issuer, quest) {
      quest.name = issuer.name + '\'s Item';
      quest.data.item = Item.new(
        base:Item.database.getRandomFiltered(
          filter:::(value) <- value.isUnique == false
        ),
        rngEnchantHint:true, 
        forceEnchant:true
      )
      
      quest.description = quest.description->replace(key:'%1', with : quest.data.item.name);
    },

    onAccept ::(island, quest, issuer) {
      @:Landmark = import(:'game_mutator.landmark.mt');
      @:pos = island.getAPosition();
      @:landmark = Landmark.new(
        island : island,
        base: Landmark.database.find(:'base:forest-generic'),
        x : pos.x,
        y : pos.y
      );
      landmark.symbol = 'X';
      landmark.legendName = quest.name;
      
      @:loc = landmark.getRandomEmptyPosition();
      
      @:item = Location.new(
        landmark: landmark,
        xHint : loc.x,
        yHint : loc.y,
        base: Location.database.find(:'base:lost-item')
      );
      landmark.addLocation(location:item);
      
      item.inventory.add(:quest.data.item);
      quest.data.itemID = quest.data.item.worldID; // only one copy of an item can exist when saving.
      quest.data.landmarkID = landmark.worldID;
      quest.data.itemName = quest.data.item.name;
      quest.data.item = empty;
      island.addLandmark(:landmark);
      
      windowEvent.queueMessage(
        speaker: issuer.name,
        text : '"Thank you so much. Please come back when you\'ve found it!"'
      );      

      windowEvent.queueMessage(
        text : 'The probable location was marked on the island map.'
      );      
    },
    
    onStep ::(quest, landmark, island) {
    
    },
    
    onTurnIn ::(quest, issuer) {
      windowEvent.queueMessage(
        speaker: issuer.name,
        text: '"Oh excellent! You found the ' + quest.data.itemName + '! Thank you so much!"'
      );

      windowEvent.queueMessage(
        text: 'The party handed over the ' + quest.data.itemName + '.'
      );

      world.party.getItem(condition::(value) <- value.worldID == quest.data.itemID, remove:true);

      windowEvent.queueMessage(
        speaker: issuer.name,
        text: '"Here, I would like you to have this."'
      );

            
      
      world.island.removeLandmark(:world.island.landmarks->filter(::(value) <- value.worldID == quest.data.landmarkID)[0]);
    },
    
    onNextHour ::(quest) {
    
    },

    // The scene to play when a landmark is entered.
    onLandmarkEnter ::(quest, landmark) {},
  
    // Whether the quest is complete and able to be taken back 
    // for the reward.
    isComplete ::(quest, party) {
      return party.getItem(condition::(value) <- value.worldID == quest.data.itemID) != empty;
    },
    
    dependsOn : []
  }
);
}





@:generateDefaultReward::(state) {
  match(state.rank) {
    (RANK.NONE): ::<= {
      state.rewardG = random.integer(from:20, to:70);
      state.rewardItems = [
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.isUnique == false && value.canHaveEnchants
          ),
          rngEnchantHint:true, 
          forceEnchant:true
        )
      ]
    },
  
    (RANK.E): ::<= {
      state.rewardG = random.integer(from:20, to:70);
      if (random.try(percentSuccess:40)) ::<= {
        state.rewardItems = [
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                          && value.tier <= 1
            ),
            rngEnchantHint:true, 
            forceEnchant:true
          )
        ]
      }
    },
    
    (RANK.D): ::<= {
      state.rewardG = random.integer(from:70, to:150);
      if (random.try(percentSuccess:80)) ::<= {
        state.rewardItems = [
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                          && value.tier <= 1
            ),
            rngEnchantHint:true, 
            forceEnchant:true
          )
        ]
      }
      
      if (random.try(percentSuccess:50)) ::<= {
        state.rewardItems->push(:
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                          && value.tier <= 2
            ),
            rngEnchantHint:true, 
            forceEnchant:true
          )
        );
      }      
    },


    (RANK.C): ::<= {
      state.rewardG = random.integer(from:130, to:250);
      if (random.try(percentSuccess:80)) ::<= {
        state.rewardItems = [
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                          && value.tier <= 2
            ),
            rngEnchantHint:true, 
            forceEnchant:true
          )
        ]
      }
      
      if (random.try(percentSuccess:50)) ::<= {
        state.rewardItems->push(:
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                          && value.tier <= 3
            ),
            rngEnchantHint:true, 
            forceEnchant:true
          )
        );
      }      
    },
    
    (RANK.B): ::<= {
      state.rewardG = random.integer(from:300, to:500);
      for(0, 1+Number.random()*3) ::(i) {
        state.rewardItems->push(:
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                          && value.tier <= 4
            ),
            rngEnchantHint:true, 
            forceEnchant:true
          )
        );
      }
    },    

    (RANK.A): ::<= {
      state.rewardG = random.integer(from:500, to:700);
      for(0, 1+Number.random()*3) ::(i) {
        state.rewardItems->push(:
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                          && value.tier <= 4
            ),
            rngEnchantHint:true, 
            forceEnchant:true
          )
        );
      }
      
      state.rewardItems->push(:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.isUnique == false && value.type == Item.TYPE.RING
          ),
          rngEnchantHint:true, 
          forceEnchant:true
        )
      );      
    },    

    (RANK.S): ::<= {
      state.rewardG = random.integer(from:700, to:1000);
      for(0, 1+Number.random()*3) ::(i) {
        state.rewardItems->push(:
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                          && value.tier > 2
            ),
            rngEnchantHint:true, 
            forceEnchant:true
          )
        );
      }
      
      state.rewardItems->push(:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.isUnique == false && value.type == Item.TYPE.TRINKET
          ),
          rngEnchantHint:true, 
          forceEnchant:true
        )
      );      
    },    

    (RANK.SS): ::<= {
      state.rewardG = random.integer(from:1100, to:1400);
      for(0, 1+Number.random()*3) ::(i) {
        state.rewardItems->push(:
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                          && value.tier > 3
            ),
            rngEnchantHint:true, 
            forceEnchant:true
          )
        );
      }
      
      state.rewardItems->push(:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.isUnique == false &&
              value.tier > 1
          ),
          qualityHint : 'base:masterwork',
          rngEnchantHint:true, 
          forceEnchant:true
        )
      );      
    }, 
    
    (RANK.SS): ::<= {
      state.rewardG = random.integer(from:2000, to:4000);
      for(0, 1+Number.random()*3) ::(i) {
        state.rewardItems->push(:
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                          && value.tier > 3
            ),
            qualityHint : 'base:masterwork',
            rngEnchantHint:true, 
            forceEnchant:true
          )
        );
      }
      
      state.rewardItems->push(:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.isUnique == false &&
              value.type == Item.TYPE.RING
          ),
          qualityHint : 'base:masterwork',
          rngEnchantHint:true, 
          forceEnchant:true
        )
      );      
      
    }, 


    (RANK.X): ::<= {
      state.rewardG = random.integer(from:5000, to:10000);
      for(0, 1+Number.random()*4) ::(i) {
        state.rewardItems->push(:
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                          && value.tier > 3
            ),
            qualityHint : 'base:masterwork',
            rngEnchantHint:true, 
            forceEnchant:true
          )
        );
      }
      
      state.rewardItems->push(:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.isUnique == false &&
              value.type == Item.TYPE.RING
          ),
          qualityHint : 'base:masterwork',
          rngEnchantHint:true, 
          forceEnchant:true
        )
      );      

      
      state.rewardItems->push(:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.isUnique == false &&
              value.type == Item.TYPE.TRINKET
          ),
          qualityHint : 'base:divine',
          rngEnchantHint:true, 
          forceEnchant:true
        )
      );      
    }
  }
}

// essentially an opaque wrapper for custom per-step 
// controllers of landmarks.
@:Quest = databaseItemMutatorClass.create(
  name : 'Wyvern.Quest',
  statics : {
    RANK : {
      get ::<- RANK
    }
  },
  items : {
    // the world ID of the issuer of the quest
    issuerID : -1, 
    
    // The visual name of the quest
    name : '',
    
    // the ephemeral world ID of the landmark created for this event.
    landmarkID : -1,
    
    
    // full description of the quest
    description : '',
    
    // The name of the issuer
    issuerName : '',
    
    // Where the quest leads.
    locationName : '',
    
    // If true, the quest can be turned in no matter what.
    forceComplete : false,

    // reward for turning in the quest in G
    rewardG : 0,
    
    // rewards for turning in the quest
    rewardItems : [],
    
    // Extra data for quests to store.
    data : empty,
    
    // The rank of the quest
    rank : -1,
  },
  
  database : Database.new(
    name:'Wyvern.Quest.Base',
    attributes : {
      id : String,
      // All possible description bases
      descriptions : Object,
      
      // Special traits that the quest has. Check the TRAITS enum
      traits : Number,
      
      // Called on the first time the quest is created.
      onCreate : Function,
      
      // Called when accepting the quest. This should generate 
      // any landmark to be visited.
      onAccept : Function,
      
      // Called when the quest is turned in.
      onTurnIn : Function,
      
      // when a player takes a step in either the landmark context
      onStep : Function,
      
      // when a new hour passes,
      onNextHour : Function,
      
      // The action to do when a landmark is entered.
      onLandmarkEnter : Function,

      // Whether the quest is complete and able to be taken back 
      // for the reward.
      isComplete : Function,
      
      // the quest IDs that must be completed before this quest can be taken 
      dependsOn : Object,
      
      
    },
    reset
  ),
  
  define::(this, state) {
        
    this.interface = {
      initialize ::(parent) {
      },
      
      defaultLoad ::(base, issuer, rank) {
        state.data = {};
        state.base = base;
        state.rank = rank;
        state.name = '????';
        state.issuerID = issuer.worldID;
        state.issuerName = issuer.name + ', the ' + issuer.species.name + (if(issuer.profession.id == 'base:none') '' else ' ' + issuer.profession.name)
        state.description = random.pickArrayItem(:base.descriptions);
        generateDefaultReward(state);
        base.onCreate(quest:this, issuer);
      },      
      
      
      
      setReward::(g, items) {
        state.rewardG = if (g == empty) 0 else g;
        state.rewardItems = [...items];
      },
      
      // creates the quest, returning the landmark 
      // for where the quest belongs
      accept ::(island, issuer) {
        @:landmark = state.base.onAccept(quest:this, island, issuer);
        return landmark;
      },
      
      data : {
        get ::<- state.data
      },
      
      name : {
        get ::<- state.name,
        set ::(value) <- state.name = value      
      },
      
      issuerID : {
        get ::<- state.issuerID
      },
      
      isComplete : {
        get ::<- state.base.isComplete(quest:this, party:import(:'game_singleton.world.mt').party)
      },
      
      step ::(landmark, island){
        state.base.onStep(quest:this, landmark, island);
      },
      
      nextHour ::<- state.base.onNextHour(quest:this),
      
      turnIn ::(issuer) {
        state.base.onTurnIn(quest:this, issuer);
        
        windowEvent.queueDisplay(
          lines : [
            'Quest ' + this.name + ': Complete!',
            '',
            'Reward:',
            '',
            ...state.rewardItems->map(::(value) <- ' - ' + value.name),
            ' - ' + g(:state.rewardG)
          ]
        );
        @:world = import(module:'game_singleton.world.mt');
        @:party = world.party;        
        foreach(state.rewardItems) ::(k, item) {
          party.inventory.add(:item);
        }
        state.rewardItems = [];
        windowEvent.queueCustom(
          onEnter::{
            party.addGoldAnimated(amount:state.rewardG);
          }
        );
      },
      
      description : {
        get :: <- state.description,
        set ::(value) <- state.description = value
      },
      
      renderPrompt::(showCompleteness, topWeight, leftWeight) {
        if (topWeight == empty)
            topWeight = 0;
        canvas.renderTextFrameGeneral(
          lines:canvas.refitLines(
            input : [
              'Quest  : ' + state.name,
              'Issuer : ' + state.issuerName,
              '',
              state.description, 
              '',
              'Reward(s):',
              ...(if (state.base.traits & TRAITS.HIDDEN_REWARD != 0) 
                [' - ???']
              else
                state.rewardItems->map(::(value) <- ' - ' + value.name)
              ),
              if (state.rewardG) ' - ' + g(:state.rewardG) else '',
              if (showCompleteness == true) 
                'Status: ' + if (this.isComplete) 'Ready to turn in!' else 'In progress...' 
              else  
                ''
            ],
            maxWidth : canvas.width * 0.6
          ),
          topWeight,
          leftWeight
        );
      }
    }
  }
);


return Quest;
