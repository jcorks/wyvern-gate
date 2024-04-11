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
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');


@:NAMES = [
    'HP',
    'AP',
    'ATK',
    'INT',
    'DEF',
    'LUK',
    'SPD',
    'DEX'
]


@:StatSet = LoadableClass.createLight(
    name : 'Wyvern.Entity.StatSet',
    statics: {

        NAMES : {
            get ::<- NAMES
        },
        
        isDifferent::(stats, other) {
            return 
                stats.HP != other.HP ||
                stats.AP != other.AP ||
                stats.ATK != other.ATK ||
                stats.DEF != other.DEF ||
                stats.INT != other.INT ||
                stats.SPD != other.SPD ||
                stats.LUK != other.LUK ||
                stats.DEX != other.DEX
            ;
        },
        
        diffToLines ::(stats, other) {
            return canvas.columnsToLines(columns:[
                [
                    'HP:',
                    'AP:',
                    'ATK:',
                    'DEF:',
                    'INT:',
                    'SPD:',
                    'LUK:',
                    'DEX:'
                ],
                
                [
                    ''+stats.HP,
                    ''+stats.AP,
                    ''+stats.ATK,
                    ''+stats.DEF,
                    ''+stats.INT,
                    ''+stats.SPD,
                    ''+stats.LUK,
                    ''+stats.DEX                        
                ],
                
                [
                    ' -> ',
                    ' -> ',
                    ' -> ',
                    ' -> ',
                    ' -> ',
                    ' -> ',
                    ' -> ',                        
                    ' -> ',                        
                ],
                
                [
                    ''+other.HP,
                    ''+other.AP,
                    ''+other.ATK,
                    ''+other.DEF,
                    ''+other.INT,
                    ''+other.SPD,
                    ''+other.LUK,
                    ''+other.DEX                        
                ],
                
                [
                    (if (other.HP - stats.HP  != 0) (if (other.HP > stats.HP) '(+' else '(') + (other.HP  - stats.HP)  + ')' else ''),
                    (if (other.AP - stats.AP  != 0) (if (other.AP > stats.AP) '(+' else '(') + (other.AP  - stats.AP)  + ')' else ''),
                    (if (other.ATK - stats.ATK  != 0) (if (other.ATK > stats.ATK) '(+' else '(') + (other.ATK  - stats.ATK)  + ')' else ''),
                    (if (other.DEF - stats.DEF  != 0) (if (other.DEF > stats.DEF)'(+' else '(') + (other.DEF  - stats.DEF)  + ')' else ''),
                    (if (other.INT - stats.INT  != 0) (if (other.INT > stats.INT)'(+' else '(') + (other.INT  - stats.INT)  + ')' else ''),
                    (if (other.SPD - stats.SPD  != 0) (if (other.SPD > stats.SPD)'(+' else '(') + (other.SPD  - stats.SPD)  + ')' else ''),
                    (if (other.LUK - stats.LUK  != 0) (if (other.LUK > stats.LUK)'(+' else '(') + (other.LUK  - stats.LUK)  + ')' else ''),
                    (if (other.DEX - stats.DEX  != 0) (if (other.DEX > stats.DEX)'(+' else '(') + (other.DEX  - stats.DEX)  + ')' else ''),

                ]                        
            ]);     
        },
        
        diffRateToLines::(stats, other) {
            return canvas.columnsToLines(columns:[
                [
                    'HP:',
                    'AP:',
                    'ATK:',
                    'DEF:',
                    'INT:',
                    'SPD:',
                    'LUK:',
                    'DEX:'
                ],
                
                [
                    (if(stats.HP>0)'+'+stats.HP+'%' else if (stats.HP==0)'--' else ''+stats.HP+'%'),
                    (if(stats.AP>0)'+'+stats.AP+'%' else if (stats.AP==0)'--' else ''+stats.AP+'%'),
                    (if(stats.ATK>0)'+'+stats.ATK+'%' else if (stats.ATK==0)'--' else ''+stats.ATK+'%'),
                    (if(stats.DEF>0)'+'+stats.DEF+'%' else if (stats.DEF==0)'--' else ''+stats.DEF+'%'),
                    (if(stats.INT>0)'+'+stats.INT+'%' else if (stats.INT==0)'--' else ''+stats.INT+'%'),
                    (if(stats.SPD>0)'+'+stats.SPD+'%' else if (stats.SPD==0)'--' else ''+stats.SPD+'%'),
                    (if(stats.LUK>0)'+'+stats.LUK+'%' else if (stats.LUK==0)'--' else ''+stats.LUK+'%'),
                    (if(stats.DEX>0)'+'+stats.DEX+'%' else if (stats.DEX==0)'--' else ''+stats.DEX+'%')                        
                ],
                
                [
                    ' -> ',
                    ' -> ',
                    ' -> ',
                    ' -> ',
                    ' -> ',
                    ' -> ',
                    ' -> ',                        
                    ' -> ',                        
                ],
                
                [
                    (if(other.HP>0)'+'+other.HP+'%' else if (other.HP==0)'--' else ''+other.HP+'%'),
                    (if(other.AP>0)'+'+other.AP+'%' else if (other.AP==0)'--' else ''+other.AP+'%'),
                    (if(other.ATK>0)'+'+other.ATK+'%' else if (other.ATK==0)'--' else ''+other.ATK+'%'),
                    (if(other.DEF>0)'+'+other.DEF+'%' else if (other.DEF==0)'--' else ''+other.DEF+'%'),
                    (if(other.INT>0)'+'+other.INT+'%' else if (other.INT==0)'--' else ''+other.INT+'%'),
                    (if(other.SPD>0)'+'+other.SPD+'%' else if (other.SPD==0)'--' else ''+other.SPD+'%'),
                    (if(other.LUK>0)'+'+other.LUK+'%' else if (other.LUK==0)'--' else ''+other.LUK+'%'),
                    (if(other.DEX>0)'+'+other.DEX+'%' else if (other.DEX==0)'--' else ''+other.DEX+'%')                        
                ],
                
                [
                    (if (other.HP - stats.HP  != 0) (if (other.HP > stats.HP) '(+' else '(') + (other.HP  - stats.HP)  + '%)' else ''),
                    (if (other.AP - stats.AP  != 0) (if (other.AP > stats.AP) '(+' else '(') + (other.AP  - stats.AP)  + '%)' else ''),
                    (if (other.ATK - stats.ATK  != 0) (if (other.ATK > stats.ATK) '(+' else '(') + (other.ATK  - stats.ATK)  + '%)' else ''),
                    (if (other.DEF - stats.DEF  != 0) (if (other.DEF > stats.DEF)'(+' else '(') + (other.DEF  - stats.DEF)  + '%)' else ''),
                    (if (other.INT - stats.INT  != 0) (if (other.INT > stats.INT)'(+' else '(') + (other.INT  - stats.INT)  + '%)' else ''),
                    (if (other.SPD - stats.SPD  != 0) (if (other.SPD > stats.SPD)'(+' else '(') + (other.SPD  - stats.SPD)  + '%)' else ''),
                    (if (other.LUK - stats.LUK  != 0) (if (other.LUK > stats.LUK)'(+' else '(') + (other.LUK  - stats.LUK)  + '%)' else ''),
                    (if (other.DEX - stats.DEX  != 0) (if (other.DEX > stats.DEX)'(+' else '(') + (other.DEX  - stats.DEX)  + '%)' else ''),

                ]                        
            ]);      
        }
    },
    items : {
        HP : 0,
        AP : 0,
        ATK : 0,
        INT : 0,
        DEF : 0,
        LUK : 0,
        SPD : 0,
        DEX : 0,
        
        HPmod : 0,
        APmod : 0,
        ATKmod : 0,
        INTmod : 0,
        DEFmod : 0,
        SPDmod : 0,
        LUKmod : 0,
        DEXmod : 0
    },
    
    private : {},

    interface : {
        defaultLoad::(HP, AP, ATK, INT, DEF, LUK, SPD, DEX) {
            @:state = _.state;
            if (HP != empty) state.HP  = HP;
            if (AP != empty) state.AP  = AP;
            if (ATK != empty) state.ATK = ATK;
            if (INT != empty) state.INT = INT;
            if (DEF != empty) state.DEF = DEF;
            if (LUK != empty) state.LUK = LUK;
            if (SPD != empty) state.SPD = SPD;
            if (DEX != empty) state.DEX = DEX;   
        },
            
        isEmpty : {
            get :: {
                @:state = _.state;
                return
                state.HP ==0 &&
                state.AP ==0 &&
                state.ATK ==0 &&
                state.INT ==0 &&
                state.DEF ==0 &&
                state.LUK ==0 &&
                state.SPD ==0 &&
                state.DEX ==0                    
            }
        },


    
        mod ::(stats) {
            @:state = _.state;
            state.HPmod  += stats.HP;
            state.APmod  += stats.AP;
            state.ATKmod += stats.ATK;
            state.INTmod += stats.INT;
            state.DEFmod += stats.DEF;
            state.LUKmod += stats.LUK;
            state.SPDmod += stats.SPD;
            state.DEXmod += stats.DEX;            
        },
            
        modRate ::(stats) {
            @:state = _.state;
            state.HPmod  += (state.HP*(stats.HP/100))->ceil;
            state.APmod  += (state.AP*(stats.AP/100))->ceil;
            state.ATKmod += (state.ATK*(stats.ATK/100))->ceil;
            state.INTmod += (state.INT*(stats.INT/100))->ceil;
            state.DEFmod += (state.DEF*(stats.DEF/100))->ceil;
            state.LUKmod += (state.LUK*(stats.LUK/100))->ceil;
            state.SPDmod += (state.SPD*(stats.SPD/100))->ceil;
            state.DEXmod += (state.DEX*(stats.DEX/100))->ceil;    
            
                    
        
        },
            
        resetMod :: {
            @:state = _.state;
            state.HPmod  = 0;
            state.APmod  = 0;
            state.ATKmod = 0;
            state.INTmod = 0;
            state.DEFmod = 0;
            state.SPDmod = 0;
            state.LUKmod = 0;
            state.DEXmod = 0;
        },
            
        add ::(stats) {
            @:state = _.state;
            state.HP  += stats.HP;
            state.AP  += stats.AP;
            state.ATK += stats.ATK;
            state.INT += stats.INT;
            state.DEF += stats.DEF;
            state.LUK += stats.LUK;
            state.SPD += stats.SPD;
            state.DEX += stats.DEX;   
        },
            
        subtract ::(stats) {
            @:state = _.state;
            state.HP  -= stats.HP;
            state.AP  -= stats.AP;
            state.ATK -= stats.ATK;
            state.INT -= stats.INT;
            state.DEF -= stats.DEF;
            state.LUK -= stats.LUK;
            state.SPD -= stats.SPD;
            state.DEX -= stats.DEX;               
        },
        
        sum : {
            get ::<-
                _.state.HP +
                _.state.AP +
                _.state.ATK +
                _.state.INT + 
                _.state.DEF + 
                _.state.LUK + 
                _.state.SPD +
                _.state.DEX
        },
            
        HP : {
            get ::{
                return (_.state.HP + _.state.HPmod)->floor;
            }
        },
        AP : {
            get ::{
                return (_.state.AP + _.state.APmod)->floor;
            }
        },        
        ATK : {
            get ::{
                return (_.state.ATK + _.state.ATKmod)->floor;
            }
        },
        INT : {
            get ::{
                return (_.state.INT + _.state.INTmod)->floor;
            }
        },
        DEF : {
            get ::{
                return (_.state.DEF + _.state.DEFmod)->floor;
            }
        },
        LUK : {
            get ::{
                return (_.state.LUK + _.state.LUKmod)->floor;
            }
        },
        SPD : {
            get ::{
                return (_.state.SPD + _.state.SPDmod)->floor;
            }
        },
        DEX : {
            get ::{
                return (_.state.DEX + _.state.DEXmod)->floor;
            }
        },
        
        printDiff ::(other, prompt, renderable) {
            windowEvent.queueDisplay(
                prompt,
                pageAfter: 10,
                renderable,
                lines : StatSet.diffToLines(stats:_.this, other)            
            );
        },
            
        printDiffRate ::(other, prompt) {
            windowEvent.queueDisplay(
                prompt,
                pageAfter: 10,
                lines: StatSet.diffRateToLines(stats:_.this, other)
            );
        },
            
        description : {
            get :: {
                @:state = _.state;
                return 
                    'HP:  ' + state.HP + '\n' +
                    'AP:  ' + state.AP + '\n' +
                    'ATK: ' + state.ATK + '\n' +
                    'DEF: ' + state.DEF + '\n' +
                    'INT: ' + state.INT + '\n' +
                    'SPD: ' + state.SPD + '\n' +
                    'LUK: ' + state.LUK + '\n' +
                    'DEX: ' + state.DEX + '\n'
                ;
            }
        },

        descriptionRate : {
            get :: {
                @:state = _.state;
                return 
                    'HP:  ' + (if(state.HP > 0) '+' + state.HP + '%\n' else if (state.HP == 0) '--\n' else ''+state.HP+ '%\n') +
                    'AP:  ' + (if(state.AP > 0) '+' + state.AP + '%\n' else if (state.AP == 0) '--\n' else ''+state.AP+ '%\n') +
                    'ATK: ' + (if(state.ATK > 0) '+' + state.ATK + '%\n' else if (state.ATK == 0) '--\n' else ''+state.ATK+ '%\n') +
                    'DEF: ' + (if(state.DEF > 0) '+' + state.DEF + '%\n' else if (state.DEF == 0) '--\n' else ''+state.DEF+ '%\n') +
                    'INT: ' + (if(state.INT > 0) '+' + state.INT + '%\n' else if (state.INT == 0) '--\n' else ''+state.INT+ '%\n') +
                    'SPD: ' + (if(state.SPD > 0) '+' + state.SPD + '%\n' else if (state.SPD == 0) '--\n' else ''+state.SPD+ '%\n') +
                    'LUK: ' + (if(state.LUK > 0) '+' + state.LUK + '%\n' else if (state.LUK == 0) '--\n' else ''+state.LUK+ '%\n') +
                    'DEX: ' + (if(state.DEX > 0) '+' + state.DEX + '%\n' else if (state.DEX == 0) '--\n' else ''+state.DEX+ '%\n')
                ;
            }
        }
    }
);
return StatSet;
