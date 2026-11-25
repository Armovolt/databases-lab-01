from io import BytesIO
import os
from pathlib import Path
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


def report_font():
    if "Library" in pdfmetrics.getRegisteredFontNames():
        return "Library"
    windows = Path(os.getenv("WINDIR", "C:/Windows"))
    candidates = (
        os.getenv("LAB04_PDF_FONT"),
        windows / "Fonts/arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    )
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            pdfmetrics.registerFont(TTFont("Library", str(candidate)))
            return "Library"
    raise RuntimeError("Задайте LAB04_PDF_FONT із шляхом до TTF-шрифту з підтримкою української.")


def catalog_pdf(books):
    buffer = BytesIO()
    font = report_font()
    doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=38, leftMargin=38,
                            topMargin=42, bottomMargin=42, title="Каталог електронної бібліотеки")
    title = ParagraphStyle("Title", fontName=font, fontSize=21, leading=28, textColor=colors.HexColor("#203c32"))
    text = ParagraphStyle("Text", fontName=font, fontSize=9, leading=13)
    rows = [["Назва", "Автори", "Рік", "Доступно"]]
    rows.extend([
        Paragraph(escape(book["title"]), text), Paragraph(escape(book["authors"]), text),
        str(book["published_year"]), str(book["available_copies"]),
    ] for book in books)
    table = Table(rows, colWidths=(206, 166, 55, 78), repeatRows=1)
    table.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (-1, -1), font),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#203c32")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.HexColor("#f1f5f1"), colors.white]),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    doc.build([
        Paragraph("Каталог електронної бібліотеки", title),
        Spacer(1, 10), Paragraph(f"Видань у звіті: {len(books)}", text), Spacer(1, 18), table,
    ])
    buffer.seek(0)
    return buffer
