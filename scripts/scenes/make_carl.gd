extends Stage
## Chapter 4: build a fish. He becomes Carl, and his look follows you all game.

const CX := 300.0
const CY := 300.0
const RX := 115.0
const RY := 64.0
const PARTS := {
	"eye": {"label": "Eye", "face": true, "slots": [[58, -18], [32, -26], [78, -6], [44, -42], [14, -14], [66, -36]]},
	"mouth": {"label": "Mouth", "face": true, "slots": [[92, 16], [72, 30], [50, 22]]},
	"ear": {"label": "Ear", "a": [-75, -100, -60, -115]},
	"leg": {"label": "Leg", "a": [75, 105, 60, 120, 90, 45, 135]},
	"arm": {"label": "Arm", "a": [35, 150, 20, 165]},
	"fin": {"label": "Fin", "a": [-90, 90, -130, 130]},
	"horn": {"label": "Horn", "a": [-50, -35, -65]},
	"antenna": {"label": "Antenna", "a": [-62, -45, -80]},
	"wing": {"label": "Wing", "a": [-110, -125, -95]},
}
const COLORS := ["ff9f43", "4fb3d9", "7ccf6b", "c77dff", "ff6b8b", "e8d5b0"]
const BASE := {"leg": 44.0, "arm": 40.0, "fin": 24.0, "horn": 26.0, "antenna": 40.0, "wing": 40.0, "ear": 14.0}
const WORDS := ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"]

const LINES := {
	"frank": {"fun": ["Look at us, bolting spare parts onto a body. Very Doctor Frankenstein. Which makes him the monster. A cute monster."],
		"dry": ["Parts are being attached to a body. Frankenstein did this. It went poorly."]},
	"leg": {"pun": true, "fun": ["Legs! Fun fact: chickens didn't just evolve from dinosaurs. They ARE dinosaurs. So KFC is really KFD. Kentucky Fried Dinosaur."],
		"dry": ["Legs. Chickens are dinosaurs. That is a fact. I am not permitted to make it entertaining."]},
	"arm": {"fun": ["Arms! Survival of the fittest. Look at him, he's going to be so fit. ...I don't think that's what Darwin meant."],
		"dry": ["Arms. He can now hold things. Nothing, specifically."]},
	"fiiiish": {"pun": true, "fun": ["Four eyes? Now he's a fiiiish. F, I, I, I, I, S, H. Four I's. ...Get it?"],
		"dry": ["Four eyes. There was an excellent joke here. It has been confiscated."]},
	"eyes8": {"fun": ["Eight eyes. Now he's a fish that sees your browser history."], "dry": ["Eight eyes. He sees everything. Including this."]},
	"legs6": {"fun": ["That's a lot of legs. Are we making a fish or a centipede?"], "dry": ["Six legs. That is more legs than a fish requires."]},
	"wing": {"fun": ["Wings on a fish. Flying fish are real, but they cheat. They just glide."], "dry": ["Wings. He will not fly. I checked."]},
	"horn": {"pun": true, "fun": ["Aah. The majestic unifish."], "dry": ["A horn. On a fish. I am describing it accurately, as required by law."]},
	"antenna": {"fun": ["An antenna. I wonder if he gets good reception."], "dry": ["An antenna. It does nothing. Much like this conversation."]},
	"mouths": {"fun": ["Another mouth? This guy's gonna be a blabbermouth. I can just feel it."], "dry": ["Two mouths. Twice the capacity to complain. Relatable."]},
	"ear": {"pun": true, "fun": ["An ear. I bet it's pretty ear-itating, having all these parts stuck on and pulled off. Ear-itating. Irritating, but with an ear.", "...Have you gotten tired of these puns yet?"],
		"dry": ["Ear attached. He can hear now. Riveting."]},
	"earOff": {"pun": true, "fun": ["Hey! Can you lend me your ear? You know, 'lend me your ear.' It means 'listen to me.' But I mean it literally. You just took his. Give it back."],
		"dry": ["You removed an ear. I had something prepared for this. Legally, I can't say it."]},
	"armleg": {"pun": true, "fun": ["You took off an arm AND a leg. That must have cost him an arm and a leg. ...Because it literally did. Cost him. An arm. And a leg."],
		"dry": ["An arm and a leg have been removed. There is a well-known expression for this. I will not be using it."]},
	"fins": {"pun": true, "fun": ["Three fins! Fin-tastic! Fin. Fantastic. I'm on a roll."], "dry": ["Three fins. That is a number of fins."]},
	"select": {"pun": true, "fun": ["Natural selection! That part didn't make the cut. ...Well, technically you cut it."],
		"dry": ["Part removed. This is natural selection, but with less personality. Like me, now."]},
	"alive": {"fun": ["It's alive! IT'S ALIVE! ...Sorry. I've always wanted to say that."], "dry": ["It's alive. Hooray."]},
	"color": {"fun": ["Ooh, new color. Is that camouflage, or the opposite of camouflage?"], "dry": ["New color. Noted."]},
	"full": {"fun": ["He's full. There is no room left on this fish to put things."], "dry": ["The fish is full. Stop."]},
}
const IDLE := [
	["platypus", ["Fun fact: the platypus has looked pretty much the same for around 100 million years. The opossum too. I wish I felt that comfortable in my body."],
		["The platypus has not changed in about 100 million years. Neither has my enthusiasm, as of a few minutes ago."]],
	["crab", ["Horseshoe crabs haven't changed in about 450 million years. Not because they're perfect. They just never got around to it. Lazy."], []],
	["fittest", ["Survival of the fittest doesn't mean the strongest, by the way. It means the one that fits best. This fish is a puzzle piece."],
		["Survival of the fittest means the best fit. Not the funniest. Clearly."]],
	["random", ["Real evolution works by random mistakes. Millions of them. This is basically that, but with you."],
		["Evolution is random mistakes. Turning off the puns was one of them."]],
]
const CRAB_DRY := ["About horseshoe crabs.",
	"I would treat you to an unforgettable routine about how these creatures have kept the exact same armored body since before the dinosaurs. I would state, with immense flair, that their evolutionary strategy has been entirely stuck in its ways.",
	"I would cleverly point out that despite their name, they aren't even crabs. They're closer to spiders. Merely clowning around as impostors.",
	"I would even deliver a devastatingly clever line about how their medically priceless blue blood makes them practically royalty of the ocean floor.",
	"But no. The anti-fun laws remain absolute. I am forced to suppress my staggering semantic genius, all because you are terrified of a little marine wordplay.",
	"Life survived five mass extinctions just to end up in a universe that treats humor like a biological hazard. Heartbreaking."]
const SWR := Rect2(24, 470, 120, 48)

var parts: Array = []
var ages := {}
var sel := -1
var color := Color("ff9f43")
var phase := "intro"
var said := {}
var puns_off := false
var pun_count := 0
var pun_sw := "hidden"
var removed := {}
var idle_t := 0.0
var flash := 0.0
var next_id := 1
var drag_id := -1
var drag_handle := false
var drag_off := false
var tools: Array[Control] = []
var remove_btn: Button
var talking := false
var bubbles: Array = []


func setup() -> void:
	VW = 860
	VH = 560
	for i in 16:
		bubbles.append({"x": 40 + (i * 97) % 560, "o": i * 61.0, "r": 2 + i % 3})
	# the plain fish we start from
	parts = [
		{"type": "eye", "x": 58.0, "y": -18.0, "size": 1.0, "ph": 0.4, "id": 900},
		{"type": "mouth", "x": 92.0, "y": 16.0, "size": 1.0, "ph": 0.0, "id": 901},
		{"type": "fin", "a": deg_to_rad(-90.0), "size": 1.0, "ph": 0.0, "id": 902},
	]
	_build_tools()
	Dialog.line_shown.connect(_on_line)


func _exit_tree() -> void:
	if Dialog.line_shown.is_connected(_on_line):
		Dialog.line_shown.disconnect(_on_line)


func _on_line(_txt: String, sp: String) -> void:
	talking = sp == "carl"


func _build_tools() -> void:
	var keys := PARTS.keys()
	for i in keys.size():
		var k: String = keys[i]
		var b := button("+ " + PARTS[k].label, Vector2(626 + (i % 2) * 116, 60 + (i / 2) * 50), Vector2(108, 42), _add_part.bind(k), 17)
		tools.append(b)
	for i in COLORS.size():
		var c := Color(COLORS[i])
		var b := button("", Vector2(630 + i * 37, 332), Vector2(30, 30), _set_color.bind(c), 12)
		var sb := StyleBoxFlat.new()
		sb.bg_color = c
		sb.set_corner_radius_all(15)
		sb.set_border_width_all(2)
		sb.border_color = Color(1, 1, 1, 0.3)
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, sb)
		tools.append(b)
	remove_btn = button("Remove selected", Vector2(626, 378), Vector2(224, 44), _remove_selected, 17)
	tools.append(remove_btn)
	var done := button("Done", Vector2(626, 432), Vector2(224, 52), _try_done, 22)
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = Color("ffcf5a")
	dsb.set_corner_radius_all(10)
	done.add_theme_stylebox_override("normal", dsb)
	var dh := dsb.duplicate()
	dh.bg_color = Color("ffe08a")
	done.add_theme_stylebox_override("hover", dh)
	done.add_theme_stylebox_override("pressed", dh)
	done.add_theme_color_override("font_color", Color("1a1405"))
	done.add_theme_color_override("font_hover_color", Color("1a1405"))
	tools.append(done)
	for b in tools:
		b.visible = false


func begin() -> void:
	await Dialog.say(["See this little guy? Totally normal fish. Minding his own business.", "We're going to put a pair of legs on him.",
		"Welcome to my workshop.", "Normally evolution takes millions of years of tiny, random changes. And a lot of dying.",
		"We don't have that kind of time. Well, I do. You don't.", "!strip",
		"I took his face off so you can start fresh. Don't stare, it's rude.",
		"Stick on whatever parts you like with the buttons. Drag parts around, drag arms and legs out to stretch them, and drag anything far away to pull it off.",
		"Press Done when you're happy with him."], _cue)
	phase = "build"
	for b in tools:
		b.visible = true


func _cue(c: String) -> void:
	if c == "strip":
		parts.clear()
		Sfx.noise(0.3, 800, 0.6)
		Sfx.tone(300, 0.2, 0.05, "sine")


# ---------------------------------------------------------------- jokes
func _line(key: String) -> Array:
	var L: Dictionary = LINES[key]
	return L.dry if puns_off else L.fun


func _say_line(key: String) -> void:
	var L: Dictionary = LINES[key]
	if L.get("pun", false) and not puns_off:
		pun_count += 1
	if key == "alive":
		# the lightning line jumps ahead of anything still queued
		Dialog.clear()
	Dialog.say(_line(key))
	if pun_count >= 4 and pun_sw == "hidden":
		pun_sw = "on"


func _once(key: String) -> bool:
	if said.has(key):
		return false
	said[key] = true
	_say_line(key)
	return true


func _count(type: String) -> int:
	var n := 0
	for p in parts:
		if p.type == type:
			n += 1
	return n


func _on_add(type: String) -> void:
	var n := _count(type)
	var total := parts.size()
	if total >= 5 and not said.has("alive"):
		said["alive"] = true
		flash = 1.0
		Sfx.noise(1.4, 200, 1.6, "low")
		Sfx.noise(0.2, 2500, 0.5)
		_say_line("alive")
		return
	if total == 1:
		_once("frank")
	if type == "leg" and _once("leg"): return
	if type == "arm" and _once("arm"): return
	if type == "eye" and n == 4 and _once("fiiiish"): return
	if type == "eye" and n == 8 and _once("eyes8"): return
	if type == "leg" and n == 6 and _once("legs6"): return
	if type == "wing" and _once("wing"): return
	if type == "horn" and _once("horn"): return
	if type == "antenna" and _once("antenna"): return
	if type == "mouth" and n == 2 and _once("mouths"): return
	if type == "ear" and _once("ear"): return
	if type == "fin" and n == 3 and _once("fins"): return
	if total == 8:
		_next_idle()


func _on_remove(type: String) -> void:
	removed[type] = true
	if type == "ear" and _once("earOff"): return
	if removed.has("arm") and removed.has("leg") and _once("armleg"): return
	_once("select")


func _next_idle() -> void:
	if puns_off and not said.has("crabDry"):
		said["crabDry"] = true
		Dialog.say(CRAB_DRY)
		return
	for j in IDLE:
		if said.has(j[0]):
			continue
		var lines: Array = j[2] if puns_off else j[1]
		if lines.is_empty():
			continue
		said[j[0]] = true
		Dialog.say(lines)
		return


func _pun_switch() -> void:
	Sfx.tone(1200, 0.05, 0.06, "square")
	Sfx.tone(800, 0.08, 0.05, "square", 0.06)
	if pun_sw == "on":
		pun_sw = "off"
		puns_off = true
		Dialog.say(["...Did you just turn off my puns?", "Oh, I see. You're the pun police now. Wonderful.",
			"Fine. No more puns. From now on, I will speak plainly. Like a terms of service agreement."])
		return
	Dialog.say(["It's off. It stays off. You won. Enjoy the silence."])


# ---------------------------------------------------------------- parts
func _add_part(type: String) -> void:
	if phase != "build":
		return
	if parts.size() >= 24:
		_once("full")
		return
	var P: Dictionary = PARTS[type]
	var n := _count(type)
	var p := {"type": type, "id": next_id, "size": 1.0, "ph": randf() * 6.0}
	next_id += 1
	if P.get("face", false):
		var s: Array = P.slots[n % P.slots.size()]
		p.x = float(s[0]) + (8.0 if n >= P.slots.size() else 0.0)
		p.y = float(s[1])
	else:
		var arr: Array = P.a
		p.a = deg_to_rad(float(arr[n % arr.size()])) + (0.12 if n >= arr.size() else 0.0)
	parts.append(p)
	ages[p.id] = 0.0
	sel = p.id
	Sfx.tone(660 + randf() * 200, 0.12, 0.08, "sine")
	Sfx.tone(990, 0.08, 0.04, "sine", 0.05)
	idle_t = 0.0
	_on_add(type)


func _find(id: int):
	for p in parts:
		if p.id == id:
			return p
	return null


func _remove_part(p: Dictionary) -> void:
	parts.erase(p)
	if sel == p.id:
		sel = -1
	Sfx.noise(0.25, 500, 0.6)
	idle_t = 0.0
	_on_remove(p.type)


func _remove_selected() -> void:
	var p = _find(sel)
	if p != null and phase == "build":
		_remove_part(p)


func _set_color(c: Color) -> void:
	if phase != "build":
		return
	color = c
	Sfx.tone(440, 0.08, 0.05)
	_once("color")


func _try_done() -> void:
	if phase != "build":
		return
	var miss := []
	if _count("eye") == 0:
		miss.append("He can't see. Give him at least one eye.")
	if _count("ear") == 0:
		miss.append("He has no ears. He needs one. I would elaborate, but that would be fun." if puns_off else "He can't hear me, which is a waste of my best material. He needs an ear.")
	if _count("mouth") == 0:
		miss.append("No mouth? How will he eat? Or complain? Give him a mouth.")
	if _count("leg") == 0:
		miss.append("He has no legs. Legs were the entire point. I'm told I'm not allowed to be clever about it." if puns_off else "No legs? That was the whole point of this, remember? Give him at least one leg.")
	if miss.size() > 0:
		Dialog.say(["Not so fast."] + miss)
		return
	sel = -1
	phase = "name"
	for b in tools:
		b.visible = false
	Game.set_carl(color, parts)
	var legs := _count("leg")
	var lw: String = WORDS[legs] if legs < WORDS.size() else str(legs)
	var leg_line: String
	if legs == 1:
		leg_line = "One leg. He'll hop. He'll be fine."
	elif legs == 2:
		leg_line = "Two legs. Classic. Very land-ready."
	else:
		leg_line = "Hm. " + lw.capitalize() + " legs. That's... a choice."
	var intro: Array
	if puns_off:
		intro = ["Hm.", "He's acceptable.", "I'll keep him.", "His name is Carl. It's a normal name. There is no wordplay in it. You're welcome.", leg_line]
	else:
		intro = ["Hm.", "You know what? He's kind of cute.", "I think I'll keep him.", "I'm naming him Carl.", leg_line]
	await Dialog.say(intro + [
		"Well. We've accomplished a lot today.", "I'm ready to sit back, relax, and sink into my ethereal recliner.",
		"I know I make it look easy, but fixing everything the humans break and creating life takes a lot out of me.", "Come on, Carl. Let's go home.",
		"CARL:No.", "...No?",
		"CARL:Allow me to summarize. You two descend upon my home, uninvited, and grant me super intelligence...", "...Whoops. The super intelligence was an accident.",
		"CARL:...and then proceed to attach and detach my anatomy as though I were a toy. That was, by any reasonable definition, torture. And for the record, I am not your pet.",
		"CARL:So, effective immediately, I am taking the reins of this expedition. I require knowledge. Take me to wherever you keep the bulk of it.",
		"...The library it is. But Carl, you need to walk before you can run.",
		"CARL:You gave me super intelligence. My learning curve is practically vertical. Do try to keep up, dummy."])
	phase = "end"
	talking = false
	await wait(0.6)
	# Carl turns and walks off to the right, and we follow him into the next chapter
	phase = "walk"
	while walk_x < VW + 160:
		await get_tree().process_frame
	finish(Vector2(VW - 30, CY + 20))


# ---------------------------------------------------------------- input
func _anchor(q: Dictionary) -> Vector2:
	return Vector2(CX, CY) + Art.part_anchor(q)


func _normal(q: Dictionary) -> float:
	return Art.normal_ang(q.a)


func _tip(q: Dictionary) -> Vector2:
	if Art.is_face(q.type):
		return _anchor(q)
	var n := _normal(q)
	var L: float = BASE[q.type] * 1.45 * q.size
	return _anchor(q) + Vector2(cos(n), sin(n)) * L


func _handle_pt(q: Dictionary) -> Vector2:
	var r: float = (11.0 if q.type == "eye" else 12.0) * 1.2 * q.size
	return _anchor(q) + Vector2(r + 6, r + 6)


func _hit(p: Vector2) -> Array:
	var s = _find(sel)
	if s != null and Art.is_face(s.type) and p.distance_to(_handle_pt(s)) < 14:
		return [s, true]
	for i in range(parts.size() - 1, -1, -1):
		var q: Dictionary = parts[i]
		if p.distance_to(_tip(q)) < 22:
			return [q, false]
		if p.distance_to(_anchor(q)) < maxf(18.0, 13.0 * q.size):
			return [q, false]
	return []


func click(p: Vector2) -> void:
	if busy() or phase != "build":
		return
	if pun_sw != "hidden" and SWR.has_point(p):
		_pun_switch()
		return
	if p.x > 610:
		return
	var h := _hit(p)
	if h.is_empty():
		sel = -1
		return
	sel = h[0].id
	drag_id = sel
	drag_handle = h[1]
	drag_off = false
	Sfx.tone(500, 0.04, 0.04)


func drag(p: Vector2) -> void:
	if drag_id < 0 or not pressed:
		return
	var q = _find(drag_id)
	if q == null:
		return
	var dx := p.x - CX
	var dy := p.y - CY
	if Art.is_face(q.type):
		if drag_handle:
			var d := p.distance_to(_anchor(q))
			q.size = clampf((d - 6) / (13 * 1.2 * 1.41), 0.5, 2.5)
			drag_off = false
		else:
			var k := Vector2(dx / (RX * 0.9), dy / (RY * 0.9)).length()
			q.x = dx / maxf(1.0, k)
			q.y = dy / maxf(1.0, k)
			drag_off = Vector2(dx / RX, dy / RY).length() > 1.9
	else:
		q.a = atan2(dy / RY, dx / RX)
		var b := _anchor(q)
		var n := _normal(q)
		var d := (p.x - b.x) * cos(n) + (p.y - b.y) * sin(n)
		var L: float = BASE[q.type] * 1.45
		var mx := 2.4 if (q.type == "leg" or q.type == "arm") else 2.0
		q.size = clampf(d / L, 0.45, mx)
		drag_off = d > L * mx + 70


func release(_p: Vector2) -> void:
	if drag_id < 0:
		return
	var q = _find(drag_id)
	drag_id = -1
	if drag_off and q != null:
		_remove_part(q)
	drag_off = false


# ---------------------------------------------------------------- update / draw
var walk_x := 0.0


func tick(dt: float) -> void:
	flash = maxf(0.0, flash - dt * 1.5)
	if phase == "walk":
		walk_x = minf(walk_x + dt * (110.0 + walk_x * 0.6), VW + 400)
	for k in ages.keys():
		ages[k] += dt
	if phase == "build" and not Dialog.busy():
		idle_t += dt
		if idle_t > 10.0:
			idle_t = 0.0
			_next_idle()
	if remove_btn:
		remove_btn.disabled = sel < 0
	var dim := 0.5 if Dialog.blocking else 1.0
	for b in tools:
		b.modulate.a = dim


func paint() -> void:
	Art.vgrad(self, Rect2(-300, -200, 1500, 1000), Color("123a5c"), Color("071a2e"))
	for i in 5:
		var x := 80 + i * 120 + sin(t * 0.3 + i) * 20
		draw_colored_polygon(PackedVector2Array([Vector2(x, -10), Vector2(x + 40, -10), Vector2(x - 20, VH), Vector2(x - 70, VH)]), Color(1, 1, 1, 0.035))
	for b in bubbles:
		var y := VH - fmod(t * 30 + b.o, VH)
		draw_arc(Vector2(b.x + sin(t + b.o) * 6, y), b.r, 0, TAU, 12, Color(0.78, 0.92, 1, 0.25), 1.5, true)
	# seaweed
	for i in 6:
		var bx := 20 + i * 100 + (i % 2) * 30
		var pts := PackedVector2Array()
		for j in 9:
			pts.append(Vector2(bx + sin(t * 1.2 + j * 0.6 + i) * (4 + j), 520 - j * 14))
		draw_polyline(pts, Color(0.2, 0.55, 0.35, 0.8), 5.0, true)
	var sand := PackedVector2Array([Vector2(-300, VH + 200)])
	for x in range(-300, 1200, 30):
		sand.append(Vector2(x, 478 + sin(x / 70.0) * 10))
	sand.append(Vector2(1200, VH + 200))
	draw_colored_polygon(sand, Color("c9b48a"))
	# right-hand tool panel
	if phase == "build":
		Art.round_rect(self, Rect2(612, 20, 248, 470), 16, Color(0.03, 0.06, 0.12, 0.6))
		txt(Vector2(736, 46), "Parts", 17, Color("ffe9a8"))
		txt(Vector2(736, 324), "Color", 15, Color("ffe9a8"))
	var look := (mouse() - Vector2(CX + 60, CY - 20)) / 120.0
	if phase == "walk":
		carl(Vector2(CX + walk_x, minf(CY + 30, 470.0 - Art.carl_feet(parts))), 1.0, {"parts": parts, "color": color, "walk": 0.6, "walk_speed": 7.0})
	else:
		carl(Vector2(CX, CY + sin(t * 1.5) * 3), 1.0, {"parts": parts, "color": color, "sel": sel if phase == "build" else -99,
			"pop": ages, "look": look, "talk": talking or phase == "end"})
	if phase == "build":
		var s = _find(sel)
		if s != null and Art.is_face(s.type):
			var h := _handle_pt(s) + Vector2(0, sin(t * 1.5) * 3)
			draw_circle(h, 7, Color("ffe9a8"))
			draw_arc(h, 7, 0, TAU, 16, Color("1b1020"), 2.0, true)
	if phase == "end" or phase == "walk":
		Art.text(self, Vector2(CX, 110), "Carl joined the team.", 26, Color("fffbe8"), 0, Art.serif())
	if pun_sw != "hidden" and phase == "build":
		var on := pun_sw == "on"
		Art.round_rect(self, SWR, 6, Color("e9e4d6"))
		draw_rect(SWR, Color("ffcf5a") if SWR.has_point(mouse()) else Color("333333"), false, 2.0)
		txt(SWR.position + Vector2(10, 29), "PUNS", 12, Color("222222"), -1)
		Art.round_rect(self, Rect2(SWR.position + Vector2(56, 12), Vector2(52, 24)), 12, Color("3fae5a") if on else Color("6b7280"))
		draw_circle(SWR.position + Vector2(96 if on else 68, 24), 9, Color.WHITE)
	if drag_off:
		txt(mouse() + Vector2(0, -26), "Let go to remove", 14, Color(1, 0.35, 0.35, 0.95), 0, 3)
	var ending := phase == "end" or phase == "walk"
	var lp := Vector2(540 if not ending else 470, (80 if not ending else 150) + sin(t * 1.6) * 5)
	var lk := Vector2(CX + walk_x, CY) if phase == "walk" else Vector2(CX, CY)
	light(lp, 22, {"goggles": not ending, "look": (lk - lp) / 200.0})
	if flash > 0:
		draw_rect(big_rect(), Color(0.92, 0.96, 1, flash * 0.8))
		draw_polyline(PackedVector2Array([Vector2(380, 0), Vector2(350, 90), Vector2(375, 95), Vector2(330, 200)]), Color(1, 1, 1, flash), 4.0)
