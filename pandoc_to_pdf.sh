#!/usr/bin/env bash
set -euo pipefail

INPUT="book.md"
OUTPUT="La_vita_dentro_noi_stessi.pdf"
CLEAN_MD=$(mktemp /tmp/book_clean_XXXX.md)

# ── Dependency check ────────────────────────────────────────────────────────

install_if_missing() {
  local cmd="$1" brew_pkg="$2"
  if ! command -v "$cmd" &>/dev/null; then
    if command -v brew &>/dev/null; then
      echo "📦  Installing $brew_pkg via Homebrew…"
      brew install "$brew_pkg"
    else
      echo "❌  '$cmd' is required but not installed."
      echo "    Install Homebrew first: https://brew.sh"
      echo "    Then run: brew install $brew_pkg"
      exit 1
    fi
  fi
}

install_if_missing pandoc pandoc

# Prefer xelatex (better Unicode/Italian support), fall back to pdflatex
PDF_ENGINE=""
for engine in xelatex pdflatex; do
  if command -v "$engine" &>/dev/null; then
    PDF_ENGINE="$engine"
    break
  fi
done

if [ -z "$PDF_ENGINE" ]; then
  if command -v brew &>/dev/null; then
    echo "📦  Installing BasicTeX via Homebrew (this may take a while)…"
    brew install --cask basictex
    eval "$(/usr/libexec/path_helper)"
    sudo tlmgr update --self
    sudo tlmgr install collection-fontsrecommended babel-italian
    PDF_ENGINE="xelatex"
  else
    echo "❌  No LaTeX engine found (xelatex / pdflatex)."
    echo "    Install Homebrew (https://brew.sh) then run:"
    echo "      brew install --cask basictex"
    exit 1
  fi
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

rm -f "$CLEAN_MD"

echo "✅  Done → $OUTPUT"
