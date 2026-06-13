name = "himeno/mopress"

version = "0.1.0"

import {
  "bobzhang/toml@0.2.1",
  "moonbitlang/x@0.4.43",
  "moonbitlang/async@0.19.3",
}

readme = "README.mbt.md"

repository = "https://github.com/biyuehu/mopress"

license = "GPL-3.0-or-later"

keywords = [ "docs", "utils", "cli", "functional", "site-generator", "website" ]

description = "A modern documentation and static site generator for the MoonBit ecosystem, inspired by mdBook and Hakyll"

preferred_target = "native"

options(
  source: "src",
)
