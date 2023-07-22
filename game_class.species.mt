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
@:Database = import(module:'game_class.database.mt');
@:class = import(module:'Matte.Core.Class');
@:StatSet = import(module:'game_class.statset.mt');
@:Species = class(
    statics : {
        database : empty
    },
    name: 'Wyvern.Species',
    define:::(this) {
        Database.setup(
            item: this,
            attributes : {
                name : String,
                rarity: Number,
                qualities : Object,
                description : String,
                growth : StatSet.type,
                passives : Object,
                special : Boolean
            }
        );
    }
);

Species.database = Database.new(items: [
    Species.new(data:{
        name : 'Wolf',
        rarity : 10,
        description: 'A common canid race.',
        growth : StatSet.new(
            HP : 5,
            AP : 2,
            ATK: 3,
            DEF: 3,
            INT: 2,
            LUK: 1,
            SPD: 2,
            DEX: 3
        ),        
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        special : false,
        passives : [
        ]
    }),

    Species.new(data:{
        name : 'Lynx',
        rarity : 10,
        description: 'A felid race.',
        growth : StatSet.new(
            HP : 2,
            AP : 6,
            ATK: 2,
            DEF: 2,
            INT: 8,
            LUK: 6,
            SPD: 6,
            DEX: 4
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),

    Species.new(data:{
        name : 'Fox',
        rarity : 10,
        description: 'A canid race.',
        growth : StatSet.new(
            HP : 3,
            AP : 6,
            ATK: 4,
            DEF: 1,
            INT: 5,
            LUK: 8,
            SPD: 6,
            DEX: 4
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),
    
    Species.new(data:{
        name : 'Kitsune',
        rarity : 10,
        description: 'A canid race.',
        growth : StatSet.new(
            HP : 2,
            AP : 5,
            ATK: 2,
            DEF: 1,
            INT: 8,
            LUK: 3,
            SPD: 7,
            DEX: 8
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),    

    Species.new(data:{
        name : 'Tiger',
        description: 'A common felid race.',
        rarity : 45,
        growth : StatSet.new(
            HP : 3,
            AP : 2,
            ATK: 6,
            DEF: 2,
            INT: 4,
            LUK: 2,
            SPD: 5,
            DEX: 3
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),
    
    Species.new(data:{
        name : 'Deer',
        description: 'A common ungulate race.',
        rarity : 10,
        growth : StatSet.new(
            HP : 3,
            AP : 4,
            ATK: 3,
            DEF: 4,
            INT: 5,
            LUK: 6,
            SPD: 6,
            DEX: 6
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),
    
    Species.new(data:{
        name : 'Gazelle',
        description: 'A tall ungulate race.',
        rarity : 40,
        growth : StatSet.new(
            HP : 3,
            AP : 6,
            ATK: 3,
            DEF: 3,
            INT: 7,
            LUK: 3,
            SPD: 8,
            DEX: 3
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),    
    
    
    Species.new(data:{
        name : 'Kobold',
        description: 'A common dragon-like race of small stature.',
        rarity : 30,
        growth : StatSet.new(
            HP : 1,
            AP : 10,
            ATK: 2,
            DEF: 2,
            INT: 10,
            LUK: 4,
            SPD: 10,
            DEX: 8
        ),
        qualities : [
            'snout',
            'scales',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),
    
    Species.new(data:{
        name : 'Serval',
        description: 'A felid race of medium stature.',
        rarity : 30,
        growth : StatSet.new(
            HP : 3,
            AP : 2,
            ATK: 4,
            DEF: 2,
            INT: 4,
            LUK: 6,
            SPD: 10,
            DEX: 8
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),


    Species.new(data:{
        name : 'Jackal',
        rarity : 30,
        description: 'A slender canid race.',
        growth : StatSet.new(
            HP : 5,
            AP : 4,
            ATK: 2,
            DEF: 1,
            INT: 3,
            LUK: 6,
            SPD: 4,
            DEX: 5
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),
    
    Species.new(data:{
        name : 'Possum',
        rarity : 40,
        description: 'A marsupial race of medium stature.',
        growth : StatSet.new(
            HP : 7,
            AP : 3,
            ATK: 3,
            DEF: 3,
            INT: 4,
            LUK: 10,
            SPD: 3,
            DEX: 2
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),
    
    Species.new(data:{
        name : 'Bear',
        rarity : 100,
        description: 'A large mammal race.',
        growth : StatSet.new(
            HP : 10,
            AP : 1,
            ATK: 7,
            DEF: 9,
            INT: 1,
            LUK: -3,
            SPD: -3,
            DEX: 1
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),

    Species.new(data:{
        name : 'Kangaroo',
        rarity : 100,
        description: 'A large mammal race.',
        growth : StatSet.new(
            HP : 4,
            AP : 3,
            ATK: 8,
            DEF: 2,
            INT: 4,
            LUK: 0,
            SPD: 5,
            DEX: 0
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),

    Species.new(data:{
        name : 'Raven',
        rarity : 100,
        description: 'A bird race of medium stature',
        growth : StatSet.new(
            HP : 3,
            AP : 8,
            ATK: 3,
            DEF: 2,
            INT: 7,
            LUK: 2,
            SPD: 5,
            DEX: 4
        ),
        qualities : [
            'feathers',
            'eyes',
            'face',
            'body'
        ],        
        special : false,
        passives : [
        ]
    }),


    Species.new(data:{
        name : 'Pigeon',
        rarity : 100,
        description: 'A bird race of medium stature',
        growth : StatSet.new(
            HP : 4,
            AP : 0,
            ATK: 5,
            DEF: 5,
            INT: 0,
            LUK: 10,
            SPD: 10,
            DEX: 0
        ),
        qualities : [
            'feathers',
            'eyes',
            'face',
            'body'
        ],        
        
        special : false,
        passives : [
        ]
    }),


    
    Species.new(data:{
        name : 'Rat',
        rarity : 100,
        description: 'A mammal race of medium stature',
        growth : StatSet.new(
            HP : 4,
            AP : 3,
            ATK: 3,
            DEF: 3,
            INT: 4,
            LUK: 5,
            SPD: 3,
            DEX: 3
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),

    Species.new(data:{
        name : 'Caracal',
        rarity : 40,
        description: 'A felid race of medium stature',
        growth : StatSet.new(
            HP : 3,
            AP : 4,
            ATK: 2,
            DEF: 3,
            INT: 5,
            LUK: 2,
            SPD: 6,
            DEX: 2
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),

    Species.new(data:{
        name : 'Tanuki',
        rarity : 40,
        description: 'A canid race of medium stature',
        growth : StatSet.new(
            HP : 3,
            AP : 4,
            ATK: 2,
            DEF: 2,
            INT: 5,
            LUK: 2,
            SPD: 3,
            DEX: 6
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),


    Species.new(data:{
        name : 'Werewolf',
        rarity : 200,
        description: 'Canid race thought to be blessed by the moon.',
        growth : StatSet.new(
            HP : 8,
            AP : 2,
            ATK: 10,
            DEF: 1,
            INT: 2,
            LUK: 0,
            SPD: 10,
            DEX: 1
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),
    
    Species.new(data:{
        name : 'Hyena',
        rarity: 100,
        description: 'A mammal race of medium stature.',
        growth : StatSet.new(
            HP : 4,
            AP : 2,
            ATK: 4,
            DEF: 3,
            INT: 7,
            LUK: 2,
            SPD: 6,
            DEX: 7
        ),
        special : false,
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        passives : [
        ]
    }),

    
    Species.new(data:{
        name : 'Gnoll',
        rarity : 200,
        description: 'A mammal race of medium stature.',
        growth : StatSet.new(
            HP : 6,
            AP : 1,
            ATK: 8,
            DEF: 5,
            INT: 2,
            LUK: 1,
            SPD: 6,
            DEX: 3
        ),
        qualities : [
            'snout',
            'fur',
            'eyes',
            'ears',
            'face',
            'body'
        ],
        
        special : false,
        passives : [
        ]
    }),
    
    
    Species.new(data:{
        name : 'Creature',
        rarity : 200000000000,
        description: '',
        growth : StatSet.new(
            HP : 7,
            AP : 1,
            ATK: 4,
            DEF: 4,
            INT: 2,
            LUK: 1,
            SPD: 7,
            DEX: 4
        ),
        qualities : [
        ],
        
        special : true,
        passives : [
        ]
    }),



    Species.new(data:{
        name : 'Fire Sprite',
        rarity : 2000000000000,
        description: 'Hot n\' spicy!',
        growth : StatSet.new(
            HP : 3,
            AP : 1,
            ATK: 7,
            DEF: 4,
            INT: 7,
            LUK: 1,
            SPD: 2,
            DEX: 4
        ),
        qualities : [

        ],
        
        special : true,
        passives : [
        ]
    }),

    Species.new(data:{
        name : 'Ice Elemental',
        rarity : 2000000000000,
        description: 'Brrr that\'s cold!',
        growth : StatSet.new(
            HP : 7,
            AP : 4,
            ATK: 7,
            DEF: 4,
            INT: 7,
            LUK: 1,
            SPD: 6,
            DEX: 4
        ),
        qualities : [

        ],
        
        special : true,
        passives : [
        ]
    }),
    
    Species.new(data:{
        name : 'Thunder Spawn',
        rarity : 2000000000000,
        description: 'Shocking!',
        growth : StatSet.new(
            HP : 7,
            AP : 6,
            ATK: 10,
            DEF: 4,
            INT: 7,
            LUK: 1,
            SPD: 6,
            DEX: 4
        ),
        qualities : [

        ],
        
        special : true,
        passives : [
        ]
    }),    


    Species.new(data:{
        name : 'Guiding Light',
        rarity : 2000000000000,
        description: 'Oh!',
        growth : StatSet.new(
            HP : 7,
            AP : 12,
            ATK: 2,
            DEF: 4,
            INT: 7,
            LUK: 1,
            SPD: 6,
            DEX: 8
        ),
        qualities : [

        ],
        
        special : true,
        passives : [
        ]
    }),    
    

    
    Species.new(data:{
        name : 'Wyvern',
        rarity : 2000000000000,
        description: 'Keepers of the gates',
        growth : StatSet.new(
            HP : 60,
            AP : 10,
            ATK: 10,
            DEF: 10,
            INT: 10,
            LUK: 10,
            SPD: 10,
            DEX: 10
        ),
        qualities : [
        ],
        
        special : true,
        passives : [
        ]
    }),

    Species.new(data:{
        name : 'Wyvern of Fire',
        rarity : 2000000000000,
        description: 'Keepers of the gates',
        growth : StatSet.new(
            HP : 60,
            AP : 10,
            ATK: 10,
            DEF: 10,
            INT: 10,
            LUK: 10,
            SPD: 10,
            DEX: 10
        ),
        qualities : [
        ],
        
        special : true,
        passives : [
        ]
    }),

    Species.new(data:{
        name : 'Wyvern of Ice',
        rarity : 2000000000000,
        description: 'Keepers of the gates',
        growth : StatSet.new(
            HP : 60,
            AP : 10,
            ATK: 10,
            DEF: 10,
            INT: 10,
            LUK: 10,
            SPD: 10,
            DEX: 10
        ),
        qualities : [
        ],
        
        special : true,
        passives : [
            'Icy'
        ]
    }),


    
]);


return Species;
