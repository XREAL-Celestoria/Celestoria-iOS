# Celestoria visionOS 앱 리팩토링 요약

## 개요

Celestoria는 Apple Vision Pro용 3D 공간 SNS 앱으로, 사용자의 추억을 별처럼 3D 공간에 배치하여 표시합니다. 이번 리팩토링은 MVP/POC 단계의 "스파게티 코드"를 20년차 iOS 개발자의 관점에서 체계적으로 개선하는 작업이었습니다.

## 기존 구조의 문제점

### 1. 단일 책임 원칙 위반

- **SpaceCoordinator**가 모든 3D 공간 관련 로직을 담당
  - 별(Star) 엔티티의 생성, 업데이트, 제거
  - 배경(Starfield) 텍스처 관리
  - 3D 위치 계산 및 충돌 감지
  - 메모리 상태 추적 및 동기화
- 이로 인해 한 기능의 변경이 다른 기능에 영향을 미칠 위험이 높았음

### 2. 상태 관리 중복

- **AppModel**과 여러 **ViewModel**들이 각자 상태를 관리
- 동일한 데이터(userId, userProfile 등)가 여러 곳에 중복 저장
- 상태 동기화 문제로 인한 UI 불일치 발생 가능성

## 리팩토링 후 구조

### 1. 책임 분리를 통한 모듈화

#### 1.1 SpaceCoordinator의 역할 재정의

**기존 구조**: 모든 3D 관련 로직을 직접 처리

**개선된 구조**: 순수한 조정자(Coordinator) 역할로 축소

```swift
// 개선된 SpaceCoordinator - 조정만 담당
class SpaceCoordinator: ObservableObject {
    weak var appState: AppState?
    let spaceEntity = SpaceEntity()

    // 다른 객체들에게 작업을 위임하는 메서드들
    func addStar(for memory: Memory) async {
        await spaceEntity.addStar(for: memory)
    }
}
```

### 2. 통합 상태 관리 시스템

#### 2.1 AppModel에서 AppState로 전환

**기존 구조**:

- AppModel이 일부 상태 관리
- 각 ViewModel이 독립적으로 상태 관리
- 상태 동기화를 위한 복잡한 바인딩

**개선된 구조**: AppState를 통한 단일 진실 공급원(Single Source of Truth)

```swift
@MainActor
final class AppState: ObservableObject {
    // Core State - 앱 전체에서 공유되는 핵심 상태
    @Published var userId: UUID?
    @Published var userProfile: UserProfile?
    @Published var activeScreen: ActiveScreen = .login

    // UI State - UI 관련 상태
    @Published var showAddMemoryView = false
    @Published var selectedStarfield: StarField? = .FIELD_1

    // Immersive Space - visionOS 특화 상태
    @Published var isImmersiveViewActive = false

    // ViewModels - 주요 뷰모델 참조 (Optional로 안전하게 관리)
    let spaceCoordinator: SpaceCoordinator?
    let mainViewModel: MainViewModel?
    var loginViewModel: LoginViewModel?
}
```

이를 통해:

- 모든 상태가 한 곳에서 관리되어 일관성 보장
- 상태 변경 추적이 용이함
- 디버깅과 테스트가 간편해짐

### 3. 의존성 주입 개선

#### 3.1 DIContainer를 통한 중앙화된 의존성 관리

**기존 구조**:

- ViewModels가 직접 의존성을 생성
- 테스트 시 모의 객체 주입 불가능

**개선된 구조**: DIContainer가 모든 의존성을 관리

```swift
@MainActor
final class DIContainer: ObservableObject {
    // Core State
    let appState: AppState

    // Repositories - 데이터 접근 계층
    let memoryRepository: MemoryRepository
    let authRepository: AuthRepositoryProtocol

    // Use Cases - 비즈니스 로직
    private let fetchMemoriesUseCase: FetchMemoriesUseCase
    let profileUseCase: ProfileUseCase

    init() {
        // 1. 저장소 초기화
        // 2. 유스케이스 초기화
        // 3. 뷰모델 초기화
        // 4. AppState 생성 및 연결
    }
}
```

### 4. 안전한 초기화 및 옵셔널 처리

#### 4.1 Force Unwrapping 제거

**기존 구조**:

```swift
// 위험한 force unwrapping
ContentView()
    .environmentObject(diContainer.spaceCoordinator!)
    .environmentObject(diContainer.mainViewModel!)
```

**개선된 구조**: 안전한 옵셔널 바인딩

```swift
if let spaceCoordinator = diContainer.appState.spaceCoordinator,
   let mainViewModel = diContainer.appState.mainViewModel {
    ContentView()
        .environmentObject(spaceCoordinator)
        .environmentObject(mainViewModel)
} else {
    ProgressView("Loading...")
}
```

### 5. 성능 최적화

#### 5.1 중복 업데이트 방지

**BackgroundManager의 개선**: 동일한 배경 재설정 방지

```swift
private var currentBackgroundName: String?

func updateBackground(imageName: String) {
    if currentBackgroundName == imageName {
        return // 중복 업데이트 방지
    }
    currentBackgroundName = imageName
    // 실제 업데이트 로직
}
```

#### 5.2 메모리 효율적인 엔티티 관리

- EntityPool을 통한 엔티티 재사용 (현재는 단순 구조로 유지)
- 불필요한 객체 생성 최소화

## 아키텍처의 주요 개선점

### 1. 계층 분리 명확화

```
Presentation Layer (View + ViewModel)
         ↓
Domain Layer (UseCases + Entities)
         ↓
Data Layer (Repositories + Supabase)
```

### 2. 단방향 데이터 흐름

- User Action → ViewModel → UseCase/Repository → AppState → View Update
- 예측 가능한 상태 변경과 디버깅 용이성

### 3. 테스트 가능한 구조

- 모든 의존성이 프로토콜을 통해 주입됨
- 모의 객체를 사용한 단위 테스트 가능
- UI와 비즈니스 로직의 완전한 분리

## 향후 개선 방향

### 1. 테스트 커버리지

- 핵심 비즈니스 로직에 대한 단위 테스트 추가
- UI 테스트를 통한 사용자 시나리오 검증

### 2. 에러 처리 체계화

- 사용자 친화적인 에러 메시지
- 네트워크 오류에 대한 재시도 로직

## 결론

이번 리팩토링을 통해 Celestoria 앱은 다음과 같은 개선을 달성했습니다:

1. **유지보수성 향상**: 각 컴포넌트의 책임이 명확해져 코드 수정 시 영향 범위를 쉽게 파악 가능

2. **확장성 확보**: 새로운 기능 추가 시 기존 코드 수정 없이 확장 가능한 구조

3. **안정성 강화**: Force unwrapping 제거와 옵셔널 처리로 런타임 크래시 방지

4. **개발 효율성**: 명확한 아키텍처로 팀원 간 협업이 원활해짐

## 2025년 7월 iOS UI 개선사항

### 개요

iOS 앱의 UI가 디자인 목업과 일치하지 않는 문제를 해결하기 위한 상세한 UI 개선 작업을 수행했습니다. 특히 실제 데이터 연동과 레이아웃 조정에 중점을 두었습니다.

### 주요 개선 사항

#### 1. UserInfoModalView (홈 화면 하단 모달)

**문제점:**
- Add 버튼이 잘못된 위치에 있음
- 프로필과 통계가 한 줄에 표시되어 레이아웃이 복잡함
- 하드코딩된 목업 데이터 사용 (memoryCount: 15, likeCount: 356 등)

**해결책:**
- ZStack alignment를 사용하여 Add 버튼을 우측 상단에 배치
- 프로필과 이름을 상단, 통계(별, 댓글, 좋아요)를 하단에 배치
- 실제 데이터 연동:
  - 메모리 개수: `memoryUseCase.execute(for: userId)`로 실제 개수 조회
  - 좋아요 수: 사용자의 모든 메모리에 대한 좋아요 총합 계산
  - 댓글 수: 기능 미구현으로 0 표시

#### 2. MemoryDetailView (메모리 상세 화면)

**문제점:**
- 좋아요/댓글 수가 하드코딩된 값 사용
- 좋아요 기능이 실제로 작동하지 않음

**해결책:**
- 실시간 좋아요 기능 구현:
  - `memoryRepository.getLikeCount()`: 좋아요 개수 조회
  - `memoryRepository.hasLiked()`: 현재 사용자의 좋아요 상태 확인
  - `memoryRepository.createLike()`/`deleteLike()`: 좋아요 토글
- 자신의 메모리에는 좋아요 불가 처리
- 좋아요 상태 변경 시 즉각적인 UI 업데이트

#### 3. AddMemoryDoneView (메모리 업로드 완료 화면)

**문제점:**
- visionOS 디자인과 일치하지 않는 UI
- 아이콘과 텍스트 스타일이 다름

**해결책:**
- visionOS의 AddMemoryDoneView 디자인 참조하여 통일
- 별 아이콘에 그라데이션 배경과 글로우 효과 추가
- 텍스트 크기와 간격 조정
- "View Memory Star" 버튼 스타일 개선

### 기술적 구현 세부사항

#### 데이터 통합
```swift
// 기존: 목업 데이터
@State private var likeCount: Int = 356 // TODO: Replace with actual data

// 개선: 실제 데이터 조회
private func loadUserStats() async {
    let memories = try await diContainer.memoryUseCase.execute(for: userId)
    memoryCount = memories.count
    
    var totalLikes = 0
    for memory in memories {
        let likeCount = try await diContainer.memoryRepository.getLikeCount(for: memory.id)
        totalLikes += likeCount
    }
    likeCount = totalLikes
}
```

#### UI 레이아웃 개선
- HStack + VStack 조합에서 ZStack alignment 활용으로 변경
- 절대 위치 지정이 필요한 요소(Add 버튼)의 정확한 배치
- 반응형 디자인을 위한 적절한 spacing과 padding 값 조정

### 성과

1. **일관성**: iOS와 visionOS 간의 UI 일관성 확보
2. **정확성**: 실제 데이터베이스 값을 표시하여 신뢰성 향상
3. **사용성**: 즉각적인 피드백을 제공하는 인터랙션 구현
4. **유지보수성**: 목업 데이터 제거로 향후 유지보수 용이
