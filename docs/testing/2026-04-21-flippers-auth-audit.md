# Flippers Auth Error / Missing-Config Audit

작성일: 2026-04-21  
상태: 현재 저장소 기준 auth 실패 상태와 missing-config 동작 점검 메모

## 목적

이 문서는 `Flippers`의 인증 경로가 **Firebase 설정 유무에 따라 어떻게 동작하는지**, 그리고 **대표 실패 케이스가 어떤 사용자 메시지로 매핑되는지**를 빠르게 다시 확인할 수 있게 정리한다.

## 점검 대상 파일

- `Flippers/Presentation/Auth/AuthViewModel.swift`
- `Flippers/Presentation/Auth/AuthView.swift`
- `Flippers/Data/Remote/FirebaseAuthRepository.swift`
- `Flippers/Services/FirebaseBootstrap.swift`
- `FlippersTests/FlippersTests.swift`

## 현재 동작 요약

### 1. Firebase 설정이 없을 때

- `FirebaseBootstrap.configureIfAvailable()` 가 `GoogleService-Info.plist` 유무를 먼저 확인한다.
- 설정 파일이 없으면 `.missingGoogleServiceInfo` 를 반환한다.
- 이 경우 `AuthViewModel` 은 `UnavailableAuthRepository` 를 사용한다.
- 사용자에게는 다음 의미의 고정 메시지가 노출된다.
  - 로그인/클라우드 동기화 비활성화
  - 로컬 학습 기능은 계속 사용 가능

대표 메시지:
- `GoogleService-Info.plist가 번들에 없어 로그인과 클라우드 동기화가 비활성화되었습니다. 로컬 학습 기능은 계속 사용할 수 있습니다.`

### 2. Firebase 설정 파일이 있지만 읽을 수 없을 때

- `FirebaseBootstrap.configureIfAvailable()` 가 `.invalidGoogleServiceInfo` 를 반환한다.
- 사용자에게는 설정 파일 구성을 확인하라는 메시지가 노출된다.

대표 메시지:
- `Firebase 설정 파일을 읽을 수 없어 로그인과 클라우드 동기화가 비활성화되었습니다. GoogleService-Info.plist 구성을 확인하세요.`

### 3. 이메일 로그인/회원가입 실패 매핑

`FirebaseAuthRepository.mapFirebaseError(_:)` 기준:

- `invalidEmail` → `이메일 형식이 올바르지 않습니다.`
- `wrongPassword`, `invalidCredential` → `이메일 또는 비밀번호가 올바르지 않습니다.`
- `userNotFound` → `등록된 계정이 없습니다.`
- `emailAlreadyInUse` → `이미 사용 중인 이메일입니다.`
- `weakPassword` → `비밀번호는 6자 이상이어야 합니다.`
- `networkError` → `네트워크 연결을 확인해주세요.`
- `tooManyRequests` → `잠시 후 다시 시도해주세요. (요청 횟수 초과)`
- `userDisabled` → `비활성화된 계정입니다. 고객센터에 문의해주세요.`

### 4. Apple Sign-In 실패 처리

- 인증이 애초에 비활성 상태면 `configurationMessage` 를 바로 사용자에게 보여준다.
- Apple 로그인 결과가 취소(`ASAuthorizationError.canceled`)면 에러를 띄우지 않는다.
- Apple credential / token / nonce 를 해석할 수 없으면:
  - `Apple 로그인 정보를 처리할 수 없습니다.`
- Firebase 쪽 인증 실패는 공통 `koreanMessage(for:)` 경로를 통해 처리된다.

### 5. 로그아웃 실패 처리

- `AuthViewModel.signOut()` 도 이제 공통 `koreanMessage(for:)` 경로를 사용한다.
- 따라서 `AuthError.network` 같은 내부 auth 에러는 영문 raw message 대신 사용자용 한글 메시지로 보여준다.

## 현재 테스트 근거

### AuthViewModelTests

- missing-config 상태에서 `submitEmail()` 이 설정 메시지를 그대로 노출하는지
- missing-config 상태에서 `handleAppleSignIn()` 이 설정 메시지를 그대로 노출하는지
- `signOut()` 이 사용자용 한글 auth 메시지를 사용하는지

### FirebaseBootstrapTests

- `.missingGoogleServiceInfo` 메시지 고정 여부
- `.invalidGoogleServiceInfo` 메시지 고정 여부
- 테스트 번들에 `GoogleService-Info.plist` 가 없을 때 `configureIfAvailable(bundle:)` 가 `.missingGoogleServiceInfo` 를 반환하는지

### FirebaseAuthErrorMappingTests

- `invalidEmail` 매핑
- `wrongPassword` → `invalidCredentials` 매핑
- 비-Firebase domain 에러 passthrough

## 현재 남은 한계

- 이 저장소에는 실제 `GoogleService-Info.plist` 가 없어서 실환경 Firebase 로그인 smoke test 는 아직 불가능하다.
- Apple Sign-In 의 실제 디바이스/시뮬레이터 경로는 정적 코드 점검과 테스트 더블 수준만 확인했다.
- 실제 Firebase 프로젝트와 연결된 네트워크/권한/Apple capability 검증은 별도 실환경 체크리스트로 이어서 확인해야 한다.

## 다음 연결 작업

- `docs/testing/2026-04-21-flippers-firebase-smoke-checklist.md` 에서 실환경 검증 절차를 정리한다.
- 실제 `GoogleService-Info.plist` 가 준비되면 이메일 로그인 / Apple 로그인 / 동기화 smoke test 를 수행한다.
