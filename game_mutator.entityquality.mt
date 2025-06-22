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
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:random = import(module:'game_singleton.random.mt');








@:reset ::{

@:State = import(module:'game_class.state.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

EntityQuality.database.newEntry(
  data : {
    name : 'fur',
    id : 'base:fur',
    appearanceChance : 1,
    plural : false,
    countable : false,
    descriptions : [
      '$0',
      '$0 with $1',
      '$0 with great length and $1',
      '$0 with stripes of $2',
      '$0 with $2 spots',
      '$0 with a $2 color at their extremities'
    ],
    
    trait0qualifiers : [
      'iridescent',
      'soft',
      'pure',
      'deep',
      'mesmerizing',
      'light',
      'dark',
      'quite'
    ],
    trait0qualifierChance: 0.20,
    trait0 : [
      'brown',
      'white',
      'light brown',
      'black',
      'grey',
      'light grey',
      'yellow',
      'goldenrod',
      'grey',
      'tan',
    ],
    
    
    trait1qualifiers : [
      'curious',
      'various',
      'interesting',
      'striking',
    ],
    trait1qualifierChance: 1,
    trait1 : [
      'markings',
      'battlescars',
      'highlights'
    ],
    
    trait2qualifiers : [
      'iridescent',
      'soft',
      'pure',
      'deep',
      'mesmerizing',
      'light',
      'dark',
    ],
    trait2qualifierChance: 0.20,
    trait2 : [
      'brown',
      'white',
      'light brown',
      'black',
      'grey',
      'light grey',
      'yellow',
      'goldenrod',
      'grey',
      'tan',
    ],      
  }
)

EntityQuality.database.newEntry(
  data : {
    name : 'face',
    id : 'base:face',
    appearanceChance : 0.3,
    plural : false,
    countable : true,
    descriptions : [
      '$0',
      'hard to read but seems $0',
      '$0',
      '$0',
      '$0 with $1',
    ],
    trait0qualifiers : [
      'quite',
      'fairly',
      'especially'
    ],
    
    trait0qualifierChance : 0.2,
    
    trait0 : [
      'soft',
      'hard',
      'trusting',
      'gentle',
      'stern',
      'neutral',
    ],

    trait1qualifiers : [
      'small',
      'scattered'
    ],
    
    trait1qualifierChance : 0.2,

    trait1 : [
      'freckles',
      'markings'
    ],
    
    trait2qualifierChance : 0,
    trait2qualifiers : [
    ],
    trait2 : [
    ]       
  }
)


EntityQuality.database.newEntry(
  data : {
    name : 'scales',
    id : 'base:scales',
    appearanceChance : 1,
    plural : true,
    countable : true,
    descriptions : [
      '$0',
      '$0 with $1',
      '$0',
      '$0 with $1',
      '$0 with an interesting pattern that is $2',
      '$0 with various patterns that are $2',
    ],
    
    
    trait0qualifiers : [
      'iridescent',
      'soft',
      'pure',
      'deep',
      'light',
      'dark',
      'quite',
      'especially'
    ],
    trait0qualifierChance: 0.20,
    trait0 : [
      'brown',
      'white',
      'black',
      'green',
      'blue',
      'red',
      'purple',
      'tan'
    ],
    
    
    
    trait1qualifiers : [
      'curious',
      'various',
      'interesting',
      'striking',
    ],
    trait1qualifierChance: 1,
    trait1 : [
      'markings',
      'battlescars',
      'highlights',
      'tattoos',
    ],

    trait2qualifiers : [
      'iridescent',
      'soft',
      'pure',
      'deep',
      'mesmerizing',
      'light',
      'dark',
      'quite',
      'seemingly'
    ],
    trait2qualifierChance: 0.20,
    trait2 : [
      'brown',
      'white',
      'black',
      'green',
      'blue',
      'red',
      'purple',
      'tan'
    ],
          
  }    
)    


EntityQuality.database.newEntry(
  data : {
    name : 'feathers',
    id : 'base:feathers',
    appearanceChance : 1,
    plural : true,
    countable : true,
    descriptions : [
      '$0'
    ],
    trait0qualifiers : [
      'iridescent',
      'soft',
      'pure',
      'deep',
      'light',
      'dark',
      'quite',
      'seemingly'
    ],
    trait0qualifierChance: 0.20,
    trait0 : [
      'brown',
      'white',
      'black',
      'blue',
      'red',
      'purple',
      'tan'
    ],
    
    
    
    trait1qualifiers : [
    ],
    trait1qualifierChance: 1,
    trait1 : [
    ],

    trait2qualifiers : [
    ],
    trait2qualifierChance: 0.20,
    trait2 : [
    ],          
  }
)   

EntityQuality.database.newEntry(
  data : {
    name : 'eyes',
    id : 'base:eyes',
    appearanceChance : 1,
    plural : true,
    countable : true,
    descriptions : [
      '$2 with $1',
      '$0 and $2',
      '$2 and have $1',
      '$2 with $1',
      '$0 and $2',
      '$2 and have $1',
      '$2 with $1',
      '$0 and $2',
      '$2 and have $1',
      'covered with a fabric of some kind',
    ],
    
    trait0qualifierChance : 0.2,
    trait0qualifiers : [
      'especially',
      'quite',
      'noticeably'
    ],
    
    trait0 : [
      'thin',
      'large',
      'small',
    ],    
    
    trait1qualifierChance : 0.1,
    trait1qualifiers : [
    ],
    trait1 : [
      'a gentle affect',
      'a piercing stare',
      'a constant look of boredom',
      'a look of hopeful glee',
      'a look of constant worry'
    ],

    
    trait2qualifiers : [
      'soft',
      'pure',
      'deep',
      'mesmerizing',
      'light',
      'dark',
      'quite'
    ],
    trait2qualifierChance : 0.2,
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

EntityQuality.database.newEntry(
  data : {
    name : 'ears',
    id : 'base:ears',
    plural : true,
    countable : true,
    appearanceChance : 1,
    descriptions : [
      '$0',
      '$0 and emotive',
      '$0 with shining jewelry',
    ],
    trait0qualifierChance : 0.2,
    trait0qualifiers : [],
    trait0 : [
      'small',
      'long',
      'medium-size',
    ],
    
    trait1qualifierChance : 0.2,
    trait1qualifiers : [],
    trait1 : [
    ],
    
    trait2qualifierChance : 0.2,
    trait2qualifiers : [],    
    trait2 : [
    ]       
  }
)    

EntityQuality.database.newEntry(
  data : {
    name : 'horns',
    id : 'base:horns',
    plural : true,
    countable : true,
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
    
    trait0qualifierChance : 0.2,
    trait0qualifiers : [
      'notably',
      'especially'   
    ],
    
    trait0 : [
      'short',
      'large',
      'small',
      'long'
    ],
    
    
    
    trait1qualifierChance : 0.2,
    trait1qualifiers : [
      'quite'
    ],
    trait1 : [
      'sharp',
      'curled',
      'dulled',
      'intimidating'
    ],
    
    trait2qualifierChance : 0.2,
    trait2qualifiers : [],
    trait2 : [
    ]       
  }
)    


EntityQuality.database.newEntry(
  data : {
    name : 'tail',
    id : 'base:tail',
    plural : false,
    countable : true,
    appearanceChance : 1,
    descriptions : [
      '$0',
      '$0',
      '$0',
      '$0',
      '$0',
      '$0',
      '$0 and $1',
    ],
    
    trait0qualifierChance : 0.2,
    trait0qualifiers : [
      'quite',
      'distractingly'
    ],
    trait0 : [
      'small',
      'large',
      'medium-size',
      'long'
    ],
    
    
    trait1qualifierChance : 0.2,
    trait1qualifiers : [],
    trait1 : [
      'fluffy'
    ],
    
    
    
    trait2qualifierChance : 0.2,
    trait2qualifiers : [],
    trait2 : [
    ]       
  }
) 


EntityQuality.database.newEntry(
  data : {
    name : 'snout',
    id : 'base:snout',
    appearanceChance : 1,
    plural : false,
    countable : true,
    descriptions : [
      '$0',
    ],
    
    trait0qualifierChance : 0,
    trait0qualifiers : [],
    trait0 : [
      'short',
      'long',
      'medium-length',
      'small',
      'large'
    ],
    
    trait1qualifierChance : 0,
    trait1qualifiers : [],
    trait1 : [
    ],
    
    trait2qualifierChance : 0,
    trait2qualifiers : [],
    trait2 : [
    ]       
  }
)    


EntityQuality.database.newEntry(
  data : {
    name : 'body',
    id : 'base:body',
    appearanceChance : 1,
    plural : false,
    countable : true,
    descriptions : [
      '$0',
      '$0 and $1',
    ],
    
    
    trait0qualifierChance : 0.2,
    trait0qualifiers : [
      'notably',
    ],    
    trait0 : [
      'short',
      'tall',
      'medium-height',
      'small',
      'large'
    ],
    
    trait1qualifierChance : 0.2,
    trait1qualifiers : [
      'notably',
      'exceedingly',
      'rather',
    ],    
    trait1 : [
      'stocky',
      'stout',
      'slender',
      'lithe',
      'well-toned',
      'rotund',
      'muscular',
      'well-built'
    ],
    
    trait2qualifierChance : 0.2,
    trait2qualifiers : [
    ],    
    trait2 : [
    ]       
  }
) 
}


@:EntityQuality = databaseItemMutatorClass.create(
  name : 'Wyvern.EntityQuality',
  items : {
    trait0 : 0,
    trait1 : 0,
    trait2 : 0,
    descIndex : 0
  },
  database : Database.new(
    name : 'Wyvern.EntityQuality.Base',   
    attributes : {
      name : String,
      id : String,
      plural : Boolean,
      countable : Boolean,
      appearanceChance : Number,
      descriptions : Object,
      trait0 : Object,
      trait0qualifierChance : Number,
      trait0qualifiers : Object,
      
      trait1 : Object,
      trait1qualifierChance : Number,
      trait1qualifiers : Object,

      trait2 : Object,
      trait2qualifierChance : Number,
      trait2qualifiers : Object
    },
    reset 
  ),

  define:::(this, state) {
    
    @:generateTrait::(which, index) {
      @traits;
      @qualifiers;
      @qualifyChance;
      
      match(which) {
        (0) ::<= {
          traits = state.base.trait0;
          qualifiers = state.base.trait0qualifiers;
          qualifyChance = state.base.trait0qualifierChance;
        },

        (1) ::<= {
          traits = state.base.trait1;
          qualifiers = state.base.trait1qualifiers;
          qualifyChance = state.base.trait1qualifierChance;
        },

        (2) ::<= {
          traits = state.base.trait2;
          qualifiers = state.base.trait2qualifiers;
          qualifyChance = state.base.trait2qualifierChance;
        }
      }
      @base = traits[index];
      if (qualifiers->size > 0 && random.try(percentSuccess:100*qualifyChance)) ::<= {
        base = random.pickArrayItem(list:qualifiers) + ' ' + base;
      }

      return base;
    }
    
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

      countable : {
        get :: {
          return state.base.countable;
        },
      },
      
      appearanceChance : {
        get ::<- state.base.appearanceChance
      },
      
      description : {
        get ::{
          @base = state.base.descriptions[state.descIndex];
          if (base->contains(key:'$0')) base = base->replace(key:'$0', with:generateTrait(which:0, index:state.trait0));
          if (base->contains(key:'$1')) base = base->replace(key:'$1', with:generateTrait(which:1, index:state.trait1));
          if (base->contains(key:'$2')) base = base->replace(key:'$2', with:generateTrait(which:2, index:state.trait2));
          return base;
        }
      }       
    }
  
  }
);


return EntityQuality;
