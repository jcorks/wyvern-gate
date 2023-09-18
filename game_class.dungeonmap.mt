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



@:EPSILON = 0.000001;

@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
}

@:BIG = 100000000;

@:GEN_OFFSET = 20;


@Area = class(
    name: 'Wyvern.DungeonMap.Area',
    define::(this) {
        @_x;
        @_y;
        @_w;
        @_h;
        @items = {};
        
        this.interface = {
            setup::(x, y, width, height) {
                _x = x => Number;
                _y = y => Number;
                _w = width => Number;
                _h = height => Number;
                return this;
            },
            
            x : {get::<-_x},        
            y : {get::<-_y},        
            width : {get::<-_w},        
            height : {get::<-_h},
            items : {get::<-items}      
        }
    }
);



@:DungeonAlpha = ::(map, mapHint) {
    @cavities = [];
    @:areas = [];
    
    @ROOM_AREA_SIZE = random.integer(from:4, to:7); // was 5
    @ROOM_AREA_SIZE_LARGE = random.integer(from:4, to:9);// was 9
    @ROOM_AREA_VARIANCE = random.integer(from:1, to: 3)*0.2; // was 0.2
    @ROOM_SIZE = random.integer(from:35, to:45); //50;
    @ROOM_EMPTY_AREA_COUNT = random.integer(from:12, to: 18); //13;
    ;
    

    @:generateArea ::(item) {
        @width  = if (Number.random() > 0.5) ROOM_AREA_SIZE else ROOM_AREA_SIZE_LARGE;
        @height = width;
        width  *= 1 + Number.random() * 0.2;
        height *= 1 + Number.random() * 0.2;
    
        width = width->floor;
        height = height->floor;
    
        @left = (item.x - width/2  + width  * (Number.random() * 0.4 - 0.2))->floor;
        @top  = (item.y - height/2 + height * (Number.random() * 0.4 - 0.2))->floor;
        


        if (left < 0) left = GEN_OFFSET;
        if (left + width +2 >= (ROOM_SIZE+GEN_OFFSET)-1) left = (ROOM_SIZE+GEN_OFFSET) - width - 3;
        if (top < 0) top = GEN_OFFSET;
        if (top + height +2 >= (ROOM_SIZE+GEN_OFFSET)-1) top = (ROOM_SIZE+GEN_OFFSET) - height - 3;
        

        areas->push(value: Area.new().setup(
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
            @ax = (a.x + (Number.random() - 0.5)*0.5 * a.width + a.width/2)->floor;
            @ay = (a.y + (Number.random() - 0.5)*0.5 * a.height + a.height/2)->floor;

            @bx = (b.x + (Number.random() - 0.5)*0.5 * b.width + b.width/2)->floor;
            @by = (b.y + (Number.random() - 0.5)*0.5 * b.height + b.height/2)->floor;


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
                x: (ROOM_SIZE * Number.random())->floor,
                y: (ROOM_SIZE * Number.random())->floor
            );
        });*/
                
    
        
        for(0, ROOM_EMPTY_AREA_COUNT)::(i) {
            generateArea(
                item:{
                    x:(Number.random()*ROOM_SIZE)->floor + GEN_OFFSET, 
                    y:(Number.random()*ROOM_SIZE)->floor + GEN_OFFSET
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
    
    @:AREA_SIZE = random.pickArrayItem(
        list: [
            7, 9, 11
        ]
    );
    
    @:AREA_GAP = random.pickArrayItem(
        list: [
            1, 2, 3
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
    
    
    @:AREA_WIDTH  = random.integer(from:5, to:8);
    @:AREA_HEIGHT = random.integer(from:5, to:8);

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
            if (y == 0)             empty else gridNodes[x + (y-1)*AREA_WIDTH],
            if (x == AREA_WIDTH-1)  empty else gridNodes[x+1 + (y)*AREA_WIDTH],
            if (x == 0)             empty else gridNodes[x-1 + (y)*AREA_WIDTH],
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
        node.area = Area.new().setup(
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
        
        if (x != 0)             list->push(value:WEST);
        if (y != 0)             list->push(value:NORTH);
        if (x != AREA_WIDTH-1)  list->push(value:EAST);
        if (y != AREA_HEIGHT-1) list->push(value:SOUTH);
        return list;    
    }
    
    // generate starting areas and map nodes
    for(0, AREA_HEIGHT) ::(y) {
        for(0, AREA_WIDTH) ::(x) {
            @:node = if (random.try(percentSuccess:AREA_CHANCE)) ::<= {
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
            

            
            gridNodes[x + y*AREA_WIDTH] = node;
        }
    }
    
    
    // keep making path nodes until all 
    // adjacent nodes that connect to open 
    // directions have a path.
    {:::} {
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
            {:::} {
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
            return {:::} {
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
        return {:::} {
            forever ::{
                match(merge()) {
                  (MERGE__COMPLETE): send(message:false),
                  (MERGE__NEXT): empty,                  
                  (MERGE__IMPOSSIBLE): send(message:true)
                }
            }
        }   
    }
    
    
    {:::} {
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

            {:::} {
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
                @:top    = node.area.y;
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
                if (node.waysOpen[EAST])  map.disableWall(x:left + width -1,           y: top + (height / 2)->floor);    
                if (node.waysOpen[WEST])  map.disableWall(x:left,                      y: top + (height / 2)->floor);    
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
            
            if (node.waysOpen[NORTH]) ::<= {
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
            if (node.waysOpen[SOUTH]) ::<= {
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
            if (node.waysOpen[EAST]) ::<= {
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
            if (node.waysOpen[WEST]) ::<= {
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














@:DungeonMap = class(
    name: 'Wyvern.DungeonMap',
    new ::(mapHint => Object) {
        @:this = DungeonMap.defaultNew();
        this.initialize(mapHint);
        return this;
    },
    inherits:[import(module:'game_class.mapbase.mt')],
    statics : {
        LAYOUT_ALPHA : {get::<- 0},  
        LAYOUT_BETA  : {get::<- 1},  
        LAYOUT_DELTA : {get::<- 2},  
        LAYOUT_GAMMA : {get::<- 3},
        LAYOUT_CUSTOM: {get::<- 4}  
},
    
    define:::(this) {

        @areas = [];

        @:putArea = ::<= {
          @:tryMap = [
                [0, 0],
                [-1, -1],
                [1, -1],
                [-1, 0],
                [0, -1],
                [1, 0],
                [1, 1],
                [0, 1],
                [-1, 1],
                [-2, 1],
                [-2, 0],
                [-2, -1],
                [-2, -2],
                [-1, -2],
                [0, -2],
                [1, -2],
                [2, -2],
                [2, -1],
                [2, 0],
                [2, 1],
                [2, 2]
            ];
            return ::(area, item, symbol, name) {
                area.items->push(value:item);
                {:::} {                
                    @iter = 0;
                    forever ::{
                        @:offset = tryMap[iter];
                        iter += 1;
                        @location = {
                            x: (area.x + area.width/2 + offset[0]*2)->floor,
                            y: (area.y + area.height/2 + offset[1]*2)->floor
                        }                

                        @:already = this.itemsAt(x:location.x, y:location.y);
                        when(already != empty && already->keycount) empty;
                        item.x = location.x;
                        item.y = location.y;

                        this.setItem(data:item, x:location.x, y:location.y, symbol, discovered:true, name);



                        send();
                    }      
                }          
            }
        }


        
        this.interface = {
            initialize ::(mapHint) {



                this.paged = false;
                this.renderOutOfBounds = true;
                this.outOfBoundsCharacter = '`';

                if (mapHint.wallCharacter != empty) this.wallCharacter = mapHint.wallCharacter;
                if (mapHint.outOfBoundsCharacter != empty) this.outOfBoundsCharacter = mapHint.outOfBoundsCharacter;
                match(mapHint.layoutType) {
                    (DungeonMap.LAYOUT_ALPHA): areas = DungeonAlpha(map:this, mapHint),
                    (DungeonMap.LAYOUT_BETA): areas = DungeonBeta(map:this, mapHint),
                    default:
                        areas = DungeonAlpha(map:this, mapHint)
                }
                return this;
            },
        
            areas : {
                get ::<- areas
            },
            
            addToRandomArea ::(item, symbol, name) {
                return putArea(
                    area: random.pickArrayItem(list:areas),
                    item,
                    symbol,
                    name
                );
            },
            
            addToRandomEmptyArea ::(item, symbol, name) {
                @areasEmpty = [...areas]->filter(by::(value) <- value.items->keycount == 0);
                when (areasEmpty->keycount == 0)
                    this.addToRandomArea(item, symbol, name)

                return putArea(
                    area: random.pickArrayItem(list:areasEmpty),
                    item,
                    symbol,
                    name
                );
            },
            
            getRandomEmptyArea :: {
                @areasEmpty = [...areas]->filter(by::(value) <- value.items->keycount == 0);
                when (areasEmpty->keycount == 0)
                    random.pickArrayItem(list:areas);
                    
                return random.pickArrayItem(list:areasEmpty);
            },
            
            getRandomArea :: {
                return random.pickArrayItem(list:areas);
            }            
        
        } 
    }
);
return DungeonMap;
