import { dirname } from 'node:path'

const req = JSON.parse(await Bun.stdin.text())
const sourcePath = dirname(req.target)
const baseUrl: string = req.config.base_url

function isLocalMdRelative(url: string): boolean {
  if (/^[a-z][a-z0-9+.-]*:/i.test(url)) return false
  if (url.startsWith('//') || url.startsWith('/') || url.startsWith('#')) return false
  const [pathPart] = url.split('#')
  return pathPart.endsWith('.md') || pathPart.endsWith('.markdown')
}

let changed = false

function mapInline(nodes: any[]): any[] {
  return nodes.map((node) => {
    const [tag, ...rest] = node
    switch (tag) {
      case 'Link': {
        const [label, url] = rest
        const newLabel = mapInline(label)
        if (isLocalMdRelative(url)) {
          changed = true
          return [
            'Link',
            newLabel,
            ((url) => {
              const [pathPart, hash] = url.split('#')
              const dir = sourcePath.split('/').filter(Boolean)
              const parts = dir.concat(pathPart.split('/'))
              const stack: string[] = []
              for (const part of parts) {
                if (part === '.' || part === '') continue
                if (part === '..') stack.pop()
                else stack.push(part)
              }
              const abs = `${baseUrl.replace(/\/$/, '')}/${stack.join('/').replace(/\.(md|markdown)$/, '')}.html`
              return hash ? `${abs}#${hash}` : abs
            })(url)
          ]
        }
        return ['Link', newLabel, url]
      }
      case 'Emphasis':
        return ['Emphasis', mapInline(rest[0])]
      case 'Strong':
        return ['Strong', mapInline(rest[0])]
      default:
        return node
    }
  })
}

function mapBlocks(blocks: any[]): any[] {
  return blocks.map((block) => {
    if (typeof block === 'string') return block // ThematicBreak
    const [tag, ...rest] = block
    switch (tag) {
      case 'Paragraph':
        return ['Paragraph', mapInline(rest[0])]
      case 'Heading':
        return ['Heading', rest[0], mapInline(rest[1])]
      case 'BlockQuote':
        return ['BlockQuote', mapBlocks(rest[0])]
      case 'List': {
        const lb = rest[0]
        return ['List', { ...lb, items: lb.items.map((i: any[]) => mapBlocks(i)) }]
      }
      case 'Table': {
        const tb = rest[0]
        return [
          'Table',
          {
            headers: tb.headers.map((c: any[]) => mapInline(c)),
            rows: tb.rows.map((r: any[][]) => r.map((c) => mapInline(c)))
          }
        ]
      }
      default:
        return block
    }
  })
}

const result = mapBlocks(req.data)

if (!changed) {
  process.stdout.write('')
} else {
  process.stdout.write(JSON.stringify({ data: result }))
}
