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
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Inventory = import(module:'game_class.inventory.mt');


return ::{
  @:world = import(module:'game_singleton.world.mt')

  // Hello.
  // we are going to do some trickery
  
  @:self = world.island.newInhabitant(
    professionHint: 'base:adventurer'
  );
  self.name = 'the Leader';
  self.removeAllProfessionArts();
  self.unequipAll(inventory : Inventory.new(), silent:true);
  
  @stats = self.stats.save();
  stats.SPD = 10000;
  stats.ATK = 10;
  stats.HP = 6;
  self.stats.load(:stats);
  self.heal(amount:99999, silent:true);
  
  
  @:target = world.island.newInhabitant(
    professionHint: 'base:adventurer'
  );
  target.unequipAll(inventory : Inventory.new(), silent:true);
  target.removeAllProfessionArts();

  target.name = 'the Enemy';
  stats = self.stats.save();
  stats.SPD = 100;
  stats.ATK = 1;
  stats.DEF = 1;
  stats.HP = 3;
  target.stats.load(:stats);
  @:TAG = "BATTLETUTORIALNESTED";


  
  @:realLeader = world.party.leader;
  world.party.add(:self);
  world.party.leader = self;
  
  @realInventory = world.party.inventory.save();
  world.party.inventory.clear();



  @:doScene::(acts) {
    when(acts->size == 0) empty;
    @:next = acts[0];
    acts->remove(key:0);
    
    when (next.endNested != empty) ::<= {
      if (windowEvent.canJumpToTag(:TAG))
        windowEvent.jumpToTag(
          name: TAG
        )
      when(next.resolve)
        windowEvent.forceResolveNext();
      
    }
    
    
    @:startSceneNext ::{

      /*when(next.continue != empty) ::<= {
        windowEvent.queueInputEvents(:[
          {input:empty, waitFrames:20, callback::<- doScene(acts)}
        ]);
      }*/
      when(next.callback) ::<= {
        next.callback();
        doScene(acts);
      }
      
      when(next.text != empty) ::<= {
        windowEvent.queueMessage(
          text:next.text,
          topWeight: if (next.topWeight == empty) 1 else next.topWeight,
          onLeave::<- doScene(:acts)
        );
      }
      when(next.wait != empty) ::<= {
        windowEvent.queueCustom(
          waitFrames : 40,
          onLeave ::{
            doScene(acts);
          }
        );
      }
    
      when(next.inputs != empty) ::<= {
        windowEvent.queueInputEvents(:[
          ...next.inputs,
          {input:empty, waitFrames:0, callback:: {
            doScene(acts)
          }}
        ]);
      }
      //error(:'Invalid scene');

    }
    if (next.nested)
      if (next.waitFrames == empty)
        windowEvent.queueNestedResolve(
          jumpTag: TAG,
          onEnter :: {
            doScene(acts)
          },
          onLeave ::{
            doScene(acts)
          }
        )
      else
        windowEvent.addDelayedCallback(
          waitFrames: next.waitFrames,
          callback ::{
            windowEvent.queueNestedResolve(
              jumpTag: TAG,
              onEnter :: {
                doScene(acts)
              },
              onLeave ::{
                breakpoint();
                doScene(acts)
              }
            )
            windowEvent.forceResolveNext();
          }
        )
    else
      startSceneNext();



  }


  @turn1 = [
    {nested: true,text:"Welcome to the battle tutorial. This will explain the basics of how to engage enemies."},
      {text:"This is the screen that you will see when fighting enemies."},
      {wait:true},
      {text:"Fighting is done in turns. The top right box shows the order determined for each combatant to take a turn. "},
      {text:"The higher the SPD of the combatant, the earlier their turn is."},
      {text:"The entries on the left of the screen show the basic status of each combatant, showing their AP and HP."},
      {wait:true},
      {text:"Keep an eye on combatant\'s remaining HP! When a combatant\'s HP reaches 0, they are knocked out."},
      {text:"If a combatant receives damage when their HP is 0, they will begin Dying."},
      {text:"When all allies or all enemies are incapacitated in some way, the battle ends."},
    {endNested:true},

    // yield back to natural battle menu
    {nested:true, waitFrames:30},
      {text:"When it is the leader's turn, the menu below will appear. These are the actions that you can make as leader on your turn.", topWeight: 0.6},
      {text:"Note that you only control the party's leader. All other combatants will act on their own.", topWeight: 0.6},
      {text:"Before we go over these, let's cover some basics.", topWeight: 0.6},
      {wait:true},
      {text:"All actions that a combatant can do are referred to as Arts. Unless they're special, Arts cost 2 AP to use. If an Art is used without enough AP, it will fail.", topWeight: 0.6},
      {text:"When an Art is used, it will lose its charge. Arts recharge each turn, or after walking around outside battle.", topWeight: 0.6},
      {wait:true},
      {text:"Note that each combatant gains 1 AP at the start of their turn. When a battle begins, each combatant starts with half of their total AP.", topWeight: 0.6},
      {wait:true},
      {text:"Now, let\'s look at the battle menu."},
      {text:"First is the Attack Art command. This Art is special in that it costs no AP and has no needed recharge.", topWeight: 0.6},
      {text:"It simply does physical damage with whatever is in hand.", topWeight: 0.6},
      {text:"Because it's costless, Attack is the most basic Ability Art, but it ends the turn after use.", topWeight: 0.6},
    {endNested:true},    
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:20},
      {input:empty, waitFrames:10}
    ]},
    {nested:true, waitFrames:10},
      {text:"Check allows you to see the status of your your allies and enemies.", topWeight: 0.6},
    {endNested:true},
    
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:20},
      {input:empty, waitFrames:10}
    ]},
    {nested:true, waitFrames:10},
      {text:"Wait is a special Art command that allows the user to rest for the turn, allowing them to gain 3 AP.", topWeight: 0.6},
    {endNested:true},

    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:20},
      {input:empty, waitFrames:10}
    ]},
    {nested:true, waitFrames:10},
      {text:"The Log will open a window that shows all the events that have happened in the battle so far.", topWeight: 0.6},
    {endNested:true},

    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.UP, waitFrames:20},
      {input:empty, waitFrames:10}
    ]},
    
    {nested:true, waitFrames:10},
      {text:"The Item Art command uses an item from the party\'s inventory. Item use does not end the turn, but does cost 2 AP to use.", topWeight: 0.6},
    {endNested:true},

    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.UP, waitFrames:20},
      {input:empty, waitFrames:10}
    ]},
    
    {nested:true, waitFrames:10},
      {text:"And finally, the Arts command is where the leader can choose to use any Art currently equipped.", topWeight: 0.6},
      {text:"Equipped Arts come from different sources, such as the currently equipped weapon, the profession, and learnable support Arts.", topWeight: 0.6},
      {text:"As you fight, you will gain additional supporting Arts that you can customize your loadout with in the Party menu outside of battle.", topWeight: 0.6},
      {text:"Let\'s choose the Arts option.", topWeight: 0.6},
    {endNested:true},

    {inputs:[
      {input:empty, waitFrames: 5, callback ::{ 
        @:Arts = import(:'game_mutator.arts.mt');
        // artificially create hand 
        self.supportArts = [
          Arts.new(base:Arts.database.find(id:'base:stab')),
          Arts.new(base:Arts.database.find(id:'base:fire')),
          Arts.new(base:Arts.database.find(id:'base:doublestrike')),

          Arts.new(base:Arts.database.find(id:'base:pebble')),
          Arts.new(base:Arts.database.find(id:'base:quick-shield')),
          Arts.new(base:Arts.database.find(id:'base:banish')),
        ]
      }},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:5},
      {input:empty, waitFrames:10},
    ]},
    {nested:true, waitFrames:10},
      {text:"Before choosing an Art, the category must be chosen.", topWeight: 0.6},
      {text:"Arts come in 2 varieties.", topWeight: 0.6},
      {text:"Ability Arts are generally more influential and potent, but will end the turn after use.", topWeight: 0.6},
    {endNested:true},
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.UP, waitFrames:20},
      {input:empty, waitFrames:10}
    ]},
    {nested:true, waitFrames:10},
      {text:"Effect Arts can be used freely without ending a turn.", topWeight: 0.6},
      {text:"Remember, unless youre using a special Art like Attack or Wait, you need at least 2 AP to use any Art!", topWeight: 0.6},
      {wait:true},
      {text:"Let's look at Effect arts first.", topWeight: 0.6},
    {endNested:true},
    {inputs:[
      {input:empty, waitFrames:20},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:5},
      {input:empty, waitFrames:30}
    ]},
    {nested:true, waitFrames:10},
      {text:"When selecting an Art to use, the charge amount and name of the Art are shown.", topWeight: 0.6},
      {text:"Selecting an Art displays what it does when used.", topWeight: 0.6},
    {endNested:true},
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:5},
      {input:empty, waitFrames:60}
    ]},
    {nested:true, waitFrames:10},
      {text:"Along with using the Art, there are a few other options.", topWeight: 0.6},
    {endNested:true},
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:20},
      {input:empty, waitFrames:10}
    ]},
    {nested:true, waitFrames:10},    
      {text:"When fully charged, an Art's charges can be donated to another Art. This never ends the turn.", topWeight:0.6},
    {endNested:true},
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:20},
      {input:empty, waitFrames:10}
    ]},
    {nested:true, waitFrames:10},
      {text:"When fully charged, an Art's charge can be depleted to gain 1 AP. This also never ends the turn.", topWeight:0.6},
      {text:"Let's choose to use the Art 'Pebble'.", topWeight:0.6},
      {text:"'Pebble' can be used to very lightly damage an enemy, but it has the benefit of being an Effect with a low recharge requirement.", topWeight:0.6},
    {endNested:true},
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:30},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:40},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:80},
    ]},
    {nested:true, waitFrames:60},
      {text:"Another note: When choosing to use an Art, certain arts will allow aiming for a specific part of the body.", topWeight:0.6},
      {text:"The effect of aiming each body part is slightly different.", topWeight:0.6},
    {endNested:true},

    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:50},
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:50},
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:50},
    ]},

    {nested:true, waitFrames:30},
      {text:"Aiming for the body is the most common option.", topWeight:0.6},
    {endNested:true},


    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:50},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:60},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:60},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:60},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:100},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:60},
    ]},
    {nested:true, waitFrames:10},
      {text:'Now that you know the basics, try to play out the rest of the battle.'},
      {callback ::<- world.battle.requestRedrawBG()},
    {endNested:true}

  ];

  /*  
  @endTurn = [
    {text:'Here are some extra pointers about attacking.', topWeight: 0.5},
    {text: 'When choosing an Art that attacks someone, the one getting attacked may have a chance to block. If so, they will choose a body part to block. If this matches the attacker\'s aiming part, then the attack is nullified.', topWeight: 0.5},
    {text: 'Note that when the leader is attacked and they\'re able to block, they will have a chance to choose a part to defend.', topWeight: 0.5},
    {text:'In most cases, aiming for the body is safest, as it has unreduced damage. However, be aware that most combatants will expect this and will try to defend this more often.', topWeight: 0.5},    
    {text:'It\'s also notable that some Arts, like offensive magick, are not able to be aimed to specific parts and will just focus on the body of the target.', topWeight: 0.5}
  ]
  */
  
  
  
  windowEvent.queueNestedResolve(
    renderable:{
      render::<- canvas.fill()
    },
    onEnter ::{    
      world.battle.start(
        party:world.party,
        allies: [self],
        enemies: [target],
        landmark:{},
        skipResults: true,

        
        onTurn::(entity, battle, landmark) {
          if (entity == self) ::<= {
            when(turn1) ::<= {
              doScene(acts:turn1);
              turn1 = empty;
            }

          }
        },
        
        onTurnPrep :: {
          /*
          when(endTurn != empty && turn1 == empty) ::<= {
            doScene(acts:endTurn);
            endTurn = empty;
          }
          */
        
        },
        
        onEnd::(result) {
          world.party.remove(member:self, silent:true);
          world.party.leader = realLeader;
          world.party.inventory.load(:realInventory);

          /*when(endTurn) ::<= {
            doScene(acts:endTurn);
            endTurn = empty;
          }*/
        }
      );
    }
  ); 

}
