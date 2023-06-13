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
@:struct = import(module:'game_struct.mt');


return struct(
    name: 'Wyvern.StoryFlags',
    
    items : {
        // whether the Fire Key is has been given to the party
        foundFireKey : Boolean,

        // whether the Ice Key has been given to the party
        foundIceKey : Boolean,

        // whether the thunder key has been given to the party
        foundThunderKey : Boolean,

        // whether the light key has been given to the party        
        foundLightKey : Boolean,
        
        // whether the dark key has been given to the party
        hasDarkKey : Boolean,
        
        
        
        
        
        // whether the wyvern of fire has been defeated
        defeatedWyvernFire : Boolean,
        
        defeatedWyvernIce : Boolean,
        
        defeatedWyvernThunder : Boolean,
        
        defeatedWyvernLight : Boolean,
        
        
        
        // Number of discovered locations
        data_locationsDiscovered : Number,
        
        data_locationsNeeded : Number
    }
).new(state: {
    foundFireKey : false,
    foundIceKey : false,
    foundThunderKey : false,
    foundLightKey : false,
    
    
    defeatedWyvernFire : true,//false,
    defeatedWyvernIce : false,
    defeatedWyvernThunder : false,
    defeatedWyvernLight : false,
    
    hasDarkKey : false,
    
    data_locationsDiscovered : 0,
    data_locationsNeeded : 25
});
