@:Item = import(module:'game_mutator.item.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Scenario = import(module:'game_mutator.scenario.mt');
@:Arts = import(module:'game_mutator.arts.mt');
@:commonInteractions = import(module:'game_singleton.commoninteractions.mt');
@:Effect = import(module:'game_database.effect.mt');
@:random = import(module:'game_singleton.random.mt');

@:world = import(module:'game_singleton.world.mt');
@:instance = import(module:'game_singleton.instance.mt');

@:Entity = import(module:'game_class.entity.mt');
@:Species = import(module:'game_database.species.mt');
@:Profession = import(module:'game_database.profession.mt');
@:EnterNumber = import(module:'game_function.number.mt');

@:canvas = import(module:'game_singleton.canvas.mt');
@:StatSet = import(module:'game_class.statset.mt');



@:MAIN_TAG = 'statsimdisplay'

@:redrawMain::{
  windowEvent.invalidateCache(:MAIN_TAG);
}

import(:'game_function.descriptivelist.mt');

@:addEntity ::(data, ent){
  ent.data.tier = world.island.tier;
  data.entities->push(:ent)
  windowEvent.invalidateCache(:MAIN_TAG);
}

@:statSim_Island ::(data){
  @:onGetChoices ::{
    return [
      'Set Level (currently: ' + world.island.level + ')',
      'Set Tier (currently: ' + world.island.tier + ')'
    ]
  }
  windowEvent.queueChoices(
    prompt: 'Island...',
    onGetChoices,
    leftWeight : 1,
    topWeight : 1,
    canCancel: true,
    keep: true,
    onChoice::(choice) {
      when(choice == 1) 
        EnterNumber(
          onDone ::(n) {
            world.island.level = n;
          },
          prompt: 'Enter a new level',
          canCancel : true
        );

      when(choice == 2) 
        EnterNumber(
          onDone ::(n) {
            world.island.tier = n;
          },
          prompt: 'Enter a new tier',
          canCancel : true
        );

        
    }
  );
}


@:statSim_Entities_New_GenerateFromIsland::(data) {
  @equips = 0;
  @professionLevel = 0
  @defaultGen = true;
  @:gen ::{
    @:ent = world.island.newInhabitant(raw:defaultGen == false)

    // equips    
    ::<= {
    
      @:equipSlot ::(slot) {
        @:base = Item.database.getRandomFiltered(
            filter:::(value) <- 
              Entity.equipTypeToSlots(:value.equipType)[0] == slot &&
              value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
              value.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS) &&
              value.tier <= world.island.tier
        );
        when(base == empty) empty;
        @:item = Item.new(
          base,
          rngEnchantHint:true, 
          forceEnchant:true
        )
        ent.equip(item, slot, silent:true);
      }
    

      for(0, equips) ::(i) {
        // like irl, prefer hand and armor first
        when(ent.getEquipped(:Entity.EQUIP_SLOTS.HAND_LR).base.id == 'base:none')
          equipSlot(:Entity.EQUIP_SLOTS.HAND_LR);

        when(ent.getEquipped(:Entity.EQUIP_SLOTS.ARMOR).base.id == 'base:none')
          equipSlot(:Entity.EQUIP_SLOTS.ARMOR);

      
        @:openSlots = Entity.EQUIP_SLOTS->values->filter(::(value) <- ent.getEquipped(:value).base.id == 'base:none');
        breakpoint();
        when(openSlots->size == 0) empty
        
        equipSlot(:random.pickArrayItem(:openSlots));
      }
    }
    // end equips


    for(0, professionLevel) ::(i) {
      ent.autoLevelProfessionPlayer();
    }


    return ent;    

  
  }        


  windowEvent.queueChoices(
    canCancel: true,
    keep: true,
    prompt: 'New Entity...',
    onGetChoicesMatch ::<- [
      'Generate', ::{
        @:ent = gen();
        addEntity(data, ent);
        windowEvent.queueMessage(text:'Added ' + ent.name);
      },
      
      'Use Default Gen? ' + if (defaultGen == true) 'Yes' else 'No', ::{
        defaultGen = !defaultGen
      },
      
      'Set Equip Count (currently: ' + equips + ')', ::{
        EnterNumber(
          prompt: 'How many equips?',
          canCancel : true,
          onDone ::(n) {
            equips = n;
          }
        )      
      },
      
      'Set Profession Level (currently : ' + professionLevel + ')', ::{
        EnterNumber(
          prompt: 'Natural Profession Level?',
          canCancel : true,
          onDone ::(n) {
            professionLevel = n;
          }
        )      
      }
    ]
  );
}

@:statSim_Entities_New_GenerateMonster ::(data) {
  @:list = Species.getAll()->filter(::(value) <- Profession.findSoft(:value.id) != empty);
  
  windowEvent.queueChoices(
    prompt: 'Add which?',
    canCancel: true,
    keep : true,
    choices: list->map(::(value) <- value.name),
    onChoice::(choice) {
      @:ent = world.island.newInhabitant(
        professionHint : list[choice-1].id,
        speciesHint : list[choice-1].id
      )
      addEntity(ent, data);
      windowEvent.queueMessage(text:'Added ' + ent.name);
    }  
  );
}

@:statSim_Entities_New ::(data) {
  windowEvent.queueChoices(
    prompt: 'Entity',
    canCancel: true,
    keep: true,
    
    choicesMatch : [
      'Standard',  ::<- statSim_Entities_New_GenerateFromIsland(data),
      'Special',   ::<- statSim_Entities_New_GenerateMonster(data)
      //('Custom...') ::<- statSim_Entities_New_Custom(:data);
    ]
  );
}

@:statSim_Entities_View ::(data) {
  windowEvent.queueChoices(
    choices : data.entities->map(::(value) <- value.name),
    keep :true,
    canCancel :true,
    onChoice ::(choice) {
      data.entities[choice-1].describe();
    }
  );
}

@:statSim_Entities_Remove ::(data) {
  windowEvent.queueChoices(
    onGetChoices ::<- data.entities->map(::(value) <- value.name),
    keep :true,
    canCancel :true,
    onChoice ::(choice) {
      data.entities->remove(:choice-1)
      redrawMain();
    }
  );

}

@:statSim_Entities ::(data) <-
  windowEvent.queueChoices(
    prompt: 'Entities...',
    canCancel: true,
    keep: true,
    choicesMatch : [
      'New', ::<- statSim_Entities_New(:data),
      'View', ::<- statSim_Entities_View(:data),
      'Remove', ::<- statSim_Entities_Remove(:data)
    ]
  )





return { 
  onGameStartup ::{
  },

  onDatabaseStartup :: {
    Scenario.database.newEntry(data:{
      name : 'Stat Sim',
      
      id: 'mod.dev.rasa.stat-sim:start',
      
      events : {
        // Called when first starting the scenario.
        onBegin ::(data) {
          data.entities = [];

      

          @:keyhome = Item.new(
            base: Item.database.find(id:'base:wyvern-key')
          );

          keyhome.setIslandGenTraits(
            nameHint:'', 
            levelHint:6,
            idHint: 'base:none',
            tierHint: 0  
          )

          world.loadIsland(
            key:keyhome, 
            skipSave:true,
            onDone ::(island){
              windowEvent.queueMessage(
                text: "Welcome to Stat-Sim! Let\'s start balancing!"
              );
        
              windowEvent.queueChoices(
                canCancel: false,
                keep:true,
                leftWeight : 1,
                topWeight : 0,
                choices: [
                  'Island...',
                  'Entities...'
                ],
                jumpTag : MAIN_TAG,
                
                renderable : {
                  render ::{
                    canvas.fill(:' ');
                    @iter = 0;
                    foreach(data.entities) ::(k, v) {
                      @:bounds = canvas.renderTextFrameGeneral(
                        x : iter,
                        y : 0,
                        title: v.name,
                        lines: [
                          'Lvl: ' + v.level + ', Tier ' + v.data.tier,
                          v.profession.name + ' (' + v.species.name + ')',
                          
                          ...v.statModComparisonToLines()
                        ]
                      );

                        
                      
                      canvas.renderTextFrameGeneral(
                        x: iter,
                        y: bounds.height,
                        title: 'Basic DMG',
                        lines : [
                          'Attack: ~' + Arts.database.find(:'base:attack').baseDamage(level:1, user:v),
                          'Fire:   ~' + Arts.database.find(:'base:fire').baseDamage(level:1, user:v),
                        ]
                      );

                      
                      iter += bounds.width;
                    }
                  }
                },
                
                onChoice::(choice) {
                  when(choice == 1) statSim_Island(data);              
                  when(choice == 2) statSim_Entities(data);              
                }
              );
            }
          ); 
        },
        
        // Called when a new day starts
        onNewDay ::(data){},

        // Called when a file is loaded with this scenario 
        onResume ::(data){},
        
        // Called when a party member dies.
        onDeath ::(data, entity){}
      },

      skipName : true,
      everyoneIsAFriend: true,

      // List of interactions available when talking to an Entity.  
      // This is specifically when at a location owned by an Entity.
      interactionsPerson: [],

      // List of interactions when at a location.
      interactionsLocation: [],
      
      // List of interactions when at a landmark.
      interactionsLandmark: [],
      
      // List of interactions available when simply walking around at 
      // either the landmark or island level.
      interactionsWalk : [],
      
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
      interactionsOptions : [],


      // Function reserved for overriding database options. Good for database 
      // items that are specific to this scenario.
      databaseOverrides ::(){

      
      
      
      },

      // Whether to disable the hunger mechanic. Foods will still exist.
      ignoreHunger : false,


      // List of accolades (achievements) available when beating this scenario.
      accolades : [],
      
      // Text to display when completing the scenario that summarizes highlights 
      // of data that the player did. For example in "The Chosen" scenario, the 
      // number of knockouts is displayed.
      reportCard :: {
        return '';
      }
    });    

  }
}
