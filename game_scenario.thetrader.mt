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
@:databaseItemMutatorClass = import(module:'game_function.databaseitemmutatorclass.mt');
@:commonInteractions = import(module:'game_singleton.commoninteractions.mt');
@:InteractionMenuEntry = import(module:'game_struct.interactionmenuentry.mt');
@:Personality = import(module:'game_database.personality.mt');
@:g = import(module:'game_function.g.mt');
@:Scene = import(module:'game_database.scene.mt');


@:WORK_ORDER__SPACE = 1;
@:WORK_ORDER__FRONT = 2;

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
                when(popular->findIndex(value:value.base.name) != -1) 'High'
                when(unpopular->findIndex(value:value.base.name) != -1) 'Low'
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
        
        // The last thing that attacked this hiree while exploring
        lastAttackedBy : empty,
        
        // number of days employed.
        daysEmployed : 0,
        
        // worth of items found
        earned : 0,
        
        // amount sold as a shopkeeper
        sold : 0,
        
        // How much money has been paid out
        spent : 0
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
                        'Dispatch    :' + g(g:state.earned) + '\n' +
                        'Shopkeeping :' + g(g:state.sold) + '\n'
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
                
                {:::} {
                    for(0, random.integer(from:6, to:12)) ::(i) {
                        (random.pickArrayItemWeighted(
                            list : [
                                // small chest
                                {
                                    rarity: 2,
                                    action::{
                                        spoils->push(value:
                                            Item.new(
                                                base:Item.database.getRandomFiltered(
                                                    filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                                                                            && value.tier <= world.island.tier
                                                ),
                                                rngEnchantHint:true
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
                                                        filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                                                                                && value.tier <= world.island.tier + 1
                                                    ),
                                                    rngEnchantHint:true, 
                                                    forceEnchant:true
                                                )
                                            );           
                                        }                             
                                    }                                
                                },
                                
                                // normal hostile encounter
                                {
                                    rarity: 3,
                                    action::{
                                        @:instance = import(module:'game_singleton.instance.mt');                                    
                                        @other;
                                        if (random.flipCoin()) ::<= {
                                            other = instance.island.newInhabitant()
                                            other.anonymize();
                                        } else if (Number.random() > 0.02) ::<= {
                                            other = instance.island.newHostileCreature()
                                            other.nickname = 'a ' + other.name;
                                            breakpoint();
                                        } else ::<= {
                                            @:TheBeast = import(module:'game_class.landmarkevent_thebeast.mt');
                                            other = TheBeast.createBeast();
                                        } 
                                            
                                        state.lastAttackedBy = other.name;
                                        windowEvent.autoSkip = true;
                                            {:::} {
                                                forever ::{
                                                    when(state.member.isIncapacitated()) send();
                                                    when(other.isIncapacitated()) send();
                                                    
                                                    // give the benefit of the doubt, let our person attack first
                                                    state.member.attack(
                                                        target: other,
                                                        amount:state.member.stats.ATK * (0.5),
                                                        damageType : Damage.TYPE.PHYS,
                                                        damageClass: Damage.CLASS.HP
                                                    );                                                   

                                                    if (!other.isIncapacitated())
                                                        other.attack(
                                                            target: state.member,
                                                            amount:other.stats.ATK * (0.5),
                                                            damageType : Damage.TYPE.PHYS,
                                                            damageClass: Damage.CLASS.HP
                                                        );                                                   
                                                }
                                            }
                                        windowEvent.autoSkip = false;
                                        if (!state.member.isIncapacitated()) ::<={
                                            spoils->push(value:
                                                Item.new(
                                                    base:Item.database.getRandomFiltered(
                                                        filter:::(value) <- value.isUnique == false
                                                                                && value.tier <= world.island.tier
                                                    ),
                                                    rngEnchantHint:true
                                                )
                                            );                                            
                                        } else
                                            defeat();
                                    }
                                }
                               
                            ]
                        )).action();
                        
                        
                        if (state.member.hp < state.member.stats.HP / 2) send();

                    }  
                    completed = true;                  
                    spoils->push(value:
                        Item.new(
                            base:Item.database.getRandomFiltered(
                                filter:::(value) <- value.isUnique == false
                                                    && value.hasQuality
                            ),
                            qualityHint : 'Masterwork',
                            rngEnchantHint:true
                        )
                    );   


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
                    when(slot == Entity.EQUIP_SLOTS.HAND_LR && (item.base.attributes & Item.ATTRIBUTE.WEAPON == 0))
                        spoilsFiltered->push(value:item);
                    
                    // simply take
                    when (current.base.name == 'None')
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
        modData : empty,
        
        // world ID for the city where the shop resides 
        cityID : empty,
        
        // inventory of the shop.
        shopInventory : empty,
        
        // world ID for the shop that is owned by the player.
        shopID : empty,
        
        // Current popular items (base names)
        popular : empty,
        
        // No one will buy these (base names)
        unpopular : empty,
        
        // Location IDs that are owned by the player
        ownedProperties : empty,
        
        // Location IDs of properties that are owned but up for sale.
        propertiesForSale : empty,
        
        // Whether a work order was put in for upgrading the shop.
        workOrder : empty,
        
        // The times the gold goal has been met
        goldTier : 0,
        
        // history of transactions
        ledger : empty,
        
        // How many NPC-fronted storefronts there are.
        additionalStorefrontCount : 0,
        
        // whether a recessions is present and for how many days.
        // if positive, currently experiencing a recession 
        // if negative, a recession is impossible for that many days 
        // if 0, no recession.
        recession: 0
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
                
                windowEvent.queueNoDisplay(
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
                        @:currentLandmark = instance.landmark;
                        if (currentLandmark != empty && currentLandmark.base.pointOfNoReturn == true) ::<= {
                            windowEvent.queueMessage(
                                text: '"Oh huh. The courier is here... somehow."'
                            );
                        } else 
                            windowEvent.queueMessage(
                                text: '"Ah. The courier is here."'
                            );

                        @hasNews = false;
                        
                        if (state.workOrder != empty) ::<= {
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

                            state.workOrder = empty;
                        }
                        

                        foreach([...state.hirees]) ::(i, hiree) {
                            when (hiree.role != ROLES.DISPATCHED) empty;

                            when (hiree.entity.isDead) ::<= {
                                hasNews = true;
                                windowEvent.queueMessage(
                                    speaker: 'Courier',
                                    text: '"I have unfortunate news... Your hiree ' + hiree.entity.name + ' has not returned from their exploration. Word is that ' + hiree.lastAttackedBy+ ' got them while adventuring. I don\'t think they\'ll be coming back..."'
                                );
                                
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
                            
                            @:which = [...Item.database.getAll()]->filter(by::(value) <- value.isUnique == false);
                            state.popular = [
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which)
                            ]->map(to:::(value) <- value.name);

                            state.unpopular = [
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which),
                                random.removeArrayItem(list:which)
                            ]->map(to:::(value) <- value.name);

                            
                            @popnews = 'These items are now popular. People will pay high prices for them compared to normal.\n\n';
                            foreach(state.popular) ::(i, val) {
                                popnews = popnews + ' - ' + val + '\n';
                            }
                            
                            windowEvent.queueMessage(text:popnews, pageAfter:14);

                            @unpopnews = 'These items are now unpopular. People will avoid these or won\'t be willing to buy them for normal prices.\n\n';
                            foreach(state.unpopular) ::(i, val) {
                                unpopnews = unpopnews + ' - ' + val + '\n';
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
                            }
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
                        
                        windowEvent.queueNoDisplay(
                            onEnter ::{
                                onDoneReal();
                            }
                        );
                    }
                )
            },
            
            isPropertyOwned ::(location) {
                when(state.ownedProperties->findIndex(query::(value) <- value == location.worldID) != -1) true;
                when(state.propertiesForSale->findIndex(query::(value) <- value == location.worldID) != -1) true;
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

                
                windowEvent.queueChoices(
                    prompt: 'Finances...',
                    choices: [
                        'View ledger',
                        'Hiree report'
                    ],
                    keep:true,
                    canCancel: true,
                    onChoice::(choice) {
                        match(choice-1) {
                          (0): finances_ledger(),
                          (1): finances_employee()
                        }
                    }
                );
            },
            
            
            manage ::{
                windowEvent.queueChoices(
                    prompt : 'Manage...',
                    choices : [
                        'Hirees',
                        'Properties',
                        'Finances'
                    ],
                    
                    onChoice::(choice) {
                        match(choice) {
                          (1): this.manageHirees(),
                          (2): this.manageProperties(),
                          (3): this.finances()                        
                        }
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
                  
                when (party.inventory.gold > tiers[state.goldTier]) ::<= {
                    Scene.start(name:'trader.scene_gold0', onDone ::{
                    });
                }


                @:currentLandmark = instance.landmark;
                when (currentLandmark != empty && currentLandmark.base.pointOfNoReturn == true) ::<= {
                    windowEvent.queueMessage(
                        speaker: party.members[0].name,
                        text: '"What a terrible day to be stuck here. Guess I won\'t open shop today."'
                    );
                }
                
                @:doStart :: {
                    windowEvent.queueChoices(
                        prompt:'Today I will...',
                        choices : [
                            'Open shop',
                            'Explore'
                        ],
                        renderable : {
                            render ::{
                                canvas.blackout();
                            }
                        },
                        keep:true,
                        jumpTag: 'day-start',
                        onChoice::(choice) {
                            when(choice == 2) ::<={
                                this.explore();
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
                    name:name,
                    standardPrice: location.modData.trader.listPrice,
                    shopper: buyer,
                    onDone ::(bought, price) {
                        when(!bought) windowEvent.queueMessage(
                            text: 'They left without buying ' + name + '...'
                        );

                        
                        windowEvent.queueMessage(
                            text:  name + ' was bought for ' + g(g:price) + '.'
                        );                        
                        
                        state.propertiesForSale->remove(key:state.propertiesForSale->findIndex(value:id));
                        location.modData.trader.listPrice = price;
                        world.party.inventory.addGold(amount:price);
                        onDone();
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
                    windowEvent.queueMessage(
                        text: "Your hiree " + hiree.entity.name + " comes up to you, hopeful."
                    );
                    
                    @:raiseAmount = (hiree.contractRate * 0.6)->floor
                    
                    windowEvent.queueMessage(
                        speaker: hiree.entity.name,
                        text: random.pickArrayItem(
                            list : [
                                '"I\'ve worked very hard as your employee. I believe I am in my right to ask for a raise. ',
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
                                
                                hiree.contractRate += raiseAmount;
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
            
            simulateShopkeep::(itemsSold) {
                when(state.shopInventory.items->size == 0) -1;
                @maxPerHour = (
                    (state.shopInventory.items->size / 4.5)
                )->ceil;
                
                if (maxPerHour < 3)
                    maxPerHour = 3;
                    
                if (maxPerHour > 8)
                    maxPerHour = 8;

                @gained = 0;
                @world = import(module:'game_singleton.world.mt');

                @:popular   = state.popular;
                @:unpopular   = state.unpopular;



                {:::} {
                    for(world.TIME.LATE_MORNING, world.TIME.EVENING) ::(i) {
                        @shoppers = random.integer(from:0, to:maxPerHour);                            

                        if (state.recession > 0)
                            shoppers = if (random.try(percentSuccess:20)) 1 else 0;


                        for(0, shoppers) ::(n) {
                            when(state.shopInventory.items->size == 0) send();
                            @:sold = random.removeArrayItem(list:state.shopInventory.items);

                            @price = 
                                if (popular->findIndex(value:sold.base.name) != -1) 
                                    ((sold.price / 10)->floor)*2
                                else if (unpopular->findIndex(value:sold.base.name) != -1)
                                    ((sold.price / 20)->floor)
                                else 
                                    (sold.price / 10)->floor
                            if (price < 1)
                                price = 1;
                                    
                            gained += price;
                            itemsSold->push(value:sold);
                            state.shopInventory.remove(item:sold);
                        }                                    
                    }
                }
                return gained;
            },
        
            dayEnd::(onDone) {
                @:onDoneReal ::{
                    @:instance = import(module:'game_singleton.instance.mt');
                    instance.savestate();
                    onDone();
                    windowEvent.jumpToTag(name:'dayEnd', goBeforeTag:true, doResolveNext:true);
                }
                
                windowEvent.queueNoDisplay(
                    renderable : {
                        render :: {
                            canvas.blackout();
                        }
                    },
                    keep:true,
                    jumpTag : 'dayEnd',
                    onEnter ::{
                        
                        @world = import(module:'game_singleton.world.mt');

                        windowEvent.queueMessage(
                            text: 'The day is over.'
                        );



                        // called once all the event based stuff is done.
                        @:wrapUp = ::{
                            if (state.hirees->size > 0 && [...state.hirees]->filter(by:::(value) <- value.role == ROLES.DISPATCHED)->size > 0) ::<= {
                                windowEvent.queueMessage(
                                    text: 'Your dispatched hirees should be coming to you with news...'
                                );
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
                                                hiree.earned += (item.price / 10)->floor;
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

                            if (state.hirees->size > 0 && [...state.hirees]->filter(by:::(value) <- value.role == ROLES.SHOPKEEP)->size > 0) ::<= {
                                windowEvent.queueMessage(
                                    text: 'Your shopkeeps are here with news.'
                                );
                            }
                            foreach([...state.hirees]) ::(i, hiree) {
                                when (hiree.role != ROLES.SHOPKEEP) empty;
                                @:itemsSold = [];
                                @:gained = this.simulateShopkeep(itemsSold);
                                
                                // < 0 means stock was empty.
                                when (gained == -1) 
                                    windowEvent.queueMessage(
                                        speaker:hiree.entity.name,
                                        text: '"Unforunately, no sales were made today due to the store stock being depleted."'
                                    );

                                when (gained == 0) 
                                    windowEvent.queueMessage(
                                        speaker:hiree.entity.name,
                                        text: '"Unforunately, no sales were made today."'
                                    );

                                windowEvent.queueMessage(
                                    speaker:hiree.entity.name,
                                    text: random.pickArrayItem(
                                        list : [
                                            '"Selling today went great."',
                                            '"Another great day at the store front."',
                                            '"Many customers today!"',
                                            '"It was great to see so many things off the shelves."'
                                        ]
                                    )
                                );
                                
                                
                                @sold = "Items sold by " + hiree.entity.name + ':\n\n';
                                foreach(itemsSold) ::(i, item) {
                                    sold = sold + "- " + item.name + '\n'
                                }
                                sold = sold + '\n\n' + 'Total earned: ' + g(g:gained);
                                windowEvent.queueMessage(
                                    text:sold,
                                    pageAfter:14
                                );                        
                                hiree.sold += gained;
                                world.party.inventory.addGold(amount:gained);
                            }


                            @:endWrapUp :: {
                                @status = "Todays profit:\n";
                                
                                @earnings = world.party.inventory.gold - state.startingG;
                                status = status + "  Earnings     : "+ (if (earnings < 0) g(g:earnings) else "+" + g(g:earnings)) + "\n\n";


                                @:Location = import(module:'game_mutator.location.mt');

                                @rent = 0;
                                foreach(state.ownedProperties) ::(i, id) {
                                    @:location = world.island.findLocation(id);
                                    
                                    if (location.base.category == Location.CATEGORY.RESIDENTIAL) ::<= {
                                        rent += (location.modData.trader.boughtPrice * 0.07)->ceil;
                                        @current = location.modData.trader.listPrice;
                                        current += (((Number.random() - 0.5) * 0.05) * location.modData.trader.boughtPrice)->floor;

                                        if (state.recession > 0)
                                            current *= 0.92;
                                        current = current->floor;


                                        if (current < 2000)
                                            current = 2000;
                                        location.modData.trader.listPrice = current;
                                    }
                                }
                                world.party.inventory.addGold(amount:rent);
                                @investments = rent;
                                if (rent > 0)
                                    status = status + "  Rent         : +" + g(g:rent) + "\n";
                                

                                rent = 0;
                                foreach(state.ownedProperties) ::(i, id) {
                                    @:location = world.island.findLocation(id);
                                    when (location.base.category == Location.CATEGORY.RESIDENTIAL) empty
                                    
                                    @profit = location.modData.trader.listPrice * 0.15;
                                    profit = random.integer(from:(profit * 0.5)->floor, to:(profit * 1.5)->floor);
                                    
                                    if (state.recession > 0 && random.try(percentSuccess:65))
                                        rent -= profit
                                    else
                                        rent += profit;


                                    @current = location.modData.trader.listPrice;
                                    current += (((Number.random() - 0.5) * 0.15) * location.modData.trader.listPrice)->floor;

                                    if (state.recession > 0)
                                        current *= 0.92;
                                    current = current->floor;

                                    if (current < 9000)
                                        current = 9000;
                                    location.modData.trader.listPrice = current;
                                }

                                world.party.inventory.addGold(amount:rent);
                                investments += rent;
                                if (rent > 0)
                                    status = status + "  Businesses   : " + (if (rent >= 0) '+' + g(g:rent) else g(g:rent)) + "\n";


                                status 

                                @cost = 0;
                                foreach(state.hirees) ::(i, hiree) {
                                    when (hiree.entity.isDead) empty;
                                    cost += hiree.contractRate;
                                    hiree.spent += hiree.contractRate;
                                    hiree.daysEmployed += 1;
                                }
                                status = status + "  Contracts    : -" + g(g:cost) + "\n";
                                
                                cost += state.upkeep;
                                status = status + "  Upkeep       : -" + g(g:state.upkeep) + "\n";
                                
                                @currentG = world.party.inventory.gold
                                @:profit = (earnings + investments) - cost;
                                state.days += 1;
                                if (profit > state.bestProfit)            
                                    state.bestProfit = profit;
                                if (state.days % 2 == 0 && profit > 0) 
                                    state.upkeep += (profit * 0.01)->floor;
                                
                                status = status + "_________________________________\n";
                                status = status + "  Profit       : " + (if (profit < 0) g(g:profit) else "+" + g(g:profit)) + "\n\n";
                                

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
                                    Scene.start(name:'trader.scene_bankrupt', onDone::{                    
                                        windowEvent.jumpToTag(name:'MainMenu', clearResolve:true);
                                    });        
                                        


                                // return to pool
                                foreach(state.hirees) ::(i, hiree) {
                                    if (world.party.isMember(entity:hiree.entity))
                                        hiree.returnFromParty();
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
                                
                                windowEvent.queueNoDisplay(
                                    onEnter ::{
                                        onDoneReal();
                                    }
                                );
                            }
                            
                            this.allocateRaises(onDone:endWrapUp);
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
                )

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
                state.hirees->push(value:
                    TraderState_Hiree.new(
                        member:entity,
                        rate
                    )
                );
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

                @hiree = state.hirees[state.hirees->findIndex(query::(value) <- value == entity)];
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
                    text: location.ownedBy.name + '\'s ' + location.base.name + ' is currently worth ' + g(g:location.modData.trader.listPrice) + '. Once put up for sale, it will no longer generate revenue.'
                );

                windowEvent.queueAskBoolean(
                    prompt: 'Sell for ' + g(g:location.modData.trader.listPrice) + '?',
                    onChoice::(which) {
                        when(which == false) empty;
                        
                        
                        @:index = state.ownedProperties->findIndex(value:location.worldID);
                        if (index == -1) error(detail: 'No such property');
                        state.ownedProperties->remove(key:index);
                        
                        state.propertiesForSale->push(value:location.worldID);
                    
                        windowEvent.queueMessage(
                            text: location.ownedBy.name + '\'s ' + location.base.name + ' is now up for sale for ' + g(g:location.modData.trader.listPrice) + '.'
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
                            @:delta = location.modData.trader.listPrice - location.modData.trader.boughtPrice;

                            names->push(value: location.ownedBy.name + '\'s ' + location.base.name);
                            worth->push(value:g(g:location.modData.trader.listPrice) + ' (' + (if(delta > 0) '+' else '') + g(g:delta) + ')');
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
                        @:wages  = [];
                        @:status = [];
                        foreach(state.hirees) ::(i, hiree) {
                            names->push(value:hiree.entity.name);
                            wages->push(value:g(g:hiree.contractRate));
                            status->push(value:roleToString(role:hiree.role));
                        }
                        return [
                            names, wages, status
                        ];
                    },
                    prompt: 'Hirees...',
                    header : ['Name', 'Wage', 'Status'],
                    leftJustified : [true, true, true],
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
                                'Financial report',
                                'Change role',
                                'Fire'
                            ],
                            canCancel : true,
                            onChoice::(choice) {
                                when(choice == 0) empty;
                                
                                match(choice) {
                                  (1): hiree.entity.describe(),
                                  (2): hiree.report(),
                                  (3): this.changeRole(hiree),
                                  (4): this.fire(hiree)
                                }
                            }
                        );
                    }
                );
            },
            
            preflightCheckStart::(onDone, isShopkeeping) {
                @world = import(module:'game_singleton.world.mt');
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
                                    @:instance = import(module:'game_singleton.instance.mt');

                                    foreach(state.hirees) ::(k, hiree) {
                                        if (hiree.role == ROLES.IN_PARTY)
                                            hiree.addToParty();
                                    }

                                    instance.visitIsland();            
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
                        prompt: ' Current shop stock:',
                        traderState : state,
                        inventory: state.shopInventory,
                        canCancel: true,
                        goldMultiplier: 0.1, // standard rate
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
                            text: 'You have no items to stock the shop with. Perhaps you should hire someone to look for items. Otherwise, you must explore on your own to find things to sell.'
                        );
                    
                    pickItemStock(
                        prompt: ' Current inventory:',
                        traderState : state,
                        inventory: world.party.inventory,
                        canCancel: true,
                        goldMultiplier: 0.1,
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
                                        when (state.shopInventory.isFull) ::<= {
                                            windowEvent.queueMessage(
                                                text: 'The shop stock is full. The shop can be upgraded to hold more items.'
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
            haggle::(shopper, displayName, name, standardPrice, onDone) {
                @offer = standardPrice;
                @tries = 0;
                @lastOffer = 0.5;

                @isPopular = ::<= {                    
                    @:popular   = state.popular;
                    return (popular->findIndex(value:name) != -1)
                }                    

                @isUnpopular = ::<= {                    
                    @:unpopular   = state.unpopular;
                    return (unpopular->findIndex(value:name) != -1)
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
                        base += 0.2*(Number.random() -.5); // still can vary a bit
                        
                        base *= 0.3; // personality only place a slight role
                        base += 0.05; // people are generally reasonable
                        @amount = (base + 1) * standardPrice + 1;
                        
                        // cheapskates or splurgers
                        if (random.try(percentSuccess:33)) 
                            if (random.flipCoin())
                                amount *= 0.7
                            else
                                amount *= 1.3
                        ;
                        
                        
                        // not for free!
                        if (amount < 1) amount = 1;
                        amount = amount->ceil;    
                        return amount;                
                    }
                    
                    @:base = match(shopper.personality.name) {
                      ('Friendly'):       (standardPrice * 1.56)->floor,
                      ('Short-tempered'): (standardPrice * 1.13)->floor,
                      ('Quiet'):          (standardPrice * 1.28)->floor,
                      ('Charismatic'):    (standardPrice * 1)->floor,
                      ('Caring'):         (standardPrice * 1.3)->floor,
                      ('Cold'):           (standardPrice * 1.15)->floor,
                      ('Disconnected'):   (standardPrice * 1.45)->floor,
                      ('Inquisitive'):    (standardPrice * 1.25)->floor,
                      ('Curious'):        (standardPrice * 1.2)->floor,
                      ('Calm'):           (standardPrice * 1.3)->floor,
                      default: defaultCalculation()
                    }

                    when(isPopular)   base * 2;
                    when(isUnpopular) (base * 0.5)->floor;
                    return base;
                }
                
                @:offerFromFraction::(fraction) {
                    @:min = standardPrice * 0;
                    @:max = standardPrice * 2;
                    
                    return (fraction * (max - min) + min)->ceil;
                }
                
                @haggleNext :: {
                    windowEvent.queueSlider(
                        renderable : {
                            render ::{
                                canvas.renderTextFrameGeneral(
                                    lines: [
                                        shopper.name + ' wants to buy: ',
                                        displayName + ' (worth standardly: ' + g(g:standardPrice) + ')',
                                        if (isPopular) 'NOTE: this item is currently in demand.' else if (isUnpopular) 'NOTE: this item is currently experiencing a price-drop.' else '',
                                        'Their personality seems to be: ' + shopper.personality.name
                                    ],
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
                        increments: 40,
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
                                    onDone(bought:false, price:offer);
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
                                onDone(bought:true, price:offer);
                            }
                        }
                    );
                }
                haggleNext();
            },
            
            finishDay ::(landmark, island) {
                @world = import(module:'game_singleton.world.mt');
                if (world.time <= 3)
                    if (landmark)
                        landmark.wait(until:4) // late morning
                    else 
                        world.island.wait(until:4)                        
                

                if (landmark)
                    landmark.wait(until:3) // late morning
                else 
                    world.island.wait(until:3)             
            },

            startShopDay :: {
                @world = import(module:'game_singleton.world.mt');

                // find shop
                @:instance = import(module:'game_singleton.instance.mt');
                //instance.visitIsland();
                @:landmark = world.island.landmarks->filter(by::(value) <- value.worldID == state.cityID)[0];
                @:location = landmark.locations->filter(by::(value) <- value.worldID == state.shopID)[0];
                //instance.visitLandmark(landmark, where:{x:location.x, y:location.y});            
                @:item = landmark.map.getItem(data:location);
                landmark.map.setPointer(
                    x: item.x,
                    y: item.y
                );




                windowEvent.queueNoDisplay(
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
                            windowEvent.jumpToTag(name:'day-start-shop', goBeforeTag:true);
                            this.finishDay();               
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
                            
                            @:item = random.removeArrayItem(list:state.shopInventory.items);
                            
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
                                name : item.base.name,
                                standardPrice: (item.price / 10)->ceil,
                                onDone::(bought, price) {
                                    if (bought) ::<= {
                                        world.party.inventory.addGold(amount:price);
                                        windowEvent.queueMessage(
                                            text: shopper.name + ' bought the ' + item.name + ' for ' + g(g:price) + '.'
                                        );
                                        state.shopInventory.remove(item);
                                    } else ::<= {
                                        windowEvent.queueMessage(
                                            text: shopper.name + ' left without buying anything.'
                                        );                                    
                                    }
                                    nextShopper();                        
                                
                                }
                            )                            
                        }
                        
                        @:finishHour ::{
                            @:hour = world.time;
                            {:::} {
                                forever ::{
                                    when(world.time == hour)
                                        world.stepTime();
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
                    
                    when (state.workOrder != empty)
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
                            
                            world.party.inventory.addGold(amount:costNext);
                            state.workOrder = WORK_ORDER__SPACE;
                        }
                    );
                }
                
                
                @:upgradeShop_fronts = ::{
                    when (state.workOrder != empty)
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
                            
                            world.party.inventory.subtractGold(amount:costNext);
                            state.workOrder = WORK_ORDER__FRONT;
                        }
                    );
                }
                
                
                windowEvent.queueChoices(
                    prompt: 'Upgrades...',
                    choices : [
                        'Stock size',
                        'Additional store fronts'
                    ],
                    canCancel: true,                    
                    onChoice::(choice) {
                        match(choice) {
                          (1): upgradeShop_space(),
                          (2): upgradeShop_fronts()
                        }
                    }
                );
                
            },
            
            openShop :: {
                windowEvent.queueChoices(
                    prompt: 'Shop options:',
                    choices : [
                        'Manage...',
                        'Stock shop', // inv to shop 
                        'Upgrade shop', // stock, starts at 15 
                        'Start the day!'
                    ],
                    keep:true,
                    canCancel: true,
                    onChoice::(choice) {
                        when(choice == 0) empty;
                        match(choice) {
                          (1): this.manage(),
                          (2): this.stockShop(),
                          (3): this.upgradeShop(),
                          (4): this.preflightCheckStart(onDone::{this.startShopDay();}, isShopkeeping:true)
                        }
                    }
                );
            }                      
        }
    }
)







@:interactionsPerson = [
    commonInteractions.person.barter,
    InteractionMenuEntry.new(
        displayName: 'Hire with contract',
        filter ::(entity)<- true,
        onSelect ::(entity) {
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

                    trader.addHiree(
                        entity:this,
                        rate: cost
                    );
                        
                    windowEvent.queueMessage(
                        text: this.name + ' was hired! They\'ll start working for you tomorrow. Be sure to assign them a task.'
                    );     

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
    onBegin ::(data) {
    
    
        @:instance = import(module:'game_singleton.instance.mt');
        @:story = import(module:'game_singleton.story.mt');
        @world = import(module:'game_singleton.world.mt');
        @:LargeMap = import(module:'game_singleton.largemap.mt');
        @party = world.party;            


        {:::} {
            forever ::{
                if (world.time == world.TIME.MORNING) send();
                world.stepTime();
            }
        }
    
        @:keyhome = Item.new(
            base: Item.database.find(name:'Wyvern Key')
        );
        keyhome.name = 'Wyvern Key: Home';
        
            
        keyhome.addIslandEntry(island:world.discoverIsland(
            nameHint:namegen.island(), 
            levelHint:story.levelHint,
            tierHint: 0,
            landmarksHint: [
                'City',
                'City',
                'Town',
                'Mysterious Shrine',
                'Mine',
                'Mine',
                'Forest'
            ]
        ));
        world.island = keyhome.islandEntry;
        @:island = world.island;
        instance.island = island;
        party = world.party;
        party.reset();
        party.inventory.maxItems = 70;



        
        // debug
            //party.inventory.addGold(amount:100000);

        
        // since both the party members are from this island, 
        // they will already know all its locations
        foreach(island.landmarks)::(index, landmark) {
            landmark.discover(); 
        }
        
        
        
        @:Species = import(module:'game_database.species.mt');
        @:p0 = island.newInhabitant(professionHint: 'Trader', levelHint:story.levelHint);
        p0.normalizeStats();

        

        // Add initial inventory.
        for(0, 15)::(i) {
            party.inventory.add(item:
                Item.new(
                    base:Item.database.getRandomFiltered(
                        filter:::(value) <- value.isUnique == false
                                            && value.tier <= world.island.tier
                    ),
                    from:p0, 
                    rngEnchantHint:true
                )
            );
        }

        party.add(member:p0);
        party.inventory.addGold(amount:250);
        
        
        
        // setup shop
        @:city = island.landmarks->filter(by::(value) <- value.base.name == 'City')[0];            
        @:shop = city.locations->filter(by::(value) <- value.base.name == 'Shop')[0];
        shop.ownedBy = empty;

        data.trader = TraderState.new(
            city,
            shop
        );
        party.inventory.add(item:
            Item.new(
                base:Item.database.find(name:'Gold Pouch'),
                from:p0
            )
        );


            
            /*
            party.inventory.addGold(amount:200000);
            
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
                    base:Item.database.find(name:'Shipment'),
                    from:p0
                )
            );

            party.inventory.add(item:
                Item.new(
                    base:Item.database.find(name:'Crate'),
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
        Scene.start(name:'trader.scene_intro', onDone::{                    
            data.trader.dayStart();                
            /*island.addEvent(
                event:Event.database.find(name:'Encounter:Non-peaceful').new(
                    island, party, landmark //, currentTime
                )
            );*/  
        });        
        
        
        
        
    },

    onNewDay ::(data){
        when(data.trader == empty) empty;
        data.trader.newDay();
    },

    
    interactionsPerson : interactionsPerson,
    interactionsLocation : [
        InteractionMenuEntry.new(
            displayName : 'Buy property',
            filter ::(location) {
                @world = import(module:'game_singleton.world.mt');
                @:Location = import(module:'game_mutator.location.mt');
                @:trader = world.scenario.data.trader;
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
                if (location.modData.trader == empty)
                    location.modData.trader = {};
                 
                // generate list price   
                if (location.modData.trader.listPrice == empty) ::<= {
                    @basePrice = match(location.base.category) {
                      // residential properties can be bought, and thee owners become 
                      // tennants
                      (Location.CATEGORY.RESIDENTIAL): random.pickArrayItem(list:[9000, 12000, 8000, 14000, 5000]),
                      (Location.CATEGORY.BUSINESS): random.pickArrayItem(list:[100000, 120000, 89000, 160000]),
                      (Location.CATEGORY.UTILITY): random.pickArrayItem(list:[30000, 35000, 22000, 45000])
                    }
                    
                    location.modData.trader.listPrice = random.integer(from:(basePrice * 0.8)->floor, to:(basePrice * 1.2)->floor);
                }

                windowEvent.queueMessage(
                    text: location.ownedBy.name + '\'s ' + location.base.name + ' is available for purchase for ' + g(g:location.modData.trader.listPrice) + '.'
                );
                
                when(world.party.inventory.gold < location.modData.trader.listPrice)
                    windowEvent.queueMessage(
                        text: 'The party cannot afford to buy this property.'
                    );

                windowEvent.queueAskBoolean(
                    prompt: 'Buy property for ' + g(g:location.modData.trader.listPrice) + '?',
                    onChoice::(which) {
                        when(which == false) empty;
                        
                        world.party.inventory.subtractGold(amount: location.modData.trader.listPrice);
                        location.modData.trader.boughtPrice = location.modData.trader.listPrice;

                        
                        @:trader = world.scenario.data.trader;
                        trader.ownedProperties->push(value: location.worldID);

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
        )
    ],
    onResume ::(data) {
        @:trader = data.trader;
        trader.dayStart();                
    },
    
    onDeath ::(data, entity) {
        @:world = import(module:'game_singleton.world.mt')
        when (entity == world.party.members[0]) ::<= {
            windowEvent.queueMessage(
                text: 'The Trader ' + entity.name + '\'s journey comes to an end...',
                onLeave :: {
                    windowEvent.jumpToTag(name:'MainMenu');                
                }
            );
        }
        
        data.trader.removeHireeEntity(entity);
    },


    interactionsLandmark : [],
    interactionsWalk : [
        commonInteractions.walk.check,
        InteractionMenuEntry.new(
            displayName: 'Finances',
            filter::(island, landmark) <- true,
            onSelect::(island, landmark) {
                @:world = import(module:'game_singleton.world.mt')
                world.scenario.data.trader.finances();
            }
        ),
        commonInteractions.walk.party,
        InteractionMenuEntry.new(
            displayName: 'Finish Day',
            filter::(island, landmark) <- landmark == empty || landmark.base.pointOfNoReturn == false,
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
        commonInteractions.battle.act,
        commonInteractions.battle.check,
        commonInteractions.battle.item,
        commonInteractions.battle.wait,
        commonInteractions.battle.pray
    ],
    interactionsOptions : [
        commonInteractions.options.system,
        commonInteractions.options.quit
    ],
    
    
    databaseOverrides ::{
        Item.database.newEntry(data : {
            name : "Crate",
            description: 'A sizeable container full of raw material. Can be quite expensive.',
            examine : '',
            equipType: Item.TYPE.HAND,
            rarity : 300,
            canBeColored : false,
            keyItem : false,
            weight : 50,
            basePrice: 250,
            levelMinimum : 1,
            tier: 2,
            hasSize : false,
            canHaveEnchants : false,
            canHaveTriggerEnchants : false,
            enchantLimit : 10,
            hasQuality : false,
            hasMaterial : true,
            isApparel : false,
            isUnique : false,
            useTargetHint : Item.USE_TARGET_HINT.ONE,

            // fatigued
            equipMod : StatSet.new(
                SPD: -100,
                DEX: -100
            ),
            useEffects : [
            ],
            possibleAbilities : [
            ],

            equipEffects : [],
            attributes : 
                Item.ATTRIBUTE.SHARP |
                Item.ATTRIBUTE.METAL
            ,
            onCreate ::(item, creationHint) {}

        })        


        Item.database.newEntry(data : {
            name : "Shipment",
            description: 'A large container full of raw material. One person can barely lift it alone. Can be quite expensive.',
            examine : '',
            equipType: Item.TYPE.HAND,
            rarity : 300,
            canBeColored : false,
            keyItem : false,
            weight : 250,
            basePrice: 150,
            levelMinimum : 1,
            tier: 2,
            hasSize : false,
            canHaveEnchants : false,
            canHaveTriggerEnchants : false,
            enchantLimit : 10,
            hasQuality : false,
            hasMaterial : true,
            isApparel : false,
            isUnique : false,
            useTargetHint : Item.USE_TARGET_HINT.ONE,

            // fatigued
            equipMod : StatSet.new(
                SPD: -100,
                DEX: -100
            ),
            useEffects : [
            ],
            possibleAbilities : [
            ],

            equipEffects : [],
            attributes : 
                Item.ATTRIBUTE.SHARP |
                Item.ATTRIBUTE.METAL
            ,
            onCreate ::(item, creationHint) {}

        })   

    
    },
    onSaveLoad ::(data) {
        data.trader.dayStart();
    }
}
