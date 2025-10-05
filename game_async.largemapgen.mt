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
@:AsyncWorker = empty;
/*
::? {
  return import(:'Matte.System.AsyncWorker');
} => {
  onError::(message) {
    // synchronous
  }
}
*/

@:JSON = import(:'Matte.Core.JSON');




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





/*

// Standard pretty

@:SEED_GROW_ITER = 7;
@:SEED_FILL_ITER = 4;
@:SEED_RADIUS_MIN = 3;
@:SEED_RADIUS_MAX = 16;
@:GROW_LAYERS_MIN = 5;
@:GROW_LAYERS_MAX = 9;
@:SEED_COUNT ::(width, height) <- 4+(width+height)/25
*/

// mini
@:SEED_GROW_ITER = 7;
@:SEED_FILL_ITER = 4;
@:SEED_RADIUS_MIN = 5;
@:SEED_RADIUS_MAX = 9;
@:GROW_LAYERS_MIN = 5;
@:GROW_LAYERS_MAX = 9;
@:SEED_COUNT ::(width, height) <- (4+(width+height)/18.0)->round







@:generateTerrain_phase1::(out, map, width, height, symbols, symbolList, areas) {
  
  for(0, SEED_COUNT(width, height))::(i) {
    @:xSeed = BUFFER_SPACE + (random.number() * width)->round;
    @:ySeed = BUFFER_SPACE + (random.number() * height)->round;
    @:radius = random.integer(from:SEED_RADIUS_MIN, to:SEED_RADIUS_MAX);; 
    @:distanceFn = import(:'game_function.distance.mt');
    
    @:info = {
      x : xSeed,
      y : ySeed,
      boxes : []
    }
  
    for(0, height + BUFFER_SPACE*2) ::(y) {
      for(0, width + BUFFER_SPACE*2) ::(x) {
      
        if (distanceFn(x0:x, y0:y, x1:xSeed, y1:ySeed) <= radius) ::<= {
            out[x + (width + BUFFER_SPACE*2) * y] = symbolList[0];
            info.boxes->push(:{
              x: x,
              y: y
            });
        }        
      }
    }
    
    areas->push(:info);
  }
}

@:generateTerrain_phase2::(out, map, width, height, symbols, symbolList) {


  @xIncr = 1;
  @yIncr = 1;

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
}


@:generateTerrain_landscape_phase1::(out, map, width, height, symbols, symbolList) {
  @:SEED_LANDSCAPE_COUNT = ((width*height)**0.5) / 2.5
  

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
      ...random.scrambled(:emptyAreas)->subset(from:0, to:SEED_LANDSCAPE_COUNT/2-1),
      ...random.scrambled(:outAreas)->subset(from:0, to:SEED_LANDSCAPE_COUNT/2-1)
    ];
  
  foreach(selectAreas) ::(k, v) {
    out[v.x + (width + BUFFER_SPACE*2) * v.y] = symbolList[random.integer(from:1, to:symbolList->keycount-1)]
  }


  @xIncr = 1;
  @yIncr = 1;
  
  for(0, SEED_GROW_ITER)::(i) {
    @:toAdd = [];
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
        toAdd->push(:{
          loc:x + (width + BUFFER_SPACE*2) * y, 
          val:random.pickArrayItem(:neighbors)
        });
      }
    }
    
    foreach(toAdd) ::(k, v) {
      out[v.loc] = v.val;
    }
  }
}

@:generateTerrain_landscape_phase2::(out, map, width, height, symbols, symbolList) {
  // fill gaps
  
  for(0, SEED_FILL_ITER)::(i) {
    @:toAdd = [];
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
          (if (v0 != empty && v0 != symbolList[0]) 1 else 0)+
          (if (v1 != empty && v1 != symbolList[0]) 1 else 0)+
          (if (v2 != empty && v2 != symbolList[0]) 1 else 0)+
          (if (v3 != empty && v3 != symbolList[0]) 1 else 0)
        ;
        if (sides >= 3)
          toAdd->push(:{
            loc : x + (width + BUFFER_SPACE*2) * y,
            val : random.pickArrayItem(list:[v0, v1, v2, v3]->filter(by::(value) <- value != empty)) 
          });        

      }
    }
    
    foreach(toAdd) ::(k, v) {
      out[v.loc] = v.val;
    }
  }
}

@:generateTerrain_finalize1::(out, map, width, height, symbols, symbolList, land, spire, spireEnd, border) {
        
  @:table = out;

  for(0, map.height) ::(y) {
    for(0, map.width) ::(x) {
      @:val = table[x + (width + BUFFER_SPACE*2) * y];
      when(val == empty) empty;
      map.setSceneryIndex(
        x:x,
        y:y,
        symbol:val
      );
    }
  }
  

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
        
        @lenSecondary = random.integer(from:1, to:2);//random.integer(from:5, to:9) * scale * 0.5;
        @len = random.integer(from:2, to: 4);
        
        
        
        ::? {
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
}

@:generateTerrain_connect::(out, map, width, height, symbols, symbolList, land, areas) {

  
  
  // now that we have the list..... form groups
  foreach(areas) ::(k, v) {
    v.group = [v];
  }

  @:groups = areas->map(::(value) <- value.group);

  
  @:mergeGroups::(a, b) {
    groups->remove(:groups->findIndex(:a.group));
    groups->remove(:groups->findIndex(:b.group));
  
    @group = {};
    foreach([...a.group, ...b.group]) ::(k, v) {
      group[v] = true;
    }
    group = group->keys; // removes dupes!
    
    foreach(group) ::(k, v) {
      v.group = group;
    }
    groups->push(:group);
  }


  // prevent repeat getPath grinding
  @:connects = {};

  ::? {
    forever :: {
      @needRemerge = false;
      ::? {
        foreach(groups) ::(k, group) {
          // already has a group
          @:rep = group[0];

          foreach(groups) ::(k, v) {
            @other = v[0];
            if (other == rep) empty;
            
            
            if ((connects[rep] != empty && connects[rep][other] == true) || map.getPath(
              useBFS: true,
              fromX : rep.x,
              fromY : rep.y,
              toX : other.x,
              toY : other.y,
              corners : false
            ) != empty) ::<={
              if (connects[rep] == empty)
                connects[rep] = {};
              connects[rep][other] = true;

              if (connects[other] == empty)
                connects[other] = {};
              connects[other][rep] = true;

            
              mergeGroups(a:rep, b:other);
              needRemerge = true;
              send();
            }
          }      
        }
      }
      if (needRemerge == false)
        send();
    }
  }
  


  // no additional work needed
  when(groups->size == 1) empty;


  
  foreach(areas) ::(k, area) {
    area.others = areas->filter(::(value) <- value != area && value.group != area.group)
      ->map(::(value) <- {
        area : value,
        distance : distance(x0:area.x, y0:area.y, x1:value.x, y1:value.y)
      });
      
    area.others->sort(::(a, b) {
      when(a.distance < b.distance) -1
      when(a.distance > b.distance) 0
      return 1;
    });
  }




  // before going on, lets revisit the "others" member 
  // of each area. Remove
  
  @:createBridge = ::(from, to) {
    @xfrom = from.x;
    @xto   = to.x;

    @yfrom = from.y;
    @yto   = to.y;

    @:freeSpace::(x, y, ch) {
      if (map.isWalled(x, y)) ::<= {
        map.setSceneryIndex(x, y, symbol:ch);
        map.disableWall(x, y);
      }
    }
    
    @:ew = map.addScenerySymbol(:'─');
    @:ns = map.addScenerySymbol(:'│');


    for(xfrom, xto) ::(x) {
      freeSpace(x, y:yfrom, ch:ew)
    }

    for(yfrom, yto) ::(y) {
      freeSpace(x:xto, y, ch:ns)
    }
  }
  
  ::? {
    forever::{
      // no connecting needed! done :)
      when(groups->size == 1) send();
      
      @closestFrom = groups[0][0];
      @closestDist = closestFrom.others[0].distance;
      @closestTo   = groups[1][0];
      
      foreach(groups[0]) ::(k, from) {
        foreach(from.others) ::(k, v) {
          // can still happen intramerge
          when (v.area.group == from.group) empty;
          
          if (v.distance < closestDist) ::<= {
            closestDist = v.distance;
            closestTo = v.area;
            closestFrom = from;
          }
        } 
      }
      
      // create a bridge
      createBridge(from:closestFrom, to:closestTo);
      mergeGroups(a:closestFrom, b:closestTo);
      
      
      
    }
  }

  
}


@:generateTerrain_cleanup::(out, map, width, height, symbols, symbolList, land) {


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
        map.enableWall(x, y);
    }
  }
}





@:clearScenery::(map, x, y) {
  @index = map.addScenerySymbol(character:' ');

  for(x-1, x+2) ::(ix) {
    for(y-1, y+2) ::(iy) {
      map.setSceneryIndex(x:ix, y:iy, symbol:index);
      map.clearScenery
    }
  }
}   
  
@:create::(sizeW, sizeH, symbols) {        
  @:map = Map.new();
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
  map.title = 'Island';

  @:land = map.addScenerySymbol(character:' ');
  @:border = map.addScenerySymbol(character:'_')
  @:spire = map.addScenerySymbol(character:'░');
  @:spireEnd = map.addScenerySymbol(character:'▒');



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
  @:areas = [];
  @:args = {
    map : map,
    width:map.width - BUFFER_SPACE*2,
    height:map.height - BUFFER_SPACE*2,
    symbols: symbols,
    symbolList : symbolList,
    out : out,
    land: land,
    border: border,
    spire : spire,
    spireEnd : spireEnd,
    areas : areas
  }   
  
  @:phases = [
    ['Generating terrain (1/2)...', generateTerrain_phase1],
    ['Generating terrain (2/2)...', generateTerrain_phase2],
    ['Generating landscape (1/2)...', generateTerrain_landscape_phase1],
    ['Generating landscape (2/2)...', generateTerrain_landscape_phase2],
    ['Finalizing terrain (1/2)...', generateTerrain_finalize1],
    ['Finalizing terrain (2/2)...', generateTerrain_cleanup],
    ['Connecting islands...', generateTerrain_connect],
  ]        
  @:loading = import(:'game_function.loading.mt');
  foreach(phases) ::(k, phase) {
    if (AsyncWorker)
      AsyncWorker.sendToParent(:phase[0]);
    phase[1](*args);
  }

  foreach(areas) ::(k, v) {
    map.addArea(:
      Map.Area.new(
        x : v.x,
        y : v.y,
        
        // TODO:
        width: 1,
        height: 1
      )
    )
  }

  return map;
}
return ::<= {
  @:input = JSON.decode(:parameters.input);
  
  random.load(:input.random);
  
  @:result = {};
  result.map = 
    create(
      sizeW : input.sizeW,
      sizeH : input.sizeH,
      symbols : input.symbols  
    ).save()
  
  result.random = random.save();

  return JSON.encode(:result);  
}


