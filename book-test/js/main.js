// ---------------------------------------------------------------------
// mopress doc template — runtime behaviour
// No build step, no dependencies. Drop in as-is.
// ---------------------------------------------------------------------

function toggleSidebar() {
	document.getElementById("docRoot").classList.toggle("nav-collapsed");
}

function togglePageToc(navItemEl, tocEl) {
	var isOpen = tocEl.classList.contains("open");
	if (isOpen) {
		tocEl.classList.remove("open");
		navItemEl.classList.remove("page-expanded");
	} else {
		tocEl.classList.add("open");
		navItemEl.classList.add("page-expanded");
	}
}

// Copy button inside generated code blocks.
// Markup contract: <button class="code-copy" data-copy-target="#some-id">
function initCodeCopyButtons() {
	document.querySelectorAll(".code-copy").forEach((btn) => {
		btn.addEventListener("click", () => {
			var targetSel = btn.getAttribute("data-copy-target");
			var codeEl = targetSel
				? document.querySelector(targetSel)
				: btn.closest(".code-block").querySelector("code");
			if (!codeEl) return;
			var text = codeEl.innerText;
			navigator.clipboard.writeText(text).then(() => {
				var original = btn.textContent;
				btn.textContent = "✓ copied";
				setTimeout(() => {
					btn.textContent = original;
				}, 1400);
			});
		});
	});
}

// Reading progress bar — fraction of .content scrolled.
function initProgressBar() {
	var content = document.querySelector(".content");
	var root = document.getElementById("docRoot");
	if (!content || !root) return;
	function update() {
		var scrollable = content.scrollHeight - content.clientHeight;
		var pct = scrollable > 0 ? (content.scrollTop / scrollable) * 100 : 0;
		root.style.setProperty("--progress", pct + "%");
	}
	content.addEventListener("scroll", update, { passive: true });
	update();
}

// Highlight the in-page TOC entry matching the heading currently in view.
function initTocScrollSpy() {
	var headings = Array.prototype.slice.call(
		document.querySelectorAll(".content [id]"),
	);
	var tocLinks = Array.prototype.slice.call(
		document.querySelectorAll(".toc-sub-item[data-anchor]"),
	);
	if (!headings.length || !tocLinks.length) return;

	var byAnchor = {};
	tocLinks.forEach((link) => {
		byAnchor[link.getAttribute("data-anchor")] = link;
	});

	var observer = new IntersectionObserver(
		(entries) => {
			entries.forEach((entry) => {
				if (!entry.isIntersecting) return;
				var id = entry.target.id;
				tocLinks.forEach((l) => {
					l.classList.remove("active");
				});
				if (byAnchor[id]) byAnchor[id].classList.add("active");
			});
		},
		{ rootMargin: "0px 0px -70% 0px" },
	);

	headings.forEach((h) => {
		observer.observe(h);
	});
}

document.addEventListener("DOMContentLoaded", () => {
	initCodeCopyButtons();
	initProgressBar();
	initTocScrollSpy();

	// Wire up the page-toc disclosure triggers rendered by the template.
	document.querySelectorAll("[data-toc-trigger]").forEach((trigger) => {
		var targetId = trigger.getAttribute("data-toc-trigger");
		var tocEl = document.getElementById(targetId);
		if (!tocEl) return;
		trigger.addEventListener("click", (e) => {
			e.preventDefault();
			togglePageToc(trigger, tocEl);
		});
	});

	var navToggle = document.getElementById("navToggle");
	if (navToggle) navToggle.addEventListener("click", toggleSidebar);
});
