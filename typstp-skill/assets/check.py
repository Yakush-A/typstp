#!/usr/bin/env python3
"""Проверка документа на typo-stp (СТП 01-2024) с учётом типа документа.

Использование:
  check.py --type diploma|course|lab|other [--strict] main.typ [package-path]
           [--font-path DIR ...] [--pdf OUT.pdf] [--words FILE] [--no-spell]

Типы документов:
  diploma  дипломный проект/работа: все проверки, включая объёмы (раздел 1 СТП)
  course   курсовой проект/работа
  lab      отчёт по лабораторной работе
  other    типовой расчёт, реферат, эссе и т. п.
Проверки раздела 1 СТП (введение, заключение, число страниц, Wikipedia)
выполняются ТОЛЬКО для diploma. Остальные (раздел 2: шрифты, поля, подписи,
ссылки, стиль текста, источники, орфография) выполняются для любого типа.

Выход: 1 при ошибке компиляции; с --strict ещё и при любом WARN. Иначе 0.
Строки NOTE информационные и на код выхода не влияют.

Зависимости: typst; для PDF-проверок pdftotext/pdffonts/pdfinfo (poppler).
Необязательные: fonttools (прокси-шрифт Times New Roman из Liberation Serif),
hunspell + словарь ru_RU (орфография; иначе aspell или pyspellchecker),
PyYAML (проверка sources.yml).
"""
import argparse
import glob
import html
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter

MM = 72 / 25.4  # pt в одном мм
A4 = (595.28, 841.89)
# Допуски на поля (мм): bbox глифа немного выступает за поле.
TOL = {"left": 28.5, "right": 13.0, "top": 18.0, "bottom": 18.0}
TEXT_H = 257.0  # высота текстового поля A4 в мм (297 - 20 - 20)


class Report:
    def __init__(self):
        self.warns = 0

    def section(self, title):
        print(f"\n== {title} ==")

    def ok(self, msg):
        print(f"OK: {msg}")

    def note(self, msg):
        print(f"NOTE: {msg}")

    def warn(self, msg):
        self.warns += 1
        print(f"WARN: {msg}")


R = Report()


def run(cmd, **kw):
    env = dict(os.environ, LANG="C.UTF-8", LC_ALL="C.UTF-8")
    return subprocess.run(cmd, capture_output=True, text=True, env=env, **kw)


def have(tool):
    return shutil.which(tool) is not None


# --------------------------------------------------------------------------
# Шрифты
# --------------------------------------------------------------------------
FONT_DIRS = [
    "/usr/share/fonts", "/usr/local/share/fonts", os.path.expanduser("~/.fonts"),
    os.path.expanduser("~/.local/share/fonts"), "/Library/Fonts",
    "/System/Library/Fonts", "C:/Windows/Fonts",
]


def typst_fonts(base, font_paths):
    cmd = ["typst", "fonts"] + sum([["--font-path", p] for p in font_paths], [])
    r = run(cmd)
    return {ln.strip().lower() for ln in r.stdout.splitlines() if ln.strip()}


def build_proxy_fonts(font_paths, tmp):
    """Метрически совместимый Liberation Serif/Mono, переименованный в
    Times New Roman/Courier New, только для проверки вёрстки."""
    try:
        from fontTools.ttLib import TTFont
    except Exception:
        return None, "не установлен fonttools (pip install fonttools)"
    dirs = list(font_paths) + FONT_DIRS
    found = {}
    for d in dirs:
        for pat in ("LiberationSerif-*.ttf", "LiberationMono-*.ttf"):
            for p in glob.glob(os.path.join(d, "**", pat), recursive=True):
                found.setdefault(os.path.basename(p), p)
    if not any(n.startswith("LiberationSerif-") for n in found):
        return None, "не найден Liberation Serif (fonts-liberation2)"
    out = os.path.join(tmp, "proxyfonts")
    os.makedirs(out, exist_ok=True)
    fam = {"LiberationSerif": "Times New Roman", "LiberationMono": "Courier New"}
    styles = {"Regular": "Regular", "Bold": "Bold", "Italic": "Italic", "BoldItalic": "Bold Italic"}
    for name, path in found.items():
        stem = name[:-4]
        base, _, st = stem.partition("-")
        if base not in fam or st not in styles:
            continue
        f = TTFont(path)
        for rec in f["name"].names:
            if rec.nameID in (1, 16):
                rec.string = fam[base]
            elif rec.nameID in (2, 17):
                rec.string = styles[st]
            elif rec.nameID == 4:
                rec.string = fam[base] + ("" if st == "Regular" else " " + styles[st])
            elif rec.nameID == 6:
                rec.string = fam[base].replace(" ", "") + "-" + styles[st].replace(" ", "")
        f.save(os.path.join(out, "proxy-" + name))
    return out, None


def check_fonts_before(font_paths, tmp):
    """Возвращает (font_args, reliable, proxy)."""
    R.section("шрифты")
    have_fonts = typst_fonts("", font_paths)
    tnr = "times new roman" in have_fonts
    cour = "courier new" in have_fonts
    termes = "tex gyre termes math" in have_fonts
    args = sum([["--font-path", p] for p in font_paths], [])
    if tnr:
        R.ok("Times New Roman установлен: вёрстка и число страниц достоверны")
        reliable, proxy = True, False
    else:
        out, why = build_proxy_fonts(font_paths, tmp)
        if out:
            args += ["--font-path", out]
            R.note("Times New Roman не установлен; для проверки вёрстки использована временная копия "
                   "метрически совместимого Liberation Serif (переименована в Times New Roman). "
                   "Число страниц, переносы и поля достоверны. ИТОГОВЫЙ PDF для сдачи соберите с "
                   "настоящим Times New Roman.")
            reliable, proxy = True, True
        else:
            R.warn(f"Times New Roman не найден и прокси-шрифт недоступен ({why}). Typst подставит другой "
                   "шрифт: число страниц, переносы и заполнение страниц НЕДОСТОВЕРНЫ. Положите шрифты "
                   "в --font-path.")
            reliable, proxy = False, False
    if not cour and not proxy:
        R.note("Courier New не найден: листинги будут набраны другим шрифтом (на остальную вёрстку не влияет)")
    if not termes:
        R.note("TeX Gyre Termes Math не найден: формулы набраны запасным математическим шрифтом "
               "(внешний вид формул отличается, страницы почти не меняются)")
    return args, reliable, proxy, termes


def check_fonts_after(pdf, termes):
    if not have("pdffonts"):
        return
    r = run(["pdffonts", pdf])
    names = []
    for ln in r.stdout.splitlines()[2:]:
        if ln.strip():
            nm = ln.split()[0]
            names.append(re.sub(r"^[A-Z]{6}\+", "", nm))
    if not names:
        return
    expected = re.compile(r"TimesNewRoman|TeXGyreTermes|Termes|CourierNew|NewCM|CMMath|LiberationSerif", re.I)
    math_fallback = re.compile(r"Libertinus|NewCM", re.I)
    odd = sorted({n for n in names if not expected.search(n) and not (not termes and math_fallback.search(n))})
    fam = sorted({re.split(r"[-,]", n)[0] for n in names})
    print(f"шрифты в PDF: {', '.join(fam)}")
    if odd:
        R.warn("в PDF есть посторонние шрифты (не Times New Roman / Courier New / математический): "
               + ", ".join(odd) + ". Обычно это запасной шрифт для символа, которого нет в основном.")
    if not termes and any(math_fallback.search(n) for n in names):
        R.note("в формулах использован запасной шрифт (кириллица в индексах формул берётся из Libertinus): "
               "с TeX Gyre Termes Math этого не будет")


# --------------------------------------------------------------------------
# Typst: компиляция и запросы
# --------------------------------------------------------------------------
def typst_args(pkg, font_args):
    a = []
    if pkg:
        a += ["--package-path", pkg]
    return a + font_args


def compile_doc(inp, pdf, targs):
    R.section("компиляция")
    r = run(["typst", "compile"] + targs + [inp, pdf])
    if r.returncode != 0:
        sys.stderr.write(r.stderr)
        print("FAIL: компиляция не удалась", file=sys.stderr)
        sys.exit(1)
    R.ok(f"{inp} собран")
    err = r.stderr
    unknown = sorted(set(re.findall(r"unknown font family: ([^\n]+)", err)))
    other = [ln for ln in err.splitlines() if ln.startswith("warning:") and "unknown font family" not in ln]
    if unknown:
        print(f"предупреждения Typst: неизвестные шрифты: {', '.join(unknown)}")
    for ln in other[:10]:
        R.warn("Typst: " + ln[len("warning: "):])


def query(inp, sel, targs):
    r = run(["typst", "query"] + targs + [inp, sel])
    if r.returncode != 0:
        R.warn(f"typst query «{sel}» не выполнился: {r.stderr.strip().splitlines()[-1] if r.stderr.strip() else '?'}")
        return None
    try:
        return json.loads(r.stdout)
    except Exception:
        R.warn(f"typst query «{sel}» вернул не JSON")
        return None


def text_of(node):
    if node is None:
        return ""
    if isinstance(node, str):
        return node
    if isinstance(node, list):
        return "".join(text_of(x) for x in node)
    if isinstance(node, dict):
        f = node.get("func")
        if f == "text":
            return node.get("text", "")
        if f in ("space", "linebreak"):
            return " "
        return "".join(text_of(v) for v in node.values() if isinstance(v, (dict, list)))
    return ""


def check_structure(inp, targs, dtype):
    R.section("структура")
    figures = query(inp, "figure", targs) or []
    refs = query(inp, "ref", targs) or []
    cites = query(inp, "cite", targs) or []
    outlines = query(inp, "outline", targs) or []
    headings = query(inp, "heading", targs) or []

    targets = {r.get("target") for r in refs if r.get("target")}
    counts = Counter()
    for f in figures:
        counts[f.get("kind") or "other"] += 1
    print(f"рисунков: {counts['image']}, таблиц: {counts['table']}, приложений: {counts['appendix']}")

    if not outlines:
        if dtype == "diploma":
            R.warn("нет #outline(): СТП 2.2.7 (содержание) для дипломного проекта обязательно")
        elif dtype in ("course", "other"):
            R.note("нет #outline(): для курсовой/другого документа проверьте требования кафедры")
        # lab: содержание может отсутствовать, молчим

    for f in figures:
        kind = f.get("kind")
        if kind not in ("image", "table", "appendix"):
            continue
        label = f.get("label")
        cap = f.get("caption")
        name = text_of(cap.get("body")).strip() if cap else ""
        shown = label or (f"«{name}»" if name else "<без метки>")
        if kind in ("image", "table") and not cap:
            R.warn(f"{kind} {shown}: нет подписи (СТП 2.5.5 / 2.6.2)")
        if not label:
            R.warn(f"{kind} {shown}: нет метки, на него нельзя сослаться из текста (СТП 2.5.6 / 2.6.1 / 2.7.2)")
        elif label not in targets:
            R.warn(f"{kind} {label}: нет ссылки из текста (СТП 2.5.6 / 2.6.1 / 2.7.2)")

    for h in headings:
        if h.get("level") == 4:
            body = text_of(h.get("body")).strip()
            if body:
                R.warn(f"заголовок 4-го уровня: шаблон отбрасывает текст «{body}»")
    cited = set()
    for r in refs:
        if r.get("target"):
            cited.add(str(r["target"]).strip("<>"))
    for c in cites:
        if c.get("key"):
            cited.add(str(c["key"]))
    print(f"ссылок в тексте (@ и #cite): {len(refs) + len(cites)}")
    return cited


# --------------------------------------------------------------------------
# PDF: геометрия, строки
# --------------------------------------------------------------------------
def load_lines(pdf, tmp):
    if not have("pdftotext"):
        return None
    out = os.path.join(tmp, "bbox.html")
    r = run(["pdftotext", "-bbox-layout", pdf, out])
    if r.returncode != 0 or not os.path.exists(out):
        return None
    txt = open(out, encoding="utf-8").read()
    pages = []
    for pg in re.split(r"<page ", txt)[1:]:
        m = re.match(r'width="([\d.]+)" height="([\d.]+)"', pg)
        W, H = float(m[1]), float(m[2])
        lines = []
        for lm in re.finditer(r'<line xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</line>', pg, re.S):
            words = [html.unescape(w) for w in re.findall(r"<word[^>]*>(.*?)</word>", lm[5], re.S)]
            lines.append({"x0": float(lm[1]), "y0": float(lm[2]), "x1": float(lm[3]), "y1": float(lm[4]),
                          "text": " ".join(words)})
        pages.append({"W": W, "H": H, "lines": lines})
    return pages


def is_page_number(ln, H):
    return re.fullmatch(r"\d{1,3}", ln["text"]) and ln["y1"] > H - 20 * MM


def check_geometry(pages, reliable):
    R.section("страницы и поля (СТП 2.1.1: левое 30, правое 15, верх 20, низ 20 мм)")
    if not pages:
        R.note("нет pdftotext: геометрия не проверена")
        return set()
    sizes = Counter((round(p["W"]), round(p["H"])) for p in pages)
    bad_size = [s for s in sizes if abs(s[0] - A4[0]) > 2 or abs(s[1] - A4[1]) > 2]
    if bad_size:
        R.warn("размер страниц не A4 (210×297): " + ", ".join(f"{s[0]/MM:.0f}×{s[1]/MM:.0f} мм" for s in bad_size))
    bad = []
    numbered = 0
    mins = {"left": 999, "right": 999, "top": 999, "bottom": 999}
    for n, p in enumerate(pages, 1):
        body = [ln for ln in p["lines"] if not is_page_number(ln, p["H"])]
        numbered += len(body) != len(p["lines"])
        if not body:
            continue
        m = {
            "left": min(l["x0"] for l in body) / MM,
            "right": (p["W"] - max(l["x1"] for l in body)) / MM,
            "top": min(l["y0"] for l in body) / MM,
            "bottom": (p["H"] - max(l["y1"] for l in body)) / MM,
        }
        for k in m:
            mins[k] = min(mins[k], m[k])
        viol = [k for k in m if m[k] < TOL[k]]
        if viol:
            bad.append((n, m, viol))
    names = {"left": "левое", "right": "правое", "top": "верхнее", "bottom": "нижнее"}
    flagged = {n for n, _, _ in bad}
    for n, m, viol in bad[:12]:
        txt = ", ".join(f"{names[k]} {m[k]:.1f} мм" for k in viol)
        R.warn(f"стр. {n}: текст заходит в поля: {txt}")
    if len(bad) > 12:
        R.warn(f"…и ещё {len(bad) - 12} стр. с нарушением полей")
    if not bad:
        R.ok("текст везде в пределах полей (допуск ±1,5 мм на выступ глифов)")
    print("самые узкие поля по документу (минимум среди страниц): левое {left:.1f}, правое {right:.1f}, верх {top:.1f}, "
          "низ (без номера) {bottom:.1f} мм".format(**mins))
    if numbered == 0 and len(pages) > 1:
        R.warn("номера страниц не найдены (СТП 2.2.8: внизу страницы справа)")
    return flagged


def check_ink_margins(pdf, tmp, flagged_pages):
    """Поля по закрашенным пикселям: ловит рисунки, фигуры и линии таблиц за полями."""
    if not have("pdftoppm"):
        R.note("нет pdftoppm: графика за полями не проверена")
        return
    try:
        from PIL import Image
    except Exception:
        R.note("нет Pillow: графика за полями не проверена (pip install pillow)")
        return
    prefix = os.path.join(tmp, "pg")
    dpi = 72
    r = run(["pdftoppm", "-r", str(dpi), "-gray", "-png", pdf, prefix])
    if r.returncode != 0:
        return
    px_mm = dpi / 25.4
    bad = []
    for path in sorted(glob.glob(prefix + "-*.png")):
        n = int(re.search(r"-(\d+)\.png$", path)[1])
        if n in flagged_pages:
            continue
        im = Image.open(path).convert("L")
        W, H = im.size
        mask = im.point(lambda v: 255 if v < 235 else 0)
        # область без нижней полосы 20 мм (там допустим только номер страницы)
        body_h = int(H - 20 * px_mm)
        body = mask.crop((0, 0, W, body_h))
        bb = body.getbbox()
        probs = []
        if bb:
            m = {"left": bb[0] / px_mm, "right": (W - bb[2]) / px_mm, "top": bb[1] / px_mm}
            for k, v in m.items():
                if v < TOL[k]:
                    probs.append(f"{ {'left': 'левое', 'right': 'правое', 'top': 'верхнее'}[k] } {v:.1f} мм")
        band = mask.crop((0, body_h, W, H)).getbbox()
        if band and (band[2] - band[0]) / px_mm > 15:
            probs.append("графика заходит в нижнее поле")
        if probs:
            bad.append((n, probs))
    for n, probs in bad[:12]:
        R.warn(f"стр. {n}: рисунок/фигура/линия заходит в поля: " + ", ".join(probs))
    if not bad:
        R.ok("графика (рисунки, линии таблиц) везде в пределах полей")


def join_lines(lines):
    """Склеить строки в текст, снимая переносы."""
    out = []
    for ln in lines:
        t = ln["text"]
        if out and out[-1].endswith("\u00ad"):
            out[-1] = out[-1][:-1] + t
        elif out and re.search(r"[А-Яа-яЁё]-$", out[-1]) and t[:1].islower():
            out[-1] = out[-1] + t
        else:
            out.append(t)
    return "\n".join(out).replace("\u00ad", "")


HEAD_RE = re.compile(r"^(?:\d+\s+[А-ЯЁ][А-ЯЁ0-9 ,.\-–«»()/]+|ВВЕДЕНИЕ|ЗАКЛЮЧЕНИЕ|СПИСОК ИСПОЛЬЗОВАННЫХ ИСТОЧНИКОВ|ПРИЛОЖЕНИЕ\b.*)$")


def flat_lines(pages):
    seq = []
    for n, p in enumerate(pages, 1):
        for ln in p["lines"]:
            if is_page_number(ln, p["H"]):
                continue
            seq.append(dict(ln, page=n, H=p["H"]))
    return seq


def section_extent(seq, title):
    """Длина раздела в «страницах» по занятой высоте. None, если не найден."""
    idx = [i for i, l in enumerate(seq) if l["text"].strip() == title]
    if not idx:
        return None
    s = idx[-1]  # последний: пропускаем строку в содержании
    e = len(seq)
    for j in range(s + 1, len(seq)):
        if HEAD_RE.match(seq[j]["text"].strip()):
            e = j
            break
    block = seq[s:e]
    per = {}
    for l in block:
        a = per.setdefault(l["page"], [l["y0"], l["y1"]])
        a[0] = min(a[0], l["y0"])
        a[1] = max(a[1], l["y1"])
    return sum((b - a) / MM for a, b in per.values()) / TEXT_H, len(per)


def check_diploma_volumes(pages, reliable):
    R.section("объёмы дипломного проекта (раздел 1 СТП, только для diploma)")
    if not pages:
        return
    suffix = "" if reliable else " (ненадёжно: нет Times New Roman)"
    seq = flat_lines(pages)
    first_app = next((l["page"] for l in seq if re.match(r"^ПРИЛОЖЕНИЕ\s+[А-Я]\b", l["text"].strip())
                      and l["page"] > 3), None)
    body_pages = (first_app - 1) if first_app else len(pages)
    print(f"страниц всего: {len(pages)}; до приложений: {body_pages}")
    if not 60 <= body_pages <= 80:
        R.warn(f"объём ПЗ без приложений {body_pages} стр., ориентир СТП 1.2.4: 60–80 стр.{suffix}")
    for title, lo, hi, nm, pt in (("ВВЕДЕНИЕ", 0.0, 2.0, "введение", "1.2.11"),
                                  ("ЗАКЛЮЧЕНИЕ", 1.4, 2.1, "заключение", "1.2.15")):
        res = section_extent(seq, title)
        if res is None:
            R.warn(f"раздел «{title}» не найден в PDF (СТП 1.2.5)")
            continue
        ext, npg = res
        print(f"{nm}: ≈{ext:.1f} стр. на {npg} стр.")
        if ext > hi:
            R.warn(f"{nm} ≈{ext:.1f} стр.: больше {hi:g} стр. (СТП {pt}){suffix}")
        elif ext < lo:
            R.warn(f"{nm} ≈{ext:.1f} стр.: меньше {lo:g} стр. (СТП {pt}, ориентир 1,5–2){suffix}")


# --------------------------------------------------------------------------
# Lint текста PDF
# --------------------------------------------------------------------------
LINT = [
    (r"(?i)\b(мы\s+получили|мы\s+нашли|мы\s+определили|будем\s+иметь|получится|выразится)\b",
     "оборот запрещён в выводах из формул, пишите «получаем», «находим» (СТП 2.4.1)", False),
    (r"(?i)\b(рисунк\w*|таблиц\w*|приложени\w*)\s+(Рисунок|Таблица|Приложение)\s+\S",
     "дубль слова при ссылке («на рисунке Рисунок 1.1»): используйте @метка[] (writing-style.md §7)", False),
    (r"\b(?:по|в|из|для)\s+\(\d+(?:\.\d+)?\)",
     "ссылка на формулу без слова: «по формуле (3.1)» (СТП 2.4.7)", False),
    (r"(?<!\.)\.\.(?!\.)", "двойная точка", False),
    (r",,", "двойная запятая", False),
    (r"\b(?:мощностью|напряжением|током|массой|длиной|частотой|мощность)\s+в\s+\d",
     "лишний предлог перед значением («мощностью 600 Вт», а не «в 600 Вт»; СТП 2.3.12)", False),
    (r"\bп\.\s?\d+(?:\.\d+)*",
     "ссылка на пункт: слово «пункт» пишут без сокращения (СТП 2.3.10)", False),
    (r"(?i)википеди|wikipedia", "Wikipedia и подобные вики запрещены (СТП 1.2.16)", True),
]


def lint_text(pages, dtype):
    R.section("стиль текста (lint по PDF)")
    if not pages:
        R.note("нет pdftotext: lint текста пропущен")
        return None
    full = join_lines([ln for p in pages for ln in p["lines"] if not is_page_number(ln, p["H"])])
    # Исключаем список источников и приложения-оглавление: правила про текст ПЗ.
    cut = None
    for m in re.finditer(r"^СПИСОК ИСПОЛЬЗОВАННЫХ ИСТОЧНИКОВ$", full, re.M):
        cut = m.start()
    body = full[:cut] if cut else full
    flat = re.sub(r"\s+", " ", body)
    found = 0
    for rx, msg, diploma_only in LINT:
        if diploma_only and dtype != "diploma":
            continue
        hits = [m for m in re.finditer(rx, flat)]
        if not hits:
            continue
        found += 1
        ctx = "; ".join("…" + flat[max(0, m.start() - 25):m.end() + 25].strip() + "…" for m in hits[:3])
        R.warn(f"{msg} — {len(hits)} раз: {ctx}")
    if not found:
        R.ok("запрещённых оборотов не найдено")
    return full


# --------------------------------------------------------------------------
# Lint исходников и источников
# --------------------------------------------------------------------------
SRC_LINT = [
    (r"#pagebreak\b|pagebreak\(", "ручной разрыв страницы: шаблон управляет разрывами сам"),
    (r"#set\s+page\b", "#set page: поля и размер заданы шаблоном"),
    (r"#set\s+par\b", "#set par: абзац и интервал заданы шаблоном"),
    (r"#set\s+text\s*\(\s*(?:[^)]*\b)?(?:font|size)\s*:", "#set text(font/size): шрифт и кегль заданы шаблоном"),
    (r"#upper\s*\(|\bupper\(", "ручное upper(): прописные в заголовках делает шаблон"),
    (r"(?<![@\w.])\b(?:Рисунок|Таблица)\s+\d+(?:\.\d+)?\b(?!\s*[–-])",
     "номер рисунка/таблицы написан вручную: используйте @метка[] (нумерацию ведёт шаблон)"),
]


def collect_sources(main):
    seen, order, stack = set(), [], [os.path.abspath(main)]
    while stack:
        p = stack.pop()
        if p in seen or not os.path.exists(p):
            continue
        seen.add(p)
        order.append(p)
        txt = open(p, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r'#?include\s*\(?\s*"([^"]+\.typ)"', txt):
            stack.append(os.path.normpath(os.path.join(os.path.dirname(p), m[1])))
    return order


def lint_sources(main):
    R.section("исходники .typ")
    files = collect_sources(main)
    bib_path = None
    keys = []
    for p in files:
        rel = os.path.relpath(p)
        raw = open(p, encoding="utf-8", errors="replace").read()
        code_free = "\n".join(ln for ln in raw.splitlines() if not ln.strip().startswith("//"))
        for rx, msg in SRC_LINT:
            hits = re.findall(rx, code_free)
            if hits:
                R.warn(f"{rel}: {msg} ({len(hits)} раз)")
        m = re.search(r'bibliography\(\s*"([^"]+)"', raw)
        if m:
            bib_path = os.path.normpath(os.path.join(os.path.dirname(p), m[1]))
            if bib_path.lower().endswith(".bib"):
                R.warn(f"{rel}: источники в .bib: часть случаев (4+ авторов, коллективный автор, «В 2 т.», газета) "
                       "через него не работает; используйте Hayagriva (.yml)")
        text_lines = [ln for ln in code_free.splitlines() if ln.strip() and not ln.lstrip().startswith("#")]
        manual = re.findall(r"(?<![@\w(])\[\d{1,3}\](?![(\[])", "\n".join(text_lines))
        if manual:
            R.warn(f"{rel}: ссылки на источники набраны вручную ({len(manual)} раз): используйте @ключ")
    return files, bib_path


def lint_yaml_entries(bib_path, dtype):
    """Статические проверки записей; возвращает data или None."""
    R.section("источники (Hayagriva)")
    if not bib_path or not os.path.exists(bib_path):
        R.note("файл источников не найден по #bibliography(...)")
        return None
    if bib_path.lower().endswith(".bib"):
        R.note(".bib: проверки записей пропущены (см. предупреждение выше)")
        return None
    try:
        import yaml
    except Exception:
        R.note("нет PyYAML: записи источников не проверены (pip install pyyaml)")
        return None
    try:
        data = yaml.safe_load(open(bib_path, encoding="utf-8")) or {}
    except Exception as e:
        R.warn(f"{os.path.basename(bib_path)}: YAML не читается: {e}")
        return None
    cities = {"москва": "М.", "санкт-петербург": "СПб.", "спб": "СПб.", "минск.": "Минск", "мн.": "Минск", "мн": "Минск"}
    n = 0
    for key, e in data.items():
        if not isinstance(e, dict):
            continue
        n += 1
        pre = f"{key}:"
        title = e.get("title")
        tstr = title.get("value", "") if isinstance(title, dict) else (title or "")
        if not tstr:
            R.warn(f"{pre} нет title")
        auth = e.get("author")
        alist = auth if isinstance(auth, list) else ([auth] if auth else [])
        if len(alist) > 3:
            R.warn(f"{pre} {len(alist)} авторов в author: при 4 и более используйте affiliated/collaborator "
                   "(иначе появится заголовок записи, СТП 2.8.6)")
        for a in alist:
            if isinstance(a, str) and "," not in a:
                R.warn(f"{pre} автор «{a}» без запятой: ожидается «Фамилия, Имя»; без инициалов или "
                       "организация: через collaborator")
        genre = e.get("genre")
        if genre and str(genre).strip().lower() == str(tstr).strip().lower():
            R.warn(f"{pre} genre дублирует title («Заглавие : Заглавие»)")
        url = e.get("url")
        if url:
            u = url.get("value") if isinstance(url, dict) else url
            if not re.match(r"https?://", str(u)):
                R.warn(f"{pre} url не абсолютный: «{u}» (нужен http:// или https://)")
        pt = e.get("page-total")
        if pt is not None and not isinstance(pt, int):
            R.warn(f"{pre} page-total должен быть числом; текст («1 компакт-диск») пишите в note")
        if "[Электронный ресурс]" in str(tstr) and e.get("type") in ("web", "repository"):
            R.warn(f"{pre} «[Электронный ресурс]» в title лишняя: для type {e.get('type')} стиль ставит её сам")
        pub = e.get("publisher")
        loc = pub.get("location") if isinstance(pub, dict) else None
        if loc and str(loc).strip().lower() in cities:
            R.warn(f"{pre} место издания «{loc}»: пишите «{cities[str(loc).strip().lower()]}» (СТП 2.8.6, примечание 5)")
        for fld in ("volumes", "subtitle", "short-title", "pagetotal", "journaltitle"):
            if fld in e:
                R.warn(f"{pre} поле «{fld}» относится к BibLaTeX и в Hayagriva не работает")
        if re.search(r"(?i)википеди|wikipedia", str(e)):
            if dtype == "diploma":
                R.warn(f"{pre} Wikipedia и подобные вики запрещены (СТП 1.2.16)")
            else:
                R.note(f"{pre} Wikipedia: в дипломе запрещена (СТП 1.2.16); для вашего документа уточните у руководителя")
    print(f"записей в {os.path.basename(bib_path)}: {n}")
    return data


def lint_yaml_refs(data, cited, files):
    if not data:
        return
    R.section("источники: ссылки из текста")
    unused = [k for k in data if isinstance(data[k], dict) and k not in cited]
    if unused:
        R.warn("не процитированы, в список НЕ попадут: " + ", ".join(unused[:15]) + ("…" if len(unused) > 15 else ""))
    # ссылки без неразрывного пробела
    for p in files:
        raw = open(p, encoding="utf-8", errors="replace").read()
        for k in data:
            c = len(re.findall(rf"[ \t]@{re.escape(k)}\b(?!\[)", raw))
            if c:
                R.warn(f"{os.path.relpath(p)}: перед ссылкой @{k} обычный пробел ({c} раз): поставьте ~ "
                       "(СТП 2.8.2: ссылка не должна переноситься отдельно от слова)")


# --------------------------------------------------------------------------
# Орфография
# --------------------------------------------------------------------------
def spell_candidates(full):
    cut = None
    for m in re.finditer(r"^СПИСОК ИСПОЛЬЗОВАННЫХ ИСТОЧНИКОВ$", full, re.M):
        cut = m.start()
    body = full[:cut] if cut else full
    words = Counter()
    for tok in re.findall(r"[А-Яа-яЁё]+(?:-[А-Яа-яЁё]+)*", body):
        for part in tok.split("-"):
            if len(part) < 3 or (part.isupper() and len(part) <= 8):
                continue
            words[part] += 1
    return words


def check_spelling(full, words_file, enabled):
    R.section("орфография (приблизительно)")
    if not enabled:
        R.note("отключено --no-spell")
        return
    if full is None:
        R.note("нет текста PDF")
        return
    words = spell_candidates(full)
    known = set()
    if words_file and os.path.exists(words_file):
        known = {w.strip().lower() for w in open(words_file, encoding="utf-8") if w.strip() and not w.startswith("#")}
    uniq = [w for w in words if w.lower() not in known]
    tool = None
    bad = []
    if have("hunspell"):
        r = run(["hunspell", "-d", "ru_RU", "-i", "utf-8", "-l"], input="\n".join(uniq))
        if r.returncode == 0 and "can't open affix" not in (r.stderr or "").lower():
            bad, tool = [w for w in r.stdout.split() if w], "hunspell ru_RU"
    if tool is None and have("aspell"):
        r = run(["aspell", "-l", "ru", "list", "--encoding=utf-8"], input="\n".join(uniq))
        if r.returncode == 0:
            bad, tool = [w for w in r.stdout.split() if w], "aspell ru"
    if tool is None:
        try:
            from spellchecker import SpellChecker
            sp = SpellChecker(language="ru")
            bad, tool = list(sp.unknown([w.lower() for w in uniq])), "pyspellchecker ru (грубо)"
        except Exception:
            pass
    if tool is None:
        R.note("орфография не проверена: установите hunspell с ru_RU (apt install hunspell hunspell-ru), "
               "либо aspell-ru, либо pip install pyspellchecker")
        return
    bad_set = {b.lower() for b in bad}
    shown = sorted(((w, c) for w, c in words.items() if w.lower() in bad_set and w.lower() not in known),
                   key=lambda x: (-x[1], x[0]))
    print(f"словарь: {tool}; проверено слов: {len(uniq)}")
    if not shown:
        R.ok("неизвестных слов нет")
        return
    R.warn(f"{len(shown)} неизвестных слов (среди них термины и фамилии; проверьте глазами): "
           + ", ".join(f"{w}" + (f"×{c}" if c > 1 else "") for w, c in shown[:40])
           + ("…" if len(shown) > 40 else ""))
    print("  Верные термины и фамилии добавьте в файл словаря (по слову в строке) и передайте --words.")


# --------------------------------------------------------------------------
CHECKLIST = {
    "all": [
        "каждый рисунок/таблица/приложение упомянуты в тексте до них",
        "приложения: буквы А, Б, В… (Ё, З, Й, О, Ч, Ъ, Ы, Ь пропущены), заголовков внутри приложений нет",
        "список источников сверен с образцами СТП 2.8.6; нет придуманных данных",
        "посмотрите страницы глазами: pdftoppm -r 60 -png out.pdf page",
    ],
    "diploma": [
        "состав ПЗ по п. 1.2.5 и задание, ведомость, отчёт о заимствованиях — от пользователя",
        "введение ≤ 2 стр., заключение 1,5–2 стр. (проверено выше приблизительно)",
    ],
    "course": ["состав и объём по требованиям кафедры/методички (СТП их не задаёт)"],
    "lab": ["состав по методичке: введение, заключение и содержание могут не требоваться"],
    "other": ["состав и объём по требованиям заказчика/кафедры"],
}


def main():
    ap = argparse.ArgumentParser(description="Проверка typo-stp документа")
    ap.add_argument("input")
    ap.add_argument("package", nargs="?", default=os.environ.get("TYPST_PACKAGE_PATH"))
    ap.add_argument("--type", choices=["diploma", "course", "lab", "other"], default=None)
    ap.add_argument("--strict", action="store_true")
    ap.add_argument("--font-path", action="append", default=[])
    ap.add_argument("--pdf", help="сохранить собранный PDF")
    ap.add_argument("--words", help="файл со словарём проекта для орфографии")
    ap.add_argument("--no-spell", action="store_true")
    a = ap.parse_args()

    if not have("typst"):
        print("typst не найден в PATH", file=sys.stderr)
        sys.exit(2)
    dtype = a.type or "other"
    if a.type is None:
        R.note("тип документа не указан (--type diploma|course|lab|other): выполнены только общие проверки")
    else:
        print(f"тип документа: {dtype}")
    words_file = a.words or os.path.join(os.path.dirname(os.path.abspath(a.input)), ".typstp-words.txt")

    with tempfile.TemporaryDirectory(prefix="typstp-check.") as tmp:
        font_args, reliable, proxy, termes = check_fonts_before(a.font_path, tmp)
        targs = typst_args(a.package, font_args)
        pdf = os.path.join(tmp, "main.pdf")
        files, bib = lint_sources(a.input)
        data = lint_yaml_entries(bib, dtype)
        compile_doc(a.input, pdf, targs)
        check_fonts_after(pdf, termes)
        cited = check_structure(a.input, targs, dtype)
        pages = load_lines(pdf, tmp)
        flagged = check_geometry(pages, reliable)
        check_ink_margins(pdf, tmp, flagged or set())
        if dtype == "diploma":
            check_diploma_volumes(pages, reliable)
        full = lint_text(pages, dtype)
        lint_yaml_refs(data, cited, files)
        check_spelling(full, words_file, not a.no_spell)
        if a.pdf:
            shutil.copy(pdf, a.pdf)
            print(f"\nPDF сохранён: {a.pdf}")

    print("\nВручную проверьте:")
    for s in CHECKLIST["all"] + CHECKLIST[dtype]:
        print(f"  - {s}")
    print()
    if R.warns:
        print(f"ИТОГ: предупреждений {R.warns}; каждое проверьте глазами (часть может быть ложной)")
    else:
        print("ИТОГ: предупреждений нет")
    if a.strict and R.warns:
        sys.exit(1)


if __name__ == "__main__":
    main()
