@:windowEvent = import(module:'game_singleton.windowevent.mt');


/* 
    This represents the most basic 
    scenario possible with default entries for 
    most aspects of the scenario.
    
    For behavior of each of these

*/

return {
    name : 'Example Scenario',
    
    // Called when first starting the scenario.
    onBegin ::(data) {
        windowEvent.queueMessage(
            speaker: 'System',
            text: 'The scenario has begun.'
        );
    },
    
    // Called when a new day starts
    onNewDay ::(data){},

    // Called when a file is loaded with this scenario 
    onResume ::(data){},
    
    // Called when a party member dies.
    onDeath ::(data, entity){},


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
}
