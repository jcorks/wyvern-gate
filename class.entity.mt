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
@:dialogue = import(module:'singleton.dialogue.mt');
@:StatSet = import(module:'class.statset.mt');
@:Species = import(module:'class.species.mt');
@:Personality = import(module:'class.personality.mt');
@:Profession = import(module:'class.profession.mt');
@:NameGen = import(module:'singleton.namegen.mt');
@:Item = import(module:'class.item.mt');
@:Damage = import(module:'class.damage.mt');
@:Ability = import(module:'class.ability.mt');
@:Effect = import(module:'class.effect.mt');
@:Inventory = import(module:'class.inventory.mt');
@:BattleAI = import(module:'class.battleai.mt');
@:StateFlags = import(module:'class.stateflags.mt');
@:Location = import(module:'class.location.mt');
@:random = import(module:'singleton.random.mt');
@:canvas = import(module:'singleton.canvas.mt');

// returns EXP recommended for next level
@:levelUp ::(level, stats => StatSet.type, growthPotential => StatSet.type, whichStat) {
            
    stats.add(stats:StatSet.new(
        HP  : 2+(Number.random()*3)->floor,
        MP  : (Number.random()*3)->floor,
        ATK : (Number.random()*3)->floor,
        INT : (Number.random()*3)->floor,
        DEF : (Number.random()*3)->floor,
        SPD : (Number.random()*3)->floor,
        LUK : (Number.random()*3)->floor,
        DEX : (Number.random()*3)->floor
    ));
    
    return (50 + (level*level * 0.1056) * 1000)->floor;
};	

@:statUp ::(level, growth => Number) {

    @:stat :: (potential, level) {
        when(potential <= 0) potential = 1;
        return 1 + ((level**0.65) + (Number.random()*4))->floor;
    };
    return stat(potential:growth,  level:level+1);


};



@:EQUIP_SLOTS = {
    HAND_L : 0,
    HAND_R : 1,
    ARMOR : 2,
    AMULET : 3,
    RING_L : 4,
    RING_R : 5,
    TRINKET : 6
};

@:Entity = class(
    name : 'Wyvern.Entity', 
    statics : {
        EQUIP_SLOTS : EQUIP_SLOTS
   
    },
    
    
    define :::(this) {
        @stats = StatSet.new(HP:1);
        @hp = stats.HP;
        @mp = stats.MP;
        @:flags = StateFlags.new();
        @isDead = false;
        @name = NameGen.person();
        @nickname = empty;
        @species = Species.database.getRandom();
        @profession;
        @professions = [];
        @personality = Personality.database.getRandom();
        @emotionalState;
        @favoritePlace = Location.Base.database.getRandom();
        @growth = StatSet.new();
        @enemies_ = [];
        @allies_ = [];
        @abilitiesUsedBattle = empty;
        @adventurous = Number.random() <= 0.5;
        @battleAI = BattleAI.new(
            user: this
        );
        // requests removal from battle
        @requestsRemove = false;
        

        @none = Item.Base.database.find(name:'None').new();
        @:equips = [
            none, // handl
            none, // handr
            none, // armor
            none, // amulet
            none, // ringl
            none, // ringr
            none
        ];
        @effects = []; // effects. abilities and equips push / pop these.
        @abilitiesAvailable = [
            Ability.database.find(name:'Attack'),
            Ability.database.find(name:'Defend'),

        ]; // active that can choose in combat
        @abilitiesLearned = []; // abilities that can choose outside battle.
        
        @:inventory = Inventory.new();
        inventory.addGold(amount:(Number.random() * 100)->ceil);
        
        @expNext = 10;
        @level = 0;


        @:resetEffects :: {
            effects = [];
            
            [0, EQUIP_SLOTS.RING_R+1]->for(do:::(slot) {
                when(slot == EQUIP_SLOTS.HAND_R) empty;
                equips[slot].base.equipEffects->foreach(do:::(index, effect) {
                    this.addEffect(
                        from:this, 
                        name:effect, 
                        durationTurns: -1
                    );
                });
            });
            
            
            profession.base.passives->foreach(do:::(index, passiveName) {
                this.addEffect(
                    from:this, 
                    name:passiveName, 
                    durationTurns: -1
                );
            });
            
            if (profession.base.weaponAffinity == equips[EQUIP_SLOTS.HAND_L].base.name)
                this.addEffect(
                    from:this,
                    name:'Weapon Affinity',
                    durationTurns: -1 
                );      
        };


        this.constructor = ::(speciesHint, professionHint, levelHint => Number, state) {
            when(state != empty) ::<= {
                this.state = state;
                return this;
            };
            profession = if (professionHint == empty) 
                Profession.Base.database.getRandomFiltered(
                    filter:::(value) <- levelHint >= value.levelMinimum
                ).new() 
            else 
                    Profession.Base.database.find(name:professionHint).new()
            ;
            professions->push(value:profession);
            if (speciesHint != empty) ::<= {
                species = speciesHint;
            };
            
            growth.mod(stats:species.growth);
            growth.mod(stats:personality.growth);
            growth.mod(stats:profession.base.growth);
            [0, levelHint]->for(do:::(i) {
                this.autoLevel();                
            });

            ::<={
                [0, (Number.random()*5)->floor]->for(do:::(i) {
                    @:item = Item.Base.database.getRandomWeightedFiltered(
                        filter:::(value) <- level >= value.levelMinimum &&
                                            value.isUnique == false
                        
                    );
                    if (item.name != 'None') ::<={
                        @:itemInstance = item.new(from:this);
                        inventory.add(item:itemInstance);
                    };
                    
                    
                });
                
            };

            return this;
        };
        
        this.interface = {
            state : {
                set ::(value) {
                    hp = value.hp;
                    mp = value.mp;
                    stats.state = value.stats;
                    name = value.name;
                    nickname = value.nickname;
                    species = Species.database.find(name:value.speciesName);
                    professions = [];
                    value.professions->foreach(do:::(index, profState) {
                        @:p = Profession.Base.database.find(name:profState.baseName).new(state:profState);
                        professions->push(value:p);
                    });                
                    profession = professions[value.professionIndex];
                    personality = Personality.database.find(name:value.personalityName);
                    favoritePlace = Location.Base.database.find(name:value.favoritePlace);
                    growth.state = value.growth;
                    adventurous = value.adventurous;
                    battleAI.state = value.battleAI;
                    level = value.level;
                    expNext = value.expNext;
                    equips->foreach(do:::(index, eq) {
                        @:data = value.equips[index];
                        when(index == EQUIP_SLOTS.HAND_R) empty;
                        when(data.baseName == 'None') empty;
                        this.equip(slot:index, silent:true, inventory:inventory, item:Item.Base.database.find(name:data.baseName).new(state:data));
                    });
                    
                    inventory.state = value.inventory;
                    abilitiesLearned = [];
                    value.abilitiesLearned->foreach(do:::(index, name) {
                        abilitiesLearned->push(value:Ability.database.find(name));
                    });
                    abilitiesAvailable = [];
                    value.abilitiesAvailable->foreach(do:::(index, name) {
                        abilitiesAvailable->push(value:Ability.database.find(name));
                    });
                    
                },
            
                get :: {
                    return {
                        hp : hp,
                        mp : mp,
                        stats : stats.state,
                        name : name,
                        nickname : nickname,
                        speciesName : species.name,
                        professionIndex : professions->findIndex(value:profession),
                        professions : [...professions]->map(to:::(value) <- value.state),
                        personalityName : personality.name,
                        favoritePlace : favoritePlace.name,
                        growth : growth.state,
                        adventurous : adventurous,
                        battleAI : battleAI.state,
                        level : level,
                        expNext : expNext,
                        equips : [...equips]->map(to:::(value) <- value.state),
                        inventory : inventory.state,
                        abilitiesLearned : [...abilitiesLearned]->map(to:::(value) <- value.name),
                        abilitiesAvailable : [...abilitiesAvailable]->map(to:::(value) <- value.name),
                    };
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
            battleStart ::(allies, enemies) {
                battleAI.reset(
                    enemies: enemies,
                    allies: allies
                );            
                enemies_ = enemies;
                allies_ = allies;
                requestsRemove = false;
                abilitiesUsedBattle = {};
                resetEffects();              
            },
            

            // called to signal that a battle has started involving this entity
            battleEnd :: {
                effects->foreach(do:::(index, effect) {

                    effect.effect.onRemoveEffect(
                        user:effect.from, 
                        holder:this,
                        item:effect.item
                    );
                });
                allies_ = [];
                enemies_ = [];
                abilitiesUsedBattle = empty;                
                resetEffects();
            },

            
            recalculateStats :: {
                stats.resetMod();
                effects->foreach(do:::(index, effect) {
                    effect.effect.onStatRecalculate(user:effect.from, stats, holder:this, item:effect.item);
                    stats.modRate(stats:effect.effect.stats);
                });

                equips->foreach(do:::(index, equip) {
                    when(index == EQUIP_SLOTS.HAND_R) empty;
                    stats.modRate(stats:equip.equipMod);
                });
            },
            
            endTurn :: {
            },

            // lets the entity know that their turn has come.            
            actTurn ::() => Boolean {
                @act = true;
                effects->foreach(do:::(index, effect) {                        
                    if (effect.duration != -1 && effect.turnIndex >= effect.duration) ::<= {
                        effect.effect.onRemoveEffect(
                            user:effect.from, 
                            holder:this,
                            item:effect.item
                        );
                        effects->remove(key:index);
                    } else ::<= {
                        if (effect.effect.skipTurn == true)
                            act = false;
                        effect.effect.onNextTurn(user:effect.from, turnIndex:effect.turnIndex, turnCount: effect.duration, holder:this, item:effect.item);                    
                        effect.turnIndex += 1;
                    };
                });
                return act;
            },

            
            flags : {
                get :: {
                    return flags;
                }
            },
            
            name : {
                get :: {
                    when (nickname != empty) nickname;
                    return name;
                }
            },
            
            species : {
                get :: {
                    return species;
                } 
            },

            requestsRemove : {
                get ::<- requestsRemove,
                set ::(value) <- requestsRemove = value
            },

            profession : {
                get :: {
                    return profession;
                },
                
                set ::(value => Profession.type) {
                    profession = [::]{
                        professions->foreach(do:::(index, prof) {
                            if (value.base.name == prof.base.name) ::<= {
                                send(message:prof);
                            };
                        });
                        professions->push(value);
                        return value;
                    };            
                    
                                        
                    growth.resetMod();
                    growth.mod(stats:species.growth);
                    growth.mod(stats:personality.growth);
                    growth.mod(stats:profession.base.growth);
                
                
                }
            },
            
            nickname : {
                set ::(value) {
                    nickname = value;
                }
            },
            
            renderHP ::(length) {
                if (length == empty) length = 12;
                
                @:numFilled = ((length - 2) * (hp / stats.HP))->floor;
                
                @out = ' ';
                [0, numFilled]->for(do:::(i) {
                    out = out+'▓';
                });
                [0, length - numFilled - 2]->for(do:::(i) {
                    out = out+'▁';
                });
                return out + ' ';
                
            },
            
            level : {
                get ::{
                    return level;
                }
            },
            
            effects : {
                get ::<- [...effects]
            },
            
            
            attack::(
                amount => Number,
                damageType => Number,
                damageClass => Number,
                target => this.type
            ){
                @:dmg = Damage.new(
                    amount,
                    damageType,
                    damageClass
                );
                
                @:damaged = [];
                // TODO: add weapon affinities if phys and equip weapon
                // phys is always assumed to be with equipped weapon
                effects->foreach(do:::(index, effect) {
                    when (dmg.amount <= 0) empty;
                    effect.effect.onGiveDamage(user:effect.from, item:effect.item, holder:this, to:target, damage:dmg);
                });
                when(dmg.amount <= 0) empty;
                target.damage(from:this, damage:dmg);


                
                effects->foreach(do:::(index, effect) {
                    effect.effect.onGivenDamage(user:effect.from, item:effect.item, holder:this, to:target);
                });

            },
            
            damage ::(from => this.type, damage => Damage.type) {
                when(isDead) empty;

                if (from.stats.DEX > this.stats.DEX)               
                    // as DEX increases: randomness decreases 
                    // amount of reliable damage increases
                    // This models user skill vs receiver skill
                    damage.amount = damage.amount + damage.amount * ((Number.random() - 0.5) * (this.stats.DEX / from.stats.DEX) + (1 -  this.stats.DEX / from.stats.DEX))
                else
                    damage.amount = damage.amount + damage.amount * (Number.random() - 0.5)
                ; 
                
                @critChance = 0.999 - (this.stats.LUK - level) / 100;
                if (critChance < 0.90) critChance = 0.9;
                if (Number.random() > critChance) ::<={
                    damage.amount += from.stats.DEX * 2.5;
                    dialogue.message(text: 'Critical damage!');
                };

                damage.amount -= stats.DEF/4;
                if (damage.amount <= 0) damage.amount = 1;


                effects->foreach(do:::(index, effect) {
                    effect.effect.onDamage(user:effect.from, holder:this, from, damage);
                });


                when (damage.amount == 0) empty;
                when(hp == 0) ::<= {
                    dialogue.message(text: '' + this.name + ' has died!');                
                    flags.add(flag:StateFlags.IS_DEAD);
                    isDead = true;                    
                };
                
                if (damage.damageClass == Damage.CLASS.HP) ::<= {
                    hp -= damage.amount;
                    if (hp < 0) hp = 0;
                    dialogue.message(text: '' + this.name + ' received ' + damage.amount + ' damage (HP:' + this.renderHP() + ')' );
                } else ::<= {
                    mp -= damage.amount;
                    if (mp < 0) mp = 0;                
                    dialogue.message(text: '' + this.name + ' received ' + damage.amount + ' MP damage (MP:' + mp + '/' + stats.MP + ')' );

                };
                @:world = import(module:'singleton.world.mt');

                if (world.party.isMember(entity:this) && damage.amount > stats.HP * 0.2 && Number.random() > 0.7)
                    dialogue.message(
                        speaker: this.name,
                        text: '"' + random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.HURT]) + '"'
                    );
                    

                flags.add(flag:StateFlags.HURT_THIS_TURN);
                
                if (damage.damageType == Damage.TYPE.FIRE && Number.random() > 0.9)
                    this.addEffect(from, name:'Burned',durationTurns:5);
                if (damage.damageType == Damage.TYPE.ICE && Number.random() > 0.9)
                    this.addEffect(from, name:'Frozen',durationTurns:5);
                if (damage.damageType == Damage.TYPE.THUNDER && Number.random() > 0.9)
                    this.addEffect(from, name:'Paralyzed',durationTurns:5);
                
                
                if (world.party.isMember(entity:this) && hp == 0 && Number.random() > 0.7) ::<= {
                    dialogue.message(
                        speaker: this.name,
                        text: '"' + random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.DEATH]) + '"'
                    );
                };
                
                if (hp == 0)
                    dialogue.message(text: '' + this.name + ' has been knocked out.');                                
                                
                
            },
            
            // where they roam to in their freetime. if places doesnt have one they stay home
            favoritePlace : {
                get ::<- favoritePlace
            },
            
            heal ::(amount => Number) {
                amount = amount->ceil;
                hp += amount;
                if (hp > stats.HP) hp = stats.HP;
                dialogue.message(text: '' + this.name + ' heals ' + amount + ' HP (HP:' + this.renderHP() + ')');
            },
            
            healMP ::(amount => Number) {
                amount = amount->ceil;
                mp += amount;
                if (mp > stats.MP) mp = stats.MP;
                dialogue.message(text: '' + this.name + ' heals ' + amount + ' MP (MP:' + mp + '/' + stats.MP + ')');
                
                
            },
            
            
            isIncapacitated :: {
                return hp <= 0;
            },
            
            isDead : {
                get :: {
                    return isDead;
                }   
            },
            
            gainExp ::(amount => Number, chooseStat, afterLevel) {
                [::] {
                    forever(do:::{
                        when(amount <= 0) send();
                        when(amount < expNext) ::<={
                            expNext -= amount;
                            send();
                        };
                        
                        amount -= expNext;
                        expNext = levelUp(
                            level,
                            stats,
                            growthPotential : growth
                        );
                        
                        if (chooseStat == empty) ::<={ 
                            @choice = random.integer(from:0, to:7);
                            stats.add(stats: StatSet.new(
                                HP: if (choice == 0) statUp(level, growth:growth.HP) else 0,
                                MP: if (choice == 1) statUp(level, growth:growth.MP) else 0,
                                ATK: if (choice == 2) statUp(level, growth:growth.ATK) else 0,
                                DEF: if (choice == 3) statUp(level, growth:growth.DEF) else 0,
                                INT: if (choice == 4) statUp(level, growth:growth.INT) else 0,
                                SPD: if (choice == 5) statUp(level, growth:growth.SPD) else 0,
                                LUK: if (choice == 6) statUp(level, growth:growth.LUK) else 0,
                                DEX: if (choice == 7) statUp(level, growth:growth.DEX) else 0
                            
                            ));
                        
                        } else ::<= {
                            @hp = statUp(level, growth:growth.HP);                            
                            @mp = statUp(level, growth:growth.MP);                            
                            @atk = statUp(level, growth:growth.ATK);                            
                            @def = statUp(level, growth:growth.DEF);                            
                            @luk = statUp(level, growth:growth.LUK);                            
                            @spd = statUp(level, growth:growth.SPD);                            
                            @dex = statUp(level, growth:growth.DEX);                            
                            @int = statUp(level, growth:growth.INT);                            
                            @choice = chooseStat(
                                hp, mp, atk, def, int, spd, luk, dex
                            );
                            
                            stats.add(stats: StatSet.new(
                                HP: if (choice == 0) hp else 0,
                                MP: if (choice == 1) mp else 0,
                                ATK: if (choice == 2) atk else 0,
                                DEF: if (choice == 3) def else 0,
                                INT: if (choice == 4) int else 0,
                                SPD: if (choice == 5) spd else 0,
                                LUK: if (choice == 6) luk else 0,
                                DEX: if (choice == 7) dex else 0
                            ));                            
                            
                            
                        
                        };
                        if (afterLevel != empty) afterLevel();
                        hp = stats.HP;
                        mp = stats.MP;
                        level += 1;
                    });
                };
                this.recalculateStats();                
            },
            
            stats : {
                get :: {
                    return stats;
                }
            },
            
            autoLevel :: {
                this.gainExp(amount:expNext);  
            },
            
            dropExp :: {
                return 
                    ((stats.HP +
                    stats.MP +
                    stats.ATK +
                    stats.INT +
                    stats.DEF +
                    stats.SPD + 
                    stats.DEX + 
                    stats.LUK)* 1.7 + 40)->floor
                ;
            },
            
            // whether they would be okay with being hired for the team.
            adventurous : {
                get :: {
                    return adventurous;
                }
            },
            
            addEffect::(from => Entity.type, name => String, durationTurns => Number, item) {
                if (durationTurns == empty) durationTurns = -1;
                @einst = {
                    from: from,
                    item : item,
                    effect: Effect.database.find(name),
                    duration: durationTurns,
                    turnIndex: 0
                };
                if (einst.effect == empty || einst.duration->type != Number) error(detail:'Bad addEffect() call: effect or duration was invalid.');                
                if (durationTurns != 0)
                    effects->push(value:einst);
                

                einst.effect.onAffliction(
                    user:from, 
                    holder:this,
                    item
                );
                this.recalculateStats();

            },
            
            
            removeEffects::(effectBases => Object) {
                effects = effects->filter(by:::(value) {
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
                    };
                });
            },
            
            abilitiesAvailable : {
                get :: {
                    return abilitiesAvailable;
                }
            },
            
            learnAbility::(name => String) {
                when (name == empty) empty;

                @:ability = Ability.database.find(name);
                if (abilitiesAvailable->keycount < 7)
                    abilitiesAvailable->push(value:ability);
                    
                abilitiesLearned->push(value:ability);
            },
            
            hp : {
                get :: {
                    return hp;
                }
            },
            
            mp : {
                get :: {
                    return mp;
                }
            },
            
            rest :: {
                hp = stats.HP;
                mp = stats.MP;
            },
            
            inventory : {
                get :: {
                    return inventory;
                }
            },
            
            battleAI : {
                get ::<- battleAI
            },
            
            equip ::(item => none->type, slot => Number, silent, inventory => Inventory.type) {
                this.recalculateStats();
                @:oldstats = StatSet.new();
                oldstats.add(stats: this.stats);

                @olditem = equips[slot];
        
                when (this.getSlotsForItem(item)->findIndex(value:slot) == -1)
                    error(detail:'Item does not enter the given slot.');


                @:old = this.unequip(slot, silent:true);                
                if (old != empty)
                    inventory.add(item:old);

                if (item.base.equipType == Item.TYPE.TWOHANDED) ::<={
                    equips[EQUIP_SLOTS.HAND_L] = item;
                    equips[EQUIP_SLOTS.HAND_R] = item;
                } else ::<= {
                    equips[slot] = item;
                };
                
                
                item.base.equipEffects->foreach(do:::(index, effect) {
                    this.addEffect(
                        from:this, 
                        name:effect, 
                        durationTurns: -1
                    );
                });

                inventory.remove(item);
                
                this.recalculateStats();

                
                if (silent != true) ::<={
                    if (olditem.name == 'None') ::<= {
                        dialogue.message(text:this.name + ' has equipped the ' + item.name + '.');                    
                    } else ::<= {
                        dialogue.message(text:this.name + ' unequipped the ' + olditem.name + ' and equipped the ' + item.name + '.');                    
                    };
                    oldstats.printDiff(prompt: '(Equipped: ' + item.name + ')', other:this.stats);
                };
            },
            anonymize :: {
                this.nickname = 'the ' + this.species.name + (if(this.profession.base.name == 'None') '' else ' ' + this.profession.base.name);            
            },
            
            getEquipped::(slot => Number) {
                return equips[slot];
            },
            
            
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
                };
            },
            
            
            unequip ::(slot => Number, silent) {
                @:current = equips[slot];
                if (equips[slot].base.equipType == Item.TYPE.TWOHANDED) ::<={
                    equips[EQUIP_SLOTS.HAND_L] = none;                                
                    equips[EQUIP_SLOTS.HAND_R] = none;                                
                } else ::<={
                    equips[slot] = none;                
                };
                
                current.base.equipEffects->foreach(do:::(i, effect) {
                    @:effectObj = effects->filter(by:::(value) <- value.effect.name == effect)[0];
                    effectObj.effect.onRemoveEffect(
                        user:effectObj.from, 
                        holder:this,
                        item:effectObj.item
                    );
                    
                    effects->remove(key:effects->findIndex(value:effectObj));
                });
                
                this.recalculateStats();
                return current;
            },
            
            useAbility::(ability, targets, turnIndex, extraData) {
                when(mp < ability.mpCost) dialogue.message(
                    text: this.name + " tried to use " + ability.name + ", but couldn\'t muster the mental strength!"
                );
                when(hp < ability.hpCost) dialogue.message(
                    text: this.name + " tried to use " + ability.name + ", but couldn't muster the strength!"
                );
                
                when (abilitiesUsedBattle != empty && ability.oncePerBattle && abilitiesUsedBattle[ability.name] == true) dialogue.message(
                    text: this.name + " tried to use " + ability.name + ", but it worked the first time!"
                );
                if (abilitiesUsedBattle) abilitiesUsedBattle[ability.name] = true;
                
                mp -= ability.mpCost;
                hp -= ability.hpCost;
                ability.onAction(
                    user:this,
                    targets, turnIndex, extraData                 
                );
            
            },
            
            // interacts with this entity
            interactPerson ::(party, location) {
                dialogue.message(
                    speaker: name,
                    text: random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.GREET])
                );                
                @:choice = dialogue.choicesNow(
                    canCancel : true,
                    prompt: 'Talking to ' + name,
                    choices: [
                        'chat',
                        'hire',
                        'aggress...'
                    ]
                );  
                
                when(choice == 0) empty;
                
                match(choice-1) {
                  // Chat
                  (0): ::<= {
                    dialogue.message(
                        speaker: name,
                        text: random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.CHAT])
                    );                                                        
                  },
                  
                  // hire 
                  (1): ::<= {
                    when(party.isMember(entity:this))
                        dialogue.message(
                            text: name + ' is already a party member.'
                        );                
                  
                    when (party.members->keycount >= 3 || !adventurous)
                        dialogue.message(
                            speaker: name,
                            text: random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_DENY])
                        );                
                        
                    dialogue.message(
                        speaker: name,
                        text: random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_ACCEPT])
                    );                

                    @:cost = 50+((stats.sum/3 + level)*2.5)->ceil;


                    this.describe();

                    when(dialogue.askBoolean(
                        prompt: 'Hire for ' + cost + 'G?'
                    ) == false) empty;
                    
                    when(party.inventory.gold < cost)
                        dialogue.message(
                            text: 'The party cannot afford to hire ' + name
                        );                
                        
                    party.inventory.subtractGold(amount:cost);
                    party.add(member:this);
                        dialogue.message(
                            text: name + ' joins the party!'
                        );                
                    

                    
                  }
                
                };
                
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
            
            describe:: {
                @:plainStats = StatSet.new();
                stats.resetMod();
                plainStats.add(stats);
                this.recalculateStats();
                dialogue.message(
                    speaker: this.name,
                    text: '       Name: ' + name + '\n\n' +
                          '         HP: ' + this.hp + ' / ' + this.stats.HP + '\n' + 
                          '         MP: ' + this.mp + ' / ' + this.stats.MP + '\n\n' + 
                          '    species: ' + species.name + '\n' +
                          ' profession: ' + profession.base.name + '\n' +
                          'personality: ' + personality.name + '\n\n' +
                                'Level: ' + level + ' (would drop ' + this.dropExp() + ' EXP) \n' +
                          'Exp to next: ' + expNext + '\n',

                    pageAfter:canvas.height-4
                );
                

                
                plainStats.printDiff(other:stats, 
                    prompt:this.name + '(Base -> w/Mods.)'
                );
                    


                dialogue.message(
                    speaker: this.name,
                    text: 
                    ' -Equipment-  \n'                
                        + 'hand(l): ' + equips[EQUIP_SLOTS.HAND_L].name + '\n'
                        + 'hand(r): ' + equips[EQUIP_SLOTS.HAND_R].name + '\n'
                        + 'armor  : ' + equips[EQUIP_SLOTS.ARMOR].name + '\n'
                        + 'amulet : ' + equips[EQUIP_SLOTS.AMULET].name + '\n'
                        + 'trinket: ' + equips[EQUIP_SLOTS.TRINKET].name + '\n'
                        + 'ring(l): ' + equips[EQUIP_SLOTS.RING_L].name + '\n'
                        + 'ring(r): ' + equips[EQUIP_SLOTS.RING_R].name + '\n',
                    pageAfter:canvas.height-4
                );
                
                @:modRate = StatSet.new();
                effects->foreach(do:::(index, effect) {
                    effect.effect.onStatRecalculate(user:effect.from, stats, holder:this, item:effect.item);
                    modRate.add(stats:effect.effect.stats);
                });

                equips->foreach(do:::(index, equip) {
                    when(index == EQUIP_SLOTS.HAND_R) empty;
                    modRate.add(stats:equip.equipMod);
                });


                dialogue.message(
                    speaker: this.name,
                    text: 
                    ' - Stat Modifiers - \n' +
                    modRate.getRates(),
                    pageAfter:canvas.height-4
                );
                
                if (effects->keycount) ::<= {
                    @out = ' - Effects - \n\n';
                    effects->foreach(do:::(index, effect) {
                        out = out + effect.effect.name + ': ' + effect.effect.description + '\n';
                    });
                    dialogue.message(
                        speaker: this.name,
                        text: out,
                        pageAfter:canvas.height-4
                    );
                    
                    
                };
            }
            

        };
        
        
    }
);


return Entity;
