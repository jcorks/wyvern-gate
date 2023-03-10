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


@: nextSPLevel ::(spLevel) {
    return 1;
    //return (((spLevel+1)*0.75 * 10) + (spLevel+1) * 5)->ceil;
};

@:Profession = class(
    statics : {
        Base : empty
    },
    name : 'Wyvern.Profession.Instance',
    define :::(this) {
        @base_;
        @sp = 0;
        @spNext = 1;
        @spLevel = 0;
        this.constructor = ::(base, state){
            when(state != empty) ::<= {
                this.state = state;
                return this;
            };
            base_ = base;
            return this;
        };
        
        this.interface = {
            state : {   
                set ::(value) {
                    sp = value.sp;
                    spNext = value.spNext;
                    base_ = Profession.Base.database.find(name:value.baseName);
                    spLevel = value.spLevel;
                },
                get :: {
                    return {
                        baseName : base_.name,
                        sp : sp,
                        spNext : spNext,
                        spLevel : spLevel,
                    };
                }
            },
            base : {
                get ::{
                    return base_;
                }
            },
            
            sp : {
                get :: {
                    return sp;
                }
            },
            
            // returns any learned abilities();
            gainSP ::(amount) {
                spNext -= amount;
                @learned = [];
                [::] {
                    forever(do:::{
                        when(spNext > 0) send();
                        @:next = base_.abilities[spLevel];

                        spNext += nextSPLevel(spLevel);
                        spLevel+=1;
                        when(next == empty) empty; 
                        learned->push(value:next);
                    
                    });
                };
                
                return learned;
            }
        };
    }
);

Profession.Base = class(
    name : 'Wyvern.Profession',   
    statics : {
        database : empty
       
    }, 
    define:::(this) {
        Database.setup(
            item : this,
            attributes : {
                name : String,
                description : String,
                growth : StatSet.type,
                minKarma : Number,
                maxKarma : Number,
                abilities : Object,
                levelMinimum : Number,
                passives : Object,
                learnable : Boolean,
                weaponAffinity : String
            }
        );


        this.interface = {
            new ::(state){
                return Profession.new(base:this, state);
            }
        };

        
    }
);



/*

    Each profession:
        - 32 pts base 
        - 8 skills
        
    + 8 pts for each missing skill
    - 1 skill for passive


*/

Profession.Base.database = Database.new(
    items: 
        [
            Profession.Base.new(data:{
                name: 'Adventurer',
                description : 'General, well-rounded profession. Learns abilities on-the-fly to stay alive.', 
                weaponAffinity : 'Shortsword',
                growth: StatSet.new(
                    HP:  4,
                    MP:  4,
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
                abilities : [
                    'First Aid',
                    'Swipe Kick',
                    'Doublestrike',     // 2 hits RNG targets, 80% of attack
                    'Focus Perception', // + 25% ATK for 5 turns 
                    'Cheer',            // + 30% ATK for whole party 5 turns
                    'Follow Up',        // if hurt this turn, does +150% damage, else is attack strength
                    'Grapple',          // No action for user or target for 3 turns
                    'Triplestrike',     // 3 hits RNG targets, 70% power
                ],
                
                passives : []
            }),
            
            Profession.Base.new(data:{
                name: 'Martial Artist',
                weaponAffinity: 'Staff',
                description : 'A fighter that uses various stances to bend to the flow of battle.', 
                growth: StatSet.new(
                    HP:  6,
                    MP:  2,
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
                abilities : [
                    // only one stance at a time
                    'Defensive Stance',  // +%75 Def -50% Atk
                    'Offensive Stance',  // +%75 Atk -50% Def
                    'Light Stance',      // +75% Speed -50% Atk
                    'Heavy Stance',      // +75% Def -50% Spd 
                    'Meditative Stance', // +75% INT -50% Spd
                    'Striking Stance',   // +100% ATK, -30%Def,Spd
                    'Reflective Stance', // if hit, retaliates
                    'Evasive Stance',    // 50% chance evade
                    
                ],
                
                passives : []            
            
            }),

            Profession.Base.new(data:{
                name: 'Field Mage',
                description : 'A self-taught mage. Knows a variety of magicks.', 
                weaponAffinity: 'Wand',
                growth: StatSet.new(
                    HP:  3,
                    MP:  7,
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
                
                abilities : [
                    'Fire',
                    'Ice',      // all enemies
                    'Meditate', // MP recover, self
                    'Thunder',  // 4 random strikes
                    'Mind Focus', // +100% INT for 10 turns
                    'Flash',    // all enemies, 50% chance cant act for a turn
                    'Flare',    // one enemy, big damage
                    'Explosion', // all enemies, fire big damage
                ],
                
                passives : []
            }),


            Profession.Base.new(data:{
                name: 'Cleric',
                description : 'A self-taught healing mage. Knows a variety of magicks.', 
                weaponAffinity: 'Mage-rod',
                growth: StatSet.new(
                    HP:  5,
                    MP:  6,
                    ATK: 4,
                    INT: 6,
                    DEF: 2,
                    SPD: 4,
                    LUK: 3,
                    DEX: 2
                ),
                minKarma : 100,
                maxKarma : 1000,
                learnable : true,
                levelMinimum : 1,
                
                abilities : [
                    'Cure',
                    'Antidote', // specifically cures poison
                    'Protect',
                    'Greater Cure',
                    'Protect All',
                    'Soothe', // mp recovery, any
                    'Cleanse', // removal of standard status ailments
                    'Grace', // save from death, once    
                ],
                
                passives : []
            }),

            Profession.Base.new(data:{
                name: 'Divine Lunist',
                weaponAffinity: 'Tome',
                description : 'Blessed by the moon, their magicks are entwined with the night.', 
                growth: StatSet.new(
                    HP:  3,
                    MP:  8,
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
                
                abilities : [
                    'Lunar Blessing',   // make it night time
                    'Moonbeam',         // attack enhanced by night time
                    'Night Veil',       // +100% Def if in night time
                    'Moonsong',         // HoT if in night time
                    'Call of the Night',// +60% ATK if in night time
                    'Lunacy',           // Berserk: attacks random enemy instead of turn, +70% ATK and +70% DEF. only usable at night
                ],
                passives : [
                    'Lunar Affinity'
                ]
            }),

            Profession.Base.new(data:{
                name: 'Divine Solist',
                weaponAffinity: 'Tome',
                description : 'Blessed by the sun, their magicks are entwined with daylight.', 
                growth: StatSet.new(
                    HP:  3,
                    MP:  8,
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
                
                abilities : [
                    'Solar Blessing', // make it day time
                    'Sunbeam',        // attack enhanced by day 
                    'Dayshroud',      // +100% Def if in day time     
                    'Sol Attunement', // +5% health every turn
                    'Sunburst',       // attack enhanced by day 
                    'Phoenix Soul'    // autorevive once
                ],
                passives : [
                    'Solar Affinity'
                ]
            }),


            Profession.Base.new(data:{
                name: 'Blacksmith',
                weaponAffinity: 'Hammer',
                description : 'Skilled with metalworking, their skills are revered.', 
                growth: StatSet.new(
                    HP:  14,
                    MP:  3,
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
                
                abilities : [
                    'Sharpen',
                    'Weaken Armor',
                    'Strengthen Armor',
                    'Dull Weapon'
                ],
                passives : [
                ]
            }),
            
            Profession.Base.new(data:{
                name: 'Trader',
                weaponAffinity: 'Dagger',
                description : 'A silver tongue and a quick hand make this profession both lauded and loathed.', 
                growth: StatSet.new(
                    HP:  4,
                    MP:  12,
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

                abilities : [
                    'Convince',
                    'Bribe',
                    'Quickhand', // do 2 item actions, same target
                ],
                passives : [
                    'Penny Picker' // after battle may notice dropped G
                ]
            }),

            Profession.Base.new(data:{
                name: 'Warrior',
                weaponAffinity: 'Greatsword',
                description : "Excelling in raw strength and technique, users of this profession are fearsome.", 
                growth: StatSet.new(
                    HP:  9,
                    MP:  1,
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
                
                abilities : [
                    'Tackle',
                    'Stun',
                    'Big Swing',
                    'Leg Sweep',
                    'Stab', // bleeding effect
                    'Wild Swing',
                    'Duel', // pick enemy. if attacking, +150% damage
                ],
                passives : [
                ]
            }), 

            Profession.Base.new(data:{
                name: 'Guard',
                weaponAffinity: 'Polearm',
                description : "Standard profession excelling in defending others, for better or for worse.", 
                growth: StatSet.new(
                    HP:  6,
                    MP:  1,
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

                abilities : [
                    'Guard',   // defend 2.0
                    'Proceed with Caution', // defense buff for team
                    'Mend',    // heal other, no MP cost!!!! but weak
                    'Defend Other',
                    'Retaliate',    // auto-attack if hit
                    'Tandem', // stat boost for every other in party with same profession 
                    'Avenge', // after use, if any teammates are hit, K'Od, or killed, boost to ATK and DEF
                ],
                passives : [
                    'Trained Hand', // +30% attack
                ]
            }), 


            Profession.Base.new(data:{
                name: 'Arcanist',
                weaponAffinity: 'Tome',
                description : "A scholar first, their large knowledge of the arcane yields interesting magicks for any situation.", 
                growth: StatSet.new(
                    HP:  3,
                    MP:  14,
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
                
                abilities : [
                    'Telekinesis',  // stun for a turn
                    'Materialize',  // summon temporary equipment
                    'Dematerialize',
                    'Mind read', // use random ability of target
                    'Flight', // make target fly?
                    
                ],
                passives : [
                ]
            }), 

            Profession.Base.new(data:{
                name: 'Runologist',
                weaponAffinity: 'Tome',                
                description : "An arcanist scholar who focuses on runes.", 
                growth: StatSet.new(
                    HP:  3,
                    MP:  13,
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
                
                // runes fade after 5 turns
                abilities : [
                    'Poison Rune', // weak DoT until released
                    'Rune Release', // releases all runes on target
                    'Destruction Rune', // damage when released.
                    'Regeneration Rune', // HoT until released
                    'Cure Rune', // heal when released
                    'Shield Rune', // DEF + 100% until released
                    'Multiply Rune' // ddoubles targets Rune charges
                ],
                passives : [
                ]
            }), 


            Profession.Base.new(data:{
                name: 'Elementalist',
                weaponAffinity: 'Shortsword',                
                description : "Capable of infusing magicks into normal objects for combat.", 
                growth: StatSet.new(
                    HP:  5,
                    MP:  6,
                    ATK: 6,
                    INT: 6,
                    DEF: 4,
                    SPD: 5,
                    LUK: 3,
                    DEX: 4
                ),
                levelMinimum : 1,

                minKarma : 0,
                maxKarma : 1000,
                learnable : true,
                
                abilities : [
                    'Fire Shift', // shifts current ele,emt
                    'Elemental Attack', // 50% better than normal attack, elemental damage
                    'Ice Shift', // shifts current ele,emt
                    'Elemental Shield', // no damage if taking hit from current element.
                    'Thunder Shift', // shifts current ele,emt
                    'Elemental Tag', // Take +100% damage from element type
                    'Tri Attack' // 3 hits, one of each type of damage
                ],
                passives : [
                ]
            }),
            

            Profession.Base.new(data:{
                name: 'Farmer',
                weaponAffinity: 'Shovel',
                description : "Skilled individual who knows their way around the fields.", 
                growth: StatSet.new(
                    HP:  12,
                    MP:  4,
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

                abilities : [
                    'Poisonroot', // grows at targets feet quickly. after 4 turns, 50% poison damage
                    'Triproot',   // grows at targets feet quickly. after 4 turns, 50% chance trip
                    'Healroot',   // grows at targets feet quickly. after 4 turns, 5% heal per turn
                    'Green Thumb',  // farmer roots grow instantly
                ],
                passives : [
                ]
            }),

            Profession.Base.new(data:{
                name: 'Alchemist',
                weaponAffinity: 'Dagger',
                description : "Skilled at brewing potions for all sorts of purposes.", 
                growth: StatSet.new(
                    HP:  3,
                    MP:  5,
                    ATK: 2,
                    INT: 4,
                    DEF: 3,
                    SPD: 3,
                    LUK: 2,
                    DEX: 2
                ),
                minKarma : 100,
                learnable : true,
                maxKarma : 1000,
                levelMinimum : 1,

                abilities : [
                    'Pink Brew',     // -1 ingredient pack, +1 pink potion 
                    'Cyan Brew',     // -1 ingredient pack, +1 cyan ption 
                    'Green Brew',    // etc (poison)
                    'Orange Brew',   // etc (explosion)
                    'Purple Brew',   // etc (health + mp)
                    'Grey Brew',     // petrify
                    'Purple Elixir', // heal + mp for party 
                ],
                passives : [
                    'Alchemist\'s Scavenging' // find 2-5 Ingredient Packs
                ]
            }),

            Profession.Base.new(data:{
                name: 'Cook',
                weaponAffinity: 'Butcher\'s Knife',
                description : "Skilled individual who can cook a mean meal.", 
                growth: StatSet.new(
                    HP:  12,
                    MP:  4,
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

                abilities : [
                    'Give Snack',
                    'Rotten Food', // minor damage, poison chance 75%
                    'Flambe', // fire damage, all enemies weak damage
                ],
                passives : [
                    'Field Cook'
                ]
            }),


            Profession.Base.new(data:{
                name: 'Ranger',
                weaponAffinity: 'Bow & Quiver',
                description : "", 
                growth: StatSet.new(
                    HP:  4,
                    MP:  4,
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

                abilities : [
                    'Sharpshoot', // dex-based attack 
                    'Tranquilizer', // Paralysis + DEX attack,
                    'Hunter', // +100% damage to Creatures
                    'Ensnare', // both user and target cannot use an action for one turn
                    'Call', // calls a creature to help (join team for single battle)
                    'Tame', // chance to convince creature to join party.
                ],
                passives : [
                ]
            }),

            Profession.Base.new(data:{
                name: 'Cultist',
                weaponAffinity: 'Dagger',
                description : "", 
                growth: StatSet.new(
                    HP:  7,
                    MP:  4,
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
                
                abilities : [
                    'Curse',       // - 50% HP, -ATK 100% one enemy 10 turns
                    'Blood Rite',  // - 50% HP, HoT (+5% each turn)
                    'Blind Faith', // - 50% HP, ATK + 100%
                    'Soulbound',   // - 50% HP, any damage to self is caused to target
                    'Wither',      // - 50% HP, DEF - 100%, SPD - 100%
                    'Divine Gift', // - 50% HP, +25% MP target
                    'Sacrifice',   // - 99% HP, heal party + 75% hp
                ],
                passives : [
                ]
            }), 


            Profession.Base.new(data:{
                name: 'Thief',
                weaponAffinity: 'Dagger',
                description : "Efficient, silent movements are this profession's assets.", 
                growth: StatSet.new(
                    HP:  4,
                    MP:  3,
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

                abilities : [
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
            }),            



            Profession.Base.new(data:{
                name: 'Assassin',
                weaponAffinity: 'Dagger',                
                description : "Unparalleled in their ability to take down a target, this profession is respected for its abilities.", 
                growth: StatSet.new(
                    HP:  2,
                    MP:  5,
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
                
                abilities : [
                    'Poison Attack',  //atk + poison
                    'Tripwire',       //ONCE PER BATTLE: attack that pushes ppl into a tripwire you set up before battle (cant act for a turn)
                    'Trip Explosive', //ONCE PER BATTLE: attach that push ppl into a trip explosive u set up before battle (enemy party damage)
                    'Petrify',        //atk + petrify
                    'Dire Precision', // if damage from this user were to knock out a character, it kills them instead
                    'Spike Pit'       //Once per battle: all enemy fall in pit dmg + disable
                ],
                passives : [
                    'Assassin\'s Pride', // Each kill in battle gives a 25% buff to attack and speed
                ]
            }),  


            Profession.Base.new(data:{
                name: 'Outlaw',
                weaponAffinity: 'Shortsword',                
                description : "", 
                growth: StatSet.new(
                    HP:  5,
                    MP:  3,
                    ATK: 6,
                    INT: 5,
                    DEF: 2,
                    SPD: 4,
                    LUK: 8,
                    DEX: 4
                ),
                levelMinimum : 1,
                minKarma : 0,
                learnable : false,
                maxKarma : 50,
                
                abilities : [
                ],
                passives : [
                ]
            }), 

            Profession.Base.new(data:{
                name: 'Mercenary',
                weaponAffinity: 'Shortsword',                
                description : "", 
                growth: StatSet.new(
                    HP:  6,
                    MP:  3,
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
                
                abilities : [
                ],
                passives : [
                ]
            }), 

            Profession.Base.new(data:{
                name: 'Bounty Hunter',
                weaponAffinity: 'Shortsword',
                description : "", 
                growth: StatSet.new(
                    HP:  6,
                    MP:  3,
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
                
                abilities : [
                ],
                passives : [
                ]
            }), 

            Profession.Base.new(data:{
                name: 'Necromancer',
                weaponAffinity: 'Mage-rod',                
                description : "", 
                growth: StatSet.new(
                    HP:  3,
                    MP:  7,
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
                
                abilities : [
                ],
                passives : [
                ]
            }), 
            
            Profession.Base.new(data:{
                name: 'Pyromancer',
                weaponAffinity: 'Shortsword',                
                description : "", 
                growth: StatSet.new(
                    HP:  5,
                    MP:  8,
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
                
                abilities : [
                ],
                passives : [
                ]
            }),            
            
            Profession.Base.new(data:{
                name: 'Witch',
                weaponAffinity: 'Tome',                
                description : "", 
                growth: StatSet.new(
                    HP:  3,
                    MP:  7,
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
                
                abilities : [
                ],
                passives : [
                ]
            }),             
            
            Profession.Base.new(data:{
                name: 'Highwayman',
                weaponAffinity: 'Shortsword',                
                description : "Excelling in their forward manner, highwaymen are a feared profession", 
                growth: StatSet.new(
                    HP:  5,
                    MP:  2,
                    ATK: 5,
                    INT: 5,
                    DEF: 3,
                    SPD: 6,
                    LUK: 10,
                    DEX: 3
                ),
                levelMinimum : 1,
                learnable : false,

                minKarma : 0,
                maxKarma : 50,
                
                abilities : [
                    'Mug',   // attack and steal gold 
                    'Unarm', // attack + 50% chance to unarm
                    //'Swipe', // trip enemy, skipping their turn
                ],
                passives : [
                ]
            }),
            
            Profession.Base.new(data:{
                name: 'Disciple',
                weaponAffinity: 'Glaive',                
                description : "", 
                levelMinimum : 100,

                growth: StatSet.new(
                    HP:  7,
                    MP:  7,
                    ATK: 7,
                    INT: 7,
                    DEF: 7,
                    SPD: 7,
                    LUK: 10,
                    DEX: 7
                ),
                minKarma : 0,
                maxKarma : 50,
                learnable : false,
                
                abilities : [
                    'Mug',   // attack and steal gold 
                    'Unarm', // attack + 50% chance to unarm
                    'Swipe', // trip enemy, skipping their turn
                ],
                passives : [
                ]
            }),

            Profession.Base.new(data:{
                name: 'Keeper',
                weaponAffinity: 'Glaive',                
                description : "", 
                levelMinimum : 100,

                growth: StatSet.new(
                    HP:  10,
                    MP:  10,
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
                
                abilities : [
                    'Mug',   // attack and steal gold 
                    'Unarm', // attack + 50% chance to unarm
                    'Swipe', // trip enemy, skipping their turn
                ],
                passives : [
                ]
            }),
            
            
            Profession.Base.new(data:{
                name: 'Creature',
                weaponAffinity: 'None',
                description : "", 
                levelMinimum : 100,

                growth: StatSet.new(
                    HP:  7,
                    MP:  7,
                    ATK: 7,
                    INT: 7,
                    DEF: 7,
                    SPD: 7,
                    LUK: 10,
                    DEX: 7
                ),
                minKarma : 0,
                maxKarma : 50,
                learnable : false,
                
                abilities : [
                    'Call',   // calls for backup, DQ style
                ],
                passives : [
                ]
            })
            
            
        ]
    
);

return Profession;
