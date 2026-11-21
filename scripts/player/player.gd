class_name Pemain
extends CharacterBody3D
## Raden Wirabraja — ksatria yang dikendalikan pemain.
## Kontrol: WASD gerak (relatif kamera), Shift lari, Spasi lompat, klik kiri serang,
## klik kanan / Ctrl menghindar, Q Ajian Braja (v2.0).
##
## State machine pemain:
##   NORMAL -> MENYERANG (klik kiri; klik lagi = kombo s.d. 3 pukulan) -> NORMAL
##   NORMAL/MENYERANG -> MENGHINDAR (melesat singkat, kebal) -> NORMAL
##   NORMAL/MENYERANG -> AJIAN (bar kasekten penuh; gelombang kejut di sekeliling) -> NORMAL
##   NORMAL/MENYERANG -> TERKENA (diserang) -> NORMAL
##   apa pun -> MATI (HP habis)
##
## Model placeholder ada di node "Model". Untuk mengganti dengan model asli,
## ganti isi node Model; node LenganKanan/LenganKiri/KakiKanan/KakiKiri bersifat
## opsional (animasi prosedural hanya berjalan bila node tersebut ada).

signal hp_berubah(hp: int, hp_maks: int)
signal kasekten_berubah(nilai: float, maks: float)
signal ajian_dilepas

enum State { NORMAL, MENYERANG, MENGHINDAR, AJIAN, TERKENA, MATI }

@export_group("Gerak")
## Kecepatan jalan ksatria (m/detik)
@export var kecepatan: float = 5.0
## Kecepatan saat menahan Shift (m/detik)
@export var kecepatan_lari: float = 8.5
@export var kekuatan_lompat: float = 6.5
@export var percepatan: float = 45.0
@export var kecepatan_putar: float = 12.0

@export_group("Nyawa")
@export var hp_maks: int = 100
## Lama kebal setelah terkena serangan (detik)
@export var waktu_kebal: float = 0.7
@export var lama_terhuyung: float = 0.25

@export_group("Serangan")
@export var damage: int = 25
@export var durasi_serangan: float = 0.42
## Jendela waktu hitbox aktif, dihitung dari awal ayunan (detik)
@export var awal_hitbox: float = 0.10
@export var akhir_hitbox: float = 0.26
@export var dorongan_ke_musuh: float = 7.0
@export var langkah_maju_serangan: float = 3.0

@export_group("Kombo")
## Pengali damage pukulan ke-3 (pukulan penutup kombo).
@export var pengali_pukulan_3: float = 1.8
@export var pengali_dorong_pukulan_3: float = 1.7

@export_group("Menghindar")
@export var kecepatan_hindar: float = 15.0
@export var durasi_hindar: float = 0.22
@export var jeda_hindar: float = 0.7

@export_group("Ajian Braja")
@export var kasekten_maks: float = 100.0
## Kasekten bertambah setiap pukulan gada mengenai musuh.
@export var kasekten_per_kena: float = 12.0
@export var radius_ajian: float = 7.0
@export var damage_ajian: int = 70
@export var waktu_ancang_ajian: float = 0.45

@onready var model: Node3D = $Model
@onready var hitbox: Area3D = $Model/Hitbox
@onready var kamera_rig: KameraOrbit = $KameraRig
@onready var komponen_hp: KomponenHP = $KomponenHP
@onready var _lengan_kanan: Node3D = get_node_or_null("Model/LenganKanan")
@onready var _lengan_kiri: Node3D = get_node_or_null("Model/LenganKiri")
@onready var _kaki_kanan: Node3D = get_node_or_null("Model/KakiKanan")
@onready var _kaki_kiri: Node3D = get_node_or_null("Model/KakiKiri")

var state: State = State.NORMAL
var _gravitasi: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _waktu_state: float = 0.0
var _sisa_kebal: float = 0.0
var _minta_serang: bool = false
var _sudah_kena: Array[Node] = []
var _fase_langkah: float = 0.0
var _tween_lengan: Tween
var kombo: int = 0
var kasekten: float = 0.0
var _kombo_antre: bool = false
var _minta_hindar: bool = false
var _minta_ajian: bool = false
var _sisa_jeda_hindar: float = 0.0
var _arah_hindar: Vector3 = Vector3.FORWARD
var _ajian_meledak: bool = false


func _ready() -> void:
	add_to_group("pemain")
	komponen_hp.hp_berubah.connect(func(h: int, m: int) -> void: hp_berubah.emit(h, m))
	komponen_hp.habis.connect(_saat_mati)
	komponen_hp.inisialisasi(hp_maks)
	# Model menghadap arah awal node, lalu node akar dibuat tanpa rotasi
	# (rotasi hadap ditangani node Model, kamera ditangani KameraRig).
	model.rotation.y = rotation.y
	rotation.y = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("serang") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_minta_serang = true
	elif event.is_action_pressed("menghindar"):
		_minta_hindar = true
	elif event.is_action_pressed("ajian"):
		_minta_ajian = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravitasi * delta
	_sisa_kebal = maxf(_sisa_kebal - delta, 0.0)
	_sisa_jeda_hindar = maxf(_sisa_jeda_hindar - delta, 0.0)
	_waktu_state += delta

	# Ajian dan menghindar dapat memotong serangan biasa.
	if state == State.NORMAL or state == State.MENYERANG:
		if _minta_ajian and kasekten >= kasekten_maks:
			_mulai_ajian()
		elif _minta_hindar and _sisa_jeda_hindar <= 0.0:
			_mulai_hindar()

	match state:
		State.NORMAL:
			_proses_gerak(delta, 1.0)
			if Input.is_action_just_pressed("lompat") and is_on_floor():
				velocity.y = kekuatan_lompat
				AudioManager.putar_sfx("lompat")
			if _minta_serang:
				_mulai_serang(1)
		State.MENYERANG:
			_proses_gerak(delta, 0.35)
			if _minta_serang and _waktu_state >= awal_hitbox:
				_kombo_antre = true
			if _waktu_state >= awal_hitbox and _waktu_state <= akhir_hitbox:
				_periksa_hitbox()
			if _waktu_state >= durasi_serangan:
				if _kombo_antre and kombo < 3:
					_mulai_serang(kombo + 1)
				else:
					kombo = 0
					_ganti_state(State.NORMAL)
		State.MENGHINDAR:
			velocity.x = _arah_hindar.x * kecepatan_hindar
			velocity.z = _arah_hindar.z * kecepatan_hindar
			if _waktu_state >= durasi_hindar:
				velocity.x *= 0.3
				velocity.z *= 0.3
				_ganti_state(State.NORMAL)
		State.AJIAN:
			_rem(delta, 30.0)
			if not _ajian_meledak and _waktu_state >= waktu_ancang_ajian:
				_ledakkan_ajian()
			if _waktu_state >= waktu_ancang_ajian + 0.3:
				_ganti_state(State.NORMAL)
		State.TERKENA:
			_rem(delta, 10.0)
			if _waktu_state >= lama_terhuyung:
				_ganti_state(State.NORMAL)
		State.MATI:
			_rem(delta, 8.0)

	_minta_serang = false
	_minta_hindar = false
	_minta_ajian = false
	move_and_slide()
	_animasi_langkah(delta)


## Dipanggil musuh/bos. `arah_dorong` adalah arah pemain terpental (tanpa komponen y).
func terima_serangan(jumlah: int, arah_dorong: Vector3, kekuatan_dorong: float = 6.0) -> void:
	if state == State.MATI or _sisa_kebal > 0.0 or not GameManager.sedang_bermain():
		return
	if not komponen_hp.kurangi(jumlah):
		return
	GameManager.damage_diterima += jumlah
	kombo = 0
	_sisa_kebal = waktu_kebal
	EfekVisual.kilat_kena(model)
	AudioManager.putar_sfx("kena")
	var dorong := arah_dorong
	dorong.y = 0.0
	velocity = dorong.normalized() * kekuatan_dorong + Vector3.UP * 2.5
	if state != State.MATI:
		_ganti_state(State.TERKENA)


func sedang_di_udara() -> bool:
	return not is_on_floor()


## Memulihkan HP (dipakai jamu). Mengembalikan true bila HP benar-benar bertambah.
func pulihkan(jumlah: int) -> bool:
	if state == State.MATI or komponen_hp.hp >= komponen_hp.hp_maks:
		return false
	komponen_hp.pulihkan(jumlah)
	return true


func tambah_kasekten(jumlah: float) -> void:
	var lama := kasekten
	kasekten = clampf(kasekten + jumlah, 0.0, kasekten_maks)
	if kasekten != lama:
		kasekten_berubah.emit(kasekten, kasekten_maks)


# ---------------------------------------------------------------- gerak

func _proses_gerak(delta: float, pengali: float) -> void:
	var masukan := Input.get_vector("kiri", "kanan", "maju", "mundur")
	var arah := Vector3(masukan.x, 0.0, masukan.y).rotated(Vector3.UP, kamera_rig.ambil_yaw())
	var laju := kecepatan_lari if Input.is_action_pressed("lari") else kecepatan
	var target := arah * laju * pengali
	velocity.x = move_toward(velocity.x, target.x, percepatan * delta)
	velocity.z = move_toward(velocity.z, target.z, percepatan * delta)
	if arah.length_squared() > 0.01 and state == State.NORMAL:
		_hadap_ke(arah, delta)


func _rem(delta: float, gesekan: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, gesekan * delta)
	velocity.z = move_toward(velocity.z, 0.0, gesekan * delta)


func _hadap_ke(arah: Vector3, delta: float) -> void:
	# Model menghadap -Z (konvensi Godot).
	var sudut := atan2(-arah.x, -arah.z)
	model.rotation.y = lerp_angle(model.rotation.y, sudut, clampf(kecepatan_putar * delta, 0.0, 1.0))


func _arah_hadap() -> Vector3:
	return -model.global_basis.z.normalized()


# ---------------------------------------------------------------- serangan

func _mulai_serang(langkah: int) -> void:
	_ganti_state(State.MENYERANG)
	kombo = langkah
	_kombo_antre = false
	_sudah_kena.clear()
	# Ayunkan ke arah gerak kamera bila pemain menekan arah, agar serangan terasa responsif.
	var masukan := Input.get_vector("kiri", "kanan", "maju", "mundur")
	if masukan.length_squared() > 0.01:
		var arah := Vector3(masukan.x, 0.0, masukan.y).rotated(Vector3.UP, kamera_rig.ambil_yaw())
		model.rotation.y = atan2(-arah.x, -arah.z)
	var maju := _arah_hadap() * langkah_maju_serangan * (1.4 if langkah == 3 else 1.0)
	velocity.x = maju.x
	velocity.z = maju.z
	if langkah == 3 and is_on_floor():
		velocity.y = 3.0  # lompatan kecil untuk pukulan penutup
	_animasi_ayunan(langkah)
	AudioManager.putar_sfx("ayun", null, 0.85 if langkah == 3 else 1.0)


func _periksa_hitbox() -> void:
	for tubuh: Node3D in hitbox.get_overlapping_bodies():
		if tubuh == self or tubuh in _sudah_kena:
			continue
		if tubuh.has_method("terima_serangan"):
			_sudah_kena.append(tubuh)
			var arah := tubuh.global_position - global_position
			arah.y = 0.0
			var penutup := kombo == 3
			var jumlah := int(damage * pengali_pukulan_3) if penutup else damage
			var dorong := dorongan_ke_musuh * (pengali_dorong_pukulan_3 if penutup else 1.0)
			tubuh.call("terima_serangan", jumlah, arah.normalized(), dorong)
			tambah_kasekten(kasekten_per_kena)
			if penutup:
				kamera_rig.guncang(0.08, 0.12)


# ---------------------------------------------------------------- menghindar & ajian

func _mulai_hindar() -> void:
	var masukan := Input.get_vector("kiri", "kanan", "maju", "mundur")
	if masukan.length_squared() > 0.01:
		_arah_hindar = Vector3(masukan.x, 0.0, masukan.y).rotated(Vector3.UP, kamera_rig.ambil_yaw()).normalized()
	else:
		_arah_hindar = -_arah_hadap()  # tanpa arah: melompat mundur
	kombo = 0
	_ganti_state(State.MENGHINDAR)
	_sisa_jeda_hindar = jeda_hindar
	_sisa_kebal = maxf(_sisa_kebal, durasi_hindar + 0.08)
	AudioManager.putar_sfx("hindar")
	# Badan merunduk sesaat.
	var t := create_tween()
	t.tween_property(model, "scale", Vector3(1.1, 0.8, 1.1), durasi_hindar * 0.4)
	t.tween_property(model, "scale", Vector3.ONE, durasi_hindar * 0.6)


func _mulai_ajian() -> void:
	kombo = 0
	_ganti_state(State.AJIAN)
	_ajian_meledak = false
	kasekten = 0.0
	kasekten_berubah.emit(kasekten, kasekten_maks)
	_sisa_kebal = maxf(_sisa_kebal, waktu_ancang_ajian + 0.35)
	AudioManager.putar_sfx("ajian")
	if _lengan_kanan:
		if _tween_lengan and _tween_lengan.is_valid():
			_tween_lengan.kill()
		_tween_lengan = create_tween()
		_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 3.1, waktu_ancang_ajian * 0.8)
		_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 0.8, 0.1)
		_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 0.0, 0.3)


func _ledakkan_ajian() -> void:
	_ajian_meledak = true
	GameManager.ajian_dipakai += 1
	ajian_dilepas.emit()
	var emas := Color(1.0, 0.82, 0.3, 0.85)
	EfekVisual.gelombang_debu(get_parent(), global_position, radius_ajian, emas)
	EfekVisual.gelombang_debu(get_parent(), global_position, radius_ajian * 0.6, Color(1.0, 0.95, 0.7, 0.9))
	kamera_rig.guncang(0.22, 0.35)
	AudioManager.putar_sfx("bos_hantam", null, 1.3)
	for m: Node in get_tree().get_nodes_in_group("musuh"):
		var musuh := m as Node3D
		if musuh == null or not musuh.has_method("terima_serangan"):
			continue
		var d := musuh.global_position - global_position
		d.y = 0.0
		if d.length() <= radius_ajian:
			musuh.call("terima_serangan", damage_ajian, d.normalized(), 12.0)


func _saat_mati() -> void:
	_ganti_state(State.MATI)
	# Ksatria rebah ke belakang.
	var t := create_tween()
	t.tween_property(model, "rotation:x", deg_to_rad(80.0), 0.6).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(model, "position:y", 0.35, 0.6)
	GameManager.lapor_pemain_kalah()


func _ganti_state(baru: State) -> void:
	state = baru
	_waktu_state = 0.0


# ---------------------------------------------------------------- animasi prosedural

func _animasi_ayunan(langkah: int = 1) -> void:
	if _lengan_kanan == null:
		return
	if _tween_lengan and _tween_lengan.is_valid():
		_tween_lengan.kill()
	_tween_lengan = create_tween()
	var ayun := akhir_hitbox - awal_hitbox
	var kembali := durasi_serangan - akhir_hitbox
	if langkah == 2:
		# Pukulan ke-2: sabetan mendatar dari kanan ke kiri.
		_lengan_kanan.rotation.x = 1.5
		_tween_lengan.tween_property(_lengan_kanan, "rotation:z", -1.3, awal_hitbox * 0.9)
		_tween_lengan.tween_property(_lengan_kanan, "rotation:z", 1.2, ayun).set_ease(Tween.EASE_IN)
		_tween_lengan.tween_property(_lengan_kanan, "rotation:z", 0.0, kembali)
		_tween_lengan.parallel().tween_property(_lengan_kanan, "rotation:x", 0.0, kembali)
		return
	# Pukulan ke-1 dan ke-3: angkat gada ke atas kepala lalu hantamkan ke depan.
	_lengan_kanan.rotation.z = 0.0
	var tinggi := 3.6 if langkah == 3 else 3.3
	_tween_lengan.tween_property(_lengan_kanan, "rotation:x", tinggi, awal_hitbox * 0.9)
	_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 0.8 if langkah == 3 else 1.0, ayun) \
			.set_ease(Tween.EASE_IN)
	_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 0.0, kembali)


func _animasi_langkah(delta: float) -> void:
	var laju_datar := Vector2(velocity.x, velocity.z).length()
	var bergerak := is_on_floor() and laju_datar > 0.3 and state != State.MATI
	if bergerak:
		var fase_lama := _fase_langkah
		_fase_langkah += delta * laju_datar * 2.2
		# Bunyi langkah setiap kali kaki menapak (sinus melewati nol).
		if floori(fase_lama / PI) != floori(_fase_langkah / PI):
			AudioManager.putar_sfx("langkah")
	else:
		_fase_langkah = lerpf(_fase_langkah, roundf(_fase_langkah / PI) * PI, 10.0 * delta)
	var ayun := sin(_fase_langkah) * clampf(laju_datar / kecepatan_lari, 0.0, 1.0) * 0.8
	if _kaki_kanan:
		_kaki_kanan.rotation.x = ayun
	if _kaki_kiri:
		_kaki_kiri.rotation.x = -ayun
	if _lengan_kiri:
		_lengan_kiri.rotation.x = ayun * 0.8
	if _lengan_kanan and state == State.NORMAL and not (_tween_lengan and _tween_lengan.is_running()):
		_lengan_kanan.rotation.x = -ayun * 0.6
		_lengan_kanan.rotation.z = 0.0
	# Di udara: kaki sedikit ditekuk.
	if not is_on_floor() and state != State.MATI:
		if _kaki_kanan:
			_kaki_kanan.rotation.x = 0.5
		if _kaki_kiri:
			_kaki_kiri.rotation.x = -0.2
