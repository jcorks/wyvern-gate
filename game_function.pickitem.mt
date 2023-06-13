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
@:dialogue = import(module:'game_singleton.dialogue.mt');
@:Inventory = import(module:'game_class.inventory.mt');



return ::(inventory => Inventory.type, canCancel => Boolean, onPick => Function, leftWeight, topWeight, prompt) {
    dialogue.choices(
        leftWeight: if (leftWeight == empty) 1 else leftWeight => Number,
        topWeight:  if (topWeight == empty)  1 else topWeight => Number,
        prompt: if (prompt == empty) 'Choose an item:' else prompt => String,
        canCancel: canCancel,
        onGetChoices ::{
            @:names = [...inventory.items]->map(to:::(value) {return value.name;});
            when(names->keycount == 0) ::<={
                dialogue.message(text: "The inventory is empty.");
            };
            return names;
        },
        keep:true,
        onChoice ::(choice) {
            when(choice == 0) onPick();
            onPick(item:inventory.items[choice-1]);
        }
    );
};
