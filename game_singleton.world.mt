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
@:Island = import(module:'game_mutator.island.mt');
@:Party = import(module:'game_class.party.mt');
@:Battle = import(module:'game_class.battle.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:State = import(module:'game_class.state.mt');
@:random = import(:'game_singleton.random.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');

@:TIME = {
  DAWN : 0,
  EARLY_MORNING : 1,
  MORNING : 2,
  LATE_MORNING: 3,
  MIDDAY: 4,
  AFTERNOON: 5,
  LATE_AFTERNOON: 6,
  SUNSET: 7,
  EARLY_EVENING: 8,
  EVENING: 9,
  LATE_EVENING: 10,
  MIDNIGHT: 11,
  DEAD_HOUR: 12,
  DEAD_NIGHT: 13
}

@:SEASON = {
  SPRING : 0,
  SUMMER : 1,
  AUTUMN : 2,
  WINTER : 3
}

// assume walking speed is about 5km/hr
// each "step" is about 2m 
// each "turn" is about 1/4km (125 steps raw, but assume theres some waiting time, so lets say 60)
// each "hour" is about 20 turns
// each "day" is exactly 14 hours 
// each "year" is 100 days 

@:STEPS_PER_TURN = 60;
@:TURNS_PER_HOUR = 20;
@:HOURS_PER_DAY  = 14;
@:DAYS_PER_YEAR  = 80; // match starsign, one for each 10 days


@:ACCOLADE_LIST = {

  // accolades

  
  // "The true Chosen."
  acceptedQuest : Boolean, // beat Wyvern of Darkness
  
  // "Let's be friends?"
  wyvernsRevisited : Boolean,

  // "I'd buy that for a dollar! Barely."
  boughtWorthlessItem : Boolean,

  // "You know, there were some pretty powerful people you didn't have in your party that would have made your quest a lot easier. Good job!"
  recruitedOPNPC : Boolean, // if FALSE/empty is an accolade

  // "Not-so-thrifty spender!"
  boughtItemOver2000G : Boolean,
  
  // "Where did you find that thing?"
  soldItemOver500G : Boolean,

  // "No really, where did you find that thing?"
  soldWorthlessItem : Boolean,

  
  // "Lucky, lucky!"
  wonGamblingGame : Boolean,
  
  // "Honestly, the Arena is a little brutal..."
  wonArenaBet : Boolean,
  
  // "My pockets feel lighter..."
  hasStolen : Boolean,
  
  // "Should have kicked them out a while ago."
  foughtDrunkard : Boolean,
  
  // "Property destruction is hard sometimes."
  hasVandalized : Boolean,

  // "I guess it wasn't that important..."
  gotRidOfWyvernKey : Boolean,

  // "The traps were kind of fun to setup, to be honest."
  trapsFallenFor : Number, // if over 5, is an accolade

  // "Two's company but three's a crowd! ...Assuming no one died."
  recruitedCount : Number, // if over 0, is an accolade 
  
  // "Top-notch boxer."
  knockouts : Number, // if over 40, is an accolade
  
  // "You're so nice and not murder-y!"
  murders : Number, // if equal to 0, is an accolade
  
  // "A trustworthy friend."
  deadPartyMembers : Number, // if 0, is an accolade 
  
  // "Tinkerer!"
  itemImprovements : Number, // if over 5, is an accolade 
  
  // "Someone was thirsty I guess."
  drinksTaken : Number, // if above 15, is an accolade
  
  // "Smart fella."
  intuitionGained : Number, // if above 5, is an accolade

  // "Thrifty spender!"
  buyCount : Number, // if above 20, is an accolade

  // "Easy money."
  sellCount : Number, // if above 20, is an accolade

  // "Someone likes Roman numerals."
  enchantmentsReceived : Number, // if above 5, is an accolade
  
  // "Well, that was a waste of time."
  daysTaken : Number, // if below 10 ingame days, is an accolade
  
  // "Finders, keepers!"
  chestsOpened : Number, // if above 15, is an accolade
  
  // "Either you've done research, or you're really adventurous. Awesome job!
  accoladeCount : Number, // if equal to all accolades, is an accolade
}


@:World = LoadableClass.create(
  name: 'Wyvern.World',
  items : {
    saveName : '',
    // 10 steps per turn
    // 10 turns per "time"
    // 14 times per "day"
    // 100 days per "year"
    step : 0,
    turn : 0,
    time : TIME.LATE_MORNING,
    day : 0,
    year : 1033,
    party : empty,
    currentIslandID : 0,
    currentLandmarkID : 0,
    idPool : 1,
    disgruntled : false,
    story : empty,
    npcs : empty,
    finished : false,
    wish : "",
    scenario : empty,
    accolades : empty,
    data : empty
  },  
  

  define:::(this, state) {

    @battle = Battle.new();
    @island = empty;
    @landmark = empty;


    // intialize NPCs if they havent been already
    @:initializeNPCs ::{
      // already loaded from file.
      if (state.npcs != empty) empty;
      
      @:Entity = import(module:'game_class.entity.mt');
      @:EntityQuality = import(module:'game_mutator.entityquality.mt');
      @:Item = import(module:'game_mutator.item.mt');
      @:story = import(module:'game_singleton.story.mt');
      
      @:currentIsland = this.island;
      
      this.island = Island.new(
        base : Island.database.find(:'base:none'),
        createEmpty : true
      );
      
      state.npcs = {
        faus : ::<= {
          @:ent = Entity.new(
            speciesHint: 'base:rabbit',
            professionHint: 'base:summoner',
            personalityHint: 'base:caring',
            levelHint: 20,
            adventurousHint: true,
            innateEffects : [
              'base:seasoned-adventurer'
            ],
            qualities : [
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:snout'), trait0Hint:0),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:fur'),   descriptionHint: 6, trait0Hint:10, trait2Hint:3),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:eyes'),  descriptionHint: 3, trait2Hint:6, trait1Hint: 0),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:ears'),  descriptionHint: 1, trait0Hint:2),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:face'),  descriptionHint: 0, trait0Hint:3),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:tail'),  descriptionHint: 0, trait0Hint:0),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:body'),  descriptionHint: 1, trait0Hint:0, trait1Hint:0),      
            ]
          );



          @:fausWeapon = Item.new(
            base: Item.database.find(id: 'base:morning-star'),
            rngEnchantHint: false,
            qualityHint: 'base:masterwork',
            materialHint: 'base:mythril',
            colorHint: 'base:gold',
            enchantHint: ['base:aura-gold'],
            forceEnchant: true
          );
          fausWeapon.maxOut();
          
          @:fausRobe = Item.new(
            base: Item.database.find(id: 'base:robe'),
            rngEnchantHint: false,
            qualityHint: 'base:masterwork',
            colorHint: 'base:black',
            apparelHint: 'base:mythril',
            forceEnchant: true
          );
          fausRobe.maxOut();


          @:fausCloak = Item.new(
            base: Item.database.find(id: 'base:cloak'),
            rngEnchantHint: false,
            qualityHint: 'base:masterwork',
            colorHint: 'base:olive-green',
            apparelHint: 'base:mythril',
            forceEnchant: true
          );
          fausCloak.maxOut();

          ent.supportArts = [
            'base:cancel',
            'base:prismatic-wisp',
            'base:pebble',
            'base:quick-shield',
            'base:bloods-summoning',
            'base:banish',
            'base:shield-amplifier',
            'base:banishing-light',
            'base:greater-banish'
          ];
          
          
          ent.equip(item:fausWeapon, slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
          ent.equip(item:fausCloak,  slot:Entity.EQUIP_SLOTS.TRINKET, silent:true);
          ent.equip(item:fausRobe,   slot:Entity.EQUIP_SLOTS.ARMOR, silent:true);

          ent.heal(
            amount: 9999,
            silent: true
          );


          ent.name = 'Faus';          
          return ent;
        },
      
      
        sylvia : ::<= {
          @:ent = Entity.new(
            speciesHint: 'base:kobold',
            professionHint: 'base:alchemist',
            personalityHint: 'base:inquisitive',
            levelHint: story.levelHint-1,
            adventurousHint: true,
            qualities : [
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:snout'), trait0Hint:0),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:scales'),   descriptionHint: 0, trait0Hint:5),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:eyes'),  descriptionHint: 3, trait2Hint:0, trait1Hint: 3),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:face'),  descriptionHint: 4, trait0Hint:0, trait1Hint:0),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:tail'),  descriptionHint: 0, trait0Hint:1),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:body'),  descriptionHint: 1, trait0Hint:0, trait1Hint:2),      
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:horns'), descriptionHint: 6, trait0Hint:2, trait1Hint:1)
            ]              
          );


          @:sylvWeapon = Item.new(
            base: Item.database.find(id: 'base:tome'),
            rngEnchantHint: true,
            qualityHint: 'base:durable',
            materialHint: 'base:moonstone',
            colorHint: 'base:gold',
            forceEnchant: true
          );
          sylvWeapon.maxOut();
          
          @:sylvRobe = Item.new(
            base: Item.database.find(id: 'base:robe'),
            rngEnchantHint: true,
            qualityHint: 'base:sturdy',
            colorHint: 'base:brown',
            apparelHint: 'base:cloth',
            forceEnchant: true
          );
          sylvRobe.maxOut();
          
          @:sylvAcc = Item.new(
            base: Item.database.find(id: 'base:hat'),
            rngEnchantHint: true,
            qualityHint: 'base:sturdy',
            colorHint: 'base:brown',
            apparelHint: 'base:leather',
            forceEnchant: true
          );
          sylvAcc.maxOut();
          
          ent.equip(item:sylvWeapon, slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
          ent.equip(item:sylvRobe,   slot:Entity.EQUIP_SLOTS.ARMOR, silent:true);
          ent.equip(item:sylvAcc,  slot:Entity.EQUIP_SLOTS.TRINKET, silent:true);

          ent.supportArts = [
            'base:cancel',
            'base:prismatic-wisp',
            'base:pebble',
            'base:quick-shield',
            'base:bloods-summoning',
            'base:banish',
            'base:shield-amplifier',
            'base:banishing-light',
            'base:greater-banish'
          ];


          ent.name = 'Sylvia';
          return ent;          
        },
        mei : ::<= {
          @:ent = Entity.new(
            speciesHint: 'base:sheep',
            professionHint: 'base:cleric',
            personalityHint: 'base:caring',
            levelHint: story.levelHint-1,
            adventurousHint: true,
            innateEffects : [
              'base:seasoned-adventurer'
            ],
            qualities : [
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:snout'), trait0Hint:2),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:fur'),   descriptionHint: 0, trait0Hint:8),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:eyes'),  descriptionHint: 0, trait2Hint:0, trait1Hint: 0),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:ears'),  descriptionHint: 2, trait0Hint:2),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:face'),  descriptionHint: 0, trait0Hint:0),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:tail'),  descriptionHint: 0, trait0Hint:0),
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:body'),  descriptionHint: 1, trait0Hint:0, trait1Hint:5),      
              EntityQuality.new(base: EntityQuality.database.find(id: 'base:horns'), descriptionHint: 1, trait0Hint:2, trait1Hint:1)
            ]
          );



          @:meiWeapon = Item.new(
            base: Item.database.find(id: 'base:falchion'),
            rngEnchantHint: true,
            qualityHint: 'base:quality',
            materialHint: 'base:dragonglass',
            colorHint: 'base:pink',
            forceEnchant: true
          );
          meiWeapon.maxOut();
          
          @:meiRobe = Item.new(
            base: Item.database.find(id: 'base:robe'),
            rngEnchantHint: true,
            qualityHint: 'base:masterwork',
            colorHint: 'base:pink',
            apparelHint: 'base:wool-plus',
            forceEnchant: true
          );
          meiRobe.maxOut();
          
          @:meiAcc = Item.new(
            base: Item.database.find(id: 'base:meis-bow'),
            rngEnchantHint: true,
            forceEnchant: true
          );
          
          ent.equip(item:meiWeapon, slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
          ent.equip(item:meiRobe,   slot:Entity.EQUIP_SLOTS.ARMOR, silent:true);
          ent.equip(item:meiAcc,  slot:Entity.EQUIP_SLOTS.TRINKET, silent:true);

          ent.heal(
            amount: 9999,
            silent: true
          );

          ent.supportArts = [
            'base:cancel',
            'base:prismatic-wisp',
            'base:pebble',
            'base:quick-shield',
            'base:bloods-summoning',
            'base:banish',
            'base:shield-amplifier',
            'base:banishing-light',
            'base:greater-banish'
          ];

          ent.name = 'Mei';
          return ent;
        },
        
        skie : ::<= {
          @:ent = Entity.new(
            speciesHint:'base:drake-kin',
            professionHint: 'base:runologist',
            levelHint: story.levelHint-1,
            adventurousHint: true,
            innateEffects : [
              'base:seasoned-adventurer'
            ]
          );
          
          @:skieWeapon = Item.new(
            base: Item.database.find(id: 'base:tome'),
            rngEnchantHint: true,
            qualityHint: 'base:legendary',
            materialHint: 'base:mythril',
            colorHint: 'base:gold',
            forceEnchant: true
          );
          skieWeapon.maxOut();
          
          @:skieRobe = Item.new(
            base: Item.database.find(id: 'base:robe'),
            rngEnchantHint: true,
            qualityHint: 'base:legendary',
            colorHint: 'base:silver',
            apparelHint: 'base:eversilk',
            forceEnchant: true
          );
          skieRobe.maxOut();

          @:skieCloak = Item.new(
            base: Item.database.find(id: 'base:cloak'),
            rngEnchantHint: false,
            qualityHint: 'base:sturdy',
            colorHint: 'base:black',
            apparelHint: 'base:mythril',
            forceEnchant: true
          );
          skieCloak.maxOut();

          ent.supportArts = [
            'base:cancel',
            'base:prismatic-wisp',
            'base:pebble',
            'base:quick-shield',
            'base:bloods-summoning',
            'base:banish',
            'base:shield-amplifier',
            'base:banishing-light',
            'base:greater-banish'
          ];            
          
          ent.equip(item:skieWeapon, slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
          ent.equip(item:skieRobe,   slot:Entity.EQUIP_SLOTS.ARMOR, silent:true);
          ent.equip(item:skieCloak,  slot:Entity.EQUIP_SLOTS.TRINKET, silent:true);

          
          ent.name = 'Skie';
          return ent;          
        }
      } 
      island = currentIsland;
      
          
    };


    
    @:getDayString = ::{
      return match(state.time) {
        (TIME.DAWN): 'It is dawn.',
        (TIME.EARLY_MORNING): 'It is early morning.',
        (TIME.MORNING): 'It is mid-morning.',
        (TIME.LATE_MORNING): 'It is late in the morning.',
        (TIME.MIDDAY): 'It is midday.',
        (TIME.AFTERNOON): 'It is the afternoon.',
        (TIME.LATE_AFTERNOON): 'It is late in the afternoon.',
        (TIME.SUNSET): 'The sun is setting.',
        (TIME.EARLY_EVENING): 'It is starting to get dark out.',
        (TIME.EVENING): 'It is night out.',
        (TIME.LATE_EVENING): 'It is late night.',
        (TIME.MIDNIGHT): 'It is midnight.',
        (TIME.DEAD_HOUR): 'It is the dead hour.',
        (TIME.DEAD_NIGHT): 'It is the dead of the night.'
      }
    }
    
    @:getSeasonString = ::{
      return match(this.season) {
        (SEASON.SPRING): 'Spring',       
        (SEASON.SUMMER): 'Summer',       
        (SEASON.AUTUMN): 'Autumn',       
        (SEASON.WINTER): 'Winter'     
       }
    }
    
    
    this.interface = {
      initialize :: {
        state.story = import(module:'game_singleton.story.mt');
      },
      defaultLoad ::{
        state.day = (random.number()*100)->floor;
        state.party = Party.new();
        state.accolades = {};
        state.data = {};
      },    
      resetAll ::{
        state.saveName = '';
        state.step = 0;
        state.turn = 0;
        state.time = TIME.LATE_MORNING;
        state.day = (random.number()*100)->floor;
        state.year = 1033;
        state.party = Party.new();
        state.idPool = 0;
        state.story = empty;
        state.npcs = empty;
        state.finished = false;
        state.wish = "";
        state.scenario = empty;
        state.accolades = {};
        state.data = {};
        state.currentIslandID = -1
        state.currentLandmarkID = -1
        state.idPool = 1
        battle = Battle.new();
        island = empty;
      },
    
      TIME : {
        get ::<- TIME
      },
      SEASON : {
        get ::<- SEASON
      },
    
      timeString : {
        get :: {
          return 'Year ' + state.year +', ' + getSeasonString() + '. ' + getDayString();
        }
      },
      
      getDayString : getDayString,
      
      saveName : {        
        get :: {
          return state.saveName
        }
      },
            
      time : {
        get ::<- state.time
      },
      
      MAX_NORMAL_TIER : {
        get ::<- 4
      },
      
      day : {
        get ::<- state.day
      },
      
      season : {
        get :: {
          return match(true) {
            (state.day > 75): SEASON.WINTER,
            (state.day > 50): SEASON.AUTUMN,
            (state.day > 25): SEASON.SUMMER,
            default: SEASON.SPRING
          }
        }
      },

      
      party : {
        get ::<- state.party
      },
      
      island : {
        get ::<- island,
        set ::(value) <- island = value
      },
      
      wait::(until) {     
        ::? {
          forever ::{
            when(this.time != until) send()
            this.incrementTime();
          }
        }
        ::? {
          forever ::{
            when(this.time == until) send()
            this.incrementTime();
          }
        }
      },
      
      
      landmark : {
        get ::<- landmark,
        set ::(value) {
          @:Landmark = import(module:'game_mutator.landmark.mt');
          @:oldLandmark = landmark;
          if (landmark != empty && landmark.base.hasTraits(:Landmark.TRAIT.EPHEMERAL))
            landmark.unloadContent();
            
          @:isMean::(landmark) <- landmark != empty &&
                                  landmark.base.landmarkType == Landmark.TYPE.DUNGEON &&
                                  landmark.base.hasTraits(:Landmark.TRAIT.POINT_OF_NO_RETURN)

          @:isNotMean::(landmark) <- !isMean(landmark);
            
          landmark = value
          state.currentLandmarkID = -1;
          if (landmark) ::<= {
            landmark.loadContent();
            state.currentLandmarkID = landmark.worldID;
            foreach(this.party.quests) ::(k, quest) {
              quest.enterLandmark(:landmark);
            }
          }
          if (isMean(:oldLandmark) && isNotMean(:landmark))
            this.party.leaveDungeon(:oldLandmark);
          
          if (isNotMean(:oldLandmark) && isMean(:landmark))
            this.party.enterDungeon(landmark);
        }
      },
      
      
      scenario : {
        get ::<- state.scenario
      },

      
      getNextID ::{
        state.idPool += 1;
        return state.idPool-1;
      },
      
      battle : {
        get :: <- battle
      },
      
      storyFlags : {
        get :: <- state.story
      },
      
      npcs : {
        get ::<- state.npcs
      },
      
      setWish ::(wish) {
        state.wish = wish;
        state.finished = true;
      },
      
      finished : {
        get ::<- state.finished
      },
      
      wish : {
        get ::<- state.wish
      },
      
      incrementTime ::(isStep) {
        if (isStep == empty) ::<= {
          state.turn += 1;
          state.step = 0
        } else ::<= { 
          state.step += 1;
        }
        
        if (state.step >= STEPS_PER_TURN) ::<={
          state.turn += 1;
          state.step = 0;
        }
          
          
        @newHour = false;
        if (state.turn >= TURNS_PER_HOUR) ::<={
          state.turn = 0;
          state.time += 1;
          if (state.time == TIME.MORNING)
            this.scenario.onNewDay();
          newHour = true;
        }
          
          
        if (state.time >= HOURS_PER_DAY) ::<={
          state.time = 0;
          state.day += 1;
          this.accoladeIncrement(name:'daysTaken');
        }
        
        if (state.day >= DAYS_PER_YEAR) ::<={
          state.day = 0;
          state.year += 1;
        }        

        if (newHour && state.time == TIME.EVENING) ::<= {
          @:instance = import(:'game_singleton.instance.mt');
          if (instance.y) ::<= {
            windowEvent.queueMessage(
              text: '"What a horrible night to have a curse."'
            );  
          }
        }

        
        if (newHour && island != empty) ::<= {      
          foreach(this.party.quests) ::(k, v) {
            v.incrementTime(landmark:this, island:this.island);
          }

          island.incrementTime();
        }
      },
      
      accoladeIncrement ::(name) {
        when (ACCOLADE_LIST[name] != Number) empty;
          
        if (state.accolades[name] == empty)
          state.accolades[name] = 1 
        else 
          state.accolades[name] += 1
      },
      
      start ::(name, scenario, seed) {
        if (seed)
          random.seed(:seed)
        else
          random.seedRandom();
          
        this.resetAll();
        state.saveName = name;
        state.scenario = scenario;
        initializeNPCs();
        this.scenario.base.onBegin(data:this.scenario.data);
      
      },
      
      disgruntled : {
        get ::<- state.disgruntled,
        set ::(value) {
          state.disgruntled = true;
        }
      },
      
      accoladeCount ::(name) => Number { 
        return if (state.accolades[name] == empty) 0 else state.accolades[name]
      },
      
      accoladeEnabled ::(name) => Boolean {
        return if (state.accolades[name] == empty) false else state.accolades[name]
      },
      
      accoladeEnable ::(name) {
        when (ACCOLADE_LIST[name] != Boolean) empty;
        state.accolades[name] = true      
      },
      
      
      
      
      data : {
        get ::<- state.data
      },
      
      save ::{
        State.startRootSerializeGuard();
        // first load
        @:instance = import(:'game_singleton.instance.mt');
        @save = instance.getSaveDataRaw();
        if (save == empty)
          save = {};
      
        // then save the island and update the entry
        // the islands property is saved outside of the world.
        if (island != empty) ::<= {
          @:islandSave = island.save();
          
          // update the island.
          if (save.islands == empty)
            save.islands = [];
          save.islands[island.worldID] = islandSave;
        }        
        save.world = state.save();
        save.rng = random.save();

        // check to see if the current landmark is part of the current island. 
        // If it isnt, save it separately.
        if (state.currentLandmarkID != -1 && (::? {
            foreach(island.landmarks) ::(k, v) {
              if (v.worldID == state.currentLandmarkID)
                send(:false);
            }
            return true;
        })) ::<= {
          save.orphanedLandmark = this.landmark.save();
        } else ::<= {
          // just in case it was there before.
          save->remove(key:'orphanedLandmark');
        }

        // cleanup
        State.endRootSerializeGuard();
        State.weightEmplace(:save);
        return save;        
      },

      loadIslandID ::(id, islandGenTraits, skipSave, onDone => Function) {
        // first load existing save. The save has all the current islands 
        @:instance = import(:'game_singleton.instance.mt');

        @save = if (skipSave != true)
          instance.getSaveDataRaw();

        
        @:commitLoad :: {
          state.currentIslandID = id;
          if (alreadyLoaded != empty)
            island = alreadyLoaded 
          else ::<= {
            island = Island.new(base:Island.database.find(:'base:none'), createEmpty:true);
            State.weightCheck(:which);
            island.load(serialized:which);
          }
          

          // traveling always triggers a save.
          if (skipSave != true) ::<= {
            save.world = state.save();
            save.rng = random.save();
            State.weightEmplace(:save);
            instance.savestate(saveOverride:save);      
          }
          
          //when (skipLoadMap)
            onDone(:this.island);        
          /*
          this.island.loadMap(
            onDone::(map) {
              onDone(:this.island);        
            }
          );
          */
        }
        
        
        if (save == empty || save->keycount == 0) ::<= {
          save = this.save();
        }
        

        if (save.islands == empty)
          save.islands = [];
          
        if (island != empty)
          save.islands[island.worldID] = island.save();

        // retrieve, creating if it doesnt exist
        @which = save.islands[id];
        @alreadyLoaded;
        if (which == empty) ::<= {
          @:newIsland = Island.new(
            *{worldID : id, ...(if (islandGenTraits) islandGenTraits else {})}
          );
          island = newIsland;
          newIsland.loadMap(onDone ::(map) {
            alreadyLoaded = newIsland;
            
            // need a location too if first making.
            @gate = newIsland.landmarks->filter(by:::(value) <- value.base.id == 'base:wyvern-gate');
            when(gate->size == 0) empty;
            
            gate = gate[0];
            newIsland.map.setPointer(
              x: gate.x,
              y: gate.y
            );               
          
            save.islands[id] = newIsland.save(); 
            which = save.islands[id];

            commitLoad();          
          });
        } else 
          commitLoad();
      },

      // makes the key's island the current island. If the key's island 
      // doesnt exist, it is made, saved, and set to the island
      loadIsland ::(key, skipSave, onDone => Function) {
        // get ID if none exists
        if (key.islandID == 0) ::<= {
          key.islandID = this.getNextID();
        }

        this.loadIslandID(id:key.islandID, skipSave, islandGenTraits:key.islandGenTraits, onDone);
      },
     
      
      load ::(serialized) {
        State.startRootSerializeGuard();
        ::<= {
          if (!State.weightCheck(:serialized)) ::<= {
            @:instance = import(:'game_singleton.instance.mt');
            instance.x = true;
          }
        
          if (serialized.rng != empty)
            random.load(:serialized.rng);
          
          state.load(parent:this, serialized:serialized.world, loadFirst:['scenario']);
          
          island = Island.new(base:Island.database.find(:'base:none'), createEmpty:true);
          island.load(:serialized.islands[state.currentIslandID]);
          landmark = ::? {  
            foreach(island.landmarks) ::(k, v) {
              if (v.worldID == state.currentLandmarkID)
                send(:v);
            } 
            
            // orphanedLandmark
            when (state.currentLandmarkID != -1 && serialized.orphanedLandmark) ::<= {
              @:Landmark = import(module:'game_mutator.landmark.mt');
              @:l = Landmark.new(parent: island.map, state:serialized.orphanedLandmark);
              return l;
            }
            
            state.currentLandmarkID = -1;
            return empty;
          }
        }
        State.endRootSerializeGuard();
      }
    }
  }
);

return World.new();
