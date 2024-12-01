extends Control
class_name TerminalCanvas;

const HEIGHT:int = 22;
const WIDTH:int = 80;


@export var canvasTheme: Theme;
@export var color: Color = Color.AQUAMARINE;
@onready var errorLabel: RichTextLabel = %ErrorLabel;
@onready var bg: ColorRect = %Background;

var lines: Array = [];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    errorLabel.hide();
    var width = WIDTH*canvasTheme.default_font.get_char_size(' '.to_int(),canvasTheme.default_font_size).x
    var height = 0;
    for i in HEIGHT:
        var line = RichTextLabel.new();
        lines.append(line);
        self.add_child(line);
        var fontHeight = canvasTheme.default_font.get_height(canvasTheme.default_font_size);
        line.position.y = (fontHeight-1) * i;
        line.size.x = get_viewport_rect().size.x;
        line.size.y = fontHeight;
        line.theme = canvasTheme;
        line.modulate = color;
        line.text = str("[]", i);
        height = line.size.y + line.position.y;
    bg.set_size(Vector2(width, height));    
        
func set_line(index, line:String):
    if index > lines.size():
        return
    var converted = [];
    for i in line.length():
        converted.append(line.unicode_at(i));
    var l = PackedByteArray(converted);
    (lines[index] as RichTextLabel).text = l.get_string_from_utf8();

func set_error(text):
    for i in HEIGHT:
        lines[i].hide();
    errorLabel.show();
    errorLabel.text = text;
    

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
