return ::(word) <- (

  match(word->charAt(index:0)) {
    ('a', 'e', 'i', 'o', 'u',
     'A', 'E', 'I', 'O', 'U'): 'an ',
     
    default: 'a '
  }

) + word;
