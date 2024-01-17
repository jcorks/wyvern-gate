@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'game_class.database.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Battle = import(module:'game_class.battle.mt');
@:random = import(module:'game_singleton.random.mt');
@:Material = import(module:'game_database.material.mt');
@:Profession = import(module:'game_mutator.profession.mt');
@:Item = import(module:'game_mutator.item.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:Personality = import(module:'game_class.personality.mt');
@:Damage = import(module:'game_class.damage.mt');


@:PersonInteraction = Database.new(
    name : 'Wyvern.PersonInteraction',
    attributes : {
        name : String,
        displayName : String,
        onInteract : Function
    }
);




PersonInteraction.newEntry(
    data : {
        name : 'barter',
        displayName : 'Barter',
        onInteract ::(this, location) {
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
    }
)


PersonInteraction.newEntry(
    data : {
        name : 'hire',
        displayName : 'Hire',
        onInteract ::(this, location) {
            when(this.isIncapacitated())
                windowEvent.queueMessage(
                    text: this.name + ' is not currently able to talk.'
                );                                                        
            @:world = import(module:'game_singleton.world.mt');
            @:party = world.party;


            when(party.isMember(entity:this))
                windowEvent.queueMessage(
                    text: this.name + ' is already a party member.'
                );                
          
            when (party.members->keycount >= 3 || !this.adventurous)
                windowEvent.queueMessage(
                    speaker: this.name,
                    text: random.pickArrayItem(list:this.personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_DENY])
                );                
                
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
            
            if (highestStat <= 10)
                cost = 50+((this.stats.sum/3 + this.level)*2.5)->ceil
            else
                cost = 200 + this.stats.sum*13; // bigger and better stats come at a premium
            this.describe();

            windowEvent.queueAskBoolean(
                prompt: 'Hire for ' + cost + 'G?',
                onChoice::(which) {
                    when(which == false) empty;
                    when(party.inventory.gold < cost)
                        windowEvent.queueMessage(
                            text: 'The party cannot afford to hire ' + this.name
                        );                
                        
                    party.inventory.subtractGold(amount:cost);
                    party.add(member:this);
                        windowEvent.queueMessage(
                            text: this.name + ' joins the party!'
                        );     
                    world.accoladeIncrement(name:'recruitedCount');                                        
                    // the location is the one that has ownership over this...
                    if (this.owns != empty)
                        this.owns.ownedBy = empty;
                        
                    if (onHire) onHire();           

                }
            );        
        }
    }
)
    
    
PersonInteraction.newEntry(
    data : {
        name : 'aggress',
        displayName: 'Aggress...',
        onInteract::(this, location) {
            @whom;

            @:world = import(module:'game_singleton.world.mt');
            @:party = world.party;


                
            // some actions result in a confrontation        
            @:confront ::{
                windowEvent.queueMessage(
                    speaker: this.name,
                    text:'"What are you doing??"'
                );

                if (location != empty) ::<= {
                    location.landmark.peaceful = false;
                    windowEvent.queueMessage(text:'The people here are now aware of your aggression.');
                }

                world.battle.start(
                    party,                            
                    allies: [whom],
                    enemies: [this],
                    landmark: {},
                    onEnd::(result) {
                        when(!world.battle.partyWon())
                            windowEvent.jumpToTag(name:'MainMenu');
                        finish();
                    }
                );                  
            }
            
            
            @:aggress = ::{
                windowEvent.queueChoices(
                    prompt: whom.name + ' - Aggressing ' + this.name,
                    choices: ['Attack', 'Steal'],
                    canCancel: true,
                    onChoice::(choice) {
                        when(choice == 0) empty;
                        @:aggressChoice = choice;
                        
                        
                        // when fighting the person
                        @:aggressAttack :: {
                            windowEvent.queueMessage(
                                text: whom.name + ' attacks ' + this.name + '!'
                            );

                            @hp = this.hp;
                            whom.attack(
                                target:this,
                                amount:whom.stats.ATK * (0.5),
                                damageType : Damage.TYPE.PHYS,
                                damageClass: Damage.CLASS.HP
                            );                        
                            
                            when (hp > 0 && this.isIncapacitated()) ::<= {
                                windowEvent.queueMessage(
                                    text:this.name + ' silently went down without anyone noticing.'
                                );
                            };
                            
                            when(this.isIncapacitated())
                                empty
                        
                            confront();                                       
                        }


                        // when fighting the person
                        @:aggressSteal :: {
                            windowEvent.queueMessage(
                                text: whom.name + ' attempts to steal from ' + this.name + '.'
                            );

                            @:stealSuccess ::{
                                @:item = this.inventory.items[0];
                                windowEvent.queueMessage(
                                    text: whom.name + ' steals ' + correctA(word:item.name) + ' from ' + this.name + '.'
                                );                                                                                                 
                                world.accoladeEnable(name:'hasStolen');
                                world.party.karma -= 100;
                                this.inventory.remove(item);
                                party.inventory.add(item);                                
                            }

                            // whoops always successful
                            when (this.isIncapacitated()) ::<= {
                                when (this.inventory.isEmpty) ::<= {
                                    windowEvent.queueMessage(
                                        text: this.name + ' had nothing on their person.'
                                    );                
                                }
                                stealSuccess();
                            }


                            @success;                                            
                            @diffpercent = (whom.stats.DEX - this.stats.DEX) / this.stats.DEX;
                            
                            if (diffpercent > 0) ::<= {
                                if (diffpercent > .9)
                                    diffpercent = 0.95;
                                
                            } else ::<= {
                                diffpercent = 1 - diffpercent->abs;
                                if (diffpercent < 0.2)
                                    diffpercent = 0.2;
                            }
                            success = random.try(percentSuccess:diffpercent*100);
                            
                            
                            
                            if (success) ::<= {                                
                                stealSuccess();
                                windowEvent.queueMessage(
                                    text: whom.name + ' went unnoticed.'
                                );
                            } else ::<= {
                                windowEvent.queueMessage(
                                    text: this.name + ' noticed ' + whom.name + '\'s actions!'
                                );
                                confront();
                            }              
                        }
                        
                        match(choice-1) {
                          (0): aggressAttack(),
                          (1): aggressSteal()
                        }
                    }
                )
            }
            
            windowEvent.queueMessage(text:'Who will be aggressing?');
            @:choices = [...world.party.members]->map(to:::(value) <- value.name);
            windowEvent.queueChoices(
                choices,
                prompt: 'Pick someone.',
                canCancel: true,
                onChoice::(choice) {
                    when(choice == 0) empty;
                    whom = world.party.members[choice-1];
                    
                    aggress();
                }
            )                            
        }
    }
)


return PersonInteraction;
