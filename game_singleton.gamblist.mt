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
- The intent of the game is to win 3 rounds. Each round, a player chooses a card 
  and places it face-down. Once both players have chosen, the cards are flipped.
    . IF the attacker's card is of HIGHER value, the attacker wins the round. The cards 
      are kept by the attacker in a separate pile (their respective scoring pile)
      and used to mark the score. If the attacker doesnt win, 
      the cards are placed in a game-wide discard pile and no scoring occurs.
      
- the player who is the first to win 3 scores is the winner
- Once both players have no cards in their hands, and no player has received 3 scores,
  5 new cards are drawn from the deck.
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
        
        @partyAttacker = if (

        
        @:renderCards = ::{        
            /*




            */  
            canvas.blackout();
            cardLeft.render(
                x: canvas.width / 2 - Deck.Card.WIDTH*2,
                y: canvas.height / 2 - Deck.Card.HEIGHT/2
            );

            cardRight.render(
                flipped:!cardRevealed,
                x: canvas.width / 2 + Deck.Card.WIDTH*2,
                y: canvas.height / 2 - Deck.Card.HEIGHT/2
            );

        }


        windowEvent.queueNoDisplay(
            keep:true,
            jumpTag: 'HighLow',
            renderable : {
                render:renderCards
            },
            onEnter::{},
            onLeave::{}
        );
        
        
        @:doTurn = ::{
            cardRevealed = false;
            deck.resetCards();
            deck.shuffle();
            cardLeft = deck.drawNextCard();
            cardRight = deck.drawNextCard();
            windowEvent.queueMessage(
                text:'Here\'s the guess...',
                renderable : {
                    render:renderCards
                },
                onLeave ::{
                    cardRevealed = true;
                    windowEvent.queueMessage(
                        text: '',
                        renderable : {
                            render:renderCards
                        },
                        onLeave ::{
                            doTurn();
                        }
                    );
                }
            );
        }
        doTurn();        
        
        
        
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
