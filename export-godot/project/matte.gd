extends Matte

@onready var canvas: TerminalCanvas = %Canvas;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    connect("on_send_line", func(index, str): 
        canvas.set_line(index, str)
    )

    connect("on_send_error", func(str): 
        canvas.set_error(str)
    )


    connect("on_request_exit", func(): 
        get_tree().quit()
    )
    initialize_vm(0)
