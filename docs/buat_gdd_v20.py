"""Generator GDD Versi Final 2.0 (UTS) — format ringkas, hitam putih.

Cara pakai (dari folder proyek):
    pip install python-docx pillow
    python docs/buat_gdd_v20.py          -> docs/GDD_v2.0_Final.docx
    python docs/docx_ke_pdf.py docs/GDD_v2.0_Final.docx   (opsional, PDF)

Kelanjutan GDD v1.0 dan v1.1 (Tugas 2). Dokumen dibuat singkat, tanpa warna.
"""
from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor
from PIL import Image, ImageOps

FOLDER = Path(__file__).resolve().parent
HITAM = RGBColor(0, 0, 0)
FONT = "Times New Roman"


# ------------------------------------------------------------------ utilitas

def gaya(doc: Document) -> None:
    n = doc.styles["Normal"]
    n.font.name = FONT
    n.font.size = Pt(11)
    n.font.color.rgb = HITAM
    n.element.rPr.rFonts.set(qn("w:eastAsia"), FONT)
    n.paragraph_format.line_spacing = 1.15
    n.paragraph_format.space_after = Pt(4)
    for nama, ukuran in (("Heading 1", 13), ("Heading 2", 11)):
        h = doc.styles[nama]
        h.font.name = FONT
        h.font.size = Pt(ukuran)
        h.font.bold = True
        h.font.italic = False
        h.font.color.rgb = HITAM
        rf = h.element.rPr.rFonts
        rf.set(qn("w:eastAsia"), FONT)
        # Hapus font tema (Calibri Light) agar judul benar-benar memakai Times New Roman.
        for atr in ("w:asciiTheme", "w:hAnsiTheme", "w:eastAsiaTheme", "w:cstheme"):
            if rf.get(qn(atr)) is not None:
                del rf.attrib[qn(atr)]
        rf.set(qn("w:ascii"), FONT)
        rf.set(qn("w:hAnsi"), FONT)
        h.paragraph_format.space_before = Pt(10)
        h.paragraph_format.space_after = Pt(4)
        h.paragraph_format.keep_with_next = True
    for s in doc.sections:
        s.page_height, s.page_width = Cm(29.7), Cm(21.0)
        s.left_margin = s.right_margin = Cm(2.5)
        s.top_margin = s.bottom_margin = Cm(2.2)


def par(doc: Document, teks: str, tebal: bool = False, tengah: bool = False, ukuran: int | None = None):
    p = doc.add_paragraph()
    r = p.add_run(teks)
    r.bold = tebal
    r.font.color.rgb = HITAM
    if ukuran:
        r.font.size = Pt(ukuran)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER if tengah else WD_ALIGN_PARAGRAPH.JUSTIFY
    return p


def butir(doc: Document, teks: str, label: str | None = None) -> None:
    p = doc.add_paragraph(style="List Bullet")
    if label:
        r = p.add_run(label + " ")
        r.bold = True
    p.add_run(teks)
    p.paragraph_format.space_after = Pt(1)


def judul(doc: Document, teks: str, level: int = 1) -> None:
    doc.add_heading(teks, level=level)


def tabel(doc: Document, kepala: list[str] | None, baris: list[list[str]], lebar: list[float],
          ukuran: int = 10) -> None:
    t = doc.add_table(rows=1 if kepala else 0, cols=len(lebar))
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.autofit = False
    for i, k in enumerate(kepala or []):
        sel = t.rows[0].cells[i]
        sel.text = ""
        r = sel.paragraphs[0].add_run(k)
        r.bold = True
        r.font.size = Pt(ukuran)
    for b in baris:
        sel = t.add_row().cells
        for i, v in enumerate(b):
            sel[i].text = ""
            r = sel[i].paragraphs[0].add_run(v)
            r.font.size = Pt(ukuran)
            sel[i].paragraphs[0].paragraph_format.line_spacing = 1.0
            sel[i].paragraphs[0].paragraph_format.space_after = Pt(0)
    for i, w in enumerate(lebar):
        t.columns[i].width = Cm(w)
        for row in t.rows:
            row.cells[i].width = Cm(w)
    # Tabel tidak terpotong antarhalaman: setiap baris (kecuali terakhir) menempel ke baris berikutnya.
    for j, row in enumerate(t.rows):
        if j < len(t.rows) - 1:
            for sel_ in row.cells:
                for pr in sel_.paragraphs:
                    pr.paragraph_format.keep_with_next = True
    doc.add_paragraph().paragraph_format.space_after = Pt(0)


def kode(doc: Document, teks: str) -> None:
    p = doc.add_paragraph()
    baris = teks.strip("\n").split("\n")
    for i, b in enumerate(baris):
        r = p.add_run(b)
        r.font.name = "Courier New"
        r.element.rPr.rFonts.set(qn("w:eastAsia"), "Courier New")
        r.font.size = Pt(8)
        if i < len(baris) - 1:
            r.add_break()
    p.paragraph_format.line_spacing = 1.0
    p.paragraph_format.keep_together = True


def gambar_abu(doc: Document, nama: str, keterangan: str, lebar: float = 12.0) -> None:
    sumber = FOLDER / "gambar" / nama
    if not sumber.exists():
        return
    abu = FOLDER / "gambar" / ("abu_" + nama)
    ImageOps.grayscale(Image.open(sumber)).save(abu)
    doc.add_picture(str(abu), width=Cm(lebar))
    doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER
    p = par(doc, keterangan, tengah=True, ukuran=9)
    p.runs[0].italic = True
    abu.unlink()


def nomor_halaman(doc: Document) -> None:
    p = doc.sections[0].footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run()
    for tag, isi in (("begin", None), (None, "PAGE"), ("end", None)):
        if tag:
            e = OxmlElement("w:fldChar")
            e.set(qn("w:fldCharType"), tag)
        else:
            e = OxmlElement("w:instrText")
            e.set(qn("xml:space"), "preserve")
            e.text = isi
        r._r.append(e)
    r.font.size = Pt(9)


# ------------------------------------------------------------------ isi

def buat() -> Path:
    doc = Document()
    gaya(doc)
    nomor_halaman(doc)
    doc.core_properties.title = "GDD Wirabraja v2.0 Final"
    doc.core_properties.author = "I Gusti Agung Ayu Putu Wulan Aristina"

    par(doc, "GAME DESIGN DOCUMENT (GDD) — VERSI FINAL 2.0", tebal=True, tengah=True, ukuran=14)
    par(doc, "Wirabraja: Geger Alun-Alun Keraton", tebal=True, tengah=True, ukuran=13)
    tabel(doc, None, [
        ["Nama / NIM", "I Gusti Agung Ayu Putu Wulan Aristina / 240030296"],
        ["Program Studi", "Sistem Informasi, Institut Teknologi dan Bisnis STIKOM Bali"],
        ["Mata Kuliah", "Pengembangan Permainan Digital"],
        ["Tahun", "2026"],
    ], [4.0, 12.0])

    judul(doc, "Riwayat Versi")
    tabel(doc, ["Versi", "Perubahan"], [
        ["1.0", "Level 1 sederhana: ksatria (gerak, lari, lompat, serang, kamera orbit, HP), 1 jenis buta, "
                "1 bos dengan 1 pola serangan, menang/kalah + tombol R, HUD minimal."],
        ["1.1", "3 jenis buta baru, 3 gelombang musuh, bos 3 pola serangan + fase 2, audio gamelan, "
                "narasi pembuka gaya dalang."],
        ["2.0 (Final)", "Menu utama, menu jeda & pengaturan, kombo 3 pukulan, menghindar, Ajian Braja, "
                        "item jamu, layar hasil (statistik, peringkat, rekor), build Web & Windows."],
    ], [2.4, 13.6])

    judul(doc, "1. Identitas Game")
    tabel(doc, ["Aspek", "Keterangan"], [
        ["Judul", "Wirabraja: Geger Alun-Alun Keraton"],
        ["Genre", "Aksi 3D orang ketiga (third-person action)"],
        ["Platform", "PC Windows (.exe) dan browser (web)"],
        ["Engine / bahasa", "Godot Engine 4.7 (kompatibel 4.5+), GDScript"],
        ["Kontrol", "Keyboard + mouse"],
        ["Target pemain", "Remaja dan dewasa (13+), pelajar/mahasiswa"],
        ["Tema budaya", "Keraton Surakarta (Solo), wayang purwa, gamelan, jamu"],
        ["Durasi", "± 8–12 menit (1 level)"],
    ], [4.0, 12.0])

    judul(doc, "2. Konsep dan Cerita")
    par(doc, "Para buta (raksasa jahat dalam pewayangan) dari hutan Gandamayit menyerbu Alun-Alun Lor Keraton "
             "Kasunanan Surakarta. Pemain mengendalikan Raden Wirabraja, ksatria penjaga gerbang keraton "
             "(desain orisinal yang terinspirasi Gatotkaca). Pemain harus mengalahkan tiga gelombang buta, lalu "
             "melawan raksasa Ditya Kalamurka. Cerita dibuka dengan narasi gaya dalang (\"Hong wilaheng... "
             "Kacarita...\") dan ditutup dengan layar hasil berisi peringkat ksatria.")

    judul(doc, "3. Unsur Budaya Jawa")
    butir(doc, "alun-alun, sepasang beringin berpagar, pendopo joglo, dan gerbang keraton.", "Latar:")
    butir(doc, "ksatria melawan buta seperti adegan perang kembang dalam wayang kulit.", "Wayang:")
    butir(doc, "narasi dalang dengan kayon (gunungan), bunyi keprak, dan istilah Jawa (kacarita, mangkana, "
               "becik ketitik ala ketara).", "Pakeliran:")
    butir(doc, "musik bernuansa gamelan (saron, bonang, kenong, kempul, gong, kendang), laras slendro.", "Gamelan:")
    butir(doc, "item pemulih HP berupa jamu (kunyit asam, beras kencur, temulawak).", "Jamu:")
    butir(doc, "kasekten (kesaktian), ajian (jurus sakti), gelar Ksatria Utama/Madya/Muda.", "Istilah:")
    butir(doc, "warna sogan, emas, merah marun, dan hijau.", "Warna:")

    judul(doc, "4. Tokoh dan Musuh")
    tabel(doc, ["Tokoh", "Ciri / perilaku"], [
        ["Raden Wirabraja (pemain)", "HP 100, bersenjata gada; dapat kombo, menghindar, dan Ajian Braja."],
        ["Buta Prajurit", "HP 75; mendekat lalu memukul dengan gada kayu."],
        ["Buta Kilat", "HP 45; cepat, bergerak zig-zag, menerjang lurus."],
        ["Buta Gempal", "HP 220; lambat, tidak terhuyung saat dipukul, Injak Bumi (area 360°)."],
        ["Buta Pelempar", "HP 50; menjaga jarak dan melempar batu."],
        ["Buta Cilik", "HP 30; dipanggil bos."],
        ["Ditya Kalamurka (bos)", "HP 650; 3 pola serangan, menjadi murka (fase 2) saat HP < 50%."],
    ], [4.6, 11.4])

    judul(doc, "5. Kontrol")
    tabel(doc, ["Tombol", "Aksi"], [
        ["W A S D", "Bergerak"],
        ["Shift", "Berlari"],
        ["Spasi", "Melompat"],
        ["Klik kiri", "Serang (klik 3x = kombo)"],
        ["Klik kanan / Ctrl", "Menghindar"],
        ["Q", "Ajian Braja (saat bar kasekten penuh)"],
        ["Mouse", "Memutar kamera"],
        ["Esc / P", "Jeda"],
        ["M", "Musik hidup/mati"],
        ["R", "Ulangi setelah menang/kalah"],
    ], [4.6, 11.4])

    judul(doc, "6. Mekanik Permainan")
    butir(doc, "pemain dan musuh memiliki HP; pemain kebal sesaat setelah terkena serangan.", "HP:")
    butir(doc, "serangan gada (damage 25); klik lagi saat mengayun menyambung kombo, pukulan ke-3 ×1,8.", "Serangan & kombo:")
    butir(doc, "melesat cepat 0,22 detik dan kebal selama melesat.", "Menghindar:")
    butir(doc, "bar kasekten terisi setiap pukulan mengenai musuh; saat penuh, tombol Q melepas gelombang emas "
               "yang melukai semua musuh dalam radius 7 m (damage 70).", "Ajian Braja:")
    butir(doc, "buta berpeluang 30% menjatuhkan jamu; jamu memulihkan 25 HP.", "Jamu:")
    butir(doc, "state machine Diam → Mengejar → Ancang-ancang → Menyerang → Pulih. Ancang-ancang menjadi tanda "
               "bagi pemain untuk menghindar.", "AI buta:")
    butir(doc, "(1) Hantaman Bumi: lingkaran merah, lolos dengan keluar lingkaran atau melompat; (2) Serbuan "
               "Lurus: jalur merah, bos terhuyung bila menabrak tembok; (3) Panggil Bala: memanggil buta cilik.",
          "Pola bos:")
    butir(doc, "saat HP bos < 50%, bos lebih cepat, hantaman dua kali, dan memanggil lebih banyak buta.", "Fase murka:")
    butir(doc, "menang bila bos kalah, kalah bila HP pemain habis.", "Menang/kalah:")
    butir(doc, "menampilkan waktu, jumlah buta dikalahkan, damage diterima, peringkat (A Ksatria Utama, "
               "B Ksatria Madya, C Ksatria Muda), dan rekor waktu terbaik.", "Layar hasil:")

    judul(doc, "7. Desain Level 1: Alun-Alun Lor")
    kode(doc, """
                 UTARA
 +=============[ GERBANG ]=============+
 |        +--------------------+       |
 |        |   PENDOPO (joglo)  |       |
 |        +--------------------+       |
 |                 X  (bos muncul)     |
 |      [##] beringin   beringin [##]  |
 |                 .                   |
 |                 .  (jalan sumbu)    |
 |                 P  (pemain mulai)   |
 +=====================================+
                SELATAN    (arena 64 x 64 m)
""")
    tabel(doc, ["Tahap", "Isi"], [
        ["Gelombang 1", "3 Buta Prajurit + 1 Buta Kilat"],
        ["Gelombang 2", "2 Buta Kilat + 2 Buta Pelempar"],
        ["Gelombang 3", "2 Buta Gempal + 1 Buta Prajurit + 1 Buta Pelempar"],
        ["Bos", "Ditya Kalamurka (fase 1 lalu fase murka)"],
    ], [4.0, 12.0])
    gambar_abu(doc, "ss_hud_v2.png", "Gambar 1. Tampilan permainan (HP, bar kasekten, jamu)", 9.5)

    judul(doc, "8. Pengembangan dari Tugas 2 (Versi 2.0)")
    tabel(doc, ["Fitur baru", "Keterangan"], [
        ["Menu utama", "Mulai, Pengaturan, Kontrol, Keluar, dan rekor terbaik"],
        ["Menu jeda & pengaturan", "Volume musik/efek, sensitivitas mouse, layar penuh (tersimpan)"],
        ["Kombo 3 pukulan", "Pukulan ke-3 lebih kuat"],
        ["Menghindar", "Melesat singkat dan kebal sesaat"],
        ["Ajian Braja", "Jurus area yang terisi dari pukulan"],
        ["Jamu", "Item pemulih HP bernuansa budaya Jawa"],
        ["Layar hasil", "Statistik, peringkat, rekor waktu"],
        ["Build", "Windows (.exe) dan web (browser)"],
    ], [4.6, 11.4])

    judul(doc, "9. Aset dan Teknologi")
    butir(doc, "bentuk dasar Godot (kapsul, kotak, silinder, bola) sebagai placeholder.", "Model 3D:")
    butir(doc, "musik dan efek suara bernuansa gamelan yang disintesis sendiri (Python).", "Audio:")
    butir(doc, "Godot 4.7, GDScript; GDD dibuat dengan Python (python-docx).", "Teknologi:")
    butir(doc, "uji otomatis 74 pemeriksaan, semuanya lulus.", "Pengujian:")
    butir(doc, "https://github.com/romanussudimin-debu/wirabraja", "Source code:")
    butir(doc, "https://romanussudimin-debu.github.io/wirabraja/", "Main di web:")

    judul(doc, "10. Daftar Pustaka")
    for item in (
        "Brandon, J. R. (Ed.). (1970). On thrones of gold: Three Javanese shadow plays. Harvard University Press.",
        "Godot Engine. (2025). Godot Engine documentation (stable). https://docs.godotengine.org/en/stable/",
        "Keeler, W. (1987). Javanese shadow plays, Javanese selves. Princeton University Press.",
        "Lindsay, J. (1992). Javanese gamelan (2nd ed.). Oxford University Press.",
        "Ricklefs, M. C. (2008). A history of modern Indonesia since c. 1200 (4th ed.). Palgrave Macmillan.",
        "UNESCO. (2008). Wayang puppet theatre. https://ich.unesco.org/en/RL/wayang-puppet-theatre-00063",
    ):
        p = par(doc, item)
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.left_indent = Cm(1.0)
        p.paragraph_format.first_line_indent = Cm(-1.0)

    keluar = FOLDER / "GDD_v2.0_Final.docx"
    doc.save(keluar)
    return keluar


if __name__ == "__main__":
    print("GDD disimpan:", buat())
