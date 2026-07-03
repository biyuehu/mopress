set windows-shell := ["powershell.exe"]

init:
  lefthook install
  bun scripts/generate.ts

test:
  bun scripts/generate.ts
  moon test

build:
  bun scripts/generate.ts
  moon build
