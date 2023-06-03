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
@:Random = import(module:'game_singleton.random.mt');
@:BattleAction = import(module:'game_struct.battleaction.mt');
@:class  = import(module:'Matte.Core.Class');
@:Ability = import(module:'game_class.ability.mt');

return class(
    name: 'Wyvern.BattleAI',
    define:::(this) {
        @user_;
        
        @enemies_;
        @allies_;
    
        
        this.constructor = ::(
            user => Object
        ) {
            user_ = user;
            return this;
        };
    
        this.interface = {
            state : {
                set ::(value) {
                
                },
                get :: {
                    return {};                
                }
            },
            reset ::(
                allies,
                enemies,
            ) {
                enemies_ = enemies;
                allies_ = allies;
                
            },
            
            takeTurn ::(battle){
                when(enemies_->keycount == 0)
                    battle.entityCommitAction(action:BattleAction.new(
                        state : {
                            ability: Ability.database.find(name:'Wait'),
                            targets: [],
                            extraData: {}                        
                        }
                    ));
            
                battle.entityCommitAction(action:BattleAction.new(
                    state : {
                        ability: 
                            user_.abilitiesAvailable[0],
                            //Ability.database.find(name:'Bribe'),

                        targets: [
                            Random.pickArrayItem(list:enemies_)
                        ],
                        extraData: {}                        
                    }
                ));            
            }
        };   
    }  

);
