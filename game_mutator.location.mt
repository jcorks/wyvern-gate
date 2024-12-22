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
@:Database = import(module:'game_class.database.mt');
@:class = import(module:'Matte.Core.Class');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');


@:CATEGORY = {  
  ENTRANCE : 0,
  RESIDENTIAL : 1,
  BUSINESS : 2,
  UTILITY : 3,
  EXIT : 4,
  DUNGEON_SPECIAL : 5
}  

@:reset ::{

@:random = import(module:'game_singleton.random.mt');
@:Landmark = import(module:'game_mutator.landmark.mt');
@:Item = import(module:'game_mutator.item.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:Scene = import(module:'game_database.scene.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:State = import(module:'game_class.state.mt');

Location.database.newEntry(data:{
  id: 'base:entrance',
  name: 'Entrance',
  rarity: 100000000,
  ownVerb: '',
  category : CATEGORY.ENTRANCE,
  minStructureSize : 1,
  onePerLandmark : false,
  descriptions: [
    "A sturdy gate surrounded by a well-maintained fence around the area.",
    "A decrepit gate surrounded by a feeble attempt at fencing.",
    "A protective gate surrounded by a proper stone wall. Likely for safety."
  ],
  symbol: '#',
  
  interactions : [
    'base:exit',
  ],
  
  aggressiveInteractions : [      
    'base:vandalize',
  ],
  
  
  minOccupants : 0,
  maxOccupants : 0,
  
  onFirstInteract ::(location){
  
  },

  onInteract ::(location) {
    return true;
  },      

  
  onCreate ::(location) {
  
  },
  
        
  onIncrementTime ::(location, time) {
    // make everyone come home
    //if (time == WORLD.TIME.EVENING) ::<={
      
    //} else ::<={
    
    //}
  }
})

Location.database.newEntry(data:{
  id: 'base:farm',
  name: 'Farm',
  rarity: 100,
  ownVerb: 'owned',
  category : CATEGORY.RESIDENTIAL,
  symbol: 'F',
  minStructureSize : 2,
  onePerLandmark : false,

  descriptions: [
    "A well-maintained farm. Looks like an experienced farmer works it.",
    "An old farm. It looks like it has a rich history.",
    "A modest farm. A little sparse, but well-maintained",
  ],
  
  interactions : [
    'base:talk',
    'base:examine'
  ],
  
  aggressiveInteractions : [      
    'base:steal',
  ],
  
  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location){
    location.ownedBy = location.landmark.island.newInhabitant();
    @:Profession = import(module:'game_database.profession.mt');
    location.ownedBy.profession = Profession.find(id:'base:farmer');  
    location.ownedBy.normalizeStats();        
    @:story = import(module:'game_singleton.story.mt');
    
    for(0, 2+(random.number()*4)->ceil)::(i) {
      // no weight, as the value scales
      location.inventory.add(item:
        Item.new(
          base:Item.database.getRandomFiltered(filter::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE)
                  && value.tier <= location.landmark.island.tier
      
          ),
          rngEnchantHint:true
        )
      );
    }
  },
  
  onInteract ::(location) {
    return true;
  },      
  
  onCreate ::(location) {
  },
        
  onIncrementTime ::(location, time) {
    // make everyone come home
    //if (time == WORLD.TIME.EVENING) ::<={
      
    //} else ::<={
    
    //}
  }
  

})


Location.database.newEntry(data:{
  id: 'base:home',
  name: 'Home',
  rarity: 100,
  ownVerb: 'owned',
  category : CATEGORY.RESIDENTIAL,
  symbol: '',
  minStructureSize : 1,
  onePerLandmark : false,

  descriptions: [
    "A well-kept residence. Looks like it's big enough to hold a few people",
    "An old residence. It looks like it has a rich history.",
    "A modest residence. Not too much in the way of amenities, but probably lived in by someone trustworthy",
    "An ornate residence. Unexpectedly, this seems lived in by people of wealth.",
    "An average residence. Nothing short of ordinary."
  ],
  
  interactions : [
    'base:talk',
    'base:examine'
  ],
  
  aggressiveInteractions : [      
    'base:steal',
    'base:vandalize',
  ],
  
  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {
    location.ownedBy = location.landmark.island.newInhabitant();
    location.ownedBy.normalizeStats();        
    @:story = import(module:'game_singleton.story.mt');
  
    for(0, 2+(random.number()*4)->ceil)::(i) {
      // no weight, as the value scales
      location.inventory.add(
        item:Item.new(
          base:Item.database.getRandomFiltered(filter::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE)
                  && value.tier <= location.landmark.island.tier
      
          ),
          rngEnchantHint:true
        )
      );
    }
  },      
  onInteract ::(location) {      
    return true;

  },      
  
  onCreate ::(location) {
  
  },
        
  onIncrementTime ::(location, time) {
    // make everyone come home
    //if (time == WORLD.TIME.EVENING) ::<={
      
    //} else ::<={
    
    //}
  }
  

})

Location.database.newEntry(data:{
  name: 'Ore vein',
  id: 'base:ore-vein',
  rarity: 100,
  ownVerb: '???',
  category : CATEGORY.UTILITY,
  symbol: '%',
  minStructureSize : 1,

  descriptions: [
    "A rocky area with a clearly different color than its surroundings."
  ],
  
  interactions : [
    'base:mine',
    'base:examine'
  ],
  
  aggressiveInteractions : [      
  ],
  
  
  minOccupants : 0,
  maxOccupants : 0,
  onePerLandmark : false,
  onFirstInteract ::(location) {
  },      
  onInteract ::(location) {
    return true;

  },      
  
  onCreate ::(location) {
  
  },
        
  onIncrementTime ::(location, time) {

  }
  

})


Location.database.newEntry(data:{
  id: 'base:smelter',
  name: 'Smelter',
  rarity: 100,
  ownVerb: '???',
  category : CATEGORY.UTILITY,
  symbol: 'm',
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
    "Heated enough to melt metal."
  ],
  
  interactions : [
    'base:smelt-ore',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:vandalize',            
  ],
  
  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {

  },      
  onInteract ::(location) {
    return true;

  },      
  
  onCreate ::(location) {
  
  },
        
  onIncrementTime ::(location, time) {
    // make everyone come home
    //if (time == WORLD.TIME.EVENING) ::<={
      
    //} else ::<={
    
    //}
  }
  

})



::<= {
  @:restockShop::(location) {
    when(location.ownedBy == empty) empty;

    @:addMissing ::(id) {
      if (location.inventory.items->findIndexCondition(::(value) <- value.base.id == id) == -1)
        location.inventory.add(item:Item.new(base:Item.database.find(
          id
        )));        
    }


    addMissing(:'base:arts-crystal');
    addMissing(:'base:pickaxe');
    addMissing(:'base:smithing-hammer');
    addMissing(:'base:wyvern-key');
    
    for(location.inventory.items->size, 30 + (location.ownedBy.level / 4)->ceil)::(i) {
      // no weight, as the value scales
      location.inventory.add(item:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
                      location.ownedBy.level >= value.levelMinimum
                      && value.tier <= location.landmark.island.tier
          ),
          rngEnchantHint:true
        )
      );
    }  
  }
  Location.database.newEntry(data:{
    name: 'Shop',
    id: 'base:shop',
    rarity: 100,
    ownVerb : 'run',
    category : CATEGORY.BUSINESS,
    symbol: '$',
    onePerLandmark : false,
    minStructureSize : 1,

    descriptions: [
      "A modest trading shop. Relatively small.",
      "Extravagant shop with many wild trinkets."
    ],
    interactions : [
      'base:buy:shop',
      'base:sell:shop',
      'base:bag:shop',
      'base:appraise',
      'base:talk',
      'base:examine'
    ],
    
    aggressiveInteractions : [
      'base:steal',
      'base:vandalize',      
    ],


    
    minOccupants : 0,
    maxOccupants : 0,
    onFirstInteract ::(location) {
      @:Profession = import(module:'game_database.profession.mt');
      location.ownedBy = location.landmark.island.newInhabitant();      
      location.ownedBy.profession = Profession.find(id:'base:trader');
      location.ownedBy.normalizeStats();        
      location.name = 'Shop';
      location.inventory.maxItems = 50;

      @:nameGen = import(module:'game_singleton.namegen.mt');
      @:story = import(module:'game_singleton.story.mt');

      restockShop(location);
    },
    onInteract ::(location) {
      return true;

    },      
    
    onCreate ::(location) {

    },
    
    onIncrementTime::(location) {
      @:world = import(module:'game_singleton.world.mt');
      if (world.time == world.TIME.MIDNIGHT) ::<= {
        @:items = random.scrambled(:location.inventory.items);
        
        foreach(items) ::(k, v) <- location.inventory.remove(:v)
        
        if (items->size > 1)
          items->setSize(:(items->size/2)->floor);
        
        restockShop(location);
        
       
      }
    }
  })
}
Location.database.newEntry(data:{
  name: 'Arts Tecker',
  id: 'base:arts-tecker',
  rarity: 100,
  ownVerb : 'run',
  category : CATEGORY.BUSINESS,
  symbol: '^',
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
    "A mystical and exotic shop that provides services rather than goods.",
  ],
  interactions : [
    'base:trade:arts',
    'base:uncover:arts',
    'base:talk',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:steal',
    'base:vandalize',      
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {
    @:Profession = import(module:'game_database.profession.mt');
    location.ownedBy = location.landmark.island.newInhabitant();      
    location.ownedBy.profession = Profession.find(id:'base:arcanist');
    location.ownedBy.normalizeStats();        
    location.name = 'Arts Tecker';
    location.inventory.maxItems = 50;

    @:nameGen = import(module:'game_singleton.namegen.mt');
    @:story = import(module:'game_singleton.story.mt');




    location.inventory.add(item:Item.new(base:Item.database.find(
      id: 'base:arts-crystal'
    )));        
    location.inventory.add(item:Item.new(base:Item.database.find(
      id: 'base:arts-crystal'
    )));        
  },
  onInteract ::(location) {
    return true;

  },      
  
  onCreate ::(location) {

  },
  
  onIncrementTime::(location, time) {
  
  }
})



Location.database.newEntry(data:{
  name: 'Enchant Stand',
  id: 'base:enchant-stand',
  rarity: 100,
  ownVerb : 'run',
  category : CATEGORY.BUSINESS,
  symbol: '$',
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
    'An enchanter\'s stand.'
  ],
  interactions : [
    'base:enchant',
    'base:disenchant',
    'base:transfer-enchant',
    'base:talk',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:vandalize',      
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {
    location.ownedBy = location.landmark.island.newInhabitant();
  
  
    @:ItemEnchant = import(module:'game_mutator.itemenchant.mt');
  
    location.data.enchants = [
      ItemEnchant.database.getRandom().id,
      ItemEnchant.database.getRandom().id,
      ItemEnchant.database.getRandom().id,
      ItemEnchant.database.getRandom().id
    ];

    for(0, location.data.enchants->keycount)::(i) {
      when (i > location.data.enchants->keycount) empty;
      for(0, location.data.enchants->keycount)::(n) {
        when (i == n) empty;
        when (n > location.data.enchants->keycount) empty;
      
        if (location.data.enchants[i] ==
          location.data.enchants[n])
          location.data.enchants->remove(key:n);
      }
    }
  },      
  onInteract ::(location) {
    return true;

  },      
  
  onCreate ::(location) {


  },
  
  onIncrementTime::(location, time) {
  
  }
})

Location.database.newEntry(data:{
  name: 'Blacksmith',
  id: 'base:blacksmith',
  rarity: 100,
  ownVerb : 'run',
  category : CATEGORY.BUSINESS,
  symbol: '/',
  minStructureSize : 1,

  descriptions: [
    "A modest trading shop. Relatively small.",
    "Extravagant shop with many wild trinkets."
  ],
  onePerLandmark : false,
  interactions : [
    'base:buy:shop',
    'base:forge',
    'base:talk',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:steal',
    'base:vandalize',      
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {
    @:Profession = import(module:'game_database.profession.mt');
    location.ownedBy = location.landmark.island.newInhabitant();      
    location.ownedBy.profession = Profession.find(id:'base:blacksmith');
    location.name = 'Blacksmith';
    location.ownedBy.normalizeStats();
    @:story = import(module:'game_singleton.story.mt');
    for(0, 1 + (location.ownedBy.level / 4)->ceil)::(i) {

      location.inventory.add(
        item:Item.new(
          base: Item.database.getRandomFiltered(
            filter::(value) <- (
              value.hasNoTrait(:Item.TRAIT.UNIQUE) && 
              location.ownedBy.level >= value.levelMinimum &&
              (value.traits & Item.TRAIT.METAL) &&
              (value.traits & Item.TRAIT.HAS_QUALITY)
            )
          )
        )
      );

    }
  },      
  onInteract ::(location) {
    
    return true;

  },      
  
  onCreate ::(location) {

  },
  
  onIncrementTime::(location, time) {
  
  }
})    


Location.database.newEntry(data:{
  name: 'Tavern',
  id: 'base:tavern',
  rarity: 100,
  ownVerb : 'run',
  category : CATEGORY.UTILITY,
  symbol: '&',
  onePerLandmark : false,
  minStructureSize : 2,

  descriptions: [
    "A modest tavern with a likely rich history.",
  ],
  interactions : [
    'base:drink:tavern',
    'base:quest-guild',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:steal',
    'base:vandalize',      
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {
    location.ownedBy = location.landmark.island.newInhabitant();      
    location.ownedBy.normalizeStats();        
  },
  
  onInteract ::(location) {

  },      
  onCreate ::(location) {

  },
  
  onIncrementTime::(location, time) {
  
  }
})

Location.database.newEntry(data:{
  name: 'Arena',
  id: 'base:arena',
  rarity: 100,
  ownVerb : 'run',
  category : CATEGORY.UTILITY,
  symbol: '!',
  onePerLandmark : false,
  minStructureSize : 2,

  descriptions: [
    "A fighting arena",
  ],
  interactions : [
    //'compete',
    'base:bet',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:steal',
    'base:vandalize',      
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {
    location.ownedBy = location.landmark.island.newInhabitant();      
    location.ownedBy.normalizeStats();          
  },
  
  onInteract ::(location) {

  },      
  onCreate ::(location) {

  },
  
  onIncrementTime::(location, time) {
  
  }
})

Location.database.newEntry(data:{
  name: 'Inn',
  id: 'base:inn',
  rarity: 100,
  ownVerb : 'run',
  category : CATEGORY.UTILITY,
  symbol: '=',
  onePerLandmark : false,
  minStructureSize : 2,


  descriptions: [
    "An inn",
  ],
  interactions : [
    'base:rest',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:steal',
    'base:vandalize',      
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {
    location.ownedBy = location.landmark.island.newInhabitant();      
    location.ownedBy.normalizeStats();          
  },
  
  onInteract ::(location) {

  },      
  onCreate ::(location) {

  },
  
  onIncrementTime::(location, time) {
  
  }
})

Location.database.newEntry(data:{
  name: 'School',
  id: 'base:school',
  rarity: 100,
  ownVerb : 'run',
  category : CATEGORY.UTILITY,
  symbol: '+',
  onePerLandmark : false,
  minStructureSize : 2,

  descriptions: [
    "A school.",
  ],
  interactions : [
    'base:learn-profession',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:steal',
    'base:vandalize',      
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {},
  
  onInteract ::(location) {
    
  },      
  onCreate ::(location) {
    location.ownedBy = location.landmark.island.newInhabitant();
    location.name = location.ownedBy.profession.name + ' school';
    location.ownedBy.normalizeStats();        
  },
  
  onIncrementTime::(location, time) {
  
  }
})

Location.database.newEntry(data:{
  name: 'Library',
  id: 'base:library',
  rarity: 100,
  ownVerb : '',
  category : CATEGORY.UTILITY,
  symbol: '[]',
  onePerLandmark : true,
  minStructureSize : 2,

  descriptions: [
    "A library",
  ],
  interactions : [
    'base:browse',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:steal',
    'base:vandalize',      
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {},
  
  onInteract ::(location) {
    
  },      
  onCreate ::(location) {
  },
  
  onIncrementTime::(location, time) {
  
  }
})


Location.database.newEntry(data:{
  name: 'Gate',
  id: 'base:gate',
  rarity: 100,
  ownVerb : '',
  category : CATEGORY.UTILITY,
  symbol: '@',
  onePerLandmark : true,
  minStructureSize : 1,

  descriptions: [
    "A large stone ring, tall enough to fit a few people and a wagon.",
  ],
  interactions : [
    'base:enter-gate',
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  
  onFirstInteract ::(location) {},
  onInteract ::(location) {
    return true;        
  },
  
  onCreate ::(location) {
    location.contested = true;
  },
  
  onIncrementTime::(location, time) {
  
  }
})




Location.database.newEntry(data:{
  name: 'Stairs Down',
  id: 'base:stairs-down',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '\\',
  category : CATEGORY.EXIT,
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
    "Decrepit stairs",
  ],
  interactions : [
    'base:next-floor',
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  
  onFirstInteract ::(location) {},
  onInteract ::(location) {
    @open = location.isUnlockedWithPlate();
    if (!open)  
      windowEvent.queueMessage(text: 'The entry to the stairway is locked. Perhaps some lever or plate nearby can unlock it.');
    return open;      
  },
  
  onCreate ::(location) {
    /*
    if (location.landmark.island.tier > 1) 
      if (random.flipCoin()) ::<= {
        location.lockWithPressurePlate();
      }
    */
  },
  
  onIncrementTime::(location, time) {
  
  }
})

Location.database.newEntry(data:{
  name: 'Warp Point',
  id: 'base:warp-point',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: 'w',
  category : CATEGORY.DUNGEON_SPECIAL,
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
    "Strange stone column that allows travel between 2 points.",
  ],
  interactions : [
    'base:warp-floor',
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  
  onFirstInteract ::(location) {
    when(location.data.warpPoint != empty) empty;
    
    @:possibilities = [...location.landmark.locations]->filter(by::(value) <-
      value.base.id == 'base:warp-point' &&
      value.data.warpPoint == empty &&
      value != location 
    );
    when(possibilities->size == 0) empty;
    
    @:other = possibilities[0];
    other.data.warpPoint = location.worldID;
    location.data.warpPoint = other.worldID;
  },
  onInteract ::(location) {
  },
  
  onCreate ::(location) {
  },
  
  onIncrementTime::(location, time) {
  
  }
})


Location.database.newEntry(data:{
  name: 'Ladder',
  id: 'base:ladder',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '=',
  onePerLandmark : false,
  category : CATEGORY.EXIT,
  minStructureSize : 1,

  descriptions: [
    "Ladder leading to the surface.",
  ],
  interactions : [
    'base:climb-up',
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  
  onFirstInteract ::(location) {},
  onInteract ::(location) {
  },
  
  onCreate ::(location) {
  },
  
  onIncrementTime::(location, time) {
  
  }
})    

Location.database.newEntry(data:{
  name: '?????',
  id: 'base:treasure-pit',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '?',
  category : CATEGORY.EXIT,
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
    "A suspicious pit.",
  ],
  interactions : [
    'base:explore-pit',
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  
  onFirstInteract ::(location) {},
  onInteract ::(location) {
    @:world = import(module:'game_singleton.world.mt');
    return true;
  },
  
  onCreate ::(location) {
    location.contested = true;
  },
  
  onIncrementTime::(location, time) {
  
  }
})     



    
Location.database.newEntry(data:{
  name: 'Small Chest',
  id: 'base:small-chest',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '$',
  category : CATEGORY.UTILITY,
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
  ],
  interactions : [
    'base:open-chest'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {},
  
  onInteract ::(location) {
  },
  
  onCreate ::(location) {
    @:story = import(module:'game_singleton.story.mt');
    location.inventory.add(item:
      Item.new(
        base:Item.database.getRandomFiltered(
          filter:::(value) <- 
            value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
            value.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS) &&
            value.tier <= location.landmark.island.tier
        ),
        rngEnchantHint:true, 
        forceEnchant:true
      )
    );
  },
  
  onIncrementTime::(location, time) {
  
  }
}) 


Location.database.newEntry(data:{
  name: 'Magic Chest',
  id: 'base:magic-chest',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '$',
  category : CATEGORY.UTILITY,
  onePerLandmark : true,
  minStructureSize : 1,

  descriptions: [
  ],
  interactions : [
    'base:open-magic-chest'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {},
  
  onInteract ::(location) {
  },
  
  onCreate ::(location) {
  },
  
  onIncrementTime::(location, time) {
  
  }
}) 


Location.database.newEntry(data:{
  name: 'Locked Chest',
  id: 'base:locked-chest',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '$',
  category : CATEGORY.UTILITY,
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
  ],
  interactions : [
    'base:open-chest'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {},
  
  onInteract ::(location) {
    @open = location.isUnlockedWithPlate();
    if (!open)  
      windowEvent.queueMessage(text: 'The chest is locked. Perhaps some lever or plate nearby can unlock it.');
    return open;      
  },
  
  onCreate ::(location) {
    location.lockWithPressurePlate();  
  
    @:story = import(module:'game_singleton.story.mt');
    for(0, 3) ::{
      location.inventory.add(item:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- 
              value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
              value.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS) 
              && value.tier <= location.landmark.island.tier + 1
          ),
          rngEnchantHint:true, 
          forceEnchant:true
        )
      );
    }
  },
  
  onIncrementTime::(location, time) {
  
  }
}) 


Location.database.newEntry(data:{
  name: 'Pressure Plate',
  id: 'base:pressure-plate',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '=',
  category : CATEGORY.UTILITY,
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
  ],
  interactions : [
    'base:examine-plate',
    'base:press-pressure-plate'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {},
  
  onInteract ::(location) {
  },
  
  onCreate ::(location) {
    location.data.pressed = false;
  },
  
  onIncrementTime::(location, time) {
  
  }
}) 





Location.database.newEntry(data:{
  name: 'Fountain',
  id: 'base:fountain',
  rarity: 4,
  ownVerb : '',
  symbol: 'S',
  category : CATEGORY.DUNGEON_SPECIAL,
  onePerLandmark : true,
  minStructureSize : 1,

  descriptions: [
    'A simple fountain flowing with fresh water.'
  ],
  interactions : [
    'base:drink-fountain'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {},
  
  onInteract ::(location) {
  },
  
  onCreate ::(location) {

  },
  
  onIncrementTime::(location, time) {
  
  }

});


Location.database.newEntry(data:{
  name: 'Healing Circle',
  id: 'base:healing-circle',
  rarity: 4,
  ownVerb : '',
  symbol: 'O',
  category : CATEGORY.DUNGEON_SPECIAL,
  onePerLandmark : true,
  minStructureSize : 1,

  descriptions: [
    'An inscribed circle containing a one-time use healing spell.'
  ],
  interactions : [
    'base:healing-circle'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {},
  
  onInteract ::(location) {
  },
  
  onCreate ::(location) {
    location.data.used = false;
  },
  
  onIncrementTime::(location, time) {
  
  }

});


Location.database.newEntry(data:{
  name: 'Wyvern Statue',
  id: 'base:wyvern-statue',
  rarity: 4,
  ownVerb : '',
  symbol: 'M',
  category : CATEGORY.DUNGEON_SPECIAL,
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
    'A statue depecting a forlorn wyvern holding their hands in the air in sorrow. It\'s very old.',
    'A statue depecting a kneeling wyvern, looking to the sky. It\'s very old.',
    'A statue depecting a wyvern with one wing in the air, and the other wrapping around themself. It\'s very old.',
  ],
  interactions : [
    'base:pray-statue'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {},
  
  onInteract ::(location) {
  },
  
  onCreate ::(location) {
    location.data.hasPrayer = true;

  },
  
  onIncrementTime::(location, time) {
  
  }

});


Location.database.newEntry(data:{
  name: 'Enchantment Stand',
  id: 'base:enchantment-stand',
  rarity: 4,
  ownVerb : '',
  symbol: '%',
  category : CATEGORY.DUNGEON_SPECIAL,
  onePerLandmark : false,
  minStructureSize : 1,

  descriptions: [
    'A stone stand with magic runes.'
  ],
  interactions : [
    'base:enchant-once'
  ],
  
  aggressiveInteractions : [
  ],

  
  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {
  },  
  
  onInteract ::(location) {
  },
  
  onCreate ::(location) { 
    @:ItemEnchant = import(module:'game_mutator.itemenchant.mt');
    location.data.enchant = ItemEnchant.new(
      base:ItemEnchant.database.getRandom()
    )
  },
  
  onIncrementTime::(location, time) {
  
  }

});


Location.database.newEntry(data:{
  name: 'Clothing Shop',
  id: 'base:clothing-shop',
  rarity: 4,
  ownVerb : 'run',
  symbol: '%',
  category : CATEGORY.DUNGEON_SPECIAL,
  onePerLandmark : true,
  minStructureSize : 1,

  descriptions: [
    'A makeshift wooden stand with a crude sign depecting a sheep selling clothing.'
  ],
  interactions : [
    'base:buy:shop',
    'base:sell:shop',
    'base:talk',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:steal',
    'base:vandalize'     
  ],

  
  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {
    @:Profession = import(module:'game_database.profession.mt');
    @:Entity = import(module:'game_class.entity.mt');
    @:EntityQuality = import(module:'game_mutator.entityquality.mt');
    @:world = import(module:'game_singleton.world.mt');        
    when(world.npcs.mei == empty || world.npcs.mei.isIncapacitated())
      location.ownedBy = empty;

    location.ownedBy = world.npcs.mei;
    location.inventory.maxItems = 50;

    @:nameGen = import(module:'game_singleton.namegen.mt');
    @:story = import(module:'game_singleton.story.mt');

    for(0, 10)::(i) {
      // no weight, as the value scales
      location.inventory.add(item:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.hasTraits(:Item.TRAIT.APPAREL)
          ),
          apparelHint: 'base:wool-plus',
          rngEnchantHint:true
        )
      );
    }
  },  
  
  onInteract ::(location) {
    @:story = import(module:'game_singleton.story.mt');
    @:world = import(module:'game_singleton.world.mt');  
          
    when(location.ownedBy == empty) ::<= {
      windowEvent.queueMessage(
        text: 'The shop seems empty...'
      );
      return false;
    }
    location.ownedBy.onInteract = ::(interaction) {
      when(interaction != 'Hire' && interaction != 'Hire with contract') empty;
      @:story = import(module:'game_singleton.story.mt');
      world.npcs.mei = empty;
      world.accoladeEnable(name:'recruitedOPNPC');
    };      
  },
  
  onCreate ::(location) { 
    location.data.peaceful = true;
  },
  
  onIncrementTime::(location, time) {
  
  }

});

Location.database.newEntry(data:{
  name: 'Potion Shop',
  id: 'base:potion-shop',
  rarity: 4,
  ownVerb : 'run',
  symbol: 'P',
  category : CATEGORY.DUNGEON_SPECIAL,
  onePerLandmark : true,
  minStructureSize : 1,

  descriptions: [
    'A makeshift wooden stand with a crude sign depecting a drake-kin selling potions.'
  ],
  interactions : [
    'base:buy:shop',
    'base:sell:shop',
    'base:talk',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:steal',
    'base:vandalize'     
  ],

  
  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {
    @:Profession = import(module:'game_database.profession.mt');
    @:Entity = import(module:'game_class.entity.mt');
    @:EntityQuality = import(module:'game_mutator.entityquality.mt');
    @:story = import(module:'game_singleton.story.mt');
    @:world = import(module:'game_singleton.world.mt');        
    when (world.npcs.sylvia == empty || world.npcs.sylvia.isIncapacitated())
      location.ownedBy = empty;

    location.ownedBy = world.npcs.sylvia;
    location.inventory.maxItems = 50;

    @:nameGen = import(module:'game_singleton.namegen.mt');
    @:story = import(module:'game_singleton.story.mt');

    for(0, 14)::(i) {
      @:item = Item.new(
        base:Item.database.getRandomFiltered(
          filter:::(value) <- value.name->contains(key:'Potion')
        )
      );
      
      // scalping is bad!
      item.price *= 10;

      location.inventory.add(item);
    }
  },  
  
  onInteract ::(location) {
    @:story = import(module:'game_singleton.story.mt');
    when(location.ownedBy == empty) ::<= {
      windowEvent.queueMessage(
        text: 'The shop seems empty...'
      );
      return false;
    }
    location.ownedBy.onInteract = ::(interaction) {
      when(interaction != 'Hire' && interaction != 'Hire with contract') empty;
      @:world = import(module:'game_singleton.world.mt');        
      world.npcs.sylvia = empty;
      // Nerfed 'em because too common of an appearance. People can recruit if they want without penalty.
      //world.accoladeEnable(name:'recruitedOPNPC');
    };      
  },
  
  onCreate ::(location) { 
    location.data.peaceful = true;
  },
  
  onIncrementTime::(location, time) {
  
  }

});

Location.database.newEntry(data:{
  name: 'Fancy Shop',
  id: 'base:fancy-shop',
  rarity: 4,
  ownVerb : 'run',
  symbol: '$',
  category : CATEGORY.DUNGEON_SPECIAL,
  onePerLandmark : true,
  minStructureSize : 1,

  descriptions: [
    'A surprisingly ornate and refined shopping stand.'
  ],
  interactions : [
    'base:buy:shop',
    'base:sell:shop',
    'base:talk',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:steal',
    'base:vandalize'  
  ],

  
  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract ::(location) {
    @:Profession = import(module:'game_database.profession.mt');
    @:Entity = import(module:'game_class.entity.mt');
    @:EntityQuality = import(module:'game_mutator.entityquality.mt');
    @:world = import(module:'game_singleton.world.mt');        
    when(world.npcs.faus == empty || world.npcs.faus.isIncapacitated()) empty;
      location.ownedBy = empty
      
    location.ownedBy = world.npcs.faus;
    location.inventory.maxItems = 50;

    @:nameGen = import(module:'game_singleton.namegen.mt');
    @:story = import(module:'game_singleton.story.mt');



    @:qualities = [
      'base:legendary',
      'base:divine',
      'base:masterwork',
      'base:queens',
      'base:kings'
    ]


    for(0, 10)::(i) {
      // no weight, as the value scales
      location.inventory.add(item:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.hasTraits(:Item.TRAIT.HAS_QUALITY)
          ),
          qualityHint: random.pickArrayItem(list:qualities),
          rngEnchantHint:true
        )
      );
    }
  },  
  
  onInteract ::(location) {
    @:story = import(module:'game_singleton.story.mt');
    when(location.ownedBy == empty) ::<= {
      windowEvent.queueMessage(
        text: 'The shop seems empty...'
      );
      return false;
    }
    
    location.ownedBy.onInteract = ::(interaction) {
      when(interaction != 'Hire' && interaction != 'Hire with contract') empty;
      @:world = import(module:'game_singleton.world.mt');        
      world.npcs.faus = empty;      
      world.accoladeEnable(name:'recruitedOPNPC');
    };    
  },
  
  onCreate ::(location) { 
    location.data.peaceful = true;
  },
  
  onIncrementTime::(location, time) {
  
  }

});


Location.database.newEntry(data:{
  name: 'Large Chest',
  id: 'base:large-chest',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '$',
  category : CATEGORY.UTILITY,
  minStructureSize : 1,
  onePerLandmark : true,

  descriptions: [
    'An extremely ornate, large chest. What\'s inside?'
  ],
  interactions : [
    'base:open-chest'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  
  onFirstInteract ::(location) {
    @:nameGen = import(module:'game_singleton.namegen.mt');
    @:Story = import(module:'game_singleton.story.mt');
    

    @:story = import(module:'game_singleton.story.mt');
    for(0, 3)::(i) {
      location.inventory.add(item:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE) 
                      && value.tier <= location.landmark.island.tier
          ),
          rngEnchantHint:true
        )
      );
    }
    
    location.inventory.add(item:
      Item.new(
        base:Item.database.getRandomFiltered(
          filter:::(value) <- 
            value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
            value.hasTraits(:Item.TRAIT.HAS_QUALITY)          
        ),
        qualityHint : 'base:masterwork',
        rngEnchantHint:true
      )
    );    

    location.inventory.add(item:
      Item.new(
        base:Item.database.getRandomFiltered(
          filter:::(value) <- 
            value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
            value.hasTraits(:Item.TRAIT.CAN_BE_APPRAISED)          
        ),
        forceNeedsAppraisal : true
      )
    );   

    location.inventory.add(item:
      Item.new(
        base:Item.database.find(id:'base:perfect-arts-crystal')
      )
    );    


  },
  onInteract ::(location) {
  },
  
  onCreate ::(location) {

  },
  
  onIncrementTime::(location, time) {
  
  }
})

Location.database.newEntry(data:{
  name: 'Body',
  id: 'base:body',
  rarity: 1000000000000,
  ownVerb : 'owned',
  symbol: '-',
  category : CATEGORY.DUNGEON_SPECIAL,
  minStructureSize : 1,
  onePerLandmark : false,

  descriptions: [
    'An incapacitated individual.'
  ],
  interactions : [
    'base:loot'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract::(location){},      
  onInteract ::(location) {
  },
  
  onCreate ::(location) {
    foreach(location.ownedBy.inventory.items)::(i, item) {
      location.inventory.add(item);
    }
    location.ownedBy.inventory.clear();
  },
  
  onIncrementTime::(location, time) {
  
  }
})    

Location.database.newEntry(data:{
  name: 'Lost Item',
  id: 'base:lost-item',
  rarity: 1000000000000,
  ownVerb : 'owned',
  symbol: 'i',
  category : CATEGORY.DUNGEON_SPECIAL,
  minStructureSize : 1,
  onePerLandmark : false,

  descriptions: [
    'A lost item.'
  ],
  interactions : [
    'base:take'
  ],
  
  aggressiveInteractions : [
  ],


  
  minOccupants : 0,
  maxOccupants : 0,
  onFirstInteract::(location){},      
  onInteract ::(location) {
  },
  
  onCreate ::(location) {
  },
  
  onIncrementTime::(location, time) {
  
  }
}) 

}


@:Location = databaseItemMutatorClass.create(
  name: 'Wyvern.Location',
  items : {
    worldID : 0,
    targetLandmark : empty, // where this location could take the party. Could be a different island in theory
    targetLandmarkEntry : empty, // where in the landmark to take to. Should be an X-Y if populated, else its the locations responsibility to populate as needed.
    base : empty,
    occupants : empty, // entities. non-owners can shift
    ownedBy : empty,// entity
    description : '',
    inventory : empty,
    x : 0,
    y : 0,
    contested : false,
    name : '',
    data : empty, // simple table
    visited : false,
    data : empty
  },
  statics : {
    CATEGORY : {get ::<- CATEGORY}
  },

  
  database : Database.new(
    name: 'Wyvern.Location.Base',
    attributes : {
      id: String,
      name: String,
      rarity: Number,
      descriptions : Object,
      symbol : String,
      
      // List of interaction names
      interactions : Object,
      
      // List of interaction names that will mark you as 
      // hostile by the owner / occupants. Might initiate 
      // combat
      aggressiveInteractions : Object,
      
      ownVerb : String,
      // number of people aside from the owner
      minOccupants : Number,
      // number of people aside from the owner
      maxOccupants : Number,
      
      // Whether there can only be one per landmark.
      // This is strictly followed in dungeons.
      onePerLandmark: Boolean,

      // when the location is interacted with, before displaying options
      // The return value is whether to continue with interaction options 
      // or not.
      onInteract : Function,
      
      // Called on first time interaction is attempted. 
      onFirstInteract : Function,
      
      // when the location is created
      onCreate : Function,
      // called by the world when the time of day changes, hourly
      onIncrementTime : Function,
      // the type of location it is
      category : Number,
      
      // in structural maps, this determines the structure 
      // size in min units.
      minStructureSize : Number
    },
    reset
  ),
  
  define:::(this, state) {
    @:random = import(module:'game_singleton.random.mt');
    @:Landmark = import(module:'game_mutator.landmark.mt');
    @:Item = import(module:'game_mutator.item.mt');
    @:Inventory = import(module:'game_class.inventory.mt');
    @:Scene = import(module:'game_database.scene.mt');
    @:windowEvent = import(module:'game_singleton.windowevent.mt');

    @landmark_;
    @world = import(module:'game_singleton.world.mt');  

        
    
    this.interface = {
      initialize ::(landmark, parent) {
        landmark = if (landmark) landmark else parent.parent; // parents of locations are always maps

        if (landmark == empty)
          landmark = import(:'game_singleton.world.mt').landmark;

        if (landmark == empty)
          error(:'A location MUST be initialized with a landmark or parent.');

        landmark_ = landmark;   
      },
      defaultLoad ::(base, x, y, ownedByHint) {
        state.worldID = world.getNextID();
        state.occupants = []; // entities. non-owners can shift
        state.inventory = Inventory.new(size:30);
        state.data = {}; // simple table
        state.data = {};


        state.base = base;
        state.x = if (x) x else 0;
        state.y = if (x) y else 0;
        //state.x = if (xHint == empty) (random.number() * landmark_.width ) else xHint;  
        //state.y = if (yHint == empty) (random.number() * landmark_.height) else yHint;
        if (ownedByHint != empty)
          this.ownedBy = ownedByHint;
             
        @:desc = random.pickArrayItem(list:base.descriptions);
        state.description = if (desc != empty) desc else "";
        base.onCreate(location:this);
        return this;
      },
      
      afterLoad ::{
        if (this.ownedBy)
          this.ownedBy.owns = this;
      },

      worldID : {
        get ::<- state.worldID
      },
      
      targetLandmark : {
        get ::<- state.targetLandmark,
        set ::(value) <- state.targetLandmark = value
      },

      targetLandmarkEntry : {
        get ::<- state.targetLandmarkEntry,
        set ::(value) <- state.targetLandmarkEntry = value
      },

      
      inventory : {
        get ::<- state.inventory
      },
      ownedBy : {
        get ::<- state.ownedBy,
        set ::(value) {
          if (state.ownedBy != empty)
            state.ownedBy.owns = empty;
          state.ownedBy = value      
          if (value != empty)      
            value.owns = this;
        }
      },
      
      data : {
        get ::<- state.data
      },
      
      description : {
        get ::<- state.description + (if (state.ownedBy != empty && state.base.ownVerb != '') ' This ' + state.base.name + ' is ' + state.base.ownVerb + ' by ' + state.ownedBy.name + '.' else '')
      },
      
      contested : {
        get ::<- state.contested,
        set ::(value) <- state.contested = value
      },
      x : {
        get:: <- state.x,
        set::(value) <- state.x = value
      },
      
      y : {
        get:: <- state.y,
        set::(value) <- state.y = value
      },
      
      inventory : {
        get :: <- state.inventory
      },
      
      name : {
        get::<- if (state.name == "") (if (state.ownedBy == empty) state.base.name else (state.ownedBy.name + "'s " + state.base.name)) else state.name,
        set::(value) <- state.name = value
      },
      occupants : {
        get :: {
          return state.occupants;
        }
      },
      
      discovered : {
        get :: <- true
      },  
      
      
      landmark : {
        get ::<- landmark_,
        set ::(value) <- landmark_ = value
      },
      
      peaceful : {
        get ::{
          when (state.data.peaceful) true;
          return landmark_.peaceful;
        }
      },
      
      // per location mod data.
      data : {
        get ::<- state.data
      },
      
      incrementTime :: {
        state.base.onIncrementTime(location:this);
      },
      
      lockWithPressurePlate :: {
        @:pressurePlate = landmark_.addLocation(
          location: Location.new(landmark: landmark_, base:Location.database.find(:'base:pressure-plate'))
        );
        
        state.data.plateID = pressurePlate.worldID;
        pressurePlate.data.pressed = false;


        if (random.flipCoin()) ::<= {
          // for every pressure plate, there is a trapped 
          // pressure plate.
          @:pressurePlateFake = landmark_.addLocation(
            location: Location.new(landmark: landmark_, base:Location.database.find(:'base:pressure-plate'))
          );
          pressurePlateFake.data.trapped = true;
        }
      },
      
      
      isUnlockedWithPlate :: {
        when(state.data.plateID == empty) true;
        
        @locations = landmark_.locations;
        
        return locations[locations->findIndexCondition(::(value) <- 
          value.base.id == 'base:pressure-plate' &&
          value.worldID == state.data.plateID
        )].data.pressed;
      },
      
      interact ::{
        @world = import(module:'game_singleton.world.mt');
        @party = world.party;      
        @:Interaction = import(module:'game_database.interaction.mt');
        

      
        @:aggress::(location, party) {
        
          @:choiceNames = [];
          foreach(location.base.aggressiveInteractions) ::(k, name) {
            choiceNames->push(value:
              Interaction.find(id:name).name
            );
          }        
          windowEvent.queueChoices(
            prompt: 'Aggress how?',
            choices: choiceNames,
            canCancel : true,
            onChoice ::(choice) {
              when(choice == 0) empty;


              @:interaction = Interaction.find(id:
                location.base.aggressiveInteractions[choice-1]
              );
              
              when (!location.landmark.peaceful) ::<= {
                interaction.onInteract(location, party);          
                if (!interaction.keepInteractionMenu && windowEvent.canJumpToTag(name:'LocationInteract'))
                  windowEvent.jumpToTag(name:'LocationInteract', goBeforeTag:true, doResolveNext:true);

              }
                
              
              windowEvent.queueAskBoolean(
                prompt: 'Are you sure?',
                onChoice::(which) {
                  when(which == false) empty;
                  interaction.onInteract(location, party);                                        
                  if (!interaction.keepInteractionMenu && windowEvent.canJumpToTag(name:'LocationInteract'))
                    windowEvent.jumpToTag(name:'LocationInteract', goBeforeTag:true, doResolveNext:true);
                }
              );
            }
          );
        }      
      
      
        // initial interaction 
        // Initial interaction triggers an event.
        
        if (state.visited == false) ::<= {
          for(0, random.integer(from:state.base.minOccupants, to:state.base.maxOccupants))::(i) {
            state.occupants->push(value:landmark_.island.newInhabitant());
          }
        
        
          state.visited = true;
          this.base.onFirstInteract(location:this);
        }
          
        
        @canInteract = {:::} {
          return this.base.onInteract(location:this);
        }
          
        when(canInteract == false) empty;
        
        @:interactionNames = [...this.base.interactions]->map(to:::(value) {
          return Interaction.find(id:value).name;
        });
        
        @:scenarioInteractions = [...world.scenario.base.interactionsLocation]->filter(
          by::(value) <- value.filter(location:this)
        );
          
        @:choices = [
          ...interactionNames,
          ...([...scenarioInteractions]->map(to:::(value) <- value.name))  
        ];
        

        if (this.base.aggressiveInteractions->keycount)
          choices->push(value: 'Aggress');
          
        windowEvent.queueChoices(
          prompt: this.name + '...',
          choices:choices,
          canCancel : true,
          keep: true,
          jumpTag: 'LocationInteract',
          onChoice::(choice) {
         
            when(choice == 0) empty;

            // aggress
            when(this.base.aggressiveInteractions->keycount > 0 && choice == choices->size) ::<= {
              aggress(location:this, party);
            }
            
            when(choice-1 >= interactionNames->size) ::<= {
              @:interaction = scenarioInteractions[choice-(1+interactionNames->size)];
              interaction.onSelect(location:this)
              if (!interaction.keepInteractionMenu && windowEvent.canJumpToTag(name:'LocationInteract'))
                windowEvent.jumpToTag(name:'LocationInteract', goBeforeTag:true, doResolveNext:true);
            }
            
            @:interaction = Interaction.find(id:this.base.interactions[choice-1])
            
            interaction.onInteract(
              location: this,
              party
            );          
            // the action CAN unload ephemeral landmarks, so check if its valid. 
            if (this.landmark.map != empty)   
              this.landmark.step();
                            
            if (!interaction.keepInteractionMenu && windowEvent.canJumpToTag(name:'LocationInteract'))
              windowEvent.jumpToTag(name:'LocationInteract', goBeforeTag:true, doResolveNext:true);

          }
        );      
      }
    }
  }
);


return Location;
