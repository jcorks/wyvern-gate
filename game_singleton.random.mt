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


return class(
    name : 'Wyvern.random',
    
    define:::(this) {
        // This example implements a version of the TT800 Random Number Generator 
        // published by Makoto Matsumoto in 1996.
        @:tt800 = ::<= {
            @:SEED_COUNT = 25;
            @:END = 7;
            
            
            @state = [];
            @index = 0;
            @a = [0x0, 0x8ebfd028];
            
            @:interface = {
                // initializes the state of the RNG with 
                // default a seed state as recommended by 
                // the original publication.
                init ::{
                    state = [
                        0x30b72d97,
                        0x2027d4ad,
                        0x3631a263,
                        0xf8a3dcaa,
                        0x402417b9,

                        0xd437b359,
                        0x0b33c134,
                        0xdd185f38,
                        0x0c991509,
                        0x00a04c8d,

                        0x773ff5fb,
                        0xba19cf6b,
                        0x1f17cc9e,
                        0xebaddf26,
                        0xe69ecd9a,

                        0x92c4a6dc,
                        0xb8150e72,
                        0xf0e1e969,
                        0x9dfc6d1e,
                        0xbce24d44,

                        0x233375ae,
                        0xdc159ae4,
                        0x9757ea4c,
                        0xe2282e2b,
                        0xe9585859          
                    ];
                },
                
                // Returns the next rng number 0 through 1
                next::{
                    if (index == SEED_COUNT) ::<= {
                        interface.twist();
                    }
                    @i = index;
                    index += 1;
                    
                    @out = state[i];
                    out ^= (out << 7)  & 0x2b5b2500;
                    out ^= (out << 15) & 0xdb8b0000;
                    out ^= (out >> 16);
                    
                    // binary ops work with two-s complement 32-bit integers
                    // So out at this point is from -0xffffffff to 0xffffffff; 
                    return out->abs / (0xffffffff/2 + 1);
                },
                
                // reorients the RNG
                twist ::{
                    for(0, (SEED_COUNT - END))::(i) {
                        state[i] = (state[i+END]) ^
                                   (state[i] >> 1) ^
                                   (a[state[i]->abs%2]);
                    }
                    
                    for(SEED_COUNT - END, SEED_COUNT)::(i) {
                        state[i] = (state[i + (END - SEED_COUNT)]) ^
                                   (state[i] >> 1) ^
                                   (a[state[i]->abs%2]);
                    }
                    
                    index = 0;
                },
                // seeds the RNG with a string.
                seed::(string) {
                    interface.init();
                    @offset = 0;
                    for(0, string->length)::(i) {
                        offset = (offset + (string->charCodeAt(index:i) << (2*(i%8)))) % 0xffffffff;       
                    }
                    
                    
                    for(0, state->keycount)::(ind) {            
                        state[ind] += offset;
                    }
                    
                    interface.twist();
                }
            }
            
            return interface;
        }
        
        // use normal rng to seed the regular rng
        tt800.init();
        tt800.seed(string:'' + Number.random() + '' + Number.random() + '' + Number.random());


    
        this.interface = {
            integer::(from, to) {
                return from + (tt800.next() * ((to+1)-from))->floor;
            },
            
            float:: {
                return tt800.next();
            },
            
            range::(from, to) {
                return from + (tt800.next() * ((to+1)-from));
            },
        
            pickArrayItem::(list) {
                return list[this.instance.integer(from:0, to:list->keycount-1)];
            },

            pickTableItem::(table) {
                return table[this.instance.pickArrayItem(list:table->keys)];
            },
            
            flipCoin:: <- tt800.next() < 0.5,
            
            try::(percentSuccess) <- tt800.next() < percentSuccess / 100,
            
            pickArrayItemWeighted::(list) {
                @:weightTable = [];
                @totalWeight = 0;
                foreach(list)::(index, item) {
                    weightTable[index] = totalWeight;
                    totalWeight += 1 / item.rarity;
                }
                weightTable[list->keycount] = totalWeight;
                
                @:which = tt800.next()*totalWeight;

                return list[ 
                    {:::}{
                        for(0, weightTable->keycount-1)::(index) {
                            when(which > weightTable[index] &&
                                 which < weightTable[index+1])
                                send(message:index);
                            
                        }
                        return list->keycount-1;
                    } 
                ];
            }
            

        }
    }
).new();
