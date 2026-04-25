# Flippers Change Record

작성일: 2026-04-06
변경명: OCR 외부 전송 고지 및 사용자 선택권 추가

## 1. 변경 목적

컴플라이언스 초안과 실행 문서 기준으로, OCR 이미지가 외부 AI 서비스로 전송될 수 있는데도 앱 UI에 사전 고지와 선택권이 없던 문제를 완화하기 위한 변경이다.

## 2. 사용자 관점 변화

- OCR 화면에서 Claude 보완 사용 여부를 직접 선택할 수 있다.
- 기본값은 로컬 OCR만 사용하는 방향으로 변경됐다.
- 외부 AI 보완을 켜기 전 경고 문구가 표시된다.
- 처리 방식 안내 시트에서 로컬 처리와 외부 전송 범위를 확인할 수 있다.
- 외부 보완을 끈 경우 읽기/뜻이 비어 있을 수 있다는 안내가 리뷰 단계에 표시된다.

## 3. 구현 상세

### UI

- OCR 업로드 화면에 `Claude 읽기/뜻 보완` 설정 섹션 추가
- `처리 방식 보기` 시트 추가
- 토글 활성화 시 경고 alert 추가

### 로직

- `processImage`에 `useCloudEnhancement` 인자를 추가
- 비활성 상태에서는 `ClaudeOCRService` 호출을 생략
- 비활성 상태에서 빈 reading/meaning이 있으면 안내 메시지 표시

## 4. 변경 파일

- `Flippers/Flippers/Presentation/OCR/OCRView.swift`
- `Flippers/Flippers/Presentation/OCR/OCRViewModel.swift`

## 5. 잔여 리스크

- Claude API는 여전히 클라이언트에서 직접 호출된다.
- `Config.plist` 기반 API 키 사용 구조는 그대로 남아 있다.
- 공개용 정책 문서와 App Store 제출용 개인정보 설명은 별도로 작성해야 한다.

## 6. 검증

- OCR 호출부 검색으로 새 함수 시그니처 적용 여부 확인
- `xcodebuild` 검증은 시도했으나 active developer directory가 Command Line Tools로 설정되어 있어 실행 불가
