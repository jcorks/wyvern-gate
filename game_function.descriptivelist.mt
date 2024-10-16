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

@:Arts = import(:'game_database.arts.mt');
@:windowEvent = import(:'game_singleton.windowevent.mt');
@:ArtsDeck = import(:'game_class.artsdeck.mt');
@:canvas = import(module:'game_singleton.canvas.mt');

return ::(
  renderable,
  items,
  listRatio,
  onChoice,
  onGetItems,
  canCancel,
  onCancel,
  prompt,
  keep,
  onHover
) {

  @which = 0;
  windowEvent.queueChoices(
    prompt,
    leftWeight: 1,
    topWeight: 0.5,
    maxWidth: listRatio,
    onGetChoices ::{
      if (onGetItems != empty) ::<= {
        items = onGetItems();
      }
      
      return items->map(::(value) <- value[0]);
    },    
    keep,
    canCancel: canCancel,
    onCancel : onCancel,
    renderable : {
      render::{
        if (renderable)
          renderable.render();
        
        when(items[which] == empty) empty;
        canvas.renderTextFrameGeneral(
          lines: items[which][1],
          topWeight: 0.5,
          leftWeight: 0,
          maxWidth: 1 - listRatio
        );
      }
    },
    onHover::(choice) {
      which = choice-1;
      if (onHover) onHover(which:which);
    },
    
    onChoice::(choice) {
      which = choice-1;
      if (onChoice) onChoice(which:which);
    }
  );
}
