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
@:StatSet = import(module:'game_class.statset.mt');
@:Species = import(module:'game_class.species.mt');
@:Personality = import(module:'game_class.personality.mt');
@:Profession = import(module:'game_class.profession.mt');
@:NameGen = import(module:'game_singleton.namegen.mt');
@:Item = import(module:'game_class.item.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Ability = import(module:'game_class.ability.mt');
@:Effect = import(module:'game_class.effect.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:BattleAI = import(module:'game_class.battleai.mt');
@:StateFlags = import(module:'game_class.stateflags.mt');
@:Location = import(module:'game_class.location.mt');
@:random = import(module:'game_singleton.random.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:EntityQuality = import(module:'game_class.entityquality.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:story = import(module:'game_singleton.story.mt');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

// returns EXP recommended for next level
@:levelUp ::(level, stats => StatSet.type, growthPotential => StatSet.type, whichStat) {
            
    @:stat = ::(name) {
        @:base = growthPotential[name];
        @val =  (0.5 * (Number.random()/2) * (base / 3))->floor
        when (val < 1)
            Number.random() * 2;
        return val;
    }
            
    stats.add(stats:StatSet.new(
        HP  : 1+(stat(name:'HP')),
        AP  : 2+(stat(name:'AP')),
        ATK : stat(name:'ATK'),
        INT : stat(name:'INT'),
        DEF : stat(name:'DEF'),
        SPD : stat(name:'SPD'),
        LUK : stat(name:'LUK'),
        DEX : stat(name:'DEX')
    ));
    
    return (50 + (level*level * 0.1056) * 1000)->floor;
}	

@:statUp ::(level, growth => Number) {

    @:stat :: (potential, level) {
        when(potential <= 0) potential = 1;
        return 1 + ((level**0.65) + (Number.random()*4))->floor;
    }
    return stat(potential:growth,  level:level+1);


}


@:removeDuplicates ::(list) {
    @:temp = {}
    foreach(list)::(index, val) {
        temp[val] = val;
    }
    return temp->keys;
}


@:EQUIP_SLOTS = {
    HAND_L : 0,
    HAND_R : 1,
    ARMOR : 2,
    AMULET : 3,
    RING_L : 4,
    RING_R : 5,
    TRINKET : 6
}

@none;

@:Entity = LoadableClass.new(
    name : 'Wyvern.Entity', 
    statics : {
        EQUIP_SLOTS : {get::<- EQUIP_SLOTS}
   
    },
        
    new ::(parent, speciesHint, professionHint, personalityHint, levelHint => Number, state, adventurousHint, qualities) {
        @:this = Entity.defaultNew();
        this.initialize();
        if (state != empty)
            this.load(serialized:state)
        else 
            this.defaultLoad(speciesHint, professionHint, personalityHint, levelHint, adventurousHint, qualities);

        return this;
    },
    
    
    define :::(this) {
        if (none == empty) none = Item.new(base:Item.Base.database.find(name:'None'));
        @battle_;
        @onInteract = empty;
        // requests removal from battle
        @requestsRemove = false;
        @onHire;
        @enemies_ = [];
        @allies_ = [];
        @abilitiesUsedBattle = empty;




        @state = State.new(
            items : {
                stats : StatSet.new(
                    HP:1,
                    AP:1,
                    ATK:1,
                    DEX:1,
                    INT:1,
                    DEF:1,
                    // LUK can be zero. some people are just unlucky!
                    SPD:1    
                ),



                hp : 1,
                ap : 1,
                flags : StateFlags.new(),
                isDead : false,
                name : NameGen.person(),
                nickname : empty,
                species : Species.database.getRandom(),
                profession : empty,
                personality : Personality.database.getRandom(),
                emotionalState : empty,
                favoritePlace : Location.Base.database.getRandom(),
                favoriteItem : Item.Base.database.getRandomFiltered(filter::(value) <- value.isUnique == false && value.tier <= story.tier),
                growth : StatSet.new(),
                qualityDescription : empty,
                qualitiesHint : empty,
                adventurous : Number.random() <= 0.5,
                battleAI : empty,
                professions : [],
                

                equips : [
                    empty, // handl
                    empty, // handr
                    empty, // armor
                    empty, // amulet
                    empty, // ringl
                    empty, // ringr
                    empty
                ],
                effects : [], // effects. abilities and equips push / pop these.
                abilitiesAvailable : [
                    Ability.database.find(name:'Attack'),
                    Ability.database.find(name:'Defend'),

                ], // active that can choose in combat
                abilitiesLearned : [], // abilities that can choose outside battle.
                
                inventory : Inventory.new(size:10),
                expNext : 10,
                level : 0
            }
        );
        state.inventory.addGold(amount:(Number.random() * 100)->ceil);



        
        for(0, 3)::(i) {
            state.inventory.add(item:
                Item.new(
                    base: Item.Base.database.getRandomFiltered(
                        filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                                                    && value.tier <= story.tier
                    ),
                    rngEnchantHint:true, from:this
                )
            );
        }


        @:resetEffects :: {
            state.effects = [];
            
            for(0, EQUIP_SLOTS.RING_R+1)::(slot) {
                when(slot == EQUIP_SLOTS.HAND_R) empty;
                @:equip = state.equips[slot];
                when(equip == empty) empty;
                foreach(equip.equipEffects)::(index, effect) {
                    this.addEffect(
                        from:this, 
                        name:effect, 
                        durationTurns: -1
                    );
                }
            }
            
            
            foreach(state.profession.base.passives)::(index, passiveName) {
                this.addEffect(
                    from:this, 
                    name:passiveName, 
                    durationTurns: -1
                );
            }
            
      
        }



        
        this.interface = {
            initialize ::{
                state.battleAI = BattleAI.new(
                    user: this
                );                
            },

            defaultLoad::(speciesHint, professionHint, personalityHint, levelHint, adventurousHint, qualities) {
                if (adventurousHint != empty)
                    state.adventurous = adventurousHint;
                
                if (personalityHint != empty)
                    state.personality = Personality.database.find(name:personalityHint);

                state.qualitiesHint = qualities;

    
                
                state.profession = Profession.new(
                    base:
                        if (professionHint == empty) 
                            Profession.Base.database.getRandomFiltered(
                                filter:::(value) <- levelHint >= value.levelMinimum
                            ) 
                        else 
                            Profession.Base.database.find(name:professionHint)
                );
                if (speciesHint != empty) ::<= {
                    state.species = Species.database.find(name:speciesHint);
                }
                state.professions->push(value:state.profession);
                
                
                state.growth.mod(stats:state.species.growth);
                state.growth.mod(stats:state.personality.growth);
                state.growth.mod(stats:state.profession.base.growth);
                for(0, levelHint)::(i) {
                    this.autoLevel();                
                }

                /*
                ::<={
                    [0, 1+(Number.random()*3)->floor]->for(do:::(i) {
                        @:item = Item.Base.database.getRandomWeightedFiltered(
                            filter:::(value) <- level >= value.levelMinimum &&
                                                value.isUnique == false
                            
                        );
                        if (item.name != 'None') ::<={
                            @:itemInstance = item.new(from:this);
                            if (itemInstance.enchantsCount == 0) 
                                inventory.add(item:itemInstance);
                        }
                        
                        
                    });
                    
                }
                */

                return this;
            },     
        
            save :: {
                return state.save()
            },
            
            load ::(serialized) {
                state.load(parent:this, serialized);
                foreach(state.equips) ::(k, equip) {
                    when(equip == empty) empty;
                    equip.equippedBy = this;
                }
            },

        
            // Called to indicate to the entity the 
            // start of a new turn in general.
            // This does things like reset stats according to 
            // effects and such.
            startTurn :: {
                this.recalculateStats();             
                this.flags.reset();
            },
            
            // called to signal that a battle has started involving this entity
            battleStart ::(battle, allies, enemies) {
                battle_ = battle;
                state.battleAI.reset(
                    enemies: enemies,
                    allies: allies
                );            
                enemies_ = enemies;
                allies_ = allies;
                requestsRemove = false;
                abilitiesUsedBattle = {}
                resetEffects();              
            },
            
            battle : {
                get ::<- battle_
            },
            

            // called to signal that a battle has started involving this entity
            battleEnd :: {
                battle_ = empty;
                foreach(state.effects)::(index, effect) {

                    effect.effect.onRemoveEffect(
                        user:effect.from, 
                        holder:this,
                        item:effect.item
                    );
                }
                allies_ = [];
                enemies_ = [];
                abilitiesUsedBattle = empty;                
                resetEffects();
            },

            
            recalculateStats :: {
                state.stats.resetMod();
                foreach(state.effects)::(index, effect) {
                    effect.effect.onStatRecalculate(user:effect.from, stats:state.stats, holder:this, item:effect.item);
                    state.stats.modRate(stats:effect.effect.stats);
                }

                foreach(state.equips)::(index, equip) {
                    when(equip == empty) empty;
                    when(index == EQUIP_SLOTS.HAND_R) empty;
                    state.stats.modRate(stats:equip.equipMod);
                }
            },
            
            personality : {
                get ::<- state.personality
            },
            
            endTurn ::(battle) {
                @:equips = state.equips;
                foreach(EQUIP_SLOTS)::(str, i) {
                    when(i == 0 && equips[0] == equips[1]) empty;
                    when(equips[i] == empty) empty;
                    equips[i].onTurnEnd(wielder:this, battle);
                }
            },

            // lets the entity know that their turn has come.            
            actTurn ::() => Boolean {
                @act = true;
                foreach(state.effects)::(index, effect) {                        
                    if (effect.duration != -1 && effect.turnIndex >= effect.duration) ::<= {
                        effect.effect.onRemoveEffect(
                            user:effect.from, 
                            holder:this,
                            item:effect.item
                        );
                        state.effects->remove(key:index);
                    } else ::<= {
                        if (effect.effect.skipTurn == true)
                            act = false;
                        effect.effect.onNextTurn(user:effect.from, turnIndex:effect.turnIndex, turnCount: effect.duration, holder:this, item:effect.item);                    
                        effect.turnIndex += 1;
                    }
                }
                
                if (this.stats.SPD < 0) ::<= {
                    windowEvent.queueMessage(text:this.name + ' cannot move due to negative speed!');
                    act = false;
                }

                if (this.stats.DEX < 0) ::<= {
                    windowEvent.queueMessage(text:this.name + ' fumbles about due to negative dexterity!');
                    act = false;
                }

                if (act == false)
                    this.flags.add(flag:StateFlags.SKIPPED);
                return act;
            },

            
            flags : {
                get :: {
                    return state.flags;
                }
            },
            
            name : {
                get :: {
                    when (state.nickname != empty) state.nickname;
                    return state.name;
                },
                
                set ::(value => String) {
                    state.name = value;
                }
            },
            
            species : {
                get :: {
                    return state.species;
                }, 
                
                set ::(value) {
                    state.species = value;
                }
            },

            requestsRemove : {
                get ::<- requestsRemove,
                set ::(value) <- requestsRemove = value
            },

            profession : {
                get :: {
                    return state.profession;
                },
                
                set ::(value => Profession.type) {
                    state.profession = {:::}{
                        foreach(state.professions)::(index, prof) {
                            if (value.base.name == prof.base.name) ::<= {
                                send(message:prof);
                            }
                        }
                        state.professions->push(value);
                        return value;
                    }            
                    
                                        
                    state.growth.resetMod();
                    state.growth.mod(stats:state.species.growth);
                    state.growth.mod(stats:state.personality.growth);
                    state.growth.mod(stats:state.profession.base.growth);
                
                
                }
            },
            
            nickname : {
                set ::(value) {
                    state.nickname = value;
                }
            },
            
            renderHP ::(length) {
                if (length == empty) length = 12;
                
                @:numFilled = ((length - 2) * (state.hp / state.stats.HP))->floor;
                
                @out = ' ';
                for(0, numFilled)::(i) {
                    out = out+'▓';
                }
                for(0, length - numFilled - 2)::(i) {
                    out = out+'▁';
                }
                return out + ' ';
                
            },
            
            level : {
                get ::{
                    return state.level;
                }
            },
            
            effects : {
                get ::<- [...state.effects]
            },
            
            onHire : {
                set ::(value) {
                    onHire = value;
                }
            },
            
            
            attack::(
                amount => Number,
                damageType => Number,
                damageClass => Number,
                target => Entity.type
            ){
                @:dmg = Damage.new(
                    amount,
                    damageType,
                    damageClass
                );
                
                @:damaged = [];
                // TODO: add weapon affinities if phys and equip weapon
                // phys is always assumed to be with equipped weapon
                foreach(state.effects)::(index, effect) {
                    when (dmg.amount <= 0) empty;
                    effect.effect.onPreAttackOther(user:effect.from, item:effect.item, holder:this, to:target, damage:dmg);
                }
                
                when(dmg.amount <= 0) empty;
                foreach(target.effects)::(index, effect) {
                    when (dmg.amount <= 0) empty;
                    effect.effect.onAttacked(user:target, item:effect.item, holder:target, by:this, damage:dmg);                
                }
                

                when(dmg.amount <= 0) empty;
                when(target.hp == 0) ::<= {
                    this.flags.add(flag:StateFlags.DEFEATED_ENEMY);
                    target.flags.add(flag:StateFlags.DIED);
                    target.kill();                
                }

                @critChance = 0.999 - (this.stats.LUK - state.level) / 100;
                @isCrit = false;
                if (critChance < 0.90) critChance = 0.9;
                if (Number.random() > critChance) ::<={
                    dmg.amount += this.stats.DEX * 2.5;
                    isCrit = true;
                }

                when(!target.damage(from:this, damage:dmg, dodgeable:true, critical:isCrit)) empty;


                this.flags.add(flag:StateFlags.ATTACKED);


                
                foreach(state.effects)::(index, effect) {
                    effect.effect.onPostAttackOther(user:effect.from, item:effect.item, holder:this, to:target);
                }
                return true;
            },
            
            damage ::(from => Entity.type, damage => Damage.type, dodgeable => Boolean, critical, exact) {
                when(state.isDead) false;
                @originalAmount = damage.amount;
                @whiff = false;
                if (dodgeable) ::<= {
                    @diffpercent = (from.stats.DEX - this.stats.DEX) / this.stats.DEX;
                    // if attacker dex is above target dex, hit always connects
                    when(diffpercent > 0) empty;
                    
                    // if less dex, then a percent to miss, up to 50%
                    diffpercent = diffpercent + (1 - diffpercent) / 3.0;
                    if (diffpercent < 0.5) diffpercent = 0.5;
                    if (Number.random() > diffpercent)
                        whiff = true;
                }
                
                when(whiff) ::<= {
                    windowEvent.queueMessage(text:random.pickArrayItem(list:[
                        this.name + ' lithely dodges ' + from.name + '\'s attack!',                 
                        this.name + ' narrowly dodges ' + from.name + '\'s attack!',                 
                        this.name + ' dances around ' + from.name + '\'s attack!',                 
                        from.name + '\'s attack completely misses ' + this.name + '!'
                    ]));
                    this.flags.add(flag:StateFlags.DODGED_ATTACK);
                    return false;
                }



                if (from.stats.DEX > this.stats.DEX)               
                    // as DEX increases: randomness decreases 
                    // amount of reliable damage increases
                    // This models user skill vs receiver skill
                    damage.amount = damage.amount + damage.amount * ((Number.random() - 0.5) * (this.stats.DEX / from.stats.DEX) + (1 -  this.stats.DEX / from.stats.DEX))
                else
                    damage.amount = damage.amount + damage.amount * (Number.random() - 0.5)
                ; 
                
                


                damage.amount -= state.stats.DEF/4;
                if (damage.amount <= 0) damage.amount = 1;


                foreach(state.effects)::(index, effect) {
                    effect.effect.onDamage(user:effect.from, holder:this, from, damage);
                }

                if (exact)
                    damage.amount = originalAmount;

                when (damage.amount == 0) false;
                when(state.hp == 0) false;

                
                if (critical == true)
                    windowEvent.queueMessage(text: 'Critical damage!');


                @damageTypeName ::{
                    return match(damage.damageType) {
                      (Damage.TYPE.FIRE): 'fire ',
                      (Damage.TYPE.ICE): 'ice ',
                      (Damage.TYPE.THUNDER): 'thunder ',
                      (Damage.TYPE.LIGHT): 'light ',
                      (Damage.TYPE.DARK): 'dark ',
                      (Damage.TYPE.PHYS): 'physical ',
                      (Damage.TYPE.POISON): 'poison ',
                      (Damage.TYPE.NEUTRAL): ''
                    }
                }
                
                if (damage.damageClass == Damage.CLASS.HP) ::<= {
                    state.hp -= damage.amount;
                    if (state.hp < 0) state.hp = 0;
                    windowEvent.queueMessage(text: '' + this.name + ' received ' + damage.amount + ' '+damageTypeName() + 'damage (HP:' + this.renderHP() + ')' );
                } else ::<= {
                    state.ap -= damage.amount;
                    if (state.ap < 0) state.ap = 0;                
                    windowEvent.queueMessage(text: '' + this.name + ' received ' + damage.amount + ' AP damage (AP:' + state.ap + '/' + state.stats.AP + ')' );

                }
                @:world = import(module:'game_singleton.world.mt');

                if (world.party.isMember(entity:this) && state.hp != 0 && damage.amount > state.stats.HP * 0.2 && Number.random() > 0.7)
                    windowEvent.queueMessage(
                        speaker: this.name,
                        text: '"' + random.pickArrayItem(list:state.personality.phrases[Personality.SPEECH_EVENT.HURT]) + '"'
                    );
                    

                state.flags.add(flag:StateFlags.HURT);
                
                if (damage.damageType == Damage.TYPE.FIRE && Number.random() > 0.9)
                    this.addEffect(from, name:'Burned',durationTurns:5);
                if (damage.damageType == Damage.TYPE.ICE && Number.random() > 0.9)
                    this.addEffect(from, name:'Frozen',durationTurns:2);
                if (damage.damageType == Damage.TYPE.THUNDER && Number.random() > 0.9)
                    this.addEffect(from, name:'Paralyzed',durationTurns:2);
                if (damage.damageType == Damage.TYPE.PHYS && Number.random() > 0.99) 
                    this.addEffect(from, name:'Bleeding',durationTurns:5);
                if (damage.damageType == Damage.TYPE.POISON && Number.random() > 0.9) 
                    this.addEffect(from, name:'Poisoned',durationTurns:5);
                if (damage.damageType == Damage.TYPE.DARK && Number.random() > 0.9)
                    this.addEffect(from, name:'Blind',durationTurns:2);
                if (damage.damageType == Damage.TYPE.LIGHT && Number.random() > 0.9)
                    this.addEffect(from, name:'Petrified',durationTurns:2);
                
                
                if (world.party.isMember(entity:this) && state.hp == 0 && Number.random() > 0.7) ::<= {
                    windowEvent.queueMessage(
                        speaker: this.name,
                        text: '"' + random.pickArrayItem(list:state.personality.phrases[Personality.SPEECH_EVENT.DEATH]) + '"'
                    );
                }
                
                if (state.hp == 0) ::<= {
                    windowEvent.queueMessage(text: '' + this.name + ' has been knocked out.');                                
                    this.flags.add(flag:StateFlags.FALLEN);
                    from.flags.add(flag:StateFlags.DEFEATED_ENEMY);
                }

                return true;
            },
            
            // where they roam to in their freetime. if places doesnt have one they stay home
            favoritePlace : {
                get ::<- state.favoritePlace
            },
            
            heal ::(amount => Number, silent) {
                when(state.hp >= state.stats.HP) empty;
                amount = amount->ceil;
                state.hp += amount;
                this.flags.add(flag:StateFlags.HEALED);
                if (state.hp > state.stats.HP) state.hp = state.stats.HP;
                if (silent == empty)
                    windowEvent.queueMessage(text: '' + this.name + ' heals ' + amount + ' HP (HP:' + this.renderHP() + ')');
            },
            
            healAP ::(amount => Number, silent) {
                amount = amount->ceil;
                state.ap += amount;
                if (state.ap > state.stats.AP) state.ap = state.stats.AP;
                if (silent == empty)
                    windowEvent.queueMessage(text: '' + this.name + ' heals ' + amount + ' AP (AP:' + state.ap + '/' + state.stats.AP + ')');
                
                
            },
            
            
            isIncapacitated :: {
                return state.hp <= 0;
            },
            
            isDead : {
                get :: {
                    return state.isDead;
                }   
            },
            
            gainExp ::(amount => Number, chooseStat, afterLevel) {
                {:::} {
                    forever ::{
                        when(amount <= 0) send();
                        when(amount < state.expNext) ::<={
                            state.expNext -= amount;
                            send();
                        }
                        
                        amount -= state.expNext;
                        state.expNext = levelUp(
                            level:state.level,
                            stats:state.stats,
                            growthPotential : state.growth
                        );
                        
                        if (chooseStat == empty) ::<={ 
                            @choice = random.integer(from:0, to:7);
                            state.stats.add(stats: StatSet.new(
                                HP: if (choice == 0) statUp(level:state.level, growth:state.growth.HP) else 0,
                                AP: if (choice == 1) statUp(level:state.level, growth:state.growth.AP) else 0,
                                ATK: if (choice == 2) statUp(level:state.level, growth:state.growth.ATK) else 0,
                                DEF: if (choice == 3) statUp(level:state.level, growth:state.growth.DEF) else 0,
                                INT: if (choice == 4) statUp(level:state.level, growth:state.growth.INT) else 0,
                                SPD: if (choice == 5) statUp(level:state.level, growth:state.growth.SPD) else 0,
                                LUK: if (choice == 6) statUp(level:state.level, growth:state.growth.LUK) else 0,
                                DEX: if (choice == 7) statUp(level:state.level, growth:state.growth.DEX) else 0
                            
                            ));
                        
                        } else ::<= {
                            @hp = statUp(level:state.level, growth:state.growth.HP);                            
                            @ap = statUp(level:state.level, growth:state.growth.AP);                            
                            @atk = statUp(level:state.level, growth:state.growth.ATK);                            
                            @def = statUp(level:state.level, growth:state.growth.DEF);                            
                            @luk = statUp(level:state.level, growth:state.growth.LUK);                            
                            @spd = statUp(level:state.level, growth:state.growth.SPD);                            
                            @dex = statUp(level:state.level, growth:state.growth.DEX);                            
                            @int = statUp(level:state.level, growth:state.growth.INT);                            
                            @choice = chooseStat(
                                hp, ap, atk, def, int, spd, luk, dex
                            );
                            
                            state.stats.add(stats: StatSet.new(
                                HP: if (choice == 0) hp else 0,
                                AP: if (choice == 1) ap else 0,
                                ATK: if (choice == 2) atk else 0,
                                DEF: if (choice == 3) def else 0,
                                INT: if (choice == 4) int else 0,
                                SPD: if (choice == 5) spd else 0,
                                LUK: if (choice == 6) luk else 0,
                                DEX: if (choice == 7) dex else 0
                            ));                            
                            
                            
                        
                        }
                        if (afterLevel != empty) afterLevel();
                        state.hp = state.stats.HP;
                        state.ap = state.stats.AP;
                        state.level += 1;
                    }
                }
                this.recalculateStats();                
            },
            
            stats : {
                get :: {
                    return state.stats;
                }
            },
            
            autoLevel :: {
                this.gainExp(amount:state.expNext);  
            },
            
            dropExp :: {
                return 
                    ((state.stats.HP +
                    state.stats.AP +
                    state.stats.ATK +
                    state.stats.INT +
                    state.stats.DEF +
                    state.stats.SPD + 
                    state.stats.DEX + 
                    state.stats.LUK)* 1.7 + 40)->floor
                ;
            },
            
            // whether they would be okay with being hired for the team.
            adventurous : {
                get :: {
                    return state.adventurous;
                }
            },
            
            kill ::(silent) {
                state.hp = 0;
                if (silent == empty)
                    windowEvent.queueMessage(text: '' + this.name + ' has died!');                
                state.flags.add(flag:StateFlags.DIED);
                state.isDead = true;                
            },
            
            addEffect::(from => Entity.type, name => String, durationTurns => Number, item) {
                if (durationTurns == empty) durationTurns = -1;
                
                @:effect = Effect.database.find(name);
                @:existingEffectIndex = state.effects->findIndex(query::(value) <- value.effect.name == name);               
                when (effect.stackable == false && existingEffectIndex != -1) ::<= {
                    // reset duration of effect and source.
                    @einst = state.effects[existingEffectIndex];
                    einst.duration = durationTurns;
                    einst.turnIndex = 0;
                    einst.item = item;
                    einst.from = from;
                }
                
                @einst = {
                    from: from,
                    item : item,
                    effect : effect,
                    duration: durationTurns,
                    turnIndex: 0
                }
                if (einst.effect == empty || einst.duration->type != Number) error(detail:'Bad addEffect() call: effect or duration was invalid.');                
                if (durationTurns != 0)
                    state.effects->push(value:einst);
                

                einst.effect.onAffliction(
                    user:from, 
                    holder:this,
                    item
                );
                this.recalculateStats();

            },
            
            
            removeEffects::(effectBases => Object) {
                state.effects = state.effects->filter(by:::(value) {
                    @:current = value.effect;
                    @:keep = effectBases->all(condition:::(value) <-
                        value != current
                    );
                    
                    if (!keep) ::<={
                    
                        value.effect.onRemoveEffect(
                            user:value.from, 
                            holder:this,
                            item:value.item
                        );
                    }
                });
            },
            
            abilitiesAvailable : {
                get :: {
                    @out = [...state.abilitiesAvailable];
                    foreach(EQUIP_SLOTS)::(i, val) {
                        if (state.equips[val] != empty && state.equips[val].ability != empty) ::<= {
                            @:ab = Ability.database.find(name:state.equips[val].ability);
                            when(out->findIndex(value:ab) != -1) empty;
                            out->push(value:ab);
                        }
                    }
                    return out;
                }
            },
            
            learnAbility::(name => String) {
                when (name == empty) empty;

                @:ability = Ability.database.find(name);
                if (state.abilitiesAvailable->keycount < 7)
                    state.abilitiesAvailable->push(value:ability);
                    
                state.abilitiesLearned->push(value:ability);
            },
            
            learnNextAbility::{
                @:skills = this.profession.gainSP(amount:1);
                when(skills == empty) empty;
                foreach(skills)::(i, skill) {
                    this.learnAbility(name:skill);
                }
            },
            
            clearAbilities::{
                state.abilitiesAvailable = [
                    Ability.database.find(name:'Attack'),
                    Ability.database.find(name:'Defend'),
                ];
                state.abilitiesLearned = [];
            },
            
            hp : {
                get :: {
                    return state.hp;
                }
            },
            
            ap : {
                get :: {
                    return state.ap;
                }
            },
            
            rest :: {
                state.hp = state.stats.HP;
                state.ap = state.stats.AP;
            },
            
            inventory : {
                get :: {
                    return state.inventory;
                }
            },
            
            battleAI : {
                get ::<- state.battleAI
            },
            
            equip ::(item => none->type, slot, silent, inventory) {
                this.recalculateStats();
                @:oldstats = StatSet.new();
                oldstats.add(stats: this.stats);

                @olditem = state.equips[slot];
                if (item.name == 'None')
                    error(detail:'Can\'t equip the None item. Unequip instead.');
        
                when (this.getSlotsForItem(item)->findIndex(value:slot) == -1) ::<= {
                    when(silent) empty;
                    error(detail:'Item does not enter the given slot.');
                }



                @:old = this.unequip(slot, silent:true);                


                if (old != empty && inventory)
                    inventory.add(item:old);

                if (item.base.equipType == Item.TYPE.TWOHANDED) ::<={
                    state.equips[EQUIP_SLOTS.HAND_L] = item;
                    state.equips[EQUIP_SLOTS.HAND_R] = item;
                } else ::<= {
                    state.equips[slot] = item;
                }
                
                item.equippedBy = this;
                
                foreach(item.equipEffects)::(index, effect) {
                    this.addEffect(
                        from:this, 
                        name:effect, 
                        durationTurns: -1
                    );
                }

                if ((slot == EQUIP_SLOTS.HAND_L || slot == EQUIP_SLOTS.HAND_R) && state.profession.base.weaponAffinity == state.equips[EQUIP_SLOTS.HAND_L].base.name) ::<= {
                    if (silent != true) ::<= {
                        windowEvent.queueMessage(
                            speaker: this.name,
                            text: '"This ' + item.base.name + ' really works for me as ' + correctA(word:state.profession.base.name) + '"'
                        );
                    }
                    this.addEffect(
                        from:this,
                        name:'Weapon Affinity',
                        durationTurns: -1 
                    );
                }


                if (inventory)
                    inventory.remove(item);
                
                this.recalculateStats();

                
                if (silent != true) ::<={
                    if (olditem == empty || olditem.name == 'None') ::<= {
                        windowEvent.queueMessage(text:this.name + ' has equipped the ' + item.name + '.');                    
                    } else ::<= {
                        windowEvent.queueMessage(text:this.name + ' unequipped the ' + olditem.name + ' and equipped the ' + item.name + '.');                    
                    }
                    oldstats.printDiff(prompt: '(Equipped: ' + item.name + ')', other:this.stats);
                }
            },
            anonymize :: {
                this.nickname = 'the ' + this.species.name + (if(this.profession.base.name == 'None') '' else ' ' + this.profession.base.name);            
            },
            
            getEquipped::(slot => Number) {
                @:eq = state.equips[slot];
                when(eq == empty) none;
                return eq;
            },

            isEquipped::(item) {
                return state.equips->any(func::(value) <- value == item);
            },
            
            resetEffects : resetEffects,
            
            // returns an array of equip slots that the item can fit in.
            getSlotsForItem ::(item => none->type) {
                return match(item.base.equipType) {
                    (Item.TYPE.HAND)     :  [EQUIP_SLOTS.HAND_L, EQUIP_SLOTS.HAND_R],
                    (Item.TYPE.ARMOR)    :  [EQUIP_SLOTS.ARMOR],
                    (Item.TYPE.AMULET)   :  [EQUIP_SLOTS.AMULET],
                    (Item.TYPE.RING)     :  [EQUIP_SLOTS.RING_L, EQUIP_SLOTS.RING_R],
                    (Item.TYPE.TRINKET)  :  [EQUIP_SLOTS.TRINKET],
                    (Item.TYPE.TWOHANDED):  [EQUIP_SLOTS.HAND_L, EQUIP_SLOTS.HAND_R],
                    default: error(detail:'Item has an invalid equiptype?')      
                }
            },
            
            
            unequip ::(slot => Number, silent) {
                @:current = state.equips[slot];
                when (current == empty) empty;
                if (current.base.equipType == Item.TYPE.TWOHANDED) ::<={
                    state.equips[EQUIP_SLOTS.HAND_L] = empty;                                
                    state.equips[EQUIP_SLOTS.HAND_R] = empty;                                
                } else ::<={
                    state.equips[slot] = empty;                
                }
                if (state.profession.base.weaponAffinity == current.base.name)
                    state.effects->remove(key:state.effects->findIndex(query::(value) <- value.effect.name == 'Weapon Affinity'));
                
                current.equippedBy = empty;

                
                foreach(current.equipEffects)::(i, effect) {
                    @:effectObj = state.effects->filter(by:::(value) <- value.effect.name == effect)[0];
                    effectObj.effect.onRemoveEffect(
                        user:effectObj.from, 
                        holder:this,
                        item:effectObj.item
                    );
                    
                    state.effects->remove(key:state.effects->findIndex(value:effectObj));
                }
                
                
                this.recalculateStats();
                return current;
            },
            unequipItem ::(item => none->type, silent) {
                @slotOut;
                foreach(state.equips)::(slot, equip) {
                    if (equip == item) ::<= {
                        this.unequip(slot, silent);
                        slotOut = slot;
                    }
                }
                return slotOut;
            },
            
            useAbility::(ability, targets, turnIndex, extraData) {
                when(state.ap < ability.apCost) windowEvent.queueMessage(
                    text: this.name + " tried to use " + ability.name + ", but couldn\'t muster the mental strength!"
                );
                when(state.hp < ability.hpCost) windowEvent.queueMessage(
                    text: this.name + " tried to use " + ability.name + ", but couldn't muster the strength!"
                );
                
                when (abilitiesUsedBattle != empty && ability.oncePerBattle && abilitiesUsedBattle[ability.name] == true) windowEvent.queueMessage(
                    text: this.name + " tried to use " + ability.name + ", but it worked the first time!"
                );
                if (abilitiesUsedBattle) abilitiesUsedBattle[ability.name] = true;
                
                state.ap -= ability.apCost;
                state.hp -= ability.hpCost;
                ability.onAction(
                    user:this,
                    targets, turnIndex, extraData                 
                );
            
            },
            
            // interacts with this entity
            interactPerson ::(party, location, onDone, overrideChat, skipIntro) {
                when(onInteract) onInteract(party, location, onDone);
                
                @:finish ::{
                    onDone();
                    windowEvent.jumpToTag(name:'InteractPerson', goBeforeTag:true, doResolveNext:true);
                }
                
                if (skipIntro == empty) 
                    windowEvent.queueMessage(
                        speaker: this.name,
                        text: random.pickArrayItem(list:state.personality.phrases[Personality.SPEECH_EVENT.GREET])
                    );                
                    
                windowEvent.queueChoices(
                    canCancel : true,
                    prompt: 'Talking to ' + this.name,
                    choices: [
                        'Chat',
                        'Hire',
                        'Barter',
                        'Aggress...'
                    ],
                    keep: true,
                    onLeave :onDone,
                    canCancel: true,
                    jumpTag: 'InteractPerson',
                    onChoice::(choice) {
                
                        when(choice == 0) empty;
                        
                        match(choice-1) {
                          // Chat
                          (0): ::<= {
                            when (overrideChat) overrideChat();
                            
                             
                            windowEvent.queueMessage(
                                speaker: this.name,
                                text: random.pickArrayItem(list:state.personality.phrases[Personality.SPEECH_EVENT.CHAT])
                            );                                                        
                          },
                          
                          // hire 
                          (1): ::<= {
                            when(party.isMember(entity:this))
                                windowEvent.queueMessage(
                                    text: this.name + ' is already a party member.'
                                );                
                          
                            when (party.members->keycount >= 3 || !state.adventurous)
                                windowEvent.queueMessage(
                                    speaker: this.name,
                                    text: random.pickArrayItem(list:state.personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_DENY])
                                );                
                                
                            windowEvent.queueMessage(
                                speaker: this.name,
                                text: random.pickArrayItem(list:state.personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_ACCEPT])
                            );                

                            @:cost = 50+((state.stats.sum/3 + state.level)*2.5)->ceil;


                            this.describe();

                            windowEvent.queueAskBoolean(
                                prompt: 'Hire for ' + cost + 'G?',
                                onChoice::(which) {
                                    when(which == false) empty;
                                    when(party.inventory.gold < cost)
                                        windowEvent.queueMessage(
                                            text: 'The party cannot afford to hire ' + this.name
                                        );                
                                        
                                    party.inventory.subtractGold(amount:cost);
                                    party.add(member:this);
                                        windowEvent.queueMessage(
                                            text: this.name + ' joins the party!'
                                        );     
                                        
                                    if (onHire) onHire();           

                                }
                            );
                          },
                          
                          // barter
                          (2):::<= {
                            when (state.inventory.isEmpty) ::<= {
                                windowEvent.queueMessage(
                                    text: this.name + ' has nothing to barter with.'
                                );                
                            }
                            @:item = state.inventory.items[0];

                            windowEvent.queueMessage(
                                text: this.name + ' is interested in acquiring ' + correctA(word:state.favoriteItem.name) + '. They are willing to trade one for their ' + item.name + '.'
                            );                
                            
                            
                            @:tradeItems = party.inventory.items->filter(by::(value) <- value.base == state.favoriteItem);
                            
                            when(tradeItems->keycount == 0) ::<= {
                                windowEvent.queueMessage(
                                    text: 'You have no such items to trade, sadly.'
                                );                                                 
                            }
                            


                            windowEvent.queueChoices(
                                prompt: this.name + ' - bartering',
                                choices: ['Trade', 'Check Item', 'Compare Equipment'],
                                jumpTag: 'Barter',
                                canCancel: true,
                                keep:true,
                                onChoice::(choice) {
                                    when(choice == 0) empty;
                                    
                                    match(choice-1) {
                                      // Trade
                                      (0)::<= {
                                        windowEvent.queueChoices(
                                            choices: [...tradeItems]->map(to::(value) <- value.name),
                                            canCancel: true,
                                            onChoice::(choice) {
                                                when(choice == 0) empty;
                                                
                                                @:chosenItem = tradeItems[choice-1];
                                                party.inventory.remove(item:chosenItem);
                                                this.inventory.remove(item);
                                                party.inventory.add(item);
                                                
                                                windowEvent.queueMessage(
                                                    text: 'In exchange for your ' + chosenItem.name + ', ' + this.name + ' gives the party ' + correctA(word:item.name) + '.'
                                                );                                                                                                 
                                                
                                                windowEvent.jumpToTag(name:'Barter', goBeforeTag:true, doResolveNext:true);
                                            }
                                        );
                                      },
                                      // check
                                      (1)::<= {
                                        item.describe();
                                      },
                                      // compare 
                                      (2)::<= {
                                        @:memberNames = [...party.members]->map(to:::(value) <- value.name);
                                        @:choice = windowEvent.queueChoices(
                                            prompt: 'Compare equipment for whom?',
                                            choices: memberNames,
                                            onChoice::(choice) {
                                                @:user = party.members[choice-1];
                                                @slot = user.getSlotsForItem(item)[0];
                                                @currentEquip = user.getEquipped(slot);
                                                
                                                currentEquip.equipMod.printDiffRate(
                                                    prompt: '(Equip) ' + currentEquip.name + ' -> ' + item.name,
                                                    other:item.equipMod
                                                );                                                                               
                                            }
                                        );
                                      }  
                                    }   
                                }
                            );

                            
                            
                            
                          }
                        
                        }                    
                    }
                );  

                
                // if aggress:
                //
                /*
                    choices : [
                        'fight',
                        'steal', // ask: Who's stealing? Dex compared to target's Int determines if caught
                    ]
                
                */
            },
            
            // dummy for map
            discovered : {
                get ::<- true
            },
            
            allies : {
                get ::<- allies_
            },

            enemies : {
                get ::<- enemies_
            },
            
            // when set, this overrides the default interaction menu
            onInteract : {
                set ::(value) {
                    onInteract = value;
                }
            },
            
            describeQualities ::{
                when (state.qualityDescription) state.qualityDescription;
                
                @qualities = state.qualitiesHint;
                
                if (qualities == empty) ::<= {
                    qualities = [];
                    foreach(state.species.qualities)::(i, qual) {
                        @:q = EntityQuality.Base.database.find(name:qual);
                        if (q.appearanceChance == 1 || Number.random() < q.appearanceChance)
                            qualities->push(value:EntityQuality.new(base:q));
                    }
                }
            
                @out = this.name + ' is ' + correctA(word:state.species.name) + '. ';
                @:quals = [...qualities];

                // inefficient, but idc                
                @:describeDual::(qual0, qual1, index) {
                    return ([
                        'They have ' + qual0.name + 
                                (if (qual0.plural) ' that are ' else ' that is ') 
                            + qual0.description + ', and their '
                            + qual1.name + 
                                (if (qual1.plural) ' are ' else ' is ') 
                            + qual1.description + '. ',
                            
                        this.name + '\'s ' + qual0.name + 
                                (if (qual0.plural) ' are ' else ' is ') 
                            + qual0.description + ', and they have '
                            + qual1.name + 
                                (if (qual1.plural) ' which are ' else ' which is ') 
                            + qual1.description + '. ',
                    ])[index];
                }

                @:describeSingle::(qual, index) {
                    return ([
                        this.name + '\'s ' + qual.name + 
                                (if (qual.plural) ' are ' else ' is ') 
                            + qual.description + '. ',

                        'Their ' + qual.name + 
                                (if (qual.plural) ' are quite ' else ' is quite ') 
                            + qual.description + '. ',
                            

                        'Their ' + qual.name + 
                                (if (qual.plural) ' are ' else ' is ') 
                            + qual.description + '. ',

                        'Their ' + qual.name + 
                                (if (qual.plural) ' are seemingly ' else ' is seemingly ') 
                            + qual.description + '. ',

                        'Their ' + qual.name + 
                                (if (qual.plural) ' are fairly ' else ' is fairly ') 
                            + qual.description + '. '
                    ])[index];
                }
                
                @:singleChoices = [0, 1, 2, 3, 4];
                @:dualChoices = [0, 1];
                
                @:pickDescriptionChoice::(list) {
                    @:index = random.integer(from:0, to:list->keycount-1);
                    @:out = list[index];
                    list->remove(key:index);
                    return out;
                }
                
                // when we pick descriptive sentences, we dont want to 
                // reuse structures more than once except for the unflourished 
                // one.
                {:::} {
                    forever ::{
                        when(quals->keycount == 0) send();
                        
                        @single = if (quals->keycount >= 2) (Number.random() < 0.5) else true;
                        
                        if (!single) ::<= {
                            @qual0 = quals->pop;
                            @qual1 = quals->pop;
                            
                            @index = if(dualChoices->keycount == 0)
                                0
                            else                                
                                pickDescriptionChoice(list:dualChoices);                                
                            out = out + describeDual(qual0, qual1, index);
                        } else ::<= {
                            @qual = quals->pop;
                            
                            @index = if(singleChoices->keycount == 0)
                                2
                            else                                
                                pickDescriptionChoice(list:singleChoices);                                
                            out = out + describeSingle(qual, index);                        
                        }
                    }
                    
                }
                state.qualityDescription = out;
                return out;
            },
            
            describe:: {
                @:plainStats = StatSet.new();
                state.stats.resetMod();
                plainStats.add(stats:state.stats);
                this.recalculateStats();

                @:modRate = StatSet.new();
                foreach(state.effects)::(index, effect) {
                    effect.effect.onStatRecalculate(user:effect.from, stats:state.stats, holder:this, item:effect.item);
                    modRate.add(stats:effect.effect.stats);
                }

                foreach(state.equips)::(index, equip) {
                    when(equip == empty) empty;
                    when(index == EQUIP_SLOTS.HAND_R) empty;
                    modRate.add(stats:equip.equipMod);
                }
                

                plainStats.printDiff(other:state.stats, 
                    prompt:this.name + '(Base -> w/Mods.)'
                );
                windowEvent.queueMessageSet(
                    speaker: this.name,
                    pageAfter:canvas.height-4,
                    set: [ 
                          '       Name: ' + this.name + '\n\n' +
                          '         HP: ' + this.hp + ' / ' + this.stats.HP + '\n' + 
                          '         AP: ' + this.ap + ' / ' + this.stats.AP + '\n\n' + 
                          '    species: ' + state.species.name + '\n' +
                          ' profession: ' + state.profession.base.name + '\n' +
                          'personality: ' + state.personality.name + '\n\n'
                         ,
                         this.describeQualities()
                         ,
                         
                          ' -Equipment-  \n'                
                                + 'hand(l): ' + this.getEquipped(slot:EQUIP_SLOTS.HAND_L).name + '\n'
                                + 'hand(r): ' + this.getEquipped(slot:EQUIP_SLOTS.HAND_R).name + '\n'
                                + 'armor  : ' + this.getEquipped(slot:EQUIP_SLOTS.ARMOR).name + '\n'
                                + 'amulet : ' + this.getEquipped(slot:EQUIP_SLOTS.AMULET).name + '\n'
                                + 'trinket: ' + this.getEquipped(slot:EQUIP_SLOTS.TRINKET).name + '\n'
                                + 'ring(l): ' + this.getEquipped(slot:EQUIP_SLOTS.RING_L).name + '\n'
                                + 'ring(r): ' + this.getEquipped(slot:EQUIP_SLOTS.RING_R).name + '\n'
                         ,
                        
                          
                            ' - Stat Modifiers - \n' +
                            modRate.getRates()
                         ,
                          ::<= {
                            @out = ' - Effects - \n\n';
                            foreach(state.effects)::(index, effect) {
                                out = out + effect.effect.name + ': ' + effect.effect.description + '\n';
                            }
                            return out;
                         }
                     ]                                   
                );                     
                           
                
                
                


            }
            

        }
        
        
    }
);


return Entity;
