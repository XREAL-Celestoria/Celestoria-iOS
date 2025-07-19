# Celestoria visionOS 앱 리팩토링 요약

## 개요
Celestoria는 Apple Vision Pro용 3D 공간 SNS 앱으로, 사용자의 추억을 별처럼 3D 공간에 배치하여 표시합니다. 이번 리팩토링은 MVP/POC 단계의 "스파게티 코드"를 20년차 iOS 개발자의 관점에서 체계적으로 개선하는 작업이었습니다.

## 주요 리팩토링 내용

### 1. 책임 분리 및 관심사 분리 (Separation of Concerns)

#### 1.1 SpaceCoordinator 리팩토링
**문제점**: 
- SpaceCoordinator가 너무 많은 책임을 가지고 있었음
- 별 생성/관리, 배경 관리, 위치 계산 등 모든 것을 담당

**해결책**:
- `StarSystemManager`: 별의 생성, 업데이트, 제거 담당
- `BackgroundManager`: 배경 텍스처 관리 전담
- `PositionManager`: 3D 공간 내 위치 계산 및 충돌 방지
- `EntityPool`: 성능 최적화를 위한 엔티티 재사용

```swift
// Before
class SpaceCoordinator {
    func addStar(...) { /* 모든 로직이 여기에 */ }
    func updateBackground(...) { /* 배경 관리도 여기에 */ }
    func calculatePosition(...) { /* 위치 계산도 여기에 */ }
}

// After
class SpaceCoordinator {
    private let starSystemManager: StarSystemManager
    private let backgroundManager: BackgroundManager
    // 조정자 역할만 수행
}
```

### 2. 상태 관리 통합 (Unified State Management)

#### 2.1 AppState 도입
**문제점**:
- AppModel과 여러 ViewModel들 간의 상태 동기화 문제
- 중복된 상태 관리 로직

**해결책**:
- `AppState`: 앱 전체의 중앙 상태 관리 객체 생성
- AppModel과의 호환성을 유지하면서 점진적 마이그레이션

```swift
@MainActor
final class AppState: ObservableObject {
    @Published var userId: UUID?
    @Published var userProfile: UserProfile?
    @Published var activeScreen: ActiveScreen = .login
    @Published var showAddMemoryView = false
    @Published var isImmersiveViewActive = false
    // 중앙 집중식 상태 관리
}
```

### 3. 성능 최적화

#### 3.1 엔티티 풀링 시스템
**구현 내용**:
- Generic 타입의 재사용 가능한 EntityPool
- 메모리 사용량 감소 및 생성/제거 오버헤드 최소화

### 4. 문제 해결

#### 4.1 로그인 동기화 문제
**문제**: 로그인 시 AppModel만 업데이트되고 AppState는 업데이트되지 않아 발생하는 불일치

**해결**: LoginViewModel이 AppModel과 AppState를 모두 업데이트하도록 수정

#### 4.2 Add Memory 버튼 빈 화면 문제
**문제**: WindowGroup이 AppState를 체크하지만 실제로는 AppModel만 업데이트됨

**해결**: 모든 관련 View와 ViewModel에서 상태 동기화

#### 4.3 Starfield 중복 업데이트 문제
**문제**: 배경이 3번 연속으로 업데이트되어 성능 저하

**해결**: BackgroundManager에 현재 배경 추적 및 중복 호출 방지 로직 추가

### 5. 코드 품질 개선

#### 5.1 불필요한 로그 제거
- UserProfile 배열 전체 출력 제거
- Info.plist 반복 로그 제거
- 프로필 이미지 반복 로그 제거
- 디버그 정보를 최소화하여 콘솔 가독성 향상

#### 5.2 에러 처리 개선
- 명확한 에러 메시지와 로깅
- 비동기 작업의 적절한 에러 처리

## 아키텍처 개선 사항

### MVVM + Clean Architecture 강화
1. **Presentation Layer**: View와 ViewModel의 명확한 분리
2. **Domain Layer**: UseCase를 통한 비즈니스 로직 캡슐화
3. **Data Layer**: Repository 패턴을 통한 데이터 접근 추상화

### 의존성 주입 개선
- DIContainer를 통한 중앙 집중식 의존성 관리
- 테스트 가능성 향상 및 결합도 감소

## 향후 권장 사항

1. **AppModel 제거**: AppState로 완전히 마이그레이션
2. **로깅 시스템**: 로그 레벨별 필터링 구현
3. **에러 처리**: 사용자 친화적인 에러 메시지 시스템
4. **테스트**: 유닛 테스트 및 통합 테스트 추가
5. **문서화**: 주요 컴포넌트에 대한 상세 문서 작성

## 결론
이번 리팩토링을 통해 코드의 유지보수성, 확장성, 성능이 크게 개선되었습니다. 특히 책임 분리를 통해 각 컴포넌트의 역할이 명확해졌고, 새로운 기능 추가 시 영향 범위를 최소화할 수 있는 구조가 되었습니다.

MVP/POC 단계에서 프로덕션 준비 단계로 나아가는 중요한 첫걸음이 되었으며, 향후 visionOS 2.0+ 기능들을 추가하기 위한 견고한 기반이 마련되었습니다.