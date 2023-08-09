@:class = import(module:'Matte.Core.Class');
@:canvas = import(module:'game_singleton.canvas.mt');
@:random = import(module:'game_singleton.random.mt');
@:Deck = import(module:'game_class.deck.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');

// default game is called "Sorcerer"
/*
Sorcerer

- 5 cards per hand 
- the game is played in rounds. Each round, a player is the attacker, and the other is the 
  defender. After the round, the roles switch.
- At the start of the game, you must choose whether to start attacking before drawing.
- The intent of the game is to win 3 points. As each round starts, each player chooses a card 
  and places it face-down. Once both players have chosen, the cards are flipped.
    . IF the attacker's card is of HIGHER value, the attacker wins the round. The cards 
      are kept by the attacker in a separate 2-card piles in an unused play area
      (their respective scoring area) and used to mark the score. Each 2-card pile 
      represents a point. If the attacker doesnt win, the flipped cards are 
      placed in a game-wide discard pile and no scoring occurs.

    . IF the defender loses, the defender MAY choose to increase the stakes 
      by challenging the attacker once more. The attacker MUST accept this second challenge.
      In this case, the current cards are left face up, and each player chooses 
      an additional card form their hand to put face down. Once this is done, 
      the face down cards are revealed and their values are compared.
      
      IF the attacker's second card is of HIGHER value than the defenders second card, 
      the attacker gains one scoring point and the defender loses a scoring point (
      the lost point cards are sent to the game-wide discard pile). 
      If the defender wins the second round, no points are lost or gained. 

    . If at any time (including the second challenge) the same card value is revealed,
      the round is over and no points are lost or gained. 

    . Note that if the the first attack is complete with no cards remaining in-hand,
      a second challenge is impossible

- The player who is the first to win 3 points is the winner. At this time the game ends.
- Once both players have no cards in their hands, and no player has received 3 points,
  Each player draws 5 new cards from the deck.
- If no cards remain in the deck, the discard pile is added to the deck and the deck is 
  shuffled.    









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
