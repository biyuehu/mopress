import { readFileSync } from "node:fs";
import { extname, resolve } from "node:path";

const req = JSON.parse(await Bun.stdin.text());

const INCLUDE_RE =
	/\{\{@\s+([^\s:#}]+)(?:#([\w-]+))?(?::(\d+)?:(\d+)?)?\s*\}\}/g;

const langMap: Record<string, string> = {
	".rs": "rust",
	".mbt": "moonbit",
	".mbtx": "moonbit",
	".ts": "typescript",
	".tsx": "tsx",
	".js": "javascript",
	".jsx": "jsx",
	".mjs": "javascript",
	".cjs": "javascript",
	".py": "python",
	".pyi": "python",
	".pyc": "python",
	".pyx": "cython",
	".pxd": "cython",
	".pxi": "cython",
	".java": "java",
	".class": "java",
	".go": "go",
	".c": "c",
	".h": "c",
	".cpp": "cpp",
	".cc": "cpp",
	".cxx": "cpp",
	".hpp": "cpp",
	".hh": "cpp",
	".hxx": "cpp",
	".ipp": "cpp",
	".inl": "cpp",
	".cs": "csharp",
	".csx": "csharp",
	".vb": "vbnet",
	".fs": "fsharp",
	".fsx": "fsharp",
	".fsi": "fsharp",
	".sh": "bash",
	".bash": "bash",
	".zsh": "zsh",
	".fish": "fish",
	".ps1": "powershell",
	".psm1": "powershell",
	".psd1": "powershell",
	".bat": "batch",
	".cmd": "batch",
	".toml": "toml",
	".json": "json",
	".jsonc": "jsonc",
	".json5": "json5",
	".md": "markdown",
	".markdown": "markdown",
	".rmd": "rmarkdown",
	".html": "html",
	".htm": "html",
	".xhtml": "html",
	".css": "css",
	".scss": "scss",
	".sass": "sass",
	".less": "less",
	".vue": "vue",
	".svelte": "svelte",
	".astro": "astro",
	".yaml": "yaml",
	".yml": "yaml",
	".xml": "xml",
	".xsd": "xml",
	".xsl": "xml",
	".xslt": "xml",
	".svg": "svg",
	".plist": "plist",
	".strings": "strings",
	".storyboard": "storyboard",
	".xib": "xib",
	".rb": "ruby",
	".erb": "erb",
	".php": "php",
	".phtml": "php",
	".swift": "swift",
	".kt": "kotlin",
	".kts": "kotlin",
	".scala": "scala",
	".sc": "scala",
	".lua": "lua",
	".r": "r",
	".dart": "dart",
	".sql": "sql",
	".psql": "sql",
	".graphql": "graphql",
	".gql": "graphql",
	".proto": "protobuf",
	".pl": "perl",
	".pm": "perl",
	".t": "perl",
	".hs": "haskell",
	".lhs": "haskell",
	".elm": "elm",
	".clj": "clojure",
	".cljs": "clojure",
	".edn": "clojure",
	".ex": "elixir",
	".exs": "elixir",
	".erl": "erlang",
	".hrl": "erlang",
	".zig": "zig",
	".nim": "nim",
	".cr": "crystal",
	".lean": "lean",
	".d": "d",
	".jl": "julia",
	".raku": "raku",
	".pm6": "raku",
	".t6": "raku",
	".lisp": "lisp",
	".lsp": "lisp",
	".cl": "clisp",
	".rkt": "racket",
	".ml": "ocaml",
	".mli": "ocaml",
	".v": "vlang",
	".pony": "pony",
	".hx": "haxe",
	".idr": "idris",
	".agda": "agda",
	".coffee": "coffeescript",
	".litcoffee": "coffeescript",
	".pug": "pug",
	".ejs": "ejs",
	".haml": "haml",
	".slim": "slim",
	".mustache": "mustache",
	".handlebars": "handlebars",
	".hbs": "handlebars",
	".tex": "latex",
	".bib": "latex",
	".sty": "latex",
	".cls": "latex",
	".bst": "latex",
	".asm": "assembly",
	".s": "assembly",
	".S": "assembly",
};

let matched = false;

const result = req.data.replace(
	INCLUDE_RE,
	(
		_full: string,
		relPath: string,
		block?: string,
		start?: string,
		end?: string,
	) => {
		matched = true;
		const absPath = resolve(req.config.src, relPath);
		let content: string;
		try {
			content = readFileSync(absPath, "utf-8");
		} catch {
			process.stderr.write(
				JSON.stringify({ error: `Include file not found: ${absPath}` }),
			);
			process.exit(1);
		}

		let sliced: string;
		const lines = content.split("\n");

		if (block) {
			let startLine = -1;
			let endLine = -1;
			for (let i = 0; i < lines.length; i++) {
				if (startLine === -1 && lines[i].includes(`@block ${block}`)) {
					startLine = i + 1;
				}
				if (startLine !== -1 && lines[i].includes("@end")) {
					endLine = i - 1;
					break;
				}
			}
			if (startLine === -1) {
				process.stderr.write(
					JSON.stringify({
						error: `Block marker not found: ${relPath}#${block}`,
					}),
				);
				process.exit(1);
			}
			if (endLine === -1) {
				process.stderr.write(
					JSON.stringify({
						error: `Block end marker not found: ${relPath}#${block}`,
					}),
				);
				process.exit(1);
			}
			if (startLine > endLine) {
				process.stderr.write(
					JSON.stringify({ error: `Invalid block range: ${relPath}#${block}` }),
				);
				process.exit(1);
			}
			sliced = lines.slice(startLine, endLine + 1).join("\n");
		} else {
			const from = start ? parseInt(start, 10) : 1;
			const to = end ? parseInt(end, 10) : lines.length;
			if (from < 1 || to > lines.length || from > to) {
				process.stderr.write(
					JSON.stringify({
						error: `Invalid line range: ${relPath}:${start}:${end}`,
					}),
				);
				process.exit(1);
			}
			sliced = lines.slice(from - 1, to).join("\n");
		}

		const lang = langMap[extname(absPath)] ?? "text";
		return `\`\`\`${lang}\n${sliced}\n\`\`\``;
	},
);

if (!matched) {
	process.stdout.write("");
} else {
	process.stdout.write(JSON.stringify({ data: result }));
}
