extends Stage
## Chapter 5: Carl travels to the library. One button, five stages:
## walk, run, horse, car, plane. Carl's body (from Make Carl) changes his lines.

const GROUND := 370.0
const CX0 := 170.0
const LANES := [318.0, 372.0]
const STAGES := [
	{"name": "Walk", "mode": "jump", "btn": "Hop", "speed": 150.0, "grav": 2000.0, "jv": -640.0, "len": 3000.0, "obs": ["rock", "log"], "gap": [280.0, 420.0], "prop": ""},
	{"name": "Run", "mode": "jump", "btn": "Jump", "speed": 250.0, "grav": 2000.0, "jv": -690.0, "len": 5200.0, "obs": ["rock", "hole", "rock", "hole"], "gap": [330.0, 480.0], "prop": "band"},
	{"name": "Horse", "mode": "jump", "btn": "Jump", "speed": 310.0, "grav": 2100.0, "jv": -800.0, "len": 6400.0, "obs": ["fence", "hole", "fence"], "gap": [380.0, 520.0], "prop": "cowboy"},
	{"name": "Car", "mode": "lane", "btn": "Change lane", "speed": 360.0, "len": 7600.0, "obs": ["cone", "car", "pothole"], "gap": [250.0, 360.0], "prop": "shades"},
	{"name": "Plane", "mode": "flap", "btn": "Climb", "speed": 190.0, "grav": 1150.0, "jv": -370.0, "gates": 16, "gap": [270.0, 270.0], "prop": "pilot"},
]
const INTRO := ["Okay, Carl. Road trip. The library is a long way from the ocean.", "CARL:Then let us proceed. Bipedal locomotion: engaged.",
	"Hop over the rocks. Click, or press Space. And try not to fall over. You've had legs for about five minutes."]
const AFTER := [
	["Look at you. Walking like a pro.", "CARL:Walking is tediously slow. I calculate we'll arrive sometime next century. I require more speed.",
		"That's how every human invention starts. Somebody gets impatient.", "Fine. Running. Watch out for holes. Running is just falling forward and catching yourself."],
	["CARL:My muscles are filling with lactic acid. Running is a deeply inefficient system.", "The humans thought so too. So about six thousand years ago, they started letting horses do the running for them.",
		"CARL:Outsourcing the labor to a larger mammal. Elegant.", "Hop on. And Carl? Hold your horses. ...Because you're literally holding a horse.", "Also, yes, I own a cowboy hat. I own a lot of hats."],
	["Then, about a hundred and forty years ago, the humans swapped the horse for an engine.", "CARL:And what became of the horses?", "They retired. Mostly. This car has two hundred horsepower.",
		"CARL:Then where, precisely, are the horses?", "That's the neat part. There aren't any.",
		"Fun fact: a single horse can actually hit almost fifteen horsepower at full sprint. The unit undersells them. Very human of them.",
		"CARL:So the humans named a unit of measurement after the horse and then got it wrong by a factor of fifteen. Remarkable.",
		"Tap to switch lanes. Oh, and it's a stick shift. A paradigm SHIFT. ...That's the theme of this whole game, Carl. I'm very proud of that one.", "CARL:Truly. The subtlety is breathtaking."],
	["CARL:Gridlock. Millions of years of evolution, and the result is sitting still in a metal box.", "Then let's skip the road entirely. In 1903, two brothers named Wright got a plane off the ground for twelve whole seconds.",
		"CARL:Twelve seconds? I've held my breath longer. Well, I have gills, but the point stands.", "Says the guy who was a fish this morning.", "Tap to climb. Stop tapping to drop. Fly through the gaps."],
]
const CRASH := [
	[["You tripped over a rock. A rock you could see coming.", "CARL:I've possessed legs for approximately five minutes. Adjust your expectations."],
		["Walking. Human babies learn this at age one. You're doing great.", "CARL:Human infants also lack super intelligence. Their loss, not my failing."]],
	[["Running is falling forward and catching yourself. You skipped the catching part.", "CARL:That hole was statistically improbable. I'm filing a complaint."],
		["Remember: the legs go under you. That's the whole system.", "CARL:Noted. Thank you for that groundbreaking insight, dummy."]],
	[["You're supposed to jump the fence. Not hug it.", "CARL:The horse declined to jump. I respect its autonomy.", "Don't blame the horse. The horse is doing its best."],
		["The horse is fine, by the way. Thanks for asking.", "CARL:I didn't ask. I was conducting a controlled experiment."]],
	[["Rule one of driving: don't hit things. That's pretty much all of the rules.", "CARL:The cone was occupying MY lane. Legally, this is the cone's fault."],
		["Somewhere, an insurance company just felt a disturbance.", "CARL:Define insurance.", "Something humans pay for so they can worry about it."]],
	[["What goes up must come down. Ideally slower than that.", "CARL:Gravity: 1. Carl: 0. I'm requesting a rematch."],
		["The Wright brothers crashed a lot too. Not that much, though.", "CARL:Every crash is data. I am simply gathering a great deal of data."]],
]
const MID := [
	["CARL:Left, right, left... Fascinating. The humans do this without even thinking. That explains a lot."],
	["You're running! Faster than a fish. Admittedly, a low bar."],
	["CARL:This horse emits a remarkable odor.", "He says the same about you."],
	["Fun fact: the first speeding ticket was in 1896. The car was doing eight miles an hour."],
	["CARL:I can see my house from here!", "Your house is the ocean, Carl. It's everywhere."],
]
const ARRIVE := ["There it is. The library. Where the humans keep most of their knowledge.", "Well. Used to. Now they mostly keep it on their phones.",
	"CARL:Define phone.", "You'll find out. Unfortunately.", "CARL:From the ocean to the sky in a single afternoon. Evolution took millions of years. Amateur."]

var st := 0
var S: Dictionary
var dist := 0.0
var obs: Array = []
var phase := "talk"
var next_spawn := 0.0
var gates_spawned := 0
var gates_passed := 0
var lib_x := -1.0
var mid_said := false
var crash_n := [0, 0, 0, 0, 0]
var particles: Array = []
var cy := GROUND
var vy := 0.0
var lane := 1
var lane_y := 372.0
var ground := true
var falling := false
var body_said := {}
var cs := 0.27       # Carl's scale on the road
var legs := 2
var arms := 0
var eyes := 1
var wings := 0
var clouds: Array = []
var head_legs := false   # every leg was stuck on top of Carl's head


func setup() -> void:
	VW = 800
	VH = 440
	legs = Game.carl_count("leg")
	arms = Game.carl_count("arm")
	eyes = Game.carl_count("eye")
	wings = Game.carl_count("wing")
	head_legs = legs > 0
	for q in Game.carl.get("parts", []):
		if q.type == "leg" and sin(float(q.a)) > -0.3:
			head_legs = false
	for i in 7:
		clouds.append({"x": i * 170.0, "y": 50.0 + (i * 53) % 150, "s": 0.7 + (i % 3) * 0.25})
	_set_stage(0)
	phase = "enter"


var enter_x := -80.0   # Carl climbing out of the sea at the start


const SHORE := 135.0     # world x where the grass ends and the beach slopes into the sea
const SEA_Y := GROUND + 6.0


func _coast(x: float) -> float:
	## Ground height (screen y) of the sloping beach at the start (world x, before scrolling).
	return GROUND + maxf(0.0, SHORE - x) * 0.32


func begin() -> void:
	while enter_x < CX0:
		await get_tree().process_frame
	phase = "talk"
	var lines := INTRO.duplicate()
	if head_legs:
		var one := legs == 1
		lines[1] = "CARL:Then let us proceed. Floppedal locomotion: engaged."
		lines.insert(2, "CARL:And kindly stop rushing me. I do technically possess %s, but you attached %s to my head, which renders %s roughly as useful as a decorative hat." % [
			"a leg" if one else "legs", "it" if one else "them", "it" if one else "them"])
	elif legs == 1:
		lines[1] = "CARL:Then let us proceed. Unipedal locomotion: engaged."
		lines.insert(2, "CARL:And kindly stop rushing me. I have precisely one leg.")
	elif legs >= 4:
		lines.insert(2, "CARL:With this many legs, I am essentially a myriapod. Observe me shuttle.")
	if wings > 0:
		lines.append_array(["CARL:Also, you gave me wings, yet they are paper thin. At my mass, they are purely ornamental.", "They're for style, Carl."])
	await Dialog.say(lines)
	phase = "ready"


func _set_stage(i: int) -> void:
	st = i
	S = STAGES[i]
	dist = 0.0
	obs.clear()
	particles.clear()
	gates_passed = 0
	gates_spawned = 0
	lib_x = -1.0
	mid_said = false
	next_spawn = 420.0 if S.mode == "flap" else 500.0
	cy = 200.0 if S.mode == "flap" else GROUND
	vy = 0.0
	lane = 1
	lane_y = LANES[1]
	ground = true
	falling = false
	phase = "ready"


func _jv() -> float:
	var v: float = S.jv
	if S.mode == "jump" and legs == 1:
		v *= 0.95
	if S.mode == "flap" and wings > 0:
		v *= 1.05
	return v


func _grav() -> float:
	var g: float = S.get("grav", 2000.0)
	if S.mode == "jump" and legs == 1:
		g *= 0.92
	return g


func _speed() -> float:
	var s: float = S.speed
	if st <= 1 and legs >= 4:
		s *= 1.1
	return s


# ---------------------------------------------------------------- input
func _press() -> void:
	if busy():
		return
	if phase == "ready":
		phase = "play"
	if phase != "play":
		return
	match S.mode:
		"jump":
			if ground and not falling:
				vy = _jv()
				ground = false
				Sfx.tone(260 if st == 2 else 440, 0.1, 0.06)
				if st == 2:
					Sfx.noise(0.08, 800, 0.4)
		"lane":
			lane = 1 - lane
			Sfx.tone(520, 0.06, 0.05, "square")
		_:
			vy = _jv()
			Sfx.tone(300, 0.08, 0.04, "sawtooth")


func click(_p: Vector2) -> void:
	_press()


func key(code: int) -> void:
	if code == KEY_SPACE or code == KEY_UP or code == KEY_W:
		_press()


# ---------------------------------------------------------------- obstacles
func _spawn(x: float) -> void:
	if S.mode == "flap":
		if gates_spawned >= S.gates:
			if lib_x < 0:
				lib_x = x + 200
			return
		gates_spawned += 1
		obs.append({"k": "gate", "x": x, "w": 62.0, "gy": randf_range(140, GROUND - 120), "gap": 165.0, "passed": false})
		return
	var k: String = S.obs.pick_random()
	match k:
		"rock":
			obs.append({"k": k, "x": x, "w": 28.0, "h": 22.0})
		"log":
			obs.append({"k": k, "x": x, "w": 48.0, "h": 18.0})
		"hole":
			obs.append({"k": k, "x": x, "w": randf_range(70, 120 if st == 2 else 100)})
		"fence":
			obs.append({"k": k, "x": x, "w": 14.0, "h": randf_range(40, 60)})
		_:
			obs.append({"k": k, "x": x, "lane": randi() % 2, "w": 78.0 if k == "car" else (22.0 if k == "cone" else 40.0)})


func _over_hole(x: float) -> bool:
	for o in obs:
		if o.k == "hole" and x > o.x + 10 and x < o.x + o.w - 10:
			return true
	return false


func _crash(why := "") -> void:
	if phase != "play":
		return
	phase = "crash"
	shake = 0.5
	Sfx.noise(0.5, 300, 1.2, "low")
	Sfx.tone(110, 0.3, 0.1, "sawtooth")
	for i in 14:
		var a := randf() * TAU
		particles.append({"p": Vector2(CX0, _carl_y() - 20), "v": Vector2(cos(a) * 160, sin(a) * 160 - 80), "life": 0.8})
	var set: Array = CRASH[st]
	var lines: Array = set[crash_n[st] % set.size()].duplicate()
	crash_n[st] += 1
	if head_legs and str(lines[0]).begins_with("Remember: the legs go under you"):
		lines[1] = "CARL:You installed my %s on top of my head. Short of a handstand, %s cannot go under me. Perhaps review your own engineering before critiquing mine." % [
			"leg" if legs == 1 else "legs", "it" if legs == 1 else "they"]
	# Carl's body has opinions
	if st <= 1 and eyes == 1 and not body_said.has("oneeye") and why == "obstacle":
		body_said["oneeye"] = true
		lines = ["CARL:In my defense, I possess a single eye. Without binocular vision I have no depth perception. That rock was effectively a rumor."]
	elif st <= 2 and eyes >= 3 and not body_said.has("manyeyes"):
		body_said["manyeyes"] = true
		lines = ["CARL:With this many eyes there is simply too much to observe. I was distracted by a remarkably well-formed cloud.", "Focus, Carl. Pick an eye and use it."]
	elif st <= 1 and legs == 1 and not head_legs and not body_said.has("oneleg"):
		body_said["oneleg"] = true
		lines = ["CARL:Stop rushing me. I have precisely one leg. Hopping is a craft.", "You chose to keep one leg. Well, someone did."]
	await wait(0.7)
	await Dialog.say(lines)
	_set_stage(st)


func _carl_y() -> float:
	return lane_y if S.mode == "lane" else cy


# ---------------------------------------------------------------- update
func tick(dt: float) -> void:
	Dialog.quip_passthrough = phase == "play"
	for p in particles:
		p.p += p.v * dt
		p.v.y += 500 * dt
		p.life -= dt
	particles = particles.filter(func(p): return p.life > 0)
	if phase == "enter":
		enter_x = minf(CX0, enter_x + dt * 70.0)
		return
	if phase == "arrive":
		cy += (GROUND - 40 - cy) * dt * 1.2
		vy = 0
		dist += (lib_x - 260 - dist) * dt * 1.2
		return
	if phase != "play" or busy():
		return
	dist += _speed() * dt
	while dist + VW + 60 > next_spawn:
		_spawn(next_spawn)
		next_spawn += randf_range(S.gap[0], S.gap[1])
	obs = obs.filter(func(o): return o.x + o.w > dist - CX0 - 80)
	match S.mode:
		"jump":
			vy += _grav() * dt
			cy += vy * dt
			if cy >= GROUND and not falling:
				if _over_hole(dist):
					falling = true
				else:
					cy = GROUND
					vy = 0
					ground = true
			if falling and cy > GROUND + 60:
				_crash("hole")
				return
			var hw := 28.0 if st == 2 else 12.0
			for o in obs:
				if o.k == "hole":
					continue
				if dist + hw > o.x + 3 and dist - hw < o.x + o.w - 3 and cy > GROUND - o.h + 4:
					_crash("obstacle")
					return
		"lane":
			lane_y += (LANES[lane] - lane_y) * minf(1.0, dt * 12)
			for o in obs:
				if absf(lane_y - LANES[o.lane]) < 22 and dist + 36 > o.x + 4 and dist - 36 < o.x + o.w - 4:
					_crash("obstacle")
					return
		_:
			vy += _grav() * dt
			cy += vy * dt
			if cy < 24:
				cy = 24
				vy = maxf(0, vy)
			if cy > GROUND - 14:
				_crash("ground")
				return
			for o in obs:
				if o.k != "gate":
					continue
				if not o.passed and o.x + o.w < dist - 20:
					o.passed = true
					gates_passed += 1
					Sfx.tone(880, 0.08, 0.04)
				if dist + 18 > o.x and dist - 18 < o.x + o.w and (cy - 12 < o.gy - o.gap / 2 or cy + 12 > o.gy + o.gap / 2):
					_crash("obstacle")
					return
			if lib_x > 0 and gates_passed >= S.gates and dist > lib_x - 360:
				_arrive()
				return
	var prog := _progress()
	if prog > 0.5 and not mid_said:
		mid_said = true
		var mid: Array = MID[st]
		if st == 0 and head_legs:
			mid = ["CARL:Flop. Flop. Flop. Locomotion by a series of controlled collapses. The humans call this being a toddler."]
		elif st == 0 and legs == 1:
			mid = ["CARL:Left, left, left, left... One leg makes for a rather monotonous march. The humans would call it a limp. I call it consistency."]
		for l in mid:
			Dialog.quip(l)
		if st == 4 and wings > 0 and not body_said.has("wings"):
			body_said["wings"] = true
			Dialog.quip("CARL:And now that I am in an airplane, my wings are entirely irrelevant. Splendid.")
	if S.mode != "flap" and prog >= 1.0:
		_stage_done()


func _progress() -> float:
	if S.mode == "flap":
		return float(gates_passed) / S.gates
	return minf(1.0, dist / S.len)


func _stage_done() -> void:
	phase = "talk"
	for i in 3:
		Sfx.tone([523, 659, 784][i], 0.3, 0.06, "triangle", i * 0.1)
	await wait(0.5)
	var lines: Array = AFTER[st].duplicate()
	if st == 2 and arms == 0:
		lines.append_array(["CARL:A minor design flaw. I have no arms. How precisely am I expected to operate a steering wheel?",
			"Use your fins. Or your face. I don't make the rules. ...Okay, I do make the rules."])
	await Dialog.say(lines)
	_set_stage(st + 1)


func _arrive() -> void:
	phase = "arrive"
	await wait(1.6)
	await Dialog.say(ARRIVE)
	phase = "end"
	await wait(0.6)
	finish(Vector2(lib_x - dist + CX0 + 95, GROUND - 60))


# ---------------------------------------------------------------- drawing
func _draw_carl() -> void:
	var x := CX0
	var y := _carl_y()
	var feet := Art.carl_feet() * cs
	match st:
		0, 1:
			if phase == "enter" or (st == 0 and enter_x < CX0):
				var ex := enter_x
				var ey := _coast(ex)
				carl(Vector2(ex, ey - feet), cs, {"walk": 0.45, "walk_speed": 9.0, "tilt": -0.3 if ex < SHORE else 0.0})
				return
			var lean := 0.12 if st == 1 else 0.0
			var air := not ground
			var fade := 1.0 - clampf((y - GROUND) / 34.0, 0.0, 1.0) if falling else 1.0
			carl(Vector2(x, y - feet), cs, {"walk": 0.0 if air else (0.7 if st == 1 else 0.45), "walk_speed": 16.0 if st == 1 else 9.0, "air": air,
				"tilt": lean - (vy / 3000.0 if air else 0.0), "hat": "", "talk": Dialog.blocking, "alpha": fade})
		2:
			_draw_horse(Vector2(x, minf(y, GROUND + 10.0) if falling else y))
			carl(Vector2(x - 2, y - 66), cs * 0.85, {"tilt": -0.1})
		3:
			var yb := y + sin(t * 20.0) * 0.8
			Art.ellipse(self, Vector2(x, y + 1), 44, 4, Color(0, 0, 0, 0.25))
			_draw_car(Vector2(x, yb), 84.0, Color("d64535"), true)
			for i in 3:
				var p := fmod(t * 3 + i / 3.0, 1.0)
				draw_circle(Vector2(x - 46 - p * 30, yb - 10 - p * 6), 3 + p * 6, Color(0.7, 0.7, 0.7, 0.35 * (1 - p)))
		_:
			var tilt := clampf(vy / 700.0, -0.5, 0.6)
			draw_set_transform_matrix(cam * Transform2D(tilt, Vector2(x, y)))
			Art.cam = cam * Transform2D(tilt, Vector2(x, y))
			draw_colored_polygon(PackedVector2Array([Vector2(-28, 0), Vector2(-44, -16), Vector2(-36, 0)]), Color("2f6fb3"))
			Art.ellipse(self, Vector2.ZERO, 34, 10, Color("2f6fb3"))
			draw_rect(Rect2(-30, -2, 60, 3), Color(1, 1, 1, 0.25))
			carl(Vector2(-2, -12), cs * 0.42, {"tilt": -0.1})
			draw_rect(Rect2(-20, 6, 40, 5), Color("e7c14a"))
			draw_rect(Rect2(-20, -30, 40, 5), Color("e7c14a"))
			for sx in [-14, 12]:
				draw_line(Vector2(sx, -26), Vector2(sx, 6), Color("8a6a20"), 2.0)
			var pr := sin(t * 60.0) * 14
			draw_line(Vector2(36, -pr), Vector2(36, pr), Color("cccccc"), 3.0)
			draw_circle(Vector2(35, 0), 3, Color("555555"))
			Art.cam = cam
			draw_set_transform_matrix(cam)


const PATH_COL := [Color("c9a26b"), Color("a87b4a"), Color("d6b77c")]
const PATH_H := [16.0, 22.0, 24.0]


func _hh(i: int, k := 0) -> float:
	## Stable pseudo-random 0..1 for scenery, so details never flicker as they scroll.
	var v := sin(float(i) * 12.9898 + float(k) * 78.233) * 43758.5453
	return v - floor(v)


func _blade(b: Vector2, h: float, lean: float, col: Color, w := 1.4) -> void:
	draw_colored_polygon(PackedVector2Array([b + Vector2(-w, 1), b + Vector2(lean * 0.35 - w * 0.55, -h * 0.5), b + Vector2(lean, -h),
		b + Vector2(lean * 0.35 + w * 0.55, -h * 0.5), b + Vector2(w, 1)]), col)


func _blades(y: float, sp: float, hmin: float, hmax: float, c1: Color, c2: Color, seed: int, xl: float) -> void:
	## A row of single grass blades along y, scrolling with the road.
	var i0 := int(floor((dist - 160.0) / sp))
	var i1 := int(floor((dist + VW + 240.0) / sp)) + 1
	for i in range(i0, i1):
		var sx := i * sp + _hh(i, seed) * sp * 0.6 - dist
		if sx < xl:
			continue
		var h := lerpf(hmin, hmax, _hh(i, seed + 1))
		_blade(Vector2(sx, y), h, (_hh(i, seed + 2) - 0.5) * h * 0.7, c1.lerp(c2, _hh(i, seed + 3)))


func _clumps(y: float, sp: float, hmin: float, hmax: float, c1: Color, c2: Color, seed: int, xl: float, keep := 0.55) -> void:
	## Fanned tufts of grass, like little bunches.
	var i0 := int(floor((dist - 160.0) / sp))
	var i1 := int(floor((dist + VW + 240.0) / sp)) + 1
	for i in range(i0, i1):
		if _hh(i, seed) > keep:
			continue
		var sx := i * sp + _hh(i, seed + 1) * sp * 0.5 - dist
		if sx < xl:
			continue
		var h := lerpf(hmin, hmax, _hh(i, seed + 2))
		for b in 7:
			var f := (b - 3.0) / 3.0
			var bh := h * (1.0 - absf(f) * 0.45) * (0.8 + 0.4 * _hh(i * 7 + b, seed + 3))
			_blade(Vector2(sx + f * 4.0, y), bh, f * h * 0.6, c1.lerp(c2, _hh(i * 7 + b, seed + 4)), 1.6)


func _pebbles(y0: float, y1: float, sp: float, c1: Color, c2: Color, seed: int, xl: float) -> void:
	var i0 := int(floor((dist - 160.0) / sp))
	var i1 := int(floor((dist + VW + 240.0) / sp)) + 1
	for i in range(i0, i1):
		var sx := i * sp + _hh(i, seed) * sp - dist
		if sx < xl:
			continue
		var r := 1.0 + _hh(i, seed + 1) * 1.8
		Art.ellipse(self, Vector2(sx, lerpf(y0, y1, _hh(i, seed + 2))), r * 1.3, r * 0.8, c1.lerp(c2, _hh(i, seed + 3)))


func _draw_backdrop() -> void:
	## Far hills, mesas or the city skyline behind the road.
	if st <= 2:
		var far: Color = [Color("a9d3a0"), Color("9cc98e"), Color("e2c793")][st]
		var near: Color = [Color("7fbf6a"), Color("70b05c"), Color("c7a86b")][st]
		var fp := PackedVector2Array([Vector2(-400, GROUND + 20)])
		for x in range(-400, int(VW) + 410, 10):
			var u := x + dist * 0.1
			var y := GROUND - 92 - sin(u / 140.0) * 30 - sin(u / 53.0) * 8
			if st == 2:
				y = GROUND - 66 - clampf(sin(u / 70.0) * 70, 0, 38) - clampf(sin(u / 31.0 + 1.0) * 30, 0, 10)
			fp.append(Vector2(x, y))
		fp.append(Vector2(VW + 400, GROUND + 20))
		draw_colored_polygon(fp, far)
		var hills := PackedVector2Array([Vector2(-400, GROUND + 20)])
		for x in range(-400, int(VW) + 410, 10):
			hills.append(Vector2(x, GROUND - 60 - sin((x + dist * 0.2) / 90.0) * 24))
		hills.append(Vector2(VW + 400, GROUND + 20))
		draw_colored_polygon(hills, near)
		for i in 12:
			var x := fmod(i * 113.0 - dist * 0.2 + 4000.0, 1356.0) - 200.0
			var y := GROUND - 60 - sin((x + dist * 0.2) / 90.0) * 24 + 4
			if st == 2:
				if i % 3 != 0:
					continue
				# saguaro cactus on the ridge
				var cc := Color("6a8f4a")
				draw_line(Vector2(x, y), Vector2(x, y - 22), cc, 5.0)
				draw_line(Vector2(x - 7, y - 8), Vector2(x - 7, y - 15), cc, 3.5)
				draw_line(Vector2(x - 7, y - 8), Vector2(x, y - 8), cc, 3.5)
				draw_line(Vector2(x + 7, y - 12), Vector2(x + 7, y - 19), cc, 3.5)
				draw_line(Vector2(x + 7, y - 12), Vector2(x, y - 12), cc, 3.5)
			elif i % 2 == 0:
				draw_line(Vector2(x, y), Vector2(x, y - 12), Color("6a4a2a"), 3.0)
				draw_circle(Vector2(x, y - 18), 9, Color("3f8a3a"))
				draw_circle(Vector2(x - 4, y - 21), 5, Color("56a34a"))
	elif st == 3:
		for i in 18:
			var x := fmod(i * 70 - dist * 0.25 + 4000.0, 1260.0) - 230.0
			var h := 60 + (i * 37) % 90
			draw_rect(Rect2(x, GROUND - 90 - h, 50, h + 40), Color("7c8aa6"))
			for wy in range(0, h, 14):
				draw_rect(Rect2(x + 8, GROUND - 84 - h + wy, 8, 6), Color(1, 0.95, 0.7, 0.35))
				draw_rect(Rect2(x + 30, GROUND - 84 - h + wy, 8, 6), Color(1, 0.95, 0.7, 0.35))


func _draw_ground() -> void:
	var xl := -400.0
	if st == 0 and dist < VW + 200:
		xl = SHORE - dist
	var big := VW + 800.0 - xl
	match st:
		0:
			# meadow with a sandy footpath
			Art.vgrad(self, Rect2(xl, GROUND, big, VH - GROUND + 40), Color("5aa34a"), Color("3f8a3a"))
			draw_rect(Rect2(xl, VH + 40, big, 300), Color("3f8a3a"))
			draw_rect(Rect2(xl, GROUND, big, 16), PATH_COL[0])
			draw_rect(Rect2(xl, GROUND, big, 2), Color("a8834f"))
			_pebbles(GROUND + 4, GROUND + 13, 21, Color("a08058"), Color("e6c995"), 3, xl)
			_blades(GROUND + 1, 5, 5, 13, Color("4f9a3e"), Color("76c45a"), 1, xl)
			for i in range(int(floor((dist - 160.0) / 70.0)), int(floor((dist + VW + 240.0) / 70.0)) + 1):
				if _hh(i, 21) > 0.45:
					continue
				var fx := i * 70.0 + _hh(i, 22) * 40 - dist
				if fx < xl:
					continue
				var fh := 8 + _hh(i, 23) * 8
				draw_line(Vector2(fx, GROUND), Vector2(fx + 1, GROUND - fh), Color("3f7d33"), 1.2)
				var fc: Color = [Color("ffd84a"), Color("ff8fb5"), Color("ffffff"), Color("b58aff")][int(_hh(i, 24) * 4) % 4]
				for k in 5:
					draw_circle(Vector2(fx + 1, GROUND - fh) + Vector2.from_angle(k * TAU / 5) * 2.2, 1.6, fc)
				draw_circle(Vector2(fx + 1, GROUND - fh), 1.3, Color("e7a83a"))
			_blades(GROUND + 18, 4, 4, 9, Color("5aa34a"), Color("82cf62"), 7, xl)
			_clumps(GROUND + 46, 90, 10, 18, Color("4f9a3e"), Color("8bd36a"), 11, xl)
			_clumps(GROUND + 66, 130, 12, 22, Color("3f8a3a"), Color("76c45a"), 13, xl)
		1:
			# packed dirt trail over a band of stony soil, tall grass behind
			draw_rect(Rect2(xl, GROUND, big, VH - GROUND + 300), Color("4f9a3e"))
			draw_rect(Rect2(xl, GROUND, big, 22), PATH_COL[1])
			Art.vgrad(self, Rect2(xl, GROUND + 22, big, 34), Color("6e4a2c"), Color("5a3b22"))
			_pebbles(GROUND + 26, GROUND + 52, 13, Color("8a6440"), Color("c2a27a"), 5, xl)
			_pebbles(GROUND + 4, GROUND + 18, 37, Color("8f8a82"), Color("bdb7ad"), 6, xl)
			for i in range(int(floor((dist - 160.0) / 40.0)), int(floor((dist + VW + 240.0) / 40.0)) + 1):
				var rx := i * 40.0 - dist
				if rx < xl:
					continue
				if _hh(i, 31) > 0.35:
					draw_line(Vector2(rx, GROUND + 9), Vector2(rx + 22 + _hh(i, 32) * 10, GROUND + 9), Color("8e6538"), 1.5)
				if _hh(i, 33) > 0.4:
					draw_line(Vector2(rx + 8, GROUND + 16), Vector2(rx + 30, GROUND + 16), Color("8e6538"), 1.5)
				if _hh(i, 34) > 0.93:
					Art.ellipse(self, Vector2(rx + 20, GROUND + 12), 18, 3.5, Color(0.45, 0.6, 0.75, 0.75))
					draw_line(Vector2(rx + 10, GROUND + 11), Vector2(rx + 20, GROUND + 11), Color(1, 1, 1, 0.5), 1.0)
			_blades(GROUND + 57, 4, 5, 11, Color("4f9a3e"), Color("76c45a"), 17, xl)
			_blades(GROUND + 1, 6, 4, 9, Color("4f9a3e"), Color("7cc45c"), 15, xl)
			_clumps(GROUND + 1, 46, 14, 28, Color("3f8a3a"), Color("8bd36a"), 19, xl, 0.6)
			_clumps(GROUND + 84, 110, 12, 20, Color("3a7d33"), Color("6fb35c"), 23, xl)
		2:
			# sandy prairie road with wagon ruts, dry grass and sagebrush
			draw_rect(Rect2(xl, GROUND, big, VH - GROUND + 300), Color("a89a4c"))
			draw_rect(Rect2(xl, GROUND, big, 24), PATH_COL[2])
			Art.vgrad(self, Rect2(xl, GROUND + 24, big, 40), Color("b7834e"), Color("9a6a3c"))
			for k in 3:
				draw_line(Vector2(xl, GROUND + 32 + k * 10), Vector2(xl + big, GROUND + 32 + k * 10), Color(0, 0, 0, 0.07), 2.0)
			_pebbles(GROUND + 28, GROUND + 60, 17, Color("8a5a32"), Color("d8a878"), 8, xl)
			for ry in [GROUND + 7.0, GROUND + 17.0]:
				draw_line(Vector2(xl, ry), Vector2(xl + big, ry), Color("b8955a"), 2.5)
				draw_line(Vector2(xl, ry + 2), Vector2(xl + big, ry + 2), Color(1, 1, 1, 0.15), 1.0)
			for i in range(int(floor((dist - 160.0) / 26.0)), int(floor((dist + VW + 240.0) / 26.0)) + 1):
				var hx := i * 26.0 - dist
				Art.ellipse(self, Vector2(hx, GROUND + 12 + (i % 2) * 2), 2.2, 1.3, Color("b8955a"))
			for i in range(int(floor((dist - 160.0) / 150.0)), int(floor((dist + VW + 240.0) / 150.0)) + 1):
				if _hh(i, 41) > 0.6:
					continue
				var bx := i * 150.0 + _hh(i, 42) * 80 - dist
				for k in 4:
					draw_circle(Vector2(bx + (k - 1.5) * 6, GROUND - 4 - (k % 2) * 4), 6 + _hh(i * 4 + k, 43) * 2, Color("8a9a6a").lerp(Color("a9b88a"), _hh(i * 4 + k, 44)))
			_blades(GROUND + 1, 9, 4, 11, Color("b3a64e"), Color("dccb72"), 25, xl)
			_clumps(GROUND + 66, 70, 10, 18, Color("9a8a3e"), Color("d4c26a"), 27, xl)
		3:
			# city street: sidewalk with lamps, two lanes, curb and verge
			draw_rect(Rect2(xl, GROUND - 98, big, 18), Color("b9b4aa"))
			for i in range(int(floor((dist - 160.0) / 40.0)), int(floor((dist + VW + 240.0) / 40.0)) + 1):
				var jx := i * 40.0 - dist
				draw_line(Vector2(jx, GROUND - 98), Vector2(jx - 6, GROUND - 80), Color(0, 0, 0, 0.12), 1.0)
			for i in range(int(floor((dist - 160.0) / 240.0)), int(floor((dist + VW + 240.0) / 240.0)) + 1):
				var lx := i * 240.0 - dist + 60
				draw_line(Vector2(lx, GROUND - 90), Vector2(lx, GROUND - 168), Color("3d4250"), 3.0)
				draw_line(Vector2(lx, GROUND - 168), Vector2(lx + 16, GROUND - 168), Color("3d4250"), 3.0)
				Art.round_rect(self, Rect2(lx + 10, GROUND - 168, 14, 6), 3, Color("ffe9a8"))
				if i % 2 == 0:
					draw_rect(Rect2(lx + 90, GROUND - 118, 4, 28), Color("6b5a3a"))
					draw_circle(Vector2(lx + 92, GROUND - 126), 12, Color("3f8a3a"))
			draw_rect(Rect2(xl, GROUND - 80, big, 94), Color("4a4d55"))
			draw_rect(Rect2(xl, GROUND - 80, big, 3), Color("9a9da6"))
			draw_rect(Rect2(xl, GROUND + 9, big, 2), Color("e8e8e8"))
			for i in 14:
				var x := fmod(i * 90 - dist + 9000.0, 1260.0) - 200.0
				draw_rect(Rect2(x, (LANES[0] + LANES[1]) / 2 - 12, 40, 4), Color("f2e6a0"))
			draw_rect(Rect2(xl, GROUND + 14, big, VH - GROUND + 300), Color("5aa34a"))
			draw_rect(Rect2(xl, GROUND + 14, big, 5), Color("c8c3b8"))
			_blades(GROUND + 24, 5, 4, 9, Color("4f9a3e"), Color("7cc45c"), 29, xl)
		_:
			# farmland seen from the air
			draw_rect(Rect2(xl, GROUND, big, VH - GROUND + 300), Color("5aa34a"))
			for i in range(int(floor((dist - 160.0) / 150.0)), int(floor((dist + VW + 240.0) / 150.0)) + 1):
				var fx := i * 150.0 - dist
				var fc: Color = [Color("6fb35c"), Color("c9b25a"), Color("8fbf5a"), Color("a0c86a")][int(_hh(i, 51) * 4) % 4]
				draw_rect(Rect2(fx + 2, GROUND + 4, 146, 60), fc)
				for k in 5:
					draw_line(Vector2(fx + 4, GROUND + 10 + k * 11), Vector2(fx + 146, GROUND + 10 + k * 11), Color(0, 0, 0, 0.07), 2.0)
			_blades(GROUND + 1, 7, 3, 7, Color("4f9a3e"), Color("7cc45c"), 31, xl)
	if st == 0 and dist < VW + 200:
		_draw_shore()


func _draw_hole(sx: float, w: float) -> void:
	## A flat ellipse in the path: the far inner wall shows on top, darkness below.
	var c := Vector2(sx + w / 2, GROUND + 7)
	var rx := w / 2 + 2
	var ry := 7.0
	Art.ellipse(self, c, rx, ry, Color("6b4a2c"))
	Art.ellipse(self, c + Vector2(rx * 0.62, -0.5), rx * 0.3, ry * 0.75, Color("7f5c3a"))
	Art.ellipse(self, c + Vector2(-rx * 0.06, ry * 0.32), rx * 0.9, ry * 0.66, Color("140d07"))


func _hole_lip(sx: float, w: float) -> void:
	## The near edge of the hole, redrawn over Carl so he drops in behind it.
	if st > 2:
		return
	var c := Vector2(sx + w / 2, GROUND + 7)
	var rx := w / 2 + 2
	var ry := 7.0
	var ph: float = PATH_H[st]
	var pts := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	pts.append(Vector2(c.x - rx, GROUND + ph))
	pts.append(Vector2(c.x + rx, GROUND + ph))
	draw_colored_polygon(pts, PATH_COL[st])


func _draw_shore() -> void:
	## The sloping beach Carl walks up out of the sea. Scrolls away with the road.
	var ox := -dist
	var sand := PackedVector2Array([Vector2(ox + SHORE + 6, GROUND)])
	for i in 33:
		var x := SHORE - i * 20.0
		sand.append(Vector2(ox + x, _coast(x)))
	sand.append(Vector2(ox + SHORE - 640, VH + 400))
	sand.append(Vector2(ox + SHORE + 6 + (VH + 400 - GROUND) * 0.4, VH + 400))
	draw_colored_polygon(sand, Color("e3cf98"))
	# darker wet sand below the waterline
	var xm := SHORE - (SEA_Y - GROUND) / 0.32
	var wet := PackedVector2Array()
	for i in 30:
		var x := xm + 4 - i * 20.0
		wet.append(Vector2(ox + x, _coast(x) + 0.5))
	for i in 30:
		var x := xm + 4 - (29 - i) * 20.0
		wet.append(Vector2(ox + x, _coast(x) + 16))
	draw_colored_polygon(wet, Color("c9b07a"))
	for i in 7:
		var x := xm + 2 + i * 3.0
		draw_circle(Vector2(ox + x, _coast(x) + 4 + (i % 3) * 3), 1.4, Color("f4e6c0") if i % 2 else Color("b89e6a"))
	# beach rocks and a shell
	Art.ellipse(self, Vector2(ox + xm + 10, _coast(xm + 10) - 1), 6, 3.5, Color("8a857c"))
	Art.ellipse(self, Vector2(ox + xm + 9, _coast(xm + 10) - 2.5), 3, 1.4, Color(1, 1, 1, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(ox + SHORE - 4, GROUND + 1), Vector2(ox + SHORE - 1, GROUND - 4), Vector2(ox + SHORE + 2, GROUND + 1)]), Color("f0c9b0"))
	# beach grass along the edge of the dunes
	for k in 4:
		var yy := GROUND + 20.0 + k * 16.0
		var ex := ox + SHORE + 6 + (yy - GROUND) * 0.4
		for b in 5:
			var f := (b - 2.0) / 2.0
			_blade(Vector2(ex - 2 + f * 3, yy), 9 + (b % 2) * 4, f * 6.0, Color("8fae5a").lerp(Color("c9c27a"), (k + b) % 3 / 3.0), 1.3)
	# the grass lip where the meadow ends
	draw_colored_polygon(PackedVector2Array([Vector2(ox + SHORE - 8, GROUND + 2), Vector2(ox + SHORE + 6, GROUND - 2), Vector2(ox + SHORE + 10, GROUND + 6)]), Color("5aa34a"))
	for k in 5:
		_blade(Vector2(ox + SHORE - 6 + k * 3.5, GROUND + 1), 8 + (k % 2) * 5, (k - 2) * 2.0, Color("4f9a3e").lerp(Color("a8b860"), 0.4))


func _draw_sea_front() -> void:
	## Drawn after Carl so he looks like he is wading out of it.
	var ox := -dist
	var xm := SHORE - (SEA_Y - GROUND) / 0.32
	var sea := PackedVector2Array()
	for i in 41:
		var x := -500.0 + i * (xm + 500.0) / 40.0
		var calm := clampf((xm - x) / 40.0, 0.0, 1.0)
		sea.append(Vector2(ox + x, SEA_Y + sin(x / 18.0 + t * 2.4) * 2.5 * calm))
	for i in 31:
		var x := xm - i * 21.0
		sea.append(Vector2(ox + x, _coast(x)))
	draw_colored_polygon(sea, Color(0.2, 0.52, 0.82, 0.86))
	var surf := PackedVector2Array()
	for i in 41:
		surf.append(sea[i])
	draw_polyline(surf, Color(1, 1, 1, 0.45), 2.0)
	for i in 6:
		var x := -330.0 + i * 60.0 + fmod(t * 14.0, 60.0)
		if x < xm - 30:
			draw_line(Vector2(ox + x, SEA_Y + 10 + (i % 2) * 8), Vector2(ox + x + 18, SEA_Y + 10 + (i % 2) * 8), Color(1, 1, 1, 0.3), 2.0)
	var fx := xm - 6 + sin(t * 1.6) * 5
	draw_line(Vector2(ox + fx - 14, SEA_Y + 1), Vector2(ox + fx + 4, _coast(fx + 4) - 0.5), Color(1, 1, 1, 0.7), 2.5)


func _draw_horse(f: Vector2) -> void:
	## A brown horse in a gallop. f = point between the hooves on the ground.
	var coat := Color("8a5a2b")
	var dark := Color("5e3a1a")
	var mane := Color("2e1b0c")
	var gait := t * 13.0 if ground else 0.0
	var bob := sin(gait * 2.0) * 1.5 if ground else -2.0
	var b := f + Vector2(0, -40 + bob)     # centre of the barrel
	# legs: upper leg, lower leg and hoof, far pair darker and behind
	var legs := [[-20.0, 0.0, true], [16.0, PI, true], [-14.0, PI * 0.5, false], [22.0, PI * 1.5, false]]
	for far in [true, false]:
		for L in legs:
			if L[2] != far:
				continue
			var ph: float = gait + L[1]
			var swing := sin(ph) * (0.55 if ground else 0.0)
			var bend := maxf(0.0, cos(ph)) * (0.9 if ground else 0.0)
			if not ground:
				swing = 0.5 if L[0] > 0 else -0.5
				bend = 1.0
			var hip := b + Vector2(L[0], 8)
			var knee := hip + Vector2(sin(swing), cos(swing)) * 16
			var hoof := knee + Vector2(sin(swing - bend * (1 if L[0] > 0 else -1)), cos(swing - bend)) * 16
			var c := Art.shade(coat, 0.75) if far else coat
			draw_line(hip, knee, c, 6.0, true)
			draw_line(knee, hoof, c, 4.5, true)
			draw_rect(Rect2(hoof - Vector2(3, 1), Vector2(6, 4)), Color("222222"))
	# tail
	var sway := sin(t * 6.0) * 4.0
	draw_polyline(Art.quad(b + Vector2(-30, -6), b + Vector2(-50, -4 + sway), b + Vector2(-46, 20 + sway)), mane, 6.0, true)
	draw_polyline(Art.quad(b + Vector2(-30, -4), b + Vector2(-46, 4 + sway), b + Vector2(-40, 22 + sway)), mane, 3.0, true)
	# barrel, chest and rump
	Art.ellipse(self, b, 32, 14, coat)
	draw_circle(b + Vector2(22, -2), 13, coat)
	draw_circle(b + Vector2(-22, -2), 13, coat)
	Art.ellipse(self, b + Vector2(0, -6), 24, 5, Color(1, 1, 1, 0.12))
	# neck and head
	var nb := b + Vector2(24, -6)
	var head := b + Vector2(44, -34 + bob * 0.5)
	draw_colored_polygon(PackedVector2Array([nb + Vector2(-6, -8), nb + Vector2(10, 8), head + Vector2(4, 6), head + Vector2(-6, -6)]), coat)
	draw_set_transform_matrix(cam * Transform2D(0.55, head))
	Art.ellipse(self, Vector2(4, 0), 13, 7, coat)
	Art.ellipse(self, Vector2(14, 1), 6, 5.5, Art.shade(coat, 0.85))
	draw_circle(Vector2(17, 2), 1.3, Color("222222"))
	draw_set_transform_matrix(cam)
	draw_circle(head + Vector2(0, -2), 2.2, Color("111111"))
	draw_circle(head + Vector2(-0.6, -2.6), 0.7, Color.WHITE)
	# ears
	draw_colored_polygon(PackedVector2Array([head + Vector2(-6, -6), head + Vector2(-8, -16), head + Vector2(-1, -7)]), dark)
	# mane along the neck
	for i in 5:
		var k := i / 4.0
		var p0 := (nb + Vector2(-6, -8)).lerp(head + Vector2(-6, -6), k)
		draw_line(p0, p0 + Vector2(-7 + sin(t * 8 + i) * 2, 3), mane, 3.0, true)
	# saddle and reins
	Art.ellipse(self, b + Vector2(-2, -13), 12, 4, Color("6b2a1a"))
	draw_line(b + Vector2(4, -14), head + Vector2(10, 6), Color(0.15, 0.1, 0.05, 0.8), 1.2, true)


func _draw_car(base: Vector2, w: float, body: Color, rider := false) -> void:
	## Side view of a little hatchback facing right. base = middle of the car at road level.
	var x := base.x
	var y := base.y
	var h := w * 0.5
	var dark := Art.shade(body, 0.7)
	if rider:
		carl(Vector2(x - w * 0.02, y - 30), cs * 0.55, {})
	# lower body with hood and trunk
	var lower := PackedVector2Array([
		Vector2(x - h, y - 8), Vector2(x - h - 1, y - 20), Vector2(x - h + 6, y - 25), Vector2(x - w * 0.26, y - 26),
		Vector2(x + w * 0.24, y - 26), Vector2(x + h - 8, y - 22), Vector2(x + h, y - 17), Vector2(x + h + 1, y - 10), Vector2(x + h - 3, y - 8)])
	draw_colored_polygon(lower, body)
	# cabin: pillars and roof, with see-through glass
	var glass := PackedVector2Array([Vector2(x - w * 0.26, y - 26), Vector2(x - w * 0.18, y - 40), Vector2(x + w * 0.1, y - 40), Vector2(x + w * 0.24, y - 26)])
	draw_colored_polygon(glass, Color(0.72, 0.88, 0.97, 0.45 if rider else 0.75))
	draw_polyline(glass, body, 3.5, true)
	draw_line(Vector2(x - w * 0.03, y - 40), Vector2(x - w * 0.03, y - 26), body, 3.0)
	draw_line(glass[1] + Vector2(3, 2), glass[2] + Vector2(-4, 2), Color(1, 1, 1, 0.35), 1.5)
	# trim, door seams, handles, lights, bumper
	draw_line(Vector2(x - h + 2, y - 19), Vector2(x + h - 2, y - 19), Color(1, 1, 1, 0.22), 2.0)
	draw_line(Vector2(x - w * 0.03, y - 26), Vector2(x - w * 0.03, y - 10), dark, 1.2)
	draw_line(Vector2(x + w * 0.24, y - 26), Vector2(x + w * 0.22, y - 10), dark, 1.2)
	draw_rect(Rect2(x + w * 0.06, y - 22, 6, 2), dark)
	draw_rect(Rect2(x - w * 0.2, y - 22, 6, 2), dark)
	Art.ellipse(self, Vector2(x + h - 2, y - 17), 2.5, 2.2, Color("fff2b0"))
	draw_rect(Rect2(x - h - 1, y - 20, 3, 5), Color("e0403a"))
	draw_rect(Rect2(x - h - 2, y - 11, w + 4, 3), Color("3a3d44"))
	# wheels in their arches
	for wx in [-w * 0.3, w * 0.3]:
		var wc := Vector2(x + wx, y - 6)
		draw_circle(Vector2(x + wx, y - 8), 10.5, dark)
		draw_circle(wc, 8, Color("1d1d22"))
		draw_circle(wc, 4, Color("a9afb8"))
		for k in 3:
			var aa := t * 14.0 + k * TAU / 3.0
			draw_line(wc, wc + Vector2(cos(aa), sin(aa)) * 3.6, Color("6b7079"), 1.2)


func _draw_obs() -> void:
	for o in obs:
		var sx: float = o.x - dist + CX0
		if sx > VW + 80 or sx + o.w < -80:
			continue
		match o.k:
			"rock":
				var c := Vector2(sx + o.w / 2, GROUND)
				var w: float = o.w
				var hh: float = o.h
				Art.ellipse(self, c + Vector2(0, 1), w * 0.55, 3, Color(0, 0, 0, 0.18))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-w / 2, 0), c + Vector2(-w * 0.44, -hh * 0.55), c + Vector2(-w * 0.2, -hh - 2),
					c + Vector2(w * 0.12, -hh + 1), c + Vector2(w * 0.42, -hh * 0.6), c + Vector2(w / 2, 0)]), Color("85817a"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(w * 0.12, -hh + 1), c + Vector2(w * 0.42, -hh * 0.6), c + Vector2(w / 2, 0), c + Vector2(w * 0.05, 0)]), Color("6a6660"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-w * 0.3, -hh * 0.7), c + Vector2(-w * 0.18, -hh + 1), c + Vector2(0, -hh * 0.8)]), Color(1, 1, 1, 0.22))
				draw_polyline(PackedVector2Array([c + Vector2(-2, -hh * 0.9), c + Vector2(2, -hh * 0.5), c + Vector2(-1, -hh * 0.2)]), Color(0.25, 0.24, 0.22, 0.6), 1.2)
			"log":
				var hh: float = o.h
				var w: float = o.w
				var r := hh / 2
				Art.ellipse(self, Vector2(sx + w / 2, GROUND + 1), w * 0.55, 3, Color(0, 0, 0, 0.18))
				draw_rect(Rect2(sx, GROUND - hh, w, hh), Color("7a4e2a"))
				draw_circle(Vector2(sx, GROUND - r), r, Color("6a4224"))
				for i in 4:
					var yy: float = GROUND - hh + 3 + i * (hh - 6) / 3.0
					draw_line(Vector2(sx + 4 + (i % 2) * 6, yy), Vector2(sx + w - 10 - (i % 2) * 8, yy), Color("5a361c"), 1.5)
				Art.ellipse(self, Vector2(sx + w, GROUND - r), r * 0.55, r, Color("d8ab70"))
				Art.ellipse_line(self, Vector2(sx + w, GROUND - r), r * 0.3, r * 0.55, Color("a87a44"), 1.2)
				draw_line(Vector2(sx + w * 0.4, GROUND - hh), Vector2(sx + w * 0.35, GROUND - hh - 8), Color("5a361c"), 2.0)
				Art.ellipse(self, Vector2(sx + w * 0.33, GROUND - hh - 9), 4, 2.5, Color("5aa34a"))
			"hole":
				_draw_hole(sx, o.w)
			"fence":
				var w: float = o.w
				var hh: float = o.h
				var wood := Color("b07a45")
				var lite := Color("cf9a62")
				for px in [sx - 10, sx + w + 4]:
					draw_rect(Rect2(px, GROUND - hh - 4, 7, hh + 4), wood)
					draw_colored_polygon(PackedVector2Array([Vector2(px, GROUND - hh - 4), Vector2(px + 3.5, GROUND - hh - 9), Vector2(px + 7, GROUND - hh - 4)]), wood)
					draw_rect(Rect2(px + 1, GROUND - hh, 2, hh), lite)
				for ry in [GROUND - hh + 4, GROUND - hh * 0.5]:
					draw_rect(Rect2(sx - 14, ry, w + 28, 6), lite)
					draw_rect(Rect2(sx - 14, ry + 4, w + 28, 2), wood)
					for nx in [sx - 7, sx + w + 7]:
						draw_circle(Vector2(nx, ry + 3), 1.2, Color("4a3220"))
			"cone":
				var y: float = LANES[o.lane]
				var w: float = o.w
				Art.ellipse(self, Vector2(sx + w / 2, y + 1), w * 0.75, 3, Color(0, 0, 0, 0.2))
				draw_rect(Rect2(sx - 4, y - 4, w + 8, 4), Color("e2611a"))
				draw_colored_polygon(PackedVector2Array([Vector2(sx + 1, y - 4), Vector2(sx + w / 2 - 3, y - 30), Vector2(sx + w / 2 + 3, y - 30), Vector2(sx + w - 1, y - 4)]), Color("ff7a1a"))
				draw_colored_polygon(PackedVector2Array([Vector2(sx + 5, y - 13), Vector2(sx + 7.5, y - 19), Vector2(sx + w - 7.5, y - 19), Vector2(sx + w - 5, y - 13)]), Color.WHITE)
				draw_line(Vector2(sx + w / 2 - 1, y - 28), Vector2(sx + 5, y - 5), Color(1, 1, 1, 0.3), 1.5)
			"car":
				var y: float = LANES[o.lane]
				var w: float = o.w
				Art.ellipse(self, Vector2(sx + w / 2, y + 1), w * 0.55, 4, Color(0, 0, 0, 0.25))
				var cols := [Color("4a78c9"), Color("3fa36b"), Color("e0b63a"), Color("8a5cc7")]
				var ci := int(o.x) % cols.size()
				_draw_car(Vector2(sx + w / 2, y), w, cols[ci])
			"pothole":
				var w: float = o.w
				var c := Vector2(sx + w / 2, LANES[o.lane] - 4)
				Art.ellipse(self, c, w / 2 + 3, 8, Color("2c2d31"))
				Art.ellipse(self, c + Vector2(0, 1), w / 2, 6, Color("121214"))
				Art.ellipse(self, c + Vector2(4, 2), w / 2 - 8, 3, Color(0.3, 0.45, 0.6, 0.5))
				for k in 3:
					var aa := -2.6 + k * 1.1
					draw_line(c + Vector2(cos(aa) * w / 2, sin(aa) * 7), c + Vector2(cos(aa) * (w / 2 + 9), sin(aa) * 11), Color("2c2d31"), 1.5)
			"gate":
				var top: float = o.gy - o.gap / 2
				var bot: float = o.gy + o.gap / 2
				var bw: float = o.w
				# cloud bank hanging from above
				draw_rect(Rect2(sx, -300, bw, top + 290), Color("cfd5e0"))
				for i in 5:
					draw_circle(Vector2(sx + 4 + i * 13.5, top - 6 + (i % 2) * 4), 12, Color("cfd5e0"))
				for i in 4:
					draw_circle(Vector2(sx + 10 + i * 14, top - 16), 9, Color("e6eaf1"))
				# skyscraper standing below. Window lights are fixed per building so they never flicker.
				var seed := int(o.x)
				draw_rect(Rect2(sx, bot, bw, GROUND - bot), Color("56607a"))
				draw_rect(Rect2(sx + bw - 10, bot, 10, GROUND - bot), Color("48506a"))
				draw_rect(Rect2(sx - 3, bot, bw + 6, 6), Color("6c7792"))
				draw_rect(Rect2(sx + bw * 0.5 - 1, bot - 16, 2, 16), Color("9aa3b8"))
				draw_circle(Vector2(sx + bw * 0.5, bot - 17), 2.5, Color(1, 0.3, 0.25, 0.6 + 0.4 * sin(t * 4.0)))
				var row := 0
				var yy := bot + 12
				while yy < GROUND - 22:
					for col in 4:
						var hsh := absi((seed * 31 + row * 17 + col * 7) * 2654435761) % 7
						draw_rect(Rect2(sx + 7 + col * 13, yy, 8, 9), Color("ffd86b") if hsh > 2 else Color("323a4f"))
					yy += 16
					row += 1
				draw_rect(Rect2(sx + bw * 0.5 - 7, GROUND - 14, 14, 14), Color("2a3043"))


func _draw_world() -> void:
	var tops := [Color("8fd0ff"), Color("8fd0ff"), Color("ffcf8f"), Color("9fb6d6"), Color("5aa0e8")]
	Art.vgrad(self, Rect2(-400, -300, VW + 800, VH + 300), tops[st], Color("eaf6ff"))
	Art.glow(self, Vector2(VW - 120, 60), 140, Color(1, 0.95, 0.7, 0.6))
	for c in clouds:
		var x := fmod(c.x - dist * 0.08 + 2000.0, 1200.0) - 200.0
		for j in 3:
			Art.ellipse(self, Vector2(x + j * 26 * c.s, c.y - (j % 2) * 10 * c.s), 34 * c.s, 14 * c.s, Color(1, 1, 1, 0.75))
	_draw_backdrop()
	_draw_ground()
	_draw_obs()
	if lib_x > 0:
		_draw_library(lib_x - dist + CX0)


func _draw_library(sx: float) -> void:
	## A small classical library: steps, columns, pediment, big doors, lamps.
	var g := GROUND
	Art.ellipse(self, Vector2(sx + 95, g + 2), 140, 6, Color(0, 0, 0, 0.15))
	# side wings with windows
	draw_rect(Rect2(sx - 34, g - 110, 258, 110), Color("d6cab0"))
	draw_rect(Rect2(sx - 38, g - 114, 266, 6), Color("c9bc9e"))
	for wx in [sx - 24.0, sx + 202.0]:
		Art.round_rect(self, Rect2(wx, g - 94, 18, 34), 8, Color("4d5f78"))
		draw_line(Vector2(wx + 9, g - 92), Vector2(wx + 9, g - 60), Color("8c7a58"), 1.5)
		draw_line(Vector2(wx, g - 76), Vector2(wx + 18, g - 76), Color("8c7a58"), 1.5)
		draw_rect(Rect2(wx - 2, g - 60, 22, 3), Color("c2b496"))
	# main hall
	draw_rect(Rect2(sx, g - 150, 190, 150), Color("e4dac4"))
	# entablature with lettering
	draw_rect(Rect2(sx - 10, g - 162, 210, 18), Color("d2c5a6"))
	draw_rect(Rect2(sx - 10, g - 146, 210, 3), Color("c2b496"))
	txt(Vector2(sx + 95, g - 149), "L I B R A R Y", 11, Color("5a4630"))
	# pediment
	draw_colored_polygon(PackedVector2Array([Vector2(sx - 16, g - 162), Vector2(sx + 95, g - 206), Vector2(sx + 206, g - 162)]), Color("cbbd9c"))
	draw_colored_polygon(PackedVector2Array([Vector2(sx + 6, g - 166), Vector2(sx + 95, g - 197), Vector2(sx + 184, g - 166)]), Color("ddd1b4"))
	draw_circle(Vector2(sx + 95, g - 178), 8, Color("cbbd9c"))
	Art.ellipse(self, Vector2(sx + 95, g - 178), 4, 6, Color("ffe9a8"))
	# doors (behind the columns)
	Art.round_rect(self, Rect2(sx + 78, g - 80, 34, 56), 8, Color("5a3d24"))
	draw_line(Vector2(sx + 95, g - 78), Vector2(sx + 95, g - 24), Color("3e2a18"), 2.0)
	draw_circle(Vector2(sx + 91, g - 50), 1.5, Color("e7c14a"))
	draw_circle(Vector2(sx + 99, g - 50), 1.5, Color("e7c14a"))
	# columns with capitals, bases and fluting
	for i in 6:
		var cx := sx + 6 + i * 34.0
		if i == 2 or i == 3:
			cx += -6 if i == 2 else 6
		draw_rect(Rect2(cx, g - 140, 14, 116), Color("f3ecdc"))
		draw_rect(Rect2(cx + 10, g - 140, 4, 116), Color("dcd2bc"))
		draw_line(Vector2(cx + 5, g - 136), Vector2(cx + 5, g - 28), Color(0, 0, 0, 0.08), 1.0)
		draw_rect(Rect2(cx - 3, g - 145, 20, 6), Color("e8dfca"))
		draw_rect(Rect2(cx - 3, g - 26, 20, 4), Color("e8dfca"))
	# steps
	for i in 3:
		draw_rect(Rect2(sx - 6 - i * 6, g - 22 + i * 7, 202 + i * 12, 8), Color("cfc3a8") if i % 2 == 0 else Color("ddd2b8"))
	# lamps
	for lx in [sx + 66.0, sx + 124.0]:
		draw_rect(Rect2(lx - 1, g - 70, 2, 10), Color("3a3a3a"))
		draw_circle(Vector2(lx, g - 72), 3.5, Color("ffe08a"))
		Art.glow(self, Vector2(lx, g - 72), 16, Color(1, 0.9, 0.5, 0.35))
	# a reading banner
	draw_rect(Rect2(sx + 150, g - 134, 14, 36), Color("7a2a3a"))
	draw_colored_polygon(PackedVector2Array([Vector2(sx + 150, g - 98), Vector2(sx + 157, g - 92), Vector2(sx + 164, g - 98)]), Color("7a2a3a"))
	draw_rect(Rect2(sx + 152, g - 124, 10, 8), Color("ffe9a8"))
	draw_line(Vector2(sx + 157, g - 124), Vector2(sx + 157, g - 116), Color("7a2a3a"), 1.0)


func paint() -> void:
	_draw_world()
	if phase != "crash" or int(t * 12) % 2 == 1:
		_draw_carl()
	if falling:
		for o in obs:
			if o.k == "hole":
				_hole_lip(o.x - dist + CX0, o.w)
	if st == 0 and dist < VW + 200:
		_draw_sea_front()
	for p in particles:
		draw_rect(Rect2(p.p, Vector2(4, 4)), Color(1, 0.87, 0.47, minf(1, p.life * 2)))
	light(Vector2(VW - 70, 64 + sin(t * 1.6) * 5), 18, {S.prop: true} if S.prop != "" else {})
	var prog := 1.0 if phase in ["end", "arrive"] else _progress()
	Art.round_rect(self, Rect2(20, 20, 300, 10), 5, Color(0, 0, 0, 0.25))
	Art.round_rect(self, Rect2(20, 20, maxf(10, 300 * prog), 10), 5, Color("ffcf5a"))
	if S.mode == "flap":
		txt(Vector2(20, 48), "Gaps %d/%d" % [gates_passed, S.gates], 14, Color("1b2a3a"), -1)
	if phase == "ready" and not busy():
		Art.round_rect(self, Rect2(VW / 2 - 170, 170, 340, 60), 12, Color(0.04, 0.04, 0.12, 0.55))
		txt(Vector2(VW / 2, 207), "Click or press Space: " + S.btn, 20, Color("fffbe8"))
	if phase == "end":
		Art.text(self, Vector2(VW / 2, 120), "You made it to the library.", 24, Color("1b2a3a"), 0, Art.serif())
