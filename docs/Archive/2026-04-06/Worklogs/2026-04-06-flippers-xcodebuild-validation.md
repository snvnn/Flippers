# Flippers Worklog

작성일: 2026-04-06
작업 주제: Xcode 빌드 검증 및 실패 원인 확인
작업 상태: 완료

## 1. 작업 배경

- 사용자 요청으로 현재 저장소 기준에서 `Flippers`의 실제 Xcode 빌드 가능 여부를 직접 확인함
- 기존 문서에서 `xcodebuild` 검증 미실행 상태와 Firebase 설정 재현성 문제가 반복적으로 언급되어 있었음

## 2. 참고 문서

- `docs/Codereviews/Flippers-Code-Review-2026-04-01.md`
- `docs/Codereviews/2026-04-01-flippers-code-review-refresh.md`
- `docs/Compliance/Flippers-Compliance-Working-Draft-2026-04-06.md`

## 3. 수행 내용

1. Xcode CLI 사용 가능 여부 확인

- 기본 `xcodebuild`는 active developer directory가 `CommandLineTools`로 설정되어 있어 바로 실행되지 않음을 확인
- system-wide `xcode-select`는 변경하지 않고, `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` 방식으로 Xcode 26.4를 직접 사용하도록 우회함

2. 프로젝트 메타데이터 확인

- `xcodebuild -project Flippers/Flippers.xcodeproj -list`로 타깃과 스킴을 확인
- 확인 결과:
  - Target: `Flippers`, `FlippersTests`, `FlippersUITests`
  - Scheme: `Flippers`

3. 시뮬레이터용 빌드 실행

- 아래 명령으로 코드사인 없이 시뮬레이터 빌드를 시도함

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Flippers/Flippers.xcodeproj \
  -scheme Flippers \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath /tmp/flippers-derived \
  CODE_SIGNING_ALLOWED=NO \
  build
```

4. 실패 원인 확인

- 빌드는 `BUILD FAILED`와 함께 종료 코드 `65`로 실패함
- 1차 실패 원인은 Swift 컴파일 단계의 Firebase 모듈 해석 실패였음
- 확인된 오류:
  - `import FirebaseAuth`
  - `import FirebaseFirestore`
  - `import FirebaseCore`

## 4. 확인된 핵심 사실

1. Xcode 자체는 설치되어 있음

- `/Applications/Xcode.app` 존재 확인
- 직접 호출 시 `Xcode 26.4` 사용 가능

2. 프로젝트는 메타데이터 조회까지는 가능함

- `.xcodeproj` 자체는 손상되지 않았고 스킴도 정상 조회됨

3. 현재 저장소 상태로는 클린 빌드가 재현되지 않음

- `Flippers.xcodeproj/project.pbxproj`의 `packageProductDependencies`가 비어 있는 상태와 일치하게, 실제 컴파일에서도 Firebase 관련 import가 모두 실패함
- 즉, 문서에서 지적된 `Firebase SPM 미연결` 문제가 실제 빌드 실패로 재현됨

4. 시뮬레이터 서비스는 현재 환경에서 불안정함

- `CoreSimulatorService connection refused` 계열 오류가 함께 출력됨
- 다만 이번 빌드에서는 그보다 먼저 Firebase 모듈 해석 실패가 실제 차단 원인이었음

## 5. 관련 확인 파일

- `Flippers/Flippers.xcodeproj/project.pbxproj`
- `Flippers/Flippers/FlippersApp.swift`
- `Flippers/Flippers/Data/Remote/FirebaseAuthRepository.swift`
- `Flippers/Flippers/Data/Remote/FirebaseSyncService.swift`
- `docs/Worklogs/2026-04-06-flippers-xcodebuild-validation.md`

## 6. 남은 리스크

- Firebase Swift Package Manager 연결이 여전히 누락되어 있어 앱 컴파일이 불가함
- `GoogleService-Info.plist` 부재 문제는 컴파일 이후의 런타임 단계 리스크로 남아 있음
- 현재 실행 환경에서는 CoreSimulator 서비스 접근도 불안정하여 `test`까지 바로 이어가기 어려움

## 7. 다음 조치 제안

1. `Flippers.xcodeproj`에 Firebase iOS SDK SPM 의존성 추가

- 최소 필요 후보:
  - `FirebaseCore`
  - `FirebaseAuth`
  - `FirebaseFirestore`

2. 빌드 재실행

- 동일한 `DEVELOPER_DIR` + `iphonesimulator` 조합으로 재검증

3. 컴파일 통과 후 런타임 설정 검증

- `GoogleService-Info.plist` 또는 대체 Firebase 설정 경로 점검
- 가능하면 simulator 대상 `test` 또는 최소 `build-for-testing` 재시도

## 8. 검증 메모

- `xcode-select`의 전역 설정은 변경하지 않음
- `/tmp/flippers-derived`를 사용해 샌드박스 내에서 파생 빌드 산출물을 분리함
- 이번 검증은 "실제 빌드가 어디서 막히는지"를 확인하는 목적은 달성했으며, 현재 가장 앞선 차단 요인은 Firebase 패키지 미연결로 판단됨
