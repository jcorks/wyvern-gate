/*
    Wyvern Gate, a procedural, console-based RPG
    Copyright (C) 2023, Johnathan Corkery (jcorkery@umich.edu)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
@:class = import(module:'Matte.Core.Class');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:battlemenu = import(module:'game_function.battlemenu.mt');
@:random = import(module:'game_singleton.random.mt');
@:Party = import(module:'game_class.party.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:StateFlags = import(module:'game_class.stateflags.mt');

@: RESULTS = {
    ALLIES_WIN: 0,
    ENEMIES_WIN: 1,
    NOONE_WIN: 2, // not everyone incapacitated
}

@:Battle = class(
    statics : {
        RESULTS : {get::<-RESULTS}
    },
    
    define:::(this) {
        @allies_;
        @enemies_;
        @:enemyAIs = [];
        @onEnemyTurn_;
        @onAllyTurn_;
        @landmark_;
        @active;
        @alliesWin = false;
        @entityTurn;
        @onTurn_;
        @onAct_;
        
    
        // some actions last multiple turns.
        // indexed by Entity.
        @actions = {} 
        @turn = [];
        @turnIndex = 0;
        @redraw;
        @party_;
        @turnPoppable = [];
        
        @result;
        @externalRenderable;
        @battleEnd;
        
        @:checkRemove :: {
            // see if anyone died
            foreach(turn)::(index, obj) {                    
                when(obj.entity.isDead == false && obj.entity.requestsRemove == false) empty;
                if (obj.isAlly && obj.entity.isDead) party_.remove(member:obj.entity);
                
                @index = allies_->findIndex(value:obj.entity);
                if (index != -1) allies_->remove(key:index);
                index = enemies_->findIndex(value:obj.entity);
                if (index != -1) enemies_->remove(key:index);
                turn = [
                    ...([...allies_]->map(to:::(value)<- {isAlly:true, entity:value})), 
                    ...([...enemies_]->map(to:::(value)<- {isAlly:false, entity:value}))
                ];
                
                index = turnPoppable->findIndex(value:obj);
                if (index != -1) turnPoppable->remove(key:index);

                
            }
        }
        
        @:endTurn ::{
            checkRemove();  
            turnIndex+=1;
            if (turnPoppable->keycount == 0) ::<= {      
                foreach(turn)::(index, obj) {
                    obj.entity.endTurn(battle:this);
                }

                if (onTurn_ != empty)
                    onTurn_();            
                when((allies_->keycount == 0) || allies_->all(condition:::(value) {
                    return value.isIncapacitated();
                })) ::<= {
                    battleEnd();
                }
                when((enemies_->keycount == 0) || enemies_->all(condition:::(value) {
                    return value.isIncapacitated();
                })) ::<={
                    alliesWin = true;
                    battleEnd();
                }
            }
        }
        
        @:nextTurn ::{
            when (turnPoppable->keycount == 0) empty;
            @:obj = turnPoppable[0];
            @:ent = obj.entity;
            turnPoppable->remove(key:0);
            entityTurn = ent;
            
            // act turn can signal to not act
            when(!ent.actTurn()) ::<={
                endTurn();
            }


            // may have died this turn.
            when (ent.isIncapacitated()) ::<={
                endTurn();
            }
            
            // multi turn actions
            if (actions[ent]) ::<= {
                @:action = actions[ent];
                action.turnIndex += 1;
                
                
                ent.useAbility(
                    ability:action.ability,
                    allies:  if(obj.isAlly) allies_  else enemies_,
                    enemies: if(obj.isAlly) enemies_ else allies_,
                    targets:action.targets,
                    turnIndex : action.turnIndex,
                    extraData : action.extraData
                );
                ent.flags.add(flag:StateFlags.WENT);

                
                if (action.turnIndex >= action.ability.durationTurns) ::<= {
                    actions[ent] = empty;
                }
                endTurn();
            } else ::<= {


                // normal turn: request action from the act function
                // given by the caller
                @:act = if (obj.isAlly) onAllyTurn_ else onEnemyTurn_;
                act(
                    battle:this,
                    user:ent,
                    landmark:landmark_,
                    allies:allies_,
                    enemies:enemies_
                );
                if (onAct_) onAct_();
                
            }

        }
        
        @:initTurn ::{
            
            // first reset stats according to current effects 
            foreach(turn)::(index, obj) {
                obj.entity.startTurn();
            }
            
            // then resort based on speed
            turn->sort(
                comparator:::(a, b) {
                    return a.entity.stats.SPD <
                           b.entity.stats.SPD;
                }
            );
            
            turnPoppable = [...turn];
            
            // then do turns.
            // Every turn returns a BattleAction:
            // includes an ability and targetset
            turnIndex = 0;
        }
    

        
        
        @:renderTurnOrder  :: {
            @:lines = [];
            @width = 0;
            foreach(turn)::(index, obj) {
                @line = (if(turnIndex == index) '--> ' else '    ') + obj.entity.name + (if(obj.entity.isIncapacitated()) ' (down)' else '');
                lines->push(value:line);                
                if (width < line->length)
                    width = line->length;
            }      
            width+= 4;
            @:top = 0;
            @:left = canvas.width - (width);
            @:height = lines->keycount+4;
            
            canvas.renderFrame(
                top, left, width, height
            );
            
            canvas.movePen(y:top, x:left+2);
            canvas.drawText(text:'Turn Order');
            
            foreach(lines)::(index, line) {
                canvas.movePen(y:top+index+2, x:left+2);
                canvas.drawText(text:line);
            }
        }
                
        
        @:renderStatusBox::{
            
                
            @lines = [];
            foreach(allies_)::(index, ally) {
                lines->push(value:ally.renderHP() + '  ' + ally.name);// + ' - Lv ' + ally.level);
                lines->push(value:'HP: ' + ally.hp + ' / ' + ally.stats.HP + '    AP: ' + ally.ap + ' / ' + ally.stats.AP);
            }
            lines->push(value:'');
            lines->push(value:'  - vs -   ');
            lines->push(value:'');

            foreach(enemies_)::(index, enemy) {
                lines->push(value:enemy.renderHP() + '  ' + enemy.name);// + ' - Lv ' + enemy.level);
                lines->push(value:'HP: ' + enemy.hp + ' / ' + enemy.stats.HP);
            }


            @:height = lines->keycount+4;
            @width = 0;
            @top = canvas.height/2 - height/2;     
            foreach(lines)::(index, text) <-
                if (text->length > width) 
                    width = text->length
            ;
            
            
            
            canvas.renderFrame(
                top:top,
                left:0,
                width:width + 4,
                height:height
            );
            
            foreach(lines)::(index, line) {
                canvas.movePen(x:2, y:top+index+2);
                canvas.drawText(text:line);
            }
            
        }
        


        
        
        this.interface = {
        
            start ::(
                party => Party.type,
                npcBattle,
            
                allies => Object,
                enemies => Object,
                landmark => Object,
                
                onTurn,
                onAct,
                noLoot,
                exp,
                
                renderable,
                
                onStart,
                onEnd => Function
            ) {
                onTurn_ = onTurn;
                onAct_ = onAct;
                allies = [...allies];
                enemies = [...enemies];
                canvas.pushState();
                turn = [];
                turnIndex = 0;
                active = true;
                externalRenderable = renderable;
                
                @:isPlayerParty = party.isMember(entity:allies[0]);
            
                party_ = party;
                foreach(enemies)::(index, enemy) {
                    enemy.battleStart(
                        battle: this,
                        allies: enemies,
                        enemies: allies
                    );
                }
                foreach(allies)::(index, ally) {
                    ally.battleStart(
                        battle: this,
                        enemies: enemies,
                        allies: allies
                    );
                }

                @:onAllyTurn = ::(battle, user, landmark, allies, enemies) {
                    if (party.isMember(entity:user))
                        battlemenu(
                            party:party_,
                            battle,
                            user,
                            landmark,
                            allies,
                            enemies 
                        )
                    else 
                        user.battleAI.takeTurn(battle)
                    ;
                }
                
                
                @:onEnemyTurn = ::(battle, user, landmark, allies, enemies) {
                    user.battleAI.takeTurn(battle);
                }

                if (npcBattle == empty) ::<= {
                    windowEvent.queueMessage(
                        text: if (enemies->keycount == 1) 
                            "You're confronted by someone!"
                        else 
                            "You're confronted by " + enemies->keycount + ' enemies!'
                    );    
                    
                    foreach(enemies)::(index, enemy) {
                        windowEvent.queueMessage(
                            text: enemy.name + '(' + enemy.stats.HP + ' HP) blocks your path!'
                        );                    
                    }
                }
                allies_ = allies;
                enemies_ = enemies;
                onAllyTurn_ = onAllyTurn;
                onEnemyTurn_ = onEnemyTurn;
                landmark_ = landmark;
                
                foreach(allies)::(k, v) {
                    turn->push(value:{
                        isAlly: true,
                        entity: v
                    });
                }

                foreach(enemies)::(k, v) {
                    turn->push(value:{
                        isAlly: false,
                        entity: v
                    });
                }
                

                battleEnd = ::{
                    breakpoint();
                    @:finishEnd :: {
                        allies_ = [];
                        enemies_ = [];
                        active = false;
                        onEnd(result);                    
                        if (windowEvent.canJumpToTag(name:'Battle'))                                            
                            windowEvent.jumpToTag(name:'Battle', goBeforeTag:true, doResolveNext:true);
                    
                    }
                    result = match(true) {
                      (alliesWin):      RESULTS.ALLIES_WIN,
                      default:          RESULTS.ENEMIES_WIN
                    }
                    
                    foreach(allies)::(k, v) {
                        v.battleEnd();
                    }

                    foreach(enemies)::(k, v) {
                        v.battleEnd();
                    }
                                
                    
                    when (npcBattle != empty) ::<= {
                        active = false;
                        windowEvent.queueMessage(text: 'The battle is over.');
                        finishEnd();
                    } 


                    if (alliesWin == true) ::<= {            




                            
                        if (noLoot == empty) ::<= {
                            @:loot = [];
                            foreach(enemies)::(index, enemy) {
                                foreach(enemy.inventory.items)::(index, item) {
                                    if (Number.random() > 0.7 && loot->keycount == 0) ::<= {
                                        loot->push(value:enemy.inventory.remove(item));
                                    }
                                }
                            }
                            
                            if (loot->keycount > 0) ::<= {
                                windowEvent.queueMessage(text: 'It looks like they dropped some items during the fight...');
                                @message = 'The party found:\n\n';
                                foreach(loot)::(index, item) {
                                    @message = 'The party found ' + correctA(word:item.name);
                                    windowEvent.queueMessage(text: message);
                                    party.inventory.add(item);
                                }
                            }
                        }
                        
                        windowEvent.queueMessage(
                            text: 'The battle is won.',
                            onLeave ::{

                                breakpoint();
                                @:Entity = import(module:'game_class.entity.mt');
                                @hasWeapon = false;
                                foreach(allies_)::(index, ally) {   
                                    @:wep = ally.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L);
                                    if (wep.name != 'None' && wep.canGainIntuition()) 
                                        hasWeapon = true;
                                };



                                if (hasWeapon && random.flipCoin()) ::<= {
                                    windowEvent.queueMessage(text:'The party feels their intuition with their weapons grow.');
                                    windowEvent.queueMessage(text:'The party must choose a way to channel this intuition.');
                                    @:fWhich = random.integer(from:0, to:2);


                                    @:renderTextBox ::(leftWeight, topWeight, lines, prompt) {

                                        @width = if (prompt == empty) 0 else prompt->length;
                                        foreach(lines)::(index, line) {
                                            if (line->length > width) width = line->length;
                                        }
                                        
                                        @left   = (canvas.width - (width+4))*leftWeight;
                                        width   = width + 4;
                                        @top    = (canvas.height - (lines->keycount + 4)) * topWeight;
                                        @height = lines->keycount + 4;
                                        
                                        if (top < 0) top = 0;
                                        if (left < 0) left = 0;
                                        
                                        
                                        canvas.renderFrame(top, left, width, height);

                                        // render text:
                                        
                                        foreach(lines)::(index, line) {
                                            canvas.movePen(x: left+2, y: top+2+index);
                                            canvas.drawText(text:line);
                                        }
                                        if (prompt != empty) ::<= {
                                            canvas.movePen(x: left+2, y:top);
                                            canvas.drawText(text:prompt);
                                        }

                                    }




                                    windowEvent.queueChoices(
                                        prompt: 'Which way?',
                                        choices : [
                                            'Inward',
                                            'Skyward',
                                            'Forward'
                                        ],
                                        canCancel: false,
                                        leftWeight: 1,
                                        topWeight : 1,
                                        
                                        renderable : {
                                            render ::{




                                                renderTextBox(
                                                    prompt:'Inward Intuition', 
                                                    lines:[
                                                        'The way inward focuses your inner perception',
                                                        'your awareness of self when wielding the weapon. ',
                                                    ],
                                                    leftWeight: 0.5,
                                                    topWeight: 0.0
                                                );

                                                renderTextBox(prompt:'Skyward Intuition',
                                                    lines: [
                                                        'The way skyward focuses your perception of the   ',
                                                        'world around you, making the weapon a better ',
                                                        'extension of the self.',
                                                    ],
                                                    leftWeight: 0.5,
                                                    topWeight: 0.4
                                                );

                                                renderTextBox(prompt:'Forward Intuition', 
                                                    lines: [
                                                        'The way forward focuses your perception of a   ',
                                                        'better future, striving to work to meet tomorrows',
                                                        'challenges better with the weapon.'
                                                    ],
                                                    leftWeight: 0.5,
                                                    topWeight: 0.8
                                                );
                                            }
                                        },
                                        
                                        onChoice::(choice) {
                                            when(random.flipCoin()) ::<= {
                                                windowEvent.queueMessage(text:'The party is close to a revelation, but not quite there.');                                                                            
                                                finishEnd();
                                            }
                                            windowEvent.queueMessage(text:'The party wields the weapons better through their intuition.');                                                                            
                                            
                                            @:choice = match(choice) {
                                                // inward -> AP, INT, DEF
                                                (1): random.pickArrayItem(list:[1, 4, 3]),
                                                // skyward -> DEX, SPD, LUK 
                                                (2): random.pickArrayItem(list:[6, 7, 5]),
                                                // forward -> ATK, HP 
                                                (3): random.pickArrayItem(list:[2, 0])
                                            };


                                            foreach(allies_)::(index, ally) {   
                                                @:wep = ally.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L);
                                                when (wep.name == 'None' || !wep.canGainIntuition()) empty;

                                                @:oldAllyStats = StatSet.new();
                                                oldAllyStats.state = ally.stats.state;
                                                @:stats = wep.stats;                             
                                                @:oldStats = StatSet.new();
                                                oldStats.add(stats);
                                                stats.add(stats:StatSet.new(
                                                    HP: if (choice == 0) 15 else 0,
                                                    AP: if (choice == 1) 15 else 0,
                                                    ATK: if (choice == 2) 15 else 0,
                                                    DEF: if (choice == 3) 15 else 0,
                                                    INT: if (choice == 4) 15 else 0,
                                                    LUK: if (choice == 5) 15 else 0,
                                                    DEX: if (choice == 6) 15 else 0,
                                                    SPD: if (choice == 7) 15 else 0
                                                ));
                                                
                                                oldStats.printDiffRate(other:stats, prompt:wep.name);
                                                ally.recalculateStats();
                                                oldAllyStats.printDiff(other:ally.stats, prompt:ally.name);
                                            }
                                            finishEnd();
                                        }
                                    )
                                } else ::<= {
                                    finishEnd();
                                
                                }
                            
                            }
                        );

                                       

                    } else ::<= {
                        if (party.members->all(condition:::(value) <- value.isIncapacitated())) ::<= {
                            windowEvent.queueMessage(text: 'The battle is lost.');
                            windowEvent.queueNoDisplay(onEnter::{
                                onEnd(result); 
                                if (windowEvent.canJumpToTag(name:'Battle'))                                               
                                    windowEvent.jumpToTag(name:'Battle', goBeforeTag:true, doResolveNext:true);
                            });                       
                            
                        }
                    }
                }


                @started = false;
                windowEvent.queueNoDisplay(
                    renderable :{
                        render::{
                            if (externalRenderable)
                                externalRenderable.render();
                            this.render();
                            return windowEvent.RENDER_AGAIN;
                        }
                    },
                    keep: true,
                    jumpTag: 'Battle',
                    onEnter::{
                        if (!started && onStart) ::<= {
                            onStart();
                            started = true;
                        }
                        
                        if (turnPoppable->keycount == 0)
                            initTurn();  
                        nextTurn();
                    }
                );

                return this;            
            },        
        
            result : {
                get ::<- result
            },
            
            enemies : {
                get ::<- [...enemies_]
            },

            allies : {
                get ::<- [...allies_]
            },
            
            isActive : {
                get ::<- active
            },
            
            join ::(enemy, ally) {
                if (enemy != empty) ::<= {
                    when (enemies_->findIndex(value:enemy) != -1) empty;
                    windowEvent.queueMessage(text:enemy.name + ' joins the fray!');
                    enemy.battleStart(
                        battle: this,
                        allies: enemies_,
                        enemies: allies_
                    );
                    enemies_->push(value:enemy);
                    turn->push(value:{
                        isAlly: false,
                        entity: enemy
                    });
                }
                if (ally != empty) ::<= {
                    when (allies_->findIndex(value:ally) != -1) empty;
                    windowEvent.queueMessage(text:ally.name + ' joins the fray!');
                    allies_->push(value:ally);
                    ally.battleStart(
                        battle: this,
                        enemies: enemies_,
                        allies: allies_
                    );
                    turn->push(value:{
                        isAlly: true,
                        entity: ally
                    });
                }
                    
            },
            
            render :: {
                renderStatusBox();
                renderTurnOrder();
            },
            
            entityCommitAction::(action) {
                entityTurn.useAbility(
                    ability:action.ability,
                    targets:action.targets,
                    turnIndex : action.turnIndex,
                    extraData : action.extraData
                );
                entityTurn.flags.add(flag:StateFlags.WENT);
                if (action.ability.name != 'Attack' &&
                    action.ability.name != 'Defend' &&
                    action.ability.name != 'Use Item')
                    entityTurn.flags.add(flag:StateFlags.ABILITY);
        
                if (action.ability.durationTurns > 0) ::<= {
                    action.turnIndex = 0;
                    actions[entityTurn] = action;
                }  
                
                windowEvent.queueNoDisplay(
                    onEnter ::{
                        endTurn();
                    }
                );
            },
            

        }
    }
);

return Battle;
