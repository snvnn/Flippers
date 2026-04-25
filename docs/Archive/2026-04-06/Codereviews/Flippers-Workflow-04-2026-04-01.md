# Flippers 개선 작업 — 04 Implementation Rules 결과

> 작업 기준일: 2026-04-01
> 기준 문서: `04-implementation-rules.md`
> 이전 작업: Fix 1–15 (sessions 01–03)

---

## 04 가드레일 적용 내용

> "구현 가능한 항목은 실제 코드에 반영해라. 추천합니다/할 수 있습니다로 끝내지 마라."

이전 세션에서 "추정", "설계 필요", "향후 처리" 등으로 남겨진 항목을 재검토하고 구현 가능한 것을 즉시 반영했다.

---

## 이번 세션 구현 (Fix 16–19)

### Fix 16 — AuthView 로그인/회원가입 Segmented Picker
- **파일**: `Presentation/Auth/AuthView.swift`
- **배경**: UX 문서 UC1-A (High), UC1-C (Medium). 기본값이 로그인 모드이고 회원가입 전환이 하단 작은 텍스트(`font(.footnote)`)로만 가능. 44pt 탭 영역 미달 가능성.
- **수정**:
  - 이메일 폼 위에 `Picker("모드", selection: $vm.isSignUpMode)` + `.pickerStyle(.segmented)` 추가.
  - 기존 "계정이 없으신가요? 회원가입" / "이미 계정이 있으신가요? 로그인" 텍스트 버튼 제거.
  - `onChange(of: vm.isSignUpMode)` → `errorMessage = nil` (기존 버튼에 있던 동작 유지).
- **효과**: 로그인/회원가입이 동등하게 visible. 44pt 탭 영역 충족. 모드 전환 즉시 인지 가능.

### Fix 17 — 카드 long press → reading 힌트 (CLAUDE.md 명세 복원)
- **파일**: `Presentation/Study/StudyView.swift`
- **배경**: CLAUDE.md 제스처 명세: "길게 탭 → 발음(요미가나) 힌트 표시". 실제 구현은 별도 버튼 탭. UX 문서 UC4-D (Medium): "카드를 길게 눌러보면 아무 반응이 없어 UI가 설명한 것과 다르다는 느낌."
- **수정**: `flashcard()` 뷰에 `.onLongPressGesture(minimumDuration: 0.5)` 추가. 트리거 시 `session.showReading.toggle()` 실행 (기존 버튼과 동일 동작, 카드 직접 탭으로도 가능).
- **부수 수정**: 버튼 레이블 "길게 눌러 발음" → "길게 눌러 발음 표시" (명확성 개선).
- **효과**: CLAUDE.md 명세와 실제 동작 일치. 카드 직접 long press와 버튼 탭 둘 다 동작.

### Fix 18 — 카드 뒤집힌 후 스와이프 방향 힌트
- **파일**: `Presentation/Study/StudyView.swift`
- **배경**: UX 문서 UC4-C (Medium). 스와이프 제스처가 Good/Again에만 매핑됨. 처음 쓰는 사람은 스와이프 가능 여부 자체를 모름.
- **수정**: `studyContent`에서 `session.isFlipped` 시 `"← Again ... Good →"` 힌트 HStack 표시. `.quaternaryLabel` 색상으로 시각적 노이즈 최소화.
- **효과**: 스와이프 제스처 발견 가능성 향상. 평가 버튼과 병행 사용 유도.

### Fix 19 — OCR Done 화면 "카드 탭에서 확인" 안내
- **파일**: `Presentation/OCR/OCRView.swift`
- **배경**: UX 문서 UC2-E (Medium). Done 화면에 "추가 스캔" 버튼만 있고 생성된 카드 확인 동선이 없음.
- **수정**: `doneStep`에 "카드 탭에서 생성된 카드를 확인할 수 있습니다." 안내 텍스트 추가.
- **제한**: 탭 직접 전환(딥링크)은 `MainTabView` 공유 상태 필요. 텍스트 안내로 대체 (구현 비용 대비 효과 적절).
- **효과**: 사용자가 생성된 카드 위치를 인지. 탭 직접 전환은 MVP 이후 처리.

---

## 재검토: "추정"으로 남겨진 항목 검증

| 항목 | 문서 추정 | 실제 코드 확인 | 결론 |
|------|---------|-------------|------|
| `createDeck()` 후 자동 선택 | "(추정: 수동으로 다시 선택해야 한다면 불편)" | `selectedDeck = deck` 이미 존재 (line 199) | ✅ 이미 자동 선택 |
| `confirmationDialog` card count | "(추정: count 표시 여부 불확실)" | count 없었음 → Fix 13으로 해결 | ✅ 해결 |
| Firebase 오류 메시지 영어 노출 | "(추정)" | `errorMessage = error.localizedDescription` 확인 | ✅ Fix 2로 해결 |
| Apple 로그인 버튼 스크롤 필요 | "(추정, 화면 크기 의존)" | ScrollView 내에 있음 — 작은 화면에서 발생 가능 | ⏭ 레이아웃 조정은 기기 테스트 필요 |
| `SRSStatusBadge` 정의 여부 | `CardsView.swift`에서 참조 | `struct SRSStatusBadge` in CardsView.swift:180 | ✅ 정의됨 |

---

## 최종 보류 항목 (Blocker 명시)

| 항목 | Blocker | 향후 처리 방향 |
|------|---------|-------------|
| Firebase SPM 패키지 선언 | Xcode GUI 필요. pbxproj 수동 편집 시 project 파일 손상 위험 | Xcode에서 File > Add Package Dependencies 로 수동 추가 |
| Firebase plist 번들 등록 | 동일 | Build Phases > Copy Bundle Resources 에 수동 추가 |
| OCR Done → 카드 탭 직접 전환 | MainTabView 선택 탭 공유 상태(@AppStorage 또는 Environment 오브젝트) 필요 | `@AppStorage("selectedTab")` 전역 상태 추가 후 처리 |
| Apple 로그인 버튼 스크롤 노출 | 기기 화면 크기 의존. 시뮬레이터 없이 검증 불가 | 실제 기기/시뮬레이터 테스트 후 레이아웃 조정 |
| Hard/Easy 스와이프 제스처 추가 | CLAUDE.md 명세는 Good(우)/Again(좌) 2개만 정의. 명세 변경 시 추가 가능 | 명세 업데이트 후 DragGesture에 수직 방향 추가 |

---

## 누적 변경 파일 (전체 세션 최종)

| 파일 | 수정 내용 |
|------|---------|
| `FlippersApp.swift` | ModelContainer App 레벨 이동 |
| `ContentView.swift` | ModelContainer 제거 |
| `Presentation/Auth/AuthView.swift` | Segmented Picker 추가, 텍스트 토글 제거 |
| `Presentation/Auth/AuthViewModel.swift` | Firebase 오류 한국어 변환 |
| `Presentation/Study/StudyView.swift` | EmptyStudyView CTA, 필터 알럿, SRS 가이드, srsState nil 복구, long press, 스와이프 힌트 |
| `Presentation/Cards/CardEditView.swift` | 빈 필드 버그, 햅틱 |
| `Presentation/OCR/OCRViewModel.swift` | 에러 배너, 스캔 메시지 |
| `Presentation/OCR/OCRView.swift` | 에러 배너, 스캔 메시지, 인라인 편집, 덱 미선택 알럿, Done 안내 |
| `Presentation/Deck/DeckDetailView.swift` | 덱 삭제 카드 수량 |
| `Services/ClaudeOCRService.swift` | OCR 병합 UUID 기반 |
| `FlippersTests/FlippersTests.swift` | SRSEngine 단위 테스트 13개 |
