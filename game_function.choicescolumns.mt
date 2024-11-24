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

return ::(*args) {
  @headerCompiled;
  @headerSrc = args.header;
  @leftJustified = args.leftJustified => Object;
  @separator = ' ' + (if (args.separator == empty) '|' else args.separator) + ' ';
  @:convertToChoices::(columns => Object, header) {

  
    @padBlock = [];
    @:padColumnRow::(text, size, leftJustified) {
      padBlock->setSize(size:0);
      if (leftJustified)
        padBlock->push(value:text);
      for(text->length, size) ::(i) {
        padBlock->push(value:' ');
      }
      if (!leftJustified)
        padBlock->push(value:text);

      return String.combine(strings:padBlock);
    }
    
    
    // first get how much padding each column should get
    @columnSizes = [];
    foreach(columns) ::(i, column) {
      @max = 0;
      foreach(column) ::(n, next) {
        if (next->length > max)
          max = next->length;
      }
      
      if (header != empty)
        if (header[i]->length > max)
          max = header[i]->length;
        
      columnSizes[i] = max;
    }
    

    @:choices = [];  
    @:combine = [];
    for(0, columns[0]->size) ::(row) {
      combine->setSize(size:0);
      foreach(columns) ::(i, column) {
        
        combine->push(value:
          padColumnRow(
            text:column[row], 
            size:columnSizes[i],
            leftJustified:leftJustified[i]
          )
        );
        
        // padding between columns
        if (i != columns->size-1 && columnSizes[i+1] > 0)
          combine->push(value: separator);
      }



      
      choices->push(value:String.combine(strings:combine));
      if (header != empty) ::<= {
        combine->setSize(size:0);
        foreach(header) ::(i, text) {
          
          combine->push(value:
            padColumnRow(
              text:header[i], 
              size:columnSizes[i],
              leftJustified:true
            )
          );
          
          // padding between columns
          if (i != header->size-1)
            combine->push(value: '   ');
        }

        headerCompiled = String.combine(strings:combine);      
      }
    }
    return choices;
  }
  @:originalGetChoices = args.onGetChoices;
  if (args.onGetChoices == empty) ::<= {
    args.choices = convertToChoices(columns:args.columns, header:headerSrc);
  } else ::<= {
    args.onGetChoices = ::{
      return convertToChoices(columns:originalGetChoices(), header:headerSrc);
    }
  }
  
  if (args.header != empty) ::<= {
    args.header = empty;
    args.onGetHeader = ::{
      // the ONLY time this should happen is if we have a delayed get.
      convertToChoices(columns:originalGetChoices(), header:headerSrc);
      return headerCompiled;
    }
  }
    
  windowEvent.queueChoices(*args);
}
