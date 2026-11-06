extends CanvasLayer
## Dialogue box (autoload "Dialog").
##   await Dialog.say(["line", "CARL:line", "!cue"], cue_callable)
## Blocking lines wait for a click, Space or Enter. Prefixes pick the speaker:
##   CARL:  Carl     LIB:  the librarian     NEW:  Carl, the Beginning
## A line starting with "!" is not shown; it calls cue_callable with the rest.
## quip() shows a short non-blocking line that times out by itself.

signal batch_done(id: int)
signal line_shown(text: String, speaker: String)

const BOX_H := 128.0
const STYLES := {
	"light": {"name": "The Light", "bg": Color(0.047, 0.04, 0.094, 0.96), "edge": Color(1, 0.91, 0.66, 0.55), "who": Color("ffe9a8"), "text": Color("f4efe2")},
	"carl": {"name": "Carl", "bg": Color(0.23, 0.10, 0.024, 0.97), "edge": Color("ff9f43"), "who": Color("ffb070"), "text": Color("fff1e2")},
	"lib": {"name": "Librarian (off screen)", "bg": Color(0.12, 0.13, 0.16, 0.97), "edge": Color("9aa4b2"), "who": Color("c9d1dc"), "text": Color("eef1f5")},
	"new": {"name": "Carl, the Beginning", "bg": Color(0.16, 0.11, 0.03, 0.97), "edge": Color("ffe9a8"), "who": Color("ffe9a8"), "text": Color("fff8e6")},
}

var blocking := false
var _queue: Array = []
var _batch := 0
var _seq := 0
var _text := ""
var _shown := 0.0
var _speaker := "light"
var _quip_t := 0.0
var _quips: Array = []
var _is_quip := false
var _t := 0.0

var _panel: Panel
var _style: StyleBoxFlat
var _who: Label
var _body: Label
var _hint: Label
var _display_font: SystemFont


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_display_font = SystemFont.new()
	_display_font.font_names = PackedStringArray(["Georgia", "Palatino Linotype", "Times New Roman", "serif"])

	_panel = Panel.new()
	_panel.position = Vector2(24, 720 - BOX_H - 14)
	_panel.size = Vector2(1232, BOX_H)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = StyleBoxFlat.new()
	_style.set_corner_radius_all(14)
	_style.border_width_top = 3
	_style.shadow_color = Color(0, 0, 0, 0.45)
	_style.shadow_size = 10
	_panel.add_theme_stylebox_override("panel", _style)
	add_child(_panel)

	_who = Label.new()
	_who.position = Vector2(22, 10)
	_who.add_theme_font_override("font", _display_font)
	_who.add_theme_font_size_override("font_size", 20)
	_panel.add_child(_who)

	_body = Label.new()
	_body.position = Vector2(22, 40)
	_body.size = Vector2(1150, 80)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 22)
	_panel.add_child(_body)

	_hint = Label.new()
	_hint.position = Vector2(1232 - 190, BOX_H - 30)
	_hint.size = Vector2(170, 24)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.text = "click to continue ▸"
	_hint.add_theme_font_size_override("font_size", 14)
	_panel.add_child(_hint)
	_panel.visible = false


func _speaker_of(raw: String) -> Array:
	if raw.begins_with("CARL:"):
		return ["carl", raw.substr(5)]
	if raw.begins_with("LIB:"):
		return ["lib", raw.substr(4)]
	if raw.begins_with("NEW:"):
		return ["new", raw.substr(4)]
	return ["light", raw]


func _apply_style(sp: String) -> void:
	var s: Dictionary = STYLES[sp]
	_style.bg_color = s.bg
	_style.border_color = s.edge
	_who.text = s.name
	_who.add_theme_color_override("font_color", s.who)
	_body.add_theme_color_override("font_color", s.text)
	_hint.add_theme_color_override("font_color", s.who * Color(1, 1, 1, 0.75))


# ---------------------------------------------------------------- blocking lines
func say(lines: Array, cue := Callable()) -> void:
	_batch += 1
	var id := _batch
	for l in lines:
		_queue.append({"text": str(l), "cue": cue})
	_queue.append({"end": id})
	_quips.clear()
	if not blocking:
		blocking = true
		_next()
	while true:
		var done: int = await batch_done
		if done == id:
			break


func _next() -> void:
	while _queue.size() > 0:
		var item: Dictionary = _queue.pop_front()
		if item.has("end"):
			if _queue.is_empty():
				blocking = false
				_hide()
			var before := _seq
			batch_done.emit(item.end)
			if _seq != before:
				return
			continue
		var raw: String = item.text
		if raw.begins_with("!"):
			var c: Callable = item.cue
			if c.is_valid():
				c.call(raw.substr(1))
			continue
		_show(raw, false)
		return
	blocking = false
	_hide()


func _show(raw: String, quip: bool) -> void:
	var r := _speaker_of(raw)
	_speaker = r[0]
	_text = r[1]
	_shown = 0.0
	_seq += 1
	_is_quip = quip
	_apply_style(_speaker)
	_body.text = _text
	_body.visible_characters = 0
	_hint.visible = not quip
	_panel.visible = true
	_panel.modulate.a = 1.0
	Sfx.blip(_speaker)
	line_shown.emit(_text, _speaker)


func _hide() -> void:
	_panel.visible = false
	_is_quip = false


func advance() -> void:
	if not _panel.visible:
		return
	if _shown < _text.length():
		_shown = _text.length()
		return
	if blocking and not _is_quip:
		_next()
	elif _is_quip:
		_quip_t = 0.0
		_hide()


## Drop everything (used when changing chapters). Anything still awaiting a
## dropped line belongs to the old chapter, which is about to be freed.
func clear() -> void:
	_queue.clear()
	_quips.clear()
	blocking = false
	_hide()


# ---------------------------------------------------------------- quips
## Non-blocking line. Shown when nothing else is talking.
func quip(raw: String, now := false) -> void:
	if blocking:
		return
	if now:
		_quips.push_front(raw)
		_quip_t = 0.0
		if _is_quip:
			_hide()
	elif not _quips.has(raw) and _quips.size() < 6:
		_quips.append(raw)


func busy() -> bool:
	return blocking or (_panel.visible and _is_quip)


var _auto := 0.0


func _process(dt: float) -> void:
	_t += dt
	if Game.autotest and _panel.visible:
		_auto += dt
		if _auto > 0.06:
			_auto = 0.0
			_shown = _text.length()
			advance()
	if _panel.visible and _shown < _text.length():
		_shown = minf(_text.length(), _shown + dt * 46.0)
		_body.visible_characters = int(_shown)
	elif _panel.visible:
		_body.visible_characters = -1
	if _panel.visible and not _is_quip:
		_hint.modulate.a = 0.55 + 0.45 * sin(_t * 4.0)
	if _is_quip and _panel.visible:
		_quip_t -= dt
		if _quip_t <= 0.0:
			_hide()
	if not blocking and not _panel.visible and _quips.size() > 0:
		var q: String = _quips.pop_front()
		_show(q, true)
		_quip_t = 2.8 + _text.length() / 22.0


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if Game.transitioning:
		if event is InputEventMouseButton or event is InputEventKey:
			get_viewport().set_input_as_handled()
		return
	if not _panel.visible:
		return
	var press := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if blocking and not _is_quip:
			press = true
		elif _is_quip and _panel.get_global_rect().has_point(event.position):
			press = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if blocking and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			press = true
	if press:
		advance()
		get_viewport().set_input_as_handled()
