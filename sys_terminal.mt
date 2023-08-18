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
//@:Entity = import(module:'class.entity.mt');
//@:Random = import(module:'singleton.random.mt');
@:Topaz   = import(module:'Topaz');
@:class   = import(module:'Matte.Core.Class');

Topaz.defaultDisplay.setParameter(
    parameter:Topaz.Display.PARAMETER.VIEW_POLICY,
    value:Topaz.Display.VIEW_POLICY.NONE
);

// create font asset
@:font = Topaz.Resources.createAsset(
    path:'sys_FSEX300.ttf',
    name:'Monospace'
);
Topaz.FontManager.registerFont(asset:font);


@:shader = Topaz.Resources.createAsset(
    path:'sys_crt.glsl',
    name:'sys_crt.glsl'
);

@:ret = Topaz.defaultDisplay.setPostProcessShader(
    vertexShader   : shader.string,
    fragmentShader : shader.string
);

if (ret != empty) ::<= {
    error(detail:ret);
}







@:RENDERER_WIDTH = 80;
@:RENDERER_HEIGHT = 32;
@:LINE_SPACING = 15;
@:FONT_SIZE = 15;

@:Terminal = class(
    inherits: [Topaz.Entity],
    define:::(this) {
        @cursor = 0;
        // renders a single line.
        // It makes no restrictions on size and assumes that the setter 
        // maintains a proper width
        @:TextLine = class(
            inherits:[Topaz.Entity],
            define:::(this) {
                @:textRenderer = Topaz.Text2D.new();
                textRenderer.font = font;
                textRenderer.size = FONT_SIZE; 

                this.constructor = ::{
                    this.components = [textRenderer];
                }

                this.interface = {
                    // the displayed line
                    line : {
                        set ::(value) {
                            textRenderer.text = value;
                        },
                        get ::<- textRenderer.text
                    }
                }
            }
        );


        
        @:bg = Topaz.Shape2D.new();

        @:lines = [];


        
        this.constructor = ::{

            bg.formRectangle(width:640, height:480);
            bg.color = '#242424';
            this.components = [bg];
            bg.position = {x:0, y:-480 + LINE_SPACING*2}
            for(0, RENDERER_HEIGHT)::(i) {
                lines[i] = TextLine.new();
                lines[i].position = {x:0, y:-LINE_SPACING*i}
                this.attach(entity:lines[i]);
            }


            return this;
        }
        

        this.interface = {
            updateLine::(index => Number, text => String) {
                lines[index].line = text;
                cursor = index;
            },
            LINE_SPACING : {
                get ::<- LINE_SPACING
            },

            clear ::{
                cursor = 0;
                for(0, RENDERER_HEIGHT)::(i) {
                    lines[i].line = '';
                }
            },

            printch::(value => String) {
                if (cursor == RENDERER_HEIGHT) cursor -=1;
                lines[cursor].line = lines[cursor].line + value;
            },

            backspace::{
                if (cursor == RENDERER_HEIGHT) cursor -=1;
                when (lines[cursor].line == '') empty;
                when (lines[cursor].line->length == 1) lines[cursor].line = '';
                lines[cursor].line = lines[cursor].line->substr(from:0, to:lines[cursor].line->length-2);
            },

            backline ::{
                cursor -=1;
                if (cursor < 0) cursor = 0;
                lines[cursor].line = '';
            },

            reprint ::(line) {
                if (cursor == RENDERER_HEIGHT) cursor -=1;
                lines[cursor].line = line;
            },

            nextLine :: {
                // delete last line in queue.
                if (cursor >= RENDERER_HEIGHT-1) ::<= {
                    for(1, RENDERER_HEIGHT)::(i) {
                        lines[i-1].line = lines[i].line;
                    }
                    cursor = RENDERER_HEIGHT-1;
                }
                cursor+=1;            
            },

            HEIGHT : {
                get ::<- RENDERER_HEIGHT
            },

            WIDTH : {
                get ::<- RENDERER_WIDTH
            },

            'print'::(line => String) {
                // delete last line in queue.
                if (cursor >= RENDERER_HEIGHT-1) ::<= {
                    for(1, RENDERER_HEIGHT)::(i) {
                        lines[i-1].line = lines[i].line;
                    }
                    cursor = RENDERER_HEIGHT-1;
                }
                lines[cursor].line = line;
                cursor+=1;
            }
        }

    }
);





return Terminal;
