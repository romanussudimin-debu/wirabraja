extends Node
## Uji otomatis Wirabraja v1.1 (dijalankan headless):
##   godot --headless --path . res://tests/uji_alur.tscn
## Memeriksa: narasi pembuka, audio, gerak/lompat/serangan pemain, tiga varian buta,
## sistem gelombang, tiga pola serangan bos + fase 2, kondisi MENANG dan KALAH.

const LEVEL := preload("res://scenes/level/level_1.tscn")
const NARASI := preload("res://scenes/ui/narasi_pembuka.tscn")
const PEMAIN := preload("res://scenes/player/player.tscn")
const BOS := preload("res://scenes/boss/bos_raksasa.tscn")
const KILAT := preload("res://scenes/enemies/buta_kilat.tscn")
const GEMPAL := preload("res://scenes/enemies/buta_gempal.tscn")
const PELEMPAR := preload("res://scenes/enemies/buta_pelempar.tscn")
const PRAJURIT := preload("res://scenes/enemies/buta.tscn")
const MENU := preload("res://scenes/ui/menu_utama.tscn")
const JAMU := preload("res://scenes/items/jamu.tscn")

var _gagal: int = 0
var _jumlah: int = 0


func _ready() -> void:
	# Simpan rekor & pengaturan asli agar uji tidak mengubah data pemain.
	var rekor_asli := [Pengaturan.rekor_waktu, Pengaturan.rekor_peringkat]
	await _jalankan_semua()
	Pengaturan.rekor_waktu = rekor_asli[0]
	Pengaturan.rekor_peringkat = rekor_asli[1]
	Pengaturan.simpan()
	AudioManager.hentikan_semua()
	await _tunggu(0.3)
	print("\n==== HASIL: %s (%d pemeriksaan, %d gagal) ====" % ["LULUS" if _gagal == 0 else "GAGAL", _jumlah, _gagal])
	get_tree().quit(1 if _gagal > 0 else 0)


func _jalankan_semua() -> void:
	await _uji_menu_dan_pengaturan()
	await _uji_narasi()
	_uji_audio()
	await _uji_kombo()
	await _uji_hindar_dan_ajian()
	await _uji_jamu()
	await _uji_varian_kilat()
	await _uji_varian_gempal()
	await _uji_varian_pelempar()
	await _uji_level_dan_bos()
	await _uji_kalah()


func _cek(kondisi: bool, pesan: String) -> void:
	_jumlah += 1
	print(("[OK]    " if kondisi else "[GAGAL] ") + pesan)
	if not kondisi:
		_gagal += 1


func _tunggu(detik: float) -> void:
	await get_tree().create_timer(detik, true, true).timeout


func _tekan(aksi: String) -> void:
	var e := InputEventAction.new()
	e.action = aksi
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var lepas := InputEventAction.new()
	lepas.action = aksi
	lepas.pressed = false
	Input.parse_input_event(lepas)
	await get_tree().process_frame


# ------------------------------------------------------------------ narasi & audio

func _uji_narasi() -> void:
	print("\n-- Narasi pembuka --")
	var n := NARASI.instantiate()
	n.pindah_otomatis = false
	add_child(n)
	var selesai := [false]
	n.selesai.connect(func() -> void: selesai[0] = true)
	await _tunggu(4.8)  # pembukaan: kayon + judul lakon
	_cek(n.indeks_baris == 0, "baris pertama janturan tampil setelah pembukaan kayon")
	_cek(AudioManager.nama_musik_sekarang() == "narasi", "musik narasi diputar")
	await _tekan("narasi_lanjut")   # teks sedang diketik -> tampil utuh
	await _tekan("narasi_lanjut")   # baris berikutnya
	_cek(n.indeks_baris == 1, "Spasi/Enter melanjutkan ke baris berikutnya")
	await _tekan("narasi_lewati")
	await _tunggu(2.0)
	_cek(selesai[0], "Esc melewati narasi (sinyal selesai)")
	n.queue_free()
	await _tunggu(0.1)


func _uji_audio() -> void:
	print("\n-- Audio --")
	var hilang: Array[String] = []
	for nama: String in AudioManager.SFX.keys() + AudioManager.MUSIK.keys():
		if not AudioManager.tersedia(nama):
			hilang.append(nama)
	_cek(hilang.is_empty(), "semua %d file audio terdaftar tersedia %s" % [AudioManager.SFX.size() + AudioManager.MUSIK.size(), hilang])
	_cek(AudioServer.get_bus_index("Musik") != -1 and AudioServer.get_bus_index("SFX") != -1, "bus audio Musik & SFX dibuat")
	# Wajib untuk versi Web: bus yang dibuat saat runtime tidak bersuara pada mode audio sample.
	var tata_bus := load("res://default_bus_layout.tres") as AudioBusLayout
	_cek(tata_bus != null and str(tata_bus.get("bus/1/name")) == "Musik" and str(tata_bus.get("bus/2/name")) == "SFX",
			"bus Musik & SFX didefinisikan di default_bus_layout.tres (syarat suara di versi Web)")


# ------------------------------------------------------------------ v2.0: menu, pengaturan, kombat

func _uji_menu_dan_pengaturan() -> void:
	print("\n-- Menu utama & pengaturan (v2.0) --")
	var m := MENU.instantiate()
	m.pindah_otomatis = false
	add_child(m)
	await _tunggu(0.3)
	var tombol: Array[String] = []
	for b: Node in m.find_children("*", "Button", true, false):
		tombol.append((b as Button).text)
	_cek("Mulai Lakon" in tombol and "Pengaturan" in tombol and "Kontrol" in tombol, "menu utama memiliki tombol %s" % [tombol])
	var dimulai := [false]
	m.mulai_ditekan.connect(func() -> void: dimulai[0] = true)
	for b: Node in m.find_children("*", "Button", true, false):
		if (b as Button).text == "Mulai Lakon":
			(b as Button).pressed.emit()
	_cek(dimulai[0], "tombol Mulai Lakon memulai permainan")
	m.queue_free()
	var lama := Pengaturan.volume_musik
	Pengaturan.ubah("volume_musik", 0.5)
	var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Musik"))
	_cek(absf(db - linear_to_db(0.5)) < 0.1, "pengaturan volume musik diterapkan ke bus (%.1f dB)" % db)
	Pengaturan.volume_musik = 0.1
	Pengaturan.muat()
	_cek(absf(Pengaturan.volume_musik - 0.5) < 0.001, "pengaturan tersimpan ke file dan dapat dimuat ulang")
	Pengaturan.ubah("volume_musik", lama)
	await _tunggu(0.1)


func _uji_kombo() -> void:
	print("\n-- Kombo 3 pukulan (v2.0) --")
	var a := _arena(PRAJURIT, Vector3(0, 0, -1.7))
	var pemain: Pemain = a[1]
	var buta: Buta = a[2]
	buta.komponen_hp.inisialisasi(9999)
	buta.ketahanan_dorong = 1.0
	buta.set_physics_process(false)
	await _tunggu(0.3)
	var hp := [buta.komponen_hp.hp]
	var selisih: Array[int] = []
	for i in 3:
		pemain._minta_serang = true
		await get_tree().physics_frame
		await _tunggu(0.2)
		pemain._minta_serang = true
		await _tunggu(0.25)
		selisih.append(hp[0] - buta.komponen_hp.hp)
		hp[0] = buta.komponen_hp.hp
		if i == 0:
			_cek(pemain.kombo >= 2, "klik saat mengayun menyambung ke pukulan ke-2 (kombo %d)" % pemain.kombo)
	_cek(selisih.size() == 3 and selisih[2] > selisih[0], "pukulan ke-3 lebih kuat (damage %s)" % [selisih])
	_cek(pemain.kasekten > 0.0, "pukulan yang mengenai mengisi kasekten (%.0f)" % pemain.kasekten)
	a[0].queue_free()
	await _tunggu(0.1)


func _uji_hindar_dan_ajian() -> void:
	print("\n-- Menghindar & Ajian Braja (v2.0) --")
	var a := _arena(PRAJURIT, Vector3(0, 0, -5.0))
	var pemain: Pemain = a[1]
	var dekat: Buta = a[2]
	dekat.set_physics_process(false)
	var jauh := PRAJURIT.instantiate() as Buta
	a[0].add_child(jauh)
	jauh.global_position = Vector3(0, 0, -13.0)
	jauh.set_physics_process(false)
	await _tunggu(0.3)
	pemain._minta_hindar = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	_cek(pemain.state == Pemain.State.MENGHINDAR and Vector2(pemain.velocity.x, pemain.velocity.z).length() > 10.0,
			"menghindar: pemain melesat (%.1f m/s)" % Vector2(pemain.velocity.x, pemain.velocity.z).length())
	var hp := pemain.komponen_hp.hp
	pemain.terima_serangan(30, Vector3.BACK)
	_cek(pemain.komponen_hp.hp == hp, "menghindar memberi kekebalan sesaat")
	await _tunggu(1.0)
	pemain.global_position = Vector3.ZERO
	pemain._minta_ajian = true
	await _tunggu(0.6)
	_cek(dekat.komponen_hp.hp == dekat.komponen_hp.hp_maks, "Ajian tidak bisa dipakai sebelum kasekten penuh")
	pemain.tambah_kasekten(999.0)
	pemain._minta_ajian = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	_cek(pemain.state == Pemain.State.AJIAN and pemain.kasekten == 0.0, "Q saat kasekten penuh: Ajian Braja dimulai, kasekten habis")
	await _tunggu(pemain.waktu_ancang_ajian + 0.2)
	_cek(dekat.komponen_hp.mati or dekat.komponen_hp.hp < dekat.komponen_hp.hp_maks, "Ajian melukai buta dalam radius 7 m")
	_cek(jauh.komponen_hp.hp == jauh.komponen_hp.hp_maks, "buta di luar radius tidak terkena")
	_cek(GameManager.ajian_dipakai == 1, "statistik ajian tercatat")
	a[0].queue_free()
	await _tunggu(0.1)


func _uji_jamu() -> void:
	print("\n-- Jamu (v2.0) --")
	var a := _arena(PRAJURIT, Vector3(0, 0, -30.0))
	var pemain: Pemain = a[1]
	(a[2] as Buta).set_physics_process(false)
	await _tunggu(0.2)
	var j := JAMU.instantiate() as Jamu
	a[0].add_child(j)
	j.global_position = Vector3.ZERO
	await _tunggu(0.4)
	_cek(is_instance_valid(j) and not j._diambil, "jamu tidak diambil saat HP penuh")
	pemain.terima_serangan(40, Vector3.BACK)
	await _tunggu(0.5)
	_cek(pemain.komponen_hp.hp == pemain.hp_maks - 40 + 25, "jamu memulihkan 25 HP (HP %d)" % pemain.komponen_hp.hp)
	_cek(GameManager.jamu_diminum == 1, "statistik jamu tercatat")
	var b := PRAJURIT.instantiate() as Buta
	b.peluang_jamu = 1.0
	a[0].add_child(b)
	b.global_position = Vector3(5, 0, 5)
	await _tunggu(0.1)
	b.terima_serangan(9999, Vector3.FORWARD)
	await _tunggu(0.2)
	_cek(get_tree().get_nodes_in_group("jamu").size() >= 1, "buta yang kalah dapat menjatuhkan jamu")
	a[0].queue_free()
	await _tunggu(0.1)


# ------------------------------------------------------------------ arena uji varian

## Arena kecil: lantai + pemain + satu musuh. Mengembalikan [akar, pemain, musuh].
func _arena(scene_musuh: PackedScene, posisi_musuh: Vector3) -> Array:
	var akar := Node3D.new()
	add_child(akar)
	var lantai := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(80, 1, 80)
	cs.shape = b
	cs.position = Vector3(0, -0.5, 0)
	lantai.add_child(cs)
	akar.add_child(lantai)
	var pemain := PEMAIN.instantiate() as Pemain
	akar.add_child(pemain)
	var musuh := scene_musuh.instantiate() as Buta
	akar.add_child(musuh)
	musuh.global_position = posisi_musuh
	GameManager.mulai_level(1)
	return [akar, pemain, musuh]


func _uji_varian_kilat() -> void:
	print("\n-- Buta Kilat --")
	var a := _arena(KILAT, Vector3(0, 0, -10))
	var pemain: Pemain = a[1]
	var kilat: ButaKilat = a[2]
	var laju_maks := 0.0
	var simpang_maks := 0.0
	for i in 120:
		await get_tree().physics_frame
		laju_maks = maxf(laju_maks, Vector2(kilat.velocity.x, kilat.velocity.z).length())
		if kilat.state == Buta.State.MENGEJAR:
			simpang_maks = maxf(simpang_maks, absf(kilat.velocity.x))
	_cek(simpang_maks > 1.0, "Buta Kilat mendekat secara zig-zag (gerak menyamping %.1f m/s)" % simpang_maks)
	_cek(laju_maks > 10.0, "Buta Kilat menerjang cepat (laju maks %.1f m/s)" % laju_maks)
	_cek(pemain.komponen_hp.hp < pemain.hp_maks, "terjangan Buta Kilat mengenai pemain (HP %d)" % pemain.komponen_hp.hp)
	a[0].queue_free()
	await _tunggu(0.1)


func _uji_varian_gempal() -> void:
	print("\n-- Buta Gempal --")
	var a := _arena(GEMPAL, Vector3(0, 0, -2.6))
	var pemain: Pemain = a[1]
	var gempal: ButaGempal = a[2]
	await _tunggu(0.3)
	gempal.terima_serangan(25, Vector3.FORWARD, 7.0)
	_cek(gempal.state != Buta.State.TERKENA, "Buta Gempal tidak terhuyung saat dipukul (super armor)")
	_cek(gempal.komponen_hp.hp_maks >= 200 and gempal.kecepatan < 2.5, "Buta Gempal ber-HP besar (%d) dan lambat (%.1f m/s)" % [gempal.komponen_hp.hp_maks, gempal.kecepatan])
	await _tunggu(2.5)
	_cek(pemain.komponen_hp.hp <= pemain.hp_maks - gempal.damage, "Injak Bumi Buta Gempal melukai pemain (HP %d)" % pemain.komponen_hp.hp)
	a[0].queue_free()
	await _tunggu(0.1)


func _uji_varian_pelempar() -> void:
	print("\n-- Buta Pelempar --")
	var a := _arena(PELEMPAR, Vector3(0, 0, -4.0))
	var pemain: Pemain = a[1]
	var pelempar: ButaPelempar = a[2]
	await _tunggu(1.0)
	var jarak := Vector2(pelempar.global_position.x, pelempar.global_position.z).distance_to(Vector2(pemain.global_position.x, pemain.global_position.z))
	_cek(jarak > 4.5, "Buta Pelempar mundur menjaga jarak (jarak %.1f m)" % jarak)
	var ada_batu := false
	for i in 300:
		await get_tree().physics_frame
		for n: Node in a[0].get_children():
			if n is BatuLempar:
				ada_batu = true
		if pemain.komponen_hp.hp < pemain.hp_maks:
			break
	_cek(ada_batu, "Buta Pelempar melempar batu (proyektil BatuLempar muncul)")
	_cek(pemain.komponen_hp.hp < pemain.hp_maks, "batu mengenai pemain (HP %d)" % pemain.komponen_hp.hp)
	a[0].queue_free()
	await _tunggu(0.1)


# ------------------------------------------------------------------ level penuh

func _bunuh_buta_aktif() -> void:
	for b: Node in get_tree().get_nodes_in_group("buta"):
		if b is Buta and b.is_in_group("musuh"):
			(b as Buta).terima_serangan(9999, Vector3.FORWARD)


func _uji_level_dan_bos() -> void:
	print("\n-- Level 1: pemain, gelombang, bos --")
	var level := LEVEL.instantiate()
	add_child(level)
	await _tunggu(0.3)
	var pemain := get_tree().get_first_node_in_group("pemain") as Pemain
	var hud := level.get_node("HUD") as Hud
	_cek(GameManager.state == GameManager.State.BERTARUNG, "state awal BERTARUNG")
	_cek(GameManager.musuh_tersisa == 12, "total buta 3 gelombang = 12 (didapat %d)" % GameManager.musuh_tersisa)
	_cek(get_tree().get_nodes_in_group("musuh").size() == 4, "hanya gelombang 1 (4 buta) yang aktif di awal")
	_cek(AudioManager.nama_musik_sekarang() == "pertempuran", "musik pertempuran diputar")
	var jeda := level.get_node("MenuJeda") as MenuJeda
	await _tekan("jeda")
	_cek(get_tree().paused and jeda.sedang_jeda(), "Esc/P menjeda permainan (v2.0)")
	jeda.lanjutkan()
	await get_tree().process_frame
	_cek(not get_tree().paused, "Lanjutkan melanjutkan permainan")

	var z0 := pemain.global_position.z
	Input.action_press("maju")
	await _tunggu(0.5)
	Input.action_release("maju")
	_cek(pemain.global_position.z < z0 - 1.0, "WASD: pemain bergerak maju (dz=%.2f)" % (pemain.global_position.z - z0))
	_cek(pemain.is_on_floor(), "pemain berdiri di lantai (collision)")
	Input.action_press("lompat")
	await _tunggu(0.15)
	Input.action_release("lompat")
	_cek(pemain.global_position.y > 0.3, "Spasi: pemain melompat (y=%.2f)" % pemain.global_position.y)
	await _tunggu(1.0)

	var buta := get_tree().get_nodes_in_group("buta")[0] as Buta
	buta.global_position = pemain.global_position + (-pemain.model.global_basis.z) * 1.6
	await _tunggu(0.1)
	var hp_awal := buta.komponen_hp.hp
	pemain._minta_serang = true
	await _tunggu(0.5)
	_cek(buta.komponen_hp.hp < hp_awal, "klik kiri: gada mengenai buta (HP %d -> %d)" % [hp_awal, buta.komponen_hp.hp])
	await _tunggu(3.0)
	_cek(pemain.komponen_hp.hp < pemain.hp_maks, "buta mengejar & menyerang pemain (HP %d)" % pemain.komponen_hp.hp)

	# Gelombang 2 & 3.
	pemain.komponen_hp.inisialisasi(99999)
	for ke in [2, 3]:
		_bunuh_buta_aktif()
		await _tunggu(2.6)
		var aktif := get_tree().get_nodes_in_group("musuh").size()
		var label: String = hud.get_node("%LabelMusuh").text
		_cek(aktif == 4 and label.begins_with("Gelombang %d/3" % ke), "gelombang %d turun (%d buta aktif, HUD: '%s')" % [ke, aktif, label])
	_bunuh_buta_aktif()
	await _tunggu(0.2)
	_cek(GameManager.musuh_tersisa == 0 and GameManager.state == GameManager.State.BOS, "12 buta kalah -> state BOS")
	await _tunggu(2.5)
	var bos := get_tree().get_first_node_in_group("bos") as BosRaksasa
	_cek(bos != null, "bos Ditya Kalamurka muncul")
	if bos == null:
		level.queue_free()
		return
	_cek(AudioManager.nama_musik_sekarang() == "bos", "musik bos diputar")
	var hp_bos := bos.komponen_hp.hp
	bos.terima_serangan(50, Vector3.FORWARD)
	_cek(bos.komponen_hp.hp == hp_bos, "bos kebal saat bangkit dari tanah")
	await _tunggu(bos.waktu_muncul)

	# Pola 1: Hantaman Bumi.
	bos._sisa_jeda_panggil = 99.0
	bos._sisa_jeda_serbu = 99.0
	pemain.global_position = bos.global_position + Vector3(0, 0, 4.0)
	var hp_p := pemain.komponen_hp.hp
	await _tunggu(0.3)
	_cek(bos.state == BosRaksasa.State.ANCANG_HANTAM and bos.penanda_hantam.visible, "Pola 1: ancang-ancang Hantaman Bumi + lingkaran penanda")
	await _tunggu(bos.waktu_ancang_hantam + 0.2)
	_cek(pemain.komponen_hp.hp < hp_p, "Pola 1: Hantaman Bumi mengenai pemain")
	await _tunggu(bos.waktu_pulih + 0.5)

	# Pola 3: Panggil Bala.
	await _tunggu_bos_mengejar(bos)
	pemain.global_position = bos.global_position + Vector3(0, 0, 7.0)
	bos._sisa_jeda_serangan = 0.0
	bos._sisa_jeda_panggil = 0.0
	await _tunggu(0.2)
	_cek(bos.state == BosRaksasa.State.MEMANGGIL, "Pola 3: bos mulai memanggil bala (state %s)" % BosRaksasa.State.keys()[bos.state])
	await _tunggu(bos.waktu_ancang_panggil + 0.3)
	var cilik := bos._jumlah_panggilan_hidup()
	_cek(cilik == bos.jumlah_panggil, "Pola 3: %d buta cilik dipanggil" % cilik)
	_cek(GameManager.state == GameManager.State.BOS and GameManager.musuh_tersisa == 0, "buta panggilan tidak mengubah hitungan misi")
	for b: Node in bos._panggilan:
		(b as Buta).terima_serangan(9999, Vector3.FORWARD)
	await _tunggu(bos.waktu_pulih + 0.3)

	# Pola 2: Serbuan Lurus (pemain berdiri jauh di depan bos, di ruang terbuka).
	await _tunggu_bos_mengejar(bos)
	bos._sisa_jeda_panggil = 99.0
	bos._sisa_jeda_serbu = 0.0
	bos._sisa_jeda_serangan = 0.0
	pemain.global_position = bos.global_position + Vector3(0, 0, 13.0)
	await _tunggu(0.2)
	_cek(bos.state == BosRaksasa.State.ANCANG_SERBU and bos.penanda_serbu.visible, "Pola 2: ancang-ancang Serbuan Lurus + jalur penanda")
	hp_p = pemain.komponen_hp.hp
	var sempat_serbu := false
	for i in 150:
		await get_tree().physics_frame
		if bos.state == BosRaksasa.State.SERBU:
			sempat_serbu = true
		if pemain.komponen_hp.hp < hp_p:
			break
	_cek(sempat_serbu, "Pola 2: bos menyeruduk lurus")
	_cek(pemain.komponen_hp.hp < hp_p, "Pola 2: serbuan mengenai pemain")
	await _tunggu(2.5)

	# Fase 2.
	var warna_awal := _warna_kulit(bos)
	var sisa := bos.komponen_hp.hp - int(bos.komponen_hp.hp_maks * 0.49)
	bos.terima_serangan(sisa, Vector3.FORWARD)
	await _tunggu(0.1)
	_cek(bos.fase == 2 and bos.state == BosRaksasa.State.BERUBAH_FASE, "HP bos < 50% -> fase 2 (MURKA)")
	_cek(_warna_kulit(bos).r > warna_awal.r + 0.05, "fase 2: kulit bos memerah")
	_cek((hud.get_node("%NamaBos") as Label).text.contains("MURKA"), "HUD menandai fase murka")
	var hp_saat_berubah := bos.komponen_hp.hp
	bos.terima_serangan(50, Vector3.FORWARD)
	_cek(bos.komponen_hp.hp == hp_saat_berubah, "bos kebal selama berubah fase")
	_cek(bos._waktu(bos.waktu_ancang_hantam) < bos.waktu_ancang_hantam and bos._radius_hantam() > bos.radius_hantaman, "fase 2: ancang-ancang lebih singkat & Hantaman Bumi lebih luas")
	var bos_baru := BOS.instantiate() as BosRaksasa
	add_child(bos_baru)
	_cek(_warna_kulit(bos_baru).is_equal_approx(warna_awal), "warna murka tidak menular ke instance bos baru")
	bos_baru.free()

	# Kalahkan bos.
	await _tunggu(bos.lama_berubah_fase + 0.2)
	bos.terima_serangan(99999, Vector3.FORWARD)
	await _tunggu(0.3)
	_cek(GameManager.state == GameManager.State.MENANG, "bos kalah -> state MENANG")
	_cek(hud.get_node("%LayarAkhir").visible and hud.get_node("%JudulAkhir").text == "MENANG!", "HUD menampilkan teks MENANG")
	_cek(AudioManager.nama_musik_sekarang() == "", "musik berhenti saat menang (diganti sfx kemenangan)")
	_cek((hud.get_node("%SubAkhir") as Label).text.contains("Peringkat") and (hud.get_node("%StatistikAkhir") as Label).text.contains("Buta dikalahkan 12"),
			"layar hasil menampilkan peringkat & statistik (v2.0)")
	_cek(Pengaturan.rekor_waktu > 0.0 and hud.get_node("%TombolAkhir").get_child_count() == 2, "rekor waktu tersimpan; tombol Ulangi & Menu Utama tersedia")
	level.queue_free()
	await _tunggu(0.3)


## Menunggu bos selesai dengan pola sebelumnya (kembali ke state MENGEJAR).
func _tunggu_bos_mengejar(bos: BosRaksasa) -> void:
	var pemain := get_tree().get_first_node_in_group("pemain") as Pemain
	for i in 600:
		# Jauhkan pemain sementara agar bos tidak memulai Hantaman Bumi lagi.
		pemain.global_position = bos.global_position + Vector3(0, 0, 8.0)
		bos._sisa_jeda_serbu = 99.0
		bos._sisa_jeda_panggil = 99.0
		await get_tree().physics_frame
		if bos.state == BosRaksasa.State.MENGEJAR:
			return


func _warna_kulit(bos: BosRaksasa) -> Color:
	var mi := bos.get_node("Model/Badan") as MeshInstance3D
	return (mi.get_surface_override_material(0) as StandardMaterial3D).albedo_color


func _uji_kalah() -> void:
	print("\n-- Kondisi kalah --")
	var level := LEVEL.instantiate()
	add_child(level)
	await _tunggu(0.3)
	_cek(GameManager.state == GameManager.State.BERTARUNG and GameManager.musuh_tersisa == 12, "level baru: state di-reset")
	var pemain := get_tree().get_first_node_in_group("pemain") as Pemain
	for i in 20:
		pemain.terima_serangan(20, Vector3.BACK)
		await _tunggu(pemain.waktu_kebal + 0.05)
		if pemain.state == Pemain.State.MATI:
			break
	_cek(pemain.state == Pemain.State.MATI, "HP pemain habis -> pemain MATI")
	_cek(GameManager.state == GameManager.State.KALAH, "state KALAH")
	var hud := level.get_node("HUD") as Hud
	_cek(hud.get_node("%JudulAkhir").text == "KALAH", "HUD menampilkan teks KALAH + petunjuk R")
	level.queue_free()
	await _tunggu(0.2)
