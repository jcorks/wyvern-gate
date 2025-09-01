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


return ::{
  @:world = import(module:'game_singleton.world.mt')

  // Hello.
  // we are going to do some trickery
  
  @:self = world.island.newInhabitant(
    professionHint: 'base:adventurer'
  );
  self.name = 'the Leader';
  
  @stats = self.stats.save();
  stats.SPD = 10000;
  stats.ATK = 10;
  stats.HP = 6;
  self.stats.load(:stats);
  self.heal(amount:99999, silent:true);
  
  
  @:target = world.island.newInhabitant(
    professionHint: 'base:adventurer'
  );
  target.name = 'the Enemy';
  stats = self.stats.save();
  stats.SPD = 100;
  stats.ATK = 1;
  stats.DEF = 1;
  stats.HP = 3;
  target.stats.load(:stats);


  
  @:realLeader = world.party.leader;
  world.party.add(:self);
  world.party.leader = self;
  
  @realInventory = world.party.inventory.save();
  world.party.inventory.clear();



  @:doScene::(acts) {
    when(acts->size == 0) empty;
    @:next = acts[0];
    acts->remove(key:0);

    when(next.continue != empty) ::<= {
      windowEvent.queueInputEvents(:[
        {input:empty, waitFrames:20, callback::<- doScene(acts)}
      ]);
    }
    
    when(next.text != empty) ::<= {
      windowEvent.queueMessage(
        text:next.text,
        topWeight: if (next.topWeight == empty) 1 else next.topWeight,
        onLeave::<- doScene(:acts)
      );
      when(next.resolve)
        windowEvent.forceResolveNext();
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

    error(:'Invalid scene');

  }


  @turn1 = [
    {text:"Welcome to the battle tutorial. This will explain the basics of how to engage enemies."},
    {text:"This is the screen that you will see when fighting enemies."},
    {wait:true},
    {text:"Fighting is done in turns. The top right box shows the order determined for each combatant to take a turn. "},
    {text:"The higher the SPD of the combatant, the earlier their turn is."},
    {text:"The entries on the left of the screen show the basic status of each combatant, showing their AP and HP."},
    {wait:true},
    {text:"Keep an eye on combatant\'s remaining HP! When a combatant\'s HP reaches 0, they are knocked out."},
    {text:"If a combatant receives damage when their HP is 0, they will begin Dying."},
    {text:"When all allies or all enemies are incapacitated in some way, the battle ends."},

    
    // yield back to natural battle menu
    {continue:true},
    
    {resolve:true, text:"And finally, when it is the leader's turn, the menu below will appear. These are the actions that you can make as leader on your turn.", topWeight: 0.6},
    {text:"Note that you only control the party's leader. All other combatants will act on their own.", topWeight: 0.6},
    {text:"Before we go over these, let's cover some basics.", topWeight: 0.6},
    {text:"All actions that a combatant can do are referred to as Arts. Arts typically cost 2 AP to use. If an Art is used without enough AP, it will fail.", topWeight: 0.6},
    {text:"Note that each combatant gains 1 AP at the start of their turn. When a battle begins, each combatant starts with half of their total AP.", topWeight: 0.6},
    {text:"Most of the commands in this menu below confer different Arts that are available.", topWeight: 0.6},
    {wait:true},
    {text:"First is the Attack Art command. This Art is special in that it costs no AP.", topWeight: 0.6},
    {text:"It simply does physical damage with whatever is in hand.", topWeight: 0.6},
    {text:"Because it's costless, Attack is the most basic Ability Art, but it ends the turn after use.", topWeight: 0.6},

    // yield back to natural battle menu
    {continue:true},
    
    
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:20},
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:20},
      {input:empty, waitFrames:10}
    ]},
    {resolve:true, text:"The Item Art command uses an item from the party\'s inventory. Item use does not end the turn.", topWeight: 0.6},
    {continue:true},
    {inputs: [
      {input:windowEvent.CURSOR_ACTIONS.LEFT, waitFrames:20},
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:20},
      {input:empty, waitFrames:20}
    ]},
    {resolve:true, text:"The Wait Art command allows the user to rest for the turn, allowing them to gain 3 AP and, optionally, discard their normal Arts.", topWeight: 0.6},
    {continue:true},
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.UP, waitFrames:20},
      {input:windowEvent.CURSOR_ACTIONS.UP, waitFrames:20},
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:20},
      {input:empty, waitFrames:20}
    ]},
    {resolve:true, text:"The Arts command is where all the normal Arts are.", topWeight: 0.6},
    {text:"These Arts are drawn from a deck of Arts assigned to the combatant. At the start of combat, this deck is shuffled.", topWeight: 0.6},
    {text:"On the start of the combatant's turn, Arts are drawn from the deck until the combatant's hand contains 5 Arts.", topWeight: 0.6},
    {text:"As you fight, you will gain additional supporting Arts that you can customize your deck with in the Party menu outside of battle.", topWeight: 0.6},
    {text:"Let\'s look and see what Arts the Leader has drawn.", topWeight: 0.6},
    {continue:true},
    {inputs:[
      {input:empty, waitFrames: 5, callback ::{ 
        @:ArtsDeck = import(:'game_class.artsdeck.mt');
        // artificially create hand 
        self.deck.hand = [
          ArtsDeck.synthesizeHandCard(id:'base:stab', energy:ArtsDeck.ENERGY.B),
          ArtsDeck.synthesizeHandCard(id:'base:pebble', energy:ArtsDeck.ENERGY.C),
          ArtsDeck.synthesizeHandCard(id:'base:quick-shield', energy:ArtsDeck.ENERGY.A),
          ArtsDeck.synthesizeHandCard(id:'base:banish', energy:ArtsDeck.ENERGY.B),
          ArtsDeck.synthesizeHandCard(id:'base:cycle', energy:ArtsDeck.ENERGY.C),
        ]
      }},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:5},
      {input:empty, waitFrames:10},
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:25},
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:25},
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:25},
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:25},
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:25}
    ]},
    {resolve: true, text:"These Arts are treated like cards in a deck. Each Art is described along with any effects it can confer upon use."},
    {text:"Note that there are different types of Arts."},
    {wait:true},
    {text:"This Art is an Ability, signified with the '//' symbol. Usually they are potent, but Abilities end your turn upon use."},
    {continue:true},
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:5},
      {input:empty, waitFrames:30}
    ]},
    {resolve:true, text:"This Art is an Effect, signified with the '^^' symbol. Effects can be freely used without ending the turn."},
    {text:"Remember, unless youre using a special Art like Attack or Wait, you need at least 2 AP to use Arts!"},
    {continue:true},
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:5},
      {input:empty, waitFrames:30}
    ]},
    {resolve:true, text:"This Art is a Reaction, signified with '!!'. Reactions can only be used in response to another Art."},
    {text:"If any are in your hand, you will be prompted when these Arts are useable."},
    {continue:true},
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:5},
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:5},
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:5},
      {input:empty, waitFrames:10}
    ]},
    {resolve:true, text:"Take a second to look at the description of this Art."},
    {wait:true},
    {wait:true},
    {wait:true},
    {text:"There are many attributes to each Art. Let's look at one called the Energy."},
    {text:"When each Art in your hand is drawn, it is assigned one of 4 Energy types: A, B, C, or D."},
    {text:"In addition to being in the description, the Energy type is reflected in the card frame symbols, so each card with the same Energy will immediately look similar.", topWeight: 0.6},
    {text:"If 2 Arts in hand are the same Energy, they can be combined."},
    {wait:true},
    {text:"If an Ability is combined with an Art, the Ability gains a level. Higher-leveled Abilities are more potent."},
    {text:"If an Effect is combined, the Effect gains a counter. When played, the combatant using it will gain AP for each counter."},
    {text:"Utilizing combinations is key to a good flow of Arts."},
    {wait:true},
    {text:"It looks like there are a few Arts with the same Energy types. Let's combine the Arts in our hand.", topWeight: 0.6},
    {continue:true},
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:25},
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:25},
      {input:empty, waitFrames:10},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:25},
      {input:empty, waitFrames:10},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:25},
      {input:empty, waitFrames:10},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:25},
      {input:empty, waitFrames:10},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:25},
      {input:empty, waitFrames:10}
    ]},
    {resolve:true, text:"Because Stab is an Ability, it gains a level, making its effects more potent."},
    {text:"It looks like there's one more Arts combination we can make. Let's combine them."},
    {continue:true},
    {inputs:[
      {input:windowEvent.CURSOR_ACTIONS.RIGHT, waitFrames:20},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:25},
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:25},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:25},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:25},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:25},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:25},

      {input:empty, waitFrames:10}
    ]},
    {resolve:true, text:"Now our hand size is reduced to 3. Recall that on the start of the next turn, the hand is drawn back to 5 cards."},
    {text:'Also recall that Effect Arts can be used freely in a turn while Ability arts end the turn.'},    
    {text:'Now that you know the basics, try to play out the rest of the battle.'}
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
      render::<- canvas.blackout()
    },
    onEnter ::{    
      world.battle.start(
        awkwardControlHack : true,
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

          when(endTurn) ::<= {
            doScene(acts:endTurn);
            endTurn = empty;
          }
        }
      );
    }
  ); 

}
