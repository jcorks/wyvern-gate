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
};

@:SEASON = {
    SPRING : 0,
    SUMMER : 1,
    AUTUMN : 2,
    WINTER : 3
};


return class(
    name: 'Wyvern.World',
    define:::(this) {
    
        // 5 turns per "time"
        // 14 times per "day"
        // 100 days per "year"
        @turn = 0;
        @time = TIME.DAWN;
        @day = (Number.random()*100)->floor;
        @year = 1033;
        @party = Party.new();
        @battle = Battle.new();
        @island = empty;
        @story = import(module:'game_singleton.story.mt');
        
        @:getDayString = ::{
            return match(time) {
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
            };
        };
        
        @:getSeasonString = ::{
            return match(this.season) {
              (SEASON.SPRING): 'Spring',           
              (SEASON.SUMMER): 'Summer',           
              (SEASON.AUTUMN): 'Autumn',           
              (SEASON.WINTER): 'Winter'         
           };
        };
        
        this.interface = {
            TIME : {
                get ::<- TIME
            },
            SEASON : {
                get ::<- SEASON
            },
        
            timeString : {
                get :: {
                    return 'Year ' + year +', ' + getSeasonString() + '. ' + getDayString();
                }
            },
            
            
            
            discoverIsland ::(levelHint => Number, tierHint => Number, nameHint) {
                @:out = Island.new(world:this, levelHint, party, nameHint, tierHint);
                return out;
            },
            
            time : {
                get ::<- time
            },
            
            season : {
                get :: {
                    return match(true) {
                      (day > 75): SEASON.WINTER,
                      (day > 50): SEASON.AUTUMN,
                      (day > 25): SEASON.SUMMER,
                      default: SEASON.SPRING
                    };
                }
            },

            
            party : {
                get ::<- party
            },
            
            island : {
                get :: <- island,
                set ::(value) <- island = value
            },
            
            battle : {
                get :: <- battle
            },
            
            storyFlags : {
                get :: <- story
            },
            
            stepTime :: {
                turn += 1;
                if (turn > 5) ::<={
                    turn = 0;
                    time += 1;
                };
                    
                if (time > 13) ::<={
                    time = 0;
                    day += 1;
                };
                
                if (day > 99) ::<={
                    day = 0;
                    year += 1;
                };                
                
            },
            
            state : {
                set ::(value) {
                    turn = value.turn;
                    time = value.time;
                    day = value.day;
                    year = value.year;
                    
                    island = Island.new(levelHint: 0, world: this, party : this.party, state:value.island);                        
                    party.state = value.party;
                    
                    value.storyFlags->foreach(do:::(key, value) {
                        story[key] = value;
                    });
                },
                get :: {
                    @:storyFlags = {};
                    story->foreach(do:::(key, value) {
                        storyFlags[key] = value;
                    });
                    return { 
                        turn : turn,
                        time: time,
                        day : day,
                        year : year,
                        island : island.state, // always valid.
                        party : party.state,
                        storyFlags : storyFlags
                    };
                }
            }
            
        };
    }
).new();
