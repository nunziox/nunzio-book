#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:$HOME/bin:$HOME/Library/Python/3.9/bin:$PATH"

INPUT="book.md"
SCRIPT_DIR="$(dirname "$0")"

# ── Flag parsing: --ita, --spa, or both (default: both) ─────────────────────

GEN_ITA=false
GEN_SPA=false

for arg in "$@"; do
  case $arg in
    --ita) GEN_ITA=true ;;
    --spa) GEN_SPA=true ;;
  esac
done

# Default: generate both if no flag given
if ! $GEN_ITA && ! $GEN_SPA; then
  GEN_ITA=true
  GEN_SPA=true
fi

# ── Dependency checks ────────────────────────────────────────────────────────

if ! command -v pandoc &>/dev/null; then
  echo "❌  pandoc not found. Install from https://pandoc.org/installing.html"
  exit 1
fi

PDF_ENGINE=""
for engine in xelatex pdflatex; do
  if command -v "$engine" &>/dev/null; then
    PDF_ENGINE="$engine"; break
  fi
done
if [ -z "$PDF_ENGINE" ]; then
  PDF_ENGINE="weasyprint"
fi

echo "✅  Using pandoc + $PDF_ENGINE"

# ── Helper: clean excess blank lines ─────────────────────────────────────────

clean_md() {
  local src="$1" dst="$2"
  python3 - "$src" "$dst" <<'PYEOF'
import sys, re
src = open(sys.argv[1], encoding="utf-8").read()
src = re.sub(r'\n{3,}', '\n\n', src)
open(sys.argv[2], "w", encoding="utf-8").write(src)
PYEOF
}

# ── Helper: build PDF from a markdown file ───────────────────────────────────

build_pdf() {
  local md_file="$1" output="$2" css="$3"
  local clean
  clean=$(mktemp)
  clean_md "$md_file" "$clean"

  echo "📖  Building $(basename "$output") …"

  if [ "$PDF_ENGINE" = "weasyprint" ]; then
    local html="${output%.pdf}.html"
    pandoc "$clean" \
      --toc --toc-depth=1 --standalone \
      --css="$css" \
      -o "$html"
    weasyprint "$html" "$output"
    rm -f "$html"
  else
    pandoc "$clean" \
      --pdf-engine="$PDF_ENGINE" \
      --toc --toc-depth=1 \
      -V documentclass=book -V papersize=a5 -V fontsize=11pt \
      -V geometry="top=2.5cm, bottom=2.5cm, left=2.8cm, right=2.2cm" \
      -V colorlinks=true -V linkcolor=black \
      -V mainfont="Georgia" -V linestretch=1.4 -V indent=true \
      -o "$output"
  fi

  rm -f "$clean"
  echo "✅  Done → $output"
}

# ── Helper: build CSS with custom running header title ───────────────────────

make_css() {
  local title="$1" lang="$2" out_css="$3"
  sed \
    -e "s|\"La vita dentro noi stessi\"|\"${title}\"|g" \
    -e "s|lang: it|lang: ${lang}|g" \
    "$SCRIPT_DIR/book.css" > "$out_css"
}

# ── Italian PDF ───────────────────────────────────────────────────────────────

if $GEN_ITA; then
  echo ""
  echo "🇮🇹  Generating Italian PDF…"
  build_pdf "$INPUT" "La_vita_dentro_noi_stessi.pdf" "$SCRIPT_DIR/book.css"
fi

# ── Spanish PDF ───────────────────────────────────────────────────────────────

if $GEN_SPA; then
  echo ""
  echo "🇪🇸  Generating Spanish PDF…"

  SPA_MD=$(mktemp /tmp/book_es_XXXXXX.md)
  SPA_CSS=$(mktemp /tmp/book_es_XXXXXX.css)

  # Translate and capture the translated title
  TRANSLATE_OUT=$(python3 "$SCRIPT_DIR/translate.py" "$INPUT" "$SPA_MD" it es)
  echo "$TRANSLATE_OUT" | grep -v "^TITLE:" || true
  SPA_TITLE=$(echo "$TRANSLATE_OUT" | grep "^TITLE:" | sed 's/^TITLE://')

  # Fall back to a default title if translation didn't return one
  if [ -z "$SPA_TITLE" ]; then
    SPA_TITLE="La vida dentro de nosotros mismos"
  fi

  make_css "$SPA_TITLE" "es" "$SPA_CSS"
  build_pdf "$SPA_MD" "La_vida_dentro_nosotros_mismos.pdf" "$SPA_CSS"

  rm -f "$SPA_MD" "$SPA_CSS"
fi
