# Flippers Compliance Working Draft

작성일: 2026-04-06
대상 프로젝트: `Flippers` iOS/iPadOS 학습 앱
문서 상태: 워킹 드래프트
주의: 이 문서는 현재 저장소 구현을 기준으로 작성한 실무용 초안이며, 법률 자문은 아니다.

## 1. 목적

이 문서는 `Flippers` 앱의 현재 구현을 기준으로 다음을 정리한다.

- 어떤 데이터가 처리되는지
- 어떤 외부 서비스가 관여하는지
- 어떤 규제 및 플랫폼 요구사항이 적용될 가능성이 높은지
- 출시 전 반드시 보완해야 할 항목이 무엇인지

## 2. 범위

본 문서는 아래 코드와 문서에 근거해 작성했다.

- `SRS.md`
- `Flippers/Flippers/FlippersApp.swift`
- `Flippers/Flippers/Presentation/Auth/AuthViewModel.swift`
- `Flippers/Flippers/Data/Remote/FirebaseAuthRepository.swift`
- `Flippers/Flippers/Data/Remote/FirebaseSyncService.swift`
- `Flippers/Flippers/Presentation/OCR/OCRView.swift`
- `Flippers/Flippers/Presentation/OCR/OCRViewModel.swift`
- `Flippers/Flippers/Services/ClaudeOCRService.swift`
- `Flippers/Flippers/Domain/Models/*.swift`
- `Flippers/Flippers.xcodeproj/project.pbxproj`

## 3. 제품 개요

`Flippers`는 일본어 단어/한자 암기용 iOS/iPadOS 앱이다. 사용자는 수동 입력 또는 OCR로 카드를 만들고, SRS 기반으로 학습하며, 계정 인증과 일부 클라우드 연동을 사용할 수 있다.

현재 코드 기준 핵심 기능은 다음과 같다.

- 이메일/비밀번호 로그인
- Apple 로그인
- OCR 이미지 업로드
- 온디바이스 Vision 텍스트 인식
- 기본값 비활성의 외부 AI 보완 옵션
- Claude API를 통한 읽기/뜻 보완
- SwiftData 기반 로컬 저장
- CloudKit 자동 동기화
- Firebase 초기화 및 인증 연동
- Firestore 동기화용 서비스 코드 존재

## 4. 현재 데이터 처리 인벤토리

### 4.1 식별 데이터

- 이메일 주소
- Firebase UID
- Apple 로그인에서 제공되는 식별 토큰 및 최초 로그인 시 이름/이메일 가능성

근거:

- `User.email`
- `FirebaseAuthRepository`
- `AuthViewModel.prepareAppleSignInRequest`

### 4.2 학습 데이터

- 덱 이름
- 섹션
- 카드 필드
- SRS 상태
- 학습 로그
- 생성 일시, 복습 일시

근거:

- `Deck`
- `Card`
- `CardField`
- `SRSState`
- `ReviewLog`

### 4.3 OCR 관련 데이터

- 사용자가 선택하거나 촬영한 이미지
- Vision OCR 추출 결과
- Claude 보완 결과
- OCR 원본 메타 모델(`OCRSource`)에 정의된 `imagePath`, `rawText`

근거:

- `OCRView`
- `OCRViewModel`
- `ClaudeOCRService`
- `OCRSource`

주의:

- `OCRSource` 모델은 정의되어 있으나 현재 저장 흐름에 명시적으로 연결된 코드는 보이지 않는다.
- Claude 외부 보완은 Vision이 추출한 단어 텍스트 보완에만 사용되며, 원본 OCR 이미지는 앱에서 직접 외부 전송하지 않는다.

### 4.4 디바이스 및 권한 데이터

- 카메라 접근 권한
- 사용자가 선택한 사진 라이브러리 이미지

근거:

- `OCRView`
- `project.pbxproj`의 `NSCameraUsageDescription`

## 5. 시스템 및 제3자 처리자 현황

### 5.1 Apple

- `CloudKit`: `ModelConfiguration(..., cloudKitDatabase: .automatic)`으로 자동 동기화가 설정되어 있다.
- `Sign in with Apple`: Apple 로그인 요청 시 `.fullName`, `.email` scope를 요청한다.
- `PhotosPicker` 및 카메라: 사용자 단말에서 이미지 선택/촬영에 사용된다.

의미:

- Apple은 단순 플랫폼 제공자를 넘어 데이터 처리 경로에 관여한다.
- 개인정보처리방침과 App Store 개인정보 레이블에서 이 경로를 반영해야 한다.

### 5.2 Google Firebase

- `FirebaseApp.configure()`가 앱 시작 시 호출된다.
- `FirebaseAuthRepository`는 이메일/비밀번호, Apple credential 기반 로그인 처리를 구현한다.
- `FirebaseSyncService`는 Firestore 업로드/조회 기능을 구현하지만, 현재 저장소에서 실제 호출 경로는 확인되지 않는다.

의미:

- 현재 코드상 Firebase Auth는 활성 경로로 보는 것이 타당하다.
- Firestore는 "구현은 있으나 실제 연결 여부는 미확정" 상태로 문서화하는 것이 맞다.

### 5.3 Anthropic Claude API

- OCR 보완 시 Vision이 추출한 단어 텍스트가 `https://api.anthropic.com/v1/messages`로 전송된다.
- 원본 OCR 이미지는 현재 앱에서 직접 Anthropic으로 전송하지 않는다.
- API 키는 번들 `Config.plist`가 아니라 `Debug` 빌드의 `CLAUDE_API_KEY` 환경 변수에서만 읽도록 구현되어 있다.
- 2026-04-06 기준 OCR 업로드 화면에 외부 보완 opt-in 토글, 경고 문구, 처리 안내 시트가 추가되었다.
- 2026-04-06 기준 API 키가 없으면 OCR 화면에서 외부 보완 토글이 비활성화되도록 1차 안전장치가 추가되었다.

의미:

- OCR 입력물에 개인정보, 민감정보, 제3자 정보가 포함될 수 있다.
- 외부 전송 사실, 목적, 보관 정책, 국외 이전 여부를 공지해야 한다.
- 클라이언트 앱 번들에서 비밀 키를 사용하는 현재 방식은 보안과 컴플라이언스 양쪽에서 부적절하다.

## 6. 적용 가능성이 높은 컴플라이언스 영역

### 6.1 기본 프라이버시 컴플라이언스

앱이 실제 사용자 데이터를 수집하거나 외부 전송한다면 최소한 아래는 필요하다.

- 개인정보처리방침
- 서비스 약관 또는 이용조건
- 제3자 처리자 목록
- 데이터 보관 및 삭제 정책
- 데이터 주체 요청 처리 절차

### 6.2 Apple App Store 요구사항

출시 시 다음 항목이 사실상 필요하다.

- App Privacy Nutrition Labels 작성
- 카메라 권한 사유 명확화
- Sign in with Apple 사용 시 관련 정책 준수
- 외부 전송되는 OCR 이미지/텍스트의 공개

### 6.3 한국 개인정보보호법(PIPA)

다음 조건이면 적용 가능성이 높다.

- 한국 거주자를 대상으로 서비스함
- 한국어 의미 데이터를 제공하며 한국 사용자를 상정함
- 한국 사업자 또는 한국 내 운영 실체가 있음

이 경우 특히 중요하다.

- 수집 목적 및 항목 고지
- 보유 및 이용기간 명시
- 제3자 제공 또는 처리위탁 고지
- 국외 이전 고지
- 파기 절차

### 6.4 GDPR

EU/EEA 사용자에게 제공하거나 EU 사용자를 대상으로 하면 검토가 필요하다.

- 처리 근거
- 국외 이전 메커니즘
- 데이터 주체 권리
- 처리자 계약
- 아동 대상 여부

### 6.5 미국 주법 프라이버시 규제

미국, 특히 캘리포니아 사용자 대상이면 CPRA/CCPA 등 주법 검토가 필요하다.

현재 코드만으로 매출/규모 기준 충족 여부는 알 수 없으므로 "즉시 적용"이라고 단정할 수는 없다. 다만 미국 대상 배포를 계획한다면 사전 검토 대상이다.

## 7. 현재 구현 기준 갭 분석

### 7.1 높은 우선순위

1. OCR 외부 텍스트 보완 통제: 부분 조치 완료

- 2026-04-06 기준 OCR 업로드 화면에 외부 보완 토글, 활성화 경고, 처리 안내 시트가 추가되었다.
- 기본값은 로컬 OCR만 사용하도록 설정되어 사용자 선택권은 이전보다 개선되었다.
- 현재 앱은 원본 OCR 이미지를 직접 Anthropic으로 전송하지 않는다.
- 다만 공개 정책 문서, 서버 프록시, 데이터 처리자 고지는 여전히 남아 있다.

2. 클라이언트 번들 기반 API 키 사용

- `ClaudeOCRService`의 직접 호출은 `Debug` 빌드에서 `CLAUDE_API_KEY` 환경 변수가 있을 때만 허용된다.
- 배포 빌드에서 안전하게 운영하려면 서버 프록시나 안전한 토큰 교환 구조가 여전히 필요하다.
- 보안 사고로 이어질 수 있고, 처리 위탁 통제와 감사 대응 측면에서도 취약하다.

3. 저장 위치와 처리자 경계가 불명확함

- SwiftData + CloudKit 자동 동기화가 활성화되어 있다.
- Firebase Auth가 실제 사용된다.
- Firestore 동기화 코드도 존재한다.
- 결과적으로 운영자가 단일 데이터 맵을 설명하기 어렵다.

4. 데이터 삭제/반출 절차 부재

- 덱 삭제는 있으나 계정 삭제, 전체 데이터 삭제, 데이터 export 요청 처리 경로는 확인되지 않았다.
- 출시형 서비스라면 법규와 사용자 신뢰 측면에서 부족하다.

### 7.2 중간 우선순위

1. 개인정보처리방침, 약관, 보관기간 문서 부재

- 2026-04-06 기준 개인정보처리방침 공개 초안이 추가되었다.
- 다만 운영자 정보, 연락처, 법률 검토, 이용약관 초안은 여전히 필요하다.

2. OCR 데이터 최소수집 기준 부재

- 원본 이미지는 외부 전송하지 않더라도, 기기 내 OCR이 민감한 텍스트를 추출할 수 있다.
- 민감정보, 타인 정보, 문서 전체 이미지 업로드에 대한 사용자 안내는 계속 유지되어야 한다.

3. 아동 대상 여부 및 연령 정책 부재

- 학습 앱 특성상 미성년자 사용 가능성을 배제하기 어렵다.
- 아동 대상 서비스가 아니라면 연령 제한 또는 보호자 정책이 필요하다.

4. 감사용 운영 문서 부재

- 처리자 목록, 서브프로세서, 사고 대응, 접근 통제, 키 관리 문서가 없다.

### 7.3 낮은 우선순위 또는 확인 필요

1. Firestore 실제 사용 여부

- 구현은 있으나 호출 경로가 없다.
- 제품 출시 문서에서는 "비활성/미사용" 여부를 명확히 정리해야 한다.

2. `OCRSource`의 실사용 여부

- 모델은 존재하지만 현재 OCR 저장 흐름에 삽입하는 코드는 보이지 않는다.
- 실제 저장하지 않는다면 정책 문서에서 제외하거나 예정 항목으로 구분해야 한다.

## 8. 출시 전 필수 조치

### 8.1 반드시 필요한 문서

- 공개용 개인정보처리방침
- 공개용 이용약관
- 내부용 데이터 맵
- 내부용 처리자/서브프로세서 목록
- 내부용 보관 및 삭제 기준서
- 보안 사고 대응 절차

### 8.2 제품 변경이 필요한 항목

- OCR 업로드 전 외부 전송 고지 및 사용자 선택권 제공
- Claude API 호출을 서버 프록시 또는 안전한 토큰 교환 구조로 변경
- CloudKit와 Firebase의 역할 분리를 명확히 설계
- 계정 삭제 및 데이터 삭제 흐름 구현
- 사용자 데이터 export 흐름 구현 여부 결정

주의:

- 첫 번째 항목은 2026-04-06 앱 UI 수준에서 1차 반영되었다.
- 그러나 법적 고지 문서와 서버 측 비밀 관리 구조는 아직 미완료다.

### 8.3 운영 설정이 필요한 항목

- Firebase Auth 및 Firestore 지역 설정 검토
- CloudKit 저장 위치와 운영 계정 통제 확인
- Anthropic 데이터 보존/학습 사용 정책 검토
- 키 회전 정책 수립
- 개발/운영 환경 분리

## 9. 권장 데이터 분류표

| 데이터 항목 | 예시 | 민감도 | 저장 위치 | 외부 전송 | 비고 |
| --- | --- | --- | --- | --- | --- |
| 계정 식별자 | 이메일, UID | 중간 | Firebase Auth, 로컬 모델 | 있음 | 로그인 필수 데이터 |
| 학습 콘텐츠 | 단어, 뜻, 예문 | 중간 | SwiftData, CloudKit, 잠재적 Firestore | 가능 | 사용자 작성 데이터 |
| 학습 이력 | 평점, 복습 시각, due date | 중간 | SwiftData, CloudKit, 잠재적 Firestore | 가능 | 행동 데이터 |
| OCR 이미지 | 교재/노트 사진 | 높음 | 단말 임시 처리, 잠재적 저장 | 있음 | 제3자 정보 포함 가능 |
| OCR 원문 텍스트 | 추출 텍스트 | 중간~높음 | 모델 정의 존재 | 있음 | 문맥상 개인정보 가능 |
| 인증 토큰 | Apple/Firebase credential | 높음 | SDK 처리 | 있음 | 직접 로깅 금지 |

## 10. 권장 보관 정책 초안

정책은 서비스 모델에 따라 달라지지만, 현재 앱 구조 기준 최소 초안은 아래와 같다.

- 계정 데이터: 계정 유지 기간 동안 보관, 탈퇴 후 지체 없이 삭제 또는 법적 예외 범위 내 분리 보관
- 카드/덱/SRS 데이터: 사용자 계정 유지 기간 동안 보관
- OCR 이미지: 원칙적으로 장기 보관 금지, 처리 후 즉시 폐기 또는 사용자가 명시적으로 저장한 경우에만 저장
- OCR 원문 텍스트: 카드 생성에 필요하지 않다면 영구 보관 금지
- 인증 로그/오류 로그: 보안 목적 범위 내 최소 기간만 보관

## 11. 배포 전 체크리스트

- 개인정보처리방침 초안이 실제 데이터 흐름과 일치하는가
- App Store 개인정보 레이블이 실제 SDK 사용과 일치하는가
- OCR 이미지의 외부 전송을 UI에서 사전에 설명하는가
- 사용자가 데이터 삭제를 요청할 수 있는가
- Claude API 키가 클라이언트 앱에 포함되지 않는가
- Firestore가 실제 미사용이면 SDK/코드/문서에서 정리했는가
- CloudKit 사용 여부와 사용자 고지 문구가 일치하는가
- 제3자 처리자별 지역, 보관, 계약 상태를 확인했는가

## 12. 권장 후속 작업 순서

1. 데이터 흐름 확정

- 최종 저장소가 CloudKit인지 Firebase인지, 또는 둘 다인지 결정
- Firestore 미사용이면 제거

2. OCR 아키텍처 정리

- Claude 직접 호출을 중단하고 서버 경유 구조로 변경
- OCR 이미지 전송 동의 문구 추가

3. 사용자 권리 기능 구현

- 계정 삭제
- 데이터 일괄 삭제
- 데이터 export 또는 지원 채널

4. 정책 문서 공개본 작성

- 개인정보처리방침
- 이용약관
- App Store 제출용 개인정보 라벨

주의:

- 개인정보처리방침 초안은 2026-04-06 기준 작성되었다.
- App Store 제출용 개인정보 요약 초안도 2026-04-06 기준 작성되었다.
- 아직 이용약관 초안과 최종 제출용 검토는 남아 있다.

## 13. 현재 시점의 실무 판단

현재 `Flippers`는 프로토타입 또는 MVP 단계의 구현으로 보이며, 개발 실험용으로는 충분할 수 있다. 그러나 외부 사용자 대상 베타 또는 정식 배포를 하려면 프라이버시 고지, OCR 외부 전송 통제, 비밀 키 관리, 데이터 삭제 절차가 선행되어야 한다.

특히 아래 두 항목은 출시 차단 이슈로 보는 것이 맞다.

- 클라이언트 번들에 Claude API 키를 두는 구조
- 공개 정책 문서 및 서버 측 비밀 관리 없이 OCR 외부 전송을 운영하는 구조

## 14. 부록: 코드 기반 관찰 메모

- `FlippersApp.swift`: Firebase 초기화 + CloudKit 자동 동기화 설정
- `AuthViewModel.swift`: Apple 로그인 시 이름/이메일 scope 요청
- `FirebaseAuthRepository.swift`: 이메일/비밀번호 및 Apple 로그인 활성 경로
- `FirebaseSyncService.swift`: Firestore 저장 구현 존재, 현재 호출 경로 미확인
- `OCRView.swift`: 사진 선택 및 카메라 촬영 UI 존재
- `OCRViewModel.swift`: Vision OCR 후 Claude 보완 수행
- `ClaudeOCRService.swift`: Vision 추출 텍스트만 Anthropic으로 전송, `Debug` 환경 변수 기반 직접 호출 사용
- `project.pbxproj`: 카메라 권한 문구 존재
