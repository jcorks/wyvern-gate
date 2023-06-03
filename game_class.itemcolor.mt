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
    statics : {
        database : empty
    },
    define:::(this) {
        Database.setup(
            item: this,
            attributes : {
                name : String,
                equipMod : StatSet.type, // percentages
            }
        );
    }
);


ItemColor.database = Database.new(
    items : [
        ItemColor.new(
            data : {
                name : 'Red',
                equipMod : StatSet.new(
                    DEF: 1,
                    ATK: 1,
                    SPD: 1
                ),
            }
        ),

        ItemColor.new(
            data : {
                name : 'Blue',
                equipMod : StatSet.new(
                    SPD: 1,
                    DEX: 1,
                    INT: 1
                ),
            }
        ),

        ItemColor.new(
            data : {
                name : 'Green',
                equipMod : StatSet.new(
                    SPD: 1,
                    DEX: 1,
                    ATK: 1
                ),
            }
        ),

        ItemColor.new(
            data : {
                name : 'Yellow',
                equipMod : StatSet.new(
                    DEX: 2,
                    ATK: 1
                ),
            }
        ),

        ItemColor.new(
            data : {
                name : 'Orange',
                equipMod : StatSet.new(
                    DEX: 1,
                    ATK: 2
                ),
            }
        ),

        ItemColor.new(
            data : {
                name : 'Grey',
                equipMod : StatSet.new(
                    SPD: 2,
                    DEX: 1
                ),
            }
        ),

        ItemColor.new(
            data : {
                name : 'Black',
                equipMod : StatSet.new(
                    ATK: 3
                ),
            }
        ),

        ItemColor.new(
            data : {
                name : 'Silver',
                equipMod : StatSet.new(
                    ATK: 1,
                    DEF: 2
                ),
            }
        ),
        
        ItemColor.new(
            data : {
                name : 'Aquamarine',
                equipMod : StatSet.new(
                    INT: 2,
                    DEF: 1
                ),
            }
        ),        


        ItemColor.new(
            data : {
                name : 'Teal',
                equipMod : StatSet.new(
                    SPD: 2,
                    INT: 1
                ),
            }
        ),        


        ItemColor.new(
            data : {
                name : 'Gold',
                equipMod : StatSet.new(
                    ATK: 2,
                    DEF: 2,
                    SPD: 2
                ),
            }
        ),


    ]
);

return ItemColor;
