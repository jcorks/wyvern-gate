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
@:mapSizeW  = 50;
@:mapSizeH  = 18;
@:SIGHT_RAY_LIMIT = 6;
@:SIGHT_RAY_EPSILON = 0.4;


@:SETTINGS_MASK    = 0x110000;
@:IS_WALLED_MASK   = 0x010000;
@:IS_OBSCURED_MASK = 0x100000;


@:distance = import(module:'game_function.distance.mt');


return class(
    name: 'Wyvern.MapBase',


  
    define:::(this) {
        @:itemIndex = [];
        @:entities = [];
        @:items = [];
        @:legendEntries = [];
        @title;

        @pointer = {
            x: 0,
            y: 0,
            discovered : true,
            symbol: 'P',
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
        

        
        @:isWalled ::(x, y) {
            @at = x+y*width;
            return (scenery[at] & IS_WALLED_MASK) != 0;
        }
        
        @renderOutOfBounds = true;
        @isDark = false;

        @:aStarHeuristicH::(from, to) <-
            distance(x0:from.x, y0:from.y, x1:to.x, y1:to.y)
        ;

        @:aStarMapEmplace::(map, key, value) {
            //when(map.index[key.id] != empty) empty;
            map.index[String(from:key.id)] = value;
            //map.list->push(value:value);
        }
        @:aStarMapFind::(map, key) {
            return map.index[String(from:key.id)];
        }
        @:aStarMapRemove::(map, key) {
            map.index->remove(key:String(from:key.id));
            //map.list->remove(key:map->findIndex(value:key));
        }
        @:aStarMapNew :: {
            return {
                //list: [],
                index: []
            }
        }
        
        @:aStarPQNew :: {
            return [];
        }


        @:aStarReconstructPath::(cameFrom, current, start) {
            @:path = [];
            return {:::} {
                forever ::{
                    path->push(value:current);
                    @:contains = aStarMapFind(map:cameFrom, key:current);
                    when(contains.id == start.id) send(message:path);
                    current = contains;
                }
            }
        }


        @:aStarFindLowestFscore::(fScore, openSet) {
            return aStarPQGetFirst(pq:openSet);
        }

        @:aStarNewNode::(x, y) {
            when (!isWalled(x, y) && x >= 0 && y >= 0 && x < width && y < height)
                {x:x, y:y, id:x + y*width}
        }

        @:aStarGetNeighbors::(current) {
            return [
                aStarNewNode(x:current.x-1, y:current.y),
                aStarNewNode(x:current.x-1, y:current.y+1),
                aStarNewNode(x:current.x-1, y:current.y-1),
                aStarNewNode(x:current.x+1, y:current.y  ),
                aStarNewNode(x:current.x+1, y:current.y+1),
                aStarNewNode(x:current.x+1, y:current.y-1),
                aStarNewNode(x:current.x  , y:current.y+1),
                aStarNewNode(x:current.x  , y:current.y-1)
            ]->filter(by::(value) <- value != empty);
        }
        
        @:aStarGetScore::(value) <- if (value == empty) THE_BIG_ONE else value;
        

        @aStarPQCompareTable;


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
            return {:::} {
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
        @:aStarPath::(start, goal) {        
            start = aStarNewNode(x:start.x, y:start.y);
            goal = aStarNewNode(x:goal.x, y:goal.y);
            
            when(start.id == goal.id) empty;
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
            
            return {:::} {
                forever ::{
                    // return empty: open set is empty but goal was never reached
                    when(openSet->keycount == 0) send();
                
                    // This operation can occur in O(Log(N)) time if openSet is a min-heap or a priority queue
                    @current = openSet[0];
                    //@current = aStarFindLowestFscore(fScore, openSet);
                    if (current.id == goal.id) ::<= {
                        @out = aStarReconstructPath(cameFrom, current, start);
                        send(message:out);
                        
                    }
                    openSet->remove(key:0);
                    foreach(aStarGetNeighbors(current))::(i, neighbor) {
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
        
        
        @:bfsPathNext::(start, goal) {
            start = aStarNewNode(x:start.x, y:start.y);
            goal = aStarNewNode(x:goal.x, y:goal.y);
            
            when(start.id == goal.id) empty;
            @:q = [];
            @:visited = {}
            visited[start.id] = true;
            q->push(value:start);
            
            return {:::} {
                forever ::{
                    when(q->keycount == 0) empty;
                    
                    @v = q[0];
                    q->remove(key:0);


                    when(v.id == goal.id) ::<= {
                        // build path
                        send(message: ::<={
                            return {:::} {
                                @a = v;
                                @last;
                                forever ::{
                                    when(a.parent.id == start.id) ::<= {
                                        
                                        
                                        send(message:a);                
                                    }                
                                    a = a.parent; 
                                }
                            }
                        })
                    }

                    foreach(aStarGetNeighbors(current:v))::(i, w) {
                        when(visited[w.id] == true) empty;
                        
                        visited[w.id] = true;
                        w.parent = v;
                        q->push(value:w);
                    }

                
                }
            }
        }
        
        
        @:renderPaged ::{
            
            
            @:left = canvas.width/2 - mapSizeW/2;
            @:top = canvas.height/2 - mapSizeH/2;
            canvas.renderFrame(
                left:left-1,
                top:top-1,
                width: mapSizeW+3,
                height: mapSizeH+3                   
            
            );
            


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
                        canvas.drawChar(text:if (items[items->keycount-1].discovered) items[items->keycount-1].symbol else '?');
                    }

                    when (symbol != empty) ::<= {
                        canvas.drawChar(text:symbol);
                    }


                    canvas.drawChar(text:' ');
                }                
            }              
                            

            
  
            canvas.movePen(
                x:left + ((pointer.x - regionX*mapSizeW  + mapSizeW*0.5))->floor,
                y:top  + ((pointer.y - regionY*mapSizeH  + mapSizeH*0.5))->floor         
            );
            
            canvas.drawText(text:'P');
                    
        }
        
        @:renderUnpaged ::{
            //@:Time = import(module:'Matte.System.Time');
            //@:ticks = Time.getTicks();
            @:left = canvas.width/2 - mapSizeW/2;
            @:top = canvas.height/2 - mapSizeH/2;
            canvas.renderFrame(
                left:left-1,
                top:top-1,
                width: mapSizeW+3,
                height: mapSizeH+3
            );

            @:centerX = (mapSizeW / 2)->floor;
            @:centerY = (mapSizeH / 2)->floor;
            
            
            
            
            @:sightRay ::(degrees) {
                @x = pointer.x + 0.5;
                @y = pointer.y + 0.5;
                @:rads = (Number.PI() / 180)*degrees;
                {:::} {
                    forever ::{
                        x += rads->cos * SIGHT_RAY_EPSILON;
                        y += rads->sin * SIGHT_RAY_EPSILON;
                        

                        when((x < offsetX || y < offsetY || x >= width+offsetX || y >= height+offsetY)) send();

                        when(distance(x0:pointer.x, y0:pointer.y, x1:x, y1:y) > SIGHT_RAY_LIMIT) send();
                        scenery[x->floor+y->floor*width] &= ~IS_OBSCURED_MASK;                        
                        if (isWalled(x:x->floor, y:y->floor))
                            send();
                    }
                }
            }
            

            {:::} {
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
                    //    if (distance(x0:pointer.x, y0:pointer.y, x1:itemX, y1:itemY) < 5)
                    //        obscured[itemX][itemY] = false;
                    
                    when(scenery[itemX+itemY*width] & IS_OBSCURED_MASK) ::<= {
                        canvas.drawChar(text:outOfBoundsCharacter);                        
                    }


                    when(symbol == empty && isWalled(x:itemX, y:itemY)) ::<= {
                        canvas.drawChar(text:wallCharacter);
                    }

                    when(items != empty && items->keycount > 0) ::<= {
                        canvas.drawChar(text:if (items[0].discovered) items[0].symbol else '?');
                    }                    


                    when (symbol != empty) ::<= {
                        canvas.drawChar(text:symbol);
                    }
                }             
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
            
            canvas.drawText(text:'P');
            //canvas.debugLine = 'Frame took ' + (Time.getTicks() - ticks) + 'ms';
                    
        }

        @:retrieveItem = ::(data) {
            return items->filter(by:::(value) <- value.data == data)[0];
        }


        this.interface = {
            
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
                @:index = scenery[at] & (~SETTINGS_MASK);
                when(index == 0) empty;
                return sceneryValues[index-1];
            },



            setItem::(
                data,
                x,
                y,
                symbol,
                discovered,
                name
            ) {
                x = x->floor;
                y = y->floor;
                
                when(x < 0 || y < 0 || x >= width || y >= height)
                    error(detail:'Bad\n');
                
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
                    name: name
                }
                loc->push(value:val);
                items->push(value:val);
                if (name != empty)
                    legendEntries->push(value:val);
            },
            
            getItem::(data) {
                return retrieveItem(data);
            },
            
            itemsAt::(x, y) {
                return itemIndex[x + y*(width)];
            },
            
            obscure::{
            
                for(0, width)::(x) {
                    for(0, height)::(y) {
                        scenery[x+y*width] |= IS_OBSCURED_MASK;
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
            
                @items = itemIndex[item.x + (item.y)*(width)];
                when(items == empty) empty;
                {:::} {
                    foreach(items)::(key, v) {
                        when(v.data == data) ::<= {
                            items->remove(key);
                            send();
                        }
                    }
                }
                if (item.name != empty) ::<= {
                    {:::} {
                        foreach(legendEntries)::(key, v) {
                            when(v.data == data) ::<= {
                                legendEntries->remove(key);
                                send();
                            }
                        }
                    }
                }


                if(items->keycount == 0)
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

            moveTowardPointer::(data) {
                @:path = this.getPathTo(data, x:pointer.x, y:pointer.y);
                when(path == empty || path->keycount == 0) empty;
                this.moveItem(
                    data, 
                    x:path[path->keycount-1].x,
                    y:path[path->keycount-1].y
                )
            },

            getPathTo::(data, x, y) {
                @:ent = retrieveItem(data);            

                @:path = aStarPath(start:ent, goal:{x:x, y:y});
                when(path == empty || path->keycount == 0) empty;
                return path;
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
                this.movePointerFree(
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

                if(changeX) ::<= {
                    @offset = x;
                    @old = pointer.x;
                    @new = offset + old;
                    y = pointer.y;

                    if (new < 0) new = 0;
                    if (new >= width) new = width-1;

                    @greater = new > old;

                    {:::} {
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
                    if (new >= width) new = width-1;

                    @greater = new > old;

                    {:::} {
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
            
            },
            
            
            paged : {
                get ::<- paged,
                set ::(value) <- paged = value
            },
            
            
            getItemsUnderPointer :: {
                return this.itemsAt(x:pointer.x, y:pointer.y);
            },

            getItemsUnderPointerRadius ::(radius) {
                @out = [];
                for(pointer.x - (radius / 2)->floor, pointer.x + (radius / 2)->ceil)::(x) {
                    for(pointer.y - (radius / 2)->floor, pointer.y + (radius / 2)->ceil)::(y) {
                        @:at = this.itemsAt(x, y);
                        when(at == empty) empty;
                        foreach(at)::(key, value) {
                            out->push(value);
                        }
                    }
                }
                
                return out;     
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
                    @camTop    = camY - mapSizeH/2;
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
                    itemList->push(value:'');
                    itemList->push(value:'P (Party)');
                    if (width < 'P (Party)'->length)
                        width = 'P (Party)'->length;
                    
                    
                    canvas.renderFrame(
                        top: 0,
                        left: 0,
                        width: width+4,
                        height: itemList->keycount+4
                    );
                    
                    canvas.movePen(x:0, y:0);
                    canvas.drawText(text:'Legend');
                    foreach(itemList)::(index, item) {
                        canvas.movePen(x:2, y:index+2);
                        canvas.drawText(text:item);
                    }
                        
                }



                @:world = import(module:'game_singleton.world.mt');
                // render the time under the map.
                canvas.movePen(x:left -1, y: 0);
                canvas.drawText(text:title);
                
            
            }
        }    
    }
);
