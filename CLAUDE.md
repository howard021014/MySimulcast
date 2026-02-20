# MySimulcast Project Guidelines

## Project Overview

MySimulcast is a personal iOS utility app for tracking anime simulcasts. It allows users to browse seasonal anime, mark favorites, and receive notifications when new episodes air.

**Core Functionality:**
- Browse anime by season (winter/spring/summer/fall)
- Favorite shows for quick access
- Receive local notifications when favorited shows air
- View anime details, cover images, and airing schedules

**Tech Stack:**
- Language: Swift
- UI: SwiftUI
- Storage: SwiftData
- API: AniList GraphQL via Apollo iOS
- Min OS: iOS 17+
- Concurrency: Swift Concurrency (async/await)
- Testing: Swift Testing framework
- Package Manager: Swift Package Manager (SPM)

## Architecture Principles

This project follows **Clean Architecture** with strict layer separation:

**Layers:** Presentation → Domain → Data → Infrastructure

### Critical Dependency Rules

> **The most important constraint:** ViewModels only call Use Cases. Use Cases only talk to Repository Protocols. Repository implementations are injected at the composition root. Nothing in Domain imports SwiftUI or SwiftData.

**Layer Dependencies:**
- **Presentation**: Can import Domain only (never Data or Infrastructure directly)
- **Domain**: Zero framework dependencies (no SwiftUI, no SwiftData, pure Swift)
- **Data**: Can import Domain (implements protocols defined there)
- **Infrastructure**: Can import Domain

**Composition Root:**
- Dependency injection happens in the app entry point
- Repositories are instantiated and injected into Use Cases
- Use Cases are injected into ViewModels

**Architecture Violation Detection:**
- Import statements reveal violations immediately
- If Domain imports SwiftUI or SwiftData = ERROR
- If ViewModels directly import Data layer = ERROR

## Folder Structure

```
MySimulcast/
├── Presentation/
│   ├── Views/           # SwiftUI views
│   ├── ViewModels/      # ObservableObject classes
│   └── Coordinators/    # Navigation (TabView)
├── Domain/
│   ├── Models/          # Plain Swift structs (Anime, Season, etc.)
│   ├── UseCases/        # Business logic
│   └── RepositoryProtocols/  # Protocol definitions
├── Data/
│   ├── Repositories/    # Protocol implementations
│   ├── Network/         # Apollo GraphQL client wrapper
│   └── Persistence/     # SwiftData models & store
└── Infrastructure/
    ├── Notifications/   # NotificationManager
    ├── Network/         # NetworkMonitor
    └── Utilities/       # Logger, extensions
```

## Data Models

### Architecture

This project maintains **two separate model layers**:

1. **Apollo-Generated Types** (Data layer)
   - Auto-generated from GraphQL schema
   - Live in `Data/Network/` directory
   - Used for API communication only

2. **Domain Models** (Domain layer)
   - Plain Swift structs (e.g., `Anime`, `Season`, `AiringSchedule`, `SimulcastSeason`)
   - Live in `Domain/Models/` directory
   - Used throughout the app's business logic and presentation

### Model Guidelines

- Domain models are **plain Swift structs** separate from Apollo types
- Conform to `Codable`, `Identifiable` where needed
- No SwiftUI or SwiftData types in Domain layer
- Repository implementations map between Apollo types and domain models
- Data layer may use separate SwiftData models for persistence

## AniList API & Apollo iOS

### API Details

- **Endpoint:** `https://graphql.anilist.co`
- **Client:** Apollo iOS framework for type-safe GraphQL queries
- **Authentication:** None required (public API)

### Apollo Configuration

- Apollo generates Swift types from GraphQL schema
- Use in-memory normalized cache
- Configure schema download and code generation after SPM setup

### Data Handling

- `airingAt` returns Unix timestamp in UTC
- Convert via `Date(timeIntervalSince1970:)`
- iOS handles timezone display automatically - no JST conversion needed
- Fetch triggers: first launch, or 1st of Jan/Apr/Jul/Oct

### GraphQL Query Strategy

- Fetch seasonal anime with airing schedules
- Include fields: id, title, coverImage (extraLarge, large), description, nextAiringEpisode
- Paginate if needed (AniList returns max 50 per page)

## Image Loading

**Custom implementation required** (no third-party libraries):

- Use `URLSession` for downloading
- `NSCache` for memory caching
- `FileManager` for disk persistence
- Async image loading with SwiftUI integration
- Thumbnail vs full cover image support

## Notifications

### Permission Timing

- **Never** ask on cold launch
- Request permission on **first favorite** only
- Show pre-permission prompt before system dialog

### Scheduling

- Notification time: **8pm in `TimeZone.current`**
- Schedule when user favorites a show
- Cancel when user unfavorites
- Re-schedule on timezone change (detect on app foreground)

### Implementation

- Use `UNUserNotificationCenter` (local notifications only)
- Notification content: "{Anime Title} Episode {N} airing now!"
- Badge, sound, and banner configured per iOS standards

## Coding Standards

### File Naming

- PascalCase for types: `FetchSimulcastSeasonUseCase.swift`
- Descriptive names that reflect purpose
- Test files: `{TypeName}Tests.swift`

### Code Style

- **Minimal comments**: Only for complex logic
- Prefer self-documenting code and clear naming
- Use SwiftLint with relaxed rules (see `.swiftlint.yml`)

### Swift Style

- Prefer `@Observable` over `ObservableObject`
- Use `async/await` for all async operations
- Follow Apple's Swift API Design Guidelines
- Use `guard` for early exits
- Prefer value types (structs) over reference types (classes)

### SwiftUI Patterns

- Extract views when they exceed 100 lines
- Use `@State` for local view state only
- Use `@Environment` for dependency injection
- Prefer `NavigationStack` over deprecated `NavigationView`
- Use `@Bindable` for bindings to @Observable objects

### Navigation Pattern
```swift
// Use NavigationStack with type-safe routing
enum Route: Hashable {
    case detail(Item)
    case settings
}

NavigationStack(path: $router.path) {
    ContentView()
        .navigationDestination(for: Route.self) { route in
            // Handle routing
        }
}
```
 
### Simplicity Rules

- **No over-engineering**: Don't add abstractions, error handling, or features beyond what's requested
- **No backwards compatibility hacks**: Delete unused code completely (no `_unused`, no re-exports, no `// removed` comments)
- **No premature optimization**: Three similar lines > premature abstraction
- **Validate at boundaries only**: User input and external APIs, not internal code

### Security

- No command injection, XSS, SQL injection, or OWASP vulnerabilities
- Validate external API responses
- Handle sensitive data appropriately

## Testing Requirements

### Framework

Use **Swift Testing** framework (modern Apple testing):
- `@Test` macro for test functions
- `@Suite` for grouping related tests
- Better async/await support
- Cleaner syntax than XCTest
- Parameterized tests support

### Coverage Requirements

**Mandatory unit tests for ALL layers:**

1. **Domain (Use Cases)** - business logic
2. **ViewModels** - presentation logic and state
3. **Repository Implementations** - data layer
4. **Infrastructure** - NotificationManager, NetworkMonitor, utilities

### Testing Strategy

- Mock repositories for testing Use Cases (protocol-based)
- Mock Use Cases for testing ViewModels
- Focus on behavior, not implementation details
- Test async operations properly with Swift Testing
- Use meaningful test names that describe behavior

## Development Workflow

### Feature Implementation Order

1. **Start in Domain:**
   - Define models (plain Swift structs)
   - Create repository protocols
   - Implement use cases

2. **Move to Data:**
   - Implement repository protocols
   - Create SwiftData models if needed
   - Set up Apollo queries

3. **Build Presentation:**
   - Create ViewModels (inject use cases)
   - Build SwiftUI views
   - Wire up navigation

### Dependency Addition

- Use Swift Package Manager (SPM) exclusively
- Apollo iOS is the only external dependency
- Add packages via Xcode → File → Add Package Dependencies

### Architecture Enforcement

- Review import statements in each file
- Domain layer should NEVER import framework code
- ViewModels should only import Domain
- Test files can import both Domain and implementation layers

## Build and Run Configuration

Use the XcodeBuildMCP and Apple Xcode MCP tools to build and search for Apple APIs:
1. List available simulators and boot an iPhone 17 Pro
2. Build and run the project for that simulator

## SwiftLint Configuration

Relaxed rules focusing on critical issues:

**Disabled:**
- Overly strict line length rules
- Pedantic whitespace enforcement

**Enabled:**
- Force unwrapping warnings
- Cyclomatic complexity checks
- Large tuple detection
- Critical code smells

See `.swiftlint.yml` for full configuration.

## Critical Reminders

1. Domain layer must remain pure Swift (no frameworks)
2. Use dependency injection at composition root
3. All layers require unit tests
4. Request notification permission only on first favorite
5. Use Apollo iOS for GraphQL (not manual URLSession)
6. Use Swift Testing framework (not XCTest)
7. Keep code simple - don't over-engineer
8. Delete unused code completely
