@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:world = import(module:'game_singleton.world.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:party = import(module:'game_singleton.world.mt').party;
@:random = import(module:'game_singleton.random.mt');


return ::(user, item, inBattle) {
    when(item.material == empty) ::<= {
        windowEvent.queueMessage(
            text: 'Only items with a specified material can be improved.'
        );                                                                                            
    }
    
    
    @:StatSet = import(module:'game_class.statset.mt'); 
    if (! party.isMember(entity:user)) ::<= {
        windowEvent.queueMessage(
            text: item.name + ' can only be improved if they\'re in the party.'
        );                                                                        
    }
    if (inBattle == true) ::<= {
        @:complainer = random.pickArrayItem(list:party.members->filter(by::(value) <- value != user));
        @:Personality = import(module:'game_database.personality.mt');
        @:personality = complainer.personality;
        windowEvent.queueMessage(
            speaker: complainer.name,
            text: '"' + random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.INAPPROPRIATE_TIME]) + '"'
        );                        
    }
    
    when(item.improvementsLeft == 0) ::<= {
        windowEvent.queueMessage(
            text: item.name + ' cannot be improved any further.'
        );                                                
    }
    
    windowEvent.queueMessage(
        text: item.name + ' can be improved by attempting to combine it with another item of the same material. Once the process is complete, the other item is lost, and this item is improved.'
    );
    
    windowEvent.queueAskBoolean(
        prompt:'Improve ' + item.name + '?',
        onChoice::(which) {
        
            when(which == false) empty;                     
            @:others = party.inventory.items->filter(by:::(value) <- value.material == item.material && value != item);
            when(others->keycount == 0) ::<= {
                windowEvent.queueMessage(
                    text: 'The party has no other items that are of the material ' + item.material.name
                );
            }
                            
            @:statChoices = [
                'ATK',
                'INT',
                'DEF',
                'SPD',
                'DEX'
            ];               
            windowEvent.queueChoices(
                prompt: 'Choose a stat to improve.',
                choices: [...statChoices]->map(to:::(value)<- value + ' (' + item.equipMod[value] + '%)'),
                canCancel: true,
                onChoice::(choice) {
                    when(choice == 0) empty;
                    @stat = statChoices[choice-1];
                    windowEvent.queueChoices(
                        prompt: 'Choose an item to use.',
                        choices:[...others]->map(to:::(value) <- value.name),
                        canCancel:true,
                        onChoice::(choice) {
                            when (choice == 0) empty;
                            
                            @:other = others[choice-1];
                            windowEvent.queueMessage(
                                text: 'Once complete, this will destroy ' + other.name + '.'
                            );
                            
                            windowEvent.queueAskBoolean(
                                prompt: 'Use ' + other.name + ' to improve ' + item.name + '?',
                                onChoice::(which) {
                                    when(which == false) empty;                     
                                    
                                    @:tryImprove::{
                                        when(random.try(percentSuccess:85)) ::<= {
                                            windowEvent.queueMessage(
                                                text:'Looks like it needs more work...'
                                            );
                                            windowEvent.queueAskBoolean(
                                                prompt: 'Try again?',
                                                onChoice::(which) {
                                                    when(which == false) empty;
                                                    tryImprove();
                                                }
                                            );
                                        }
                                        
                                        party.inventory.remove(item:other);
                                        
                                        
                                        if (random.try(percentSuccess:90)) ::<= {
                                            // success
                                            windowEvent.queueMessage(
                                                text: 'The improvement was successful!'
                                            );                                              
                                            world.accoladeIncrement(name:'itemImprovements');                                        
                                            
                                            @:oldStats = item.equipMod;
                                            @:newStats = StatSet.new();
                                            @:state = oldStats.save();
                                            state[stat] += 8;
                                            state[random.pickArrayItem(list:statChoices)] -= 4;
                                            
                                            newStats.load(serialized:state);
                                            item.improvementsLeft-=1;
                                            
                                            oldStats.printDiffRate(
                                                other:newStats,
                                                prompt: 'New stats: ' + item.name
                                            );
                                            
                                            item.equipMod.load(serialized:newStats.save());
                                            
                                            if (item.equippedBy != empty) ::<= {
                                                @:oldStats = StatSet.new();
                                                @equiper = item.equippedBy;
                                                oldStats.load(serialized:equiper.stats.save());
                                                
                                                @slot = equiper.unequipItem(item, silent:true);
                                                equiper.equip(item, slot, silent:true);
                                                
                                                oldStats.printDiff(
                                                    other: equiper.stats,
                                                    prompt: equiper.name + ': New stats'
                                                )
                                            }   
                                                
                                        } else ::<= {
                                            windowEvent.queueMessage(
                                                text: 'The improvement was unsuccessful...'
                                            );                                                
                                        }
                                        
                                    }
                                    
                                    
                                    tryImprove();
                                }
                            );
                        }
                    );                                
                }
            
            );
        }
    );
}
