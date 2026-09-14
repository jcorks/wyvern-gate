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
@:windowEvent = import(module:'core/windowevent.mt');
@:Inventory = import(module:'base/item/inventory.mt');
@:choicesColumns = import(module:'base/widgets/choicescolumns.mt');
@:g = import(module:'base/util/g.mt');
@:Item = import(:'base/item.mt');
@:canvas = import(module:'core/graphics/canvas.mt');
@:Effect = import(module:'base/entity/effect.mt');

// needed to preserve order
@:tabbedReqKeys = [
  'Usables',
  'Food',
  'Weapons',
  'Armor / Clothes',
  'Accessories',
  'Gems',
  'Keys',
  'Misc',
  'Loot',
  //'All',
]
@:tabbedReqs = [
  Item.SORT_TYPE.USABLES,
  Item.SORT_TYPE.FOOD,
  Item.SORT_TYPE.WEAPON,
  Item.SORT_TYPE.ARMOR_CLOTHES,
  Item.SORT_TYPE.ACCESSORIES,
  Item.SORT_TYPE.INLET,
  Item.SORT_TYPE.KEYS,
  Item.SORT_TYPE.MISC,
  Item.SORT_TYPE.LOOT,
  //empty
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
  extraHeader,
  extraLeftJustified,
  tabbed,
  onGetFooter,
  includeLoot,
  onGetExtraColumns
) {
  @names = []
  @items = []
  @picked;
  @cancelled = false;
  @hoveredChoice = 0;
  @tabCounts = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; // lazy,
  @headerReal = [];
  
  @:getCondensedTabs ::{
    @:out = [];
    foreach(tabbedReqKeys) ::(k, v) {
      if (tabCounts[k] != 0) 
        out->push(:v);
    }
    return out;
  }

  if (showPrices == true && showRarity == true)
    error(:'Only prices or rarity can be shown at the same time. You can do custom stuff if youd like instead.');

  @:prepTabbedChoices ::(args) {
    if (filter != empty) 
      error(:"Sorry, buddy: The pickitem interface only supports tabs when a filter isnt set!");

    args->remove(:'prompt');
    args.columns = true;



    args.onGetTabs = ::<- getCondensedTabs()
    
    @:preTag = args.onGetChoices;
    args.onGetChoices = ::(tab) {
      filter = ::(value) { 
        @:name = getCondensedTabs()[tab];
        return value.base.sortType == tabbedReqs[tabbedReqKeys->findIndex(:name)];
      }
      return preTag();
    }
    
    args.onGetMinHeight = ::<- STATIC_HEIGHT + 3;
    args.onGetMinWidth = ::{
      //@:oldFilter = filter;
      //filter = empty;
      @min = 0;
      @:lists = listGenerator();
      foreach(lists[0]) ::(n, v) {
        @len = 4;
        for(0, 2) ::(i) {
          len += lists[i][n]->length + 2;
        }
        if (len > min)
          min = len
      }
      //filter = oldFilter
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
        hoveredChoice = choice;
        when(choice == 0) empty;
        listGenerator(); // refresh items list
        picked = items[choice-1];
        when(picked == empty) empty;
        onHover(item:picked)    
      }
    } else {
      args.onHover = ::(choice, tab) <- hoveredChoice = choice
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
    @:Item = import(:'base/item.mt'); 
  
    items = if (includeLoot)
      [...inventory.items, ...inventory.loot]
    else 
      [...inventory.items]
    
    tabCounts = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; // lazy,
    foreach(items) ::(k, value) {
      tabCounts[tabbedReqs->findIndex(:value.base.sortType)] += 1;
    
    }
    
    if (filter != empty)
      items = items->filter(by:filter)

    breakpoint();
    when(items->size == 0)
      empty;

    @:alreadyCounted = [];


    items = items->filter(::(value) {
      when(value.base.hasNoTrait(:Item.TRAIT.STACKABLE)) true;
      if (alreadyCounted[value.name] == empty) 
        alreadyCounted[value.name] = 0;
      alreadyCounted[value.name] += 1;
      when(alreadyCounted[value.name] == 1) true;
      return false;
    });


    names = [...items]->map(to:::(value) <-     

      (if (value.faveMark != '')
        '[' + value.faveMark + '] '
      else
       ''
      ) +

    
      (if ((alternateNames != empty) && alternateNames[value])
        alternateNames[value]
      else 
        value.name
      ) +
      
      (if (alreadyCounted[value.name]->type == Number && alreadyCounted[value.name] > 1)
        '(x'+alreadyCounted[value.name]+')'
      else 
        ''
      )
      

    );
    
    headerReal = ['Item'];


    
    @:data = [
      ...(
        ::<= {
          when(showRarity) ::<={
            @:rarities = items->map(::(value) <-
              value.starsString
            );
            headerReal->push(:'Value');
            return [names, rarities];
          
          }
          
          when(showPrices) ::<= {
            @:prices = items->map(to:::(value) <-
              gold(:value)
            )
            headerReal->push(:'Price');
            return [names, prices]
          }
          
          return [names];
        }
      ),
      
      // custom
      ...(if (onGetExtraColumns != empty) {
        headerReal = [...headerReal, ...extraHeader];
        return onGetExtraColumns(:items)
      } else 
        [])
    ]
    
    if (data->size != headerReal->size) {
      error(:'Miscount between header size and generated list size. Check your onGetColumns() return value and the preset header.');
    }
    return data;

  }

  listGenerator()

  windowEvent.queueNestedResolve(
    onEnter :: {
      when(inventory.items->size == 0) ::<={
        windowEvent.queueMessage(text: "The inventory is empty.");
      }
      @:args = {
        promptRight: true,
        leftWeight: if (leftWeight == empty) 1 else leftWeight => Number,
        topWeight:  if (topWeight == empty)  1 else topWeight => Number,
        prompt: if (prompt == empty) 'Choose an item:' else prompt => String,
        onGetPrompt: onGetPrompt,
        canCancel: canCancel,
        jumpTag: 'pickItem',
        separator: '|',
        onGetFooter : onGetFooter,
        leftJustified : [true, if(showRarity)true else false, ...(if(extraLeftJustified == empty) [] else extraLeftJustified)],
        pageAfter: STATIC_HEIGHT+2,
        header : headerReal,
        onCancel::{cancelled = true;},
        onHover : if (onHover)
          ::(choice) {
            hoveredChoice = choice
            when(choice == 0) empty;
            onHover(item:items[choice-1])
          }
        else 
          empty,
        renderable : {
          render :: {
            @:Arts = import(module:'base/arts.mt');

            @:choice = hoveredChoice;
            @hoveredItem = items[choice-1];
            when(hoveredItem == empty) empty;
            


            
            @:getArtDesc ::(id1, id2) {
              @:toParts = ::(id) {
                when(id == empty) ['[None]', '']
                @:art = Arts.new(base:Arts.database.find(:id));
                art.charge = 0;
                @:list = Arts.renderListItem(:art);
                return [' ' + list[0], list[1]];
              }
              
              @:parts0 = toParts(:id1);
              @:parts1 = toParts(:id2);
              
              return canvas.columnsToLines(
                columns : [
                  [
                    parts0[0],
                    parts1[0]
                  ],
                  [
                    parts0[1],
                    parts1[1]              
                  ]
                ],
                
                leftJustifieds : [true, true]
              );
            }
            
            when(hoveredItem.inletArt != empty) ::<= {
              canvas.renderTextFrameGeneral(
                title: hoveredItem.name,
                lines: [
                  'Art:',
                  '',
                  ...getArtDesc(id1:hoveredItem.inletArt.base.id)
                ],
                maxWidth: 0.4,
                leftWeight: 0,
                topWeight: 0.5
              )
            }


            when(hoveredItem.inletEffect != empty) ::<= {
              canvas.renderTextFrameGeneral(
                title: hoveredItem.name,
                lines: [
                  'Effect:',
                  '',
                  Effect.find(:hoveredItem.inletEffect).name,
                  Effect.find(:hoveredItem.inletEffect).description
                ],
                maxWidth: 0.4,
                leftWeight: 0,
                topWeight: 0.5
              )
            }

            when(hoveredItem.base.hasTraits(:Item.TRAIT.STRANGE_TO_EQUIP)) empty;

            
            
            canvas.renderTextFrameGeneral(
              title: 'Summary:',
              lines: [
                'Stat boosts:',
                ...(hoveredItem.stats.descriptionRateLines->map(::(value) <- ' ' + value)),
                
                ...([if (hoveredItem.inletSlotSet != empty)
                  '' + hoveredItem.inletSlotSet.size + ' gem slot' + if (hoveredItem.inletSlotSet.size == 1) '.' else 's.'
                else 
                  ''])

              ],
              leftWeight: 0,
              topWeight: 0
            )

            canvas.renderTextFrameGeneral(
              title: 'Summary:',
              lines: [
                'Arts:',
                ...getArtDesc(id1:hoveredItem.arts[0],
                              id2:hoveredItem.arts[1])
              ],
              leftWeight: 0,
              topWeight: 1
            )

            if (renderable != empty) renderable.render()
          }
        },
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
        (import(:'base/widgets/tabbedchoices.mt'))(*args);
      } else 
        choicesColumns(*args);

    },
    
    onLeave ::{
      if (cancelled && onCancel) 
        onCancel();
    }
  )
}
