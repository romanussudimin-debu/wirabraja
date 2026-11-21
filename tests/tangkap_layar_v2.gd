extends Node
## Tangkapan layar fitur v2.0 untuk dokumentasi (butuh tampilan/GPU):
##   godot --path . res://tests/tangkap_layar_v2.tscn -- <folder_keluaran>

const LEVEL := preload("res://scenes/level/level_1.tscn")
const MENU := preload("res://scenes/ui/menu_utama.tscn")
const JAMU := preload("res://scenes/items/jamu.tscn")

var _keluar: String = "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_keluar = args[0] if args.size() > 0 else "user://"
	var m := MENU.instantiate()
	m.pindah_otomatis = false
	add_child(m)
	await _tunggu(1.0)
	await _simpan("ss_menu.png")
	m.queue_free()
	await _tunggu(0.2)

	var level := LEVEL.instantiate()
	add_child(level)
	await _tunggu(1.2)
	var pemain := get_tree().get_first_node_in_group("pemain") as Pemain
	pemain.komponen_hp.inisialisasi(99999)
	pemain.global_position = Vector3(16, 0, 20)
	pemain.tambah_kasekten(999.0)
	var j := JAMU.instantiate() as Node3D
	level.add_child(j)
	j.global_position = Vector3(17.5, 0, 16.5)
	await _tunggu(1.0)
	await _simpan("ss_hud_v2.png")
	pemain._minta_ajian = true
	await _tunggu(pemain.waktu_ancang_ajian + 0.2)
	await _simpan("ss_ajian.png")
	await _tunggu(1.0)
	var jeda := level.get_node("MenuJeda") as MenuJeda
	jeda.jeda()
	await _tunggu(0.3)
	await _simpan("ss_jeda.png")
	jeda.lanjutkan()
	# Lompat ke akhir: kalahkan semua musuh dan bos.
	GameManager.musuh_tersisa = 1
	GameManager.lapor_buta_kalah()
	await _tunggu(4.0)
	var bos := get_tree().get_first_node_in_group("bos") as BosRaksasa
	GameManager.waktu_main = 372.0
	GameManager.damage_diterima = 120
	GameManager.buta_dikalahkan = 12
	bos.terima_serangan(99999, Vector3.FORWARD)
	await _tunggu(1.6)
	await _simpan("ss_hasil.png")
	AudioManager.hentikan_semua()
	await _tunggu(0.2)
	get_tree().quit()


func _tunggu(d: float) -> void:
	await get_tree().create_timer(d, true).timeout


func _simpan(nama: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_keluar + "/" + nama)
	print("disimpan: ", nama)
