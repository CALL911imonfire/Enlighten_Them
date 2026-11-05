extends Stage
## Chapter 2: pump the flat Earth round. Pump too fast and it pops.

const E := Vector2(250, 300)
const PUMP_X := 500.0
const PUMP_TOP := 380.0
const PUMP_BOTTOM := 560.0
const STROKE := 70.0
const NOZZLE_REST := Vector2(430, 600)

var phase := "talk"
var stars: Array
var inflate := 0.0
var shown := 0.0
var pressure := 0.0
var handle := 0.0
var armed := false
var wob := 0.0
var nozzle := NOZZLE_REST
var nozzle_mode := "rest"
var hit := {}
var over_t := 0.0
var over_i := 0
var pops := 0
var bits: Array = []
var pop_t := 0.0
var auto_t := -1.0
var auto_queued := false
var grab := ""
var grab_start := Vector2.ZERO
var grab_off := 0.0
var grab_moved := false
var hold := false
var show_pump := false
var lt := Vector2(60, 60)
var drops: Array = []


func setup() -> void:
	VW = 600
	VH = 672
	stars = Art.make_stars(240, Rect2(-500, -200, 1600, 1100), 5)
	for i in 14:
		drops.append({"a": i / 14.0 * TAU, "o": randf()})


func begin() -> void:
	await Dialog.say(["...", "Oh no.", "Why is it flat?",
		"Okay. So. Here's their Earth.", "It's flat. Well, it isn't. But that's what they believe.",
		"Look at these humans. They've built pyramids. Aqueducts. Very good sandwiches.",
		"They keep doing things everyone said were impossible. And they still don't know the shape of the ground they're standing on.",
		"Please, enlighten them. Here, take this pump.", "!pump",
		"Oh, and don't mention that I sent you. That didn't turn out so well last time.",
		"Hook the hose up to the valve on the edge of the Earth. Drag the nozzle there, or click it and then click the valve."], _cue)
	phase = "hose"


func _cue(c: String) -> void:
	if c == "pump":
		show_pump = true
		Sfx.tone(660, 0.1, 0.05)


# ---------------------------------------------------------------- shape
func _ease(k: float) -> float:
	return 2.0 * k * k if k < 0.5 else 1.0 - pow(-2.0 * k + 2.0, 2.0) / 2.0


func _shape() -> Dictionary:
	var k := _ease(minf(1.0, shown))
	var squish := 1.0 + sin(t * 22.0) * 0.05 * wob
	return {"rx": (224.0 - 84.0 * k) / sqrt(squish), "ry": (62.0 + 78.0 * k) * squish, "edge": 16.0 * (1.0 - k), "k": k}


func _valve() -> Vector2:
	var s := _shape()
	return Vector2(E.x + s.rx + 6, E.y)


func _handle_y() -> float:
	return PUMP_TOP - 30.0 + handle * STROKE


func _on_handle(p: Vector2) -> bool:
	return absf(p.x - PUMP_X) < 60 and absf(p.y - _handle_y()) < 28


func _on_pump(p: Vector2) -> bool:
	return absf(p.x - PUMP_X) < 40 and p.y > PUMP_TOP - 60 and p.y < PUMP_BOTTOM


# ---------------------------------------------------------------- input
func click(p: Vector2) -> void:
	if busy():
		return
	if phase == "hose":
		if hold:
			hold = false
			_try_connect(p)
			return
		if p.distance_to(nozzle) < 30:
			grab = "nozzle"
			grab_start = p
			grab_moved = false
			Sfx.tone(660, 0.05, 0.04)
		return
	if phase == "pump":
		if _on_handle(p):
			if handle < 0.15:
				armed = true
			grab = "handle"
			grab_start = p
			grab_moved = false
			grab_off = p.y - _handle_y()
		elif _on_pump(p):
			_auto_stroke()


func drag(p: Vector2) -> void:
	if grab == "nozzle":
		if p.distance_to(grab_start) > 6:
			grab_moved = true
		nozzle = p
	elif grab == "handle":
		if absf(p.y - grab_start.y) > 6:
			grab_moved = true
		_set_handle((p.y - grab_off - (PUMP_TOP - 30.0)) / STROKE)
	elif hold:
		nozzle = p


func release(p: Vector2) -> void:
	if grab == "":
		return
	var g := grab
	grab = ""
	if g == "nozzle":
		if grab_moved:
			_try_connect(p)
		else:
			hold = true
	elif g == "handle" and not grab_moved:
		_auto_stroke()


func key(code: int) -> void:
	if code == KEY_SPACE and phase == "pump" and not busy():
		_auto_stroke()


func _try_connect(p: Vector2) -> void:
	if p.distance_to(_valve()) < 40:
		nozzle_mode = "attached"
		phase = "talk"
		Sfx.tone(880, 0.12, 0.06)
		Sfx.tone(1320, 0.15, 0.05, "triangle", 0.08)
		await Dialog.say(["Click. Good.", "Now pump. Drag the handle, click the pump, or press Space. Gently. Planets are delicate."])
		phase = "pump"
	else:
		nozzle_mode = "rest"
		nozzle = NOZZLE_REST
		Dialog.quip("The valve. The little silver nub on the edge of the Earth.", true)


func _set_handle(h: float) -> void:
	h = clampf(h, 0.0, 1.0)
	if h < 0.15:
		armed = true
	if armed and h > 0.85:
		armed = false
		_pump_puff()
	handle = h


func _auto_stroke() -> void:
	if auto_t >= 0.0:
		auto_queued = true
		return
	auto_t = 0.0


func _pump_puff() -> void:
	if phase != "pump":
		return
	if pressure > 1.0:
		_pop()
		return
	var add := 0.24 if Game.settings.relaxed else 0.3
	pressure += add
	wob = 1.0
	Sfx.noise(0.18, 1400, 0.5)
	if pressure > 1.0:
		pressure = minf(pressure, 1.12)
		over_t = 1.2
		Sfx.noise(1.1, 5000, 0.35, "high")
		Dialog.quip(["Easy! It's in the red. One more pump and it pops.", "Red means stop! It's a planet, not a pool float.", "Careful! Isaac Newton did not die for this."][over_i % 3], true)
		over_i += 1
		return
	inflate = minf(1.0, inflate + 0.065)
	Sfx.tone(300 + inflate * 500, 0.12, 0.03, "sine")
	for v in [[0.25, "Ooh, it's working. Flat Earthers, look away."], [0.5, "Halfway round. Or halfway flat, if you're a pessimist."], [0.75, "Almost a sphere. Some of them are going to be SO mad."]]:
		if inflate >= v[0] and not hit.has(v[0]):
			hit[v[0]] = true
			Dialog.quip(v[1], true)
	if inflate >= 1.0:
		phase = "talk"
		_finish()


func _pop() -> void:
	phase = "popped"
	pop_t = 1.0
	pops += 1
	over_t = 0.0
	var s := _shape()
	var cols := [Color("3a86d4"), Color("4caf50"), Color("6fb3f2"), Color("8d6e4a"), Color.WHITE]
	for i in 180:
		var a := randf() * TAU
		var sp := 80.0 + randf() * 380.0
		bits.append({"p": E + Vector2(cos(a) * s.rx * 0.6, sin(a) * s.ry * 0.6), "v": Vector2(cos(a), sin(a)) * sp, "life": 1.0 + randf(), "c": cols[i % 5]})
	inflate = 0.0
	shown = 0.0
	pressure = 0.0
	wob = 3.0
	Sfx.noise(0.9, 600, 1.2, "low")
	Sfx.tone(70, 0.8, 0.25, "sine")
	shake = 0.6
	await wait(1.1)
	var lines: Array
	if pops == 1:
		lines = ["...", "Well. You probably just killed millions of living beings.", "But that's okay. They're pretty resilient.",
			"You should have seen what I did to the dinosaurs. They never came back after that one.", "Hold on. Let me patch that up."]
	elif pops == 2:
		lines = ["Again?", "The cockroaches are fine, if you were wondering. They're always fine.", "Patching..."]
	else:
		lines = ["You know the gauge has a red part for a reason, right?", "Patch number %d. I'm running out of tape." % pops]
	await Dialog.say(lines)
	phase = "sealing"
	for i in 3:
		Sfx.tone([660, 880, 1175][i], 0.25, 0.05, "sine", i * 0.1)
	await wait(1.2)
	await Dialog.say(["There. Good as new. Mostly.", "Try again. Gently this time. Watch the gauge."])
	phase = "pump"


func _finish() -> void:
	await wait(0.9)
	Sfx.chime()
	await Dialog.say(["There. Round. Beautiful.", "Some of them still won't believe it. You can't win them all.", "Let's get a closer look."])
	finish(E + Vector2(-20, -10))


# ---------------------------------------------------------------- update
func tick(dt: float) -> void:
	var fix := phase == "popped" or phase == "sealing"
	var target := E + Vector2(-40, -95) if fix else Vector2(60, 60)
	lt += (target - lt) * (1.0 - exp(-dt * 3.0))
	var bleed := 0.3 - 0.12 * inflate
	if Game.settings.relaxed:
		bleed *= 1.25
	pressure = maxf(0.0, pressure - dt * bleed)
	if over_t > 0:
		over_t -= dt
		inflate = maxf(0.0, inflate - dt * 0.12)
	shown += (inflate - shown) * (1.0 - exp(-dt * 6.0))
	wob = maxf(0.0, wob - dt * 1.8)
	if auto_t >= 0.0:
		auto_t += dt / 0.32
		var h := auto_t * 2.0 if auto_t < 0.5 else 2.0 - auto_t * 2.0
		if auto_t < 0.5:
			armed = true
		_set_handle(0.0 if auto_t >= 1.0 else h)
		if auto_t >= 1.0:
			auto_t = 0.0 if auto_queued else -1.0
			auto_queued = false
	elif grab != "handle" and phase == "pump":
		handle = maxf(0.0, handle - dt * 2.0)
		if handle < 0.15:
			armed = true
	if nozzle_mode == "attached":
		nozzle = _valve()
	pop_t = maxf(0.0, pop_t - dt * 1.4)
	for b in bits:
		b.p += b.v * dt
		b.v.y += 60 * dt
		b.v.x *= 0.98
		b.life -= dt
	bits = bits.filter(func(b): return b.life > 0)


# ---------------------------------------------------------------- drawing
func _land(x: Vector2, rx: float, ry: float, k: float) -> void:
	for e in [[-0.35, -0.15, 0.38, 0.5], [0.05, -0.3, 0.32, 0.38], [0.3, 0.05, 0.3, 0.45], [-0.1, 0.25, 0.28, 0.35], [-0.5, 0.25, 0.15, 0.25]]:
		Art.ellipse(self, x + Vector2(e[0] * rx, e[1] * ry), e[2] * rx, e[3] * ry, Color("4caf50"))
	for e in [[0.1, -0.1, 0.08, 0.1], [-0.25, 0.05, 0.06, 0.12]]:
		Art.ellipse(self, x + Vector2(e[0] * rx, e[1] * ry), e[2] * rx, e[3] * ry, Color("8d6e4a"))
	for e in [[-0.2, -0.32, 0.05], [0.28, -0.1, 0.04]]:
		Art.ellipse(self, x + Vector2(e[0] * rx, e[1] * ry), e[2] * rx, e[2] * rx * 0.6, Color(1, 1, 1, 0.8))
	if k < 0.5:
		var a := 1.0 - k * 2.0
		for h in [[-0.4, -0.05], [0.15, -0.15], [0.32, 0.15], [-0.15, 0.2]]:
			var hp := x + Vector2(h[0] * rx, h[1] * ry)
			draw_rect(Rect2(hp + Vector2(-3, -6), Vector2(6, 6)), Color(1, 0.97, 0.9, a))
			draw_colored_polygon(PackedVector2Array([hp + Vector2(-5, -6), hp + Vector2(0, -11), hp + Vector2(5, -6)]), Color(0.75, 0.25, 0.2, a))


func _draw_earth() -> void:
	var s := _shape()
	var rx: float = s.rx
	var ry: float = s.ry
	var k: float = s.k
	var edge: float = s.edge
	var x := E
	if k < 0.9:
		for d in drops:
			var a: float = d.a + t * 0.2
			if sin(a) < 0:
				continue
			var ep := x + Vector2(cos(a) * rx, sin(a) * ry + edge)
			var len := (30.0 + 20.0 * sin(t * 3.0 + d.o * 7.0)) * (1.0 - k)
			Art.vgrad(self, Rect2(ep + Vector2(-2, 0), Vector2(4, len)), Color(0.55, 0.78, 1, 0.55 * (1 - k)), Color(0.55, 0.78, 1, 0))
	if edge > 0.5:
		Art.ellipse(self, x + Vector2(0, edge), rx, ry, Color("5b3a1e"))
		draw_rect(Rect2(x.x - rx, x.y, rx * 2, edge), Color("5b3a1e"))
		for i in 6:
			var yy := x.y + edge * (i + 0.5) / 6.0
			draw_line(Vector2(x.x - rx, yy), Vector2(x.x + rx, yy), Color(0, 0, 0, 0.12), 1.0)
	# ocean: shaded disc that becomes a lit sphere
	var pts := Art.ellipse_pts(x, rx, ry, 0, 48)
	var cols := PackedColorArray()
	var lightp := x + Vector2(-rx * 0.35, -ry * 0.4) * k
	for p in pts:
		var d := clampf((p - lightp).length() / (maxf(rx, ry) * 1.6), 0, 1)
		cols.append(Color("6fb3f2").lerp(Color("1d4f8f"), d) if k > 0.2 else Color("3a86d4").lerp(Color("2f78c4"), d))
	var center_col := Color("8cc6ff") if k > 0.2 else Color("3a86d4")
	# fan from the light point for a soft gradient
	for i in pts.size():
		var j := (i + 1) % pts.size()
		draw_polygon(PackedVector2Array([lightp, pts[i], pts[j]]), PackedColorArray([center_col, cols[i], cols[j]]))
	_land(x, rx, ry, k)
	for i in pops:
		if phase == "popped" and i == pops - 1:
			break
		var u: float = [0.45, -0.55, 0.1, -0.2, 0.6][i % 5]
		var v: float = [-0.35, 0.4, 0.55, -0.6, 0.2][i % 5]
		var pp := x + Vector2(u * rx, v * ry)
		var w := maxf(12.0, rx * 0.16)
		var h := maxf(5.0, ry * 0.08)
		for ang in [0.5, PI / 2 + 0.5]:
			draw_set_transform_matrix(cam * Transform2D(ang, pp))
			draw_rect(Rect2(-w / 2, -h / 2, w, h), Color("e9cfa3"))
			draw_set_transform_matrix(cam)
		draw_circle(pp, h * 0.35, Color(0.47, 0.31, 0.16, 0.5))
	if k > 0.3:
		# night side shadow and atmosphere rim
		Art.ellipse_line(self, x, rx, ry, Color(0.6, 0.85, 1, 0.35 * k), 4.0)
		Art.glow(self, x, maxf(rx, ry) * 1.35, Color(0.4, 0.7, 1, 0.12 * k))
	if k < 0.5:
		Art.ellipse_line(self, x, rx, ry, Color(0.91, 0.95, 1, 1.0 - k * 2.0), 6.0)
	var v := _valve()
	draw_rect(Rect2(v + Vector2(-6, -7), Vector2(12, 14)), Color("c9ced6"))
	draw_rect(Rect2(v + Vector2(4, -4), Vector2(6, 8)), Color("8a929c"))
	if phase == "hose":
		draw_arc(v, 18 + sin(t * 5.0) * 3.0, 0, TAU, 32, Color(1, 0.82, 0.25, 0.5 + 0.4 * sin(t * 5.0)), 2.5, true)


func _draw_pump() -> void:
	if not show_pump:
		return
	var x := PUMP_X
	var hy := _handle_y()
	var hose := PackedVector2Array()
	var p0 := Vector2(x, PUMP_BOTTOM - 8)
	var c1 := Vector2(x - 20, PUMP_BOTTOM + 70)
	var c2 := nozzle + Vector2(40, 80)
	for i in 25:
		var k := i / 24.0
		hose.append(p0.bezier_interpolate(c1, c2, nozzle, k))
	draw_polyline(hose, Color("2b2b2b"), 9.0, true)
	draw_polyline(hose, Color("444444"), 4.0, true)
	draw_circle(nozzle, 8, Color("d9d9d9"))
	if phase == "hose" and nozzle_mode == "rest" and not hold and grab == "":
		draw_arc(nozzle, 16, 0, TAU, 24, Color(1, 0.82, 0.25, 0.5 + 0.4 * sin(t * 5.0)), 2.5, true)
	draw_rect(Rect2(x - 4, hy, 8, PUMP_TOP - hy + 10), Color("9aa3ad"))
	Art.round_rect(self, Rect2(x - 50, hy - 12, 100, 22), 10, Color("e04f3a"))
	Art.vgrad(self, Rect2(x - 24, PUMP_TOP, 48, PUMP_BOTTOM - PUMP_TOP), Color("ef6a52"), Color("b83a28"))
	draw_rect(Rect2(x - 18, PUMP_TOP + 6, 8, PUMP_BOTTOM - PUMP_TOP - 12), Color(1, 1, 1, 0.18))
	draw_rect(Rect2(x - 40, PUMP_BOTTOM, 80, 10), Color("3a3a3a"))
	draw_rect(Rect2(x - 30, PUMP_BOTTOM - 6, 60, 8), Color("3a3a3a"))
	var g := Vector2(x, PUMP_TOP + 60)
	var gr := 24.0
	draw_circle(g, gr + 3, Color("555555"))
	draw_circle(g, gr, Color("f4efe2"))
	var a0 := PI * 0.8
	var redstart := PI * (0.8 + 1.4 / 1.15)
	draw_arc(g, gr - 6, a0, PI * 1.75, 16, Color("5bc27a"), 6.0)
	draw_arc(g, gr - 6, PI * 1.75, redstart, 8, Color("f2b632"), 6.0)
	draw_arc(g, gr - 6, redstart, PI * 2.2, 8, Color("e0412f"), 6.0)
	var na := a0 + minf(1.15, pressure) / 1.15 * PI * 1.4 + (sin(t * 50.0) * 0.08 if over_t > 0 else 0.0)
	draw_line(g, g + Vector2(cos(na), sin(na)) * (gr - 4), Color("222222"), 2.5, true)
	draw_circle(g, 3, Color("222222"))
	if phase == "pump":
		txt(Vector2(300, 625), "Drag the handle, click the pump, or press Space", 14, Color("a39fb5"))
		draw_rect(Rect2(60, 560, 280, 10), Color(1, 1, 1, 0.12))
		draw_rect(Rect2(60, 560, 280 * shown, 10), Color("ffcf5a"))
		txt(Vector2(200, 552), "Roundness", 14, Color("a39fb5"))


func paint() -> void:
	draw_rect(big_rect(), Color("07060d"))
	Art.glow(self, Vector2(80, 560), 360, Color(0.3, 0.2, 0.55, 0.15))
	Art.draw_stars(self, stars, t)
	var saved := cam
	if pop_t > 0:
		var sh := Vector2((randf() - 0.5) * 18 * pop_t, (randf() - 0.5) * 18 * pop_t)
		Art.cam = Transform2D(0, sh) * cam
		draw_set_transform_matrix(Art.cam)
	if phase == "popped":
		var s := _shape()
		Art.ellipse(self, E, s.rx * 0.5, 6, Color("2f78c4"))
	else:
		_draw_earth()
	for b in bits:
		var c: Color = b.c
		c.a = minf(1.0, b.life)
		draw_rect(Rect2(b.p, Vector2(4, 4)), c)
	if phase == "sealing":
		var s2 := _shape()
		for i in 8:
			var a := i / 8.0 * TAU + t * 3.0
			draw_line(E + Vector2(cos(a) * (s2.rx + 10), sin(a) * 70), E + Vector2(cos(a) * (s2.rx + 26), sin(a) * 86), Color(1, 0.91, 0.66, 0.8), 3.0)
	_draw_pump()
	Art.cam = saved
	draw_set_transform_matrix(cam)
	var fixing := phase == "popped" or phase == "sealing"
	light(lt + Vector2(0, sin(t * 1.6) * 5.0 + (sin(t * 14.0) * 3.0 if phase == "sealing" else 0.0)), 20, {"hat": fixing, "look": (E - lt) / 200.0})
	if over_t > 0:
		draw_rect(big_rect(), Color(0.88, 0.25, 0.18, over_t * 0.15))
