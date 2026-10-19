globalThis.MOPRESS_INDEX_DATA = []

const docRoot = document.getElementById('docRoot')

const $ = (s, root = document) => root.querySelector(s)

const getMode = () => localStorage.getItem('theme') || 'system'

const MOBILE_WIDTH = 768

function initSidebar() {
  if (!docRoot) return
  const isMobile = () => window.innerWidth <= MOBILE_WIDTH

  const toggle = () => {
    if (isMobile()) {
      docRoot.classList.toggle('nav-open')
    } else {
      docRoot.classList.toggle('nav-collapsed')
    }
  }

  const closeMobile = () => {
    if (isMobile()) {
      docRoot.classList.remove('nav-open')
    }
  }

  $('#navToggle')?.addEventListener('click', toggle)
  $('#sidebarBackdrop')?.addEventListener('click', closeMobile)

  docRoot.querySelectorAll('.nav-item').forEach((item) => {
    item.addEventListener('click', () => {
      if (isMobile()) {
        closeMobile()
      }
    })
  })

  window.addEventListener(
    'resize',
    () => {
      if (!isMobile()) {
        docRoot.classList.remove('nav-open')
      }
    },
    { passive: true }
  )
}

function initProgressBar() {
  const content = $('.content')
  if (!content) return

  const update = () => {
    const max = content.scrollHeight - content.clientHeight
    docRoot?.style.setProperty('--progress', `${max > 0 ? (content.scrollTop / max) * 100 : 0}%`)
  }

  content.addEventListener('scroll', update, { passive: true })
  update()
}

function initSearch() {
  const overlay = $('#searchOverlay')
  const input = $('#searchInput')
  const results = $('#searchResults')
  let activeIndex = -1
  let currentMatches = []

  const escapeHtml = (str) =>
    str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;')

  const highlightMatches = (text, terms) => {
    let escaped = escapeHtml(text)
    for (const term of terms) {
      if (!term) continue
      const reg = new RegExp(`(${term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi')
      escaped = escaped.replace(reg, '<mark>$1</mark>')
    }
    return escaped
  }

  const getSnippet = (content, terms) => {
    if (!content) return ''
    const lower = content.toLowerCase()
    let firstIdx = -1
    for (const t of terms) {
      const idx = lower.indexOf(t)
      if (idx !== -1 && (firstIdx === -1 || idx < firstIdx)) {
        firstIdx = idx
      }
    }
    if (firstIdx === -1) {
      return highlightMatches(content.substring(0, 100), terms) + (content.length > 100 ? '...' : '')
    }
    const start = Math.max(0, firstIdx - 30)
    const end = Math.min(content.length, firstIdx + 70)
    const prefix = start > 0 ? '...' : ''
    const suffix = end < content.length ? '...' : ''
    return prefix + highlightMatches(content.substring(start, end), terms) + suffix
  }

  const updateActive = () => {
    const items = results.querySelectorAll('.search-result')
    items.forEach((item, idx) => {
      const isActive = idx === activeIndex
      item.classList.toggle('is-active', isActive)
      if (isActive) item.scrollIntoView({ block: 'nearest' })
    })
  }

  const render = (list, terms) => {
    currentMatches = list
    activeIndex = list.length > 0 ? 0 : -1
    if (list.length === 0) {
      results.innerHTML = input.value.trim()
        ? `<div class="search-empty">未找到匹配的结果</div>`
        : `<div class="search-empty">输入关键词搜索文章标题与内容...</div>`
      return
    }

    results.innerHTML = list
      .map((item, idx) => {
        const titleHtml = highlightMatches(item.title, terms)
        const snippetHtml = getSnippet(item.content, terms)
        const activeClass = idx === 0 ? ' is-active' : ''
        return /* html */ `
          <a class="search-result${activeClass}" href="${item.location}">
            <div class="search-result-title">${titleHtml}</div>
            <div class="search-result-desc">${snippetHtml}</div>
          </a>
        `
      })
      .join('')
  }

  const search = (query) => {
    const q = query.trim().toLowerCase()
    if (!q) {
      render([], [])
      return
    }
    const terms = q.split(/\s+/).filter(Boolean)
    const scored = []

    for (const item of globalThis.MOPRESS_INDEX_DATA || []) {
      const titleLower = (item.title || '').toLowerCase()
      const contentLower = (item.content || '').toLowerCase()
      let score = 0
      let matchAll = true

      for (const term of terms) {
        let termMatched = false
        if (titleLower.includes(term)) {
          score += 100
          if (titleLower.startsWith(term)) score += 50
          termMatched = true
        }
        if (contentLower.includes(term)) {
          score += 10
          termMatched = true
        }
        if (!termMatched) {
          matchAll = false
          break
        }
      }

      if (matchAll && score > 0) {
        scored.push({ item, score })
      }
    }

    scored.sort((a, b) => b.score - a.score)
    render(
      scored.slice(0, 15).map((s) => s.item),
      terms
    )
  }

  const open = () => {
    overlay.hidden = false
    input.value = ''
    render([], [])
    input.focus()
  }

  const close = () => {
    overlay.hidden = true
    activeIndex = -1
  }

  $('#searchOpen')?.addEventListener('click', open)
  $('#searchClose')?.addEventListener('click', close)

  overlay?.addEventListener('click', (e) => {
    if (e.target === overlay) close()
  })

  input?.addEventListener('input', () => {
    search(input.value)
  })

  input?.addEventListener('keydown', (e) => {
    if (currentMatches.length === 0) return
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      activeIndex = (activeIndex + 1) % currentMatches.length
      updateActive()
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      activeIndex = (activeIndex - 1 + currentMatches.length) % currentMatches.length
      updateActive()
    } else if (e.key === 'Enter') {
      e.preventDefault()
      if (activeIndex >= 0 && activeIndex < currentMatches.length) {
        window.location.href = currentMatches[activeIndex].location
      }
    }
  })

  document.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault()
      overlay.hidden ? open() : close()
    } else if (e.key === '/' && !['INPUT', 'TEXTAREA'].includes(document.activeElement?.tagName)) {
      e.preventDefault()
      open()
    } else if (e.key === 'Escape' && !overlay.hidden) {
      e.preventDefault()
      close()
    }
  })

  fetch('/index.json')
    .then((res) => res.json())
    .then((data) => {
      if (!Array.isArray(data)) throw new Error('Data structure is not an array')
      globalThis.MOPRESS_INDEX_DATA = data
    })
    .catch((e) => console.error('Failed to load index.json search data:', e))
}

function initThemeRender() {
  const mode = getMode()
  docRoot.classList.toggle(
    'dark',
    mode === 'system' ? window.matchMedia('(prefers-color-scheme: dark)').matches : mode === 'dark'
  )
  $('#themeToggle').textContent = mode === 'system' ? '🌓' : mode === 'dark' ? '🌑' : '🌕'
}

document.addEventListener('DOMContentLoaded', () => {
  $('#themeToggle')?.addEventListener('click', () => {
    const cur = getMode()
    const next = cur === 'system' ? 'light' : cur === 'light' ? 'dark' : 'system'

    localStorage.setItem('theme', next)
    initThemeRender()
  })
  matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    if (getMode() === 'system') initThemeRender()
  })

  initSidebar()
  initProgressBar()
  initSearch()
  initThemeRender()
})
