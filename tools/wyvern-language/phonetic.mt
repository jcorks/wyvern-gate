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


@:getChunk ::(chunk) {
  
  @:ch0 = if (chunk->length < 1) empty else chunk->charAt(:0);
  @:ch1 = if (chunk->length < 2) empty else chunk->charAt(:1);
  @:chunkE = if (chunk->length < 2) empty else ch0+ch1;
  
  
  
  return {
    c0: ch0,
    c1: ch1,
    c01 : chunkE
  }
}


@:convert::(str) {
  @:syllables = [];

  @:biteSyllable ::(chunk) {
    @chunkCharCount = 0;
    
    @c = getChunk(:chunk);
    
    // first try the double chars 
    @:consIndex = consonant_double_char->findIndex(:c.c01)
    @:cons0Index = consonant_single_char->findIndex(:c.c0);
    
    @consOffset;
    if (consIndex != -1) ::<= {
      consOffset = dragonish_consonant->findIndex(:c.c01);
      chunkCharCount = 2;
    } else if (cons0Index != -1) ::<= {
      consOffset = dragonish_consonant->findIndex(:c.c0);    
      chunkCharCount = 1;
    } else ::<= {
    }
    
    
    
    // okay! Next, get the vowel
    breakpoint();
    chunk = chunk->substr(from:chunkCharCount, to:chunk->length-1);
    @c = getChunk(:chunk);

    @:vowIndex = vowel_double_char->findIndex(:c.c01)
    @:vow0Index = vowel_single_char->findIndex(:c.c);

    @vowOffset;
    if (vowIndex != -1) ::<= {
      vowOffset = dragonish_vowel->findIndex(:c.c01);
      chunkCharCount += 2;
    } else if (vow0Index != -1) ::<= {
      vowOffset = dragonish_vowel->findIndex(:c.c0);    
      chunkCharCount += 1;
    } else ::<= {
      // no vowel
      vowOffset = dragonish_vowel->findIndex(:'');
    }
    
    
    breakpoint();
    syllables->push(:'[' + dragonish_consonant[consOffset] + '-' + dragonish_vowel[vowOffset] + ']');
    return chunk->substr(from:chunkCharCount, to:chunk->length-1);
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




convert(:'aenjaal');



















