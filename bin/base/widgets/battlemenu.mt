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
@:windowEvent = import(module:'core/windowevent.mt');
@:canvas = import(module:'core/graphics/canvas.mt');
@:Random = import(module:'core/random.mt');
@:BattleAction = import(module:'base/battle/action.mt');
@:Arts = import(module:'base/arts.mt');
@:itemmenu = import(module:'base/widgets/itemmenu.mt');


@battleMenu = ::(
  party,
  battle,
  user,
  landmark,
  allies,
  enemies       
) {
  @:world = import(module:'base/world.mt');

  @:commitAction ::(action => BattleAction->type) {
    if (
      Arts.database.find(id:action.card.id).kind == Arts.KIND.ABILITY ||
      Arts.database.find(id:action.card.id).kind == Arts.KIND.SPECIAL
    ) ::<= {
      windowEvent.jumpToTag(name:'BattleMenu', goBeforeTag:true)
      battle.entityCommitAction(action:action);  
    } else ::<= {
      windowEvent.jumpToTag(name:'BattleMenu')
      battle.commitFreeAction(action:action, onDone::{
        windowEvent.jumpToTag(name:'BattleMenu');
      });  
    }

  }

  @:options = [...world.scenario.base.interactionsBattle]->filter(
    by:::(value) <- value.filter(user, battle)
  );


  @:choices = [...options]->map(to:::(value) <- value.name);

  @:next = ::{
    battle.requestRedrawBG();
    windowEvent.queueChoiceColumns(
      leftWeight: 1,
      topWeight: 1,
      choices : choices,
      jumpTag: 'BattleMenu',
      keep: true,
      itemsPerRow: 2,
      prompt: 'What will ' + user.name + ' do?',
      canCancel: false,
      onKept ::<-     battle.requestRedrawBG(),
      onChoice::(choice) {
        when(choice == 0) empty;
        options[choice-1].select(user, battle, commitAction);    
      }
    );   
  }

  windowEvent.queueNestedResolve(
    onEnter: next
  )



}

return battleMenu;
