extends SceneTree
## Developer tool: renders each speaker's ding voice typing a sample line to WAV,
## with the same timing as the dialogue box, and prints peak levels.
##   godot --headless -s res://tools/render_voices.gd -- --out=C:/some/folder
const LINE := "Hello there. This is how I sound when I talk to you."
const CPS := 46.0


func _init() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var s = load("res://scripts/core/sfx.gd").new()
	for sp in s.VOICES.keys():
		var v: Dictionary = s.VOICES[sp]
		var rate: int = s.RATE
		var mix := PackedFloat32Array()
		mix.resize(int((LINE.length() / CPS + 1.5) * rate))
		var hits: Array = [[0.0, 0, 1.15]]
		var every: int = v.every
		for c in LINE.length():
			if c % every == every - 1 and LINE[c] != " ":
				hits.append([(c + 1) / CPS, LINE[c].to_lower().hash(), 1.0])
		for h in hits:
			var notes: Array = v.notes
			var semi: int = notes[posmod(h[1], notes.size())]
			var w: AudioStreamWAV = s._make_ding(v.root * pow(2.0, semi / 12.0), v)
			var start := int(h[0] * rate)
			var gain: float = v.vol * h[2]
			for i in range(0, w.data.size(), 2):
				var j: int = start + i / 2
				if j < mix.size():
					mix[j] += w.data.decode_s16(i) / 32767.0 * gain
		var peak := 0.0
		for x in mix:
			peak = maxf(peak, absf(x))
		print("%s: %d dings, peak %.2f" % [sp, hits.size(), peak])
		if out != "":
			var w2: AudioStreamWAV = s._to_stream(mix)
			w2.save_to_wav("%s/voice_%s.wav" % [out, sp])
	s.free()
	quit()
