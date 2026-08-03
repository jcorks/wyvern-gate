@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:random = import(module:'core/random.mt');
@:StatSet = import(module:'base/util/statset.mt');


@:expToNextLevel::(level) {
  return 100 ** (1 + 0.104*level);
}


@:Improvement = LoadableClass.create(
  name: 'Wyvern.Item.Improvement',
  items : {
    left : 0,
    improvements: 0,
    exp : 0,
    expToNext : 100,
    stats : empty
  },
  
  define::(this, state) {
    @item;
    
    this.interface = {
      initialize ::(parent) {
        item = parent;
      },
      
      defaultLoad::(parent) {
        item = parent;
        state.left = if (item.base.id == 'base:none') 0 else random.integer(from:10, to:25);
        state.improvements = 0;
        state.exp = 0;
        state.stats = StatSet.new();        
      },

      left : {
        get::<- state.left,
        set ::(value) <- state.left = value
      },
      
      

      improve ::(exp) {
        @:chunk = if (state.exp + exp > state.expToNext) 
          state.expToNext - state.exp
        else 
          exp;

        state.exp += chunk;
        exp -= chunk;
        @leveled = false;
        if (state.expToNext == state.exp) ::<= {
          state.improvements += 1;
          state.left -= 1;
          if (state.left < 0)
              state.left = 0;
          state.expToNext = expToNextLevel(:state.improvements)->floor;
          state.exp = 0;
          leveled = true;
        }
        
        if (leveled)
          item.recalculateName();
        return exp;
      },

      improvements : {
        get::<- state.improvements,
      },
      
      exp : {
        get ::<- state.exp
      },
      
      expToNext : {
        get ::<- state.expToNext
      },  
      
      stats : {
        get :: {
          if (state.stats == empty) state.stats = StatSet.new();
          return state.stats
        }
      }
    }
  }
);

return Improvement;
