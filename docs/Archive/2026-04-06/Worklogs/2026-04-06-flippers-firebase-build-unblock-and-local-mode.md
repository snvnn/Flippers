# Flippers Worklog

작성일: 2026-04-06
작업 주제: Firebase 빌드 복구, 런타임 가드, 로컬 모드 진입 보강
작업 상태: 완료

## 1. 작업 배경

- 직전 작업 로그에서 `Flippers`는 Firebase Swift Package Manager 미연결 때문에 `xcodebuild`가 실패하는 상태였음
- 동시에 `FirebaseApp.configure()`가 앱 시작 시 무조건 호출되어 `GoogleService-Info.plist`가 없는 환경에서는 런타임 크래시 가능성이 남아 있었음
- 인증이 불가능한 경우에도 앱이 로그인 화면에 갇혀 로컬 카드/학습 기능에 접근할 수 없는 구조였음

## 2. 수행 내용

1. Firebase SPM 연결 복구

- `Flippers/Flippers.xcodeproj/project.pbxproj`에 Firebase iOS SDK Swift Package 의존성을 추가함
- 연결한 제품:
  - `FirebaseCore`
  - `FirebaseAuth`
  - `FirebaseFirestore`

2. 빌드 차단 컴파일 오류 정리

- 다음 파일의 SwiftUI/API 사용 오류를 수정함
  - `Flippers/Flippers/Presentation/Auth/AuthView.swift`
  - `Flippers/Flippers/Presentation/Auth/AuthViewModel.swift`
  - `Flippers/Flippers/Presentation/Study/StudyView.swift`

3. Firebase 런타임 가드 추가

- `Flippers/Flippers/Services/FirebaseBootstrap.swift` 추가
- `GoogleService-Info.plist` 존재 여부와 로드 가능 여부를 확인한 뒤에만 Firebase를 구성하도록 변경함
- 설정 파일이 없거나 유효하지 않으면 상태 메시지를 반환하고 앱은 로컬 모드로 계속 진행하도록 설계함

4. 인증 비가용 시 대체 경로 추가

- `Flippers/Flippers/Data/Remote/FirebaseAuthRepository.swift`
  - `UnavailableAuthRepository` 추가
  - Firebase 사용 불가 시 로그인/회원가입 호출이 명시적 에러 메시지를 반환하도록 처리
- `Flippers/Flippers/Presentation/Auth/AuthViewModel.swift`
  - Firebase 구성 상태를 읽어 인증 저장소를 선택하도록 변경
  - 인증 비가용 시 로그인 화면 노출 대신 로컬 모드 진입이 가능하도록 상태 계산 추가
- `Flippers/Flippers/ContentView.swift`
  - 인증이 실제로 가능한 경우에만 로그인 화면을 노출하고, 그렇지 않으면 바로 `MainTabView`로 진입하도록 변경
- `Flippers/Flippers/Presentation/MainTabView.swift`
  - 로컬 모드 진입 시 상단 배너로 "로그인/클라우드 동기화 비활성화" 상태를 노출
- `Flippers/Flippers/Presentation/Auth/AuthView.swift`
  - 인증 비가용 메시지 표시
  - 로그인/회원가입 입력과 Apple 로그인 버튼 비활성화

5. Firestore 호출 보호

- `Flippers/Flippers/Data/Remote/FirebaseSyncService.swift`
  - Firestore 접근 전에 Firebase 구성 상태를 다시 확인하도록 수정
  - 설정이 없으면 즉시 명시적 오류를 반환하게 변경

## 3. 실행한 검증

1. 시뮬레이터 빌드

```bash
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Flippers/Flippers.xcodeproj \
  -scheme Flippers \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath /tmp/flippers-derived \
  -clonedSourcePackagesDirPath /tmp/flippers-source-packages \
  CODE_SIGNING_ALLOWED=NO \
  build
```

- 결과: `BUILD SUCCEEDED`

2. 단위 테스트

```bash
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Flippers/Flippers.xcodeproj \
  -scheme Flippers \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/flippers-derived \
  -clonedSourcePackagesDirPath /tmp/flippers-source-packages \
  CODE_SIGNING_ALLOWED=NO \
  test \
  -only-testing:FlippersTests
```

- 결과: `TEST SUCCEEDED`
- 통과 테스트:
  - `SRSEngineTests` 13개 전부 통과
- 결과 번들:
  - `/tmp/flippers-derived/Logs/Test/Test-Flippers-2026.04.06_13-59-13-+0900.xcresult`

## 4. 현재 상태 평가

1. 이전 빌드 차단 이슈는 해소됨

- Firebase SPM 누락으로 인한 컴파일 실패는 더 이상 재현되지 않음

2. 런타임 안정성은 한 단계 개선됨

- `GoogleService-Info.plist`가 없는 개발 환경에서도 앱이 죽지 않고 로컬 모드로 진입 가능함
- Firebase 인증/동기화 호출은 비가용 상태를 명시적으로 처리함

3. 테스트 기준 최소 방어선은 유지됨

- 기존 `SRSEngine` 회귀 테스트는 모두 통과함

## 5. 남은 리스크

- `GoogleService-Info.plist`를 실제 번들 리소스로 넣은 상태의 로그인/Firestore 실동작은 아직 검증하지 않음
- `FlippersUITests`는 이번 실행 범위에 포함하지 않았고, 빌드만 함께 수행됨
- `Config.plist` 기반 Claude API 키 구조는 그대로 남아 있으므로 배포 전에는 별도 비밀 관리 경로가 필요함

## 6. 다음 조치 제안

1. Firebase 실환경 검증

- `GoogleService-Info.plist`를 포함한 로컬 실행으로 이메일 로그인, Apple 로그인, Firestore 동기화 확인

2. 리소스 번들 상태 확인

- `GoogleService-Info.plist`와 필요한 설정 파일이 타깃 리소스로 실제 포함되는지 점검

3. UI/통합 테스트 보강

- 로컬 모드 진입 시 배너 노출
- Firebase 비가용 시 인증 버튼 비활성화
- 인증 가능/불가 상태 전환
