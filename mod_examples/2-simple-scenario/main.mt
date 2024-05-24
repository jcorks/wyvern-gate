@:Item = import(module:'game_mutator.item.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Scenario = import(module:'game_mutator.scenario.mt');
// Note that imports for your mod are prefixed with
// the name of the mod as specified in the mod.json
@:MyScenario = import(module:'mod.example.rasa.simplescenario/scenario.mt');

/*

  2 simple scenario.
  
  This shows 2 concepts. First, how it works when you have 
  multiple files, and second how Scenarios are added 
  and information 

*/


return { 
  // This is called right when the mod is first loaded, after 
  // the "loadFirst" mods have loaded, if any.
  onGameStartup ::{
    // itll be annoying for a user if you prompt this every time a mod loads.
    // Its more common to do checking and initial work needed, as this is run once per 
    // game invocation.
    windowEvent.queueMessage(
      text: 'Simple scenario has been loaded.'
    );
  },

  // This is called right when a player starts to choose or loads 
  // a scenario. This happens after the base database items 
  // are loaded, so this is most commonly used for modifying 
  // databases.
  onDatabaseStartup :: {
    Scenario.database.newEntry(data:MyScenario)
  }
}
