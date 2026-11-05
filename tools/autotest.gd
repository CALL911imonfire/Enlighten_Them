extends Node
## Developer self-test: plays the whole game by poking each chapter's own
## functions, so runtime errors show up without clicking through by hand.
##   godot --fixed-fps 60 -- --autotest --chapter=1

var t := 0.0
var log_t := 0.0
var last_chapter := -1
var since := 0.0
var step := 0


var shot_dir := ""
var shot_t := 0.0
var shot_n := 0
var shot_every := 2.5


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			shot_dir = a.substr(8)
		if a.begins_with("--shotevery="):
			shot_every = float(a.substr(12))


func _shot() -> void:
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png("%s/shot_%03d_c%d.png" % [shot_dir, shot_n, Game.current])
		shot_n += 1


func _process(dt: float) -> void:
	t += dt
	since += dt
	if shot_dir != "":
		shot_t += dt
		if shot_t > shot_every:
			shot_t = 0.0
			_shot()
	if Game.current != last_chapter:
		last_chapter = Game.current
		since = 0.0
		step = 0
		print("[autotest] chapter ", Game.current, " ", Game.CHAPTERS[Game.current].name, " at t=", snappedf(t, 0.1))
	if Game.transitioning or Dialog.blocking:
		return
	var s = Game.scene
	if s == null:
		return
	if since > 240.0:
		print("[autotest] STUCK in chapter ", Game.current, " phase=", s.get("phase"))
		get_tree().quit(1)
		return
	call("_c%d" % Game.current, s)


func _c0(s) -> void:
	if since > 1.0 and step == 0:
		step = 1
		s._play()


func _c1(s) -> void:
	match s.phase:
		"intro":
			if s.can_orb:
				s.click(s.C)
		"sun":
			s._drop(s.sun, s.C + Vector2(100, 0))
			s._drop(s.sun, s.C)
		"order":
			if step == 0:
				step = 1
				s._drop(s.pluto, s.C + Vector2(50, 0))
				s._drop(s.bodies[3], s.C + Vector2(50, 0))
			for i in s.PL.size():
				var b: Dictionary = s.bodies[i]
				if b.mode == "tray":
					s._drop(b, s.C + Vector2(s.RINGS[i], 0))
					return


func _c2(s) -> void:
	match s.phase:
		"hose":
			s._try_connect(Vector2.ZERO)
			s._try_connect(s._valve())
		"pump":
			if step == 0:
				step = 1
				s._pump_puff()
				s._pump_puff()
				s._pump_puff()
				s._pump_puff()
				s._pump_puff()
				return
			s.pressure = 0.0
			s._pump_puff()


func _c3(s) -> void:
	if s.phase != "play":
		return
	if step == 0:
		step = 1
		s._chip(s.tiles[0], Vector2(100, 100))
		return
	if s.sw == "off" and step == 1:
		step = 2
		s._player_toggle()
		return
	if s.sw == "off" and step == 2:
		step = 3
		s._player_toggle()
		return
	for P in s.paths:
		if not P.done:
			for q in P.pts:
				q.cut = true
			s._complete_path(P)
			return


func _c4(s) -> void:
	if s.phase != "build":
		return
	match step:
		0:
			for k in ["eye", "eye", "eye", "eye", "mouth", "mouth", "ear", "leg", "leg", "arm", "fin", "fin", "fin", "horn", "antenna", "wing"]:
				s._add_part(k)
			step = 1
		1:
			s._set_color(Color("4fb3d9"))
			s.sel = s.parts[-1].id
			s._remove_selected()
			for p in s.parts:
				if p.type == "arm":
					s._remove_part(p)
					break
			for p in s.parts:
				if p.type == "ear":
					s._remove_part(p)
					break
			step = 2
		2:
			if s.pun_sw == "on":
				s._pun_switch()
			s._next_idle()
			step = 3
		3:
			if since > 30:
				s._add_part("ear")
				s._try_done()
				step = 4


func _c5(s) -> void:
	if s.phase == "ready":
		s._press()
	if s.phase != "play":
		return
	if step == 0:
		step = 1
		s._crash("obstacle")
		return
	s.obs.clear()
	if s.S.mode == "flap":
		s.cy = 200.0
		s.vy = 0.0
		s.gates_passed = s.S.gates
		s.gates_spawned = s.S.gates
		if s.lib_x < 0:
			s.lib_x = s.dist + 400
		s.dist = s.lib_x - 300
	else:
		s.dist = s.S.len


var plan: Array = []


func _c6(s) -> void:
	if s.phase != "play" or not s.anim.is_empty():
		return
	if step == 0:
		step = 1
		s.click(s.cub[0].get_center())
		s.click(s.cub[0].get_center())
		s._undo()
		s._hint()
		plan = []
		return
	if plan.is_empty():
		plan = s._solve(s.stacks, 400000)
		if plan.is_empty():
			print("[autotest] library: no solution found from ", s.stacks)
			s._redo()
			return
	var mv: Array = plan.pop_front()
	s._do_move(mv[0], mv[1])


func _c7(s) -> void:
	match s.phase:
		"wire":
			for i in s.plugs.size():
				if not s.plugs[i].done:
					if step == 0:
						step = 1
						s.sel_plug = i
						s.click(s.JACKS[(s.plugs[i].j + 1) % 3].p)
						return
					s.sel_plug = i
					s.click(s.JACKS[s.plugs[i].j].p)
					return
		"tape":
			s.click(Vector2(450, 462))
		"play":
			s.click(Vector2(260, 345))
		"track":
			s.track = s.target
		"login":
			if s.login.typing.is_empty():
				if s.login.acct == "":
					s.click(Vector2(300, 150))
				elif s.login.pass == "":
					s.click(Vector2(300, 190))
				else:
					s.click(Vector2(300, 235))
		"profiles":
			s._pick_profile(2)
		"boss":
			if s.wheels.size() > 0:
				s._hit_wheel(s.wheels[0])
		"stillq":
			s._still_yes()


func _c8(s) -> void:
	if s.phase != "play":
		return
	if s.era_i == 2 and step == 0:
		step = 1
		s._hint()
		s._phone_pickup()
		s._failed()
		return
	if s.era_i == 1 and step == 0:
		s._hint()
	for y in s.n:
		for x in s.n:
			if s.sol[y][x] != 0:
				s.grid[y][x].m = s.sol[y][x]
	s._compute()
	if s.won:
		s._solved()
	else:
		print("[autotest] dialup: solution did not connect")


func _c9(s) -> void:
	if s.phase != "play":
		return
	match s.st:
		0:
			for k in 6:
				if not s.coal[k]:
					s._build_coal(k)
					return
		1:
			if step == 0:
				step = 1
				s._run_day()
				return
			s.build = ["wind", "wind", "wind", "solar", "solar", "battery", "battery", "battery"]
			s._run_day()
		2:
			if s.fly.is_empty():
				for k in 12:
					if s.ring[k] == 0:
						s.panel_a = k * PI / 6 + s.ring_rot
						s._lock_panel()
						return


func _c10(s) -> void:
	match s.phase:
		"play":
			for st in s.stars:
				if st.state == "dying":
					s._catch(st)
		"click":
			s.click(Vector2(300, 300))
		"loop":
			if s.end_t > 3:
				s.click(Vector2(300, 300))
				print("[autotest] reached the end and looped back to the title. PASS")
				await get_tree().create_timer(3.0).timeout
				get_tree().quit(0)
