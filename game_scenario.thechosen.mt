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
@:InteractionMenuEntry = import(module:'game_struct.interactionmenuentry.mt');
@:commonInteractions = import(module:'game_singleton.commoninteractions.mt');
@:Personality = import(module:'game_database.personality.mt');
@:g = import(module:'game_function.g.mt');
@:Accolade = import(module:'game_struct.accolade.mt');


@:interactionsPerson = [
    commonInteractions.person.barter,

    InteractionMenuEntry.new(
        displayName: 'Hire',
        filter ::(entity)<- true, // everyone can barter,
        onSelect ::(entity) {
            @:this = entity;
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
                prompt: 'Hire for ' + g(g:cost) + '?',
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
                        

                }
            );  
        }
    ),

    InteractionMenuEntry.new(
        displayName: 'Aggress',
        filter ::(entity)<- true, // everyone can barter,
        onSelect::(entity) {
            @:this = entity;
            @whom;

            @:world = import(module:'game_singleton.world.mt');
            @:party = world.party;


                
            // some actions result in a confrontation        
            @:confront ::{
                windowEvent.queueMessage(
                    speaker: this.name,
                    text:'"What are you doing??"'
                );

                @:instance = import(module:'game_singleton.instance.mt');
                instance.landmark.peaceful = false;
                windowEvent.queueMessage(text:'The people here are now aware of your aggression.');

                world.battle.start(
                    party,                            
                    allies: [whom],
                    enemies: [this],
                    landmark: {},
                    onEnd::(result) {
                        when(!world.battle.partyWon())
                            windowEvent.jumpToTag(name:'MainMenu');
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
    )                    
];







return {
    name : 'The Chosen',
    onBegin ::(data) {
        @:instance = import(module:'game_singleton.instance.mt');
        @:story = import(module:'game_singleton.story.mt');
        @world = import(module:'game_singleton.world.mt');
        @:LargeMap = import(module:'game_singleton.largemap.mt');
        @party = world.party;            
    
            //story.tier = 2;
        @:keyhome = Item.new(
            base: Item.database.find(name:'Wyvern Key')
        );
        keyhome.name = 'Wyvern Key: Home';
        
        
        keyhome.setIslandGenAttributes(
            nameHint:namegen.island(), 
            levelHint:story.levelHint,
            tierHint: 0    
        )
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

            /*
            @:pan = Item.new(
                base:Item.database.find(name:'Frying Pan'),
                materialHint: 'Crystal',
                qualityHint: 'Divine',
                rngEnchantHint: true
            );
            party.inventory.add(item:pan);
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
    onNewDay ::(data){},
    
    onResume ::(data) {
        @:instance = import(module:'game_singleton.instance.mt');
        instance.visitIsland(restorePos:true);                
    },
    
    onDeath ::(data, entity) {
        @:world = import(module:'game_singleton.world.mt');
        world.party.remove(member:entity);        
    },
    
    interactionsPerson : interactionsPerson,
    interactionsLocation : [],
    interactionsLandmark : [],
    interactionsWalk : [
        commonInteractions.walk.check,
        commonInteractions.walk.lookAround,
        commonInteractions.walk.party,
        commonInteractions.walk.wait
    ],
    interactionsBattle : [
        commonInteractions.battle.act,
        commonInteractions.battle.check,
        commonInteractions.battle.item,
        commonInteractions.battle.wait,
        commonInteractions.battle.pray
    ],
    interactionsOptions : [
        commonInteractions.options.save,
        commonInteractions.options.system,
        commonInteractions.options.quit
    ],
    
    accolades :[
        Accolade.new(
            message : 'The true Chosen.',
            info: 'Accepted the Wyvern of Light\'s quest.',
            condition::(world)<- world.accoladeEnabled(name:'acceptedQuest')
        ),
        
        Accolade.new(
            message: 'Let\'s be friends?',
            info: 'Visited at least one of the Wyverns after fighting.',
            condition::(world)<- world.accoladeEnabled(name:'wyvernsRevisited')
        ),
        
        Accolade.new(
            message: 'I\'d buy that for a dollar! Barely.',
            info: 'Bought a worthless item.',
            condition ::(world)<- world.accoladeEnabled(name:'boughtWorthlessItem')
        ),
        
        Accolade.new(
            message: 'You know, there were some pretty powerful people you didn\'t have in your party that would have made your quest a lot easier. Good job!',
            info: 'Didn\'t recruit an over-powered party member.',
            condition ::(world)<- world.accoladeEnabled(name:'recruitedOPNPC') == false
        ),
        
        Accolade.new(
            message: "Not-so-thrifty spender!",
            info: 'Bought an item worth over 2000G.',
            condition::(world)<- world.accoladeEnabled(name:'boughtItemOver2000G')
        ),
        
        Accolade.new(
            message: 'Where did you find that thing?',
            info: 'Sold an item worth over 500G.',
            condition::(world)<- world.accoladeEnabled(name:'soldItemOver500')
        ),
        
        Accolade.new(
            message: "No really, where did you find that thing?",
            info : 'Sold a worthless item.',
            condition::(world)<- world.accoladeEnabled(name:'soldWorthlessItem')
        ),
        
        Accolade.new(
            message: "Lucky, lucky!",
            info : 'Won a gambling game.',
            condition::(world)<- world.accoladeEnabled(name:'wonGamblingGame')        
        ),
        
        Accolade.new(
            message: "Honestly, the Arena is a little brutal...",
            info : 'Won an Arena bet.',
            condition::(world)<- world.accoladeEnabled(name:'wonArenaBet')
        ),
        
        Accolade.new(
            message: "My pockets feel lighter...",
            info: 'Stole an item at least once.',
            condition::(world)<- world.accoladeEnabled(name:'hasStolen')
        ),
        
        Accolade.new(
            message: "Should have kicked them out a while ago.",
            info: 'Fought a drunkard at the tavern.',
            condition::(world)<- world.accoladeEnabled(name:'foughtDrunkard')
        ),
        
        Accolade.new(
            message: "Property destruction is hard sometimes.",
            info: 'Attempted to vandalize a location.',
            condition::(world)<- world.accoladeEnabled(name:'hasVandalized')
        ),
        
        Accolade.new(
            message: "I guess it wasn't that important...",
            info: 'Somehow got rid of a Wyvern Key.',
            condition::(world)<- world.accoladeEnabled(name:'gotRidOfWyvernKey')
        ),
        
        Accolade.new(
            message: "The traps were kind of fun to setup, to be honest.",
            info: 'Fell for a trap over 5 times.',
            condition::(world)<- world.accoladeCount(name:'trapsFallenFor') > 5
        ),
        
        Accolade.new(
            message: "Two's company but three's a crowd! ...Assuming no one died.",
            info: 'Recruited a party member.',
            condition::(world)<- world.accoladeCount(name:'recruitedCount') > 0
        ),
        
        Accolade.new(
            message: "Top-notch boxer.",
            info: 'Knocked out over 40 people.',
            condition::(world)<- world.accoladeCount(name:'knockouts') > 40
        ),
        
        Accolade.new(
            message: "You're so nice and not murder-y!",
            info: 'Managed to get through without murdering anyone.',
            condition::(world)<- world.accoladeCount(name:'murders') == 0
        ),
        
        Accolade.new(
            message: "A trustworthy friend.",
            info: 'Managed to get through without losing a party member.',
            condition::(world)<- world.accoladeCount(name:'deadPartyMembers') == 0
        ),
        
        Accolade.new(
            message: "Tinkerer!",
            info: 'Improved an items over 5 times.',
            condition::(world)<- world.accoladeCount(name:'itemImprovements') > 5
        ),
        
        Accolade.new(
            message: "Someone was thirsty I guess.",
            info: 'Took over 15 drinks at a tavern.',
            condition::(world)<- world.accoladeCount(name:'drinksTaken') > 15
        ),
        
        Accolade.new(
            message: "Goody-two-shoes!",
            info: 'Generally was nice and avoided doing bad stuff too often.',
            condition::(world)<- world.party.karma > 5000
        ),
        
        Accolade.new(
            message: "Smart fella.",
            info: 'Gained intuition over 5 times.',
            condition::(world)<- world.accoladeCount(name:'intuitionGained') > 5
        ),
        
        Accolade.new(
            message: "Thrifty spender!",
            info: 'Bought over 20 items.',
            condition::(world)<- world.accoladeCount(name:'buyCount') > 20
        ),
        
        Accolade.new(
            message: "Easy money.",
            info: 'Sold over 20 items.',
            condition::(world)<- world.accoladeCount(name:'sellCount') > 20
        ),
        
        Accolade.new(
            message: "Someone likes Roman numerals.",
            info: 'Enchanted items over 5 times.',
            condition::(world)<- world.accoladeCount(name:'enchantmentsReceived') > 5
        ),
        
        Accolade.new(
            message: "Well, that was a waste of time.",
            info: 'Took less than 10 days.',
            condition::(world)<- world.accoladeCount(name:'daysTaken') < 10
        ),
        
        Accolade.new(
            message: "Finders, keepers!",
            info: 'Opened more than 15 chests.',
            condition::(world)<- world.accoladeCount(name:'chestsOpened') > 15
        )
    ],
    
    reportCard :: {
        @:world = import(module:'game_singleton.world.mt');
        return 
            'Knockouts:          ' + world.accoladeCount(name:'knockouts') + '\n' +
            'Murders:            ' + world.accoladeCount(name:'murders') + '\n' +
            'Party members lost: ' + world.accoladeCount(name:'deadPartyMembers') + '\n' +
            'Chests opened:      ' + world.accoladeCount(name:'chestsOpened') + '\n';
        
    },
    
    databaseOverrides ::{
        @:Interaction = import(module:'game_database.interaction.mt');
        
        // replace with key.
        Interaction.newEntry(
            data : {
                displayName : 'Explore Pit',
                name : 'explore pit',
                onInteract ::(location, party) {
                    @:world = import(module:'game_singleton.world.mt');
                    @:Event = import(module:'game_mutator.event.mt');

                    if (location.contested == true) ::<= {
                        @:event = Event.new(
                            base:Event.database.find(name:'Encounter:TreasureBoss'),
                            currentTime:0, // TODO,
                            parent:location.landmark
                        );  
                        location.contested = false;
                    } else ::<= {
                        if (location.targetLandmark == empty) ::<={
                            @:Landmark = import(module:'game_mutator.landmark.mt');
                            

                            location.targetLandmark = 
                                location.landmark.island.newLandmark(
                                    base:Landmark.database.find(name:'Treasure Room')
                                )
                            ;
                            location.targetLandmarkEntry = location.targetLandmark.getRandomEmptyPosition();
                        }
                        @:instance = import(module:'game_singleton.instance.mt');

                        instance.visitLandmark(landmark:location.targetLandmark, where:location.targetLandmarkEntry);


                        canvas.clear();
                    }
                },
            }
        )            
    }        
    
}