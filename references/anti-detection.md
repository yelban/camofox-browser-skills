# Anti-Detection Mechanisms

## Why Camoufox?

Standard browser automation (Playwright, Puppeteer, Selenium) uses Chromium-based browsers that are easily detected by:
- `navigator.webdriver` flag
- CDP (Chrome DevTools Protocol) fingerprinting
- JavaScript-detectable automation artifacts

Camoufox is a **Firefox fork** that patches fingerprint leaks at the **C++ engine level**, making detection via JavaScript impossible.

## What Camoufox Spoofs

### Browser Fingerprint (C++ level)
| Signal | Standard Automation | Camoufox |
|--------|-------------------|----------|
| `navigator.webdriver` | `true` (detectable) | `false` (patched in C++) |
| Canvas fingerprint | Consistent/blocked | Randomized per session |
| WebGL renderer | VM/headless patterns | Realistic GPU strings |
| AudioContext | Silent/missing | Normal audio fingerprint |
| Font enumeration | Limited set | OS-appropriate font list |
| Screen resolution | Default 800x600 | Realistic values |
| Timezone | UTC/mismatch | Matches IP geolocation |
| Language | `en-US` only | Matches locale settings |

### Network Level
| Signal | Standard | Camoufox |
|--------|----------|----------|
| WebRTC leak | Exposes real IP | Blocked (`blockWebrtc`) |
| TLS fingerprint | Automation-like | Firefox-authentic |
| HTTP/2 settings | Chrome patterns | Firefox patterns |

### Behavioral
| Signal | Standard | Camoufox |
|--------|----------|----------|
| Mouse movements | Instant teleport | Human-like curves (`humanize`) |
| Click timing | 0ms delay | Randomized human delay |
| Scroll behavior | Instant | Smooth, variable speed |
| Typing speed | Instant | Character-by-character |

## Configuration

### Humanization

The `humanize` parameter controls human-like interaction timing:
- `0` — disabled (fastest, most detectable)
- `0.5` — default (balanced)
- `1.0` — maximum (slowest, least detectable)

### Headless vs Headed

- **Headless** (`CAMOFOX_HEADLESS=true`): No visible window, resource efficient
- **Headed** (`CAMOFOX_HEADLESS=false`): Visible window, useful for debugging

Camoufox headless mode patches headless detection signals that other browsers leak.

### Proxy

Route traffic through proxy for IP-level anti-detection:

```bash
HTTPS_PROXY=socks5://127.0.0.1:1080 camofox open https://example.com
```

With proxy + `geoip: true`, Camoufox auto-matches timezone/locale to the proxy's geolocation.

## Detection Test Sites

| Site | What It Tests |
|------|--------------|
| https://bot.sannysoft.com/ | Comprehensive bot detection |
| https://browserleaks.com/ | Browser fingerprint details |
| https://pixelscan.net/ | Fingerprint consistency |
| https://abrahamjuliot.github.io/creepjs/ | Advanced fingerprinting |

## Comparison with Other Anti-Detection

| Feature | Camoufox | Puppeteer Stealth | Playwright | undetected-chromedriver |
|---------|----------|-------------------|------------|----------------------|
| Engine | Firefox (C++ patched) | Chromium (JS patches) | Chromium | Chromium (binary patch) |
| Detection surface | Minimal | Moderate | High | Low-moderate |
| `navigator.webdriver` | C++ patched | JS override (detectable) | Detectable | Binary patched |
| Canvas spoof | C++ level | JS hook (detectable) | None | None |
| WebGL spoof | C++ level | Partial | None | None |
| TLS fingerprint | Firefox | Chrome | Chrome | Chrome |
| Maintenance burden | Low (engine-level) | High (cat-and-mouse) | N/A | High |
