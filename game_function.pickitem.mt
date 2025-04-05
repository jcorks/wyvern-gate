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
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:choicesColumns = import(module:'game_function.choicescolumns.mt');
@:g = import(module:'game_function.g.mt');
@:Item = import(:'game_mutator.item.mt');

// needed to preserve order
@:tabbedReqKeys = [
  'Usables',
  'Weapons',
  'Armor / Clothes',
  'Accessories',
  'Keys',
  'Inlet Gems',
  'Misc',
  'Loot',
  'All',
]
@:tabbedReqs = [
  Item.SORT_TYPE.USABLES,
  Item.SORT_TYPE.WEAPON,
  Item.SORT_TYPE.ARMOR_CLOTHES,
  Item.SORT_TYPE.ACCESSORIES,
  Item.SORT_TYPE.KEYS,
  Item.SORT_TYPE.INLET,
  Item.SORT_TYPE.MISC,
  Item.SORT_TYPE.LOOT,
  empty
]



@:STATIC_HEIGHT = 10;




return ::(
  inventory => Inventory.type, 
  canCancel => Boolean, 
  onPick => Function, 
  alternateNames, // map item to name string
  leftWeight, 
  topWeight, 
  prompt, 
  onGetPrompt, 
  onHover, 
  renderable, 
  filter, 
  ignorePriceCeiling,
  keep, 
  pageAfter, 
  onCancel, 
  showPrices, 
  showRarity,
  goldMultiplier, 
  header,
  tabbed,
  onGetHeader,
  onGetFooter,
  includeLoot
) {
  @names = []
  @items = []
  @picked;
  @cancelled = false;
  breakpoint();
    

  @:prepTabbedChoices ::(args) {
    if (filter != empty) 
      error(:"Sorry, buddy: The pickitem interface only supports tabs when a filter isnt set!");

    args->remove(:'prompt');
    args.columns = true;

    args.onGetTabs = ::{
      return tabbedReqKeys
    }
    
    @:preTag = args.onGetChoices;
    args.onGetChoices = ::(tab) {
      filter = ::(value) <- tabbedReqs[tab] == empty || value.base.sortType == tabbedReqs[tab];
      return preTag();
    }
    
    args.onGetMinHeight = ::<- STATIC_HEIGHT + 3;
    args.onGetMinWidth = ::{
      @:oldFilter = filter;
      filter = empty;
      @min = 0;
      @:lists = listGenerator();
      foreach(lists[0]) ::(n, v) {
        @len = 4;
        for(0, 3) ::(i) {
          len += lists[i][n]->length + 2;
        }
        if (len > min)
          min = len
      }
      filter = oldFilter
      return min;
    }
    
    
    args.onChoice = ::(choice, tab) {
      when(choice == 0) empty;
      listGenerator(); // refresh items list
      picked = items[choice-1];
      when(picked == empty) empty;
      onPick(item:picked)    
    }

    if (args.onHover) ::<= {
      args.onHover = ::(choice, tab) {
        when(choice == 0) empty;
        listGenerator(); // refresh items list
        picked = items[choice-1];
        when(picked == empty) empty;
        onHover(item:picked)    
      }
    }
    
  }  

  @:gold = ::(value) {
    @go = value.price * goldMultiplier;
    go = go->ceil;
    return if (go < 1)
      '?G' /// ooooh mysterious!
    else if (go > 9999 && ignorePriceCeiling != true)
      '!!G'
    else
      g(g:go);
  }

  @:listGenerator = ::{
    @:Item = import(:'game_mutator.item.mt'); 
  
    items = if (includeLoot)
      [...inventory.items, ...inventory.loot]
    else 
      [...inventory.items]
    
    
    if (filter != empty)
      items = items->filter(by:filter)
      
    when(items->size == 0)
      empty;

    @:alreadyCounted = [];

    items = items->filter(::(value) {
      when(value.base.hasNoTrait(:Item.TRAIT.STACKABLE)) true;
      if (alreadyCounted[value.base.id] == empty) 
        alreadyCounted[value.base.id] = 0;
      alreadyCounted[value.base.id] += 1;
      when(alreadyCounted[value.base.id] == 1) true;
      return false;
    });

    names = [...items]->map(to:::(value) <- 
      if ((alternateNames != empty) && alternateNames[value])
        alternateNames[value]
      else 
        value.name
    );
    
    @:amounts = items->map(to:::(value) <-
      if (alreadyCounted[value.base.id]->type == Number && alreadyCounted[value.base.id] > 1)
        '(x'+alreadyCounted[value.base.id]+')' 
      else if (value.faveMark != '')
        ' ' + value.faveMark
      else
        ''
    );
    
    when(names->size == 0)
      [[''], [''], ['']]
    
    when(showRarity) ::<={
      @:rarities = items->map(::(value) <-
        value.starsString
      );

      return [names, rarities, amounts];
    
    }
    @:prices = items->map(to:::(value) <- 
      if (showPrices != true) 
        ''
      else
        gold(:value)
    )
    

    return [names, prices, amounts];
  }

  windowEvent.queueNestedResolve(
    onEnter :: {
      when(inventory.items->size == 0) ::<={
        windowEvent.queueMessage(text: "The inventory is empty.");
      }
      breakpoint();
      @:args = {
        leftWeight: if (leftWeight == empty) 1 else leftWeight => Number,
        topWeight:  if (topWeight == empty)  1 else topWeight => Number,
        prompt: if (prompt == empty) 'Choose an item:' else prompt => String,
        onGetPrompt: onGetPrompt,
        canCancel: canCancel,
        jumpTag: 'pickItem',
        separator: '|',
        onGetFooter : onGetFooter,
        leftJustified : [true, if(showRarity)true else false, true],
        pageAfter: STATIC_HEIGHT+2,
        header : header,
        onCancel::{cancelled = true;},
        onHover : if (onHover)
          ::(choice) {
            when(choice == 0) empty;
            onHover(item:items[choice-1])
          }
        else 
          empty,
        renderable : renderable,
        onGetChoices ::<- listGenerator(),
        keep: if (keep == empty) true else keep,
        onChoice ::(choice, tab) {
          when(choice == 0) empty;
          picked = items[choice-1];
          onPick(item:picked);
        }
      }
      
      if (tabbed) ::<= {
        prepTabbedChoices(:args);
        (import(:'game_function.tabbedchoices.mt'))(*args);
      } else 
        choicesColumns(*args);

    },
    
    onLeave ::{
      if (cancelled && onCancel) 
        onCancel();
    }
  )
}
