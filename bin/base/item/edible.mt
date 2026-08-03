@:class = import(module:'Matte.Core.Class');
@:State = import(module:'core/data/state.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:random = import(module:'core/random.mt');
@:databaseItemMutatorClass = import(module:'core/data/databaseitemmutatorclass.mt');
@:Database = import(module:'core/data/database.mt');

@:reset ::{
Edible.database.newEntry(data : {
  name: 'Forager\'s Melon',
  id : 'base:foragers-melon',
  description: 'A sweet and smooth fruit that commonly grows on most islands. Not particularly tart, but generally enjoyed by most.',
  nutrientRating: 2,
  fillingRating: 1,
  tier: 0,
  price: 6,
})  

Edible.database.newEntry(data : {
  name: 'Ice Apple',
  id : 'base:ice-apple',
  description: 'A small, common fruit that has a cool and fresh aftertaste, typically eaten after a meal to prevent bad breath.',
  nutrientRating: 2,
  fillingRating: 1,
  tier: 0,
  price: 10,
})  

Edible.database.newEntry(data : {
  name: 'Mango-cherry',
  id : 'base:mango-cherry',
  description: 'A bite-sized fruit from an equally bite-sized tree. Grows easily and quickly in small gardens making them very common as a treat and as an ingredient for baked goods.',
  nutrientRating: 3,
  fillingRating: 0,
  tier: 0,
  price: 10,
})  

Edible.database.newEntry(data : {
  name: 'Fuzzy Pear',
  id : 'base:fuzzy-pear',
  description: 'Common fruit that has a surprisingly long shelflife. It has a distinct bitter note, yet is well-loved by most.',
  nutrientRating: 1,
  fillingRating: 2,
  tier: 0,
  price: 8,
})  


Edible.database.newEntry(data : {
  name: 'Rockfruit',
  id : 'base:rockfruit',
  description: 'Fruit with a rock-hard exterior, often requiring tools to open it. Opening it is well-worth the effort.',
  nutrientRating: 4,
  fillingRating: 0,
  tier: 1,
  price: 20,
})  





Edible.database.newEntry(data : {
  name: 'Utheishir Pepper',
  id : 'base:utheishir-pepper',
  description: 'The famous pepper originally cultivated from the island of Utheishir. Usually dried, it is a common ingredient to savory dishes. It is also eaten raw as a side-dish.',
  nutrientRating: 3,
  fillingRating: 0,
  tier: 0,
  price: 14,
})  

Edible.database.newEntry(data : {
  name: 'Field Onion',
  id : 'base:field-onion',
  description: 'Due to its ubiquitousness across islands and unique flavor, it is a common ingredient for savory dishes. Eating it raw is uncommon.',
  nutrientRating: 1,
  fillingRating: 0,
  tier: 0,
  price: 4,
})  

Edible.database.newEntry(data : {
  name: 'Spiceleaf',
  id : 'base:spiceleaf',
  description: 'A hearty, leafy vegetable with a sweet-and-spicy taste ' +
               'commonly eaten at the end of a meal. Slightly psychoactive and hallucinogenic.',
  nutrientRating: 2,
  fillingRating: 0,
  tier: 0,
  price: 12,
})  


Edible.database.newEntry(data : {
  name: 'Purple Beans',
  id: 'base:purple-beans',
  description: 'A small legume with an earthy note. Normally toxic, it becomes edible once boiled.',
  nutrientRating: 2,
  fillingRating: 3,
  tier: 0,
  price: 14,
})  

Edible.database.newEntry(data : {
  name: 'Matoto',
  id: 'base:matoto',
 description: 'A hearty, red vegetable typically used as an ingredient for dishes due to its savory profile and versatility when cooked.',
  nutrientRating: 2,
  fillingRating: 3,
  tier: 0,
  price: 14,
})  



Edible.database.newEntry(data : {
  name: 'Grain Rice',
  id: 'base:grain-rice',
  description: 'A small seed grown from grass-like plants. Considered a staple food across all islands thanks to its ease of growing and cultivating.',
  nutrientRating: 1,
  fillingRating: 3,
  tier: 0,
  price: 4,
})  


Edible.database.newEntry(data : {
  name: 'Scale Bread',
  id: 'base:scale-bread',
  description: 'A very common baked good from a recipe carried through generations. The recipe is said to have been given from an ancient Wyvern and originally required Snake-Chimera scales. Resembling a small disc, it compliments any meal or can be eaten as a snack.',
  nutrientRating: 0,
  fillingRating: 3,
  tier: 0,
  price: 7,
})

Edible.database.newEntry(data : {
  name: 'Common Alto Moss',
  id: 'base:common-alto-moss',
  description: 'Despite being called "moss", Alto Moss is a lichen that grows on certain ' +
               'tree species. Loved for its earthy taste, fans of this food will ' +
               'argue over minute differences in its flavor profile. This variety, ' +
               'while not particularly sought-after, is commonly enjoyed.',
  nutrientRating: 2,
  fillingRating: 1,
  tier: 0,
  price: 21
})  

Edible.database.newEntry(data : {
  name: 'Alto Moss',
  id: 'base:alto-moss',
  description: 'Despite being called "moss", Alto Moss is a lichen that grows on certain ' +
               'tree species. Loved for its earthy taste, fans of this food will ' +
               'argue over minute differences in its flavor profile. Cultivated '+
               'carefully, this particular grade of Alto Moss is fairly sought-after.',
  nutrientRating: 4,
  fillingRating: 1,
  tier: 2,
  price: 60
})  

Edible.database.newEntry(data : {
  name: 'Black Alto Moss',
  id: 'base:black-alto-moss',
  description: 'Despite being called "moss", Alto Moss is a lichen that grows on certain ' +
               'tree species. Loved for its earthy taste, fans of this food will ' +
               'argue over minute differences in its flavor profile. Black Alto Moss ' + 
               'is cultivated from the rare Kahnemm tree, giving the Alto Moss ' +
               'its distinct flavor and black color. As one of the rarest Alto Mosses, ' +
               'it is considered a delicacy.',
  nutrientRating: 8,
  fillingRating: 1,
  tier: 4,
  price: 300
})  



Edible.database.newEntry(data : {
  name: 'Garlic Bean Curry',
  id: 'base:garlic-bean-curry',
  description: 'Bean, onion, and matoto dish well-specied and served with rice. Considered a staple meal; flavorful, easy-to-make, filling, and nutrient-rich.',
  nutrientRating: 4,
  fillingRating: 4,
  tier: 1,
  price: 40
})
}

@:qualities = [
  {
    name: 'Fresh',
    priceMod: 1.20,
    nutrientRatingMod: 1,
    rarity: 1
  },

  {
    name: 'Delectable',
    priceMod: 20,
    nutrientRatingMod: 2,
    nutrientRatingMod: 2,
    rarity: 10
  },

  {
    name: 'Flavorful',
    priceMod: 1.40,
    nutrientRatingMod: 2,
    rarity: 1
  },

  {
    name: 'Perfect',
    priceMod: 5,
    nutrientRatingMod: 5,
    fillingRatingMod: 5,
    rarity: 30
  },

  {
    name: 'Jumbo',
    priceMod: 1.50,
    fillingRatingMod: 2,
    rarity: 5
  },

  {
    name: 'Meager',
    priceMod: 0.4,
    fillingRatingMod: -2,
    nutrientRatingMod: -1,
    rarity: 5
  }


]

@:starsToString::(stars) {
  @out = '';
  for(0, stars) ::(i) {
    if (i%5 == 0 && i > 0)
      out = out + ' '  
    out = out + '*';
  }
  return out;
}

@:Edible = databaseItemMutatorClass.create(
  name : 'Wyvern.Item.Edible',
  items : {
    nutrientRating : 0,
    fillingRating : 0
  },
  database : Database.new(
    name : 'Wyvern.Item.Edible.Base',   
    attributes : {
      name : String,
      id : String,
      description : String,
      tier : Number,
      price : Number,

      // More EXP
      nutrientRating : Number,
      
      // Lasts longer without needing to eat more 
      fillingRating : Number
    },
    reset 
  ),

  define:::(this, state) {
    @item;
    @:recalculateDescription :: {
      item.setOverrideDescription(:state.base.description + '\n\n' +
        'Nutrients : ' + (if (state.nutrientRating < 1) 'Minimal' else starsToString(:state.nutrientRating)) + '\n' +
        'Filling   : ' + (if (state.fillingRating < 1) 'Minimal' else starsToString(:state.fillingRating))
      );
    }
  
    this.interface = {
      initialize ::(parent) {
        item = parent;
      },
      defaultLoad::(base, parent) {
        item = parent;
        @:world = import(module:'base/world.mt');
        if (base == empty) 
          base = Edible.database.getRandomFiltered(
            ::(value) <- value.tier <= world.island.tier
          );

        state.base = base;
        state.nutrientRating = base.nutrientRating;
        state.fillingRating = base.fillingRating;
        parent.price = base.price*10.4;
        
        if (random.try(percentSuccess:30)) {
          @:qual = random.pickArrayItemWeighted(:qualities);
          
          parent.name = '(' + qual.name + ') ' + base.name;
          parent.price = parent.price * qual.priceMod;
          if (qual.nutrientRatingMod != empty) state.nutrientRating += qual.nutrientRatingMod;
          if (qual.fillingRatingMod != empty) state.fillingRating += qual.fillingRatingMod;
        } else {
          parent.name = base.name;
        }
        parent.price = parent.price->ceil;        
        recalculateDescription();
      },
      
      base : {
        get ::<- state.base
      },
      
      fillingRating : {
        get ::<- state.fillingRating,
        set ::(value) {
          state.fillingRating = value;
          recalculateDescription();
        }
      },

      nutrientRating : {
        get ::<- state.fillingRating,
        set ::(value) {
          state.fillingRating = value;
          recalculateDescription();
        }
      }
    }
  }
);

return Edible;
