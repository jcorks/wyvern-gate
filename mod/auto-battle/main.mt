@:Item = import(module:'game_mutator.item.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Scenario = import(module:'game_mutator.scenario.mt');


return { 
  onGameStartup ::{
  },

  onDatabaseStartup :: {
    breakpoint();
    Scenario.database.newEntry(data:{
      name : 'Test Battle',
      
      id: 'mod.example.rasa.auto-battle:start',
      
      // Called when first starting the scenario.
      onBegin ::(data) {

        @:world = import(module:'game_singleton.world.mt');
        @:instance = import(module:'game_singleton.instance.mt');

        @:Entity = import(module:'game_class.entity.mt');
        @:Species = import(module:'game_database.species.mt');
        @:Profession = import(module:'game_database.profession.mt');
    
    
        @:island = world.createIsland().island;
        world.island = island;
    
        @:getNPC::(data) {
          @:ent = Entity.new(
            island,
            
            speciesHint:  if (data.species == empty)
                  Species.getRandomFiltered(
                  filter:::(value) <- (value.traits & Species.TRAITS.SPECIAL) == 0
                ).id 
              else 
                data.species,
                
            levelHint: if (data.level == empty)
                6
              else 
                data.level,
            professionHint: if (data.profession == empty) 
                Profession.getRandomFiltered(filter::(value)<-value.learnable).id 
              else 
                data.profession
          );
          
          if (data.giveWeapon) ::<= {
            @:wep = Item.database.getRandomFiltered(
              filter:::(value) <-
                value.isUnique == false &&
                value.attributes & Item.database.statics.ATTRIBUTE.WEAPON
            );
              
            ent.equip(
              slot:Entity.EQUIP_SLOTS.HAND_LR, 
              item:Item.new(
                base:wep
              ), 
              inventory:ent.inventory, 
              silent:true
            );          
          }
          
          
          if (data.giveArmor) ::<= {
            @:wep = Item.database.getRandomFiltered(
              filter:::(value) <-
                value.isUnique == false &&
                value.equipType == Item.database.statics.TYPE.ARMOR
            );;
              
            ent.equip(
              slot:Entity.EQUIP_SLOTS.ARMOR, 
              item:Item.new(
                base: wep
              ), 
              inventory:ent.inventory, 
              silent:true
            );          
          }
          
          foreach(data.arts) ::(k, v) {
            ent.supportArts->push(:v);
          }

          if (data.name) 
            ent.name = data.name;
          
          return ent;
        }
        
        @:teamA = [
          getNPC(:import(:'mod.example.rasa.auto-battle/npc1-1.mt')),
          getNPC(:import(:'mod.example.rasa.auto-battle/npc1-2.mt')),      
          getNPC(:import(:'mod.example.rasa.auto-battle/npc1-3.mt'))
        ]



        @:teamB = [
          getNPC(:import(:'mod.example.rasa.auto-battle/npc2-1.mt')),
          getNPC(:import(:'mod.example.rasa.auto-battle/npc2-2.mt')),      
          getNPC(:import(:'mod.example.rasa.auto-battle/npc2-3.mt'))
        ]
        
        

        world.battle.start(
          party: import(:'game_class.party.mt').new(),
          npcBattle : true,
          allies: teamA,
          enemies : teamB,
          landmark: {},
          onStart :: {
          },
          onEnd ::(result) {          
            @:instance = import(module:'game_singleton.instance.mt');
            instance.quitRun();
          }
        );

      },
      
      // Called when a new day starts
      onNewDay ::(data){},

      // Called when a file is loaded with this scenario 
      onResume ::(data){},
      
      // Called when a party member dies.
      onDeath ::(data, entity){},

      skipName : true,

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
      interactionsBattle : [],
      
      // List of general options available, such as quitting the game.
      interactionsOptions : [],


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
      }
    });    

  }
}
