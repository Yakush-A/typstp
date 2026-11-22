---
name: typstp-skill
description: "Write, edit and check BSUIR (БГУИР) academic documents in Typst with the typo-stp package per СТП 01-2024: diploma projects (дипломный проект, дипломная работа), course papers (курсовой проект, курсовая работа), lab reports (отчёт по лабораторной работе), typical calculations, essays. Covers пояснительная записка, headings, figures, tables, formulas, appendices, footnotes and the список использованных источников in ГОСТ 7.1-2003 (Hayagriva). Use when the user mentions typo-stp, СТП, БГУИР, пояснительная записка, курсовая, лабораторная, Typst report or Typst bibliography."
---

# Typo STP — BSUIR academic documents in Typst

Use this skill for the text part of a BSUIR course paper, laboratory report,
or diploma project written with `@preview/typo-stp:0.2.1`. The package applies
the recurring typography; the authoring task is to create accurate content and
semantic Typst markup.

Scope: structure and content of the text document, headings, lists, formulas,
figures, tables, appendices, footnotes, and bibliography. Graphic material
governed by ESKD/ESTD/ESPD and department-specific forms are outside scope.

## Document type decides which СТП rules apply

СТП 01-2024 is written for diploma projects. Its sections 2 and 3 (formatting,
text, formulas, figures, tables, appendices, bibliography) also apply to course
papers, typical calculations, essays and lab reports. Section 1 (composition,
page counts, abstract, introduction/conclusion content) is **diploma-only**.

| Rules | Diploma | Course paper | Lab report |
| --- | --- | --- | --- |
| Formatting and text rules (СТП section 2) | yes | yes | yes |
| Fixed composition (title, abstract, assignment, contents, introduction, conclusion, bibliography, appendices, document register) | yes | no, set by the department | no |
| Abstract | yes | usually none | usually none |
| Contents / introduction / conclusion | yes | per department | may be absent |
| 60–80 pages, economics ≤ 18 %, labour protection 5–7 % | yes | no | no |
| «Данный дипломный проект выполнен мной лично…» sentence | yes | only if required | no |

The course and lab columns are BSUIR practice, not text of the standard. Ask
the user for the document type and the department requirements before
choosing structure; never default to the diploma structure. Every section of
`references/stp-requirements.md` and `references/writing-style.md` is tagged
**[ВСЕ]** or **[ТОЛЬКО ДИПЛОМ]**; apply only tags that match the document.

## Start with the project and the user

1. Inspect the project: main file, package version, `#show: template`,
   included chapters, bibliography, and existing front matter.
2. Establish the document type (diploma / course paper / lab report / other)
   and its required structure with the user. Do not infer diploma-only parts
   (abstract, economic section, labour protection, introduction and conclusion
   length and wording, page counts, originality sentence) for a course paper
   or laboratory report.
3. Require the user's approved title page and assignment sheet when either is
   required. Include their supplied files or content; never invent signatures,
   codes, approvals, dates, department forms, or a substitute title page.
4. For a new document, use `assets/main.typ` only as a Typst skeleton. It is
   not a prescribed chapter structure.

Read only the references needed for the change:

- `references/package-api.md` before changing markup, numbering, or layout.
- `references/recipes.md` before adding the corresponding document element.
- `references/stp-requirements.md` when a СТП requirement affects the task;
  for diploma projects, read its sections 0–1 before drafting.
- `references/writing-style.md` when writing or editing prose: phrasing,
  numbers and units, formula wording, references to figures/tables/sources,
  introduction and conclusion (diploma).
- `references/bibliography.md` **always** before creating or editing
  bibliography records.
- `assets/sources.yml` before creating or editing Hayagriva records. It holds
  verified patterns for every source type in the СТП samples and for the edge
  cases (4+ authors, corporate author, volumes, newspaper, CD, e-book).

## What the LLM does

- Ask for missing factual inputs that cannot safely be invented: approved
  structure, title/assignment files, source details, measurements, formulas,
  results, labels, and departmental requirements.
- Build the requested semantic structure with Typst headings and write or edit
  clear technical text. Use `=`, `==`, `===`, and `====` only for the levels
  the user chooses; never type heading numbers manually.
- Use package functions correctly: `#outline()`, `#figure`, `#appendix`,
  `#explanation`, `#source-text`, and `#bibliography`.
- Preserve source attribution. Check that every figure, table, and appendix is
  cited in the text; appendices must follow the order of their first citation.
- Build bibliography entries in Hayagriva following `references/bibliography.md`
  and `assets/sources.yml`; never use `.bib` (some cases do not work there).
  Inspect the rendered list against its checklist.
- Write prose in СТП style (`references/writing-style.md`): «получаем», not
  «мы получили»; numbers and units; references with `~` before `@key`.
- Compile after material edits and review warnings and the PDF when it is
  produced. Inspect page filling (only trust it when the checker reports real or
  proxy Times New Roman): when the remaining space at a page bottom is
  avoidably empty and the next content is not required to start a new section,
  remove accidental whitespace or let the natural following content flow onto
  that page. Do not force-fill pages with invented text or manual spacing.
  Report package limitations rather than silently overriding them.

## Checking the result

Run the checker after material edits and before reporting the work as done:

```bash
bash assets/check.sh --type diploma|course|lab|other [--strict] main.typ [package-path]
```

Always pass `--type`; ask the user for it if unknown. Sections 2–3 of the СТП
checks run for every type. Section 1 checks (introduction ≤ 2 pages,
conclusion ≈ 1.5–2 pages, 60–80 pages before appendices, Wikipedia ban, mandatory
`#outline()`) run **only** for `diploma`. For `lab` a missing contents page is
not reported.

What it checks:

- **Fonts.** Looks for Times New Roman (and Courier New, TeX Gyre Termes Math).
  Without Times New Roman it builds a temporary proxy from Liberation Serif
  (metrically compatible, needs `fonttools` and `fonts-liberation2`) so page
  counts and line breaks stay trustworthy; the final PDF for submission must
  still be built with real Times New Roman. If neither is available the
  script warns that page counts and page filling are **unreliable**; do not
  draw conclusions about volumes or white space then.
- **Margins** (30/15/20/20 mm) by text positions and by rendered pixels, so
  figures, shapes and table lines that overflow are caught too.
- **Structure:** captions, labels, references from the text to every figure,
  table and appendix, `0.x` numbering, level-4 headings.
- **Text lint** on the PDF: banned phrasing («мы получили», «по (2.1)»,
  «мощностью в 600 Вт», «п. 1.7», duplicated «Рисунок Рисунок»).
- **Sources:** `.typ` source lint (manual page breaks, `#set page/par`, manual
  `[N]`, missing `~` before citations) and Hayagriva lint (4+ authors in
  `author`, relative `url`, `genre` equal to `title`, full city names,
  uncited keys, BibLaTeX-only fields).
- **Spelling** with hunspell `ru_RU` (else aspell, else pyspellchecker). It
  reports unknown words only; terms and surnames appear there too. Put
  confirmed words, one per line, into `.typstp-words.txt` beside `main.typ`
  (or pass `--words FILE`) and do not report them again. Never "fix" a term
  just because the checker flagged it.

Treat every WARN as a lead, not a verdict: text and spelling checks are
heuristics. Fix real defects in the `.typ` source, never by manual spacing.
Exit code is 0 unless compilation fails; `--strict` also returns 1 on any
WARN (use it in CI).

Other tools, all standard poppler/typst utilities, for ad-hoc inspection:

| Need | Command |
| --- | --- |
| Fonts available to Typst | `typst fonts \| grep -i "times new roman"` |
| Fonts embedded in the PDF | `pdffonts main.pdf` |
| Page count and A4 size | `pdfinfo main.pdf` |
| Text with line positions | `pdftotext -layout main.pdf -` or `pdftotext -bbox-layout main.pdf out.html` |
| Look at pages (images) | `pdftoppm -r 60 -png main.pdf page` |
| PDF validity | `qpdf --check main.pdf` |
| Labels, references, headings | `typst query main.typ "figure"` / `"ref"` / `"heading"` |

For spelling install `hunspell` and `hunspell-ru` (apt); for the proxy font
`pip install fonttools` and `fonts-liberation2`; for source lint
`pip install pyyaml`; for the pixel margin check `pip install pillow`. Missing
optional tools produce a NOTE, not a failure.

## What `template` already does

Do not recreate these rules in the document: A4 page setup; margins; Times New
Roman 14 pt; 18 pt leading; paragraph indent; page footer; heading styling,
numbering, and section page breaks; automatic contents; figure/table/formula
numbers and captions; table continuations; appendix heading and letters;
footnote layout; bibliography heading.

In particular:

- `#introduction`, `#abstract`, and `#conclusion` are unnumbered level-1
  headings, so the template starts them on a new page.
- The output is a one-sided A4 document; no special markup is needed.
- Hyphenation is disabled for headings and figure/table captions.
- After a subsection heading, write the paragraph on the immediately following
  line. Do **not** insert a blank source line: the template already adds the
  required vertical spacing.
- Heading hierarchy is formatted and numbered by the template. The LLM chooses
  only the semantic levels needed by the approved structure.

## Do not add local formatting

Do not apply `*bold*`, `_italic_`, `#text(weight: ...)`, `#text(style: ...)`,
`#align`, `#set align`, or similar manual visual styling to normal text,
headings, captions, formulas, lists, or bibliography. The template owns these
decisions. Alignment inside table cells is the exception when the data itself
requires it.

Do not wrap a table or figure in a non-breakable block (`block(breakable:
false)`, `block(unbreakable: true)`, or equivalent) merely to control layout.
The package manages table pagination. Do not insert manual vertical space,
page breaks, or empty paragraphs to manipulate page filling.

Do not create rectangle, lorem ipsum, blank-image, or other illustration
placeholders unless the user explicitly asks for one. When an image is needed
but absent, say which file is needed and where it should be placed in the
project, then wait for the user to add it.

## Non-obvious package constraints

1. Apply `#show: template` once, in the main file only.
2. Use normal sentence case in heading source. Do not add `#upper`, manual
   bold, alignment, numbering, page breaks, or a manual contents/bibliography
   heading.
3. A blank `===` is an untitled point. A titled level-3 point appears in the
   outline. A level-4 heading drops its title, so use `====` without one.
4. Use figures and tables through `#figure(...)`; tables require `caption:`.
5. Put numbered figures, tables, and formulas after the first numbered section:
   before it they receive `0.x` numbers.
6. Put appendices last. Do not use Typst headings inside an appendix; after the
   first appendix, figures/tables/formulas use appendix numbering.
7. Do not nest `-` lists. Use `#abclist` for a two-level lettered list.
8. Start a continuation of a numbered list explicitly (`4. ...`).
9. Use references with the appropriate supplement: `@fig[]` after “на
   рисунке”, `@tab[]` after “в таблице”, `@eq[]` after “в формуле”, and
   `@app[приложении]` for an appendix.
10. `#source-text` takes `path("file.ext")`, not a bare string.

## Content checks the template cannot perform

- Text, data, calculations, conclusions, terminology, SI units, and source
  citations are factually correct.
- A figure/table/appendix has a meaningful text reference and is placed after
  the first reference where practical.
- Tables have no unintentional empty cells, use correct units and notes, and
  their text communicates the conclusions from the data.
- Formulas have correct symbols, explanations, punctuation, and source
  citations when borrowed.
- Bibliographic records are complete and match the patterns in
  `assets/sources.yml`; no Wikipedia or similar wiki is used; no invented
  authors, years, publishers or pages.
- The user-supplied title page and assignment sheet are present whenever the
  approved structure requires them.

## Limits

`typo-stp` does not create title pages, assignment sheets, a list of symbols,
specifications, or a document register. Do not substitute the old approximate
title-page asset for an approved department form. When an exact requirement is
not supported by the package, explain the gap and propose the smallest
package-level change instead of stacking local show-rules into the document.
