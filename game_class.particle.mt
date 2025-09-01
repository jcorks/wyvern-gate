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

@:canvas = import(module:'game_singleton.canvas.mt');
@:class = import(module:'Matte.Core.Class');
@:Map = import(:'game_class.map.mt');
@:randomRange ::(from, to) <- from + Number.random() * (to - from)


return class(
  name : 'Wyvern.ParticleEmitter',
  define ::(this) {
    @onFrameFunc;
    @onDoneFunc;
    
    @directionMin_
    @directionMax_
    @directionDeltaMin_
    @directionDeltaMax_
    @speedMin_
    @speedMax_
    @speedDeltaMin_
    @speedDeltaMax_
    @characters_
    @lifeMin_
    @lifeMax_
    @map_
    
    @particles = [];
    @stopped = false;

    @x_ = 0;
    @y_ = 0;
    @count;


    this.constructor = ::(
      directionMin => Number,
      directionMax => Number,
      directionDeltaMin => Number,
      directionDeltaMax => Number,
      speedMin => Number,
      speedMax => Number,
      speedDeltaMin => Number,
      speedDeltaMax => Number,
      characters => Object,
      lifeMin => Number,
      lifeMax => Number
    ) {
      directionMin_ = directionMin
      directionMax_ = directionMax
      directionDeltaMin_ = directionDeltaMin
      directionDeltaMax_ = directionDeltaMin
      speedMin_ = speedMin
      speedMax_ = speedMax
      speedDeltaMin_ = speedDeltaMin
      speedDeltaMax_ = speedDeltaMax
      characters_ = characters
      lifeMin_ = lifeMin
      lifeMax_ = lifeMax
    }  
    
    
    @:emit :: {
      if (count == empty) count = 1;
      
      for(0, count) ::(i) {
        @:life = randomRange(from:lifeMin_, to:lifeMax_)
        particles[{
          life           : life,
          maxLife        : life,
          direction      : randomRange(from:directionMin_, to:directionMax_),
          directionDelta : randomRange(from:directionDeltaMin_, to:directionDeltaMax_),
          speed          : randomRange(from:speedMin_, to:speedMax_),
          speedDelta     : randomRange(from:speedDeltaMin_, to:speedDeltaMax_),
          
          characterIndex : 0,
          x : x_,
          y : y_
        }] = true; 
      }
      
      if (effectActive == false) ::<= {
        @:canvas = import(module:'game_singleton.canvas.mt');
        canvas.addEffect(:effect);
        effectActive = true;
      }              
    }
    
      
    @:nextFrame ::{
      if (onFrameFunc) onFrameFunc();
    
      foreach(particles) ::(particle, nu) {
        particle.life -= 1;
        when (particle.life <= 0) particles->remove(:particle);
        
        particle.speed += particle.speedDelta;
        particle.direction += particle.directionDelta;
        
        particle.x += (particle.speed * particle.direction->asRadians->cos);
        particle.y += (particle.speed * particle.direction->asRadians->sin);

      }
    }
    
    @:render ::{
      foreach(particles) ::(particle, nu) {

        if (map_)
          canvas.movePen(
            x:map_.xMapToScreen(:particle.x->floor)->floor, 
            y:map_.yMapToScreen(:particle.y->floor)->floor
          )
        else
          canvas.movePen(
            x:particle.x->floor, 
            y:particle.y->floor
          );
        
        canvas.drawText(
          text: characters_[((1 - particle.life / particle.maxLife) * characters_->size)->floor]
        );
      }
    }    
    
    
    @effectActive = false;
    @:effect :: {
      when (canvas.showEffects == false)
        stopped = true;
        
        
      nextFrame();
      if (canvas.showEffects) render();
      
      if (stopped == false)
        emit();
      
      when (particles->keycount == 0) ::<= {
        @:canvas = import(module:'game_singleton.canvas.mt');
        effectActive = false;
        if (onDoneFunc) onDoneFunc()
        return canvas.EFFECT_FINISHED;
      }
    }
    
    this.interface = {
      move::(x, y) {
        x_ = x;
        y_ = y
      },
      
      'emit' : emit,
      
      tether::(map => Map.type) {
        map_ = map;
      },
      
      // NOT CALLED if effects are disabled.
      onFrame : {
        set::(value) <- onFrameFunc = value
      },
      
      // NOT CALLED if effects are disabled.
      onDone : {
        set::(value) <- onDoneFunc = value
      },
      
      start::(emitCount) {
        count = emitCount;
        stopped = false;
        emit();
      },
      
      stop ::{
        stopped = true;
      }
    }
  }
);
