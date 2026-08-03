@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'core/data/database.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:windowEvent = import(module:'core/windowevent.mt');
@:Damage = import(module:'base/entity/damage.mt');
@:Item = import(module:'base/item.mt');
@:correctA = import(module:'base/util/correcta.mt');
@:random = import(module:'core/random.mt');
@:canvas = import(module:'core/graphics/canvas.mt');
@:namegen = import(module:'base/namegen.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:databaseItemMutatorClass = import(module:'core/data/databaseitemmutatorclass.mt');
@:InteractionMenuEntry = import(module:'base/interaction/menuentry.mt');
@:commonInteractions = import(module:'base/interaction/common.mt');
@:Personality = import(module:'base/entity/personality.mt');
@:g = import(module:'base/util/g.mt');
@:Accolade = import(module:'base/accolade.mt');
@:loading = import(module:'base/widgets/loading.mt');
@:romanNum = import(module:'base/util/romannumerals.mt');
@:ParticleEmitter = import(module:'core/graphics/particle.mt');
@:Landmark = import(module:'base/map/landmark.mt');
@:Island = import(module:'base/map/island.mt');
@:Species = import(module:'base/entity/species.mt');
@:LandmarkEvent = import(module:'base/event/landmark.mt');
@:DungeonMap = import(:'base/map/dungeon.mt');
@:Profession = import(module:'base/entity/profession.mt');
@:Arts = import(module:'base/arts.mt');
@:Entity = import(module:'base/entity.mt');
@:Location = import(module:'base/map/location.mt');
@:State = import(module:'core/data/state.mt');
@:Inventory = import(module:'base/item/inventory.mt');
@:world = import(module:'base/world.mt');
@:pickItem = import(:'base/widgets/pickitem.mt');

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



  skipName : false,
  everyoneIsAFriend : true,

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
  // Whether to disable the hunger mechanic. Foods will still exist.
  ignoreHunger : false,

  // Text to display when completing the scenario that summarizes highlights 
  // of data that the player did. For example in "The Chosen" scenario, the 
  // number of knockouts is displayed.
  reportCard :: {
    return '';
  },

  events : {
    // Called when a new day starts
    onNewDay ::(data){},

    // Called when a file is loaded with this scenario 
    onResume ::(data){
      theRogue.context = data[DATA_KEY];  
    
      @world = import(module:'base/world.mt');
      @:instance = import(module:'game_singleton.instance.mt');
      world.island.travel();       
      if (world.landmark) ::<= {
        world.landmark.travel();
      }      
    },
    
    // Called when a party member dies.
    onDeath ::(data, entity){},
    onBegin ::(data) {
    
      @:instance = import(module:'game_singleton.instance.mt');
      @:story = import(module:'base/story.mt');
      @world = import(module:'base/world.mt');
      @:LargeMap = import(module:'base/map/large.mt');
      @party = world.party;      

      theRogue.context = theRogueClass.new();
      data[DATA_KEY] = theRogue.context;

      instance.gameOver(reason:'This isn\'t ready yet!!!');
      return empty;
      
    


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
          island.landmarks[0].visit();
        });
      });



    }  
  }
}

return theRogue;
