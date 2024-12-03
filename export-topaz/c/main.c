#include <topaz/topaz.h>
#include <topaz/modules/view_manager.h>
#include <topaz/all.h>
#include <string.h>
#include "matte/src/matte.h"

static int run_script(topaz_t * ctx, topazScript_t * script, const topazString_t * name) {
    // extract the script data
    topazFilesystem_t * fs = topaz_context_get_filesystem(ctx);
    const topazFilesystem_Path_t * path = topaz_filesystem_get_path_from_string(
        fs, 
        topaz_filesystem_get_path_from_string(
            fs,
            NULL,
            topaz_resources_get_path(topaz_context_get_resources(ctx))
        ),
        name    
    );
    if (!path) {
        return 0;
    }
    topazRbuffer_t * scriptFile = topaz_filesystem_path_read(path);
    if (!scriptFile) {
        return 0;
    }
    const topazString_t * scriptText  = topaz_rbuffer_read_string(
        scriptFile,
        topaz_rbuffer_get_size(scriptFile)
    );
          
    topaz_script_run(
        script,
        name,
        scriptText
    );
    return 1;   
}


void wyvern_gate_add_native(matte_t * m);



static void window_close_callback(
    /// The display responding to the event.
    topazDisplay_t * display,
    /// The data bound to the callback.
    void * ctx
) {
    topaz_context_quit(ctx);
}

int main(int argc, char ** argv) {
    topazString_t * path = NULL;
    topazString_t * location = NULL;
    int i;
    for(i = 0; i < argc; ++i) {
        if (strstr(argv[i], "location:") == argv[i]) {
            location = topaz_string_create_from_c_str("%s", argv[1]+strlen("location:"));            
            break;
        }
    }
 
    // Create the context and window
    topaz_t * ctx = topaz_context_create(argc, argv);


    // Creates a script instance. The permissions can 
    // activate / deactive certain features within the script context.
    topazScript_t * script = topaz_script_manager_create_context(
        topaz_context_get_script_manager(ctx),
        topazScriptManager_Permission_All
    );

    if (location != NULL) {
        if (!topaz_resources_set_path(
            topaz_context_get_resources(ctx),
            location
        )) {

            topazConsole_t * console = topaz_context_get_console(ctx);
            topaz_console_enable(console, TRUE);

            topazString_t * message = topaz_string_create_from_c_str("Could not change directory to %s", topaz_string_get_c_str(location));
            topaz_console_print(console, message);
            topaz_string_destroy(message);
            return 10;
        }
        
    }

    path = topaz_string_create_from_c_str("topaz_main.mt");
        

    
    wyvern_gate_add_native(
        topaz_script_get_context(
            script 
        )
    );
        
    


    // Optional
    topazDisplay_t * display = topaz_view_manager_create_display(topaz_context_get_view_manager(ctx), TOPAZ_STR_CAST(""));

    // add behavior for system X button
    topaz_display_add_close_callback(
        display,
        window_close_callback,
        ctx
    );

    run_script(ctx, script, TOPAZ_STR_CAST("preload"));

    if (!run_script(ctx, script, path)) {

        // We want to enable use of the debugging console.
        //
        topazConsole_t * console = topaz_context_get_console(ctx);
        topaz_console_enable(console, TRUE);

        topazString_t * message = topaz_string_create_from_c_str("Script \"%s\" could not be opened or was empty.", topaz_string_get_c_str(path));
        topaz_console_print(console, message);
        topaz_string_destroy(message);
        exit(1);
    } 
    topaz_context_run(ctx);
}
