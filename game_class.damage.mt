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

return class(
    name: 'Wyvern.Damage',
    statics : {
        TYPE : {get::<-TYPE},
        CLASS : {get::<-CLASS}
    },
    define:::(this) {
        @type_;
        @amount_;
        @dclass;
        this.constructor = ::(amount => Number, damageType => Number, damageClass => Number) {
            amount_ = (amount)->ceil;
            if (amount_ <= 0) amount_ = 1;// minimum of 1 damage
            type_ = damageType;
            dclass = damageClass;
            return this.instance;
        }
        this.interface = {
            reduce ::(byRatio) {
                amount_ *= byRatio;
            },
            
            amount : {
                get :: {
                    return amount_;
                },
                
                set ::(value => Number) {
                    amount_ = value->ceil;
                    if (amount_ <= 0) amount_ = 0;
                }
            },
            
            damageType : {
                get :: {
                    return type_;
                },
                
                set ::(value => Number) {
                    type_ = value;
                }
            },
            
            damageClass : {
                get :: {
                    return dclass;
                },
                
                set ::(value => Number) {
                    dclass = value;
                }
            
            }
        
        }    
    }
);
