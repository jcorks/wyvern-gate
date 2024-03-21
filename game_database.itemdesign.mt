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




@:reset :: {
ItemDesign.newEntry(
    data : {
        name : 'complicated',
        id : 'base:complicated',
        equipMod : StatSet.new(
            INT: 4,
            SPD: 4
        ),
    }
)

ItemDesign.newEntry(
    data : {
        name : 'humble',
        id : 'base:humble',
        equipMod : StatSet.new(
            DEF: 4,
            INT: 4
        ),
    }
)

ItemDesign.newEntry(
    data : {
        name : 'practical',
        id : 'base:practical',
        equipMod : StatSet.new(
            DEF: 4,
            ATK: 4
        ),
    }
)

ItemDesign.newEntry(
    data : {
        name : 'sharp',
        id : 'base:sharp',
        equipMod : StatSet.new(
            SPD: 4,
            ATK: 4
        ),
    }
)

ItemDesign.newEntry(
    data : {
        name : 'striking',
        id : 'base:striking',
        equipMod : StatSet.new(
            DEX: 4,
            ATK: 4
        ),
    }
)

ItemDesign.newEntry(
    data : {
        name : 'simple',
        id : 'base:simple',
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
        id : 'base:ornate',
        equipMod : StatSet.new(
            ATK: 4,
            INT: 4
        ),
    }
)


ItemDesign.newEntry(
    data : {
        name : 'weighty',
        id : 'base:weighty',
        equipMod : StatSet.new(
            DEF: 8,
            SPD: -2
        ),
    }
)

ItemDesign.newEntry(
    data : {
        name : 'minimalist',
        id : 'base:minimalist',
        equipMod : StatSet.new(
            SPD: 4,
            DEX: 4
        ),
    }
)
}

@:ItemDesign = Database.new(
    name : 'Wyvern.ItemDesign',
    attributes : {
        name : String,
        id : String,
        equipMod : StatSet.type, // percentages
    },
    reset
);






return ItemDesign;
