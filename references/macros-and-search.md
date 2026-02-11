# Search Macros

## Available Macros (13)

| Macro | Short Name | URL Pattern |
|-------|-----------|-------------|
| `@google_search` | `google` | `https://www.google.com/search?q=...` |
| `@youtube_search` | `youtube` | `https://www.youtube.com/results?search_query=...` |
| `@amazon_search` | `amazon` | `https://www.amazon.com/s?k=...` |
| `@reddit_search` | `reddit` | `https://www.reddit.com/search/?q=...` |
| `@wikipedia_search` | `wikipedia` | `https://en.wikipedia.org/w/index.php?search=...` |
| `@twitter_search` | `twitter` | `https://twitter.com/search?q=...` |
| `@yelp_search` | `yelp` | `https://www.yelp.com/search?find_desc=...` |
| `@spotify_search` | `spotify` | `https://open.spotify.com/search/...` |
| `@netflix_search` | `netflix` | `https://www.netflix.com/search?q=...` |
| `@linkedin_search` | `linkedin` | `https://www.linkedin.com/search/results/all/?keywords=...` |
| `@instagram_search` | `instagram` | `https://www.instagram.com/explore/tags/...` |
| `@tiktok_search` | `tiktok` | `https://www.tiktok.com/search?q=...` |
| `@twitch_search` | `twitch` | `https://www.twitch.tv/search?term=...` |

## Usage

### CLI (short names)

```bash
camofox search google "best coffee beans"
camofox search youtube "cooking tutorial"
camofox search amazon "wireless headphones"
camofox search reddit "programming tips"
```

Short names auto-expand: `google` → `@google_search`

### CLI (full macro names)

```bash
camofox search @google_search "best coffee beans"
```

### Direct API Call

```bash
curl -X POST http://localhost:9377/tabs/TAB_ID/navigate \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "camofox-default",
    "macro": "@google_search",
    "query": "best coffee beans"
  }'
```

## Workflow Example

```bash
# Search Google with anti-detection
camofox open https://google.com
camofox search google "site:github.com camoufox"
camofox snapshot
# → @e1 [link] "Result 1"  @e2 [link] "Result 2" ...

# Click a result
camofox click @e1
camofox snapshot  # Re-snapshot on new page

# Search YouTube
camofox search youtube "browser fingerprinting explained"
camofox snapshot
```

## Notes

- Macros navigate the active tab (or create one if none exists)
- Search results page loads with full anti-detection
- After searching, use `snapshot` to see results and interact
- Some sites (Netflix, Spotify) require authentication after search
