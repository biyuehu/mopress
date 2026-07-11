const TYPE_LABEL = {
	WebComponents: "Web Components",
	Transformers: "转换器",
	Preprocessers: "预处理器",
	MoonBit: "MoonBit 模块",
};

const TYPE_COLOR = {
	WebComponents: "#ec4899",
	Transformers: "#6366f1",
	Preprocessers: "#22c55e",
	MoonBit: "#f59e0b",
};

async function loadPlugins() {
	const res = await fetch("/plugins.json");
	if (!res.ok) throw new Error(`Failed to load plugins list: ${res.status}`);
	return res.json();
}

function render(container, plugins, filter, keyword) {
	const filtered = plugins.filter((p) => {
		const matchType = filter === "all" || p.type === filter;
		const matchKeyword =
			keyword === "" ||
			p.name.toLowerCase().includes(keyword) ||
			p.description.toLowerCase().includes(keyword);
		return matchType && matchKeyword;
	});

	container.querySelector(".ps-grid").innerHTML =
		filtered.length > 0
			? filtered
					.map(
						(p) => `
    <a class="ps-card" href="${p.url}" target="_blank" rel="noopener">
      <div class="ps-card-head">
        <span class="ps-name">${escapeHtml(p.name)}</span>
        <span class="ps-badge" style="background:${TYPE_COLOR[p.type]}1a;color:${TYPE_COLOR[p.type]}">
          ${TYPE_LABEL[p.type]}
        </span>
      </div>
      <p class="ps-desc">${escapeHtml(p.description)}</p>
    </a>`,
					)
					.join("")
			: `<p class="ps-empty">没有找到匹配的插件。</p>`;
}

function escapeHtml(text) {
	return text
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;");
}

async function init() {
	const container = document.getElementById("plugin-store");
	if (!container) return;

	container.innerHTML = `
    <style>
      #plugin-store { font-family: inherit; }
      .ps-toolbar { display: flex; gap: 0.6rem; flex-wrap: wrap; margin-bottom: 1.5rem; }
      .ps-search {
        flex: 1; min-width: 200px;
        padding: 0.5rem 0.9rem;
        border-radius: 0.5rem;
        border: 1px solid var(--ps-border, #232838);
        background: var(--ps-bg-soft, #12151d);
        color: var(--ps-text, #e7e9ee);
        font-size: 0.9rem;
      }
      .ps-filter {
        padding: 0.5rem 0.9rem;
        border-radius: 0.5rem;
        border: 1px solid var(--ps-border, #232838);
        background: transparent;
        color: var(--ps-text-dim, #8b93a7);
        font-size: 0.85rem;
        cursor: pointer;
      }
      .ps-filter.active {
        color: #fff;
        border-color: transparent;
        background: var(--ps-accent, #6366f1);
      }
      .ps-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
        gap: 1rem;
      }
      .ps-card {
        display: block;
        padding: 1.1rem;
        border-radius: 0.65rem;
        border: 1px solid var(--ps-border, #232838);
        background: var(--ps-bg-soft, #12151d);
        text-decoration: none;
        color: inherit;
        transition: border-color 0.15s, transform 0.15s;
      }
      .ps-card:hover { border-color: var(--ps-accent, #6366f1); transform: translateY(-2px); }
      .ps-card-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.5rem; gap: 0.5rem; }
      .ps-name { font-weight: 600; font-size: 0.98rem; }
      .ps-badge { font-size: 0.72rem; padding: 0.15rem 0.5rem; border-radius: 999px; white-space: nowrap; }
      .ps-desc { margin: 0; font-size: 0.85rem; color: var(--ps-text-dim, #8b93a7); line-height: 1.5; }
      .ps-empty { color: var(--ps-text-dim, #8b93a7); font-size: 0.9rem; }
    </style>
    <div class="ps-toolbar">
      <input class="ps-search" type="text" placeholder="搜索插件名称或描述…">
      <button class="ps-filter active" data-type="all">全部</button>
      <button class="ps-filter" data-type="WebComponents">Web Components</button>
      <button class="ps-filter" data-type="Transformers">转换器</button>
      <button class="ps-filter" data-type="Preprocessers">预处理器</button>
      <button class="ps-filter" data-type="MoonBit">MoonBit 模块</button>
    </div>
    <div class="ps-grid"></div>
  `;

	let plugins;
	try {
		plugins = await loadPlugins();
	} catch (err) {
		container.querySelector(".ps-grid").innerHTML =
			`<p class="ps-empty">插件列表加载失败：${String(err)}</p>`;
		return;
	}

	let currentFilter = "all";
	let currentKeyword = "";

	const searchInput = container.querySelector < HTMLInputElement > ".ps-search";
	const filterButtons =
		container.querySelectorAll < HTMLButtonElement > ".ps-filter";

	searchInput.addEventListener("input", () => {
		currentKeyword = searchInput.value.trim().toLowerCase();
		render(container, plugins, currentFilter, currentKeyword);
	});

	filterButtons.forEach((btn) => {
		btn.addEventListener("click", () => {
			for (const b of filterButtons) b.classList.remove("active");
			btn.classList.add("active");
			currentFilter = btn.dataset.type;
			render(container, plugins, currentFilter, currentKeyword);
		});
	});

	render(container, plugins, currentFilter, currentKeyword);
}

init();
