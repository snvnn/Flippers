# Jouyou Kanji and Default Vocabulary Preset Plan

작성일: 2026-05-13
상태: 기능 계획 및 설계 초안, 파이프라인 분리 반영

## 목적

`Flippers`에 상용 한자 2136자와 기본 단어 프리셋을 추가하기 위한 제품/기술 설계를 고정한다.
이 기능은 사용자가 OCR이나 수동 입력 없이도 바로 학습을 시작할 수 있게 만드는 기본 콘텐츠 축이다.

## 사용자 경험 목표

- 첫 실행 또는 빈 상태에서 기본 학습 덱을 가져올 수 있다.
- 사용자는 상용 한자 2136자와 기본 단어 프리셋 중 필요한 세트를 선택해 설치한다.
- 설치된 프리셋은 일반 카드와 동일하게 덱, 섹션, SRS 상태를 가진다.
- 프리셋 카드는 사용자가 편집하거나 삭제할 수 있어야 한다.
- 같은 프리셋을 여러 번 가져와도 중복 카드가 대량 생성되지 않아야 한다.

## 카드 학습 UX

### 앞면

- 일본어 원문만 표시한다.
- 단어 카드는 `word` 필드만 표시한다.
- 한자 카드는 `kanji` 필드만 표시한다.
- 읽기, 뜻, 예문, 힌트 문구는 기본 상태에서 앞면에 노출하지 않는다.

### 앞면 길게 누르기

- 앞면을 길게 누르는 동안 요미가나를 표시한다.
- 단어 카드는 `reading` 필드를 요미가나로 사용한다.
- 한자 카드는 우선 `kunyomi`, `onyomi`를 표시 대상으로 삼되, 화면 문구는 "요미가나"가 아니라 "읽기"로 둔다.
- 손을 떼면 다시 일본어 원문만 보이게 한다.
- 길게 누르기는 정답 확인이 아니라 힌트 동작이므로, 카드 뒤집기와 분리한다.

### 뒷면

- 뜻과 예문을 표시한다.
- 단어 카드는 `meaning`과 `example`을 기본 표시한다.
- 한자 카드는 `meaning`, `onyomi`, `kunyomi`, `example`을 표시한다.
- 예문은 있으면 표시하고, 없으면 빈 영역을 만들지 않는다.
- 뒤집은 뒤에는 사용자가 SRS 평가 버튼을 누를 수 있다.

## 데이터 설계

### 딕셔너리 파이프라인 분리

상용 한자 2136자와 기본 단어 프리셋의 원천/작성/검증 데이터는 iOS 앱 타깃 밖의 `DictionaryPipeline/`에서 관리한다.
앱은 `DictionaryPipeline/exports/`에 생성된 app-ready JSON 또는 Swift fixture만 가져온다.

분리 이유:
- 공식 출처 데이터와 자체 작성 콘텐츠의 책임 범위를 명확히 한다.
- 라이선스/출처 추적 문서와 draft authoring 데이터를 앱 번들에 실수로 포함하지 않는다.
- 2136자 전체 검증, 리뷰 상태, export 재현성을 앱 구현과 분리한다.
- 향후 CLI, 리뷰 도구, 자동 품질 검사 확장이 쉬워진다.

파이프라인 디렉터리 역할:
- `DictionaryPipeline/sources/official/`: 공식 자료 출처와 사용 범위 기록
- `DictionaryPipeline/authoring/`: Flippers가 직접 작성한 뜻/예문/태그
- `DictionaryPipeline/schemas/`: authoring/export 스키마
- `DictionaryPipeline/scripts/`: 누락/중복/리뷰 상태 검증과 export 도구
- `DictionaryPipeline/exports/`: 앱이 소비할 생성 산출물

### 기존 모델 활용

현재 `Card`, `CardField`, `Deck`, `DeckSection`, `SRSState` 구조를 유지한다.
프리셋 전용 모델을 새로 만들기보다, 초기에는 기존 카드 필드 모델을 그대로 사용한다.

기존 필드 매핑:
- 단어 카드: `word`, `reading`, `meaning`, `example`
- 한자 카드: `kanji`, `meaning`, `onyomi`, `kunyomi`, `example`

추가로 고려할 필드:
- `presetID`: 프리셋 중복 import 방지용 안정 식별자
- `presetVersion`: 프리셋 갱신/마이그레이션 추적용 버전
- `sourceLabel`: 사용자가 프리셋 출처를 이해할 수 있는 표시명

구현 시 선택지:
- 최소 변경안: `CardField`에 `presetID`, `presetVersion`을 필드로 저장한다.
- 더 명확한 변경안: `Card`에 `presetID`, `presetVersion` 속성을 추가한다.

권장안:
- 프리셋 import 중복 방지가 핵심이므로 `Card`에 안정 식별자 속성을 추가하는 쪽이 장기적으로 더 낫다.
- 다만 SwiftData 마이그레이션 부담이 크면 v1은 `CardField` 기반으로 시작한다.

### 앱 프리셋 파일 형식

프리셋은 `DictionaryPipeline/exports/`에서 생성한 버전 고정 JSON 파일을 앱 번들에 포함한다.
원천 자료와 authoring draft 파일은 앱 번들에 포함하지 않는다.

후보 경로:
- `Flippers/Resources/Presets/jouyou-kanji-v1.json`
- `Flippers/Resources/Presets/basic-vocabulary-v1.json`

한자 프리셋 예시:

```json
{
  "id": "jouyou-kanji-v1",
  "title": "상용 한자 2136",
  "version": 1,
  "cards": [
    {
      "presetID": "jouyou-kanji-v1-0001",
      "type": "kanji",
      "kanji": "日",
      "meaning": "날, 해",
      "onyomi": "ニチ, ジツ",
      "kunyomi": "ひ, か",
      "example": "日本 / にほん / 일본"
    }
  ]
}
```

단어 프리셋 예시:

```json
{
  "id": "basic-vocabulary-v1",
  "title": "기본 단어",
  "version": 1,
  "cards": [
    {
      "presetID": "basic-vocabulary-v1-0001",
      "type": "word",
      "word": "学校",
      "reading": "がっこう",
      "meaning": "학교",
      "example": "学校に行きます。 / 학교에 갑니다."
    }
  ]
}
```

## Import 흐름

### 진입점

후보 위치:
- 첫 실행 빈 상태 CTA
- 카드 탭의 추가 메뉴
- 덱 탭의 "프리셋 가져오기"

권장 UX:
- 빈 상태에서는 "기본 학습 세트 가져오기" CTA를 노출한다.
- 기존 사용자에게는 카드/덱 추가 흐름 안에 "프리셋 가져오기"를 둔다.

### 선택 화면

표시 항목:
- 프리셋 이름
- 카드 수
- 설명
- 설치 여부
- 마지막 가져오기 버전

동작:
- 사용자가 프리셋을 선택한다.
- 앱이 새 Deck을 만들거나 기존 Deck에 추가할지 선택하게 한다.
- 기본값은 프리셋별 새 Deck 생성이다.

### 중복 방지

필수 조건:
- 같은 `presetID`가 이미 있으면 새 카드를 만들지 않는다.
- 기존 카드가 사용자가 수정한 카드일 수 있으므로, 자동 덮어쓰기는 하지 않는다.
- 프리셋 버전이 올라가면 새 항목만 추가하고, 기존 항목 변경은 별도 확인이 필요하다.

## 구현 단위

### Phase 1 - 설계/데이터 준비

- `DictionaryPipeline/` 워크스페이스 생성
- 프리셋 JSON 스키마 확정
- 상용 한자 2136자 데이터 출처와 라이선스 확인
- 기본 단어 프리셋 범위 확정
- 예문 포함 여부와 예문 출처 확인
- 카드 앞/길게 누르기/뒤 UI 동작을 테스트 기준으로 문서화

### Phase 2 - 딕셔너리 파이프라인

- 공식 상용한자표 source metadata 기록
- authoring JSON 스키마 확정
- 2136자 누락/중복/필수 필드 검증 스크립트 추가
- reviewed 항목만 app-ready preset으로 export

### Phase 3 - Seed import 기반

- export된 프리셋 파일을 앱 번들 리소스로 추가
- JSON decoder와 import service 추가
- 중복 방지 로직 추가
- 가져오기 화면 추가
- 빈 상태 CTA 연결

### Phase 4 - 학습 카드 UX 반영

- 앞면은 일본어 원문만 표시하도록 정리
- 길게 누르는 동안 읽기 표시
- 뒷면에 뜻과 예문 표시
- 기존 카드/한자 카드 모두 동일한 규칙으로 맞춤
- 접근성에서 길게 누르기 대체 액션 제공

### Phase 5 - 검증

- authoring validation 테스트
- export 재현성 테스트
- 프리셋 JSON decode 테스트
- 중복 import 테스트
- 단어/한자 카드 필드 매핑 테스트
- 학습 카드 앞면/뒷면 표시 규칙 테스트
- 실제 2136자 import 성능 확인

## 테스트 기준

자동 테스트 후보:
- `PresetCatalogTests`
- `PresetImportServiceTests`
- `StudyCardFaceTests`

검증해야 할 케이스:
- 상용 한자 프리셋 카드 수가 2136인지 확인
- 필수 필드가 비어 있는 카드가 없는지 확인
- 같은 프리셋을 두 번 가져와도 중복이 생기지 않는지 확인
- 앞면 기본 상태에서 읽기/뜻/예문이 노출되지 않는지 확인
- 길게 누르기 상태에서만 읽기가 노출되는지 확인
- 뒷면에 뜻과 예문이 표시되는지 확인

## 리스크와 결정 필요 항목

- 상용 한자 2136자 데이터의 출처와 라이선스를 확정해야 한다.
- 기본 단어 프리셋의 범위, 난이도, 카드 수를 정해야 한다.
- 예문을 직접 작성할지, 공개 데이터에서 가져올지 결정해야 한다.
- 기존 SwiftData 모델에 `presetID`를 추가할지, `CardField` 기반 메타데이터로 시작할지 결정해야 한다.
- 길게 누르기 힌트가 접근성 사용자에게 불리하지 않도록 대체 액션이 필요하다.
- 2136자 전체를 한 번에 import할 때 초기 로딩/저장 시간이 UX를 해치지 않는지 확인해야 한다.

## 현재 문서와의 관계

이 기능은 출시 차단 항목은 아니다.
현재 release gate가 끝난 뒤 제품 완성도를 높이는 P1/P2 기능으로 진행한다.

단, 첫 사용자 경험을 크게 개선하므로 실제 배포 전에 시간이 남으면 최소 버전만 포함할 수 있다.
최소 버전은 "상용 한자 덱 설치 + 앞면 원문만 표시 + 길게 누르기 읽기 힌트 + 뒷면 뜻/예문"이다.
