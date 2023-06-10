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
@:dialogue = import(module:'game_singleton.dialogue.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Item = import(module:'game_class.item.mt');
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
                      
                      (Object): 
                        dialogue.message(speaker: action[0], text: action[1], onNext:doNext),
                        
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
                    ['???', '...'],
                    ['???', '...You.. you have been chosen...'],
                    ['???', 'Among those of the world, the Chosen are selected...'],
                    ['???', '...Selected to seek me, the Wyvern of Light...'],
                    ['???', 'If you seek me, I will grant you and anyone with you a wish...'],
                    ['???', 'But be warned: others will seek their own wish and will accept no others...'],
                    ['???', 'Come, chosen: seek me and the Gate Keys among the Shrines...'],
                    ['???', '...I will await you, Chosen...'],
                ]
            }
        ),     
 


        Scene.new(
            data : {
                name : 'scene_wyvernfire0',
                script: [
                    //           "Another who comes"
                    ['???',      'Nohdjaezo kaaj juhrruhnkii...'],
                    ['???',      'Welcome... to my domain, Chosen. You have done well to get here.'],
                    ['???',      'You have been summoned, but not by me. My sibling is the one who calls for you.'],
                    ['???',      'But to get to them, I must evaluate you to see if you are truly worthy of seeing the Wyvern of Light.'],
                    ['Kaedjaal', 'My name is Kaedjaal, and my domain is that of flame. I enjoy a summer\'s day as much as the next, but I\'ll be honest with you; I take it a step further.'],
                    ['Kaedjaal', 'Dancing in the fire, my test looks inward: your will, your determination, what moves you.'],
                    ['Kaedjaal', 'Chosen, can you stand my flames? Can you triumph over uncertain and, at times, unfair odds? Show me your power.'],
                    ['Kaedjaal', 'Come forth.'],
                    ::(location, landmark, doNext) {
                        @:world = import(module:'game_singleton.world.mt');
                        @:Battle = import(module:'game_class.battle.mt');

                        @:end = ::(result){

                            when(result == Battle.RESULTS.ENEMIES_WIN) ::<= {
                                dialogue.message(
                                    speaker:'Kaedjaal',
                                    text:'Perhaps it was not meant to be...',
                                    onNext ::{                                    
                                        dialogue.jumpToTag(name:'MainMenu');
                                    }
                                );
                            };
                            
                        
                            when (!location.ownedBy.isIncapacitated()) ::<= {
                                world.battle.start(
                                    party: world.party,                            
                                    allies: world.party.members,
                                    enemies: [location.ownedBy],
                                    landmark: landmark,
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
                            onEnd::(result) {
                                end(result);
                            }
                        );                         
                    },
                    ['Kaedjaal', 'Ha ha ha, splendid! Chosen, that was excellent. You have shown how well you can handle yourself.'],
                    ['Kaedjaal', 'However, be cautious: you are not the first to have triumphed over me.'],
                    ['Kaedjaal', 'There are many with their own goals and ambitions, and some will be more skilled that you currently are.'],
                    ['Kaedjaal', 'Well, I hope you enjoyed this little visit. Come and see me any time.'],
                    ['Kaedjaal', 'I will send you on your way. Remember: seek the shrine to find the Key.'],
                    ['Kaedjaal', 'May you find peace and prosperity in your heart. ']
                ]
            }
        ),     

        
        
    ]
);

return Scene;
