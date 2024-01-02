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
@:State = import(module:"game_class.state.mt");
@:LoadableClass = import(module:"game_singleton.loadableclass.mt");
@:Entity = import(module:'game_class.entity.mt');
@:EntityQuality = import(module:'game_class.entityquality.mt');
@:Item = import(module:'game_class.item.mt');
@:Story = LoadableClass.new(
    name : 'Wyvern.Story',
    new ::(parent, state) {
        @:this = Story.defaultNew();
        if (state != empty)
            this.load(serialized:state);
        return this;
    },
    define::(this) {
        @state;
        ::<= {
            @:items = {
                // whether the Fire Key is has been given to the party
                foundFireKey : false,

                // whether the Ice Key has been given to the party
                foundIceKey : false,

                // whether the thunder key has been given to the party
                foundThunderKey : false,

                // whether the light key has been given to the party        
                foundLightKey : false,
                
                // whether the dark key has been given to the party
                hasDarkKey : false,
                
                // Whether the initial box has been opened.
                openedSentimentalBox : false,
                
                // whether the player has seen the wandering gamblist
                skieEncountered : false,
                
                // The recurring NPCs in the game that are recruitable
                npcs: {},
                
                
                // progression of defeated wyverns
                // tier 0 -> none 
                // tier 1 -> fire 
                // tier 2 -> ice 
                // tier 3 -> thunder 
                // tier 4 -> light 
                tier : 0,
                
                levelHint : 6,
                
                // Number of discovered locations
                data_locationsDiscovered : 0,
                
                data_locationsNeeded : 25
            }
            @:interface = {
                save ::{
                    return state.save()
                },
                
                load::(serialized) {
                    state.load(parent:this, serialized);
                }
            
            };
            foreach(items) ::(item, val) {
                interface[item] = {
                    get ::<- state[item],
                    set ::(value) <- state[item] = value
                }
            }
            state = State.new(items);

            this.interface = interface;
        }
        
        
    }

);

return Story.new();
