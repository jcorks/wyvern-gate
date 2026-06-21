/*
  Wyvern Gate, a procedural, console-based RPG
  Copyright (C) 2026, Johnathan Corkery (jcorkery@umich.edu)

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



@:class = import(module:'Matte.Core.Class');




return class(
  name : 'Wyvern.HUD',
  define ::(this) {
    @:canvas = import(module:'game_singleton.canvas.mt');

    @enabled = true;
    
    @sets = [];
    
    
    // ID to lines
    @onDisplayLines = {};
    @:onDisplay ::(landmark, island) {
      when (onDisplayLines->size == 0) empty;
      @lines = [];
      foreach(onDisplayLines) ::(k, v) {
        foreach(v) ::(index, line) {
          lines->push(:line)
        }
        lines->push(:'');
      }
      canvas.renderTextFrameGeneral(
        leftWeight: 1,
        topWeight: 0,
        lines
      );
    }
    
    sets->push(:{
      name : 'built-in-display',
      onIslandStep : onDisplay,
      onLandmarkStep : onDisplay
    });
    
    this.interface = {
      addRenderer :: (
        name,
        onIslandStep,
        onLandmarkStep
      ) {
        @:out = {
          name : name,
          onIslandStep : onIslandStep,
          onLandmarkStep : onLandmarkStep
        }
        sets->push(:out);
        return out;
      },
      
      addDisplay ::(
        lines
      ) {
        onDisplayLines->push(:lines)
        return lines;
      },
      
      removeDisplay ::(lines) {
        onDisplayLines = onDisplayLines->filter(::(value) <- value != lines)
      },
      
      remove ::(key) {
        sets = sets->filter(::(value)<- value != key);
      },
      
      clear ::{
        sets = [];
        sets->push(:{
          name : 'built-in-display',
          onIslandStep : onDisplay,
          onLandmarkStep : onDisplay
        });
      },
      
      render ::(island, landmark) {

        when(enabled == false) empty;
        if (landmark != empty) ::<= {
          foreach(sets) ::(k, v) {
            if (v.onLandmarkStep) v.onLandmarkStep(landmark, island);
          }
        } else ::<= {
          foreach(sets) ::(k, v) {
            if (v.onIslandStep) v.onIslandStep(landmark, island);
          }
        
        }
      },
      
      enable : {
        get ::<- enabled,
        set ::(value) <- enabled = value
      },
    }
  }
).new();


