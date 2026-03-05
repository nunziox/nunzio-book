---
name: correct
description: Correct a book chapter in book.md. Fixes formatting, removes AI characters (em dashes —), and cleans up punctuation and typos. Use when the user says "correggi il capitolo", "fix chapter", "correct chapter", or similar. $ARGUMENTS should contain the chapter title.
allowed-tools: Read, Edit, Grep
---

Correct the chapter `$ARGUMENTS` in `/Users/nunziomeli/Desktop/nunzio-book/book.md`.

## Steps

1. Use Grep to find the line number of the chapter heading.
2. Read from that line to the next `##` heading to get the full chapter content.
3. Apply ALL of the following corrections:

### Remove AI characters
- Replace all em dashes `—` with commas or appropriate punctuation based on context (e.g. parenthetical `— text —` → `, text,`)

### Fix formatting
- Ensure every paragraph is separated by exactly one blank line
- Remove trailing spaces at end of lines

### Fix punctuation and typos
- Fix apostrophes: `un emozione` → `un'emozione`, `gia'` → `già`, etc.
- Fix accents: `É` → `È` at sentence start
- Fix double spaces between words
- Replace `, ` used as sentence separator with `. ` where a new sentence begins with a capital letter (e.g. `in natura, La` → `in natura. La`)
- Ensure the last sentence of the chapter ends with proper punctuation (`.`, `?`, or `!`)
- Fix `over produzione` → `sovrapproduzione` and similar Italianization of English compounds

4. Apply all fixes in a single Edit call replacing the entire chapter block.
5. Confirm what was changed.
