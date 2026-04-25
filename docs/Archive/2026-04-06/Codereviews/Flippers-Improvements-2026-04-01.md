# Flippers 개선 작업 결과

> 작업 기준일: 2026-04-01
> 참조 문서: `Flippers-Code-Review-2026-04-01.md`, `Flippers-UX-Usecases.md`

---

## 구현 완료 항목

### Fix 1 — `insertFields` 빈 필드 저장 버그 수정
- **파일**: `Presentation/Cards/CardEditView.swift:188`
- **문제**: `example`, `onyomi`, `kunyomi` 필드는 값이 비어있어도 항상 `CardField`로 저장됨. StudyView의 `card.field(named:)` 체크가 빈 문자열도 "존재한다"고 판단해 `—` placeholder 대신 빈 공간을 렌더링.
- **수정**: `guard !value.isEmpty else { continue }` 조건으로 단순화. 빈 optional 필드는 저장하지 않음.
- **효과**: kanji 카드에서 音読み/訓読み 미입력 시 `—`가 올바르게 표시됨.

---

### Fix 2 — Firebase 오류 메시지 한국어 변환
- **파일**: `Presentation/Auth/AuthViewModel.swift`
- **문제**: `error.localizedDescription`이 Firebase 영문 원문 그대로 노출됨. 예: "The email address is badly formatted.", "There is no user record corresponding to this identifier."
- **수정**: `koreanMessage(for:)` private helper 추가. `error.localizedDescription`에서 알려진 Firebase 오류 패턴을 검출해 한국어 메시지로 변환.
  - 이메일 형식 오류, 비밀번호 불일치, 계정 없음, 이미 사용 중인 이메일, 비밀번호 6자 미만, 네트워크 오류, 요청 횟수 초과, 비활성화 계정 커버.
  - 이메일 폼 오류(`submitEmail`)와 Apple 로그인 오류(`handleAppleSignIn`) 양쪽에 적용.
- **효과**: R4 리스크 해소. 신뢰도 유지.

---

### Fix 3 — EmptyStudyView 신규 사용자 CTA 추가
- **파일**: `Presentation/Study/StudyView.swift`
- **문제**: 카드가 한 장도 없는 신규 사용자가 학습 탭에 진입하면 "오늘 복습 없음 / 내일 다시 오세요" 메시지만 표시. R1 리스크(신규 사용자 이탈 트리거).
- **수정**:
  - `EmptyStudyView`에 `hasNoCards: Bool`와 `onAddCard: () -> Void` 파라미터 추가.
  - `allCards.isEmpty`일 때: "카드가 없습니다" + "첫 카드 만들기" CTA 버튼 표시. 탭 시 `CardEditView` sheet 열림.
  - `allCards`는 있지만 `dueCards`가 없을 때: 기존 스타일 유지, 문구를 "모든 카드를 복습했습니다. 내일 다시 확인하세요."로 개선.
  - `StudyView`에 `showAddCard: Bool` 상태 + `.sheet(isPresented: $showAddCard)` 추가.
- **효과**: 신규 사용자가 학습 탭에서 바로 카드 생성으로 이어질 수 있음. 이탈 장벽 제거.

---

### Fix 4 — OCR Claude 보완 실패 시 배너 표시
- **파일**: `Presentation/OCR/OCRViewModel.swift`, `Presentation/OCR/OCRView.swift`
- **문제**: Claude API 호출 실패 시 `errorMessage`를 설정하지 않고 조용히 Vision fallback으로 넘어감. 사용자는 "단어 없음"처럼 보이거나, 읽기/뜻이 비어있는 이유를 알 수 없음.
- **수정**:
  - `OCRViewModel`에 `enhancementWarning: String?` 프로퍼티 추가.
  - Claude 실패 시 경고 메시지 설정: "Claude 보완에 실패했습니다. Vision 결과만 사용합니다. 읽기/뜻이 비어있을 수 있습니다."
  - `reviewStep` 상단에 오렌지색 dismissible 배너로 표시.
  - `reset()` 시 경고 초기화.
- **효과**: fallback 동작을 사용자에게 명시적으로 알림. 디버그 가능성 향상.

---

### Fix 5 — 학습 세션 중 덱 필터 변경 확인 알럿
- **파일**: `Presentation/Study/StudyView.swift`
- **문제**: 학습 세션 진행 중 덱 필터 메뉴를 실수로 탭하면 `session.start()`가 즉시 재호출되어 세션이 초기화됨. R5 데이터 손실 리스크.
- **수정**:
  - `pendingDeckID: UUID??` 상태 추가 (이중 옵셔널: outer nil = 대기 없음, inner value = 대기 중인 덱 선택).
  - `requestDeckFilter(_:)` 헬퍼 메서드 추가. 세션 활성(`totalCount > 0 && !isDone`) 시 확인 알럿 표시.
  - "초기화" 확인 시 pending 적용 후 세션 시작. "취소" 시 pending 리셋.
- **효과**: 진행 중 세션의 의도치 않은 초기화 방지.

---

### Fix 6 — ModelContainer 생성을 FlippersApp 레벨로 이동
- **파일**: `FlippersApp.swift`, `ContentView.swift`
- **문제**: `ContentView.body`에서 매 렌더링마다 `Self.makeContainer()`가 호출될 가능성 있음. SwiftData/CloudKit 설정 실패 시 `fatalError`가 view 재계산 중에 발생.
- **수정**:
  - `ModelContainer`를 `FlippersApp.init()`에서 한 번만 생성, `private let container`로 보관.
  - `.modelContainer(container)`를 `WindowGroup` 레벨에서 적용.
  - `ContentView`에서 `makeContainer()` 제거, `import SwiftData` 제거.
- **효과**: 컨테이너가 앱 생명주기당 1회만 생성됨. 재렌더링으로 인한 중복 생성 없음.

---

### Fix 7 — OCR 스캔 단계별 진행 메시지 표시
- **파일**: `Presentation/OCR/OCRViewModel.swift`, `Presentation/OCR/OCRView.swift`
- **문제**: 스캔 화면에 무한 spinner + 고정 텍스트만 표시. Claude API 호출 포함 시 5–15초 소요될 수 있어 앱이 멈춘 것으로 오인.
- **수정**:
  - `OCRViewModel`에 `scanningMessage: String` 추가.
  - Vision 단계: "텍스트 인식 중…", Claude 단계: "읽기 · 뜻 보완 중…"으로 메시지 전환.
  - `scanningStep`에서 동적 메시지 + "이미지 크기에 따라 최대 15초 소요됩니다" 안내 문구 추가.
- **효과**: 사용자가 진행 상태를 인지할 수 있음. "앱이 멈췄나?" 오해 방지.

---

## 미구현 항목 (구현 불가 또는 범위 초과)

| 항목 | 이유 |
|------|------|
| Firebase SPM 패키지 선언 | Xcode GUI 조작 필요. `.xcodeproj` pbxproj 직접 수정은 깨질 위험 있음. Xcode에서 수동으로 패키지 추가 필요. |
| `GoogleService-Info.plist` / `Config.plist` 번들 등록 | 동일한 이유. 빌드 타겟 리소스 추가는 Xcode GUI 필요. |
| API 키 `Config.plist` 노출 | 키 로테이션 및 Xcode Build Settings 연동은 프로덕션 배포 준비 단계에서 별도 처리 필요. |
| SRS 평가 가이드 첫 학습 시 오버레이 | `@AppStorage` 기반 "첫 세션 여부" 플래그 + 오버레이 View 신규 설계 필요. 별도 이슈로 처리 권장. |
| SRSEngine 및 OCR 파싱 단위 테스트 | FlippersTests 타겟 설정 및 xcodebuild 실행 환경 미비. |
| OCR 결과 인라인 편집 | `OCRWordRow`를 `TextField`로 교체하는 작업. 현재 `@Binding var word: OCRWord` 구조에서 가능하나 키보드 UX 설계 필요. 별도 이슈 권장. |
| fatalError → 복구 가능한 에러 상태 | MVP 범위 내에서 실용적 가치 낮음. 추후 스키마 마이그레이션 시 재검토. |

---

## 요약

7개 항목 구현 완료. 핵심 3개 사용자 여정 장벽 중 **진입 장벽(빈 상태 CTA)**과 **에러 신뢰도(한국어 오류 메시지, OCR 배너)**를 해소. 세션 데이터 손실 리스크(덱 필터 확인)와 런타임 안정성(ModelContainer 위치)도 함께 개선.
