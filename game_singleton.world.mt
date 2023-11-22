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
                island : empty,
                story : import(module:'game_singleton.story.mt')
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
                get :: <- state.island,
                set ::(value) <- state.island = value
            },
            
            battle : {
                get :: <- state.battle
            },
            
            storyFlags : {
                get :: <- state.story
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
            
            save ::{
                return state.save()
            },
            
            load ::(serialized) {
                state.load(parent:this, serialized);
                @:st = state.story;
                state.story = import(module:'game_singleton.story.mt');
                state.story.load(serialized:st);
            }
            
        }
    }
);

return World.new();
