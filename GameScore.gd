extends Node

signal initialized
signal rewarded(success)

var _cb_rewarded = JavaScript.create_callback(self, "_rewarded")
var _cb_logged = JavaScript.create_callback(self, "_logged")

var _gs

func _ready() -> void:
	if OS.has_feature("JavaScript"):
		_gs = JavaScript.get_interface("_gameScore")
		while _gs == null:
			yield(get_tree().create_timer(1), "timeout")
			_gs = JavaScript.get_interface("_gameScore")
		_gs.ads.on('rewarded:close', _cb_rewarded);
		if _gs.player.isLoggedIn:
			emit_signal("initialized")
		else:
			_gs.player.login().finally(emit_signal("initialized"))


func show_rewarded_video() -> void:
	if _gs == null: return
	_gs.ads.showRewardedVideo()

func add_field(key: String, value) -> void:
	if _gs == null: return
	_gs.player.add(key, value)
	_gs.player.sync()

func get_field(key: String):
	if _gs == null: return
	return _gs.player.get(key)

func set_field(key: String, value) -> void:
	if _gs == null: return
	_gs.player.set(key, value)
	_gs.player.sync()

func get_lang() -> String:
	if _gs == null: return "en"
	return _gs.language

func _rewarded(args) -> void:
	emit_signal("rewarded", bool(args[0]))
