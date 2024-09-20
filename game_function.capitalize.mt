@:table = {
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

return ::(string => String) {
  when(string == '') '';
  @:first = string->charAt(:0);
  when (table[first] == empty) string;
  when (string->length == 1) table[first];
  
  return table[first] + string->substr(from:1, to:string->length-1);  
}
