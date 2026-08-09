/*
  Wyvern Gate, a procedural, console-based RPG
  Copyright (C) 2023, Johnathan Corkery (jcorkery@umich.edu)

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'core/data/database.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:databaseItemMutatorClass = import(module:'core/data/databaseitemmutatorclass.mt');


@:reset ::{
  /*
  Scenario.database.newEntry(
    data : import(module:'mods/the-chosen/main.mt')
  )   
  Scenario.database.newEntry(
    data : import(module:'mods/the-trader/main.mt')
  )   
  
  Scenario.database.newEntry(
    data : import(module:'game_scenario.therogue.mt')
  ) 
  */  
}



@:Scenario = databaseItemMutatorClass.create(
  name: 'Wyvern.Scenario',
  items : {
    data : empty
  },
  database : 
    Database.new(
      name : 'Wyvern.Scenario.Base',
      attributes : {
        name : String,
        id : String,
        events : Object,

        
        // Whether the naming of the file is skipped. If false,
        // the file name is the empty string.
        skipName : Boolean,
        
        // Whether the scenario allows the "friend" mechanic, where after battle 
        // theres a chance your former enemy will become a friend.
        everyoneIsAFriend : Boolean,
        
        // Whether to remove the hunger mechanic from the scenario.
        // Most scenarios keep this to true
        ignoreHunger : Boolean,  
        
        
        
        // provides the options one has when interacting with a person.
        // Each member is an InteractionMenuEntry. Each function is passed an Entity
        // The filter and onChoice accept the entity.
        interactionsPerson : Object,

        // provides the options one has when interacting with a location.
        // Each member is an InteractionMenuEntry. Each function is passed a Location
        interactionsLocation : Object,

        // provides the options one has when interacting with a landmark.
        // Each member is an InteractionMenuEntry.  Each function is passed a Landmark
        interactionsLandmark : Object,
                
        // provides the options available when exploring an island or landmark.
        // Each member is an InteractionMenuEntry. Each function is passed the current island and landmark if applicable.
        interactionsWalk: Object, 
  
        // provides the options available when commanding the party in battle.
        // Each member is an InteractionMenuEntry. Each function is passed the Battle instance and the user.
        // In addition, the onSelect function will be passed a "commitAction" function. This shall 
        // be called when the handler has finished choosing an action to commit for the user entity.
        // This will automatically back out of any existing menus that were placed since 
        // the onSelect function was called.
        interactionsBattle : Object,
        
        // Provides the options available when opening the options menu.
        // Each member is an InteractionMenuEntry. Each function is passed the current island and landmark if applicable.
        interactionsOptions : Object,
        
        
        // Function dedicated to replacing database items before loading.
        databaseOverrides : Function,
        
        // An array of accolades to recount once the game is completed.
        accolades : Object,
        
        // A function to return a small table of stats once a new record (game complete) 
        // is reached. If no such data makes sense, this can simply return an empty string.
        reportCard : Function
      },
      
      reset,
      
      knownEvents : [
        // the function to start off the scenario
        'onBegin',
        // Function called when a new day starts.
        'onNewDay',
        // Function called when loading a save.
        'onResume',
        // Function to be called when a party member experiences death.
        'onDeath'        
              
      ]
    ),
  define::(this, state) {
    this.interface = {
      defaultLoad ::(base) {
        state.data = {};
        state.base.databaseOverrides();
      },
      
      load ::(serialized) {
        @:base = Scenario.database.find(id:serialized.base.id);
        base.databaseOverrides();
        state.load(parent:this, serialized);
      },
      
      data : {
        get ::<- state.data
      },
      
      markNewDay :: {
        state.base.emit(event:'onNewDay', data:state.data)
      },

      resume :: {
        state.base.emit(event:'onResume', data:state.data)
      },
      
      death ::(entity) {
        state.base.emit(event:'onDeath', data:state.data, entity);
      },
      
      start ::{
        state.base.emit(event:'onBegin', data:state.data);      
      }
    }
  }
);





return Scenario;

