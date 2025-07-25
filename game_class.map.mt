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
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');



@:StateType = State.create(
  items : {
    itemIndexCompressed : empty,
    entities : empty,
    compressedItems : empty,
    dataList : empty,
    legendEntriesCompressed : empty,
    title : '',

    pointer : empty,
    width : 0,
    height : 0,
    offsetX : 0,
    offsetY : 0,
    drawLegend : false,
    paged : false,
    outOfBoundsCharacter : '',
    wallCharacter : '',
    //@scenery = MemoryBuffer.new();
    sceneryCompressed : empty,
    sceneryValues : empty,
    stepAction : empty,
    areas : empty,
    renderOutOfBounds : false,
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
@mapSizeW  = 50;
@mapSizeH  = 18;
@:SIGHT_RAY_LIMIT = 8;
@:SIGHT_RAY_EPSILON = 0.4;


@:SETTINGS_MASK    = 0x110000;
@:IS_WALLED_MASK   = 0x010000;
@:IS_OBSCURED_MASK = 0x100000;

@:TOO_FAR_CHARACTER = '░';
@:TOO_FAR_SYMBOL_CHARACTER = '╩';

@:distance = import(module:'game_function.distance.mt');


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
    
    mapSizeH = canvas.height;
    mapSizeW = canvas.width;

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


@:Map =  LoadableClass.create(
  name: 'Wyvern.Map',

  statics : {
    Area : {
      get::<-Area
    } 
  },
  items : {},
  
  define:::(this, state) {
  
  
    @itemIndex = [];
    @entities = [];
    @items = [];
    @legendEntries = [];
    @title;

    @pointer = {
      x: 0,
      y: 0,
      discovered : true,
      symbol: 'Ø',
      name: "(Party)"
    }

    @width = 1;
    @height = 1;
    @offsetX = 0;
    @offsetY = 0;
    @drawLegend = false;
    @paged = true;
    @outOfBoundsCharacter = '▓';
    @wallCharacter = '▓';
    //@scenery = MemoryBuffer.new();
    @scenery = [];
    @sceneryValues = [];
    @stepAction = [];
    @areas;
    @renderOutOfBounds = true;
    @isDark = false;
    @parent_;
    @neighbors = [];
    @aStarPQCompareTable;


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
          @at = itemX+dx+((itemY+dy)*width);

          if (scenery[at] == 0 || this.sceneryAt(x:itemX+dx, y:itemY+dy) == ' ') ::<= {
            canvas.movePen(x:x+dx, y:y+dy);  
            canvas.drawChar(:char);
          }        
        }
      }
    }

    
    @:isWalled ::(x, y) {
      @:id = x + y*width;
      return (scenery[id] & IS_WALLED_MASK) != 0;
    }
    
    @:isWalledID ::(id) {
      return (scenery[id] & IS_WALLED_MASK) != 0;
    }

    @:aStarHeuristicH::(from, to) {
      @fromX = from%width;
      @fromY = (from/width)->floor
      
      @toX = to%width;
      @toY = (to/width)->floor
      return distance(x0:fromX, y0:fromY, x1:toX, y1:toY)
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
      @:presized = [];
      presized[width*height] = 1;
      return {
        //list: [],
        index: presized
      }
    }
    
    @:aStarPQNew :: {
      return [];
    }


    @:aStarReconstructPath::(cameFrom, current, start) {
      @:path = [];
      return ::? {
        forever ::{
          path->push(value:{
            x: current%width,
            y:(current/width)->floor
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

    @:aStarNewNode::(x, y) {
      @id = x + y*width;
      when (!isWalledID(id) && x >= 0 && y >= 0 && x < width && y < height)
        id;
    }

    @:aStarGetNeighborsCorners::(neighbors, current) {
      neighbors->setSize(size:0);
      @:x = current%width;
      @:y = (current/width)->floor
      
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
      @:x = current%width;
      @:y = (current/width)->floor
      
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
      @:getNeighbors = if (corners)
        aStarGetNeighborsCorners
      else 
        aStarGetNeighborsNoCorners
        
           
      start = aStarNewNode(x:start.x, y:start.y);
      goal = aStarNewNode(x:goal.x, y:goal.y);
      
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
      start = aStarNewNode(x:start.x, y:start.y);
      goal = aStarNewNode(x:goal.x, y:goal.y);    
      @:getNeighbors = if (corners)
        aStarGetNeighborsCorners
      else 
        aStarGetNeighborsNoCorners
    
      when (BFS_NATIVE!=empty) ::<= {
        @:result = BFS_NATIVE(
          width,
          height,
          scenery,
          start,
          goal,
          corners
        );
        when(result == empty) empty;
        @:out = [];
        for(0, result->size) ::(i) {
          @:a = result[i];
          out->push(value:{
            x: a%width,
            y: (a/width)->floor
          });
        }
        return out;
      }
      
      
      // fallback on slow version

      
      when(start == goal) empty;
      @:q = bfsQ;
      @qIter = 0;
      @:visited = {}
      @:neighbors = [];
      visited[start] = start;
      q->push(value:start);
      
      return ::? {
        forever ::{
          when(qIter >= q->size) send();
          
          @v = q[qIter];
          qIter +=1;


          when(v == goal) ::<= {
            // build path
            send(message: ::<={
              @:path = [];
              ::? {
                @a = v;
                @last;
                forever ::{
                  @:next = {
                    x: a%width,
                    y: (a/width)->floor
                  };
                  path->push(value:next);      
                  when(visited[a] == start) ::<= {
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
        }
      }
    }
    
    
    @:renderPaged ::{
      
      
      @:left = canvas.width/2 - mapSizeW/2;
      @:top = canvas.height/2 - mapSizeH/2;

      


      @:regionX = ((pointer.x + mapSizeW*0.5) / mapSizeW)->floor;
      @:regionY = ((pointer.y + mapSizeH*0.5) / mapSizeH)->floor;


      @:centerX = (mapSizeW / 2)->floor;
      @:centerY = (mapSizeH / 2)->floor;
      
      //@:map = [...scenery, ...items->values];
      /*
      scenery->foreach(do:::(item, data) {
        @itemX = ((data.x - regionX) * mapSizeW)->floor;
        @itemY = ((data.y - regionY) * mapSizeH)->floor;
      
        when(itemX < 1 || itemY < 1 || itemX >= mapSizeW || itemY >= mapSizeH) empty;
        canvas.movePen(x:left-1 + itemX, y:top-1 + itemY);  
        canvas.drawText(text:data.symbol);
      });
      map->foreach(do:::(item, data) {
        @itemX = ((x+data.x - regionX) * mapSizeW)->floor;
        @itemY = ((y+data.y - regionY) * mapSizeH)->floor;
      
        when(itemX < 1 || itemY < 1 || itemX >= mapSizeW || itemY >= mapSizeH) empty;
        canvas.movePen(x:left-1 + itemX, y:top + itemY);  
        canvas.drawText(text:data.symbol);

        canvas.movePen(x:left-1 + itemX+1, y:top + itemY+1);  
        canvas.drawText(text:data.symbol);

        canvas.movePen(x:left-1 + itemX, y:top + itemY+1);  
        canvas.drawText(text:data.symbol);

        canvas.movePen(x:left-1 + itemX+1, y:top + itemY);  
        canvas.drawText(text:data.symbol);
      });
      */
      @:targets = {};
      @:importantItems = {};
      
      for(0, mapSizeH+1)::(y) {
        for(0, mapSizeW+1)::(x) {
          @itemX = (x) + regionX*mapSizeW - mapSizeW*0.5;
          @itemY = (y) + regionY*mapSizeH - mapSizeH*0.5;
          
          when(itemX < 0 || itemY < 0 || itemX >= width || itemY >= height) empty;
          
          @symbol = this.sceneryAt(x:itemX, y:itemY);

          canvas.movePen(x:left + x, y:top + y);  

          when(symbol == 1) ::<= {
            canvas.drawChar(text:wallCharacter);
          }
          

          when(itemX < 0 || itemY < 0 || itemX >= width+0 || itemY >= height+0) ::<= {
            when (symbol != empty)
              canvas.drawChar(text:symbol);

            when(!renderOutOfBounds) empty;
            canvas.drawChar(text:outOfBoundsCharacter);
          }


          @:items = this.itemsAt(x:itemX, y:itemY);
          when(items != empty) ::<= {
            @:discovered = items[items->keycount-1].discovered;
            
            if (discovered == true)
              targets->push(:{x:x, y:y, itemX:itemX, itemY:itemY});
              
            importantItems->push(:{
              ch:if (discovered == false) '?' else items[items->keycount-1].symbol,
              x: x,
              y: y
            });
          }

          when (symbol != empty) ::<= {
            canvas.drawChar(text:symbol);
          }


          canvas.drawChar(text:' ');
        }        
      }        
              
      foreach(targets) ::(k, v) {
        drawTarget(*v);
      }

      foreach(importantItems) ::(k, v) {
        @xt = left + v.x;
        @yt = top + v.y
        canvas.movePen(x:xt, y:yt);  
        canvas.drawChar(text:v.ch);
      }
      
  
      canvas.movePen(
        x:left + ((pointer.x - regionX*mapSizeW  + mapSizeW*0.5))->floor,
        y:top  + ((pointer.y - regionY*mapSizeH  + mapSizeH*0.5))->floor     
      );
      
      canvas.drawText(text:'Ø');
          
    }
    
    @:renderUnpaged ::{
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
            

            when((x < offsetX || y < offsetY || x >= width+offsetX || y >= height+offsetY)) send();

            when(distance(x0:pointer.x, y0:pointer.y, x1:x, y1:y) > SIGHT_RAY_LIMIT) send();
            scenery[x->floor+y->floor*width] &= ~IS_OBSCURED_MASK;            
            if (isDark == true) isLit[x->floor+y->floor*width] = true;
            if (isWalled(x:x->floor, y:y->floor))
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
      
      /*
      [0, mapSizeH+1]->for(do:::(y) {
        [0, mapSizeW+1]->for(do:::(x) {
          @itemX = ((x + pointer.x - mapSizeW/2))->floor;
          @itemY = ((y + pointer.y - mapSizeH/2))->floor;

          when((itemX < offsetX || itemY < offsetY || itemX >= width+offsetX || itemY >= height+offsetY)) empty;
          
          
          if (obscured[itemX][itemY])
            if (distance(x0:pointer.x, y0:pointer.y, x1:itemX, y1:itemY) < 5)
              obscured[itemX][itemY] = false;
        });
      }); 
      */  
      @:targets = {};   
      @:importantItems = {};  
      for(0, mapSizeH+1)::(y) {
        for(0, mapSizeW+1)::(x) {
          @itemX = ((x + pointer.x - mapSizeW/2))->floor;
          @itemY = ((y + pointer.y - mapSizeH/2))->floor;

          @symbol = this.sceneryAt(x:itemX, y:itemY);

          @:items = this.itemsAt(x:itemX, y:itemY);
          canvas.movePen(x:left + x, y:top + y);  



          when((itemX < offsetX || itemY < offsetY || itemX >= width+offsetX || itemY >= height+offsetY)) ::<= {
            when (symbol != empty) ::<= {
              canvas.drawChar(text:symbol);
            }

            when(renderOutOfBounds) ::<= {
              canvas.drawChar(text:outOfBoundsCharacter);
            }
          }

          
          
          //if (obscured[itemX][itemY])
          //  if (distance(x0:pointer.x, y0:pointer.y, x1:itemX, y1:itemY) < 5)
          //    obscured[itemX][itemY] = false;
          
          when(scenery[itemX+itemY*width] & IS_OBSCURED_MASK) ::<= {
            canvas.drawChar(text:outOfBoundsCharacter);            
          }
          
          @:chosenChar = ::<= {
            
            when(symbol == empty && isWalled(x:itemX, y:itemY)) ::<= {
              return wallCharacter;
            }

            when(items != empty && items->keycount > 0) ::<= {
              @:discovered = items[items->keycount-1].discovered;
              
              if (discovered == true && (items[items->keycount-1].noHalo == empty))
                targets->push(:{x:x, y:y, itemX:itemX, itemY:itemY});
                
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

          when(isDark == true && isLit[itemX+itemY*width] != true && chosenChar != empty) ::<= {
            when(chosenChar != empty && chosenChar == ' ') empty;
            canvas.drawChar(text:TOO_FAR_CHARACTER);            
          }
          if (chosenChar)
            canvas.drawChar(text:chosenChar);            
        }       
      }       
      
      foreach(targets) ::(k, v) {
        when(isDark && isLit[v.itemX+v.itemY*width] != true) empty;
        drawTarget(*v);
      }

      foreach(importantItems) ::(k, v) {
        @xt = v.x;
        @yt = v.y
        canvas.movePen(x:xt, y:yt);  
        when(isDark && isLit[v.itemX+v.itemY*width] != true)
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
      return ::(area, item, symbol, name, discovered) {
        area.occupy()
        ::? {        
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
            item.x = location.x;
            item.y = location.y;

            this.setItem(data:item, x:location.x, y:location.y, symbol, discovered, name);



            send();
          }    
        }      
      }
    }    


    this.interface = {
      initialize ::(parent) {
        parent_ = parent;
      },
      defaultLoad ::{},
      width : {
        get ::<- width,
        set ::(value) {
          width = value;
          @:size = (width*height);
          for(0, size)::(i) {
            scenery[i] = 0;
          }
        }
      },

      height : {
        get ::<- height,
        set ::(value) {
          height = value;
          @:size = (width*height);
          for(0, size)::(i) {
            scenery[i] = 0;
          }    
        }
      },
      
      drawLegend : {
        get ::<- drawLegend,
        set ::(value) <- drawLegend = value
      },
      
      enableWall ::(x, y) {
        scenery[x + y*(width)] |= IS_WALLED_MASK;        
      },
      
      disableWall ::(x, y) {    
        scenery[x + y*(width)] &= (~IS_WALLED_MASK);
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
        @index = x + y*(width);
        
        scenery[index] = (scenery[index] & SETTINGS_MASK) | (1+symbol);
      },
      
      
      fillSceneryIndex ::(
        symbol => Number
      ) {
        for(0, height)::(y) {
          for(0, width)::(x) {
            @index = x + y*(width);
          
            scenery[index] = (scenery[index] & SETTINGS_MASK) | (1+symbol);
          }    
        }
      },      
      setStepAction ::(
        x => Number,
        y => Number,
        action
      ) {
        stepAction[x + y*width] = action;
      },

      clearScenery ::(
        x =>Number,
        y =>Number
      ) {
        @index = x + y*(width);
        
        scenery[index] = SETTINGS_MASK & scenery[index];
      },
      
      sceneryAt::(x, y) {
        @at = x+(y*width);
        when(x < 0 || y < 0)
          outOfBoundsCharacter;
          
        when(x >= width || y >= height)
          outOfBoundsCharacter;
          
        @:index = scenery[at] & (~SETTINGS_MASK);
        when(index == 0) empty;
        return sceneryValues[index-1];
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
        symbol => Number,
        isWall,
        x => Number,
        y => Number,
        width => Number,
        height => Number
      ) {
        for(y, y+height) ::(iy) {
          for(x, x+width) ::(ix) {
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
        x,
        y,
        symbol,
        discovered,
        name,
        noHalo
      ) {
        x = x->floor;
        y = y->floor;
        
        when(x < 0 || y < 0 || x >= width || y >= height)
          error(detail:'Bad');
        
        @loc = itemIndex[x + y * (width)];
        if (loc == empty) ::<= {
          loc = [];
          itemIndex[x + y*(width)] = loc;
        }
        @:val = {
          x: x,
          y: y,
          symbol : symbol,
          discovered : discovered,
          data: data,
          name: name,
          noHalo : noHalo
        }
        loc->push(value:val);
        items->push(value:val);
        if (name != empty)
          legendEntries->push(value:val);
      },
      
      getItem::(data) {
        return retrieveItem(data);
      },
      
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
      
      itemsAt::(x, y) {
        return itemIndex[x + y*(width)];
      },
      
      obscure::{
        isDark = true;
        for(0, width)::(x) {
          for(0, height)::(y) {
            scenery[x+y*width] |= IS_OBSCURED_MASK;
          }
        }
      },
      
      obscureAt::(x, y) {
        scenery[x+y*width] |= IS_OBSCURED_MASK
      },
      
      obscureRadius::(x, y, radius) {        
        for(y - radius-1, y + radius+1) ::(yIter) {
          for(x - radius-1, x + radius+1) ::(xIter) {
            if (distance(x0:x, y0:y, x1:xIter, y1:yIter) <= radius) ::<= {
              scenery[xIter+yIter*width] |= IS_OBSCURED_MASK              
            }
          }
        }
      },
      
      clearItems::(x, y) {
        itemIndex[x + y*(width)] = empty;
      },
        
      removeItem::(
        data
      ) {
        @item = retrieveItem(data);
      
        @itemsA = itemIndex[item.x + (item.y)*(width)];
        when(itemsA == empty) empty;
        ::? {
          foreach(itemsA)::(key, v) {
            when(v.data == data) ::<= {
              itemsA->remove(key);
              send();
            }
          }
        }
        if (item.name != empty) ::<= {
          ::? {
            foreach(legendEntries)::(key, v) {
              when(v.data == data) ::<= {
                legendEntries->remove(key);
                send();
              }
            }
          }
        }


        if(itemsA->keycount == 0)
          itemIndex[item.x + (item.y)*(width)] = empty;  
          
        items = items->filter(by::(value) <- value.data != data);
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
        when(x < 0 || x > width || y < 0 || y > height)
          error(detail:'Bad');


        pointer.x = x;
        pointer.y = y;

        @:trigger = stepAction[x + y*width];
        if (trigger != empty)
          trigger(); 
      },
      
      getDistanceFromItem ::(data) {
        @:item = retrieveItem(data);
        return distance(x0:pointer.x, y0:pointer.y, x1:item.x, y1:item.y);
      },
      
      discover ::(data){
        @:item = retrieveItem(data);
        // ignore discovered == empty, which says "no discovery"
        if (item.discovered == false)
          item.discovered = true;      
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
      
      moveItem::(data, x, y) {
        @:ent = retrieveItem(data);      

        @items =  itemIndex[ent.x + (ent.y)*(width)];
        items->remove(key:items->findIndex(value:ent));

        ent.x = x;
        ent.y = y;      

        @loc = itemIndex[ent.x + (ent.y)*(width)];

        if (loc == empty) ::<= {
          loc = [];
          itemIndex[ent.x + (ent.y)*(width)] = loc;
        }
        loc->push(value:ent);
      
      },    
      
      pointerX : {
        get ::<- pointer.x
      },
      
      pointerY : {
        get ::<- pointer.y      
      },
      
      outOfBoundsCharacter : {
        get::<- outOfBoundsCharacter,
        set::(value) <- outOfBoundsCharacter = value
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

          if (new < 0) new = 0;
          if (new >= width) new = width-1;

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

          if (new < 0) new = 0;
          if (new >= height) new = height-1;

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
        when(out == empty) empty;
        return out->filter(by:::(value) <- value.name != empty);
      },

      getNamedItemsUnderPointerRadius ::(radius) {
        @:out = this.getItemsUnderPointerRadius(radius);  
        when(out == empty) empty;
        return out->filter(by:::(value) <- value.name != empty);
      },

      isLocationVisible ::(x, y) {
        return if (paged) ::<= {
          @:regionX = ((pointer.x+0) / mapSizeW)->floor;
          @:regionY = ((pointer.y+0) / mapSizeH)->floor;
          @:itemX = (x) + regionX*mapSizeW;
          @:itemY = (y) + regionY*mapSizeH;
          return !(itemX < 0 || itemY < 0 || itemX >= width+0 || itemY >= height+0);

        
        } else ::<= {
          @camX = pointer.x;
          @camY = pointer.y;
          
          @camLeft   = camX - mapSizeW/2;
          @camTop  = camY - mapSizeH/2;
          @camRight  = camX + mapSizeW/2;
          @camBottom = camY + mapSizeH/2;
          
          return x >= camLeft && x <= camRight && y >= camTop && y <= camBottom;
        }

      },
      
      MAP_CHARS_WIDTH: {
        get::<- mapSizeW
      },
      
      MAP_CHARS_HEIGHT : {
        get::<- mapSizeH
      },
      
      offsetX : {
        get::<- offsetX,
        set::(value) <- offsetX = value
      },

      offsetY : {
        get::<- offsetY,
        set::(value) <- offsetY = value
      },
      
      renderOutOfBounds : {
        get::<- renderOutOfBounds,
        set::(value) <- renderOutOfBounds = value
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
      addToArea ::(area => Area.type, item, symbol, name, discovered) {
        return putArea(
          area,
          item,
          symbol,
          name,
          discovered
        );
        
      },
      
      addToRandomArea ::(item, symbol, name, discovered) {
        return putArea(
          area: random.pickArrayItem(list:areas),
          item,
          symbol,
          name,
          discovered
        );
      },
      
      addToRandomEmptyArea ::(item, symbol, name, discovered) {
        @areasEmpty = [...areas]->filter(by::(value) <- value.isOccupied == false);
        when (areasEmpty->keycount == 0)
          this.addToRandomArea(item, symbol, name, discovered)

        return putArea(
          area: random.pickArrayItem(list:areasEmpty),
          item,
          symbol,
          name,
          discovered
        );
      },
      
      getRandomEmptyArea :: {
        @areasEmpty = [...areas]->filter(by::(value) <- value.isOccupied == false);
        when (areasEmpty->keycount == 0)
          random.pickArrayItem(list:areas);
          
        return random.pickArrayItem(list:areasEmpty);
      },
      
      getRandomArea :: {
        return random.pickArrayItem(list:areas);
      },  
      
      render :: {
        canvas.blackout();
        if (paged)
          renderPaged()
        else 
          renderUnpaged()
        ;
        
        
        @:left = canvas.width/2 - mapSizeW/2;
        @:top = canvas.height/2 - mapSizeH/2;

        
        // render the legend
        if (drawLegend) ::<= {
          @width = 0;
          @:itemList = [];
          foreach(legendEntries)::(index, item) {
            
            @:val = if(item.discovered) 
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



        @:world = import(module:'game_singleton.world.mt');
        // render the time under the map.
        canvas.movePen(x:0, y: 0);
        canvas.drawText(text:title);
        
      
      },
      
      parent : {
        get ::<- parent_
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
        
        
        @:legendEntriesCompressed = {};
        foreach(legendEntries) ::(k, val) {
          legendEntriesCompressed[k] = itemsUnique[val];
          if (legendEntriesCompressed[k] == empty)
            error(detail:'Something went wrong (legend entry was a non-numbered index)')
        }

        // sparse array indexing
        @:itemIndexCompressed = {};
        foreach(itemIndex) ::(k ,v) {
          when(v == empty) empty;
          @:locs = {};
          foreach(v) :: (index, loc) {
             locs[index] = itemsUnique[loc];
          }
          itemIndexCompressed[''+k] = locs;
        };
        
        
        // EXTREMELY simple compression thats ideal for general maps
        // since they have a lot of empty space (repeats)
        @:sceneryCompressed = [scenery->size];
        @sceneryLast = -1;
        @sceneryCount = 0;
        foreach(scenery) ::(index, value) {
          if (sceneryLast != value) ::<= {
            if (sceneryCount > 0) ::<= {
              sceneryCompressed->push(value:sceneryLast);
              sceneryCompressed->push(value:sceneryCount);
            }
            
            sceneryLast = value;
            sceneryCount = 0;
          }
          sceneryCount += 1;
        }
        if (sceneryCount > 0) ::<= {
          sceneryCompressed->push(value:sceneryLast);
          sceneryCompressed->push(value:sceneryCount);
        }
        
      
        @:state = StateType.new();
        
        state. = {
          itemIndexCompressed : itemIndexCompressed,
          entities : entities,
          compressedItems : compressedItems,
          dataList : dataList,
          legendEntriesCompressed : legendEntriesCompressed,
          title : title,

          pointer : pointer,
          width : width,
          height : height,
          offsetX : offsetX,
          offsetY : offsetY,
          drawLegend : drawLegend,
          paged : paged,
          outOfBoundsCharacter : outOfBoundsCharacter,
          wallCharacter : wallCharacter,
          //@scenery = MemoryBuffer.new();
          sceneryCompressed : sceneryCompressed,
          sceneryValues : sceneryValues,
          stepAction : stepAction,
          areas : areas,
          renderOutOfBounds : renderOutOfBounds,
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
        
        legendEntries = [];
        foreach(v.legendEntriesCompressed) ::(k, val) {
          legendEntries[k] = items[val];
        }
        
        itemIndex = [];
        foreach(v.itemIndexCompressed) ::(k, locs) {
          foreach(locs) ::(index, loc) {
            locs[index] = items[loc]
          }
          itemIndex[Number.parse(string:k)] = locs;
        }
        

        // unpack scenery by first presizing the array
        scenery = [];
        @sceneryIndex = 0;
        scenery[v.sceneryCompressed[0]] = 0;
        scenery->remove(key:v.sceneryCompressed[0]);
        
        @sceneryLast;
        @sceneryCount;
        for(1, v.sceneryCompressed->size) ::(index) {
          @:value = v.sceneryCompressed[index];
          when (sceneryLast == empty) ::<= {
            sceneryLast = value;
          }
          
          sceneryCount = value;
          for(0, sceneryCount) ::(i) {
            scenery[sceneryIndex] = sceneryLast;
            sceneryIndex += 1;
          }
          sceneryLast = empty;
        }         
        
        title = v.title;

        pointer = v.pointer;
        width = v.width;
        height = v.height;
        offsetX = v.offsetX;
        offsetY = v.offsetY;
        drawLegend = v.drawLegend;
        paged = v.paged;
        outOfBoundsCharacter = v.outOfBoundsCharacter;
        wallCharacter = v.wallCharacter;
        sceneryValues = v.sceneryValues;
        stepAction = v.stepAction;
        areas = v.areas;
        renderOutOfBounds = v.renderOutOfBounds;
        isDark = v.isDark;
      }
    }  
  }
);

return Map;
