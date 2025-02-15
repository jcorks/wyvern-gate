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

@:renderPrompt::(tabs, selected) {
  @line = '';
  @found = false;
  foreach(tabs) ::(k, v) {

    when(found == true) 
      line = line + (if (k==(tabs->size-1))'[>' else '[>]');

    if (k == selected) ::<= {
      if (k != 0)
        line = line + '['
      line = line + (tabs[selected])
      if (k != tabs->size-1)
        line = line + ']'
      found = true;
    }
    else
      line = line + (if (k==0)'<]' else '[<]');
  }
  return line;
}


return ::(*args) {
  when (args.onGetTabs      == empty) error(detail:"onGetTabs is empty for tabbed choices!");
  when (args.onGetChoices   == empty) error(detail:"onGetChoices is required for tabbed choices!");
  when (args.onChoice       == empty) error(detail:"onChoice is required from tabbed choices!");
  when (args.horizontalFlow != empty) error(detail:"horizontalFlow is not supported for tabbedchoices!");
  when (args.prompt != empty || args.onGetPrompt != empty)
    error(detail:"Prompt is overridden by tabbed choices!");


  @inputNext = windowEvent.CURSOR_ACTIONS.RIGHT;
  @inputPrev = windowEvent.CURSOR_ACTIONS.LEFT;



  @:onInput::(input) {
    when(input != inputNext &&
         input != inputPrev) empty;

    @offset = if (input == inputNext) 1 else -1;

    if (tabIndex + offset < 0)
      tabIndex += tabs->size
    tabIndex = (tabIndex + offset) % tabs->size
    if (args.onChangeTabs)
      args.onChangeTabs(:tabIndex);
  }
  


  @tabs = args.onGetTabs();
  @tabIndex = 0;
  if (args.onChangeTabs)
    args.onChangeTabs(:tabIndex);
  args.choices = empty;

  @:realOnGetChoices = args.onGetChoices;

  args.onGetChoices = ::<-
    realOnGetChoices(
    )[tabIndex]

  @:realOnChoice = args.onChoice;
  args.onChoice = ::(choice) {
    realOnChoice(choice, tab:tabIndex);
  }

  args.onGetMinWidth = ::() {
    @:all = realOnGetChoices()
    @min = 0;
    foreach(all) ::(k, cat) {
      foreach(cat) ::(k, name) {
        if (min < name->length)
          min = name->length
      }
    }
    return min
  }

  args.onGetMinHeight = ::() {
    @:all = realOnGetChoices()
    @min = 0;
    foreach(all) ::(k, cat) {
      if (min < cat->size)
        min = cat->size
    }
    return min;
  }

  args.onGetPrompt = ::<-
    renderPrompt(tabs, selected:tabIndex);
  
  args.onInput = onInput;

  windowEvent.queueChoices(
    *args    
  );
}
