import { existsSync } from "node:fs";
import { dirname, isAbsolute, resolve } from "node:path";

const req = JSON.parse(await Bun.stdin.text());
const sourcePath = resolve(req.config.src, req.target);

const errors: [string, string][] = [];

function walkInline(nodes: any[]): void {
	for (const node of nodes) {
		const [tag, ...rest] = node;
		switch (tag) {
			case "Link": {
				const [label, url] = rest;
				if (
					!/^[a-z][a-z0-9+.-]*:/i.test(url) &&
					!url.startsWith("//") &&
					!url.startsWith("#") &&
					!isAbsolute(url)
				) {
					const [pathPart] = url.split("#");
					if (pathPart === "") continue;
					const resolved = resolve(dirname(sourcePath), pathPart);
					if (!existsSync(resolved)) {
						errors.push([url, resolved]);
						continue;
					}
				}
				walkInline(label);
				break;
			}
			case "Emphasis":
			case "Strong":
				walkInline(rest[0]);
				break;
		}
	}
}

function walkBlocks(blocks: any[]): void {
	for (const block of blocks) {
		if (typeof block === "string") continue; // ThematicBreak
		const [tag, ...rest] = block;
		switch (tag) {
			case "Paragraph":
				walkInline(rest[0]);
				break;
			case "Heading":
				walkInline(rest[1]);
				break;
			case "BlockQuote":
				walkBlocks(rest[0]);
				break;
			case "List":
				for (const item of rest[0].items) walkBlocks(item);
				break;
			case "Table": {
				const { headers, rows } = rest[0];
				for (const row of [headers, ...rows])
					for (const cell of row) walkInline(cell);
				break;
			}
		}
	}
}

walkBlocks(req.data);
if (errors.length > 0) {
	process.stderr.write(
		errors
			.map(
				([url, resolved]) =>
					`Broken link: the target of link "${url}" does not exist: ${resolved}, at ${sourcePath}`,
			)
			.join("\n"),
	);
	process.exit(1);
}
process.stdout.write("");
