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
@:InteractionMenuEntry = import(module:'game_struct.interactionmenuentry.mt');
@:commonInteractions = import(module:'game_singleton.commoninteractions.mt');
@:Personality = import(module:'game_database.personality.mt');
@:g = import(module:'game_function.g.mt');
@:Accolade = import(module:'game_struct.accolade.mt');
@:loading = import(module:'game_function.loading.mt');
@:romanNum = import(module:'game_function.romannumerals.mt');

@:interactionsPerson = [
    commonInteractions.person.barter,

    InteractionMenuEntry.new(
        name: 'Hire',
        keepInteractionMenu: true,
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
        name: 'Aggress',
        keepInteractionMenu: true,
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
    id : 'rasa:thechosen',
    onBegin ::(data) {
        @:instance = import(module:'game_singleton.instance.mt');
        @:story = import(module:'game_singleton.story.mt');
        @world = import(module:'game_singleton.world.mt');
        @:LargeMap = import(module:'game_singleton.largemap.mt');
        @party = world.party;            
    
        @:keyhome = Item.new(
            base: Item.database.find(id:'base:wyvern-key')
        );
        keyhome.name = 'Wyvern Key: Home';
        
    
        // Whether the initial box has been opened.
        world.scenario.data.openedSentimentalBox = false;
    
        // Whether the wyvern of fire was defeated in combat
        world.scenario.data.fireWyvernDefeated = false;

        // Whether the wyvern of ice was defeated in combat
        world.scenario.data.iceWyvernDefeated = false;

        // Whether the wyvern of thunder was defeated in combat
        world.scenario.data.thunderWyvernDefeated = false;

        // Whether the wyvern of light was defeated in combat
        world.scenario.data.lightWyvernDefeated = false;



        
        keyhome.setIslandGenAttributes(
            nameHint:namegen.island(), 
            levelHint:story.levelHint,
            extraLandmarks : [
                'thechosen:shrine-of-fire'
            ],
            tierHint: 0    
        )
        keyhome.addIslandEntry(world);
        instance.visitIsland(noMenu:true, key:keyhome);

        party = world.party;
        party.reset();
        @:island = keyhome.islandEntry;


        
        // debug
            //party.inventory.addGold(amount:100000);

        
        // since both the party members are from this island, 
        // they will already know all its locations
        foreach(keyhome.islandEntry.landmarks)::(index, landmark) {
            landmark.discover(); 
        }
        
        
        
        @:Species = import(module:'game_database.species.mt');
        @:choices = [];
        
        for(0, 5) ::(i) {
            @:p0 = keyhome.islandEntry.newInhabitant(
                speciesHint: Species.getRandomFiltered(filter::(value) <- value.special == false).id,
                levelHint:story.levelHint-1
            );
            p0.normalizeStats();        
            choices->push(value:p0);
        }

        party.inventory.add(item:Item.new(
            base:Item.database.find(id:'thechosen:sentimental-box')
        ));



        // debug
            /*
            //party.inventory.add(item:Item.database.find(id:'Pickaxe'
            //).new(from:island.newInhabitant(),rngEnchantHint:true));
            
            @:story = import(module:'game_singleton.story.mt');
            
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
                base: Item.database.find(id:'Glaive'),
                materialHint: 'Ray',
                qualityHint: '[  ]',
                rngEnchantHint: false
            );

            @:tome = Item.new(
                base:Item.database.find(id:'Tome'),
                materialHint: 'Ray',
                qualityHint: '[  ]',
                rngEnchantHint: false,
                abilityHint: 'Cure'
            );
            party.inventory.add(item:sword);
            party.inventory.add(item:tome);
            */
            

            /*
            @:pan = Item.new(
                base:Item.database.find(id:'Frying Pan'),
                materialHint: 'Crystal',
                qualityHint: 'Divine',
                rngEnchantHint: true
            );
            party.inventory.add(item:pan);
            */


        
        
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


        windowEvent.queueMessage(
            text: 'Before it begins, we must decide who will be venturing on their journey.'
        )

        windowEvent.queueMessage(
            text: 'Who will it be? You may pick 2.'
        );
        

        
        @:extendedName::(entity) {
            return 'the ' + entity.species.name + ' ' + entity.profession.base.name
        }
        
        @:finish ::{
            loading(
                message: 'Saving...',
                do :: {
                    @somewhere = LargeMap.getAPosition(map:island.map);
                    island.map.setPointer(
                        x: somewhere.x,
                        y: somewhere.y
                    );               
                    instance.savestate();
                    @:Scene = import(module:'game_database.scene.mt');
                    Scene.start(id:'thechosen:scene_intro', onDone::{                    
                    //Scene.start(id:'thechosen:scene_wyvernlight1_quest', onDone ::{
                        instance.visitIsland(key:keyhome);                        
                        windowEvent.queueMessage(
                            speaker: party.members[0].name,
                            text: '"I should probably open that box now..."'
                        );
                    });        
                }
            )
        }
    
        @:confirmParty ::{
            windowEvent.queueAskBoolean(
                renderable : {
                    render ::{
                        canvas.renderTextFrameGeneral(
                            topWeight: 0.2,
                            leftWeight: 0.5,
                            lines : [
                                'Current party:',
                                '',                            
                                extendedName(entity:p0),
                                if (p1) extendedName(entity:p1) else ''
                            ]
                        )
                    }
                },
                topWeight: 0.65,
                leftWeight: 0.5,
                prompt: 'Continue with this party?',
                onChoice::(which) {
                    when(which == false) ::<= {
                        p0 = empty;
                        p1 = empty;
                        chooseMember();
                        windowEvent.jumpToTag(name:'ChooseMember', goBeforeTag:true, doResolveNext:true);
                    }
                                        
                    party.add(member:p0);
                    if (p1) party.add(member:p1);
                    finish();
                    windowEvent.jumpToTag(name:'ChooseMember', goBeforeTag:true, doResolveNext:true);
                }
                
            );
        }



        // choose party members
        @hovered;
        @p0;
        @p1;
        
        @whatDoStatsMean ::{
            windowEvent.queueMessage(
                text: 
                    "Stats are the basic qualities that everyone has. They determine the person's ability to face a variety of challenges.\n\n" +
                    "HP - This stat indicates how much a person can withstand before succumbing to a knockout. The higher this stat, the more damage they can withstand.\n\n"+
                    "AP - This stat indicates how often a person can use special abilities. The higher this stat, the more a person can do outside of normal actions.\n\n"+
                    "ATK - This stat measures the physical strength a person possesses. The higher this stat, the more physical damage this person can do to foes.\n\n"+
                    "DEF - This stat measures how a person's body will naturally reduce harm. The higher this stat, the less damage a person will take.\n\n"+
                    "INT - This stat measures the intellect and intuition of a person. The higher this stat, the more a user is aware of the world around them. Certain abilities, such as spells, will benefit from this as well.\n\n"+
                    "SPD - This stat measures how fast a person can move. The higher this stat, the more apt they are at acting before others.\n\n"+
                    "LUK - This stat measures how lucky a person is. The higher this stat, the more a person may get out of difficult situations.\n\n"+
                    "DEX - This stat measures the precision and grace with which a person acts. The higher this stat, the more accurate their actions and the more they avoid danger.\n\n"+
                    "All stats are important, but some stats may be more important at times than others."                    
            );
        };
        

        @:chooseMember ::{
            @:choicesMod = [...choices]->filter(by::(value) <- value != p0);

            @:choiceNames = [...choicesMod]->map(to:::(value) {
                return value.name;
            });

            @:choiceTitles = [...choicesMod]->map(to:::(value) {
                return extendedName(entity:value);  
            });

            if (p0 != empty) ::<= {
                choiceNames->push(value:'No one.');
                choiceTitles->push(value:'');
            }
            @:choicesColumns = import(module:'game_function.choicescolumns.mt');
        
            
            choicesColumns(
                canCancel : true,
                columns : [
                    choiceNames,
                    choiceTitles
                ],
                leftJustified: [
                    true,
                    true
                ],
                topWeight: 0.5,
                leftWeight: 0.5,
                keep:true,
                jumpTag: 'ChooseMember',                
                onCancel ::{
                    if (p0 != empty) p0 = empty;
                    chooseMember();
                },
                
                renderable : {
                    render :: {
                        when(hovered == empty) empty;
                        when (hovered == choicesMod->size) empty

                        canvas.renderTextFrameGeneral(
                            topWeight: 0.5,
                            leftWeight: 1,
                            title: 'Stats',
                            lines: choicesMod[hovered].stats.description->split(token:'\n')
                        );                    
                    }
                },
                onHover::(choice) {
                    hovered = choice-1;
                },
                onChoice::(choice) {
                    when (choice-1 == choicesMod->size) ::<= {
                        windowEvent.queueMessage(
                            text: 'Continuing with only one party member is a bold move. You may find others to join them later, but the journey may be more difficult.'
                        );
                        
                        windowEvent.queueAskBoolean(
                            prompt: 'Continue with just one party member?',
                            onChoice::(which) {
                                when(which == false) empty;
                                confirmParty();
                            }
                        );
                    }
                
                    @:next = choicesMod[choice-1];
                    windowEvent.queueChoices(
                        prompt: extendedName(entity:next),
                        choices : [
                            'Describe',
                            'What do the stats mean?',
                            'Choose',
                        ],
                        canCancel:true,
                        onChoice::(choice) {
                            when(choice-1 == 0)
                                next.describe(excludeStats:true);
                                
                            when(choice-1 == 1)
                                whatDoStatsMean();
                            // choose
                            windowEvent.queueAskBoolean(
                                prompt: 'Add ' + next.name + ' to the party?',
                                onChoice::(which) {
                                    when(which == false) empty;
                                    when (p0 == empty) ::<= {
                                        p0 = next;
                                        chooseMember();
                                        windowEvent.jumpToTag(name:'ChooseMember', goBeforeTag:true, doResolveNext:true);
                                    }
                                    p1 = next;
                                    confirmParty();
                                }
                            );
                        }
                    );
                }        
            )
        }
        chooseMember();
    },
    onNewDay ::(data){},
    
    onResume ::(data) {
        @:instance = import(module:'game_singleton.instance.mt');
        instance.islandTravel();           
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
        commonInteractions.walk.party,
        commonInteractions.walk.inventory,
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
        ),
        
        Accolade.new(
            message: "We're all sentimental creatures, really...",
            info: 'Kept the Sentimental Box.',
            condition::(world) <- world.party.inventory.items->filter(by:
                ::(value) <- value.base.name == 'Sentimental Box'
            )->size > 0
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
                name : 'Explore Pit',
                id : 'base:explore-pit',
                keepInteractionMenu: false,
                onInteract ::(location, party) {
                    @:world = import(module:'game_singleton.world.mt');
                    @:Event = import(module:'game_mutator.event.mt');
                    @:Scene = import(module:'game_database.scene.mt');                        
                    if (location.contested == true) ::<= {
                        Scene.start(
                            id: 'thechosen:scene_keybattle0',
                            onDone::{},
                            location:location,
                            landmark:location.landmark
                        );
                        location.contested = false;
                    } else ::<= {
                        if (location.targetLandmark == empty) ::<={
                            @:Landmark = import(module:'game_mutator.landmark.mt');
                            

                            location.targetLandmark = 
                                location.landmark.island.newLandmark(
                                    base:Landmark.database.find(id:'base:treasure-room')
                                )
                            ;
                            location.targetLandmark.loadContent();
                            location.targetLandmarkEntry = location.targetLandmark.getRandomEmptyPosition();
                        }
                        @:instance = import(module:'game_singleton.instance.mt');

                        instance.visitLandmark(landmark:location.targetLandmark, where::(landmark)<-location.targetLandmarkEntry);


                        canvas.clear();
                    }
                },
            }
        )    
        
        
        
        @:Landmark = import(module:'game_mutator.landmark.mt');
        @:DungeonMap = import(module:'game_singleton.dungeonmap.mt');


        Landmark.database.newEntry(
            data: {
                name : 'Shrine of Fire',
                id : 'thechosen:shrine-of-fire',
                legendName: 'Shrine',
                symbol : 'M',
                rarity : 100000,      
                isUnique : true,
                minLocations : 1,
                maxLocations : 3,
                peaceful: false,
                guarded : false,
                landmarkType : Landmark.database.statics.TYPE.DUNGEON,
                canSave : false,
                pointOfNoReturn : true,
                ephemeral : true,
                dungeonForceEntrance: false,
                startingEvents : [
                    'base:dungeon-encounters',
                    'base:item-specter',
                    'base:the-beast',
                    'base:treasure-golem',
                    'base:cave-bat'
                ],
                possibleLocations : [
        //                    {id: 'Stairs Down', rarity:1},

                    // the standard set
                    {id: 'base:fountain', rarity:18},
                    {id: 'base:potion-shop', rarity: 17},
                    {id: 'base:wyvern-statue', rarity: 15},
                    {id: 'base:small-chest', rarity: 16},
                    {id: 'base:locked-chest', rarity: 11},


                    {id: 'base:healing-circle', rarity:20},


                    {id: 'base:clothing-shop', rarity: 100},
                    {id: 'base:fancy-shop', rarity: 500}

                ],
                requiredLocations : [
                    'base:enchantment-stand',
                    'base:stairs-down',
                    'base:stairs-down'
                ],
                mapHint:{
                    layoutType: DungeonMap.LAYOUT_ALPHA
                },
                onCreate ::(landmark, island){
                },
                onVisit ::(landmark, island) {
                    if (landmark.floor == 0)
                        windowEvent.queueMessage(
                            text:"This place seems to shift before you..."
                        );
                }
                
            }
        )

        Landmark.database.newEntry(
            data: {
                name : 'Shrine of Ice',
                id : 'thechosen:shrine-of-ice',
                legendName: 'Shrine',
                symbol : 'M',
                rarity : 100000,      
                isUnique : true,
                minLocations : 1,
                maxLocations : 4,
                peaceful: false,
                guarded : false,
                landmarkType : Landmark.database.statics.TYPE.DUNGEON,
                canSave : false,
                pointOfNoReturn : true,
                ephemeral : true,
                dungeonForceEntrance: false,
                startingEvents : [
                    'base:dungeon-encounters',
                    'base:item-specter',
                    'base:the-beast',
                    'base:the-mirror',
                    'base:treasure-golem',
                    'base:cave-bat'
                ],
                possibleLocations : [
        //                    {id: 'Stairs Down', rarity:1},
                    {id: 'base:fountain', rarity:18},
                    {id: 'base:potion-shop', rarity: 17},
                    {id: 'base:enchantment-stand', rarity: 11},
                    {id: 'base:wyvern-statue', rarity: 15},
                    {id: 'base:small-chest', rarity: 16},
                    {id: 'base:locked-chest', rarity: 12},
                    {id: 'base:magic-chest', rarity: 15},


                    {id: 'base:healing-circle', rarity:20},
                    {id: 'base:clothing-shop', rarity: 300},
                    {id: 'base:fancy-shop', rarity: 500},
                ],
                requiredLocations : [
                    'base:enchantment-stand',
                    'base:stairs-down',
                    'base:locked-chest'
                    
                ],
                mapHint:{
                    layoutType: DungeonMap.LAYOUT_BETA
                },
                onCreate ::(landmark, island){
                },
                onVisit ::(landmark, island) {
                    if (landmark.floor == 0)
                        windowEvent.queueMessage(
                            text:"This place seems to shift before you..."
                        );
                
                }
                
            }
        )

        Landmark.database.newEntry(
            data: {
                name : 'Shrine of Thunder',
                id : 'thechosen:shrine-of-thunder',
                symbol : 'M',
                legendName: 'Shrine',
                rarity : 100000,      
                isUnique : true,
                minLocations : 2,
                maxLocations : 4,
                peaceful: false,
                guarded : false,
                landmarkType : Landmark.database.statics.TYPE.DUNGEON,
                canSave : false,
                pointOfNoReturn : true,
                ephemeral : true,
                dungeonForceEntrance: false,
                startingEvents : [
                    'base:dungeon-encounters',
                    'base:item-specter',
                    'base:the-beast',
                    'base:the-mirror',
                    'base:treasure-golem',
                    'base:cave-bat'
                ],
                possibleLocations : [
        //                    {id: 'Stairs Down', rarity:1},
                    {id: 'base:fountain', rarity:18},
                    {id: 'base:potion-shop', rarity: 17},
                    {id: 'base:enchantment-stand', rarity: 11},
                    {id: 'base:wyvern-statue', rarity: 15},
                    {id: 'base:small-chest', rarity: 16},
                    {id: 'base:locked-chest', rarity: 11},
                    {id: 'base:magic-chest', rarity: 15},

                    {id: 'base:healing-circle', rarity:25},

                    {id: 'base:clothing-shop', rarity: 80},
                    {id: 'base:fancy-shop', rarity: 100}

                ],
                requiredLocations : [
                    'base:enchantment-stand',
                    'base:stairs-down',
                    'base:locked-chest',
                    'base:small-chest',

                    'base:warp-point',
                    'base:warp-point',
                    'base:warp-point',
                    'base:warp-point'
                ],
                mapHint:{
                    layoutType: DungeonMap.LAYOUT_GAMMA
                },
                onCreate ::(landmark, island){
                },
                onVisit ::(landmark, island) {
                    if (landmark.floor == 0)
                        windowEvent.queueMessage(
                            text:"This place seems to shift before you..."
                        );
                
                }
                
            }
        )


        Landmark.database.newEntry(
            data: {
                name : 'Shrine of Light',
                id : 'thechosen:shrine-of-light',
                symbol : 'M',
                legendName: 'Shrine',
                rarity : 100000,      
                isUnique : true,
                minLocations : 2,
                maxLocations : 4,
                peaceful: false,
                guarded : false,
                landmarkType : Landmark.database.statics.TYPE.DUNGEON,
                canSave : false,
                pointOfNoReturn : true,
                ephemeral : true,
                dungeonForceEntrance: false,
                startingEvents : [
                    'base:dungeon-encounters',
                    'base:item-specter',
                    'base:the-beast',
                    'base:the-mirror',
                    'base:treasure-golem',
                    'base:cave-bat'
                ],
                possibleLocations : [
        //                    {id: 'Stairs Down', rarity:1},
                    {id: 'base:fountain', rarity:18},
                    {id: 'base:potion-shop', rarity: 17},
                    {id: 'base:enchantment-stand', rarity: 11},
                    {id: 'base:wyvern-statue', rarity: 15},
                    {id: 'base:small-chest', rarity: 16},
                    {id: 'base:locked-chest', rarity: 11},
                    {id: 'base:magic-chest', rarity: 15},

                    {id: 'base:healing-circle', rarity:35},

                    {id: 'base:clothing-shop', rarity: 100},
                    {id: 'base:fancy-shop', rarity: 50}

                ],
                requiredLocations : [
                    'base:enchantment-stand',
                    'base:stairs-down',
                    'base:locked-chest',
                    'base:small-chest',
                    
                    'base:warp-point',
                    'base:warp-point',
                    'base:warp-point',
                    'base:warp-point'                    
                ],
                mapHint:{
                    layoutType: DungeonMap.LAYOUT_DELTA
                },
                onCreate ::(landmark, island){
                },
                onVisit ::(landmark, island) {
                    if (landmark.floor == 0)
                        windowEvent.queueMessage(
                            text:"This place seems to shift before you..."
                        );
                
                }
                
            }
        )



        Landmark.database.newEntry(
            data: {
                name : 'Fire Wyvern Dimension',
                id : 'thechosen:fire-wyvern-dimension',
                legendName: '???',
                symbol : 'M',
                rarity : 1,      
                isUnique : true,
                minLocations : 2,
                maxLocations : 2,
                guarded : false,
                peaceful: true,
                landmarkType : Landmark.database.statics.TYPE.DUNGEON,
                canSave : true,
                pointOfNoReturn : false,
                ephemeral : false,
                dungeonForceEntrance: false,
                startingEvents : [
                ],
                possibleLocations : [
                ],
                requiredLocations : [
                    'thechosen:throne-fire',
                ],
                
                mapHint : {
                    roomSize: 20,
                    roomAreaSize: 15,
                    roomAreaSizeLarge: 15,
                    emptyAreaCount: 1,
                    wallCharacter: ' '
                    
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        )        



        Landmark.database.newEntry(
            data: {
                name : 'Ice Wyvern Dimension',
                id : 'thechosen:ice-wyvern-dimension',
                legendName: '???',
                symbol : 'M',
                rarity : 1,      
                isUnique : true,
                minLocations : 2,
                maxLocations : 2,
                guarded : false,
                peaceful: true,
                landmarkType : Landmark.database.statics.TYPE.DUNGEON,
                canSave : true,
                pointOfNoReturn : false,
                ephemeral : false,
                dungeonForceEntrance: false,
                startingEvents : [
                ],
                possibleLocations : [
                ],
                requiredLocations : [
                    'thechosen:throne-ice',
                ],
                
                mapHint : {
                    roomSize: 20,
                    roomAreaSize: 15,
                    roomAreaSizeLarge: 15,
                    emptyAreaCount: 1,
                    wallCharacter: ' '
                    
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        ) 

        Landmark.database.newEntry(
            data: {
                name : 'Thunder Wyvern Dimension',
                id : 'thechosen:thunder-wyvern-dimension',
                legendName: '???',
                symbol : 'M',
                rarity : 1,      
                isUnique : true,
                minLocations : 2,
                maxLocations : 2,
                guarded : false,
                peaceful: true,
                
                canSave : true,
                landmarkType : Landmark.database.statics.TYPE.DUNGEON,
                pointOfNoReturn : false,
                ephemeral : false,
                dungeonForceEntrance: false,
                startingEvents : [
                ],
                possibleLocations : [
                ],
                requiredLocations : [
                    'thechosen:throne-thunder',
                ],
                
                mapHint : {
                    roomSize: 20,
                    roomAreaSize: 15,
                    roomAreaSizeLarge: 15,
                    emptyAreaCount: 1,
                    wallCharacter: ' '
                    
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        ) 


        Landmark.database.newEntry(
            data: {
                name : 'Light Wyvern Dimension',
                id : 'thechosen:light-wyvern-dimension',
                legendName: '???',
                symbol : 'M',
                rarity : 1,      
                isUnique : true,
                minLocations : 2,
                maxLocations : 2,
                guarded : false,
                peaceful: true,
                
                canSave : true,
                landmarkType : Landmark.database.statics.TYPE.DUNGEON,
                pointOfNoReturn : false,
                ephemeral : false,
                dungeonForceEntrance: false,
                startingEvents : [
                ],
                possibleLocations : [
                ],
                requiredLocations : [
                    'thechosen:throne-light',
                ],
                
                mapHint : {
                    roomSize: 20,
                    roomAreaSize: 15,
                    roomAreaSizeLarge: 15,
                    emptyAreaCount: 1,
                    wallCharacter: ' '
                    
                },
                onCreate ::(landmark, island){},
                onVisit ::(landmark, island) {}
                
            }
        ) 




        
        
        @:Location = import(module:'game_mutator.location.mt');
        @:world = import(module:'game_singleton.world.mt');



        Location.database.newEntry(data:{
            name: 'Wyvern Throne of Fire',
            id: 'thechosen:throne-fire',
            rarity: 1,
            ownVerb : 'owned',
            category : Location.database.statics.CATEGORY.RESIDENTIAL,
            symbol: 'W',
            onePerLandmark : true,
            minStructureSize : 1,

            descriptions: [
                "What seems to be a stone throne",
            ],
            interactions : [
                'base:talk',
                'base:examine'
            ],
            
            aggressiveInteractions : [
            ],


            
            minOccupants : 0,
            maxOccupants : 0,
            
            onFirstInteract ::(location) {
            },
            onInteract ::(location) {
                return true;

            },            
            
            onCreate ::(location) {
                location.name = 'Wyvern Throne';
                @:Profession = import(module:'game_mutator.profession.mt');
                @:Species = import(module:'game_database.species.mt');
                @:Story = import(module:'game_singleton.story.mt');
                @:Scene = import(module:'game_database.scene.mt');
                @:StatSet = import(module:'game_class.statset.mt');
                location.ownedBy = location.landmark.island.newInhabitant();
                location.ownedBy.name = 'Wyvern of Fire';
                location.ownedBy.species = Species.find(id:'thechosen:wyvern-of-fire');
                location.ownedBy.profession = Profession.new(base:Profession.database.find(id:'thechosen:wyvern-of-fire'));               
                location.ownedBy.clearAbilities();
                foreach(location.ownedBy.profession.gainSP(amount:10))::(i, ability) {
                    location.ownedBy.learnAbility(id:ability);
                }

                
                location.ownedBy.overrideInteract = ::(party, location, onDone) {
                    if (world.scenario.data.fireWyvernDefeated == false) ::<= {
                        Scene.start(id:'thechosen:scene_wyvernfire0', onDone::{}, location, landmark:location.landmark);
                    } else ::<= {
                        // just visiting!
                        Scene.start(id:'thechosen:scene_wyvernfire1', onDone::{}, location, landmark:location.landmark);                        
                    }
                }
                location.ownedBy.stats.load(serialized:StatSet.new(
                    HP:   150,
                    AP:   999,
                    ATK:  12,
                    INT:  5,
                    DEF:  11,
                    LUK:  8,
                    SPD:  25,
                    DEX:  11
                ).save());
                location.ownedBy.heal(amount:9999, silent:true); 
                location.ownedBy.healAP(amount:9999, silent:true); 

                



            },
            
            onTimeChange::(location, time) {
            
            }
        })


        Location.database.newEntry(data:{
            name: 'Wyvern Throne of Ice',
            id: 'thechosen:throne-ice',
            rarity: 1,
            ownVerb : 'owned',
            category : Location.database.statics.CATEGORY.RESIDENTIAL,
            symbol: 'W',
            onePerLandmark : true,
            minStructureSize : 1,

            descriptions: [
                "What seems to be a stone throne",
            ],
            interactions : [
                'base:talk',
                'base:examine'
            ],
            
            aggressiveInteractions : [
            ],


            
            minOccupants : 0,
            maxOccupants : 0,
            
            onFirstInteract ::(location) {
            },
            onInteract ::(location) {
                return true;

            },            
            
            onCreate ::(location) {
                location.name = 'Wyvern Throne';
                @:Profession = import(module:'game_mutator.profession.mt');
                @:Species = import(module:'game_database.species.mt');
                @:Story = import(module:'game_singleton.story.mt');
                @:Scene = import(module:'game_database.scene.mt');
                @:StatSet = import(module:'game_class.statset.mt');
                location.ownedBy = location.landmark.island.newInhabitant();
                location.ownedBy.name = 'Wyvern of Ice';
                location.ownedBy.species = Species.find(id:'thechosen:wyvern-of-ice');
                location.ownedBy.profession = Profession.new(base:Profession.database.find(id:'thechosen:wyvern-of-ice'));               
                location.ownedBy.clearAbilities();
                foreach(location.ownedBy.profession.gainSP(amount:10))::(i, ability) {
                    location.ownedBy.learnAbility(id:ability);
                }

                
                location.ownedBy.overrideInteract = ::(party, location, onDone) {
                    if (world.scenario.data.iceWyvernDefeated == false) ::<= {
                        Scene.start(id:'thechosen:scene_wyvernice0', onDone::{}, location, landmark:location.landmark);
                    } else ::<= {
                        // just visiting!
                        Scene.start(id:'thechosen:scene_wyvernice1', onDone::{}, location, landmark:location.landmark);                        
                    }
                }
                location.ownedBy.stats.load(serialized:StatSet.new(
                    HP:   230,
                    AP:   999,
                    ATK:  16,
                    INT:  8,
                    DEF:  7,
                    LUK:  6,
                    SPD:  60,
                    DEX:  14
                ).save());
                location.ownedBy.heal(amount:9999, silent:true); 
                location.ownedBy.healAP(amount:9999, silent:true); 

                



            },
            
            onTimeChange::(location, time) {
            
            }
        })


        Location.database.newEntry(data:{
            name: 'Wyvern Throne of Thunder',
            id: 'thechosen:throne-thunder',
            rarity: 1,
            ownVerb : 'owned',
            category : Location.database.statics.CATEGORY.RESIDENTIAL,
            symbol: 'W',
            onePerLandmark : true,
            minStructureSize : 1,

            descriptions: [
                "What seems to be a stone throne",
            ],
            interactions : [
                'base:talk',
                'base:examine'
            ],
            
            aggressiveInteractions : [
            ],


            
            minOccupants : 0,
            maxOccupants : 0,
            
            onFirstInteract ::(location) {
            },
            onInteract ::(location) {
                return true;

            },            
            
            onCreate ::(location) {
                location.name = 'Wyvern Throne';
                @:Profession = import(module:'game_mutator.profession.mt');
                @:Species = import(module:'game_database.species.mt');
                @:Story = import(module:'game_singleton.story.mt');
                @:Scene = import(module:'game_database.scene.mt');
                @:StatSet = import(module:'game_class.statset.mt');
                @:Entity = import(module:'game_class.entity.mt');
                location.ownedBy = location.landmark.island.newInhabitant();
                location.ownedBy.name = 'Wyvern of Thunder';
                location.ownedBy.species = Species.find(id:'thechosen:wyvern-of-thunder');
                location.ownedBy.profession = Profession.new(base:Profession.database.find(id:'thechosen:wyvern-of-thunder'));               
                location.ownedBy.clearAbilities();
                foreach(location.ownedBy.profession.gainSP(amount:10))::(i, ability) {
                    location.ownedBy.learnAbility(id:ability);
                }

                
                location.ownedBy.overrideInteract = ::(party, location, onDone) {
                    @:world = import(module:'game_singleton.world.mt');                            
                    if (world.scenario.data.thunderWyvernDefeated == false) ::<= {
                        Scene.start(id:'thechosen:scene_wyvernthunder0', onDone::{}, location, landmark:location.landmark);
                    } else ::<= {
                        // just visiting!
                        Scene.start(id:'thechosen:scene_wyvernthunder1', onDone::{}, location, landmark:location.landmark);                        
                    }
                }
                location.ownedBy.stats.load(serialized:StatSet.new(
                    HP:   400,
                    AP:   999,
                    ATK:  20,
                    INT:  10,
                    DEF:  10,
                    LUK:  9,
                    SPD:  100,
                    DEX:  16
                ).save());
                location.ownedBy.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
                location.ownedBy.heal(amount:9999, silent:true); 
                location.ownedBy.healAP(amount:9999, silent:true); 

                



            },
            
            onTimeChange::(location, time) {
            
            }
        })


        Location.database.newEntry(data:{
            name: 'Wyvern Throne of Light',
            id: 'thechosen:throne-light',
            rarity: 1,
            ownVerb : 'owned',
            category : Location.database.statics.CATEGORY.RESIDENTIAL,
            symbol: 'W',
            onePerLandmark : true,
            minStructureSize : 1,

            descriptions: [
                "What seems to be a stone throne",
            ],
            interactions : [
                'base:talk',
                'base:examine'
            ],
            
            aggressiveInteractions : [
            ],


            
            minOccupants : 0,
            maxOccupants : 0,
            
            onFirstInteract ::(location) {
            },
            onInteract ::(location) {
                return true;

            },            
            
            onCreate ::(location) {
                location.name = 'Wyvern Throne';
                @:Profession = import(module:'game_mutator.profession.mt');
                @:Entity = import(module:'game_class.entity.mt');
                @:Species = import(module:'game_database.species.mt');
                @:Story = import(module:'game_singleton.story.mt');
                @:Scene = import(module:'game_database.scene.mt');
                @:StatSet = import(module:'game_class.statset.mt');
                location.ownedBy = location.landmark.island.newInhabitant();
                location.ownedBy.name = 'Wyvern of Light';
                location.ownedBy.species = Species.find(id:'thechosen:wyvern-of-light');
                location.ownedBy.profession = Profession.new(base:Profession.database.find(id:'thechosen:wyvern-of-light'));               
                location.ownedBy.clearAbilities();
                foreach(location.ownedBy.profession.gainSP(amount:10))::(i, ability) {
                    location.ownedBy.learnAbility(id:ability);
                }

                
                location.ownedBy.overrideInteract = ::(party, location, onDone) {
                    if (world.scenario.data.lightWyvernDefeated == false) ::<= {
                        Scene.start(id:'thechosen:scene_wyvernlight0', onDone::{}, location, landmark:location.landmark);
                    } else ::<= {
                        // just visiting!
                        Scene.start(id:'thechosen:scene_wyvernlight1', onDone::{}, location, landmark:location.landmark);                        
                    }
                }
                location.ownedBy.stats.load(serialized:StatSet.new(
                    HP:   650,
                    AP:   999,
                    ATK:  30,
                    INT:  17,
                    DEF:  3,
                    LUK:  6,
                    SPD:  100,
                    DEX:  20
                ).save());
                
                location.ownedBy.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
                location.ownedBy.heal(amount:9999, silent:true); 
                location.ownedBy.healAP(amount:9999, silent:true); 

                



            },
            
            onTimeChange::(location, time) {
            
            }
        })




        Location.database.newEntry(data:{
            name: 'Stairs Up',
            id: 'thechosen:stairs-up',
            rarity: 1000000000000,
            ownVerb : '',
            symbol: '\\',
            category : Location.database.statics.CATEGORY.EXIT,
            onePerLandmark : false,
            minStructureSize : 1,

            descriptions: [
                "Decrepit stairs",
            ],
            interactions : [
                'thechosen:darklair-up',
            ],
            
            aggressiveInteractions : [
            ],


            
            minOccupants : 0,
            maxOccupants : 0,
            
            onFirstInteract ::(location) {},
            onInteract ::(location) {
                @open = location.isUnlockedWithPlate();
                if (!open)  
                    windowEvent.queueMessage(text: 'The entry to the stairway is locked. Perhaps some lever or plate nearby can unlock it.');
                return open;            
            },
            
            onCreate ::(location) {
                /*
                if (location.landmark.island.tier > 1) 
                    if (random.flipCoin()) ::<= {
                        location.lockWithPressurePlate();
                    }
                */
            },
            
            onTimeChange::(location, time) {
            
            }
        })


        Location.database.newEntry(data:{
            name: 'Foreboding Entrance',
            id: 'thechosen:foreboding-entrance',
            rarity: 1000000000000,
            ownVerb : '',
            symbol: ' ',
            category : Location.database.statics.CATEGORY.ENTRANCE,
            onePerLandmark : false,
            minStructureSize : 1,

            descriptions: [
                "An entrance to a place that seems to welcome you eerily. It makes you feel uneasy.",
            ],
            interactions : [
                'next floor',
            ],
            
            aggressiveInteractions : [
            ],


            
            minOccupants : 0,
            maxOccupants : 0,
            
            onFirstInteract ::(location) {},
            onInteract ::(location) {
            },
            
            onCreate ::(location) {
                /*
                if (location.landmark.island.tier > 1) 
                    if (random.flipCoin()) ::<= {
                        location.lockWithPressurePlate();
                    }
                */
            },
            
            onTimeChange::(location, time) {
            
            }
        })

        
        
        
        @:Landmark = import(module:'game_mutator.landmark.mt');


        Landmark.database.newEntry(
            data: {
                name : 'Dark Lair',
                id : 'thechosen:dark-lair',
                symbol : 'M',
                legendName: 'Shrine',
                rarity : 100000,      
                isUnique : true,
                minLocations : 0,
                maxLocations : 4,
                peaceful: false,
                guarded : false,
                landmarkType : Landmark.database.statics.TYPE.DUNGEON,
                canSave : false,
                pointOfNoReturn : true,
                ephemeral : true,
                dungeonForceEntrance: false,
                startingEvents : [
                    'base:damned-souls',
                ],
                possibleLocations : [
        //                    {id: 'Stairs Down', rarity:1},
                    {id: 'base:fountain', rarity:18},
                    {id: 'base:potion-shop', rarity: 17},
                    {id: 'base:wyvern-statue', rarity: 15},
                    {id: 'base:small-chest', rarity: 16},
                    {id: 'base:locked-chest', rarity: 11},
                    {id: 'base:magic-chest', rarity: 15},

                    {id: 'base:Healing Circle', rarity:35}

                ],
                requiredLocations : [
                    'base:enchantment-stand',
                    'base:stairs-up',
                    'base:locked-chest',
                    'base:Small-chest'
                ],
                mapHint:{
                    layoutType: DungeonMap.LAYOUT_EPSILON
                },
                onCreate ::(landmark, island){
                },
                onVisit ::(landmark, island) {
                    if (landmark.floor == 0)
                        windowEvent.queueMessage(
                            text:"This place seems to shift before you..."
                        );
                }
            }
        )

        
        Landmark.database.newEntry(
            data : {
                name : 'Dark Lair - Entrance',
                id : 'thechosen:dark-lair-entrance',
                legendName : 'Dark Lair',
                symbol : '#',
                rarity : 100000,
                minLocations : 0,
                maxLocations : 0,
                isUnique : true,
                peaceful : true,
                landmarkType : Landmark.database.statics.TYPE.CUSTOM,
                dungeonForceEntrance: false,
                guarded : false,
                canSave : false,
                pointOfNoReturn : true,
                ephemeral : false,
                startingEvents : [],
                possibleLocations : [
                ],
                requiredLocations : [
                ],
                mapHint : {
                },
                onCreate ::(landmark, island){
                    @:map = landmark.map;
                    map.width = 100;
                    map.height = 60;
                    map.outOfBoundsCharacter = '.'
                    
                    
                    @:CASTLE_MAIN_X = 30;
                    @:CASTLE_MAIN_HEIGHT = 13;
                    @:CASTLE_MAIN_WIDTH = 32;
                    @:CASTLE_WINDOW_HEIGHT = 3;
                    
                    @:CASTLE_EXT_HEIGHT = 18;

                    @:PATH_HEIGHT = 22;



                    // main castle
                    map.paintScenerySolidRectangle(
                        x: CASTLE_MAIN_X,
                        y: 0,
                        width: CASTLE_MAIN_WIDTH,
                        height: CASTLE_MAIN_HEIGHT,
                        symbol : map.addScenerySymbol(
                            character: '▓'
                        ),
                        isWall:true
                    );
                    
                    map.paintScenerySolidRectangle(
                        x: 0,
                        y: 0,
                        width: CASTLE_MAIN_X,
                        height: CASTLE_EXT_HEIGHT,
                        symbol : map.addScenerySymbol(
                            character: '▓'
                        ),
                        isWall:true
                    );
                    
                    map.paintScenerySolidRectangle(
                        x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH,
                        y: 0,
                        width: map.width - (CASTLE_MAIN_X + CASTLE_MAIN_WIDTH)-1,
                        height: CASTLE_EXT_HEIGHT,
                        symbol : map.addScenerySymbol(
                            character: '▓'
                        ),
                        isWall:true
                    );
                    

                    map.paintScenerySolidRectangle(
                        x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH/2 - 2,
                        y: CASTLE_MAIN_HEIGHT - 1,
                        width: 4,
                        height: 1,
                        symbol : map.addScenerySymbol(
                            character: ' '
                        ),
                        isWall:false
                    );
                    
                    @:l = landmark.addLocation(
                        id: 'thechosen:foreboding-entrance',
                        x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH/2 - 2,
                        y: CASTLE_MAIN_HEIGHT - 1,
                        width: 4,
                        height: 1
                    );


                    // castle details 
                    // grows down
                    @:makeWindow ::<= {
                        @:emp = map.addScenerySymbol(character: ' ');
                        return ::(x, y) {
                            map.paintScenerySolidRectangle(
                                x,
                                y,
                                width: 1,
                                height: CASTLE_WINDOW_HEIGHT,
                                symbol: emp,
                                isWall : false
                            );
                        }
                    }

                    @:makeWindowPair::(x, y) {
                        makeWindow(x, y);
                        makeWindow(x:x+2, y);
                    }





                    for(0, 2) ::(y) {

                        for(0, 2) ::(i) {                    
                            makeWindowPair(
                                x: CASTLE_MAIN_X + 1 + i * 5, 
                                y: CASTLE_MAIN_HEIGHT - CASTLE_WINDOW_HEIGHT - 2 - y*(CASTLE_WINDOW_HEIGHT + 2));
                        }

                        for(0, 2) ::(i) {                    
                            makeWindowPair(
                                x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH - 4 - i * 5, 
                                y: CASTLE_MAIN_HEIGHT - CASTLE_WINDOW_HEIGHT - 2 - y*(CASTLE_WINDOW_HEIGHT + 2));
                        }
                    }


                    for(0, 3) ::(y) {
                        for(0, 5) ::(i) {                    
                            makeWindowPair(
                                x: CASTLE_MAIN_X - (1 + 4 + i * 5), 
                                y: CASTLE_EXT_HEIGHT - CASTLE_WINDOW_HEIGHT - 2 - y*(CASTLE_WINDOW_HEIGHT + 2) + 1);
                        }

                        for(0, 5) ::(i) {                    
                            makeWindowPair(
                                x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH + (2 + i * 5), 
                                y: CASTLE_EXT_HEIGHT - CASTLE_WINDOW_HEIGHT - 2 - y*(CASTLE_WINDOW_HEIGHT + 2) + 1);
                        }
                    }







                    // pathway 

                    map.paintScenerySolidRectangle(
                        x: 0,
                        y: CASTLE_EXT_HEIGHT,
                        width: CASTLE_MAIN_X+CASTLE_MAIN_WIDTH/2-2,
                        height: PATH_HEIGHT,
                        symbol : map.addScenerySymbol(
                            character: '.'
                        ),
                        isWall:true
                    );

                    map.paintScenerySolidRectangle(
                        x: CASTLE_MAIN_X+CASTLE_MAIN_WIDTH/2+2,
                        y: CASTLE_EXT_HEIGHT,
                        width: map.width - CASTLE_MAIN_X+CASTLE_MAIN_WIDTH/2-1,
                        height: PATH_HEIGHT,
                        symbol : map.addScenerySymbol(
                            character: '.'
                        ),
                        isWall:true
                    );


                    map.paintScenerySolidRectangle(
                        x: 0,
                        y: CASTLE_EXT_HEIGHT + PATH_HEIGHT,
                        width: map.width-1,
                        height: map.height - (CASTLE_EXT_HEIGHT + PATH_HEIGHT) - 1,
                        symbol : map.addScenerySymbol(
                            character: '.'
                        ),
                        isWall:true
                    );
                    

                    map.paintScenerySolidRectangle(
                        x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH/2 - 5,
                        y: CASTLE_EXT_HEIGHT + PATH_HEIGHT - 3,
                        width: 10,
                        height: 6,
                        symbol : map.addScenerySymbol(
                            character: ' '
                        ),
                        isWall:false
                    );





                        



                    map.setPointer(
                        x: CASTLE_MAIN_X + CASTLE_MAIN_WIDTH / 2,
                        y: CASTLE_EXT_HEIGHT + PATH_HEIGHT
                    );
                    
                    map.paged = false;

                
                },
                onVisit ::(landmark, island) {}                
            }
        );
        
        @:Effect = import(module:'game_database.effect.mt');
        Effect.newEntry(
            data : {
                name : 'Sentimental Box',
                id : 'thechosen:sentimental-box',
                description: 'Opens the box.',
                battleOnly : true,
                skipTurn : false,
                stackable: true,
                blockPoints : 0,
                flags : 0,
                stats: StatSet.new(),
                onAffliction ::(user, item, holder) {
                    Scene.start(id:'thechosen:scene_sentimentalbox', onDone::{});            
                },
                
                onRemoveEffect ::(user, item, holder) {
                },                
                onPostAttackOther ::(user, item, holder, to) {
                },

                onPreAttackOther ::(user, item, holder, to, damage) {
                },
                onAttacked ::(user, item, holder, by, damage) {
                
                },
                
                onSuccessfulBlock::(user, item, holder, from, damage) {
                
                },
                onDamage ::(user, item, holder, from, damage) {
                },
                
                onNextTurn ::(user, item, holder, turnIndex, turnCount) {
                
                },
                onStatRecalculate ::(user, item, holder, stats) {
                
                }
            }
        )



        
        
        
        
        @:Item = import(module:'game_mutator.item.mt'); 

        Item.database.newEntry(data : {
            name : "Sentimental Box",
            id : 'thechosen:sentimental-box',
            description: 'A box of sentimental value. You feel like you should open it right away.',
            examine : '',
            equipType: Item.database.statics.TYPE.TWOHANDED,
            rarity : 100,
            weight : 10,
            canBeColored : false,
            basePrice: 400,
            keyItem : false,
            hasSize : false,
            tier: 0,
            levelMinimum : 1000000000,
            canHaveEnchants : false,
            canHaveTriggerEnchants : false,
            enchantLimit : 0,
            hasQuality : false,
            hasMaterial : false,
            isApparel : false,    isUnique : true,
            useTargetHint : Item.database.statics.USE_TARGET_HINT.NONE,
            possibleAbilities : [
            ],

            // fatigued
            blockPoints : 0,
            equipMod : StatSet.new(
                ATK: 5,
                SPD: -5,
                DEX: -5
            ),
            useEffects : [
                'thechosen:sentimental-box',
            ],
            equipEffects : [],
            attributes : 
                Item.database.statics.ATTRIBUTE.SHARP  |
                Item.database.statics.ATTRIBUTE.METAL
            ,
            onCreate ::(item, user, creationHint) {     

            }
            
        })    




        Item.database.newEntry(data : {
            name : "Wyvern Key of Fire",
            id : 'thechosen:wyvern-key-of-fire',
            description: 'A key to another island. Its quite big and warm to the touch.',
            examine : '',
            equipType: Item.database.statics.TYPE.TWOHANDED,
            rarity : 100,
            weight : 10,
            hasSize : false,
            canBeColored : false,
            basePrice: 1,
            tier: 0,
            keyItem : false,
            levelMinimum : 1000000000,
            canHaveEnchants : false,
            canHaveTriggerEnchants : false,
            enchantLimit : 0,
            hasQuality : false,
            hasMaterial : false,
            isApparel : false,    isUnique : true,
            useTargetHint : Item.database.statics.USE_TARGET_HINT.ONE,
            possibleAbilities : [
                "base:fire" // for fun!
            ],

            // fatigued
            blockPoints : 2,
            equipMod : StatSet.new(
                ATK: 25,
                SPD: -5,
                DEX: -5
            ),
            useEffects : [
            ],
            equipEffects : [
                "base:burning"
            ],
            attributes : 
                Item.database.statics.ATTRIBUTE.SHARP |
                Item.database.statics.ATTRIBUTE.METAL
            ,
            onCreate ::(item, user, creationHint) {     
            
                @:world = import(module:'game_singleton.world.mt');        
                @:nameGen = import(module:'game_singleton.namegen.mt');
                @:story = import(module:'game_singleton.story.mt');
                @:island = {
                    island : empty
                }
                breakpoint();
                item.setIslandGenAttributes(
                    levelHint:  story.levelHint,//user.level => Number,
                    nameHint:   nameGen.island(),
                    tierHint : 1,
                    extraLandmarks : [
                        'thechosen:shrine-of-ice'
                    ]
                );
                
                item.price = 1;
            }
            
        })

        Item.database.newEntry(data : {
            name : "Wyvern Key of Ice",
            id : 'thechosen:wyvern-key-of-ice',
            description: 'A key to another island. Its quite big and cold to the touch.',
            examine : '',
            equipType: Item.database.statics.TYPE.TWOHANDED,
            rarity : 100,
            hasSize : false,
            weight : 10,
            canBeColored : false,
            basePrice: 1,
            tier: 0,
            keyItem : false,
            levelMinimum : 1000000000,
            canHaveEnchants : false,
            canHaveTriggerEnchants : false,
            enchantLimit : 0,
            hasQuality : false,
            hasMaterial : false,
            isApparel : false,    isUnique : true,
            useTargetHint : Item.database.statics.USE_TARGET_HINT.ONE,
            possibleAbilities : [
                "base:ice" // for fun!
            ],

            // fatigued
            blockPoints : 2,
            equipMod : StatSet.new(
                ATK: 25,
                SPD: -5,
                DEX: -5
            ),
            useEffects : [
            ],
            equipEffects : [
                "base:icy"
            ],
            attributes : 
                Item.database.statics.ATTRIBUTE.SHARP |
                Item.database.statics.ATTRIBUTE.METAL
            ,
            onCreate ::(item, user, creationHint) {     
            
                @:world = import(module:'game_singleton.world.mt');        
                @:nameGen = import(module:'game_singleton.namegen.mt');
                @:story = import(module:'game_singleton.story.mt');
                @:island = {
                    island : empty
                }

                item.setIslandGenAttributes(
                    levelHint:  story.levelHint+1,
                    nameHint:   nameGen.island(),
                    tierHint : 2,
                    extraLandmarks : [
                        'thechosen:shrine-of-thunder'
                    ]
                );
                
                item.price = 1;
            }
            
        })    

        Item.database.newEntry(data : {
            name : "Wyvern Key of Thunder",
            id : 'thechosen:wyvern-key-of-thunder',
            description: 'A key to another island. Its quite big and softly hums.',
            examine : '',
            equipType: Item.database.statics.TYPE.TWOHANDED,
            rarity : 100,
            weight : 10,
            canBeColored : false,
            hasSize : false,
            basePrice: 1,
            keyItem : false,
            tier: 0,
            levelMinimum : 1000000000,
            canHaveEnchants : false,
            canHaveTriggerEnchants : false,
            enchantLimit : 0,
            hasQuality : false,
            hasMaterial : false,
            isApparel : false,    isUnique : true,
            useTargetHint : Item.database.statics.USE_TARGET_HINT.ONE,
            possibleAbilities : [
                "base:thunder" // for fun!
            ],

            // fatigued
            blockPoints : 2,
            equipMod : StatSet.new(
                ATK: 25,
                SPD: -5,
                DEX: -5
            ),
            useEffects : [
            ],
            equipEffects : [
                "base:shock"
            ],
            attributes : 
                Item.database.statics.ATTRIBUTE.SHARP |
                Item.database.statics.ATTRIBUTE.METAL
            ,
            onCreate ::(item, user, creationHint) {     
            
                @:world = import(module:'game_singleton.world.mt');        
                @:nameGen = import(module:'game_singleton.namegen.mt');
                @:story = import(module:'game_singleton.story.mt');
                @:island = {
                    island : empty
                }

                item.setIslandGenAttributes(
                    levelHint:  story.levelHint+2,
                    nameHint:   nameGen.island(),
                    tierHint : 3,
                    extraLandmarks : [
                        'thechosen:shrine-of-light'
                    ]
                );
                
                item.price = 1;
            }
            
        })    

        Item.database.newEntry(data : {
            name : "Wyvern Key of Light",
            id : 'thechosen:wyvern-key-of-light',
            description: 'A key to another island. Its quite big and faintly glows.',
            examine : '',
            equipType: Item.database.statics.TYPE.TWOHANDED,
            rarity : 100,
            weight : 10,
            hasSize : false,
            canBeColored : false,
            basePrice: 1,
            keyItem : false,
            tier: 0,
            levelMinimum : 1000000000,
            canHaveEnchants : false,
            canHaveTriggerEnchants : false,
            enchantLimit : 0,
            hasQuality : false,
            hasMaterial : false,
            isApparel : false,    isUnique : true,
            useTargetHint : Item.database.statics.USE_TARGET_HINT.ONE,
            possibleAbilities : [
                "base:explosion" // for fun!
            ],

            // fatigued
            blockPoints : 2,
            equipMod : StatSet.new(
                ATK: 25,
                SPD: -5,
                DEX: -5
            ),
            useEffects : [
            ],
            equipEffects : [
                "base:shimmering"
            ],
            attributes : 
                Item.database.statics.ATTRIBUTE.SHARP |
                Item.database.statics.ATTRIBUTE.METAL
            ,
            onCreate ::(item, user, creationHint) {     
            
                @:world = import(module:'game_singleton.world.mt');        
                @:nameGen = import(module:'game_singleton.namegen.mt');
                @:story = import(module:'game_singleton.story.mt');
                @:island = {
                    island : empty
                }

                item.setIslandGenAttributes(
                    levelHint:  story.levelHint+3,
                    nameHint:   nameGen.island(),
                    tierHint : 4,
                    extraLandmarks : [
                        'base:lost-shrine'
                    ]

                );
                
                item.price = 1;
            }
            
        })     

               
        
        
        
        @:Scene = import(module:'game_database.scene.mt');


        Scene.newEntry(
            data : {
                id : 'thechosen:scene_intro',
                script: [
                    ['???', '...You.. you have been chosen...'],
                    ['???', 'Among those of the world, the Chosen are selected...'],
                    ['???', '...Selected to seek me, the Wyvern of Light...'],
                    ['???', 'If you seek me, I will grant you and anyone with you a wish...'],
                    ['???', 'But be warned: others will seek their own wish and will accept no others...'],
                    ['???', 'Come, Chosen: seek me and the Gate Keys among the Shrines...'],
                    ['???', '...I will await you, Chosen...'],
                ]
            }
        )     

        Scene.newEntry(
            data : {
                id: 'thechosen:scene_keybattle0',
                script: [
                    ::(location, landmark, doNext) {
                        @:world = import(module:'game_singleton.world.mt');
                        
                        @chance = Number.random(); 
                        @:island = landmark.island;   
                        @:party = world.party;
                        @enemies = [];
                        
                        
                        for(0, 3)::(i) {
                            @:enemy = island.newAggressor();
                            enemy.inventory.clear();
                            enemy.anonymize();
                            enemies->push(value:enemy);
                        }
                        
                        @:boss = enemies[1];

                        windowEvent.queueMessage(
                            speaker: '???',
                            text: random.pickArrayItem(list:[
                                'Well, well, well. Look who else is after the key. It\'s ours!',
                                'Get out of here, the key is ours!',
                                'Wait, no! The key is ours! Get out of here!',
                                'We will fight for that key to the death!',
                                'The key is ours! We are the real Chosen!'
                            ])
                        );
                        
                        
                        @:getKey ::{
                            @:Story = import(module:'game_singleton.story.mt');
                            
                            @:foundMessage ::(itemName){
                                windowEvent.queueMessage(text: 'It looks like they dropped something heavy during the fight...');
                                breakpoint();
                                @key;
                                if (itemName != empty && world.party.getItemAtAll(id:itemName) == empty) ::<= {
                                    windowEvent.queueMessage(text: '.. is that...?');                            
                                    key = Item.new(base:Item.database.find(id:itemName));
                                } else ::<= {
                                    windowEvent.queueMessage(text: '.. huh...? This is just a normal key to another island...');                            

                                    key = Item.new(base:Item.database.find(id:'base:wyvern-key'));
                                    @:namegen = import(module:'game_singleton.namegen.mt');
                                    @:name = namegen.island();
                                    key.setIslandGenAttributes(
                                        levelHint: world.island.levelMax + 1 + (world.island.levelMax * 1.2)->ceil,
                                        nameHint: name,
                                        tierHint: world.island.tier + 1,
                                        extraLandmarks : [
                                            'base:lost-shrine',
                                        ]
                                    ); 
                                    key.name = 'Key to ' + name  + ' '+romanNum(value:world.island.tier + 1);
                                    itemName = key.name;
                                } 
                                party.inventory.add(item:key);                                       


                                    
                                windowEvent.queueMessage(text: 'The party obtained the ' + key.name + '!');                            
                            }


                            match(island.tier) {
                                (0):::<= { 
                                    foundMessage(itemName:'thechosen:wyvern-key-of-fire');
                                },
                                (1):::<= {
                                    foundMessage(itemName:'thechosen:wyvern-key-of-ice');
                                },
                                (2):::<= {
                                    foundMessage(itemName:'thechosen:wyvern-key-of-thunder');
                                },
                                (3):::<= {
                                    foundMessage(itemName:'thechosen:wyvern-key-of-light');
                                },
                                default: ::<={
                                    foundMessage();
                                }
                            }   
                   
                        }

                        
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
                                    when(world.battle.partyWon()) ::<= { 
                                        getKey();
                                    };
                                      
                                    @:instance = import(module:'game_singleton.instance.mt');
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
                    //          "(comes     again      one  new)    Another new one comes..."
                    ['???',      'Juhrruhlo-rrohsharr  naan djaashaarr ...'],
                    ['???',      'Zaaluh-shol, welcome... to my domain. You have done well to get here.'],
                    ['???',      'You have been summoned, but not by me. My sibling is the one who calls for you.'],
                    ['???',      'But to get to them, I must evaluate you to see if you are truly worthy of seeing the Wyvern of Light.'],
                    ['Kaedjaal', 'My name is Kaedjaal, and my domain is that of flame. I enjoy a summer\'s day as much as the next, but I\'ll be honest with you; I take it a step further.'],
                    ['Kaedjaal', 'Dancing in the fire, my test looks inward: your will, your determination, what moves you.'],
                    ['Kaedjaal', 'Chosen, can you stand my flames? Can you triumph over uncertain and, at times, unfair odds? Show me your power.'],
                    ['Kaedjaal', 'Come forth.'],
                    ::(location, landmark, doNext) {
                        @:world = import(module:'game_singleton.world.mt');
                        @:Battle = import(module:'game_class.battle.mt');
                        @:canvas = import(module:'game_singleton.canvas.mt');
                        location.ownedBy.name = 'Kaedjaal, Wyvern of Fire';
                        @:end = ::(result){

                            when(world.battle.partyWon() == false) ::<= {
                                windowEvent.queueMessage(
                                    speaker:'Kaedjaal',
                                    text:'Perhaps it was not meant to be...'
                                );
                                
                                windowEvent.queueCustom(
                                    onEnter::{
                                        @:instance = import(module:'game_singleton.instance.mt');
                                        instance.gameOver(reason:'The party was wiped out.');
                                    }
                                );
                            }
                            
                        
                            when (!location.ownedBy.isIncapacitated()) ::<= {
                                world.battle.start(
                                    party: world.party,                            
                                    allies: world.party.members,
                                    enemies: [location.ownedBy],
                                    landmark: landmark,
                                    renderable:{render::{canvas.blackout();}},
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
                            renderable:{render::{canvas.blackout();}},
                            onEnd::(result) {
                                end(result);
                            }
                        );                         
                    },
                    ['Kaedjaal', 'Ha ha ha, splendid! Chosen, that was excellent. You have shown how well you can handle yourself.'],
                    ['Kaedjaal', 'However, be cautious: you are not the first to have triumphed over me.'],
                    ['Kaedjaal', 'There are many with their own goals and ambitions, and some will be more skilled than you currently are.'],
                    ['Kaedjaal', 'Well, I hope you enjoyed this little visit. Come and see me any time.'],
                    ['Kaedjaal', 'Along with leading you to me, each of these keys leads to a different island using magic we Wyverns know...'],
                    ['Kaedjaal', 'I will use it to bring you to the next island where you may find the next shrine.'],
                    ['', 'The Wyvern Key of Fire glows.'],
                    ['Kaedjaal', 'May you find peace and prosperity in your heart. Remember: seek the shrine to find the Key.'],
                    ::(location, landmark, doNext) {
                        location.ownedBy.name = 'Kaedjaal, Wyvern of Fire';
                        @:world = import(module:'game_singleton.world.mt');
                        @key = world.party.getItemAtAll(id:'thechosen:wyvern-key-of-fire');
                        // you can technically throw it out or Literally Throw It.
                        when(key == empty) ::<= {
                            windowEvent.queueMessage(
                                speaker: 'Kaedjaal',
                                                //(Friend   of   Me)  My friend...
                                text: '... Oh. Uh. Rrohziil shaa jiin, I do not know how you have done this, but you seem to have misplaced your key to my domain.'
                            );
                            windowEvent.queueMessage(
                                speaker: 'Kaedjaal',
                                text: 'Well, here: I have a spare.'
                            );
                            
                            @:item = Item.new(
                                base:Item.database.find(id:'thechosen:wyvern-key-of-fire'
                                        )
                            );
                            windowEvent.queueMessage(text:'The party was given a ' + item.name + '.');
                            world.party.inventory.add(item);
                            key = item;

                            windowEvent.queueMessage(
                                speaker: 'Kaedjaal',
                                text: 'Rrohziil, Please keep it safe. It breaks my heart to give these away to Chosen who already should have one...'
                            );
                        }
                        @:canvas = import(module:'game_singleton.canvas.mt');

                        windowEvent.queueMessage(
                            renderable:{render::{canvas.blackout();}},
                            text: 'You are whisked away to a new island...'
                        );

                        
                        world.scenario.data.fireWyvernDefeated = true;
                        
                        @:instance = import(module:'game_singleton.instance.mt');

                        instance.visitIsland(key, atGate:true, onReady:doNext);
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
                        @:world = import(module:'game_singleton.world.mt');
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
                                                        filter:::(value) <- value.isUnique == false && value.canHaveEnchants && value.hasMaterial
                                                    ),
                                                    rngEnchantHint:true, 
                                                    colorHint:'base:red', 
                                                    materialHint: 'base:gold'
                                                );
                                                @:ItemEnchant = import(module:'game_mutator.itemenchant.mt');
                                                item.addEnchant(mod:ItemEnchant.new(base:ItemEnchant.database.find(id:'base:burning')));
                                                item.addEnchant(mod:ItemEnchant.new(base:ItemEnchant.database.find(id:'base:burning')));


                                                windowEvent.queueMessage(text:'In exchange, the party was given ' + correctA(word:item.name) + '.');
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
                                    
                                    
                                    
                                    @:pickitem = import(module:'game_function.pickitem.mt');
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
                    ['Kaedjaal', 'Allow me to return you to the land that the Key of Fire leads to.'],                     
                           //    (world    wish[verb] travel[noun, pl] swift prosperous)   -> The World wishes travels swift and prosperous -> May your travels be swift and properous
                    ['Kaedjaal', 'Zaashael kaaluh-lo zohppuh-zodjii shiirr kohggaelaarr...'], 
                    ::(location, landmark, doNext) {
                        @:world = import(module:'game_singleton.world.mt');
                        @key = world.party.getItemAtAll(id:'thechosen:wyvern-key-of-fire');

                        @:canvas = import(module:'game_singleton.canvas.mt');
                        windowEvent.queueMessage(
                            renderable:{render::{canvas.blackout();}},
                            text: 'You are whisked away to an island of Ice...'
                        );

                        windowEvent.queueCustom(
                            onEnter ::{
                                @:instance = import(module:'game_singleton.instance.mt');
                                instance.visitIsland(key, atGate:true);
                                doNext();      
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
                    ['???',      '...'],
                    ['???', '... Another Chosen, or so you would be called.'],
                    ['???', 'Why my sibling wastes our time with some of these karrjuhzaalii is a mystery to me.'],
                    ['???', 'But with me, your journey may end here. I will not let you pass unless you earn it.'],
                    ['???', 'I will not be as easy-going as Kaedjaal.'],
                    ['???', 'Through the unforgiving cold and ice, you will understand the power which you challenge.'],
                    ['Ziikkaettaal', 'I, Ziikkaettaal will halt your path now, Chosen!'],
                    ::(location, landmark, doNext) {
                        @:world = import(module:'game_singleton.world.mt');
                        @:Battle = import(module:'game_class.battle.mt');
                        @:canvas = import(module:'game_singleton.canvas.mt');
                        location.ownedBy.name = 'Ziikkaettaal, Wyvern of Ice';
                        @:end = ::(result){

                            when(world.battle.partyWon() == false) ::<= {
                                windowEvent.queueMessage(
                                    speaker:'Ziikkaettaal',
                                    text:'Hm. As expected.'
                                );
                                
                                windowEvent.queueCustom(
                                    onEnter::{
                                        @:instance = import(module:'game_singleton.instance.mt');
                                        instance.gameOver(reason:'The party was wiped out.');
                                    }
                                );
                            }
                            
                        
                            when (!location.ownedBy.isIncapacitated()) ::<= {
                                world.battle.start(
                                    party: world.party,                            
                                    allies: world.party.members,
                                    enemies: [location.ownedBy],
                                    landmark: landmark,
                                    renderable:{render::{canvas.blackout();}},
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
                            renderable:{render::{canvas.blackout();}},
                            onEnd::(result) {
                                end(result);
                            }
                        );                         
                    },
                    ['Ziikkaettaal', 'I... I see. Kaedjaal was perhaps right to let you continue.'],
                    ['Ziikkaettaal', 'It has been some time since I have let another Chosen pass.'],
                    ['Ziikkaettaal', 'You have handled yourself well.'],
                    ['', 'The Wyvern Key of Ice glows.'],
                    ['Ziikkaettaal', 'May you find peace and prosperity in your heart. Remember: seek the shrine to find the Key.'],
                    ::(location, landmark, doNext) {
                        location.ownedBy.name = 'Kaedjaal, Wyvern of Ice';
                        @:world = import(module:'game_singleton.world.mt');
                        @key = world.party.getItemAtAll(id:'thechosen:wyvern-key-of-ice');

                        // you can technically throw it out or Literally Throw It.
                        when(key == empty) ::<= {
                            windowEvent.queueMessage(
                                speaker: 'Ziikkaettaal',
                                text: '*tells you off in dragonish*'
                            );
                            
                            @:item = Item.new(base:Item.database.find(id:'thechosen:wyvern-key-of-ice'));
                            windowEvent.queueMessage(text:'The party was given a ' + item.name + '.');
                            world.party.inventory.add(item);
                            key = item;

                            windowEvent.queueMessage(
                                speaker: 'Ziikkaettaal',
                                text: '*hisses*'
                            );
                        }
                        
                        world.scenario.data.iceWyvernDefeated = true;
                        
                        @:instance = import(module:'game_singleton.instance.mt');

                        instance.visitIsland(key, atGate:true, onReady:doNext);
                    }
                    
                    
                    
                ]
            }
        ) 

        Scene.newEntry(
            data : {
                id : 'thechosen:scene_wyvernice1',
                script: [
                    ['Ziikkaettaal', 'You.. You have returned.'],
                    ['Ziikkaettaal', 'Seeing as you have so much time on your hands, how about a little game.'],
                    ['Ziikkaettaal', 'You see, I have a bit of a penchant for... gambling.'],
                    ['Ziikkaettaal', 'Wager against me. If you lose, you hand me 1000G. If you win, you get a weapon from my hoard.'],
                    ['Ziikkaettaal', 'I assure you, my weapons are well worth it.'],
                    ::(location, landmark, doNext) {
                        @:world = import(module:'game_singleton.world.mt');
                        world.accoladeEnable(name:'wyvernsRevisited');
                        @:party = world.party;
                        windowEvent.queueAskBoolean(
                            prompt: 'Play dice with Ziikkaettaal?',
                            onChoice::(which) {
                                when(which == false) doNext();
                                
                                when (party.inventory.gold < 1000) ::<= {
                                    windowEvent.queueMessage(
                                        speaker: 'Ziikkaettaal',
                                        text: 'You do not have enough to bet with me. Come back when you are... blessed with more riches.',
                                        onLeave:doNext
                                    );
                                }
                                
                                
                                windowEvent.queueMessage(
                                    speaker: 'Ziikkaettaal',
                                    text: 'Prepare yourself.',
                                    onLeave::{
                                        @:dice = import(module:'game_function.dice.mt');
                                        dice(
                                            onFinish::(partyWins) {
                                            
                                                windowEvent.queueMessage(
                                                    text:(if (partyWins) 'The party' else 'Ziikkaettaal') + ' wins!'
                                                );
                                            
                                                if (partyWins) ::<= {
                                                    world.accoladeEnable(name:'wonGamblingGame');
                                                    windowEvent.queueMessage(
                                                        speaker: 'Ziikkaettaal',
                                                             //Curse       earth    you       -> **** you
                                                        text: 'Kkiikkohluh zaashael kaajiin...'
                                                    );                                                
                                                    windowEvent.queueMessage(
                                                        speaker: 'Ziikkaettaal',
                                                        text: 'You win. Well played.'
                                                    );                              
                                                    
                                                    @:prize = Item.new(
                                                        base: Item.database.getRandomFiltered(
                                                            filter:::(value) <- value.isUnique == false && value.canHaveEnchants && value.hasMaterial && value.attributes & Item.database.statics.ATTRIBUTE.WEAPON
                                                        ),
                                                        rngEnchantHint:true, 
                                                        colorHint:'base:blue', 
                                                        materialHint:'base:mythril', 
                                                        qualityHint:'base:masterwork'
                                                    );
                                                    @:ItemEnchant = import(module:'game_mutator.itemenchant.mt');
                                                    prize.addEnchant(mod:ItemEnchant.new(base:ItemEnchant.database.find(id:'base:icy')));

                                                    party.inventory.add(item:prize);
                                                    windowEvent.queueMessage(text:'The party was given a ' + prize.name + '.',
                                                        onLeave:doNext
                                                    );
                                                    
                                                } else ::<= {
                                                    windowEvent.queueMessage(
                                                        speaker: 'Ziikkaettaal',
                                                        text: 'Too bad! Maybe another time. Ha ha...'
                                                    );                              
                                                    party.inventory.subtractGold(amount:1000);
                                                    windowEvent.queueMessage(text:'The party lost 1000G.',
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
                    ['Ziikkaettaal', 'I\'ll take you back to your world.'],                     
                    ::(location, landmark, doNext) {
                        @:world = import(module:'game_singleton.world.mt');
                        @key = world.party.getItemAtAll(id:'thechosen:wyvern-key-of-ice');

                        @:canvas = import(module:'game_singleton.canvas.mt');
                        windowEvent.queueMessage(
                            renderable:{render::{canvas.blackout();}},
                            text: 'You are whisked away to an island of Thunder...'
                        );

                        windowEvent.queueCustom(
                            onEnter ::{
                                @:instance = import(module:'game_singleton.instance.mt');
                                instance.visitIsland(key, atGate:true);
                                doNext();      
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
                    ['???', 'Ah, ppuh-sho-zaaluh naan. Excellent.'],
                    ['???', 'As we wait, we begin to wonder if someone will show with enough shiikohl to surpass us.'],
                    ['???', 'Yet as time passes, more of you come. Some quite formiddable too.'],
                    ['???', 'What is it you seek? Is it just a wish, or something more? A test of your own growth?'],
                    ['???', 'Regardless, you come before me, Juhriikaal, in hopes to get to the Wyvern of Light.'],
                    ['Juhriikaal', 'Congratulations on getting this far. Just blind luck will not get you past me.'],
                    ['Juhriikaal', 'You will find my electrifying methods to be a little less forgiving than my siblings.'],
                    ['Juhriikaal', 'Prepare yourself, Chosen!'],
                    ::(location, landmark, doNext) {
                        @:world = import(module:'game_singleton.world.mt');
                        @:Battle = import(module:'game_class.battle.mt');
                        @:canvas = import(module:'game_singleton.canvas.mt');
                        location.ownedBy.name = 'Juhriikaal, Wyvern of Thunder';
                        @:end = ::(result){

                            when(world.battle.partyWon() == false) ::<= {
                                windowEvent.queueMessage(
                                    speaker:'Juhriikaal',
                                    text:'Djiirohshuhlo jiin.'
                                );
                                
                                windowEvent.queueCustom(
                                    onEnter::{
                                        @:instance = import(module:'game_singleton.instance.mt');
                                        instance.gameOver(reason:'The party was wiped out.');
                                    }
                                );
                            }
                            
                        
                            when (!location.ownedBy.isIncapacitated()) ::<= {
                                world.battle.start(
                                    party: world.party,                            
                                    allies: world.party.members,
                                    enemies: [location.ownedBy],
                                    landmark: landmark,
                                    renderable:{render::{canvas.blackout();}},
                                    onEnd::(result) {
                                        end(result);
                                    }
                                );                                
                            } 
                            
                            doNext();
                        }
                        
                        @:thunderSpawn ::{
                            @:Entity = import(module:'game_class.entity.mt');
                            @:sprite = Entity.new(
                                island: landmark.island,
                                speciesHint: 'base:thunder-spawn',
                                professionHint: 'base:thunder-spawn',
                                levelHint:5
                            );
                            sprite.name = 'the Thunder Spawn';
                            
                            for(0, 10)::(i) {
                                sprite.learnNextAbility();
                            }          
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
                            renderable:{render::{canvas.blackout();}},
                            onEnd::(result) {
                                end(result);
                            }
                        );                         
                    },
                    ['Juhriikaal', 'You\'ve got something special with you. The way you fight and prove yourself... You\'ve got potential.'],
                    ['Juhriikaal', 'Ah... it\'s refreshing.'],
                    ['', 'The Wyvern Key of Thunder glows.'],
                    ['Juhriikaal', 'May you find peace and prosperity in your heart. Remember: seek the shrine to find the Key.'],
                    ::(location, landmark, doNext) {
                        location.ownedBy.name = 'Juhriikaal, Wyvern of Thunder';
                        @:world = import(module:'game_singleton.world.mt');
                        @key = world.party.getItemAtAll(id:'thechosen:wyvern-key-of-thunder');

                        // you can technically throw it out or Literally Throw It.
                        when(key == empty) ::<= {
                            windowEvent.queueMessage(
                                speaker: 'Juhriikaal',
                                text: 'Uhm. Where\'s the thunder key..?'
                            );
                            
                            @:item = Item.new(base:Item.database.find(id:'thechosen:wyvern-key-of-thunder'));
                            windowEvent.queueMessage(text:'The party was given a ' + item.name + '.');
                            world.party.inventory.add(item);
                            key = item;

                            windowEvent.queueMessage(
                                speaker: 'Juhriikaal',
                                text: '...'
                            );
                        }
                        
                        world.scenario.data.thunderWyvernDefeated = true;
                        
                        @:instance = import(module:'game_singleton.instance.mt');
                        // cancel and flush current VisitIsland session
                        if (key.islandEntry == empty)
                            key.addIslandEntry(world);


                        instance.visitIsland(key, atGate:true, onReady:doNext);
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
                        @:world = import(module:'game_singleton.world.mt');
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
                                
                                @:ItemQuality = import(module:'game_database.itemquality.mt');



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
                                
                                @:doSpell::(enhanced, catalyst) {

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
                                                @:whom = enhanced.equippedBy;
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
                                            
                                            world.party.inventory.remove(item:catalyst);
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


                                
                                    @:pickItem = import(module:'game_function.pickpartyitem.mt');
                                    pickItem(
                                        canCancel: true,
                                        topWeight: 0.5,
                                        leftWeight: 0.5,
                                        prompt:'Choose an item to enhance:',
                                        onPick ::(item) {
                                            when (item == empty) ::<= {
                                                windowEvent.queueMessage(speaker:'Juhriikaal', text:'Ah I see. I will still be here if you change your mind.');
                                                windowEvent.jumpToTag(name:'pickItem', goBeforeTag: true, doResolveNext:true);
                                                windowEvent.queueCustom(
                                                    onEnter::{},
                                                    onLeave::{doNext();}                                    
                                                );                                
                                            }

                                            when (item.base.hasQuality == false) ::<= {
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
                                                filter ::(item) <- item.base.hasQuality && item.quality == enhanced.quality && item != enhanced,
                                                onPick ::(item) {
                                                    when (item == empty) ::<= {
                                                        windowEvent.queueMessage(speaker:'Juhriikaal', text:'Oh... It looks like you have no item elligible as a catalyst for this item. I am sorry. Remember: catalysts need to be the same quality as the item to enhance.');                                
                                                        tryAgain();                                            
                                                    }
                                                    catalyst = item;

                                                    when (catalyst == enhanced) ::<= {   
                                                        windowEvent.queueMessage(speaker:'Juhriikaal', text:'Chosen I am sorry, you cannot choose the same item as the catalyst.');                                
                                                    }


                                                    when (catalyst.base.hasQuality == false) ::<= {   
                                                        windowEvent.queueMessage(speaker:'Juhriikaal', text:'Chosen I am sorry, this item cannot be used as a catalyst for the spell.');                                
                                                    }
                                                    
                                                    when (catalyst.quality != enhanced.quality) ::<= {                                        
                                                        windowEvent.queueMessage(speaker:'Juhriikaal', text:'Chosen, I am sorry, I cannot cast my magic on these. The ' 
                                                            + enhanced.name + ' you wish to enhance is of ' + qualityString(item:enhanced) + 
                                                            ' while the catalyst is of ' + qualityString(item:catalyst) + '. These items must be the same quality for the spell to work.');
                                                    }
                                                   
                                                    windowEvent.queueMessage(speaker:'Juhriikaal', text:'Now. Let me cast the spell.');                                
                                                    windowEvent.jumpToTag(name:'pickItem', goBeforeTag: true, doResolveNext:true);
                                                  
                                                    doSpell(enhanced, catalyst);                                           
                                                }
                                            )
                                        }
                                    )                        
                                };
                                attempt();
                            }
                        );
                        
                    },
                    ['Juhriikaal', 'Allow me to return you to the land that the Key of Thunder leads to.'],                     
                    ::(location, landmark, doNext) {
                        @:world = import(module:'game_singleton.world.mt');
                        @key = world.party.getItemAtAll(id:'thechosen:wyvern-key-of-thunder');

                        @:canvas = import(module:'game_singleton.canvas.mt');
                        windowEvent.queueMessage(
                            renderable:{render::{canvas.blackout();}},
                            text: 'You are whisked away to an island of Light...'
                        );

                        windowEvent.queueCustom(
                            onEnter :: {
                                @:instance = import(module:'game_singleton.instance.mt');
                                instance.visitIsland(key, atGate:true);
                                doNext();       
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
                    
                        @:world = import(module:'game_singleton.world.mt');
                        @:Battle = import(module:'game_class.battle.mt');
                        @:canvas = import(module:'game_singleton.canvas.mt');
                        location.ownedBy.name = 'Shaarraeziil, Wyvern of Light';
                        @:end = ::(result){

                            when(world.battle.partyWon() == false) ::<= {
                                windowEvent.queueMessage(
                                    speaker:'Juhriikaal',
                                    text:'Alas. Another one will come, more worthy.'
                                );
                                
                                windowEvent.queueCustom(
                                    onEnter::{
                                        @:instance = import(module:'game_singleton.instance.mt');
                                        instance.gameOver(reason:'The party was wiped out.');
                                    }
                                );
                            }
                            
                        
                            when (!location.ownedBy.isIncapacitated()) ::<= {
                                world.battle.start(
                                    party: world.party,                            
                                    allies: world.party.members,
                                    enemies: [location.ownedBy],
                                    landmark: landmark,
                                    renderable:{render::{canvas.blackout();}},
                                    onEnd::(result) {
                                        end(result);
                                    }
                                );                                
                            } 
                            
                            doNext();
                        }
                        
                        @:lightSpawn ::{
                            @:Entity = import(module:'game_class.entity.mt');
                            @:sprite = Entity.new(
                                island: landmark.island,
                                speciesHint: 'base:guiding-light',
                                professionHint: 'base:guiding-light',
                                levelHint:5
                            );
                            sprite.name = 'the Guiding Light';
                            
                            for(0, 10)::(i) {
                                sprite.learnNextAbility();
                            }          
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
                            renderable:{render::{canvas.blackout();}},
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
                    ['Shaarraeziil', 'I have talked to my sibblings prior to your arrival... We all feel that you are capable of defeating the one of Darkness.'],
                    ['Shaarraeziil', '... However.'],
                    ['Shaarraeziil', 'It would be unfair to lay this burden upon you. You have proven yourself beyond all.'],
                    ['Shaarraeziil', 'You may choose to take your wish, no questions asked. You have earned it.'],
                    ['Shaarraeziil', 'But, we humbly request... that you help us defeat the Wyvern of Darkness.'],
                    ['Shaarraeziil', 'I will warn you. The Wyvern of Darkness\' treachery knows no bounds. It will be dangerous in ways you\'ve not seen...'],
                    ['Shaarraeziil', 'Upon your victory, however, your wish will be waiting for you all the same.'],
                    ['Shaarraeziil', 'What say you...? Will you help us...?'],
                

                    ::(location, landmark, doNext) {
                        @:world = import(module:'game_singleton.world.mt');
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
                                                @:world = import(module:'game_singleton.world.mt');
                                                world.accoladeEnable(name:'acceptedQuest');
                                                Scene.start(id:'thechosen:scene_wyvernlight0_quest', onDone::{}, location, landmark:location.landmark);
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
                        @:instance = import(module:'game_singleton.instance.mt');
                        @:enter = import(module:'game_function.name.mt');
                        enter(
                            prompt: 'What is your wish?',
                            onDone ::(name) {
                                @:world = import(module:'game_singleton.world.mt')
                                world.setWish(wish:name);
                                instance.savestate();
                                (import(module:'game_function.newrecord.mt'))(wish:name);
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
                        item.name = 'Wyvern\'s Hope';
                        @:world = import(module:'game_singleton.world.mt');
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
                        @:world = import(module:'game_singleton.world.mt');
                        @key = world.party.getItemAtAll(id:'thechosen:wyvern-key-of-light');

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
                        

                        @:canvas = import(module:'game_singleton.canvas.mt');
                        windowEvent.queueMessage(
                            renderable:{render::{canvas.blackout();}},
                            text: 'You are whisked away to another island...'
                        );

                        windowEvent.queueCustom(
                            onEnter :: {
                                @:instance = import(module:'game_singleton.instance.mt');
                                instance.visitIsland(key, atGate:true);
                                doNext();       
                            }
                        ); 




                        
                        @:instance = import(module:'game_singleton.instance.mt');
                        // cancel and flush current VisitIsland session
                        if (key.islandEntry == empty)
                            key.addIslandEntry(world);


                        instance.visitIsland(key, atGate:true, onReady:doNext);
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
                                @:instance = import(module:'game_singleton.instance.mt');
                                @:world = import(module:'game_singleton.world.mt');
                                instance.visitLandmark(
                                    landmark: world.island.newLandmark(
                                        base : Landmark.database.find(id:'thechosen:dark-lair-entrance')
                                    )
                                );
                            }
                        );
                    },


                    ['Shaarraeziil', 'I understand. Come back when you are ready.'],
                    ['Shaarraeziil', 'For now, I will take you back.'],
                    ::(location, landmark, doNext){
                        @:world = import(module:'game_singleton.world.mt');
                        @key = world.party.getItemAtAll(id:'thechosen:wyvern-key-of-light');



                        @:instance = import(module:'game_singleton.instance.mt');

                        @:canvas = import(module:'game_singleton.canvas.mt');
                        windowEvent.queueMessage(
                            renderable:{render::{canvas.blackout();}},
                            text: 'You are whisked away to another island...'
                        );

                        windowEvent.queueCustom(
                            onEnter :: {
                                @:instance = import(module:'game_singleton.instance.mt');
                                instance.visitIsland(key, atGate:true);
                                doNext();       
                            }
                        ); 

                        // cancel and flush current VisitIsland session
                        if (key.islandEntry == empty)
                            key.addIslandEntry(world);

                        instance.visitIsland(key, atGate:true, onReady:doNext);   
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
                        @:world = import(module:'game_singleton.world.mt')
                        world.accoladeEnable(name:'acceptedQuest');
                        @:instance = import(module:'game_singleton.instance.mt');
                        @:enter = import(module:'game_function.name.mt');
                        enter(
                            prompt: 'What is your wish?',
                            onDone ::(name) {
                                world.setWish(wish:name);
                                instance.savestate();
                                (import(module:'game_function.newrecord.mt'))(wish:name);
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
                        @:world = import(module:'game_singleton.world.mt');
                        when(world.scenario.data.openedSentimentalBox) 
                            windowEvent.queueMessage(text:
                                "The box is empty."
                            );
                        world.scenario.data.openedSentimentalBox = true;
                        doNext();
                    },
                    ['', 'Opening the box reveals items inside!'],
                    ['', 'The party receives 125G.'],
                    ['', 'The party receives 3 Pink Potions.'],
                    ['', 'The party receives a Life Crystal.'],
                    ['', 'The party receives a Skill Crystal.'],
                    ['', 'The party also receives an equippable Tome.'],
                    ['', 'There\'s also a note here...'],
                    ::(location, landmark, doNext) {
                        @:world = import(module:'game_singleton.world.mt');
                        @:Entity = import(module:'game_class.entity.mt');
                        @:someone = world.island.newInhabitant();
                        @:someoneElse = world.island.newInhabitant(levelHint:10);
                        windowEvent.queueMessage(text:
                            (random.pickArrayItem(
                                list : [
                                    '"I know we haven\'t always seen eye-to-eye; I know that we argue a lot. But when I heard you were leaving on your big adventure or whatever, I knew that I had to help. Here\'s some stuff I gathered over the years. I figure you\'ll get more use out of it than I ever will. Stay safe out there, and come back alive!"',
                                    '"Well, I didn\'t think the day would come, but here we are. I don\'t know about this \"Chosen\" nonsense, but I do know you well enough to know when you\'re determined to do something. I hope you find this stuff useful for your journey. I\'ll miss you."',
                                    '"You know, you\'re a real pain. All of a sudden you want to go on a big adventure, huh? Whatever. Just take this stuff. Put it to good use and stay alive. You might find it hard to believe, but I\'ll miss you. Do good out there."',
                                    '"There comes a time when someone has to take action and do something big. I saw it in your eyes the moment you told me. I could tell it was hard for you, too. Just know that you have my blessing. Let the items in this box be proof of that. I\'m proud of you. Stay alive out there."',
                                    '"So, it\'s finally time. We always knew you were an adventurer at heart. We prepared for the day you would finally go out into the world on your own. It might be tough, but we truly think you can overcome anything. Hopefully you\'ll find these useful on your journey. Be strong."',
                                    '"Ever since '+someoneElse.name+' left, you\'ve never been the same. Always looking out there thinking of a way to find them. I think that this "Chosen" thing is just another excuse to go out and look, but I can\'t blame you. I miss them too. Either way, stay safe and come back in one piece. Hopefully these will come in handy."' 
                                ]
                            )) + '\n\n - ' + someone.name
                        );

                        world.party.inventory.addGold(amount:125);

                        world.party.inventory.add(item:Item.new(base:Item.database.find(id:'base:life-crystal'
                        )));
                        
                        
                        for(0, 1)::(i) {
                            @:crystal = Item.new(base:Item.database.find(id:'base:skill-crystal'));
                            world.party.inventory.add(item:crystal);
                        }

                        //party.inventory.add(item:keyhome);


                        world.party.inventory.add(item:Item.new(
                            base:Item.database.find(id:'base:pink-potion')
                        ));
                        world.party.inventory.add(item:Item.new(
                            base:Item.database.find(id:'base:pink-potion')
                        ));
                        world.party.inventory.add(item:Item.new(
                            base:Item.database.find(id:'base:pink-potion')
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

        @:Species = import(module:'game_database.species.mt');

        Species.newEntry(data:{
            name : 'Wyvern of Fire',
            id : 'thechosen:wyvern-of-fire',
            rarity : 2000000000000,
            description: 'Keepers of the gates',
            growth : StatSet.new(
                HP : 60,
                AP : 10,
                ATK: 10,
                DEF: 10,
                INT: 10,
                LUK: 10,
                SPD: 10,
                DEX: 10
            ),
            qualities : [
            ],
            swarms : false,
            canBlock : true,
            
            special : true,
            passives : [
            ]
        })

        Species.newEntry(data:{
            name : 'Wyvern of Ice',
            id : 'thechosen:wyvern-of-ice',
            rarity : 2000000000000,
            description: 'Keepers of the gates',
            growth : StatSet.new(
                HP : 60,
                AP : 10,
                ATK: 10,
                DEF: 10,
                INT: 10,
                LUK: 10,
                SPD: 10,
                DEX: 10
            ),
            qualities : [
            ],
            swarms : false,
            canBlock : true,
            
            special : true,
            passives : [
                'base:icy'
            ]
        })


        Species.newEntry(data:{
            name : 'Wyvern of Thunder',
            id : 'thechosen:wyvern-of-thunder',
            rarity : 2000000000000,
            description: 'Keepers of the gates',
            growth : StatSet.new(
                HP : 60,
                AP : 10,
                ATK: 10,
                DEF: 10,
                INT: 10,
                LUK: 10,
                SPD: 10,
                DEX: 10
            ),
            qualities : [
            ],
            swarms : false,
            canBlock : true,
            
            special : true,
            passives : [
                'base:shock'
            ]
        })


        Species.newEntry(data:{
            name : 'Wyvern of Light',
            id : 'thechosen:wyvern-of-light',
            rarity : 2000000000000,
            description: 'Keepers of the gates',
            growth : StatSet.new(
                HP : 60,
                AP : 10,
                ATK: 10,
                DEF: 10,
                INT: 10,
                LUK: 10,
                SPD: 10,
                DEX: 10
            ),
            qualities : [
            ],
            swarms : false,
            canBlock : true,
            
            special : true,
            passives : [
                'base:shimmering'
            ]
        })

        @:Profession = import(module:'game_mutator.profession.mt');

        Profession.database.newEntry(data:{
            name: 'Wyvern of Fire',
            id:'thechosen:wyvern-of-fire',
            weaponAffinity: 'base:none',
            description : "", 
            levelMinimum : 100,

            growth: StatSet.new(
                HP:  20,
                AP:  20,
                ATK: 20,
                INT: 20,
                DEF: 20,
                SPD: 20,
                LUK: 20,
                DEX: 20
            ),
            minKarma : 0,
            maxKarma : 50,
            learnable : false,
            
            abilities : [
                'base:triplestrike',
                'base:backdraft',
                'base:big-swing',
                'base:stun',
                'base:fire',
                'base:wild-swing',
                'base:summon-fire-sprite'
            ],
            passives : [
            ]
        })

        Profession.database.newEntry(data:{
            name: 'Wyvern of Ice',
            id : 'thechosen:wyvern-of-ice',
            weaponAffinity: 'base:none',
            description : "", 
            levelMinimum : 100,

            growth: StatSet.new(
                HP:  20,
                AP:  20,
                ATK: 20,
                INT: 20,
                DEF: 20,
                SPD: 20,
                LUK: 20,
                DEX: 20
            ),
            minKarma : 0,
            maxKarma : 50,
            learnable : false,
            
            abilities : [
                'base:frozen-flame',
                'base:summon-ice-elemental',
                'base:ice',
                //'Magic Mist', // remove all effects
                'base:wild-swing',
                'base:sheer-cold'
            ],
            passives : [
            ]
        })            


        Profession.database.newEntry(data:{
            name: 'Wyvern of Thunder',
            id : 'thechosen:wyvern-of-thunder',
            weaponAffinity: 'base:none',
            description : "", 
            levelMinimum : 100,

            growth: StatSet.new(
                HP:  20,
                AP:  20,
                ATK: 20,
                INT: 20,
                DEF: 20,
                SPD: 20,
                LUK: 20,
                DEX: 20
            ),
            minKarma : 0,
            maxKarma : 50,
            learnable : false,
            
            abilities : [
                'base:thunder',
                'base:summon-thunder-spawn',
                //'Magic Mist', // remove all effects
                'base:wild-swing',
                'base:triplestrike',
                'base:leg-sweep',
                'base:flight',
                'base:flash',
                'base:unarm'
            ],
            passives : [
            ]
        })       

        Profession.database.newEntry(data:{
            name: 'Wyvern of Light',
            id : 'thechosen:wyvern-of-light',
            weaponAffinity: 'base:none',
            description : "", 
            levelMinimum : 100,

            growth: StatSet.new(
                HP:  20,
                AP:  20,
                ATK: 20,
                INT: 20,
                DEF: 20,
                SPD: 20,
                LUK: 20,
                DEX: 20
            ),
            minKarma : 0,
            maxKarma : 50,
            learnable : false,
            
            abilities : [
                'base:explosion',
                'base:flare',
                'base:headhunter',
                'base:sunburst',
                'base:sol-attunement',
                'base:cure',
                'base:summon-guiding-light',
                //'Magic Mist', // remove all effects
                'base:wild-swing',
                'base:triplestrike',
                'base:leg-sweep',
                'base:flash',
                'base:unarm'
            ],
            passives : [
            ]
        }) 


        // override base gate to grant special permission to the wyvern dimensions
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

                                @:which = match(keys[choice-1].name) {
                                    ('Wyvern Key of Fire'):    'thechosen:fire-wyvern-dimension',
                                    ('Wyvern Key of Ice'):     'thechosen:ice-wyvern-dimension',
                                    ('Wyvern Key of Thunder'): 'thechosen:thunder-wyvern-dimension',
                                    ('Wyvern Key of Light'):   'thechosen:light-wyvern-dimension'
                                };
                                @base = if (which != empty) Landmark.database.find(id:which)
                                if (base) ::<= {
                                    @:d = location.landmark.island.newLandmark(
                                        base
                                    );
                                    instance.visitLandmark(landmark:d);                        
                                } else ::<= {
                                    if (keys[choice-1].islandEntry == empty)
                                        keys[choice-1].addIslandEntry();
                                    instance.visitIsland(
                                        key:keys[choice-1],
                                        atGate:true
                                    );
                                }
                            });
                        }
                    );
                },
            }
        )


                
    }        
    
}
