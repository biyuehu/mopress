set windows-shell := ["powershell.exe"]

init:
  lefthook install
  just prebuild

test:
  just prebuild
  moon test

build:
  just prebuild
  moon build

prebuild:
  bun scripts/gen-includes.ts

logen:
  bun scripts/gen-log.ts
