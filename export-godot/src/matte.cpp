#include <fstream>
#include "matte.h"
#include <godot_cpp/core/class_db.hpp>
#include <../../export-cli/matte/src/matte_vm.h>
#include <../../export-cli/matte/src/matte_store.h>
#include <../../export-cli/matte/src/matte_string.h>

using namespace godot;


static matteValue_t send_line(
	matteVM_t * vm, 
	matteValue_t fn, 
	const matteValue_t * args, 
	void * userData
) {

	Matte * m = (Matte*)userData;
	matteStore_t * store = matte_vm_get_store(vm);
	std::string str(matte_string_get_c_str(matte_value_string_get_string_unsafe(store, args[1])));


	m->sendLine(
		matte_value_as_number(store, args[0]),
		str
	);

	return matte_store_new_value(store);
}



static matteValue_t update_settings(
	matteVM_t * vm, 
	matteValue_t fn, 
	const matteValue_t * args, 
	void * userData
) {

	Matte * m = (Matte*)userData;
	matteStore_t * store = matte_vm_get_store(vm);
	std::string str(matte_string_get_c_str(matte_value_string_get_string_unsafe(store, args[0])));


	m->sendSettings(
		str
	);

	return matte_store_new_value(store);
}

static matteValue_t on_play_sfx(
	matteVM_t * vm, 
	matteValue_t fn, 
	const matteValue_t * args, 
	void * userData
) {

	Matte * m = (Matte*)userData;
	matteStore_t * store = matte_vm_get_store(vm);
	std::string str(matte_string_get_c_str(matte_value_string_get_string_unsafe(store, args[0])));


	m->playSFX(
		str
	);

	return matte_store_new_value(store);
}



static matteValue_t on_play_bgm(
	matteVM_t * vm, 
	matteValue_t fn, 
	const matteValue_t * args, 
	void * userData
) {

	Matte * m = (Matte*)userData;
	matteStore_t * store = matte_vm_get_store(vm);
	std::string str(matte_string_get_c_str(matte_value_string_get_string_unsafe(store, args[0])));


    bool loop = matte_value_as_boolean(args[1]);

	m->playBGM(
		str,
		loop
	);

	return matte_store_new_value(store);
}


static matteValue_t request_exit(
	matteVM_t * vm, 
	matteValue_t fn, 
	const matteValue_t * args, 
	void * userData
) {
	Matte * m = (Matte*)userData;
	matteStore_t * store = matte_vm_get_store(vm);
	m->requestExit();
	return matte_store_new_value(store);
}


static void error_messenger(
	matte_t * ctx, 
	const char * msg
) {
	Matte * m = (Matte*)matte_get_user_data(ctx);
	m->sendError(msg);
}




void Matte::_bind_methods() {
	ClassDB::bind_method(D_METHOD("initialize_vm"), &Matte::initializeVM);
	ClassDB::bind_method(D_METHOD("send_input"), &Matte::sendInput);
	ClassDB::bind_method(D_METHOD("enable_debugging"), &Matte::enableDebugging);
	ADD_SIGNAL(
		MethodInfo("on_send_line", PropertyInfo(Variant::INT, "index"), PropertyInfo(Variant::STRING, "data"))
	);

	ADD_SIGNAL(
		MethodInfo("on_send_error", PropertyInfo(Variant::STRING, "data"))
	);

	ADD_SIGNAL(
		MethodInfo("on_send_settings", PropertyInfo(Variant::STRING, "data"))
	);

	ADD_SIGNAL(
		MethodInfo("on_play_sfx", PropertyInfo(Variant::STRING, "name"))
	);

	ADD_SIGNAL(
		MethodInfo("on_play_bgm", PropertyInfo(Variant::STRING, "name"), PropertyInfo(Variant::BOOLEAN, "loop"))
	);


	ADD_SIGNAL(
		MethodInfo("on_request_exit")
	);	
}

Matte::Matte() {
	ctx = NULL;
}

Matte::~Matte() {
}
static std::string getText(const std::string & filename) {
	std::ifstream output(filename);
	std::string line;
	std::string settings;
	while(getline(output, line)) {
		settings += line;
		settings += '\n';
	}
	output.close();
	return settings;

}
void Matte::initializeVM() {
    ctx = matte_create();

	// first get the settings for the game
	std::string text = getText("settings");
	if (text != "")
		sendSettings(text);


	matte_set_user_data(ctx, this);
        
    matte_set_io(ctx, NULL, error_messenger, NULL); // standard IO is fine
    matte_set_importer(ctx, NULL, NULL); // standard file import is fine

    matteVM_t * vm = matte_get_vm(ctx);
    matteStore_t * store = matte_vm_get_store(vm);



	// add external functions for godot behavior
    matte_add_external_function(
        ctx,
        "wyvern_gate__native__godot_send_line",
        send_line,
        this,
        
        // argument names
        "index",
        "line",
        NULL
    );

    matte_add_external_function(
        ctx,
        "wyvern_gate__native__godot_request_exit",
        send_line,
        this,
        
        // argument names
        NULL
    );	


    matte_add_external_function(
        ctx,
        "wyvern_gate__native__godot_update_settings",
        update_settings,
        this,
        
        // argument names
        NULL
    );	

    matte_add_external_function(
        ctx,
        "wyvern_gate__native__godot_on_play_bgm",
        on_play_bgm,
        this,
        
        "name",
        "loop",
        // argument names
        NULL
    );	


    matte_add_external_function(
        ctx,
        "wyvern_gate__native__godot_on_play_sfx",
        on_play_sfx,
        this,
        
        "name",
        // argument names
        NULL
    );	
    matte_vm_import(
        vm,
        MATTE_VM_STR_CAST(vm, "bridge.mt"),
        NULL,
        0,
        matte_store_new_value(store)
    );	

    sendInputMatteCall = matte_run_source(ctx, "return import(:'input.mt');\n\n");

}




void Matte::sendInput(int val) {
	if (ctx == NULL) return;
    matteVM_t * vm = matte_get_vm(ctx);



    matteStore_t * store = matte_vm_get_store(vm);

    matteValue_t arg0 = matte_store_new_value(store);
    matte_value_into_number(store, &arg0, val);
	//matte_run_source(ctx, "import(:'input.mt')();\n\n");
	
	matteValue_t o = matte_call(
		ctx,
		sendInputMatteCall,
		"input", arg0,
		NULL
	);
	

	//printf("getting input %d, %d\n", matte_value_type(o), matte_value_type(sendInputMatteCall));

}

void Matte::sendLine(int index, const std::string & str) {
	emit_signal("on_send_line", index, str.c_str());
}

void Matte::sendError(const std::string & str) {
	emit_signal("on_send_error", str.c_str());
}

void Matte::playSFX(const std::string & str) {
	emit_signal("on_play_sfx", str.c_str());
}

void Matte::playBGM(const std::string & str, bool loop) {
	emit_signal("on_play_bgm", str.c_str(), loop);
}



void Matte::sendSettings(const std::string & str) {
	emit_signal("on_send_settings", str.c_str());
}

void Matte::enableDebugging() {
	if (ctx == NULL) return;
	matte_debugging_enable(ctx);
}

void Matte::requestExit() {
	emit_signal("on_request_exit");
}
#include <stdio.h>
void Matte::_process(double delta) {

}
