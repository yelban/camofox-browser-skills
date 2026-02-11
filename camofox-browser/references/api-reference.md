# camofox-browser REST API Reference

Base URL: `http://localhost:9377` (configurable via `CAMOFOX_PORT`)

## Endpoints

### GET /health

Health check.

```bash
curl http://localhost:9377/health
# → {"status":"ok"}
```

---

### POST /tabs

Create a new browser tab.

**Body:**
```json
{
  "userId": "camofox-default",
  "sessionKey": "default",
  "url": "https://example.com"
}
```

**Response:**
```json
{
  "tabId": "abc123",
  "url": "https://example.com"
}
```

- `userId` — isolates browser context (cookies, storage)
- `sessionKey` — groups tabs within a user
- `url` — optional, navigates immediately if provided

---

### GET /tabs?userId=X

List all tabs for a user.

```bash
curl "http://localhost:9377/tabs?userId=camofox-default"
```

**Response:**
```json
[
  {"tabId": "abc123", "url": "https://example.com"},
  {"tabId": "def456", "url": "https://google.com"}
]
```

---

### DELETE /tabs/:tabId

Close a specific tab.

```bash
curl -X DELETE "http://localhost:9377/tabs/abc123?userId=camofox-default"
```

---

### DELETE /sessions/:userId

Close all tabs for a user session.

```bash
curl -X DELETE "http://localhost:9377/sessions/camofox-default"
```

---

### POST /tabs/:tabId/navigate

Navigate to URL or use search macro.

**URL navigation:**
```json
{
  "userId": "camofox-default",
  "url": "https://example.com"
}
```

**Macro navigation:**
```json
{
  "userId": "camofox-default",
  "macro": "@google_search",
  "query": "best coffee beans"
}
```

---

### GET /tabs/:tabId/snapshot?userId=X

Get accessibility snapshot with element refs.

```bash
curl "http://localhost:9377/tabs/abc123/snapshot?userId=camofox-default"
```

**Response:**
```json
{
  "snapshot": "[button e1] Submit  [link e2] Learn more  [input e3] Email",
  "refs": {
    "e1": {"role": "button", "name": "Submit"},
    "e2": {"role": "link", "name": "Learn more"},
    "e3": {"role": "textbox", "name": "Email"}
  },
  "url": "https://example.com"
}
```

- `snapshot` — text representation, 90% smaller than HTML
- `refs` — stable element refs (`e1`, `e2`, ...) for interaction
- Refs are invalidated on page navigation

---

### POST /tabs/:tabId/click

Click element by ref.

```json
{
  "userId": "camofox-default",
  "ref": "e1"
}
```

Note: Send `e1` not `@e1` — the `@` prefix is for the CLI only.

---

### POST /tabs/:tabId/type

Type text into element.

```json
{
  "userId": "camofox-default",
  "ref": "e3",
  "text": "hello@example.com"
}
```

---

### POST /tabs/:tabId/scroll

Scroll the page.

```json
{
  "userId": "camofox-default",
  "direction": "down"
}
```

Directions: `down`, `up`, `left`, `right`

---

### POST /tabs/:tabId/back

Navigate back in history.

```json
{"userId": "camofox-default"}
```

---

### POST /tabs/:tabId/forward

Navigate forward in history.

```json
{"userId": "camofox-default"}
```

---

### POST /tabs/:tabId/refresh

Reload the page.

```json
{"userId": "camofox-default"}
```

---

### GET /tabs/:tabId/links?userId=X

Get all links on the page.

```bash
curl "http://localhost:9377/tabs/abc123/links?userId=camofox-default"
```

---

### GET /tabs/:tabId/screenshot?userId=X

Capture screenshot as raw PNG binary.

```bash
curl -o screenshot.png "http://localhost:9377/tabs/abc123/screenshot?userId=camofox-default"
```

**Response:** Raw PNG binary (not JSON). Save directly to file with `curl -o`.
```

## Session Architecture

```
Browser Instance (single, shared)
└── BrowserContext (per userId — isolated cookies/storage)
    ├── Tab Group (sessionKey: "conv1")
    │   ├── Tab (google.com)
    │   └── Tab (github.com)
    └── Tab Group (sessionKey: "conv2")
        └── Tab (amazon.com)
```

- One browser instance shared across all users
- Each `userId` gets an isolated `BrowserContext` (separate cookies, storage)
- Tabs grouped by `sessionKey` within a user
- 30-minute session timeout, auto-cleanup
