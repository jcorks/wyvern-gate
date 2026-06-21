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
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');



@:EVENTS = [
  // About:    called after an effect has first been added.
  // returns:  ignored 
  // args:
  //   - data:   Generic data per-effect.
  "onAffliction",

  // About:    called before user is giving damage. set damage amount to 0 to cancel the attack.
  //           Propogation stops if damage.amount <= 0
  // returns:  ignored 
  // args:
  //   - to:      The one being attacked.
  //   - damage:  the damage information from the attack (Damage.type)
  //   - targets: the intended target
  //   - data:   Generic data per-effect.
  "onPreAttackOther",

  // About:    Called AFTER the user has explicitly damaged a target 
  // returns:  ignored 
  // args:
  //   - to: the one being attacked 
  //   - damage: the damage information from the attack. (Damage.type)
  //   - data:   Generic data per-effect.
  "onPostAttackOther",

  // About:    called when user is attacked, before being damaged. set damage amount to 0 to cancel attack
  //           Propogation stops if damage.amount <= 0
  // returns:  ignored 
  // args:     
  //   - attacker: the one attacking 
  //   - damage: the damage information from the attack. (Damage.type);
  //   - data:   Generic data per-effect.
  "onPreAttacked",


  // Event:    
  // About:    called when user is attacked after damage is successful and non-zero
  // returns:  ignored 
  // args:     
  //   - attacker: the one attacking
  //   - damage: the damage information from the attack. (Damage.type)
  //   - data:   Generic data per-effect.
  "onPostAttacked",

  // About:    Called once when removed. All effects will be removed at some point.
  // returns:  ignored
  // args:
  //   - data:   Generic data per-effect.
  "onRemoveEffect",

  // About:    Called when an effect is forcibly removed, that is, not from reaching its duration 
  //           and not from a battle ending.
  // returns:  false prevents removal of the effect
  // args:
  //   - data:   Generic data per-effect.
  //   - effectData 
  //     - id: the effect being given 
  //     - duration: the duration in turns
  "onEffectRemoveForced",

  
  // About:    Called before damaging something. Can cancel by setting damage amount to 0. This also cancels propogation
  // returns:  ignored 
  // args:
  //   - data:   Generic data per-effect.
  //   - attacker: the one attacking 
  //   - damage: the damage information from the attack. (Damage.type);
  "onPreDamaged",


  // About:    Called after damaging something. 
  // returns:  ignored 
  // args:
  //   - data:   Generic data per-effect.
  //   - attacker: the one attacking 
  //   - damage: the damage information from the attack. (Damage.type);
  "onPostDamaged",

  // About:    Called on the turn of the holder.
  // returns:  Cancels holders turn if any return false
  //           returning false does not stop propogation
  // args:
  //   - data:   Generic data per-effect.
  "onNextTurn",

  // Events:   
  // About:    when stats are recalculated for the holder.
  // returns:  ignored
  // args:
  //   - data:   Generic data per-effect.
  "onStatRecalculate",

  // About:    Called before healing is applied. amount can be set to 0 to cancel healing 
  // returns:  ignored
  // args
  //   - data:   Generic data per-effect.
  //   - healingData
  //     - amount: healing which is applied. propogation is cancelled if amount is 0 or below.
  "onPreHeal",

  // About:    Called after healing is applied. amount can be set to 0 to cancel healing 
  // returns:  ignored
  // args
  //   - data:   Generic data per-effect.
  //   - healingData
  //     - amount: healing which is applied. propogation is cancelled if amount is 0 or below.
  "onPostHeal",


  // About:    Called when this entity blocks an attack
  //           Most commonly from the Def V Dex calc or part matching
  // returns:  ignored 
  // args:
  //   - data:   Generic data per-effect.
  //   - attacker: the one attacking
  //   - damage: the info about the damaged
  //   - blockData
  //     - targetDefendPart: the part chosen by the holder to block 
  //     - targetPart: the part chosen by the attacker to attack
  "onSuccessfulBlock",

  // About:    Called when the holder's attack got blocked 
  // returns:  ignored 
  // args:
  //   - data:   Generic data per-effect.
  //   - from: the one being attacked
  "onGotBlocked",
  
  // About:    called before committing an action (art)
  // returns:  return false to prevent effect from being added
  // args:
  //   - data:   Generic data per-effect.
  //   - action: The battle action
  "onPreAction",

  // About:    called after committing an action (art).  
  // args:
  //   - data:   Generic data per-effect.
  //   - action: The battle action
  "onPostAction",

  // About:    called before adding an effect. EffectData is editable
  // returns:  return false to prevent effect from being added
  // args:
  //   - data:   Generic data per-effect.
  //   - from: the entity giving the effect     
  //   - item: the item involved with the effect 
  //   - effectData 
  //     - id: the effect being given 
  //     - duration: the duration in turns
  "onPreAddEffect",

  // About:    called after adding an effect.
  // returns:  ignored 
  // args:
  //   - data:   Generic data per-effect.
  //   - from: the entity giving the effect
  //   - item: the item involved with the effect
  //   - id: the art id of the effect
  //   - duration: the number of turns that the effect will be added for
  "onPostAddEffect",

  // About:    called after getting critical hit 
  // returns:  ignored 
  // args:
  //   - data:   Generic data per-effect.
  //   - attacker: the one performing the crit.
  "onCritted",

  // About:    called after getting critical hit on a target
  // returns:  ignored 
  // args:
  //   - data:   Generic data per-effect.
  //   - to: the one receiving the critical hit
  "onCrit",

  // About:    called after killing a target
  // returns:  ignored 
  // args:
  //   - data:   Generic data per-effect.
  //   - to: the one getting killed
  "onKill",

  // About:    called after knocking out a target
  // returns:  ignored 
  // args:
  //   - data:   Generic data per-effect.
  //   - to: the one getting knocked out
  "onKnockout",

  // About:    called before removal of the effect due to its duration being 0
  // returns:  ignored 
  // args:
  //  - data:   Generic data per-effect.
  "onDurationEnd", 
  
  // About:    called after the holder gets knocked out.
  // returns:  ignored 
  // args:
  //  - data:   Generic data per-effect.
  //  - from: the one who caused it.      
  "onKnockedOut",

  // About:    called before removal of the effect due to its duration being 0
  // returns:  ignored 
  // args:
  //  - data:   Generic data per-effect.
  "onDurationEnd"
]

@:eventLookup = {};
foreach(EVENTS) ::(k, v) {
    eventLookup[v] = true;
}


@:EffectStack = LoadableClass.create(
  name: 'Wyvern.EffectStack',
  statics : {
    CANCEL_PROPOGATION : {get::<-'you-can-(Not)-advance'},
    EVENTS : EVENTS,
    
    // for custom stuff! mods, do your best!
    addRecognizedEvent ::(event) {
      EVENTS->push(:event);
      eventLookup[event] = true;
    }
  },
  items : {
    innateEffects : empty,
    effects : empty,
  },
  define:::(state, this) {
    @:Effect = import(module:'game_database.effect.mt');
    @:subscribers = {};
    
    @:getAll :: <- [
      ...state.innateEffects,
      ...state.effects
    ];

    @:remove ::(which) {
      @:effect = Effect.find(:which.id);
      
    }
    
    @holder;
    @events = true;
  
    this.interface = {
      defaultLoad ::(parent) {
        state.innateEffects = [];
        state.effects = [];
        holder = parent;      
      },
      
      load ::(serialized, parent) {
        holder = parent;
        state.load(serialized, parent:this);
      },
      
      subscribe ::(callback) {
        subscribers->push(:callback);
      },
      
      events : {
        set ::(value) <- events = value
      },
      
      save :: {
        @:Entity = import(:'game_class.entity.mt');
        // FAILSAFE HERE:
        // if your non-innate effects contain an entity reference, 
        // it will error here instead of erroring mysteriously in the 
        // state stack.
        foreach(state.effects) ::(k, eff) {
          foreach(eff) ::(k, v) {
            if (v => Entity.type)
              error(:"Hello! you seem to have an entity in your effect stack! This is not possible under normal circumstances, as all permanent entities will already have an entry in the the world save and the duplicate would create a harder-to-find error. So this appeared instead! Try to not have targeted effects outside battle, or make sure effects are cleared properly before saving.");
          }
        }
      
        return state.save();
      },
      
      addInnate::(id, item, from) {
        @:Item = import(module:'game_mutator.item.mt');
        if (item == empty) item = Item.NONE;
        @:Arts = import(module:'game_mutator.arts.mt');

        if (item == empty)
          item = Item.NONE;

        if (from == empty)
          from = holder;

        @:ref = {
          holder : holder,
          from : from,
          id : id,
          item : item,
          duration : Arts.A_LOT,
          data : {}
        };
        state.innateEffects->push(:ref);
        this.emitEvent(name: 'onAffliction', filter::(value) <- ref == value);
        
      },
      
      removeInnate::(id, item) {
        @:index = state.innateEffects->findIndexCondition(::(value) <- 
          value.id == id &&
          (if (item == empty) true else value.item == item)
        );
        
        when(index == -1) empty;
        @:which = state.innateEffects[index];
        
        this.emitEvent(
          name : 'onRemoveEffect',
          filter ::(value) <- value == which
        );
        
        state.innateEffects->remove(:index);
      },
      
      getAll : getAll,
      
      add::(id, duration => Number, item, from, noNotify) {
        @effect = Effect.find(:id);
        if (effect.hasTraits(:Effect.TRAIT.INSTANTANEOUS))
          duration = 0;
          
        @:Item = import(module:'game_mutator.item.mt');
        
        if (item == empty)
          item = Item.NONE;
        
        if (from == empty)
          from = holder;

        // already added, remove current effect and replace!
        if (effect.stackable == false && state.effects->findIndexCondition(::(value) <- id == value.id) != -1) ::<= {
          this.removeByFilter(::(value) <- value.id == id);                        
        }
        
      
        @:r = {
          holder: holder,
          id : id,
          duration : duration,
          from : from,
          item : item,
          data : {}
        };
        state.effects->push(:r);
        
        this.emitEvent(name: 'onAffliction', filter::(value) <- r == value);

        if (noNotify != true && holder != empty && holder.battle != empty) ::<= {
          holder.notifyEffect(
            isAdding: true,
            effectIDs : [id]
          );
        }


        
        if (duration == 0) ::<= {
          this.removeByFilter(::(value) <- value == r);                
        }

      },
      
      removeByFilter::(filter) {
        @all = [...state.effects]->filter(:filter);
        when(all->size == 0) empty;

        all = all->filter(::(value) <-
          ::? {
            // forget to ask someone?
            @:rets = this.emitEvent(
              name : 'onEffectRemoveForced',
              effectData : value
            );
            
            foreach(rets) ::(k, ret) {
              if (ret.returned == false)
                send(:false);
            }
            return true;
          }
        );
        
        when (all->size == 0) empty;

        
        @:allrev = {};
        foreach(all) ::(i, v) {
          allrev[v] = true;
        }
        

        
        this.emitEvent(
          name : 'onRemoveEffect',
          filter::(value) {
            return allrev[value] == true
          }
        );

        if (holder != empty && holder.battle != empty) ::<= {
          holder.notifyEffect(
            isAdding: false,
            effectIDs : all->map(::(value) <- value.id)
          );
          
          holder.checkStatChanged();
        }
        
        state.effects = state.effects->filter(::(value) <- allrev[value] != true);
      },
      
      getAllByFilter::(filter) {
        return state.effects->filter(:filter);
      },
      
      hasEffectID ::(id) {
        @set = this.getAllByFilter(::(value) <- value.id == id);
        when(set == empty || set->size == 0) false;
        return true;
      },

      removeAllByID::(id) {
        this.removeByFilter(
          ::(value) <- value.id == id
        );
      },
      
      removeByID::(id) {
        @index = state.effects->findIndexCondition(::(value) <- value.id == id);
        when(index == -1) empty;
        @:which = state.effects[index];
        this.removeByFilter(::(value){
          return value == which;
        });
      },

      
      
      emitEvent::(*args) {
        when(events == false) empty;
        @:name = args.name => String;
        when(eventLookup[name] == empty)
          error(:'Tried to emit an unrecognized event. What the heck is this thing?? (' + name + '?)');
        @:emitCondition = args.emitCondition;
      

        if (subscribers->size > 0) ::<= {
          args.holder = holder;
          foreach(subscribers) ::(k, v) {
            v(*args);
          }
        }

        
        @all = if (args.filter)
          [...getAll()]->filter(:args.filter)
        else 
          getAll()
        ;
        when(all->size == 0) [];


      
        @:ret = [];
        ::? {
          foreach(all) ::(k, v) {
            @:effect = Effect.find(:v.id);
            if (emitCondition != empty && !emitCondition(:v)) send();


            @:cb = effect.events[name];
            when(cb == empty) empty;
            
            args.from = v.from;
            args.item = v.item;
            args.holder = holder;
            args.duration = v.duration;
            args.data = v.data;
            
            @:r = cb(*args);
            
            if (r == EffectStack.CANCEL_PROPOGATION)
              send();
            
            if (r != empty) 
              ret->push(:{
                id : v.id,
                returned : r
              });
          }
        }
        return ret;
      },
      
      modStats::(stats) {
        foreach(getAll())::(index, effectSet) {
          @:effect = Effect.find(id:effectSet.id);
          stats.mod(stats:effect.stats);
        }
        return this.emitEvent(
          name: 'onStatRecalculate',
          holder,
          stats
        );
      },
      
      endTurn:: {
        @:inSet = {};
        foreach(state.effects) ::(i, e) {
          e.duration -= 1;
          if (e.duration == 0) ::<= {
            inSet[e] = true;
          }
        }
        this.emitEvent(
          name : 'onDurationEnd',
          filter ::(value) <- inSet[value] == true
        );        
        
        this.removeByFilter(::(value) <- inSet[value] == true);        
      },
      
      
      queueList ::(
        canCancel,
        keep,
        onChoice,
        prompt,
        onCancel
      ){
        @:descriptiveList = import(:'game_function.descriptivelist.mt');
        
        
        @:turnCount ::(effect) {
          @:count = effect.duration;
          when(count > 99) 'A long time'
          return '' + count;
        }
        
        @:listTraits ::(flags) {
          @:out = [];
          
          if (flags & Effect.TRAIT.SPECIAL)  out->push(:'Special');
          if (flags & Effect.TRAIT.AILMENT)  out->push(:'Status Ailment');
          if (flags & Effect.TRAIT.BUFF)     out->push(:'Buff');
          if (flags & Effect.TRAIT.DEBUFF)   out->push(:'Debuff');
          if (flags & Effect.TRAIT.REVIVAL)  out->push(:'Revival');
          
          when(out->size == 0)
            'None'
          
          return out->reduce(::(previous, value) <- 
            if (previous == empty)
              value
            else 
              previous + ', ' + value
          )
        }
        
        @:limit::(str) {
          when (str->length > 18) 
            str->substr(from:0, to:15) + '...'
            
          return str;
        }
        
        @:items = this.getAll()->map(to::(value) { 
          @:effect = Effect.find(:value.id);
          @:symbol = Effect.TRAITS_TO_DOMINANT_SYMBOL(:effect.traits);
          return [
            limit(:'(' + symbol + ') ' + effect.name),
            [
              'Name:        ' + effect.name,
              'Traits:      ' + listTraits(:effect.traits),
              'Turns left:  ' + turnCount(:value), 
              'Description: ' + effect.description
            ]
          ]
        });
        
        descriptiveList(
          items,
          canCancel,
          keep,
          prompt,
          listRatio: 0.4,
          onChoice,
          onCancel
        );
      },      
      
      // gets all combined traits from effects
      traits : {
        get ::{
          @traits = 0;
          foreach(state.effects) ::(i, v) {
            traits |= Effect.find(:v.id).traits;
          }
          foreach(state.innateEffects) ::(i, v) {
            traits |= Effect.find(:v.id).traits;
          }
          return traits;
        }
      },
      
      
      clear::(all)  {
        @inSet = {};
        foreach(state.effects) ::(i, v) {
          inSet[v] = true;
        }
        
        if (all == true) ::<= {
          foreach(state.innateEffects) ::(i, v) {
            inSet[v] = true;
          }
        }
        
        
        @:ret = this.emitEvent(
          name: 'onRemoveEffect',
          filter::(value) <- inSet[value] == true
        );
        state.effects = [];
        if (all == true)
          state.innateEffects = [];
        return ret;
      }
    }  
  }
);

return EffectStack;
