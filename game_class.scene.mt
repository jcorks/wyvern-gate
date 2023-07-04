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
    statics : {
        database : empty
    },
    define:::(this) {
        Database.setup(
            item: this,
            attributes : {
                name : String,
                script : Object
            }
        );
        
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
                    };
                };
                
                doNext();
            }
        };
    }
);

Scene.database = Database.new(
    items : [
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
        ),     
 


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
                            };
                            
                        
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
                            }; 
                            
                            doNext();
                        };
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
                            key = [::] {
                                world.party.members->foreach(do:::(i, member) {
                                    @:wep = member.getEquipped(slot:Item.EQUIP_SLOTS.HAND_L);
                                    if (wep.name == 'Wyvern Key of Fire') ::<= {
                                        send(message:key);
                                    };
                                });
                            };
                        };
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
                            
                            @:item = Item.Base.database.find(name:'Wyvern Key of Fire'
                                        ).new(from:location.ownedBy);
                            windowEvent.queueMessage(text:'The party was given a ' + item.name + '.');
                            world.party.inventory.add(item);
                            key = item;

                            windowEvent.queueMessage(
                                speaker: 'Kaedjaal',
                                text: 'Rrohziil, Please keep it safe. It breaks my heart to give these away to Chosen who already should have one...'
                            );
                        };
                        
                        @:story = import(module:'game_singleton.story.mt');
                        if (story.tier < 1)
                            story.tier = 1;
                        
                        @:instance = import(module:'game_singleton.instance.mt');
                        // cancel and flush current VisitIsland session
                        instance.visitIsland(where:key.islandEntry);
                        if (windowEvent.canJumpToTag(name:'VisitIsland')) ::<= {
                            windowEvent.jumpToTag(name:'VisitIsland', goBeforeTag:true, doResolveNext:true);
                        };

                        breakpoint();
                        doNext();
                    }
                    
                    
                    
                ]
            }
        ), 
        
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
                                        onStart::{doNext();}                                    
                                    );
                                };


                                when(world.party.inventory.items->keycount < 3) ::<= {
                                    windowEvent.queueMessage(speaker:'Kaedjaal', text:'Djiiroshuhzolii, Chosen. You have not enough items to complete a trade.');
                                    windowEvent.queueNoDisplay(
                                        onStart::{doNext();}                                    
                                    );
                                };

                                
                                
                                @items = [];
                                @runOnce = false;
                                @chooseItem = ::(item) {
                                    when (item == empty && runOnce) ::<= {
                                        // re-add the items
                                        items->foreach(do:::(i, item) {
                                            world.party.inventory.add(item);
                                        });
                                        // cancelled by user
                                        windowEvent.queueMessage(speaker:'Kaedjaal', text:'Having second thoughts? No matter. I will still be here if you change your mind.');    
                                        windowEvent.queueNoDisplay(
                                            onStart::{doNext();}                                    
                                        );
                                                        
                                    };
                                    if (item != empty) ::<= {
                                        if (item.name == 'Wyvern Key of Fire') ::<= {
                                            windowEvent.queueMessage(speaker:'Kaedjaal', text:'Rrohziil, you... cannot trade me with the Key of Fire. You need that to leave here.');
                                        } else ::<= {
                                            items->push(value:item);
                                            world.party.inventory.remove(item);                                    
                                        };
                                    };
                                    
                                    when(items->keycount == 3) ::<= {
                                        windowEvent.queueMessage(speaker:'Kaedjaal', text:'Excellent. Let me, in exchange, give you this.');   
                                        @:item = Item.Base.database.getRandomFiltered(
                                            filter:::(value) <- value.isUnique == false && value.canHaveEnchants && value.hasMaterial
                                        ).new(rngEnchantHint:true, from:location.landmark.island.newInhabitant(), colorHint:'Red', materialHint: 'Gold');
                                        @:ItemEnchant = import(module:'game_class.itemenchant.mt');
                                        item.addEnchant(mod:ItemEnchant.Base.database.find(name:'Burning').new());
                                        item.addEnchant(mod:ItemEnchant.Base.database.find(name:'Burning').new());


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
                                                };
                                                doNext();
                                            }
                                        );
                                    };
                                    
                                    
                                    
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
                                };
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
                            key = [::] {
                                world.party.members->foreach(do:::(i, member) {
                                    @:wep = member.getEquipped(slot:Item.EQUIP_SLOTS.HAND_L);
                                    if (wep.name == 'Wyvern Key of Fire') ::<= {
                                        send(message:key);
                                    };
                                });
                            };
                        };

                        @:instance = import(module:'game_singleton.instance.mt');
                        instance.visitIsland(where:key.islandEntry);
                        doNext();                    
                    }
                ]
            }
        ),


        Scene.new(
            data : {
                name : 'scene_wyvernice0',
                script: [
                    ['???',      '...'],
                    ['???', '... Another Chosen, or so you would be called.'],
                    ['???', 'WHy my sibling wastes our time with some of these karrjuhzaalii to us is a mystery to me.'],
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
                            };
                            
                        
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
                            }; 
                            
                            doNext();
                        };
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
                    ['Ziikkaettaal', 'You have handled yourself well.'],
                    ['', 'The party hands over the Wyvern Key of Ice.'],
                    ['Ziikkaettaal', 'May you find peace and prosperity in your heart. Remember: seek the shrine to find the Key.'],
                    ::(location, landmark, doNext) {
                        location.ownedBy.name = 'Kaedjaa, Wyvern of Ice';
                        @:world = import(module:'game_singleton.world.mt');
                        @key = world.party.inventory.items->filter(by:::(value) <- value.name == 'Wyvern Key of Fire');
                        if (key != empty) key = key[0];
                        // could be equipped by hooligans and jokesters
                        if (key == empty) ::<= {
                            key = [::] {
                                world.party.members->foreach(do:::(i, member) {
                                    @:wep = member.getEquipped(slot:Item.EQUIP_SLOTS.HAND_L);
                                    if (wep.name == 'Wyvern Key of Ice') ::<= {
                                        send(message:key);
                                    };
                                });
                            };
                        };
                        // you can technically throw it out or Literally Throw It.
                        when(key == empty) ::<= {
                            windowEvent.queueMessage(
                                speaker: 'Ziikkaettaal',
                                                //(Friend   of   Me)  My friend...
                                text: '*tells you off in dragonish*'
                            );
                            
                            @:item = Item.Base.database.find(name:'Wyvern Key of Ice'
                                        ).new(from:location.ownedBy);
                            windowEvent.queueMessage(text:'The party was given a ' + item.name + '.');
                            world.party.inventory.add(item);
                            key = item;

                            windowEvent.queueMessage(
                                speaker: 'Ziikkaettaal',
                                text: '*hisses*'
                            );
                        };
                        
                        @:story = import(module:'game_singleton.story.mt');
                        if (story.tier < 2)
                            story.tier = 2;
                        
                        @:instance = import(module:'game_singleton.instance.mt');
                        // cancel and flush current VisitIsland session
                        instance.visitIsland(where:key.islandEntry);
                        if (windowEvent.canJumpToTag(name:'VisitIsland')) ::<= {
                            windowEvent.jumpToTag(name:'VisitIsland', goBeforeTag:true, doResolveNext:true);
                        };

                        breakpoint();
                        doNext();
                    }
                    
                    
                    
                ]
            }
        ), 
        
            

        
        
    ]
);

return Scene;
