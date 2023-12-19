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
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:LargeMap = import(module:'game_singleton.largemap.mt');
@:Party = import(module:'game_class.party.mt');
@:Profession = import(module:'game_class.profession.mt');
@:Event = import(module:'game_class.event.mt');
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


@:Island = LoadableClass.new(
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
    
    new::(parent, levelHint, nameHint, state, tierHint) {
        @:this = Island.defaultNew();


        // parent is usually a key
        @:world = import(module:'game_singleton.world.mt');
        @:party = world.party;

        this.initialize(world, party);

        if (state != empty)
            this.load(serialized:state)
        else
            this.defaultLoad(levelHint, nameHint, tierHint);
        return this;
    },
    
    define:::(this) {
   
        // the world
        @world_;

        // current party
        @party_;





        @state;
        
        ::<= {
            @factor = Number.random()*50 + 80;
            @sizeW  = (factor)->floor;
            @sizeH  = (factor*0.5)->floor;
            @:world = import(module:'game_singleton.world.mt');
            state = State.new(
                items : {
                    name : NameGen.island(),

                    // minimum level of encountered individuals
                    levelMin : 0,
                    
                    // maximum level of encountered individuals
                    levelMax : 0,
                    
                    // how often encounters happen between turns.
                    encounterRate : Number.random(),        
                    
                    // Size of the island... Islands are always square-ish
                    sizeW  : sizeW,
                    sizeH  : sizeH,
                    
                    // steps since the last event
                    stepsSinceLastEvent : 0,
                    
                    // map of the region
                    map : LargeMap.create(parent:this, sizeW, sizeH),
                    
                    worldID : world.getNextID(),

                    
                    climate : random.integer(
                        from:Island.CLIMATE.WARM, 
                        to  :Island.CLIMATE.COLD
                    ),
                    
                    events : [], //array of Events
                    
                    
                    // the tier of the island. This determines the difficulty
                    // tier 0-> enemies have no skills or equips. Large chests drop Fire keys 
                    // tier 1-> enemies have 1 to 2 skills, but have no equips. Large chests drop Ice keys 
                    // tier 2-> enemies have 1 to 2 skills and have weapons. Large chests drop Thunder keys 
                    // tier 3-> enemies have all skills and have equips. Large chests drop Light keys
                    // tier 4-> enemies have a random set of all skills and have full equip sets.
                    tier : 0,


                    // every island has hostile creatures.
                    nativeCreatures : [
                        NameGen.creature(),
                        NameGen.creature(),
                        NameGen.creature()
                    ],
                    
                    //Within these, there are 2-6 predominant races per island,
                    //usually in order of population distribution
                    species : ::<={
                        @rarity = 1;
                        return [
                            ... Species.database.getRandomSet(
                                    count : (5+Number.random()*5)->ceil,
                                    filter:::(value) <- value.special == false
                                )
                        ]->map(
                            to:::(value) <- {
                                species: value.name, 
                                rarity: rarity *= 1.4
                            }
                        );
                    },
                    
                    modData : {}
                }
            );
        };


        // augments an entity based on the current tier
        @augmentTiered = ::(entity) {
            match(state.tier) {
              (0): empty, // tier zero has no mods 

              // tier 1: learn 1 to 2 skills
              (1):::<= {
                entity.learnNextAbility();
                if (Number.random() > 0.5)
                    entity.learnNextAbility();
                          
              },
              

              // tier 2: learn 1 to 2 skills and get equips
              (2):::<= {
                entity.learnNextAbility();
                if (Number.random() > 0.5)
                    entity.learnNextAbility();
              
                @:Item = import(module:'game_class.item.mt');
                // add a weapon
                @:wep = Item.Base.database.getRandomFiltered(
                    filter:::(value) <-
                        value.isUnique == false &&
                        value.hasAttribute(attribute:Item.ATTRIBUTE.WEAPON)
                );
                    
                entity.equip(
                    slot:Entity.EQUIP_SLOTS.HAND_LR, 
                    item:Item.new(
                        base:wep,
                        from: entity
                    ), 
                    inventory:entity.inventory, 
                    silent:true
                );
              },
              


              // tier 3: learn 1 to 2 skills and get equips
              (3):::<= {
                for(0, 10)::(i) {
                    entity.learnNextAbility();                
                }

              
                @:Item = import(module:'game_class.item.mt');
                // add a weapon
                @:wep = Item.Base.database.getRandomFiltered(
                    filter:::(value) <-
                        value.isUnique == false &&
                        value.hasAttribute(attribute:Item.ATTRIBUTE.WEAPON)
                );
                    
                entity.equip(
                    slot:Entity.EQUIP_SLOTS.HAND_LR, 
                    item:Item.new(
                        base: wep,
                        from: entity
                    ), 
                    inventory:entity.inventory, 
                    silent:true
                );
              },
              
              
              // tier 2: learn 1 to 2 skills and get equips
              (4):::<= {
                for(0, 10)::(i) {
                    entity.learnNextAbility();                
                }

              
                @:Item = import(module:'game_class.item.mt');
                // add a weapon
                @:wep = Item.Base.database.getRandomFiltered(
                    filter:::(value) <-
                        value.isUnique == false &&
                        value.hasAttribute(attribute:Item.ATTRIBUTE.WEAPON)
                );
                    
                entity.equip(
                    slot:Entity.EQUIP_SLOTS.HAND_LR, 
                    item:Item.new(
                        base:wep,
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
                    item:Item.new(
                        base: wep,
                        from: entity
                    ), 
                    inventory:entity.inventory, 
                    silent:true
                );

              }             
              
              
            }        
        }



        


        
        this.interface = {
            initialize ::(world, party) {
                world_ = world;            
                party_ = party;
            
            },
            defaultLoad::(levelHint, nameHint, tierHint) {
                state.tier = tierHint;

                state.levelMin = (levelHint - Number.random() * (levelHint * 0.4))->ceil;
                state.levelMax = (levelHint + Number.random() * (levelHint * 0.4))->floor;
                if (state.levelMin < 1) state.levelMin = 1;
                if (nameHint != empty)
                    state.name = (nameHint) => String;

                @rarity = 1;

                
      


                @locationCount = (1 + (Number.random()*2)->floor); 
                if (locationCount < 1) locationCount = 1;
                for(0, locationCount)::(i) {
                    LargeMap.addLandmark(
                        map:state.map,
                        base:Landmark.Base.database.getRandomWeightedFiltered(
                            filter:::(value) <- value.isUnique == false
                        ),
                        island:this
                    )
                }
                
                // guaranteed gate
                LargeMap.addLandmark(
                    map:state.map,
                    base:Landmark.Base.database.find(name:'Wyvern Gate'),
                    island:this
                )
                


                // guaranteed shrine
                @:story = import(module:'game_singleton.story.mt');
                match(story.tier) {
                    (0):// nothign defeated
                        LargeMap.addLandmark(
                            map:state.map,
                            base:Landmark.Base.database.find(name:'Shrine of Fire'),
                            island:this
                        ),

                    (1):// fire defeated
                        LargeMap.addLandmark(
                            map:state.map,
                            base:Landmark.Base.database.find(name:'Shrine of Ice'),
                            island:this
                        ),

                    (2):// ice defeated
                        LargeMap.addLandmark(
                            map:state.map,
                            base:Landmark.Base.database.find(name:'Shrine of Thunder'),
                            island:this
                        ),
                        
                    (3):// thunder defeated
                        LargeMap.addLandmark(
                            map:state.map,
                            base:Landmark.Base.database.find(name:'Shrine of Light'),
                            island:this
                        ),
                        
                    default:
                        LargeMap.addLandmark(
                            map:state.map,
                            base:Landmark.Base.database.find(name:'Lost Shrine'),
                            island:this
                        )
                }                        

                
                LargeMap.addLandmark(
                    map:state.map,
                    base:Landmark.Base.database.find(name:'Town'),
                    island:this
                )






                LargeMap.addLandmark(
                    map:state.map,
                    base:Landmark.Base.database.find(name:'City'),
                    island:this
                )


                

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
                get ::<- state.tier
            },
            
            map : {
                get:: <- state.map
            },
            
            incrementTime:: {
                // every step, an event can occur.
                //if (stepsSinceLastEvent > 200000) ::<= {
                if (state.stepsSinceLastEvent > 13) ::<= {
                    if (Number.random() > 13 - (state.stepsSinceLastEvent-5) / 5) ::<={
                        // mostly its encounters. 0.1% chance of encounter 
                        if (Number.random() < 0.001) ::<= {
                            this.addEvent(
                                event:Event.new(
                                    base:Event.Base.database.find(name:'Encounter:Normal'),
                                    parent:this 
                                )
                            );
                        } else ::<= {
                            this.addEvent(
                                event:Event.new(
                                    base:Event.Base.database.getRandomFiltered(
                                        filter:::(value) <- !value.name->contains(key:'Encounter')
                                    ),
                                    parent:this
                                )
                            );                        
                        }
                        state.stepsSinceLastEvent = 0;
                    }
                }    
                state.stepsSinceLastEvent += 1;        
            
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
                    professionHint: if (professionHint == empty) Profession.Base.database.getRandomFiltered(filter::(value)<-value.learnable).name else professionHint
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
                    professionHint: Profession.Base.database.getRandomFiltered(filter::(value)<-value.learnable).name
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
