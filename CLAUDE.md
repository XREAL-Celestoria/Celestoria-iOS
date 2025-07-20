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
- Both iOS and visionOS targets share the same Assets.xcassets and 3D model files
- iOS target requires manual addition of resources in Xcode (see iOS-Specific Setup)

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
- visionOS: Full immersive space with RealityKit, 3D positioning, spatial video playback
- iOS: SceneKit-based 3D view, touch-based interaction, standard video playback

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

### Recent Changes
- **iOS Support Added**: Full iOS target with SceneKit-based 3D galaxy view
- **Removed AppModel**: Migrated all functionality to AppState
- **Simplified SpaceCoordinator**: Now acts purely as a coordinator, delegating to SpaceEntity
- **Safe Initialization**: Removed all force unwrapping, added proper optional handling
- **Performance Optimization**: Added duplicate update prevention in background management
- **Asset Sharing**: Both platforms use the same image assets and 3D models

### Recent iOS UI Improvements (July 2025)
- **UserInfoModalView**: 
  - Fixed layout with Add button positioned in top-right corner using ZStack alignment
  - Profile and name on top row, stats (stars, comments, likes) on bottom row
  - Implemented real data fetching: memory count from repository, total likes calculated across user's memories
  - Comments always show 0 (feature not implemented)
- **MemoryDetailView**: 
  - Real-time like/unlike functionality with database integration
  - Like count updates immediately when toggled
  - Users cannot like their own memories
  - All stats fetched from actual database, no mock data
- **AddMemoryDoneView**: 
  - Updated design to match visionOS implementation
  - Improved star icon with gradient background and glow effect
  - Better text styling and spacing
  - Fixed navigation and modal presentation

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

**Resource Configuration:**
1. **Assets.xcassets**: Must be added to iOS target in Xcode
   - Select Assets.xcassets → File Inspector → Target Membership → Check `Celestoria-iOS`
2. **3D Models**: Must be added to iOS target for star rendering
   - Add these files to iOS target: `Enter.usdc`, `Family.usdz`, `Pet.usdz`, `Travel.usdc`
   - Location: `Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/Entities/`
3. **AppIcon**: iOS requires its own AppIcon set in Assets.xcassets

**Apple Sign-In Configuration:**
1. **URL Scheme**: Added `com.Celestoria.Celestoria` to Info.plist for OAuth callbacks
2. **Supabase Redirect**: DIContainer configured with `redirectToURL: "com.Celestoria.Celestoria://login-callback"`
3. **Capabilities Required**:
   - Sign in with Apple capability must be enabled in Xcode
   - Provisioning Profile must support Sign in with Apple entitlement
   - Entitlements file (`Celestoria.entitlements`) must be linked in build settings

**iOS Implementation Details:**
- **3D Rendering**: Uses SceneKit instead of RealityKit
- **Background**: Uses Starfield images from `selectedImage` property, not `spaceThumbnail`
- **Star Models**: Loads 3D models from bundle root (no subfolder path)
- **Touch Interaction**: Single tap to select stars (no double-tap zoom)
- **Video Playback**: Full-screen modal with AVKit VideoPlayer

**Common Issues:**
- If assets don't load, verify they're included in iOS target's Copy Bundle Resources
- If Apple Sign-In fails with error `-7026`, check:
  - Apple Developer account has agreed to latest Program License Agreement
  - Sign in with Apple capability is properly added to iOS target
  - Provisioning Profile supports the required entitlements
  - Bundle ID matches everywhere (Info.plist, project settings, URL schemes)