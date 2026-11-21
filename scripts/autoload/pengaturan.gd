extends Node
## Pengaturan (autoload) — menyimpan & menerapkan pengaturan pemain serta rekor.
## Disimpan di user://pengaturan.cfg sehingga tetap ada saat game dibuka lagi.

signal berubah

const PATH := "user://pengaturan.cfg"

var volume_musik: float = 0.8      # 0..1
var volume_sfx: float = 0.9        # 0..1
var sensitivitas_mouse: float = 1.0  # pengali, 0.3..2.5
var layar_penuh: bool = false
var rekor_waktu: float = 0.0       # detik; 0 = belum ada rekor
var rekor_peringkat: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	muat()
	terapkan()


func muat() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	volume_musik = cfg.get_value("audio", "musik", volume_musik)
	volume_sfx = cfg.get_value("audio", "sfx", volume_sfx)
	sensitivitas_mouse = cfg.get_value("kontrol", "sensitivitas", sensitivitas_mouse)
	layar_penuh = cfg.get_value("tampilan", "layar_penuh", layar_penuh)
	rekor_waktu = cfg.get_value("rekor", "waktu", rekor_waktu)
	rekor_peringkat = cfg.get_value("rekor", "peringkat", rekor_peringkat)


func simpan() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "musik", volume_musik)
	cfg.set_value("audio", "sfx", volume_sfx)
	cfg.set_value("kontrol", "sensitivitas", sensitivitas_mouse)
	cfg.set_value("tampilan", "layar_penuh", layar_penuh)
	cfg.set_value("rekor", "waktu", rekor_waktu)
	cfg.set_value("rekor", "peringkat", rekor_peringkat)
	cfg.save(PATH)


func terapkan() -> void:
	_atur_bus("Musik", volume_musik)
	_atur_bus("SFX", volume_sfx)
	if DisplayServer.get_name() != "headless" and OS.get_name() != "Web":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if layar_penuh else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	berubah.emit()


func ubah(kunci: String, nilai: Variant) -> void:
	set(kunci, nilai)
	terapkan()
	simpan()


## Mencatat hasil kemenangan; mengembalikan true bila memecahkan rekor waktu.
func catat_kemenangan(waktu: float, peringkat: String) -> bool:
	if rekor_waktu <= 0.0 or waktu < rekor_waktu:
		rekor_waktu = waktu
		rekor_peringkat = peringkat
		simpan()
		return true
	return false


func _atur_bus(nama: String, nilai: float) -> void:
	var i := AudioServer.get_bus_index(nama)
	if i == -1:
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(nilai, 0.0001)))
	AudioServer.set_bus_mute(i, nilai <= 0.001)


## Format waktu mm:ss.
static func format_waktu(detik: float) -> String:
	var t := int(roundf(detik))
	return "%02d:%02d" % [t / 60, t % 60]
