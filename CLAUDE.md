# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build Commands
```bash
# Build Debug configuration
xcodebuild -project Celestoria/Celestoria.xcodeproj -scheme Celestoria -configuration Debug build

# Build Release configuration  
xcodebuild -project Celestoria/Celestoria.xcodeproj -scheme Celestoria -configuration Release build

# Clean build folder
xcodebuild clean -project Celestoria/Celestoria.xcodeproj

# Build for visionOS Simulator
xcodebuild -project Celestoria/Celestoria.xcodeproj -scheme Celestoria -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

# Build for iOS Simulator
xcodebuild -project Celestoria/Celestoria.xcodeproj -scheme Celestoria-iOS -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Resolve package dependencies
xcodebuild -resolvePackageDependencies -project Celestoria/Celestoria.xcodeproj

# Build RealityKit content package
cd Celestoria/Packages/RealityKitContent && swift build
```

### Development Notes
- No test targets exist in the project
- No linting tools are configured
- Environment variables are managed through Debug.xcconfig and Release.xcconfig files

## High-Level Architecture

### Project Overview
Celestoria is a Spatial Video Social Network for Apple Vision Pro that displays user memories as 3D "stars" in an immersive galaxy environment. The app recently added iOS support while maintaining its primary focus on visionOS.

**Target Configuration:**
- **visionOS Target**: `Celestoria` (Bundle ID: `com.Celestoria.Celestoria`)
- **iOS Target**: `Celestoria-iOS` (Bundle ID: `com.Celestoria.Celestoria`)
- Both targets share the same bundle ID and Info.plist file

### Architecture Pattern
The codebase follows **MVVM + Clean Architecture** with clear separation of concerns:

1. **Presentation Layer** (`Celestoria/Presentation/`)
   - Views: SwiftUI views for UI
   - ViewModels: Business logic for views, injected via DIContainer
   - Follows reactive patterns with @StateObject and @ObservedObject

2. **Domain Layer** (`Celestoria/Domain/`)
   - Entities: Core business models (Memory, User, etc.)
   - UseCases: Business rules and operations
   - Repository Protocols: Interfaces for data access

3. **Data Layer** (`Celestoria/Data/`)
   - Repository implementations using Supabase
   - Handles authentication, database operations, and storage

4. **Dependency Injection**
   - Centralized DIContainer manages all dependencies
   - Initialized in App entry points (CelestoiraApp.swift, iOSCelestoiraApp.swift)
   - ViewModels and repositories are injected, not instantiated directly
   - All dependencies initialized with proper error handling

### Key Components

**App Entry Points:**
- `CelestoiraApp.swift`: visionOS app with immersive space support
- `iOSCelestoiraApp.swift`: iOS app with basic functionality

**State Management:**
- `AppState.swift`: Centralized state management for the entire app
- Replaced AppModel with AppState for unified state handling
- All ViewModels reference AppState as single source of truth

**Core Features:**
- **Memory Management**: Create, position, and manage spatial video memories
- **Immersive Experience**: Full 3D space with RealityKit entities
- **Social Features**: User profiles, likes, explore functionality
- **Authentication**: Apple Sign-In via Supabase Auth

**Platform Differences:**
- visionOS: Full immersive space, 3D positioning, spatial video playback
- iOS: 2D interface, basic memory viewing and management

### External Dependencies
- **Supabase**: Complete backend (Auth, Database, Storage, Realtime)
- **RealityKit**: 3D rendering and spatial experiences
- **ARKit**: Spatial tracking and interactions

### Data Flow
1. User actions trigger ViewModel methods
2. ViewModels call UseCases or Repositories through DIContainer
3. Repositories interact with Supabase services
4. State updates flow through AppState (@Published properties)
5. Views update automatically via SwiftUI bindings

### Recent Refactoring Changes
- **Removed AppModel**: Migrated all functionality to AppState
- **Simplified SpaceCoordinator**: Now acts purely as a coordinator, delegating to SpaceEntity
- **Safe Initialization**: Removed all force unwrapping, added proper optional handling
- **Performance Optimization**: Added duplicate update prevention in background management

### Important Patterns
- Always use DIContainer for dependency resolution
- ViewModels should be @StateObject in parent views
- Use @EnvironmentObject for app-wide state (AppState)
- Spatial positioning uses random placement within bounds
- Memory categories: Family, Travel, Pet, Entertainment
- Always check for nil ViewModels before rendering views
- Use if-let binding instead of force unwrapping

### Configuration
- Environment variables in Debug/Release.xcconfig files
- Sensitive data (API keys) injected via Info.plist
- Backend services: Supabase, B2 Storage, Cloudflare

### iOS-Specific Setup Requirements

**Apple Sign-In Configuration:**
1. **URL Scheme**: Added `com.Celestoria.Celestoria` to Info.plist for OAuth callbacks
2. **Supabase Redirect**: DIContainer configured with `redirectToURL: "com.Celestoria.Celestoria://login-callback"`
3. **Capabilities Required**:
   - Sign in with Apple capability must be enabled in Xcode
   - Provisioning Profile must support Sign in with Apple entitlement
   - Entitlements file (`Celestoria.entitlements`) must be linked in build settings

**Common Issues:**
- If Apple Sign-In fails with error `-7026`, check:
  - Apple Developer account has agreed to latest Program License Agreement
  - Sign in with Apple capability is properly added to iOS target
  - Provisioning Profile supports the required entitlements
  - Bundle ID matches everywhere (Info.plist, project settings, URL schemes)