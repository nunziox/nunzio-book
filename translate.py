#!/usr/bin/env python3
"""
Translate a markdown book file while preserving all markdown formatting.
Usage: translate.py <input.md> <output.md> <source_lang> <target_lang>
Prints the translated book title to stdout on the last line as: TITLE:<translated title>
"""

import sys
import re
from deep_translator import GoogleTranslator

MAX_CHARS = 4500  # Google Translate limit per request


def translate_chunk(text, source, target):
    if not text.strip():
        return text
    return GoogleTranslator(source=source, target=target).translate(text)


def translate_long(text, source, target):
    """Split oversized text into sentence chunks and translate each."""
    if len(text) <= MAX_CHARS:
        return translate_chunk(text, source, target)
    sentences = re.split(r'(?<=[.!?»])\s+', text)
    parts, current = [], ""
    for s in sentences:
        if len(current) + len(s) + 1 > MAX_CHARS:
            if current:
                parts.append(translate_chunk(current.strip(), source, target))
            current = s + " "
        else:
            current += s + " "
    if current.strip():
        parts.append(translate_chunk(current.strip(), source, target))
    return " ".join(parts)


def translate_markdown(content, source, target):
    lines = content.splitlines(keepends=True)
    result = []
    translated_title = ""

    i = 0
    # ── YAML frontmatter ──────────────────────────────────────────────────────
    if lines and lines[0].strip() == "---":
        result.append(lines[0])
        i = 1
        while i < len(lines):
            line = lines[i]
            if line.strip() == "---":
                result.append(line)
                i += 1
                break
            if line.startswith("title:"):
                raw = line[6:].strip().strip('"').strip("'")
                translated_title = translate_chunk(raw, source, target)
                result.append(f'title: "{translated_title}"\n')
            elif line.startswith("lang:"):
                result.append(f"lang: {target}\n")
            else:
                result.append(line)
            i += 1

    # ── Body: translate block by block ────────────────────────────────────────
    # Collect remaining lines into blocks separated by blank lines
    body = "".join(lines[i:])
    blocks = re.split(r'(\n{2,})', body)  # keep separators

    for block in blocks:
        # Blank separator — pass through as-is
        if not block.strip():
            result.append(block)
            continue

        # Heading line(s)
        if block.startswith("## ") or block.startswith("# "):
            prefix = "## " if block.startswith("## ") else "# "
            heading_text = block[len(prefix):].rstrip("\n")
            translated_heading = translate_chunk(heading_text, source, target)
            result.append(f"{prefix}{translated_heading}\n")
            continue

        # Regular paragraph — translate the whole block for better context
        translated_block = translate_long(block.strip(), source, target)
        result.append(translated_block + "\n")

    return "".join(result), translated_title


if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: translate.py <input.md> <output.md> <source> <target>")
        sys.exit(1)

    input_file, output_file, source, target = sys.argv[1:5]

    with open(input_file, encoding="utf-8") as f:
        content = f.read()

    print(f"🌐  Translating {source.upper()} → {target.upper()} …", flush=True)
    translated, title = translate_markdown(content, source, target)

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(translated)

    print(f"TITLE:{title}")
