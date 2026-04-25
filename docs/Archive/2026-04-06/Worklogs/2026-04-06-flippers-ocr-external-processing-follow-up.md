# Flippers Worklog

작성일: 2026-04-06
작업 주제: OCR 외부 전송 고지 및 사용자 선택권 반영
작업 상태: 완료

## 1. 작업 트리거

- 사용자가 "다음 할 일을 문서들 참고해서 알아서 해달라"고 요청함
- 추가 요구사항으로 변경 내역과 작업 내용 기록을 반드시 남기도록 지정함

## 2. 참고 문서

- `docs/ExecutionPrompts/02-source-docs-and-priorities.md`
- `docs/ExecutionPrompts/03-execution-workflow.md`
- `docs/Codereviews/Flippers-Improvements-P0-P3-2026-04-01.md`
- `docs/Compliance/Flippers-Compliance-Working-Draft-2026-04-06.md`

## 3. 이번 턴의 우선순위 판단

문서 기준으로 이번 턴에서 가장 현실적으로 바로 반영 가능한 P0 항목은 아래였다.

- OCR 이미지의 외부 전송 고지 부재
- 외부 AI 보완에 대한 사용자 선택권 부재

`CLAUDE_API_KEY`의 클라이언트 번들 사용 문제도 P0이지만, 이는 앱 아키텍처 변경이나 서버 프록시 도입이 필요하므로 이번 턴의 작은 안전한 수정 범위를 넘는다고 판단했다.

## 4. 수행 내용

1. OCR 업로드 화면에 외부 AI 보완 설정 섹션 추가

- 기본값을 로컬 OCR만 사용하도록 유지
- 사용자가 명시적으로 켜야만 Claude 보완을 사용하도록 변경

2. 외부 AI 보완 활성화 전 경고 추가

- 토글을 켤 때 경고 alert를 표시
- OCR 이미지와 추출 텍스트가 외부 AI 서비스로 전송될 수 있음을 명시

3. OCR 처리 안내 시트 추가

- 로컬 처리
- 외부 AI 보완
- 민감정보 업로드 지양 안내

4. 실제 OCR 처리 로직 분기 추가

- 외부 보완 비활성 시 Claude 호출 생략
- 로컬 OCR만 사용하고 읽기/뜻이 비어 있을 수 있다는 안내를 리뷰 단계에 표시

5. 컴플라이언스 초안 갱신 예정 항목 반영

- "고지 부재"에서 "부분 조치 완료, 잔여 리스크 존재" 상태로 갱신

## 5. 변경 파일

- `Flippers/Flippers/Presentation/OCR/OCRView.swift`
- `Flippers/Flippers/Presentation/OCR/OCRViewModel.swift`
- `docs/Compliance/Flippers-Compliance-Working-Draft-2026-04-06.md`
- `docs/Changes/2026-04-06-flippers-ocr-privacy-controls.md`
- `docs/Worklogs/2026-04-06-flippers-ocr-external-processing-follow-up.md`

## 6. 보류 항목

- Claude API 호출을 서버 프록시로 옮기는 작업
- 비밀 키 관리 구조 재설계
- 공개용 개인정보처리방침 작성
- 계정 삭제 및 전체 데이터 삭제 플로우 구현

## 7. 검증 메모

- 우선 정적 확인으로 OCR 호출부가 새 시그니처와 일치하는지 확인
- `xcodebuild` 검증 시도 결과, active developer directory가 `/Library/Developer/CommandLineTools`로 설정되어 있어 빌드를 시작하지 못함
- 현재 환경에서는 Xcode 앱이 선택되어 있지 않아 전체 빌드 성공 여부는 확인 불가
