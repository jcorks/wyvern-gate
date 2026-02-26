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

@:grades = [
  'E-', 10,
  'E ', 15,
  'E+', 20,
  'D-', 25,
  'D ', 30,
  'D+', 40,
  'C-', 45,
  'C ', 50,
  'C+', 60,
  'B-', 70,
  'B ', 80,
  'B+', 85,
  'A-', 90,
  'A ', 100,
  'A+', 110,
  'S-', 130,
  'S ', 150,
  'S+', 170,
  'S++',200,
  'SS-',220,
  'SS ',240,
  'SS+',260,
  'SS++',300,
  'X-', 350,
  'X',  400,
  'X+', 500,
  'X++',600,
  '??', 998,
  '[]', 1000000
];

@:valueToGrade::(value) 
  <- ::? { 
    for(0, (grades->size/2)->floor) ::(i) {
      if (value < grades[i*2+1])
        send(:grades[i*2])
    }
    
    return grades[grades->size-2]
  }


@:gradeLimit = [
  10,
  15,
  20,
  25,
  30,
  50,
]

@:rateToMult ::(value) {
  when(value == 0) '..';
  // basic percents
  // return (if (value > 0) + '+' else value)+'%'



  // simplified?
  return if (value < 0) 
    ('!('+value) + '%)'
  else
    valueToGrade(:value);
    


  // mult
  /*
  @:multRaw = (if (value > 0)
      1+((value->ceil / 100))

  return 'x' + ((multRaw / 0.1)->ceil) * 0.1
  */
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
        NAMES->map(::(value) <- rateToMult(:stats[value])),
        NAMES->map(::(value) <- ' -> '),
        NAMES->map(::(value) <- rateToMult(:other[value]))
        /*
        NAMES->map(::(value) <- '(' + rateToMult(:other[value] - stats[value]) + ')')
        */
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
    
    isDiff ::(other) {
      @:this = _.this;
      return 
        other.HP != this.HP ||
        other.AP != this.AP ||
        other.ATK != this.ATK ||
        other.INT != this.INT ||
        other.DEF != this.DEF ||
        other.LUK != this.LUK ||
        other.SPD != this.SPD ||
        other.DEX != this.DEX
    },


  
    mod ::(stats) {
      @:state = _.state;
      foreach(NAMES) ::(k, v) {
        state[v+'mod'] += stats[v];
      }
      return _.this;
    },
    
    scale ::(amount) {
      @:state = _.state;
      foreach(NAMES) ::(k, v) {
        state[v] = (state[v]*amount)->floor;
      }            
      return _.this;
    },
      
    modRate ::(stats) {
      @:state = _.state;
      foreach(NAMES) ::(k, v) {
        state[v+'rate'] += stats[v]/100;
      }    
      return _.this;
    },
      
    resetMod :: {
      @:state = _.state;
      foreach(NAMES) ::(k, v) {
        state[v+'mod'] = 0;
        state[v+'rate'] = 1;
      }
      return _.this;
    },
      
    add ::(stats) {
      @:state = _.state;
      foreach(NAMES) ::(k, v) {
        state[v] += stats[v];
      }
      return _.this;
    },
    
    simplify :: {
      @:state = _.state;
      foreach(NAMES) ::(k, v) {
        state[v] = (state[v] / 5)->ceil * 5;
      }
      return _.this;
    },
      
    subtract ::(stats) {
      @:state = _.state;   
      foreach(NAMES) ::(k, v) {
        state[v] -= stats[v];
      }
      return _.this;
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
            return rateToMult(:this[value])
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
          return rateToMult(:this[value])
        }),
        NAMES->map(::(value) <- 
          if (baseMod[value] == 0) 
            '' 
          else
            if (baseMod[value] > 0)
              '+' + baseMod[value] + ' base'
            else
              '' + baseMod[value] + ' base' 
        )
      ];
      
    
      return canvas.columnsToLines(columns);
    
    }
  }
);
return StatSet;
