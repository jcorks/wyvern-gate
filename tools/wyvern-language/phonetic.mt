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
  'tt',
  '',
]


@:consonant_single_char = [
  'z',
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
  '',
  'ae',
  'aa',
  'oh',
  'o',
  'uh',
  'ii'
];

@:vowel_single_char = [
  'o'
];

@:vowel_double_char = [
  'ae',
  'aa',
  'oh',
  'uh',
  'ii'
];



@:roots = {
  (''):   0xa0,
  ('ae'): 0xac,
  ('aa'): 0xb8,
  ('oh'): 0xc4,
  ('o') : 0xd0,
  ('uh'): 0xdc,
  ('ii'): 0xe8
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
  @codepoints = '';

  @:addCodepoint::(cons, vowel) {
    codepoints = codepoints + ' '->setCharCodeAt(index:0, value:roots[dragonish_vowel[vowel]] + cons);
  }

  @:biteSyllable ::(chunk) {
    when(chunk->charAt(index:0) == ' ') ::<= {
      syllables->push(:' ');
      codepoints = codepoints + ' ';
      return chunk->substr(from:1, to:chunk->length-1);
    }
  
    @chunkCharCount = 0;
    @:origChunk = chunk;
    
    @c = getChunk(:chunk);
    @cCons = c;
    @hasChars = false;
    // first try the double chars 
    @:consIndex = consonant_double_char->findIndex(:c.c01)
    @:cons0Index = consonant_single_char->findIndex(:c.c0);
    
    @consOffset;
    if (consIndex != -1) ::<= {
      consOffset = dragonish_consonant->findIndex(:c.c01);
      chunkCharCount = 2;
      hasChars = true;
    } else if (cons0Index != -1) ::<= {
      consOffset = dragonish_consonant->findIndex(:c.c0);    
      chunkCharCount = 1;
      hasChars = true;
    } else ::<= {
      consOffset = dragonish_consonant->findIndex(:'');
    }
    
    
    
    // okay! Next, get the vowel
    chunk = chunk->substr(from:chunkCharCount, to:chunk->length-1);
    chunkCharCount = 0;
    @c = getChunk(:chunk);

    @:vowIndex = vowel_double_char->findIndex(:c.c01)
    @:vow0Index = vowel_single_char->findIndex(:c.c0);

    @vowOffset;
    if (vowIndex != -1) ::<= {
      vowOffset = dragonish_vowel->findIndex(:c.c01);
      chunkCharCount += 2;
      hasChars = true;
    } else if (vow0Index != -1) ::<= {
      vowOffset = dragonish_vowel->findIndex(:c.c0);    
      chunkCharCount += 1;
      hasChars = true;
    } else ::<= {
      // no vowel
      vowOffset = dragonish_vowel->findIndex(:'');
    }
    
    if (!hasChars)
      error(:'Unable to parse at >' + origChunk);

    syllables->push(:'[' + dragonish_consonant[consOffset] + '-' + dragonish_vowel[vowOffset] + ']');
    addCodepoint(cons:consOffset, vowel:vowOffset);
    return chunk->substr(from:chunkCharCount, to:chunk->length-1);
  }
  
  
  ::? {
    forever ::{
      str = biteSyllable(:str);
      when(str->length == 0) send();
    }
  }
  
  print(:String.combine(:syllables));
  print(:'Codepoint String: "' + codepoints +'"');
}




convert(:parameters.string);
//convert(:'naanshaazohkiizaal');



















