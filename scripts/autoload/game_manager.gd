extends Node
## GameManager (autoload) — pengelola state permainan Level 1.
##
## Alur state:
##   BERTARUNG (melawan bala buta) -> BOS (Ditya Kalamurka muncul)
##   -> MENANG (bos kalah)   atau   -> KALAH (HP pemain habis, dari state mana pun)
## Pada state MENANG/KALAH, tombol R memuat ulang level.

enum State { BERTARUNG, BOS, MENANG, KALAH }

## Dipancarkan setiap kali state permainan berganti.
signal state_berubah(state_baru: State)
## Dipancarkan setiap kali jumlah buta yang tersisa berubah.
signal jumlah_musuh_berubah(sisa: int)
## Dipancarkan ketika bos sudah dimunculkan oleh level.
signal bos_muncul(bos: Node)

var state: State = State.BERTARUNG
var musuh_tersisa: int = 0

# Statistik satu permainan (v2.0), ditampilkan di layar hasil.
var waktu_main: float = 0.0
var buta_dikalahkan: int = 0
var damage_diterima: int = 0
var ajian_dipakai: int = 0
var jamu_diminum: int = 0


func _ready() -> void:
	# Tetap memproses input walau pohon scene dijeda.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Dipanggil oleh level saat dimulai (juga setelah dimuat ulang).
func mulai_level(jumlah_buta: int) -> void:
	musuh_tersisa = jumlah_buta
	waktu_main = 0.0
	buta_dikalahkan = 0
	damage_diterima = 0
	ajian_dipakai = 0
	jamu_diminum = 0
	_ganti_state(State.BERTARUNG)
	jumlah_musuh_berubah.emit(musuh_tersisa)
	# Kasus khusus: level tanpa buta langsung masuk ke pertarungan bos.
	if musuh_tersisa <= 0:
		_ganti_state(State.BOS)


## Dipanggil oleh setiap buta ketika HP-nya habis.
func lapor_buta_kalah() -> void:
	if state != State.BERTARUNG:
		return
	musuh_tersisa = maxi(musuh_tersisa - 1, 0)
	buta_dikalahkan += 1
	jumlah_musuh_berubah.emit(musuh_tersisa)
	if musuh_tersisa == 0:
		_ganti_state(State.BOS)


## Dipanggil oleh level setelah node bos ditambahkan ke scene.
func lapor_bos_muncul(bos: Node) -> void:
	bos_muncul.emit(bos)


func lapor_bos_kalah() -> void:
	if state == State.BOS:
		_ganti_state(State.MENANG)


func lapor_pemain_kalah() -> void:
	if state == State.BERTARUNG or state == State.BOS:
		_ganti_state(State.KALAH)


## True selama pertarungan masih berlangsung (belum menang/kalah).
func sedang_bermain() -> bool:
	return state == State.BERTARUNG or state == State.BOS


func _process(delta: float) -> void:
	if sedang_bermain() and not get_tree().paused:
		waktu_main += delta


## Peringkat ksatria berdasarkan waktu dan damage yang diterima.
## Mengembalikan [huruf, gelar].
func hitung_peringkat() -> Array:
	if waktu_main <= 420.0 and damage_diterima <= 150:
		return ["A", "Ksatria Utama"]
	if waktu_main <= 660.0 and damage_diterima <= 350:
		return ["B", "Ksatria Madya"]
	return ["C", "Ksatria Muda"]


func ulang_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ulang") and not sedang_bermain():
		ulang_level()


func _ganti_state(baru: State) -> void:
	state = baru
	state_berubah.emit(baru)
