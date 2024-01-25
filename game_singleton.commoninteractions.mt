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
@:databaseItemMutatorClass = import(module:'game_function.databaseitemmutatorclass.mt');


return {
    options : {
        quit : InteractionMenuEntry.new(
            displayName : 'Quit',
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
            displayName : 'Save',
            filter ::(island, landmark) <- landmark == empty,
            onSelect::(island, landmark) {
                @:instance = import(module:'game_singleton.instance.mt');
                instance.savestate();
                @:world = import(module:'game_singleton.world.mt');
                windowEvent.queueMessage(text:'Successfully saved world ' + world.saveName);                        
            }
        ),
        
        system : InteractionMenuEntry.new(
            displayName: 'System',
            filter ::(island, landmark) <- true,
            onSelect::(island, landmark) {
            
            }
        )
    },
    walk : {
        check : InteractionMenuEntry.new(
            displayName : 'Check',
            filter::(island, landmark) <- landmark == empty,
            onSelect::(island, landmark) {
                windowEvent.queueMessage(speaker: 'About ' + island.name, text: island.description)
            }
        ),
        
        lookAround : InteractionMenuEntry.new(
            displayName : 'Look around',
            filter::(island, landmark) <- landmark == empty,
            onSelect::(island, landmark) {
                island.incrementTime();
                                
                windowEvent.queueMessage(text:'You look around, but fail to find anything of note.');                          
            }
        ),
        
        party : InteractionMenuEntry.new(
            displayName : 'Party',
            filter::(island, landmark) <- true,
            onSelect::(island, landmark) {
                (import(module:'game_function.partyoptions.mt'))();
            }
        ),
        
        wait : InteractionMenuEntry.new(
            displayName : 'Wait',
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
            displayName: 'Barter',
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
