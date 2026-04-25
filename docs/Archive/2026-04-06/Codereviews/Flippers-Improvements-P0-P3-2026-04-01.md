# Flippers P0–P3 개선 작업 결과

> 작업 기준일: 2026-04-01
> 기준 문서: `02-source-docs-and-priorities.md`
> 이전 작업: `Flippers-Improvements-2026-04-01.md` (Fix 1–7)

---

## 우선순위 점검 결과

### P0 — 보안·크래시

| 항목 | 상태 | 비고 |
|------|------|------|
| `Config.plist` API 키 노출 | ✅ 안전 | `.gitignore`에 `**/Config.plist` 이미 등록됨. 키가 git에 커밋되지 않음. |
| SwiftData container 생성 위치 | ✅ Fix 6 완료 | `FlippersApp.init()`으로 이동 (이전 세션) |
| Firebase SPM 패키지 미선언 | ⏭ 보류 | Xcode GUI 필요. pbxproj 직접 수정 불가 |
| `GoogleService-Info.plist` 미번들 | ⏭ 보류 | 동일 이유 |

---

### P1 — 핵심 사용자 플로우

#### Fix 8 — OCR 병합 로직: kanji 문자열 → UUID 기반 순서 매핑
- **파일**: `Services/ClaudeOCRService.swift:195–207`
- **문제**: `enhanceWords`가 `firstIndex(where: { $0.kanji == parsedCard.kanji })`로 병합. 동일 한자가 여러 행에 있으면 첫 번째 항목만 업데이트되고 나머지는 빈 reading/meaning 유지.
- **수정**: `payload.cards`를 enumerated()로 순회, `needsEnhancement[idx].id`(UUID)로 원본 단어를 찾아 병합. Claude가 입력 순서대로 응답한다는 전제 하에 안정적.
- **효과**: 중복 한자가 있는 단어장에서 병합 오류 방지.

#### Fix 9 — OCR 결과 인라인 편집 (OCRWordRow → TextField)
- **파일**: `Presentation/OCR/OCRView.swift`
- **문제**: 리뷰 화면에서 OCR 추출 결과가 `Text()`로만 표시되어 수정 불가. 추출이 잘못된 경우 해당 단어를 체크 해제하거나 전부 저장해야 함.
- **수정**: `OCRWordRow`를 TextField 3개(한자·読み方·의미)로 교체. `@Binding var word: OCRWord` 구조 활용해 인플레이스 수정 가능. 체크박스는 `Button`으로 분리해 TextField 탭과 충돌 방지.
- **효과**: OCR 추출 오류를 리뷰 단계에서 직접 수정 가능. 핵심 OCR 가치 보호.

#### Fix 10 — SRS 평가 가이드 첫 세션 오버레이
- **파일**: `Presentation/Study/StudyView.swift`
- **문제**: Again/Hard/Good/Easy 버튼의 의미 설명 없음. SRS 경험이 없는 신규 사용자에게 블랙박스.
- **수정**:
  - `@AppStorage("hasSeenRatingGuide")` — 앱 재설치 전까지 한 번만 표시.
  - 첫 세션 시작 시 `showRatingGuide = true`. `RatingGuideOverlay` 풀스크린 오버레이 표시.
  - 각 평가 버튼(컬러 + 레이블 + 결과 설명) 4개를 카드 형태로 안내.
  - "학습 시작" 버튼 또는 배경 탭으로 dismiss. 이후 다시는 표시되지 않음.
- **효과**: R3 리스크(SRS 개념 미안내) 해소.

---

### P2 — UX 마찰 감소

#### Fix 11 — 카드 저장 성공 햅틱 피드백
- **파일**: `Presentation/Cards/CardEditView.swift`
- **문제**: 카드 저장 후 시트가 그냥 닫힘. 저장됐는지 순간적으로 불안.
- **수정**: `save()` 내 `dismiss()` 호출 전 `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` 추가.
- **효과**: 저장 완료 촉각 피드백. `import UIKit` 추가.

---

### P3 — 핵심 로직 단위 테스트

#### Fix 12 — SRSEngine 단위 테스트 13개 추가
- **파일**: `FlippersTests/FlippersTests.swift`
- **문제**: iOS 테스트 타겟에 기본 placeholder 테스트만 존재. SRS 스케줄링 로직에 회귀 방어 없음.
- **수정**: Swift Testing 프레임워크(`import Testing`)로 `SRSEngineTests` struct 작성.

  | 테스트 | 검증 내용 |
  |--------|-----------|
  | `newCard_again_staysLearningStep0` | Again → learning step 0, requeue |
  | `newCard_hard_staysAtStep0` | Hard → learning step 0 유지 |
  | `newCard_good_advancesToStep1` | Good → step 1 진행 |
  | `learningCard_good_atLastStep_graduates` | 마지막 step + Good → review 졸업 |
  | `newCard_easy_graduatesImmediately` | Easy → review 즉시 졸업, ease 증가 |
  | `reviewCard_good_intervalScalesByEase` | interval = interval × ease |
  | `reviewCard_again_causesLapse` | 복습 실패 → relearning, lapseCount +1, ease 감소 |
  | `reviewCard_hard_decreasesEase` | Hard → ease 감소 |
  | `reviewCard_easy_boostsEaseAndInterval` | Easy → ease 증가, interval 증가 |
  | `ease_neverDropsBelowMinimum` | ease ≥ 1.3 보장 |
  | `ease_neverExceedsMaximum` | ease ≤ 4.0 보장 |
  | `relearningCard_good_atLastStep_returnsToReview` | 재학습 완료 → review 복귀 |
  | `relearningCard_again_requeuesSameStep` | 재학습 Again → 동일 step 재큐 |

- **참고**: `SRSEngine`이 순수 함수(값 타입 입출력, 부수효과 없음)라 테스트가 간결함. xcodebuild 실행 환경 미비로 런타임 검증은 불가하나 코드 정확성은 SRSEngine 로직과 대조 확인 완료.

---

## 미구현 항목

| 항목 | P | 이유 |
|------|---|------|
| Firebase SPM 패키지 선언 | P0 | Xcode GUI 필요 |
| Firebase plist 번들 등록 | P0 | 동일 |
| 덱 삭제 시 카드 수량 표시 | P2 | `confirmationDialog`의 현재 구현 미확인. 별도 이슈 권장 |
| 카드 덱/섹션 이동 기능 | P2 | `CardEditView` 편집 모드에서 구현 가능하나 별도 설계 필요 |
| OCR 파싱 단위 테스트 | P3 | `parseRows(from:)` private 접근자. 리팩토링 없이 테스트 불가 |

---

## 변경 파일 요약

| 파일 | 변경 |
|------|------|
| `Services/ClaudeOCRService.swift` | OCR 병합 로직 UUID 기반으로 수정 |
| `Presentation/OCR/OCRView.swift` | OCRWordRow → TextField 인라인 편집 |
| `Presentation/Study/StudyView.swift` | SRS 평가 가이드 오버레이, AppStorage 연동 |
| `Presentation/Cards/CardEditView.swift` | 저장 햅틱 피드백, UIKit import |
| `FlippersTests/FlippersTests.swift` | SRSEngine 단위 테스트 13개 |
