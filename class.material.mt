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
@:Database = import(module:'class.database.mt');
@:StatSet = import(module:'class.statset.mt');


@:Material = class(
    name : 'Wyvern.Material',
    statics : {
        database : empty
    },
    define:::(this) {
        Database.setup(
            item: this,
            attributes : {
                name : String,
                rarity : Number,
                levelMinimum : Number,
                description : String,
                statMod : StatSet.type, // percentages
                pricePercentMod : Number
            }
        );
    }
);



Material.database = Database.new(
    items: [
        Material.new(
            data : {
                name : 'Copper',
                description : 'The copper material used gives off a radiant brown color.',
                rarity : 3,
                levelMinimum : 1,
                statMod : StatSet.new(
                    DEF: 5,
                    ATK: 6
                ),
                pricePercentMod: 20
            }
        ),

        Material.new(
            data : {
                name : 'Steel',
                description : '',
                rarity : 5,
                levelMinimum : 1,
                statMod : StatSet.new(
                    DEF: 30,
                    ATK: 30
                ),
                pricePercentMod: 100
            }
        ),

        Material.new(
            data : {
                name : 'Iron',
                description : '',
                rarity : 2,
                levelMinimum : 1,
                statMod : StatSet.new(
                    DEF: 10,
                    ATK: 20,
                    SPD: -5
                ),
                pricePercentMod: 35
            }
        ),




        Material.new(
            data : {
                name : 'Mythril',
                description : '',
                rarity : 300,
                levelMinimum : 30,
                statMod : StatSet.new(
                    DEF: 70,
                    ATK: 70,
                    SPD: 30
                ),
                pricePercentMod: 1200
            }
        ),

        Material.new(
            data : {
                name : 'Adamantine',
                description : '',
                rarity : 500,
                levelMinimum : 45,
                statMod : StatSet.new(
                    DEF: 100,
                    ATK: 100
                ),
                pricePercentMod: 1600
            }
        ),    
        
        Material.new(
            data : {
                name : 'Quicksilver',
                description : '',
                rarity : 500,
                levelMinimum : 35,
                statMod : StatSet.new(
                    DEF: 50,
                    ATK: 50,
                    SPD: 60
                ),
                pricePercentMod: 1100
            }
        ),    

        Material.new(
            data : {
                name : 'Dragonglass',
                description : '',
                rarity : 500,
                levelMinimum : 55,
                statMod : StatSet.new(
                    DEF: -20,
                    ATK: 150,
                    SPD: 10
                ),
                pricePercentMod: 1800
            }
        ),    

        Material.new(
            data : {
                name : 'Composite',
                rarity : 20,
                description : '',
                levelMinimum : 20,
                statMod : StatSet.new(
                    DEF: 45,
                    ATK: 45,
                    SPD: 20
                ),
                pricePercentMod: 210
            }
        ),    


        Material.new(
            data : {
                name : 'Sunstone',
                rarity : 300,
                description : '',
                levelMinimum : 15,
                statMod : StatSet.new(
                    DEF: 35,
                    INT: 15,
                    ATK: 35
                ),
                pricePercentMod: 150
            }
        ),   

        Material.new(
            data : {
                name : 'Moonstone',
                rarity : 300,
                description : '',
                levelMinimum : 15,
                statMod : StatSet.new(
                    DEF: 15,
                    INT: 35,
                    ATK: 35
                ),
                pricePercentMod: 150
            }
        )


    
    ]
);

return Material;

