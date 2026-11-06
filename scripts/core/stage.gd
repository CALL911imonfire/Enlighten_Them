class_name Stage
extends Node2D
## Base class for every chapter. A chapter draws in its own virtual space
## (VW x VH), which is scaled to fit the area above the dialogue box.
## Override setup(), begin(), tick(dt) and paint(). Input arrives in click(p),
## release(p), drag(p) and key(code), all in virtual coordinates.

var VW := 600.0
var VH := 600.0
var t := 0.0
var cam := Transform2D()      # extra camera transform for zooms inside a chapter
var shake := 0.0
var fit_area := Rect2(0, 0, 1280, 586)
var pressed := false


func _ready() -> void:
	setup()
	_fit()


func _fit() -> void:
	var s := minf(fit_area.size.x / VW, fit_area.size.y / VH)
	scale = Vector2(s, s)
	position = fit_area.position + (fit_area.size - Vector2(VW, VH) * s) / 2.0


func setup() -> void:
	pass


func begin() -> void:
	pass


func tick(_dt: float) -> void:
	pass


func paint() -> void:
	pass


func click(_p: Vector2) -> void:
	pass


func release(_p: Vector2) -> void:
	pass


func drag(_p: Vector2) -> void:
	pass


func key(_code: int) -> void:
	pass


func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	t += dt
	shake = maxf(0.0, shake - dt)
	tick(dt)
	queue_redraw()


func _draw() -> void:
	var c := cam
	if shake > 0.0:
		c = Transform2D(0, Vector2((randf() - 0.5) * 16.0 * shake, (randf() - 0.5) * 16.0 * shake)) * c
	Art.cam = c
	draw_set_transform_matrix(c)
	paint()
	Art.cam = Transform2D()
	draw_set_transform_matrix(Transform2D())


## Mouse position in this chapter's virtual space (camera removed).
func mouse() -> Vector2:
	return cam.affine_inverse() * get_local_mouse_position()


func busy() -> bool:
	return Dialog.blocking or Game.transitioning


func _unhandled_input(event: InputEvent) -> void:
	if Game.transitioning:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pressed = true
			click(mouse())
		else:
			pressed = false
			release(mouse())
	elif event is InputEventMouseMotion:
		drag(mouse())
	elif event is InputEventKey and event.pressed and not event.echo:
		key(event.keycode)


## Leave this chapter, zooming into p (virtual coordinates).
func finish(p: Vector2) -> void:
	Game.next_chapter(get_global_transform_with_canvas() * (cam * p))


# ---------------------------------------------------------------- small helpers
func light(p: Vector2, r: float, props := {}) -> void:
	Art.draw_light(self, p, r, t, props)


func carl(p: Vector2, s: float, opts := {}) -> void:
	Art.draw_carl(self, p, s, t, opts)


func txt(p: Vector2, s: String, size := 16, col := Color.WHITE, align := 0, outline := 0) -> void:
	Art.text(self, p, s, size, col, align, null, outline, Color(0, 0, 0, 0.8))


func big_rect() -> Rect2:
	return Rect2(-VW, -VH, VW * 3.0, VH * 3.0)


## Wait in a coroutine without blocking the game.
func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


## A small UI button that lives inside the chapter (it zooms with it).
func button(label: String, pos: Vector2, size: Vector2, cb: Callable, font_size := 18) -> Button:
	var b := Button.new()
	b.text = label
	b.position = pos
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.14, 0.92)
	sb.border_color = Color(1, 0.91, 0.66, 0.5)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	var hv := sb.duplicate()
	hv.bg_color = Color(0.16, 0.14, 0.26, 0.95)
	hv.border_color = Color(1, 0.81, 0.35, 0.9)
	var dis := sb.duplicate()
	dis.bg_color = Color(0.08, 0.07, 0.14, 0.5)
	dis.border_color = Color(1, 1, 1, 0.15)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", hv)
	b.add_theme_stylebox_override("disabled", dis)
	b.add_theme_color_override("font_color", Color("f4efe2"))
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	b.pressed.connect(func():
		if not busy():
			Sfx.click()
			cb.call())
	add_child(b)
	return b
