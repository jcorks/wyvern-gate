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


@:ItemQuality = class(
    name : 'Wyvern.ItemQuality',
    statics : {
        database  :::<= {
            @db;
            return {
                get ::<- db,
                set ::(value) <- db = value
            }
        }
    },
    define:::(this) {
        Database.setup(
            item: this,
            attributes : {
                name : String,
                description : String,
                levelMinimum : Number,
                equipMod : StatSet.type, // percentages
                useEffects : Object,
                equipEffects : Object,
                pricePercentMod : Number,
                rarity: Number
            }
        );
    }
);


ItemQuality.database = Database.new(
    items : [
        ItemQuality.new(
            data : {
                name : 'Worn',
                description : 'The surface appears worn out; it might not be able to last much longer.',
                equipMod : StatSet.new(
                    DEF: -30,
                    ATK: -50,
                    SPD: -40
                ),
                pricePercentMod: -60,
                levelMinimum : 1,
                equipEffects : [
                ],
                rarity: 2,
                
                useEffects : []
            }
        ),






        ItemQuality.new(
            data : {
                name : 'Cheap',
                description : 'It is of poor quality.',
                equipMod : StatSet.new(
                    DEF: -30,
                    ATK: -30,
                    DEX: -20
                ),
                levelMinimum : 1,
                pricePercentMod: -50,
                
                equipEffects : [
                ],
                
                rarity: 3,
                
                useEffects : []
            }
        ),
        

        ItemQuality.new(
            data : {
                name : 'Sturdy',
                description : 'It is unusually sturdy.',
                equipMod : StatSet.new(
                    DEF: 20,
                    ATK: 10,
                    SPD: 10,
                    DEX: 10
                ),
                pricePercentMod: 15,
                levelMinimum : 1,
                equipEffects : [
                ],
                rarity: 2,
                
                
                useEffects : []
            }
        ),                
        
        
        ItemQuality.new(
            data : {
                name : 'Polished',
                description : 'The surface has a shine as if it has been well-kept.',
                equipMod : StatSet.new(
                    DEF: 10,
                    ATK: 10,
                    SPD: 20,
                    DEX: 10
                ),
                pricePercentMod: 15,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                rarity: 5,
                
                useEffects : []
            }
        ),

        ItemQuality.new(
            data : {
                name : 'Quality',
                description : 'The quality of this is remarkable.',
                equipMod : StatSet.new(
                    DEF: 5,
                    ATK: 5,
                    SPD: 10,
                    DEX: 5
                ),
                pricePercentMod: 10,
                levelMinimum : 1,
                equipEffects : [
                ],
                rarity: 10,
                
                useEffects : []
            }
        ),

        ItemQuality.new(
            data : {
                name : 'Light',
                description : 'It appears to be lighter than expected.',
                equipMod : StatSet.new(
                    SPD: 30,
                    DEX: 20,
                    ATK: -5,
                    DEF: -10
                ),
                pricePercentMod: 30,
                levelMinimum : 1,
                equipEffects : [
                ],
                rarity: 6,
                
                useEffects : []
            }
        ),

        ItemQuality.new(
            data : {
                name : 'Decorative',
                description : 'It appears a bit more ornate than the usual.',
                equipMod : StatSet.new(
                    SPD: -5,
                    DEX: -5,
                    ATK: -5,
                    DEF: -5
                ),
                pricePercentMod: 40,
                levelMinimum : 1,
                equipEffects : [
                ],
                rarity: 20,
                
                useEffects : []
            }
        ),

        ItemQuality.new(
            data : {
                name : 'Apprentice\'s',
                description : "This seems to be the work of a master's apprentice.",
                levelMinimum: 1,
                equipMod : StatSet.new(
                    DEF: 10,
                    ATK: 10,
                    SPD: 10,
                    DEX: 10,
                    INT: 10
                ),
                pricePercentMod: 110,
                equipEffects : [
                ],
                rarity: 25,
                
                useEffects : []
            }
        ),


        ItemQuality.new(
            data : {
                name : 'Standard',
                description : 'The quality of this seems to meet some sort of standard stock, perhaps of military grade.',
                equipMod : StatSet.new(
                    SPD: 25,
                    DEX: 25,
                    ATK: 25,
                    DEF: 25
                ),
                pricePercentMod: 120,
                levelMinimum : 1,
                equipEffects : [
                ],
                rarity: 4,
                
                useEffects : []
            }
        ),

        ItemQuality.new(
            data : {
                name : 'King\'s',
                description : "The quality of this is as if it were meant for a king.",
                levelMinimum: 1,
                equipMod : StatSet.new(
                    DEF: 50,
                    ATK: 50,
                    SPD: 50,
                    DEX: 50,
                    INT: 50
                ),
                pricePercentMod: 1200,
                equipEffects : [
                ],
                rarity: 25,
                
                useEffects : []
            }
        ),

        ItemQuality.new(
            data : {
                name : 'Queen\'s',
                description : "The quality of this is as if it were meant for a queen.",
                levelMinimum: 1,
                equipMod : StatSet.new(
                    DEF: 75,
                    ATK: 75,
                    SPD: 75,
                    DEX: 75,
                    INT: 75
                ),
                pricePercentMod: 2500,
                equipEffects : [
                ],
                rarity: 50,
                
                useEffects : []
            }
        ),

        ItemQuality.new(
            data : {
                name : 'Masterwork',
                description : "A crowning achievement by a craftsperson representing a life's work.",
                levelMinimum: 1,
                equipMod : StatSet.new(
                    DEF: 100,
                    ATK: 100,
                    SPD: 100,
                    DEX: 100,
                    INT: 100
                ),
                rarity: 100,
                pricePercentMod: 3600,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ) 
    ]
);

return ItemQuality;
