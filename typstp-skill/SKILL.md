---
name: Typo STP (BSUIR)
description: "Write and edit BSUIR/БГУИР academic documents per СТП 01-2024 in Typst with the typo-stp package. Use for explanatory notes, term and lab reports, diplomas — structure, sections, lists, formulas, figures, tables, appendices, GOST bibliography, title page, and compliance checks."
---

# Typo STP — BSUIR documents in Typst

This skill covers the text part of a пояснительная записка (ПЗ) formatted
according to **СТП 01-2024** with the **`typo-stp`** package (Typst).
Scope: document structure, layout, headings, lists, formulas, figures, tables,
appendices, bibliography, footnotes, front matter.
Out of scope: graphic material (СТП section 3: schemes, drawings, ЕСКД).

Target package version: **0.2.0** (repo `main`). Version 0.2.1 is an
unreleased branch; see `references/package-api.md` before using its features.

## Read first

Load these files before writing or changing a document — they are not loaded
automatically:

1. `references/stp-requirements.md` — normative rules with СТП clause numbers.
   Read the sections relevant to the task; read sections 1–4 for any new
   document.
2. `references/package-api.md` — what `typo-stp` exports and what the template
   already does. Read before adding any layout or numbering code.
3. `references/recipes.md` — copy-paste snippets and a table of verified
   pitfalls. Read the recipe for each element you are about to write.

Assets:

- `assets/main.typ` — document skeleton; copy it into the project.
- `assets/sources.yml` — Hayagriva bibliography example.
- `assets/title-page.typ` — approximate title page per СТП Appendix В.
- `assets/check.sh` — compile + structural checks; run it from this skill's
  directory against the project's main file.

## Workflow

1. **Inspect the project.** Find the main file (`#show: template`), the
   package version in `#import`, included chapter files, fonts, and whether
   front matter (title/abstract/task) exists.
2. **Set up** with `assets/main.typ` and `assets/sources.yml` if the project is
   new. Keep one `#show: template` in the main file only.
3. **Write content** using `references/recipes.md`. Put each section in its own
   included file if the project already does so.
4. **Compile often:** `typst compile main.typ`. Fix errors immediately; a
   table without a caption fails at compile time.
5. **Run checks:** `bash <this-skill>/assets/check.sh main.typ` (add a package
   path as the second argument when testing a local package). Review every
   warning.
6. **Manual review** against the checklist below and the relevant clauses in
   `references/stp-requirements.md`.

## Golden rules

These are verified behaviours of `typo-stp 0.2.0`; breaking them produces
wrong output or compile errors.

1. **Never format headings by hand.** Use `=`, `==`, `===`, `====` and write
   the title in normal sentence case. The template uppercases sections in the
   body, keeps the original case in the contents, bolds headings, centres
   unnumbered ones, and adds spacing. No `#upper`, `*...*`, or `#align`.
2. **A point without a title is an empty `===`.** A titled point is
   `=== Название`; it is included in the contents, an untitled point is not.
   Level 4 (`====`) prints **only the number** — the template drops its title,
   so use it without a title.
3. **Figures and tables only through `#figure(...)`.** A table must have
   `caption: [...]`; otherwise compilation fails with
   `cannot access fields on type none`.
4. **No numbered elements in the introduction or abstract.** Figures, tables
   and equations there get numbers `0.1`, `(0.1)` because the section counter
   is zero. Move them into the first numbered section.
5. **No headings inside appendices.** The section counter is not reset by
   `#appendix(...)`, so `=`, `==`, `===` inside an appendix get wrong numbers
   (`2.1`, `3`, ...). Use plain paragraphs.
6. **Appendices go last.** After the first appendix, all figures/tables/
   equations are treated as appendix elements. Refer to every appendix in the
   text.
7. **Do not nest `-` bullet lists.** The template's list show-rule drops nested
   items. Use `#abclist` for two-level lettered lists.
8. **A new numbered list restarts at 1.** To continue after a blank line, set
   the first number explicitly: `4. Четвёртый пункт;` then `+ ...`.
9. **Use the right reference form.**
   `@fig` → «Рисунок 1.1»; after the word «рисунке» use `@fig[]` → «1.1».
   `@tab[]` → «1.1»; `@eq[]` → «(1.1)»; `@app[приложении]` → «приложении Б».
   Never write `на рисунке @fig` (it yields «на рисунке Рисунок 1.1»).
10. **Do not add `СОДЕРЖАНИЕ` or `СПИСОК ИСПОЛЬЗОВАННЫХ ИСТОЧНИКОВ`
    headings manually.** `#outline()` and `#bibliography(...)` add them,
    including centring, uppercase, and a page break.
11. **`#source-text` needs `path(...)`:** `#source-text(path("file.py"), "file.py")`.
12. **Do not invent continuous numbering or references to list items.** The
    package resets counters in every section and has no list-item labels.
    Keep the standard's per-section numbering and refer to list items in prose
    («в соответствии с пунктом 1.7, б»).
13. **Bibliography is experimental.** The GOST 7.1-2003 CSL style may format
    some sources incorrectly; inspect the PDF. Wikipedia and similar open
    wikis are forbidden by the standard.

## What the template already handles

Do not duplicate these in the document:

| Area | Handled by `template` |
| --- | --- |
| Page | A4, margins 3/1.5/2/2 cm, page number bottom right 10 mm from edge |
| Text | Times New Roman 14 pt, 18 pt line spacing, justified, 1.25 cm indent |
| Headings | Numbering `1.1.1.1`, bold, uppercase sections, page breaks, outline |
| Lists | `–` marker and paragraph layout for `-`; `1` numbering for `+` |
| Contents | Title, depth 3, dot leaders, no hyphenation in entries |
| Figures | Numbering per section / appendix letter, caption below, spacing |
| Tables | Caption above, header repeat, «Продолжение таблицы X», cell break rules |
| Formulas | `(section.n)` / `(А.n)`, right-bottom number, decimal comma |
| Footnotes | `1)` numbering, bottom-of-page layout, indent |
| Appendices | New page, `ПРИЛОЖЕНИЕ А`, type in parentheses, numbering reset |
| Bibliography | Heading, `[n]` paragraphs, GOST CSL |

## Verification checklist

Run the bundled `assets/check.sh` first (from this skill's directory), then
check manually:

- **Layout:** fonts resolve to Times New Roman / Courier New / TeX Gyre Termes
  Math; margins and 14 pt / 18 pt / 1.25 cm look right in the PDF.
- **Numbering:** figures, tables and formulas start at `1.1`/`(1.1)` in each
  section, never `0.x`; appendices use `А.1`, `(А.1)`, `Таблица А.1`.
- **Contents:** all sections, subsections, titled points, appendices and the
  source list are present; page numbers and dot leaders align; no manual
  «СОДЕРЖАНИЕ» heading.
- **Headings:** sections uppercase, subsections sentence case, no hyphenation,
  no trailing dots, one blank line before/after.
- **Lists:** simple lists end with `;`, complex lists with `.`; lettered lists
  use `а)`, nested items `1)`; no nested `-`.
- **Formulas:** centred, numbered at the right edge, «где» without a colon and
  aligned by symbols, units after a comma, decimal commas, appendix numbering.
- **Figures:** every figure has a caption «Рисунок N.M – Название» and is
  referenced in the text; appendix figures use letters.
- **Tables:** caption «Таблица N.M – Название» above and left-aligned; header
  repeats; continuation says «Продолжение таблицы N.M»; no empty cells (use a
  dash); units and notes are correct.
- **Appendices:** referenced in the order they appear; letters skip
  Ё, З, Й, О, Ч, Ъ, Ы, Ь; type is `(обязательное)`, `(рекомендуемое)` or
  `(справочное)`; no headings inside.
- **Bibliography:** `[n]` citations ascend in order of first mention; entries
  follow ГОСТ 7.1-2003; no Wikipedia; one bibliography block.
- **Front matter:** title page, abstract (850–1200 characters) and task are
  counted in page numbering but show no number; introduction ≤ 2 pages;
  conclusion 1.5–2 pages.
- **Volumes** (for a diploma): 60–80 pages without reference appendices;
  economic section ≤ 18 %, labour protection 5–7 %.

## Limits and escalation

- The package does **not** generate the title page, task sheet, list of
  symbols, or specification/document list. Use `assets/title-page.typ` as a
  starting point and verify it against СТП Appendix В and the department's
  guidelines.
- Exact formula spacing (6/8 intervals, Appendix М) is approximated; do not
  promise pixel-perfect compliance.
- If a requirement cannot be met without changing the package, say so and
  propose the smallest change; do not silently fork the show rules in the
  document.
- When unsure about a normative detail, cite the clause from
  `references/stp-requirements.md` and check the original PDF
  (<https://www.bsuir.by/m/12_100229_1_185586.pdf>).
