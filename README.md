# Celestoria : Spatial Video Social Network
## Illuminate Your Memories, Make Your Galaxy

[🚀 Try Celestoria Now! (Get it on the App Store)](https://apps.apple.com/kr/app/celestoria/id6741099022)

Celestoria transforms your everyday moments into a breathtaking galaxy of Spatial Video memories. Designed exclusively for Apple Vision Pro, this immersive social network lets you curate, share, and connect through 3D experiences that feel as vivid as reality itself.

## 🌟 Features

### Core Features
- **3D Memory Galaxy**: Your memories float as stars in an immersive 3D space
- **Spatial Video Support**: Upload and view spatial videos captured on iPhone 15 Pro or Vision Pro
- **Social Interaction**: Like and explore other users' memory galaxies
- **Personalized Space**: Customize your galaxy with different starfield backgrounds
- **Memory Categories**: Organize memories into Family, Travel, Pet, and Entertainment

### Platform Support
- **visionOS** (Primary): Full immersive experience with RealityKit
- **iOS**: Companion app with SceneKit-based 3D view

## 📱 Requirements

### visionOS
- Apple Vision Pro
- visionOS 2.0 or later

### iOS
- iPhone 12 or later
- iOS 17.0 or later

## 🛠 Installation

### Prerequisites
- Xcode 15.0 or later
- Apple Developer account (for device testing)
- Supabase project (for backend services)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/Celestoria-iOS.git
   cd Celestoria-iOS
   ```

2. **Configure environment variables**
   - Copy `Debug.xcconfig.example` to `Debug.xcconfig`
   - Copy `Release.xcconfig.example` to `Release.xcconfig`
   - Add your Supabase credentials

3. **Install dependencies**
   ```bash
   xcodebuild -resolvePackageDependencies -project Celestoria/Celestoria.xcodeproj
   ```

4. **Build and run**
   - Open `Celestoria.xcodeproj` in Xcode
   - Select target: `Celestoria` for visionOS or `Celestoria-iOS` for iOS
   - Build and run (⌘R)

## 🏗 Architecture

Celestoria follows **MVVM + Clean Architecture** principles:

```
┌─────────────────────────────────────────────────┐
│                 Presentation Layer              │
│          (SwiftUI Views + ViewModels)           │
├─────────────────────────────────────────────────┤
│                  Domain Layer                   │
│         (Use Cases + Entity Models)             │
├─────────────────────────────────────────────────┤
│                   Data Layer                    │
│      (Repositories + Supabase Integration)      │
└─────────────────────────────────────────────────┘
```

### Key Components
- **AppState**: Single source of truth for app-wide state
- **DIContainer**: Dependency injection container
- **SpaceCoordinator**: Manages 3D space and memory entities (visionOS)
- **MemoryRepository**: Handles all memory-related data operations

For detailed architecture documentation, see [CLAUDE.md](./CLAUDE.md).

## 🎨 UI/UX Design

The app features a dark, space-themed design with:
- Gradient accents using purple (#A68CFF) and blue (#7B61FF) tones
- Glassmorphic UI elements
- Smooth animations and transitions
- Platform-specific optimizations

## 🔧 Development

### Build Commands
```bash
# Build for visionOS Simulator
xcodebuild -project Celestoria/Celestoria.xcodeproj -scheme Celestoria -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

# Build for iOS Simulator
xcodebuild -project Celestoria/Celestoria.xcodeproj -scheme Celestoria-iOS -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

### Code Style
- SwiftUI for all UI components
- Async/await for asynchronous operations
- Combine for reactive programming
- Swift concurrency for thread safety

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is proprietary software. All rights reserved.

## 🙏 Acknowledgments

- Built with [Supabase](https://supabase.com) for backend services
- 3D models and assets created with Reality Composer Pro
- Special thanks to the visionOS developer community

## 📞 Contact

For questions or support, please contact the development team.

---

Made with ❤️ for Apple Vision Pro