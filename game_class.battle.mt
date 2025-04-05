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
@:Arts = import(module:'game_database.arts.mt');
@:g = import(module:'game_function.g.mt');
@:Entity = import(module:'game_class.entity.mt');
@:displayHP = import(:'game_function.displayhp.mt');
@:AP_COST = 2;

@:combatChooseDefend::(targetPart, attacker, defender, onDone) {
  when (defender.blockPoints == 0) onDone(which:0);
  @:Entity = import(module:'game_class.entity.mt');

  @:notAttack = ::<= {
    @:list = [
      Entity.DAMAGE_TARGET.HEAD,
      Entity.DAMAGE_TARGET.BODY,
      Entity.DAMAGE_TARGET.LIMBS
    ]
    
    list->remove(key:list->findIndex(value:targetPart));
    return random.pickArrayItem(list);
  }

  @blockPoints = defender.blockPoints;
  
  @:partToString::(part) {
    return match(part) {
      (Entity.DAMAGE_TARGET.HEAD): 'head',
      (Entity.DAMAGE_TARGET.BODY): 'body',
      (Entity.DAMAGE_TARGET.LIMBS): 'limbs'
    }
  }
  @blocking = 0;
  @:showNot = random.try(percentSuccess:70);
  
  @:renderFrame ::{
    @:lines = [
      attacker.name + ' is preparing to attack ' + defender.name + '.',
      'How will ' + defender.name + ' respond?',
      '',
      defender.name + ' is currently capable of defending ' + defender.blockPoints + ' ' + (if (defender.blockPoints == 1) 'part' else 'parts') + ' of their body.',
      '',
      if (defender.stats.INT > attacker.stats.INT) defender.name + '\'s intuition tells them that the enemy will:' else '',
      if (defender.stats.INT > attacker.stats.INT)
        if (showNot)
          '- NOT attack the ' + partToString(part:notAttack)
        else
          '- DEFINITELY attack the ' + partToString(part:targetPart)
      else 
        '',
      'Able to block: ' + blockPoints + ' point(s).'
    ];

    if ((blocking & Entity.DAMAGE_TARGET.HEAD) != 0)  lines->push(value:'Currently blocking: Head')
    if ((blocking & Entity.DAMAGE_TARGET.BODY) != 0)  lines->push(value:'Currently blocking: Body')
    if ((blocking & Entity.DAMAGE_TARGET.LIMBS) != 0) lines->push(value:'Currently blocking: Limbs')
    
    
    canvas.renderTextFrameGeneral(
      lines:canvas.refitLines(input:lines),
      topWeight: 0,
      leftWeight: 0.5
    );
    
    
  }

  @choiceNames;
  @choices;
  
  @:resetBlocking = ::{
    blockPoints = defender.blockPoints;
    blocking = 0
    choiceNames = [
      'Defend the head',
      'Defend the body',
      'Defend the limbs'
    ];
    
    choices = [
      Entity.DAMAGE_TARGET.HEAD,
      Entity.DAMAGE_TARGET.BODY,
      Entity.DAMAGE_TARGET.LIMBS
    ]
    doNext();
  
  }
  
  @:doNext = ::{

    windowEvent.queueChoices(
      renderable : {
        render : renderFrame
      },
      topWeight:0.9,
      leftWeight: 0.5,
      onGetChoices ::{
        return choiceNames
      },
      canCancel: true,   
      onCancel :: {
        resetBlocking();
      },
      onChoice ::(choice) {
        blocking |= choices[choice-1];
        choices->remove(key:choice-1);
        choiceNames->remove(key:choice-1);
        blockPoints-=1;
        
        when(blockPoints == 0)
          onDone(which:blocking);
        doNext();
      }
    );
  }
  resetBlocking();
}


@:battleLoot ::(rngLoot, defeated, landmark, party, finishEnd) {

  @:Item = import(module:'game_mutator.item.mt');


  @:forcedAcquisition = [];
  foreach(defeated) ::(k, enemy) {
    @:inv = enemy.forceDrop;
    if (inv != empty)
      forcedAcquisition->push(value:inv);
  }

  foreach(forcedAcquisition) ::(i, inv) {
    foreach(inv.items) ::(n, item) {
      windowEvent.queueMessage(text: 'The party acquired ' + correctA(word:item.name) + '.');
      party.inventory.add(item);
    }
    if (inv.gold > 0) ::<= {
      windowEvent.queueMessage(text: 'The party acquired ' + g(g:inv.gold) + '.');
      party.addGoldAnimated(
        amount:inv.gold,
        onDone::{}
      );
    }
  }
    
    
    
    
    
  windowEvent.queueCustom(
    onEnter ::{},
    onLeave ::{
      finishEnd();      
    }
  );

}


@:Battle = class(

  define:::(this) {  
    // array of arrays of entities 
    // each group is a set of allies. all other group members are 
    // potential enemies  
    @groups;
    @ent2group;
    @group2party;
    @winningGroup;
    
    @:enemyAIs = [];
    @onEnemyTurn_;
    @onAllyTurn_;
    @landmark_;
    @active = false;
    @ended;
    @entityTurn;
    @onTurn_;
    @onAct_;
    @defeated;
    @backgroundID;
    @onFinish = [];
    
  
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
    
    @:getAllies::(ent) {
      return [...ent2group[ent]];
    }

    @:getEnemies::(ent) {   
      @:out = [];
      foreach(groups->filter(by::(value) <- value->findIndex(value:ent) == -1)) ::(k, group) {
        foreach(group) ::(i, ent) {
          out->push(value:ent);
        }
      }   
      return out;
    }
    
    @:getAll::{
      @:out = {};
      foreach(groups) ::(k, v) {
        foreach(v) ::(k, m) {
          out->push(:m);
        }
      }
      return out;
    }

    // defeated enemies were removed from their active groups
    //
    @:getEnemiesDefeated::(ent) {
      when(winningGroup == empty)
        error(detail:'This can only be called upon a team winning');
      @:out = getEnemies(ent);
      foreach(defeated->keys) ::(k, enemy) {
        if (ent2group[enemy] != ent2group[ent])
          out->push(value:enemy);
      }
      return out;
    }

    
    @:checkRemove :: {
      // see if anyone died
      @removed = [];
      foreach(turn)::(index, entity) {          
        when(entity.isDead == false && entity.requestsRemove == false) empty;
        if (group2party[ent2group[entity]] && entity.isDead) ::<= {
          @:world = import(module:'game_singleton.world.mt')
          world.scenario.onDeath(entity);
        }
        @:group  = ent2group[entity];
        entity.battleEnd();
        
        @index = group->findIndex(value:entity);
        if (index != -1) ::<= {
          defeated[group[index]] = true;
          group->remove(key:index);
        }
        if (group->size == 0)
          groups->remove(key:groups->findIndex(value:group));

        index = turnPoppable->findIndex(value:entity);
        if (index != -1) turnPoppable->remove(key:index);
        removed->push(value:entity);
      }
      
      foreach(removed) ::(i, ent) {
        @:ind = turn->findIndex(value:ent);
        if (ind != -1)
          turn->remove(key:ind);
      }
                
    }
    
    @:endTurn ::{
      entityTurn.endTurn(battle:this);
      turnIndex+=1;
      checkRemove();  
      if (turnPoppable->keycount == 0) ::<= {    


        winningGroup = empty;
        @everyoneWipedOut = true;
        {:::} {
          foreach(groups) ::(k, group) {
            @groupAlive = {:::} {
              foreach(group) ::(i, entity) {
                if (!entity.isIncapacitated())
                  send(message:true);
              }
              return false;
            }
            
            
            
            if (groupAlive) ::<= {
              everyoneWipedOut = false;
            
              if (winningGroup == empty)
                winningGroup = group
              // more than one group still alive, no winning team.
              else ::<= {
                winningGroup = empty;
                send();
              }
            }
          }
        }


        
        if (winningGroup != empty || everyoneWipedOut) ::<= {
          ended = true;
          foreach(groups) ::(k, group) {
            foreach(group) ::(i, ent) {
              ent.battleEnd();
            }
          }          
        }     
      }
      windowEvent.queueCustom(
        onEnter ::{
          windowEvent.jumpToTag(
            name:'Battle'
          )
        }
      );
    }
    
    @:nextTurn ::{
      when (turnPoppable->keycount == 0) empty;
      windowEvent.onResolveAll(
        onDone:: {
        
        @:ent = turnPoppable[0];
        turnPoppable->remove(key:0);
        entityTurn = ent;

        @:world = import(module:'game_singleton.world.mt');
        for(0, 6) ::{
          world.incrementTime(isStep:true);
        }

        windowEvent.queueMessage(
          text: 'It is now ' + ent.name + '\'s turn.'
        );

        
        // act turn can signal to not act
        when(!ent.actTurn()) ::<={
          endTurn();
        }


        // may have died this turn.
        when (!ent.canActThisTurn()) ::<={
          endTurn();
        }
        
        // multi turn actions
        if (actions[ent]) ::<= {
          @:action = actions[ent];
          action.turnIndex += 1;
          
          
          this.entityCommitAction(action:actions[ent]);
          
        } else ::<= {
          // normal turn: request action from the act function
          // given by the caller
          @:act = if (group2party[ent2group[ent]]) onAllyTurn_ else onEnemyTurn_;
          if (onTurn_) onTurn_(battle:this, entity:ent, landmark:landmark_);
          act(
            battle:this,
            user:ent,
            landmark:landmark_
          );
        }        
        if (onAct_) onAct_();

      });
    }
    
    @:initTurn ::{
      when(ended) empty;
      // first reset stats according to current effects 
      foreach(turn)::(index, entity) {
        entity.startTurn();
      }
      
      // then resort based on speed
      turn->setSize(size:0);
      foreach(groups) ::(k, group) {
        foreach(group) ::(i, ent) {
          turn->push(value:ent);
        }
      }  
      turn = random.scrambled(:turn);
      @:Effect = import(module:'game_database.effect.mt');  
      turn->sort(
        comparator:::(a, b) {
          when ((a.effectStack.traits & Effect.TRAIT.ALWAYS_FIRST) != 0)
            false
          when ((b.effectStack.traits & Effect.TRAIT.ALWAYS_FIRST) != 0)
            true

        
          return a.stats.SPD < b.stats.SPD;
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
      foreach(turn)::(index, entity) {
        @line = (if(turnIndex == index) '--> ' else '  ') + entity.name + (if(entity.isIncapacitated()) ' (down)' else '');
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
      canvas.drawText(text:'[Turn Order]');
      
      foreach(lines)::(index, line) {
        canvas.movePen(y:top+index+2, x:left+2);
        canvas.drawText(text:line);
      }
    }
        
    @:renderFrac::(isDead, value, outOf) {
      when (outOf > 99 || value < 0) 
        '?? / ??';
        
      return 
        (if (isDead) '--' else (if (value < 10) ''+value+' ' else ''+value))
        + ' / ' +
        (if (outOf < 10) ''+outOf+' ' else ''+outOf)
    }
    @:renderStatusBox::{
      
        
      @lines = [];
      @:ent2line = {};
      
      foreach(groups) ::(k, group) {
        if (k != 0) ::<= {
          if (groups->size <= 2) ::<= {
            lines->push(value:'');
            lines->push(value:'  - vs -   ');
            lines->push(value:''); 
          } else ::<= {
            lines->push(value:'  - vs -   ');          
          }
                   
        }
        foreach(group)::(index, ally) {
          ent2line[ally] = lines->size;
          if (Entity.isDisplayedHurt(entity:ally)) ::<= {
            lines->push(value:' ////////// ' + '  ' + ally.name);// + ' - Lv ' + ally.level);
            lines->push(value:'HP: ' + 'X  / X ' + '  AP: ' + 'X  / X');
          } else ::<= {
            lines->push(value:ally.renderHP() + '  ' + ally.name);// + ' - Lv ' + ally.level);
            lines->push(value:
              'HP: ' + renderFrac(isDead:ally.isDead, value:ally.hp, outOf:ally.stats.HP) + 
              '  AP: ' + renderFrac(isDead:ally.isDead, value:ally.ap, outOf:ally.stats.AP));          
          }
        }
      }
      

      /*
      foreach(enemies_)::(index, enemy) {
        lines->push(value:enemy.renderHP() + '  ' + enemy.name);// + ' - Lv ' + enemy.level);
        lines->push(value:'HP: ' + enemy.hp + ' / ' + enemy.stats.HP);
      }*/


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
      
      // grouping and display of effects
      foreach(groups) ::(k, group) {
        foreach(group)::(index, ally) {
          @:Effect = import(module:'game_database.effect.mt');  
          when (ally.effectStack == empty) empty;
          when (ally.effectStack.getAll()->size == 0) empty;
          @:pieces = [];
          
          @:categories = {
            ('?'): 0,
            ('+'): 0,
            ('-'): 0,
            ('!'): 0
          };
          
          foreach(ally.effectStack.getAll()) ::(k, v) {
            @:eff = Effect.find(:v.id);
            
            categories[Effect.TRAITS_TO_DOMINANT_SYMBOL(:eff.traits)] += 1;
          }
          
          // to preserve order
          foreach(['!', '+', '-', '?']) ::(k, v) {
            when(categories[v] == 0) empty;
            pieces->push(:
              v + 'x' + (if (categories[v] > 9) '*' else categories[v]) + ' '
            );
          }
          
          canvas.movePen(x:width + 6, y:top+2+ent2line[ally]);
          canvas.drawText(text:String.combine(:pieces));
          
        }
      }
      
    }
    


    
    
    this.interface = {
      partyWon :: {
        when(result == empty) false;
        return {:::} {
          foreach(result) ::(k, ent) {
            if (party_.isMember(entity:ent))
              send(message:true);
          }
          return false;
        }  
      },
    
      start ::(
        party => Object,
        npcBattle,
      
        allies => Object,
        enemies => Object,
        landmark => Object,
        
        onTurn,
        onAct,
        loot,
        exp,
        
        renderable,
        
        onStart,
        skipResults,
        onEnd => Function
      ) {
        @:world = import(module:'game_singleton.world.mt')
        foreach(allies) ::(k, v) {
          if (world.party.isMember(:v)) ::<= {
            v.addOpinion(
              fullName : 'the battle with ' + enemies[0].name,
              shortName : 'the battle',
              pastTense : true
            );
          }
        }
      
        onFinish = [];
        actions = {} 
        defeated = {};
        onTurn_ = onTurn;
        onAct_ = onAct;
        groups = [
          [...allies],
          [...enemies]
        ];
        ent2group = [];
        group2party = [];
        
        foreach(allies) ::(i, ally) {
          ent2group[ally] = groups[0];
        }

        foreach(enemies) ::(i, enemy) {
          ent2group[enemy] = groups[1];
        }
        
        if (npcBattle == empty)
          group2party[groups[0]] = true;

        
        turn = [];
        turnIndex = 0;
        active = true;
        ended = false;
        externalRenderable = renderable;
              
        party_ = party;
        foreach(groups) ::(i, group) {
          foreach(group)::(index, ent) {
            ent.battleStart(
              battle: this
            );
          }
        }

        @:onAllyTurn = ::(battle, user, landmark, allies, enemies) {
          if (party.leader == user)
            battlemenu(
              party:party_,
              battle,
              user,
              landmark,
              allies,
              enemies 
            )
          else 
            user.battleAI.takeTurn(battle);
          ;
        }
        
        
        @:onEnemyTurn = ::(battle, user, landmark) {            
          user.battleAI.takeTurn(battle);
        }

        if (npcBattle == empty) ::<= {
          windowEvent.queueMessage(
            text: if (groups[1]->keycount == 1) 
              "You're confronted by someone!"
            else 
              "You're confronted by " + groups[1]->keycount + ' enemies!'
          );  
          
          foreach(groups[1])::(index, enemy) {
            windowEvent.queueMessage(
              text: enemy.name + ' blocks your path!'
            );          
          }
        }
        onAllyTurn_ = onAllyTurn;
        onEnemyTurn_ = onEnemyTurn;
        landmark_ = landmark;
        
        
        
        foreach(groups) ::(i, group) {
          foreach(group)::(index, ent) {
            turn->push(value:ent);
          }
        }
        
        turn->sort(
          comparator:::(a, b) {
            return a.stats.SPD <
                 b.stats.SPD;
          }
        );
 
        battleEnd = ::{
          @:startEnd ::(message) {
            active = false;

            windowEvent.queueMessage(
              text: message
            );
            if (windowEvent.canJumpToTag(name:'Battle'))                      
              windowEvent.jumpToTag(name:'Battle', goBeforeTag:true, doResolveNext:true);          

          }
        
          @:finishEnd :: {
          
            groups = [];
            onEnd(result);      
            foreach(onFinish) ::(k, v) {
              v(:result);
            }      
            onFinish = [];        
          }
          result = winningGroup;
          
          
          
          
          when (npcBattle != empty || skipResults == true) ::<= {
            startEnd(message:'The battle is over.');
            finishEnd();
          } 


          if (this.partyWon()) ::<= {      

            startEnd(
              message: 'The battle is won.'
            );
            
            party.queueCollectSupportArt();
            party.gainProfessionExp(
              exp:getEnemiesDefeated(ent:party.members[0])->size * Entity.PROF_EXP_PER_KNOCKOUT,
              onDone::{

                @:Entity = import(module:'game_class.entity.mt');
                @hasWeapon = false;
                foreach(party_.members)::(index, ally) {   
                  @:wep = ally.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR);
                  if (wep.name != 'None' && wep.canGainIntuition()) 
                    hasWeapon = true;
                };



                if (hasWeapon && random.try(percentSuccess:50)) ::<= {
                
                  @:ally = random.pickArrayItem(:party_.members);
                  @:wep = ally.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR);
                  when (wep.name == 'None') empty;
                  when (!wep.canGainIntuition()) empty;
                
                  windowEvent.queueMessage(text:ally.name + '\'s feels the ' + wep.name + '\'s power grow.');

                  @:world = import(module:'game_singleton.world.mt')
                  world.accoladeIncrement(name:'intuitionGained');
                  @:choice = match(random.integer(from:1, to:3)) {
                    // inward -> AP, INT, DEF
                    (1): random.pickArrayItem(list:[1, 4, 3]),
                    // skyward -> DEX, SPD, LUK 
                    (2): random.pickArrayItem(list:[6, 7, 5]),
                    // forward -> ATK, HP 
                    (3): random.pickArrayItem(list:[2, 0])
                  };


                  ally.recalculateStats();
                  @:oldAllyStats = StatSet.new();
                  oldAllyStats.load(serialized:ally.stats.save());
                  @:stats = wep.stats;               
                  @:oldStats = StatSet.new();
                  oldStats.add(stats);
                  stats.add(stats:StatSet.new(
                    HP: if (choice == 0) 7 else 0,
                    AP: if (choice == 1) 7 else 0,
                    ATK: if (choice == 2) 7 else 0,
                    DEF: if (choice == 3) 7 else 0,
                    INT: if (choice == 4) 7 else 0,
                    LUK: if (choice == 5) 7 else 0,
                    DEX: if (choice == 6) 7 else 0,
                    SPD: if (choice == 7) 7 else 0
                  ));
                    
                  oldStats.printDiffRate(other:stats, prompt:wep.name);
                  ally.recalculateStats();
                  oldAllyStats.printDiff(other:ally.stats, prompt:ally.name);
                }

                battleLoot(
                  rngLoot : loot,
                  defeated:getEnemiesDefeated(ent:party.members[0]),
                  landmark, 
                  party, 
                  finishEnd
                );              
              }
            );
          } else ::<= {
            startEnd(
              message: 'The battle is lost.'
            );

            windowEvent.queueCustom(onEnter::{
              onEnd(result); 
            });             
          }
        }


        @started = false;
        windowEvent.queueCustom(
          keep: true,
          jumpTag: 'Battle',
          disableCache : true,
          onEnter :: {
          },
          onLeave ::{
          },
          
          renderable : {
            render ::{
              canvas.blackout();
              this.render()
            }
          },
          onUpdate::{
            when(ended) ::<= {
              if (windowEvent.hasAnyQueued() == false) ::<= {
                battleEnd();                
              }
            }

          
          
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
      
      getAllies ::(entity) {
        return getAllies(ent:entity)
      },

      getEnemies ::(entity) {
        return getEnemies(ent:entity)
      },
      
      addOnFinishCallback ::(cb) {
        onFinish->push(:cb);
      },
      
      getMembers :: {
        @:out = [];
        foreach(groups) ::(k, group) {
          foreach(group) ::(i, ent) {
            out->push(value:ent);
          }
        }   
        return out;
      },
      
      isMember ::(entity) <- {:::} {
        foreach(groups) ::(k, group) {
          foreach(group) ::(i, ent) {
            if (ent == entity) send(:true);
          }
        }
        return false;       
      },

      
      isActive : {
        get ::<- active
      },
      
      landmark : {
        get ::<- landmark_
      },
      
      evict ::(entity) {
        
        @:group  = ent2group[entity];

        @index = group->findIndex(value:entity);
        if (index != -1) ::<= {
          defeated[group[index]] = true;
          group->remove(key:index);
        }
        if (group->size == 0)
          groups->remove(key:groups->findIndex(value:group));

        index = turnPoppable->findIndex(value:entity);
        if (index != -1) turnPoppable->remove(key:index);
        
        @:ind = turn->findIndex(value:entity);
        if (ind != -1)
          turn->remove(key:ind);
          
        windowEvent.queueMessage(
          text: entity.name + ' was evicted from battle.'
        );
      },
      
      join ::(group, sameGroupAs) {

        @:newGroup = if (sameGroupAs != empty)
          ent2group[sameGroupAs]
        else 
          []
          

        if (party_.isMember(entity:group[0]))
          group2party[newGroup] = true;

        foreach(group) ::(i, entity) {
          newGroup->push(value:entity);
          ent2group[entity] = newGroup;
        }
        if (sameGroupAs == empty)
          groups->push(value:newGroup);
          
        foreach(group) ::(i, entity) {
          when(turn->findIndex(value:entity) != -1) 
            error(detail: 'Tried to join battle when was already a part of the battle');
          windowEvent.queueMessage(text:entity.name + ' joins the fray!');
          entity.battleStart(battle:this);
          entity.startTurn();
        }
      },
      
      render :: {
        renderStatusBox();
        renderTurnOrder();
      },
      
      entityCommitAction::(action, from) {
        @:entAct = if (from != empty) from else entityTurn;
        @originalAction = action;
        // failsafe. not normally needed.
        when (!entAct.canActThisTurn())
          endTurn();
        
        @:passesCheck ::{
          @:art = Arts.find(:action.card.id);
          when(art.traits & Arts.TRAIT.SUPPORT == 0) true;
          return false;
        }
          
        @:requiresAP = ((Arts.find(:action.card.id).traits & Arts.TRAIT.COSTLESS) == 0);
          
        when (requiresAP && entAct.ap < AP_COST) ::<= {
          @:art = Arts.find(:action.card.id);
          windowEvent.queueMessage(
            text: entAct.name + ' tried to use the Art ' + art.name + ' but couldn\'t muster the mental strength!'
          );
        }
        if (requiresAP)
          entAct.ap -= AP_COST;
          
          
          
        @:Entity = import(module:'game_class.entity.mt');
        @:world = import(module:'game_singleton.world.mt');
        @:targetDefendParts = [];
        foreach(action.targets) ::(index, target) {        
          targetDefendParts[index] = if (target.blockPoints <= 0 || random.try(percentSuccess:35)) 0 else Entity.normalizedDamageTarget(blockPoints:target.blockPoints);
        }
        
        @pendingChoices = [];
        @:art = Arts.find(id:action.card.id);
        if (world.party != empty && ((art.traits & Arts.TRAIT.CAN_BLOCK) != 0) && action.targets->size > 0) ::<= {
          pendingChoices = [...action.targets]->filter(by::(value) <- world.party.leader == value);
        }
      
        @:finish ::(useArtReturn) {

          if (Arts.find(:action.card.id).kind == Arts.KIND.EFFECT && action.card.level > 1) ::<= {
            windowEvent.queueMessage(
              text : 'The Art had ' + (action.card.level-1) + ' counter(s)!'
            );
            entAct.healAP(amount:action.card.level-1);
          }


          if (art.kind == Arts.KIND.ABILITY || art.kind == Arts.KIND.SPECIAL) ::<= {
            entAct.flags.add(flag:StateFlags.WENT);
            if (art.name != 'Wait' &&
              art.name != 'Use Item')
              entAct.flags.add(flag:StateFlags.ABILITY);

            if (art.durationTurns > 0) ::<= {
              breakpoint();
              if (actions[entAct] == action && (action.turnIndex >= art.durationTurns || useArtReturn == Arts.CANCEL_MULTITURN)) ::<= {
                actions[entAct] = empty;
              } else if (useArtReturn != Arts.CANCEL_MULTITURN) ::<= {
                actions[entAct] = action;
              }
            }


            windowEvent.queueCustom(
              onEnter ::{
                endTurn();
              }
            );
          }        
        }
      
        
        @:doAction ::{
          
          @:art = Arts.find(id:action.card.id);
        
          @:ret = entAct.useArt(
            art,
            level: action.card.level,
            targets:action.targets,
            targetParts:action.targetParts,
            targetDefendParts: targetDefendParts,
            turnIndex : action.turnIndex,
            extraData : action.extraData
          );
          windowEvent.queueCustom(
            onEnter ::{
              finish(:ret);           
            }
          );
        }
      
        // react andy time
        @checkReactions ::(onPass, onReject) {
          @toReact = getAll()->filter(::(value) <- value.canUseReactions() && value.deck.containsReaction());
          toReact->sort(:::(a, b) <- a.stats.SPD > b.stats.SPD);
          when(toReact->size == 0)
            onPass();

          @:tryNext:: {
            when(toReact->size == 0)
              onPass();
              
            @reactor = toReact->pop;
            when(reactor == entAct || reactor.ap < AP_COST)
              tryNext();

            reactor.react(
              source: entAct,
              onReact::(reaction) {
                when(reaction == empty)
                  tryNext();
                  
                when(!reactor.canUseReactions())
                  windowEvent.queueCustom(
                    onEnter ::{
                      tryNext();
                    }
                  );

                  
                reactor.deck.discardFromHand(:reaction.card);
                @art = Arts.find(:reaction.card.id);
                
                
                windowEvent.queueMessage(
                  text: reactor.name + ' reacts with the Art ' + art.name + '!'
                );
        
                reactor.ap -= AP_COST;
                
                
                @cancel = art.onAction(
                  level: 1,
                  user: reactor,
                  targets : reaction.targets,
                  targetDefendParts: [0],
                  targetParts : reaction.targetParts,
                  turnIndex: 0,
                  extraData : {
                    action: action
                  }
                );
                
                
                
                when(cancel->type == Boolean && cancel) ::<= {
                  windowEvent.queueMessage(text: reactor.name + '\'s ' + art.name + ' cancelled ' + entAct.name + '\'s Art!');
                  windowEvent.queueCustom(
                    onEnter :: {
                      onReject();
                    }
                  )
                }
                
                if (cancel->isa(:Object)) ::<= {
                  windowEvent.queueMessage(text: reactor.name + '\'s ' + art.name + ' transformed ' + entAct.name + '\'s Art!');
                  action = cancel;                
                }
                  
                
                  
                windowEvent.queueCustom(
                  onEnter :: {
                    tryNext();                
                  }
                );
              }
            )
          }
          
          tryNext();
        
        }
      
        @:chooseDefend ::(onDone) {
          @:doNext = :: {
            when(pendingChoices->size == 0) onDone();
            @:next = pendingChoices->pop;
            when(Arts.find(:action.card.id).targetMode != Arts.TARGET_MODE.ONEPART) ::<= { // todo: luck delta affecting chance
              targetDefendParts[action.targets->findIndex(value:next)] = 0;
              doNext();
            }
            combatChooseDefend(
              targetPart: action.targetParts[action.targets->findIndex(value:next)],
              attacker:entAct,
              defender:next,
              onDone ::(which) {
                @:index = action.targets->findIndex(value:next);
                targetDefendParts[index] = which;
                doNext();
              }
            );
          }
          doNext();          
        }
      
      
        entAct.deck.discardFromHand(card:action.card);
        windowEvent.onResolveAll(
          onDone :: {
            // entAct.deck was likely BLASTED due to death
            when (active == false || entAct == empty || entAct.deck == empty) 
              empty;

            entAct.deck.revealArt(
              user:entAct,
              handCard:action.card,
              prompt: entAct.name + ' uses the Art: ' + art.name + '!'
            );
            
            windowEvent.queueCustom(
              onEnter :: {
                // react here
                checkReactions(
                  onPass::{
                    windowEvent.queueCustom(
                      onEnter ::{
                        when (!entAct.canActThisTurn())
                          endTurn();
                        chooseDefend(::{
                          doAction();
                        });
                      }
                    );
                  },
                  onReject::{
                    finish();                
                  }
                );
              }
            
            )
          }
        );
      },
    }
  }
);

return Battle;
