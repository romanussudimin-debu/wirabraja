extends Control
## Menu utama (v2.0): kelir wayang dengan kayon, judul, tombol Mulai / Pengaturan /
## Kontrol / Keluar, rekor terbaik, dan identitas pembuat.

const SCENE_NARASI := "res://scenes/ui/narasi_pembuka.tscn"

## Dipancarkan saat tombol Mulai ditekan (dipakai uji otomatis).
signal mulai_ditekan
## False dipakai uji otomatis agar tidak berpindah scene.
@export var pindah_otomatis: bool = true

var _panel_menu: Control
var _pengaturan: PanelPengaturan
var _panel_kontrol: PanelContainer
var _kayon: Kayon


func _ready() -> void:
	theme = TemaJawa.ambil()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	AudioManager.putar_musik("narasi")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var latar := ColorRect.new()
	latar.color = Color(0.07, 0.045, 0.03)
	latar.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(latar)

	# Kelir di sisi kiri dengan kayon bergoyang.
	var kelir := Panel.new()
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color(0.86, 0.79, 0.64)
	gaya.border_color = TemaJawa.MARUN
	gaya.set_border_width_all(8)
	kelir.add_theme_stylebox_override("panel", gaya)
	kelir.anchor_left = 0.04
	kelir.anchor_top = 0.06
	kelir.anchor_right = 0.5
	kelir.anchor_bottom = 0.86
	add_child(kelir)
	_kayon = Kayon.new()
	_kayon.anchor_left = 0.5
	_kayon.anchor_right = 0.5
	_kayon.anchor_top = 0.5
	_kayon.anchor_bottom = 0.5
	_kayon.offset_left = -120
	_kayon.offset_right = 120
	_kayon.offset_top = -200
	_kayon.offset_bottom = 170
	kelir.add_child(_kayon)

	# Kolom kanan: judul + menu.
	var kanan := VBoxContainer.new()
	kanan.anchor_left = 0.53
	kanan.anchor_right = 0.97
	kanan.anchor_top = 0.08
	kanan.anchor_bottom = 0.86
	kanan.alignment = BoxContainer.ALIGNMENT_CENTER
	kanan.add_theme_constant_override("separation", 10)
	add_child(kanan)
	kanan.add_child(TemaJawa.label("WIRABRAJA", 64, TemaJawa.EMAS))
	kanan.add_child(TemaJawa.label("Geger Alun-Alun Keraton", 28))
	kanan.add_child(TemaJawa.label("Lakon aksi ksatria wayang di Keraton Surakarta", 16, Color(1, 0.9, 0.7, 0.8)))
	var jarak := Control.new()
	jarak.custom_minimum_size = Vector2(0, 16)
	kanan.add_child(jarak)

	var tengah := CenterContainer.new()
	kanan.add_child(tengah)
	_panel_menu = VBoxContainer.new()
	(_panel_menu as VBoxContainer).add_theme_constant_override("separation", 12)
	tengah.add_child(_panel_menu)
	_panel_menu.add_child(TemaJawa.tombol("Mulai Lakon", _mulai))
	_panel_menu.add_child(TemaJawa.tombol("Pengaturan", func() -> void: _tampilkan(_pengaturan)))
	_panel_menu.add_child(TemaJawa.tombol("Kontrol", func() -> void: _tampilkan(_panel_kontrol)))
	if OS.get_name() != "Web":
		_panel_menu.add_child(TemaJawa.tombol("Keluar", func() -> void: get_tree().quit()))
	var rekor := "Rekor terbaik: belum ada"
	if Pengaturan.rekor_waktu > 0.0:
		rekor = "Rekor terbaik: %s  (%s)" % [Pengaturan.format_waktu(Pengaturan.rekor_waktu), Pengaturan.rekor_peringkat]
	_panel_menu.add_child(TemaJawa.label(rekor, 17, TemaJawa.EMAS))

	_pengaturan = PanelPengaturan.new()
	_pengaturan.visible = false
	_pengaturan.ditutup.connect(func() -> void: _panel_menu.visible = true)
	tengah.add_child(_pengaturan)
	_panel_kontrol = _buat_panel_kontrol()
	_panel_kontrol.visible = false
	tengah.add_child(_panel_kontrol)

	var kredit := TemaJawa.label("I Gusti Agung Ayu Putu Wulan Aristina (240030296)  ·  Sistem Informasi, "
			+ "Institut Teknologi dan Bisnis STIKOM Bali  ·  2026", 14, Color(1, 0.92, 0.75, 0.7))
	kredit.anchor_top = 1.0
	kredit.anchor_bottom = 1.0
	kredit.anchor_right = 1.0
	kredit.offset_top = -40
	kredit.offset_bottom = -12
	add_child(kredit)


func _process(_delta: float) -> void:
	if _kayon:
		_kayon.rotation = sin(Time.get_ticks_msec() * 0.0015) * 0.05


func _tampilkan(panel: Control) -> void:
	_panel_menu.visible = false
	panel.visible = true


func _mulai() -> void:
	mulai_ditekan.emit()
	AudioManager.putar_sfx("gong")
	if pindah_otomatis:
		get_tree().change_scene_to_file(SCENE_NARASI)


func _buat_panel_kontrol() -> PanelContainer:
	var p := PanelContainer.new()
	var isi := VBoxContainer.new()
	isi.add_theme_constant_override("separation", 6)
	p.add_child(isi)
	isi.add_child(TemaJawa.label("Kontrol", 30, TemaJawa.EMAS))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	isi.add_child(grid)
	for pasangan: Array in [
		["W A S D", "Bergerak"], ["Shift", "Berlari"], ["Spasi", "Melompat"],
		["Klik kiri", "Serang (klik 3x = kombo)"], ["Klik kanan / Ctrl", "Menghindar"],
		["Q", "Ajian Braja (bar kasekten penuh)"], ["Mouse", "Putar kamera"],
		["Esc / P", "Jeda"], ["M", "Musik hidup/mati"], ["R", "Ulang setelah menang/kalah"],
	]:
		var a := Label.new()
		a.text = pasangan[0]
		a.add_theme_color_override("font_color", TemaJawa.EMAS)
		grid.add_child(a)
		var b := Label.new()
		b.text = pasangan[1]
		grid.add_child(b)
	var tutup := TemaJawa.tombol("Kembali", func() -> void:
		p.visible = false
		_panel_menu.visible = true)
	tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	isi.add_child(tutup)
	return p
