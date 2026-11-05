extends Node
## Sound effects and music, all synthesized in code (autoload "Sfx").
## tone() and noise() build short WAV streams on the fly and cache them.

const RATE := 22050
const POOL := 12

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _loops := {}          # name -> AudioStreamPlayer for looping sounds
var _music: AudioStreamPlayer
var _music_key := ""
var _pending: Array = []  # delayed sounds: [time_left, callable]


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -14.0
	add_child(_music)


func _process(dt: float) -> void:
	var i := 0
	while i < _pending.size():
		_pending[i][0] -= dt
		if _pending[i][0] <= 0.0:
			var c: Callable = _pending[i][1]
			_pending.remove_at(i)
			c.call()
		else:
			i += 1


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


func _play(stream: AudioStream, vol: float, delay := 0.0) -> void:
	if delay > 0.0:
		_pending.append([delay, _play.bind(stream, vol, 0.0)])
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.volume_db = linear_to_db(clampf(vol, 0.0001, 2.0))
	p.play()


# ---------------------------------------------------------------- public sounds
## vol uses the same scale as the prototypes (0.03 to 0.1 is normal).
func tone(freq: float, dur: float, vol := 0.05, kind := "triangle", delay := 0.0) -> void:
	var key := "t%d_%d_%s" % [int(freq), int(dur * 100), kind]
	if not _cache.has(key):
		_cache[key] = _make_tone(freq, dur, kind)
	_play(_cache[key], vol * 7.0, delay)


func noise(dur: float, freq := 800.0, vol := 0.5, kind := "band", delay := 0.0) -> void:
	var key := "n%d_%d_%s" % [int(dur * 100), int(freq), kind]
	if not _cache.has(key):
		_cache[key] = _make_noise(dur, freq, kind)
	_play(_cache[key], vol * 0.9, delay)


func blip(speaker := "light") -> void:
	match speaker:
		"carl":
			tone(330, 0.05, 0.03)
		"lib":
			tone(250, 0.05, 0.03)
		_:
			tone(520, 0.05, 0.03)


func boom(scale := 1.0) -> void:
	noise(2.0 * scale, 500, 1.4 * scale, "low")
	tone(60, 1.5 * scale, 0.2 * scale, "sine")


func chime() -> void:
	for i in 4:
		tone([523, 659, 784, 1046][i], 0.45, 0.06, "triangle", i * 0.12)


func whoosh() -> void:
	noise(1.2, 900, 0.5, "band")
	tone(180, 1.0, 0.03, "sine")


## Looping sounds (drill buzz, modem hiss). vol 0 stops it.
func loop(name: String, freq: float, kind: String, vol: float) -> void:
	if vol <= 0.0:
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
		add_child(p)
		_loops[name] = p
	if p.stream != _cache[key]:
		p.stream = _cache[key]
		p.play()
	elif not p.playing:
		p.play()
	p.volume_db = linear_to_db(vol)


func stop_loops() -> void:
	for p in _loops.values():
		p.stop()


# ---------------------------------------------------------------- music
## A soft looping pad per chapter: four slow chords, generated once.
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


func music_for(chapter: int) -> void:
	if not settings_music():
		_music.stop()
		_music_key = ""
		return
	var key := "m%d" % chapter
	if key == _music_key:
		return
	_music_key = key
	if not _cache.has(key):
		_cache[key] = _make_pad(MOODS.get(chapter, MOODS[0]))
	_music.stream = _cache[key]
	_music.play()


func settings_music() -> bool:
	return Game.settings.get("music", true)


func _make_pad(chords: Array) -> AudioStreamWAV:
	var per := 4.0
	var n := int(per * chords.size() * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var per_n := int(per * RATE)
	for i in n:
		var t := float(i) / RATE
		var ci := int(i / per_n)
		var local := float(i % per_n) / per_n
		var env := sin(local * PI)
		env = env * env * 0.9 + 0.1
		var v := 0.0
		var chord: Array = chords[ci]
		for j in chord.size():
			var f: float = chord[j]
			v += sin(TAU * f * t) * 0.5 + sin(TAU * f * 2.003 * t) * 0.12
		# a slow shimmer on top
		v += sin(TAU * chord[2] * 2.0 * t) * 0.05 * (0.5 + 0.5 * sin(t * 0.7))
		out[i] = v * env * 0.12
	return _to_stream(out, true)
