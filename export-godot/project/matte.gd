extends Matte

@onready var canvas: TerminalCanvas = %Canvas;
@onready var timer: Timer = %Timer;

@export var repeat_time: float =  0.1;
@export var initial_wait: float = 0.4;

@onready var SFX_Cancel: AudioStreamPlayer = %SFX_Cancel;
@onready var SFX_Confirm: AudioStreamPlayer = %SFX_Confirm;
@onready var SFX_Cursor: AudioStreamPlayer = %SFX_Cursor;
@onready var SFX_Keyboard = %SFX_Keyboard;


@onready var BGM_Title: AudioStreamPlayer = %BGM_Title;
@onready var BGM_Boot: AudioStreamPlayer = %BGM_Boot;
@onready var BGM_Bootpost: AudioStreamPlayer = %BGM_Bootpost;
@onready var BGM_World: AudioStreamPlayer = %BGM_World;
@onready var BGM_Town2: AudioStreamPlayer = %BGM_Town2;



    
func rangeToDB(val: float):
    if (val < 0.0001): val = 0.0001;
    if (val > 0.99): val = 0.99;
    return 20 * log(val) / log(10);

var lastBGM: AudioStreamPlayer;
func playBGM(which):
    if lastBGM != null:
        lastBGM.stop();
    which.play();
    lastBGM = which;

var l = 0;
var debug = false;
var keepSending = true;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    timer.connect("timeout", func():
        if (keepSending):
            send_input(-1);  
    )
    
    connect("on_play_sfx", func(name):
        if (name == 'cancel'): SFX_Cancel.play();
        if (name == 'cursor'): SFX_Cursor.play();
        if (name == 'confirm'): SFX_Confirm.play();
        if (name == 'keyboard'): SFX_Keyboard.play();
        
        print(str("Request to play ", name));
    )
        
    
    connect("on_play_bgm", func(name, loop):
        print(str("Request to play BGM", name));
        if (name == 'title'): playBGM(BGM_Title);
        if (name == 'boot'): playBGM(BGM_Boot);
        if (name == 'boot-post'): playBGM(BGM_Bootpost);

        return
        if (name == 'world'): playBGM(BGM_World);
        if (name == 'town-2'): playBGM(BGM_Town2);
    
    )    
    
    connect("on_send_line", func(index, str): 
        canvas.set_line(index, str)
    )

    connect("on_send_error", func(strn): 
        if (debug == false):
            canvas.set_error(strn)
            print(str("MATTE VM ERROR: ", strn))
        else:
            print(strn)
        keepSending = false;
    )

    connect("on_send_settings", func(str): 
        var settings = JSON.parse_string(str);    
        if (settings.debugMode == true):
            debug = true;
            print("Enabled debug mode.");
            enable_debugging();
            
        if (settings.has("volumeSFX")):
            print(str("set volume sfx", settings.volumeSFX, " ", rangeToDB(settings.volumeSFX), "db"))
            var sfxBus = AudioServer.get_bus_index("SFX");
            AudioServer.set_bus_volume_db(sfxBus, rangeToDB(settings.volumeSFX));

        if (settings.has("volumeBGM")):
            print(str("set volume bgm", settings.volumeSFX, " ", rangeToDB(settings.volumeBGM), "db"))
            var sfxBus = AudioServer.get_bus_index("BGM");
            AudioServer.set_bus_volume_db(sfxBus, rangeToDB(settings.volumeBGM));

            
        canvas.apply_settings(settings)
    )

    connect("on_request_exit", func(): 
        get_tree().quit()
    )
    initialize_vm()
    
    
    
var held = {
    "left" : 0.0,
    "up" : 0.0,
    "right" : 0.0,
    "down" : 0.0,
    "confirm" : 0.0,
    "cancel" : 0.0
}
var input2value = {
    "left" : 0,
    "up" : 1,
    "right" : 2,
    "down" : 3,
    "confirm" : 4,
    "cancel" : 5
}

var inputs = [
    "left",
    "up",
    "right",
    "down",
    "confirm",
    "cancel"
]

func _process(delta):
    for k in inputs:        
        if (Input.is_action_pressed(k, true) && held[k] == 0):
            print(str(k, held[k]));
            send_input(input2value[k])
            held[k] = 1 - initial_wait;
        elif (Input.is_action_just_released(k)):
            print(str(k, "RESET"));
            held[k] = 0;
        
        if (held[k] > 0):
            held[k] += delta;
            if (held[k] >= 1 + repeat_time):
                held[k] = 1;
                print(str(k, "REPEAT"));
                send_input(input2value[k]);


    
