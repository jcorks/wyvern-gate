@:lclass = import(module:'game_function.lclass.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:random = import(module:'game_singleton.random.mt');


@:SUITS_TEXT = [
    '@',
    '^',
    '%',
    '/'    
];

@:VALUES_TEXT = [
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


@:CARD_WIDTH = 8;
@:CARD_HEIGHT = 7;


@Card = lclass(
    name: 'Wyvern.Deck.Card',
    statics : {
        WIDTH : CARD_WIDTH,
        HEIGHT : CARD_HEIGHT
    },
    
    constructor::(suit => Number, value => Number) {
        if (suit < 0 || suit >= SUITS_TEXT->keycount)
            error(message:'Card was made with invalid suit.');

        if (value < 0 || value >= VALUES_TEXT->keycount )
            error(message:'Card was made with invalid value.');


        _.suit = suit;
        _.value = value;
        return this;
    }    
    
    interface : {
        suit : {get ::<- _.suit},
        value : {get ::<- _.value},
        
        string : {
            get ::<- VALUES_TEXT[_.value] + ' ' + SUITS_TEXT[_.suit]
        },
        

        /*
            ┌──────┐
            │4     │
            │^     │
            │      │
            │      │
            │     ^│ 
            │     4│
            └──────┘          
        
        */

        render ::(x, y, flipped) {
            canvas.movePen(x:x, y:y); canvas.drawRectangle(text: ' ', width:CARD_WIDTH, height: CARD_HEIGHT);                
            canvas.movePen(x:x, y:y); canvas.drawChar(text:'┌');
            canvas.movePen(x:x+CARD_WIDTH-1, y:y); canvas.drawChar(text:'┐');
            for(1, CARD_WIDTH-1)::(i) {
                canvas.movePen(x:x+i, y:y);               canvas.drawChar(text:'─');
                canvas.movePen(x:x+i, y:y+CARD_HEIGHT-1); canvas.drawChar(text:'─');
            }

            canvas.movePen(x:x, y:y+CARD_HEIGHT-1); canvas.drawChar(text:'└');
            canvas.movePen(x:x+CARD_WIDTH-1, y:y+CARD_HEIGHT-1); canvas.drawChar(text:'┘');
            for(1, CARD_HEIGHT-1)::(i) {
                canvas.movePen(x:x,              y:y+i); canvas.drawChar(text:'│');
                canvas.movePen(x:x+CARD_WIDTH-1, y:y+i); canvas.drawChar(text:'│');
            }

            if (flipped) ::<= {
            } else ::<= {
                canvas.movePen(x:x+1, y:y+1); canvas.drawText(text:VALUES_TEXT[_.value]);
                canvas.movePen(x:x+CARD_WIDTH-(if(VALUES_TEXT[_.value]->length==1)2 else 3), y:y+CARD_HEIGHT-2); canvas.drawText(text:VALUES_TEXT[value_]);
            
                canvas.movePen(x:x+1, y:y+2); canvas.drawText(text:SUITS_TEXT[_.suit]);
                canvas.movePen(x:x+CARD_WIDTH-2, y:y+CARD_HEIGHT-3); canvas.drawText(text:SUITS_TEXT[_.suit]);                
            }            
        }
    }
);



@Deck = lclass(
    statics : {
        Card : Card
    },
    
    constructor:: {
        _.set = [];
        _.discard = [];
    },

        
    interface : {
        addStandard52 ::{
            @:set = _.set;
            for(0, SUITS_TEXT->keycount)::(suit) {
                for(0, VALUES_TEXT->keycount)::(value) {
                    set->push(value:Card.new(
                        suit, value 
                    ));
                }
            }            
        },
        
        cardsLeft : {
            get ::<- _.set->keycount
        },
        
        drawRandomCard ::{
            when (_.set->keycount == 0) empty;
                
            @card = random.pickArrayItem(list:_.set);
            _.set->remove(value:_.set->findIndex(value:card));
            
            return card;
        },
        
        drawNextCard ::{
            when (_.set->keycount == 0) empty;
            
            @card = _.set->pop;                
            return card;
        },
        
        discard ::(card) {
            _.discard->push(value:card);
        },
        
        shuffle :: {
            @:indices = _.set->keys;
            @:newSet = [];
            foreach(_.set)::(ind, card){
                @:newIndex = random.pickArrayItem(list:indices);
                indices->remove(key:indices->findIndex(value:newIndex));
                newSet[newIndex] = card;
            }
            
            _.set = newSet;
        },
        
        // re-adds all drawn cards back into the deck
        readdCardsFromDiscard ::{
            foreach(_.discard)::(ind, card) {
                _.set->push(value:card);
            }                
            _.discard = [];
        }
    }
);


return Deck;
