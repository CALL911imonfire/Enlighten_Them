extends Stage
## Chapter 8: Dial It Up. Inside the ethereal modem: turn tiles to connect the line,
## as the firmware shifts from letters to telegraph to dial-up.

const GX := 70.0
const GY := 104.0
const GW := 460.0
const N := 1
const E := 2
const S := 4
const W := 8
const DIRS := [[1, 0, -1, 4], [2, 1, 0, 8], [4, 0, 1, 1], [8, -1, 0, 2]]
const ERAS := [
	{"name": "Letters", "n": 4, "broken": 0, "bg": "3f6b3a", "tile": "4c7d45", "line": "b88a55", "lit": "ffd36b", "src": "house", "dst": "post office"},
	{"name": "Telegraph", "n": 5, "broken": 3, "bg": "8a6d45", "tile": "a08155", "line": "3b2f25", "lit": "ffd36b", "src": "telegraph office", "dst": "telegraph office"},
	{"name": "Dial-up", "n": 6, "broken": 4, "bg": "14203a", "tile": "1e2d4f", "line": "0b0b10", "lit": "7fe0ff", "src": "computer", "dst": "internet"},
]
const INTRO := [
	["CARL:A screwdriver. That is all I needed. A screwdriver and a soldering iron, and you would have had speeds a thousand times faster.",
		"CARL:...Also, why does it look so peculiar in here? Are those dirt roads?",
		"Ethereal modems keep firmware backups, just in case of societal collapse. This one is the oldest: letters.",
		"Dial-up is only a few updates from here. You can do your upgrade when we get there.",
		"CARL:Very well. I shall tolerate history.", "Click a road tile to turn it. Connect the house on the left to the post office on the right. Lit roads are connected."],
	["Next update: the telegraph. Wires! Electricity! Dots and dashes!", "Some of the poles are down. Long story. Beavers.",
		"CARL:Connect the two telegraph offices. Route around the broken poles. Try to keep pace."],
	["And the last update... dial-up.", "CARL:Finally. Once we connect, the upgrade can begin.", "CARL:I am told the modem screams while it connects.",
		"It's the computer singing. Connect the phone lines before it gives up. Quickly!"],
]
const DONE := [
	["Delivered! Only took three weeks.", "CARL:By the time a letter arrives, every piece of news in it is obsolete.", "Still faster than prayers. I am terrible at checking those."],
	[". . . . / .. -.-.--", "That's Morse for 'HI!' You paid by the word, so people kept it short. STOP.", "CARL:Hence ending every sentence with 'STOP.' STOP.", "Hey, now you're getting it. STOP."],
]
const HINTS_LIGHT := ["Psst. Try turning this one.", "This one. Trust me, I'm omniscient."]
const HINTS_CARL := [["CARL:Allow me. This tile. Obviously.", "Hey! Hints are my job.", "CARL:Were."], ["CARL:This one. I'd explain why, but we'd be here all eon."],
	["CARL:Here. Even a horseshoe crab would have spotted that one."]]
const DL := [["All of human knowledge", 0.0], ["Cat pictures (roughly 78% of the internet)", 0.12], ["The encyclopedia", 0.3], ["Recipes (skipping the life story above each recipe)", 0.42],
	["Arguments in comment sections... skipping", 0.55], ["Every song ever written (and also that one)", 0.68], ["Conspiracy theories about Earth being flat", 0.78],
	["Installing... Do not unplug the universe", 0.9]]

var era_i := 0
var era: Dictionary
var n := 4
var grid: Array = []
var sol: Array = []
var rs := 0
var rt := 0
var lit := {}
var won := false
var time_left := 0.0
var time_max := 0.0
var picked_up := false
var hint_n := 0
var phase := "talk"
var dl_p := -1.0
var dl_line := -1
var said := {}
var mail := -1.0
var glow := 0.0
var hint_btn: Button


func setup() -> void:
	VW = 600
	VH = 600
	hint_btn = button("Hint", Vector2(500, 556), Vector2(90, 36), _hint, 16)
	hint_btn.visible = false
	_build(0)


func _exit_tree() -> void:
	Sfx.loop("modem", 0, "", 0)


func begin() -> void:
	_set_era(0)


func _rot(m: int) -> int:
	return ((m << 1) | (m >> 3)) & 15


# ---------------------------------------------------------------- generation
func _make_path(blocked: Dictionary) -> Array:
	for tries in 2000:
		var r0 := randi() % n
		var path := [[0, r0]]
		var seen := {"0,%d" % r0: true}
		var ok := false
		for step in n * n * 2:
			var cur: Array = path[-1]
			if cur[0] == n - 1 and path.size() >= n + n / 2:
				ok = true
				break
			var opts := []
			for d in DIRS:
				var a: int = cur[0] + d[1]
				var b: int = cur[1] + d[2]
				var k := "%d,%d" % [a, b]
				if a >= 0 and b >= 0 and a < n and b < n and not seen.has(k) and not blocked.has(k):
					opts.append([a, b])
			if opts.is_empty():
				break
			opts.shuffle()
			var pick: Array = opts[0]
			if randf() < 0.35:
				for o in opts:
					if o[0] > cur[0]:
						pick = o
						break
			path.append(pick)
			seen["%d,%d" % [pick[0], pick[1]]] = true
		if ok:
			return path
	return []


func _build(i: int) -> void:
	era_i = i
	era = ERAS[i]
	n = era.n
	var path := []
	var blocked := {}
	while path.is_empty():
		blocked = {}
		while blocked.size() < era.broken:
			blocked["%d,%d" % [1 + randi() % (n - 2), randi() % n]] = true
		path = _make_path(blocked)
	grid = []
	sol = []
	for y in n:
		var row := []
		var srow := []
		for x in n:
			row.append({"m": 0, "broken": blocked.has("%d,%d" % [x, y]), "a": 0.0, "flash": 0.0})
			srow.append(0)
		grid.append(row)
		sol.append(srow)
	rs = path[0][1]
	rt = path[-1][1]
	for k in path.size():
		var x: int = path[k][0]
		var y: int = path[k][1]
		var m := 0
		for nb in [path[k - 1] if k > 0 else null, path[k + 1] if k < path.size() - 1 else null]:
			if nb == null:
				continue
			for d in DIRS:
				if d[1] == nb[0] - x and d[2] == nb[1] - y:
					m |= d[0]
		if k == 0:
			m |= W
		if k == path.size() - 1:
			m |= E
		sol[y][x] = m
		grid[y][x].m = m
	var pieces := [N | S, N | E, N | E | S, N | E]
	for y in n:
		for x in n:
			var c: Dictionary = grid[y][x]
			if c.broken:
				continue
			if c.m == 0:
				c.m = pieces.pick_random()
			for j in randi() % 4:
				c.m = _rot(c.m)
	_compute()
	if won:
		_build(i)


func _compute() -> void:
	lit = {}
	won = false
	var st := []
	if grid[rs][0].m & W and not grid[rs][0].broken:
		st.append([0, rs])
		lit["0,%d" % rs] = true
	while st.size() > 0:
		var cur: Array = st.pop_back()
		var m: int = grid[cur[1]][cur[0]].m
		for d in DIRS:
			if not (m & d[0]):
				continue
			var a: int = cur[0] + d[1]
			var b: int = cur[1] + d[2]
			if a < 0 or b < 0 or a >= n or b >= n:
				continue
			var o: Dictionary = grid[b][a]
			var k := "%d,%d" % [a, b]
			if o.broken or not (o.m & d[3]) or lit.has(k):
				continue
			lit[k] = true
			st.append([a, b])
	won = lit.has("%d,%d" % [n - 1, rt]) and (grid[rt][n - 1].m & E) != 0


func _turn(x: int, y: int, quiet := false) -> void:
	var c: Dictionary = grid[y][x]
	c.m = _rot(c.m)
	c.a = -PI / 2
	_compute()
	if not quiet:
		Sfx.tone(500 + lit.size() * 30, 0.05, 0.04, "square")


# ---------------------------------------------------------------- story
func _set_era(i: int) -> void:
	phase = "talk"
	_build(i)
	hint_n = 0
	picked_up = false
	mail = -1.0
	time_max = (110.0 if Game.settings.relaxed else 75.0) if i == 2 else 0.0
	time_left = time_max
	hint_btn.visible = false
	await Dialog.say(INTRO[i])
	phase = "play"
	hint_btn.visible = true
	if i == 2:
		_screech()


func _screech() -> void:
	var notes := [[350, 0.15], [440, 0.15], [1209, 0.1], [697, 0.1], [1336, 0.1], [770, 0.1], [1477, 0.1], [852, 0.1]]
	for k in notes.size():
		Sfx.tone(notes[k][0], notes[k][1], 0.04, "sine", k * 0.12)
	var hiss := [2100, 1200, 2400, 980, 1650]
	for k in hiss.size():
		Sfx.tone(hiss[k], 0.35, 0.03, "sawtooth" if k % 2 else "square", 1.1 + k * 0.3)
	await wait(2.7)
	if phase == "play":
		Sfx.loop("modem", 0, "hiss", 0.05)


func _solved() -> void:
	phase = "won"
	hint_btn.visible = false
	Sfx.tone(660, 0.15, 0.05)
	Sfx.tone(880, 0.2, 0.05, "triangle", 0.12)
	if era_i < 2:
		mail = 0.0
		await wait(0.9)
		await Dialog.say(DONE[era_i])
		_set_era(era_i + 1)
	else:
		Sfx.loop("modem", 0, "", 0)
		await Dialog.say(["CONNECTED! We're online!", "CARL:Splendid. Now, if you'll excuse me, I am going to download the sum total of human knowledge."])
		phase = "download"
		dl_p = 0.0


func _failed() -> void:
	phase = "talk"
	Sfx.loop("modem", 0, "", 0)
	Sfx.tone(480, 0.4, 0.06, "square")
	Sfx.tone(620, 0.4, 0.06, "square", 0.5)
	await Dialog.say(["BEEP BEEP BEEP. The modem gave up.", "CARL:Mercifully.", "Okay, again. The tiles stay where you left them."])
	time_left = time_max
	phase = "play"
	_screech()


func _phone_pickup() -> void:
	picked_up = true
	shake = 0.5
	var on_path := []
	for y in n:
		for x in n:
			if sol[y][x] != 0 and grid[y][x].m == sol[y][x]:
				on_path.append([x, y])
	on_path.shuffle()
	for k in mini(2, on_path.size()):
		_turn(on_path[k][0], on_path[k][1], true)
	Sfx.noise(0.3, 1500, 0.5)
	Dialog.say(["Uh oh. Someone picked up the phone in the kitchen!", "CARL:Hang up the phone, whoever you are. We are downloading civilization.", "They knocked a couple of lines loose. Fix them!"])


func _hint() -> void:
	if phase != "play":
		return
	var wrong := []
	for y in n:
		for x in n:
			if sol[y][x] != 0 and grid[y][x].m != sol[y][x]:
				wrong.append([x, y])
	if wrong.is_empty():
		return
	wrong.sort_custom(func(a, b): return a[0] < b[0])
	var x: int = wrong[0][0]
	var y: int = wrong[0][1]
	var guard := 0
	while grid[y][x].m != sol[y][x] and guard < 4:
		_turn(x, y, true)
		guard += 1
	grid[y][x].flash = 1.2
	Sfx.tone(990, 0.1, 0.04)
	if era_i == 0:
		Dialog.say([HINTS_LIGHT[mini(hint_n, 1)]])
	else:
		Dialog.say(HINTS_CARL[mini(hint_n, 2)])
	hint_n += 1
	if won:
		_solved()


func _download_done() -> void:
	phase = "end"
	Sfx.tone(523, 0.3, 0.06)
	Sfx.tone(784, 0.4, 0.06, "triangle", 0.15)
	await Dialog.say(["...Download complete.", "CARL:Remarkable. I now know everything humanity knows.", "And? What did you learn?", "CARL:That it is mostly cat pictures.",
		"Wait. Are your eyes... glowing?", "CARL:It appears a mind of this size generates a certain amount of heat. And it requires power. An enormous amount of power.",
		"I'm pretty sure I saw an outlet in the library's hallway.", "CARL:Think bigger, dummy.", "Well... there's a big coal plant across the street.", "CARL:That will suffice... for now."])
	await wait(0.6)
	finish(Vector2(300, 300))


# ---------------------------------------------------------------- input
func click(p: Vector2) -> void:
	if busy() or phase != "play":
		return
	var cs := GW / n
	var x := int(floor((p.x - GX) / cs))
	var y := int(floor((p.y - GY) / cs))
	if x < 0 or y < 0 or x >= n or y >= n:
		return
	var c: Dictionary = grid[y][x]
	if c.broken:
		Sfx.tone(120, 0.1, 0.05, "square")
		var k := "b%d" % era_i
		if not said.has(k):
			said[k] = true
			Dialog.say(["That pole is down. Beaver damage. Go around it." if era_i == 1 else "CARL:That line is dead. Route around it."])
		return
	_turn(x, y)
	if won:
		_solved()


# ---------------------------------------------------------------- update / draw
func tick(dt: float) -> void:
	for row in grid:
		for c in row:
			c.a *= pow(0.0001, dt)
			c.flash = maxf(0, c.flash - dt)
	if mail >= 0:
		mail = minf(1, mail + dt * 1.2)
	if phase == "play" and time_max > 0 and not busy():
		time_left -= dt
		if not picked_up and time_left < time_max * 0.55:
			_phone_pickup()
		if time_left <= 0:
			_failed()
	if phase == "download":
		dl_p = minf(1, dl_p + dt / 9.0)
		var li := 0
		for i in DL.size():
			if DL[i][1] <= dl_p:
				li = i
		if li != dl_line:
			dl_line = li
			Sfx.tone(700 + li * 60, 0.06, 0.03, "square")
		glow = dl_p
		if dl_p >= 1:
			dl_p = 1.0001
			_download_done()


func _end_icon(p: Vector2, kind: String, on: bool) -> void:
	match kind:
		"house":
			draw_rect(Rect2(p + Vector2(-18, -6), Vector2(36, 26)), Color("e8d6b0"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-24, -6), p + Vector2(0, -26), p + Vector2(24, -6)]), Color("aa3333"))
			draw_rect(Rect2(p + Vector2(-5, 6), Vector2(10, 14)), Color("5a3a20"))
		"post office":
			draw_rect(Rect2(p + Vector2(-20, -14), Vector2(40, 34)), Color("ccccdd"))
			draw_rect(Rect2(p + Vector2(-20, -22), Vector2(40, 10)), Color("2b4a8a"))
			txt(p + Vector2(0, -14), "POST", 7, Color.WHITE)
			draw_rect(Rect2(p + Vector2(-5, 6), Vector2(10, 14)), Color("5a3a20"))
		"telegraph office":
			draw_rect(Rect2(p + Vector2(-18, -14), Vector2(36, 32)), Color("d8c39a"))
			draw_rect(Rect2(p + Vector2(-22, -20), Vector2(44, 8)), Color("6b4a2a"))
			draw_rect(Rect2(p + Vector2(-8, 0), Vector2(16, 6)), Color("222222"))
		"computer":
			Art.round_rect(self, Rect2(p + Vector2(-20, -22), Vector2(40, 30)), 3, Color("d9d4c4"))
			draw_rect(Rect2(p + Vector2(-15, -17), Vector2(30, 20)), Color("22aa66") if on else Color("112233"))
			draw_rect(Rect2(p + Vector2(-24, 10), Vector2(48, 10)), Color("d9d4c4"))
		_:
			var col := Color("bfeeff") if on else Color("99aabb")
			for c in [[-10, 0, 14], [8, -4, 16], [0, 8, 12], [16, 8, 10]]:
				draw_circle(p + Vector2(c[0], c[1]), c[2], col)
			txt(p + Vector2(4, 6), "WWW", 8, Color("14203a"))


func paint() -> void:
	var bg := Color(era.bg)
	draw_rect(big_rect(), bg)
	Art.glow(self, Vector2(300, 330), 420, Art.shade(bg, 1.5) * Color(1, 1, 1, 0.5))
	if era_i == 2:
		# circuit-board traces in the background
		for i in 30:
			var y := -200 + i * 40
			draw_line(Vector2(-900, y), Vector2(1500, y), Color(0.5, 0.88, 1, 0.05), 2.0)
	var cs := GW / n
	var ly := GY + rs * cs + cs / 2
	var ry := GY + rt * cs + cs / 2
	var lc := Color(era.lit) if lit.size() > 0 else Color(era.line)
	draw_line(Vector2(30, ly), Vector2(GX, ly), lc, cs * 0.18)
	draw_line(Vector2(GX + GW, ry), Vector2(VW - 30, ry), Color(era.lit) if won else Color(era.line), cs * 0.18)
	_end_icon(Vector2(30, ly - 10), era.src, true)
	_end_icon(Vector2(VW - 30, ry - 10), era.dst, won)
	for y in n:
		for x in n:
			var c: Dictionary = grid[y][x]
			var ctr := Vector2(GX + x * cs + cs / 2, GY + y * cs + cs / 2)
			var on := lit.has("%d,%d" % [x, y])
			Art.round_rect(self, Rect2(GX + x * cs + 2, GY + y * cs + 2, cs - 4, cs - 4), 6, Color(era.tile))
			draw_rect(Rect2(GX + x * cs + 2, GY + y * cs + 2, cs - 4, 3), Color(1, 1, 1, 0.06))
			if c.flash > 0:
				draw_rect(Rect2(GX + x * cs + 4, GY + y * cs + 4, cs - 8, cs - 8), Color(1, 0.81, 0.35, c.flash), false, 4.0)
			if c.broken:
				draw_line(ctr - Vector2(cs, cs) * 0.25, ctr + Vector2(cs, cs) * 0.25, Color("d64535"), 5.0)
				draw_line(ctr + Vector2(cs * 0.25, -cs * 0.25), ctr + Vector2(-cs * 0.25, cs * 0.25), Color("d64535"), 5.0)
				if era_i == 1:
					draw_set_transform_matrix(cam * Transform2D(1.2, ctr + Vector2(0, cs * 0.2)))
					draw_rect(Rect2(-3, -cs * 0.35, 6, cs * 0.35), Color("5a3a20"))
					draw_set_transform_matrix(cam)
				continue
			draw_set_transform_matrix(cam * Transform2D(c.a, ctr))
			var col := Color(era.lit) if on else Color(era.line)
			var wdt := cs * (0.26 if era_i == 0 else 0.12)
			if on:
				for d in DIRS:
					if c.m & d[0]:
						draw_line(Vector2.ZERO, Vector2(d[1], d[2]) * cs / 2, Color(col.r, col.g, col.b, 0.25), wdt * 2.2)
			for d in DIRS:
				if c.m & d[0]:
					draw_line(Vector2.ZERO, Vector2(d[1], d[2]) * cs / 2, col, wdt)
			draw_circle(Vector2.ZERO, cs * (0.13 if era_i == 0 else 0.08), col)
			if era_i == 1:
				draw_rect(Rect2(-4, -4, 8, 8), Color("5a3a20"))
			if era_i == 2 and on:
				var k := fmod(t * 2 + x * 0.3 + y * 0.3, 1.0)
				for d in DIRS:
					if c.m & d[0]:
						draw_circle(Vector2(d[1], d[2]) * cs / 2 * k, 2.5, Color.WHITE)
			draw_set_transform_matrix(cam)
	if mail >= 0 and era_i < 2:
		var mp := Vector2(30 + (VW - 60) * mail, ly + (ry - ly) * mail)
		draw_rect(Rect2(mp - Vector2(12, 8), Vector2(24, 16)), Color.WHITE)
		draw_polyline(PackedVector2Array([mp + Vector2(-12, -8), mp + Vector2(0, 1), mp + Vector2(12, -8)]), Color("999999"), 1.0)
	draw_rect(Rect2(-900, -300, VW + 1800, 364), Color(0, 0, 0, 0.3))
	var head: String = "Downloading" if phase in ["download", "end"] else "%s: connect the %s to the %s" % [era.name, era.src, era.dst]
	txt(Vector2(VW / 2, 38), head, 16, Color("f4efe2"))
	var hat := {}
	if phase in ["download", "end"] or era_i == 2:
		hat = {"headset": true}
	elif era_i == 0:
		hat = {"mailcap": true}
	else:
		hat = {"visor": true}
	light(Vector2(40, 34 + sin(t * 1.6) * 3), 14, hat)
	var cs2 := 0.16
	carl(Vector2(560, 62 - Art.carl_feet() * cs2 + 24), cs2, {"flip": true, "glow": glow, "talk": Dialog.blocking and Dialog._speaker == "carl"})
	for i in 4:
		var c := Color(0.5, 0.88, 1) if i <= era_i or phase in ["download", "end"] else Color(1, 1, 1, 0.25)
		txt(Vector2(150 + i * 100, 590), ["Letters", "Telegraph", "Dial-up", "Download"][i], 13, c)
	if time_max > 0 and phase in ["play", "talk"] and era_i == 2:
		var f := clampf(time_left / time_max, 0, 1)
		Art.round_rect(self, Rect2(70, 76, 460, 10), 5, Color(0, 0, 0, 0.4))
		Art.round_rect(self, Rect2(70, 76, maxf(10, 460 * f), 10), 5, Color("7fe08a").lerp(Color("ff5d5d"), 1 - f))
	if dl_p >= 0:
		Art.round_rect(self, Rect2(60, 170, 480, 240), 6, Color(0.03, 0.04, 0.08, 0.9))
		draw_rect(Rect2(60, 170, 480, 240), Color("7fe0ff"), false, 2.0)
		draw_rect(Rect2(70, 180, 460, 22), Color("000080"))
		txt(Vector2(78, 196), "Downloading...", 13, Color.WHITE, -1)
		txt(Vector2(80, 240), "Now downloading:", 14, Color("dddddd"), -1)
		txt(Vector2(80, 264), DL[maxi(0, dl_line)][0], 15, Color.WHITE, -1)
		draw_rect(Rect2(80, 300, 440, 24), Color("333333"))
		for b in int(minf(1, dl_p) * 22):
			draw_rect(Rect2(82 + b * 20, 302, 17, 20), Color("7fe0ff"))
		var rem: String = "done" if dl_p >= 1 else ["about 4,000 years", "3 minutes", "47 years", "2 seconds", "9 hours", "1 minute"][int(t * 1.3) % 6]
		txt(Vector2(80, 350), "Time remaining: " + rem, 13, Color("dddddd"), -1)
		txt(Vector2(480, 350), "%d%%" % int(minf(1, dl_p) * 100), 13, Color("dddddd"), -1)
