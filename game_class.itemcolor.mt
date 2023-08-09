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


@:ItemColor = class(
    name : 'Wyvern.ItemColor',
    inherits : [Database.Item],
    statics : {
        database  :::<= {
            @db = Database.new().initialize(
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
        this.constructor = ::{
            ItemColor.database.bind(item:this);
        }
    }
);


ItemColor.new().initialize(
    data : {
        name : 'Red',
        equipMod : StatSet.new().initialize(
            DEF: 3,
            ATK: 3,
            SPD: 3
        ),
    }
)

ItemColor.new().initialize(
    data : {
        name : 'Blue',
        equipMod : StatSet.new().initialize(
            SPD: 3,
            DEX: 3,
            INT: 3
        ),
    }
)

ItemColor.new().initialize(
    data : {
        name : 'Green',
        equipMod : StatSet.new().initialize(
            SPD: 3,
            DEX: 3,
            ATK: 3
        ),
    }
)

ItemColor.new().initialize(
    data : {
        name : 'Yellow',
        equipMod : StatSet.new().initialize(
            DEX: 5,
            ATK: 3
        ),
    }
)

ItemColor.new().initialize(
    data : {
        name : 'Orange',
        equipMod : StatSet.new().initialize(
            DEX: 3,
            ATK: 5
        ),
    }
)

ItemColor.new().initialize(
    data : {
        name : 'Grey',
        equipMod : StatSet.new().initialize(
            SPD: 5,
            DEX: 3
        ),
    }
)

ItemColor.new().initialize(
    data : {
        name : 'Black',
        equipMod : StatSet.new().initialize(
            ATK: 7
        ),
    }
)

ItemColor.new().initialize(
    data : {
        name : 'Silver',
        equipMod : StatSet.new().initialize(
            ATK: 5,
            DEF: 5
        ),
    }
)

ItemColor.new().initialize(
    data : {
        name : 'Aquamarine',
        equipMod : StatSet.new().initialize(
            INT: 5,
            DEF: 3
        ),
    }
)        


ItemColor.new().initialize(
    data : {
        name : 'Teal',
        equipMod : StatSet.new().initialize(
            SPD: 5,
            INT: 3
        ),
    }
)        


ItemColor.new().initialize(
    data : {
        name : 'Gold',
        equipMod : StatSet.new().initialize(
            ATK: 5,
            DEF: 5,
            SPD: 5,
            INT: 5
        ),
    }
)


return ItemColor;
