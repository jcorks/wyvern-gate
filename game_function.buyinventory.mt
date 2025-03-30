/*
  Wyvern Gate, a procedural, console-based RPG
  Copyright (C) 2025, Johnathan Corkery (jcorkery@umich.edu)

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
@:pickItem = import(module:'game_function.pickitem.mt');
@:g = import(module:'game_function.g.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:Item = import(module:'game_mutator.item.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:InletSet = import(:'game_class.inletset.mt');


return ::(inventory, shopkeep, onDone) {
  @:world = import(module:'game_singleton.world.mt');
  @:party = world.party;
  @hoveredItem;
  pickItem(
    tabbed: true,
    inventory,
    canCancel: true,
    leftWeight: 1,
    topWeight: 0.5,
    showPrices : true,
    //onGetPrompt:: <-  'Buy which? (current: ' + g(g:party.inventory.gold) + ')',
    goldMultiplier: Item.BUY_PRICE_MULTIPLIER,
    onHover ::(item) {
      hoveredItem = item;
    },
    header : ['Item', 'Price', ''],
    onGetFooter ::<- '(Party has: ' + g(:party.inventory.gold)+')',
    
    renderable : {
      render ::{
        when(hoveredItem == empty) empty;
        
        when (hoveredItem.inletStats != empty) ::<= {
          when(hoveredItem.inletEffect != empty) empty;
        
          canvas.renderTextFrameGeneral(
            title: 'Gem base stats:',
            lines: [
              'Shape: ' + InletSet.SLOT_NAMES[hoveredItem.inletShape],
              ...hoveredItem.inletStats.descriptionAugmentLines
            ],
            leftWeight: 0,
            topWeight: 0.5
          )
        }
        
        canvas.renderTextFrameGeneral(
          title: 'Summary:',
          lines: [
            'Stat boosts:',
            ...hoveredItem.stats.descriptionRateLines,
            ...([if (hoveredItem.inletSlotSet != empty)
              '' + hoveredItem.inletSlotSet.size + ' gem slot' + if (hoveredItem.inletSlotSet.size == 1) '.' else 's.'
            else 
              ''])
          ],
          leftWeight: 0,
          topWeight: 0.5
        )
      }
    },
    
    onCancel : if (onDone) onDone else empty,
    
    onPick::(item) {
      when(item == empty) empty;
      @price = (item.price * Item.BUY_PRICE_MULTIPLIER)->ceil;
      
      windowEvent.queueChoices(
        prompt: item.name,
        choices: ['Buy', 'Check', 'Compare Equipment'],
        canCancel: true,
        onChoice::(choice) {
          when(choice == 0) empty;
          
          match(choice-1) {
            // buy
            (0)::<= {
              when(world.party.inventory.isFull) ::<= {
                windowEvent.queueMessage(text: 'The party\'s inventory is full.');
              }
                
              world.accoladeIncrement(name:'buyCount');
              if (price < 1) ::<= {
                if (shopkeep != empty)
                  windowEvent.queueMessage(
                    speaker: shopkeep.name,
                    text:'"You really want this? It\'s basically worthless, but I\'ll still sell it to you if you want."'
                  )
                world.accoladeEnable(name:'boughtWorthlessItem');
                price = 1;
              }

              when (party.inventory.gold < price)
                windowEvent.queueMessage(text:'The party cannot afford this.');
              party.addGoldAnimated(
                amount:-price,
                onDone :: {
                  inventory.remove(item);

                  if (price > 2000) ::<= {
                    world.accoladeEnable(name:'boughtItemOver2000G');
                  }
                  
                  
                  windowEvent.queueMessage(text: 'Bought ' + correctA(word:item.name));
                  party.inventory.add(item);                
                }
              ) 
            },
            // check
            (1)::<= {
              item.describe();
            },
            // compare 
            (2)::<= {
              @:memberNames = [...party.members]->map(to:::(value) <- value.name);
              @:choice = windowEvent.queueChoices(
                prompt: 'Compare equipment for whom?',
                choices: memberNames,
                keep:true,
                canCancel: true,
                onChoice::(choice) {
                  @:user = party.members[choice-1];
                  @slot = user.getSlotsForItem(item)[0];

                  @:currentStats = user.stats.clone();
                  @:withEquip = user.statsIfEquippedInstead(item, slot);
                  @:lines = StatSet.diffToLines(stats:currentStats, other:withEquip);

                  windowEvent.queueDisplay(
                    prompt:user.name + ': If equipped...',
                    lines
                  );                        

                }
              );
            }  
          }   
        }
      );
    
    
    }
  );
}

