# camofox-browser-skills

[English](README.md) | [繁體中文](README.zh-TW.md)

![camofox-browser-skills](cover.jpg)

Anti-detection browser automation skill for [Claude Code](https://claude.com/claude-code) using [Camoufox](https://camoufox.com/) — a Firefox fork with C++ level fingerprint spoofing.

When standard browser tools (Playwright, Puppeteer) get blocked by Cloudflare, Akamai, or other bot detection systems, this skill gives Claude Code stealth browser automation capabilities.

Built on top of [jo-inc/camofox-browser](https://github.com/jo-inc/camofox-browser) (npm: [`@askjo/camofox-browser`](https://www.npmjs.com/package/@askjo/camofox-browser)) — a Node.js server that manages Camoufox browser instances and exposes a REST API. This skill provides the Claude Code integration layer: CLI wrapper, skill definition, and documentation.

## Installation

```bash
# Install (global, recommended)
npx skills add yelban/camofox-browser-skills -s camofox-browser -g

# Install (project-level)
npx skills add yelban/camofox-browser-skills -s camofox-browser

# List available skills
npx skills add yelban/camofox-browser-skills --list
```

First use automatically downloads and installs the Camoufox browser (~300MB, one-time). No manual setup required — just run any `camofox` command and it handles everything.

## Why Camoufox?

| Signal | Standard Automation | Camoufox |
|--------|-------------------|----------|
| `navigator.webdriver` | `true` (detectable) | `false` (patched in C++) |
| Canvas fingerprint | Consistent/blocked | Randomized per session |
| WebGL renderer | VM/headless patterns | Realistic GPU strings |
| AudioContext | Silent/missing | Normal audio fingerprint |
| Font enumeration | Limited set | OS-appropriate font list |
| TLS fingerprint | Chrome-like | Firefox-authentic |
| WebRTC | Exposes real IP | Blocked |

## Quick Start

```bash
camofox open https://example.com          # Open URL (auto-starts server)
camofox snapshot                          # Get page elements with @refs
camofox click @e1                         # Click element
camofox type @e2 "hello"                  # Type text
camofox screenshot                        # Take screenshot
camofox close                             # Close tab
```

## Core Workflow

1. **Navigate** — `camofox open <url>` opens a tab and navigates
2. **Snapshot** — `camofox snapshot` returns an accessibility tree with `@e1`, `@e2` refs
3. **Interact** — use refs to click, type, select
4. **Re-snapshot** — after navigation or DOM changes, get fresh refs
5. **Repeat** — server stays running between commands

```bash
camofox open https://example.com/login
camofox snapshot
# @e1 [input] Email  @e2 [input] Password  @e3 [button] Sign In

camofox type @e1 "user@example.com"
camofox type @e2 "password123"
camofox click @e3
camofox snapshot  # Re-snapshot after navigation
```

## Commands

### Navigation

```bash
camofox open <url>                   # Create tab + navigate (alias: goto)
camofox navigate <url>               # Navigate current tab
camofox back                         # Go back
camofox forward                      # Go forward
camofox refresh                      # Reload page
camofox scroll down                  # Scroll down (also: up, left, right)
```

### Page State

```bash
camofox snapshot                     # Accessibility snapshot with @refs
camofox screenshot                   # Screenshot to /tmp/camofox-screenshots/
camofox screenshot output.png        # Screenshot to specific path
camofox tabs                         # List all open tabs
```

### Interaction

Use `@refs` from snapshot output:

```bash
camofox click @e1                    # Click element
camofox type @e1 "text"              # Type into element
```

### Search Macros (13 available)

```bash
camofox search google "query"        # Google
camofox search youtube "query"       # YouTube
camofox search amazon "query"        # Amazon
camofox search reddit "query"        # Reddit
camofox search wikipedia "query"     # Wikipedia
camofox search twitter "query"       # X / Twitter
camofox search linkedin "query"      # LinkedIn
camofox search tiktok "query"        # TikTok
camofox search instagram "query"     # Instagram
camofox search yelp "query"          # Yelp
camofox search spotify "query"       # Spotify
camofox search netflix "query"       # Netflix
camofox search twitch "query"        # Twitch
```

### Session Management

```bash
camofox --session work open <url>    # Isolated session
camofox --session work snapshot      # Use specific session
camofox close                        # Close current tab
camofox close-all                    # Close all tabs in session
```

### Server Control

```bash
camofox start                        # Start server (usually auto)
camofox stop                         # Stop server
camofox health                       # Health check
```

## When to Use This vs Other Tools

| Scenario | Tool |
|----------|------|
| Normal websites, no bot detection | agent-browser / Playwright (faster) |
| Cloudflare / Akamai protected | **camofox-browser** |
| Sites that block Chromium automation | **camofox-browser** |
| Need anti-fingerprinting | **camofox-browser** |
| Need iOS/mobile simulation | agent-browser |
| Need video recording | agent-browser |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CAMOFOX_PORT` | `9377` | Server port |
| `CAMOFOX_SESSION` | `default` | Default session name |
| `CAMOFOX_HEADLESS` | `true` | Headless mode |
| `HTTPS_PROXY` | — | Proxy server |

## Troubleshooting

**Server won't start?**

```bash
camofox health                        # Check if running
camofox stop && camofox start         # Restart
```

**Still getting blocked?**

```bash
HTTPS_PROXY=socks5://127.0.0.1:1080 camofox open <url>
```

**Bot detection test:**

```bash
camofox open https://bot.sannysoft.com/
camofox screenshot bot-test.png
```

## Project Structure

```
camofox-browser-skills/
├── package.json
├── README.md
├── README.zh-TW.md
├── LICENSE
└── camofox-browser/
    ├── SKILL.md                      # Skill definition
    ├── scripts/
    │   ├── setup.sh                  # Installation script
    │   └── camofox.sh                # CLI wrapper (16 commands)
    ├── references/
    │   ├── api-reference.md          # REST API docs
    │   ├── anti-detection.md         # Fingerprint spoofing details
    │   └── macros-and-search.md      # 13 search macros
    └── templates/
        ├── stealth-scrape.sh         # Anti-detection scraping workflow
        └── multi-session.sh          # Multi-session isolation
```

## License

MIT
