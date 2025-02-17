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

@:TYPE = {
  NEUTRAL  : 0, //<- The Guide 
   FIRE     : 1,//<- The Flame
   THUNDER  : 2,//<- The Column
   ICE      : 3,//<- The Crystal
  LIGHT    : 4, //<- The Soul
  DARK     : 5, //<- The Vessel
  PHYS     : 6, //<- The Obelisk
  POISON   : 7  //<- The Sigil
}

@:CLASS = {
  HP : 0,
  AP : 1
}

@:TRAITS = {
  MULTIHIT : 1,
  FORCE_CRIT : 2,
  FORCE_DEF_BYPASS : 4,
  IS_CRIT : 8
}

@:type = Object.newType(
  name: 'Wyvern.Damage',
  layout : {
    damageClass : Number,
    amount : Number,
    damageType : Number,
    traits : Number
  }
);

@:Damage = {
  TYPE : TYPE,
  TRAITS : TRAITS,
  CLASS : CLASS,
  type : type,
  new ::(amount, damageType, damageClass, traits) {
    @:out = Object.instantiate(type);
    out.damageClass = damageClass;
    out.damageType = damageType;
    out.amount = amount;
    out.traits = if (traits == empty) 0 else traits;
    return out;
  }
}

return Damage;
