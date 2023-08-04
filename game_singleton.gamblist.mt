
// default game is High-Low
// kinda basic, but good enough for now.
@defaultGame <= {
    @:SUITS = [
        '@',
        '^',
        '%',
        '<>'    
    ];

    @:VALUES = [
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '10',
        'J',
        'Q',
        'K',            
        'A',
    ];
    
    
    @:makeCard = ::(suit => Number, value => Number) {
        return {
            suit : suit,
            value: value
        }
    }
    
    @:makeDeck = ::{
        @:deck = [];
        for(0, SUITS->keycount)::(suit) {
            for(0, VALUES->keycount)::(value) {
                deck->push(value:makeCard(
                    suit, value 
                ));
            }
        }
        return deck;
    }

    return ::(onFinish) {

        @cardLeft;
        @cardRight;
        @:renderCards = ::{
            @:CARD_WIDTH = 8;
            @:CARD_HEIGHT = 8'
            @:renderCard = ::(x, y, card => Object){
                for(0, CARD_WIDTH)::(i) {
                    canvas->movePen(x:x+i, y:0);             canvas.drawChar(text:'-');
                    canvas->movePen(x:x+i, y:CARD_HEIGHT-1); canvas.drawChar(text:'-');
                }

                for(0, CARD_HEIGHT)::(i) {
                    canvas->movePen(x:0,            y:y+i); canvas.drawChar(text:'|');
                    canvas->movePen(x:CARD_WIDTH-1, y:y+i); canvas.drawChar(text:'|');
                }

                if (cardLeft == empty) ::<= {
                } else ::<= {
                    canvas->movePen(x:1, y:1); canvas.drawText(text:VALUES[card.value]);
                    canvas->movePen(x:CARD_WIDTH-1, y:CARD_HEIGHT-1); canvas.drawText(text:VALUES[card.value]);
                
                    canvas->movePen(x:1, y:2); canvas.drawText(text:SUITS[card.suit]);
                    canvas->movePen(x:CARD_WIDTH-1, y:CARD_HEIGHT-2); canvas.drawText(text:SUITS[card.suit]);                
                }
            }
        
            /*
                --------
                |4     |
                |^     |
                |      |
                |      |
                |     ^| 
                |     4|
                --------

                --------
                |4     |
                |@     |
                |      |
                |      |
                |     @| 
                |     4|
                --------


                --------
                |4     |
                |%     |
                |      |
                |      |
                |     %| 
                |     4|
                --------


                --------
                |4     |
                |<>    |
                |      |
                |      |
                |    <>| 
                |     4|
                --------



            */  
            canvas.blackout();
            renderCard(
                x: canvas.width / 2 - CARD_WIDTH*2,
                y: canvas.height / 2 - CARD_HEIGHT/2
                card:cardLeft
            );

            renderCard(
                x: canvas.width / 2 + CARD_WIDTH*2,
                y: canvas.height / 2 - CARD_HEIGHT/2
                card:cardRight
            );

        }


        windowEvent.queueDisplay(
            keep:true,
            jumpTag: 'HighLow',
            renderable : {
                render:renderCards
            }
        );
        
        
        
        
        
        
        
    }
}

@:Gamblist = class(
    define::(this) {
    
        @gameList = [
            defaultGame;
        ];
    
        this.interface = ::{
            gameList : {
                set::(value) {
                
                }
            },
            
            
            playGame ::(onFinish) {
                
            }
        }
    }
);
