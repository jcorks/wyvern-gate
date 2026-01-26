@:dragonish_consonant = [
  'rr',
  'z',
  'j',
  'sh',
  'l',
  'n',

  'gg',
  'k',
  'dj',
  'ss',
  'tt'
]


@:consonant_single_char = [
  'j',
  'l',
  'n',
  'k'
]

@:consonant_double_char = [
  'rr',
  'sh',
  'gg',
  'dj',
  'ss',
  'tt'
]


@:dragonish_vowel = [
  'ae',
  'aa',
  'oh',
  'o',
  'uh',
  'ii',
  ''
];

@:vowel_single_char = [
  'o',
  ''
];

@:vowel_double_char = [
  'ae',
  'aa',
  'oh',
  'uh',
  'ii'
];



@:roots = {
  ('ae'): 0x6c,
  ('aa'): 0x61,
  ('oh'): 0xa1,
  ('o') : 0xac,
  ('uh'): 0xb7,
  ('ii'): 0xc2
}





@:convert::(str) {
  @:syllables = [];

  @:biteSyllable ::(chunk) {
    @chunkCharCount = 0;
    @:ch0 = chunk->charAt(:0);
    @:ch1 = chunk->charAt(:1);
    @:chunk = chunk->substr(from:0, to:1);
    
    // first try the double chars 
    @:consIndex = consonant_double_char->findIndex(:chunk)
    @:cons0Index = consonant_single_char->findIndex(:ch0);
    
    @:consOffset;
    if (consIndex != -1) ::<= {
      consOffset = dragonish_consonant->findIndex(:chunk);
      chunkCharCount = 2;
    } else if (cons0Index != -1) ::<= {
      consOffset = dragonish_consonant->findIndex(:ch0);    
      chunkCharCount = 1;
    } else ::<= {
      error(:'Unknown consonant : ' + chunk);
    }
    
    
    
    // okay! Next, get the vowel
    chunk = chunk->substr(from:chunkCharCount, to:chunk->length-1);
    @:ch0v = chunk->charAt(:0);
    @:ch1v = chunk->charAt(:1);
    @:chunkv = chunk->substr(from:0, to:1);

    @:vowIndex = vowel_double_char->findIndex(:chunkv)
    @:vow0Index = vowel_single_char->findIndex(:ch0v);

    @vowOffset;
    if (vowIndex != -1) ::<= {
      vowOffset = dragonish_vowel->findIndex(:chunk);
      chunkCharCount += 2;
    } else if (vow0Index != -1) ::<= {
      vowOffset = dragonish_vowel->findIndex(:ch0);    
      chunkCharCount += 1;
    } else ::<= {
      // no vowel
      vowOffset = dragonish_vowel->findIndex(:'');
    }
    
    
    syllables->push(:'[' + dragonish_consonant[consOffset] + '-' + dragonish_vowel[vowOffset] + ']');
    return chunk->substr(from:chunkCharCount, to:chunk->length);
  }
  
  
  ::? {
    forever ::{
      str = biteSyllable(:str);
      when(str->length == 0) send();
    }
  }
  
  foreach(syllables) ::(k, v) {
    print(:v);
  }
  
}
























