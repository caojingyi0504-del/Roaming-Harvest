extends Node

signal minute_passed(day: int, hour: int, minute: int)
signal day_started(day: int)
signal time_scale_changed(scale: float)

@export var real_seconds_per_game_minute: float = 1.0

var day: int = 1
var hour: int = 6
var minute: int = 0
var time_scale: float = 1.0:
	set(value):
		time_scale = maxf(value, 0.0)
		time_scale_changed.emit(time_scale)

var paused: bool = false
var _accumulator := 0.0

func _process(delta: float) -> void:
	if paused or time_scale <= 0.0:
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

func get_time_snapshot() -> Dictionary:
	return {"day": day, "hour": hour, "minute": minute}

func apply_time_snapshot(snapshot: Dictionary) -> void:
	day = int(snapshot.get("day", day))
	hour = int(snapshot.get("hour", hour))
	minute = int(snapshot.get("minute", minute))
