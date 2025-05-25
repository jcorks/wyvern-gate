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

@:windowEvent = import(:"game_singleton.windowevent.mt");

@:renderPrompt::(tabs, selected, lastTabState) {
  @line = '';
  @found = false;
  @:hasItems = ::(v) <- lastTabState[v] != empty && lastTabState[v]->size > 0

  foreach(tabs) ::(k, v) {
    when(hasItems(v) == false) empty;

    when(found == true) 
      line = line + '[>]';

    if (k == selected) ::<= {
      line = line + '[  ' + (tabs[selected]) + '  ]' 
      found = true;
    }
    else
      line = line + '[<]';
  }
  
  
  line = line->substr(from:1, to:line->length-1);
  line = line->substr(from:0, to:line->length-2);
  
  return line;
}


return ::(*args) {
  when (args.onGetTabs      == empty) error(detail:"onGetTabs is empty for tabbed choices!");
  when (args.onGetChoices   == empty) error(detail:"onGetChoices is required for tabbed choices!");
  when (args.onChoice       == empty) error(detail:"onChoice is required from tabbed choices!");
  when (args.horizontalFlow != empty) error(detail:"horizontalFlow is not supported for tabbedchoices!");
  when (args.prompt != empty || args.onGetPrompt != empty)
    error(detail:"Prompt is overridden by tabbed choices!");

  @widget = if (args.columns)
    import(:'game_function.choicescolumns.mt')
  else 
    windowEvent.queueChoices

  @inputNext = windowEvent.CURSOR_ACTIONS.RIGHT;
  @inputPrev = windowEvent.CURSOR_ACTIONS.LEFT;
  @lastInput = inputNext;


  @:onInput::(input) {
    when(input != inputNext &&
         input != inputPrev) empty;
  
    lastInput = input;

    @offset = if (input == inputNext) 1 else -1;

    if (tabIndex + offset < 0)
      tabIndex += tabs->size
    tabIndex = (tabIndex + offset) % tabs->size
    if (args.onChangeTabs)
      args.onChangeTabs(:tabIndex);
  }
  


  @tabs = args.onGetTabs();
  @:lastTabState = {};
  @tabIndex = 0;
  if (args.onChangeTabs)
    args.onChangeTabs(:tabIndex);
  args.choices = empty;

  @:realOnGetChoices = args.onGetChoices;

  args.onGetChoices = :: {
    foreach(tabs) ::(k, v) {
      @:all = realOnGetChoices(:k)
      lastTabState[v] = all;
    }

    @out;
    @:origTab = tabIndex;
    {:::} {
      forever ::{
          out = lastTabState[tabs[tabIndex]];
          realOnGetChoices(:tabIndex)
          when (out != empty) send();
          onInput(:lastInput);
          when(origTab == tabIndex) send();
      }
    }
    return out;
  }

  @:realOnChoice = args.onChoice;
  args.onChoice = ::(choice) {
    breakpoint();
    realOnChoice(choice, tab:tabIndex);
  }

  if (args.onHover) ::<= {
    @:realOnHover = args.onHover;
    args.onHover = ::(choice) {
      realOnHover(choice, tab:tabIndex);
    }
  }



  if (args.onGetMinWidth == empty)
    args.onGetMinWidth = ::() {
      @min = 0;
      foreach(tabs) ::(k, v) {
        @:all = lastTabState[v];
        foreach(all) ::(k, name) {
          if (min < name->length)
            min = name->length
        } 
      }
      return min
    }

  if (args.onGetMinHeight == empty)
    args.onGetMinHeight = ::() {
      @min = 0;
      foreach(tabs) ::(k, v) {
        @:all = lastTabState[v];
        if (min < all->size)
            min = all->size
        
      }
      return min;
    }

  args.onGetPrompt = ::<-
    renderPrompt(tabs, selected:tabIndex, lastTabState);
  
  args.onInput = onInput;

  widget(
    *args    
  );
}
