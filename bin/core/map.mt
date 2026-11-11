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
@:canvas = import(module:'core/graphics/canvas.mt');
@:class = import(module:'Matte.Core.Class');
@:random = import(module:'core/random.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:State = import(module:'core/data/state.mt');
@:EventSystem = import(module:'Matte.Core.EventSystem');
@:JSON = import(module:'Matte.Core.JSON');

@Map;

@:StateType = State.create(
  items : {
    itemIndexCompressed : empty,
    entities : empty,
    compressedItems : empty,
    dataList : empty,
    title : '',
    legendEntriesCompressed : empty, // retired.

    pointer : empty,
    offsetX : 0,
    offsetY : 0,
    drawLegend : false,
    paged : false,
    undefinedCharacter : '',
    wallCharacter : '',
    //@scenery = MemoryBuffer.new();
    sceneryCompressed : empty,
    sceneryValues : empty,
    stepAction : empty,
    areas : empty,
    isDark : false
  }
)


@BFS_NATIVE;
::? { 
  BFS_NATIVE = getExternalFunction(name:"wyvern_gate__native__bfs");
} => {
  onError::(message) {}
}
//@:MemoryBuffer = import(module:'Matte.Core.MemoryBuffer');



/*
  Generalized map interface for a rendered
  maps. Maps contain a set of items that 
  can be traveled to on a fixed grid.
  
  Each item is a reachable from a pointer and has a unique
  position on the map. Walls can also be specified as obstables 
  where no item or pointer can be placed.
  
  

*/

@:THE_BIG_ONE = 100000000;
@:SIGHT_RAY_LIMIT = 8;
@:SIGHT_RAY_EPSILON = 0.4;


@:SETTINGS_MASK    = 0x110000;
@:IS_WALLED_MASK   = 0x010000;
@:IS_OBSCURED_MASK = 0x100000;

@:TOO_FAR_CHARACTER = '░';
@:TOO_FAR_SYMBOL_CHARACTER = 'o';
@:DEFAULT_OUT_OF_BOUNDS = '`'

@:distance = import(module:'core/distance.mt');

@:posToId ::(x, y) {
  return ''+x+','+y;
}



@:CHUNK_SIZE = 20

@:ChunkState = LoadableClass.create(
  name: 'Wyvern.Map.ChunkState',
  items : {
    data : empty,
    scenery : empty,
    x : 0,
    y : 0
  },
  
  define ::(state, this) {
    this.interface = {
      defaultLoad ::(x, y, obscure) {
        state.x = x;
        state.y = y;
        state.data = {};
        @:scenery = [];
        if (obscure) {
          for(0, CHUNK_SIZE*CHUNK_SIZE) ::(i) {
            scenery[i] = IS_OBSCURED_MASK;
          }
        } else {
          for(0, CHUNK_SIZE*CHUNK_SIZE) ::(i) {
            scenery[i] = 0;
          }      
        }
        
        state.scenery = scenery;
      },
      

      
      x : {get ::<- state.x},
      y : {get ::<- state.y},
      data : {get ::<- state.data},
      scenery : {get ::<- state.scenery},
    }
  }
);

@:ChunkManager = LoadableClass.create(
  name : 'Wyvern.Map.ChunkManager',
  statics : {
    CHUNK_SIZE : {get::<-CHUNK_SIZE}
  },
  items : {
    // Cells. Indexed by 'x,y' strings
    // When out of range, the chunk entry becomes a 
    // saved string
    chunks : empty,
    chunksAwake : empty,
    obscure : false

  },
  
  define ::(this, state) {
    @island;
    @:events = EventSystem.new();
    @CHUNK_ACTIVE_COUNT = 32;


    events.events = {
      onWakeChunk ::(detail){},
      onSleepChunk ::(detail){},
      onCreateChunk ::(detail){},
    }
    
    @:posToChunk::(x) <- (x / CHUNK_SIZE)->floor
    

    

    
    @:putChunkToSleep::(id) {
      state.chunksAwake->remove(:id);
      events.emit(
        event: 'onSleepChunk',
        detail : {
          data : state.chunks[id].data,
          scenery : state.chunks[id].scenery,
          x : state.chunks[id].x,
          y : state.chunks[id].y
        }
      );
      state.chunks[id] = JSON.encode(object:state.chunks[id].save());

    }
    
    @:wakeUpChunk ::(x, y) {

      @:BiomeCell = import(module:'base/map/biomecell.mt');
      @:id = posToId(x, y);
      @:str = state.chunks[id]
      //state.chunks[id] = BiomeCell.new(parent:this);
      @:chunk = ChunkState.new(x:0, y:0);
      state.chunks[id] = chunk;
      chunk.load(:JSON.decode(:str));
      state.chunksAwake[id] = true;
      events.emit(
        event: 'onWakeChunk',
        detail : {
          data : chunk.data,
          scenery : chunk.scenery,
          x : chunk.x,
          y : chunk.y
        }
      );
      return chunk;
    }
    
    @:createChunk ::(x, y) {
      // TODO: this sucks
      ::? { 
        forever ::{
          when (state.chunksAwake->keycount < CHUNK_ACTIVE_COUNT) send();
          putChunkToSleep(:random.pickArrayItem(:state.chunksAwake->keys));
        }
      }

      @:BiomeCell = import(:'base/map/biomecell.mt');
      //@:cell = BiomeCell.new(base:island.getBiomeCellType(x, y), parent:this);
      //cell.activate(x, y);
      @:id = posToId(x, y);
      @:chunk = ChunkState.new(x, y, obscure:state.obscure);
      
      state.chunks[id] = chunk;
      state.chunksAwake[id] = true;

      
      events.emit(
        event: 'onCreateChunk',
        detail : {
          data : chunk.data,
          scenery : chunk.scenery,
          x : x,
          y : y
        }
      );
      return chunk;
    }
    
    // returns true if already loaded
    @:loadChunk ::(x, y) {
      @val = state.chunks[posToId(x, y)];
      // new chunk
      when (val == empty) ::<= {
        return createChunk(x, y);
      }
        
      // Dormant, reload
      when (val->type == String) ::<= {
        return wakeUpChunk(x, y);
      }
      
      return val;
    }
    
    
    this.interface = {
      initialize ::(parent) {
        island = parent
      },
      
      defaultLoad::() {
        state.chunks = {};
        state.chunksAwake = {};
      },
      
      getChunkSceneryForPosition::(x, y) {
        @:xi = (x->floor % CHUNK_SIZE)->abs
        @:yi = (y->floor % CHUNK_SIZE)->abs
        return loadChunk(x:posToChunk(:x), y:posToChunk(:y)).scenery[xi + yi*CHUNK_SIZE] => Number;
      },
      
      setChunkSceneryForPosition::(x, y, value) {
        @:xi = (x->floor % CHUNK_SIZE)->abs
        @:yi = (y->floor % CHUNK_SIZE)->abs
        loadChunk(x:posToChunk(:x), y:posToChunk(:y)).scenery[xi + yi*CHUNK_SIZE] = value;
      },
      
      andChunkSceneryForPosition::(x, y, value) {
        @:xi = (x->floor % CHUNK_SIZE)->abs
        @:yi = (y->floor % CHUNK_SIZE)->abs
        loadChunk(x:posToChunk(:x), y:posToChunk(:y)).scenery[xi + yi*CHUNK_SIZE] &= value;
      },

      orChunkSceneryForPosition::(x, y, value) {
        @:xi = (x->floor % CHUNK_SIZE)->abs
        @:yi = (y->floor % CHUNK_SIZE)->abs
        loadChunk(x:posToChunk(:x), y:posToChunk(:y)).scenery[xi + yi*CHUNK_SIZE] |= value;
      },
      
      events : {
        get ::<- events
      },
      
      obscure : {
        set ::(value) <- state.obscure = value,
        get ::<- state.obscure
      },

      
      loadScreenFor::(x, y) {
        @:lenX = (canvas.width / CHUNK_SIZE)->ceil+1;
        @:lenY = (canvas.height / CHUNK_SIZE)->ceil;
        
        @:middleX = posToChunk(:x);
        @:middleY = posToChunk(:y);

        if (CHUNK_ACTIVE_COUNT < (lenX + 2) * (lenY + 2))
          CHUNK_ACTIVE_COUNT = (lenX + 2) * (lenY + 2);

        @active = {};
        for(middleY-(lenX/2)->floor-1, middleY+(lenX/2)->floor+2) ::(y) {
          for(middleX-(lenY/2)->floor-1, middleX+(lenY/2)->floor+2) ::(x) {
            @:id = posToId(x, y)
            active[id] = loadChunk(x, y).scenery;
            
          }
        }
        
        return active;
      }
    }
  }
);











@area_debug_index = 0;
@Area = LoadableClass.create(
  name: 'Wyvern.Map.Area',
  items : {},
  define::(this, state) {
    @_x = 0;
    @_y = 0;
    @_w = 0;
    @_h = 0;
    @data = empty;
    @isOccupied = false;

    

    this.interface = {
      defaultLoad::(x, y, width, height) {
        _x = x => Number;
        _y = y => Number;
        _w = width => Number;
        _h = height => Number;
        isOccupied = false;
      },

      x : {get::<-_x},    
      y : {get::<-_y},    
      width : {get::<-_w},    
      height : {get::<-_h},
      occupy ::{
        isOccupied = true
      },
      
      data : {
        get ::<- data,
        set::(value) <- data = value
      },
      
      isOccupied : {
        get ::<- isOccupied
      },
      
      save ::{
        return {
          x: _x,
          y: _y,
          w: _w,
          h: _h,
          data : data,
          isOccupied: isOccupied
        }
      },
      
      debug ::(map) {
        @:ind = map.addScenerySymbol(:''+area_debug_index);
        area_debug_index = (area_debug_index + 1)%10
        for(_y, _y+_h) ::(y) {
          for(_x, _x+_w) ::(x) {
            map.setSceneryIndex(x, y, symbol:ind);
          }        
        }
      },
      
      
      load ::(serialized) {
        _x = serialized.x;
        _y = serialized.y;
        _w = serialized.w;
        _h = serialized.h;
        data = serialized.data;
        isOccupied = serialized.isOccupied;
      }
    }
  }
);


Map =  LoadableClass.create(
  name: 'Wyvern.Map',

  statics : {
    Area : {
      get::<-Area
    },
    TRAIT : {get ::<- {
      // whether the map item should have a "halo"
      // halo items indicate
      HAS_HALO : 1,
      
      // Whether the symbol should be hidden
      DISCOVERED : 2
    }}
  },
  items : {},
  
  define:::(this, state) {
  
    @events = EventSystem.new();
    events.events = {
      onSetItem:::{},
      onRemoveItem:::{},
      onMoveItem :::{},
      onPointerMove:::{}
    }
    @itemIndex = [];
    @entities = [];
    @items = [];
    @title;

    @pointer = {
      x: 0,
      y: 0,
      discovered : true,
      symbol: 'Ø',
      name: "(Party)"
    }

    @offsetX = 0;
    @offsetY = 0;
    @drawLegend = false;
    @paged = false;
    @undefinedCharacter = '`';
    @wallCharacter = '';//'▓';
    //@scenery = MemoryBuffer.new();
    @areas = [];
    @chunkManager = ChunkManager.new();
    @isDark = false;
    @parent_;
    @aStarPQCompareTable;
    @sceneryValues = [];


    @:drawTarget = ::<= {
    
      @:targetTable = [
        '┌',
        '─',
        '┐',
        
        '│',
        '│',

        '└',
        '─',
        '┘'
      ]
      
      @:targetOffsets = [
        [-1, -1],
        [ 0, -1],
        [ 1, -1],
        
        [ 1,  0],
        [-1,  0],

        [-1,  1],
        [ 0,  1],
        [ 1,  1]
      ]
    
      return ::(x, y, itemX, itemY) {      
        foreach(targetTable) ::(k, char) {
          @:dx = targetOffsets[k][0];
          @:dy = targetOffsets[k][1];

          //if (scenery[at] == 0 || this.sceneryAt(x:itemX+dx, y:itemY+dy) == ' ') ::<= {
            canvas.movePen(x:x+dx, y:y+dy);  
            canvas.drawChar(:char);
          //}        
        }
      }
    }

    
    @:isWalled ::(x, y) {
      return (chunkManager.getChunkSceneryForPosition(x, y) & IS_WALLED_MASK) != 0;
    }
    @aStarNodeIDlookup = {};
    @:aStarNewNode::(x, y) {
      when (isWalled(x, y)) empty
      @:id = ''+x+','+y;
      aStarNodeIDlookup[id] = [x, y]
      return id;
    }

    @:aStarHeuristicH::(from, to) {
      @:fromn = aStarNodeIDlookup[from];
      @:ton = aStarNodeIDlookup[to];
    
      return distance(x0:fromn[0], y0:fromn[1], x1:ton[0], y1:ton[1])
    }

    @:aStarMapEmplace::(map, key, value) {
      map.index[key] = value;
    }
    @:aStarMapFind::(map, key) {
      return map.index[key];
    }
    @:aStarMapRemove::(map, key) {
      map.index[key] = empty;
    }
    @:aStarMapNew :: {
      return {
        //list: [],
        index: {}
      }
    }
    
    @:aStarPQNew :: {
      return [];
    }


    @:aStarReconstructPath::(cameFrom, current, start) {
      @:path = [];
      return ::? {
        forever ::{
          @:n = aStarNodeIDlookup[current];
          path->push(value:{
            x: n[0],
            y: n[1]
          });
          @:contains = aStarMapFind(map:cameFrom, key:current);
          when(contains == start) send(message:path);
          current = contains;
        }
      }
    }


    @:aStarFindLowestFscore::(fScore, openSet) {
      return aStarPQGetFirst(pq:openSet);
    }


    @:aStarGetNeighborsCorners::(neighbors, current) {
      neighbors->setSize(size:0);
      @:n = aStarNodeIDlookup[current];
      @:x = n[0];
      @:y = n[1]
      
      @i;
      i = aStarNewNode(x:x+1, y:y+1); if (i != empty) neighbors->push(value:i);
      i = aStarNewNode(x:x+1, y:y-1); if (i != empty) neighbors->push(value:i);
      i = aStarNewNode(x:x-1, y:y+1); if (i != empty) neighbors->push(value:i);
      i = aStarNewNode(x:x-1, y:y-1); if (i != empty) neighbors->push(value:i);

      i = aStarNewNode(x:x-1, y:y  ); if (i != empty) neighbors->push(value:i);
      i = aStarNewNode(x:x+1, y:y  ); if (i != empty) neighbors->push(value:i);
      i = aStarNewNode(x:x  , y:y+1); if (i != empty) neighbors->push(value:i);
      i = aStarNewNode(x:x  , y:y-1); if (i != empty) neighbors->push(value:i);
      return neighbors;
    }

    @:aStarGetNeighborsNoCorners::(neighbors, current) {
      neighbors->setSize(size:0);
      @:n = aStarNodeIDlookup[current];
      @:x = n[0];
      @:y = n[1]
      
      @i;
      i = aStarNewNode(x:x-1, y:y  ); if (i != empty) neighbors->push(value:i);
      i = aStarNewNode(x:x+1, y:y  ); if (i != empty) neighbors->push(value:i);
      i = aStarNewNode(x:x  , y:y+1); if (i != empty) neighbors->push(value:i);
      i = aStarNewNode(x:x  , y:y-1); if (i != empty) neighbors->push(value:i);
      return neighbors;
    }

    
    @:aStarGetScore::(value) <- if (value == empty) THE_BIG_ONE else value;
    



    @:aStarPQCompare::(a, b) {
      @:as = aStarMapFind(map:aStarPQCompareTable, key:a);
      @:bs = aStarMapFind(map:aStarPQCompareTable, key:b);
      when(as < bs) -1;
      when(as > bs)  1;
      return 0;
    }
    
    // returns the placement of the value within the 
    // priority queue. The  
    @:aStarPQBinarySearch::(pq, value, fScore) {
      aStarPQCompareTable = fScore;
      @m = 0;
      @n = pq->keycount - 1;
      return ::? {
        forever ::{
          when(m > n) send(message:pq->keycount+m);
          @k = ((n + m) / 2)->floor;
          @cmp = aStarPQCompare(a:value, b:pq[k]);
          when(cmp > 0) m = k + 1;
          when(cmp < 0) n = k - 1;
          send(message:k);
        }
      }
    }
    
    @:aStarPQGetFirst::(pq) <- pq[0];
    
    @:aStarPQAdd::(pq, value, fScore) {
      @:in = aStarPQBinarySearch(pq, value, fScore);
      if (in < pq->keycount) empty; // already in 
      pq->insert(at:in-pq->keycount, value);
    }

    @:aStarPQRemove::(pq, value, fScore) {
      @:in = aStarPQBinarySearch(pq, value, fScore);
      if (in >= pq->keycount) empty; // not in 
      pq->remove(key:in);      
    }
    

    
    
    // A* finds a path from start to goal.
    // h is the heuristic function. h(n) estimates the cost to reach goal from node n.
    @:aStarPath::(start, goal, corners) { 
      breakpoint();
      @:getNeighbors = if (corners)
        aStarGetNeighborsCorners
      else 
        aStarGetNeighborsNoCorners
        
           
      start = aStarNewNode(x:start.x, y:start.y);
      goal = aStarNewNode(x:goal.x, y:goal.y);
      @:neighbors = [];
      
      when(start == goal) empty;
      // The set of discovered nodes that may need to be (re-)expanded.
      // Initially, only the start node is known.
      // This is usually implemented as a min-heap or priority queue rather than a hash-set.
      @openSet = aStarPQNew();
      aStarPQAdd(pq:openSet, value:start);

      // For node n, cameFrom[n] is the node immediately preceding it on the cheapest path from the start
      // to n currently known.
      @cameFrom = aStarMapNew();

      // For node n, gScore[n] is the cost of the cheapest path from start to n currently known.
      @gScore = aStarMapNew();
      aStarMapEmplace(map:gScore, key:start, value:0);

      // For node n, fScore[n] := gScore[n] + h(n). fScore[n] represents our current best guess as to
      // how cheap a path could be from start to finish if it goes through n.
      @fScore = aStarMapNew();
      aStarMapEmplace(map:fScore, key:start, value:aStarHeuristicH(from:start, to:goal));

      @path;
      @iter = 0;
      
      return ::? {
        forever ::{
          // return empty: open set is empty but goal was never reached
          when(openSet->keycount == 0) send();
        
          // This operation can occur in O(Log(N)) time if openSet is a min-heap or a priority queue
          @current = openSet[0];
          //@current = aStarFindLowestFscore(fScore, openSet);
          if (current == goal) ::<= {
            @out = aStarReconstructPath(cameFrom, current, start);
            send(message:out);
            
          }
          openSet->remove(key:0);
          foreach(getNeighbors(neighbors, current))::(i, neighbor) {
            // d(current,neighbor) is the weight of the edge from current to neighbor
            // tentative_gScore is the distance from start to the neighbor through current
            @:tentative_gScore = aStarMapFind(map:gScore, key:current) + 1;//d(current, neighbor)
            if (tentative_gScore < aStarGetScore(value:aStarMapFind(map:gScore, key:neighbor))) ::<= {
              // This path to neighbor is better than any previous one. Record it!
              aStarMapEmplace(map:cameFrom, key:neighbor, value:current);
              aStarMapEmplace(map:gScore, key:neighbor, value:tentative_gScore);
              aStarMapEmplace(map:fScore, key:neighbor, value:tentative_gScore + aStarHeuristicH(from:neighbor, to:goal));
              aStarPQAdd(pq:openSet, value:neighbor, fScore);
            }
          }
        }
      }
    }
    
    @:bfsQ = [];
    @:bfsPath::(start, goal, corners) {
      aStarNodeIDlookup = {}      
      @:startID = aStarNewNode(x:start.x, y:start.y);
      @:goalID = aStarNewNode(x:goal.x, y:goal.y);  
      @:neighbors = [];   
      when (start == empty || goal == empty) empty;
      
      @:getNeighbors = if (corners)
        aStarGetNeighborsCorners
      else 
        aStarGetNeighborsNoCorners
    
      when (BFS_NATIVE!=empty) ::<= {
        @:result = BFS_NATIVE(
          scenery: chunkManager.getChunkSceneryForPosition,
          startX: start.x,
          startY: start.y,
          goalX : goal.x,
          goalY : goal.y,
          corners
        );
        when(result == empty) empty;
        @:out = [];
        for(0, result->size/2) ::(i) {
          out->push(value:{
            x: result[i*2],
            y: result[i*2+1]
          });
        }
        return out;
      }
      
      // fallback on slow version

      
      when(startID == goalID) empty;
      @:q = bfsQ;
      q->setSize(size:0);
      @qIter = 0;
      @:visited = {}
      visited[startID] = startID;
      q->push(value:startID);
      
      @:searched = {};
      return ::? {
        forever ::{
          when(qIter >= q->size) send();
          
          @v = q[qIter];
          qIter +=1;

          when(v == goalID) ::<= {
            // build path
            send(message: ::<={
              @:path = [];
              ::? {
                @a = v;
                @last;
                forever ::{
                  @:n = aStarNodeIDlookup[a];
                  @:next = {
                    x: n[0],
                    y: n[1]
                  };
                  path->push(value:next);      
                  when(visited[a] == startID) ::<= {
                    send();        
                  }  

                  a = visited[a]; 
                }
              }
              q->setSize(size:0);
              return path;
            })
          }

          foreach(getNeighbors(neighbors, current:v))::(i, w) {
            when(visited[w] != empty) empty;
            
            visited[w] = v; // parent
            q->push(value:w);
          }
          
          searched->push(:{
            from: v,
            neighbors : getNeighbors(neighbors, current:v)
          });

        }
      }
    }
    
    
    
    @:renderUnpaged ::{
      @mapSizeW  = canvas.width;
      @mapSizeH  = canvas.height;

      //@:Time = import(module:'Matte.System.Time');
      //@:ticks = Time.getTicks();
      @:left = canvas.width/2 - mapSizeW/2;
      @:top = canvas.height/2 - mapSizeH/2;


      @:centerX = (mapSizeW / 2)->floor;
      @:centerY = (mapSizeH / 2)->floor;
      
      
      @isLit = [];
      @:sightRay ::(degrees) {
        @x = pointer.x + 0.5;
        @y = pointer.y + 0.5;
        @:rads = (Number.PI() / 180)*degrees;
        ::? {
          forever ::{
            x += rads->cos * SIGHT_RAY_EPSILON;
            y += rads->sin * SIGHT_RAY_EPSILON;
            @:id = ''+x->floor+','+y->floor

            when(distance(x0:pointer.x, y0:pointer.y, x1:x, y1:y) > SIGHT_RAY_LIMIT) send();

            if (isLit[id] == empty) ::<= {
              chunkManager.andChunkSceneryForPosition(
                x : x->floor,
                y : y->floor,
                value : ~IS_OBSCURED_MASK
              );
              isLit[id] = isWalled(x:x->floor, y:y->floor)
            }

            if (isLit[id] == true)
              send();
          }
        }
      }
      
      
      ::? {
        @i = 0;
        forever ::{
          when (i >= 360) send();
          sightRay(degrees:i);
          i += 10; 
        }
      } 
      
      

      @:targets = {};   
      @:importantItems = {};  
      
      @itemXmin = pointer.x - mapSizeW/2;
      @itemXmax = pointer.x + mapSizeW/2;

      @itemYmin = pointer.y - mapSizeH/2;
      @itemYmax = pointer.y + mapSizeH/2;
      


      @:chunks = chunkManager.loadScreenFor(x:pointer.x, y:pointer.y);
      for(itemYmin, itemYmax)::(itemY) {
        for(itemXmin, itemXmax)::(itemX) {
          
          
          @:id = posToId(x:(itemX / CHUNK_SIZE)->floor, y:(itemY / CHUNK_SIZE)->floor);
          @:scenery = chunks[id][(itemX->abs % CHUNK_SIZE) + (itemY->abs % CHUNK_SIZE)*CHUNK_SIZE];
          
          //@:scenery = chunkManager.getChunkSceneryForPosition(x:itemX, y:itemY);
          when(scenery != empty && scenery & IS_OBSCURED_MASK) empty



          /*
          @symbol 
          @:index = scenery & (~SETTINGS_MASK);
          if (index != 0)
            symbol = sceneryValues[index-1];
          
          if (symbol == '') symbol = empty;          
          */
          // a shiny quarter to anyone who can figure out 
          // why the above doesnt work as an alternative for whats below
          @symbol ::<= {
            @:index = scenery & (~SETTINGS_MASK);
            when(index == 0) empty;
            @:val = sceneryValues[index-1];
            
            when(val == '') empty;
            return val;          
          }
          



          @:x = itemX - pointer.x + mapSizeW/2;
          @:y = itemY - pointer.y + mapSizeH/2;
          canvas.movePen(x:left + x, y:top + y);  

          
          
          @chosenChar = ::<= {
            @:isWalled = (scenery & IS_WALLED_MASK);
            when(wallCharacter->length > 0 && symbol == empty && isWalled) ::<= {
              return wallCharacter;
            }

            @:items = this.itemsAt(x:itemX, y:itemY);
            if (items != empty && items->keycount > 0) ::<= {
              @:discovered = (items[items->keycount-1].traits & Map.TRAIT.DISCOVERED) != 0;
              
              if (
                discovered == true && 
                ((items[items->keycount-1].traits & Map.TRAIT.HAS_HALO) != 0) &&
                distance(x0:mapSizeW/2, y0:mapSizeH/2, x1:x, y1:y) < 7
              ) {
                targets->push(:{x:x, y:y, itemX:itemX, itemY:itemY});
              }
              importantItems->push(:{
                ch:if (discovered == false) '?' else items[items->keycount-1].symbol,
                x: x,
                y: y,
                itemX:itemX, itemY:itemY
              });
            }

            when (symbol != empty) ::<= {
              return symbol;
            }
          }

          when(isDark == true && isLit[''+itemX+','+itemY] == empty && chosenChar != empty) ::<= {
            when(chosenChar != empty && chosenChar == ' ')
              canvas.drawChar(text:' ');            
              
            canvas.drawChar(text:TOO_FAR_CHARACTER);            
          }
          if (chosenChar)
            canvas.drawChar(text:chosenChar);            
        }       
      }       
      
      foreach(targets) ::(k, v) {
        when(isDark && isLit[''+v.itemX+','+v.itemY] == empty) empty;
        drawTarget(*v);
      }

      foreach(importantItems) ::(k, v) {
        when(v.ch == '') empty;

        @xt = v.x;
        @yt = v.y
        canvas.movePen(x:xt, y:yt);  
        when(isDark && isLit[''+v.itemX+','+v.itemY] == empty)
          canvas.drawChar(:TOO_FAR_SYMBOL_CHARACTER);

        canvas.drawChar(text:v.ch);
      }
      
      
      // TODO: walls
      
      /*
      entities->foreach(do:::(i, ent) {
        @itemX = ((ent.x - pointer.x + mapSizeW/2))->floor;
        @itemY = ((ent.y - pointer.y + mapSizeH/2))->floor;
      
        when(itemX < 1 || itemY < 1 || itemX >= mapSizeW || itemY > mapSizeH) empty;
        canvas.movePen(x:left-1 + itemX, y:top + itemY);  
        canvas.drawText(text:'*');        
      });
      */
      
  
      canvas.movePen(
        x:left + (mapSizeW/2)->floor,
        y:top  + (mapSizeH/2)->floor     
      );
      
      canvas.drawText(text:'Ø');
      //canvas.debugLine = 'Frame took ' + (Time.getTicks() - ticks) + 'ms';
          
    }

    @:retrieveItem = ::(data) {
      return items->filter(by:::(value) <- value.data == data)[0];
    }
    
    @:putArea = ::<= {
      @:tryMap = [
        [0, 0],
        [-1, -1],
        [1, 1],
        [-1, 1],
        [1, -1],
        [-2, 0],
        [ 2, 0],
        [ 0, 2],
        [ 0, -2],
      ];
      return ::(area, item) <- ::? {        
        @iter = 0;
        forever ::{
          @:offset = tryMap[iter];
          iter += 1;
          if (iter >= tryMap->size)
            iter = 0;
            
          @location = {
            x: (area.x + area.width/2 + offset[0])->floor,
            y: (area.y + area.height/2 + offset[1])->floor
          }        

          @:already = this.itemsAt(x:location.x, y:location.y);
          when(already != empty && already->keycount) empty;
          area.occupy()
          send(:location);
        }    
      
      }
    }    

    this.interface = {
      initialize ::(parent) {
        parent_ = parent;
      },
      events : {
        get ::<- events
      },
      defaultLoad ::{},
      
      drawLegend : {
        get ::<- drawLegend,
        set ::(value) <- drawLegend = value
      },
      
      enableWall ::(x, y) {
        chunkManager.orChunkSceneryForPosition(x, y, value:IS_WALLED_MASK);        
      },
      
      disableWall ::(x, y) {  
        chunkManager.andChunkSceneryForPosition(x, y, value:~IS_WALLED_MASK);
      },
      
      mapCoordinatesToScreen ::(x, y) {
        @mapSizeW  = canvas.width;
        @mapSizeH  = canvas.height;

        if (paged) ::<= {
          @:regionX = ((pointer.x+0) / mapSizeW)->floor;
          @:regionY = ((pointer.y+0) / mapSizeH)->floor;

          x = x - regionX*mapSizeW;
          y = y - regionY*mapSizeH;
        
        } else ::<= {
          @camX = pointer.x;
          @camY = pointer.y;
          
          @camLeft   = camX - mapSizeW/2;
          @camTop    = camY - mapSizeH/2;
          @camRight  = camX + mapSizeW/2;
          @camBottom = camY + mapSizeH/2;
          
          
          x -= camLeft;
          y -= camTop;
        }
        
        return {
          x: x,
          y: y
        }
      },
      
      addScenerySymbol ::(character) {
        @:preIndex = sceneryValues->findIndex(value:character);
        when(preIndex != -1) preIndex;
        
        @:index = sceneryValues->keycount;
        sceneryValues->push(value:character);
        return index;
      },
      
      setSceneryIndex ::(
        x =>Number,
        y =>Number,
        symbol => Number
      ) {
        @:val = chunkManager.getChunkSceneryForPosition(x, y);
        chunkManager.setChunkSceneryForPosition(x, y, value: (1+symbol) | (val & SETTINGS_MASK));
      },


      fillSceneryIndexRectangle ::(
        symbol => Number,
        x => Number,
        y => Number,
        fillWidth => Number,
        fillHeight => Number
      ) {
        for(x, x+fillWidth)::(xi) {
          for(y, y+fillHeight)::(yi) {
            @:val = chunkManager.getChunkSceneryForPosition(x:xi, y:yi);
            chunkManager.setChunkSceneryForPosition(x:xi, y:yi, value: (1+symbol)|(val & SETTINGS_MASK));
          }    
        }
      },        
      
 
      clearScenery ::(
        x =>Number,
        y =>Number
      ) {
        chunkManager.andChunkSceneryForPosition(x, y, value:SETTINGS_MASK);
      },
      
      sceneryAt::(x, y) {
        @:index = chunkManager.getChunkSceneryForPosition(x, y) & (~SETTINGS_MASK);
        when(index == 0) empty;
        @:val = sceneryValues[index-1];
        
        when(val == '') empty;
        return val;
      },

      // loads a whole block of graphical scenery 
      // in a visual way
      paintScenery::(
        lines,
        wallCharacters,
        x,
        y
      ) {
        if (x == empty) x = 0;
        if (y == empty) y = 0;
      
        @:charIndex = {};
        @:wallIndex = {};
        if (wallCharacters != empty) ::<= {
          foreach(wallCharacters) ::(i, ch) {
            wallIndex[ch] = true;
          }
        }
        
        foreach(lines) ::(i, line) {
          for(0, line->length) ::(i) {
            @:ch = line->charAt(index:i);
            
            if (charIndex[ch] == empty)
              charIndex[ch] = this.addScenerySymbol(symbol:ch);
          }
        }

        foreach(lines) ::(i, line) {
          for(0, line->length) ::(i) {
            @:ch = line->charAt(index:i);
            this.setSceneryIndex(x, y, symbol:charIndex[ch]);
            if (wallIndex[ch] != empty)
              this.enableWall(x, y);
            x += 1;
          }
          y += 1;
        }
      },
      
      paintScenerySolidRectangle::(
        symbol, // if empty, clears scenery
        isWall,
        x => Number,
        y => Number,
        width => Number,
        height => Number
      ) {
        for(y, y+height) ::(iy) {
          for(x, x+width) ::(ix) {
            if (symbol == empty)
              this.clearScenery(x:ix, y:iy)
            else
              this.setSceneryIndex(x:ix, y:iy, symbol);
            if (isWall == true)
              this.enableWall(x:ix, y:iy)
            else 
              this.disableWall(x:ix, y:iy)
            ;
          }
        }
      },



      setItem::(
        data,
        
        // if presented, supercedes any x / y specified 
        // When an area is given, the map will attempt to place the 
        // item within a non-occupied region within the area.
        // if that fails, it will always place it in the center 
        // of the area.
        area,
        
        x,
        y,
        symbol,
        traits,
        name
      ) {
        // default: plain item
        if (traits == empty) {
          traits = Map.TRAIT.DISCOVERED
        }
      
        if (area) {
          @:location = putArea(area);
          if (location) {
            x = location.x;
            y = location.y;
          }
        }
        x = x->floor;
        y = y->floor;
        
        
        @loc = itemIndex[posToId(x, y)];
        if (loc == empty) ::<= {
          loc = [];
          itemIndex[posToId(x, y)] = loc;
        }
        @:val = {
          x: x,
          y: y,
          symbol : symbol,
          traits : traits,
          data: data,
          name: name
        }
        loc->push(value:val);
        items->push(value:val);
        events.emit(
          event: 'onSetItem',
          detail: {
            x : x,
            y : y,
            data : data
          }
        );
        return {x:x, y:y}
      },
      
      getItem::(data) {
        return retrieveItem(data);
      },
      
      xMapToScreen::(x) <- x - pointer.x + canvas.width/2,
      yMapToScreen::(y) <- y - pointer.y + canvas.height/2,
      
      getAllItemData::{
        @:out = {};
        foreach(items) ::(k, val) {
          out[val.data] = true;
        }
        return out->keys;
      },
      
      getAllItems ::{
        return items;
      },


      getItemsInView :: {
        @:which = [];
        foreach(items) ::(k, item) {
          if (this.isLocationVisible(x:item.x, y:item.y))
            which->push(:item);
        }
        return which;
      }, 
      
      itemsAt::(x, y) {
        return itemIndex[posToId(x, y)];
      },
      
      obscure : {
        set ::(value => Boolean) <- chunkManager.obscure = value,
        get ::<- chunkManager.obscure
      },
      
      obscureRectangle::(ignore, x, y, width, height) {
        for(x, x+width)::(x) {
          for(y, y+height)::(y) {
            @:sc = chunkManager.getChunkSceneryForPosition(x, y);
            when (ignore != empty && ((sc & (~SETTINGS_MASK))-1) == ignore) empty;
            chunkManager.orChunkSceneryForPosition(x, y, value: IS_OBSCURED_MASK);
          }
        }
      },
      
      obscureAt::(x, y) {
        chunkManager.orChunkSceneryForPosition(x, y, value: IS_OBSCURED_MASK);
      },
      
      obscureRadius::(x, y, radius) {        
        for(y - radius-1, y + radius+1) ::(yIter) {
          for(x - radius-1, x + radius+1) ::(xIter) {
            if (distance(x0:x, y0:y, x1:xIter, y1:yIter) <= radius) ::<= {
              chunkManager.orChunkSceneryForPosition(x:xIter, y:yIter, value: IS_OBSCURED_MASK);
            }
          }
        }
      },
      unobscureAt::(x, y) {
        chunkManager.andChunkSceneryForPosition(x, y, value: ~IS_OBSCURED_MASK);
      },

      unobscureRadius::(x, y, radius) {        
        for(y - radius-1, y + radius+1) ::(yIter) {
          for(x - radius-1, x + radius+1) ::(xIter) {
            if (distance(x0:x, y0:y, x1:xIter, y1:yIter) <= radius) ::<= {
              chunkManager.andChunkSceneryForPosition(x:xIter, y:yIter, value: ~IS_OBSCURED_MASK);
            }
          }
        }
      },

      
      clearItems::(x, y) {
        chunkManager.setChunkSceneryForPosition(x, y, value:empty);
      },
        
      removeItem::(
        data
      ) {
        @item = retrieveItem(data);
        @id = posToId(x:item.x, y:item.y);
      
        @itemsA = itemIndex[id];
        when(itemsA == empty) empty;
        ::? {
          foreach(itemsA)::(key, v) {
            when(v.data == data) ::<= {
              itemsA->remove(key);
              send();
            }
          }
        }



        if(itemsA->keycount == 0)
          itemIndex->remove(key:id);  
        
        items = items->filter(by::(value) <- value.data != data);
        events.emit(
          event: 'onRemoveItem',
          detail : {
            x : item.x,
            y : item.y,
            data : data
          }
        )

      },
      
      
      title : {
        set ::(value) <- title = value,
        get :: <- title
      },
      
      setPointer::(
        x,
        y
      ) {
        if (x == pointer.x &&
          y == pointer.y) empty;
      
        x = x->floor;
        y = y->floor;


        pointer.x = x;
        pointer.y = y;
        
        events.emit(
          event: 'onPointerMove',
          detail : {
            x : x,
            y : y
          }
        )
      },
      
      getDistanceFromItem ::(data) {
        @:item = retrieveItem(data);
        // todo: error?
        when (item == empty) 0xffffffff
        return distance(x0:pointer.x, y0:pointer.y, x1:item.x, y1:item.y);
      },
      
      discover ::(data){
        @:item = retrieveItem(data);
        // ignore discovered == empty, which says "no discovery"
        if ((item.traits & Map.TRAIT.DISCOVERED) == 0)
          item.traits |= Map.TRAIT.DISCOVERED;      
      },
      
      movePointerToward::(x, y) {
        @:path = aStarPath(start:pointer, goal:{x:x, y:y});        
        when(path == empty || path->keycount == 0) empty;
        
        this.setPointer(
          x: path[path->keycount-1].x,
          y: path[path->keycount-1].y        
        );
        
      },

      moveTowardPointer::(data, useBFS) {
        @:path = this.getPathTo(data, x:pointer.x, y:pointer.y, useBFS);
        when(path == empty || path->keycount == 0) empty;
        this.moveItem(
          data, 
          x:path[path->keycount-1].x,
          y:path[path->keycount-1].y
        )
      },
      
      getPath::(fromX, fromY, toX, toY, useBFS, corners) {
        // default
        if (corners == empty)
          corners = true;

        when(useBFS != empty)
          bfsPath(start:{x:fromX, y:fromY}, goal:{x:toX, y:toY}, corners);
        @:path = aStarPath(start:{x:fromX, y:fromY}, goal:{x:toX, y:toY}, corners);
        when(path == empty || path->keycount == 0) empty;
        return path;
      },

      getPathTo::(data, x, y, useBFS) {
        @:ent = retrieveItem(data);      
        return this.getPath(fromX:ent.x, fromY:ent.y,toX:x, toY:y, useBFS);
      },

      updateItem ::(
        data,
        traits,
        symbol,
        name
      ) {
        @:item = retrieveItem(data);      
        item.traits = traits;
        item.symbol = symbol;
        if (name != empty)
          item.name = name;
      },
      
      moveItem::(data, x, y) {
        @:ent = retrieveItem(data);      

        @items =  itemIndex[posToId(x:ent.x, y:ent.y)];
        items->remove(key:items->findIndex(value:ent));

        ent.x = x;
        ent.y = y;      

        @loc = itemIndex[posToId(x:ent.x, y:ent.y)];

        if (loc == empty) ::<= {
          loc = [];
          itemIndex[posToId(x:ent.x, y:ent.y)] = loc;
        }
        loc->push(value:ent);
        events.emit(
          event: 'onRemoveItem',
          detail : {
            x : x,
            y : y,
            data : data
          }
        )
      
      },    
      
      pointerX : {
        get ::<- pointer.x
      },
      
      pointerY : {
        get ::<- pointer.y      
      },
      
      undefinedCharacter : {
        get::<- undefinedCharacter,
        set::(value) <- undefinedCharacter = value
      },

      wallCharacter : {
        get::<- wallCharacter,
        set::(value) <- wallCharacter = value
      },
      
      movePointerAdjacent::(
        x,
        y
      ) {
        return this.movePointerFree(
          x:if (x > 0) 1 else if (x < 0) -1 else 0,
          y:if (y > 0) 1 else if (y < 0) -1 else 0
        );
      },
      
      movePointerFree::(
        x => Number,
        y => Number
      ) {
        x = x->floor;
        y = y->floor;

        @:changeX = x != 0;
        @:changeY = y != 0;

        if (changeX &&
          changeY) empty;

        @oldX = pointer.x;
        @oldY = pointer.y;

        if(changeX) ::<= {
          @offset = x;
          @old = pointer.x;
          @new = offset + old;
          y = pointer.y;


          @greater = new > old;

          ::? {
            forever ::{
              when (isWalled(x:new, y)) ::<= {
                new = new + (if (greater) -1 else 1);
              } 
              send();   
            }
          }
          x = new;
        } else ::<= {
          @offset = y;
          @old = pointer.y;
          @new = offset + old;
          x = pointer.x;


          @greater = new > old;

          ::? {
            forever ::{
              when (isWalled(x, y:new)) ::<= {
                new = new + (if (greater) -1 else 1);
              } 
              send();   
            }
          }
          y = new;
        
        }

        this.setPointer(x, y);
        when(oldX == pointer.x && oldY == pointer.y) false;
        return true;
      
      },
      
      
      paged : {
        get ::<- paged,
        set ::(value) <- paged = value
      },
      
      
      getItemsUnderPointer :: {
        return this.itemsAt(x:pointer.x, y:pointer.y);
      },

      getItemsUnderPointerRadius ::(radius) <- this.getItemsWithinRadius(x:pointer.x, y:pointer.y, radius),
      
      getItemsWithinRadius ::(x, y, radius) {
        @out = {};
        for(x - (radius / 2)->floor, x + (radius / 2)->ceil)::(xa) {
          for(y - (radius / 2)->floor, y + (radius / 2)->ceil)::(ya) {
            @:at = this.itemsAt(x:xa, y:ya);
            when(at == empty) empty;
            foreach(at)::(key, value) {
              out[value.data] = value;
            }
          }
        }
        
        return out->values;         
      },

      getNamedItemsUnderPointer :: {
        @:out = this.itemsAt(x:pointer.x, y:pointer.y);
        when(out == empty) [];
        return out->filter(by:::(value) <- value.name != empty);
      },

      getNamedItemsUnderPointerRadius ::(radius) {
        @:out = this.getItemsUnderPointerRadius(radius);  
        when(out == empty) [];
        return out->filter(by:::(value) <- value.name != empty);
      },

      isLocationVisible ::(x, y) {
        when(chunkManager.getChunkSceneryForPosition(x, y) & IS_OBSCURED_MASK) false;
        @mapSizeW  = canvas.width;
        @mapSizeH  = canvas.height;


        @camX = pointer.x;
        @camY = pointer.y;
        
        @camLeft   = camX - mapSizeW/2;
        @camTop  = camY - mapSizeH/2;
        @camRight  = camX + mapSizeW/2;
        @camBottom = camY + mapSizeH/2;
        
        return x >= camLeft && x <= camRight && y >= camTop && y <= camBottom;

      },
      
      MAP_CHARS_WIDTH: {
        get::<- canvas.width
      },
      
      MAP_CHARS_HEIGHT : {
        get::<- canvas.height
      },
      
      offsetX : {
        get::<- offsetX,
        set::(value) <- offsetX = value
      },

      offsetY : {
        get::<- offsetY,
        set::(value) <- offsetY = value
      },
      
      areas : {
        get ::<- areas
      },
            
      addArea ::(area => Area.type) {
        if (areas == empty)
          areas = [];
        areas->push(:area)
      },
      
      removeArea ::(area => Area.type) {
        @:index = areas->findIndex(:area);
        when(index == -1) empty;
        areas->remove(:index);
      },
      
      'isWalled' : ::(x, y) <- isWalled(x, y),

      
      getRandomEmptyArea :: {
        @areasEmpty = [...areas]->filter(by::(value) <- value.isOccupied == false);
        when (areasEmpty->keycount == 0)
          random.pickArrayItem(list:areas);
          
        return random.pickArrayItem(list:areasEmpty);
      },
      
      getRandomArea :: {
        return random.pickArrayItem(list:areas);
      }, 
      
      
      render ::(noBlank)  {
        if (noBlank != true)
          canvas.fill(:undefinedCharacter);

        renderUnpaged()
        @mapSizeW  = canvas.width;
        @mapSizeH  = canvas.height;

        
        @:left = canvas.width/2 - mapSizeW/2;
        @:top = canvas.height/2 - mapSizeH/2;

        
        // render the legend
        if (drawLegend) ::<= {
          @:legendEntries = this.getItemsInView();
          when(legendEntries->size == 0) empty;
          @width = 0;
          @:itemList = [];
          foreach(legendEntries)::(index, item) {
            
            @:val = if((item.traits & Map.TRAIT.DISCOVERED) != 0) 
              '' + item.symbol + ' ' + if (item.name == '') item.name else item.name
            else 
              '? ????'
            ;
            itemList->push(value:val);
            if (width < val->length)
              width = val->length;
          }
          
          
          canvas.renderFrame(
            top: 2,
            left: 0,
            width: width+4,
            height: itemList->keycount+2
          );
          
          canvas.movePen(x:1, y:2);
          canvas.drawText(text:'[Legend]');
          foreach(itemList)::(index, item) {
            canvas.movePen(x:2, y:index+3);
            canvas.drawText(text:item);
          }
            
        }



        @:world = import(module:'base/world.mt');
        // render the time under the map.
        canvas.movePen(x:0, y: 0);
        canvas.drawText(text:title);
        
      
      },
      
      parent : {
        get ::<- parent_,
        set ::(value) <- if (parent_ == empty) parent_ = value
      },
      
      
      isDark : {
        set ::(value) <- isDark = value,
        get ::<- isDark
      },
      
      /*
        Custom saving loading to save on data and reduce repeats 
        while keeping the actual usage of the data optimized for 
        quick access
      */
      save ::{
        @:compressedItems = {}
        @:dataList = [];
        @dataListPool = 0;
        @:dataUnique = {};
        foreach(items) ::(k, val) {
          @:itemCopy = {...val};
          compressedItems->push(value:itemCopy);

          @:dat = val.data;
          when(dat == empty) empty;



          if (dataUnique[dat] != empty) ::<= {
            itemCopy.data = dataUnique[dat]; // index copy.
          } else ::<= {
            dataUnique[dat] = dataListPool;
            dataList->push(value:dat);
            itemCopy.data = dataListPool;
            dataListPool+=1;
          }
        }
        
        
        
        
        @:itemsUnique = {};
        foreach(items) ::(index, value) {
          itemsUnique[value] = index;
        }
        
        

        // sparse array indexing
        @:itemIndexCompressed = {};
        foreach(itemIndex) ::(k ,v) {
          when(v == empty) empty;
          @:locs = {};
          foreach(v) :: (index, loc) {
             locs[index] = itemsUnique[loc];
          }
          itemIndexCompressed[k] = locs;
        };
        
        

        
      
        @:state = StateType.new();
        
        state. = {
          itemIndexCompressed : itemIndexCompressed,
          entities : entities,
          compressedItems : compressedItems,
          dataList : dataList,
          title : title,

          pointer : pointer,
          offsetX : offsetX,
          offsetY : offsetY,
          drawLegend : drawLegend,
          paged : paged,
          undefinedCharacter : undefinedCharacter,
          wallCharacter : wallCharacter,
          //@scenery = MemoryBuffer.new();
          sceneryCompressed : chunkManager,
          sceneryValues : sceneryValues,
          areas : areas,
          isDark : isDark,
        }
        return state.save();    
      },
      
      load ::(serialized) {
        @:v = StateType.new();
        v.load(parent:this, serialized);

        entities = v.entities;
        items = v.compressedItems;
        foreach(items) ::(k, val) {
          when(val.data == empty) empty;
          
          val.data = v.dataList[val.data];
        }
        
        
        itemIndex = [];
        foreach(v.itemIndexCompressed) ::(k, locs) {
          foreach(locs) ::(index, loc) {
            locs[index] = items[loc]
          }
          itemIndex[k] = locs;
        }
        
        
        title = v.title;

        pointer = v.pointer;
        offsetX = v.offsetX;
        offsetY = v.offsetY;
        drawLegend = v.drawLegend;
        paged = v.paged;
        undefinedCharacter = v.undefinedCharacter;
        wallCharacter = v.wallCharacter;
        sceneryValues = v.sceneryValues;
        areas = v.areas;
        isDark = v.isDark;
        chunkManager = v.sceneryCompressed;
      }
    }  
  }
);

return Map;
