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
  renderable,
  categories,
  list,
  onChoice,
  onGetList,
  onGetCategories,
  canCancel,
  onCancel,
  prompt,
  onGetPrompt,
  keep,
  onHover
) {

  @:choices = [];
  @:choiceActs = [];
  @:choiceCategories = [];
  

  @:typeToStr = [
    '//',
    '!!',
    '^^',
    '**',
  ]

  @:pushArt::(id, category){
    choiceCategories->push(:category);
    if (id == empty) ::<= {
      choices->push(:' ▆ - [Empty]')
      choiceActs->push(:empty);
    } else ::<= {
      @art = Arts.find(:id);
      choices->push(:' ▆ - ' + typeToStr[(art.kind)]);
      choiceActs->push(:id);
    }
  }
  
  @:gather:: {
    if (onGetCategories)
      categories = onGetCategories() 
    else if (onGetList)
      list = onGetList() 
        
  
    choices->setSize(:0);
    choiceActs->setSize(:0);
    choiceCategories->setSize(:0);
    if (categories) ::<= {
      foreach(categories) ::(k, set) {
        @:category = set[0];        
        choices->push(:category);
        choiceActs->push();
        choiceCategories->push(:category);
        foreach(set[1]) ::(ind, id) {
          pushArt(id, category);
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
    onGetPrompt,
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
    onCancel : onCancel,
    renderable : {
      render::{
        if (renderable)
          renderable.render();
        
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
      if (onHover) onHover(
        art:choiceActs[which],
        category:choiceCategories[which]
      );
    },
    
    onChoice::(choice) {
      which = choice-1;
      if (onChoice) onChoice(
        art:choiceActs[which],
        category:choiceCategories[which]
      );
    }
  );
}
