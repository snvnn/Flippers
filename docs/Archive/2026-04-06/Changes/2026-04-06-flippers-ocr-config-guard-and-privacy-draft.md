# Flippers Change Record

작성일: 2026-04-06
변경명: OCR 설정 가드 및 개인정보처리방침 초안 추가

## 1. 변경 목적

- 키 미설정 상태에서 OCR 클라우드 보완이 오작동하거나 사용자를 혼란스럽게 만드는 문제를 줄이기 위함
- 컴플라이언스 초안 문서를 공개용 정책 초안으로 연결하기 위함

## 2. 사용자 영향

- `CLAUDE_API_KEY`가 없으면 OCR 화면에서 클라우드 보완 토글이 비활성화된다
- 왜 사용할 수 없는지 앱 화면에서 바로 확인할 수 있다
- 프로젝트 문서에 공개용 개인정보처리방침 초안이 추가되었다

## 3. 구현 상세

### 코드

- `OCRConfiguration` 추가
- `OCRView`에서 설정 가능 여부에 따라 토글 상태와 실제 사용 여부를 분리

### 문서

- 공개용 개인정보처리방침 초안 작성
- App Store 개인정보 제출용 요약 초안 작성
- 컴플라이언스 초안에 현재 조치 반영

## 4. 변경 파일

- `Flippers/Flippers/Services/ClaudeOCRService.swift`
- `Flippers/Flippers/Presentation/OCR/OCRView.swift`
- `docs/Policies/Flippers-Privacy-Policy-Draft-ko-KR-2026-04-06.md`
- `docs/AppStore/Flippers-App-Privacy-Disclosure-Draft-2026-04-06.md`
- `docs/Compliance/Flippers-Compliance-Working-Draft-2026-04-06.md`

## 5. 잔여 리스크

- 키 저장 구조 자체는 아직 안전하지 않다
- 법적 공개 문서로 사용하려면 운영자 정보와 법률 검토가 필요하다
