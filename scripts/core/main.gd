extends Node2D
## Root of the game. Holds the world (the active chapter) and the snapshot layer
## used for the seamless zoom between chapters. Esc opens a small pause menu.

var _pause: CanvasLayer


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.027, 0.024, 0.051))
	process_mode = Node.PROCESS_MODE_ALWAYS
	var world := Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	var flayer := CanvasLayer.new()
	flayer.layer = 5
	add_child(flayer)
	var feather: Node2D = load("res://scripts/core/feather.gd").new()
	feather.visible = false
	flayer.add_child(feather)
	Game.feather = feather
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var snap := Sprite2D.new()
	snap.visible = false
	layer.add_child(snap)
	Game.main = self
	Game.world = world
	Game.snap = snap
	_build_pause()
	var arg := _chapter_from_args()
	if "--autotest" in OS.get_cmdline_user_args():
		Game.autotest = true
		var driver: Node = load("res://tools/autotest.gd").new()
		add_child(driver)
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--peek="):
			add_child(load("res://tools/peek.gd").new())
	Game.start(arg)


func _chapter_from_args() -> int:
	# "--chapter=N" on the command line jumps straight to a chapter (handy for testing).
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if str(a).begins_with("--chapter="):
			return clampi(int(str(a).substr(10)), 0, Game.CHAPTERS.size() - 1)
	return 0


func _build_pause() -> void:
	_pause = CanvasLayer.new()
	_pause.layer = 30
	_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause.visible = false
	add_child(_pause)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.8)
	dim.size = Vector2(1280, 720)
	_pause.add_child(dim)
	var title := Label.new()
	title.text = "Paused"
	title.add_theme_font_override("font", Art.serif())
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("ffe9a8"))
	title.position = Vector2(0, 170)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause.add_child(title)
	var items := [
		["Resume", func(): _toggle_pause()],
		["Restart this chapter", func():
			_toggle_pause()
			Dialog.clear()
			Game.start(Game.current)],
		["Back to title", func():
			_toggle_pause()
			Dialog.clear()
			Game.start(0)],
		["", func():
			Sfx.toggle_mute()
			_mute_btn.text = _mute_label()],
	]
	for i in items.size():
		var b := Button.new()
		b.text = items[i][0]
		b.position = Vector2(490, 260 + i * 70)
		b.size = Vector2(300, 54)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(Sfx.click)
		b.pressed.connect(items[i][1])
		_pause.add_child(b)
		_mute_btn = b
	_mute_btn.text = _mute_label()
	var tip := Label.new()
	tip.text = "Volume settings are under Options on the title screen."
	tip.position = Vector2(0, 560)
	tip.size = Vector2(1280, 30)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", 16)
	tip.add_theme_color_override("font_color", Color(0.9, 0.88, 0.96, 0.6))
	_pause.add_child(tip)


var _mute_btn: Button


func _mute_label() -> String:
	return "Sound: off  (M)" if Sfx.muted() else "Sound: on  (M)"


func _toggle_pause() -> void:
	_pause.visible = not _pause.visible
	_mute_btn.text = _mute_label()
	get_tree().paused = _pause.visible


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if Game.current != 0 and not Game.transitioning:
			_toggle_pause()
			get_viewport().set_input_as_handled()
