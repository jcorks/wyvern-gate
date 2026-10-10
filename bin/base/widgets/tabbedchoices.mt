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

@:windowEvent = import(:"core/windowevent.mt");

@:renderPrompt::(tabs, selected, tabNames, columns) {
  @line = '';
  @tabName = tabNames[selected]
  @maxLen = 0;
  foreach(tabNames) ::(k, v) {
    if (v->length > maxLen)
      maxLen = v->length;
  }
  @:pad = ::(str) {
    @:strs = [];
    for(0, maxLen/2 - str->length/2) ::(i) {
      strs->push(:' ');
    }
    strs->push(:str);
    for(maxLen/2 + str->length/2, maxLen) ::(i) {
      strs->push(:' ');
    }

    return String.combine(:strs);
  }
  
  @:hasItems = ::(v) <- tabs[v] != empty && (if (columns) tabs[v][0]->size else tabs[v]->size) > 0  
  @:filtered = tabNames->filter(::(value) <- hasItems(:value));
  selected = filtered->findIndex(value:tabName);
  foreach(filtered) ::(k, v) {
    @distance = (k-selected);
    
    when(distance < 0) empty;
      /*
      line = line + match(distance) {
        (-1):     '[<-',
        (-2, -3): '[<',
        default:  '['
      };
      */

    when(distance > 0)
      line = line + match(distance) {
        (1):     '->]',
        (2, 3):   ']',
        default:   ']'
      };

    line = line + '<<< ' + (pad(:filtered[selected])) + '  ]' 
  }
  
  
  line = line->substr(from:1, to:line->length-1);
  line = line->substr(from:0, to:line->length-2);
  
  return line;
}


return ::(*args) {
  when (args.onGetTabNames    == empty) error(detail:"onGetTabNames is empty for tabbed choices! This is used to determine the order of the tabs. It can be a superset of the available tabs");
  when (args.onGetChoiceTable == empty) error(detail:"onGetChoiceTable is required for tabbed choices! This should ");
  when (args.onChoice         == empty) error(detail:"onChoice is required from tabbed choices!");
  when (args.horizontalFlow   != empty) error(detail:"horizontalFlow is not supported for tabbedchoices!");
  when (args.prompt != empty || args.onGetPrompt != empty)
    error(detail:"Prompt is overridden by tabbed choices!");

  @:columns = args.columns;
  @widget = if (args.columns)
    import(:'base/widgets/choicescolumns.mt')
  else 
    windowEvent.queueChoices

  @inputNext = windowEvent.CURSOR_ACTIONS.RIGHT;
  @inputPrev = windowEvent.CURSOR_ACTIONS.LEFT;
  @lastInput = inputNext;


  @:nextTab::(offset) { 
    when(tabNames->size == 1) empty;
    
    if (offset == empty) offset = 1
    
    // the inverse of onGetChoices' use of nextTab forward.
    // should combine at one point. Also hi, i havent been commenting much lately, 
    // so im gonna try now!! yay!
    if (offset < 0) {
      @:origIndex = tabNamesIndex;
      ::? {
        forever ::{
          tabNamesIndex-=1;
          if (tabNamesIndex < 0) tabNamesIndex += tabNames->size;
          @out = tabs[tabNames[tabNamesIndex]];
          when (out != empty && (if (columns) out[0]->size > 0 else out->size > 0)) send();
          // bug of some kind if it happens
          when(tabNamesIndex == origIndex) send();
        }
      }
    } else {
      tabNamesIndex = (tabNamesIndex + offset) % tabNames->size
    }
    if (args.onChangeTabs)
      args.onChangeTabs(:tabNamesIndex);
  }

  @:onInput::(input) {
    when(input != inputNext &&
         input != inputPrev) empty;
  
    lastInput = input;

    @offset = if (input == inputNext) 1 else -1;
    nextTab(offset);
  }
  


  @tabs;
  @tabNames;
  @tabNamesIndex = 0;
  if (args.onChangeTabs)
    args.onChangeTabs(:tabNamesIndex);
  args.choices = empty;

  @:realOnGetChoices = args.onGetChoiceTable;

  args.onGetChoices = :: {
    tabs = realOnGetChoices();
    @out;
    @:origTab = tabNamesIndex;
    tabNames = args.onGetTabNames();
    ::? {
      forever ::{
        out = tabs[tabNames[tabNamesIndex]];
        when (out != empty && (if (columns) out[0]->size > 0 else out->size > 0)) send();
        nextTab();
        when(origTab == tabNamesIndex) send();
      }
    }
    return out;
  }

  @:realOnChoice = args.onChoice;
  args.onChoice = ::(choice) {
    realOnChoice(choice, tab:tabNames[tabNamesIndex]);
  }

  if (args.onHover) ::<= {
    @:realOnHover = args.onHover;
    args.onHover = ::(choice) {
      realOnHover(choice, tab:tabNames[tabNamesIndex]);
    }
  }


  /*
  if (args.onGetMinWidth == empty)
    args.onGetMinWidth = ::() {
      @min = 0;
      foreach(tabs) ::(k, v) {
        @:all = if (columns) v[0] else v;
        foreach(all) ::(k, name) {
          if (min < name->length)
            min = name->length
        } 
      }
      return min
    }
*/
  if (args.onGetMinHeight == empty)
    args.onGetMinHeight = ::() {
      @min = 999
      foreach(tabs) ::(k, v) {
        @:all = if (columns) v[0] else v;
        if (all->size < min)
            min = all->size
        
      }
      return min;
    }
  args.onGetPrompt = ::<-
    renderPrompt(tabs, selected:tabNamesIndex, tabNames, columns);
  
  args.onInput = onInput;

  widget(
    *args    
  );
}
