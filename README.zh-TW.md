# camofox-browser-skills

[English](README.md) | [繁體中文](README.zh-TW.md)

為 [Claude Code](https://claude.com/claude-code) 打造的反偵測瀏覽器自動化 skill，基於 [Camoufox](https://camoufox.com/)——一款在 C++ 層級偽造指紋的 Firefox 分支。

當標準瀏覽器工具（Playwright、Puppeteer）被 Cloudflare、Akamai 等機器人偵測系統擋下時，這個 skill 讓 Claude Code 具備隱匿瀏覽能力。

## 安裝

```bash
# 安裝（全域，建議）
npx skills add yelban/camofox-browser-skills -s camofox-browser -g

# 安裝（專案層級）
npx skills add yelban/camofox-browser-skills -s camofox-browser

# 列出可用 skills
npx skills add yelban/camofox-browser-skills --list
```

首次使用時會自動下載並安裝 Camoufox 瀏覽器（約 300MB，僅需一次）。不需要手動設定——直接執行任何 `camofox` 指令即可。

## 為什麼選 Camoufox？

| 指紋訊號 | 一般自動化工具 | Camoufox |
|---------|-------------|----------|
| `navigator.webdriver` | `true`（可被偵測） | `false`（C++ 層級修補） |
| Canvas 指紋 | 固定/被封鎖 | 每次工作階段隨機化 |
| WebGL 渲染器 | VM/無頭模式特徵 | 擬真 GPU 字串 |
| AudioContext | 靜音/缺失 | 正常音訊指紋 |
| 字型列舉 | 有限集合 | 符合作業系統的字型清單 |
| TLS 指紋 | Chrome 模式 | Firefox 原生 |
| WebRTC | 洩漏真實 IP | 已封鎖 |

## 快速開始

```bash
camofox open https://example.com          # 開啟網址（自動啟動伺服器）
camofox snapshot                          # 取得頁面元素與 @refs
camofox click @e1                         # 點擊元素
camofox type @e2 "hello"                  # 輸入文字
camofox screenshot                        # 截圖
camofox close                             # 關閉分頁
```

## 核心流程

1. **導覽** — `camofox open <url>` 開啟分頁並導覽
2. **快照** — `camofox snapshot` 回傳無障礙樹，帶有 `@e1`、`@e2` 參照
3. **互動** — 用參照來點擊、輸入、選擇
4. **重新快照** — 頁面變動後，重新取得參照
5. **重複** — 伺服器在指令間持續運作

```bash
camofox open https://example.com/login
camofox snapshot
# @e1 [input] Email  @e2 [input] Password  @e3 [button] Sign In

camofox type @e1 "user@example.com"
camofox type @e2 "password123"
camofox click @e3
camofox snapshot  # 導覽後必須重新快照
```

## 指令一覽

### 導覽

```bash
camofox open <url>                   # 建立分頁 + 導覽（別名：goto）
camofox navigate <url>               # 在目前分頁導覽
camofox back                         # 上一頁
camofox forward                      # 下一頁
camofox refresh                      # 重新載入
camofox scroll down                  # 向下捲動（也支援：up, left, right）
```

### 頁面狀態

```bash
camofox snapshot                     # 無障礙快照，帶 @refs
camofox screenshot                   # 截圖至 /tmp/camofox-screenshots/
camofox screenshot output.png        # 截圖至指定路徑
camofox tabs                         # 列出所有開啟的分頁
```

### 互動

使用 snapshot 輸出的 `@refs`：

```bash
camofox click @e1                    # 點擊元素
camofox type @e1 "text"              # 在元素中輸入文字
```

### 搜尋巨集（共 13 個）

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

### 工作階段管理

```bash
camofox --session work open <url>    # 隔離的工作階段
camofox --session work snapshot      # 使用指定工作階段
camofox close                        # 關閉目前分頁
camofox close-all                    # 關閉工作階段中所有分頁
```

### 伺服器控制

```bash
camofox start                        # 啟動伺服器（通常自動）
camofox stop                         # 停止伺服器
camofox health                       # 健康檢查
```

## 何時使用這個工具

| 情境 | 工具 |
|------|------|
| 一般網站，無機器人偵測 | agent-browser / Playwright（較快） |
| Cloudflare / Akamai 保護的網站 | **camofox-browser** |
| 封鎖 Chromium 自動化的網站 | **camofox-browser** |
| 需要反指紋偵測 | **camofox-browser** |
| 需要 iOS/行動裝置模擬 | agent-browser |
| 需要錄影 | agent-browser |

## 環境變數

| 變數 | 預設值 | 說明 |
|------|-------|------|
| `CAMOFOX_PORT` | `9377` | 伺服器連接埠 |
| `CAMOFOX_SESSION` | `default` | 預設工作階段名稱 |
| `CAMOFOX_HEADLESS` | `true` | 無頭模式 |
| `HTTPS_PROXY` | — | 代理伺服器 |

## 疑難排解

**伺服器無法啟動？**

```bash
camofox health                        # 檢查是否在運作
camofox stop && camofox start         # 重新啟動
```

**仍然被封鎖？**

```bash
HTTPS_PROXY=socks5://127.0.0.1:1080 camofox open <url>
```

**機器人偵測測試：**

```bash
camofox open https://bot.sannysoft.com/
camofox screenshot bot-test.png
```

## 專案結構

```
camofox-browser-skills/
├── package.json
├── README.md
├── README.zh-TW.md
├── LICENSE
└── camofox-browser/
    ├── SKILL.md                      # Skill 定義
    ├── scripts/
    │   ├── setup.sh                  # 安裝腳本
    │   └── camofox.sh                # CLI 包裝（16 個指令）
    ├── references/
    │   ├── api-reference.md          # REST API 文件
    │   ├── anti-detection.md         # 指紋偽造細節
    │   └── macros-and-search.md      # 13 個搜尋巨集
    └── templates/
        ├── stealth-scrape.sh         # 反偵測爬取流程
        └── multi-session.sh          # 多工作階段隔離
```

## 授權

MIT
