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
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:Entity = import(module:'game_class.entity.mt');


return ::(canCancel => Boolean, onPick => Function, keep, onCancel, leftWeight, topWeight, prompt, onGetPrompt, filter) {
  @:world = import(module:'game_singleton.world.mt');


  @:all = world.party.getAllItems();
  @:items = all[0]
  @:equippedBy = all[1];
  @:altNames = [];

  @:inv = Inventory.new(size:99999);
  foreach(items) ::(i, v) {
      @prefix = '';
      
      if (equippedBy[i] != empty) ::<= {
        prefix = equippedBy[i].name + ': ';
      }
      inv.add(:v);
      altNames[v] = prefix + v.name;
  }
  
  @:pickItem = import(:'game_function.pickitem.mt');

  pickItem(
    inventory : inv,
    leftWeight: if (leftWeight == empty) 1 else leftWeight => Number,
    topWeight:  if (topWeight == empty)  1 else topWeight => Number,
    filter,
    alternateNames : altNames,
    prompt: if (prompt == empty) 'Choose a party item:' else prompt => String,
    onGetPrompt: onGetPrompt,
    canCancel: canCancel,
    onCancel : onCancel,
    keep:if (keep == empty) true else keep,
    onPick ::(item) {
      breakpoint();
      onPick(item, equippedBy:equippedBy[item]);
    }
  );
}
