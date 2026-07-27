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
@:Arts = import(module:'game_mutator.arts.mt');
@:g = import(module:'game_function.g.mt');

@:MAX_QUEST_COUNT = 15

@Hunger;

@:Party = LoadableClass.create(
  name: 'Wyvern.Party',
  items : {
    inventory : {},
    loot : {}, 
    members : empty,
    karma : 5500,
    arts : [],
    denyJoinPartyCount : 0,
    queuedArts : [],
    leader : 0,
    inDungeon : false,
    guildRank : -1,
    guildEXP : 0,
    guildEXPtoNext : 100,
    guildTeamName : '',
    activeQuests : [],
    completedQuests : [],
    firstEncounter : true,
    hunger : empty,
    bank : empty,
    steps : 0
  },

  define:::(this, state) {   
        
    this.interface = {  
      initialize :: {
        state.denyJoinPartyCount = 0
        state.firstEncounter = true
      },
      defaultLoad ::{      
        state.members = [];
        state.inventory = Inventory.new(size:40);
        state.hunger = Hunger.new(parent:this);
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
      
      steps : {
        get ::<- state.steps
      },
      
      inDungeon : {
        get ::<- state.inDungeon,
        set ::(value) <- state.inDungeon = value
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
        
        // cant talk to us, BUT. is friendly :)
        @:Species = import(module:'game_database.species.mt');
        if (member.species.traits & Species.TRAIT.NO_COMMON_SPEAK)
          member.nickname = 'Friendly ' + member.name
        
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
          return ::? {
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
      
      // returns an array of 2:
      // [0] -> array of items (Item) 
      // [1] -> array of equippers (Entity, or empty);
      getAllItems ::(filter) {
        @:items = {};
        @:equippedBy = {};
        
        foreach(this.inventory.items) ::(k, v) {
          when(filter != empty && ! filter(value:v)) empty;
          items->push(:v);
          equippedBy->push(:empty);
        }

        foreach(this.members) ::(k, member) {
          foreach(Entity.EQUIP_SLOTS) ::(k, slot) {
            when(slot == Entity.EQUIP_SLOTS.HAND_R) empty;
            @:item = member.getEquipped(slot);
            when(item == empty) empty;
            when(item.base.id == 'base:none') empty;
            
            when(filter != empty && ! filter(value:item)) empty;

            items->push(:item);
            equippedBy->push(:member);

          }
        }      
        
        
        return [
          items,
          equippedBy
        ]
      },
      
      inventory : {
        get :: <- state.inventory
      },

      bank : {
        get :: {
          if (state.bank == empty)
            state.bank = Inventory.new(size:9999999);                        
          return state.bank
        }
      },

      
      isMember::(entity => Entity.type) {
        return state.members->any(condition:::(value) <- value == entity);
      },

      isMemberID::(id => Number) {
        return state.members->any(condition:::(value) <- value.worldID == id);
      },
            
      remove::(member => Entity.type, silent) {
        ::?{
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
              
              state.denyJoinPartyCount = 0;

                
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
            Arts.database.getRandomFiltered(::(value) <- 
              (value.traits & Arts.TRAIT.SUPPORT) != 0 &&
              ((value.traits & Arts.TRAIT.SPECIAL) == 0)         
            )
          ]        
          
        /*when (state.inDungeon) ::<= {
          state.queuedArts = [...state.queuedArts, ...(arts->map(::(value) <- value.id))];
        }*/
      
      
        if (arts->size <= 2) ::<= {    
          @:ArtsDeck = import(:'game_class.artsdeck.mt');
        

          foreach(arts) ::(k, v) {      
            this.addSupportArt(id:v.id);
            windowEvent.queueMessage(
              topWeight: 1,
              text: 'A new Art has been revealed!',
              renderable : {
                render :: {
                  Arts.renderArt(
                    id:v.id,
                    topWeight: 0
                  );
                }
              }
            );
          }


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
        get ::<- [...state.arts->map(::(value) <- value.id)]
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
          onLeave :: {
            if (gained > 0)
              this.inventory.addGold(amount:gained)
            else
              this.inventory.subtractGold(amount:-gained);
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
      
      enterDungeon ::(landmark) {
        state.inDungeon = true;
        windowEvent.queueMessage(
          text:"The party ventures into " + landmark.name + "..."
        );
      },
      
      leaveDungeon ::(landmark) {
        state.inDungeon = false;
        
        windowEvent.queueNestedResolve(
          renderable : {
            render ::{
              canvas.fill();
            }
          },
          
          onEnter ::{
            windowEvent.queueMessage(
              text: 'The party returns from ' + landmark.name
            );  

            if (state.queuedArts->size) ::<= {
              this.queueCollectSupportArt(
                :(state.queuedArts->map(::(value) <- Arts.database.find(:value)))
              );              
              state.queuedArts = [];
            }            


            /*
            @:loot = state.inventory.loot;
            if (loot != empty && loot->size > 0) ::<= {
              windowEvent.queueMessage(
                text: 'Leaving the area unlocked the power of the party\'s Ethereal Shards!'
              );  
            
              @:items = loot->map(::(value) <-
                value.unbox()
              );
              state.inventory.clearLoot();
              items->sort(::(a, b) {
                when(a.stars > b.stars) -1;
                when(a.stars < b.stars)  1;
                return 0;
              });
              @:inv = Inventory.new(size:99999);
              foreach(items) :: (k, v) {
                inv.add(:v);
              }
              
              @:pickItem = import(:'game_function.pickitem.mt');
              @:queueChoicesColumn = import(:'game_function.choicescolumns.mt');
              queueChoicesColumn(
                prompt: "Loot:", // 985's mark
                topWeight: 0.5,
                leftWeight: 0.5,
                columns : [
                  loot->map(::(value) <- value.name),
                  loot->map(::(value) <- value.starsString),
                ],
                leftJustified : [true, true],
                onChoice::(choice) {
                },
                canCancel : true,
                onCancel ::{
                }
              );

              pickItem(
                prompt: "Loot: Get!", // 985's mark
                topWeight: 0.5,
                leftWeight: 0.5,
                inventory : inv,
                onPick ::(item) {
                  item.describe();
                },
                canCancel : true,
                showRarity : true,
                onCancel ::{
                  // FOR NOW dump to inventory, but we need selection in case too many items!!!!
                  foreach(items) ::(k, v) {
                    this.inventory.add(:v);
                  }
                }
              );
            }
            */
          }
        );
      },
      
      
      animateGainGuildEXP ::(exp, onDone) {
        @:animateBar = import(:'game_function.animatebar.mt');
        @:Quest = import(:'game_mutator.quest.mt');

        @:level:: {
          @remainingForLevel = state.guildEXPtoNext - state.guildEXP;
          @val = state.guildEXP;
          breakpoint();
          animateBar(
            from: state.guildEXP,
            to:   state.guildEXP + exp,
            max:  state.guildEXPtoNext,
            
            onGetPauseFinish::<- true,
            
            onFinish:: {
              when(state.guildEXP+exp >= state.guildEXPtoNext) ::<= {
                exp -= (state.guildEXPtoNext - state.guildEXP);
                
                state.guildRank += 1;
                state.guildEXP = 0;
                state.guildEXPtoNext = (90 ** (1 + 0.31*state.guildRank))->floor;

                windowEvent.queueDisplay(
                  lines : [
                    'Rank up!',
                    'Congratulations! Team ' + state.guildTeamName + ' is now rank ' + Quest.RANK2NAME[state.guildRank]
                  ]
                );


                level();            
              }
              
              state.guildEXP += exp;
              if (onDone != empty) onDone();
            },
            onGetCaption       ::<- ' - Team ' + state.guildTeamName + ' - ', 
            onGetCoCaption     ::<- 'Guild rank: ' + Quest.RANK2NAME[state.guildRank],
            onGetSubcaption    ::<- 'Exp to next rank: ' + (remainingForLevel - (val - state.guildEXP))->ceil,
            onGetSubsubcaption ::<- '                + ' + (exp - (val - state.guildEXP))->ceil,
            
            onGetLeftWeight::<- 0.5,
            onGetTopWeight::<- 0.5,
            onNewValue ::(value) <- val = value->ceil
          );
        }

        level();
        

      },  
      
      step :: {
        state.steps += 1;
        foreach(state.members) ::(k, v) {
          v.step();
        }
        foreach(state.inventory.items) ::(k, v) {
          v.step();
        }
        if (state.steps > 0 && (state.steps % 70) == 0) ::<= {
          foreach(state.members) ::(k, member) {
            member.recharge()
          }
        }
        @:world = import(module:'game_singleton.world.mt');
        if (world.scenario.base.ignoreHunger != true) {
          state.hunger.step();
        }
      },
      
      eat ::{
        state.hunger.eat();
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
      
      denyJoinPartyCount : {
        get ::<- state.denyJoinPartyCount,
        set ::(value) <- state.denyJoinPartyCount = value
      },
      firstEncounter : {
        get ::<- state.firstEncounter,
        set ::(value) <- state.firstEncounter = value
      },

      
      karma : {
        get ::<- state.karma,
        set ::(value) <- state.karma = value
      }
    }
  }
);


// hunger helper class 
@:HUNGER_LEVELS = [
  [0.55, 'The party is starting to get hungry.'],
  [0.4,  'The party is hungry.'],
  [0.3,  'The party is quite hungry.'],
  [0.21, 'The party is famished.'],
  [0.15, 'The party is beginning to starve.'],
  [0.04, 'The party is starving.'],
]

Hunger = LoadableClass.create(
  name : 'Wyvern.Party.Hunger',
  items : {
    tummy : 1
  },
  
  define::(this, state) {
    @party;
    
    this.interface = {
      initialize ::(parent) {
        party = parent;
        state.tummy = 0.5;
      },
      
      defaultLoad::(parent) {
        state.tummy = 0.5;      
        party = parent;
      },
      
      step ::{
        @:rateToLevel::(rate) <-
          ::? {
            foreach(HUNGER_LEVELS) ::(i, val) {
              when(rate > val[0]) send(:i)
            }     
            return HUNGER_LEVELS->size-1;     
          }
        
        @:before = rateToLevel(:state.tummy);
        @:after  = rateToLevel(:state.tummy - 0.0001);
        
        state.tummy -= 0.0001
        breakpoint();
        
        if (before != after) {
          windowEvent.queueMessage(
            text: HUNGER_LEVELS[after][1]
          );
        }
      },
      
      eat ::{
        @:eatThese::(foods) {
          @totalNutrients = 0;
          @totalFilling = 0;
          @:eatNext::() {
            when(foods->size == 0) ::<= {
              @:starsToString::(stars) {
                @out = '';
                for(0, stars) ::(i) {
                  if (i%5 == 0 && i > 0)
                    out = out + ' '  
                  out = out + '*';
                }
                return out;
              }
              
              if (totalNutrients < 0) totalNutrients = 0;
              if (totalFilling < 1) totalFilling = 1;

              @:RATINGS_FILLING = [
                [3, 'Not very filling.'],
                [6, 'Pretty filling.'],
                [9, 'Very hearty.'],
                [11, 'MAX']
              ]

              @:RATINGS_NUTRIENTS = [
                [3, 'Not very nutritional.'],
                [6, 'Pretty nutrient-rich.'],
                [9, 'Very healthy.'],
                [11, 'MAX']
              ]


              @:nutrientsToRating::<-
                ::? {
                  foreach(RATINGS_NUTRIENTS) ::(i, val) {
                    when(totalNutrients < val[0]) send(:i)
                  }     
                  return RATINGS_NUTRIENTS->size-1;     
                }

              @:fillingToRating::<-
                ::? {
                  foreach(RATINGS_FILLING) ::(i, val) {
                    when(totalFilling < val[0]) send(:i)
                  }     
                  return RATINGS_FILLING->size-1;     
                }

              
              windowEvent.queueMessage(
                text: 'The meal is finished.\n\n'+
                  'Nutrients : ' + RATINGS_NUTRIENTS[nutrientsToRating()][1] + '\n' +
                  'Filling   : ' + RATINGS_FILLING[fillingToRating()][1]
              );
              
              state.tummy = 0.55 + (totalFilling / 2) * 0.1;
              if (state.tummy > 1) state.tummy = 1;
              
                            
              party.gainProfessionExp(
                exp:Entity.PROF_EXP_PER_KNOCKOUT * totalNutrients,
                onDone ::{
                  //windowEvent.jumpToTag(name:'EATFOOD', goBeforeTag:true);
                }
              )
              
              
              
              
            }
            @:food = foods[0];
            foods->remove(:0);
            
            windowEvent.queueMessage(
              text: 'The party shared the ' + food.name + '.'
            );
            
            
            windowEvent.queueMessage(
              renderable : {
                render ::{
                  @iter = 0;
                  foreach(party.members) ::(k, member) {
                    @:rating = member.judgeFood(:food);
                    canvas.renderTextFrameGeneral(
                      title: member.name,
                      lines : [
                        '"' + rating + '"'
                      ],
                      maxWidth : canvas.width / party.members->size,
                      leftWeight: iter * 0.5
                    );
                    
                    iter += 1;
                  }
                }
              },
              topWeight: 1,
              text: 'Eating: ' + food.name
            )
            totalFilling += food.edible.fillingRating
            totalNutrients += food.edible.nutrientRating;
            
            
            
            windowEvent.queueCustom(
              onEnter::{
                eatNext();
              }
            );
          }
          
          eatNext();
        }
        
        
        when (state.tummy > HUNGER_LEVELS[0][0]) 
          windowEvent.queueMessage(
            text: 'The party is not currently hungry.'
          )
        
        
        @:foods = party.inventory.items->filter(::(value) <- value.edible != empty);
        when (foods->size == 0) 
          windowEvent.queueMessage(
            text: 'Unfortunately, the party currently has no food...'
          );
        
        @selected = {};
        @hovered
        
        windowEvent.queueChoices(
          topWeight: 1,
          maxHeight : 6,
          keep :true,
          canCancel : true,
          jumpTag: 'EATFOOD',
          renderable : {
            render ::{
              if (hovered != empty)
                canvas.renderTextFrameGeneral(
                  topWeight: 0.3,
                  lines : canvas.refitLines(
                    input:[hovered.description],
                    maxWidth : canvas.width-7
                  )
                );

              canvas.renderTextFrameGeneral(
                topWeight: 0,
                lines : [
                  'Pick up to 3 foods for the party\'s meal.'
                ]
              );

              
            }
          },
          onHover ::(choice) {
            hovered = foods[choice-1];
          },
          
          onGetChoices ::{
            @list = [];
            foreach(foods)::(i, food) {
              list->push(:
                (if(selected[food] == true) '[x] ' else '[ ] ') + food.name
              );
            }
            
            list->push(value: 'Done.');
            return list;
          },
          onChoice::(choice) {
            when (choice == foods->size+1) ::<= {
              windowEvent.jumpToTag(name: 'EATFOOD', goBeforeTag:true);
              windowEvent.queueAskBoolean(
                renderable : {
                  render ::{
                    canvas.renderTextFrameGeneral(
                      topWeight: 0,
                      lines : canvas.refitLines(input:[
                        'Have a meal of' + ::<= {
                          @out = '';
                          foreach(selected->keys) ::(i, food) {
                            out = out + ', ' + (if(i == selected->keys->size-1) 'and ' else '') + food.name
                          }
                          return out;
                        } + '?'
                              
                      ], maxWidth: canvas.width-5)
                    )
                  }
                },
                
                onChoice::(which) {
                  when(which == false) empty;
                  eatThese(:selected->keys);
                }
              );  
            } 
            // toggle
            if (selected[hovered] == true)
              selected->remove(:hovered)
            else {  
              when (selected->keys->size >= 3) ::<= {
                windowEvent.queueMessage(
                  text: 'There\'s already 3 selected! Only up to 3 foods are supported.'
                )
              }
              selected[hovered] = true;
            }
              
          }
        );
      }
    }  
  }
);



return Party;
