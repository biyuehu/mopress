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
	const update = () => {
		if (window.innerWidth < MOBILE_WIDTH) setSidebar(true);
	};
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
			btn.textContent = "✓ copied";
			setTimeout(() => {
				btn.textContent = old;
			}, 1400);
		} catch {}
	});
}

function initProgressBar() {
	const content = $(".content");
	if (!content || !docRoot) return;

	const update = () => {
		const max = content.scrollHeight - content.clientHeight;
		docRoot.style.setProperty(
			"--progress",
			`${max > 0 ? (content.scrollTop / max) * 100 : 0}%`,
		);
	};
	content.addEventListener("scroll", update, {
		passive: true,
	});
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
			const visible = entries.find((e) => e.isIntersecting);
			if (!visible) return;
			active?.classList.remove("active");
			active = map[visible.target.id];
			active?.classList.add("active");
		},
		{ rootMargin: "0px 0px -70% 0px" },
	);

	for (const h of headings) observer.observe(h);
}

function initPageToc() {
	$$("[data-toc-trigger]").forEach((trigger) => {
		const toc = document.getElementById(trigger.dataset.tocTrigger);
		if (!toc) return;

		trigger.addEventListener("click", (e) => {
			e.preventDefault();
			togglePageToc(trigger, toc);
		});
	});
}

document.addEventListener("DOMContentLoaded", () => {
	initMobileSidebar();
	initCodeCopyButtons();
	initProgressBar();
	initTocScrollSpy();
	initPageToc();

	$("#navToggle")?.addEventListener("click", toggleSidebar);
});
