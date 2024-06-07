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

return ::(
  categories,
  list,
  onChoice,
  onGetList,
  onGetCategories,
  canCancel,
  prompt,
  keep,
  onHover
) {

  @:choices = [];
  @:choiceActs = [];

  @:typeToStr = [
    '//',
    '!!',
    '^^',
    '**',
  ]

  @:pushArt::(id){
    @art = Arts.find(:id);
    choices->push(:' ▆ - ' + typeToStr[(art.kind)]);
    choiceActs->push(:id);
  }
  
  @:gather:: {
    if (onGetCategories)
      categories = onGetCategories() 
    else if (onGetList)
      list = onGetList() 
        
  
    choices->setSize(:0);
    choiceActs->setSize(:0);
    if (categories) ::<= {
      foreach(categories) ::(category, set) {
        choices->push(:category + ':');
        choiceActs->push();
        foreach(set) ::(ind, id) {
          pushArt(id);
        }
      }
    } else if (list) ::<= {
      foreach(list) ::(ind, id) {
        pushArt(id);    
      }
    }
  }

  gather();
  @which = 0;
  windowEvent.queueChoices(
    choices,
    prompt,
    leftWeight: 1,
    topWeight: 0.5,
    maxWidth: 0.3,
    onGetChoices: if (onGetList != empty || onGetCategories != empty) 
        ::{
          gather();
          return choices;
        }
      else
        empty 
    ,    
    keep,
    canCancel: canCancel,
    renderable : {
      render::{
        when(choiceActs[which] == empty) empty;
        ArtsDeck.renderArt(
          handCard: ArtsDeck.synthesizeHandCard(id:choiceActs[which]),
          topWeight: 0.5,
          leftWeight: 0,
          maxWidth: 0.7
        );
      }
    },
    onHover::(choice) {
      which = choice-1;
      if (onHover) onHover(:which);
    },
    
    onChoice::(choice) {
      which = choice-1;
      if (onChoice) onChoice(:which);
    }
  );
}
