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
@:dialogue = import(module:'singleton.dialogue.mt');



return class(
    name : 'Wyvern.Entity.StatSet',
    define:::(this) {
        @HP_  = 0;
        @MP_  = 0;
        @ATK_ = 0;
        @INT_ = 0;
        @DEF_ = 0;
        @LUK_ = 0;
        @SPD_ = 0;
        @DEX_ = 0;
        
        @HPmod  = 0;
        @MPmod  = 0;
        @ATKmod = 0;
        @INTmod = 0;
        @DEFmod = 0;
        @SPDmod = 0;
        @LUKmod = 0;
        @DEXmod = 0;
        
        this.constructor = ::(HP, AP, ATK, INT, DEF, LUK, SPD, DEX) {
            if (HP != empty) HP_  = HP;
            if (AP != empty) MP_  = AP;
            if (ATK != empty)ATK_ = ATK;
            if (INT != empty) INT_ = INT;
            if (DEF != empty) DEF_ = DEF;
            if (LUK != empty) LUK_ = LUK;
            if (SPD != empty) SPD_ = SPD;
            if (DEX != empty) DEX_ = DEX;   
            return this;
        };
        
        this.interface = {
            state : {
                set ::(value) {
                    HP_ = value.HP;
                    MP_ = value.AP;
                    ATK_ = value.ATK;
                    INT_ = value.INT;
                    DEF_ = value.DEF;
                    LUK_ = value.LUK;
                    SPD_ = value.SPD;
                    DEX_ = value.DEX;

                    HPmod = value.HPmod;
                    MPmod = value.MPmod;
                    ATKmod = value.ATKmod;
                    INTmod = value.INTmod;
                    DEFmod = value.DEFmod;
                    LUKmod = value.LUKmod;
                    SPDmod = value.SPDmod;
                    DEXmod = value.DEXmod;

                
                },
            
                get :: {
                    return {
                        HP: HP_,
                        AP: MP_,
                        ATK: ATK_,
                        INT: INT_,
                        DEF: DEF_,
                        LUK: LUK_,
                        SPD: SPD_,
                        DEX: DEX_,
                        
                        HPmod : HPmod,
                        MPmod : MPmod,
                        ATKmod : ATKmod,
                        INTmod : INTmod,
                        DEFmod : DEFmod,
                        SPDmod : SPDmod,
                        LUKmod : LUKmod,
                        DEXmod : DEXmod
                    };                
                }
            },
        
            mod ::(stats) {
                HPmod  += stats.HP;
                MPmod  += stats.AP;
                ATKmod += stats.ATK;
                INTmod += stats.INT;
                DEFmod += stats.DEF;
                LUKmod += stats.LUK;
                SPDmod += stats.SPD;
                DEXmod += stats.DEX;            
            },
            
            modRate ::(stats) {
                HPmod  += (HP_*(stats.HP/100))->ceil;
                MPmod  += (MP_*(stats.AP/100))->ceil;
                ATKmod += (ATK_*(stats.ATK/100))->ceil;
                INTmod += (INT_*(stats.INT/100))->ceil;
                DEFmod += (DEF_*(stats.DEF/100))->ceil;
                LUKmod += (LUK_*(stats.LUK/100))->ceil;
                SPDmod += (SPD_*(stats.SPD/100))->ceil;
                DEXmod += (DEX_*(stats.DEX/100))->ceil;    
                
                        
            
            },
            
            resetMod :: {
                HPmod  = 0;
                MPmod  = 0;
                ATKmod = 0;
                INTmod = 0;
                DEFmod = 0;
                SPDmod = 0;
                LUKmod = 0;
                DEXmod = 0;
            },
            
            add ::(stats) {
                HP_  += stats.HP;
                MP_  += stats.AP;
                ATK_ += stats.ATK;
                INT_ += stats.INT;
                DEF_ += stats.DEF;
                LUK_ += stats.LUK;
                SPD_ += stats.SPD;
                DEX_ += stats.DEX;   
                
                         
            },
            
            HP : {
                get ::{
                    return (HP_ + HPmod)->floor;
                }
            },
            AP : {
                get ::{
                    return (MP_ + MPmod)->floor;
                }
            },        
            ATK : {
                get ::{
                    return (ATK_ + ATKmod)->floor;
                }
            },
            INT : {
                get ::{
                    return (INT_ + INTmod)->floor;
                }
            },
            DEF : {
                get ::{
                    return (DEF_ + DEFmod)->floor;
                }
            },
            LUK : {
                get ::{
                    return (LUK_ + LUKmod)->floor;
                }
            },
            SPD : {
                get ::{
                    return (SPD_ + SPDmod)->floor;
                }
            },
            DEX : {
                get ::{
                    return (DEX_ + DEXmod)->floor;
                }
            },
            
            sum : {
                get ::<- (HP_ + MP_ + ATK_ + INT_ + DEF_ + LUK_ + SPD_ + DEX_)
            },
            
            printDiff ::(other, prompt, onNext => Function) {
                dialogue.displayColumns(
                    prompt,
                    pageAfter: 10,
                    onNext,
                    columns: [
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
                            ''+this.HP,
                            ''+this.AP,
                            ''+this.ATK,
                            ''+this.DEF,
                            ''+this.INT,
                            ''+this.SPD,
                            ''+this.LUK,
                            ''+this.DEX                        
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
                            (if (other.HP - this.HP  != 0) (if (other.HP > this.HP) '(+' else '(') + (other.HP  - this.HP)  + ')' else ''),
                            (if (other.AP - this.AP  != 0) (if (other.AP > this.AP) '(+' else '(') + (other.AP  - this.AP)  + ')' else ''),
                            (if (other.ATK - this.ATK  != 0) (if (other.ATK > this.ATK) '(+' else '(') + (other.ATK  - this.ATK)  + ')' else ''),
                            (if (other.DEF - this.DEF  != 0) (if (other.DEF > this.DEF)'(+' else '(') + (other.DEF  - this.DEF)  + ')' else ''),
                            (if (other.INT - this.INT  != 0) (if (other.INT > this.INT)'(+' else '(') + (other.INT  - this.INT)  + ')' else ''),
                            (if (other.SPD - this.SPD  != 0) (if (other.SPD > this.SPD)'(+' else '(') + (other.SPD  - this.SPD)  + ')' else ''),
                            (if (other.LUK - this.LUK  != 0) (if (other.LUK > this.LUK)'(+' else '(') + (other.LUK  - this.LUK)  + ')' else ''),
                            (if (other.DEX - this.DEX  != 0) (if (other.DEX > this.DEX)'(+' else '(') + (other.DEX  - this.DEX)  + ')' else ''),

                        ]                        
                    ]
                );
            
            },
            
            printDiffRate ::(other, prompt, onNext => Function) {
                dialogue.displayColumns(
                    prompt,
                    pageAfter: 10,
                    onNext,
                    columns: [
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
                            ''+this.HP+'%',
                            ''+this.AP+'%',
                            ''+this.ATK+'%',
                            ''+this.DEF+'%',
                            ''+this.INT+'%',
                            ''+this.SPD+'%',
                            ''+this.LUK+'%',
                            ''+this.DEX+'%'                        
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
                            ''+other.HP+'%',
                            ''+other.AP+'%',
                            ''+other.ATK+'%',
                            ''+other.DEF+'%',
                            ''+other.INT+'%',
                            ''+other.SPD+'%',
                            ''+other.LUK+'%',
                            ''+other.DEX+'%'                        
                        ],
                        
                        [
                            (if (other.HP - this.HP  != 0) (if (other.HP > this.HP) '(+' else '(') + (other.HP  - this.HP)  + ')' else ''),
                            (if (other.AP - this.AP  != 0) (if (other.AP > this.AP) '(+' else '(') + (other.AP  - this.AP)  + ')' else ''),
                            (if (other.ATK - this.ATK  != 0) (if (other.ATK > this.ATK) '(+' else '(') + (other.ATK  - this.ATK)  + ')' else ''),
                            (if (other.DEF - this.DEF  != 0) (if (other.DEF > this.DEF)'(+' else '(') + (other.DEF  - this.DEF)  + ')' else ''),
                            (if (other.INT - this.INT  != 0) (if (other.INT > this.INT)'(+' else '(') + (other.INT  - this.INT)  + ')' else ''),
                            (if (other.SPD - this.SPD  != 0) (if (other.SPD > this.SPD)'(+' else '(') + (other.SPD  - this.SPD)  + ')' else ''),
                            (if (other.LUK - this.LUK  != 0) (if (other.LUK > this.LUK)'(+' else '(') + (other.LUK  - this.LUK)  + ')' else ''),
                            (if (other.DEX - this.DEX  != 0) (if (other.DEX > this.DEX)'(+' else '(') + (other.DEX  - this.DEX)  + ')' else ''),

                        ]                        
                    ]
                );
            
            },
            
            
            description : {
                get :: {
                    return 
                        'HP:  ' + HP_ + '\n' +
                        'AP:  ' + MP_ + '\n' +
                        'ATK: ' + ATK_ + '\n' +
                        'DEF: ' + DEF_ + '\n' +
                        'INT: ' + INT_ + '\n' +
                        'SPD: ' + SPD_ + '\n' +
                        'LUK: ' + LUK_ + '\n' +
                        'DEX: ' + DEX_ + '\n'
                    ;
                }
            },
            
            getRates :: {
                return 
                    'HP:  ' + (if (HP_ > 0) '+' else '')  +HP_ + '%\n' +
                    'AP:  ' + (if (MP_ > 0) '+' else '')  +MP_ + '%\n' +
                    'ATK: ' + (if (ATK_ > 0) '+' else '') +ATK_ + '%\n' +
                    'DEF: ' + (if (DEF_ > 0) '+' else '') +DEF_ + '%\n' +
                    'INT: ' + (if (INT_ > 0) '+' else '') +INT_ + '%\n' +
                    'SPD: ' + (if (SPD_ > 0) '+' else '') +SPD_ + '%\n' +
                    'LUK: ' + (if (LUK_ > 0) '+' else '') +LUK_ + '%\n' +
                    'DEX: ' + (if (DEX_ > 0) '+' else '') +DEX_ + '%\n'
                ;
            }
        };
    }
);
