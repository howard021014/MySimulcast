# MySimulcast

A personal iOS app for tracking anime simulcasts. Browse seasonal anime, mark favorites, and get notified when new episodes air.

## Features

- Browse anime by season (Winter/Spring/Summer/Fall)
- Favorite shows for quick access
- Local notifications when favorited shows air
- View cover images, episode details, and airing schedules

## Tech Stack

- Swift / SwiftUI
- SwiftData (persistence)
- Apollo iOS (AniList GraphQL API)
- Swift Concurrency (async/await)
- Swift Testing
- Swift Package Manager

**Requirements:** Xcode 26+, iOS 17+. No API key required — AniList is a public API.

## Setup

1. Clone the repo
2. Open `MySimulcast.xcodeproj` in Xcode
3. Xcode resolves the Apollo iOS SPM dependency automatically
4. Build and run on a simulator or device

To regenerate Apollo code after schema/query changes:

```bash
./apollo-ios-cli generate --path apollo-codegen-config.json
```
