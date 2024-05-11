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
@:Effect = import(module:'game_database.effect.mt');

/*

    Known Events:

    onAffliction : Function, //Called once when first activated
    onPostAttackOther : Function, // Called AFTER the user has explicitly damaged a target
    onPreAttackOther : Function, // called when user is giving damage
    onAttacked : Function, // called when user is attacked, before being damaged.
    onRemoveEffect : Function, //Called once when removed. All effects will be removed at some point.
    onDamage : Function, // when the holder of the effect is hurt
    onNextTurn : Function, //< on end phase of turn once added as an effect. Not called if duration is 0
    onStatRecalculate : Function, // on start of a turn. Not called if duration is 0
    onSuccessfulBlock : Function, // when a targetted body part is blocked by the receiver.

New events:

    onDraw
    onHeal
    onDiscard 
    onStartTurn
    onReaction 
    onBlocked 
    onAddEffect // returns whether the effect is allowed
....onCrit 
....onCritted
....onKill 
....onKnockout
....onStatusAilment

*/

@:EffectStack = LoadableClass.create(
    name: 'Wyvern.EffectStack',
    statics : {
        CANCEL_PROPOGATION : {get::<-'you-can-(Not)-advance'}
    },
    items : {
        innateEffects : empty,
        effects : empty,
    },
    define:::(state, this) {
            
        @:getAll :: <- [
            ...state.innateEffects,
            ...state.effects
        ];

        @:remove ::(which) {
            @:effect = Effect.find(:which.id);
            
        }
        
        @holder;
    
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
            
            addInnate::(id, item) {
                @:ref = {
                    id : id,
                    item : item
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
            
            add::(id, duration => Number, holder, item, from) {
                @effect = Effect.find(:id);
                
                // already added. Ignores innate effects.
                when (effect.stackable == false && state.effects->findIndexCondition(::(value) <- id == value.id) != -1) empty;
                
            
                @:r = {
                    holder: holder,
                    id : id,
                    duration : duration,
                    turnCount : 0,
                    from : from
                };
                state.effects->push(:r);
                
                this.emitEvent(name: 'onAffliction', filter::(value) <- r == value);
            },
            
            removeByFilter::(filter) {
                @:all = [...state.effects]->filter(:filter);
                
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
                
                state.effects = all;
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
                @:name = args.name => String;
                @:emitCondition = args.emitCondition;
            
                
                @all = if (args.filter)
                    [...getAll()]->filter(:args.filter)
                else 
                    getAll()
                ;
                when(all->size == 0) empty;
                breakpoint();

            
                @:ret = [];
                {:::} {
                    foreach(all) ::(k, v) {
                        @:effect = Effect.find(:v.id);
                        if (emitCondition != empty && !emitCondition(:v)) send();


                        @:cb = effect.events[name];
                        when(cb == empty) empty;
                        
                        args.from = v.from;
                        args.item = v.item;
                        args.holder = holder;
                        if (v.turnCount) ::<= {
                            args.turnCount = v.turnCount;
                            args.turnIndex = v.turnCount - v.duration;
                        } else ::<= {
                            args.turnCount = empty;
                            args.turnIndex = empty;
                        }
                        
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
                    stats.modRate(stats:effect.stats);
                }
                return this.emitEvent(
                    name: 'onStatRecalculate',
                    holder,
                    stats
                );
            },
            
            nextTurn:: {
                @:inSet = {};
                foreach(state.effects) ::(i, e) {
                    e.duration -= 1;
                    if (e.duration == 0) ::<= {
                        inSet[e] = true;
                    }
                }
                @:ret = this.emitEvent(
                    name: 'onRemoveEffect',
                    filter::(value) <- inSet[value] == true, 
                    holder
                );                
                foreach(inSet) ::(i, e) {
                    state.effects->remove(:state.effects->findIndex(:i));                
                }
                
                this.emitEvent(
                    holder,
                    name : 'onNextTurn'
                );
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
                    filter::(value) <- inSet[value] == true, 
                    holder
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
