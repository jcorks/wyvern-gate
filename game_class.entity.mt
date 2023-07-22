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

// returns EXP recommended for next level
@:levelUp ::(level, stats => StatSet.type, growthPotential => StatSet.type, whichStat) {
            
    stats.add(stats:StatSet.new(
        HP  : 2+(Number.random()*3)->floor,
        AP  : 2+(Number.random()*3)->floor,
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


@:removeDuplicates ::(list) {
    @:temp = {};
    list->foreach(do:::(index, val) {
        temp[val] = val;
    });
    return temp->keys;
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
        @ap = stats.AP;
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
        @favoriteItem = Item.Base.database.getRandomFiltered(filter::(value) <- value.isUnique == false && value.tier <= story.tier);
        @growth = StatSet.new();
        @enemies_ = [];
        @allies_ = [];
        @battle_;
        @qualityDescription = empty;
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
        
        @:inventory = Inventory.new(size:10);
        inventory.addGold(amount:(Number.random() * 100)->ceil);
        
        [0, 3]->for(do::(i) {
            inventory.add(item:Item.Base.database.getRandomFiltered(
                    filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                                            && value.tier <= story.tier
                ).new(rngEnchantHint:true, from:this));
        });
        @expNext = 10;
        @level = 0;
        @onInteract = empty;


        @:resetEffects :: {
            effects = [];
            
            [0, EQUIP_SLOTS.RING_R+1]->for(do:::(slot) {
                when(slot == EQUIP_SLOTS.HAND_R) empty;
                equips[slot].equipEffects->foreach(do:::(index, effect) {
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
                    };
                    
                    
                });
                
            };
            */

            return this;
        };
        
        this.interface = {
            state : {
                set ::(value) {
                    hp = value.hp;
                    ap = value.ap;
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
                        ap : ap,
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
            battleStart ::(battle, allies, enemies) {
                battle_ = battle;
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
            
            battle : {
                get ::<- battle_
            },
            

            // called to signal that a battle has started involving this entity
            battleEnd :: {
                battle_ = empty;
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
            
            personality : {
                get ::<- personality
            },
            
            endTurn ::(battle) {
                EQUIP_SLOTS->foreach(do:::(str, i) {
                    when(i == 0 && equips[0] == equips[1]) empty;
                    equips[i].onTurnEnd(wielder:this, battle);
                });
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
                
                if (this.stats.SPD < 0) ::<= {
                    windowEvent.queueMessage(text:this.name + ' cannot move due to negative speed!');
                    act = false;
                };

                if (this.stats.DEX < 0) ::<= {
                    windowEvent.queueMessage(text:this.name + ' fumbles about due to negative dexterity!');
                    act = false;
                };

                if (act == false)
                    this.flags.add(flag:StateFlags.SKIPPED);
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
                },
                
                set ::(value => String) {
                    name = value;
                }
            },
            
            species : {
                get :: {
                    return species;
                }, 
                
                set ::(value) {
                    species = value;
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
                    effect.effect.onPreAttackOther(user:effect.from, item:effect.item, holder:this, to:target, damage:dmg);
                });
                
                when(dmg.amount <= 0) empty;
                target.effects->foreach(do:::(index, effect) {
                    when (dmg.amount <= 0) empty;
                    effect.effect.onAttacked(user:target, item:effect.item, holder:target, by:this, damage:dmg);                
                });
                

                when(dmg.amount <= 0) empty;
                when(target.hp == 0) ::<= {
                    this.flags.add(flag:StateFlags.DEFEATED_ENEMY);
                    target.flags.add(flag:StateFlags.DIED);
                    target.kill();                
                };

                when(!target.damage(from:this, damage:dmg, dodgeable:true)) empty;

                this.flags.add(flag:StateFlags.ATTACKED);


                
                effects->foreach(do:::(index, effect) {
                    effect.effect.onPostAttackOther(user:effect.from, item:effect.item, holder:this, to:target);
                });
                return true;
            },
            
            damage ::(from => this.type, damage => Damage.type, dodgeable => Boolean) {
                when(isDead) empty;

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
                };
                
                when(whiff) ::<= {
                    windowEvent.queueMessage(text:random.pickArrayItem(list:[
                        this.name + ' lithely dodges ' + from.name + '\'s attack!',                 
                        this.name + ' narrowly dodges ' + from.name + '\'s attack!',                 
                        this.name + ' dances around ' + from.name + '\'s attack!',                 
                        from.name + '\'s attack completely misses ' + this.name + '!'
                    ]));
                    this.flags.add(flag:StateFlags.DODGED_ATTACK);
                    return false;
                };


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
                    windowEvent.queueMessage(text: 'Critical damage!');
                };

                damage.amount -= stats.DEF/4;
                if (damage.amount <= 0) damage.amount = 1;


                effects->foreach(do:::(index, effect) {
                    effect.effect.onDamage(user:effect.from, holder:this, from, damage);
                });


                when (damage.amount == 0) false;
                when(hp == 0) false;

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
                    };
                };
                
                if (damage.damageClass == Damage.CLASS.HP) ::<= {
                    hp -= damage.amount;
                    if (hp < 0) hp = 0;
                    windowEvent.queueMessage(text: '' + this.name + ' received ' + damage.amount + ' '+damageTypeName() + 'damage (HP:' + this.renderHP() + ')' );
                } else ::<= {
                    ap -= damage.amount;
                    if (ap < 0) ap = 0;                
                    windowEvent.queueMessage(text: '' + this.name + ' received ' + damage.amount + ' AP damage (AP:' + ap + '/' + stats.AP + ')' );

                };
                @:world = import(module:'game_singleton.world.mt');

                if (world.party.isMember(entity:this) && damage.amount > stats.HP * 0.2 && Number.random() > 0.7)
                    windowEvent.queueMessage(
                        speaker: this.name,
                        text: '"' + random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.HURT]) + '"'
                    );
                    

                flags.add(flag:StateFlags.HURT);
                
                if (damage.damageType == Damage.TYPE.FIRE && Number.random() > 0.9)
                    this.addEffect(from, name:'Burned',durationTurns:5);
                if (damage.damageType == Damage.TYPE.ICE && Number.random() > 0.9)
                    this.addEffect(from, name:'Frozen',durationTurns:5);
                if (damage.damageType == Damage.TYPE.THUNDER && Number.random() > 0.9)
                    this.addEffect(from, name:'Paralyzed',durationTurns:5);
                if (damage.damageType == Damage.TYPE.PHYS && Number.random() > 0.99) 
                    this.addEffect(from, name:'Bleeding',durationTurns:5);
                if (damage.damageType == Damage.TYPE.POISON && Number.random() > 0.9) 
                    this.addEffect(from, name:'Poisoned',durationTurns:5);
                if (damage.damageType == Damage.TYPE.DARK && Number.random() > 0.9)
                    this.addEffect(from, name:'Blind',durationTurns:5);
                if (damage.damageType == Damage.TYPE.LIGHT && Number.random() > 0.9)
                    this.addEffect(from, name:'Petrified',durationTurns:5);
                
                
                if (world.party.isMember(entity:this) && hp == 0 && Number.random() > 0.7) ::<= {
                    windowEvent.queueMessage(
                        speaker: this.name,
                        text: '"' + random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.DEATH]) + '"'
                    );
                };
                
                if (hp == 0) ::<= {
                    windowEvent.queueMessage(text: '' + this.name + ' has been knocked out.');                                
                    this.flags.add(flag:StateFlags.FALLEN);
                    from.flags.add(flag:StateFlags.DEFEATED_ENEMY);
                };

                return true;
            },
            
            // where they roam to in their freetime. if places doesnt have one they stay home
            favoritePlace : {
                get ::<- favoritePlace
            },
            
            heal ::(amount => Number, silent) {
                when(hp >= stats.HP) empty;
                amount = amount->ceil;
                hp += amount;
                this.flags.add(flag:StateFlags.HEALED);
                if (hp > stats.HP) hp = stats.HP;
                if (silent == empty)
                    windowEvent.queueMessage(text: '' + this.name + ' heals ' + amount + ' HP (HP:' + this.renderHP() + ')');
            },
            
            healAP ::(amount => Number, silent) {
                amount = amount->ceil;
                ap += amount;
                if (ap > stats.AP) ap = stats.AP;
                if (silent == empty)
                    windowEvent.queueMessage(text: '' + this.name + ' heals ' + amount + ' AP (AP:' + ap + '/' + stats.AP + ')');
                
                
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
                                AP: if (choice == 1) statUp(level, growth:growth.AP) else 0,
                                ATK: if (choice == 2) statUp(level, growth:growth.ATK) else 0,
                                DEF: if (choice == 3) statUp(level, growth:growth.DEF) else 0,
                                INT: if (choice == 4) statUp(level, growth:growth.INT) else 0,
                                SPD: if (choice == 5) statUp(level, growth:growth.SPD) else 0,
                                LUK: if (choice == 6) statUp(level, growth:growth.LUK) else 0,
                                DEX: if (choice == 7) statUp(level, growth:growth.DEX) else 0
                            
                            ));
                        
                        } else ::<= {
                            @hp = statUp(level, growth:growth.HP);                            
                            @ap = statUp(level, growth:growth.AP);                            
                            @atk = statUp(level, growth:growth.ATK);                            
                            @def = statUp(level, growth:growth.DEF);                            
                            @luk = statUp(level, growth:growth.LUK);                            
                            @spd = statUp(level, growth:growth.SPD);                            
                            @dex = statUp(level, growth:growth.DEX);                            
                            @int = statUp(level, growth:growth.INT);                            
                            @choice = chooseStat(
                                hp, ap, atk, def, int, spd, luk, dex
                            );
                            
                            stats.add(stats: StatSet.new(
                                HP: if (choice == 0) hp else 0,
                                AP: if (choice == 1) ap else 0,
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
                        ap = stats.AP;
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
                    stats.AP +
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
            
            kill ::(silent) {
                hp = 0;
                if (silent == empty)
                    windowEvent.queueMessage(text: '' + this.name + ' has died!');                
                flags.add(flag:StateFlags.DIED);
                isDead = true;                
            },
            
            addEffect::(from => Entity.type, name => String, durationTurns => Number, item) {
                if (durationTurns == empty) durationTurns = -1;
                
                @:effect = Effect.database.find(name);
                @:existingEffectIndex = effects->findIndex(query::(value) <- value.effect.name == name);               
                when (effect.stackable == false && existingEffectIndex != -1) ::<= {
                    // reset duration of effect and source.
                    @einst = effects[existingEffectIndex];
                    einst.duration = durationTurns;
                    einst.turnIndex = 0;
                    einst.item = item;
                    einst.from = from;
                };
                
                @einst = {
                    from: from,
                    item : item,
                    effect : effect,
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
                    @out = [...abilitiesAvailable];
                    EQUIP_SLOTS->foreach(do::(i, val) {
                        if (equips[val] != empty && equips[val].ability != empty) ::<= {
                            @:ab = Ability.database.find(name:equips[val].ability);
                            when(out->findIndex(value:ab) != -1) empty;
                            out->push(value:ab);
                        };
                    });
                    return out;
                }
            },
            
            learnAbility::(name => String) {
                when (name == empty) empty;

                @:ability = Ability.database.find(name);
                if (abilitiesAvailable->keycount < 7)
                    abilitiesAvailable->push(value:ability);
                    
                abilitiesLearned->push(value:ability);
            },
            
            learnNextAbility::{
                @:skills = this.profession.gainSP(amount:1);
                when(skills == empty) empty;
                skills->foreach(do:::(i, skill) {
                    this.learnAbility(name:skill);
                });
            },
            
            clearAbilities::{
                @abilitiesAvailable = [
                    Ability.database.find(name:'Attack'),
                    Ability.database.find(name:'Defend'),
                ];
                abilitiesLearned = [];
            },
            
            hp : {
                get :: {
                    return hp;
                }
            },
            
            ap : {
                get :: {
                    return ap;
                }
            },
            
            rest :: {
                hp = stats.HP;
                ap = stats.AP;
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
        
                when (this.getSlotsForItem(item)->findIndex(value:slot) == -1) ::<= {
                    when(silent) empty;
                    error(detail:'Item does not enter the given slot.');
                };



                @:old = this.unequip(slot, silent:true);                


                if (old != empty)
                    inventory.add(item:old);

                if (item.base.equipType == Item.TYPE.TWOHANDED) ::<={
                    equips[EQUIP_SLOTS.HAND_L] = item;
                    equips[EQUIP_SLOTS.HAND_R] = item;
                } else ::<= {
                    equips[slot] = item;
                };
                
                
                item.equipEffects->foreach(do:::(index, effect) {
                    this.addEffect(
                        from:this, 
                        name:effect, 
                        durationTurns: -1
                    );
                });

                if (profession.base.weaponAffinity == equips[EQUIP_SLOTS.HAND_L].base.name) ::<= {
                    if (silent != true) ::<= {
                        windowEvent.queueMessage(
                            speaker: this.name,
                            text: '"This ' + item.base.name + ' really works for me as ' + correctA(word:profession.base.name) + '"'
                        );
                    };
                    this.addEffect(
                        from:this,
                        name:'Weapon Affinity',
                        durationTurns: -1 
                    );
                };



                inventory.remove(item);
                
                this.recalculateStats();

                
                if (silent != true) ::<={
                    if (olditem.name == 'None') ::<= {
                        windowEvent.queueMessage(text:this.name + ' has equipped the ' + item.name + '.');                    
                    } else ::<= {
                        windowEvent.queueMessage(text:this.name + ' unequipped the ' + olditem.name + ' and equipped the ' + item.name + '.');                    
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
                if (profession.base.weaponAffinity == current.base.name)
                    effects->remove(key:effects->findIndex(query::(value) <- value.effect.name == 'Weapon Affinity'));
                


                
                current.equipEffects->foreach(do:::(i, effect) {
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
            unequipItem ::(item, silent) {
                equips->foreach(do:::(slot, equip) {
                    if (equip == item)
                        this.unequip(slot, silent);
                });
            },
            
            useAbility::(ability, targets, turnIndex, extraData) {
                when(ap < ability.apCost) windowEvent.queueMessage(
                    text: this.name + " tried to use " + ability.name + ", but couldn\'t muster the mental strength!"
                );
                when(hp < ability.hpCost) windowEvent.queueMessage(
                    text: this.name + " tried to use " + ability.name + ", but couldn't muster the strength!"
                );
                
                when (abilitiesUsedBattle != empty && ability.oncePerBattle && abilitiesUsedBattle[ability.name] == true) windowEvent.queueMessage(
                    text: this.name + " tried to use " + ability.name + ", but it worked the first time!"
                );
                if (abilitiesUsedBattle) abilitiesUsedBattle[ability.name] = true;
                
                ap -= ability.apCost;
                hp -= ability.hpCost;
                ability.onAction(
                    user:this,
                    targets, turnIndex, extraData                 
                );
            
            },
            
            // interacts with this entity
            interactPerson ::(party, location, onDone) {
                when(onInteract) onInteract(party, location, onDone);
                
                @:finish ::{
                    onDone();
                    windowEvent.jumpToTag(name:'InteractPerson', goBeforeTag:true, doResolveNext:true);
                };
                
                windowEvent.queueMessage(
                    speaker: name,
                    text: random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.GREET])
                );                
                windowEvent.queueChoices(
                    canCancel : true,
                    prompt: 'Talking to ' + name,
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
                            windowEvent.queueMessage(
                                speaker: name,
                                text: random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.CHAT])
                            );                                                        
                          },
                          
                          // hire 
                          (1): ::<= {
                            when(party.isMember(entity:this))
                                windowEvent.queueMessage(
                                    text: name + ' is already a party member.'
                                );                
                          
                            when (party.members->keycount >= 3 || !adventurous)
                                windowEvent.queueMessage(
                                    speaker: name,
                                    text: random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_DENY])
                                );                
                                
                            windowEvent.queueMessage(
                                speaker: name,
                                text: random.pickArrayItem(list:personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_ACCEPT])
                            );                

                            @:cost = 50+((stats.sum/3 + level)*2.5)->ceil;


                            this.describe();

                            windowEvent.queueAskBoolean(
                                prompt: 'Hire for ' + cost + 'G?',
                                onChoice::(which) {
                                    when(which == false) empty;
                                    when(party.inventory.gold < cost)
                                        windowEvent.queueMessage(
                                            text: 'The party cannot afford to hire ' + name
                                        );                
                                        
                                    party.inventory.subtractGold(amount:cost);
                                    party.add(member:this);
                                        windowEvent.queueMessage(
                                            text: name + ' joins the party!'
                                        );                

                                }
                            );
                          },
                          
                          // barter
                          (2):::<= {
                            when (inventory.isEmpty) ::<= {
                                windowEvent.queueMessage(
                                    text: name + ' has nothing to barter with.'
                                );                
                            };
                            @:item = inventory.items[0];

                            windowEvent.queueMessage(
                                text: name + ' is interested in acquiring ' + correctA(word:favoriteItem.name) + '. They are willing to trade one for their ' + item.name + '.'
                            );                
                            
                            
                            @:tradeItems = party.inventory.items->filter(by::(value) <- value.base == favoriteItem);
                            
                            when(tradeItems->keycount == 0) ::<= {
                                windowEvent.queueMessage(
                                    text: 'You have no such items to trade, sadly.'
                                );                                                 
                            };
                            


                            windowEvent.queueChoices(
                                prompt: name + ' - bartering',
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
                                                    text: 'In exchange for your ' + chosenItem.name + ', ' + name + ' gives the party ' + correctA(word:item.name) + '.'
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
                                    };   
                                }
                            );

                            
                            
                            
                          }
                        
                        };                    
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
                when (qualityDescription) qualityDescription;
                
                @qualities = [];
                species.qualities->foreach(do:::(i, qual) {
                    @:q = EntityQuality.Base.database.find(name:qual);
                    if (q.appearanceChance == 1 || Number.random() < q.appearanceChance)
                        qualities->push(value:q.new());
                });

            
                @out = this.name + ' is ' + correctA(word:species.name) + '. ';
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
                };

                @:describeSingle::(qual, index) {
                    return ([
                        this.name + '\'s ' + qual.name + 
                                (if (qual.plural) ' are ' else ' is ') 
                            + qual.description + '. ',

                        'Their ' + qual.name + 
                                (if (qual.plural) ' are very clearly ' else ' is very clearly ') 
                            + qual.description + '. ',
                            

                        'Their ' + qual.name + 
                                (if (qual.plural) ' are ' else ' is ') 
                            + qual.description + '. ',

                        'Their ' + qual.name + 
                                (if (qual.plural) ' are evidently ' else ' is evidently ') 
                            + qual.description + '. ',

                        'Their ' + qual.name + 
                                (if (qual.plural) ' are fairly ' else ' is fairly ') 
                            + qual.description + '. '
                    ])[index];
                };
                
                @:singleChoices = [0, 1, 2, 3, 4];
                @:dualChoices = [0, 1];
                
                @:pickDescriptionChoice::(list) {
                    @:index = random.integer(from:0, to:list->keycount-1);
                    @:out = list[index];
                    list->remove(key:index);
                    return out;
                };
                
                // when we pick descriptive sentences, we dont want to 
                // reuse structures more than once except for the unflourished 
                // one.
                [::] {
                    forever(do::{
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
                        };
                    });
                    
                };
                qualityDescription = out;
                return out;
            },
            
            describe:: {
                @:plainStats = StatSet.new();
                stats.resetMod();
                plainStats.add(stats);
                this.recalculateStats();

                @:modRate = StatSet.new();
                effects->foreach(do:::(index, effect) {
                    effect.effect.onStatRecalculate(user:effect.from, stats, holder:this, item:effect.item);
                    modRate.add(stats:effect.effect.stats);
                });

                equips->foreach(do:::(index, equip) {
                    when(index == EQUIP_SLOTS.HAND_R) empty;
                    modRate.add(stats:equip.equipMod);
                });
                

                plainStats.printDiff(other:stats, 
                    prompt:this.name + '(Base -> w/Mods.)'
                );
                
                windowEvent.queueMessageSet(
                    speaker: this.name,
                    pageAfter:canvas.height-4,
                    set: [ 
                          '       Name: ' + name + '\n\n' +
                          '         HP: ' + this.hp + ' / ' + this.stats.HP + '\n' + 
                          '         AP: ' + this.ap + ' / ' + this.stats.AP + '\n\n' + 
                          '    species: ' + species.name + '\n' +
                          ' profession: ' + profession.base.name + '\n' +
                          'personality: ' + personality.name + '\n\n'
                         ,
                         this.describeQualities()
                         ,
                         
                          ' -Equipment-  \n'                
                                + 'hand(l): ' + equips[EQUIP_SLOTS.HAND_L].name + '\n'
                                + 'hand(r): ' + equips[EQUIP_SLOTS.HAND_R].name + '\n'
                                + 'armor  : ' + equips[EQUIP_SLOTS.ARMOR].name + '\n'
                                + 'amulet : ' + equips[EQUIP_SLOTS.AMULET].name + '\n'
                                + 'trinket: ' + equips[EQUIP_SLOTS.TRINKET].name + '\n'
                                + 'ring(l): ' + equips[EQUIP_SLOTS.RING_L].name + '\n'
                                + 'ring(r): ' + equips[EQUIP_SLOTS.RING_R].name + '\n'
                         ,
                        
                          
                            ' - Stat Modifiers - \n' +
                            modRate.getRates()
                         ,
                          ::<= {
                            @out = ' - Effects - \n\n';
                            effects->foreach(do:::(index, effect) {
                                out = out + effect.effect.name + ': ' + effect.effect.description + '\n';
                            });
                            return out;
                         }
                     ]                                   
                );                     
                           
                
                
                


            }
            

        };
        
        
    }
);


return Entity;
