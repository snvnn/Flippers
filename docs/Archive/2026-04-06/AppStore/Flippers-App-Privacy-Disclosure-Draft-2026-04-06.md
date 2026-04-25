# Flippers App Store Privacy Disclosure Draft

작성일: 2026-04-06
문서 상태: Draft
주의: App Store Connect 제출 전 실제 SDK 사용 상태, 리전 설정, 운영 정책과 대조가 필요합니다.

## 1. 전제

이 문서는 2026-04-06 기준 저장소 구현을 바탕으로 App Store 개인정보 라벨 작성을 돕기 위한 내부 초안입니다.

현재 코드 기준 주요 처리 경로:

- Firebase Authentication
- Apple Sign in
- SwiftData + CloudKit
- Photos / Camera OCR
- 선택적 Claude OCR 보완

## 2. Tracking 여부 초안

- Tracking: 아니오 초안

근거:

- 현재 코드상 제3자 광고 SDK, 광고 식별자, 교차 앱 추적 로직은 확인되지 않음

## 3. 수집 데이터 카테고리 초안

### 3.1 Contact Info

- 데이터: 이메일 주소
- 수집 여부: 예
- 목적: 계정 생성 및 로그인
- 연결 여부: 사용자 계정에 연결됨
- 추적 목적 사용 여부: 아니오

### 3.2 Identifiers

- 데이터: Firebase UID, Apple 계정 기반 식별값
- 수집 여부: 예
- 목적: 인증, 계정 식별, 동기화
- 연결 여부: 사용자 계정에 연결됨
- 추적 목적 사용 여부: 아니오

### 3.3 User Content

- 데이터: 카드, 덱, 섹션, 예문, 학습 콘텐츠
- 수집 여부: 예
- 목적: 앱 핵심 기능 제공, 기기 간 동기화
- 연결 여부: 사용자 계정에 연결될 수 있음
- 추적 목적 사용 여부: 아니오

### 3.4 Usage Data

- 데이터: 복습 기록, 학습 상태, SRS 관련 값
- 수집 여부: 예
- 목적: 학습 기록 유지, 복습 스케줄 계산, 사용자별 진행 상태 제공
- 연결 여부: 사용자 계정에 연결될 수 있음
- 추적 목적 사용 여부: 아니오

### 3.5 Photos or Videos

- 데이터: 사용자가 OCR에 사용하는 이미지
- 수집 여부: 조건부
- 목적: OCR 카드 생성
- 연결 여부: 이미지 내용에 따라 사용자와 연결될 수 있음
- 추적 목적 사용 여부: 아니오
- 주의: 사용자가 `Claude 읽기/뜻 보완`을 켠 경우 외부 서비스로 전송될 수 있음

## 4. Not Collected 또는 추가 확인 필요 항목

현재 코드 기준 아래 항목은 수집이 확인되지 않았거나 App Store 제출 전 재검토가 필요합니다.

- Precise Location
- Health and Fitness
- Financial Info
- Contacts
- Browsing History
- Search History
- Purchases
- Diagnostics

주의:

- Firebase SDK 또는 Apple 플랫폼에서 자동 수집되는 진단/기기 데이터 범위는 실제 배포 설정으로 재확인해야 합니다.

## 5. App Privacy 목적 매핑 초안

### App Functionality

- 이메일 주소
- 계정 식별자
- 카드/덱/학습 콘텐츠
- 학습 기록
- OCR 이미지

### Account Management

- 이메일 주소
- 계정 식별자

### Product Personalization

- 학습 기록
- SRS 상태

### Developer Advertising

- 해당 없음 초안

### Analytics

- 현재 코드 기준 명시적 분석 SDK는 확인되지 않음

## 6. 제출 전 확인 체크리스트

- 실제 배포 빌드에 포함된 SDK 목록 확인
- Firebase Auth 외 Firebase 제품 사용 여부 재확인
- CloudKit 동기화가 실제 배포 범위에 포함되는지 확인
- OCR 이미지 장기 저장 여부 확인
- Claude 외부 보완이 기본 꺼짐 상태인지 확인
- 운영 정책과 공개용 개인정보처리방침 문구 일치 여부 확인

## 7. 현재 판단

현 시점 초안으로는 `Tracking 없음`, `Contact Info`, `Identifiers`, `User Content`, `Usage Data`, `Photos or Videos` 범주를 우선 검토 대상으로 보는 것이 타당합니다.

다만 App Store 개인정보 라벨은 구현뿐 아니라 실제 배포 설정과 SDK 런타임 동작을 기준으로 제출해야 하므로, 최종 제출 전 빌드 산출물 기준 재검토가 필요합니다.
