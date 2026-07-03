const req = JSON.parse(await Bun.stdin.text());

const COLORS: Record<string, string> = {
	NOTE: "#0969da",
	TIP: "#1a7f37",
	IMPORTANT: "#8250df",
	WARNING: "#9a6700",
	CAUTION: "#cf222e",
};

const re =
	/^> \[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\][ \t]*\r?\n((?:>.*(?:\r?\n|$))*)/gim;

let matched = false;
const data = (req.data as string).replace(
	re,
	(_m: string, type: string, block: string) => {
		matched = true;
		type = type.toUpperCase();
		const content = block
			.split(/\r?\n/)
			.map((l) => l.replace(/^>\s?/, ""))
			.join("\n")
			.trim();
		const color = COLORS[type];
		const title = type[0] + type.slice(1).toLowerCase();
		return `<div style="border-left:4px solid ${color};padding:8px 16px;margin:16px 0;background:${color}1a">
<p style="font-weight:600;color:${color};margin:0 0 4px">${title}</p>
<p style="margin:0;white-space:pre-wrap">${content}</p>
</div>\n`;
	},
);

if (!matched) {
	process.stdout.write("");
} else {
	process.stdout.write(JSON.stringify({ data }));
}

export {};
