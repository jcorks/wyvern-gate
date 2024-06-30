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
@:choicesColumns = import(module:'game_function.choicescolumns.mt');
@:g = import(module:'game_function.g.mt');


return ::(inventory => Inventory.type, canCancel => Boolean, onPick => Function, leftWeight, topWeight, prompt, onGetPrompt, goldMultiplier, onHover, renderable, filter, header, leftJustified) {
  when(inventory.items->size == 0) ::<= {
    windowEvent.queueMessage(
      text: 'This inventory is empty.',
      onLeave :: {
        onPick();
      }
    );
  }
  
  @items = []
  choicesColumns(
    leftWeight: if (leftWeight == empty) 1 else leftWeight => Number,
    topWeight:  if (topWeight == empty)  1 else topWeight => Number,
    prompt: if (prompt == empty) 'Choose an item:' else prompt => String,
    onGetPrompt: onGetPrompt,
    canCancel: canCancel,
    jumpTag: 'pickItem',
    onHover : if (onHover)
      ::(choice) {
        when(choice == 0) empty;
        onHover(item:inventory.items[choice-1])
      }
    else 
      empty,
    renderable : renderable,
    onGetChoices ::{
      
      items = if (filter != empty)
        inventory.items->filter(by:filter)
      else  
        [...inventory.items]
      ;
    
      @:names = [...items]->map(to:::(value) {
        return value.name;
      });
      
      @:gold = [...items]->map(to:::(value) {
        @go = value.price * goldMultiplier;
        go = go->ceil;
        return if (go < 1)
          '?G' /// ooooh mysterious!
        else
          g(g:go);      
      });
      when(names->keycount == 0) ::<={
        windowEvent.queueMessage(text: "The inventory is empty.");
        return [[], []];
      }
      return [
        names,
        gold
      ];
    },
    header : header,
    leftJustified : leftJustified,
    keep:true,
    onChoice ::(choice) {
      when(choice == 0) onPick();
      onPick(item:items[choice-1]);
    }
  );
}
