extends Control
class_name TerminalCanvas;

const HEIGHT:int = 22;
const WIDTH:int = 80;
var base_width:float = 0;
var base_height:float = 0;


@export var canvasTheme: Theme;
@export var color: Color = Color.AQUAMARINE;
@onready var errorLabel: RichTextLabel = %ErrorLabel;
@onready var bg: ColorRect = %Background;
@onready var crt: Control = %CRT;

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
    
    base_width = width;
    base_height = height;
    bg.set_size(Vector2(width, height));

    get_window().size_changed.connect(func(): 
        var siz = get_window().size;
        
        # first, find the nearest scale that preserves the aspect ratio
        var aspRatio = base_height / base_width;
        var reqWidth = 0;
        var reqHeight = 0;
        var scale = 1;
        if (siz.x < siz.y):
            reqWidth = siz.x;
            reqHeight = siz.x * aspRatio;
        else:
            reqWidth = siz.y / aspRatio
            reqHeight = siz.y ;
        
        if (reqWidth > siz.x):
            reqWidth = siz.x;
            reqHeight = reqWidth * aspRatio;

        if (reqHeight > siz.y):
            reqHeight = siz.y;
            reqHeight = reqWidth / aspRatio;

        scale = reqWidth / base_width;
        self.position = -Vector2(
            (reqWidth - siz.x)/2,
            (reqHeight - siz.y)/2,
        )
        self.scale = Vector2(scale, scale);
        bg.global_position = Vector2(0, 0);
        bg.size = Vector2(
            siz.x * (1/self.scale.x),
            siz.y * (1/self.scale.y)
        );

    ) 


    get_window().size = Vector2i(width*2, height*2)        
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

func apply_settings(settings):
    if (settings.has('fullscreen')):
        if (settings.fullscreen == false):
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        else:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

    if (settings.has('crtShader')):
        if (settings.crtShader == false && crt.get_parent() != null):
            self.remove_child(crt)
            print("DISABLING CRT")
        elif (settings.crtShader == true && crt.get_parent() == null):
            self.add_child(crt)
            print("ENABLING CRT")

    if (settings.has("fgColor")):

        color.r8 = settings.fgColor[0];
        color.g8 = settings.fgColor[1];
        color.b8 = settings.fgColor[2];
        for i in HEIGHT:
            lines[i].modulate = color;
    
    if (settings.has("bgColor")):
        var bgColor: Color;
        bgColor.r8 = settings.bgColor[0];
        bgColor.g8 = settings.bgColor[1];
        bgColor.b8 = settings.bgColor[2];
        bg.color = bgColor;



# Called every frame. 'delta' is the elapsed time since the previous frame.
