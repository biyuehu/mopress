globalThis.MOPRESS_INDEX_DATA = [];

const docRoot = document.getElementById("docRoot");

const $ = (s, root = document) => root.querySelector(s);

const getMode = () => localStorage.getItem("theme") || "system";

const MOBILE_WIDTH = 768;

function initMobileSidebar() {
	if (!docRoot) return;
	const update = () =>
		window.innerWidth < MOBILE_WIDTH &&
		!!docRoot?.classList.toggle("nav-collapsed", true);
	window.addEventListener("resize", update, { passive: true });
	update();
}

// function initCodeCopyButtons() {
// 	document.addEventListener("click", async (e) => {
// 		const btn = e.target.closest(".code-copy");
// 		if (!btn) return;

// 		const target = btn.dataset.copyTarget
// 			? $(btn.dataset.copyTarget)
// 			: btn.closest(".code-block")?.querySelector("code");
// 		if (!target) return;

// 		try {
// 			await navigator.clipboard.writeText(target.innerText);
// 			const old = btn.textContent;
// 			btn.textContent = "✓";
// 			setTimeout(() => (btn.textContent = old), 1200);
// 		} catch { }
// 	});
// }

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

// function initTocScrollSpy() {
// 	const links = $$(".toc-sub-item[data-anchor]");
// 	const headings = $$(".content [id]");
// 	if (!links.length || !headings.length) return;

// 	const map = Object.fromEntries(links.map((l) => [l.dataset.anchor, l]));
// 	let active = null;

// 	const observer = new IntersectionObserver(
// 		(entries) => {
// 			const v = entries.find((e) => e.isIntersecting);
// 			if (!v) return;
// 			active?.classList.remove("active");
// 			active = map[v.target.id];
// 			active?.classList.add("active");
// 		},
// 		{ rootMargin: "0px 0px -70% 0px" },
// 	);

// 	headings.forEach((h) => observer.observe(h));
// }

// function initPageToc() {
// 	$$("[data-toc-trigger]").forEach((t) => {
// 		const toc = document.getElementById(t.dataset.tocTrigger);
// 		if (!toc) return;
// 		t.addEventListener("click", (e) => {
// 			e.preventDefault();
// 			t.classList.toggle("page-expanded", toc.classList.toggle("open"));
// 		});
// 	});
// }

function initSearch() {
	const overlay = $("#searchOverlay");
	const input = $("#searchInput");
	const results = $("#searchResults");

	const render = (list) => {
		results.innerHTML = list.length
			? list
					.map(
						(i) =>
							/* html */ `<a class="search-result" href="${i.location}"><strong>${i.title}</strong><br>${i.content.substring(0, 40)}...</a>`,
					)
					.join("")
			: `<div class="search-empty">No result</div>`;
	};

	const open = () => {
		overlay.hidden = false;
		input.value = "";
		render([]);
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
		render(
			q === ""
				? []
				: MOPRESS_INDEX_DATA.filter(
						(i) => i.title.includes(q) || i.content.includes(q),
					),
		);
	});

	document.addEventListener("keydown", (e) => {
		if ((e.metaKey || e.ctrlKey) && e.key === "k") {
			e.preventDefault();
			overlay.hidden ? open() : close();
		}
		if (e.key === "Escape") close();
	});

	fetch("/index.json")
		.then((res) => res.json())
		.then((data) => {
			if (!Array.isArray(data))
				throw new Error("Data structure is not a array");
			globalThis.MOPRESS_INDEX_DATA = data;
		})
		.catch((e) => console.error("Failed to load indexs data:", e));
}

function initThemeRender() {
	const mode = getMode();
	docRoot.classList.toggle(
		"dark",
		mode === "system"
			? window.matchMedia("(prefers-color-scheme: dark)").matches
			: mode === "dark",
	);
	$("#themeToggle").textContent =
		mode === "system" ? "🌓" : mode === "dark" ? "🌑" : "🌕";
}

document.addEventListener("DOMContentLoaded", () => {
	$("#navToggle")?.addEventListener(
		"click",
		() => !!docRoot?.classList.toggle("nav-collapsed"),
	);
	$("#themeToggle")?.addEventListener("click", () => {
		const cur = getMode();
		const next =
			cur === "system" ? "light" : cur === "light" ? "dark" : "system";

		localStorage.setItem("theme", next);
		initThemeRender();
	});
	matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
		if (getMode() === "system") initThemeRender();
	});

	initMobileSidebar();
	initProgressBar();
	initSearch();
	initThemeRender();
});
