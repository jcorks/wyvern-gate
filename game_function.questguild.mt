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

@:guildQuests::(location) {
  windowEvent.queueMessage(
    speaker : location.data.guildmaster.name,
    text : '"Looks like there aren\'t any postings today."'
  );
}


@:guildShop::(location) {
  @:rerollShop ::(inventory){
    inventory.clear();
    for(0, 15)::(i) {
      // no weight, as the value scales
      inventory.add(item:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.isUnique == false 
                      && value.tier <= location.landmark.island.tier &&
                      value.hasQuality && value.hasMaterial &&
                      (
                        ((value.attributes & Item.database.statics.ATTRIBUTE.WEAPON) != 0) ||
                        ((value.attributes & Item.database.statics.ATTRIBUTE.SHIELD) != 0) ||
                        (value.equipType == Item.database.statics.TYPE.ARMOR)
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
        )
      );
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
  }
  
  buySomethinWillYa(
    inventory:location.data.guildInventory
  );
}


@:mainMenu::(location, party) {
  @:choices = [
    ::<- teamInfo(:party),
    ::<- guildShop(:location),
    ::<- guildQuests(:location)
  ];
  
  windowEvent.queueChoices(
    prompt: 'Guild menu',
    canCancel : true,
    keep : true,
    choices : [
      'Team info',
      'Guild Shop',
      'Available quests'
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
