extends Node
## Sound effects and music, all synthesized in code (autoload "Sfx").
## tone() and noise() build short WAV streams on the fly and cache them.
## Music is composed per chapter from chords, bass, arpeggios and soft drums,
## rendered on a worker thread, and crossfaded between chapters.
## Volume runs through three buses (Master, Music, SFX); M mutes everything.

const RATE := 22050
const POOL := 12

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _loops := {}          # name -> AudioStreamPlayer for looping sounds
var _pending: Array = []  # delayed sounds: [time_left, callable]

var _music: AudioStreamPlayer       # the track playing now
var _music_old: AudioStreamPlayer   # the track fading out
var _music_key := ""
var _want_music := -1               # chapter whose music should be playing
var _rendering := -1                # chapter being rendered on the worker thread
var _render_queue: Array[int] = []
var _task := -1
var _abort := false                 # set when the game quits mid-render
var _bus_music := 0
var _bus_sfx := 0
var _toast: Label
var _toast_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bus_music = _make_bus("Music")
	_bus_sfx = _make_bus("SFX")
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = _new_music_player()
	_music_old = _new_music_player()
	# older saves had a plain "music" on/off switch
	if Game.settings.has("music"):
		if not Game.settings.music:
			Game.settings["vol_music"] = 0.0
		Game.settings.erase("music")
	apply_volume()
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_toast = Label.new()
	_toast.position = Vector2(980, 14)
	_toast.size = Vector2(284, 30)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_theme_font_size_override("font_size", 18)
	_toast.add_theme_color_override("font_color", Color("ffe9a8"))
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_toast.add_theme_constant_override("outline_size", 5)
	_toast.modulate.a = 0.0
	layer.add_child(_toast)
	whoosh(false)  # build the transition sound now so the first zoom doesn't stutter


func _make_bus(bus_name: String) -> int:
	var i := AudioServer.get_bus_index(bus_name)
	if i == -1:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, "Master")
	return i


func _new_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	p.volume_db = -80.0
	add_child(p)
	return p


func _process(dt: float) -> void:
	_toast_t = maxf(0.0, _toast_t - dt)
	_toast.modulate.a = clampf(_toast_t * 2.0, 0.0, 1.0)
	_fade_music(dt)
	var i := 0
	while i < _pending.size():
		_pending[i][0] -= dt
		if _pending[i][0] <= 0.0:
			var c: Callable = _pending[i][1]
			_pending.remove_at(i)
			c.call()
		else:
			i += 1


# ---------------------------------------------------------------- volume
## Settings: vol_master, vol_music, vol_sfx (0..1) and muted.
func vol(k: String) -> float:
	var d := 0.7 if k == "vol_music" else 0.8
	return clampf(float(Game.settings.get(k, d)), 0.0, 1.0)


func set_vol(k: String, v: float) -> void:
	Game.settings[k] = snappedf(clampf(v, 0.0, 1.0), 0.1)
	if Game.settings[k] > 0.0 and muted():
		Game.settings["muted"] = false
	apply_volume()
	Game.save_game()


func muted() -> bool:
	return Game.settings.get("muted", false)


func toggle_mute() -> void:
	Game.settings["muted"] = not muted()
	apply_volume()
	Game.save_game()
	_show_toast("Sound off  (M)" if muted() else "Sound on  (M)")
	if not muted():
		click()


func apply_volume() -> void:
	var pairs := [[0, "vol_master"], [_bus_music, "vol_music"], [_bus_sfx, "vol_sfx"]]
	for pr in pairs:
		var v := vol(pr[1])
		AudioServer.set_bus_volume_db(pr[0], linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(pr[0], v <= 0.0)
	if muted():
		AudioServer.set_bus_mute(0, true)


func _show_toast(s: String) -> void:
	_toast.text = s
	_toast_t = 1.6


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		toggle_mute()


# ---------------------------------------------------------------- synthesis
func _wave(kind: String, ph: float) -> float:
	match kind:
		"square":
			return 1.0 if fmod(ph, 1.0) < 0.5 else -1.0
		"sawtooth":
			return 2.0 * fmod(ph, 1.0) - 1.0
		"triangle":
			var x := fmod(ph, 1.0)
			return 4.0 * absf(x - 0.5) - 1.0
		_:
			return sin(ph * TAU)


func _to_stream(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s


func _make_tone(freq: float, dur: float, kind: String) -> AudioStreamWAV:
	var n := int((dur + 0.03) * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := minf(1.0, t / 0.01) * exp(-4.5 * t / maxf(dur, 0.02))
		if t > dur:
			env *= maxf(0.0, 1.0 - (t - dur) / 0.03)
		out[i] = _wave(kind, freq * t) * env
	return _to_stream(out)


## kind: "band", "low", "high". freq picks the colour of the noise.
func _make_noise(dur: float, freq: float, kind: String) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var a := clampf(freq / RATE * TAU, 0.001, 0.99)
	var lp := 0.0
	var lp2 := 0.0
	for i in n:
		var w := randf() * 2.0 - 1.0
		lp += a * (w - lp)
		lp2 += a * (lp - lp2)
		var v := 0.0
		match kind:
			"low":
				v = lp2 * 2.2
			"high":
				v = (w - lp) * 0.8
			_:
				v = (lp - lp2) * 3.0
		var k := float(i) / n
		out[i] = v * pow(1.0 - k, 2.0) * minf(1.0, k * 60.0)
	return _to_stream(out)


func _play(stream: AudioStream, v: float, delay := 0.0) -> void:
	if delay > 0.0:
		_pending.append([delay, _play.bind(stream, v, 0.0)])
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.volume_db = linear_to_db(clampf(v, 0.0001, 2.0))
	p.play()


# ---------------------------------------------------------------- public sounds
## vol uses the same scale as the prototypes (0.03 to 0.1 is normal).
func tone(freq: float, dur: float, v := 0.05, kind := "triangle", delay := 0.0) -> void:
	var key := "t%d_%d_%s" % [int(freq), int(dur * 100), kind]
	if not _cache.has(key):
		_cache[key] = _make_tone(freq, dur, kind)
	_play(_cache[key], v * 7.0, delay)


func noise(dur: float, freq := 800.0, v := 0.5, kind := "band", delay := 0.0) -> void:
	var key := "n%d_%d_%s" % [int(dur * 100), int(freq), kind]
	if not _cache.has(key):
		_cache[key] = _make_noise(dur, freq, kind)
	_play(_cache[key], v * 0.9, delay)


func _voice(speaker: String) -> float:
	match speaker:
		"carl":
			return 330.0
		"lib":
			return 250.0
	return 520.0


## The little sound when a new line of dialogue appears.
func blip(speaker := "light") -> void:
	tone(_voice(speaker), 0.05, 0.03)


## A soft typing tick while dialogue writes itself out; the pitch wobbles with the letter.
func type_blip(speaker: String, ch: String) -> void:
	var steps := [1.0, 1.122, 0.891, 1.26]
	var f: float = _voice(speaker) * steps[ch.unicode_at(0) % steps.size()]
	var kind := "square" if speaker == "carl" else ("sawtooth" if speaker == "lib" else "triangle")
	var key := "b%d_%s" % [int(f), kind]
	if not _cache.has(key):
		_cache[key] = _make_tone(f, 0.035, kind)
	_play(_cache[key], 0.07 if kind == "triangle" else 0.035)


## Button press.
func click() -> void:
	tone(1250, 0.025, 0.03, "square")
	noise(0.03, 3000, 0.25, "high")


func boom(scale := 1.0) -> void:
	noise(2.0 * scale, 500, 1.4 * scale, "low")
	tone(60, 1.5 * scale, 0.2 * scale, "sine")


## Puzzle solved: a bright rising arpeggio with a sparkle on top.
func chime() -> void:
	var notes := [523.3, 659.3, 784.0, 1046.5, 1318.5]
	for i in notes.size():
		tone(notes[i], 0.5, 0.055, "triangle", i * 0.08)
	tone(130.8, 0.9, 0.08, "sine")
	tone(196.0, 0.9, 0.05, "sine", 0.32)
	var sparkle := [2093.0, 2637.0, 3136.0, 2637.0]
	for i in sparkle.size():
		tone(sparkle[i], 0.18, 0.018, "sine", 0.42 + i * 0.07)


func solved() -> void:
	chime()


## Chapter transition: rushing air and a rising tone as the camera zooms in.
func whoosh(play := true) -> void:
	var key := "whoosh"
	if not _cache.has(key):
		var dur := 1.6
		var n := int(dur * RATE)
		var out := PackedFloat32Array()
		out.resize(n)
		var lp := 0.0
		var ph := 0.0
		for i in n:
			var k := float(i) / n
			var env := sin(k * PI) * sin(k * PI)
			lp += lerpf(0.02, 0.35, k) * ((randf() * 2.0 - 1.0) - lp)
			ph += lerpf(140.0, 620.0, k * k) / RATE
			out[i] = lp * env * 1.2 + sin(ph * TAU) * env * 0.16
		_cache[key] = _to_stream(out)
	if play:
		_play(_cache[key], 0.6)


## Looping sounds (drill buzz, modem hiss). vol 0 stops it.
func loop(name: String, freq: float, kind: String, v: float) -> void:
	if v <= 0.0:
		if _loops.has(name):
			_loops[name].stop()
		return
	var key := "loop_%s_%d_%s" % [name, int(freq), kind]
	if not _cache.has(key):
		var n := int(RATE * 0.5)
		var out := PackedFloat32Array()
		out.resize(n)
		var f := roundf(freq * 0.5) / 0.5
		for i in n:
			var t := float(i) / RATE
			if kind == "hiss":
				out[i] = (randf() * 2.0 - 1.0) * 0.5
			else:
				out[i] = _wave(kind, f * t) * 0.8
		_cache[key] = _to_stream(out, true)
	var p: AudioStreamPlayer
	if _loops.has(name):
		p = _loops[name]
	else:
		p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_loops[name] = p
	if p.stream != _cache[key]:
		p.stream = _cache[key]
		p.play()
	elif not p.playing:
		p.play()
	p.volume_db = linear_to_db(v)


func stop_loops() -> void:
	for p in _loops.values():
		p.stop()


# ---------------------------------------------------------------- music
## Four chords per chapter (one bar each). The loop plays them twice, the second
## time with the melody an octave up.
const MOODS := {
	0: [[261.6, 329.6, 392.0], [220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7]],
	1: [[130.8, 196.0, 261.6], [116.5, 174.6, 233.1], [103.8, 155.6, 207.7], [116.5, 174.6, 233.1]],
	2: [[146.8, 220.0, 293.7], [130.8, 196.0, 261.6], [116.5, 174.6, 233.1], [130.8, 196.0, 261.6]],
	3: [[110.0, 164.8, 220.0], [98.0, 146.8, 196.0], [87.3, 130.8, 174.6], [98.0, 146.8, 196.0]],
	4: [[196.0, 246.9, 329.6], [174.6, 220.0, 293.7], [164.8, 207.7, 261.6], [174.6, 220.0, 293.7]],
	5: [[196.0, 246.9, 293.7], [220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7]],
	6: [[174.6, 220.0, 261.6], [164.8, 196.0, 246.9], [146.8, 174.6, 220.0], [164.8, 196.0, 246.9]],
	7: [[155.6, 196.0, 233.1], [138.6, 174.6, 207.7], [123.5, 155.6, 185.0], [138.6, 174.6, 207.7]],
	8: [[164.8, 207.7, 246.9], [146.8, 185.0, 220.0], [130.8, 164.8, 196.0], [146.8, 185.0, 220.0]],
	9: [[130.8, 164.8, 196.0], [146.8, 174.6, 220.0], [116.5, 146.8, 174.6], [130.8, 164.8, 196.0]],
	10: [[110.0, 130.8, 164.8], [98.0, 123.5, 146.8], [87.3, 110.0, 130.8], [82.4, 103.8, 123.5]],
}

## How each chapter's track is played.
## bpm; arp: which chord tone plays on each eighth note (-1 rest, 3 octave);
## lead: melody wave; drums: 0 none, 1 soft shaker, 2 kick and shaker.
const STYLES := {
	0: {"bpm": 66, "arp": [0, 1, 2, 3, 2, 1, -1, -1], "lead": "sine", "drums": 0},
	1: {"bpm": 58, "arp": [0, -1, 2, -1, 3, -1, 2, -1], "lead": "sine", "drums": 0},
	2: {"bpm": 92, "arp": [0, 2, 1, 2, 0, 2, 3, 2], "lead": "triangle", "drums": 1},
	3: {"bpm": 76, "arp": [0, -1, 1, 2, -1, 1, 3, -1], "lead": "triangle", "drums": 1},
	4: {"bpm": 96, "arp": [0, 1, 2, 1, 3, 2, 1, 2], "lead": "triangle", "drums": 2},
	5: {"bpm": 108, "arp": [0, 2, 3, 2, 1, 2, 3, 2], "lead": "square", "drums": 2},
	6: {"bpm": 84, "arp": [3, 2, 1, 0, 1, 2, -1, -1], "lead": "triangle", "drums": 1},
	7: {"bpm": 96, "arp": [0, 0, 2, 0, 3, 0, 2, 1], "lead": "square", "drums": 2},
	8: {"bpm": 112, "arp": [0, 3, 1, 3, 2, 3, 1, 3], "lead": "square", "drums": 2},
	9: {"bpm": 100, "arp": [0, 1, 2, 3, 0, 1, 2, 3], "lead": "sawtooth", "drums": 2},
	10: {"bpm": 54, "arp": [0, -1, -1, 2, -1, -1, 3, -1], "lead": "sine", "drums": 0},
}

const MUSIC_DB := -12.0


func music_for(chapter: int) -> void:
	_want_music = chapter
	if Game.autotest:
		return
	var key := "m%d" % chapter
	if key == _music_key:
		return
	if _cache.has(key):
		_start_track(key)
	else:
		_queue_render(chapter, true)


func settings_music() -> bool:
	return vol("vol_music") > 0.0


func _start_track(key: String) -> void:
	_music_key = key
	var tmp := _music_old
	_music_old = _music
	_music = tmp
	_music.stream = _cache[key]
	_music.volume_db = -60.0
	_music.play()


func _fade_music(dt: float) -> void:
	if _music.playing:
		_music.volume_db = minf(MUSIC_DB, _music.volume_db + dt * 30.0)
	if _music_old.playing:
		_music_old.volume_db -= dt * 30.0
		if _music_old.volume_db < -60.0:
			_music_old.stop()


func _queue_render(chapter: int, urgent := false) -> void:
	if _cache.has("m%d" % chapter) or chapter == _rendering:
		return
	_render_queue.erase(chapter)
	if urgent:
		_render_queue.push_front(chapter)
	else:
		_render_queue.append(chapter)
	_render_next()


func _render_next() -> void:
	if _rendering != -1 or _render_queue.is_empty():
		return
	_rendering = _render_queue.pop_front()
	var ch := _rendering
	_task = WorkerThreadPool.add_task(func():
		var bytes := _compose(ch)
		if not _abort:
			_track_done.call_deferred(ch, bytes))


func _exit_tree() -> void:
	_abort = true
	if _task != -1:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func _track_done(ch: int, bytes: PackedByteArray) -> void:
	if _abort:
		return
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = bytes
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = bytes.size() / 2
	_cache["m%d" % ch] = s
	_rendering = -1
	if ch == _want_music and _music_key != "m%d" % ch:
		_start_track("m%d" % ch)
	# get the next chapter's track ready before the player gets there
	var nxt := (ch + 1) % MOODS.size()
	if not _cache.has("m%d" % nxt) and nxt != _want_music:
		_queue_render(nxt)
	_render_next()


## Runs on a worker thread, so it only touches its own arrays.
func _compose(ch: int) -> PackedByteArray:
	var chords: Array = MOODS.get(ch, MOODS[0])
	var st: Dictionary = STYLES.get(ch, STYLES[0])
	var beat := 60.0 / float(st.bpm)
	var bar := beat * 4.0
	var bars := chords.size() * 2
	var n := int(bar * bars * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + ch
	# pad: the chord, swelling in and out over each bar
	var bar_n := bar * RATE
	for i in n:
		if i % 8192 == 0 and _abort:
			return PackedByteArray()
		var t := float(i) / RATE
		var bi := int(i / bar_n) % chords.size()
		var local := fmod(float(i), bar_n) / bar_n
		var env := sin(local * PI) * 0.8 + 0.2
		var chord: Array = chords[bi]
		var v := 0.0
		for f in chord:
			v += sin(TAU * f * t) * 0.5 + sin(TAU * f * 2.003 * t) * 0.1
		buf[i] = v * env * 0.07
	var lead: String = st.lead
	var arp: Array = st.arp
	var lead_vol := 0.12 if lead == "sine" else (0.09 if lead == "triangle" else 0.045)
	for b in bars:
		var chord: Array = chords[b % chords.size()]
		var t0 := b * bar
		var up := 2.0 if b >= chords.size() else 1.0
		# bass on beats one and three
		_note(buf, t0, chord[0] * 0.5, beat * 1.8, 0.22, "sine", 2.2)
		_note(buf, t0 + beat * 2.0, chord[0] * 0.5, beat * 1.5, 0.18, "sine", 2.5)
		if st.drums == 2:
			_note(buf, t0 + beat * 3.5, chord[1] * 0.5, beat * 0.5, 0.12, "triangle", 5.0)
		# melody: an arpeggio over the chord
		for e in 8:
			var idx: int = arp[e]
			if idx < 0:
				continue
			var f: float = chord[0] * 2.0 if idx == 3 else chord[idx]
			f *= up if ch == 10 else 2.0 * up
			var acc := 1.0 if e % 2 == 0 else 0.75
			_note(buf, t0 + e * beat * 0.5, f, beat * 0.9, lead_vol * acc, lead, 4.0)
		if st.drums >= 1:
			for e in 8:
				_hat(buf, t0 + e * beat * 0.5, 0.05 if e % 2 == 1 else 0.025, rng)
		if st.drums == 2:
			_kick(buf, t0)
			_kick(buf, t0 + beat * 2.0)
			_hat(buf, t0 + beat, 0.08, rng, 0.12)
			_hat(buf, t0 + beat * 3.0, 0.08, rng, 0.12)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i] * 1.3, -1.0, 1.0) * 32767.0))
	return bytes


## Adds one note into the loop buffer. Tails wrap around so the loop is seamless.
func _note(buf: PackedFloat32Array, start: float, freq: float, dur: float, v: float, kind: String, decay: float) -> void:
	var n := buf.size()
	var s0 := int(start * RATE)
	for j in int((dur + 0.05) * RATE):
		var t := float(j) / RATE
		var env := minf(1.0, t / 0.006) * exp(-decay * t / dur)
		if t > dur:
			env *= maxf(0.0, 1.0 - (t - dur) / 0.05)
		buf[(s0 + j) % n] += _wave(kind, freq * t) * env * v


func _kick(buf: PackedFloat32Array, start: float) -> void:
	var n := buf.size()
	var s0 := int(start * RATE)
	var ph := 0.0
	for j in int(0.22 * RATE):
		var t := float(j) / RATE
		ph += lerpf(120.0, 45.0, minf(1.0, t / 0.12)) / RATE
		buf[(s0 + j) % n] += sin(ph * TAU) * exp(-t * 18.0) * 0.32


func _hat(buf: PackedFloat32Array, start: float, v: float, rng: RandomNumberGenerator, dur := 0.04) -> void:
	var n := buf.size()
	var s0 := int(start * RATE)
	var lp := 0.0
	for j in int(dur * RATE):
		var t := float(j) / RATE
		var w := rng.randf() * 2.0 - 1.0
		lp += 0.5 * (w - lp)
		buf[(s0 + j) % n] += (w - lp) * exp(-t * 4.0 / dur) * v
