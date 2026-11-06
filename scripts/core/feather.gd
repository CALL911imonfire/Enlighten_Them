extends Node2D
## Soft edge for the zoom transition. While the next chapter grows out of the
## focus point, this paints a round, blurred iris around it so its rectangle
## edges never show as a hard line.

const BG := Color(0.027, 0.024, 0.051)
const SPREAD := 1.04  # iris size relative to the growing chapter

var rect := Rect2()
var strength := 0.0
var _tex: GradientTexture2D


func _ready() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 0.8, 0.98])
	g.colors = PackedColorArray([Color(BG, 0.0), Color(BG, 0.0), Color(BG, 0.55), Color(BG, 1.0)])
	_tex = GradientTexture2D.new()
	_tex.gradient = g
	_tex.fill = GradientTexture2D.FILL_RADIAL
	_tex.fill_from = Vector2(0.5, 0.5)
	_tex.fill_to = Vector2(1.0, 0.5)
	_tex.width = 256
	_tex.height = 256


func show_rect(r: Rect2, k: float) -> void:
	rect = r
	strength = k
	visible = k > 0.001
	queue_redraw()


func _draw() -> void:
	if strength <= 0.001:
		return
	var c := Color(BG, strength)
	var iris := Rect2(rect.get_center() - rect.size * SPREAD / 2.0, rect.size * SPREAD)
	var full := Rect2(-20, -20, 1320, 760)
	# solid outside the iris
	draw_rect(Rect2(full.position.x, full.position.y, full.size.x, iris.position.y - full.position.y), c)
	draw_rect(Rect2(full.position.x, iris.end.y, full.size.x, full.end.y - iris.end.y), c)
	draw_rect(Rect2(full.position.x, iris.position.y, iris.position.x - full.position.x, iris.size.y), c)
	draw_rect(Rect2(iris.end.x, iris.position.y, full.end.x - iris.end.x, iris.size.y), c)
	draw_texture_rect(_tex, iris, false, Color(1, 1, 1, strength))
