#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "matte/src/matte.h"
#include "matte/src/matte_vm.h"
#include "matte/src/matte_store.h"
#include "matte/src/matte_string.h"
#include "matte/src/matte_array.h"

#define SETTINGS_MASK 0x110000
#define IS_WALLED_MASK 0x010000
#define IS_OBSCURED_MASK 0x100000



#define CHECK_ARG(__V__, __T__) if(matte_value_type(__V__) != __T__) assert(!"Incorrect parameter value.");



#define wyvern_gate__native__bfs__xy_to_id(__x__, __y__) ((__x__) + (__y__)*map.width)
#define wyvern_gate__native__bfs__id_to_x(__id__) (__id__%(map.width))
#define wyvern_gate__native__bfs__id_to_y(__id__) (__id__/(map.width))

#define wyvern_gate__native__bfs__q_push(__v__) (q[qLen++] = __v__)


#define WYVERN_GATE__NATIVE__BFS__BAD_ID -1



// represents the external map
typedef struct {
    // width of the map;
    int width;
    // height of the map
    int height;
    
    // scenery of the map, always width * height size
    matteValue_t scenery;
    
    // reference to the store
    matteStore_t * store;
} wyvern_gate__native__bfs__map_t;



static int wyvern_gate__native__bfs__new_node(int x, int y, wyvern_gate__native__bfs__map_t map) {
    int id = wyvern_gate__native__bfs__xy_to_id(x, y);
    matteValue_t * atScenery = matte_value_object_array_at_unsafe(map.store, map.scenery, id);
    int atSceneryValue = (int)matte_value_as_number(map.store, *atScenery);
    if (!(atSceneryValue & IS_WALLED_MASK) && x >= 0 && y >= 0 && x < map.width && y < map.height) return id;
    return WYVERN_GATE__NATIVE__BFS__BAD_ID;
}



static int wyvern_gate__native__bfs__get_neighbors(
    int current,
    int * neighbors,
    wyvern_gate__native__bfs__map_t map,
    int * pattern,
    int patternSize
) {



    int neighborCount = 0;
    int x = wyvern_gate__native__bfs__id_to_x(current);
    int y = wyvern_gate__native__bfs__id_to_y(current);
    
    int i;
    int n;
    for(n = 0; n < patternSize; ++n) {
        
        i = wyvern_gate__native__bfs__new_node(
            x + pattern[n*2+0],
            y + pattern[n*2+1],
            map
        );
        
        if (i != WYVERN_GATE__NATIVE__BFS__BAD_ID)
            neighbors[neighborCount++] = i;
    }
    
    return neighborCount;
}


/*
    5 arguments:
        0 -> "width" (NUMBER), width of the entire map
        1 -> "height" (NUMBER), height of the entire map
        2 -> "scenery" (OBJECT), array of number values
        3 -> "start" (NUMBER), packed ID of start
        4 -> "goal" (NUMBER), packed ID of goal
        5 -> "corners" (BOOLEAN), false if no diagnal movement
*/
static matteValue_t wyvern_gate__native__bfs(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    matteStore_t * store = matte_vm_get_store(vm);

    // Preflight checks in case a mod got ahold of the BFS and is 
    // trying to be silly.
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_NUMBER);
    CHECK_ARG(args[1], MATTE_VALUE_TYPE_NUMBER);
    CHECK_ARG(args[2], MATTE_VALUE_TYPE_OBJECT);
    CHECK_ARG(args[3], MATTE_VALUE_TYPE_NUMBER);
    CHECK_ARG(args[4], MATTE_VALUE_TYPE_NUMBER);
    CHECK_ARG(args[5], MATTE_VALUE_TYPE_BOOLEAN);
    


    static int patternCorner[] = {
        1, 1,
        1, -1,
        -1, 1,
        -1, -1,
        
        -1, 0,
        1, 0,
        0, 1,
        0, -1
    };

    static int patternNoCorner[] = {
        -1, 0,
        1, 0,
        0, 1,
        0, -1
    };


    int * pattern = NULL;
    int patternSize = 0;

    if (matte_value_as_boolean(store, args[5])) {
        pattern = patternCorner;
        patternSize = 8;
    } else {
        pattern = patternNoCorner;
        patternSize = 4;
    }
    
    
    
    int width = matte_value_as_number(store, args[0]);
    int height = matte_value_as_number(store, args[1]);    
    
    assert(matte_value_object_get_number_key_count(store, args[2]) == width * height);


    wyvern_gate__native__bfs__map_t map;
    map.width = width;
    map.height = height;
    map.scenery = args[2];
    map.store = store;



    int start = matte_value_as_number(store, args[3]);
    int goal = matte_value_as_number(store, args[4]);

    matteValue_t out = matte_store_new_value(store);
    

    // already done. no path
    if (start == goal) return out;    

    int * q = (int*)malloc(width*height * sizeof(int));
    int qLen = 0;
    int * visited = (int*)calloc(width*height, sizeof(int));
    int qIter = 0;

    int neighbors[8];
    int neighborCount;
    
    visited[start] = start;
    wyvern_gate__native__bfs__q_push(start);
    
    while(qIter < qLen) {
        int v = q[qIter];
        qIter++;
        
        // Success! Build the path based on parent history.
        if (v == goal) {
            
            int a = v;
            int last;
            matteArray_t * returnOut = matte_array_create(sizeof(matteValue_t));
            for(;;) {
                matteValue_t aValue = matte_store_new_value(store);
                matte_value_into_number(store, &aValue, a);
                matte_array_push(returnOut, aValue);
                
                if (visited[a] == start) {
                    matte_value_into_new_object_array_ref(store, &out, returnOut);
                    matte_array_destroy(returnOut);
                    goto L_DONE;
                }                    
                
                a = visited[a];
            }
        }
        
        neighborCount = wyvern_gate__native__bfs__get_neighbors(
            v,
            neighbors,
            map,
            pattern,
            patternSize
        );
        
        int i;
        for(i = 0; i < neighborCount; ++i) {
            int w = neighbors[i];
            // this will exclude 0,0 and is a bug, by the way.
            if (visited[w]) continue;
            visited[w] = v;
            wyvern_gate__native__bfs__q_push(w);
        }
    }
L_DONE:
    // no path
    free(q);
    free(visited);
    return out;
}

















static uint32_t CHAR__CORNER_TOPLEFT  = 0x2552;//'╒';
static uint32_t CHAR__CORNER_TOPRIGHT = 0x2555;//'╕';
static uint32_t CHAR__CORNER_BOTTOMRIGHT = 0x2518;//'┘';
static uint32_t CHAR__CORNER_BOTTOMLEFT = 0x2514;//'└';
static uint32_t CHAR__SIDE = 0x2502;//'│';
static uint32_t CHAR__TOP = 0x2550;//'═';
static uint32_t CHAR__BOTTOM = 0x2500;//'─';

#define EFFECT_FINISHED -1

typedef struct {
    matteValue_t self;
    matte_t * m;

    int penx;
    int peny;
    
    int width;
    int height;
    
    uint32_t * canvas;
    matteArray_t * savestates; // full of uint32_t * canvas
    matteArray_t * savestates_id; // full of uint32_t ids
    
    uint32_t idStatePool;
    matteArray_t * idStatePool_dead;
    matteValue_t onCommit;
    
    matteArray_t * effects;

} WyvGateCanvas;

static matteValue_t wyvern_gate__native__canvas__reset(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    uint32_t i;
    for(i = 0; i < cr->savestates->size; ++i) {
        char * state = matte_array_at(cr->savestates, char *, i);
        free(state);
    }
    matte_array_set_size(cr->savestates, 0);
    cr->idStatePool = 0;
    matte_array_set_size(cr->idStatePool_dead, 0);
    
    return matte_store_new_value(store);
}


static matteValue_t wyvern_gate__native__canvas__resize(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_NUMBER);
    CHECK_ARG(args[1], MATTE_VALUE_TYPE_NUMBER);

    wyvern_gate__native__canvas__reset(vm, fn, args, userData);

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    cr->width = matte_value_as_number(store, args[0]);
    cr->height = matte_value_as_number(store, args[1]);
    
    free(cr->canvas);
    cr->canvas = calloc(sizeof(uint32_t), cr->width * cr->height);
    

    
    matteValue_t w = matte_store_new_value(store);
    matteValue_t h = matte_store_new_value(store);
    
    matte_value_into_number(store, &w, cr->width);
    matte_value_into_number(store, &h, cr->height);
    
    matte_value_object_set_key_string(
        store,
        cr->self,
        MATTE_VM_STR_CAST(vm, "width"),
        w
    );

    matte_value_object_set_key_string(
        store,
        cr->self,
        MATTE_VM_STR_CAST(vm, "height"),
        h
    );
    return matte_store_new_value(store);
    
}

static matteValue_t wyvern_gate__native__canvas__movePen(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_NUMBER);
    CHECK_ARG(args[1], MATTE_VALUE_TYPE_NUMBER);

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    cr->penx = matte_value_as_number(store, args[0]);
    cr->peny = matte_value_as_number(store, args[1]);   
    return matte_store_new_value(store);
}

static matteValue_t wyvern_gate__native__canvas__movePenRelative(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_NUMBER);
    CHECK_ARG(args[1], MATTE_VALUE_TYPE_NUMBER);

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    cr->penx += matte_value_as_number(store, args[0]);
    cr->peny += matte_value_as_number(store, args[1]);   
    return matte_store_new_value(store);
}


static matteValue_t wyvern_gate__native__canvas__renderBarAsString(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    CHECK_ARG(args[1], MATTE_VALUE_TYPE_NUMBER);

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    
    int width = matte_value_type(args[0]) == MATTE_VALUE_TYPE_EMPTY ? 
      12
        :
      matte_value_as_number(store, args[0])
    ;
    
    
    double fillFraction = matte_value_as_number(store, args[1]);

    uint32_t character = matte_value_type(args[2]) != MATTE_VALUE_TYPE_STRING ? 
      9619 // (block character)
        :
      matte_string_get_char(matte_value_string_get_string_unsafe(store, args[2]), 0)
    ;
    
    float ratio = fillFraction;
    if (ratio > 1) ratio = 1;
    if (ratio < 0) ratio = 0;

    int numFilled = ((width - 2) * (ratio));
    if (fillFraction > 0 && numFilled < 1) numFilled = 1;
    
    matteString_t * out = matte_string_create(' ');
    uint32_t i;
    for(i = 0; i < numFilled; ++i) {
        matte_string_append_char(out, character);
    }
    for(i = 0; i < width - numFilled - 2; ++i) {
        matte_string_append_char(out, 0x2581); // low block
    }
    matte_string_append_char(out, ' ');

    matteValue_t v = matte_store_new_value(store);
    matte_value_into_string(store, &v, out);
    matte_string_destroy(out);
    
    return v;

}

static void drawChar(WyvGateCanvas * cr, uint32_t ch) {
    if (cr->penx < 0 || cr->penx >= cr->width || cr->peny < 0 || cr->peny >= cr->height) 
      return;
    cr->canvas[cr->penx + cr->peny * cr->width] = ch;
}

static void drawText(WyvGateCanvas * cr, const matteString_t * text) {
    int left = cr->penx;
    uint32_t i;
    for(i = 0; i < matte_string_get_length(text); ++i) {
        drawChar(cr, matte_string_get_char(text, i));
        cr->penx += 1;
    }
    cr->penx = left;
}


static void renderFrame(
    WyvGateCanvas * cr,
    int top,
    int left,
    int width,
    int height 
) {


    // TOP LINE
    cr->penx = left;
    cr->peny = top;
    
    drawChar(cr, CHAR__CORNER_TOPLEFT);
    cr->penx += 1;
    
    uint32_t x;
    for(x = 2; x < width; ++x) {
        drawChar(cr, CHAR__TOP);
        cr->penx += 1;   
    }
    drawChar(cr, CHAR__CORNER_TOPRIGHT);

    
    // NLINES
    uint32_t y;
    for(y = 1; y < height - 1; ++y) {
      cr->penx = left;
      cr->peny = top+y;
      
      drawChar(cr, CHAR__SIDE);
      cr->penx += 1;

      for(x = 2; x < width; ++x) {
        drawChar(cr, ' ');  
        cr->penx += 1;
      }
      drawChar(cr, CHAR__SIDE);
    }


    // BOTTOM LINE
    cr->penx = left;
    cr->peny = top+(height-1);
    
    drawChar(cr, CHAR__CORNER_BOTTOMLEFT);
    cr->penx += 1;
    for(x = 2; x < width; ++x) {
      drawChar(cr, CHAR__BOTTOM);  
      cr->penx += 1;
          
    }
    drawChar(cr, CHAR__CORNER_BOTTOMRIGHT);

}


static matteValue_t wyvern_gate__native__canvas__renderFrame(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_NUMBER);
    CHECK_ARG(args[1], MATTE_VALUE_TYPE_NUMBER);
    CHECK_ARG(args[2], MATTE_VALUE_TYPE_NUMBER);
    CHECK_ARG(args[3], MATTE_VALUE_TYPE_NUMBER);

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    
    renderFrame(
        cr,
        matte_value_as_number(store, args[0]),
        matte_value_as_number(store, args[1]),
        matte_value_as_number(store, args[2]),
        matte_value_as_number(store, args[3])
    );
    

    return matte_store_new_value(store);
}

static matteArray_t * refitLines(matteVM_t * vm, WyvGateCanvas * cr, matteValue_t input, int MAX_WIDTH) {
    matteStore_t * store = matte_vm_get_store(vm);

    matteArray_t * lines = matte_array_create(sizeof(matteString_t*));
    uint32_t count = matte_value_object_get_number_key_count(store, input);
    uint32_t i;
    for(i = 0; i < count; ++i) {
        matteValue_t v = matte_value_object_access_index(store, input, i);
        if (matte_value_type(v) == MATTE_VALUE_TYPE_STRING) {
            const matteString_t * vs = matte_value_string_get_string_unsafe(store, v);
            matteString_t * vc_copy = matte_string_clone(vs);
            matte_array_push(lines, vc_copy);
            if (i != count-1) {
                matteString_t * nl = matte_string_create_from_c_str("\n");
                matte_array_push(lines, nl);
            }
        }
    }


    matteString_t * text = matte_string_create();
    for(i = 0; i < lines->size; ++i) {
        matteString_t * inter = matte_array_at(lines, matteString_t *, i);
        matte_string_concat(text, inter);
        matte_string_destroy(inter);
    }

    matte_array_set_size(lines, 0);    






    matteArray_t * chars = matte_array_create(sizeof(uint32_t));    

    for(i = 0; i < matte_string_get_length(text); ++i) {
        uint32_t word = matte_string_get_char(text, i);

        if (word == '\n') {
            matteString_t * newline = matte_string_create();
            uint32_t n;
            for(n = 0; n < chars->size; ++n) {
                matte_string_append_char(newline, matte_array_at(chars, uint32_t, n));
            }
            matte_array_push(lines, newline);
            matte_array_set_size(chars, 0);
            continue;
        }


        matte_array_push(chars, word);
        if (chars->size >= MAX_WIDTH) {
            matteArray_t * nextLine = matte_array_create(sizeof(uint32_t));
            while(1) {
                uint32_t ch = matte_array_at(chars, uint32_t, chars->size-1);
                if (chars->size < MAX_WIDTH && ch == ' ')
                    break;
                
                matte_array_insert_n(
                    nextLine,
                    0,
                    &ch,
                    1
                );
                if (chars->size <= 1)
                    matte_array_set_size(chars, 0);
                else                    
                    matte_array_set_size(chars, chars->size - 1);
            }
            
            // combine and add to lines
            matteString_t * line = matte_string_create();
            uint32_t n;
            for(n = 0; n < chars->size; ++n) {
                uint32_t ch = matte_array_at(chars, uint32_t, n);
                matte_string_append_char(line, ch);
            }
            matte_array_push(lines, line);
            matte_array_destroy(chars);
            chars = nextLine;
        }        
    }

    matteString_t * line = matte_string_create();
    uint32_t n;
    for(n = 0; n < chars->size; ++n) {
        uint32_t ch = matte_array_at(chars, uint32_t, n);
        matte_string_append_char(line, ch);
    }
    matte_array_push(lines, line);
    matte_string_destroy(text);
    matte_array_destroy(chars);
    return lines;
}


static matteValue_t wyvern_gate__native__canvas__refitLines(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_OBJECT);
    
    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);

    
    int MAX_WIDTH = matte_value_type(args[1]) == MATTE_VALUE_TYPE_EMPTY ?
        cr->width - 4 
      :
        matte_value_as_number(store, args[1])
    ;


    matteArray_t * lines = refitLines(
        vm,
        cr,
        args[0],
        MAX_WIDTH
    );  


    // convert lines into an array of strings
    matteArray_t * linesOut = matte_array_create(sizeof(matteValue_t));
    uint32_t i;
    for(i = 0; i < lines->size; ++i) {
        matteValue_t line = matte_store_new_value(store);
        matte_value_into_string(store, &line, matte_array_at(lines, matteString_t *, i));
        matte_string_destroy(matte_array_at(lines, matteString_t *, i));
        matte_array_push(linesOut, line);
    }

    matteValue_t linesOutV = matte_store_new_value(store);
    matte_value_into_new_object_array_ref(store, &linesOutV, linesOut);
    for(i = 0; i < lines->size; ++i) {
        matte_store_recycle(store, matte_array_at(linesOut, matteValue_t, i));
    }
    matte_array_destroy(linesOut);
    matte_array_destroy(lines);
    return linesOutV;
}


static matteValue_t wyvern_gate__native__canvas__renderTextFrameGeneral(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    const int WINDOW_BUFFER = 4;
    
    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    
    
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_OBJECT);
    float topWeight  = matte_value_type(args[2]) == MATTE_VALUE_TYPE_EMPTY ? 0.5 : matte_value_as_number(store, args[2]);
    float leftWeight = matte_value_type(args[3]) == MATTE_VALUE_TYPE_EMPTY ? 0.5 : matte_value_as_number(store, args[3]);

    matteArray_t * lines;

    // maxWidth
    if (matte_value_type(args[4]) == MATTE_VALUE_TYPE_NUMBER) {
        lines = refitLines(
            vm,
            cr,
            args[0],
            (cr->width - WINDOW_BUFFER) * matte_value_as_number(store, args[4])
        );
    } else {
        lines = matte_array_create(sizeof(matteString_t*));
        uint32_t count = matte_value_object_get_number_key_count(store, args[0]);
        uint32_t i;
        for(i = 0; i < count; ++i) {
            matteValue_t v = matte_value_object_access_index(store, args[0], i);
            if (matte_value_type(v) == MATTE_VALUE_TYPE_STRING) {
                const matteString_t * vs = matte_value_string_get_string_unsafe(store, v);
                matteString_t * vc_copy = matte_string_clone(vs);
                matte_array_push(lines, vc_copy);
            }
        }
 
    }
    
    const matteString_t * title = matte_value_type(args[1]) == MATTE_VALUE_TYPE_STRING ?
        matte_value_string_get_string_unsafe(store, args[1])
      :
        NULL 
    ;
    
    int width = title ? matte_string_get_length(title) + 2 : 0;

    if (matte_value_type(args[6]) == MATTE_VALUE_TYPE_NUMBER) {
        if (width < matte_value_as_number(store, args[6]))
            width = matte_value_as_number(store, args[6]);
    }
    
    uint32_t i;
    for(i = 0; i < lines->size; ++i) {
        uint32_t len = matte_string_get_length(matte_array_at(lines, matteString_t*, i));
        if (len > width)
            width = len;
    }
    
    
    int left = (cr->width - (width + WINDOW_BUFFER)) * leftWeight;
    width = width + WINDOW_BUFFER;
    int top = (cr->height - (lines->size + WINDOW_BUFFER)) * topWeight;
    int height = lines->size + WINDOW_BUFFER;
    
    if (top < 0) top = 0;
    if (left < 0) left = 0;
    
    renderFrame(
        cr,
        top, left, width, height
    );
    
    for(i = 0; i < lines->size; ++i) {
        cr->penx = left+2;
        cr->peny = top + 2 + i;
        
        drawText(cr, matte_array_at(lines, matteString_t *, i));
    }
    
    if (title && matte_string_get_length(title) > 0) {
        cr->penx = left+2;
        cr->peny = top;
        matteString_t * titleFull = matte_string_create_from_c_str(
            "[%s]",
            matte_string_get_c_str(title)
        ); 
        drawText(cr, titleFull);
        matte_string_destroy(titleFull);
    }
    
    if (matte_value_type(args[7]) == MATTE_VALUE_TYPE_STRING) {
        const matteString_t * notchText = matte_value_string_get_string_unsafe(store, args[7]);
        cr->penx = left+width-2-(matte_string_get_length(notchText));
        cr->peny = top+height-1;
        drawText(cr, notchText);
    }
    
    matteValue_t out = matte_store_new_value(store);
    matte_value_into_new_object_ref(store, &out);
    
    matteValue_t temp = matte_store_new_value(store);
    
    matte_value_into_number(store, &temp, left);
    matte_value_object_set_key_string(
        store,
        out,
        MATTE_VM_STR_CAST(vm, "left"),
        temp
    );
    
    matte_value_into_number(store, &temp, top);
    matte_value_object_set_key_string(
        store,
        out,
        MATTE_VM_STR_CAST(vm, "top"),
        temp
    );

    matte_value_into_number(store, &temp, width);
    matte_value_object_set_key_string(
        store,
        out,
        MATTE_VM_STR_CAST(vm, "width"),
        temp
    );

    matte_value_into_number(store, &temp, height);
    matte_value_object_set_key_string(
        store,
        out,
        MATTE_VM_STR_CAST(vm, "height"),
        temp
    );
    
    for(i = 0; i < lines->size; ++i) {
        matte_string_destroy(matte_array_at(lines, matteString_t *, i));
    }
    matte_array_destroy(lines);

    return out;

    
}


static matteValue_t wyvern_gate__native__canvas__pushState(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);

    uint32_t numBytes = sizeof(uint32_t) * cr->width * cr->height;
    uint32_t * canvasCopy = malloc(numBytes);
    memcpy(canvasCopy, cr->canvas, numBytes);

    uint32_t id;
    if (cr->idStatePool_dead->size) {
        id = matte_array_at(cr->idStatePool_dead, uint32_t, cr->idStatePool_dead->size-1);
        matte_array_set_size(cr->idStatePool_dead, cr->idStatePool_dead->size-1);
    } else {
        id = cr->idStatePool++;
    }
    
    matte_array_push(cr->savestates_id, id);
    matte_array_push(cr->savestates, canvasCopy);

    matteValue_t out = matte_store_new_value(store);
    matte_value_into_number(store, &out, id);
    return out;
}

static void blackout(WyvGateCanvas * cr, uint32_t with) {
    if (with == 0) with = ' ';
    uint32_t i;
    for(i = 0; i < cr->width * cr->height; ++i) {
        cr->canvas[i] = with;
    }
}

static void canvasClear(WyvGateCanvas * cr) {
    if (cr->savestates->size) {
        memcpy(
            cr->canvas, 
            matte_array_at(cr->savestates, uint32_t *, cr->savestates->size-1), 
            cr->width * cr->height * sizeof(uint32_t)
        );
        return;
    }
    
    blackout(cr, 0);
}

static matteValue_t wyvern_gate__native__canvas__removeState(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);

    CHECK_ARG(args[0], MATTE_VALUE_TYPE_NUMBER);
    uint32_t id = matte_value_as_number(store, args[0]);
    
    uint32_t i;
    for(i = 0; i < cr->savestates_id->size; ++i) {
        if (id == matte_array_at(cr->savestates_id, uint32_t, i)) {
            matte_array_remove(cr->savestates_id, i);
            uint32_t * buffer = matte_array_at(cr->savestates, uint32_t *, i);
            free(buffer);
            matte_array_remove(cr->savestates, i);
            
            canvasClear(cr);
            return matte_store_new_value(store);

        }
    }
    

}

static matteValue_t wyvern_gate__native__canvas__drawText(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_STRING);

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    const matteString_t * text = matte_value_string_get_string_unsafe(store, args[0]);

    drawText(cr, text);
    return matte_store_new_value(store);

}



static matteValue_t wyvern_gate__native__canvas__drawChar(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_STRING);

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    const matteString_t * text = matte_value_string_get_string_unsafe(store, args[0]);

    uint32_t textCh = ' ';
    if (matte_string_get_length(text) && matte_string_get_char(text, 0) != '\n')
        textCh = matte_string_get_char(text, 0);
        
    drawChar(cr, textCh);
    return matte_store_new_value(store);

}


static matteValue_t wyvern_gate__native__canvas__drawRectangle(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_STRING);
    CHECK_ARG(args[1], MATTE_VALUE_TYPE_NUMBER);
    CHECK_ARG(args[2], MATTE_VALUE_TYPE_NUMBER);

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    uint32_t ch = matte_string_get_char(matte_value_string_get_string_unsafe(store, args[0]), 0);
    int width  = matte_value_as_number(store, args[1]);
    int height = matte_value_as_number(store, args[2]);


    int x, y;
    int offsetx = cr->penx;
    int offsety = cr->peny;
    
    for(y = 0; y < height; ++y) {
        cr->peny = offsety + y;
        for(x = 0; x < width; ++x) {
            cr->penx = offsetx + x;
            drawChar(cr, ch);
        }
    }
    
    cr->penx = offsetx;
    cr->peny = offsety;
    return matte_store_new_value(store);
}


static matteValue_t wyvern_gate__native__canvas__erase(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    drawChar(cr, ' ');
    return matte_store_new_value(store);
}

static matteValue_t wyvern_gate__native__canvas__writeText(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_STRING);

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    const matteString_t * text = matte_value_string_get_string_unsafe(store, args[0]);

    uint32_t i;
    uint32_t len = matte_string_get_length(text);
    
    for(i = 0; i < len; ++i) {
        drawChar(cr, matte_string_get_char(text, i));
        if (cr->penx >= cr->width) {
            cr->penx = 0;
            cr->peny++;
        } else {
            cr->penx++;
        }
    }
    return matte_store_new_value(store);

}


static matteValue_t wyvern_gate__native__canvas__blackout(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);

    uint32_t ch = 0;
    if (matte_value_type(args[0]) == MATTE_VALUE_TYPE_STRING)
        ch = matte_string_get_char(matte_value_string_get_string_unsafe(store, args[0]), 0);

    blackout(cr, ch);
    return matte_store_new_value(store);
}

static matteValue_t wyvern_gate__native__canvas__clear(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);

    canvasClear(cr);
    return matte_store_new_value(store);
}


static void formatColumn(
    WyvGateCanvas * cr, 
    int column, 
    const matteString_t * text, 
    uint8_t * leftJustifieds, // column index ok!
    matteArray_t * parts,
    matteArray_t * widths
) {



    uint32_t i;
    uint32_t count = abs(matte_string_get_length(text) - matte_array_at(widths, int, column));
    if (!leftJustifieds[column]) {
        for(
            i = 0; 
            i < count; 
            ++i
        ) {
            matteString_t * sp = matte_string_create_from_c_str(" ");
            matte_array_push(parts, sp);    
        }
    }
    
    matteString_t * c = matte_string_clone(text);
    matte_array_push(parts, c);

    if (leftJustifieds[column]) {
        for(
            i = 0; 
            i < count; 
            ++i
        ) {
            matteString_t * sp = matte_string_create_from_c_str(" ");
            matte_array_push(parts, sp);    
        }
    }
    

}


static matteValue_t wyvern_gate__native__canvas__columnsToLines(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    CHECK_ARG(args[0], MATTE_VALUE_TYPE_OBJECT);

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    
    
    uint32_t nColumns = matte_value_object_get_number_key_count(store, args[0]);
    uint8_t * leftJustifieds = malloc(nColumns);
    memset(leftJustifieds, 1, nColumns);

    
    if (matte_value_type(args[1]) == MATTE_VALUE_TYPE_OBJECT) {
        uint32_t i;
        for(i = 0; i < nColumns; ++i) {
            leftJustifieds[i] = matte_value_as_boolean(store, matte_value_object_access_index(store, args[1], i));
        }
    }

    int spacing = 1;
    if (matte_value_type(args[2]) == MATTE_VALUE_TYPE_NUMBER) {
        spacing = matte_value_as_number(store, args[2]);
    }

    matteArray_t * lines = matte_array_create(sizeof(matteString_t *));
    matteArray_t * widths = matte_array_create(sizeof(int));
    int rowCount = 0;
    
    uint32_t i;
    for(i = 0; i < nColumns; ++i) {
        matteValue_t lines = matte_value_object_access_index(store, args[0], i);
        CHECK_ARG(lines, MATTE_VALUE_TYPE_OBJECT);
        
        int width = 0;

        uint32_t row;
        uint32_t nLines = matte_value_object_get_number_key_count(store, lines);
        for(row = 0; row < nLines; ++row) {
            matteValue_t lineV = matte_value_object_access_index(store, lines, row);
            CHECK_ARG(lineV, MATTE_VALUE_TYPE_STRING);
            const matteString_t * line = matte_value_string_get_string_unsafe(store, lineV);

            if (matte_string_get_length(line) > width)
                width = matte_string_get_length(line);
                
            if (row+1 > rowCount)
                rowCount = row+1;
            
        }
        
        matte_array_push(widths, width);
    }
    
    
    
    
    matteArray_t * parts = matte_array_create(sizeof(matteString_t *));
    
    
    uint32_t row;
    for(row = 0; row < rowCount; ++row) {
        uint32_t i;
        for(i = 0; i < parts->size; ++i) {
            matte_string_destroy(matte_array_at(parts, matteString_t *, i));
        }
        matte_array_set_size(parts, 0);
        
        
        uint32_t column = 0;
        for(column = 0; column < nColumns; ++column) {
            matteValue_t lines = matte_value_object_access_index(store, args[0], column);
            CHECK_ARG(lines, MATTE_VALUE_TYPE_OBJECT);

            matteValue_t line = matte_value_object_access_index(store, lines, row);;
            CHECK_ARG(line, MATTE_VALUE_TYPE_STRING);

            formatColumn(
                cr, 
                column,
                matte_value_string_get_string_unsafe(store, line),
                
                leftJustifieds,
                parts,
                widths
            );
            
            for(i = 0; i < spacing; ++i) {
                matteString_t * str = matte_string_create_from_c_str(" ");
                matte_array_push(parts, str);
            }
        }
        
        matteString_t * fullLine = matte_string_create();
        for(i = 0; i < parts->size; ++i) {
            matte_string_concat(fullLine, matte_array_at(parts, matteString_t *, i));
        }
        matte_array_push(lines, fullLine);
    }
    
    for(i = 0; i < parts->size; ++i) {
        matte_string_destroy(matte_array_at(parts, matteString_t *, i));
    }
    matte_array_destroy(parts);
    
    
    
    // convert lines into matte value array
    matteValue_t output = matte_store_new_value(store);
    matte_value_into_new_object_ref(store, &output);
    for(i = 0; i < lines->size; ++i) {
        matteValue_t line = matte_store_new_value(store);
        matte_value_into_string(store, &line, matte_array_at(lines, matteString_t *, i));
        matte_string_destroy(matte_array_at(lines, matteString_t *, i));
        
        matte_value_object_push(store, output, line);
    }

    matte_array_destroy(lines);
    matte_array_destroy(widths);
    free(leftJustifieds);
    return output;

}


static matteValue_t wyvern_gate__native__canvas__addEffect(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {

    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);

    assert(matte_value_is_function(args[0]));
    matte_value_object_push_lock(store, args[0]);

    matte_array_push(cr->effects, args[0]);

    return matte_store_new_value(store);
}

static void pushToScreen(
    WyvGateCanvas * cr,
    matteVM_t * vm,
    matteStore_t * store,
    int renderNow
) {
    matteValue_t onCommit = matte_value_object_access_string(
        store,
        cr->self,
        MATTE_VM_STR_CAST(vm, "onCommit")
    );
    
    if (!matte_value_is_function(onCommit)) return;
    matteValue_t lines_output = matte_store_new_value(store);
    matte_value_into_new_object_ref(store, &lines_output);
    
    uint32_t row, n;
    for(row = 0; row < cr->height; ++row) {
        matteString_t * next = matte_string_create();
        
        for(n = row*cr->width; n < (row+1)*cr->width; ++n) {
            matte_string_append_char(next, cr->canvas[n]);
        }
        
        matteValue_t nextV = matte_store_new_value(store);
        matte_value_into_string(store, &nextV, next);
        matte_string_destroy(next);
        
        matte_value_object_push(store, lines_output, nextV);
    }

    
    if (renderNow) {
        matteValue_t renderNowV = matte_store_new_value(store);
        matte_value_into_boolean(store, &renderNowV, renderNow);
        matte_call(
            cr->m,
            onCommit,
            
            "lines", lines_output,
            "renderNow", renderNowV,
            NULL
        );    
    
    } else {  
        matte_call(
            cr->m,
            onCommit,
            
            "lines", lines_output,
            NULL
        );     
    }
     
}


static matteValue_t wyvern_gate__native__canvas__update(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {


    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);

    if (cr->effects->size == 0)
        return matte_store_new_value(store);


    uint32_t nBytes = cr->width * cr->height * sizeof(uint32_t);
    uint32_t * copy = malloc(nBytes);
    memcpy(copy, cr->canvas, nBytes);
    
    uint32_t * old = cr->canvas;
    cr->canvas = copy;
    
    
    
    uint32_t i;
    for(i = 0; i < cr->effects->size; ++i) {
        matteValue_t res = matte_call(
            cr->m,
            matte_array_at(cr->effects, matteValue_t, i),
            NULL
        );
        
        if (matte_value_type(res) == MATTE_VALUE_TYPE_NUMBER && matte_value_as_number(store, res) == EFFECT_FINISHED) {
            matte_value_object_pop_lock(store, matte_array_at(cr->effects, matteValue_t, i));
            matte_array_remove(cr->effects, i);
            i--;
        }
    }
    
    pushToScreen(cr, vm, store, 0);
    
    cr->canvas = old;
    free(copy);


    return matte_store_new_value(store);
}


static matteValue_t wyvern_gate__native__canvas__commit(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {


    WyvGateCanvas * cr = userData;
    matteStore_t * store = matte_vm_get_store(vm);
    
    int renderNow = 0;
    if (matte_value_type(args[0]) == MATTE_VALUE_TYPE_BOOLEAN) {
        renderNow = matte_value_as_boolean(store, args[0]);
    }
    
    if (cr->effects->size > 0 && (renderNow != 1))
        return matte_store_new_value(store);
    
    pushToScreen(cr, vm, store, 0);


    return matte_store_new_value(store);
}




static matteValue_t wyvern_gate__native__canvas(
    matteVM_t * vm,
    matteValue_t fn,
    const matteValue_t * args,
    void * userData
) {
    matteStore_t * store = matte_vm_get_store(vm);
    matteValue_t a = matte_store_new_value(store);
    
    matte_value_into_new_object_ref(store, &a);
    
    WyvGateCanvas * cr = calloc(1, sizeof(WyvGateCanvas));
    cr->self = a;
    cr->penx = 0;
    cr->peny = 0;
    cr->width = 80;
    cr->height = 24;
    cr->m = userData;
    
    cr->canvas = calloc(cr->width * cr->height, sizeof(uint32_t));
    cr->savestates = matte_array_create(sizeof(uint32_t *));
    cr->savestates_id = matte_array_create(sizeof(uint32_t));

    cr->idStatePool = 0;
    cr->idStatePool_dead = matte_array_create(sizeof(uint32_t));
    cr->effects = matte_array_create(sizeof(matteValue_t));
      

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__reset",
        wyvern_gate__native__canvas__reset,
        cr,
        NULL
    );


    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__resize",
        wyvern_gate__native__canvas__resize,
        cr,
        
        "width",
        "height",
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__movePen",
        wyvern_gate__native__canvas__movePen,
        cr,
        
        "x",
        "y",
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__movePenRelative",
        wyvern_gate__native__canvas__movePenRelative,
        cr,
        
        "x",
        "y",
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__renderBarAsString",
        wyvern_gate__native__canvas__renderBarAsString,
        cr,
        
        "width",
        "fillFraction",
        "character",
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__renderFrame",
        wyvern_gate__native__canvas__renderFrame,
        cr,
        
        "top",
        "left",
        "width",
        "height",
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__refitLines",
        wyvern_gate__native__canvas__refitLines,
        cr,
        
        "input",
        "maxWidth",
        NULL
    );


    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__renderTextFrameGeneral",
        wyvern_gate__native__canvas__renderTextFrameGeneral,
        cr,
        
        "lines",
        "title",
        "topWeight",
        "leftWeight",
        "maxWidth",
        "maxHeight",
        "minWidth",
        "notchText",
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__pushState",
        wyvern_gate__native__canvas__pushState,
        cr,
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__removeState",
        wyvern_gate__native__canvas__removeState,
        cr,
        
        "id",
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__drawText",
        wyvern_gate__native__canvas__drawText,
        cr,
        
        "text",
        NULL
    );
    
    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__drawChar",
        wyvern_gate__native__canvas__drawChar,
        cr,
        
        "text",
        NULL
    );    

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__drawRectangle",
        wyvern_gate__native__canvas__drawRectangle,
        cr,
        
        "text",
        "width",
        "height",
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__erase",
        wyvern_gate__native__canvas__erase,
        cr,
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__writeText",
        wyvern_gate__native__canvas__writeText,
        cr,
        
        "text",
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__clear",
        wyvern_gate__native__canvas__clear,
        cr,
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__blackout",
        wyvern_gate__native__canvas__blackout,
        cr,
        
        "width",
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__columnsToLines",
        wyvern_gate__native__canvas__columnsToLines,
        cr,
        
        "columns",
        "leftJustifieds",
        "spacing",
        NULL
    );


    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__addEffect",
        wyvern_gate__native__canvas__addEffect,
        cr,
        
        "effect",
        NULL
    );

    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__update",
        wyvern_gate__native__canvas__update,
        cr,
        
        NULL
    );


    matte_add_external_function(
        userData,
        "wyvern_gate__native__canvas__commit",
        wyvern_gate__native__canvas__commit,
        cr,
        
        NULL
    );

    return a;
}




void wyvern_gate_add_native(matte_t * m) {
    matte_add_external_function(
        m,
        "wyvern_gate__native__bfs",
        wyvern_gate__native__bfs,
        NULL,
        
        "width",    
        "height",
        "scenery",
        "start",
        "goal",
        "corners",
        NULL
    );


    matte_add_external_function(
        m,
        "wyvern_gate__native__canvas",
        wyvern_gate__native__canvas,
        m,
        NULL
    );


}

