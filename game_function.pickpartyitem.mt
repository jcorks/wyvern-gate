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


return ::(canCancel => Boolean, onPick => Function, leftWeight, topWeight, prompt, onGetPrompt, filter) {
  @:world = import(module:'game_singleton.world.mt');
  @listNames = []
  @listReal = []

  foreach(world.party.members) ::(k, member) {
    @:prefix = member.name + ": ";
    foreach(Entity.EQUIP_SLOTS) ::(k, slot) {
      when(slot == Entity.EQUIP_SLOTS.HAND_R) empty;
      @:item = member.getEquipped(slot);
      when(item == empty) empty;
      when(item.base.id == 'base:none') empty;
      
      when(filter != empty && ! filter(item)) empty;
      listNames->push(value: prefix + item.name);
      listReal->push(value:item);
    }
  }
  
  foreach(world.party.inventory.items) ::(k, item) {
    when(filter != empty && ! filter(item)) empty;
    listReal->push(value:item);
    listNames->push(value:item.name);
  }
  

  when(listNames->keycount == 0) ::<={
    windowEvent.queueMessage(text: "No items were found.");
    onPick();
  }

  windowEvent.queueChoices(
    leftWeight: if (leftWeight == empty) 1 else leftWeight => Number,
    topWeight:  if (topWeight == empty)  1 else topWeight => Number,
    prompt: if (prompt == empty) 'Choose a party item:' else prompt => String,
    onGetPrompt: onGetPrompt,
    canCancel: canCancel,
    jumpTag: 'pickItem',
    onGetChoices ::{
      return listNames;
    },
    keep:true,
    onChoice ::(choice) {
      when(choice == 0) onPick();
      onPick(item:listReal[choice-1]);
    }
  );
}
