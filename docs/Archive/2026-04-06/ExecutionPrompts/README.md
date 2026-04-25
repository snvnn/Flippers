# Improvement Execution Prompts

이 디렉터리는 `docs` 안의 리뷰/UX 문서를 읽고, 실제 코드 변경과 검증까지 이어지게 만드는 실행 프롬프트를 단계별로 쪼개 놓은 문서 모음이다.

## 구성

- `01-mission-and-scope.md`
  - 역할, 목표, 리뷰 범위, 기본 원칙
- `02-source-docs-and-priorities.md`
  - 반드시 읽을 문서, 우선순위 기준, 확인할 구현 후보
- `03-execution-workflow.md`
  - 실제 수행 절차와 작업 순서
- `04-implementation-rules.md`
  - 실행 시 지켜야 할 규칙과 가드레일
- `05-deliverables-and-documentation.md`
  - 최종 산출물 형식과 Markdown 문서화 규칙
- `06-code-review-prompt.md`
  - 지금 시점의 프로젝트 상태를 기준으로 한 코드 리뷰 전용 프롬프트

## 사용 방법

1. 순서대로 읽으면서 하나의 긴 프롬프트로 합쳐 사용한다.
2. 또는 필요한 문서만 골라 부분 프롬프트로 사용한다.
3. 실제 실행 시에는 `docs/Codereviews` 아래 문서를 먼저 읽게 해야 한다.

## 권장 조합

- 전체 실행용:
  - `01` + `02` + `03` + `04` + `05`
- 빠른 실행용:
  - `01` + `02` + `03`
- 문서화 강조용:
  - `03` + `05`
- 코드 리뷰 전용:
  - `06`
