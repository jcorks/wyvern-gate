extends Matte

@onready var canvas: TerminalCanvas = %Canvas;
@onready var timer: Timer = %Timer;

@export var repeat_time: float =  0.1;
@export var initial_wait: float = 0.4;

var l = 0;
var debug = false;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    timer.connect("timeout", func():
        send_input(-1);  
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
    )

    connect("on_send_settings", func(str): 
        var settings = JSON.parse_string(str);    
        if (settings.debugMode == true):
            debug = true;
            print("Enabled debug mode.");
            enable_debugging();
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


    
