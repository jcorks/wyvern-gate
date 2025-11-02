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

@:theRogueInitDatabase = import(:'game_scenario.therogue.database.mt');
@:theRogueClass        = import(:'game_scenario.therogue.class.mt');
@:characterCreator     = import(:'game_scenario.therogue.charactercreator.mt');


/*

main area:
- venerated inventory: inventory to save across runs 
  - sacrifices the item for the run, but stores it there for other runs 
  - can do the same for G
- unlockable after death?
- Arts are always kept, only inventory is wiped


sub-areas:
- Rest place that contains places to upgrade 
- Always gets 3 choices, each costs money
  - Level up x2
  - Enchanter 
  - Generic Shop (fully stocked)
  - Free mone
  - Temporary teammate (one stint, matches current NPC level)
  - 2 Arts packs 
  -
  


completion:
- 5 floor stints
- NPC Level increase after each
-.Boss after 4 stints
*/



@:DATA_KEY = 'therogue';







@:theRogue = {
  name : 'The Rogue',
  id : 'rasa:therogue',
  
  context : empty,


  // Called when a new day starts
  onNewDay ::(data){},

  // Called when a file is loaded with this scenario 
  onResume ::(data){
    theRogue.context = data[DATA_KEY];  
  
    @world = import(module:'game_singleton.world.mt');
    @:instance = import(module:'game_singleton.instance.mt');
    instance.islandTravel();
    if (world.landmark) ::<= {
      instance.landmarkTravel();
    }      
  },
  
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
  databaseOverrides ::{
    theRogueInitDatabase();  
  },
  
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

    theRogue.context = theRogueClass.new();
    data[DATA_KEY] = theRogue.context;
    
  


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

return theRogue;
