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
@:canvas = import(module:'singleton.canvas.mt');
@:class = import(module:'Matte.Core.Class');



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
@:mapSizeH  = 16;



@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
};


return class(
    name: 'Wyvern.MapBase',


  
    define:::(this) {
        @:itemIndex = [];
        @:entities = [];
        @:wallIndex = [];
        @:items = [];
        @:legendEntries = [];
        @title;

        @pointer = {
            x: 0,
            y: 0,
            discovered : true,
            symbol: 'P',
            name: "(Party)"
        };

        @width;
        @height;
        @offsetX = 0;
        @offsetY = 0;
        @drawLegend = false;
        @paged = true;
        
        @:isWalled ::(x, y) {
            when(wallIndex->keycount == 0) false;
            @wallY = wallIndex[x];
            when(wallY == empty) false;
            return wallY[y] == true;
        };

        @:aStarHeuristicH::(from, to) <-
            distance(x0:from.x, y0:from.y, x1:to.x, y1:to.y);
        ;

        @:aStarMapEmplace::(map, key, value) {
            map[''+key.x+'-'+key.y] = value;
        };
        @:aStarMapFind::(map, key) {
            return map[''+key.x+'-'+key.y];
        };
        @:aStarMapRemove::(map, key) {
            map->remove(key:''+key.x+'-'+key.y);
        };


        @:aStarReconstructPath::(cameFrom, current) {
            @:total_path = [current];
            return [::] {
                forever(do:::{
                    @:contains = aStarMapFind(map:cameFrom, key:current);
                    when(contains == empty) send(message:total_path);
                    current = contains;
                    total_path->insert(at:0, value:current);        
                });
            };
        };


        @:aStartFindLowestFscore::(fScore, openSet) {
            @lowestVal = THE_BIG_ONE;
            @lowest = empty;
            openSet->foreach(do:::(key, set) {
                @:val = aStarMapFind(map:fScore, key:set);
                if (val < lowestVal) ::<= {
                    lowestVal = val;
                    lowest = set;
                };
            });
            
            return lowest;
        };

        @:aStarGetNeighbors::(current) {
            return [
                {x:current.x-1, y:current.y  },
                {x:current.x-1, y:current.y+1},
                {x:current.x-1, y:current.y-1},
                {x:current.x+1, y:current.y  },
                {x:current.x+1, y:current.y+1},
                {x:current.x+1, y:current.y-1},
                {x:current.x  , y:current.y+1},
                {x:current.x  , y:current.y-1}
            ]->filter(by::(value) <- !isWalled(x:value.x, y:value.y));
        };
        
        @:aStarGetScore::(value) <- if (value == empty) THE_BIG_ONE else value;
        

        // A* finds a path from start to goal.
        // h is the heuristic function. h(n) estimates the cost to reach goal from node n.
        @:aStar::(start, goal) {
            // The set of discovered nodes that may need to be (re-)expanded.
            // Initially, only the start node is known.
            // This is usually implemented as a min-heap or priority queue rather than a hash-set.
            @openSet = {};
            aStarMapEmplace(map:openSet, key:start, value:start);

            // For node n, cameFrom[n] is the node immediately preceding it on the cheapest path from the start
            // to n currently known.
            @cameFrom = {};

            // For node n, gScore[n] is the cost of the cheapest path from start to n currently known.
            @gScore = {};
            aStarMapEmplace(map:gScore, key:start, value:0);

            // For node n, fScore[n] := gScore[n] + h(n). fScore[n] represents our current best guess as to
            // how cheap a path could be from start to finish if it goes through n.
            @fScore = {};
            aStarMapEmplace(map:fScore, key:start, value:aStarHeuristicH(from:start, to:goal));

            @path;
            
            return [::] {
                forever(do:::{
                    // return empty: open set is empty but goal was never reached
                    when(openSet->keycount == 0) send();
                
                    // This operation can occur in O(Log(N)) time if openSet is a min-heap or a priority queue
                    
                    @current = aStartFindLowestFscore(fScore, openSet);
                    if (current.x == goal.x && current.y == goal.y) ::<= {
                        send(message:aStarReconstructPath(cameFrom, current));
                        
                    };

                    aStarMapRemove(map:openSet, key:current);
                    aStarGetNeighbors(current)->foreach(do:::(i, neighbor) {
                        // d(current,neighbor) is the weight of the edge from current to neighbor
                        // tentative_gScore is the distance from start to the neighbor through current
                        @:tentative_gScore = aStarGetScore(value:aStarMapFind(map:gScore, key:current)) + 1;//d(current, neighbor)
                        if (tentative_gScore < aStarGetScore(value:aStarMapFind(map:gScore, key:neighbor))) ::<= {
                            // This path to neighbor is better than any previous one. Record it!
                            aStarMapEmplace(map:cameFrom, key:neighbor, value:current);
                            aStarMapEmplace(map:gScore, key:neighbor, value:tentative_gScore);
                            aStarMapEmplace(map:fScore, key:neighbor, value:tentative_gScore + aStarHeuristicH(from:neighbor, to:goal));
                            if (aStarMapFind(map:openSet, key:neighbor) == empty)
                                aStarMapEmplace(map:openSet, key:neighbor, value:neighbor);
                        };
                    });
                });
            };
        };
        
        
        @:renderPaged ::{
            
            
            @:left = canvas.width/2 - mapSizeW/2;
            @:top = canvas.height/2 - mapSizeH/2;
            canvas.renderFrame(
                left:left-1,
                top:top-1,
                width: mapSizeW+3,
                height: mapSizeH+3                   
            
            );
            


            @:regionX = ((pointer.x+0) / mapSizeW)->floor;
            @:regionY = ((pointer.y+0) / mapSizeH)->floor;


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
            
            
            
            [0, mapSizeH+1]->for(do:::(y) {
                [0, mapSizeW+1]->for(do:::(x) {
                    @itemX = (x) + regionX*mapSizeW;
                    @itemY = (y) + regionY*mapSizeH;
                    
                    
                    when(isWalled(x:itemX, y:itemY)) ::<= {
                        canvas.movePen(x:left + x, y:top + y);  
                        canvas.drawChar(text:'░');
                    };
                    
                    @:items = this.itemsAt(x:itemX, y:itemY);
                    when(items != empty) ::<= {
                        canvas.movePen(x:left + x, y:top + y);
                        canvas.drawChar(text:if (items[0].discovered) items[0].symbol else '?');
                    };
                    
                    when(itemX < 0 || itemY < 0 || itemX >= width+0 || itemY >= height+0) ::<= {
                        canvas.movePen(x:left + x, y:top + y);  
                        canvas.drawChar(text:'▓');
                    };
                    canvas.movePen(x:left + x, y:top + y);  
                    canvas.drawChar(text:' ');
                });                
            });                
                            

            
  
            canvas.movePen(
                x:left + ((pointer.x - regionX*mapSizeW))->floor,
                y:top  + ((pointer.y - regionY*mapSizeH))->floor         
            );
            
            canvas.drawText(text:'P');
                    
        };
        
        @:renderUnpaged ::{
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
            
            //@:map = [...scenery, ...items->values, ...walls];
            /*
            scenery->foreach(do:::(item, data) {
                @itemX = ((data.x - regionX) * mapSizeW)->floor;
                @itemY = ((data.y - regionY) * mapSizeH)->floor;
            
                when(itemX < 1 || itemY < 1 || itemX >= mapSizeW || itemY >= mapSizeH) empty;
                canvas.movePen(x:left-1 + itemX, y:top-1 + itemY);  
                canvas.drawText(text:data.symbol);
            });*/
            /*
            map->foreach(do:::(item, data) {
                @itemX = ((data.x - pointer.x + mapSizeW/2))->floor;
                @itemY = ((data.y - pointer.y + mapSizeH/2))->floor;
            
                when(itemX < 1 || itemY < 1 || itemX >= mapSizeW || itemY > mapSizeH) empty;
                canvas.movePen(x:left-1 + itemX, y:top + itemY);  
                canvas.drawText(text:data.symbol);
            });*/
            
            [0, mapSizeH+1]->for(do:::(y) {
                [0, mapSizeW+1]->for(do:::(x) {
                    @itemX = ((x + pointer.x - mapSizeW/2))->floor;
                    @itemY = ((y + pointer.y - mapSizeH/2))->floor;

                    when(isWalled(x:itemX, y:itemY)) ::<= {
                        canvas.movePen(x:left + x, y:top + y);  
                        canvas.drawChar(text:'░');
                    };
                    @:items = this.itemsAt(x:itemX, y:itemY);
                    when(items != empty) ::<= {
                        canvas.movePen(x:left + x, y:top + y);
                        canvas.drawChar(text:if (items[0].discovered) items[0].symbol else '?');
                    };
                    
                    when(itemX < offsetX || itemY < offsetY || itemX >= width+offsetX || itemY >= height+offsetY) ::<= {
                        canvas.movePen(x:left + x, y:top + y);  
                        canvas.drawChar(text:'▓');
                    };
                });                
            });               
            
            
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
                x:left + (mapSizeW/2)->floor - 1,
                y:top  + (mapSizeH/2)->floor         
            );
            
            canvas.drawText(text:'P');
                    
        };

        @:retrieveItem = ::(data) {
            return items->filter(by:::(value) <- value.data == data)[0];
        };


        this.interface = {
            
            width : {
                get ::<- width,
                set ::(value) <- width = value
            },

            height : {
                get ::<- height,
                set ::(value) <- height = value
            },
            
            drawLegend : {
                get ::<- drawLegend,
                set ::(value) <- drawLegend = value
            },

            addWall ::(x, y) {
                when(x < 0 || y < 0) empty;
                @v = wallIndex[x];
                if (v == empty) ::<={
                    v = [];
                    wallIndex[x] = v;
                };
                v[y] = true;                
            },
            
            removeWall ::(x, y) {        
                @xval = wallIndex[x];
                when(xval == empty) empty;
                xval[y] = false;
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
                
                when(x < 0 || x > width || y < 0 || y > height)
                    error(detail:'Bad\n');
                
                @itemIndexY = itemIndex[x];
                if (itemIndexY == empty) ::<= {
                    itemIndexY = [];
                    itemIndex[x] = itemIndexY;
                };
                @loc = itemIndexY[y];
                if (loc == empty) ::<= {
                    loc = [];
                    itemIndexY[y] = loc;
                };
                @:val = {
                    x: x,
                    y: y,
                    symbol : symbol,
                    discovered : discovered,
                    data: data,
                    name: name
                };
                loc->push(value:val);
                items->push(value:val);
                if (name != empty)
                    legendEntries->push(value:val);
            },
            
            itemsAt::(x, y) {
                @itemY = itemIndex[x];
                when(itemY == empty) empty;
                return itemY[y];
            },
                
            removeItem::(
                data
            ) {
                @item = retrieveItem(data);
            
                @itemY = itemIndex[item.x];
                when(itemY == empty) empty;
                @items = itemY[item.y];
                [::] {
                    items->foreach(do:::(key, v) {
                        when(v.data == data) ::<= {
                            items->remove(key);
                            send();
                        };
                    });
                };
                if (item.name != empty) ::<= {
                    [::] {
                        legendEntries->foreach(do:::(key, v) {
                            when(v.data == data) ::<= {
                                legendEntries->remove(key);
                                send();
                            };
                        });
                    };
                };


                if(items->keycount == 0)
                    itemY[item.y] = empty;    
                    
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
                x = x->floor;
                y = y->floor;
                when(x < 0 || x > width || y < 0 || y > height)
                    error(detail:'Bad');


                pointer.x = x;
                pointer.y = y;
            },
            
            getDistanceFromItem ::(data) {
                @:item = retrieveItem(data);
                return distance(x0:pointer.x, y0:pointer.y, x1:item.x, y1:item.y);
            },
            
            movePointerToward::(x, y) {
                // direct linear path
                when(wallIndex->keycount == 0) ::<= {
                    @xdiff = if (x - pointer.x > 0) 1 else -1;
                    @ydiff = if (y - pointer.y > 0) 1 else -1;
                    if (xdiff->abs < 1) xdiff = 0;
                    if (ydiff->abs < 1) ydiff = 0;
                    this.movePointerAdjacent(
                        x: xdiff,
                        y: ydiff
                    );
                };  
                @:path = aStar(start:pointer, goal:{x:x, y:y});                
                when(path == empty || path->keycount <= 1) empty;
                pointer.x = path[1].x;
                pointer.y = path[1].y;
                
            },

            moveTowardPointer::(data) {
                this.moveTowardPoint(data, x:pointer.x, y:pointer.y);
            },

            moveTowardPoint::(data, x, y) {
                @:ent = retrieveItem(data);            
                when(wallIndex->keycount == 0) ::<= {
                    @xdiff = if (x - ent.x > 0) 1 else -1;
                    @ydiff = if (y - ent.y > 0) 1 else -1;
                    if (xdiff->abs < 1) xdiff = 0;
                    if (ydiff->abs < 1) ydiff = 0;
                    ent.x += xdiff;
                    ent.y += ydiff;
                };  
            
                @:path = aStar(start:ent, goal:{x:x, y:y});
                when(path == empty || path->keycount <= 1) empty;
                ent.x = path[1].x;
                ent.y = path[1].y;
            },

            
            
            pointerX : {
                get ::<- pointer.x
            },
            
            pointerY : {
                get ::<- pointer.y            
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
                
                @:oldX = pointer.x;
                @:oldY = pointer.y;



                pointer.x += x;
                pointer.y += y;

                if (pointer.x < 0) pointer.x  = 0;
                if (pointer.y < 0) pointer.y  = 0;
                if (pointer.x >= width) pointer.x  = width-1;
                if (pointer.y >= height) pointer.y  = height-1;

                if (isWalled(x:pointer.x, y:pointer.y)) ::<= {
                    pointer.x = oldX;
                    pointer.y = oldY;
                };                  
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
                [pointer.x - (radius / 2)->floor, pointer.x + (radius / 2)->ceil]->for(do:::(x) {
                    [pointer.y - (radius / 2)->floor, pointer.y + (radius / 2)->ceil]->for(do:::(y) {
                        @:at = this.itemsAt(x, y);
                        when(at == empty) empty;
                        at->foreach(do:::(key, value) {
                            out->push(value);
                        });
                    });
                });
                
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
            
            render :: {
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
                    legendEntries->foreach(do:::(index, item) {
                        
                        @:val = if(item.discovered) 
                            '' + item.symbol + ' ' + if (item.name == '') item.name else item.name
                        else 
                            '? ????'
                        ;
                        itemList->push(value:val);
                        if (width < val->length)
                            width = val->length;
                    }); 
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
                    itemList->foreach(do:::(index, item) {
                        canvas.movePen(x:2, y:index+2);
                        canvas.drawText(text:item);
                    });
                        
                };



                @:world = import(module:'singleton.world.mt');
                // render the time under the map.
                canvas.movePen(x:left -1, y: 0);
                canvas.drawText(text:world.timeString + '                   ');
                
                canvas.commit();            
            
            }
        };    
    }
);
