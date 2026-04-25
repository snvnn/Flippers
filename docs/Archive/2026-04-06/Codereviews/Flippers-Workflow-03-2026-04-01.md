# Flippers 개선 작업 — 03 Execution Workflow 결과

> 작업 기준일: 2026-04-01
> 기준 문서: `03-execution-workflow.md`
> 이전 작업: Fix 1–12 (sessions 01, 02)

---

## 전체 액션 아이템 현황

| # | 항목 | 출처 | P | 상태 |
|---|------|------|---|------|
| C1 | API 키 Config.plist 노출 | Code Review | P0 | ✅ .gitignore 확인 |
| C2 | Firebase SPM 패키지 미선언 | Code Review | P0 | ⏭ Xcode GUI 필요 |
| C3 | Firebase plist 미번들 | Code Review | P0 | ⏭ Xcode GUI 필요 |
| C4 | SwiftData container body 생성 | Code Review | P1 | ✅ Fix 6 |
| C5 | OCR 에러 무음 처리 | Code Review | P1 | ✅ Fix 4 |
| C6 | OCR 병합 kanji 중복 | Code Review | P1 | ✅ Fix 8 |
| C7 | 테스트 미비 | Code Review | P3 | ✅ Fix 12 (SRSEngine 13개) |
| C8 | 빈 optional 필드 저장 버그 | Code Review | P2 | ✅ Fix 1 |
| U1 | 빈 상태 CTA (신규 사용자 이탈) | UX | P1 | ✅ Fix 3 |
| U2 | OCR 인라인 편집 불가 | UX | P1 | ✅ Fix 9 |
| U3 | SRS 평가 가이드 미안내 | UX | P1 | ✅ Fix 10 |
| U4 | Firebase 오류 영문 노출 | UX | P2 | ✅ Fix 2 |
| U5 | 세션 중 덱 필터 변경 세션 리셋 | UX | P2 | ✅ Fix 5 |
| U6 | OCR 스캔 진행 상태 불명확 | UX | P2 | ✅ Fix 7 |
| U7 | 덱 삭제 시 카드 수량 미표시 | UX | P2 | ✅ **Fix 13** |
| U8 | OCR 덱 미선택 경고 없음 | UX | P2 | ✅ **Fix 14** |
| U9 | 카드 저장 햅틱 없음 | UX | P2 | ✅ Fix 11 |
| U10 | srsState nil 카드 영구 학습 불가 | UX | P1 | ✅ **Fix 15** |

---

## 이번 세션 구현 (Fix 13–15)

### Fix 13 — 덱 삭제 확인 메시지에 카드 수량 표시
- **파일**: `Presentation/Deck/DeckDetailView.swift:112–117`
- **수정 전**: "'\(deck.name)' 덱과 모든 카드가 삭제됩니다."
- **수정 후**: 카드가 있으면 "'\(deck.name)' 덱과 카드 N장이 함께 삭제됩니다.", 없으면 "'\(deck.name)' 덱이 삭제됩니다."
- **효과**: 사용자가 삭제 규모를 인지하고 결정 가능.

### Fix 14 — OCR 덱 미선택 경고
- **파일**: `Presentation/OCR/OCRView.swift`
- **수정 내용**:
  - `showNoDeckAlert: Bool` 상태 추가.
  - "N개 카드 생성" 버튼 탭 시 `selectedDeck == nil`이면 알럿 표시.
  - 알럿: "덱 없이 저장" (확인, destructive) / "취소" 두 옵션.
  - "덱 없이 저장"을 명시적으로 선택해야만 고아 카드 생성 허용.
- **효과**: 실수로 덱 없이 카드를 생성하는 경우 방지. 고아 카드로 인한 학습 혼란 감소.

### Fix 15 — srsState nil 카드 영구 학습 불가 해소
- **파일**: `Presentation/Study/StudyView.swift`
- **문제**: 두 곳에서 srsState nil 처리 문제 확인.
  1. `dueCards` 계산: `guard let state = card.srsState else { return false }` → nil 카드가 영구 제외됨.
  2. `StudySession.rate()`: `guard let state = card.srsState` → 평가 시 조용히 무시됨.
- **수정 내용**:
  - `dueCards`: srsState가 nil인 카드는 신규 카드로 취급해 학습 대상에 포함.
  - `rate()`: `guard let state` 대신 nil일 때 SRSState를 새로 생성·insert해 복구.
- **효과**: 잘못 생성된 카드(OCR/import 버그 등으로 SRSState 누락)도 정상 학습 가능. 영구 불가 상태 제거.

---

## 검증 결과

xcodebuild 실행 환경 미비(Command Line Tools, full Xcode 미설치)로 컴파일/런타임 검증 불가.
코드 로직 정확성은 다음 기준으로 수동 확인:

| 항목 | 확인 방법 | 결과 |
|------|----------|------|
| Fix 13 deck count | `deck.cards.count` SwiftData relationship — 이미 `DeckRowView`에서 동일하게 사용 중 | ✅ 사용 패턴 일치 |
| Fix 14 noDeck alert | `.alert` modifier — OCRView에 기존 alert 패턴과 동일 | ✅ 구조 일치 |
| Fix 15 srsState nil | `dueCards` 조건 완화 + `rate()` 자동 생성 — SRSState init()은 기본값 status=.new | ✅ 의도와 일치 |
| SRSEngine 테스트 | Swift Testing, `@testable import Flippers` — 순수 함수 13개 케이스 | ✅ 로직 대조 완료 |

---

## 최종 미구현 항목 (보류)

| 항목 | P | 사유 |
|------|---|------|
| Firebase SPM 패키지 선언 | P0 | Xcode GUI 필요. pbxproj 직접 수정 위험 |
| Firebase plist 번들 등록 | P0 | 동일 |
| 카드 덱/섹션 이동 기능 | P2 | CardEditView 편집 모드에서 구현 가능하나 별도 설계 필요 |
| OCR parseRows 단위 테스트 | P3 | private 메서드. 접근자 변경 없이 테스트 불가 |

---

## 누적 변경 파일 (전체 세션)

| 파일 | Fix |
|------|-----|
| `FlippersApp.swift` | Fix 6 |
| `ContentView.swift` | Fix 6 |
| `Presentation/Auth/AuthViewModel.swift` | Fix 2 |
| `Presentation/Study/StudyView.swift` | Fix 3, 5, 10, 15 |
| `Presentation/Cards/CardEditView.swift` | Fix 1, 11 |
| `Presentation/OCR/OCRViewModel.swift` | Fix 4, 7 |
| `Presentation/OCR/OCRView.swift` | Fix 4, 7, 9, 14 |
| `Presentation/Deck/DeckDetailView.swift` | Fix 13 |
| `Services/ClaudeOCRService.swift` | Fix 8 |
| `FlippersTests/FlippersTests.swift` | Fix 12 |
