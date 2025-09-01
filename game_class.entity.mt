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
@:BattleAction = import(:'game_struct.battleaction.mt');
@:displayHP = import(:'game_function.displayhp.mt');
@:animateBar = import(:'game_function.animatebar.mt');


@:MIN_SUPPORT_COUNT = 5;
@:DAMAGE_RNG_SPREAD = 0.3;
@:PROF_EXP_PER_KNOCKOUT = 35;
@:DECK_MIN_ART_COUNT = 25;
@:FEELING_TYPE = {
  PERSON : 1,
  ITEM : 2,
  PLACE : 3
}
@:STARSIGN_NAMES = [
  "The Guide",
  "The Flame",
  "The Column",
  "The Crystal",
  "The Soul",
  "The Vessel",
  "The Obelisk",
  "The Omen"
]




@:getFeelings = ::<= {

  @:feelings = [
    // negative
    [
      // statements
      [
        '"I\'m not sure about this..."',
        '"I don\'t feel very good."',
        '"What was that?"',
        '"Ugh."',
      ],      


      // emotions
      [
        'awful',
        'afraid',
        'uneasy',
        'nauseous',
        'moody',
        'bewildered',
        'nervous',
        'depressed',
        'scared',
        'grouchy',
        'unsure',
        'remorseful',
        'disgusted',
        'filled with disdain',
        'defeated'
      ],
      
      // judgements
      [
        'the worst',
        'scary',
        'unsafe',
        'gross',
        'weird',
        'strange',
        'puzzling',
        'disgusting',
        'stressful',
        'frustrating',
      ]      
    ],
    
    // neutral
    [
      // statements
      [
        '"I feel fine."',
        '"Not much going on."',
        '"This is fine."',
        '"Not much to write home about."',
        '"Alright."'
      ],
      
      
      // emotions 
      [
        'neutral',
        'okay',
        'indifferent',
      ],
      
      
      // judgements
      [
        "okay",
        'not very interesting',
        'boring',
      ]      
    ],
    
    
    // positive
    [
      // statements
      [
        '"This is great!"',
        '"I really like this."',
        '"I feel at peace."',
        '"This gives me strength"',
        '"This is the best!"'
      ],
      
      
      // emotions 
      [
        "good",
        "great",
        "fantastic",
        "elated",
        "amused",
        "confident",
        "empowered",
        "excited",
        "inspired",
        "curious",
        "relieved",
        "thankful",
      ],
      
      // judgements
      [
        "interesting",
        "fascinating",
        "excellent",
        "quite good",
        "wonderous",
        "really nice"
      ]      
    ]
  ]


  return ::(this, state) {
    if (this.opinions == empty) ::<= {
      for(0, 2) ::(i) {
        this.addOpinion(
          fullName : Item.database.getRandomFiltered(::(value) <- (value.traits & Item.TRAIT.UNIQUE) == 0).name + 's',
          plural : true
        )
      }
    }    
    
    
    @:cores = state.opinions->keys->filter(::(value) <- state.opinions[value].core == true);

    @:which = if (cores->size > 0 && random.try(percentSuccess:10)) 
      random.pickArrayItem(:cores)
    else 
      random.pickArrayItem(:[...state.recentOpinions]);
      
    
    @:set = state.opinions[which];
    
    @:statements = feelings[set.affect][0];
    @:emotions   = feelings[set.affect][1];
    @:judgements = feelings[set.affect][2];
    
    @:plural = if (set.plural == empty || set.plural == false) false else true;
    
    @:statement = statements[((statements->size-1) * set.statement)->round]
    @:emotion   = emotions  [((emotions->size-1)   * set.emotion)->round]
    @:judgement = judgements[((judgements->size-1) * set.judgement)->round]
    
    
    
    return if (plural) 
      statement + '\n' +
      '\n' +
      this.name + ' feels ' + emotion + '.\n' +
      'They are thinking about ' + which + '. ' + this.name + ' feels that ' + set.shortName + (if(set.pastTense == true) ' were ' else ' are ') + judgement + '.\n'
    
     else 
      statement + '\n' +
      '\n' +
      this.name + ' feels ' + emotion + '.\n' +
      'They are thinking about ' + which + '. ' + this.name + ' feels that ' + set.shortName + (if(set.pastTense == true) ' was ' else ' is ') + judgement + '.\n'

  }
}

// returns EXP recommended for next level
@:levelUp ::(level, stats => StatSet.type, growthPotential => StatSet.type, whichStat) {
      
  @:stat = ::(name) {
    when (random.flipCoin()) 0;
    @:base = growthPotential[name];
    @val =  (0.5 * (random.number()/2) * (base / 4) + base/5)->floor
    when (val < 1)
      random.number() * 2;
    return val;
  }
      
  stats.add(stats:StatSet.new(
    HP  : (if(random.flipCoin()) 3 else 1) + (stat(name:'HP')),
    AP  : 0,
    ATK : stat(name:'ATK'),
    INT : stat(name:'INT'),
    DEF : stat(name:'DEF'),
    SPD : stat(name:'SPD'),
    LUK : stat(name:'LUK'),
    DEX : stat(name:'DEX')
  ));
  
  return (50 + (level*level * 0.1056) * 1000)->floor;
}	


@:notifyEffect ::(this, state, isAdding, effectIDs) {
  @:alreadyPosted = {};
  @needsUpdate = false;
  @:getSummary ::(id) {
    when (alreadyPosted[id] == true) empty;
    alreadyPosted[id] = true;
    @:effect = Effect.find(id:id);
    when(effect.hasTraits(:Effect.TRAIT.INSTANTANEOUS)) empty;
    @:counts = this.effectStack.getAllByFilter(::(value) <- value.id == id)->size;
    
    @:base = effect.name + (if (counts > 1) "(x"+counts+")" else "");
    when(effectIDs->findIndex(:id) == -1) "   " + base;
    
    needsUpdate = true;
    when (effectIDs->size == 1)
      (if (isAdding)"++ " else "-- ") + base + ": " + effect.description;


    return (if (isAdding)"++ " else "-- ") + base;
  }
  
  
  @:lines = [];
  foreach(this.effectStack.getAll()) ::(k, v) {
    @:line = getSummary(:v.id);
    when(line == empty) empty;
    lines->push(:line);
  }
  
  when(lines->size == 0) empty;
  when(needsUpdate == false) empty;
  
  
  windowEvent.queueDisplay(
    prompt: this.name + ' - Effects Changed!',
    lines: canvas.refitLines(input:lines)
  );
}

@:statUp ::(level, growth => Number) {

  @:stat :: (potential, level) {
    when(potential <= 0) potential = 1;
    return 1 + ((level**0.65) + (random.number()*4))->floor;
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

@:newDeckTemplate ::<- {
  supportArts : [],
  professionArts : []
}



@:assembleDeck ::(this, state) {
  @:deck = ArtsDeck.new(profession: this.profession.id);
  @:set = state.deckTemplates[state.equippedDeck];
  
  deck.subscribe(::(event, card) {
    match(event) {
      (ArtsDeck.EVENTS.DRAW): this.effectStack.emitEvent(
        name: 'onDraw',
        card
      ),

      (ArtsDeck.EVENTS.DISCARD): this.effectStack.emitEvent(
        name: 'onDiscard',
        card
      ),

      (ArtsDeck.EVENTS.LEVEL): this.effectStack.emitEvent(
        name: 'onLevel',
        card
      ),

      (ArtsDeck.EVENTS.SHUFFLE): this.effectStack.emitEvent(
        name: 'onShuffle'
      )
    }
  });
  

  // add weapon
  @:hand = state.equips[EQUIP_SLOTS.HAND_LR];
  if (hand != empty && hand.arts->size >= 2) ::<= {
    deck.addArt(id:hand.arts[0]);
    deck.addArt(id:hand.arts[1]);
  }  
  
  // profession boosts
  foreach(set.professionArts) ::(k, v) {
    deck.addArt(id:v);
  }
  
  
  @:world = import(module:'game_singleton.world.mt');
  if (set.supportArts) ::<= {
    foreach(set.supportArts)::(k, v) {
      deck.addArt(id:v);
    }
  }
  
  return deck;
}

@:animateDamageParticles::() {
  @:emitter = import(:'game_class.particle.mt').new(
    directionMin: -70,
    directionMax: -15,
    directionDeltaMin: 0,
    directionDeltaMax: 0,
    
    speedMin: 0.5,
    speedMax: 2,
    speedDeltaMin: -0.06,
    speedDeltaMax: -0.02,
    
    characters : ['/', '/', '/', ',', ',', ',', '.', '.', '.'],
    lifeMin: 5,
    lifeMax: 9
  );

  @:emitterTrail = import(:'game_class.particle.mt').new(
    directionMin: 0,
    directionMax: 0,
    directionDeltaMin: 0,
    directionDeltaMax: 0,
    
    speedMin: 0,
    speedMax: 0,
    speedDeltaMin: 0,
    speedDeltaMax: 0,
    
    characters : ['\\', '\\', '\\', ',', ',', ',', '.', '.', '.'],
    lifeMin: 9,
    lifeMax: 20
  );


  @emitterTransform = ::<= {
    @x = canvas.width / 2 + canvas.width / 8;
    @y = canvas.height / 2 - canvas.height / 3;
    emitter.move(x, y);
    emitterTrail.move(x, y);

    return ::{
      when (y > canvas.height / 2 + canvas.height/3) ::<= {
        emitter.stop();
        emitterTrail.stop();
      }
      emitter.move(x, y);
      emitterTrail.move(x, y);
      x -= 2.1;
      y += 1.5;
    }
  };
  emitter.onFrame = emitterTransform;
  emitter.start();
}

@:animateDamage ::(this, from, to, caption) {

  if (windowEvent.log != empty)
    windowEvent.log->push(:'!!  ' + caption);

  @hp = from - to;
  @frame = 0;

  @:getShakeWeight ::{
    when(hp <= 1) 0.5;
    @scale = from - to;
    when(frame > hp) 0.5;
    if (scale > 10) scale = 10;
    @shakeScale = scale / 15.0;
    return 0.5 + (-shakeScale/2 + random.number()*shakeScale)
  }
  
  @:maxHP = displayHP(:this.stats.HP);
  windowEvent.queueCustom(
    onEnter ::{
      when (hp <= 1) empty;
      when (windowEvent.autoSkip) empty
      when (windowEvent.autoSkipAnimations) empty
      
      animateDamageParticles();    
    },
    isAnimation: true,
    onInput ::(input) {
      match(input) {
        (windowEvent.CURSOR_ACTIONS.CONFIRM,
         windowEvent.CURSOR_ACTIONS.CANCEL):
        hp = 0
      }
    },
    animationFrame ::{  
      canvas.renderTextFrameGeneral(
        leftWeight: getShakeWeight(),
        topWeight : getShakeWeight(),
        lines : [
          caption,
          '',
          canvas.renderBarAsString(width:40, fillFraction: (to + hp) / this.stats.HP),
          'HP: ' + (if (maxHP == '??') '??' else to + hp->round) + ' / ' + maxHP
        ]
      );
      frame += 1;

      
      hp = hp * 0.9;

      when(hp->abs <= 0.15)
        windowEvent.ANIMATION_FINISHED;
    }
  );
    
  windowEvent.queueDisplay(
    leftWeight: 0.5,
    topWeight : 0.5,
    skipAnimation: true,
    lines : [
      caption,
      '',
      canvas.renderBarAsString(width:40, fillFraction: (to) / this.stats.HP),
      'HP: ' + (if (maxHP == '??') '??' else to) + ' / ' + displayHP(:this.stats.HP)
    ]        
  );    

}

@:animateDeath ::(this) {
  @frame = 0;

  @:getShakeWeight ::{
    @shakeScale = 1 - frame / 15;
    when(shakeScale < 0) 0.5;
    return 0.5 + (-shakeScale/2 + random.number()*shakeScale)
  }
  
  windowEvent.queueCustom(
    onEnter ::{},
    isAnimation: true,
    onInput ::(input) {
      match(input) {
        (windowEvent.CURSOR_ACTIONS.CONFIRM,
         windowEvent.CURSOR_ACTIONS.CANCEL):
          frame = 20
      }
    },
    animationFrame ::{
      canvas.renderTextFrameGeneral(
        leftWeight: getShakeWeight(),
        topWeight : getShakeWeight(),
        lines : [
          this.name,
          '',
          canvas.renderBarAsString(width:40, fillFraction: 0),
          'HP: ' + '0 ' + ' / ' + displayHP(:this.stats.HP)
        ]
      );
      frame += 1;

      when(frame > 20)
        windowEvent.ANIMATION_FINISHED;
    }
  );
    
  windowEvent.queueDisplay(
    leftWeight: 0.5,
    topWeight : 0.5,
    skipAnimation: true,
    lines : [
      this.name,
      '',
      if (this.name->contains(key:'Wyvern'))
          '     ------ D E F E A T E D -------     '
        else
          '     ---------- D E A D  ----------     ',
      'HP: ' + '--' + ' / ' + displayHP(:this.stats.HP)
    ]        
  );    

}


@:levelUpProfession ::(this, state, profession) {
  @set = state.professionProgress[profession.id];


  @:level2exp ::(level) {
    @:ct = profession.arts->size;
    @:MAX_DEFEATS = 15;
    @:averageSub = MAX_DEFEATS / ct;
    // y = mx + b
    // y - mx = b
    // m = ((y1 - mx1)-y0) / (-x0)
    // -x0m = y1 - mx1 - y0
    // mx1 - x0m = y1 - y0
    // x1 - x0 = (y1 - y0) / m
    // x1 - x0 / y1 - y0 = 1 / m
    // y1 - y0 / x1 - x0 = m
    
    @:m = (MAX_DEFEATS - 2) / (ct - 0);
    @:b = MAX_DEFEATS - m*ct;
    
    return ((m*level + b)*PROF_EXP_PER_KNOCKOUT)->floor;
  }

  
  if (set == empty) ::<= {
    set = {
      level : 0,
      exp : 0,
      expToNext : level2exp(:0)
    }
    state.professionProgress[profession.id] = set;
  } else ::<= {
    set.level += 1;
    set.exp = 0;
    set.expToNext = level2exp(:set.level);
    @:nextArt = profession.arts[set.level-1];
    if (nextArt)
      state.professionArts->push(:nextArt);
  }
  
}

@:expUpProfession ::(this, state, profession, exp, silent, onDone) {
  @set = state.professionProgress[profession.id];
  if (set.level >= profession.arts->size)      
    exp = 0;

  when(exp == 0) 
    if (onDone) onDone();


  if (set == empty) ::<= {
    levelUpProfession(this, state, profession);
    set = state.professionProgress[profession.id];
  }
  
  if (silent == empty || silent == false) ::<= {
    @:animateLevel::{
      @curVal = exp;
      @originalExpToNext = set.expToNext;
      @originalExp = exp;      
      @originalSetExp = set.exp;
      
      
      if (exp >= set.expToNext) ::<= {
        exp -= set.expToNext;
        set.exp += set.expToNext;
        set.expToNext = 0;
      } else ::<= {
        set.expToNext -= exp;
        set.exp += exp;
        exp = 0;
      }
      
      animateBar(
        from: originalSetExp,
        to:   set.exp,
        max:  set.expToNext + set.exp,
        
        onGetPauseFinish ::<- true,
        onFinish :: {
          
          if (set.expToNext == 0) ::<= {
            levelUpProfession(this, state, profession);
            windowEvent.queueDisplay(
              lines: [
                'Level Up!',
                this.name + ', the ' + profession.name + ' is now Level ' + if (set.level >= profession.arts->size) 'MAX' else set.level,
                '',
                'Learned: ' + Arts.find(:profession.arts[set.level-1]).name
              ]
            )
            
            windowEvent.queueMessage(
              text: 'To view this new art, visit the Arts menu for ' + this.name + ' in the party menu.'
            );
            
            windowEvent.queueMessage(
              text: this.name + '\'s fortitude increased.'
            );
            
            @:oldStats = StatSet.new();
            oldStats.load(serialized:this.stats.save());
            @:newState = this.stats.save();
            newState['HP'] += if (random.try(percentSuccess:20)) 3 else 2;
            this.stats.load(serialized:newState);
            
            oldStats.printDiff(
              other:this.stats,
              prompt: 'New stats: ' + this.name
            );            
            
            when (set.level >= profession.arts->size) 
              if (onDone) onDone();
            
            animateLevel()
          } else 
            if (onDone) onDone();

        },
        onGetCaption       ::<- this.name + ', ' + profession.name + ': Level ' + if (set.level >= profession.arts->size) 'MAX' else set.level,
        onGetSubcaption    ::{
          @amount = (originalExpToNext-(curVal-originalSetExp));
          if (amount < 0) amount = 0; 
          return if (set.level >= profession.arts->size) '' else 'Exp to next: ' + amount + ' EXP'
        },
        onGetSubsubcaption ::<- if (set.level >= profession.arts->size) '' else '            +' + (originalExp - (curVal-originalSetExp)),
        onGetLeftWeight:: <- 0.5,
        onGetTopWeight:: <- 0.5,
        
        onNewValue ::(value) {
          curVal = value->round;
        }
      );
    }
    
    animateLevel();
  } else ::<= {
    ::? {
      forever ::{
        when(exp == 0) send();
        if (set.level >= profession.arts->size) send();
        
        if (exp > set.expToNext) ::<= {
          exp -= set.expToNext;
          levelUpProfession(this, state, profession);
        } else ::<= {
          set.exp += exp
          set.expToNext -= exp
        }
      }
    }
  }
}


@initializeEffectStackProper ::(this, state) {
  
  @:items = [];
  if (state.innateEffects != empty) ::<= {
    foreach(state.innateEffects) ::(i, v) {
      this.effectStack.addInnate(id:v);
      items->push(:v);
    }
  }
  
  foreach(this.profession.passives)::(index, passiveName) {
    items->push(:passiveName);
    this.effectStack.add(
      id:passiveName,
      from:this,
      duration:Arts.A_LOT,
      noNotify : true
    );
  }


  foreach(state.equips) ::(i, item) {
    when(item == empty) empty;
    foreach(item.equipEffects)::(index, effect) {
      items->push(:effect);
      this.effectStack.add(
        id:effect,
        item,
        from:this,
        duration:Arts.A_LOT,
        noNotify : true
      );
    }
  }
  
  if (items->size > 0)
    this.notifyEffect(
      isAdding: true,
      effectIDs : items
    );
  
  
  this.effectStack.subscribe(
    ::(*args) {
      foreach(state.equips) ::(i, v) {
        when(v == empty) empty;
        when(v.base.id == 'base:none') empty;
        v.commitEffectEvent(*args);
      }
    }
  );
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

@none = Item.NONE;
@displayedHurt = {};




@:Entity = LoadableClass.createLight(
  name : 'Wyvern.Entity', 
  statics : {
    PROF_EXP_PER_KNOCKOUT : {get::<- PROF_EXP_PER_KNOCKOUT},
    EQUIP_SLOTS : {get::<- EQUIP_SLOTS},
    DAMAGE_TARGET : {get::<- DAMAGE_TARGET},
    normalizedDamageTarget :: {
      @:rate = random.number();
      when (rate <= 0.25) DAMAGE_TARGET.HEAD;
      when (rate <  0.75) DAMAGE_TARGET.BODY;
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
    shield : 0,
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
    data : empty,
    deckTemplates : empty,
    equippedDeck : 'MAIN',
    professionArts : empty,
    innateEffects : empty,
    professionProgress : empty,
    opinions : empty,
    recentOpinions : empty,
    affinity : -1
  },
  
  private : {
    effectStack : Nullable,
    battle : Nullable,
    overrideInteract : Nullable,
    requestsRemove : Boolean,
    onInteract : Function,
    abilitiesUsedBattle : Nullable,
    owns : Nullable,
    canActThisTurn : Boolean,
    deck : Nullable
  },
  
  
  interface : {
    initialize ::{
      if (none == empty) none = Item.NONE;
      @:this = _.this;
      _.state.battleAI = BattleAI.new(user:this); 
      @:state = _.state;
    },
      
    
  
    defaultLoad::(island, speciesHint, professionHint, personalityHint, levelHint, adventurousHint, qualities, innateEffects, faveWeapon) {
      @:world = import(module:'game_singleton.world.mt');
      @:state = _.state;
      @:this = _.this;

      state.innateEffects = innateEffects;
      state.affinity = random.pickArrayItem(:Damage.TYPE->values);
      
      state.worldID = world.getNextID();
      state.deckTemplates = {
        MAIN : newDeckTemplate()
      };

      // starting supports
      state.stats = StatSet.new(
        HP:1,
        AP:random.integer(from:8, to:14),
        ATK:1,
        DEX:1,
        INT:1,
        DEF:1,
        // LUK can be zero. some people are just unlucky!
        SPD:1  
      );

      @:Location = import(module:'game_mutator.location.mt');

      state.hp = 1;
      state.ap = 0;
      state.flags = StateFlags.new();
      state.isDead = false;
      state.name = NameGen.person();
      state.personality = Personality.getRandom();
      state.favoritePlace = Location.database.getRandom();
      state.growth = StatSet.new();
      state.adventurous = random.try(percentSuccess:25);
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
      state.data = {};






      if (adventurousHint != empty)
        state.adventurous = adventurousHint;
      
      if (personalityHint != empty)
        state.personality = Personality.find(id:personalityHint);

      state.qualitiesHint = qualities;


      
      state.profession = if (professionHint == empty) 
          Profession.getRandomFiltered(filter::(value) <- value.learnable) 
        else 
          Profession.find(id:professionHint)

      state.professionProgress = [];
      state.professionArts = [];

      if (state.profession.traits & Profession.TRAIT.NON_COMBAT) ::<= {
        for(0, 21) ::(i) {
          this.autoLevelProfession();
        }
      } else 
        this.autoLevelProfession();
      

      


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
              filter:::(value) <- 
                value.hasNoTrait(:Item.TRAIT.UNIQUE) && 
                value.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS)
                && value.tier <= island.tier
            ),
            rngEnchantHint:true
          )
        );


        if (random.try(percentSuccess:0.2 + island.tier*2)) ::<= {
          @itemMaterials = [
            'base:mythril',
            'base:quicksilver',
            'base:dragonglass',
            'base:sunstone',
            'base:moonstone',
            'base:adamantine',
            'base:ray',
            'base:ethereal',
          ]
          
          @itemQualities = [
            'base:kings',
            'base:queens',
            'base:masterwork',
            'base:legendary',
            'base:divine',
          ]
          
          @item = Item.new(
            base: Item.database.getRandomFiltered(
              filter::(value) <- (
                value.hasNoTrait(:Item.TRAIT.UNIQUE) && 
                value.hasTraits(:Item.TRAIT.METAL | Item.TRAIT.HAS_QUALITY)
              )
            ),
            rngEnchantHint:true,     
            qualityHint : random.pickArrayItem(list:itemQualities),
            materialHint : random.pickArrayItem(list:itemMaterials)
          )  

          state.inventory.add(item);
            
        }
      
        if (state.faveWeapon == empty)
          state.faveWeapon = Item.database.getRandomFiltered(filter::(value) <- 
            value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
            (value.traits & Item.TRAIT.WEAPON) != 0 && value.tier <= island.tier)
      } else ::<= {
        if (state.faveWeapon == empty)
          state.faveWeapon = Item.database.getRandomFiltered(filter::(value) <- 
            value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
            (value.traits & Item.TRAIT.WEAPON) != 0)
      }
      state.inventory.addGold(amount:(random.number() * 100)->ceil);
      state.favoriteItem = Item.database.getRandomFiltered(filter::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE))





      return this;
    },   
    

    afterLoad :: {
      @:state = _.state;
      @:this = _.this;
      state.battleAI.setUser(user:this);
      if (state.affinity == -1)
        state.affinity = random.pickArrayItem(:Damage.TYPE->values)       

    },

    worldID : {
      get ::<- _.state.worldID
    },
    
    // Called to indicate to the entity the 
    // start of a new turn in general.
    // This does things like reset stats according to 
    // effects and such.
    startTurn :: {
      _.this.recalculateStats();       
      _.this.flags.reset();
    },
    
    getChanceOfAttackSuccessDEXvDEF::(other) {
      @:state = _.state;
      @:this = _.this;
      
      @ratioDiff = 1 - ((other.stats.DEF - this.stats.DEX) / (other.stats.DEF));
      ratioDiff += this.stats.LUK / 100.0;

      if (ratioDiff < 0.4)
        ratioDiff = 0.4;


      if (ratioDiff > 0.95)
        ratioDiff = 0.95;

      return ratioDiff;            
    },
    
    getArtMinDamage ::(handCard) {
      @:this = _.this;
      @:art = Arts.find(id:handCard.id);
      @dmg= art.baseDamage(user:this, level:handCard.level);
      when(dmg == empty) empty;
      
      return (dmg * (1 - 0.5 * DAMAGE_RNG_SPREAD))->ceil;
    },

    getArtMaxDamage ::(handCard) {
      @:this = _.this;
      @:art = Arts.find(id:handCard.id);
      @dmg= art.baseDamage(user:this, level:handCard.level);
      when(dmg == empty) empty;
      
      return (dmg * (1 + 0.5 * DAMAGE_RNG_SPREAD))->ceil;
    },
    
    // called to signal that a battle has started involving this entity
    battleStart ::(battle) {
      @:state = _.state;
      @:this = _.this;
      _.requestsRemove = false;
      _.abilitiesUsedBattle = {}
      _.effectStack = EffectStack.new(parent:this);
      _.canActThisTurn = true;
      foreach(this.species.passives)::(index, passiveName) {
        this.effectStack.addInnate(id:passiveName);
      }      
      _.battle = battle;
      _.deck = assembleDeck(this, state);
      _.deck.shuffle();
      _.deck.redraw();
      initializeEffectStackProper(*_);
      state.ap = (state.stats.AP / 2)->floor

      //resetEffects(priv:_, this:_.this, state:_.state);        
    },
    
    
    addOpinion ::(fullName, shortName, plural, pastTense, core) {
      @:state = _.state;
      @:this = _.this;
      
      ::<= {
        if (state.opinions == empty) ::<= {
          state.opinions = [];
          state.recentOpinions = [];
        }
        when(state.opinions[fullName] != empty) empty;
          
        if (shortName == empty)
          shortName = fullName;      
          
        state.opinions[fullName] = {
          affect : random.integer(from:0, to:2),
          shortName : shortName,
          statement : random.float(),
          emotion : random.float(),
          judgement : random.float(),
          plural : plural,
          pastTense : pastTense,
          core : core
        } 
      }
      
      if (state.recentOpinions->size > 3)
        state.recentOpinions->remove(key:0);
      state.recentOpinions->push(:fullName);
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
      get ::<- _.deck
    },
    
    
    supportArts : {
      get ::<- _.state.deckTemplates[_.state.equippedDeck].supportArts,
      set ::(value) <- _.state.deckTemplates[_.state.equippedDeck].supportArts = value
    },
    
    professionArts : {
      get ::<- [..._.state.professionArts]
    },
    
    deckTemplateNames : {
      get ::<- _.state.deckTemplates->keys
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
    
    addDeck ::(name) {
      @:state = _.state;
      @:this = _.this;
      
      state.deckTemplates[name] = newDeckTemplate();
    },
    
    getEquippedDeckName ::<- _.state.equippedDeck,
    
    equipDeck ::(name, silent) {
      @:state = _.state;
      @:this = _.this;

      when (state.deckTemplates->keys->findIndex(:name) == -1) 
        error(:"No such deck is equippable. Check your code!");

      @:set = state.deckTemplates[name];
      when(this.calculateDeckSize(:set) < DECK_MIN_ART_COUNT)
        windowEvent.queueMessage(
          text: "Deck "+name+' has too few cards to be equipped. Each art gives cards to the Arts deck based on its rarity. A minimum threshold is required. Your deck has ' + this.calculateDeckSize(:set) + ' out of the minimum of ' + DECK_MIN_ART_COUNT + '.'
        );
      
      if (silent != true)
        windowEvent.queueMessage(
          text: this.name + ' is now using the deck ' + name + '.'
        );

      _.state.equippedDeck = name;
    },
    
    removeDeck ::(which) {
      @:state = _.state;
      @:this = _.this;

      when(which == state.equippedDeck) empty;
      @:world = import(module:'game_singleton.world.mt');
      
      foreach(state.deckTemplates[which].supportArts) ::(k, v) {
        world.party.addSupportArt(id:v);
      }
      state.deckTemplates->remove(:which);
    },
    
    editDeck ::(which) {
      @:state = _.state;
      @:this = _.this;
      @:pickArt = import(:'game_function.pickart.mt');
      
      @:set = state.deckTemplates[which];
      if (set == empty)
        error(:'Incorrect deck name');
      
      
      
      @:equipped::{
        when(set.supportArts->size == 0)
          windowEvent.queueMessage(
            text: this.name + ' currently has no Support Arts. View the Trunk to add some.'
          );
      
        @:pickArt = import(:'game_function.pickart.mt');
        pickArt( 
          onGetPrompt :: {
            @:size = this.calculateDeckSize(:set);
            return which + ': ' + (if(size <= DECK_MIN_ART_COUNT) 
                ''+size + ' / ' + DECK_MIN_ART_COUNT + ' cards'
              else
                ''+size + ' cards'
            )
          },
           
          onGetList :: {
            return set.supportArts;
          },
          canCancel:true,
          keep: true,
          onChoice::(choice) {
            @:which = choice;
            @:id = set.supportArts[which];
            
            when(id == empty) empty;
            
            @:art = Arts.find(id:id);
            
            windowEvent.queueChoices(
              prompt: art.name,
              choices : [
                'Put in Trunk'
              ],
              canCancel: true,
              onChoice::(choice) {
                @:world = import(module:'game_singleton.world.mt');
                
                when (set.supportArts->size == MIN_SUPPORT_COUNT) ::<= {
                  windowEvent.queueMessage(text: 'Each person must have at least 5 supports in their deck. Please try adding a different Support to this person\'s deck before removing this Art.');
                }
                
                world.party.addSupportArt(id:art.id);
                set.supportArts->remove(:set.supportArts->findIndex(:art.id));
              }
            );

          }
        );

        
      }
      
      
      @:trunk::{
        @:world = import(module:'game_singleton.world.mt');

        when(world.party.arts->size == 0)
          windowEvent.queueMessage(
            text: 'The party\'s Support Trunk currently has no Support Arts.'
          );
          
        @list;

        @:pickArt = import(:'game_function.pickart.mt');
        pickArt(
          keep: true,
          prompt : 'Support Trunk:', 
          canCancel:true,
          onGetList :: {
            list = [...world.party.arts]->map(::(value) <- value.id);
            return list;
          },
          onChoice::(art, category) {
            @id = art;
            when(id == empty) empty;
            
            art = Arts.find(id);
            
            windowEvent.queueChoices(
              prompt: art.name,
              choices : [
                'Put in ' + this.name + '\'s Deck'
              ],
              canCancel: true,
              onChoice::(choice) {
                @:world = import(module:'game_singleton.world.mt');
                when(set.supportArts->findIndex(:id) != -1)
                  windowEvent.queueMessage(
                    text: 'Only one of each kind of Support Art can be equipped at a time.'
                  );
                
                world.party.takeSupportArt(id:art.id);
                set.supportArts->push(:art.id);
              }
            );
          }
        );
      }
      
      @:addProfessionArt ::{
        

        when (this.getUnequippedProfessionArts()->size == 0) 
          windowEvent.queueMessage(
            text: this.name + ' has no more equippable profession Arts available.'
          );        
        
      
        pickArt(
          prompt: 'Profession Arts:',
          onGetList ::<- this.getUnequippedProfessionArts(),
          canCancel: true,
          onChoice ::(art, category) {
            set.professionArts->push(:art);
          }
        );
      }
      


      @:start ::{
        pickArt(
          keep:true,
          onGetPrompt :: {
            @:size = this.calculateDeckSize(:set);
            return which + ': ' + (if(size <= DECK_MIN_ART_COUNT) 
                ''+size + ' / ' + DECK_MIN_ART_COUNT + ' cards'
              else
                ''+size + ' cards'
            )
          },



          onCancel ::{
            when(this.calculateDeckSize(:set) < DECK_MIN_ART_COUNT && state.equippedDeck == which) ::<= {
              windowEvent.queueMessage(
                text: this.name + '\'s deck has too few cards to keep equipped. Each art gives cards to the Arts deck based on its rarity. A minimum threshold is required. Your deck has ' + this.calculateDeckSize(:set) + ' out of the minimum of ' + DECK_MIN_ART_COUNT + '.'
              );
              
              
              start();
            }
          },
          onGetCategories ::{
            @:categories = [];
            @:hand = state.equips[EQUIP_SLOTS.HAND_LR];
            categories->push(:['Weapon:', if (hand != empty && hand.arts != empty && hand.arts->size >= 2) [
              hand.arts[0],        
              hand.arts[1]
            ] else [empty, empty]]);

            categories->push(:['Profession:',::<= {
              @:profArts = [...set.professionArts];
              for(profArts->size, 5) ::(i) {
                profArts->push(:empty);
              }
              return profArts;
            }]);

            categories->push(:['Support:', [...set.supportArts]]);
            categories->push(:[' Add support...', []]);
            return categories;
          },
          onChoice::(art, category) {
            
            when(category == ' Add support...') ::<= {
              trunk();
            }
          
            when(category == 'Support:') ::<= {
              when (art == empty)
                trunk();
                
              windowEvent.queueChoices(
                choices: ['Unequip'],
                canCancel: true,
                leftWeight : 1,
                topWeight : 1,
                onChoice::(choice) {
                  @:world = import(module:'game_singleton.world.mt');
                  world.party.addSupportArt(id:art);
                  set.supportArts->remove(:set.supportArts->findIndex(:art));
                
                }
              )
            }

            when(category == 'Weapon:') 
              windowEvent.queueMessage(
                text: 'Weapon arts come directly from an equipped weapon. These are only viewable here.'
              );

            
            when(category == 'Profession:') ::<= {
              when(art == empty) ::<= {
                addProfessionArt();
              }
              
              windowEvent.queueChoices(
                choices: ['Unequip'],
                leftWeight: 1,
                topWeight: 1,
                canCancel: true,
                keep: false,
                onChoice::(choice) {
                  when(choice == 0) empty;
                  
                  set.professionArts->remove(:
                    set.professionArts->findIndex(:art)
                  );
                }
              );
            }
          },
          canCancel:true
        );      
      }
      start();
    },

    viewDeckArts ::(prompt, which) {
      @:this = _.this;
      @:state = _.state;
      // add weapon
      @:categories = {}

      @:hand = state.equips[EQUIP_SLOTS.HAND_LR];
      if (hand != empty && hand.arts != empty && hand.arts->size >= 2) ::<= {
        categories->push(:['Weapon:',[
          hand.arts[0],        
          hand.arts[1]
        ]])
      }  
      @:set = state.deckTemplates[state.equippedDeck];

      // profession boosts
      categories->push(:['Profession:', [...set.professionArts]]);

      if (set.supportArts) ::<= {
        categories->push(:['Support:', [...set.supportArts]]);;
      }

      
      @:pickArt = import(:'game_function.pickart.mt');
      pickArt(categories, prompt, canCancel:true);
    },    

    // called to signal that a battle has started involving this entity
    battleEnd :: {
      _.battle = empty;
      @:this = _.this;
      _.this.effectStack.clear(all:true);
      _.effectStack = empty;
      _.abilitiesUsedBattle = empty;        
      
      _.deck = empty;
      
      _.this.recalculateStats(); 
      _.state.ap = 0;               
      _.state.shield = 0;
      breakpoint();
    },
    
    calculateDeckSize ::(set){
      @:state = _.state;
      @:this = _.this;
      @:pickArt = import(:'game_function.pickart.mt');
      
      if (set == empty)
        set = state.deckTemplates[state.equippedDeck];
      
      @:cards = [
        ...set.supportArts, 
        ...set.professionArts,
        ...(if (state.equips[EQUIP_SLOTS.HAND_LR] != empty && state.equips[EQUIP_SLOTS.HAND_LR].arts != empty) 
          [
            state.equips[EQUIP_SLOTS.HAND_LR].arts[0],        
            state.equips[EQUIP_SLOTS.HAND_LR].arts[1]
          ]
        else 
          []
        )
      ]      
      
      when(cards->size == 0) 0;
      return cards->reduce(::(previous, value) <-
          (if (previous == empty) 0 else previous) + 
          ArtsDeck.artIDtoCount(:value)
        );    
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
      
      
      foreach(state.equips)::(index, equip) {
        when(equip == empty) empty;
        state.stats.mod(stats:equip.equipModBase);
      }

      foreach(state.equips)::(index, equip) {
        when(equip == empty) empty;
        state.stats.modRate(stats:equip.equipMod);
      }

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
      this.effectStack.endTurn();
    },
    
    canUseAbilities :: {
      when(_.this.isIncapacitated()) false;
      when(_.canActThisTurn == false) false;
      return _.this.effectStack.getAllByFilter( 
        ::(value) <- Effect.find(:value.id).hasTraits(:Effect.TRAIT.CANT_USE_ABILITIES)
      )->size == 0
    },

    canUseReactions :: {
      when(_.this.isIncapacitated()) false;
      when(_.canActThisTurn == false) false;
      return _.this.effectStack.getAllByFilter( 
        ::(value) <- Effect.find(:value.id).hasTraits(:Effect.TRAIT.CANT_USE_REACTIONS)
      )->size == 0
    },

    canUseEffects :: {
      when(_.this.isIncapacitated()) false;
      when(_.canActThisTurn == false) false;
      return _.this.effectStack.getAllByFilter( 
        ::(value) <- Effect.find(:value.id).hasTraits(:Effect.TRAIT.CANT_USE_EFFECTS)
      )->size == 0
    },

    canActThisTurn ::{
      when(_.this.isIncapacitated()) false;
      when(_.canActThisTurn == false) false;
      return true;    
    },


    // lets the entity know that their turn has come.      
    actTurn ::() => Boolean {
      @:state = _.state;
      @:this = _.this;
      
      _.deck.redraw();
      @act = true;
      state.ap += 1;
      
      
      @:rets = this.effectStack.emitEvent(
        name : 'onNextTurn'
      );      
      this.checkStatChanged();
      @:priv = _;
      _.canActThisTurn = true;

      when(rets->findIndexCondition(::(value) <- value.returned == false) != -1) ::<= {
        priv.canActThisTurn = false;
        return false;
      }
      
                  
      if (this.stats.SPD < 0) ::<= {
        //windowEvent.queueMessage(text:this.name + ' cannot move! (negative speed)');
        //act = false;
      }

      if (this.stats.DEX < 0) ::<= {
        //windowEvent.queueMessage(text:this.name + ' fumbles about! (negative dexterity)');
        //act = false;
      }

      if (act == false)
        this.flags.add(flag:StateFlags.SKIPPED);
      _.canActThisTurn = act;
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
    
    professions : {
      get ::<- _.state.professionProgress->keys->map(::(value) <- Profession.find(:value))
    },
    
    getProfessionProgress ::(profession) {
      when(_.state.professionProgress[profession.id] == empty) empty;
      return {..._.state.professionProgress[profession.id]};
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
    
    opinions : {get ::<- _.state.opinions},
      
    renderHP ::(length, x) {
      @:state = _.state;
      when(state.shield == 0) 
        canvas.renderBarAsString(width:length, fillFraction:state.hp / state.stats.HP);

      return canvas.renderBarAsString(width:length, fillFraction:state.hp / state.stats.HP, character: '=') + '+' + state.shield;

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
      damage => Damage.type,
      target,
      targetPart,
      onFinish
    ){

      if (targetPart == empty)
        targetPart = DAMAGE_TARGET.BODY;

      when(target == empty) empty;
    
      @:this = _.this;
      @:state = _.state;
    
      displayedHurt[target] = true;
      if (targetPart == empty) targetPart = Entity.normalizedDamageTarget();
    
      @:hasNoEffectStack = this.effectStack == empty;
    
      if (hasNoEffectStack) 
        _.effectStack = EffectStack.new(parent:this);
        
      @:effectStack = _.effectStack;
      
      @:dmg = damage;
      @:parent = _;
      
      @:damaged = [];
      // TODO: add weapon affinities if phys and equip weapon
      // phys is always assumed to be with equipped weapon


      @:overrideTarget = [];




      @isCrit = false;
      @isHitHead = false;
      @isLimbHit = false;
      @isHitBody = false;
      
      @missHead = false;
      @missBody = false;
      @missLimb = false;


      @backupStats;

      @isDexed = false;
      @isDefed = false;
      @:hpWas0 = if (target.hp == 0) true else false;

      
      windowEvent.queueNestedPhases(
        onFinish ::(proper)  {
          if (hasNoEffectStack)        
            parent.this.effectStack.clear(all:true);
          if (hasNoEffectStack)        
            parent.effectStack = empty;

          displayedHurt->remove(key:target);
        },
        
        
        phases : [
      
      
        // attack prep + crit
        ::{
          effectStack.emitEvent(
            name: 'onPreAttackOther',
            to : target, 
            damage : dmg,
            emitCondition ::(effectInstance) <- dmg.amount > 0,
            overrideTarget,
            targetPart : targetPart
          );
          
          if (overrideTarget->size)
            target = overrideTarget[0]

          @critChance = (this.stats.LUK - target.stats.LUK) / 100;
          if (critChance < 0.001) critChance = 0.001;
          critChance *= 100;
          if (critChance > 25) critChance = 25;
          if (random.try(percentSuccess:critChance) || ((dmg.traits & Damage.TRAIT.FORCE_CRIT) != 0)) ::<={
            if (dmg.amount < 5) dmg.amount = 5;
            dmg.amount *= 2.5;
            dmg.traits |= Damage.TRAIT.IS_CRIT;
            isCrit = true;
          }
          when(dmg.amount <= 0) false;
          
        },
        
        
        // pre attacked check 
        :: {
          if (target.effectStack)
            target.effectStack.emitEvent(
              name: 'onPreAttacked',
              attacker : this, 
              damage : dmg,
              targetPart : targetPart,
              emitCondition ::(effectInstance) <- dmg.amount > 0
            );
          

          when(dmg.amount <= 0) false;        
        },

        // Def / Dex hit chance
        ::{
          when (target.isIncapacitated() || ((dmg.traits & Damage.TRAIT.FORCE_DEF_BYPASS) == 0)) empty;

          @:ratioDiff = this.getChanceOfAttackSuccessDEXvDEF(:target);
          if (random.try(percentSuccess:(1-ratioDiff)*100)) ::<= {       
            windowEvent.queueMessage(
              text: target.name + ' avoided the incoming attack!'
            );
            dmg.amount = 0;
          }
          when(dmg.amount <= 0) false;
        },
        
        
        ::{
          @:which = match(targetPart) {
            (Entity.DAMAGE_TARGET.HEAD): 'head',
            (Entity.DAMAGE_TARGET.BODY): 'body',
            (Entity.DAMAGE_TARGET.LIMBS): 'limbs'
          }
          @imperfectGuard = false;
          backupStats = this.stats.save();
          match(true) {
            ((targetPart & DAMAGE_TARGET.HEAD) != 0):::<= {
              when(isCrit)
                isHitHead = true;
            
              if (random.try(percentSuccess:20)) ::<= {
                isCrit = true;
                dmg.amount += this.stats.DEX * 1.5;
                isHitHead = true;
              } else ::<= {
                missHead = true;
                dmg.amount = 1;
              }
            },

            ((targetPart & DAMAGE_TARGET.BODY) != 0):::<= {
              isHitBody = true;   
            },

            ((targetPart & DAMAGE_TARGET.LIMBS) != 0):::<= {
              when(isCrit)
                isLimbHit = true;

              dmg.amount = 1;
              if (random.try(percentSuccess:30)) ::<= {
                isLimbHit = true;
              } else ::<= {
                missLimb = true;
              }
            }

          }
          when(dmg.amount <= 0) false;
        
        },

        ::{


          @:result = target.damage(attacker:this, damage:dmg, dodgeable:true, critical:isCrit);
          

          
          
          if (backupStats != empty)
            this.stats.load(serialized:backupStats);

          
          when(!result) empty;

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
            windowEvent.queueMessage(text: 'The hit missed the head, but still managed to hit ' + target.name +' for minimal damage!');            
          }
          if (missLimb) ::<= {
            windowEvent.queueMessage(text: 'The hit missed the limbs, but still managed to hit ' + target.name +' for minimal damage!');            
          }

          this.flags.add(flag:StateFlags.ATTACKED);




          effectStack.emitEvent(
            name : 'onPostAttackOther',
            to: target,
            damage: dmg,
            targetPart : targetPart
          );        
        },
        
        ::{
          when(target.isDead == false && hpWas0 && target.hp == 0) ::<= {
            this.flags.add(flag:StateFlags.DEFEATED_ENEMY);
            target.flags.add(flag:StateFlags.DIED);
            target.kill(from:this);                  
          }

          if (target.effectStack)
            target.effectStack.emitEvent(
              name: 'onPostAttacked',
              attacker : this, 
              damage : dmg,
              targetPart : targetPart
            );
        }
      
      ]);
    },
      
    damage ::(attacker => Object, damage => Object, dodgeable => Boolean, critical, exact) {
      @:this = _.this;
      @:state = _.state;
      
      @:alreadyKnockedOut = this.hp == 0 || state.isDead;
      if (alreadyKnockedOut)
        dodgeable = false;
        
      if (attacker == this)
        dodgeable = false;
        
        
        
      @:hasNoEffectStack = this.effectStack == empty;
      
      if (hasNoEffectStack)
        _.effectStack = EffectStack.new(parent:this);


        
      @:retval = ::<= {

        @originalAmount = damage.amount;


        // flat 15% chance to avoid damage with a shield 
        // pretty nifty!
        /*
        when (dodgeable && 
            (this.getEquipped(slot:EQUIP_SLOTS.HAND_LR).base.traits & Item.TRAIT.SHIELD) && 
            random.try(percentSuccess:15)) ::<= {
          windowEvent.queueMessage(text:random.pickArrayItem(list:[
            this.name + ' defends against ' + from.name + '\'s attack with their shield!',         
          ]));
          this.flags.add(flag:StateFlags.DODGED_ATTACK);
          return false;                              
        }*/
        


        damage.amount *= 1 + (random.number() - 0.5) * DAMAGE_RNG_SPREAD
        
        


        if (damage.amount <= 0) damage.amount = 1;


        this.effectStack.emitEvent(
          name : 'onPreDamage',
          attacker,
          damage,
          emitCondition ::(v) <- (damage.amount > 0 || exact != empty)
        );

        if (exact)
          damage.amount = originalAmount;

        when (damage.amount == 0) false;

        
        if (critical == true) ::<= {
          windowEvent.queueMessage(text: 'Critical damage!');
          this.effectStack.emitEvent(
            name: 'onCritted',
            attacker
          );

          if (attacker.effectStack)
            attacker.effectStack.emitEvent(
              name: 'onCrit',
              to: this
            );
        }


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
        
        if (state.shield > 0) ::<= {
          state.shield -= damage.amount;
          if (state.shield < 0) state.shield = 0;
          windowEvent.queueMessage(text: '' + this.name + ' received ' + damage.amount + ' '+damageTypeName() + 'damage to their shield (HP:' + this.renderHP() + ')' );        
        } else ::<= {
          if (damage.damageClass == Damage.CLASS.HP) ::<= {
            @:oldHP = state.hp;
            state.hp -= damage.amount;
            if (state.hp < 0) state.hp = 0;
            if (state.isDead || !alreadyKnockedOut)
              animateDamage(this, from:oldHP, to:state.hp, caption: '' + this.name + ' received ' + damage.amount + ' '+damageTypeName() + 'damage');
          } else ::<= {
            state.ap -= damage.amount;
            if (state.ap < 0) state.ap = 0;        
            windowEvent.queueMessage(text: '' + this.name + ' received ' + damage.amount + ' AP damage (AP:' + state.ap + '/' + state.stats.AP + ')' );
          }
        }
        @:world = import(module:'game_singleton.world.mt');

        if (world.party != empty && world.party.isMember(entity:this) && state.hp != 0 && damage.amount > state.stats.HP * 0.2 && random.number() > 0.7)
          windowEvent.queueMessage(
            speaker: this.name,
            text: '"' + random.pickArrayItem(list:state.personality.phrases[Personality.SPEECH_EVENT.HURT]) + '"'
          );
          

        state.flags.add(flag:StateFlags.HURT);
        
        if (damage.damageType == Damage.TYPE.FIRE && random.number() > 0.98)
          this.addEffect(from:attacker, id:'base:burned',durationTurns:5);
        if (damage.damageType == Damage.TYPE.ICE && random.number() > 0.98)
          this.addEffect(from:attacker, id:'base:frozen',durationTurns:2);
        if (damage.damageType == Damage.TYPE.THUNDER && random.number() > 0.98)
          this.addEffect(from:attacker, id:'base:paralyzed',durationTurns:2);
        if (damage.damageType == Damage.TYPE.PHYS && random.number() > 0.99) 
          this.addEffect(from:attacker, id:'base:bleeding',durationTurns:5);
        if (damage.damageType == Damage.TYPE.POISON && random.number() > 0.98) 
          this.addEffect(from:attacker, id:'base:poisoned',durationTurns:5);
        if (damage.damageType == Damage.TYPE.DARK && random.number() > 0.98)
          this.addEffect(from:attacker, id:'base:blind',durationTurns:2);
        if (damage.damageType == Damage.TYPE.LIGHT && random.number() > 0.98)
          this.addEffect(from:attacker, id:'base:petrified',durationTurns:2);
        

        this.effectStack.emitEvent(
          name : 'onPostDamage',
          attacker,
          damage
        );


        
        if (world.party != empty && !alreadyKnockedOut && world.party.isMember(entity:this) && state.hp == 0 && random.number() > 0.7 && world.party.members->size > 1) ::<= {
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
          
          if (attacker.effectStack)
            attacker.effectStack.emitEvent(
              name: 'onKnockout',
              to: this
            );

          if (world.party.leader == this) ::<= {
            windowEvent.queueMessage(text: this.name + ' is no longer able to act as the leader.');
            
            @:nextLead = world.party.members->filter(::(value) <- !value.isIncapacitated() && value != this)[0];

            // something got you while in the wild outside of battle, huh?
            // sorry....
            when (this.battle == empty && nextLead == empty) ::<= {
              @:instance = import(module:'game_singleton.instance.mt');
              instance.gameOver(reason:'No one is able to be leader...');              
            }
            if (nextLead != empty) ::<= {
              world.party.leader = nextLead;
              windowEvent.queueMessage(text: nextLead.name + ' is now the leader.');
            }
          }

            
          this.effectStack.emitEvent(
            name: 'onKnockedOut',
            from: attacker
          );
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
    
    heal ::(amount => Number, isShield, silent) {
      @:state = _.state;
      @:this = _.this;

      when(isShield == empty && state.hp >= state.stats.HP) empty;

      @healingData = {
        amount : amount
      };
      if (this.effectStack)
        this.effectStack.emitEvent(
          name: 'onPreHeal',
          healingData: healingData,
          emitCondition ::(effectInstance) <- healingData.amount > 0
        );
      when(healingData.amount <= 0) empty;
      amount = healingData.amount;


      amount = amount->ceil;

      if (isShield) ::<= {
        state.shield += amount;
  
        if (silent == empty)
          windowEvent.queueMessage(text: '' + this.name + ' heals ' + amount + ' Shield HP (HP:' + this.renderHP() + ')');

  
      } else ::<= {
        if (state.hp > state.stats.HP) state.hp = state.stats.HP;
        state.hp += amount;
        this.flags.add(flag:StateFlags.HEALED);
        if (state.hp > state.stats.HP) state.hp = state.stats.HP;

        if (silent == empty)
          windowEvent.queueMessage(text: '' + this.name + ' heals ' + amount + ' HP (HP:' + this.renderHP() + ')');

      }


      if (this.effectStack)
        this.effectStack.emitEvent(
          name: 'onPostHeal',
          amount: amount,
          emitCondition ::(effectInstance) <- healingData.amount > 0
        );
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
          filter::(value) <- value.hasTraits(:Item.TRAIT.METAL | Item.TRAIT.HAS_QUALITY) && value.hasNoTrait(:Item.TRAIT.UNIQUE)
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
      ::? {
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
          
          /*
          if (chooseStat == empty) ::<={ 
            @choice = random.integer(from:2, to:7);
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
          */
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
    
    // returns the stats as if the given item were equipped
    statsIfEquippedInstead ::(slot, item) {
      @:state = _.state;
      @:this = _.this;
  
      @:olditem = this.unequip(slot, silent:true);
      this.equip(item, slot, silent:true);
      this.recalculateStats();
      @:newStats = this.stats.clone();

      this.unequip(slot);      
      if (olditem) ::<= {
        this.equip(item:olditem, slot, silent:true);
      }
      this.recalculateStats();
            
      return newStats;
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
    
    autoLevelProfession ::(profession){
      @:state = _.state;
      @:this = _.this;
      levelUpProfession(this, state, profession:if (profession == empty) this.profession else profession);
    },
    
    gainProfessionExp ::(profession, exp, silent, onDone) {
      @:state = _.state;
      @:this = _.this;
      expUpProfession(
        state,
        this,
        profession : if (profession == empty) this.profession else profession,
        exp, 
        silent,
        onDone
      );
    },
    
    
    removeAllProfessionArts ::{
      @:state = _.state;
      state.deckTemplates[state.equippedDeck].professionArts = [];
    },
    
    equipAllProfessionArts:: {
      @:state = _.state;
      state.deckTemplates[state.equippedDeck].professionArts = [...state.professionArts];
    },
    
    getUnequippedProfessionArts:: {
      @:state = _.state;

      return state.professionArts->filter(::(value) <-
        (state.deckTemplates[state.equippedDeck].professionArts->findIndex(:value) == -1)
      )
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
      },
      set ::(value) {
        _.state.adventurous = value;
      }
    },
      
    // per-entity data for mods
    data : {
      get ::<- _.state.data
    },

    // happens once the dying effect is removed
    killFinalize::(from, silent) {
      @:world = import(module:'game_singleton.world.mt');
      @:state = _.state;
      @:this = _.this;
    
      if (from != empty) ::<= {
        from.effectStack.emitEvent(
          name : 'onKill',
          to: this
        );
      }

      state.flags.add(flag:StateFlags.DIED);
      state.isDead = true;        

      // basically if anyone dies its a bad time
      if (world.party.isMember(entity:this))
        world.accoladeIncrement(name:'deadPartyMembers')
      else ::<= {
        if (from != empty && world.party.isMember(entity:from)) ::<= {
          world.accoladeIncrement(name:'murders');                    
          world.party.karma -= 1000;
        }
      }

      if (silent != true)
        animateDeath(:this);
    },

      
    kill ::(silent, from) {
      @:state = _.state;
      @:this = _.this;
      state.hp = 0;
      
     when (this.effectStack == empty)
        this.killFinalize(from, silent:true);

      if (this.effectStack.getAllByFilter(::(value) <- value.id == 'base:dying')->size == 0)
        this.addEffect(from, id:'base:dying', durationTurns:2);
    },
    
    addEffect::(from => Object, id => String, durationTurns => Number, item, innate) {
      @:state = _.state;
      @:this = _.this;
      
      @:hasEffectStack = _.effectStack != empty;

      if (!hasEffectStack)
        _.effectStack = EffectStack.new(parent:this);


      @:effectData = {
        id : id,
        duration : durationTurns
      }
      

      @:rets = this.effectStack.emitEvent(
        name: 'onPreAddEffect',
        from,
        item,
        effectData
      );
      
      id = effectData.id;
      durationTurns = effectData.duration;
      
      
      when(rets->findIndexCondition(::(value) <- value.returned == false) != -1) empty;
      
      if (innate == true) ::<= {
        this.effectStack.addInnate(
          from,
          id,
          item
        );      
      } else ::<= {
        this.effectStack.add(
          from,
          id,
          duration: durationTurns,
          item
        );
      }

      this.checkStatChanged();


      if (this.effectStack != empty) ::<= {
        if (hasEffectStack) ::<= {
          this.effectStack.emitEvent(
            name: 'onPostAddEffect',
            from,
            id: id,
            duration: durationTurns, 
            effectData : effectData
          );
          
         } else ::<= {
            this.effectStack.clear(all:true);
         }
       }
       
       if (!hasEffectStack)
          _.effectStack = empty;
    },
    
    notifyEffect::(isAdding, effectIDs) <-
      notifyEffect(
        this:_.this,
        state:_.state,
        isAdding,
        effectIDs
      )
    ,
        
      
    removeEffectsByFilter::(filter => Function) {
      @:state = _.state;
      @:this = _.this;

      this.effectStack.removeByFilter(:filter);
    },

    removeFirstEffectByFilter::(filter => Function) {
      @:state = _.state;
      @:this = _.this;

      @removed = false;
      this.removeEffectsByFilter(::(value) {
        when(removed) false;
        when(filter(value)) ::<= {
          removed = true;
          return true;
        }
        return false;
      });
    },

      
    removeEffects::(effectBases => Object) {
      @:state = _.state;
      @:this = _.this;
      
      @:table = {};
      foreach(effectBases) ::(i, eff) {
        table[eff.id] = true;
      }
      this.effectStack.removeByFilter(::(value) <- table[value.id] == true);
    },

    removeEffectInstance::(instance => Object) {
      @:state = _.state;
      @:this = _.this;

      this.effectStack.removeByFilter(::(value) <- value == instance);
    },
    
    checkStatChanged::(oldStats) {
      @:state = _.state;
      @:this = _.this;

      if (oldStats == empty) ::<= {
          oldStats = StatSet.new();
          oldStats.load(serialized:this.stats.save());
      }
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
    
    shield : {
      get ::<- _.state.shield
    },
      
    ap : {
      set ::(value) <- _.state.ap = value,
      get :: {
        return _.state.ap;
      }
    },
      
    rest :: {
      @:state = _.state;
      @:this = _.this;
      state.hp = state.stats.HP;
      state.ap = state.stats.AP;

      
      if (random.flipCoin()) ::<= {
        if (random.flipCoin()) ::<= {
          this.addOpinion(
            fullName : 'their dream',
            shortName : 'the dream',
            plural : false,
            pastTense : true,
            core : false
          );
        } else ::<= {
          this.addOpinion(
            fullName : 'their nightmare',
            shortName : 'the nightmare',
            plural : false,
            pastTense : true,
            core : false
          );
        
        }
      }

    },
      
    inventory : {
      get :: {
        return _.state.inventory;
      }
    },
      
    battleAI : {
      get ::<- _.state.battleAI
    },
    
    hasEquipped::(item) {
      @:this = _.this;
      return ::? {
        foreach(this.getSlotsForItem(item)) ::(k, v) {
          if (this.getEquipped(:v) == item)
            send(:true);
        }
        return false;
      }
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
      this.addOpinion(
        fullName : 'the ' + item.name
      );


      if (item.base.equipType == Item.TYPE.TWOHANDED) ::<={
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
      
      
      if (_.effectStack) ::<= {
        foreach(item.equipEffects)::(index, effect) {
          this.effectStack.add(
            id:effect,
            duration: Arts.A_LOT,
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

    getEquips:: {
      return [..._.state.equips];
    },


    isEquipped::(item) {
      return _.state.equips->any(func::(value) <- value == item);
    },
      
    // returns an array of equip slots that the item can fit in.
    getSlotsForItem ::(item => Item.type) {
      return match(item.base.equipType) {
        (Item.TYPE.HAND)   :  [EQUIP_SLOTS.HAND_LR],
        (Item.TYPE.ARMOR)  :  [EQUIP_SLOTS.ARMOR],
        (Item.TYPE.AMULET)   :  [EQUIP_SLOTS.AMULET],
        (Item.TYPE.RING)   :  [EQUIP_SLOTS.RING_L, EQUIP_SLOTS.RING_R],
        (Item.TYPE.TRINKET)  :  [EQUIP_SLOTS.TRINKET],
        (Item.TYPE.TWOHANDED):  [EQUIP_SLOTS.HAND_LR],
        default: error(detail:'Item has an invalid equiptype?')    
      }
    },
      
    unequip ::(slot => Number, silent, inventory) {
      @:state = _.state;
      @:this = _.this;
      @:current = state.equips[slot];
      when (current == empty) empty;
      state.equips[slot] = empty;        
      


      if (_.effectStack) ::<= {
        foreach(current.equipEffects) ::(i, id) {
          this.effectStack.removeByFilter(::(value) <-
            value.id == id &&
            value.item == current
          );
        }
      }
      if (inventory)
        inventory.add(:current);

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
    unequipItem ::(item => Item.type, silent, inventory) {
      @:state = _.state;
      @:this = _.this;
      @slotOut;
      foreach(state.equips)::(slot, equip) {
        if (equip == item) ::<= {
          this.unequip(slot, silent, inventory);
          slotOut = slot;
        }
      }
      return slotOut;
    },
      
    pickTarget::(art, onPick, canCancel, showHitChance) {
      @:battle = _.battle;
      @:allies = battle.getAllies(entity:_.this);
      @:enemies = battle.getEnemies(entity:_.this);
      @:state = _.state;
      @:this = _.this;

    
      @:tabbedChoices = import(:'game_function.tabbedchoices.mt');
      @:choices = [
        [...enemies],
        [...allies]
      ];

      @:choiceNames = [
         [...(enemies->map(to:::(value)<- value.name))],
         [...(allies-> map(to:::(value)<- value.name))]
      ]              
      

      @hovered;
      tabbedChoices(
        leftWeight: 1,
        topWeight: 1,
        onGetTabs ::<- ['Enemies', 'Allies'],
        onGetChoices::(tab) <- choiceNames[tab],
        canCancel: if (canCancel == empty) true else canCancel,
        renderable : {
          render :: {
            when (hovered == empty) empty;
            when (showHitChance != true) empty;
            when (art.hasNoTrait(:Arts.TRAIT.IS_ATTACK)) empty;
            canvas.renderTextFrameGeneral(
              lines : canvas.columnsToLines(
                columns : [
                  [this.name, "DEX: "+this.stats.DEX, " ", " "],
                  ["", if (this.stats.DEX > hovered.stats.DEF) '>' else '<', " ", ""+(this.getChanceOfAttackSuccessDEXvDEF(:hovered)*100)->round + "% Hit Chance"],
                  [hovered.name, "DEF: "+hovered.stats.DEF, " ", " "],
                ]
              ),
              topWeight: 0.5,
              leftWeight: 0.5
            );
          }
        },
        onHover::(choice, tab) {
          hovered = choices[tab][choice-1];
        },
        
        onChoice::(choice, tab) {
          when(choice == 0) empty; 
          onPick(target:hovered)
        }
      )
    },
      
    useArt::(art, level, targets, turnIndex, targetDefendParts, targetParts, extraData) {
      @:state = _.state;
      @:this = _.this;
      @:abilitiesUsedBattle = _.abilitiesUsedBattle;
      
      when (abilitiesUsedBattle != empty && ((art.traits & Arts.TRAIT.ONCE_PER_BATTLE) != 0) && abilitiesUsedBattle[art.id] == true) windowEvent.queueMessage(
        text: this.name + " tried to use " + art.name + ", but already was used and could not be used!"
      );
      if (abilitiesUsedBattle) abilitiesUsedBattle[art.id] = true;

          
      if (art.notifCommit != Arts.NO_NOTIF) ::<= {
        @mess = art.notifCommit;
        mess = mess->replace(key:'$1', with:this.name);
        if (targets->size > 0)
          mess = mess->replace(key:'$2', with:targets[0].name);
        windowEvent.queueMessage(text: mess);
      }
     

      @:ret = art.onAction(
        user:this,
        level,
        targets, turnIndex, targetParts, extraData      
      );      
      

      if (ret->type == String && ret == Arts.FAIL && art.notifFail != Arts.FAIL) ::<= {
        @mess = art.notifFail;
        mess = mess->replace(key:'$1', with:this.name);
        if (targets->size > 0)
          mess = mess->replace(key:'$2', with:targets[0].name);
        windowEvent.queueMessage(text: mess);
      }
      
      return ret;
    },
    
    playerUseArt ::(commitAction, onCancel, card, canCancel) {
      @:battle = _.battle;
      @:allies = battle.getAllies(entity:_.this);
      @:enemies = battle.getEnemies(entity:_.this);
      @:state = _.state;
      @:this = _.this;

      @battleAction;
      windowEvent.queueNestedResolve(
        onEnter ::{
          @:art = Arts.find(id:card.id);
          @:level = card.level;
          
          @:Entity = import(module:'game_class.entity.mt');

          match(art.targetMode) {
            (Arts.TARGET_MODE.ONE,
             Arts.TARGET_MODE.ONEPART): ::<={
              
              @:chooseOnePart ::(onDone) {
                @:text = 
                [
                  [
                    'The attack aims for the head.',
                    'Has a 20% chance to do an unreduced critical hit.',
                    'If unsuccessful, does 1 damage instead.'
                  ],
                  [
                    'The attack aims for the body.',
                    'Does base damage without any additional effect.'
                  ],
                  [
                    'The attack aims for the limbs.',
                    'Has a 30% chance to cause Stunned for a turn.',
                    'Always deals 1 damage.'
                  ]
                ];
                
                @hovered = 0;
                windowEvent.queueChoices(
                  prompt: 'Use where?',
                  choices : [
                    'Aim for the head',
                    'Aim for the body',
                    'Aim for the limbs',
                  ],
                  canCancel: if (canCancel == empty) true else canCancel,
                  topWeight: 0.2,
                  leftWeight: 0.5,
                  onHover ::(choice) {
                    hovered = choice-1;
                  },
                  renderable : {
                    render :: {
                      canvas.renderTextFrameGeneral(
                        topWeight: 0.7,
                        leftWeight: 0.5,
                        lines : text[hovered]
                      );
                    }
                  },
                  onChoice::(choice) {
                    onDone(
                      which:match(choice) {
                        (1): Entity.DAMAGE_TARGET.HEAD,
                        (2): Entity.DAMAGE_TARGET.BODY,
                        (3): Entity.DAMAGE_TARGET.LIMBS
                      }
                    );
                  }
                );
              }
              
              
              this.pickTarget(
                art,
                canCancel,
                showHitChance : true, // needs work since sometimes its not relevant
                onPick ::(target) {
                  
                  if (art.targetMode == Arts.TARGET_MODE.ONEPART) ::<= {
                    chooseOnePart(onDone::(which){
                      battleAction = BattleAction.new(
                        card,
                        turnIndex : 0,
                        targets: [target],
                        targetParts: [which],
                        extraData: {}
                      )
                    });
                  } else ::<= {
                    battleAction = BattleAction.new(
                      card,
                      turnIndex : 0,
                      targets: [target],
                      targetParts: [DAMAGE_TARGET.BODY],
                      extraData: {}
                    )
                  }                  
                }
              );
            },
            (Arts.TARGET_MODE.ALLALLY): ::<={
              battleAction=
                BattleAction.new(
                  card,
                  turnIndex : 0,
                  targets: allies,
                  targetParts: [...allies]->map(to:::(value) <- DAMAGE_TARGET.BODY),                  
                  extraData: {}
                )
                 
            },
            (Arts.TARGET_MODE.ALLENEMY): ::<={
              
              battleAction=
                BattleAction.new(
                  card,
                  turnIndex : 0,
                  targets: enemies,
                  targetParts: [...enemies]->map(to:::(value) <- DAMAGE_TARGET.BODY),                  
                  extraData: {}                
                )
            },

            (Arts.TARGET_MODE.ALL): ::<={
              battleAction=
                BattleAction.new(
                  card,
                  turnIndex : 0,
                  targets: [...allies, ...enemies],
                  targetParts: [...allies, ...enemies]->map(to:::(value) <- DAMAGE_TARGET.BODY),                  
                  extraData: {}                
                )
            },



            (Arts.TARGET_MODE.NONE): ::<={
              battleAction=
                BattleAction.new(
                  card,
                  turnIndex : 0,
                  targets: [],
                  targetParts : [],
                  extraData: {}                
                )
            },

            (Arts.TARGET_MODE.RANDOM): ::<={
              @all = [];
              foreach(allies)::(index, ally) {
                all->push(value:ally);
              }
              foreach(enemies)::(index, enemy) {
                all->push(value:enemy);
              }

              battleAction=
                BattleAction.new(
                  card,
                  turnIndex : 0,
                  targets: random.pickArrayItem(list:all),
                  targetParts : [DAMAGE_TARGET.BODY],
                  extraData: {}                
                )
            }
          }  
        },
        
        onLeave ::{
          if (battleAction != empty)
            commitAction(action:battleAction)
          else if (onCancel)
            onCancel();
        }
      )
    },
    
    
    chooseDiscard::(
      act,
      onChoice
    ) {
      @:this = _.this;
      @:deck = _.deck;
      @:world = import(module:'game_singleton.world.mt');

      when(world.party.leader == this) 
        deck.chooseDiscardPlayer(
          act,
          onChoice
        )
        
      onChoice(id:deck.chooseDiscardRandom());
    },
    

    discardArt::(chosenBy) {
      if (_.deck == empty)
        error(detail: 'Can\'t discard when not in battle.');
        
      @:this = _.this;
      @:deck = _.deck;
      @:world = import(module:'game_singleton.world.mt');
      
      if (chosenBy == empty) ::<= {
        if (world.party.leader == this)
          deck.discardPlayer()
        else ::<= {
          windowEvent.queueMessage(
            text: this.name + ' discards an Art.'
          );
          deck.discardRandom()        
        }
      } else ::<= {
        if (world.party.leader == chosenBy) ::<= {
          deck.discardPlayer()
        } else ::<= {
          @:which = deck.discardRandom()        
          windowEvent.queueMessage(
            text: this.name + ' is told to discard the Art: ' + Arts.find(:which.id).name + ' by ' + chosenBy.name + '.' 
          );
        }      
      }
    },
    
    react::(source, onReact) {
      if (_.deck == empty)
        error(detail: 'Can\'t react when not in battle.');
      @:priv = _;
      @:this = _.this;
      @:state = _.state;
      @:abilitiesUsedBattle = _.abilitiesUsedBattle;
      @:deck = _.deck;
      @:world = import(module:'game_singleton.world.mt');

      when (this.canUseReactions() == false)
        onReact();
      
      @:chooseReact::(action) {
        when(action == empty)
          onReact();


        @:card = action.card;

        @:art = Arts.find(:card.id);
        when (abilitiesUsedBattle != empty && ((art.traits & Arts.TRAIT.ONCE_PER_BATTLE) != 0) && abilitiesUsedBattle[card.id] == true) ::<= {
          windowEvent.queueMessage(
            text: this.name + " tried to use " + art.name + ", but already was used and could not be used again!"
          ) 
          onReact()
        }
        @:rets = this.effectStack.emitEvent(
          name: 'onPreReact',
          card: card
        );
        
        // event cancelled reaction.
        when (rets->findIndexCondition(::(value) <- value.returned == false) != -1) onReact();


        if (abilitiesUsedBattle) abilitiesUsedBattle[art.id] = true;

        onReact(:action);

        @:rets = this.effectStack.emitEvent(
          name: 'onPostReact',
          card: card
        );

      
      }

      if (world.party.leader == this) ::<= {
        windowEvent.queueMessage(
          text: '' + this.name + ' is able to react to this Art. You can either choose a Reaction Art or cancel to pass.'
        );
        
        windowEvent.queueCustom(
          onEnter :: {
            deck.chooseArtPlayer(
              user:this,
              act: 'React',
              canCancel: true,
              filter::(value) <- Arts.find(:value.id).kind == Arts.KIND.REACTION,
              onChoice::(
                card
              ) {
                this.playerUseArt(
                  card, 
                  commitAction::(action) {
                    chooseReact(:action)                    
                  }
                );
              },
              
              onCancel ::{
                onReact();
              }
            )
          }
        )
      } else ::<= {
        state.battleAI.chooseReaction(
          source,
          battle:priv.battle,
          onCommit ::(action) {
            chooseReact(
              action
            );
          }
        );
      }
    },
    
    drawArt ::(count) {
      if (_.deck == empty)
        error(detail: 'Can\'t draw when not in battle.');
        
      @:this = _.this;
      @:deck = _.deck;
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
          if (q.appearanceChance == 1 || random.number() < q.appearanceChance)
            qualities->push(value:EntityQuality.new(base:q));
        }
      }
    
      @out = this.name + ' is ' + correctA(word:state.species.name) + '. ';
      @:quals = random.scrambled(list:qualities);

      // inefficient, but idc        
      @:describeDual::(qual0, qual1, index) {
        return random.pickArrayItem(list:[
          'They have ' + (if (qual0.plural == true || qual0.countable == false) qual0.name else correctA(:qual0.name)) + 
              (if (qual0.plural) ' that are ' else ' that is ') 
            + qual0.description + ', and their '
            + qual1.name + 
              (if (qual1.plural) ' are ' else ' is ') 
            + qual1.description + '. ',

          'They have ' + (if (qual0.plural == true || qual0.countable == false) qual0.name else correctA(:qual0.name)) + 
              (if (qual0.plural) ' that are ' else ' that is ') 
            + qual0.description + ', and their '
            + qual1.name + 
              (if (qual1.plural) ' are ' else ' is ') 
            + qual1.description + '. ',

            
          this.name + '\'s ' + qual0.name + 
              (if (qual0.plural) ' are ' else ' is ') 
            + qual0.description + ', and they have '
            + (if (qual1.plural == true || qual1.countable == false) qual1.name else correctA(word:qual1.name)) + 
              (if (qual1.plural && qual1.countable) ' which are ' else ' which is ') 
            + qual1.description + '. ',
        ]);
      }

      @:describeSingle::(qual, index) {
        return random.pickArrayItem(list:[
          this.name + '\'s ' + qual.name + 
              (if (qual.plural && qual.countable) ' are ' else ' is ') 
            + qual.description + '. ',

          'Their ' + qual.name + 
              (if (qual.plural && qual.countable) ' are ' else ' is ') 
            + qual.description + '. ',              

          'Their ' + qual.name + 
              (if (qual.plural && qual.countable) ' are ' else ' is ') 
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
      ::? {
        forever ::{
          when(quals->keycount == 0) send();
          
          @single = if (quals->keycount >= 2) (random.number() < 0.5) else true;
          
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
   
      
    describe::(excludeStats, showFeelings)  {
      @:state = _.state;
      @:this = _.this;
      @:plainStatsState = this.stats.save();
      @:plainStats = StatSet.new();
      plainStats.load(serialized:plainStatsState);
      plainStats.resetMod();


      
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
        speakers: [ 
          this.name + ': Summary',
          this.name + ': ' + if (excludeStats != true) '(Base -> w/Mods.)' else '',
          this.name + ': Description',
          this.name + ': Thinking about...?',
          this.name + ': Equipment',
          this.name + ': Effects'
        ],
          
        pageAfter:canvas.height-4,
        set: [ 
          '       Name: ' + this.name + '\n\n' +
          '         HP: ' + this.hp + ' / ' + this.stats.HP + '\n' + 
          '         AP: ' + this.stats.AP + '\n\n' + 
          '    Species: ' + state.species.name + '\n' +
          ' Profession: ' + this.profession.name + '\n' +
          ' Fave. wep.: ' + state.faveWeapon.name + '\n' +
          'Personality: ' + state.personality.name + '\n' +
          '   Starsign: ' + '"' + STARSIGN_NAMES[state.affinity] + '"\n\n' 
          ,
          
          if (excludeStats != true)
            StatSet.diffToLines(
              stats:plainStats, 
              other:state.stats
            )->reduce(
              ::(previous, value) <- 
                if (previous != empty) 
                  previous + '\n' + value
                else 
                  value
            )
          else
            '', 
          this.describeQualities(),
          
          if (showFeelings)
            getFeelings(this, state)
          else 
            ''
          ,
           
              'hand(l): ' + this.getEquipped(slot:EQUIP_SLOTS.HAND_LR).name + '\n'
            + 'hand(r): ' + getRightHandName() + '\n'
            + 'armor  : ' + this.getEquipped(slot:EQUIP_SLOTS.ARMOR).name + '\n'
            + 'amulet : ' + this.getEquipped(slot:EQUIP_SLOTS.AMULET).name + '\n'
            + 'trinket: ' + this.getEquipped(slot:EQUIP_SLOTS.TRINKET).name + '\n'
            + 'ring(l): ' + this.getEquipped(slot:EQUIP_SLOTS.RING_L).name + '\n'
            + 'ring(r): ' + this.getEquipped(slot:EQUIP_SLOTS.RING_R).name + '\n'
          ,
            
           if (effects != empty) ::<= {
            @out = '';
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
