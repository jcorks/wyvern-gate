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
@:Database = import(module:'game_class.database.mt');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:g = import(module:'game_function.g.mt');



@: reset ::{

@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:random = import(module:'game_singleton.random.mt');
@:Battle = import(module:'game_class.battle.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Item = import(module:'game_mutator.item.mt');
@:Entity = import(module:'game_class.entity.mt');
@:Scene = import(module:'game_database.scene.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

IslandEvent.database.newEntry(
  data: {
    id : 'base:weather:1',
    rarity: 3,    
    onEventStart ::(event) {
      // only one weather event at a time.
      when (event.island.events->any(condition::(value) <- value.base.id->contains(key:'base:weather'))) 0;
      @:world = import(module:'game_singleton.world.mt');
      match(world.season) {

        (world.SEASON.WINTER): windowEvent.queueMessage(
          text: random.pickArrayItem(list:[
            'It starts to snow softly.',
            'A thick snow obscures your vision.',
            'A quiet snowfall begins.',
          ])
        ),

        default: windowEvent.queueMessage(
          text: random.pickArrayItem(list:[
            'It starts to rain gently.',
            'It starts to storm intensely.',
            'It starts to rain.',
            'It starts to rain as a gentle fog rolls in.'
          ])
        )

        
        
      }
      return 14+(random.number()*20)->floor; // number of timesteps active
    },
    
    onIncrementTime ::(event) {
      
    },
    
    onStep ::(event) {
    
    },
    
    onEventEnd ::(event) {
      when(event.duration == 0) empty;
      windowEvent.queueMessage(
        text: random.pickArrayItem(list:[
          'The weather subsides.',
        ])
      );        
      
    }
  }
)





IslandEvent.database.newEntry(
  data: {
    id : 'base:bbq',
    rarity: 100, //5    
    onEventStart ::(event) {
      @:party = event.party;
      windowEvent.queueMessage(speaker: '???', text:'"Hey!"');
      windowEvent.queueMessage(text:'Someone calls out to the party.');
      windowEvent.queueMessage(text:'They are by a fire enjoying a meal.');
      windowEvent.queueMessage(speaker: '???', text:'"Care to join me? There\'s plenty to share!"');

      windowEvent.queueAskBoolean(
        prompt:'Sit by the fire?',
        onChoice::(which) {
          when(which == false)
            windowEvent.queueMessage(speaker:'???', text:'"Ah, I understand. Stay safe out there!"');

          windowEvent.queueMessage(text:'The party is given some food.');

          @StatSet = import(module:'game_class.statset.mt');
          if (random.try(percentSuccess:95)) ::<= {
            windowEvent.queueMessage(text:'The food is delicious.');
            foreach(event.party.members)::(index, member) {
              @oldStats = StatSet.new();
              oldStats.load(serialized:member.stats.save());
              member.stats.add(stats:StatSet.new(HP:(oldStats.HP*0.1)->ceil, AP:(oldStats.AP*0.1)->ceil));
              oldStats.printDiff(other:member.stats, prompt:member.name + ': Mmmm...');

              member.heal(amount:member.stats.HP * 0.1);
              member.healAP(amount:member.stats.AP * 0.1);
            }
            
          } else ::<= {
            windowEvent.queueMessage(text:'The food tastes terrible. The party feels ill.');
            @:Damage = import(module:'game_class.damage.mt');
            foreach(event.party.members)::(index, member) {
              @oldStats = StatSet.new();
              oldStats.load(serialized:member.stats.save());
              member.stats.add(stats:StatSet.new(HP:-(oldStats.HP*0.1)->ceil, AP:-(oldStats.AP*0.1)->ceil));
              oldStats.printDiff(other:member.stats, prompt:member.name + ': Ugh...');


              member.damage(
                attacker: member,
                damage: Damage.new(
                  amount:member.stats.AP * (0.1),
                  damageType : Damage.TYPE.PHYS,
                  damageClass: Damage.CLASS.AP
                ),
                dodgeable:false
              );
            }
          
          }

          @:nicePerson = event.island.newInhabitant();
          nicePerson.adventurous = true;
          nicePerson.interactPerson(
            party:event.party,
            skipIntro: true,
            onDone ::{
              if (!party.isMember(entity:nicePerson)) ::<= {
                if (nicePerson.isIncapacitated())
                  windowEvent.queueMessage(text:'You leave the body and walk away.')
                else
                  windowEvent.queueMessage(text:'You thank the person and continue on your way.')
              }
            }
          );

        }
      );
      return 0; // number of timesteps active
    },
    
    
    onIncrementTime ::(event) {
      
    },
    
    onStep ::(event) {
    
    },

    onEventEnd ::(event) {

    }
  }
)

IslandEvent.database.newEntry(
  data: {
    id : 'base:camp-out',
    rarity: 300, //5    
    onEventStart ::(event) {
      @:party = event.party;
      
      @needsHealing = false;
      foreach(party.members) ::(i, member) {
        if (member.hp < member.stats.HP)  
          needsHealing = true
      }
      
      when(!needsHealing) 0;
      
      if (party.members->keycount == 1) ::<= {
        windowEvent.queueMessage(
          speaker:party.members[0].name,
          text:'This looks like a good place to rest...'
        );
      } else ::<= {
        windowEvent.queueMessage(
          speaker:party.members[1].name,
          text:'"Can we take a break for a bit?"'
        );
      }

      windowEvent.queueAskBoolean(
        prompt:'Rest?',
        onChoice::(which) {
          when(which == false)
            windowEvent.queueMessage(speaker:'???', text:'The party continues on their way.');


          windowEvent.queueMessage(text:
            random.pickArrayItem(
              list:
              
              if (party.members->keycount == 1)
                [
                  party.members[0].name + ' sits next to the campfire in a peaceful silence.'
                ]                
              else
                [
                  'The party starts a fire and huddles up close to it, resting in silence.',
                  'The party makes a fire and sits, excitedly talking about the most recent endaevors.',
                  'The party sets up camp, and sleeps for a brief time.'   
                ]
                
            )
          );
          @StatSet = import(module:'game_class.statset.mt');
          
          windowEvent.queueCustom(
            onLeave::{
              @:world = import(module:'game_singleton.world.mt');
              for(0, 5*3)::(i) {
                world.incrementTime();
              }
      
              foreach(event.party.members)::(index, member) {
                if (random.try(percentSuccess:5)) ::<= {
                  @oldStats = StatSet.new();
                  oldStats.load(serialized:member.stats.save());
                  member.stats.add(stats:StatSet.new(HP:(oldStats.HP*0.1)->ceil, AP:(oldStats.AP*0.1)->ceil));
                  oldStats.printDiff(other:member.stats, prompt:member.name + ': I feel refreshed!');
                }

                member.heal(amount:member.stats.HP);
                member.healAP(amount:member.stats.AP);
              }
            },
            
            onEnter::{}
          );


        }
      );


      return 0;
    },
    
    
    onIncrementTime ::(event) {
      
    },
    
    onStep ::(event) {
    
    },

    
    onEventEnd ::(event) {

    }
  }
)



IslandEvent.database.newEntry(
  data: {
    id : 'base:encounter:normal',
    rarity: 1,    
    onEventStart ::(event) {
      @:world = import(module:'game_singleton.world.mt');
      // safe time
      when(world.time < world.TIME.LATE_EVENING) 0;
      when(world.party.inventory.gold < 100) 0;
      
      @chance = random.number(); 
      @:island = event.island;   
      @:party = event.party;
      
      windowEvent.queueMessage(
        text: 'A shadow emerges; the party is caught off-guard!'
      );       
      
      
         
      @enemies = 
          match(true) {
            (chance < 0.8): [
              island.newAggressor(),
              island.newAggressor(),          
              island.newAggressor()            
            ],
            
            (chance < 0.95):::<= {
              @:only = island.newAggressor();                        
              ::? {
                forever ::{
                  only.autoLevel();
                  if (only.level >= island.levelMax)
                    send();                  
                }
              }

              return [
                island.newAggressor(),
                only,
                island.newAggressor()                                
              ];
            },
            
            default: [
              island.newAggressor(),
              island.newAggressor()
            ]
          }
      ;

      foreach(enemies)::(index, e) {
        e.name = 'the ' + e.species.name + ' Thief';
      }
      
      @:stealg = (world.party.inventory.gold * 0.9)->ceil;
      windowEvent.queueMessage(
        speaker : enemies[0].name,
        text: '"Listen here: we know you got some G on ya. Give up ' + g(:stealg) + ' and we\'ll let you go. Don\'t be stupid, now."'
      );
      
      windowEvent.queueAskBoolean(
        prompt: 'Hand over ' + g(:stealg) + '?',
        onChoice::(which) {
          when(which == true) ::<= {
            windowEvent.queueMessage(
              speaker : enemies[0].name,
              text: '"Smart choice."'
            );            

            world.party.addGoldAnimated(amount:-stealg);
            windowEvent.queueMessage(
              text: 'The thieves vanish without a trace.'
            );            
          }
          
          windowEvent.queueMessage(
            speaker : enemies[0].name,
            text: '"Get \'em!"'
          );            

          world.battle.start(
            party,
            
            allies: party.members,
            enemies,
            landmark: {},
            loot : true,
            onEnd::(result){
              when(world.battle.partyWon()) empty;
              windowEvent.queueCustom(
                onEnter::{
                  @:instance = import(module:'game_singleton.instance.mt');
                  instance.gameOver(reason:'The party was wiped out.');
                }
              );        
            }
          );          
        
        }
      );
    
      return 0; // number of timesteps active
    },
    
    
    onIncrementTime ::(event) {
      
    },
    
    onStep ::(event) {
    
    },

    
    onEventEnd ::(event) {

    }
  }
)
}




@:IslandEvent = databaseItemMutatorClass.create(
  name: 'Wyvern.IslandEvent',
  items : {
    timeLeft : 0,
    duration : 0,
    startAt : empty   
  },
  database: Database.new(
    name : 'Wyvern.IslandEvent.Base',
    attributes : {
      id : String,
      rarity: Number,
      onEventStart : Function,
      onStep : Function,
      onIncrementTime : Function,
      onEventEnd : Function
    },
    reset     
  ),
    
  define:::(this, state) {    
  
    @party_;
    @island_;
    @landmark_;
    this.interface = {
      initialize ::(parent, base, currentTime, state) {
        @:world = import(module:'game_singleton.world.mt');
        
        @:Island = import(module:'game_mutator.island.mt');
        @:Landmark = import(module:'game_mutator.landmark.mt');
        
        @landmark;
        @island;
        
        if (parent->type == Island.type) ::<= {
          landmark = empty;
          island = parent;
        } else if (parent->type == Landmark.type) ::<= {
          landmark = parent;
          island = landmark.island;
        } else 
          error(detail:'Parents of Events can only be either Landmarks or Islands');
        
        @:party = world.party;        
        island_ = island;
        party_ = party;
        landmark_ = landmark;
      },

      defaultLoad ::(base, currentTime) {
        state.base = base; 
        state.startAt = currentTime;
        state.duration = base.onEventStart(event:this);
        state.duration = 0;
        state.timeLeft = state.duration;
        return this;
      },
    
      expired : {
        get :: <- state.timeLeft == 0
      },
      
      incrementTime :: {
        state.base.onIncrementTime(event:this);
        if (state.timeLeft > 0) state.timeLeft -= 1;
      },

      step :: {
        state.base.onStep(event:this);
      },
      
      duration : {
        get :: <- state.duration
      },
      
      island : {
        get :: <- island_
      },
      
      party : {
        get :: <- party_
      },
      
      landmark : {
        get :: <- landmark_
      }
    }
  }

);


return IslandEvent;
