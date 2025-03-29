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

@:filterStat::(stats, stat) <-
  if(stat == 'HP' || stat == 'AP') 
    displayHP(:stats[stat])
  else 
    ''+stats[stat]
;

@:StatSet = LoadableClass.createLight(
  name : 'Wyvern.Entity.StatSet',
  statics: {

    NAMES : {
      get ::<- NAMES
    },
    
    isDifferent::(stats, other) {
      return {:::} {
        foreach(NAMES) ::(k, v) {
          if (stats[v] != other[v])
            send(:true);
        }
        return false;
      }
    },
    
    diffToLines ::(stats, other) {
      return canvas.columnsToLines(columns:[
        NAMES->map(::(value) <- value + ': '),
        NAMES->map(::(value) <- filterStat(stats, stat:value)),
        NAMES->map(::(value) <- ' -> '),
        NAMES->map(::(value) <- filterStat(stats:other, stat:value)),        
        NAMES->map(::(value) <- (
          if (other[value] - stats[value]  != 0) 
            (if (other[value] > stats[value]) 
              '(+' else '(') + (other[value]  - stats[value])  + ')' 
            else ''
          )
        )
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
        return {:::} {
          foreach(NAMES) ::(k, v) {
            if (state[v] != 0)
              send(:false);
          }
          return true;
        }
      }
    },
    
    clone ::{
      @n = StatSet.new();
      n.load(:_.this.save());
      return n;
    },


  
    mod ::(stats) {
      @:state = _.state;
      foreach(NAMES) ::(k, v) {
        state[v+'mod'] += stats[v];
      }
    },
      
    modRate ::(stats) {
      @:state = _.state;
      foreach(NAMES) ::(k, v) {
        state[v+'mod'] += (state[v] * (stats[v]/100))->ceil;
      }    
    },
      
    resetMod :: {
      @:state = _.state;
      foreach(NAMES) ::(k, v) {
        state[v+'mod'] = 0;
      }
    },
      
    add ::(stats) {
      @:state = _.state;
      foreach(NAMES) ::(k, v) {
        state[v] += stats[v];
      }
    },
      
    subtract ::(stats) {
      @:state = _.state;   
      foreach(NAMES) ::(k, v) {
        state[v] -= stats[v];
      }
    },
    
    sum : {
      get ::{
        @:state = _.state;
        return NAMES->reduce(::(previous, value) <- 
          if (previous == empty) 
            state[value] 
          else 
            previous + state[value]
        );
      }
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
        return String.combine(:canvas.columnsToLines(
          columns : [
            NAMES->map(::(value) <- value + ': '),
            NAMES->map(::(value) <- ''+state[value])
            
          ]
        )->map(::(value) <- value + '\n'));
      }
    },

    descriptionRateLines : {
      get :: {
        @:state = _.state;
        @:columns = [
          NAMES->map(::(value) <- value + ': '),
          NAMES->map(::(value) {
            return (if(state[value] > 0) '+' + state[value] + '%' else if (state[value] == 0) '--' else ''+state[value]+ '%')
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
          return (if(state[value] > 0) '+' + state[value] + '%' else if (state[value] == 0) '--' else ''+state[value]+ '%')
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
