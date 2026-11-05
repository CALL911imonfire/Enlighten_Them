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


func setup() -> void:
	VW = 800
	VH = 440
	legs = Game.carl_count("leg")
	arms = Game.carl_count("arm")
	eyes = Game.carl_count("eye")
	wings = Game.carl_count("wing")
	for i in 7:
		clouds.append({"x": i * 170.0, "y": 50.0 + (i * 53) % 150, "s": 0.7 + (i % 3) * 0.25})
	_set_stage(0)
	phase = "talk"


func begin() -> void:
	var lines := INTRO.duplicate()
	if legs == 1:
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
	# Carl's body has opinions
	if st <= 1 and eyes == 1 and not body_said.has("oneeye") and why == "obstacle":
		body_said["oneeye"] = true
		lines = ["CARL:In my defense, I possess a single eye. Without binocular vision I have no depth perception. That rock was effectively a rumor."]
	elif st <= 2 and eyes >= 3 and not body_said.has("manyeyes"):
		body_said["manyeyes"] = true
		lines = ["CARL:With this many eyes there is simply too much to observe. I was distracted by a remarkably well-formed cloud.", "Focus, Carl. Pick an eye and use it."]
	elif st <= 1 and legs == 1 and not body_said.has("oneleg"):
		body_said["oneleg"] = true
		lines = ["CARL:Stop rushing me. I have precisely one leg. Hopping is a craft.", "You chose to keep one leg. Well, someone did."]
	await wait(0.7)
	await Dialog.say(lines)
	_set_stage(st)


func _carl_y() -> float:
	return lane_y if S.mode == "lane" else cy


# ---------------------------------------------------------------- update
func tick(dt: float) -> void:
	for p in particles:
		p.p += p.v * dt
		p.v.y += 500 * dt
		p.life -= dt
	particles = particles.filter(func(p): return p.life > 0)
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
		for l in MID[st]:
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
			var lean := 0.12 if st == 1 else 0.0
			var air := not ground
			carl(Vector2(x, y - feet), cs, {"walk": 0.0 if air else (0.7 if st == 1 else 0.45), "walk_speed": 16.0 if st == 1 else 9.0, "air": air,
				"tilt": lean - (vy / 3000.0 if air else 0.0), "hat": "", "talk": Dialog.blocking})
		2:
			_draw_horse(Vector2(x, y))
			carl(Vector2(x - 2, y - 66), cs * 0.85, {"tilt": -0.1})
		3:
			var yb := y + sin(t * 20.0) * 0.8
			carl(Vector2(x + 2, yb - 36), cs * 0.6, {})
			var body := PackedVector2Array([Vector2(x - 40, yb - 6), Vector2(x - 40, yb - 26), Vector2(x - 22, yb - 26), Vector2(x - 12, yb - 42), Vector2(x - 9, yb - 42),
				Vector2(x - 16, yb - 28), Vector2(x + 20, yb - 28), Vector2(x + 13, yb - 42), Vector2(x + 16, yb - 42), Vector2(x + 26, yb - 26), Vector2(x + 40, yb - 26), Vector2(x + 40, yb - 6)])
			draw_colored_polygon(body, Color("d64535"))
			draw_line(Vector2(x - 9, yb - 42), Vector2(x + 13, yb - 42), Color("d64535"), 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 16, yb - 28), Vector2(x - 9, yb - 39), Vector2(x + 13, yb - 39), Vector2(x + 20, yb - 28)]), Color(0.75, 0.89, 0.96, 0.35))
			draw_rect(Rect2(x - 40, yb - 20, 80, 4), Color(1, 1, 1, 0.2))
			for wx in [-24, 24]:
				draw_circle(Vector2(x + wx, yb - 6), 8, Color("222222"))
				draw_circle(Vector2(x + wx, yb - 6), 3, Color("999999"))
			for i in 3:
				var p := fmod(t * 3 + i / 3.0, 1.0)
				draw_circle(Vector2(x - 44 - p * 30, yb - 10 - p * 6), 3 + p * 6, Color(0.7, 0.7, 0.7, 0.35 * (1 - p)))
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


func _draw_obs() -> void:
	for o in obs:
		var sx: float = o.x - dist + CX0
		if sx > VW + 80 or sx + o.w < -80:
			continue
		match o.k:
			"rock":
				draw_colored_polygon(Art.ellipse_pts(Vector2(sx + o.w / 2, GROUND), o.w / 2, o.h + 2, 0, 16, PI, TAU), Color("7d7a73"))
				Art.ellipse(self, Vector2(sx + o.w / 2 - 4, GROUND - o.h * 0.6), o.w * 0.18, o.h * 0.2, Color(1, 1, 1, 0.2))
			"log":
				draw_rect(Rect2(sx, GROUND - o.h, o.w, o.h), Color("7a4e2a"))
				Art.ellipse(self, Vector2(sx + o.w, GROUND - o.h / 2), 4, o.h / 2, Color("c79a63"))
			"hole":
				draw_rect(Rect2(sx, GROUND, o.w, VH - GROUND + 200), Color("1d140c"))
			"fence":
				draw_rect(Rect2(sx, GROUND - o.h, 6, o.h), Color("e9e1cf"))
				draw_rect(Rect2(sx + o.w - 6, GROUND - o.h, 6, o.h), Color("e9e1cf"))
				draw_rect(Rect2(sx - 8, GROUND - o.h + 6, o.w + 16, 6), Color("e9e1cf"))
				draw_rect(Rect2(sx - 8, GROUND - o.h / 2, o.w + 16, 6), Color("e9e1cf"))
			"cone":
				var y: float = LANES[o.lane]
				draw_colored_polygon(PackedVector2Array([Vector2(sx, y), Vector2(sx + o.w / 2, y - 28), Vector2(sx + o.w, y)]), Color("ff7a1a"))
				draw_rect(Rect2(sx + 6, y - 16, o.w - 12, 4), Color.WHITE)
			"car":
				var y: float = LANES[o.lane]
				Art.round_rect(self, Rect2(sx, y - 24, o.w, 18), 5, Color("4a78c9"))
				Art.round_rect(self, Rect2(sx + 16, y - 38, o.w - 34, 16), 5, Color("4a78c9"))
				draw_rect(Rect2(sx + 20, y - 35, o.w - 42, 10), Color(0.75, 0.89, 0.96, 0.6))
				for wx in [14.0, o.w - 14.0]:
					draw_circle(Vector2(sx + wx, y - 6), 7, Color("222222"))
			"pothole":
				Art.ellipse(self, Vector2(sx + o.w / 2, LANES[o.lane] - 4), o.w / 2, 6, Color("1a1a1a"))
			"gate":
				var top: float = o.gy - o.gap / 2
				var bot: float = o.gy + o.gap / 2
				draw_rect(Rect2(sx, -300, o.w, top + 300), Color("d9dde6"))
				for i in 4:
					draw_circle(Vector2(sx + 8 + i * 16, top), 13, Color("d9dde6"))
				draw_rect(Rect2(sx, bot, o.w, GROUND - bot), Color("5a6378"))
				var yy := bot + 10
				while yy < GROUND - 8:
					var xx := sx + 8
					while xx < sx + o.w - 8:
						if int(xx * 7 + yy * 3) % 5 > 1:
							draw_rect(Rect2(xx, yy, 6, 8), Color("ffd86b"))
						xx += 14
					yy += 16


func _draw_world() -> void:
	var tops := [Color("8fd0ff"), Color("8fd0ff"), Color("ffcf8f"), Color("9fb6d6"), Color("5aa0e8")]
	Art.vgrad(self, Rect2(-400, -300, VW + 800, VH + 300), tops[st], Color("eaf6ff"))
	Art.glow(self, Vector2(VW - 120, 60), 140, Color(1, 0.95, 0.7, 0.6))
	for c in clouds:
		var x := fmod(c.x - dist * 0.08 + 2000.0, 1200.0) - 200.0
		for j in 3:
			Art.ellipse(self, Vector2(x + j * 26 * c.s, c.y - (j % 2) * 10 * c.s), 34 * c.s, 14 * c.s, Color(1, 1, 1, 0.75))
	if st <= 2:
		var hills := PackedVector2Array([Vector2(-400, GROUND)])
		for x in range(-400, int(VW) + 410, 10):
			hills.append(Vector2(x, GROUND - 60 - sin((x + dist * 0.2) / 90.0) * 24))
		hills.append(Vector2(VW + 400, GROUND))
		draw_colored_polygon(hills, Color("c7a86b") if st == 2 else Color("7fbf6a"))
	elif st == 3:
		for i in 18:
			var x := fmod(i * 70 - dist * 0.25 + 4000.0, 1260.0) - 230.0
			var h := 60 + (i * 37) % 90
			draw_rect(Rect2(x, GROUND - 90 - h, 50, h + 40), Color("7c8aa6"))
			for wy in range(0, h, 14):
				draw_rect(Rect2(x + 8, GROUND - 84 - h + wy, 8, 6), Color(1, 0.95, 0.7, 0.35))
				draw_rect(Rect2(x + 30, GROUND - 84 - h + wy, 8, 6), Color(1, 0.95, 0.7, 0.35))
	if st <= 2:
		draw_rect(Rect2(-400, GROUND, VW + 800, VH - GROUND + 300), Color("5aa34a"))
		if st == 1:
			for i in 10:
				var x := fmod(i * 130 - dist + 5200.0, 1300.0) - 200.0
				Art.ellipse(self, Vector2(x, GROUND + 20), 26, 6, Color("8b6b3e"))
		if st == 2:
			draw_rect(Rect2(-400, GROUND, VW + 800, 24), Color("b08850"))
			for i in 26:
				var x := fmod(i * 53 - dist + 5300.0, 1378.0) - 200.0
				draw_rect(Rect2(x, GROUND + 8 + (i % 3) * 5, 8, 3), Color("977042"))
		for i in 50:
			var x := fmod(i * 29 - dist + 5800.0, 1450.0) - 200.0
			draw_line(Vector2(x, GROUND), Vector2(x + 3, GROUND - 7), Color("3f7d33"), 2.0)
	elif st == 3:
		draw_rect(Rect2(-400, GROUND - 80, VW + 800, VH - GROUND + 380), Color("4a4d55"))
		draw_rect(Rect2(-400, GROUND + 14, VW + 800, VH), Color("5aa34a"))
		for i in 14:
			var x := fmod(i * 90 - dist + 9000.0, 1260.0) - 200.0
			draw_rect(Rect2(x, (LANES[0] + LANES[1]) / 2 - 12, 40, 4), Color("f2e6a0"))
	else:
		draw_rect(Rect2(-400, GROUND, VW + 800, VH - GROUND + 300), Color("5aa34a"))
	_draw_obs()
	if lib_x > 0:
		var sx := lib_x - dist + CX0
		draw_rect(Rect2(sx, GROUND - 150, 190, 150), Color("d8cdb4"))
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 14, GROUND - 150), Vector2(sx + 95, GROUND - 200), Vector2(sx + 204, GROUND - 150)]), Color("b9ab8c"))
		for i in 5:
			draw_rect(Rect2(sx + 14 + i * 36, GROUND - 140, 12, 140), Color("f3ecdc"))
		draw_rect(Rect2(sx + 78, GROUND - 60, 34, 60), Color("4a3a28"))
		txt(Vector2(sx + 95, GROUND - 160), "LIBRARY", 14, Color("4a3a28"))


func paint() -> void:
	_draw_world()
	if phase != "crash" or int(t * 12) % 2 == 1:
		_draw_carl()
	for p in particles:
		draw_rect(Rect2(p.p, Vector2(4, 4)), Color(1, 0.87, 0.47, minf(1, p.life * 2)))
	light(Vector2(VW - 70, 64 + sin(t * 1.6) * 5), 18, {S.prop: true} if S.prop != "" else {})
	var prog := 1.0 if phase in ["end", "arrive"] else _progress()
	Art.round_rect(self, Rect2(20, 20, 300, 10), 5, Color(0, 0, 0, 0.25))
	Art.round_rect(self, Rect2(20, 20, maxf(10, 300 * prog), 10), 5, Color("ffcf5a"))
	var label: String = S.name + ("  ·  gaps %d/%d" % [gates_passed, S.gates] if S.mode == "flap" else "")
	txt(Vector2(20, 48), label, 14, Color("1b2a3a"), -1)
	for i in STAGES.size():
		var c := Color("ffcf5a") if i == st else (Color(0.1, 0.16, 0.23, 0.8) if i < st else Color(0.1, 0.16, 0.23, 0.3))
		txt(Vector2(360 + i * 64, 30), STAGES[i].name, 13, c, 0)
	if phase == "ready" and not busy():
		Art.round_rect(self, Rect2(VW / 2 - 170, 170, 340, 60), 12, Color(0.04, 0.04, 0.12, 0.55))
		txt(Vector2(VW / 2, 207), "Click or press Space: " + S.btn, 20, Color("fffbe8"))
	if phase == "end":
		Art.text(self, Vector2(VW / 2, 120), "You made it to the library.", 24, Color("1b2a3a"), 0, Art.serif())
