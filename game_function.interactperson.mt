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

@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:random = import(module:'game_singleton.random.mt');
@:Personality = import(module:'game_class.personality.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:Battle = import(module:'game_class.battle.mt');
@:Damage = import(module:'game_class.damage.mt');


// interacts with this entity
return ::(this, party, location, onDone, overrideChat, skipIntro, onHire) {
    @:world = import(module:'game_singleton.world.mt');
    
    @:finish ::{
        if (onDone != empty)
            onDone();
        windowEvent.jumpToTag(name:'InteractPerson', goBeforeTag:true, doResolveNext:true);
    }
    
    
    
    
    if (skipIntro == empty) 
        if (this.isIncapacitated())
            if (this.isDead) 
                windowEvent.queueMessage(
                    text: this.name + ' appears dead.'
                )                
            else                            
                windowEvent.queueMessage(
                    text: this.name + ' appears unconscious.'
                )                
        else                    
            windowEvent.queueMessage(
                speaker: this.name,
                text: random.pickArrayItem(list:this.personality.phrases[Personality.SPEECH_EVENT.GREET])
            )
    ;                
        
    windowEvent.queueChoices(
        canCancel : true,
        prompt: 'Talking to ' + this.name,
        choices: [
            'Chat',
            'Hire',
            'Barter',
            'Aggress...'
        ],
        keep: true,
        onLeave :onDone,
        canCancel: true,
        jumpTag: 'InteractPerson',
        onChoice::(choice) {
    
            when(choice == 0) empty;
            
            match(choice-1) {
              // Chat
              (0): ::<= {
                when(this.isIncapacitated())
                    windowEvent.queueMessage(
                        text: this.name + ' is not currently able to chat.'
                    );                                                        
                    


                world.party.karma += 1;
                when (overrideChat) overrideChat();
                
                 
                windowEvent.queueMessage(
                    speaker: this.name,
                    text: random.pickArrayItem(list:this.personality.phrases[Personality.SPEECH_EVENT.CHAT])
                );                                                        
              },
              
              // hire 
              (1): ::<= {
                when(this.isIncapacitated())
                    windowEvent.queueMessage(
                        text: this.name + ' is not currently able to talk.'
                    );                                                        


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

                @:cost = 50+((this.stats.sum/3 + this.level)*2.5)->ceil;


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
              },
              
              // barter
              (2):::<= {
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
              },
              // Aggress
              (3):::<= {
                @whom;
                    
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
                            when(result == Battle.RESULTS.ENEMIES_WIN)
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
        }
    );  
};
