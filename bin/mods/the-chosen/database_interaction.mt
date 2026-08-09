@:WyvernGate = import(:'wyvern-gate.mt');
@:Interaction = WyvernGate.Interaction
@:world = WyvernGate.World
@:windowEvent = WyvernGate.Core.WindowEvent
@:Item = WyvernGate.Item
@:Scene = WyvernGate.Scene
@:canvas = WyvernGate.Core.Graphics.Canvas
@:random = WyvernGate.Core.Random
@:StatSet = WyvernGate.Util.StatSet

return ::{
  Interaction.newEntry(:{
    name : 'Sentimental Box',
    id : 'thechosen:box-shopkeep',
    keepInteractionMenu : false,
    isAvailable ::(location, party) <- true,
    interact ::(location, party) {
      @:world = import(module:'base/world.mt');
      
      @:shopkeep = location.ownedBy;
      
      windowEvent.queueMessage(
        speaker : shopkeep.name,
        text: '"Oh! Hey, ' + party.members[0].name + '! I was told to give you this."'
      );
      
      windowEvent.queueMessage(
        text: 'The party received a box. It can be used from the inventory.'
      );

      party.inventory.add(item:Item.new(
        base:Item.database.find(id:'thechosen:sentimental-box')
      ));
      
      location.overrideInteractID = '';

      windowEvent.queueMessage(
        speaker : shopkeep.name,
        text: '"Come by any time if you need anything."'
      );

      
    }
  });


  Interaction.newEntry(:{
    name : 'Wyvern of Fire',
    id : 'thechosen:wyvern-of-fire',
    keepInteractionMenu : false,
    isAvailable ::(location, party) <- true,
    interact ::(location, party) {
      @:world = import(module:'base/world.mt');              
      if (world.scenario.data.fireWyvernDefeated == false) ::<= {
        Scene.start(id:'thechosen:scene_wyvernfire0', onDone::{}, location, landmark:location.landmark);
      } else ::<= {
        // just visiting!
        Scene.start(id:'thechosen:scene_wyvernfire1', onDone::{}, location, landmark:location.landmark);            
      }
    }
  });

  Interaction.newEntry(:{
    name : 'Wyvern of Ice',
    id : 'thechosen:wyvern-of-ice',
    keepInteractionMenu : false,
    isAvailable ::(location, party) <- true,
    interact ::(location, party) {
      @:world = import(module:'base/world.mt');              
      if (world.scenario.data.iceWyvernDefeated == false) ::<= {
        Scene.start(id:'thechosen:scene_wyvernice0', onDone::{}, location, landmark:location.landmark);
      } else ::<= {
        // just visiting!
        Scene.start(id:'thechosen:scene_wyvernice1', onDone::{}, location, landmark:location.landmark);            
      }
    }
  });
      

  Interaction.newEntry(:{
    name : 'Wyvern of Thunder',
    id : 'thechosen:wyvern-of-thunder',
    keepInteractionMenu : false,
    isAvailable ::(location, party) <- true,
    interact ::(location, party) {
      @:world = import(module:'base/world.mt');              
      if (world.scenario.data.thunderWyvernDefeated == false) ::<= {
        Scene.start(id:'thechosen:scene_wyvernthunder0', onDone::{}, location, landmark:location.landmark);
      } else ::<= {
        // just visiting!
        Scene.start(id:'thechosen:scene_wyvernthunder1', onDone::{}, location, landmark:location.landmark);            
      }
    }
  });

  Interaction.newEntry(:{
    name : 'Wyvern of Light',
    id : 'thechosen:wyvern-of-light',
    keepInteractionMenu : false,
    isAvailable ::(location, party) <- true,
    interact ::(location, party) {
      @:world = import(module:'base/world.mt');              
      if (world.scenario.data.lightWyvernDefeated == false) ::<= {
        Scene.start(id:'thechosen:scene_wyvernlight0', onDone::{}, location, landmark:location.landmark);
      } else ::<= {
        // just visiting!
        Scene.start(id:'thechosen:scene_wyvernlight1', onDone::{}, location, landmark:location.landmark);            
      }
    }
  });
  Interaction.newEntry(
    data : {
      name : 'Final Floor',
      id :  'thechosen:final-stairs',
      isAvailable ::(location, party) <- true,
      keepInteractionMenu : false,
      interact ::(location, party) {
        @:world = import(module:'base/world.mt');

        @:proceed ::{
          if (location.targetLandmark == empty) ::<={
            @:Landmark = import(module:'base/map/landmark.mt');
           
            @:id = location.landmark.island.base.id;
           
            location.targetLandmark = Landmark.new(
              island : location.landmark.island,
              base: Landmark.database.find(id:
                match(id) {
                  ('thechosen:island-of-fire'):    'thechosen:fire-wyvern-dimension',
                  ('thechosen:island-of-ice'):     'thechosen:ice-wyvern-dimension',
                  ('thechosen:island-of-thunder'): 'thechosen:thunder-wyvern-dimension',
                  ('thechosen:island-of-light'):   'thechosen:light-wyvern-dimension'
                }
              )
            )
            location.targetLandmark.loadContent();
            location.targetLandmarkEntry = location.targetLandmark.getRandomEmptyPosition();
          }
          @:instance = import(module:'base/instance.mt');

          location.targetLandmark.visit()
          location.targetLandmark.map.setPointer(
            x: location.targetLandmarkEntry.x,
            y: location.targetLandmarkEntry.y
          );
          location.targetLandmark.travel();
          canvas.clear();          
        }


        if (location.contested == true) ::<= {


          windowEvent.queueMessage(
            text: 'This looks to be the last floor...'
          );
          
          windowEvent.queueAskBoolean(
            prompt: 'Proceed?',
            onChoice::(which) {
              when (which == false) empty;

              Scene.start(
                id: 'thechosen:scene_prewyvernbattle0',
                onDone::{},
                location:location,
                landmark:location.landmark
              );
              location.contested = false;
            }
          );
              
        } else ::<= {
          windowEvent.queueMessage(
            text: 'This looks to be the last floor...'
          );

          windowEvent.queueMessage(
            text: '...Oh! It looks like theres a path to the entrance, too.'
          );

          windowEvent.queueChoices(
            prompt: 'Do which?',
            canCancel: true,
            choicesMatch : [
              'Proceed, unaware of what lies ahead', ::<- proceed(),
              'Go back to entrance', :: {
                windowEvent.queueMessage(
                  text: 'You return to the entrance.',
                  renderable :{
                    render ::{
                      canvas.fill();
                    }   
                  }
                );
                
                windowEvent.queueCustom(
                  onEnter::{
                    @:instance = import(module:'base/instance.mt');
                    world.island.visit();
                    world.island.travel();
                  }
                )
              },
              'Wait for now', ::<- empty
            ]
          );
        }
      }
    }
  )

      
  Interaction.newEntry(
    data : {
      name : 'Next Floor',
      id :  'thechosen:next-floor',
      keepInteractionMenu : false,
      isAvailable ::(location, party) <- true,
      interact ::(location, party) {
        if (location.targetLandmark == empty) ::<={
        
          if (location.landmark.floor > 5 && random.number() > 0.5 - (0.2*(location.landmark.floor - 5))) ::<= {
            @:Landmark = import(module:'base/map/landmark.mt');
            
            
            
            location.targetLandmark = Landmark.new(
              island : location.landmark.island,
              base:Landmark.database.find(id:'thechosen:shrine-lost-floor')
            );
            location.targetLandmark.loadContent();

          } else ::<= {
            @:Landmark = import(module:'base/map/landmark.mt');
            
            location.targetLandmark = Landmark.new(
              island : location.landmark.island,
              base:Landmark.database.find(id:location.landmark.base.id),
              floorHint:location.landmark.floor+1
            )
            location.targetLandmark.loadContent();
            
            location.targetLandmark.name = 'Shrine ('+location.targetLandmark.floor+'F)';
          }

          location.targetLandmarkEntry = location.targetLandmark.getRandomEmptyPosition();      
        }

        windowEvent.queueMessage(
          text:'The party travels to the next floor.'
        );
        
        windowEvent.queueCustom(
          onEnter:: {
            @:instance = import(module:'base/instance.mt');
            location.targetLandmark.visit();
            location.targetLandmark.map.setPointer(
              x:location.targetLandmarkEntry.x,
              y:location.targetLandmarkEntry.y
            );
            location.targetLandmark.travel();
          }
        )
      }
    }
  )  
}
