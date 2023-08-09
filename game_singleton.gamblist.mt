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
  playing deck. The intent of the game is to get 3 points. 
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

- Each player's points are kept in separate, 2-card piles 
  in an unused play area (their respective scoring area) and are used
  to mark the score. Each 2-card pile represents a point. If the
  attacker doesnt win, the flipped cards are placed in a game-wide
  discard pile and no scoring occurs.



Playing the Game

- The intent of the game is to win 3 points. The player who is the 
  first to win 3 points is the winner. At this time the game ends.

- The game is played in rounds. As each round starts, each player chooses
  a card from their hand and places it face-down. Once both players have
  chosen, the cards are flipped. This is called a "challenge".
  
    . IF the attacker's card is of HIGHER value, the attacker
      wins the challenge. 

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
      the round is over and the attacker gains a point.
      
    . IF the attacker DOESN'T win (the first challenge), no scoring occurs.

    . IF at any challenge the same card value is revealed, the round 
      is over and no points are lost or gained. 

    . NOTE that if the the first attack is complete with no cards 
      remaining in-hand, a second challenge is impossible and the 
      round is over.

- Once both players have no cards in their hands, and no player has 
  received 3 points, each player draws 5 new cards from the deck.
  
- If no cards remain in the deck, the discard pile is placed facedown 
  and shuffled. This pile becomes the new deck.














*/
@sorcerer ::<= {

    return ::(onFinish) {

        @deck = Deck.new();
        deck.addStandard52();
        deck.shuffle();

        @playerHand = [];
        @gamblistHand = [];
    
        
        
        
    }
}

@:Gamblist = class(
    define::(this) {
    
        @gameList = [
            sorcerer
        ];
    
        this.interface = {
            /*
            gameList : {
                set::(value) {
                
                }
            },
            */
            
            playGame ::(onFinish) {
                random.pickArrayItem(list:gameList)(onFinish);
            }
        }
    }
);

return Gamblist.new();
