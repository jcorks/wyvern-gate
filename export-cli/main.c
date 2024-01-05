#include <stdlib.h>
#include <string.h>
#include "matte/src/matte.h"
#include "matte/src/matte_vm.h"
#include "matte/src/matte_store.h"
#include "matte/src/matte_string.h"



// Provided by native.c, binds native function implementations 
// (external functions) to the runtime.
void wyvern_gate_add_native(matte_t * m);



// returns whether the given args contains a string.
static int contains_arg(int argc, char ** argv, const char * hint) {
    int i;
    for(i = 0; i < argc; ++i) {
        if (!strcmp(hint, argv[i]))
            return 1;
    }
    return 0;
}



// Sets up Matte runtime and runs cli.mt
int main(int argc, char ** argv) {
    matte_t * m = matte_create();
    
    wyvern_gate_add_native(m);
    
    matte_set_io(m, NULL, NULL, NULL); // standard IO is fine
    matte_set_importer(m, NULL, NULL); // standard file import is fine

    matteVM_t * vm = matte_get_vm(m);
    matteStore_t * store = matte_vm_get_store(vm);

    if (contains_arg(argc, argv, "--debug")) {
        matte_debugging_enable(m);
    }
    
    matteValue_t v = matte_vm_import(
        vm,
        MATTE_VM_STR_CAST(vm, "cli.mt"),
        matte_store_new_value(store)
    );
    
    matte_destroy(m);        
    return 0;
}
