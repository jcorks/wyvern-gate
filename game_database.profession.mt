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
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:StatSet = import(module:'game_class.statset.mt');




/*

    Each profession:
        - 32 pts base 
        - 8 skills
        
    + 8 pts for each missing skill
    - 1 skill for passive


*/
@:reset ::{
Profession.newEntry(data:{
    name: 'Adventurer',
    id : 'base:adventurer',
    description : 'General, well-rounded profession. Learns abilities on-the-fly to stay alive.', 
    weaponAffinity : 'base:shortsword',
    growth: StatSet.new(
        HP:  4,
        AP:  4,
        ATK: 4,
        INT: 4,
        DEF: 4,
        SPD: 4,
        LUK: 4,
        DEX: 4
    ),
    minKarma : 0,
    maxKarma : 1000,
    levelMinimum : 1,
    learnable : true,
    arts : [
        'base:first-aid',        //X
        'base:combo-strike',       //X
        'base:doublestrike',     //X2 hits RNG targets, 80% of attack
        'base:focus-perception', //X + 25% ATK for 5 turns 
        'base:cheer',            //X + 30% ATK for whole party 5 turns
        'base:follow-up',        //X if hurt this turn, does +150% damage, else is attack strength
        'base:grapple',          //X No action for user or target for 3 turns
        'base:triplestrike',     //X 3 hits RNG targets, 70% power
    ],
    
    passives : []
})

Profession.newEntry(data:{
    name: 'Martial Artist',
    id : 'base:martial-artist',
    weaponAffinity: 'base:staff',
    description : 'A fighter that uses various stances to bend to the flow of battle.', 
    growth: StatSet.new(
        HP:  6,
        AP:  2,
        ATK: 5,
        INT: 2,
        DEF: 4,
        SPD: 5,
        LUK: 2,
        DEX: 6
    ),
    minKarma : 100,
    maxKarma : 1000,
    levelMinimum : 1,
    learnable : true,
    arts : [
        // only one stance at a time
        'base:doublestrike',  //X +%75 Def -50% Atk
        'base:triplestrike',  //X +%75 Atk -50% Def
        'base:doublestrike',  //X +%75 Def -50% Atk
        'base:triplestrike',  //X +%75 Atk -50% Def
        'base:combo-strike',      //X +75% Speed -50% Atk
        'base:counter',      //X +75% Def -50% Spd 
        'base:reflective-stance', //X if hit, retaliates
        'base:evasive-stance',    //X 50% chance evade
        
    ],
    
    passives : []            

})

Profession.newEntry(data:{
    name: 'Field Mage',
    id : 'base:field-mage',
    description : 'A self-taught mage. Knows a variety of magicks.', 
    weaponAffinity: 'base:wand',
    growth: StatSet.new(
        HP:  3,
        AP:  7,
        ATK: 3,
        INT: 6,
        DEF: 3,
        SPD: 3,
        LUK: 4,
        DEX: 3
    ),
    minKarma : 100,
    maxKarma : 1000,
    learnable : true,
    levelMinimum : 1,
    
    arts : [
        'base:fire',     //X
        'base:ice',      //X all enemies
        'base:meditate', //X AP recover, this
        'base:thunder',  //X 4 random strikes
        'base:mind-focus',//X +100% INT for 10 turns
        'base:flash',    //X all enemies, 50% chance cant act for a turn
        'base:flare',    //X one enemy, big damage
        'base:explosion', //X all enemies, fire big damage
    ],
    
    passives : []
})


Profession.newEntry(data:{
    name: 'Cleric',
    id : 'base:cleric',
    description : 'A self-taught healing mage. Knows a variety of magicks.', 
    weaponAffinity: 'base:mage-staff',
    growth: StatSet.new(
        HP:  5,
        AP:  8,
        ATK: 4,
        INT: 8,
        DEF: 2,
        SPD: 4,
        LUK: 5,
        DEX: 4
    ),
    minKarma : 100,
    maxKarma : 1000,
    learnable : true,
    levelMinimum : 1,
    
    arts : [
        'base:cure',         //X
        'base:cleanse',      //X removal of standard status ailments
        'base:protect',      //X
        'base:cure-all', //X
        'base:protect-all',  //X
        'base:soothe',       //X ap recovery, any
        'base:grace',        //X save from death, once    
    ],
    
    passives : []
})

Profession.newEntry(data:{
    name: 'Divine Lunist',
    id : 'base:divine-lunist',
    weaponAffinity: 'base:tome',
    description : 'Blessed by the moon, their magicks are entwined with the night.', 
    growth: StatSet.new(
        HP:  3,
        AP:  8,
        ATK: 2,
        INT: 9,
        DEF: 4,
        SPD: 7,
        LUK: 5,
        DEX: 4

    ),
    minKarma : 100,
    maxKarma : 1000,
    learnable : true,
    levelMinimum : 1,
    
    arts : [
        'base:lunar-blessing',   //X make it night time
        'base:moonbeam',         //X attack enhanced by night time
        'base:night-veil',       //X +100% Def if in night time
        'base:moonsong',         //X HoT if in night time
        'base:call-of-the-night',//X +60% ATK if in night time
        'base:lunacy',           //X Berserk: attacks random enemy instead of turn, +70% ATK and +70% DEF. only usable at night
    ],
    passives : [
        'base:lunar-affinity'
    ]
})

Profession.newEntry(data:{
    name: 'Divine Solist',
    id : 'base:divine-solist',
    weaponAffinity: 'base:tome',
    description : 'Blessed by the sun, their magicks are entwined with daylight.', 
    growth: StatSet.new(
        HP:  3,
        AP:  8,
        ATK: 2,
        INT: 9,
        DEF: 4,
        SPD: 7,
        LUK: 5,
        DEX: 4

    ),
    minKarma : 100,
    maxKarma : 1000,
    learnable : true,
    levelMinimum : 1,
    
    arts : [
        'base:solar-blessing', //X make it day time
        'base:sunbeam',        //X attack enhanced by day 
        'base:dayshroud',      //X +100% Def if in day time     
        'base:sol-attunement', //X +5% health every turn
        'base:sunburst',       //X attack enhanced by day 
        'base:phoenix-soul'    //X autorevive once
    ],
    passives : [
        'base:solar-affinity'  //X
    ]
})


Profession.newEntry(data:{
    name: 'Blacksmith',
    id : 'base:blacksmith',
    weaponAffinity: 'base:smithing-hammer',
    description : 'Skilled with metalworking, their skills are revered.', 
    growth: StatSet.new(
        HP:  14,
        AP:  3,
        ATK: 14,
        INT: 2,
        DEF: 11,
        SPD: 3,
        LUK: 8,
        DEX: 9
    ),
    minKarma : 100,
    maxKarma : 1000,
    learnable : true,
    levelMinimum : 1,
    
    arts : [
        'base:sharpen',          //X
        'base:weaken-armor',     //X
        'base:strengthen-armor', //X
        'base:dull-weapon'       //X
    ],
    passives : [
    ]
})

Profession.newEntry(data:{
    name: 'Trader',
    id : 'base:trader',
    weaponAffinity: 'base:dagger',
    description : 'A silver tongue and a quick hand make this profession both lauded and loathed.', 
    growth: StatSet.new(
        HP:  4,
        AP:  12,
        ATK: 4,
        INT: 16,
        DEF: 4,
        SPD: 8,
        LUK: 12,
        DEX: 4
    ),
    minKarma : 100,
    maxKarma : 1000,
    learnable : true,
    levelMinimum : 1,

    arts : [
        'base:convince',     //X convinces target to not do anything for 1 to 3 turns 
        'base:bribe',        //X pay to leave battle
        //'base:quickhand-item',//X do 2 item actions, same target
    ],
    passives : [
        'base:penny-picker'  //X after battle may notice dropped G
    ]
})

Profession.newEntry(data:{
    name: 'Warrior',
    id : 'base:warrior',
    weaponAffinity: 'base:greatsword',
    description : "Excelling in raw strength and technique, users of this profession are fearsome.", 
    growth: StatSet.new(
        HP:  9,
        AP:  1,
        ATK: 9,
        INT: 2,
        DEF: 4,
        SPD: 5,
        LUK: 3,
        DEX: 7
    ),
    minKarma : 0,
    maxKarma : 1000,
    learnable : true,
    levelMinimum : 1,
    
    arts : [
        'base:tackle',           //X Damage, better than attack
        'base:stun',             //X Normal attack with 50% chance to stun
        'base:big-swing',        //X damage all enemies
        'base:leg-sweep',        //X damage all and 50% chance to stun
        'base:stab',             //X bleeding effect
        'base:wild-swing',       //X 4 strong attacks to random targets
        'base:duel',             // pick enemy. if attacking, +225% damage
    ],
    passives : [
    ]
}) 

Profession.newEntry(data:{
    name: 'Guard',
    id : 'base:guard',
    weaponAffinity: 'base:polearm',
    description : "Standard profession excelling in defending others, for better or for worse.", 
    growth: StatSet.new(
        HP:  6,
        AP:  1,
        ATK: 5,
        INT: 3,
        DEF: 7,
        SPD: 4,
        LUK: 3,
        DEX: 4
    ),
    minKarma : 200,
    maxKarma : 1000,
    learnable : true,
    levelMinimum : 1,

    arts : [
        'base:guard',                //X defend 2.0
        'base:proceed-with-caution', //X defense buff for team (10 turns)
        'base:mend',                 //X heal other, no AP cost!!!! but weak
        'base:defend-other',         //X Defends another for 4 turns
        'base:retaliate',            //X auto-attack if hit (10 turns)
        'base:coordination',         //X stat boost for every other in party with same profession 
        'base:perfect-guard',        //X Nullifies all damage for 3 turns
    ],
    passives : [
        'base:trained-hand',         //X +30% attack
    ]
}) 

Profession.newEntry(data:{
    name: 'Summoner',
    id : 'base:summoner',
    weaponAffinity: 'base:tome',
    description : "Amagick-user who is able to temporarily materialize allies.", 
    growth: StatSet.new(
        HP:  5,
        AP:  15,
        ATK: 7,
        INT: 11,
        DEF: 3,
        SPD: 7,
        LUK: 4,
        DEX: 4
    ),
    levelMinimum : 1,

    minKarma : 0,
    maxKarma : 1000,
    learnable : true,
    
    arts : [
        'base:summon-fire-sprite',    //X
        'base:summon-ice-elemental',  //X
        'base:unsummon',               //X removes equip
        'base:summon-thunder-spawn',  //X use random ability of target
        'base:summon-guiding-light',  //X make target fly
        
    ],
    passives : [
    ]
}) 



Profession.newEntry(data:{
    name: 'Arcanist',
    id : 'base:arcanist',
    weaponAffinity: 'base:tome',
    description : "A scholar first, their large knowledge of the arcane yields interesting magicks for any situation.", 
    growth: StatSet.new(
        HP:  3,
        AP:  14,
        ATK: 2,
        INT: 20,
        DEF: 3,
        SPD: 5,
        LUK: 7,
        DEX: 2
    ),
    levelMinimum : 1,

    minKarma : 0,
    maxKarma : 1000,
    learnable : true,
    
    arts : [
        'base:telekinesis',   //X stun for a turn
        'base:frozen-flame',  //X damage all, chance for freeze
        'base:dematerialize', //X removes equip
        //'base:mind-read',     //X use random ability of target
        'base:flight',        //X make target fly
        
    ],
    passives : [
    ]
}) 

Profession.newEntry(data:{
    name: 'Runologist',
    id : 'base:runologist',
    weaponAffinity: 'base:tome',                
    description : "An arcanist scholar who focuses on runes.", 
    growth: StatSet.new(
        HP:  3,
        AP:  13,
        ATK: 2,
        INT: 16,
        DEF: 3,
        SPD: 4,
        LUK: 5,
        DEX: 2
    ),
    levelMinimum : 1,

    minKarma : 0,
    maxKarma : 1000,
    learnable : true,
    
    // runes fade after 10 turns
    arts : [
        'base:poison-rune',       // X weak DoT until released
        'base:rune-release',      // X releases all runes on target
        'base:destruction-rune',  // X damage when released.
        'base:regeneration-rune', // X HoT until released
        'base:shield-rune',       // X DEF + 100% until released
        'base:cure-rune',         // X heal when released
        'base:multiply-runes'     // X ddoubles targets Rune charges
    ],
    passives : [
    ]
}) 


Profession.newEntry(data:{
    name: 'Elementalist',
    id : 'base:elementalist',
    weaponAffinity: 'base:shortsword',                
    description : "Capable of infusing magicks into normal objects for combat.", 
    growth: StatSet.new(
        HP:  5,
        AP:  7,
        ATK: 7,
        INT: 6,
        DEF: 4,
        SPD: 5,
        LUK: 5,
        DEX: 4
    ),
    levelMinimum : 1,

    minKarma : 0,
    maxKarma : 1000,
    learnable : true,
    
    arts : [
        'base:fire-shift',       //X adds fire aspect
        'base:elemental-tag',    //X Take +100% damage from elemental damage type
        'base:ice-shift',        //X adds ice aspect
        'base:elemental-shield', //X Blocks most damage for current elemental aspects.
        'base:thunder-shift',    //X adds thunder aspect
        'base:tri-shift'         //X Stacks all 3
    ],
    passives : [
    ]
})


Profession.newEntry(data:{
    name: 'Farmer',
    id : 'base:farmer',
    weaponAffinity: 'base:shovel',
    description : "Skilled individual who knows their way around the fields.", 
    growth: StatSet.new(
        HP:  12,
        AP:  4,
        ATK: 5,
        INT: 6,
        DEF: 11,
        SPD: 4,
        LUK: 12,
        DEX: 8
    ),
    minKarma : 100,
    learnable : true,
    maxKarma : 1000,
    levelMinimum : 1,

    arts : [
        'base:plant-poisonroot', //X grows at targets feet quickly. after 4 turns, continuous poison damage every turn
        'base:plant-triproot',   //X grows at targets feet quickly. after 4 turns, 50% chance trip every turn
        'base:plant-healroot',   //X grows at targets feet quickly. after 4 turns, 5% heal per turn
        'base:green-thumb',      //X farmer roots grow instantly
    ],
    passives : [
    ]
})

Profession.newEntry(data:{
    name: 'Alchemist',
    id : 'base:alchemist',
    weaponAffinity: 'base:dagger',
    description : "Skilled at brewing potions for all sorts of purposes.", 
    growth: StatSet.new(
        HP:  3,
        AP:  5,
        ATK: 2,
        INT: 6,
        DEF: 3,
        SPD: 5,
        LUK: 2,
        DEX: 2
    ),
    minKarma : 100,
    learnable : true,
    maxKarma : 1000,
    levelMinimum : 1,

    arts : [
        'base:pink-brew',     //X -3 ingredient pack, +1 pink potion 
        'base:cyan-brew',     //X -3 ingredient pack, +1 cyan ption 
        'base:green-brew',    //X etc (poison)
        'base:orange-brew',   //X etc (explosion)
        'base:purple-brew',   //X etc (health + ap)
        'base:black-brew',    //X petrify
    ],
    passives : [
        'base:alchemists-scavenging' // find 1 Ingredient Pack
    ]
})
/*
Profession.newEntry(data:{
    name: 'Cook',
    weaponAffinity: 'Butcher\'s Knife',
    description : "Skilled individual who can cook a mean meal.", 
    growth: StatSet.new(
        HP:  12,
        AP:  4,
        ATK: 8,
        INT: 10,
        DEF: 4,
        SPD: 11,
        LUK: 4,
        DEX: 11
    ),
    minKarma : 100,
    maxKarma : 1000,
    learnable : true,
    levelMinimum : 1,

    arts : [
        'Give Snack',  // X
        //'Rotten Food', // minor damage, poison chance 75%
        //'Flambe',      // fire damage, all enemies weak damage
    ],
    passives : [
        'Field Cook'
    ]
})
*/

Profession.newEntry(data:{
    name: 'Ranger',
    id : 'base:ranger',
    weaponAffinity: 'base:bow-and-quiver',
    description : "", 
    growth: StatSet.new(
        HP:  4,
        AP:  4,
        ATK: 6,
        INT: 6,
        DEF: 4,
        SPD: 8,
        LUK: 4,
        DEX: 12
    ),
    minKarma : 100,
    maxKarma : 1000,
    learnable : true,
    levelMinimum : 1,

    arts : [
        
        'base:precise-strike',// X dex-based attack 
        'base:tranquilizer',  // X Paralysis + DEX attack,
        'base:ensnare',       // X damages both user and target cannot use an action for one turn
        'base:call',          // X calls a creature to help (join team for single battle)
        'base:tame',          // X chance to convince creature to join party.
        'base:headhunter'     // X deals 1 HP. 5% chance to one-hit KO                    
    ],
    passives : [
    ]
})

/*
Profession.newEntry(data:{
    name: 'Blood Mage',
    weaponAffinity: 'Tome',
    description : "", 
    growth: StatSet.new(
        HP:  7,
        AP:  4,
        ATK: 4,
        INT: 6,
        DEF: 4,
        SPD: 6,
        LUK: 5,
        DEX: 4
    ),
    levelMinimum : 1,
    learnable : false,

    minKarma : 0,
    maxKarma : 50,
    
    arts : [
        
        'Curse',       // - 50% HP, -ATK 100% -DEF 50% one enemy 10 turns
        'Blood Rite',  // - 50% HP, HoT (+10% each turn)
        'Blind Faith', // - 50% HP, ATK + 200%
        'Soulbound',   // - 50% HP, any damage to this is caused to target
        'Wither',      // - 50% HP, DEF - 200%, SPD - 100%
        'Divine Gift', // - 50% HP, +25% AP target
        'Sacrifice',   // - 99% HP, heal party + 99% hp
        
    ],
    passives : [
    ]
}) 
*/

/*
Profession.newEntry(data:{
    name: 'Thief',
    weaponAffinity: 'Dagger',
    description : "Efficient, silent movements are this profession's assets.", 
    growth: StatSet.new(
        HP:  4,
        AP:  3,
        ATK: 4,
        INT: 3,
        DEF: 2,
        SPD: 8,
        LUK: 5,
        DEX: 9
    ),
    minKarma : 0,
    maxKarma : 50,
    levelMinimum : 1,
    learnable : true,

    arts : [
        
        'Steal',       // steal 
        'Lightfooted', // +50% speed for 5 turns  
        'Backstab',    // hi damage attack
        'Precise Strike', // DEX based attack
        'Conceal',   // dodge next attack
        'Reflexes', // %25 chance to avoid damage for 4 turns
        'Multistrike' // 2-5 hits single target
        
    ],
    passives : [
    ]
}) 
*/           



Profession.newEntry(data:{
    name: 'Assassin',
    id : 'base:assassin',
    weaponAffinity: 'base:dagger',                
    description : "Unparalleled in their ability to take down a target, this profession is respected for its abilities.", 
    growth: StatSet.new(
        HP:  2,
        AP:  5,
        ATK: 10,
        INT: 5,
        DEF: 3,
        SPD: 6,
        LUK: 4,
        DEX: 5
    ),
    levelMinimum : 1,
    learnable : true,

    minKarma : 0,
    maxKarma : 50,
    
    arts : [
        'base:poison-attack',  //X atk + poison
        'base:tripwire',       //X ONCE PER BATTLE: attack that pushes ppl into a tripwire you set up before battle (cant act for a turn)
        'base:trip-explosive', //X ONCE PER BATTLE: attach that push ppl into a trip explosive u set up before battle (enemy party damage)
        'base:petrify',        //X atk + petrify
        'base:headhunter',     //X
        'base:spike-pit'       //X Once per battle: all enemy fall in pit dmg + disable
    ],
    passives : [
        'base:assassins-pride', // Each kill in battle gives a 25% buff to attack and speed
    ]
})  



/*
Profession.newEntry(data:{
    name: 'Mercenary',
    weaponAffinity: 'Shortsword',                
    description : "", 
    growth: StatSet.new(
        HP:  6,
        AP:  3,
        ATK: 6,
        INT: 3,
        DEF: 6,
        SPD: 2,
        LUK: 2,
        DEX: 3
    ),
    levelMinimum : 1,
    learnable : true,

    minKarma : 0,
    maxKarma : 50,
    
    arts : [
    ],
    passives : [
    ]
}) 
*/
/*
Profession.newEntry(data:{
    name: 'Bounty Hunter',
    weaponAffinity: 'Shortsword',
    description : "", 
    growth: StatSet.new(
        HP:  6,
        AP:  3,
        ATK: 6,
        INT: 3,
        DEF: 6,
        SPD: 2,
        LUK: 2,
        DEX: 3
    ),
    levelMinimum : 1,

    learnable : true,
    minKarma : 0,
    maxKarma : 50,
    
    arts : [
    ],
    passives : [
    ]
}) 
*/
/*
Profession.newEntry(data:{
    name: 'Necromancer',
    weaponAffinity: 'Mage-rod',                
    description : "", 
    growth: StatSet.new(
        HP:  3,
        AP:  7,
        ATK: 3,
        INT: 7,
        DEF: 1,
        SPD: 4,
        LUK: 0,
        DEX: 3
    ),
    levelMinimum : 1,

    learnable : true,
    minKarma : 0,
    maxKarma : 50,
    
    arts : [
    ],
    passives : [
    ]
}) 
*/

/*
Profession.newEntry(data:{
    name: 'Pyromancer',
    weaponAffinity: 'Shortsword',                
    description : "", 
    growth: StatSet.new(
        HP:  5,
        AP:  8,
        ATK: 4,
        INT: 4,
        DEF: 2,
        SPD: 6,
        LUK: 4,
        DEX: 2
    ),
    levelMinimum : 1,

    minKarma : 0,
    maxKarma : 50,
    learnable : true,
    
    arts : [
    ],
    passives : [
    ]
})  
*/          
/*
Profession.newEntry(data:{
    name: 'Witch',
    weaponAffinity: 'Tome',                
    description : "", 
    growth: StatSet.new(
        HP:  3,
        AP:  7,
        ATK: 4,
        INT: 7,
        DEF: 2,
        SPD: 5,
        LUK: 3,
        DEX: 1
    ),
    levelMinimum : 1,

    learnable : true,
    minKarma : 0,
    maxKarma : 50,
    
    arts : [
    ],
    passives : [
    ]
})             
*/


Profession.newEntry(data:{
    name: 'Keeper',
    id : 'base:keeper',
    weaponAffinity: 'base:glaive',                
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  10,
        AP:  10,
        ATK: 10,
        INT: 10,
        DEF: 10,
        SPD: 10,
        LUK: 10,
        DEX: 10
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
    ],
    passives : [
    ]
})


Profession.newEntry(data:{
    name: 'Creature',
    id : 'base:creature',
    weaponAffinity: 'base:shortsword',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  7,
        AP:  7,
        ATK: 2,
        INT: 7,
        DEF: 7,
        SPD: 7,
        LUK: 10,
        DEX: 7
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:call',   // calls for backup, DQ style
    ],
    passives : [
    ]
})

Profession.newEntry(data:{
    name: 'Fire Sprite',
    id : 'base:fire-sprite',
    weaponAffinity: 'base:shortsword',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  7,
        AP:  7,
        ATK: 2,
        INT: 7,
        DEF: 7,
        SPD: 7,
        LUK: 10,
        DEX: 7
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:fire',   // calls for backup, DQ style
    ],
    passives : [
        'base:burning'
    ]
})

Profession.newEntry(data:{
    name: 'Ice Elemental',
    id : 'base:ice-elemental',
    weaponAffinity: 'base:shortsword',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  7,
        AP:  7,
        ATK: 2,
        INT: 7,
        DEF: 7,
        SPD: 7,
        LUK: 10,
        DEX: 7
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:ice',   // calls for backup, DQ style
        'base:frozen-flame'
    ],
    passives : [
        'base:icy'
    ]
})            

Profession.newEntry(data:{
    name: 'Thunder Spawn',
    id : 'base:thunder-spawn',
    weaponAffinity: 'base:shortsword',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  7,
        AP:  7,
        ATK: 2,
        INT: 7,
        DEF: 7,
        SPD: 7,
        LUK: 10,
        DEX: 7
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:thunder',
        'base:triplestrike',
        'base:ensnare'
    ],
    passives : [
        'base:shock'
    ]
})

Profession.newEntry(data:{
    name: 'Guiding Light',
    id : 'base:guiding-light',
    weaponAffinity: 'base:shortsword',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  7,
        AP:  7,
        ATK: 2,
        INT: 7,
        DEF: 7,
        SPD: 7,
        LUK: 10,
        DEX: 7
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:cure',
        'base:cure-all',
        'base:protect',
        'base:explosion'
    ],
    passives : [
        'base:shimmering'
    ]
})            



Profession.newEntry(data:{
    name: 'Wyvern Specter',
    id : 'base:wyvern-specter',
    weaponAffinity: 'base:none',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  20,
        AP:  20,
        ATK: 20,
        INT: 20,
        DEF: 20,
        SPD: 20,
        LUK: 20,
        DEX: 20
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:headhunter',
        'base:cure',
        //'Magic Mist', // remove all effects
        'base:triplestrike',
        'base:leg-sweep',
        'base:flash',
        'base:unarm'
    ],
    passives : [
    ]
}) 

Profession.newEntry(data:{
    name: 'Beast',
    id: 'base:beast',
    weaponAffinity: 'base:none',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  20,
        AP:  20,
        ATK: 20,
        INT: 20,
        DEF: 20,
        SPD: 20,
        LUK: 20,
        DEX: 20
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:headhunter',
        //'Magic Mist', // remove all effects
        'base:wild-swing',
        'base:triplestrike',
        'base:leg-sweep',
        'base:unarm',
        'base:doublestrike'
    ],
    passives : [
    ]
}) 

Profession.newEntry(data:{
    name: 'Wyvern',
    id: 'base:wyvern',
    weaponAffinity: 'base:none',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  20,
        AP:  20,
        ATK: 20,
        INT: 20,
        DEF: 20,
        SPD: 20,
        LUK: 20,
        DEX: 20
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:headhunter',
        //'Magic Mist', // remove all effects
        'base:wild-swing',
        'base:triplestrike',
        'base:leg-sweep',
        'base:unarm',
        'base:doublestrike',
        'base:cancel',
        'base:cancel',
        'base:retaliate'
    ],
    passives : [
    ]
}) 

Profession.newEntry(data:{
    name: 'Snake Siren',
    id : 'base:snake-siren',
    weaponAffinity: 'base:none',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  20,
        AP:  20,
        ATK: 20,
        INT: 20,
        DEF: 20,
        SPD: 20,
        LUK: 20,
        DEX: 20
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:sweet-song',
        'base:poison-attack',
        'base:petrify',
        'base:wrap',
    ],
    passives : [
    ]
}) 


Profession.newEntry(data:{
    name: 'Treasure Golem',
    id : 'base:treasure-golem',
    weaponAffinity: 'base:none',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  20,
        AP:  20,
        ATK: 20,
        INT: 20,
        DEF: 20,
        SPD: 20,
        LUK: 20,
        DEX: 20
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:headhunter',
        //'Magic Mist', // remove all effects
        'base:wild-swing',
        'base:leg-sweep',
        'base:doublestrike'
    ],
    passives : [
    ]
}) 


Profession.newEntry(data:{
    name: 'Cave Bat',
    id : 'base:cave-bat',
    weaponAffinity: 'base:none',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  7,
        AP:  7,
        ATK: 6,
        INT: 7,
        DEF: 7,
        SPD: 7,
        LUK: 10,
        DEX: 3
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:headhunter',
        //'Magic Mist', // remove all effects
        'base:triplestrike',
        'base:doublestrike',
        'base:poison-attack',
        'base:petrify'
    ],
    passives : [
    ]
}) 



Profession.newEntry(data:{
    name: 'Spirit',
    id : 'base:spirit',
    weaponAffinity: 'base:none',
    description : "", 
    levelMinimum : 100,

    growth: StatSet.new(
        HP:  7,
        AP:  7,
        ATK: 6,
        INT: 1,
        DEF: 7,
        SPD: 7,
        LUK: 10,
        DEX: 3
    ),
    minKarma : 0,
    maxKarma : 50,
    learnable : false,
    
    arts : [
        'base:doublestrike',
        'base:attack',
        'base:attack',
        'base:attack',
        'base:attack'
    ],
    passives : [
    ]
}) 
}

@:Profession = Database.new(
    name : 'Wyvern.Profession.Base',   
    attributes : {
        name : String,
        id : String,
        description : String,
        growth : StatSet.type,
        minKarma : Number,
        maxKarma : Number,
        arts : Object,
        levelMinimum : Number,
        passives : Object,
        learnable : Boolean,
        weaponAffinity : String
    },
    reset           
);



return Profession;
