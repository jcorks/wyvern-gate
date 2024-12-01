extends Matte

@onready var canvas: TerminalCanvas = %Canvas;
@onready var timer: Timer = %Timer;
var l = 0;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    timer.connect("timeout", func():
        send_input(-1);  
    )
    
    connect("on_send_line", func(index, str): 
        canvas.set_line(index, str)
    )

    connect("on_send_error", func(str): 
        canvas.set_error(str)
        print(str("MATTE VM ERROR: ", str))
    )


    connect("on_request_exit", func(): 
        get_tree().quit()
    )
    initialize_vm(0)
func _input(event: InputEvent):
    if (event is InputEventKey && (event.pressed || event.echo)):
        
        if (event.keycode == KEY_UP):
            send_input(1)
        if (event.keycode == KEY_DOWN):
            send_input(3)
        if (event.keycode == KEY_LEFT):
            send_input(0)
        if (event.keycode == KEY_RIGHT):
            send_input(2)
            
        if (event.keycode == KEY_SPACE ||
            event.keycode == KEY_Z):
            send_input(4)

        if (event.keycode == KEY_BACKSPACE ||
            event.keycode == KEY_X):
            send_input(5)

    
