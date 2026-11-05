class_name Art
extends RefCounted
## Code-drawn art helpers shared by every scene: shapes, glows, the light
## (God, the Beginning) with all its props, and Carl drawn from Game.carl.
## Nothing here loads an image file; every pixel comes from these functions.

## Camera transform of the scene currently drawing. Art functions draw on top of it.
static var cam := Transform2D()
static var _glow_tex: GradientTexture2D
static var _font: Font
static var _serif: SystemFont

const CARL_RX := 115.0
const CARL_RY := 64.0
const LIMB := {"leg": 44.0, "arm": 40.0, "fin": 24.0, "horn": 26.0, "antenna": 40.0, "wing": 40.0, "ear": 14.0}


# ---------------------------------------------------------------- basics
static func font() -> Font:
	if _font == null:
		_font = ThemeDB.fallback_font
	return _font


static func serif() -> Font:
	if _serif == null:
		_serif = SystemFont.new()
		_serif.font_names = PackedStringArray(["Georgia", "Palatino Linotype", "Times New Roman", "serif"])
	return _serif


static func text(ci: CanvasItem, pos: Vector2, s: String, size := 16, col := Color.WHITE, align := 0, f: Font = null, outline := 0, outline_col := Color.BLACK) -> void:
	## align: -1 left, 0 centre, 1 right. pos is the baseline anchor.
	var fo := f if f else font()
	var w := fo.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x := pos.x
	if align == 0:
		x -= w / 2.0
	elif align == 1:
		x -= w
	if outline > 0:
		ci.draw_string_outline(fo, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, outline_col)
	ci.draw_string(fo, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func shade(c: Color, k: float) -> Color:
	return Color(clampf(c.r * k, 0, 1), clampf(c.g * k, 0, 1), clampf(c.b * k, 0, 1), c.a)


static func ellipse_pts(c: Vector2, rx: float, ry: float, rot := 0.0, n := 40, a0 := 0.0, a1 := TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var full := is_equal_approx(a1 - a0, TAU)
	var count := n if full else n + 1
	for i in count:
		var a := a0 + (a1 - a0) * float(i) / float(n)
		var p := Vector2(cos(a) * rx, sin(a) * ry).rotated(rot)
		pts.append(c + p)
	return pts


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot := 0.0) -> void:
	if rx < 0.3 or ry < 0.3:
		return
	ci.draw_colored_polygon(ellipse_pts(c, rx, ry, rot, 36), col)


static func ellipse_line(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, width := 2.0, rot := 0.0, a0 := 0.0, a1 := TAU) -> void:
	var pts := ellipse_pts(c, rx, ry, rot, 48, a0, a1)
	if is_equal_approx(a1 - a0, TAU):
		pts.append(pts[0])
	ci.draw_polyline(pts, col, width, true)


static func quad(p0: Vector2, p1: Vector2, p2: Vector2, n := 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var k := float(i) / n
		pts.append(p0.lerp(p1, k).lerp(p1.lerp(p2, k), k))
	return pts


static func round_rect(ci: CanvasItem, r: Rect2, rad: float, col: Color) -> void:
	rad = minf(rad, minf(r.size.x, r.size.y) / 2.0)
	var pts := PackedVector2Array()
	var cs := [r.position + Vector2(r.size.x - rad, rad), r.position + Vector2(r.size.x - rad, r.size.y - rad), r.position + Vector2(rad, r.size.y - rad), r.position + Vector2(rad, rad)]
	var starts := [-PI / 2, 0.0, PI / 2, PI]
	for i in 4:
		for j in 7:
			var a: float = starts[i] + PI / 2 * j / 6.0
			pts.append(cs[i] + Vector2(cos(a), sin(a)) * rad)
	ci.draw_colored_polygon(pts, col)


static func vgrad(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	var pts := PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)])
	ci.draw_polygon(pts, PackedColorArray([top, top, bottom, bottom]))


static func _gtex() -> GradientTexture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		g.add_point(0.7, Color(1, 1, 1, 0.12))
		_glow_tex = GradientTexture2D.new()
		_glow_tex.gradient = g
		_glow_tex.fill = GradientTexture2D.FILL_RADIAL
		_glow_tex.fill_from = Vector2(0.5, 0.5)
		_glow_tex.fill_to = Vector2(1.0, 0.5)
		_glow_tex.width = 128
		_glow_tex.height = 128
	return _glow_tex


## Soft radial glow (an additive-looking blob).
static func glow(ci: CanvasItem, pos: Vector2, radius: float, col: Color) -> void:
	if radius <= 0.5 or col.a <= 0.0:
		return
	ci.draw_texture_rect(_gtex(), Rect2(pos - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, col)


static func make_stars(n: int, area: Rect2, seed_val := 7) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var out := []
	for i in n:
		out.append({"p": Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y)),
			"s": rng.randf_range(0.4, 2.0), "ph": rng.randf() * TAU, "c": [Color("ffffff"), Color("fff3d6"), Color("d6e6ff")][rng.randi() % 3]})
	return out


static func draw_stars(ci: CanvasItem, stars: Array, t: float, alpha := 1.0) -> void:
	for s in stars:
		var a: float = alpha * (0.4 + 0.6 * (0.5 + 0.5 * sin(t * 1.5 + s.ph)))
		var c: Color = s.c
		c.a = a
		if s.s > 1.6:
			glow(ci, s.p, s.s * 4.0, Color(c.r, c.g, c.b, a * 0.35))
		ci.draw_circle(s.p, s.s * 0.6, c)


static func vignette(ci: CanvasItem, r: Rect2, strength := 0.55) -> void:
	var c := Color(0, 0, 0, strength)
	var e := r.size.y * 0.22
	vgrad(ci, Rect2(r.position, Vector2(r.size.x, e)), c, Color(0, 0, 0, 0))
	vgrad(ci, Rect2(r.position + Vector2(0, r.size.y - e), Vector2(r.size.x, e)), Color(0, 0, 0, 0), c)


## A music note drawn with shapes (single or a pair joined by a beam).
static func note(ci: CanvasItem, p: Vector2, s: float, col: Color, double := false) -> void:
	ellipse(ci, p, s * 0.42, s * 0.3, col, -0.4)
	ci.draw_line(p + Vector2(s * 0.36, -s * 0.05), p + Vector2(s * 0.36, -s * 1.3), col, maxf(1.5, s * 0.12))
	if double:
		ellipse(ci, p + Vector2(s * 0.9, -s * 0.2), s * 0.42, s * 0.3, col, -0.4)
		ci.draw_line(p + Vector2(s * 1.26, -s * 0.25), p + Vector2(s * 1.26, -s * 1.5), col, maxf(1.5, s * 0.12))
		ci.draw_line(p + Vector2(s * 0.36, -s * 1.3), p + Vector2(s * 1.26, -s * 1.5), col, maxf(2.0, s * 0.25))
	else:
		ci.draw_polyline(quad(p + Vector2(s * 0.36, -s * 1.3), p + Vector2(s * 0.9, -s * 1.0), p + Vector2(s * 0.75, -s * 0.55), 6), col, maxf(1.5, s * 0.12), true)


## A shaded sphere: stacked circles that drift towards the light source.
static func ball(ci: CanvasItem, pos: Vector2, r: float, col: Color, light_dir := Vector2(-0.4, -0.4)) -> void:
	ci.draw_circle(pos, r, shade(col, 0.45))
	for i in 7:
		var k := float(i + 1) / 8.0
		ci.draw_circle(pos + light_dir * r * k * 0.9, r * (1.0 - k * 0.72), shade(col, 0.55 + k * 0.75).lerp(Color.WHITE, k * k * 0.35))


# ---------------------------------------------------------------- the light
static func light_glow(ci: CanvasItem, pos: Vector2, r: float, t: float) -> void:
	var pulse := (1.0 + sin(t * 2.0)) * 0.5
	glow(ci, pos, r * (2.1 + 0.15 * pulse), Color(1, 0.88, 0.55, 0.55))
	glow(ci, pos, r * 1.2, Color(1, 0.98, 0.9, 0.95))
	ci.draw_circle(pos, r * 0.62, Color(1, 1, 0.97, 1))


## The narrator: a soft glowing orb with little eyes and swappable props.
## props: hat, mic, goggles, glasses, book, band, cowboy, shades, pilot, popcorn,
##        mailcap, visor, headset, helmet, dim (0..1), squint, look (Vector2)
static func draw_light(ci: CanvasItem, pos: Vector2, r: float, t: float, props := {}) -> void:
	var dim: float = props.get("dim", 0.0)
	if dim >= 1.0:
		return
	var a := 1.0 - dim
	ci.draw_set_transform_matrix(cam)
	var pulse := (1.0 + sin(t * 2.0)) * 0.5
	glow(ci, pos, r * (2.2 + 0.2 * pulse), Color(1, 0.86, 0.5, 0.5 * a))
	glow(ci, pos, r * 1.25, Color(1, 0.98, 0.9, 0.95 * a))
	ci.draw_circle(pos, r * 0.66, Color(1, 1, 0.96, a))
	# eyes
	var look: Vector2 = props.get("look", Vector2.ZERO)
	var blink := fmod(t + 0.7, 4.3) < 0.12
	var ey := pos + Vector2(0, -r * 0.08)
	for sx in [-1.0, 1.0]:
		var e: Vector2 = ey + Vector2(sx * r * 0.27, 0) + look.limit_length(1.0) * r * 0.06
		if blink or props.get("squint", false):
			ci.draw_line(e - Vector2(r * 0.09, 0), e + Vector2(r * 0.09, 0), Color(0.35, 0.25, 0.1, 0.8 * a), maxf(1.5, r * 0.06), true)
		else:
			ellipse(ci, e, r * 0.07, r * 0.11, Color(0.3, 0.22, 0.08, 0.85 * a))
	var col_dark := Color(0.23, 0.18, 0.13, a)
	if props.get("hat", false):
		ci.draw_colored_polygon(ellipse_pts(pos + Vector2(0, -r * 0.55), r * 0.78, r * 0.78, 0, 20, PI, TAU), Color("ffc21a"))
		ci.draw_rect(Rect2(pos.x - r * 1.08, pos.y - r * 0.62, r * 2.16, r * 0.22), Color("f2b200"))
		ci.draw_rect(Rect2(pos.x - r * 0.12, pos.y - r * 1.3, r * 0.24, r * 0.72), Color("e0a400"))
	if props.get("goggles", false):
		ci.draw_line(pos + Vector2(-r * 1.3, -r * 0.12), pos + Vector2(r * 1.3, -r * 0.12), Color("5a4632"), 3.0, true)
		for sx in [-1.0, 1.0]:
			var g: Vector2 = pos + Vector2(sx * r * 0.42, -r * 0.12)
			ci.draw_circle(g, r * 0.36, Color(0.47, 0.86, 1, 0.55))
			ellipse_line(ci, g, r * 0.36, r * 0.36, Color("3b2e22"), 3.0)
	if props.get("glasses", false):
		for sx in [-1.0, 1.0]:
			ellipse_line(ci, pos + Vector2(sx * r * 0.3, -r * 0.06), r * 0.22, r * 0.17, col_dark, 2.2)
		ci.draw_line(pos + Vector2(-r * 0.08, -r * 0.08), pos + Vector2(r * 0.08, -r * 0.08), col_dark, 2.0)
	if props.get("book", false):
		var bx := pos.x - r * 2.6
		var by := pos.y + r * 1.3 + sin(t * 2.0) * 3.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx, by), Vector2(bx + 30, by + 6), Vector2(bx + 30, by + 38), Vector2(bx, by + 32)]), Color("e9dfc6"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx + 30, by + 6), Vector2(bx + 60, by), Vector2(bx + 60, by + 32), Vector2(bx + 30, by + 38)]), Color("f4ecd8"))
		for i in 4:
			ci.draw_line(Vector2(bx + 4, by + 9 + i * 5), Vector2(bx + 26, by + 13 + i * 5), Color(0, 0, 0, 0.25), 1.0)
			ci.draw_line(Vector2(bx + 34, by + 13 + i * 5), Vector2(bx + 56, by + 9 + i * 5), Color(0, 0, 0, 0.25), 1.0)
		glow(ci, Vector2(bx + 30, by + 18), 40, Color(1, 0.95, 0.7, 0.25))
	if props.get("mic", false):
		ci.draw_line(pos + Vector2(r * 1.2, r * 1.3), pos + Vector2(r * 0.55, r * 0.3), Color("333333"), 5.0, true)
		ci.draw_circle(pos + Vector2(r * 0.45, r * 0.12), r * 0.5, Color("8a9099"))
		ellipse_line(ci, pos + Vector2(r * 0.45, r * 0.12), r * 0.5, r * 0.5, Color("5c626b"), 1.5)
		for i in 3:
			var p := fmod(t * 0.8 + i / 3.0, 1.0)
			note(ci, pos + Vector2(r * 1.5 + sin((p + i) * 6.0) * 6.0, -r * 0.4 - p * r * 2.6), r * 0.5, Color(1, 0.91, 0.66, 1.0 - p), i % 2 == 1)
	if props.get("band", false):
		ci.draw_rect(Rect2(pos.x - r, pos.y - r * 0.55, r * 2, r * 0.32), Color("e8433a"))
		ci.draw_rect(Rect2(pos.x - r, pos.y - r * 0.47, r * 2, r * 0.08), Color.WHITE)
	if props.get("cowboy", false):
		ellipse(ci, pos + Vector2(0, -r * 0.6), r * 1.5, r * 0.28, Color("8a5a2b"))
		var crown := quad(pos + Vector2(-r * 0.7, -r * 0.6), pos + Vector2(-r * 0.75, -r * 1.6), pos + Vector2(0, -r * 1.3), 8)
		crown.append_array(quad(pos + Vector2(0, -r * 1.3), pos + Vector2(r * 0.75, -r * 1.6), pos + Vector2(r * 0.7, -r * 0.6), 8))
		ci.draw_colored_polygon(crown, Color("8a5a2b"))
		ci.draw_rect(Rect2(pos.x - r * 0.72, pos.y - r * 0.85, r * 1.44, r * 0.18), Color("5b3a1a"))
	if props.get("shades", false):
		for sx in [-1.0, 1.0]:
			ellipse(ci, pos + Vector2(sx * r * 0.36, -r * 0.08), r * 0.3, r * 0.2, Color("111111"))
		ci.draw_line(pos + Vector2(-r * 0.1, -r * 0.12), pos + Vector2(r * 0.1, -r * 0.12), Color("111111"), 3.0)
	if props.get("pilot", false):
		ci.draw_colored_polygon(ellipse_pts(pos + Vector2(0, -r * 0.2), r * 0.95, r * 0.95, 0, 16, PI * 1.05, PI * 1.95), Color("6b4a2e"))
		for sx in [-1.0, 1.0]:
			var g: Vector2 = pos + Vector2(sx * r * 0.42, -r * 0.45)
			ci.draw_circle(g, r * 0.3, Color(0.55, 0.86, 1, 0.7))
			ellipse_line(ci, g, r * 0.3, r * 0.3, Color("3b2e22"), 3.0)
		var scarf := quad(pos + Vector2(r * 0.6, r * 0.7), pos + Vector2(r * 1.8, r * 0.6 + sin(t * 8.0) * 6.0), pos + Vector2(r * 2.6, r * 0.9 + sin(t * 8.0 + 1.0) * 8.0))
		ci.draw_polyline(scarf, Color("e8e2d0"), 6.0, true)
	if props.get("popcorn", false):
		var bx := pos.x + r * 1.1
		var by := pos.y + r * 0.6
		for i in 6:
			ci.draw_circle(Vector2(bx - 8 + i * 3.5, by - 2 - (i % 2) * 3), 4.0, Color.WHITE)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 12, by), Vector2(bx + 12, by), Vector2(bx + 9, by + 20), Vector2(bx - 9, by + 20)]), Color("d64535"))
		ci.draw_rect(Rect2(bx - 3, by, 4, 20), Color.WHITE)
	if props.get("mailcap", false):
		ci.draw_rect(Rect2(pos.x - r, pos.y - r - 6, r * 2, 8), Color("2b4a8a"))
		ci.draw_colored_polygon(ellipse_pts(pos + Vector2(0, -r - 6), r * 0.9, 7, 0, 12, PI, TAU), Color("2b4a8a"))
		ci.draw_rect(Rect2(pos.x - r - 2, pos.y - r + 1, r + 8, 3), Color("1d3566"))
	if props.get("visor", false):
		ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(-r, -r + 2), pos + Vector2(r, -r + 2), pos + Vector2(r + 8, -r + 10), pos + Vector2(-r - 8, -r + 10)]), Color(0.16, 0.63, 0.31, 0.85))
	if props.get("headset", false):
		ci.draw_arc(pos, r + 3, PI * 1.1, PI * 1.9, 16, Color("333333"), 3.0, true)
		ci.draw_rect(Rect2(pos.x - r - 6, pos.y - 4, 6, 10), Color("333333"))
		ci.draw_rect(Rect2(pos.x + r, pos.y - 4, 6, 10), Color("333333"))
		ci.draw_polyline(quad(pos + Vector2(-r - 3, 6), pos + Vector2(-r, r), pos + Vector2(-4, r - 2)), Color("333333"), 2.0, true)
	if props.get("helmet", false):
		ci.draw_circle(pos, r * 1.35, Color(0.78, 0.9, 1, 0.12))
		ellipse_line(ci, pos, r * 1.35, r * 1.35, Color(0.78, 0.9, 1, 0.8), 2.0)
	ci.draw_set_transform_matrix(cam)


static func draw_recliner(ci: CanvasItem, pos: Vector2, k: float) -> void:
	if k <= 0.0:
		return
	var c := Color("6b4a8a")
	c.a = k * 0.9
	round_rect(ci, Rect2(pos + Vector2(-34, -10), Vector2(68, 26)), 8, c)
	round_rect(ci, Rect2(pos + Vector2(-34, -46), Vector2(20, 44)), 8, c)
	var c2 := Color("8a6ab0")
	c2.a = k * 0.9
	ci.draw_rect(Rect2(pos + Vector2(20, 6), Vector2(24, 8)), c2)
	var c3 := Color("3a2a4a")
	c3.a = k * 0.9
	ci.draw_rect(Rect2(pos + Vector2(-28, 16), Vector2(6, 10)), c3)
	ci.draw_rect(Rect2(pos + Vector2(22, 16), Vector2(6, 10)), c3)


# ---------------------------------------------------------------- Carl
static func edge_pt(a: float) -> Vector2:
	return Vector2(CARL_RX * cos(a), CARL_RY * sin(a))


static func normal_ang(a: float) -> float:
	return atan2(sin(a) / CARL_RY, cos(a) / CARL_RX)


static func is_face(type: String) -> bool:
	return type == "eye" or type == "mouth"


static func part_anchor(q: Dictionary) -> Vector2:
	if is_face(q.type):
		return Vector2(q.x, q.y)
	return edge_pt(q.a)


## How far below Carl's centre his feet reach, in body units (multiply by scale).
static func carl_feet(parts: Array = []) -> float:
	if parts.is_empty():
		parts = Game.carl.parts
	var best := CARL_RY
	for q in parts:
		if q.type == "leg":
			var n := normal_ang(q.a)
			var foot := edge_pt(q.a) + Vector2(cos(n), sin(n)) * 44.0 * 1.45 * float(q.get("size", 1.0))
			best = maxf(best, foot.y + 10.0)
	return best


## Draw Carl. pos = centre of his body, s = scale (1.0 is Make Carl size).
## opts: flip, walk (0..1 stride), walk_speed, air, glow (0..1), hat, look (Vector2 local dir),
##       talk, parts, color, sel (part id), pop (Dictionary id->age), tilt, alpha
static func draw_carl(ci: CanvasItem, pos: Vector2, s: float, t: float, opts := {}) -> void:
	var parts: Array = opts.get("parts", Game.carl.parts)
	var color: Color = opts.get("color", Game.carl.color)
	var flip := -1.0 if opts.get("flip", false) else 1.0
	var tilt: float = opts.get("tilt", 0.0)
	var gl: float = opts.get("glow", 0.0)
	var alpha: float = opts.get("alpha", 1.0)
	var body := cam * Transform2D(tilt, Vector2(s * flip, s), 0.0, pos)
	if gl > 0.0:
		ci.draw_set_transform_matrix(cam)
		glow(ci, pos, (150.0 + gl * 260.0) * s, Color(1, 0.94, 0.7, minf(0.85, 0.15 + gl * 0.7) * alpha))
	var dark := shade(color, 0.72)
	dark.a = alpha
	var sel = opts.get("sel", null)
	# limbs behind the body
	var walk: float = opts.get("walk", 0.0)
	var wspeed: float = opts.get("walk_speed", 9.0)
	var leg_i := 0
	for q in parts:
		if is_face(q.type):
			continue
		var w := sin(t * 5.0 + q.get("ph", 0.0))
		if q.type == "leg" and walk > 0.0:
			w = sin(t * wspeed + leg_i * PI) * walk * 4.0
			leg_i += 1
		if q.type == "leg" and opts.get("air", false):
			w = 1.2
		_draw_limb(ci, body, q, w, t, color, dark, alpha, sel != null and q.get("id", -2) == sel, opts.get("pop", {}).get(q.get("id", -1), 9.0))
	# tail
	var tw := sin(t * 3.0) * 0.2
	var tail := body * Transform2D(tw, Vector2(-CARL_RX + 6, 0))
	ci.draw_set_transform_matrix(tail)
	var tc := shade(color, 0.85)
	tc.a = alpha
	var tp := PackedVector2Array([Vector2(4, 0), Vector2(-60, -44)])
	tp.append_array(quad(Vector2(-60, -44), Vector2(-44, 0), Vector2(-60, 44), 8))
	ci.draw_colored_polygon(tp, tc)
	for i in 3:
		ci.draw_line(Vector2(-6, 0), Vector2(-50, -30 + i * 30), Color(0, 0, 0, 0.12 * alpha), 2.0)
	# body with a soft vertical gradient
	ci.draw_set_transform_matrix(body)
	var pts := ellipse_pts(Vector2.ZERO, CARL_RX, CARL_RY, 0, 44)
	var cols := PackedColorArray()
	for p in pts:
		var k := (p.y / CARL_RY + 1.0) * 0.5
		var c := shade(color, 0.9).lerp(shade(color, 1.22), k)
		c.a = alpha
		cols.append(c)
	ci.draw_polygon(pts, cols)
	# scales
	for x in range(-60, 40, 20):
		for y in range(-40, 41, 20):
			var cx := float(x) + (10.0 if int(y / 20) % 2 != 0 else 0.0)
			if Vector2(cx / CARL_RX, float(y) / CARL_RY).length() < 0.85:
				ci.draw_arc(Vector2(cx, y), 10, -1.2, 1.2, 8, Color(0, 0, 0, 0.1 * alpha), 2.0, true)
	ci.draw_polyline(quad(Vector2(45, -48), Vector2(30, 0), Vector2(45, 48)), Color(0, 0, 0, 0.15 * alpha), 3.0, true)
	ellipse(ci, Vector2(10, -34), 46, 12, Color(1, 1, 1, 0.16 * alpha), -0.12)
	ellipse_line(ci, Vector2.ZERO, CARL_RX, CARL_RY, Color(0, 0, 0, 0.25 * alpha), 2.0)
	# face
	for q in parts:
		if is_face(q.type):
			_draw_face(ci, body, q, t, gl, opts, sel != null and q.get("id", -2) == sel, alpha, opts.get("pop", {}).get(q.get("id", -1), 9.0))
	# hats copy the light's
	var hat: String = opts.get("hat", "")
	if hat != "":
		var top := Vector2(30, -CARL_RY + 4)
		ci.draw_set_transform_matrix(body)
		match hat:
			"hard":
				ci.draw_colored_polygon(ellipse_pts(top, 34, 30, 0, 16, PI, TAU), Color("f2c230"))
				ci.draw_rect(Rect2(top + Vector2(-42, -4), Vector2(84, 9)), Color("e0a800"))
			"shades":
				var e := Vector2(60, -20)
				for q in parts:
					if q.type == "eye":
						e = Vector2(q.x, q.y)
						break
				ci.draw_rect(Rect2(e + Vector2(-24, -10), Vector2(48, 18)), Color("111111"))
				ci.draw_line(e + Vector2(-24, -4), e + Vector2(-70, -8), Color("111111"), 4.0)
			"helmet":
				ellipse_line(ci, Vector2.ZERO, CARL_RX + 40, CARL_RY + 40, Color(0.78, 0.9, 1, 0.8), 5.0)
				ellipse(ci, Vector2.ZERO, CARL_RX + 40, CARL_RY + 40, Color(0.78, 0.9, 1, 0.1))
			"tie":
				ci.draw_colored_polygon(PackedVector2Array([Vector2(40, 30), Vector2(54, 30), Vector2(50, 58), Vector2(47, 64), Vector2(44, 58)]), Color("c0392b"))
	ci.draw_set_transform_matrix(cam)


static func _draw_limb(ci: CanvasItem, body: Transform2D, q: Dictionary, w: float, t: float, color: Color, dark: Color, alpha: float, selected: bool, age: float) -> void:
	var b := edge_pt(q.a)
	var n := normal_ang(q.a)
	var pop := minf(1.0, age * 5.0)
	var sc := 0.3 + 0.7 * (1.0 - pow(1.0 - pop, 3.0)) + sin(minf(1.0, age * 5.0) * PI) * 0.15
	var k: float = q.get("size", 1.0)
	var stretch: bool = q.type == "leg" or q.type == "arm"
	var u := sc * 1.45 * (1.0 if stretch else k)
	var xf := body * Transform2D(n, Vector2(u, u), 0.0, b)
	ci.draw_set_transform_matrix(xf)
	if selected:
		glow(ci, Vector2(LIMB.get(q.type, 30.0) * 0.6 * (k if stretch else 1.0), 0), 40, Color(1, 0.91, 0.66, 0.5))
	match q.type:
		"leg":
			ci.draw_set_transform_matrix(xf * Transform2D(w * 0.18, Vector2.ZERO))
			var foot := Vector2(42 * k, -2 + w * 3)
			ci.draw_polyline(PackedVector2Array([Vector2(-6, 0), Vector2(22 * k, 4), foot]), dark, 9.0, true)
			ci.draw_circle(Vector2(22 * k, 4), 4.5, dark)
			ellipse(ci, foot + Vector2(2, 0), 5, 9, dark)
		"arm":
			ci.draw_set_transform_matrix(xf * Transform2D(-0.4 + w * 0.25, Vector2.ZERO))
			var hand := Vector2(34 * k, -10)
			ci.draw_polyline(PackedVector2Array([Vector2(-6, 0), Vector2(20 * k, 0), hand]), dark, 7.0, true)
			for a in [-0.6, 0.0, 0.6]:
				ci.draw_line(hand, hand + Vector2(cos(a - 0.8), sin(a - 0.8)) * 9.0, dark, 3.5, true)
		"fin":
			ci.draw_set_transform_matrix(xf * Transform2D(w * 0.12, Vector2.ZERO))
			var fp := PackedVector2Array([Vector2(-8, -14)])
			fp.append_array(quad(Vector2(-8, -14), Vector2(14, -10), Vector2(28, 0), 6))
			fp.append_array(quad(Vector2(28, 0), Vector2(14, 10), Vector2(-8, 14), 6))
			var fc := shade(color, 0.85)
			fc.a = 0.9 * alpha
			ci.draw_colored_polygon(fp, fc)
			for i in range(-2, 3):
				ci.draw_line(Vector2(-4, i * 5), Vector2(22, i * 1.5), dark, 1.5)
		"horn":
			var hp := PackedVector2Array([Vector2(-6, -9)])
			hp.append_array(quad(Vector2(-6, -9), Vector2(18, -8), Vector2(30, -6), 6))
			hp.append_array(quad(Vector2(30, -6), Vector2(14, 4), Vector2(-6, 9), 6))
			ci.draw_colored_polygon(hp, Color(0.95, 0.92, 0.82, alpha))
			for i in 3:
				ci.draw_line(Vector2(4 + i * 7, -7 + i), Vector2(4 + i * 7, 6 - i * 1.8), Color(0.8, 0.75, 0.61, alpha), 1.5)
		"antenna":
			ci.draw_polyline(quad(Vector2(-4, 0), Vector2(20, w * 10), Vector2(38, w * 6)), Color(0.2, 0.2, 0.2, alpha), 2.5, true)
			ci.draw_circle(Vector2(40, w * 6), 5, Color(1, 0.36, 0.36, alpha))
			glow(ci, Vector2(40, w * 6), 12, Color(1, 0.4, 0.4, 0.4 * alpha))
		"wing":
			var f := 0.7 + 0.3 * sin(t * 9.0 + q.get("ph", 0.0))
			ci.draw_set_transform_matrix(xf * Transform2D(0, Vector2(1, f), 0, Vector2.ZERO))
			var wp := PackedVector2Array([Vector2(-6, -6)])
			wp.append_array(quad(Vector2(-6, -6), Vector2(30, -30), Vector2(60, -12), 6))
			wp.append_array(quad(Vector2(60, -12), Vector2(48, -2), Vector2(54, 6), 4))
			wp.append_array(quad(Vector2(54, 6), Vector2(36, 4), Vector2(40, 14), 4))
			wp.append_array(quad(Vector2(40, 14), Vector2(18, 10), Vector2(-6, 8), 4))
			ci.draw_colored_polygon(wp, Color(0.96, 0.95, 1, alpha))
			wp.append(wp[0])
			ci.draw_polyline(wp, Color(0.73, 0.7, 0.81, alpha), 1.5, true)
		"ear":
			ellipse(ci, Vector2(8, 0), 14, 10, dark)
			ellipse(ci, Vector2(9, 0), 8, 5, Color(1, 0.7, 0.76, alpha))


static func _draw_face(ci: CanvasItem, body: Transform2D, q: Dictionary, t: float, gl: float, opts: Dictionary, selected: bool, alpha: float, age: float) -> void:
	var b := Vector2(q.x, q.y)
	var pop := minf(1.0, age * 5.0)
	var sc := (0.5 + 0.7 * pop) * float(q.get("size", 1.0))
	var xf := body * Transform2D(0, Vector2(sc, sc), 0, b)
	ci.draw_set_transform_matrix(xf)
	if selected:
		glow(ci, Vector2.ZERO, 26, Color(1, 0.91, 0.66, 0.6))
	if q.type == "eye":
		var blink := fmod(t + q.get("ph", 0.0) * 2.0, 4.0) < 0.12
		var white := Color(1, 0.96, 0.78, alpha) if gl > 0.5 else Color(1, 1, 1, alpha)
		ellipse(ci, Vector2.ZERO, 11, 1.5 if blink else 11.0, white)
		ellipse_line(ci, Vector2.ZERO, 11, 1.5 if blink else 11.0, Color(0.13, 0.13, 0.13, alpha), 2.0)
		if not blink:
			var look: Vector2 = opts.get("look", Vector2.ZERO)
			var d := look.limit_length(1.0) * 4.0
			var pupil := Color(1, 0.81, 0.35, alpha) if gl > 0.5 else Color(0.07, 0.07, 0.07, alpha)
			ci.draw_circle(d, 5, pupil)
			ci.draw_circle(d + Vector2(-2, -2), 1.6, Color(1, 1, 1, alpha))
			if gl > 0.5:
				glow(ci, d, 14, Color(1, 0.9, 0.5, 0.6 * alpha))
	else:
		var open: float = 6.0 if opts.get("talk", false) else 0.0
		var mp := quad(Vector2(-11, -2), Vector2(0, 10 + open), Vector2(11, -2), 10)
		if open > 0.0:
			ci.draw_colored_polygon(mp, Color(0.48, 0.16, 0.2, alpha))
		ci.draw_polyline(mp, Color(0.23, 0.1, 0.1, alpha), 3.5, true)
