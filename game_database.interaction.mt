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



@:reset ::{

@:StatSet = import(module:'game_class.statset.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Battle = import(module:'game_class.battle.mt');
@:random = import(module:'game_singleton.random.mt');
@:Material = import(module:'game_database.material.mt');
@:Profession = import(module:'game_database.profession.mt');
@:Item = import(module:'game_mutator.item.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:g = import(module:'game_function.g.mt');
@:Scene = import(module:'game_database.scene.mt');
@:chooseMultiple = import(:'game_function.choosemultiple.mt');



Interaction.newEntry(
  data : {
    id :  'base:exit',
    name : 'Exit',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      when (location.peaceful == false && 
        (location.landmark.base.id == 'base:town' || location.landmark.base.id == 'base:city')) ::<= {
        windowEvent.queueMessage(
          speaker: '???',
          text: "There they are!!"
        );
        @:world = import(module:'game_singleton.world.mt');

        match(world.battle.start(
          party,              
          allies: party.members,
          enemies: [
            location.landmark.island.newInhabitant(professionHint:'base:guard'),
            location.landmark.island.newInhabitant(professionHint:'base:guard'),
            location.landmark.island.newInhabitant(professionHint:'base:guard'),            
          ]->map(to:::(value){ value.anonymize(); return value;}),
          landmark: {}
        ).result) {
          (Battle.RESULTS.ALLIES_WIN,
           Battle.RESULTS.NOONE_WIN): ::<= {
          },
          
          (Battle.RESULTS.ENEMIES_WIN): ::<= {
            @:instance = import(module:'game_singleton.instance.mt');
            instance.gameOver(reason:'The party was wiped out.');
          }
        } 
      }

      // jumps to the prev menu lock
      windowEvent.jumpToTag(name:'VisitLandmark', goBeforeTag:true, clearResolve:true);
    }
  }
)
Interaction.newEntry(
  data : {
    name : 'Examine',
    id :  'base:examine',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      // jumps to the prev menu lock
      windowEvent.queueMessage(speaker:location.name, text:location.description);       
    }
  }
)

Interaction.newEntry(
  data : {
    name : 'Vandalize',
    id :  'base:vandalize',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      // this is so silly but ill make it do something one day
      windowEvent.queueMessage(text:'You try to vandalize the location, but you do a poor job.');       
      @:world = import(module:'game_singleton.world.mt')
      world.accoladeEnable(name:'hasVandalized');


      if (location.landmark.peaceful) ::<= {
        location.landmark.peaceful = false;
        windowEvent.queueMessage(text:'Even though you did a poor job, the people here are now aware of your aggression.');
      }        
    }
  }
)


Interaction.newEntry(
  data : {
    id :  'base:stairs',
    name : 'Stairs',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      

    }
  }
)

Interaction.newEntry(
  data : {
    id :  'base:press-pressure-plate',
    name : 'Press',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      
      windowEvent.queueChoices(
        prompt: 'Who will press it?',
        canCancel: true,
        choices: [...party.members]->map(to:::(value) <- value.name),
        onChoice::(choice) {
          when(choice == 0) empty;
          @whom = party.members[choice-1];
    
          when (location.data.pressed) ::<= {
            windowEvent.queueMessage(
              text: 'The plate was pressed but nothing happened.'
            );
          }
          if (location.data.trapped == true) ::<= {
            windowEvent.queueMessage(
              text: 'The pressure plate was trapped!'
            );
            (import(module:'game_function.trap.mt'))(location, party, whom);
            @:world = import(module:'game_singleton.world.mt')
            world.accoladeIncrement(name:'trapsFallenFor');                    
          } else ::<= {
            windowEvent.queueMessage(
              text: 'Something clicked elsewhere.'
            );        
          }
          location.data.pressed = true;        
        }
      )
    }    
  }

)


Interaction.newEntry(
  data : {
    id :  'base:examine-plate',
    name : 'Is this a trap...?',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:displayState ::(speaker){
        if (location.data.detected == true) ::<= {
          if (location.data.trapped == true) ::<= {
            windowEvent.queueMessage(
              speaker,
              text: '"It is very likely this is trapped."'
            );
          } else ::<= {
            windowEvent.queueMessage(
              speaker,
              text: '"It is very likely that this is safe."'
            );          
          }
        } else ::<= {
          windowEvent.queueMessage(
            speaker,
            text: '"It\'s hard to tell if it\'s trapped."'
          );                
        }
      }
      
      
      when (location.data.detected != empty) ::<= {
        displayState();
      }

      windowEvent.queueChoices(
        prompt: 'Who will examine it?',
        canCancel: true,
        choices: [...party.members]->map(to:::(value) <- value.name),
        onChoice::(choice) {
          when(choice == 0) empty;
          @whom = party.members[choice-1];
    
          @:test = location.landmark.island.newAggressor();
          if (random.try(percentSuccess:70))
            location.data.detected = (test.stats.INT < whom.stats.INT)
          else
            location.data.detected = false;
            
          displayState(speaker:whom.name);
         
        }
      )

    }    
  }

)



Interaction.newEntry(
  data : {
    id :  'base:talk',
    name : 'Talk',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      // jumps to the prev menu lock
      @choices = [];
      if (location.ownedBy != empty)
        choices->push(value:location.ownedBy);
      foreach(location.occupants)::(index, person) {
        choices->push(value:person);
      }
      
      when (choices->keycount == 0)
        windowEvent.queueMessage(text:'No one is within the ' + location.base.name);       

      @talkee;
      
      windowEvent.queueChoices(
        prompt: 'Talk to whom?',
        choices : [...choices]->map(to:::(value) <- value.name),
        canCancel : true,
        onChoice::(choice) {
          when(choice == 0) empty;
          talkee = choices[choice-1];              

          // if cancelled
          when(talkee == empty) empty;


          if (location.peaceful == false && !talkee.isIncapacitated()) ::<= {
            @:Event = import(module:'game_mutator.event.mt');


            if (location.landmark.base.guarded == true) ::<= {
              windowEvent.queueMessage(speaker:talkee.name, text:'Guards! Guards! Help!');
              Scene.start(id:'base:scene_guards0', onDone::{}, location, landmark:location.landmark);
            } else ::<= {
              @:world = import(module:'game_singleton.world.mt');
              windowEvent.queueMessage(speaker:talkee.name, text:'You never should have come here!');
              world.battle.start(
                party,              
                allies: party.members,
                enemies: [talkee],
                landmark: {},
                onEnd::(result) {
                  @:instance = import(module:'game_singleton.instance.mt');
                  when(!world.battle.partyWon()) 
                    instance.gameOver(reason:'The party was wiped out.');
                
                  location.ownedBy = empty;                                    
                }
              );                
            }
          } else ::<= {
            talkee.interactPerson(
              party,
              location
            );
          }

        }
      );
      
    }
  }
)




Interaction.newEntry(
  data : {
    name: 'Buy Drink',
    id :  'base:drink:tavern',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:story = import(module:'game_singleton.story.mt');
      @:world = import(module:'game_singleton.world.mt');
      when (location.peaceful == false) ::<= {
        windowEvent.queueMessage(
          speaker: 'Bartender',
          text: "Nope. Not servin' ya. Get out."
        );
      }
      
      windowEvent.queueAskBoolean(
        prompt: 'Buy a drink? (1G)',
        onChoice::(which) {
          when(which  == false) empty; 
      when (party.inventory.gold < 5)
        windowEvent.queueMessage(text:'Not enough gold...');
      
        party.inventory.subtractGold(amount:1);
        world.accoladeIncrement(name:'drinksTaken');                    
        
        windowEvent.queueMessage(
          text: random.pickArrayItem(list:
            [
              'The frothy drink calms your soul.',
              'Tastes a bit fruitier than you would have thought.',
              'The drink puts you at ease.',
            ]       
          )
        );   


        /*
        foreach(party.members)::(index, member) {
          if (member.ap < member.stats.AP)
            member.healAP(amount:member.stats.AP * 0.1);
        }
        */



        
        @:chance = random.number();
        match(true) {
          // normal
          (chance < 0.7)::<= {
            windowEvent.queueMessage(
              text:'Someone sits next to you.'
            );   
            
            @:talkee = location.landmark.island.newInhabitant();
            talkee.adventurous = true;
            
            // Here is the wild-west of stats. You could find someone stronger than normal here 
            // but its up in the air whether theyll join you.
            if (random.flipCoin())
              talkee.normalizeStats();
            
            
            talkee.interactPerson(
              party,
              location,
              onDone::{
                windowEvent.queueMessage(text:'You finish your drink.');                
              }
            );
          },
          

          // gamblist
          (chance < 0.85 && world.npcs.skie != empty && !world.npcs.skie.isIncapacitated() && !world.party.isMember(entity:world.npcs.skie))::<= {
            windowEvent.queueMessage(
              text:'Someone sits next to you...'
            );   
            
            if (story.skieEncountered) ::<= {
              windowEvent.queueMessage(
                text:'... wait it\'s.. huh.'
              );                 

              windowEvent.queueMessage(
                speaker: 'Wandering Gamblist',
                text:'"Hello again, stranger."'
              );                 

                  
            } else ::<= {
              story.skieEncountered = true;
              windowEvent.queueMessage(
                speaker: '???',
                text:'"Hello, stranger."'
              );                 

            }
            

            windowEvent.queueMessage(
              speaker: 'Wandering Gamblist',
              text:'"May I interest you in some... Entertainment? All it costs is an item of yours. Any will do."'
            );                 

            windowEvent.queueMessage(
              speaker: 'Wandering Gamblist',
              text:'"If you win, you get your item back and one of mine. If I win, well..."'
            );              


            windowEvent.queueAskBoolean(
              prompt:'Play a game?',
              onChoice::(which) {
                when(which == false) ::<= {
                  windowEvent.queueMessage(
                    speaker: 'Wandering Gamblist',
                    text:'"Suit yourself. Perhaps another time."'
                  );                 
                }     

                @:pickItem = import(module:'game_function.pickpartyitem.mt');
                pickItem(
                  canCancel:true, 
                  prompt: 'Wager which?',
                  topWeight : 0.5,
                  leftWeight : 0.5,
                  onPick::(item) {
                    when(item == empty) ::<= {
                      windowEvent.queueMessage(
                        speaker: 'Wandering Gamblist',
                        text:'"Suit yourself. Perhaps another time."'
                      );
                      windowEvent.jumpToTag(name:'pickItem', doResolveNext: true, goBeforeTag: true);
                                                        
                    }
                    
                  
                    windowEvent.queueMessage(
                      speaker: 'Wandering Gamblist',
                      text: '"Excellent. Now, we play."'                  
                    );
                    windowEvent.jumpToTag(name:'pickItem', doResolveNext: true, goBeforeTag: true);
                    
                    @:gamblist = import(module:'game_singleton.gamblist.mt');
                    gamblist.playGame(onFinish::(partyWins) {
                      when(!partyWins) ::<= {
                        windowEvent.queueMessage(
                          speaker: 'Wandering Gamblist',
                          text: '"Ah, well. Perhaps next time. A gamble is a gamble, after all."'                  
                        );
                        party.inventory.remove(item);
                        if (item.equippedBy != empty)
                          item.equippedBy.unequipItem(item:item);
                          
                        if (item.name->contains(key:'Wyvern Key of'))
                          world.accoladeEnable(name:'gotRidOfWyvernKey');    
                      }
                      @:offerJoin = world.accoladeEnabled(name:'wonGamblingGame') &&
                                    world.party.members->size < 3;
                      world.accoladeEnable(name:'wonGamblingGame');
                      
                      windowEvent.queueMessage(
                        speaker: 'Wandering Gamblist',
                        text: '"Ah, well done. A gamble is a gamble, after all."'                  
                      );
                      
                      if (offerJoin) 
                        windowEvent.queueMessage(
                          speaker: 'Wandering Gamblist',
                          text: '"Alternatively, I can offer my services..."'                  
                        );
                        
                      
                      windowEvent.queueChoices(
                        canCancel: false,
                        choices: 
                          if (offerJoin)
                            ['Get Prize', 'Join Party']
                          else 
                            ['Get Prize']
                        ,
                        onChoice::(choice) {
                          when(choice == 2) ::<= {
                            @:Species = import(module:'game_database.species.mt');
                            @:Entity = import(module:'game_class.entity.mt');

                            windowEvent.queueMessage(
                              text: world.npcs.skie.name + ' joins the party!'
                            );        
                            party.add(member:world.npcs.skie);
                            world.npcs.skie = empty;
                            world.accoladeEnable(name:'recruitedOPNPC');
                            
                          }
                        
                        
                          @itemPrice = item.price;
                          @itemChoices = [];
                          
                          @itemMaterials = [
                            'base:gold',
                            'base:crystal',
                            'base:mythril',
                            'base:quicksilver',
                            'base:dragonglass',
                            'base:sunstone',
                            'base:moonstone',
                          ]
                          
                          @itemQualities = [
                            'base:durable',
                            'base:standard',
                            'base:kings',
                            'base:queens',
                            'base:masterwork',
                            'base:legendary'
                          ]
                          
                          for(0, 50)::(i) {
                            @newItem = Item.new(
                              base: Item.database.getRandomFiltered(
                                filter::(value) <- (
                                  value.isUnique == false &&
                                  value.hasMaterial == true &&
                                  value.hasQuality == true
                                )
                              ),
                              rngEnchantHint:true,     
                              qualityHint : random.pickArrayItem(list:itemQualities),
                              materialHint : random.pickArrayItem(list:itemMaterials)
                            )  
                            itemChoices->push(value:newItem);                  
                          }
                          
                          itemChoices->sort(comparator::(a, b) {
                            @diffA = (a.price - itemPrice)->abs;
                            @diffB = (b.price - itemPrice)->abs;
                            when (diffA < diffB) -1;
                            when (diffA > diffB)  1;
                            return 0;
                          });
                          
                          itemChoices = itemChoices->subset(from:0, to:6);
                          
                          @:Inventory = import(module:'game_class.inventory.mt');
                          @inv = Inventory.new(size: 30);
                          foreach(itemChoices)::(i, it) {
                            inv.add(item:it);
                          }
                          
                          @:pickItemInv = (import(module:'game_function.pickitem.mt'));
                          pickItemInv(
                            canCancel : false,
                            onGetPrompt ::<- 'Pick a prize!',
                            topWeight : 0.5,
                            leftWeight : 0.5,
                            inventory:inv,
                            onPick::(item) {
                              windowEvent.queueMessage(
                                text: 'The party won the ' + item.name + '!'
                              );
                              
                              party.inventory.add(item);

                              windowEvent.queueMessage(
                                speaker: 'Wandering Gamblist',
                                text: '"Until next time..."'                  
                              );
                              windowEvent.jumpToTag(name:'pickItem', doResolveNext: true, goBeforeTag: true);
                            }
                          );                      
                        
                        }
                      );
                    });
                  }
                )


              }
            )          
          },


          

          // drunkard
          (chance < 0.88)::<= {              
          @:talkee = location.landmark.island.newInhabitant();
          talkee.supportArts = []; // drunk, no supports
          talkee.anonymize();
          windowEvent.queueMessage(
            text:'Someone stumbles toward you...'
          );

          windowEvent.queueMessage(
            speaker: '???',
            text: random.pickArrayItem(
              list: [
                '"Hhheeeyy whaddya ddoin heer"',
                '"wwwhaaat? did youu sayy to mee.??"',
                '"uugghht gett outtaa my waaayy"'
              ]
            )
          );

          @:world = import(module:'game_singleton.world.mt');
          world.accoladeEnable(name:'foughtDrunkard');
          world.battle.start(
            party,              
            allies: party.members,
            enemies: [talkee],
            landmark: {},
            onEnd::(result) {
              @:instance = import(module:'game_singleton.instance.mt');
              when(!world.battle.partyWon())
                instance.gameOver(reason:'The party was wiped out.');
            
              if (talkee.isDead) ::<= {
                windowEvent.queueMessage(
                  speaker: 'Bartender',
                  text:"You killed 'em...?"
                );              
                windowEvent.queueMessage(
                  speaker: 'Bartender',
                  text:"*sigh*"
                );              
                windowEvent.queueMessage(
                  text:'The guards are alerted of the death.'
                );              
                location.landmark.peaceful = false;
              } else ::<= {
                windowEvent.queueMessage(
                  speaker: 'Bartender',
                  text:'Gah, what a drunk. Sorry \'bout that.'
                );              
              }
                            
            }
          );              
          

          },
          
          default: 
          windowEvent.queueMessage(
            text:'The drink is enjoyed in solitude.'
          )
          
        }
                                    
                      
        }
      );
    }
  }
)

Interaction.newEntry(
  data : {
    name : 'Mine',
    id :  'base:mine',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:Entity = import(module:'game_class.entity.mt');

      if (location.data.charges == empty)
        location.data.charges = 5+random.number()*10;



      @:miners = party.members->filter(by:::(value) <- value.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR).base.name == 'Pickaxe');
      when(miners->keycount == 0)
        windowEvent.queueMessage(text:'No party member has a pickaxe equipped. Ore cannot be mined.');

      when (location.data.charges <= 0)
        windowEvent.queueMessage(text:'The ore vein is depleted...');
        

      
      @:minerNames = [...miners]->map(to:::(value) <- value.name);
      

      @:mining ::(miner) {
        windowEvent.queueMessage(text:'*clank clank*');

        if (random.number() > 0.9) ::<= {
          windowEvent.queueMessage(speaker:miner.name, text:'Oh...?');

          @:item = Item.new(base:Item.database.find(id:'base:ore'));
          
          windowEvent.queueMessage(text:'The party obtained some Ore!');   

          when (party.inventory.isFull) ::<= {
            windowEvent.queueMessage(text:'The party\'s inventory is full...');   
          }
          party.inventory.add(item);


          location.data.charges -= 1;    
          
          
        } else ::<= {
          windowEvent.queueMessage(text:'Nothing yet...');

        }
        windowEvent.queueAskBoolean(
          prompt:'Continue?',
          onChoice::(which) {
            when(which == true)
              mining(miner);
          }
        );          
      }
      
      
      windowEvent.queueChoices(
        prompt: 'Who will mine?',
        choices: minerNames,
        canCancel : true,
        onChoice ::(choice) {
          @:miner = miners[choice-1];          
          when(choice == 0) empty;
          mining(miner);
        }
      );
      

      
    }
  }
)

Interaction.newEntry(
  data : {
    name : 'Smelt Ore',
    id :  'base:smelt-ore',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:ores = party.inventory.items->filter(by:::(value) <- value.base.name == 'Ore');
      
      when(ores->keycount < 2)
        windowEvent.queueMessage(text: 'The party doesn\'t have enough ore to smelt into ingots. 2 units of ore are required per ingot.');

      party.inventory.remove(item:ores[0]);
      party.inventory.remove(item:ores[1]);
      
      @:metal = Item.new(base:Item.database.getRandomWeightedFiltered(filter:::(value) <- value.attributes & Item.database.statics.ATTRIBUTE.RAW_METAL));            
      windowEvent.queueMessage(text: 'Smelted 2 ore chunks into ' + correctA(word:metal.name) + '!');
      party.inventory.add(item:metal);          
        
    }

  }
)    


Interaction.newEntry(
  data : {
    name : 'Sell',
    id :  'base:sell:shop',
    keepInteractionMenu : true,
    onInteract ::(location, party) {

      when(location.ownedBy == empty)
        windowEvent.queueMessage(
          text: "No one is at the shop to sell you anything."
        );
        
      when(location.ownedBy.isIncapacitated())
        windowEvent.queueMessage(
          text: location.ownedBy.name + ' is incapacitated and cannot sell you anything.'
        );


      when (location.peaceful == false && location.ownedBy != empty) ::<= {
        windowEvent.queueMessage(
          speaker: location.ownedBy.name,
          text: "You're not welcome here!!"
        );
        world.battle.start(
          party,              
          allies: party.members,
          enemies: [location.ownedBy],
          landmark: {},
          onEnd::(result) {
            @:instance = import(module:'game_singleton.instance.mt');
            if (!world.battle.partyWon()) 
              instance.gameOver(reason:'The party was wiped out.');
          }
        );
      }

      @:world = import(module:'game_singleton.world.mt');
      when (world.time < world.TIME.MORNING || world.time > world.TIME.EVENING)
        windowEvent.queueMessage(text: 'The shop appears to be closed at this hour..');              


      @:pickItem = import(module:'game_function.pickitemprices.mt');
      pickItem(
        inventory:party.inventory,
        canCancel: true,
        leftWeight: 0.5,
        topWeight: 0.5,
        onGetPrompt:: <-  'Sell which? (current: ' + g(g:party.inventory.gold) + ')',
        goldMultiplier: (0.5 / 5)*0.5,
        header : ['Item', 'Price'],
        leftJustified : [true, false],
        onPick::(item) {
          when(item == empty) empty;

          @price = (item.price * ((0.5 / 5)*0.5))->ceil;
          if (price < 1) ::<= {
            windowEvent.queueMessage(
              speaker: location.ownedBy.name,
              text:'"Technically, this is worthless, but I thought I\'d do you a favor and take it off your hands."'
            )
            world.accoladeEnable(name:'soldWorthlessItem');
            price = 1;
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
              location.inventory.add(item);
            }
          )
        }
      );
    },
    

    
  }
)
Interaction.newEntry(
  data : {
    name : 'Expand Bag',
    id :  'base:bag:shop',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:cost = (200 + 30*(party.inventory.maxItems - 10)**1.3)->floor;
      windowEvent.queueMessage(text: 'The shopkeep offers to exchange your bag for a larger one. This new one will hold 5 additional items, making the capacity ' + (party.inventory.maxItems + 5) + ' items. This upgrade will cost ' + g(g:cost) +'.');
      when(party.inventory.gold < cost)
        windowEvent.queueMessage(text: 'The party cant afford to upgrade their bag.');
      windowEvent.queueAskBoolean(
        prompt: 'Expand bag for ' + cost + 'G?',
        onChoice::(which) {
          when(which == false) empty;
          
          party.inventory.maxItems += 5;
          windowEvent.queueMessage(text: 'The party\'s bag can now hold ' + party.inventory.maxItems + ' items.');
          party.addGoldAnimated(amount:-cost, onDone::{});
        }
      );              
            
    }
  }
);


Interaction.newEntry(
  data : {
    name : 'Buy',
    id :  'base:buy:shop',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');
      when(location.ownedBy == empty)
        windowEvent.queueMessage(
          text: "No one is at the shop to sell you anything."
        );
        
      when(location.ownedBy.isIncapacitated())
        windowEvent.queueMessage(
          text: location.ownedBy.name + ' is incapacitated and cannot sell you anything.'
        );


      when (location.peaceful == false && location.ownedBy != empty) ::<= {
        windowEvent.queueMessage(
          speaker: location.ownedBy.name,
          text: "You're not welcome here!!"
        );
        world.battle.start(
          party,              
          allies: party.members,
          enemies: [location.ownedBy],
          landmark: {},
          onEnd::(result) {
            @:instance = import(module:'game_singleton.instance.mt');
            if (!world.battle.partyWon()) 
              instance.gameOver(reason:'The party was wiped out.');
          }
        );
      }
      @:pickItem = import(module:'game_function.pickitemprices.mt');
      
      when (world.time < world.TIME.MORNING || world.time > world.TIME.EVENING)
        windowEvent.queueMessage(text: 'The shop appears to be closed at this hour..');              

      
      import(:'game_function.buyinventory.mt')(
        inventory:location.inventory,
        shopkeep: location.ownedBy
      );
    }
  }
)

Interaction.newEntry(
  data : {
    name : 'Uncover Art',
    id :  'base:uncover:arts',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');
      when(location.ownedBy == empty)
        windowEvent.queueMessage(
          text: "No one is at the shop to sell you anything."
        );
        
      when(location.ownedBy.isIncapacitated())
        windowEvent.queueMessage(
          text: location.ownedBy.name + ' is incapacitated and cannot provide this service.'
        );

      windowEvent.queueMessage(
        speaker: 'Arts Tecker',
        text: '"For merely 150G, I can unlock new Arts within you for use in battle."'
      );


      when(world.party.inventory.gold < 150)
        windowEvent.queueMessage(
          text: 'The party cannot afford this service.'
        );

      windowEvent.queueAskBoolean(
        prompt: 'Learn new Support Arts for 150G?',
        onChoice::(which) {
          when(which == false) empty;
          
          world.party.addGoldAnimated(amount:-150, onDone::{
            windowEvent.queueMessage(
              speaker: 'Arts Tecker',
              text: '"Deep within your soul, I unlock your potential..."'            
            );
            
            world.party.queueCollectSupportArt();

            windowEvent.queueMessage(
              speaker: 'Arts Tecker',
              text: '"Enjoy your new Arts... Haha..."'            
            );
          });
        }      
      );
    },
  }
)


Interaction.newEntry(
  data : {
    name : 'Exchange Arts',
    id :  'base:trade:arts',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');
      when(location.ownedBy == empty)
        windowEvent.queueMessage(
          text: "No one is at the shop to sell you anything."
        );
        
      when(location.ownedBy.isIncapacitated())
        windowEvent.queueMessage(
          text: location.ownedBy.name + ' is incapacitated and cannot provide this service.'
        );

      windowEvent.queueMessage(
        speaker: 'Arts Tecker',
        text: '"For 3 of your reserve Support Arts, I may give you one from my collection..."'
      );


      when(world.party.arts->size < 3)
        windowEvent.queueMessage(
          text: 'The party does not have 3 Support Arts in the Trunk for trading.'
        );

      windowEvent.queueAskBoolean(
        prompt: 'Trade 3 arts for a new one?',
        onChoice::(which) {
          when(which == false) empty;
          
          windowEvent.queueMessage(
            speaker: 'Arts Tecker',
            text: '"Choose 3 Support Arts to trade..."'            
          );
          
          
          
          @:choiceItems = [];
          @:choiceNames = [];
          
          @:Arts = import(:'game_database.arts.mt');
          @:ArtsDeck = import(:'game_class.artsdeck.mt');
          
          foreach(world.party.arts) ::(k, v) {
            for(0, v.count) ::(i) {
              choiceItems->push(:v.id);
              choiceNames->push(:Arts.find(:v.id).name);
            }
          }
          
          @hoveredArt;
          chooseMultiple(
            choiceItems,
            choiceNames,
            count: 3,
            prompt: 'Trade arts',
            leftWeight: 1,
            renderable : {
              render :: {
                when(hoveredArt == empty) empty;
                ArtsDeck.renderArt(
                  handCard:ArtsDeck.synthesizeHandCard(id:hoveredArt),
                  topWeight: 0.5,
                  leftWeight: 0
                );                  
              }
            },
            onHover::(item) {
              hoveredArt = item;
            },
            
            onChoice::(items) {          
              windowEvent.queueMessage(
                text: 'The Arts Tecker uses magick of some kind on the party...'            
              );

              world.party.queueCollectSupportArt();

              foreach(items) ::(k, id) {
                world.party.takeSupportArt(:id);
              }

              windowEvent.queueMessage(
                speaker: 'Arts Tecker',
                text: '"Enjoy your new Art... Haha..."'            
              );
            }
          );
        }
      );
    },
  }
)


Interaction.newEntry(
  data : {
    name : 'Forge',
    id :  'base:forge',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
    
      @:Entity = import(module:'game_class.entity.mt');

      @:items = party.inventory.items->filter(by:::(value) <- value.base.attributes & Item.database.statics.ATTRIBUTE.RAW_METAL);
      when(items->keycount == 0)
        windowEvent.queueMessage(text:'No suitable ingots or materials were found in the party inventory.');


      @charge = false;
      @smith = empty;

      @:smithingDo ::(item, ingot) {
        @:material = ingot.data.RAW_MATERIAL;

        @:output = Item.new(
          base:Item.database.find(id:item),
          materialHint: material
        );
        
        windowEvent.queueMessage(
          speaker: smith.name,
          text: 
            if (smith.profession.id == 'base:blacksmith')
              '"No problem!"'
            else 
              '"I\'m no blacksmith, but I\'ll try my best!"'
        );

        @success = if (smith.profession.id == 'base:blacksmith') true else random.flipCoin();                     
        

        windowEvent.queueMessage(
          text:'*clank clank*'
        );


        if (success) ::<= {
          party.inventory.remove(item:ingot);
          windowEvent.queueMessage(
            text:smith.name + ' forged a ' + output.name
          );
          
          windowEvent.queueCustom(
            onEnter ::{
              party.inventory.add(item:output);                                                    
            }
          );         
        } else ::<= {
          windowEvent.queueMessage(
            text: 'Due to their inexperience, ' + smith.name + ' burned their hand while mishandling the forge tools and was unable to produce anything.'
          );

          @:Damage = import(module:'game_class.damage.mt');
          smith.damage(
            attacker: smith,
            damage: Damage.new(
              amount: 1,
              damageType: Damage.TYPE.FIRE,
              damageClass: Damage.CLASS.HP
            ),
            dodgeable : false,
            critical : false
          );
        }       
      }


      @:smithingInAction = :: {
         
        @:itemNames = [...items]->map(to:::(value) <- value.name);

        windowEvent.queueChoices(
          prompt: 'Which material?',
          choices: itemNames,
          canCancel: true,
          onChoice::(choice) {
            @:ore = items[choice-1];

            windowEvent.queueAskBoolean(
              prompt:'Smith with ' + ore.base.name + '?',
              onChoice::(which) {
                when(which == false) empty;

                @:canMake = smith.getCanMake();
                @:canMakeNames = [...canMake]->map(to:::(value) <- Item.database.find(id:value).name);
                windowEvent.queueChoices(
                  prompt:smith.name + ' - "Here\'s what I can make:"',
                  choices: canMakeNames,
                  canCancel: true,
                  onChoice::(choice) {
                    when(choice == 0) empty;

                    when (party.isMember(entity:smith)) 
                      smithingDo(ingot:ore, item:canMake[choice-1]);
                    party.addGoldAnimated(
                      amount:-300,
                      onDone ::{
                        smithingDo(ingot:ore, item:canMake[choice-1]);           
                      }                  
                    );              
                  }
                )
              }
            )
          }
        );     
      }

    
      @:smiths = party.members->filter(by:::(value) <- value.profession.id == 'base:blacksmith');

      @:choosePartySmith ::{
        @hasHammer = [...party.members]->filter(
          by:::(value) <- value.getEquipped(
            slot:Entity.EQUIP_SLOTS.HAND_LR
          ).base.id == 'base:smithing-hammer'
        );
        
        windowEvent.queueAskBoolean(
          prompt: 'Have a party member work the forge?',
          onChoice::(which) {
            breakpoint();
            when(which == false) empty;

            when(hasHammer->size == 0)
              windowEvent.queueMessage(
                text: 'No one in the party has a Smithing Hammer equipped. Working the forge requies a Smithing Hammer in hand.'
              );

            @:hammerNames = [...hasHammer]->map(to:::(value) <- value.name);
            windowEvent.queueChoices(
              prompt: 'Who should work the forge?',
              choices: hammerNames,
              canCancel: true,
              onChoice::(choice) {
                when(choice == 0) empty;

                smith = hasHammer[choice-1];
                smithingInAction();
              
              }
            );              
          }
        );
      };

      if (smiths->keycount == 0) ::<= {
        windowEvent.queueMessage(text:'No one in your party can professionally work the forge (no one is a Blacksmith)');

        @:world = import(module:'game_singleton.world.mt');
        if (world.time < world.TIME.MORNING || world.time > world.TIME.EVENING) ::<= {
          windowEvent.queueMessage(text:'The Blacksmith here would normally be able to forge for you, but the blacksmith is gone for the night.');
          choosePartySmith();
        } else ::<= {
          windowEvent.queueMessage(text:'The Blacksmith offers to work the forge for you.');
          windowEvent.queueMessage(text:'While you don\'t have a Blacksmith, it is common for most folk to be able to use a forge for some items. Typically, Blacksmiths are preferred because of their larger amount of expertise and knowledge working the forge.');


          windowEvent.queueAskBoolean(
            prompt: 'Hire Blacksmith to forge for 300G?',
            onChoice::(which) {
              when(which == false) choosePartySmith();
              when(party.inventory.gold < 300)
                windowEvent.queueMessage(text:'The party cannot afford to pay the Blacksmith.');
              
              smith = location.ownedBy;
              charge = true;
              smithingInAction();
            }
          );
        }
      } else ::<= {
        choosePartySmith();      
      }
      
    },
    

    
  }
)

Interaction.newEntry(
  data : {
    name : 'Enter Gate',
    id :  'base:enter-gate',
    keepInteractionMenu : false,
    onInteract ::(location, party) {

      @:keys = [];
      @:keynames = [];
      foreach(party.inventory.items)::(index, item) {
        if (item.base.name->contains(key:'Key')) ::<= {
          keys->push(value: item);
          keynames->push(value: item.name);
        }
          
      }
      when(keys->keycount == 0)
        windowEvent.queueMessage(text:'Entering a gate requires a key. The party has none.');
        
      
        
      windowEvent.queueChoices(
        prompt: 'Enter with which?',
        choices: keynames,
        canCancel: true,
        onChoice:::(choice) {
          when(choice == 0) empty;
          canvas.clear();
          windowEvent.queueMessage(text:'As the key is pushed in, the gate gently whirrs and glows with a blinding light...');
          windowEvent.queueMessage(text:'As you enter, you feel the world around you fade.', renderable:{render::{canvas.blackout();}});
          windowEvent.queueMessage(text:'...', renderable:{render::{canvas.blackout();}});
          
          windowEvent.queueCustom( 
            onEnter::{
            @:Event = import(module:'game_mutator.event.mt');
            @:Landmark = import(module:'game_mutator.landmark.mt');
            @:world = import(module:'game_singleton.world.mt');
            @:instance = import(module:'game_singleton.instance.mt');


            @:key = keys[choice-1];
            world.loadIsland(:key);
            breakpoint();
            instance.visitIsland(
              atGate:true
            );
          });
        }
      );
    },
  }
)

Interaction.newEntry(
  data : {
    name : 'Warp to ???',
    id :  'base:warp-floor',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      when(location.data.warpPoint == empty)
        windowEvent.queueMessage(
          text: 'The warp column doesn\'t seem active.'
        );
      
      windowEvent.queueMessage(
        renderable : {
          render :: {
            canvas.blackout();
          }
        },
        text: 'The party was teleported elsewhere on the floor.'
      );
      
      @:warp = [...location.landmark.locations]->filter(by::(value) <- value.worldID == location.data.warpPoint)[0]
      
      when(warp == empty)
        windowEvent.queueMessage(
          text: 'The warp column doesn\'t seem active.'
        );
      
      location.landmark.map.setPointer(
        x:warp.x,
        y:warp.y
      );
    },
  }
)    
  
  
// specifically for exploring different areas of dungeons.
Interaction.newEntry(
  data : {
    name : 'Next Floor',
    id :  'base:next-floor',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      breakpoint();
      if (location.targetLandmark == empty) ::<={
      
        if (location.landmark.floor > 5 && random.number() > 0.5 - (0.2*(location.landmark.floor - 5))) ::<= {
          @:Landmark = import(module:'game_mutator.landmark.mt');
          
          location.targetLandmark = Landmark.new(
            island : location.landmark.island,
            base:Landmark.database.find(id:'base:shrine-lost-floor')
          );
          location.targetLandmark.loadContent();

        } else ::<= {
          @:Landmark = import(module:'game_mutator.landmark.mt');
          
          location.targetLandmark = Landmark.new(
            island : location.landmark.island,
            base:Landmark.database.find(id:location.landmark.base.id),
            floorHint:location.landmark.floor+1
          )
          location.targetLandmark.loadContent();
          
          location.targetLandmark.name = 'Shrine ('+location.targetLandmark.floor+'F)';
        }

        location.targetLandmarkEntry = location.targetLandmark.getRandomEmptyPosition();      
      }

      canvas.clear();
      windowEvent.queueMessage(text:'The party travels to the next floor.', renderable:{render::{canvas.blackout();}});
      
      
      @:instance = import(module:'game_singleton.instance.mt');
      instance.visitLandmark(landmark:location.targetLandmark, where::(landmark) <- location.targetLandmarkEntry);
    },
  }
)  


Interaction.newEntry(
  data : {
    name : 'Climb Up',
    id :  'base:climb-up',
    keepInteractionMenu : false,
    onInteract ::(location, party) {

      windowEvent.queueMessage(text:'The party uses the ladder to climb up to the surface.', renderable:{render::{canvas.blackout();}});
      windowEvent.queueCustom(onEnter::{windowEvent.jumpToTag(name:'VisitIsland');});          
    },
  }
)  



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
          island : location.landmark.island,
          base:Landmark.database.find(id:'base:treasure-room')
        )
        location.targetLandmark.loadContent();
        location.targetLandmarkEntry = location.targetLandmark.getRandomEmptyPosition();
      }
      @:instance = import(module:'game_singleton.instance.mt');

      instance.visitLandmark(landmark:location.targetLandmark, where::(landmark)<-location.targetLandmarkEntry);
      canvas.clear();
    }
  }
)      
      
  
Interaction.newEntry(
  data : {
    name : 'Steal',
    id :  'base:steal',
    keepInteractionMenu : true,
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
      world.accoladeEnable(name:'hasStolen');

      if (location.ownedBy != empty && !location.ownedBy.isIncapacitated()) ::<= {
        when (random.flipCoin()) ::<= {
          windowEvent.queueMessage(
            text: "The stealing goes unnoticed."
          );        
        }
        windowEvent.queueMessage(
          speaker: location.ownedBy.name,
          text: "What do you think you're doing?!"
        );
        windowEvent.queueMessage(
          speaker: location.ownedBy.name,
          text: "Guards!!!"
        );


        @:e = [
          location.landmark.island.newInhabitant(professionHint:'base:guard'),
          location.landmark.island.newInhabitant(professionHint:'base:guard')            
        ];
        
        foreach(e)::(index, guard) {
          guard.equip(
            item:Item.new(
              base:Item.database.find(
                id:'base:halberd'
              ),
              qualityHint:'base:standard',
              materialHint: 'base:mythril',
              rngEnchantHint: true
            ),
            slot: Entity.EQUIP_SLOTS.HAND_R,
            silent:true, 
            inventory:guard.inventory
          );

          guard.equip(
            item:Item.new(
              base: Item.database.find(
                id:'base:plate-armor'
              ),
              qualityHint:'base:standard',
              materialHint: 'base:mythril',
              rngEnchantHint: true
            ),
            slot: Entity.EQUIP_SLOTS.ARMOR,
            silent:true, 
            inventory:guard.inventory
          );
          guard.name = 'Bodyguard ' + (index+1);
        }
        
        e->push(value:location.ownedBy);


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

          }
        );
                  
        if (location.landmark.peaceful) ::<= {
          location.landmark.peaceful = false;
          windowEvent.queueMessage(text:'The people here are now aware of your aggression.');
        }        


      }
      



      location.inventory.remove(item);
      party.inventory.add(item);          
    },
  }
)



Interaction.newEntry(
  data : {
    name : 'Rest',
    id :  'base:rest',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      @level = party.members[0].level;
    
      @:cost = (level * (party.members->keycount)) * 2;
    
      windowEvent.queueAskBoolean(
        prompt: 'Rest for ' + g(g:cost) + '?',
        onChoice::(which) {
          when(which == false) empty;

          when(party.inventory.gold < cost)
            windowEvent.queueMessage(text:'Not enough gold...');

          party.inventory.subtractGold(amount:cost);


          windowEvent.queueMessage(
            text: 'A restful slumber is welcomed...',
            renderable : {
              render::<- canvas.blackout()
            }
          );          



          // get those refreshing 7 hours!
          @:world = import(module:'game_singleton.world.mt');
          {:::} {
            forever ::{
              world.stepTime();
              if (world.time == world.TIME.MORNING)
                send();            
            }
          }

          windowEvent.queueMessage(
            text: 'The party is refreshed.'
          );

          foreach(party.members)::(i, member) {
            member.rest();
          }


        }
      );
    },
  }
)

Interaction.newEntry(
  data : {
    name : 'Change Profession',
    id :  'base:change-profession',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      @:names = [];
      foreach(party.members)::(i, member) {
        names->push(value:member.name);
      }
      
      windowEvent.queueChoices(
        leftWeight: 0.5,
        topWeight: 0.5,
        choices: names,
        prompt: 'Whom?',
        canCancel: true,
        onChoice:::(choice) {

          when(choice == 0) empty;
          
          @:whom = party.members[choice-1];
          @cost = ((whom.level + whom.stats.sum/30)*10)->ceil;

          when(whom.profession.id == location.ownedBy.profession.id)
            windowEvent.queueMessage(
              text: whom.name + ' is already ' + correctA(word:location.ownedBy.profession.name) + '.'
            );
          
          windowEvent.queueMessage(
            text:
              'Profession: ' + location.ownedBy.profession.name + '\n\n' +
              location.ownedBy.profession.description + '\n' +
              'Weapon affinity: ' + Item.database.find(id:location.ownedBy.profession.weaponAffinity).name
          );


          windowEvent.queueMessage(
            text: 'Changing ' + whom.name + "'s profession from " + whom.profession.name + ' to ' + location.ownedBy.profession.name + ' will cost ' + g(g:cost) + '.'

          );

          when(party.inventory.gold < cost)
            windowEvent.queueMessage(
              text: 'The party cannot afford this.'
            );


          windowEvent.queueAskBoolean(
            prompt: 'Continue?',
            onChoice:::(which) {
              when(which == false) empty;
              party.addGoldAnimated(
                amount:-cost,
                onDone::{
                  whom.profession = Profession.find(id: location.ownedBy.profession.id);

                  windowEvent.queueMessage(
                    text: '' + whom.name + " is now " + correctA(word:whom.profession.name) + '.'
                  );                
                }
              );     
            }
          );
        }
      );
    },
  }
)    

Interaction.newEntry(
  data : {
    name : 'Bet',
    id :  'base:bet',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      @:Entity = import(module:'game_class.entity.mt');
      @:getAWeapon = ::(from)<-
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- (
              value.isUnique == false &&
              value.attributes & Item.database.statics.ATTRIBUTE.WEAPON
            )
          )
        )          
      ;
      
      @:generateTeam ::(other){
        @:count = 3;
        @:members = [];

        for(0, count)::(i) {
          @:combatant = location.landmark.island.newInhabitant();
          @:weapon = getAWeapon(from:combatant);
          combatant.equip(item:weapon, slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true, inventory: combatant.inventory);

          members->push(value:combatant);
        }     
        
        @name = 'The ' + Material.getRandom().name + ' ' + getAWeapon().base.name + 's';
        
        // prevent same names from occurring
        if (other != empty && name == other.name) ::<= {
          {:::} {
            forever::{
              when(name != other.name) send();
              name = 'The ' + Material.getRandom().name + ' ' + getAWeapon().base.name + 's';
            }
          }
        }
       
         
        return {
          name : name,
          members : members
        }
      }

      @teamA;
      @teamB;
      @hasChampion = false;
      if (location.data.bet_winningTeam != empty) ::<= {
        hasChampion = true;
        teamA = location.data.bet_winningTeam;
        foreach(location.data.bet_winningTeam.members) ::(k, member) {
          member.heal(amount:100000, silent:true);
          member.healAP(amount:100000, silent:true);
        }   
        location.data.bet_winningTeam = empty;
      } else ::<= {
        teamA = location.data.bet_teamA;
      }

      teamB = location.data.bet_teamB;
      
      
      if (teamA == empty) teamA = generateTeam(:teamB);
      if (teamB == empty) teamB = generateTeam(:teamA);

      location.data.bet_teamA = teamA;
      location.data.bet_teamB = teamB;
        
    



      windowEvent.queueMessage(
        text:'The croud cheers furiously as the teams get ready.'
      );
      
      if (!hasChampion) ::<= {
        windowEvent.queueMessage(
          speaker:'Announcer',
          text:'The next match is about to begin! Here we have "' + teamA.name + '" up against "' + teamB.name + '"! Place your bets!'
        );
      } else ::<= {
        windowEvent.queueMessage(
          speaker:'Announcer',
          text:'The next match is about to begin! Here we have the reigning champions "' + teamA.name + '" up against "' + teamB.name + '"! Place your bets!'
        );      
      }


      windowEvent.queueChoices(
        choices: [
          teamA.name + ' stats',
          teamB.name + ' stats',
          'place bet'
        ],
        canCancel: true,
        keep: true,
        jumpTag: 'Bet',
        onChoice::(choice) {          
          when(choice == 0) empty;
          
          match(choice-1) {
            // team A examine
            (0): ::<= {
              @counter = 0;
              foreach(teamA.members)::(k, member) {
                windowEvent.queueMessage(text:teamA.name + ' - Member ' + (counter+1));
                member.describe();
                counter += 1
              }
            },

            // team B examine
            (1): ::<= {
              @counter = 0;
              foreach(teamB.members)::(k, member) {
                windowEvent.queueMessage(text:teamB.name + ' - Member ' + (counter+1));
                member.describe();
                counter += 1
              }
            },
            
            // bet
            (2): ::<= {
            
              @bet = 0;
              
              @:bets = [
                50,
                100,
                200,
                500,
                2000,
                5000,
                15000,
                50000,
                100000,
                1000000
              ];
              
        
              @:payout ::(isTeamA) {
                when(teamA.members->size == teamB.members->size) bet;
                
                when(isTeamA == true) ::<= {
                  @frac = teamA.members->size / teamB.members->size;
                  return (((1 / frac)**2) * bet)->floor
                }

                @frac = teamB.members->size / teamA.members->size;
                return (((1 / frac)**2) * bet)->floor

              }
                          
              
              @choice = windowEvent.queueChoices(
                prompt: 'Bet how much?',
                choices: [...bets]->map(to:::(value) <- g(g:value)),
                canCancel: true,
                onChoice::(choice) {
                  when(choice == 0) empty;
                  bet = bets[choice-1];
                  
                  when(party.inventory.gold < bet)
                    windowEvent.queueMessage(text:'The party cannot afford this bet.');
                    
                  choice = windowEvent.queueChoices(
                    prompt: 'Bet on which team?',
                    choices: [
                      teamA.name + '(payout: +' + (payout(isTeamA:true)) + ')',
                      teamB.name + '(payout: +' + (payout(isTeamA:false)) + ')'
                    ],
                    canCancel: true,
                    onChoice::(choice) {
                      when(choice == 0) empty;                            
                      @betOnA = choice == 1;
                      
                      @:world = import(module:'game_singleton.world.mt');
                      
                      world.battle.start(
                        party,              
                        allies: teamA.members,
                        enemies: teamB.members,
                        landmark: {},
                        renderable : {
                          render:: {
                            canvas.blackout();                          
                          }
                        },
                        onTurn ::{
                          if (random.number() < 0.7) ::<= {
                            windowEvent.queueMessage(text:random.pickArrayItem(list:[
                              '"YEAH, tear them limb from limb!"',
                              'The croud jeers at team ' + (if (random.number() < 0.5) teamA.name else teamB.name) + '.',  
                              'The croud goes silent.',
                              'The croud goes wild in an uproar.',
                              'The crowd murmurs restlessly.',
                              'The crowd gasps.'
                            ]));
                          }
                        },
                        npcBattle: true,
                        onEnd::(result) {
                          @aWon = {:::} {
                            foreach(result) ::(k ,entity) {
                              foreach(teamA.members) ::(i, member) {
                                if (member == entity) send(message:true);
                              }
                            }
                            return false;
                          }
                        
                          @win = payout(isTeamA:betOnA);
                          if (aWon) ::<= {
                            windowEvent.queueMessage(
                              text: teamA.name + ' wins!'
                            );                  
                            location.data.bet_winningTeam = teamA;
                            foreach(teamA.members) ::(k, member) {
                              when(!member.isIncapacitated()) empty;
                              windowEvent.queueMessage(
                                text:member.name + ' of team ' + teamA.name + ' was carried out of the arena...'
                              );
                              teamA.members->remove(key:teamA.members->findIndex(value:member));
                            }
                          
                          } else ::<= {
                            windowEvent.queueMessage(
                              text: teamB.name + ' wins!'
                            );                  
                            location.data.bet_winningTeam = teamB;
                            foreach(teamB.members) ::(k, member) {
                              when(!member.isIncapacitated()) empty;
                              windowEvent.queueMessage(
                                text:member.name + ' of team ' + teamB.name + ' was carried out of the arena...'
                              );
                              teamB.members->remove(key:teamB.members->findIndex(value:member));
                            }
                          }
                          
                          location.data.bet_teamA = empty;
                          location.data.bet_teamB = empty;
                          
                          
                          
                          // payout
                          if ((betOnA && aWon) || (!betOnA && !aWon)) ::<= {
                            world.accoladeEnable(name:'wonArenaBet');
                            windowEvent.queueMessage(
                              text:'The party won ' + g(g:win) + '.'
                            );                  
                            party.addGoldAnimated(
                              amount:win,
                              onDone::{
                                windowEvent.jumpToTag(name:'Bet', goBeforeTag:true, doResolveNext:true);                            
                              }
                            );
                          } else ::<= {
                            windowEvent.queueMessage(
                              text:'The party lost ' + g(g:bet) + '.'
                            );                  
                            party.addGoldAnimated(
                              amount:-bet,
                              onDone::{
                                windowEvent.jumpToTag(name:'Bet', goBeforeTag:true, doResolveNext:true);                            
                              }
                            );
                          }  
                        }  
                      );                       
                    }
                  );
                }
              );
            }
          }            
        }
      );

      
      
      
      
    
         
    },
    

    
  }
  
  
        
) 
Interaction.newEntry(
  data : {
    name : 'Open Chest',
    id :  'base:open-chest',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');
      when(location.inventory.items->keycount == 0)
        windowEvent.queueMessage(text:'The chest was empty.');
      
      
      world.accoladeIncrement(name:'chestsOpened');      
      windowEvent.queueMessage(text:'The party opened the chest...');
      
      when(location.inventory.items->keycount > world.party.inventory.slotsLeft) ::<= {
        windowEvent.queueMessage(text: '...but the party\'s inventory was too full.');
      }
      
      foreach(location.inventory.items)::(i, item) {
        windowEvent.queueMessage(text:'The party found ' + correctA(word:item.name) + '.');
      }
      
      foreach(location.inventory.items)::(i, item) {
        world.party.inventory.add(item);
      }
      location.inventory.clear();

    
      @:amount = (20 + random.number()*75)->floor;
      windowEvent.queueMessage(text:'The party found ' + g(g:amount) + '.');
      world.party.addGoldAnimated(amount, onDone::{});  

    }
  }
)        

Interaction.newEntry(
  data : {
    name : 'Open Chest',
    id :  'base:open-magic-chest',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');

      windowEvent.queueMessage(text:'The magic chest billows out a murky mist as its opened.');
      windowEvent.queueMessage(text:'The mist is so thick, its hard to see inside of it.');
      windowEvent.queueMessage(text:'It appears to beckon for items to be placed inside. It looks as if theres enough room for 3 items.');

      when (party.inventory.items->size < 3)
        windowEvent.queueMessage(text:'The party hasn\'t 3 items to place inside...');

      
      windowEvent.queueAskBoolean(
        prompt: 'Place items inside?',
        onChoice::(which) {
          when(which == false) empty;
            
          @:pick3 = ::<= {
            @which = [];   
            @dummy = party.inventory.clone();       
            return ::(doAfter) { 
              when (which->size == 3) 
                doAfter(items:which);
                          
              @:pickItem = import(module:'game_function.pickitem.mt');
              pickItem(
                inventory:dummy, 
                canCancel:true,
                topWeight: 0.5,
                leftWeight: 0.5, 
                onGetPrompt::{
                  return 'Pick ' + match(which->size) {
                    (0): '1st',
                    (1): '2nd',
                    (2): '3rd'
                  } + ' item'
                },
                onPick ::(item) {
                  dummy.remove(item);
                  which->push(value:item);
                  pick3(doAfter);
                  windowEvent.jumpToTag(name:'pickItem', doResolveNext: true, goBeforeTag: true);
                }
              ); 
            }
          };
          
          pick3(doAfter::(items) {
            foreach(items)::(index, item) {
              if (item.name->contains(key:'Wyvern Key of'))
                world.accoladeEnable(name:'gotRidOfWyvernKey');    
              
              party.inventory.remove(item);
            }
            @:world = import(module:'game_singleton.world.mt');
            
            windowEvent.queueMessage(text:'After the 3rd item, the chest shines brightly.');
            windowEvent.queueMessage(text:'Something is rising out...');
            
            @:item = Item.new(
              base:Item.database.getRandomFiltered(
                filter:::(value) <- value.isUnique == false && value.canHaveEnchants && value.tier <= world.island.tier+2
              ),
              rngEnchantHint:true
            );
            @message = 'The party received ' + correctA(word:item.name);
            windowEvent.queueMessage(text: message);


            party.inventory.add(item);            
          });
        }                 
      );

    }
  }
)  


Interaction.newEntry(
  data : {
    name : 'Drink Water',
    id :  'base:drink-fountain',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');
      
      windowEvent.queueMessage(text:'The party took turns drinking from the fountain.');
    
      foreach(world.party.members) ::(index, member) {
        if (member.hp < member.stats.HP/2)
          member.heal(amount: member.stats.HP * 0.1);
        if (member.ap < member.stats.AP/2)
          member.healAP(amount: member.stats.AP * 0.1);
      }
      
      
      windowEvent.queueMessage(text:
        random.pickArrayItem(list:[
          'The party feels slightly refreshed.',
          'Everyone was slightly refreshed by the drink.',
          'A welcomed rest for the party.'
        ])
      );
    }
  }
) 

Interaction.newEntry(
  data : {
    name : 'Heal',
    id :  'base:healing-circle',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      when(location.data.used)
        windowEvent.queueMessage(text:'This healing circle is no longer active.');
        
      @:world = import(module:'game_singleton.world.mt');
      
      windowEvent.queueMessage(text:'The party goes within the healing circle.');
    
      foreach(world.party.members) ::(index, member) {
        member.heal(amount: member.stats.HP);
      }
      
      
      windowEvent.queueMessage(text:
        random.pickArrayItem(list:[
          'The party feels refreshed.',
          'A welcomed rest for the party.'
        ])
      );
      location.data.used = true;
    }
  }
) 


Interaction.newEntry(
  data : {
    name : 'Approach',
    id :  'base:pray-statue',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');


      @whom;
      @:approach = :: {
        windowEvent.queueMessage(text:whom.name + ' approaches the wyvern statue slowly.');        
        windowEvent.queueMessage(text:'They feel an energy, an aura from it...');        
        windowEvent.queueMessage(text:'It\'s as if the statue calls for them. Calling for judgement...');        
        windowEvent.queueAskBoolean(
          prompt: 'Place hand on statue?',
          onChoice::(which) {
            when(which == false) empty;

            windowEvent.queueMessage(text:whom.name + ' places their hand on the statue.');        
            
            // already exhausted
            when(location.data.hasPrayer == false) ::<= {
              windowEvent.queueMessage(text:'Nothing happens.');        
            }
            
            location.data.hasPrayer = false;
            windowEvent.queueMessage(text:'After a moment of silence, the statue hums gently.');        
            
            @:statChoices = [
              'HP',
              'AP',
              'ATK',
              'INT',
              'DEF',
              'LUK',
              'SPD',
              'DEX'
            ];

            // Good!
            when(random.flipCoin()) ::<= {
              windowEvent.queueMessage(text: 'The statue glows along with ' + whom.name + '.');
              windowEvent.queueMessage(text: whom.name + ' is met with a blessing.');
              
              
              windowEvent.queueChoices(
                choices: [...statChoices]->map(to:::(value) <- value + ' (' + whom.stats.save()[value] + ')'),
                prompt: 'Pick a base stat to improve.',
                canCancel : false,
                onChoice::(choice) {
                  @:oldStats = StatSet.new();
                  oldStats.load(serialized:whom.stats.save());
                  @:newState = whom.stats.save();
                  newState[statChoices[choice-1]] += 3;
                  whom.stats.load(serialized:newState);
                  
                  oldStats.printDiff(
                    other:whom.stats,
                    prompt: 'New stats: ' + whom.name
                  );
                }
              );

            };    



            
            // bad!        
            windowEvent.queueMessage(text: 'The statue glows along with ' + whom.name + '.');
            windowEvent.queueMessage(text: whom.name + ' is met with a sudden burst of malevolent energy.');

            @:Entity = import(module:'game_class.entity.mt');
            @:Damage = import(module:'game_class.damage.mt');

            @:statue = location.landmark.island.newInhabitant();
            statue.name = 'the Wyvern Statue';
            @:landed = whom.damage(
              attacker: statue,
              damage: Damage.new(
                amount: 1,
                damageType: Damage.TYPE.NEUTRAL,
                damageClass: Damage.CLASS.HP
              ),
              dodgeable : true,
              critical : false
            );
            
            if (landed) ::<= {

              windowEvent.queueMessage(text: whom.name + ' is met with a curse.');

              @:oldStats = StatSet.new();
              oldStats.load(serialized:whom.stats.save());
              @:newState = {...whom.stats.save()};
              @:stat = random.pickArrayItem(list:statChoices);
              newState[stat] -= 2;
              if (newState[stat] < 1)
                newState[stat] = 1;
                
              whom.stats.load(serialized:newState);
                
              oldStats.printDiff(
                other:whom.stats,
                prompt: whom.name + ': No...'
              );
            }

          }
        );
      }

      windowEvent.queueMessage(text:'Who approaches the statue?');
      @:choices = [...world.party.members]->map(to:::(value) <- value.name);
      windowEvent.queueChoices(
        choices,
        prompt: 'Pick someone.',
        canCancel: true,
        onChoice::(choice) {
          when(choice == 0) empty;
          whom = world.party.members[choice-1];
          
          approach();
        }
      )
    }
  }
) 

Interaction.newEntry(
  data : {
    name : 'Enchant',
    id :  'base:enchant-once',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');
      
      when(location.data.enchant == empty) ::<= {
        windowEvent.queueMessage(text:'The enchant stand doesnt seem to be active anymore.');        
      };

      windowEvent.queueMessage(text:'The stand lights up as you approach.');        
      windowEvent.queueMessage(text:'The runes appear before you, but you cannot read them.');        
      windowEvent.queueMessage(text:'An abstract thought appears in your mind. It seems like this will enchant a single item.');        
      windowEvent.queueMessage(text:'The stand grants the enchantment: ' + location.data.enchant.name + ', which will add the following description to an item: "' + location.data.enchant.description +'"');        


      @:isStatBased = !location.data.enchant.base.equipMod.isEmpty;

      if (isStatBased)
        windowEvent.queueMessage(
          speaker:location.data.enchant.name + ' - Enchant Stats',
          text:String.combine(:location.data.enchant.base.equipMod.descriptionRateLines->map(::(value) <- value + '\n')),
          pageAfter:canvas.height-4
        );
        
        
      windowEvent.queueAskBoolean(
        prompt: 'Enchant?',
        onChoice::(which) {
          when(!which) empty;
          
          @:pickItem = import(module:'game_function.pickpartyitem.mt');
          pickItem(
            canCancel:true, 
            onGetPrompt::{
              return 'Enchant which?'
            },
            topWeight : 0.5,
            leftWeight : 0.5,
            filter::(item) <-
              item.base.canHaveEnchants &&
              item.enchantsCount < item.base.enchantLimit
            ,
            onPick::(item) {
              when(item == empty) empty;
              windowEvent.queueMessage(text:'This will add the enchant ' + location.data.enchant.name + ' to the ' + item.name + '. This change is permanent.');
              windowEvent.queueAskBoolean(
                prompt: 'Continue?',
                onChoice::(which) {
                  when(which == false) empty;
                  world.accoladeIncrement(name:'enchantmentsReceived');
                  windowEvent.queueMessage(text:'The stand glows along with the item for a time before returning to normal.');
                  @:whom = item.equippedBy;
                  @oldStats;
                  @slot
                  if (whom != empty) ::<= {
                    oldStats = StatSet.new(state:whom.stats.save());
                    slot = whom.unequipItem(item, silent:true);
                  }
                  item.addEnchant(mod:location.data.enchant);
                  location.data.enchant = empty;
                  if (whom != empty) ::<= {
                    whom.equip(item, slot, silent:true);
                    if (isStatBased)
                      oldStats.printDiff(prompt: whom.name + ': enchanted ' + item.name, other:whom.stats);
                  }                  
                  windowEvent.jumpToTag(name:'pickItem', goBeforeTag: true, doResolveNext:true);
                }
              );
            }
          );          
        }
      );      

    }
  }
) 

Interaction.newEntry(
  data : {
    name : 'Loot',
    id :  'base:loot',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');
      when(location.inventory.items->keycount == 0)
        windowEvent.queueMessage(text:location.ownedBy.name + '\'s body contained no items');
      
      windowEvent.queueMessage(text:'The party looted the body...');
      
      when(world.party.inventory.isFull) ::<= {
        windowEvent.queueMessage(text: '...but the party\'s inventory was full.');
      }
      
      foreach(location.inventory.items)::(i, item) {
        windowEvent.queueMessage(text:'The party found ' + correctA(word:item.name) + '.');
      }
      
      foreach(location.inventory.items)::(i, item) {
        world.party.inventory.add(item);
      }
      location.inventory.clear();
    }
  }
) 

Interaction.newEntry(
  data : {
    name : 'Take',
    id :  'base:take',
    keepInteractionMenu : false,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');
            
      when(world.party.inventory.isFull) ::<= {
        windowEvent.queueMessage(text: '...but the party\'s inventory was full.');
      }
      
      foreach(location.inventory.items)::(i, item) {
        windowEvent.queueMessage(text:'The party found ' + correctA(word:item.name) + '.');
      }
      
      foreach(location.inventory.items)::(i, item) {
        world.party.inventory.add(item);
      }
      location.inventory.clear();
      location.landmark.removeLocation(:location);
    }
  }
) 


Interaction.newEntry(
  data : {
    name : 'Quest Guild...',
    id :  'base:quest-guild',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      import(:'game_function.questguild.mt')(location, party);
    }
  }
) 



Interaction.newEntry(
  data : {
    name : 'Compete',
    id :  'base:compete',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
    }
  }
)

/*
Interaction.newEntry(
  data : {
    name : 'Rune Research',
    id :  'base:sylvia-research',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');

      when(world.storyFlags.data_locationsDiscovered <
         world.storyFlags.data_locationsNeeded) ::<= {
        when (world.storyFlags.data_locationsDiscovered == 0)
          windowEvent.queueMessage(speaker:'Sylvia', text: '"Don\'t forget to visit new locations with the runestone!"');

        windowEvent.queueMessage(speaker:'Sylvia', text: '"Hmmm according to the stone, I still need ' + (world.storyFlags.data_locationsNeeded - world.storyFlags.data_locationsDiscovered) + ' rune samples."');
      }
    }
  }
)  
 
Interaction.newEntry(
  data : {
    name : 'Tablet Trading',
    id :  'base:sylvia-tablet',
    keepInteractionMenu : true,
    onInteract ::(location, party) {
      @:world = import(module:'game_singleton.world.mt');
      @:tablets = world.party.inventory.items->filter(by:::(value) <- value.base.name->contains(key:'Tablet ('));
      
      when (tablets->keycount == 0) ::<= {
        windowEvent.queueMessage(speaker: 'Sylvia', text: '"No tablets, eh? They are pretty hard to come across. I\'ll be here for you when you have any though!"');
      }
      
      @:tabletNames = [...tablets]->map(to:::(value) <- value.name);
      @choice = windowEvent.queueChoicesNow(
        choices : tabletNames,
        prompt: 'Give which?',
        canCancel : true
      );
      when(choice == 0) empty;
      @:tablet = tablets[choice-1];
      
      when(windowEvent.queueAskBoolean(
        prompt: 'Give the ' + tablet.name + '?'
      ) == false) empty;
      
      world.party.inventory.remove(item:tablet);
      windowEvent.queueMessage(speaker: 'Sylvia', text: 'Let\'s see what this one says...');
      @item;
      
      
      match(tablet.name) {
        ('Tablet (Green)')::<= { 
        windowEvent.queueMessage(speaker: 'Sylvia', text: 
          random.pickArrayItem(list: [
            '"Seems to be a personal journal. It\'s stuff like this that reminds me how little we know about the day-to-day"',
            '"It\'s a .... shopping list? Wait no that can\'t be right.."',
            '"Some sort of ledger it seems like."',
            '"An inventory listing of some sort."',
          ])
        );
        
        windowEvent.queueMessage(speaker: 'Sylvia', text: '"Here! Thanks again."');
        item = Item.database.getRandomFiltered(filter:::(value) <- 
          value.name->contains(key:' Potion') ||
          value.name->contains(key:'Ingot')
        );
        },


        ('Tablet (Orange)')::<= {
        windowEvent.queueMessage(speaker: 'Sylvia', text: 
          random.pickArrayItem(list: [
            '"Seems to be a historical recounting, or some sort of official record..."',
          ])
        );
        
        windowEvent.queueMessage(speaker: 'Sylvia', text: '"Here! Thanks again."');
        item = Item.database.getRandomFiltered(filter:::(value) <- 
          value.attributes & Item.database.statics.ATTRIBUTE.WEAPON &&
          !value.isUnique
        );
        },


        ('Tablet (Red)')::<= {
        windowEvent.queueMessage(speaker: 'Sylvia', text: 
          random.pickArrayItem(list: [
            '"Oh wow. It seems to be some sort of religious text.."',
          ])
        );
        
        windowEvent.queueMessage(speaker: 'Sylvia', text: '"Here! Thanks again."');
        item = Item.database.getRandomFiltered(filter:::(value) <- 
          (value.attributes & Item.database.statics.ATTRIBUTE.WEAPON ||
           value.equipType == Item.database.statics.TYPE.RING ||
           value.equipType == Item.database.statics.TYPE.TRINKET) &&
          value.isUnique
        );
        }            
      
      }

      item = Item.new(base:item);          
      world.party.inventory.add(item);
      windowEvent.queueMessage(speaker:'', text:'The party received ' + correctA(word:item.name) + '!');
      
      
      
      
      
      
      
    }
  }
)    
*/
}

@:Interaction = Database.new(
  name : 'Wyvern.Interaction',
  attributes : {
    name : String,
    id : String,
    name : String,
    onInteract : Function,
    keepInteractionMenu : Boolean
  },
  reset
);     
    

return Interaction;
