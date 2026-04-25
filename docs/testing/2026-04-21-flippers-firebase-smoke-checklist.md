# Flippers Firebase Smoke Test Checklist

작성일: 2026-04-21  
상태: 실환경 Firebase 검증 전 체크리스트 초안

## 목적

이 문서는 `Flippers` 에 실제 Firebase 설정을 연결했을 때 **무엇을 어떤 순서로 확인할지** 고정한다.

현재 저장소에는 `GoogleService-Info.plist` 가 없으므로, 이 문서는 **즉시 실행 로그** 가 아니라 **실행 준비 체크리스트** 다.

## 현재 차단 조건

- 현재 저장소에는 `GoogleService-Info.plist` 가 포함되어 있지 않다.
- 따라서 이메일 로그인 / Apple 로그인 / Firebase 연동 smoke test 를 이 저장소 상태만으로는 완료할 수 없다.
- 실검증을 시작하려면 먼저 올바른 Firebase 프로젝트용 `GoogleService-Info.plist` 가 필요하다.

## 사전 준비

### 필수 파일 / 설정

- [ ] 올바른 `GoogleService-Info.plist` 확보
- [ ] 대상 Xcode 타깃 번들에 `GoogleService-Info.plist` 포함 확인
- [ ] Firebase Authentication 에 이메일/비밀번호 로그인 활성화 확인
- [ ] Firebase Authentication 에 Sign in with Apple 설정 확인
- [ ] Apple Developer 쪽 Sign in with Apple capability 확인
- [ ] 앱 entitlements / bundle identifier / Team 설정이 Firebase 프로젝트와 일치하는지 확인

### 테스트 환경

- [ ] 실제 테스트용 이메일 계정 준비
- [ ] 회원가입 가능한 신규 테스트 이메일 준비
- [ ] Apple 로그인 테스트용 Apple ID 준비
- [ ] 네트워크 연결 가능한 실제 기기 또는 시뮬레이터 준비
- [ ] 테스트 결과를 기록할 로그 문서 또는 메모 준비

## Smoke Test 순서

### 1. 앱 부팅 / 설정 로딩

목표:
- Firebase 설정 파일이 있는 상태에서 앱이 정상 부팅되는지 확인

체크:
- [ ] 앱 실행 시 crash 없음
- [ ] Firebase 미설정 경고 UI가 더 이상 기본 상태로 뜨지 않음
- [ ] Auth 화면이 로그인 가능 상태로 표시됨
- [ ] 로컬 모드 fallback 대신 실제 auth 경로가 열림

실패 시 확인:
- 번들에 `GoogleService-Info.plist` 가 실제 포함됐는지
- plist 파일이 다른 Firebase 프로젝트용이 아닌지
- `FirebaseBootstrap.configureIfAvailable()` 가 `.configured` 로 가는지

### 2. 이메일 로그인

목표:
- 기존 계정으로 이메일 로그인 가능한지 확인

체크:
- [ ] 기존 테스트 계정으로 로그인 성공
- [ ] 로그인 후 인증 상태가 반영됨
- [ ] 로그인 후 앱 내 사용자 상태가 유지됨
- [ ] 실패 시 한글화된 메시지가 일관되게 표시됨

대표 실패 케이스:
- [ ] 잘못된 이메일 형식
- [ ] 잘못된 비밀번호
- [ ] 존재하지 않는 계정
- [ ] 네트워크 오류
- [ ] 요청 횟수 초과

기록할 내용:
- 실제 사용자 메시지
- 콘솔/런타임 에러 여부
- 로그인 성공 직후 화면 전환 상태

### 3. 이메일 회원가입

목표:
- 신규 계정 생성 경로 확인

체크:
- [ ] 신규 이메일로 회원가입 성공
- [ ] 회원가입 직후 로그인 상태 반영
- [ ] 중복 이메일 에러 메시지 확인
- [ ] 약한 비밀번호 에러 메시지 확인

### 4. Apple 로그인

목표:
- Apple Sign-In 경로가 실제 환경에서 동작하는지 확인

체크:
- [ ] Apple 로그인 시트 정상 표시
- [ ] 로그인 성공 후 사용자 상태 반영
- [ ] 사용자가 취소했을 때 불필요한 에러 메시지 없음
- [ ] credential/token 처리 실패 시 사용자 메시지 확인
- [ ] Firebase 쪽 Apple auth 실패 시 한글화된 메시지 확인

실패 시 추가 확인:
- Apple capability / identifier / Firebase provider 설정 정합성
- nonce/token 처리 오류 여부
- 실제 기기/시뮬레이터 제약 여부

### 5. 로그아웃

목표:
- 인증 세션 정리 확인

체크:
- [ ] 로그아웃 성공
- [ ] 로그아웃 후 로그인 화면 또는 비로그인 상태 복귀
- [ ] 로그아웃 실패 시 사용자 메시지 확인

### 6. 동기화 관련 기본 점검

목표:
- 인증이 들어간 상태에서 실제 사용하는 저장/동기화 경로에 치명적 문제가 없는지 확인

체크:
- [ ] 로그인 상태에서 앱 기본 사용 가능
- [ ] 카드 생성/열람 등 핵심 로컬 흐름 정상
- [ ] CloudKit 또는 실제 사용하는 동기화 경로와 충돌 징후 없는지 확인
- [ ] Firebase 관련 런타임 오류가 콘솔에 반복되지 않는지 확인

## 실행 결과 기록 템플릿

```md
# Firebase Smoke Test Result

- 날짜:
- 빌드:
- 기기/시뮬레이터:
- Firebase 프로젝트:

## 1. 앱 부팅
- 결과:
- 메모:

## 2. 이메일 로그인
- 결과:
- 메모:

## 3. 이메일 회원가입
- 결과:
- 메모:

## 4. Apple 로그인
- 결과:
- 메모:

## 5. 로그아웃
- 결과:
- 메모:

## 6. 동기화 기본 점검
- 결과:
- 메모:
```

## 완료 조건

다음이 모두 충족되면 Firebase smoke test 를 완료로 본다.

- [ ] `GoogleService-Info.plist` 포함 상태에서 앱 실행 확인
- [ ] 이메일 로그인 확인
- [ ] 이메일 회원가입 확인
- [ ] Apple 로그인 확인
- [ ] 로그아웃 확인
- [ ] 인증 상태에서 핵심 앱 흐름 사용 가능 확인
- [ ] 대표 실패 케이스 메시지 기록 완료

## 연계 문서

- `docs/testing/2026-04-21-flippers-auth-audit.md`
- `docs/Current/Flippers-Current-Priorities-2026-04-06.md`
- `docs/Current/Flippers-Current-Status-2026-04-06.md`
