extends SceneTree
## Developer tool: renders every chapter's music to WAV files and prints peak levels.
##   godot --headless -s res://tools/render_music.gd -- --out=C:/some/folder
func _init() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var s = load("res://scripts/core/sfx.gd").new()
	for ch in 11:
		var b: PackedByteArray = s._compose(ch)
		var peak := 0
		var clip := 0
		for i in range(0, b.size(), 2):
			var v := absi(b.decode_s16(i))
			peak = maxi(peak, v)
			if v >= 32767:
				clip += 1
		print("ch %d: %.1fs, peak %.2f, clipped %d" % [ch, b.size() / 44100.0, peak / 32767.0, clip])
		if out != "":
			var w := AudioStreamWAV.new()
			w.format = AudioStreamWAV.FORMAT_16_BITS
			w.mix_rate = 22050
			w.data = b
			w.save_to_wav("%s/music_ch%02d.wav" % [out, ch])
	s.free()
	quit()
