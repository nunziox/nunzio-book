---
name: publish
description: Commit and push all changes, then generate the book PDF. Use when the user says "publish", "push and generate", "build the book", or similar.
allowed-tools: Bash
---

Run the full publish workflow for the book:

1. Stage all changed files:
```
git add -A
```

2. Commit with a short message. If the user passed arguments via $ARGUMENTS, use them as the commit message. Otherwise use "update book content" as the default message.

3. Push to origin main.

4. Generate the PDF by running:
```
./readme_to_book.sh
```

Show the output of each step clearly. If any step fails, stop and report the error.
