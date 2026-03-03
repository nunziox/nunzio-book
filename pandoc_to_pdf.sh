#!/usr/bin/env bash
set -euo pipefail

# Include user-local bin (e.g. manually installed pandoc)
export PATH="$HOME/bin:$HOME/Library/Python/3.9/bin:$PATH"

INPUT="book.md"
OUTPUT="La_vita_dentro_noi_stessi.pdf"
CLEAN_MD=$(mktemp)

# ── Dependency check ────────────────────────────────────────────────────────

install_pip_if_missing() {
  local cmd="$1" pkg="$2"
  if ! command -v "$cmd" &>/dev/null; then
    echo "📦  Installing $pkg via pip3…"
    pip3 install "$pkg" --quiet
  fi
}

if ! command -v pandoc &>/dev/null; then
  echo "❌  pandoc not found. Install it from https://pandoc.org/installing.html"
  exit 1
fi

# ── PDF engine: prefer xelatex/pdflatex, fall back to weasyprint ────────────

PDF_ENGINE=""
for engine in xelatex pdflatex; do
  if command -v "$engine" &>/dev/null; then
    PDF_ENGINE="$engine"
    break
  fi
done

if [ -z "$PDF_ENGINE" ]; then
  install_pip_if_missing weasyprint weasyprint
  PDF_ENGINE="weasyprint"
fi

echo "✅  Using pandoc + $PDF_ENGINE"

# ── Pre-process: collapse excess blank lines ─────────────────────────────────

python3 - "$INPUT" "$CLEAN_MD" <<'PYEOF'
import sys, re
src = open(sys.argv[1], encoding="utf-8").read()
src = re.sub(r'\n{3,}', '\n\n', src)
open(sys.argv[2], "w", encoding="utf-8").write(src)
PYEOF

# ── Build PDF ────────────────────────────────────────────────────────────────

echo "📖  Building PDF…"

if [ "$PDF_ENGINE" = "weasyprint" ]; then
  # weasyprint path: markdown → HTML → PDF
  pandoc "$CLEAN_MD" \
    --toc \
    --toc-depth=1 \
    --standalone \
    --css="$(dirname "$0")/book.css" \
    -o "${OUTPUT%.pdf}.html"
  weasyprint "${OUTPUT%.pdf}.html" "$OUTPUT"
  rm -f "${OUTPUT%.pdf}.html"
else
  # LaTeX path: full book formatting
  pandoc "$CLEAN_MD" \
    --pdf-engine="$PDF_ENGINE" \
    --toc \
    --toc-depth=1 \
    -V documentclass=book \
    -V papersize=a5 \
    -V fontsize=11pt \
    -V geometry="top=2.5cm, bottom=2.5cm, left=2.8cm, right=2.2cm" \
    -V colorlinks=true \
    -V linkcolor=black \
    -V mainfont="Georgia" \
    -V linestretch=1.4 \
    -V indent=true \
    -V "header-includes=\\usepackage{fancyhdr}\\pagestyle{fancy}\\fancyhf{}\\fancyhead[LE,RO]{\\thepage}\\fancyhead[RE]{La vita dentro noi stessi}\\fancyhead[LO]{Nunzio Meli}\\renewcommand{\\headrulewidth}{0.4pt}" \
    -o "$OUTPUT"
fi

rm -f "$CLEAN_MD"

echo "✅  Done → $OUTPUT"
