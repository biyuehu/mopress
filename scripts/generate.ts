import { readFileSync, writeFileSync } from "node:fs";

writeFileSync(
	"src/main/includes.mbt",
	(
		[
			["docs/scripts/main.js", "scripts_main_js"],
			["docs/styles/index.css", "styles_index_css"],
			["docs/templates/default.html", "templates_default_html"],
			[
				"docs/plugins/preprocessers/github-alert.ts",
				"preprocessers_github_alert_ts",
			],
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
