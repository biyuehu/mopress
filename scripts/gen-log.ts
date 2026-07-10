import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";

((content) =>
	((datas) => datas.map(([file, content]) => writeFileSync(file, content)))([
		["CHANGELOG.md", content],
		["docs/changelog.md", `---\ntitle: Changelog\n---\n\n${content}`],
	] as const))(`# Changelog${execSync("bunx changelogen").toString()}`);
