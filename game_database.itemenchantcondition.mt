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







@:reset :: {
@:StateFlags = import(module:'game_class.stateflags.mt');

ItemEnchantCondition.newEntry(
    data : {
        name : 'On Defend',
        id : 'base:on-defend',
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
        id : 'base:on-attack',
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
        id : 'base:on-ability',
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
        id : 'base:on-heal',
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
        id : 'base:on-hurt',
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
        id : 'base:on-defeat-enemy',
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
        id : 'base:on-dodge-attack',
        description : 'After the wielder dodges an attack',                
        isState : false,
        onTurnCheck ::(wielder, item, battle) {
            return wielder.flags.has(flag:StateFlags.DODGED_ATTACK);
        }                                
    }
)   

ItemEnchantCondition.newEntry(
    data : {
        name : 'On Block Attack',
        id : 'base:on-block-attack',
        description : 'After the wielder blocks an attack',                
        isState : false,
        onTurnCheck ::(wielder, item, battle) {
            return wielder.flags.has(flag:StateFlags.BLOCKED_ATTACK);
        }                                
    }
)   


ItemEnchantCondition.newEntry(
    data : {
        name : 'End Of Turn',
        id : 'base:end-of-turn',
        description : 'At the end of the wielder\'s turn',                
        isState : false,
        onTurnCheck ::(wielder, item, battle) {
            return true;
        }                                
    }
)
}

// conditions are checked at the end of turns
@:ItemEnchantCondition = Database.new(
    name : 'Wyvern.ItemEnchantCondition',
    attributes : {
        name : String,
        id : String,
        description : String,
        isState : Boolean,
        onTurnCheck : Function
    },
    reset
);


return ItemEnchantCondition;
