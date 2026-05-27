extends Node2D
## Level 3 Idea — Final Stage
## Puzzle platformer menggunakan SEMUA mekanik Castor & Pollux.
## 8 section dengan difficulty scaling, target ~5-7 menit gameplay.
##
## Platform sekarang pakai TileMapLayer (bukan StaticBody2D).
## Non-tile elements (spike, terminal, bridge, hazard, finish) tetap dari script.

# ── Preloads ─────────────────────────────────────────────────────────────────
const SpikeScene = preload("res://hazards/spike_hazard/SpikeHazard.tscn")
const TerminalScene = preload("res://interactables/terminal/terminal.tscn")
const BridgeScene = preload("res://interactables/bridge/bridge.tscn")
const EnvHazardScript = preload("res://hazards/environmental_hazard/environmental_hazard.gd")

# ── Tile Constants ───────────────────────────────────────────────────────────
# Atlas source ID = 0 (satu-satunya source di tileset)
const SRC := 0
# Beberapa atlas coords untuk variasi visual
const T_SOLID     := Vector2i(0, 0)   # tile solid utama
const T_SOLID2    := Vector2i(1, 0)
const T_SOLID3    := Vector2i(2, 0)
const T_TOP       := Vector2i(0, 1)   # tile permukaan atas
const T_TOP2      := Vector2i(1, 1)
const T_TOP3      := Vector2i(2, 1)
const T_FILL      := Vector2i(3, 3)   # tile filler/interior
const T_FILL2     := Vector2i(4, 3)
const T_WALL      := Vector2i(0, 2)   # tile dinding vertikal
const T_WALL2     := Vector2i(1, 2)
const T_ACCENT    := Vector2i(5, 0)   # tile aksen (terminal platforms dll)
const T_ACCENT2   := Vector2i(6, 0)
const T_FINISH    := Vector2i(3, 1)   # tile finish area

# ── Color Palette (untuk non-tile elements) ──────────────────────────────────
const CLR_HAZARD   = Color(0.87, 0.20, 0.27)
const CLR_GLOW     = Color(1.00, 0.87, 0.38, 0.45)
const CLR_LABEL    = Color(0.55, 0.65, 0.80, 0.60)

# ── Finish State ─────────────────────────────────────────────────────────────
var _castor_finished := false
var _pollux_finished := false
var _level_complete  := false

# ── References ───────────────────────────────────────────────────────────────
@onready var tilemap: TileMapLayer = $TileMapLayer

# ══════════════════════════════════════════════════════════════════════════════
#  LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_section_1()
	_build_section_2()
	_build_section_3()
	_build_section_4()
	_build_section_5()
	_build_section_6()
	_build_section_7()
	_build_section_8()
	_build_kill_zone()

# ══════════════════════════════════════════════════════════════════════════════
#  TILE HELPERS
# ══════════════════════════════════════════════════════════════════════════════

## Gambar garis horizontal tiles dari grid (gx, gy) sepanjang w tiles.
## top_tile = tile untuk baris pertama (permukaan), fill_tile = tile di bawahnya.
## depth = berapa baris ke bawah (termasuk permukaan).
func _tile_platform(gx: int, gy: int, w: int, depth: int = 2,
		top_tile := T_TOP, fill_tile := T_FILL) -> void:
	for x in range(gx, gx + w):
		tilemap.set_cell(Vector2i(x, gy), SRC, top_tile)
		for d in range(1, depth):
			tilemap.set_cell(Vector2i(x, gy + d), SRC, fill_tile)

## Gambar kolom vertikal tiles (wall) dari grid (gx, gy) ke bawah sepanjang h tiles.
func _tile_wall(gx: int, gy: int, h: int, tile := T_WALL) -> void:
	for y in range(gy, gy + h):
		tilemap.set_cell(Vector2i(gx, y), SRC, tile)

## Gambar rectangle tiles solid
func _tile_rect(gx: int, gy: int, w: int, h: int, tile := T_SOLID) -> void:
	for x in range(gx, gx + w):
		for y in range(gy, gy + h):
			tilemap.set_cell(Vector2i(x, y), SRC, tile)

# ══════════════════════════════════════════════════════════════════════════════
#  NON-TILE HELPERS (spike, hazard, terminal, bridge, label, finish)
# ══════════════════════════════════════════════════════════════════════════════

func _spikes(x0: float, x1: float, y: float, gap := 32.0) -> void:
	var x := x0
	while x <= x1:
		var s = SpikeScene.instantiate()
		s.position = Vector2(x, y)
		add_child(s)
		x += gap

func _env_hazard(pos: Vector2, size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.position = pos
	area.collision_mask = 7
	area.set_script(EnvHazardScript)
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	var vis := ColorRect.new()
	vis.color = CLR_HAZARD
	vis.position = Vector2(-size.x * 0.5, -size.y * 0.5)
	vis.size = size
	area.add_child(vis)
	var glow := ColorRect.new()
	glow.color = CLR_GLOW
	glow.position = Vector2(-size.x * 0.5, -size.y * 0.25)
	glow.size = Vector2(size.x, size.y * 0.5)
	area.add_child(glow)
	add_child(area)
	return area

func _terminal(pos: Vector2) -> Node:
	var t = TerminalScene.instantiate()
	t.position = pos
	add_child(t)
	return t

func _bridge(pos: Vector2, sx: float) -> Node:
	var b = BridgeScene.instantiate()
	b.position = pos
	b.scale = Vector2(sx, 1.0)
	add_child(b)
	return b

func _label(pos: Vector2, text: String) -> void:
	var lbl := Label.new()
	lbl.position = pos
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", CLR_LABEL)
	add_child(lbl)

func _finish_zone(pos: Vector2, size: Vector2) -> void:
	var area := Area2D.new()
	area.name = "FinishZone"
	area.position = pos
	area.collision_mask = 7
	area.monitoring = true
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	var vis := ColorRect.new()
	vis.color = Color(0.2, 1.0, 0.5, 0.12)
	vis.position = Vector2(-size.x * 0.5, -size.y * 0.5)
	vis.size = size
	area.add_child(vis)
	area.body_entered.connect(_on_finish_entered)
	add_child(area)

func _on_finish_entered(body: Node2D) -> void:
	if _level_complete:
		return
	if body.name == "Castor":
		_castor_finished = true
	elif body.name == "Pollux":
		_pollux_finished = true
	if _castor_finished and _pollux_finished:
		_level_complete = true
		_show_victory()

func _show_victory() -> void:
	get_tree().paused = true
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "  LEVEL COMPLETE!  "
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var sub := Label.new()
	sub.text = "  Castor & Pollux berhasil!  "
	sub.add_theme_font_size_override("font_size", 8)
	sub.add_theme_color_override("font_color", Color(0.6, 0.8, 0.7))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 1 — "The Descent"
#  Mekanik: Movement (A/D), Jump (Space)
#  Platform menurun bertahap ke kanan.
#
#  Grid coords (tile 32px):
#    Spawn platform:  gx=0,  gy=0,  w=11, depth=3
#    Step 1:          gx=13, gy=2,  w=5
#    Step 2:          gx=18, gy=4,  w=4    (sempit)
#    Step 3:          gx=23, gy=6,  w=5
#    Landing:         gx=28, gy=8,  w=5
# ══════════════════════════════════════════════════════════════════════════════

func _build_section_1() -> void:
	# Spawn — lebar, aman
	_tile_platform(0, 0, 11, 3)
	# Step 1
	_tile_platform(13, 2, 5, 2)
	# Step 2 — sempit
	_tile_platform(18, 4, 4, 2, T_TOP2, T_FILL2)
	# Step 3
	_tile_platform(23, 6, 5, 2)
	# Landing → connects to S2
	_tile_platform(28, 8, 5, 2)

	# Death pit di bawah gap-gap (pixel coords)
	_env_hazard(Vector2(560, 420), Vector2(700, 80))
	_spikes(380, 900, 380, 40)

	_label(Vector2(40, -48), "- Final Chapter -")

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 2 — "Rope Crossing"
#  Mekanik: Jump + Reel In/Out (Q/E)
#  Gap lebar memerlukan rope management — reel out dulu sebelum lompat.
#
#  Grid:
#    Continues from S1 landing (gx=28, gy=8)
#    Rest 1:   gx=37, gy=8, w=2   (tiny! ~128px gap)
#    Rest 2:   gx=43, gy=8, w=2   (tiny! ~128px gap)
#    Landing:  gx=49, gy=8, w=4
# ══════════════════════════════════════════════════════════════════════════════

func _build_section_2() -> void:
	# Rest platforms — sangat kecil, butuh presisi
	_tile_platform(37, 8, 2, 2, T_ACCENT, T_FILL)
	_tile_platform(43, 8, 2, 2, T_ACCENT, T_FILL)
	# Landing
	_tile_platform(49, 8, 4, 2)

	# Death pit
	_env_hazard(Vector2(1280, 420), Vector2(700, 80))
	_spikes(1040, 1600, 380, 40)

	_label(Vector2(960, 210), "Reel Out (E) sebelum lompat!")

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 3 — "Vertical Ascent"
#  Mekanik: Super-jump/Lift (berdiri di atas Pollux + E), Ledge Pull (Q)
#  Menara zigzag naik ke atas.
#
#  Grid:
#    Base:    gx=54, gy=8,  w=4
#    Step 1:  gx=57, gy=4,  w=4   (offset kanan, 4 tiles up)
#    Wall 1:  gx=56, gy=5,  h=3   (antara base dan step1)
#    Step 2:  gx=54, gy=0,  w=4   (offset kiri, 4 tiles up)
#    Wall 2:  gx=58, gy=1,  h=3
#    Top:     gx=57, gy=-4, w=5   (lebih lebar)
#    Wall 3:  gx=56, gy=-3, h=3
# ══════════════════════════════════════════════════════════════════════════════

func _build_section_3() -> void:
	# Base
	_tile_platform(54, 8, 4, 2)
	# Step 1 — naik 4 tiles, offset kanan
	_tile_platform(57, 4, 4, 2)
	_tile_wall(56, 5, 3)       # Wall untuk ledge pull
	# Step 2 — naik 4 tiles, offset kiri
	_tile_platform(54, 0, 4, 2)
	_tile_wall(58, 1, 3, T_WALL2)
	# Top — lebih lebar untuk safety
	_tile_platform(57, -4, 5, 2)
	_tile_wall(56, -3, 3)

	_label(Vector2(1700, 210), "Berdiri di Pollux + E")
	_label(Vector2(1700, 222), "Q dekat dinding = tarik Pollux")

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 4 — "Terminal Maze"
#  Mekanik: Throw Pollux (R), Terminal (F), Bridge
#  Lempar Pollux ke platform tinggi → aktifkan terminal → buka bridge.
#
#  Grid:
#    Entry:        gx=62, gy=-4, w=5
#    TermPlat 1:   gx=66, gy=-8, w=4   (throw target)
#    Post-bridge:  gx=71, gy=-4, w=4
#    TermPlat 2:   gx=75, gy=-8, w=4
#    Exit:         gx=79, gy=-2, w=4
# ══════════════════════════════════════════════════════════════════════════════

func _build_section_4() -> void:
	# Entry
	_tile_platform(62, -4, 5, 2)
	# Terminal platform 1 (throw target — aksen)
	_tile_platform(66, -8, 4, 2, T_ACCENT, T_ACCENT2)
	var term1 = _terminal(Vector2(66 * 32 + 64, -8 * 32 - 24))
	# Bridge 1
	var bridge1 = _bridge(Vector2(66 * 32, -4 * 32 + 16), 5.0)
	term1.terminal_activated.connect(bridge1.set_bridge_status)
	# Post bridge 1
	_tile_platform(71, -4, 4, 2)

	# Spikes di bawah gap
	_spikes(64 * 32, 70 * 32, -4 * 32 + 26, 40)

	# Terminal platform 2
	_tile_platform(75, -8, 4, 2, T_ACCENT, T_ACCENT2)
	var term2 = _terminal(Vector2(75 * 32 + 64, -8 * 32 - 24))
	# Bridge 2 (exit sedikit lebih tinggi)
	var bridge2 = _bridge(Vector2(75 * 32, -2 * 32 + 16), 5.0)
	term2.terminal_activated.connect(bridge2.set_bridge_status)
	# Exit
	_tile_platform(79, -2, 4, 2)

	_spikes(74 * 32, 78 * 32, -4 * 32 + 26, 40)
	_label(Vector2(62 * 32, -4 * 32 - 40), "R = lempar Pollux | F = terminal")

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 5 — "The Gauntlet"
#  Mekanik: Presisi platforming + Rope Power Limit
#  Platform kecil zigzag dengan spike atas & bawah.
#
#  Grid:
#    Entry:  gx=84, gy=-2, w=4
#    Plat1:  gx=90, gy=-2, w=2
#    Plat2:  gx=95, gy=-1, w=2  (lower)
#    Plat3:  gx=100,gy=-2, w=2
#    Plat4:  gx=105,gy=-1, w=2  (lower)
#    Exit:   gx=110,gy=-2, w=4
# ══════════════════════════════════════════════════════════════════════════════

func _build_section_5() -> void:
	# Entry
	_tile_platform(84, -2, 4, 2)
	# Zigzag kecil
	_tile_platform(90, -2, 2, 1, T_TOP2)
	_tile_platform(95, -1, 2, 1, T_TOP3)    # Lebih rendah
	_tile_platform(100, -2, 2, 1, T_TOP2)
	_tile_platform(105, -1, 2, 1, T_TOP3)   # Lebih rendah
	# Exit
	_tile_platform(110, -2, 4, 2)

	# Spike pit bawah
	_env_hazard(Vector2(97 * 32, 3 * 32), Vector2(800, 80))
	_spikes(87 * 32, 112 * 32, 1 * 32, 40)
	# Ceiling hazard atas
	_env_hazard(Vector2(97 * 32, -5 * 32), Vector2(600, 24))

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 6 — "Split Path"
#  Mekanik: Throw + Terminal + Ledge Pull
#  Dua jalur: Pollux dilempar ke atas → terminal, Castor jalan bawah.
#
#  Grid:
#    Entry:     gx=115, gy=-2, w=4
#    Lower:     gx=121, gy=-2, w=6
#    Upper:     gx=121, gy=-7, w=6   (throw target)
#    Wall:      gx=120, gy=-6, h=4
#    Exit:      gx=130, gy=-2, w=4
# ══════════════════════════════════════════════════════════════════════════════

func _build_section_6() -> void:
	# Entry
	_tile_platform(115, -2, 4, 2)
	# Lower path (Castor)
	_tile_platform(121, -2, 6, 2)
	# Upper path (Pollux throw target — aksen)
	_tile_platform(121, -7, 6, 2, T_ACCENT, T_ACCENT2)
	# Wall pemisah + ledge pull surface
	_tile_wall(120, -6, 4)
	# Terminal di upper
	var term3 = _terminal(Vector2(121 * 32 + 96, -7 * 32 - 24))
	# Bridge di lower
	var bridge3 = _bridge(Vector2(128 * 32, -2 * 32 + 16), 5.0)
	term3.terminal_activated.connect(bridge3.set_bridge_status)
	# Exit
	_tile_platform(130, -2, 4, 2)

	# Pit bawah
	_env_hazard(Vector2(124 * 32, 2 * 32), Vector2(500, 80))
	_spikes(118 * 32, 132 * 32, 0 * 32, 40)

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 7 — "Pendulum Gauntlet"
#  Mekanik: Jump + Rope + Air movement
#  Gap lebar berturut-turut di atas spike pit.
#
#  Grid:
#    Entry:   gx=135, gy=0,  w=3
#    Anchor:  gx=140, gy=-7, w=14  (high, lebar — throw target)
#    Rest 1:  gx=143, gy=0,  w=2
#    Rest 2:  gx=150, gy=0,  w=2
#    Landing: gx=157, gy=0,  w=4
# ══════════════════════════════════════════════════════════════════════════════

func _build_section_7() -> void:
	# Entry
	_tile_platform(135, 0, 3, 2)
	# High anchor (throw Pollux untuk swing)
	_tile_platform(140, -7, 14, 2, T_ACCENT, T_ACCENT2)
	# Rest 1 — kecil
	_tile_platform(143, 0, 2, 1, T_TOP2)
	# Rest 2 — kecil
	_tile_platform(150, 0, 2, 1, T_TOP2)
	# Landing
	_tile_platform(157, 0, 4, 2)

	# Spike pit
	_env_hazard(Vector2(148 * 32, 4 * 32), Vector2(800, 80))
	_spikes(137 * 32, 159 * 32, 3 * 32, 40)

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 8 — "Final Ascent"
#  Mekanik: SEMUA
#  Menara terakhir + terminal di puncak + bridge ke finish.
#
#  Grid:
#    Base:      gx=162, gy=0,  w=4
#    Step 1:    gx=165, gy=-4, w=4
#    Wall 1:    gx=164, gy=-3, h=3
#    Step 2:    gx=162, gy=-8, w=4
#    Wall 2:    gx=166, gy=-7, h=3
#    TermPlat:  gx=165, gy=-12, w=5  (throw target)
#    Wall 3:    gx=164, gy=-11, h=3
#    Finish:    gx=174, gy=-8, w=10  (lebar, aman)
# ══════════════════════════════════════════════════════════════════════════════

func _build_section_8() -> void:
	# Base
	_tile_platform(162, 0, 4, 2)
	# Step 1 — naik 4 tiles
	_tile_platform(165, -4, 4, 2)
	_tile_wall(164, -3, 3)
	# Step 2 — naik 4 tiles lagi
	_tile_platform(162, -8, 4, 2)
	_tile_wall(166, -7, 3)

	# Terminal platform (throw target di puncak)
	_tile_platform(165, -12, 5, 2, T_ACCENT, T_ACCENT2)
	_tile_wall(164, -11, 3)
	var term4 = _terminal(Vector2(165 * 32 + 80, -12 * 32 - 24))

	# Final bridge ke finish
	var bridge4 = _bridge(Vector2(171 * 32, -8 * 32 + 16), 8.0)
	term4.terminal_activated.connect(bridge4.set_bridge_status)

	# ★ FINISH PLATFORM ★
	_tile_platform(174, -8, 10, 3, T_FINISH, T_FILL)
	_finish_zone(Vector2(174 * 32 + 160, -8 * 32 - 48), Vector2(320, 128))

	# Danger bawah tower
	_env_hazard(Vector2(164 * 32, 4 * 32), Vector2(400, 80))
	_spikes(161 * 32, 170 * 32, 3 * 32, 40)

	_label(Vector2(176 * 32, -8 * 32 - 32), "★ FINISH ★")

# ══════════════════════════════════════════════════════════════════════════════
#  KILL ZONE — Death zone di dasar seluruh level
# ══════════════════════════════════════════════════════════════════════════════

func _build_kill_zone() -> void:
	_env_hazard(Vector2(2700, 600), Vector2(8000, 200))
