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
@:random = import(module:'singleton.random.mt');


@:mapSizeW  = 28;
@:mapSizeH  = 16;

@:EPSILON = 0.000001;

@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
};


@:generateTerrain::(size) {
    @:out = {};
    [0, 60]->for(do:::(i) {
        out->push(value:{
            x: Number.random() * size,
            y: Number.random() * size,
            symbol: random.pickArrayItem(list:[',', '.', '`', '^'])
        });
    });
    
    @xIncr = 1 / mapSizeW;
    @yIncr = 1 / mapSizeH;
    
    [0, 10]->for(do:::(i) {
        @nextset = {};
        out->foreach(do:::(n, val) {
            when(Number.random() < 0.5) empty;
            @:choice = (Number.random() * 4)->floor;
            
            nextset->push(value:{
                x: if (choice == 1) val.x+xIncr else if (choice == 2) val.x-xIncr else val.x,
                y: if (choice == 3) val.y+yIncr else if (choice == 0) val.y-yIncr else val.y,
                symbol: val.symbol
            });
        });
        
        nextset->foreach(do:::(n, val) <- out->push(value:val));
    });
    return out;
};

return class(
    name: 'Wyvern.LargeMap',


  
    define:::(this) {
        @:items = {};
        @scenery = [];
        @pointer = {
            x: 0,
            y: 0,
            discovered : true
        };
        @title = '';
        @size_ = 1;
        @:distanceFrom::(item) {
            return distance(x0:pointer.x, y0:pointer.y, x1:item.x, y1:item.y);
        };

        this.constructor = ::(state, size) {
            when (state) ::<= {
                this.state = state;
                return this;
            };
            
            size_ = size;
            
            
            scenery = generateTerrain(size);
            return this;
                    
        };


        this.interface = {
            state : {
                set ::(value) {
                    pointer = value.pointer;
                    title = value.title;
                    size_ = value.size;
                    scenery = value.scenery;
                },
                get :: {
                    // set assumes items have all ready been set.
                    return {
                        pointer : pointer,
                        title : title,
                        size : size_,
                        scenery : scenery
                    };
                }
            },
        
            setItem::(
                object,
                x,
                y,
                symbol
            ) {
                items[object] = {
                    x: x,
                    y: y,
                    symbol : symbol                    
                };
            },
            
            title : {
                set ::(value) <- title = value
            },
            
            setPointer::(
                x,
                y
            ) {
                pointer.x = x;
                pointer.y = y;
                pointer.symbol = 'P';
                pointer.name = "(Party)";
            },
            
            getDistanceFromItem ::(item) {
                return distanceFrom(item);
            },
            
            pointerX : {
                get ::<- pointer.x
            },
            
            pointerY : {
                get ::<- pointer.y            
            },
            
            movePointer::(
                x,
                y
            ) {
                pointer.x += x;
                pointer.y += y;
                
                if (pointer.x < 0) pointer.x  = 0;
                if (pointer.y < 0) pointer.y  = 0;
                if (pointer.x > size_) pointer.x  = size_;
                if (pointer.y > size_) pointer.y  = size_;
                         
            },
            
            getItemUnderPointer :: {
                return [::] {
                    items->foreach(do:::(item, data) {
                        if (distanceFrom(item:data) < 0.1)
                            send(message:item);
                    });
                    
                    // implicit but ok
                    return empty;
                };
            },
            
            size : {
                get ::<- size_
            },
            
            items : {
            
                get :: <- items
            },
            
            render ::  {
            
                
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
                
                
                @map = [...scenery, ...items->values];
                map->foreach(do:::(item, data) {
                    @itemX = centerX + ((data.x - pointer.x) * mapSizeW)->floor;
                    @itemY = centerY + ((data.y - pointer.y) * mapSizeH)->floor;
                
                    when(itemX < 1 || itemY < 1 || itemX >= mapSizeW || itemY >= mapSizeH) empty;
                    canvas.movePen(x:left-1 + itemX, y:top-1 + itemY);  
                    canvas.drawText(text:data.symbol);
                });
                
                [0, mapSizeH+1]->for(do:::(y) {
                    [0, mapSizeW+1]->for(do:::(x) {
                        @itemX = (((x - (mapSizeW/2)->floor) / mapSizeW) + pointer.x);
                        @itemY = (((y - (mapSizeH/2)->floor) / mapSizeH) + pointer.y);
                        
                        when(itemX < 0 || itemY < 0 || itemX >= size_ || itemY >= size_) ::<= {
                            canvas.movePen(x:left + x, y:top + y);  
                            canvas.drawChar(text:'~');
                        };
                    });                
                });                
                                
 
                

  
                canvas.movePen(
                    x:left + (mapSizeW / 2)->floor,
                    y:top  + (mapSizeH / 2)->floor                
                );
                
                canvas.drawText(text:'P');
                
                

                
                // render the legend
                ::<= {
                    @width = 0;
                    @:itemList = [];
                    items->foreach(do:::(item, data) {
                        @:val = if(item.discovered) 
                            '' + data.symbol + ' ' + if (item.name == '') item.base.name else item.name
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
