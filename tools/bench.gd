extends Node
## Developer tool: measures how long each frame takes in every chapter.
##   godot -- --bench
## Visits each chapter, waits for it to settle, then times 120 frames with vsync off
## and prints the average and worst frame and the GDScript process time.

var ch := 0
var t := 0.0
var frames: Array[float] = []
var proc: Array[float] = []
var last := 0


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	Game.start(0)


func _process(dt: float) -> void:
	if Game.transitioning:
		return
	Dialog.clear()
	t += dt
	var now := Time.get_ticks_usec()
	if t > 2.5 and frames.is_empty():
		Game.tick_us = 0
		Game.paint_us = 0
		Game.prof.clear()
	if t > 2.5:
		frames.append((now - last) / 1000.0)
		proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	last = now
	if frames.size() >= 120:
		var s := 0.0
		var worst := 0.0
		for f in frames:
			s += f
			worst = maxf(worst, f)
		var p := 0.0
		for x in proc:
			p += x
		var n := float(frames.size())
		print("ch %2d %-22s frame avg %5.2f ms  worst %5.2f ms  tick %5.2f ms  paint %5.2f ms" % [ch, Game.CHAPTERS[ch].name, s / n, worst,
			Game.tick_us / n / 1000.0, Game.paint_us / n / 1000.0])
		var ks: Array = Game.prof.keys()
		ks.sort_custom(func(a, b): return Game.prof[a] > Game.prof[b])
		var line := "     "
		for k in ks:
			line += " %s %.2f" % [k, Game.prof[k] / n / 1000.0]
		print(line)
		frames.clear()
		proc.clear()
		t = 0.0
		ch += 1
		if ch >= Game.CHAPTERS.size():
			get_tree().quit()
			return
		Game.start(ch)
