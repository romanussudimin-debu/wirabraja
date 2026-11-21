"""Generator GDD Versi Final 2.0 "Wirabraja: Geger Alun-Alun Keraton" (UTS).

Cara pakai (dari folder proyek):
    pip install python-docx
    python docs/buat_gdd_v20.py        -> docs/GDD_v2.0_Final.docx

Kelanjutan dari GDD v1.0 dan v1.1 (Tugas 2). Bab yang tidak berubah sejak v1.1
dipakai ulang dari buat_gdd_v11.py; bagian yang berubah diberi tanda
[Diperbarui v2.0] dan bagian baru diberi tanda [Baru v2.0].
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import buat_gdd as g  # noqa: E402
import buat_gdd_v11 as v11  # noqa: E402
from docx import Document  # noqa: E402
from docx.enum.section import WD_SECTION  # noqa: E402
from docx.enum.table import WD_TABLE_ALIGNMENT  # noqa: E402
from docx.shared import Cm, Pt, RGBColor  # noqa: E402

VERSI = "2.0"
TANGGAL = "21 November 2026"
RIWAYAT = v11.RIWAYAT + [
    ("2.0 (Final)", TANGGAL,
     "Versi final UTS: menu utama, menu jeda dan pengaturan (volume, sensitivitas, layar penuh) yang "
     "tersimpan; kombo 3 pukulan; gerak menghindar; jurus Ajian Braja dengan bar kasekten; item jamu "
     "pemulih HP; layar hasil dengan statistik, peringkat, dan rekor; build Web (GitHub Pages, otomatis "
     "lewat GitHub Actions) dan Windows (.exe); perbaikan suara pada versi Web; uji otomatis 74 pemeriksaan.",
     g.PENULIS),
]

WARNA_BARU = RGBColor(0x1E, 0x6B, 0x2E)
WARNA_UBAH = RGBColor(0xB0, 0x5A, 0x00)
LINK_WEB = "https://romanussudimin-debu.github.io/wirabraja/"
LINK_REPO = "https://github.com/romanussudimin-debu/wirabraja"

# Penanda v1.1 tidak ditampilkan lagi di versi final (diganti penanda v2.0).
_isi_teks_asli = g._isi_teks


def _isi_teks_bersih(p, teks: str, **kw):
    teks = re.sub(r"\*\*\[v1\.1\]\*\* ?", "", teks)
    teks = re.sub(r"\[(Baru|Diperbarui) v1\.1\] ?", "", teks)
    return _isi_teks_asli(p, teks, **kw)


g._isi_teks = _isi_teks_bersih


def judul(doc: Document, teks: str, level: int = 1, tanda: str | None = None):
    h = doc.add_heading(teks, level=level)
    if tanda:
        r = h.add_run("  [Baru v2.0]" if tanda == "baru" else "  [Diperbarui v2.0]")
        r.font.size = Pt(10)
        r.italic = True
        r.font.color.rgb = WARNA_BARU if tanda == "baru" else WARNA_UBAH
    return h


# Bab v1.1 yang dipakai ulang tampil tanpa penanda v1.1.
v11.judul = lambda doc, teks, level=1, tanda=None: doc.add_heading(teks, level=level)

p, butir, tabel, gambar, blok_kode = g.paragraf, g.butir, g.tabel, g.gambar, g.blok_kode
berurut = v11.berurut


# =================================================================== halaman depan

def sampul(doc: Document) -> None:
    doc.add_paragraph()
    p(doc, "GAME DESIGN DOCUMENT", rata="center", tebal=True, ukuran=18)
    par = p(doc, g.JUDUL, rata="center", tebal=True, ukuran=24)
    par.runs[0].font.color.rgb = g.MARUN
    p(doc, "Game Aksi 3D Orang Ketiga Bertema Budaya Jawa Surakarta dan Pewayangan",
      rata="center", miring=True, ukuran=13)
    p(doc, "Versi Final 2.0 — Ujian Tengah Semester", rata="center", tebal=True, ukuran=13)
    gambar(doc, "ss_menu.png", "", lebar_cm=9.5)
    t = doc.add_table(rows=0, cols=3)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for label, nilai in (("Mata Kuliah", ""), ("Dosen Pengampu", ""), ("Disusun oleh", g.PENULIS),
                         ("NIM", g.NIM)):
        c = t.add_row().cells
        c[0].text, c[1].text, c[2].text = label, ":", nilai
        c[0].width, c[1].width, c[2].width = Cm(4.0), Cm(0.5), Cm(8.5)
        for sel in c:
            sel.paragraphs[0].paragraph_format.line_spacing = 1.15
    doc.add_paragraph()
    for baris in (g.PRODI.upper(), g.KAMPUS.upper(), g.TAHUN):
        p(doc, baris, rata="center", tebal=True, ukuran=13).paragraph_format.space_after = Pt(0)


def riwayat(doc: Document) -> None:
    p(doc, "RIWAYAT VERSI", rata="center", tebal=True, ukuran=14)
    tabel(doc, ["Versi", "Tanggal", "Perubahan", "Penulis"], [list(r) for r in RIWAYAT],
          lebar_cm=[1.6, 2.6, 7.8, 3.0], ukuran=9)
    p(doc, "PANDUAN PENANDA PERUBAHAN", rata="center", tebal=True, ukuran=12)
    par = p(doc, "Dokumen ini adalah kelanjutan GDD v1.1 (Tugas 2). Judul bagian bertanda ")
    r = par.add_run("[Baru v2.0]")
    r.italic, r.font.color.rgb = True, WARNA_BARU
    par.add_run(" adalah bagian baru, sedangkan ")
    r = par.add_run("[Diperbarui v2.0]")
    r.italic, r.font.color.rgb = True, WARNA_UBAH
    par.add_run(" menandai bagian yang diubah. Bagian tanpa tanda sama dengan v1.1.")
    tabel(doc, ["Bagian", "Status", "Ringkasan perubahan v1.1 → v2.0"], [
        ["1. Ringkasan Game", "Diperbarui/Baru", "Identitas, daftar fitur versi final (1.5)"],
        ["4. Gameplay, Kontrol & Antarmuka", "Diperbarui/Baru", "Kontrol baru, alur layar, menu utama, jeda, pengaturan"],
        ["6.9–6.14 Mekanik", "Baru", "Kombo, menghindar, Ajian Braja, jamu, statistik & peringkat, HUD"],
        ["7. Aset & Teknologi", "Diperbarui", "Aset & audio baru, build Web/Windows, GitHub Actions"],
        ["8. Pengujian", "Diperbarui", "74 pemeriksaan otomatis, uji audio Web, rencana uji main"],
        ["9. Penutup", "Diperbarui", "Pemenuhan ketentuan UTS, keterbatasan, pengembangan lanjut"],
        ["10. Daftar Pustaka", "Diperbarui", "Tambahan rujukan budaya jamu"],
    ], lebar_cm=[4.6, 3.0, 7.4], keterangan="Tabel 0.1 Ringkasan perubahan v1.1 → v2.0")
    g.pindah_halaman(doc)
    p(doc, "DAFTAR ISI", rata="center", tebal=True, ukuran=14)
    g.daftar_isi(doc)


# =================================================================== bab 1

def bab_ringkasan(doc: Document) -> None:
    judul(doc, "1. Ringkasan Game", tanda="ubah")
    judul(doc, "1.1 Identitas Game", 2, tanda="ubah")
    tabel(doc, ["Aspek", "Keterangan"], [
        ["Judul", g.JUDUL],
        ["Genre", "Aksi (_action_) 3D, pertarungan jarak dekat (_hack and slash_ ringan)"],
        ["Platform", f"PC Windows (.exe) dan **peramban web** ({LINK_WEB}); papan ketik + tetikus"],
        ["Kamera", "Orang ketiga (_third-person_), di belakang tokoh, dapat diputar dengan tetikus"],
        ["Mesin & bahasa", "Godot Engine 4.7 (kompatibel 4.5+), GDScript dengan _static typing_"],
        ["Target pemain", "Remaja dan dewasa (13+), pelajar/mahasiswa, pemain kasual yang tertarik budaya Jawa; "
                          "kekerasan fantasi tanpa darah"],
        ["Mode", "Pemain tunggal: menu utama → narasi dalang → Level 1 (3 gelombang + bos 2 fase) → layar hasil; "
                 "durasi 8–12 menit"],
        ["Audio", "Musik bernuansa gamelan (narasi, pertempuran, bos) dan 21 efek suara"],
        ["Nilai budaya", "Keraton Kasunanan Surakarta, ksatria & buta wayang purwa, janturan dalang & kayon, "
                         "gamelan, jamu, palet warna batik sogan"],
    ], lebar_cm=[3.5, 11.5], keterangan="Tabel 1.1 Identitas game")
    judul(doc, "1.2 Konsep Singkat", 2)
    p(doc, f"**{g.JUDUL}** adalah game aksi 3D orang ketiga. Pemain mengendalikan **Raden Wirabraja**, ksatria "
           "rekaan penjaga Keraton Kasunanan Surakarta, untuk menghalau tiga gelombang bala buta lalu mengalahkan "
           "raksasa **Ditya Kalamurka**. Cerita dibingkai sebagai sebuah lakon wayang: dibuka oleh dalang dan "
           "ditutup dengan peringkat ksatria.")
    judul(doc, "1.3 Nilai Budaya yang Diangkat", 2, tanda="ubah")
    for b in (
        "**Ruang keraton** — Alun-Alun Lor dengan ringin kurung, pendopo, dan gerbang pada sumbu utara–selatan.",
        "**Wayang purwa & pakeliran** — ksatria melawan buta (_perang kembang_), janturan dalang, kayon, keprak "
        "(Brandon, 1970; Keeler, 1987).",
        "**Gamelan** — bunyi saron, bonang, kenong, kempul, gong, dan kendang dalam laras slendro (Lindsay, 1992; "
        "Sumarsam, 1995).",
        "**[Baru v2.0] Jamu** — minuman jamu (kunyit asam, beras kencur, temulawak) menjadi item pemulih tenaga, "
        "mengangkat budaya sehat jamu yang diakui UNESCO sebagai Warisan Budaya Takbenda pada tahun 2023 "
        "(UNESCO, 2023).",
        "**[Baru v2.0] Kesaktian ksatria** — _kasekten_ (kesaktian) dan _ajian_ (ilmu kesaktian) yang lazim dalam "
        "cerita wayang diwujudkan sebagai bar kasekten dan jurus Ajian Braja.",
        "**[Baru v2.0] Gelar ksatria** — hasil permainan diberi gelar Ksatria Utama, Madya, atau Muda (istilah "
        "utama–madya–muda/nistha lazim dipakai untuk menyatakan tingkatan dalam bahasa Jawa).",
    ):
        butir(doc, b)
    judul(doc, "1.4 Pilar Desain", 2)
    for b in (
        "**Responsif:** kontrol langsung terasa; kombo dan menghindar memberi pilihan aksi.",
        "**Terbaca:** setiap serangan musuh diawali ancang-ancang yang terlihat dan terdengar.",
        "**Berakar budaya:** latar, tokoh, narasi, musik, item, dan istilah bersumber dari budaya Jawa.",
        "**Mudah dikembangkan:** nilai keseimbangan berupa @export; model dan audio placeholder mudah diganti.",
    ):
        butir(doc, b)
    judul(doc, "1.5 Fitur Versi Final (Pengembangan dari Tugas 2)", 2, tanda="baru")
    tabel(doc, ["Fitur baru v2.0", "Uraian singkat", "Alasan desain"], [
        ["Menu utama", "Kelir + kayon, Mulai Lakon, Pengaturan, Kontrol, Keluar, rekor terbaik",
         "Pintu masuk yang jelas dan bernuansa wayang"],
        ["Menu jeda", "Esc/P: Lanjutkan, Pengaturan, Ulangi Level, Menu Utama",
         "Pemain bisa berhenti kapan saja; wajib untuk versi web"],
        ["Pengaturan", "Volume musik, volume efek, sensitivitas tetikus, layar penuh; tersimpan",
         "Kenyamanan dan aksesibilitas"],
        ["Kombo 3 pukulan", "Klik saat mengayun menyambung pukulan; pukulan ke-3 ×1,8 damage",
         "Menambah kedalaman dan ritme serangan"],
        ["Menghindar", "Klik kanan/Ctrl: melesat 15 m/s selama 0,22 s dan kebal sesaat",
         "Alat bertahan aktif menghadapi bos dan Buta Kilat"],
        ["Ajian Braja", "Bar kasekten terisi dari pukulan; Q melepas gelombang emas radius 7 m",
         "Imbalan bagi permainan agresif; jalan keluar saat dikepung"],
        ["Jamu", "Dijatuhkan buta (30%); bos murka menjatuhkan 2; memulihkan 25 HP",
         "Pemulihan berbasis budaya; menyeimbangkan kesulitan"],
        ["Layar hasil", "Waktu, buta dikalahkan, damage, ajian, jamu, peringkat, rekor",
         "Umpan balik dan motivasi bermain ulang"],
        ["Build Web & Windows", "Main di peramban (GitHub Pages) dan file .exe",
         "Mudah dibagikan dan dinilai tanpa memasang Godot"],
    ], lebar_cm=[3.2, 6.6, 5.2], ukuran=9, keterangan="Tabel 1.2 Fitur baru versi final")


# =================================================================== bab 4

def bab_gameplay(doc: Document) -> None:
    judul(doc, "4. Gameplay, Kontrol, dan Antarmuka", tanda="ubah")
    judul(doc, "4.1 Alur Inti (Core Loop)", 2, tanda="ubah")
    berurut(doc, [
        "Membaca jenis buta dari warna dan ukurannya, lalu memilih cara menghadapinya.",
        "Menyerang dengan kombo gada; setiap pukulan yang mengenai mengisi bar kasekten.",
        "Menghindar dari ancang-ancang musuh; memungut jamu bila HP menipis.",
        "Saat kasekten penuh, melepas Ajian Braja untuk menghancurkan kepungan.",
        "Menuntaskan tiga gelombang, lalu mengalahkan Ditya Kalamurka dalam dua fase.",
        "Melihat peringkat ksatria dan berusaha memecahkan rekor waktu.",
    ])
    judul(doc, "4.2 Kontrol", 2, tanda="ubah")
    tabel(doc, ["Tombol", "Aksi"], [
        ["W / A / S / D (atau panah)", "Bergerak relatif terhadap arah kamera"],
        ["Shift kiri (tahan)", "Berlari"],
        ["Spasi", "Melompat (juga: lanjut narasi)"],
        ["Klik kiri", "Serangan gada; klik lagi saat mengayun = kombo (maks. 3)"],
        ["Klik kanan / Ctrl kiri", "**[Baru]** Menghindar"],
        ["Q", "**[Baru]** Ajian Braja (saat kasekten penuh)"],
        ["Gerakan tetikus", "Memutar kamera orbit"],
        ["Esc / P", "**[Baru]** Jeda (di narasi: Esc melewati narasi)"],
        ["Enter / Tab", "Lanjut / lewati narasi"],
        ["M", "Musik hidup/mati"],
        ["R", "Mengulang level setelah menang atau kalah"],
    ], lebar_cm=[5.0, 10.0], keterangan="Tabel 4.1 Pemetaan kontrol versi final")
    judul(doc, "4.3 Kamera", 2, tanda="ubah")
    p(doc, "Kamera orbit (yaw + SpringArm3D, pitch −65° sampai +25°, jarak 5,5 m). Pada v2.0 sensitivitas dapat "
           "diatur di menu Pengaturan, dan lonjakan gerak tetikus sesaat setelah kursor dikunci di peramban "
           "diabaikan agar kamera tidak tersentak.")
    judul(doc, "4.4 Alur Layar", 2, tanda="baru")
    blok_kode(doc, """
 [Menu Utama]  --Mulai Lakon-->  [Narasi Dalang]  --selesai / Esc-->  [Level 1]
 [Menu Utama]  --Pengaturan / Kontrol-->  panel di dalam menu utama
 [Level 1]     --Esc / P-->       [Menu Jeda]
 [Menu Jeda]   --Lanjutkan-->     [Level 1]
 [Menu Jeda]   --Ulangi Level-->  [Level 1] (dimuat ulang)
 [Menu Jeda]   --Menu Utama-->    [Menu Utama]
 [Level 1]     --bos kalah / HP habis-->  [Layar Hasil]
 [Layar Hasil] --Ulangi / R-->    [Level 1] (dimuat ulang)
 [Layar Hasil] --Menu Utama-->    [Menu Utama]
""", ukuran=7)
    judul(doc, "4.5 Menu Utama", 2, tanda="baru")
    p(doc, "Menu utama menampilkan kelir wayang dengan kayon yang bergoyang pelan, judul WIRABRAJA, tombol "
           "Mulai Lakon, Pengaturan, Kontrol, dan Keluar (tombol Keluar disembunyikan pada versi web), rekor "
           "waktu terbaik, serta identitas pembuat. Musik narasi sudah mengalun sejak menu dan berlanjut tanpa "
           "jeda ke narasi pembuka.")
    gambar(doc, "ss_menu.png", "Gambar 4.1 Menu utama versi final", 12.5)
    judul(doc, "4.6 Menu Jeda dan Pengaturan", 2, tanda="baru")
    p(doc, "Esc atau P menjeda permainan (seluruh scene berhenti, menu tetap aktif). Di peramban, tombol Esc "
           "lebih dulu dipakai browser untuk melepas kunci tetikus; karena itu permainan juga dijeda otomatis "
           "setiap kali kunci tetikus terlepas saat bertarung. Panel Pengaturan dipakai bersama oleh menu utama "
           "dan menu jeda. Nilainya langsung diterapkan ke bus audio dan disimpan di user://pengaturan.cfg oleh "
           "autoload **Pengaturan**.")
    gambar(doc, "ss_jeda.png", "Gambar 4.2 Menu jeda", 12)


# =================================================================== bab 6 (lanjutan)

def bab_mekanik(doc: Document) -> None:
    v11.bab_mekanik(doc)  # 6.1–6.8 sama dengan v1.1
    judul(doc, "6.9 Kombo Tiga Pukulan", 2, tanda="baru")
    p(doc, "Klik kiri yang ditekan setelah hitbox pukulan aktif disimpan sebagai antrean (_input buffer_). Saat "
           "ayunan selesai, pukulan berikutnya langsung dimulai. Pukulan ke-1 menghantam dari atas, pukulan ke-2 "
           "menyabet mendatar, dan pukulan ke-3 menghantam dengan lompatan kecil. Pukulan ke-3 memberi damage "
           "×1,8 (45), dorongan ×1,7, dan guncangan kamera kecil. Kombo terputus bila pemain terkena serangan, "
           "menghindar, atau melepas ajian.")
    judul(doc, "6.10 Menghindar", 2, tanda="baru")
    p(doc, "Klik kanan atau Ctrl kiri membuat pemain melesat 15 m/s selama 0,22 detik ke arah tombol gerak "
           "yang ditekan (atau mundur bila tidak ada arah), dengan kekebalan selama melesat dan jeda pemakaian "
           "0,7 detik. Menghindar dapat memotong ayunan gada sehingga pemain bisa bereaksi terhadap ancang-ancang "
           "musuh kapan saja.")
    judul(doc, "6.11 Ajian Braja dan Bar Kasekten", 2, tanda="baru")
    gambar(doc, "ss_ajian.png", "Gambar 6.2 Ajian Braja: gelombang emas di sekeliling Raden Wirabraja", 12.5)
    tabel(doc, ["Parameter", "Nilai", "Keterangan"], [
        ["kasekten_maks", "100", "Kapasitas bar kasekten"],
        ["kasekten_per_kena", "12", "Tambahan setiap pukulan gada yang mengenai (≈ 9 pukulan untuk penuh)"],
        ["waktu_ancang_ajian", "0,45 s", "Gada diangkat tinggi; pemain kebal selama ancang-ancang"],
        ["radius_ajian", "7 m", "Semua musuh dalam radius terkena, termasuk bos"],
        ["damage_ajian", "70", "Cukup untuk mengalahkan Prajurit, Kilat, Pelempar, Cilik sekaligus"],
    ], lebar_cm=[4.0, 2.0, 9.0], keterangan="Tabel 6.5 Parameter Ajian Braja")
    p(doc, "HUD menampilkan bar kasekten berwarna emas di bawah bar HP. Saat penuh, tulisan berubah menjadi "
           "\"Kasekten penuh! Tekan Q: Ajian Braja\". Pelepasan ajian diiringi gong, desir naik, dan denting saron.")
    judul(doc, "6.12 Jamu", 2, tanda="baru")
    p(doc, "Setiap buta misi berpeluang 30% menjatuhkan jamu saat kalah (buta cilik 12%). Ketika Ditya Kalamurka "
           "memasuki fase murka, dua jamu jatuh di dekat pemain sebagai bekal. Jamu melayang dan berputar di atas "
           "cincin emas, dapat diambil dengan menyentuhnya, memulihkan 25 HP, dan lenyap setelah 20 detik "
           "(berkedip pada 3 detik terakhir). Jamu tidak terambil bila HP penuh sehingga tidak terbuang. Nama jamu "
           "dipilih acak dari kunyit asam, beras kencur, dan temulawak, lalu ditampilkan di layar.")
    judul(doc, "6.13 Statistik, Peringkat, dan Rekor", 2, tanda="baru")
    tabel(doc, ["Peringkat", "Syarat", "Makna"], [
        ["A — Ksatria Utama", "Waktu ≤ 7 menit dan damage diterima ≤ 150", "Ksatria tingkat tertinggi"],
        ["B — Ksatria Madya", "Waktu ≤ 11 menit dan damage diterima ≤ 350", "Ksatria tingkat menengah"],
        ["C — Ksatria Muda", "Selain itu", "Ksatria yang masih harus berlatih"],
    ], lebar_cm=[4.2, 6.4, 4.4], keterangan="Tabel 6.6 Aturan peringkat ksatria")
    p(doc, "GameManager mencatat waktu bermain (berhenti saat jeda), jumlah buta dikalahkan, damage yang diterima, "
           "jumlah ajian, dan jamu yang diminum. Waktu kemenangan tercepat disimpan sebagai rekor dan ditampilkan "
           "di menu utama. Layar hasil menyediakan tombol Ulangi dan Menu Utama.")
    gambar(doc, "ss_hasil.png", "Gambar 6.3 Layar hasil: peringkat, statistik, dan rekor baru", 12.5)
    judul(doc, "6.14 HUD Versi Final", 2, tanda="baru")
    p(doc, "Kiri atas: nama, bar HP, bar kasekten. Kanan atas: gelombang dan buta tersisa. Tengah atas: bar HP bos "
           "(merah saat murka). Tengah: pengumuman (gelombang, pola bos, jamu, ajian). Kanan tengah: tulisan "
           "\"Kombo x2/x3!\". Bawah: petunjuk kontrol.")
    gambar(doc, "ss_hud_v2.png", "Gambar 6.4 HUD versi final (bar kasekten penuh, jamu di dekat pemain)", 12.5)


# =================================================================== bab 7–10

def bab_aset(doc: Document) -> None:
    judul(doc, "7. Aset dan Teknologi", tanda="ubah")
    judul(doc, "7.1 Teknologi", 2, tanda="ubah")
    tabel(doc, ["Komponen", "Pilihan"], [
        ["Mesin game", "Godot Engine 4.7.2 (proyek kompatibel 4.5+); Forward+ di desktop, Compatibility di web"],
        ["Bahasa", "GDScript dengan static typing; pewarisan kelas untuk varian buta"],
        ["Autoload", "GameManager (state & statistik), AudioManager (audio), **Pengaturan** (pengaturan & rekor)"],
        ["Fisika", "CharacterBody3D, Area3D (hitbox, batu, jamu), StaticBody3D (arena)"],
        ["Audio", "Ogg Vorbis (musik), WAV (efek); bus Musik & SFX di default_bus_layout.tres"],
        ["Build", "Web (HTML5, tanpa thread) dan Windows x86_64 (.exe)"],
        ["Otomasi", f"GitHub Actions: uji otomatis → ekspor Web → GitHub Pages ({LINK_WEB})"],
        ["Kode sumber", LINK_REPO],
    ], lebar_cm=[3.5, 11.5], keterangan="Tabel 7.1 Teknologi yang digunakan")
    judul(doc, "7.2 Struktur Proyek", 2, tanda="ubah")
    blok_kode(doc, """
wirabraja/
  project.godot  export_presets.cfg  default_bus_layout.tres
  .github/workflows/web.yml   build & pasang versi web otomatis
  scenes/player|enemies|boss|level|items|ui/
      ui: menu_utama, narasi_pembuka, hud, menu_jeda      items: jamu
  scripts/autoload/    game_manager.gd, audio_manager.gd, pengaturan.gd
  scripts/player/      player.gd (kombo, hindar, ajian), kamera_orbit.gd
  scripts/enemies/     buta.gd + buta_kilat/gempal/pelempar.gd, batu_lempar.gd
  scripts/items/       jamu.gd
  scripts/ui/          menu_utama, menu_jeda, panel_pengaturan, tema_jawa,
                       hud, narasi_pembuka, kayon
  audio/musik/ (3 .ogg)   audio/sfx/ (21 .wav)
  docs/                GDD v1.0, v1.1, v2.0 Final + generatornya, gambar/
  tests/               uji_alur (74 pemeriksaan), tangkap_layar
  tools/               buat_scene_karakter.py, buat_audio.py
""", ukuran=7)
    judul(doc, "7.3 Aset Visual Baru", 2, tanda="baru")
    tabel(doc, ["Aset", "Bentuk", "Keterangan"], [
        ["Botol jamu", "CylinderMesh kuning kunyit transparan + tutup sogan + TorusMesh emas", "Item pemulih"],
        ["Gelombang Ajian Braja", "Dua TorusMesh emas yang membesar dan memudar", "Efek jurus"],
        ["Menu utama & jeda", "Panel kelir, kayon (_draw), tema tombol sogan-emas-marun (TemaJawa)", "Antarmuka"],
        ["Bar kasekten, tulisan kombo, layar hasil", "ProgressBar + Label bergaya emas", "HUD"],
    ], lebar_cm=[4.2, 7.6, 3.2], keterangan="Tabel 7.2 Aset visual baru v2.0 (semua buatan sendiri)")
    judul(doc, "7.4 Audio", 2, tanda="ubah")
    p(doc, "Seluruh audio adalah placeholder sintetis buatan sendiri (tools/buat_audio.py). Versi final menambah "
           "4 efek: hindar (desir cepat), ajian_braja (desir naik + gong + saron), jamu (dua denting saron naik), "
           "dan klik (ketukan bonang untuk tombol menu), sehingga total menjadi 3 musik dan 21 efek. Daftar "
           "lengkapnya ada di audio/README.md.")
    p(doc, "**Perbaikan penting:** pada versi web, Godot memutar suara dalam mode _sample_. Bus audio yang dibuat "
           "saat runtime tidak tersambung ke speaker sehingga seluruh suara senyap. Bus Musik dan SFX kini "
           "didefinisikan di default_bus_layout.tres, dan perbaikannya diverifikasi dengan mengukur sinyal yang "
           "keluar dari peramban.")
    judul(doc, "7.5 Build dan Distribusi", 2, tanda="baru")
    tabel(doc, ["Target", "Cara mendapatkan", "Catatan"], [
        ["Web (HTML5)", LINK_WEB, "Chrome/Edge/Firefox di laptop; ±40 MB saat pertama dimuat; klik layar untuk "
                                  "mengaktifkan suara dan mengunci tetikus"],
        ["Windows", "Wirabraja.exe (folder Build_Game pengumpulan)", "Satu file, tanpa instalasi; bila muncul "
                                                                    "peringatan SmartScreen pilih More info → Run anyway"],
        ["Source code", LINK_REPO, "Buka project.godot di Godot 4.5+ lalu tekan F5"],
    ], lebar_cm=[2.6, 6.2, 6.2], ukuran=9, keterangan="Tabel 7.3 Build dan distribusi")


def bab_pengujian(doc: Document) -> None:
    judul(doc, "8. Pengujian", tanda="ubah")
    judul(doc, "8.1 Uji Otomatis", 2, tanda="ubah")
    p(doc, "Uji otomatis (tests/uji_alur.tscn) dijalankan headless di komputer pengembang dan di GitHub Actions "
           "sebelum setiap ekspor web. Hasil versi final: **74 pemeriksaan lulus, 0 gagal**.")
    tabel(doc, ["Kelompok", "Jumlah", "Contoh pemeriksaan"], [
        ["Menu utama & pengaturan", "4", "Tombol menu, Mulai Lakon, volume diterapkan, pengaturan tersimpan"],
        ["Narasi & audio", "7", "Lanjut/lewati narasi, 24 file audio, tata bus default"],
        ["Kombo", "3", "Kombo tersambung, pukulan ke-3 lebih kuat, kasekten terisi"],
        ["Menghindar & Ajian", "7", "Melesat & kebal, ajian butuh kasekten penuh, radius 7 m"],
        ["Jamu", "4", "Tidak terambil saat HP penuh, +25 HP, statistik, dijatuhkan buta"],
        ["Varian buta", "9", "Zig-zag & terjangan, super armor & injak bumi, lempar batu"],
        ["Level, jeda, gelombang", "13", "Gerak, lompat, serang, jeda/lanjut, gelombang 2 & 3"],
        ["Bos & hasil", "23", "3 pola, fase murka, MENANG, peringkat, statistik, rekor"],
        ["Kondisi kalah", "4", "Reset level, KALAH, teks dan petunjuk R"],
    ], lebar_cm=[4.2, 1.6, 9.2], ukuran=9, keterangan="Tabel 8.1 Ringkasan uji otomatis versi final")
    judul(doc, "8.2 Uji Versi Web", 2, tanda="baru")
    p(doc, "Build web diuji pada Chromium: narasi tampil, Esc melewati narasi, level termuat dengan HUD, dan sinyal "
           "audio terukur keluar (musik narasi, keprak, musik pertempuran, ayunan gada) setelah klik pertama.")
    judul(doc, "8.3 Rencana Uji Main (Playtest)", 2, tanda="baru")
    tabel(doc, ["Aspek", "Pertanyaan untuk penguji", "Indikator berhasil"], [
        ["Kontrol", "Apakah gerak, kombo, dan menghindar terasa responsif?", "≥ 4 dari 5 (skala Likert)"],
        ["Keterbacaan", "Apakah ancang-ancang musuh dan bos mudah dikenali?", "Penguji dapat menghindar setelah 1–2 percobaan"],
        ["Kesulitan", "Apakah bos terlalu mudah atau sulit?", "Menang dalam ≤ 3 percobaan"],
        ["Budaya", "Unsur budaya apa yang Anda ingat setelah bermain?", "Menyebut ≥ 3 unsur (dalang, gamelan, jamu, keraton…)"],
        ["Audio-visual", "Apakah musik dan warna terasa bernuansa Jawa?", "≥ 4 dari 5"],
    ], lebar_cm=[2.6, 7.0, 5.4], ukuran=9, keterangan="Tabel 8.2 Kuesioner singkat uji main")


def bab_penutup(doc: Document) -> None:
    judul(doc, "9. Penutup", tanda="ubah")
    judul(doc, "9.1 Pemenuhan Ketentuan UTS", 2, tanda="baru")
    tabel(doc, ["Ketentuan", "Pemenuhan"], [
        ["GDD versi final (kelanjutan Tugas 2)", "Dokumen ini (v2.0), lanjutan v1.0 & v1.1 dengan riwayat versi dan penanda perubahan"],
        ["Prototipe dengan pengembangan/tambahan dari Tugas 2", "9 fitur baru (Tabel 1.2): menu, jeda, pengaturan, kombo, menghindar, Ajian Braja, jamu, layar hasil, build Web & Windows"],
        ["Presentasi & rekaman GDD + demo game", "Slide presentasi dan naskah rekaman disertakan di folder pengumpulan"],
        ["Pengumpulan: GDD, build, source code, video", "Folder pengumpulan berisi GDD (.docx/.pdf), build (.exe + web), source code (.zip), folder video"],
    ], lebar_cm=[5.5, 9.5], keterangan="Tabel 9.1 Pemenuhan ketentuan UTS")
    judul(doc, "9.2 Keterbatasan", 2, tanda="baru")
    for b in (
        "Model 3D masih placeholder dari bentuk dasar Godot dengan animasi prosedural.",
        "Audio adalah sintesis bernuansa gamelan, bukan rekaman gamelan asli.",
        "Baru tersedia satu level; keseimbangan belum disetel dari uji main dengan banyak pemain.",
        "Versi web membutuhkan papan ketik dan tetikus (belum mendukung layar sentuh).",
    ):
        butir(doc, b)
    judul(doc, "9.3 Pengembangan Lanjut", 2, tanda="ubah")
    for b in (
        "Model 3D bergaya wayang dengan animasi rangka dan rekaman gamelan asli berlisensi jelas.",
        "Level 2 (Alun-Alun Kidul) dan Level 3 (Sitihinggil) dengan lakon lanjutan serta bos baru.",
        "Kontrol layar sentuh dan gamepad.",
        "Penyetelan kesulitan berdasarkan hasil uji main (Tabel 8.2).",
    ):
        butir(doc, b)


def bab_pustaka(doc: Document) -> None:
    judul(doc, "10. Daftar Pustaka", tanda="ubah")
    pustaka = [
        "Anderson, B. R. O'G. (1965). _Mythology and the tolerance of the Javanese_. Modern Indonesia "
        "Project, Cornell University.",
        "Brandon, J. R. (Ed.). (1970). _On thrones of gold: Three Javanese shadow plays_. Harvard University Press.",
        "Godot Engine. (2025). _Godot Engine documentation_ (stable). https://docs.godotengine.org/en/stable/",
        "Keeler, W. (1987). _Javanese shadow plays, Javanese selves_. Princeton University Press.",
        "Lindsay, J. (1992). _Javanese gamelan_ (2nd ed.). Oxford University Press.",
        "Nystrom, R. (2014). _Game programming patterns_. Genever Benning.",
        "Ricklefs, M. C. (2008). _A history of modern Indonesia since c. 1200_ (4th ed.). Palgrave Macmillan.",
        "Schell, J. (2019). _The art of game design: A book of lenses_ (3rd ed.). CRC Press.",
        "Sumarsam. (1995). _Gamelan: Cultural interaction and musical development in Central Java_. "
        "University of Chicago Press.",
        "UNESCO. (2008). _Wayang puppet theatre_. Intangible Cultural Heritage. "
        "https://ich.unesco.org/en/RL/wayang-puppet-theatre-00063",
        "UNESCO. (2023). _Jamu wellness culture_ [Elemen Daftar Representatif Warisan Budaya Takbenda]. "
        "Intangible Cultural Heritage. https://ich.unesco.org/en/lists",
    ]
    for item in pustaka:
        par = p(doc, item, rata="left")
        par.paragraph_format.left_indent = Cm(1.25)
        par.paragraph_format.first_line_indent = Cm(-1.25)
        par.paragraph_format.line_spacing = 1.15


def buat() -> Path:
    doc = Document()
    g.atur_gaya(doc)
    doc.core_properties.title = f"GDD {g.JUDUL} v{VERSI} Final"
    doc.core_properties.author = g.PENULIS
    sampul(doc)
    sec = doc.add_section(WD_SECTION.NEW_PAGE)
    sec.footer.is_linked_to_previous = False
    g.nomor_halaman(sec)
    riwayat(doc)
    g.pindah_halaman(doc)
    for bab in (bab_ringkasan, v11.bab_cerita, v11.bab_tokoh, bab_gameplay, v11.bab_level, bab_mekanik,
                bab_aset, bab_pengujian, bab_penutup, bab_pustaka):
        bab(doc)
    keluar = g.FOLDER_DOCS / f"GDD_v{VERSI}_Final.docx"
    doc.save(keluar)
    return keluar


if __name__ == "__main__":
    print("GDD disimpan:", buat())
