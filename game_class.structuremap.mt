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
@windowEvent = import(module:'game_singleton.windowevent.mt');
@:Map = import(module:'game_class.map.mt');


@:EPSILON = 0.000001;

@:distance::(x0, y0, x1, y1) {
  @xd = x1 - x0;
  @yd = y1 - y0;
  return (xd**2 + yd**2)**0.5;
}

@:BIG = 100000000;

@:NORTH = 0;
@:EAST  = 1;
@:WEST  = 2;
@:SOUTH = 3;


@:ZONE_BUILDING_MINIMUM_WIDTH  = 6;
@:ZONE_BUILDING_MINIMUM_HEIGHT = 5;
@:ZONE_MINIMUM_SPAN = 2;
@:ZONE_MAXIMUM_SPAN  = 5;
@:STRUCTURE_MAP_STARTING_X = 100;
@:STRUCTURE_MAP_STARTING_Y = 100;
@:STRUCTURE_MAP_SIZE = 200;
@:ZONE_CONTENT_PADDING = 2;
@:STRUCTURE_MAP_FILLER_MINIMUM_RATE = 0.8;
@:STRUCTURE_MAP_PADDING = 20;


@Zone = class(
  name: 'Wyvern.StructureMap.Zone',
  define::(this) {
    @_x;
    @_y;
    @_w;
    @_h;
    @_map;
    @_category;
    @_topDeco;
    @_bottomDeco;
    @_landmark;
    @unitsWide;
    @unitsHigh;
    @gateSide = random.integer(from:NORTH, to:SOUTH);
    
    @slots = [];
    @freeSpaces = [];
    @blockSceneryIndex;
    
    @:addBuildingBlock::(x, y) {
      _map.enableWall(x, y);
      _map.setSceneryIndex(x, y, symbol:blockSceneryIndex);
    }
    @:addBuildingBlockTop::(x, y) {
      _map.enableWall(x, y);
      _map.setSceneryIndex(x, y, symbol:_topDeco);
    }
    @:addBuildingBlockBottom::(x, y) {
      _map.enableWall(x, y);
      _map.setSceneryIndex(x, y, symbol:_bottomDeco);
    }

    @:addLocations::(name, locationLeft, locationRight, x, y) {
      locationLeft.x = x;
      locationLeft.y = y;

      locationRight.x = x+1;
      locationRight.y = y;

      @:locationMarker = Location.new(
        landmark: _landmark,
        base: Location.database.find(:'base:sign')
      );
      
      locationMarker.name = name;
      locationMarker.x = x;
      locationMarker.y = y;
      _landmark.addLocation(location:locationMarker, traits : Map.TRAIT.DISCOVERED, width:2, height:1);        
     
      _landmark.addLocation(location:locationLeft, traits : Map.TRAIT.DISCOVERED);
      _landmark.addLocation(location:locationRight, traits : Map.TRAIT.DISCOVERED);        
    
    }
    
    
    @:getSpaceBySlot::(x, y) {
      return freeSpaces[freeSpaces->findIndexCondition(::(value) <- value.x == x && value.y == y)];
    }   
    
    // adds a minimally-sized building
    @:addMinimalBuilding ::(name, left, top, symbol, locationLeft, locationRight) {
      /*   
        |  |
        xxxx
        x$$x
        x  x
      
      */
      addBuildingBlockTop(x:left + 1, y: top + 1);
      addBuildingBlockTop(x:left + 4, y: top + 1);

      addBuildingBlock(x:left + 1, y: top + 2);
      addBuildingBlock(x:left + 2, y: top + 2);
      addBuildingBlock(x:left + 3, y: top + 2);
      addBuildingBlock(x:left + 4, y: top + 2);

      addBuildingBlock(x:left + 1, y: top + 3);
      addBuildingBlock(x:left + 2, y: top + 3);
      addBuildingBlock(x:left + 3, y: top + 3);
      addBuildingBlock(x:left + 4, y: top + 3);


      addBuildingBlockBottom(x:left + 1, y: top + 4);
      addBuildingBlockBottom(x:left + 4, y: top + 4);

      if (symbol != empty) ::<= {
        @:index = _map.addScenerySymbol(character:symbol);
        _map.setSceneryIndex(x:left + 2, y: top + 3, symbol:index);
        _map.setSceneryIndex(x:left + 3, y: top + 3, symbol:index);
      }
      
      
      addLocations(name, locationLeft, locationRight, x:left + 2, y: top + 4);
      /*
      locationLeft.x = left + 2;
      locationLeft.y = top + 4;

      locationRight.x = left + 3;
      locationRight.y = top + 4;

     
      _landmark.addLocation(location:locationLeft, traits : Map.TRAIT.DISCOVERED);
      _landmark.addLocation(location:locationRight, traits : Map.TRAIT.DISCOVERED);        
      */

    }  
    
    
    
    // adds a non-functioning decoration
    @:addDecoration ::(left, top, symbol, location) {
      random.pickArrayItem(list:[
          // pokemon style
          /*   
            x  x
            xxxx
            xxxx
            xxxx
          
          */

        /*
        ::{
          addBuildingBlockTop(x:left + 1, y: top + 1);
          addBuildingBlockTop(x:left + 4, y: top + 1);

          addBuildingBlock(x:left + 1, y: top + 2);
          addBuildingBlock(x:left + 2, y: top + 2);
          addBuildingBlock(x:left + 3, y: top + 2);
          addBuildingBlock(x:left + 4, y: top + 2);

          addBuildingBlock(x:left + 1, y: top + 3);
          addBuildingBlock(x:left + 2, y: top + 3);
          addBuildingBlock(x:left + 3, y: top + 3);
          addBuildingBlock(x:left + 4, y: top + 3);

          addBuildingBlockBottom(x:left + 1, y: top + 4);
          addBuildingBlock(x:left + 4, y: top + 4);
          addBuildingBlock(x:left + 2, y: top + 4);
          addBuildingBlockBottom(x:left + 3, y: top + 4);
        },*/
        
        
          /*   
             .,.,.
             ,.,.,
             .,.,.
             ,.,.,
          
          */


        ::{
          @:off = _map.addScenerySymbol(character:'.');
          @:on  = _map.addScenerySymbol(character:',');
          
          @iter = false;
          for(0, ZONE_BUILDING_MINIMUM_WIDTH)::(x) {
            for(0, ZONE_BUILDING_MINIMUM_HEIGHT)::(y) {
              _map.setSceneryIndex(x:left+x, y:top+y, symbol: if(iter) on else off);
              iter = !iter;
            }
          }          
        },

          /*   
             . . .
            . . 
             . . .
            . . 
          
          */


        ::{
          @:off = _map.addScenerySymbol(character:'.');
          @:on  = _map.addScenerySymbol(character:' ');
          
          @iter = false;
          for(0, ZONE_BUILDING_MINIMUM_WIDTH)::(x) {
            for(0, ZONE_BUILDING_MINIMUM_HEIGHT)::(y) {
              _map.setSceneryIndex(x:left+x, y:top+y, symbol: if(iter) on else off);
              iter = !iter;
            }
          }          
        },
        

          /*   
             .,.,
             ,^^.
             .^^,
             ,.,.
          
          */


        ::{
          @:off   = _map.addScenerySymbol(character:'.');
          @:on  = _map.addScenerySymbol(character:',');
          @:bush  = _map.addScenerySymbol(character:'^');
          
          @iter = false;
          for(0, ZONE_BUILDING_MINIMUM_WIDTH)::(x) {
            for(0, ZONE_BUILDING_MINIMUM_HEIGHT)::(y) {
              _map.setSceneryIndex(x:left+x, y:top+y, symbol: if(iter) on else off);
              iter = !iter;
            }
          }
          
          _map.setSceneryIndex(x:left+1, y:top+1, symbol: bush);
          _map.setSceneryIndex(x:left+2, y:top+1, symbol: bush);
          _map.setSceneryIndex(x:left+1, y:top+2, symbol: bush);
          _map.setSceneryIndex(x:left+2, y:top+2, symbol: bush);
          
          
        },

          /*   
             .,.,
             ,╿╿.
             .╿╿,
             ,.,.
          
          */
        
        ::{
          @:off   = _map.addScenerySymbol(character:'.');
          @:on  = _map.addScenerySymbol(character:',');
          @:tree  = _map.addScenerySymbol(character:'╿');
          
          @iter = false;
          for(0, ZONE_BUILDING_MINIMUM_WIDTH)::(x) {
            for(0, ZONE_BUILDING_MINIMUM_HEIGHT)::(y) {
              _map.setSceneryIndex(x:left+x, y:top+y, symbol: if(iter) on else off);
              iter = !iter;
            }
          }          
          
          _map.setSceneryIndex(x:left+1, y:top+1, symbol: tree);
          _map.setSceneryIndex(x:left+2, y:top+1, symbol: tree);
          _map.setSceneryIndex(x:left+1, y:top+2, symbol: tree);
          _map.setSceneryIndex(x:left+2, y:top+2, symbol: tree);
          
          _map.enableWall(x:left+1, y:top+1);
          _map.enableWall(x:left+2, y:top+1);
          _map.enableWall(x:left+1, y:top+2);
          _map.enableWall(x:left+2, y:top+2);
          
        },        
        
        
      ])();

    }     



    // adds a minimally-sized building
    @:addGate ::(left, top, which) {
      @:location = Location.new(
        base: Location.database.find(:'base:entrance'),
        landmark: _landmark
      );

      @:mark = Location.new(
        landmark: location.landmark,
        base: Location.database.find(:'base:sign')
      );
      
      @:spaceIndex = _map.addScenerySymbol(:' ');
      
      
      mark.name = 'Exit'
      mark.halo = false;
      

      match(which) {
        // North       
        (NORTH):::<={
          location.x = left - ZONE_CONTENT_PADDING;
          location.y = top-ZONE_CONTENT_PADDING+1;
          mark.x = location.x;
          mark.y = location.y;
          
          location.landmark.addLocation(
            location,
            width: ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2+1,
            height: 1
          );
          location.landmark.addLocation(
            location:mark,
            width: ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2+1,
            height: 1,
            traits: Map.TRAIT.DISCOVERED
          );
          
          
          _map.setPointer(x:location.x + ZONE_BUILDING_MINIMUM_WIDTH/2+ZONE_CONTENT_PADDING, y:location.y);
          for(location.x+1, location.x + ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2-1) ::(i) {
            _map.disableWall(x:i, y:location.y);
            _map.setSceneryIndex(x:i, y:location.y-1, symbol:spaceIndex);
          }
        

        },

        // East       
        (EAST):::<={
          location.x = left+ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING-1;
          location.y = top - ZONE_CONTENT_PADDING;
          mark.x = location.x;
          mark.y = location.y;
          
          location.landmark.addLocation(
            location,
            width: 1,
            height: ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2+1
          );
          location.landmark.addLocation(
            location:mark,
            width: 1,
            height: ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2+1,
            traits: Map.TRAIT.DISCOVERED
          );

          _map.setPointer(x:location.x, y:location.y+ZONE_BUILDING_MINIMUM_WIDTH/2+ZONE_CONTENT_PADDING);
          for(location.y+1, location.y + ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2-1) ::(i) {
            _map.disableWall(x:location.x,   y:i);
            _map.setSceneryIndex(x:location.x+1, y:i, symbol:spaceIndex);
          }


        },

        // West       
        (WEST):::<={

          location.x = left-ZONE_CONTENT_PADDING+1;
          location.y = top - ZONE_CONTENT_PADDING;
          mark.x = location.x;
          mark.y = location.y;
          
          location.landmark.addLocation(
            location,
            width: 1,
            height: ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2+1
          );
          location.landmark.addLocation(
            location:mark,
            width: 1,
            height: ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2+1,
            traits: Map.TRAIT.DISCOVERED
          );

          _map.setPointer(x:location.x, y:location.y+ZONE_BUILDING_MINIMUM_WIDTH/2+ZONE_CONTENT_PADDING);
          for(location.y+1, location.y + ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2-1) ::(i) {
            _map.disableWall(x:location.x,   y:i);
            _map.setSceneryIndex(x:location.x-1, y:i, symbol:spaceIndex);
          }

        },



        // South
        (SOUTH):::<={
          location.x = left - ZONE_CONTENT_PADDING;
          location.y = top+ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING-1;
          mark.x = location.x;
          mark.y = location.y;
          
          location.landmark.addLocation(
            location,
            width: ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2+1,
            height: 1
          );
          location.landmark.addLocation(
            location:mark,
            width: ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2+1,
            height: 1,
            traits: Map.TRAIT.DISCOVERED
          );
          _map.setPointer(x:location.x +ZONE_BUILDING_MINIMUM_WIDTH/2+ZONE_CONTENT_PADDING, y:location.y);
          for(location.x+1, location.x + ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING*2-1) ::(i) {
            _map.disableWall(x:i, y:location.y);
            _map.setSceneryIndex(x:i, y:location.y+1, symbol:spaceIndex);
          }

        }
        
        
      }

      
      return which;

    }  



    // adds a minimally-sized wide building
    @:addWideBuilding ::(name, left, top, symbol, locationLeft, locationRight) {
      /*
        x        x
        xxxxxxxxxx
        xxxxxxx$$x
        x  xxxxxxx
      
      */

      /*
        i        i
        xxxxxxxxxx
        x$$xxxxxxx
        xxxxxxx  x
      
      */



      addBuildingBlockTop(x:left + 1,  y:top+1)
      addBuildingBlockTop(x:left + 10, y:top+1)
      for(1, 4)::(y) {
        for(0, 10)::(x) {   
          addBuildingBlock(x:left+x + 1, y:top+y+1);
        }
      }


      if (random.flipCoin() == true) ::<= {
        _map.disableWall(x:left + 2, y: top + 4);
        _map.disableWall(x:left + 3, y: top + 4);
        _map.clearScenery(x:left + 2, y: top + 4);
        _map.clearScenery(x:left + 3, y: top + 4);


        addLocations(name, locationLeft, locationRight, x:left + 2, y: top + 4);
       
        

        if (symbol != empty) ::<= {
          @:index = _map.addScenerySymbol(character:symbol);
          _map.setSceneryIndex(x:left + 8, y: top + 3, symbol:index);
          _map.setSceneryIndex(x:left + 9, y: top + 3, symbol:index);
        }


      } else ::<= {      
        _map.disableWall(x:left + 8, y: top + 4);
        _map.disableWall(x:left + 9, y: top + 4);
        _map.clearScenery(x:left + 8, y: top + 4);
        _map.clearScenery(x:left + 9, y: top + 4);
        
        addLocations(name, locationLeft, locationRight, x:left + 8, y: top + 4);

        if (symbol != empty) ::<= {
          @:index = _map.addScenerySymbol(character:symbol);
          _map.setSceneryIndex(x:left + 2, y: top + 3, symbol:index);
          _map.setSceneryIndex(x:left + 3, y: top + 3, symbol:index);
        }

      }


    } 


    // adds a minimally-sized wide building
    @:addTallBuilding ::(name, left, top, symbol, locationLeft, locationRight) {
      /*
        ||||
        xxxx
        xxxx
        xxxx
        xxxx
        xxxx
        x  x
      
      */
      addBuildingBlockTop(x:left+  1, y:top+2)
      addBuildingBlockTop(x:left+  4, y:top+2)

      for(2, 7)::(y) {
        for(0, 4)::(x) {
          addBuildingBlock(x:left+x + 1, y:top+y+1);
        }
      }




      _map.disableWall(x:left + 2, y: top + 7);
      _map.disableWall(x:left + 3, y: top + 7);
      _map.clearScenery(x:left + 2, y: top + 7);
      _map.clearScenery(x:left + 3, y: top + 7);
      
      
      addLocations(name, locationLeft, locationRight, x:left + 2, y: top + 7);
      
      
      if (symbol != empty) ::<= {
        @:index = _map.addScenerySymbol(character:symbol);
        _map.setSceneryIndex(x:left + 2, y: top + 4, symbol:index);
        _map.setSceneryIndex(x:left + 3, y: top + 4, symbol:index);
      }
      

    }
    

    @:Location = import(module:'game_mutator.location.mt');

    this.constructor = ::(map, landmark, category => Number, topDeco => String, bottomDeco => String) {
      _topDeco = map.addScenerySymbol(character:topDeco);
      _bottomDeco = map.addScenerySymbol(character:bottomDeco);
      unitsWide = random.integer(from:ZONE_MINIMUM_SPAN, to:ZONE_MAXIMUM_SPAN); 
      unitsHigh = random.integer(from:ZONE_MINIMUM_SPAN, to:ZONE_MAXIMUM_SPAN); 
      _landmark = landmark;

      if (unitsWide > ZONE_MAXIMUM_SPAN ||
        unitsHigh > ZONE_MAXIMUM_SPAN)
        error(detail:' uhhh RNG brokey.');

      blockSceneryIndex = map.addScenerySymbol(character:'▓');

      // if category is Entrance, the area is 2x2 
      if (category == 0) ::<= {
        unitsWide = 1;
        unitsHigh = 1;
      }

      _map = map;
      _category = category;
      _w = unitsWide * ZONE_BUILDING_MINIMUM_WIDTH +ZONE_CONTENT_PADDING*2;
      _h = unitsHigh * ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING*2;
      
      for(0, unitsWide)::(x) {
        slots[x] = [];
        for(0, unitsHigh)::(y) {
          slots[x][y] = false;
          freeSpaces->push(value:{x:x, y:y});
        } 
      }
      
    };
    
    this.interface = {
    
    
      left : {get::<-_x},    
      top : {get::<-_y},  
      
      setPosition ::(left, top) {
        _x = left;
        _y = top;
        
        
        for(0, _w)::(i) {
          _map.enableWall(x:i+_x, y:_y);
          _map.enableWall(x:i+_x, y:_y+_h);
        }   

        for(0, _h)::(i) {
          _map.enableWall(x:_x, y:_y+i);
          _map.enableWall(x:_x+_w, y:_y+i);
        }
        _map.enableWall(x:_x+_w, y:_y+_h);
           
      },
          
      width : {get::<-_w},    
      height : {get::<-_h},
      category : {get::<- _category},
      
      fillDecoration ::{
      
      
        for(0, unitsWide)::(x) {
          for(0, unitsHigh)::(y) {
            when(slots[x][y] == true) empty;
            
            when(random.flipCoin()) empty;
            
              
            slots[x][y] = true;
            freeSpaces->remove(key:freeSpaces->findIndexCondition(::(value) <- value.x == x && value.y == y));
            addDecoration(
              left:x * ZONE_BUILDING_MINIMUM_WIDTH + _x+ZONE_CONTENT_PADDING,
              top:y * ZONE_BUILDING_MINIMUM_HEIGHT + _y+ZONE_CONTENT_PADDING
            );            
          } 
        }              
      },
      
      // only for zones that have gates, gets the 
      // side that the gate is hugging. This is primarily used for 
      // placement of the first zone in the map so that it logically 
      // looks like an entrance to the outside.
      // is empty if there is no gate.
      gateSide : {get::<- gateSide},
      
      addEntrance ::{



        ::? {
          for(0, 20)::(i) {
            @x0;
            @y0;
            @x1;
            @y1;
            
            match(gateSide) {
              (EAST, WEST):::<= {
                x0 = if (gateSide == WEST) 0 else unitsWide - 1;
                y0 = random.integer(from:0, to:unitsHigh-1);
                
                x1 = x0;
                y1 = y0;
                if (gateSide == WEST)
                  x1 += 1
                else  
                  x1 -= 1;
                              
              },
              
              
              (NORTH, SOUTH):::<= {
                x0 = random.integer(from:0, to:unitsWide-1);                
                y0 = if (gateSide == NORTH) 0 else unitsHigh - 1;

                x1 = x0;
                y1 = y0;
                if (gateSide == SOUTH)
                  y1 += 1
                else  
                  y1 -= 1;                
              }
            }              
            when(slots[x0][y0] != false) empty;
            //when(slots[x1][y1] != false) empty;

            @:space0 = getSpaceBySlot(x:x0, y:y0);
            //@:space1 = getSpaceBySlot(x:x1, y:y1);


            
            slots[x0][y0] = true;
            //slots[x1][y1] = true;
            
            freeSpaces->remove(key:space0);
            //freeSpaces->remove(key:space1);
            addGate(
              left:space0.x * ZONE_BUILDING_MINIMUM_WIDTH + _x+ZONE_CONTENT_PADDING,
              top:space0.y * ZONE_BUILDING_MINIMUM_HEIGHT + _y+ZONE_CONTENT_PADDING,
              which:gateSide
            );
            send();
          }
        }      
      },
      
      
      // returns false if cant fit the location
      addPortal::(portalSpec) {
        @:Landmark = import(module:'game_mutator.landmark.mt');

        @:createPortalFromSpecification:: {
          @:spec = {...portalSpec};
          @:landmarkID = portalSpec.id;
          spec.id = 'base:portal'
          @:loc = _landmark.createLocationFromSpecification(spec);
          loc.data.linkedPortalLandmarkID = landmarkID;
          return loc;
        }

        @:locationLeft = createPortalFromSpecification();
        @:locationRight = createPortalFromSpecification();

        // {"linkedPortalID" : "structure-entrance-left"}
        // {"linkedPortalID" : "structure-entrance-right"}
        locationLeft.data.linkedPortalID = 'structure-entrance-left';
        locationRight.data.linkedPortalID = 'structure-entrance-right';
      
        locationLeft.portal.addChainItem(:locationRight);
        locationRight.portal.addChainItem(:locationLeft);



        @:landmarkBase = Landmark.database.find(:portalSpec.id);
        
        @:size = if (landmarkBase.hasTraits(:Landmark.TRAIT.STRUCTURE_LARGE)) 2 else 1;
        when(random.flipCoin() && size == 1) ::<= {
          when(freeSpaces->keycount == 0) false;
          
          @:space = random.pickArrayItem(list:freeSpaces);
          slots[space.x][space.y] = true;
          freeSpaces->remove(key:freeSpaces->findIndex(value:space));
          addMinimalBuilding(
            name: portalSpec.name,
            locationLeft,
            locationRight,
            symbol:if (landmarkBase.hasTraits(:Landmark.TRAIT.STRUCTURE_RESIDENTIAL)) empty else portalSpec.symbol,
            left:space.x * ZONE_BUILDING_MINIMUM_WIDTH + _x+ZONE_CONTENT_PADDING,
            top:space.y * ZONE_BUILDING_MINIMUM_HEIGHT + _y+ZONE_CONTENT_PADDING
          );
          return true;
        }
        
        
        when(true) ::<= {
          @:wide = random.flipCoin();
          
          return ::? {
            for(0, 10)::(i) {
              @:space0 = random.pickArrayItem(list:freeSpaces);
              @space1;
              
              if (wide) ::<= {
                space1 = (freeSpaces->filter(by::(value) <- value.x == space0.x+1 && value.y == space0.y))[0];
                if (space1 == empty)
                  space1 = (freeSpaces->filter(by::(value) <- value.x == space0.x-1 && value.y == space0.y))[0];
              } else ::<= {
                space1 = (freeSpaces->filter(by::(value) <- value.x == space0.x && value.y == space0.y+1))[0];
                if (space1 == empty)
                  space1 = (freeSpaces->filter(by::(value) <- value.x == space0.x && value.y == space0.y-1))[0];              
              }
              // this attempt failed
              when(space1 == empty) empty;

              slots[space0.x][space0.y] = true;
              freeSpaces->remove(key:freeSpaces->findIndex(value:space0));
              slots[space1.x][space1.y] = true;
              freeSpaces->remove(key:freeSpaces->findIndex(value:space1));

              
              
              if (wide) ::<= {
                @:left = if (space0.x < space1.x) space0.x else space1.x;
                addWideBuilding(
                  name: portalSpec.name,
                  locationLeft,
                  locationRight,
                  symbol:if (landmarkBase.hasTraits(:Landmark.TRAIT.STRUCTURE_RESIDENTIAL)) empty else portalSpec.symbol,
                  left:_x + left * ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING,
                  top: _y + space0.y * ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING
                );
              } else ::<= {
                @:top = if (space0.y < space1.y) space0.y else space1.y;
                addTallBuilding(
                  name: portalSpec.name,
                  locationLeft,
                  locationRight,
                  symbol:if (landmarkBase.hasTraits(:Landmark.TRAIT.STRUCTURE_RESIDENTIAL)) empty else portalSpec.symbol,
                  left:_x + space0.x * ZONE_BUILDING_MINIMUM_WIDTH+ZONE_CONTENT_PADDING,
                  top: _y + top * ZONE_BUILDING_MINIMUM_HEIGHT+ZONE_CONTENT_PADDING
                );              
              }
              
              send(message:true);
            }
            return false;
          }
        }
        
        
        error(detail:'Dunno what to do here.');
      },
  

    }
  }
);



return ::(mapHint => Object, landmark, objects) {
  @Location = import(module:'game_mutator.location.mt');

  @map;
  @landmark
  @hasZoningWalls = true;
  @hasFillerBuildings = true;
  @zones = [];
  @paired = [];
  @topDeco = random.pickArrayItem(
    list : [
      ',',
      '|',
      '.',
      '-',
      '_',
      '=',
      '~'
    ]
  );
  @bottomDeco = random.pickArrayItem(
    list : [
      '▓'
    ]
  );
  
  @isPaired = ::(i, n) {
    @temp;
    if (i < n) ::<= {
      temp = i;
      i = n;
      n = temp;
    }
    
    return paired['' + i + '-' + n]!=empty;
  }
  
  
  @setPaired = ::(i, n, alongIcoord, alongIside, alongIcenter) {
    @temp;
    if (i < n) ::<= {
      temp = i;
      i = n;
      n = temp;
    }
    
    paired['' + i + '-' + n] = {
      first: i,
      second: n,
      coord: alongIcoord,
      side: alongIside,
      center:alongIcenter
    }
  }    


  
  // returns whether 2 line segments overlap
  // l0 is less than m0,
  // l1 is less than m1
  @:is1DlineOverlap::(l0, m0, l1, m1) <-
    if (l0 < l1) 
      l1 < m0
    else 
      m1 > l0
  ;
  
  
  @:isZoneAllowed::(top, left, zone) {
    when (
      top < STRUCTURE_MAP_PADDING ||
      left < STRUCTURE_MAP_PADDING ||
      left + zone.width  > map.width - STRUCTURE_MAP_PADDING ||
      top + zone.height > map.height - STRUCTURE_MAP_PADDING
      
    ) false;

  
    return ::? {
      foreach(zones)::(i, z) {
        // intersects with existing zones
        @xOverlap = is1DlineOverlap(
          l0:   z.left, m0:   z.left +  z.width,
          l1:   left, m1:   left + zone.width
        );
        
        @yOverlap = is1DlineOverlap(
          l0:   z.top, m0:   z.top +  z.height,
          l1:   top, m1:   top + zone.height
        );
        
        
        if (xOverlap
           &&
          yOverlap
        ) send(message:false);



      }
      
      return true;
    }
  }
  
  // adds a new zone.
  // if no zones exist, then the zone is placed somewhere 
  // out in the open. Else, it must be touching an existing zone 
  // on its side
  @:addZone ::(category) {
    @zone = Zone.new(map:map, landmark, category, topDeco, bottomDeco);
    @top;
    @left;
    @alongIcoord;
    @alongIside;
    @alongIcenter;
    @preZone;
    if (zones->keycount == 0) ::<= {
      // fallback
      match(zone.gateSide) {
        (NORTH):::<= {
          top = STRUCTURE_MAP_PADDING;
          left = ((map.width - STRUCTURE_MAP_PADDING) / 2)->floor;
        },

        (EAST):::<= {
          top = ((map.height - STRUCTURE_MAP_PADDING) / 2)->floor;
          left = (map.width - STRUCTURE_MAP_PADDING) - zone.width;
        },
        
        (WEST):::<= {
          top = ((map.height - STRUCTURE_MAP_PADDING) / 2)->floor;
          left = STRUCTURE_MAP_PADDING;
        },
        
        (SOUTH):::<= {
          top = (map.height - STRUCTURE_MAP_PADDING) - zone.height;
          left = ((map.width - STRUCTURE_MAP_PADDING) / 2)->floor;
        },

        default: ::<= {
          top  = STRUCTURE_MAP_STARTING_Y + STRUCTURE_MAP_PADDING;
          left = STRUCTURE_MAP_STARTING_X + STRUCTURE_MAP_PADDING;                  
        }
      }
    } else ::<= {
      ::? {
        @try = 0;
        forever ::{
          // pick a random zone and extend it 
          preZone = zones[try]; try = (try+1)%zones->size;
          when(preZone == empty) empty;
          match(random.integer(from:0, to:3)) {
            // North
            (NORTH):::<= {
              top = preZone.top - zone.height;
              left = (preZone.left + preZone.width / 2 + (-0.5 + random.float()) * zone.width)->floor - zone.width/2;
              top = top->floor;
              left = left->floor;
              alongIcoord = preZone.top;
              alongIside = NORTH;
              
              @:innerMiddle = if (left > preZone.left) left else preZone.left;
              @:outerMiddle = if (zone.width + left < preZone.width + preZone.left) zone.width + left else preZone.width + preZone.left;
              alongIcenter = ((innerMiddle + outerMiddle)/2)->floor;
            },
            
            // East 
            (WEST):::<= {
              top = (preZone.top + preZone.height / 2 + (-0.5 + random.float()) * zone.height)->floor - zone.height/2;          
              left = preZone.left - zone.width;
              top = top->floor;
              left = left->floor;
              alongIcoord = preZone.left;
              alongIside = WEST;
              @:innerMiddle = if (top > preZone.top) top else preZone.top;
              @:outerMiddle = if (zone.height + top < preZone.height + preZone.top) zone.height + top else preZone.height + preZone.top;
              alongIcenter = ((innerMiddle + outerMiddle)/2)->floor;

            },
            
            // South
            (SOUTH):::<= {
              top = preZone.top + preZone.height;
              left = (preZone.left + preZone.width / 2 + (-0.5 + random.float()) * zone.width)->floor - zone.width/2;
              top = top->floor;
              left = left->floor;
              alongIcoord = top;
              alongIside = SOUTH;
              @:innerMiddle = if (left > preZone.left) left else preZone.left;
              @:outerMiddle = if (zone.width + left < preZone.width + preZone.left) zone.width + left else preZone.width + preZone.left;
              alongIcenter = ((innerMiddle + outerMiddle)/2)->floor;
            },
            
            // West
            (EAST):::<= {
              top = (preZone.top + preZone.height / 2 + (-0.5 + random.float()) * zone.height)->floor - zone.height/2;          
              left = preZone.left + preZone.width;
              top = top->floor;
              left = left->floor;
              alongIcoord = left;
              alongIside = EAST;
              @:innerMiddle = if (top > preZone.top) top else preZone.top;
              @:outerMiddle = if (zone.height + top < preZone.height + preZone.top) zone.height + top else preZone.height + preZone.top;
              alongIcenter = ((innerMiddle + outerMiddle)/2)->floor;
            }

            
          }
          
          when (!isZoneAllowed(top, left, zone)) empty;            
          send();
        }
      }
    }
    
    zone.setPosition(top, left);      
    zones->push(value:zone);

          
    setPaired(
      i:zones->findIndex(value:preZone),
      n:zones->keycount-1,
      alongIcoord,
      alongIside,
      alongIcenter
    );  
    
    
    return zone;
  }    



  return ::<= {
    @:Landmark = import(module:'game_mutator.landmark.mt');
    map = landmark.map;
    map.paged = false;
    map.undefinedCharacter = ' ';
    map.width = STRUCTURE_MAP_SIZE+STRUCTURE_MAP_PADDING*2;
    map.height = STRUCTURE_MAP_SIZE+STRUCTURE_MAP_PADDING*2;
    

    if (mapHint.wallCharacter != empty) map.wallCharacter = mapHint.wallCharacter;
    if (mapHint.undefinedCharacter != empty) map.undefinedCharacter = mapHint.undefinedCharacter;
    if (mapHint.hasZoningWalls != empty) hasZoningWalls = mapHint.hasZoningWalls;
    if (mapHint.hasFillerBuildings != empty) hasFillerBuildings = mapHint.hasFillerBuildings;



    @:zone = addZone(category:0);
    zone.addEntrance();

    // special function that adds a location value 
    // to the map in a designated zoning area.
    foreach(objects) ::(k, v) {
      @:base = Landmark.database.find(:v.id);
      @:category = if (base.hasTraits(:Landmark.TRAIT.STRUCTURE_RESIDENTIAL))
        Landmark.TRAIT.STRUCTURE_RESIDENTIAL
      else if (base.hasTraits(:Landmark.TRAIT.STRUCTURE_BUSINESS))
        Landmark.TRAIT.STRUCTURE_BUSINESS 
      else 
        Landmark.TRAIT.STRUCTURE_UTILITY
    
    
    
      @:zonesCat = zones->filter(by:::(value) <- value.category == category);
      @zone = if (zonesCat == empty || zonesCat->keycount == 0)
        addZone(category)
      else
        random.pickArrayItem(list:zonesCat)
      ;
      
      if (zone.addPortal(:v) == false) ::<= {
        zone = addZone(category);
        zone.addPortal(:v);
      }
    }




    // indicates that no other locations will be added 
    // so any final step can be taken, such as adding 
    // zoning walls and expanding / connecting 
    // buildings.

    foreach(zones)::(i, zone) {
      zone.fillDecoration();
    }
    
    foreach(paired)::(i, data) {
      @:base = zones[data.first];
      @:other = zones[data.second];
      match(data.side) {
        (NORTH, SOUTH):::<= {
          for(data.center-1, data.center+2)::(x) {
            map.disableWall(x, y: data.coord);
            map.clearScenery(x, y: data.coord);            
          }
        },

        (EAST, WEST):::<= {
          for(data.center-1, data.center+2)::(y) {
            map.disableWall(x:data.coord, y);
            map.clearScenery(x:data.coord, y);            
          }
        }

      }
    }
  } 
};

