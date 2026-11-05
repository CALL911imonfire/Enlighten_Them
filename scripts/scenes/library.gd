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
