@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'game_class.database.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Item = import(module:'game_mutator.item.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:random = import(module:'game_singleton.random.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:namegen = import(module:'game_singleton.namegen.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:commonInteractions = import(module:'game_singleton.commoninteractions.mt');
@:InteractionMenuEntry = import(module:'game_struct.interactionmenuentry.mt');
@:Personality = import(module:'game_database.personality.mt');
@:g = import(module:'game_function.g.mt');
@:Scene = import(module:'game_database.scene.mt');
@:Accolade = import(module:'game_struct.accolade.mt');
@:romanNum = import(module:'game_function.romannumerals.mt');


@:WORK_ORDER__SPACE = 1;
@:WORK_ORDER__FRONT = 2;

@:LEVEL_HIRE_EMPLOYEES  = 3;
@:LEVEL_UPGRADE_SHOP0   = 5;
@:LEVEL_UPGRADE_SHOP1   = 7;
@:LEVEL_BUY_PROPERTY  = 10;

// Other shopkeeps have a standard reduction 
// of 10 for their sales.
//
// Ours is higher because we are new
@:STANDARD_REDUCTION_PRICE = 14;


@:hireeContractWorth::(entity)<- 5+((entity.stats.sum/8 + entity.level)*2.5)->ceil;
@:pickItemStock = ::(*args) {
  @:choicesColumns = import(module:'game_function.choicescolumns.mt');
  @items = []
  choicesColumns(
    leftWeight: args.leftWeight => Number,
    topWeight:  args.topWeight => Number,
    prompt: args.prompt => String,
    onGetPrompt: args.onGetPrompt,
    canCancel: args.canCancel,
    jumpTag: 'pickItem',
    onHover : if (args.onHover)
      ::(choice) {
        when(choice == 0) empty;
        args.onHover(item:args.inventory.items[choice-1])
      }
    else 
      empty,
    renderable : args.renderable,
    onGetChoices ::{

      @:popular   = args.traderState.popular
      @:unpopular   = args.traderState.unpopular;

      
      items =  
        [...args.inventory.items]
      ;
    
      @:names = [...items]->map(to:::(value) {
        return value.name;
      });
      
      @:gold = [...items]->map(to:::(value) {
        @go = value.price * args.goldMultiplier;
        go = go->ceil;
        return if (go < 1)
          '?G' /// ooooh mysterious!
        else
          g(g:go);      
      });
      
      @:popularList = [...items]->map(to:::(value) {
        when(popular->findIndex(value:value.base.id) != -1) 'High'
        when(unpopular->findIndex(value:value.base.id) != -1) 'Low'
        return ' '
      })
      
      if (names->keycount == 0) ::<={
        windowEvent.queueMessage(text: "The inventory is empty.");
      }
      return [
        names,
        popularList,
        gold,
      ];
    },
    header : ['Item', 'Popularity', 'Worth', ],
    leftJustified : [true, true, false],
    keep:true,
    onChoice ::(choice) {
      when(choice == 0) args.onPick();
      args.onPick(item:items[choice-1]);
    }
  );
};


@:ROLES = {
  WAITING : 0,
  DISPATCHED : 1,
  IN_PARTY : 2,
  SHOPKEEP : 3,
}

@:MOODS = {
  TERRIBLE : 0,
  NOT_GREAT : 1,
  OK : 2,
  GOOD : 3,
  FANTASTIC : 4
}

@:moodToString::(mood) {
  return match(mood) {
    (0): 'Terrible...',
    (1): 'Not great.',
    (2): 'Okay.',
    (3): 'Good!',
    (4): 'Fantastic!'
  }
}

@:roleToString::(role) {
  return match(role) {
    (0): 'Waiting',
    (1): 'Exploring',
    (2): 'In Party',
    (3): 'Shopkeeping'
  }
}
@:TraderState_Hiree = LoadableClass.create(
  name: 'Wyvern.Scenario.TheTrader.State.Hiree',
  items : {
    // entity of the hiree
    member : empty,
    
    // contract amount 
    contractRate : 0,
    
    // Whether the hiree was dispatched for the day.
    role : ROLES.WAITING,
    
    // mood for the day.
    mood : MOODS.OK,
    
    // The last thing that attacked this hiree while exploring
    lastAttackedBy : '',
    
    // number of days employed.
    daysEmployed : 0,
    
    // worth of items found
    earned : 0,
    
    // amount sold as a shopkeeper
    sold : 0,
    
    // How much money has been paid out
    spent : 0,
    
    // overrides mood when relevant
    consistentMood : 0,
    
    // consistent mood days
    consistentMoodDays : 0,
    
    // The named title for the employee
    title : 'Employee'
  },
  define ::(this, state) {
  
    this.interface = {
      defaultLoad ::(member, rate) {
        state.member = member;
        state.contractRate = rate;
      },
      
      entity : {
        get ::<- state.member
      },
      
      title : {
        get ::<- state.title,
      },
      
      setTitle ::{
        @:nameFn = import(module:'game_function.name.mt');
        nameFn(
          prompt: state.member.name + '\'s title:',
          onDone ::(name) {
            when(name->length > 20)
              windowEvent.queueMessage(text:'This title is too long.');
              
            state.title = name;
          },
          canCancel:true
        );
      },
      
      lastAttackedBy : {
        get ::<- state.lastAttackedBy
      },
      
      report :: {
        windowEvent.queueMessage(
          pageAfter: 14,
          text: 
            'Report on: ' + state.member.name +'\n' +
            'Contract worth : ' + g(g:hireeContractWorth(entity:state.member)) + ' a day\n' +
            'Current wage   : ' + g(g:state.contractRate) + ' a day\n' + 
            'Employed for   : ' + state.daysEmployed + ' days\n' +  
            'Current role   : ' + roleToString(role:state.role) + '\n\n' +
            
            'Total expenses in wages : ' + g(g:-state.spent) + '\n\n' +

            'Profit from employment:\n' +
            'Dispatch  : ' + g(g:state.earned) + '\n' +
            'Shopkeeping : ' + g(g:state.sold) + '\n'
        );  
      },
    
      // deducted each day from total.
      contractRate : {
        get ::<- state.contractRate,
        set ::(value) <- state.contractRate = value
      },
      
      role : {
        get ::<- state.role,
        set ::(value) <- state.role = value
      },

      mood : {
        get ::<- if (state.consistentMoodDays > 0) state.consistentMood else state.mood,
        set ::(value) <- state.mood = value
      },

      
      addToParty ::{
        @world = import(module:'game_singleton.world.mt');
        world.party.add(member: state.member);
      },
      
      returnFromParty ::{
        @world = import(module:'game_singleton.world.mt');
        {:::} {
          foreach(world.party.members) ::(i, member) {
            if (state.member == member) ::<= {
              world.party.remove(member);
              send();
            }
          }
        }
      },
      
      daysEmployed : {
        get ::<- state.daysEmployed,
        set ::(value) <- state.daysEmployed = value
      },
      
      earned : {
        get ::<- state.earned,
        set ::(value) <- state.earned = value      
      },

      sold : {
        get ::<- state.sold,
        set ::(value) <- state.sold = value      
      },

      
      spent : {
        get ::<- state.spent,
        set ::(value) <- state.spent = value
      },
      
      setConsistentMood ::(mood, days) {
        state.consistentMood = mood;
        state.consistentMoodDays = days;
      },
      
      dayFinished :: {
        if (state.consistentMoodDays > 0)
          state.consistentMoodDays -= 1;
          
        if (state.daysEmployed > 3)
          state.mood = random.integer(from:0, to:4);
      },
      
      // dispatches the NPC to go foraging in the shrine
      // this is a simulated / simplified experience
      dispatch::{
        @world = import(module:'game_singleton.world.mt');
        @spoils = [];
        @completed = false;
        @:defeat ::{
          if (random.flipCoin())
            state.member.kill(silent:true);
        }
        
        @:actions = {};
        for(0, random.integer(from:4, to:6)) ::(i){
          actions->push(::
            {
              spoils->push(value:
                Item.new(
                  base:Item.database.getRandomFiltered(
                    filter:::(value) <- 
                      value.hasNoTrait(:Item.TRAIT.UNIQUE) && 
                      value.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS)
                      && value.tier <= world.island.tier
                  ),
                  rngEnchantHint:true,
                  forceNeedsAppraisal: false
                )
              );                    
            }          
          )
        }

        for(0, random.integer(from:3, to:6)) ::(i){
          actions->push(:random.pickArrayItemWeighted(
            list : [
              // small chest
              {
                rarity: 2,
                action::{
                  spoils->push(value:
                    Item.new(
                      base:Item.database.getRandomFiltered(
                        filter:::(value) <- 
                          value.hasNoTrait(:Item.TRAIT.UNIQUE) && 
                          value.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS)
                          && value.tier <= world.island.tier
                      ),
                      rngEnchantHint:true,
                      forceNeedsAppraisal: false
                    )
                  );                    
                }
              },
              
              // locked chest
              {
                rarity: 6,
                action::{
                  for(0, 3) ::{
                    spoils->push(value:
                      Item.new(
                        base:Item.database.getRandomFiltered(
                          filter:::(value) <- 
                            value.hasNoTrait(:Item.TRAIT.UNIQUE) && 
                            value.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS)
                            && value.tier <= world.island.tier + 1
                        ),
                        rngEnchantHint:true, 
                        forceEnchant:true,
                        forceNeedsAppraisal: false
                      )
                    );       
                  }               
                }                
              },
              
              // normal hostile encounter
              {
                rarity: 3,
                action::{
                  @:world = import(module:'game_singleton.world.mt');                  
                  @other;
                  if (random.flipCoin()) ::<= {
                    other = world.island.newInhabitant()
                    other.anonymize();
                  } else if (random.number() > 0.02) ::<= {
                    other = world.island.newHostileCreature()
                    other.nickname = correctA(word:other.name);
                    breakpoint();
                  } else ::<= {
                    @:TheBeast = import(module:'game_class.landmarkevent_thebeast.mt');
                    other = TheBeast.createEntity();
                  } 
                    
                  state.lastAttackedBy = other.name;
                  windowEvent.autoSkip = true;
                    {:::} {
                      forever ::{
                        when(state.member.isIncapacitated()) send();
                        when(other.isIncapacitated()) send();
                        
                        @:moodBonus = match(this.mood) {
                          (0): 0.4,
                          (1): 0.8,
                          (2): 1,
                          (3): 1.3,
                          (4): 1.8
                        }
                        
                        // give the benefit of the doubt, let our person attack first
                        state.member.attack(
                          target: other,
                          damage: Damage.new(
                            amount:state.member.stats.ATK * (0.5) * moodBonus,
                            damageType : Damage.TYPE.PHYS,
                            damageClass: Damage.CLASS.HP
                          )
                        );                           

                        if (!other.isIncapacitated())
                          other.attack(
                            target: state.member,
                            damage: Damage.new(
                              amount:other.stats.ATK * (0.5),
                              damageType : Damage.TYPE.PHYS,
                              damageClass: Damage.CLASS.HP
                            )
                          );                           
                      }
                    }
                  windowEvent.autoSkip = false;
                  if (!state.member.isIncapacitated()) ::<={
                    spoils->push(value:
                      Item.new(
                        base:Item.database.getRandomFiltered(
                          filter:::(value) <- 
                            value.hasNoTrait(:Item.TRAIT.UNIQUE)
                            && value.tier <= world.island.tier
                        ),
                        rngEnchantHint:true,
                        forceNeedsAppraisal: false
                      )
                    );                      
                  } else
                    defeat();
                }
              }
               
            ]
          ).action);          
        }
        
        {:::} {
          foreach(actions) ::(k, v) {
            v();
            if (state.member.hp < state.member.stats.HP / 2) send();
          }  
          completed = true;          
          spoils->push(value:
            Item.new(
              base:Item.database.getRandomFiltered(
                filter:::(value) <- 
                  value.hasTraits(:Item.TRAIT.HAS_QUALITY) &&
                  value.hasNoTrait(:Item.TRAIT.UNIQUE)         
              ),
              qualityHint : 'base:masterwork',
              rngEnchantHint:true,
              forceNeedsAppraisal: false
            )
          ); 
          world.scenario.data.trader.state.accolade_employeeCompletedDungeon = true;  


        }
        // Too bad 
        when (state.member.isDead) [];
        @:Entity = import(module:'game_class.entity.mt');
        // first, look through all items and pick any equipment thats 
        // more expensive for the slot. This approximates "better gear"
        @spoilsFiltered = [];
        foreach(spoils) ::(i, item) {
          @slot = state.member.getSlotsForItem(item)[0];
          @:current = state.member.getEquipped(slot);
          
          // ignore equipping hand things that arent weapons.
          when(slot == Entity.EQUIP_SLOTS.HAND_LR && (item.base.traits & Item.TRAIT.WEAPON == 0))
            spoilsFiltered->push(value:item);
          
          // simply take
          when (current.base.id == 'base:none')
            state.member.equip(item, slot, silent:true);


          // exchange
          if (item.price > current.price) ::<= {
            state.member.equip(item, slot, silent:true);
            spoilsFiltered->push(value:current);            
          } else 
            spoilsFiltered->push(value:item)
          
        }
        spoils = spoilsFiltered;
        
        
        // then, randomly take half of the spoils. Hiree deserves some good stuff too,
        // they earned it after all.
        spoils->setSize(size:(spoils->size/2)->ceil);

        // the remainder is given to you.        
        return spoils;
      }
    }
  }
);

@:TraderState = LoadableClass.create(
  name: 'Wyvern.Scenario.TheTrader.State',
  items : {
    // current upkeep. Accrues more as you do better 
    upkeep : 70,
    
    // Days since beginning. Determines tier increases.
    days : 0,
    
    // Party G at the start of the day. Difference after end of the day is current day's profit.
    startingG : 0,
    
    // Best profit recorded. This is used as the basis for increasing rent (EVIL)
    bestProfit : 0,
    
    // Array of TraderState_Hiree
    hirees : empty,
    
    // Excess data for mods.
    data : empty,
    
    // world ID for the city where the shop resides 
    cityID : -1,
    
    // inventory of the shop.
    shopInventory : empty,
    
    // world ID for the shop that is owned by the player.
    shopID : -1,
    
    // world ID for the island where the shop owned by the player resides.
    islandID : -1,
    
    // Current popular items (base names)
    popular : empty,
    
    // No one will buy these (base names)
    unpopular : empty,
    
    // Location IDs that are owned by the player
    ownedProperties : empty,
    
    // Location IDs of properties that are owned but up for sale.
    propertiesForSale : empty,
    
    // Whether a work order was put in for upgrading the shop.
    workOrder : 0,
    
    // The times the gold goal has been met
    goldTier : 0,
    
    // How much EXP gained from sales for this level
    sellingEXP : 0,
    
    // Selling EXP to next 
    sellingEXPtoNext : 700,
    
    // How many levels gained from sales.
    sellingLevel : 1,
    
    // history of transactions
    ledger : empty,
    
    // How many NPC-fronted storefronts there are.
    additionalStorefrontCount : 0,
    
    // whether a recessions is present and for how many days.
    // if positive, currently experiencing a recession 
    // if negative, a recession is impossible for that many days 
    // if 0, no recession.
    recession: 0,
    
    // Total earned from purely investments 
    totalEarnedInvestments : 0,
    
    // Total earned from purely shopkeeping / selling property
    totalEarnedSales : 0,
    
    // You are truly a monster.
    defeatedWyvern : false,
    
    
    //////////////
    ////////////// accolade data 
    //////////////

    accolade_srank : false,

    // whether the player experienced a recession
    accolade_experiencedRecession: false,
    
    // whether an employee was never heard from again. 
    // honestly pretty common, so getting this is hard 
    accolade_noEmployeesLost : true,
    
    // whether an employee completed a dungeon
    accolade_employeeCompletedDungeon : false,
    
    // Whether a player had a customer walk out on them 
    accolade_failedToHaggle : false,
    
    // Whether the player agreed to a raise of over 1000G
    accolade_raiseOver1000G : false,
    
    // Whether a player sold a property.
    accolade_soldAPropertyProfit : false,
    
    // Whether a player found and sold a material shipment.
    accolade_soldAShipment : false,
    
    // Whether a player bought a business that cost over 100000G
    accolade_boughtBusinessOver100000G : false,
    
    // Whether a player denied a raise to get an employee to quit 
    accolade_hadEmployeeQuit : false,
    
    // Manage at least 5 simultaneous employees
    accolade_5simultaneousHiree : false,
    
    // under 40 days is an accolade 

    // whether a player sold a worthless item.
    accolade_soldAWorthlessItem : false
    
    // completing a dungeon by hand is an accolade
    
    
    //imported accolades
    
    
  },
  
  define::(this, state) {
    this.interface = {
      defaultLoad::(city, shop) {
        @:Inventory = import(module:'game_class.inventory.mt');
        state.hirees = [];
        state.ledger = [];
        state.popular = [];
        state.unpopular = [];
        state.ownedProperties = [];
        state.propertiesForSale = [];
        state.cityID = city.worldID;
        state.shopID = shop.worldID;
        state.islandID = city.island.worldID;
        @world = import(module:'game_singleton.world.mt');
        state.startingG = world.party.inventory.gold;
        state.shopInventory = Inventory.new();
        state.shopInventory.maxItems = 10;
      },
      
      startingG : {
        get ::<- state.startingG
      },
      
      goldTier : {
        set ::(value) <- state.goldTier = value,
        get ::<- state.goldTier
      },
      
      courierReportDay ::(onDone) {
        @:onDoneReal ::{
          onDone();
          windowEvent.jumpToTag(name:'courierReport', goBeforeTag:true, doResolveNext:true);
        }
        
        windowEvent.queueCustom(
          renderable : {
            render :: {
              canvas.blackout();
            }
          },
          keep:true,
          jumpTag : 'courierReport',
          onEnter ::{

            @:instance = import(module:'game_singleton.instance.mt');
            @world = import(module:'game_singleton.world.mt');
            @:currentLandmark = world.landmark;
            @:Landmark = import(module:'game_mutator.landmark.mt');
            if (currentLandmark != empty && currentLandmark.base.hasTraits(:Landmark.TRAIT.POINT_OF_NO_RETURN) == true) ::<= {
              windowEvent.queueMessage(
                text: '"Oh huh. The courier is here... somehow."'
              );
            } else 
              windowEvent.queueMessage(
                text: '"Ah. The courier is here."'
              );

            @hasNews = false;
            
            if (state.workOrder != 0) ::<= {
              hasNews = true;
              windowEvent.queueMessage(
                speaker: 'Courier',
                text: '"It seems that your work order for upgrading your shop has finished successfully. Enjoy the new space."'
              );
              breakpoint();
              if (state.workOrder == WORK_ORDER__SPACE)
                state.shopInventory.maxItems += 5
              else
                state.additionalStorefrontCount += 1;

              state.workOrder = 0;
            }
            

            foreach([...state.hirees]) ::(i, hiree) {
              when (hiree.role != ROLES.DISPATCHED) empty;

              when (hiree.entity.isDead) ::<= {
                hasNews = true;
                windowEvent.queueMessage(
                  speaker: 'Courier',
                  text: '"I have unfortunate news... Your ' + hiree.title + ' ' + hiree.entity.name + ' has not returned from their exploration. Word is that ' + hiree.lastAttackedBy+ ' got them while adventuring. I don\'t think they\'ll be coming back..."'
                );
                state.accolade_noEmployeesLost = false;
                
                state.hirees->remove(key:state.hirees->findIndex(value:hiree));
                windowEvent.queueMessage(
                  text: hiree.entity.name + ' was removed from the hirees list.'
                );
              }
            }



            if (world.island.tier > 0 && state.days % 3 == 1) ::<= {        
              windowEvent.queueMessage(
                speaker: 'Courier',
                text: '"I have received news of what\'s in demand and what\'s not."'
              );
              hasNews = true;
              


              
              @popnews = 'These items are now popular. People will pay high prices for them compared to normal.\n\n';
              foreach(state.popular) ::(i, val) {
                popnews = popnews + ' - ' + Item.database.find(id:val).name + '\n';
              }
              
              windowEvent.queueMessage(text:popnews, pageAfter:14);

              @unpopnews = 'These items are now unpopular. People will avoid these or won\'t be willing to buy them for normal prices.\n\n';
              foreach(state.unpopular) ::(i, val) {
                unpopnews = unpopnews + ' - ' + Item.database.find(id:val).name + '\n';
              }
              windowEvent.queueMessage(text:unpopnews, pageAfter:14);
            }


            if (state.days % 5 == 0) ::<= {
              if (world.island.tier < 5) ::<= {
                windowEvent.queueMessage(
                  speaker: 'Courier',
                  text: '"I have received news that the Mysterious Shrine has shifted. I am told this means the quality of items from exploration will increase."'
                );
                hasNews = true;
                world.island.tier += 1;
              } else             
                if (state.days % 10 == 0)
                  world.island.tier += 1;
            }

            if (state.recession < 0)
              state.recession += 1;

            
            if (state.recession > 0) ::<= {
              state.recession -= 1;
              if (state.recession == 0) ::<= {
                windowEvent.queueMessage(
                  speaker: 'Courier',
                  text: '"Truly great news. It looks like the island is coming out of its recession. Business should be returning to normal soon."'
                );
                hasNews = true;
                state.recession = -9; // days cooldown
              } else ::<= {
                windowEvent.queueMessage(
                  speaker: 'Courier',
                  text: '"I hear the island\'s recession is still ongoing. Hopefully business returns to normal soon."'
                );              
                hasNews = true;
              }
            }
            
            if (state.days > 25 && state.recession == false && random.try(percentSuccess:10)) ::<= {
              state.recession = 5;
              state.accolade_experiencedRecession = true;

              windowEvent.queueMessage(
                speaker: 'Courier',
                text: '"Truly unfortunate news. It looks like the island is currently experiencing a recession. This will affect business for a while."'
              );
              hasNews = true;
            }
            
            


            if (!hasNews) ::<= {
              windowEvent.queueMessage(
                speaker: 'Courier',
                text: '"No essential news today, but... ' + 
                  if (state.days == 1) 
                    'Word is, people are looking for contract work similar to what you need. Most people seem to look for work while sharing drinks at Taverns."'
                  else
                    random.pickArrayItem(
                    list : [
                      'I am told that the items that people consider desirable will change soon."',
                      'Word is, business is booming around cities, and most businesses are accepting buy offers."',
                      'Word is, people are looking for contract work similar to what you need. Most people seem to look for work while sharing drinks at Taverns."'
                    ]
                  )
              );
            
            }


            if (world.party.inventory.gold > 5) ::<= {
              world.party.inventory.subtractGold(amount:5);

              windowEvent.queueMessage(
                text: 'You tip the courier 5G for their services.'
              );
            }
            windowEvent.queueMessage(
              speaker: 'Courier',
              text: '"Well, that\'s all the news for today. Have a good day."'
            );
            
            windowEvent.queueCustom(
              onEnter ::{
                onDoneReal();
              }
            );
          }
        )
      },
      
      isPropertyOwned ::(location) {
        when(state.ownedProperties->findIndexCondition(::(value) <- value == location.worldID) != -1) true;
        when(state.propertiesForSale->findIndexCondition(::(value) <- value == location.worldID) != -1) true;
        return false;
      },
      
      finances ::{
        @:finances_ledger ::{
          when(state.ledger->size == 0) ::<= {
            windowEvent.queueMessage(
              text: 'The ledger is empty. Check again tomorrow.'
            );
          }
        
          // each line has earnings, expenses, and investments, followed by balance
          @:earnings = [];
          @:expenses = [];
          @:investments = [];
          @:balances = [];
          @:day = [];
          
          foreach(state.ledger) ::(i, ledge) {
            day->push(value:''+(i+1));
            earnings->push(value:g(g:ledge.earnings));
            expenses->push(value:'-'+ g(g:ledge.expenses));
            investments->push(value:g(g:ledge.investments));
            balances->push(value:g(g:ledge.balance));
          }
          
          
          @:choicesColumns = import(module:'game_function.choicescolumns.mt');
          

          choicesColumns(
            onGetChoices ::{
              return [
                day,
                earnings,
                expenses,
                investments,
                balances
              ]
            },
            prompt: 'Ledger:',
            header : [
              'Day',
              'Earned',
              'Expenses',
              'Investments',
              'Balance'
            ],
            canCancel: true,
            keep: true,
            leftJustified : [true, true, true, true, true],
            leftWeight: 0.5,
            topWeight: 0.5,
            onChoice ::(choice) {
            }
          );
          
        }
        
        @:finances_employee:: {
          when(state.hirees->size == 0)
            windowEvent.queueMessage(
              text: 'You have no one currently employed.'
            );
          windowEvent.queueChoices(
            prompt: 'View whom?',
            choices: [...state.hirees]->map(to:::(value) <- value.entity.name),
            canCancel: true,
            keep:true,
            onChoice::(choice) {
              @:hiree = state.hirees[choice-1];
              hiree.report();            
            }
          );
        }

        @:choiceNames = ['View ledger'];
        @:choices = [finances_ledger];
        
        if (state.sellingLevel >= LEVEL_HIRE_EMPLOYEES) ::<= {
          choiceNames->push(value:'Hiree report');
          choices->push(value:finances_employee);
        } else ::<= {
          choiceNames->push(value:'????');
          choices->push(value: ::{
            windowEvent.queueMessage(
              text: 'This option isn\'t available yet. You feel that you need to gain more experience as a salesperson before this is relevant.'
            );
          });        
        }
        
        
        windowEvent.queueChoices(
          prompt: 'Finances...',
          choices: choiceNames,
          keep:true,
          canCancel: true,
          onChoice::(choice) {
            choices[choice-1]();
          }
        );
      },
      
      
      manage ::{
        @:choiceNames = [];
        @:choices = [];
        
        if (state.sellingLevel >= LEVEL_HIRE_EMPLOYEES) ::<= {
          choiceNames->push(value: 'Hirees');
          choices->push(value: this.manageHirees);
        } else ::<= {
          choices->push(value: ::{
            windowEvent.queueMessage(
              text: 'This option isn\'t available yet. You feel that you need to gain more experience as a salesperson before this is relevant.'
            );
          });        
          choiceNames->push(value: '????');
        }

        if (state.sellingLevel >= LEVEL_BUY_PROPERTY) ::<= {
          choiceNames->push(value: 'Properties');
          choices->push(value: this.manageProperties);
        } else ::<= {
          choices->push(value: ::{
            windowEvent.queueMessage(
              text: 'This option isn\'t available yet. You feel that you need to gain more experience as a salesperson before this is relevant.'
            );
          });        
          choiceNames->push(value: '????');
        }
        
        choiceNames->push(value:'Finances');
        choices->push(value:this.finances);
        
        



        windowEvent.queueChoices(
          prompt : 'Manage...',
          choices : choiceNames,
          
          onChoice::(choice) {
            choices[choice-1]();
          },
          keep:true,
          canCancel:true
        );
      },
      
      dayStart ::{
        @:instance = import(module:'game_singleton.instance.mt');
        @world = import(module:'game_singleton.world.mt');
        @party = world.party;      
        
        
        @:tiers = [
          10000,
          80000,
          250000
        ];
          
        when (state.defeatedWyvern != true && party.inventory.gold > tiers[state.goldTier]) ::<= {
          Scene.start(id:'thetrader:scene_gold0', onDone ::{
          });
        }


        @:Landmark = import(module:'game_mutator.landmark.mt');
        @:currentLandmark = world.landmark;
        when (currentLandmark != empty && currentLandmark.base.hasTraits(:Landmark.TRAIT.POINT_OF_NO_RETURN) == true) ::<= {
          windowEvent.queueMessage(
            speaker: party.members[0].name,
            text: '"What a terrible day to be stuck here. Guess I won\'t open shop today."'
          );
        }


        windowEvent.queueMessage(
          text: 'You travel back to your shop.'
        );

        
        @:doStart :: {
          windowEvent.queueChoices(
            prompt:'Today I will:',
            choices : [
              'Open shop...',
              'Explore...',
              'Wait until tomorrow'
            ],
            renderable : {
              render ::{
                canvas.blackout(with:'`');
              }
            },
            keep:true,
            jumpTag: 'day-start',
            onChoice::(choice) {
              when(choice == 2) ::<={
                this.explore();
              }    
              
              when(choice == 3) ::<= {
                windowEvent.queueAskBoolean(
                  prompt: 'Wait until tomorrow?',
                  onChoice::(which) {
                    when(which) 
                      this.preflightCheckStart(onDone::{
                        this.finishDay();                      
                      });
                  }
                );
              }
              this.openShop();
            }
          );        
        }        
        
        
        if (state.days != 0)
          this.courierReportDay(onDone::{
            doStart();
          })
        else 
          doStart();
      },
      
      animateGainExp ::(accuracy, onDone, price) {
        @exp = 
          if (price >= 10)
            (30 * (accuracy * (1+accuracy)**3.5))->ceil
          else 
            150

        @:rating = ::<= {
          when(price < 10)
            '-- (sale too cheap for rating)'
          when (accuracy >= 0.99 && price > 30) ::<= {
            state.accolade_srank = true;
            exp *= 2;
            return 'S (Perfect!)';
          }
          when (accuracy >= 0.98 && price > 30) 'A+ (Amazing!)';
          when (accuracy >= 0.93) 'A (Great sale!)';
          when (accuracy >= 0.90) 'A- (Pretty great!)';
          when (accuracy >= 0.87) 'B+ (Good work!)';
          when (accuracy >= 0.83) 'B (Good!)';
          when (accuracy >= 0.80) 'B- (Alright.)';
          when (accuracy >= 0.77) 'C+ (Could be better.)';
          when (accuracy >= 0.73) 'C (In the right direction.)';
          when (accuracy >= 0.70) 'C- (Could have sold higher.)';

          exp += 300;
          return 'Generous! You were really nice and gave a big discount.';
        };


        
        
        @:animate = import(:'game_function.animatebar.mt');
        @:level = ::{
          @remainingForLevel = state.sellingEXPtoNext - state.sellingEXP;
          @val = state.sellingEXP;
          animate(
            from: state.sellingEXP,
            to:   state.sellingEXP + exp,
            max:  state.sellingEXPtoNext,
            
            onGetPauseFinish::<- true,
            pauseStart: true,
            
            onFinish :: {
              when (state.sellingEXP + exp >= state.sellingEXPtoNext) ::<= {
                exp -= (state.sellingEXPtoNext - state.sellingEXP);
                state.sellingLevel += 1;
                state.sellingEXP = 0;
                state.sellingEXPtoNext = 100 + (state.sellingEXPtoNext ** 1.010)->floor;

                windowEvent.queueDisplay(
                  lines : [
                    'Level up!',
                    'Selling level: ' + state.sellingLevel,
                    'People will now be willing to pay more for your items being sold.'
                  ]
                );



                if (state.sellingLevel == LEVEL_HIRE_EMPLOYEES) 
                  windowEvent.queueMessage(
                    text: 'You are now a high enough level to hire employees. Employees can be hired to explore dungeons for you, join your party, and more.\n\nNext unlock at level ' + LEVEL_UPGRADE_SHOP0 + ': Shop upgrades: stock size.'
                  );

                if (state.sellingLevel == LEVEL_UPGRADE_SHOP0) 
                  windowEvent.queueMessage(
                    text: 'You are now a high enough level to expand your shop, allowing you to spend G to hold more items in your shop\'s stock. Tomorrow, check the "Upgrade shop" in the Shop options at the start of the day.\n\nNext unlock at level ' + LEVEL_UPGRADE_SHOP1 + ' : Shop upgrades: additional store fronts.'
                  );
                
                if (state.sellingLevel == LEVEL_UPGRADE_SHOP1) 
                  windowEvent.queueMessage(
                    text: 'You are now a high enough level to add additional store fronts, allowing you to upgrade your shop to have your employees sell you items on your behalf. Tomorrow, check the "Upgrade shop" in the Shop options at the start of the day.\n\nNext unlock at level ' + LEVEL_BUY_PROPERTY + ' : Buying/selling property.'
                  );

                if (state.sellingLevel == LEVEL_BUY_PROPERTY) 
                  windowEvent.queueMessage(
                    text: 'You are now a high enough level to buy and sell property. Properties are any homes and businesses in towns and cities.'
                  );



                level();
              }
              
              state.sellingEXP += exp;
              
              windowEvent.queueCustom(
                onEnter :: {
                  onDone();
                }
              );          
            },
            
            onGetCaption      ::<- 'Sale rating: ' + rating,
            onGetCoCaption    ::<- 'Selling level: ' + state.sellingLevel,
            onGetSubcaption   ::<- 'Exp to next level: ' + (remainingForLevel - (val - state.sellingEXP)),
            onGetSubsubcaption::<- 
                                    '                  +' + (exp - (val - state.sellingEXP)),
            onGetLeftWeight::<- 0.5,
            onGetTopWeight::<- 0.5,
            onNewValue::(value) <- val = value->ceil

          )                
        }
        level();

      },      
      
      attemptSellProperty::(id, onDone) {
        @world = import(module:'game_singleton.world.mt');
        @location = world.island.findLocation(id);
        @:buyer = world.island.newInhabitant();
        buyer.anonymize();
        windowEvent.queueMessage(
          text: 'What\'s this? Someone approaches you with haste...'
        );  
        
        @:name = location.ownedBy.name + '\'s ' + location.base.name;
        windowEvent.queueMessage(
          speaker: buyer.name,
          text: '"Good day. I would like to purchase the establishment you have on sale. I believe you have it listed as \'' + name + '\'.'
        );
        
        this.haggle(
          displayName:name,
          id:name,
          standardPrice: location.data.trader.listPrice,
          shopper: buyer,
          onDone ::(bought, price, accuracy) {
            when(!bought) windowEvent.queueMessage(
              text: 'They left without buying ' + name + '...'
            );

            
            windowEvent.queueMessage(
              text:  name + ' was sold for ' + g(g:price) + '.'
            );            
            
            state.propertiesForSale->remove(key:state.propertiesForSale->findIndex(value:id));
            location.data.trader.listPrice = price;
            world.party.addGoldAnimated(
              amount:price,
              onDone ::{
                if (price > location.data.trader.boughtPrice)
                  state.accolade_soldAPropertyProfit = true;

                this.animateGainExp(
                  price:price,
                  accuracy,
                  onDone ::{
                    onDone();              
                  }
                );
              }
            );
            
          }
        );
        
        
      },
      
      allocateRaises ::(onDone) {
        when(state.hirees->size == 0) onDone();
        
        @:wantsRaise = [];              
        foreach([...state.hirees]) ::(i, hiree) {
          @:percent = if (state.recession > 0) 45 else 25;
          if (hiree.entity.isDead == false && hiree.daysEmployed > 4 && random.try(percentSuccess:percent)) ::<= {
            wantsRaise->push(value:hiree);
          }
        }      
        
        @:nextRaise = ::{
          when(wantsRaise->size == 0) onDone();
          
          @:hiree = wantsRaise->pop;
          @:raiseAmount = 1+(hiree.contractRate * 0.6)->floor;



          windowEvent.queueMessage(
            text: "Your hiree " + hiree.entity.name + " comes up to you, hopeful."
          );
          
          
          windowEvent.queueMessage(
            speaker: hiree.entity.name,
            text: random.pickArrayItem(
              list : [
                '"I\'ve worked very hard as your ' + hiree.title + '. I believe I am in my right to ask for a raise. ',
                '"So, I\'ve been working very hard for you. Would you be open to raising my wages? ',
                '"I\'ll be forward. '
              ]
            ) + "I would like a raise of " + g(g:raiseAmount) + '.\"'
          );
          
          
          @:decide ::{
            windowEvent.queueAskBoolean(
              prompt: 'Give ' + hiree.entity.name + ' a raise of ' + g(g:raiseAmount) + '?',
              onChoice ::(which) {
                when(which == false) ::<= {
                  if (random.flipCoin()) ::<= {
                    this.quit(hiree);
                  } else ::<= {
                    windowEvent.queueMessage(
                      text: hiree.entity.name + ' walks away disappointed.'
                    );
                  };
                  hiree.setConsistentMood(mood:MOODS.TERRIBLE, days:3);               
                  nextRaise();
                }
                  
                windowEvent.queueMessage(
                  speaker: hiree.entity.name,
                  text: random.pickArrayItem(list: [
                    '"Thanks a lot. I\'ll continue to work even harder!"',
                    '"That went better than I expected, to be honest. Thanks."',
                    '"Alright! I\'ll get back to it."'
                  ])
                );     
                
                hiree.setConsistentMood(mood:MOODS.FANTASTIC, days:3);               
                
                hiree.contractRate += raiseAmount;
                if (hiree.contractRate > 1000)
                  state.accolade_raiseOver1000G = true;

                nextRaise();
                
              }
            );
            windowEvent.jumpToTag(name:'thinkRaise', goBeforeTag:true, doResolveNext:true);
          }
          
          windowEvent.queueChoices(
            prompt: hiree.entity.name + ' is asking for a ' + g(g:raiseAmount) + ' raise',
            choices: [
              'Describe',
              'Finances',
              'Decide'
            ],
            keep: true,
            canCancel: false,
            jumpTag : 'thinkRaise',
            
            onChoice::(choice) {
              match(choice-1) {
                (0): hiree.entity.describe(),
                (1): this.finances(),
                (2): decide()
              }
            }
          );
        }
        nextRaise();
      },
      
      simulateShopkeep::(shopkeeper) {
        when(state.shopInventory.items->size == 0) {
          gained : -1,
          sold : [],
          prices : [],
          markup : []          
        };
        @maxPerHour = (
          (state.shopInventory.items->size / 6)
        )->ceil;
        
          
        if (maxPerHour > 5)
          maxPerHour = 5;

        @gained = 0;
        @world = import(module:'game_singleton.world.mt');

        @:popular   = state.popular;
        @:unpopular   = state.unpopular;

        if (shopkeeper.mood == MOODS.NOT_GREAT)
          maxPerHour *= 0.6;

        if (shopkeeper.mood == MOODS.TERRIBLE)
          maxPerHour *= 0.3;

        maxPerHour = maxPerHour->floor;
        
        
        @:itemsSold  = [];
        @:itemsPrice   = [];
        @:itemsMarkup  = [];
        @:itemsPopular = [];

        {:::} {
          for(world.TIME.LATE_MORNING, world.TIME.EVENING) ::(i) {
            @shoppers = random.integer(from:0, to:maxPerHour);              

            if (state.recession > 0)
              shoppers = if (random.try(percentSuccess:20)) 1 else 0;


            for(0, shoppers) ::(n) {
              when(state.shopInventory.items->size == 0) send();
              @:sold = random.removeArrayItem(list:state.shopInventory.items);

              
              @isPopular = ::<= {          
                @:popular   = state.popular;
                return (popular->findIndex(value:sold.base.id) != -1)
              }          

              @isUnpopular = ::<= {          
                @:unpopular   = state.unpopular;
                return (unpopular->findIndex(value:sold.base.id) != -1)
              }      

              @price = 
                if (isPopular) 
                  ((sold.price / STANDARD_REDUCTION_PRICE)->floor)*2 // uses standard reduction
                else if (isUnpopular)
                  ((sold.price / (STANDARD_REDUCTION_PRICE*2))->floor)
                else 
                  (sold.price / STANDARD_REDUCTION_PRICE)->floor
                  
              match(shopkeeper.mood) {
                (0, 1): ::<= {
                  if (random.flipCoin())
                    price *= 1 - (random.number() * 0.3)
                },
                
                (2): ::<= {
                  if (random.flipCoin())
                    price *= 1 + (random.number() * 0.15)
                },

                (3): ::<= {
                  if (random.flipCoin())
                    price *= 1 + (random.number() * 0.6)
                },
                (4): ::<= {
                  price *= 1.1 + (random.number() * 0.8)
                }

              }
                  
              if (price < 1) ::<= {
                state.accolade_soldAWorthlessItem = true;
                price = 1;
              }
              price = price->floor;
                
              if (sold.base.id == 'thetrader:shipment')
                state.accolade_soldAShipment = true;
                  
              gained += price;
              
              
              @:markup = (((price - (sold.price / STANDARD_REDUCTION_PRICE)) / (sold.price / STANDARD_REDUCTION_PRICE)) * 100)->floor;
              itemsSold->push(value:sold.name);
              itemsPrice->push(value:g(g:price));
              itemsMarkup->push(value:if (markup == 0) '--' else (if (markup < 0)''+markup else '+'+markup)+'%');
              itemsPopular->push(value:if (isPopular) 'High' else (if (isUnpopular) 'Low' else ''));
              state.shopInventory.remove(item:sold);
            }                  
          }
        }
        return {
          gained : gained,
          sold : itemsSold,
          prices : itemsPrice,
          markup : itemsMarkup,
          popular : itemsPopular
        }
      },
    
      dayEnd::(onDone) {
        @:onDoneReal ::{
          @:instance = import(module:'game_singleton.instance.mt');
          @:loading = import(module:'game_function.loading.mt');
          loading(
            message: 'Ending day...',
            do::{
              instance.savestate();
              onDone();

            }
          );
          windowEvent.jumpToTag(name:'dayEnd', goBeforeTag:true, doResolveNext:true);

        }


        @:dayEndCommit ::{
            
          @world = import(module:'game_singleton.world.mt');

          windowEvent.queueMessage(
            text: 'The day is over.'
          );

          
          @:hireesEnd ::(onDone) {
            if (state.hirees->size > 0 && [...state.hirees]->filter(by:::(value) <- value.role == ROLES.DISPATCHED)->size > 0) ::<= {
              windowEvent.queueMessage(
                text: 'Your dispatched hirees should be coming to you with news...'
              );
            }
            
            
            @:nextHireeReport = ::(hiree) {
            
            }
            
            
            foreach([...state.hirees]) ::(i, hiree) {
              when (hiree.role != ROLES.DISPATCHED) empty;
              @:spoils = hiree.dispatch();
              
              when (hiree.entity.isDead) ::<= {
                windowEvent.queueMessage(
                  text: 'You hear no word from ' + hiree.entity.name + ' on their whereabouts...'
                );
              }
              
              if (hiree.entity.isIncapacitated() || spoils->size == 0) ::<= {
                windowEvent.queueMessage(
                  speaker: hiree.entity.name,
                  text: '"I\'ve returned, but barely in one piece..."'
                );
              } else ::<= {
                windowEvent.queueMessage(
                  speaker: hiree.entity.name,
                  text: '"Exploration was a success!"'
                );      
              }          
              
              if (spoils->size == 0) ::<= {
                windowEvent.queueMessage(
                  text:hiree.entity.name + ' was not able to find anything...'
                );            

              } else ::<= {
                if (!world.party.inventory.isFull) ::<= {
                  @itemsFound = "Items found by " + hiree.entity.name + ':\n\n';
                  foreach(spoils) ::(i, item) {
                    if (!world.party.inventory.isFull) ::<= {
                      itemsFound = itemsFound + "- " + item.name + '\n'
                      hiree.earned += (item.price / STANDARD_REDUCTION_PRICE)->floor;
                      world.party.inventory.add(item);
                    }
                  }
                  windowEvent.queueMessage(
                    text:itemsFound
                  );   
                }
                if (world.party.inventory.isFull)
                  windowEvent.queueMessage(
                    text:'"I found more stuff, but we didn\'t have any space left to hold it."'
                  );   
              }
              hiree.entity.heal(amount:hiree.entity.stats.HP, silent:true);
              
            }

            @noShopkeeps = false;
            if (state.hirees->size > 0 && [...state.hirees]->filter(by:::(value) <- value.role == ROLES.SHOPKEEP)->size > 0) ::<= {
              windowEvent.queueMessage(
                text: 'Your shopkeeps are here with news.'
              );
            } else 
              noShopkeeps = true;
            
            
            // no event based stuff, continue;
            when(noShopkeeps) onDone();
            
            
            @:shopkeeps = [...state.hirees];
            @:nextShopkeep :: {
              breakpoint();
              when(shopkeeps->size == 0) onDone(); 
              @:hiree = shopkeeps->pop;
              when(hiree.role != ROLES.SHOPKEEP) nextShopkeep();
               
              
              @:data = this.simulateShopkeep(shopkeeper:hiree);
              @:gained = data.gained;
              @:itemsSold = data.sold;
              
              // < 0 means stock was empty.
              when (gained == -1) ::<= {
                windowEvent.queueMessage(
                  speaker:hiree.entity.name,
                  text: '"Unforunately, no sales were made today due to the store stock being depleted."'
                )
                nextShopkeep();
              }

              when (gained == 0) ::<= {
                windowEvent.queueMessage(
                  speaker:hiree.entity.name,
                  text: '"Unforunately, no sales were made today."'
                );
                nextShopkeep();                
              }

              windowEvent.queueMessage(
                speaker:hiree.entity.name,
                text: random.pickArrayItem(
                  list : 
                    match(hiree.mood) {
                      (0, 1):  
                        [
                          '"I had a hard time, I at least got some sales."',
                          '"Not feeling great, but I tried my best."'
                        ],
                      (2, 3):
                        [
                          '"Selling today went great."',
                          '"Another great day at the store front."',                        
                        ],
                      (4):
                        
                        [
                          '"Many customers today!"',
                          '"It was great to see so many things off the shelves!"',
                          '"Truly a great day to shopkeep!"'
                        ]
                    }
                )
              );
              
              
              @sold = "Items sold by " + hiree.entity.name +  '. Earned: ' + g(g:gained) ;

              @:choicesColumns = import(module:'game_function.choicescolumns.mt');
              choicesColumns(
                onGetChoices ::{
                  return [
                    data.sold,
                    data.popular,
                    data.prices,
                    data.markup
                  ]
                },
                prompt: sold,
                header: ['Item', 'Popularity', 'Sold at...', 'Markup'],
                leftJustified : [true, true, true, true],
                leftWeight: 0.5,
                topWeight: 0.5,
                canCancel: true,
                keep : true,
                jumpTag: 'ItemsSold',
                onChoice ::(choice) {
                  windowEvent.jumpToTag(
                    name: 'ItemsSold',
                    goBeforeTag: true,
                    doResolveNext: true
                  )
                }
              )

              hiree.sold += gained;
              world.party.addGoldAnimated(
                amount:gained,
                onDone ::{
                  nextShopkeep()
                }
              );
              state.totalEarnedSales += gained;
            } 
            nextShopkeep();                     
          }
          



          // called once all the event based stuff is done.
          @:wrapUp = ::{
            @:endWrapUp :: {
              @status = "Todays profit:\n";
              
              @earnings = world.party.inventory.gold - state.startingG;
              status = status + "  Earnings   : "+ (if (earnings < 0) g(g:earnings) else "+" + g(g:earnings)) + "\n\n";


              @:Location = import(module:'game_mutator.location.mt');

              @rent = 0;
              foreach(state.ownedProperties) ::(i, id) {
                @:location = world.island.findLocation(id);
                
                if (location.base.category == Location.CATEGORY.RESIDENTIAL) ::<= {
                  rent += (location.data.trader.boughtPrice * 0.07)->ceil;
                  @current = location.data.trader.listPrice;
                  current += (((random.number() - 0.5) * 0.05) * location.data.trader.boughtPrice)->floor;

                  if (state.recession > 0)
                    current *= 0.92;
                  current = current->floor;


                  if (current < 2000)
                    current = 2000;
                  location.data.trader.listPrice = current;
                }
              }
              state.totalEarnedInvestments += rent;
              world.party.inventory.addGold(amount:rent);
              @investments = rent;
              if (rent > 0)
                status = status + "  Rent       : +" + g(g:rent) + "\n";
              

              rent = 0;
              foreach(state.ownedProperties) ::(i, id) {
                @:location = world.island.findLocation(id);
                when (location.base.category == Location.CATEGORY.RESIDENTIAL) empty
                
                @profit = location.data.trader.listPrice * 0.15;
                profit = random.integer(from:(profit * 0.5)->floor, to:(profit * 1.5)->floor);
                
                if (state.recession > 0 && random.try(percentSuccess:65))
                  rent -= profit
                else
                  rent += profit;


                @current = location.data.trader.listPrice;
                current += (((random.number() - 0.5) * 0.15) * location.data.trader.listPrice)->floor;

                if (state.recession > 0)
                  current *= 0.92;
                current = current->floor;

                if (current < 9000)
                  current = 9000;
                location.data.trader.listPrice = current;
              }
              state.totalEarnedInvestments += rent;
              world.party.inventory.addGold(amount:rent);
              investments += rent;
              if (rent != 0)
                status = status + "  Businesses : " + (if (rent >= 0) '+' + g(g:rent) else g(g:rent)) + "\n";


              status 

              @cost = 0;
              foreach(state.hirees) ::(i, hiree) {
                when (hiree.entity.isDead) empty;
                cost += hiree.contractRate;
                hiree.spent += hiree.contractRate;
                hiree.daysEmployed += 1;
              }
              status = status + "  Contracts  : -" + g(g:cost) + "\n";
              
              cost += state.upkeep;
              status = status + "  Upkeep     : -" + g(g:state.upkeep) + "\n";
              
              @currentG = world.party.inventory.gold
              @:profit = (earnings + investments) - cost;
              state.days += 1;
              if (profit > state.bestProfit)      
                state.bestProfit = profit;
              if (state.days % 2 == 0 && profit > 0) 
                state.upkeep += (profit * 0.01)->floor;
              
              status = status + "_________________________________\n";
              status = status + "  Profit     : " + (if (profit < 0) g(g:profit) else "+" + g(g:profit)) + "\n\n";
              

              world.party.inventory.subtractGold(amount:cost);

              state.ledger->push(value:{
                earnings : earnings,
                expenses : cost,
                investments : investments,
                balance : world.party.inventory.gold
              });




              if (cost > currentG)
                status = status + "Remaining: [BANKRUPT]"
              else 
                status = status + "Remaining: " + g(g:world.party.inventory.gold)

              when (cost > currentG)
                Scene.start(id:'thetrader:scene_bankrupt', onDone::{          
                  @:instance = import(module:'game_singleton.instance.mt');
                  instance.gameOver(reason:'You\'re no longer chosen by the Wyvern of Fortune.');
                });    
                  


              // decide popular items for next day
              if (world.island.tier > 0 && state.days % 3 == 1) ::<= {        
                @:which = [...Item.database.getAll()]->filter(by::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE));
                state.popular = [
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which)
                ]->map(to:::(value) <- value.id);

                state.unpopular = [
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which),
                  random.removeArrayItem(list:which)
                ]->map(to:::(value) <- value.id);
              }


              // return to pool
              foreach(state.hirees) ::(i, hiree) {
                if (world.party.isMember(entity:hiree.entity))
                  hiree.returnFromParty();
                hiree.dayFinished();
              }
              
              // Interesting. You seemed to have a phantom employee in your party!
              // This is possible with Skie, but could be done through other 
              // means perhaps. They are now your free employees!
              if (world.party.members->size > 1) ::<= {
                {:::} {
                  forever ::{
                    when(world.party.members->size == 1) send();
                    
                    @:newMem = world.party.members->pop;
                    this.addHiree(
                      entity: newMem,
                      rate: 0
                    );
                  }
                }   
              }
              
              state.startingG = world.party.inventory.gold;        
              windowEvent.queueMessage(text:status, pageAfter:14);
              
              windowEvent.queueCustom(
                onEnter ::{
                  onDoneReal();
                }
              );
            }
            
            hireesEnd(onDone::{
              this.allocateRaises(
                onDone:endWrapUp
              );
            });
          }

          /// property sales. Event-based so it may be a bit confusing...
          @:trySell = [...state.propertiesForSale];
          @:nextSale = ::{
            when(trySell->size == 0) wrapUp();
            @:id = trySell->pop;
            when(random.try(percentSuccess:75)) nextSale();
            
            this.attemptSellProperty(id, onDone:nextSale);
          }        
          nextSale();           
        }
        windowEvent.queueCustom(
          onEnter::{
            dayEndCommit();
          },
          keep:true,
          jumpTag: 'dayEnd',
          renderable : {
            render ::{
              canvas.blackout()
            }
          }
        );
          

      },
      
      newDay :: {
        this.dayEnd(onDone::{
          this.dayStart();
        });
      },
      
      ownedProperties : {
        get ::<- state.ownedProperties
      },

      
      isHired ::(entity) {
        return {:::} {
          foreach(state.hirees) ::(i, hiree) {
            if (hiree.entity == entity)
              send(message:true);
          }
          return false;                
        }  
      },

      
      addHiree ::(entity, rate) {
        @:n = TraderState_Hiree.new(
          member:entity,
          rate
        )
        state.hirees->push(value:n);
        if (state.hirees->size >= 5)
          state.accolade_5simultaneousHiree = true;
        return n;
      },
      
      changeRole::(hiree) {
        windowEvent.queueChoices(
          prompt: "Do what?",
          choices : [
            'Wait',
            'Dispatch',
            'Add to party',
            'Shopkeep'         
          ],
          leftWeight: 1,
          topWeight: 0.5,
          canCancel: true,
          onChoice ::(choice) {
            when(choice-1 == ROLES.IN_PARTY && [...state.hirees]->filter(by::(value) <- value.role == ROLES.IN_PARTY)->size == 2) ::<= {
              windowEvent.queueMessage(
                text: 'You already have 2 hirees set to join your party. This is the maximum amount.'
              );
            }
            
            
            when(choice-1 == ROLES.SHOPKEEP && [...state.hirees]->filter(by::(value) <- value.role == ROLES.SHOPKEEP)->size == state.additionalStorefrontCount) ::<= {
              windowEvent.queueMessage(
                text: 'You currently have no store front available to be kept by a hiree. Your main shop front must be kept by you. You can outfit your shop with additional store fronts by upgrading it.'
              );
            }
            
          
            hiree.role = choice-1;
          }
        );
      },
      
      removeHireeEntity::(entity) {
        @world = import(module:'game_singleton.world.mt');
    
        world.party.remove(member:entity);

        @hiree = state.hirees[state.hirees->findIndexCondition(::(value) <- value == entity)];
        state.hirees->remove(key:state.hirees->findIndex(value:hiree));
        windowEvent.queueMessage(
          text: entity.name + ' was removed from the hirees list.'
        );      
      },
      
      quit ::(hiree) {
        
        state.hirees->remove(key:state.hirees->findIndex(value:hiree));
        
        windowEvent.queueMessage(
          speaker : hiree.entity.name,
          text : random.pickArrayItem(
            list : [
              '"I think I\'ve had enough here. Have a good life."',
              '"I don\'t think this is working out how I expected. I think it\'s time we part ways."',
              '"Okay. That\'s it. No more."'
            ]
          ) 
        );
        
        windowEvent.queueMessage(
          text : hiree.entity.name + ' quits working for you.'
        );  
        
        state.accolade_hadEmployeeQuit = true;      
      },
      
      fire::(hiree) {
        windowEvent.queueAskBoolean(
          prompt: 'Fire ' + hiree.entity.name + '?',
          onChoice::(which) {
            when(which == false) empty;
            
            state.hirees->remove(key:state.hirees->findIndex(value:hiree));
            
            windowEvent.queueMessage(
              speaker : hiree.entity.name,
              text : random.pickArrayItem(
                list : [
                  '"Yeah, well, it wasn\'t exactly great working for you, either."',
                  '"Curse it all... How am I going to pay my bills now..."',
                  '"After all the work I did for you...?"',
                  '"Figures."'
                ]
              ) 
            );
            
            windowEvent.queueMessage(
              text : hiree.entity.name + ' walks away sadly...'
            );
          }
        );      
      },
      sellProperty ::(location) {
      
        windowEvent.queueMessage(
          text: location.ownedBy.name + '\'s ' + location.base.name + ' is currently worth ' + g(g:location.data.trader.listPrice) + '. Once put up for sale, it will no longer generate revenue.'
        );

        windowEvent.queueAskBoolean(
          prompt: 'Sell for ' + g(g:location.data.trader.listPrice) + '?',
          onChoice::(which) {
            when(which == false) empty;
            
            
            @:index = state.ownedProperties->findIndex(value:location.worldID);
            if (index == -1) error(detail: 'No such property');
            state.ownedProperties->remove(key:index);
            
            state.propertiesForSale->push(value:location.worldID);
          
            windowEvent.queueMessage(
              text: location.ownedBy.name + '\'s ' + location.base.name + ' is now up for sale for ' + g(g:location.data.trader.listPrice) + '.'
            );
          }
        );
      },
      
      manageProperties ::{
        @world = import(module:'game_singleton.world.mt');
        when(state.ownedProperties->size == 0 && state.propertiesForSale->size == 0)
          windowEvent.queueMessage(
            text: 'You don\'t currently have any properties except your shop.'
          );

        @:locations = [...state.ownedProperties, ...state.propertiesForSale]->map(to:::(value) <- world.island.findLocation(id:value));
        @:choicesColumns = import(module:'game_function.choicescolumns.mt');
        

        choicesColumns(
          onGetChoices ::{
            @:names = [];
            @:worth = [];
            @:status = [];
            foreach(locations) ::(i, location) {
              @:delta = location.data.trader.listPrice - location.data.trader.boughtPrice;

              names->push(value: location.ownedBy.name + '\'s ' + location.base.name);
              worth->push(value:g(g:location.data.trader.listPrice) + ' (' + (if(delta > 0) '+' else '') + g(g:delta) + ')');
              status->push(value: if (state.propertiesForSale->findIndex(value:location.worldID) == -1) 'Owned' else 'For sale');
            }
            return [
              names, worth, status
            ];
          },
          prompt: 'Properties owned:',
          header: ['Name', 'Worth', 'Status'],
          leftJustified : [true, true, true],
          leftWeight: 0.5,
          topWeight: 0.5,
          canCancel: true,
          keep : true,
          onChoice ::(choice) {
            when(choice == 0) empty;            
            @location = locations[choice-1];
      


            windowEvent.queueChoices(
              prompt: "Location: " + location.ownedBy.name + '\'s ' + location.name,
              leftWeight: 1,
              topWeight: 0.5,
              choices : [
                'Sell',
              ],
              canCancel : true,
              onChoice::(choice) {
                when(choice == 0) empty;
                
                when(state.propertiesForSale->findIndex(value:location.worldID) != -1)
                  windowEvent.queueMessage(
                    text: 'The property is already for sale.'
                  );
                if (choice == 1) this.sellProperty(location);
              }
            );
          }
        );

      
      },
      
      manageHirees :: {
        when(state.hirees->size == 0)
          windowEvent.queueMessage(
            text: 'You don\'t currently have anyone employed.'
          );
        
        @:choicesColumns = import(module:'game_function.choicescolumns.mt');
          
        choicesColumns(
          onGetChoices ::{
            @:names  = [];
            @:titles = [];
            @:wages  = [];
            @:moods  = [];
            @:status = [];
            foreach(state.hirees) ::(i, hiree) {
              names->push(value:hiree.entity.name);
              titles->push(value:hiree.title);
              wages->push(value:g(g:hiree.contractRate));
              moods->push(value:moodToString(mood:hiree.mood));
              status->push(value:roleToString(role:hiree.role));
            }
            return [
              names, titles, wages, moods, status
            ];
          },
          prompt: 'Hirees...',
          header : ['Name', 'Title', 'Wage', 'Mood', 'Status'],
          leftJustified : [true, true, true, true, true],
          leftWeight: 0.5,
          topWeight: 0.5,
          canCancel: true,
          keep : true,
          onChoice ::(choice) {
            when(choice == 0) empty;
            
            @hiree = state.hirees[choice-1];
            windowEvent.queueChoices(
              prompt: "Hiree: " + hiree.entity.name,
              leftWeight: 1,
              topWeight: 0.5,
              choices : [
                'Describe',
                'Set title',
                'Financial report',
                'Change role',
                'Fire'
              ],
              canCancel : true,
              onChoice::(choice) {
                when(choice == 0) empty;
                
                match(choice) {
                  (1): hiree.entity.describe(),
                  (2): hiree.setTitle(),
                  (3): hiree.report(),
                  (4): this.changeRole(hiree),
                  (5): this.fire(hiree)
                }
              }
            );
          }
        );
      },
      
      preflightCheckStart::(onDone, isShopkeeping) {
        @world = import(module:'game_singleton.world.mt');

        @preflightCheckStart_hireeInPartyWhenShopKeeping :: {
          when(isShopkeeping != true) nextChain();
          @hasWaitingHiree = false;
          foreach(state.hirees) ::(k, hiree) {
            if (hiree.role == ROLES.IN_PARTY) ::<= {
              hasWaitingHiree = true;
            }
          }
          
          when(hasWaitingHiree == false) nextChain();           
          
          windowEvent.queueMessage(
            text: 'You have one or more employees that are in your party, but you\'re not exploring today.'
          );
          
          windowEvent.queueAskBoolean(
            prompt: 'Start day with unassigned hiree tasks?',
            onChoice::(which) {
              when(which == false) empty;
              nextChain();
            }
          );
        }

        @preflightCheckStart_hireeswaiting :: {
          @hasWaitingHiree = false;
          foreach(state.hirees) ::(k, hiree) {
            if (hiree.role == ROLES.WAITING) ::<= {
              hasWaitingHiree = true;
            }
          }
          
          when(hasWaitingHiree == false) nextChain();           
          
          windowEvent.queueMessage(
            text: 'You have one or more employees that dont have a task.'
          );
          
          windowEvent.queueAskBoolean(
            prompt: 'Start day with unassigned hiree tasks?',
            onChoice::(which) {
              when(which == false) empty;
              nextChain();
            }
          );
        }

        @:preflightCheckStart_shopkeepingwithnostock :: {
          when(isShopkeeping == empty) nextChain();
          when(state.shopInventory.items->size != 0) nextChain();
          
          windowEvent.queueMessage(
            text: 'You\'ve chosen to open up shop, but have not stocked your shop yet with items from your inventory. (You have ' + world.party.inventory.items->size + ' item(s) in your inventory to stock the shop with.)'
          );
          
          windowEvent.queueAskBoolean(
            prompt: 'Start shopkeeping with empty shop?',
            onChoice::(which) {
              when(which == false) empty;
              nextChain();
            }
          );
          
        }


        @:chain = [
          preflightCheckStart_hireeswaiting,
          preflightCheckStart_hireeInPartyWhenShopKeeping,
          preflightCheckStart_shopkeepingwithnostock
        ]
        
        @:nextChain ::(cancel) {
          when(cancel) empty;
          when(chain->size == 0) onDone();
          @:val = chain[chain->size-1];
          chain->pop;
          val();
        }
        
        nextChain();
        
        
      },
      
      explore ::{
        windowEvent.queueChoices(
          prompt: 'What next?',
          choices : [
            'Manage...',
            'Start exploring!'
          ],
          keep:true,
          canCancel: true,
          onChoice::(choice) {
            when(choice == 0) empty;
            match(choice) {
              (1): this.manage(),
              
              (2): ::<= {
                this.preflightCheckStart(
                  onDone :: {
                    @world = import(module:'game_singleton.world.mt');
                    @:instance = import(module:'game_singleton.instance.mt');
                    world.loadIslandID(id:state.islandID);
                    instance.islandTravel();

                    foreach(state.hirees) ::(k, hiree) {
                      if (hiree.role == ROLES.IN_PARTY)
                        hiree.addToParty();
                    }

                    
                    @:landmarks = world.island.landmarks;
                    @:city = landmarks[landmarks->findIndexCondition(::(value) <- value.worldID == state.cityID)];
                    
                    @:locations = city.locations;
                    @:shop = locations[locations->findIndexCondition(::(value) <- value.worldID == state.shopID)]

                    breakpoint();
                    instance.visitLandmark(
                      landmark:city,
                      where: ::(landmark)<- shop
                    );        

                    windowEvent.jumpToTag(name:'day-start', goBeforeTag:true, doResolveNext:true);
                  }
                )
              }
            }
          }
        );      
      },
      
      stockShop ::{
        @world = import(module:'game_singleton.world.mt');

        @:shopInventory ::{
          when(state.shopInventory.items->size == 0)
            windowEvent.queueMessage(
              text: 'The shop has no items stocked. You have to stock it from your inventory first.'
            );
          
          pickItemStock(
            prompt: 'Current shop stock:',
            traderState : state,
            inventory: state.shopInventory,
            canCancel: true,
            goldMultiplier: 1 / STANDARD_REDUCTION_PRICE, // standard rate
            topWeight: 0.5,
            leftWeight: 0.5,
            onPick ::(item) {
              windowEvent.queueChoices(
                prompt: item.name,
                leftWeight: 1,
                canCancel: true,
                choices: [
                  'Check',
                  'Move to inventory'
                ],
                
                onChoice::(choice) {
                  when(choice == 0) empty;
                  match(choice) {
                    (1): ::<= {
                      item.describe();
                    },
                    
                    (2): ::<= {
                      when (world.party.inventory.isFull) ::<= {
                        windowEvent.queueMessage(
                          text: 'The party inventory is full.'
                        ); 
                      }

                      state.shopInventory.remove(item);
                      world.party.inventory.add(item);
                    }           
                  }
                }
              );
            }
          );
        }
      
        @:ownInventory ::{
          when(world.party.inventory.items->size == 0)
            windowEvent.queueMessage(
              text: 
                if (state.sellingLevel >= LEVEL_HIRE_EMPLOYEES)
                  'You have no items to stock the shop with. Perhaps you should hire someone to look for items. Otherwise, you must explore on your own to find things to sell.'
                else
                  'You have no items to stock the shop with. For now, you must explore on your own to find things to sell.'
            );
          
          pickItemStock(
            prompt: 'Current inventory:',
            traderState : state,
            inventory: world.party.inventory,
            canCancel: true,
            goldMultiplier: 1 / STANDARD_REDUCTION_PRICE,
            topWeight: 0.5,
            leftWeight: 0.5,
            onPick ::(item) {
              windowEvent.queueChoices(
                prompt: item.name,
                leftWeight: 1,
                canCancel: true,
                choices: [
                  'Stock in shop',
                  'Check'
                ],
                
                onChoice::(choice) {
                  when(choice == 0) empty;
                  match(choice) {                    
                    (1): ::<= {
                    
                      when ((item.base.traits & Item.TRAIT.KEY_ITEM) != 0)
                        windowEvent.queueMessage(
                          text:'You feel unable to part with this.'
                        )
                    
                    
                      when (state.shopInventory.isFull) ::<= {
                        windowEvent.queueMessage(
                          text: 
                          if (state.sellingLevel >= LEVEL_UPGRADE_SHOP0)
                            'The shop stock is full. The shop can be upgraded to hold more items.'
                          else 
                            'The shop stock is full.'
                        ); 
                      }

                      world.party.inventory.remove(item);
                      state.shopInventory.add(item);
                    },
                    (2): ::<= {
                      item.describe();
                    }
                    
                            
                  }
                }
              );
            }
          );
        }      
      
        windowEvent.queueChoices(
          prompt: 'Shop stocking',
          keep: true,
          choices : [
            "Check shop stock",
            "Stock from inventory"
          ],
          canCancel : true,
          onChoice::(choice) {
            when(choice == 0) empty;
            
            match(choice) {
              (1): shopInventory(),
              (2): ownInventory()
            }
          }
        );
      },
      
      // starts the haggling process.
      // When done, onDone is called with the following arguments:
      // - bought, a boolean saying whether it was bought 
      // - price, the final offer that was given before buying or not buying.
      haggle::(shopper, displayName, id, standardPrice, onDone) {
        @worthless = standardPrice < 1;
        if (standardPrice < 1) standardPrice = 1;
      
        @offer = standardPrice;
        @tries = 0;
        @lastOffer = 0.5;

        @isPopular = ::<= {          
          @:popular   = state.popular;
          return (popular->findIndex(value:id) != -1)
        }          

        @isUnpopular = ::<= {          
          @:unpopular   = state.unpopular;
          return (unpopular->findIndex(value:id) != -1)
        }          

        
        // personality determines how much theyre willing to go above 
        // the baseline haggle limit
        @:shopperWillingToPay = ::<= {
          // for custom or unknown personality types
          @:defaultCalculation::{
            @:stats = shopper.personality.growth;
            // Personality's more big-brain stats affect this.
            @base = (stats.INT + stats.LUK + stats.AP) / (stats.sum);
            if (base < 0) base = 0;
            if (base > 1) base = 1;
            base = 1 - base;
            return base;       
          }
          
          @base = match(shopper.personality.name) {
            ('Friendly'):     (standardPrice * 1.56)->floor,
            ('Short-tempered'): (standardPrice * 1.13)->floor,
            ('Quiet'):      (standardPrice * 1.28)->floor,
            ('Charismatic'):  (standardPrice * 1)->floor,
            ('Caring'):     (standardPrice * 1.3)->floor,
            ('Cold'):       (standardPrice * 1.15)->floor,
            ('Disconnected'):   (standardPrice * 1.45)->floor,
            ('Inquisitive'):  (standardPrice * 1.25)->floor,
            ('Curious'):    (standardPrice * 1.2)->floor,
            ('Calm'):       (standardPrice * 1.3)->floor,
            default: defaultCalculation()
          }
          base *= 1+0.2*(random.number() -.5); // still can vary a bit          
          base *= 1.05; // people are generally reasonable
          
          // cheapskates or splurgers
          if (random.try(percentSuccess:15)) 
            if (random.flipCoin())
              base *= 0.9
            else
              base *= 1.1
          ;
          
          base = base + ((state.sellingLevel-1)*0.03 * standardPrice)->ceil;

          when(isPopular)   base * 2;
          when(isUnpopular) (base * 0.5)->floor;
          
          if (base < 1) base = 1;
          return base;
        }
        
        @:offerFromFraction::(fraction) {
          @:min = standardPrice * 0;
          @:max = standardPrice * 2 + (standardPrice * (state.sellingLevel-1) * 0.05)->ceil;
          
          return (fraction * (max - min) + min)->ceil;
        }
        
        @haggleNext :: {
          windowEvent.queueSlider(
            renderable : {
              render ::{
                canvas.renderTextFrameGeneral(
                  lines: canvas.refitLines(input:[
                    shopper.name + ' wants to buy: ',
                    displayName + ' (worth: ' + (if(worthless) 'WORTHLESS' else g(g:standardPrice)) + ')',
                    if (isPopular) 'NOTE: this item is currently in demand.' else if (isUnpopular) 'NOTE: this item is currently experiencing a price-drop.' else '',
                    'Their personality seems to be: ' + shopper.personality.name
                  ]),
                  topWeight: 0,
                  leftWeight: 0.5
                );
                
                @delta = offer - standardPrice;
                canvas.renderTextFrameGeneral(
                  lines: [
                    'Current offer: ' + g(g:offer) + " (" + (if(delta >= 0) '+'+delta else delta) + ")",
                  ],
                  topWeight: 1,
                  leftWeight: 0.5
                );

              }
            },
            prompt: 'Offer for how much?',
            increments: 60,
            defaultValue : lastOffer,
            topWeight: 0.6,
            
            onHover ::(fraction) {
              offer = offerFromFraction(fraction);
            },
            
            onChoice ::(fraction) {
              lastOffer = fraction;
              offer = offerFromFraction(fraction);
              windowEvent.queueMessage(
                text: '"How about ' + g(g:offer) + '? ' +
                  random.pickArrayItem(
                    list : [
                      'Surely that\'s a reasonable price."',
                      'That is about the best I can do."',
                      'A great choice, by the way."',
                      'Truly a fine piece."',
                      'You have a great eye."',
                      'It breaks my heart to part with it."',
                      'It is great indeed, indeed."'
                    ]
                  )
              );
              
              if (offer > shopperWillingToPay) ::<= {
                tries += 1;
                if (tries > 2) ::<= {
                  windowEvent.queueMessage(
                    speaker: shopper.name,
                    text : random.pickArrayItem(
                      list : [
                        '"Sorry, I think I\'ll reconsider this purchase."',
                        '"Sorry, I just think that\'s too expensive."',
                        '"I think I\'ve had enough haggling for one day."'
                      ]
                    )
                  );
                  onDone(bought:false, price:offer, accuracy:0);
                  state.accolade_failedToHaggle = true;
                } else ::<= {
                  windowEvent.queueMessage(
                    speaker: shopper.name,
                    text : random.pickArrayItem(
                      list : [
                        '"Ah, I cannot afford this price... Surely you could go lower?"',
                        '"I really want this, but that\'s too expensive."',
                        '"I don\'t think it\'s worth this much..."'
                      ]
                    )
                  );
                  haggleNext();
                }
              } else ::<= {
                windowEvent.queueMessage(
                  speaker: shopper.name,
                  text : random.pickArrayItem(
                    list : [
                      '"Sure, that sounds reasonable."',
                      '"Well, alright!"'
                    ]
                  )
                );  
                if (id == 'thetrader:shipment')
                  state.accolade_soldAShipment = true;
                  
                if (worthless)
                  state.accolade_soldAWorthlessItem = true;

                state.totalEarnedSales += offer;
                @accuracy = (shopperWillingToPay - (offer - shopperWillingToPay)->abs) / shopperWillingToPay;
                if (fraction == 1)
                  accuracy = 0.95; // default accuracy if you maxed out the slider
                onDone(bought:true, price:offer, accuracy);
              }
            }
          );
        }
        haggleNext();
      },
      
      finishDay ::(landmark, island) {
        @world = import(module:'game_singleton.world.mt');
        if (world.time <= 3)
          world.wait(until:4)            
        

        world.wait(until:3)       
      },

      startShopDay :: {
        @world = import(module:'game_singleton.world.mt');

        // find shop
        @:instance = import(module:'game_singleton.instance.mt');
        //instance.visitIsland();
        @:landmark = world.island.landmarks->filter(by::(value) <- value.worldID == state.cityID)[0];
        @:location = landmark.locations->filter(by::(value) <- value.worldID == state.shopID)[0];

        @:item = landmark.map.getItem(data:location);
        landmark.map.setPointer(
          x: item.x,
          y: item.y
        );




        windowEvent.queueCustom(
          keep:true,
          renderable:landmark.map,
          jumpTag: 'day-start-shop',
          onEnter:: {

            windowEvent.queueMessage(
              text: 'The shop is now open!'
            );

            windowEvent.queueMessage(
              text: '...'
            );

            @maxPerHour = (
              (state.shopInventory.items->size / 4.5)
            )->ceil;
            
            if (maxPerHour < 3)
              maxPerHour = 3;
            if (maxPerHour > 5)
              maxPerHour = 5;


            @shopperList = [];

            @:endShopDay :: {
              this.finishDay();         
              windowEvent.jumpToTag(name:'day-start-shop', goBeforeTag:true, doResolveNext:true);
            }
              
            @:startHour ::{
            
              when (world.time > world.TIME.EVENING) ::<= {
                windowEvent.queueMessage(
                  speaker: world.party.members[0].name,
                  text: '"It\'s gotten pretty late... Guess it\'s time to close up shop."',
                  onLeave:: {
                    endShopDay();
                  }
                );          
              }
                
              when(state.shopInventory.items->size == 0) ::<= {
                windowEvent.queueMessage(
                  text: 'The shop has no more items to sell for the day.',
                  onLeave :: {
                    endShopDay();              
                  }
                );
              };

              @shoppers = random.integer(from:0, to:maxPerHour);


              windowEvent.queueMessage(
                text: 'Some time passes...' + world.getDayString()
              );

              if (state.recession > 0)
                shoppers = if (random.try(percentSuccess:20)) 1 else 0;


              when (shoppers == 0)
                windowEvent.queueMessage(
                  text: random.pickArrayItem(
                    list : [
                      "Awfully quiet this hour...",
                      "Nope. No customers anywhere...",
                      "I wonder where the shoppers are...",
                      "Maybe I should put a new sign up..."
                    ]   
                  ),
                  onLeave :: {
                    finishHour();              
                  }
                )

              // welcome the shoppers
              windowEvent.queueMessage(
                text: '' + shoppers + (if (shoppers == 1) ' customer' else ' customers') + ' arrived at the shop.'
              );
              
              
              shopperList = [];
              for(0, shoppers) ::(i) {
                shopperList->push(value:world.island.newInhabitant());
              }
              
              nextShopper();
            }
            
            
            @:nextShopper ::{
              when(shopperList->size == 0) finishHour();
              when(state.shopInventory.items->size == 0) finishHour();
              @:shopper = shopperList->pop;

              shopper.anonymize();
              
              @:item = random.pickArrayItem(list:state.shopInventory.items);
              
              windowEvent.queueMessage(
                speaker: shopper.name,
                text: (random.pickArrayItem(
                  list : [
                    '"Hello! I would like this $, please."',
                    '"Hmm this one looks interesting. I would like the $, please."',
                    '"This would make an excellent gift. I\'ll take one $."',
                    '"Wow I love these! I\'ll take one $!"'
                  ]
                ))->replace(key:'$', with: item.name)

              );
              
              /// barter logic
              this.haggle(
                shopper,
                displayName:item.name,
                id : item.base.id,
                standardPrice: (item.price / STANDARD_REDUCTION_PRICE)->ceil,
                onDone::(bought, price, accuracy) {
                  if (bought) ::<= {
                    windowEvent.queueMessage(
                      text: shopper.name + ' bought the ' + item.name + ' for ' + g(g:price) + '.'
                    );
                    state.shopInventory.remove(item);
                    

                    
                    world.party.addGoldAnimated(
                      amount:price,
                      onDone :: {
                        this.animateGainExp(
                          price,
                          accuracy,
                          onDone ::{
                            nextShopper();                          
                          }
                        );
                      }
                    )  
                    
                    
                                      
                  } else ::<= {
                    windowEvent.queueMessage(
                      text: shopper.name + ' left without buying anything.'
                    );                  
                    nextShopper();            
                  }
                
                }
              )              
            }
            
            @:finishHour ::{
              @:hour = world.time;
              {:::} {
                forever ::{
                  when(world.time == hour)
                    world.incrementTime();
                  send();
                }
              }   
              startHour();                
            }
            startHour();
                    
          }
        )
        windowEvent.jumpToTag(name:'day-start', goBeforeTag:true, doResolveNext:true);

      },
      
      
      upgradeShop ::{ 
        @:upgradeShop_space = ::{
          @:current = state.shopInventory.maxItems;
          
          when (state.workOrder != 0)
            windowEvent.queueMessage(
              text: 'A work order for upgrading has already been placed.'
            );
          
          @table = [
            100,
            300,
            500,
            700,
            1400,
            2200,
            4000,
            8300,
            12000,
            18000,
            26000,
            40000,
            78000,
            112000
          ]
          

          @:costNext = table[((current - 10)/5)->floor];
          when(costNext == empty)
            windowEvent.queueMessage(
              text: 'Your shop cannot be upgraded any further in this way.'
            );
          
          windowEvent.queueMessage(
            text: 'Your shop can currently hold ' + current + ' items in its stock. It will cost ' + g(g:costNext) + ' in supplies to increase the stock. If upgraded, it will take a day to complete the order.'
          );
          
          windowEvent.queueAskBoolean(
            prompt: 'Upgrade shop for ' + g(g:costNext) + '?',
            onChoice::(which) {
              when(which == false) empty;
              @:world = import(module:'game_singleton.world.mt');
              
              if (costNext > world.party.inventory.gold)
                windowEvent.queueMessage(
                  text: 'You cannot afford to upgrade the shop at this time.'
                );
                
              windowEvent.queueMessage(
                text: 'Your work order upgrade should finish tomorrow.'
              );
              
              world.party.addGoldAnimated(
                amount:-costNext,
                onDone::{
                
                }
              )
              state.workOrder = WORK_ORDER__SPACE;
            }
          );
        }
        
        
        @:upgradeShop_fronts = ::{
          when (state.workOrder != 0)
            windowEvent.queueMessage(
              text: 'A work order for upgrading has already been placed.'
            );
          
          @table = [
            1000,
            3000,
            14000,
            27000,
            40000,
            74000,
            100200,
            220000,
          ]
          

          @:costNext = table[state.additionalStorefrontCount];
          when(costNext == empty)
            windowEvent.queueMessage(
              text: 'Your shop cannot be upgraded any further in this way.'
            );
          
          windowEvent.queueMessage(
            text: 'Your shop can currently has '+state.additionalStorefrontCount+' additional store fronts. Additional store fronts can be managed by hirees, allowing you to sell items either simultaneously, or while you are away. It will cost ' + g(g:costNext) + ' in supplies to add an additional store front. If upgraded, it will take a day to complete the order.'
          );
          
          windowEvent.queueAskBoolean(
            prompt: 'Upgrade shop for ' + g(g:costNext) + '?',
            onChoice::(which) {
              when(which == false) empty;
              @:world = import(module:'game_singleton.world.mt');
              
              if (costNext > world.party.inventory.gold)
                windowEvent.queueMessage(
                  text: 'You cannot afford to upgrade the shop at this time.'
                );
                
              windowEvent.queueMessage(
                text: 'Your work order upgrade should finish tomorrow.'
              );
              
              world.party.addGoldAnimated(
                amount:-costNext,
                onDone::{}
              );
              state.workOrder = WORK_ORDER__FRONT;
            }
          );
        }
        
        @:choiceNames = ['Stock size'];
        @:choices = [
          upgradeShop_space
        ]
        
        if (state.sellingLevel >= LEVEL_UPGRADE_SHOP1) ::<= {
          choiceNames->push(value:'Add store front');
          choices->push(value:upgradeShop_fronts);
        }
          
        
        windowEvent.queueChoices(
          prompt: 'Upgrades...',
          choices : choiceNames,
          canCancel: true,          
          onChoice::(choice) {
            choices[choice-1]();
          }
        );
        
      },
      
      state : {
        get ::<- state
      },
      
      openShop :: {
      
        @:choiceNames = [];
        @:choices = [];
        
        choiceNames->push(value:'Manage...');
        choices->push(value:this.manage);
        
        choiceNames->push(value:'Stock shop');
        choices->push(value: this.stockShop);
        
        if (state.sellingLevel >= LEVEL_UPGRADE_SHOP0) ::<= {
          choiceNames->push(value: 'Upgrade shop');
          choices->push(value: this.upgradeShop);
        } else ::<= {
          choiceNames->push(value: '????');
          choices->push(
            value:::{
              windowEvent.queueMessage(
                text: 'This option isn\'t available yet. You feel that you need to gain more experience as a salesperson before this is relevant.'
              ); 
            }           
          )
        }
        
        choiceNames->push(value:'Start the day!');
        choices->push(value: ::{
          this.preflightCheckStart(onDone::{this.startShopDay();}, isShopkeeping:true)        
        });

        


      
        windowEvent.queueChoices(
          prompt: 'Shop options:',
          choices : choiceNames,
          keep:true,
          canCancel: true,
          onChoice::(choice) {
            when(choice == 0) empty;
            choices[choice-1]();
          }
        );
      }            
    }
  }
)







@:interactionsPerson = [
  commonInteractions.person.barter,
  InteractionMenuEntry.new(
    name: 'Hire with contract',
    keepInteractionMenu: true,
    filter ::(entity) {
      @:world = import(module:'game_singleton.world.mt');
      @:party = world.party;
      @:trader = world.scenario.data.trader;

      return trader.state.sellingLevel >= LEVEL_HIRE_EMPLOYEES;
    },
    onSelect ::(entity, location) {
      @:this = entity;
      when(this.isIncapacitated())
        windowEvent.queueMessage(
          text: this.name + ' is not currently able to talk.'
        );          
        
      @:world = import(module:'game_singleton.world.mt');
      @:party = world.party;
      @:trader = world.scenario.data.trader;
      
      // prevents a few ownership issues that can come up naturally 
      // by mixing property ownership and employee hiring
      when (entity.owns != empty && trader.isPropertyOwned(location:entity.owns))
        windowEvent.queueMessage(
          speaker: this.name,
          text: random.pickArrayItem(list:this.personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_DENY])
        );        



      when(trader.isHired(entity:this))
        windowEvent.queueMessage(
          text: this.name + ' is already employed by you.'
        );        
      
      /*when (!this.adventurous)
        windowEvent.queueMessage(
          speaker: this.name,
          text: random.pickArrayItem(list:this.personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_DENY])
        );        
      */  
      windowEvent.queueMessage(
        speaker: this.name,
        text: random.pickArrayItem(list:this.personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_ACCEPT])
      );        

      @highestStat = 0;
      if (this.stats.ATK > highestStat) highestStat = this.stats.ATK;
      if (this.stats.DEF > highestStat) highestStat = this.stats.DEF;
      if (this.stats.INT > highestStat) highestStat = this.stats.INT;
      if (this.stats.SPD > highestStat) highestStat = this.stats.SPD;
      if (this.stats.LUK > highestStat) highestStat = this.stats.LUK;
      if (this.stats.DEX > highestStat) highestStat = this.stats.DEX;



      @cost;
      
      cost = hireeContractWorth(entity:this);
      this.describe();

      windowEvent.queueAskBoolean(
        prompt: 'Hire for ' + g(g:cost) + ' a day?',
        onChoice::(which) {
          when(which == false) empty;

          @:hiree = trader.addHiree(
            entity:this,
            rate: cost
          );
          if (world.party.members->size == 3)
            windowEvent.queueMessage(
              text: this.name + ' was hired! They\'ll start working for you tomorrow. Be sure to assign them a task.'
            )
          else ::<= {
            windowEvent.queueMessage(
              text: this.name + ' was hired! You have the option to add them to your party now if you wish. Otherwise, you can assign them a task tomorrow.'
            );
            
            windowEvent.queueAskBoolean(
              prompt: 'Add to party now?',
              onChoice::(which) {
                when(which == false) empty;
                hiree.addToParty();  
              }
            );            
            
          
          }   

          world.accoladeIncrement(name:'recruitedCount');                    
          // the location is the one that has ownership over this...
          if (this.owns != empty)
            this.owns.ownedBy = empty;
            
        }
      );    
    }
  )
];










return {
  name : 'The Trader',
  id : 'rasa:thetrader',
  onBegin ::(data) {
    windowEvent.queueMessage(
      text: 'This scenario autosaves on the end of each day. Manual saves will not be possible.'
    );
  
    @:instance = import(module:'game_singleton.instance.mt');
    @:story = import(module:'game_singleton.story.mt');
    @world = import(module:'game_singleton.world.mt');
    @:LargeMap = import(module:'game_singleton.largemap.mt');
    @party = world.party;      


    {:::} {
      forever ::{
        if (world.time == world.TIME.MORNING) send();
        world.incrementTime();
      }
    }
  
    @:keyhome = Item.new(
      base: Item.database.find(id:'thetrader:wyvern-key')
    );
    keyhome.name = 'Key: Home';
    
    @:Island = import(module:'game_mutator.island.mt');
    keyhome.setIslandGenTraits(
      nameHint:namegen.island(), 
      levelHint:story.levelHint,
      idHint: 'thetrader:starting-island',
      tierHint: 0  
    )
    world.loadIsland(key:keyhome, skipSave:true);

    party = world.party;
    party.reset();
    party.inventory.maxItems = 70;
    @:island = world.island;
    party.inventory.add(:keyhome);


    
    // debug
      //party.inventory.addGold(amount:100000);

    
    // since both the party members are from this island, 
    // they will already know all its locations
    foreach(world.island.landmarks)::(index, landmark) {
      landmark.discover(); 
    }
    
    
    
    @:Species = import(module:'game_database.species.mt');
    @:p0 = island.newInhabitant(professionHint: 'base:trader', levelHint:story.levelHint);
    p0.normalizeStats();

    

    // Add initial inventory.
    for(0, 15)::(i) {
      party.inventory.add(item:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE)
                      && value.tier <= world.island.tier
          ),
          from:p0, 
          rngEnchantHint:true,
          forceNeedsAppraisal: false
        )
      );
    }

    party.add(member:p0);
    party.inventory.addGold(amount:250);
    
    
    
    // setup shop
    @:city = island.landmarks->filter(by::(value) <- value.base.id == 'thetrader:city')[0];      
    @:shop = city.locations->filter(by::(value) <- value.base.id == 'thetrader:shop')[0];
    shop.ownedBy = empty;

    data.trader = TraderState.new(
      city,
      shop
    );
    party.inventory.add(item:
      Item.new(
        base:Item.database.find(id:'base:gold-pouch'),
        from:p0
      )
    );

    @:basicArts = [
      'base:pebble',
      'base:brace',
      'base:retaliate',
      'base:reevaluate',
      'base:agility',
      'base:foresight',
      'base:mind-games',
      'base:wyvern-prayer'
    ];

    p0.supportArts = [...basicArts];


      
      /*
      //party.inventory.addGold(amount:250000);
      party.inventory.addGold(amount:2500);
      
      world.island.tier = 3;
      
      
      
      data.trader.addHiree(
        entity: world.island.newInhabitant(),
        rate:117
      );
      data.trader.addHiree(
        entity: world.island.newInhabitant(),
        rate:103
      );
      data.trader.addHiree(
        entity: world.island.newInhabitant(),
        rate:157
      );
          
      party.inventory.add(item:
        Item.new(
          base:Item.database.find(id:'Shipment'),
          from:p0
        )
      );

      party.inventory.add(item:
        Item.new(
          base:Item.database.find(id:'Crate'),
          from:p0
        )
      );
      */
      

    @somewhere = LargeMap.getAPosition(map:island.map);
    island.map.setPointer(
      x: somewhere.x,
      y: somewhere.y
    );         
    instance.savestate();
    @:Scene = import(module:'game_database.scene.mt');
    Scene.start(id:'thetrader:scene_intro', onDone::{          
      data.trader.dayStart();        
    });    
    
    
    
    
  },

  onNewDay ::(data){
    when(data.trader == empty) empty;
    data.trader.newDay();
  },

  
  interactionsPerson : interactionsPerson,
  interactionsLocation : [
    InteractionMenuEntry.new(
      name : 'Buy property',
      keepInteractionMenu: true,
      filter ::(location) {
        @world = import(module:'game_singleton.world.mt');
        @:trader = world.scenario.data.trader;      
        when(trader.state.sellingLevel < LEVEL_BUY_PROPERTY) false;
      
        @:Location = import(module:'game_mutator.location.mt');
        return 
          location.ownedBy != empty && 
          trader.ownedProperties->findIndex(value:location.worldID) == -1 &&
          (
            location.base.category == Location.CATEGORY.RESIDENTIAL ||
            location.base.category == Location.CATEGORY.UTILITY ||
            location.base.category == Location.CATEGORY.BUSINESS
          )
        ;
      },
          
      onSelect::(location) {
        @world = import(module:'game_singleton.world.mt');
        @:trader = world.scenario.data.trader;
        
        when(location.ownedBy == empty)
          windowEvent.queueMessage(
            text: 'This property\'s owner is currently not present.'
          );
          
        
        when(trader.ownedProperties->findIndex(value:location.worldID) != -1)
          windowEvent.queueMessage(
            text: 'This property is already owned by you.'
          );

        @:Location = import(module:'game_mutator.location.mt');
        if (location.data.trader == empty)
          location.data.trader = {};
         
        // generate list price   
        if (location.data.trader.listPrice == empty) ::<= {
          @basePrice = match(location.base.category) {
            // residential properties can be bought, and thee owners become 
            // tennants
            (Location.CATEGORY.RESIDENTIAL): random.pickArrayItem(list:[9000, 12000, 8000, 14000, 5000]),
            (Location.CATEGORY.BUSINESS): random.pickArrayItem(list:[100000, 120000, 89000, 160000]),
            (Location.CATEGORY.UTILITY): random.pickArrayItem(list:[30000, 35000, 22000, 45000])
          }
          
          location.data.trader.listPrice = random.integer(from:(basePrice * 0.8)->floor, to:(basePrice * 1.2)->floor);
        }

        windowEvent.queueMessage(
          text: location.ownedBy.name + '\'s ' + location.base.name + ' is available for purchase for ' + g(g:location.data.trader.listPrice) + '.'
        );
        
        when(world.party.inventory.gold < location.data.trader.listPrice)
          windowEvent.queueMessage(
            text: 'The party cannot afford to buy this property.'
          );

        windowEvent.queueAskBoolean(
          prompt: 'Buy property for ' + g(g:location.data.trader.listPrice) + '?',
          onChoice::(which) {
            when(which == false) empty;
            
            world.party.addGoldAnimated(
              amount: -location.data.trader.listPrice,
              onDone ::{

                location.data.trader.boughtPrice = location.data.trader.listPrice;

                
                @:trader = world.scenario.data.trader;
                trader.ownedProperties->push(value: location.worldID);

                if (location.data.trader.listPrice > 100000)
                  trader.state.accolade_boughtBusinessOver100000G = true;

                windowEvent.queueMessage(
                  text: 'Congratulations! You now own ' + location.ownedBy.name + '\'s ' + location.base.name + '.'
                );
                
                if (location.base.category == Location.CATEGORY.RESIDENTIAL)
                  windowEvent.queueMessage(
                    text: 'This residence will pay you rent daily based on a percentage of the price you bought it at.'
                  )
                else              
                  windowEvent.queueMessage(
                    text: 'This business will pay you a percentage of their profits at the end of the day. This rate will be variable, but scales with how expensive the business is.'
                  )
              
              }
            );
          }
        );
          
        
      }
    )
  ],
  onResume ::(data) {
    @:trader = data.trader;
    trader.dayStart();        
  },
  
  onDeath ::(data, entity) {
    @:world = import(module:'game_singleton.world.mt')
    when (entity == world.party.members[0]) ::<= {
      @:instance = import(module:'game_singleton.instance.mt');
      instance.gameOver(reason:
        'The Trader ' + entity.name + '\'s journey comes to an end...'      
      );
    }
    
    data.trader.removeHireeEntity(entity);
  },
  skipName : false,

  interactionsLandmark : [],
  interactionsWalk : [
    commonInteractions.walk.check,
    InteractionMenuEntry.new(
      name: 'Finances',
      keepInteractionMenu: true,
      filter::(island, landmark) <- true,
      onSelect::(island, landmark) {
        @:world = import(module:'game_singleton.world.mt')
        world.scenario.data.trader.finances();
      }
    ),
    commonInteractions.walk.party,
    commonInteractions.walk.inventory,
    InteractionMenuEntry.new(
      name: 'Finish Day',
      keepInteractionMenu: true,
      filter::(island, landmark) { 
        @:Landmark = import(module:'game_mutator.landmark.mt');

        return if (landmark != empty && landmark.base.id == 'thetrader:fortune-wyvern-dimension')
          false
        else
          landmark == empty || landmark.base.hasTraits(:Landmark.TRAIT.POINT_OF_NO_RETURN) == false
      },
      onSelect::(island, landmark) {
        windowEvent.queueAskBoolean(
          prompt: 'Wait until next day to open shop / explore?',
          onChoice::(which) {
            when(which == false) empty;
            @world = import(module:'game_singleton.world.mt');
            world.scenario.data.trader.finishDay(landmark);             
          }
        );
      }
    )
  ],
  interactionsBattle : [
    commonInteractions.battle.attack,
    commonInteractions.battle.arts,
    commonInteractions.battle.check,
    commonInteractions.battle.item,
    commonInteractions.battle.wait
  ],
  interactionsOptions : [
    commonInteractions.options.system,
    commonInteractions.options.quit
  ],
  
  accolades : [
    Accolade.new(
      message: "Lucky, lucky!",
      info : 'Won a gambling game.',
      condition::(world)<- world.accoladeEnabled(name:'wonGamblingGame')    
    ),
    
    Accolade.new(
      message: "Honestly, the Arena is a little brutal...",
      info : 'Won an Arena bet.',
      condition::(world)<- world.accoladeEnabled(name:'wonArenaBet')
    ),
    
    Accolade.new(
      message: "Should have kicked them out a while ago.",
      info: 'Fought a drunkard at the tavern.',
      condition::(world)<- world.accoladeEnabled(name:'foughtDrunkard')
    ),





    Accolade.new(
      message: "Sly salesperson.",
      info : 'Got an S rank sale.',
      condition::(world)<- world.scenario.data.trader.state.accolade_srank   
    ),

    Accolade.new(
      message: 'Business is not-so-booming anymore, is it?',
      info: 'Managed to get caught up in an economic recession.',
      condition ::(world) <- world.scenario.data.trader.state.accolade_experiencedRecession
    ),
  
    Accolade.new(
      message: 'Voted best place to work on the island!',
      info: 'No employees got murdered.',
      condition ::(world) <- world.scenario.data.trader.state.accolade_noEmployeesLost && world.accoladeCount(name:'deadPartyMembers') == 0
    ),

    Accolade.new(
      message: 'Wow uh. Your employee is a little on the intense side...',
      info: 'Have a hiree complete a dungeon run and get a Masterwork item at the end.',
      condition ::(world) <- world.scenario.data.trader.state.accolade_employeeCompletedDungeon
    ),

    Accolade.new(
      message: 'You don\'t have to make THAT much of a profit, you know.',
      info: 'Have a customer leave after haggling to aggressively.',
      condition ::(world) <- world.scenario.data.trader.state.accolade_failedToHaggle
    ),
    
    Accolade.new(
      message: 'Voted best place to work on the island*! (* by our employees)',
      info: 'Agree to a wage of over 1,000G.',
      condition ::(world) <- world.scenario.data.trader.state.accolade_raiseOver1000G
    ),


    Accolade.new(
      message: 'It\'s not scalping if it\'s a property... That\'s called an investment!',
      info: 'Sold a property for a profit.',
      condition ::(world) <- world.scenario.data.trader.state.accolade_soldAPropertyProfit
    ),

    Accolade.new(
      message: 'Hey! Where\'d you find that? More importantly, how did you carry that around?',
      info: 'Find and sell a material shipment.',
      condition ::(world) <- world.scenario.data.trader.state.accolade_soldAShipment
    ),

    Accolade.new(
      message: 'Got money to spend, I guess.',
      info: 'Bought a business worth over 100,000G.',
      condition ::(world) <- world.scenario.data.trader.state.accolade_boughtBusinessOver100000G
    ),
    
    Accolade.new(
      message: 'You probably should have given them the raise.',
      info: 'Had an employee quit.',
      condition ::(world) <- world.scenario.data.trader.state.accolade_hadEmployeeQuit
    ),

    Accolade.new(
      message: 'Like a finely-tuned machine.',
      info: 'Had 5 simultaneous hirees.',
      condition ::(world) <- world.scenario.data.trader.state.accolade_5simultaneousHiree
    ),

    Accolade.new(
      message: 'A true trader.',
      info: 'Raise 250,000G for the Wyvern of Fortune in fewer than 50 days.',
      condition ::(world) <- world.scenario.data.trader.state.days < 50
    ),

    Accolade.new(
      message: 'Someone\'s gotta buy it, right?',
      info: 'Sold a worthless item to a customer.',
      condition ::(world) <- world.scenario.data.trader.state.accolade_soldAWorthlessItem
    )
    // TODO: completing a dungeon by hand is an accolade
  ],
  
  reportCard :: {
    @world = import(module:'game_singleton.world.mt');
    @trader = world.scenario.data.trader;
    return 
      'Days taken  : ' + trader.state.days + '\n' +
      'Final total : ' + g(g:world.party.inventory.gold) + '\n' +
      'Properties  : ' + (trader.state.ownedProperties->size + trader.state.propertiesForSale->size) + '\n' +
      'Hirees      : ' + (trader.state.hirees->size) + '\n' +
      ' - Earnings -\n' +
      'Investments : ' + g(g:trader.state.totalEarnedInvestments) + '\n' +
      'Sales       : ' + g(g:trader.state.totalEarnedSales) + '\n'
  },
  
  databaseOverrides ::{
    @:Interaction = import(module:'game_database.interaction.mt');
  
    // Overridden
    Interaction.newEntry(
      data : {
        name : 'Explore Pit',
        id :  'base:explore-pit',
        keepInteractionMenu : false,
        onInteract ::(location, party) {
          @:world = import(module:'game_singleton.world.mt');
          @:Event = import(module:'game_mutator.event.mt');

          if (location.targetLandmark == empty) ::<={
            @:Landmark = import(module:'game_mutator.landmark.mt');
            

            location.targetLandmark = Landmark.new(
              base:Landmark.database.find(id:'base:treasure-room')
            )

            location.targetLandmark.loadContent();
            location.targetLandmarkEntry = location.targetLandmark.getRandomEmptyPosition();
          }
          @:instance = import(module:'game_singleton.instance.mt');
          
          
          @:trader = world.scenario.data.trader;          
          if (trader.state.defeatedWyvern) ::<= {
            @:key = Item.new(base:Item.database.find(id:'base:wyvern-key'));
            @:namegen = import(module:'game_singleton.namegen.mt');
            @:name = namegen.island();
            key.setIslandGenTraits(
              levelHint: world.island.levelMax + 1 + (world.island.levelMax * 1.2)->ceil,
              nameHint: name,
              tierHint: world.island.tier + 1,
              extraLandmarks : [
                'base:lost-shrine',
              ]
            ); 
            key.name = 'Key to ' + name  + ' '+romanNum(value:world.island.tier + 1);
            party.inventory.add(item:key);                     
            windowEvent.queueMessage(text: 'Oh? It looks like there\'s something near the entrance...');              
            windowEvent.queueMessage(text: 'The party obtained the ' + key.name + '!');
          }          
          
          

          instance.visitLandmark(landmark:location.targetLandmark, where::(landmark)<-location.targetLandmarkEntry);
          canvas.clear();
        }
      }
    )    
  
  
    Interaction.newEntry(
      data : {
        name : 'Steal',
        id :  'thetrader:steal_wyvern',
        keepInteractionMenu : false,
        onInteract ::(location, party) {
          @:Entity = import(module:'game_class.entity.mt');
        
          // the steal attempt happens first before items 
          //
          when (location.inventory.items->keycount == 0) ::<= {
            windowEvent.queueMessage(text: "There was nothing to steal.");              
          }
          
          @:item = random.pickArrayItem(list:location.inventory.items);
          windowEvent.queueMessage(text:'Stole ' + item.name);

          when(party.inventory.isFull) ::<= {
            windowEvent.queueMessage(text: '...but the party\'s inventory was full.');
          }

          @:world = import(module:'game_singleton.world.mt')

          if (location.ownedBy != empty && !location.ownedBy.isIncapacitated()) ::<= {
            when (random.try(percentSuccess:10)) ::<= {
              windowEvent.queueMessage(
                text: "The stealing goes unnoticed."
              );        
            }
            
            
            
            windowEvent.queueMessage(
              speaker: location.ownedBy.name,
              text: "What..??? You dare to steal from me???"
            );
            windowEvent.queueMessage(
              speaker: location.ownedBy.name,
              text: "That will be your last stealing on this plane, mortal!"
            );

            @:fireSprite ::{
              @:Entity = import(module:'game_class.entity.mt');
              @:sprite = Entity.new(
                island: location.landmark.island,
                speciesHint: 'base:fire-sprite',
                professionHint: 'base:fire-sprite',
                levelHint:5
              );
              sprite.name = 'the Fire Sprite';
              
              for(0, 10)::(i) {
                sprite.learnNextAbility();
              }      
              return sprite;    
            };
            @:e = [
              fireSprite(),
              location.ownedBy,
              fireSprite()  
            ];
            
            


            @:world = import(module:'game_singleton.world.mt');
            world.battle.start(
              party,              
              allies: party.members,
              enemies: e,
              landmark: {},
              onEnd::(result) {
                @:instance = import(module:'game_singleton.instance.mt');
                if (!world.battle.partyWon()) 
                  instance.gameOver(reason:'The party was wiped out.');
                
                Scene.start(id:'thetrader:scene_defeatwyvern', onDone::{}, location, landmark:if (location) location.landmark else empty);
              }
            );
          }
          



          location.inventory.remove(item);
          party.inventory.add(item);          
        },
      }
    )  
  
  
  
    @:Island = import(module:'game_mutator.island.mt');
    @:LandmarkEvent = import(module:'game_mutator.landmarkevent.mt');

    Island.database.newEntry(
      data : {
        id : 'thetrader:starting-island',
        requiredLandmarks : [
          'thetrader:city',
          'base:town',
          'base:wyvern-gate',
          'thetrader:eternal-shrine'
        ],
        possibleLandmarks : [
          
        ],
        minAdditionalLandmarkCount : 0,
        maxAdditionalLandmarkCount : 0,
        minSize : 40,//80,
        maxSize : 60, //130,
        events : [
          'base:bbq',
          'base:weather:1',
          'base:camp-out',
          'base:encounter:normal'      
        ],
        possibleSceneryCharacters : [
          '╿', '.', '`', '^', '░'
        ],
        traits : Island.TRAIT.SPECIAL,
        
        overrideSpecies : empty,
        overrideNativeCreatures : empty,
        overridePossibleEvents : empty,
        overrideClimate : empty,  
      }
    )

  
  
    @:Landmark = import(module:'game_mutator.landmark.mt');


    Landmark.database.newEntry(
      data: {
        name: 'City',
        id: 'thetrader:city',
        legendName : 'City',
        symbol : '|',
        rarity : 5,
        minLocations : 12,
        maxLocations : 17,
        traits :
          Landmark.TRAIT.UNIQUE |
          Landmark.TRAIT.GUARDED |
          Landmark.TRAIT.PEACEFUL | 
          Landmark.TRAIT.CAN_SAVE,
        minEvents : 0,
        maxEvents : 0,
        eventPreference : LandmarkEvent.KIND.PEACEFUL,
        landmarkType : Landmark.TYPE.STRUCTURE,
        requiredEvents : [],
        possibleLocations : [
          {id:'base:home', rarity: 1},
          //{id:'inn', rarity: 3},
          //{id:'guild', rarity: 25}
          //{id:'tavern', rarity: 100}
          //{id:'school', rarity: 7}
        ],
        requiredLocations : [
          'base:shop',
          'thetrader:shop',
          'base:shop',
          'base:arts-tecker',
          'base:tavern',
          'base:arena',
          'base:inn',
          'base:school',
          'base:school',
          'base:blacksmith'  ,
          'base:auction-house'    
        ],
        mapHint : {
          roomSize: 30,
          roomAreaSize: 5,
          roomAreaSizeLarge: 7,
          emptyAreaCount: 18,
          wallCharacter : '|'
        },
        onCreate ::(landmark, island){},
        onIncrementTime ::(landmark, island){},
        onStep ::(landmark, island) {},
        onVisit ::(landmark, island) {}
        
      }
    )

    @:DungeonMap = import(module:'game_singleton.dungeonmap.mt');

    Landmark.database.newEntry(
      data: {
        name: 'Eternal Shrine',
        id: 'thetrader:eternal-shrine',
        symbol : 'M',
        legendName: 'Shrine',
        rarity : 100000,
        traits : 
          Landmark.TRAIT.UNIQUE |
          Landmark.TRAIT.POINT_OF_NO_RETURN |
          Landmark.TRAIT.EPHEMERAL,
        minEvents: 1,
        maxEvents: 4,
        eventPreference : LandmarkEvent.KIND.HOSTILE,
            
        minLocations : 2,
        maxLocations : 4,
        landmarkType : Landmark.TYPE.DUNGEON,
        requiredEvents : [
          'base:dungeon-encounters',
        ],
        possibleLocations : [
    //          {id: 'Stairs Down', rarity:1},
          {id: 'base:fountain', rarity:18},
          {id: 'base:potion-shop', rarity: 17},
          {id: 'base:enchantment-stand', rarity: 18},
          {id: 'base:wyvern-statue', rarity: 15},
          {id: 'base:small-chest', rarity: 16},
          {id: 'base:locked-chest', rarity: 11},
          {id: 'base:magic-chest', rarity: 15},

          {id: 'base:healing-circle', rarity:35},

          {id: 'base:clothing-shop', rarity: 100},
          {id: 'base:fancy-shop', rarity: 50}

        ],
        requiredLocations : [
          'base:stairs-down',
          'base:locked-chest',
          'base:small-chest',
          'base:small-chest',
          'base:warp-point',
          'base:warp-point'
        ],
        mapHint:{
          layoutType: DungeonMap.LAYOUT_DELTA
        },
        onIncrementTime ::(landmark, island){},
        onStep ::(landmark, island) {},
        onCreate ::(landmark, island){
        },
        onVisit ::(landmark, island) {
        }
        
      }
    )



    Landmark.database.newEntry(
      data: {
        name : 'Fortune Wyvern Dimension',
        id : 'thetrader:fortune-wyvern-dimension',
        legendName: '???',
        symbol : 'M',
        rarity : 1,    
        traits : 
          Landmark.TRAIT.UNIQUE |
          Landmark.TRAIT.PEACEFUL,
        minEvents : 0,
        maxEvents : 0,
        eventPreference : LandmarkEvent.KIND.PEACEFUL,

        minLocations : 2,
        maxLocations : 2,
        landmarkType : Landmark.TYPE.DUNGEON,
        requiredEvents : [
        ],
        possibleLocations : [
        ],
        requiredLocations : [
          'thetrader:fortune-throne',
        ],
        
        mapHint : {
          roomSize: 20,
          roomAreaSize: 15,
          roomAreaSizeLarge: 15,
          emptyAreaCount: 1,
          wallCharacter: ' ',
          outOfBoundsCharacter: '$'
        },
        onCreate ::(landmark, island){},
        onVisit ::(landmark, island) {},
        onIncrementTime::(landmark) {},
        onStep::(landmark) {}
        
      }
    )
    
    
    @:Location = import(module:'game_mutator.location.mt');
  
    Location.database.newEntry(data:{
      id: 'thetrader:fortune-throne',
      name: 'Wyvern Throne of Fortune',
      rarity: 1,
      ownVerb : 'owned',
      category : Location.CATEGORY.DUNGEON_SPECIAL,
      symbol: 'W',
      onePerLandmark : true,
      minStructureSize : 1,

      descriptions: [
        "What seems to be a gold throne",
      ],
      interactions : [
        'base:talk',
        'base:examine',
      ],
      
      aggressiveInteractions : [
        'thetrader:steal_wyvern'
      ],


      
      minOccupants : 0,
      maxOccupants : 0,
      
      onFirstInteract ::(location) {
      },
      onInteract ::(location) {
        return true;

      },      
      
      onCreate ::(location) {
        location.name = 'Wyvern Throne';
        @:Profession = import(module:'game_database.profession.mt');
        @:Species = import(module:'game_database.species.mt');
        @:Story = import(module:'game_singleton.story.mt');
        @:Scene = import(module:'game_database.scene.mt');
        @:StatSet = import(module:'game_class.statset.mt');

        @:world = import(module:'game_singleton.world.mt');         
        @:key = Item.new(base:Item.database.find(id:'base:wyvern-key'));
        @:namegen = import(module:'game_singleton.namegen.mt');
        @:name = namegen.island();
        key.setIslandGenTraits(
          levelHint: world.island.levelMax + 1 + (world.island.levelMax * 1.2)->ceil,
          nameHint: name,
          tierHint: world.island.tier + 1,
          extraLandmarks : [
            'base:lost-shrine',
          ]
        ); 
        key.name = 'Key to ' + name  + ' '+romanNum(value:world.island.tier + 1);

        location.inventory.add(
          item:key
        );
        
        location.ownedBy = location.landmark.island.newInhabitant(
          speciesHint : 'base:wyvern',
          professionHint : 'base:wyvern'
        );
        location.ownedBy.name = 'Wyvern of Fortune';
        for(0, 20) ::(i) {
          location.ownedBy.autoLevelProfession(:location.ownedBy.profession);
        }
        location.ownedBy.equipAllProfessionArts();          

        
        location.ownedBy.overrideInteract = ::(party, location, onDone) {
          @:world = import(module:'game_singleton.world.mt');
          @:trader = world.scenario.data.trader;

          Scene.start(id:'thetrader:scene_gold1-' + trader.goldTier, onDone::{}, location, landmark:location.landmark);
          trader.goldTier += 1;
        }
        location.ownedBy.stats.load(serialized:StatSet.new(
          HP:   400,
          AP:   999,
          ATK:  15,
          INT:  5,
          DEF:  11,
          LUK:  8,
          SPD:  25,
          DEX:  11
        ).save());
        location.ownedBy.heal(amount:9999, silent:true); 
        location.ownedBy.healAP(amount:9999, silent:true); 
      },
      
      onIncrementTime::(location, time) {
      
      },
      
      onStep ::(location, entities) {
      
      }
    })
  

    Location.database.newEntry(data:{
      name: 'Your Shop',
      id: 'thetrader:shop',
      rarity: 100,
      ownVerb : 'run',
      category : Location.CATEGORY.BUSINESS,
      symbol: '$',
      onePerLandmark : false,
      minStructureSize : 1,

      descriptions: [
        "Your trading shop. It has served you well over the years.",
      ],
      interactions : [
        'base:examine'
      ],
      
      aggressiveInteractions : [
      ],


      
      minOccupants : 0,
      maxOccupants : 0,
      onFirstInteract ::(location) {

      },
      onInteract ::(location) {

      },      
      
      onCreate ::(location) {

      },
      
      onIncrementTime::(location) {

      },
      onStep ::(location, entities) {
      
      },

    })
  
  
  

    Item.database.newEntry(data : {
      name : "Wyvern Key",
      id : 'thetrader:wyvern-key',
      sortType : Item.SORT_TYPE.KEYS,
      description: 'A key to your home where your shop is. The key is huge, dense, and requires 2 hands to wield. In fact, it is so large and sturdy that it could even be wielded as a weapon in dire circumstances.',
      examine : '',
      equipType: Item.TYPE.TWOHANDED,
      rarity : 100,
      weight : 10,
      canBeColored : true,
      basePrice: 1000,
      tier: 0,
      levelMinimum : 1000000000,
      enchantLimit : 0,
      useTargetHint : Item.USE_TARGET_HINT.ONE,
      possibleArts : [
      ],

      // fatigued
      blockPoints : 2,
      equipMod : StatSet.new(
        ATK: 15,
        SPD: -5,
        DEX: -5
      ),
      useEffects : [
      ],
      equipEffects : [],
      traits : 
        Item.TRAIT.SHARP  |
        Item.TRAIT.KEY_ITEM|
        Item.TRAIT.UNIQUE

      ,
      onCreate ::(item, user, creationHint) {
      }
    });
  
  
    Item.database.newEntry(data : {
      name : "Crate",
      id : 'thetrader:crate',
      sortType : Item.SORT_TYPE.MISC,
      description: 'A sizeable container full of raw material. Can be quite expensive.',
      examine : '',
      equipType: Item.TYPE.HAND,
      rarity : 300,
      weight : 50,
      basePrice: 250,
      levelMinimum : 1,
      tier: 2,
      blockPoints: 0,
      enchantLimit : 10,
      useTargetHint : Item.USE_TARGET_HINT.ONE,

      // fatigued
      equipMod : StatSet.new(
        SPD: -100,
        DEX: -100
      ),
      useEffects : [
      ],
      possibleArts : [
      ],

      equipEffects : [],
      traits : 
        Item.TRAIT.SHARP |
        Item.TRAIT.METAL
      ,
      onCreate ::(item, creationHint) {}

    })    


    Item.database.newEntry(data : {
      name : "Shipment",
      id : 'thetrader:shipment',
      sortType : Item.SORT_TYPE.MISC,
      description: 'A large container full of raw material. One person can barely lift it alone. Can be quite expensive.',
      examine : '',
      equipType: Item.TYPE.HAND,
      rarity : 300,
      weight : 250,
      basePrice: 150,
      levelMinimum : 1,
      tier: 2,
      blockPoints: 0,
      enchantLimit : 10,
      useTargetHint : Item.USE_TARGET_HINT.ONE,

      // fatigued
      equipMod : StatSet.new(
        SPD: -100,
        DEX: -100
      ),
      useEffects : [
      ],
      possibleArts : [
      ],

      equipEffects : [],
      traits : 
        Item.TRAIT.SHARP |
        Item.TRAIT.METAL 
      ,
      onCreate ::(item, creationHint) {}

    })   

    @:Scene = import(module:'game_database.scene.mt');

    Scene.newEntry(
      data : {
        id : 'thetrader:scene_intro',
        script: [
          ['???', '...Greetings, mortal.'],
          ['???', 'Congratulations! For I, Shiikaakael, the Wyvern of Fortune, have chosen YOU for a once-in-a-lifetime opportunity.'],
          ['Shiikaakael, Wyvern of Fortune', 'You see, my hoard of treasure is looking a bit... small. I require riches.'],
          ['Shiikaakael, Wyvern of Fortune', 'If you bring me gold, I will grant you a wish. Anything you like. Doesn\'t that sound wonderful?'],
          ['Shiikaakael, Wyvern of Fortune', 'Bring me.... Hummm... Let us say, 10,000G and a wish shall be yours.'],
          ['Shiikaakael, Wyvern of Fortune', 'Your meager, drab existence as a simple trader is no more! Now you have something to drive you!'],
          ['Shiikaakael, Wyvern of Fortune', 'Go forth, mortal! Get riches! Exploit! Your wish awaits!'],
        ]
      }
    )   

    Scene.newEntry(
      data : {
        id : 'thetrader:scene_bankrupt',
        script: [
          ['???', '...'],
          ['Shiikaakael, Wyvern of Fortune', '...Mortal... I have sensed something...'],
          ['Shiikaakael, Wyvern of Fortune', '...most disappointing. The absence of riches.'],
          ['Shiikaakael, Wyvern of Fortune', 'What\'s worse is those were MY riches that you lost...'],
          ['Shiikaakael, Wyvern of Fortune', '...Bah. Dreadful. Disgusting, even.'],
          ['Shiikaakael, Wyvern of Fortune', 'This is why I don\'t do anything with lesser creatures... Be gone, you.'],
        ]
      }
    )


    Scene.newEntry(
      data : {
        id : 'thetrader:scene_gold0',
        script: [
          ['???', '...'],
          ['Shiikaakael, Wyvern of Fortune', '...Mortal... I have sensed that you have my riches ready!'],
          ['Shiikaakael, Wyvern of Fortune', 'I can hardly wait. I will bring you to me at once!'],
          ['', 'Magic lifts you off your feet and transports you to a new land...'],
          ::(location, landmark, doNext) {
            @:world = import(module:'game_singleton.world.mt');
            @:instance = import(module:'game_singleton.instance.mt');
            @:Landmark = import(module:'game_mutator.landmark.mt');

            @:d = Landmark.new(
              base:Landmark.database.find(id:'thetrader:fortune-wyvern-dimension')
            );
            instance.visitLandmark(landmark:d);       
            doNext();
          }
        ]
      }
    )


    Scene.newEntry(
      data : {
        id : 'thetrader:scene_gold1-0',
        script: [
          ['Shiikaakael, Wyvern of Fortune', 'Mortal, show me the fruits of your labor...!'],
          ['Shiikaakael, Wyvern of Fortune', '...'],
          ['Shiikaakael, Wyvern of Fortune', '.......'],
          ['Shiikaakael, Wyvern of Fortune', '..........'],
          ['Shiikaakael, Wyvern of Fortune', 'I\'ll be honest. 10,000G looks a tad... smaller... in person than I was hoping.'],
          ['Shiikaakael, Wyvern of Fortune', 'Surely, you are capable of much more! Let me think...'],
          ['Shiikaakael, Wyvern of Fortune', '...Perhaps If you came back with 80,000G! Yes! That would be wonderful.'],
          ['Shiikaakael, Wyvern of Fortune', 'Obedient mortal, I have decided. Keep your 10,000G. Instead, I will come for you when you have 80,000G. This feels much more befitting of the cost of a wish, does it not?'],
          ['Shiikaakael, Wyvern of Fortune', '...'],
          ['Shiikaakael, Wyvern of Fortune', 'Well. Go get my riches! Shoo!'],
          ['', 'The Wyvern\'s magic lifts you off your feet and transports you home...'],
          ::(location, landmark, doNext) {
            @:world = import(module:'game_singleton.world.mt');
            @:instance = import(module:'game_singleton.instance.mt');


            instance.visitCurrentIsland(atGate:true);        
          }
        ]
      }
    )

    Scene.newEntry(
      data : {
        id : 'thetrader:scene_gold1-1',
        script: [
          ['Shiikaakael, Wyvern of Fortune', 'Mortal, you have done it! 80,000G in all its glory!'],
          ['Shiikaakael, Wyvern of Fortune', '...'],
          ['Shiikaakael, Wyvern of Fortune', '.......'],
          ['Shiikaakael, Wyvern of Fortune', '..........'],
          ['Shiikaakael, Wyvern of Fortune', 'Hmm. I was thinking it would fill me with joy seeing all these riches. But something about it still feels...'],
          ['Shiikaakael, Wyvern of Fortune', '...too small.'],
          ['Shiikaakael, Wyvern of Fortune', 'Surely, you are capable of much more! Let me think...'],
          ['Shiikaakael, Wyvern of Fortune', '...Perhaps If you came back with 250,000G! Yes! That would be perfect.'],
          ['Shiikaakael, Wyvern of Fortune', 'Obedient mortal, I have decided. Keep your 80,000G. Instead, I will come for you when you have 250,000G. This feels much more befitting of the cost of a wish, does it not?'],
          ['Shiikaakael, Wyvern of Fortune', '...'],
          ['Shiikaakael, Wyvern of Fortune', 'Well. Go get my riches! Shoo!'],
          ['', 'The Wyvern\'s magic lifts you off your feet and transports you home...'],
          ::(location, landmark, doNext) {
            @:world = import(module:'game_singleton.world.mt');
            @:instance = import(module:'game_singleton.instance.mt');


            instance.visitCurrentIsland(atGate:true);        
          }
        ]
      }
    )


    Scene.newEntry(
      data : {
        id : 'thetrader:scene_gold1-2',
        script: [
          ['Shiikaakael, Wyvern of Fortune', 'Mortal... Let me see it. What you have done. What you have brought me!'],
          ['Shiikaakael, Wyvern of Fortune', '...'],
          ['Shiikaakael, Wyvern of Fortune', '.......'],
          ['Shiikaakael, Wyvern of Fortune', '..........'],
          ['Shiikaakael, Wyvern of Fortune', '...It\'s glorious! It\'s perfect!'],
          ['Shiikaakael, Wyvern of Fortune', 'Never have I seen so much mortal gold! This will be a wonderful addition to my hoard.'],
          ['Shiikaakael, Wyvern of Fortune', '...Yes, oh yes!'],
          ['Shiikaakael, Wyvern of Fortune', 'I\'m unable to fathom how are able to even carry that with you! 250,000G is enough to swim in, even for a creature such as me!'],
          ['Shiikaakael, Wyvern of Fortune', '...Well. You have earned it. Here is your wish.'],
          ::(location, landmark, doNext) {
            @:instance = import(module:'game_singleton.instance.mt');
            @:enter = import(module:'game_function.name.mt');
            enter(
              prompt: 'What is your wish?',
              onDone ::(name) {
                @:world = import(module:'game_singleton.world.mt')
                world.setWish(wish:name);
                instance.savestate();
                (import(module:'game_function.newrecord.mt'))(wish:name);
              }
            );
          }
        ]
      }
    )
  
    Scene.newEntry(
      data : {
        id : 'thetrader:scene_defeatwyvern',
        script: [
          ['Shiikaakael, Wyvern of Fortune', 'Augh..!!'],
          ['Shiikaakael, Wyvern of Fortune', 'I... what ... why are you so strong...? What ARE you??'],
          ['Shiikaakael, Wyvern of Fortune', 'Something is.. very wrong here.. I\'ve made a mistake...'],
          ['Shiikaakael, Wyvern of Fortune', 'Mortal... you... I want nothing further to do with you.!'],
          ['Shiikaakael, Wyvern of Fortune', 'Get away from me...!'],
          ['', 'In a violent flash of light, the Wyvern\'s magic lifts you off your feet and transports you home...'],
          ::(location, landmark, doNext) {
            @:world = import(module:'game_singleton.world.mt');
            @:instance = import(module:'game_singleton.instance.mt');


            instance.visitCurrentIsland(atGate:true);        
            @:world = import(module:'game_singleton.world.mt');
            @:party = world.party;
            @:trader = world.scenario.data.trader;

            trader.state.defeatedWyvern = true;
            
          }
        ]
      }
    )    
  
  },
  onSaveLoad ::(data) {
    data.trader.dayStart();
  }
}
