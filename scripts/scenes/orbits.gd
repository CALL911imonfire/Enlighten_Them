extends Stage
## Chapter 1: the light, the Big Bang, and fixing the Earth-centred sky.

const C := Vector2(300, 300)
const RINGS := [50.0, 76.0, 102.0, 130.0, 168.0, 206.0, 240.0, 272.0]
const PLUTO_LINES := [
	"Ah. Pluto. It used to be a planet. Then in 2006 the humans held a vote and... now it isn't.",
	"Still no. Humans are always changing their minds. Give it a few years.",
	"Pluto doesn't fit anywhere right now. It's not you. It's the International Astronomical Union.",
	"I'm not saying it's fair. I'm saying it's paperwork.",
]
const PL := [
	{"id": "mercury", "name": "Mercury", "r": 7.0, "col": "b9b3a9", "quip": "Mercury goes right next to the Sun. It likes it hot.",
		"yes": "Mercury! Smallest planet, front-row seat. A year there lasts 88 days. Birthdays get exhausting."},
	{"id": "venus", "name": "Venus", "r": 10.0, "col": "e8c37a", "quip": "Venus is second. Pretty, toxic and spins backwards. Relatable.",
		"yes": "Venus! Hottest planet in the neighborhood. Not the closest, just the most dramatic."},
	{"id": "earth", "name": "Earth", "r": 11.0, "col": "3d8bd9", "quip": "Earth goes third. Not first. Not the center. Third. Humbling, isn't it?",
		"yes": "Earth. Third rock from the Sun. Don't let it go to your head."},
	{"id": "mars", "name": "Mars", "r": 8.0, "col": "d0603a", "quip": "Mars comes right after Earth. They're neighbors. They don't talk much.",
		"yes": "Mars! Don't tell anyone, but Martians are real. They're a lot like humans. Not very bright."},
	{"id": "jupiter", "name": "Jupiter", "r": 20.0, "col": "d9a066", "quip": "Jupiter is enormous. Put it out past Mars, where it has room to sprawl.",
		"yes": "Jupiter! See that big red spot? It's a storm bigger than Earth that's been raging for centuries. Some planets really hold a grudge."},
	{"id": "saturn", "name": "Saturn", "r": 16.0, "col": "e6cf8b", "quip": "Saturn goes sixth, right after Jupiter. Look for the bling.",
		"yes": "Saturn! ♪ I liked it, so I put a ring on it ♪ ...Sorry. I get carried away."},
	{"id": "uranus", "name": "Uranus", "r": 13.0, "col": "9fe3e6", "quip": "Uranus goes seventh, after Saturn. Yes, it's a funny name. Focus.",
		"yes": "Uranus. Go on, get the joke out of your system. ...Done? It also spins on its side. Nobody knows why."},
	{"id": "neptune", "name": "Neptune", "r": 13.0, "col": "4a6fe0", "quip": "Neptune is the last one. Way out there, past Uranus.",
		"yes": "Neptune! Windiest planet out here. The humans found it with math before anyone ever saw it. Nerds."},
]
# geocentric loops around Earth: deferent radius, epicycle radius, speeds
const GEO := {"mercury": [58.0, 14.0, 0.9, 3.1], "venus": [92.0, 20.0, 0.7, 2.4], "sun": [134.0, 0.0, 0.45, 0.0],
	"mars": [178.0, 28.0, 0.35, 1.9], "jupiter": [220.0, 20.0, 0.22, 1.5], "saturn": [250.0, 14.0, 0.16, 1.2]}

var phase := "intro"
var bodies: Array = []
var sun: Dictionary
var earth: Dictionary
var pluto: Dictionary
var slots: Array = []
var placed := 0
var mistakes := 0
var pluto_tries := 0
var ring_flash := []
var sys_a := 0.0
var ring_a := 0.0
var bang_t := 0.0
var can_orb := false
var stars: Array
var parts: Array = []
var grab = null
var hold = null
var grab_start := Vector2.ZERO
var grab_moved := false
var mic_t := 0.0
var flash := 0.0


func setup() -> void:
	VW = 600
	VH = 672
	stars = Art.make_stars(260, Rect2(-500, -200, 1600, 1100), 3)
	for i in 9:
		slots.append(Vector2(36 + i * 66, 618))
	ring_flash.resize(RINGS.size())
	ring_flash.fill(0.0)
	for p in PL:
		var b := _body(p.id, p.r, Color(p.col))
		b.p = p
		if not GEO.has(p.id) and p.id != "earth":
			b.mode = "hidden"
			b.pos = Vector2(VW + 40, 618)
		bodies.append(b)
		if p.id == "earth":
			earth = b
			b.mode = "center"
	sun = _body("sun", 24.0, Color("ffd23f"))
	sun.a = 1.2
	bodies.append(sun)
	pluto = _body("pluto", 5.0, Color("c9b8a6"))
	pluto.p = {"name": "Pluto"}
	pluto.mode = "hidden"
	pluto.pos = Vector2(VW + 40, 618)
	bodies.append(pluto)


func _body(id: String, r: float, col: Color) -> Dictionary:
	return {"id": id, "r": r, "col": col, "pos": C, "mode": "geo", "a": randf() * 7.0, "b": randf() * 7.0,
		"trail": [], "slot": Vector2.ZERO, "tx": Vector2.ZERO, "after": "", "ang": 0.0, "rad": 0.0, "p": {}}


func begin() -> void:
	await Dialog.say(["Oh! Hello there.", "Want to see something cool?", "Click me. Go on. Click the light."])
	can_orb = true


# ---------------------------------------------------------------- input
func _grabbable(p: Vector2):
	if phase == "sun" and p.distance_to(sun.pos) < sun.r + 16:
		return sun
	if phase == "order":
		for b in bodies:
			if b.mode == "tray" and p.distance_to(b.pos) < maxf(24.0, b.r + 12.0):
				return b
	return null


func click(p: Vector2) -> void:
	if busy():
		return
	if phase == "intro" and can_orb and p.distance_to(C) < 90:
		_start_bang()
		return
	if hold != null:
		var h = hold
		hold = null
		_drop(h, p)
		return
	var b = _grabbable(p)
	if b == null:
		return
	grab = b
	grab_start = p
	grab_moved = false
	b.mode = "held"
	Sfx.tone(660, 0.05, 0.04)


func drag(p: Vector2) -> void:
	if grab != null:
		if p.distance_to(grab_start) > 6:
			grab_moved = true
		grab.pos = p
	elif hold != null:
		hold.pos = p


func release(p: Vector2) -> void:
	if grab == null:
		return
	var g = grab
	grab = null
	if grab_moved:
		_drop(g, p)
	else:
		hold = g


func _fly(b: Dictionary, to: Vector2, after: String) -> void:
	b.mode = "fly"
	b.tx = to
	b.after = after


func _drop(b: Dictionary, p: Vector2) -> void:
	if b == sun:
		if p.distance_to(C) < 48:
			_sun_placed()
			return
		b.mode = "geo"
		Sfx.tone(150, 0.15, 0.05, "sawtooth")
		Dialog.say([["Close! The middle. The very middle.", "That's not the center. That's just... somewhere.", "Think bigger. Think central."].pick_random()])
		return
	if b == pluto:
		_fly(b, b.slot, "tray")
		for i in 3:
			Sfx.tone([330, 262, 196][i], 0.25, 0.05, "sine", i * 0.18)
		Dialog.say([PLUTO_LINES[mini(pluto_tries, PLUTO_LINES.size() - 1)]])
		pluto_tries += 1
		return
	var d := p.distance_to(C)
	var ring := -1
	for i in RINGS.size():
		if absf(d - RINGS[i]) < 13:
			ring = i
	var want := PL.find(b.p)
	if ring == want:
		b.mode = "orbit"
		b.ang = (p - C).angle()
		b.rad = RINGS[ring]
		placed += 1
		Sfx.tone(784, 0.3, 0.06)
		Sfx.tone(1046, 0.3, 0.06, "triangle", 0.08)
		Dialog.say([b.p.yes])
		if b.id == "saturn":
			mic_t = 7.0
		if placed == PL.size():
			phase = "done"
			_finish()
		return
	_fly(b, b.slot, "tray")
	if ring >= 0:
		ring_flash[ring] = 1.0
		mistakes += 1
		Sfx.tone(140, 0.2, 0.06, "sawtooth")
		Dialog.say([b.p.quip])


# ---------------------------------------------------------------- story
func _start_bang() -> void:
	phase = "bang"
	bang_t = 0.0
	can_orb = false
	flash = 1.0
	Sfx.boom()
	var cols := [Color.WHITE, Color("ffe9a8"), Color("ffb86b"), Color("9ec5ff"), Color("e3a6ff")]
	for i in 320:
		var a := randf() * TAU
		var s := 60.0 + randf() * 460.0
		parts.append({"p": C, "v": Vector2(cos(a), sin(a)) * s, "life": 1.0 + randf() * 1.8, "c": cols[i % 5], "s": randf_range(1.5, 4.0)})


func _after_bang() -> void:
	phase = "geo"
	await Dialog.say([
		"Ta-da! That was the Big Bang. You're welcome.",
		"Let's skip ahead a few billion years...",
		"Here's what the humans worked out from looking up at the sky.",
		"Everything goes around THEM. The Sun, the planets, all of it.",
		"And see those loopy paths? The planets didn't move the way the humans expected, so they added little circles on top of the circles. Epicycles. Very creative. Completely wrong.",
		"Typical. Humans always think they're the center of the universe.",
		"No. That spot belongs to the light. Obviously.",
		"Please, enlighten them. Put the Sun where it belongs. Drag it to the middle, or click it and click again to drop it.",
	])
	phase = "sun"


func _sun_placed() -> void:
	phase = "moving"
	_fly(sun, C, "center")
	Sfx.boom(0.4)
	for b in bodies:
		b.trail = []
	var order := range(slots.size())
	order.shuffle()
	var i := 0
	for b in bodies:
		if b == sun or b == pluto:
			continue
		b.slot = slots[order[i]]
		_delayed_fly(b, 0.15 + i * 0.09)
		i += 1
	pluto.slot = slots[order[PL.size()]]
	_delayed_fly(pluto, 0.9)
	await wait(0.9)
	await Dialog.say([
		"Much better. The light in the middle, where it belongs.",
		"Hm. Now everyone's a little out of place. Earth especially. Sorry, Earth.",
		"And who are these two? Uranus and Neptune. The humans haven't found them yet. Don't spoil it.",
		"Put the planets back on their rings. Closest to the Sun goes first.",
	])
	phase = "order"


func _delayed_fly(b: Dictionary, d: float) -> void:
	await wait(d)
	_fly(b, b.slot, "tray")


func _finish() -> void:
	await wait(3.2)
	while Dialog.busy():
		await wait(0.2)
	var first: String
	if mistakes == 0:
		first = "Perfect, first try! Are you sure you're not a deity?"
	else:
		first = "Perfect! And only %d wrong guess%s. I've seen worse. I've seen MUCH worse." % [mistakes, "es" if mistakes > 1 else ""]
	await Dialog.say([
		first,
		"Copernicus is going to be so smug about this.",
		"And Pluto... Pluto can wait in the tray. It's used to waiting." if pluto_tries > 0 else "Oh, and don't worry about Pluto. Nobody does anymore.",
		"Galileo too. They'll put him under house arrest for agreeing with you. Humans!",
		"Anyway. Let's take a closer look at that little blue one.",
	])
	finish(earth.pos)


# ---------------------------------------------------------------- update
func tick(dt: float) -> void:
	mic_t = maxf(0.0, mic_t - dt)
	flash = maxf(0.0, flash - dt * 0.8)
	if phase == "bang":
		bang_t += dt
		for p in parts:
			p.p += p.v * dt
			p.v *= 0.985
			p.life -= dt
		if bang_t > 3.2:
			parts.clear()
			_after_bang()
	if phase != "intro" and phase != "bang":
		sys_a = minf(1.0, sys_a + dt * 0.6)
	if phase in ["order", "done", "moving"]:
		ring_a = minf(1.0, ring_a + dt * 0.8)
	for i in ring_flash.size():
		ring_flash[i] = maxf(0.0, ring_flash[i] - dt * 1.5)
	for b in bodies:
		match b.mode:
			"geo":
				var g: Array = GEO[b.id]
				b.a += dt * g[2] * 0.6
				b.b += dt * g[3] * 0.6
				b.pos = C + Vector2(cos(b.a), sin(b.a)) * g[0] + Vector2(cos(b.b), sin(b.b)) * g[1]
				b.trail.append(b.pos)
				if b.trail.size() > 220:
					b.trail.pop_front()
			"center":
				b.pos = C
			"fly":
				var k := 1.0 - exp(-dt * 7.0)
				b.pos += (b.tx - b.pos) * k
				if b.pos.distance_to(b.tx) < 1.0:
					b.pos = b.tx
					b.mode = b.after
			"orbit":
				b.ang += dt * 0.9 * pow(62.0 / b.rad, 1.5)
				b.pos = C + Vector2(cos(b.ang), sin(b.ang)) * b.rad


# ---------------------------------------------------------------- drawing
func _draw_body(b: Dictionary, label: bool) -> void:
	var x: Vector2 = b.pos
	var r: float = b.r
	if b.id == "sun":
		Art.glow(self, x, r * 4.0, Color(1, 0.7, 0.2, 0.5))
		Art.glow(self, x, r * 2.2, Color(1, 0.9, 0.5, 0.8))
		Art.ball(self, x, r, Color("ffd23f"))
		return
	if b.id == "saturn":
		Art.ellipse_line(self, x, r * 1.9, r * 0.6, Color("cdb67a"), 3.0, -0.35, PI, TAU)
	Art.ball(self, x, r, b.col)
	if b.id == "earth":
		for c in [[-0.35, -0.2, 0.42], [0.3, 0.3, 0.33], [0.2, -0.45, 0.22]]:
			draw_circle(x + Vector2(c[0], c[1]) * r, c[2] * r, Color(0.3, 0.68, 0.31, 0.9))
	elif b.id == "jupiter":
		for dy in [-0.5, -0.1, 0.3, 0.6]:
			var w := sqrt(maxf(0.0, 1.0 - dy * dy)) * r
			draw_line(x + Vector2(-w, dy * r), x + Vector2(w, dy * r), Color(0.55, 0.31, 0.16, 0.45), r * 0.16)
		Art.ellipse(self, x + Vector2(r * 0.35, r * 0.38), r * 0.2, r * 0.12, Color("c0583a"))
	elif b.id == "mars":
		Art.ellipse(self, x + Vector2(0, -r * 0.8), r * 0.5, r * 0.18, Color(1, 1, 1, 0.9))
	if b.id == "saturn":
		Art.ellipse_line(self, x, r * 1.9, r * 0.6, Color("e3cf94"), 3.0, -0.35, 0, PI)
	if label:
		txt(x + Vector2(0, maxf(r, 14) + 20), b.p.name, 13, Color("d8d3e6"))


func _dashed_circle(c: Vector2, r: float, col: Color, w: float, dash := 6.0, gap := 8.0) -> void:
	var circ := TAU * r
	var n := int(circ / (dash + gap))
	for i in n:
		var a0 := float(i) / n * TAU
		var a1 := a0 + dash / r
		draw_arc(c, r, a0, a1, 4, col, w, true)


func paint() -> void:
	if phase == "intro":
		draw_rect(big_rect(), Color("efe6cf"))
		Art.glow(self, C, 620, Color(1, 0.995, 0.96, 1))
		var pulse := 1.0 + sin(t * 2.2) * 0.06 + (sin(t * 6.0) * 0.03 if can_orb else 0.0)
		Art.glow(self, C, 230 * pulse, Color(1, 0.88, 0.55, 0.7))
		light(C, 70 * pulse, {"look": (mouse() - C) / 300.0})
		if can_orb:
			for i in 24:
				var a := t * 0.5 + i * TAU / 24
				draw_arc(C, 110, a, a + 0.14, 4, Color(0.78, 0.59, 0.16, 0.4 + 0.3 * sin(t * 4.0)), 3.0, true)
		return
	if phase == "bang":
		var k := minf(1.0, bang_t / 1.6)
		draw_rect(big_rect(), Color(1, 0.99, 0.96).lerp(Color("07060d"), k))
		Art.draw_stars(self, stars, t, maxf(0.0, (bang_t - 1.2) / 2.0))
		Art.glow(self, C, bang_t * 700 + 1, Color(1, 1, 1, maxf(0.0, 1.0 - bang_t / 1.4)))
		for p in parts:
			if p.life > 0:
				var c: Color = p.c
				c.a = minf(1.0, p.life)
				draw_circle(p.p, p.s, c)
		return
	draw_rect(big_rect(), Color("07060d"))
	Art.glow(self, Vector2(120, 520), 380, Color(0.3, 0.2, 0.55, 0.16))
	Art.glow(self, Vector2(520, 120), 320, Color(0.15, 0.3, 0.6, 0.14))
	Art.draw_stars(self, stars, t)
	var a := sys_a
	for b in bodies:
		if b.trail.size() > 1:
			var col := Color(1, 0.82, 0.25, 0.35 * a) if b.id == "sun" else Color(0.7, 0.67, 0.86, 0.28 * a)
			draw_polyline(PackedVector2Array(b.trail), col, 1.5, true)
	if ring_a > 0:
		for i in RINGS.size():
			var done := false
			for b in bodies:
				if b.mode == "orbit" and b.rad == RINGS[i]:
					done = true
			var col := Color(0.78, 0.76, 0.9, 0.35 * ring_a)
			if ring_flash[i] > 0:
				col = Color(1, 0.35, 0.27, 0.4 + ring_flash[i] * 0.6)
			elif done:
				col = Color(1, 0.82, 0.25, 0.45 * ring_a)
			if done:
				draw_arc(C, RINGS[i], 0, TAU, 96, col, 2.0, true)
			else:
				_dashed_circle(C, RINGS[i], col, 3.0 if ring_flash[i] > 0 else 2.0)
	if phase == "sun" and sun.mode == "geo":
		draw_arc(sun.pos, sun.r + 14 + sin(t * 5.0) * 3.0, 0, TAU, 40, Color(1, 0.82, 0.25, 0.5 + 0.4 * sin(t * 5.0)), 2.5, true)
	if phase in ["order", "moving"]:
		Art.round_rect(self, Rect2(4, 574, 592, 92), 14, Color(1, 1, 1, 0.05))
	var held = hold if hold != null else grab
	if held == null or held.id != "sun":
		_draw_body(sun, false)
	for b in bodies:
		if (held != null and b.id == held.id) or b.id == "sun" or b.mode == "hidden":
			continue
		_draw_body(b, b.mode == "tray")
	if held != null:
		_draw_body(held, false)
	light(Vector2(58, 58 + sin(t * 1.6) * 5.0), 20, {"mic": mic_t > 0})
	if flash > 0:
		draw_rect(big_rect(), Color(1, 1, 1, flash))
