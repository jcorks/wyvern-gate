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


@:reset::{
ApparelMaterial.newEntry(
  data : {
    name : 'Cloth',
    id : 'base:cloth',
    description : 'The cloth used is generic and nondescript, but comfortable.',
    rarity : 3,
    tier : 0,
    statMod : StatSet.new(
      DEF: 3,
      SPD: 5
    ),
    enchantLimit : 2,
    pricePercentMod: 20
  }
)


ApparelMaterial.newEntry(
  data : {
    name : 'Leather',
    id : 'base:leather',
    description : 'The rough leather of the item makes it quite sturdy.',
    rarity : 3,
    tier : 0,
    statMod : StatSet.new(
      DEF: 15,
      ATK: 5,
      DEX: 5,
      SPD: -2
    ),
    enchantLimit : 2,
    pricePercentMod: 20
  }
)

ApparelMaterial.newEntry(
  data : {
    name : 'Linen',
    id : 'base:linen',
    description : 'The linen used offers durability mixed with comfort.',
    rarity : 3,
    tier : 0,
    statMod : StatSet.new(
      DEF: 10,
      ATK: 5,
      DEX: 5,
      SPD: 5
    ),
    enchantLimit : 3,
    pricePercentMod: 20
  }
)

ApparelMaterial.newEntry(
  data : {
    name : 'Silk',
    id : 'base:silk', 
    description : 'The silk material feels lavishly soft.',
    rarity : 3,
    tier : 1,
    statMod : StatSet.new(
      INT: 10,
      SPD: 20,
      DEX: 15
    ),
    enchantLimit : 4,
    pricePercentMod: 200
  }
)

ApparelMaterial.newEntry(
  data : {
    name : 'Wool',
    id : 'base:wool',
    description : 'The wool material feels warm and soft.',
    rarity : 3,
    tier : 1,
    statMod : StatSet.new(
      INT: 10,
      DEF: 20,
      DEX: 5,
      DEF: 5
    ),
    enchantLimit : 5,
    pricePercentMod: 100
  }
)



ApparelMaterial.newEntry(
  data : {
    name : 'Wool+',
    id : 'base:wool-plus',
    description : 'The wool used is different somehow.',
    rarity : 3,
    tier : 100,
    statMod : StatSet.new(
      INT: 25,
      DEF: 25,
      DEX: 25,
      DEF: 25,
      ATK: 25
    ),
    enchantLimit : 2,
    pricePercentMod: 30
  }
)

ApparelMaterial.newEntry(
  data : {
    name : 'Mythril',
    id : 'base:mythril',
    description : 'The mythril used makes it radiantly green',
    rarity : 30,
    tier : 2,
    statMod : StatSet.new(
      DEF: 70,
      ATK: 70,
      SPD: 30
    ),
    enchantLimit : 5,
    pricePercentMod: 1200
  }
)


ApparelMaterial.newEntry(
  data : {
    name : 'Eversilk',
    id : 'base:eversilk',
    description : 'The wool used is different somehow.',
    rarity : 40,
    tier : 2,
    statMod : StatSet.new(
      INT: 35,
      DEF: 35,
      DEX: 35,
      DEF: 35,
      ATK: 35,
      SPD: 35
    ),
    enchantLimit : 7,
    pricePercentMod: 3000
  }
)


ApparelMaterial.newEntry(
  data : {
    name : 'Soulstrand',
    id : 'base:soulstrand',
    description : 'The soulstrand material softly glows.',
    rarity : 50,
    tier : 3,
    statMod : StatSet.new(
      INT: 105,
      DEF: 105,
      DEX: 105,
      DEF: 105,
      SPD: 105,
      ATK: 105
    ),
    enchantLimit : 10,
    pricePercentMod: 10000
  }
)
}

@:ApparelMaterial = Database.new(
  name: 'Wyvern.ApparelMaterial',
  attributes : {
    name : String,
    id : String,
    rarity : Number,
    tier : Number,
    enchantLimit: Number,
    description : String,
    statMod : StatSet.type, // percentages
    pricePercentMod : Number
  },
  reset
);



return ApparelMaterial;

