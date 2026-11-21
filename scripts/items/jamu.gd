class_name Jamu
extends Area3D
## Jamu — minuman jamu tradisional Jawa yang memulihkan HP pemain (v2.0).
## Dijatuhkan buta saat kalah (peluang tertentu). Botol melayang-berputar dan
## lenyap sendiri setelah beberapa saat bila tidak diambil.

const JENIS: PackedStringArray = ["Jamu kunyit asam", "Jamu beras kencur", "Jamu temulawak"]

@export var pemulihan: int = 25
@export var umur: float = 20.0

@onready var _visual: Node3D = $Visual

var nama_jamu: String = ""
var _waktu: float = 0.0
var _diambil: bool = false


func _ready() -> void:
	add_to_group("jamu")
	nama_jamu = JENIS[randi() % JENIS.size()]
	body_entered.connect(_saat_disentuh)
	_visual.scale = Vector3.ONE * 0.01
	create_tween().tween_property(_visual, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	_waktu += delta
	_visual.position.y = 0.6 + sin(_waktu * 3.0) * 0.12
	_visual.rotation.y += delta * 2.0
	# Berkedip menjelang lenyap.
	if _waktu > umur - 3.0:
		_visual.visible = fmod(_waktu, 0.3) < 0.18
	if _waktu > umur and not _diambil:
		queue_free()


func _saat_disentuh(tubuh: Node3D) -> void:
	if _diambil or not (tubuh is Pemain):
		return
	var pemain := tubuh as Pemain
	if not pemain.pulihkan(pemulihan):
		return  # HP penuh: jamu dibiarkan untuk nanti
	_diambil = true
	GameManager.jamu_diminum += 1
	AudioManager.putar_sfx("jamu")
	get_tree().call_group("hud", "tampilkan_pengumuman", "%s: HP +%d" % [nama_jamu, pemulihan], 1.5)
	set_deferred("monitoring", false)
	var t := create_tween()
	t.tween_property(_visual, "position:y", 2.0, 0.3)
	t.parallel().tween_property(_visual, "scale", Vector3.ONE * 0.01, 0.3)
	t.tween_callback(queue_free)


## Pemain yang sudah berdiri di atas jamu saat HP-nya berkurang tetap bisa mengambilnya.
func _physics_process(_delta: float) -> void:
	if _diambil or not monitoring:
		return
	for b: Node3D in get_overlapping_bodies():
		_saat_disentuh(b)
