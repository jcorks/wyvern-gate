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
@:random = import(module:'game_singleton.random.mt');
@:Landmark = import(module:'game_mutator.landmark.mt');
@:Map = import(module:'game_class.map.mt');

@:mapSizeW  = 38;
@:mapSizeH  = 16;

@:BUFFER_SPACE = 80;

@:EPSILON = 0.000001;

@:distance::(x0, y0, x1, y1) {
  @xd = x1 - x0;
  @yd = y1 - y0;
  return (xd**2 + yd**2)**0.5;
}

@:addLandscapeAreas ::(map, width, height, symbols, out, symbolList) {
  @:SEED_COUNT = ((width*height)**0.5) / 2.5

  @emptyAreas = [];
  @outAreas = [];
  for(BUFFER_SPACE, height + BUFFER_SPACE) ::(y) {
    for(BUFFER_SPACE, width + BUFFER_SPACE) ::(x) {
      @:which = out[x + (width + BUFFER_SPACE*2) * y];

      if (which == symbolList[0] || which == empty) ::<= {
        if (which == empty)
          outAreas->push(:{x:x, y:y})
        else
          emptyAreas->push(:{x:x, y:y});
      }
    }
  }



  

  @:selectAreas = 
    [
      ...random.scrambled(:emptyAreas)->subset(from:0, to:SEED_COUNT/2-1),
      ...random.scrambled(:outAreas)->subset(from:0, to:SEED_COUNT/2-1)
    ];
  foreach(selectAreas) ::(k, v) {
    out[v.x + (width + BUFFER_SPACE*2) * v.y] = symbolList[random.integer(from:1, to:symbolList->keycount-1)]
  }
  breakpoint();


  @xIncr = 1;
  @yIncr = 1;
  
  for(0, 2)::(i) {
    for(0, height + BUFFER_SPACE*2) ::(y) {
      for(0, width + BUFFER_SPACE*2) ::(x) {
        when(random.flipCoin()) empty;
        //when(random.number() < 0.4) empty;
        @:val = out[x + (width + BUFFER_SPACE*2) * y];
        when(val != symbolList[0] && val != empty) empty;

        @:neighbors = [
          out[x + 1 + (width + BUFFER_SPACE*2) * y],
          out[x - 1 + (width + BUFFER_SPACE*2) * y],
          out[x   + (width + BUFFER_SPACE*2) * (y+1)],
          out[x   + (width + BUFFER_SPACE*2) * (y-1)]
        ]->filter(::(value) <- value != empty && value != symbolList[0]);
        
        when(neighbors->size == 0) empty;        
        out[x + (width + BUFFER_SPACE*2) * y] = random.pickArrayItem(:neighbors);
      }
    }
  }





  // fill gaps
  for(0, 4)::(i) {
    for(0, height + BUFFER_SPACE*2) ::(y) {
      for(0, width + BUFFER_SPACE*2) ::(x) {
        //when(random.number() < 0.4) empty;
        @:val = out[x + (width + BUFFER_SPACE*2) * y];
        when(val == symbolList[0]) empty;
        

        @v;        
        @:v0 = out[x + 1 + (width + BUFFER_SPACE*2) * y];
        @:v1 = out[x - 1 + (width + BUFFER_SPACE*2) * y];
        @:v2 = out[x   + (width + BUFFER_SPACE*2) * (y+1)];
        @:v3 = out[x   + (width + BUFFER_SPACE*2) * (y-1)];
        
        @sides = 
          (if (v0 != empty) 1 else 0)+
          (if (v1 != empty) 1 else 0)+
          (if (v2 != empty) 1 else 0)+
          (if (v3 != empty) 1 else 0)
        ;
        if (sides >= 3)
          out[x + (width + BUFFER_SPACE*2) * y] = random.pickArrayItem(list:[v0, v1, v2, v3]->filter(by::(value) <- value != empty));
        

      }
    }
  }

}

@:basic_island ::(map, width, height, symbols, out, symbolList) {




  for(0, height)::(i) {
    out[
      0 + BUFFER_SPACE+
      (width + BUFFER_SPACE*2) * (i + BUFFER_SPACE)
    ] = symbolList[0];
  }

  for(0, height)::(i) {
    out[
          width + BUFFER_SPACE+
      (width + BUFFER_SPACE*2) * (i + BUFFER_SPACE)
    ] = symbolList[0];
  }

  for(0, width)::(i) {
    out[
          i + BUFFER_SPACE+
      (width + BUFFER_SPACE*2) * (0 + BUFFER_SPACE)
    ] = symbolList[0];
  }

  for(0, width)::(i) {
    out[
          i + BUFFER_SPACE + 
      (width + BUFFER_SPACE*2) * (height + BUFFER_SPACE)
    ] = symbolList[0];
  }


  addLandscapeAreas(map, width, height, symbols, out, symbolList);
  @xIncr = 1;
  @yIncr = 1;
  
  // just for border
  for(0, 4)::(i) {
    @:toAdd = [];
    for(0, height + BUFFER_SPACE*2) ::(y) {
      for(0, width + BUFFER_SPACE*2) ::(x) {
        //when(random.number() < 0.4) empty;
        @:val = out[x + (width + BUFFER_SPACE*2) * y];
        when(val != symbolList[0]) empty;
        
        @:choice = random.integer(from:0, to:5);
        when (choice == 5) empty;
        @newx = if (choice == 1) x+xIncr else if (choice == 2) x-xIncr else x;
        @newy = if (choice == 3) y+yIncr else if (choice == 0) y-yIncr else y;
        toAdd->push(:{x:newx, y:newy, val:val});
      }
    }
    
    foreach(toAdd) ::(k, v) {
      out[v.x + (width + BUFFER_SPACE*2) * v.y] = v.val;    
    }
  }


  // fill gaps
  for(0, 4)::(i) {
    for(0, height + BUFFER_SPACE*2) ::(y) {
      for(0, width + BUFFER_SPACE*2) ::(x) {
        //when(random.number() < 0.4) empty;
        @:val = out[x + (width + BUFFER_SPACE*2) * y];
        when(val == empty || val == symbolList[0]) empty;
        

        @v;        
        @:v0 = out[x + 1 + (width + BUFFER_SPACE*2) * y];
        @:v1 = out[x - 1 + (width + BUFFER_SPACE*2) * y];
        @:v2 = out[x   + (width + BUFFER_SPACE*2) * (y+1)];
        @:v3 = out[x   + (width + BUFFER_SPACE*2) * (y-1)];
        
        @sides = 
          (if (v0 != empty) 1 else 0)+
          (if (v1 != empty) 1 else 0)+
          (if (v2 != empty) 1 else 0)+
          (if (v3 != empty) 1 else 0)
        ;
        if (sides >= 3)
          out[x + (width + BUFFER_SPACE*2) * y] = random.pickArrayItem(list:[v0, v1, v2, v3]->filter(by::(value) <- value != empty));
        

      }
    }
  }
  
}




@:cluster_island ::(map, width, height, symbols, out, symbolList) {

  @:SEED_COUNT = 10;
  @:SEED_RADIUS_MIN = 3;
  @:SEED_RADIUS_MAX = 11;
  @:GROW_LAYERS_MIN = 5;
  @:GROW_LAYERS_MAX = 9;


  @xIncr = 1;
  @yIncr = 1;
  
  for(0, SEED_COUNT)::(i) {
    @:xSeed = BUFFER_SPACE + (random.number() * width)->round;
    @:ySeed = BUFFER_SPACE + (random.number() * height)->round;
    @:radius = random.integer(from:SEED_RADIUS_MIN, to:SEED_RADIUS_MAX);; 
    @:distanceFn = import(:'game_function.distance.mt');
  
    for(0, height + BUFFER_SPACE*2) ::(y) {
      for(0, width + BUFFER_SPACE*2) ::(x) {
      
        if (distanceFn(x0:x, y0:y, x1:xSeed, y1:ySeed) <= radius) ::<= {
            out[x + (width + BUFFER_SPACE*2) * y] = symbolList[0];
        }        
      }
    }
  }



  for(0, random.integer(from:GROW_LAYERS_MIN, to:GROW_LAYERS_MIN))::(i) {
    @:xSeed = (random.number() * width)->round;
    @:ySeed = (random.number() * height)->round;
    @:radius = 20 + random.number()*50; 
    @:distanceFn = import(:'game_function.distance.mt');
    
    @:added = {};
  
    for(0, height + BUFFER_SPACE*2) ::(y) {
      for(0, width + BUFFER_SPACE*2) ::(x) {
        when (random.flipCoin()) empty;
      
        @:p_now = (x  ) + (width + BUFFER_SPACE*2) * (y  );
        @:p0    = (x-1) + (width + BUFFER_SPACE*2) * (y  );
        @:p1    = (x+1) + (width + BUFFER_SPACE*2) * (y  );
        @:p2    = (x  ) + (width + BUFFER_SPACE*2) * (y-1);
        @:p3    = (x  ) + (width + BUFFER_SPACE*2) * (y+1);
      
        when(out[p_now] == symbolList[0]) empty;
      
        if (
          out[p0] == symbolList[0] ||
          out[p1] == symbolList[0] ||
          out[p2] == symbolList[0] ||
          out[p3] == symbolList[0]
        ) ::<= {
          added->push(:p_now);
        }
      }
    }
    
    foreach(added) ::(k, v){
      out[v] = symbolList[0];
    }
  }
  
  addLandscapeAreas(map, width, height, symbols, out, symbolList);
  
}




@:generateTerrain::(map, width, height, symbols) {
  if (symbols->size < 5) 
    error(:'Symbol list for terrain must have at least 5 characters');

  @:symbolList = [
    map.addScenerySymbol(character:' '),
    ...(
      random.scrambled(:symbols)
        ->subset(from:0, to:3)
          ->map(::(value) <- map.addScenerySymbol(character:value))
    )
  ];
  @:out = [];




  //basic_island(map, width, height, symbols, out, symbolList);
  cluster_island(map, width, height, symbols, out, symbolList);
  
  
  
  /*
  for(0, 1)::(i) {
    @:toAdd = [];
    for(0, height + BUFFER_SPACE*2) ::(y) {
      for(0, width + BUFFER_SPACE*2) ::(x) {
        //when(random.number() < 0.4) empty;
        @:val = out[x + (width + BUFFER_SPACE*2) * y];
        when(val != symbolList[0]) empty;
        toAdd->push(:{
          x: x,
          y: y
        });
      }
    }
    
    foreach(toAdd) ::(k, v) {
      @:x = v.x;
      @:y = v.y;
      @:val = symbolList[0];        
      out[x + (width + BUFFER_SPACE*2) * (y+1)] = val;
      out[x + (width + BUFFER_SPACE*2) * (y-1)] = val;

      out[x-1 + (width + BUFFER_SPACE*2) * y] = val;
      out[x-1 + (width + BUFFER_SPACE*2) * (y+1)] = val;
      out[x-1 + (width + BUFFER_SPACE*2) * (y-1)] = val;

      out[x+1 + (width + BUFFER_SPACE*2) * y] = val;
      out[x+1 + (width + BUFFER_SPACE*2) * (y+1)] = val;
      out[x+1 + (width + BUFFER_SPACE*2) * (y-1)] = val;
    }
  } 
  */
  
  return out;
}

@:LargeMap = class(
  name: 'Wyvern.LargeMap',
  define:::(this) {
    @:clearScenery::(map, x, y) {
      @index = map.addScenerySymbol(character:' ');

      for(x-1, x+2) ::(ix) {
        for(y-1, y+2) ::(iy) {
          map.setSceneryIndex(x:ix, y:iy, symbol:index);
          map.clearScenery
        }
      }
    }   
    
    this.interface = {

      create::(parent, sizeW, sizeH, symbols) {        
        @:map = Map.new(parent);
        map.width = sizeW + BUFFER_SPACE*2;
        map.height = sizeH + BUFFER_SPACE*2;

        @index = map.addScenerySymbol(character:'▓');

        for(0, map.height)::(y) {
          for(0, map.width)::(x) {
            map.setSceneryIndex(x, y, symbol:index);
          }
        }
        
        map.offsetX = 0;
        map.offsetY = 0;
        map.paged = false;
        map.drawLegend = true;
        
        @:table = generateTerrain(map, width:map.width - BUFFER_SPACE*2, height:map.height - BUFFER_SPACE*2, symbols);

        for(0, map.height) ::(y) {
          for(0, map.width) ::(x) {
            @:val = table[x + (sizeW + BUFFER_SPACE*2) * y];
            when(val == empty) empty;
            map.setSceneryIndex(
              x:x,
              y:y,
              symbol:val
            );
          }
        }
        
        @:land = map.addScenerySymbol(character:' ');
        @:border = map.addScenerySymbol(character:'_')
        @:spire = map.addScenerySymbol(character:'░');
        @:spireEnd = map.addScenerySymbol(character:'▒');

        // finally, border out bottoms and extend 
        for(0, map.height) ::(y) {
          for(0, map.width) ::(x) {
            @:val = map.sceneryAt(x, y);
            @:below = map.sceneryAt(x, y:y+1);
            @:belowbelow = map.sceneryAt(x, y:y+2);


            if (val != '▓' && val != '░' && val != '▒' && below == '▓') ::<= {
              @iter = y;
              if (belowbelow == '▓') ::<= {
                map.setSceneryIndex(x, y:iter, symbol:border);
              } else ::<= {
                map.setSceneryIndex(x, y:iter, symbol:land);
              }
              iter += 1;
              
              @scale = 1 - 2*((((x - BUFFER_SPACE) / (map.width - 2*BUFFER_SPACE)) - 0.5)->abs)

              //scale *= scale;
              
              @lenSecondary = 1 + random.integer(from:5, to:9) * scale * 0.5;
              @len = random.integer(from:2, to: 2);
              
              
              
              {:::} {
                for(0, len) ::(i) {
                  @:next = map.sceneryAt(x, y:iter);
                  if (next == '▓')
                    map.setSceneryIndex(x, y:iter, symbol:spire)
                  else
                    send();
                  iter += 1;
                }
                for(0, lenSecondary) ::(i) {
                  @:next = map.sceneryAt(x, y:iter);
                  if (next == '▓')
                    map.setSceneryIndex(x, y:iter, symbol:spireEnd)
                  else
                    send();
                  iter += 1;
                }
                
              }
            }
          }
        }        
        // some places might have "holes" that need work.
        for(0, 2) ::(i) {
          for(0, map.height) ::(y) {
            for(0, map.width) ::(x) {
              @:val = map.sceneryAt(x, y);
                   
              when(val == '▓' || val == ' ') empty;
              if (
                (
                  (if (map.sceneryAt(x:x-1, y) == ' ') 1 else 0) +
                  (if (map.sceneryAt(x:x+1, y) == ' ') 1 else 0) +
                  (if (map.sceneryAt(x, y:y-1) == ' ') 1 else 0) +
                  (if (map.sceneryAt(x, y:y+1) == ' ') 1 else 0)
                ) >= 3
              )
                map.setSceneryIndex(x, y, symbol:land);
            
              
            }
          }
        }

        for(0, map.height) ::(y) {
          for(0, map.width) ::(x) {
            @:scen = map.sceneryAt(x, y);
            if (scen == '▓' ||
                scen == '▒' ||
                scen == '░') 
                empty;
              //map.enableWall(x, y);
          }
        }

        
        return map;
            
      },


      addLandmark::(map, island, base) { 
        @:x = random.integer(from:BUFFER_SPACE + (0.2*(map.width  - BUFFER_SPACE*2))->floor, to:(map.width  - BUFFER_SPACE)-(0.2*(map.width  - BUFFER_SPACE*2))->floor);
        @:y = random.integer(from:BUFFER_SPACE + (0.2*(map.height - BUFFER_SPACE*2))->floor, to:(map.height - BUFFER_SPACE)-(0.2*(map.height - BUFFER_SPACE*2))->floor);
        @:landmark = Landmark.new(
          island,
          base,
          x,
          y
        );
        clearScenery(map, x, y);
        island.addLandmark(:landmark);
        return landmark;
      },
      
      getAPosition ::(map) {
        return {
          x:random.integer(from:BUFFER_SPACE + (0.2*(map.width  - BUFFER_SPACE*2))->floor, to:(map.width  - BUFFER_SPACE)-(0.2*(map.width  - BUFFER_SPACE*2))->floor),
          y:random.integer(from:BUFFER_SPACE + (0.2*(map.height - BUFFER_SPACE*2))->floor, to:(map.height - BUFFER_SPACE)-(0.2*(map.height - BUFFER_SPACE*2))->floor)
        }
      }
      
      
    }
  }
);
return LargeMap.new();
