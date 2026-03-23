# 🎌 Anime App — Product Requirements Document

**Version:** 1.1 | **Date:** 2026-02-17 | **Status:** Final Draft

---

## Executive Summary

Anime App is a personal iOS utility that solves a simple but recurring problem: keeping track of which anime are currently airing in simulcast, when new episodes drop, and never missing an episode of a favourited show. It fetches seasonal simulcast data from AniList's GraphQL API, persists it locally, and schedules local push notifications for favourited titles. It is a focused, single-user app with no backend, no auth, and no social features — built with SwiftUI, SwiftData, and Swift Concurrency following Clean Architecture principles.

---

## Goals & Non-Goals

**Goals**
- Let the user browse the current simulcast season and past seasons
- Let the user favourite shows and have them persist reliably
- Let the user search for any anime by title
- Notify the user at 8pm local time on the day a favourited show airs
- Work offline using cached data when no internet is available

**Non-Goals**
- User accounts, authentication, or sync across devices
- Social features: sharing, reviews, ratings
- Video playback or streaming links
- Server-side logic or a custom backend
- Auto-complete in search
- Android or web versions

---

## User Stories & Acceptance Criteria

### Feature 1 — Simulcast Browser

**US-01: Browse current simulcast season**
As a user, I want to see all currently airing anime so I know what's available this season.

*Acceptance Criteria:*
- On first launch, app fetches simulcast data from AniList and displays it
- Each anime card shows: cover image, title, next airing day/time
- Cards are displayed in a 2-column grid
- A season category pill (e.g. "Winter 2026") is shown at the top, defaulting to the current season
- If fetch fails on first launch, a full empty state is shown with an error message and "Try Again" button
- Data is re-fetched automatically on the 1st of Jan, Apr, Jul, Oct

**US-02: Browse past simulcast seasons** *(V1)*
As a user, I want to scroll back through past seasons so I can discover shows I may have missed.

*Acceptance Criteria:*
- Season pills are ordered newest → oldest (e.g. Winter 2026 → Fall 2025 → ...)
- Swiping the content area left/right switches seasons (page-style)
- Tapping a pill also navigates to that season
- When a new season begins, it is automatically prepended and selected

---

### Feature 2 — Favourites

**US-03: Favourite a show**
As a user, I want to mark a show as a favourite so I can track it separately and get notified.

*Acceptance Criteria:*
- Each card has a heart icon in the top-right corner
- Tapping the heart toggles favourite state immediately (optimistic UI)
- Favourited state persists across app launches via SwiftData
- Favouriting a show triggers notification scheduling (see Feature 4)
- Unfavouriting cancels any pending notifications for that show

**US-04: Browse favourites**
As a user, I want a dedicated favourites tab so I can see all my tracked shows in one place.

*Acceptance Criteria:*
- Favourites tab shows all favourited anime in a 2-column card grid
- An "All" pill is pinned on the left; additional pills group favourites by season
- If no favourites exist, empty state: *"No favourites yet. Tap ❤️ on any show to add one."*
- Favourited shows are never evicted from cache regardless of age

---

### Feature 3 — Search

**US-05: Search for anime**
As a user, I want to search for any anime by title so I can find shows not in the current simulcast.

*Acceptance Criteria:*
- Search bar is always visible at the top of the Search tab
- Results appear in the same screen as the search bar (no separate results page)
- Results are paginated with infinite scroll and intelligent prefetching
- No auto-complete; results update on explicit search submission
- If no results found: inline empty state *"No results for '[query]'"*
- If search fails due to no internet: inline error below search bar with "Try Again" button
- Each result card shows: cover image and title

---

### Feature 4 — Push Notifications

**US-06: Receive airing reminders**
As a user, I want to be notified at 8pm on the day a favourited show airs so I don't miss it.

*Acceptance Criteria:*
- When user favourites their first show, app checks `UNUserNotificationCenter` authorization status
- If `.notDetermined`: show a custom pre-permission half-sheet (before any system dialog) with the message *"Get notified at 8pm on the day each favourited show airs. You can turn this off anytime in Settings."* and two buttons: "Enable Notifications" and "Not Now"
- Tapping "Enable Notifications" triggers the system permission dialog
- Tapping "Not Now" dismisses the sheet silently with no further prompting
- If `.denied`: skip pre-prompt entirely; show a subtle inline banner *"Notifications are off. Enable them in Settings to get airing reminders."* with a deep link directly to the app's Settings page
- If permission is granted, notifications are scheduled locally via `UNUserNotificationCenter`
- Notification fires at 8pm in the user's current local timezone (`TimeZone.current`)
- Notification copy: *"[Show Title] airs today 🎌"*
- On app foreground, timezone is compared to stored timezone; if changed, all notifications are rescheduled
- Unfavouriting a show cancels its pending notifications immediately
- A toggle in Settings to disable all app notifications without revoking system permission

---

### Feature 5 — Offline & Error Handling

**US-07: Use app offline**
As a user, I want to see content even when I have no internet so the app is always useful.

*Acceptance Criteria:*
- If internet is unavailable but cache exists: show cached content with a subtle top banner *"Content may be outdated"*
- If internet is unavailable and no cache exists: full empty state with error message and "Try Again" button
- Retry uses silent exponential backoff under the hood; user only sees a "Try Again" button
- Search is disabled offline: inline message *"Search requires an internet connection"*

---

### Feature 6 — Card Interactions

**US-08: Interact with anime cards**
As a user, I want cards to feel responsive and let me quickly read a show's description without leaving the screen.

*Acceptance Criteria:*
- **Press feedback:** touching down on a card scales it to 0.96 with a spring animation; releases back to 1.0 on lift — gives immediate tactile acknowledgment
- **Flip:** tap triggers a `rotation3DEffect` flip on the Y axis revealing the card's back face; front face exits before back face enters (0.35s staggered delay) to avoid see-through artifact
- **Back face content:** show title + max 3 lines of description truncated with ellipsis + a "Details" chevron
- **Flip back:** tapping the flipped card again flips it back to the front face
- **Details sheet:** tapping the "Details" chevron opens a system `sheet` (bottom drawer) with full description (scrollable), airing schedule, and favourite toggle; dismissable by swipe down
- **Loading state:** while images are loading, cards display an animated shimmer placeholder (LinearGradient sweeping left to right) — no blank/grey boxes
- **Appear animation:** on grid first load, cards animate in with a spring stagger, each card offset by its index (subtle upward slide) *(V1 polish)*
- All touch targets minimum 44×44pt per HIG
- No hover effects (iPhone only; hover requires pointer device per HIG)

---

## Technical Constraints

| Concern | Decision |
|---------|----------|
| **Language** | Swift |
| **UI Framework** | SwiftUI |
| **Concurrency** | Swift Concurrency (async/await) |
| **Local Storage** | SwiftData |
| **Min OS Version** | iOS 17+ |
| **External API** | AniList GraphQL — [docs](https://docs.anilist.co/guide/introduction) |
| **Image Loading** | Custom: URLSession + NSCache + FileManager |
| **Architecture** | MVVM + Clean Architecture (single Xcode target, folder-separated layers) |
| **Notifications** | UNUserNotificationCenter (local only, no APNs) |

---

## Architecture Overview

Three layers, enforced by folder structure within a single Xcode target:

**Presentation** — SwiftUI Views + ViewModels + AppCoordinator (TabView navigation)

**Domain** — Use Cases, Repository Protocols (Swift protocols), plain Swift model structs with zero framework dependencies

**Data** — Repository implementations, AniList GraphQL client (URLSession), SwiftData local store, image cache (NSCache + FileManager)

**Infrastructure** — NotificationManager, NetworkMonitor, Logger

The most important constraint: ViewModels only call Use Cases. Use Cases only talk to Repository Protocols. Repository implementations are injected at the composition root. Nothing in Domain imports SwiftUI or SwiftData.

---

## Data Model

```swift
struct Anime: Identifiable, Codable {
    let id: Int
    let title: String
    let coverImageURL: URL
    let thumbnailImageURL: URL?
    let description: String
    let airingSchedule: AiringSchedule
    var isFavourited: Bool
}

struct AiringSchedule: Codable {
    let nextEpisode: Int
    let nextAiringAt: Date    // converted from AniList's airingAt Unix timestamp (UTC)
}

// Usage: derive day of week and notification date from nextAiringAt at runtime
// e.g. Calendar.current.component(.weekday, from: airingSchedule.nextAiringAt)

enum Season: String, Codable, CaseIterable {
    case winter, spring, summer, fall
}

struct SimulcastSeason: Identifiable, Codable {
    let id: String            // e.g. "winter-2026"
    let season: Season
    let year: Int
    var anime: [Anime]
    let fetchedAt: Date
}
```

> **Note:** AniList's `nextAiringEpisode` returns only `airingAt` (Unix timestamp in UTC), `timeUntilAiring` (seconds, a convenience field), and `episode`. There is no JST field — `airingAt` already encodes the exact global airing moment. Convert to `Date` via `Date(timeIntervalSince1970: airingAt)` and let iOS handle timezone display and notification scheduling automatically.

---

## API Contract

**Source:** AniList GraphQL — `https://graphql.anilist.co`

**Fetch trigger:** App first launch, or on the 1st of Jan / Apr / Jul / Oct

**Key query — fetch simulcast season:**
```graphql
query SimulcastSeason($season: MediaSeason, $year: Int) {
  Page {
    media(season: $season, seasonYear: $year, type: ANIME, format: TV) {
      id
      title { romaji english }
      coverImage { large medium }
      description
      nextAiringEpisode {
        episode
        airingAt
        timeUntilAiring
      }
    }
  }
}
```

**Search query:**
```graphql
query SearchAnime($query: String, $page: Int) {
  Page(page: $page, perPage: 20) {
    media(search: $query, type: ANIME) {
      id
      title { romaji english }
      coverImage { medium }
    }
    pageInfo { hasNextPage currentPage }
  }
}
```

---

## Caching Strategy

| Data | Storage | Eviction |
|------|---------|----------|
| Anime metadata | SwiftData + NSCache | Non-favourited entries older than current season eligible for eviction |
| Favourited anime | SwiftData | Never evicted, user must unfavourite |
| Thumbnail images | FileManager (disk) | Evicted when parent anime is evicted |
| Full-res images (favourited) | FileManager (disk) | Never evicted |
| Decoded images (visible) | NSCache (memory) | Evicted by system under memory pressure |

---

## UI Spec

### Navigation
- `TabView` with 3 tabs: **Simulcast**, **Favourites**, **Search**
- Tab order is fixed; icons use SF Symbols

### Simulcast & Favourites Screens
- 2-column `LazyVGrid` of anime cards
- Card front: cover image, title, next airing time, heart icon top-right
- Card back: title, 3-line truncated description, "Details" chevron
- Card interactions: press → scale to 0.96 spring; tap → Y-axis flip via `rotation3DEffect`; loading → shimmer placeholder
- Season pills: horizontal scroll, `ScrollView(.horizontal)`, page-style swipe on content
- Loading state: shimmer skeleton cards (LinearGradient sweep animation)
- All touch targets minimum 44×44pt per HIG

### Search Screen
- Persistent search bar at top (`.searchable` modifier)
- Results in same view, infinite scroll with prefetch
- Offline / empty / error states shown inline below search bar

### Detail Sheet
- System `sheet` presentation (bottom drawer)
- Content: full-size cover image, full description (scrollable), airing schedule, favourite toggle
- Dismissable by swipe down or tap outside

### Notification Pre-Permission Sheet
- Custom half-sheet presented on first favourite (if status is `.notDetermined`)
- Shows app icon, explanation copy, "Enable Notifications" (primary) and "Not Now" (secondary) buttons
- "Enable Notifications" → triggers system `UNUserNotificationCenter.requestAuthorization()`

### HIG Compliance Notes
- Tab bar is navigation only — no action buttons in the tab bar
- Notification permission requested contextually on first favourite, never on cold launch
- Pre-permission prompt provides clear user benefit before system dialog
- SF Symbols used for all iconography
- Dynamic Type supported on all text elements
- Dark Mode supported via system colors (no hardcoded hex values)
- No hover effects — iPhone only, hover requires pointer device

---

## Feature / Task List

| Task | Description | Status |
|------|-------------|--------|
| **Feature 1 — Simulcast Browser** | | |
| US-01: Browse current simulcast season | Fetch & display current season anime in 2-col grid with season pill | Done |
| US-02: Browse past simulcast seasons | Swipeable past seasons with pill navigation, organic accumulation | Done |
| **Feature 2 — Favourites** | | |
| US-03: Favourite a show | Heart toggle, SwiftData persistence, notification scheduling on favourite | Done |
| US-04: Browse favourites | Dedicated tab with season filter pills, empty state, sorted display | Done |
| **Feature 3 — Search** | | |
| US-05: Search for anime | Search tab with debounce, pagination, offline detection | Done |
| **Feature 4 — Push Notifications** | | |
| US-06: Receive airing reminders | 8pm local notifications, pre-permission sheet, timezone handling, settings toggle | Done |
| **Feature 5 — Offline & Error Handling** | | |
| US-07: Use app offline | NetworkMonitor, cache fallback, error states, retry with exponential backoff | Done |
| **Feature 6 — Card Interactions** | | |
| US-08: Card press feedback | Scale to 0.96 with spring animation on press | Done |
| US-08: Card flip animation | Y-axis rotation3DEffect flip with back face (title + description) | Done |
| US-08: Shimmer loading state | LinearGradient sweep animation placeholder while images load | Done |
| US-08: Detail sheet | Bottom sheet with full description, airing schedule, favourite toggle | Done |
| US-08: Appear animation (stagger) | Cards animate in with spring stagger on grid first load | Not Done |
| **Technical / Infrastructure** | | |
| AniList GraphQL client (Apollo iOS) | Apollo codegen, type-safe queries, pagination | Done |
| Custom image cache (NSCache + URLSession) | Memory cache with 200 image / 50MB limit | Done |
| TabView navigation (4 tabs) | Simulcast, Favourites, Search, Settings | Done |
| Clean Architecture | Domain pure Swift, DI at composition root, layer separation | Done |
| Unit test suite | 12 test files covering all layers with mocks (Swift Testing) | Done |
| Image disk persistence (FileManager) | Persistent disk cache for images | Done |
| Full-res image download for favourites | Download high-res images for favourited anime | Not Done |
| Intelligent prefetching in search | Prefetch next page before user reaches bottom | Not Done |

---

## Build Roadmap

### MVP — Core loop working end to end
- [x] AniList GraphQL client + fetch current season (Apollo iOS with codegen)
- [x] Simulcast browse screen (2-column grid, season pill, error states, "Last updated" subtitle)
- [x] Card interactions: press feedback + flip + shimmer loading state
- [x] SwiftData persistence for favourites (FavouriteEntry with airing schedule fields)
- [x] Favourites tab (2-column grid, season filter pills, empty state, schedule text per card)
- [x] Custom image cache (NSCache memory cache + URLSession loading)
- [x] TabView navigation (4 tabs: Simulcast, Favourites, Search, Settings)
- [x] Clean Architecture enforced (Domain layer pure Swift, DI at composition root, full test coverage)
- [x] Offline cache fallback + error states (NetworkMonitor, cache fallback, retry with backoff)

### V1 — Full feature set
- [x] Search with pagination
- [x] Detail bottom sheet
- [x] Local push notifications with pre-permission prompt + timezone handling
- [x] Notification settings toggle
- [x] Past seasons browsing

### V2 — Polish
- [ ] Full-res image download for favourites
- [x] Image disk persistence (FileManager)
- [ ] Intelligent prefetching in search
- [ ] Appear animation (spring stagger on grid load)

---

## Decisions Log

| Question | Decision | Rationale |
|----------|----------|-----------|
| Timezone for notifications? | `TimeZone.current` at scheduling time; re-schedule on foreground if timezone changed | Server time adds unnecessary complexity for a personal app. Clock manipulation is an acceptable edge case. |
| Retry UI? | "Try Again" button for user-visible errors; silent exponential backoff underneath | HIG: clear, actionable feedback. Exposing backoff timers adds anxiety, not value. |
| Card flip with long description? | Max 3-line truncation on flip; "Details" opens a bottom sheet | Cards are physically small in a 2-column grid. Sheet follows HIG pattern for supplementary content. |
| Architecture scale? | Full Clean Architecture in one Xcode target, folders not framework targets | Builds the right habits (protocol-based repos, testable domain) without unnecessary build complexity. |
| Hover effect on cards? | Not applicable — skipped | `.hoverEffect()` requires a pointer device; not available on iPhone. |
| Notification permission timing? | Pre-permission half-sheet on first favourite, then system dialog | HIG: always explain why before requesting. Never prompt on cold launch. |
| `airingTimeJST` in data model? | Removed — not needed and not returned by AniList | AniList returns `airingAt` as a UTC Unix timestamp. Convert to `Date` and derive everything from it at runtime. No JST handling needed. |
