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
@:displayHP = import(:'game_function.displayhp.mt');


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
          ''+displayHP(:stats.HP),
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
          ''+displayHP(:other.HP),
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
    
    getNthStat ::(n) <- NAMES[n],
    getStatsInOrder ::<- NAMES,
    
    diffRateToLines::(stats, other) {
      return canvas.columnsToLines(columns:[
        NAMES->map(::(value) <- value + ': '),
        NAMES->map(::(value) <- if(stats[value]>0)'+'+stats[value]+'%' else if (stats[value]==0)'--' else ''+stats[value]+'%'),
        NAMES->map(::(value) <- ' -> '),
        NAMES->map(::(value) <- if(other[value]>0)'+'+other[value]+'%' else if (other[value]==0)'--' else ''+other[value]+'%'),
        NAMES->map(::(value) <- if (other[value] - stats[value]  != 0) (if (other[value] > stats[value]) '(+' else '(') + (other[value]  - stats[value])  + '%)' else ''),          
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
        return canvas.columnsToLines(
          columns : [
            NAMES->map(::(value) <- value + ': '),
            NAMES->map(::(value) <- state[value])
            
          ]
        );
      }
    },

    descriptionRateLines : {
      get :: {
        @:state = _.state;
        @:columns = [
          NAMES->map(::(value) <- value + ': '),
          NAMES->map(::(value) {
            return (if(state[value] > 0) '+' + state[value] + '%\n' else if (state[value] == 0) '--' else ''+state[value]+ '%')
          })
        ];
        return canvas.columnsToLines(columns);
      }
    },
    
    descriptionRateLinesBase ::(baseMod) {
      @:state = _.state;
      @:columns = [
        NAMES->map(::(value) <- value + ': '),
        NAMES->map(::(value) {
          return (if(state[value] > 0) '+' + state[value] + '%\n' else if (state[value] == 0) '--' else ''+state[value]+ '%')
        }),
        NAMES->map(::(value) <- 
          if (baseMod[value] == 0) 
            '' 
          else
            if (baseMod[value] > 0)
              ' +' + baseMod[value] + ' base'
            else
              '' + baseMod[value] + ' base' 
        )
      ];
      
    
      return canvas.columnsToLines(columns);
    
    }
  }
);
return StatSet;
