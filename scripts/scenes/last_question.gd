extends Stage
## Chapter 10: The Last Question. Catch the last light of dying stars, the light
## retires to its recliner, and Carl becomes the new light. Then it all begins again.

const CARL_P := Vector2(300, 360)
const WAVES := [{"n": 10, "every": 1.5, "win": 2.6, "drain": 0.035}, {"n": 14, "every": 1.1, "win": 2.1, "drain": 0.045}, {"n": 16, "every": 0.8, "win": 1.7, "drain": 0.055}]
const WAVE_TALK := [
	["A few trillion years later...", "The stars are starting to go out. Even the big ones.", "CARL:Then we catch what light they have left. When a star swells up red, click it before it goes dark."],
	["CARL:I have a question. How can entropy be reversed?", "There is as yet insufficient data for a meaningful answer.", "CARL:You are quoting a book.", "It's a good book. Keep catching."],
	["CARL:I have absorbed all knowledge. Every library, every server, every star. How can entropy be reversed?", "...Still insufficient data, buddy.",
		"Hey, have I gotten dimmer? I feel dimmer.", "CARL:Focus. These are the last ones."],
]

var st := 0
var phase := "talk"
var said := {}
var stars: Array = []
var motes: Array = []
var energy := 0.7
var wave := 0
var dying := 0
var spawn_t := 0.0
var caught := 0
var lost := 0
var light_dim := 0.0
var dim_to := 0.0       # light_dim eases toward this so the light never pops
var glow_shown := 0.7   # Carl's drawn glow eases toward energy
var recline := 0.0
var low_n := 0
var morph := 0.0
var parts: Array = []
var bang := 0.0
var end_t := 0.0
var new_stars: Array


func setup() -> void:
	VW = 600
	VH = 600
	new_stars = Art.make_stars(200, Rect2(-300, -100, 1200, 800), 99)
	_make_stars()


func begin() -> void:
	_set_stage(0)


func _make_stars() -> void:
	stars.clear()
	while stars.size() < 44:
		var p := Vector2(30 + randf() * 540, 40 + randf() * 520)
		if p.distance_to(CARL_P) < 100 or (p.x < 120 and p.y < 120):
			continue
		stars.append({"p": p, "r": 1.5 + randf() * 2.5, "state": "alive", "k": 0.0, "tw": randf() * 7})


func _set_stage(i: int) -> void:
	st = i
	phase = "talk"
	motes.clear()
	match i:
		0:
			_make_stars()
			energy = 0.7
			wave = 0
			dying = 0
			spawn_t = 0
			light_dim = 0
			dim_to = 0
			glow_shown = energy
			recline = 0
			await Dialog.say(WAVE_TALK[0])
			phase = "play"
		1:
			for s in stars:
				s.state = "dead"
			energy = 1.0
			dim_to = 0.6
			await Dialog.say(["...", "That was the last one. Every star in the universe. Gone.",
				"CARL:And yet I am still glowing. I carry all of it now. Every photon we caught.",
				"And I'm... fading. Funny thing about being a light. When the stars go, so do I.", "!recline", "Ahh. Finally. My ethereal recliner.",
				"CARL:This is hardly the time to put your feet up.", "It's exactly the time. You'll take it from here, right?", "CARL:Take what, precisely?",
				"The job. The universe. All of it. You've got all the knowledge and all the power. And now, a sense of humor.", "CARL:I do not have a sense of hum...",
				"You laughed at the pun books.", "CARL:...They were statistically amusing.", "I used to have legs, you know. Long story.", "CARL:...What?",
				"Goodnight, Carl. Don't forget to put a little light in everything.", "!fade"], _cue)
			_set_stage(2)
		2:
			morph = 0
			parts.clear()
			end_t = 0
			light_dim = 1.0
			dim_to = 1.0
			recline = 1.0
			await Dialog.say(["CARL:...", "CARL:Alone. In the dark. With every answer except one.", "CARL:How can entropy be reversed?"])
			phase = "morph"
			morph = 0
			Sfx.tone(220, 3, 0.03, "sine")
			Sfx.tone(330, 3, 0.03, "sine", 1.0)
			Sfx.tone(440, 3, 0.03, "sine", 2.0)


func _cue(c: String) -> void:
	match c:
		"recline":
			recline = 0.01
			Sfx.tone(200, 0.4, 0.04, "sine")
		"fade":
			dim_to = 1.0
			Sfx.tone(330, 1.2, 0.04, "sine")
			Sfx.tone(220, 1.6, 0.04, "sine", 0.4)


# ---------------------------------------------------------------- stars
func _start_dying() -> void:
	var alive := stars.filter(func(s): return s.state == "alive")
	if alive.is_empty():
		return
	var s: Dictionary = alive.pick_random()
	s.state = "dying"
	s.k = 0.0
	dying += 1
	Sfx.tone(180, 0.3, 0.03, "sine")


func _catch(s: Dictionary) -> void:
	s.state = "caught"
	caught += 1
	Sfx.tone(660 + caught * 15, 0.12, 0.05)
	for i in 5:
		motes.append({"p": s.p, "v": Vector2(randf() - 0.5, randf() - 0.5) * 80, "f": 0.0, "done": false})
	if not said.has("c1"):
		said["c1"] = true
		Dialog.say(["CARL:Delicious. Ancient starlight. Notes of hydrogen."])


func _star_died(s: Dictionary) -> void:
	s.state = "dead"
	lost += 1
	Sfx.noise(0.15, 400, 0.2)
	if lost == 3 and not said.has("l3") and phase == "play":
		said["l3"] = true
		Dialog.say(["You missed one. Click them while they're red and swollen."])


func _wave_done() -> void:
	phase = "talk"
	wave += 1
	if wave >= WAVES.size():
		for s in stars:
			if s.state == "alive":
				s.state = "dying"
				s.k = 0.6
		await wait(2.2)
		_set_stage(1)
		return
	dying = 0
	dim_to = wave * 0.2
	await Dialog.say(WAVE_TALK[wave])
	phase = "play"


func _low_power() -> void:
	energy = 0.45
	low_n += 1
	shake = 0.3
	phase = "talk"
	Sfx.tone(150, 0.5, 0.05, "sawtooth")
	var L := [["Carl! Hey! Stay with me!", "CARL:I am... fine. Merely... conserving... brilliance.", "Here, have some of mine."],
		["Carl, you're flickering!", "CARL:Lights flicker. It is... very on brand.", "Take a little more of my glow. I've got plenty. Probably."]]
	dim_to = minf(0.7, dim_to + 0.08)
	await Dialog.say(L[mini(low_n - 1, 1)])
	phase = "play"


# ---------------------------------------------------------------- input
func click(p: Vector2) -> void:
	if busy():
		return
	if st == 0 and phase == "play":
		var best = null
		var bd := 40.0
		for s in stars:
			if s.state != "dying":
				continue
			var d := p.distance_to(s.p)
			if d < bd:
				bd = d
				best = s
		if best != null:
			_catch(best)
	elif st == 2 and phase == "click" and p.distance_to(Vector2(300, 300)) < 100:
		_big_bang()
	elif st == 2 and phase == "loop" and end_t > 2.5:
		phase = "gone"
		Game.zoom_to(0, Vector2(640, 300), 1.6)


func _big_bang() -> void:
	phase = "bang"
	bang = 0.001
	Sfx.boom()
	var cols := [Color.WHITE, Color("ffe9a8"), Color("ffb86b"), Color("9ec5ff"), Color("e3a6ff"), Game.carl.color]
	for i in 320:
		var a := randf() * TAU
		var v := 60.0 + randf() * 460.0
		parts.append({"p": Vector2(300, 300), "v": Vector2(cos(a), sin(a)) * v, "life": 1.0 + randf() * 1.8, "c": cols[i % cols.size()], "s": randf_range(1.5, 4.0)})


# ---------------------------------------------------------------- update
func tick(dt: float) -> void:
	var sp := 0.75 if Game.settings.relaxed else 1.0
	if st == 0 and phase == "play" and not busy():
		var W: Dictionary = WAVES[wave]
		energy -= W.drain * dt * sp
		spawn_t -= dt * sp
		if spawn_t <= 0 and dying < W.n:
			_start_dying()
			spawn_t = W.every * (0.7 + randf() * 0.6)
		if energy <= 0:
			_low_power()
		var any := false
		for s in stars:
			if s.state == "dying":
				any = true
		if dying >= W.n and not any:
			_wave_done()
	for s in stars:
		if s.state == "dying":
			if st == 0 and phase == "play" and busy():
				continue
			s.k += dt * (sp / WAVES[mini(wave, 2)].win if st == 0 else 0.5)
			if s.k >= 1:
				_star_died(s)
	for m in motes:
		m.f += dt * 1.3
		var target := CARL_P - Vector2(0, 10)
		m.p += (target - m.p) * minf(1, dt * 3 * m.f) + m.v * dt * (1 - m.f)
		if m.f >= 1 and not m.done:
			m.done = true
			energy = minf(1, energy + 0.01)
	motes = motes.filter(func(m): return m.f < 1.2)
	light_dim += (dim_to - light_dim) * minf(1.0, dt * 1.2)
	glow_shown += (energy - glow_shown) * minf(1.0, dt * 2.5)
	if recline > 0 and recline < 1:
		recline = minf(1, recline + dt * 0.8)
	if phase == "morph":
		morph = minf(1, morph + dt / 8.0)
		if morph >= 1:
			phase = "talk"
			_carl_speaks()
	if bang > 0:
		bang += dt
		for p in parts:
			p.p += p.v * dt
			p.v *= 0.985
			p.life -= dt
		if bang > 3.2 and phase == "bang":
			phase = "loop"
	if phase == "loop":
		end_t += dt


func _carl_speaks() -> void:
	await Dialog.say(["CARL:...I understand now.", "NEW:Want to see something cool?", "NEW:Click me. Go on. Click the light."])
	phase = "click"


# ---------------------------------------------------------------- drawing
func _smooth(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


func _first_screen() -> void:
	var m := 1.0 if phase == "click" or (phase == "talk" and morph >= 1) else morph
	# three overlapping beats, each eased: Carl brightens and rises, he melts
	# into a new orb of light, then the whole screen warms into the opening scene
	var a1 := _smooth(clampf(m / 0.4, 0, 1))
	var a2 := _smooth(clampf((m - 0.25) / 0.45, 0, 1))
	var e := _smooth(clampf((m - 0.5) / 0.5, 0, 1))
	draw_rect(big_rect(), Color("03030a"))
	Art.draw_recliner(self, Vector2(70, 95), 1.0 - a1, t)
	var bg := Color("efe6cf")
	bg.a = e
	draw_rect(big_rect(), bg)
	Art.glow(self, Vector2(300, 300), 620 * (0.3 + 0.7 * e), Color(1, 0.995, 0.96, maxf(e, a2 * 0.25)))
	var rise := CARL_P.y + (300 + 30 - CARL_P.y) * a1
	var cy := rise + (300 - rise) * a2
	# sparks of light spiralling into Carl
	if a1 > 0 and e < 1:
		for i in 18:
			var k := fmod(t * 0.35 + i / 18.0, 1.0)
			var ang := i * 2.4 + k * 3.0
			var rad := 220.0 * (1.0 - k)
			Art.glow(self, Vector2(300, cy) + Vector2(cos(ang), sin(ang)) * rad, 8, Color(1, 0.93, 0.7, a1 * (1 - e) * k))
	if a2 < 1:
		var cs := 0.3 * (1.0 - 0.6 * a2)
		carl(Vector2(300, cy), cs, {"flip": true, "glow": glow_shown + a1 * (1.6 - glow_shown), "alpha": 1 - a2})
	var pulse := 1.0 + sin(t * 2.2) * 0.06 + (sin(t * 6) * 0.03 if phase == "click" else 0.0)
	var r := (10 + 28 * a2 + 32 * e) * pulse
	if a2 <= 0:
		return
	# the fish tail: Carl's own colour, glowing behind the new light
	var tc: Color = Game.carl.color.lerp(Color("f5c76a"), 0.4)
	tc.a = _smooth(clampf((m - 0.6) / 0.4, 0, 1)) * 0.9
	var tail := PackedVector2Array([Vector2(r * 0.45, -r * 0.2), Vector2(r * 1.5, -r * 0.65), Vector2(r * 1.28, 0), Vector2(r * 1.5, r * 0.65), Vector2(r * 0.45, r * 0.2)])
	var moved := PackedVector2Array()
	for p in tail:
		moved.append(p + Vector2(300, cy))
	Art.glow(self, Vector2(300 + r * 1.4, cy), r * 0.9, Color(1, 0.85, 0.55, 0.4 * e))
	draw_colored_polygon(moved, tc)
	Art.glow(self, Vector2(300, cy), r * 3.2, Color(1, 0.88, 0.55, 0.7 * a2))
	light(Vector2(300, cy), r, {"look": (mouse() - Vector2(300, cy)) / 300.0, "dim": 1.0 - a2, "squint": m < 0.97})
	if phase == "click":
		for i in 24:
			var a := t * 0.5 + i * TAU / 24
			draw_arc(Vector2(300, 300), 110, a, a + 0.14, 4, Color(0.78, 0.59, 0.16, 0.4 + 0.3 * sin(t * 4)), 3.0, true)


func paint() -> void:
	draw_rect(big_rect(), Color("03030a"))
	if st == 2 and (morph > 0 or phase == "click") and not phase in ["bang", "loop", "gone"]:
		_first_screen()
		return
	if phase in ["bang", "loop", "gone"]:
		var k := minf(1, bang / 1.6)
		draw_rect(big_rect(), Color(1, 0.99, 0.96).lerp(Color("07060d"), k))
		Art.draw_stars(self, new_stars, t, clampf((bang - 1.2) / 2, 0, 1))
		Art.glow(self, Vector2(300, 300), bang * 700 + 1, Color(1, 1, 1, maxf(0, 1 - bang / 1.4)))
		for p in parts:
			if p.life > 0:
				var c: Color = p.c
				c.a = minf(1, p.life)
				draw_circle(p.p, p.s, c)
		if phase != "bang":
			var a := minf(1, end_t / 2)
			Art.text(self, Vector2(300, 290), "The End", 46, Color(1, 0.91, 0.66, a), 0, Art.serif())
			Art.text(self, Vector2(300, 326), "...or the Beginning.", 18, Color(1, 0.91, 0.66, a), 0, Art.serif())
			if end_t > 2.5:
				txt(Vector2(300, 380), "Click to play again", 13, Color(0.64, 0.62, 0.71, a))
		return
	for s in stars:
		match s.state:
			"alive":
				var c := Color(1, 1, 0.94, 0.6 + 0.4 * sin(t * 2 + s.tw))
				Art.glow(self, s.p, s.r * 4, Color(1, 1, 0.9, 0.25))
				draw_circle(s.p, s.r, c)
			"dying":
				var R: float = s.r + s.k * 16
				Art.glow(self, s.p, R * 2.4, Color(1, 0.35, 0.24, 0.6 * (1 - s.k * 0.5)))
				draw_circle(s.p, R * 0.6, Color(1, (140 - s.k * 90) / 255.0, (90 - s.k * 60) / 255.0))
				draw_arc(s.p, R + 6, 0, TAU, 24, Color(1, 0.81, 0.35, 0.8 - s.k * 0.5), 2.0, true)
	for m in motes:
		Art.glow(self, m.p, 12, Color(1, 0.94, 0.7, 0.9))
	Art.draw_recliner(self, Vector2(70, 95), recline, t)
	var rk := _smooth(clampf(recline, 0, 1))
	light(Vector2(60, 60).lerp(Vector2(66, 66), rk), 16, {"dim": light_dim, "squint": recline > 0.5})
	carl(CARL_P, 0.3, {"flip": true, "glow": glow_shown, "talk": Dialog.blocking and Dialog._speaker == "carl"})
	if st == 0:
		Art.round_rect(self, Rect2(150, 560, 300, 14), 7, Color(0, 0, 0, 0.5))
		Art.round_rect(self, Rect2(152, 562, maxf(6, 296 * maxf(0, energy)), 10), 5, Color("ff7a5a") if energy < 0.25 else Color("ffcf5a"))
		txt(Vector2(300, 552), "Carl's glow", 12, Color("dddddd"))
		var left := stars.filter(func(s): return s.state == "alive" or s.state == "dying").size()
		txt(Vector2(585, 30), "Stars left: %d" % left, 12, Color("dddddd"), 1)
