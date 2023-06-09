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
@:Species = import(module:'game_class.species.mt');
@:Entity = import(module:'game_class.entity.mt');
@:Landmark = import(module:'game_class.landmark.mt');
@:dialogue = import(module:'game_singleton.dialogue.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:LargeMap = import(module:'game_class.largemap.mt');
@:Party = import(module:'game_class.party.mt');
@:Profession = import(module:'game_class.profession.mt');
@:Event = import(module:'game_class.event.mt');
@:CLIMATE = {
    WARM : 0,
    TEMPERATE : 1,
    DRY : 2,
    RAINY : 3,
    HUMID : 4,
    SNOWY : 5,
    COLD : 6
};

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

@:genID :: {
    @:genHex :: {
        return hexKey[(Number.random()*16)->floor];
    };
    
    @:genBlock :: {
        return genHex() + genHex() + genHex() + genHex();
    };
    
    return genBlock() + '-' +
           genBlock() + '-' +
           genBlock() + '-' +
           genBlock();
};


// todo: database.


@:Island = class(
    name: 'Wyvern.Island',
    statics : {
        CLIMATE : CLIMATE,
        
        climateToString::(climate) {
            return match(climate) {
                (0): 'warm',
                (1): 'temperate',
                (2): 'dry',
                (3): 'rainy',
                (4): 'humid',
                (5): 'snowy',
                (6): 'cold'         
            };
        },
        
        
        describeEncounterRate::(rate) {
            return match(true) {
              (rate < 0.2): 'It is peaceful.',
              (rate < 0.4): 'It is generally peaceful.',
              (rate < 0.6): 'It is relatively peaceful',
              (rate < 0.8): 'It is slightly chaotic.',
              default: 'It is very chaotic.'
            };
        }
    },
    define:::(this) {
        @name = NameGen.island();

        // the world
        @world_;

        // minimum level of encountered individuals
        @levelMin;
        
        // maximum level of encountered individuals
        @levelMax;
        
        // how often encounters happen between turns.
        @encounterRate = Number.random();        
        
        // Size of the island... Islands are always square-ish
        @factor = Number.random()*50 + 70;
        @sizeW  = (factor)->floor;
        @sizeH  = (factor*0.5)->floor;
        
        // steps since the last event
        @stepsSinceLastEvent = 0;
        
        // map of the region
        @map = LargeMap.new(sizeW, sizeH);
        
        @id = genID();

        
        @climate = random.integer(
            from:this.class.CLIMATE.WARM, 
            to  :this.class.CLIMATE.COLD
        );
        
        @events = []; //array of Events
        
        @party_;
        
        // the tier of the island. This determines the difficulty
        // tier 0-> enemies have no skills or equips. Large chests drop Fire keys 
        // tier 1-> enemies have 1 to 2 skills, but have no equips. Large chests drop Ice keys 
        // tier 2-> enemies have 1 to 2 skills and have weapons. Large chests drop Thunder keys 
        // tier 3-> enemies have all skills and have equips. Large chests drop Light keys
        // tier 4-> enemies have a random set of all skills and have full equip sets.
        @tier_ = 0;


        // every island has hostile creatures.
        @:nativeCreatures = [
            NameGen.creature(),
            NameGen.creature(),
            NameGen.creature()
        ];
        
        //Within these, there are 2-6 predominant races per island,
        //usually in order of population distribution
        @species = ::<={
            @rarity = 1;
            return [
                ... Species.database.getRandomSet(
                        count : (4+Number.random()*3)->ceil,
                        filter:::(value) <- value
                    )
            ]->map(
                to:::(value) <- {
                    species: value, 
                    rarity: rarity *= 2
                }
            );
        };


        // Similarly, only a handful of professions of each are found on
        // any given island.
        @professions;

        // Islands have a set number of landmarks.


        @significantLandmarks = {};

        // augments an entity based on the current tier
        @augmentTiered = ::(entity) {
            match(tier_) {
              (0): empty, // tier zero has no mods 

              // tier 1: learn 1 to 2 skills
              (1):::<= {
                entity.profession.gainSP(amount:1);
                if (Number.random() > 0.5)
                    entity.profession.gainSP(amount:1);
                          
              },
              

              // tier 2: learn 1 to 2 skills and get equips
              (2):::<= {
                entity.profession.gainSP(amount:1);
                if (Number.random() > 0.5)
                    entity.profession.gainSP(amount:1);
              
                @:Item = import(module:'game_class.item.mt');
                // add a weapon
                @:wep = Item.Base.database.getRandomFiltered(
                    filter:::(value) <-
                        value.isUnique == false &&
                        value.attributes->findIndex(value:Item.ATTRIBUTE.WEAPON) != -1
                );
                    
                entity.equip(
                    slot:Entity.EQUIP_SLOTS.HAND_L, 
                    item:wep.new(
                        from: entity
                    ), 
                    inventory:entity.inventory, 
                    silent:true
                );
              },
              


              // tier 2: learn 1 to 2 skills and get equips
              (2):::<= {
                entity.profession.gainSP(amount:10);

              
                @:Item = import(module:'game_class.item.mt');
                // add a weapon
                @:wep = Item.Base.database.getRandomFiltered(
                    filter:::(value) <-
                        value.isUnique == false &&
                        value.attributes->findIndex(value:Item.ATTRIBUTE.WEAPON) != -1
                );
                    
                entity.equip(
                    slot:Entity.EQUIP_SLOTS.HAND_L, 
                    item:wep.new(
                        from: entity
                    ), 
                    inventory:entity.inventory, 
                    silent:true
                );
              },
              
              
              // tier 2: learn 1 to 2 skills and get equips
              (3):::<= {
                entity.profession.gainSP(amount:10);

              
                @:Item = import(module:'game_class.item.mt');
                // add a weapon
                @:wep = Item.Base.database.getRandomFiltered(
                    filter:::(value) <-
                        value.isUnique == false &&
                        value.attributes->findIndex(value:Item.ATTRIBUTE.WEAPON) != -1
                );
                    
                entity.equip(
                    slot:Entity.EQUIP_SLOTS.HAND_L, 
                    item:wep.new(
                        from: entity
                    ), 
                    inventory:entity.inventory, 
                    silent:true
                );


                // add some armor!
                @:wep = Item.Base.database.getRandomFiltered(
                    filter:::(value) <-
                        value.isUnique == false &&
                        value.type == Item.TYPE.ARMOR
                );;
                    
                entity.equip(
                    slot:Entity.EQUIP_SLOTS.ARMOR, 
                    item:wep.new(
                        from: entity
                    ), 
                    inventory:entity.inventory, 
                    silent:true
                );

              }             
              
              
            };        
        };


        this.constructor = ::(world => Object, levelHint => Number, party => Party.type, nameHint, state, tierHint => Number) {
            world_ = world;            
            party_ = party;
            tier_ = tierHint;

            when (state != empty) ::<= {
                this.state = state;
                return this;            
            };
            levelMin = (levelHint - Number.random() * (levelHint * 0.4))->ceil;
            levelMax = (levelHint + Number.random() * (levelHint * 0.4))->floor;
            if (levelMin < 1) levelMin = 1;
            if (nameHint != empty)
                name = (nameHint) => String;

            @rarity = 1;
            professions = [
                ... Profession.Base.database.getRandomSet(
                        count : (2+Number.random()*3)->ceil,
                        filter:::(value) <- 
                            levelMin >= value.levelMinimum &&
                            value.learnable
                    )
            ]->map(
                to:::(value) <- {
                    profession: value, 
                    rarity: rarity *= 2
                }
            );
            
  


            @locationCount = (1 + (Number.random()*4)->floor); 
            if (locationCount < 1) locationCount = 1;
            [0, locationCount]->for(do:::(i) {
                @:landmark = Landmark.Base.database.getRandomWeightedFiltered(
                    filter:::(value) <- value.isUnique == false
                ).new(
                    island:this,
                    x: Number.random()*(sizeW - 0.2) + 0.2,
                    y: Number.random()*(sizeH - 0.2) + 0.2
                );

                map.setItem(data:landmark, x:landmark.x, y:landmark.y, symbol:landmark.base.symbol, name:landmark.base.name);

                significantLandmarks->push(value:landmark);
            });
            
            // guaranteed gate
            @:gate = Landmark.Base.database.find(name:'Wyvern Gate').new(
                island:this,
                x: Number.random()*(sizeW - 0.2) + 0.2,
                y: Number.random()*(sizeH - 0.2) + 0.2
            );

            map.setItem(data:gate, x:gate.x, y:gate.y, symbol:gate.base.symbol, name:gate.base.name);

            significantLandmarks->push(value:gate);


            // guaranteed town
            @:gate = Landmark.Base.database.find(name:'Shrine').new(
                island:this,
                x: 30, //Number.random()*(sizeW - 0.2) + 0.2,
                y: 30  //Number.random()*(sizeH - 0.2) + 0.2
            );
            map.setItem(data:gate, x:gate.x, y:gate.y, symbol:gate.base.symbol, name:gate.base.name);
            significantLandmarks->push(value:gate);
            
            @:gate = Landmark.Base.database.find(name:'town').new(
                island:this,
                x: Number.random()*(sizeW - 0.2) + 0.2,
                y: Number.random()*(sizeH - 0.2) + 0.2
            );
            map.setItem(data:gate, x:gate.x, y:gate.y, symbol:gate.base.symbol, name:gate.base.name);
            significantLandmarks->push(value:gate);




            // free treasure!
            @:gate = Landmark.Base.database.find(name:'forest').new(
                island:this,
                x: Number.random()*(sizeW - 0.2) + 0.2,
                y: Number.random()*(sizeH - 0.2) + 0.2
            );
            map.setItem(data:gate, x:gate.x, y:gate.y, symbol:gate.base.symbol, name:gate.base.name);
            significantLandmarks->push(value:gate);


            @:gate = Landmark.Base.database.find(name:'city').new(
                island:this,
                x: Number.random()*(sizeW - 0.2) + 0.2,
                y: Number.random()*(sizeH - 0.2) + 0.2
            );
            map.setItem(data:gate, x:gate.x, y:gate.y, symbol:gate.base.symbol, name:gate.base.name);
            significantLandmarks->push(value:gate);

            

            return this;
        };

        
        this.interface = {
            state : {
                set ::(value) {
                    id = value.id;
                    name = value.name;
                    levelMin = value.levelMin;
                    levelMax = value.levelMax;
                    encounterRate = value.encounterRate;
                    sizeW = value.sizeW;
                    sizeH = value.sizeH;
                    stepsSinceLastEvent = value.stepsSinceLastEvent;
                    climate = value.climate;
                    species = [];
                    value.species->foreach(do:::(index, speciesData) {
                        species->push(value:{
                            rarity: speciesData.rarity,
                            species: Species.database.find(name:speciesData.name)
                        });
                    });

                    significantLandmarks = [];
                    map = LargeMap.new(state:value.map);

                    value.significantLandmarks->foreach(do:::(index, landmarkData) {
                        @:landmark = Landmark.Base.database.find(name:landmarkData.baseName).new(x:0, y:0, state:landmarkData, island:this);
                        map.setItem(data:landmark, x:landmark.x, y:landmark.y, symbol:landmark.base.symbol, name:landmark.base.name);
                        significantLandmarks->push(value:landmark);
                    });
                    
                    events = [];
                    @:world = import(module:'game_singleton.world.mt');
                    value.events->foreach(do:::(index, eventData) {
                        @:event = Event.new(state:eventData, island:this, party:world.party);
                        events->push(value:event);
                    });

                    professions = [];
                    value.professions->foreach(do:::(index, professionData) {
                        @:prof = professionData;
                        prof.profession = Profession.Base.database.find(name:prof.profession);                       
                        professions->push(value:prof);
                    });


                },
            
                get :: {
                    breakpoint();
                
                    return {
                        name : name,
                        levelMin : levelMin,
                        levelMax : levelMax,
                        id : id,
                        encounterRate : encounterRate,
                        sizeW : sizeW,
                        sizeH : sizeH,
                        stepsSinceLastEvent : stepsSinceLastEvent,
                        map : map.state,
                        climate : climate,
                        species : [...species]->map(to:::(value) <- {rarity:value.rarity, name:value.species.name}),
                        significantLandmarks : [...significantLandmarks]->map(to:::(value) <- value.state),
                        events : [...events]->map(to:::(value) <- value.state),
                        professions : [...professions]->map(to:::(value) <- {rarity:value.rarity, profession:value.profession.name})
                    
                    };
                }
            },
            
            name : {
                get :: {
                    return name;
                }
            }, 
            
            description : {
                get :: {
                    @out = 'A ' + this.class.climateToString(climate) + ' island, ' + name + ' is mostly populated by people of ' + species[0].species.name + ' and ' + species[1].species.name + ' descent. ';//The island is known for its ' + professions[0].profession.name + 's and ' + professions[1].profession.name + 's.\n';
                    //out = out + this.class.describeEncounterRate(rate:encounterRate) + '\n';
                    //out = out + '(Level range: ' + levelMin + ' - ' + levelMax + ')' + '\n\n';
                    
                    out = out + 'It has ' + significantLandmarks->keycount + ' landmark(s): \n';

                    significantLandmarks->foreach(do:::(index, landmark) {
                        if (landmark.discovered)
                            out = out + landmark.description + '\n'
                        else
                            out = out + 'An undiscovered ' + landmark.base.name + '\n';
                    });
                    
                    return out;
                }
            },
            
            id : {
                get ::<- id
            },
            
            sizeW : {
                get ::<- sizeW
            },
            sizeH : {
                get ::<- sizeH
            },
            
            tier : {
                get ::<- tier_
            },
            
            map : {
                get:: <- map
            },
            
            incrementTime:: {
                // every step, an event can occur.
                //if (stepsSinceLastEvent > 200000) ::<= {
                if (stepsSinceLastEvent > 13) ::<= {
                    if (Number.random() > 13 - (stepsSinceLastEvent-5) / 5) ::<={
                        // mostly its encounters. 0.1% chance of encounter 
                        if (Number.random() < 0.001) ::<= {
                            this.addEvent(
                                event:Event.Base.database.find(name:'Encounter:Normal').new(
                                    island:this, 
                                    party:world_.party //, currentTime
                                )
                            );
                        } else ::<= {
                            this.addEvent(
                                event:Event.Base.database.getRandomFiltered(
                                    filter:::(value) <- !value.name->contains(key:'Encounter')
                                ).new(
                                    island:this, 
                                    party:world_.party //, currentTime
                                )
                            );                        
                        };
                        stepsSinceLastEvent = 0;
                    };
                };    
                stepsSinceLastEvent += 1;        
            
                events->foreach(do:::(index, event) {
                    event.stepTime();
                });
                events->foreach(do:::(index, event) {
                    if (event.expired) ::<= {
                        event.base.onEventEnd(event);                    
                        events->remove(key:events->findIndex(value:event));
                    };
                });
            },
            
            addEvent::(event) {
                events->push(value:event);
            },
            
            events : {
                get :: <- events
            },
                                    
            newInhabitant ::(professionHint, levelHint, speciesHint) {
                @:out = Entity.new(
                    speciesHint:    if (speciesHint == empty) random.pickArrayItemWeighted(list:species).species else speciesHint,
                    levelHint:      if (levelHint == empty) random.integer(from:levelMin, to:levelMax) else levelHint,
                    professionHint: if (professionHint == empty) this.getProfession().name  else professionHint
                );
                
                augmentTiered(entity:out);
                
                return out;
            },
            
            getProfession ::{
                return random.pickArrayItemWeighted(list:professions).profession;
            },
            
            species : {
                get :: <- [...species]->map(to:::(value) <- value.species)
            },
            
            newAggressor ::(levelMaxHint) {            
                @levelHint = random.integer(from:levelMin, to:if(levelMaxHint == empty) levelMax else levelMaxHint);
                @:angy =  Entity.new(
                    speciesHint: random.pickArrayItemWeighted(list:species).species,
                    levelHint,
                    professionHint: Profession.Base.database.getRandomFiltered(
                        filter:::(value) <- 
                            value.maxKarma < 1000 &&
                            levelHint >= value.levelMinimum
                    ).name
                );       
                
                augmentTiered(entity:angy);                       
                return angy;  
            },

            newHostileCreature ::(levelMaxHint) {
                @levelHint = random.integer(from:levelMin, to:if(levelMaxHint == empty) levelMax else levelMaxHint);
                @:angy =  Entity.new(
                    speciesHint: Species.database.find(name:'Creature'),
                    levelHint,
                    professionHint: 'Creature'
                );       
                
                angy.nickname = random.pickArrayItem(list:nativeCreatures);
                       
                return angy;  
            },

            
            getLandmarkIndex ::(landmark => Landmark.type) {
                return significantLandmarks->findIndex(value:landmark);
            },
            
            landmarks : {
                get ::<- significantLandmarks
            },
            
            levelMin : {
                get ::<- levelMin
            },
            levelMax : {
                get ::<- levelMax
            },
            
            world : {
                get :: {
                    return world_;
                }
            }

        };
        

    }
);

return Island;
