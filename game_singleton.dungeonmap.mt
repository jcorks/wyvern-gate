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
@:Map = import(module:'game_class.map.mt');

@:Area = Map.Area;


@:EPSILON = 0.000001;

@:distance::(x0, y0, x1, y1) {
  @xd = x1 - x0;
  @yd = y1 - y0;
  return (xd**2 + yd**2)**0.5;
}

@:BIG = 100000000;

@:GEN_OFFSET = 20;





@:DungeonGamma = ::(map, mapHint) {
  @cavities = [];
  @:areas = [];
  
  @ROOM_AREA_SIZE = random.integer(from:4, to:7); // was 5
  @ROOM_AREA_SIZE_LARGE = random.integer(from:4, to:9);// was 9
  @ROOM_AREA_VARIANCE = random.integer(from:1, to: 3)*0.2; // was 0.2
  @ROOM_SIZE = random.integer(from:35, to:45); //50;
  @ROOM_EMPTY_AREA_COUNT = random.integer(from:12, to: 18); //13;
  ;
  

  @:generateArea ::(item) {
    @width  = if (random.number() > 0.5) ROOM_AREA_SIZE else ROOM_AREA_SIZE_LARGE;
    @height = width;
    width  *= 1 + random.number() * 0.2;
    height *= 1 + random.number() * 0.2;
  
    width = width->floor;
    height = height->floor;
  
    @left = (item.x - width/2  + width  * (random.number() * 0.4 - 0.2))->floor;
    @top  = (item.y - height/2 + height * (random.number() * 0.4 - 0.2))->floor;
    


    if (left < 0) left = GEN_OFFSET;
    if (left + width +2 >= (ROOM_SIZE+GEN_OFFSET)-1) left = (ROOM_SIZE+GEN_OFFSET) - width - 3;
    if (top < 0) top = GEN_OFFSET;
    if (top + height +2 >= (ROOM_SIZE+GEN_OFFSET)-1) top = (ROOM_SIZE+GEN_OFFSET) - height - 3;
    

    areas->push(value: Area.new(
      x: left,
      y: top,
      width: width,
      height: height
    ));
        
    for(0, width+1)::(i) {
      map.enableWall(
        x:left + i,
        y:top
      );

      map.enableWall(
        x:left + i,
        y:top + height
      );
    }

    for(0, height+1)::(i) {
      map.enableWall(
        x:left,
        y:top + i
      );

      map.enableWall(
        x:left + width,
        y:top + i
      );
    }

  }
  
  @:applyCavities::{
    foreach(cavities)::(i, cav) {
      map.enableWall(
        x:cav.x+1,
        y:cav.y
      );
      map.enableWall(
        x:cav.x-1,
        y:cav.y
      );
      map.enableWall(
        x:cav.x,
        y:cav.y+1
      );
      map.enableWall(
        x:cav.x,
        y:cav.y-1
      );
      
      map.enableWall(
        x:cav.x-1,
        y:cav.y-1
      );
      map.enableWall(
        x:cav.x+1,
        y:cav.y+1
      );
      map.enableWall(
        x:cav.x+1,
        y:cav.y-1
      );
      map.enableWall(
        x:cav.x-1,
        y:cav.y+1
      );

    }
  }

  @:cleanupAreas::{
    foreach(areas)::(i, area) {
      for(area.x+1, area.x + area.width)::(x) {
        for(area.y+1, area.y + area.height)::(y) {
          map.disableWall(x, y);
        }
      }
    }
    
    foreach(cavities)::(i, cav) {
      map.disableWall(x:cav.x, y:cav.y);
    }
    cavities = [];
  }

  
  @:addCavity ::(x, y) {
    cavities->push(value:{x:x, y:y});
  }
  
  @:networkAreas ::{
    @remaining = [...areas];
    @next = remaining->pop;
    for(0, areas->keycount-1)::(i) {
      @:a = next;
      @:b = remaining->pop;        

      // find x / y path from a -> b
      @ax = (a.x + (random.number() - 0.5)*0.5 * a.width + a.width/2)->floor;
      @ay = (a.y + (random.number() - 0.5)*0.5 * a.height + a.height/2)->floor;

      @bx = (b.x + (random.number() - 0.5)*0.5 * b.width + b.width/2)->floor;
      @by = (b.y + (random.number() - 0.5)*0.5 * b.height + b.height/2)->floor;


      if (ax < 0) ax = 0;
      if (ay < 0) ay = 0;
      if (bx < 0) bx = 0;
      if (by < 0) by = 0;


      @fromx = if (ax < bx) ax else bx;
      @tox   = if (ax > bx) ax else bx;
      @fromy = if (ay < by) ay else by;
      @toy   = if (ay > by) ay else by;
    
      @fromx_y = if (ax < bx) ay else by;

      next = b;
      
      /*
      if(fromx <= 0) fromx = 1;
      if(fromx >= (ROOM_SIZE+GEN_OFFSET)-1) fromx = (ROOM_SIZE+GEN_OFFSET)-2;
      if(fromy <= 0) fromy = 1;
      if(fromy >= ROOM_SIZE-1) fromy = ROOM_SIZE-2;
      if(tox <= 0) tox = 1;
      if(tox >= ROOM_SIZE-1) tox = ROOM_SIZE-2;
      if(toy <= 0) toy = 1;
      if(toy >= ROOM_SIZE-1) toy = ROOM_SIZE-2;
      */


      for(fromx-1, tox+1)::(i) {
        addCavity(
          x:i,
          y:fromx_y
        );          
      }


      for(fromy-1, toy+1)::(i) {
        addCavity(
          x:tox,
          y:i
        );          
      }

      
    }
  }

  @:generateLayout :: {
    /*[0, 200]->for(do:::(i) {
      enableWall(
        x: (ROOM_SIZE * random.number())->floor,
        y: (ROOM_SIZE * random.number())->floor
      );
    });*/
        
  
    
    for(0, ROOM_EMPTY_AREA_COUNT)::(i) {
      generateArea(
        item:{
          x:(random.number()*ROOM_SIZE)->floor + GEN_OFFSET, 
          y:(random.number()*ROOM_SIZE)->floor + GEN_OFFSET
        }
      );        
    }
    
    networkAreas();
    applyCavities();
    cleanupAreas();
  }
  
  
  if (mapHint.roomAreaSize != empty) ROOM_AREA_SIZE = mapHint.roomAreaSize;
  if (mapHint.roomAreaSizeLarge != empty) ROOM_AREA_SIZE_LARGE = mapHint.roomAreaSize;
  if (mapHint.emptyAreaCount != empty) ROOM_EMPTY_AREA_COUNT = mapHint.emptyAreaCount;
  if (mapHint.roomSize != empty) ROOM_SIZE = mapHint.roomSize;
  map.width = ROOM_SIZE + GEN_OFFSET*2;
  map.height = ROOM_SIZE + GEN_OFFSET*2;
  map.obscure();  
  generateLayout();
  return areas;
};






@:DungeonBeta = ::(map, mapHint) {
  @cavities = [];
  @:areas = [];
  
  @:AREA_SIZE = 7; 
  @:MINIMUM_AREA_COUNT = 4;
  
  @:AREA_GAP = random.pickArrayItem(
    list: [
      1
    ]
  );
  
  
  @:AREA_CHANCE = random.pickArrayItem(
    list: [
      33,
      40,
      50,
      65
    ]
  );
  
  
  @:AREA_WIDTH  = random.integer(from:5, to:6);
  @:AREA_HEIGHT = random.integer(from:5, to:6);

  @gridNodes = [];  
  
  @:NORTH = 0;
  @:EAST  = 1;
  @:WEST  = 2;
  @:SOUTH = 3;
  
  map.width  = AREA_WIDTH  * (AREA_SIZE + AREA_GAP*2) + GEN_OFFSET*2;
  map.height = AREA_HEIGHT * (AREA_SIZE + AREA_GAP*2) + GEN_OFFSET*2;
  
  
  
  @:getOpposite::(dir) {
    when(dir == NORTH) SOUTH;
    when(dir == EAST)  WEST;
    when(dir == WEST)  EAST;
    when(dir == SOUTH) NORTH;
    error(detail: 'Not a direction');
  }

  @:getNeighbors ::(x, y) {
    return [
      if (y == 0)       empty else gridNodes[x + (y-1)*AREA_WIDTH],
      if (x == AREA_WIDTH-1)  empty else gridNodes[x+1 + (y)*AREA_WIDTH],
      if (x == 0)       empty else gridNodes[x-1 + (y)*AREA_WIDTH],
      if (y == AREA_HEIGHT-1) empty else gridNodes[x + (y+1)*AREA_WIDTH]
    ]
  }
  
  @:getNeighborsNode ::(node) <- getNeighbors(x:node.x, y:node.y);

  // gets all neighbors connected.
  @:getNeighborsNodeConnected ::(node) {
     @neighbors = getNeighbors(x:node.x, y:node.y);
     foreach(neighbors) ::(dir, neighbor) {
      when(neighbor == empty) empty;
      if (node.waysOpen[dir] != true ||
        neighbor.waysOpen[getOpposite(dir)] != true)
        neighbors[dir] = empty;
     }
     return neighbors;
   }


  @:generateNode ::(x, y) {
    return {
      waysOpen : [
        false,
        false,
        false,
        false
      ],
      x: x,
      y: y
    }
  }
  
  @:isEmpty ::(node) <- 
      node.waysOpen[NORTH] == false &&
      node.waysOpen[EAST]  == false &&
      node.waysOpen[WEST]  == false &&
      node.waysOpen[SOUTH] == false;
  
  @:generateAreaNode ::(x, y) {
    @:node = generateNode(x, y);
    node.area = Area.new(
      x:x * (AREA_SIZE + AREA_GAP*2) + AREA_GAP + GEN_OFFSET, 
      y:y * (AREA_SIZE + AREA_GAP*2) + AREA_GAP + GEN_OFFSET,
      width: AREA_SIZE,
      height: AREA_SIZE
    )
    areas->push(value:node.area);
    node.isArea = true;
    return node;
  }
  
  // generate possible paths from this node x, y
  @:generateWays ::(x, y) {
    @:list = [];
    
    if (x != 0)       list->push(value:WEST);
    if (y != 0)       list->push(value:NORTH);
    if (x != AREA_WIDTH-1)  list->push(value:EAST);
    if (y != AREA_HEIGHT-1) list->push(value:SOUTH);
    return list;  
  }
  
  // generate starting areas and map nodes
  @:areaList = [];
  @iter = 0;
  @alreadyArea = 0;
  for(0, AREA_HEIGHT) ::(y) {
    for(0, AREA_WIDTH) ::(x) {
      areaList[iter] = random.try(percentSuccess:AREA_CHANCE);
      if (areaList[iter])
        alreadyArea += 1;


      iter += 1;
    }
  }
  
  if (alreadyArea < MINIMUM_AREA_COUNT) ::<= {
    for(alreadyArea, MINIMUM_AREA_COUNT) ::(i) {
      areaList[random.integer(from:0, to:AREA_HEIGHT*AREA_WIDTH-1)] = true;
    }
  }
    
  iter = 0;
  for(0, AREA_HEIGHT) ::(y) {
    for(0, AREA_WIDTH) ::(x) {
      @:node = if (areaList[iter]) ::<= {
        @:n = generateAreaNode(x, y);
        // pick 2 directions to be open
        @:list = generateWays(x, y);
        
        
        @:which0 = random.pickArrayItem(list);
        list->remove(key:list->findIndex(value:which0));
        @:which1 = random.pickArrayItem(list);
        
        n.waysOpen[which0] = true;
        n.waysOpen[which1] = true;
        return n;       
      } else  
        generateNode(x, y)
      ;
      

      
      gridNodes[iter] = node;
      iter += 1;
    }
  }
  
  
  // keep making path nodes until all 
  // adjacent nodes that connect to open 
  // directions have a path.
  ::? {
    forever ::{
      @complete = true;
      for(0, AREA_HEIGHT) ::(y) {
        for(0, AREA_WIDTH) ::(x) {
          @:node = gridNodes[x + y*AREA_WIDTH];
          
          when(isEmpty(node)) empty;
          
          
          // else we found a path or area node.
          // need to check if adjacents already have items
          foreach(getNeighbors(x, y))::(dir, neighbor) {
            // only work with open ways.
            when(node.waysOpen[dir] == false) empty;

            // can have empty neighbors on edges
            when(neighbor == empty) empty;

            @:oppositeDir = getOpposite(dir);

            // If already has an emplacement, ensure that 
            // a path is opened between the node and its neighbor.
            when(!isEmpty(node:neighbor)) ::<= {
              if ( node.waysOpen[dir] &&
                !neighbor.waysOpen[oppositeDir]) ::<= {
                neighbor.waysOpen[oppositeDir] = true;
                complete = false;                
              }
              // if it already had it open, no change is needed
            }
            
            neighbor.waysOpen[oppositeDir] = true;
            complete = false;                
            
            // we have an empty node. 
            // Add 1 to 3 openings
            @:openingCount = random.integer(from:0, to:2);
            
            
            match(dir) {
              (NORTH): y -= 1,
              (SOUTH): y += 1,
              (WEST) : x -= 1,
              (EAST) : x += 1
            }
            
            
            @:list = generateWays(x, y);
            for(0, openingCount) ::(i) {
              @:d = random.pickArrayItem(list);
              list->remove(key:list->findIndex(value:d));
              neighbor.waysOpen[d] = true;
            }
          }
        }
      }
      if (complete)
        send();
    }
  }
  
  
  // now, make sure that ALL nodes are connected one way or another
  @:ensureOneGroup = ::{
  
    @groupIndex = 0;
    @groups = [];
    // starting from a node, forms a group of all nodes connected to that node.
    @:makeGroup = ::(initialNode) {
      @:index = groupIndex;
      groupIndex += 1;
      @:stack = [initialNode];
      initialNode.groupIndex = index;
      @:group = [initialNode];
      ::? {
        forever ::{
          when(stack->keycount == 0) send();
          @:n = stack->pop;
          
          foreach(getNeighborsNodeConnected(node:n)) ::(k, v) {
            when (v == empty) empty;
            when (v.groupIndex == index) empty;
            v.groupIndex = index;
            stack->push(value:v);
            group->push(value:v);
          }          
        }
      }
      groups[index] = group;
    }
    
    // Form groups
    @iter = 0;
    for(0, AREA_HEIGHT) ::(y) {
      for(0, AREA_WIDTH) ::(x) {
        @:node = gridNodes[iter];
        iter+= 1;
        when (isEmpty(node)) empty; 
        when (node.groupIndex == empty)        
          makeGroup(initialNode:node);
      }
    }
    
    groups->sort(comparator::(a, b) {
      when(a->keycount < b->keycount) -1;
      when(a->keycount > b->keycount)  1;
      return 0;
    });
    
    // reset indices.
    foreach(groups) ::(index, group) {
      foreach(group) ::(y, member) {
        member.groupIndex = index;
      }
    }
    
    
    @:leader = groups[groups->keycount-1];
    
    @:MERGE__COMPLETE = 0;
    @:MERGE__NEXT = 1;
    @:MERGE__IMPOSSIBLE = 2;
    
    @:merge = ::{
      return ::? {
        @nonLeaderCount = 0;
        @:leaderIndex = leader[0].groupIndex;
        @iter = 0;
        for(0, AREA_HEIGHT) ::(y) {
          for(0, AREA_WIDTH) ::(x) {
            @:node = gridNodes[iter];
            iter += 1;
            when(node.groupIndex == empty) empty; // empty node            
            when(node.groupIndex == leaderIndex) empty;
            nonLeaderCount += 1;
            
            foreach(getNeighborsNode(node)) ::(dir, neighbor){
              when(neighbor == empty) empty;
              if (neighbor.groupIndex == leaderIndex) ::<= {
                // this node touches the leader group. form a connection 
                // and merge all members of node's group into the 
                // leader group
                
                node.waysOpen[dir] = true;
                neighbor.waysOpen[getOpposite(dir)] = true;

                
                @nodeGroup = groups[node.groupIndex];
                groups[node.groupIndex] = empty;
                foreach(nodeGroup) ::(k, v) {
                  v.groupIndex = leaderIndex;
                  groups[leaderIndex]->push(value:v);
                }

                send(message:MERGE__NEXT);
              }
            }
          }  
        }
        
        when(nonLeaderCount == 0) MERGE__COMPLETE;        
        return MERGE__IMPOSSIBLE;  
      }    
    }
    
    // keep merging adjacent groups until either 
    // all groups are merged into the leader group 
    // or a valley is discovered.
    return ::? {
      forever ::{
        match(merge()) {
          (MERGE__COMPLETE): send(message:false),
          (MERGE__NEXT): empty,          
          (MERGE__IMPOSSIBLE): send(message:true)
        }
      }
    }   
  }
  
  
  ::? {
    forever ::{
      @:restart = ensureOneGroup();

      // reset group index
      @iter = 0;
      for(0, AREA_HEIGHT) ::(y) {
        for(0, AREA_WIDTH) ::(x) {
          gridNodes[iter].groupIndex = empty;
          iter += 1;
        }
      }

      when(!restart) send();
      
      // ensureOneGroup failed, meaning there were 
      // some gaps that prevented merging.
      // This case is very rare, but still possible.
      // So, now we can attempt to patch it by filling 
      // a random hole and trying again 

      ::? {
        for(0, AREA_HEIGHT) ::(y) {
          for(0, AREA_WIDTH) ::(x) {
            @node = gridNodes[x + y*AREA_WIDTH];
            when(!isEmpty(node)) empty;
          
            node = generateAreaNode(x, y);
            gridNodes[x + y*AREA_WIDTH] = node;
            
            foreach(getNeighborsNode(node)) ::(dir, neighbor) {
              when(neighbor == empty) empty;
              node.waysOpen[dir] = true;
              neighbor.waysOpen[getOpposite(dir)] = true;
            }            
            send();
          }            
        }
      }
    }
  }
  
  
  
  
  
  // make areas and pathways
  for(0, AREA_HEIGHT) ::(y) {
    for(0, AREA_WIDTH) ::(x) {
      @:node = gridNodes[x + y*AREA_WIDTH];
      
      when(isEmpty(node)) empty;
      
      // areas are boxes
      when(node.isArea) ::<= {
        @:left   = node.area.x;
        @:top  = node.area.y;
        @:width  = node.area.width;
        @:height = node.area.height;
        for(0, width)::(i) {
          map.enableWall(
            x:left + i,
            y:top
          );

          map.enableWall(
            x:left + i,
            y:top + height-1
          );
        }

        for(0, height)::(i) {
          map.enableWall(
            x:left,
            y:top + i
          );

          map.enableWall(
            x:left + width-1,
            y:top + i
          );
        }
        
        // openings
        if (node.waysOpen[NORTH]) map.disableWall(x:left + (width / 2)->floor, y: top);  
        if (node.waysOpen[SOUTH]) map.disableWall(x:left + (width / 2)->floor, y: top + height-1);  
        if (node.waysOpen[EAST])  map.disableWall(x:left + width -1,       y: top + (height / 2)->floor);  
        if (node.waysOpen[WEST])  map.disableWall(x:left,            y: top + (height / 2)->floor);  
      }
      
      // else its a path
      @centerX = x * (AREA_SIZE + AREA_GAP*2) + AREA_GAP + (AREA_SIZE/2)->floor + GEN_OFFSET;
      @centerY = y * (AREA_SIZE + AREA_GAP*2) + AREA_GAP + (AREA_SIZE/2)->floor + GEN_OFFSET;


      //start with the junction

      map.enableWall(
        x:centerX - 1,
        y:centerY - 1
      );      
      map.enableWall(
        x:centerX - 1,
        y:centerY
      );      
      map.enableWall(
        x:centerX - 1,
        y:centerY + 1
      );      

      map.enableWall(
        x:centerX + 1,
        y:centerY - 1
      );      
      map.enableWall(
        x:centerX + 1,
        y:centerY
      );      
      map.enableWall(
        x:centerX + 1,
        y:centerY + 1
      );      

      map.enableWall(
        x:centerX,
        y:centerY + 1
      );      

      map.enableWall(
        x:centerX,
        y:centerY - 1
      ); 
      
      if (node.waysOpen[NORTH] && y > 0) ::<= {
        map.disableWall(x:centerX, y:centerY-1);   

        for(centerY - (AREA_SIZE/2)->floor, centerY-1)::(i) {
          map.enableWall(
            x:centerX-1,
            y:i
          ); 
          map.enableWall(
            x:centerX+1,
            y:i
          ); 
        }

      }
      if (node.waysOpen[SOUTH] && y < AREA_HEIGHT-1) ::<= {
        map.disableWall(x:centerX, y:centerY+1);   

        for(centerY+1, centerY+(AREA_SIZE/2)->floor+1)::(i) {
          map.enableWall(
            x:centerX-1,
            y:i
          ); 
          map.enableWall(
            x:centerX+1,
            y:i
          ); 
        }

      }
      if (node.waysOpen[EAST] && x < AREA_WIDTH-1) ::<= {
        map.disableWall(x:centerX+1, y:centerY);   

        for(centerX+1, centerX+(AREA_SIZE/2)->floor+1)::(i) {
          map.enableWall(
            x:i,
            y:centerY-1
          ); 
          map.enableWall(
            x:i,
            y:centerY+1
          ); 
        }
      }
      if (node.waysOpen[WEST] && x > 0) ::<= {
        map.disableWall(x:centerX-1, y:centerY);   
        
        for(centerX - (AREA_SIZE/2)->floor, centerX-1)::(i) {
          map.enableWall(
            x:i,
            y:centerY-1
          ); 
          map.enableWall(
            x:i,
            y:centerY+1
          ); 
        }        
      }

      
    }
  }
  
  
  // Finally, fill in gaps
  for(0, AREA_HEIGHT) ::(y) {
    for(0, AREA_WIDTH) ::(x) {
      @node = gridNodes[x + y*AREA_WIDTH];

      @:leftNode = x * (AREA_SIZE + AREA_GAP*2) + AREA_GAP + GEN_OFFSET; 
      @:topNode  = y * (AREA_SIZE + AREA_GAP*2) + AREA_GAP + GEN_OFFSET;
      @centerX = leftNode + (AREA_SIZE/2)->floor;
      @centerY = topNode  + (AREA_SIZE/2)->floor;

      
      // the gap to the right and below are covered.
      if (node.waysOpen[SOUTH]) ::<= {

        @:from = topNode + AREA_SIZE;
        @:to   = from + AREA_GAP*2;
        for(from, to) ::(i) {
          map.enableWall(
            x:centerX+1,
            y:i
          ); 
          map.enableWall(
            x:centerX-1,
            y:i
          );           
        }
      }
      
      if (node.waysOpen[EAST]) ::<= {

        @:from = leftNode + AREA_SIZE;
        @:to   = from + AREA_GAP*2;
        for(from, to) ::(i) {
          map.enableWall(
            x:i,
            y:centerY+1
          ); 
          map.enableWall(
            x:i,
            y:centerY-1
          );           
        }
      }      
    }
  }  

  
  map.obscure();  
  return areas;
};



@:DungeonBlock = ::<= {

  @:DIRECTION = {
    NORTH : 0,
    EAST : 1,
    WEST : 2,
    SOUTH : 3
  }

  @:getOpposite::(dir) <-
    match(dir) {
      (DIRECTION.EAST): DIRECTION.WEST,
      (DIRECTION.WEST): DIRECTION.EAST,
      (DIRECTION.NORTH): DIRECTION.SOUTH,
      (DIRECTION.SOUTH): DIRECTION.NORTH
    }
  ;

  @isDirVertical::(dir) <- 
    match(dir) {(DIRECTION.NORTH, DIRECTION.SOUTH):true, default:false};


  
  @:BlockSpace = class(
    define ::(this) {
      @:openings = [
        [],
        [],
        [],
        []
      ];
      
      @w = empty;
      @h = empty;
      @x_ = empty;
      @y_ = empty;
      @area = empty;
      @root;
      @allConnected; // only populated if root.
      @walls;
      this.interface = {
        setup ::(width, height) {
          w = width;
          h = height;
        },
        width : {get ::<- w},
        height : {get ::<- h},
        
        addOpening ::(dir, space) {
          space = space->floor; // just in case.
          @isVert = isDirVertical();
          if (isVert && space < 0 || space >= w)
            error(detail:"Too long.");

          if (!isVert && space < 0 || space >= h)
            error(detail:"Too long.");

          openings[dir][space] = false;
        },
        
        // force placement at 0,0
        anchorRoot ::(x, y) {
          x_ = x;
          y_ = y;
          root = this;
          allConnected = [this];
        },
        
        // places a space.
        // assumed to be adjacent to an existing space with 
        // no overlaps.
        anchor ::(x, y, from) {
          root = from.getRoot();
          x_ = x;
          y_ = y;
        },
        
        // gets the root.
        // the root holds all connected areas.
        getRoot ::<- root,
        
        
        
        // sets whether or not this is an externally recognized area.
        // some places are hallways.
        markAsArea ::(x, y, width, height) {
          // prototype;
          area = {
            x: x,
            y: y,
            width: width,
            height: height
          }
        },
        
        
        getArea ::{
          if (area != empty && area->type != Area.type) ::<= {
            area = Area.new(
              x:x_ + area.x,
              y:y_ + area.y,
              width:area.width,
              height:area.height
            );          
          }
          
          return area;
        },
        
        // gets the openings in that direction
        getOpenings ::(dir) {
          @:opens = [];
          foreach(openings[dir]) ::(k, v) {
            if (v->type == Boolean)
              opens->push(value:k);
          }
          return opens;
        },
        
        occupy ::(dir, space, other) {
          openings[dir][space] = other;
        },
        
        // gets all attached areas. Attached areas 
        // always have a valid XY
        getAllAttached ::{
          when (root == this) allConnected;
          return root.getAllAttached();
        },
        
        x : {get ::<- x_},
        y : {get ::<- y_},
        
        getAllSpan ::{
          @x = 1000;
          @y = 1000;
          @x1 = -1000;
          @y1 = -1000;

          foreach(root.getAllAttached()) ::(k, space) {
            if (space.x < x) x = space.x;
            if (space.y < y) y = space.y;

            if (space.x + space.width > x1) x1 = space.x + space.width;
            if (space.y + space.height > y1) y1 = space.y + space.height;
          }


          if (x < 0 || y < 0)
            error(detail:"Too big");
          return {
            x: x,
            y: y,
            width: x1 - x,
            height: y1 - y,
          };
           
            
        },
        
        setWalls ::(coords) {
          walls = coords;
        },
        
        // determines whether this area (placed) 
        // overlaps with the given rectangle
        overlaps ::(x, y, width, height) {
          @:ra_x0 = x_;
          @:ra_x1 = x_ + w;
          @:ra_y0 = y_;
          @:ra_y1 = y_ + h;
                  
          return
            (ra_x0 < x + width && ra_x1 > x &&
             ra_y0 < y + height && ra_y1 > y)
          ;
        },
        
        // Checks to see if a rectangle would be allowed to be placed
        isPlacementAllowed ::(x, y, width, height) {
          @:all = this.getRoot().getAllAttached();
          return ::? {
            foreach(all) ::(k, space) {
              if (space.overlaps(x, y, width, height))
                send(message:false);
            }
            return true;
          }
        },
        
        // enables wall using the given map
        finalize ::(map) {  
          @localx;
          @localy;
          foreach(walls) ::(k, coor) {
            when(localx == empty)
              localx = coor;
              
            localy = coor;
            
            @:x = x_ + localx;
            @:y = y_ + localy;
            map.enableWall(x, y);
            localx = empty;
          }
        },
        
        
        // Any openings are blocked off with a wall.
        cap ::(map) {
          for(0, 4) ::(dir) {
            foreach(openings[dir]) ::(space, item) {
              when(item->type != Boolean || item == empty) empty; // covered. Good!
              when(dir == DIRECTION.NORTH) ::<= {
                map.enableWall(
                  x: x_ + space,
                  y: y_ 
                );
              }
             
              when(dir == DIRECTION.EAST) ::<= {
                map.enableWall(
                  y: y_ + space,
                  x: x_ + w-1
                );
              }

              when(dir == DIRECTION.WEST) ::<= {
                map.enableWall(
                  y: y_ + space,
                  x: x_
                );
              }

              when(dir == DIRECTION.SOUTH) ::<= {
                map.enableWall(
                  x: x_ + space,
                  y: y_ + h-1
                );
              }
            }
          }
        },
        
        // attempts to place a space next to this space.
        // success is returned.
        placeAdjacent ::(other => BlockSpace.type) {
          
          @:otherWidth = other.width;
          @:otherHeight = other.height;


          
          return ::? {
            // choose a random direction          
            foreach(random.scrambled(list:[DIRECTION.NORTH, DIRECTION.SOUTH, DIRECTION.EAST, DIRECTION.WEST])) ::(k, dir) {
              @:openings = random.scrambled(list:this.getOpenings(dir));
              foreach(openings) ::(k, opening) {
                when(opening == empty) empty;
                // test until we find an opening.
                @:otherOpenings = random.scrambled(list:other.getOpenings(dir:getOpposite(dir)));
                
                foreach(otherOpenings) ::(k, oppositeOpening) {
                  when(opening == empty) empty;

                  @x;
                  @y;
                  
                  if (dir == DIRECTION.WEST) ::<= {
                     x = x_ - otherWidth;
                     y = y_ - oppositeOpening + opening; // aligned entrance
                  } 
                  
                  
                  if (dir == DIRECTION.EAST) ::<= {
                    
                     x = x_ + w;
                     y = y_ - oppositeOpening + opening; // aligned entrance
                  } 

                  if (dir == DIRECTION.NORTH) ::<= {
                    x = x_ - oppositeOpening + opening;
                    y = y_ - otherHeight
                  }

                  
                  if (dir == DIRECTION.SOUTH) ::<= {
                    x = x_ - oppositeOpening + opening;
                    y = y_ + h
                  }
                  
                  when (x == empty || y == empty) empty;
                  
                  
                  // if overlaps with existing placement, give up
                  when(!this.isPlacementAllowed(
                    x, y, width:otherWidth, height:otherHeight
                  )) empty;


                  
                  // else, we made it 
                  other.anchor(x, y, from:this);
                  root.getAllAttached()->push(value:other);
                  
                  // connect
                  this.occupy(dir, space:opening, other);
                  other.occupy(dir:getOpposite(dir), space:oppositeOpening, other:this);


                  // complete
                  send(message:true);       
                }
              }
            }
            
            // couldnt place. failure
            return false;
          }
        }
      }
    }
  );
  
  @areaSpaces_;
  @hallSpaces_;
  @chanceArea_;
  
  @:getASpace = ::{
    when(random.try(percentSuccess:chanceArea_)) random.pickArrayItem(list:areaSpaces_)();
    return random.pickArrayItem(list:hallSpaces_)();
  }
  
  return {
  
    make::(map, mapHint, areaSpaces, hallSpaces, chanceArea) {
    
      areaSpaces_ = areaSpaces;
      hallSpaces_ = hallSpaces;
      chanceArea_ = chanceArea;
    
      @:CENTER_X = 140;
      @:CENTER_Y = 140;
      @:SPACE_COUNT = random.integer(from:10, to:20);//32;
    
      // first, pick an initial location
      @:root = random.pickArrayItem(list:areaSpaces)();
      root.anchorRoot(x:CENTER_X, y:CENTER_Y);
      
      @:areas = [];
      
      for(0, SPACE_COUNT) ::(i) {
        // either area or a hallway
        @:next = getASpace();
        
        // find where it should go and keep trying till it fits.
        @:list = random.scrambled(list:root.getAllAttached());
        ::? {
          foreach(list) ::(k, existing) {
            if (existing.placeAdjacent(other:next))
              send();
          }
        }
        
      }
      
      @:span = root.getAllSpan();
      map.width = span.x + span.width + 80;
      map.height = span.y + span.height + 40;

      
      foreach(root.getAllAttached()) ::(k, space) {
        @:area = space.getArea();
        if (area != empty)
          areas->push(value:area);
        space.finalize(map);
        space.cap(map);
      }

      map.obscure();
      return areas;
    },
    BlockSpace : BlockSpace,
    DIRECTION : DIRECTION
  }
}



// room based 
//@:DungeonGamma ::(map, mapHint) {
@:DungeonAlpha ::(map, mapHint) {
  /*
  @:LAYOUT_MIN_SIZE = 25;
  @:LAYOUT_MAX_SIZE = 30;
  @:LAYOUT_CENTER_OFFSET_MIN = 0.4;
  @:LAYOUT_CENTER_OFFSET_MAX = 0.6;
  @:LAYOUT_NEIGHBOR_DISTANCE = 5;
  @:ROOM_MIN = 4;
  @:ROOM_MAX = 6;
  */
  
  @:LAYOUT_ROOM_SIZE_MIN = 4;
  @:LAYOUT_ROOM_SIZE_MAX = 8;
  @:LAYOUT_ROOM_OFF_SIZE = 7;
  @:LAYOUT_ROOM_OPEN_SIZE_MIN = 3;
  @:LAYOUT_ROOM_OPEN_SIZE_MAX = 10;
  @:LAYOUT_NEIGHBOR_DISTANCE = 5;
  @:LAYOUT_ROOM_COUNT_MIN = 3;
  @:LAYOUT_ROOM_COUNT_MAX = 8;
  
  
  @:ABOVE = 0;
  @:RIGHT = 1;
  @:BELOW = 2;
  @:LEFT  = 3;
  
  
  @:layouts = [];
  @:wallIndex = map.addScenerySymbol(character:'▓');
  @:emptyIndex = map.addScenerySymbol(character:' ');
  @:funnyIndex = map.addScenerySymbol(character:'.');
  
  
  map.width = 200;
  map.height = 200;
  @:mx = (map.width /2)->floor
  @:my = (map.height/2)->floor


  
  // incomplete "complicated" layout. Very messy with little to gain
  
  @:GammaLayout = class(
    name : 'Wyvern.DungeonMap.Gamma.Layout',
    define ::(this) {
      @w;
      @h;
      
      // topleft!
      @x;
      @y;
           
      // horizontal -> 0, vertical -> 1
      @openSide;
      @openArea;
      @rooms;

      @:placeLayout ::{   
        // branch from an existing one
        @:r = random.scrambled(:layouts)[0];
        
        @:facingDir = random.integer(from:ABOVE, to:LEFT);
        match(facingDir) {
          // above
          (ABOVE): ::<= {
            x = r.x;
            y = r.y - (LAYOUT_NEIGHBOR_DISTANCE + r.height);
          },

          // to the right
          (RIGHT): ::<= {
            x = LAYOUT_NEIGHBOR_DISTANCE + r.x + r.width;
            y = r.y;
          },
          
          // below 
          (BELOW): ::<= {
            x = r.x;
            y = LAYOUT_NEIGHBOR_DISTANCE + r.y + r.height;
          },
          
          // to the left
          (LEFT): ::<= {
            x = r.x - (LAYOUT_NEIGHBOR_DISTANCE + r.width);
            y = r.y;
          }
          
        }

      }
      
      @:makeWallPerimeter::(dims) {
        for(dims.y, dims.y + dims.h) ::(yiter) {
          map.setSceneryIndex(x:dims.x, y:yiter, symbol:wallIndex);
          map.enableWall(x:dims.x, y:yiter);


          map.setSceneryIndex(x:dims.x+dims.w, y:yiter, symbol:wallIndex);
          map.enableWall(x:dims.x+dims.w, y:yiter);
        }

        for(dims.x, dims.x + dims.w) ::(xiter) {
          map.setSceneryIndex(y:dims.y, x:xiter, symbol:wallIndex);
          map.enableWall(y:dims.y, x:xiter);


          map.setSceneryIndex(y:dims.y+dims.h, x:xiter, symbol:wallIndex);
          map.enableWall(y:dims.y+dims.h, x:xiter);
        }      


        map.setSceneryIndex(x:dims.x+dims.w, y:dims.y+dims.h, symbol:wallIndex);
        map.enableWall(x:dims.x+dims.w, y:dims.y+dims.h);


      }
      
      @:makeRoom::(dims) {
        @:area = Area.new(
          x: dims.x+1,
          y: dims.y+1,
          width: dims.w-1,
          height: dims.h-1
        );

        // make initial walls
        //area.debug(:map);


        dims.area = area;
        rooms->push(:dims);
        return dims;
      }


      @:makeRoomsSide :: {
        @xiter = x;
        @yiter = y;
        for(0, random.integer(from:LAYOUT_ROOM_COUNT_MIN, to:LAYOUT_ROOM_COUNT_MAX)) ::(i) {

          match(openSide) {
          
            
            (ABOVE, BELOW): ::<= {
              @:dims = makeRoom(:{
                x:xiter, 
                y:y, 
                h:LAYOUT_ROOM_OFF_SIZE, 
                w:random.integer(from:LAYOUT_ROOM_SIZE_MIN, to:LAYOUT_ROOM_SIZE_MAX)
              });
              
              xiter += dims.w;
            },

            (LEFT, RIGHT): ::<= {
              @:dims = makeRoom(:{
                y:yiter, 
                x:x, 
                w:LAYOUT_ROOM_OFF_SIZE, 
                h:random.integer(from:LAYOUT_ROOM_SIZE_MIN, to:LAYOUT_ROOM_SIZE_MAX)
              });
              
              yiter += dims.h;
            }
          }
        }
        
        if (openSide == LEFT || openSide == RIGHT) ::<= {
          h = yiter - y;
          breakpoint();
        } else ::<= {
          w = xiter - x;
        }
      }
      
      @:makeBlankSide ::{
        openArea = match(openSide) {
          (ABOVE): ::<= {
            @:openH = random.integer(from:LAYOUT_ROOM_OPEN_SIZE_MIN, to:LAYOUT_ROOM_OPEN_SIZE_MAX);
            y = y - (openH + 1);
            h = openH + LAYOUT_ROOM_OFF_SIZE + 1;
            
            return Map.Area.new(
              x: x+1,
              y: y+1,
              width: w-1,
              height: openH
            );
          },
          
          (RIGHT): ::<= {
            @:openW = random.integer(from:LAYOUT_ROOM_OPEN_SIZE_MIN, to:LAYOUT_ROOM_OPEN_SIZE_MAX);
            w = LAYOUT_ROOM_OFF_SIZE + openW;
            
            return Map.Area.new(
              x: x+LAYOUT_ROOM_OFF_SIZE+1,
              y: y+1,
              width: openW,
              height: h-1
            );
          
          },
          
          (BELOW): ::<= {
            @:openH = random.integer(from:LAYOUT_ROOM_OPEN_SIZE_MIN, to:LAYOUT_ROOM_OPEN_SIZE_MAX);
            h = openH + LAYOUT_ROOM_OFF_SIZE;
            
            return Map.Area.new(
              x: x+1,
              y: y+LAYOUT_ROOM_OFF_SIZE+1,
              width: w-1,
              height: openH
            );          
          },
          
          (LEFT): ::<= {
            @:openW = random.integer(from:LAYOUT_ROOM_OPEN_SIZE_MIN, to:LAYOUT_ROOM_OPEN_SIZE_MAX);
            w = openW + 1 + LAYOUT_ROOM_OFF_SIZE;
            x = x - openW;
            
            return Map.Area.new(
              x: x+1,
              y: y+1,
              width: openW-1,
              height: h-1
            );          
          }
        }
        
        /*
        makeWallPerimeter(:{
          x: openArea.x-1,
          y: openArea.y-1,
          w: openArea.width+2,
          h: openArea.height+2
        });
        */
        
        //openArea.debug(:map);
        
        
      }

      @:reinit:: {
        w = empty;
        h = empty;
        x = empty;
        y = empty;
             
        // horizontal -> 0, vertical -> 1
        openSide = LEFT;//random.integer(from:ABOVE, to:LEFT);
        openArea = empty;
        rooms = [];      
      }
      
      this.constructor = ::{
        // this is not a good idea! Replace thank you!
        ::? {
          forever :: {
            reinit();

            if (layouts->size == 0) ::<= {
              x = mx;
              y = my;
            } else ::<= {
              placeLayout();
            }

            makeRoomsSide();
            makeBlankSide();
            
            


            if (layouts->size == 0)
              send();
            

            // if it overlaps, try again
            if (!layouts->reduce(::(value, previous) <-
              if (previous == true)
                true
              else 
                value.overlaps(other:this)
            )) ::<= {
              send();
            }
          }
        }
        foreach(rooms) ::(k, v) <- 
          makeWallPerimeter(:v);

        makeWallPerimeter(:{
          x: x,
          y: y,
          w: w,
          h: h
        });
        
        
        layouts->push(:this);        
      };
      
      
      this.interface = {
        x : {
          get ::<- x
        },

        y : {
          get ::<- y
        },

        width : {
          get ::<- w
        },

        height : {
          get ::<- h
        },
        
        areas : {
          get ::<- [...(rooms->map(::(value) <- value.area)), openArea]
        },
        
        overlaps ::(other) {
          @:ra_x0 = x;
          @:ra_x1 = x + w;
          @:ra_y0 = y;
          @:ra_y1 = y + h;
                  
          return
            (ra_x0 < other.x + other.width  && ra_x1 > other.x &&
             ra_y0 < other.y + other.height && ra_y1 > other.y)
          ;
        }
      }
    }
  );




  
  /*
  
  // incomplete "complicated" layout. Very messy with little to gain
  
  @:GammaLayout = class(
    name : 'Wyvern.DungeonMap.Gamma.Layout',
    define ::(this) {
      @w;
      @h;
      
      // topleft!
      @x;
      @y;
      
      // for connecting
      @facingDir;
      
      
      @openArea;
      @:areas = [];


      // make rooms!
      @:populateOpenArea ::{
        // heres the trick: make an "open area"
        // this defines the walls for the rooms in the layout
        
        //@subw = w - random.integer(from:LAYOUT_CENTER_OFFSET_MIN, to:LAYOUT_CENTER_OFFSET_MAX);
        //@subh = h - random.integer(from:LAYOUT_CENTER_OFFSET_MIN, to:LAYOUT_CENTER_OFFSET_MAX);
        
        @subw = (w * random.range(from:LAYOUT_CENTER_OFFSET_MIN, to:LAYOUT_CENTER_OFFSET_MAX))->floor
        @subh = (h * random.range(from:LAYOUT_CENTER_OFFSET_MIN, to:LAYOUT_CENTER_OFFSET_MAX))->floor
        
        @subx = 0;
        @suby = 0;
        
        @hug = random.integer(from:0, to:3);

        match(hug) {
          // hugTopLeft
          (0): ::<= {
            subx = x;
            suby = y;
          },
          
          // hugTopRight 
          (1): ::<= {
            subx = x + (w - subw)->floor;
            suby = y;
          },

          // hugBottomLeft
          (2): ::<= {
            subx = x;
            suby = y + (h - subh)->floor;
          },

          // hugBottomRight
          (3): ::<= {
            subx = x + (w - subw)->floor;
            suby = y + (h - subh)->floor;
          }
        }
        
        if (subx + subw > x + w)
          subw = (x + w) - subx;

        if (suby + subh > y + h)
          subw = (y + h) - suby;
        

        
        openArea = Map.Area.new(
          x : subx,
          y : suby,
          width : subw,
          height : subh
        );

        for(suby, suby + subh) ::(yiter) {
          map.setSceneryIndex(x:subx, y:yiter, symbol:wallIndex);
          map.enableWall(x:subx, y:yiter);


          map.setSceneryIndex(x:subx+subw, y:yiter, symbol:wallIndex);
          map.enableWall(x:subx+subw, y:yiter);
        }

        for(subx, subx + subw) ::(xiter) {
          map.setSceneryIndex(x:xiter, y:suby, symbol:wallIndex);
          map.enableWall(x:xiter, y:suby);


          map.setSceneryIndex(x:xiter, y:suby+subh, symbol:wallIndex);
          map.enableWall(x:xiter, y:suby+subh);
        }
        map.setSceneryIndex(x:subx+subw, y:suby+subh, symbol:wallIndex);
        map.enableWall(x:subx+subw, y:suby+subh);


        // open up walls for eventual "fusion" areas in the corner
        match(hug) {
          // hugTopLeft -> free BottomRight
          (0): ::<= {
            @:hugCornerX = openArea.x + openArea.width;
            @:hugCornerY = openArea.y + openArea.height;

            map.disableWall(x:hugCornerX, y:hugCornerY);
            map.disableWall(x:hugCornerX, y:hugCornerY-1);
            map.disableWall(x:hugCornerX-1, y:hugCornerY);

            map.setSceneryIndex(x:hugCornerX, y:hugCornerY, symbol:emptyIndex);
            map.setSceneryIndex(x:hugCornerX, y:hugCornerY-1, symbol:emptyIndex);
            map.setSceneryIndex(x:hugCornerX-1, y:hugCornerY, symbol:emptyIndex);

          },
          
          // hugTopRight -> freeBottomLeft
          (1): ::<= {
            @:hugCornerX = openArea.x;
            @:hugCornerY = openArea.y + openArea.height;

            map.disableWall(x:hugCornerX, y:hugCornerY);
            map.disableWall(x:hugCornerX, y:hugCornerY-1);
            map.disableWall(x:hugCornerX+1, y:hugCornerY);

            map.setSceneryIndex(x:hugCornerX, y:hugCornerY, symbol:emptyIndex);
            map.setSceneryIndex(x:hugCornerX, y:hugCornerY-1, symbol:emptyIndex);
            map.setSceneryIndex(x:hugCornerX+1, y:hugCornerY, symbol:emptyIndex);

          },

          // hugBottomLeft -> freeTopRight
          (2): ::<= {
            @:hugCornerX = openArea.x + openArea.width;
            @:hugCornerY = openArea.y;

            map.disableWall(x:hugCornerX, y:hugCornerY);
            map.disableWall(x:hugCornerX, y:hugCornerY+1);
            map.disableWall(x:hugCornerX+1, y:hugCornerY);

            map.setSceneryIndex(x:hugCornerX, y:hugCornerY, symbol:emptyIndex);
            map.setSceneryIndex(x:hugCornerX, y:hugCornerY+1, symbol:emptyIndex);
            map.setSceneryIndex(x:hugCornerX+1, y:hugCornerY, symbol:emptyIndex);

          },

          // hugBottomRight -> freeTopLeft
          (3): ::<= {
            @:hugCornerX = openArea.x;
            @:hugCornerY = openArea.y;


            map.disableWall(x:hugCornerX, y:hugCornerY);
            map.disableWall(x:hugCornerX, y:hugCornerY+1);
            map.disableWall(x:hugCornerX+1, y:hugCornerY);

            map.setSceneryIndex(x:hugCornerX, y:hugCornerY, symbol:emptyIndex);
            map.setSceneryIndex(x:hugCornerX, y:hugCornerY+1, symbol:emptyIndex);
            map.setSceneryIndex(x:hugCornerX+1, y:hugCornerY, symbol:emptyIndex);

          }
        }



        areas->push(:openArea);
      }

      @:makeLayoutWall ::{
        for(y, y+h) ::(yiter) {
          map.setSceneryIndex(x, y:yiter, symbol:wallIndex);
          map.enableWall(x, y:yiter);


          map.setSceneryIndex(x:x+w, y:yiter, symbol:wallIndex);
          map.enableWall(x:x+w, y:yiter);

        }

        for(x, x+w) ::(xiter) {
          map.setSceneryIndex(x:xiter, y:y, symbol:wallIndex);
          map.enableWall(x:xiter, y:y);

          map.setSceneryIndex(x:xiter, y:y+h, symbol:wallIndex);
          map.enableWall(x:xiter, y:y+h);

        } 
        map.setSceneryIndex(x:x+w, y:y+h, symbol:wallIndex);
        map.enableWall(x:x+w, y:y+h);


      }


      // initial placement
      @:placeLayout ::{   
        // branch from an existing one
        ::? {
          forever ::{
            @:r = random.scrambled(:layouts)[0];
            
            facingDir = random.integer(from:0, to:3);
            match(facingDir) {
              // above
              (0): ::<= {
                x = r.x;
                y = r.y - (LAYOUT_NEIGHBOR_DISTANCE + h);
              },

              // to the right
              (1): ::<= {
                x = LAYOUT_NEIGHBOR_DISTANCE + r.x + r.width;
                y = r.y;
              },
              
              // below 
              (2): ::<= {
                x = r.x;
                y = LAYOUT_NEIGHBOR_DISTANCE + r.y + r.height;
              },
              
              // to the left
              (3): ::<= {
                x = r.x - (LAYOUT_NEIGHBOR_DISTANCE + r.width);
                y = r.y;
              }
              
            }
            breakpoint();
            // if it overlaps, try again
            if (!layouts->reduce(::(value, previous) <-
              if (previous == true)
                true
              else 
                value.overlaps(other:this)
            )) ::<= {
              // all good! no overlaps :)
              
              // now connect!
              
              send();
            }
          }
        }  
      }
      
      @:populateLayout ::{
        @:getNext ::<- random.integer(from:ROOM_MIN, to:ROOM_MAX);
        
        // left 
        if (openArea.x != x) ::<= {
          @layerLimit = getNext();
          @start = y + h - 1;
          for(y+h, y) ::(yiter) {
            when(layerLimit > 0) ::<= {layerLimit-=1;}

            @:area = Map.Area.new(
              x: x,
              y: yiter,
              height: start - yiter,
              width: openArea.x - x
            );

            start = yiter;
            areas->push(:area);
            
            // make opening
            map.disableWall(x:area.x+area.width, y:area.y+2);
            map.setSceneryIndex(x:area.x+area.width, y:area.y+2, symbol:funnyIndex);
            



            layerLimit = getNext();
            
            // make wall 
            for(x, openArea.x) ::(xiter) {
              map.setSceneryIndex(x:xiter, y:yiter, symbol:wallIndex);
              map.enableWall(x:xiter, y:yiter);
            }
          }
        }
        
        
        
        // right
        if (openArea.x + openArea.width != x + w) ::<= {
          @layerLimit = getNext();
          @start = y;
          for(y, y+h) ::(yiter) {
            when(layerLimit > 0) ::<= {layerLimit-=1;}


            
            @:area = Map.Area.new(
              x: openArea.x + openArea.width,
              y: start,
              height: yiter - start,
              width: (x + w) - (openArea.width+openArea.x)
            );
            start = yiter+1;
            areas->push(:area);
            
            // make opening
            map.disableWall(x:area.x, y:area.y+1);
            map.setSceneryIndex(x:area.x, y:area.y+1, symbol:funnyIndex);
            



            
            layerLimit = getNext();
            
            
            
            // make wall 
            for(openArea.x+openArea.width, x + w) ::(xiter) {
              map.setSceneryIndex(x:xiter, y:yiter, symbol:wallIndex);
              map.enableWall(x:xiter, y:yiter);
            }
          }
        }



        // top
        if (openArea.y != y) ::<= {
          @start = x+w;
          @layerLimit = getNext();
          for(x+w, openArea.x) ::(xiter) {
            when(layerLimit > 0) ::<= {layerLimit-=1;}


            @:area = Map.Area.new(
              x: xiter,
              y: y,
              height: openArea.y - y,
              width: start - xiter
            );
            start = area.x-1;
            areas->push(:area);
            
            // make opening
            map.disableWall(x:area.x+1, y:area.y+area.height);
            map.setSceneryIndex(x:area.x+1, y:area.y+area.height, symbol:funnyIndex);





            layerLimit = getNext();
            
            // make wall 
            for(y, openArea.y) ::(yiter) {
              map.setSceneryIndex(x:xiter, y:yiter, symbol:wallIndex);
              map.enableWall(x:xiter, y:yiter);
            }
          }
        }

        // bottom
        if (openArea.y + openArea.height != y + h) ::<= {
          @start = openArea.x+1;
          @layerLimit = getNext();
          for(openArea.x, openArea.x + openArea.width) ::(xiter) {
            when(layerLimit > 0) ::<= {layerLimit-=1;};


            @:area = Map.Area.new(
              x: start,
              y: openArea.y + openArea.height,
              height: (y + h) - (openArea.height + openArea.y),
              width: xiter - start
            );
            start = xiter+1;
            areas->push(:area);
            
            // make opening
            map.disableWall(x:area.x+1, y:area.y);
            map.setSceneryIndex(x:area.x+1, y:area.y, symbol:funnyIndex);




            layerLimit = getNext();
            
            // make wall 
            for(openArea.y+openArea.height, y + h) ::(yiter) {
              map.setSceneryIndex(x:xiter, y:yiter, symbol:wallIndex);
              map.enableWall(x:xiter, y:yiter);
            }
          }
        }

      }
      
      this.constructor = ::{
        for(0, 1) ::{random.number();}
      
        w = random.integer(from:LAYOUT_MIN_SIZE, to:LAYOUT_MAX_SIZE);
        h = random.integer(from:LAYOUT_MIN_SIZE, to:LAYOUT_MAX_SIZE);

        if (layouts->size == 0) ::<= {
          x = mx;
          y = my;
        } else ::<= {
          placeLayout();
        }
        
        layouts->push(:this);        
        makeLayoutWall();
        populateOpenArea();
        populateLayout();
        
        // debug 
      };
      
      
      this.interface = {
        x : {
          get ::<- x
        },

        y : {
          get ::<- y
        },

        width : {
          get ::<- w
        },

        height : {
          get ::<- w
        },
        
        areas : {
          get ::<- areas
        },
        
        overlaps ::(other) {
          @:ra_x0 = x;
          @:ra_x1 = x + w;
          @:ra_y0 = y;
          @:ra_y1 = y + h;
                  
          return
            (ra_x0 < other.x + other.width  && ra_x1 > other.x &&
             ra_y0 < other.y + other.height && ra_y1 > other.y)
          ;
        }
      }
    }
  );
  */



  //map.obscure();  
  @allAreas = [];
  for(0, 2) ::(i) {
    allAreas = [...allAreas, ...GammaLayout.new().areas]
  }

  return allAreas;
}



@:DungeonZeta = ::<= {
  
  // true area layouts.
  // Only these can be anchors
  @:areaSpaces = [
    ::<= {
      @:coords = [
        0, 0, 1, 0, 2, 0,   4, 0, 5, 0, 6, 0,
        0, 1, 1, 1,         5, 1, 6, 1,
        0, 2,               6, 2,

        0, 4,               6, 4,
        0, 5, 1, 5,         5, 5, 6, 5,
        0, 6, 1, 6, 2, 6,   4, 6, 5, 6, 6, 6,
      ];
      return ::{
        @:area = DungeonBlock.BlockSpace.new();
        area.setup(width:7, height:7);
        area.addOpening(dir:DungeonBlock.DIRECTION.WEST, space:3);
        area.addOpening(dir:DungeonBlock.DIRECTION.EAST, space:3);
        area.addOpening(dir:DungeonBlock.DIRECTION.NORTH, space:3);
        area.addOpening(dir:DungeonBlock.DIRECTION.SOUTH, space:3);
        area.setWalls(coords);
        area.markAsArea(
          x:2,
          y:2,
          width:3,
          height:3
        );
        return area;
      }
    }  
  
  ]

  // transient spaces
  @:hallSpaces = [
   
    ::<= {
      @:coords = [
                  3, 0,     5, 0,
            1, 1, 2, 1, 3, 1,     5, 1, 6, 1, 7, 1,
            1, 2,                 7, 2,
        0, 3, 1, 3,                 7, 3, 8, 3,
                    4, 4,  
        0, 5, 1, 5,                 7, 5, 8, 5,
            1, 6,                 7, 6,
            1, 7, 2, 7, 3, 7,     5, 7, 6, 7, 7, 7,
                  3, 8,     5, 8

      ];
      return ::{
        @:hall = DungeonBlock.BlockSpace.new();
        hall.setup(width:9, height:9);
        hall.addOpening(dir:DungeonBlock.DIRECTION.WEST, space:4);
        hall.addOpening(dir:DungeonBlock.DIRECTION.EAST, space:4);
        hall.addOpening(dir:DungeonBlock.DIRECTION.NORTH, space:4);
        hall.addOpening(dir:DungeonBlock.DIRECTION.SOUTH, space:4);
        hall.setWalls(coords);
        return hall;
      }
    },
    
    
    ::<= {
      @:coords = [
              2, 0, 3, 0,     5, 0, 6, 0,
            1, 1, 2, 1,           6, 1, 7, 1, 
        0, 2, 1, 2,                 7, 2, 8, 2,
        0, 3,                       8, 3,
        0, 4,                       8, 4,
        0, 5,                       8, 5,
        0, 6,                       8, 6,
        0, 7,           4, 7,           8, 7,
        0, 8,       3, 8, 4, 8, 5, 8,       8, 8,
        0, 9,     2, 9, 3, 9,     5, 9, 6, 9,     8, 9
      ];
      
      return ::{
        @:hall = DungeonBlock.BlockSpace.new();
        hall.setup(width:9, height:10);
        hall.addOpening(dir:DungeonBlock.DIRECTION.NORTH, space:4);
        hall.addOpening(dir:DungeonBlock.DIRECTION.SOUTH, space:7);
        hall.addOpening(dir:DungeonBlock.DIRECTION.SOUTH, space:1);
        hall.setWalls(coords);
        return hall;
      }
    },
    

    ::<= {
      @:coords = [
        0, 0,     2, 0, 3, 0,     5, 0, 6, 0,     8, 0,
        0, 1,       3, 1, 4, 1, 5, 1,       8, 1,
        0, 2,           4, 2,           8, 2,
        0, 3,                       8, 3,
        0, 4,                       8, 4,
        0, 5,                       8, 5,
        0, 6,                       8, 6,
        0, 7, 1, 7,                 7, 7, 8, 7,
            1, 8, 2, 8,           6, 8, 7, 8, 
              2, 9, 3, 9,     5, 9, 6, 9,
      ];
      
      return ::{
        @:hall = DungeonBlock.BlockSpace.new();
        hall.setup(width:9, height:10);
        hall.addOpening(dir:DungeonBlock.DIRECTION.SOUTH, space:4);
        hall.addOpening(dir:DungeonBlock.DIRECTION.NORTH, space:7);
        hall.addOpening(dir:DungeonBlock.DIRECTION.NORTH, space:1);
        hall.setWalls(coords);
        return hall;
      }
    },
    
    ::<= {
      @:coords = [
        0, 0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0,
                              7, 1, 8, 1,
        0, 2,                       8, 2, 9, 2,
        0, 3, 1, 3,                       9, 3,
            1, 4, 2, 4,
        0, 5, 1, 5,                       9, 5,
        0, 6,                       8, 6, 9, 6,
                              7, 7, 8, 7,
        0, 8, 1, 8, 2, 8, 3, 8, 4, 8, 5, 8, 6, 8, 7, 8
      ];
      
      return ::{
        @:hall = DungeonBlock.BlockSpace.new();
        hall.setup(width:10, height:9);
        hall.addOpening(dir:DungeonBlock.DIRECTION.EAST, space:4);
        hall.addOpening(dir:DungeonBlock.DIRECTION.WEST, space:7);
        hall.addOpening(dir:DungeonBlock.DIRECTION.WEST, space:1);
        hall.setWalls(coords);
        return hall;
      }
    },        


    ::<= {
      @:coords = [
              2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8, 0, 9, 0,
            1, 1, 2, 1,             
        0, 2, 1, 2,                       9, 2,
        0, 3,                       8, 3, 9, 3,
                              7, 4, 8, 4,
        0, 5,                       8, 5, 9, 5,
        0, 6, 1, 6,                       9, 6,
            1, 7, 2, 7,             
              2, 8, 3, 8, 4, 8, 5, 8, 6, 8, 7, 8, 8, 8, 9, 8

      ];
      
      return ::{
        @:hall = DungeonBlock.BlockSpace.new();
        hall.setup(width:10, height:9);
        hall.addOpening(dir:DungeonBlock.DIRECTION.WEST, space:4);
        hall.addOpening(dir:DungeonBlock.DIRECTION.EAST, space:7);
        hall.addOpening(dir:DungeonBlock.DIRECTION.EAST, space:1);
        hall.setWalls(coords);
        return hall;
      }
    },        

    
  ];


  return ::(map, mapHint) {
    return DungeonBlock.make(
      map, 
      mapHint,
      areaSpaces,
      hallSpaces,
      chanceArea: 70
    );
  }
}




@:LAYOUT_ALPHA = 0;
@:LAYOUT_BETA = 1;
@:LAYOUT_GAMMA = 2;
@:LAYOUT_DELTA = 3;
@:LAYOUT_CUSTOM = 4;
@:LAYOUT_EPSILON = 5;
@:LAYOUT_ZETA = 6;
@:DungeonMap = class(
  name: 'Wyvern.DungeonMap',
  define:::(this) {
  
    @:layoutToAreas ::(layout, map, mapHint){
      return match(layout) {
        (LAYOUT_ALPHA):  DungeonAlpha(map:map, mapHint),
        (LAYOUT_BETA):   DungeonBeta(map:map, mapHint),
        (LAYOUT_GAMMA):  DungeonGamma(map:map, mapHint),
        (LAYOUT_DELTA):
          match(random.integer(from:0, to:2)) {
            (0): DungeonAlpha(map:map, mapHint),
            (1): DungeonBeta(map:map, mapHint),
            (2): DungeonGamma(map:map, mapHint)
          },
        (LAYOUT_EPSILON): ::<= {
          @:world = import(module:'game_singleton.world.mt');            
          return match(world.island.tier) {
            (0): layoutToAreas(layout:LAYOUT_ALPHA, map, mapHint),
            (1): layoutToAreas(layout:LAYOUT_BETA, map, mapHint),
            (2): layoutToAreas(layout:LAYOUT_GAMMA, map, mapHint),
            default: layoutToAreas(layout:LAYOUT_DELTA, map, mapHint)
          }
        },

          
          
        default:
          DungeonAlpha(map:map, mapHint)
      }    
    }
  
    this.interface = {
      LAYOUT_ALPHA   : {get::<- LAYOUT_ALPHA},  
      LAYOUT_BETA  : {get::<- LAYOUT_BETA},  
      LAYOUT_GAMMA   : {get::<- LAYOUT_GAMMA},
      LAYOUT_DELTA   : {get::<- LAYOUT_DELTA},  
      LAYOUT_EPSILON : {get::<- LAYOUT_EPSILON},  
      LAYOUT_CUSTOM  : {get::<- LAYOUT_CUSTOM},


      create ::(mapHint, parent) {
        @:map = Map.new(parent);

        @areas;

        map.paged = false;
        map.renderOutOfBounds = true;
        map.outOfBoundsCharacter = '`';

        if (mapHint.wallCharacter != empty) map.wallCharacter = mapHint.wallCharacter;
        if (mapHint.outOfBoundsCharacter != empty) map.outOfBoundsCharacter = mapHint.outOfBoundsCharacter;
        
        areas = layoutToAreas(layout:mapHint.layoutType, map, mapHint);
        foreach(areas) ::(k, v) {
          map.addArea(area:v);
        }
        return map;
      }
    } 
  }
);
return DungeonMap.new();
