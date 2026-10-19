@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:random = import(module:'core/random.mt');
@:StatSet = import(module:'base/util/statset.mt');


@:expToNextLevel::(level) {
  return 100 ** (1 + 0.104*level);
}


@:Improvement = LoadableClass.create(
  name: 'Wyvern.Item.Improvement',
  items : {
    improvements: 0,
    left: 0,
    stats : empty
  },
  
  define::(this, state) {
    @item;
      
    @:newSet ::<- {
      stat : 0,
      exp : 0,
      expToNext : 100,
      stats : empty
    }

    
    this.interface = {
      initialize ::(parent) {
        item = parent;
      },
      
      defaultLoad::(parent) {
        item = parent;
        state.stats = {};
        foreach(StatSet.NAMES) ::(k, name) {
          state.stats[name] = newSet();
        }
        
        state.left = if (item.base.id == 'base:none') 0 else ((random.integer(from:25, to:50) / 5)->round*5);
      },
      

      left : {
        get::<- state.left,
        set ::(value) <- state.left = value
      },
      
      
      // doesnt check improvement limit, so you can work around it
      levelUp ::(stat) {
        state.improvements += 1;
        state.left -= 1
        if (state.left < 0) state.left = 0;
        state.stats[stat].stat += 1;
        item.price = (item.price * 1.05)->ceil
        item.recalculateName();
      },

      improvements : {
        get::<- state.improvements,
      },
      setExp ::(stat, exp) <- state.stats[stat].exp = exp,
      getExp ::(stat) <- state.stats[stat].exp,
      getExpToNext ::(stat) <- state.stats[stat].expToNext,
      stats : {
        get :: {
          @:inputs = {};
          foreach(state.stats) ::(k, v) {
            inputs[k] = v.stat
          }
          return StatSet.new(
            *(inputs)
          )
        }
      }
    }
  }
);

return Improvement;
