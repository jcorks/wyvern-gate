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
@:Entity = import(module:'class.entity.mt');
@:Random = import(module:'singleton.random.mt');

@:canvas = import(module:'singleton.canvas.mt');
@:instance = import(module:'singleton.instance.mt');



// Called when telling the external device that 
// a new frame will be prepared
// no args, no return
@:external_onStartCommit = getExternalFunction(name:'external_onStartCommit');

// Called when telling the external device that 
// a new frame data has been delivered.
// no args, no return
@:external_onEndCommit = getExternalFunction(name:'external_onEndCommit');


// Called when the next character to be displayed is known.
// The characters are given from left to right, top to bottom.
// The current size is standard VT 24 x 80
//
// arg: string holding one character.
// return: none
@:external_onCommitText  = getExternalFunction(name:'external_onCommitText');

// Called when saving the state.
// arg: slot (number, 0-2), data (string)
// return none
@:external_onSaveState   = getExternalFunction(name:'external_onSaveState');

// Called when loading the state.
// arg: slot (number, 0-2)
// return: state (string)
@:external_onLoadState     = getExternalFunction(name:'external_onLoadState');

// Called when getting input.
// Will hold thread until an input is ready from the device.
// 
// returns the appropriate cursor action number 
//
/*
    LEFT : 0,
    UP : 1,
    RIGHT : 2,
    DOWN : 3,
    CONFIRM : 4,
    CANCEL : 5,
*/
@:external_getInput      = getExternalFunction(name:'external_getInput');




instance.mainMenu(
    onCommit :::(lines) {
        external_onStartCommit();
        lines->foreach(do:::(index, line) {
            line->foreach(do:::(i, iter) {
                external_onCommitText(a:iter.text);
            });
        });    
        external_onEndCommit();
    },
    
    onSaveState :::(
        slot,
        data
    ) {
        external_onSaveState(a:slot, b:data);
    },

    onLoadState :::(
        slot
    ) {
        return [::] {
            return external_onLoadState(a:slot);
        } : {
            onError:::(detail) {
                return empty;
            }
        };
    },

    useCursor : true,
    
    onInputNumber :::() {
    },
    
    onInputCursor :::() {
        return external_getInput();
    }
);







/*

@:ppl = [
    Entity.new(),
    Entity.new(),
];





@:Battle = import(module:'class.battle.mt');



forever(do:::{
    when(ppl[0].isIncapacitated() &&
         ppl[1].isIncapacitated()) send(message:'Party was wiped.');

    @e1 = Entity.new();
    @e2 = Entity.new();
    e1.nickname = 'the ' + e1.species.name + ' ' + (if(e1.profession.base.name == 'None') 'person' else e1.profession.base.name);
    e2.nickname = 'the ' + e2.species.name + ' ' + (if(e2.profession.base.name == 'None') 'person' else e2.profession.base.name);
    
    Battle.new(
        allies: [
            ppl[0],
            ppl[1]
        ],
        
        enemies : [
            e1,
            e2
        ],
        

        
        landmark: {}
    );
});

*/



/*



dialogue.choiceColumns(
    itemsPerColumn: 2,
    choices: [
        'Ability',
        'Check',
        'Item',
        'Run',
    ]
);

dialogue.choices(
    choices: [
        'Apple',
        'Orange',
        'lemon',
        'pear',
        'strawberry',
        'pommegranate',
        'apple 2',
        'green appl',
        'wolf appl',
        'crab appl',
        'pear update',
        'adwa',
        'dw'
        
    ],
    canCancel : true,
    prompt: 'choose one?'
);  

dialogue.choices(
    choices: ['yes', 'no'],
    prompt: 'Are you sure?'
);

dialogue.message(
    speaker: 'Test',
    text: "
What is Lorem Ipsum?

Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
Why do we use it?

It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like).

Where does it come from?

Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum' (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet..', comes from a line in section 1.10.32.

The standard chunk of Lorem Ipsum used since the 1500s is reproduced below for those interested. Sections 1.10.32 and 1.10.33 from 'de Finibus Bonorum et Malorum' by Cicero are also reproduced in their exact original form, accompanied by English versions from the 1914 translation by H. Rackham.
Where can I get some?

There are many variations of passages of Lorem Ipsum available, but the majority have suffered alteration in some form, by injected humour, or randomised words which don't look even slightly believable. If you are going to use a passage of Lorem Ipsum, you need to be sure there isn't anything embarrassing hidden in the middle of text. All the Lorem Ipsum generators on the Internet tend to repeat predefined chunks as necessary, making this the first true generator on the Internet. It uses a dictionary of over 200 Latin words, combined with a handful of model sentence structures, to generate Lorem Ipsum which looks reasonable. The generated Lorem Ipsum is therefore always free from repetition, injected humour, or non-characteristic words etc.
    "
);

*/


/*
canvas.penX = 0;
canvas.penY = 0;

[0, 400]->for(do:::(i) {
    
    canvas.erase();
    
    if(canvas.penX >= canvas.width) ::<= {
        canvas.penY += 1;
        canvas.penX = 0;    
    } else ::<= {
        canvas.penX += 1;
    };
    canvas.drawChar(text:'@');

    canvas.commit();
});
*/



