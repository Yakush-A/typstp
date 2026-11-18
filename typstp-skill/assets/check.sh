#!/usr/bin/env bash
# Basic compliance checks for a typo-stp document.
#
# Usage:
#   ./check.sh main.typ
#   ./check.sh main.typ /path/to/typst/packages   # local package dir
#
# Exits non-zero only if compilation fails. Warnings are printed for
# issues that usually mean a violation of СТП 01-2024 and need a human look.

set -uo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <main.typ> [package-path]" >&2
  exit 2
fi

input="$1"
pkg_path="${2:-${TYPST_PACKAGE_PATH:-}}"

typst_args=()
if [[ -n "$pkg_path" ]]; then
  typst_args+=(--package-path "$pkg_path")
fi

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/typo-stp-check.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

pdf="$tmpdir/main.pdf"
log="$tmpdir/typst.log"

echo "== compile =="
if ! typst compile "${typst_args[@]}" "$input" "$pdf" >"$log" 2>&1; then
  cat "$log" >&2
  echo "FAIL: compilation failed" >&2
  exit 1
fi
echo "OK: $input -> $pdf"
if [[ -s "$log" ]]; then
  echo "-- compiler warnings --"
  cat "$log"
fi

echo
echo "== structure =="
typst query "${typst_args[@]}" "$input" "figure" >"$tmpdir/figures.json" 2>/dev/null || true
typst query "${typst_args[@]}" "$input" "ref" >"$tmpdir/refs.json" 2>/dev/null || true
typst query "${typst_args[@]}" "$input" "outline" >"$tmpdir/outlines.json" 2>/dev/null || true
typst query "${typst_args[@]}" "$input" "heading" >"$tmpdir/headings.json" 2>/dev/null || true

python3 - "$tmpdir/figures.json" "$tmpdir/refs.json" "$tmpdir/outlines.json" "$tmpdir/headings.json" <<'PY'
import json
import sys


def load(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return []


def text_of(node):
    if node is None:
        return ""
    if isinstance(node, str):
        return node
    if isinstance(node, list):
        return "".join(text_of(x) for x in node)
    if isinstance(node, dict):
        if node.get("func") == "text":
            return node.get("text", "")
        if node.get("func") == "space":
            return " "
        if node.get("func") == "linebreak":
            return " "
        return "".join(text_of(v) for v in node.values() if isinstance(v, (dict, list)))
    return ""


figures = load(sys.argv[1])
refs = load(sys.argv[2])
outlines = load(sys.argv[3])
headings = load(sys.argv[4])

targets = {r.get("target") for r in refs if r.get("target")}
warnings = 0

counts = {"image": 0, "table": 0, "appendix": 0, "other": 0}
for f in figures:
    kind = f.get("kind") or "other"
    key = kind if kind in counts else "other"
    counts[key] += 1

print(f"figures: {counts['image']}, tables: {counts['table']}, appendices: {counts['appendix']}")

if not outlines:
    print("WARN: no #outline() found — СТП 2.2.7 requires СОДЕРЖАНИЕ")
    warnings += 1

for f in figures:
    kind = f.get("kind")
    if kind not in ("image", "table", "appendix"):
        continue
    label = f.get("label")
    caption = f.get("caption")
    name = text_of(caption.get("body")) if caption else ""
    shown = label or (f"«{name}»" if name else "<no label>")

    if kind in ("image", "table") and not caption:
        print(f"WARN: {kind} {shown} has no caption — СТП 2.5.5 / 2.6.2")
        warnings += 1

    if kind in ("image", "table", "appendix"):
        if not label:
            print(f"WARN: {kind} {shown} has no label — нельзя сослаться из текста (СТП 2.5.6 / 2.6.1 / 2.7.2)")
            warnings += 1
        elif label not in targets:
            what = "appendices" if kind == "appendix" else f"{kind}s"
            print(f"WARN: {kind} {label} is not referenced in text — СТП 2.5.6 / 2.6.1 / 2.7.2 ({what})")
            warnings += 1

for h in headings:
    if h.get("level") == 4:
        body = text_of(h.get("body")).strip()
        if body:
            print(f"WARN: level-4 heading text is dropped by the template: «{body}»")
            warnings += 1

print(f"references found: {len([r for r in refs if r.get('target')])}")

if warnings:
    print(f"WARNINGS: {warnings} item(s) need a human check")
else:
    print("OK: no structural warnings")
PY

echo
echo "== PDF =="
if command -v pdfinfo >/dev/null 2>&1; then
  pages="$(pdfinfo "$pdf" 2>/dev/null | awk '/^Pages:/ {print $2}')"
  [[ -n "$pages" ]] && echo "pages: $pages"
fi

if command -v pdftotext >/dev/null 2>&1; then
  pdftotext -layout "$pdf" "$tmpdir/text.txt" 2>/dev/null || true
  if [[ -f "$tmpdir/text.txt" ]]; then
    bad="$(grep -nE '(Рисунок|Таблица)[[:space:]]+0\.|\(0\.[0-9]+\)' "$tmpdir/text.txt" | head -10 || true)"
    if [[ -n "$bad" ]]; then
      echo "WARN: numbering starts with 0.x (element before first numbered section):"
      echo "$bad"
    fi
    apps="$(grep -cE '^[[:space:]]*ПРИЛОЖЕНИЕ[[:space:]]+[А-Я]' "$tmpdir/text.txt" || true)"
    [[ "$apps" -gt 0 ]] && echo "appendix pages found: $apps"
  fi
fi

echo
echo "Manual checklist:"
echo "  - headings: sections UPPERCASE, subsections sentence case, no hyphenation"
echo "  - every figure/table referenced in text"
echo "  - appendix letters follow А, Б, В, ... (Ё, З, Й, О, Ч, Ъ, Ы, Ь skipped)"
echo "  - no headings inside appendices"
echo "  - bibliography matches ГОСТ 7.1-2003; no Wikipedia"
echo "  - introduction <= 2 pages, conclusion 1.5-2 pages"
