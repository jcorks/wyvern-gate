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
Material.newEntry(
  data : {
    name : 'Hardstone',
    id : 'base:hardstone',
    description : 'The polished hardstone it\'s made of is dark and shiny.',
    rarity : 13,
    tier : 0,
    statMod : StatSet.new(
      DEF: 3,
      ATK: 7,
      SPD: -5
    ),
    enchantLimit : 2,
    pricePercentMod: 20
  }
)

Material.newEntry(
  data : {
    name : 'Copper',
    id : 'base:copper',
    description : 'The copper material used gives off a radiant brown color.',
    rarity : 13,
    tier : 0,
    statMod : StatSet.new(
      DEF: 5,
      ATK: 6
    ),
    enchantLimit : 3,
    pricePercentMod: 20
  }
)

Material.newEntry(
  data : {
    name : 'Steel',
    id : 'base:steel',
    description : 'The steel used gives a persistent shine.',
    rarity : 15,
    tier : 1,
    statMod : StatSet.new(
      DEF: 30,
      ATK: 30
    ),
    enchantLimit : 4,
    pricePercentMod: 100
  }
)

Material.newEntry(
  data : {
    name : 'Iron',
    id : 'base:iron',
    description : 'The iron used gives it a solid grey color.',
    rarity : 13,
    tier : 0,
    statMod : StatSet.new(
      DEF: 10,
      ATK: 20,
      SPD: -5
    ),
    enchantLimit : 4,
    pricePercentMod: 35
  }
)

Material.newEntry(
  data : {
    name : 'Gold',
    id : 'base:gold',
    description : 'The gold used gives a radiant glow.',
    rarity : 30,
    tier : 1,
    statMod : StatSet.new(
      DEF: 5,
      ATK: 10,
      INT: 30,
      SPD: 5
    ),
    enchantLimit : 10,
    pricePercentMod: 300
  }
)


Material.newEntry(
  data : {
    name : 'Crystal',
    id : 'base:crystal',
    description : 'The crystal material grants a haunting translucency.',
    rarity : 60,
    tier : 1,
    statMod : StatSet.new(
      DEF: -10,
      ATK: 30,
      INT: 30,
      SPD: 10
    ),
    enchantLimit : 5,
    pricePercentMod: 500
  }
)



Material.newEntry(
  data : {
    name : 'Ethereal',
    id : 'base:ethereal',
    description : 'The magic used to create this makes it feel solid yet light.',
    rarity : 100,
    tier : 2,
    statMod : StatSet.new(
      DEF: 10,
      ATK: 30,
      INT: 35,
      SPD: 15
    ),
    enchantLimit : 10,
    pricePercentMod: 800
  }
)



Material.newEntry(
  data : {
    name : 'Tungsten',
    id : 'base:tungsten',
    description : 'The tungsten used gives it a whitish-grey color.',
    rarity : 15,
    tier : 1,
    statMod : StatSet.new(
      DEF: 20,
      ATK: 25,
      SPD: -10
    ),
    enchantLimit : 5,
    pricePercentMod: 35
  }
)


Material.newEntry(
  data : {
    name : 'Mythril',
    id : 'base:mythril',
    description : 'The mythril used makes it radiantly green.',
    rarity : 70,
    tier : 2,
    statMod : StatSet.new(
      DEF: 70,
      ATK: 70,
      SPD: 30
    ),
    enchantLimit : 8,
    pricePercentMod: 1200
  }
)

Material.newEntry(
  data : {
    name : 'Adamantine',
    id : 'base:adamantine',
    description : 'The adamantine used makes it earthly.',
    rarity : 90,
    tier : 3,
    statMod : StatSet.new(
      DEF: 100,
      ATK: 100
    ),
    enchantLimit : 6,
    pricePercentMod: 1600
  }
)  

Material.newEntry(
  data : {
    name : 'Quicksilver',
    id : 'base:quicksilver',
    description : 'The quicksilver used makes it remarkably shiny.',
    rarity : 110,
    tier : 3,
    statMod : StatSet.new(
      DEF: 50,
      ATK: 50,
      SPD: 60,
      DEX: 40
    ),
    enchantLimit : 5,
    pricePercentMod: 1900
  }
)  

Material.newEntry(
  data : {
    name : 'Dragonglass',
    id : 'base:dragonglass',
    description : 'The dragonglass used gives it a deep black color.',
    rarity : 110,
    tier : 3,
    statMod : StatSet.new(
      DEF: -20,
      ATK: 150,
      SPD: 10,
      DEX: 60
    ),
    enchantLimit : 5,
    pricePercentMod: 1800
  }
)  

Material.newEntry(
  data : {
    name : 'Composite',
    id : 'base:composite',
    rarity : 20,
    description : 'The composite material used is sturdy.',
    tier : 1,
    statMod : StatSet.new(
      DEF: 45,
      ATK: 45,
      SPD: 20
    ),
    enchantLimit : 5,
    pricePercentMod: 210
  }
)  

Material.newEntry(
  data : {
    name : 'Skystone',
    id : 'base:skystone',
    rarity : 220,
    description : 'The rare skystone material makes it feel very light.',
    tier : 5,
    statMod : StatSet.new(
      DEF: 20,
      ATK: 200,
      SPD: 100,
      DEX: 150
    ),
    enchantLimit : 8,
    pricePercentMod: 7500
  }
)  



Material.newEntry(
  data : {
    name : 'Ray',
    id : 'base:ray',
    rarity : 260,
    description : 'Parts of this seem to be made of solid light.',
    tier : 5,
    statMod : StatSet.new(
      DEF: 60,
      INT: 200,
      ATK: 200,
      SPD: 100
    ),
    enchantLimit : 10,
    pricePercentMod: 9500
  }
)  

Material.newEntry(
  data : {
    name : 'Sunstone',
    id : 'base:sunstone',
    rarity : 50,
    description : 'The sunstone used gives it a warm touch.',
    tier : 1,
    statMod : StatSet.new(
      DEF: 35,
      INT: 15,
      ATK: 35
    ),
    enchantLimit : 5,
    pricePercentMod: 150
  }
)   

Material.newEntry(
  data : {
    name : 'Moonstone',
    id : 'base:moonstone',
    rarity : 50,
    description : 'The moonstone used gives it a cold touch.',
    tier : 1,
    statMod : StatSet.new(
      DEF: 15,
      INT: 35,
      ATK: 35
    ),
    enchantLimit : 5,
    pricePercentMod: 150
  }
)


}

@:Material = Database.new(
  name : 'Wyvern.Material',
  attributes : {
    name : String,
    id : String,
    rarity : Number,
    tier : Number,
    description : String,
    statMod : StatSet.type, // percentages
    enchantLimit : Number,
    pricePercentMod : Number
  },
  reset      
);


return Material;

