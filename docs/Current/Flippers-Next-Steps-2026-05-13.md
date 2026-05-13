# Flippers Next Steps

작성일: 2026-05-13
상태: 현재 저장소 기준 후속 진행 항목

## 목적

이 문서는 `Flippers`에서 다음에 진행해야 할 일을 한곳에 고정한다.
기준은 현재 코드, `docs/Current` 문서, 릴리스 게이트, 운영 runbook, 테스트 체크리스트다.

## 현재 판단

`docs/plans/2026-04-21-flippers-master-plan.md`의 1차 기술 안정화 과제는 체크상 완료되어 있다.
남은 핵심 작업은 새 기능 추가보다 `릴리스 운영 확정`, `공개 문서 마감`, `실환경 검증`이다.

현재 배포 판단은 아직 `release-ready`가 아니다.
`docs/release/2026-04-21-flippers-release-readiness-checklist.md`의 must-block-release 항목이 남아 있다.

## P0 - 출시 차단 항목

### 1. 연락 및 권리 요청 경로 확정

완료해야 할 일:
- 공개용 문의 채널 확정
- 개인정보 처리 문의 / 권리 요청 접수 경로 확정
- 계정 삭제와 전체 데이터 삭제 요청 접수 경로 확정
- 데이터 반출(export) 지원 여부 확정

현재 문서의 보수적 기본값:
- `yunh1205@gmail.com`을 공개 문의와 개인정보/권리 요청의 단일 접수 경로로 사용
- 계정 삭제와 전체 데이터 삭제는 같은 이메일 기반 수동 처리로 통합
- 데이터 반출은 이번 릴리스에서는 기본 미지원으로 두고, 요청 시 미지원 안내

산출물:
- `docs/release/2026-04-21-flippers-release-readiness-checklist.md` 갱신
- 개인정보처리방침 반영본
- App Store 지원/문의 메타데이터에 동일한 접점 반영

### 2. OCR 운영 프록시 확정

완료해야 할 일:
- 실제 운영 프록시 배포 대상 확정
- 운영 URL을 Release 빌드 설정/배포 파이프라인에 반영
- 서버 측 비밀 키 저장 방식 확정
- 운영 로그 보관 정책과 접근 범위 확정
- 사고 대응 / 키 유출 대응 절차 문서화
- 과거 노출 가능 키 폐기 / 교체 여부 확인

현재 코드 기준:
- iOS 클라이언트는 Claude API를 직접 호출하지 않는다.
- 앱은 Vision으로 추출한 단어 텍스트만 프록시에 보낸다.
- `tools/ocr-proxy-server.mjs`는 로컬 스텁이며 `127.0.0.1` 바인딩 기준이다.
- 실제 운영 배포는 별도 서비스로 보고 인증, rate limit, request size 제한, 관측성, 비밀 관리가 필요하다.

검증 기준:
- 앱 번들에 비밀 키가 없어야 한다.
- 운영 프록시는 `words` 배열 기반 text-only 요청만 허용해야 한다.
- image payload는 명시적으로 거절되어야 한다.
- opt-in을 켠 경우에만 외부 보완이 동작해야 한다.

### 3. 공개 문서와 App Store 제출값 마감

완료해야 할 일:
- 개인정보처리방침에 실제 운영자, 문의 경로, 외부 처리 구조 반영
- App Store Privacy 제출값 확정
- 공개 문구와 실제 구현 정합성 점검
- 이용약관 공개 여부 결정
- App Store / 공개 메타데이터용 웹사이트 또는 지원 링크 확정

확인해야 할 정합성:
- OCR 외부 보완은 opt-in이다.
- 원본 이미지는 앱에서 Claude로 직접 전송하지 않는다.
- 외부 보완은 Vision 추출 텍스트만 프록시로 전달한다.
- 지원/권리 요청 접점은 문서, 앱스토어 제출값, 공개 문구에서 동일해야 한다.

참고 원문:
- `docs/Archive/2026-04-06/Policies/Flippers-Privacy-Policy-Draft-ko-KR-2026-04-06.md`
- `docs/Archive/2026-04-06/AppStore/Flippers-App-Privacy-Disclosure-Draft-2026-04-06.md`
- `docs/Current/Flippers-Release-Privacy-Summary-2026-04-06.md`

### 4. 실환경 Firebase / Apple Sign-In 검증

완료해야 할 일:
- 실제 `GoogleService-Info.plist` 확보
- Release / Archive 배포용 빌드에 설정 파일 포함 확인
- 같은 빌드 ID에서 Firebase smoke test 수행
- 같은 빌드 ID에서 실제 Apple Sign-In smoke test 수행
- 배포 빌드 기준 SDK / 인증 / 동기화 경로 재점검

현재 차단 조건:
- 저장소에는 `GoogleService-Info.plist`가 없다.
- 따라서 현재 저장소 상태만으로 Firebase 로그인, Apple Sign-In, Firebase 연동 smoke test를 PASS 처리할 수 없다.

PASS 기준:
- 시뮬레이터, 로컬 목, debug fallback은 참고 자료로만 사용한다.
- 실제 배포 빌드와 실제 계정/프로젝트에서 나온 결과만 PASS 근거로 기록한다.

## P1 - 출시 안정성 보강

### 5. 상용 한자 / 기본 단어 프리셋 설계

완료해야 할 일:
- 상용 한자 2136자 프리셋 데이터 출처와 라이선스 확정
- 기본 단어 프리셋 범위, 난이도, 카드 수 확정
- 프리셋 JSON 스키마와 import 중복 방지 기준 확정
- 학습 카드 UX를 "앞면 일본어 원문만 표시, 길게 누를 때 요미가나, 뒷면 뜻 및 예문"으로 정리
- 접근성 사용자를 위한 길게 누르기 대체 액션 설계

설계 기준:
- 단어 카드 앞면은 `word`만 표시한다.
- 한자 카드 앞면은 `kanji`만 표시한다.
- 길게 누르는 동안 단어 카드는 `reading`, 한자 카드는 `onyomi`/`kunyomi`를 표시한다.
- 뒷면은 `meaning`과 `example`을 중심으로 표시한다.
- 프리셋 카드는 일반 카드와 같은 `Deck`, `Card`, `CardField`, `SRSState` 구조를 사용한다.

상세 문서:
- `docs/plans/2026-05-13-jouyou-kanji-default-preset-plan.md`

### 6. OCR 품질 실데이터 검증

완료해야 할 일:
- 실제 단어장/교과서 이미지 샘플로 OCR 결과 확인
- 현재 가로형 일본어 단어표 외 레이아웃에서 실패 패턴 수집
- 파서 개선이 필요한 케이스를 테스트로 먼저 고정
- 사용자가 저장 전 수정해야 하는 partial result 안내가 충분한지 확인

현재 상태:
- shifted columns, split meanings, checkbox noise, unsupported Japanese-only row는 테스트에 들어가 있다.
- 여전히 실제 문서 레이아웃 다양성에 대한 검증은 부족하다.

### 7. 검증 명령 재실행 및 결과 기록

우선 실행:

```bash
node --test tools/tests/ocr-proxy-server.test.mjs
```

Xcode 환경에서 실행:

```bash
xcodebuild build-for-testing \
  -project Flippers.xcodeproj \
  -scheme Flippers \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

필요 시 좁은 테스트:
- `OCRConfigurationTests`
- `ClaudeOCRServiceTests`
- `OCRRowParserTests`
- `OCRViewModelTests`
- `AuthViewModelTests`
- `FirebaseBootstrapTests`
- `FirebaseAuthErrorMappingTests`

기록 위치:
- `docs/testing/2026-04-21-flippers-verification-matrix.md`
- 필요하면 새 실행 로그 문서 추가

## P2 - 문서 / 제품 기준 정리

### 8. 누락된 기준 문서 확인

현재 마스터 플랜과 기존 문서 일부는 `SRS.md`를 참조하지만, 현재 저장소 루트에는 `SRS.md`가 없다.

결정할 일:
- `SRS.md`를 복구하거나 새로 작성
- 문서 참조에서 `SRS.md`를 제거하고 현재 문서 체계로 대체

### 9. UI 테스트와 회귀 기준 보강

현재 `FlippersUITests` 타깃은 존재하지만, 릴리스 게이트의 핵심 흐름을 자동으로 방어하는 수준은 아니다.

후보 범위:
- 앱 launch smoke
- 로컬 모드 진입
- OCR 업로드 화면 기본 표시
- 외부 보완 토글 비가용 상태
- 저장 전 검토 화면 주요 상태

## 지금 바로 할 순서

1. `docs/release/2026-04-21-flippers-release-readiness-checklist.md`의 미완료 항목을 실제 결정값으로 채운다.
2. 운영 프록시 배포 대상, 비밀 키 저장 방식, 로그 정책, 사고 대응 절차를 확정한다.
3. 개인정보처리방침과 App Store Privacy 제출값을 현재 구현 기준으로 마감한다.
4. 실제 `GoogleService-Info.plist`와 Release / Archive 빌드 ID를 준비해 Firebase / Apple Sign-In smoke test를 실행한다.
5. 상용 한자 2136자와 기본 단어 프리셋의 데이터 출처, 스키마, 카드 표시 규칙을 확정한다.
6. 실제 OCR 샘플로 품질 검증을 진행하고, 실패 패턴을 테스트로 추가한다.

## 지금은 미루는 일

- 릴리스 게이트를 건너뛰는 새 기능 확장
- 대규모 UI 재설계
- 동기화 구조 재작성
- `card-ace-sync` 관련 작업
- 운영/문서/실환경 검증 없이 App Store 제출 진행

## 근거로 확인한 파일

- `docs/README.md`
- `docs/Current/Flippers-Current-Priorities-2026-04-06.md`
- `docs/Current/Flippers-Current-Status-2026-04-06.md`
- `docs/Current/Flippers-Release-Privacy-Summary-2026-04-06.md`
- `docs/plans/2026-04-21-flippers-master-plan.md`
- `docs/plans/2026-05-13-jouyou-kanji-default-preset-plan.md`
- `docs/release/2026-04-21-flippers-release-readiness-checklist.md`
- `docs/release/2026-04-24-flippers-release-blocker-followup-plan.md`
- `docs/operations/2026-04-21-flippers-ocr-proxy-runbook.md`
- `docs/testing/2026-04-21-flippers-firebase-smoke-checklist.md`
- `docs/testing/2026-04-21-flippers-verification-matrix.md`
- `Flippers/Presentation/OCR/OCRView.swift`
- `Flippers/Presentation/OCR/OCRViewModel.swift`
- `Flippers/Services/ClaudeOCRService.swift`
- `tools/ocr-proxy-server.mjs`
