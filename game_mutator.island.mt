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
}


@:reset = :: {

Island.database.newEntry(
  data : {
    id : 'base:none',
    requiredLandmarks : [
      'base:wyvern-gate',
    ],
    possibleLandmarks : [
      
    ],
    minAdditionalLandmarkCount : 0,
    maxAdditionalLandmarkCount : 0,
    minSize : 40,//80,
    maxSize : 40, //130,
    events : [
      
    ],
    possibleSceneryCharacters : [
      '╿', '.', '`', '^', ','
    ],
    traits : TRAIT.SPECIAL,
    
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
      'base:town',
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

    // minimum level of encountered individuals
    levelMin : 0,

    // maximum level of encountered individuals
    levelMax : 0,

    // how often encounters happen between turns.
    encounterRate: 0,    

    // Size of the island... Islands are always square-ish
    sizeW : 0,
    sizeH : 0,

    // steps since the last event
    stepsSinceLastEvent : 0,

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
      @:Arts = import(module:'game_database.arts.mt');

      // Assigns support arts for every entity.
      @:assignSupportArts::(entity, professionLevel, removeBasicCount) {
        // basic arts: 10 + 12 = 22
        entity.supportArts = [
          'base:pebble',    //5
          'base:cycle',     //5
          'base:diversify', //3
          'base:brace',     //3
          'base:prismatic-wisp', //3
          'base:mind-games',//3
        ];
        
        
        entity.supportArts = random.scrambled(:entity.supportArts);
        for(0, removeBasicCount) ::(i) {
          entity.supportArts->pop;
        }
        
        // for each professional art, a support art is replaced
        for(0, professionLevel) ::(i) {
          entity.autoLevelProfession(:entity.profession);
        }
        entity.equipAllProfessionArts();  
        foreach(entity.professionArts) ::(k, v) {
          entity.supportArts->pop;
        }
        

        // finally collect unique random support arts until 35 is reached
        @:addCondition ::(value) <- entity.supportArts->findIndex(:value.id) == -1
        ::? {
          forever ::{
            if (entity.calculateDeckSize() >= 35) send();

            entity.supportArts->push(:
              Arts.getRandomFiltered(::(value) <- 
                ((value.traits & Arts.TRAIT.SPECIAL) == 0)
                &&
                ((value.traits & Arts.TRAIT.SUPPORT) != 0)
                &&
                addCondition(:value)
              ).id
            );

          }
        }
      }

    
      @tier = state.tier + 10*instance.y;
      if (instance.y)
        instance.x = true;
      match(tier) {
        (0):::<= {
          entity.capHP(max:random.integer(from:7, to:9));
          assignSupportArts(
            entity,
            professionLevel : 1,
            removeBasicCount : 0
          );
        }, // tier zero has no mods 

        // tier 1: learn 1 to 2 skills
        (1):::<= {
          assignSupportArts(
            entity,
            professionLevel : 1,
            removeBasicCount : 1
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
            professionLevel : 2,
            removeBasicCount : 2
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
            professionLevel : 4,
            removeBasicCount : 3
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
          state.levelMin = 0;
          state.levelMax = 0;
          state.possibleEvents = if (possibleEventsHint) possibleEventsHint else [...base.events];
          state.encounterRate = random.number();
          state.sizeW  = sizeW;
          state.sizeH  = sizeH;
          state.stepsSinceLastEvent = 0;
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

        state.levelMin = (levelHint - random.number() * (levelHint * 0.2))->round;
        state.levelMax = (levelHint + random.number() * (levelHint * 0.2))->round;
        if (state.levelMin < 1) state.levelMin = 1;
        if (nameHint != empty || nameHint == '')
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
        LargeMap.create(
          parent:this, 
          sizeW:state.sizeW, 
          sizeH:state.sizeH, 
          symbols:base.possibleSceneryCharacters,
          onDone ::(map) {
            state.map = map;
            state.map.title = '';

            foreach(base.requiredLandmarks) ::(i, landmarkName) {
              LargeMap.addLandmark(
                map:state.map,
                base:Landmark.database.find(id:landmarkName),
                island:this
              )          
            }

            for(0, random.integer(from:base.minAdditionalLandmarkCount, to:base.maxAdditionalLandmarkCount)) ::(i) {
              @:landmarkName = random.pickArrayItem(:base.possibleLandmarks);
              LargeMap.addLandmark(
                map:state.map,
                base:Landmark.database.find(id:landmarkName),
                island:this
              )          
            }


            if (extraLandmarks != empty) ::<= {
              foreach(extraLandmarks) ::(i, landmarkName) {
                LargeMap.addLandmark(
                  map:state.map,
                  base:Landmark.database.find(id:landmarkName),
                  island:this
                )          
              }
            
            }
            
            
            onDone(:state.map);
          
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
              instance.visitLandmark(
                landmark: v
              );
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
            event.base.onEventEnd(event);          
            state.events->remove(key:state.events->findIndex(value:event));
          }
        }
        
        foreach(this.landmarks) ::(i, v) {
          v.incrementTime();
        }
      },
      
      findLocation ::(id) {
        return ::? {
          foreach(state.map.getAllItemData())::(i, landmark) {
            foreach(landmark.locations)::(n, location) {
              when(location.worldID == id)
                send(message:location);
            }
          }
        }
      },
      
      // represents a physical step in island space (not in a landmark)
      step :: {      
        state.stepsSinceLastEvent += 1;    

        foreach(state.events)::(index, event) {
          event.step();
        }


        
        when(state.possibleEvents->size == 0) empty;
      
        // every step, an event can occur.
        //if (stepsSinceLastEvent > 200000) ::<= {
        if (state.stepsSinceLastEvent > 20) ::<= {
          if (random.number() > 13 - (state.stepsSinceLastEvent-5) / 5) ::<={
            this.addEvent(
              event:IslandEvent.new(
                base:random.pickArrayItemWeighted(list:state.possibleEvents->map(
                  ::(value) <- IslandEvent.database.find(:value)
                )),
                parent:this
              )
            );            
            state.stepsSinceLastEvent = 0;
          }
        }  
      },
      
      addLandmark ::(landmark) {
      
        state.map.setItem(
          data:landmark, 
          x:landmark.x, 
          y:landmark.y, 
          symbol:landmark.symbol, 
          name:landmark.legendName,
          discovered:false
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
                  
      newInhabitant ::(professionHint, levelHint, speciesHint) {
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
          levelHint:    if (levelHint == empty) random.integer(from:state.levelMin, to:state.levelMax) else levelHint,
          professionHint: if (professionHint == empty) Profession.getRandomFiltered(filter::(value)<-value.learnable).id else professionHint
        );
        
        augmentTiered(entity:out);
        
        return out;
      },
      
      
      species : {
        get :: <- [...state.species]->map(to:::(value) <- value.species)
      },
      
      newAggressor ::(levelMaxHint, professionHint) {
        if (professionHint == empty) 
          professionHint = Profession.getRandomFiltered(filter::(value)<-value.learnable).id

        @levelHint = random.integer(from:state.levelMin, to:if(levelMaxHint == empty) state.levelMax else levelMaxHint);
        @:angy =  Entity.new(
          island: this,
          speciesHint: random.pickArrayItemWeighted(list:state.species).species,
          levelHint,
          professionHint
        );     
        
        augmentTiered(entity:angy);             
        return angy;  
      },

      newHostileCreature ::(levelMaxHint) {
        @levelHint = random.integer(from:state.levelMin, to:if(levelMaxHint == empty) state.levelMax else levelMaxHint);
        @:angy =  Entity.new(
          island: this,
          speciesHint: 'base:creature',
          levelHint,
          professionHint: 'base:creature'
        );     
        
        angy.nickname = random.pickArrayItem(list:state.nativeCreatures);
             
        return angy;  
      },

      
      getLandmarkIndex ::(landmark => Landmark.type) {
        return state.map.getAllItemData()->findIndex(value:landmark);
      },
      
      getAPosition :: {
        return LargeMap.getAPosition(:state.map);
      },
      
      landmarks : {
        get ::<- state.map.getAllItemData()
      },
      
      levelMin : {
        get ::<- state.levelMin
      },
      levelMax : {
        get ::<- state.levelMax
      },
      
      world : {
        get :: {
          return world_;
        }
      }

    }
    

  }
);

return Island;
