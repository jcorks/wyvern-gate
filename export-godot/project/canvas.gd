extends Control
class_name TerminalCanvas;

const HEIGHT:int = 22;
const WIDTH:int = 80;

@export var canvasTheme: Theme;
@onready var errorLabel: RichTextLabel = %ErrorLabel;

var lines: Array = [];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    errorLabel.hide();
    for i in HEIGHT:
        var line = RichTextLabel.new();
        lines.append(line);
        self.add_child(line);
        var fontHeight = canvasTheme.default_font.get_height(canvasTheme.default_font_size);
        line.position.y = fontHeight * i;
        line.size.x = get_viewport_rect().size.x;
        line.size.y = fontHeight;
        line.theme = canvasTheme;
        line.text = str("[]", i)
        
func set_line(index, line:String):
    print(line);
    if index > lines.size():
        return
    var converted = [];
    for i in line.length():
        converted.append(line.unicode_at(i));
    var l = PackedByteArray(converted);
    (lines[index] as RichTextLabel).text = l.get_string_from_utf8();

func set_error(text):
    print(text);
    for i in HEIGHT:
        lines[i].hide();
    errorLabel.show();
    errorLabel.text = text;
    

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
