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


// create font asset
@:font = Topaz.Resources.createAsset(
    path:'monof55.ttf',
    name:'Monospace'
);
Topaz.FontManager.registerFont(asset:font);


@:RENDERER_WIDTH = 80;
@:RENDERER_HEIGHT = 25;
@:LINE_SPACING = 15;
@:FONT_SIZE = 15;

@:TextCanvas = class(
    inherits: [Topaz.Entity],
    define:::(this) {

        // renders a single line.
        // It makes no restrictions on size and assumes that the setter 
        // maintains a proper width
        @:TextLine = class(
            inherits:[Topaz.Entity],
            define:::(this) {
                @:textRenderer = Topaz.Text2D.new();
                textRenderer.font = font;
                textRenderer.size = FONT_SIZE; 
                //textRenderer.color = Topaz.Color.parse(string:'white');

                this.components = [textRenderer];
                this.interface = {
                    // the displayed line
                    line : {
                        set ::(value) {
                            textRenderer.text = value;
                        } 
                    }
                };
            }
        );

        @:lines = [];
        [0, RENDERER_HEIGHT]->for(do:::(i) {
            lines[i] = TextLine.new();
            lines[i].position = {x:0, y:-LINE_SPACING*i};
            this.attach(entity:lines[i]);
        });
        

        this.interface = {
            updateLine::(index => Number, text => String) {
                lines[index].line = text;
            },
            LINE_SPACING : {
                get ::<- LINE_SPACING
            }
        };

    }
);



return TextCanvas;