extends Stage
## Start screen: "Enlighten Them". Play zooms straight into the light.

var stars: Array
var menu := "main"   # main, chapters, options, credits
var panel: Control
var hover_light := false


func setup() -> void:
	VW = 1280
	VH = 720
	fit_area = Rect2(0, 0, 1280, 720)
	stars = Art.make_stars(220, Rect2(0, 0, 1280, 720), 11)
	_build_menu()


func _clear_panel() -> void:
	if panel:
		panel.queue_free()
	panel = Control.new()
	panel.position = Vector2(0, 0)
	panel.size = Vector2(1280, 720)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)


func _btn(label: String, pos: Vector2, w: float, cb: Callable, fs := 22, enabled := true) -> Button:
	var b := button(label, pos, Vector2(w, 52), cb, fs)
	b.disabled = not enabled
	remove_child(b)
	panel.add_child(b)
	return b


func _build_menu() -> void:
	_clear_panel()
	match menu:
		"main":
			_btn("Play", Vector2(540, 430), 200, _play, 26)
			_btn("Chapters", Vector2(540, 494), 200, func(): _go("chapters"))
			_btn("Options", Vector2(540, 558), 200, func(): _go("options"))
			_btn("Credits", Vector2(540, 622), 200, func(): _go("credits"))
		"chapters":
			for i in range(1, Game.CHAPTERS.size()):
				var col := (i - 1) % 2
				var row := (i - 1) / 2
				var open := i <= Game.reached
				var label: String = ("%d. %s" % [i, Game.CHAPTERS[i].name]) if open else ("%d. ???" % i)
				_btn(label, Vector2(330 + col * 320, 250 + row * 64), 300, _jump.bind(i), 19, open)
			_btn("Back", Vector2(540, 590), 200, func(): _go("main"))
		"options":
			_toggle("Steady hands (no drill wobble)", "steady_hands", 0)
			_toggle("Relaxed timers", "relaxed", 1)
			_toggle("Mute all sound  (M)", "muted", 2)
			_volume("Volume", "vol_master", 3)
			_volume("Music", "vol_music", 4)
			_volume("Sound effects", "vol_sfx", 5)
			_btn("Reset progress" if not confirm_reset else "Really reset? Click again", Vector2(330, 610), 380, _reset, 18)
			_btn("Back", Vector2(730, 610), 220, func(): _go("main"))
		"credits":
			_btn("Back", Vector2(540, 600), 200, func(): _go("main"))


func _toggle(label: String, k: String, i: int) -> void:
	var on: bool = Game.settings.get(k, false)
	_btn(("☑  " if on else "☐  ") + label, Vector2(400, 250 + i * 58), 480, func():
		if k == "muted":
			Sfx.toggle_mute()
		else:
			Game.settings[k] = not Game.settings.get(k, false)
			Game.save_game()
		_build_menu(), 20)


## A volume row:  [ - ]  Music: 70%  [ + ]
func _volume(label: String, k: String, i: int) -> void:
	var y := 250 + i * 58
	var v := Sfx.vol(k)
	var mid := _btn("%s: %d%%" % [label, roundi(v * 100.0)] if v > 0.0 else "%s: off" % label, Vector2(470, y), 340, func(): pass, 20)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn("-", Vector2(400, y), 60, func():
		Sfx.set_vol(k, Sfx.vol(k) - 0.1)
		_build_menu(), 24, v > 0.0)
	_btn("+", Vector2(820, y), 60, func():
		Sfx.set_vol(k, Sfx.vol(k) + 0.1)
		_build_menu(), 24, v < 1.0)


var confirm_reset := false


func _reset() -> void:
	if not confirm_reset:
		confirm_reset = true
	else:
		confirm_reset = false
		Game.reset_progress()
		Sfx.tone(300, 0.2, 0.05)
	_build_menu()


func _go(m: String) -> void:
	confirm_reset = false
	menu = m
	_build_menu()


func _play() -> void:
	Sfx.tone(784, 0.2, 0.05)
	panel.visible = false
	Game.zoom_to(1, Vector2(640, 250), 1.8)


func _jump(i: int) -> void:
	Sfx.tone(784, 0.2, 0.05)
	panel.visible = false
	Game.zoom_to(i, Vector2(640, 250), 1.4)


func click(p: Vector2) -> void:
	if menu == "main" and p.distance_to(Vector2(640, 250)) < 70:
		_play()


func tick(_dt: float) -> void:
	hover_light = menu == "main" and mouse().distance_to(Vector2(640, 250)) < 70


func paint() -> void:
	Art.vgrad(self, Rect2(0, 0, 1280, 720), Color("0b0918"), Color("1a1230"))
	Art.draw_stars(self, stars, t)
	# a faint nebula
	Art.glow(self, Vector2(300, 520), 420, Color(0.45, 0.25, 0.7, 0.18))
	Art.glow(self, Vector2(1000, 200), 380, Color(0.2, 0.4, 0.8, 0.16))
	# the light, with planets orbiting it as a nod to chapter one
	var main_menu := menu == "main"
	var lp := Vector2(640, (250 if main_menu else 100) + sin(t * 1.4) * 6.0)
	var lr := 44.0 if main_menu else 26.0
	var cols := [Color("b9b3a9"), Color("e8c37a"), Color("3d8bd9"), Color("d0603a")]
	for front in [false, true]:
		if front:
			Art.glow(self, lp, lr * 6.0 + (30 if hover_light else 0), Color(1, 0.85, 0.5, 0.25))
			light(lp, lr, {"look": (mouse() - lp) / 200.0})
		for i in 4:
			var a := t * (0.6 - i * 0.1) + i * 1.7
			var r := (lr * 2.0 + i * lr * 0.6)
			if (sin(a) > 0) == front:
				draw_circle(lp + Vector2(cos(a) * r, sin(a) * r * 0.32), (5 + i) * lr / 44.0, cols[i])
	# Carl swims past if he exists
	if Game.carl_made:
		var cx := fmod(t * 60.0, 1700.0) - 200.0
		carl(Vector2(cx, 660 + sin(t * 2.0) * 6.0), 0.22, {"walk": 0.4})
	match menu:
		"main":
			Art.text(self, Vector2(640, 120), "Enlighten Them", 84, Color("ffe9a8"), 0, Art.serif(), 6, Color(0.1, 0.05, 0.15, 0.8))
			Art.text(self, Vector2(640, 168), "A comedy about paradigm shifts", 22, Color("c9c3db"), 0)
			if hover_light:
				Art.text(self, Vector2(640, 340), "Click the light.", 18, Color(1, 0.91, 0.66, 0.8 + 0.2 * sin(t * 4.0)), 0)
		"chapters":
			Art.text(self, Vector2(640, 200), "Chapters", 46, Color("ffe9a8"), 0, Art.serif())
		"options":
			Art.text(self, Vector2(640, 212), "Options", 46, Color("ffe9a8"), 0, Art.serif())
		"credits":
			Art.text(self, Vector2(640, 370), "Credits", 46, Color("ffe9a8"), 0, Art.serif())
			var lines := [
				"Story, puzzles and jokes: CALL911imonfire",
				"Code, code-drawn graphics, synthesized sound and some dialogue written with Claude.",
				"No image-generation AI was used. Every shape is drawn by code.",
				"Music and sound effects are generated by code as the game runs. No audio files or samples.",
				"Made in Godot for GitHub Game Off 2026. Theme: SHIFT.",
			]
			for i in lines.size():
				Art.text(self, Vector2(640, 420 + i * 34), lines[i], 20, Color("e8e2f5"), 0)
