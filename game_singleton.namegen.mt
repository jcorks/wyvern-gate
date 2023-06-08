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
@:Random = import(module:'game_singleton.random.mt');
@:class = import(module:'Matte.Core.Class');


@:hardConsonant = ::<= {
    @:list = [
        'k',
        'ph',
        'ch',
        'th',
        'ts',
        't'
    ];
    return :: {
        return Random.pickArrayItem(list);
    };
};


@:softConsonant = ::<= {
    @:list = [
        's',
        'sh',
        'l',
        'f',
        'r',
        'v',
        'z'
    ];
    return :: {
        return Random.pickArrayItem(list);
    };
};
@:vowel = ::<= {

    @:list = [
        'ah',
        'e',
        'ei',
        'i',
        'u',
        'a',
        'o'
    ];
    
    return ::{
        return Random.pickArrayItem(list);
    };
};


@:capitalize = ::<= {
    @:c = {
        'a' : 'A',
        'b' : 'B',
        'c' : 'C',
        'd' : 'D',
        'e' : 'E',
        'f' : 'F',
        'g' : 'G',
        'h' : 'H',
        'i' : 'I',
        'j' : 'J',
        'k' : 'K',
        'l' : 'L',
        'm' : 'M',
        'n' : 'N',
        'o' : 'O',
        'p' : 'P',
        'q' : 'Q',
        'r' : 'R',
        's' : 'S',
        't' : 'T',
        'u' : 'U',
        'v' : 'V',
        'w' : 'W',
        'x' : 'X',
        'y' : 'Y',
        'z' : 'Z'
    };  
    
    return ::(name) {
        return name->setCharAt(index:0, value:c[name->charAt(index:0)]);
    };
};





/*



*/

@:dragonish_hardConsonant = ::<= {
    @:list = [
        'k',
        'gg',
        'dj',
        'pp'
    ];
    return :: {
        return Random.pickArrayItem(list);
    };
};


@:dragonish_softConsonant = ::<= {
    @:list = [
        'rr',
        'z',
        'j',
        'l',
        'n',
        'x'
    ];
    return :: {
        return Random.pickArrayItem(list);
    };
};
@:dragonish_vowel = ::<= {

    @:list = [
        'ae',
        'aa',
        'oh',
        'o',
        'uh',
        'ii'
    ];
    
    return ::{
        return Random.pickArrayItem(list);
    };
};

@:creatureMod = [
    'Dire',
    'Giant',
    'Spotted',
    'Shrieking',
    'Skulking',
    'Menacing',
    'Grotesque'
];


@:creatureBaseNames = [
    'Frog',
    'Beaver',
    'Snake',
    'Spider',
    'Crab',
    'Ant',
    'Isopod',
    'Krill',
    'Shrimp',
    'Lizard',
    'Bird',
    'Raptor',
    'Aardwolf',
    'Wasp',
    'Chicken',
    'Manticore',
    'Chimera',
    'Squirrel',
    'Mustelid'
];

return class(
    name : 'Wyvern.NameGen',
    define:::(this) {
        this.interface = {
            person :: {
                @:val = Number.random();
                return capitalize(
                  name:
                    match(true) {
                      (val < 0.2): hardConsonant() + vowel(),
                      (val < 0.4): vowel() + softConsonant() + vowel() + '-' + hardConsonant() + vowel(),
                      (val < 0.6): softConsonant() + vowel() + hardConsonant() + vowel(),
                      (val < 0.8): vowel() + hardConsonant() + vowel(),
                      default:
                        hardConsonant() + vowel() + softConsonant() + vowel() + hardConsonant() + vowel()  
                    }
                );
            },
            
            island :: {
                @:features = [
                    'Plain',
                    'Quarry',
                    'Mountain',
                    'Plateau',
                    'Basin',
                    'Crater',
                    'Lake',
                    'Sea',
                    'Peaks',
                    'Mire',
                    'Sky'
                ];

                @:val = Number.random();
                return (match(true) {
                      (val < 0.2): this.person() + 'lor',
                      (val < 0.4): this.person() + 'shor',
                      (val < 0.6): this.person() + 'tir',
                      (val < 0.8): this.person() + 'shir',
                      default:
                        this.person() + 'mir'
                    })
                + (if(Number.random() > 0.8) '' else ' ' + Random.pickArrayItem(list:features));
            
            },
            
            place :: {
                @:val = Number.random();
                return match(true) {
                      (val < 0.2): this.person() + 'neim',
                      (val < 0.4): this.person() + 'mmin',
                      (val < 0.6): this.person() + 'grimm',
                      (val < 0.8): this.person() + 'nemm',
                      default:
                        this.person() + 'nim'
                    }
                ;
            
            },
            
            creature :: {
                @:mod = if (Number.random() > 0.8) Random.pickArrayItem(list:creatureMod)+' ' else '';
                @:first = Random.pickArrayItem(list:creatureBaseNames);
                @second = [::] { 
                    forever(do:::{
                        @sec = Random.pickArrayItem(list:creatureBaseNames);
                        when (sec != first) send(message:sec);
                    });
                };
                return mod + first + '-' + second;
            }
        };
    }
).new();
