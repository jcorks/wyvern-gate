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
@:canvas = import(module:'game_singleton.canvas.mt');
@:Random = import(module:'game_singleton.random.mt');
@:BattleAction = import(module:'game_struct.battleaction.mt');
@:Ability = import(module:'game_database.ability.mt');
@:itemmenu = import(module:'game_function.itemmenu.mt');


return ::(
    party,
    battle,
    user,
    landmark,
    allies,
    enemies             
) {
    @:world = import(module:'game_singleton.world.mt');

    @:commitAction ::(action => BattleAction->type) {
        battle.entityCommitAction(action:action);    
        windowEvent.jumpToTag(name:'BattleMenu', goBeforeTag:true, doResolveNext:true);
    }

    @:options = [...world.scenario.base.interactionsBattle]->filter(
        by:::(value) <- value.filter(user, battle)
    );


    @:choices = [...options]->map(to:::(value) <- value.displayName);


    windowEvent.queueChoiceColumns(
        leftWeight: 1,
        topWeight: 1,
        choices : choices,
        jumpTag: 'BattleMenu',
        keep: true,
        itemsPerColumn: 3,
        prompt: 'What will ' + user.name + ' do?',
        canCancel: false,
        onChoice::(choice) {
            when(choice == 0) empty;
            options[choice-1].onSelect(user, battle, commitAction);        
        }
    );    
}
