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
@:Entity = import(module:'game_class.entity.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:g = import(module:'game_function.g.mt');


@:Party = LoadableClass.create(
    name: 'Wyvern.Party',
    items : {
        inventory : empty,
        members : empty,
        karma : 5500,
        arts : [],
        leader : 0
    },

    define:::(this, state) {   
                
        this.interface = {    
            initialize :: {},
            defaultLoad ::{            
                state.members = [];
            },
            reset ::{
                state.members = [];
                state.inventory = Inventory.new(size:40);
            },
            
            leader : {
                get ::<- state.members[state.leader],
                set ::(value) {
                    state.leader = state.members->findIndex(:value);
                    if (state.leader < 0)
                        state.leader = 0
                }
            },
        
            add::(member => Entity.type) {
                // no repeats, please
                when(state.members->any(condition::(value) <- value == member)) empty;                
                /*
                member.inventory.items->foreach(do:::(index, item) {
                    inventory.add(item);                    
                });
                member.inventory.clear();
                */

                state.members->push(value:member);
                
            },
            
            getItemAtAll ::(id) {
                @key = this.inventory.items->filter(by:::(value) <- value.base.id == id);
                when (key->size != 0) key[0];

                // could be equipped
                return {:::} {
                    foreach(this.members)::(i, member) {
                        foreach(Entity.EQUIP_SLOTS) ::(n, slot) {
                            @:wep = member.getEquipped(slot);
                            if (wep.base.id == id) ::<= {
                                send(message:wep);
                            }
                        }
                    }
                }                
            },
            
            inventory : {
                get :: <- state.inventory
            },
            
            isMember::(entity => Entity.type) {
                return state.members->any(condition:::(value) <- value == entity);
            },

            isMemberID::(id => Number) {
                return state.members->any(condition:::(value) <- value.worldID == id);
            },
                        
            remove::(member => Entity.type) {
                {:::}{
                    foreach(state.members)::(index, m) {
                        if (m == member)::<={
                            breakpoint();
                            state.members->remove(key:index);
                            windowEvent.queueMessage(text:m.name + ' has been removed from the party.');
                            send();
                        }                        
                    }
                }
            },
            
            isIncapacitated :: {
                return state.members->all(condition:::(value) <- value.isIncapacitated());
            },
            
            addSupportArt ::(id) {
                @index = state.arts->findIndexCondition(::(value) <- value.id == id);
                when(index == -1) ::<={
                    state.arts->push(:{
                        id: id,
                        count: 1
                    });
                }
                
                state.arts[index].count+=1;
            },
            
            takeSupportArt ::(id) {
                @index = state.arts->findIndexCondition(::(value) <- value.id == id);
                when(index == -1) empty;
                state.arts[index].count-=1;
                if (state.arts[index].count == 0) 
                    state.arts->remove(:index);
            },
            
            arts : {
                get ::<- [...state.arts]
            },
            
            addGoldAnimated ::(amount, onDone) {
                @gained = amount;
                @oldG = this.inventory.gold;
                @price = gained;
                windowEvent.queueCustom(
                    onEnter ::{},
                    isAnimation: true,
                    onInput ::(input) {
                        match(input) {
                          (windowEvent.CURSOR_ACTIONS.CONFIRM,
                           windowEvent.CURSOR_ACTIONS.CANCEL):
                            price = 0
                        }
                    },
                    animationFrame ::{
                        canvas.renderTextFrameGeneral(
                            leftWeight: 0.5,
                            topWeight : 0.5,
                            lines : [
                                'Current funds: ' + g(g:oldG),
                                if (price >= 0)
                                '              +' + g(g:price)
                                else
                                '              ' + g(g:price)
                            ]
                        );
                        
                        when(price->abs <= 0) ::<= {
                            if (gained > 0)
                                this.inventory.addGold(amount:gained)
                            else
                                this.inventory.subtractGold(amount:-gained);

                            return canvas.ANIMATION_FINISHED
                        }
                        
                        @newPrice = if (price < 0) (price * 0.9)->ceil else (price*0.9)->floor;
                        @red = newPrice - price;
                        price += red;
                        oldG -= red;
                    }
                );
                
                windowEvent.queueDisplay(
                    leftWeight: 0.5,
                    topWeight : 0.5,
                    lines : [
                        'Current funds: ' + g(g:oldG + gained),
                        '               '
                    ],
                    skipAnimation : true
                )
                
                windowEvent.queueCustom(
                    onEnter :: {
                        onDone();
                    }
                );
            },
            
        
            members : {
                get ::<- state.members
            },
            
            clear :: {
                state.inventory.clear();
                state.members = [];            
            },
            
            karma : {
                get ::<- state.karma,
                set ::(value) <- state.karma = value
            }
        }
    }
);
return Party;
