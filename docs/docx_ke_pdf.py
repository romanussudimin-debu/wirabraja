"""Mengubah GDD .docx menjadi .pdf lewat LibreOffice, setelah memperbarui daftar isi.

Pemakaian:  python docs/docx_ke_pdf.py docs/GDD_v2.0_Final.docx
(Butuh LibreOffice. Jalankan dengan python yang memiliki modul `uno`.)
"""
import subprocess
import sys
import time
from pathlib import Path

import uno
from com.sun.star.beans import PropertyValue


def prop(nama, nilai):
    p = PropertyValue()
    p.Name, p.Value = nama, nilai
    return p


def main(path_docx: str) -> None:
    sumber = Path(path_docx).resolve()
    proses = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore",
                               "--accept=socket,host=localhost,port=2002;urp;"])
    try:
        konteks = uno.getComponentContext()
        resolver = konteks.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", konteks)
        for _ in range(60):
            try:
                ctx = resolver.resolve("uno:socket,host=localhost,port=2002;urp;StarOffice.ComponentContext")
                break
            except Exception:
                time.sleep(0.5)
        desktop = ctx.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
        doc = desktop.loadComponentFromURL(sumber.as_uri(), "_blank", 0, (prop("Hidden", True),))
        indeks = doc.getDocumentIndexes()
        jumlah = indeks.getCount()
        for i in range(jumlah):
            indeks.getByIndex(i).update()
        tujuan = sumber.with_suffix(".pdf")
        doc.storeToURL(tujuan.as_uri(), (prop("FilterName", "writer_pdf_Export"),))
        doc.close(True)
        print("PDF disimpan:", tujuan, "| daftar isi diperbarui:", jumlah)
        try:
            desktop.terminate()
        except Exception:
            pass
    finally:
        time.sleep(1)
        proses.terminate()


if __name__ == "__main__":
    main(sys.argv[1])
