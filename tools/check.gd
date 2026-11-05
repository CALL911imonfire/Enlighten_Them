extends SceneTree
## Developer tool: loads every script so parse errors show up in one run.
##   godot --headless -s res://tools/check.gd

func _init() -> void:
	var dirs := ["res://scripts/core", "res://scripts/scenes"]
	var bad := 0
	for d in dirs:
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				var s = load(d + "/" + f)
				if s == null or not s.can_instantiate():
					print("FAILED: ", d, "/", f)
					bad += 1
				else:
					print("ok: ", f)
	print("done, failures: ", bad)
	quit()
