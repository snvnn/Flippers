# Flippers Worklog

작성일: 2026-04-06
작업 주제: OCR 설정 가드 추가 및 개인정보처리방침 초안 작성
작업 상태: 완료

## 1. 작업 배경

- 이전 작업에서 OCR 외부 전송 고지와 사용자 선택권을 반영함
- 남은 우선순위 중 즉시 가능한 항목으로 `키 미설정 상태의 안전한 처리`와 `공개 정책 문서 초안 작성`을 선정함

## 2. 참고 문서

- `docs/Codereviews/Flippers-Code-Review-2026-04-01.md`
- `docs/Codereviews/Flippers-UX-Usecases.md`
- `docs/Compliance/Flippers-Compliance-Working-Draft-2026-04-06.md`

## 3. 수행 내용

1. OCR 설정 감지 공통화

- `OCRConfiguration`를 추가해 `CLAUDE_API_KEY` 존재 여부를 공통으로 확인할 수 있게 정리함

2. 키 미설정 시 OCR 클라우드 보완 비활성화

- OCR 화면에서 API 키가 없으면 토글을 비활성화
- 저장된 토글 값이 켜져 있어도 실제 동작은 로컬 OCR만 사용하도록 정규화
- 사용자에게 왜 사용할 수 없는지 설명 문구를 노출

3. 공개용 개인정보처리방침 초안 작성

- 현재 구현 기준으로 수집 항목, 목적, 외부 처리자, 선택적 Claude 보완, 권리, 보관 원칙을 정리
- 운영자 정보와 문의처는 placeholder로 남김

4. App Store 제출용 개인정보 요약 초안 작성

- App Privacy 라벨 작성 시 검토해야 할 데이터 범주를 현재 코드 기준으로 정리
- Tracking 여부와 주요 수집 카테고리 초안을 문서화

## 4. 변경 파일

- `Flippers/Flippers/Services/ClaudeOCRService.swift`
- `Flippers/Flippers/Presentation/OCR/OCRView.swift`
- `docs/Policies/Flippers-Privacy-Policy-Draft-ko-KR-2026-04-06.md`
- `docs/AppStore/Flippers-App-Privacy-Disclosure-Draft-2026-04-06.md`
- `docs/Compliance/Flippers-Compliance-Working-Draft-2026-04-06.md`
- `docs/Changes/2026-04-06-flippers-ocr-config-guard-and-privacy-draft.md`
- `docs/Worklogs/2026-04-06-flippers-ocr-config-guard-and-privacy-draft.md`

## 5. 남은 리스크

- `CLAUDE_API_KEY` 자체는 여전히 클라이언트 번들 기반 구조를 전제로 함
- 서버 프록시나 안전한 토큰 교환 구조는 아직 미구현
- 공개 정책 문서는 초안일 뿐이며 법률 검토와 실제 운영자 정보 반영이 필요

## 6. 검증 메모

- OCR 설정 감지 호출부와 UI 사용처를 정적으로 확인
- 전체 iOS 빌드는 현재 로컬 Xcode 환경 미설정으로 검증 불가
