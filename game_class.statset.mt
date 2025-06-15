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

@:filterStat::(stats, stat) {
  @:s = stats[stat]  
  return if(stat == 'HP' || stat == 'AP') 
    displayHP(:s)
  else 
    ''+s
}



@:StatSet = LoadableClass.createLight(
  name : 'Wyvern.Entity.StatSet',
  statics: {

    NAMES : {
      get ::<- NAMES
    },
    
    isDifferent::(stats, other) {
      return ::? {
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
        NAMES->map(::(value) {
          @:self = stats[value];
          @:othr = other[value];
        
          return if (othr - self != 0) 
              (if (othr > self) 
                '(+' + (othr - self) + ')'
              else 
                '(' + (othr  - self)  + ')')
            else 
              ''
        })
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
    DEXmod : 0,
    
    HPrate : 1,
    APrate : 1,
    ATKrate : 1,
    INTrate : 1,
    DEFrate : 1,
    SPDrate : 1,
    LUKrate : 1,
    DEXrate : 1
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
        @:this = _.this;
        return ::? {
          foreach(NAMES) ::(k, v) {
            if (this[v] != 0)
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
        state[v+'rate'] += stats[v]/100;
      }    
    },
      
    resetMod :: {
      @:state = _.state;
      foreach(NAMES) ::(k, v) {
        state[v+'mod'] = 0;
        state[v+'rate'] = 1;
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
        @:this = _.this;
        return NAMES->reduce(::(previous, value) <- 
          if (previous == empty) 
            this[value] 
          else 
            previous + this[value]
        );
      }
    },
      
    HP : {
      get ::{
        return ((_.state.HP + _.state.HPmod) * _.state.HPrate)->floor;
      }
    },
    AP : {
      get ::{
        return ((_.state.AP + _.state.APmod) * _.state.APrate)->floor;
      }
    },    
    ATK : {
      get ::{
        return ((_.state.ATK + _.state.ATKmod) * _.state.ATKrate)->floor;
      }
    },
    INT : {
      get ::{
        return ((_.state.INT + _.state.INTmod) * _.state.INTrate)->floor;
      }
    },
    DEF : {
      get ::{
        return ((_.state.DEF + _.state.DEFmod) * _.state.DEFrate)->floor;
      }
    },
    LUK : {
      get ::{
        return ((_.state.LUK + _.state.LUKmod) * _.state.LUKrate)->floor;
      }
    },
    SPD : {
      get ::{
        return ((_.state.SPD + _.state.SPDmod) * _.state.SPDrate)->floor;
      }
    },
    DEX : {
      get ::{
        return ((_.state.DEX + _.state.DEXmod) * _.state.DEXrate)->floor;
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
        @:this = _.this;
        return String.combine(:canvas.columnsToLines(
          columns : [
            NAMES->map(::(value) <- value + ': '),
            NAMES->map(::(value) <- ''+this[value])
            
          ]
        )->map(::(value) <- value + '\n'));
      }
    },

    descriptionAugmentLines : {
      get :: {
        @:state = _.state;
        @:this = _.this;
        return canvas.columnsToLines(
          columns : [
            NAMES->map(::(value) <- value + ': '),
            NAMES->map(::(value) {
              @:s = this[value];
              return if (s == 0) 
                ' ' 
              else if (s > 0) 
                '+'+s
              else
                ''+s
            })
          ]
        )
      }
    },


    descriptionRateLines : {
      get :: {
        @:state = _.state;
        @:this = _.this;
        @:columns = [
          NAMES->map(::(value) <- value + ': '),
          NAMES->map(::(value) {
            return (if(this[value] > 0) '+' + this[value] + '%' else if (this[value] == 0) '--' else ''+this[value]+ '%')
          })
        ];
        return canvas.columnsToLines(columns);
      }
    },
    
    descriptionRateLinesBase ::(baseMod) {
      @:state = _.state;
      @:this = _.this;
      @:columns = [
        NAMES->map(::(value) <- value + ': '),
        NAMES->map(::(value) {
          return (if(this[value] > 0) '+' + this[value] + '%' else if (this[value] == 0) '--' else ''+this[value]+ '%')
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
