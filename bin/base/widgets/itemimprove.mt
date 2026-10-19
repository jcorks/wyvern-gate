@:windowEvent = import(module:'core/windowevent.mt');
@:world = import(module:'base/world.mt');
@:canvas = import(module:'core/graphics/canvas.mt');
@:random = import(module:'core/random.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:pickItem = import(module:'base/widgets/pickitem.mt');
@:animateMultiBar = import(:'base/widgets/animatemultibar.mt');
@:ImprovementStyle = import(:'base/item/improvementstyle.mt');
@:Item = import(:'base/item.mt');

@:expFromItem::(item) {
  @exp = item.equipMod.sum + item.equipModBase.sum*50;
  if (exp < 35) exp = 35;  
  return exp;
}

@:generateClientEXPUp ::(item, style) {
  @:exp = expFromItem(item);
  @:out = {};
  foreach(['ATK', 'INT', 'DEF', 'SPD', 'DEX']) ::(k, name) {
    out[name] = ((style.stats[name] / 100.0) * exp)->ceil;
  }
  return out;
}

@:generateClients ::(item, itemOther, style) {
  @:expUp = generateClientEXPUp(item:itemOther, style);
  @:clients = [];
  @:curStats = item.improvement.stats;
  foreach(['ATK', 'INT', 'DEF', 'SPD', 'DEX']) ::(k, name) {
    clients->push(:{
      stat: name,
      title: name + ' (+' + curStats[name] +')',
      from: item.improvement.getExp(:name),
      to : item.improvement.getExp(:name) + expUp[name],
      max: item.improvement.getExpToNext(:name)
    }); 
  }
  return clients;
}

@:addExpAnimated::(item, user, other, clients, onDone, style) {
  breakpoint();
  
  
  animateMultiBar.widget(
    clients, 
    onGetPauseFinish ::<- true,
    pauseStart : true,

    onGetCaption      ::<- item.name,
    onGetSubcaption   ::<- '',
    onGetSubsubcaption::<- '                  ',
    
    onGetLeftWeight::<- 0.5,
    onGetTopWeight::<- 0.5,
    onCompleteValue ::(client) {
      item.improvement.levelUp(stat:clients[client].stat)
      style.onLevel(item, stat:clients[client].stat);
      user.recalculateStats();
      clients[client].to -= 100;
      @:name = clients[client].stat
      clients[client].title = name + ' (+' + item.improvement.stats[name] +')'
      if (clients[client].to < 0)
        clients[client].to = 0;
      return {
        from: 0,
        to: clients[client].to,
        max: 100,
      }
    },
    
    onFinish::(client, value) {
      item.improvement.setExp(stat:clients[client].stat, exp:value)
    }
  );
  
  windowEvent.queueCustom(
    onEnter ::{
      onDone()
    }
  );

}


@:improve::(item, user, style) {

  @:party = import(module:'base/world.mt').party;
  @:itemFilter = ::(value) <- value.material == item.material && value != item;
          
  @:others = party.inventory.items->filter(by:itemFilter);
  when(others->keycount == 0) ::<= {
    windowEvent.queueMessage(
      text: 'The party has no other items that are of the material ' + item.material.name
    );
  }
  @:itemSrc = item; 
  @itemOther;
  pickItem(
    prompt: 'Choose an item to use as material.',
    tabbed: true,
    leftWeight: 1.0,
    inventory: party.inventory.clone(:itemFilter),
    canCancel: true,
    showRarity: false,
    showPrices: false,
    keep : true,
    
    renderable : {
      render ::{
        canvas.renderTextFrameGeneral(
          lines: animateMultiBar.generateLines(:generateClients(item:itemSrc, itemOther, style)),
          leftWeight: 0
        )
      }
    },
    onHover ::(item) {
      itemOther = item;
    },
    
    onPick::(item) {
      @:other = item;
      item = itemSrc;
      windowEvent.queueChoices(
        leftWeight: 0.5,
        topWeight: 0.5,
        prompt: other.name,
        colorHints : Item.toColorHints(:other),
        canCancel : true,
        keep:true,
        choices: [
          'Check',
          'Sacrifice'
        ],
        onChoice::(choice) {
          when (choice == 0) empty;        
          when (choice == 1) other.describe();
          when (choice == 2) ::<= {
            windowEvent.jumpToTag(name:'pickItem', goBeforeTag:true);
            windowEvent.queueAskBoolean(
              colorHints : {...Item.toColorHints(:item), ...Item.toColorHints(:itemOther)},
              prompt: 'Use ' + other.name + ' to give EXP to ' + item.name + '?',
              onChoice::(which) {
                when(which == false) empty;           
                    
                party.inventory.remove(item:other);
                
                addExpAnimated(
                  item,
                  user,
                  other,
                  style,
                  clients: generateClients(item, itemOther:other, style),
                  onDone ::{
                    windowEvent.queueAskBoolean(
                      prompt: 'Improve again?',
                      onChoice::(which) {
                        when (which == false) empty;
                        improve(item, user, style);
                      }
                    );
                  }
                );
              }

            ); 
          }
        }
      );
      /*
      @:other = item;
      item = itemSrc;

      windowEvent.queueMessage(
        text: 'Once complete, this will destroy ' + other.name + '.'
      );


      
      */       
    }
  );
}

@:statToStars = ::(stat) {
  @:stars = [];
  for(0, (stat/100)*7) ::(i) {
    stars->push(:'*');
  }
  return String.combine(:stars);
}

@:pickStyle ::(onFinish) {
  @:party = import(module:'base/world.mt').party;
  windowEvent.queueMessage(
    text: 'When improving an item, an improvement style must be chosen.'
  );
  @hovered
  windowEvent.queueChoices(
    prompt: 'Known styles:',
    leftWeight: 1.0,
    choices : party.improvementStyles->map(::(value) <- ImprovementStyle.find(:value).name),
    onHover::(choice) {
      hovered = party.improvementStyles[choice-1];
    },
    onChoice::(choice) {
      onFinish(:ImprovementStyle.find(:hovered));
    },
    canCancel: true,
    renderable : {
      render ::{
        @:style = ImprovementStyle.find(:hovered);
        canvas.renderTextFrameGeneral(
          leftWeight: 0.0,
          maxWidth: (canvas.width/3)->floor,
          lines : [
            'Style: ' + style.name,
            '',
            style.description,
            if (style.expMultiplier != 1) 'EXP Boost:' + (style.expMultiplier*100)->floor + '%' else '',
            ... ::<= {
              @:out = [];
              foreach(StatSet.NAMES) ::(k, name) {
                @:val = style.stats[name];
                if (val != empty && val != 0) {
                  out->push(:name + ': ' + statToStars(:val));
                }
              }
              return out;
            }
          ]
        );
      }
    }
      
  );
}


return ::(user, item, inBattle) {
  @:party = import(module:'base/world.mt').party;

  when(item.material == empty) ::<= {
    windowEvent.queueMessage(
      text: 'Only items with a specified material can be improved.',
      colorHints: Item.toColorHints(:item)
    );                                              
  }
  
  when(item.needsAppraisal)
    windowEvent.queueMessage(
      text: 'The chaotic nature of this item prevents improvement. Appraisal will help solidify its existence.'
    );                                              
  
  
  when (user != empty && !party.isMember(entity:user)) ::<= {
    windowEvent.queueMessage(
      text: user.name + '\'s ' + item.name + ' can only be improved if they\'re in the party.',
      colorHints: Item.toColorHints(:item)
    );                                    
  }
  
  if (inBattle == true) ::<= {
    @:complainer = random.pickArrayItem(list:party.members->filter(by::(value) <- value != user));
    @:Personality = import(module:'base/entity/personality.mt');
    @:personality = complainer.personality;
    windowEvent.queueMessage(
      speaker: complainer.name,
      text: '"' + random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.INAPPROPRIATE_TIME]) + '"'
    );            
  }
  
  when(item.improvement.left == 0) ::<= {
    windowEvent.queueMessage(
      text: item.name + ' cannot be improved any further.',
      colorHints: Item.toColorHints(:item)
    );                        
  }
  
  windowEvent.queueMessage(
    text: item.name + ' can be improved by attempting to combine it with another item of the same material. Once the process is complete, the other item is lost, and this item is given EXP. Once enough EXP is accumulated, the item improved will gain additional base stats.',
      colorHints: Item.toColorHints(:item)
  );
  
  windowEvent.queueAskBoolean(
    prompt:'Improve ' + item.name + '?',
    colorHints: Item.toColorHints(:item),
    onChoice::(which) {
      when(which == false) empty; 
      pickStyle(onFinish::(style) {
        improve(item, user, style)
      })
    }
  );
}
