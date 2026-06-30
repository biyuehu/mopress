import { readFileSync, writeFileSync } from "node:fs";

writeFileSync(
	"src/cmd/main/includes.mbt",
	(
		[
			["docs/scripts/main.js", "scripts_main_js"],
			["docs/styles/index.css", "styles_index_css"],
			["docs/templates/default.html", "templates_default_html"],
		] as [string, string][]
	)
		.map(
			([p, n]) =>
				`///|\nlet ${n}: String = ${readFileSync(p, "utf-8")
					.split("\n")
					.map((l) => `  #|${l}`)
					.join("\n")}\n`,
		)
		.join("\n"),
);
