class BiliVideo extends HTMLElement {
	connectedCallback() {
		const bv = this.getAttribute("bv");
		if (!bv) return;
		const page = this.getAttribute("page") ?? "1";
		const iframe = document.createElement("iframe");
		iframe.src = `https://player.bilibili.com/player.html?bvid=${bv}&page=${page}&high_quality=1&danmaku=0`;
		iframe.style.width = "100%";
		iframe.style.aspectRatio = "16 / 9";
		iframe.style.border = "none";
		iframe.allowFullscreen = true;
		iframe.scrolling = "no";
		this.appendChild(iframe);
	}
}

customElements.define("bili-video", BiliVideo);
