@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Item = import(module:'game_mutator.item.mt');
@:buySomethinWillYa = import(:'game_function.buyinventory.mt');
@:random = import(module:'game_singleton.random.mt');
@:Inventory = import(module:'game_class.inventory.mt');

@:rankToString = ::<= {
  @:table = [
    'E',
    'D',
    'C',
    'B',
    'A',
    'S',
    'SS',
    'X'
  ];
  return ::(rank) <- table[rank];
};

@:teamInfo::(party) {
  windowEvent.queueDisplay(
    lines : [
      'Team: ' + party.guildTeamName,
      'Rank: ' + rankToString(:party.guildRank),
      'EXP to next rank: ' + party.guildEXPtoNext,
      'EXP total: ' + party.guildEXP
    ]
  );
}

@:rerollQuests ::(location) {
  if (location.data.quests == empty)
    location.data.quests = [];
  @:Quest = import(:'game_mutator.quest.mt');

    
  location.data.quests = random.scrambled(:location.data.quests);
  location.data.quests->setSize(:location.data.quests->size / 2);
  
  for(location.data.quests->size, 18) ::(i) {
    location.data.quests->push(value:
      Quest.new(
        landmark : location.landmark,
        issuer : location.data.guildmaster,
        rank : random.integer(from:0, to:Quest.RANK.X),
        base : Quest.database.getRandomFiltered(filter::(value) <- (value.traits & Quest.TRAITS.SPECIAL) == 0)
      )
    );
  }

  for(0, 2) ::(i) {
    location.data.quests->push(value:
      Quest.new(
        landmark : location.landmark,
        issuer : location.data.guildmaster,
        rank : 0,
        base : Quest.database.getRandomFiltered(filter::(value) <- (value.traits & Quest.TRAITS.SPECIAL) == 0)
      )
    );
  }
  
  location.data.quests = random.scrambled(:location.data.quests);


}


@:guildQuests::(location) {
  when (location.data.quests->size == 0)
    windowEvent.queueMessage(
      speaker : location.data.guildmaster.name,
      text : '"Looks like there aren\'t any postings today. Come back tomorrow, I\'m sure there will be some then."'
    );
  @:world = import(module:'game_singleton.world.mt');
  @quests = location.data.quests;
  @which;
  windowEvent.queueChoices(
    leftWeight: 1,
    topWeight: 1,
    prompt: 'Quests:',
    canCancel: true,
    keep: true,
    onGetChoices ::<- quests->map(::(value) <- value.name),
    onHover ::(choice) {
      which = choice;
    },
    renderable : {
      render ::{
        quests[which-1].renderPrompt(showCompleteness:false, leftWeight:0, topWeight: 0.5);
      }
    },
    onChoice::(choice) {
      @:quest = quests[choice-1];
      
      when (quest.rank > world.party.guildRank) 
        windowEvent.queueMessage(
          text: 'The party\'s rank is too low to accept this quest.'
        );
      
      windowEvent.queueAskBoolean(
        prompt: 'Accept ' + quest.name + '?',
        onChoice::(which) {
          when(which == false) empty;
          
          
          if (world.party.acceptQuest(quest, island:world.island, issuer:location.data.guildmaster)) ::<= {
            location.data.quests->remove(:
              location.data.quests->findIndex(:quest)
            );
            
            windowEvent.queueMessage(
              speaker: location.data.guildmaster.name,
              
              text: '"' + random.pickArrayItem(:[
                'I figured you\'d take that one.',
                'A fine quest.',
                'No one has taken that one for a while.',
                'A challenge fit for you, I\'m sure.'
              
              ]) + ' Come back to turn it in when it\'s complete for your reward."'
            );
          }
          
        }
      );
    }
  );

}






@:turnInQuests::(location) {
  @:world = import(module:'game_singleton.world.mt');
  
  when(world.party.quests->size == 0)
    windowEvent.queueMessage(
      text: 'The party has no active quests.'
    )


  @quests = world.party.quests->filter(::(value) <- value.isComplete);

  when(quests->size == 0)
    windowEvent.queueMessage(
      text: 'No taken quests are currently complete.'
    )

  @which;
  windowEvent.queueChoices(
    leftWeight: 1,
    topWeight: 1,
    prompt: 'Quests to turn in:',
    keep: true,
    canCancel: true,
    onGetChoices :: {
      quests = world.party.quests->filter(::(value) <- value.isComplete);
      return quests->map(::(value) <- value.name)
    },
     
    onHover ::(choice) {
      which = choice;
    },
    renderable : {
      render ::{
        quests[which-1].renderPrompt(showCompleteness:true, leftWeight:0, topWeight: 0.5);
      }
    },
    onChoice::(choice) {
      @:quest = quests[choice-1];

      
      windowEvent.queueAskBoolean(
        prompt: 'Turn in ' + quest.name + '?',
        onChoice::(which) {
          when(which == false) empty;
          when (quest.issuerID != location.data.guildmaster.worldID) ::<= {
            windowEvent.queueMessage(
              speaker : location.data.guildmaster.name,
              text: '"Hmm, it looks like this is from a different quest guild. It\'s against policy to turn in a quest in a place other than where you got it, you see. Too many counterfeits, and it makes bookkeeping a mess."' 
            );
          }
          quest.turnIn(issuer:location.data.guildmaster);

          windowEvent.queueCustom(
            onEnter :: {
              world.party.animateGainGuildEXP(
                exp : [
                    35,
                    55,
                    90,
                    120,
                    170,
                    250,
                    340,
                    470,
                    600,
                    800,
                    1500,              
                ][quest.rank],
                onDone ::{
                  location.data.guildNeedsRestock = true;
                  world.party.quests->remove(key:world.party.quests->findIndex(:quest));
                }
              );
            }
          );
        }
      );
    }
  );

}


@:guildShop::(location) {
  @:rerollShop ::(inventory){
    inventory.clear();
    for(0, 15)::(i) {
      // no weight, as the value scales
      @:item = Item.new(
        base:Item.database.getRandomFiltered(
          filter:::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
                    && value.tier <= location.landmark.island.tier &&
                    value.hasTraits(
                      Item.TRAIT.HAS_QUALITY |
                      Item.TRAIT.METAL
                    ) &&
                    (
                      ((value.traits & Item.TRAIT.WEAPON) != 0) ||
                      ((value.traits & Item.TRAIT.SHIELD) != 0) ||
                      (value.equipType == Item.TYPE.ARMOR)
                    )
                      
        ),
        rngEnchantHint:true,
        
        
        
        qualityHint : random.pickArrayItem(:[
          'base:robust',
          'base:quality',
          'base:light',
          'base:reinforced',
          'base:durable',
          'base:standard',
          'base:masterwork'
        ]),
        
        materialHint : random.pickArrayItem(:[
          'base:copper',
          'base:steel',
          'base:iron',
          'base:crystal',
          'base:tungsten',
          'base:mythril',
          'base:adamantine',
          'base:quicksilver',
          'base:dragonglass',
          'base:composite',
          'base:sunstone',
          'base:moonstone'
        ])
      );
        
      // tag for later :3
      item.data.fromGuild = true;

      inventory.add(item);
    }   
  }

  if (location.data.guildInventory == empty) ::<= {
    @:inv = Inventory.new();
    location.data.guildInventory = inv;
    location.data.guildNeedsRestock = true;
  }
  
  if (location.data.guildNeedsRestock) ::<= {
    windowEvent.queueMessage(
      speaker: 'Guild Shopkeep',
      text: '"We have new equipment in stock."'
    );
    rerollShop(inventory:location.data.guildInventory);           
    location.data.guildNeedsRestock = false;
  }
  
  buySomethinWillYa(
    inventory:location.data.guildInventory
  );
}


@:mainMenu::(location, party) {
  @:choices = [
    ::<- teamInfo(:party),
    ::<- guildShop(:location),
    ::<- guildQuests(:location),
    ::<- turnInQuests(:location)
  ];
  
  
  
  windowEvent.queueChoices(
    prompt: 'Guild menu',
    canCancel : true,
    keep : true,
    choices : [
      'Team info',
      'Guild Shop',
      'Available quests',
      'Turn in quests',
    ],
    onChoice::(choice) {
      choices[choice-1]();
    }
  );
}


@:welcome ::(location) {
  if (location.data.guildmaster == empty) ::<= {
    location.data.guildmaster = location.landmark.island.newInhabitant(
      professionHint : 'base:guard',
      levelHint: 20
    );
    @:gm = location.data.guildmaster;  
    gm.adventurous = false;  
    gm.name = 'Guildmaster ' + gm.name;

    windowEvent.queueMessage(
      speaker:gm.name,
      text: '"Welcome to the quest guild. I am ' + gm.name + '."'
    );
    rerollQuests(location);
  } else ::<= {
    windowEvent.queueMessage(
      speaker:location.data.guildmaster.name,
      text: '"Welcome back."'
    );
  }
}


@:join ::(location, party) {
  @:gm = location.data.guildmaster;  
  @:world = import(module:'game_singleton.world.mt');
  
  when (world.accoladeCount(:'knockouts') < 5) ::<= {
    windowEvent.queueMessage(
      speaker:gm.name,
      text: '"Hmmm... We tend to look for guild members that can adapt to tough situations. Come back when you have a bit more battle experience."'
    );
  }
  
  if (location.data.askedJoin == empty) ::<= {
    location.data.askedJoin = true;
    windowEvent.queueMessage(
      speaker:gm.name,
      text: '"Oh...! it would seem that you have a bit of adventure in your spirit. How about joining the quest guild?"'
    );

    windowEvent.queueMessage(
      speaker:gm.name,
      text: '"As a guild team, you would be able to fulfill requests posted and get certain perks as you raise your guild team\'s rank. Of course, when you start out you\'ll only get the lowest-ranked quests..."'
    );
    windowEvent.queueMessage(
      speaker:gm.name,
      text: '"People post all sorts of quests at the quest guild, often with quite nice rewards. Not to mention, the guild has access to some services that would be hard to acquire otherwise."'
    );

    windowEvent.queueMessage(
      speaker:gm.name,
      text: '"There is a catch: registration costs 300G. However, if that\'s fine, I\'m sure you\'ll make it back through questing quite swiftly."'
    );  

  } else ::<= {
    windowEvent.queueMessage(
      speaker:gm.name,
      text: '"Did you reconsider the offer to join the quest guild?"'
    );  
  }
  
  when (party.inventory.gold < 300)
    windowEvent.queueMessage(
      text: 'The party cannot afford to join the quest guild.'
    );
  

  windowEvent.queueAskBoolean(
    prompt: 'Join quest guild for 300G?',
    onChoice::(which) {
      when(which == false) ::<= {
        windowEvent.queueMessage(
          speaker:gm.name,
          text: '"I understand! Feel free to come back any time to rediscuss you joining."'
        );          
      }
      
      party.addGoldAnimated(
        amount: -300,
        onDone ::{
          windowEvent.queueMessage(
            speaker:gm.name,
            text: '"Ah, before we continue, your guild team must have a name to register."'
          );            
          
          @:name = import(:"game_function.name.mt");
          name(
            prompt: 'Enter your guild team name:',
            onDone::(name) {
              party.setGuildTeamName(name);

              windowEvent.queueMessage(
                speaker:gm.name,
                text: '"Allow me to officially introduce you to the guild, team ' + party.guildTeamName + '."'
              );          
              mainMenu(location, party);
            }
          )
        }
      )
    }
  );
  
  
}


return ::(location, party) {
  welcome(location);
  
  // not in a guild yet
  when (party.guildRank == -1)
    join(location, party);

  mainMenu(location, party);
}
