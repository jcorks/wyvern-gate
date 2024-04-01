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
@:lclass = import(module:'game_function.lclass.mt');

@:TYPE = {
    NEUTRAL    : 0,
     FIRE       : 1,
     THUNDER    : 2,
     ICE        : 3,
    LIGHT      : 4,
    DARK       : 5,
    PHYS       : 6,
    POISON     : 7

}

@:CLASS = {
    HP : 0,
    AP : 1
}

@:Damage = lclass(
    name: 'Wyvern.Damage',
    statics : {
        TYPE : TYPE,
        CLASS : CLASS
    },
    
    constructor = ::(amount => Number, damageType => Number, damageClass => Number) {
        amount = (amount)->ceil;
        if (amount <= 0) amount = 1;// minimum of 1 damage
        _.amount = amount;
        _.type = damageType;
        _.dclass = damageClass;
    };    
    
    
    interface : {
    
        reduce ::(byRatio) {
            _.amount *= byRatio;
        },
        
        amount : {
            get :: {
                return _.amount;
            },
            
            set ::(value => Number) {
                _.amount_= value->ceil;
                if (_.amount <= 0) _.amount = 0;
            }
        },
        
        damageType : {
            get :: {
                return _.type;
            },
            
            set ::(value => Number) {
                _.type = value;
            }
        },
        
        damageClass : {
            get :: {
                return _.dclass;
            },
            
            set ::(value => Number) {
                _.dclass = value;
            }
        }
    
    }    
);
return Damage;
