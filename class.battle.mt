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
@:dialogue = import(module:'singleton.dialogue.mt');
@:canvas = import(module:'singleton.canvas.mt');
@:StatSet = import(module:'class.statset.mt');
@:battlemenu = import(module:'function.battlemenu.mt');
@:Random = import(module:'singleton.random.mt');
@:Party = import(module:'class.party.mt');


@: RESULTS = {
    ALLIES_WIN: 0,
    ENEMIES_WIN: 1,
    NOONE_WIN: 2, // not everyone incapacitated
};

@:Battle = class(
    statics : {
        RESULTS : RESULTS
    },
    
    define:::(this) {
        @allies_;
        @enemies_;
        @:enemyAIs = [];
        @onEnemyTurn_;
        @onAllyTurn_;
        @landmark_;
        @active;
    
        // some actions last multiple turns.
        // indexed by Entity.
        @actions = {}; 
        @turn = [];
        @turnIndex = 0;
        @redraw;
        @party_;
        
        @result;
        
        
        
        @:checkRemove :: {
            // see if anyone died
            turn->foreach(do:::(index, obj) {                    
                when(obj.entity.isDead == false && obj.entity.requestsRemove == false) empty;
                if (obj.isAlly && obj.entity.isDead) party_.remove(member:obj.entity);
                
                @index = allies_->findIndex(value:obj.entity);
                if (index != -1) allies_->remove(key:index);
                @index = enemies_->findIndex(value:obj.entity);
                if (index != -1) enemies_->remove(key:index);
                turn = [
                    ...([...allies_]->map(to:::(value) {return {isAlly:true, entity:value};})), 
                    ...([...enemies_]->map(to:::(value){return {isAlly:false, entity:value};}))
                ];
                
            });
            redraw();        
        };
        
        @:doTurn ::{
            
            // first reset stats according to current effects 
            turn->foreach(do:::(index, obj) {
                obj.entity.startTurn();
            });
            
            // then resort based on speed
            turn->sort(
                comparator:::(a, b) {
                    return a.entity.stats.SPD <
                           b.entity.stats.SPD;
                }
            );
            
            
            // then do turns.
            // Every turn returns a BattleAction:
            // includes an ability and targetset
            turn->foreach(do:::(index, obj) {
                @:ent = obj.entity;
                turnIndex = index;
                
                // act turn can signal to not act
                when(!ent.actTurn()) checkRemove();


                // may have died this turn.
                when (ent.isIncapacitated()) checkRemove();
                this.prompt();
                
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
                    redraw();

                    
                    if (action.turnIndex >= action.ability.durationTurns) ::<= {
                        actions[ent] = empty;
                    };
                } else ::<= {


                    // normal turn: request action from the act function
                    // given by the caller
                    @:act = if (obj.isAlly) onAllyTurn_ else onEnemyTurn_;
                    @:action = act(
                        battle:this,
                        user:ent,
                        landmark:landmark_,
                        allies:allies_,
                        enemies:enemies_
                    );
                    ent.useAbility(
                        ability:action.ability,
                        targets:action.targets,
                        turnIndex : action.turnIndex,
                        extraData : action.extraData
                    );
            
                    if (action.ability.durationTurns > 0) ::<= {
                        action.turnIndex = 0;
                        actions[ent] = action;
                    };
                };

                checkRemove();
                
            });
            
            
            turn->foreach(do:::(index, obj) {
                obj.entity.endTurn();
            });

            
        
        };
    

        
        
        @:renderTurnOrder  :: {
            @:lines = [];
            @width = 0;
            turn->foreach(do:::(index, obj) {
                @line = (if(turnIndex == index) '--> ' else '    ') + obj.entity.name + (if(obj.entity.isIncapacitated()) ' (down)' else '');
                lines->push(value:line);                
                if (width < line->length)
                    width = line->length;
            });                
            width+= 4;
            @:top = 0;
            @:left = canvas.width - (width);
            @:height = lines->keycount+4;
            
            canvas.renderFrame(
                top, left, width, height
            );
            
            canvas.movePen(y:top, x:left+2);
            canvas.drawText(text:'Turn Order');
            
            lines->foreach(do:::(index, line) {
                canvas.movePen(y:top+index+2, x:left+2);
                canvas.drawText(text:line);
            });
        };
                
        
        @:renderStatusBox::{
            
                
            @lines = [];
            allies_->foreach(do:::(index, ally) {
                lines->push(value:ally.renderHP() + '  ' + ally.name);// + ' - Lv ' + ally.level);
                lines->push(value:'HP: ' + ally.hp + ' / ' + ally.stats.HP + '    MP: ' + ally.mp + ' / ' + ally.stats.MP);
            });
            lines->push(value:'');
            lines->push(value:'  - vs -   ');
            lines->push(value:'');

            enemies_->foreach(do:::(index, enemy) {
                lines->push(value:enemy.renderHP() + '  ' + enemy.name);// + ' - Lv ' + enemy.level);
                lines->push(value:'HP: ' + enemy.hp + ' / ' + enemy.stats.HP);
            });


            @:height = lines->keycount+4;
            @width = 0;
            @top = canvas.height/2 - height/2;     
            lines->foreach(do:::(index, text) <-
                if (text->length > width) 
                    width = text->length
            );
            
            
            
            canvas.renderFrame(
                top:top,
                left:0,
                width:width + 4,
                height:height
            );
            
            lines->foreach(do:::(index, line) {
                canvas.movePen(x:2, y:top+index+2);
                canvas.drawText(text:line);
            });
            
        };
        

        redraw = ::{
            canvas.clear();

            renderStatusBox();
            renderTurnOrder();
            canvas.commit();        
        };
        
        
        this.interface = {
        
            start ::(
                party => Party.type,
                npcBattle,
            
                allies => Object,
                enemies => Object,
                landmark => Object,
                
                onTurn,
                noLoot,
                exp,
                
                onStart
            ) {
                allies = [...allies];
                enemies = [...enemies];
                canvas.pushState();
                turn = [];
                turnIndex = 0;
                active = true;
                
                @:isPlayerParty = party.isMember(entity:allies[0]);
            
                party_ = party;
                enemies->foreach(do:::(index, enemy) {
                    enemy.battleStart(
                        allies: enemies,
                        enemies: allies
                    );
                });
                allies->foreach(do:::(index, ally) {
                    ally.battleStart(
                        enemies: enemies,
                        allies: allies
                    );
                });

                @:onAllyTurn = ::(battle, user, landmark, allies, enemies) {
                    return if (party.isMember(entity:user))
                        battlemenu(
                            party:party_,
                            battle,
                            user,
                            landmark,
                            allies,
                            enemies 
                        )
                    else 
                        user.battleAI.takeTurn()
                    ;
                };
                
                
                @:onEnemyTurn = ::(battle, user, landmark, allies, enemies) {
                    return user.battleAI.takeTurn();
                };

                if (npcBattle == empty) ::<= {
                    dialogue.message(
                        text: if (enemies->keycount == 1) 
                            "You're confronted by someone!"
                        else 
                            "You're confronted by " + enemies->keycount + ' enemies!'
                    );    
                    
                    enemies->foreach(do:::(index, enemy) {
                        dialogue.message(
                            text: enemy.name + '(' + enemy.stats.HP + ' HP) blocks your path!'
                        );                    
                    });
                };
                allies_ = allies;
                enemies_ = enemies;
                onAllyTurn_ = onAllyTurn;
                onEnemyTurn_ = onEnemyTurn;
                landmark_ = landmark;
                
                allies->foreach(do:::(k, v) {
                    turn->push(value:{
                        isAlly: true,
                        entity: v
                    });
                });

                enemies->foreach(do:::(k, v) {
                    turn->push(value:{
                        isAlly: false,
                        entity: v
                    });
                });
                redraw();
                @alliesWin = [::] {
                    if (onStart) onStart();
                    forever(do:::{
                        when(allies->all(condition:::(value) {
                            return value.isIncapacitated();
                        })) send(message:false);
                        
                        when(enemies->all(condition:::(value) {
                            return value.isIncapacitated();
                        })) send(message:true);
                                    
                        doTurn();
                        if (onTurn != empty)
                            onTurn();
                    });
                };
                
                result = match(true) {
                  (alliesWin):      RESULTS.ALLIES_WIN,
                  (!isPlayerParty): RESULTS.ENEMIES_WIN,
                  default:          RESULTS.NOONE_WIN
                };
                
                
                allies->foreach(do:::(k, v) {
                    v.battleEnd();
                });

                enemies->foreach(do:::(k, v) {
                    v.battleEnd();
                });
                            
                
                when (npcBattle != empty) ::<= {
                    active = false;
                    dialogue.message(text: 'The battle is over.');
                    canvas.popState();

                    allies_ = [];
                    enemies_ = [];
                    
                    return this;
                };


                if (alliesWin) ::<= {            
                    dialogue.message(text: 'The battle is won.');

                    if (exp == true) ::<= {
                        @exp = 0;
                        enemies_->foreach(do:::(index, enemy) {
                            exp += enemy.dropExp();
                        });                
                        exp /= allies_->keycount;
                        exp = exp->ceil;
                        dialogue.message(text: 'Each party member gains ' + exp + ' EXP.');
                        allies_->foreach(do:::(index, ally) {
                            ally.stats.resetMod();
                            
                            @stats = StatSet.new();
                            @level = ally.level;
                            stats.add(stats:ally.stats);
                            ally.gainExp(amount:exp, chooseStat:::(
                                hp, mp, atk, def, int, luk, dex, spd
                            ) {
                                dialogue.message(text: ally.name + ' has leveled up.');


                                ally.stats.resetMod();
                                stats.printDiff(other:ally.stats, prompt:ally.name + ' - (Level:  ' + level  + ' -> ' + (ally.level+1) + ': Base Stats)');                        
                                stats = StatSet.new();
                                stats.add(stats:ally.stats);                        
                                return dialogue.choicesNow(
                                    prompt: ally.name + ' - Focus which?',
                                    choices: [
                                        'HP  (+' + hp + ')',
                                        'MP  (+' + mp + ')',
                                        'ATK (+' + atk + ')',
                                        'INT (+' + int + ')',
                                        'DEF (+' + def + ')',
                                        'SPD (+' + spd + ')',
                                        'LUK (+' + luk + ')',
                                        'DEX (+' + dex + ')'
                                    ]
                                )-1;
                            },
                            
                            afterLevel :::{
                                ally.stats.resetMod();
                                stats.printDiff(other:ally.stats, prompt:'(Level:  ' + level  + ' -> ' + (ally.level+1) + ': Focus)');                        
                            
                            });
                            @:Entity = import(module:'class.entity.mt');
                            @:wep = ally.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L);
                            if (wep != empty) ::<= {
                                wep.addVictory();
                            };
                            ally.recalculateStats();
                            
         
                        }); 
                    };
                    if (noLoot == empty) ::<= {
                        @:loot = [];
                        enemies->foreach(do:::(index, enemy) {
                            enemy.inventory.items->foreach(do:::(index, item) {
                                if (Number.random() > 0.7 && loot->keycount == 0) ::<= {
                                    loot->push(value:enemy.inventory.remove(item));
                                };
                            });
                        });
                        
                        if (loot->keycount > 0) ::<= {
                            dialogue.message(text: 'It looks like they dropped some items during the fight...');
                            @message = 'The party found:\n\n';
                            loot->foreach(do:::(index, item) {
                                @message = 'The party found a(n) ';
                                message = message + item.name;
                                dialogue.message(text: message);
                                party.inventory.add(item);
                            });
                        };
                    };
                                   
                    canvas.popState();

                } else ::<= {
                    if (party.members->all(condition:::(value) <- value.isIncapacitated())) ::<= {
                        dialogue.message(text: 'The battle is lost.');
                    };
                    canvas.popState();
                };
                allies_ = [];
                enemies_ = [];
                active = false;
                
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
                    dialogue.message(text:enemy.name + ' joins the fray!');
                    enemies_->push(value:enemy);
                };
                if (ally != empty) ::<= {
                    when (allies_->findIndex(value:ally) != -1) empty;
                    dialogue.message(text:ally.name + ' joins the fray!');
                    allies_->push(value:ally);
                };
                    
            },
            
            prompt :: (text, choices, canCancel){                                
                canvas.clear();

                renderStatusBox();
                renderTurnOrder();
                when (choices == empty) -1;
                return dialogue.choiceColumnsNow(
                    leftWeight: 1,
                    topWeight: 1,
                    choices,
                    itemsPerColumn: 3,
                    prompt:text
                );

            }
        };
    }
);

return Battle;
