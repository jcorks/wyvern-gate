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
@:Landmark = import(module:'game_mutator.landmark.mt');



return { 
  onGameStartup ::{
  },

  onDatabaseStartup :: {

    Scenario.database.newEntry(data:{
      name : 'Landmark Viewer',
      
      id: 'mod.dev.rasa.landmark-viewer:start',
      
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

          @:visitIsland = ::(island, landmark) {
          
          }


          world.loadIsland(
            key:keyhome, 
            skipSave:true,
            onDone ::(island){
              @:allLandmarks = Landmark.database.getAll()
                ->map(::(value) <- value.id)
              allLandmarks->sort(::(a, b) <- a < b);
                  
              windowEvent.queueChoices(
                choices : allLandmarks->map(::(value) <- Landmark.database.find(:value).name),
                prompt: 'Pick a landmark to generate.',
                onChoice::(choice) {
                  @:id = allLandmarks[choice-1];
                  @:landmark = Landmark.new(
                    island,
                    base : Landmark.database.find(:id),
                    width:0,
                    height:0
                  );
                  island.addLandmark(:landmark);
                  
                  landmark.visit(where : if (landmark.map.areas->size > 0)
                      ::(landmark)<- landmark.getRandomEmptyPosition()
                    else empty
                  );
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
