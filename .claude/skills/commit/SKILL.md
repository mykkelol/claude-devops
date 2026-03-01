---
name: commit
description: Commit code to github with a comment of the change
allowed-tools: Bash, Read
disable-model-invocation: true
---

Commit the changes completed in the session to Github repo

Steps:
- [ ] Add all changes: `git add .`
- [ ] Create a summarized comment with present/imperative tense of changes made in the session
- [ ] Commit the changes with message flag: `git commit -m {{summarized imperative comment}}`
- [ ] Push to main: `git push origin main`

If any step fails, stop and report the error. Do not continue to the next step.