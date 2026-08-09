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
@:Database = import(module:'core/data/database.mt');
@:class = import(module:'Matte.Core.Class');
@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:databaseItemMutatorClass = import(module:'core/data/databaseitemmutatorclass.mt');
@:g = import(module:'base/util/g.mt');



@:TRAIT = {
  NONE : 0,

  // will have no halo or symbol drawn and will not appear in the nearby name list
  INVISIBLE : 1,

  // Hint for generative maps to not make more than one.
  ONE_PER_LANDMARK : 2,

  // Whether this location can be symbolically considered an 
  // an entrance to a different landmark. Mostly used for dungeons.
  ENTRANCE_HINT : 4,

  // Whether this location can be symbolically considered an 
  // exit out of a landmark. Mostly used for dungeons.
  EXIT_HINT : 8  

}

@:reset ::{

@:random = import(module:'core/random.mt');
@:Landmark = import(module:'base/map/landmark.mt');
@:Item = import(module:'base/item.mt');
@:Inventory = import(module:'base/item/inventory.mt');
@:Scene = import(module:'base/scene.mt');
@:windowEvent = import(module:'core/windowevent.mt');
@:State = import(module:'core/data/state.mt');


Location.database.newEntry(data:{
  id: 'base:door',
  name: 'Door',
  rarity: 100000000,
  ownVerb: '',

  descriptions: [
    "A door leading to elsewhere."
  ],
  symbol: '#',
  
  interactions : [
    'base:go-door',
  ],
  
  aggressiveInteractions : [      
  ],
  
  
  traits : TRAIT.ENTRANCE_HINT,
  events : {
  
  }
})



Location.database.newEntry(data:{
  id: 'base:sign',
  name: 'Sign',
  rarity: 100000000,
  ownVerb: '',

  descriptions: [
  ],
  symbol: '',
  
  interactions : [
  ],
  
  aggressiveInteractions : [      
  ],
  
  
  traits : 0,
  events : {
  
  }
})

Location.database.newEntry(data:{
  id: 'base:decoration',
  name: 'Decoration',
  rarity: 100000000,
  ownVerb: '',

  descriptions: [
  ],
  symbol: '',
  
  interactions : [
    'base:redecorate',
  ],
  
  aggressiveInteractions : [      
  ],
  
  
  traits : 0,
  events : {
    onCreate::(location) {
      if (location.landmark.data.decorationCh == empty)
        location.landmark.data.decorationCh = ' '->setCharCodeAt(index:0, value:random.integer(from:33, to:126)); 
      location.symbol = location.landmark.data.decorationCh
    }
  }
})






Location.database.newEntry(data:{
  id: 'base:portal',
  name: 'Portal',
  rarity: 100000000,
  ownVerb: '',
  descriptions: [
    "From somewhere, to somewhere."
  ],
  symbol: ' ',
  
  interactions : [
  ],
  
  aggressiveInteractions : [      
  ],
  traits : TRAIT.ENTRANCE_HINT | TRAIT.INVISIBLE,
  
  events : {  
  
    onStep ::(location, entities) {
      location.portal.use();
      
    }
  }
})


Location.database.newEntry(data:{
  id: 'base:entrance',
  name: 'Entrance',
  rarity: 100000000,
  ownVerb: '',
  traits : TRAIT.ENTRANCE_HINT | TRAIT.INVISIBLE,
  descriptions: [
    "A sturdy gate surrounded by a well-maintained fence around the area.",
    "A decrepit gate surrounded by a feeble attempt at fencing.",
    "A protective gate surrounded by a proper stone wall. Likely for safety."
  ],
  symbol: '',
  
  interactions : [
  ],
  
  aggressiveInteractions : [      
  ],
  events : {
    onStep ::(location){
      @:world = import(module:'base/world.mt');
      @:party = location;
      @:Battle = import(module:'base/battle.mt');

      @:go ::{


        // jumps to the prev menu lock
        windowEvent.queueCustom(
          onEnter::{
            //invaidate a cache
            windowEvent.jumpToTag(name:'VisitIsland');
          }
        );

        windowEvent.queueTransition(
          kind:windowEvent.TRANSITION.FADE_TO_BLACK, 
          renderableStart : location.landmark.map,
          renderableMiddle: location.landmark.island.map
        );
      }
    
      when (location.peaceful == false && 
        (location.landmark.base.id == 'base:town' || location.landmark.base.id == 'base:city')) ::<= {
        windowEvent.queueMessage(
          speaker: '???',
          text: "There they are!!"
        );

        world.battle.start(
          party,              
          allies: party.members,
          enemies: [
            location.landmark.island.newInhabitant(professionHint:'base:guard'),
            location.landmark.island.newInhabitant(professionHint:'base:guard'),
            location.landmark.island.newInhabitant(professionHint:'base:guard'),            
          ]->map(to:::(value){ value.anonymize(); return value;}),
          landmark: {},
          onEnd::(result) {
            match(result) {
              (Battle.RESULTS.ALLIES_WIN,
               Battle.RESULTS.NOONE_WIN): ::<= {
              },
              
              (Battle.RESULTS.ENEMIES_WIN): ::<= {
                @:instance = import(module:'base/instance.mt');
                instance.gameOver(reason:'The party was wiped out.');
              }
            }
          }
        )
         
      }

      go();    
    }
  }
})



Location.database.newEntry(data:{
  id: 'base:entrance',
  name: 'Entrance',
  rarity: 100000000,
  ownVerb: '',
  traits : TRAIT.ENTRANCE_HINT | TRAIT.INVISIBLE,
  descriptions: [
    "A sturdy gate surrounded by a well-maintained fence around the area.",
    "A decrepit gate surrounded by a feeble attempt at fencing.",
    "A protective gate surrounded by a proper stone wall. Likely for safety."
  ],
  symbol: '',
  
  interactions : [
  ],
  
  aggressiveInteractions : [      
  ],
  events : {
    onStep ::(location){
      @:world = import(module:'base/world.mt');
      @:party = location;
      @:Battle = import(module:'base/battle.mt');

      @:go ::{
        location.landmark.island.travel(
          startAnimationRenderable: location.landmark.map
        );
      }
    
      when (location.peaceful == false && 
        (location.landmark.base.id == 'base:town' || location.landmark.base.id == 'base:city')) ::<= {
        windowEvent.queueMessage(
          speaker: '???',
          text: "There they are!!"
        );

        world.battle.start(
          party,              
          allies: party.members,
          enemies: [
            location.landmark.island.newInhabitant(professionHint:'base:guard'),
            location.landmark.island.newInhabitant(professionHint:'base:guard'),
            location.landmark.island.newInhabitant(professionHint:'base:guard'),            
          ]->map(to:::(value){ value.anonymize(); return value;}),
          landmark: {},
          onEnd::(result) {
            match(result) {
              (Battle.RESULTS.ALLIES_WIN,
               Battle.RESULTS.NOONE_WIN): ::<= {
              },
              
              (Battle.RESULTS.ENEMIES_WIN): ::<= {
                @:instance = import(module:'base/instance.mt');
                instance.gameOver(reason:'The party was wiped out.');
              }
            }
          }
        )
         
      }

      go();    
    }
  }
})


Location.database.newEntry(data:{
  id: 'base:dungeon-entrance',
  name: 'Entrance',
  rarity: 100000000,
  ownVerb: '',
  traits : TRAIT.ENTRANCE_HINT,
  descriptions: [
  ],
  symbol: '',
  
  interactions : [
  ],
  
  aggressiveInteractions : [      
  ],
  events : {
    onStep ::(location){
      @:world = import(module:'base/world.mt');
      @:party = location;
      @:Battle = import(module:'base/battle.mt');

      @:go ::{


        // jumps to the prev menu lock
        windowEvent.queueCustom(
          onEnter::{
            //invaidate a cache
            windowEvent.jumpToTag(name:'VisitIsland');
          }
        );

        windowEvent.queueTransition(
          kind:windowEvent.TRANSITION.FADE_TO_BLACK, 
          renderableStart : location.landmark.map,
          renderableMiddle: location.landmark.island.map
        );
      }
    
      when (location.peaceful == false && 
        (location.landmark.base.id == 'base:town' || location.landmark.base.id == 'base:city')) ::<= {
        windowEvent.queueMessage(
          speaker: '???',
          text: "There they are!!"
        );

        world.battle.start(
          party,              
          allies: party.members,
          enemies: [
            location.landmark.island.newInhabitant(professionHint:'base:guard'),
            location.landmark.island.newInhabitant(professionHint:'base:guard'),
            location.landmark.island.newInhabitant(professionHint:'base:guard'),            
          ]->map(to:::(value){ value.anonymize(); return value;}),
          landmark: {},
          onEnd::(result) {
            match(result) {
              (Battle.RESULTS.ALLIES_WIN,
               Battle.RESULTS.NOONE_WIN): ::<= {
              },
              
              (Battle.RESULTS.ENEMIES_WIN): ::<= {
                @:instance = import(module:'base/instance.mt');
                instance.gameOver(reason:'The party was wiped out.');
              }
            }
          }
        )
         
      }

      go();    
    }
  }
})

Location.database.newEntry(data:{
  id: 'base:farm',
  name: 'Farm',
  rarity: 100,
  ownVerb: 'owned',
  symbol: 'F',
  traits: 0,//TRAIT.STRUCTURE_LARGE,

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
  
  events : {
    onFirstInteract ::(location){
      location.ownedBy = location.landmark.island.newInhabitant();
      @:Profession = import(module:'base/entity/profession.mt');
      location.ownedBy.profession = Profession.find(id:'base:farmer');  
      @:story = import(module:'base/story.mt');
      
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
    }
  }
})


Location.database.newEntry(data:{
  id: 'base:person-static',
  name: '',
  rarity: 100,
  ownVerb: '',
  symbol: '',
  traits : 0,

  descriptions: [
  ],
  
  interactions : [
    'base:talk',
    'base:describe-person',
  ],
  
  aggressiveInteractions : [      
    'base:steal',
  ],
  
  
  events : {
    onCreate ::(location) {
      location.ownedBy = location.landmark.island.newInhabitant(
        professionHint: location.data.professionHint
      );

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

      @:owner = location.ownedBy;
      location.name = owner.name;
      
    },
  }
})

Location.database.newEntry(data:{
  name: 'Ore vein',
  id: 'base:ore-vein',
  rarity: 100,
  ownVerb: '???',
  symbol: '%',

  descriptions: [
    "A rocky area with a clearly different color than its surroundings."
  ],
  
  interactions : [
    'base:mine',
    'base:examine'
  ],
  
  aggressiveInteractions : [      
  ],
  
  
  traits : 0,
  events : {}

})


Location.database.newEntry(data:{
  id: 'base:smelter',
  name: 'Smelter',
  rarity: 100,
  ownVerb: '???',
  symbol: 'm',

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
  
  traits : 0,
  events : {}
})

Location.database.newEntry(data:{
  id: 'base:shopkeep',
  name: 'Shopkeep',
  rarity: 100,
  ownVerb: '???',
  symbol: 'm',
  traits : TRAIT.INVISIBLE,

  descriptions: [
  ],
  
  interactions : [
  ],
  
  aggressiveInteractions : [
  ],
  
  
  events : {}
  

})

::<= {
@:restock = ::(location){
  location.inventory.clear();
  location.data.discount = random.integer(from:20, to:50);
  location.inventory.add(item:
    Item.new(
      base:Item.database.getRandomFiltered(
        filter:::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE) /*&&
                  location.ownedBy.level >= value.levelMinimum
                  && value.tier <= location.landmark.island.tier*/ 
                  // specials are wild.
      ),
      forceNeedsAppraisal : false,
      rngEnchantHint:true
    )
  );
  @:item = location.inventory.items[0];
  location.data.originalPrice = (Item.BUY_PRICE_MULTIPLIER* item.price)->floor
  location.data.discountPrice = (Item.BUY_PRICE_MULTIPLIER * item.price * (1 - 0.01*location.data.discount))->floor
}
Location.database.newEntry(data:{
  id: 'base:shop-special',
  name: 'Special!',
  rarity: 100,
  ownVerb: '???',
  symbol: '',
  traits : 0,

  descriptions: [
  ],
  
  interactions : [
    'base:describe-item',
    'base:buy:shop'
  ],
  
  aggressiveInteractions : [
  ],
  
  
  events : {
    onCreate ::(location) {
      restock(location);
    },
    onIncrementTime::(location) {
      @:world = import(module:'base/world.mt');
      if (world.time == world.TIME.MIDNIGHT) ::<= {
        @:items = random.scrambled(:location.inventory.items);
        restock(location);
      }
    },
  
    onPartyEnter ::(location) {
      @:hud = import(:'core/graphics/hud.mt');
      @:item = location.inventory.items[0];
      
      if (item != empty && location.data.hudID == empty)
        location.data.hudID = hud.addDisplay(:[
          'On sale!!!',
          '"' + item.name + '"',
          'Was: ' + g(:location.data.originalPrice) ,
          'Now: ' + g(:location.data.discountPrice) + '('+location.data.discount+'% off!)'
        ]);
    },
    
    onPartyLeave ::(location) {
      @:hud = import(:'core/graphics/hud.mt');
      if (location.data.hudID != empty) {
        hud.removeDisplay(:location.data.hudID);
        location.data.hudID = empty;
      }
    }
  }
  

})
}



::<= {
  @:restockShop::(location) {
    when(location.ownedBy == empty) empty;
    @:world = import(module:'base/world.mt');

    @:addMissing ::(id, minCount) {
      when (Item.database.find(:id).tier > world.island.tier) empty;

      @:found = location.inventory.items->filter(::(value) <- 
        value.base.id == id &&
        world.island.tier >= value.base.tier
      )->size;

      for(found, if (minCount == empty) 1 else minCount) ::(i) {
        location.inventory.add(item:Item.new(
          base:Item.database.find(
            id
          ),
          forceNeedsAppraisal : false
        ));  
      }
    }


    addMissing(id:'base:pickaxe');
    addMissing(id:'base:smithing-hammer');
    addMissing(id:'base:ingot', minCount:6);
    addMissing(id:'base:wyvern-key');
    addMissing(id:'base:escape-stone', minCount:5);
    addMissing(id:'base:storage-stone', minCount:3);
    addMissing(id:'base:life-crystal');
    addMissing(id:'base:potion', minCount:5);
    addMissing(id:'base:scroll', minCount:3);
    addMissing(id:'base:inlet-gem', minCount:7);
    addMissing(id:'base:basic-food', minCount:10);
    addMissing(id:'base:wyvern-flower', minCount:1);
    
    for(location.inventory.items->size, 60 + (location.ownedBy.level / 4)->ceil)::(i) {
      // no weight, as the value scales
      location.inventory.add(item:
        Item.new(
          base:Item.database.getRandomFiltered(
            filter:::(value) <- value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
                      location.ownedBy.level >= value.levelMinimum
                      && value.tier <= location.landmark.island.tier
          ),
          forceNeedsAppraisal : false,
          rngEnchantHint:true
        )
      );
    }  
    
    location.data.shopkeepRestocked = true;
  }

  Location.database.newEntry(data:{
    name: 'Shop',
    id: 'base:shop',
    rarity: 100,
    ownVerb : 'run',
    symbol: '$',

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


    
    traits : 0,
    events : {
      onCreate ::(location) {
        @:Profession = import(module:'base/entity/profession.mt');
        location.ownedBy = location.landmark.island.newInhabitant();      
        location.ownedBy.profession = Profession.find(id:'base:trader');
        location.name = 'Shop';
        location.inventory.maxItems = 100;
      },
      onFirstInteract ::(location) {
        restockShop(location);
      },

      onInteract ::(location) {
        if (location.data.shopkeepRestocked == true) {
          location.data.shopkeepRestocked = false;
          
          windowEvent.queueMessage(
            text: '"We have new items in stock."',
            speaker: location.ownedBy.name
          );
        }
      },

      onIncrementTime::(location) {
        @:world = import(module:'base/world.mt');
        if (world.time == world.TIME.MIDNIGHT) ::<= {
          @:items = random.scrambled(:location.inventory.items);
          
          foreach(items) ::(k, v) <- location.inventory.remove(:v)
          
          if (items->size > 1)
            items->setSize(:(items->size/2)->floor);
          
          restockShop(location);
          
         
        }
      }
    }
  })

  
}


// can either bid or place on auction. Once per day!
::<= {
  @:PRICE_THRESHOLD = 12000;

  @:restock ::(location) {
    @:world = import(module:'base/world.mt');

    location.inventory.clear();
    @:origTier = world.island.tier;
    world.island.tier = 10;
    ::? {
      forever ::{
        @item = Item.new(
          base : Item.database.getRandomFiltered(::(value) <- 
            value.hasTraits(:Item.TRAIT.CAN_BE_APPRAISED)
          ),
          forceNeedsAppraisal : true 
        );
        
        item = item.appraise();
        
        if (item.price * Item.SELL_PRICE_MULTIPLIER > PRICE_THRESHOLD) ::<= {
          location.inventory.add(:item)
          send();
        }
      }
    }
    world.island.tier = origTier;
    
  }

  Location.database.newEntry(data:{
    name: 'Auction House',
    id: 'base:auction-house',
    rarity: 300,
    ownVerb : 'run',
    symbol: '%',
    traits : TRAIT.ONE_PER_LANDMARK,

    descriptions: [
      "A trading location often perused by the wealthy.",
    ],
    interactions : [
      'base:place-auction',
      'base:join-auction',
      'base:talk',
      'base:examine'
    ],
    
    aggressiveInteractions : [
      'base:steal',
      'base:vandalize',      
    ],


    
    events : {
      onFirstInteract ::(location) {
        @:Profession = import(module:'base/entity/profession.mt');
        location.ownedBy = location.landmark.island.newInhabitant();      
        location.ownedBy.profession = Profession.find(id:'base:trader');
        location.name = 'Auction House';
        location.inventory.maxItems = 1;

        @:nameGen = import(module:'base/namegen.mt');
        @:story = import(module:'base/story.mt');

      },
      
      onIncrementTime::(location) {
        @:world = import(module:'base/world.mt');
        if (world.time == world.TIME.MIDNIGHT) ::<= {
          restock(location);
        }
      }
    }
  })
}


Location.database.newEntry(data:{
  name: 'Arts Tecker',
  id: 'base:arts-tecker',
  rarity: 100,
  ownVerb : 'run',
  symbol: '^',

  descriptions: [
    "A mystical and exotic shop that provides services rather than goods.",
  ],
  interactions : [
    'base:buy:arts',
    'base:trade:arts',
    'base:uncover:arts',
    'base:talk',
    'base:examine'
  ],
  
  aggressiveInteractions : [
    'base:steal',
    'base:vandalize',      
  ],


  
  traits : 0,
  events : {
    onFirstInteract ::(location) {
      @:Profession = import(module:'base/entity/profession.mt');
      location.ownedBy = location.landmark.island.newInhabitant();      
      location.ownedBy.profession = Profession.find(id:'base:arcanist');
      location.name = 'Arts Tecker';
      location.inventory.maxItems = 50;

      @:nameGen = import(module:'base/namegen.mt');
      @:story = import(module:'base/story.mt');
        
    },    onIncrementTime::(location) {
      @:world = import(module:'base/world.mt');
      @:Arts = import(:'base/arts.mt');
      if (world.time == world.TIME.MIDNIGHT) ::<= {
        when (location.data.arts == empty) empty;
        @:items = random.scrambled(:location.data.arts);

        items->setSize(:(items->size / 2)->floor);
          
        for(items->size, 15)::(i) {
          location.data.arts->push(:Arts.database.getRandomFiltered(::(value) <-
            value.hasNoTrait(:Arts.TRAIT.SPECIAL) &&
            value.hasTraits(:Arts.TRAIT.SUPPORT)

          ).id);
        }          
      }
    }
  }
})



Location.database.newEntry(data:{
  name: 'Enchant Stand',
  id: 'base:enchant-stand',
  rarity: 100,
  ownVerb : 'run',
  symbol: '$',

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


  
  traits : 0,
  events : {
    onFirstInteract ::(location) {
      location.ownedBy = location.landmark.island.newInhabitant();
    
    
      @:ItemEnchant = import(module:'base/item/enchant.mt');
    
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
    }
  }
})


::<= {

@:restockShop ::(location){
    for(0, 15 + random.integer(from:4, to:6))::(i) {

      location.inventory.add(
        item:Item.new(
          forceNeedsAppraisal : false,
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
}

Location.database.newEntry(data:{
  name: 'Blacksmith',
  id: 'base:blacksmith',
  rarity: 100,
  ownVerb : 'run',
  symbol: '/',

  descriptions: [
    "A modest trading shop. Relatively small.",
    "Extravagant shop with many wild trinkets."
  ],
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


  
  traits : 0,
  events : {
    onFirstInteract ::(location) {
      @:Profession = import(module:'base/entity/profession.mt');
      location.ownedBy = location.landmark.island.newInhabitant();      
      location.ownedBy.profession = Profession.find(id:'base:blacksmith');
      location.name = 'Blacksmith';
      @:story = import(module:'base/story.mt');
      restockShop(location);
    },      
    
    onIncrementTime::(location, time) {
      @:world = import(module:'base/world.mt');
      when(location.ownedBy == empty) empty;
      if (world.time == world.TIME.MIDNIGHT) ::<= {
        @:items = random.scrambled(:location.inventory.items);
        
        foreach(items) ::(k, v) <- location.inventory.remove(:v)
        
        if (items->size > 1)
          items->setSize(:(items->size/2)->floor);
        
        restockShop(location);
        
       
      }
    }
  }
})   
} 


Location.database.newEntry(data:{
  name: 'Chair',
  id: 'base:chair',
  rarity: 100,
  ownVerb : 'run',
  symbol: 'n',
  traits : 0,//TRAIT.STRUCTURE_LARGE,

  descriptions: [
    "A wooden chair.",
  ],
  interactions : [
    'base:sit:chair-cursed',
  ],
  
  aggressiveInteractions : [
    // add a poke option
  ],
  
  events : {}
})

Location.database.newEntry(data:{
  name: 'Tavern',
  id: 'base:tavern',
  rarity: 100,
  ownVerb : 'run',
  symbol: '&',
  traits: 0,//TRAIT.STRUCTURE_LARGE,

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


  
  events : {
    onFirstInteract ::(location) {
      location.ownedBy = location.landmark.island.newInhabitant();      
    }
  }
})

Location.database.newEntry(data:{
  name: 'Arena',
  id: 'base:arena',
  rarity: 100,
  ownVerb : 'run',
  symbol: '!',
  traits : 0,//TRAIT.STRUCTURE_LARGE,

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


  
  events : {
    onFirstInteract ::(location) {
      location.ownedBy = location.landmark.island.newInhabitant();      
    }
  }
})

Location.database.newEntry(data:{
  name: 'Inn',
  id: 'base:inn',
  rarity: 100,
  ownVerb : 'run',
  symbol: '=',
  traits : 0,//TRAIT.STRUCTURE_LARGE,


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


  
  events : {
    onFirstInteract ::(location) {
      location.ownedBy = location.landmark.island.newInhabitant();      
    }
  }
})

Location.database.newEntry(data:{
  name: 'School',
  id: 'base:school',
  rarity: 100,
  ownVerb : 'run',
  symbol: '+',
  traits : 0,//TRAIT.STRUCTURE_LARGE,

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


  
  events : {
    onInteract ::(location) {
      @:Profession = import(:'base/entity/profession.mt');
      if (location.data.professionSet == empty)
        location.data.professionSet = Profession.getRandomSet(count:3)->map(::(value) <- value.id);
    },      
    onCreate ::(location) {
      @:Profession = import(:'base/entity/profession.mt');
      location.ownedBy = location.landmark.island.newInhabitant();
      location.name = 'Profession school';
      location.data.professionSet = Profession.getRandomSet(count:3, filter::(value) <- value.learnable)->map(::(value) <- value.id);
    }
  }
})

Location.database.newEntry(data:{
  name: 'Library',
  id: 'base:library',
  rarity: 100,
  ownVerb : '',
  symbol: '[]',
  traits: TRAIT.ONE_PER_LANDMARK, // large structure

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


  
  events : {}
})


Location.database.newEntry(data:{
  name: 'Gate',
  id: 'base:gate',
  rarity: 100,
  ownVerb : '',
  symbol: '@',
  traits : TRAIT.ONE_PER_LANDMARK,

  descriptions: [
    "A large stone ring, tall enough to fit a few people and a wagon.",
  ],
  interactions : [
    'base:enter-gate',
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {
    // TODO: remove
    onCreate ::(location) {
      location.contested = true;
    }
  }
})




Location.database.newEntry(data:{
  name: 'Stairs Down',
  id: 'base:stairs-down',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '\\',

  descriptions: [
    "Decrepit stairs",
  ],
  interactions : [
    'base:next-floor',
  ],
  
  aggressiveInteractions : [
  ],


  
  traits : TRAIT.EXIT_HINT,
  events : {
    onInteract ::(location) {
      @open = location.isUnlockedWithPlate();
      if (!open)  
        windowEvent.queueMessage(text: 'The entry to the stairway is locked. Perhaps some lever or plate nearby can unlock it.');
      return open;      
    }
  }
})




Location.database.newEntry(data:{
  name: 'Stairs Down',
  id: 'base:stairs-down-fake',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '\\',

  descriptions: [
    "Decrepit stairs?",
  ],
  interactions : [
    'base:next-floor-fake',
  ],
  
  aggressiveInteractions : [
  ],


  
  traits : TRAIT.EXIT_HINT,
  events : {}
})


Location.database.newEntry(data:{
  name: 'Warp Point',
  id: 'base:warp-point',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: 'w',

  descriptions: [
    "Strange stone column that allows travel between 2 points.",
  ],
  interactions : [
    'base:warp-floor',
  ],
  
  aggressiveInteractions : [
  ],


  
  traits : 0,
  events : {
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
    }
  }
})


Location.database.newEntry(data:{
  name: 'Ladder',
  id: 'base:ladder',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '=',

  descriptions: [
    "Ladder leading to the surface.",
  ],
  interactions : [
    'base:climb-up',
  ],
  
  aggressiveInteractions : [
  ],
  traits: TRAIT.EXIT_HINT,

  
  events : {}
})    



Location.database.newEntry(data:{
  name: 'Bed',
  id: 'base:bed',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '',

  descriptions: [
  ],
  interactions : [
    'base:sleep',
  ],
  
  aggressiveInteractions : [
  ],
  traits: 0,
  events : {}
})  


Location.database.newEntry(data:{
  name: '?????',
  id: 'base:treasure-pit',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '?',
  traits: TRAIT.EXIT_HINT,

  descriptions: [
    "A suspicious pit.",
  ],
  interactions : [
    'base:explore-pit',
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {}
})     

Location.database.newEntry(data:{
  name: 'Bank Teller',
  id: 'base:party-chest',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '$',
  traits: 0,


  descriptions: [
  ],
  interactions : [
    'base:bank'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {  
    onCreate ::(location) {
      @:world = import(module:'base/world.mt');        
      world.party.bank.add(item:Item.new(
        base:Item.database.find(id:'thechosen:sentimental-box')
      ));
    }
  }
}) 

    
Location.database.newEntry(data:{
  name: 'Small Chest',
  id: 'base:small-chest',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '$',
  traits: 0,


  descriptions: [
  ],
  interactions : [
    'base:open-chest'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {  
    onCreate ::(location) {
      @:story = import(module:'base/story.mt');
      for(0, 2) ::(i) {
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
      }
    }
  }
}) 



    
Location.database.newEntry(data:{
  name: 'Barred Door',
  id: 'base:barred-door-vertical',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '|',
  traits: 0,


  descriptions: [
  ],
  interactions : [
    'base:break-door'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {    
    onCreate ::(location) {
      location.landmark.map.enableWall(
        x : location.x,
        y : location.y
      );
    }
  }
}) 


Location.database.newEntry(data:{
  name: 'Barred Door',
  id: 'base:barred-door-horizontal',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '▆',
  traits: 0,


  descriptions: [
  ],
  interactions : [
    'base:break-door'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {    
    
    onCreate ::(location) {
      location.landmark.map.enableWall(
        x : location.x,
        y : location.y
      );

    }
  }
}) 


Location.database.newEntry(data:{
  name: 'Item',
  id: 'base:item',
  rarity: 1000000000000,
  ownVerb : 'owned',
  symbol: 'i',
  traits: 0,


  descriptions: [
    'An item of some kind.'
  ],
  interactions : [
    'base:take',
    'base:describe-item',
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {

    onCreate ::(location) {
      @:item = if (random.try(percentSuccess:75))
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
      else 
        Item.new(
          base:Item.database.find(:'base:inlet-gem')
        )


      location.name = item.name;
      location.inventory.add(item:
        item
      );
    }
  }
}) 



Location.database.newEntry(data:{
  name: 'Magic Chest',
  id: 'base:magic-chest',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '$',
  traits : TRAIT.ONE_PER_LANDMARK,
  descriptions: [
  ],
  interactions : [
    'base:open-magic-chest'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {

  
    onCreate ::(location) {
      @:ItemEnchant = import(module:'base/item/enchant.mt');


      @:possibilities = [
        {
          rarity: 10,
          item : Item.new(
            base:Item.database.find(:'base:tablet')                
          )
        },
        
        {
          rarity: 50,
          item: Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- 
                value.hasNoTrait(:Item.TRAIT.UNIQUE) &&
                value.hasTraits(:Item.TRAIT.CAN_BE_APPRAISED)          
            ),
            forceNeedsAppraisal : true
          )
        },
        
        {
          rarity : 40,
          item: Item.new(
            base:Item.database.find(id:'base:seed')
          )
        }
        
      ] 
    
      location.inventory.add(:random.pickArrayItemWeighted(:possibilities).item);
      location.inventory.add(:random.pickArrayItemWeighted(:possibilities).item);
    
    
    }
  }
}) 


Location.database.newEntry(data:{
  name: 'Locked Chest',
  id: 'base:locked-chest',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '$',
  traits: 0,


  descriptions: [
  ],
  interactions : [
    'base:open-chest'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {  
    onInteract ::(location) {
      @open = location.isUnlockedWithPlate();
      if (!open)  
        windowEvent.queueMessage(text: 'The chest is locked. Perhaps some lever or plate nearby can unlock it.');
      return open;      
    },
  
    onCreate ::(location) {
      location.lockWithPressurePlate();  
    
      @:story = import(module:'base/story.mt');
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
    }
  }
}) 


Location.database.newEntry(data:{
  name: 'Pressure Plate',
  id: 'base:pressure-plate',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '=',
  traits: 0,


  descriptions: [
  ],
  interactions : [
    'base:examine-plate',
    'base:press-pressure-plate'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {}
}) 





Location.database.newEntry(data:{
  name: 'Fountain',
  id: 'base:fountain',
  rarity: 4,
  ownVerb : '',
  symbol: 'S',
  traits: TRAIT.ONE_PER_LANDMARK,

  descriptions: [
    'A simple fountain flowing with fresh water.'
  ],
  interactions : [
    'base:drink-fountain'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {
  
  }
});


Location.database.newEntry(data:{
  name: 'Healing Circle',
  id: 'base:healing-circle',
  rarity: 4,
  ownVerb : '',
  symbol: 'O',
  traits: TRAIT.ONE_PER_LANDMARK,

  descriptions: [
    'An inscribed circle containing a one-time use healing spell.'
  ],
  interactions : [
    'base:healing-circle'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {
    onCreate ::(location) {
      location.data.used = false;
    }  
  }

});


Location.database.newEntry(data:{
  name: 'Wyvern Statue',
  id: 'base:wyvern-statue',
  rarity: 4,
  ownVerb : '',
  symbol: 'M',
  traits: 0,

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


  
  events : {
    onCreate ::(location) {
      location.data.hasPrayer = true;
    }
  }
});


Location.database.newEntry(data:{
  name: 'Enchantment Stand',
  id: 'base:enchantment-stand',
  rarity: 4,
  ownVerb : '',
  symbol: '%',
  traits: TRAIT.ONE_PER_LANDMARK,


  descriptions: [
    'A stone stand with magic runes.'
  ],
  interactions : [
    'base:enchant-once'
  ],
  
  aggressiveInteractions : [
  ],

  
  
  events : {
    onCreate ::(location) { 
      @:ItemEnchant = import(module:'base/item/enchant.mt');
      location.data.enchant = ItemEnchant.new()
    }
  }
});


Location.database.newEntry(data:{
  name: 'Clothing Shop',
  id: 'base:clothing-shop',
  rarity: 4,
  ownVerb : 'run',
  symbol: '%',
  traits: TRAIT.ONE_PER_LANDMARK,

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

  
  
  events : {
    onFirstInteract ::(location) {
      @:Profession = import(module:'base/entity/profession.mt');
      @:Entity = import(module:'base/entity.mt');
      @:EntityQuality = import(module:'base/entity/quality.mt');
      @:world = import(module:'base/world.mt');        
      when(world.npcs.mei == empty || world.npcs.mei.isIncapacitated())
        location.ownedBy = empty;

      location.ownedBy = world.npcs.mei;
      location.inventory.maxItems = 50;

      @:nameGen = import(module:'base/namegen.mt');
      @:story = import(module:'base/story.mt');

      for(0, 10)::(i) {
        // no weight, as the value scales
        location.inventory.add(item:
          Item.new(
            base:Item.database.getRandomFiltered(
              filter:::(value) <- value.hasTraits(:Item.TRAIT.APPAREL) && value.hasNoTrait(:Item.TRAIT.UNIQUE)
            ),
            forceNeedsAppraisal : false,
            apparelHint: 'base:wool-plus',
            rngEnchantHint:true
          )
        );
      }
    },  
    
    onInteract ::(location) {
      @:story = import(module:'base/story.mt');
      @:world = import(module:'base/world.mt');  
            
      when(location.ownedBy == empty) ::<= {
        windowEvent.queueMessage(
          text: 'The shop seems empty...'
        );
        return false;
      }
      location.ownedBy.overrideInteract = ::(interaction) {
        when(interaction != 'Hire' && interaction != 'Hire with contract') empty;
        @:story = import(module:'base/story.mt');
        world.npcs.mei = empty;
        world.accoladeEnable(name:'recruitedOPNPC');
      };      
    },
  
    onCreate ::(location) { 
      location.data.peaceful = true;
    }
  }
});

Location.database.newEntry(data:{
  name: 'Potion Shop',
  id: 'base:potion-shop',
  rarity: 4,
  ownVerb : 'run',
  symbol: 'P',
  traits: TRAIT.ONE_PER_LANDMARK,

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

  
  
  events : {
    onFirstInteract ::(location) {
      @:Profession = import(module:'base/entity/profession.mt');
      @:Entity = import(module:'base/entity.mt');
      @:EntityQuality = import(module:'base/entity/quality.mt');
      @:story = import(module:'base/story.mt');
      @:world = import(module:'base/world.mt');        
      when (world.npcs.sylvia == empty || world.npcs.sylvia.isIncapacitated())
        location.ownedBy = empty;

      location.ownedBy = world.npcs.sylvia;
      location.inventory.maxItems = 50;

      @:nameGen = import(module:'base/namegen.mt');
      @:story = import(module:'base/story.mt');

      for(0, 21)::(i) {
        @:item = Item.new(
          base:Item.database.find(:'base:potion')
        );
        
        // scalping is bad!
        item.price *= 5;

        location.inventory.add(item);
      }
    },  
  
    onInteract ::(location) {
      @:story = import(module:'base/story.mt');
      when(location.ownedBy == empty) ::<= {
        windowEvent.queueMessage(
          text: 'The shop seems empty...'
        );
        return false;
      }
      location.ownedBy.overrideInteract = ::(interaction) {
        when(interaction != 'Hire' && interaction != 'Hire with contract') empty;
        @:world = import(module:'base/world.mt');        
        world.npcs.sylvia = empty;
        // Nerfed 'em because too common of an appearance. People can recruit if they want without penalty.
        //world.accoladeEnable(name:'recruitedOPNPC');
      };      
    },
  
    onCreate ::(location) { 
      location.data.peaceful = true;
    }
  }

});

Location.database.newEntry(data:{
  name: 'Fancy Shop',
  id: 'base:fancy-shop',
  rarity: 4,
  ownVerb : 'run',
  symbol: '$',
  traits: TRAIT.ONE_PER_LANDMARK,

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

  
  
  events : {
    onFirstInteract ::(location) {
      @:Profession = import(module:'base/entity/profession.mt');
      @:Entity = import(module:'base/entity.mt');
      @:EntityQuality = import(module:'base/entity/quality.mt');
      @:world = import(module:'base/world.mt');        
      when(world.npcs.faus == empty || world.npcs.faus.isIncapacitated()) empty;
        location.ownedBy = empty
        
      location.ownedBy = world.npcs.faus;
      location.inventory.maxItems = 50;

      @:nameGen = import(module:'base/namegen.mt');
      @:story = import(module:'base/story.mt');



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
            forceNeedsAppraisal : false,
            qualityHint: random.pickArrayItem(list:qualities),
            rngEnchantHint:true
          )
        );
      }
    },  
  
    onInteract ::(location) {
      @:story = import(module:'base/story.mt');
      when(location.ownedBy == empty) ::<= {
        windowEvent.queueMessage(
          text: 'The shop seems empty...'
        );
        return false;
      }
      
      location.ownedBy.overrideInteract = ::(interaction) {
        when(interaction != 'Hire' && interaction != 'Hire with contract') empty;
        @:world = import(module:'base/world.mt');        
        world.npcs.faus = empty;      
        world.accoladeEnable(name:'recruitedOPNPC');
      };    
    },
    
    onCreate ::(location) { 
      location.data.peaceful = true;
    }
  }
});


Location.database.newEntry(data:{
  name: 'Large Chest',
  id: 'base:large-chest',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '$',
  traits: TRAIT.ONE_PER_LANDMARK,

  descriptions: [
    'An extremely ornate, large chest. What\'s inside?'
  ],
  interactions : [
    'base:open-chest'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {
    
    onFirstInteract ::(location) {
      @:nameGen = import(module:'base/namegen.mt');
      @:Story = import(module:'base/story.mt');
      

      @:story = import(module:'base/story.mt');
      
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
          base:Item.database.find(id:'base:wyvern-key')
        )
      );    

      location.inventory.add(item:
        Item.new(
          base:Item.database.find(id:'base:seed')
        )
      );    


    }
  }
})

Location.database.newEntry(data:{
  name: 'Body',
  id: 'base:body',
  rarity: 1000000000000,
  ownVerb : 'owned',
  symbol: '-',
  traits : 0,

  descriptions: [
    'An incapacitated individual.'
  ],
  interactions : [
    'base:loot'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {
    /*
    onPartyEnter ::(location) {
      location.data.hudID = hud.addDisplay(:[
        'Contains: ',
        [...location.ownedBy.inventory.items->map(::(value)<- value.name)]
      ])
    },
    
    onPartyLeave ::(location) {
      hud.removeDisplay(:location.data.hudID);
    },
    */

    onCreate ::(location) {
      @world = import(module:'base/world.mt');  
      if (world.party.inDungeon) ::<= {
        foreach(location.ownedBy.inventory.items)::(i, item) {
          location.inventory.add(:item);
        }
      } else ::<= {
        foreach(location.ownedBy.inventory.items)::(i, item) {
          location.inventory.add(:item);
        }    
      }

      location.ownedBy.inventory.clear();
    }
  }
})    



Location.database.newEntry(data:{
  name: 'Poisonous Goop',
  id: 'base:poison-tile',
  symbol: '~',
  traits : 0,

  descriptions: [
    'This area seems to be covered in an acidic poison. Best not to stay on it for too long.'
  ],
  interactions : [
  ],
  
  aggressiveInteractions : [
  ],


  rarity: 1000000000000,
  ownVerb : '',
  
  events : {
    onStep::(location, entities) {
      
      @:Damage = import(:'base/entity/damage.mt');
      foreach(entities) ::(k, v) {
        when (v.hp <= 1) empty;
        @world = import(module:'base/world.mt');  
        
        if (!world.party.isMember(:v))
          windowEvent.autoSkip = true;

        v.damage(
          attacker: v,
          damage : Damage.new(
            amount: 1,
            damageType: Damage.TYPE.POISON,
            damageClass: Damage.CLASS.HP
          ),
          dodgeable: false,
          exact:true
        )

        if (!world.party.isMember(:v))
          windowEvent.autoSkip = false;
      }
    }
  }
})




Location.database.newEntry(data:{
  name: 'Puddle',
  id: 'base:water-tile',
  rarity: 1000000000000,
  ownVerb : '',
  symbol: '~',
  traits: 0,


  descriptions: [
    'This area seems to be wet. Careful not to slip!'
  ],
  interactions : [
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {}
})





Location.database.newEntry(data:{
  name: 'Lost Item',
  id: 'base:lost-item',
  rarity: 1000000000000,
  ownVerb : 'owned',
  symbol: 'i',
  traits: 0,


  descriptions: [
    'A lost item.'
  ],
  interactions : [
    'base:take'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {}

}) 


Location.database.newEntry(data:{
  name: 'Lost Item',
  id: 'base:lost-item-hostile',
  rarity: 1000000000000,
  ownVerb : 'owned',
  symbol: 'i',
  traits: 0,


  descriptions: [
    'A lost item.'
  ],
  interactions : [
    'base:take'
  ],
  
  aggressiveInteractions : [
  ],


  
  events : {
    onInteract ::(location) {
      @:world = import(module:'base/world.mt');
      when (location.data.alreadyWon == true) empty;

      windowEvent.queueMessage(
        text:'A shadow leapt in from the darkness!'
      );
      world.battle.start(
        party:world.party,              
        allies: [...world.party.members],
        enemies: [location.landmark.island.newHostileCreature(levelHint : location.landmark.island.level-1)],
        landmark: {},
        onEnd::(result) {
          location.data.alreadyWon = true;
          when(world.battle.partyWon()) empty;
            
          @:instance = import(module:'base/instance.mt');
          instance.gameOver(reason:'The party was wiped out.');
        }
      );      
    }
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
    data : empty,
    overrideInteractID : '',
    interactions : empty,
    aggressiveInteractions : empty,
    symbol : '',
    halo : false,
    portal : empty
  },
  statics : {
    TRAIT : {get::<- TRAIT},
    Portal : {
      get ::<- import(module:'base/map/location/portal.mt')
    }
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

      // See Location.TRAIT
      traits : Number,

      
      // events known
      events : Object

    },
    reset,
    knownEvents : [
      // when the location is interacted with, before displaying options
      // The return value is whether to continue with interaction options 
      // or not.
      'onInteract',
      
      // Called on first time interaction is attempted. 
      'onFirstInteract',
      
      // when the location is created
      'onCreate',
      
      // called by the world when the time of day changes, hourly
      'onIncrementTime',
      
      // Called when entities step on the tile.
      // argument: entities, location
      'onStep',
      
      // Called when an entity is entering the location
      'onEntityEnter',
      
      // called when an entity is leaving the location
      'onEntityLeave',
      
      // called when a party comes within interactable range 
      // of the location.
      'onPartyEnter',
      
      // called when a party was in interactable range and 
      // is not any longer. This includes if the party entered  
      // and and left the landmark entirely.
      'onPartyLeave',
    ]
  ),
  
  define:::(this, state) {
    @:random = import(module:'core/random.mt');
    @:Landmark = import(module:'base/map/landmark.mt');
    @:Item = import(module:'base/item.mt');
    @:Inventory = import(module:'base/item/inventory.mt');
    @:Scene = import(module:'base/scene.mt');
    @:windowEvent = import(module:'core/windowevent.mt');

    @landmark_;
    @world = import(module:'base/world.mt');  
    @partyEntered = false;
        
    
    this.interface = {
      initialize ::(landmark, parent) {
        landmark = if (landmark) landmark else parent.parent; // parents of locations are always maps

        if (landmark == empty)
          landmark = import(:'base/world.mt').landmark;

        if (landmark == empty)
          error(:'A location MUST be initialized with a landmark or parent.');

        landmark_ = landmark;   
      },
      defaultLoad ::(base, x, y, ownedByHint, data) {
        state.worldID = world.getNextID();
        state.occupants = []; // entities. non-owners can shift
        state.inventory = Inventory.new(size:30);
        state.data = {}; // simple table
        if (data != empty) {
          foreach(data) ::(k, v) {
            state.data[k] = v
          }
        }
          
        state.interactions = [...base.interactions]
        state.aggressiveInteractions = [...base.aggressiveInteractions]
        state.symbol = base.symbol;
        
        if (base.hasTraits(:Location.TRAIT.INVISIBLE))
          state.halo = false
        else
          state.halo = true;

        state.base = base;
        state.x = if (x) x else 0;
        state.y = if (x) y else 0;
        //state.x = if (xHint == empty) (random.number() * landmark_.width ) else xHint;  
        //state.y = if (yHint == empty) (random.number() * landmark_.height) else yHint;
        if (ownedByHint != empty)
          this.ownedBy = ownedByHint;
             
        @:desc = random.pickArrayItem(list:base.descriptions);
        state.description = if (desc != empty) desc else "";
        base.emit(event:'onCreate', location:this);
        return this;
      },
      
      afterLoad ::{
        if (this.ownedBy)
          this.ownedBy.owns = this;
      },

      worldID : {
        get ::<- state.worldID
      },
      
      overrideInteractID : {
        set ::(value => String) <- state.overrideInteractID = value
      },
      
      targetLandmark : {
        get ::<- state.targetLandmark,
        set ::(value) <- state.targetLandmark = value
      },

      targetLandmarkEntry : {
        get ::<- state.targetLandmarkEntry,
        set ::(value) <- state.targetLandmarkEntry = value
      },
      
      symbol : {
        get ::<- state.symbol,
        set ::(value) <- state.symbol = value
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
      
      partyEntered :: {
        when(partyEntered) empty;
        partyEntered = true;
        state.base.emit(event:'onPartyEnter', location:this);
      },


      partyLeft :: {
        when(partyEntered == false) empty;
        partyEntered = false;
        state.base.emit(event:'onPartyLeave', location:this);
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
          return [...state.occupants];
        }
      },
      
      hasPortal : {
        get::<- state.portal != empty
      },
      
      portal : {
        get ::{
          when (state.portal != empty) state.portal
          when (state.data.linkedPortalID == empty) empty;

          if (state.data.linkedPortalLandmarkID == empty)
            error(:'Portal locations that have a linkedPortalID are also required to have a linkedPortalLandmarkID in their data, as this is the database id of the landmark to create with the portal.');

          state.portal = Location.Portal.new(parent:this, landmarkID:state.data.linkedPortalLandmarkID);
          return state.portal;
        }
      },

      
      enter ::(entity) {
        when (entity->findIndex(:entity) != -1) empty;
        state.occupants->push(:entity);
        state.base.emit(event:'onEntityEnter', location:this, entity);
      },
      
      leave ::(entity) {
        when (entity->findIndex(:entity) == -1) empty;
        state.occupants = state.occupants->filter(::(value) <- value != entity);
        state.base.emit(event:'onEntityLeave', location:this, entity);
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
      
      canInteract ::<- state.interactions->size > 0,
      
      // per location mod data.
      data : {
        get ::<- state.data
      },
      
      // go ahead! add what you like.
      interactions : {
        get ::<- state.interactions
      },
      
      // go ahead! add what you like.
      aggressiveInteractions : {
        get ::<- state.aggressiveInteractions
      },
      
      halo : {
        get ::<- state.halo,
        set ::(value) <- state.halo = value
      },
      
      
      incrementTime :: {
        state.base.emit(event:'onIncrementTime', location:this);
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
        breakpoint();
      
        @world = import(module:'base/world.mt');
        @party = world.party;      
        @:Interaction = import(module:'base/interaction.mt');

      
        @:aggress::(location, party) {
        
          @:choiceNames = [];
          foreach(location.aggressiveInteractions) ::(k, name) {
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
                interaction.interact(location, party);          
                if (!interaction.keepInteractionMenu && windowEvent.canJumpToTag(name:'LocationInteract'))
                  windowEvent.jumpToTag(name:'LocationInteract', goBeforeTag:true, doResolveNext:true);

              }
                
              
              windowEvent.queueAskBoolean(
                prompt: 'Are you sure?',
                onChoice::(which) {
                  when(which == false) empty;
                  interaction.interact(location, party);                                        
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
          state.visited = true;
          this.base.emit(event:'onFirstInteract', location:this);
        }
          
        
          
        when(this.base.emit(event:'onInteract', location:this) == false) empty;
        
        when (state.overrideInteractID != '') 
          Interaction.find(:state.overrideInteractID).interact(party, location:this);

        
        @:interactionNames = [...this.interactions]->map(to:::(value) {
          return Interaction.find(id:value).name;
        });
        
        @:scenarioInteractions = [...world.scenario.base.interactionsLocation]->filter(
          by::(value) <- value.filter(location:this)
        );
          
        @:choices = [
          ...interactionNames,
          ...([...scenarioInteractions]->map(to:::(value) <- value.name))  
        ];
        

        if (this.aggressiveInteractions->keycount)
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
            when(this.aggressiveInteractions->keycount > 0 && choice == choices->size) ::<= {
              aggress(location:this, party);
            }
            
            when(choice-1 >= interactionNames->size) ::<= {
              @:interaction = scenarioInteractions[choice-(1+interactionNames->size)];
              interaction.select(location:this)
              if (!interaction.keepInteractionMenu && windowEvent.canJumpToTag(name:'LocationInteract'))
                windowEvent.jumpToTag(name:'LocationInteract', goBeforeTag:true, doResolveNext:true);
            }
            
            @:interaction = Interaction.find(id:this.interactions[choice-1])
            
            interaction.interact(
              location: this,
              party
            );          

            foreach(party.members) ::(k, v) {
              v.addOpinion(
                fullName : if (this.ownedBy) this.name else 'the ' + this.name
              );
            }


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
