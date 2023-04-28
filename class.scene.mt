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
@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'class.database.mt');
@:StatSet = import(module:'class.statset.mt');
@:dialogue = import(module:'singleton.dialogue.mt');
@:Damage = import(module:'class.damage.mt');
@:Item = import(module:'class.item.mt');
@:Scene = class(
    name : 'Wyvern.Scene',
    statics : {
        database : empty
    },
    define:::(this) {
        Database.setup(
            item: this,
            attributes : {
                name : String,
                script : Object
            }
        );
        
        this.interface = {
        
            act::(onDone => Function, location, landmark) {
                @:left = [...this.script];
                
                @:doNext ::{
                    when(left->keycount == 0) onDone();
                    @:action = left[0];
                    left->remove(key:0);
                    breakpoint();
                    match(action->type) {
                      (Function):
                        action(location, landmark, doNext),
                      
                      (Object): 
                        dialogue.message(speaker: action[0], text: action[1], onNext:doNext),
                        
                      default:
                        error(detail:'Scene scripts only accept arrays or functions')
                    };
                };
                
                doNext();
            }
        };
    }
);

Scene.database = Database.new(
    items : [
        Scene.new(
            data : {
                name : 'scene_intro',
                script: [
                    ['', '...Hey...you up?'],
                    ['', 'Guess we slept longer than we were hoping...'],
                    ['', 'Its morning now though, so we should get going and find that grotto.'],
                    ['', 'They say it\'s the only place to get Gate Keys.'],
                ]
            }
        ),     
 
        
        
    ]
);

return Scene;
