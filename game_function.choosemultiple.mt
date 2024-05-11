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


// Function to pick multiple things from a list.

@:valueToName ::(value => Number) {
    when (value % 10 == 1) ''+value + 'st';
    when (value % 10 == 2) ''+value + 'nd';
    when (value % 10 == 3) ''+value + 'rd';
    return value + 'th';
}

return ::(
    choiceNames => Object,
    choiceItems => Object,
    leftWeight,
    topWeight,
    prompt,
    canCancel,
    renderable,
    count,
    onChoice,
    onHover,
    onCancel
) {

    @:oldIndices = [];
    @:output = [];
    @:outputNames = [];

    choiceNames = [...choiceNames];
    choiceItems = [...choiceItems];
    @:nextChoice ::{
        when(output->size == count)
            onChoice(:output);
    
    
        windowEvent.queueChoices(
            onGetChoices ::{
                return choiceNames
            },
            leftWeight,
            jumpTag: 'CHOOSEMULTIPLE',
            topWeight,
            prompt: prompt + ': ' + (valueToName(:output->size+1)),
            renderable,
            keep: true,
            onHover ::(choice) {
                if (onHover)
                    onHover(:choiceItems[choice-1]);
            },
            canCancel: if (output->size == 0) canCancel else true,
            onCancel ::{
                when(output->size == 0)
                    if (onCancel) onCancel();
                @:prev = oldIndices->pop;
                
                choiceNames->insert(at:prev, value:outputNames->pop);
                choiceItems->insert(at:prev, value:output->pop);
                
                nextChoice();
            },
            onChoice::(choice) {
                @index = choice-1;
                
                windowEvent.queueAskBoolean(
                    prompt: 'Pick ' + choiceNames[index] + '?',
                    onChoice::(which) {
                        when(which == false) false;
        
                        oldIndices->push(:index);
                        outputNames->push(:choiceNames[index]);
                        output->push(:choiceItems[index]); 
                        
                        choiceNames->remove(:index);
                        choiceItems->remove(:index);
                        
                        windowEvent.jumpToTag(goBeforeTag:true, name:'CHOOSEMULTIPLE');
                        
                        nextChoice();                    
                    }
                );

            }
        );
    }
    nextChoice();
}
