set windows-shell := ["powershell.exe"]

init:
  lefthook install

test:
  bun scripts/generate.ts
  moon test

build:
  bun scripts/generate.ts
  moon build
