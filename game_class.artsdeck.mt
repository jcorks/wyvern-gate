@:Arts = import(module:'game_database.arts.mt');
@:random = import(module:'game_singleton.random.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:Profession = import(:'game_database.profession.mt');
@:ArtsTerm = import(:'game_database.artsterm.mt');
@:Effect = import(module:'game_database.effect.mt');



@:ENERGY = {
    A : 0,
    B : 1,
    C : 2,
    D : 3
}

@:HandCard = Object.newType(
  name: 'Wyvern.HandCard',
  layout : {
    id : String,
    owner: Nullable,
    level : Number,
    energy : Number
  }
);

@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:CARD_WIDTH = 8;
@:CARD_HEIGHT = 7;
@:MAX_ART_WIDTH = (canvas.width * 0.7)->floor;
@:renderCard ::<= {
  @:cardSymbols = [
    '//',
    '!!',
    '^^',
    '**',
  ]
  
  @:energySymbols = [
    '_',
    '=',
    '.',
    '~',
  ];

  @:drawRectangle::(x, y, width, height, handCard, showEnergy) {
    canvas.movePen(x:x, y:y); canvas.drawRectangle(text: ' ', width:width, height: height);        
    canvas.movePen(x:x, y:y); canvas.drawChar(text:'┌');
    canvas.movePen(x:x+width-1, y:y); canvas.drawChar(text:'┐');
    for(1, width-1)::(i) {
      canvas.movePen(x:x+i, y:y);      canvas.drawChar(text:'─');
      canvas.movePen(x:x+i, y:y+height-1); canvas.drawChar(text:
          if (showEnergy) 
            (energySymbols)[handCard.energy]
          else 
            '─'
        );
    }

    canvas.movePen(x:x, y:y+height-1); canvas.drawChar(text:'└');
    canvas.movePen(x:x+width-1, y:y+height-1); canvas.drawChar(text:'┘');
    for(1, height-1)::(i) {
      canvas.movePen(x:x,     y:y+i); canvas.drawChar(text:'│');
      canvas.movePen(x:x+width-1, y:y+i); canvas.drawChar(text:'│');
    }
  
  }


  return ::(x, y, handCard, flipped, showEnergy) {
    @:art = Arts.find(id:handCard.id);
    drawRectangle(x, y, width:CARD_WIDTH, height:CARD_HEIGHT, handCard, showEnergy);
    drawRectangle(x:x+1, y:y+1, width:CARD_WIDTH-2, height:(CARD_HEIGHT/2)->floor, handCard, showEnergy);


    // inner graphic box


    if (flipped) ::<= {
    } else ::<= {
      @:base = (CARD_HEIGHT/2)->floor+1;      
      canvas.movePen(x:x+1, y:y + base); canvas.drawText(text:cardSymbols[art.kind]);

      if (art.kind == Arts.KIND.ABILITY) ::<= {
        canvas.movePen(x:x+1, y:y+base+1); canvas.drawText(text:'Lv. ' + handCard.level);
      } else ::<= {
        if (handCard.level > 1) ::<= {
          canvas.movePen(x:x+1, y:y+base+1); canvas.drawText(text:' x' + (handCard.level-1));        
        }
      } 
    }      
  }
}


@:getTraits::(handCard) {
  @:art = Arts.find(:handCard.id);
  when(art.traits == 0) 'None';
  
  @out = '';
  @val = art.traits;
  
  foreach(Arts.TRAITS) ::(k, val) {
    if (art.traits & val)
      out = out + (if (out == '') 
        Arts.traitToString(:val)
      else 
        ', ' + Arts.traitToString(:val))
  }
  
  return out;
  
}


@:getRarity::(rarity) {
  return match(rarity) {
    (0): 'Common',
    (1): 'Uncommon',
    (2): 'Rare',
    (3): 'Epic'
  }
}

@:renderArt::(user, handCard, topWeight, leftWeight, maxWidth, showEnergy){
  if (maxWidth == empty) maxWidth = 1;
  @:art = Arts.find(id:handCard.id);
  @baseDamageMax;
  @baseDamageMin;  
  
  if (user) ::<= {
    baseDamageMin = user.getArtMinDamage(:handCard);
    baseDamageMax = user.getArtMaxDamage(:handCard);
  }
  
  @:en = 'Energy: ' + (['A', 'B', 'C', 'D'])[handCard.energy];

  @:lines = [
    art.name,
    " - Kind: " + match(art.kind) {
      (Arts.KIND.ABILITY): "Ability (//)",
      (Arts.KIND.EFFECT): "Effect (^^)",
      (Arts.KIND.REACTION): "Reaction (!!)"
    },
    " - Rarity: " + getRarity(:art.rarity),
    " - Traits: " + getTraits(:handCard),
    (if (art.kind == Arts.KIND.ABILITY)
      " - (Lv. " + handCard.level + ') - ' + (if(showEnergy)en else '')
    else 
      " - " + (if(showEnergy)en else '')),
    art.description,
    if (user != empty && baseDamageMin != empty) 'Around: ' + baseDamageMin + ' - ' + baseDamageMax + " damage" else '',
  ]
  
  foreach(art.keywords) ::(k, v)  {
    // first check if its an effect 
    @thing = Effect.findSoft(:v);
    
    when(thing) ::<= {
      lines->push(:'[Effect: ' + thing.name + ']: ' + thing.description + (if (thing.stackable == false) ' This is unstackable.' else ''));
    }

    thing = ArtsTerm.find(id:v);
    when(thing) ::<= {
      lines->push(:'[' + thing.name + ']: ' + thing.description);
    }
  }
  canvas.renderTextFrameGeneral(
    topWeight,
    leftWeight,
    maxWidth,
    lines
  );
}

@selected = 0;
@:renderCards ::(user, cards, enabled, showEnergy){
  @index;
  if (enabled != empty) ::<= {
    index = enabled[selected]
  } else 
    index = selected;

  @fitWidth = CARD_WIDTH;

  @x = (canvas.width / 2 - (CARD_WIDTH/2) * cards->size)->floor;
  if (x < 1)
    fitWidth = 3;


  @:y = canvas.height - (CARD_HEIGHT);
  
  for(0, cards->size) ::(i) {
    renderCard(x, y:y + (if (i == index) -1 else 0), handCard:cards[i], showEnergy);
    x += fitWidth;
    
    if (i == index) ::<= {
      renderArt(user, handCard:cards[i], topWeight:0.1, showEnergy);
    }
    
  }
}

@:EVENTS = {
  DRAW : 0,
  DISCARD : 1,
  SHUFFLE : 2,
  LEVEL : 3
}

@:ArtsDeck = LoadableClass.create(
  name: 'Wyvern.ArtsDeck',
  items : {
    deck : empty,
    hand : empty,
    discard : empty,
    profession: '',
    handSize : 5
  },

  statics : {
    artIDtoCount::(id)<- match(Arts.find(:id).rarity) {
      (Arts.RARITY.COMMON): 5,
      (Arts.RARITY.UNCOMMON): 3,
      (Arts.RARITY.RARE): 2,
      (Arts.RARITY.EPIC): 1
    },
  
    EVENTS : {
      get ::<- EVENTS
    },
    
    ENERGY : {
      get ::<- ENERGY
    },
  
    synthesizeHandCard ::(id, level, energy) {
      @c = Object.instantiate(type:HandCard);
      c.level = if (level == empty) 1 else level;
      c.id = id;
      c.energy = if (energy==empty) random.pickArrayItem(:ENERGY->values) else energy;
      return c;
    },
    
    viewCards ::(user, cards, onChoice, canCancel) {
      when(cards->size == 0)
        windowEvent.queueMessage(
          text: user.name + ' has no Arts in their hand.'
        );
    

      windowEvent.queueChoices(
        hideWindow : true,
        keep : true,
        choices : cards->map(::(value) <- value.id),
        onHover::(choice) {
          selected = choice-1;
        },
        renderable : {
          render ::{
            renderCards(user, cards, showEnergy:true);          
          }
        },
        canCancel:if (canCancel == empty) true else canCancel,
        
        onChoice ::(choice) {          
          if (onChoice)
            onChoice(choice);
        }        
      );      
    },    
    
    renderArt : renderArt
  },

  define:::(this, state) {
    @:subscribers = {};
  
    @:addHandCard::(id, noDeck) {
      @:card = Object.instantiate(type:HandCard);
      card.id = id;
      card.owner = if (noDeck == true) empty else state;
      card.level = if (Profession.find(:state.profession).arts->findIndex(:id) == -1) 1 else 2;
      card.energy = random.pickArrayItem(:ENERGY->values);
      state.hand->push(value:card);
      emitEvent(event:EVENTS.DRAW, card);
      return card;
    }
    
    @:emitEvent::(*args) {
      foreach(subscribers) ::(k, fn) {
        fn(*args);
      }
    }
  
    this.interface = {
      defaultLoad ::(profession => String) {
        state.deck = [];
        state.hand = [];
        state.discard = [];
        state.profession = profession;
      },
      
      
      subscribe ::(callback) {
        subscribers->push(:callback);
      },
      
      handSize : {
        set ::(value) <- state.handSize = value,
        get ::<- state.handSize
      },
      
      addArt::(id) {
        @:art = Arts.find(id);
        for(0, ArtsDeck.artIDtoCount(id)) ::(i) {
          state.deck->push(value:id);
        }
      },
      
      deckSize : {
        get ::<- state.deck->size
      },
      
      shuffle ::{
        state.deck = random.scrambled(list:state.deck);
      },
      
      redraw :: {
        for(state.hand->size, state.handSize) ::(i) {
          this.draw();
        }
      },
      
      draw ::(silent){
        if (state.deck->size == 0) ::<= {
          state.deck = state.discard;
          state.discard = [];
          this.shuffle();
          emitEvent(event:EVENTS.SHUFFLE);
        }
        when (state.deck->size == 0) empty;
        return addHandCard(id:state.deck->pop);      
      },
      
      peekTopCards ::(count => Number) {
        @:out = [];
        for(0, if (count > state.deck->size) state.deck->size else count) ::(i) {
          out->push(:state.deck[state.deck->size-(1+i)]);
        }
        return out;
      },
      
      addHandCard::(id) {
        return addHandCard(id);
      },
      
      addHandCardTemporary::(id) {
        return addHandCard(id, noDeck:true);
      },
      
      discardFromHandIndex ::(which) {
        @:cardRec = state.hand[which];
        if (cardRec.owner)
          cardRec.owner.discard->push(value:cardRec.id); // handles if using other peoples cards
        state.hand->remove(key:which);
        emitEvent(event:EVENTS.DISCARD, card:cardRec);
      },

      discardFromHand ::(card) {
        if (card.owner)
          card.owner.discard->push(value:card.id); // handles if using other peoples cards
        state.hand->remove(key:state.hand->findIndex(value:card));
      },
      
      increaseLevel ::(which) {
        state.hand[which].level += 1;
      },
      
      getHandCard ::(which) {
        return state.hand[which];
      },
      
      hand : {
        get ::<- state.hand,
        set ::(value) <- state.hand = value
      },
      
      discardPile : {
        get ::<- state.discard
      },
      
      deckPile : {
        get ::<- state.deck
      },
      
      purge ::(id) {
        state.hand = state.hand->filter(::(value) <- value.id != id);
        state.discard = state.discard->filter(::(value) <- value != id);
        state.deck = state.deck->filter(::(value) <- value != id);
      },
      
      discardRandom ::{
        @:card = random.pickArrayItem(list:state.hand);
        when (card == empty) empty;
        this.discardFromHand(card:card);
        return card;
      },
      
      discardPlayer :: {
        windowEvent.queueNestedResolve(
          onEnter ::{
          
            windowEvent.queueMessage(
              text: 'Choose a card to discard.'
            );
            windowEvent.queueCustom(
              onEnter :: {
                this.chooseArtPlayer(
                  act: 'Discard',
                  canCancel: false,
                  onChoice::(
                    card
                  ) {
                    this.discardFromHand(card);
                  }
                )
              }
            );
          }
        )
      },
      
      revealArt ::(user, handCard, prompt) {
        windowEvent.queueMessage(
          renderable : {
            render ::{
              renderCard(
                x: canvas.width/2 - CARD_WIDTH/2,
                y: 4,
                handCard
              );
              renderArt(user, handCard, topWeight:0.3);
            }
          },
          topWeight: 1,
          text: prompt
        );
      },
      

      
      viewHand ::(user) {
        ArtsDeck.viewCards(user, cards:state.hand);
      },     
       
      containsReaction ::{
        return {:::} {
          foreach(state.hand) ::(k, card) {
            when(Arts.find(:card.id).kind == Arts.KIND.REACTION) ::<= {
              send(:true);
            }
          }
          return false;
        }
      },
      
      chooseDiscardRandom :: {
        when(state.hand->size == 0) empty;
        return random.pickArrayItem(:state.hand).id
      },


      
      chooseDiscardPlayer ::(
        user,
        onChoice,
        onCancel,
        canCancel,
        act,
        filter 
      ) {
        when(state.discard->size == 0) ::<= {
          windowEvent.queueMessage(
            text: 'There are no cards to choose from the discard pile.'
          )
          if (act)
            windowEvent.queueCustom(
              onEnter::{
                onChoice();
              }
            );
        }
        
  
        @:list = if (filter) 
          [...state.discard]->filter(:filter)
        else 
          [...state.discard]   
          
        
        @:choices = [...list]->map(::(value) <- 
          Arts.find(:value).name
        );  
        

        @out;
        windowEvent.queueNestedResolve(
          onLeave :: {
            when (out == empty)
              if (onCancel && canCancel)
                onCancel()
              else 
                empty;
            
            onChoice(id:out);
          },
        
          onEnter :: {
            @selected = 0;
            windowEvent.queueChoices(
              prompt: 'Discarded Arts',
              leftWeight: 1,
              topWeight: 1,
              keep : true,
              renderable : {
                render ::{
                  renderArt(
                    user,
                    handCard:
                      ArtsDeck.synthesizeHandCard(id:list[selected], level:1), 
                    leftWeight:0.4, 
                    topWeight:0.5
                  );            
                }
              },
              choices,
              jumpTag : 'ARTSDISCARDCHOOSE',
              onHover::(choice) {
                selected = choice-1;
              },
              canCancel,
              
              onChoice ::(choice) {
                when(act == empty) empty;

                

                @:choices = [if (act) act else 'Use'];            
                @:choiceActions = [
                  ::{
                    out = list[choice-1]
                    windowEvent.jumpToTag(
                      name: 'ARTSDISCARDCHOOSE',
                      goBeforeTag: true,
                      doResolveNext: true
                    );                    
                  }
                ];

                windowEvent.queueChoices(
                  choices,
                  canCancel: true,
                  onChoice ::(choice) {
                    choiceActions[choice-1]();
                  }
                );
              }
            );
          }
        )
      },
      
      levelUp::(levelIndex, discardIndex) {
        @:handCard = this.hand[levelIndex];
        @:discard = this.hand[discardIndex];
        handCard.level += discard.level;
        this.discardFromHand(:discard);
      
        emitEvent(event:EVENTS.LEVEL, card:handCard);
      },
      
      chooseArtPlayer ::(user, onChoice, onCancel, canCancel, act, filter) {
        selected = 0;
  
        @enabled = [];
        for(0, state.hand->size) ::(i) {
          if(
            filter == empty ||
            filter(:state.hand[i])
          ) enabled->push(:i);
        }
        
        @chosenCard;

        windowEvent.queueNestedResolve(
          onEnter ::{
        
            windowEvent.queueChoices(
              hideWindow : true,
              horizontalFlow: true,
              keep : true,
              onGetChoices :: {
                enabled = [];
                for(0, state.hand->size) ::(i) {
                  if(
                    filter == empty ||
                    filter(:state.hand[i])
                  ) enabled->push(:i);
                }
                return [...enabled]->map(::(value)<- '' + value)
              },
              jumpTag : 'ARTSDECKCHOOSE',
              onHover::(choice) {
                selected = choice-1;
              },
              
              
              renderable : {
                render :: {
                  renderCards(user, cards:state.hand, enabled, showEnergy:true);                
                }
              },
              canCancel,
              
              onChoice ::(choice) {
                when(act == empty) empty;

                @handCard 
                if (enabled == empty)
                  handCard = state.hand[choice-1]
                else
                  handCard = state.hand[enabled[choice-1]]
                ;
                  
                  
                @:choices = [if (act) act else 'Use'];            
                @:choiceActions = [
                  ::{
                    chosenCard = handCard;
                    windowEvent.jumpToTag(
                      name: 'ARTSDECKCHOOSE',
                      goBeforeTag: true,
                      doResolveNext: true
                    );
                  }
                ];
                                
                @:upgradable = Arts.find(:handCard.id).kind == Arts.KIND.ABILITY ||
                               Arts.find(:handCard.id).kind == Arts.KIND.EFFECT;
                if (act == 'Use' && upgradable) ::<= {
                  @:isAbility = Arts.find(:handCard.id).kind == Arts.KIND.ABILITY;
                  choices->push(:if (isAbility) 'Level up' else 'Add counter');
                  choiceActions->push(::{
                    // need at least 2 of the same kind
                    when([...state.hand]->filter(::(value) <- value.energy == handCard.energy)->size < 2) ::<= {
                      windowEvent.queueMessage(
                        text: 'Enhancing Arts requires more than 1 of the same Energy type.'
                      );
                    } 
                    
                    windowEvent.queueMessage(
                      text: 'Choose an Art to combine with this one.'
                    );    
                    
                    @:choiceCards = [...state.hand]->filter(::(value) <- value.energy == handCard.energy && value != handCard);
                    @:choices = [...choiceCards]->map(::(value) {
                      return Arts.find(:value.id).name;
                    });
                    
                    windowEvent.queueChoices(
                      choices,
                      canCancel: true,
                      onChoice::(choice) {    
                        this.levelUp(
                          levelIndex: this.hand->findIndex(:handCard),
                          discardIndex: this.hand->findIndex(:choiceCards[choice-1])
                        );

                        if (isAbility) ::<= {
                          windowEvent.queueMessage(
                            text: 'The Art was sacrificed to increase the ' + Arts.find(id:handCard.id).name + ' art to Lv. ' + handCard.level + '.'
                          );
                        } else ::<= {
                          windowEvent.queueMessage(
                            text: 'The Art was sacrificed to increase the ' + Arts.find(id:handCard.id).name + ' card\'s AP counter to ' + (handCard.level-1) + '.'
                          );                        
                        }
                      }
                    );
                  });
                }
                windowEvent.queueChoices(
                  choices,
                  canCancel: true,
                  onChoice ::(choice) {
                    choiceActions[choice-1]();
                  }
                );
              }
            );
          },
          
          onLeave ::{
            if (chosenCard != empty)
              onChoice(:chosenCard)
            else if (canCancel && onCancel != empty)
              onCancel()
          }
        )
      }
    }
  }
)


return ArtsDeck;
