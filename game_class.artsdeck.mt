@:Arts = import(module:'game_database.arts.mt');
@:random = import(module:'game_singleton.random.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

@:HandCard = Object.newType(
    name: 'Wyvern.HandCard',
    layout : {
        id : String,
        owner: Object,
        level : Number
    }
);

@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:CARD_WIDTH = 8;
@:CARD_HEIGHT = 7;
@:renderCard ::<= {
    @:cardSymbols = [
        '//',
        '!!',
        '^^'
    ]

    @:drawRectangle::(x, y, width, height) {
        canvas.movePen(x:x, y:y); canvas.drawRectangle(text: ' ', width:width, height: height);                
        canvas.movePen(x:x, y:y); canvas.drawChar(text:'┌');
        canvas.movePen(x:x+width-1, y:y); canvas.drawChar(text:'┐');
        for(1, width-1)::(i) {
            canvas.movePen(x:x+i, y:y);          canvas.drawChar(text:'─');
            canvas.movePen(x:x+i, y:y+height-1); canvas.drawChar(text:'─');
        }

        canvas.movePen(x:x, y:y+height-1); canvas.drawChar(text:'└');
        canvas.movePen(x:x+width-1, y:y+height-1); canvas.drawChar(text:'┘');
        for(1, height-1)::(i) {
            canvas.movePen(x:x,         y:y+i); canvas.drawChar(text:'│');
            canvas.movePen(x:x+width-1, y:y+i); canvas.drawChar(text:'│');
        }
    
    }


    return ::(x, y, handCard, flipped) {
        @:art = Arts.find(id:handCard.id);
        drawRectangle(x, y, width:CARD_WIDTH, height:CARD_HEIGHT);
        drawRectangle(x:x+1, y:y+1, width:CARD_WIDTH-2, height:(CARD_HEIGHT/2)->floor);


        // inner graphic box


        if (flipped) ::<= {
        } else ::<= {
            @:base = (CARD_HEIGHT/2)->floor+1;            
            canvas.movePen(x:x+1, y:y + base); canvas.drawText(text:cardSymbols[art.kind]);

            if (art.kind == Arts.KIND.ABILITY) ::<= {
                canvas.movePen(x:x+1, y:y+base+1); canvas.drawText(text:'Lv. ' + handCard.level);
            }
        }            
    }
}



@:renderArt::(handCard, topWeight, leftWeight){
    @:art = Arts.find(id:handCard.id);
    canvas.renderTextFrameGeneral(
        topWeight,
        leftWeight,
        lines : canvas.refitLines(:[
            art.name,
            " - " + match(art.kind) {
              (Arts.KIND.ABILITY): "Ability (/)",
              (Arts.KIND.EFFECT): "Effect (^)",
              (Arts.KIND.REACT): "Reaction (!)"
            },
            if (art.kind == Arts.KIND.ABILITY)
                "Lv. " + handCard.level 
            else 
                "",
            "",
            (if (art.isMeta) "A meta Art. " else "") + art.description
        ])
    );
}

@selected = 0;
@:renderHand ::(state){
    selected = (selected % state.hand->size)->abs;
    @x = (canvas.width / 3)->floor;
    @:y = canvas.height - (CARD_HEIGHT+1);
    
    for(0, state.hand->size) ::(i) {
        renderCard(x, y:y + (if (i == selected) -2 else 0), handCard:state.hand[i]);
        x += CARD_WIDTH;
        
        if (i == selected) ::<= {
            renderArt(handCard:state.hand[i], topWeight:0.1);
        }
        
    }
}

@:ArtsDeck = LoadableClass.create(
    name: 'Wyvern.ArtsDeck',
    items : {
        deck : empty,
        hand : empty,
        discard : empty,
        handSize : 5
    },

    statics : {
        synthesizeHandCard ::(id, level) {
            @c = Object.instantiate(type:HandCard);
            c.level = if (level == empty) 1 else level;
            c.id = id;
            return c;
        },
    },

    define:::(this, state) {
        @:addHandCard::(id) {
            @:card = Object.instantiate(type:HandCard);
            card.id = id;
            card.owner = state;
            card.level = 1;
            state.hand->push(value:card);
        }
    
        this.interface = {
            defaultLoad ::{
                state.deck = [];
                state.hand = [];
                state.discard = [];
            },
            
            handSize : {
                set ::(value) <- state.handSize = value,
                get ::<- state.handSize
            },
            
            addArt::(id) {
                @:art = Arts.find(id);
                for(0, match(art.rarity) {
                  (Arts.RARITY.COMMON): 5,
                  (Arts.RARITY.UNCOMMON): 3,
                  (Arts.RARITY.RARE): 2,
                  (Arts.RARITY.EPIC): 1
                }) ::(i) {
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
            
            draw ::{
                if (state.deck->size == 0) ::<= {
                    state.deck = state.discard;
                    state.discard = [];
                    this.shuffle();
                }
                addHandCard(id:state.deck->pop);            
            },
            
            discardFromHandIndex ::(which) {
                @:cardRec = state.hand[which];
                if (cardRec.owner)
                    cardRec.owner.discard->push(value:cardRec.id); // handles if using other peoples cards
                state.hand->remove(key:which);
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
            
            discardRandom ::{
                @:card = random.pickArrayItem(list:state.hand);
                when (card == empty) empty;
                this.discardFromHand(card:card);
            },
            
            discardPlayer :: {
                windowEvent.queueMessage(
                    text: 'Choose a card to discard.'
                );
                this.chooseArtPlayer(
                    isDiscarding: true,
                    trap: true,
                    onChoice::(
                        card,
                        backout
                    ) {
                        this.discardFromHand(card);
                        backout();
                    }
                )
            },
            
            revealArt ::(handCard, prompt) {
                windowEvent.queueMessage(
                    renderable : {
                        render ::{
                            renderCard(
                                x: canvas.width/2 - CARD_WIDTH/2,
                                y: 4,
                                handCard
                            );
                            renderArt(handCard, topWeight:0.3);
                        }
                    },
                    topWeight: 1,
                    text: prompt
                );
            },
            
            view ::(prompt) {
                @bg;
                windowEvent.queueCustom(
                    onEnter::{
                        bg = canvas.addBackground(::{
                            renderHand(:state);
                        });
                    }
                );

                windowEvent.queueChoices(
                    hideWindow : true,
                    keep : true,
                    choices : [...state.hand]->map(::(value) <- value.id),
                    onHover::(choice) {
                        selected = choice-1;
                    },
                    onLeave ::{             
                        canvas.removeBackground(:bg);
                    },
                    canCancel:true,
                    
                    onChoice ::(choice) {                    
                        
                    }                
                );
            },
            
            chooseArtPlayer ::(onChoice, trap, isDiscarding) {
                selected = 0;

                
                @:queueID = windowEvent.addResolveQueue();                
                @bg;
                windowEvent.queueCustom(
                    onEnter::{
                        bg = canvas.addBackground(::{
                            renderHand(:state);
                        });
                        windowEvent.setActiveResolveQueue(:queueID);
                    }
                );
                windowEvent.queueChoices(
                    queueID,
                    hideWindow : true,
                    keep : true,
                    getChoices ::<- [...state.hand]->map(::(value) <- value.id),
                    jumpTag : 'ARTSDECKCHOOSE',
                    onHover::(choice) {
                        selected = choice-1;
                    },
                    onLeave ::{             
                        canvas.removeBackground(:bg);
                    },
                    canCancel:trap != true,
                    onCancel :: {
                        windowEvent.removeResolveQueue(:queueID);                    
                    },
                    
                    onChoice ::(choice) {
                        @:handCard = state.hand[choice-1];
                        @:choices = [if (isDiscarding) 'Discard' else 'Use'];                        
                        @:choiceActions = [
                            ::{
                                windowEvent.removeResolveQueue(:queueID);
                                onChoice(card:handCard, backout ::{
                                    windowEvent.jumpToTag(
                                        name: 'ARTSDECKCHOOSE',
                                        goBeforeTag: true,
                                        doResolveNext: true
                                    );
                                });
                            }
                        ];
                        
                        if (isDiscarding != true && Arts.find(:handCard.id).kind == Arts.KIND.ABILITY) ::<= {
                            choices->push(:'Level up');
                            choiceActions->push(::{
                                // need at least 2 of the same kind
                                when([...state.hand]->filter(::(value) <- value.id == handCard.id)->size < 2) ::<= {
                                    windowEvent.queueMessage(
                                        queueID,
                                        text: 'Leveling Ability Arts requires more than 1 of the same Ability.'
                                    );
                                } 
                                
                                windowEvent.queueMessage(
                                    queueID,
                                    text: 'Choose the ' + Arts.find(id:handCard.id).name + ' Art to combine with this one.'
                                );        
                                
                                @:choiceCards = [...state.hand]->filter(::(value) <- value.id == handCard.id && value != handCard);
                                @:choices = [...choiceCards]->map(::(value) {
                                    @:art = Arts.find(id:value.id);
                                    return art.name + ' - Lv.' + value.level;
                                });
                                
                                windowEvent.queueChoices(
                                    queueID,
                                    choices,
                                    canCancel: true,
                                    onChoice::(choice) {        
                                        handCard.level += choiceCards[choice-1].level;
                                        this.discardFromHand(:choiceCards[choice-1]);
                                        windowEvent.queueMessage(
                                            queueID,
                                            text: 'The card was sacrificed to increase the ' + Arts.find(id:handCard.id).name + ' art to Lv. ' + handCard.level + '.'
                                        );
                                    }
                                );
                            });
                        }
                        windowEvent.queueChoices(
                            choices,
                            queueID,
                            canCancel: true,
                            onChoice ::(choice) {
                                choiceActions[choice-1]();
                            }
                        );
                    }
                );
                
                
                
                
            }
        }
    }
)

return ArtsDeck;
