extends Stage
## Chapter 7: Be Kind, Rewind. Wire the VCR, fix the tracking, sign into MixFlix,
## then fight the buffering wheel.

const SCR := Rect2(170, 75, 260, 190)
const JACKS := [{"c": "f2c230", "n": "VIDEO", "p": Vector2(505, 214)}, {"c": "f4f1e8", "n": "AUDIO L", "p": Vector2(505, 246)}, {"c": "d64535", "n": "AUDIO R", "p": Vector2(505, 278)}]
const PLUGS0 := [{"j": 2, "p": Vector2(110, 440)}, {"j": 0, "p": Vector2(165, 458)}, {"j": 1, "p": Vector2(220, 442)}]
const WRONG := [["That's an audio jack. Plugging video into audio is how you get a podcast."],
	["CARL:The colors match the jacks. That is the entire system. It was designed for exhausted parents at midnight."],
	["Red goes with red. I invented colors specifically so this would be easy."]]
const BOSS_INTRO := ["Okay. 'How It All Began: A Documentary.' Let's see how they got it wrong.", "...Oh no.", "CARL:The buffering wheel. Humanity's most persistent adversary.",
	"Hit it. Keep hitting it until the video loads."]
const TOTAL := 12
const MODEM := Vector2(470, 430)
const CARL_HOME := Vector2(550, 500)

var phase := "talk"
var plugs: Array = []
var sel_plug := -1
var wrong_n := 0
var tape_t := -1.0
var track := 0.5
var target := 0.2
var clear_t := 0.0
var beat_t := 0.0
var dead_t := 0.0
var login := {"acct": "", "pass": "", "typing": {}}
var wheels: Array = []
var hits := 0
var said := {}
var smoke: Array = []
var modem := 0.0
var modem_on := false
var carl_in := 0.0
var carl_go := false
var knob_drag := false
var knob_x := 0.0
var knob_v := 0.0
var track_btns: Array[Button] = []
var hold_dir := 0.0
var hold_t := 0.0


func setup() -> void:
	VW = 600
	VH = 520
	for p in PLUGS0:
		plugs.append({"j": p.j, "p": p.p, "done": false})
	target = randf_range(0.15, 0.3) if randf() < 0.5 else randf_range(0.7, 0.85)
	var l := button("◀ Tracking", Vector2(185, 470), Vector2(110, 38), func(): pass, 15)
	var r := button("Tracking ▶", Vector2(305, 470), Vector2(110, 38), func(): pass, 15)
	l.button_down.connect(_hold.bind(-1.0))
	r.button_down.connect(_hold.bind(1.0))
	l.button_up.connect(_hold.bind(0.0))
	r.button_up.connect(_hold.bind(0.0))
	track_btns = [l, r]
	for b in track_btns:
		b.visible = false


func begin() -> void:
	await Dialog.say(["A TV and a VCR, tucked in the corner of a library. Of course.",
		"CARL:The cables are disconnected. Allow me to supervise while you do the manual labor.",
		"Click a plug, then click the jack it goes in. Match the colors. Then load the tape and press play."])
	phase = "wire"


func _cue(c: String) -> void:
	match c:
		"modem":
			modem_on = true
			Sfx.tone(440, 0.3, 0.05, "sine")
			Sfx.tone(660, 0.4, 0.05, "sine", 0.2)
		"zap":
			carl_go = true
			Sfx.noise(0.4, 2500, 0.5)
			Sfx.tone(1200, 0.3, 0.05, "square")
			Sfx.tone(300, 0.5, 0.05, "sawtooth", 0.2)


# ---------------------------------------------------------------- flow
func _wired() -> bool:
	for p in plugs:
		if not p.done:
			return false
	return true


func _after_wire() -> void:
	await wait(0.3)
	phase = "tape"
	Dialog.say(["Cables: done. Now the tape. Click it to load it."])


func _after_tape() -> void:
	phase = "play"
	Dialog.say(["CARL:The clock is blinking 12:00.", "Nobody in history has ever set that clock. Not once. Press PLAY."])


func _start_track() -> void:
	phase = "track"
	Sfx.noise(0.4, 3000, 0.4)
	for b in track_btns:
		b.visible = true
	Dialog.say(["Static. Classic. Turn the tracking until the picture clears. Drag the knob, or use the buttons under the TV."])


func _vcr_dies() -> void:
	phase = "dead"
	dead_t = 0.0
	for b in track_btns:
		b.visible = false
	Sfx.noise(0.6, 800, 0.6)
	Sfx.tone(90, 0.8, 0.08, "sawtooth")
	for i in 8:
		smoke.append({"p": Vector2(300 + randf() * 40 - 20, 330), "v": Vector2((randf() - 0.5) * 20, -20 - randf() * 20), "r": 6 + randf() * 6, "life": 2.5})
	await wait(1.2)
	await Dialog.say(["...And it's dead. Outdated piece of junk.", "CARL:That silhouette. Just before it cut out. It was oddly familiar.", "Tracking error. Happens all the time.",
		"Forget tapes. We'll stream it. I have a MixFlix account.", "We're in a library, so we can just use their wifi. All I need is my library card.", "...Which I forgot.",
		"CARL:You are omnipresent. You are, by definition, wherever your library card is.", "Omnipresent, yes. Organized, no. Wait here a second. I'll grab my ethereal modem.", "!modem",
		"There. One ethereal modem, all set up. Now, my MixFlix account.", "Account name: BrightIdea7. Password: password.", "CARL:Your password is 'password.'",
		"Nobody would ever guess it. It's too obvious.", "CARL:It is statistically the most common password on Earth. Somewhere, a hacker is guessing it right now purely out of habit.",
		"Relax. I have two-factor authentication.", "CARL:And the second factor is?", "Also 'password.'", "CARL:...You created the universe.",
		"And I'd like to watch my shows without memorizing a bunch of squiggly symbols. Click the boxes to sign in."], _cue)
	phase = "login"


func _signed_in() -> void:
	phase = "profiles"
	Sfx.tone(660, 0.2, 0.05)
	Dialog.say(["Who's watching? Pick a profile."])


func _pick_profile(k: int) -> void:
	phase = "talk"
	match k:
		0:
			await Dialog.say(["That's me. Obviously."])
		1:
			await Dialog.say(["Also me. I contain multitudes."])
		2:
			await Dialog.say(["...Who is Steve?", "CARL:According to the watch history, Steve has viewed four hundred hours of baking competitions on your account.", "...Leave Steve alone. He's going through a lot."])
	phase = "bossintro"
	_start_boss()
	await Dialog.say(BOSS_INTRO)
	phase = "boss"


func _start_boss() -> void:
	hits = 0
	wheels = [{"p": SCR.get_center(), "v": Vector2(120, 80), "r": 26.0, "hp": 4, "stage": 1, "flash": 0.0}]


func _hit_wheel(w: Dictionary) -> void:
	w.hp -= 1
	w.flash = 0.2
	hits += 1
	shake = 0.15
	Sfx.tone(300 + hits * 40, 0.08, 0.06, "square")
	Sfx.noise(0.06, 2000, 0.3)
	if w.stage == 1 and w.hp <= 0:
		w.stage = 2
		w.hp = 4
		w.r = 34.0
		w.v *= 1.6
		Dialog.say(["CARL:It has breached containment.", "It's out of the TV! That's not supposed to happen!"])
		return
	if w.stage == 2 and w.hp <= 0:
		wheels.erase(w)
		for i in 4:
			var a := i * PI / 2 + 0.4
			wheels.append({"p": w.p, "v": Vector2(cos(a), sin(a)) * 240, "r": 18.0, "hp": 1, "stage": 3, "flash": 0.0})
		Dialog.say(["It's multiplying! Like Steve's watch history!"])
		return
	if w.hp <= 0:
		wheels.erase(w)
		if wheels.is_empty():
			_boss_done()


func _boss_done() -> void:
	phase = "still"
	Sfx.chime()
	await Dialog.say(["It's loading! One hundred percent! We did it!", "CARL:A historic victory. Future generations will sing of this."])
	phase = "stillq"


func _still_yes() -> void:
	phase = "end"
	Sfx.tone(880, 0.1, 0.05)
	await Dialog.say(["ARE WE STILL WATCHING? OF COURSE WE'RE STILL WATCHING. We fought a WHEEL for this.", "CARL:And there it goes. Buffering again.",
		"CARL:The wheel was merely a symptom. The real problem is the connection. What exactly is your internet plan?",
		"...Dial-up.", "CARL:Dial. Up.", "Hey, it was top of the line once.",
		"CARL:We need to get you an upgrade. Fortunately, I know precisely how. I simply need to get inside that modem. Hand me a screwdr...",
		"Okay. You asked for it.", "!zap"], _cue)
	await wait(1.4)
	finish(MODEM)


# ---------------------------------------------------------------- input
func click(p: Vector2) -> void:
	if busy():
		return
	match phase:
		"wire":
			for i in plugs.size():
				if not plugs[i].done and p.distance_to(plugs[i].p) < 22:
					sel_plug = i
					Sfx.tone(600, 0.05, 0.04)
					return
			for ji in JACKS.size():
				if p.distance_to(JACKS[ji].p) < 18 and sel_plug >= 0:
					var q: Dictionary = plugs[sel_plug]
					var taken := false
					for o in plugs:
						if o.done and o.j == ji:
							taken = true
					if q.j == ji and not taken:
						q.done = true
						sel_plug = -1
						Sfx.tone(880, 0.08, 0.05)
						Sfx.noise(0.05, 3000, 0.3)
						if _wired():
							_after_wire()
					else:
						Dialog.say(WRONG[wrong_n % WRONG.size()])
						wrong_n += 1
						Sfx.tone(150, 0.15, 0.06, "square")
						sel_plug = -1
					return
		"tape":
			if p.distance_to(Vector2(450, 462)) < 44:
				tape_t = 0.0
				phase = "loading"
				Sfx.noise(0.3, 600, 0.4)
		"play":
			if Rect2(236, 332, 48, 26).has_point(p):
				_start_track()
		"track":
			if p.distance_to(Vector2(395, 346)) < 26:
				knob_drag = true
				knob_x = p.x
				knob_v = track
		"login":
			if Rect2(200, 140, 200, 26).has_point(p) and login.acct == "" and login.typing.is_empty():
				login.typing = {"f": "acct", "s": "BrightIdea7", "i": 0.0}
			elif Rect2(200, 180, 200, 26).has_point(p) and login.pass == "" and login.typing.is_empty():
				login.typing = {"f": "pass", "s": "password", "i": 0.0}
				if not said.has("pw"):
					said["pw"] = true
					Dialog.say(["CARL:Please note: I am watching you type 'password' and I am judging all of us."])
			elif Rect2(250, 222, 100, 26).has_point(p):
				if login.acct.length() == 11 and login.pass.length() == 8:
					_signed_in()
				else:
					Dialog.say(["Fill in both boxes first. Click them."])
		"profiles":
			for k in 3:
				if Rect2(190 + k * 80, 140, 60, 70).has_point(p):
					_pick_profile(k)
					return
		"boss":
			for i in range(wheels.size() - 1, -1, -1):
				var w: Dictionary = wheels[i]
				if p.distance_to(w.p) < w.r + 8:
					_hit_wheel(w)
					return
			Sfx.tone(120, 0.04, 0.02)
		"stillq":
			if Rect2(255, 200, 90, 30).has_point(p):
				_still_yes()


func drag(p: Vector2) -> void:
	if knob_drag:
		track = clampf(knob_v + (p.x - knob_x) / 250.0, 0, 1)


func release(_p: Vector2) -> void:
	knob_drag = false


func _hold(dir: float) -> void:
	hold_dir = dir
	hold_t = 0.0
	if dir != 0.0:
		_nudge(0.025 * dir)


func _nudge(d: float) -> void:
	if phase == "track" and not busy():
		track = clampf(track + d, 0, 1)
		Sfx.tone(400, 0.03, 0.02)


# ---------------------------------------------------------------- update
func tick(dt: float) -> void:
	if modem_on:
		modem = minf(1, modem + dt * 1.5)
	if carl_go:
		carl_in = minf(1, carl_in + dt * 0.8)
	if hold_dir != 0.0:
		hold_t += dt
		if hold_t > 0.09:
			hold_t = 0
			_nudge(0.025 * hold_dir)
	for s in smoke:
		s.p += s.v * dt
		s.r += dt * 8
		s.life -= dt
	smoke = smoke.filter(func(s): return s.life > 0)
	if phase == "loading":
		tape_t = minf(1, tape_t + dt * 1.5)
		if tape_t >= 1:
			_after_tape()
	if phase == "track" and not busy():
		var d := absf(track - target)
		if d < 0.04:
			clear_t += dt
			if clear_t > 0.8:
				phase = "beat"
				beat_t = 0
				for b in track_btns:
					b.visible = false
				Sfx.tone(220, 0.6, 0.05, "sine")
		else:
			clear_t = 0
		if not said.has("warm") and d < 0.15:
			said["warm"] = true
			Dialog.say(["CARL:Warmer. I can almost make out a shape."])
	if phase == "beat":
		beat_t += dt
		if beat_t > 5.5:
			_vcr_dies()
	if phase == "dead":
		dead_t += dt
	if not login.typing.is_empty():
		var ty: Dictionary = login.typing
		ty.i += dt * 10
		var k := int(ty.i)
		login[ty.f] = ty.s.substr(0, k)
		if randf() < 0.3:
			Sfx.tone(1200, 0.02, 0.015, "square")
		if k >= ty.s.length():
			login[ty.f] = ty.s
			login.typing = {}
	if phase == "boss" and not busy():
		var sp := 0.7 if Game.settings.relaxed else 1.0
		for w in wheels:
			w.p += w.v * sp * dt
			w.flash = maxf(0, w.flash - dt)
			var b := SCR if w.stage == 1 else Rect2(20, 20, VW - 40, VH - 40)
			if w.p.x - w.r < b.position.x:
				w.p.x = b.position.x + w.r
				w.v.x = absf(w.v.x)
			if w.p.x + w.r > b.end.x:
				w.p.x = b.end.x - w.r
				w.v.x = -absf(w.v.x)
			if w.p.y - w.r < b.position.y:
				w.p.y = b.position.y + w.r
				w.v.y = absf(w.v.y)
			if w.p.y + w.r > b.end.y:
				w.p.y = b.end.y - w.r
				w.v.y = -absf(w.v.y)


# ---------------------------------------------------------------- drawing
func _static(amount: float) -> void:
	if amount <= 0:
		return
	for i in int(400 * amount):
		var v := randf()
		draw_rect(Rect2(SCR.position + Vector2(randf() * SCR.size.x, randf() * SCR.size.y), Vector2(3, 2)), Color(v, v, v, 0.5 + amount * 0.5))
	draw_rect(Rect2(SCR.position.x, SCR.position.y + fmod(t * 80, SCR.size.y - 10), SCR.size.x, 10), Color(1, 1, 1, 0.06 * amount))


func _figure(alpha: float, wob: float) -> void:
	var x := Vector2(300 + wob, 165)
	Art.glow(self, x, 60, Color(1, 0.9, 0.65, alpha))
	draw_colored_polygon(PackedVector2Array([x + Vector2(-30, 0), x + Vector2(-52, -16), x + Vector2(-48, 0), x + Vector2(-52, 16)]), Color(1, 0.92, 0.7, 0.5 * alpha))


func _wheel(w: Dictionary) -> void:
	for i in 8:
		var a := t * 6 + i * PI / 4
		var c := Color("ff5d5d") if w.flash > 0 else Color("e9ecf2")
		c.a = (i + 1) / 8.0
		draw_circle(w.p + Vector2(cos(a), sin(a)) * w.r, w.r * 0.22, c)
	if w.stage < 3:
		for i in w.hp:
			draw_rect(Rect2(w.p.x - w.r + i * (w.r * 2 / 4) + 2, w.p.y - w.r - 14, w.r * 2 / 4 - 4, 4), Color("ff5d5d"))


func _on_screen(ph: String) -> bool:
	return ph in ["login", "profiles", "bossintro", "boss", "still", "stillq", "end"] or (ph == "talk" and dead_t > 0)


func _draw_room() -> void:
	# wood-panelled wall, picture rail, baseboard, carpet and a rug
	draw_rect(big_rect(), Color("2a1d14"))
	for i in range(-12, 24):
		draw_rect(Rect2(i * 52, -600, 2, 1000), Color("3a2a1d"))
		draw_rect(Rect2(i * 52 + 24, -600, 1, 1000), Color(1, 1, 1, 0.025))
	draw_rect(Rect2(-600, 30, 1800, 6), Color("4a3524"))
	draw_rect(Rect2(-600, 392, 1800, 10), Color("4a3524"))
	draw_rect(Rect2(-600, 400, 1800, 600), Color("5a2e2a"))
	for i in 40:
		draw_rect(Rect2(-600 + i * 46, 400, 1, 600), Color(0, 0, 0, 0.06))
	Art.ellipse(self, Vector2(300, 470), 250, 42, Color("6e3b2e"))
	Art.ellipse_line(self, Vector2(300, 470), 236, 36, Color("c79a5b"), 2.0)
	Art.ellipse_line(self, Vector2(300, 470), 220, 31, Color("8a4a36"), 3.0)
	# framed picture of a sunset
	draw_rect(Rect2(-170, 80, 120, 86), Color("6b4a2a"))
	Art.vgrad(self, Rect2(-162, 88, 104, 70), Color("f2a65a"), Color("7a4a8a"))
	draw_circle(Vector2(-110, 140), 14, Color("ffe08a"))
	draw_rect(Rect2(-162, 140, 104, 18), Color("3a5a7a"))
	# floor lamp
	draw_rect(Rect2(638, 150, 4, 250), Color("2a2a2a"))
	Art.ellipse(self, Vector2(640, 400), 20, 5, Color("2a2a2a"))
	draw_colored_polygon(PackedVector2Array([Vector2(616, 150), Vector2(664, 150), Vector2(652, 112), Vector2(628, 112)]), Color("e9d9b0"))
	Art.glow(self, Vector2(640, 170), 140, Color(1, 0.85, 0.5, 0.16))
	# potted plant
	draw_colored_polygon(PackedVector2Array([Vector2(28, 400), Vector2(64, 400), Vector2(58, 440), Vector2(34, 440)]), Color("b8603a"))
	for k in 7:
		var a := -2.4 + k * 0.3 + sin(t * 0.8 + k) * 0.03
		var tip := Vector2(46, 400) + Vector2(cos(a), sin(a)) * (60 + (k % 3) * 12)
		draw_polyline(Art.quad(Vector2(46, 400), Vector2(46, 400).lerp(tip, 0.5) + Vector2(0, -12), tip), Color("3f8a4a"), 5.0, true)


func _draw_tv() -> void:
	# rabbit-ear antenna
	draw_line(Vector2(300, 60), Vector2(250, 6), Color("888888"), 2.0, true)
	draw_line(Vector2(300, 60), Vector2(352, 10), Color("888888"), 2.0, true)
	draw_circle(Vector2(250, 6), 3, Color("aaaaaa"))
	draw_circle(Vector2(352, 10), 3, Color("aaaaaa"))
	Art.ellipse(self, Vector2(300, 60), 16, 7, Color("2b2b31"))
	# cabinet with a wood-grain trim and a speaker grille
	Art.round_rect(self, Rect2(146, 56, 308, 232), 18, Color("2b2b31"))
	Art.round_rect(self, Rect2(150, 58, 300, 224), 16, Color("3b3b42"))
	Art.round_rect(self, Rect2(156, 64, 288, 212), 12, Color("4a4a52"))
	draw_rect(Rect2(160, 66, 280, 3), Color(1, 1, 1, 0.08))
	draw_rect(SCR.grow(4), Color("1c1c22"))
	draw_rect(SCR, Color("0b0b0f"))
	draw_rect(Rect2(254, 282, 92, 12), Color("2b2b31"))
	Art.round_rect(self, Rect2(236, 290, 128, 8), 3, Color("222227"))


func _draw_tv_front() -> void:
	# screen curvature glare and the brand badge, drawn over the picture
	draw_rect(Rect2(SCR.position, Vector2(SCR.size.x, 30)), Color(1, 1, 1, 0.04))
	draw_colored_polygon(PackedVector2Array([SCR.position + Vector2(8, 8), SCR.position + Vector2(70, 8), SCR.position + Vector2(8, 60)]), Color(1, 1, 1, 0.05))
	txt(Vector2(300, 279), "LUMINA", 8, Color("9a9aa6"))


func _draw_panel() -> void:
	# A/V input box on the side of the TV
	Art.round_rect(self, Rect2(452, 190, 84, 112), 6, Color("1f1f25"))
	Art.round_rect(self, Rect2(456, 194, 76, 104), 4, Color("2b2b31"))
	txt(Vector2(494, 205), "AV IN", 8, Color("8a8a96"))
	for sp in [Vector2(460, 198), Vector2(528, 198), Vector2(460, 294), Vector2(528, 294)]:
		draw_circle(sp, 2, Color("55555e"))
	for j in JACKS:
		var jp: Vector2 = j.p
		draw_circle(jp, 11, Color("15151a"))
		draw_circle(jp, 9, Color(j.c))
		draw_circle(jp, 6, Art.shade(Color(j.c), 0.75))
		draw_circle(jp, 3.5, Color("111111"))
		txt(jp + Vector2(-14, 3), j.n, 7, Color("dddddd"), 1)


func _qpts(a: Vector2, c: Vector2, b: Vector2, n := 8) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var k := float(i) / n
		out.append(a.lerp(c, k).lerp(c.lerp(b, k), k))
	return out


func _cable_path(i: int, q: Dictionary) -> PackedVector2Array:
	## Cables leave the back of the VCR, run along the floor and up the wall in
	## separate lanes, so they never cross each other or the labels.
	var j: int = q.j
	var y0 := 352.0 + (2 - j) * 7.0      # lower run for the outer lane
	var pts := PackedVector2Array([Vector2(400, y0)])
	if q.done:
		var e: Vector2 = JACKS[j].p + Vector2(22, 0)
		var lane := 556.0 + (2 - j) * 13.0
		pts.append_array(_qpts(Vector2(430, y0), Vector2(lane, y0), Vector2(lane, y0 - 24)))
		pts.append_array(_qpts(Vector2(lane, e.y + 18), Vector2(lane, e.y), Vector2(lane - 18, e.y)))
		pts.append(e)
	else:
		var e: Vector2 = q.p - Vector2(10, 0)
		pts.append_array(_qpts(Vector2(424, y0), Vector2(470 + j * 8, y0 + 4), Vector2(470 + j * 8, 400)))
		pts.append_array(_qpts(Vector2(470 + j * 8, 410), Vector2(470, e.y + 34 + j * 6), Vector2(380, e.y + 30 + j * 6)))
		pts.append_array(_qpts(Vector2(e.x + 20, e.y + 30 + j * 6), Vector2(e.x - 30, e.y + 26), e))
	return pts


func _draw_cables() -> void:
	for i in plugs.size():
		var q: Dictionary = plugs[i]
		var col := Color(JACKS[q.j].c)
		var pts := _cable_path(i, q)
		draw_polyline(pts, Art.shade(col, 0.6), 6.0, true)
		draw_polyline(pts, col, 4.0, true)


func _draw_plugs() -> void:
	for i in plugs.size():
		var q: Dictionary = plugs[i]
		var col := Color(JACKS[q.j].c)
		if q.done:
			# plug pushed into the jack, sleeve sticking out to the right
			var e: Vector2 = JACKS[q.j].p
			Art.round_rect(self, Rect2(e + Vector2(4, -6), Vector2(20, 12)), 3, col)
			draw_rect(Rect2(e + Vector2(4, -6), Vector2(4, 12)), Color("b9bcc4"))
			draw_rect(Rect2(e + Vector2(10, -6), Vector2(10, 3)), Color(1, 1, 1, 0.25))
		else:
			var e: Vector2 = q.p
			Art.round_rect(self, Rect2(e - Vector2(10, 7), Vector2(20, 14)), 3, col)
			draw_rect(Rect2(e + Vector2(-10, -7), Vector2(20, 4)), Color(1, 1, 1, 0.25))
			draw_rect(Rect2(e + Vector2(10, -3), Vector2(9, 6)), Color("c9ccd4"))
			draw_rect(Rect2(e + Vector2(10, -3), Vector2(9, 2)), Color(1, 1, 1, 0.4))
			if sel_plug == i:
				Art.round_rect(self, Rect2(e - Vector2(15, 12), Vector2(38, 24)), 6, Color(1, 0.81, 0.35, 0.25))
				draw_rect(Rect2(e - Vector2(15, 12), Vector2(38, 24)), Color("ffcf5a"), false, 2.0)
			elif phase == "wire" and sel_plug < 0:
				draw_arc(e + Vector2(4, 0), 18 + sin(t * 5) * 2, 0, TAU, 24, Color(1, 0.81, 0.35, 0.35 + 0.3 * sin(t * 5)), 1.5, true)


func _draw_vcr() -> void:
	# low cabinet with doors and a stack of tapes
	draw_rect(Rect2(146, 372, 308, 12), Color("5a3a1e"))
	draw_rect(Rect2(146, 372, 308, 3), Color("7a5230"))
	draw_rect(Rect2(152, 384, 296, 16), Color("4a2e17"))
	draw_rect(Rect2(156, 400, 10, 22), Color("4a2e17"))
	draw_rect(Rect2(434, 400, 10, 22), Color("4a2e17"))
	for k in 3:
		Art.round_rect(self, Rect2(160 + k * 14, 352 - 0, 12, 20), 2, Color(["2a2a30", "1f1f25", "3a2a20"][k]))
		draw_rect(Rect2(162 + k * 14, 356, 8, 8), Color(["e9e1cf", "d64535", "f2c230"][k]))
	# the VCR
	Art.round_rect(self, Rect2(200, 322, 222, 50), 6, Color("1d1d22"))
	draw_rect(Rect2(204, 324, 214, 3), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(204, 366, 214, 4), Color("141418"))
	# tape slot with a flap
	draw_rect(Rect2(268, 328, 70, 12), Color("0c0c10"))
	draw_rect(Rect2(270, 329, 66, 3), Color("2a2a30"))
	txt(Vector2(303, 349), "VHS", 7, Color("6a6a74"))
	# clock display
	Art.round_rect(self, Rect2(206, 340, 32, 16), 2, Color("0a0a0c"))
	var blink := int(t * 2) % 2 == 0
	if blink and dead_t == 0 and phase != "dead":
		Art.text(self, Vector2(209, 353), "12:00", 10, Color("ff4d3a"), -1)
	# play button
	var play_col := Color("3a3a40")
	if phase == "play":
		play_col = Color("7fe08a") if blink else Color("3a6a40")
	Art.round_rect(self, Rect2(240, 336, 40, 18), 3, play_col)
	draw_colored_polygon(PackedVector2Array([Vector2(254, 340), Vector2(254, 350), Vector2(262, 345)]), Color.WHITE)
	# little transport buttons
	for k in 4:
		Art.round_rect(self, Rect2(342 + k * 9, 352, 7, 6), 1, Color("3a3a40"))
	# tracking knob
	draw_circle(Vector2(395, 346), 14, Color("2a2a30"))
	draw_set_transform_matrix(cam * Transform2D((track - 0.5) * 4, Vector2(395, 346)))
	draw_circle(Vector2.ZERO, 12, Color("55555c"))
	for k in 12:
		var a := k * TAU / 12
		draw_line(Vector2(cos(a), sin(a)) * 9, Vector2(cos(a), sin(a)) * 12, Color("44444a"), 1.5)
	draw_rect(Rect2(-1.5, -11, 3, 7), Color("dddddd"))
	draw_set_transform_matrix(cam)
	if phase == "track":
		draw_arc(Vector2(395, 346), 17, 0, TAU, 20, Color(1, 0.81, 0.35, 0.5 + 0.4 * sin(t * 5)), 2.0, true)
	txt(Vector2(330, 362), "TRACKING", 7, Color("8a8a94"))


func _draw_modem(a: float) -> void:
	## A beige dial-up modem with a phone cord, vents and blinking lights.
	var m := MODEM
	Art.glow(self, m, 80, Color(1, 0.94, 0.7, 0.4 * a))
	# phone cord curling off to the wall
	var cord := PackedVector2Array()
	for i in 30:
		var k := i / 29.0
		cord.append(m + Vector2(34, 4).lerp(Vector2(120, -40), k) + Vector2(sin(k * 40.0) * 3.0, cos(k * 40.0) * 3.0))
	draw_polyline(cord, Color(0.85, 0.82, 0.72, a), 1.6, true)
	Art.ellipse(self, m + Vector2(0, 14), 40, 4, Color(0, 0, 0, 0.25 * a))
	# body: slanted top and front face
	draw_colored_polygon(PackedVector2Array([m + Vector2(-38, -6), m + Vector2(-30, -16), m + Vector2(30, -16), m + Vector2(38, -6)]), Color(0.9, 0.87, 0.78, a))
	Art.round_rect(self, Rect2(m + Vector2(-38, -6), Vector2(76, 20)), 4, Color(0.96, 0.94, 0.88, a))
	draw_rect(Rect2(m + Vector2(-38, 10), Vector2(76, 4)), Color(0.82, 0.78, 0.66, a))
	for k in 6:
		draw_line(m + Vector2(-20 + k * 8, -13), m + Vector2(-22 + k * 8, -9), Color(0.6, 0.56, 0.46, a), 1.2)
	# lights with labels
	var labels := ["HS", "AA", "CD", "RD", "SD"]
	for k in 5:
		var on := sin(t * (5 + k) + k * 2) > 0.1 or k == 0
		var c := Color(["7fe08a", "7fe08a", "ffcf5a", "ff6a5a", "7fe0ff"][k]) if on else Color("6a6a60")
		c.a = a
		var lp := m + Vector2(-30 + k * 9, 2)
		draw_circle(lp, 2.4, c)
		if on:
			Art.glow(self, lp, 6, Color(c.r, c.g, c.b, 0.5 * a))
		txt(lp + Vector2(0, 9), labels[k], 5, Color(0.45, 0.42, 0.34, a))
	txt(m + Vector2(22, 4), "ETHEREAL", 6, Color(0.54, 0.48, 0.31, a))
	# a little antenna for the cosmic connection
	draw_line(m + Vector2(28, -16), m + Vector2(34, -36), Color(0.75, 0.72, 0.62, a), 2.0)
	draw_circle(m + Vector2(34, -37), 2.5, Color(1, 0.91, 0.66, a))


func paint() -> void:
	_draw_room()
	Art.glow(self, SCR.get_center(), 320, Color(0.5, 0.65, 1, 0.08 if phase in ["wire", "tape"] else 0.18))
	_draw_tv()
	_draw_panel()
	_draw_cables()
	_draw_vcr()
	_draw_plugs()
	_draw_screen()
	_draw_tv_front()
	_draw_props()


func _draw_screen() -> void:
	# screen contents
	if phase == "track":
		var d := absf(track - target)
		var c := maxf(0, 1 - d / 0.3)
		_figure(c * 0.8, (1 - c) * sin(t * 40) * 30)
		_static(1 - c * 0.9)
	elif phase == "beat":
		_figure(0.85, sin(t * 30) * 2)
		_static(0.15 + (0.6 if beat_t > 4 else 0.0))
		var words := "\"Let there be...\""
		if beat_t > 1.2:
			txt(Vector2(300, 250), words.substr(0, mini(words.length(), int((beat_t - 1.2) * 6))), 15, Color.WHITE)
	elif phase == "dead":
		var k := minf(1, dead_t * 3)
		draw_rect(Rect2(SCR.position.x + SCR.size.x * k / 2, 165 - (1 - k) * 90, SCR.size.x * (1 - k), 2 + (1 - k) * 180), Color(1, 1, 1, 1 - k))
	elif _on_screen(phase):
		draw_rect(SCR, Color("141414"))
		Art.text(self, SCR.position + Vector2(12, 28), "MixFlix", 22, Color("e50914"), -1)
		if phase == "login" or (phase == "talk" and dead_t > 0):
			txt(Vector2(202, 136), "Account", 11, Color("dddddd"), -1)
			txt(Vector2(202, 176), "Password", 11, Color("dddddd"), -1)
			for y in [140, 180]:
				var hl: bool = phase == "login" and Rect2(200, y, 200, 26).has_point(mouse())
				draw_rect(Rect2(200, y, 200, 26), Color("444444") if hl else Color("333333"))
			Art.text(self, Vector2(208, 158), login.acct, 14, Color.WHITE, -1)
			Art.text(self, Vector2(208, 198), "•".repeat(login.pass.length()), 14, Color.WHITE, -1)
			Art.round_rect(self, Rect2(250, 222, 100, 26), 4, Color("e50914"))
			txt(Vector2(300, 240), "Sign In", 13, Color.WHITE)
		if phase == "profiles":
			txt(Vector2(300, 125), "Who's watching?", 15, Color.WHITE)
			var pr := [["God", "ffcf5a"], ["Also God", "ffe9a8"], ["Steve", "4fb3d9"]]
			for k in 3:
				var x := 190 + k * 80
				Art.round_rect(self, Rect2(x, 140, 60, 52), 6, Color(pr[k][1]))
				draw_circle(Vector2(x + 22, 162), 3, Color(0, 0, 0, 0.6))
				draw_circle(Vector2(x + 38, 162), 3, Color(0, 0, 0, 0.6))
				draw_arc(Vector2(x + 30, 172), 8, 0.3, PI - 0.3, 8, Color(0, 0, 0, 0.6), 2.0)
				txt(Vector2(x + 30, 208), pr[k][0], 12, Color("dddddd"))
		if phase in ["bossintro", "boss", "still", "stillq", "end"]:
			draw_rect(Rect2(SCR.position + Vector2(0, 40), SCR.size - Vector2(0, 40)), Color("222222"))
			var prog := float(hits) / TOTAL if phase in ["boss", "bossintro"] else 1.0
			draw_rect(Rect2(SCR.position.x + 10, SCR.end.y - 14, SCR.size.x - 20, 5), Color("444444"))
			draw_rect(Rect2(SCR.position.x + 10, SCR.end.y - 14, (SCR.size.x - 20) * prog, 5), Color("e50914"))
			txt(Vector2(SCR.position.x + 10, SCR.end.y - 22), "How It All Began: A Documentary", 11, Color("bbbbbb"), -1)
			if not phase in ["boss", "bossintro"]:
				_figure(0.25, 0)
			if phase == "stillq":
				draw_rect(SCR, Color(0, 0, 0, 0.8))
				txt(Vector2(300, 180), "Are you still watching?", 16, Color.WHITE)
				Art.round_rect(self, Rect2(255, 200, 90, 30), 4, Color("e50914"))
				txt(Vector2(300, 220), "Yes", 14, Color.WHITE)
			if phase == "end":
				_wheel({"p": Vector2(300, 160), "r": 20.0, "stage": 3, "hp": 0, "flash": 0.0})


func _draw_props() -> void:
	# tape
	if tape_t < 1:
		var k := maxf(0, tape_t)
		var x := Vector2(450, 462).lerp(Vector2(300, 335), k)
		draw_set_transform_matrix(cam * Transform2D(0, Vector2.ONE * (1 - k * 0.4), 0, x))
		Art.round_rect(self, Rect2(-40, -22, 80, 44), 4, Color("1b1b1f"))
		draw_rect(Rect2(-32, -17, 64, 13), Color("f2eee2"))
		txt(Vector2(0, -7), "DO NOT WATCH", 8, Color("d64535"))
		for dx in [-15, 15]:
			draw_circle(Vector2(dx, 9), 7, Color("555555"))
		if phase == "tape" and not busy():
			draw_rect(Rect2(-44, -26, 88, 52), Color("ffcf5a"), false, 2.0)
		draw_set_transform_matrix(cam)
	for s in smoke:
		draw_circle(s.p, s.r, Color(0.63, 0.63, 0.63, s.life / 5))
	if phase in ["boss", "bossintro"]:
		for w in wheels:
			_wheel(w)
	if modem > 0:
		_draw_modem(modem)
	# Carl
	if carl_in < 1:
		var cp := CARL_HOME.lerp(MODEM + Vector2(0, 2), carl_in)
		var cs := 0.24 * (1 - carl_in)
		if cs > 0.01:
			carl(cp - Vector2(0, Art.carl_feet() * cs), cs, {"flip": true, "talk": Dialog.blocking and Dialog._speaker == "carl"})
		if carl_go:
			draw_line(Vector2(60, 70), cp, Color(1, 0.91, 0.66, 0.7), 3.0, true)
	var popcorn := phase in ["profiles", "bossintro", "boss", "still", "stillq", "end"]
	light(Vector2(60, 70 + sin(t * 1.6) * 5), 18, {"popcorn": popcorn})
