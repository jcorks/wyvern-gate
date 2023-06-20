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






@:EntityQuality = class(
    name : 'Wyvern.EntityQuality',
    statics : {
        Base : empty
    },
    define:::(this) {
        @base_;
        @descIndex;
        @trait0;
        @trait1;
        @trait2;

        this.constructor = ::(base, descriptionHint, trait0Hint, trait1Hint, trait2Hint, state) {
            when(state != empty) ::<= {
                this.state = state;
                return this;
            };
            base_ = base;            
            
            if (trait0Hint != empty) 
                trait0 = trait0Hint
            else 
                trait0 = random.integer(from:0, to:base_.trait0->keycount);


            if (trait1Hint != empty) 
                trait1 = trait1Hint
            else 
                trait1 = random.integer(from:0, to:base_.trait1->keycount);

            if (trait2Hint != empty) 
                trait2 = trait2Hint
            else 
                trait2 = random.integer(from:0, to:base_.trait2->keycount);
            
            if (descriptionHint != empty) 
                descIndex = descriptionHint
            else 
                descIndex = random.integer(from:0, to:base_.descriptions->keycount);
            
            return this;
            
        };
        
        this.interface = {
            base : {
                get :: {
                    return base_;
                }
            },
            
            
            name : {
                get :: {
                    return base_.name;
                },
            },

            plural : {
                get :: {
                    return base_.plural;
                },
            },
            
            description : {
                get ::{
                    @:base = base_.descriptions[descIndex];
                    return base->replace(key:'$0', with:base_.trait0[trait0])
                               ->replace(key:'$1', with:base_.trait1[trait1])
                               ->replace(key:'$2', with:base_.trait2[trait2]);
                }
            },
            
            state : {
                set ::(value) {
                    base_ = EntityQuality.Base.database.find(name:value.baseName);
                    descIndex = value.descIndex;
                    trait0 = value.trait0;
                    trait1 = value.trait1;
                    trait2 = value.trait2;
                },
                get :: {
                    return {
                        baseName : base_.name,
                        descIndex : descIndex,
                        trait0: trait0,
                        trait1: trait1,
                        trait2: trait2                        
                    };
                }
            }
        };
    
    }
);





EntityQuality.Base = class(
    name : 'Wyvern.EntityQuality.Base',
    statics : {
        database : empty
    },
    define:::(this) {
        Database.setup(
            item: this,
            attributes : {
                name : String,
                plural : Boolean,
                descriptions : Object,
                trait0 : Object,
                trait1 : Object,
                trait2 : Object
            }
        );
        
        this.interface = {
            new ::(descriptionHint, trait0Hint, trait1Hint, trait2Hint) {
                return EntityQuality.new(base:this, descriptionHint, trait0Hint, trait1Hint, trait2Hint);
            } 
        };
    }
);


EntityQuality.Base.database = Database.new(
    items : [
        EntityQuality.Base.new(
            data : {
                name : 'fur',
                plural : false,
                descriptions : [
                    ['$0'],
                    ['$0 with $1'],
                    ['slightly irridescent $0 with $1'],
                    ['$0 with stripes of $2'],
                    ['thick and $1'],
                    ['$0 with $2 spots'],
                ],
                
                trait0 : [
                    'brown',
                    'white',
                    'light brown',
                    'black',
                    'grey',
                    'soft grey'
                ],
                
                trait1 : [
                    'curious markings',
                    'various battlescars',
                    'great length',
                    'short length',
                    'blonde highlights'
                ],
                
                trait2 : [
                    'brown',
                    'white',
                    'light brown',
                    'black',
                    'grey',
                    'soft grey'
                ]             
            }
        ),
        
        
        EntityQuality.Base.new(
            data : {
                name : 'scales',
                plural : true,
                descriptions : [
                    ['$0'],
                    ['$0 with $1'],
                    ['slightly irridescent $0 with $1'],
                    ['$0 with a checkered pattern of $2'],
                    ['shiny and $1'],
                ],
                
                trait0 : [
                    'brown',
                    'white',
                    'black',
                    'green',
                    'blue',
                    'red',
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
        ),        


        EntityQuality.Base.new(
            data : {
                name : 'feathers',
                plural : true,
                descriptions : [
                    ['$0'],
                    ['$0 with $1'],
                    ['slightly irridescent $0 with $1'],
                    ['shiny and $1'],
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
        ),   

        EntityQuality.Base.new(
            data : {
                name : 'eyes',
                plural : true,
                descriptions : [
                    ['$2 with $1.'],
                    ['particularly $0 and $2.'],
                    ['$0 and $2 eyes with $1.'],
                    ['mesmerizingly $2.'],
                    ['covered with a fabric of some kind.'],
                ],
                trait0 : [
                    'rather thin',
                    'large',
                    'small',
                ],        
                
                trait1 : [
                    'a gentle affect',
                    'a piercing stare',
                    'a blinded left eye',
                    'a blinded right eye',
                    'a constant look for boredom',
                    'a look of hopeful glee',
                    'a look of constant worry'
                ],

                
                trait2 : [
                    'green',
                    'blue',
                    'red',
                    'purple',
                    'brown',
                    'grey'
                ],
                
            }
        ),
        
        EntityQuality.Base.new(
            data : {
                name : 'ears',
                plural : true,
                descriptions : [
                    ['$0'],
                    ['$0 and emotive'],
                    ['pierced and $0'],
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
        ),        

        EntityQuality.Base.new(
            data : {
                name : 'snout',
                plural : false,
                descriptions : [
                    ['$0'],
                    ['$0 and spotted'],
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
        ),        


        EntityQuality.Base.new(
            data : {
                name : 'body',
                plural : false,
                descriptions : [
                    ['$0'],
                    ['$0 and $1'],
                ],
                
                trait0 : [
                    'short',
                    'tall',
                    'of medium height',
                ],
                
                trait1 : [
                    'stocky',
                    'slender',
                    'lithe',
                    'well-toned',
                    'rotund',
                ],
                
                trait2 : [
                ]             
            }
        ), 

    ]
);

return EntityQuality;
