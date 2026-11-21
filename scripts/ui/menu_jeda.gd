class_name MenuJeda
extends CanvasLayer
## Menu jeda (v2.0). Esc / P menjeda permainan. Di browser, menekan Esc melepas
## kunci mouse; kejadian itu juga otomatis menjeda permainan.

const SCENE_MENU := "res://scenes/ui/menu_utama.tscn"

var _latar: ColorRect
var _panel_utama: PanelContainer
var _pengaturan: PanelPengaturan
var _mouse_terkunci_sebelumnya: bool = false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_latar = ColorRect.new()
	_latar.color = Color(0.05, 0.03, 0.02, 0.7)
	_latar.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_latar)
	var tengah := CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	_latar.add_child(tengah)
	_panel_utama = PanelContainer.new()
	_panel_utama.theme = TemaJawa.ambil()
	tengah.add_child(_panel_utama)
	var isi := VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	_panel_utama.add_child(isi)
	isi.add_child(TemaJawa.label("Jeda", 36, TemaJawa.EMAS))
	isi.add_child(TemaJawa.label("Wayang berhenti sejenak di kelir...", 16))
	isi.add_child(TemaJawa.tombol("Lanjutkan", lanjutkan))
	isi.add_child(TemaJawa.tombol("Pengaturan", func() -> void:
		_panel_utama.visible = false
		_pengaturan.visible = true))
	isi.add_child(TemaJawa.tombol("Ulangi Level", func() -> void: GameManager.ulang_level()))
	isi.add_child(TemaJawa.tombol("Menu Utama", func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file(SCENE_MENU)))
	_pengaturan = PanelPengaturan.new()
	_pengaturan.visible = false
	_pengaturan.ditutup.connect(func() -> void: _panel_utama.visible = true)
	tengah.add_child(_pengaturan)
	_latar.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jeda"):
		if sedang_jeda():
			lanjutkan()
		elif GameManager.sedang_bermain():
			jeda()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	# Mouse terlepas saat bermain (Esc di browser / jendela kehilangan fokus) -> jeda otomatis.
	var terkunci := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if _mouse_terkunci_sebelumnya and not terkunci and not sedang_jeda() and GameManager.sedang_bermain():
		jeda()
	_mouse_terkunci_sebelumnya = terkunci


func sedang_jeda() -> bool:
	return _latar.visible


func jeda() -> void:
	_latar.visible = true
	_panel_utama.visible = true
	_pengaturan.visible = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_terkunci_sebelumnya = false


func lanjutkan() -> void:
	_latar.visible = false
	get_tree().paused = false
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
