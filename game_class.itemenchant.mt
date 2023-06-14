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


@:ItemEnchant = class(
    name : 'Wyvern.ItemEnchant',
    statics : {
        database : empty
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
                priceMod : Number
            }
        );
    }
);


ItemEnchant.database = Database.new(
    items : [



        ItemEnchant.new(
            data : {
                name : 'Cursed',
                description : 'Somehow, cursed magicks have seeped into this.',
                equipMod : StatSet.new(
                    DEF: -70,
                    ATK: -70,
                    INT: 100,
                    SPD: 20
                ),
                levelMinimum : 5,
                priceMod: 300,
                
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),




        ItemEnchant.new(
            data : {
                name : 'Inlet: Morion',
                description : 'Set with an enchanted morion stone.',
                equipMod : StatSet.new(
                    SPD: 100,
                    DEX: 100,
                    ATK: -50,
                    DEF: -50,
                    INT: -50
                ),
                priceMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),
        
        ItemEnchant.new(
            data : {
                name : 'Inlet: Amethyst',
                description : 'Set with an enchanted amethyst.',
                equipMod : StatSet.new(
                    SPD: -50,
                    DEX: 100,
                    ATK: 100,
                    DEF: -50,
                    INT: -50
                ),
                priceMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Inlet: Citrine',
                description : 'Set with an enchanted citrine stone.',
                equipMod : StatSet.new(
                    SPD: -50,
                    DEX: -50,
                    ATK: 100,
                    DEF: 100,
                    INT: -50
                ),
                priceMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Inlet: Garnet',
                description : 'Set with an enchanted garnet stone.',
                equipMod : StatSet.new(
                    SPD: -50,
                    DEX: -50,
                    ATK: -50,
                    DEF: 100,
                    INT: 100
                ),
                priceMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),


        ItemEnchant.new(
            data : {
                name : 'Inlet: Praesolite',
                description : 'Set with an enchanted praesolite stone.',
                equipMod : StatSet.new(
                    SPD: 100,
                    DEX: -50,
                    ATK: -50,
                    DEF: -50,
                    INT: 100
                ),
                priceMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Inlet: Aquamarine',
                description : 'Set with an enchanted aquamarine stone.',
                equipMod : StatSet.new(
                    SPD: 100,
                    DEX: -50,
                    ATK: 100,
                    DEF: -50,
                    INT: -50
                ),
                priceMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Inlet: Diamond',
                description : 'Set with an enchanted diamond stone.',
                equipMod : StatSet.new(
                    SPD: 100,
                    DEX: -50,
                    ATK: -50,
                    DEF: 100,
                    INT: -50
                ),
                priceMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),
        
        ItemEnchant.new(
            data : {
                name : 'Inlet: Pearl',
                description : 'Set with an enchanted pearl.',
                equipMod : StatSet.new(
                    SPD: -50,
                    DEX: 100,
                    ATK: -50,
                    DEF: 100,
                    INT: -50
                ),
                priceMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Inlet: Ruby',
                description : 'Set with an enchanted ruby.',
                equipMod : StatSet.new(
                    SPD: -50,
                    DEX: 100,
                    ATK: -50,
                    DEF: -50,
                    INT: 100
                ),
                priceMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Inlet: Sapphire',
                description : 'Set with an enchanted sapphire.',
                equipMod : StatSet.new(
                    SPD: 100,
                    DEX: -50,
                    ATK: 100,
                    DEF: -50,
                    INT: -50
                ),
                priceMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Inlet: Opal',
                description : 'Set with an enchanted opal stone.',
                equipMod : StatSet.new(
                    SPD: -50,
                    DEX: -50,
                    ATK: 100,
                    DEF: -50,
                    INT: 100
                ),
                priceMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),


        ItemEnchant.new(
            data : {
                name : 'Burning',
                description : 'The material its made of is warm to the touch. Gives it a fire aspect when used as a weapon, and gives ice resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                priceMod: 200,
                
                equipEffects : [
                    "Burning"
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Icy',
                description : 'The material its made of is cold to the touch. Gives it an ice aspect when used as a weapon, and gives fire resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                priceMod: 200,
                
                equipEffects : [
                    "Icy"
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Shock',
                description : 'The material its made of gently hums. Gives it an thunder aspect when used as a weapon, and gives thunder resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                priceMod: 200,
                
                equipEffects : [
                    "Shock"
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Toxic',
                description : 'The material its made has been made poisonous. Gives it a poison aspect when used as a weapon, and gives poison resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                priceMod: 200,
                
                equipEffects : [
                    "Toxic"
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Shimmering',
                description : 'The material its made of glows softly. Gives it a light aspect when used as a weapon, and gives dark resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                priceMod: 200,
                
                equipEffects : [
                    "Shimmering"
                ],
                
                useEffects : []
            }
        ),

        ItemEnchant.new(
            data : {
                name : 'Dark',
                description : 'The material its made of is very dark. Gives it a dark aspect when used as a weapon, and gives light resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                priceMod: 200,
                
                equipEffects : [
                    "Dark"
                ],
                
                useEffects : []
            }
        ),

    
    ]
);

return ItemEnchant;
