# Flippers Release / Privacy Readiness Gate

작성일: 2026-04-21  
상태: frozen release gate / 배포 차단 기준

## 목적

이 문서는 `Flippers`의 외부 배포 여부를 판단하는 **고정된 출시 게이트**다.  
아래 **must-block-release** 항목 중 하나라도 미완료면 배포하지 않는다.

이 문서는 현재 상태/우선순위/프라이버시 요약 문서와 맞춰 유지하며, 새 backlog나 장기 아이디어를 적는 문서가 아니다.

## 배포 차단 기준: must-block-release

### 1. 운영자 및 사용자 연락 경로

- [x] 운영자명 확인: `윤현`
- [x] 사용자 문의 이메일 확보: `yunh1205@gmail.com`
- [ ] 공개용 문의 채널 확정
- [ ] 개인정보 처리 문의 / 권리 요청 접수 경로 확정

### 2. 보안 및 외부 처리 구조

- [x] Claude API 키를 클라이언트 번들에서 제거
- [x] OCR 외부 보완 경로를 프록시 구조로 전환
- [x] OCR 프록시 계약을 `text-only enhancement` 로 고정
- [ ] OCR 외부 전송은 사용자 opt-in / 선택 동의가 있어야만 동작하도록 최종 확인
- [ ] 실제 운영 프록시 배포 대상 확정 및 반영
- [ ] 서버 측 비밀 키 관리 방식 확정
- [ ] 운영 로그 보관 정책과 접근 범위 확정
- [ ] 사고 대응 / 키 유출 대응 절차 문서화
- [ ] 과거 노출 가능 키 폐기 / 교체 여부 확인
- [ ] 외부 전송 고지와 실제 구현이 일치하는지 최종 점검

### 3. 공개 문서 / 제출 정보

- [x] 개인정보처리방침 초안 존재
- [x] App Store Privacy 초안 존재
- [x] 컴플라이언스 워킹 드래프트 존재
- [ ] 개인정보처리방침에 실제 운영 정보 반영 완료
- [ ] App Store Privacy 제출값 확정
- [ ] 공개 문구와 실제 구현 / 운영 구조 정합성 최종 점검
- [ ] 이용약관 공개 여부 결정 및, 필요 시 초안 작성
- [ ] App Store / 공개 메타데이터용 웹사이트 또는 지원 링크 확정

### 4. 사용자 권리 절차

- [ ] 권리 요청 접수는 `yunh1205@gmail.com` 하나로 단일화
- [ ] 계정 삭제와 전체 데이터 삭제는 같은 이메일 기반 수동 처리 경로로 통합
- [ ] 데이터 반출(export)은 기본 미지원으로 확정
- [ ] 데이터 반출 요청에는 미지원 안내 문구를 문서화
- [ ] 문의 / 권리 요청 처리 기준 정리

### 5. 실환경 검증

- [ ] 실제 Firebase 설정이 포함된 Release / Archive 배포용 빌드에서 smoke test 통과 및 빌드 ID 기록
- [ ] 실제 Apple Sign-In 이 실제 기기 / 실제 계정 기준으로 통과
- [ ] Firebase smoke 와 Apple Sign-In smoke 가 같은 빌드 ID 에서 나온 증거인지 확인
- [ ] 배포 빌드 기준으로 SDK / 인증 / 동기화 경로 재점검
- [ ] debug 전용 우회, 로컬 목, 개발용 fallback 이 PASS 근거가 아님을 확인

## 배포 후 처리 또는 비차단 항목

아래 항목은 현재 release gate를 막지 않지만, 배포 후 또는 별도 정리 대상으로 남겨둘 수 있다.

- 선택적 정책 문구 다듬기
- 내부 운영 메모 정리
- 문의 응답 SLA 세부화
- 웹사이트 문서의 추가 보강

## 현재 확보된 운영 정보

- 운영자명: `윤현`
- 문의 이메일: `yunh1205@gmail.com`

## 연계 문서

- `docs/Current/Flippers-Release-Privacy-Summary-2026-04-06.md`
- `docs/operations/2026-04-21-flippers-ocr-proxy-runbook.md`
- `docs/testing/2026-04-21-flippers-auth-audit.md`
- `docs/testing/2026-04-21-flippers-firebase-smoke-checklist.md`
- `docs/release/2026-04-24-flippers-release-blocker-followup-plan.md`
