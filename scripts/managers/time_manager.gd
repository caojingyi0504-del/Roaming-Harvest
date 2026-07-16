extends Node

signal minute_passed(day: int, hour: int, minute: int)
signal day_started(day: int)
signal time_scale_changed(scale: float)
signal phase_changed(phase: String)

@export var real_seconds_per_game_minute: float = 1.0

var day: int = 1
var hour: int = 6
var minute: int = 0
var time_scale: float = 1.0:
	set(value):
		time_scale = maxf(value, 0.0)
		time_scale_changed.emit(time_scale)

var paused: bool = false
var ui_paused: bool = false
var _accumulator := 0.0
var _last_phase := ""

func _ready() -> void:
	_last_phase = get_phase()

func _process(delta: float) -> void:
	if paused or ui_paused or time_scale <= 0.0:
		return
	_accumulator += delta * time_scale
	while _accumulator >= real_seconds_per_game_minute:
		_accumulator -= real_seconds_per_game_minute
		advance_minutes(1)

func advance_minutes(amount: int) -> void:
	for _i in range(maxi(amount, 0)):
		minute += 1
		if minute >= 60:
			minute = 0
			hour += 1
		if hour >= 24:
			hour = 0
			day += 1
			day_started.emit(day)
		minute_passed.emit(day, hour, minute)
		_emit_phase_if_changed()

func get_phase() -> String:
	if hour >= 5 and hour < 7:
		return "dawn"
	if hour >= 7 and hour < 17:
		return "day"
	if hour >= 17 and hour < 19:
		return "dusk"
	return "night"

func get_phase_display_name() -> String:
	return {"dawn": "黎明", "day": "白天", "dusk": "黄昏", "night": "夜晚"}.get(get_phase(), "白天")

func set_time(new_hour: int, new_minute: int = 0, new_day: int = -1) -> void:
	if new_day > 0:
		day = new_day
	hour = posmod(new_hour, 24)
	minute = clampi(new_minute, 0, 59)
	_accumulator = 0.0
	minute_passed.emit(day, hour, minute)
	_emit_phase_if_changed(true)

func _emit_phase_if_changed(force: bool = false) -> void:
	var phase := get_phase()
	if force or phase != _last_phase:
		_last_phase = phase
		phase_changed.emit(phase)

func get_time_snapshot() -> Dictionary:
	return {"day": day, "hour": hour, "minute": minute}

func apply_time_snapshot(snapshot: Dictionary) -> void:
	day = int(snapshot.get("day", day))
	hour = int(snapshot.get("hour", hour))
	minute = int(snapshot.get("minute", minute))
	_accumulator = 0.0
	_emit_phase_if_changed(true)
