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



@:reset ::{


ItemQuality.newEntry(
  data : {
    name : 'Worn',
    id : 'base:worn',
    description : 'The surface appears worn out; it might not be able to last much longer.',
    equipMod : StatSet.new(
      DEF: -20,
      ATK: -5,
      DEX: -10
    ),
    pricePercentMod: -60,
    levelMinimum : 1,
    equipEffects : [
    ],
    rarity: 2,
    
    useEffects : []
  }
)






ItemQuality.newEntry(
  data : {
    name : 'Cheap',
    id : 'base:cheap',
    description : 'It is of poor quality.',
    equipMod : StatSet.new(
      DEF: -10,
      ATK: -10,
      DEX: -5
    ),
    levelMinimum : 1,
    pricePercentMod: -50,
    
    equipEffects : [
    ],
    
    rarity: 3,
    
    useEffects : []
  }
)


ItemQuality.newEntry(
  data : {
    name : 'Sturdy',
    id : 'base:sturdy',
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
)        


ItemQuality.newEntry(
  data : {
    name : 'Robust',
    id : 'base:robust',
    description : 'It has been shown that this is resistant to even heavy use.',
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
)


ItemQuality.newEntry(
  data : {
    name : 'Quality',
    id : 'base:quality',
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
)

ItemQuality.newEntry(
  data : {
    name : 'Light',
    id : 'base:light',
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
)

ItemQuality.newEntry(
  data : {
    name : 'Decorative',
    id : 'base:decorative',
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
)

ItemQuality.newEntry(
  data : {
    name : 'Apprentice\'s',
    id : 'base:apprentices',
    description : "This seems to be the work of a master's apprentice.",
    levelMinimum: 1,
    equipMod : StatSet.new(
      DEF: 10,
      ATK: 10,
      SPD: 10,
      DEX: 10
    ),
    pricePercentMod: 110,
    equipEffects : [
    ],
    rarity: 25,
    
    useEffects : []
  }
)

ItemQuality.newEntry(
  data : {
    name : 'Reinforced',
    id : 'base:reinforced',
    description : "Extra care has been taken to assure that this will last a long time.",
    levelMinimum: 1,
    equipMod : StatSet.new(
      DEF: 15,
      ATK: 15,
      DEX: 15
    ),
    pricePercentMod: 115,
    equipEffects : [
    ],
    rarity: 25,
    
    useEffects : []
  }
)

ItemQuality.newEntry(
  data : {
    name : 'Durable',
    id : 'base:durable',
    description : "At the intersection of good quality materials and workmanship.",
    levelMinimum: 1,
    equipMod : StatSet.new(
      DEF: 20,
      ATK: 20,
      DEX: 20,
      SPD: 20
    ),
    pricePercentMod: 117,
    equipEffects : [
    ],
    rarity: 25,
    
    useEffects : []
  }
)

ItemQuality.newEntry(
  data : {
    name : 'Standard',
    id : 'base:standard',
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
)

ItemQuality.newEntry(
  data : {
    name : 'King\'s',
    id : 'base:kings',
    description : "The quality of this is as if it were meant for a king.",
    levelMinimum: 1,
    equipMod : StatSet.new(
      DEF: 50,
      ATK: 50,
      SPD: 50,
      DEX: 50
    ),
    pricePercentMod: 1200,
    equipEffects : [
    ],
    rarity: 25,
    
    useEffects : []
  }
)

ItemQuality.newEntry(
  data : {
    name : 'Queen\'s',
    id : 'base:queens',
    description : "The quality of this is as if it were meant for a queen.",
    levelMinimum: 1,
    equipMod : StatSet.new(
      DEF: 75,
      ATK: 75,
      SPD: 75,
      DEX: 75
    ),
    pricePercentMod: 2500,
    equipEffects : [
    ],
    rarity: 50,
    
    useEffects : []
  }
)

ItemQuality.newEntry(
  data : {
    name : 'Masterwork',
    id : 'base:masterwork',
    description : "A crowning achievement by a craftsperson representing a life's work.",
    levelMinimum: 1,
    equipMod : StatSet.new(
      DEF: 100,
      ATK: 100,
      SPD: 100,
      DEX: 100
    ),
    rarity: 100,
    pricePercentMod: 3600,
    equipEffects : [
    ],
    
    useEffects : []
  }
) 





ItemQuality.newEntry(
  data : {
    name : 'Legendary',
    id : 'base:legendary',
    description : "It is said that this is part of some legend.",
    levelMinimum: 1,
    equipMod : StatSet.new(
      DEF: 150,
      ATK: 150,
      SPD: 150,
      DEX: 150
    ),
    rarity: 200,
    pricePercentMod: 9600,
    equipEffects : [
    ],
    
    useEffects : []
  }
) 


ItemQuality.newEntry(
  data : {
    name : 'Divine',
    id : 'base:divine',
    description : "It is said the origin of this is mythical.",
    levelMinimum: 1,
    equipMod : StatSet.new(
      DEF: 200,
      ATK: 200,
      SPD: 200,
      DEX: 200,
      INT: 50
    ),
    rarity: 400,
    pricePercentMod: 10600,
    equipEffects : [
    ],
    
    useEffects : []
  }
) 

ItemQuality.newEntry(
  data : {
    name : 'God\'s',
    id : 'base:gods',
    description : "It is said this was created by a deity.",
    levelMinimum: 1,
    equipMod : StatSet.new(
      DEF: 400,
      ATK: 400,
      SPD: 400,
      DEX: 400,
      INT: 400
    ),
    rarity: 1000,
    pricePercentMod: 29600,
    equipEffects : [
    ],
    
    useEffects : []
  }
) 


ItemQuality.newEntry(
  data : {
    name : '[  ]',
    id : 'base:null',
    description : "It is said this shouldn\'t exist.",
    levelMinimum: 1,
    equipMod : StatSet.new(
      DEF: 1000,
      ATK: 1000,
      SPD: 1000,
      DEX: 1000,
      INT: 1000
    ),
    rarity: 8000,
    pricePercentMod: 40000,
    equipEffects : [
    ],
    
    useEffects : []
  }
) 
}

@:ItemQuality = Database.new(
  name : 'Wyvern.ItemQuality',
  attributes : {
    name : String,
    id : String,
    description : String,
    levelMinimum : Number,
    equipMod : StatSet.type, // percentages
    useEffects : Object,
    equipEffects : Object,
    pricePercentMod : Number,
    rarity: Number
  },
  reset 
);




return ItemQuality;
