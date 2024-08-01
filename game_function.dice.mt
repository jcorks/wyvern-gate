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
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:random = import(module:'game_singleton.random.mt');
@:Arts = import(module:'game_database.arts.mt');
@:class = import(module:'Matte.Core.Class');
@:Die = import(module:'game_class.die.mt');



@:DICE_BUFFER = 4;



@:SCORE_TYPE = {
  ONES : 0,
  TWOS : 1,
  THREES : 2,
  FOURS : 3,
  FIVES : 4,
  SIXES : 5,
  STRAIGHT : 6,
  FULL_HOUSE : 7,
  THREE_OF_A_KIND : 8,
  FOUR_OF_A_KIND : 9,
  FIVE_OF_A_KIND : 10,
  SUM : 11
}


@:SCORING_NAMES = [
  'Ones',
  'Twos',
  'Threes',
  'Fours',
  'Fives',
  'Sixes',
  'Straight',
  'Full House',
  'Three-of-a-kind',
  'Four-of-a-kind',
  'Five-of-a-kind',
  'Sum'
];

@:SCORING_FN = [];

SCORING_FN[SCORE_TYPE.ONES] = ::(rolls) {
  @val = 0;
  for(0, 5)::(i) {
    if (rolls[i].value == 1)
      val += 1;
  }
  return val;
}
    
SCORING_FN[SCORE_TYPE.TWOS] = ::(rolls) {
  @val = 0;
  for(0, 5)::(i) {
    if (rolls[i].value == 2)
      val += 2;
  }
  return val;
}


SCORING_FN[SCORE_TYPE.THREES] = ::(rolls) {
  @val = 0;
  for(0, 5)::(i) {
    if (rolls[i].value == 3)
      val += 3;
  }
  return val;
}

SCORING_FN[SCORE_TYPE.FOURS] = ::(rolls) {
  @val = 0;
  for(0, 5)::(i) {
    if (rolls[i].value == 4)
      val += 4;
  }
  return val;
}

SCORING_FN[SCORE_TYPE.FIVES] = ::(rolls) {
  @val = 0;
  for(0, 5)::(i) {
    if (rolls[i].value == 5)
      val += 5;
  }
  return val;
}


SCORING_FN[SCORE_TYPE.SIXES] = ::(rolls) {
  @val = 0;
  for(0, 5)::(i) {
    if (rolls[i].value == 6)
      val += 6;
  }
  return val;
}


SCORING_FN[SCORE_TYPE.STRAIGHT] = ::(rolls) {
  @:slots = [];
  return {:::} {
    for(0, 5)::(i) {
      if (slots[rolls[i].value] == true) send(message:0);
      slots[rolls[i].value] = true;
    }
    return 20;
  }
}


SCORING_FN[SCORE_TYPE.FULL_HOUSE] = ::(rolls) {
  @:slots = [0, 0, 0, 0, 0, 0];
  for(0, 5)::(i) {
    slots[rolls[i].value-1] += 1;
  }
  @has2 = false;
  @has3 = false;
  for(0, 6)::(i) {
    if (slots[i] == 2) ::<= {
      has2 = true;
    }

    if (slots[i] == 3) ::<= {
      has3 = true;
    }
  }
  
  return (if(has3 && has2) 30 else 0);
}



SCORING_FN[SCORE_TYPE.THREE_OF_A_KIND] = ::(rolls) {
  @:slots = [0, 0, 0, 0, 0, 0, 0];
  for(0, 5)::(i) {
    slots[rolls[i].value-1] += 1;
  }
  @val = 0;
  for(0, 6)::(i) {
    if (slots[i] >= 3) ::<= {
      val = 25;    
    }
  }
  return val;
}

SCORING_FN[SCORE_TYPE.FOUR_OF_A_KIND] = ::(rolls) {
  @:slots = [0, 0, 0, 0, 0, 0, 0];
  for(0, 5)::(i) {
    slots[rolls[i].value-1] += 1;
  }
  @val = 0;
  for(0, 6)::(i) {
    if (slots[i] >= 4) ::<= {
      val = 40;    
    }
  }
  return val;
}

SCORING_FN[SCORE_TYPE.FIVE_OF_A_KIND] = ::(rolls) {
  @:slots = [0, 0, 0, 0, 0, 0, 0];
  for(0, 5)::(i) {
    slots[rolls[i].value-1] += 1;
  }
  @val = 0;
  for(0, 6)::(i) {
    if (slots[i] == 5) ::<= {
      val = 60;    
    }
  }
  return val;
}


SCORING_FN[SCORE_TYPE.SUM] = ::(rolls) {
  @val = 0;
  for(0, 5)::(i) {
    val += rolls[i].value;
  }
  return val;
}



@:getPossibleScores::(player, rolls, scores, pts, kind){
  foreach(SCORING_FN)::(i, fn) {
    @:val = fn(rolls);
    when(val == 0) empty;
    when(player.scoringTable[i].hasScore) empty;
    pts->push(value:val);
    scores->push(value: SCORING_NAMES[i] + ': ' + val + ' pts'); 
    kind->push(value:i);
  }
}


@:PlayerAction = class(
  statics : {
    // Player requests to reroll
    REROLL : {get::<-0},
    
    // Player requests to score immediately
    SCORE : {get::<-1}
  },
  
  
  define:::(this) {

    @_action;
    @_scoreType;
    @_scratchType;
    @_keepWhich;

    this.constructor = ::(action, scoreType, scratchType, keepWhich) {
      _action = action;
      _scoreType = scoreType;
      _scratchType = scratchType;
      _keepWhich = keepWhich;
    };

    
    this.interface = {
      action : {
        get::<- _action
      },
      scoreType : {
        get::<- _scoreType
      },
      scratchType : {
        get::<- _scratchType
      },
      keepWhich : {
        get::<- _keepWhich
      }
    }
  }
);








@:Player = class(

  define::(this) {
    @_name;
    @_decider;
    @scoringTable = [];

    foreach(SCORING_NAMES)::(i, val) {
      scoringTable->push(value:{
        hasScore: false,
        value: 0,
        kind: i
      });
    }
    
    
    
    this.constructor = ::(name => String, decider => Function) {
      _name = name;
      _decider = decider;
    };
    
    this.interface = {
      scoringTable : {
        get::<-scoringTable
      },
      name : {
        get::<-_name
      },
      reportScores ::(new) {
        @lines = [];
        @total = 0;
        foreach(scoringTable)::(i, value) {
          @line = (if(new == i) '-> ' else '   ') + (if (value.hasScore == false) '--' else (if (value.value < 10) (' ' + value.value) else ('' + value.value)));
          line = line + ' pts | ' + SCORING_NAMES[i];
          total += value.value;
          lines->push(value:line);
        }
        
        lines->push(value:'_______________________');
        lines->push(value:'   ' + total + ' pts total');  
        windowEvent.queueDisplay(
          prompt:_name,
          pageAfter:15,
          lines:lines
        );
      },
      
      isScoreTableComplete::{
        @out = true;
        foreach(scoringTable)::(i, val) <- if (val.hasScore != true) out = false;
        return out;      
      },
      
      score:: {
        @total = 0;
        foreach(scoringTable)::(i, val) <- total += val.value;
        return total;
      },
      
      decideAction::(onDecide, rolls, rollIndex) {
        _decider(player:this, onDecide, rolls, rollIndex);
      }    
    }
  }

);





return ::(onFinish => Function) {

  @:party = Player.new(
    name:'Party',
    decider::(player, rolls, rollIndex, onDecide){
      
      @:scoreParty:: {
        @:scores = [];
        @:pts = [];
        @:kind = [];
        getPossibleScores(player, rolls, scores, pts, kind);   
        scores->push(value:'Scratch');  
        
        
        
        windowEvent.queueChoices(
          prompt:'Score for: ' + rolls[0].value + '-' + rolls[1].value + '-' + rolls[2].value + '-' + rolls[3].value + '-' + rolls[4].value,
          choices: scores,
          canCancel: false,
          keep:true,
          jumpTag: 'Scoring',
          onChoice::(choice){
            // scratch
            when(choice-1 == scores->keycount-1) ::<= {
              @scratchable = [];
              @kind = [];
              foreach(SCORING_NAMES)::(i, name) {
                when(player.scoringTable[i].hasScore) empty;
                scratchable->push(value: name);
                kind->push(value:i);
              }
              
              
              windowEvent.queueChoices(
                choices:scratchable,
                prompt:'Scratch which?',
                canCancel: true,
                onChoice::(choice) {
                  when(choice == 0) empty;
                  
                  onDecide(
                    action: PlayerAction.new(
                      keepWhich: [true, true, true, true, true],
                      scratchType: kind[choice-1],
                      action: PlayerAction.SCORE
                    )                      
                  );  
                  windowEvent.jumpToTag(name:'Scoring', goBeforeTag:true, doResolveNext:true);                
                }
              );
              
            }
          

            onDecide(
              action: PlayerAction.new(
                keepWhich: [true, true, true, true, true],
                scoreType: kind[choice-1],
                action: PlayerAction.SCORE
              )                      
            );
            windowEvent.jumpToTag(name:'Scoring', goBeforeTag:true, doResolveNext:true);                

          }
        );
      }  
      
      when(rollIndex >= 2)
        scoreParty();  
    
    
      windowEvent.queueChoices(
        choices:[
          'Choose dice',
          'Check scores',
          'Keep all'
        ],
        renderable: diceRenderable,
        keep: true,
        jumpTag: 'PlayerTurn',
        topWeight: 1,
        leftWeight: 1,
        canCancel: false,
        onChoice::(choice) {
          @keep = [
            false,
            false,
            false,
            false,
            false
          ];
          
        
          match(choice) {
            // choose what to keep.
            (1):::<= {
              windowEvent.queueChoices(
                topWeight: 1,
                leftWeight: 1,
                keep: true,
                canCancel: true,
                prompt: 'Keep which?',
                jumpTag: 'dicekeep',
                renderable: diceRenderable,
                onGetChoices::{
                  @list = [];
                  for(0, 5)::(i){
                    list->push(value: (
                      if(keep[i] == true) '[x] ' else '[ ] ') + 
                      (match(i) {
                        (0): 'First  ',
                        (1): 'Second ',
                        (2): 'Third  ',
                        (3): 'Fourth ',
                        (4): 'Fifth  '
                      }) + '(' + rolls[i].value + ')'
                    );
                  }
                  
                  list->push(value: 'Done.');
                  return list;
                },
                
                onChoice::(choice) {
                  when(choice == 0) empty;
                  match(choice) {
                    (1, 2, 3, 4, 5):::<= {
                      keep[choice-1] = !keep[choice-1];
                    },
                    
                    (6) :::<= {
                      @isDone = true;
                      foreach(keep)::(i, val) {
                        if (val != true)
                          isDone = false;
                      }         
                      when(isDone) ::<= {
                        scoreParty();
                        windowEvent.jumpToTag(name:'PlayerTurn', goBeforeTag:true, doResolveNext:true);                    
                      }

                      onDecide(
                        action: PlayerAction.new(
                          keepWhich: keep,
                          scoreType: 0,
                          scratchType: 0,
                          action: PlayerAction.REROLL
                        )                      
                      );                   
                      windowEvent.jumpToTag(name:'PlayerTurn', goBeforeTag:true, doResolveNext:true);                    
                    }
                  }
                }
              );
            },

            (2):::<= {
              reportScores();
            },
            
            
            // keep what we got,
            (3):::<= {
              scoreParty();
              windowEvent.jumpToTag(name:'PlayerTurn', goBeforeTag:true, doResolveNext:true);                    
            }
            
          }            
        }
      );    
    
    }
  );
  @:wyvern = Player.new(
    name:'Ziikkaettaal',
    decider: ::<= {
      @:SCORE_HUNT_AI = [];


      
      SCORE_HUNT_AI[SCORE_TYPE.ONES] = {
        isReasonableToConsider::(rolls){
          @okChance = 0;
          for(0, 5)::(i) {
            if (rolls[i].value == 1)
              okChance+=1; 
          }
          return okChance >= 2;
        },
        maxPotential: 5,
        keepWhich::(rolls, keep) {
          for(0, 5)::(i) {
            keep[i] = rolls[i].value == 1; 
          }
        }
      }



      SCORE_HUNT_AI[SCORE_TYPE.TWOS] = {
        isReasonableToConsider::(rolls){
          @okChance = 0;
          for(0, 5)::(i) {
            if (rolls[i].value == 2)
              okChance+=1; 
          }
          return okChance >= 2;
        },
        maxPotential: 10,
        keepWhich::(rolls, keep) {
          for(0, 5)::(i) {
            keep[i] = rolls[i].value == 2; 
          }
        }
      }

      SCORE_HUNT_AI[SCORE_TYPE.THREES] = {
        isReasonableToConsider::(rolls){
          @okChance = 0;
          for(0, 5)::(i) {
            if (rolls[i].value == 3)
              okChance+=1; 
          }
          return okChance >= 2;
        },
        maxPotential: 15,
        keepWhich::(rolls, keep) {
          for(0, 5)::(i) {
            keep[i] = rolls[i].value == 3; 
          }
        }
      }

      SCORE_HUNT_AI[SCORE_TYPE.FOURS] = {
        isReasonableToConsider::(rolls){
          @okChance = 0;
          for(0, 5)::(i) {
            if (rolls[i].value == 4)
              okChance+=1; 
          }
          return okChance >= 2;
        },
        maxPotential: 20,
        keepWhich::(rolls, keep) {
          for(0, 5)::(i) {
            keep[i] = rolls[i].value == 4; 
          }
        }
      }


      SCORE_HUNT_AI[SCORE_TYPE.FIVES] = {
        isReasonableToConsider::(rolls){
          @okChance = 0;
          for(0, 5)::(i) {
            if (rolls[i].value == 5)
              okChance+=1; 
          }
          return okChance >= 2;
        },
        maxPotential: 25,
        keepWhich::(rolls, keep) {
          for(0, 5)::(i) {
            keep[i] = rolls[i].value == 5; 
          }
        }
      }

      SCORE_HUNT_AI[SCORE_TYPE.SIXES] = {
        isReasonableToConsider::(rolls){
          @okChance = 0;
          for(0, 5)::(i) {
            if (rolls[i].value == 6)
              okChance+=1; 
          }
          return okChance >= 2;
        },
        maxPotential: 30,
        keepWhich::(rolls, keep) {
          for(0, 5)::(i) {
            keep[i] = rolls[i].value == 6; 
          }
        }
      }    
      
      SCORE_HUNT_AI[SCORE_TYPE.STRAIGHT] = {
        isReasonableToConsider::(rolls){
          @uniqueCount = 0;
          @:gotAlready = [0, 0, 0, 0, 0, 0];
          for(0, 5)::(i) {
            gotAlready[rolls[i].value-1] += 1;
          }
          foreach(gotAlready)::(i, val) {
            if (val == 1)
              uniqueCount += 1;
          }
          return uniqueCount >= 3;
        },
        maxPotential: 20,
        keepWhich::(rolls, keep) {
          // get rid of duplicates
          @:gotAlready = [];
          for(0, 5)::(i) {
            keep[i] = gotAlready[rolls[i].value-1] != true; 
            gotAlready[rolls[i].value-1] = true;
          }
        }
      }       

      SCORE_HUNT_AI[SCORE_TYPE.FULL_HOUSE] = {
        isReasonableToConsider::(rolls){
          @uniqueCount = 0;
          @:gotAlready = [0, 0, 0, 0, 0, 0];
          for(0, 5)::(i) {
            gotAlready[rolls[i].value-1] += 1;
          }
          foreach(gotAlready)::(i, val) {
            if (val == 1)
              uniqueCount += 1;
          }
          return uniqueCount <= 3;
        },
        maxPotential: 30,
        keepWhich::(rolls, keep) {
          @:gotAlready = [0, 0, 0, 0, 0, 0];
          for(0, 5)::(i) {
            gotAlready[rolls[i].value-1]+=1;
          }
          for(0, 5)::(i) {
            keep[i] = gotAlready[rolls[i].value-1] >= 2 && gotAlready[rolls[i].value-1] < 4;
          }
        }
      }       

      SCORE_HUNT_AI[SCORE_TYPE.THREE_OF_A_KIND] = {
        isReasonableToConsider::(rolls){
          @:gotAlready = [0, 0, 0, 0, 0, 0];
          for(0, 5)::(i) {
            gotAlready[rolls[i].value-1] += 1;
          }
          @viable = false;
          foreach(gotAlready)::(i, val) {
            if (val >= 2)
              viable = true;
          }
          return viable;
        },
        maxPotential: 25,
        keepWhich::(rolls, keep) {
          @:gotAlready = [0, 0, 0, 0, 0, 0];
          for(0, 5)::(i) {
            gotAlready[rolls[i].value-1]+=1;
          }

          @max = 0;
          @maxRoll = 0;          
          for(0, 5)::(i) {
            if (gotAlready[rolls[i].value-1] > max) ::<= {
              max = gotAlready[rolls[i].value-1];
              maxRoll = rolls[i].value;
            }
          }


          for(0, 5)::(i) {
            keep[i] = rolls[i].value == maxRoll;
          }
        }
      }   

      SCORE_HUNT_AI[SCORE_TYPE.FOUR_OF_A_KIND] = {
        isReasonableToConsider::(rolls){
          @:gotAlready = [0, 0, 0, 0, 0, 0];
          for(0, 5)::(i) {
            gotAlready[rolls[i].value-1] += 1;
          }
          @viable = false;
          foreach(gotAlready)::(i, val) {
            if (val >= 2)
              viable = true;
          }
          return viable;
        },
        maxPotential: 40,
        keepWhich::(rolls, keep) {
          @:gotAlready = [0, 0, 0, 0, 0, 0];
          for(0, 5)::(i) {
            gotAlready[rolls[i].value-1]+=1;
          }

          @max = 0;
          @maxRoll = 0;          
          for(0, 5)::(i) {
            if (gotAlready[rolls[i].value-1] > max) ::<= {
              max = gotAlready[rolls[i].value-1];
              maxRoll = rolls[i].value;
            }
          }


          for(0, 5)::(i) {
            keep[i] = rolls[i].value == maxRoll;
          }
        }
      }   

      SCORE_HUNT_AI[SCORE_TYPE.FIVE_OF_A_KIND] = {
        isReasonableToConsider::(rolls){
          @:gotAlready = [0, 0, 0, 0, 0, 0];
          for(0, 5)::(i) {
            gotAlready[rolls[i].value-1] += 1;
          }
          @viable = false;
          foreach(gotAlready)::(i, val) {
            if (val >= 3)
              viable = true;
          }
          return viable;
        },
        maxPotential: 60,
        keepWhich::(rolls, keep) {
          @:gotAlready = [0, 0, 0, 0, 0, 0];
          for(0, 5)::(i) {
            gotAlready[rolls[i].value-1]+=1;
          }

          @max = 0;
          @maxRoll = 0;          
          for(0, 5)::(i) {
            if (gotAlready[rolls[i].value-1] > max) ::<= {
              max = gotAlready[rolls[i].value-1];
              maxRoll = rolls[i].value;
            }
          }


          for(0, 5)::(i) {
            keep[i] = rolls[i].value == maxRoll;
          }
        }
      } 


      SCORE_HUNT_AI[SCORE_TYPE.SUM] = {
        isReasonableToConsider::(rolls){
          return true;
        },
        maxPotential: 30,
        keepWhich::(rolls, keep) {
          for(0, 5)::(i) {
            keep[i] = rolls[i].value > 3;
          }
        }
      } 


      return ::(player, rolls, rollIndex, onDecide) {
        // first, see whats doable
        @typesAvail = player.scoringTable->filter(by:::(value) <- value.hasScore == false)->map(to:::(value) <- value.kind);
        @:eval = [...typesAvail]->filter(by:::(value) <- SCORE_HUNT_AI[value].isReasonableToConsider(rolls))
          ->map(to:::(value) <- {
            maxPotential : SCORE_HUNT_AI[value].maxPotential,
            score :    SCORING_FN[value](rolls),
            kind  :    value
          });
        
        
        // if this is our last turn, just say what score we would have
        @scoreType = if (eval->keycount) ::<= {
          eval->sort(comparator:::(a, b) {
            when (a.score < b.score) -1;
            when (a.score > b.score) 1;
            return 0;
          });
          @out = eval[eval->keycount-1];
          when (out.score == 0) empty;
          return out.kind;
        } else empty;
        
        

        
        
        

        // next determine which to scratch if any
        @scratchType;
        if (scoreType == empty) ::<= {
          if (typesAvail->findIndexCondition(::(value) <- value == SCORE_TYPE.ONES) != -1)
            scratchType = SCORE_TYPE.ONES;

          if (scratchType == empty && typesAvail->findIndexCondition(::(value) <- value == SCORE_TYPE.TWOS) != -1)
            scratchType = SCORE_TYPE.TWOS;

          if (scratchType == empty && typesAvail->findIndexCondition(::(value) <- value == SCORE_TYPE.THREES) != -1)
            scratchType = SCORE_TYPE.THREES;
            
          if (scratchType == empty && typesAvail->findIndexCondition(::(value) <- value == SCORE_TYPE.FIVE_OF_A_KIND) != -1)
            scratchType = SCORE_TYPE.FIVE_OF_A_KIND;
            
          if (scratchType == empty)
            scratchType = random.pickArrayItem(list:typesAvail);
        }
        
        
        // in the case its not our last roll, we need to decide what to 
        // keep. If we dont have anything we're hunting for , 
        // dump all (default)
        @:keepWhich = [false, false, false, false, false];
        
        if (eval->keycount > 0) ::<= {
        
          
          eval->sort(comparator::(a, b) {
            when(a.maxPotential < b.maxPotential) -1;
            when(a.maxPotential > b.maxPotential)  1;
            return 0;
          });
          
          SCORE_HUNT_AI[eval[eval->keycount-1].kind].keepWhich(
            rolls,
            keep:keepWhich
          );
        } else ::<= {
          // dont give up! at this point nothing is "reasonable",
          // so we just hunt whatevers available thats high value. 
          if (typesAvail->keycount != 0) ::<= {
            typesAvail->sort(comparator:::(a, b) {
              @maxA = SCORE_HUNT_AI[a].maxPotential;
              @maxB = SCORE_HUNT_AI[b].maxPotential;
              when (maxA < maxB) -1;
              when (maxA > maxB)  1;
              return 0;
            });
            
            SCORE_HUNT_AI[typesAvail[typesAvail->keycount-1]].keepWhich(
              rolls,
              keep:keepWhich
            );            
          }
        }
        
        
        @action = PlayerAction.REROLL;
        
        // finally we need to decide whether to stay or keep going.
        if (scoreType != empty && eval->keycount > 0) ::<= {
          // if we have a potential score, we need to decide if its worth 
          // going for.
          @block = eval[eval->findIndexCondition(::(value) <- value.kind == scoreType)];
          if (
            block.maxPotential == block.score
          )
            action = PlayerAction.SCORE;
            
        }
        onDecide(
          action: PlayerAction.new(
            keepWhich,
            scoreType,
            scratchType,
            action
          )
        );
      }
    }
  );
  @currentPlayer;


  @:reportScores = :: {
    party.reportScores();
    wyvern.reportScores();
  }


  windowEvent.queueCustom(
    renderable : {
      render::{canvas.blackout();}
    },
    keep:true,
    jumpTag: 'Dice',
    onEnter::{},
    onLeave::{    
      @:partyWins = party.score() > wyvern.score();
      onFinish(partyWins);
    }
  );


  // renderable background for dice.
  @:diceRenderable = {
    rolls : [],
    render::{
      canvas.blackout();
      @:rolls = diceRenderable.rolls;

      @:space = ((canvas.width - (Die.WIDTH * 5)) / 5)->floor;
      canvas.movePen(x:0, y:0);
      canvas.drawText(text:'Current player: ' +currentPlayer.name);
      for(0, 5)::(i) {
        rolls[i].render(x:DICE_BUFFER + i*(Die.WIDTH+space) , y:DICE_BUFFER);
      }
          
    }
  }


  @rollDice::(rolls, onRolled => Function) {
    @index = 0;

    // renders all dice
    @:renderRolls ::{
      diceRenderable.rolls = rolls;
      windowEvent.queueMessage(
        speaker: '',
        text: if (index >= 6) 'Heres the roll' else ('Die ' + (index)),
        leftWeight: 0.5,
        topWeight: 1,
        renderable : diceRenderable,
        onLeave::{
          when (index == 6) ::<= {
            onRolled();
          }
          
          rollNext();
        }
      );
    }
    
    @:rollNext ::{
      {:::} {
        forever ::{
          when(index == 5) ::<= {
            index += 1;
            send();
          }
          when(rolls[index].value != empty)
            index += 1;
          rolls[index].roll();
          index += 1;
          send();          
        }
      }
      renderRolls();
    }
    rollNext();
  }


  @:takeTurn ::(player){
    when (party.isScoreTableComplete() &&
        wyvern.isScoreTableComplete()) ::<= {
      windowEvent.jumpToTag(name:'Dice', goBeforeTag:true);
    }


    currentPlayer = player;
    @:rolls = [
      Die.new(),
      Die.new(),
      Die.new(),
      Die.new(),
      Die.new()    
    ];
    @rollIndex = 0;  
    diceRenderable.rolls = rolls;  


    

    @:chooseRollAction ::{
    
      player.decideAction(
        rolls,
        rollIndex,
        onDecide:::(action) {
          @:scores = [];
          @:pts = [];
          @:kind = [];
          getPossibleScores(player, rolls, scores, pts, kind);

          when (action.action == PlayerAction.SCORE || rollIndex == 2)
            windowEvent.queueMessage(
              text:if (player == wyvern) 'Hmmm I think I will keep this...' else 'The party\'s turn is over',
              renderable: diceRenderable,
              onLeave::{
              
              

                if (action.scratchType != empty) ::<= {
                  
                  player.scoringTable[action.scratchType].hasScore = true;
                  player.scoringTable[action.scratchType].value = 0;
                  player.reportScores(new:action.scratchType);

                } else ::<= {



                  player.scoringTable[action.scoreType].hasScore = true;
                  player.scoringTable[action.scoreType].value = pts[kind->findIndex(value:action.scoreType)];
                  player.reportScores(new:action.scoreType);
                }
                
                if (player == wyvern)
                  takeTurn(player:party)
                else 
                  takeTurn(player:wyvern)
                ;
              }
            ); 
            
          rollIndex += 1;
          for(0, 5)::(i) {
            if (action.keepWhich[i] == false) ::<= {
              rolls[i].value = empty;
            }
          }
          // reroll.
          doRoll();
                       
        }
      );
    
    }

      
      
      
      
    @:doRoll::{


      windowEvent.queueMessage(
        renderable: diceRenderable,
        text:([
          'First roll...',
          'Second roll...',
          'Third roll...'
        ])[rollIndex],
        onLeave::{
          rollDice(rolls, onRolled:chooseRollAction);
        }
      );
      
    }
    
    @:initialChoices = ::{
      when(player == wyvern)
        doRoll();
        
      windowEvent.queueChoices(
        choices: [
          'Roll',
          'Check Scores',
          'Give up'
        ],
        topWeight: 1,
        leftWeight: 1,
        canCancel: false,
        renderable: diceRenderable,
        onChoice::(choice) {
          match(choice) {
            (1):::<= {
              doRoll();
            },
            
            (2):::<= {
              reportScores();
              initialChoices();    
            }
          }
        }
      );
    }
    initialChoices();    
  }

  /*
  @rolls = [];
  @:reroll = ::{
    rolls = [];
    rolls[4] = random.integer(from:1, to:6);
    rolls[0] = random.integer(from:1, to:6);
    rolls[3] = random.integer(from:1, to:6);
    rollDice(rolls, onRolled:reroll);  
  }
  rollDice(rolls, onRolled:reroll);
  */
  takeTurn(player:party);
}
