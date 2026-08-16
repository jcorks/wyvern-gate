@:WyvernGate = import(:'wyvern-gate.mt');

@:Scene = WyvernGate.Scene
@:ParticleEmitter = WyvernGate.Core.Graphics.Particle
@:random = WyvernGate.Core.Random
@:windowEvent = WyvernGate.Core.WindowEvent
@:Item = WyvernGate.Item
@:canvas = WyvernGate.Core.Graphics.Canvas
@:StatSet = WyvernGate.Util.StatSet
@:Landmark = WyvernGate.Map.Landmark

return ::{
  @:etherealEmitter = ParticleEmitter.new(
    directionMin : 0,
    directionMax : 360,

    directionDeltaMin : 1,
    directionDeltaMax : 3,

    speedMin : 0.2,
    speedMax : 0.55,
    
    speedDeltaMin : -.003,
    speedDeltaMax : -.008,

    characters : ['O', 'O', 'O', '0', '0', 'o', 'o', ',', ',', ',' , '.', '.', '.'],
    charactersRepeat : false,
    
    lifeMax : 30,
    lifeMin : 10
  );

  Scene.newEntry(
    data : {
      id : 'thechosen:scene_intro',
      script: [
        /*
        ::(location, landmark, doNext) {
          etherealEmitter.move(
            x : canvas.width / 2,
            y : canvas.height / 2
          );
          etherealEmitter.start(:2);    
          
          
          @counter = 0;
          etherealEmitter.onFrame = ::{
            counter += 1;
            if (counter == 1000) ::<= {
              breakpoint();
              doNext();
            }
          }
          
          
        },
        */
        ['???', '...You.. you have been chosen...', {topWeight:1}],
        ['???', 'Among those of the world, the Chosen are selected...', {topWeight:1}],
        ['???', '...Selected to seek me, the Wyvern of Light...', {topWeight:1}],
        ['???', 'If you seek me, I will grant you and anyone with you a wish...', {topWeight:1}],
        ['???', 'But be warned: others will seek their own wish and will accept no others...', {topWeight:1}],
        ['???', 'Come, Chosen: take this Key and seek me among the islands in the sky...', {topWeight:1}],
        ['???', '...I will await you, Chosen...', {topWeight:1}],
        /*
        ::(location, landmark, doNext) {
          etherealEmitter.stop();
          etherealEmitter.onDone = ::{
            breakpoint();
            doNext();
          }
        }
        */
      ]
    }
  )   

  Scene.newEntry(
    data : {
      id : 'thechosen:scene_intro_changeling',
      script: [
        ['???', '...You.. you are different.'],
        ['???', 'It is as if you were not meant to be, yet you are here...'],
        ['???', 'There is a great power within you.. I feel it. I can see it as clear as Sol.'],
        ['???', 'Despite it all, you are here. And now, you are a Chosen.'],
        ['???', '...Come... seek me, the Wyvern of Light...'],
        ['???', 'If you seek me, I will grant you and anyone with you a wish...'],
        ['???', 'But be warned: others will seek their own wish and will accept no others...'],
        ['???', 'Come, Chosen: take this Key and seek me among the islands in the sky...'],
        ['???', '...I will await you, Chosen...'],
      ]
    }
  )   

  @:perfectLearning ::{
    @:world = import(module:'base/world.mt');

    world.party.members[0].addEffect(from:world.party.members[0], id: 'base:learn-arts-perfect', durationTurns:1);
  }



  Scene.newEntry(
    data : {
      id: 'thechosen:scene_prewyvernbattle0',
      script: [
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          
          @chance = random.number(); 
          @:island = landmark.island;   
          @:party = world.party;
          @enemies = [];
          
          
          for(0, match(island.tier) {
            (0): 1,
            (1): 2,
            default: 3
          })::(i) {
            @:enemy = island.newAggressor();
            enemy.inventory.clear();
            enemy.anonymize();
            enemies->push(value:enemy);
          }
          
          @:boss = enemies[1];

          windowEvent.queueMessage(
            speaker: '???',
            text: random.pickArrayItem(list:[
              'Well, well, well. Look who else is going to the Wyvern. Get \'em!',
              'Get out of here, the wish is ours!',
              'Wait, no! The wish is ours! Get out of here!',
              'We will fight for that wish to the death!',
              'The wish is ours! We are the real Chosen!'
            ])
          );
          
          

          
          @:battleStart = ::{
            world.battle.start(
              party,

              allies: party.members,
              enemies,
              exp:true,
              landmark: {},
              onStart :: {
              },
              onEnd ::(result) {
                when(world.battle.partyWon()) empty;
                  
                @:instance = import(module:'base/instance.mt');
                instance.gameOver(reason:'The party was wiped out.');
              }
            );
          }
          battleStart();      
        }      
      ]  
    }
  )



  Scene.newEntry(
    data : {
      id : 'thechosen:scene_wyvernfire0',
      script: [
        //      "(comes   again    one  new)  Another new one comes..."
        ['???',    '"Juhrruhlo-rrohsharr naan djaashaarr ..."'],
        ['???',    'Zaaluh-shol, welcome... to my domain. You have done well to get here.'],
        ['???',    'You have been summoned, but not by me. My sibling is the one who calls for you.'],
        ['???',    'But to get to them, I must evaluate you to see if you are truly worthy of seeing the Wyvern of Light.'],
        ['Kaedjaal', 'My name is Kaedjaal, and my domain is that of flame. I enjoy a summer\'s day as much as the next, but I\'ll be honest with you; I take it a step further.'],
        ['Kaedjaal', 'Dancing in the fire, my test looks inward: your will, your determination, what moves you.'],
        ['Kaedjaal', 'Chosen, can you stand my flames? Can you triumph over uncertain and, at times, unfair odds? Show me your power.'],
        ['Kaedjaal', 'Come forth.'],
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          @:Battle = import(module:'base/battle.mt');
          @:canvas = import(module:'core/graphics/canvas.mt');
          location.ownedBy.name = 'Kaedjaal, Wyvern of Fire';
          @:end = ::(result){

            when(world.battle.partyWon() == false) ::<= {
              windowEvent.queueMessage(
                speaker:'Kaedjaal',
                text:'Perhaps it was not meant to be...'
              );
              
              windowEvent.queueCustom(
                onEnter::{
                  @:instance = import(module:'base/instance.mt');
                  instance.gameOver(reason:'The party was wiped out.');
                }
              );
            }
            when(world.party.isMember(:location.ownedBy)) ::<= {
              location.ownedBy = empty;
              doNext();
            }
          
            when (!location.ownedBy.isIncapacitated()) ::<= {
              world.battle.start(
                party: world.party,              
                allies: world.party.members,
                enemies: [location.ownedBy],
                landmark: landmark,
                renderable:{render::{canvas.fill();}},
                onEnd::(result) {
                  end(result);
                }
              );                
            } 
            
            doNext();
          }
          world.battle.start(
            party:world.party,              
            allies: world.party.members,
            enemies: [location.ownedBy],
            landmark: landmark,
            renderable:{render::{canvas.fill();}},
            onEnd::(result) {
              end(result);
            }
          );             
        },
        ['Kaedjaal', 'Ha ha ha, splendid! Chosen, that was excellent. You have shown how well you can handle yourself.'],
        ['Kaedjaal', 'However, be cautious: you are not the first to have triumphed over me.'],
        ['Kaedjaal', 'There are many with their own goals and ambitions, and some will be more skilled than you currently are.'],
        ['Kaedjaal', 'The special Key which you have received... I will give you another where you may find the next shrine.'],
        ['', 'The party received The Wyvern Key of Ice.'],     
        ['Kaedjaal', 'Oh! Actually, I\'d like you to have this other key as well, as a thanks for agreeing to start this journey.'],
        ['', 'The party received a normal key.'],     
        ['Kaedjaal', 'Visiting other mortal islands can help you find more to help you along your journey... But, it may be treacherous. Be prepared.'],
        ['Kaedjaal', 'Ah, one more thing. Let me impart this to you, as a prize for getting this far'],
        ['', 'The party received a Knowledge Stone.'],     
        ['Kaedjaal', 'You may find this useful for learning new Arts through combat.'],
        ['Kaedjaal', '...'],
        ['Kaedjaal', 'I suppose it is now time to return you. '],
        ['Kaedjaal', 'I hope you enjoyed this little visit. Come and see me any time.'],
        ['', 'Kaedjaal glows.'],
        ['Kaedjaal', 'May you find peace and prosperity in your heart. Remember: seek the shrines with this new Key. We\'ll be waiting.'],
        ::(location, landmark, doNext) {
          if (location.ownedBy)
            location.ownedBy.name = 'Kaedjaal, Wyvern of Fire';
          @:world = import(module:'base/world.mt');
          world.scenario.data.fireWyvernDefeated = true;
          @keyother = Item.new(
            base: Item.database.find(id:'thechosen:wyvern-key-of-ice')
          );
          world.party.inventory.add(:keyother);

          keyother = Item.new(
            base: Item.database.find(id:'base:wyvern-key'),
            creationHint : {
              tier : 1
            }
          );
          world.party.inventory.add(:keyother);

          /*
          keyother = Item.new(
            base: Item.database.find(id:'base:knowledge-stone')
          );
          world.party.inventory.add(:keyother);
          */
          instance.unlockScenarios();
          instance.unlockSeeds();



          windowEvent.queueMessage(
            renderable:{render::{canvas.fill();}},
            text: 'You are teleported away...'
          );
          @:instance = import(module:'base/instance.mt');
          windowEvent.queueCustom(onEnter::{

            world.island.travel();
          });            
        }
      ]
    }
  ) 

  Scene.newEntry(
    data : {
      id : 'thechosen:scene_wyvernfire1',
      script: [
        ['Kaedjaal', 'Rrohziil shaa jiin, you have come to check on me, eh?'],
        ['Kaedjaal', 'Welcome back to my domain, Chosen. I am happy that you have returned.'],
        ['Kaedjaal', 'Perhaps you are interested in a trade? I have a habit of collecting trinkets.'],
        ['Kaedjaal', 'If you give me 3 items, I will give you 1 item from my hoard.'],
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          world.accoladeEnable(name:'wyvernsRevisited');
          windowEvent.queueAskBoolean(
            prompt:'Trade?',
            onChoice::(which) {
              when(which == false) ::<= {
                windowEvent.queueMessage(speaker:'Kaedjaal', text:'Ah I see. That is understandable. I will still be here if you change your mind.');
                windowEvent.queueCustom(
                  onEnter::{},
                  onLeave::{doNext();}                  
                );
              }


              when(world.party.inventory.items->keycount < 3) ::<= {
                windowEvent.queueMessage(speaker:'Kaedjaal', text:'Djiiroshuhzolii, Chosen. You have not enough items to complete a trade.');
                windowEvent.queueCustom(
                  onEnter::{},
                  onLeave::{doNext();}                  
                );
              }

              
              
              @items = [];
              @runOnce = false;
              @chooseItem = ::(item) {
                @:cancelTrade = ::{
                   // re-add the items
                  foreach(items)::(i, item) {
                    world.party.inventory.add(item);
                  }
                  // cancelled by user
                  windowEvent.queueMessage(speaker:'Kaedjaal', text:'Having second thoughts? No matter. I will still be here if you change your mind.');  
                  windowEvent.queueCustom(
                    onEnter::{},
                    onLeave::{doNext();}                  
                  );              
                }

                when (item == empty && runOnce) ::<= {
                  cancelTrade();
                }
                if (item != empty) ::<= {
                  if (item.base.id == 'thechosen:wyvern-key-of-fire') ::<= {
                    windowEvent.queueMessage(speaker:'Kaedjaal', text:'Rrohziil, you... cannot trade me with the Key of Fire. You need that to leave here.');
                  } else ::<= {
                    items->push(value:item);
                    world.party.inventory.remove(item);                  
                  }
                }
                
                when(items->keycount == 3) ::<= {
                
                  windowEvent.queueAskBoolean(
                    prompt: 'Trade items?',
                    onChoice::(which) {
                      when(which == false) cancelTrade();

                      windowEvent.queueMessage(speaker:'Kaedjaal', text:'Excellent. Let me, in exchange, give you this.');   
                      @:item = Item.new(
                        base:Item.database.getRandomFiltered(
                          filter:::(value) <- 
                              value.hasNoTrait(:Item.TRAIT.UNIQUE) && 
                              value.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS | Item.TRAIT.METAL)
                        ),
                        rngEnchantHint:true, 
                        colorHint:'base:red', 
                        materialHint: 'base:gold',
                        forceSlotCount: 2
                      );
                      item.enchantLimit = 10;
                      @:ItemEnchant = import(module:'base/item/enchant.mt');
                      item.addEnchant(mod:ItemEnchant.new(), force:true);
                      item.addEnchant(mod:ItemEnchant.new(), force:true);
                      item.addEnchant(mod:ItemEnchant.new(), force:true);
                      item.addEnchant(mod:ItemEnchant.new(), force:true);
                      item.addEnchant(mod:ItemEnchant.new(), force:true);

                      windowEvent.queueMessage(text:'In exchange, the party was given ' + WyvernGate.Util.CorrectA(word:item.name) + '.');
                      world.party.inventory.add(item);
                      
                      windowEvent.queueMessage(speaker:'Kaedjaal', text:'Would you like to trade once more?');
                      windowEvent.queueAskBoolean(
                        prompt:'Trade again?',
                        onChoice::(which) {
                          when(which) ::<= {
                            runOnce = false;
                            items = [];
                            chooseItem();
                          }
                          doNext();
                        }
                      );                    
                    }
                  )
                }
                
                
                
                @:pickitem = import(module:'base/widgets/pickitem.mt');
                runOnce = true;
                pickitem(
                  inventory: world.party.inventory,
                  leftWeight: 0.5,
                  topWeight: 0.5,
                  canCancel:false,
                  keep:false,
                  prompt: 'Pick the ' + (match(items->keycount) {
                        (0): 'first',
                        (1): 'second',
                        (2): 'third'
                      }) + ' item.',
                  onPick:::(item){
                    chooseItem(item);
                  }
                );
              }
              chooseItem();
            }
          );
          
        },
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          windowEvent.queueMessage(
            speaker:'Kaedjaal', 
            text:'Now, would you like me to teleport you back?'
          );
          
          windowEvent.queueAskBoolean(
            prompt: 'Leave?',
            onChoice::(which) {
              windowEvent.queueMessage(
                text: 'Kaedjaal glows.'
              );                

              windowEvent.queueMessage(
                speaker:'Kaedjaal', 
                 //  (world  wish[verb] travel[noun, pl] swift prosperous)   -> The World wishes travels swift and prosperous -> May your travels be swift and properous
                text:'Zaashael kaaluh-lo zohssuh-zodjii shiirr kohggaelaarr...'
              );                
              windowEvent.queueMessage(
                renderable:{render::{canvas.fill();}},
                text: 'You are teleported away...'
              );

              windowEvent.queueCustom(onEnter::{
                world.island.travel();                
              });            
            }
          );
        }
      ]
    }
  )


  Scene.newEntry(
    data : {
      id : 'thechosen:scene_wyvernice0',
      script: [
        ['???',    '...'],
        ['???', '... Another Chosen, or so you would be called.'],
        ['???', 'Why my sibling wastes our time with some of these karrjuhzaalii is a mystery to me.'],
        ['???', 'But with me, your journey may end here. I will not let you pass unless you earn it.'],
        ['???', 'I will not be as easy-going as Kaedjaal.'],
        ['???', 'Through the unforgiving cold and ice, you will understand the power which you challenge.'],
        ['Ziikaettaal', 'I, Ziikaettaal will halt your path now, Chosen!'],
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          @:Battle = import(module:'base/battle.mt');
          @:canvas = import(module:'core/graphics/canvas.mt');
          location.ownedBy.name = 'Ziikaettaal, Wyvern of Ice';
          @:end = ::(result){

            when(world.battle.partyWon() == false) ::<= {
              windowEvent.queueMessage(
                speaker:'Ziikaettaal',
                text:'Hm. As expected.'
              );
              
              windowEvent.queueCustom(
                onEnter::{
                  @:instance = import(module:'base/instance.mt');
                  instance.gameOver(reason:'The party was wiped out.');
                }
              );
            }

            when(world.party.isMember(:location.ownedBy)) ::<= {
              location.ownedBy = empty;
              doNext();
              
            }
            
          
            when (!location.ownedBy.isIncapacitated()) ::<= {
              world.battle.start(
                party: world.party,              
                allies: world.party.members,
                enemies: [location.ownedBy],
                landmark: landmark,
                renderable:{render::{canvas.fill();}},
                onEnd::(result) {
                  end(result);
                }
              );                
            } 
            
            doNext();
          }
          world.battle.start(
            party:world.party,              
            allies: world.party.members,
            enemies: [location.ownedBy],
            landmark: landmark,
            renderable:{render::{canvas.fill();}},
            onEnd::(result) {
              end(result);
            }
          );             
        },
        ['Ziikaettaal', 'I... I see. Kaedjaal was perhaps right to let you continue.'],
        ['Ziikaettaal', 'It has been some time since I have let another Chosen pass.'],
        ['Ziikaettaal', 'You have handled yourself well.'],
        ['Ziikaettaal', 'The special Keys you have been receiving... I will give you another where you may find the next shrine.'],
        ['', 'The party received The Wyvern Key of Thunder.'],          
        ['Ziikaettaal', 'Ah, of course. Maybe it is only fair to give you something in return for getting this far.'],
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          windowEvent.queueMessage(
            text: 'Ziikaettaal gently taps ' + world.party.members[0].name + ' on the head.'
          );
          perfectLearning();
          
          windowEvent.queueCustom(
            onLeave ::{
              doNext();
            }
          );
        },
        ['Ziikaettaal', 'I suppose it is now time to return you. '],
        ['', 'Ziikaettaal glows.'],
        ['Ziikaettaal', 'Chosen, the road ahead is still dangerous. Remember: seek the shrines with this new Key. We\'ll be waiting.'],
        ::(location, landmark, doNext) {
          if (location.ownedBy)
            location.ownedBy.name = 'Ziikaettaal, Wyvern of Ice';
          @:world = import(module:'base/world.mt');
          world.scenario.data.fireWyvernDefeated = true;
          @:keyother = Item.new(
            base: Item.database.find(id:'thechosen:wyvern-key-of-thunder')
          );
          world.party.inventory.add(:keyother);
          windowEvent.queueMessage(
            renderable:{render::{canvas.fill();}},
            text: 'You are teleported away...'
          );
          @:instance = import(module:'base/instance.mt');
          windowEvent.queueCustom(onEnter::{
            world.island.travel();                
          });            
        }
      ]
    }
  ) 

  Scene.newEntry(
    data : {
      id : 'thechosen:scene_wyvernice1',
      script: [
        ['Ziikaettaal', 'You.. You have returned.'],
        ['Ziikaettaal', 'Seeing as you have so much time on your hands, how about a little game.'],
        ['Ziikaettaal', 'You see, I have a bit of a penchant for... gambling.'],
        ['Ziikaettaal', 'Wager against me. If you lose, you hand me 500G. If you win, you get a weapon from my hoard.'],
        ['Ziikaettaal', 'I assure you, my weapons are well worth it.'],
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          world.accoladeEnable(name:'wyvernsRevisited');
          @:party = world.party;
          windowEvent.queueAskBoolean(
            prompt: 'Play dice with Ziikaettaal?',
            onChoice::(which) {
              when(which == false) doNext();
              
              when (party.inventory.gold < 500) ::<= {
                windowEvent.queueMessage(
                  speaker: 'Ziikaettaal',
                  text: 'You do not have enough to bet with me. Come back when you are... blessed with more riches.',
                  onLeave:doNext
                );
              }
              
              
              windowEvent.queueMessage(
                speaker: 'Ziikaettaal',
                text: 'Prepare yourself.',
                onLeave::{
                  @:dice = import(module:'base/gambling/dice.mt');
                  dice(
                    onFinish::(partyWins) {
                    
                      windowEvent.queueMessage(
                        text:(if (partyWins) 'The party' else 'Ziikaettaal') + ' wins!'
                      );
                    
                      if (partyWins) ::<= {
                        world.accoladeEnable(name:'wonGamblingGame');
                        windowEvent.queueMessage(
                          speaker: 'Ziikaettaal',
                             //Curse     earth  you     -> **** you
                          text: '"kiikohluh zaashael kaajiin..."'
                        );                        
                        windowEvent.queueMessage(
                          speaker: 'Ziikaettaal',
                          text: 'You win. Well played.'
                        );                
                        
                        @:prize = Item.new(
                          base: Item.database.getRandomFiltered(
                            filter:::(value) <- 
                              value.hasNoTrait(:Item.TRAIT.UNIQUE) && 
                              value.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS | Item.TRAIT.METAL | Item.TRAIT.WEAPON)
                          ),
                          rngEnchantHint:true, 
                          colorHint:'base:blue', 
                          materialHint:'base:mythril', 
                          qualityHint:'base:masterwork',
                          forceSlotCount: 3
                        );
                        @:ItemEnchant = import(module:'base/item/enchant.mt');
                        prize.enchantLimit = 12;
                        prize.addEnchant(mod:ItemEnchant.new(), force:true);
                        prize.addEnchant(mod:ItemEnchant.new(), force:true);
                        prize.addEnchant(mod:ItemEnchant.new(), force:true);
                        prize.addEnchant(mod:ItemEnchant.new(), force:true);
                        prize.addEnchant(mod:ItemEnchant.new(), force:true);
                        prize.addEnchant(mod:ItemEnchant.new(), force:true);
                        prize.addEnchant(mod:ItemEnchant.new(), force:true);


                        party.inventory.add(item:prize);
                        windowEvent.queueMessage(text:'The party was given a ' + prize.name + '.',
                          onLeave:doNext
                        );
                        
                      } else ::<= {
                        windowEvent.queueMessage(
                          speaker: 'Ziikaettaal',
                          text: 'Too bad! Maybe another time. Ha ha...'
                        );                
                        party.inventory.subtractGold(amount:500);
                        windowEvent.queueMessage(text:'The party lost 500G.',
                          onLeave:doNext
                        );
                      }
                      
                    }
                  );   
                }
              );          
              
              
            }
          );
          
        },
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          windowEvent.queueMessage(
            speaker:'Ziikaettaal', 
            text:'Now, would you like me to teleport you back?'
          );
          
          windowEvent.queueAskBoolean(
            prompt: 'Leave?',
            onChoice::(which) {
              windowEvent.queueMessage(
                text: 'Ziikaettaal glows.'
              );                

              windowEvent.queueMessage(
                renderable:{render::{canvas.fill();}},
                text: 'You are teleported away...'
              );

              windowEvent.queueCustom(onEnter::{
                world.island.travel();                
              });            
            }
          );
        }
      ]
    }
  )


  Scene.newEntry(
    data : {
      id : 'thechosen:scene_wyvernthunder0',
      script: [
        ['???', '...'],
        ['???', 'Ah, ssuh-sho-zaaluh naan. Excellent.'],
        ['???', 'As we wait, we begin to wonder if someone will show with enough shiikohl to surpass us.'],
        ['???', 'Yet as time passes, more of you come. Some quite formiddable too.'],
        ['???', 'What is it you seek? Is it just a wish, or something more? A test of your own growth?'],
        ['???', 'Regardless, you come before me, Juhriikaal, in hopes to get to the Wyvern of Light.'],
        ['Juhriikaal', 'Congratulations on getting this far. Just blind luck will not get you past me.'],
        ['Juhriikaal', 'You will find my electrifying methods to be a little less forgiving than my siblings.'],
        ['Juhriikaal', 'Prepare yourself, Chosen!'],
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          @:Battle = import(module:'base/battle.mt');
          @:canvas = import(module:'core/graphics/canvas.mt');
          location.ownedBy.name = 'Juhriikaal, Wyvern of Thunder';
          @:end = ::(result){

            when(world.battle.partyWon() == false) ::<= {
              windowEvent.queueMessage(
                speaker:'Juhriikaal',
                text:'"Djiirohshuhlo jiin."'
              );
              
              windowEvent.queueCustom(
                onEnter::{
                  @:instance = import(module:'base/instance.mt');
                  instance.gameOver(reason:'The party was wiped out.');
                }
              );
            }

            when(world.party.isMember(:location.ownedBy)) ::<= {
              location.ownedBy = empty;
              doNext();
            }
            
          
            when (!location.ownedBy.isIncapacitated()) ::<= {
              world.battle.start(
                party: world.party,              
                allies: world.party.members,
                enemies: [location.ownedBy],
                landmark: landmark,
                renderable:{render::{canvas.fill();}},
                onEnd::(result) {
                  end(result);
                }
              );                
            } 
            
            doNext();
          }
          
          @:thunderSpawn ::{
            @:Entity = import(module:'base/entity.mt');
            @:sprite = Entity.new(
              island: landmark.island,
              speciesHint: 'base:thunder-spawn',
              professionHint: 'base:thunder-spawn',
              levelHint:7
            );
            for(0, 20) ::(i) {
              sprite.autoLevelProfession(:sprite.profession);
            }
            sprite.equipAllProfessionArts();  
            sprite.name = 'the Thunder Spawn';    
            return sprite;    
          };
          
          world.battle.start(
            party:world.party,              
            allies: world.party.members,
            enemies: [
              thunderSpawn(),            
              location.ownedBy,
              thunderSpawn()
            ],
            landmark: landmark,
            renderable:{render::{canvas.fill();}},
            onEnd::(result) {
              end(result);
            }
          );             
        },
        ['Juhriikaal', 'You\'ve got something special with you. The way you fight and prove yourself... You\'ve got potential.'],
        ['Juhriikaal', 'Ah... it\'s refreshing.'],
        ['', 'The party received The Wyvern Key of Light.'],          
        ['Juhriikaal', 'Take this. It\'s the Key to take you to your wish.'],
        ['Juhriikaal', 'Ah yes! You might have been expecting this as well...'],
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          windowEvent.queueMessage(
            text: 'Juhriikaal gently taps ' + world.party.members[0].name + ' on the head.'
          );
          perfectLearning();
          
          windowEvent.queueCustom(
            onLeave ::{
              doNext();
            }
          );
        },
        ['', 'Juhriikaal glows.'],
        ['Juhriikaal', 'Until next time, Chosen. Remember: seek the shrines with this new Key. We\'ll be waiting.'],
        ::(location, landmark, doNext) {
          if (location.ownedBy)
            location.ownedBy.name = 'Juhriikaal, Wyvern of Thunder';
          @:world = import(module:'base/world.mt');
          world.scenario.data.fireWyvernDefeated = true;
          @:keyother = Item.new(
            base: Item.database.find(id:'thechosen:wyvern-key-of-light')
          );
          world.party.inventory.add(:keyother);
          windowEvent.queueMessage(
            renderable:{render::{canvas.fill();}},
            text: 'You are teleported away...'
          );
          @:instance = import(module:'base/instance.mt');
          windowEvent.queueCustom(onEnter::{
            world.island.travel();                
          });            
        }
      ]
    }
  ) 


  Scene.newEntry(
    data : {
      id : 'thechosen:scene_wyvernthunder1',
      script: [
        ['Juhriikaal', 'Ah you have returned? Well, welcome back.'],
        ['Juhriikaal', 'You know... I do have a bit of a hobby that may come in handy for you.'],
        ['Juhriikaal', 'Materialization magic. Very difficult and sought after... I have spent some time trying to master it, and have had some... mild success.'],
        ['Juhriikaal', 'If you give me 2 items of the same quality and throw in some gold, I can make one of them of improved quality.'],    
        ['Juhriikaal', 'This magic DOES destroy the other item, however... And there is a chance it might not be successful as well....'],
        ['Juhriikaal', 'So there is a bit of risk. But if successful, this could let you reach new heights.'],
        ['Juhriikaal', 'A Chosen is only as good as their tools, or so they say.'],
        ::(location, landmark, doNext) {
          world.accoladeEnable(name:'wyvernsRevisited');
          @:world = import(module:'base/world.mt');
          windowEvent.queueAskBoolean(
            prompt:'Enhance item quality?',
            onChoice::(which) {
              when(which == false) ::<= {
                windowEvent.queueMessage(speaker:'Juhriikaal', text:'Ah I see. That is understandable. I will still be here if you change your mind.');
                windowEvent.queueCustom(
                  onEnter::{},
                  onLeave::{doNext();}                  
                );
              }
              
              @:ItemQuality = import(module:'base/item/quality.mt');



              @:qualityString ::(item) {
                return if (item.quality == empty) 
                  'no quality yet'
                else 
                  'quality ' + item.quality.name
              }

              @:tryAgain = ::{
                windowEvent.queueAskBoolean(
                  prompt:'Try enhancing again?',
                  onChoice::(which) {
                    when(which) ::<= {
                      attempt();
                    }

                    windowEvent.queueAskBoolean(
                      prompt:'Teleport to island?',
                      onChoice::(which) {
                        when(which) ::<= {
                          when(which)
                            doNext()
                        }
                      }
                    )
                  }
                );              
              }
              
              @:doSpell::(enhanced, catalyst, equippedBy) {

                @:newQual = ::<= {
                  // default -> Apprentice

                  @:improvementTree = {
                    'base:apprentices' : 'base:kings',
                    'base:kings' : 'base:queens',
                    'base:queens' : 'base:masterwork',
                    'base:masterwork' : 'base:legendary',
                    'base:legendary' : 'base:divine',
                    'base:divine' : 'base:gods',
                    'base:gods' : 'base:null'
                  };

                  when(enhanced.quality == empty) 'Apprentice\'s';
                  // TODO: mod support?
                  when(improvementTree[enhanced.quality.id] == empty) 'Apprentice\'s';                 
                  
                  return improvementTree[enhanced.quality.id];
                }
                
                windowEvent.queueMessage(speaker:'Juhriikaal', text:'This will improve ' +enhanced.name+ ' to be of quality ' + ItemQuality.find(id:newQual).name + '. This will cost you 500G.');                
              
                windowEvent.queueAskBoolean(
                  prompt:'Sacrifice ' + catalyst.name + ' and pay 500G?',
                  onChoice::(which) {
                    when(which == false)
                      tryAgain();
                    
                    windowEvent.queueMessage(text:'Juhriikaal takes the gold and the items and begins to concentrate.');                                  
                    windowEvent.queueMessage(speaker:'Juhriikaal', text:'...');                
                    windowEvent.queueMessage(text:'A deep blue light envelops the items...');                
                    
                    if (random.flipCoin()) ::<= {
                      windowEvent.queueMessage(text:'...before flashing!');  
                      windowEvent.queueMessage(speaker:'Juhriikaal', text:'Ah! It looks like it was successful.');                
                      @:whom = equippedBy;
                      @oldStats;
                      @slot;
                      if (whom != empty) ::<= {
                        oldStats = StatSet.new(state:whom.stats.save());
                        slot = whom.unequipItem(item:enhanced, silent:true);
                      }
                      enhanced.quality = ItemQuality.find(id:newQual);
                      if (whom != empty) ::<= {
                        whom.equip(item:enhanced, slot, silent:true);
                        oldStats.printDiff(prompt: enhanced.name + ': success! ', other:whom.stats);
                      }
                    } else ::<= {
                      windowEvent.queueMessage(text:'The light is disrupted and the catalyst shatters violently.');                
                      windowEvent.queueMessage(speaker:'Juhriikaal', text:'Well... Sometimes this happens. Materialization magic is quite volatile...');                
                    }
                    
                    catalyst.throwOut();
                    world.party.inventory.subtractGold(amount:500);
                    tryAgain();
                  }
                );               
              }

              @:attempt = ::{
                @enhanced;
                @catalyst;


                when(world.party.inventory.items->keycount < 1) ::<= {
                  windowEvent.queueMessage(speaker:'Juhriikaal', text:'Djiiroshuhzolii, Chosen. You have not enough items to let me attempt my magic.');
                  windowEvent.queueCustom(
                    onEnter::{},
                    onLeave::{doNext();} // always since no inventory anyway. cant change that.              
                  );
                }

                when(world.party.inventory.gold < 500) ::<= {
                  windowEvent.queueMessage(speaker:'Juhriikaal', text:'Djiiroshuhzolii, Chosen. You have not enough gold for my services. You need at least 500G.');
                  windowEvent.queueCustom(
                    onEnter::{},
                    onLeave::{doNext();} // always since no inventory anyway. cant change that.              
                  );
                }


              
                @:pickItem = import(module:'base/widgets/pickpartyitem.mt');
                pickItem(
                  canCancel: true,
                  topWeight: 0.5,
                  leftWeight: 0.5,
                  prompt:'Choose an item to enhance:',
                  onPick ::(item, equippedBy) {
                    when (item == empty) ::<= {
                      windowEvent.queueMessage(speaker:'Juhriikaal', text:'Ah I see. I will still be here if you change your mind.');
                      windowEvent.jumpToTag(name:'pickItem', goBeforeTag: true, doResolveNext:true);
                      windowEvent.queueCustom(
                        onEnter::{},
                        onLeave::{doNext();}                  
                      );                
                    }
                    @:holder = equippedBy;

                    when (item.base.hasTraits(:Item.TRAIT.HAS_QUALITY)) ::<= {
                      windowEvent.queueMessage(speaker:'Juhriikaal', text:'Chosen I am sorry, this item cannot have its quality improved.');                
                    }
                    
                    
                    windowEvent.queueMessage(speaker:'Juhriikaal', text:'Excellent. Now, choose an item to be the catalyst for the magic.');                
                    windowEvent.queueMessage(speaker:'Juhriikaal', text:'Remember, this item will be destroyed in the process and must be the same quality.');                
                    
                    enhanced = item;
                    windowEvent.jumpToTag(name:'pickItem', goBeforeTag: true, doResolveNext:true);
                    
                    pickItem(
                      canCancel: true,
                      topWeight: 0.5,
                      leftWeight: 0.5,
                      prompt:'Choose an item to sacrifice:',
                      filter ::(value) <- 
                        value.base.hasTraits(:Item.TRAIT.HAS_QUALITY) && 
                        value.quality == enhanced.quality && value != enhanced,
                      onPick ::(item, equippedBy) {
                        when (item == empty) ::<= {
                          windowEvent.queueMessage(speaker:'Juhriikaal', text:'Oh... It looks like you have no item elligible as a catalyst for this item. I am sorry. Remember: catalysts need to be the same quality as the item to enhance.');                
                          tryAgain();                      
                        }
                        catalyst = item;

                        when (catalyst == enhanced) ::<= {   
                          windowEvent.queueMessage(speaker:'Juhriikaal', text:'Chosen I am sorry, you cannot choose the same item as the catalyst.');                
                        }


                        when (catalyst.base.hasTraits(:Item.TRAIT.HAS_QUALITY) == false) ::<= {   
                          windowEvent.queueMessage(speaker:'Juhriikaal', text:'Chosen I am sorry, this item cannot be used as a catalyst for the spell.');                
                        }
                        
                        when (catalyst.quality != enhanced.quality) ::<= {                    
                          windowEvent.queueMessage(speaker:'Juhriikaal', text:'Chosen, I am sorry, I cannot cast my magic on these. The ' 
                            + enhanced.name + ' you wish to enhance is of ' + qualityString(item:enhanced) + 
                            ' while the catalyst is of ' + qualityString(item:catalyst) + '. These items must be the same quality for the spell to work.');
                        }
                         
                        windowEvent.queueMessage(speaker:'Juhriikaal', text:'Now. Let me cast the spell.');                
                        windowEvent.jumpToTag(name:'pickItem', goBeforeTag: true, doResolveNext:true);
                        
                        doSpell(enhanced, catalyst, equippedBy:holder);                       
                      }
                    )
                  }
                )            
              };
              attempt();
            }
          );
          
        },
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          windowEvent.queueMessage(
            speaker:'Juhriikaal', 
            text:'Now, would you like me to teleport you back?'
          );
          
          windowEvent.queueAskBoolean(
            prompt: 'Leave?',
            onChoice::(which) {
              windowEvent.queueMessage(
                text: 'Juhriikaal glows.'
              );                

              windowEvent.queueMessage(
                renderable:{render::{canvas.fill();}},
                text: 'You are teleported away...'
              );

              windowEvent.queueCustom(onEnter::{
                world.island.travel();                
              });            
            }
          );
        }
      ]
    }
  )



  Scene.newEntry(
    data : {
      id : 'thechosen:scene_wyvernlight0',
      script: [
        ['???', '...'],
        ['???', '... At last.'],
        ['???', 'I have waited so long for this moment.'],
        ['Shaarraeziil', 'Chosen... You come before me, Shaarraeziil, the Wyvern of Light.'],
        ['Shaarraeziil', '...'],
        ['Shaarraeziil', 'I beckoned for you, and as such I will grant you your wish as a reward...'],
        ['Shaarraeziil', '...However.'],
        ['Shaarraeziil', 'Before that, I must determine if you\'re worthy of my gift. If you\'re truly worthy to bear the name Chosen.'],
        ['Shaarraeziil', 'I must feel your power for myself. My siblings may have held back, but I will not.'],
        ['Shaarraeziil', 'Brace yourself for true power!'],
        ::(location, landmark, doNext) {      
        
          @:world = import(module:'base/world.mt');
          @:Battle = import(module:'base/battle.mt');
          @:canvas = import(module:'core/graphics/canvas.mt');
          location.ownedBy.name = 'Shaarraeziil, Wyvern of Light';
          @:end = ::(result){

            when(world.battle.partyWon() == false) ::<= {
              windowEvent.queueMessage(
                speaker:'Juhriikaal',
                text:'Alas. Another one will come, more worthy.'
              );
              
              windowEvent.queueCustom(
                onEnter::{
                  @:instance = import(module:'base/instance.mt');
                  instance.gameOver(reason:'The party was wiped out.');
                }
              );
            }
            
            when(world.party.isMember(:location.ownedBy)) ::<= {
              location.ownedBy = empty;
              doNext();
            }

          
            when (!location.ownedBy.isIncapacitated()) ::<= {
              world.battle.start(
                party: world.party,              
                allies: world.party.members,
                enemies: [location.ownedBy],
                landmark: landmark,
                renderable:{render::{canvas.fill();}},
                onEnd::(result) {
                  end(result);
                }
              );                
            } 
            
            doNext();
          }
          
          @:lightSpawn ::{
            @:Entity = import(module:'base/entity.mt');
            @:sprite = Entity.new(
              island: landmark.island,
              speciesHint: 'base:guiding-light',
              professionHint: 'base:guiding-light',
              levelHint:12
            );
            for(0, 20) ::(i) {
              sprite.autoLevelProfession(:sprite.profession);
            }
            sprite.equipAllProfessionArts();  
            sprite.name = 'the Guiding Light';
            return sprite;    
          };
          
          world.battle.start(
            party:world.party,              
            allies: world.party.members,
            enemies: [
              lightSpawn(),            
              location.ownedBy,
              lightSpawn()
            ],
            landmark: landmark,
            renderable:{render::{canvas.fill();}},
            onEnd::(result) {
              end(result);
            }
          );             
        },
        ['Shaarraeziil', 'Truly! It is you! The one I seek!'],
        ['Shaarraeziil', 'Blessed day! Blessed day indeed.'],
        ['Shaarraeziil', 'Chosen, you have truly earned your name, and your reward.'],
        ['Shaarraeziil', '...However.'],
        ['Shaarraeziil', 'I must be forward with you. The real reason I have called you here. The real reason why you had to fight, fang and claw, to me.'],
        ['Shaarraeziil', '...We need your help.'],
        ['Shaarraeziil', 'Another wyvern, the Wyvern of Darkness... They threaten our domain, our way of life, and the mortal realm.'],
        ['Shaarraeziil', 'Me and my siblings... truthfully we haven\'t the power to stop them. We... are too weak.'],
        ['Shaarraeziil', 'But you... you have power. Power we cannot best.'],
        ['Shaarraeziil', 'I have talked to my siblings prior to your arrival... We all feel that you are capable of defeating the one of Darkness.'],
        ['Shaarraeziil', '... However.'],
        ['Shaarraeziil', 'It would be unfair to lay this burden upon you. You have proven yourself beyond all.'],
        ['Shaarraeziil', 'You may choose to take your wish, no questions asked. You have earned it.'],
        ['Shaarraeziil', 'But, we humbly request... that you help us defeat the Wyvern of Darkness.'],
        ['Shaarraeziil', 'I will warn you. The Wyvern of Darkness\' treachery knows no bounds. It will be dangerous in ways you\'ve not seen...'],
        ['Shaarraeziil', 'Upon your victory, however, your wish will be waiting for you all the same.'],
        ['Shaarraeziil', 'What say you...? Will you help us...?'],
      

        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          @doQuest = false;
          world.scenario.data.lightWyvernDefeated = true;

          @:ask = ::{
            windowEvent.queueChoices(
              prompt:'Do which?',
              canCancel: false,
              choices: [
                'Take wish',
                'Accept quest to defeat the Wyvern of Darkness'
              ],
              onChoice::(choice) {
                @doQuest = (choice == 2);
                
                windowEvent.queueAskBoolean(
                  prompt: 'Are you sure you want to ' + if(doQuest) 'accept the quest?' else 'take the wish?',
                  onChoice::(which) {
                    when(which == false) ask();
                    if (doQuest == false)
                      Scene.start(id:'thechosen:scene_wyvernlight0_wish', onDone::{}, location, landmark:location.landmark)
                    else ::<= {
                      @:world = import(module:'base/world.mt');
                      world.accoladeEnable(name:'acceptedQuest');
                      
                      windowEvent.queueMessage(
                        speaker : 'The Game',
                        text : '"Psst this hasn\'t been implemented yet! So we\'ll just pretend for now..."'
                      );
                      
                      windowEvent.queueCustom(
                        onEnter :: {
                          Scene.start(id:'thechosen:scene_wyvernlight0_wish', onDone::{}, location, landmark:location.landmark)                          
                        }
                      );
                      //Scene.start(id:'thechosen:scene_wyvernlight0_quest', onDone::{}, location, landmark:location.landmark);
                    }
                  }
                );
              }
            )      
          }
          ask();    
        }
      ]
    }
  ) 

  Scene.newEntry(
    data : {
      id : 'thechosen:scene_wyvernlight0_wish',
      script: [
        ['Shaarraeziil', 'I see.'],
        ['Shaarraeziil', '...'],
        ['Shaarraeziil', 'Alas! You have done a great job.'],
        ['Shaarraeziil', 'Now.. What is your wish?'],
        ::(location, landmark, doNext) {
          @:instance = import(module:'base/instance.mt');
          @:enter = import(module:'base/widgets/name.mt');
          enter(
            prompt: 'What is your wish?',
            onDone ::(name) {
              @:world = import(module:'base/world.mt')
              world.setWish(wish:name);
              instance.savestate();
              (import(module:'base/accolade/newrecord.mt'))(wish:name);
            }
          );
        }
      ]
    }
  )


  Scene.newEntry(
    data : {
      id : 'thechosen:scene_wyvernlight0_quest',
      script: [
        ['Shaarraeziil', 'Chosen, from the bottom of my heart, thank you.'],
        ['Shaarraeziil', '...'],
        ['Shaarraeziil', 'You will need to prepare for the struggle ahead.'],
        ['Shaarraeziil', 'When you are ready, come to me once more.'],
        ['Shaarraeziil', 'Also... This may help with your battle.'],
        ::(location, landmark, doNext) {
          @:item = Item.new(
            base: Item.database.find(id:'base:greatsword'),
            qualityHint: 'base:divine',
            materialHint: 'base:dragonglass',
            colorHint: 'base:gold',
            designHint: 'base:striking',
            abilityHint: 'base:greater-cure'
          );
          @:ItemEnchant = import(module:'base/item/enchant.mt');
          item.enchantLimit = 13;

          item.name = 'Wyvern\'s Hope';
          @:world = import(module:'base/world.mt');
          world.party.inventory.add(item);                
          windowEvent.queueMessage(text:'The party was given the ' + item.name + '.');
          doNext();
        },
        ['Shaarraeziil', 'I forged this in hopes that our Chosen would be able to wield it.'],
        ['Shaarraeziil', 'Perhaps you don\'t need it, but it is for you regardless. Do with it as you like.'],

        ['Shaarraeziil', 'The islands of the sky are aplenty... There is one that the light key points to. I will take you there.'],
        ['Shaarraeziil', 'Come to the gate and use the key of light to see me again when you\'re ready for the journey ahead.'],
        
        ::(location, landmark, doNext) {
          location.ownedBy.name = 'Shaarraeziil';
          @:world = import(module:'base/world.mt');
          @key = world.party.getItem(condition::(value) <- value.base.id == 'thechosen:wyvern-key-of-light');

          // you can technically throw it out or Literally Throw It.
          when(key == empty) ::<= {
            windowEvent.queueMessage(
              speaker: 'Shaarraeziil',
              text: 'Uhm. Where\'s the light key..?'
            );

            windowEvent.queueMessage(
              speaker: 'Shaarraeziil',
              text: 'While I admit that it is impressive that you so casually got rid of an important artifact, please do not do that in the future.'
            );

            
            @:item = Item.new(base:Item.database.find(id:'thechosen:wyvern-key-of-light'),
                 from:location.ownedBy);
            windowEvent.queueMessage(text:'The party was given a ' + item.name + '.');
            world.party.inventory.add(item);
            key = item;
          }
          

          @:canvas = import(module:'core/graphics/canvas.mt');
          windowEvent.queueMessage(
            renderable:{render::{canvas.fill();}},
            text: 'You are whisked away to another island...'
          );

          windowEvent.queueCustom(
            onEnter :: {
              @:instance = import(module:'base/instance.mt');
              world.loadIsland(key, onDone::(island) {
                world.island.visit();
                @:which = world.island.landmarks->filter(::(value) <- value.base.id == 'base:wyvern-gate');
                if (which != empty && which->size > 0)
                  world.island.map.setPointer(
                    x: which[0].x,
                    y: which[0].y
                  );
                world.island.travel();
                doNext();     
              });
            }
          ); 




          
          @:instance = import(module:'base/instance.mt');

          world.loadIsland(key, onDone::(island) {
            world.island.visit();
            @:which = world.island.landmarks->filter(::(value) <- value.base.id == 'base:wyvern-gate');
            if (which != empty && which->size > 0)
              world.island.map.setPointer(
                x: which[0].x,
                y: which[0].y
              );
            world.island.travel(onReady:doNext);
          });
        } 
      ]
    }
  )


  Scene.newEntry(
    data : {
      id : 'thechosen:scene_wyvernlight1',
      script: [
        ['Shaarraeziil', '...'],
        ['Shaarraeziil', 'Chosen, are you ready?'],
        ['Shaarraeziil', 'It will be treacherous...'],
        ::(location, landmark, doNext) {
          windowEvent.queueAskBoolean(
            prompt: 'Venture forth?',
            onChoice::(which) {
              when(which == false) ::<= {
                doNext();  
              }
              @:instance = import(module:'base/instance.mt');
              @:world = import(module:'base/world.mt');
              @:landmark = Landmark.new(
                island : location.landmark.island,
                base : Landmark.database.find(id:'thechosen:dark-lair-entrance')
              );
              landmark.visit();
              landmark.travel();
            }
          );
        },


        ['Shaarraeziil', 'I understand. Come back when you are ready.'],
        ['Shaarraeziil', 'For now, I will take you back.'],
        ::(location, landmark, doNext){
          @:world = import(module:'base/world.mt');
          @key = world.party.getItem(condition::(value) <- value.base.id == 'thechosen:wyvern-key-of-light');



          @:instance = import(module:'base/instance.mt');

          @:canvas = import(module:'core/graphics/canvas.mt');
          windowEvent.queueMessage(
            renderable:{render::{canvas.fill();}},
            text: 'You are whisked away to another island...'
          );

          windowEvent.queueCustom(
            onEnter :: {
              @:instance = import(module:'base/instance.mt');
              world.loadIsland(key, onDone::(island) {
                world.island.visit();
                @:which = world.island.landmarks->filter(::(value) <- value.base.id == 'base:wyvern-gate');
                if (which != empty && which->size > 0)
                  world.island.map.setPointer(
                    x: which[0].x,
                    y: which[0].y
                  );

                world.island.travel(onReady:doNext);
              });
            }
          ); 

        }
      ]
    }
  );


  Scene.newEntry(
    data : {
      id : 'thechosen:scene_wyvernlight2_quest',
      script : [

        ['Shaarraeziil', 'Now.. What is your wish?'],

        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt')
          world.accoladeEnable(name:'acceptedQuest');
          @:instance = import(module:'base/instance.mt');
          @:enter = import(module:'base/widgets/name.mt');
          enter(
            prompt: 'What is your wish?',
            onDone ::(name) {
              world.setWish(wish:name);
              instance.savestate();
              (import(module:'base/accolade/newrecord.mt'))(wish:name);
            }
          );
        }    
      ]
    }
  );


  Scene.newEntry(
    data : {
      id : 'thechosen:scene_sentimentalbox',
      script: [
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          when(world.scenario.data.openedSentimentalBox) 
            windowEvent.queueMessage(text:
              "The box is empty."
            );
          world.scenario.data.openedSentimentalBox = true;
          doNext();
        },
        ['', 'Opening the box reveals items inside!'],
        ['', 'The party receives a book on how to fight.'],
        ['', 'The party receives 3 Potions.'],
        ['', 'The party receives 3 Gems.'],
        ['', 'The party receives a Life Crystal.'],
        ['', 'The party receives 4 Escape Stones.'],
        ['', 'The party also receives an equippable Tome.'],
        ['', 'There\'s also a note here...'],
        ::(location, landmark, doNext) {
          @:world = import(module:'base/world.mt');
          @:Entity = import(module:'base/entity.mt');
          @:someone = world.island.newInhabitant();
          @:someoneElse = world.island.newInhabitant(levelHint:10);
          /*
          windowEvent.queueMessage(text:
            (random.pickArrayItem(
              list : [
                '"I know we haven\'t always seen eye-to-eye; I know that we argue a lot. But when I heard you were leaving on your big adventure or whatever, I knew that I had to help. Here\'s some stuff I gathered over the years. I figure you\'ll get more use out of it than I ever will. Stay safe out there, and come back alive!"',
                '"Well, I didn\'t think the day would come, but here we are. I don\'t know about "seeing the world", but I do know you well enough to know when you\'re determined to do something. I hope you find this stuff useful for your journey. I\'ll miss you."',
                '"You know, you\'re a real pain. All of a sudden you want to go on a big adventure, huh? Whatever. Just take this stuff. Put it to good use and stay alive. You might find it hard to believe, but I\'ll miss you. Do good out there."',
                '"There comes a time when someone has to take action and do something big. I saw it in your eyes the moment you told me. I could tell it was hard for you, too. Just know that you have my blessing. Let the items in this box be proof of that. I\'m proud of you. Stay alive out there."',
                '"So, it\'s finally time. We always knew you were an adventurer at heart. We prepared for the day you would finally go out into the world on your own. It might be tough, but we truly think you can overcome anything. Hopefully you\'ll find these useful on your journey. Be strong."',
                '"Ever since '+someoneElse.name+' left, you\'ve never been the same. Always looking out there thinking of a way to find them. And you know what? I can\'t blame you. I miss them too. Either way, stay safe and come back in one piece. Hopefully these will come in handy."' 
              ]
            ))
          );
          */

         windowEvent.queueMessage(text:
          '"Don\'t forget! If you\'re ever in a tight spot, use your Escape Stones. I think you\'ll need them. You can find more at any shop in a town or city, but I\'m sure you already know that."' +
          '\n\n - '+someone.name
         );


          world.party.inventory.addGold(amount:80);
          world.party.inventory.add(item: ::<= {
             @:i = Item.new(
                base:Item.database.find(id:'base:life-crystal'),
                materialHint : 'base:hardstone',                 
                qualityHint : 'base:worn'
              )
              i.price = 10;
              return i;
            }
          );
          
          
          for(0, 3)::(i) {
            @:crystal = Item.new(
              base:Item.database.find(:"base:inlet-gem"),
              forceNeedsAppraisal : false
            )

            world.party.inventory.add(item:crystal);
          }

          //party.inventory.add(item:keyhome);

          world.party.inventory.add(item:Item.new(
            base:Item.database.find(id:'base:book'),
            creationHint:'base:how-to-fight'
          ));

          world.party.inventory.add(item:Item.new(
            base:Item.database.find(id:'base:escape-stone'),
            creationHint:0
          ));

          world.party.inventory.add(item:Item.new(
            base:Item.database.find(id:'base:escape-stone'),
            creationHint:0
          ));

          world.party.inventory.add(item:Item.new(
            base:Item.database.find(id:'base:escape-stone'),
            creationHint:0
          ));

          world.party.inventory.add(item:Item.new(
            base:Item.database.find(id:'base:escape-stone'),
            creationHint:0
          ));

          world.party.inventory.add(item:Item.new(
            base:Item.database.find(id:'base:potion'),
            creationHint:0
          ));
          world.party.inventory.add(item:Item.new(
            base:Item.database.find(id:'base:potion'),
            creationHint:0
          ));
          world.party.inventory.add(item:Item.new(
            base:Item.database.find(id:'base:potion'),
            creationHint:0
          ));

          
          @tome = Item.new(
            base:Item.database.find(id:'base:tome'),
            abilityHint: 'base:cure',
            materialHint: 'base:hardstone',
            qualityHint: 'base:quality'
          );
          world.party.inventory.add(item:tome);        

          windowEvent.queueAskBoolean(
            prompt: 'Toss the box?',
            onChoice::(which) {
              if (which) ::<= {
                windowEvent.queueMessage(
                  text: 'The sentimental box was tossed out.'
                );
                world.party.inventory.remove(item: 
                  world.party.inventory.items->filter(by:
                    ::(value) <- value.base.id == 'thechosen:sentimental-box'
                  )[0]
                );
              } else ::<= {
                windowEvent.queueMessage(
                  speaker:world.party.members[0].name,
                  text:'"We probably could sell it later if we needed to."'
                );
              }          
            
              doNext();
            }
          );
          
        }
      ]
    }
  )
}
