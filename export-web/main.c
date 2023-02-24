#include <emscripten.h>
#include <stdio.h>
#include "./matte/src/matte_vm.h"
#include "./matte/src/matte.h"
#include "./matte/src/matte_heap.h"
#include "./matte/src/matte_string.h"
#include <string.h>
#include <stdlib.h>

// forward declare the external links
void external_on_start_commit();
void external_on_end_commit();
void external_on_commit_text(const char *);
void external_on_save_state(int, const char *);
char * external_on_load_state(int);
int external_get_input();
void external_unhandled_error(const char *, const char *);



void matte_external_unhandled_error(
    matteVM_t * vm, 
    uint32_t file, 
    int lineNumber, 
    matteValue_t value, 
    void * data
) {
    matteString_t * err = matte_string_create();
    matteValue_t s = matte_value_object_access_string(matte_vm_get_heap(vm), value, MATTE_VM_STR_CAST(vm, "summary"));
    if (s.binID) {
        
        matte_string_concat_printf(
            err,            
            "Unhandled error: %s\n", 
            matte_string_get_c_str(matte_value_string_get_string_unsafe(matte_vm_get_heap(vm), s))
        );
    }
    external_unhandled_error(
        WYRVEN_GIT_COMMIT,
        matte_string_get_c_str(err)
    );
    matte_string_destroy(err);
}


static matteValue_t matte_external_on_start_commit(
    matteVM_t * vm, 
    matteValue_t fn, 
    const matteValue_t * args, 
    void * userData
) {
    external_on_start_commit();
    return matte_heap_new_value(matte_vm_get_heap(vm));
}



static matteValue_t matte_external_on_end_commit(
    matteVM_t * vm, 
    matteValue_t fn, 
    const matteValue_t * args, 
    void * userData
) {
    external_on_end_commit(); 
    return matte_heap_new_value(matte_vm_get_heap(vm));
}

static matteValue_t matte_external_on_commit_text(
    matteVM_t * vm, 
    matteValue_t fn, 
    const matteValue_t * args, 
    void * userData
) {
    external_on_commit_text(
        matte_string_get_c_str(
            matte_value_string_get_string_unsafe(
                matte_vm_get_heap(vm),
                args[0]
            )
        )
    );
    return matte_heap_new_value(matte_vm_get_heap(vm));
}

static matteValue_t matte_external_on_save_state(
    matteVM_t * vm, 
    matteValue_t fn, 
    const matteValue_t * args, 
    void * userData
) {
    external_on_save_state(
        matte_value_as_number(matte_vm_get_heap(vm), args[0]),
        
        matte_string_get_c_str(
            matte_value_string_get_string_unsafe(
                matte_vm_get_heap(vm),
                args[1]
            )
        )
    );
    return matte_heap_new_value(matte_vm_get_heap(vm));
}

static matteValue_t matte_external_on_load_state(
    matteVM_t * vm, 
    matteValue_t fn, 
    const matteValue_t * args, 
    void * userData
) {
    char * state = external_on_load_state(
        matte_value_as_number(matte_vm_get_heap(vm), args[0])
    );
    
    matteValue_t out = matte_heap_new_value(matte_vm_get_heap(vm));
    matteString_t * str = matte_string_create();
    matte_string_concat_printf(str, "%s", state);
    matte_value_into_string(matte_vm_get_heap(vm), &out, str);
    matte_string_destroy(str);
    free(state);
    return out;
}

static matteValue_t matte_external_get_input(
    matteVM_t * vm, 
    matteValue_t fn, 
    const matteValue_t * args, 
    void * userData
) {
    emscripten_sleep(18);   
    double val = external_get_input();
    matteValue_t out = matte_heap_new_value(matte_vm_get_heap(vm));
    matte_value_into_number(matte_vm_get_heap(vm), &out,  val);
    return out;
}



int main(int argc, char ** argv) {
    matte_t * m = matte_create();
    matteVM_t * vm = matte_get_vm(m);
    matte_vm_set_unhandled_callback(vm, matte_external_unhandled_error, NULL);
    // set external functions
    matte_vm_set_external_function_autoname(vm, MATTE_VM_STR_CAST(vm, "external_onStartCommit"), 0, matte_external_on_start_commit, NULL);
    matte_vm_set_external_function_autoname(vm, MATTE_VM_STR_CAST(vm, "external_onEndCommit"),   0, matte_external_on_end_commit, NULL);
    matte_vm_set_external_function_autoname(vm, MATTE_VM_STR_CAST(vm, "external_onCommitText"),  1, matte_external_on_commit_text, NULL);
    matte_vm_set_external_function_autoname(vm, MATTE_VM_STR_CAST(vm, "external_onSaveState"),   2, matte_external_on_save_state, NULL);
    matte_vm_set_external_function_autoname(vm, MATTE_VM_STR_CAST(vm, "external_onLoadState"),   1, matte_external_on_load_state, NULL);
    matte_vm_set_external_function_autoname(vm, MATTE_VM_STR_CAST(vm, "external_getInput"),      0, matte_external_get_input, NULL);
    
    matteValue_t v = matte_vm_import(vm, MATTE_VM_STR_CAST(vm, "main_external.mt"), matte_heap_new_value(matte_vm_get_heap(vm)));
    matte_heap_recycle(matte_vm_get_heap(vm), v);
    matte_destroy(m);
    return 0;
}





// temporary simple tests
//////////////////////

/*
static int counter = 0;
void external_on_start_commit() {
    printf("\033[2J");
    counter = 0;
}
void external_on_commit_text(const char * ch) {

    printf("%s", ch);
    printf("\n");
}
void external_on_end_commit() {
    fflush(stdout);
}

void external_on_save_state(int slot, const char * str) {
    
}
char * external_on_load_state(int h) {
    return NULL;
}
int external_get_input() {
    char str[2] = {};
    str[0] = getc(stdin);
    return atoi(str);
}
void external_unhandled_error(const char * ch) {
    printf("ERROR:\n%s", ch);
}
*/


//////////////////////



