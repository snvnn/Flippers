# Flippers OCR Proxy Runbook

작성일: 2026-04-21  
상태: 현재 `Flippers`의 OCR text-enhancement 프록시 운영 기준 초안

## 목적

이 문서는 `Flippers` 앱이 사용하는 OCR 프록시의 **운영 계약(contract)** 과 **배포 체크리스트** 를 고정한다.

핵심 원칙:
- 앱은 **원본 이미지를 직접 Claude로 보내지 않는다**.
- 앱은 Vision on-device로 먼저 텍스트를 추출한다.
- 프록시는 **텍스트 보완 전용(text-only enhancement)** 으로만 동작한다.

## 현재 계약

### 엔드포인트

- Health: `GET /health`
- OCR enhancement: `POST /api/ocr`

### 허용 요청 형식

```json
{
  "words": ["腕", "機会"]
}
```

### 허용하지 않는 형식

아래와 같은 이미지 직접 업로드 형식은 운영 계약 밖이다.

```json
{
  "imageBase64": "...",
  "mimeType": "image/png"
}
```

현재 스텁 구현은 `words` 배열이 비어 있으면 이런 요청을 `400`으로 거절한다.
`words` 와 함께 추가 필드가 같이 들어오면 현재는 무시될 수 있으므로, 운영 프록시에서는 text-only 계약 위반 요청을 명시적으로 차단하는 것이 바람직하다.

## 환경 변수

### 필수(운영 relay 모드)

- `ANTHROPIC_API_KEY`
  - 서버에만 둔다.
  - 앱 번들, 클라이언트 저장소, Info.plist에 넣지 않는다.

### 선택

- `PORT`
  - 기본값: `8787`
- `ANTHROPIC_MODEL`
  - 기본값: `claude-opus-4-5`

## 모드

> 주의: 현재 저장소의 `tools/ocr-proxy-server.mjs` 는 `127.0.0.1` 에 바인딩되는 **로컬 스텁** 이다. 로컬 smoke test 와 계약 검증용으로는 충분하지만, 이 파일 자체를 그대로 production relay 로 간주하면 안 된다. 실제 운영 배포 시에는 listener/networking, 비밀 관리, 인증, 관측성, 제한 정책을 별도로 갖춘 서비스로 넘겨야 한다.

### 1. Mock mode

`ANTHROPIC_API_KEY`가 없으면 mock 응답을 반환한다.

확인:

```bash
curl http://127.0.0.1:8787/health
```

예상:

```json
{"ok":true,"mode":"mock"}
```

### 2. Relay mode

`ANTHROPIC_API_KEY`가 있으면 프록시가 Anthropic Messages API로 relay 한다.

확인:

```bash
curl http://127.0.0.1:8787/health
```

예상:

```json
{"ok":true,"mode":"relay"}
```

## 로컬 실행

```bash
cd /home/yoonhyeon/projects/nipponbenkyo/Flippers
node tools/ocr-proxy-server.mjs
```

포트 지정:

```bash
PORT=8787 node tools/ocr-proxy-server.mjs
```

relay 모드 예시:

```bash
ANTHROPIC_API_KEY=*** PORT=8787 node tools/ocr-proxy-server.mjs
```

## 요청 검증 예시

### 정상 요청

```bash
curl -s http://127.0.0.1:8787/api/ocr \
  -H 'content-type: application/json' \
  -d '{"words":["腕","機会"]}'
```

### 차단되어야 하는 요청

```bash
curl -i http://127.0.0.1:8787/api/ocr \
  -H 'content-type: application/json' \
  -d '{"imageBase64":"ZmFrZQ==","mimeType":"image/png"}'
```

예상:
- HTTP `400`
- 에러 메시지에 `text-only` 또는 `words array` 취지 포함

## 앱 연결 기준

앱은 다음 구성 중 하나로 프록시 base URL을 받는다.

- Info.plist 키: `OCRProxyBaseURL`
- 환경 변수: `OCR_PROXY_BASE_URL`

현재 프로젝트 기준:
- Debug 빌드: 로컬 프록시 URL 사용 가능
- Release 빌드: 저장소 기본값은 빈 값 유지
- 실제 운영 URL 주입 방식은 App Store 런타임 환경변수 주입이 아니라, 릴리스 빌드 설정/xcconfig/CI 비밀값 등 배포 파이프라인에서 별도로 확정해야 한다.

## 배포 체크리스트

### 배포 전

- [ ] 운영 프록시 URL 확정
- [ ] `ANTHROPIC_API_KEY`를 서버 비밀 저장소에만 배치
- [ ] 앱 번들/클라이언트 저장소에 비밀 키가 없는지 재확인
- [ ] `GET /health` 동작 확인
- [ ] `POST /api/ocr` text-only 요청 확인
- [ ] image payload가 `400`으로 차단되는지 확인
- [ ] 로그에 요청 본문 원문 전체나 비밀 키를 남기지 않는지 확인
- [ ] 인증, rate limiting, request size 제한, 네트워크 노출 범위를 운영 환경에서 별도로 설계했는지 확인

### 배포 후

- [ ] 앱 Debug/Release 설정이 올바른 URL을 바라보는지 확인
- [ ] opt-in을 켠 경우만 외부 보완이 동작하는지 확인
- [ ] 프록시 장애 시 앱이 Vision-only fallback으로 복귀하는지 확인

## 키 관리 / 회전

- 키는 서버 비밀 저장소에서 관리한다.
- 과거 노출 이력이 의심되면 기존 키를 폐기하고 새 키로 교체한다.
- 키 교체 시 앱 업데이트보다 서버 설정 갱신이 우선이다.
- 키를 코드, git history, 스크린샷, 로그에 남기지 않는다.

## 장애 대응

### 증상: `/health`는 정상인데 `/api/ocr`가 실패함

확인 순서:
1. `ANTHROPIC_API_KEY` 설정 여부
2. Anthropic API 응답 코드/에러 메시지
3. 프록시 outbound 네트워크 제한 여부
4. 모델명(`ANTHROPIC_MODEL`) 오타 여부

### 증상: 프록시 장애 시 앱 UX 저하

기대 동작:
- 앱은 OCR 전체를 실패시키지 않고
- Vision 결과만으로 review 단계에 진입해야 한다.
- 읽기/뜻이 비어 있을 수 있다는 경고를 보여줘야 한다.

## 롤백 기준

다음 중 하나면 relay 기능을 꺼도 된다.
- 외부 보완 실패율이 높음
- 응답 지연이 UX를 심하게 해침
- 보안/운영 상태가 불명확함

롤백 방식:
- 운영 URL 제거 또는 서버 비활성화
- 앱은 Vision-only 흐름으로 계속 동작

## 현재 남은 운영 갭

- 실제 프로덕션 프록시 배포 대상 미확정
- 비밀 저장소/배포 파이프라인 미확정
- 운영 로그 정책 및 사고 대응 문서 미확정
- 공개 개인정보처리방침/App Store Privacy 항목과 최종 정합성 확인 필요
