# 02. Source Docs And Priorities

```text
반드시 먼저 읽을 문서:
- `docs/Codereviews/Flippers-Code-Review-2026-04-01.md`
- `docs/Codereviews/Flippers-UX-Usecases.md`

필요하면 추가로 읽을 것:
- `docs` 하위의 다른 Markdown 문서 전부
- 코드와 연결되는 기존 스펙 문서 (`CLAUDE.md`, `SRS.md` 등)

작업 목표:
1. 문서들에서 개선 요구사항을 추출한다.
2. 중복/충돌 항목을 정리한다.
3. 우선순위를 정한다.
4. 실제 코드 수정으로 반영한다.
5. 가능한 검증을 수행한다.
6. 어떤 항목을 반영했고 어떤 항목은 보류했는지 Markdown 문서로 기록한다.

우선순위 기준:
- P0: 보안 문제, 앱 실행 불가, 빌드 불가, 데이터 손상, 런타임 크래시
- P1: 핵심 사용자 플로우 저해 (회원가입, 첫 카드 생성, OCR 등록, 학습 시작/완료)
- P2: UX 마찰 감소, 에러 메시지 개선, 빈 상태 개선, 후속 품질 개선
- P3: nice-to-have polishing

반드시 점검할 구현 후보:
- secret/API key 처리 방식
- Firebase/Xcode 설정 재현 가능성
- plist/resource target 포함 여부
- SwiftData container 생성 위치와 실패 처리
- OCR 실패 시 사용자 메시지
- OCR 결과 편집/병합 로직
- 첫 실행/카드 0개 상태 UX
- 학습 세션 평가 가이드 및 진행 상태 혼란
- 덱/섹션 흐름
- placeholder 테스트만 있는 문제
- 핵심 로직 테스트 추가
```
