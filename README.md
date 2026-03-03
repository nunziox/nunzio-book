# La vita dentro noi stessi — Book Project

*by Nunzio Meli*

## Project structure

| File | Description |
|---|---|
| `book.md` | Book source in Pandoc markdown |
| `pandoc_to_pdf.sh` | Generates the PDF from `book.md` |
| `.claude/skills/publish/` | `/publish` Claude Code skill |

## Edit the book

Open and edit `book.md` directly. It uses standard markdown with a YAML frontmatter block at the top for title, author, and language metadata.

## Generate the PDF

```bash
./pandoc_to_pdf.sh
```

Outputs `La_vita_dentro_noi_stessi.pdf`. Requires `pandoc` + `xelatex` — the script installs them automatically via Homebrew if missing.

## Publish (commit + push + PDF)

Use the `/publish` skill inside Claude Code:

```
/publish your commit message
```

This stages all changes, commits, pushes to `origin/main`, and regenerates the PDF in one step.
