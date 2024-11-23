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




return ::(inventory => Inventory.type, canCancel => Boolean, onPick => Function, leftWeight, topWeight, prompt, onGetPrompt, onHover, renderable, filter, keep, pageAfter, onCancel, showPrices, goldMultiplier, header) {
  @names = []
  @items = []
  @picked;
  @cancelled = false;

  @:gold = ::(value) {
    @go = value.price * goldMultiplier;
    go = go->ceil;
    return if (go < 1)
      '?G' /// ooooh mysterious!
    else
      g(g:go);
  }

  windowEvent.queueNestedResolve(
    onEnter :: {
      when(inventory.items->size == 0) ::<={
        windowEvent.queueMessage(text: "The inventory is empty.");
      }
    
    
      choicesColumns(
        leftWeight: if (leftWeight == empty) 1 else leftWeight => Number,
        topWeight:  if (topWeight == empty)  1 else topWeight => Number,
        prompt: if (prompt == empty) 'Choose an item:' else prompt => String,
        onGetPrompt: onGetPrompt,
        canCancel: canCancel,
        jumpTag: 'pickItem',
        separator: '|',
        leftJustified : [true, false, true],
        pageAfter: pageAfter,
        header : header,
        onCancel::{cancelled = true;},
        onHover : if (onHover)
          ::(choice) {
            when(choice == 0) empty;
            onHover(item:inventory.items[choice-1])
          }
        else 
          empty,
        renderable : renderable,
        onGetChoices ::{
          @:Item = import(:'game_mutator.item.mt'); 
        
          items = if (filter != empty)
            inventory.items->filter(by:filter)
          else  
            [...inventory.items]
          ;
          @:alreadyCounted = [];

          items = items->filter(::(value) {
            when(value.base.hasNoTrait(:Item.TRAIT.STACKABLE)) true;
            if (alreadyCounted[value.base.id] == empty) 
              alreadyCounted[value.base.id] = 0;
            alreadyCounted[value.base.id] += 1;
            when(alreadyCounted[value.base.id] == 1) true;
            return false;
          });

          names = [...items]->map(to:::(value) <- 
            value.name
          );
          
          @:amounts = items->map(to:::(value) <-
            if (alreadyCounted[value.base.id]->type == Number && alreadyCounted[value.base.id] > 1)
              'x'+alreadyCounted[value.base.id]  
            else if (value.faveMark != '')
              ' ' + value.faveMark
            else
              ''
          );
          
          @:prices = items->map(to:::(value) <- 
            if (showPrices != true) 
              ''
            else
              gold(:value)
          )

          return [names, prices, amounts];
        },
        keep: if (keep == empty) true else keep,
        onChoice ::(choice) {
          when(choice == 0) empty;
          picked = items[choice-1];
          onPick(item:picked)
        }
      );
    },
    
    onLeave ::{
      if (cancelled && onCancel) 
        onCancel();
    }
  )
}
