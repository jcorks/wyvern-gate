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


@:SPECIES_NAME = 'Wyvern.Species'

@:Species = Database.create(
    name : 'Wyvern.Species',
    attributes : {
        name : String,
        rarity: Number,
        qualities : Object,
        description : String,
        growth : StatSet.type,
        passives : Object,
        special : Boolean,
        swarms : Boolean
    }            
);


// 36 points

Species.newEntry(data:{
    name : 'Wolf',
    rarity : 10,
    description: 'A common canid race.',
    growth : StatSet.new(
        HP : 8,
        AP : 2,
        ATK: 4,
        DEF: 4,
        INT: 2,
        LUK: 1,
        SPD: 7,
        DEX: 8
    ),        
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'body',
        'tail'
    ],
    special : false,
    passives : [
    ],
    swarms : false
})

Species.newEntry(data:{
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
        'body',
        'tail'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})


Species.newEntry(data:{
    name : 'Rabbit',
    rarity : 10,
    description: 'A mammal race of medium stature.',
    growth : StatSet.new(
        HP : 2,
        AP : 6,
        ATK: 4,
        DEF: 1,
        INT: 4,
        LUK: 4,
        SPD: 7,
        DEX: 8
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})


Species.newEntry(data:{
    name : 'Fox',
    rarity : 10,
    description: 'A canid race.',
    growth : StatSet.new(
        HP : 2,
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
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})

Species.newEntry(data:{
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
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})    

Species.newEntry(data:{
    name : 'Tiger',
    description: 'A common felid race.',
    rarity : 45,
    growth : StatSet.new(
        HP : 5,
        AP : 3,
        ATK: 7,
        DEF: 2,
        INT: 4,
        LUK: 2,
        SPD: 6,
        DEX: 7
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})

Species.newEntry(data:{
    name : 'Deer',
    description: 'A common ungulate race.',
    rarity : 10,
    growth : StatSet.new(
        HP : 3,
        AP : 4,
        ATK: 3,
        DEF: 4,
        INT: 4,
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
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})


Species.newEntry(data:{
    name : 'Goat',
    description: 'A common ungulate race.',
    rarity : 10,
    growth : StatSet.new(
        HP : 3,
        AP : 4,
        ATK: 4,
        DEF: 2,
        INT: 3,
        LUK: 6,
        SPD: 6,
        DEX: 8
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'tail',
        'body',
        'horns'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})


Species.newEntry(data:{
    name : 'Sheep',
    description: 'A common ungulate race.',
    rarity : 10,
    growth : StatSet.new(
        HP : 3,
        AP : 6,
        ATK: 3,
        DEF: 4,
        INT: 6,
        LUK: 4,
        SPD: 6,
        DEX: 4
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'tail',
        'body',
        'horns'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})
Species.newEntry(data:{
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
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})    


Species.newEntry(data:{
    name : 'Kobold',
    description: 'A common dragon-like race of small stature.',
    rarity : 30,
    growth : StatSet.new(
        HP : 1,
        AP : 8,
        ATK: 1,
        DEF: 1,
        INT: 8,
        LUK: 1,
        SPD: 8,
        DEX: 8
    ),
    qualities : [
        'snout',
        'scales',
        'eyes',
        'face',
        'tail',
        'horns',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})


Species.newEntry(data:{
    name : 'Drake-kin',
    description: 'A common dragon-like race of medium stature with fur.',
    rarity : 30,
    growth : StatSet.new(
        HP : 5,
        AP : 4,
        ATK: 4,
        DEF: 9,
        INT: 5,
        LUK: 2,
        SPD: 1,
        DEX: 6
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'face',
        'tail',
        'horns',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})

Species.newEntry(data:{
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
        SPD: 8,
        DEX: 7
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})


Species.newEntry(data:{
    name : 'Jackal',
    rarity : 30,
    description: 'A slender canid race.',
    growth : StatSet.new(
        HP : 6,
        AP : 5,
        ATK: 2,
        DEF: 2,
        INT: 4,
        LUK: 6,
        SPD: 5,
        DEX: 6
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})

Species.newEntry(data:{
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
        DEX: 3
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})

Species.newEntry(data:{
    name : 'Bear',
    rarity : 100,
    description: 'A large mammal race.',
    growth : StatSet.new(
        HP : 12,
        AP : 1,
        ATK: 8,
        DEF: 9,
        INT: 2,
        LUK: 1,
        SPD: 1,
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
    swarms : false,
    
    special : false,
    passives : [
    ]
})

Species.newEntry(data:{
    name : 'Kangaroo',
    rarity : 100,
    description: 'A large mammal race.',
    growth : StatSet.new(
        HP : 5,
        AP : 4,
        ATK: 10,
        DEF: 2,
        INT: 5,
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
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})

Species.newEntry(data:{
    name : 'Raven',
    rarity : 100,
    description: 'A bird race of medium stature',
    growth : StatSet.new(
        HP : 3,
        AP : 9,
        ATK: 3,
        DEF: 2,
        INT: 8,
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
    swarms : false,
    special : false,
    passives : [
    ]
})


Species.newEntry(data:{
    name : 'Pigeon',
    rarity : 100,
    description: 'A bird race of medium stature',
    growth : StatSet.new(
        HP : 4,
        AP : 1,
        ATK: 5,
        DEF: 5,
        INT: 1,
        LUK: 9,
        SPD: 10,
        DEX: 1
    ),
    qualities : [
        'feathers',
        'eyes',
        'face',
        'body'
    ],        
    swarms : false,
    
    special : false,
    passives : [
    ]
})



Species.newEntry(data:{
    name : 'Rat',
    rarity : 100,
    description: 'A rodent race of medium stature',
    growth : StatSet.new(
        HP : 5,
        AP : 5,
        ATK: 4,
        DEF: 4,
        INT: 5,
        LUK: 3,
        SPD: 5,
        DEX: 5
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})

Species.newEntry(data:{
    name : 'Caracal',
    rarity : 40,
    description: 'A felid race of medium stature',
    growth : StatSet.new(
        HP : 4,
        AP : 6,
        ATK: 3,
        DEF: 4,
        INT: 7,
        LUK: 2,
        SPD: 7,
        DEX: 3
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})

Species.newEntry(data:{
    name : 'Tanuki',
    rarity : 40,
    description: 'A canid race of medium stature',
    growth : StatSet.new(
        HP : 6,
        AP : 4,
        ATK: 2,
        DEF: 8,
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
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})


Species.newEntry(data:{
    name : 'Werewolf',
    rarity : 200,
    description: 'Canid race thought to be blessed by the moon.',
    growth : StatSet.new(
        HP : 8,
        AP : 2,
        ATK: 10,
        DEF: 1,
        INT: 2,
        LUK: 1,
        SPD: 10,
        DEX: 2
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})

Species.newEntry(data:{
    name : 'Hyena',
    rarity: 100,
    description: 'A mammal race of medium stature.',
    growth : StatSet.new(
        HP : 4,
        AP : 2,
        ATK: 5,
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
        'tail',
        'body'
    ],
    swarms : false,
    
    passives : [
    ]
})


Species.newEntry(data:{
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
        SPD: 7,
        DEX: 6
    ),
    qualities : [
        'snout',
        'fur',
        'eyes',
        'ears',
        'face',
        'tail',
        'body'
    ],
    swarms : false,
    
    special : false,
    passives : [
    ]
})


Species.newEntry(data:{
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
    swarms : true,
    
    special : true,
    passives : [
    ]
})



Species.newEntry(data:{
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
    swarms : false,
    
    special : true,
    passives : [
    ]
})

Species.newEntry(data:{
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
    swarms : false,
    
    special : true,
    passives : [
    ]
})

Species.newEntry(data:{
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
    swarms : false,
    
    special : true,
    passives : [
    ]
})    


Species.newEntry(data:{
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
    swarms : false,
    
    special : true,
    passives : [
    ]
})    



Species.newEntry(data:{
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
    swarms : false,
    
    special : true,
    passives : [
    ]
})

Species.newEntry(data:{
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
    swarms : false,
    
    special : true,
    passives : [
    ]
})

Species.newEntry(data:{
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
    swarms : false,
    
    special : true,
    passives : [
        'Icy'
    ]
})


Species.newEntry(data:{
    name : 'Wyvern of Thunder',
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
    swarms : false,
    
    special : true,
    passives : [
        'Shock'
    ]
})


Species.newEntry(data:{
    name : 'Wyvern of Light',
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
    swarms : false,
    
    special : true,
    passives : [
        'Shimmering'
    ]
})


Species.newEntry(data:{
    name : 'Wyvern Specter',
    rarity : 2000000000000,
    description: 'Ancient spirit',
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
    swarms: true,
    special : true,
    passives : [
        'Apparition'
    ]
})


Species.newEntry(data:{
    name : 'Beast',
    rarity : 2000000000000,
    description: 'Force of nature',
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
    swarms : true,
    
    special : true,
    passives : [
        'The Beast'
    ]
})


Species.newEntry(data:{
    name : 'Treasure Golem',
    rarity : 2000000000000,
    description: 'Looks like a chest! Not as friendly though.',
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
    swarms : true,
    
    special : true,
    passives : [
    ]
})


Species.newEntry(data:{
    name : 'Cave Bat',
    rarity : 2000000000000,
    description: 'Large, wild bat.',
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
    swarms : true,
    
    special : true,
    passives : [
    ]
})
return Species;
