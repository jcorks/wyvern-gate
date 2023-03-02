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


@:mapSizeW  = 38;
@:mapSizeH  = 16;

@:EPSILON = 0.000001;

@:distance::(x0, y0, x1, y1) {
    @xd = x1 - x0;
    @yd = y1 - y0;
    return (xd**2 + yd**2)**0.5;
};


@:generateTerrain::(width, height) {
    @:out = {};
    [0, width*height*4]->for(do:::(i) {
        out->push(value:{
            x: Number.random() * width,
            y: Number.random() * height,
            symbol: random.pickArrayItem(list:['╿', '.', '`', '^', '░'])
        });
    });


    [0, width*height*4]->for(do:::(i) {
        out->push(value:{
            x: 0,
            y: Number.random() * height,
            symbol: '▓'
        });
    });

    [0, width*height*4]->for(do:::(i) {
        out->push(value:{
            x: width,
            y: Number.random() * height,
            symbol: '▓'
        });
    });

    [0, width*height*4]->for(do:::(i) {
        out->push(value:{
            x: Number.random()*width,
            y: 0,
            symbol: '▓'
        });
    });

    [0, width*height*4]->for(do:::(i) {
        out->push(value:{
            x: Number.random()*width,
            y: height,
            symbol: '▓'
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
        @width = 1;
        @height = 1;
        @x;
        @y;
        @:distanceFrom::(item) {
            return distance(x0:pointer.x, y0:pointer.y, x1:item.x, y1:item.y);
        };

        this.constructor = ::(state, sizeW, sizeH) {
            when (state) ::<= {
                this.state = state;
                return this;
            };
            
            width = sizeW;
            height = sizeH;
            x = Number.random()*2;
            y = Number.random()*2;
            
            
            scenery = generateTerrain(width, height);
            return this;
                    
        };


        this.interface = {
            state : {
                set ::(value) {
                    pointer = value.pointer;
                    title = value.title;
                    width = value.width;
                    height = value.height;
                    x = value.x;
                    y = value.y;
                    scenery = value.scenery;
                },
                get :: {
                    // set assumes items have all ready been set.
                    return {
                        pointer : pointer,
                        title : title,
                        width: width,
                        height: height,
                        x : x,
                        y : y,
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
                if (pointer.x > width) pointer.x  = width;
                if (pointer.y > height) pointer.y  = height;
                         
            },
            
            getItemUnderPointer :: {
                return [::] {
                    items->foreach(do:::(item, data) {
                        if (distanceFrom(item:data) < 0.125)
                            send(message:item);
                    });
                    
                    // implicit but ok
                    return empty;
                };
            },
            
            width : {
                get ::<- width
            },
            height : {
                get ::<- height
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
                


                @:regionX = (pointer.x+x)->floor;
                @:regionY = (pointer.y+y)->floor;


                @:centerX = (mapSizeW / 2)->floor;
                @:centerY = (mapSizeH / 2)->floor;
                
                @:map = [...scenery, ...items->values];
                /*
                scenery->foreach(do:::(item, data) {
                    @itemX = ((data.x - regionX) * mapSizeW)->floor;
                    @itemY = ((data.y - regionY) * mapSizeH)->floor;
                
                    when(itemX < 1 || itemY < 1 || itemX >= mapSizeW || itemY >= mapSizeH) empty;
                    canvas.movePen(x:left-1 + itemX, y:top-1 + itemY);  
                    canvas.drawText(text:data.symbol);
                });*/
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
                @offsetX = x;
                @offsetY = y;
                [0, mapSizeH+1]->for(do:::(y) {
                    [0, mapSizeW+1]->for(do:::(x) {
                        @itemX = (((x) / mapSizeW) + regionX);
                        @itemY = (((y) / mapSizeH) + regionY);
                        
                        when(itemX < offsetX || itemY < offsetY || itemX >= width+offsetX || itemY >= height+offsetY) ::<= {
                            canvas.movePen(x:left + x, y:top + y);  
                            canvas.drawChar(text:'▓');
                        };
                    });                
                });                
                                
 
                
      
                canvas.movePen(
                    x:left + ((pointer.x - regionX+offsetX) * mapSizeW)->floor,
                    y:top  + ((pointer.y - regionY+offsetY) * mapSizeH)->floor         
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
