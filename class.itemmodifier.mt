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


@:ItemMod = class(
    name : 'Wyvern.ItemModifier',
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
                pricePercentMod : Number
            }
        );
    }
);


ItemMod.database = Database.new(
    items : [
        ItemMod.new(
            data : {
                name : 'Rusty',
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
                
                useEffects : []
            }
        ),






        ItemMod.new(
            data : {
                name : 'Cheap',
                description : 'It was made with poor quality.',
                equipMod : StatSet.new(
                    DEF: -60,
                    ATK: -60
                ),
                levelMinimum : 1,
                pricePercentMod: -50,
                
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),
        


        ItemMod.new(
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
                pricePercentMod: 300,
                
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),
                
        
        
        ItemMod.new(
            data : {
                name : 'Polished',
                description : 'The surface has a shine as if it has been well-kept.',
                equipMod : StatSet.new(
                    DEF: 10,
                    ATK: 10,
                    SPD: 20,
                    DEX: 10
                ),
                pricePercentMod: 10,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        ItemMod.new(
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
                
                useEffects : []
            }
        ),

        ItemMod.new(
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
                
                useEffects : []
            }
        ),

        ItemMod.new(
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
                
                useEffects : []
            }
        ),

        ItemMod.new(
            data : {
                name : 'Standard',
                description : 'The quality of this seems to meet some sort of standard stock, perhaps of a military or castle-bourne grade.',
                equipMod : StatSet.new(
                    SPD: 15,
                    DEX: 15,
                    ATK: 15,
                    DEF: 15
                ),
                pricePercentMod: 120,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        ItemMod.new(
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
                pricePercentMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),
        
        ItemMod.new(
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
                pricePercentMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        ItemMod.new(
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
                pricePercentMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        ItemMod.new(
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
                pricePercentMod: 1200,
                levelMinimum : 1,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ),

        

        ItemMod.new(
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
                pricePercentMod: 3600,
                equipEffects : [
                ],
                
                useEffects : []
            }
        ), 

        ItemMod.new(
            data : {
                name : 'Burning',
                description : 'The material its made of is warm to the touch. Gives it a fire aspect when used as a weapon, and gives ice resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                pricePercentMod: 20,
                
                equipEffects : [
                    "Burning"
                ],
                
                useEffects : []
            }
        ),

        ItemMod.new(
            data : {
                name : 'Icy',
                description : 'The material its made of is cold to the touch. Gives it an ice aspect when used as a weapon, and gives fire resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                pricePercentMod: 20,
                
                equipEffects : [
                    "Icy"
                ],
                
                useEffects : []
            }
        ),

        ItemMod.new(
            data : {
                name : 'Shock',
                description : 'The material its made of gently hums. Gives it an thunder aspect when used as a weapon, and gives thunder resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                pricePercentMod: 20,
                
                equipEffects : [
                    "Shock"
                ],
                
                useEffects : []
            }
        ),

        ItemMod.new(
            data : {
                name : 'Toxic',
                description : 'The material its made of is poisonous. Gives it a poison aspect when used as a weapon, and gives poison resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                pricePercentMod: 20,
                
                equipEffects : [
                    "Toxic"
                ],
                
                useEffects : []
            }
        ),

        ItemMod.new(
            data : {
                name : 'Shimmering',
                description : 'The material its made of glows softly. Gives it a light aspect when used as a weapon, and gives dark resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                pricePercentMod: 20,
                
                equipEffects : [
                    "Shimmering"
                ],
                
                useEffects : []
            }
        ),

        ItemMod.new(
            data : {
                name : 'Dark',
                description : 'The material its made of is very dark. Gives it a dark aspect when used as a weapon, and gives light resistance when used as armor.',
                equipMod : StatSet.new(
                ),
                levelMinimum : 1,
                pricePercentMod: 20,
                
                equipEffects : [
                    "Dark"
                ],
                
                useEffects : []
            }
        ),

    
    ]
);

return ItemMod;
