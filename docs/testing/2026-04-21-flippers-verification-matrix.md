# Flippers Verification Matrix

작성일: 2026-04-21  
상태: 현재 저장소 기준 좁은 범위 검증 명령 모음

## 목적

이 문서는 `Flippers` 작업 중 변경 범위에 맞는 **가장 좁은 검증 명령** 을 바로 고를 수 있게 정리한다.

핵심 원칙:
- 전체 시뮬레이터 런타임이 불안정하거나 느릴 때는 먼저 좁은 검증을 사용한다.
- 문서만 수정한 경우에는 관련 문서 정합성 확인으로 충분하다.
- Swift/Xcode 검증은 **macOS + Xcode 환경** 에서 실행해야 한다.

## 현재 환경 메모

- 이 저장소는 iOS/Xcode 프로젝트다.
- `xcodebuild`, `swift`, `xcrun` 이 없는 환경에서는 Swift 테스트/빌드를 실제 실행할 수 없다.
- 그런 환경에서는:
  - 문서/소스 정적 점검
  - 테스트 파일 범위 확인
  - Node 기반 프록시 테스트
  까지만 수행하고, 실제 iOS 빌드/테스트는 macOS 환경으로 넘긴다.

## 권장 검증 순서

1. **가장 좁은 테스트**
2. **관련 테스트 묶음**
3. **`build-for-testing`**
4. 필요할 때만 더 넓은 시뮬레이터 실행

---

## 1. OCR 프록시 / OCR 설정

### 1-1. OCR proxy stub contract

목표:
- text-only enhancement 계약 유지 확인

명령:
```bash
node --test tools/tests/ocr-proxy-server.test.mjs
```

확인 포인트:
- text-only 요청 허용
- legacy image payload 거절

### 1-2. OCR Swift 설정 / 프록시 URL 해석

대상 테스트:
- `OCRConfigurationTests`

권장 명령:
```bash
xcodebuild test \
  -project Flippers.xcodeproj \
  -scheme Flippers \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FlippersTests/OCRConfigurationTests
```

---

## 2. OCR parser regression

대상 테스트:
- `OCRRowParserTests`

포함 범위:
- shifted columns
- split meaning blocks
- checkbox noise 제거
- unsupported Japanese-only row fallback

권장 명령:
```bash
xcodebuild test \
  -project Flippers.xcodeproj \
  -scheme Flippers \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FlippersTests/OCRRowParserTests
```

---

## 3. OCR review / save validation

대상 테스트:
- `OCRViewModelTests`

포함 범위:
- invalid selected rows
- deselected invalid rows
- incomplete selected rows review notice
- empty OCR results unsupported-layout notice
- saveCards invalid-row guard

권장 명령:
```bash
xcodebuild test \
  -project Flippers.xcodeproj \
  -scheme Flippers \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FlippersTests/OCRViewModelTests
```

---

## 4. Auth / Firebase 비가용 / 에러 매핑

### 4-1. Auth view-model missing-config behavior

대상 테스트:
- `AuthViewModelTests`

권장 명령:
```bash
xcodebuild test \
  -project Flippers.xcodeproj \
  -scheme Flippers \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FlippersTests/AuthViewModelTests
```

### 4-2. Firebase bootstrap status / missing-config detection

대상 테스트:
- `FirebaseBootstrapTests`

권장 명령:
```bash
xcodebuild test \
  -project Flippers.xcodeproj \
  -scheme Flippers \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FlippersTests/FirebaseBootstrapTests
```

### 4-3. Firebase auth error mapping

대상 테스트:
- `FirebaseAuthErrorMappingTests`

권장 명령:
```bash
xcodebuild test \
  -project Flippers.xcodeproj \
  -scheme Flippers \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FlippersTests/FirebaseAuthErrorMappingTests
```

---

## 5. OCR enhancement merge behavior

대상 테스트:
- `ClaudeOCRServiceTests`

목표:
- 프록시 요청 body
- reading/meaning merge behavior

권장 명령:
```bash
xcodebuild test \
  -project Flippers.xcodeproj \
  -scheme Flippers \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FlippersTests/ClaudeOCRServiceTests
```

---

## 6. 최소 빌드 검증

목표:
- 테스트 실행 전 compile-level sanity 확인

권장 명령:
```bash
xcodebuild build-for-testing \
  -project Flippers.xcodeproj \
  -scheme Flippers \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

사용 시점:
- 여러 Swift 파일을 함께 수정했을 때
- 테스트 런타임 전에 컴파일 안정성만 빠르게 확인하고 싶을 때

---

## 7. 문서 변경만 있을 때

문서만 바뀐 경우 확인 항목:
- [ ] 새 문서 경로가 실제 존재하는지
- [ ] 관련 Current 문서에서 참조 경로가 깨지지 않는지
- [ ] 중복되거나 모순되는 운영 지침이 없는지

관련 문서:
- `docs/operations/2026-04-21-flippers-ocr-proxy-runbook.md`
- `docs/testing/2026-04-21-flippers-auth-audit.md`
- `docs/testing/2026-04-21-flippers-firebase-smoke-checklist.md`
- `docs/Current/Flippers-Current-Priorities-2026-04-06.md`
- `docs/Current/Flippers-Current-Status-2026-04-06.md`
- `docs/Current/Flippers-Release-Privacy-Summary-2026-04-06.md`

---

## 빠른 선택 가이드

### OCR parser만 바꿨다
1. `OCRRowParserTests`
2. `OCRViewModelTests`
3. `build-for-testing`

### OCR review UX만 바꿨다
1. `OCRViewModelTests`
2. 필요 시 `OCRRowParserTests`
3. `build-for-testing`

### Auth 관련만 바꿨다
1. `AuthViewModelTests`
2. `FirebaseBootstrapTests`
3. `FirebaseAuthErrorMappingTests`
4. `build-for-testing`

### OCR proxy stub만 바꿨다
1. `node --test tools/tests/ocr-proxy-server.test.mjs`
2. 필요 시 runbook/doc 정합성 확인

## 현재 테스트 클래스 기준 인덱스

- `SRSEngineTests`
- `OCRConfigurationTests`
- `ClaudeOCRServiceTests`
- `AuthViewModelTests`
- `FirebaseBootstrapTests`
- `FirebaseAuthErrorMappingTests`
- `OCRRowParserTests`
- `OCRViewModelTests`
