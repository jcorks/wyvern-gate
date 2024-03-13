@:class = import(module:'Matte.Core.Class');
@:canvas = import(module:'game_singleton.canvas.mt');
@:random = import(module:'game_singleton.random.mt');
@:Deck = import(module:'game_class.deck.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');

// default game is called "Sorcerer"
/*


Sorcerer


Overview
- This game is played with 2 players and a standard 52-card 
  playing deck. The goal of the game is to get 3 points. 
  The game is played in rounds, and each round, one player 
  is the "attacker" while the other is the "defender". 
  These roles switch at the end of a round.





Starting a Game

- At the start of the game, you must choose who will start attacking 
  before drawing cards. This can be decided with a coin flip, 
  or some other agreement.

- Once decided, the deck is shuffled. Both players 5 cards to their  
  hand from the deck. Each player can (and should) look at their hands.


Scoring

- Each player's points are kept in separate, card piles 
  in an unused play area (their respective scoring area) and are used
  to mark the score. Each card pile represents a point. If the
  attacker doesnt win, the flipped cards are placed in a game-wide
  discard pile and no scoring occurs.



Playing the Game

- The intent of the game is to win 3 points. The player who is the 
  first to win 3 points is the winner. At this time the game ends.

- The game is played in rounds. At the start of a round,
  any player that has no cards in their hand draws 5 new cards 
  from the deck. Afterward, each player chooses
  a card from their hand and places it face-down. Once both players have
  chosen, the cards are flipped. This is called a "challenge".
  
    . IF the attacker's card is of HIGHER value, the attacker
      wins the challenge. Aces are the highest value card.

    . IF the attacker wins the first challenge, 
      the defender MAY choose to increase the stakes by challenging 
      the attacker once more. The attacker MUST accept this second 
      challenge. In this case, the current cards are left face up, 
      and each player chooses an additional card from their hand 
      to put face down. Once this is done, the face down cards are 
      revealed and their values are compared.
      
      IF the attacker's second card is of HIGHER value than the 
      defenders second card, the round is over: the attacker gains 
      one scoring point and the defender loses a scoring point 
      (the lost point cards are sent to the game-wide discard pile). 
      If the defender wins the second round, no points are lost or gained.
      
      Otherwise, IF the defender chooses not to have a second challenge, 
      the round is over and the attacker gains a point AND the defender 
      gets to draw back to 5 cards.
      
    . IF the attacker DOESN'T win (the first challenge), no scoring occurs.

    . IF at any challenge the same card value is revealed, the round 
      is over and no points are lost or gained. 

    . NOTE that if the the first attack is complete with any player 
      not having any remaining cards a second challenge is 
      impossible and the round is over.

  
- If no cards remain in the deck, the discard pile is placed facedown 
  and shuffled. This pile becomes the new deck.














*/
@sorcerer ::<= {
    @:PHASE = {
        CHOOSE_CARD1 : 0,
        FLIP_CARD1 : 1,
        CHOOSE_CARD2 : 2,
        FLIP_CARD2 : 3
    };

    @:Player = class(
        define::(this) {
            @hand = [];
            @points = []; // arrays of 2 to 4 cards.
            @name = '';
            @deciderCard = empty;
            @deciderChallenge2 = empty;
            
            this.interface = {
                // Sets the function to decide actions. 
                // For the Gamblist, this is ai, for the user it is 
                // a menu of options
                setDecider :: (card => Function, challenge2 => Function) {
                    deciderCard = card;
                    deciderChallenge2 = challenge2;
                },
                
                name : {
                    set ::(value) <- name = value,
                    get ::<- name
                },
            
                // draws to 5 cards from the deck
                draw::(deck => Deck.type) {
                    {:::} {
                        forever ::{
                            when(hand->keycount == 5) send();
                            if (deck.cardsLeft == 0) ::<= {
                                deck.readdCardsFromDiscard()
                                deck.shuffle();
                            }
                            hand->push(value:deck.drawNextCard());
                        }
                    }
                },
                
                hand : {
                    get ::<- [...hand]
                },
                
                points : {
                    get ::<- [...points]
                },
                
                chooseChallengeCard::(
                    // function to do action when 
                    // done deciding. Expects a number index of the 
                    // card from the player's hand
                    onChoose => Function,
                
                    // Other player. No peeking!
                    challenger => Player.type,
                    
                    // The results of the first bout, if any.
                    // If empty, this is the first challenge.
                    // If an object, will be keyed with each player 
                    // and the card they played
                    firstBout    
                ) {
                    deciderCard(
                        player: this,
                        onChoose,
                        challenger,
                        firstBout                       
                    );
                },
                
                
                chooseChallenge2::(
                    // function to do action once decided.
                    // Expects a boolean denoting whether to 
                    // challenge again.
                    onChoose => Function,
                    
                    // the opposing player
                    challenger => Player.type,
                    
                    // the attackers card.
                    attackerCard => Deck.Card.type,
                    
                    // the defenders card
                    defenderCard => Deck.Card.type
                ) {
                    deciderChallenge2(
                        player: this,
                        onChoose,
                        challenger,
                        attackerCard,
                        defenderCard
                    );
                },
                
                
                playCard::(index) {
                    @card = hand[index];
                    hand->remove(key:index);
                    return card;
                },
                
                
                addPoint::(bout => Object) {
                    points->push(value: bout);
                },

                losePoint::() {
                    when(points->keycount == 0) empty;
                    return points->pop;
                },
                
                renderHand::(x, y, flipped) {
                    @index = 0;
                    foreach(hand)::(i, card) {
                        card.render(x:x+index, y, flipped);
                        index += 3;
                    }
                }                
                
            }            
        }
    );






    return ::(onFinish) {
        @partyWins;
        @placeholderDecider = ::(
            player,
            onChoose,
            challenger,
            firstBout                       
        ) {
            @doit = random.try(percentSuccess: 30);
                
            when(doit) ::<= {
                windowEvent.queueMessage(
                    text: 'I\'ll pick this card',
                    renderable,
                    onLeave::{
                        onChoose(index:random.pickArrayItem(list:player.hand->keys));            
                    }
                )             
            }
            @:hand = [...player.hand];
            hand->sort(comparator::(a, b) {
                when (a.value < b.value) -1;
                when (a.value > b.value) 1;
                return 0;
            });
            
            @index = if (firstBout == empty) ::<= {
                return player.hand->findIndex(value:hand[0]);
            } else ::<= {
                return player.hand->findIndex(value:hand[hand->keycount-1]);            
            }
            
            
            // if attacking and pressured other, 
            // always pick highest card.
            if (attacker == player && challenger.hand->keycount <= 1) ::<= {
                index = player.hand->findIndex(value:hand[hand->keycount-1]);                        
            }
            
            
            windowEvent.queueMessage(
                text: 'I\'ll pick this card',
                renderable,
                onLeave::{
                    onChoose(index);            
                }
            )             
        }

        @placeholderDeciderChallenge2 = ::(
            player,
            onChoose,
            challenger,
            attackerCard,
            defenderCard                     
        ) {
            @doit = random.try(percentSuccess: if (player.hand->keycount < 3) 40 else 85);

            @hand = [...player.hand];
            hand->sort(comparator::(a, b) {
                when(a.value < b.value) -1;
                when(a.value > b.value) 1;
                return 0;
            })
            
            if (hand[hand->keycount-1].value < 9)
                doit = random.try(percentSuccess:90);
            

            
            if (challenger.points->keycount >= 2)
                doit = true;
            
            
            
            windowEvent.queueMessage(
                text: 'I will' + (if (doit) ' ' else ' not ') + 'challenge once more.',
                renderable,
                onLeave ::{
                    onChoose(challenge2:doit);            
                }
            );
        }




        @playerDecider = ::(
            player,
            onChoose,
            challenger,
            firstBout                       
        ) {
            @options = [...player.hand]->map(to:::(value) <- value.string);
        
            windowEvent.queueChoices(
                prompt: 'Play which?',
                renderable,
                topWeight: 1,
                leftWeight : 1,
                keep: true,
                canCancel : false,
                jumpTag : 'ChooseCard',
                choices : options,
                onChoice::(choice) {
                    windowEvent.queueAskBoolean(
                        prompt: 'Play the ' + options[choice-1] + ' ?',
                        onChoice::(which) {
                            when (which == false) empty;
                            onChoose(index:choice-1);     
                            windowEvent.jumpToTag(name: 'ChooseCard', goBeforeTag: true, doResolveNext: true);                             
                        }
                    )
                }
            ) 
        }


      @playerDeciderChallenge2 = ::(
            player,
            onChoose,
            challenger,
            attackerCard,
            defenderCard                     
        ) {
            windowEvent.queueMessage(
                text: 'As the defender, you have a chance to nullify the challenge through challenging again. If you win as the defender in the second challenge, ' + challenger.name + ' won\'t gain a point. But if you lose, you lose a point and they gain a point.',
                renderable,
                onLeave ::{
                    windowEvent.queueAskBoolean(    
                        prompt: 'Challenge once more? ',
                        renderable,
                        onChoice::(which) {
                            onChoose(challenge2:which);                            
                        }
                    )                
                }
            );
        }




        @deck = Deck.new();
        deck.addStandard52();
        deck.shuffle();
        
        
        

        @:player = Player.new();
        @:gamblist = Player.new();
    
        player.name = 'Party';
        gamblist.name = 'The Gamblist';
        
        player.setDecider(card:playerDecider, challenge2:playerDeciderChallenge2);
        gamblist.setDecider(card:placeholderDecider, challenge2:placeholderDeciderChallenge2);
        
        
        @phase = PHASE.CHOOSE_CARD1;
        @attacker;
        @defender;

        @playerCard0;
        @gamblistCard0;
        
        @playerCard1;
        @gamblistCard1;        
        
        @renderable = {render ::{
            canvas.blackout();
            @:centerX = canvas.width / 2;
            @:centerY = canvas.height / 2;

            if (playerCard0) ::<= {
                playerCard0.render(
                    x:centerX - Deck.Card.WIDTH/2 + 2,
                    y:centerY ,
                    flipped: phase < PHASE.FLIP_CARD1
                );
            }
            
            if (gamblistCard0) ::<= {
                gamblistCard0.render(
                    x:centerX - Deck.Card.WIDTH/2,
                    y:centerY - Deck.Card.HEIGHT,
                    flipped: phase < PHASE.FLIP_CARD1
                );
            }            


            if (playerCard1) ::<= {
                playerCard1.render(
                    x:centerX - Deck.Card.WIDTH/2 + 3,
                    y:centerY + 1,
                    flipped: phase < PHASE.FLIP_CARD2
                );
            }
            
            if (gamblistCard1) ::<= {
                gamblistCard1.render(
                    x:centerX - Deck.Card.WIDTH/2 + 1,
                    y:centerY - Deck.Card.HEIGHT + 1,
                    flipped: phase < PHASE.FLIP_CARD2
                );
            } 


            player.renderHand(x:0, y:canvas.height - Deck.Card.HEIGHT, flipped:false);
            gamblist.renderHand(x:canvas.width - Deck.Card.WIDTH*gamblist.hand->keycount, y:0, flipped:true);        

            canvas.movePen(x:0, y:0);
            canvas.drawText(text: 'Current attacker: [' + attacker.name + ']');            
            canvas.movePen(x:0, y:2);
            canvas.drawText(text: 'Score ');
            canvas.movePen(x:0, y:3);
            canvas.drawText(text: (if (attacker == player) '*' else ' ') + '  Party        : ' + ::<= {
                @out = '';
                for(0, player.points->keycount) ::(i) {
                    out = out + 'o';
                }
                return out
            });
            canvas.movePen(x:0, y:4);
            canvas.drawText(text: (if (attacker == player) ' ' else '*') + '  The Gamblist : ' + ::<= {
                @out = '';
                for(0, gamblist.points->keycount) ::(i) {
                    out = out + 'o';
                }
                return out
            });
            
            canvas.movePen(x:canvas.width/2-(22/2), y:canvas.height-1);
            canvas.drawText(text: 
                if (phase < PHASE.CHOOSE_CARD2)
                    " - First Challenge - "
                else
                    " - Second Challenge - "
            );            
    
            
        }}
        
        
        
        
        if (random.flipCoin()) ::<= {
            attacker = gamblist;
            defender = player;
        } else ::<= {
            defender = gamblist;
            attacker = player;        
        }
        
        
        @:doTurn = ::{
        
            when (player.points->keycount >= 3) ::<= {
                windowEvent.queueMessage(
                    text: player.name + ' wins!',
                    onLeave ::{
                        partyWins = true;
                        windowEvent.jumpToTag(name:'Sorcerer', goBeforeTag: true);                    
                    }
                );                
            }

            when (gamblist.points->keycount >= 3) ::<= {
                windowEvent.queueMessage(
                    text: gamblist.name + ' wins!',
                    onLeave :: {
                        partyWins = false;
                        windowEvent.jumpToTag(name:'Sorcerer', goBeforeTag: true);                    
                    }
                );                
            }
            
            if (player.hand->keycount == 0) ::<= {
                player.draw(deck);
            }

            if (gamblist.hand->keycount == 0) ::<= {
                gamblist.draw(deck);        
            }
            @temp = attacker;
            attacker = defender;
            defender = temp;
        
            playerCard0 = empty;
            playerCard1 = empty;
            gamblistCard0 = empty;
            gamblistCard1 = empty;
            
            phase = PHASE.CHOOSE_CARD1;
            
            windowEvent.queueMessage(
                text: attacker.name + ' is now the attacker',
                renderable
            );
            
            gamblist.chooseChallengeCard(
                onChoose ::(index){
                    gamblistCard0 = gamblist.playCard(index);
                    player.chooseChallengeCard(
                        onChoose::(index) {
                            playerCard0 = player.playCard(index);
                            doTurn_flip1();
                        },
                        challenger : gamblist
                        
                    )
                },
                challenger : player
            )
            
            @:doTurn_flip1 = ::{
                windowEvent.queueMessage(
                    
                    text: 'Here\'s the flip.',
                    topWeight: 1,
                    renderable,
                    onLeave ::{
                        phase = PHASE.FLIP_CARD1;
                        windowEvent.queueMessage(
                            
                            text: 'Here\'s the flip.',
                            topWeight: 1,
                            renderable,
                            onLeave ::{
                                @attackerCard;
                                @defenderCard;
                                
                                if (attacker == gamblist) ::<= {
                                    attackerCard = gamblistCard0;
                                    defenderCard = playerCard0;
                                } else ::<= {
                                    attackerCard = playerCard0;
                                    defenderCard = gamblistCard0;                                
                                }

                                when (attackerCard.value == 
                                      defenderCard.value) ::<= {
                                    windowEvent.queueMessage(
                                        
                                        text: 'No one wins the challenge.',
                                        topWeight: 1,
                                        renderable,
                                        onLeave ::{   
                                            deck.discard(card:playerCard0);                                 
                                            deck.discard(card:gamblistCard0);                                 
                                            doTurn();
                                        }
                                    );
                                }
                                

            
                                // attacker doesnt win. round over.                    
                                when (attackerCard.value < 
                                      defenderCard.value) ::<= {
                                    windowEvent.queueMessage(
                                        
                                        text: defender.name +' wins the challenge.',
                                        topWeight: 1,
                                        renderable,
                                        onLeave ::{   
                                            deck.discard(card:playerCard0);                                 
                                            deck.discard(card:gamblistCard0);                                 
                                            doTurn();
                                        }
                                    );
                                }
                                
                                
                                
                                // else, the attacker one
                                windowEvent.queueMessage(
                                    
                                    text: attacker.name + ' wins the challenge.',
                                    topWeight: 1,
                                    renderable,
                                    onLeave ::{       
                                        when(attacker.hand->keycount == 0 ||
                                             defender.hand->keycount == 0) ::<= {
                                            windowEvent.queueMessage(
                                                
                                                text: 'Not enough cards for both players to play another challenge.. ' + attacker.name + ' gains a point.',
                                                topWeight: 1,
                                                renderable,
                                                onLeave ::{   
                                                    attacker.addPoint(bout:[gamblistCard0, playerCard0])      
                                                    doTurn();
                                                }
                                            );
                                        
                                        }                                    
                                    
                                                                 
                                        defender.chooseChallenge2(
                                            challenger: attacker,
                                            attackerCard: if (attacker == gamblist) gamblistCard0 else playerCard0,
                                            defenderCard: if (defender == gamblist) gamblistCard0 else playerCard0,
                                            onChoose::(challenge2) {
                                                when(!challenge2) ::<= {
                                                    windowEvent.queueMessage(
                                                        
                                                        text: defender.name + ' has decided not to rechallenge. ' + attacker.name + ' gains a point and ' + defender.name + ' draws back up to 5 cards.',
                                                        topWeight: 1,
                                                        renderable,
                                                        onLeave ::{   
                                                            defender.draw(deck);
                                                            attacker.addPoint(bout:[gamblistCard0, playerCard0])      
                                                            doTurn();
                                                        }
                                                    );
                                                }
                                                

                                                
                                                windowEvent.queueMessage(
                                                    
                                                    text: defender.name + ' has decided to rechallenge.',
                                                    topWeight: 1,
                                                    renderable,
                                                    onLeave ::{   
                                                        doTurn_choose2();
                                                    }
                                                );                                                
                                            }
                                        )   
                                    }
                                );
                            }
                        )
                    }
                );                            
            }
            
            
            @:doTurn_choose2 = ::{
                phase = PHASE.CHOOSE_CARD2;
                @bout1 = {};
                bout1[player]   = playerCard0;
                bout1[gamblist] = gamblistCard0;
                gamblist.chooseChallengeCard(
                    onChoose ::(index){
                        gamblistCard1 = gamblist.playCard(index);
                        player.chooseChallengeCard(
                            onChoose::(index) {
                                playerCard1 = player.playCard(index);
                                doTurn_flip2();
                            },
                            
                            challenger : gamblist,
                            firstBout : bout1
                        )
                    },
                    challenger : player,
                    firstBout : bout1
                )
            }
            
            @:doTurn_flip2 = ::{
                windowEvent.queueMessage(
                    
                    text: 'Here\'s the flip.',
                    topWeight: 1,
                    renderable,
                    onLeave ::{
                        phase = PHASE.FLIP_CARD2;
                        windowEvent.queueMessage(
                            
                            text: 'Here\'s the flip.',
                            topWeight: 1,
                            renderable,
                            onLeave ::{
                                @attackerCard;
                                @defenderCard;
                                
                                if (attacker == gamblist) ::<= {
                                    attackerCard = gamblistCard1;
                                    defenderCard = playerCard1;
                                } else ::<= {
                                    attackerCard = playerCard1;
                                    defenderCard = gamblistCard1;                                
                                }
                                
                                when (attackerCard.value == 
                                      defenderCard.value) ::<= {
                                    windowEvent.queueMessage(
                                        
                                        text: 'No one wins the challenge.',
                                        topWeight: 1,
                                        renderable,
                                        onLeave ::{   
                                            deck.discard(card:playerCard0);                                 
                                            deck.discard(card:gamblistCard0);                                 
                                            doTurn();
                                        }
                                    );
                                }                                
            
                                // attacker doesnt win. round over.                    
                                when (attackerCard.value <= 
                                      defenderCard.value) ::<= {
                                    windowEvent.queueMessage(
                                        
                                        text: defender.name + ' wins the challenge.',
                                        topWeight: 1,
                                        renderable,
                                        onLeave ::{   
                                            deck.discard(card:playerCard0);                                 
                                            deck.discard(card:gamblistCard0);                                 
                                            deck.discard(card:playerCard1);                                 
                                            deck.discard(card:gamblistCard1);                                 
                                            doTurn();
                                        }
                                    );
                                }
                                
                                
                                // else, the attacker one
                                windowEvent.queueMessage(
                                    
                                    text: attacker.name + ' wins the challenge. ' + defender.name + ' loses a point and ' + attacker.name + ' wins a point.',
                                    topWeight: 1,
                                    renderable,
                                    onLeave ::{
                                        @lostPoint = defender.losePoint();
                                        if (lostPoint) ::<= {                                    
                                            foreach(lostPoint)::(k, card) {
                                                deck.discard(card);
                                            } 
                                        }
                                        attacker.addPoint(bout:[playerCard0, playerCard1, gamblistCard0, gamblistCard1]);
                                        doTurn();
                                    }
                                );
                            }
                        )
                    }
                );                            
            }            
            
        }
                
        windowEvent.queueCustom(
            renderable : {
                render::{canvas.blackout();}
            },
            keep:true,
            jumpTag: 'Sorcerer',
            onEnter::{},
            onLeave::{        
                onFinish(partyWins);
            }
        );   
        
        windowEvent.queueChoices(
            choices: ['Play', 'Rules'],
            keep : true,
            canCancel : false,
            prompt: 'Sorcerer - A Duel of Magic',
            onChoice::(choice) {
                when(choice == 1) doTurn();     
                
                windowEvent.queueDisplay(
                    prompt: 'Rules',
                    lines: [
                        "Sorcerer - A Duel of Magic",
                        "",
                        "Overview",
                        "- This game is played with 2 players and",
                        "  a standard 52-card  playing deck. The ",
                        "  goal of the game is to get 3 points.",
                        "  The game is played in rounds, and each",
                        "  round, one player is the \"attacker\"",
                        "  while the other is the \"defender\".",
                        "  These roles switch at the end of a round.",
                        "",
                        "Starting a Game",
                        "",                        
                        "- At the start of the game, you must choose",
                        "  who will start attacking before drawing",
                        "  cards. This can be decided with a coin",
                        "  flip, or some other agreement.",
                        "",
                        "- Once decided, the deck is shuffled. Both",
                        "  players draw 5 cards from the",
                        "  deck. Each player can (and should)",
                        "  look at their hands.",
                        "",
                        "Scoring",
                        "",
                        "- Each player's points are kept in",
                        "  separate card piles in an unused play",
                        "  area (their respective scoring area) and",
                        "  are used to mark the score. Each card",
                        "  pile represents a point. If the attacker",
                        "  doesnt win, the flipped cards are placed",
                        "  in a game-wide discard pile and no",
                        "  scoring occurs.",
                        "",
                        "Playing the Game",
                        "",
                        "- The intent of the game is to win 3",
                        "  points. The player who is the first to", 
                        "  win 3 points is the winner. At this",
                        "  time the game ends.",
                        "",
                        "- The game is played in rounds. At the ",
                        "  start of a round, any player that has ",
                        "  no cards in their hand draws 5 new cards", 
                        "  from the deck. Afterward, each player",
                        "  chooses a card from their hand and",
                        "  places it face-down. Once both players",
                        "  have chosen, the cards are flipped. ",
                        "  This is called a \"challenge\".",
                        "",
                        " . IF the attacker's card is of HIGHER", 
                        "   value, the attacker wins the challenge.", 
                        "   Aces are the highest value card.",
                        "",
                        " . IF the attacker wins the first", 
                        "   challenge, the defender MAY choose to", 
                        "   increase the stakes by challenging the", 
                        "   attacker once more. The attacker MUST", 
                        "   accept this second challenge. In this",
                        "   case, the current cards are left face", 
                        "   up, and each player chooses an", 
                        "   additional card from their hand to put",
                        "   face down. Once this is done, the face",
                        "   down cards are revealed and their", 
                        "   values are compared.",
                        "",
                        "   IF the attacker's second card is of", 
                        "   HIGHER value than the defenders second",
                        "   card, the round is over: the attacker", 
                        "   gains one scoring point and the defender",
                        "   loses a scoring point (the lost point", 
                        "   cards are sent to the game-wide discard",
                        "   pile). If the defender wins the second", 
                        "   round, no points are lost or gained.",
                        "",
                        "   Otherwise, IF the defender chooses not",
                        "   to have a second challenge, the round", 
                        "   is over and the attacker gains a point.",
                        "   At this time, the defender draws back",
                        "   to 5 cards.",
                        "",
                        " . IF the attacker DOESN'T win (the first",
                        "   challenge), no scoring occurs.",
                        "",
                        " . IF at any challenge the same card value",
                        "   is revealed, the round is over and no",
                        "   points are lost or gained.", 
                        "",
                        " . NOTE that if the the first attack is",
                        "   complete with no cards remaining", 
                        "   in-hand, a second challenge is", 
                        "   impossible and the round is over.",
                        "",  
                        "- If no cards remain in the deck, the", 
                        "  discard pile is placed facedown and ",
                        "  shuffled. This pile becomes the new deck."               
                    ],
                    pageAfter: 16
                );
            }
        );
        
        
        
        
    }
}


@:high_low_but_dumb = ::(onFinish) {
    @deck = Deck.new();
    deck.addStandard52();
    deck.shuffle();
    
    
    @pointsWon  = 0;
    @pointsLost = 0;
    @partyWins;


    @:nextRound :: {
        when (pointsWon >= 3) ::<= {
            windowEvent.queueMessage(
                text: 'The party wins!',
                onLeave ::{
                    partyWins = true;
                    windowEvent.jumpToTag(name:'HighLowButDumb', goBeforeTag: true);                    
                }
            );                
        }

        when (pointsLost >= 3) ::<= {
            windowEvent.queueMessage(
                text: 'The Gamblist wins!',
                onLeave :: {
                    partyWins = false;
                    windowEvent.jumpToTag(name:'HighLowButDumb', goBeforeTag: true);                    
                }
            );                
        }    
        @:is3 = random.flipCoin();
        
        
        @:nameToChoice = ::(name) <-
            if (is3) 
                match(name) {
                    ('Left')   : 0,
                    ('Middle') : 1,
                    ('Right')  : 2
                }
            else
                match(name) {
                    ('Left')   : 0,
                    ('Right')  : 1
                }
        ;
        
        @:hand = [
            deck.drawNextCard(),
            deck.drawNextCard(),
        ]
        
        @:obscured = [
            true,
            true
        ]
        
        @:boardRenderable = {
            render ::{
                canvas.blackout();
                
                
                // draw scoreboard
                canvas.movePen(x:0, y:0);
                canvas.drawText(text:'Wins  : ');
                for(0, pointsWon)::(i) {
                    canvas.movePen(x:8+i, y:0);
                    canvas.drawChar(text: 'o')
                }

                canvas.movePen(x:0, y:1);
                canvas.drawText(text:'Losses: ');
                for(0, pointsLost)::(i) {
                    canvas.movePen(x:8+i, y:1);
                    canvas.drawChar(text: 'x')
                }


                // draw cards
                @centerX = (canvas.width  / 2)->floor;
                @centerY = (canvas.height / 2)->floor;
                if (is3) ::<= {
                    @offsetX = centerX - (Deck.Card.WIDTH/2)->floor;
                    @offsetY = centerY - (Deck.Card.HEIGHT/2)->floor;
                    hand[0].render(x:offsetX - (Deck.Card.WIDTH - 2), y:offsetY, flipped:obscured[0]);
                    hand[1].render(x:offsetX +2,                      y:offsetY, flipped:obscured[1]);
                    hand[2].render(x:offsetX + (Deck.Card.WIDTH + 2), y:offsetY, flipped:obscured[2]);
                    
                } else ::<= {
                    @offsetX = centerX;
                    @offsetY = centerY - (Deck.Card.HEIGHT/2)->floor;
                    hand[0].render(x:offsetX - (Deck.Card.WIDTH + 2), y:offsetY, flipped:obscured[0]);
                    hand[1].render(x:offsetX,                         y:offsetY, flipped:obscured[1]);
                }
            }
        }
        
        
        @:checkFinalChoice = ::(isFirst, which){
            @highest = which;
            for(0, hand->keycount) ::(i){
                obscured[i] = false;
                if (hand[i].value > hand[highest].value)
                    highest = i;
            }


            windowEvent.queueMessage(
                speaker: 'The Gamblist',
                text: if (highest == which) 'Good choice...' else 'Better luck next time.',
                topWeight: 1,
                renderable:boardRenderable,
                onLeave ::{
            
                    // party was correct
                    if (highest == which)
                        pointsWon += if (isFirst) 2 else 1
                    else 
                        pointsLost += 1
                        
                    
                        
                    nextRound();
                
                }

            );        
        }
        
        
        
        if (is3) ::<= {
            hand->push(value:deck.drawNextCard());
            obscured->push(value:true);
            windowEvent.queueMessage(
                speaker: 'The Gamblist',
                text: 'In this round, I will draw 3 cards. You must choose the highest card. If your first guess is correct, it counts as 2 wins.',
                renderable:boardRenderable
            );
        } else ::<= {
            windowEvent.queueMessage(
                speaker: 'The Gamblist',
                text: 'In this round, I will draw 2 cards. You must choose which card is higher. If your first guess is correct, it counts as 2 wins.',
                renderable:boardRenderable
            );
        }


        windowEvent.queueMessage(
            speaker: 'The Gamblist',
            topWeight: 1,
            text: 'Pick a card.',
            renderable:boardRenderable
        );

        @cardChoices = if (is3)
            ['Left', 'Middle', 'Right']
        else 
            ['Left', 'Right'];
            
            
        
        windowEvent.queueChoices(
            prompt:'Pick which?',
            canCancel : false,
            topWeight: 1,
            leftWeight: 1,
            choices: cardChoices,
            renderable:boardRenderable,
            onChoice::(choice) {
                @:originalChoice = choice-1;
                windowEvent.queueMessage(
                    topWeight: 1,
                    text : random.pickArrayItem(list:
                        if (is3)
                            [
                                'The gamblist smiles slyly before revealing two of the cards.',   
                                'The gamblist emotionlessly flips two of the cards.',   
                                'The gamblist chuckles for a while before flipping two of the cards.',   
                                'The gamblist sternly flips two of the cards before starring at you.'
                            ]
                        else 
                            [
                                'The gamblist smiles slyly before revealing one of the cards.',   
                                'The gamblist emotionlessly flips one of the cards.',   
                                'The gamblist chuckles for a while before flipping one of the cards.',   
                                'The gamblist sternly flips one of the cards before starring at you.'
                            ]
                    ),
                    renderable:boardRenderable,
                    onLeave ::{
                    
                        @isSneaky = random.try(percentSuccess:40);
                        @dontReveal = 0;
                        if (!isSneaky) ::<= {
                            for(1, hand->keycount) ::(i) {
                                if ((7 - hand[i].value)->abs > (7 - hand[dontReveal].value)->abs) ::<= {
                                    dontReveal = i;
                                }
                            }
                        } else ::<= {
                            @choices = [];
                            for(0, hand->keycount) ::(i) {
                                choices->push(value:i);
                            }
                            dontReveal = random.pickArrayItem(list:choices);              
                        }

                        for(0, hand->keycount) ::(i) {
                            when(i == dontReveal) empty;
                            obscured[i] = false;
                        }



                        windowEvent.queueMessage(
                            speaker: 'The Gamblist',
                            text : 'Perhaps you\'ll change your choice.',
                            topWeight: 1,
                            renderable:boardRenderable,
                            onLeave ::{
                                windowEvent.queueAskBoolean(
                                    prompt: 'Keep original choice of the ' + cardChoices[originalChoice] + ' card?',
                                    topWeight: 1,
                                    renderable: boardRenderable,
                                    onChoice::(which) {
                                        when(which == true) checkFinalChoice(isFirst:true, which:originalChoice);

                                        cardChoices->remove(key:originalChoice);
                                    
                                        windowEvent.queueChoices(
                                            prompt:'Pick which?',
                                            canCancel : false,
                                            topWeight: 1,
                                            leftWeight: 1,
                                            choices: cardChoices,
                                            renderable:boardRenderable,
                                            keep:true,
                                            onChoice::(choice) {
                                                
                                                checkFinalChoice(isFirst:false, which:nameToChoice(name:cardChoices[choice-1]));
                                            }
                                        )
                                    }
                                )
                            }
                        )
                    }
                )
                
            }
        );
    }
    
    windowEvent.queueCustom(
        renderable : {
            render::{canvas.blackout();}
        },
        keep:true,
        jumpTag: 'HighLowButDumb',
        onEnter::{},
        onLeave::{        
            onFinish(partyWins);
        }
    );  
    
    
    nextRound(); 
        
}

@:Gamblist = class(
    define::(this) {
    
        @gameList = [
            high_low_but_dumb,
            sorcerer
        ];
    
        this.interface = {
            
            gameList : {
                get::(value) {
                    return gameList;
                }
            },
            
            
            playGame ::(onFinish) {
                random.pickArrayItem(list:gameList)(onFinish);
            }
        }
    }
);

return Gamblist.new();
