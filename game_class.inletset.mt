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
@:class = import(module:'Matte.Core.Class');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:random = import(module:'game_singleton.random.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:Inventory = import(module:'game_class.inventory.mt');


@:SLOTS = {
  ROUND : 0,
  TRIANGLE : 1,
  SQUARE : 2
}

@:SLOT_CHARS = {
  (SLOTS.ROUND):    'o',
  (SLOTS.TRIANGLE): '^',
  (SLOTS.SQUARE):   '▓'
}


@:makeSlot ::<- {
  shape : random.pickArrayItem(:SLOTS->values),
  connectNext : random.flipCoin(),
  inset : empty
}


@:renderSlot ::(x, y, state, i, selected) {
  @:self = state.slots[i];
  @:prev = state.slots[i-1];
  @:next = state.slots[i+1];

  canvas.movePen(x:x  , y:y  );
  canvas.drawChar(text:'┌');

  canvas.movePen(x:x+1, y:y  );
  canvas.drawChar(text:'─');

  canvas.movePen(x:x+2, y:y  );
  canvas.drawChar(text:'┐');


  canvas.movePen(x:x  , y:y+1);

  if (prev != empty && prev.connectNext == true)
    canvas.drawChar(text:'┐')
  else
    canvas.drawChar(text:'│');

  canvas.movePen(x:x+2, y:y+1);
  if (next != empty && self.connectNext == true) ::<= {
    canvas.drawChar(text:'└');
    canvas.movePen(x:x+3, y:y+1);
    canvas.drawChar(text:'─');
    canvas.movePen(x:x+4, y:y+1);
    canvas.drawChar(text:'─');

  } else
    canvas.drawChar(text:'│');


  canvas.movePen(x:x  , y:y+2);
  canvas.drawChar(text:'└');

  canvas.movePen(x:x+1, y:y+2);
  canvas.drawChar(text:'─');

  canvas.movePen(x:x+2, y:y+2);
  canvas.drawChar(text:'┘');


  canvas.movePen(x:x+1, y:y+1);
  canvas.drawChar(text:
    if (self.inset != empty)
      match(self.shape) {
        (SLOTS.ROUND):    'o',
        (SLOTS.TRIANGLE): '^',
        (SLOTS.SQUARE):   '▓',
        default :         '?'
      }
    else
      ' '
  )
  
  if (selected) ::<= {
    canvas.movePen(x:x+1, y:y+3);
    canvas.drawChar(text:'^');
    canvas.movePen(x:x+1, y:y+4);
    canvas.drawChar(text:'|');
  
  }
}

@:renderField ::(state, selected) {
  @:width = (5*state.slots->size);
  @:height = 7;
  @x = (canvas.width / 2 - width/2)->floor;
  @:y = 3

  canvas.renderFrame(
    top: y - 2,
    left: x - 2,
    width: width+2,
    height: height+1
  );


  foreach(state.slots) ::(k, v) {
    renderSlot(x, y, state, i:k, selected:selected == k);
    x += 5;
  }
}



@:InletSet = LoadableClass.create(
  name: 'Wyvern.InletSet',
  statics : {
    SLOTS : {get::<-SLOTS},
    SLOT_NAMES : {get ::<- [
      'Round',
      'Triangular',
      'Square'
    ]},
    SLOT_CHARS : {get ::<- SLOT_CHARS},

  },
  items : {
    slots  : empty
  },
  define:::(this, state) {
    this.interface = {
      initialize ::{
        state.slots = [];
      },
      
      size : {
        get ::<- state.slots->size
      },
      
      gems : {
        get :: <- state.slots->filter(::(value) <- value.inset != empty)->map(::(value) <- value.inset)        
      },
      
      defaultLoad::(size) {
        for(0, size) ::(i) {
          state.slots->push(:makeSlot())
        }
      },
      
      renderSet :: <-
        renderField(state, selected:-1)
      ,
      
      fillInletSlots ::(count) {
        @:Item = import(module:'game_mutator.item.mt');
        ::? {
          for(0, state.slots->size) ::(i) {
            when(count == 0) send();
            when (state.slots[i].inset != empty) empty;             
            count -= 1
            @:inlet = Item.new(
              base:Item.database.find(:'base:inlet-gem'),
              forceNeedsAppraisal : false,
              data : {
                inletShape : state.slots[i].shape
              }
            )
            
            state.slots[i].inset = inlet;
          }
        }
      },
      
      equip ::(user, item, canCancel) {
        @:onItem = item;
        @:world = import(module:'game_singleton.world.mt')
        @:inv = world.party.inventory;
        
        @:equipInlet ::(slot) {
          @:filter = ::(value) <- value.inletShape == slot.shape;
          @:items = inv.items->filter(:filter);
          
          when (items->size == 0)
            windowEvent.queueMessage(
              text: 'The party has no gems that fit this slot. A ' + InletSet.SLOT_NAMES[slot.shape] + '-shaped gem is required.'
            )
            
          @:pickItem = import(:'game_function.pickitem.mt');
          @selectedItem;
          @:Effect = import(module:'game_database.effect.mt');
          @:Arts = import(module:'game_mutator.arts.mt');
          pickItem(
            inventory: inv,
            filter,
            leftWeight : 0.5,
            topWeight: 0.0,
            prompt: 'Compatible Gems',
            canCancel : true,
            keep : true,
            renderable : {
              render ::{
                canvas.renderTextFrameGeneral(          
                  lines : 
                    if (selectedItem.inletArt != empty)
                      [
                        'Grants Art:',
                        selectedItem.inletArt.base.name
                      ]
                    else 
                      [
                        'Grants Effect:',
                        Effect.find(:selectedItem.inletEffect).name                      
                      ],
                  topWeight: 1
                );      
              }
            },
            onHover ::(item) {
              selectedItem = item;
            },
            onPick ::(item) {
              windowEvent.queueChoices(
                prompt: item.name + '...',
                choices : ['Equip', 'Check'],
                canCancel: true,
                keep: false,
                onChoice::(choice) {
                
                  // equip
                  when(choice == 1) ::<= {
                    @:old = slot.inset;
                    @:oldGemArts = user.gemArts
                    if (slot.inset)
                      inv.add(:slot.inset);
                    inv.remove(:item);
       
                    slot.inset = item;
                    
                    windowEvent.queueMessage(
                      text:user.name + ' placed the ' + item.name + ' into the ' + onItem.name + '.'
                    );

                    if (user.hasEquipped(:onItem)) {
                      user.notifyGemSwap(oldGemArts);
                      user.recalculateStats();
                    }                
                  }


                  when(choice == 2) ::<= {
                    item.describe();              
                  }

                  
                }
              )
            }
          );
          
        }

        
        
        @selected
        windowEvent.queueChoices(
          horizontalFlow: true,
          hideWindow : true,
          keep:true,
          choices : state.slots->map(::(value) <- ''),
          onHover ::(choice) {
            selected = choice-1;
          },
          canCancel: if (canCancel) canCancel else true,
          
          onChoice::(choice) {
            @:slot = state.slots[selected];

            when(slot.inset == empty)
              equipInlet(slot);
              
            windowEvent.queueChoices(
              prompt: slot.inset.name,
              canCancel: true,
              keep:false,
              leftWeight: 0.5,
              topWeight: 0.7,
              renderable : {
                render::{
                  when (slot.inset == empty) empty;
                  this.renderSlotInfo(:slot);
                }
              },  
              choices : ['Swap', 'Remove', 'Check'],
              onChoice ::(choice) {
                when(choice == 1) equipInlet(slot);
                

                when (choice == 2) ::<= {
                 @:oldGemArts = user.gemArts
     
                  if (slot.inset)
                    inv.add(:slot.inset);
                  slot.inset = empty;
                  if (user.hasEquipped(:item))
                    user.recalculateStats();
                  user.notifyGemSwap(oldGemArts);
                }

                
                // check
                when (choice == 3) ::<= {
                  when (slot.inset == empty)
                    windowEvent.queueMessage(
                      text: 'This gem slot is currently empty.'
                    );
                    
                  windowEvent.queueMessage(
                    text : String.combine(:
                      (slot.inset.inletGetDescriptionLines())->map(::(value) 
                        <- value + '\n'
                      )
                    )
                  );
                }
                  
              }
            );
          },
          
          renderable : {
            render ::{
              renderField(state, selected);            

              /*canvas.renderTextFrameGeneral(
                leftWeight: 0.5,
                topWeight: 1,
                title : 'Gems: Stats (Base)',
                lines : this.stats.description->split(token:'\n')
              )*/

              this.renderSlotInfo(slot:state.slots[selected]);

            }
          }
        );
      },
      
      renderSlotInfo ::(slot) {

        canvas.renderTextFrameGeneral(
          leftWeight: 0.5,
          topWeight: 1,
          title : 'Gem slot',
          lines : 
            if (slot.inset == empty) 
              [
                'Slot shape: ' + InletSet.SLOT_NAMES[slot.shape],
                '',
                'Slot is empty.'
              ] 
            else 
              [
                slot.inset.name,
                '',
                ...slot.inset.inletGetDescriptionLines()
              ]
        )      
      },
      
      queueShowBasic ::{
        @selected
        windowEvent.queueChoices(
          horizontalFlow: true,
          hideWindow : true,
          keep:false,
          choices : state.slots->map(::(value) <- ''),
          onHover ::(choice) {
            selected = choice-1;
          },
          canCancel: true,
          
          onChoice::(choice) {

          },
          
          renderable : {
            render ::{
              renderField(state, selected);            

              /*canvas.renderTextFrameGeneral(
                leftWeight: 0.5,
                topWeight: 1,
                title : 'Gems: Stats (Base)',
                lines : this.stats.description->split(token:'\n')
              )*/

              this.renderSlotInfo(slot:state.slots[selected]);

            }
          }
        );
      }
      
    }
  }
);
return InletSet;
