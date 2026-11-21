class_name PanelPengaturan
extends PanelContainer
## Panel pengaturan (v2.0): volume musik, volume efek suara, sensitivitas mouse,
## dan layar penuh. Nilai langsung diterapkan dan disimpan oleh autoload Pengaturan.

signal ditutup


func _ready() -> void:
	theme = TemaJawa.ambil()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var isi := VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	add_child(isi)
	isi.add_child(TemaJawa.label("Pengaturan", 30, TemaJawa.EMAS))
	isi.add_child(_baris_slider("Volume musik", Pengaturan.volume_musik, 0.0, 1.0,
			func(v: float) -> void: Pengaturan.ubah("volume_musik", v)))
	isi.add_child(_baris_slider("Volume efek suara", Pengaturan.volume_sfx, 0.0, 1.0,
			func(v: float) -> void:
				Pengaturan.ubah("volume_sfx", v)
				AudioManager.putar_sfx("klik")))
	isi.add_child(_baris_slider("Sensitivitas mouse", Pengaturan.sensitivitas_mouse, 0.3, 2.5,
			func(v: float) -> void: Pengaturan.ubah("sensitivitas_mouse", v)))
	if OS.get_name() != "Web":
		var cek := CheckBox.new()
		cek.text = "Layar penuh"
		cek.button_pressed = Pengaturan.layar_penuh
		cek.toggled.connect(func(on: bool) -> void: Pengaturan.ubah("layar_penuh", on))
		isi.add_child(cek)
	var tutup := TemaJawa.tombol("Kembali", func() -> void:
		visible = false
		ditutup.emit())
	tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	isi.add_child(tutup)


func _baris_slider(judul: String, nilai: float, minimum: float, maksimum: float, saat_ubah: Callable) -> Control:
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 16)
	var l := Label.new()
	l.text = judul
	l.custom_minimum_size = Vector2(220, 0)
	baris.add_child(l)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maksimum
	slider.step = 0.05
	slider.value = nilai
	slider.custom_minimum_size = Vector2(260, 28)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var angka := Label.new()
	angka.custom_minimum_size = Vector2(60, 0)
	angka.text = "%d%%" % roundi(nilai * 100.0)
	slider.value_changed.connect(func(v: float) -> void:
		angka.text = "%d%%" % roundi(v * 100.0)
		saat_ubah.call(v))
	baris.add_child(slider)
	baris.add_child(angka)
	return baris
