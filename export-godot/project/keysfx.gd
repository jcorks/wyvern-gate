extends Node2D

@onready var SFX_Keyboard_1: AudioStreamPlayer = %SFX_Keyboard_1;
@onready var SFX_Keyboard_2: AudioStreamPlayer = %SFX_Keyboard_2;
@onready var SFX_Keyboard_3: AudioStreamPlayer = %SFX_Keyboard_3;
@onready var SFX_Keyboard_4: AudioStreamPlayer = %SFX_Keyboard_4;


func play() -> void:
    var all = [
        SFX_Keyboard_1,
        SFX_Keyboard_2,
        SFX_Keyboard_3,
        SFX_Keyboard_4
    ];
    for v in all:
        v.stop();
    var sfx = all.pick_random();
    sfx.pitch_scale = randf()*0.07 + 0.97;
    sfx.play()    
    
    
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
