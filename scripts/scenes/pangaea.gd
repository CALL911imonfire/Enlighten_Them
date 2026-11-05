extends Stage
## Chapter 3: drill Pangaea apart along the fault lines with a wobbly drill.

# N North America, E Eurasia, S South America, A Africa, U Australia, T Antarctica, # cracked rock
const MAP := [
	"..NNNN#EEEEEE...",
	".NNNNN#EEEEEEEE.",
	".NNNNN#EEEEEEEE.",
	"..NNN##EEEEEEE..",
	"...###.####EEE..",
	"..SSS#AAA#####..",
	"..SSS#AAAA#UU...",
	"...SS#AAA##UU...",
	"....##AA##UU....",
	".....####.......",
	"....TTTTTT......",
	".....TTTT.......",
]
const FAULTS := [
	[[6, 0], [6, 1], [6, 2], [6, 3], [5, 3], [5, 4], [4, 4], [3, 4]],
	[[7, 4], [8, 4], [9, 4], [10, 4], [10, 5], [11, 5], [12, 5], [13, 5]],
	[[5, 5], [5, 6], [5, 7], [5, 8], [5, 9], [6, 9], [7, 9], [8, 9]],
	[[10, 6], [9, 7], [9, 8], [8, 8], [8, 9]],
]
const HS := 19.0
const SQ := 1.7320508
const CONT := {
	"N": {"name": "North America", "drift": Vector2(-55, -55), "hue": 0.27, "chip": "That was a chunk of Canada. They'll probably apologize to you for it.",
		"free": "North America, drifting west. It'll be fine. Mostly."},
	"E": {"name": "Eurasia", "drift": Vector2(55, -60), "hue": 0.22, "chip": "You just drilled into Europe. They've had wars over less.",
		"free": "Funny. Later on, the Europeans got the opposite problem. They couldn't stay in their continent. Couldn't hold it in. Ended up on every other one. In. Continent. Get it? ...Tough crowd."},
	"S": {"name": "South America", "drift": Vector2(-80, 55), "hue": 0.32, "chip": "Careful! That was the Amazon. Probably.",
		"free": "South America slides away. Look how it still fits against Africa, like a puzzle piece. That's how the humans figured all this out."},
	"A": {"name": "Africa", "drift": Vector2(15, 30), "hue": 0.15, "chip": "Ow. That was part of Africa. It needed that.",
		"free": "♪ I bless the rains down in Africa... ♪", "mic": true},
	"U": {"name": "Australia", "drift": Vector2(95, 60), "hue": 0.09, "chip": "That was Australia. Everything there was trying to kill you anyway.",
		"free": "Australia, off on its own. That explains a lot about the animals."},
	"T": {"name": "Antarctica", "drift": Vector2(0, 95), "hue": 0.55, "chip": "You drilled into Antarctica. The penguins saw that.",
		"free": "Antarctica, heading south to chill. Literally."},
}
const GLAD := ["Another tsunami! And for once, it's not my fault.", "Look at that earthquake. Usually I get blamed for those.",
	"The humans call these 'acts of God.' Not this time, they're not.", "This is nice, actually. Being innocent for once."]
const LIGHT_LINES := ["OW! Hey! You're BORING me to death! Boring. Like a drill bore. ...Get it?", "Just kidding. I can't die.",
	"You should have seen the holes the humans drilled in the last guy I sent, though."]
const LIGHT_AGAIN := ["I put on a hard hat. That's how you know I'm serious.", "Still not dying. Still annoying.", "The fault lines are over THERE.", "Drill me one more time and I'm turning off gravity."]
const SWR := Rect2(40, 554, 150, 72)

var X0 := 0.0
var Y0 := 150.0
var tiles: Array = []
var paths: Array = []
var freed := {}
var phase := "talk"
var chips := 0
var sw := "hidden"
var sw_on := 0
var quake_t := 0.0
var rings: Array = []
var bits: Array = []
var scorch: Array = []
var popups: Array = []
var next_quake := 8.0
var glad_i := 0
var wob_level := 0.55
var light_hits := 0
var light_t := 0.0
var light_cd := 0.0
var drill_hat_t := 0.0
var on_light := false
var hat_t := 0.0
var mic_t := 0.0
var off_t := 0.0
var chip_cd := 0.0
var drilling := false
var toggle := false
var down_at := -1.0
var down_pos := Vector2.ZERO
var wob := Vector2.ZERO
var wob_v := Vector2.ZERO
var speed := 0.0
var last_mouse := Vector2.ZERO
var lt := Vector2(548, 556)
var lt_target := Vector2(548, 556)
var quake_intro := false
var off_once := false
var fish_on := false


func setup() -> void:
	VW = 600
	VH = 672
	X0 = (VW - HS * SQ * (16 + 0.5)) / 2.0 + HS * SQ / 2.0
	_build()


func _exit_tree() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.loop("drill", 0, "", 0)


func begin() -> void:
	await Dialog.say(["Hm.", "Why is all the land stuck together in one big lump?",
		"Oh, right. Here's Pangaea. All the land on Earth, stuck together in one big lump.",
		"Right now Earth only has one continent. So technically, it's in-continent. In. Continent. ...I'll see myself out.",
		"That giant ocean around it is Panthalassa. It's Greek for 'all sea.' Not my most creative name.",
		"Let's spread things out. Take this drill.",
		"This reminds me of a girl I used to date. Way too attached. I had to break it up.",
		"Drill along the dashed fault lines. Hold the mouse button, or click once to start and again to stop. It wobbles a bit, so keep it steady. Stay off the continents."])
	phase = "play"


func hex(c: int, r: int) -> Vector2:
	return Vector2(X0 + HS * SQ * (c + 0.5 * (r & 1)), Y0 + HS * 1.5 * r)


func _nbrs(c: int, r: int) -> Array:
	var d := [[1, 0], [-1, 0], [-1, -1], [0, -1], [-1, 1], [0, 1]] if r % 2 == 0 else [[1, 0], [-1, 0], [0, -1], [1, -1], [0, 1], [1, 1]]
	var out := []
	for o in d:
		var cc: int = c + o[0]
		var rr: int = r + o[1]
		if cc >= 0 and cc < 16 and rr >= 0 and rr < MAP.size():
			out.append([cc, rr])
	return out


func _build() -> void:
	tiles.clear()
	for r in MAP.size():
		for c in 16:
			var k: String = MAP[r][c]
			if k == ".":
				continue
			tiles.append({"c": c, "r": r, "k": k, "alive": true, "sink": 0.0, "shade": randf() * 0.12 - 0.06})
	freed.clear()
	for L in CONT:
		freed[L] = {"on": false, "d": 0.0}
	paths.clear()
	for ch in FAULTS:
		var pts := []
		for i in ch.size() - 1:
			var a := hex(ch[i][0], ch[i][1])
			var b := hex(ch[i + 1][0], ch[i + 1][1])
			var n := int(ceil(a.distance_to(b) / 4.0))
			for j in n:
				pts.append({"p": a.lerp(b, float(j) / n), "cut": false})
		pts.append({"p": hex(ch[-1][0], ch[-1][1]), "cut": false})
		paths.append({"tiles": ch, "pts": pts, "done": false})
	scorch.clear()
	chips = 0


func _tile(c: int, r: int):
	for k in tiles:
		if k.c == c and k.r == r:
			return k
	return null


# ---------------------------------------------------------------- input
func _on_switch(p: Vector2) -> bool:
	return sw != "hidden" and SWR.has_point(p)


func click(p: Vector2) -> void:
	if busy() or phase != "play":
		return
	if _on_switch(p):
		_player_toggle()
		return
	if toggle:
		_stop_drill()
		return
	down_at = t
	down_pos = p
	_start_drill()


func release(p: Vector2) -> void:
	if down_at < 0:
		return
	if t - down_at < 0.25 and p.distance_to(down_pos) < 8:
		toggle = true
	else:
		_stop_drill()
	down_at = -1.0


func _start_drill() -> void:
	drilling = true
	toggle = false


func _stop_drill() -> void:
	drilling = false
	toggle = false


func _tip() -> Vector2:
	return mouse() + wob


func _land_at(p: Vector2):
	var best = null
	var bd := HS * 0.95
	for k in tiles:
		if not k.alive or (k.k != "#" and freed[k.k].on):
			continue
		var d := p.distance_to(hex(k.c, k.r))
		if d < bd:
			bd = d
			best = k
	return best


func _near_path(p: Vector2) -> float:
	var bd := 1e9
	for P in paths:
		if P.done:
			continue
		for q in P.pts:
			bd = minf(bd, p.distance_to(q.p))
	return bd


func _wobble_level() -> float:
	if Game.settings.steady_hands:
		return 0.0
	return wob_level


func _drill_tick(dt: float) -> void:
	var m := mouse()
	speed = speed * 0.8 + m.distance_to(last_mouse) * 0.2
	last_mouse = m
	var W := _wobble_level() * (1.0 + (0.3 if sw == "on" else 0.0) + quake_t * 1.2) * (1.0 + minf(2.0, speed / 12.0))
	for ax in 2:
		wob_v[ax] += (randf() - 0.5) * 200.0 * W * dt * 7.7
		wob_v[ax] -= wob[ax] * 12.0 * dt
		wob_v[ax] *= exp(-3.0 * dt)
		wob[ax] += wob_v[ax] * dt
		if W == 0.0:
			wob[ax] *= 0.8
			wob_v[ax] = 0.0
	if not drilling or phase != "play":
		return
	var p := _tip()
	for P in paths:
		if P.done:
			continue
		var any := false
		for q in P.pts:
			if not q.cut and p.distance_to(q.p) < 11:
				q.cut = true
				any = true
		if any:
			var cut := 0
			for q in P.pts:
				if q.cut:
					cut += 1
			if float(cut) / P.pts.size() >= 0.93:
				_complete_path(P)
	on_light = p.distance_to(lt) < 26
	light_cd -= dt
	if on_light:
		drill_hat_t = 1.5
		light_t += dt
		if randf() < dt * 40:
			var a := randf() * TAU
			bits.append({"p": p, "v": Vector2(cos(a) * 140, sin(a) * 140 - 60), "life": 0.35, "c": Color("ffd84a")})
		if light_t > 0.25 and light_cd <= 0:
			light_t = 0
			if light_hits >= 1:
				light_cd = 6
				Dialog.quip(LIGHT_AGAIN[(light_hits - 1) % LIGHT_AGAIN.size()], true)
			else:
				light_cd = 15
				for i in range(LIGHT_LINES.size() - 1, -1, -1):
					Dialog.quip(LIGHT_LINES[i], true)
			light_hits += 1
		return
	light_t = 0
	chip_cd -= dt
	var k = _land_at(p)
	if k != null and k.k != "#" and _near_path(p) > 14:
		off_t += dt
		if off_t > 0.3 and chip_cd <= 0:
			off_t = 0
			chip_cd = 1.2
			_chip(k, p)
	else:
		off_t = maxf(0, off_t - dt)
	if randf() < dt * 25:
		var a := randf() * TAU
		var col := Color("6b8f4e") if (k != null and k.k != "#") else Color("9a9488")
		bits.append({"p": p, "v": Vector2(cos(a) * 60, sin(a) * 60 - 40), "life": 0.4, "c": col})


func _chip(k: Dictionary, p: Vector2) -> void:
	chips += 1
	scorch.append({"p": p, "s": randf() * 7})
	Sfx.tone(140, 0.25, 0.07, "sawtooth")
	Sfx.noise(0.15, 900, 0.5)
	if chips >= 3:
		phase = "talk"
		hat_t = 99
		_stop_drill()
		await wait(0.4)
		await Dialog.say(["Okay, that's enough geography vandalism.", "Hold on. Let me glue it all back together.", "There. Try again. Stay on the lines this time."])
		hat_t = 0
		_build()
		phase = "play"
		return
	Dialog.quip(CONT[k.k].chip, true)


func _complete_path(P: Dictionary) -> void:
	P.done = true
	for ct in P.tiles:
		var k = _tile(ct[0], ct[1])
		if k != null and k.alive:
			k.alive = false
			k.sink = 1.0
			var q := hex(ct[0], ct[1])
			for i in 6:
				var a := randf() * TAU
				bits.append({"p": q, "v": Vector2(cos(a) * 90, sin(a) * 90 - 50), "life": 0.7, "c": Color("9a9488")})
	Sfx.noise(0.6, 300, 1.0, "low")
	_check_free()


func _check_free() -> void:
	var live := []
	for k in tiles:
		if k.alive and not (k.k != "#" and freed[k.k].on):
			live.append(k)
	var map := {}
	for k in live:
		map["%d,%d" % [k.c, k.r]] = k
	var seen := {}
	var newly := []
	for s in live:
		var key := "%d,%d" % [s.c, s.r]
		if seen.has(key):
			continue
		var comp := []
		var st := [s]
		seen[key] = true
		while st.size() > 0:
			var k = st.pop_back()
			comp.append(k)
			for n in _nbrs(k.c, k.r):
				var nk := "%d,%d" % [n[0], n[1]]
				if map.has(nk) and not seen.has(nk):
					seen[nk] = true
					st.append(map[nk])
		var letters := {}
		for k in comp:
			if k.k != "#":
				letters[k.k] = true
		if letters.size() == 0:
			for k in comp:
				k.alive = false
				k.sink = 1.0
		elif letters.size() == 1:
			newly.append(letters.keys()[0])
			for k in comp:
				if k.k == "#":
					k.alive = false
					k.sink = 1.0
	for L in newly:
		if not freed[L].on:
			freed[L].on = true
			_on_free(L)
	for P in paths:
		if P.done:
			continue
		var gone := true
		for ct in P.tiles:
			var k = _tile(ct[0], ct[1])
			if k != null and k.alive:
				gone = false
		if gone:
			P.done = true


# ---------------------------------------------------------------- disasters
func _disaster(at: Vector2, big: bool) -> void:
	if wob_level < 1.0:
		wob_level = 1.0
	quake_t = maxf(quake_t, 2.6 if big else 1.6)
	Sfx.noise(1.6, 110, 1.4, "low")
	for i in (4 if big else 3):
		rings.append({"p": at, "r": 8.0, "delay": i * 0.3, "max": 330.0 if big else 230.0})
	popups.append({"text": "EARTHQUAKE!", "p": at + Vector2((randf() - 0.5) * 60, -30), "t": 0.0})
	_tsunami(at)
	if sw_on >= 2 and sw == "on":
		Dialog.quip(GLAD[glad_i % GLAD.size()])
		glad_i += 1


func _tsunami(at: Vector2) -> void:
	await wait(0.6)
	popups.append({"text": "TSUNAMI!", "p": at + Vector2((randf() - 0.5) * 80, 40), "t": 0.0})
	Sfx.noise(1.2, 500, 0.6, "low")


func _cont_center(L: String) -> Vector2:
	var s := Vector2.ZERO
	var n := 0
	for k in tiles:
		if k.k == L:
			s += hex(k.c, k.r)
			n += 1
	var e := _ease(freed[L].d)
	return s / maxf(1, n) + CONT[L].drift * e


func _on_free(L: String) -> void:
	var c: Dictionary = CONT[L]
	var q := _cont_center(L)
	if sw == "hidden" or sw == "on":
		_disaster(q, true)
	else:
		Sfx.noise(1.6, 110, 1.0, "low")
	if not quake_intro:
		quake_intro = true
		phase = "talk"
		sw = "on"
		_stop_drill()
		await wait(1.0)
		await Dialog.say(["Uh oh.", "All that shifting is setting off earthquakes. And tsunamis. A plethora of them."])
		lt_target = Vector2(220, 580)
		await wait(0.9)
		await Dialog.say(["...Who left this on?"])
		_flip("off")
		await wait(0.5)
		await Dialog.say(["There. Disasters off. Carry on."])
		lt_target = Vector2(548, 556)
		phase = "play"
		_free_quip(c)
		_check_all()
		return
	_free_quip(c)
	_check_all()


func _free_quip(c: Dictionary) -> void:
	Dialog.quip(c.free)
	if c.get("mic", false):
		mic_t = 7.0


func _check_all() -> void:
	for L in freed:
		if not freed[L].on:
			return
	if phase == "done":
		return
	phase = "done"
	_stop_drill()
	await wait(3.6)
	_finish()


func _flip(state: String) -> void:
	sw = state
	Sfx.tone(1200, 0.05, 0.06, "square")
	Sfx.tone(800, 0.08, 0.05, "square", 0.06)
	if state == "off":
		quake_t = minf(quake_t, 0.3)


func _player_toggle() -> void:
	if sw == "off":
		if sw_on == 0:
			sw_on = 1
			_flip("on")
			phase = "talk"
			_stop_drill()
			_disaster(_cont_center("A"), false)
			await wait(0.7)
			await Dialog.say(["...Did you just turn natural disasters back ON?", "Of course. I finally get some help with the humans, and it's a sociopath. Just my luck."])
			lt_target = Vector2(220, 580)
			await wait(0.9)
			_flip("off")
			await Dialog.say(["Off. And it stays off."])
			lt_target = Vector2(548, 556)
			phase = "play"
			return
		if sw_on == 1:
			sw_on = 2
			wob_level = 1.6
			_flip("on")
			phase = "talk"
			_stop_drill()
			await wait(0.5)
			await Dialog.say(["Again?", "...Fine. Leave it on.", "But these deaths are on YOUR hands this time. Not mine."])
			phase = "play"
			next_quake = 3.0
			return
		_flip("on")
		Dialog.quip("Back on. Bold.", true)
		return
	_flip("off")
	Dialog.quip("Oh, NOW you feel bad." if (sw_on >= 2 and not off_once) else "Off. Good.", true)
	off_once = true


func _finish() -> void:
	for k in tiles:
		if k.alive and k.k == "#":
			k.alive = false
			k.sink = 1.0
	Sfx.chime()
	await Dialog.say(["See that? Panthalassa is becoming the Pacific. The Atlantic and Indian Oceans are pouring into the gaps.",
		"Normally this takes about 200 million years. You did it in a few minutes. Show-off.",
		"Hey. Want to see something funny?", "Follow me."])
	fish_on = true
	lt_target = _fish_pos() + Vector2(30, -30)
	await wait(1.4)
	finish(_fish_pos())


func _fish_pos() -> Vector2:
	return hex(6, 7) + CONT.A.drift + Vector2(-30, 8)


# ---------------------------------------------------------------- update
func _ease(x: float) -> float:
	return 2 * x * x if x < 0.5 else 1 - pow(-2 * x + 2, 2) / 2


func tick(dt: float) -> void:
	mic_t = maxf(0, mic_t - dt)
	drill_hat_t = maxf(0, drill_hat_t - dt)
	quake_t = maxf(0, quake_t - dt)
	_drill_tick(dt)
	var m := mouse()
	var show_drill := phase == "play" and not busy() and not _on_switch(m) and Rect2(0, 0, VW, VH).has_point(m)
	var want := Input.MOUSE_MODE_HIDDEN if show_drill else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != want and DisplayServer.get_name() != "headless":
		Input.mouse_mode = want
	if drilling and phase == "play" and not busy():
		var hit := on_light and drill_hat_t > 1.4
		if hit:
			Sfx.loop("drill", 560, "square", 0.05)
			if randf() < dt * 14:
				Sfx.tone(1800 + randf() * 1400, 0.05, 0.03, "square")
		else:
			Sfx.loop("drill", 95, "sawtooth", 0.06)
	else:
		Sfx.loop("drill", 0, "", 0)
	if sw == "on" and phase == "play":
		next_quake -= dt
		if next_quake <= 0:
			next_quake = 6 + randf() * 4
			var land := tiles.filter(func(k): return k.alive and k.k != "#")
			if land.size() > 0:
				var k = land.pick_random()
				_disaster(hex(k.c, k.r), false)
	for L in freed:
		if freed[L].on:
			freed[L].d = minf(1, freed[L].d + dt / 3.5)
	for k in tiles:
		if k.sink > 0:
			k.sink = maxf(0, k.sink - dt * 1.6)
	for r in rings:
		if r.delay > 0:
			r.delay -= dt
		else:
			r.r += dt * 150
	rings = rings.filter(func(r): return r.r < r.max)
	for p in popups:
		p.t += dt
	popups = popups.filter(func(p): return p.t < 1.6)
	for b in bits:
		b.p += b.v * dt
		b.v.y += 300 * dt
		b.life -= dt
	bits = bits.filter(func(b): return b.life > 0)
	lt += (lt_target - lt) * (1 - exp(-dt * 3))


# ---------------------------------------------------------------- drawing
func _hex_pts(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60 * i - 30)
		pts.append(c + Vector2(cos(a), sin(a)) * s)
	return pts


func _offset(k: Dictionary) -> Vector2:
	if k.k == "#":
		return Vector2.ZERO
	return CONT[k.k].drift * _ease(freed[k.k].d)


func _draw_tile(k: Dictionary) -> void:
	var q := hex(k.c, k.r) + _offset(k)
	var s := HS + 0.6
	var a := 1.0
	if not k.alive:
		if k.sink <= 0:
			return
		s *= k.sink
		a = k.sink
		q.y += (1 - k.sink) * 8
	var col: Color
	if k.k == "#":
		col = Color.from_hsv(0.11, 0.08, 0.5 + k.shade * 4)
	else:
		if freed[k.k].on:
			q.y += sin(t * 2 + k.c) * 0.6
		var hue: float = CONT[k.k].hue
		col = Color.from_hsv(hue + k.shade * 0.3, 0.45, 0.48 + k.shade * 2.5)
	col.a = a
	var pts := _hex_pts(q, s)
	draw_colored_polygon(pts, col)
	# a little relief: lighter top edge, darker bottom
	draw_polyline(PackedVector2Array([pts[3], pts[4], pts[5]]), Color(1, 1, 1, 0.12 * a), 1.5)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2]]), Color(0, 0, 0, 0.18 * a), 1.5)
	if k.k == "#" and k.alive:
		draw_line(q + Vector2(-6, -4), q + Vector2(2, 2), Color(0, 0, 0, 0.25), 1.0)
		draw_line(q + Vector2(2, 2), q + Vector2(5, 7), Color(0, 0, 0, 0.25), 1.0)


func _draw_paths() -> void:
	for P in paths:
		if P.done:
			continue
		var pts: Array = P.pts
		for i in range(0, pts.size() - 1, 3):
			var j := mini(i + 2, pts.size() - 1)
			draw_line(pts[i].p, pts[j].p, Color(1, 0.91, 0.66, 0.55 + 0.25 * sin(t * 3)), 2.5, true)
		for i in range(1, pts.size()):
			if pts[i].cut and pts[i - 1].cut:
				draw_line(pts[i - 1].p, pts[i].p, Color("2a1a10"), 6.0, true)
		draw_circle(pts[0].p, 4, Color("ffe9a8"))
		draw_circle(pts[-1].p, 4, Color("ffe9a8"))


func _draw_switch() -> void:
	if sw == "hidden":
		return
	var x := SWR.position.x + SWR.size.x / 2
	var by := SWR.position.y
	Art.round_rect(self, SWR, 6, Color("e9e4d6"))
	var hl := phase == "play" and _on_switch(mouse())
	draw_rect(SWR, Color("ffcf5a") if hl else Color("333333"), false, 2.0)
	txt(Vector2(x, by + 15), "ALLOW NATURAL DISASTERS", 9, Color("222222"))
	txt(Vector2(x, by + 26), "DURING PANGAEA PUZZLE", 9, Color("222222"))
	var on := sw == "on"
	Art.round_rect(self, Rect2(x - 26, by + 34, 52, 26), 13, Color("d64535") if on else Color("6b7280"))
	draw_circle(Vector2(x + 13 if on else x - 13, by + 47), 10, Color.WHITE)
	txt(Vector2(x - 12 if on else x + 12, by + 51), "ON" if on else "OFF", 10, Color("222222"))


func _draw_drill(p: Vector2) -> void:
	var j := (randf() - 0.5) * 2 if drilling else 0.0
	draw_set_transform_matrix(cam * Transform2D(-0.7, p + Vector2(j, j)))
	draw_colored_polygon(PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(0, 10)]), Color("c0c6ce"))
	draw_rect(Rect2(-3, -16, 6, 16), Color("9aa3ad"))
	if drilling:
		for i in 4:
			var yy := -16 + fmod(t * 80 + i * 4, 16)
			draw_line(Vector2(-3, yy), Vector2(3, yy + 2), Color("5c636b"), 1)
	Art.round_rect(self, Rect2(-11, -42, 22, 26), 4, Color("f2b632"))
	draw_rect(Rect2(-6, -16, 12, 4), Color("333333"))
	draw_rect(Rect2(8, -36, 14, 9), Color("333333"))
	draw_set_transform_matrix(cam)
	draw_arc(p, 5, 0, TAU, 16, Color("ffcf5a") if drilling else Color(1, 0.91, 0.66, 0.6), 1.5, true)


func paint() -> void:
	var qa := minf(1, quake_t) * 14
	if qa > 0:
		Art.cam = Transform2D(0, Vector2((randf() - 0.5) * qa, (randf() - 0.5) * qa)) * cam
		draw_set_transform_matrix(Art.cam)
	# ocean
	draw_rect(big_rect(), Color("0b2346"))
	Art.glow(self, Vector2(300, 320), 560, Color(0.14, 0.42, 0.66, 0.9))
	for i in 18:
		var y := -60 + i * 48
		var line := PackedVector2Array()
		for x in range(-700, 1320, 20):
			line.append(Vector2(x, y + sin(x / 40.0 + t + i) * (4 + quake_t * 6)))
		draw_polyline(line, Color(1, 1, 1, 0.05), 2.0)
	if phase != "done" or not fish_on:
		Art.text(self, Vector2(300, 645), "P a n t h a l a s s a", 16, Color(1, 1, 1, 0.28), 0, Art.serif())
	for r in rings:
		if r.delay > 0:
			continue
		var a := maxf(0, 1 - r.r / r.max)
		draw_arc(r.p, r.r, 0, TAU, 48, Color(0.86, 0.94, 1, a), 5 * a + 1, true)
		draw_arc(r.p, maxf(1, r.r - 8), 0, TAU, 48, Color(0.47, 0.75, 1, a * 0.6), 10 * a + 0.1, true)
	for k in tiles:
		_draw_tile(k)
	if not fish_on:
		for s in scorch:
			draw_circle(s.p, 7, Color(0.16, 0.08, 0.04, 0.75))
			for i in 4:
				var a: float = s.s + i * 1.6
				draw_line(s.p, s.p + Vector2(cos(a), sin(a)) * 13, Color(0.16, 0.08, 0.04, 0.75), 1.5)
		_draw_paths()
	for L in freed:
		var f: Dictionary = freed[L]
		if f.d < 0.4:
			continue
		var q := _cont_center(L)
		txt(q + Vector2(0, 4), CONT[L].name, 13, Color(1, 0.98, 0.91, minf(1, (f.d - 0.4) * 2.5)), 0, 3)
	for b in bits:
		var c: Color = b.c
		c.a = minf(1, b.life * 2)
		draw_rect(Rect2(b.p, Vector2(4, 4)), c)
	if fish_on:
		var fp := _fish_pos() + Vector2(0, sin(t * 3) * 1.5)
		Art.ellipse(self, fp, 7, 3.5, Color("ff9f43"))
		draw_colored_polygon(PackedVector2Array([fp + Vector2(-6, 0), fp + Vector2(-11, -3), fp + Vector2(-11, 3)]), Color("ff9f43"))
		draw_circle(fp + Vector2(4, -1), 0.9, Color.BLACK)
	Art.cam = cam
	draw_set_transform_matrix(cam)
	for p in popups:
		var s := minf(1, p.t * 6)
		var a: float = 1.0 if p.t <= 1.1 else 1 - (p.t - 1.1) / 0.5
		draw_set_transform_matrix(cam * Transform2D(-0.08, Vector2(s, s), 0, p.p - Vector2(0, p.t * 12)))
		var col := Color("ffcf5a") if p.text.begins_with("E") else Color("7fd3ff")
		col.a = maxf(0, a)
		Art.text(self, Vector2.ZERO, p.text, 28, col, 0, null, 6, Color(0.1, 0.06, 0.12, maxf(0, a)))
	draw_set_transform_matrix(cam)
	_draw_switch()
	light(lt + Vector2(0, sin(t * 1.6) * 5), 20, {"mic": mic_t > 0, "hat": hat_t > 0 or drill_hat_t > 0, "squint": on_light and drilling})
	if not fish_on:
		var dmg := ""
		for i in 3:
			dmg += "●" if i < chips else "○"
		txt(Vector2(16, 662), "Damage: " + dmg, 14, Color("d8d3e6"), -1)
	var m := mouse()
	if phase == "play" and not busy() and not _on_switch(m) and Rect2(0, 0, VW, VH).has_point(m):
		_draw_drill(_tip())
