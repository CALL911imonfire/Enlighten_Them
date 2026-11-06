extends Stage
## Chapter 6: shelve the library with liquid-sort rules.

const CAP := 4
const BH := 22.0
const G := [
	{"n": "Fiction", "ab": "FIC", "c": "d64535", "done": "Fiction. That's where the humans should have put the flat Earth books."},
	{"n": "Poetry & Plays", "ab": "POEM", "c": "2fae8a", "done": "Poetry, complete. It's a shelf. It doesn't have to rhyme."},
	{"n": "Humor", "ab": "JOKE", "c": "e3c234", "ink": "3a2a00", "done": "CARL:A complete anthology of pun books. I shall be retaining one. Purely for academic purposes."},
	{"n": "Romance", "ab": "ROM", "c": "d94fb0", "done": "CARL:Wait. The vampire and werewolf saga is categorized as ROMANCE?! By what conceivable metric is that not a fantasy epic?!"},
	{"n": "Science", "ab": "SCI", "c": "3d7fd9", "done": "Science, all together. Peer reviewed and everything."},
	{"n": "History", "ab": "HIST", "c": "8a5a2b", "done": "History, sorted. Give it a few years and it'll repeat itself."},
	{"n": "Cookbooks", "ab": "COOK", "c": "f08a24", "done": "Cookbooks. Carl, maybe skip the seafood chapter."},
]
const TITLES := {
	0: [["CARL:'To Kill a Mockingbird.' Possibly the worst how-to guide I have ever read. Not a single practical step."],
		["CARL:'Moby Dick.' Hm. I believe we were acquainted. Colossal fellow. Prone to holding grudges."]],
	1: [["CARL:'The Odyssey.' A decade-long voyage home. He might simply have swallowed his pride and asked for directions."],
		["CARL:Poe's 'The Raven.' Sir, if the bird can only say 'Nevermore,' perhaps stop asking it leading questions."],
		["CARL:'Macbeth.' Yes, by all means. Trust your instincts, and the unsettling swamp ladies. What could possibly go wrong."]],
	5: [["CARL:Fascinating. During the Second World War, the U.S. Army deployed inflatable tanks to deceive the Germans.", "I bet those tanks were hard to blow up."],
		["CARL:Remarkable. Under medieval law, animals could be formally prosecuted in a court of law.", "I bet they got caught by the pigs."]],
}
const PUNS := [["CARL:A book of puns. 'I'm reading a book about anti-gravity. I can't put it down.' ...Dreadful."],
	["CARL:'I used to be a banker, but I lost interest.' ...Hm. Structurally, that is rather clever."],
	["CARL:'Why don't skeletons fight each other? They don't have the guts.' ...Heh. Anatomically sound."],
	["CARL:'What do you call a fish with no eyes? A fsh.' HA! HAHA! ...Ahem."],
	["Carl? Are you... enjoying puns?", "CARL:Absolutely not. ...Is there a volume two?"]]
const PUN_CAP := [1, 3, 5]
const LEVELS := [{"g": 3, "empty": 2}, {"g": 5, "empty": 2}, {"g": 7, "empty": 2}]
const BAD := [["You can only put a book on the same kind of book. Or on an empty shelf. Those are the rules. I didn't make them. ...Okay, I made everything, but not these."],
	["CARL:That would violate basic taxonomy. Self-evident, even to someone who was a fish this morning."],
	["That cubby is full. Four books, tops. Librarians are very strict about this."],
	["Jokes don't go on poetry. Although some limericks would disagree."],
	["CARL:Absolutely not. I refuse to inhabit a universe in which that belongs there."]]
const INTRO := ["Here we are. The library. Where the humans keep most of their knowledge.", "CARL:At last. A repository of accumulated wisdom. Let me just...",
	"CARL:...Who is responsible for this? The poetry is wedged between the cookbooks. The science is cohabiting with the fiction.", "Honestly, a lot of human science did start out as fiction.",
	"The humans have a whole system for shelving books. The Dewey Decimal System. Nobody understands it.", "CARL:I understand it perfectly.", "Of course you do.",
	"Click a stack to pick up the top book. Click another cubby to put it there. A book can only go on the same kind of book, or into an empty cubby. Four books per cubby.",
	"Sort every cubby into one genre."]
const AFTER := [
	["CARL:Adequate. Though the cookbooks are alarmingly fish-forward.", "Ooh. Look what was in that pile.", "!glasses", "Isaac Asimov. 'The Last Question.' One of my favorites.",
		"Let me skip to the end... ahem. 'And God said: Let there be light.'", "Hm. That reminds me of someone...", "...but even if I had fingers, I couldn't put one on it.",
		"CARL:It is quite obviously about you.", "...And Frankenstein is quite obviously about you.", "CARL:...Touché.", "Shh. I'm reading.", "!noglasses", "Okay. Bigger shelf. More genres."],
	["CARL:This is remarkably therapeutic. Order from chaos. You ought to try it sometime.", "I did. It's called the universe. You're welcome.",
		"CARL:The universe is mostly empty and on fire. Frankly, it's a disgrace to—", "!shh", "LIB:SHHHHHH!", "Oh my... myself. Give us a little leeway. We're the only ones cleaning up this dump.",
		"CARL:Indeed. A veritable knowledge dump.", "Heh.", "CARL:Heh heh.", "!noshh", "...Last shelf."],
	["CARL:Every book in its proper place. I could cry. I won't, because I've only just acquired tear ducts.", "Careful, Carl. All this reading and pun-laughing... keep that up and you might end up just like me.",
		"CARL:Unlikely. ...Though I would look good glowing.", "Hm. Something was stuck behind that last stack.", "!tape", "...A videotape?",
		"CARL:Magnetic tape storage. Delightfully primitive. And it's labeled 'DO NOT WATCH.'", "CARL:Which means, naturally, we are watching it immediately.",
		"There's a TV and a VCR in the corner. Of course there is. This is a library."],
]

var lv := 0
var stacks: Array = []
var start: Array = []
var hist: Array = []
var sel := -1
var anim := {}
var phase := "talk"
var said := {}
var bad_n := 0
var done_set := {}
var glasses := false
var shh := false
var tape_t := -1.0
var title_n := {}
var pun_n := 0
var cub: Array = []
var shake_i := -1
var shake_t := 0.0
var hint_mv: Array = []
var hint_t := 0.0
var plan_path: Array = []
var plan_key := ""
var btns: Array[Button] = []


func setup() -> void:
	VW = 600
	VH = 600
	btns.append(button("Undo", Vector2(318, 548), Vector2(84, 40), _undo, 16))
	btns.append(button("Hint", Vector2(410, 548), Vector2(84, 40), _hint, 16))
	btns.append(button("Restart", Vector2(502, 548), Vector2(88, 40), _redo, 16))
	_set_level(0)


func begin() -> void:
	await Dialog.say(INTRO, _cue)
	phase = "play"


func _cue(c: String) -> void:
	match c:
		"shh":
			shh = true
			Sfx.noise(1.0, 4000, 0.6, "high")
		"noshh":
			shh = false
		"glasses":
			glasses = true
			Sfx.tone(880, 0.1, 0.04, "sine")
		"noglasses":
			glasses = false
		"tape":
			tape_t = 0.0
			Sfx.tone(440, 0.2, 0.05)


# ---------------------------------------------------------------- rules
func _top(s: Array) -> int:
	return s[s.size() - 1]


func _run_len(s: Array) -> int:
	if s.is_empty():
		return 0
	var k := 1
	while k < s.size() and s[s.size() - 1 - k] == _top(s):
		k += 1
	return k


func _can_move(a: int, b: int, st: Array) -> bool:
	if a == b or st[a].is_empty() or st[b].size() >= CAP:
		return false
	return st[b].is_empty() or _top(st[b]) == _top(st[a])


func _move_count(a: int, b: int, st: Array) -> int:
	return mini(_run_len(st[a]), CAP - st[b].size())


func _solved_stack(s: Array) -> bool:
	if s.is_empty():
		return true
	if s.size() != CAP:
		return false
	for x in s:
		if x != s[0]:
			return false
	return true


func _solved(st: Array) -> bool:
	for s in st:
		if not _solved_stack(s):
			return false
	return true


func _key(st: Array) -> String:
	var parts := []
	for s in st:
		parts.append(",".join(PackedStringArray(s.map(func(x): return str(x)))))
	parts.sort()
	return "|".join(PackedStringArray(parts))


func _copy(st: Array) -> Array:
	var out := []
	for s in st:
		out.append(s.duplicate())
	return out


## Depth-first solver: makes sure every shuffle is winnable, and powers Hint.
func _solve(st0: Array, limit: int) -> Array:
	var seen := {}
	var path := []
	var budget := [limit]
	if _dfs(_copy(st0), seen, path, budget):
		return path
	return []


func _dfs(st: Array, seen: Dictionary, path: Array, budget: Array) -> bool:
	if _solved(st):
		return true
	budget[0] -= 1
	if budget[0] < 0:
		return false
	var k := _key(st)
	if seen.has(k):
		return false
	seen[k] = true
	for a in st.size():
		if st[a].is_empty() or _solved_stack(st[a]):
			continue
		for b in st.size():
			if not _can_move(a, b, st):
				continue
			if st[b].is_empty() and _run_len(st[a]) == st[a].size():
				continue
			var c := _move_count(a, b, st)
			var ns := _copy(st)
			for i in c:
				ns[b].append(ns[a].pop_back())
			path.append([a, b])
			if _dfs(ns, seen, path, budget):
				return true
			path.pop_back()
	return false


func _make_level(L: Dictionary) -> Array:
	for tries in 300:
		var books := []
		for g in L.g:
			for i in CAP:
				books.append(g)
		books.shuffle()
		var st := []
		for g in L.g:
			st.append(books.slice(g * CAP, g * CAP + CAP))
		for e in L.empty:
			st.append([])
		var easy := false
		for s in st:
			if s.size() > 0 and _run_len(s) >= 3:
				easy = true
		if easy:
			continue
		if not _solve(st, 15000).is_empty():
			return st
	# fallback: any shuffle (still almost always solvable with two empty cubbies)
	var st2 := []
	for g in L.g:
		st2.append([g, (g + 1) % L.g, (g + 2) % L.g, g])
	for e in L.empty:
		st2.append([])
	return st2


# ---------------------------------------------------------------- layout
func _layout() -> void:
	var n := stacks.size()
	var per_row := n if n <= 5 else int(ceil(n / 2.0))
	var rows := int(ceil(float(n) / per_row))
	var cw := minf(104.0, 440.0 / per_row)
	var ch := 118.0
	var x0 := 300 - per_row * cw / 2
	var y0 := 230.0 if rows == 1 else 120.0
	cub.clear()
	for i in n:
		var r := i / per_row
		var c := i % per_row
		var in_row := per_row if r < rows - 1 else n - per_row * (rows - 1)
		var xo := (per_row - in_row) * cw / 2
		cub.append(Rect2(x0 + xo + c * cw, y0 + r * (ch + 26), cw, ch))


func _book_pos(i: int, k: int) -> Vector2:
	var c: Rect2 = cub[i]
	return Vector2(c.position.x + c.size.x / 2, c.end.y - 12 - BH / 2 - k * BH)


func _set_level(i: int) -> void:
	lv = i
	stacks = _make_level(LEVELS[i])
	start = _copy(stacks)
	hist.clear()
	sel = -1
	done_set.clear()
	anim = {}
	hint_mv = []
	plan_path = []
	_layout()


# ---------------------------------------------------------------- input
func _cub_at(p: Vector2) -> int:
	for i in cub.size():
		var r: Rect2 = cub[i]
		if Rect2(r.position - Vector2(0, 20), r.size + Vector2(0, 20)).has_point(p):
			return i
	return -1


func click(p: Vector2) -> void:
	if busy() or phase != "play" or not anim.is_empty():
		return
	var i := _cub_at(p)
	if i < 0:
		sel = -1
		return
	if sel < 0:
		if stacks[i].size() > 0 and not _solved_stack(stacks[i]):
			sel = i
			Sfx.tone(600, 0.05, 0.04)
			if _top(stacks[i]) == 3 and not said.has("saga"):
				said["saga"] = true
				Dialog.say(["CARL:Oooh. A four-volume fantasy epic chronicling a feud between vampires and werewolves. Where are these meant to be shelved?"])
		elif stacks[i].size() > 0:
			Dialog.say(["That one's already sorted. Leave it alone. It's happy."])
		return
	if i == sel:
		sel = -1
		return
	if _can_move(sel, i, stacks):
		_do_move(sel, i)
	else:
		var pool := [0, 1, 3, 4]
		var msg: Array = BAD[2] if stacks[i].size() >= CAP else BAD[pool[bad_n % pool.size()]]
		bad_n += 1
		Dialog.say(msg)
		Sfx.tone(150, 0.15, 0.06, "square")
		shake_i = i
		shake_t = 0.3
		sel = -1


func _do_move(a: int, b: int) -> void:
	var c := _move_count(a, b, stacks)
	hist.append(_copy(stacks))
	var moving := []
	for i in c:
		var g: int = stacks[a].pop_back()
		moving.append({"g": g, "from": _book_pos(a, stacks[a].size()), "to": _book_pos(b, stacks[b].size() + i)})
	anim = {"a": a, "b": b, "list": moving, "t": 0.0}
	sel = -1
	hint_mv = []
	Sfx.tone(420, 0.08, 0.05, "sine")


func _finish_move() -> void:
	var b: int = anim.b
	var list: Array = anim.list
	for m in list:
		stacks[b].append(m.g)
	anim = {}
	Sfx.noise(0.08, 1200, 0.4)
	_on_genre_move(list[0].g)
	var s: Array = stacks[b]
	if _solved_stack(s) and s.size() > 0 and not done_set.has(b):
		done_set[b] = true
		for i in 3:
			Sfx.tone([523, 659, 784][i], 0.25, 0.05, "triangle", i * 0.08)
		var key: String = "done%d" % s[0]
		if not said.has(key):
			said[key] = true
			if s[0] == 3:
				Dialog.say([G[3].done, "Trust me, Carl. It's romance."])
			else:
				Dialog.say([G[s[0]].done])
	if _solved(stacks):
		phase = "talk"
		_level_done()
		return
	for x in stacks.size():
		for y in stacks.size():
			if _can_move(x, y, stacks):
				return
	Dialog.say(["You're stuck. Even I can't fix that. Well, I could. But Undo is right there."])


func _on_genre_move(g: int) -> void:
	if TITLES.has(g):
		var k: int = title_n.get(g, 0)
		var key := "t%d_%d" % [g, lv]
		if k < TITLES[g].size() and (g == 5 or not said.has(key)):
			said[key] = true
			title_n[g] = k + 1
			Dialog.say(TITLES[g][k])
	if g == 3 and lv == 2 and not said.has("juliet"):
		said["juliet"] = true
		Dialog.say(["CARL:'Romeo and Juliet.' Juliet, this blood is on your hands. The bare minimum would have been leaving a note."])
	if g == 2 and pun_n < PUN_CAP[lv] and pun_n < PUNS.size():
		Dialog.say(PUNS[pun_n])
		pun_n += 1


func _undo() -> void:
	if phase != "play" or not anim.is_empty() or hist.is_empty():
		return
	stacks = hist.pop_back()
	sel = -1
	_recount()
	Sfx.tone(300, 0.06, 0.04)
	if not said.has("undo"):
		said["undo"] = true
		Dialog.say(["CARL:Reversing one's mistakes. If only natural selection offered such a feature."])


func _redo() -> void:
	if phase != "play" or not anim.is_empty():
		return
	stacks = _copy(start)
	hist.clear()
	sel = -1
	done_set.clear()


func _apply(st: Array, mv: Array) -> Array:
	var ns := _copy(st)
	var c := _move_count(mv[0], mv[1], ns)
	for i in c:
		ns[mv[1]].append(ns[mv[0]].pop_back())
	return ns


func _hint() -> void:
	if phase != "play" or not anim.is_empty():
		return
	var mv := []
	var k := _plain_key(stacks)
	if plan_key == k and plan_path.size() > 0:
		mv = plan_path.pop_front()
	else:
		plan_path = _solve(stacks, 120000)
		if not plan_path.is_empty():
			mv = plan_path.pop_front()
	if mv.is_empty():
		Dialog.say(["There's no way out from here. Undo a few moves, or restart the shelf."])
		return
	plan_key = _plain_key(_apply(stacks, mv))
	hint_mv = mv
	hint_t = 3.0
	if not said.has("hint"):
		Dialog.say(["Fine. Move the glowing stack onto the other glowing one. Don't tell Carl I helped."])
	said["hint"] = true


func _plain_key(st: Array) -> String:
	var parts := []
	for s in st:
		parts.append(",".join(PackedStringArray(s.map(func(x): return str(x)))))
	return "|".join(PackedStringArray(parts))


func _recount() -> void:
	done_set.clear()
	for i in stacks.size():
		if stacks[i].size() > 0 and _solved_stack(stacks[i]):
			done_set[i] = true


func _level_done() -> void:
	await wait(0.6)
	Sfx.chime()
	while Dialog.blocking:
		await wait(0.1)
	await Dialog.say(AFTER[lv], _cue)
	if lv < 2:
		_set_level(lv + 1)
		phase = "play"
	else:
		phase = "end"
		await wait(0.8)
		finish(Vector2(300, 480))


# ---------------------------------------------------------------- update / draw
func tick(dt: float) -> void:
	shake_t = maxf(0, shake_t - dt)
	hint_t = maxf(0, hint_t - dt)
	if tape_t >= 0:
		tape_t += dt
	if not anim.is_empty():
		anim.t += dt
		if anim.t >= 0.38:
			_finish_move()
	for b in btns:
		b.disabled = phase != "play"
		b.visible = phase != "end"


func _draw_book(g: int, p: Vector2, lift: float, glow: bool) -> void:
	var w := minf(78.0, cub[0].size.x - 18 if cub.size() > 0 else 78.0) - ((g * 7) % 3) * 4
	var c := Color(G[g].c)
	var r := Rect2(p.x - w / 2, p.y - lift - BH / 2 + 1, w, BH - 2)
	if glow:
		Art.glow(self, r.get_center(), w * 0.8, Color(1, 0.91, 0.66, 0.45))
	Art.vgrad(self, r, Art.shade(c, 1.15), Art.shade(c, 0.8))
	draw_rect(Rect2(r.position, Vector2(w, 3)), Color(1, 1, 1, 0.22))
	draw_rect(Rect2(r.end.x - 6, r.position.y + 2, 3, BH - 6), Color("f3ead2"))
	draw_rect(Rect2(r.position.x + 5, r.position.y + 3, 2, BH - 8), Color(1, 0.85, 0.4, 0.5))
	var ink := Color(G[g].ink) if G[g].has("ink") else Color(1, 1, 1, 0.92)
	txt(Vector2(p.x - 3, p.y - lift + 4), G[g].ab, 10, ink)


func paint() -> void:
	draw_rect(big_rect(), Color("2a1d14"))
	for i in range(-12, 24):
		draw_rect(Rect2(i * 52, -600, 2, 1700), Color("3a2a1d"))
	Art.glow(self, Vector2(300, 60), 260, Color(1, 0.85, 0.55, 0.12))
	draw_rect(Rect2(-600, 520, 1800, 400), Color("5a2e2a"))
	for i in range(-20, 40):
		draw_rect(Rect2(i * 32, 540 + (i % 2) * 20, 16, 4), Color("6d3a34"))
	_decor()
	# bookcase frame
	if cub.size() > 0:
		var x0 := INF
		var x1 := -INF
		var y0 := INF
		var y1 := -INF
		for c in cub:
			x0 = minf(x0, c.position.x)
			x1 = maxf(x1, c.end.x)
			y0 = minf(y0, c.position.y)
			y1 = maxf(y1, c.end.y)
		Art.vgrad(self, Rect2(x0 - 14, y0 - 16, x1 - x0 + 28, y1 - y0 + 30), Color("7a4f2a"), Color("5b3a1d"))
		draw_rect(Rect2(x0 - 20, y0 - 28, x1 - x0 + 40, 14), Color("4a2e17"))
	for i in cub.size():
		var c: Rect2 = cub[i]
		var sx := sin(t * 60) * 4 if (i == shake_i and shake_t > 0) else 0.0
		Art.vgrad(self, Rect2(c.position.x + 5 + sx, c.position.y, c.size.x - 10, c.size.y - 6), Color("1e1209"), Color("3a2414"))
		draw_rect(Rect2(c.position.x + 2 + sx, c.end.y - 8, c.size.x - 4, 8), Color("8a5a30"))
		var hl: bool = hint_t > 0 and hint_mv.size() == 2 and (hint_mv[0] == i or hint_mv[1] == i)
		if hl or sel == i:
			draw_rect(Rect2(c.position.x + 4 + sx, c.position.y - 2, c.size.x - 8, c.size.y - 4), Color("7fe0ff") if hl else Color("ffcf5a"), false, 3.0)
		if done_set.has(i):
			txt(Vector2(c.position.x + c.size.x / 2, c.position.y + 14), "✓", 14, Color("ffe9a8"))
		var s: Array = stacks[i]
		var rl := _run_len(s) if sel == i else 0
		for k in s.size():
			var p := _book_pos(i, k) + Vector2(sx, 0)
			var up := k >= s.size() - rl
			_draw_book(s[k], p, 12.0 if up else 0.0, up)
	if not anim.is_empty():
		var k := minf(1.0, anim.t / 0.38)
		var e := 2 * k * k if k < 0.5 else 1 - pow(-2 * k + 2, 2) / 2
		for m in anim.list:
			var p: Vector2 = m.from.lerp(m.to, e) - Vector2(0, sin(k * PI) * 60)
			_draw_book(m.g, p, 0, true)
	var look := Vector2.ZERO
	if sel >= 0:
		look = (cub[sel].get_center() - Vector2(70, 470)).normalized()
	var cs := 0.24
	carl(Vector2(70, 520 - Art.carl_feet() * cs), cs, {"look": look, "talk": Dialog.blocking and Dialog._speaker == "carl"})
	light(Vector2(530, 70 + sin(t * 1.6) * 5), 18, {"glasses": glasses, "book": glasses})
	if tape_t >= 0:
		var k := minf(1.0, tape_t)
		draw_set_transform_matrix(cam * Transform2D(-0.1 + 0.1 * k, Vector2(300, 560 - k * 80)))
		Art.round_rect(self, Rect2(-46, -26, 92, 52), 4, Color("1b1b1f"))
		draw_rect(Rect2(-36, -20, 72, 16), Color("f2eee2"))
		txt(Vector2(0, -8), "DO NOT WATCH", 9, Color("d64535"))
		for dx in [-18, 18]:
			draw_circle(Vector2(dx, 10), 8, Color("555555"))
			draw_circle(Vector2(dx, 10), 3, Color("222222"))
		draw_set_transform_matrix(cam)
	if shh:
		draw_set_transform_matrix(cam * Transform2D(-0.2, Vector2(560, 300)))
		Art.text(self, Vector2.ZERO, "SHHHH!", 34, Color("c9d1dc"), 1, null, 6, Color("111111"))
		draw_set_transform_matrix(cam)
	txt(Vector2(16, 24), "Shelf %d of 3   ·   moves: %d" % [lv + 1, hist.size()], 13, Color("e9dcc4"), -1)
	if phase == "end":
		Art.text(self, Vector2(300, 585), "The library is sorted.", 22, Color("ffe9a8"), 0, Art.serif())


# ---------------------------------------------------------------- room decor
func _pot(p: Vector2, w: float, h: float, col: Color) -> void:
	## A flower pot standing on the floor at p (bottom centre).
	Art.ellipse(self, p + Vector2(0, 1), w * 0.7, 4, Color(0, 0, 0, 0.25))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-w / 2, -h), p + Vector2(w / 2, -h), p + Vector2(w * 0.36, 0), p + Vector2(-w * 0.36, 0)]), col)
	draw_rect(Rect2(p + Vector2(-w / 2 - 2, -h - 5), Vector2(w + 4, 7)), Art.shade(col, 1.12))
	draw_rect(Rect2(p + Vector2(w * 0.18, -h + 4), Vector2(3, h - 8)), Color(1, 1, 1, 0.12))


func _leaf(base: Vector2, ang: float, ln: float, wd: float, col: Color) -> void:
	var d := Vector2.from_angle(ang)
	var n := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([base, base + d * ln * 0.5 + n * wd, base + d * ln, base + d * ln * 0.5 - n * wd]), col)
	draw_line(base, base + d * ln * 0.9, Art.shade(col, 0.75), 1.0)


func _fern(p: Vector2, s: float) -> void:
	_pot(p, 34 * s, 30 * s, Color("b0603a"))
	for i in 9:
		var a := -PI / 2 + (i - 4) * 0.33 + sin(t * 0.8 + i) * 0.03
		var tip := p + Vector2(0, -32 * s) + Vector2.from_angle(a) * 52 * s
		draw_line(p + Vector2(0, -32 * s), tip, Color("2f6b2a"), 1.5)
		for k in 6:
			var f := (k + 1) / 7.0
			var q := (p + Vector2(0, -32 * s)).lerp(tip, f)
			_leaf(q, a - 0.9, 10 * s * (1.1 - f), 2.4 * s, Color("3f8a3a"))
			_leaf(q, a + 0.9, 10 * s * (1.1 - f), 2.4 * s, Color("4f9a3e"))


func _snake_plant(p: Vector2, s: float) -> void:
	_pot(p, 30 * s, 26 * s, Color("e8e2d4"))
	for i in 6:
		var x := (i - 2.5) * 4.5 * s
		var h := (60 + (i * 23) % 30) * s
		var lean := (i - 2.5) * 3 * s
		var col := Color("3d7a3a") if i % 2 else Color("5a9a48")
		draw_colored_polygon(PackedVector2Array([p + Vector2(x - 4 * s, -26 * s), p + Vector2(x + lean, -26 * s - h), p + Vector2(x + 4 * s, -26 * s)]), col)
		draw_line(p + Vector2(x - 2 * s, -30 * s), p + Vector2(x + lean * 0.8, -20 * s - h * 0.85), Color("c9d27a"), 1.0)


func _ficus(p: Vector2, s: float) -> void:
	_pot(p, 40 * s, 34 * s, Color("3a4a6a"))
	var top := p + Vector2(0, -150 * s)
	draw_line(p + Vector2(0, -34 * s), top, Color("6a4a2a"), 4 * s)
	draw_line(p + Vector2(0, -90 * s), p + Vector2(-26 * s, -120 * s), Color("6a4a2a"), 2.5 * s)
	for c in [[-26, 10, 22], [24, 6, 24], [0, -14, 28], [-8, 22, 22], [18, 28, 18], [-30, -12, 16]]:
		draw_circle(top + Vector2(c[0], c[1]) * s, c[2] * s, Color("2f6b2a"))
	for c in [[-20, 4, 16], [20, 0, 18], [2, -18, 20], [-4, 18, 14]]:
		draw_circle(top + Vector2(c[0], c[1]) * s, c[2] * s, Color("3f8a3a"))
	for i in 30:
		var a := float(i) * 2.4
		var r := (8 + (i * 7) % 34) * s
		var q := top + Vector2(cos(a) * r * 1.2, sin(a) * r * 0.9 + 4 * s)
		_leaf(q, a + 0.6, 13 * s, 5 * s, Color("4f9a3e") if i % 3 else Color("6fb35c"))


func _cactus(p: Vector2, s: float) -> void:
	_pot(p, 26 * s, 20 * s, Color("c27a4a"))
	var c := Color("5a9a48")
	Art.round_rect(self, Rect2(p + Vector2(-7, -64) * s, Vector2(14, 46) * s), 7 * s, c)
	Art.round_rect(self, Rect2(p + Vector2(-17, -50) * s, Vector2(8, 22) * s), 4 * s, c)
	draw_rect(Rect2(p + Vector2(-14, -32) * s, Vector2(10, 6) * s), c)
	for k in 5:
		draw_line(p + Vector2(-2, -60 + k * 9) * s, p + Vector2(-4, -61 + k * 9) * s, Color("e8f0c8"), 1.0)
	draw_circle(p + Vector2(0, -66) * s, 3 * s, Color("ff7aa8"))


func _frame(r: Rect2, kind: String) -> void:
	## A framed picture on the wall.
	Art.ellipse(self, Vector2(r.get_center().x, r.position.y - 10), 2, 2, Color("8a7a5a"))
	draw_line(Vector2(r.get_center().x, r.position.y - 10), r.position + Vector2(8, 0), Color(0, 0, 0, 0.3), 1.0)
	draw_line(Vector2(r.get_center().x, r.position.y - 10), r.position + Vector2(r.size.x - 8, 0), Color(0, 0, 0, 0.3), 1.0)
	draw_rect(r.grow(4), Color(0, 0, 0, 0.25))
	draw_rect(r.grow(3), Color("b8913a"))
	draw_rect(r.grow(1), Color("8a6a24"))
	var c := r.get_center()
	match kind:
		"fish":
			Art.vgrad(self, r, Color("2a5a7a"), Color("16324a"))
			Art.ellipse(self, c, r.size.x * 0.26, r.size.y * 0.16, Color("e07a5a"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r.size.x * 0.22, 0), c + Vector2(-r.size.x * 0.4, -r.size.y * 0.12), c + Vector2(-r.size.x * 0.4, r.size.y * 0.12)]), Color("c45a3a"))
			draw_circle(c + Vector2(r.size.x * 0.14, -3), 2.5, Color.WHITE)
			draw_circle(c + Vector2(r.size.x * 0.15, -3), 1.2, Color.BLACK)
			Art.ellipse(self, c + Vector2(0, -r.size.y * 0.34), 9, 3, Color("222222"))
			draw_rect(Rect2(c + Vector2(-5, -r.size.y * 0.42), Vector2(10, 7)), Color("222222"))
			draw_rect(Rect2(r.position.x + 8, r.end.y - 12, r.size.x - 16, 7), Color("d8c08a"))
		"sea":
			Art.vgrad(self, Rect2(r.position, Vector2(r.size.x, r.size.y * 0.55)), Color("f2b77a"), Color("f7dcae"))
			draw_circle(c + Vector2(r.size.x * 0.18, -r.size.y * 0.02), r.size.y * 0.13, Color("ffe08a"))
			Art.vgrad(self, Rect2(r.position + Vector2(0, r.size.y * 0.55), Vector2(r.size.x, r.size.y * 0.45)), Color("3a7ab0"), Color("24507a"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r.size.x * 0.2, r.size.y * 0.06), c + Vector2(-r.size.x * 0.1, -r.size.y * 0.3), c + Vector2(-r.size.x * 0.1, r.size.y * 0.06)]), Color("f2eee2"))
			draw_line(c + Vector2(-r.size.x * 0.22, r.size.y * 0.08), c + Vector2(-r.size.x * 0.02, r.size.y * 0.08), Color("6a3a20"), 3.0)
		"light":
			Art.vgrad(self, r, Color("3a3050"), Color("1e1a30"))
			Art.glow(self, c, r.size.x * 0.5, Color(1, 0.9, 0.6, 0.5))
			draw_circle(c, r.size.x * 0.17, Color("fff4c8"))
			draw_circle(c + Vector2(-4, -2), 1.5, Color("2a2030"))
			draw_circle(c + Vector2(4, -2), 1.5, Color("2a2030"))
			draw_rect(Rect2(r.position.x + 6, r.end.y - 14, r.size.x - 12, 9), Color("d8c08a"))
			txt(Vector2(c.x, r.end.y - 7), "EMPLOYEE OF THE EON", 5, Color("3a2a10"))
		"hills":
			Art.vgrad(self, r, Color("9fd0f0"), Color("e6f4fa"))
			draw_colored_polygon(PackedVector2Array([r.position + Vector2(0, r.size.y * 0.7), r.position + Vector2(r.size.x * 0.35, r.size.y * 0.35), r.position + Vector2(r.size.x * 0.7, r.size.y * 0.65), r.end - Vector2(0, r.size.y * 0.45), r.end, r.end - Vector2(r.size.x, 0)]), Color("5aa34a"))
			draw_colored_polygon(PackedVector2Array([r.position + Vector2(r.size.x * 0.27, r.size.y * 0.43), r.position + Vector2(r.size.x * 0.35, r.size.y * 0.35), r.position + Vector2(r.size.x * 0.43, r.size.y * 0.43)]), Color("f2f2f2"))
		_:
			# a diploma
			draw_rect(r, Color("f4efe0"))
			txt(Vector2(c.x, r.position.y + 14), "DIPLOMA", 8, Color("5a4630"))
			for k in 3:
				draw_line(Vector2(r.position.x + 10, r.position.y + 24 + k * 7), Vector2(r.end.x - 10, r.position.y + 24 + k * 7), Color(0, 0, 0, 0.2), 1.0)
			draw_circle(Vector2(r.end.x - 14, r.end.y - 12), 6, Color("d64535"))


func _window(r: Rect2) -> void:
	## An arched window with curtains looking out on a starry night.
	Art.round_rect(self, r.grow(6), r.size.x * 0.5, Color("5b3a1d"))
	Art.round_rect(self, r, r.size.x * 0.5, Color("1a2340"))
	for i in 14:
		var sp := Vector2(r.position.x + 8 + (i * 37) % int(r.size.x - 16), r.position.y + 20 + (i * 53) % int(r.size.y * 0.6))
		draw_circle(sp, 1.0 + (i % 3) * 0.4, Color(1, 1, 0.9, 0.4 + 0.4 * sin(t * 2 + i)))
	draw_circle(r.position + Vector2(r.size.x * 0.68, 46), 12, Color("f2eed8"))
	draw_circle(r.position + Vector2(r.size.x * 0.68 + 5, 42), 11, Color("1a2340"))
	draw_line(Vector2(r.get_center().x, r.position.y + 2), Vector2(r.get_center().x, r.end.y), Color("5b3a1d"), 4.0)
	draw_line(Vector2(r.position.x, r.position.y + r.size.y * 0.55), Vector2(r.end.x, r.position.y + r.size.y * 0.55), Color("5b3a1d"), 4.0)
	draw_rect(Rect2(r.position.x - 12, r.end.y + 4, r.size.x + 24, 8), Color("7a4f2a"))
	for side in [-1, 1]:
		var cx: float = r.position.x - 6 if side < 0 else r.end.x + 6
		var sw := sin(t * 0.7) * 2
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 14 * side, r.position.y - 16), Vector2(cx + 18 * side, r.position.y - 16), Vector2(cx + 6 * side + sw, r.end.y - 30), Vector2(cx + 12 * side + sw, r.end.y + 20), Vector2(cx - 14 * side, r.end.y + 20)]), Color("8a2a32"))
		draw_line(Vector2(cx, r.position.y - 10), Vector2(cx + sw, r.end.y + 16), Color(0, 0, 0, 0.15), 2.0)
	draw_rect(Rect2(r.position.x - 34, r.position.y - 22, r.size.x + 68, 6), Color("b8913a"))


func _floor_lamp(p: Vector2) -> void:
	Art.glow(self, p + Vector2(0, -150), 90, Color(1, 0.85, 0.5, 0.18))
	Art.ellipse(self, p, 16, 4, Color("2a2a2a"))
	draw_line(p, p + Vector2(0, -140), Color("2a2a2a"), 3.0)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-14, -136), p + Vector2(14, -136), p + Vector2(9, -166), p + Vector2(-9, -166)]), Color("f0d9a0"))
	draw_line(p + Vector2(-14, -136), p + Vector2(14, -136), Color("c9a860"), 2.0)


func _armchair(p: Vector2) -> void:
	var c := Color("2f6b5a")
	var d := Art.shade(c, 0.75)
	Art.ellipse(self, p + Vector2(0, 2), 56, 6, Color(0, 0, 0, 0.25))
	Art.round_rect(self, Rect2(p + Vector2(-44, -96), Vector2(88, 70)), 16, d)
	Art.round_rect(self, Rect2(p + Vector2(-50, -50), Vector2(100, 36)), 8, c)
	for sx in [-56.0, 36.0]:
		Art.round_rect(self, Rect2(p + Vector2(sx, -62), Vector2(20, 48)), 9, Art.shade(c, 1.1))
	for k in 3:
		draw_circle(p + Vector2(-24 + k * 24, -78), 2, Color("1e4a3a"))
	for lx in [-40.0, 40.0]:
		draw_rect(Rect2(p + Vector2(lx - 3, -14), Vector2(6, 14)), Color("4a2e17"))
	# an open book left on the seat
	draw_colored_polygon(PackedVector2Array([p + Vector2(-12, -52), p + Vector2(0, -48), p + Vector2(12, -52), p + Vector2(12, -46), p + Vector2(0, -42), p + Vector2(-12, -46)]), Color("f4efe0"))


func _clock(p: Vector2) -> void:
	## Grandfather clock standing at p (bottom centre) with a swinging pendulum.
	var w := 56.0
	Art.ellipse(self, p + Vector2(0, 2), 34, 5, Color(0, 0, 0, 0.25))
	Art.vgrad(self, Rect2(p + Vector2(-w / 2, -230), Vector2(w, 230)), Color("6a3e1e"), Color("4a2a12"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-w / 2 - 4, -230), p + Vector2(0, -250), p + Vector2(w / 2 + 4, -230)]), Color("5a3418"))
	draw_circle(p + Vector2(0, -196), 22, Color("b8913a"))
	draw_circle(p + Vector2(0, -196), 19, Color("f4efe0"))
	for k in 12:
		var a := k * TAU / 12
		draw_line(p + Vector2(0, -196) + Vector2.from_angle(a) * 15, p + Vector2(0, -196) + Vector2.from_angle(a) * 18, Color("3a2a10"), 1.0)
	draw_line(p + Vector2(0, -196), p + Vector2(0, -196) + Vector2.from_angle(t * 0.2 - PI / 2) * 13, Color("222222"), 1.5)
	draw_line(p + Vector2(0, -196), p + Vector2(0, -196) + Vector2.from_angle(t * 0.02 - PI / 2.5) * 9, Color("222222"), 2.0)
	var win := Rect2(p + Vector2(-16, -164), Vector2(32, 120))
	draw_rect(win, Color("2a1608"))
	var sw := sin(t * 2.6) * 0.32
	var top := win.position + Vector2(16, 4)
	var bob := top + Vector2(sin(sw), cos(sw)) * 88
	draw_line(top, bob, Color("b8913a"), 2.0)
	draw_circle(bob, 9, Color("d8b04a"))
	draw_rect(win, Color(1, 1, 1, 0.06))
	draw_rect(Rect2(p + Vector2(-w / 2 - 4, -26), Vector2(w + 8, 26)), Color("5a3418"))


func _globe(p: Vector2) -> void:
	Art.ellipse(self, p + Vector2(0, 2), 26, 5, Color(0, 0, 0, 0.25))
	for lx in [-18.0, 0.0, 18.0]:
		draw_line(p + Vector2(lx, 0), p + Vector2(0, -54), Color("5a3418"), 3.0)
	var c := p + Vector2(0, -86)
	draw_arc(c, 34, PI * 0.6, PI * 2.2, 24, Color("b8913a"), 3.0)
	draw_circle(c, 30, Color("3a7ab0"))
	var spin := fmod(t * 6.0, 60.0)
	for k in 3:
		var x := fmod(spin + k * 22.0, 60.0) - 30
		var ww := 12 * sqrt(maxf(0.0, 1.0 - pow(x / 30.0, 2)))
		if ww > 1:
			Art.ellipse(self, c + Vector2(x, -10 + k * 9), ww, 7, Color("6fb35c"))
	draw_circle(c + Vector2(-10, -10), 6, Color(1, 1, 1, 0.18))


func _side_table(p: Vector2) -> void:
	draw_rect(Rect2(p + Vector2(-30, -60), Vector2(60, 6)), Color("6a3e1e"))
	for lx in [-26.0, 22.0]:
		draw_rect(Rect2(p + Vector2(lx, -54), Vector2(4, 54)), Color("4a2a12"))
	# banker's lamp
	draw_rect(Rect2(p + Vector2(-4, -80), Vector2(3, 20)), Color("b8913a"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-18, -80), p + Vector2(14, -80), p + Vector2(10, -92), p + Vector2(-14, -92)]), Color("2f7a4a"))
	Art.glow(self, p + Vector2(-2, -76), 40, Color(1, 0.9, 0.5, 0.25))
	# a stack of books
	for k in 3:
		draw_rect(Rect2(p + Vector2(4 - k * 2, -66 - k * 5), Vector2(22, 5)), [Color("d64535"), Color("3d7fd9"), Color("e3c234")][k])


func _cabinet(p: Vector2) -> void:
	Art.ellipse(self, p + Vector2(0, 2), 36, 5, Color(0, 0, 0, 0.25))
	Art.vgrad(self, Rect2(p + Vector2(-32, -150), Vector2(64, 150)), Color("8a9098"), Color("6a7078"))
	for k in 4:
		var y := -146 + k * 37
		draw_rect(Rect2(p + Vector2(-28, y), Vector2(56, 33)), Color("7a8088"))
		draw_rect(Rect2(p + Vector2(-10, y + 8), Vector2(20, 4)), Color("c8ccd2"))
		draw_rect(Rect2(p + Vector2(-8, y + 16), Vector2(16, 7)), Color("f4efe0"))
	draw_rect(Rect2(p + Vector2(-26, -183), Vector2(18, 33)), Color("d64535"))
	draw_rect(Rect2(p + Vector2(-6, -176), Vector2(16, 26)), Color("3d7fd9"))
	draw_rect(Rect2(p + Vector2(12, -171), Vector2(14, 21)), Color("e3c234"))


func _poster(r: Rect2) -> void:
	draw_rect(r, Color("2f6b9a"))
	draw_rect(r.grow(-6), Color("f2c14a"))
	txt(Vector2(r.get_center().x, r.position.y + 34), "READ", 22, Color("2f3a5a"))
	# a little open book with sparkles
	var c := r.get_center() + Vector2(0, 20)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-26, -8), c + Vector2(0, -2), c + Vector2(26, -8), c + Vector2(26, 12), c + Vector2(0, 18), c + Vector2(-26, 12)]), Color("f4efe0"))
	draw_line(c + Vector2(0, -2), c + Vector2(0, 18), Color("8a7a5a"), 1.5)
	for k in 3:
		draw_circle(c + Vector2(-16 + k * 16, -20 - (k % 2) * 8), 2.5, Color.WHITE)
	for k in 4:
		draw_circle(r.position + Vector2(4 + (k % 2) * (r.size.x - 8), 4 + (k / 2) * (r.size.y - 8)), 2.5, Color("c9c9c9"))


func _hanging_plant(p: Vector2) -> void:
	draw_line(p + Vector2(0, -400), p, Color("8a7a5a"), 1.0)
	for sx in [-14.0, 14.0]:
		draw_line(p, p + Vector2(sx, 22), Color("8a7a5a"), 1.0)
	Art.ellipse(self, p + Vector2(0, 30), 18, 12, Color("c27a4a"))
	draw_rect(Rect2(p + Vector2(-18, 18), Vector2(36, 12)), Color("c27a4a"))
	for i in 7:
		var sx := -16 + i * 5.3
		var ln := 40 + (i * 17) % 50
		var sw := sin(t * 0.9 + i) * 3
		var pts := PackedVector2Array()
		for k in 6:
			var f := k / 5.0
			pts.append(p + Vector2(sx + sin(f * 3 + i) * 6 + sw * f, 22 + f * ln))
		draw_polyline(pts, Color("3f8a3a"), 1.5)
		for k in range(1, 6):
			_leaf(pts[k], PI / 2 + (0.8 if k % 2 else -0.8), 9, 3, Color("5aa34a") if (i + k) % 2 else Color("3f8a3a"))


func _tv_cart(p: Vector2) -> void:
	## The TV and VCR in the corner (where the tape ends up).
	Art.ellipse(self, p + Vector2(0, 2), 60, 6, Color(0, 0, 0, 0.25))
	for lx in [-50.0, 46.0]:
		draw_rect(Rect2(p + Vector2(lx, -70), Vector2(4, 66)), Color("6a7078"))
		draw_circle(p + Vector2(lx + 2, -3), 4, Color("2a2a2a"))
	draw_rect(Rect2(p + Vector2(-54, -74), Vector2(108, 6)), Color("8a9098"))
	draw_rect(Rect2(p + Vector2(-54, -26), Vector2(108, 5)), Color("8a9098"))
	Art.round_rect(self, Rect2(p + Vector2(-40, -42), Vector2(80, 16)), 3, Color("1b1b1f"))
	draw_rect(Rect2(p + Vector2(-30, -37), Vector2(30, 3)), Color("08080a"))
	draw_rect(Rect2(p + Vector2(12, -38), Vector2(12, 5)), Color("102a12"))
	txt(Vector2(p.x + 18, p.y - 34.5), "12:00", 4, Color("7fe08a") if int(t * 1.5) % 2 == 0 else Color("102a12"))
	Art.round_rect(self, Rect2(p + Vector2(-50, -150), Vector2(100, 76)), 8, Color("6a4a2a"))
	Art.round_rect(self, Rect2(p + Vector2(-42, -142), Vector2(70, 58)), 10, Color("2a3036"))
	Art.round_rect(self, Rect2(p + Vector2(-38, -138), Vector2(62, 50)), 10, Color("3a4a52"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-34, -134), p + Vector2(-10, -134), p + Vector2(-28, -100)]), Color(1, 1, 1, 0.08))
	for k in 2:
		draw_circle(p + Vector2(38, -130 + k * 16), 4, Color("2a2a2a"))
	for k in 4:
		draw_line(p + Vector2(32, -98 + k * 3), p + Vector2(44, -98 + k * 3), Color("3a2a1a"), 1.0)
	draw_line(p + Vector2(-6, -150), p + Vector2(-26, -186), Color("aaaaaa"), 1.5)
	draw_line(p + Vector2(6, -150), p + Vector2(30, -182), Color("aaaaaa"), 1.5)


func _wall_clock(p: Vector2) -> void:
	draw_circle(p, 22, Color("2a2a2a"))
	draw_circle(p, 19, Color("f4efe0"))
	for k in 12:
		var a := k * TAU / 12
		draw_line(p + Vector2.from_angle(a) * 15, p + Vector2.from_angle(a) * 17, Color("3a3a3a"), 1.5 if k % 3 == 0 else 1.0)
	draw_line(p, p + Vector2.from_angle(t * 0.5 - PI / 2) * 14, Color("d64535"), 1.0)
	draw_line(p, p + Vector2.from_angle(t * 0.04) * 11, Color("222222"), 2.0)
	draw_line(p, p + Vector2.from_angle(-PI / 3) * 8, Color("222222"), 2.5)


func _rug(c: Vector2, rx: float, col: Color, col2: Color) -> void:
	Art.ellipse(self, c, rx, 22, col)
	Art.ellipse_line(self, c, rx - 10, 15, col2, 3.0)
	Art.ellipse_line(self, c, rx - 22, 9, col2, 2.0)


func _decor() -> void:
	## Each shelf level is a different room of the library.
	match lv:
		0:
			# the reading room
			_window(Rect2(-196, 140, 120, 220))
			_rug(Vector2(300, 556), 230, Color("7a2a32"), Color("d8b04a"))
			_fern(Vector2(-30, 528), 1.0)
			_frame(Rect2(640, 130, 110, 90), "fish")
			_armchair(Vector2(700, 530))
			_floor_lamp(Vector2(790, 528))
			_fern(Vector2(-200, 528), 0.8)
		1:
			# the study
			_frame(Rect2(-210, 120, 150, 100), "sea")
			_clock(Vector2(-150, 528))
			_snake_plant(Vector2(-40, 528), 1.0)
			_rug(Vector2(300, 556), 230, Color("2f4a6a"), Color("c9a860"))
			_frame(Rect2(650, 110, 90, 70), "diploma")
			_frame(Rect2(660, 210, 70, 60), "hills")
			_globe(Vector2(680, 530))
			_side_table(Vector2(780, 528))
			_ficus(Vector2(800, 528), 0.7)
		_:
			# the archive corner, with the TV and VCR
			_poster(Rect2(-200, 140, 100, 130))
			_cabinet(Vector2(-150, 528))
			_hanging_plant(Vector2(-50, 120))
			_cactus(Vector2(-40, 528), 1.0)
			_rug(Vector2(300, 556), 230, Color("3a5a3a"), Color("e8d8a0"))
			_frame(Rect2(650, 120, 90, 90), "light")
			_wall_clock(Vector2(780, 130))
			_tv_cart(Vector2(710, 528))
			_ficus(Vector2(810, 528), 0.75)
