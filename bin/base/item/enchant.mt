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
@:Database = import(module:'core/data/database.mt');
@:databaseItemMutatorClass = import(module:'core/data/databaseitemmutatorclass.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:random = import(module:'core/random.mt');
@:Arts = import(:'base/arts.mt');
@:ArtsDeck = import(:'base/arts/deck.mt');
@:Damage = import(module:'base/entity/damage.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');



@:CONDITION_EVENT_DESCRIPTION = {
  onAffliction : ["When a new effect is added", 'On New Effect'],
  onPreAttackOther : ["Right before attacking a target", 'Before Attack'],
  onPostAttackOther : ["After damaging a target", 'After Attack'],
  onPreAttacked : ["Before taking damage from an attack", 'Before being Attacked'],
  onPostAttacked : ["After taking damage from an attack", 'After being Attacked'],
  onRemoveEffect : ["When an effect is removed", 'On Effect Remove'],
  onEffectRemoveForced : ["When an effect is forcibly removed", 'On Effect Force Remove'],
  onPreDamaged : ["Right before getting damaged", 'Before Damaged'],
  onPostDamaged : ["After getting damaged", 'After Damaged'],
  onNextTurn : ["On the start of the holder's turn", 'On Turn'],
  //"onStatRecalculate" // banning this one for now
  onPreHeal : ['Before getting healed', 'Before Heal'],
  onPreHeal : ['After getting healed', 'After Heal'],
  onSuccessfulBlock : ["When successfully blocking an attack", 'On Block'],
  onGotBlocked: ["Upon having the holder\'s attack blocked", 'Upon Getting Blocked'],
  onPreAction: ["Right before using an Art", 'Before Art'],
  onPostAction: ["After using an Art", 'After Art'],
  onPreAddEffect: ["Before a new effect is added to the holder", 'Before New Effect'],
  onPostAddEffect: ["After a new effect is added to the holder", 'After New Effect'],
  //onCritted: ["When hit with a critical hit", 'When Crit\'d'],
  //onCrit: ["When landing a critical hit", 'On Crit'],
  //onKill: ["Upon killing a target", 'After Murder'],
  onKnockout: ["Upon knocking out target", 'On Knockout'],
  //"onDurationEnd", // too much
  onKnockedOut: ["When getting knocked out", 'On Knocked Out']
};



@:CONDITION_ENCHANT_TURNS = 3;
@:CONDITION_TYPE_CHANCE = 30;
@:BAD_EFFECT_CHANCE = 20;

@:Effect = import(module:'base/entity/effect.mt');


@:ItemEnchant = LoadableClass.create(
  name : 'Wyvern.ItemEnchant',
  
  items : {
    // percent chance of trigger
    conditionChance : 0,
    
    // database id of the effect
    effectID : '',
    
    // EffectStack event to cause the enchant to trigger 
    // "" if its an on battle start effect
    event : '',
    
    // Override description
    description : '',
    
    // Override name,
    name : ''
    
  },

  define:::(this, state) {

    this.interface = {
      initialize::{},
      defaultLoad ::(base, eventHint, conditionChanceHint, effectIDHint, nameHint, descriptionHint) {      
        @:world = import(module:'base/world.mt');
        @:tier = if (world.island) world.island.tier else 0;

        if (effectIDHint != empty) state.effectID = effectIDHint => String
        else ::<= {
          if (random.try(percentSuccess:BAD_EFFECT_CHANCE) && tier > 0) 
            state.effectID = Effect.getRandomFiltered(::(value) <- value.tier <= tier && ((value.traits & Effect.TRAIT.SPECIAL) == 0)).id
          else
            state.effectID = Effect.getRandomFiltered(::(value) <- value.tier <= tier && ((value.traits & Effect.TRAIT.SPECIAL) == 0) && ((value.traits & Effect.TRAIT.BUFF) != 0)).id;
        }



        if (eventHint == empty) ::<= {
          if (random.try(percentSuccess:CONDITION_TYPE_CHANCE)) ::<= {
            state.event = random.pickArrayItem(:CONDITION_EVENT_DESCRIPTION->keys);
          }
        } else ::<= {
          state.event = eventHint;
        }



        
        if (state.event != '') ::<= {
          state.conditionChance = (((random.number() * 100) / 5)->ceil) * 5
          if (state.conditionChance < 33) state.conditionChance = 33;
        }
        
        if (nameHint != empty) state.name = nameHint;
        if (descriptionHint != empty) state.description = descriptionHint;

        return this;
      },


      description : {
        get ::{
          when(state.description != '') state.description;
          
          // always on battle start
          when(state.event == '') ::<= {
            return '[Add Effect - At Battle Start]\n' + Effect.find(:state.effectID).description
          }
          
          return '[Add Effect - ' + state.conditionChance + '% Chance: ' + CONDITION_EVENT_DESCRIPTION[state.event][1] + ']\n' + Effect.find(:state.effectID).description
        },
        
        set ::(value) {
          state.description = value;
        }
      },
      
      name : {
        get ::{
          return Effect.find(:state.effectID).name
        },
        
        set ::(value) {
          state.name = value;
        }
      },
      
      price : {
        get ::{
          @effect = Effect.find(:state.effectID)
          @price = match(effect.tier) {
            (0): 30,
            (1): 80,
            (2): 220,
            (3): 300,
            default: effect.tier * 100
          }
          
          
          if (effect.hasTraits(:Effect.TRAIT.DEBUFF) ||
              effect.hasTraits(:Effect.TRAIT.AILMENT))
            price *= -1
        
          return price;
        }
      },
      
      processEvent ::(*args) {
        @:world = import(module:'base/world.mt');
        when(state.event == '') empty;
        
        if (state.event == args.name) ::<= {
          when(!random.try(percentSuccess:state.conditionChance)) empty;
          args.holder.addEffect(
            from:args.holder, id: state.effectID, durationTurns: 1, item:args.item
          );
        }
      }
    }
  }

);

return ItemEnchant;
