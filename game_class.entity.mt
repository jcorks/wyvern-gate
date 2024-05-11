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
@:Species = import(module:'game_database.species.mt');
@:Personality = import(module:'game_database.personality.mt');
@:Profession = import(module:'game_database.profession.mt');
@:NameGen = import(module:'game_singleton.namegen.mt');
@:Item = import(module:'game_mutator.item.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Arts = import(module:'game_database.arts.mt');
@:Effect = import(module:'game_database.effect.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:BattleAI = import(module:'game_class.battleai.mt');
@:StateFlags = import(module:'game_class.stateflags.mt');
@:random = import(module:'game_singleton.random.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:EntityQuality = import(module:'game_mutator.entityquality.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:ArtsDeck = import(module:'game_class.artsdeck.mt');
@:EffectStack = import(:'game_class.effectstack.mt');


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
        HP  : (if(random.flipCoin()) 1 else 0) + (stat(name:'HP')),
        AP  : (if(random.flipCoin()) 2 else 0) + (stat(name:'AP')),
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


@:outfitDeck ::(this, deck) {
    @:world = import(module:'game_singleton.world.mt');
    when(this.supportArts) ::<= {
        foreach(this.supportArts)::(k, v) {
            deck.addArt(id:v);
        }
    }
        
 


    // profession is expected to pick up the slack
    when (this.species.special == true) empty;
    
    // otherwise its default tier bs 
    match(world.island.tier) {
      (0, 1): ::<= {
        deck.addArt(id:'base:pebble');
        deck.addArt(id:'base:diversify');
        deck.addArt(id:'base:brace');            
        deck.addArt(id:'base:mind-games');
      },
      
      (2): ::<= {
        deck.addArt(id:'base:pebble');
        deck.addArt(id:'base:retaliate');
        deck.addArt(id:'base:diversify');
        deck.addArt(id:'base:brace');            
        deck.addArt(id:'base:mind-games');
        deck.addArt(id:'base:crossed-wires');
        deck.addArt(id:'base:recycle');          
      },
      
      (3): ::<= {
        deck.addArt(id:'base:pebble');
        deck.addArt(id:'base:retaliate');
        deck.addArt(id:'base:diversify');
        deck.addArt(id:'base:brace');            
        deck.addArt(id:'base:mind-games');
        deck.addArt(id:'base:crossed-wires');
        deck.addArt(id:'base:recycle');          
        deck.addArt(id:'base:cancel');    
      },

      (4): ::<= {
        deck.addArt(id:'base:pebble');
        deck.addArt(id:'base:retaliate');
        deck.addArt(id:'base:diversify');
        deck.addArt(id:'base:brace');            
        deck.addArt(id:'base:mind-games');
        deck.addArt(id:'base:crossed-wires');
        deck.addArt(id:'base:recycle');          
        deck.addArt(id:'base:cancel');    
        deck.addArt(id:'base:cancel');    
      }

      
    }
}

@:assembleDeck ::(this, state) {
    @:deck = ArtsDeck.new();
    

    // add weapon
    @:hand = state.equips[EQUIP_SLOTS.HAND_LR];
    if (hand != empty) ::<= {
        deck.addArt(id:hand.arts[0]);
        deck.addArt(id:hand.arts[1]);
    }    
    
    // profession boosts
    foreach(state.profession.arts) ::(k, v) {
        deck.addArt(id:v);
    }
    
    
    outfitDeck(deck, this);
    

    
    
    return deck;
}


@initializeEffectStackProper ::(this, state) {
    
    if (state.innateEffects != empty) ::<= {
        foreach(state.innateEffects) ::(i, v) {
            this.effectStack.addInnate(id:v);
        }
    }
    
    foreach(this.profession.passives)::(index, passiveName) {
        this.effectStack.addInnate(
            id:passiveName
        );
    }


    foreach(state.equips) ::(i, item) {
        when(item == empty) empty;
        foreach(item.equipEffects)::(index, effect) {
            this.effectStack.addInnate(
                id:effect,
                item
            );
        }
    }
}


@:EQUIP_SLOTS = {
    HAND_LR : 0,
    ARMOR : 1,
    AMULET : 2,
    RING_L : 3,
    RING_R : 4,
    TRINKET : 5
}

@:DAMAGE_TARGET = {
    HEAD : 1,
    BODY : 2,
    LIMBS : 4
};

@none;
@displayedHurt = {};




@:Entity = LoadableClass.createLight(
    name : 'Wyvern.Entity', 
    statics : {
        EQUIP_SLOTS : {get::<- EQUIP_SLOTS},
        DAMAGE_TARGET : {get::<- DAMAGE_TARGET},
        normalizedDamageTarget ::(blockPoints) {
            when(blockPoints == 1 || blockPoints == empty) ::<={
                @:rate = Number.random();
                when (rate <= 0.25) DAMAGE_TARGET.HEAD;
                when (rate <  0.75) DAMAGE_TARGET.BODY;
                return DAMAGE_TARGET.LIMBS
            };
            when(blockPoints >= 3)
                DAMAGE_TARGET.HEAD |
                DAMAGE_TARGET.BODY |
                DAMAGE_TARGET.LIMBS
            
            @:list = [
                DAMAGE_TARGET.HEAD,
                DAMAGE_TARGET.BODY,
                DAMAGE_TARGET.LIMBS
            ]
            
            return random.removeArrayItem(list) |
                   random.removeArrayItem(list)
        },
        
        displayedHurt : {
            get ::<- displayedHurt->keys()
        },
        
        isDisplayedHurt::(entity) {
            return displayedHurt[entity] == true;
        },
    },
    items : {
        worldID : 0,
        stats  : empty,
        hp  : 0,
        ap  : 0,
        flags  : empty,
        isDead  : false,
        name  : '',
        nickname  : '',
        species   : empty,
        personality   : empty,
        emotionalState  : empty,
        favoritePlace  : empty,
        favoriteItem : empty,
        growth : empty,
        qualityDescription : '',
        qualitiesHint : empty,
        faveWeapon : empty,
        adventurous : false,
        battleAI : empty,
        aiAbilityChance : 0,
        profession : empty,
        canMake : empty,
        forceDrop : empty,
        equips : empty,
        abilitiesLearned : empty,
        inventory : empty,
        expNext : 1,
        level : 0,
        modData : empty,
        deck : empty,
        supportArts : empty,
        innateEffects : empty
    },
    
    private : {
        effectStack : Nullable,
        battle : Nullable,
        overrideInteract : Nullable,
        requestsRemove : Boolean,
        onInteract : Function,
        enemies : Nullable,
        allies : Nullable,
        abilitiesUsedBattle : Nullable,
        owns : Nullable
    },
    
    
    interface : {
        initialize ::{
            if (none == empty) none = Item.new(base:Item.database.find(id:'base:none'));
            @:this = _.this;
            _.state.battleAI = BattleAI.new(user:this);                
        },
            
        
    
        defaultLoad::(island, speciesHint, professionHint, personalityHint, levelHint, adventurousHint, qualities, innateEffects, faveWeapon) {
            @:world = import(module:'game_singleton.world.mt');
            @:state = _.state;
            @:this = _.this;

            state.innateEffects = innateEffects;
            
            state.worldID = world.getNextID();
            state.stats = StatSet.new(
                HP:1,
                AP:1,
                ATK:1,
                DEX:1,
                INT:1,
                DEF:1,
                // LUK can be zero. some people are just unlucky!
                SPD:1    
            );

            @:Location = import(module:'game_mutator.location.mt');


            state.hp = 1;
            state.ap = 1;
            state.flags = StateFlags.new();
            state.isDead = false;
            state.name = NameGen.person();
            state.personality = Personality.getRandom();
            state.favoritePlace = Location.database.getRandom();
            state.growth = StatSet.new();
            state.adventurous = Number.random() <= 0.5;
            state.equips = [
                empty, // handl
                empty, // handr
                empty, // armor
                empty, // amulet
                empty, // ringl
                empty, // ringr
                empty
            ];
            state.abilitiesLearned = []; // abilities that can choose outside battle.
            
            state.expNext = 10;
            state.level = 0;
            state.modData = {};






            if (adventurousHint != empty)
                state.adventurous = adventurousHint;
            
            if (personalityHint != empty)
                state.personality = Personality.find(id:personalityHint);

            state.qualitiesHint = qualities;


            
            state.profession = if (professionHint == empty) 
                    Profession.getRandomFiltered(filter::(value) <- value.learnable) 
                else 
                    Profession.find(id:professionHint)



            if (speciesHint != empty) ::<= {
                state.species = Species.find(id:speciesHint);
            } else 
                error(detail: 'No species was specified when creating this entity. Please specify a species id!!!');

            
            state.growth.mod(stats:state.species.growth);
            state.growth.mod(stats:state.personality.growth);
            state.growth.mod(stats:state.profession.growth);
            for(0, levelHint)::(i) {
                this.autoLevel();                
            }
            state.inventory = Inventory.new(size:10);
            if (faveWeapon)
                state.faveWeapon = Item.database.find(id:faveWeapon);

            if (island != empty)  ::<= {
                state.inventory.add(item:
                    Item.new(
                        base: Item.database.getRandomFiltered(
                            filter:::(value) <- value.isUnique == false && value.canHaveEnchants
                                                        && value.tier <= island.tier
                        ),
                        rngEnchantHint:true
                    )
                );

                if (state.faveWeapon == empty)
                    state.faveWeapon = Item.database.getRandomFiltered(filter::(value) <- value.isUnique == false && (value.attributes & Item.database.statics.ATTRIBUTE.WEAPON) != 0 && value.tier <= island.tier)
            } else ::<= {
                if (state.faveWeapon == empty)
                    state.faveWeapon = Item.database.getRandomFiltered(filter::(value) <- value.isUnique == false && (value.attributes & Item.database.statics.ATTRIBUTE.WEAPON) != 0)
            }
            state.inventory.addGold(amount:(Number.random() * 100)->ceil);
            state.favoriteItem = Item.database.getRandomFiltered(filter::(value) <- value.isUnique == false)


            foreach(this.species.passives)::(index, passiveName) {
                this.effectStack.addInnate(id:passiveName);
            }


            /*
            ::<={
                [0, 1+(Number.random()*3)->floor]->for(do:::(i) {
                    @:item = Item.database.getRandomWeightedFiltered(
                        filter:::(value) <- level >= value.levelMinimum &&
                                            value.isUnique == false
                        
                    );
                    if (item.name != 'None') ::<={
                        @:itemInstance = item.new();
                        if (itemInstance.enchantsCount == 0) 
                            inventory.add(item:itemInstance);
                    }
                    
                    
                });
                
            }
            */

            return this;
        },     
        

        afterLoad :: {
            @:state = _.state;
            @:this = _.this;
            foreach(state.equips) ::(k, equip) {
                when(equip == empty) empty;
                equip.equippedBy = this;
            }
            state.battleAI.setUser(user:this);
        },

        worldID : {
            get ::<- _.state.worldID
        },
        
        // Called to indicate to the entity the 
        // start of a new turn in general.
        // This does things like reset stats according to 
        // effects and such.
        startTurn ::(allies, enemies) {
            _.allies = allies;
            _.enemies = enemies;
            _.this.recalculateStats();             
            _.this.flags.reset();
        },
        
        // called to signal that a battle has started involving this entity
        battleStart ::(battle) {
            @:state = _.state;
            @:this = _.this;
            _.battle = battle;
            _.requestsRemove = false;
            _.abilitiesUsedBattle = {}
            state.deck = assembleDeck(this, state);
            state.deck.shuffle();
            state.deck.redraw();
            _.effectStack = EffectStack.new(parent:this);
            initializeEffectStackProper(*_);

            //resetEffects(priv:_, this:_.this, state:_.state);              
        },
        
        battle : {
            get ::<- _.battle
        },
            
        owns : {
            get ::<- _.owns,
            set ::(value) <- _.owns = value
        },
        
        aiAbilityChance : {
            set ::(value) <- _.state.aiAbilityChance = value,
            get ::<- _.state.aiAbilityChance
        },
        
        deck : {
            get ::<- _.state.deck
        },
        
        
        supportArts : {
            get ::<- _.state.supportArts,
            set ::(value) <- _.state.supportArts = value
        },
            
        blockPoints : {
            get :: {
                @:this = _.this;
                @:state = _.state;
                when(this.isIncapacitated()) 0;
                @:am = ::<= {
                    @wep = this.getEquipped(slot:EQUIP_SLOTS.HAND_LR);
                    @amount = if (wep.base.id == 'base:none') 0 else wep.base.blockPoints;
                    
                    foreach(this.effectStack.getAll()) ::(index, f) {
                        @:effect = Effect.find(:f.id);
                        amount += effect.blockPoints
                    }
                    
                    return amount;
                }
                when (am < 0) 0;
                return am;
            }
        },
        
        assembleDeck ::{
            return assembleDeck(*_);
        },
        

        viewDeckArts ::(prompt) {
            @:state = _.state;
            @:this = _.this;

            @:choices = [];
            @:choiceActs = [];

            @:pushArt::(id){
                @art = Arts.find(:id);
                choices->push(:' ' + art.name);
                choiceActs->push(:id);
            }

            // add weapon
            @:hand = state.equips[EQUIP_SLOTS.HAND_LR];
            if (hand != empty) ::<= {
                choices->push(:'Weapon:');
                choiceActs->push(:empty);
                pushArt(id:hand.arts[0]);
                pushArt(id:hand.arts[1]);
            }    


            
            // profession boosts
            choices->push(:'Profession:');
            choiceActs->push(:empty);
            foreach(state.profession.arts) ::(k, v) {
                pushArt(id:v);
            }


            
            if (this.supportArts) ::<= {
                choices->push(:'Support:');
                choiceActs->push(:empty);
                foreach(this.supportArts)::(k, v) {
                    pushArt(id:v);
                }
            }            
        
        
            @which = 0;
            windowEvent.queueChoices(
                choices,
                prompt,
                leftWeight: 1,
                topWeight: 0.5,
                canCancel: true,
                renderable : {
                    render::{
                        when(choiceActs[which] == empty) empty;
                        ArtsDeck.renderArt(
                            handCard: ArtsDeck.synthesizeHandCard(id:choiceActs[which]),
                            topWeight: 0.5,
                            leftWeight: 0
                        );
                    }
                },
                onHover::(choice) {
                    which = choice-1
                },
                
                onChoice::(choice) {
                    which = choice-1;
                }
            );
        },        

        // called to signal that a battle has started involving this entity
        battleEnd :: {
            _.battle = empty;
            @:this = _.this;
            _.this.effectStack.clear(all:true);
            _.effectStack = empty;
            _.allies = empty;
            _.enemies = empty;
            _.abilitiesUsedBattle = empty;                
            
            _.state.deck = empty;
            
            _.this.recalculateStats();                                
        },

            
        recalculateStats :: {    
            @:this = _.this;
            @:state = _.state;
                    
            @oldHP = this.hp;
            @:oldHPmax = this.stats.HP;
            @oldAP = this.ap;
            @:oldAPmax = this.stats.AP;
            if (oldHP > oldHPmax) oldHP = oldHPmax;
            if (oldAP > oldAPmax) oldAP = oldAPmax;
            
            
            state.stats.resetMod();
            if (this.effectStack)
                this.effectStack.modStats(stats:state.stats);            
            @:hand = state.equips[EQUIP_SLOTS.HAND_LR];
            @weaponAffinity = false;
            if (hand != empty)
                weaponAffinity = 
                    (this.profession.weaponAffinity == hand.base.id) ||
                    (state.faveWeapon.id == hand.base.id)
                ;
            
            // flat bonus
            if (weaponAffinity) ::<= {
                state.stats.modRate(stats:StatSet.new(
                    ATK: 60,
                    DEF: 60,
                    SPD: 60,
                    INT: 60,
                    DEX: 60
                ))
            }
            
            foreach(state.equips)::(index, equip) {
                when(equip == empty) empty;
                state.stats.modRate(stats:equip.equipMod);
            }
            
            state.hp = (state.stats.HP * (oldHP / oldHPmax))->round
            state.ap = (state.stats.AP * (oldAP / oldAPmax))->round;
            
        },
            
        personality : {
            get ::<- _.state.personality
        },
            
        endTurn ::(battle) {
            @:state = _.state;
            @:this = _.this;
            @:equips = state.equips;
            foreach(EQUIP_SLOTS)::(str, i) {
                when(i == 0 && equips[0] == equips[1]) empty;
                when(equips[i] == empty) empty;
                equips[i].onTurnEnd(wielder:this, battle);
            }
        },

        // lets the entity know that their turn has come.            
        actTurn ::() => Boolean {
            @:state = _.state;
            @:this = _.this;
            
            state.deck.redraw();
            @act = true;
            
            this.effectStack.nextTurn();
            this.checkStatChanged();
            
            if (this.stats.SPD < 0) ::<= {
                windowEvent.queueMessage(text:this.name + ' cannot move! (negative speed)');
                act = false;
            }

            if (this.stats.DEX < 0) ::<= {
                windowEvent.queueMessage(text:this.name + ' fumbles about! (negative dexterity)');
                act = false;
            }

            if (act == false)
                this.flags.add(flag:StateFlags.SKIPPED);
            return act;
        },

            
        flags : {
            get :: {
                return _.state.flags;
            }
        },
            
        name : {
            get :: {
                when (_.state.nickname != '') _.state.nickname;
                return _.state.name;
            },
            
            set ::(value => String) {
                _.state.name = value;
            }
        },
            
        species : {
            get :: {
                return _.state.species;
            }, 
            
            set ::(value) {
                _.state.species = value;
            }
        },

        requestsRemove : {
            get ::<- _.requestsRemove,
            set ::(value) <- _.requestsRemove = value
        },

        favoriteItem : {
            get ::<- _.state.favoriteItem
        },

        profession : {
            get :: {
                return _.state.profession;
            },
            
            set ::(value) {
                @:state = _.state;
                @:this = _.this;
                if (this.effectStack) ::<= {
                    foreach(this.profession.passives)::(index, passiveName) {
                        this.effectStack.removeInnate(
                            id:passiveName
                        );
                    }
                }

                state.profession = value;

                if (this.effectStack) ::<= {
                    foreach(this.profession.passives)::(index, passiveName) {
                        this.effectStack.addInnate(
                            id:passiveName
                        );
                    }                
                }
                state.growth.resetMod();
                state.growth.mod(stats:state.species.growth);
                state.growth.mod(stats:state.personality.growth);
                state.growth.mod(stats:state.profession.growth);
            
            
            }
        },
            
        nickname : {
            set ::(value) {
                _.state.nickname = value;
            }
        },
            
        renderHP ::(length, x) {
            return canvas.renderBarAsString(width:length, fillFraction:_.state.hp / _.state.stats.HP);
        },
            
        level : {
            get ::{
                return _.state.level;
            }
        },
            
        effectStack : {
            get ::<- _.effectStack
        },
        
        overrideInteract : {
            set ::(value) {
                _.overrideInteract = value;
            }
        },
            
            
        attack::(
            amount => Number,
            damageType => Number,
            damageClass => Number,
            target => Object,
            targetPart,
            targetDefendPart
        ){
            @:this = _.this;
            @:state = _.state;
        
            displayedHurt[target] = true;
            if (targetPart == empty) targetPart = Entity.normalizedDamageTarget();
            if (targetDefendPart == empty) targetPart = Entity.normalizedDamageTarget();
        
            @:hasNoEffectStack = _.effectStack == empty;
        
            @:effectStack = if (hasNoEffectStack) EffectStack.new() else _.this.effectStack;
            @:retval = ::<= {
                @:dmg = Damage.new(
                    amount,
                    damageType,
                    damageClass
                );
                
                @:damaged = [];
                // TODO: add weapon affinities if phys and equip weapon
                // phys is always assumed to be with equipped weapon
                effectStack.emitEvent(
                    name: 'onPreAttackOther',
                    to : target, 
                    damage : dmg,
                    emitCondition ::(effectInstance) <- dmg.amount > 0
                );
                
                when(dmg.amount <= 0) empty;

                if (target.effectStack)
                    target.effectStack.emitEvent(
                        name: 'onAttacked',
                        attacker : this, 
                        damage : dmg,
                        emitCondition ::(effectInstance) <- dmg.amount > 0
                    );
                

                when(dmg.amount <= 0) empty;


                @critChance = 0.999 - (this.stats.LUK/1.2) / 100;
                @isCrit = false;
                @isHitHead = false;
                @isLimbHit = false;
                @isHitBody = false;
                
                @missHead = false;
                @missBody = false;
                @missLimb = false;
                if (critChance < 0.75) critChance = 0.75;
                if (Number.random() > critChance || dmg.forceCrit) ::<={
                    dmg.amount += this.stats.DEX * 1.5;
                    isCrit = true;
                }


                @backupStats;
                @:which = match(targetPart) {
                  (Entity.DAMAGE_TARGET.HEAD): 'head',
                  (Entity.DAMAGE_TARGET.BODY): 'body',
                  (Entity.DAMAGE_TARGET.LIMBS): 'limbs'
                }
                @imperfectGuard = false;

                if (targetPart != empty) ::<= {
                    if (targetDefendPart == empty)
                        targetDefendPart = 0;
                    if (target.species.canBlock == false)
                        targetDefendPart = 0;
                    if (target.isIncapacitated())
                        targetDefendPart = 0;
                        
                        
                    if (targetDefendPart == 0 && target.species.canBlock == true && target.isIncapacitated() == false) 
                        windowEvent.queueMessage(text: target.name + ' wasn\'t given a chance to block!');

                    if ((targetPart & targetDefendPart) != 0) ::<= {
                    
                        // Cant defend EVERYTHING perfectly. If you guard multiple parts of 
                        // your body, even with gear, you still arent a perfect fortress
                        imperfectGuard = (targetDefendPart != Entity.DAMAGE_TARGET.HEAD &&
                                          targetDefendPart != Entity.DAMAGE_TARGET.BODY &&
                                          targetDefendPart != Entity.DAMAGE_TARGET.LIMBS &&
                                          random.flipCoin());
                        this.flags.add(flag:StateFlags.BLOCKED_ATTACK);
                        
                        if (!imperfectGuard) ::<= {
                            windowEvent.queueMessage(
                                text: target.name + ' predicted ' + this.name + '\'s attack to their ' + which + ' and successfully blocked it!'
                            );
                            
                            target.effectStack.emitEvent(
                                name : 'onSuccessfulBlock',
                                attacker: this,
                                damage: dmg
                            );
                            dmg.amount = 0;
                        } else ::<= {
                            dmg.amount *= .4;
                        }
                        
                    } else ::<= {
     


                        backupStats = this.stats.save();
                        match(true) {
                          ((targetPart & DAMAGE_TARGET.HEAD) != 0):::<= {
                            if (random.try(percentSuccess:15)) ::<= {
                                if (random.try(percentSuccess:90)) ::<= {
                                    isCrit = true;
                                    dmg.amount += this.stats.DEX * 1.5;
                                } else
                                    dmg.amount *= 1.4;
                                isHitHead = true;
                            } else ::<= {
                                missHead = true;
                                dmg.amount *= 0.1;
                            }
                          },

                          ((targetPart & DAMAGE_TARGET.BODY) != 0):::<= {
                            dmg.amount *= 1.3;                           
                            isHitBody = true;   
                          },

                          ((targetPart & DAMAGE_TARGET.LIMBS) != 0):::<= {
                            if (random.try(percentSuccess:45)) ::<= {
                                isLimbHit = true;
                            } else ::<= {
                                missLimb = true;
                                dmg.amount *= 0.1;
                            }
                          }

                        }
                    }
                }
                when(dmg.amount <= 0) empty;



                @:hpWas0 = if (target.hp == 0) true else false;
                @:result = target.damage(attacker:this, damage:dmg, dodgeable:true, critical:isCrit);
                
                if (backupStats != empty)
                    this.stats.load(serialized:backupStats);
                
                if (imperfectGuard) ::<= {
                    if (result)
                        windowEvent.queueMessage(
                            text: target.name + ' predicted ' + this.name + '\'s attack to their ' + which + ', but wasn\'t able to fully block the damage!'
                        )
                    else                
                        windowEvent.queueMessage(
                            text: target.name + ' predicted ' + this.name + '\'s attack to their ' + which + '!'
                        );

                }
                
                when(!result) empty;

                if (!imperfectGuard) ::<= {
                    if (isLimbHit) ::<= {
                        windowEvent.queueMessage(text: 'The hit caused direct damage to the limbs!');
                        if (!target.isIncapacitated())
                            target.addEffect(from:this, id:'base:stunned', durationTurns:1);                    
                    }

                    if (isHitBody) ::<= {
                        windowEvent.queueMessage(text: 'The hit caused direct damage to the body!');
                    }

                    
                    if (isHitHead) ::<= {
                        windowEvent.queueMessage(text: 'The hit caused direct damage to the head!');
                    }
                    
                    
                    if (missHead) ::<= {
                        windowEvent.queueMessage(text: 'The hit missed the head, but still managed to hit ' + target.name +'!');                        
                    }
                    if (missLimb) ::<= {
                        windowEvent.queueMessage(text: 'The hit missed the limbs, but still managed to hit ' + target.name +'!');                        
                    }

                }
                this.flags.add(flag:StateFlags.ATTACKED);




                effectStack.emitEvent(
                    name : 'onPostAttackOther',
                    to: target
                );

                when(hpWas0 && target.hp == 0) ::<= {
                    this.flags.add(flag:StateFlags.DEFEATED_ENEMY);
                    target.flags.add(flag:StateFlags.DIED);
                    target.kill(from:this);                
                }

                return true;
            }
            
            if (hasNoEffectStack)                
                _.this.effectStack.clear(all:true);
            if (hasNoEffectStack)                
                _.effectStack = empty;


            windowEvent.queueCustom(
                onEnter :: {
                    displayedHurt->remove(key:target);
                }
            );
            return retval;
        },
            
        damage ::(attacker => Object, damage => Object, dodgeable => Boolean, critical, exact) {
            @:this = _.this;
            @:state = _.state;
            
            @:alreadyKnockedOut = this.hp == 0;
            if (alreadyKnockedOut)
                dodgeable = false;
                
            if (attacker == this)
                dodgeable = false;
                
                
            @:hasNoEffectStack = _.effectStack == empty;
            
            if (hasNoEffectStack)
                _.effectStack = EffectStack.new();


                
            @:retval = ::<= {

                when(state.isDead) false;
                @originalAmount = damage.amount;


                // flat 15% chance to avoid damage with a shield 
                // pretty nifty!
                /*
                when (dodgeable && 
                      (this.getEquipped(slot:EQUIP_SLOTS.HAND_LR).base.attributes & Item.database.statics.ATTRIBUTE.SHIELD) && 
                      random.try(percentSuccess:15)) ::<= {
                    windowEvent.queueMessage(text:random.pickArrayItem(list:[
                        this.name + ' defends against ' + from.name + '\'s attack with their shield!',                 
                    ]));
                    this.flags.add(flag:StateFlags.DODGED_ATTACK);
                    return false;                                                            
                }*/
                
                // flat 15% chance if is Wyvern! because hard
                when(dodgeable && this.species.name->contains(key:'Wyvern of') && random.try(percentSuccess:15)) ::<= {
                    windowEvent.queueMessage(text:random.pickArrayItem(list:[
                        'You will have to try harder than that, Chosen!',
                        'Come at me; do not hold back, Chosen!',
                        'You disrespect me with such a weak attack, Chosen!',
                        'Nice try, but it is not enough!'
                    ]));
                    windowEvent.queueMessage(text:this.name + ' deflected the attack!');
                    this.flags.add(flag:StateFlags.DODGED_ATTACK);
                    return false;                                                                                
                }
                


                if (attacker.stats.DEX > this.stats.DEX)               
                    // as DEX increases: randomness decreases 
                    // amount of reliable damage increases
                    // This models user skill vs receiver skill
                    damage.amount = damage.amount + damage.amount * ((Number.random() - 0.5) * (this.stats.DEX / attacker.stats.DEX) + (1 -  this.stats.DEX / attacker.stats.DEX))
                else
                    damage.amount = damage.amount + damage.amount * (Number.random() - 0.5)
                ; 
                
                


                damage.amount -= state.stats.DEF/3;
                if (damage.amount <= 0) damage.amount = 1;


                this.effectStack.emitEvent(
                    name : 'onDamage',
                    attacker,
                    damage,
                    emitCondition ::(v) <- (damage.amount > 0 || exact != empty)
                );

                if (exact)
                    damage.amount = originalAmount;

                when (damage.amount == 0) false;

                
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
                
                damage.amount = (damage.amount)->ceil
                
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
                
                if (damage.damageType == Damage.TYPE.FIRE && Number.random() > 0.98)
                    this.addEffect(from:attacker, id:'base:burned',durationTurns:5);
                if (damage.damageType == Damage.TYPE.ICE && Number.random() > 0.98)
                    this.addEffect(from:attacker, id:'base:frozen',durationTurns:2);
                if (damage.damageType == Damage.TYPE.THUNDER && Number.random() > 0.98)
                    this.addEffect(from:attacker, id:'base:paralyzed',durationTurns:2);
                if (damage.damageType == Damage.TYPE.PHYS && Number.random() > 0.99) 
                    this.addEffect(from:attacker, id:'base:bleeding',durationTurns:5);
                if (damage.damageType == Damage.TYPE.POISON && Number.random() > 0.98) 
                    this.addEffect(from:attacker, id:'base:poisoned',durationTurns:5);
                if (damage.damageType == Damage.TYPE.DARK && Number.random() > 0.98)
                    this.addEffect(from:attacker, id:'base:blind',durationTurns:2);
                if (damage.damageType == Damage.TYPE.LIGHT && Number.random() > 0.98)
                    this.addEffect(from:attacker, id:'base:petrified',durationTurns:2);
                
                
                if (!alreadyKnockedOut && world.party.isMember(entity:this) && state.hp == 0 && Number.random() > 0.7 && world.party.members->size > 1) ::<= {
                    windowEvent.queueMessage(
                        speaker: this.name,
                        text: '"' + random.pickArrayItem(list:state.personality.phrases[Personality.SPEECH_EVENT.DEATH]) + '"'
                    );
                }
                
                if (!alreadyKnockedOut && state.hp == 0) ::<= {
                    if (this.name->contains(key:'Wyvern'))
                        windowEvent.queueMessage(text: '' + this.name + ' is no longer able to fight.')                               
                    else
                        windowEvent.queueMessage(text: '' + this.name + ' has been knocked out.');                                

                    if (!world.party.isMember(entity:this))
                        world.accoladeIncrement(name:'knockouts');                                        

                    this.flags.add(flag:StateFlags.FALLEN);
                    attacker.flags.add(flag:StateFlags.DEFEATED_ENEMY);
                }

                return true;
            }
            if (hasNoEffectStack)
                this.effectStack.clear(all:true);
            if (hasNoEffectStack)
                _.effectStack = empty;
                

            return retval;
        },
            
        // where they roam to in their freetime. if places doesnt have one they stay home
        favoritePlace : {
            get ::<- _.state.favoritePlace
        },
        
        forceDrop : {
            get ::<- _.state.forceDrop,
            set ::(value) <- _.state.forceDrop = value
        },
        
        heal ::(amount => Number, silent) {
            @:state = _.state;
            @:this = _.this;
            
            if (state.hp > state.stats.HP) state.hp = state.stats.HP;
            when(state.hp >= state.stats.HP) empty;
            amount = amount->ceil;
            state.hp += amount;
            this.flags.add(flag:StateFlags.HEALED);
            if (state.hp > state.stats.HP) state.hp = state.stats.HP;
            if (silent == empty)
                windowEvent.queueMessage(text: '' + this.name + ' heals ' + amount + ' HP (HP:' + this.renderHP() + ')');
        },
            
        getCanMake ::{
            @:state = _.state;
            @:this = _.this;
            when(state.canMake) state.canMake;

            // was thinking about making this specific to blacksmiths, but 
            // i dunno people can have hobbies and learn how to make stuff, thats cool

            state.canMake = [];
            foreach(Item.database.getRandomSet(
                    count:if (this.profession.id == 'base:blacksmith') 10 else 2,
                    filter::(value) <- value.hasMaterial == true
            )) ::(k, val) {
                state.canMake->push(value:val.id);
            }

            return state.canMake;
        },
        
        healAP ::(amount => Number, silent) {
            @:state = _.state;
            @:this = _.this;
            amount = amount->ceil;
            state.ap += amount;
            if (state.ap > state.stats.AP) state.ap = state.stats.AP;
            if (silent == empty)
                windowEvent.queueMessage(text: '' + this.name + ' heals ' + amount + ' AP (AP:' + state.ap + '/' + state.stats.AP + ')');
            
            
        },
            
            
        isIncapacitated :: {
            return _.state.hp <= 0;
        },
            
        isDead : {
            get :: {
                return _.state.isDead;
            }   
        },
            
        gainExp ::(amount => Number, chooseStat, afterLevel) {
            @:state = _.state;
            @:this = _.this;
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
                return _.state.stats;
            }
        },

        capHP ::(max) {
            @:state = _.state;
            @stats = state.stats.save();
            if (stats.HP > max) stats.HP = max;
            state.stats.load(serialized:stats);   
            if (state.hp > stats.HP) state.hp = stats.HP;             
        },

        normalizeStats ::(min, max, maxHP) {
            @:state = _.state;
            @:this = _.this;
            if (min == empty) min = 3;
            if (max == empty) max = 10;
            if (maxHP == empty) maxHP = 12;
        
            @aMin = 9999999;
            @aMax =-9999999;
            @stats = state.stats.save();
            foreach(StatSet.NAMES) ::(index, name) {
                when(name == 'HP' || name == 'AP') empty;
                @val = stats[name];
                if (val < aMin) aMin = val;
                if (val > aMax) aMax = val;
            }

            foreach(StatSet.NAMES) ::(index, name) {
                when(name == 'HP' || name == 'AP') empty;
                @val = stats[name];
                stats[name] = (((val - aMin) / (aMax - aMin)) * (max - min) + min)->floor;
            }
            
            if (stats.HP > maxHP)
                stats.HP = maxHP;
            
            state.stats.load(serialized:stats);
            if (state.hp > maxHP)
                state.hp = maxHP;
        },
            
        autoLevel :: {
            _.this.gainExp(amount:_.state.expNext);  
        },
            
        dropExp :: {
            @:state = _.state;
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
                return _.state.adventurous;
            }
        },
            
        // per-entity data for mods
        modData : {
            get ::<- _.state.modData
        },
            
        kill ::(silent, from) {
            @:world = import(module:'game_singleton.world.mt');
            @:state = _.state;
            @:this = _.this;
            state.hp = 0;
            if (silent == empty)
                if (this.name->contains(key:'Wyvern'))
                    windowEvent.queueMessage(text: '' + this.name + ' has been defeated!')            
                else 
                    windowEvent.queueMessage(text: '' + this.name + ' has died!');                


            // basically if anyone dies its a bad time
            if (world.party.isMember(entity:this))
                world.accoladeIncrement(name:'deadPartyMembers')
            else ::<= {
                if (from != empty && world.party.isMember(entity:from)) ::<= {
                    world.accoladeIncrement(name:'murders');                                        
                    world.party.karma -= 1000;
                }
            }

            state.flags.add(flag:StateFlags.DIED);
            state.isDead = true;                
        },
        
        addEffect::(from => Object, id => String, durationTurns => Number, item) {
            @:state = _.state;
            @:this = _.this;
            
            if (_.battle == empty)
                _.effectStack = EffectStack.new(parent:this);
                
            this.effectStack.add(
                from,
                id,
                duration: durationTurns,
                item
            );
            this.checkStatChanged();
            
            if (_.battle == empty)
                this.effectStack.clear(all:true);
            if (_.battle == empty)
                _.effectStack = empty;

        },
            
            
        removeEffects::(effectBases => Object) {
            @:state = _.state;
            @:this = _.this;
            
            @:table = {};
            foreach(effectBases) ::(i, id) {
                table[id] = true;
            }
            
            this.effectStack.removeByFilter(::(value) <- table[value.id] == true);
            this.checkStatChanged();
        },

        removeEffectInstance::(instance => Object) {
            @:state = _.state;
            @:this = _.this;
            this.effectStack.removeByFilter(::(value) <- value == instance);
            this.checkStatChanged();
        },
        
        checkStatChanged::(instance) {
            @:state = _.state;
            @:this = _.this;

            @:oldStats = StatSet.new();
            oldStats.load(serialized:this.stats.save());
            this.recalculateStats();
            if (StatSet.isDifferent(stats:oldStats, other:this.stats)) ::<= {
                windowEvent.queueDisplay(
                    prompt: this.name + ': stats changed!',
                    lines: StatSet.diffToLines(
                        stats:oldStats,
                        other:this.stats
                    )
                );
            }
        },

        
        hp : {
            set ::(value) <- _.state.hp = value,
            get :: {
                return _.state.hp;
            }
        },
            
        ap : {
            set ::(value) <- _.state.ap = value,
            get :: {
                return _.state.ap;
            }
        },
            
        rest :: {
            @:state = _.state;
            state.hp = state.stats.HP;
            state.ap = state.stats.AP;
        },
            
        inventory : {
            get :: {
                return _.state.inventory;
            }
        },
            
        battleAI : {
            get ::<- _.state.battleAI
        },
            
        equip ::(item => Item.type, slot, silent, inventory) {
            @:state = _.state;
            @:this = _.this;
            this.recalculateStats();
            @:oldstats = StatSet.new();
            oldstats.add(stats: this.stats);

            @olditem = state.equips[slot];
            if (item.base.id == 'base:none')
                error(detail:'Can\'t equip the None item. Unequip instead.');
    
            when (this.getSlotsForItem(item)->findIndex(value:slot) == -1) ::<= {
                when(silent) empty;
                error(detail:'Item does not enter the given slot.');
            }



            @:old = this.unequip(slot, silent:true);                



            if (item.base.equipType == Item.database.statics.TYPE.TWOHANDED) ::<={
                state.equips[EQUIP_SLOTS.HAND_LR] = item;
            } else ::<= {
                state.equips[slot] = item;
            }
            
            if (silent != true) ::<= {
                if ((slot == EQUIP_SLOTS.HAND_LR) && this.profession.weaponAffinity == state.equips[EQUIP_SLOTS.HAND_LR].base.id) ::<= {
                    if (silent != true) ::<= {
                        windowEvent.queueMessage(
                            speaker: this.name,
                            text: '"This ' + item.base.name + ' really works for me as ' + correctA(word:this.profession.name) + '"'
                        );
                    }
                } else if ((slot == EQUIP_SLOTS.HAND_LR) && state.faveWeapon.id == state.equips[EQUIP_SLOTS.HAND_LR].base.id) ::<= {
                    if (silent != true) ::<= {
                        windowEvent.queueMessage(
                            speaker: this.name,
                            text: '"This ' + item.base.name + ' is my favorite kind of weapon!"'
                        );
                    }                
                }                
            }
            
            item.equippedBy = this;
            
            if (_.effectStack) ::<= {
                foreach(item.equipEffects)::(index, effect) {
                    this.effectStack.addInnate(
                        id:effect,
                        item
                    );
                }
            }



            if (inventory)
                inventory.remove(item);

            if (olditem != empty && inventory)
                inventory.add(item:olditem);

            
            this.recalculateStats();

            
            if (silent != true) ::<={
                if (olditem == empty || olditem.base.id == 'base:none') ::<= {
                    windowEvent.queueMessage(text:this.name + ' has equipped the ' + item.name + '.');                    
                } else ::<= {
                    windowEvent.queueMessage(text:this.name + ' unequipped the ' + olditem.name + ' and equipped the ' + item.name + '.');                    
                }
                oldstats.printDiff(prompt: '(Equipped: ' + item.name + ')', other:this.stats);
            }
        },
        anonymize :: {
            @:this = _.this;
            this.nickname = 'the ' + this.species.name + (if(this.profession.id == 'base:none') '' else ' ' + this.profession.name);            
        },
            
        getEquipped::(slot => Number) {
            @:eq = _.state.equips[slot];
            when(eq == empty) none;
            return eq;
        },

        isEquipped::(item) {
            return _.state.equips->any(func::(value) <- value == item);
        },
            
        // returns an array of equip slots that the item can fit in.
        getSlotsForItem ::(item => Item.type) {
            return match(item.base.equipType) {
                (Item.database.statics.TYPE.HAND)     :  [EQUIP_SLOTS.HAND_LR],
                (Item.database.statics.TYPE.ARMOR)    :  [EQUIP_SLOTS.ARMOR],
                (Item.database.statics.TYPE.AMULET)   :  [EQUIP_SLOTS.AMULET],
                (Item.database.statics.TYPE.RING)     :  [EQUIP_SLOTS.RING_L, EQUIP_SLOTS.RING_R],
                (Item.database.statics.TYPE.TRINKET)  :  [EQUIP_SLOTS.TRINKET],
                (Item.database.statics.TYPE.TWOHANDED):  [EQUIP_SLOTS.HAND_LR],
                default: error(detail:'Item has an invalid equiptype?')      
            }
        },
            
        unequip ::(slot => Number, silent) {
            @:state = _.state;
            @:this = _.this;
            @:current = state.equips[slot];
            when (current == empty) empty;
            state.equips[slot] = empty;                
            
            current.equippedBy = empty;


            if (_.effectStack) ::<= {
                foreach(current.equipEffects) ::(i, id) {
                    this.effectStack.removeInnate(
                        item: current,
                        id
                    );
                }
            }

            /*
            if (effects != empty) ::<= {
                foreach(current.equipEffects)::(i, effect) {
                    @:effectObj = effects->filter(by:::(value) <- value.effect.id == effect)[0];
                    effectObj.effect.onRemoveEffect(
                        user:effectObj.from, 
                        holder:this,
                        item:effectObj.item
                    );
                    
                    effects->remove(key:effects->findIndex(value:effectObj));
                }
            }*/
            
            this.recalculateStats();
            return current;
        },
        unequipItem ::(item => Item.type, silent) {
            @:state = _.state;
            @:this = _.this;
            @slotOut;
            foreach(state.equips)::(slot, equip) {
                if (equip == item) ::<= {
                    this.unequip(slot, silent);
                    slotOut = slot;
                }
            }
            return slotOut;
        },
            
        useArt::(art, level, targets, turnIndex, targetDefendParts, targetParts, extraData) {
            @:state = _.state;
            @:this = _.this;
            @:abilitiesUsedBattle = _.abilitiesUsedBattle;
            
            when (abilitiesUsedBattle != empty && art.oncePerBattle && abilitiesUsedBattle[art.id] == true) windowEvent.queueMessage(
                text: this.name + " tried to use " + art.name + ", but it worked the first time!"
            );
            if (abilitiesUsedBattle) abilitiesUsedBattle[art.id] = true;
            
            return art.onAction(
                user:this,
                level,
                targets, turnIndex, targetDefendParts, targetParts, extraData          
            );            
        },

        discardArt:: {
            if (_.state.deck == empty)
                error(detail: 'Can\'t discard when not in battle.');
                
            @:this = _.this;
            @:deck = _.state.deck;
            @:world = import(module:'game_singleton.world.mt');
            if (world.party.leader == _.this)
                deck.discardPlayer()
            else ::<= {
                windowEvent.queueMessage(
                    text: this.name + ' discards an Art.'
                );
                deck.discardRandom()                
            }
        },
        
        react::(source, onReact) {
            if (_.state.deck == empty)
                error(detail: 'Can\'t react when not in battle.');
            @:priv = _;
            @:this = _.this;
            @:state = _.state;
            @:deck = state.deck;
            @:world = import(module:'game_singleton.world.mt');

            if (world.party.leader == this) ::<= {
                windowEvent.queueMessage(
                    text: '' + this.name + ' is able to react to this Art. You can either choose a Reaction Art or cancel to pass.'
                );
                deck.chooseArtPlayer(
                    act: 'React',
                    canCancel: true,
                    filter::(value) <- Arts.find(:value.id).kind == Arts.KIND.REACTION,
                    onChoice::(
                        card,
                        backout
                    ) {
                        onReact(:card)
                        backout();
                    },
                    
                    onCancel ::{
                        onReact();
                    }
                )
            } else ::<= {
                @card = state.battleAI.chooseReaction(
                    source,
                    battle:priv.battle,
                    allies:priv.allies,
                    enemies: priv.enemies
                );
                
                onReact(:card);
            }
        },
        
        drawArt ::(count) {
            if (_.state.deck == empty)
                error(detail: 'Can\'t draw when not in battle.');
                
            @:this = _.this;
            @:deck = _.state.deck;
            @:world = import(module:'game_singleton.world.mt');
            windowEvent.queueMessage(
                text: this.name + ' draws ' + (if (count == empty) 'an Art card.' else ''+count+' Art cards.')
            );
            for(0, if (count == empty) 1 else count) ::(i) {
                deck.draw()                
            }
        
        },
            
        // interacts with this entity
        interactPerson ::(party, location, onDone, overrideChat, skipIntro) {
            when(_.overrideInteract) _.overrideInteract(party, location, onDone);
            @:this = _.this;
            
            (import(module:'game_function.interactperson.mt'))(
                this, party, location, onDone, overrideChat, skipIntro
            );
        },
            
        // dummy for map
        discovered : {
            get ::<- true
        },
            
        allies : {
            get ::<- _.allies
        },

        enemies : {
            get ::<- _.enemies
        },
        
        // when set, this overrides the default interaction menu
        onInteract : {
            set ::(value) {
                _.onInteract = value;
            },
            get :: <- _.onInteract
        },
            
        describeQualities ::{
            @:state = _.state;
            @:this = _.this;
            when (state.qualityDescription != '') state.qualityDescription;
            
            @qualities = state.qualitiesHint;
            
            if (qualities == empty) ::<= {
                qualities = [];
                foreach(state.species.qualities)::(i, qual) {
                    @:q = EntityQuality.database.find(id:qual);
                    if (q.appearanceChance == 1 || Number.random() < q.appearanceChance)
                        qualities->push(value:EntityQuality.new(base:q));
                }
            }
        
            @out = this.name + ' is ' + correctA(word:state.species.name) + '. ';
            @:quals = random.scrambled(list:qualities);

            // inefficient, but idc                
            @:describeDual::(qual0, qual1, index) {
                return random.pickArrayItem(list:[
                    'They have ' + qual0.name + 
                            (if (qual0.plural) ' that are ' else ' that is ') 
                        + qual0.description + ', and their '
                        + qual1.name + 
                            (if (qual1.plural) ' are ' else ' is ') 
                        + qual1.description + '. ',

                    'They have ' + qual0.name + 
                            (if (qual0.plural) ' that are ' else ' that is ') 
                        + qual0.description + ', and their '
                        + qual1.name + 
                            (if (qual1.plural) ' are ' else ' is ') 
                        + qual1.description + '. ',

                        
                    this.name + '\'s ' + qual0.name + 
                            (if (qual0.plural) ' are ' else ' is ') 
                        + qual0.description + ', and they have '
                        + (if (qual1.plural == false) correctA(word:qual1.name) else qual1.name) + 
                            (if (qual1.plural) ' which are ' else ' which is ') 
                        + qual1.description + '. ',
                ]);
            }

            @:describeSingle::(qual, index) {
                return random.pickArrayItem(list:[
                    this.name + '\'s ' + qual.name + 
                            (if (qual.plural) ' are ' else ' is ') 
                        + qual.description + '. ',

                    'Their ' + qual.name + 
                            (if (qual.plural) ' are ' else ' is ') 
                        + qual.description + '. ',                            

                    'Their ' + qual.name + 
                            (if (qual.plural) ' are ' else ' is ') 
                        + qual.description + '. '     
                ]);
            }
            
            
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
                                                       
                        out = out + describeDual(qual0, qual1);
                    } else ::<= {
                        @qual = quals->pop;
                        
                        out = out + describeSingle(qual);                        
                    }
                }
                
            }
            state.qualityDescription = out;
            return out;
        },
            
        describe::(excludeStats)  {
            @:state = _.state;
            @:this = _.this;
            @:plainStatsState = this.stats.save();
            @:plainStats = StatSet.new();
            plainStats.load(serialized:plainStatsState);
            plainStats.resetMod();


            if (excludeStats != true)
                plainStats.printDiff(other:state.stats, 
                    prompt:this.name + '(Base -> w/Mods.)'
                );
            
            @:getRightHandName ::{
                @:hand = this.getEquipped(slot:EQUIP_SLOTS.HAND_LR);
                return 
                    if (hand.base.id == "base:none")
                        ""
                    else
                        hand.name 
                ;
            }
            
            @:effects = if (_.this.effectStack) _.this.effectStack.getAll() else empty;
            windowEvent.queueMessageSet(
                speaker: this.name,
                pageAfter:canvas.height-4,
                set: [ 
                      '       Name: ' + this.name + '\n\n' +
                      '         HP: ' + this.hp + ' / ' + this.stats.HP + '\n' + 
                      '         AP: ' + this.ap + ' / ' + this.stats.AP + '\n\n' + 
                      '    species: ' + state.species.name + '\n' +
                      ' profession: ' + this.profession.name + '\n' +
                      ' fave. wep.: ' + state.faveWeapon.name + '\n' +
                      'personality: ' + state.personality.name + '\n\n'
                     ,
                     this.describeQualities()
                     ,
                     
                      ' -Equipment-  \n'                
                            + 'hand(l): ' + this.getEquipped(slot:EQUIP_SLOTS.HAND_LR).name + '\n'
                            + 'hand(r): ' + getRightHandName() + '\n'
                            + 'armor  : ' + this.getEquipped(slot:EQUIP_SLOTS.ARMOR).name + '\n'
                            + 'amulet : ' + this.getEquipped(slot:EQUIP_SLOTS.AMULET).name + '\n'
                            + 'trinket: ' + this.getEquipped(slot:EQUIP_SLOTS.TRINKET).name + '\n'
                            + 'ring(l): ' + this.getEquipped(slot:EQUIP_SLOTS.RING_L).name + '\n'
                            + 'ring(r): ' + this.getEquipped(slot:EQUIP_SLOTS.RING_R).name + '\n'
                     ,
                      
                     if (effects != empty) ::<= {
                        @out = ' - Effects - \n\n';
                        foreach(effects)::(index, f) {
                            @:effect = Effect.find(:f.id);
                            out = out + effect.name + ': ' + effect.description + '\n';
                        }
                        return out;
                     } else ::<= {
                        return '';                         
                     }
                     
                 ]                                   
            );                     
        }
    }
);


return Entity;
