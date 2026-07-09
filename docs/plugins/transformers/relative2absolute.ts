const req = JSON.parse(await Bun.stdin.text());
const baseUrl: string = req.config.base_url ?? "/";

function isLocalMdRelative(url: string): boolean {
	if (/^[a-z][a-z0-9+.-]*:/i.test(url)) return false;
	if (url.startsWith("//") || url.startsWith("/") || url.startsWith("#"))
		return false;
	const [pathPart] = url.split("#");
	return pathPart.endsWith(".md") || pathPart.endsWith(".markdown");
}

function toAbsoluteHtmlUrl(url: string, sourcePath: string): string {
	const [pathPart, hash] = url.split("#");
	const dir = sourcePath.split("/").slice(0, -1);
	const parts = dir.concat(pathPart.split("/"));
	const stack: string[] = [];
	for (const part of parts) {
		if (part === "." || part === "") continue;
		if (part === "..") stack.pop();
		else stack.push(part);
	}
	const withoutExt = stack.join("/").replace(/\.(md|markdown)$/, "");
	const abs = `${baseUrl.replace(/\/$/, "")}/${withoutExt}.html`;
	return hash ? `${abs}#${hash}` : abs;
}

let changed = false;

function mapInline(nodes: any[], sourcePath: string): any[] {
	return nodes.map((node) => {
		if (node.$tag === "Link") {
			const [label, url] = node.$val;
			if (isLocalMdRelative(url)) {
				changed = true;
				return {
					$tag: "Link",
					$val: [
						mapInline(label, sourcePath),
						toAbsoluteHtmlUrl(url, sourcePath),
					],
				};
			}
			return { ...node, $val: [mapInline(label, sourcePath), url] };
		}
		if (node.$tag === "Emphasis" || node.$tag === "Strong") {
			return { ...node, $val: [mapInline(node.$val[0], sourcePath)] };
		}
		return node;
	});
}

function mapBlocks(blocks: any[], sourcePath: string): any[] {
	return blocks.map((block) => {
		switch (block.$tag) {
			case "Paragraph":
				return { ...block, $val: [mapInline(block.$val[0], sourcePath)] };
			case "Heading":
				return {
					...block,
					$val: [block.$val[0], mapInline(block.$val[1], sourcePath)],
				};
			case "BlockQuote":
				return { ...block, $val: [mapBlocks(block.$val[0], sourcePath)] };
			case "List": {
				const lb = block.$val[0];
				return {
					...block,
					$val: [
						{
							...lb,
							items: lb.items.map((i: any[]) => mapBlocks(i, sourcePath)),
						},
					],
				};
			}
			case "Table": {
				const tb = block.$val[0];
				return {
					...block,
					$val: [
						{
							headers: tb.headers.map((c: any[]) => mapInline(c, sourcePath)),
							rows: tb.rows.map((r: any[][]) =>
								r.map((c) => mapInline(c, sourcePath)),
							),
						},
					],
				};
			}
			default:
				return block;
		}
	});
}

const sourcePath: string = req.source_path ?? "";
const result = mapBlocks(req.data, sourcePath);

if (!changed) {
	process.stdout.write("");
} else {
	process.stdout.write(JSON.stringify({ data: result }));
}

export {};
