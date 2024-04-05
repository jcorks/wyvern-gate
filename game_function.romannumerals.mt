@:computeDigit = ::(digit, single, half, whole) {
    // special cases first
    when (digit == 4) single + half;    
    when (digit == 5) half;
    when (digit == 9) ::<= {
        return single + whole;
    }


    // then iterative cases
    @out = '';
    when (digit < 4) ::<= {
        for(0, digit) ::{
            out = out + single;
        }
        return out;
    }

    out = half;
    for(5, digit) ::{
        out = out + single;
    }
    return out;
}

@:characters = [
    ['I', 'V', 'X'],
    ['X', 'L', 'C'],
    ['C', 'D', 'M'],
    ['M', '&', '*'],
    ['*', '|', '~'],
    ['^', '+', '=']
];

@:unknown = ['?', '?', '?']


return ::(value) {
    value = value->floor;

    @out = '';
    @tier = 0;
    {:::} {
        forever ::{
            when(value == 0) send();
            @set = characters[tier];
            if (set == empty)
                set = unknown;

            out = computeDigit(
                digit: value % 10,
                single: set[0],
                half:   set[1],
                whole:  set[2]
            ) + out;

            tier += 1;
            value = (value / 10)->floor
        }
    };
    return out;
}
