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

@:generateStats ::(state) {
  @stats = StatSet.new();
  
  // first get chains. singles are also in the chains, but will have a size of 1
  @chains = [];
  ::<= {
    @curChain = [];;
    foreach(state.slots) ::(k, v) {
      when (v.inset == empty) ::<= {
        // failed to create chain. Added each as 
        // standalone chains
        foreach(curChain) ::(k, index) {
          chains->push(:[index]);
        }
        curChain = [];
      }
      
      // chain is done
      when(v.connectNext == false) ::<= {
        chains->push(:curChain);
        curChain = [];
      }
      
      curChain->push(:[k]);
    }
    if (curChain->size > 0) ::<= {
      chains->push(:curChain);
      curChain = [];
    }
  }
  
  
  foreach(chains) ::(k, v) {
    when(v->size == 1) ::<= {
      stats.add(:state.slots[v[0][0]].inset.inletStats);
    }
    
    @:chainStats = StatSet.new();
    foreach(v) ::(k, index) {
      @:s = state.slots[index].inset.inletStats.save();
      foreach(s) ::(name, stat) {
        if (stat < 0)
          s[name] = 0
      }
      
      @:s_off = StatSet.new();
      s_off.load(:s);
      chainStats.add(:s_off);
    }
    stats.add(:chainStats);
  }
  return stats;
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
      
      defaultLoad::(size) {
        for(0, size) ::(i) {
          state.slots->push(:makeSlot())
        }
      },
      
      renderSet :: <-
        renderField(state, selected:-1)
      ,
      
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
          pickItem(
            inventory: inv,
            filter,
            topWeight: 0.5,
            prompt: 'Compatible Gems',
            canCancel : true,
            keep : false,
            renderable : {
              render ::{
                when(selectedItem == empty) empty;
                canvas.renderTextFrameGeneral(
                  leftWeight: 0,
                  topWeight : 0.5,
                  lines : selectedItem.inletGetDescriptionLines()
                );
              }
            },
            onHover ::(item) {
              selectedItem = item;
            },
            onPick ::(item) {
              if (slot.inset)
                inv.add(:slot.inset);
              inv.remove(:item);
              slot.inset = item;
              
              windowEvent.queueMessage(
                text:user.name + ' placed the ' + item.name + ' into the ' + onItem.name + '.'
              );
              
              if (user.hasEquipped(:item))
                user.checkStatsChanged();
              
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

            windowEvent.queueChoices(
              prompt: if (slot.inset != empty) slot.inset.name else "Empty Slot: " + InletSet.SLOT_NAMES[slot.shape],
              canCancel: true,
              keep:false,
              leftWeight: 1,
              renderable : {
                render::{
                  when (slot.inset == empty) empty;
                  this.renderSlotInfo(:slot);
                }
              },  
              choices : if(slot.inset == empty) ['Place'] else ['Swap', 'Check'],
              onChoice ::(choice) {
                when(choice == 1) equipInlet(slot);
                
                
                // check
                when (choice == 2) ::<= {
                  when (slot.inset == empty)
                    windowEvent.queueMessage(
                      text: 'This gem slot is currently empty.'
                    );
                    
                  windowEvent.queueMessage(
                    text : slot.inset.inletGetDescriptionLines()
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
        windowEvent.queueMessage(
          renderable : {
            render ::{
              renderField(
                state : state
              )
            }
          },
          leftWeight: 0.5,
          topWeight: 1,
          speaker : 'Gem inlets:',
          text : 
            '' + (state.slots->filter(::(value) <- value.inset != empty)->size) + ' / ' + state.slots->size + ' slots in use.'
          
        );
      },
      
      stats : {
        get::<- generateStats(:state)
      },
    }
  }
);
return InletSet;
