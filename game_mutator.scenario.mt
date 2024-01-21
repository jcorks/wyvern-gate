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


@:Scenario = databaseItemMutatorClass(
    name: 'Wyvern.Scenario',
    items : {
        data : empty
    },
    database : 
        Database.new(
            name : 'Wyvern.Scenario.Base',
            attributes : {
                name : String,
                // the function to start off the scenario
                begin : Function,
                // Function called when a new day starts.
                newDay : Function,
                // provides the options one has when interacting with a person.
                // This is decided by the scenario
                personInteractions : Object
            }
        ),
    define::(this, state) {
        this.interface = {
            defaultLoad ::{
                state.data = {};
            },
            
            data : {
                get ::<- state.data
            },
            
            newDay :: {
                state.base.newDay(data:state.data)
            }
        }
    }
);






Scenario.database.newEntry(
    data : {
        name : 'The Chosen',
        begin ::(data) {
            @:instance = import(module:'game_singleton.instance.mt');
            @:story = import(module:'game_singleton.story.mt');
            @world = import(module:'game_singleton.world.mt');
            @:LargeMap = import(module:'game_singleton.largemap.mt');
            @party = world.party;            
        
                //story.tier = 2;
            @:keyhome = Item.new(
                base: Item.database.find(name:'Wyvern Key'),
                creationHint: {
                    nameHint:namegen.island(), levelHint:story.levelHint
                }
            );
            keyhome.name = 'Wyvern Key: Home';
            
            
                
            keyhome.addIslandEntry(world);
            world.island = keyhome.islandEntry;
            @:island = world.island;
            party = world.party;
            party.reset();



            
            // debug
                //party.inventory.addGold(amount:100000);

            
            // since both the party members are from this island, 
            // they will already know all its locations
            foreach(island.landmarks)::(index, landmark) {
                landmark.discover(); 
            }
            
            
            
            @:Species = import(module:'game_database.species.mt');
            @:p0 = island.newInhabitant(speciesHint: island.species[0], levelHint:story.levelHint);
            @:p1 = island.newInhabitant(speciesHint: island.species[1], levelHint:story.levelHint-2);
            // theyre just normal people so theyll have some trouble against 
            // professionals.
            p0.normalizeStats();
            p1.normalizeStats();

            party.inventory.add(item:Item.new(
                base:Item.database.find(name:'Sentimental Box')
            ));



            // debug
                /*
                //party.inventory.add(item:Item.database.find(name:'Pickaxe'
                //).new(from:island.newInhabitant(),rngEnchantHint:true));
                
                @:story = import(module:'game_singleton.story.mt');
                story.foundFireKey = true;
                story.foundIceKey = true;
                story.foundThunderKey = true;
                story.foundLightKey = true;
                story.tier = 3;
                
                party.inventory.addGold(amount:20000);
                


                

                @:story = import(module:'game_singleton.story.mt');
                

                

                party.inventory.maxItems = 50
                for(0, 20) ::(i) {
                    party.inventory.add(
                        item:Item.new(
                            base:Item.database.getRandomFiltered(
                                    filter:::(value) <- value.isUnique == false && value.hasQuality
                            ),
                            rngEnchantHint:true
                        )
                    )
                };
                */
                
                


                
                /*
                @:sword = Item.new(
                    base: Item.database.find(name:'Glaive'),
                    materialHint: 'Ray',
                    qualityHint: 'Null',
                    rngEnchantHint: false
                );

                @:tome = Item.new(
                    base:Item.database.find(name:'Tome'),
                    materialHint: 'Ray',
                    qualityHint: 'Null',
                    rngEnchantHint: false,
                    abilityHint: 'Cure'
                );
                party.inventory.add(item:sword);
                party.inventory.add(item:tome);
                
                */


            party.add(member:p0);
            party.add(member:p1);
            
            
            /*
            windowEvent.queueMessage(
                text: '... As it were, today is the beginning of a new adventure.'
            );


            windowEvent.queueMessage(
                text: '' + party.members[0].name + ' and their faithful companion ' + party.members[1].name + ' have decided to leave their long-time home of ' + island.name + '. Emboldened by countless tales of long lost eras, these 2 set out to discover the vast, mysterious, and treacherous world before them.'
            );

            windowEvent.queueMessage(
                text: 'Their first task is to find a way off their island.\nDue to their distances and dangerous winds, travel between sky islands is only done via the Wyvern Gates, ancient portals of seemingly-eternal magick that connect these islands.'
            );
            
            windowEvent.queueMessage(
                text: party.members[0].name + ' has done the hard part and acquired a key to the Gate.\nAll thats left is to go to it and find where it leads.'
            );
            */





            @somewhere = LargeMap.getAPosition(map:island.map);
            island.map.setPointer(
                x: somewhere.x,
                y: somewhere.y
            );               
            instance.savestate();
            @:Scene = import(module:'game_database.scene.mt');
            Scene.start(name:'scene_intro', onDone::{                    
                instance.visitIsland();
                
                /*island.addEvent(
                    event:Event.database.find(name:'Encounter:Non-peaceful').new(
                        island, party, landmark //, currentTime
                    )
                );*/  
            });        
        },
        newDay ::{},
        
        personInteractions : [
            'hire',
            'barter',
            'aggress'
        ]
    }
)   


::<= {



@:ROLES = {
    WAITING : 0,
    DISPATCHED : 1,
    IN_PARTY : 2,
    BODYGUARD : 3
}

@:roleToString::(role) {
    return match(role) {
      (0): 'Waiting',
      (1): 'Dispatched',
      (2): 'In Party',
      (3): 'Bodyguard'
    }
}
@:TraderState_Hiree = LoadableClass.create(
    name: 'Wyvern.Scenario.TheTrader.State.Hiree',
    items : {
        // entity of the hiree
        member : empty,
        
        memberID : empty,
        
        // contract amount 
        contractRate : 0,
        
        // Whether the hiree was dispatched for the day.
        role : ROLES.WAITING
    },
    define ::(this, state) {
        @lastAttackedBy;
    
        this.interface = {
            defaultLoad ::(member, rate) {
                state.member = member;
                state.contractRate = rate;
                state.memberID = member.worldID; 
            },
            
            entity : {
                get ::<- state.member
            },
            
            lastAttackedBy : {
                get ::<- lastAttackedBy
            },
            
        
            // deducted each day from total.
            contractRate : {
                get ::<- state.contractRate
            },
            
            role : {
                get ::<- state.role,
                set ::(value) <- state.role = value
            },
            
            addToParty ::{
                @world = import(module:'game_singleton.world.mt');
                world.party.add(member: state.member);
                state.member = empty;             
            },
            
            returnFromParty ::{
                @world = import(module:'game_singleton.world.mt');
                {:::} {
                    foreach(world.party.members) ::(i, member) {
                        if (state.memberID == member.worldID) ::<= {
                            world.party.remove(member);
                            state.member = member;
                            send();
                        }
                    }
                }
            },
            
            // dispatches the NPC to go foraging in the shrine
            // this is a simulated / simplified experience
            dispatch::{
                @world = import(module:'game_singleton.world.mt');
                @spoils = [];
                
                @:defeat ::{
                    if (random.flipCoin())
                        state.member.kill(silent:true);
                }
                
                {:::} {
                    for(0, random.integer(from:10, to:20)) ::(i) {
                        (random.pickArrayItemWeighted(
                            list : [
                                // small chest
                                {
                                    rarity: 5,
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
                                    rarity: 2,
                                    action::{
                                        @:instance = import(module:'game_singleton.instance.mt');                                    
                                        @other;
                                        if (random.flipCoin()) ::<= {
                                            other = instance.island.newInhabitant()
                                            other.anonymize();
                                        } else if (Number.random() > 0.02) ::<= {
                                            other = instance.island.newHostileCreature()
                                            other.name = 'a ' + other.name;
                                        } else ::<= {
                                            @:TheBeast = import(module:'game_class.landmarkevent_thebeast.mt');
                                            other = TheBeast.createBeast();
                                        } 
                                            
                                        lastAttackedBy = other;
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
                }
                // Too bad 
                when (state.member.isDead) [];
                @:Entity = import(module:'game_class.entity.mt');
                // first, look through all items and pick any equipment thats 
                // more expensive for the slot. This approximates "better gear"
                breakpoint();
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
                        spoilsFiltered->push(value:current)
                    
                }
                spoils = spoilsFiltered;
                breakpoint();
                
                
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
        shopID : empty
    },
    
    define::(this, state) {
        this.interface = {
            defaultLoad::(city, shop) {
                @:Inventory = import(module:'game_class.inventory.mt');
                state.hirees = [];
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
            
            dayStart ::{
                @:instance = import(module:'game_singleton.instance.mt');
                @world = import(module:'game_singleton.world.mt');
                @party = world.party;            



                @:currentLandmark = instance.landmark;
                when (currentLandmark != empty && currentLandmark.base.pointOfNoReturn == true) ::<= {
                    windowEvent.queueMessage(
                        speaker: party.members[0].name,
                        text: '"What a terrible night to be stuck here. Guess I won\'t open shop today."'
                    );
                }

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


            },
        
            dayEnd:: {
                @world = import(module:'game_singleton.world.mt');

                windowEvent.queueMessage(
                    text: 'The day is over.'
                );

            
                if (state.hirees->size > 0) ::<= {
                    windowEvent.queueMessage(
                        text: 'News from your dispatched hirees has arrived.'
                    );
                }
                foreach([...state.hirees]) ::(i, hiree) {
                    when (hiree.role != ROLES.DISPATCHED) empty;
                    @:spoils = hiree.dispatch();
                    
                    when (hiree.entity.isDead) ::<= {
                        windowEvent.queueMessage(
                            speaker: 'Courier',
                            text: '"I have unfortunate news... Your hiree ' + hiree.entity.name + ' has not returned from their exploration. Word is that ' + hiree.lastAttackedBy.name + ' got them while adventuring. I don\'t think they\'ll be coming back..."'
                        );
                        
                        state.hirees->remove(key:state.hirees->findIndex(value:hiree));
                        windowEvent.queueMessage(
                            text: hiree.entity.name + ' was removed from the hirees list.'
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
                        @itemsFound = "Items found by " + hiree.entity.name + '\n';
                        foreach(spoils) ::(i, item) {
                            itemsFound = itemsFound + "-" + item.name + '\n'
                            world.party.inventory.add(item);
                        }
                        windowEvent.queueMessage(
                            text:itemsFound 
                        );                        
                    }
                    hiree.entity.heal(amount:hiree.entity.stats.HP, silent:true);
                    
                }
            
                @status = "Todays profit:\n";
                
                @earnings = world.party.inventory.gold - state.startingG;
                status = status + "  Earnings     : "+ (if (earnings < 0) earnings else "+" + earnings) + "\n\n";
                @cost = 0;
                foreach(state.hirees) ::(i, hiree) {
                    cost += hiree.contractRate;
                }
                status = status + "  Contracts    : -" + cost + "G\n";
                
                cost += state.upkeep;
                status = status + "  Upkeep       : -" + state.rent + "G\n";
                
                @currentG = world.party.inventory.gold
                @:profit = earnings - cost;
                state.days += 1;
                if (profit > state.bestProfit)            
                    state.bestProfit = profit;
                if (state.days % 3 == 0) 
                    state.upkeep += (state.bestProfit * 0.33)->floor;
                
                status = status + "_________________________________\n";
                status = status + "  Profit       : " + (if (profit < 0) profit else "+" + profit) + "\n\n";
                

                world.party.inventory.subtractGold(amount:cost);

                if (cost > currentG)
                    status = status + "Remaining G: [BANKRUPT]"
                else 
                    status = status + "Remaining G: " + world.party.inventory.gold

                // return to pool
                foreach(state.hirees) ::(i, hiree) {
                    if (world.party.isMember(entity:hiree.entity))
                        hiree.returnFromParty();
                }
                state.startingG = world.party.inventory.gold;                
                windowEvent.queueMessage(text:status);
            },
            
            newDay :: {
                this.dayEnd();
                this.dayStart();
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
                      'Guard the shop'                    
                    ],
                    leftWeight: 1,
                    topWeight: 0.5,
                    canCancel: true,
                    onChoice ::(choice) {
                        hiree.role = choice-1;
                    }
                );
            },
            
            manageHirees :: {
                when(state.hirees->size == 0)
                    windowEvent.queueMessage(
                        text: 'You don\'t currently have anyone employed.'
                    );
                windowEvent.queueChoices(
                    onGetChoices ::{
                        @:choices = [];
                        foreach(state.hirees) ::(i, hiree) {
                            choices->push(value: hiree.entity.name + ' -- ' + roleToString(role:hiree.role));
                        }
                        return choices;
                    },
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
                                'Change role',
                                'Fire'
                            ],
                            canCancel : true,
                            onChoice::(choice) {
                                when(choice == 0) empty;
                                
                                match(choice) {
                                  (1): ::<= {
                                    hiree.entity.describe()
                                  },
                                  
                                  (2): ::<= {
                                    this.changeRole(hiree);
                                  }
                                }
                            }
                        );
                    }
                );
            },
            
            explore ::{
                windowEvent.queueChoices(
                    prompt: 'What next?',
                    choices : [
                        'Manage hirees',
                        'Start exploring!'
                    ],
                    keep:true,
                    canCancel: false,
                    onChoice::(choice) {
                        when(choice == 0) empty;
                        match(choice) {
                          (1): ::<= {
                            this.manageHirees();                            
                          },
                          
                          (2): ::<= {
                            @:instance = import(module:'game_singleton.instance.mt');
                            instance.visitIsland();            
                            windowEvent.jumpToTag(name:'day-start', goBeforeTag:true, doResolveNext:true);

                          }
                        }
                    }
                );            
            },
            
            stockShop ::{
                @:pickItem = import(module:'game_function.pickitem.mt');
                @world = import(module:'game_singleton.world.mt');

                @:shopInventory ::{
                    when(state.shopInventory.items->size == 0)
                        windowEvent.queueMessage(
                            text: 'The shop has no items stocked. You have to stock it from your inventory first.'
                        );
                    
                    pickItem(
                        inventory: state.shopInventory,
                        canCancel: true,
                        showGold: true,
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
                    
                    pickItem(
                        inventory: world.party.inventory,
                        canCancel: true,
                        showGold: true,
                        goldMultiplier: 0.1,
                        topWeight: 0.5,
                        leftWeight: 0.5,
                        onPick ::(item) {
                            windowEvent.queueChoices(
                                prompt: item.name,
                                leftWeight: 1,
                                choices: [
                                    'Check',
                                    'Stock in shop'
                                ],
                                
                                onChoice::(choice) {
                                    when(choice == 0) empty;
                                    match(choice) {
                                      (1): ::<= {
                                        item.describe();
                                      },
                                      
                                      (2): ::<= {
                                        world.party.inventory.remove(item);
                                        state.shopInventory.add(item);
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
            
            startShopDay :: {
                @world = import(module:'game_singleton.world.mt');
                // fast forward till morning
                {:::} {
                    forever ::{
                        if (world.time == world.TIME.MORNING) send();
                        world.stepTime();
                    }
                }

                // find shop
                @:instance = import(module:'game_singleton.instance.mt');
                instance.visitIsland();
                @:landmark = world.island.landmarks->filter(by::(value) <- value.worldID == state.cityID)[0];
                @:location = landmark.locations->filter(by::(value) <- value.worldID == state.shopID)[0];
                instance.visitLandmark(landmark, where:{x:location.x, y:location.y});            
                windowEvent.jumpToTag(name:'day-start', goBeforeTag:true, doResolveNext:true);


                @maxPerHour = (
                    (state.shopInventory.items->size / 4.5)
                )->ceil;
                
                if (maxPerHour < 3)
                    maxPerHour = 3;


                @shopperList = [];

                @:endShopDay :: {
                    {:::} {
                        forever ::{
                            when(world.time != world.TIME.DAWN)
                                world.stepTime();
                            send();
                        }
                    }                
                }
                    
                @:startHour ::{
                
                    if (world.time > world.TIME.EVENING) ::<= {
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

                    @:shoppers = random.integer(from:0, to:maxPerHour);

                    if (shoppers == 0)
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
                        );

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
                    
                    @:item = state.shopInventory.items->pop;
                    
                    windowEvent.queueMessage(
                        speaker: shopper.name,
                        text: (random.pickArrayItem(
                            list : [
                                '"Hello! I would like this $, please."',
                                '"Hmm this one looks interesting. I would like the $, please."',
                                '"This would make an excellent gift. I\'ll take one $."',
                                '"Wow I love these! I\'ll take one $!"'
                            ]
                        ))->replace(key:'$', with: item.name),
                        onLeave ::{
                            /// barter logic

                   
                            @sale = item.price / 10;
                            world.party.inventory.addGold(amount:sale);
                            windowEvent.queueMessage(
                                text: shopper.name + ' bought the ' + item.name + ' for ' + sale + 'G.',
                                onLeave ::{
                                    state.shopInventory.remove(item);
                                    nextShopper();                        
                                }
                            );
                        
                        }
                    );
                }
                
                @:finishHour ::{
                    world.stepTime();                    
                    startHour();                                
                }
            
                
                                
            },
            
            openShop :: {
                windowEvent.queueChoices(
                    prompt: 'Shop options:',
                    choices : [
                        'Manage hirees',
                        'Stock shop', // inv to shop 
                        'Upgrade shop', // stock, starts at 15 
                        'Start the day!'
                    ],
                    keep:true,
                    canCancel: true,
                    onChoice::(choice) {
                        when(choice == 0) empty;
                        match(choice) {
                          (1): this.manageHirees(),
                          (2): this.stockShop(),
                          (3): this.upgradeShop(),
                          (4): this.startShopDay()
                        }
                    }
                );
            }                      
        }
    }
)
Scenario.database.newEntry(
    data : {
        name : 'The Trader',
        begin ::(data) {
        
        
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
                base: Item.database.find(name:'Wyvern Key'),
                creationHint: {
                    nameHint:namegen.island(), levelHint:story.levelHint
                }
            );
            keyhome.name = 'Wyvern Key: Home';
            
                
            keyhome.addIslandEntry(world);
            world.island = keyhome.islandEntry;
            @:island = world.island;
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
            party.inventory.addGold(amount:500);
            
            
            
            // setup shop
            @:city = island.landmarks->filter(by::(value) <- value.base.name == 'City')[0];            
            @:shop = city.locations->filter(by::(value) <- value.base.name == 'Shop')[0];
            shop.ownedBy = p0;

            data.trader = TraderState.new(
                city,
                shop
            );

            

            /*data.trader.addHiree(
                entity: world.island.newInhabitant(),
                rate:117
            );*/


            @somewhere = LargeMap.getAPosition(map:island.map);
            island.map.setPointer(
                x: somewhere.x,
                y: somewhere.y
            );               
            //instance.savestate();
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

        newDay ::(data){
            when(data.trader == empty) empty;
            data.trader.newDay();
        },

        
        personInteractions : [
            'barter',
            'trader.hire-with-contract'
        ]
    }
)   
}
return Scenario;

