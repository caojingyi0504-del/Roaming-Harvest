extends Control

const FRAME_PATTERN := "res://movies/intro_frames/frame_%04d.jpg"
const NEXT_SCENE := "res://scenes/GrassWorld.tscn"

@export var frame_count: int = 120
@export var frame_rate: float = 8.0

@onready var image: TextureRect = $Image
@onready var audio: AudioStreamPlayer = $Audio

var _elapsed := 0.0
var _current_frame := -1
var _finished := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	audio.play()
	_show_frame(1)

func _process(delta: float) -> void:
	if _finished:
		return
	_elapsed += delta
	var frame := mini(int(_elapsed * frame_rate) + 1, frame_count)
	_show_frame(frame)
	if _elapsed >= float(frame_count) / frame_rate:
		_finish_intro()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_finish_intro()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_intro()
	if event is InputEventScreenTouch and event.pressed:
		_finish_intro()

func _show_frame(frame: int) -> void:
	if frame == _current_frame:
		return
	_current_frame = frame
	var texture := load(FRAME_PATTERN % frame) as Texture2D
	if texture != null:
		image.texture = texture

func _finish_intro() -> void:
	if _finished:
		return
	_finished = true
	audio.stop()
	get_tree().change_scene_to_file(NEXT_SCENE)
