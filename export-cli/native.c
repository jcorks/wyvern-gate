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
    wyvern_gate__native__bfs__map_t map
) {
    static int pattern[] = {
        //1, 1,
        //1, -1,
        //-1, 1,
        //-1, -1,
        
        -1, 0,
        1, 0,
        0, 1,
        0, -1
    };


    int neighborCount = 0;
    int x = wyvern_gate__native__bfs__id_to_x(current);
    int y = wyvern_gate__native__bfs__id_to_y(current);
    
    int i;
    int n;
    for(n = 0; n < 4; ++n) {
        
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
            map
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
        NULL
    );
}

