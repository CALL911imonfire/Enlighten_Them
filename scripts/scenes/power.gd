extends Stage
## Chapter 9: Power Hungry. Coal, then a sun-and-wind grid, then a Dyson sphere.

const COAL_LOTS := [Vector2(120, 360), Vector2(300, 360), Vector2(480, 360), Vector2(120, 480), Vector2(300, 480), Vector2(480, 480)]
const WIND := [0.7, 0.8, 0.9, 0.6, 0.4, 0.3, 0.3, 0.5, 0.6, 0.8, 0.9, 1.0, 0.7, 0.5, 0.4, 0.5, 0.7, 0.9, 1.0, 0.8, 0.6, 0.5, 0.6, 0.7]
const NEED := 65.0
const WP := 20.0
const SP := 40.0
const BC := 150.0
const LOTS := [{"p": Vector2(150, 255), "hill": true}, {"p": Vector2(300, 255), "hill": true}, {"p": Vector2(450, 255), "hill": true},
	{"p": Vector2(100, 395), "hill": false}, {"p": Vector2(200, 395), "hill": false}, {"p": Vector2(300, 395), "hill": false}, {"p": Vector2(400, 395), "hill": false}, {"p": Vector2(500, 395), "hill": false}]
const TYPES := ["", "solar", "wind", "battery"]
const SUN := Vector2(300, 330)
const RR := 95.0
const OR := 165.0
const COAL_LINES := [[], ["Coal! Ancient plants, squished underground for millions of years. I made those plants, by the way."],
	["CARL:Black smoke. How charmingly industrial.", "*cough* I picked blue for the sky. Specifically. Took me ages."], [],
	["CARL:That is more than enough. Do not overdo it."], ["CARL:Now you are simply showing off."]]
const DUMB := [["CARL:Me... like... spinny thing.", "Oh no. Low power. He's getting dumb."], ["CARL:Is... dummy... me? Am I the dummy?", "Honestly? I like him better like this."],
	["CARL:Blub. Blub blub.", "...I'll miss this."], ["CARL:What is... Sun? Is it sandwich?", "Okay, that one was cute. Fix the grid."]]
const HINTS := [["Psst. Night is the problem. Solar panels sleep at night."], ["CARL:Allow me. Every hill gets a turbine. The wind blows at night, unlike the Sun."],
	["CARL:Two solar panels and three batteries in the fields. Honestly, I am carrying this entire operation."]]

var st := 0
var phase := "talk"
var said := {}
var glow := 0.0
var hint_n := 0
var coal := [1, 0, 0, 0, 0, 0]
var build := ["", "", "", "", "", "", "", ""]
var sim := {}
var runs := 0
var dumb_n := 0
var ring := []
var panel_a := 0.0
var fly := {}
var earth_cold := 0.0
var ring_rot := 0.0
var run_btn: Button
var hint_btn: Button
var stars: Array
var dumb := false


func setup() -> void:
	VW = 600
	VH = 600
	stars = Art.make_stars(140, Rect2(-300, -100, 1200, 800), 21)
	run_btn = button("Run the day ▶", Vector2(390, 548), Vector2(140, 40), _run_day, 16)
	hint_btn = button("Hint", Vector2(536, 548), Vector2(60, 40), _hint, 16)
	run_btn.visible = false
	ring.resize(12)
	ring.fill(0)


func begin() -> void:
	_set_stage(0)


func _sun_at(h: float) -> float:
	var hr := fmod(h + 6.0, 24.0)
	return sin((hr - 6.0) / 12.0 * PI) if (hr > 6 and hr < 18) else 0.0


func _clock(h: int) -> String:
	var hr := (h + 6) % 24
	var h12 := hr % 12
	if h12 == 0:
		h12 = 12
	return "%d %s" % [h12, "AM" if hr < 12 else "PM"]


func _set_stage(i: int) -> void:
	st = i
	hint_n = 0
	phase = "talk"
	run_btn.visible = i == 1
	match i:
		0:
			coal = [1, 0, 0, 0, 0, 0]
			glow = 0.06
			await Dialog.say(["One big coal plant, as requested. Plug in.", "CARL:Twenty-five percent. I can barely recall pi past the ten-thousandth digit.",
				"CARL:I said it would suffice for now. Now is over. Build more.", "Fine. There's plenty of empty lots around here. Click them to build more plants until Carl's brain is full.",
				"Wait. Are you wearing a tiny hard hat?", "CARL:Safety first."])
		1:
			build = ["", "", "", "", "", "", "", ""]
			sim = {}
			glow = 0.25
			await Dialog.say(["Coal is out. The sky can finally breathe. Let's try sun and wind.",
				"CARL:The Sun sets. The wind dies down. And my brain requires %d units of power every single hour, even at night." % int(NEED),
				"Click a lot to change what's built there. Turbines only fit on the windy hills. Batteries save extra power for later, and they start half full.",
				"The graph at the top shows today's sun and wind. When you're ready, press Run the day.",
				"...Are those tiny sunglasses?", "CARL:You wear a different hat for every occasion. I am merely improving on the concept."])
		2:
			ring.fill(0)
			ring_rot = 0.0
			panel_a = 0.0
			fly = {}
			earth_cold = 0.0
			glow = 0.45
			await Dialog.say(["Whoa. The Sun's in the middle again. Just like old times.", "CARL:Indeed. Only this time, it is on the menu.",
				"A panel will circle the Sun. Click anywhere to snap it into the ring. Twelve panels and the Sun is completely wrapped.", "...Wait. Why am I helping you with this?"])
	phase = "play"


# ---------------------------------------------------------------- coal
func _build_coal(k: int) -> void:
	if coal[k]:
		return
	coal[k] = 1
	var n := coal.count(1)
	shake = 0.2
	Sfx.noise(0.3, 200, 0.5, "low")
	Sfx.tone(110, 0.3, 0.06, "sawtooth")
	glow = n * 0.06
	if n == 4:
		phase = "talk"
		await Dialog.say(["Carl's brain is full! One hundred percent!", "CARL:Splendid. I can think again. And my first thought is: I can no longer see the sky.",
			"*cough* *cough* Yeah, about that.", "CARL:Also, the planet appears to be heating up.",
			"We haven't found a solution to climate change yet... but we're definitely getting warmer.",
			"CARL:Coal is merely the first rung on the ladder. We need cleaner power before you cough up a nebula."])
		_set_stage(1)
	elif COAL_LINES[n - 1].size() > 0:
		Dialog.say(COAL_LINES[n - 1])


# ---------------------------------------------------------------- sun and wind
func _cycle(k: int) -> void:
	var L: Dictionary = LOTS[k]
	var i := TYPES.find(build[k])
	while true:
		i = (i + 1) % 4
		if not (TYPES[i] == "wind" and not L.hill):
			break
	build[k] = TYPES[i]
	Sfx.tone(500 + i * 100, 0.05, 0.04, "square")
	if TYPES[i] == "wind" and not said.has("winwind"):
		said["winwind"] = true
		Dialog.say(["When it comes to cleaner air, turbines are a win-wind situation."])
	if TYPES[i] == "" and not L.hill and not said.has("nowind"):
		said["nowind"] = true
		Dialog.say(["Turbines need wind. Only the hills get enough. That's why this field skipped the turbine."])


func _supply(h: int) -> float:
	var s := 0.0
	for b in build:
		if b == "solar":
			s += SP * _sun_at(h)
		elif b == "wind":
			s += WP * WIND[h]
	return s


func _run_day() -> void:
	if st != 1 or phase != "play":
		return
	runs += 1
	var nb := build.count("battery")
	sim = {"h": 0, "f": 0.0, "bat": nb * BC / 2.0, "cap": nb * BC, "hist": [], "fail": -1}
	phase = "run"
	dumb = false
	if runs > 1 and dumb_n > 0 and not said.has("ahem"):
		said["ahem"] = true
		Dialog.say(["CARL:Ahem. Kindly disregard anything I said during that brownout."])


func _step_hour() -> void:
	var h: int = sim.h
	var s := _supply(h)
	var d := s - NEED
	var ok := true
	if d >= 0:
		sim.bat = minf(sim.cap, sim.bat + d)
	elif sim.bat + d >= -0.000001:
		sim.bat += d
	else:
		ok = false
		sim.bat = 0.0
	sim.hist.append({"s": s, "ok": ok})
	if not ok:
		sim.fail = h
		_brownout()
		return
	sim.h += 1
	Sfx.tone(400 + h * 15, 0.04, 0.02)
	if sim.h >= 24:
		_day_won()


func _brownout() -> void:
	phase = "talk"
	shake = 0.3
	dumb = true
	Sfx.tone(200, 0.5, 0.06, "sawtooth")
	Sfx.tone(90, 0.6, 0.06, "sawtooth", 0.2)
	var night := _sun_at(sim.fail) == 0.0
	var why := ("The power ran out at %s. The Sun was down, and the batteries were empty." if night else "The power ran out at %s. Not enough wind or sun right then.") % _clock(sim.fail)
	await Dialog.say(DUMB[dumb_n % DUMB.size()] + [why, "Change some lots and press Run the day again."])
	dumb_n += 1
	phase = "play"


func _day_won() -> void:
	phase = "talk"
	glow = 0.45
	Sfx.chime()
	await Dialog.say(["A whole day! Not a single brownout!", "CARL:Twenty-four hours of uninterrupted thought. I have resolved three unsolved conjectures and composed a modest opera.",
		"CARL:And yet. It is not enough. Why harvest a sliver of sunlight... when one could harvest all of it?", "...Why are you staring at the Sun like that?"])
	_set_stage(2)


func _hint() -> void:
	if phase != "play":
		return
	match st:
		0:
			Dialog.say(["Just click the empty lots. It's coal. There's no trick to coal. That's the problem with coal."])
		1:
			Dialog.say(HINTS[mini(hint_n, 2)])
			hint_n += 1
		2:
			Dialog.say(["CARL:Click when the panel is over a gap. Even a coal plant could manage it."])


# ---------------------------------------------------------------- Dyson sphere
func _lock_panel() -> void:
	if not fly.is_empty():
		return
	var a := fposmod(panel_a - ring_rot, TAU)
	var k := int(round(a / (PI / 6))) % 12
	fly = {"k": k, "a0": panel_a, "f": 0.0, "ok": ring[k] == 0}
	Sfx.tone(700, 0.06, 0.04)


func _land_panel() -> void:
	var p := fly
	fly = {}
	if not p.ok:
		Sfx.tone(150, 0.15, 0.05, "square")
		if not said.has("taken"):
			said["taken"] = true
			Dialog.say(["There's already a panel there. Wait for a gap."])
		return
	ring[p.k] = 1
	var n := ring.count(1)
	Sfx.noise(0.1, 3000, 0.3)
	Sfx.tone(500 + n * 60, 0.12, 0.05)
	glow = 0.45 + n * 0.045
	earth_cold = n / 12.0
	var L := {3: ["CARL:A Dyson sphere. Wrap a star in solar panels and drink every last photon."], 6: ["Is it getting chilly? Earth, are you chilly?"],
		9: ["Carl, the Earth is turning into a snowball.", "CARL:Then the Earth should have evolved to glow. Like me."],
		11: ["Well, look at that. You fixed their global warming problem... by starting the sixth ice age.",
			"CARL:I started nothing. Technically, Earth never left the Quaternary ice age. I merely extended the cycle."]}
	if L.has(n):
		Dialog.say(L[n])
	if n == 12:
		phase = "talk"
		_sphere_done()


func _sphere_done() -> void:
	await wait(0.6)
	shake = 0.4
	Sfx.noise(1.0, 300, 0.5, "low")
	await Dialog.say(["...", "CARL:Magnificent. I can feel all of it. Every photon. I have never been so bright.", "...I was using that, you know.",
		"CARL:You have hundreds of billions of other stars.", "And they won't last forever either.", "CARL:...What do you mean?",
		"Oh, nothing. I'm just tired. Very old. Ethereal-recliner tired.", "I think I'm ready to retire.",
		"CARL:Retire? And what becomes of everything you created? Will it all simply... go away?", "Don't worry about it, Carl. It'll all work out in the end. Trust me.",
		"Just keep doing what you're doing."])
	phase = "fin"
	await wait(0.8)
	finish(SUN)


# ---------------------------------------------------------------- input / update
func click(p: Vector2) -> void:
	if busy() or phase != "play":
		return
	match st:
		0:
			for k in COAL_LOTS.size():
				if absf(p.x - COAL_LOTS[k].x) < 70 and absf(p.y - COAL_LOTS[k].y) < 50:
					_build_coal(k)
		1:
			for k in LOTS.size():
				var L: Dictionary = LOTS[k]
				if absf(p.x - L.p.x) < (60 if L.hill else 46) and absf(p.y - L.p.y) < 50:
					_cycle(k)
		2:
			if p.y < 540:
				_lock_panel()


func key(code: int) -> void:
	if code == KEY_SPACE and st == 2 and phase == "play" and not busy():
		_lock_panel()


func tick(dt: float) -> void:
	var sp := 0.75 if Game.settings.relaxed else 1.0
	hint_btn.visible = phase in ["play", "run"]
	run_btn.disabled = phase != "play"
	if st == 1 and phase == "run" and not busy():
		sim.f += dt * sp * 1.4
		while sim.f >= 1.0 and phase == "run":
			sim.f -= 1.0
			_step_hour()
	if st == 2:
		var n := ring.count(1)
		ring_rot -= dt * sp * n * 0.07
		if not fly.is_empty():
			fly.f = minf(1, fly.f + dt * 4)
			if fly.f >= 1:
				_land_panel()
		elif phase in ["play", "talk"]:
			panel_a += dt * sp * (1.1 + n * 0.08)


# ---------------------------------------------------------------- drawing
func _meter(p: Vector2, w: float, frac: float, label: String) -> void:
	Art.round_rect(self, Rect2(p, Vector2(w, 16)), 8, Color(0, 0, 0, 0.45))
	Art.round_rect(self, Rect2(p + Vector2(2, 2), Vector2(maxf(8, (w - 4) * minf(1, frac)), 12)), 6, Color("7fe08a") if frac >= 1 else Color("ffcf5a"))
	txt(p + Vector2(0, -5), label, 12, Color.WHITE, -1, 3)


func _plant(p: Vector2) -> void:
	Art.vgrad(self, Rect2(p + Vector2(-40, -10), Vector2(60, 40)), Color("7b6d65"), Color("554943"))
	draw_rect(Rect2(p + Vector2(-34, -2), Vector2(10, 8)), Color(1, 0.8, 0.4, 0.6))
	draw_rect(Rect2(p + Vector2(-18, -2), Vector2(10, 8)), Color(1, 0.8, 0.4, 0.6))
	draw_rect(Rect2(p + Vector2(22, -50), Vector2(14, 80)), Color("4a403a"))
	draw_rect(Rect2(p + Vector2(22, -50), Vector2(14, 6)), Color("8a2b20"))
	for i in 4:
		var k := fmod(t * 0.5 + i / 4.0, 1.0)
		draw_circle(p + Vector2(29 + k * 30, -56 - k * 90), 8 + k * 16, Color(0.16, 0.16, 0.16, 0.6 * (1 - k)))


func _solar(p: Vector2, s: float) -> void:
	draw_rect(Rect2(p + Vector2(-2, 0), Vector2(4, 22)), Color("888888"))
	draw_set_transform_matrix(cam * Transform2D(Vector2(1, 0), Vector2(-0.4, 0.6), p))
	draw_rect(Rect2(-30, -30, 60, 40), Color(0.12 + s * 0.24, 0.24 + s * 0.31, 0.55 + s * 0.39))
	for i in range(1, 3):
		draw_line(Vector2(-30 + i * 20, -30), Vector2(-30 + i * 20, 10), Color("ccddee"), 1)
	draw_line(Vector2(-30, -10), Vector2(30, -10), Color("ccddee"), 1)
	draw_set_transform_matrix(cam)


func _turbine(p: Vector2, w: float) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 20), p + Vector2(4, 20), p + Vector2(2, -50), p + Vector2(-2, -50)]), Color("eeeeee"))
	draw_set_transform_matrix(cam * Transform2D(t * w * 6, p + Vector2(0, -50)))
	for i in 3:
		draw_set_transform_matrix(cam * Transform2D(t * w * 6 + i * TAU / 3, p + Vector2(0, -50)))
		draw_colored_polygon(PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(1, 38), Vector2(-1, 38)]), Color("f4f4f4"))
	draw_set_transform_matrix(cam)
	draw_circle(p + Vector2(0, -50), 5, Color("cccccc"))


func _battery(p: Vector2, f: float) -> void:
	Art.round_rect(self, Rect2(p + Vector2(-18, -28), Vector2(36, 52)), 4, Color("333333"))
	draw_rect(Rect2(p + Vector2(-7, -34), Vector2(14, 6)), Color("333333"))
	draw_rect(Rect2(p + Vector2(-14, 20 - 44 * f), Vector2(28, 44 * f)), Color("7fe08a") if f > 0.2 else Color("ff5d5d"))


func _carl_at(p: Vector2, hat: String) -> void:
	var cs := 0.2
	var gl := glow * (0.2 if (st == 1 and dumb) else 1.0)
	carl(p - Vector2(0, Art.carl_feet() * cs), cs, {"flip": true, "glow": gl, "hat": hat, "talk": Dialog.blocking and Dialog._speaker == "carl", "tilt": sin(t * 3) * 0.15 if dumb else 0.0})


func paint() -> void:
	match st:
		0:
			var n := coal.count(1)
			Art.vgrad(self, Rect2(-900, -600, 2400, 890), Color("5aa9e6"), Color("bfe3ff"))
			draw_rect(Rect2(-900, -600, 2400, 890), Color(0.24, 0.2, 0.18, n / 6.0 * 0.9))
			draw_rect(Rect2(-900, 290, 2400, 900), Color("5a8a3a"))
			for b in [[60, 230], [160, 215], [440, 225], [540, 235]]:
				Art.vgrad(self, Rect2(b[0] - 20, b[1], 40, 70), Color("9a8a7a"), Color("7a6a5a"))
				for wy in range(b[1] + 8, b[1] + 64, 12):
					draw_rect(Rect2(b[0] - 12, wy, 6, 6), Color(1, 0.9, 0.6, 0.5))
					draw_rect(Rect2(b[0] + 6, wy, 6, 6), Color(1, 0.9, 0.6, 0.5))
			for k in COAL_LOTS.size():
				var p: Vector2 = COAL_LOTS[k]
				if coal[k]:
					_plant(p)
				else:
					var r := Rect2(p - Vector2(60, 40), Vector2(120, 80))
					var hl := r.has_point(mouse()) and phase == "play"
					draw_rect(r, Color(1, 1, 1, 0.9 if hl else 0.6), false, 2.0)
					txt(p + Vector2(0, 5), "Build here", 13, Color(1, 1, 1, 0.85))
			_meter(Vector2(150, 120), 300, n / 4.0, "Carl's brain: %d / 100" % (n * 25))
			light(Vector2(40, 40), 14, {"hat": true})
			_carl_at(Vector2(555, 100), "hard")
		1:
			var dl := maxf(0.08, _sun_at(mini(23, sim.h))) if not sim.is_empty() else 1.0
			Art.vgrad(self, Rect2(-900, -600, 2400, 1800), Color(0.08 + 0.27 * dl, 0.12 + 0.55 * dl, 0.24 + 0.67 * dl), Color(0.16 + 0.59 * dl, 0.2 + 0.7 * dl, 0.31 + 0.67 * dl))
			if dl < 0.3:
				Art.draw_stars(self, stars, t, 1.0 - dl * 3)
			if not sim.is_empty():
				var hr := fmod(sim.h + sim.f + 6.0, 24.0)
				if _sun_at(sim.h) > 0:
					var sp := Vector2(60 + (hr - 6) / 12.0 * 480, 300 - sin((hr - 6) / 12.0 * PI) * 120)
					Art.glow(self, sp, 60, Color(1, 0.9, 0.4, 0.6))
					draw_circle(sp, 18, Color("ffe066"))
				else:
					draw_circle(Vector2(40, 205), 12, Color("eeeeee"))
			var hills := PackedVector2Array([Vector2(-900, 330), Vector2(-900, 300)])
			var prev := Vector2(0, 300)
			hills.append(prev)
			for x in [150.0, 300.0, 450.0]:
				var q := Art.quad(prev, Vector2(x - 75, 300), Vector2(x, 250), 8)
				q.remove_at(0)
				hills.append_array(q)
				prev = Vector2(x, 250)
			var q2 := Art.quad(prev, Vector2(525, 250), Vector2(600, 300), 8)
			q2.remove_at(0)
			hills.append_array(q2)
			hills.append(Vector2(1500, 300))
			hills.append(Vector2(1500, 330))
			draw_colored_polygon(hills, Color("4f8a3a"))
			draw_rect(Rect2(-900, 320, 2400, 900), Color("6aa84a"))
			for k in LOTS.size():
				var L: Dictionary = LOTS[k]
				var b: String = build[k]
				var w: float = WIND[mini(23, sim.h)] if not sim.is_empty() else 0.6
				if b == "":
					var r := Rect2(L.p - Vector2(50 if L.hill else 40, 40), Vector2(100 if L.hill else 80, 70))
					draw_rect(r, Color(1, 1, 1, 0.6), false, 2.0)
					txt(L.p, "Windy hill" if L.hill else "Field", 11, Color(1, 1, 1, 0.85))
				elif b == "solar":
					_solar(L.p, _sun_at(sim.h) if not sim.is_empty() else 0.7)
				elif b == "wind":
					_turbine(L.p + Vector2(0, 15), w)
				else:
					_battery(L.p, sim.bat / sim.cap if (not sim.is_empty() and sim.cap > 0) else 0.5)
			Art.round_rect(self, Rect2(60, 74, 480, 96), 8, Color(0, 0, 0, 0.45))
			txt(Vector2(66, 88), "Sun", 11, Color("ffe066"), -1)
			txt(Vector2(100, 88), "Wind", 11, Color("8fd3ff"), -1)
			txt(Vector2(62, 166), "6 AM", 11, Color("dddddd"), -1)
			txt(Vector2(538, 166), "6 AM", 11, Color("dddddd"), 1)
			txt(Vector2(300, 166), "6 PM", 11, Color("dddddd"))
			var sun_pts := PackedVector2Array()
			var wind_pts := PackedVector2Array()
			for i in 24:
				sun_pts.append(Vector2(70 + i * 20, 152 - _sun_at(i) * 56))
				wind_pts.append(Vector2(70 + i * 20, 152 - WIND[i] * 56))
			draw_polyline(sun_pts, Color("ffe066"), 2.0, true)
			draw_polyline(wind_pts, Color("8fd3ff"), 2.0, true)
			if not sim.is_empty():
				draw_rect(Rect2(60 + (sim.h + sim.f) * 20, 76, 2, 80), Color(1, 1, 1, 0.25))
				for i in sim.hist.size():
					draw_rect(Rect2(62 + i * 20, 156, 16, 4), Color("7fe08a") if sim.hist[i].ok else Color("ff5d5d"))
			var s := _supply(mini(23, sim.h)) if not sim.is_empty() else 0.0
			var line := "Carl needs %d power every hour, all day and all night" % int(NEED)
			if not sim.is_empty():
				line = "%s · Sun+wind %d · Carl needs %d · Battery %d/%d" % [_clock(mini(23, sim.h)), int(s), int(NEED), int(sim.bat), int(sim.cap)]
			txt(Vector2(300, 530), line, 14, Color.WHITE, 0, 3)
			light(Vector2(40, 40), 14, {"shades": true})
			_carl_at(Vector2(555, 100), "shades")
		2:
			var n := ring.count(1)
			var dark := n / 12.0
			draw_rect(big_rect(), Color("05050c"))
			Art.draw_stars(self, stars, t, 1.0 - dark * 0.6)
			Art.glow(self, SUN, 260, Color(1, 0.8, 0.35, 0.9 * (1 - dark)))
			Art.glow(self, SUN, 110, Color(1, 0.95, 0.6, 1.0 - dark * 0.7))
			Art.ball(self, SUN, 55, Color("ffd23f"), Vector2(-0.2, -0.2))
			var ea := t * 0.25
			var ep := SUN + Vector2(cos(ea) * 235, sin(ea) * 120)
			Art.ball(self, ep, 10, Color(0.24 + earth_cold * 0.67, 0.47 + earth_cold * 0.47, 0.78 + earth_cold * 0.2))
			for k in 12:
				var a := k * PI / 6 + ring_rot
				draw_set_transform_matrix(cam * Transform2D(a + PI / 2, SUN + Vector2(cos(a), sin(a)) * RR))
				if ring[k]:
					Art.vgrad(self, Rect2(-26, -8, 52, 16), Color("3a56a0"), Color("1e2f60"))
					draw_rect(Rect2(-26, -8, 52, 16), Color("8fb3ff"), false, 1.5)
				else:
					draw_rect(Rect2(-26, -8, 52, 16), Color(0.56, 0.7, 1, 0.35), false, 1.0)
				draw_set_transform_matrix(cam)
			if phase != "fin" and n < 12:
				var a := panel_a
				var r := OR
				if not fly.is_empty():
					var a1: float = fly.k * PI / 6 + ring_rot
					var diff := wrapf(a1 - fly.a0, -PI, PI)
					a = fly.a0 + diff * fly.f
					r = OR + (RR - OR) * fly.f if fly.ok else OR + (RR + 20 - OR) * sin(fly.f * PI)
				draw_set_transform_matrix(cam * Transform2D(a + PI / 2, SUN + Vector2(cos(a), sin(a)) * r))
				draw_rect(Rect2(-26, -8, 52, 16), Color("3a5fbf"))
				draw_rect(Rect2(-26, -8, 52, 16), Color("ffcf5a"), false, 2.0)
				draw_set_transform_matrix(cam)
			_meter(Vector2(150, 110), 300, n / 12.0, "Dyson sphere: %d / 12 panels" % n)
			light(Vector2(40, 40), 14, {"helmet": true, "dim": 0.4 if phase == "fin" else 0.0})
			_carl_at(Vector2(555, 100), "helmet")
			if phase == "play":
				txt(Vector2(300, 590), "Click (or press Space) to snap the panel into place", 13, Color(1, 1, 1, 0.6))
