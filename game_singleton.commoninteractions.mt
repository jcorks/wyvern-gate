@:InteractionMenuEntry = import(module:'game_struct.interactionmenuentry.mt');
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
@:BattleAction = import(module:'game_struct.battleaction.mt');
@:Arts = import(module:'game_database.arts.mt');
@:ArtsDeck = import(module:'game_class.artsdeck.mt');






return {
  battle : {
    attack : InteractionMenuEntry.new(
      name : 'Attack',
      filter::(user, battle) <- true,
      onSelect::(user, battle, commitAction) {
        @:card = ArtsDeck.synthesizeHandCard(id:'base:attack');

        windowEvent.queueChoices(
          choices : [
            'Use',
          ],
          canCancel: true,
          topWeight : 1,
          renderable : {
            render ::{
              ArtsDeck.renderArt(user, handCard:card, topWeight:0.1);
              
            },
          },
          onChoice::(choice) {
            user.playerUseArt(
              card: card,
              commitAction
            )        
          }
        );
      }
    ),
    
    arts : InteractionMenuEntry.new(
      name : 'Arts',
      filter::(user, battle) <- true,
      onSelect::(user, battle, commitAction) {
        
        user.deck.chooseArtPlayer(
          user,
          canCancel: true,
          act: 'Use',
          onChoice::(card, backout) {
            when (Arts.find(:card.id).kind == Arts.KIND.REACTION)
              windowEvent.queueMessage(
                text: 'Reaction Arts can only be used in response to other Arts. They cannot be played right now.'
              );
            user.playerUseArt(
              card,
              onCancel ::{
                backout();
              },
              commitAction::(action){
                backout();
                commitAction(action);
              }
            );
          }
        );
      }
    ),
    
    check : InteractionMenuEntry.new(
      name : 'Check',
      filter::(user, battle) <- true,
      onSelect::(user, battle, commitAction) {

        @:allies  = battle.getAllies(entity:user);
        @:enemies = battle.getEnemies(entity:user);

        windowEvent.queueChoices(
          topWeight: 1,
          prompt: 'Check which?', 
          leftWeight: 1,
          keep: true,
          canCancel: true,
          choices : [
          'Allies',
          'Discarded Arts'
          ],
          onChoice::(choice) {
          when(choice == 0) empty;

          match(choice-1) {
            (0): ::<={ // allies
              @:names = [...allies]->map(to:::(value){return value.name;});
              
              choice = windowEvent.queueChoices(
                topWeight: 1,
                leftWeight: 1,
                prompt:'Check which ally?',
                choices: names,
                keep: true,
                canCancel: true,
                onChoice::(choice) {
                  when (choice == 0) empty;

                  @:ally = allies[choice-1];
                  ally.describe();              
                }
              );
            },
            
            
            (1): ::<= {
              user.deck.chooseDiscard(
                canCancel: true
              );
            }
          
          }          
          }
        )
      }    
    ),
    
    wait : InteractionMenuEntry.new(
      name : 'Wait',
      filter::(user, battle) <- true,
      onSelect::(user, battle, commitAction) {
        commitAction(action:
          BattleAction.new(
            card: ArtsDeck.synthesizeHandCard(id:'base:wait'),
            targets: [],
            extraData: {}
          )        
        );
      }
    ),
    
    
    item : InteractionMenuEntry.new(
      name : 'Item',
      filter::(user, battle) <- true,
      onSelect::(user, battle, commitAction) {
        @:world = import(module:'game_singleton.world.mt');
        @:itemmenu = import(module:'game_function.itemmenu.mt');
        @:enemies = battle.getEnemies(entity:user);

        itemmenu(inBattle:true, user, party:world.party, enemies, onAct::(action){
          commitAction(action);
        });
      }
    )
  },

  options : {
    quit : InteractionMenuEntry.new(
      name : 'Quit',
      keepInteractionMenu : true,
      filter::(island, landmark) <- true,
      onSelect::(island, landmark) {
        windowEvent.queueChoices(
          prompt:'Quit?',
          choices: [
            'Yes',
            'No'
          ],
          onChoice::(choice) {
            when(choice == 2) empty;
            @:instance = import(module:'game_singleton.instance.mt');
            instance.quitRun();
          }
        );      
      }
    ),
    
    save : InteractionMenuEntry.new(
      name : 'Save',
      filter ::(island, landmark) <- landmark == empty,
      keepInteractionMenu : true,
      onSelect::(island, landmark) {
        @:instance = import(module:'game_singleton.instance.mt');
        @:loading = import(module:'game_function.loading.mt');
        loading(
          message : 'Saving world...',
          do::{
            instance.savestate();
            @:world = import(module:'game_singleton.world.mt');
            windowEvent.queueMessage(text:'Successfully saved world ' + world.saveName);            
          }
        );
      }
    ),
    
    system : InteractionMenuEntry.new(
      name: 'System',
      keepInteractionMenu : true,
      filter ::(island, landmark) <- true,
      onSelect::(island, landmark) {
      
      }
    )
  },
  walk : {
    check : InteractionMenuEntry.new(
      name : 'Check',
      keepInteractionMenu : true,
      filter::(island, landmark) <- landmark == empty,
      onSelect::(island, landmark) {
        @:choices = [
          ::{
            windowEvent.queueMessage(speaker: 'About ' + island.name, text: island.description)          
          },
          
          ::{
            island.incrementTime();
            @:world = import(module:'game_singleton.world.mt');
            
            when(random.try(percentSuccess:80))
              windowEvent.queueMessage(text:'You look around, but fail to find anything of note.');   
  


            @:openChest = ::(opener){

              windowEvent.queueMessage(text:'The party opens the chest...'); 
              @:Damage = import(module:'game_class.damage.mt');
              
              when(Number.random() < 0.5) ::<= {
                windowEvent.queueMessage(text:'A trap is triggered, and a volley of arrows springs form the chest!'); 
                if (Number.random() < 0.5) ::<= {
                  windowEvent.queueMessage(text:opener.name + ' narrowly dodges the trap.');             
                } else ::<= {
                  opener.damage(
                    attacker: opener,
                    damage: Damage.new(
                      amount:opener.stats.HP * (0.7),
                      damageType : Damage.TYPE.PHYS,
                      damageClass: Damage.CLASS.HP
                    ),
                    dodgeable: false
                  );
                }
              } 
              
              
              @:itemCount = (2+Number.random()*3)->floor;
              
              windowEvent.queueMessage(text:'The chest contained ' + itemCount + ' items!'); 
              
            
              when(itemCount > party.inventory.slotsLeft) ::<= {
                windowEvent.queueMessage(text: '...but the party\'s inventory was too full.');
              }        
              for(0, itemCount)::(index) {
                @:item = Item.new(
                  base:Item.database.getRandomFiltered(
                    filter:::(value) <- value.isUnique == false && value.canHaveEnchants && value.tier <= island.tier
                  ),
                  rngEnchantHint:true
                );
                @message = 'The party found ' + correctA(word:item.name);
                windowEvent.queueMessage(text: message);


                party.inventory.add(item);
                
              }

            }


            
            @:party = world.party;
            windowEvent.queueMessage(text:'What\'s this?');
            windowEvent.queueMessage(text:'The party trips over a hidden chest!');
            windowEvent.queueAskBoolean(
              prompt: 'Open the chest?',
              onChoice ::(which) {
                when(which == false) empty;
                          
                windowEvent.queueChoices(
                  prompt: 'Who opens up the chest?',
                  choices : [...party.members]->map(to:::(value) <- value.name),
                  canCancel: false,
                  onChoice::(choice) {
                    openChest(opener:party.members[choice-1]);
                  }
                );
              }
            );
          }
        ]
        windowEvent.queueChoices(
          choices: [
            'Island',
            'Immediate area...'
          ],
          keep:true,
          canCancel:true,
          onChoice::(choice) {
            choices[choice-1]();
          }
        );
        
      }
    ),
    
    party : InteractionMenuEntry.new(
      name : 'Party',
      keepInteractionMenu : true,
      filter::(island, landmark) <- true,
      onSelect::(island, landmark) {
        (import(module:'game_function.partyoptions.mt'))();
      }
    ),
    
    inventory : InteractionMenuEntry.new(
      name : 'Inventory',
      keepInteractionMenu : true,
      filter::(island, landmark) <- true,
      onSelect::(island, landmark) {
        @:world = import(module:'game_singleton.world.mt');
        @firstAwake = empty;
        {:::} {
          foreach(world.party.members)::(index, member) {
            if (!member.isIncapacitated()) ::<= {
              firstAwake = member
              send();
            }
          }
        }
        @:itemmenu = import(module:'game_function.itemmenu.mt');
        itemmenu(
          inBattle: false,
          user:firstAwake, 
          party:world.party, 
          enemies:[],
          limitedMenu:true,
          topWeight:0.5,
          leftWeight:0.5,
          onAct::(action) {
            when(action == empty) empty;
            firstAwake.useArt(
              art:Arts.find(id:action.card.id),
              targets:action.targets,
              turnIndex : 0,
              extraData : action.extraData
            );                
          }
        );

      }
    ),
    
    wait : InteractionMenuEntry.new(
      name : 'Wait',
      keepInteractionMenu : false,
      filter::(island, landmark) <- true,
      onSelect::(island, landmark) {
        @:Landmark = import(module:'game_mutator.landmark.mt');
        @:world = import(module:'game_singleton.world.mt');
        when(landmark != empty && landmark.base.landmarkType == Landmark.database.statics.TYPE.DUNGEON) 
          windowEvent.queueChoices(
            prompt: 'Wait until...',
            choices : [
              'Morning (?)',
              'Evening (?)'
            ],
            
            canCancel: true,
            onChoice ::(choice) {
              when(choice == 0) empty;
              
              landmark.wait(:if(choice == 1) world.TIME.LATE_MORNING else world.TIME.LATE_EVENING);
                
              windowEvent.queueMessage(
                text: 'The party waits for some time to pass...',
                renderable : {
                  render ::{
                    canvas.blackout();
                  }
                }
              )
            }
          ) 

      
      
        windowEvent.queueChoices(
          prompt: 'Wait until...',
          choices : [
            'Dawn',
            'Early morning',
            'Morning',
            'Late morning',
            'Midday',
            'Afternoon',
            'Late afternoon',
            'Sunset',
            'Early evening',
            'Evening',
            'Late evening',
            'Midnight',
            'The dead hour',
            'The dead of the night',
          ],
          
          canCancel: true,
          onChoice ::(choice) {
            when(choice == 0) empty;
            
            @:until = choice-1;
            if (landmark)
              landmark.wait(until)
            else 
              island.wait(until)
              
            windowEvent.queueMessage(
              text: 'The party waits...',
              renderable : {
                render ::{
                  canvas.blackout();
                }
              }
            )
          }
        )      
      }
    )
  },
  person : {
    fetchQuestStart : InteractionMenuEntry.new(
      name: 'Need something?',
      keepInteractionMenu : true,
      filter ::(entity) {
        @:world = import(module:'game_singleton.world.mt');
        @:party = world.party;
        return party.quests->findIndexCondition(::(value) <- value.issuerID == entity.worldID) == -1
      },
      onSelect::(entity) {
        windowEvent.queueMessage(
          speaker: entity.name,
          text: '"Funny you should ask, yeah I need some help..."'
        );
        @:Quest = import(:'game_mutator.quest.mt');
        
        if (entity.data.quest == empty)
          entity.data.quest = 
            Quest.new(
              issuer : entity,
              rank : Quest.RANK.NONE,
              base : Quest.find(id:'base:fetch-quest-personal')
            );
        
        windowEvent.queueAskBoolean(
          renderable : {
            render ::{
              entity.data.quest.renderPrompt();            
            }
          },
          topWeight : 1,
          prompt: 'Accept quest?',
          onChoice::(which) {
            @:world = import(module:'game_singleton.world.mt');
            @:party = world.party;
            party.quests->push(:entity.data.quest);
          }
        );
      }
    ),

    fetchQuestEnd : InteractionMenuEntry.new(
      name: 'About that item...',
      keepInteractionMenu : true,
      filter ::(entity) {
        @:world = import(module:'game_singleton.world.mt');
        @:party = world.party;
        return party.quests->findIndexCondition(::(value) <- value.issuerID == entity.worldID) != -1
      },
      onSelect::(entity) {
        //@:quest = party.quests[party.quests->findIndexCondition(::(value) <- value.issuerID == entity.worldID)];

        // todo: turn in quest
        
      }
    ),
  
  
    barter : InteractionMenuEntry.new(
      name: 'Barter',
      keepInteractionMenu : true,
      filter ::(entity)<- true, // everyone can barter,
      onSelect::(entity) {
        @:this = entity;
        when(this.isIncapacitated())
          windowEvent.queueMessage(
            text: this.name + ' is not currently able to talk.'
          );                            


        when (this.inventory.isEmpty) ::<= {
          windowEvent.queueMessage(
            text: this.name + ' has nothing to barter with.'
          );        
        }
        @:item = this.inventory.items[0];

        windowEvent.queueMessage(
          text: this.name + ' is interested in acquiring ' + correctA(word:this.favoriteItem.name) + '. They are willing to trade one for their ' + item.name + '.'
        );        
        
        @:world = import(module:'game_singleton.world.mt');
        @:party = world.party;

        @:tradeItems = party.inventory.items->filter(by::(value) <- value.base == this.favoriteItem);
        
        when(tradeItems->keycount == 0) ::<= {
          windowEvent.queueMessage(
            text: 'You have no such items to trade, sadly.'
          );                         
        }
        


        windowEvent.queueChoices(
          prompt: this.name + ' - bartering',
          choices: ['Trade', 'Check Item', 'Compare Equipment'],
          jumpTag: 'Barter',
          canCancel: true,
          keep:true,
          onChoice::(choice) {
            when(choice == 0) empty;
            
            match(choice-1) {
              // Trade
              (0)::<= {
              windowEvent.queueChoices(
                choices: [...tradeItems]->map(to::(value) <- value.name),
                canCancel: true,
                onChoice::(choice) {
                  when(choice == 0) empty;
                  
                  @:chosenItem = tradeItems[choice-1];
                  party.inventory.remove(item:chosenItem);
                  this.inventory.remove(item);
                  party.inventory.add(item);
                  
                  windowEvent.queueMessage(
                    text: 'In exchange for your ' + chosenItem.name + ', ' + this.name + ' gives the party ' + correctA(word:item.name) + '.'
                  );                                                 
                  world.party.karma += 100;
                  
                  windowEvent.jumpToTag(name:'Barter', goBeforeTag:true, doResolveNext:true);
                }
              );
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
    )
  }
}
