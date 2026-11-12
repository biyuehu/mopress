class MoonbitPlayground extends HTMLElement {
  connectedCallback() {
    if (this._initialized) return
    this._initialized = true

    const src = this.getAttribute('src') || 'https://try.moonbitlang.com/'
    const height = this.getAttribute('height') || '500px'
    const code = (this.getAttribute('code') || this.textContent || '').trim()

    // Clear static fallback text
    this.innerHTML = ''

    // Container wrapper
    const container = document.createElement('div')
    container.className = 'mbt-playground-container'
    container.style.display = 'flex'
    container.style.flexDirection = 'column'
    container.style.width = '100%'
    container.style.margin = '1.5em 0'
    container.style.border = '1px solid var(--border-color, #e1e4e8)'
    container.style.borderRadius = '8px'
    container.style.overflow = 'hidden'
    container.style.background = 'var(--bg-card, #ffffff)'
    container.style.boxShadow = '0 2px 8px rgba(0, 0, 0, 0.05)'

    // Header toolbar
    const toolbar = document.createElement('div')
    toolbar.className = 'mbt-playground-toolbar'
    toolbar.style.display = 'flex'
    toolbar.style.alignItems = 'center'
    toolbar.style.justifyContent = 'space-between'
    toolbar.style.padding = '8px 14px'
    toolbar.style.background = 'var(--bg-toolbar, #f6f8fa)'
    toolbar.style.borderBottom = '1px solid var(--border-color, #e1e4e8)'
    toolbar.style.fontSize = '13px'
    toolbar.style.fontFamily = 'system-ui, -apple-system, sans-serif'

    const titleSpan = document.createElement('div')
    titleSpan.style.display = 'flex'
    titleSpan.style.alignItems = 'center'
    titleSpan.style.gap = '8px'
    titleSpan.style.fontWeight = '600'
    titleSpan.style.color = 'var(--text-primary, #24292e)'
    titleSpan.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polygon points="5 3 19 12 5 21 5 3"></polygon>
      </svg>
      <span>MoonBit Playground</span>
    `

    const actions = document.createElement('div')
    actions.style.display = 'flex'
    actions.style.gap = '12px'

    const openLink = document.createElement('a')
    openLink.href = src
    openLink.target = '_blank'
    openLink.rel = 'noopener noreferrer'
    openLink.textContent = '在新窗口打开 ↗'
    openLink.style.color = 'var(--link-color, #0969da)'
    openLink.style.textDecoration = 'none'
    openLink.style.fontSize = '12px'
    openLink.style.cursor = 'pointer'

    actions.appendChild(openLink)
    toolbar.appendChild(titleSpan)
    toolbar.appendChild(actions)

    // Iframe embed
    const iframe = document.createElement('iframe')
    iframe.src = src
    iframe.style.width = '100%'
    iframe.style.height = height
    iframe.style.border = 'none'
    iframe.style.display = 'block'
    iframe.title = 'MoonBit Playground'
    iframe.allow = 'clipboard-read; clipboard-write'
    iframe.setAttribute('loading', 'lazy')

    container.appendChild(toolbar)
    container.appendChild(iframe)
    this.appendChild(container)
  }
}

customElements.define('moonbit-playground', MoonbitPlayground)

