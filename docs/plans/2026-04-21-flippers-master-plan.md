# Flippers Release Stabilization Master Plan

> **For Hermes:** Use subagent-driven-development skill to execute this plan task-by-task when parallelization or independent review helps.

**Goal:** Bring `Flippers` from the current local-first MVP state to a release-ready state by closing the remaining P0–P3 gaps around OCR security/operations, runtime validation, test coverage, and release documentation.

**Architecture:** Keep the current `Presentation -> Domain <- Data` structure intact. Preserve the on-device Vision-first OCR flow, and keep cloud enhancement as an explicit opt-in text-enhancement step behind an OCR proxy. Treat release readiness as a sequence of bounded hardening tasks rather than a large refactor.

**Tech Stack:** SwiftUI, SwiftData, Firebase Auth, CloudKit, Vision, Node.js OCR proxy stub, Swift Testing, Xcode build/test tooling.

---

## Canonical Inputs

Read these first when revisiting the plan:

1. `docs/Current/Flippers-Current-Priorities-2026-04-06.md`
2. `docs/Current/Flippers-Current-Status-2026-04-06.md`
3. `docs/Current/Flippers-Release-Privacy-Summary-2026-04-06.md`
4. `CLAUDE.md`
5. `SRS.md`

## Current Working Assumptions

- The app is local-first and should remain usable without Firebase.
- New OCR code must **not** send raw images directly to Claude; only Vision-extracted text may be sent through a proxy.
- `GoogleService-Info.plist` is currently unavailable in the repo, so Firebase real-environment verification must be prepared but cannot be fully completed yet.
- The existing OCR proxy stub at `tools/ocr-proxy-server.mjs` is part of the release-risk surface and must match the intended text-only contract.

---

## Phase 1 — Close the P0 OCR Security / Operations Gap

### Task 1: Lock the OCR proxy contract to text-only enhancement

**Objective:** Remove remaining legacy image-relay behavior so the proxy and client contract match the documented Vision-first architecture.

**Files:**
- Modify: `tools/ocr-proxy-server.mjs`
- Modify: `Flippers/Services/ClaudeOCRService.swift`
- Test: `tools/tests/ocr-proxy-server.test.mjs`
- Test: `FlippersTests/FlippersTests.swift`
- Document: `docs/operations/2026-04-21-flippers-ocr-proxy-runbook.md`

**Success criteria:**
- Proxy accepts only `words` payloads for enhancement.
- Any `imageBase64`-style legacy path is rejected or removed.
- Automated tests cover the text-only contract.
- Runbook documents env vars, health check, and deployment expectations.

**Verification:**
- `node --test tools/tests/ocr-proxy-server.test.mjs`
- `xcodebuild -project Flippers.xcodeproj -scheme Flippers -destination 'platform=iOS Simulator,name=iPhone 16' build-for-testing`

### Task 2: Add deployment/runbook documentation for the OCR proxy

**Objective:** Make the remaining operational work explicit so the production proxy can be deployed without guessing.

**Files:**
- Create: `docs/operations/2026-04-21-flippers-ocr-proxy-runbook.md`
- Optionally create: `docs/operations/ocr-proxy.env.example`
- Update: `docs/Current/Flippers-Current-Priorities-2026-04-06.md`

**Success criteria:**
- Required env vars are documented.
- Health checks, deployment checklist, key rotation, and rollback steps are documented.
- The doc clearly distinguishes local mock mode vs production relay mode.

---

## Phase 2 — Stabilize OCR Quality (P1)

### Task 3: Expand OCR parser regression coverage for known layout drift

**Objective:** Capture the currently known parser brittleness in tests before changing parsing behavior.

**Files:**
- Modify: `FlippersTests/FlippersTests.swift`
- Modify: `Flippers/Presentation/OCR/OCRParsing.swift`
- Inspect: `Flippers/Presentation/OCR/OCRVisionExtractor.swift`
- Inspect: `Flippers/Presentation/OCR/OCRView.swift`

**Success criteria:**
- Tests cover shifted columns, split meanings, noisy checkbox artifacts, and at least one unsupported-layout fallback path.
- Parser changes are minimal and tied to failing tests.

**Verification:**
- Narrow test runs for OCR parser cases.
- Full `FlippersTests` target compile.

### Task 4: Tighten OCR review UX around unsupported/partial results

**Objective:** Reduce bad saves when OCR output is incomplete but technically parsable.

**Files:**
- Modify: `Flippers/Presentation/OCR/OCRViewModel.swift`
- Modify: `Flippers/Presentation/OCR/OCRView.swift`
- Test: `FlippersTests/FlippersTests.swift`

**Success criteria:**
- Unsupported or low-confidence OCR results produce clearer warnings.
- Save-state logic protects against blank or obviously malformed rows.

---

## Phase 3 — Prepare Auth / Firebase Validation (P1–P2)

### Task 5: Audit auth error handling against real flows and missing-config behavior

**Objective:** Ensure the app behaves clearly both with and without Firebase configuration.

**Files:**
- Inspect/modify: `Flippers/Presentation/Auth/AuthViewModel.swift`
- Inspect/modify: `Flippers/Data/Remote/FirebaseAuthRepository.swift`
- Inspect/modify: `Flippers/Services/FirebaseBootstrap.swift`
- Test: `FlippersTests/FlippersTests.swift`

**Success criteria:**
- Missing-config mode has deterministic user-facing errors.
- Email/password and Apple Sign-In failure states are mapped and documented.
- Tests cover representative missing-config and mapping cases.

### Task 6: Prepare Firebase smoke-test checklist for real credentials

**Objective:** Make the eventual real-environment test pass a checklist-driven execution instead of ad-hoc manual exploration.

**Files:**
- Create: `docs/testing/2026-04-21-flippers-firebase-smoke-checklist.md`
- Update if needed: `docs/Current/Flippers-Current-Status-2026-04-06.md`

**Success criteria:**
- Checklist covers app launch, email login, Apple login, and sync verification.
- Preconditions clearly call out the missing `GoogleService-Info.plist` blocker.

---

## Phase 4 — Strengthen Test Coverage and Build Verification (P2)

### Task 7: Re-establish a reliable narrow verification matrix

**Objective:** Ensure touched areas have repeatable verification commands even if full simulator runtime remains flaky.

**Files:**
- Update: `docs/testing/2026-04-21-flippers-verification-matrix.md`
- Inspect: `FlippersTests/FlippersTests.swift`

**Success criteria:**
- Narrow commands exist for OCR config, OCR parser, OCR save validation, and auth mapping.
- Build-for-testing and small-scope runs are documented.

---

## Phase 5 — Finish Release / Privacy Readiness (P2–P3)

### Task 8: Consolidate public release/privacy deliverables

**Objective:** Turn the current drafts into a checklist of publishable release artifacts.

**Files:**
- Inspect/update: `docs/Current/Flippers-Release-Privacy-Summary-2026-04-06.md`
- Inspect archive references under: `docs/Archive/2026-04-06/Policies/`, `docs/Archive/2026-04-06/AppStore/`, `docs/Archive/2026-04-06/Compliance/`
- Create: `docs/release/2026-04-21-flippers-release-readiness-checklist.md`

**Success criteria:**
- Operator contact info, deletion/request workflow, and App Store privacy answers are tracked in one place.
- Remaining external/legal dependencies are explicit.

---

## Immediate Next Task

Start with **Task 1: Lock the OCR proxy contract to text-only enhancement**.

**Why this first:**
- It is already the top P0 risk area.
- It is actionable with the current repo state.
- It reduces architecture drift between the app, the proxy stub, and the release/privacy docs.
- It creates a solid base for the operational runbook that follows.

## Execution Notes

- Use TDD for any code or behavior change.
- Keep edits tightly scoped; avoid unrelated cleanup while the repo already has many uncommitted files.
- Prefer narrow verification commands over broad simulator runs unless a change truly needs end-to-end UI validation.
- Do not modify `card-ace-sync/`.

## Progress Tracking

- [x] Task 1 complete — OCR proxy contract locked to text-only enhancement
- [x] Task 2 complete — OCR proxy runbook documented
- [x] Task 3 complete — OCR parser regression coverage expanded
- [x] Task 4 complete — OCR review UX hardened
- [x] Task 5 complete — auth/missing-config behavior audited
- [x] Task 6 complete — Firebase smoke checklist prepared
- [x] Task 7 complete — verification matrix refreshed
- [x] Task 8 complete — release/privacy readiness checklist consolidated
