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

@:APPAREL_NAME = 'Wyvern.ApparelMaterial'

@:ApparelMaterial = class(
    name : APPAREL_NAME,
    inherits : [Database.Item],
    new ::(data) {
        @:this = ApparelMaterial.defaultNew();
        this.initialize(data);
        return this;
    },
    statics : {
        database  :::<= {
            @db = Database.new(
                name: APPAREL_NAME,
                attributes : {
                    name : String,
                    rarity : Number,
                    tier : Number,
                    description : String,
                    statMod : StatSet.type, // percentages
                    pricePercentMod : Number
                }            
            );
            return {
                get ::<- db
            }
        }
    },
    define:::(this) {
        ApparelMaterial.database.add(item:this);
    }
);


ApparelMaterial.new(
    data : {
        name : 'Cloth',
        description : 'The cloth used is generic and nondescript, but comfortable.',
        rarity : 3,
        tier : 0,
        statMod : StatSet.new(
            DEF: 3,
            SPD: 5
        ),
        pricePercentMod: 20
    }
)


ApparelMaterial.new(
    data : {
        name : 'Leather',
        description : 'The rough leather of the item makes it quite sturdy.',
        rarity : 3,
        tier : 0,
        statMod : StatSet.new(
            DEF: 15,
            ATK: 5,
            DEX: 5,
            SPD: -2
        ),
        pricePercentMod: 20
    }
)

ApparelMaterial.new(
    data : {
        name : 'Linen',
        description : 'The linen used offers durability mixed with comfort.',
        rarity : 3,
        tier : 0,
        statMod : StatSet.new(
            DEF: 10,
            ATK: 5,
            DEX: 5,
            SPD: 5
        ),
        pricePercentMod: 20
    }
)

ApparelMaterial.new(
    data : {
        name : 'Silk',
        description : 'The silk material feels lavishly soft.',
        rarity : 3,
        tier : 1,
        statMod : StatSet.new(
            INT: 10,
            SPD: 20,
            DEX: 15
        ),
        pricePercentMod: 200
    }
)

ApparelMaterial.new(
    data : {
        name : 'Wool',
        description : 'The wool material feels warm and soft.',
        rarity : 3,
        tier : 1,
        statMod : StatSet.new(
            INT: 10,
            DEF: 20,
            DEX: 5,
            DEF: 5
        ),
        pricePercentMod: 100
    }
)



ApparelMaterial.new(
    data : {
        name : 'Wool+',
        description : 'The wool used is different somehow.',
        rarity : 3,
        tier : 100,
        statMod : StatSet.new(
            INT: 25,
            DEF: 25,
            DEX: 25,
            DEF: 25,
            ATK: 25
        ),
        pricePercentMod: 30
    }
)

ApparelMaterial.new(
    data : {
        name : 'Mythril',
        description : 'The mythril used makes it radiantly green',
        rarity : 30,
        tier : 2,
        statMod : StatSet.new(
            DEF: 70,
            ATK: 70,
            SPD: 30
        ),
        pricePercentMod: 1200
    }
)


ApparelMaterial.new(
    data : {
        name : 'Eversilk',
        description : 'The wool used is different somehow.',
        rarity : 20,
        tier : 2,
        statMod : StatSet.new(
            INT: 35,
            DEF: 35,
            DEX: 35,
            DEF: 35,
            ATK: 35,
            SPD: 35
        ),
        pricePercentMod: 3000
    }
)


ApparelMaterial.new(
    data : {
        name : 'Soulstrand',
        description : 'The soulstrand material softly glows.',
        rarity : 30,
        tier : 3,
        statMod : StatSet.new(
            INT: 105,
            DEF: 105,
            DEX: 105,
            DEF: 105,
            SPD: 105,
            ATK: 105
        ),
        pricePercentMod: 10000
    }
)


return ApparelMaterial;
