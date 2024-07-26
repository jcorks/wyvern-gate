@:pickItem = import(module:'game_function.pickitemprices.mt');
@:g = import(module:'game_function.g.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:correctA = import(module:'game_function.correcta.mt');


return ::(inventory, shopkeep) {
  @:world = import(module:'game_singleton.world.mt');
  @:party = world.party;
  @hoveredItem;
  pickItem(
    inventory,
    canCancel: true,
    leftWeight: 0.6,
    topWeight: 0.5,
    onGetPrompt:: <-  'Buy which? (current: ' + g(g:party.inventory.gold) + ')',
    goldMultiplier: (0.5 / 5),
    onHover ::(item) {
      hoveredItem = item;
    },
    header : ['Item', 'Price'],
    leftJustified : [true, false],
    
    renderable : {
      render ::{
        when(hoveredItem == empty) empty;
        canvas.renderTextFrameGeneral(
          title: 'Equip stats:',
          lines: hoveredItem.stats.descriptionRateLines,
          leftWeight: 0,
          topWeight: 0.5
        )
      }
    },
    
    onPick::(item) {
      when(item == empty) empty;
      @price = (item.price * (0.5 / 5))->ceil;
      
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
                  @currentEquip = user.getEquipped(slot);
                  
                  currentEquip.equipMod.printDiffRate(
                    prompt: '(Equip) ' + currentEquip.name + ' -> ' + item.name,
                    other:item.equipMod
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

