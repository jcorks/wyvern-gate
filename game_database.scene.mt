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
@:windowEvent = import(module:'game_singleton.windowevent.mt');




@:reset :: {
@:StatSet = import(module:'game_class.statset.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Item = import(module:'game_mutator.item.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:random = import(module:'game_singleton.random.mt');
@:canvas = import(module:'game_singleton.canvas.mt');

Scene.newEntry(
    data : {
        name : 'scene_intro',
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
        name : 'scene_wyvernfire0',
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
                        
                        windowEvent.queueNoDisplay(
                            onEnter::{
                                windowEvent.jumpToTag(name:'MainMenu');                                    
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
            ['Kaedjaal', 'There are many with their own goals and ambitions, and some will be more skilled that you currently are.'],
            ['Kaedjaal', 'Well, I hope you enjoyed this little visit. Come and see me any time.'],
            ['Kaedjaal', 'Along with leading you to me, each of these keys leads to a different island using magic we Wyverns know...'],
            ['Kaedjaal', 'I will use it to bring you to the next island where you may find the next shrine.'],
            ['', 'The Wyvern Key of Fire glows.'],
            ['Kaedjaal', 'May you find peace and prosperity in your heart. Remember: seek the shrine to find the Key.'],
            ::(location, landmark, doNext) {
                location.ownedBy.name = 'Kaedjaal, Wyvern of Fire';
                @:world = import(module:'game_singleton.world.mt');
                @key = world.party.inventory.items->filter(by:::(value) <- value.name == 'Wyvern Key of Fire');
                if (key != empty) key = key[0];
                // could be equipped by hooligans and jokesters
                if (key == empty) ::<= {
                    key = {:::} {
                        foreach(world.party.members)::(i, member) {
                            @:wep = member.getEquipped(slot:Item.EQUIP_SLOTS.HAND_LR);
                            if (wep.name == 'Wyvern Key of Fire') ::<= {
                                send(message:key);
                            }
                        }
                    }
                }
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
                        base:Item.database.find(name:'Wyvern Key of Fire'
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

                
                @:story = import(module:'game_singleton.story.mt');
                if (story.tier < 1)
                    story.tier = 1;
                
                @:instance = import(module:'game_singleton.instance.mt');
                // cancel and flush current VisitIsland session
                if (key.islandEntry == empty)
                    key.addIslandEntry(world);

                
                instance.visitIsland(where:key.islandEntry);
                if (windowEvent.canJumpToTag(name:'VisitIsland')) ::<= {
                    windowEvent.jumpToTag(name:'VisitIsland', goBeforeTag:true, doResolveNext:true);
                }

                breakpoint();
                doNext();
            }
            
            
            
        ]
    }
) 

Scene.newEntry(
    data : {
        name : 'scene_wyvernfire1',
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
                            windowEvent.queueNoDisplay(
                                onEnter::{},
                                onLeave::{doNext();}                                    
                            );
                        }


                        when(world.party.inventory.items->keycount < 3) ::<= {
                            windowEvent.queueMessage(speaker:'Kaedjaal', text:'Djiiroshuhzolii, Chosen. You have not enough items to complete a trade.');
                            windowEvent.queueNoDisplay(
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
                                windowEvent.queueNoDisplay(
                                    onEnter::{},
                                    onLeave::{doNext();}                                    
                                );                            
                            }

                            when (item == empty && runOnce) ::<= {
                                cancelTrade();
                            }
                            if (item != empty) ::<= {
                                if (item.name == 'Wyvern Key of Fire') ::<= {
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
                                            colorHint:'red', 
                                            materialHint: 'Gold'
                                        );
                                        @:ItemEnchant = import(module:'game_mutator.itemenchant.mt');
                                        item.addEnchant(mod:ItemEnchant.new(base:ItemEnchant.database.find(name:'Burning')));
                                        item.addEnchant(mod:ItemEnchant.new(base:ItemEnchant.database.find(name:'Burning')));


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
                @key = world.party.inventory.items->filter(by:::(value) <- value.name == 'Wyvern Key of Fire');
                if (key != empty) key = key[0];
                // could be equipped by hooligans and jokesters
                if (key == empty) ::<= {
                    @:Entity = import(module:'game_class.entity.mt');
                    key = {:::} {
                        foreach(world.party.members)::(i, member) {
                            @:wep = member.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR);
                            if (wep.name == 'Wyvern Key of Fire') ::<= {
                                send(message:key);
                            }
                        }
                    }
                }
                @:canvas = import(module:'game_singleton.canvas.mt');
                windowEvent.queueMessage(
                    renderable:{render::{canvas.blackout();}},
                    text: 'You are whisked away to the island of Ice...'
                );

                @:instance = import(module:'game_singleton.instance.mt');
                instance.visitIsland(where:key.islandEntry);
                doNext();                    
            }
        ]
    }
)


Scene.newEntry(
    data : {
        name : 'scene_wyvernice0',
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
                        
                        windowEvent.queueNoDisplay(
                            onEnter::{
                                windowEvent.jumpToTag(name:'MainMenu');                                    
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
                @key = world.party.inventory.items->filter(by:::(value) <- value.name == 'Wyvern Key of Ice');
                if (key != empty) key = key[0];
                // could be equipped by hooligans and jokesters
                if (key == empty) ::<= {
                    @:Entity = import(module:'game_class.entity.mt');
                    key = {:::} {
                        foreach(world.party.members)::(i, member) {
                            @:wep = member.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR);
                            if (wep.name == 'Wyvern Key of Ice') ::<= {
                                send(message:key);
                            }
                        }
                    }
                }
                // you can technically throw it out or Literally Throw It.
                when(key == empty) ::<= {
                    windowEvent.queueMessage(
                        speaker: 'Ziikkaettaal',
                                        //(Friend   of   Me)  My friend...
                        text: '*tells you off in dragonish*'
                    );
                    
                    @:item = Item.new(base:Item.database.find(name:'Wyvern Key of Ice'));
                    windowEvent.queueMessage(text:'The party was given a ' + item.name + '.');
                    world.party.inventory.add(item);
                    key = item;

                    windowEvent.queueMessage(
                        speaker: 'Ziikkaettaal',
                        text: '*hisses*'
                    );
                }
                
                @:story = import(module:'game_singleton.story.mt');
                if (story.tier < 2)
                    story.tier = 2;
                
                @:instance = import(module:'game_singleton.instance.mt');
                // cancel and flush current VisitIsland session
                if (key.islandEntry == empty)
                    key.addIslandEntry(world);


                instance.visitIsland(where:key.islandEntry);
                if (windowEvent.canJumpToTag(name:'VisitIsland')) ::<= {
                    windowEvent.jumpToTag(name:'VisitIsland', goBeforeTag:true, doResolveNext:true);
                }

                breakpoint();
                doNext();
            }
            
            
            
        ]
    }
) 

Scene.newEntry(
    data : {
        name : 'scene_wyvernice1',
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
                                                    filter:::(value) <- value.isUnique == false && value.canHaveEnchants && value.hasMaterial && value.attributes & Item.ATTRIBUTE.WEAPON
                                                ),
                                                rngEnchantHint:true, 
                                                colorHint:'blue', 
                                                materialHint: 'Mythril', 
                                                qualityHint: 'Masterwork'
                                            );
                                            @:ItemEnchant = import(module:'game_mutator.itemenchant.mt');
                                            prize.addEnchant(mod:ItemEnchant.new(base:ItemEnchant.database.find(name:'Icy')));

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
                @key = world.party.inventory.items->filter(by:::(value) <- value.name == 'Wyvern Key of Ice');
                if (key != empty) key = key[0];
                // could be equipped by hooligans and jokesters
                if (key == empty) ::<= {
                    key = {:::} {
                        foreach(world.party.members)::(i, member) {
                            @:wep = member.getEquipped(slot:Item.EQUIP_SLOTS.HAND_LR);
                            if (wep.name == 'Wyvern Key of Ice') ::<= {
                                send(message:key);
                            }
                        }
                    }
                }
                @:canvas = import(module:'game_singleton.canvas.mt');
                windowEvent.queueMessage(
                    renderable:{render::{canvas.blackout();}},
                    text: 'You are whisked away to the island of Thunder...'
                );

                @:instance = import(module:'game_singleton.instance.mt');
                instance.visitIsland(where:key.islandEntry);
                doNext();                    
            }
        ]
    }
)


Scene.newEntry(
    data : {
        name : 'scene_wyvernthunder0',
        script: [
            ['???', '...'],
            ['???', 'Ah, ppuh-sho-zaaluh naan. Excellent.'],
            ['???', 'As we wait, we begin to wonder if someone will show with enough shiikohl surpass us.'],
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
                        
                        windowEvent.queueNoDisplay(
                            onEnter::{
                                windowEvent.jumpToTag(name:'MainMenu');                                    
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
                        speciesHint: 'Thunder Spawn',
                        professionHint: 'Thunder Spawn',
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
                @key = world.party.inventory.items->filter(by:::(value) <- value.name == 'Wyvern Key of Thunder');
                if (key != empty) key = key[0];
                // could be equipped by hooligans and jokesters
                if (key == empty) ::<= {
                    key = {:::} {
                        foreach(world.party.members)::(i, member) {
                            @:wep = member.getEquipped(slot:Item.EQUIP_SLOTS.HAND_LR);
                            if (wep.name == 'Wyvern Key of Thunder') ::<= {
                                send(message:key);
                            }
                        }
                    }
                }
                // you can technically throw it out or Literally Throw It.
                when(key == empty) ::<= {
                    windowEvent.queueMessage(
                        speaker: 'Juhriikaal',
                        text: 'Uhm. Where\'s the thunder key..?'
                    );
                    
                    @:item = Item.new(base:Item.database.find(name:'Wyvern Key of Thunder'));
                    windowEvent.queueMessage(text:'The party was given a ' + item.name + '.');
                    world.party.inventory.add(item);
                    key = item;

                    windowEvent.queueMessage(
                        speaker: 'Juhriikaal',
                        text: '...'
                    );
                }
                
                @:story = import(module:'game_singleton.story.mt');
                if (story.tier < 3)
                    story.tier = 3;
                
                @:instance = import(module:'game_singleton.instance.mt');
                // cancel and flush current VisitIsland session
                if (key.islandEntry == empty)
                    key.addIslandEntry(world);


                instance.visitIsland(where:key.islandEntry);
                if (windowEvent.canJumpToTag(name:'VisitIsland')) ::<= {
                    windowEvent.jumpToTag(name:'VisitIsland', goBeforeTag:true, doResolveNext:true);
                }

                breakpoint();
                doNext();
            }
            
            
            
        ]
    }
) 


Scene.newEntry(
    data : {
        name : 'scene_wyvernthunder1',
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
                            windowEvent.queueNoDisplay(
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
                                    'Apprentice\'s' : 'King\'s',
                                    'King\'s' : 'Queen\'s',
                                    'Queen\'s' : 'Masterwork',
                                    'Masterwork' : 'Legendary',
                                    'Legendary' : 'Divine',
                                    'Divine' : 'God\'s',
                                    'God\'s' : 'Null'
                                };

                                when(enhanced.quality == empty) 'Apprentice\'s';
                                // TODO: mod support?
                                when(improvementTree[enhanced.quality.name] == empty) 'Apprentice\'s';                               
                                
                                return improvementTree[enhanced.quality.name];
                            }
                            
                            windowEvent.queueMessage(speaker:'Juhriikaal', text:'This will improve ' +enhanced.name+ ' to be of quality ' + newQual + '. This will cost you 500G.');                                
                        
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
                                        enhanced.quality = ItemQuality.find(name:newQual);
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
                                windowEvent.queueNoDisplay(
                                    onEnter::{},
                                    onLeave::{doNext();} // always since no inventory anyway. cant change that.                          
                                );
                            }

                            when(world.party.inventory.gold < 500) ::<= {
                                windowEvent.queueMessage(speaker:'Juhriikaal', text:'Djiiroshuhzolii, Chosen. You have not enough gold for my services. You need at least 500G.');
                                windowEvent.queueNoDisplay(
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
                                        windowEvent.queueNoDisplay(
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
                @key = world.party.inventory.items->filter(by:::(value) <- value.name == 'Wyvern Key of Thunder');
                if (key != empty) key = key[0];
                // could be equipped by hooligans and jokesters
                if (key == empty) ::<= {
                    @:Entity = import(module:'game_class.entity.mt');
                    key = {:::} {
                        foreach(world.party.members)::(i, member) {
                            @:wep = member.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR);
                            if (wep.name == 'Wyvern Key of Thunder') ::<= {
                                send(message:key);
                            }
                        }
                    }
                }
                @:canvas = import(module:'game_singleton.canvas.mt');
                windowEvent.queueMessage(
                    renderable:{render::{canvas.blackout();}},
                    text: 'You are whisked away to another island...'
                );

                @:instance = import(module:'game_singleton.instance.mt');
                instance.visitIsland(where:key.islandEntry);
                doNext();                    
            }
        ]
    }
)



Scene.newEntry(
    data : {
        name : 'scene_wyvernlight0',
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
                        
                        windowEvent.queueNoDisplay(
                            onEnter::{
                                windowEvent.jumpToTag(name:'MainMenu');                                    
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
                        speciesHint: 'Guiding Light',
                        professionHint: 'Guiding Light',
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
                @:story = import(module:'game_singleton.story.mt');
                if (story.tier < 4)
                    story.tier = 4;

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
                                        Scene.start(name:'scene_wyvernlight0_wish', onDone::{}, location, landmark:location.landmark)
                                    else ::<= {
                                        @:world = import(module:'game_singleton.world.mt');
                                        world.accoladeEnable(name:'acceptedQuest');
                                        Scene.start(name:'scene_wyvernlight0_quest', onDone::{}, location, landmark:location.landmark);
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
        name : 'scene_wyvernlight0_wish',
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
        name : 'scene_wyvernlight0_quest',
        script: [
            ['Shaarraeziil', 'Chosen, from the bottom of my heart, thank you.'],
            ['Shaarraeziil', '...'],
            ['Shaarraeziil', 'You will need to prepare for the struggle ahead.'],
            ['Shaarraeziil', 'When you are ready, come to me once more.'],
            ['Shaarraeziil', 'Also... This may help with your battle.'],
            ::(location, landmark, doNext) {
                @:item = Item.new(
                    base: Item.database.find(name:'Greatsword'),
                    qualityHint: 'Divine',
                    materialHint: 'Dragonglass',
                    colorHint: 'Gold',
                    designHint: 'striking',
                    abilityHint: 'Greater Cure'
                );
                item.name = 'Wyvern\'s Hope';
                @:world = import(module:'game_singleton.world.mt');
                world.party.inventory.add(item);                                
                windowEvent.queueMessage(text:'The party was given the ' + item.name + '.');
                doNext();
            },
            ['Shaarraeziil', 'I forged this in hopes that our Chosen would be able to wield it.'],
            ['Shaarraeziil', 'Perhaps you don\'t need it, but it is for you regardless. Do with it as you like.'],



            ::(location, landmark, doNext) {
                windowEvent.queueNoDisplay(
                    keep : true,
                    onEnter ::{
                        doNext()
                    },
                    renderable : {
                        render ::{
                            canvas.blackout()
                        }
                    }
                );
            },
            
            ['', '(So! Congratulations, you would have gotten to the "good" ending if you continued!)'],
            ['', '(But, it\'s not ready yet. So let\'s just pretend you did it.)'],
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

            /*
            ::(location, landmark, doNext) {
                location.ownedBy.name = 'Shaarraeziil';
                @:world = import(module:'game_singleton.world.mt');
                @key = world.party.inventory.items->filter(by:::(value) <- value.name == 'Wyvern Key of Light');
                if (key != empty) key = key[0];
                // could be equipped by hooligans and jokesters
                if (key == empty) ::<= {
                    key = {:::} {
                        foreach(world.party.members)::(i, member) {
                            @:wep = member.getEquipped(slot:Item.EQUIP_SLOTS.HAND_LR);
                            if (wep.name == 'Wyvern Key of Light') ::<= {
                                send(message:key);
                            }
                        }
                    }
                }
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

                    
                    @:item = Item.new(base:Item.database.find(name:'Wyvern Key of Light'),
                             from:location.ownedBy);
                    windowEvent.queueMessage(text:'The party was given a ' + item.name + '.');
                    world.party.inventory.add(item);
                    key = item;
                }
                
                
                @:instance = import(module:'game_singleton.instance.mt');
                // cancel and flush current VisitIsland session
                if (key.islandEntry == empty)
                    key.addIslandEntry(world);


                instance.visitIsland(where:key.islandEntry);
                if (windowEvent.canJumpToTag(name:'VisitIsland')) ::<= {
                    windowEvent.jumpToTag(name:'VisitIsland', goBeforeTag:true, doResolveNext:true);
                }

                breakpoint();
                doNext();
            },  
            */
            

        ]
    }
)

Scene.newEntry(
    data : {
        name : 'scene_sentimentalbox',
        script: [
            ::(location, landmark, doNext) {
                @:story = import(module:'game_singleton.story.mt');
                when(story.openedSentimentalBox) 
                    windowEvent.queueMessage(text:
                        "The box is empty."
                    );
                story.openedSentimentalBox = true;
                doNext();
            },
            ['', 'Opening the box reveals items inside!'],
            ['', 'The party receives 250G.'],
            ['', 'The party receives 3 Pink Potions.'],
            ['', 'The party receives a Life Crystal.'],
            ['', 'The party receives a Skill Crystal.'],
            ['', 'The party also receives an equippable Tome.'],
            ['', 'There\'s also a note here...'],
            ::(location, landmark, doNext) {
                @:Entity = import(module:'game_class.entity.mt');
                @:someone = Entity.new(levelHint:5);
                windowEvent.queueMessage(text:
                    (random.pickArrayItem(
                        list : [
                            '"I know we haven\'t always seen eye-to-eye; I know that we argue a lot. But when I heard you were leaving on your big adventure or whatever, I knew that I had to help. Here\'s some stuff I gathered over the years. I figure you\'ll get more use out of it than I ever will. Stay safe out there, and come back alive!"',
                            '"Well, I didn\'t think the day would come, but here we are. I don\'t know about this \"Chosen\" nonsense, but I do know you well enough to know when you\'re determined to do something. I hope you find this stuff useful for your journey. I\'ll miss you."',
                            '"You know, you\'re a real pain. All of a sudden you want to go on a big adventure, huh? Whatever. Just take this stuff. Put it to good use and stay alive. You might find it hard to believe, but I\'ll miss you. Do good out there."',
                            '"There comes a time when someone has to take action and do something big. I saw it in your eyes the moment you told me. I could tell it was hard for you, too. Just know that you have my blessing. Let the items in this box be proof of that. I\'m proud of you. Stay alive out there."',
                            '"So, it\'s finally time. We always knew you were an adventurer at heart. We prepared for the day you would finally go out into the world on your own. It might be tough, but we truly think you can overcome anything. Hopefully you\'ll find these useful on your journey. Be strong."',
                            '"Ever since '+(Entity.new(levelHint:10).name)+' left, you\'ve never been the same. Always looking out there thinking of a way to find them. I think that this "Chosen" thing is just another excuse to go out and look, but I can\'t blame you. I miss them too. Either way, stay safe and come back in one piece. Hopefully these will come in handy."' 
                        ]
                    )) + '\n\n - ' + someone.name
                );

                @:world = import(module:'game_singleton.world.mt');
                world.party.inventory.addGold(amount:250);

                world.party.inventory.add(item:Item.new(base:Item.database.find(name:'Life Crystal'
                )));
                
                
                for(0, 1)::(i) {
                    @:crystal = Item.new(base:Item.database.find(name:'Skill Crystal'));
                    world.party.inventory.add(item:crystal);
                }

                //party.inventory.add(item:keyhome);


                world.party.inventory.add(item:Item.new(
                    base:Item.database.find(name:'Pink Potion')
                ));
                world.party.inventory.add(item:Item.new(
                    base:Item.database.find(name:'Pink Potion')
                ));
                world.party.inventory.add(item:Item.new(
                    base:Item.database.find(name:'Pink Potion')
                ));
                
                @tome = Item.new(
                    base:Item.database.find(name:'Tome'),
                    abilityHint: 'Cure',
                    materialHint: 'Hardstone',
                    qualityHint: 'Worn'
                );
                world.party.inventory.add(item:tome);                

                
                doNext();
                
            }
        ]
    }
)






Scene.newEntry(
    data : {
        name : 'trader.scene_intro',
        script: [
            ['???', '...Greetings, mortal.'],
            ['???', 'Congratulations! For I, Shiikaakael, the Wyvern of Fortune, have chosen YOU for a once-in-alifetime opportunity.'],
            ['Shiikaakael, Wyvern of Fortune', 'You see, my hoard of treasure is looking a bit... small. I require riches.'],
            ['Shiikaakael, Wyvern of Fortune', 'If you bring me gold, I will grant you a wish. Anything you like. Doesn\'t that sound wonderful?'],
            ['Shiikaakael, Wyvern of Fortune', 'Bring me.... Hummm... Let us say, 10,000G and a wish shall be yours.'],
            ['Shiikaakael, Wyvern of Fortune', 'Your meager, drab existence as a simple trader is no more! Now you have something to drive you!'],
            ['Shiikaakael, Wyvern of Fortune', 'Go forth, mortal! Get riches! Exploit! Your wish awaits!'],
        ]
    }
)     

Scene.newEntry(
    data : {
        name : 'trader.scene_bankrupt',
        script: [
            ['???', '...'],
            ['Shiikaakael, Wyvern of Fortune', '...Mortal... I have sensed something...'],
            ['Shiikaakael, Wyvern of Fortune', '...most disappointing. The absence of riches.'],
            ['Shiikaakael, Wyvern of Fortune', 'What\'s worse is those were MY riches that you lost...'],
            ['Shiikaakael, Wyvern of Fortune', '...Bah. Dreadful. Disgusting, even.'],
            ['Shiikaakael, Wyvern of Fortune', 'This is why I don\'t do anything with lesser creatures... Be gone, you.'],
        ]
    }
)


Scene.newEntry(
    data : {
        name : 'trader.scene_gold0',
        script: [
            ['???', '...'],
            ['Shiikaakael, Wyvern of Fortune', '...Mortal... I have sensed that you have my riches ready!'],
            ['Shiikaakael, Wyvern of Fortune', 'I can hardly wait. I will bring you to me at once!'],
            ['', 'Magic lifts you off your feet and transports you to a new land...'],
            ::(location, landmark, doNext) {
                @:world = import(module:'game_singleton.world.mt');
                @:instance = import(module:'game_singleton.instance.mt');
                @:Landmark = import(module:'game_mutator.landmark.mt');

                @:d = world.island.newLandmark(
                    base:Landmark.database.find(name:'Fortune Wyvern Dimension')
                );
                instance.visitLandmark(landmark:d);             
                doNext();
            }
        ]
    }
)


Scene.newEntry(
    data : {
        name : 'trader.scene_gold1-0',
        script: [
            ['Shiikaakael, Wyvern of Fortune', 'Mortal, show me the fruits of your labor...!'],
            ['Shiikaakael, Wyvern of Fortune', '...'],
            ['Shiikaakael, Wyvern of Fortune', '.......'],
            ['Shiikaakael, Wyvern of Fortune', '..........'],
            ['Shiikaakael, Wyvern of Fortune', 'I\'ll be honest. 10,000G looks a tad... smaller... in person than I was hoping.'],
            ['Shiikaakael, Wyvern of Fortune', 'Surely, you are capable of much more! Let me think...'],
            ['Shiikaakael, Wyvern of Fortune', '...Perhaps If you came back with 80,000G! Yes! That would be wonderful.'],
            ['Shiikaakael, Wyvern of Fortune', 'Obedient mortal, I have decided. Keep your 10,000G. Instead, I will come for you when you have 80,000G. This feels much more befitting of the cost of a wish, does it not?'],
            ['Shiikaakael, Wyvern of Fortune', '...'],
            ['Shiikaakael, Wyvern of Fortune', 'Well. Go get my riches! Shoo!'],
            ['', 'The Wyvern\'s magic lifts you off your feet and transports you home...'],
            ::(location, landmark, doNext) {
                @:world = import(module:'game_singleton.world.mt');
                @:instance = import(module:'game_singleton.instance.mt');


                instance.visitIsland(restorePos:true);                
            }
        ]
    }
)

Scene.newEntry(
    data : {
        name : 'trader.scene_gold1-1',
        script: [
            ['Shiikaakael, Wyvern of Fortune', 'Mortal, you have done it! 80,000G in all its glory!'],
            ['Shiikaakael, Wyvern of Fortune', '...'],
            ['Shiikaakael, Wyvern of Fortune', '.......'],
            ['Shiikaakael, Wyvern of Fortune', '..........'],
            ['Shiikaakael, Wyvern of Fortune', 'Hmm. I was thinking it would fill me with joy seeing all these riches. But something about it still feels...'],
            ['Shiikaakael, Wyvern of Fortune', '...too small.'],
            ['Shiikaakael, Wyvern of Fortune', 'Surely, you are capable of much more! Let me think...'],
            ['Shiikaakael, Wyvern of Fortune', '...Perhaps If you came back with 250,000G! Yes! That would be perfect.'],
            ['Shiikaakael, Wyvern of Fortune', 'Obedient mortal, I have decided. Keep your 80,000G. Instead, I will come for you when you have 250,000G. This feels much more befitting of the cost of a wish, does it not?'],
            ['Shiikaakael, Wyvern of Fortune', '...'],
            ['Shiikaakael, Wyvern of Fortune', 'Well. Go get my riches! Shoo!'],
            ['', 'The Wyvern\'s magic lifts you off your feet and transports you home...'],
            ::(location, landmark, doNext) {
                @:world = import(module:'game_singleton.world.mt');
                @:instance = import(module:'game_singleton.instance.mt');


                instance.visitIsland(restorePos:true);                
            }
        ]
    }
)


Scene.newEntry(
    data : {
        name : 'trader.scene_gold1-2',
        script: [
            ['Shiikaakael, Wyvern of Fortune', 'Mortal... Let me see it. What you have done. What you have brought me!'],
            ['Shiikaakael, Wyvern of Fortune', '...'],
            ['Shiikaakael, Wyvern of Fortune', '.......'],
            ['Shiikaakael, Wyvern of Fortune', '..........'],
            ['Shiikaakael, Wyvern of Fortune', '...It\'s glorious! It\'s perfect!'],
            ['Shiikaakael, Wyvern of Fortune', 'Never have I seen so much mortal gold! This will be a wonderful addition to my hoard.'],
            ['Shiikaakael, Wyvern of Fortune', '...Yes, oh yes!'],
            ['Shiikaakael, Wyvern of Fortune', 'I\'m unable to fathom how are able to even carry that with you! 250,000G is enough to swim in, even for a creature such as me!'],
            ['Shiikaakael, Wyvern of Fortune', '...Well. You have earned it. Here is your wish.'],
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
}

@:Scene = class(
    inherits:[Database],
    define::(this) {
        this.interface = {
            start::(name, onDone => Function, location, landmark) {
                @:scene = this.find(name);
                if (scene == empty)
                    error(detail:'No such scene ' + name);
                    
                @:left = [...scene.script];
                
                @:doNext ::{
                    when(left->keycount == 0) onDone();
                    @:action = left[0];
                    left->remove(key:0);
                    match(action->type) {
                      (Function):
                        action(location, landmark, doNext),
                      
                      (Object): ::<= {
                        windowEvent.queueMessage(speaker: action[0], text: action[1]);
                        windowEvent.queueNoDisplay(onEnter:doNext);
                      },
                      default:
                        error(detail:'Scene scripts only accept arrays or functions')
                    }
                }
                
                doNext();
            }    
        }
    }
).new(
    name : 'Wyvern.Scene',
    attributes : {
        name : String,
        script : Object
    },
    reset
);



return Scene;