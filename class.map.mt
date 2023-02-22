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


@:mapSizeW  = 28;
@:mapSizeH  = 16;

@:EPSILON = 0.000001;

@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
};


return class(
    name: 'Wyvern.Map',


  
    define:::(this) {
        @:items = {};
        @pointer = {
            x: 0,
            y: 0,
            discovered : true
        };
        @title = '';
        @size = 1;
        @:distanceFrom::(item) {
            return distance(x0:pointer.x, y0:pointer.y, x1:item.x, y1:item.y);
        };


        this.interface = {
            state : {
                set ::(value) {
                    pointer = value.pointer;
                    title = value.title;
                    size = value.size;
                },
                get :: {
                    // set assumes items have all ready been set.
                    return {
                        pointer : pointer,
                        title : title,
                        size : size
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
                towards,
                units
            ) {
                if (distanceFrom(item:towards) < 1) ::<= {
                    pointer.x = towards.x;
                    pointer.y = towards.y;                            
                } else ::<= {
                    @xd = towards.x - pointer.x;
                    @yd = towards.y - pointer.y;
                    @:mag = (xd**2 + yd**2)**0.5;
                    
                    xd /= mag;
                    yd /= mag;
                    
                    pointer.x += xd;
                    pointer.y += yd;
                };                
            },
            
            getItemUnderPointer :: {
                return [::] {
                    items->foreach(do:::(item, data) {
                        if (distanceFrom(item) < EPSILON)
                            send(message:item);                        
                    });
                    
                    // implicit but ok
                    return empty;
                };
            },
            
            size : {
                get ::<- size,
                set ::(value) <- size = value
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
                
                @map = {};
                items->foreach(do:::(item, data) {
                    map[item] = {
                        x:((data.x / size) * mapSizeW)->floor,
                        y:((data.y / size) * mapSizeH)->floor
                    };
                });


                
                
                @:lines = [];
                
                @:renderCellChar ::(x, y) {
                    return [::] {
                        map->foreach(do:::(item, cell) {
                            @data = items[item];
                            if (data == empty) data = pointer;
                            if (cell.x == x && cell.y == y) ::<= {
                                send(message: if (item.discovered) data.symbol else '?' );
                            };
                        });
                        return ' ';
                    };
                };
                
                
                canvas.movePen(x:left-1, y:top-1);
                canvas.drawText(text:title);
                [0, mapSizeH]->for(do:::(y) {
                    @line = '';
                    [0, mapSizeW]->for(do:::(x) {
                        line = line + renderCellChar(x, y);
                    });
                    canvas.movePen(x:left + 1, y:top + y);
                    canvas.drawText(text:line);
                }); 

                canvas.movePen(
                    x:left +     ((pointer.x / size) * mapSizeW)->floor,
                    y:top  +     ((pointer.y / size) * mapSizeH)->floor                
                );
                
                canvas.drawText(text:'(P)');
                
                
                
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
