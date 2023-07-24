@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:random = import(module:'game_singleton.random.mt');
@:BattleAction = import(module:'game_struct.battleaction.mt');
@:Ability = import(module:'game_class.ability.mt');
@:pickItem = import(module:'game_function.pickitem.mt');



@:DICE_WIDTH = 9;
@:DICE_HEIGHT = 6;
@:DICE_BUFFER = 4;

/*
     _______
    |       |    |
    | o   o |    |
    |   o   |    |
    | o   o |    |
    |_______|    |


*/


@:SCORE_TYPE__ONES = 0;
@:SCORE_TYPE__TWOS = 1;
@:SCORE_TYPE__THREES = 2;
@:SCORE_TYPE__FOURS = 3;
@:SCORE_TYPE__FIVES = 4;
@:SCORE_TYPE__SIXES = 5;
@:SCORE_TYPE__STRAIGHT = 6;
@:SCORE_TYPE__FULL_HOUSE = 7;
@:SCORE_TYPE__THREE_OF_A_KIND = 8;
@:SCORE_TYPE__FOUR_OF_A_KIND = 9;
@:SCORE_TYPE__FIVE_OF_A_KIND = 10;
@:SCORE_TYPE__SUM = 11;


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

SCORING_FN[SCORE_TYPE__ONES] = ::(rolls) {
    @val = 0;
    [0, 5]->for(do::(i) {
        if (rolls[i] == 1)
            val += 1;
    });
    return val;
};
        
SCORING_FN[SCORE_TYPE__TWOS] = ::(rolls) {
    @val = 0;
    [0, 5]->for(do::(i) {
        if (rolls[i] == 2)
            val += 2;
    });
    return val;
};


SCORING_FN[SCORE_TYPE__THREES] = ::(rolls) {
    @val = 0;
    [0, 5]->for(do::(i) {
        if (rolls[i] == 3)
            val += 3;
    });
    return val;
};

SCORING_FN[SCORE_TYPE__FOURS] = ::(rolls) {
    @val = 0;
    [0, 5]->for(do::(i) {
        if (rolls[i] == 4)
            val += 4;
    });
    return val;
};

SCORING_FN[SCORE_TYPE__FIVES] = ::(rolls) {
    @val = 0;
    [0, 5]->for(do::(i) {
        if (rolls[i] == 5)
            val += 5;
    });
    return val;
};


SCORING_FN[SCORE_TYPE__SIXES] = ::(rolls) {
    @val = 0;
    [0, 5]->for(do::(i) {
        if (rolls[i] == 6)
            val += 6;
    });
    return val;
};


SCORING_FN[SCORE_TYPE__STRAIGHT] = ::(rolls) {
    @:slots = [];
    return [::] {
        [0, 5]->for(do::(i) {
            if (slots[rolls[i]] == true) send(message:0);
            slots[rolls[i]] = true;
        });
        return 20;
    };
};


SCORING_FN[SCORE_TYPE__FULL_HOUSE] = ::(rolls) {
    @:slots = [0, 0, 0, 0, 0, 0];
    [0, 5]->for(do::(i) {
        slots[rolls[i]-1] += 1;
    });
    @has2 = false;
    @has3 = false;
    [0, 6]->for(do::(i) {
        if (slots[i] == 2) ::<= {
            has2 = true;
        };

        if (slots[i] == 3) ::<= {
            has3 = true;
        };
    });
    
    return (if(has3 && has2) 30 else 0);
};



SCORING_FN[SCORE_TYPE__THREE_OF_A_KIND] = ::(rolls) {
    @:slots = [0, 0, 0, 0, 0, 0, 0];
    [0, 5]->for(do::(i) {
        slots[rolls[i]-1] += 1;
    });
    @val = 0;
    [0, 6]->for(do::(i) {
        if (slots[i] >= 3) ::<= {
            val = 25;        
        };
    });
    return val;
};

SCORING_FN[SCORE_TYPE__FOUR_OF_A_KIND] = ::(rolls) {
    @:slots = [0, 0, 0, 0, 0, 0, 0];
    [0, 5]->for(do::(i) {
        slots[rolls[i]-1] += 1;
    });
    @val = 0;
    [0, 6]->for(do::(i) {
        if (slots[i] >= 4) ::<= {
            val = 40;        
        };
    });
    return val;
};

SCORING_FN[SCORE_TYPE__FIVE_OF_A_KIND] = ::(rolls) {
    @:slots = [0, 0, 0, 0, 0, 0, 0];
    [0, 5]->for(do::(i) {
        slots[rolls[i]-1] += 1;
    });
    @val = 0;
    [0, 6]->for(do::(i) {
        if (slots[i] == 5) ::<= {
            val = 60;        
        };
    });
    return val;
};


SCORING_FN[SCORE_TYPE__SUM] = ::(rolls) {
    @val = 0;
    [0, 5]->for(do::(i) {
        val += rolls[i];
    });
    return val;
};


@:newPlayer ::(name){
    @:scoringTable = [];
    
    SCORING_NAMES->foreach(do:::(i, val) {
        scoringTable->push(value:{
            hasScore: false,
            value: 0   
        });
    });
    
    return {
        scoringTable : scoringTable,
        name : name,
        
        reportScores :: {
            @lines = [];
            @total = 0;
            scoringTable->foreach(do:::(i, value) {
                @line = if (value.hasScore == false) '--' else (if (value.value < 10) (' ' + value.value) else ('' + value.value));
                line = line + ' pts | ' + SCORING_NAMES[i];
                total += value.value;
                lines->push(value:line);
            });
            
            lines->push(value:'_____________');
            lines->push(value:'' + total + ' pts total');    
            windowEvent.queueDisplay(
                prompt:name,
                pageAfter:15,
                lines:lines
            );
        },
        
        score:: {
            @total = 0;
            scoringTable->foreach(do:::(i, val) <- total += val.value);
            return total;
        }
    };
};


return ::(onFinish => Function) {

    @:party = newPlayer(name:'Party');
    @:wyvern = newPlayer(name:'Ziikkaettaal');
    @currentPlayer;


    @:reportScores = :: {
        party.reportScores();
        wyvern.reportScores();
    };


    windowEvent.queueNoDisplay(
        renderable : {
            render::{canvas.blackout();}
        },
        keep:true,
        jumpTag: 'Dice',
        onEnter::{},
        onLeave::{
            onFinish();
        }
    );


    // renderable background for dice.
    @:diceRenderable = {
        rolls : [],
        render::{
            canvas.blackout();
            @:rolls = diceRenderable.rolls;
            // renders a single die at x,y
            @:renderDie::(x, y, number) {
            
                canvas.movePen(x:0, y:0);
                canvas.drawText(text:'Current player: ' +currentPlayer.name);
            
                // render base 
                [1, DICE_WIDTH-1]->for(do::(i) {
                    canvas.movePen(x:x+i, y); canvas.drawChar(text:'_');
                });


                [1, DICE_WIDTH-1]->for(do::(i) {
                    canvas.movePen(x:x+i, y:y+DICE_HEIGHT-1); canvas.drawChar(text:'_');
                });

                [1, DICE_HEIGHT]->for(do::(i) {
                    canvas.movePen(x, y:y+i); canvas.drawChar(text:'|');
                });

                [1, DICE_HEIGHT]->for(do::(i) {
                    canvas.movePen(x:x+DICE_WIDTH-1, y:y+i); canvas.drawChar(text:'|');
                });


                match(number) {
                  (1):::<= {
                    canvas.movePen(x:x + 4, y:y + 3); canvas.drawChar(text:'o');
                  },
                  
                  (2):::<= {
                    canvas.movePen(x:x + 2, y:y + 2); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 6, y:y + 4); canvas.drawChar(text:'o');
                  },


                  (3):::<= {
                    canvas.movePen(x:x + 2, y:y + 2); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 4, y:y + 3); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 6, y:y + 4); canvas.drawChar(text:'o');
                  },
                  
                  (4):::<= {
                    canvas.movePen(x:x + 2, y:y + 2); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 2, y:y + 4); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 6, y:y + 4); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 6, y:y + 2); canvas.drawChar(text:'o');
                  },

                  (5):::<= {
                    canvas.movePen(x:x + 2, y:y + 2); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 2, y:y + 4); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 6, y:y + 4); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 6, y:y + 2); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 4, y:y + 3); canvas.drawChar(text:'o');
                  },

                  (6):::<= {
                    canvas.movePen(x:x + 2, y:y + 2); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 2, y:y + 4); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 4, y:y + 4); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 4, y:y + 2); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 6, y:y + 4); canvas.drawChar(text:'o');
                    canvas.movePen(x:x + 6, y:y + 2); canvas.drawChar(text:'o');
                  }
                  
                };



            };

            @:space = ((canvas.width - (DICE_WIDTH * 5)) / 5)->floor;
            [0, 5]->for(do::(i) {
                renderDie(x:DICE_BUFFER + i*(DICE_WIDTH+space) , y:DICE_BUFFER, number:rolls[i]);
            });

            //renderDie(x:DICE_BUFFER, y:DICE_BUFFER, number:rolls[0]);
            //renderDie(x:canvas.width - (DICE_WIDTH + DICE_WIDTH), y:DICE_BUFFER, number:rolls[1]);
            //renderDie(x:canvas.width / 2 - DICE_WIDTH/2, y:DICE_BUFFER*2 + DICE_HEIGHT, number:rolls[2]);
            //renderDie(x:DICE_BUFFER, y:DICE_BUFFER*3 + DICE_HEIGHT*2, number:rolls[3]);
            //renderDie(x:canvas.width - (DICE_WIDTH + DICE_WIDTH), y:DICE_BUFFER*3 + DICE_HEIGHT*2, number:rolls[4]);

                    
        }
    };


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
                    };
                    
                    rollNext();
                }
            );
        };
        
        @:rollNext ::{
            [::] {
                forever(do:::{
                    when(index == 6) send();
                    when(rolls[index] != empty)
                        index += 1;
                    @:number = random.integer(from:1, to:6);
                    rolls[index] = number;
                    index += 1;
                    send();                    
                });
            };
            renderRolls();
        };
        rollNext();
    };


    @:takeTurn ::(player){
        currentPlayer = player;
        @:rolls = [];
        @rollIndex = 0;  
        diceRenderable.rolls = rolls;  

        @:getPossibleScores::(rolls, scores, pts, kind){
            SCORING_FN->foreach(do:::(i, fn) {
                @:val = fn(rolls);
                when(val == 0) empty;
                when(player.scoringTable[i].hasScore) empty;
                pts->push(value:val);
                scores->push(value: SCORING_NAMES[i] + ': ' + val + ' pts'); 
                kind->push(value:i);
            });
        };
        
        @:scoreParty::(rolls) {
            @:scores = [];
            @:pts = [];
            @:kind = [];
            getPossibleScores(rolls, scores, pts, kind);     
            scores->push(value:'Scratch');    
            
            windowEvent.queueChoices(
                prompt:'Score for: ' + rolls[0] + '-' + rolls[1] + '-' + rolls[2] + '-' + rolls[3] + '-' + rolls[4],
                choices: scores,
                onChoice::(choice){
                    
                    if (kind[choice-1]) ::<= {
                        player.scoringTable[kind[choice-1]].hasScore = true;
                        player.scoringTable[kind[choice-1]].value = pts[choice-1];
                    };
                    
                    player.reportScores();
                    
                    if (player == wyvern)
                        takeTurn(player:party)
                    else 
                        takeTurn(player:wyvern)
                    ;
                }
            );
        };        

        @:chooseRollAction_AI ::{
            @:scores = [];
            @:pts = [];
            @:kind = [];
            getPossibleScores(rolls, scores, pts, kind);



        
            @:scoreWyvern::{            
                windowEvent.queueMessage(
                    text:'Hmmm I think I will keep this...',
                    renderable: diceRenderable,
                    onLeave::{





                        if (kind[0] != empty) ::<= {
                            player.scoringTable[kind[0]].hasScore = true;
                            player.scoringTable[kind[0]].value = pts[0];
                        };
                        player.reportScores();
                        
                        if (player == wyvern)
                            takeTurn(player:party)
                        else 
                            takeTurn(player:wyvern)
                        ;
                    }
                );
            };
            
            scoreWyvern();
        };

            
            
        @:chooseRollAction:: {
            when(player == wyvern) ::<= {
                chooseRollAction_AI();
            };
        
        
            when (rollIndex >= 2) ::<= {
                scoreParty(rolls);
            };
        
            windowEvent.queueChoices(
                choices:[
                    'Choose dice',
                    'Keep all',
                    'Check scores'
                ],
                renderable: diceRenderable,
                
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
                                [0, 5]->for(do:::(i){
                                    list->push(value: (
                                        if(keep[i] == true) '[x] ' else '[ ] ') + 
                                        (match(i) {
                                            (0): 'First  ',
                                            (1): 'Second ',
                                            (2): 'Third  ',
                                            (3): 'Fourth ',
                                            (4): 'Fifth  '
                                        }) + '(' + rolls[i] + ')'
                                    );
                                });
                                
                                list->push(value: 'Done.');
                                return list;
                            },
                            
                            onChoice::(choice) {
                                match(choice) {
                                  (1, 2, 3, 4, 5):::<= {
                                    keep[choice-1] = !keep[choice-1];
                                  },
                                  
                                  (6) :::<= {
                                    @isDone = true;
                                    [0, 5]->for(do:::(i) {
                                        if (keep[i] == false) ::<= {
                                            rolls[i] = empty;
                                            isDone = false;
                                        };
                                    });
                                    rollIndex += 1;
                                                                      
                                    when(isDone) ::<= {
                                        scoreParty(rolls);
                                        windowEvent.jumpToTag(name:'dicekeep', goBeforeTag:true);                                        
                                    };
                                   
                                    doRoll();
                                    windowEvent.jumpToTag(name:'dicekeep', goBeforeTag:true);                                        
                                  }
                                };
                            }
                        );
                      },
                      
                      
                      // keep what we got,
                      (2):::<= {
                        scoreParty(rolls);
                      },
                      
                      (3):::<= {
                        
                        reportScores();
                        chooseRollAction();
                      }                             
                    };                      
                }
            );
            
        };
            
            
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
            
        };
        
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
                    };
                }
            );
        };
        initialChoices();        
    };

    /*
    @rolls = [];
    @:reroll = ::{
        rolls = [];
        rolls[4] = random.integer(from:1, to:6);
        rolls[0] = random.integer(from:1, to:6);
        rolls[3] = random.integer(from:1, to:6);
        rollDice(rolls, onRolled:reroll);    
    };
    rollDice(rolls, onRolled:reroll);
    */
    takeTurn(player:party);
};
