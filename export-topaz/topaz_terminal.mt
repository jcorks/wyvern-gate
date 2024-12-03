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
@:Settings = import(:'topaz_settings.mt');
@:display = Topaz.ViewManager.getDefault();


display.setParameter(
    param:Topaz.Display.Parameter.ViewPolicy,
    value:Topaz.Display.ViewPolicy.None
);


// create font asset
@:font = Topaz.Resources.createDataAssetFromPath(
    path:'topaz_font.ttf',
    name:'Monospace'
);
Topaz.FontManager.registerFont(asset:font);



if (Settings.getObject().disableShaders != true) ::<= {
    @:shader = Topaz.Resources.createDataAssetFromPath(
        path:'topaz_crt.glsl',
        name:'topaz_crt.glsl'
    );

    @:ret = display.setPostProcessShader(
        vertexShader   : shader.getAsString(),
        fragmentShader : shader.getAsString()
    );

    if (ret != empty) ::<= {
        error(detail:ret);
    }
}






@:RENDERER_WIDTH = 80;
@:RENDERER_HEIGHT = 24;
@:LINE_SPACING = 15;
@:FONT_SIZE = 15;

@TERM_WIDTH = RENDERER_WIDTH * FONT_SIZE * (0.54);
@TERM_HEIGHT = RENDERER_HEIGHT * LINE_SPACING;



@:Terminal = {
    new :: {
        @:this = Topaz.Entity.create();
    
        @cursor = 0;
        // renders a single line.
        // It makes no restrictions on size and assumes that the setter 
        // maintains a proper width
        @:createTextLine = ::{
            @:this = Topaz.Entity.create();
            @:textRenderer = Topaz.Text2D.create();
            textRenderer.setFont(font, pixelSize:FONT_SIZE);

            this.addComponent(component:textRenderer);

            this.line = {
                set ::(value) {
                    textRenderer.setText(text:value);
                },
                get ::<- textRenderer.getText()
            }
            
            this->setIsInterface(enabled:true);
            return this;
        };


        
        @:bg = Topaz.Shape2D.create();
        @requestStringMappings = false;
        @:lines = [];


        

        bg.formRectangle(width:TERM_WIDTH, height:TERM_HEIGHT);
        bg.setColor(color:Topaz.Color.fromString(str:'#242424'));
        this.addComponent(component:bg);
        bg.setPosition(value:{x:0, y:-TERM_HEIGHT});
        for(0, RENDERER_HEIGHT)::(i) {
            lines[i] = createTextLine();
            lines[i].setPosition(value:{x:0, y:-LINE_SPACING*i - LINE_SPACING*2});
            this.attach(child:lines[i]);
        }
        

        this. = {
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
            
            widthPixels : {
                get ::<- TERM_WIDTH
            },
            
            heightPixels : {
                get ::<- TERM_HEIGHT
            },
            
            requestStringMappings : {
                get ::<- requestStringMappings,
                set ::(value) <- requestStringMappings = value
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
        this->setIsInterface(enabled:true);
        return this;
    }
};





return Terminal;
