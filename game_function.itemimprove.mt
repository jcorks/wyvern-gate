@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:world = import(module:'game_singleton.world.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:random = import(module:'game_singleton.random.mt');
@:StatSet = import(module:'game_class.statset.mt');


@:levelUp::(item, user, onDone) {
  @:statChoices = [
    'ATK',
    'INT',
    'DEF',
    'SPD',
    'DEX'
  ];         


  windowEvent.queueChoices(
    prompt: 'Choose a stat to improve.',
    choices: [...statChoices]->map(to:::(value)<- value + ' (+' + item.equipModBase[value] + ')'),
    onChoice::(choice) {
      when(choice == 0) empty;
      @stat = statChoices[choice-1];

      


      world.accoladeIncrement(name:'itemImprovements');                    
                    
      @:oldStats = item.equipModBase;
      @:newStats = StatSet.new();
      @:state = oldStats.save();
      state[stat] += 1;
      newStats.load(serialized:state);
      
      oldStats.printDiff(
        other:newStats,
        prompt: 'New stats: ' + item.name
      );
      
      item.equipModBase.load(serialized:newStats.save());
      
      if (user != empty) ::<= {
        @:oldStats = StatSet.new();
        @equiper = user;
        oldStats.load(serialized:equiper.stats.save());
        
        @slot = equiper.unequipItem(item, silent:true);
        equiper.equip(item, slot, silent:true);
        
        oldStats.printDiff(
          other: equiper.stats,
          prompt: equiper.name + ': New stats'
        )
      }   
      
      windowEvent.queueCustom(
        onEnter :: {
          onDone();
        }
      );

    }
  );

}


@:addExpAnimated::(item, user, other, exp, onDone) {
  @remainingForLevel = item.improvementEXPtoNext - item.improvementEXP;
  
  
  @:animateBar = import(:'game_function.animatebar.mt');
  @current = 0;
  animateBar(
    from: item.improvementEXP,
    to:   item.improvementEXP + exp,
    max:  item.improvementEXPtoNext,
    
    onGetPauseFinish:: <- true,
    onFinish ::{  
      @:remaining = exp - (item.improvementEXPtoNext - item.improvementEXP);
      @:oldLevel = item.improvements;
      item.improve(:exp);      
      when (oldLevel != item.improvements) ::<= {
        windowEvent.queueMessage(
          text: 'Item: Level up!'
        );
        windowEvent.queueCustom(
          onEnter :: {      
            levelUp(
              item : item,
              user : user,
              onDone :: {
                addExpAnimated(item, other, exp:remaining, onDone);
              }
            );
          }
        );
      }
      windowEvent.queueCustom(
        onEnter :: {
          onDone();
        }
      );
         
    },
    
    onGetCaption      ::<- 'Item level: ' + item.improvements,
    onGetSubcaption   ::<- 'Exp to next level: ' + (remainingForLevel - (current - item.improvementEXP)),
    onGetSubsubcaption::<- '                  +' + (exp - (current - item.improvementEXP)),
    
    onGetLeftWeight::<- 0.5,
    onGetTopWeight::<- 0.5,
    
    onNewValue ::(value) {
      current = value->ceil;
    }
  );
}


@:improve::(item, user) {
  @:party = import(module:'game_singleton.world.mt').party;
          
  @:others = party.inventory.items->filter(by:::(value) <- value.material == item.material && value != item);
  when(others->keycount == 0) ::<= {
    windowEvent.queueMessage(
      text: 'The party has no other items that are of the material ' + item.material.name
    );
  }
          

  
  windowEvent.queueChoices(
    prompt: 'Choose an item to use as material.',
    choices:[...others]->map(to:::(value) <- value.name),
    canCancel:true,
    onChoice::(choice) {
      when (choice == 0) empty;
      @:other = others[choice-1];
      windowEvent.queueMessage(
        text: 'Once complete, this will destroy ' + other.name + '.'
      );

      @exp = other.equipMod.sum + other.equipModBase.sum*50;
      if (exp < 35) exp = 35;
      windowEvent.queueAskBoolean(
        prompt: 'Use ' + other.name + ' to give ' + exp + ' EXP to ' + item.name + '?',
        onChoice::(which) {
          when(which == false) empty;           
              
          party.inventory.remove(item:other);
          
          addExpAnimated(
            item,
            user,
            other,
            exp,
            onDone ::{
              windowEvent.queueAskBoolean(
                prompt: 'Improve again?',
                onChoice::(which) {
                  when (which == false) empty;
                  improve(item);
                }
              );
            }
          );
        }
      );                
    }
  
  );
}



return ::(user, item, inBattle) {
  @:party = import(module:'game_singleton.world.mt').party;

  when(item.material == empty) ::<= {
    windowEvent.queueMessage(
      text: 'Only items with a specified material can be improved.'
    );                                              
  }
  
  
  @:StatSet = import(module:'game_class.statset.mt'); 
  when (!party.isMember(entity:user)) ::<= {
    windowEvent.queueMessage(
      text: user.name + '\'s ' + item.name + ' can only be improved if they\'re in the party.'
    );                                    
  }
  
  if (inBattle == true) ::<= {
    @:complainer = random.pickArrayItem(list:party.members->filter(by::(value) <- value != user));
    @:Personality = import(module:'game_database.personality.mt');
    @:personality = complainer.personality;
    windowEvent.queueMessage(
      speaker: complainer.name,
      text: '"' + random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.INAPPROPRIATE_TIME]) + '"'
    );            
  }
  
  when(item.improvementsLeft == 0) ::<= {
    windowEvent.queueMessage(
      text: item.name + ' cannot be improved any further.'
    );                        
  }
  
  windowEvent.queueMessage(
    text: item.name + ' can be improved by attempting to combine it with another item of the same material. Once the process is complete, the other item is lost, and this item is given EXP. Once enough EXP is accumulated, the item improved will gain additional base stats.'
  );
  
  windowEvent.queueAskBoolean(
    prompt:'Improve ' + item.name + '?',
    onChoice::(which) {
      when(which == false) empty; 
      improve(item, user);
    }
  );
}
