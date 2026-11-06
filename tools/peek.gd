extends Node
## Developer screenshot helper (not used by the game).
##   godot -- --chapter=2 --peek=C:/tmp/out.png --wait=2 --set="phase=\"pump\";shown=0.0" --nodialog
## Starts a chapter, forces the given variables every frame, then saves one screenshot and quits.

var out := ""
var wait := 2.0
var sets := {}
var nodialog := false
var t := 0.0
var done := false
var crop := Rect2i()
var calls: Array = []
var called := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--peek="):
			out = a.substr(7)
		elif a.begins_with("--wait="):
			wait = float(a.substr(7))
		elif a.begins_with("--set="):
			for kv in a.substr(6).split(";", false):
				var i := kv.find("=")
				sets[kv.substr(0, i)] = str_to_var(kv.substr(i + 1))
		elif a.begins_with("--crop="):
			var v := a.substr(7).split(",")
			crop = Rect2i(int(v[0]), int(v[1]), int(v[2]), int(v[3]))
		elif a.begins_with("--call="):
			calls = Array(a.substr(7).split(","))
		elif a == "--nodialog":
			nodialog = true


func _process(dt: float) -> void:
	t += dt
	var s = Game.scene
	if s and not Game.transitioning:
		for k in sets:
			s.set(k, sets[k])
		if nodialog:
			Dialog.clear()
	if s and t > wait * 0.5 and not called:
		called = true
		for c in calls:
			s.call(c)
	if t > wait and not done:
		done = true
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		if crop.size.x > 0:
			img = img.get_region(crop)
			img.resize(crop.size.x * 4, crop.size.y * 4, Image.INTERPOLATE_NEAREST)
		img.save_png(out)
		get_tree().quit()
