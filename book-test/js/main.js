const docRoot = document.getElementById("docRoot");

const $ = (s, root = document) => root.querySelector(s);
const $$ = (s, root = document) => [...root.querySelectorAll(s)];

const MOBILE_WIDTH = 768;

const setSidebar = (collapsed) =>
	docRoot?.classList.toggle("nav-collapsed", collapsed);

const toggleSidebar = () => docRoot?.classList.toggle("nav-collapsed");

function togglePageToc(navItem, toc) {
	navItem.classList.toggle("page-expanded", toc.classList.toggle("open"));
}

function initMobileSidebar() {
	if (!docRoot) return;
	const update = () => window.innerWidth < MOBILE_WIDTH && setSidebar(true);
	window.addEventListener("resize", update, { passive: true });
	update();
}

function initCodeCopyButtons() {
	document.addEventListener("click", async (e) => {
		const btn = e.target.closest(".code-copy");
		if (!btn) return;

		const target = btn.dataset.copyTarget
			? $(btn.dataset.copyTarget)
			: btn.closest(".code-block")?.querySelector("code");
		if (!target) return;

		try {
			await navigator.clipboard.writeText(target.innerText);
			const old = btn.textContent;
			btn.textContent = "✓";
			setTimeout(() => (btn.textContent = old), 1200);
		} catch {}
	});
}

function initProgressBar() {
	const content = $(".content");
	if (!content) return;

	const update = () => {
		const max = content.scrollHeight - content.clientHeight;
		docRoot?.style.setProperty(
			"--progress",
			`${max > 0 ? (content.scrollTop / max) * 100 : 0}%`,
		);
	};

	content.addEventListener("scroll", update, { passive: true });
	update();
}

function initTocScrollSpy() {
	const links = $$(".toc-sub-item[data-anchor]");
	const headings = $$(".content [id]");
	if (!links.length || !headings.length) return;

	const map = Object.fromEntries(links.map((l) => [l.dataset.anchor, l]));
	let active = null;

	const observer = new IntersectionObserver(
		(entries) => {
			const v = entries.find((e) => e.isIntersecting);
			if (!v) return;
			active?.classList.remove("active");
			active = map[v.target.id];
			active?.classList.add("active");
		},
		{ rootMargin: "0px 0px -70% 0px" },
	);

	headings.forEach((h) => observer.observe(h));
}

function initPageToc() {
	$$("[data-toc-trigger]").forEach((t) => {
		const toc = document.getElementById(t.dataset.tocTrigger);
		if (!toc) return;
		t.addEventListener("click", (e) => {
			e.preventDefault();
			togglePageToc(t, toc);
		});
	});
}

function initSearch() {
	const overlay = $("#searchOverlay");
	const input = $("#searchInput");
	const results = $("#searchResults");

	const data = [
		["Getting Started", "/getting-started.html"],
		["Configuration", "/config.html"],
		["Navigation", "/navigation.html"],
		["Search", "/search.html"],
		["Code Blocks", "/code.html"],
		["Changelog", "/CHANGELOG.html"],
	];

	const render = (list) => {
		results.innerHTML = list.length
			? list
					.map((i) => `<a class="search-result" href="${i[1]}">${i[0]}</a>`)
					.join("")
			: `<div class="search-empty">No result</div>`;
	};

	const open = () => {
		overlay.hidden = false;
		input.value = "";
		render(data);
		input.focus();
	};

	const close = () => (overlay.hidden = true);

	$("#searchOpen")?.addEventListener("click", open);
	$("#searchClose")?.addEventListener("click", close);

	overlay?.addEventListener("click", (e) => {
		if (e.target === overlay) close();
	});

	input?.addEventListener("input", () => {
		const q = input.value.trim().toLowerCase();
		render(data.filter((i) => i[0].toLowerCase().includes(q)));
	});

	document.addEventListener("keydown", (e) => {
		if ((e.metaKey || e.ctrlKey) && e.key === "k") {
			e.preventDefault();
			overlay.hidden ? open() : close();
		}
		if (e.key === "Escape") close();
	});
}

document.addEventListener("DOMContentLoaded", () => {
	initMobileSidebar();
	initCodeCopyButtons();
	initProgressBar();
	initTocScrollSpy();
	initPageToc();
	initSearch();

	$("#navToggle")?.addEventListener("click", toggleSidebar);
});
