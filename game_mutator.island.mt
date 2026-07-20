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
@:random = import(module:'game_singleton.random.mt');
@:NameGen = import(module:'game_singleton.namegen.mt');
@:Species = import(module:'game_database.species.mt');
@:Entity = import(module:'game_class.entity.mt');
@:Landmark = import(module:'game_mutator.landmark.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:LargeMap = import(module:'game_singleton.largemap.mt');
@:Party = import(module:'game_class.party.mt');
@:Profession = import(module:'game_database.profession.mt');
@:IslandEvent = import(module:'game_mutator.islandevent.mt');
@:State = import(module:'game_class.state.mt');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:Database = import(module:'game_class.database.mt');
@:correctA = import(module:'game_function.correcta.mt');


@:CLIMATE = {
  WARM : 0,
  TEMPERATE : 1,
  DRY : 2,
  RAINY : 3,
  HUMID : 4,
  SNOWY : 5,
  COLD : 6
}

@:hexKey = [
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  'a',
  'b',
  'c',
  'd',
  'e',
  'f'
];

@:TRAIT = {
  // Diverse islands ignore the species predisposition.
  // An inhabitant can be any non-special species.
  DIVERSE : 1,
  
  SPECIAL : 2,
  
  // the island skips generation entirely.
  EMPTY : 4
}

@:levelGen ::(level) {
  when(level <= 8) level;
  when(level < 16) (level + random.integer(from:-1, to:1));
  @:dev = level * 0.2;
  @min = level-dev;
  @max = level+dev;
  if (min < 0) min = 1;
  if (max < 0) max = 1;
  return random.integer(from:min, to:max);
}

@:reset = :: {

Island.database.newEntry(
  data : {
    id : 'base:none',
    requiredLandmarks : [
    ],
    possibleLandmarks : [
      
    ],
    minAdditionalLandmarkCount : 0,
    maxAdditionalLandmarkCount : 0,
    minSize : 1,//80,
    maxSize : 1, //130,
    events : [
      
    ],
    possibleSceneryCharacters : [
      '╿', '.', '`', '^', ','
    ],
    traits : TRAIT.SPECIAL | TRAIT.EMPTY,
    
    overrideSpecies : empty,
    overrideNativeCreatures : empty,
    overridePossibleEvents : empty,
    overrideClimate : empty,  
  }
)


Island.database.newEntry(
  data : {
    id : 'base:starting-island',
    requiredLandmarks : [
      'base:town-start',
      'base:wyvern-gate',
    ],
    possibleLandmarks : [
      
    ],
    minAdditionalLandmarkCount : 0,
    maxAdditionalLandmarkCount : 0,
    minSize : 40,//80,
    maxSize : 60, //130,
    events : [
      'base:bbq',
      'base:weather:1',
      'base:camp-out',
      'base:encounter:normal'      
    ],
    possibleSceneryCharacters : [
      '╿', '.', '`', '^', ','
    ],
    traits : TRAIT.DIVERSE | TRAIT.SPECIAL,
    
    overrideSpecies : empty,
    overrideNativeCreatures : empty,
    overridePossibleEvents : empty,
    overrideClimate : empty,  
  }
)


Island.database.newEntry(
  data : {
    id : 'base:normal-island',
    requiredLandmarks : [
      'base:wyvern-gate',
      'base:lost-shrine',
      'base:city'
    ],
    possibleLandmarks : [
      'base:town',
      'base:forest',
      'base:villa',
      'base:mine',
      'base:village',
    ],
    minAdditionalLandmarkCount : 1,
    maxAdditionalLandmarkCount : 3,
    minSize : 30,//80,
    maxSize : 130, //130,
    events : [
      'base:bbq',
      'base:weather:1',
      'base:camp-out',
      'base:encounter:normal'
    ],
    possibleSceneryCharacters : [
      '╿', '.', '`', '^', ',',
      ')', '(', ']', ']', '/',
      '+', '~', '=', '|', '>',
      '<', '*', '%', '-', '_'
    ],    
    traits : 0,
    overrideSpecies : empty,
    overrideNativeCreatures : empty,
    overridePossibleEvents : empty,
    overrideClimate : empty,  
  }
)


}


@:addLandmarkDefaults = ::<= {

  @:clearScenery::(map, x, y) {
    @index = map.addScenerySymbol(character:' ');

    for(x-1, x+2) ::(ix) {
      for(y-1, y+2) ::(iy) {
        when (ix < 0 || iy < 0) empty;
        map.setSceneryIndex(x:ix, y:iy, symbol:index);
      }
    }
  }   

  return ::(map, island, base) {
    @:loc = if (map.areas->size == 0)
      ({x:0, y:0})
    else
      random.scrambled(:map.areas)[0];
      
      
    @:x = loc.x;      
    @:y = loc.y;      
    @:landmark = Landmark.new(
      island,
      base,
      x,
      y
    );

    if (x != 0 && y != 0)
      clearScenery(map, x, y);
    island.addLandmark(landmark);
    return landmark;
  }
}

@:Island = databaseItemMutatorClass.create(  
  name : 'Wyvern.Island',
  statics : {
    CLIMATE : {get::<-CLIMATE},
    TRAIT : {get::<-TRAIT},
    
    climateToString::(climate) {
      return match(climate) {
        (0): 'warm',
        (1): 'temperate',
        (2): 'dry',
        (3): 'rainy',
        (4): 'humid',
        (5): 'snowy',
        (6): 'cold'     
      }
    },
    
    
    describeEncounterRate::(rate) {
      return match(true) {
        (rate < 0.2): 'It is peaceful.',
        (rate < 0.4): 'It is generally peaceful.',
        (rate < 0.6): 'It is relatively peaceful',
        (rate < 0.8): 'It is slightly chaotic.',
        default: 'It is very chaotic.'
      }
     }
  },
  
  items : {
    name : '',

    // the base of the island
    base : empty,

    // maximum level of encountered individuals
    level : 0,

    // how often encounters happen between turns.
    encounterRate: 0,    

    // Size of the island... Islands are always square-ish
    sizeW : 0,
    sizeH : 0,

    // steps since the last event
    steps : 0,

    // map of the region
    map : empty,

    worldID : -1,


    climate : 0,

    events : empty,


    // the tier of the island. This determines the difficulty
    // tier 0-> enemies have no skills or equips. Large chests drop Fire keys 
    // tier 1-> enemies have 1 to 2 skills, but have no equips. Large chests drop Ice keys 
    // tier 2-> enemies have 1 to 2 skills and have weapons. Large chests drop Thunder keys 
    // tier 3-> enemies have all skills and have equips. Large chests drop Light keys
    // tier 4-> enemies have a random set of all skills and have full equip sets.
    tier : 0,


    // every island has hostile creatures.
    nativeCreatures : empty,

    //Within these, there are 2-6 predominant races per island,
    //usually in order of population distribution
    species : empty,
    
    // Whether the island experiences the normal set of possible events
    possibleEvents : empty,

    data : empty,
    
    // explored areas of the island. May or may not have a map marking
    areas : empty,
    
    // landmarks that are not part of the map.
    // added to when adding a landmark with the unmapped flag
    unmappedLandmarks : empty,
  },
  
  database : Database.new(
    name : 'Wyvern.Island.Base',
    attributes : {
      id : String,
      requiredLandmarks : Object,
      possibleLandmarks : Object,
      minAdditionalLandmarkCount : Number,
      maxAdditionalLandmarkCount : Number,
      minSize : Number,
      maxSize : Number,
      events : Object,
      possibleSceneryCharacters : Object,
      
      overrideSpecies : Nullable,
      overrideNativeCreatures : Nullable,
      overridePossibleEvents : Nullable,
      overrideClimate : Nullable,
      traits : Number
    },
    reset
  ),
  
  
  define:::(this, state) {
   
    // the world
    @world_;

    // current party
    @party_;

    

    // augments an entity based on the current tier
    @augmentTiered = ::(entity) {
      @:instance = import(:'game_singleton.instance.mt');
      @:Arts = import(module:'game_mutator.arts.mt');

      // Assigns support arts for every entity.
      @:assignSupportArts::(entity, professionLevel, removeBasicCount) {
        
        for(0, professionLevel) ::(i) {
          entity.autoLevelProfession(:entity.profession);
        }
        entity.equipAllProfessionArts();
      }

    
      @tier = state.tier + 10*instance.y;
      if (instance.y)
        instance.x = true;
      match(tier) {
        (0):::<= {
          assignSupportArts(
            entity,
            professionLevel : 1
          );
        }, // tier zero has no mods 

        // tier 1: learn 1 to 2 skills
        (1):::<= {
          assignSupportArts(
            entity,
            professionLevel : 2
          );
        },
        

        // tier 2: learn 1 to 2 skills and get equips
        (2):::<= {
          
          @:Item = import(module:'game_mutator.item.mt');
          // add a weapon
          @:wep = Item.database.getRandomFiltered(
            filter:::(value) <-
              value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
              value.traits & Item.TRAIT.WEAPON
          );
            
          entity.equip(
            slot:Entity.EQUIP_SLOTS.HAND_LR, 
            item:Item.new(
              base:wep,
              materialHint : 'base:iron'
            ), 
            inventory:entity.inventory, 
            silent:true
          );
          
          
          assignSupportArts(
            entity,
            professionLevel : 3
          );


        },
        


        // tier 3: learn 1 to 2 skills and get equips
        (3):::<= {
          
          @:Item = import(module:'game_mutator.item.mt');
          // add a weapon
          @:wep = Item.database.getRandomFiltered(
            filter:::(value) <-
              value.hasNoTrait(:Item.TRAIT.UNIQUE)&&
              value.traits & Item.TRAIT.WEAPON
          );
            
          entity.equip(
            slot:Entity.EQUIP_SLOTS.HAND_LR, 
            item:Item.new(
              base: wep,
              materialHint : 'base:iron'
            ), 
            inventory:entity.inventory, 
            silent:true
          );
          
          assignSupportArts(
            entity,
            professionLevel : 4
          );

        },
        
        
        // tier 2: learn 1 to 2 skills and get equips
        default: ::<= {

          
          @:Item = import(module:'game_mutator.item.mt');
          // add a weapon
          @:wep = Item.database.getRandomFiltered(
            filter:::(value) <-
              value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
              value.traits & Item.TRAIT.WEAPON
          );
            
          entity.equip(
            slot:Entity.EQUIP_SLOTS.HAND_LR, 
            item:Item.new(
              base:wep,
              rngEnchantHint : true
            ), 
            inventory:entity.inventory, 
            silent:true
          );


          // add some armor!
          @:wep = Item.database.getRandomFiltered(
            filter:::(value) <-
              value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
              value.equipType == Item.TYPE.ARMOR
          );;
            
          entity.equip(
            slot:Entity.EQUIP_SLOTS.ARMOR, 
            item:Item.new(
              base: wep,
              rngEnchantHint : true
            ), 
            inventory:entity.inventory, 
            silent:true
          );

          assignSupportArts(
            entity,
            professionLevel : 8,
            removeBasicCount : 4
          );
        }       
        
        
      }  
      
      entity.equipAllProfessionArts();  
    }


    
    this.interface = {
      initialize:: { 
        @:world = import(module:'game_singleton.world.mt');
        @:party = world.party;

        world_ = world;      
        party_ = party;
      
      },

      
      defaultLoad::(base, createEmpty, worldID, levelHint, nameHint, tierHint, possibleEventsHint, hasSpeciesBias) {
        when(createEmpty) empty;
        @:world = import(module:'game_singleton.world.mt');

        @:oldIsland = world.island;
        world.island = this;
 
        ::<= {
          @factor = random.number()*50 + 80;
          @sizeW  = (factor)->floor;
          @sizeH  = (factor*0.5)->floor;
          
          state.base = base;
          state.name = NameGen.island();
          state.level = 0;
          state.possibleEvents = if (possibleEventsHint) possibleEventsHint else [...base.events];
          state.encounterRate = random.number();
          state.sizeW  = sizeW;
          state.sizeH  = sizeH;
          state.unmappedLandmarks = [];

          if (state.sizeW < base.minSize) state.sizeW = base.minSize;
          if (state.sizeW > base.maxSize) state.sizeW = base.maxSize;
          if (state.sizeH < base.minSize) state.sizeH = base.minSize;
          if (state.sizeH > base.maxSize) state.sizeH = base.maxSize;

          state.steps = 0;
          state.worldID = worldID;
          state.climate = random.integer(
            from:Island.CLIMATE.WARM, 
            to  :Island.CLIMATE.COLD
          );
          state.events = []; //array of Events
          state.tier = 0;
          state.nativeCreatures = [
            NameGen.creature(),
            NameGen.creature(),
            NameGen.creature()
          ];
          state.species = ::<={
            @rarity = 1;
            return [
              ... Species.getRandomSet(
                  count : 2,
                  filter:::(value) <- (value.traits & Species.TRAIT.SPECIAL) == 0
                )
            ]->map(
              to :::(value) <- {
                species: value.id,
                rarity : rarity *= 1.4
              }
            );
          };
        };
        
      
      
        state.tier = tierHint;

        state.level = levelHint; //(levelHint - random.number() * (levelHint * 0.2))->round;
        if (state.level < 1) state.leven = 1;
        if (nameHint != empty)
          state.name = (nameHint) => String;

        @rarity = 1;

        
    


        
        world.island = oldIsland;
        return this;
      },
      
      
      // Takes a good amount of time and overrides the current 
      // visual set.
      // calls end function after
      loadMap ::(onDone, extraLandmarks) {
        @:base = state.base;
        
        @:baseOnDone = ::{
          state.map.title = '';

          foreach(base.requiredLandmarks) ::(i, landmarkName) {
            addLandmarkDefaults(
              map:state.map,
              base:Landmark.database.find(id:landmarkName),
              island:this
            )          
          }

          for(0, random.integer(from:base.minAdditionalLandmarkCount, to:base.maxAdditionalLandmarkCount)) ::(i) {
            @:landmarkName = random.pickArrayItem(:base.possibleLandmarks);
            addLandmarkDefaults(
              map:state.map,
              base:Landmark.database.find(id:landmarkName),
              island:this
            )          
          }


          if (extraLandmarks != empty) ::<= {
            foreach(extraLandmarks) ::(i, landmarkName) {
              addLandmarkDefaults(
                map:state.map,
                base:Landmark.database.find(id:landmarkName),
                island:this
              )          
            }
          
          }
          
          
          onDone(:state.map);        
        }
        
        when((base.traits & TRAIT.EMPTY) != 0) ::<= {
          
          @:Map = import(module:'game_class.map.mt');
          state.map = Map.new();
          state.map.title = '';

          baseOnDone();
          
          if (this.landmarks->size == 0) ::<= {
            @:landmark = Landmark.new(
              island:this,
              base: Landmark.database.find(:'base:none'),
              x:0,
              y:0
            );
            this.addLandmark(landmark);          
          }
        }
        
        LargeMap.create(
          parent:this, 
          sizeW:state.sizeW, 
          sizeH:state.sizeH, 
          symbols:base.possibleSceneryCharacters,
          onDone ::(map) {
            state.map = map;
            baseOnDone();
          }
        );

      },

      save ::{
        @:world = import(module:'game_singleton.world.mt');
        return state.save();
      },
      load ::(serialized) {
        @:world = import(module:'game_singleton.world.mt');
        state.load(parent:this, serialized);
      },
      
      name : {
        get :: {
          return state.name;
        }
      }, 
      
      description : {
        get :: {
          @:climate = Island.climateToString(climate:state.climate);
          @out = state.name + ' is '+ correctA(:climate) + ' island.';
          if ((state.base.traits & Island.TRAIT.DIVERSE) != 0) ::<= {
            out = out + 'The island is mostly populated by people of ' + Species.find(:state.species[0].species).name + ' and ' + Species.find(:state.species[1].species).name + ' descent. ';          
          }
          
          return out;
        }
      },
      
      //
      explore ::(x, y) {
        /*
        // in most cases just like 100-200 max
        ::? {
          foreach(areas) ::(k, v) {
            if (v.x == x && v.y == y) ::<= {
              v.visit()
            }
          }
        }
      
        @:loc = Landmark.new(
          x
        ) 
        */
      
      },
      
      worldID : {
        get ::<- state.worldID
      },
      
      sizeW : {
        get ::<- state.sizeW
      },
      sizeH : {
        get ::<- state.sizeH
      },
      
      tier : {
        set ::(value) <- state.tier = value,
        get ::<- state.tier
      },
      
      map : {
        get:: <- state.map
      },
      
      
      // represents the passage of time
      incrementTime:: {
        @:world = import(module:'game_singleton.world.mt');

        foreach(state.events)::(index, event) {
          event.incrementTime();
        }
        foreach(state.events)::(index, event) {
          if (event.expired) ::<= {
            event.base.emit(event:'onEventEnd', evt:event);          
            state.events->remove(key:state.events->findIndex(value:event));
          }
        }
        
        foreach(this.landmarks) ::(i, v) {
          v.incrementTime();
        }
      },
      
      findLocation ::(id) {
        return ::? {
          foreach(this.landmarks)::(i, landmark) {
            foreach(landmark.locations)::(n, location) {
              when(location.worldID == id)
                send(message:location);
            }
          }
        }
      },
      
      findLandmark ::(id) {
        return ::? {
          foreach(this.landmarks)::(i, landmark) {
            when(landmark.worldID == id)
              send(message:landmark);
          }
        }
      },      
      
      // represents a physical step in island space (not in a landmark)
      step :: {      
        state.steps += 1;    

        foreach(state.events)::(index, event) {
          event.step();
        }

        foreach(world_.party.members) ::(k, member) <- member.recharge(:10);
        
        
        when(state.possibleEvents->size == 0) empty;
      
        // every step, an event can occur.
        //if (stepsSinceLastEvent > 200000) ::<= {
        if (state.steps > 20) ::<= {
          if (random.number() > 13 - (state.steps-5) / 5) ::<={
            this.addEvent(
              event:IslandEvent.new(
                base:random.pickArrayItemWeighted(list:state.possibleEvents->map(
                  ::(value) <- IslandEvent.database.find(:value)
                )),
                parent:this
              )
            );            
            state.steps = 0;
          }
        }  
      },
      
      addLandmark ::(landmark, unmapped) {
        @:Map = import(module:'game_class.map.mt');
        
        if (unmapped == true)
          state.unmappedLandmarks->push(:landmark)
        else
          state.map.setItem(
            data:landmark, 
            x:landmark.x, 
            y:landmark.y, 
            traits : Map.TRAIT.HAS_HALO,
            symbol:landmark.symbol, 
            name:landmark.legendName
          );
      },
      
      removeLandmark ::(landmark) {
        state.map.removeItem(
          data:landmark
        );
      },
      
      addEvent::(event) {
        state.events->push(value:event);
      },
      
      events : {
        get :: <- state.events
      },
                  
      newInhabitant ::(professionHint, levelHint, speciesHint, raw) {
        @species = 
          if (((state.base.traits & TRAIT.DIVERSE) == 0) && random.try(percentSuccess:95))
            random.pickArrayItemWeighted(list:state.species).species
          else
            Species.getRandomFiltered(
              filter:::(value) <- (value.traits & Species.TRAIT.SPECIAL) == 0
            ).id
        ;
          
            
        @:out = Entity.new(
          island: this,
          speciesHint:  if (speciesHint == empty) species else speciesHint,
          levelHint:    if (levelHint == empty) levelGen(:state.level) else levelHint,
          professionHint: if (professionHint == empty) Profession.getRandomFiltered(filter::(value)<-value.learnable).id else professionHint
        );
        
        if (raw != true)
          augmentTiered(entity:out);
        
        return out;
      },
      
      
      species : {
        get :: <- [...state.species]->map(to:::(value) <- value.species)
      },
      
      newAggressor ::(levelHint, professionHint) {
        if (professionHint == empty) 
          professionHint = Profession.getRandomFiltered(filter::(value)<-value.learnable).id

        if (levelHint == empty)
          levelHint = levelGen(:state.level);

        @:angy =  Entity.new(
          island: this,
          speciesHint: random.pickArrayItemWeighted(list:state.species).species,
          levelHint,
          professionHint
        );     
        
        augmentTiered(entity:angy);             
        return angy;  
      },

      newHostileCreature ::(levelHint) {

        @:creatureMod = [
          'Small',
          'Giant',
          'Spotted',
          'Shrieking',
          'Skulking',
          'Menacing',
          'Grotesque'
        ];
        if (levelHint == empty)
          levelHint = levelGen(:state.level);;
        @:angy =  Entity.new(
          island: this,
          speciesHint: 'base:creature',
          levelHint,
          professionHint: 'base:creature'
        );     
        
        @:nameBase = random.pickArrayItem(list:state.nativeCreatures)
        angy.name = nameBase[0] + '-' + nameBase[1];
        angy.nickname = 
          'the ' + 
          (if (random.flipCoin()) '' else random.pickArrayItem(:creatureMod) + ' ') + 
          nameBase[0] + '-' + nameBase[1];
        return angy;  
      },

      getAPosition :: {
        return LargeMap.getAPosition(:state.map);
      },
      
      landmarks : {
        get ::<- [...state.map.getAllItemData(), ...state.unmappedLandmarks]
      },
      
      level : {
        get ::<- state.level,
        set ::(value) <- state.level = value
      },

      world : {
        get :: {
          return world_;
        }
      },


      // enters the travel ui state, bringing the user to the 
      // interactive travel menu for this island.
      // This also removes any existing travel menu for and up to 
      // this one.
      //
      // onLoad is called within the "loading spot" of the transition 
      //
      // onReady is called in a queued event RIGHT before 
      // the cursorMove event for the travel.
      //
      // startAnimationRenderable is a renderable that will be used 
      // for the starting visual for the transition animation.
      //
      // skipAnimation is whether to skip the transition from the travel
      travel ::(onLoad, onReady, startAnimationRenderable, skipAnimation) {  
        @:world = import(module:'game_singleton.world.mt');
        @:island = this;
        @:sound = import(module:'game_singleton.sound.mt');
        @:jumpTag = 'VisitIslandWORLDID'+this.worldID;
        if (world.island != this) ::<= {
          error(:'The current landmark isnt the one being traveled to!')
        }

        sound.playBGM(name:'world', loop:true);

        if (windowEvent.canJumpToTag(:jumpTag)) {
          canvas.freeze();
          windowEvent.jumpToTag(name:jumpTag, goBeforeTag:true);
          windowEvent.queueCustom(
            onEnter ::{
              canvas.thaw();            
            }
          );
        }

        
        @enteredChoices = false;
        @underFoot;
        @steps = 0;
        island.map.title = island.name + ' : ' + world.timeString;

        @:visitLandmark::(landmark) {
          when (landmark.base.hasTraits(:Landmark.TRAIT.POINT_OF_NO_RETURN)) ::<= {
            windowEvent.queueMessage(
              text: "It may be difficult to return... "
            );
            windowEvent.queueAskBoolean(
              prompt:'Enter?',
              onChoice::(which) {
                if (which == true) {
                  landmark.visit();
                  landmark.travel();
                }
              }
            )
          }
          landmark.visit();              
          landmark.travel();
          if (windowEvent.canJumpToTag(name:'LandmarkInteraction')) ::<= {
            windowEvent.jumpToTag(name:'LandmarkInteraction', goBeforeTag:true, doResolveNext:true);
          }                       
        }


        @islandTravel = ::{
          @:startup ::{
            windowEvent.queueCustom(
              onEnter ::{
                if (onReady) onReady();
              }
            );

          
            windowEvent.queueCursorMove(
              leftWeight: 1,
              topWeight: 1,
              prompt: 'Traveling...',
              jumpTag,
              onMenu :: {
                islandChoices();
              },
              
              renderable : {
                render ::{
                  this.visit();
                  @:hud = import(module:'game_singleton.hud.mt');
                  island.map.render();
                  hud.render(island);
                  when(underFoot == empty || underFoot->size == 0) empty;


                  
                  @:lines = [];
                  foreach(underFoot)::(i, arr) {


                    lines->push(value:arr.data.name);

                    //island.map.setPointer(
                    //  x: arr.x,
                    //  y: arr.y
                    //);
                  
                  }
                  
                  
                  
                  canvas.renderTextFrameGeneral(
                    title: 'Nearby:',
                    topWeight : 1,
                    leftWeight : 1,
                    lines
                  );
                }
              },
              onMove ::(choice) {
                world.landmark = empty;
                              
                // move by one unit in that direction
                // or ON it if its within one unit.
                island.map.movePointerFree(
                  x: if (choice == windowEvent.CURSOR_ACTIONS.RIGHT) 1 else if (choice == windowEvent.CURSOR_ACTIONS.LEFT) -1 else 0,
                  y: if (choice == windowEvent.CURSOR_ACTIONS.DOWN)  1 else if (choice == windowEvent.CURSOR_ACTIONS.UP)   -1 else 0
                );
                island.map.title = island.name + ' : ' + world.timeString + '           ';
                steps += 1;
                
                if (steps%4 == 0)
                  world.incrementTime();
                island.step();
                
                // cancel if we've arrived somewhere
                underFoot = island.map.getNamedItemsUnderPointerRadius(radius:5);
                
                foreach(underFoot)::(i, arr) {
                  arr.data.discover();
                  island.map.discover(data:arr.data);                      
                }
                @:underunderFoot = island.map.getNamedItemsUnderPointer();
                if (underunderFoot != empty && underunderFoot->size == 1)
                  visitLandmark(:underunderFoot[0].data);                

              }
            );
          }
        

          if (skipAnimation != true)
            windowEvent.queueTransition(
              kind:windowEvent.TRANSITION.FADE_TO_BLACK, 
              renderableStart: startAnimationRenderable,
              renderableMiddle: {
                render :: {
                  startup();
                  this.map.render();
                }
              }
            )
          else
            startup();


        }

        
        
        
        @:islandChoices = ::{   
        
          @islandOptions;
          @choiceActions;
          enteredChoices = true;
          windowEvent.queueChoices(
            leftWeight: 1,
            topWeight: 1,
            prompt: 'What next?',
            //renderable: island.map,
            canCancel : true,
            keep: true,
            jumpTag: 'LandmarkInteraction',
            onGetChoices ::{
              islandOptions = [...world.scenario.base.interactionsWalk]->filter(by::(value) <- value.filter(island));
              
              @choices = [];
              choiceActions = [];
              @visitable = island.map.getNamedItemsUnderPointerRadius(radius:5);

              if (visitable != empty) ::<= {
                foreach(visitable)::(i, vis) {
                  choices->push(value:'Visit ' + vis.name); 
                  choiceActions->push(::{
                    visitLandmark(:vis.data);                
                  });       
                }
              }
              
              foreach(islandOptions) ::(k, value) {
                choices->push(:value.name);
                choiceActions->push(::{
                  value.select(island);
                  if (!value.keepInteractionMenu && windowEvent.canJumpToTag(name:'LandmarkInteraction')) ::<= {
                    windowEvent.jumpToTag(name:'LandmarkInteraction', goBeforeTag:true, doResolveNext:true);
                  }              
                })
              }
              choices->push(value: 'Options');
              choiceActions->push(::{
                @:options = [...world.scenario.base.interactionsOptions]->filter(by::(value) <- value.filter(island));
                @:choices = [...options]->map(to::(value) <- value.name);

                windowEvent.queueChoices(
                  leftWeight: 1,
                  topWeight: 1,
                  prompt: 'Options',
                  canCancel : true,
                  keep: true,
                  jumpTag: 'LandmarkInteractionOptions',
                  choices,
                  onChoice::(choice) {
                    when(choice == 0) empty;
                    options[choice-1].select(island);
                    if (!options[choice-1].keepInteractionMenu && windowEvent.canJumpToTag(name:'LandmarkInteractionOptions'))
                      windowEvent.jumpToTag(name:'LandmarkInteractionOptions', goBeforeTag:true, doResolveNext:true);
                  }
                );              
              });
              return choices;
            },
            onChoice::(choice) {
              choiceActions[choice-1]();
            }
          );
        } 
        islandTravel();        
      },
      
      
      // Analog to landmark.visit()
      // Sets this island as the active island and implicitly visits it.
      //
      // onLoad is called within the "loading spot" of the transition 
      //
      // onReady is called in a queued event RIGHT before 
      // the cursorMove event for the travel.
      visit ::(onLoad, onReady, startAnimationRenderable, skipAnimation) {        
        @:world = import(module:'game_singleton.world.mt');
        when (world.island == this) empty;
        world.island = this;
        @:island = this;
        
        // check if we're AT a location.
        island.map.title = "(Map of " + island.name + ')';

        @hasVisitIsland;
        hasVisitIsland = true;
        
        
      }
    }
    

  }
);

return Island;
