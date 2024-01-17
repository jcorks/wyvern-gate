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


@:ItemColor = Database.new(
    name : 'Wyvern.ItemColor',
    attributes : {
        name : String,
        equipMod : StatSet.type, // percentages
    }            
);


ItemColor.newEntry(
    data : {
        name : 'red',
        equipMod : StatSet.new(
            DEF: 3,
            ATK: 3,
            SPD: 3
        ),
    }
)

ItemColor.newEntry(
    data : {
        name : 'blue',
        equipMod : StatSet.new(
            SPD: 3,
            DEX: 3,
            INT: 3
        ),
    }
)


ItemColor.newEntry(
    data : {
        name : 'purple',
        equipMod : StatSet.new(
            SPD: 2,
            DEX: 2,
            INT: 2,
            ATK: 2
        ),
    }
)


ItemColor.newEntry(
    data : {
        name : 'pink',
        equipMod : StatSet.new(
            DEX: 3,
            INT: 5
        ),
    }
)

ItemColor.newEntry(
    data : {
        name : 'white',
        equipMod : StatSet.new(
            DEF: 7
        ),
    }
)



ItemColor.newEntry(
    data : {
        name : 'green',
        equipMod : StatSet.new(
            SPD: 3,
            DEX: 3,
            ATK: 3
        ),
    }
)

ItemColor.newEntry(
    data : {
        name : 'olive-green',
        equipMod : StatSet.new(
            SPD: 3,
            DEX: 4,
            ATK: 3
        ),
    }
)

ItemColor.newEntry(
    data : {
        name : 'yellow',
        equipMod : StatSet.new(
            DEX: 5,
            ATK: 3
        ),
    }
)

ItemColor.newEntry(
    data : {
        name : 'orange',
        equipMod : StatSet.new(
            DEX: 3,
            ATK: 5
        ),
    }
)

ItemColor.newEntry(
    data : {
        name : 'grey',
        equipMod : StatSet.new(
            SPD: 5,
            DEX: 3
        ),
    }
)

ItemColor.newEntry(
    data : {
        name : 'brown',
        equipMod : StatSet.new(
            DEF: 5,
            DEX: 3
        ),
    }
)

ItemColor.newEntry(
    data : {
        name : 'black',
        equipMod : StatSet.new(
            ATK: 7
        ),
    }
)

ItemColor.newEntry(
    data : {
        name : 'silver',
        equipMod : StatSet.new(
            ATK: 5,
            DEF: 5
        ),
    }
)

ItemColor.newEntry(
    data : {
        name : 'aquamarine',
        equipMod : StatSet.new(
            INT: 5,
            DEF: 3
        ),
    }
)        


ItemColor.newEntry(
    data : {
        name : 'teal',
        equipMod : StatSet.new(
            SPD: 5,
            INT: 3
        ),
    }
)        


ItemColor.newEntry(
    data : {
        name : 'gold',
        equipMod : StatSet.new(
            ATK: 5,
            DEF: 5,
            SPD: 5,
            INT: 5
        ),
    }
)


return ItemColor;
