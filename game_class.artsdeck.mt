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
@:MAX_ART_WIDTH = (canvas.width * 0.7)->floor;
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

@:renderArt::(handCard, topWeight, leftWeight){
    @:art = Arts.find(id:handCard.id);
    canvas.renderTextFrameGeneral(
        topWeight,
        leftWeight,
        lines : canvas.refitLines(
            maxWidth : MAX_ART_WIDTH,
            input : [
                art.name,
                " - Kind: " + match(art.kind) {
                  (Arts.KIND.ABILITY): "Ability (//)",
                  (Arts.KIND.EFFECT): "Effect (^^)",
                  (Arts.KIND.REACTION): "Reaction (!!)"
                },
                " - Rarity: " + getRarity(:art.rarity),
                " - Traits: " + getTraits(:handCard),
                if (art.kind == Arts.KIND.ABILITY)
                    "Lv. " + handCard.level 
                else 
                    "",
                "",
                art.description
            ]
        )
    );
}

@selected = 0;
@:renderHand ::(state, enabled){
    @index;
    if (enabled != empty) ::<= {
        index = enabled[selected]
    } else 
        index = selected;


    @x = (canvas.width / 3)->floor;
    @:y = canvas.height - (CARD_HEIGHT+1);
    
    for(0, state.hand->size) ::(i) {
        renderCard(x, y:y + (if (i == index) -2 else 0), handCard:state.hand[i]);
        x += CARD_WIDTH;
        
        if (i == index) ::<= {
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
        
        renderArt : renderArt
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
                    act: 'Discard',
                    canCancel: false,
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
            

            
            viewHand ::(prompt) {
                @bg;
                windowEvent.queueCustom(
                    onEnter::{
                        bg = canvas.addBackground(::{
                            renderHand(state);
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
            
            chooseDiscard ::(
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
                                onChoice(backout::{});
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
                

                @:queueID = windowEvent.addResolveQueue();                
                windowEvent.queueCustom(
                    onEnter::{
                        windowEvent.setActiveResolveQueue(:queueID);
                    }
                );
                
                @selected = 0;
                windowEvent.queueChoices(
                    queueID,
                    prompt: 'Discarded Arts',
                    leftWeight: 1,
                    topWeight: 1,
                    keep : true,
                    renderable : {
                        render ::{
                            breakpoint();
                            renderArt(handCard:
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
                    onCancel :: {
                        windowEvent.removeResolveQueue(:queueID);    
                        if (onCancel)
                            onCancel();                
                    },
                    
                    onChoice ::(choice) {
                        when(act == empty) empty;

                        

                        @:choices = [if (act) act else 'Use'];                        
                        @:choiceActions = [
                            ::{
                                windowEvent.removeResolveQueue(:queueID);
                                onChoice(id:list[choice-1], backout ::{
                                    windowEvent.jumpToTag(
                                        name: 'ARTSDISCARDCHOOSE',
                                        goBeforeTag: true,
                                        doResolveNext: true
                                    );
                                });
                            }
                        ];

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
            },
            
            
            
            chooseArtPlayer ::(onChoice, onCancel, canCancel, act, filter) {
                selected = 0;
    
                @enabled = [];
                for(0, state.hand->size) ::(i) {
                    if(
                        filter == empty ||
                        filter(:state.hand[i])
                    ) enabled->push(:i);
                }
                
                @:queueID = windowEvent.addResolveQueue();                
                @bg;
                windowEvent.queueCustom(
                    onEnter::{
                        bg = canvas.addBackground(::{
                            renderHand(state, enabled);
                        });
                        windowEvent.setActiveResolveQueue(:queueID);
                    }
                );
                windowEvent.queueChoices(
                    queueID,
                    hideWindow : true,
                    keep : true,
                    onGetChoices ::<- [...enabled]->map(::(value)<- '' + value),
                    jumpTag : 'ARTSDECKCHOOSE',
                    onHover::(choice) {
                        selected = choice-1;
                    },
                    onLeave ::{             
                        canvas.removeBackground(:bg);
                    },
                    canCancel,
                    onCancel :: {
                        windowEvent.removeResolveQueue(:queueID);    
                        if (onCancel)
                            onCancel();                
                    },
                    
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
                        
                        if (act == 'Use' && Arts.find(:handCard.id).kind == Arts.KIND.ABILITY) ::<= {
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