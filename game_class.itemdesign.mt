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


@:ITEM_DESIGN_NAME = 'Wyvern.ItemDesign';
@:ItemDesign = class(
    name : ITEM_DESIGN_NAME,
    inherits : [Database.Item],
    new ::(data) {
        @:this = ItemDesign.defaultNew();
        this.initialize(data);
        return this;
    },
    statics : {
        database  :::<= {
            @db = Database.new(
                name : ITEM_DESIGN_NAME,
                attributes : {
                    name : String,
                    equipMod : StatSet.type, // percentages
                }            
            )
            return {
                get ::<- db,
            }
        }

    },
    define:::(this) {
        ItemDesign.database.add(item:this);
    }
);


ItemDesign.new(
    data : {
        name : 'complicated',
        equipMod : StatSet.new(
            INT: 4,
            SPD: 4
        ),
    }
)

ItemDesign.new(
    data : {
        name : 'humble',
        equipMod : StatSet.new(
            DEF: 4,
            INT: 4
        ),
    }
)

ItemDesign.new(
    data : {
        name : 'practical',
        equipMod : StatSet.new(
            DEF: 4,
            ATK: 4
        ),
    }
)

ItemDesign.new(
    data : {
        name : 'sharp',
        equipMod : StatSet.new(
            SPD: 4,
            ATK: 4
        ),
    }
)

ItemDesign.new(
    data : {
        name : 'striking',
        equipMod : StatSet.new(
            DEX: 4,
            ATK: 4
        ),
    }
)

ItemDesign.new(
    data : {
        name : 'simple',
        equipMod : StatSet.new(
            DEX: 1,
            ATK: 1,
            SPD: 1,
            DEF: 1,
            INT: 1
        ),
    }
)

ItemDesign.new(
    data : {
        name : 'ornate',
        equipMod : StatSet.new(
            ATK: 4,
            INT: 4
        ),
    }
)


ItemDesign.new(
    data : {
        name : 'weighty',
        equipMod : StatSet.new(
            DEF: 8,
            SPD: -2
        ),
    }
)

ItemDesign.new(
    data : {
        name : 'minimalist',
        equipMod : StatSet.new(
            SPD: 4,
            DEX: 4
        ),
    }
)







return ItemDesign;
