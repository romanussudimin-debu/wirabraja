class_name TemaJawa
extends RefCounted
## Tema antarmuka bernuansa Jawa (sogan, emas, marun) untuk menu dan panel (v2.0).

const SOGAN_GELAP := Color(0.16, 0.09, 0.05, 0.96)
const SOGAN := Color(0.32, 0.19, 0.09, 1)
const EMAS := Color(0.95, 0.76, 0.3, 1)
const MARUN := Color(0.46, 0.08, 0.11, 1)
const KREM := Color(0.98, 0.93, 0.82, 1)

static var _tema: Theme


static func ambil() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font_size = 20
	var normal := _kotak(SOGAN, EMAS, 2)
	var hover := _kotak(MARUN, EMAS, 3)
	var tekan := _kotak(Color(0.25, 0.04, 0.06), EMAS, 3)
	var fokus := _kotak(Color(0, 0, 0, 0), KREM, 2)
	for nama: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var gaya: StyleBox = {"normal": normal, "hover": hover, "pressed": tekan, "focus": fokus, "disabled": normal}[nama]
		t.set_stylebox(nama, "Button", gaya)
	t.set_color("font_color", "Button", KREM)
	t.set_color("font_hover_color", "Button", EMAS)
	t.set_color("font_pressed_color", "Button", EMAS)
	t.set_color("font_focus_color", "Button", KREM)
	t.set_font_size("font_size", "Button", 22)
	t.set_stylebox("panel", "PanelContainer", _kotak(SOGAN_GELAP, EMAS, 3, 18))
	t.set_color("font_color", "Label", KREM)
	t.set_color("font_color", "CheckBox", KREM)
	var alur := StyleBoxFlat.new()
	alur.bg_color = Color(0.1, 0.06, 0.03)
	alur.content_margin_top = 4
	alur.content_margin_bottom = 4
	alur.set_corner_radius_all(3)
	t.set_stylebox("slider", "HSlider", alur)
	var isi := alur.duplicate() as StyleBoxFlat
	isi.bg_color = EMAS
	t.set_stylebox("grabber_area", "HSlider", isi)
	t.set_stylebox("grabber_area_highlight", "HSlider", isi)
	_tema = t
	return t


static func _kotak(latar: Color, tepi: Color, tebal: int, margin: float = 10.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = latar
	s.border_color = tepi
	s.set_border_width_all(tebal)
	s.set_corner_radius_all(6)
	s.content_margin_left = margin + 8
	s.content_margin_right = margin + 8
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	return s


## Tombol dengan bunyi klik (bonang) saat ditekan.
static func tombol(teks: String, aksi: Callable) -> Button:
	var b := Button.new()
	b.text = teks
	b.custom_minimum_size = Vector2(320, 52)
	b.pressed.connect(func() -> void:
		AudioManager.putar_sfx("klik")
		aksi.call()
	)
	return b


static func label(teks: String, ukuran: int = 20, warna: Color = KREM) -> Label:
	var l := Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
