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
@:Database = import(module:'game_class.database.mt');







@:reset :: {
@:StateFlags = import(module:'game_class.stateflags.mt');


ItemEnchantCondition.newEntry(
  data : {
    name : 'On Attack',
    id : 'base:on-attack',
    description : 'After the wielder attacks',        
    isState : false,
    effectEvent: 'onPostAttackOther',     
  }
)

ItemEnchantCondition.newEntry(
  data : {
    name : 'On Hurt',
    id : 'base:on-hurt',
    description : 'After the wielder is hurt',        
    isState : false,
    effectEvent: 'onPostDamage'      
  }
)

ItemEnchantCondition.newEntry(
  data : {
    name : 'On Discard',
    id : 'base:on-discard',
    description : 'After the wielder discards an Art',
    isState : false,
    effectEvent: 'onDiscard'
  }
)

ItemEnchantCondition.newEntry(
  data : {
    name : 'On React',
    id : 'base:on-react',
    description : 'After the wielder reacts',
    isState : false,
    effectEvent: 'onPostReact'
  }
)


ItemEnchantCondition.newEntry(
  data : {
    name : 'On Defeat Enemy',
    id : 'base:on-defeat-enemy',
    description : 'After the wielder defeats an enemy',        
    isState : false,
    effectEvent: 'onKnockout'
  }
)    



ItemEnchantCondition.newEntry(
  data : {
    name : 'On Critical Hit',
    id : 'base:on-crit',
    description : 'After the wielder successfully lands a critical hit',
    isState : false,
    effectEvent : 'onCrit'
  }
)





ItemEnchantCondition.newEntry(
  data : {
    name : 'On Turn',
    id : 'base:turn',
    description : 'At the start of the wielder\'s turn',        
    isState : false,
    effectEvent : 'onNextTurn'
  }
)
}

// conditions are checked at the end of turns
@:ItemEnchantCondition = Database.new(
  name : 'Wyvern.ItemEnchantCondition',
  attributes : {
    name : String,
    id : String,
    description : String,
    isState : Boolean,
    effectEvent : String
  },
  reset
);


return ItemEnchantCondition;
