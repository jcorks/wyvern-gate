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
@:Landmark = import(module:'game_mutator.landmark.mt');
@:Map = import(module:'game_class.map.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');

@:Async = ::? {
  return import(:'Matte.System.Async');
} => {
  onError::(message) {
    
  }
}



@:LargeMap = class(
  name: 'Wyvern.LargeMap',
  define:::(this) {
  
    @:clearScenery::(map, x, y) {
      @index = map.addScenerySymbol(character:' ');

      for(x-1, x+2) ::(ix) {
        for(y-1, y+2) ::(iy) {
          map.setSceneryIndex(x:ix, y:iy, symbol:index);
          map.clearScenery
        }
      }
    }   
    
    
    this.interface = {

      create::(parent, sizeW, sizeH, symbols, onDone) {        
        @:JSON = import(:"Matte.Core.JSON");
        @:input = JSON.encode(:{
          sizeW : sizeW,
          sizeH : sizeH,
          symbols : symbols,
          random : random.save()
        })
        
        
        @:handleResults ::(resultStr) {
            @:map = Map.new();
            
            @:results = JSON.decode(:resultStr);
            random.load(:results.random);
            map.load(:results.map);
            map.parent = parent;
            onDone(:map);        
        }
        when(Async) ::<= {
          @ct = 0;
          @message = 'Loading ';
          @status = Async.Worker.State.Unknown
        
          @:worker = Async.Worker.new(
            module: 'game_async.largemapgen.mt',
            input
          );        
          
          worker.installHook(
            event: 'onStateChange',
            hook ::(detail) {
              status = detail;
            }
          )

          worker.installHook(
            event: 'onNewMessage',
            hook ::(detail) {
              message = detail;
            }
          )

          @:genDots ::{
            return match((ct/3)->floor % 4) {
              (0): '[-]',
              (1): '[\\]',
              (2): '[|]',
              (3): '[/]'
            }
          }
          windowEvent.queueCustom(
            isAnimation: true,
            animationFrame ::{
              Async.update();

              
              ct += 1;
              canvas.blackout();
              canvas.movePen(
                x: (canvas.width / 2 - message->length / 2)->floor,
                y: (canvas.height/2)->floor
              );
              
              canvas.drawText(text:message + genDots());
              
              return match(status) {
                (Async.Worker.State.Failed):
                  error(:worker.error),
                  
                (Async.Worker.State.Finished): ::<= {
                  handleResults(:worker.result);

                  return windowEvent.ANIMATION_FINISHED
                }                  
              }
              
            }
          );
          
        }


        // synchronous route. will freeze

        @:loading = import(module:'game_function.loading.mt');
        loading(
          message: 'Generating island... This may take a while and may freeze for a sec.',
          do:: {   
            handleResults(:importModule(
                module: 'game_async.largemapgen.mt',
                noCache: true,
                parameters : {
                  input : input               
                }
              )
            );
          }
        );
        
      },


      addLandmark::(map, island, base) { 
        @:loc = random.scrambled(:map.areas)[0];
        @:x = loc.x;      
        @:y = loc.y;      
        @:landmark = Landmark.new(
          island,
          base,
          x,
          y
        );
        clearScenery(map, x, y);
        island.addLandmark(:landmark);
        return landmark;
      },
      
      getAPosition ::(map) {
        @:loc = random.scrambled(:map.areas)[0];
        @:x = loc.x;      
        @:y = loc.y;      

        return {
          x: x,
          y: y
        }
      }
      
      
    }
  }
);
return LargeMap.new();
