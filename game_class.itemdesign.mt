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


@:ItemDesign = Database.create(
    name : 'Wyvern.ItemDesign',
    attributes : {
        name : String,
        equipMod : StatSet.type, // percentages
    }            
);


ItemDesign.newEntry(
    data : {
        name : 'complicated',
        equipMod : StatSet.new(
            INT: 4,
            SPD: 4
        ),
    }
)

ItemDesign.newEntry(
    data : {
        name : 'humble',
        equipMod : StatSet.new(
            DEF: 4,
            INT: 4
        ),
    }
)

ItemDesign.newEntry(
    data : {
        name : 'practical',
        equipMod : StatSet.new(
            DEF: 4,
            ATK: 4
        ),
    }
)

ItemDesign.newEntry(
    data : {
        name : 'sharp',
        equipMod : StatSet.new(
            SPD: 4,
            ATK: 4
        ),
    }
)

ItemDesign.newEntry(
    data : {
        name : 'striking',
        equipMod : StatSet.new(
            DEX: 4,
            ATK: 4
        ),
    }
)

ItemDesign.newEntry(
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

ItemDesign.newEntry(
    data : {
        name : 'ornate',
        equipMod : StatSet.new(
            ATK: 4,
            INT: 4
        ),
    }
)


ItemDesign.newEntry(
    data : {
        name : 'weighty',
        equipMod : StatSet.new(
            DEF: 8,
            SPD: -2
        ),
    }
)

ItemDesign.newEntry(
    data : {
        name : 'minimalist',
        equipMod : StatSet.new(
            SPD: 4,
            DEX: 4
        ),
    }
)







return ItemDesign;
