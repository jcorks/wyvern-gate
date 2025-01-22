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
@:Entity = import(module:'game_class.entity.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Arts = import(module:'game_database.arts.mt');
@:g = import(module:'game_function.g.mt');

@:MAX_QUEST_COUNT = 15

@:Party = LoadableClass.create(
  name: 'Wyvern.Party',
  items : {
    inventory : Inventory.new(size:40),
    members : empty,
    karma : 5500,
    arts : [],
    leader : 0,
    guildRank : -1,
    guildEXP : 0,
    guildEXPtoNext : 100,
    guildTeamName : '',
    activeQuests : [],
    completedQuests : []
  },

  define:::(this, state) {   
        
    this.interface = {  
      initialize :: {},
      defaultLoad ::{      
        state.members = [];
      },
      reset ::{
        state.members = [];
        state.inventory = Inventory.new(size:40);
      },
      
      leader : {
        get ::<- state.members[state.leader],
        set ::(value) {
          state.leader = state.members->findIndex(:value);
          if (state.leader < 0)
            state.leader = 0
        }
      },
    
      add::(member => Entity.type) {
        // no repeats, please
        when(state.members->any(condition::(value) <- value == member)) empty;        
        /*
        member.inventory.items->foreach(do:::(index, item) {
          inventory.add(item);          
        });
        member.inventory.clear();
        */

        
        foreach(state.members) ::(k, v) {
          v.addOpinion(
            fullName : v.name + '\'s teammate ' + member.name,
            shortName : member.name,
            core : true
          );

          member.addOpinion(
            fullName : member.name + '\'s teammate ' + v.name,
            shortName : v.name,
            core : true
          );
        }


        state.members->push(value:member);
        
      },
      
      getItem ::(condition, remove) {      
        @heldBy;
        @:which = ::<= {
          @key = this.inventory.items->filter(:condition);
          when (key->size != 0) key[0];

          // could be equipped
          return {:::} {
            foreach(this.members)::(i, member) {
              foreach(Entity.EQUIP_SLOTS) ::(n, slot) {
                @:wep = member.getEquipped(slot);
                if (condition(:wep)) ::<= {
                  heldBy = member;
                  send(message:wep);
                }
              }
            }
          }        
        }
        if (remove) ::<= {
          if (heldBy != empty)
            heldBy.unequipItem(item:which);
          which.throwOut();
        }
        return which;
      },
      
      inventory : {
        get :: <- state.inventory
      },
      
      isMember::(entity => Entity.type) {
        return state.members->any(condition:::(value) <- value == entity);
      },

      isMemberID::(id => Number) {
        return state.members->any(condition:::(value) <- value.worldID == id);
      },
            
      remove::(member => Entity.type, silent) {
        {:::}{
          foreach(state.members)::(index, m) {
            if (m == member)::<={
              state.members->remove(key:index);
              if (silent != true)
                windowEvent.queueMessage(text:m.name + ' has been removed from the party.');
              if (state.leader == index) ::<= {
                state.leader = (index+1)%state.members->size;
              } 
              
              foreach(state.members) ::(index, other) {
                other.addOpinion(
                  fullName : 'losing ' + other.name + '\'s teammate ' + m.name,
                  pastTense : true,
                  core:true
                )
              }
                
              send();
            }            
          }
        }
      },
      quests : {
        get ::<- state.activeQuests
      },
      
      acceptQuest::(issuer, island, quest) {
        when (state.activeQuests->size >= MAX_QUEST_COUNT) ::<= {
          windowEvent.queueMessage(
            text:"The party has too many active quests. Please either turn in or remove other quests before taking this one."
          );
          return false;
        }
        state.activeQuests->push(:quest);
        quest.accept(
          island,
          issuer
        );
        return true;
      },
      
      questCompleted ::(id) {
        state.completedQuests[id] = true;
      },
      
      isIncapacitated :: {
        return state.members->all(condition:::(value) <- value.isIncapacitated());
      },
      
      gainProfessionExp::(exp, onDone) {
        when(exp == 0)
          windowEvent.queueCustom(
            onLeave::{
              onDone()
            }
          )
          
        @index = 0;
        @:next :: {
          when(index >= state.members->size) 
            windowEvent.queueCustom(
              onLeave::{
                if (onDone)
                  onDone()
              }
            )

          state.members[index].gainProfessionExp(
            exp,
            onDone ::{
              index += 1;
              next();
            }
          );
        }
        
        next()
      },
      
      queueCollectSupportArt::(
        arts
      ) {
        if (arts == empty)
          arts = [
            Arts.getRandomFiltered(::(value) <- 
              (value.traits & Arts.TRAITS.SUPPORT) != 0 &&
              ((value.traits & Arts.TRAITS.SPECIAL) == 0)         
            ),        
            Arts.getRandomFiltered(::(value) <- 
              (value.traits & Arts.TRAITS.SUPPORT) != 0 &&
              ((value.traits & Arts.TRAITS.SPECIAL) == 0)         
            )
          ]        
          
        @:ArtsDeck = import(:'game_class.artsdeck.mt');
      
        @:newArtRender ::(art){
          ArtsDeck.renderArt(
            handCard:ArtsDeck.synthesizeHandCard(id:art.id),
            topWeight: 0
          );
        }

        foreach(arts) ::(k, v) {      
          this.addSupportArt(id:v.id);
          windowEvent.queueMessage(
            topWeight: 1,
            text: 'A new Art has been revealed!',
            renderable : {
              render :: {newArtRender(:v);}
            }
          );
        }


        windowEvent.queueMessage(
          text: 'The Arts were added to the Trunk. They are now available when editing any party member\'s Arts in the Party menu.'
        );      
      },
      
      addSupportArt ::(id => String) {
        @index = state.arts->findIndexCondition(::(value) <- value.id == id);
        when(index == -1) ::<={
          state.arts->push(:{
            id: id,
            count: 1
          });
        }
        
        state.arts[index].count+=1;
      },
      
      takeSupportArt ::(id) {
        @index = state.arts->findIndexCondition(::(value) <- value.id == id);
        when(index == -1) empty;
        state.arts[index].count-=1;
        if (state.arts[index].count == 0) 
          state.arts->remove(:index);
      },
      
      arts : {
        get ::<- [...state.arts]
      },
      
      addGoldAnimated ::(amount, onDone) {
        foreach(state.members) ::(k, v) {
          v.addOpinion(
            fullName : 'money',
            shortName : 'gold'
          );
        }
      
      
        @gained = amount;
        @oldG = this.inventory.gold;
        @price = gained;
        windowEvent.queueCustom(
          onEnter ::{},
          isAnimation: true,
          onInput ::(input) {
            match(input) {
              (windowEvent.CURSOR_ACTIONS.CONFIRM,
               windowEvent.CURSOR_ACTIONS.CANCEL):
              price = 0
            }
          },
          animationFrame ::{
            canvas.renderTextFrameGeneral(
              leftWeight: 0.5,
              topWeight : 0.5,
              lines : [
                'Current funds: ' + g(g:oldG),
                if (price >= 0)
                '        +' + g(g:price)
                else
                '        ' + g(g:price)
              ]
            );
            
            when(price->abs <= 0) ::<= {
              if (gained > 0)
                this.inventory.addGold(amount:gained)
              else
                this.inventory.subtractGold(amount:-gained);

              return windowEvent.ANIMATION_FINISHED
            }
            
            @newPrice = if (price < 0) (price * 0.9)->ceil else (price*0.9)->floor;
            @red = newPrice - price;
            price += red;
            oldG -= red;
          }
        );
        
        windowEvent.queueDisplay(
          leftWeight: 0.5,
          topWeight : 0.5,
          lines : [
            'Current funds: ' + g(g:oldG + gained),
            '         '
          ],
          skipAnimation : true
        )
        
        if (onDone)
          windowEvent.queueCustom(
            onEnter :: {
              onDone();
            }
          );
      },
      
      guildRank : {
        get ::<- state.guildRank
      },
      
      guildTeamName : {
        get ::<- state.guildTeamName
      },
      
      
      guildEXPtoNext : {
        get ::<- state.guildEXPtoNext
      },
      
      guildEXP : {
        get ::<- state.guildEXP
      },
      
      animateGainGuildEXP ::(exp, onDone) {
        @:Quest = import(:'game_mutator.quest.mt');

        @remainingForLevel = state.guildEXPtoNext - state.guildEXP;
        windowEvent.queueDisplay(
          lines : [
            ' - Team ' + state.guildTeamName + ' - ',
            '',
            'Guild rank: ' + Quest.RANK2NAME[state.guildRank],
            canvas.renderBarAsString(width:40, fillFraction: state.guildEXP / state.guildEXPtoNext),
            'Exp to next rank: ' + remainingForLevel,
            '                 +' + exp
          ]
        )
        
        
        @:level = ::{
          windowEvent.queueCustom(
            onEnter ::{},
            isAnimation: true,
            /*onInput ::(input) {
              match(input) {
                (windowEvent.CURSOR_ACTIONS.CONFIRM,
                 windowEvent.CURSOR_ACTIONS.CANCEL):
                exp = 0
              }
            },*/
            animationFrame ::{
              @remainingForLevel = state.guildEXPtoNext - state.guildEXP;
              canvas.renderTextFrameGeneral(
                leftWeight: 0.5,
                topWeight : 0.5,
                lines : [
                  ' - Team ' + state.guildTeamName + ' - ',
                  '',
                  'Guild rank: ' + Quest.RANK2NAME[state.guildRank],
                  canvas.renderBarAsString(width:40, fillFraction: state.guildEXP / state.guildEXPtoNext),
                  'Exp to next rank: ' + remainingForLevel,
                  if (exp >= 0)
                  '                 +' + exp
                  else
                  '                  ' + exp
                ]
              );
              

              
              @newExp = if (exp < 0) (exp * 0.9)->ceil else (exp*0.9)->floor;
              @add = exp - newExp;
              
              state.guildEXP += add;
              exp = newExp;
              
              when (state.guildEXP >= state.guildEXPtoNext) ::<= {
                state.guildRank += 1;
                state.guildEXP = state.guildEXP - state.guildEXPtoNext;
                state.guildEXPtoNext = (90 ** (1 + 0.31*state.guildRank))->floor;

                windowEvent.queueDisplay(
                  lines : [
                    'Rank up!',
                    'Congratulations! Team ' + state.guildTeamName + ' is now rank ' + Quest.RANK2NAME[state.guildRank]
                  ]
                );


                level();
                return windowEvent.ANIMATION_FINISHED;
              }

              when(exp->abs <= 0) ::<= {
                windowEvent.queueDisplay(
                  lines : [
                    ' - Team ' + state.guildTeamName + ' - ',
                    '',
                    'Guild rank: ' + Quest.RANK2NAME[state.guildRank],
                    canvas.renderBarAsString(width:40, fillFraction: state.guildEXP / state.guildEXPtoNext),
                    'Exp to next rank: ' + remainingForLevel,
                    ''
                  ],
                  skipAnimation: true
                )
                
                windowEvent.queueCustom(
                  onEnter :: {
                    onDone();
                  }
                );
                return windowEvent.ANIMATION_FINISHED
              }
            }
          );
        }
        level();
        

      },  
      
      
      
      setGuildTeamName ::(name) {
        state.guildTeamName = name;
        state.guildRank = 0;
        state.guildEXP = 0;
      },

      members : {
        get ::<- state.members
      },
      
      clear :: {
        state.inventory.clear();
        state.members = [];      
      },
      
      karma : {
        get ::<- state.karma,
        set ::(value) <- state.karma = value
      }
    }
  }
);
return Party;
