extends Node
## Global game state (autoload "Game").
## Holds Carl's player-made appearance so every scene draws the same Carl,
## the chapter order, settings, saving, and the seamless zoom transition.

const SAVE_PATH := "user://enlighten_them.save"

## Chapters in story order. Each one zooms into the next.
const CHAPTERS := [
	{"name": "Title", "path": "res://scripts/scenes/title.gd"},
	{"name": "Let There Be Light", "path": "res://scripts/scenes/orbits.gd"},
	{"name": "Pump It Round", "path": "res://scripts/scenes/pump.gd"},
	{"name": "Break Up Pangaea", "path": "res://scripts/scenes/pangaea.gd"},
	{"name": "Make Carl", "path": "res://scripts/scenes/make_carl.gd"},
	{"name": "Road to the Library", "path": "res://scripts/scenes/road.gd"},
	{"name": "Sort the Library", "path": "res://scripts/scenes/library.gd"},
	{"name": "Be Kind, Rewind", "path": "res://scripts/scenes/vcr.gd"},
	{"name": "Dial It Up", "path": "res://scripts/scenes/dialup.gd"},
	{"name": "Power Hungry", "path": "res://scripts/scenes/power.gd"},
	{"name": "The Last Question", "path": "res://scripts/scenes/last_question.gd"},
]

## Carl's look. Filled in by Make Carl, saved to disk, and read by every later scene.
## Each part: {type, x, y (face parts) or a (edge parts, radians), size, ph}
var carl := {}
var carl_made := false

var settings := {"steady_hands": false, "relaxed": false, "music": true}
var reached := 1          # furthest chapter unlocked
var current := 0
var transitioning := false
var autotest := false     # developer self-test: dialogue advances by itself

var main: Node = null      # set by main.gd
var world: Node2D = null   # parent of the active scene
var snap: Sprite2D = null  # screenshot used for the zoom transition
var feather: Node2D = null # soft edge around the growing chapter
var scene: Node = null


func _ready() -> void:
	carl = default_carl()
	load_game()


# ---------------------------------------------------------------- Carl
func default_carl() -> Dictionary:
	return {
		"color": Color("ff9f43"),
		"parts": [
			{"type": "eye", "x": 58.0, "y": -18.0, "size": 1.0, "ph": 0.3},
			{"type": "mouth", "x": 92.0, "y": 16.0, "size": 1.0, "ph": 1.1},
			{"type": "ear", "a": deg_to_rad(-75.0), "size": 1.0, "ph": 2.0},
			{"type": "leg", "a": deg_to_rad(75.0), "size": 1.0, "ph": 0.0},
			{"type": "leg", "a": deg_to_rad(105.0), "size": 1.0, "ph": 3.1},
		],
	}


func carl_count(type: String) -> int:
	var n := 0
	for p in carl.get("parts", []):
		if p.type == type:
			n += 1
	return n


func set_carl(color: Color, parts: Array) -> void:
	var copy := []
	for p in parts:
		var d := {}
		for k in p.keys():
			if k in ["type", "x", "y", "a", "size", "ph"]:
				d[k] = p[k]
		copy.append(d)
	carl = {"color": color, "parts": copy}
	carl_made = true
	save_game()


# ---------------------------------------------------------------- saving
func save_game() -> void:
	if autotest:
		return
	var parts := []
	for p in carl.parts:
		var d: Dictionary = p.duplicate()
		parts.append(d)
	var data := {
		"reached": reached,
		"settings": settings,
		"carl_made": carl_made,
		"carl_color": carl.color.to_html(),
		"carl_parts": parts,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> void:
	if "--autotest" in OS.get_cmdline_user_args():
		return
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	reached = int(data.get("reached", 1))
	var s = data.get("settings", {})
	if typeof(s) == TYPE_DICTIONARY:
		for k in s.keys():
			settings[k] = s[k]
	if data.get("carl_made", false):
		var parts = data.get("carl_parts", [])
		if typeof(parts) == TYPE_ARRAY and parts.size() > 0:
			carl = {"color": Color.html(str(data.get("carl_color", "ff9f43"))), "parts": parts}
			carl_made = true


# ---------------------------------------------------------------- scenes
func reset_progress() -> void:
	reached = 1
	carl = default_carl()
	carl_made = false
	save_game()


func make_scene(index: int) -> Node:
	var script: Script = load(CHAPTERS[index].path)
	var node: Node = script.new()
	node.name = "Chapter%d" % index
	return node


## Start a chapter instantly (used at boot and by the chapter menu).
func start(index: int) -> void:
	current = index
	if scene:
		scene.queue_free()
	scene = make_scene(index)
	world.position = Vector2.ZERO
	world.scale = Vector2.ONE
	world.add_child(scene)
	Sfx.music_for(index)
	if scene.has_method("begin"):
		scene.call_deferred("begin")


## Seamless zoom: the old scene keeps zooming into `focus` (screen coords) while
## the next chapter grows out of that same point.
func next_chapter(focus: Vector2 = Vector2(640, 300)) -> void:
	var idx := current + 1
	if idx >= CHAPTERS.size():
		idx = 0
	zoom_to(idx, focus)


func zoom_to(index: int, focus: Vector2 = Vector2(640, 300), duration := 1.6) -> void:
	if transitioning:
		return
	transitioning = true
	Dialog.clear()
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var px := Vector2.ONE
	if img and not img.is_empty():
		px = Vector2(img.get_width() / 1280.0, img.get_height() / 720.0)
		snap.texture = ImageTexture.create_from_image(img)
	else:
		snap.texture = null
	snap.centered = false
	snap.offset = -focus * px
	snap.position = focus
	snap.scale = Vector2.ONE / px
	snap.modulate = Color(1, 1, 1, 1)
	snap.visible = true

	current = index
	if index > reached:
		reached = index
		save_game()
	if scene:
		scene.queue_free()
	scene = make_scene(index)
	world.add_child(scene)
	Sfx.music_for(index)
	Sfx.whoosh()

	var tw := create_tween()
	tw.tween_method(_zoom_step.bind(focus, px), 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	snap.visible = false
	snap.texture = null
	if feather:
		feather.show_rect(Rect2(0, 0, 1280, 720), 0.0)
	world.position = Vector2.ZERO
	world.scale = Vector2.ONE
	transitioning = false
	if scene and scene.has_method("begin"):
		scene.begin()


func _zoom_step(k: float, focus: Vector2, px: Vector2) -> void:
	# old picture: rushes towards the viewer and fades
	var s_old := pow(14.0, k)
	snap.scale = Vector2.ONE / px * s_old
	snap.modulate.a = clampf(1.0 - k * 1.35, 0.0, 1.0)
	# new chapter: starts as a tiny dot at the focus and grows to full size
	var s_new := lerpf(0.06, 1.0, k * k * (3.0 - 2.0 * k))
	world.scale = Vector2(s_new, s_new)
	world.position = focus * (1.0 - s_new)
	if feather:
		var fade := 1.0 - smoothstep(0.8, 1.0, k)
		feather.show_rect(Rect2(world.position, Vector2(1280, 720) * s_new), fade)
