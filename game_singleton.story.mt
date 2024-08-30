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
@:State = import(module:"game_class.state.mt");
@:LoadableClass = import(module:"game_singleton.loadableclass.mt");
@:Entity = import(module:'game_class.entity.mt');
@:EntityQuality = import(module:'game_mutator.entityquality.mt');
@:Item = import(module:'game_mutator.item.mt');


@:ITEM_SOURCE = {
  

  
  // whether the player has seen the wandering gamblist
  skieEncountered : false,
  
  // The recurring NPCs in the game that are recruitable
  npcs: {},
  
  
  // base level hint. If this changes... well....
  levelHint : 6,
  
  // Number of discovered locations
  data_locationsDiscovered : 0,
  
  data_locationsNeeded : 25
}

@:Story = LoadableClass.create(
  name : 'Wyvern.Story',
  items : ITEM_SOURCE,

  define::(this, state) {
    @:interface = {
      defaultLoad::{}
    };
    foreach(ITEM_SOURCE) ::(item, val) {
      interface[item] = {
        get ::<- state[item],
        set ::(value) <- state[item] = value
      }
    }

    this.interface = interface;
  }

);

return Story.new();
