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
@:StateFlags = import(module:'game_class.stateflags.mt');




// conditions are checked at the end of turns
@:ItemEnchantCondition = Database.new(
    name : 'Wyvern.ItemEnchantCondition',
    attributes : {
        name : String,
        description : String,
        isState : Boolean,
        onTurnCheck : Function
    }
);




ItemEnchantCondition.newEntry(
    data : {
        name : 'On Defend',
        description : 'After the wielder defends',
        isState : false,
        onTurnCheck ::(wielder, item, battle) {
            return wielder.flags.has(flag:StateFlags.DEFENDED);
        }                
    }
)

ItemEnchantCondition.newEntry(
    data : {
        name : 'On Attack',
        description : 'After the wielder attacks',
        isState : false,
        onTurnCheck ::(wielder, item, battle) {
            return wielder.flags.has(flag:StateFlags.ATTACKED);
        }
    }
)

ItemEnchantCondition.newEntry(
    data : {
        name : 'On Ability',
        description : 'After the wielder uses an ability',
        isState : false,
        onTurnCheck ::(wielder, item, battle) {
            return wielder.flags.has(flag:StateFlags.ABILITY);
        }                                
    }
)

ItemEnchantCondition.newEntry(
    data : {
        name : 'On Heal',
        description : 'After the wielder heals',                
        isState : false,
        onTurnCheck ::(wielder, item, battle) {
            return wielder.flags.has(flag:StateFlags.HEALED);
        }                                
    }
)

ItemEnchantCondition.newEntry(
    data : {
        name : 'On Hurt',
        description : 'After the wielder is hurt',                
        isState : false,
        onTurnCheck ::(wielder, item, battle) {
            return wielder.flags.has(flag:StateFlags.HURT);
        }                                
    }
)

ItemEnchantCondition.newEntry(
    data : {
        name : 'On Defeat Enemy',
        description : 'After the wielder defeats an enemy',                
        isState : false,
        onTurnCheck ::(wielder, item, battle) {
            return wielder.flags.has(flag:StateFlags.DEFEATED_ENEMY);
        }                                
    }
)        

ItemEnchantCondition.newEntry(
    data : {
        name : 'On Dodge Attack', // Dex build!
        description : 'After the wielder dodges an attack',                
        isState : false,
        onTurnCheck ::(wielder, item, battle) {
            return wielder.flags.has(flag:StateFlags.DODGED_ATTACK);
        }                                
    }
)   

ItemEnchantCondition.newEntry(
    data : {
        name : 'End Of Turn',
        description : 'At the end of the wielder\'s turn',                
        isState : false,
        onTurnCheck ::(wielder, item, battle) {
            return true;
        }                                
    }
)

return ItemEnchantCondition;
