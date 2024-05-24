@:class = import(module:'Matte.Core.Class');
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


@Card = class(
  name: 'Wyvern.Deck.Card',
  statics : {
    WIDTH : {get::<- CARD_WIDTH},
    HEIGHT : {get::<- CARD_HEIGHT}
  },
  define:::(this) {
    @suit_;
    @value_;
    
    this.constructor = ::(suit => Number, value => Number) {
      if (suit < 0 || suit >= SUITS_TEXT->keycount)
        error(message:'Card was made with invalid suit.');

      if (value < 0 || value >= VALUES_TEXT->keycount )
        error(message:'Card was made with invalid value.');


      suit_ = suit;
      value_ = value;
      return this;
    }
    
    
    this.interface = {
      suit : {get ::<- suit_},
      value : {get ::<- value_},
      
      string : {
        get ::<- VALUES_TEXT[value_] + ' ' + SUITS_TEXT[suit_]
      },
      

      /*
        ┌──────┐
        │4   │
        │^   │
        │    │
        │    │
        │   ^│ 
        │   4│
        └──────┘      
      
      */

      render ::(x, y, flipped) {
        canvas.movePen(x:x, y:y); canvas.drawRectangle(text: ' ', width:CARD_WIDTH, height: CARD_HEIGHT);        
        canvas.movePen(x:x, y:y); canvas.drawChar(text:'┌');
        canvas.movePen(x:x+CARD_WIDTH-1, y:y); canvas.drawChar(text:'┐');
        for(1, CARD_WIDTH-1)::(i) {
          canvas.movePen(x:x+i, y:y);         canvas.drawChar(text:'─');
          canvas.movePen(x:x+i, y:y+CARD_HEIGHT-1); canvas.drawChar(text:'─');
        }

        canvas.movePen(x:x, y:y+CARD_HEIGHT-1); canvas.drawChar(text:'└');
        canvas.movePen(x:x+CARD_WIDTH-1, y:y+CARD_HEIGHT-1); canvas.drawChar(text:'┘');
        for(1, CARD_HEIGHT-1)::(i) {
          canvas.movePen(x:x,        y:y+i); canvas.drawChar(text:'│');
          canvas.movePen(x:x+CARD_WIDTH-1, y:y+i); canvas.drawChar(text:'│');
        }

        if (flipped) ::<= {
        } else ::<= {
          canvas.movePen(x:x+1, y:y+1); canvas.drawText(text:VALUES_TEXT[value_]);
          canvas.movePen(x:x+CARD_WIDTH-(if(VALUES_TEXT[value_]->length==1)2 else 3), y:y+CARD_HEIGHT-2); canvas.drawText(text:VALUES_TEXT[value_]);
        
          canvas.movePen(x:x+1, y:y+2); canvas.drawText(text:SUITS_TEXT[suit_]);
          canvas.movePen(x:x+CARD_WIDTH-2, y:y+CARD_HEIGHT-3); canvas.drawText(text:SUITS_TEXT[suit_]);        
        }      
      }
    }
  }
);



@Deck = class(
  statics : {
    Card : {
      get ::<- Card
    }
  },

  define:::(this) {
    @set = [];
    @discard = [];
    
    
    this.interface = {
      addStandard52 ::{
        for(0, SUITS_TEXT->keycount)::(suit) {
          for(0, VALUES_TEXT->keycount)::(value) {
            set->push(value:Card.new(
              suit, value 
            ));
          }
        }      
      },
      
      cardsLeft : {
        get ::<- set->keycount
      },
      
      drawRandomCard ::{
        when (set->keycount == 0) empty;
          
        @card = random.pickArrayItem(list:set);
        set->remove(value:set->findIndex(value:card));
        
        return card;
      },
      
      drawNextCard ::{
        when (set->keycount == 0) empty;
        
        @card = set->pop;        
        return card;
      },
      
      discard ::(card) {
        discard->push(value:card);
      },
      
      shuffle :: {
        @:indices = set->keys;
        @:newSet = [];
        foreach(set)::(ind, card){
          @:newIndex = random.pickArrayItem(list:indices);
          indices->remove(key:indices->findIndex(value:newIndex));
          newSet[newIndex] = card;
        }
        
        set = newSet;
      },
      
      // re-adds all drawn cards back into the deck
      readdCardsFromDiscard ::{
        foreach(discard)::(ind, card) {
          set->push(value:card);
        }        
        discard = [];
      }
      
    }
    
  }

);


return Deck;
