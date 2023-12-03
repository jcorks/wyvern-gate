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
@:Island = import(module:'game_class.island.mt');
@:Party = import(module:'game_class.party.mt');
@:Battle = import(module:'game_class.battle.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');
@:TIME = {
    DAWN : 0,
    EARLY_MORNING : 1,
    MORNING : 2,
    LATE_MORNING: 3,
    MIDDAY: 4,
    AFTERNOON: 5,
    LATE_AFTERNOON: 6,
    SUNSET: 7,
    EARLY_EVENING: 8,
    EVENING: 9,
    LATE_EVENING: 10,
    MIDNIGHT: 11,
    DEAD_HOUR: 12,
    DEAD_NIGHT: 13
}

@:SEASON = {
    SPRING : 0,
    SUMMER : 1,
    AUTUMN : 2,
    WINTER : 3
}


@:World = LoadableClass.new(
    name: 'Wyvern.World',
    
    // not used due to singleton nature.
    new ::(parent, state) {
        @:this = World.defaultNew();
        
        if (state != empty)
            this.load(serialized:state);
            
        return this;
    },
    define:::(this) {

        @battle = Battle.new();
        @island = empty;
        @loadableIslands = [];
    
        @:findIsland ::{
            {:::}{
                foreach(loadableIslands) ::(k, is) {
                    if (is.worldID == state.islandID) ::<= {
                        island = is;
                        send();
                    }                
                }
                
                error(detail: 'Internal error: Could not find loadable island.');
            }
        }
    
        @:state = State.new(
            items : {
                // 5 turns per "time"
                // 14 times per "day"
                // 100 days per "year"
                turn : 0,
                time : TIME.LATE_MORNING,
                day : (Number.random()*100)->floor,
                year : 1033,
                party : Party.new(),
                islandID : empty,
                orphanedIsland : empty, // IN THE CASE that a user has tossed or otherwise 
                                        // lost the key to the island they are residing in 
                                        // the island becomes orphaned. The world becomes 
                                        // the sole owner of the island.
                idPool : 0,
                story : import(module:'game_singleton.story.mt'),
                npcs : empty,
                modData : {}
            }
        );

        
        @:getDayString = ::{
            return match(state.time) {
              (TIME.DAWN): 'It is dawn.',
              (TIME.EARLY_MORNING): 'It is early morning.',
              (TIME.MORNING): 'It is mid-morning.',
              (TIME.LATE_MORNING): 'It is late in the morning.',
              (TIME.MIDDAY): 'It is midday.',
              (TIME.AFTERNOON): 'It is the afternoon.',
              (TIME.LATE_AFTERNOON): 'It is late in the afternoon.',
              (TIME.SUNSET): 'The sun is setting.',
              (TIME.EARLY_EVENING): 'It is starting to get dark out.',
              (TIME.EVENING): 'It is night out.',
              (TIME.LATE_EVENING): 'It is late night.',
              (TIME.MIDNIGHT): 'It is midnight.',
              (TIME.DEAD_HOUR): 'It is the dead hour.',
              (TIME.DEAD_NIGHT): 'It is the dead of the night.'
            }
        }
        
        @:getSeasonString = ::{
            return match(this.season) {
              (SEASON.SPRING): 'Spring',           
              (SEASON.SUMMER): 'Summer',           
              (SEASON.AUTUMN): 'Autumn',           
              (SEASON.WINTER): 'Winter'         
           }
        }
        
        
        this.interface = {
            TIME : {
                get ::<- TIME
            },
            SEASON : {
                get ::<- SEASON
            },
        
            timeString : {
                get :: {
                    return 'Year ' + state.year +', ' + getSeasonString() + '. ' + getDayString();
                }
            },
            
            
            
            discoverIsland ::(levelHint => Number, tierHint => Number, nameHint) {
                @:out = Island.new(parent:this, levelHint, nameHint, tierHint);
                return out;
            },
            
            time : {
                get ::<- state.time
            },
            
            season : {
                get :: {
                    return match(true) {
                      (state.day > 75): SEASON.WINTER,
                      (state.day > 50): SEASON.AUTUMN,
                      (state.day > 25): SEASON.SUMMER,
                      default: SEASON.SPRING
                    }
                }
            },

            
            party : {
                get ::<- state.party
            },
            
            island : {
                get :: <- island,
                set ::(value) {
                    state.islandID = value.worldID;
                    island = value;
                }
            },

            
            getNextID ::{
                state.idPool += 1;
                return state.idPool-1;
            },
            
            battle : {
                get :: <- battle
            },
            
            storyFlags : {
                get :: <- state.story
            },
            
            npcs : {
                get ::<- state.npcs
            },
            
            stepTime :: {
                state.turn += 1;
                if (state.turn > 10) ::<={
                    state.turn = 0;
                    state.time += 1;
                }
                    
                if (state.time > 13) ::<={
                    state.time = 0;
                    state.day += 1;
                }
                
                if (state.day > 99) ::<={
                    state.day = 0;
                    state.year += 1;
                }                
                
            },
            
            
            // intialize NPCs if they havent been already
            initializeNPCs ::{
                // already loaded from file.
                if (state.npcs != empty) empty;
                
                @:Entity = import(module:'game_class.entity.mt');
                @:EntityQuality = import(module:'game_class.entityquality.mt');
                @:Item = import(module:'game_class.item.mt');
                @:story = import(module:'game_singleton.story.mt');
                
                state.npcs = {
                    faus : ::<= {
                        @:ent = Entity.new(
                            speciesHint: 'Rabbit',
                            professionHint: 'Summoner',
                            personalityHint: 'Caring',
                            levelHint: 5,
                            adventurousHint: true,
                            qualities : [
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'snout'), trait0Hint:0),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'fur'),   descriptionHint: 6, trait0Hint:10, trait2Hint:3),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'eyes'),  descriptionHint: 3, trait2Hint:6, trait1Hint: 0),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'ears'),  descriptionHint: 1, trait0Hint:2),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'face'),  descriptionHint: 0, trait0Hint:3),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'tail'),  descriptionHint: 0, trait0Hint:0),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'body'),  descriptionHint: 1, trait0Hint:0, trait1Hint:0),            
                            ]
                        );



                        @:fausWeapon = Item.new(
                            base: Item.Base.database.find(name: 'Morning Star'),
                            rngEnchantHint: false,
                            qualityHint: 'Masterwork',
                            materialHint: 'Mythril',
                            colorHint: 'gold',
                            enchantHint: 'Aura: Gold',
                            forceEnchant: true
                        );
                        fausWeapon.maxOut();
                        
                        @:fausRobe = Item.new(
                            base: Item.Base.database.find(name: 'Robe'),
                            rngEnchantHint: false,
                            qualityHint: 'Masterwork',
                            colorHint: 'black',
                            apparelHint: 'Mythril',
                            forceEnchant: true,
                            enchantHint: 'Inlet: Opal'            
                        );
                        fausRobe.maxOut();


                        @:fausCloak = Item.new(
                            base: Item.Base.database.find(name: 'Cloak'),
                            rngEnchantHint: false,
                            qualityHint: 'Masterwork',
                            colorHint: 'olive-green',
                            apparelHint: 'Mythril',
                            forceEnchant: true
                        );
                        fausCloak.maxOut();


                        
                        
                        ent.equip(item:fausWeapon, slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
                        ent.equip(item:fausCloak,  slot:Entity.EQUIP_SLOTS.TRINKET, silent:true);
                        ent.equip(item:fausRobe,   slot:Entity.EQUIP_SLOTS.ARMOR, silent:true);

                        ent.heal(
                            amount: 9999,
                            silent: true
                        );

                        @:learned = ent.profession.gainSP(amount:20);
                        foreach(learned)::(index, ability) {
                            ent.learnAbility(name:ability);
                        }                                                



                        ent.name = 'Faus';                    
                        return ent;
                    },
                
                
                    sylvia : ::<= {
                        @:ent = Entity.new(
                            speciesHint: 'Kobold',
                            professionHint: 'Alchemist',
                            personalityHint: 'Inquisitive',
                            levelHint: story.levelHint-1,
                            adventurousHint: true
                        );

                        @:learned = ent.profession.gainSP(amount:20);
                        foreach(learned)::(index, ability) {
                            ent.learnAbility(name:ability);
                        }                                                

                        ent.name = 'Sylvia';
                        return ent;                    
                    },
                    mei : ::<= {
                        @:ent = Entity.new(
                            speciesHint: 'Sheep',
                            professionHint: 'Cleric',
                            personalityHint: 'Caring',
                            levelHint: story.levelHint-1,
                            adventurousHint: true,
                            qualities : [
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'snout'), trait0Hint:2),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'fur'),   descriptionHint: 0, trait0Hint:8),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'eyes'),  descriptionHint: 0, trait2Hint:0, trait1Hint: 0),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'ears'),  descriptionHint: 2, trait0Hint:2),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'face'),  descriptionHint: 0, trait0Hint:0),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'tail'),  descriptionHint: 0, trait0Hint:0),
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'body'),  descriptionHint: 1, trait0Hint:0, trait1Hint:5),            
                                EntityQuality.new(base: EntityQuality.Base.database.find(name: 'horns'), descriptionHint: 1, trait0Hint:2, trait1Hint:1)
                            ]
                        );



                        @:meiWeapon = Item.new(
                            base: Item.Base.database.find(name: 'Falchion'),
                            rngEnchantHint: true,
                            qualityHint: 'Quality',
                            materialHint: 'Dragonglass',
                            colorHint: 'pink',
                            forceEnchant: true
                        );
                        meiWeapon.maxOut();
                        
                        @:meiRobe = Item.new(
                            base: Item.Base.database.find(name: 'Robe'),
                            rngEnchantHint: true,
                            qualityHint: 'Masterwork',
                            colorHint: 'pink',
                            apparelHint: 'Wool+',
                            forceEnchant: true
                        );
                        meiRobe.maxOut();
                        
                        @:meiAcc = Item.new(
                            base: Item.Base.database.find(name: 'Mei\'s Bow'),
                            rngEnchantHint: true,
                            forceEnchant: true
                        );
                        
                        ent.equip(item:meiWeapon, slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
                        ent.equip(item:meiRobe,   slot:Entity.EQUIP_SLOTS.ARMOR, silent:true);
                        ent.equip(item:meiAcc,    slot:Entity.EQUIP_SLOTS.TRINKET, silent:true);

                        ent.heal(
                            amount: 9999,
                            silent: true
                        );

                        @:learned = ent.profession.gainSP(amount:20);
                        foreach(learned)::(index, ability) {
                            ent.learnAbility(name:ability);
                        }                                                

                        ent.name = 'Mei';
                        return ent;
                    }     
                }       
            },
            
            modData : {
                get ::<- state.modData
            },
            
            save ::{
                State.startRootSerializeGuard();

                loadableIslands = [];
                @:out = state.save()

                // check to see if we have an orphaned island
                @hasIsland = false;
                {:::} {
                    foreach(loadableIslands) ::(k, is) {
                        if (state.islandID == is.worldID) ::<= {
                            hasIsland = true;
                            send();
                        }
                    }
                }
                
                @:output = if (hasIsland == false) ::<= {
                    state.orphanedIsland = island.save();
                    State.endRootSerializeGuard();
                    State.startRootSerializeGuard();
                    return state.save(); // TODO: is there a faster way that isnt messy?
                } else out;
                
                
                State.endRootSerializeGuard();
                
                loadableIslands = [];                
                return output;                
            },

            // for initial loading from state.
            addLoadableIsland ::(island) {
                loadableIslands->push(value:island);
            },
            
            load ::(serialized) {
                loadableIslands = [];
                state.load(parent:this, serialized);
                // overwrite singleton with saved instance
                @:st = state.story;
                state.story = import(module:'game_singleton.story.mt');
                state.story.load(serialized:st.save());
                findIsland();                
                loadableIslands = [];
                state.orphanedIsland = empty;
            }
            
        }
    }
);

return World.new();
