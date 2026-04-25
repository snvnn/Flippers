# Flippers Worklog

작성일: 2026-04-06
작업 주제: ClaudeOCRService Swift 6 actor isolation 경고 정리
작업 상태: 완료

## 1. 작업 배경

- 사용자 제공 스크린샷 `docs/ErrorMessages/Archive/2026-04-06/ErrorMessages_20260406_1406.png`에서 `ClaudeOCRService` 관련 Swift 6 actor isolation 경고 7건을 확인함
- 주요 경고 유형:
  - `OCRConfiguration.claudeAPIKey(bundle:)` 정적 메서드 호출
  - `UIImage.resized(toMaxDimension:)` 호출
  - `ClaudeResponse`, `CardsPayload`의 `Decodable` conformances 사용

## 2. 원인

- 현재 프로젝트는 Swift 기본 격리 설정이 `MainActor` 기준으로 동작하고 있음
- 그 결과 `ClaudeOCRService` 내부에서 사용하는 보조 타입과 헬퍼가 불필요하게 main actor 격리를 상속받고 있었음
- 반면 `ClaudeOCRService`는 별도 actor이므로, 이 타입들을 actor 내부에서 사용할 때 Swift 6 모드 기준 경고가 발생함

## 3. 수정 내용

- `Flippers/Flippers/Services/ClaudeOCRService.swift`에서 아래 선언들을 `nonisolated`로 명시함
  - `ParsedCard`
  - `ClaudeResponse`
  - `ClaudeResponse.ContentBlock`
  - `CardsPayload`
  - `OCRError`
  - `OCRConfiguration`
  - `UIImage` resize helper extension

## 4. 검증

실행 명령:

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

검증 결과:

- `BUILD SUCCEEDED`
- `ClaudeOCRService` 관련 actor isolation 경고는 재현되지 않음
- 빌드 로그에 남은 경고는 다음 두 가지 계열뿐이었음
  - Xcode의 다중 simulator destination 선택 경고
  - `AppIntents.framework` 미사용에 따른 metadata extraction skipped 경고

## 5. 관련 파일

- `docs/ErrorMessages/Archive/2026-04-06/ErrorMessages_20260406_1406.png`
- `Flippers/Flippers/Services/ClaudeOCRService.swift`

## 6. 현재 상태

- `ClaudeOCRService`는 Swift 6 actor isolation 기준에서도 경고 없이 빌드 가능한 상태로 정리됨
- 남아 있는 OCR 관련 이슈는 actor isolation이 아니라 배포 전 secret 관리와 실제 Claude API 런타임 검증 쪽임
