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
    }
}


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
    }
}
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
    }
}


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
    }  
    
    return ::(name) {
        return name->setCharAt(index:0, value:c[name->charAt(index:0)]);
    }
}





/*
    Wyvern's language.
    Some notes on the language
    
    - Adjectives / modifiers are always after the noun they modify. Series of adjectives / modifiers can be strung to further describe the noun
    - Verbs come before the subject and object. Subject comes before the object. (VSO)
    - Endings of words act as explicit particles for types and functions of words
    - adverbs always come after verbs and are dashed. they follow the conjugation suffix
    
    
    Current word list:
        // pronouns. Always end in n
        jiin            me / I
        kaajiin         you
        naan            one / someone
        laen            they / he / she 
        
        // prepositions. always end in aa
        // propositions link with dashes their subject and object
        // prepositions come after the subject and behave as adjectives in placement
        // Example: "warrior" -> (one of war) -> naan-shaa-zohkiizaal
        shaa            of / from

        // nouns end in l. end in ii for multiple
        zaashael        world / earth (assumed if contextless) / planet
        rrohziil        friend
        zohkaal         enemy
        zohkiizaal      war
        kael            wing
        djaal           fire / flame
        luhl            reality
        kaarrjuhzaal    groveler
        ziikkael        fang
        ttaal           ice / cold / snow
        kaal            thunder / lighting
        juhriil         claw / talon
        rraeziil        horn
        shaal           light        
        shiikohl        power / influence / strength
        
        
        
        // verbs. infinitive always ends in uh 
        // prefix with kaa- to negate a verb
        zohppuh         to travel
        juhrruh         to come 
        ppuh            to be
        kaaluh          to wish
        zaaluh          to choose
        zohkuh          to fight
        djiirohshuh     to apologize
        kkiikkohluh     to curse
        
        // adjectives / adverbs, always end in rr
        shiirr          swift
        kohggaelaarr    prosperous
        djaashaarr      new
        rrohsharr       again / repeatedly
        
        
        // conjunctions always end in z
        jaan            but



    Conjugation. separated by a dash
    Add an l to make it a noun
        -lo             present tense
        -sho            past tense 
        -zo             affirmative / command


    grammatical caveats
        - the verb "to be" is special in that it can form modifiers to nouns by linking with other words. Those 
          attached to "to be" are also dashed together.
          For example, the word "Chosen" / "Chosen one" (as in somebody who is chosen) is literally the verb 'to be' conjugated in the past tense linked with the infinitive of "to choose" with the subject "one"
          in other words: ppuh-sho-zaaluh naan
          which is distinctly different from "zaaluh-zol" which is the word for "choice" 
          (it is more common to just informally say "zaaluh-shol" (chosen (noun form))
    

        
    Cultural bits 
        - The World (zaashael) is a way to refer to the world but also the creator of things. Not in an explicit sense 
          but a incorporeal spiritual sense, whatever that may be to the individual.
          A common way to do well wishings upon another is to tell them "The world wishes xxx", i.e. "the world wishes you swift and prosperous travels" is a common phrase to wish one on a journey
            . Related: a common swear to someone is "Kkiikkohluh zaashael kaajiin" ("earth curse you")
*/

@:dragonish_hardConsonant = ::<= {
    @:list = [
        'k',
        'gg',
        'dj',
        'pp',
        'tt',
    ];
    return :: {
        return Random.pickArrayItem(list);
    }
}


@:dragonish_softConsonant = ::<= {
    @:list = [
        'rr',
        'z',
        'j',
        'l',
        'n',
        'sh'
    ];
    return :: {
        return Random.pickArrayItem(list);
    }
}
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
    }
}

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
                @second = {:::} { 
                    forever ::{
                        @sec = Random.pickArrayItem(list:creatureBaseNames);
                        when (sec != first) send(message:sec);
                    }
                }
                return mod + first + '-' + second;
            }
        }
    }
).new();
