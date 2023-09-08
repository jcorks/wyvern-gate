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
@:StatSet = import(module:'game_class.statset.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Item = import(module:'game_class.item.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:Scene = class(
    name : 'Wyvern.Scene',
    inherits : [Database.Item],
    new ::(data) {
        @:this = Scene.defaultNew();
        this.initialize(data);
        return this;
    },
    statics : {
        database  :::<= {
            @db = Database.new(
                attributes : {
                    name : String,
                    script : Object
                }
            );

            return {
                get ::<- db,
            }
        }
    },
    define:::(this) {
        
        this.interface = {
        
            act::(onDone => Function, location, landmark) {
                @:left = [...this.script];
                
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
        
        Scene.database.add(item:this);
    }
);

Scene.new(
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



Scene.new(
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

                    when(result == Battle.RESULTS.ENEMIES_WIN) ::<= {
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
            ['Kaedjaal', 'Ha ha ha, splendid! Chosen, that was excellent. You have shown how well you can handle yourthis.'],
            ['Kaedjaal', 'However, be cautious: you are not the first to have triumphed over me.'],
            ['Kaedjaal', 'There are many with their own goals and ambitions, and some will be more skilled that you currently are.'],
            ['Kaedjaal', 'Well, I hope you enjoyed this little visit. Come and see me any time.'],
            ['Kaedjaal', 'Please hand me the key and I will send you on your way.'],
            ['', 'The party hands over the Wyvern Key of Fire.'],
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
                            @:wep = member.getEquipped(slot:Item.EQUIP_SLOTS.HAND_L);
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
                        base:Item.Base.database.find(name:'Wyvern Key of Fire'
                                ),
                        from:location.ownedBy
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

Scene.new(
    data : {
        name : 'scene_wyvernfire1',
        script: [
            ['Kaedjaal', 'Rrohziil shaa jiin, you have come to check on me, eh?'],
            ['Kaedjaal', 'Welcome back to my domain, Chosen. I am happy that you have returned.'],
            ['Kaedjaal', 'Perhaps you are interested in a trade? I have a habit of collecting trinkets.'],
            ['Kaedjaal', 'If you give me 3 items, I will give you 1 item from my hoard.'],
            ::(location, landmark, doNext) {
                @:world = import(module:'game_singleton.world.mt');
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
                            when (item == empty && runOnce) ::<= {
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
                            if (item != empty) ::<= {
                                if (item.name == 'Wyvern Key of Fire') ::<= {
                                    windowEvent.queueMessage(speaker:'Kaedjaal', text:'Rrohziil, you... cannot trade me with the Key of Fire. You need that to leave here.');
                                } else ::<= {
                                    items->push(value:item);
                                    world.party.inventory.remove(item);                                    
                                }
                            }
                            
                            when(items->keycount == 3) ::<= {
                                windowEvent.queueMessage(speaker:'Kaedjaal', text:'Excellent. Let me, in exchange, give you this.');   
                                @:item = Item.new(
                                    base:Item.Base.database.getRandomFiltered(
                                        filter:::(value) <- value.isUnique == false && value.canHaveEnchants && value.hasMaterial
                                    ),
                                    rngEnchantHint:true, 
                                    from:location.landmark.island.newInhabitant(), 
                                    colorHint:'Red', 
                                    materialHint: 'Gold'
                                );
                                @:ItemEnchant = import(module:'game_class.itemenchant.mt');
                                item.addEnchant(mod:ItemEnchant.new(base:ItemEnchant.Base.database.find(name:'Burning')));
                                item.addEnchant(mod:ItemEnchant.new(base:ItemEnchant.Base.database.find(name:'Burning')));


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
                            
                            
                            
                            @:pickitem = import(module:'game_function.pickitem.mt');
                            runOnce = true;
                            pickitem(
                                inventory: world.party.inventory,
                                leftWeight: 0.5,
                                topWeight: 0.5,
                                canCancel:true,
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
                    key = {:::} {
                        foreach(world.party.members)::(i, member) {
                            @:wep = member.getEquipped(slot:Item.EQUIP_SLOTS.HAND_L);
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


Scene.new(
    data : {
        name : 'scene_wyvernice0',
        script: [
            ['???',      '...'],
            ['???', '... Another Chosen, or so you would be called.'],
            ['???', 'Why my sibling wastes our time with some of these karrjuhzaalii to us is a mystery to me.'],
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

                    when(result == Battle.RESULTS.ENEMIES_WIN) ::<= {
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
            ['Ziikkaettaal', 'I... I see. Kaedjaal was perhaps right to let you continue to me.'],
            ['Ziikkaettaal', 'It has been some time since I have let another Chosen pass.'],
            ['Ziikkaettaal', 'You have handled yourthis well.'],
            ['', 'The party hands over the Wyvern Key of Ice.'],
            ['Ziikkaettaal', 'May you find peace and prosperity in your heart. Remember: seek the shrine to find the Key.'],
            ::(location, landmark, doNext) {
                location.ownedBy.name = 'Kaedjaa, Wyvern of Ice';
                @:world = import(module:'game_singleton.world.mt');
                @key = world.party.inventory.items->filter(by:::(value) <- value.name == 'Wyvern Key of Fire');
                if (key != empty) key = key[0];
                // could be equipped by hooligans and jokesters
                if (key == empty) ::<= {
                    key = {:::} {
                        foreach(world.party.members)::(i, member) {
                            @:wep = member.getEquipped(slot:Item.EQUIP_SLOTS.HAND_L);
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
                    
                    @:item = Item.new(base:Item.Base.database.find(name:'Wyvern Key of Ice'),
                             from:location.ownedBy);
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

Scene.new(
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
                            text: 'Prepare yourthis.',
                            onLeave::{
                                @:dice = import(module:'game_function.dice.mt');
                                dice(
                                    onFinish::(partyWins) {
                                    
                                        windowEvent.queueMessage(
                                            text:(if (partyWins) 'The party' else 'Ziikkaettaal') + ' wins!'
                                        );
                                    
                                        if (partyWins) ::<= {
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
                                                base: Item.Base.database.getRandomFiltered(
                                                    filter:::(value) <- value.isUnique == false && value.canHaveEnchants && value.hasMaterial && value.attributes->findIndex(value:Item.ATTRIBUTE.WEAPON) != -1
                                                ),
                                                rngEnchantHint:true, 
                                                from:location.landmark.island.newInhabitant(), 
                                                colorHint:'Blue', 
                                                materialHint: 'Mythril', 
                                                qualityHint: 'Masterwork'
                                            );
                                            @:ItemEnchant = import(module:'game_class.itemenchant.mt');
                                            prize.addEnchant(mod:ItemEnchant.new(base:ItemEnchant.Base.database.find(name:'Icy')));

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
                            @:wep = member.getEquipped(slot:Item.EQUIP_SLOTS.HAND_L);
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

return Scene;
