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
@:Ability = import(module:'game_database.ability.mt');


return {
    battle : {
        act : InteractionMenuEntry.new(
            name : 'Act',
            filter::(user, battle) <- true,
            onSelect::(user, battle, commitAction) {
                @:abilities = [];
                @:allies  = battle.getAllies(entity:user);
                @:enemies = battle.getEnemies(entity:user);
                foreach(user.abilitiesAvailable)::(index, ability) {
                    abilities->push(value:
                        if (ability.apCost > 0 || ability.hpCost > 0)
                            if (ability.apCost > 0) 
                                ability.name + '(' + ability.apCost + ' AP)'
                            else 
                                ability.name + '(' + ability.apCost + ' HP)'
                        else
                            ability.name
                    );
                }
                
                windowEvent.queueChoices(
                    leftWeight: 1,
                    topWeight: 1,
                    prompt:'What ability should ' + user.name + ' use?',
                    choices: abilities,
                    canCancel: true,
                    keep: true,
                    onChoice::(choice) {
                        when(choice == 0) empty;
                        
                        
                        @:ability = user.abilitiesAvailable[choice-1];
                        
                        @:Entity = import(module:'game_class.entity.mt');
                        
                        match(ability.targetMode) {
                          (Ability.TARGET_MODE.ONE,
                           Ability.TARGET_MODE.ONEPART): ::<={
                            @:all = [
                                ...enemies,
                                ...allies
                            ];
                            
                            
                            @:allNames = [...all]->map(to:::(value)<- value.name);
                          
                            @:chooseOnePart ::(onDone) {
                                @:text = 
                                [
                                    [
                                        'The attack aims for the head.',
                                        'While fairly difficult to hit, when it lands it will',
                                        'almost definitely cause a critical hit.'
                                    ],
                                    [
                                        'The attack aims for the body.',
                                        'While easiest to hit, when it lands it will',
                                        'cause additional general damage.'
                                    ],
                                    [
                                        'The attack aims for the limbs.',
                                        'While slightly difficult hit, when it lands it will',
                                        'has a high chance to stun the target for a turn.'
                                    ]
                                ];
                                
                                @hovered = 0;
                                windowEvent.queueChoices(
                                    prompt: 'Use where?',
                                    choices : [
                                        'Aim for the head',
                                        'Aim for the body',
                                        'Aim for the limbs',
                                    ],
                                    canCancel: true,
                                    topWeight: 0.2,
                                    leftWeight: 0.5,
                                    onHover ::(choice) {
                                        hovered = choice-1;
                                    },
                                    renderable : {
                                        render :: {
                                            canvas.renderTextFrameGeneral(
                                                topWeight: 0.7,
                                                leftWeight: 0.5,
                                                lines : text[hovered]
                                            );
                                        }
                                    },
                                    onChoice::(choice) {
                                        onDone(
                                            which:match(choice) {
                                              (1): Entity.DAMAGE_TARGET.HEAD,
                                              (2): Entity.DAMAGE_TARGET.BODY,
                                              (3): Entity.DAMAGE_TARGET.LIMBS
                                            }
                                        );
                                    }
                                );
                            }
                          
                            windowEvent.queueChoices(
                              leftWeight: 1,
                              topWeight: 1,
                              prompt: 'Against whom?',
                              choices: allNames,
                              canCancel: true,
                              keep: true,
                              onChoice::(choice) {
                                when(choice == 0) empty;
                                
                                if (ability.targetMode == Ability.TARGET_MODE.ONEPART) ::<= {
                                    chooseOnePart(onDone::(which){
                                        commitAction(action:
                                            BattleAction.new(
                                                ability: ability,
                                                targets: [all[choice-1]],
                                                targetParts: [which],
                                                extraData: {}
                                            )                                    
                                        )
                                    });
                                } else ::<= {
                                    commitAction(action:
                                        BattleAction.new(
                                            ability: ability,
                                            targets: [all[choice-1]],
                                            targetParts: [Entity.normalizedDamageTarget()],
                                            extraData: {}
                                        )
                                    );
                                }
                              }
                            );
                            
                          },
                          (Ability.TARGET_MODE.ALLALLY): ::<={
                            commitAction(action:
                                BattleAction.new(
                                    ability: ability,
                                    targets: allies,
                                    targetParts: [...allies]->map(to:::(value) <- Entity.normalizedDamageTarget()),                                    
                                    extraData: {}
                                )
                            );                          
                          },
                          (Ability.TARGET_MODE.ALLENEMY): ::<={
                            commitAction(action:
                                BattleAction.new(
                                    ability: ability,
                                    targets: enemies,
                                    targetParts: [...enemies]->map(to:::(value) <- Entity.normalizedDamageTarget()),                                    
                                    extraData: {}                                
                                )
                            );
                          },

                          (Ability.TARGET_MODE.ALL): ::<={
                            commitAction(action:
                                BattleAction.new(
                                    ability: ability,
                                    targets: [...allies, ...enemies],
                                    targetParts: [...allies, ...enemies]->map(to:::(value) <- Entity.normalizedDamageTarget()),                                    
                                    extraData: {}                                
                                )
                            );
                          },



                          (Ability.TARGET_MODE.NONE): ::<={
                            commitAction(action:
                                BattleAction.new(
                                    ability: ability,
                                    targets: [],
                                    targetParts : [],
                                    extraData: {}                                
                                )
                            );
                          },

                          (Ability.TARGET_MODE.RANDOM): ::<={
                            @all = [];
                            foreach(allies)::(index, ally) {
                                all->push(value:ally);
                            }
                            foreach(enemies)::(index, enemy) {
                                all->push(value:enemy);
                            }
                
                            commitAction(action:
                                BattleAction.new(
                                    ability: ability,
                                    targets: random.pickArrayItem(list:all),
                                    extraData: {}                                
                                )
                            );
                          }
                        }                    
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
                    'Abilities',
                    'Allies',
                    'Enemies'
                  ],
                  onChoice::(choice) {
                    when(choice == 0) empty;

                    match(choice-1) {
                      (0): ::<={ // abilities
                        @:names = [...user.abilitiesAvailable]->map(to:::(value){return value.name;});
                        
                        windowEvent.queueChoices(
                          leftWeight: 1,
                          topWeight: 1,
                          prompt: 'Check which ability?',
                          choices: names,
                          keep: true,
                          canCancel: true,
                          onChoice::(choice) {
                            when(choice == 0) empty;
                                
                            @:ability = user.abilitiesAvailable[choice-1];

                            windowEvent.queueMessage(
                                speaker: 'Ability: ' + ability.name,
                                text:ability.description
                            );                          
                          }
                        );
                      },
                      
                      (1): ::<={ // allies
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
                        ability: Ability.find(id:'base:wait'),
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
        ),
        
        pray : InteractionMenuEntry.new(
            name : 'Pray',
            filter::(user, battle) <- true,
            onSelect::(user, battle, commitAction) {

                @:allies  = battle.getAllies(entity:user);
                @:enemies = battle.getEnemies(entity:user);
                
                commitAction(action:
                    BattleAction.new(
                        ability: Ability.find(id:'base:wyvern-prayer'),
                        targets: [...enemies, ...allies],
                        extraData: {}
                    )                
                );             
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
                        windowEvent.jumpToTag(name:'MainMenu');
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
                                        from: opener,
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
                        firstAwake.useAbility(
                            ability:action.ability,
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
