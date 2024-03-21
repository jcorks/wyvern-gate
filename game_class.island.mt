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
@:Profession = import(module:'game_mutator.profession.mt');
@:Event = import(module:'game_mutator.event.mt');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

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


// todo: database.


@:Island = LoadableClass.create(
    name: 'Wyvern.Island',
    statics : {
        CLIMATE : {get::<-CLIMATE},
        
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
        name : empty,

        // minimum level of encountered individuals
        levelMin : empty,

        // maximum level of encountered individuals
        levelMax : empty,

        // how often encounters happen between turns.
        encounterRate: empty,        

        // Size of the island... Islands are always square-ish
        sizeW : empty,
        sizeH : empty,

        // steps since the last event
        stepsSinceLastEvent : empty,

        // map of the region
        map : empty,

        worldID : empty,


        climate : empty,

        events : empty,


        // the tier of the island. This determines the difficulty
        // tier 0-> enemies have no skills or equips. Large chests drop Fire keys 
        // tier 1-> enemies have 1 to 2 skills, but have no equips. Large chests drop Ice keys 
        // tier 2-> enemies have 1 to 2 skills and have weapons. Large chests drop Thunder keys 
        // tier 3-> enemies have all skills and have equips. Large chests drop Light keys
        // tier 4-> enemies have a random set of all skills and have full equip sets.
        tier : empty,


        // every island has hostile creatures.
        nativeCreatures : empty,

        //Within these, there are 2-6 predominant races per island,
        //usually in order of population distribution
        species : empty,
        
        // Whether the island experiences the normal set of possible events
        possibleEvents : empty,

        modData : empty
    },
    
    
    define:::(this, state) {
   
        // the world
        @world_;

        // current party
        @party_;

        

        // augments an entity based on the current tier
        @augmentTiered = ::(entity) {
            match(state.tier) {
              (0):::<= {
                entity.capHP(max:11);
              }, // tier zero has no mods 

              // tier 1: learn 1 to 2 skills
              (1):::<= {
                entity.capHP(max:14);
                entity.learnNextAbility();
                if (Number.random() > 0.5)
                    entity.learnNextAbility();
                          
              },
              

              // tier 2: learn 1 to 2 skills and get equips
              (2):::<= {
                entity.capHP(max:16);
                entity.learnNextAbility();
                if (Number.random() > 0.5)
                    entity.learnNextAbility();
              
                @:Item = import(module:'game_mutator.item.mt');
                // add a weapon
                @:wep = Item.database.getRandomFiltered(
                    filter:::(value) <-
                        value.isUnique == false &&
                        value.attributes & Item.ATTRIBUTE.WEAPON
                );
                    
                entity.equip(
                    slot:Entity.EQUIP_SLOTS.HAND_LR, 
                    item:Item.new(
                        base:wep
                    ), 
                    inventory:entity.inventory, 
                    silent:true
                );
              },
              


              // tier 3: learn 1 to 2 skills and get equips
              (3):::<= {
                entity.capHP(max:20);
                for(0, 10)::(i) {
                    entity.learnNextAbility();                
                }

              
                @:Item = import(module:'game_mutator.item.mt');
                // add a weapon
                @:wep = Item.database.getRandomFiltered(
                    filter:::(value) <-
                        value.isUnique == false &&
                        value.attributes & Item.ATTRIBUTE.WEAPON
                );
                    
                entity.equip(
                    slot:Entity.EQUIP_SLOTS.HAND_LR, 
                    item:Item.new(
                        base: wep
                    ), 
                    inventory:entity.inventory, 
                    silent:true
                );
              },
              
              
              // tier 2: learn 1 to 2 skills and get equips
              default: ::<= {
                for(0, 10)::(i) {
                    entity.learnNextAbility();                
                }

              
                @:Item = import(module:'game_mutator.item.mt');
                // add a weapon
                @:wep = Item.database.getRandomFiltered(
                    filter:::(value) <-
                        value.isUnique == false &&
                        value.attributes & Item.ATTRIBUTE.WEAPON
                );
                    
                entity.equip(
                    slot:Entity.EQUIP_SLOTS.HAND_LR, 
                    item:Item.new(
                        base:wep
                    ), 
                    inventory:entity.inventory, 
                    silent:true
                );


                // add some armor!
                @:wep = Item.database.getRandomFiltered(
                    filter:::(value) <-
                        value.isUnique == false &&
                        value.equipType == Item.TYPE.ARMOR
                );;
                    
                entity.equip(
                    slot:Entity.EQUIP_SLOTS.ARMOR, 
                    item:Item.new(
                        base: wep
                    ), 
                    inventory:entity.inventory, 
                    silent:true
                );

              }             
              
              
            }        
        }

        @:addDefaultLandmarks::{
            @locationCount = (1 + (Number.random()*2)->floor); 
            if (locationCount < 1) locationCount = 1;
            for(0, locationCount)::(i) {
                LargeMap.addLandmark(
                    map:state.map,
                    base:Landmark.database.getRandomWeightedFiltered(
                        filter:::(value) <- value.isUnique == false
                    ),
                    island:this
                )
            }
            
            // guaranteed gate
            LargeMap.addLandmark(
                map:state.map,
                base:Landmark.database.find(id:'base:wyvern-gate'),
                island:this
            )
            
                  

            
            LargeMap.addLandmark(
                map:state.map,
                base:Landmark.database.find(id:'base:town'),
                island:this
            )






            LargeMap.addLandmark(
                map:state.map,
                base:Landmark.database.find(id:'base:city'),
                island:this
            )

        
        }

        
        this.interface = {
            initialize:: { 
                @:world = import(module:'game_singleton.world.mt');
                @:party = world.party;

                world_ = world;            
                party_ = party;
            
            },

            wait::(until) {       
                @:world = import(module:'game_singleton.world.mt');
                {:::} {
                    forever ::{
                        when(world.time != until) send()
                        this.incrementTime();
                    }
                }
                {:::} {
                    forever ::{
                        when(world.time == until) send()
                        this.incrementTime();
                    }
                }

            },
            
            defaultLoad::(levelHint, nameHint, tierHint, landmarksHint, sizeWHint, sizeHHint, possibleEventsHint, extraLandmarks) {
                @:world = import(module:'game_singleton.world.mt');

                @:oldIsland = world.island;
                world.island = this;
 
                ::<= {
                    @factor = Number.random()*50 + 80;
                    @sizeW  = (factor)->floor;
                    @sizeH  = (factor*0.5)->floor;
                    
                    state.name = NameGen.island();
                    state.levelMin = 0;
                    state.levelMax = 0;
                    state.possibleEvents = if (possibleEventsHint) possibleEventsHint else [
                        'BBQ',
                        'Weather:1',
                        'Camp out'
                    ];
                    state.encounterRate = Number.random();
                    state.sizeW  = if (sizeWHint != empty) sizeWHint else sizeW;
                    state.sizeH  = if (sizeHHint != empty) sizeHHint else sizeH;
                    state.stepsSinceLastEvent = 0;
                    state.map = LargeMap.create(parent:this, sizeW, sizeH);
                    state.worldID = world.getNextID();
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
                                    count : (5+Number.random()*5)->ceil,
                                    filter:::(value) <- value.special == false
                                )
                        ]->map(
                            to:::(value) <- {
                                species: value.id, 
                                rarity: rarity *= 1.4
                            }
                        );
                    };
                };
                
            
            
                state.tier = tierHint;

                state.levelMin = (levelHint - Number.random() * (levelHint * 0.4))->ceil;
                state.levelMax = (levelHint + Number.random() * (levelHint * 0.4))->floor;
                if (state.levelMin < 1) state.levelMin = 1;
                if (nameHint != empty)
                    state.name = (nameHint) => String;

                @rarity = 1;

                
      

                if (landmarksHint == empty)
                    addDefaultLandmarks()
                else ::<= {
                    foreach(landmarksHint) ::(i, landmarkName) {
                        LargeMap.addLandmark(
                            map:state.map,
                            base:Landmark.database.find(id:landmarkName),
                            island:this
                        )                    
                    }
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

                
                world.island = oldIsland;
                return this;
            },

            save ::{
                @:world = import(module:'game_singleton.world.mt');
                world.addLoadableIsland(island:this);
                return state.save();
            },
            load ::(serialized) {
                @:world = import(module:'game_singleton.world.mt');
                state.load(parent:this, serialized);
                world.addLoadableIsland(island:this);
            },
            
            name : {
                get :: {
                    return state.name;
                }
            }, 
            
            description : {
                get :: {
                    @out = 'A ' + Island.climateToString(climate:state.climate) + ' island, ' + state.name + ' is mostly populated by people of ' + state.species[0].species + ' and ' + state.species[1].species + ' descent. ';//The island is known for its ' + professions[0].profession.name + 's and ' + professions[1].profession.name + 's.\n';
                    //out = out + this.class.describeEncounterRate(rate:encounterRate) + '\n';
                    //out = out + '(Level range: ' + levelMin + ' - ' + levelMax + ')' + '\n\n';
                    /*
                    out = out + 'It has ' + significantLandmarks->keycount + ' landmark(s): \n';

                    foreach(significantLandmarks)::(index, landmark) {
                        if (landmark.discovered)
                            out = out + landmark.description + '\n'
                        else
                            out = out + 'An undiscovered ' + landmark.base.name + '\n';
                    }
                    */
                    return out;
                }
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
            
            incrementTime:: {
                @:world = import(module:'game_singleton.world.mt');
                world.stepTime(); 
                foreach(state.events)::(index, event) {
                    event.stepTime();
                }
                foreach(state.events)::(index, event) {
                    if (event.expired) ::<= {
                        event.base.onEventEnd(event);                    
                        state.events->remove(key:state.events->findIndex(value:event));
                    }
                }
            },
            
            findLocation ::(id) {
                return {:::} {
                    foreach(state.map.getAllItemData())::(i, landmark) {
                        foreach(landmark.locations)::(n, location) {
                            when(location.worldID == id)
                                send(message:location);
                        }
                    }
                }
            },
            
            takeStep :: {            
                state.stepsSinceLastEvent += 1;        
                
                when(state.possibleEvents->size == 0) empty;
            
                // every step, an event can occur.
                //if (stepsSinceLastEvent > 200000) ::<= {
                if (state.stepsSinceLastEvent > 13) ::<= {
                    if (Number.random() > 13 - (state.stepsSinceLastEvent-5) / 5) ::<={
                        this.addEvent(
                            event:Event.new(
                                base:Event.database.find(id:random.pickArrayItem(list:state.possibleEvents)),
                                parent:this
                            )
                        );                        
                        state.stepsSinceLastEvent = 0;
                    }
                }    
            },
            
            newLandmark ::(base, x, y, floorHint) {
                @landmark = Landmark.new(
                    base:base,
                    parent:state.map,
                    x: x,
                    y: y,
                    floorHint:floorHint
                );            
                
                if (x != empty && y != empty) ::<= {
                    state.map.setItem(data:landmark, x:landmark.x, y:landmark.y, symbol:landmark.base.symbol, name:landmark.base.legendName);
                }
                return landmark;
            },
            
            addEvent::(event) {
                state.events->push(value:event);
            },
            
            events : {
                get :: <- state.events
            },
                                    
            newInhabitant ::(professionHint, levelHint, speciesHint) {
                @:out = Entity.new(
                    island: this,
                    speciesHint:    if (speciesHint == empty) random.pickArrayItemWeighted(list:state.species).species else speciesHint,
                    levelHint:      if (levelHint == empty) random.integer(from:state.levelMin, to:state.levelMax) else levelHint,
                    professionHint: if (professionHint == empty) Profession.database.getRandomFiltered(filter::(value)<-value.learnable).id else professionHint
                );
                
                augmentTiered(entity:out);
                
                return out;
            },
            
            
            species : {
                get :: <- [...state.species]->map(to:::(value) <- value.species)
            },
            
            newAggressor ::(levelMaxHint) {            
                @levelHint = random.integer(from:state.levelMin, to:if(levelMaxHint == empty) state.levelMax else levelMaxHint);
                @:angy =  Entity.new(
                    island: this,
                    speciesHint: random.pickArrayItemWeighted(list:state.species).species,
                    levelHint,
                    professionHint: Profession.database.getRandomFiltered(filter::(value)<-value.learnable).name
                );       
                
                augmentTiered(entity:angy);                       
                return angy;  
            },

            newHostileCreature ::(levelMaxHint) {
                @levelHint = random.integer(from:state.levelMin, to:if(levelMaxHint == empty) state.levelMax else levelMaxHint);
                @:angy =  Entity.new(
                    island: this,
                    speciesHint: 'Creature',
                    levelHint,
                    professionHint: 'Creature'
                );       
                
                angy.nickname = random.pickArrayItem(list:state.nativeCreatures);
                       
                return angy;  
            },

            
            getLandmarkIndex ::(landmark => Landmark.type) {
                return state.map.getAllItemData()->findIndex(value:landmark);
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
