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
@:pickItem = import(module:'base/widgets/pickitem.mt');
@:g = import(module:'base/util/g.mt');
@:canvas = import(module:'core/graphics/canvas.mt');
@:windowEvent = import(module:'core/windowevent.mt');
@:correctA = import(module:'base/util/correcta.mt');
@:Item = import(module:'base/item.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:InletSet = import(:'base/item/inletset.mt');
@:Arts = import(module:'base/arts.mt');
@:Effect = import(module:'base/entity/effect.mt');

@:buy ::(item, price, shopkeep, inventory) {
  @:world = import(module:'base/world.mt');
  @:party = world.party;
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
}

@:sell ::(item, price, shopkeep, inventory){
  @:world = import(module:'base/world.mt');
  @:party = world.party;
  when ((item.base.traits & Item.TRAIT.KEY_ITEM) != 0)
    windowEvent.queueMessage(
      text:'You feel unable to give this away.'
    )
  when ((item.base.traits & Item.TRAIT.PRICELESS) != 0)
    windowEvent.queueMessage(
      speaker: shopkeep.name,
      text:'"I\'m unable to buy this from you.'
    )



  if (price < 1) ::<= {
    windowEvent.queueMessage(
      speaker: shopkeep.name,
      text:'"Technically, this is worthless, but I thought I\'d do you a favor and take it off your hands."'
    )
    world.accoladeEnable(name:'soldWorthlessItem');
    price = 1;
  }
  if (price > 9999) ::<= {
    windowEvent.queueMessage(
      speaker: shopkeep.name,
      text:'"This item is too expensive to sell to me. I can\'t even tell how much it\'s worth!"'
    )
    windowEvent.queueMessage(
      speaker: shopkeep.name,
      text:'"I\'d recommend trying to sell it at an Auction House. Most cities should have one."'
    )

    windowEvent.queueMessage(
      speaker: shopkeep.name,
      text:'"Alternatively, I can take it off your hands for 9,999G. Just be aware it is likely worth much more than that."'
    )


    price = 9999;
  }


  windowEvent.queueAskBoolean(
    prompt:'Sell the ' + item.name + ' for ' + g(g:price) + '?',
    onChoice::(which) {
      when(which == false) empty;

      world.accoladeIncrement(name:'sellCount');

      if (item.name->contains(key:'Wyvern Key of'))
        world.accoladeEnable(name:'gotRidOfWyvernKey');    


      if (price > 500) ::<= {
        world.accoladeEnable(name:'soldItemOver500G');
      }

      
      windowEvent.queueMessage(text: 'Sold the ' + item.name + ' for ' + g(g:price) + '.');

      party.addGoldAnimated(
        amount:price,
        onDone::{}
      );
      party.inventory.remove(item);              
      inventory.add(item);
    }
  )
}

return ::(inventory, shopkeep, onDone, sellMode) {
  if (sellMode == empty) sellMode = false;
  @:PRICE_MOD = if (sellMode) Item.SELL_PRICE_MULTIPLIER else Item.BUY_PRICE_MULTIPLIER
  @:world = import(module:'base/world.mt');
  @:party = world.party;
  @hoveredItem;
  pickItem(
    tabbed: true,
    inventory:if (sellMode) party.inventory else inventory,
    canCancel: true,
    leftWeight: 1,
    topWeight: 0.5,
    showPrices : true,
    ignorePriceCeiling : true,
    //onGetPrompt:: <-  'Buy which? (current: ' + g(g:party.inventory.gold) + ')',
    goldMultiplier: PRICE_MOD,
    onHover ::(item) {
      hoveredItem = item;
    },
    onGetFooter ::<- '(Party has: ' + g(:party.inventory.gold)+')',
    
    
    
    onCancel : if (onDone) onDone else empty,
    
    onPick::(item) {
      when(item == empty) empty;
      @price = (item.price * PRICE_MOD)->ceil;
      
      windowEvent.queueChoices(
        prompt: item.name,
        choices: if (!item.base.hasTraits(:Item.TRAIT.STRANGE_TO_EQUIP)) 
          [if (sellMode) 'Sell' else 'Buy', 'Check', 'Compare Equipment']
        else        
          [if (sellMode) 'Sell' else 'Buy', 'Check']
        ,
        canCancel: true,
        onChoice::(choice) {
          when(choice == 0) empty;
          
          match(choice-1) {
            // buy
            (0)::<= {

              (if (sellMode) sell else buy)(item, price, shopkeep, inventory)

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

