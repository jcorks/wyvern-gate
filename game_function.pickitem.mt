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



return ::(inventory => Inventory.type, canCancel => Boolean, onPick => Function, leftWeight, topWeight, prompt, onGetPrompt, showGold, goldMultiplier, onHover, renderable) {
    windowEvent.queueChoices(
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
            @:names = [...inventory.items]->map(to:::(value) {
                when(showGold) ::<= {
                    @g = value.price * goldMultiplier;
                    g = g->ceil;
                    return if (g < 1)
                        value.name + '(?G)' /// ooooh mysterious!
                    else
                        value.name + '(' + g + 'G)';
                }
                return value.name;
            });
            when(names->keycount == 0) ::<={
                windowEvent.queueMessage(text: "The inventory is empty.");
            }
            return names;
        },
        keep:true,
        onChoice ::(choice) {
            when(choice == 0) onPick();
            onPick(item:inventory.items[choice-1]);
        }
    );
}
