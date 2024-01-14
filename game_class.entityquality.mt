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
@:Database = import(module:'game_class.database.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:random = import(module:'game_singleton.random.mt');
@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');





@:EntityQuality = LoadableClass.create(
    name : 'Wyvern.EntityQuality',
    statics : {
        Base  :::<= {
            @db;
            return {
                get ::<- db,
                set ::(value) <- db = value
            }
        }
    },
    items : {
        trait0 : empty,
        trait1 : empty,
        trait2 : empty,
        descIndex : empty,
        base : empty
    },
    
    define:::(this, state) {
        
        
        
        this.interface = {
            initialize ::{},
            defaultLoad::(base, descriptionHint, trait0Hint, trait1Hint, trait2Hint) {
                state.base = base;            
                
                if (trait0Hint != empty) 
                    state.trait0 = trait0Hint
                else 
                    state.trait0 = random.integer(from:0, to:state.base.trait0->keycount-1);


                if (trait1Hint != empty) 
                    state.trait1 = trait1Hint
                else 
                    state.trait1 = random.integer(from:0, to:state.base.trait1->keycount-1);

                if (trait2Hint != empty) 
                    state.trait2 = trait2Hint
                else 
                    state.trait2 = random.integer(from:0, to:state.base.trait2->keycount-1);
                
                if (descriptionHint != empty) 
                    state.descIndex = descriptionHint
                else 
                    state.descIndex = random.integer(from:0, to:state.base.descriptions->keycount-1);
                
                return this;
                
            },
        
            base : {
                get :: {
                    return state.base;
                }
            },
            
            
            name : {
                get :: {
                    return state.base.name;
                },
            },

            plural : {
                get :: {
                    return state.base.plural;
                },
            },
            
            appearanceChance : {
                get ::<- state.base.appearanceChance
            },
            
            description : {
                get ::{
                    @base = state.base.descriptions[state.descIndex];
                    if (base->contains(key:'$0')) base = base->replace(key:'$0', with:state.base.trait0[state.trait0]);
                    if (base->contains(key:'$1')) base = base->replace(key:'$1', with:state.base.trait1[state.trait1]);
                    if (base->contains(key:'$2')) base = base->replace(key:'$2', with:state.base.trait2[state.trait2]);
                    return base;
                }
            }           
        }
    
    }
);




EntityQuality.Base = Database.create(
    name : 'Wyvern.EntityQuality.Base',     
    attributes : {
        name : String,
        plural : Boolean,
        appearanceChance : Number,
        descriptions : Object,
        trait0 : Object,
        trait1 : Object,
        trait2 : Object
    }            
);


EntityQuality.Base.newEntry(
    data : {
        name : 'fur',
        appearanceChance : 1,
        plural : false,
        descriptions : [
            '$0',
            '$0 with $1',
            'slightly iridescent $0 with $1',
            '$0 with stripes of $2',
            'thick and has $1',
            '$0 with $2 spots',
            '$0 with a $2 color at their extremities'
        ],
        
        trait0 : [
            'brown',
            'white',
            'light brown',
            'black',
            'grey',
            'orange',
            'yellow',
            'goldenrod',
            'pure white',
            'soft grey',
            'tan',
        ],
        
        trait1 : [
            'curious markings',
            'various battlescars',
            'great length',
            'short length',
            'blonde highlights'
        ],
        
        trait2 : [
            'light brown',
            'bright white',
            'hazelnut',
            'deep black',
            'light grey',
            'shiny grey'
        ]             
    }
)

EntityQuality.Base.newEntry(
    data : {
        name : 'face',
        appearanceChance : 0.3,
        plural : false,
        descriptions : [
            '$0',
            '$0',
            '$0',
            '$0',
            '$0 with $1',
        ],
        
        trait0 : [
            'soft',
            'hard',
            'trusting',
            'gentle',
            'stern',
            'neutral',
        ],
        
        trait1 : [
            'freckles',
            'markings'
        ],
        
        trait2 : [
        ]             
    }
)


EntityQuality.Base.newEntry(
    data : {
        name : 'scales',
        appearanceChance : 1,
        plural : true,
        descriptions : [
            '$0',
            '$0 with $1',
            'slightly iridescent $0 with $1',
            '$0 with a checkered pattern of $2',
            'shiny and $1',
        ],
        
        trait0 : [
            'brown',
            'white',
            'black',
            'green',
            'blue',
            'red',
            'purple',
        ],
        
        trait1 : [
            'curious tattoos',
            'various battlescars',
        ],
        
        trait2 : [
            'brown',
            'white',
            'black',
            'green',
            'blue',
            'red',
        ]             
    }
)        


EntityQuality.Base.newEntry(
    data : {
        name : 'feathers',
        appearanceChance : 1,
        plural : true,
        descriptions : [
            '$0',
            '$0 with $1',
            '$0',
            '$0 with $1',
            'slightly iridescent $0 with $1',
            'shiny with $1',
        ],
        
        trait0 : [
            'brown',
            'white',
            'black',
            'green',
            'blue',
            'red',
            'purple',
        ],
        
        trait1 : [
            'curious markings',
        ],
        
        trait2 : [
            'brown',
            'white',
            'black',
            'green',
            'blue',
            'red',
        ]             
    }
)   

EntityQuality.Base.newEntry(
    data : {
        name : 'eyes',
        appearanceChance : 1,
        plural : true,
        descriptions : [
            '$2 with $1',
            'particularly $0 and $2',
            '$0 and $2',
            '$2 and have $1',
            'mesmerizingly $2',
            'covered with a fabric of some kind',
        ],
        trait0 : [
            'rather thin',
            'large',
            'small',
        ],        
        
        trait1 : [
            'a gentle affect',
            'a piercing stare',
            'a constant look of boredom',
            'a look of hopeful glee',
            'a look of constant worry'
        ],

        
        trait2 : [
            'green',
            'blue',
            'red',
            'purple',
            'brown',
            'grey',
            'teal'
        ],
        
    }
)

EntityQuality.Base.newEntry(
    data : {
        name : 'ears',
        plural : true,
        appearanceChance : 1,
        descriptions : [
            '$0',
            '$0 and emotive',
            'pierced and $0',
        ],
        
        trait0 : [
            'small',
            'large',
            'medium-size',
        ],
        
        trait1 : [
        ],
        
        trait2 : [
        ]             
    }
)        

EntityQuality.Base.newEntry(
    data : {
        name : 'horns',
        plural : true,
        appearanceChance : 0.5,
        descriptions : [
            '$0',
            '$0 and $1',
            '$0',
            '$0 and $1',
            '$0',
            '$0 and $1',
            'in multiple sets which are $1'
        ],
        
        trait0 : [
            'short',
            'large',
            'medium-size',
            'long'
        ],
        
        trait1 : [
            'sharp',
            'curled',
            'dulled'
        ],
        
        trait2 : [
        ]             
    }
)        


EntityQuality.Base.newEntry(
    data : {
        name : 'tail',
        plural : false,
        appearanceChance : 1,
        descriptions : [
            '$0',
            '$0 and particularly expressive',
        ],
        
        trait0 : [
            'small',
            'large',
            'medium-size',
        ],
        
        trait1 : [
        ],
        
        trait2 : [
        ]             
    }
) 


EntityQuality.Base.newEntry(
    data : {
        name : 'snout',
        appearanceChance : 1,
        plural : false,
        descriptions : [
            '$0',
        ],
        
        trait0 : [
            'short',
            'long',
            'medium-length',
        ],
        
        trait1 : [
        ],
        
        trait2 : [
        ]             
    }
)        


EntityQuality.Base.newEntry(
    data : {
        name : 'body',
        appearanceChance : 1,
        plural : false,
        descriptions : [
            '$0',
            '$0 and $1',
        ],
        
        trait0 : [
            'short',
            'tall',
            'of medium height',
        ],
        
        trait1 : [
            'stocky',
            'stout',
            'slender',
            'lithe',
            'well-toned',
            'rotund',
        ],
        
        trait2 : [
        ]             
    }
) 

return EntityQuality;
